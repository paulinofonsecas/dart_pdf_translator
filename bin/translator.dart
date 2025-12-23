import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:args/args.dart';
import 'package:ai_dart_pdf_translator/src/translators/translator.dart';
import 'package:ai_dart_pdf_translator/src/cli.dart';
import 'package:ai_dart_pdf_translator/src/pdf_processor.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main(List<String> arguments) async {
  // --- 1. Load Configuration ---
  final env = DotEnv(includePlatformEnvironment: true)..load();

  final parser = ArgParser()
    ..addOption('input', abbr: 'i', help: 'Input PDF file path')
    ..addOption('output', abbr: 'o', help: 'Output file path (md or pdf)')
    ..addOption('target', abbr: 't', help: 'Target language (e.g., pt)')
    ..addOption('engine', help: 'Translation engine: gemini or ollama')
    ..addOption('api-key', help: 'API key for Gemini')
    ..addOption('gemini-model', help: 'Gemini model name')
    ..addOption('ollama-model', help: 'Ollama model name')
    ..addOption('ollama-url', help: 'Ollama API base URL (e.g., http://localhost:11434)')
    ..addOption('page-step', help: 'Process every Nth page', defaultsTo: '1')
    ..addOption('delay', help: 'Delay between page translations (seconds)', defaultsTo: '1')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('Argument error: ${e.toString()}');
    print(parser.usage);
    exit(64);
  }

  if (argResults['help'] as bool) {
    print('Usage: ai_pdf_translate [options]\n');
    print(parser.usage);
    exit(0);
  }

  final pdfPath = argResults['input'] as String? ?? (arguments.isNotEmpty ? arguments.first : 'sample.pdf');
  final outputPath = argResults['output'] as String? ?? '${pdfPath.split('.').first}_translated.md';
  final targetLanguage = argResults['target'] as String? ?? env['TARGET_LANGUAGE'] ?? 'English';
  final engine = (argResults['engine'] as String?) ?? env['TRANSLATION_ENGINE'] ?? 'gemini';
  final pageStep = int.tryParse(argResults['page-step'] as String) ?? int.tryParse(env['PAGE_STEP'] ?? '1') ?? 1;
  final translationDelay = Duration(seconds: int.tryParse(argResults['delay'] as String) ?? 1);

  print('--- PDF Translator Initialized ---');
  print('Translation Engine: $engine');
  print('Target Language:    $targetLanguage');
  print('PDF File:           $pdfPath');
  print('Output File:        $outputPath');
  print('Translation Delay:  ${translationDelay.inSeconds} seconds');
  print('Page Step:          $pageStep');
  print('------------------------------------');

  // --- 2. Prepare merged config and initialize translator ---
  final config = <String, String>{};
  // populate from env
  for (final key in ['TRANSLATION_ENGINE', 'TARGET_LANGUAGE', 'GEMINI_API_KEY', 'GEMINI_MODEL', 'OLLAMA_API_URL', 'OLLAMA_MODEL', 'PAGE_STEP']) {
    final v = env[key];
    if (v != null) config[key] = v;
  }
  // overrides from args
  if (argResults['api-key'] != null) config['GEMINI_API_KEY'] = argResults['api-key'] as String;
  if (argResults['gemini-model'] != null) config['GEMINI_MODEL'] = argResults['gemini-model'] as String;
  if (argResults['ollama-url'] != null) config['OLLAMA_API_URL'] = argResults['ollama-url'] as String;
  if (argResults['ollama-model'] != null) config['OLLAMA_MODEL'] = argResults['ollama-model'] as String;
  config['TRANSLATION_ENGINE'] = engine;
  config['TARGET_LANGUAGE'] = targetLanguage;

  Translator translator;
  try {
    translator = getTranslator(config);
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
    print('You can specify a different file with --input or provide the path as first argument.');
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
  for (int i = 0; i < pages.length; i += pageStep) {
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
      print('  - Skipping.');
      continue;
    }
  }
  print('✅ pages translated successfully.');

  // --- 5. Save the translated content to output (md or pdf) ---
  try {
    if (outputPath.toLowerCase().endsWith('.pdf')) {
      final doc = pw.Document();
      for (int i = 0; i < translatedPages.length; i++) {
        final text = translatedPages[i];
        doc.addPage(pw.Page(build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(children: [
              pw.Text('Translation of: $pdfPath', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Page ${i + 1}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(text),
            ]),
          );
        }));
      }

      final outFile = File(outputPath);
      await outFile.writeAsBytes(await doc.save());
      print('\n--- Translation Complete! ---');
      print('Translated PDF saved to: $outputPath');
    } else {
      final outputFile = File(outputPath);
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
      print('Translated content saved to: $outputPath');
    }
  } catch (e) {
    print('Error saving the output file: ${e.toString()}');
    exit(1);
  }
}

// Translator initialization is provided by `lib/src/cli.dart` (getTranslator).
