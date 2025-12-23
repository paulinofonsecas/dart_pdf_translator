# CLI Documentation

This document describes the command-line interface for the `ai_pdf_translate` executable.

## Installation

Install the package globally:

```bash
dart pub global activate ai_dart_pdf_translator .
```

Install the package globally (from the project root):

```bash
dart pub global activate --source path .
```

This registers the `ai_pdf_translate` executable so you can call it directly from your shell.

## Basic usage

```bash
ai_pdf_translate [options]
```

Or provide the PDF path as the first positional argument (shorthand):

```bash
ai_pdf_translate path/to/file.pdf
```

## Options

- `-i`, `--input`  : Input PDF file path. If omitted, the first positional argument is used or `sample.pdf`.
- `-o`, `--output` : Output file path. If ends with `.pdf` a PDF is generated; otherwise a Markdown file is created. Defaults to `<input>_translated.md`.
- `-t`, `--target` : Target language (e.g., `pt` for Portuguese). Can also be set via `TARGET_LANGUAGE` in `.env`.
- `--engine`       : Translation engine to use: `gemini` or `ollama`. Defaults to `gemini` or `TRANSLATION_ENGINE` from `.env`.
- `--api-key`      : Gemini API key (overrides `GEMINI_API_KEY` from `.env`). Required for Gemini.
- `--gemini-model` : Gemini model name (overrides `GEMINI_MODEL`).
- `--ollama-url`   : Ollama API base URL (e.g., `http://localhost:11434`) (overrides `OLLAMA_API_URL`).
- `--ollama-model` : Ollama model name (overrides `OLLAMA_MODEL`).
- `--delay`        : Delay between page translations in seconds (defaults to `0`).
- `--parallel`     : Number of parallel translations to run (default: `1`).
- `-h`, `--help`   : Show help.

## Environment variable precedence

Options set via CLI flags override values in your `.env` file. The following environment variables are honored:

- `TRANSLATION_ENGINE` — `gemini` or `ollama`
- `TARGET_LANGUAGE` — e.g., `English`, `Portuguese`
- `GEMINI_API_KEY` — required for Gemini
- `GEMINI_MODEL`
- `OLLAMA_API_URL` — required for Ollama
- `OLLAMA_MODEL` — required for Ollama
- `TRANSLATION_DELAY`

When both CLI flags and environment vars are present, CLI flags take precedence.

## Examples

Translate using Gemini (API key):

```bash
ai_pdf_translate --input doc.pdf --output doc_translated.pdf --api-key "MY_KEY" --target pt
```

Translate using a local Ollama model:

```bash
ai_pdf_translate --input doc.pdf --output doc_translated.md --ollama-url http://localhost:11434 --ollama-model mistral --target pt
```

## Notes

- Output PDF generation is simple and may not preserve original layout. Use Markdown output if you prefer plain text output for post-processing.
- Ensure `pdftotext` and `pdfinfo` are installed and available in PATH for the built-in PDF extraction.
- For programmatic usage, consider importing the package and using the `Translator` implementations directly.

## Avoid `pub get` on every run

When invoking the CLI via the Dart runtime or in some activation scenarios, you may see `Downloading packages...` before the tool runs. To avoid that and run the CLI instantly, compile a native executable once and run it directly:

Windows (PowerShell):

```powershell
.\scripts\build-exe.ps1
.\bin\ai_pdf_translate.exe -h
```

macOS / Linux:

```bash
./scripts/build-exe.sh
./bin/ai_pdf_translate -h
```

The compiled native executable contains the package snapshot and does not trigger package resolution at runtime.

## Using the library as a package

If you prefer to use this project as a package rather than the CLI, import the public entrypoint and use the provided `PdfProcessor` and `Translator` implementations:

```dart
import 'package:ai_dart_pdf_translator/ai_dart_pdf_translator.dart';

void main() async {
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

Programmatic usage gives you more control over batching, parallelism, or custom post-processing.
