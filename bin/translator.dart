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
    ..addOption('delay', help: 'Delay between page translations (seconds)', defaultsTo: '0')
    ..addOption('parallel', help: 'Number of parallel translations (default: 1)', defaultsTo: '1')
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
  final translationDelay = Duration(seconds: int.tryParse(argResults['delay'] as String) ?? int.tryParse(env['TRANSLATION_DELAY'] ?? '0') ?? 0);
  final parallelCount = int.tryParse(argResults['parallel'] as String) ?? 1;

  print('--- PDF Translator Initialized ---');
  print('Translation Engine: $engine');
  print('Target Language:    $targetLanguage');
  print('PDF File:           $pdfPath');
  print('Output File:        $outputPath');
  if (translationDelay.inSeconds > 0) {
    print('Translation Delay:  ${translationDelay.inSeconds} seconds');
  }
  // Page-step option removed; always translating every page.
  if (parallelCount > 1) {
    print('Parallel Tasks:     $parallelCount');
  }
  print('------------------------------------');

  // --- 2. Prepare merged config and initialize translator ---
  final config = <String, String>{};
  // populate from env
  for (final key in ['TRANSLATION_ENGINE', 'TARGET_LANGUAGE', 'GEMINI_API_KEY', 'GEMINI_MODEL', 'OLLAMA_API_URL', 'OLLAMA_MODEL']) {
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

  // --- 4. Translate pages with support for parallelism ---
  final translatedPages = List<String?>.filled(pages.length, null);
  final totalPages = pages.length;
  final pagesToTranslate = <int>[]; // Collect pages to translate (all pages)

  for (int i = 0; i < totalPages; i++) {
    pagesToTranslate.add(i);
  }

  print('📄 Pages to translate: ${pagesToTranslate.length} out of $totalPages');
  
  // Process pages in parallel if requested
  if (parallelCount > 1) {
    // Parallel processing
    final futures = <Future<void>>[];
    final semaphore = _Semaphore(parallelCount);
    
    int translatedCount = 0;
    for (final pageIndex in pagesToTranslate) {
      futures.add(semaphore.acquire(() async {
        final pageNumber = pageIndex + 1;
        final pageText = pages[pageIndex];
        
        if (pageText.trim().isEmpty) {
          print('  - Page $pageNumber is empty, skipping.');
          translatedPages[pageIndex] = '';
          return;
        }
        
        print('  ⟳ Translating page $pageNumber of $totalPages...');
        try {
          if (translationDelay.inSeconds > 0) {
            await Future.delayed(translationDelay);
          }
          final translatedText = await translator.translate(
            text: pageText,
            targetLanguage: targetLanguage,
          );
          translatedPages[pageIndex] = translatedText;
          print('    ✅ Pages translated successfully.');
        } catch (e) {
          print('  - ❌ Error translating pages : ${e.toString()}');
          translatedPages[pageIndex] = '';
        }
      }));
    }
    
    await Future.wait(futures);
    translatedCount = pagesToTranslate.length;
    print('✅ Translation complete! $translatedCount pages translated successfully (parallel mode).');
    } else {
    // Sequential processing
    int translatedCount = 0;
    for (int i = 0; i < totalPages; i++) {
      final pageNumber = i + 1;
      final pageText = pages[i];
      if (pageText.trim().isEmpty) {
        print('  - Page $pageNumber is empty, skipping.');
        translatedPages[i] = '';
        continue;
      }

      translatedCount++;
      print('  ⟳ Translating page $pageNumber of $totalPages (translation $translatedCount of ${pagesToTranslate.length})...');
      try {
        if (translationDelay.inSeconds > 0) {
          await Future.delayed(translationDelay);
        }
        final translatedText = await translator.translate(
          text: pageText,
          targetLanguage: targetLanguage,
        );
        translatedPages[i] = translatedText;
        print('    ✅ Page $pageNumber translated successfully.');
      } catch (e) {
        print('  - ❌ Error translating page $pageNumber: ${e.toString()}');
        translatedPages[i] = '';
      }
    }
    print('✅ Translation complete! $translatedCount pages translated successfully.');
  }

  // Convert nulls to empty strings
  final finalPages = translatedPages.map((p) => p ?? '').toList();
  // Replace any truly-empty pages with the original extracted text when available,
  // or a short placeholder explaining why the page is empty.
  for (int i = 0; i < finalPages.length; i++) {
    if (finalPages[i].trim().isEmpty) {
      if (pages[i].trim().isNotEmpty) {
        finalPages[i] = pages[i];
      } else {
        finalPages[i] = '_[No text extracted from page ${i + 1}. The page may contain images or scanned content.]_';
      }
    }
  }

  // --- 5. Save the translated content to output (md or pdf) ---
  try {
    if (outputPath.toLowerCase().endsWith('.pdf')) {
      final doc = pw.Document();
      for (int i = 0; i < finalPages.length; i++) {
        final text = finalPages[i];
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

      for (int i = 0; i < finalPages.length; i++) {
        markdownBuffer.writeln('## Page ${i + 1}');
        markdownBuffer.writeln();
        markdownBuffer.writeln(finalPages[i]);
        markdownBuffer.writeln();
        if (i < finalPages.length - 1) {
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
/// Simple semaphore implementation for limiting concurrent async operations
class _Semaphore {
  final int _max;
  int _count = 0;

  _Semaphore(this._max);

  Future<T> acquire<T>(Future<T> Function() fn) async {
    while (_count >= _max) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    _count++;
    try {
      return await fn();
    } finally {
      _count--;
    }
  }
}