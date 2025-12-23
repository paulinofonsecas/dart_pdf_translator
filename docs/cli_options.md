# CLI Options

Available flags and options:

- `-i`, `--input`  : Input PDF file path. If omitted, the first positional argument is used or `sample.pdf`.
- `-o`, `--output` : Output file path. If ends with `.pdf` a PDF is generated; otherwise a Markdown file is created. Defaults to `<input>_translated.md`.
- `-t`, `--target` : Target language (e.g., `pt` for Portuguese). Can also be set via `TARGET_LANGUAGE` in `.env`.
- `--engine`       : Translation engine to use: `gemini` or `ollama`. Defaults to `gemini` or `TRANSLATION_ENGINE` from `.env`.
- `--api-key`      : Gemini API key (overrides `GEMINI_API_KEY` from `.env`). Required for Gemini.
- `--gemini-model` : Gemini model name (overrides `GEMINI_MODEL`).
- `--ollama-url`   : Ollama API base URL (e.g., `http://localhost:11434`) (overrides `OLLAMA_API_URL`).
- `--ollama-model` : Ollama model name (overrides `OLLAMA_MODEL`).
- `--page-step`    : Process every Nth page (defaults to `1`). Useful to sample or skip pages.
- `--delay`        : Delay between page translations in seconds (defaults to `1`).
- `-h`, `--help`   : Show help.

Environment variables (used when CLI flags are not provided):

- `TRANSLATION_ENGINE`, `TARGET_LANGUAGE`, `GEMINI_API_KEY`, `GEMINI_MODEL`, `OLLAMA_API_URL`, `OLLAMA_MODEL`, `PAGE_STEP`

Precedence: CLI flags override `.env` values and environment variables.
