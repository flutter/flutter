# Flutter Codebase Test Inventory

This file lists and categorizes the test files found in the Flutter codebase.
Due to the large number of tests (over 6000 files), they are grouped by category and location.

## Runtime Length
- **Sub-second**: < 1 second (Simple unit tests, e.g., in `dev/tools`)
- **Fast**: < 10 seconds (Most unit tests, simple widget tests)
- **Medium**: 10-60 seconds (Complex widget tests, some tool tests)
- **Slow**: > 60 seconds (Integration tests, devicelab tasks, analyze script)

## Groupings

### 1. Framework Tests
- **Location**: `packages/flutter/test/`
- **Language**: Dart
- **Description**: Unit and Widget tests for the Flutter framework.
- **Documentation**:
  - [Running-and-writing-tests.md](Running-and-writing-tests.md)
  - [Writing-a-golden-file-test-for-package-flutter.md](Writing-a-golden-file-test-for-package-flutter.md)
  - [Leak-tracking.md](Leak-tracking.md)
- **Run Locally**: Yes.
- **Commands**:
  - Run all tests in a directory: `bin/flutter test packages/flutter/test/foundation`
  - Run a specific test: `bin/flutter test packages/flutter/test/foundation/assertions_test.dart`
- **Speed**: Fast (< 10 seconds) for individual tests when environment is working.
- **Count**: ~1000+ files.

### 2. Tool Tests
- **Location**: `packages/flutter_tools/test/`
- **Language**: Dart
- **Description**: Where the flutter tool tests live.
- **Documentation**: [README.md](../../../packages/flutter_tools/README.md)
- **Run Locally**: Yes.
- **Commands**:
  - Run general unit tests: `bin/flutter test packages/flutter_tools/test/general.shard`
  - Run a specific test: `bin/flutter test packages/flutter_tools/test/general.shard/base_utils_test.dart`
  - Run integration tests: `bin/flutter test packages/flutter_tools/test/integration.shard` (Requires `FLUTTER_ROOT` environment variable).
- **Speed**: Fast (< 10 seconds) for general shard tests, Medium to Slow for integration tests.
- **Count**: ~500+ files.

### 3. DeviceLab Tests
- **Location**: `dev/devicelab/`
- **Language**: Dart
- **Description**: Performance and integration tests run in the Flutter DeviceLab.
- **Documentation**:
  - [README.md](../../../dev/devicelab/README.md)
  - [How-to-write-a-memory-test-for-Flutter.md](How-to-write-a-memory-test-for-Flutter.md)
  - [How-to-write-a-render-speed-test-for-Flutter.md](How-to-write-a-render-speed-test-for-Flutter.md)
- **Run Locally**: Partially. May require a physical device or emulator and specific environment setup (e.g., `ANDROID_SDK_ROOT`).
- **Commands**:
  - Run a task: `../../bin/cache/dart-sdk/bin/dart bin/test_runner.dart test -t {NAME_OF_TEST}` (Run from `dev/devicelab`).
  - Example: `../../bin/cache/dart-sdk/bin/dart bin/test_runner.dart test -t complex_layout__start_up`
- **Speed**: Slow (> 60 seconds).
- **Count**: ~100+ files.

### 4. Benchmarks
- **Location**: `dev/benchmarks/`
- **Language**: Dart
- **Description**: Performance benchmarks.
- **Documentation**:
  - [README.md](../../../dev/devicelab/README.md) (Benchmarks are run as DeviceLab tasks).
  - [How-to-write-a-memory-test-for-Flutter.md](How-to-write-a-memory-test-for-Flutter.md)
  - [How-to-write-a-render-speed-test-for-Flutter.md](How-to-write-a-render-speed-test-for-Flutter.md)
- **Run Locally**: Partially, same requirements as DeviceLab tests.
- **Commands**: See DeviceLab Tests.
- **Speed**: Slow (> 60 seconds).
- **Count**: ~160+ files.

### 5. Analysis and Lint Tests
- **Key Files**:
  - `dev/bots/analyze.dart`: Enforces style and structure rules.
  - `dev/bots/test.dart`: Main test orchestrator.
- **Documentation**: [Running-and-writing-tests.md](Running-and-writing-tests.md)
- **Run Locally**: Yes.
- **Commands**:
  - Run analysis: `bin/cache/dart-sdk/bin/dart --enable-asserts dev/bots/analyze.dart` (Verified locally, takes > 60 seconds for full run).
- **Speed**: Slow (> 60 seconds) for full execution.

### 6. Package Tests
- **Location**: `packages/*/test/` (excluding `flutter` and `flutter_tools`)
- **Language**: Dart
- **Description**: Tests for packages. Any folder with a `pubspec.yaml` file is considered a package and may contain a `test/` directory.
- **Documentation**: [Running-and-writing-tests.md](Running-and-writing-tests.md)
- **Run Locally**: Yes.
- **Commands**:
  - Run tests in a package: `bin/flutter test packages/<package_name>/test`
- **Speed**: Fast (< 10 seconds) for individual tests.

### 7. Engine Tests
- **Location**: `engine/src` (in the [flutter/engine](https://github.com/flutter/engine) repository)
- **Language**: C++, Dart, Java, Kotlin, etc.
- **Description**: Tests for the Flutter engine.
- **Documentation**: [Testing-the-engine.md](../../engine/testing/Testing-the-engine.md)
- **Run Locally**: Yes, but requires the complete Engine development environment (GN, Ninja, etc.).
- **Commands**:
  - **Using `run_tests.py` from `engine/src/flutter`**:
    - Run C++ tests: `testing/run_tests.py --type=engine`
    - Run Java tests: `testing/run_tests.py --type=java`
    - Run Dart tests: `testing/run_tests.py --type=dart`
  - **Using `et` (Engine Tool)**:
    - Run a test target: `et test //flutter/impeller:impeller_unittests`
    - Query test targets: `et query targets --testonly`
- **Speed**: Fast for individual unit tests, Slow for full suites.
