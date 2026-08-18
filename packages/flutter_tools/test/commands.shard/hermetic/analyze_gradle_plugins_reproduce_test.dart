// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/project_validator.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;
  late Terminal terminal;
  late ProcessManager processManager;
  late Platform platform;

  group('analyze --suggestions with AndroidGradlePluginValidator', () {
    setUp(() {
      Cache.disableLocking();
      fileSystem = MemoryFileSystem.test();
      Cache.flutterRoot = '/flutter';
      fileSystem.directory('/flutter/bin/cache').createSync(recursive: true);
      fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: foo_project
environment:
  sdk: ^3.7.0-0
''');
      fileSystem.directory('android/app').createSync(recursive: true);
      terminal = Terminal.test();
      processManager = FakeProcessManager.empty();
      platform = FakePlatform();
    });

    tearDown(() {
      Cache.enableLocking();
    });

    testUsingContext(
      'passes when correct Groovy plugins are applied',
      () async {
        fileSystem.file('android/settings.gradle').writeAsStringSync('''
pluginManagement {
    plugins {
        id "dev.flutter.flutter-gradle-plugin" version "1.0.0"
    }
}
''');
        fileSystem.file('android/build.gradle').writeAsStringSync('''
plugins {
    id 'dev.flutter.flutter-plugin-loader' version "1.0.0"
}
''');
        fileSystem.file('android/app/build.gradle').writeAsStringSync('''
apply plugin: 'dev.flutter.flutter-plugin-loader'
''');

        final loggerTest = BufferLogger.test(
          outputPreferences: OutputPreferences.test(wrapColumn: 1000),
        );
        final command = AnalyzeCommand(
          artifacts: Artifacts.test(),
          fileSystem: fileSystem,
          logger: loggerTest,
          platform: platform,
          terminal: terminal,
          processManager: processManager,
          allProjectValidators: <ProjectValidator>[
            AndroidProjectGradlePluginValidator(),
          ],
          suppressAnalytics: true,
        );
        final CommandRunner<void> runner = createTestCommandRunner(command);

        await runner.run(<String>['analyze', '--suggestions', '--no-pub', './']);

        expect(loggerTest.statusText, contains('[✓] Gradle plugins check: Correct plugins applied'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Cache: () => Cache.test(processManager: processManager, fileSystem: fileSystem),
      },
    );

    testUsingContext(
      'passes when correct Kotlin DSL plugins are applied',
      () async {
        fileSystem.file('android/settings.gradle.kts').writeAsStringSync('''
pluginManagement {
    plugins {
        id("dev.flutter.flutter-gradle-plugin") version "1.0.0"
    }
}
''');
        fileSystem.file('android/build.gradle.kts').writeAsStringSync('''
plugins {
    id("dev.flutter.flutter-plugin-loader")
}
''');
        fileSystem.file('android/app/build.gradle.kts').writeAsStringSync('''
plugins {
    id("dev.flutter.flutter-plugin-loader")
}
''');

        final loggerTest = BufferLogger.test(
          outputPreferences: OutputPreferences.test(wrapColumn: 1000),
        );
        final command = AnalyzeCommand(
          artifacts: Artifacts.test(),
          fileSystem: fileSystem,
          logger: loggerTest,
          platform: platform,
          terminal: terminal,
          processManager: processManager,
          allProjectValidators: <ProjectValidator>[
            AndroidProjectGradlePluginValidator(),
          ],
          suppressAnalytics: true,
        );
        final CommandRunner<void> runner = createTestCommandRunner(command);

        await runner.run(<String>['analyze', '--suggestions', '--no-pub', './']);

        expect(loggerTest.statusText, contains('[✓] Gradle plugins check: Correct plugins applied'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Cache: () => Cache.test(processManager: processManager, fileSystem: fileSystem),
      },
    );

    testUsingContext(
      'fails when incorrect plugins are applied (Groovy style)',
      () async {
        fileSystem.file('android/settings.gradle').writeAsStringSync('''
pluginManagement {
    plugins {
        id 'dev.flutter.flutter-plugin-loader' version "1.0.0"
    }
}
''');
        fileSystem.file('android/build.gradle').writeAsStringSync('''
plugins {
    id "dev.flutter.flutter-gradle-plugin" version "1.0.0"
}
''');
        fileSystem.file('android/app/build.gradle').writeAsStringSync('''
apply plugin: "dev.flutter.flutter-gradle-plugin"
''');

        final loggerTest = BufferLogger.test(
          outputPreferences: OutputPreferences.test(wrapColumn: 1000),
        );
        final command = AnalyzeCommand(
          artifacts: Artifacts.test(),
          fileSystem: fileSystem,
          logger: loggerTest,
          platform: platform,
          terminal: terminal,
          processManager: processManager,
          allProjectValidators: <ProjectValidator>[
            AndroidProjectGradlePluginValidator(),
          ],
          suppressAnalytics: true,
        );
        final CommandRunner<void> runner = createTestCommandRunner(command);

        await runner.run(<String>['analyze', '--suggestions', '--no-pub', './']);

        expect(
          loggerTest.statusText,
          contains('[✗] settings.gradle: dev.flutter.flutter-plugin-loader applied in settings.gradle'),
        );
        expect(
          loggerTest.statusText,
          contains('warning: The dev.flutter.flutter-plugin-loader plugin should be applied in build.gradle, not settings.gradle. Use dev.flutter.flutter-gradle-plugin instead.'),
        );
        expect(
          loggerTest.statusText,
          contains('[✗] build.gradle: dev.flutter.flutter-gradle-plugin applied in build.gradle'),
        );
        expect(
          loggerTest.statusText,
          contains('warning: The dev.flutter.flutter-gradle-plugin plugin should be applied in settings.gradle, not build.gradle. Use dev.flutter.flutter-plugin-loader instead.'),
        );
        expect(
          loggerTest.statusText,
          contains('[✗] app/build.gradle: dev.flutter.flutter-gradle-plugin applied in app/build.gradle'),
        );
        expect(
          loggerTest.statusText,
          contains('warning: The dev.flutter.flutter-gradle-plugin plugin should be applied in settings.gradle, not app/build.gradle. Use dev.flutter.flutter-plugin-loader instead.'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Cache: () => Cache.test(processManager: processManager, fileSystem: fileSystem),
      },
    );

    testUsingContext(
      'fails when incorrect plugins are applied (Kotlin DSL style)',
      () async {
        fileSystem.file('android/settings.gradle.kts').writeAsStringSync('''
pluginManagement {
    plugins {
        id("dev.flutter.flutter-plugin-loader")
    }
}
''');
        fileSystem.file('android/build.gradle.kts').writeAsStringSync('''
plugins {
    id("dev.flutter.flutter-gradle-plugin")
}
''');
        fileSystem.file('android/app/build.gradle.kts').writeAsStringSync('''
plugins {
    id("dev.flutter.flutter-gradle-plugin")
}
''');

        final loggerTest = BufferLogger.test(
          outputPreferences: OutputPreferences.test(wrapColumn: 1000),
        );
        final command = AnalyzeCommand(
          artifacts: Artifacts.test(),
          fileSystem: fileSystem,
          logger: loggerTest,
          platform: platform,
          terminal: terminal,
          processManager: processManager,
          allProjectValidators: <ProjectValidator>[
            AndroidProjectGradlePluginValidator(),
          ],
          suppressAnalytics: true,
        );
        final CommandRunner<void> runner = createTestCommandRunner(command);

        await runner.run(<String>['analyze', '--suggestions', '--no-pub', './']);

        expect(
          loggerTest.statusText,
          contains('[✗] settings.gradle.kts: dev.flutter.flutter-plugin-loader applied in settings.gradle.kts'),
        );
        expect(
          loggerTest.statusText,
          contains('warning: The dev.flutter.flutter-plugin-loader plugin should be applied in build.gradle, not settings.gradle. Use dev.flutter.flutter-gradle-plugin instead.'),
        );
        expect(
          loggerTest.statusText,
          contains('[✗] build.gradle.kts: dev.flutter.flutter-gradle-plugin applied in build.gradle.kts'),
        );
        expect(
          loggerTest.statusText,
          contains('warning: The dev.flutter.flutter-gradle-plugin plugin should be applied in settings.gradle, not build.gradle. Use dev.flutter.flutter-plugin-loader instead.'),
        );
        expect(
          loggerTest.statusText,
          contains('[✗] app/build.gradle.kts: dev.flutter.flutter-gradle-plugin applied in app/build.gradle.kts'),
        );
        expect(
          loggerTest.statusText,
          contains('warning: The dev.flutter.flutter-gradle-plugin plugin should be applied in settings.gradle, not app/build.gradle. Use dev.flutter.flutter-plugin-loader instead.'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Cache: () => Cache.test(processManager: processManager, fileSystem: fileSystem),
      },
    );
  });
}
