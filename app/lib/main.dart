import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart'; // Import the vibration package
import 'package:flutter_background/flutter_background.dart';
import 'package:app/background.dart'; // Import the background task file
import 'package:torch_light/torch_light.dart';
import 'API/Client.dart'; // Import the vibration package
import 'audiorec.dart';  // Import the audio recorder service
bool buttonsEnabled = true;
bool isFlashlightOn = false;
bool isVibrating = false;
void main() async {
  runApp(MyApp());
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

class _MyHomePageState extends State<MyHomePage> {
  List<bool> isSelected1 = [true, false];
  List<bool> isSelected2 = [false, true];
  List<bool> isSelected3 = [false, true];

  final AudioRecorderService _audioRecorder = AudioRecorderService(); // Initialize audio recorder
  bool isRecording = false;
  AudioUploader MyClient = AudioUploader(serverUrl: '10.0.2.2:5000');
  @override
  void initState() {
    super.initState();
    _startRecordingOnLaunch();  // Start recording when the app launches
    MyClient.connectToServer();  // Connect to the server on startup
  }

  // Automatically start recording when the app starts
  Future<void> _startRecordingOnLaunch() async {
    while(true) {
      await _audioRecorder.startRecording();
      setState(() {isRecording = true;});
      await Future.delayed(const Duration(seconds: 6));
      final path = await _audioRecorder.stopRecording();
      if(path == null) {print("there was an error and it didnt return a file path"); return;}
      //add logic here 
      MyClient.uploadAudioFile(path);
      print('Recording saved at: $path');
      setState(() => isRecording = false);
    }
  }

  void _toggleSelection(List<bool> list, int index) {
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
  
  // Start/Stop recording function
  Future<void> _toggleRecording() async {
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

                      // Call vibration function directly when "On" is selected
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
              onPressed: _toggleRecording, // Start/Stop recording
              child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
          ],
        ),
      ),
    );
  }
}


