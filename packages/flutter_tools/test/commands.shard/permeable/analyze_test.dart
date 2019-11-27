// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../../src/common.dart';
import '../../src/context.dart';

final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};

void main() {
  group('analyze', () {
    Directory tempDir;
    String projectPath;

    setUpAll(() {
      Cache.disableLocking();
      tempDir = fs.systemTempDirectory.createTempSync('flutter_analyze.').absolute;
      projectPath = fs.path.join(tempDir.path, 'flutter_project');
    });

    tearDownAll(() {
      tryToDelete(tempDir);
    });

    testUsingContext('--flutter-repo should run update-package first', () async {
      await runCommand(
        command: AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze', '--flutter-repo'],
        statusTextContains: <String>['Running "flutter pub get" in automated_tests...'],
      );
    }, overrides: <Type, Generator>{
      Pub: () => const Pub(),
    });
  });
}

void assertContains(String text, List<String> patterns) {
  if (patterns == null) {
    expect(text, isEmpty);
  } else {
    for (String pattern in patterns) {
      expect(text, contains(pattern));
    }
  }
}

Future<void> runCommand({
  FlutterCommand command,
  List<String> arguments,
  List<String> statusTextContains,
  List<String> errorTextContains,
  bool toolExit = false,
  String exitMessageContains,
}) async {
  try {
    arguments.insert(0, '--flutter-root=${Cache.flutterRoot}');
    await createTestCommandRunner(command).run(arguments);
    expect(toolExit, isFalse, reason: 'Expected ToolExit exception');
  } on ToolExit catch (e) {
    if (!toolExit) {
      testLogger.clear();
      rethrow;
    }
    if (exitMessageContains != null) {
      expect(e.message, contains(exitMessageContains));
    }
  }
  assertContains(testLogger.statusText, statusTextContains);
  assertContains(testLogger.errorText, errorTextContains);

  testLogger.clear();
}
