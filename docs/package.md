# Using as a package

Import the public entrypoint to reuse `PdfProcessor` and `Translator` implementations in your app:

```dart
import 'package:ai_dart_pdf_translator/ai_dart_pdf_translator.dart';

Future<void> main() async {
  final processor = PopplerPdfProcessor();
  final pages = await processor.extractText('document.pdf');

  final translator = GeminiTranslator('YOUR_KEY');
  for (var i = 0; i < pages.length; i++) {
    final t = await translator.translate(text: pages[i], targetLanguage: 'Portuguese');
    print('--- Page ${i + 1} ---');
    print(t);
  }
}
```

Notes:

- Use `PopplerPdfProcessor` for CLI/desktop. For Flutter/mobile, implement your own processor strategy.
- Translators follow the `Translator` interface (see `lib/src/translators/translator.dart`).
