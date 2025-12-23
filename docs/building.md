# Building a native executable

To avoid package resolution (`dart pub get`) on each run, compile a native binary once and run it directly.

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

After building, the executable includes a snapshot of dependencies and won't trigger downloads at runtime.
