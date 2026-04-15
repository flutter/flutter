# Flutter Web Engine Developer Tools

This directory contains the source code and configuration for **`felt`** (Flutter Engine Local Tester), the primary command-line tool for building and testing the Flutter web engine.

## Overview

The `dev/` directory provides the infrastructure needed to:
- **Build the Web Engine:** Interface with GN and Ninja to compile engine targets (SDK, CanvasKit, Skwasm, etc.).
- **Run Unit Tests:** A comprehensive testing framework that handles browser lifecycle, test compilation, and execution across multiple browsers and renderers.
- **Manage Browser Environments:** Automate the installation and configuration of specific versions of Chrome, Firefox, Edge, and Safari.
- **Maintain Engine Quality:** Provide tools for checking license headers, generating CI configurations, and rolling browser versions in CIPD.

## Subdirectories

- **`steps/`**: Contains individual `PipelineStep` implementations used by `felt` to modularize tasks like compilation, artifact copying, and test execution.

## Files

- **`browser_process.dart`**: Manages the lifecycle of a browser process, including standard I/O draining and clean shutdown.
- **`browser.dart`**: Defines the base interfaces for browser environments (`BrowserEnvironment`) and individual browser instances (`Browser`).
- **`build.dart`**: Implements the `felt build` command, providing a high-level wrapper around GN and Ninja for web engine targets.
- **`chrome_installer.dart`**: Handles the automatic downloading and installation of specific Chromium versions.
- **`chrome.dart`**: Implements the Chrome-specific browser environment and execution logic.
- **`cipd.dart`**: Utility functions for interacting with the CIPD (Chrome Infrastructure Package Deployment) tool.
- **`clean.dart`**: Implements the `felt clean` command to delete build caches, artifacts, and temporary tool directories.
- **`common.dart`**: Contains shared constants, platform-specific bindings, and utility functions used throughout the tool.
- **`edge_installation.dart`**: Manages the installation and configuration of Microsoft Edge for testing.
- **`edge.dart`**: Implements the Edge-specific browser environment and execution logic.
- **`environment.dart`**: Provides a centralized collection of file paths and tool locations (such as the Dart SDK and engine build directories) required by the `felt` tool.
- **`exceptions.dart`**: Defines custom exception types for tool-specific errors and controlled exits.
- **`felt`**: The bash entry point for the tool on Linux and macOS.
- **`felt.bat`**: The batch script entry point for the tool on Windows.
- **`felt.dart`**: The main Dart entry point that handles command parsing and dispatching via `package:args`.
- **`felt_config.dart`**: Provides a typed Dart interface for the `felt_config.yaml` file, defining test suites and configurations.
- **`firefox_installer.dart`**: Handles the automatic downloading and installation of specific Firefox versions.
- **`firefox.dart`**: Implements the Firefox-specific browser environment and execution logic.
- **`generate_builder_json.dart`**: Generates JSON configuration files for LUCI (Continuous Integration) builders.
- **`generate_scene_test.dart`**: A utility to generate Dart scene tests from JSON descriptions of engine scenes.
- **`licenses.dart`**: Implements the `felt check-licenses` command to verify that source files have correct license headers.
- **`package_lock.dart`**: Provides programmatic access to the tool and browser versions defined in `package_lock.yaml`.
- **`package_lock.yaml`**: Specifies the pinned versions of browsers and tools used for consistent testing.
- **`package_roller.dart`**: A script used to roll browser versions in CIPD for CI infrastructure.
- **`pipeline.dart`**: Implements a generic execution pipeline for sequences of asynchronous build or test tasks.
- **`roll_fallback_fonts.dart`**: Tool for generating fallback font data from Google Fonts and managing them in CIPD.
- **`safari_macos.dart`**: Implements the Safari-specific browser environment for macOS using `safaridriver`.
- **`suite_filter.dart`**: Provides logic for filtering test suites based on name, browser, compiler, or renderer.
- **`test_platform.dart`**: A custom `package:test` platform plugin that serves and communicates with the browser during tests.
- **`test_runner.dart`**: Implements the `felt test` command, coordinating compilation, artifact management, and execution.
- **`utils.dart`**: General utility functions for process management, file path handling, and terminal output formatting.
- **`web_engine_analysis.sh`**: A shell script for running static analysis (`dart analyze`) on the web engine source code.
- **`webdriver_browser.dart`**: An implementation of the `Browser` interface that controls browsers via WebDriver.
