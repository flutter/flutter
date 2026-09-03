// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';

import '../utils.dart';
import 'common.dart';

typedef AsyncVoidCallback = Future<void> Function();

/// Capture the output of calling [callback]
/// and validate if it emitted any formatted errors.
///
/// This function will fail the current test if either of the following is true:
/// - [shouldHaveErrors] is true and no errors were reported
/// - [shouldHaveErrors] is false and any errors were reported
///
/// Returns the captured output.
Future<String> capture(AsyncVoidCallback callback, {bool shouldHaveErrors = false}) async {
  final buffer = StringBuffer();
  final PrintCallback oldPrint = print;
  try {
    print = (Object? line) {
      buffer.writeln(line);
    };
    await callback();
    expect(
      hasError,
      shouldHaveErrors,
      reason: buffer.isEmpty
          ? '(No output to report.)'
          : hasError
          ? 'Unexpected errors:\n$buffer'
          : 'Unexpected success:\n$buffer',
    );
  } finally {
    print = oldPrint;
    resetErrorStatus();
  }
  if (stdout.supportsAnsiEscapes) {
    // Remove ANSI escapes when this test is running on a terminal.
    return buffer.toString().replaceAll(RegExp(r'(\x9B|\x1B\[)[0-?]{1,3}[ -/]*[@-~]'), '');
  } else {
    return buffer.toString();
  }
}

File getFile(String filepath, Directory directory) {
  final String platformFilepath = filepath.replaceAll('/', Platform.pathSeparator);
  final String searchPattern = directory.basename + Platform.pathSeparator;
  // Don't use `lastIndexOf`, as for files in test fixes
  // i.e. `packages/flutter_test/test_fixes/flutter_test/matchers.dart`
  // the overlap index could appear multiple times.
  // Only take the first one.
  final int overlapIndex = platformFilepath.indexOf(searchPattern);

  if (overlapIndex < 0) {
    throw ArgumentError('filepath $filepath must be located in directory ${directory.path}.');
  }

  final String filename = platformFilepath.substring(overlapIndex + searchPattern.length);
  return directory.childFile(filename);
}

/// Writes [importString] into the given file.
///
/// The default [importString] is `import 'package:flutter/material.dart';`.
void writeImport(File file, [String importString = "import 'package:flutter/material.dart';"]) {
  file
    ..createSync(recursive: true)
    ..writeAsStringSync(importString);
}

/// Writes [importString] into the given [filePaths] in [inDirectory].
///
/// The default [importString] is `import 'package:flutter/material.dart';`.
void writeImportInFiles(
  Iterable<String> filePaths, {
  required Directory inDirectory,
  String importString = "import 'package:flutter/material.dart';",
}) {
  for (final filepath in filePaths) {
    writeImport(getFile(filepath, inDirectory), importString);
  }
}
