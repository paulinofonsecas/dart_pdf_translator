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

/// Extracts text from a PDF file, processing it page by page using `pdftotext`.
///
/// Throws a [FileSystemException] if the [filePath] is not found.
/// Throws an [Exception] if the required Poppler tools are not installed.
///
/// Returns a [Future] that completes with a list of strings, where each string
/// is the text content of a single page.
Future<List<String>> extractTextFromPdf(String filePath) async {
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

    for (var i = 1; i <= pageCount; i++) {
      // Use pdftotext to extract text from a single page and pipe to stdout.
      final result = await Process.run(
        'pdftotext',
        [
          '-f', // First page flag
          i.toString(),
          '-l', // Last page flag
          i.toString(),
          filePath,
          '-', // Pipe output to stdout
        ],
      );

      if (result.exitCode != 0) {
        print('Warning: pdftotext failed for page $i: ${result.stderr}');
        pageTexts.add(''); // Add an empty string for the failed page to maintain page order.
      } else {
        pageTexts.add(result.stdout.toString());
      }
    }
    return pageTexts;
  } catch (e) {
    // Re-throw any exception that occurs during processing to be handled by the caller.
    throw Exception('An unexpected error occurred while processing the PDF with Poppler: $e');
  }
}

