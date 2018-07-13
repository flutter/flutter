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
import 'test_utils.dart';

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
  });
}
