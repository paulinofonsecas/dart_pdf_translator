#!/usr/bin/env bash
# Build native executable (Unix/macOS/Linux)
# Run from project root: ./scripts/build-exe.sh

set -euo pipefail

echo "Building native executable..."
dart compile exe bin/translator.dart -o bin/ai_pdf_translate
echo "Build complete: bin/ai_pdf_translate"
