// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_apk.dart';
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

  void createMinimalProject() {
    fs.file('pubspec.yaml').writeAsStringSync('''
name: foo_bar
description: A sample app
version: 1.0.0+1
environment:
  sdk: '>=3.0.0 <4.0.0'
flutter:
  uses-material-design: true
''');
    fs.file('lib/main.dart').createSync(recursive: true);
    final Directory androidDir = fs.directory('android')..createSync(recursive: true);
    androidDir.childFile('build.gradle').createSync();
    final File manifestFile = androidDir.childFile('app/src/main/AndroidManifest.xml');
    manifestFile.createSync(recursive: true);
    manifestFile.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="foo_bar">
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''');
  }

  testWithoutContext('throws ToolExit if androidSdk is null', () async {
    createMinimalProject();

    final command = BuildApkCommand(
      androidBuilder: FakeAndroidBuilder(),
      androidContext: FakeAndroidContext(),
      androidSdk: null,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    expect(
      createTestCommandRunner(command).run(const <String>['apk', '--no-pub']),
      throwsToolExit(message: 'No Android SDK found'),
    );
  });

  testWithoutContext('builds APK successfully with default arguments', () async {
    createMinimalProject();

    var buildApkCalled = false;
    final fakeBuilder = _RecordingAndroidBuilder(
      onBuildApk:
          ({
            required FlutterProject project,
            required AndroidBuildInfo androidBuildInfo,
            required String target,
            bool configOnly = false,
          }) {
            buildApkCalled = true;
          },
    );

    final command = BuildApkCommand(
      androidBuilder: fakeBuilder,
      androidContext: androidContext,
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    await createTestCommandRunner(command, fakeAnalytics).run(const <String>['apk', '--no-pub']);
    expect(buildApkCalled, isTrue);
    expect(
      fakeAnalytics.sentEvents,
      contains(Event.flutterBuildInfo(label: 'manifest-impeller-enabled', buildType: 'android')),
    );
  });

  testWithoutContext('records unified analytics usage values', () async {
    createMinimalProject();

    final command = BuildApkCommand(
      androidBuilder: FakeAndroidBuilder(),
      androidContext: androidContext,
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['apk', '--no-pub']);
    final Event event = await command.unifiedAnalyticsUsageValues('apk');
    expect(
      event,
      Event.commandUsageValues(
        workflow: 'apk',
        commandHasTerminal: false,
        buildApkTargetPlatform: 'android-arm,android-arm64,android-x64',
        buildApkBuildMode: 'release',
        buildApkSplitPerAbi: false,
        buildApkEnableHcpp: false,
      ),
    );
  });

  testWithoutContext('passes splitPerAbi and targetPlatform to AndroidBuildInfo', () async {
    createMinimalProject();

    AndroidBuildInfo? capturedBuildInfo;
    final fakeBuilder = _RecordingAndroidBuilder(
      onBuildApk:
          ({
            required FlutterProject project,
            required AndroidBuildInfo androidBuildInfo,
            required String target,
            bool configOnly = false,
          }) {
            capturedBuildInfo = androidBuildInfo;
          },
    );

    final command = BuildApkCommand(
      androidBuilder: fakeBuilder,
      androidContext: androidContext,
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    await createTestCommandRunner(command).run(const <String>[
      'apk',
      '--no-pub',
      '--split-per-abi',
      '--target-platform=android-arm64',
      '--debug',
    ]);

    expect(capturedBuildInfo, isNotNull);
    expect(capturedBuildInfo!.splitPerAbi, isTrue);
    expect(capturedBuildInfo!.targetArchs, <CpuArch>[CpuArch.arm64]);
    expect(capturedBuildInfo!.buildInfo.mode, BuildMode.debug);
  });
}

class _RecordingAndroidBuilder extends FakeAndroidBuilder {
  _RecordingAndroidBuilder({this.onBuildApk});

  final void Function({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    bool configOnly,
  })?
  onBuildApk;

  @override
  Future<void> buildApk({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    bool configOnly = false,
  }) async {
    onBuildApk?.call(
      project: project,
      androidBuildInfo: androidBuildInfo,
      target: target,
      configOnly: configOnly,
    );
  }
}
