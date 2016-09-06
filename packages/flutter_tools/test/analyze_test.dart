// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  AnalysisServer server;
  Directory tempDir;

  setUp(() {
    FlutterCommandRunner.initFlutterRoot();
    tempDir = Directory.systemTemp.createTempSync('analysis_test');
  });

  tearDown(() {
    tempDir?.deleteSync(recursive: true);
    return server?.dispose();
  });

  group('analyze', () {
    testUsingContext('AnalysisServer success', () async {
      _createSampleProject(tempDir);

      await pubGet(directory: tempDir.path);

      server = new AnalysisServer(dartSdkPath, <String>[tempDir.path]);

      int errorCount = 0;
      Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
      server.onErrors.listen((FileAnalysisErrors errors) => errorCount += errors.errors.length);

      await server.start();
      await onDone;

      expect(errorCount, 0);
    }, overrides: <Type, dynamic>{
      OperatingSystemUtils: os
    });

    testUsingContext('AnalysisServer errors', () async {
      _createSampleProject(tempDir, brokenCode: true);

      await pubGet(directory: tempDir.path);

      server = new AnalysisServer(dartSdkPath, <String>[tempDir.path]);

      int errorCount = 0;
      Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
      server.onErrors.listen((FileAnalysisErrors errors) => errorCount += errors.errors.length);

      await server.start();
      await onDone;

      expect(errorCount, 2);
    }, overrides: <Type, dynamic>{
      OperatingSystemUtils: os
    });

    testUsingContext('inRepo', () {
      AnalyzeCommand cmd = new AnalyzeCommand();
      // Absolute paths
      expect(cmd.inRepo(<String>[tempDir.path]), isFalse);
      expect(cmd.inRepo(<String>[path.join(tempDir.path, 'foo')]), isFalse);
      expect(cmd.inRepo(<String>[Cache.flutterRoot]), isTrue);
      expect(cmd.inRepo(<String>[path.join(Cache.flutterRoot, 'foo')]), isTrue);
      // Relative paths
      var oldWorkingDirectory = path.current;
      try {
        Directory.current = Cache.flutterRoot;
        expect(cmd.inRepo(['.']), isTrue);
        expect(cmd.inRepo(['foo']), isTrue);
        Directory.current = tempDir.path;
        expect(cmd.inRepo(['.']), isFalse);
        expect(cmd.inRepo(['foo']), isFalse);
      } finally {
        Directory.current = oldWorkingDirectory;
      }
      // Ensure no exceptions
      cmd.inRepo(null);
      cmd.inRepo(<String>[]);
    });
  });
}

void _createSampleProject(Directory directory, { bool brokenCode: false }) {
  File pubspecFile = new File(path.join(directory.path, 'pubspec.yaml'));
  pubspecFile.writeAsStringSync('''
name: foo_project
''');

  File dartFile = new File(path.join(directory.path, 'lib', 'main.dart'));
  dartFile.parent.createSync();
  dartFile.writeAsStringSync('''
void main() {
  print('hello world');
  ${brokenCode ? 'prints("hello world");' : ''}
}
''');
}
