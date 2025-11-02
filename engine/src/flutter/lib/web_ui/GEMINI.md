# Customizing the Flutter Web Engine

This document describes how to build the engine and run tests for the Flutter Web Engine using the `felt` tool.

## `felt`: Flutter Engine Local Tester

`felt` is a command-line tool for building and testing the Flutter web engine. To use it, you need to add `FLUTTER_ROOT/engine/src/flutter/lib/web_ui/dev` to your `PATH`.

Before building the engine, ensure your dependencies are up to date by running the following command from the root of your Flutter checkout:

```bash
gclient sync -D
```

### Building the Engine with `felt`

The `felt build` command builds web engine targets. You can specify targets to build, or build all of them by default.

**Common Targets:**

*   `sdk`: The Flutter Web SDK.
*   `canvaskit`: Flutter's version of CanvasKit.
*   `canvaskit_chromium`: A Chromium-optimized version of CanvasKit.
*   `skwasm`: Experimental Skia Wasm module renderer.

**Examples:**

Build all web engine targets:

```bash
felt build
```

Build the `sdk` and `canvaskit` targets:

```bash
felt build sdk canvaskit
```

### Testing with `felt`

The `felt test` command compiles and runs web engine unit tests.

**Useful Flags:**

*   `--compile`: Compiles test bundles.
*   `--run`: Runs unit tests.
*   `--copy-artifacts`: Copies build artifacts needed for tests.
*   `--list`: Lists all test suites and bundles.
*   `--verbose`: Outputs extra debugging information.
*   `--start-paused`: Pauses tests before starting to allow setting breakpoints.
*   `--browser`: Filters tests by browser (e.g., `chrome`, `firefox`, `safari`).
*   `--compiler`: Filters tests by compiler (e.g., `dart2js`, `dart2wasm`).
*   `--renderer`: Filters tests by renderer (e.g., `html`, `canvaskit`, `skwasm`).

**Examples:**

Run all test suites:

```bash
felt test
```

Run a specific test file:

```bash
felt test test/engine/util_test.dart
```

Run tests that use the `dart2wasm` compiler:

```bash
felt test --compiler dart2wasm
```

Run tests on Chrome using the CanvasKit renderer:

```bash
felt test --browser chrome --renderer canvaskit
```

### Generating Golden Files

To update the golden files for screenshot tests, use the `--update-screenshot-goldens` flag with the `felt test` command. This is useful when a browser update or other change affects the rendering of a test.

The generated golden files are placed in the `.dart_tool/skia_gold` directory, under subdirectories for each test configuration (e.g., `chrome-dart2js-canvaskit-ui`).

**Example:**

```bash
felt test --update-screenshot-goldens test/ui/some_golden_test.dart
```

### Test Directory Structure

The `test` directory contains the following subdirectories:

*   `canvaskit`: Tests for the CanvasKit backend.
*   `common`: Common utilities for tests.
*   `engine`: Core engine logic tests.
*   `fallbacks`: Tests for fallback mechanisms (like fonts).
*   `ui`: Tests for the `dart:ui` layer implementation for the web, including most of the golden tests.
*   `webparagraph`: Tests related to paragraph and text layout on the web.
