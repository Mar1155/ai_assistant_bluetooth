// lib/services/chatgpt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatGPTService {
  // Replace with your actual API key in a secure way in production
  static const String _apiKey = 'sk-your_fake_api_key_here';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Method to get assistance for an error code
  Future<String> getAssistanceForError({
    required String errorCode,
    required String errorDescription,
    required String manualText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that helps users understand and fix issues with their machinery. You have been provided with the machine\'s manual and should use it to provide accurate assistance.'
            },
            {
              'role': 'user',
              'content': 'I have encountered error code $errorCode with the following description: "$errorDescription". Here is the relevant section from the manual: $manualText. Please explain what this error means and how I can resolve it.'
            }
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Error communicating with AI assistant. Please try again later.\nStatus code: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error communicating with AI assistant: $e';
    }
  }

  // Method to get general assistance
  Future<String> getGeneralAssistance({
    required String question,
    required String manualText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that helps users understand and operate their machinery. You have been provided with the machine\'s manual and should use it to provide accurate assistance.'
            },
            {
              'role': 'user',
              'content': 'I have a question about my machine: "$question". Here is the relevant section from the manual: $manualText. Please provide assistance.'
            }
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Error communicating with AI assistant. Please try again later.\nStatus code: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error communicating with AI assistant: $e';
    }
  }
}