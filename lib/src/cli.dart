import 'package:ai_dart_pdf_translator/src/translators/translator.dart';
import 'package:ai_dart_pdf_translator/src/translators/gemini_translator.dart';
import 'package:ai_dart_pdf_translator/src/translators/ollama_translator.dart';

/// Returns a configured [Translator] based on the provided [config].
///
/// Expected keys in [config]:
/// - `TRANSLATION_ENGINE`: 'gemini' or 'ollama' (defaults to 'gemini')
/// - `GEMINI_API_KEY`, `GEMINI_MODEL`
/// - `OLLAMA_API_URL`, `OLLAMA_MODEL`
Translator getTranslator(Map<String, String> config) {
  final engine = config['TRANSLATION_ENGINE']?.toLowerCase() ?? 'gemini';

  switch (engine) {
    case 'gemini':
      final apiKey = config['GEMINI_API_KEY'];
      final modelName = config['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
      if (apiKey == null || apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found. It is required when TRANSLATION_ENGINE is "gemini".');
      }
      return GeminiTranslator(apiKey, modelName: modelName);
    case 'ollama':
      final apiUrl = config['OLLAMA_API_URL'];
      final modelName = config['OLLAMA_MODEL'];
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('OLLAMA_API_URL not found. It is required when TRANSLATION_ENGINE is "ollama".');
      }
      if (modelName == null || modelName.isEmpty) {
        throw Exception('OLLAMA_MODEL not found. It is required when TRANSLATION_ENGINE is "ollama".');
      }
      return OllamaTranslator(apiUrl: apiUrl, modelName: modelName);
    default:
      throw Exception('Invalid TRANSLATION_ENGINE: "$engine". Please use "gemini" or "ollama".');
  }
}
