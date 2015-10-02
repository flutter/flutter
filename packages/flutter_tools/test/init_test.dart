// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test can take a while due to network requests
@Timeout(const Duration(seconds: 60))
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:sky_tools/src/init.dart';
import 'package:test/test.dart';

main() => defineTests();

defineTests() {
  group('', () {
    Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('sky_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    // Verify that we create a project that is well-formed.
    test('init flutter-simple', () async {
      InitCommand command = new InitCommand();
      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      await runner.run(['init', '--out', temp.path])
          .then((int code) => expect(code, equals(0)));

      String path = p.join(temp.path, 'lib', 'main.dart');
      expect(new File(path).existsSync(), true);
      ProcessResult exec = Process.runSync(
          'dartanalyzer', ['--fatal-warnings', path],
          workingDirectory: temp.path);
      expect(exec.exitCode, 0);
    });
  });
}
