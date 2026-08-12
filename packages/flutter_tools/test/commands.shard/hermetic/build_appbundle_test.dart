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
import 'package:flutter_tools/src/commands/build_appbundle.dart';
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

  testWithoutContext('has alias aab', () async {
    final command = BuildAppBundleCommand(
      androidBuilder: FakeAndroidBuilder(),
      androidContext: androidContext,
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );
    expect(command.aliases, contains('aab'));
  });

  testWithoutContext('throws ToolExit if androidSdk is null', () async {
    createMinimalProject();

    final command = BuildAppBundleCommand(
      androidBuilder: FakeAndroidBuilder(),
      androidContext: FakeAndroidContext(),
      androidSdk: null,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    expect(
      createTestCommandRunner(command).run(const <String>['appbundle', '--no-pub']),
      throwsToolExit(message: 'No Android SDK found'),
    );
  });

  testWithoutContext('builds AppBundle successfully with default arguments', () async {
    createMinimalProject();

    var buildAabCalled = false;
    final fakeBuilder = _RecordingAndroidBuilder(
      onBuildAab:
          ({
            required FlutterProject project,
            required AndroidBuildInfo androidBuildInfo,
            required String target,
            bool validateDeferredComponents = true,
            bool deferredComponentsEnabled = false,
            bool configOnly = false,
          }) {
            buildAabCalled = true;
          },
    );

    final command = BuildAppBundleCommand(
      androidBuilder: fakeBuilder,
      androidContext: androidContext,
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    await createTestCommandRunner(
      command,
      fakeAnalytics,
    ).run(const <String>['appbundle', '--no-pub']);
    expect(buildAabCalled, isTrue);
    expect(
      fakeAnalytics.sentEvents,
      contains(Event.flutterBuildInfo(label: 'manifest-impeller-enabled', buildType: 'android')),
    );
  });

  testWithoutContext('records unified analytics usage values', () async {
    createMinimalProject();

    final command = BuildAppBundleCommand(
      androidBuilder: FakeAndroidBuilder(),
      androidContext: androidContext,
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['appbundle', '--no-pub']);
    final Event event = await command.unifiedAnalyticsUsageValues('appbundle');
    expect(
      event,
      Event.commandUsageValues(
        workflow: 'appbundle',
        commandHasTerminal: false,
        buildAppBundleTargetPlatform: 'android-arm,android-arm64,android-x64',
        buildAppBundleBuildMode: 'release',
        buildBundleEnableHcpp: false,
      ),
    );
  });

  testWithoutContext('passes targetPlatform and deferred components options', () async {
    createMinimalProject();

    AndroidBuildInfo? capturedBuildInfo;
    bool? capturedDeferredComponentsEnabled;
    final fakeBuilder = _RecordingAndroidBuilder(
      onBuildAab:
          ({
            required FlutterProject project,
            required AndroidBuildInfo androidBuildInfo,
            required String target,
            bool validateDeferredComponents = true,
            bool deferredComponentsEnabled = false,
            bool configOnly = false,
          }) {
            capturedBuildInfo = androidBuildInfo;
            capturedDeferredComponentsEnabled = deferredComponentsEnabled;
          },
    );

    final command = BuildAppBundleCommand(
      androidBuilder: fakeBuilder,
      androidContext: androidContext,
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );

    await createTestCommandRunner(command).run(const <String>[
      'appbundle',
      '--no-pub',
      '--target-platform=android-arm64',
      '--profile',
      '--no-deferred-components',
    ]);

    expect(capturedBuildInfo, isNotNull);
    expect(capturedBuildInfo!.targetArchs, <CpuArch>[CpuArch.arm64]);
    expect(capturedBuildInfo!.buildInfo.mode, BuildMode.profile);
    expect(capturedDeferredComponentsEnabled, isFalse);
  });
}

class _RecordingAndroidBuilder extends FakeAndroidBuilder {
  _RecordingAndroidBuilder({this.onBuildAab});

  final void Function({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    bool validateDeferredComponents,
    bool deferredComponentsEnabled,
    bool configOnly,
  })?
  onBuildAab;

  @override
  Future<void> buildAab({
    required FlutterProject project,
    required AndroidBuildInfo androidBuildInfo,
    required String target,
    bool validateDeferredComponents = true,
    bool deferredComponentsEnabled = false,
    bool configOnly = false,
  }) async {
    onBuildAab?.call(
      project: project,
      androidBuildInfo: androidBuildInfo,
      target: target,
      validateDeferredComponents: validateDeferredComponents,
      deferredComponentsEnabled: deferredComponentsEnabled,
      configOnly: configOnly,
    );
  }
}
