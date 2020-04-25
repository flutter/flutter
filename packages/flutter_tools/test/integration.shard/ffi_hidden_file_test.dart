// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/ffi.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  FileSystem fileSystem;
  Directory testDirectory;

  setUpAll(() {
    fileSystem = const LocalFileSystem();
    testDirectory = fileSystem.systemTempDirectory
      .createTempSync('flutter_test_ffi')
      ..createSync();
  });

  tearDownAll(() {
    testDirectory?.deleteSync(recursive: true);
  });

  test('FFIService can detect hidden files on windows', () async {
    final FFIService ffiService = FFIService();
    const ProcessManager processManager = LocalProcessManager();

    // Create a file and apply a hidden attribute to it.
    final File file = testDirectory.childFile('test.txt')
      ..createSync();
    final ProcessResult setResult = await processManager.run(<String>[
      'attrib',
      '+h',
      file.absolute.path,
    ]);

    expect(setResult.exitCode, 0);

    // Verify the hidden attribute is set.
    final ProcessResult checkResult = await processManager.run(<String>[
      'attrib',
      file.absolute.path,
    ]);

    expect(checkResult.exitCode, 0);
    expect(checkResult.stdout, contains('H'));

    // Verify the ffi service is consistent.
    expect(ffiService.isFileHidden(file.absolute.path), true);

    // Verify with non-hidden file.
    final File nonHiddenFile = testDirectory.childFile('other_test.txt')
      ..createSync();

    expect(ffiService.isFileHidden(nonHiddenFile.path), false);
  }, skip: ! const LocalPlatform().isWindows);

  test('FFIService defaults to non-hidden on platforms besides windows', () async {
    final FFIService ffiService = FFIService();
    final File file = testDirectory.childFile('other_test.txt')
      ..createSync();

    expect(ffiService.isFileHidden(file.path), false);
  }, skip: const LocalPlatform().isWindows);
}
