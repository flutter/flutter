# Web Engine Pipeline Steps

This directory contains the individual steps used in the `felt` (Flutter Engine Local Tester) pipeline for building and testing the Flutter web engine.

## Overview

Each file in this directory defines a `PipelineStep` that encapsulates a specific part of the web engine's build and test lifecycle. These steps are orchestrated by the `felt` tool to ensure a consistent and reproducible environment for web engine development.

## Files

- **`compile_bundle_step.dart`**: Compiles a set of web test files into a test bundle. It supports multiple compilers (`dart2js` and `dart2wasm`) and renderers (`canvaskit`, `skwasm`).
- **`copy_artifacts_step.dart`**: Manages the retrieval and placement of required build artifacts (such as CanvasKit WASM, Skwasm, fonts, and test images) into the local testing directory. Artifacts can be sourced from local builds or downloaded from Google Cloud Storage.
- **`run_suite_step.dart`**: Executes a precompiled test suite in a specified browser environment. It handles browser lifecycle, Skia Gold integration for visual regression testing, and reporting of test results.
