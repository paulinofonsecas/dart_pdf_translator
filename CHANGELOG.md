# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2025-12-23

### Changed

- **refactor**: Replace translator.dart with cli_translator.dart and update CLI options
- **refactor**: Remove page-step option and enhance parallel translation support
- **docs**: Enhance CLI functionality and documentation
- **docs**: Split documentation into separate files and update README index

### Added

- **ci**: Add cl.yaml GitHub Actions workflow for static analysis
- **chore**: Add native build scripts and docs to avoid pub get on each run

### Fixed

- Fix lints in codebase
- Update Gemini model version

## [1.0.1] - 2025-12-21

- Documentation improvements and multilingual (English/Portuguese) announcement examples
- Ready for next release on pub.dev

## [1.0.0] - 2025-12-21

- Initial release on pub.dev
- Extracts text from PDF files page by page using Poppler (CLI)
- Supports translation using Gemini (Google) or a local Ollama instance
- CLI and library usage
- Outputs translated content to a structured Markdown file
- Multilingual documentation: English and Portuguese announcement
- Test files added for core functionality
