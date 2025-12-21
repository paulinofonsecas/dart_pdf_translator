import 'package:google_generative_ai/google_generative_ai.dart';
import 'translator.dart';

/// A translator that uses the Google Gemini API.
class GeminiTranslator implements Translator {
  final GenerativeModel _model;

  /// Creates a new Gemini translator with the given [apiKey] and optional [modelName].
  GeminiTranslator(String apiKey, {String modelName = 'gemini-2.5-flash'})
      : _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(maxOutputTokens: 8000), // Increased token limit for larger pages
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
          ],
        );

  /// Translates a given text to the target language using the Gemini API.
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

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Could not get a valid translation from Gemini.';
    } catch (e) {
      // Re-throw a more specific error
      throw Exception('Error during Gemini translation: $e');
    }
  }
}
