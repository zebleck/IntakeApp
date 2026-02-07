import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static Future<String?> extractUrlFromImage(Uint8List imageBytes) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not set. '
        'Build with --dart-define=GEMINI_API_KEY=your_key',
      );
    }

    final base64Image = base64Encode(imageBytes);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-3-flash-preview:generateContent?key=$_apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Extract any URL from this image. Return only the URL, '
                    'nothing else. If no URL is found, return NONE.',
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                },
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return null;
    }

    final parts = (candidates[0] as Map<String, dynamic>)['content']
        ['parts'] as List<dynamic>;
    final text = (parts[0] as Map<String, dynamic>)['text'] as String;
    final trimmed = text.trim();

    if (trimmed.toUpperCase() == 'NONE' || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
