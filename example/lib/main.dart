import 'dart:io';
import 'package:flutter/material.dart';

// --- Dependencies for the example app ---
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// --- Dependencies from the parent package ---
import 'package:dart_pdf_translator/dart_pdf_translator.dart';
import 'package:dotenv/dotenv.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Translator Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // --- State Variables ---
  String _status = 'Pick a PDF file to begin translation.';
  String _translatedMarkdown = '';
  bool _isLoading = false;

  /// Picks a PDF, extracts its text, translates it, and updates the UI.
  Future<void> _pickAndTranslatePdf() async {
    // 1. Reset state and start loading
    setState(() {
      _isLoading = true;
      _translatedMarkdown = '';
      _status = 'Picking file...';
    });

    // 2. Pick a PDF file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      setState(() {
        _isLoading = false;
        _status = 'File picking cancelled.';
      });
      return;
    }

    final filePath = result.files.single.path!;
    final fileName = result.files.single.name;

    try {
      // 3. Initialize the translator
      // For this example, we use the Gemini translator.
      // It reads the .env file from the PARENT directory.
      setState(() => _status = 'Initializing translator...');
      final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);
      final apiKey = env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
        throw Exception('GEMINI_API_KEY is not configured in ../.env');
      }
      final translator = GeminiTranslator(apiKey);

      // 4. Extract text from the PDF using a Flutter-compatible library
      setState(() => _status = 'Extracting text from PDF...');
      final pages = await _extractTextFromPdf(filePath);
      if (pages.isEmpty) {
        throw Exception('Could not extract any text from the PDF.');
      }

      // 5. Translate page by page
      final translatedPages = <String>[];
      for (int i = 0; i < pages.length; i++) {
        setState(() {
          _status = 'Translating page ${i + 1} of ${pages.length}...';
        });
        final pageText = pages[i];
        if (pageText.trim().isEmpty) {
          translatedPages.add('');
          continue;
        }
        final translatedText = await translator.translate(
          text: pageText,
          targetLanguage: 'English', // Hardcoded for the example
        );
        translatedPages.add(translatedText);
      }

      // 6. Format and display the final Markdown output
      final markdownOutput = _formatAsMarkdown(translatedPages, fileName);
      setState(() {
        _translatedMarkdown = markdownOutput;
        _status = 'Translation complete!';
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _status = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  /// Extracts text from a PDF file using the syncfusion_flutter_pdf package.
  /// This implementation is specific to the Flutter example app.
  Future<List<String>> _extractTextFromPdf(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    
    final List<String> pageTexts = [];
    for (int i = 0; i < document.pages.count; i++) {
      final String text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      pageTexts.add(text);
    }
    document.dispose();
    return pageTexts;
  }

  /// Formats the translated pages into a single Markdown string.
  String _formatAsMarkdown(List<String> pages, String originalFileName) {
    final buffer = StringBuffer();
    buffer.writeln('# Translation of: $originalFileName');
    buffer.writeln();

    for (int i = 0; i < pages.length; i++) {
      buffer.writeln('## Page ${i + 1}');
      buffer.writeln();
      buffer.writeln(pages[i]);
      buffer.writeln();
      if (i < pages.length - 1) {
        buffer.writeln('---');
        buffer.writeln();
      }
    }
    return buffer.toString();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('PDF Translator Example'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // --- Status and Loading Indicator ---
              if (_isLoading)
                const CircularProgressIndicator()
              else
                const Icon(Icons.picture_as_pdf, size: 60, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              
              // --- Translated Content ---
              if (_translatedMarkdown.isNotEmpty)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Markdown(
                      data: _translatedMarkdown,
                      selectable: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickAndTranslatePdf,
        tooltip: 'Pick PDF',
        icon: const Icon(Icons.file_upload),
        label: const Text('Pick PDF'),
        backgroundColor: _isLoading ? Colors.grey : Colors.deepPurple,
      ),
    );
  }
}