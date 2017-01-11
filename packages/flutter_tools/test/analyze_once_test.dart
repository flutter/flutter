// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/commands/analyze_continuously.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/analyze_test_common.dart';
import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  AnalysisServer server;
  Directory tempDir;

  setUp(() {
    FlutterCommandRunner.initFlutterRoot();
    tempDir = fs.systemTempDirectory.createTempSync('analysis_test');
  });

  tearDown(() {
    tempDir?.deleteSync(recursive: true);
    return server?.dispose();
  });

  Future<dynamic> _runAnalyze(List<String> args, checkResults(), {bool brokenCode: false}) async {
    createSampleProject(tempDir, brokenCode: brokenCode);

    await pubGet(directory: tempDir.path);

    AnalyzeCommand command = new AnalyzeCommand();
    applyMocksToCommand(command);
    Directory originalDir = fs.currentDirectory;
    fs.currentDirectory = tempDir.path;
    return createTestCommandRunner(command).run(
        <String>['analyze', path.join(tempDir.path, 'lib', 'main.dart')]
    ).then((_) {
      checkResults();
    }).whenComplete(() {
      fs.currentDirectory = originalDir;
    });
  }

  group('analyze once', () {
    group('success', () {
      testUsingContext('directory', () {
        List<String> args = <String>[];
        return _runAnalyze(args, () {
          expect(testLogger.statusText, contains('No issues found'));
          expect(testLogger.errorText, isEmpty);
        });
      }, overrides: <Type, Generator>{
        OperatingSystemUtils: () => os
      });

      testUsingContext('one file', () {
        List<String> args = <String>[path.join(tempDir.path, 'lib', 'main.dart')];
        return _runAnalyze(args, () {
          expect(testLogger.statusText, contains('No issues found'));
          expect(testLogger.errorText, isEmpty);
        });
      }, overrides: <Type, Generator>{
        OperatingSystemUtils: () => os
      });
    });

    group('errors', () {
      testUsingContext('directory', () {
        List<String> args = <String>[];
        return _runAnalyze(args, () {
          String allText = testLogger.statusText + '\n' + testLogger.errorText;
          // language warning
          expect(allText, contains('The function \'prints\' isn\'t defined.'));
          // expect lint specified in flutter user analysis options
          expect(allText, contains('Avoid empty else statements.'));
          expect(allText, contains('Avoid empty statements.'));
          // expect lint specified in user's options file
          expect(allText, contains('Only throw instances of classes extending either Exception or Error'));
          expect(allText, contains('1 error and 3 lints found.'));
        }, brokenCode: true);
      }, overrides: <Type, Generator>{
        OperatingSystemUtils: () => os
      });

      testUsingContext('one file', () {
        List<String> args = <String>[path.join(tempDir.path, 'lib', 'main.dart')];
        return _runAnalyze(args, () {
          String allText = testLogger.statusText + '\n' + testLogger.errorText;
          // language warning
          expect(allText, contains('The function \'prints\' isn\'t defined.'));
          // expect lint specified in flutter user analysis options
          expect(allText, contains('Avoid empty else statements.'));
          expect(allText, contains('Avoid empty statements.'));
          // expect lint specified in user's options file
          expect(allText, contains('Only throw instances of classes extending either Exception or Error'));
          expect(allText, contains('1 error and 3 lints found.'));
        }, brokenCode: true);
      }, overrides: <Type, Generator>{
        OperatingSystemUtils: () => os
      });
    });
  });
}