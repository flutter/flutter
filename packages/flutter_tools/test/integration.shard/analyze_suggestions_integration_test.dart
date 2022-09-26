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
      '┌───────────────────────────────────────────────────────────────────┐\n'
      '│ General Info                                                      │\n'
      '│ [✓] App Name: flutter_gallery                                     │\n'
      '│ [✓] Supported Platforms: android, ios, web, macos, linux, windows │\n'
      '│ [✓] Is Flutter Package: yes                                       │\n'
      '│ [✓] Uses Material Design: yes                                     │\n'
      '│ [✓] Is Plugin: no                                                 │\n'
      '└───────────────────────────────────────────────────────────────────┘\n';

      expect(loggerTest.statusText, contains(expected));
    });

    testUsingContext('PubDependenciesProjectValidator success ', () async {
      final BufferLogger loggerTest = BufferLogger.test();
      final AnalyzeCommand command = AnalyzeCommand(
        artifacts: globals.artifacts!,
        fileSystem: fileSystem,
        logger: loggerTest,
        platform: globals.platform,
        terminal: globals.terminal,
        processManager: globals.processManager,
        allProjectValidators: <ProjectValidator>[
          PubDependenciesProjectValidator(globals.processManager),
        ],
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
        '┌────────────────────────────────────────────────────────────────────────────────────┐\n'
        '│ Pub dependencies                                                                   │\n'
        '│ [✓] Dart dependencies: All pub dependencies are hosted on https://pub.dartlang.org │\n'
        '└────────────────────────────────────────────────────────────────────────────────────┘\n';
      expect(loggerTest.statusText, contains(expected));
    });
  });

  group('analyze --suggestions --machine command integration', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = createResolvedTempDirectorySync('run_test.');
      await globals.processManager.run(<String>['flutter', 'create', 'test_project'], workingDirectory: tempDir.path);
    });

    tearDown(() async {
      tryToDelete(tempDir);
    });

    testUsingContext('analyze --suggesions --machine produces expected values', () async {
      final ProcessResult result = await globals.processManager.run(<String>['flutter', 'analyze', '--info'], workingDirectory: tempDir.childDirectory('test_project').path);

      expect(result.stdout is String, true);
      expect((result.stdout as String).startsWith('{'), true);
      expect(result.stdout, contains('"FlutterProject.directory": "')); // We dont verify path as it is a temp path that changes
      expect(result.stdout, contains('"FlutterProject.metadataFile": "')); // We dont verify path as it is a temp path that changes
      expect(result.stdout, contains('"FlutterProject.android.exists": true,'));
      expect(result.stdout, contains('"FlutterProject.ios.exists": true,'));
      expect(result.stdout, contains('"FlutterProject.web.exists": true,'));
      expect(result.stdout, contains('"FlutterProject.macos.exists": true,'));
      expect(result.stdout, contains('"FlutterProject.linux.exists": true,'));
      expect(result.stdout, contains('"FlutterProject.windows.exists": true,'));
      expect(result.stdout, contains('"FlutterProject.fuchsia.exists": false,'));
      expect(result.stdout, contains('"FlutterProject.android.isKotlin": true,'));
      expect(result.stdout, contains('"FlutterProject.ios.isSwift": true,'));
      expect(result.stdout, contains('"FlutterProject.isModule": false,'));
      expect(result.stdout, contains('"FlutterProject.isPlugin": false,'));
      expect(result.stdout, contains('"FlutterProject.manifest.appname": "test_project",'));
      expect(result.stdout, contains('"FlutterVersion.frameworkRevision": "",'));
      expect(result.stdout, contains('"Platform.operatingSystem": "macos",'));
      expect(result.stdout, contains('"Platform.isAndroid": false,'));
      expect(result.stdout, contains('"Platform.isIOS": false,'));
      expect(result.stdout, contains('"Platform.isWindows": false,'));
      expect(result.stdout, contains('"Platform.isMacOS": true,'));
      expect(result.stdout, contains('"Platform.isFuchsia": false,'));
      expect(result.stdout, contains('"Platform.pathSeparator": "/",'));
      expect(result.stdout, contains('"Cache.flutterRoot": "')); // We dont verify path as it is a temp path that changes
      expect((result.stdout as String).endsWith('}\n'), true);
    }, overrides: <Type, Generator>{});
  });
}
