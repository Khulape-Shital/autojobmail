// lib/services/gemini_chat_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiChatService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<String> getGeminiResponse(String userMessage) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": userMessage}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] ??
          "No reply.";
    } else {
      print("Error: ${response.body}");
      throw Exception("Failed to fetch Gemini response.");
    }
  }
}
