// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/commands/analyze_continuously.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  AnalysisServer server;
  Directory tempDir;

  setUp(() {
    FlutterCommandRunner.initFlutterRoot();
    tempDir = fs.systemTempDirectory.createTempSync('analysis_test');
  });

  Future<AnalysisServer> analyzeWithServer({ bool brokenCode: false, bool flutterRepo: false, int expectedErrorCount: 0 }) async {
    _createSampleProject(tempDir, brokenCode: brokenCode);

    await pubGet(directory: tempDir.path);

    server = new AnalysisServer(dartSdkPath, <String>[tempDir.path], flutterRepo: flutterRepo);

    final Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
    final List<AnalysisError> errors = <AnalysisError>[];
    server.onErrors.listen((FileAnalysisErrors fileErrors) {
      errors.addAll(fileErrors.errors);
    });

    await server.start();
    await onDone;

    expect(errors, hasLength(expectedErrorCount));
    return server;
  }

  tearDown(() {
    tempDir?.deleteSync(recursive: true);
    return server?.dispose();
  });

  group('analyze --watch', () {
  });

  group('AnalysisServer', () {
    testUsingContext('success', () async {
      server = await analyzeWithServer();
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => os
    });

    testUsingContext('errors', () async {
      server = await analyzeWithServer(brokenCode: true, expectedErrorCount: 1);
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => os
    });

    testUsingContext('--flutter-repo', () async {
      // When a Dart SDK containing support for the --flutter-repo startup flag
      // https://github.com/dart-lang/sdk/commit/def1ee6604c4b3385b567cb9832af0dbbaf32e0d
      // is rolled into Flutter, then the expectedErrorCount should be set to 1.
      server = await analyzeWithServer(flutterRepo: true, expectedErrorCount: 0);
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => os
    });
  });
}

void _createSampleProject(Directory directory, { bool brokenCode: false }) {
  final File pubspecFile = fs.file(fs.path.join(directory.path, 'pubspec.yaml'));
  pubspecFile.writeAsStringSync('''
name: foo_project
''');

  final File analysisOptionsFile = fs.file(fs.path.join(directory.path, 'analysis_options.yaml'));
  analysisOptionsFile.writeAsStringSync('''
linter:
  rules:
    - hash_and_equals
''');

  final File dartFile = fs.file(fs.path.join(directory.path, 'lib', 'main.dart'));
  dartFile.parent.createSync();
  dartFile.writeAsStringSync('''
void main() {
  print('hello world');
  ${brokenCode ? 'prints("hello world");' : ''}
}

class SomeClassWithoutDartDoc { }
''');
}
