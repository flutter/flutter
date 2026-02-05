# Repository Guidelines

## Project Structure & Module Organization
- `packages/`: Flutter framework and core Dart packages (`flutter`, `flutter_test`, `flutter_tools`, etc.).
- `engine/`: C++/Skia-based engine sources and build files (see `engine/README.md` for engine build steps).
- `bin/`: Flutter CLI entrypoints (`bin/flutter`) and cached tooling.
- `dev/`: Internal tooling, CI scripts, and large test suites (e.g., `dev/bots`, `dev/devicelab`).
- `examples/`: Sample apps and integration examples.
- `docs/`: Project documentation and contributing references.

## Build, Test, and Development Commands
- `./bin/flutter --version`: Bootstraps the repo toolchain (downloads the Dart SDK if needed).
- `./bin/flutter test`: Run tests for a package (run from the package directory, e.g., `packages/flutter`).
- `bin/cache/dart-sdk/bin/dart dev/bots/test.dart`: CI-style test runner; use shards like `SHARD=framework_tests`.
- `bin/cache/dart-sdk/bin/dart --enable-asserts dev/bots/analyze.dart`: Repository-wide analysis and lint checks.
- `./dev/tools/format.sh`: Applies Dart formatting used by CI.

## Coding Style & Naming Conventions
- Dart uses 2-space indentation; rely on the formatter (`./dev/tools/format.sh`) instead of manual alignment.
- Follow `analysis_options.yaml` at the repo root (and in `dev/`) for lints and analyzer settings.
- File names are lower_snake_case; test files must end with `_test.dart`.

## Testing Guidelines
- Unit/widget tests live in `*/test/` and are run with `flutter test`.
- CI uses `dev/bots/test.dart`; prefer shards when validating a focused area.
- New features or bug fixes should include tests near the affected package or tool.

## Commit & Pull Request Guidelines
- Recent commits use a concise summary with a PR number suffix, e.g. `Roll Skia … (#181780)`.
- Keep commit subjects imperative and scoped to the change.
- PRs should include: a clear description, linked issue (if any), and the tests run.
- Follow `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` for process and community rules.

## Agent Notes (GTK4 Porting)
- Engine deps are synced from the repo root using `.gclient` copied from `engine/scripts/standard.gclient`; do not use the archived `https://github.com/flutter/engine.git` mirror.
- Run `gclient sync` at the repo root; it may take a long time and needs network access.
- GN/Ninja builds can take >10 minutes; use longer timeouts (e.g., 600s) when running `ninja -C engine/src/out/host_debug_unopt` via automation.
