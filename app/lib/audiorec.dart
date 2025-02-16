import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  final _key = encrypt.Key.fromUtf8('your32characterlongencryptionkey'); // AES key (32 chars for AES-256)
  final _iv = encrypt.IV.fromLength(16); // Initialization Vector (IV)

  // Start the recording process
  Future<void> startRecording() async {
    try {
      // Get the external storage directory (use getExternalStorageDirectory for Android)
      final directory = await getExternalStorageDirectory();

      if (directory != null) {
        // Construct the path where you want to save the audio file
        final path = '${directory.path}/recording.wav'; 
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
        if (path != null) {
          print("Recording saved at: $path");
          return await encryptFile(path); // Encrypt the file before returning
        }
      }
      return null;
    } catch (e) {
      print("Error stopping recording: $e");
      return null;
    }
  }

  // Encrypt the recorded file
  Future<String> encryptFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    final encryptedData = encrypter.encryptBytes(bytes, iv: _iv);

    // Save the encrypted file with an ".enc" extension
    final encryptedFilePath = '$filePath.enc';
    final encryptedFile = File(encryptedFilePath);
    await encryptedFile.writeAsBytes(encryptedData.bytes);

    print("File encrypted at: $encryptedFilePath");

    // Optionally, you can delete the original file after encryption
    await file.delete(); // Delete the original file
    print("Original file deleted at: $filePath");

    return encryptedFilePath;
  }

  bool get isRecording => _isRecording;
}