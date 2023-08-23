// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/project_validator.dart';
import 'package:test/fake.dart';

import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {

  group('Android analyze command', () {
    late FileSystem fileSystem;
    late Platform platform;
    late BufferLogger logger;
    late FakeProcessManager processManager;
    late Terminal terminal;
    late AnalyzeCommand command;
    late CommandRunner<void> runner;
    late Directory tempDir;
    late FakeAndroidBuilder builder;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() async {
      fileSystem = MemoryFileSystem.test();
      platform = FakePlatform();
      logger = BufferLogger.test();
      processManager = FakeProcessManager.empty();
      terminal = Terminal.test();
      command = AnalyzeCommand(
        artifacts: Artifacts.test(),
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
        terminal: terminal,
        allProjectValidators: <ProjectValidator>[],
        suppressAnalytics: true,
      );
      runner = createTestCommandRunner(command);
      tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      tempDir.childDirectory('android').createSync();

      // Setup repo roots
      const String homePath = '/home/user/flutter';
      Cache.flutterRoot = homePath;
      for (final String dir in <String>['dev', 'examples', 'packages']) {
        fileSystem.directory(homePath).childDirectory(dir).createSync(recursive: true);
      }
      builder = FakeAndroidBuilder();

    });

    testUsingContext('can list build variants', () async {
      builder.variants = <String>['debug', 'release'];
      await runner.run(<String>['analyze', '--android', '--list-build-variants', tempDir.path]);
      expect(logger.statusText, contains('["debug","release"]'));
    }, overrides: <Type, Generator>{
      AndroidBuilder: () => builder,
    });

    testUsingContext('throw if provide multiple path', () async {
      final Directory anotherTempDir = fileSystem.systemTempDirectory.createTempSync('another');
      await expectLater(
        runner.run(<String>['analyze', '--android', '--list-build-variants', tempDir.path, anotherTempDir.path]),
        throwsA(
          isA<Exception>().having(
            (Exception e) => e.toString(),
          'description',
          contains('The Android analyze can process only one directory path'),
          ),
        ),
      );
    });

    testUsingContext('can output app link settings', () async {
      const String buildVariant = 'release';
      await runner.run(<String>['analyze', '--android', '--output-app-link-settings', '--build-variant=$buildVariant', tempDir.path]);
      expect(builder.outputVariant, buildVariant);
    }, overrides: <Type, Generator>{
      AndroidBuilder: () => builder,
    });

    testUsingContext('output app link settings throws if no build variant', () async {
      await expectLater(
        runner.run(<String>['analyze', '--android', '--output-app-link-settings', tempDir.path]),
        throwsA(
          isA<Exception>().having(
            (Exception e) => e.toString(),
            'description',
            contains('"--build-variant" must be provided'),
          ),
        ),
      );
    });
  });
}

class FakeAndroidBuilder extends Fake implements AndroidBuilder {
  List<String> variants = const <String>[];
  String? outputVariant;

  @override
  Future<List<String>> getBuildVariants({required FlutterProject project}) async {
    return variants;
  }

  @override
  Future<void> outputsAppLinkSettings(String buildVariant, {required FlutterProject project}) async {
    outputVariant = buildVariant;
  }
}
