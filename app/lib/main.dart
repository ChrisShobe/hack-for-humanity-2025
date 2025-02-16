import 'dart:io';  // For file handling on Android, iOS, or desktop platforms
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart'; // Import the vibration package
import 'package:flutter_background/flutter_background.dart';
import 'package:app/background.dart'; // Import the background task file
import 'package:torch_light/torch_light.dart';
import 'API/Client.dart'; // Import the vibration package
import 'audiorec.dart';  // Import the audio recorder service
import 'package:encrypt/encrypt.dart' as encrypt; // For encryption
import 'package:mime/mime.dart';  // Import the mime package
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

// Request permission

bool buttonsEnabled = true;
bool isFlashlightOn = false;
bool isVibrating = false;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hearo',
      theme: ThemeData(
        //primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A2A4E),
      ),
      home: const MyHomePage(title: 'Hearo'),
     // home: BackgroundTaskScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

  void showSirenMessage(BuildContext context) {
    final snackBar = SnackBar(content: Text("Turning on flash and vibration"));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

class _MyHomePageState extends State<MyHomePage> {
  List<bool> isSelected1 = [true, false];
  List<bool> isSelected2 = [false, true];
  List<bool> isSelected3 = [false, true];

  final AudioRecorderService _audioRecorder = AudioRecorderService(); // Initialize audio recorder
  bool isRecording = false;
  AudioUploader MyClient = AudioUploader(serverUrl: '192.168.50.19:5050');
  
  @override
  void initState() {
    print("INITSTATCALLED");
    super.initState();
    _requestPermissions(); 
    _startRecordingOnLaunch();  // Start recording when the app launches
    print("CONNECTING TO SERVER ");
    MyClient.connectToServer();  // Connect to the server on startup
  }


  Future<void> _requestPermissions() async {
    bool _permissionsGranted = false;
    if (_permissionsGranted) return;

    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          throw Exception("Manage External Storage permission not granted");
        }
      }
    } 
    _permissionsGranted = true; // Update the permissions state
  }
  bool isRecordingInProgress = false;
  void showSirenMessage(BuildContext context) {
    final snackBar = SnackBar(
      content: Text("Turning on flash and vibration"),
      duration: Duration(seconds: 3), // Set the duration to 3 seconds
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  Future<void> _startRecordingOnLaunch() async {
    await Permission.microphone.request();
    while (true) {
      if (!isRecordingInProgress) {
        isRecordingInProgress = true;
        await _audioRecorder.startRecording();
        print("LOOPING");
        setState(() { isRecording = true; });
        await Future.delayed(const Duration(seconds: 3));

        final path = await _audioRecorder.stopRecording();
        if (path == null) {
          print("There was an error and it didn't return a file path");
          isRecordingInProgress = false;  // Reset flag after failure
          return;
        }
        setState(() => isRecording = false);
        final encryptedFilePath = await _audioRecorder.encryptFile(path);
        print("IT GETS TILL HERE");
        String result = await MyClient.uploadAudioFile(encryptedFilePath);
        print('Result of AI is: $result');
        Map<String, dynamic> resultMap = jsonDecode(result);
        String message = resultMap['message'];
        if (message == "Siren") {
          print("Turning on flash and vibration");
          showSirenMessage(context);
          if (!isFlashlightOn) {
            _blinkFlashlight();
          }
          if (!isVibrating) {
            _vibratePhone();
          }
        } else {
          print("No siren detected!");
          if (isFlashlightOn) {
            _toggleFlashlight();
          }
          if (isVibrating) {
            _stopVibration();
          }
        }

        isRecordingInProgress = false; // Reset flag after recording ends
      }
      await Future.delayed(const Duration(seconds: 1)); // Optional delay to prevent excessive checks
    }
  }


  void toggleSelection(List<bool> list, int index) {
    setState(() {
      for (int i = 0; i < list.length; i++) {
        list[i] = (i == index);
      }
    });
  }

  void _vibratePhone() async {
    /*
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000); // Vibrates for 500 milliseconds
    }*/

   if (await Vibration.hasVibrator() ?? false) {
    isVibrating = true; // Start vibrating

    while (isVibrating) { // Loop only if isVibrating is true
      Vibration.vibrate(duration: 300);
      await Future.delayed(Duration(milliseconds: 200)); // Short pause
    }
  }
  }

  void _stopVibration() {
  isVibrating = false; // Stop the loop
}

  Future<void> _toggleFlashlight() async {
    try {
      if (isFlashlightOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() {
        isFlashlightOn = !isFlashlightOn;
      });
    } catch (e) {
      print('Error toggling flashlight: $e');
    }
  }
  Future<void> _blinkFlashlight() async {
  try {
    int blinkDuration = 50; // Duration in milliseconds for each blink
    int totalDuration = 3000; // Total duration of blinking in milliseconds
    int endTime = DateTime.now().millisecondsSinceEpoch + totalDuration;

    while (DateTime.now().millisecondsSinceEpoch < endTime) {
      await TorchLight.enableTorch();
      await Future.delayed(Duration(milliseconds: blinkDuration));
      await TorchLight.disableTorch();
      await Future.delayed(Duration(milliseconds: blinkDuration));
    }
  } catch (e) {
    print('Error blinking flashlight: $e');
  }
}
  // Start/Stop recording function
  Future<void> toggleRecording() async {
    if (isRecording) {
      final path = await _audioRecorder.stopRecording();

      print('Recording saved at: $path');
    } else {
      await _audioRecorder.startRecording();
    }
    setState(() => isRecording = !isRecording);  // Toggle recording state
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0251D3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // Removes shadow
        centerTitle: true,
        toolbarHeight: 100,
        title: Padding(
          padding: const EdgeInsets.only(top: 40),
        child: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'H',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontFamily: 'Bungee',
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 4),
                      blurRadius: 4,
                      color: Color(0xFF000000),
                    )
                  ],
                ),
              ),
              TextSpan(
                text: 'ear',
                style: TextStyle(
                  color: Color(0xFF8BFFA4),
                  fontSize: 50,
                  fontFamily: 'Bungee',
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 4),
                      blurRadius: 4,
                      color: Color(0xFF000000),
                    )
                  ],
                ),
              ),
              TextSpan(
                text: 'o',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontFamily: 'Bungee',
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 4),
                      blurRadius: 4,
                      color: Color(0xFF000000),
                    )
                  ],
                ),
              ),
            ],
          ),
          
        ),
        ),
        
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Alert Options:',
              textAlign: TextAlign.center,
                style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Candal',
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white, // Set the underline color to white
              ),
            ),
            const SizedBox(height: 50),
          


            //const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              SizedBox(
                  width: 150,
                  child: Text(
                    'Flashlight',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Candal',
                    fontSize: 20,
                    ),
                  ),
              ),
              const SizedBox(width: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300], // Default background color for unselected state
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4), // Optional padding
                child: ToggleButtons(
                isSelected: isSelected2,
                onPressed: (index) {
                  setState(() {
                      isSelected2 = [index == 0, index == 1]; // Toggle state
                      // Call vibration function directly when "On" is selected
                      if (index == 0 && !isFlashlightOn) {
                        _toggleFlashlight(); // Turn on flashlight
                      } else if (index == 1 && isFlashlightOn) {
                        _toggleFlashlight(); // Turn off flashlight
                      }
            });
                  },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white, // Text color when selected
                fillColor: Colors.transparent, // Make default fill color transparent
                color: const Color(0xFF0251D3), // Default text color
                disabledColor: Colors.grey,
                renderBorder: false,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: isSelected2[0] ? const Color(0xFF8BFFA4) : Colors.transparent, // Green if selected
                    ),
                    child: SizedBox(
                      width: 30,
                      child: Text(
                        'On',
                        textAlign: TextAlign.center, 
                        style: TextStyle(
                        fontFamily: 'Candal',
                        color: isSelected2[0] ? Colors.white : Colors.transparent, // Ensures text is visible on green
                      ),
                      )
                      
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: isSelected2[1] ? Colors.red : Colors.transparent, // Red if selected
                    ),
                    child: SizedBox(
                      width: 30,
                      child: Text(
                        'Off',
                        textAlign: TextAlign.center, 
                        style: TextStyle(
                        fontFamily: 'Candal',
                        color: isSelected2[1] ? Colors.white : Colors.transparent, // Ensures text is visible on green
                      ),
                      )
                      
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),


            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              SizedBox(
                  width: 150,
                  child: Text(
                    'Vibration',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Candal',
                    fontSize: 20,
                    ),
                  ),
              ),
              const SizedBox(width: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300], // Default background color for unselected state
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4), // Optional padding
                child: ToggleButtons(
                isSelected: isSelected3,
                onPressed: (index) {
                  setState(() {
                      isSelected3 = [index == 0, index == 1]; // Toggle state
                      if (index == 0) {
                        _vibratePhone();
                      }
                      else{
                        _stopVibration();
                      }
                     });
                  },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white, // Text color when selected
                fillColor: Colors.transparent, // Make default fill color transparent
                color: const Color(0xFF0251D3), // Default text color
                disabledColor: Colors.grey,
                renderBorder: false,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: isSelected3[0] ? const Color(0xFF8BFFA4) : Colors.transparent, // Green if selected
                    ),
                    child: SizedBox(
                      width: 30,
                      child: Text(
                        'On',
                        textAlign: TextAlign.center, 
                        style: TextStyle(
                        fontFamily: 'Candal',
                        color: isSelected3[0] ? Colors.white : Colors.transparent, // Ensures text is visible on green
                      ),
                      )
                      
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: isSelected3[1] ? Colors.red : Colors.transparent, // Red if selected
                    ),
                    child: SizedBox(
                      width: 30,
                      child: Text(
                        'Off',
                        textAlign: TextAlign.center, 
                        style: TextStyle(
                        fontFamily: 'Candal',
                        color: isSelected3[1] ? Colors.white : Colors.transparent, // Ensures text is visible on green
                      ),
                      )
                      
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
            const SizedBox(height: 50), // Add some space between the counter and button
           Center(
            child: Row(
              mainAxisSize: MainAxisSize.min, // Makes the Row take the minimum required width
              mainAxisAlignment: MainAxisAlignment.center, // Centers the buttons
              children: [
                ElevatedButton(
                  onPressed: buttonsEnabled 
                    ? () {
                        setState(() {
                          isSelected1 = [true, false]; // Enable "Yes" for Screen
                          isSelected2 = [true, false]; // Enable "Yes" for Flashlight
                          isSelected3 = [true, false]; // Enable "Yes" for Vibration
                        });

                        _toggleFlashlight(); // Call your flashlight activation function
                        _vibratePhone(); // Start vibration
                    }
                    : null, // Disables the button when `buttonsEnabled` is false
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9), // Button background color
                    shape: RoundedRectangleBorder(
                      //borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                  ),
                  child: const Text('Enable All', style: TextStyle(color: Color(0xFF0251D3), fontFamily: 'Candal',)),
                ),
                const SizedBox(width: 30), 
                ElevatedButton(
                  onPressed: buttonsEnabled 
                    ? () {
                        setState(() {
                          isSelected1 = [false, true]; // Enable "No" for Screen
                          isSelected2 = [false, true]; // Enable "No" for Flashlight
                          isSelected3 = [false, true]; // Enable "No" for Vibration
                        });

                        _stopVibration(); // Stop vibration
                        _toggleFlashlight(); // Turn off flashlight

                    }
                    : null, // Disables the button when `buttonsEnabled` is false
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9), // Button background color
                    shape: RoundedRectangleBorder(

                    ),
                  ),
                  child: const Text('Disable All', style: TextStyle(color: Color(0xFF0251D3), fontFamily: 'Candal',)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50), 
          Image.asset(
            './assets/images/HearoLogo.png', // Replace with your actual asset path
            height: 100, // Adjust size as needed
         ),
        
            const SizedBox(height: 20), // Add some space between buttons
            ElevatedButton(
              onPressed: toggleRecording, // Start/Stop recording
              child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
          ],
        ),
      ),
    );
  }
}


