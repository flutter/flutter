// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project_validator.dart';

import '../src/context.dart';
import '../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;

  group('analyze --suggestions command integration', () {

    setUp(() {
      fileSystem = globals.localFileSystem;
    });

    testUsingContext('General Info Project Validator', () async {
      final BufferLogger loggerTest = BufferLogger.test();
      final AnalyzeCommand command = AnalyzeCommand(
          artifacts: globals.artifacts!,
          fileSystem: fileSystem,
          logger: loggerTest,
          platform: globals.platform,
          terminal: globals.terminal,
          processManager: globals.processManager,
          allProjectValidators: <ProjectValidator>[GeneralInfoProjectValidator()],
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>[
        'analyze',
        '--no-pub',
        '--no-current-package',
        '--suggestions',
        '../../dev/integration_tests/flutter_gallery',
      ]);

      const String expected = '\n'
      '┌────────────────────────────────────────────────────────────────────────────┐\n'
      '│ General Info                                                               │\n'
      '│ [✓] App Name: flutter_gallery                                              │\n'
      '│ [✓] Supported Platforms: android, ios, web, macos, linux, windows, fuchsia │\n'
      '│ [✓] Is Flutter Package: yes                                                │\n'
      '│ [✓] Uses Material Design: yes                                              │\n'
      '│ [✓] Is Plugin: no                                                          │\n'
      '└────────────────────────────────────────────────────────────────────────────┘\n';

      expect(loggerTest.statusText, contains(expected));
    });
  });
}
