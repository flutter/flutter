// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('OperatingSystemUtils', () {
    Directory temp;

    setUp(() {
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    testUsingContext('makeExecutable', () async {
      final File file = fs.file(fs.path.join(temp.path, 'foo.script'));
      file.writeAsStringSync('hello world');
      os.makeExecutable(file);

      // Skip this test on windows.
      if (!platform.isWindows) {
        final String mode = file.statSync().modeString();
        // rwxr--r--
        expect(mode.substring(0, 3), endsWith('x'));
      }
    }, overrides: <Type, Generator> {
      OperatingSystemUtils: () => new OperatingSystemUtils(),
    });
  });
}
