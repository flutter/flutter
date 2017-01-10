// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  group('analyze once', () {
    testUsingContext('success', () async {
      createSampleProject(tempDir);

      await pubGet(directory: tempDir.path);

      AnalyzeCommand command = new AnalyzeCommand();
      applyMocksToCommand(command);
      return createTestCommandRunner(command).run(
          <String>['analyze', path.join(tempDir.path, 'lib', 'main.dart')]
      ).then((_) {
        expect(testLogger.statusText, contains('No analyzer warnings!'));
        expect(testLogger.errorText, isEmpty);
      });
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => os
    });
  });

  testUsingContext('errors', () async {
    createSampleProject(tempDir, brokenCode: true);

    await pubGet(directory: tempDir.path);

    AnalyzeCommand command = new AnalyzeCommand();
    applyMocksToCommand(command);
    bool toolExited = false;
    return createTestCommandRunner(command).run(
        <String>['analyze', path.join(tempDir.path, 'lib', 'main.dart')]
    ).catchError((_) {
      toolExited = true;
    }, test: (dynamic e) => e is ToolExit).then((_) {
      // expect lint specified in flutter user analysis options
      expect(testLogger.errorText, contains('Avoid empty else statements.'));
      expect(testLogger.errorText, contains('Avoid empty statements.'));
      // language warning
      expect(testLogger.errorText, contains('The function \'prints\' isn\'t defined.'));
      expect(toolExited, true);
    });
  }, overrides: <Type, Generator>{
    OperatingSystemUtils: () => os
  });
}
