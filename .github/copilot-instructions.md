# Copilot Instructions for dart_pdf_translator

## Project Overview
- **Purpose:** Extracts text from PDF files and translates it page-by-page using either Google Gemini API or a local Ollama instance.
- **Modes:** Command-line tool (primary) and Flutter example app (see `example/`).
- **Output:** Translated content is saved as Markdown (`*_translated.md`).

## Architecture
- **Main entry:** `bin/translator.dart` orchestrates config loading, PDF extraction, translation, and output.
- **PDF Extraction:** Uses Poppler CLI tools (`pdftotext`, `pdfinfo`) via `lib/src/pdf_processor.dart`.
- **Translation Engines:**
  - Gemini: `lib/src/translators/gemini_translator.dart` (Google API)
  - Ollama: `lib/src/translators/ollama_translator.dart` (local API)
- **Abstraction:** All translators implement the `Translator` interface (`lib/src/translators/translator.dart`).
- **Config:** `.env` file at project root controls engine, keys, and model selection.

## Developer Workflows
- **Setup:**
  - Install Dart SDK and Poppler tools (see `README.md` for platform-specific instructions).
  - Copy `.env.example` to `.env` and configure keys/models.
  - Run `dart pub get` to install dependencies.
- **Run CLI:**
  - `dart run bin/translator.dart [pdf_path]`
  - Output file: `[pdf_path]_translated.md`
- **Flutter Example:**
  - Navigate to `example/` and run `flutter run`.
  - Uses `syncfusion_flutter_pdf` for extraction (not Poppler).

## Patterns & Conventions
- **Translation Prompt:** Both engines use a strict prompt: "Translate the following text to <targetLanguage>. Only return the translated text, without any introductory phrases, formatting, or explanations."
- **Error Handling:**
  - CLI exits with clear error messages for missing files, config, or tools.
  - Empty pages are skipped but preserved in output order.
- **Extensibility:** Add new translators by implementing the `Translator` interface.
- **Markdown Output:** Each page is a separate section; pages separated by `---`.

## Integration Points
- **Gemini:** Requires API key and model name in `.env`.
- **Ollama:** Requires local API URL and model name in `.env`.
- **Poppler:** Must be installed and available in PATH for CLI mode.

## Key Files & Directories
- `bin/translator.dart`: Main CLI logic
- `lib/src/pdf_processor.dart`: PDF extraction
- `lib/src/translators/`: Translation engines
- `.env.example`: Configuration template
- `README.md`: Setup and usage
- `example/`: Flutter demo app

## Example: Add a New Translator
1. Create a new file in `lib/src/translators/`.
2. Implement the `Translator` interface.
3. Update `_getTranslator()` in `bin/translator.dart` to support your engine.

---
For questions or unclear conventions, review `README.md` or ask for clarification.
