import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'API/Client.dart'; // Import the vibration package
import 'package:vibration/vibration.dart'; // Import the vibration package
import 'audiorec.dart';  // Import the audio recorder service
import 'package:flutter_background/flutter_background.dart';
import 'package:app/background.dart'; // Import the background task file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Background Task",
    notificationText: "Listening for sounds...",
    notificationImportance: AndroidNotificationImportance.normal,
    enableWifiLock: true,
  );

  bool hasPermissions =
      await FlutterBackground.initialize(androidConfig: androidConfig);

  if (hasPermissions) {
    await FlutterBackground.enableBackgroundExecution();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vibration Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Vibration App'),
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
  List<bool> isSelected2 = [true, false];
  List<bool> isSelected3 = [true, false];

  final AudioRecorderService _audioRecorder = AudioRecorderService(); // Initialize audio recorder
  bool isRecording = false;

  void _toggleSelection(List<bool> list, int index) {
    setState(() {
      for (int i = 0; i < list.length; i++) {
        list[i] = (i == index);
      }
    });
  }
  void _vibratePhone() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500); // Vibrates for 500 milliseconds
    }
  }
  AudioUploader MyClient = AudioUploader(serverUrl: 'localhost:5000/upload');

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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Do you agree?'),
            const SizedBox(height: 10),
            ToggleButtons(
              isSelected: isSelected1,
              onPressed: (index) => _toggleSelection(isSelected1, index),
              borderRadius: BorderRadius.circular(10),
              selectedColor: Colors.white,
              fillColor: Colors.deepPurple,
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Yes'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ToggleButtons(
              isSelected: isSelected2,
              onPressed: (index) => _toggleSelection(isSelected2, index),
              borderRadius: BorderRadius.circular(10),
              selectedColor: Colors.white,
              fillColor: Colors.deepPurple,
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Yes'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ToggleButtons(
              isSelected: isSelected3,
              onPressed: (index) => _toggleSelection(isSelected3, index),
              borderRadius: BorderRadius.circular(10),
              selectedColor: Colors.white,
              fillColor: Colors.deepPurple,
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Yes'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No'),
                ),
              ],
            ),
            const SizedBox(
                height: 20), // Add some space between the counter and button
            ElevatedButton(
              onPressed: _vibratePhone, // Vibrates the phone on button press
              child: const Text('Vibrate Phone'),
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