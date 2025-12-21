/// An abstract interface for translation services.
///
/// Implementations of this class should provide a method to translate text
/// from a source language to a target language.
abstract class Translator {
  /// Translates the given [text] to the [targetLanguage].
  ///
  /// Returns the translated text as a [Future<String>].
  Future<String> translate({
    required String text,
    required String targetLanguage,
  });
}
