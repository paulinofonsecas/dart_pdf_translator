import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:ai_dart_pdf_translator/src/translators/translator.dart';
import 'package:ai_dart_pdf_translator/src/translators/gemini_translator.dart';
import 'package:ai_dart_pdf_translator/src/translators/ollama_translator.dart';
import 'package:ai_dart_pdf_translator/src/pdf_processor.dart';

Future<void> main(List<String> arguments) async {
  // --- 1. Load Configuration ---
  final env = DotEnv(includePlatformEnvironment: true)..load();

  final String engine = env['TRANSLATION_ENGINE'] ?? 'gemini';
  final String targetLanguage = env['TARGET_LANGUAGE'] ?? 'English';
  final String pdfPath = arguments.isNotEmpty ? arguments.first : 'sample.pdf';
  final translationDelay = Duration(seconds: 1);

  print('--- PDF Translator Initialized ---');
  print('Translation Engine: $engine');
  print('Target Language:    $targetLanguage');
  print('PDF File:           $pdfPath');
  print('Translation Delay:  ${translationDelay.inSeconds} seconds');
  print('------------------------------------');

  // --- 2. Initialize the correct translator based on config ---
  Translator translator;
  try {
    translator = _getTranslator(env);
  } catch (e) {
    print('Configuration Error: ${e.toString()}');
    exit(1);
  }

  // --- 3. Extract text from PDF ---
  print('\nReading PDF file...');
  List<String> pages;
  try {
    pages = await extractTextFromPdf(pdfPath);
  } on FileSystemException {
    print('Error: The file "$pdfPath" was not found.');
    print(
        'You can specify a different file by passing its path as an argument.');
    exit(1);
  } on Exception catch (e) {
    print('An error occurred during PDF processing:');
    print(e.toString());
    exit(1);
  }

  if (pages.isEmpty) {
    print('Could not extract any text from the PDF. Exiting.');
    exit(0);
  }
  print('✅ PDF read successfully. Found ${pages.length} pages.');

  // --- 4. Translate page by page ---
  final translatedPages = <String>[];
  for (int i = 0; i < pages.length; i++) {
    final pageText = pages[i];
    if (pageText.trim().isEmpty) {
      print('  - Page ${i + 1} is empty, skipping.');
      translatedPages.add('');
      continue;
    }

    print('  - Translating page ${i + 1} of ${pages.length}...');
    try {
      await Future.delayed(translationDelay);
      final translatedText = await translator.translate(
        text: pageText,
        targetLanguage: targetLanguage,
      );
      translatedPages.add(translatedText);
    } catch (e) {
      print('  - ❌ Error translating page ${i + 1}: ${e.toString()}');
      print('  - Skiping.');
      continue;
    }
  }
  print('✅ pages translated successfully.');

  // --- 5. Save the translated content to a Markdown file ---
  final outputFileName = '${pdfPath.split('.').first}_translated.md';
  try {
    final outputFile = File(outputFileName);

    final markdownBuffer = StringBuffer();
    markdownBuffer.writeln('# Translation of: $pdfPath');
    markdownBuffer.writeln();

    for (int i = 0; i < translatedPages.length; i++) {
      markdownBuffer.writeln('## Page ${i + 1}');
      markdownBuffer.writeln();
      markdownBuffer.writeln(translatedPages[i]);
      markdownBuffer.writeln();
      if (i < translatedPages.length - 1) {
        markdownBuffer.writeln('---');
        markdownBuffer.writeln();
      }
    }
    await outputFile.writeAsString(markdownBuffer.toString());
    print('\n--- Translation Complete! ---');
    print('Translated content saved to: $outputFileName');
  } catch (e) {
    print('Error saving the output file: ${e.toString()}');
    exit(1);
  }
}

/// Factory function to get the correct translator based on environment variables.
Translator _getTranslator(DotEnv env) {
  try {
    final engine = env['TRANSLATION_ENGINE']?.toLowerCase() ?? 'gemini';

    switch (engine) {
      case 'gemini':
        final apiKey = env['GEMINI_API_KEY'];
        final modelName = env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
        if (apiKey == null || apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
          throw Exception(
              'GEMINI_API_KEY not found or not set in .env file. It is required when TRANSLATION_ENGINE is "gemini".');
        }
        return GeminiTranslator(apiKey, modelName: modelName);
      case 'ollama':
        final apiUrl = env['OLLAMA_API_URL'];
        final modelName = env['OLLAMA_MODEL'];
        if (apiUrl == null || apiUrl.isEmpty) {
          throw Exception(
              'OLLAMA_API_URL not found in .env file. It is required when TRANSLATION_ENGINE is "ollama".');
        }
        if (modelName == null || modelName.isEmpty) {
          throw Exception(
              'OLLAMA_MODEL not found in .env file. It is required when TRANSLATION_ENGINE is "ollama".');
        }
        return OllamaTranslator(apiUrl: apiUrl, modelName: modelName);
      default:
        throw Exception(
            'Invalid TRANSLATION_ENGINE: "$engine". Please use "gemini" or "ollama".');
    }
  } catch (e) {
    throw Exception('Error initializing translator: ${e.toString()}');
  }
}
