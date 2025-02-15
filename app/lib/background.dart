import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';

// Background task
class BackgroundTaskScreen extends StatefulWidget {
  const BackgroundTaskScreen({super.key});

  @override
  _BackgroundTaskScreenState createState() => _BackgroundTaskScreenState();
}

// State of the background task
class _BackgroundTaskScreenState extends State<BackgroundTaskScreen> {
  bool _isRunning = false;
  Timer? _timer;

  void _startBackgroundTask() async {
    print("Starting background task");

    // Check if plugin is initialized
    bool isInitialized = FlutterBackground.isBackgroundExecutionEnabled;
    if (!isInitialized) {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "Background Task",
        notificationText: "Listening for sounds...",
        notificationImportance: AndroidNotificationImportance.normal,
        enableWifiLock: true,
      );

      bool hasPermissions =
          await FlutterBackground.initialize(androidConfig: androidConfig);
      if (!hasPermissions) {
        print("Failed to initialize background task");
        return;
      }
    }

    bool success = await FlutterBackground.enableBackgroundExecution();
    print("Background task enabled: $success");
    if (success) {
      setState(() {
        _isRunning = true;
      });

      _timer = Timer.periodic(Duration(seconds: 5), (timer) {
        print("Background task running: ${DateTime.now()}");
      });
    } else {
      print("Failed to enable background task");
    }
  }

  void _stopBackgroundTask() {
    print("Stopping background task");
    _timer?.cancel();
    FlutterBackground.disableBackgroundExecution();
    setState(() {
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(title: Text("Background Task Example")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRunning ? "Task Running..." : "Task Stopped",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _isRunning ? _stopBackgroundTask : _startBackgroundTask,
              child: Text(_isRunning ? "Stop Task" : "Start Task"),
            ),
          ],
        ),
      ),
    );
  }
}
