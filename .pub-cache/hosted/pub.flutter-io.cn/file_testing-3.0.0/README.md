[![pub package](https://img.shields.io/pub/v/file_testing.svg)](https://pub.dev/packages/file_testing)

Testing utilities intended to work with `package:file`

## Features

This package provides a series of matchers to be used in tests that work with file
system types.

## Usage

```dart
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:test/test.dart';

void main() {
  MemoryFileSystem fs;

  setUp(() {
    fs = MemoryFileSystem();
    fs.file('/foo').createSync();
  });

  test('some test', () {
    expectFileSystemException(
      ErrorCodes.ENOENT,
      () {
        fs.directory('').resolveSymbolicLinksSync();
      },
    );
    expect(fs.file('/path/to/file'), isFile);
    expect(fs.file('/path/to/directory'), isDirectory);
    expect(fs.file('/foo'), exists);
  });
}
```
