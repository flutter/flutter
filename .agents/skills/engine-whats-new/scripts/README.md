# Flutter Engine What's New Tool

This directory contains helper scripts for the `engine-whats-new` skill.

## `generate_engine_whats_new.dart`

Generates the "What's New" summary and diff file for changes in the Flutter engine directory (`//engine/src/flutter`) between two Flutter releases.

### Usage

```bash
dart .agents/skills/engine-whats-new/scripts/generate_engine_whats_new.dart --release <TARGET_RELEASE> [--from <BASE_RELEASE>]
```

### Options

* `--release`, `--to`, `--target <version>`: Target Flutter release version (e.g., `3.47`).
* `--from`, `--base <version>`: Base Flutter release version (e.g., `3.44`). If omitted, the tool automatically deduces the preceding quarterly release.
* `--engine-path <path>`: Path to the Flutter engine directory relative to the repository root (defaults to `engine/src/flutter`).
* `--output-diff <file>`: Filepath to write the generated diff (default: `engine_diff_<base>_to_<target>.diff`).
* `--output-summary <file>`: Filepath to write the Markdown summary (default: `engine_whats_new_<target>.md`).
* `--format <markdown|json|text>`: Stdout output format (default: `markdown`).
