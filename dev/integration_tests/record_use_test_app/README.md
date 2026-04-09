# Record Use Test App

An integration test app for testing the "Record Use" asset tree-shaking feature.

## Overview

This app is used to verify that Flutter can tree-shake assets based on their usage in the source code. It works in conjunction with the `record_use_test_package`.

The feature relies on:
- `@RecordUse()` annotation on functions that use assets.
- Asset hooks (`build.dart` and `link.dart`) that process usage recordings.

## How it works

1. The `record_use_test_package` contains a `translations.json` asset with multiple entries.
2. The package provides a `translate(String key)` function annotated with `@RecordUse()`.
3. This app (`record_use_test_app`) calls `translate('hello')` and `translate('friend')`.
4. During the build, the `link.dart` hook in the package receives a recording of these calls.
5. The hook filters `translations.json` to only include the entries for "hello" and "friend", tree-shaking the unused ones.

## Testing

The integration test for this feature is located at:
`packages/flutter_tools/test/integration.shard/isolated/record_use_test.dart`

To run the test:
```bash
bin/cache/dart-sdk/bin/dart packages/flutter_tools/test/integration.shard/isolated/record_use_test.dart
```

Note: The test requires `--enable-record-use` and `--enable-dart-data-assets` to be enabled in the Flutter config.
