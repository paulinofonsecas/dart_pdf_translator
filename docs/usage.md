# Usage

This document shows basic CLI usage and examples.

Run directly with Dart (development):

```bash
dart run bin/translator.dart --input my.pdf --output out.md --target pt
```

If you activated the package globally (`dart pub global activate`), run the installed executable:

```bash
ai_pdf_translate --input my.pdf --output out.pdf --api-key YOUR_GEMINI_KEY --target pt
```

Example (Ollama local):

```bash
ai_pdf_translate --input my.pdf --output out.md --ollama-url http://localhost:11434 --ollama-model mistral --target pt
```

Output behavior:
- If `--output` ends with `.pdf` a simple PDF is generated; otherwise a Markdown file is written.

See `docs/cli_options.md` for all flags and env precedence.
