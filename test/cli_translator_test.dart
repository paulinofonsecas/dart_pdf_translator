import 'package:test/test.dart';
import 'package:ai_dart_pdf_translator/src/cli.dart';
import 'package:ai_dart_pdf_translator/src/translators/gemini_translator.dart';
import 'package:ai_dart_pdf_translator/src/translators/ollama_translator.dart';

void main() {
  group('getTranslator', () {
    test('throws when gemini selected but API key missing', () {
      final config = {'TRANSLATION_ENGINE': 'gemini'};
      expect(() => getTranslator(config), throwsA(isA<Exception>()));
    });

    test('returns GeminiTranslator when gemini config provided', () {
      final config = {'TRANSLATION_ENGINE': 'gemini', 'GEMINI_API_KEY': 'fake-key'};
      final translator = getTranslator(config);
      expect(translator, isA<GeminiTranslator>());
    });

    test('throws when ollama selected but config missing', () {
      final config = {'TRANSLATION_ENGINE': 'ollama'};
      expect(() => getTranslator(config), throwsA(isA<Exception>()));
    });

    test('returns OllamaTranslator when ollama config provided', () {
      final config = {
        'TRANSLATION_ENGINE': 'ollama',
        'OLLAMA_API_URL': 'http://localhost:11434',
        'OLLAMA_MODEL': 'mistral'
      };
      final translator = getTranslator(config);
      expect(translator, isA<OllamaTranslator>());
    });
  });
}
