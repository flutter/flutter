// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/base/os.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

main() => defineTests();

defineTests() {
  group('OperatingSystemUtils', () {
    Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    test('makeExecutable', () {
      File file = new File(path.join(temp.path, 'foo.script'));
      file.writeAsStringSync('hello world');
      os.makeExecutable(file);

      // Skip this test on windows.
      if (!Platform.isWindows) {
        String mode = file.statSync().modeString();
        // rwxr--r--
        expect(mode.substring(0, 3), endsWith('x'));
      }
    });
  });
}
