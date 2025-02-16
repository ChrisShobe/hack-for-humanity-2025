import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';

class AudioUploader {
  final String serverUrl;

  AudioUploader({required this.serverUrl});

  Future<void> connectToServer() async {
    try {
      print("GET RQUEST TO http://$serverUrl");
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

  Future<String> uploadAudioFile(String filePath) async {
    try {
      File file = File(filePath);
      print("Uploading $file");

      if (!file.existsSync()) {
        print("File not found at $filePath");
        return "No file found";
      }

      String? mimeType = mime(filePath);
      // Manually set MIME type if you want to override it
      if (filePath.endsWith('.wav')) {
        mimeType = 'audio/wav';
      } else if (filePath.endsWith('.mp3')) {
        mimeType = 'audio/mpeg';
      }

      // Optional: Add more conditions for other file types if needed
      print("Mime type is $mimeType");

      if (mimeType == null) {
        print("Error with mimeType");
        return "ERROR";
      }

      final String serverUrlWithScheme = "http://$serverUrl/upload"; // Add "http://" if not present
      print("Server URL is $serverUrlWithScheme");

      var request = http.MultipartRequest(
        'POST', Uri.parse(serverUrlWithScheme),
      );

      var fileStream = http.MultipartFile.fromBytes(
        'file',
        file.readAsBytesSync(),
        filename: file.uri.pathSegments.last,
        contentType: MediaType.parse(mimeType!),
      );

      print("Request sent to $serverUrlWithScheme");

      // Add file to the request
      request.files.add(fileStream);

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        print("File uploaded successfully!");

        // Read the response body if needed
        var responseBody = await response.stream.bytesToString();
        print("Server response: $responseBody");
        return responseBody;
      } else {
        print("Failed to upload file. Status code: ${response.statusCode}");

        // Read the response body if needed
        var responseBody = await response.stream.bytesToString();
        print("Server response: $responseBody");
        return "Failed to upload";
      }
    } catch (e) {
      print("Error while uploading file: $e");
      return "Error";
    }
  }
}
