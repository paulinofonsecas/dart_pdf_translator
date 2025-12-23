# Dart PDF Translator

A versatile command-line tool to extract text from PDF files and translate it page by page using either the Google Gemini API or a local Ollama instance.

This tool is designed for developers who need to automate the translation of PDF documents directly from the terminal.

## Features

- **PDF Text Extraction**: Reliably extracts text from PDF files using the battle-tested Poppler command-line tools.
- **Flexible Translation Engines**: Choose between:
  - **Gemini**: Google's powerful and scalable translation models.
  - **Ollama**: Run translations locally using your own models (e.g., Llama3, Mistral) for privacy and offline use.
- **Page-by-Page Processing**: Translates large documents page by page to avoid API context limits and provide incremental progress.

A concise index of documentation for this project. See the linked pages for detailed instructions and examples.

- Installation: [docs/installation.md](docs/installation.md)
- Usage (CLI examples): [docs/usage.md](docs/usage.md)
- CLI options and env precedence: [docs/cli_options.md](docs/cli_options.md)
- Using as a package (programmatic): [docs/package.md](docs/package.md)
- Building native executables to avoid `pub get`: [docs/building.md](docs/building.md)

Quick start:

```bash
dart pub get
dart run bin/cli_translator.dart --input sample.pdf
```

Or build a native executable (see `docs/building.md`) and run directly.
        winget install poppler
