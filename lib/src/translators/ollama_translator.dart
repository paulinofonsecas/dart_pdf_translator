import 'dart:convert';
import 'package:http/http.dart' as http;
import 'translator.dart';

/// A translator that uses a local Ollama instance.
class OllamaTranslator implements Translator {
  final String apiUrl;
  final String modelName;

  /// Creates a new Ollama translator.
  ///
  /// [apiUrl] is the base URL of the Ollama API (e.g., 'http://localhost:11434').
  /// [modelName] is the name of the model to use for translation (e.g., 'llama3').
  OllamaTranslator({
    required this.apiUrl,
    required this.modelName,
  });

  /// Translates a given text to the target language using a local Ollama instance.
  ///
  /// [text] The text to translate.
  /// [targetLanguage] The language to translate the text into (e.g., "Portuguese", "English").
  /// Returns the translated text as a string.
  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    final prompt =
        'Translate the following text to $targetLanguage. Only return the translated text, without any introductory phrases, formatting, or explanations:\n\n---\n\n$text';

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'model': modelName,
      'prompt': prompt,
      'stream': false, // We want the full response at once
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/generate'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        final content = decodedBody['response'] as String?;
        return content?.trim() ?? 'Could not get a valid translation from Ollama.';
      } else {
        throw Exception(
            'Ollama API returned an error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during Ollama translation: $e');
    }
  }
}
