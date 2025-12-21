import 'dart:developer';

import 'package:test/test.dart';
import 'dart:io';
import 'package:ai_dart_pdf_translator/src/pdf_processor.dart';

void main() {
  group('PopplerPdfProcessor', () {
    final processor = PopplerPdfProcessor();
    // Use a sample PDF file for testing. You must provide a valid path for this test to pass.
    const samplePdf = 'test/assets/sample.pdf';

    setUpAll(() async {
      // Ensure the sample PDF exists for the test
      if (!await File(samplePdf).exists()) {
        throw Exception('Sample PDF not found at $samplePdf. Please add a test PDF.');
      }
    });

    test('extractText returns non-empty list for valid PDF', () async {
      final result = await processor.extractText(samplePdf);
      expect(result, isA<List<String>>());
      expect(result.isNotEmpty, isTrue);
      expect(result.first.trim(), isNotEmpty);
    });

    test('extractText supports page range', () async {
      final result = await processor.extractText(samplePdf, startPage: 1, endPage: 1);
      expect(result.length, 1);
      expect(result.first.trim(), isNotEmpty);
    });

    test('extractText supports page range', () async {
      final result = await processor.extractText(samplePdf, startPage: 1, endPage: 1, pagesPerBatch: 2);
      expect(result.length, 1);
      expect(result.first.trim(), isNotEmpty);
    });

    test('extractText throws for missing file', () async {
      expect(
        () => processor.extractText('test/assets/does_not_exist.pdf'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
