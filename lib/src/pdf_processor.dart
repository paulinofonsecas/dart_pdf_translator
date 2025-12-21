import 'dart:io';

/// Checks if the required Poppler command-line tools (`pdftotext` and `pdfinfo`)
/// are available in the system's PATH.
///
/// Returns `true` if both tools are found, `false` otherwise.
Future<bool> _checkPopplerTools() async {
  try {
    // Running with '-v' (version) is a lightweight way to check for existence
    // and executability without processing any files.
    await Process.run('pdftotext', ['-v']);
    await Process.run('pdfinfo', ['-v']);
    return true;
  } catch (e) {
    // A ProcessException is thrown if the command is not found.
    return false;
  }
}

/// Gets the total number of pages in a PDF file using the `pdfinfo` tool.
///
/// Throws an [Exception] if `pdfinfo` fails or if the page count cannot be parsed.
Future<int> _getPageCount(String filePath) async {
  final result = await Process.run('pdfinfo', [filePath]);
  if (result.exitCode != 0) {
    throw Exception('pdfinfo execution failed:\n${result.stderr}');
  }

  final lines = result.stdout.toString().split('\n');
  final pagesLine = lines.firstWhere(
    (line) => line.startsWith('Pages:'),
    orElse: () => '',
  );

  if (pagesLine.isEmpty) {
    throw Exception('Could not determine page count from pdfinfo output.');
  }

  return int.parse(pagesLine.split(':')[1].trim());
}


/// Abstract strategy for PDF text extraction.
abstract class PdfProcessorStrategy {
  Future<List<String>> extractText(
    String filePath, {
    int? startPage,
    int? endPage,
    int pagesPerBatch = 1,
  });
}

/// Poppler-based implementation of PdfProcessorStrategy.
class PopplerPdfProcessor implements PdfProcessorStrategy {
  @override
  Future<List<String>> extractText(
    String filePath, {
    int? startPage,
    int? endPage,
    int pagesPerBatch = 1,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException("File not found", filePath);
    }

    if (!await _checkPopplerTools()) {
      throw Exception(
          'Required Poppler tools (pdftotext, pdfinfo) not found in your system\'s PATH. Please install Poppler to proceed.');
    }

    try {
      final int pageCount = await _getPageCount(filePath);
      final List<String> pageTexts = [];

      final int firstPage = startPage ?? 1;
      final int lastPage = endPage ?? pageCount;

      if (firstPage < 1 || lastPage > pageCount || firstPage > lastPage) {
        throw ArgumentError('Invalid page range: $firstPage-$lastPage for PDF with $pageCount pages.');
      }

      for (var i = firstPage; i <= lastPage; i += pagesPerBatch) {
        final int batchStart = i;
        final int batchEnd = (i + pagesPerBatch - 1).clamp(batchStart, lastPage);

        final result = await Process.run(
          'pdftotext',
          [
            '-f',
            batchStart.toString(),
            '-l',
            batchEnd.toString(),
            filePath,
            '-',
          ],
        );

        if (result.exitCode != 0) {
          print('Warning: pdftotext failed for pages $batchStart-$batchEnd: ${result.stderr}');
          for (var j = batchStart; j <= batchEnd; j++) {
            pageTexts.add('');
          }
        } else {
          if (pagesPerBatch == 1) {
            pageTexts.add(result.stdout.toString());
          } else {
            final pages = result.stdout.toString().split('\f');
            if (pages.isNotEmpty && pages.last.trim().isEmpty) {
              pages.removeLast();
            }
            pageTexts.addAll(pages);
          }
        }
      }
      return pageTexts;
    } catch (e) {
      throw Exception('An unexpected error occurred while processing the PDF with Poppler: $e');
    }
  }
}

// Legacy function for backward compatibility. Uses PopplerPdfProcessor by default.
Future<List<String>> extractTextFromPdf(
  String filePath, {
  int? startPage,
  int? endPage,
  int pagesPerBatch = 1,
  PdfProcessorStrategy? processor,
}) async {
  final strategy = processor ?? PopplerPdfProcessor();
  return strategy.extractText(
    filePath,
    startPage: startPage,
    endPage: endPage,
    pagesPerBatch: pagesPerBatch,
  );
}

