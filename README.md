# Dart PDF Translator

A versatile command-line tool to extract text from PDF files and translate it page by page using either the Google Gemini API or a local Ollama instance.

This tool is designed for developers who need to automate the translation of PDF documents directly from the terminal.

## Features

- **PDF Text Extraction**: Reliably extracts text from PDF files using the battle-tested Poppler command-line tools.
- **Flexible Translation Engines**: Choose between:
  - **Gemini**: Google's powerful and scalable translation models.
  - **Ollama**: Run translations locally using your own models (e.g., Llama3, Mistral) for privacy and offline use.
- **Page-by-Page Processing**: Translates large documents page by page to avoid API context limits and provide incremental progress.
- **Markdown Output**: Saves the translated content in a clean, structured Markdown file.
- **Configurable**: Easily configure your translation engine, API keys, and models via an `.env` file.
- **Pub.dev Ready**: Structured and documented to be published as a reusable package.

## Prerequisites

1.  **Dart SDK**: Make sure you have the [Dart SDK](https://dart.dev/get-dart) installed.
2.  **Poppler**: The command-line tools `pdftotext` and `pdfinfo` are required for PDF processing.

    -   **macOS (via Homebrew):**
        ```sh
        brew install poppler
        ```
    -   **Windows (via Winget - Recommended):**
        ```sh
        winget install poppler
        ```
    -   **Linux (Debian/Ubuntu):**
        ```sh
        sudo apt-get update && sudo apt-get install poppler-utils
        ```

    *After installing, ensure the tools are available in your system's PATH.*

## Setup

1.  **Clone the repository** or download the source code.
2.  **Create an environment file**:
    -   Rename `.env.example` to `.env`.
    -   Open the `.env` file and fill in the required values based on your desired translation engine.

    ```dotenv
    # ---------------------------
    # GENERAL SETTINGS
    # ---------------------------
    # The translation engine to use. Options: "gemini" or "ollama".
    TRANSLATION_ENGINE=gemini
    
    # The language to translate the PDF text into (e.g., "English", "Portuguese").
    TARGET_LANGUAGE=English
    
    # ---------------------------
    # GEMINI SETTINGS
    # ---------------------------
    # Required if TRANSLATION_ENGINE is "gemini".
    GEMINI_API_KEY=YOUR_API_KEY_HERE
    GEMINI_MODEL=gemini-1.5-flash-latest
    
    # ---------------------------
    # OLLAMA SETTINGS
    # ---------------------------
    # Required if TRANSLATION_ENGINE is "ollama".
    OLLAMA_API_URL=http://localhost:11434
    OLLAMA_MODEL=llama3
    ```

3.  **Install dependencies**:
    ```sh
    dart pub get
    ```

## Usage

1.  Place a PDF file in the project's root directory (e.g., `sample.pdf`).
2.  Run the translator from your terminal, optionally passing the path to your PDF as an argument.

    ```sh
    # Use the default 'sample.pdf'
    dart run bin/translator.dart
    
    # Specify a different PDF file
    dart run bin/translator.dart path/to/my_document.pdf
    ```

3.  A new Markdown file (e.g., `my_document_translated.md`) will be created with the translated content.

## Flutter Example App

This project includes a complete Flutter application in the `example/` directory to demonstrate how the translation logic can be used within a mobile/desktop UI.

**Note:** The example app uses a Flutter-compatible package (`syncfusion_flutter_pdf`) for text extraction, as the command-line Poppler tools are not suitable for a mobile environment. This showcases how the core `Translator` interface can be used with different platform-specific utilities.

### Running the Example

1.  **Set up the API Key**: Ensure you have a valid `GEMINI_API_KEY` in the main `.env` file at the root of *this* project (`dart_pdf_translator/.env`). The example app is configured to read the key from there.
2.  **Navigate to the example directory**:
    ```sh
    cd example
    ```
3.  **Run the Flutter app**:
    ```sh
    flutter run
    ```
4.  Use the "Pick PDF" button in the app to select a file and start the translation.

## Library vs. Executable

This package is primarily designed as a command-line executable. However, its core components are exported as a library and can be used programmatically. See the `example/` directory for a basic illustration.

## Publishing to Pub.dev

This package is structured to be published on [pub.dev](https://pub.dev).

1.  Update the `homepage` and `repository` URLs in `pubspec.yaml`.
2.  Review the `LICENSE`, `CHANGELOG.md`, and documentation.
3.  Run `dart pub publish --dry-run` to validate the package.
4.  If validation passes, run `dart pub publish` to publish.