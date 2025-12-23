# Installation

## Prerequisites

- **Dart SDK**: Install from <https://dart.dev/get-dart>
- **Poppler (CLI tools)**: `pdftotext` and `pdfinfo` are required for PDF extraction.

Install Poppler:

- macOS (Homebrew):

```bash
brew install poppler
```

- Windows (Winget - recommended):

```powershell
winget install poppler
```

- Debian/Ubuntu:

```bash
sudo apt-get update && sudo apt-get install poppler-utils
```

Verify installation by running `pdftotext -v` and `pdfinfo -v`.

## Fetch dependencies

From the project root run:

```bash
dart pub get
```

To avoid resolving packages every time you run the CLI, see `docs/building.md` to compile a native executable.
