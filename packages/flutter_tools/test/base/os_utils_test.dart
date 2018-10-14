// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('OperatingSystemUtils', () {
    Directory tempDir;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_os_utils_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('makeExecutable', () async {
      final File file = fs.file(fs.path.join(tempDir.path, 'foo.script'));
      file.writeAsStringSync('hello world');
      os.makeExecutable(file);

      // Skip this test on windows.
      if (!platform.isWindows) {
        final String mode = file.statSync().modeString();
        // rwxr--r--
        expect(mode.substring(0, 3), endsWith('x'));
      }
    }, overrides: <Type, Generator> {
      OperatingSystemUtils: () => OperatingSystemUtils(),
    });
  });
}
