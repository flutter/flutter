// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:sky_tools/src/os_utils.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

main() => defineTests();

defineTests() {
  group('OperatingSystemUtils', () {
    Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('sky_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    test('makeExecutable', () {
      File file = new File(p.join(temp.path, 'foo.script'));
      file.writeAsStringSync('hello world');
      osUtils.makeExecutable(file);

      // Skip this test on windows.
      if (!Platform.isWindows) {
        String mode = file.statSync().modeString();
        // rwxr--r--
        expect(mode.substring(0, 3), endsWith('x'));
      }
    });

    /// Start a script listening on a port, try and kill that process.
    test('killTcpPortListeners', () async {
      final int port = 40170;

      File file = new File(p.join(temp.path, 'script.dart'));
      file.writeAsStringSync('''
import 'dart:io';

void main() async {
  ServerSocket serverSocket = await ServerSocket.bind(
      InternetAddress.LOOPBACK_IP_V4, ${port});
  // wait...
  print('listening on port ${port}...');
}
''');
      Process process = await Process.start('dart', [file.path]);
      await process.stdout.first;

      osUtils.killTcpPortListeners(40170);
      int exitCode = await process.exitCode;
      expect(exitCode, isNot(equals(0)));
    });

    /// Try and kill with a port that no process is listening to.
    test('killTcpPortListeners none', () {
      osUtils.killTcpPortListeners(40171);
    });
  });
}
