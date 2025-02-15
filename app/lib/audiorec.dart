import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  // Start the recording process
  Future<void> startRecording() async {
    try {
      // Get the external storage directory (use getExternalStorageDirectory for Android)
      final directory = await getExternalStorageDirectory();

      if (directory != null) {
        // Construct the path where you want to save the audio file
        final path = '${directory.path}/recording.wav'; // Full path with file name

        // Check for microphone permission before starting recording
        if (await _recorder.hasPermission()) {
          // Create the RecordConfig object (you can add more settings to the config if needed)
          final config = RecordConfig(
            // You can specify options like sample rate, bitrate, etc., here
            // Example: sampleRate: 44100, bitRate: 128000,
          );

          // Pass the RecordConfig and path to the start method
          await _recorder.start(config, path: path);  // Provide both config and path
          _isRecording = true;
          print("Recording started at: $path");
        } else {
          print("Permission denied.");
        }
      } else {
        print("Failed to get external storage directory.");
      }
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  // Stop the recording
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        _isRecording = false;
        final path = await _recorder.stop();  // Stop and get the path where the file is saved
        print("Recording saved at: $path");
        return path; // Returns the path where the recording was saved
      }
      return null;
    } catch (e) {
      print("Error stopping recording: $e");
      return null;
    }
  }

  bool get isRecording => _isRecording;
}