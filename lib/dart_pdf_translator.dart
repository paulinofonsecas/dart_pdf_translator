/// A versatile command-line PDF translator.
///
/// This library provides utilities to extract text from PDF files and translate it
/// using either the Google Gemini API or a local Ollama instance.
library;

// Export the main functionality for programmatic use if needed.
// Note: The primary use of this package is via the command-line tool.
export 'src/pdf_processor.dart';
export 'src/translators/translator.dart';
export 'src/translators/gemini_translator.dart';
export 'src/translators/ollama_translator.dart';
