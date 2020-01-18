// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

const String frameworkRevision = '12345678';
const String frameworkChannel = 'omega';
final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};
const String samplesIndexJson = '''[
  { "id": "sample1" },
  { "id": "sample2" }
]''';

void main() {
  Directory tempDir;
  Directory projectDir;
  FlutterVersion mockFlutterVersion;
  LoggingProcessManager loggingProcessManager;

  setUpAll(() async {
    Cache.disableLocking();
    await _ensureFlutterToolsSnapshot();
  });

  setUp(() {
    loggingProcessManager = LoggingProcessManager();
    tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_create_test.');
    projectDir = tempDir.childDirectory('flutter_project');
    mockFlutterVersion = MockFlutterVersion();
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  tearDownAll(() async {
    await _restoreFlutterToolsSnapshot();
  });

  // Verify that we create a default project ('app') that is
  // well-formed.
  testUsingContext('can create a default project', () async {
    await _createAndAnalyzeProject(
      projectDir,
      <String>['-i', 'objc', '-a', 'java'],
      <String>[
        'android/app/src/main/java/com/example/flutter_project/MainActivity.java',
        'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        'flutter_project.iml',
        'ios/Flutter/AppFrameworkInfo.plist',
        'ios/Runner/AppDelegate.m',
        'ios/Runner/GeneratedPluginRegistrant.h',
        'lib/main.dart',
      ],
    );
    return _runFlutterTest(projectDir);
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('can create a default project if empty directory exists', () async {
    await projectDir.create(recursive: true);
    await _createAndAnalyzeProject(
      projectDir,
      <String>['-i', 'objc', '-a', 'java'],
      <String>[
        'android/app/src/main/java/com/example/flutter_project/MainActivity.java',
        'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        'flutter_project.iml',
        'ios/Flutter/AppFrameworkInfo.plist',
        'ios/Runner/AppDelegate.m',
        'ios/Runner/GeneratedPluginRegistrant.h',
      ],
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('creates a module project correctly', () async {
    await _createAndAnalyzeProject(projectDir, <String>[
      '--template=module',
    ], <String>[
      '.android/app/',
      '.gitignore',
      '.ios/Flutter',
      '.ios/Flutter/flutter_project.podspec',
      '.metadata',
      'lib/main.dart',
      'pubspec.yaml',
      'README.md',
      'test/widget_test.dart',
    ], unexpectedPaths: <String>[
      'android/',
      'ios/',
    ]);
    return _runFlutterTest(projectDir);
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('cannot create a project if non-empty non-project directory exists with .metadata', () async {
    await projectDir.absolute.childDirectory('blag').create(recursive: true);
    await projectDir.absolute.childFile('.metadata').writeAsString('project_type: blag\n');
    expect(() async => await _createAndAnalyzeProject(
        projectDir,
        <String>[],
        <String>[],
        unexpectedPaths: <String>[
          'android/',
          'ios/',
          '.android/',
          '.ios/',
        ]),
      throwsToolExit(message: 'Sorry, unable to detect the type of project to recreate'));
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
    ...noColorTerminalOverride,
  });

  testUsingContext('Will create an app project if non-empty non-project directory exists without .metadata', () async {
    await projectDir.absolute.childDirectory('blag').create(recursive: true);
    await projectDir.absolute.childDirectory('.idea').create(recursive: true);
    await _createAndAnalyzeProject(
      projectDir,
      <String>[
        '-i', 'objc', '-a', 'java',
      ],
      <String>[
        'android/app/src/main/java/com/example/flutter_project/MainActivity.java',
        'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        'flutter_project.iml',
        'ios/Flutter/AppFrameworkInfo.plist',
        'ios/Runner/AppDelegate.m',
        'ios/Runner/GeneratedPluginRegistrant.h',
      ],
      unexpectedPaths: <String>[
        '.android/',
        '.ios/',
      ],
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('detects and recreates an app project correctly', () async {
    await projectDir.absolute.childDirectory('lib').create(recursive: true);
    await projectDir.absolute.childDirectory('ios').create(recursive: true);
    await _createAndAnalyzeProject(
      projectDir,
      <String>[
        '-i', 'objc', '-a', 'java',
      ],
      <String>[
        'android/app/src/main/java/com/example/flutter_project/MainActivity.java',
        'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        'flutter_project.iml',
        'ios/Flutter/AppFrameworkInfo.plist',
        'ios/Runner/AppDelegate.m',
        'ios/Runner/GeneratedPluginRegistrant.h',
      ],
      unexpectedPaths: <String>[
        '.android/',
        '.ios/',
      ],
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('detects and recreates a plugin project correctly', () async {
    await projectDir.create(recursive: true);
    await projectDir.absolute.childFile('.metadata').writeAsString('project_type: plugin\n');
    return _createAndAnalyzeProject(
      projectDir,
      <String>[
        '-i', 'objc', '-a', 'java',
      ],
      <String>[
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
        'example/ios/Runner/AppDelegate.h',
        'example/ios/Runner/AppDelegate.m',
        'example/ios/Runner/main.m',
        'example/lib/main.dart',
        'flutter_project.iml',
        'ios/Classes/FlutterProjectPlugin.h',
        'ios/Classes/FlutterProjectPlugin.m',
        'lib/flutter_project.dart',
      ],
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('detects and recreates a package project correctly', () async {
    await projectDir.create(recursive: true);
    await projectDir.absolute.childFile('.metadata').writeAsString('project_type: package\n');
    return _createAndAnalyzeProject(
      projectDir,
      <String>[],
      <String>[
        'lib/flutter_project.dart',
        'test/flutter_project_test.dart',
      ],
      unexpectedPaths: <String>[
        'android/app/src/main/java/com/example/flutter_project/MainActivity.java',
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
        'example/ios/Runner/AppDelegate.h',
        'example/ios/Runner/AppDelegate.m',
        'example/ios/Runner/main.m',
        'example/lib/main.dart',
        'ios/Classes/FlutterProjectPlugin.h',
        'ios/Classes/FlutterProjectPlugin.m',
        'ios/Runner/AppDelegate.h',
        'ios/Runner/AppDelegate.m',
        'ios/Runner/main.m',
        'lib/main.dart',
        'test/widget_test.dart',
      ],
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('kotlin/swift legacy app project', () async {
    return _createProject(
      projectDir,
      <String>['--no-pub', '--template=app', '--android-language=kotlin', '--ios-language=swift'],
      <String>[
        'android/app/src/main/kotlin/com/example/flutter_project/MainActivity.kt',
        'ios/Runner/AppDelegate.swift',
        'ios/Runner/Runner-Bridging-Header.h',
        'lib/main.dart',
        '.idea/libraries/KotlinJavaRuntime.xml',
      ],
      unexpectedPaths: <String>[
        'android/app/src/main/java/com/example/flutter_project/MainActivity.java',
        'ios/Runner/AppDelegate.h',
        'ios/Runner/AppDelegate.m',
        'ios/Runner/main.m',
      ],
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('can create a package project', () async {
    await _createAndAnalyzeProject(
      projectDir,
      <String>['--template=package'],
      <String>[
        'lib/flutter_project.dart',
        'test/flutter_project_test.dart',
      ],
      unexpectedPaths: <String>[
        'android/app/src/main/java/com/example/flutter_project/MainActivity.java',
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
        'example/ios/Runner/AppDelegate.h',
        'example/ios/Runner/AppDelegate.m',
        'example/ios/Runner/main.m',
        'example/lib/main.dart',
        'ios/Classes/FlutterProjectPlugin.h',
        'ios/Classes/FlutterProjectPlugin.m',
        'ios/Runner/AppDelegate.h',
        'ios/Runner/AppDelegate.m',
        'ios/Runner/main.m',
        'lib/main.dart',
        'test/widget_test.dart',
      ],
    );
    return _runFlutterTest(projectDir);
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('can create a plugin project', () async {
    await _createAndAnalyzeProject(
      projectDir,
      <String>['--template=plugin', '-i', 'objc', '-a', 'java'],
      <String>[
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
        'example/ios/Runner/AppDelegate.h',
        'example/ios/Runner/AppDelegate.m',
        'example/ios/Runner/main.m',
        'example/lib/main.dart',
        'flutter_project.iml',
        'ios/Classes/FlutterProjectPlugin.h',
        'ios/Classes/FlutterProjectPlugin.m',
        'lib/flutter_project.dart',
      ],
    );
    return _runFlutterTest(projectDir.childDirectory('example'));
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('kotlin/swift plugin project', () async {
    return _createProject(
      projectDir,
      <String>['--no-pub', '--template=plugin', '-a', 'kotlin', '--ios-language', 'swift'],
      <String>[
        'android/src/main/kotlin/com/example/flutter_project/FlutterProjectPlugin.kt',
        'example/android/app/src/main/kotlin/com/example/flutter_project_example/MainActivity.kt',
        'example/ios/Runner/AppDelegate.swift',
        'example/ios/Runner/Runner-Bridging-Header.h',
        'example/lib/main.dart',
        'ios/Classes/FlutterProjectPlugin.h',
        'ios/Classes/FlutterProjectPlugin.m',
        'ios/Classes/SwiftFlutterProjectPlugin.swift',
        'lib/flutter_project.dart',
      ],
      unexpectedPaths: <String>[
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
        'example/ios/Runner/AppDelegate.h',
        'example/ios/Runner/AppDelegate.m',
        'example/ios/Runner/main.m',
      ],
    );
  });

  testUsingContext('plugin project with custom org', () async {
    return _createProject(
      projectDir,
      <String>[
        '--no-pub',
        '--template=plugin',
        '--org', 'com.bar.foo',
        '-i', 'objc',
        '-a', 'java',
      ], <String>[
        'android/src/main/java/com/bar/foo/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/bar/foo/flutter_project_example/MainActivity.java',
      ],
      unexpectedPaths: <String>[
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
      ],
    );
  });

  testUsingContext('plugin project with valid custom project name', () async {
    return _createProject(
      projectDir,
      <String>[
        '--no-pub',
        '--template=plugin',
        '--project-name', 'xyz',
        '-i', 'objc',
        '-a', 'java',
      ], <String>[
        'android/src/main/java/com/example/xyz/XyzPlugin.java',
        'example/android/app/src/main/java/com/example/xyz_example/MainActivity.java',
      ],
      unexpectedPaths: <String>[
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
      ],
    );
  });

  testUsingContext('plugin project with invalid custom project name', () async {
    expect(
      () => _createProject(projectDir,
        <String>['--no-pub', '--template=plugin', '--project-name', 'xyz.xyz'],
        <String>[],
      ),
      throwsToolExit(message: '"xyz.xyz" is not a valid Dart package name.'),
    );
  });

  testUsingContext('legacy app project with-driver-test', () async {
    return _createAndAnalyzeProject(
      projectDir,
      <String>['--with-driver-test', '--template=app'],
      <String>['lib/main.dart'],
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('module project with pub', () async {
    return _createProject(projectDir, <String>[
      '--template=module',
    ], <String>[
      '.android/build.gradle',
      '.android/Flutter/build.gradle',
      '.android/Flutter/flutter.iml',
      '.android/Flutter/src/main/AndroidManifest.xml',
      '.android/Flutter/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
      '.android/gradle.properties',
      '.android/gradle/wrapper/gradle-wrapper.jar',
      '.android/gradle/wrapper/gradle-wrapper.properties',
      '.android/gradlew',
      '.android/gradlew.bat',
      '.android/include_flutter.groovy',
      '.android/local.properties',
      '.android/settings.gradle',
      '.gitignore',
      '.metadata',
      '.packages',
      'lib/main.dart',
      'pubspec.lock',
      'pubspec.yaml',
      'README.md',
      'test/widget_test.dart',
    ], unexpectedPaths: <String>[
      'android/',
      'ios/',
      '.android/Flutter/src/main/java/io/flutter/facade/FlutterFragment.java',
      '.android/Flutter/src/main/java/io/flutter/facade/Flutter.java',
    ]);
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });


  testUsingContext('androidx is used by default in an app project', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    void expectExists(String relPath) {
      expect(globals.fs.isFileSync('${projectDir.path}/$relPath'), true);
    }

    expectExists('android/gradle.properties');

    final String actualContents = await globals.fs.file(projectDir.path + '/android/gradle.properties').readAsString();

    expect(actualContents.contains('useAndroidX'), true);
  });

  testUsingContext('non androidx app project', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--no-androidx', projectDir.path]);

    void expectExists(String relPath) {
      expect(globals.fs.isFileSync('${projectDir.path}/$relPath'), true);
    }

    expectExists('android/gradle.properties');

    final String actualContents = await globals.fs.file(projectDir.path + '/android/gradle.properties').readAsString();

    expect(actualContents.contains('useAndroidX'), false);
  });

  testUsingContext('androidx is used by default in a module project', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--template=module', '--no-pub', projectDir.path]);

    final FlutterProject project = FlutterProject.fromDirectory(projectDir);
    expect(
      project.usesAndroidX,
      true,
    );
  });

  testUsingContext('non androidx module', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--template=module', '--no-pub', '--no-androidx', projectDir.path]);

    final FlutterProject project = FlutterProject.fromDirectory(projectDir);
    expect(
      project.usesAndroidX,
      false,
    );
  });

  testUsingContext('androidx is used by default in a plugin project', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--template=plugin', projectDir.path]);

    void expectExists(String relPath) {
      expect(globals.fs.isFileSync('${projectDir.path}/$relPath'), true);
    }

    expectExists('android/gradle.properties');

    final String actualContents = await globals.fs.file(projectDir.path + '/android/gradle.properties').readAsString();

    expect(actualContents.contains('useAndroidX'), true);
  });

  testUsingContext('non androidx plugin project', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--template=plugin', '--no-androidx', projectDir.path]);

    void expectExists(String relPath) {
      expect(globals.fs.isFileSync('${projectDir.path}/$relPath'), true);
    }

    expectExists('android/gradle.properties');

    final String actualContents = await globals.fs.file(projectDir.path + '/android/gradle.properties').readAsString();

    expect(actualContents.contains('useAndroidX'), false);
  });

  testUsingContext('app supports macOS if requested', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    expect(projectDir.childDirectory('macos').childDirectory('Runner.xcworkspace').existsSync(), true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('app does not include macOS by default', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    expect(projectDir.childDirectory('macos').childDirectory('Runner.xcworkspace').existsSync(), false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
  });

  testUsingContext('plugin supports macOS if requested', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--template=plugin', projectDir.path]);

    expect(projectDir.childDirectory('macos').childFile('flutter_project.podspec').existsSync(), true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('plugin does not include macOS by default', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--template=plugin', projectDir.path]);

    expect(projectDir.childDirectory('macos').childFile('flutter_project.podspec').existsSync(), false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
  });

  testUsingContext('has correct content and formatting with module template', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--template=module', '--no-pub', '--org', 'com.foo.bar', projectDir.path]);

    void expectExists(String relPath, [bool expectation = true]) {
      expect(globals.fs.isFileSync('${projectDir.path}/$relPath'), expectation);
    }

    expectExists('lib/main.dart');
    expectExists('test/widget_test.dart');

    final String actualContents = await globals.fs.file(projectDir.path + '/test/widget_test.dart').readAsString();

    expect(actualContents.contains('flutter_test.dart'), true);

    for (final FileSystemEntity file in projectDir.listSync(recursive: true)) {
      if (file is File && file.path.endsWith('.dart')) {
        final String original = file.readAsStringSync();

        final Process process = await Process.start(
          sdkBinaryName('dartfmt'),
          <String>[file.path],
          workingDirectory: projectDir.path,
        );
        final String formatted = await process.stdout.transform(utf8.decoder).join();

        expect(original, formatted, reason: file.path);
      }
    }

    await _runFlutterTest(projectDir, target: globals.fs.path.join(projectDir.path, 'test', 'widget_test.dart'));

    // Generated Xcode settings
    final String xcodeConfigPath = globals.fs.path.join('.ios', 'Flutter', 'Generated.xcconfig');
    expectExists(xcodeConfigPath);
    final File xcodeConfigFile = globals.fs.file(globals.fs.path.join(projectDir.path, xcodeConfigPath));
    final String xcodeConfig = xcodeConfigFile.readAsStringSync();
    expect(xcodeConfig, contains('FLUTTER_ROOT='));
    expect(xcodeConfig, contains('FLUTTER_APPLICATION_PATH='));
    expect(xcodeConfig, contains('FLUTTER_TARGET='));

    // Generated export environment variables script
    final String buildPhaseScriptPath = globals.fs.path.join('.ios', 'Flutter', 'flutter_export_environment.sh');
    expectExists(buildPhaseScriptPath);
    final File buildPhaseScriptFile = globals.fs.file(globals.fs.path.join(projectDir.path, buildPhaseScriptPath));
    final String buildPhaseScript = buildPhaseScriptFile.readAsStringSync();
    expect(buildPhaseScript, contains('FLUTTER_ROOT='));
    expect(buildPhaseScript, contains('FLUTTER_APPLICATION_PATH='));
    expect(buildPhaseScript, contains('FLUTTER_TARGET='));

    // Generated podspec
    final String podspecPath = globals.fs.path.join('.ios', 'Flutter', 'flutter_project.podspec');
    expectExists(podspecPath);
    final File podspecFile = globals.fs.file(globals.fs.path.join(projectDir.path, podspecPath));
    final String podspec = podspecFile.readAsStringSync();
    expect(podspec, contains('Flutter module - flutter_project'));

    // App identification
    final String xcodeProjectPath = globals.fs.path.join('.ios', 'Runner.xcodeproj', 'project.pbxproj');
    expectExists(xcodeProjectPath);
    final File xcodeProjectFile = globals.fs.file(globals.fs.path.join(projectDir.path, xcodeProjectPath));
    final String xcodeProject = xcodeProjectFile.readAsStringSync();
    expect(xcodeProject, contains('PRODUCT_BUNDLE_IDENTIFIER = com.foo.bar.flutterProject'));
    // Xcode build system
    final String xcodeWorkspaceSettingsPath = globals.fs.path.join('.ios', 'Runner.xcworkspace', 'xcshareddata', 'WorkspaceSettings.xcsettings');
    expectExists(xcodeWorkspaceSettingsPath, false);

    final String versionPath = globals.fs.path.join('.metadata');
    expectExists(versionPath);
    final String version = globals.fs.file(globals.fs.path.join(projectDir.path, versionPath)).readAsStringSync();
    expect(version, contains('version:'));
    expect(version, contains('revision: 12345678'));
    expect(version, contains('channel: omega'));

    // IntelliJ metadata
    final String intelliJSdkMetadataPath = globals.fs.path.join('.idea', 'libraries', 'Dart_SDK.xml');
    expectExists(intelliJSdkMetadataPath);
    final String sdkMetaContents = globals.fs
        .file(globals.fs.path.join(
          projectDir.path,
          intelliJSdkMetadataPath,
        ))
        .readAsStringSync();
    expect(sdkMetaContents, contains('<root url="file:/'));
    expect(sdkMetaContents, contains('/bin/cache/dart-sdk/lib/core"'));
  }, overrides: <Type, Generator>{
    FlutterVersion: () => mockFlutterVersion,
    Platform: _kNoColorTerminalPlatform,
  });

  testUsingContext('has correct content and formatting with app template', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--template=app', '--no-pub', '--org', 'com.foo.bar', projectDir.path]);

    void expectExists(String relPath) {
      expect(globals.fs.isFileSync('${projectDir.path}/$relPath'), true);
    }

    expectExists('lib/main.dart');
    expectExists('test/widget_test.dart');

    for (final FileSystemEntity file in projectDir.listSync(recursive: true)) {
      if (file is File && file.path.endsWith('.dart')) {
        final String original = file.readAsStringSync();

        final Process process = await Process.start(
          sdkBinaryName('dartfmt'),
          <String>[file.path],
          workingDirectory: projectDir.path,
        );
        final String formatted = await process.stdout.transform(utf8.decoder).join();

        expect(original, formatted, reason: file.path);
      }
    }

    await _runFlutterTest(projectDir, target: globals.fs.path.join(projectDir.path, 'test', 'widget_test.dart'));

    // Generated Xcode settings
    final String xcodeConfigPath = globals.fs.path.join('ios', 'Flutter', 'Generated.xcconfig');
    expectExists(xcodeConfigPath);
    final File xcodeConfigFile = globals.fs.file(globals.fs.path.join(projectDir.path, xcodeConfigPath));
    final String xcodeConfig = xcodeConfigFile.readAsStringSync();
    expect(xcodeConfig, contains('FLUTTER_ROOT='));
    expect(xcodeConfig, contains('FLUTTER_APPLICATION_PATH='));
    // App identification
    final String xcodeProjectPath = globals.fs.path.join('ios', 'Runner.xcodeproj', 'project.pbxproj');
    expectExists(xcodeProjectPath);
    final File xcodeProjectFile = globals.fs.file(globals.fs.path.join(projectDir.path, xcodeProjectPath));
    final String xcodeProject = xcodeProjectFile.readAsStringSync();
    expect(xcodeProject, contains('PRODUCT_BUNDLE_IDENTIFIER = com.foo.bar.flutterProject'));

    final String versionPath = globals.fs.path.join('.metadata');
    expectExists(versionPath);
    final String version = globals.fs.file(globals.fs.path.join(projectDir.path, versionPath)).readAsStringSync();
    expect(version, contains('version:'));
    expect(version, contains('revision: 12345678'));
    expect(version, contains('channel: omega'));

    // IntelliJ metadata
    final String intelliJSdkMetadataPath = globals.fs.path.join('.idea', 'libraries', 'Dart_SDK.xml');
    expectExists(intelliJSdkMetadataPath);
    final String sdkMetaContents = globals.fs
        .file(globals.fs.path.join(
          projectDir.path,
          intelliJSdkMetadataPath,
        ))
        .readAsStringSync();
    expect(sdkMetaContents, contains('<root url="file:/'));
    expect(sdkMetaContents, contains('/bin/cache/dart-sdk/lib/core"'));
  }, overrides: <Type, Generator>{
    FlutterVersion: () => mockFlutterVersion,
    Platform: _kNoColorTerminalPlatform,
  });

  testUsingContext('has correct application id for android and bundle id for ios', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    String tmpProjectDir = globals.fs.path.join(tempDir.path, 'hello_flutter');
    await runner.run(<String>['create', '--template=app', '--no-pub', '--org', 'com.example', tmpProjectDir]);
    FlutterProject project = FlutterProject.fromDirectory(globals.fs.directory(tmpProjectDir));
    expect(
        await project.ios.productBundleIdentifier,
        'com.example.helloFlutter',
    );
    expect(
        project.android.applicationId,
        'com.example.hello_flutter',
    );

    tmpProjectDir = globals.fs.path.join(tempDir.path, 'test_abc');
    await runner.run(<String>['create', '--template=app', '--no-pub', '--org', 'abc^*.1#@', tmpProjectDir]);
    project = FlutterProject.fromDirectory(globals.fs.directory(tmpProjectDir));
    expect(
        await project.ios.productBundleIdentifier,
        'abc.1.testAbc',
    );
    expect(
        project.android.applicationId,
        'abc.u1.test_abc',
    );

    tmpProjectDir = globals.fs.path.join(tempDir.path, 'flutter_project');
    await runner.run(<String>['create', '--template=app', '--no-pub', '--org', '#+^%', tmpProjectDir]);
    project = FlutterProject.fromDirectory(globals.fs.directory(tmpProjectDir));
    expect(
        await project.ios.productBundleIdentifier,
        'flutterProject.untitled',
    );
    expect(
        project.android.applicationId,
        'flutter_project.untitled',
    );
  }, overrides: <Type, Generator>{
    FlutterVersion: () => mockFlutterVersion,
    Platform: _kNoColorTerminalPlatform,
  });

  testUsingContext('can re-gen default template over existing project', () async {
    Cache.flutterRoot = '../..';

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    final String metadata = globals.fs.file(globals.fs.path.join(projectDir.path, '.metadata')).readAsStringSync();
    expect(metadata, contains('project_type: app\n'));
  });

  testUsingContext('can re-gen default template over existing app project with no metadta and detect the type', () async {
    Cache.flutterRoot = '../..';

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--template=app', projectDir.path]);

    // Remove the .metadata to simulate an older instantiation that didn't generate those.
    globals.fs.file(globals.fs.path.join(projectDir.path, '.metadata')).deleteSync();

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    final String metadata = globals.fs.file(globals.fs.path.join(projectDir.path, '.metadata')).readAsStringSync();
    expect(metadata, contains('project_type: app\n'));
  });

  testUsingContext('can re-gen app template over existing app project and detect the type', () async {
    Cache.flutterRoot = '../..';

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--template=app', projectDir.path]);

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    final String metadata = globals.fs.file(globals.fs.path.join(projectDir.path, '.metadata')).readAsStringSync();
    expect(metadata, contains('project_type: app\n'));
  });

  testUsingContext('can re-gen template over existing module project and detect the type', () async {
    Cache.flutterRoot = '../..';

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--template=module', projectDir.path]);

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    final String metadata = globals.fs.file(globals.fs.path.join(projectDir.path, '.metadata')).readAsStringSync();
    expect(metadata, contains('project_type: module\n'));
  });

  testUsingContext('can re-gen default template over existing plugin project and detect the type', () async {
    Cache.flutterRoot = '../..';

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--template=plugin', projectDir.path]);

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    final String metadata = globals.fs.file(globals.fs.path.join(projectDir.path, '.metadata')).readAsStringSync();
    expect(metadata, contains('project_type: plugin'));
  });

  testUsingContext('can re-gen default template over existing package project and detect the type', () async {
    Cache.flutterRoot = '../..';

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create', '--no-pub', '--template=package', projectDir.path]);

    await runner.run(<String>['create', '--no-pub', projectDir.path]);

    final String metadata = globals.fs.file(globals.fs.path.join(projectDir.path, '.metadata')).readAsStringSync();
    expect(metadata, contains('project_type: package'));
  });

  testUsingContext('can re-gen module .android/ folder, reusing custom org', () async {
    await _createProject(
      projectDir,
      <String>['--template=module', '--org', 'com.bar.foo'],
      <String>[],
    );
    projectDir.childDirectory('.android').deleteSync(recursive: true);
    return _createProject(
      projectDir,
      <String>[],
      <String>[
        '.android/app/src/main/java/com/bar/foo/flutter_project/host/MainActivity.java',
      ],
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('can re-gen module .ios/ folder, reusing custom org', () async {
    await _createProject(
      projectDir,
      <String>['--template=module', '--org', 'com.bar.foo'],
      <String>[],
    );
    projectDir.childDirectory('.ios').deleteSync(recursive: true);
    await _createProject(projectDir, <String>[], <String>[]);
    final FlutterProject project = FlutterProject.fromDirectory(projectDir);
    expect(
      await project.ios.productBundleIdentifier,
      'com.bar.foo.flutterProject',
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext('can re-gen app android/ folder, reusing custom org', () async {
    await _createProject(
      projectDir,
      <String>[
        '--no-pub',
        '--template=app',
        '--org', 'com.bar.foo',
        '-i', 'objc',
        '-a', 'java',
      ],
      <String>[],
    );
    projectDir.childDirectory('android').deleteSync(recursive: true);
    return _createProject(
      projectDir,
      <String>['--no-pub', '-i', 'objc', '-a', 'java'],
      <String>[
        'android/app/src/main/java/com/bar/foo/flutter_project/MainActivity.java',
      ],
      unexpectedPaths: <String>[
        'android/app/src/main/java/com/example/flutter_project/MainActivity.java',
      ],
    );
  });

  testUsingContext('can re-gen app ios/ folder, reusing custom org', () async {
    await _createProject(
      projectDir,
      <String>['--no-pub', '--template=app', '--org', 'com.bar.foo'],
      <String>[],
    );
    projectDir.childDirectory('ios').deleteSync(recursive: true);
    await _createProject(projectDir, <String>['--no-pub'], <String>[]);
    final FlutterProject project = FlutterProject.fromDirectory(projectDir);
    expect(
      await project.ios.productBundleIdentifier,
      'com.bar.foo.flutterProject',
    );
  });

  testUsingContext('can re-gen plugin ios/ and example/ folders, reusing custom org', () async {
    await _createProject(
      projectDir,
      <String>[
        '--no-pub',
        '--template=plugin',
        '--org', 'com.bar.foo',
        '-i', 'objc',
        '-a', 'java',
      ],
      <String>[],
    );
    projectDir.childDirectory('example').deleteSync(recursive: true);
    projectDir.childDirectory('ios').deleteSync(recursive: true);
    await _createProject(
      projectDir,
      <String>['--no-pub', '--template=plugin', '-i', 'objc', '-a', 'java'],
      <String>[
        'example/android/app/src/main/java/com/bar/foo/flutter_project_example/MainActivity.java',
        'ios/Classes/FlutterProjectPlugin.h',
      ],
      unexpectedPaths: <String>[
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
      ],
    );
    final FlutterProject project = FlutterProject.fromDirectory(projectDir);
    expect(
      await project.example.ios.productBundleIdentifier,
      'com.bar.foo.flutterProjectExample',
    );
  });

  testUsingContext('fails to re-gen without specified org when org is ambiguous', () async {
    await _createProject(
      projectDir,
      <String>['--no-pub', '--template=app', '--org', 'com.bar.foo'],
      <String>[],
    );
    globals.fs.directory(globals.fs.path.join(projectDir.path, 'ios')).deleteSync(recursive: true);
    await _createProject(
      projectDir,
      <String>['--no-pub', '--template=app', '--org', 'com.bar.baz'],
      <String>[],
    );
    expect(
      () => _createProject(projectDir, <String>[], <String>[]),
      throwsToolExit(message: 'Ambiguous organization'),
    );
  });

  // Verify that we help the user correct an option ordering issue
  testUsingContext('produces sensible error message', () async {
    Cache.flutterRoot = '../..';

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    expect(
      runner.run(<String>['create', projectDir.path, '--pub']),
      throwsToolExit(exitCode: 2, message: 'Try moving --pub'),
    );
  });

  testUsingContext('fails when file exists where output directory should be', () async {
    Cache.flutterRoot = '../..';
    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    final File existingFile = globals.fs.file(globals.fs.path.join(projectDir.path, 'bad'));
    if (!existingFile.existsSync()) {
      existingFile.createSync(recursive: true);
    }
    expect(
      runner.run(<String>['create', existingFile.path]),
      throwsToolExit(message: 'existing file'),
    );
  });

  testUsingContext('fails overwrite when file exists where output directory should be', () async {
    Cache.flutterRoot = '../..';
    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    final File existingFile = globals.fs.file(globals.fs.path.join(projectDir.path, 'bad'));
    if (!existingFile.existsSync()) {
      existingFile.createSync(recursive: true);
    }
    expect(
      runner.run(<String>['create', '--overwrite', existingFile.path]),
      throwsToolExit(message: 'existing file'),
    );
  });

  testUsingContext('overwrites existing directory when requested', () async {
    Cache.flutterRoot = '../..';
    final Directory existingDirectory = globals.fs.directory(globals.fs.path.join(projectDir.path, 'bad'));
    if (!existingDirectory.existsSync()) {
      existingDirectory.createSync(recursive: true);
    }
    final File existingFile = globals.fs.file(globals.fs.path.join(existingDirectory.path, 'lib', 'main.dart'));
    existingFile.createSync(recursive: true);
    await _createProject(
      globals.fs.directory(existingDirectory.path),
      <String>['--overwrite', '-i', 'objc', '-a', 'java'],
      <String>[
        'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        'lib/main.dart',
        'ios/Flutter/AppFrameworkInfo.plist',
        'ios/Runner/AppDelegate.m',
        'ios/Runner/GeneratedPluginRegistrant.h',
      ],
    );
  }, overrides: <Type, Generator>{
    Pub: () => const Pub(),
  });

  testUsingContext(
    'invokes pub offline when requested',
    () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--pub', '--offline', projectDir.path]);
      expect(loggingProcessManager.commands.first, contains(matches(r'dart-sdk[\\/]bin[\\/]pub')));
      expect(loggingProcessManager.commands.first, contains('--offline'));
    },
    overrides: <Type, Generator>{
      ProcessManager: () => loggingProcessManager,
      Pub: () => const Pub(),
    },
  );

  testUsingContext(
    'invokes pub online when offline not requested',
    () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--pub', projectDir.path]);
      expect(loggingProcessManager.commands.first, contains(matches(r'dart-sdk[\\/]bin[\\/]pub')));
      expect(loggingProcessManager.commands.first, isNot(contains('--offline')));
    },
    overrides: <Type, Generator>{
      ProcessManager: () => loggingProcessManager,
      Pub: () => const Pub(),
    },
  );

  testUsingContext('can create a sample-based project', () async {
    await _createAndAnalyzeProject(
      projectDir,
      <String>['--no-pub', '--sample=foo.bar.Baz'],
      <String>[
        'lib/main.dart',
        'flutter_project.iml',
        'android/app/src/main/AndroidManifest.xml',
        'ios/Flutter/AppFrameworkInfo.plist',
      ],
      unexpectedPaths: <String>['test'],
    );
    expect(projectDir.childDirectory('lib').childFile('main.dart').readAsStringSync(),
      contains('void main() {}'));
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => MockHttpClient(200, result: 'void main() {}'),
  });

  testUsingContext('can write samples index to disk', () async {
    final String outputFile = globals.fs.path.join(tempDir.path, 'flutter_samples.json');
    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    final List<String> args = <String>[
      'create',
      '--list-samples',
      outputFile,
    ];

    await runner.run(args);
    final File expectedFile = globals.fs.file(outputFile);
    expect(expectedFile.existsSync(), isTrue);
    expect(expectedFile.readAsStringSync(), equals(samplesIndexJson));
  }, overrides: <Type, Generator>{
    HttpClientFactory: () =>
        () => MockHttpClient(200, result: samplesIndexJson),
  });
  testUsingContext('provides an error to the user if samples json download fails', () async {
    final String outputFile = globals.fs.path.join(tempDir.path, 'flutter_samples.json');
    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    final List<String> args = <String>[
      'create',
      '--list-samples',
      outputFile,
    ];

    await expectLater(runner.run(args), throwsToolExit(exitCode: 2, message: 'Failed to write samples'));
    expect(globals.fs.file(outputFile).existsSync(), isFalse);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () =>
        () => MockHttpClient(404, result: 'not found'),
  });
}

Future<void> _createProject(
  Directory dir,
  List<String> createArgs,
  List<String> expectedPaths, {
  List<String> unexpectedPaths = const <String>[],
}) async {
  Cache.flutterRoot = '../../..';
  final CreateCommand command = CreateCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'create',
    ...createArgs,
    dir.path,
  ]);

  bool pathExists(String path) {
    final String fullPath = globals.fs.path.join(dir.path, path);
    return globals.fs.typeSync(fullPath) != FileSystemEntityType.notFound;
  }

  final List<String> failures = <String>[
    for (final String path in expectedPaths)
      if (!pathExists(path))
        'Path "$path" does not exist.',
    for (final String path in unexpectedPaths)
      if (pathExists(path))
        'Path "$path" exists when it shouldn\'t.',
  ];
  expect(failures, isEmpty, reason: failures.join('\n'));
}

Future<void> _createAndAnalyzeProject(
  Directory dir,
  List<String> createArgs,
  List<String> expectedPaths, {
  List<String> unexpectedPaths = const <String>[],
}) async {
  await _createProject(dir, createArgs, expectedPaths, unexpectedPaths: unexpectedPaths);
  await _analyzeProject(dir.path);
}

Future<void> _ensureFlutterToolsSnapshot() async {
  final String flutterToolsPath = globals.fs.path.absolute(globals.fs.path.join(
    'bin',
    'flutter_tools.dart',
  ));
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(globals.fs.path.join(
    '..',
    '..',
    'bin',
    'cache',
    'flutter_tools.snapshot',
  ));
  final String dotPackages = globals.fs.path.absolute(globals.fs.path.join(
    '.packages',
  ));

  final File snapshotFile = globals.fs.file(flutterToolsSnapshotPath);
  if (snapshotFile.existsSync()) {
    snapshotFile.renameSync(flutterToolsSnapshotPath + '.bak');
  }

  final List<String> snapshotArgs = <String>[
    ...dartVmFlags,
    '--snapshot=$flutterToolsSnapshotPath',
    '--packages=$dotPackages',
    flutterToolsPath,
  ];
  final ProcessResult snapshotResult = await Process.run(
    '../../bin/cache/dart-sdk/bin/dart',
    snapshotArgs,
  );
  if (snapshotResult.exitCode != 0) {
    print(snapshotResult.stdout);
    print(snapshotResult.stderr);
  }
  expect(snapshotResult.exitCode, 0);
}

Future<void> _restoreFlutterToolsSnapshot() async {
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(globals.fs.path.join(
    '..',
    '..',
    'bin',
    'cache',
    'flutter_tools.snapshot',
  ));

  final File snapshotBackup = globals.fs.file(flutterToolsSnapshotPath + '.bak');
  if (!snapshotBackup.existsSync()) {
    // No backup to restore.
    return;
  }

  snapshotBackup.renameSync(flutterToolsSnapshotPath);
}

Future<void> _analyzeProject(String workingDir) async {
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(globals.fs.path.join(
    '..',
    '..',
    'bin',
    'cache',
    'flutter_tools.snapshot',
  ));

  final List<String> args = <String>[
    ...dartVmFlags,
    flutterToolsSnapshotPath,
    'analyze',
  ];

  final ProcessResult exec = await Process.run(
    '$dartSdkPath/bin/dart',
    args,
    workingDirectory: workingDir,
  );
  if (exec.exitCode != 0) {
    print(exec.stdout);
    print(exec.stderr);
  }
  expect(exec.exitCode, 0);
}

Future<void> _runFlutterTest(Directory workingDir, { String target }) async {
  final String flutterToolsSnapshotPath = globals.fs.path.absolute(globals.fs.path.join(
    '..',
    '..',
    'bin',
    'cache',
    'flutter_tools.snapshot',
  ));

  // While flutter test does get packages, it doesn't write version
  // files anymore.
  await Process.run(
    '$dartSdkPath/bin/dart',
    <String>[
      ...dartVmFlags,
      flutterToolsSnapshotPath,
      'packages',
      'get',
    ],
    workingDirectory: workingDir.path,
  );

  final List<String> args = <String>[
    ...dartVmFlags,
    flutterToolsSnapshotPath,
    'test',
    '--no-color',
    if (target != null) target,
  ];

  final ProcessResult exec = await Process.run(
    '$dartSdkPath/bin/dart',
    args,
    workingDirectory: workingDir.path,
  );
  if (exec.exitCode != 0) {
    print(exec.stdout);
    print(exec.stderr);
  }
  expect(exec.exitCode, 0);
}

class MockFlutterVersion extends Mock implements FlutterVersion {}

/// A ProcessManager that invokes a real process manager, but keeps
/// track of all commands sent to it.
class LoggingProcessManager extends LocalProcessManager {
  List<List<String>> commands = <List<String>>[];

  @override
  Future<Process> start(
    List<String> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    commands.add(command);
    return super.start(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
  }
}

class MockHttpClient implements HttpClient {
  MockHttpClient(this.statusCode, {this.result});

  final int statusCode;
  final String result;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(statusCode, result: result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClient - $invocation';
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  MockHttpClientRequest(this.statusCode, {this.result});

  final int statusCode;
  final String result;

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(statusCode, result: result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientRequest - $invocation';
  }
}

class MockHttpClientResponse implements HttpClientResponse {
  MockHttpClientResponse(this.statusCode, {this.result});

  @override
  final int statusCode;

  final String result;

  @override
  String get reasonPhrase => '<reason phrase>';

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.decompressed;
  }

  @override
  StreamSubscription<Uint8List> listen(
    void onData(Uint8List event), {
    Function onError,
    void onDone(),
    bool cancelOnError,
  }) {
    return Stream<Uint8List>.fromIterable(<Uint8List>[Uint8List.fromList(result.codeUnits)])
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Future<dynamic> forEach(void Function(Uint8List element) action) {
    action(Uint8List.fromList(result.codeUnits));
    return Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientResponse - $invocation';
  }
}
