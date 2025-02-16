import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart'; 

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

  Future<String> uploadAudioFile(String filePath) async {
    try {
      File file = File(filePath);
      print("Uploading $file");
      if (!file.existsSync()) {
        print("File not found at $filePath");
        return "No file found";
      }

      String? mimeType = mime(filePath);
      print("mimetype is $mimeType");
      if (mimeType == null) {print("Error with mimetype");return "ERROR";};
      // if (mimeType == null || !mimeType.startsWith("audio")) {
      //   print("The file is not a valid audio file");
      //   return "invalid audio file";
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

      // Read the response body
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print("File uploaded successfully!");
        print("Server response: $responseBody");
        return responseBody;
      } 
      else {
        print("Failed to upload file. Status code: ${response.statusCode}");
        String responseBody = await response.stream.bytesToString();
        print("Server response: $responseBody");
        return "Failed to Upload";
      }
    } catch (e) {
      print("Error while uploading file: $e");
      return "error";
    }
  }

}
