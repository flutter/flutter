// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/tester/flutter_tester.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

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
      return await device.startApp(null,
          mainPath: mainPath,
          debuggingOptions: new DebuggingOptions.enabled(
              const BuildInfo(BuildMode.debug, null)));
    }

    testUsingContext('start', () async {
      _writePubspec();
      _writePackages();

      final String mainPath = fs.path.join('lib', 'main.dart');
      _writeFile(mainPath, r'''
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

      final String line = await device.getLogReader().logLines.first;
      expect(line, 'Hello!');

      expect(await device.stopApp(null), isTrue);
    });

    testUsingContext('keeps running', () async {
      _writePubspec();
      _writePackages();
      await _getPackages();

      final String mainPath = fs.path.join('lib', 'main.dart');
      _writeFile(mainPath, r'''
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

      final LaunchResult result = await start(mainPath);

      expect(result.started, isTrue);
      expect(result.observatoryUri, isNotNull);

      await new Future<void>.delayed(const Duration(seconds: 3));
      expect(device.isRunning, true);

      expect(await device.stopApp(null), isTrue);
    });
  });
}

void _writeFile(String path, String content) {
  fs.file(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}

void _writePackages() {
  _writeFile('.packages', '''
test:${fs.path.join(fs.currentDirectory.path, 'lib')}/
''');
}

void _writePubspec() {
  _writeFile('pubspec.yaml', '''
name: test
dependencies:
  flutter:
    sdk: flutter
''');
}

Future<void> _getPackages() async {
  final List<String> command = <String>[
    fs.path.join(getFlutterRoot(), 'bin', 'flutter'),
    'packages',
    'get'
  ];
  final Process process = await processManager.start(command);
  final StringBuffer errorOutput = new StringBuffer();
  process.stderr.transform(utf8.decoder).listen(errorOutput.write);
  final int exitCode = await process.exitCode;
  if (exitCode != 0)
    throw new Exception('flutter packages get failed: ${errorOutput.toString()}');
}
