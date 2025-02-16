import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';  // Updated import for MIME type detection

class AudioUploader {
  final String serverUrl;
  AudioUploader({required this.serverUrl});
  Future<void> connectToServer() async {
    try {
      final response = await http.get(Uri.parse('http://$serverUrl'));
      if (response.statusCode == 200) {
        print('Connected to server successfully!');
      } else {
        print('Failed to connect. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error connecting to server: $e');
    }
  }
  Future<void> uploadAudioFile(String filePath) async {
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        print("File not found at $filePath");
        return;
      }

      String? mimeType;
      mimeType = 'audio/wav';  // Set mime type to audio/wav

      // String? mimeType = mime(filePath);
      // if (mimeType == null || !mimeType.startsWith("audio")) {
      //   print("The file is not a valid audio file. The type is: $mimeType");
      //   return;
      // }

      // // Explicitly set the mimeType to audio/wav (or any desired audio type)
      // if (mimeType != 'audio/wav') {
      //   mimeType = 'audio/wav';  // Set mime type to audio/wav
      // }

      final String serverUrlWithScheme = "http://$serverUrl/upload";  // Add "http://" if not present
      var request = http.MultipartRequest(
        'POST', Uri.parse(serverUrlWithScheme)  // Append the /upload path
      );
      var fileStream = http.MultipartFile.fromBytes(
        'file',
        file.readAsBytesSync(),
        filename: file.uri.pathSegments.last,
        contentType: MediaType.parse(mimeType),
      );

      // Add file to the request
      request.files.add(fileStream);
      var response = await request.send();
      if (response.statusCode == 200) {
        print("File uploaded successfully!");
      } else {
        print("Failed to upload file. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error while uploading file: $e");
    }
  }
}
