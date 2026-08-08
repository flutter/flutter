// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_aar.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/android_common.dart';
import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late BufferLogger logger;
  late MemoryFileSystem fs;
  late FakeProcessManager processManager;
  late Platform platform;
  late Cache cache;
  late FakeAnalytics fakeAnalytics;
  late FakeToolContext toolContext;
  late FakeAndroidContext androidContext;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fs = MemoryFileSystem.test();
    final Directory flutterRoot = fs.directory('flutter');
    Cache.flutterRoot = flutterRoot.path;
    logger = BufferLogger.test();
    platform = FakePlatform(environment: const <String, String>{'PATH': ''});
    processManager = FakeProcessManager.empty();
    cache = Cache.test(rootOverride: flutterRoot, logger: logger, processManager: processManager);
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fs,
      fakeFlutterVersion: FakeFlutterVersion(),
    );
    toolContext = FakeToolContext(
      cache: cache,
      fs: fs,
      logger: logger,
      platform: platform,
      processManager: processManager,
      projectFactory: FlutterProjectFactory(fileSystem: fs, logger: logger),
    );
    androidContext = FakeAndroidContext(androidSdk: FakeAndroidSdk());
  });

  testWithoutContext('will not build an AAR for a plugin', () async {
    fs.file('pubspec.yaml').writeAsStringSync('''
name: foo_bar

flutter:
  plugin:
    platforms:
      some_platform:
        null
''');

    final command = BuildAarCommand(
      androidBuilder: FakeAndroidBuilder(),
      androidContext: androidContext,
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    expect(
      createTestCommandRunner(command).run(const <String>['aar', '--no-pub']),
      throwsToolExit(message: 'AARs can only be built from modules'),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('will build an AAR for a module', () async {
    fs.file('pubspec.yaml').writeAsStringSync('''
name: foo_bar

flutter:
  module:
    foo: bar
''');
    final Directory dotAndroidDir = fs.directory('.android')..createSync(recursive: true);
    dotAndroidDir.childFile('gradlew').createSync();

    final command = BuildAarCommand(
      androidBuilder: FakeAndroidBuilder(),
      androidContext: androidContext,
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    await createTestCommandRunner(command, fakeAnalytics).run(const <String>['aar', '--no-pub']);
    expect(
      fakeAnalytics.sentEvents,
      contains(
        Event.commandUsageValues(
          workflow: 'aar',
          commandHasTerminal: false,
          buildAarProjectType: 'module',
          buildAarTargetPlatform: 'android-arm,android-arm64,android-x64',
        ),
      ),
    );
  });

  testWithoutContext('throws ToolExit if androidSdk is null', () async {
    fs.file('pubspec.yaml').writeAsStringSync('''
name: foo_bar

flutter:
  module:
    foo: bar
''');

    final command = BuildAarCommand(
      androidBuilder: FakeAndroidBuilder(),
      androidContext: FakeAndroidContext(),
      androidSdk: null,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    expect(
      createTestCommandRunner(command).run(const <String>['aar', '--no-pub']),
      throwsToolExit(message: 'No Android SDK found'),
    );
  });
}
