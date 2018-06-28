// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/tester/flutter_tester.dart';
import 'package:test/test.dart';

import '../src/context.dart';
import 'util.dart';

void main() {
  Directory tempDir;
  Directory oldCurrentDir;

  setUp(() async {
    tempDir = await fs.systemTempDirectory.createTemp('flutter_tester_device');
    oldCurrentDir = fs.currentDirectory;
    fs.currentDirectory = tempDir;
  });

  tearDown(() {
    fs.currentDirectory = oldCurrentDir;
    try {
      tempDir?.deleteSync(recursive: true);
      tempDir = null;
    } catch (e) {
      // Ignored.
    }
  });

  group('FlutterTesterDevice', () {
    FlutterTesterDevice device;

    setUp(() {
      device = new FlutterTesterDevice('flutter-tester');
    });

    Future<LaunchResult> start(String mainPath) async {
      return await device.startApp(
        null,
        mainPath: mainPath,
        debuggingOptions: new DebuggingOptions.enabled(
          const BuildInfo(BuildMode.debug, null),
        ),
      );
    }

    testUsingContext('start', () async {
      writePubspec(tempDir.path);
      writePackages(tempDir.path);

      final String mainPath = fs.path.join('lib', 'main.dart');
      writeFile(mainPath, r'''
import 'dart:async';
void main() {
  new Timer.periodic(const Duration(milliseconds: 1), (Timer timer) {
    print('Hello!');
  });
}
''');

      final LaunchResult result = await start(mainPath);
      expect(result.started, isTrue);
      expect(result.observatoryUri, isNotNull);

      final String line = await device.getLogReader().logLines.firstWhere((String line) => !line.contains('TeXGyreSchola'));
      expect(line, equals('Hello!'));

      expect(await device.stopApp(null), isTrue);
    });

    testUsingContext('keeps running', () async {
      writePubspec(tempDir.path);
      writePackages(tempDir.path);
      await getPackages(tempDir.path);

      final String mainPath = fs.path.join('lib', 'main.dart');
      writeFile(mainPath, r'''
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      home: new Container(),
    );
  }
}
''');

      // Capture process output so that if the process quits we can print the
      // stdout/stderr in the error.
      final StringBuffer logs = new StringBuffer();
      device.getLogReader().logLines.listen(logs.write);

      final LaunchResult result = await start(mainPath);

      expect(result.started, isTrue);
      expect(result.observatoryUri, isNotNull);

      // This test has been seen to flake on mac_bot because the process did not keep running.
      // and on Travis with a timeout:
      // 05:33 +416 ~9 -1: test/integration/flutter_tester_test.dart: FlutterTesterDevice start [E]                                                                                                             
      // TimeoutException after 0:00:30.000000: Test timed out after 30 seconds.
      // package:test  Invoker._onRun.<fn>.<fn>.<fn>
      // 06:00 +623 ~9 -1: Some tests failed.
      //
      // TODO(dantup): Find a way to better log what's going on before un-skipping again.

      await new Future<void>.delayed(const Duration(seconds: 3));
      expect(device.isRunning, true, reason: 'Device did not remain running.\n\n$logs'.trim());

      expect(await device.stopApp(null), isTrue);
    }, skip: true);
  });
}
