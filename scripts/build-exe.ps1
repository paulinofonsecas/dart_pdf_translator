<#
Build native executable for Windows (PowerShell).

Run this from the project root:

    .\scripts\build-exe.ps1

This will compile `bin/translator.dart` to `bin/ai_pdf_translate.exe`.
#>
param()

Write-Host "Building native executable..."
dart compile exe bin/translator.dart -o bin/ai_pdf_translate.exe
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build complete: bin/ai_pdf_translate.exe"
} else {
    Write-Error "Build failed with exit code $LASTEXITCODE"
}
