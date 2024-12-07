import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // For making HTTP requests

Future<Map<String, dynamic>> fetchDeck(String deckcode) async {
  try {
    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/app/deck"),
      headers: {
        'Content-Type': 'application/json',
        'token': 'from windows app',
      },
      body: jsonEncode({'deck': deckcode}),
    );

    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      final Directory directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}\\deck';
      
      // Get the image URL from the response
      String imageUrl = body['bgimageurl'];

      // Determine the file extension from the image URL
      String fileExtension = imageUrl.split('.').last.split('?').first;
      if (!['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
        // Default to PNG if the extension is not recognized
        fileExtension = 'png';
      }

      // Complete file path with extension
      filePath += '.$fileExtension';

      print('Saving image to: $filePath');

      // Download and save the image with the correct extension
      await Dio().download(imageUrl, filePath);

      print('Image successfully downloaded and saved.');

      return body;
    } else {
      // Return an error message for non-200 status codes
      return {'error': 'Deck not found! (${response.statusCode})'};
    }
  } catch (e) {
    // Return an error message for exceptions
    return {'error': 'Exception: $e'};
  }
}
