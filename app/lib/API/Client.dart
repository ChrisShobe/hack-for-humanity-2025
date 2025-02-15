import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';  // Updated import for MIME type detection

class AudioUploader {
  final String serverUrl;
  AudioUploader({required this.serverUrl});
  Future<void> uploadAudioFile(String filePath) async {
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        print("File not found at $filePath");
        return;
      }
      String? mimeType = mime(filePath);
      if (mimeType == null || !mimeType.startsWith("audio")) {
        print("The file is not a valid audio file");
        return;
      }
      var request = http.MultipartRequest(
        'POST', Uri.parse(serverUrl)
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
