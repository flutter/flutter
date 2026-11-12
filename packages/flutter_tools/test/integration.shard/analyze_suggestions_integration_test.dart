// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/project_validator.dart';

import '../src/common.dart';
import '../src/fakes.dart';
import '../src/test_flutter_command_runner.dart';
import 'test_utils.dart';

void main() {
  group('analyze --suggestions command integration', () {
    testWithoutContext('General Info Project Validator', () async {
      Cache.disableLocking();
      addTearDown(Cache.enableLocking);
      final loggerTest = BufferLogger.test();
      final String flutterRoot = getFlutterRoot();
      final cache = Cache.test(
        rootOverride: fileSystem.directory(flutterRoot),
        flutterRoot: flutterRoot,
        fileSystem: fileSystem,
        logger: loggerTest,
        platform: platform,
        processManager: processManager,
      );
      final artifacts = CachedArtifacts(
        fileSystem: fileSystem,
        cache: cache,
        platform: platform,
        operatingSystemUtils: cache.osUtils,
      );
      final config = Config.test(logger: loggerTest);
      final toolContext = FakeToolContext(
        artifacts: artifacts,
        cache: cache,
        config: config,
        fs: fileSystem,
        logger: loggerTest,
        os: cache.osUtils,
        platform: platform,
        processManager: processManager,
        terminal: AnsiTerminal(stdio: Stdio(), platform: platform),
      );
      final Java? java = Java.find(
        androidStudioBuilder: () => AndroidStudio.latestValid(toolContext: toolContext),
        config: config,
        fileSystem: fileSystem,
        logger: loggerTest,
        platform: platform,
        processManager: processManager,
      );
      final command = AnalyzeCommand(
        allProjectValidators: <ProjectValidator>[
          GeneralInfoProjectValidator(
            androidContext: FakeAndroidContext(java: java),
            logger: loggerTest,
            processManager: processManager,
          ),
        ],
        suppressAnalytics: true,
        toolContext: toolContext,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>[
        'analyze',
        '--no-pub',
        '--no-current-package',
        '--suggestions',
        '../../dev/integration_tests/flutter_gallery',
      ]);

      const expected =
          '\n'
          '┌───────────────────────────────────────────────────────────────────────────┐\n'
          '│ General Info                                                              │\n'
          '│ [✓] App Name: flutter_gallery                                             │\n'
          '│ [✓] Supported Platforms: android, ios, web, macos, linux, windows         │\n'
          '│ [✓] Is Flutter Package: yes                                               │\n'
          '│ [✓] Uses Material Design: yes                                             │\n'
          '│ [✓] Is Plugin: no                                                         │\n'
          '│ [✓] Java/Gradle/KGP/Android Gradle Plugin: ${AndroidProject.validJavaGradleAgpKgpString} │\n'
          '└───────────────────────────────────────────────────────────────────────────┘\n';

      expect(loggerTest.statusText, contains(expected));
    });
  });

  group('analyze --suggestions --machine command integration', () {
    late Directory tempDir;
    late Platform platform;

    setUpAll(() async {
      platform = const LocalPlatform();
      tempDir = createResolvedTempDirectorySync('run_test.');
      await processManager.run(<String>[
        'flutter',
        'create',
        'test_project',
      ], workingDirectory: tempDir.path);
    });

    tearDown(() async {
      tryToDelete(tempDir);
    });

    testWithoutContext('analyze --suggestions --machine produces expected values', () async {
      final ProcessResult result = await processManager.run(<String>[
        'flutter',
        'analyze',
        '--suggestions',
        '--machine',
      ], workingDirectory: tempDir.childDirectory('test_project').path);

      expect(result.stdout is String, true);
      expect((result.stdout as String).startsWith('{\n'), true);
      expect(result.stdout, isNot(contains(',\n}'))); // No trailing commas allowed in JSON
      expect((result.stdout as String).endsWith('}\n'), true);

      final decoded = jsonDecode(result.stdout as String) as Map<String, Object?>;

      expect(decoded.containsKey('FlutterProject.android.exists'), true);
      expect(decoded.containsKey('FlutterProject.ios.exists'), true);
      expect(decoded.containsKey('FlutterProject.web.exists'), true);
      expect(decoded.containsKey('FlutterProject.macos.exists'), true);
      expect(decoded.containsKey('FlutterProject.linux.exists'), true);
      expect(decoded.containsKey('FlutterProject.windows.exists'), true);
      expect(decoded.containsKey('FlutterProject.fuchsia.exists'), true);
      expect(decoded.containsKey('FlutterProject.android.isKotlin'), true);
      expect(decoded.containsKey('FlutterProject.ios.isSwift'), true);
      expect(decoded.containsKey('FlutterProject.isModule'), true);
      expect(decoded.containsKey('FlutterProject.isPlugin'), true);
      expect(decoded.containsKey('FlutterProject.manifest.appname'), true);
      expect(decoded.containsKey('FlutterVersion.frameworkRevision'), true);

      expect(decoded.containsKey('FlutterProject.directory'), true);
      expect(decoded.containsKey('FlutterProject.metadataFile'), true);
      expect(decoded.containsKey('Platform.operatingSystem'), true);
      expect(decoded.containsKey('Platform.isAndroid'), true);
      expect(decoded.containsKey('Platform.isIOS'), true);
      expect(decoded.containsKey('Platform.isWindows'), true);
      expect(decoded.containsKey('Platform.isMacOS'), true);
      expect(decoded.containsKey('Platform.isFuchsia'), true);
      expect(decoded.containsKey('Platform.pathSeparator'), true);
      expect(decoded.containsKey('Cache.flutterRoot'), true);

      expect(decoded['FlutterProject.android.exists'], true);
      expect(decoded['FlutterProject.ios.exists'], true);
      expect(decoded['FlutterProject.web.exists'], true);
      expect(decoded['FlutterProject.macos.exists'], true);
      expect(decoded['FlutterProject.linux.exists'], true);
      expect(decoded['FlutterProject.windows.exists'], true);
      expect(decoded['FlutterProject.fuchsia.exists'], false);
      expect(decoded['FlutterProject.android.isKotlin'], true);
      expect(decoded['FlutterProject.ios.isSwift'], true);
      expect(decoded['FlutterProject.isModule'], false);
      expect(decoded['FlutterProject.isPlugin'], false);
      expect(decoded['FlutterProject.manifest.appname'], 'test_project');

      expect(decoded['Platform.isAndroid'], false);
      expect(decoded['Platform.isIOS'], false);
      expect(decoded['Platform.isWindows'], platform.isWindows);
      expect(decoded['Platform.isMacOS'], platform.isMacOS);
      expect(decoded['Platform.isFuchsia'], platform.isFuchsia);
      expect(decoded['Platform.pathSeparator'], platform.pathSeparator);
    });
  });
}
