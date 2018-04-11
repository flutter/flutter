// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

const String frameworkRevision = '12345678';
const String frameworkChannel = 'omega';

void main() {
  group('create', () {
    Directory temp;
    Directory projectDir;
    FlutterVersion mockFlutterVersion;
    LoggingProcessManager loggingProcessManager;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      loggingProcessManager = new LoggingProcessManager();
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
      projectDir = temp.childDirectory('flutter_project');
      mockFlutterVersion = new MockFlutterVersion();
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    // Verify that we create a project that is well-formed.
    testUsingContext('project', () async {
      await _createAndAnalyzeProject(
        projectDir,
        <String>[],
        <String>[
          'android/app/src/main/java/com/example/flutterproject/MainActivity.java',
          'ios/Runner/AppDelegate.h',
          'ios/Runner/AppDelegate.m',
          'ios/Runner/main.m',
          'lib/main.dart',
          'test/widget_test.dart',
          'flutter_project.iml',
        ],
      );
      return _runFlutterTest(projectDir);
    }, timeout: allowForRemotePubInvocation);

    testUsingContext('kotlin/swift project', () async {
      return _createProject(
        projectDir,
        <String>['--no-pub', '--android-language', 'kotlin', '-i', 'swift'],
        <String>[
          'android/app/src/main/kotlin/com/example/flutterproject/MainActivity.kt',
          'ios/Runner/AppDelegate.swift',
          'ios/Runner/Runner-Bridging-Header.h',
          'lib/main.dart',
        ],
        unexpectedPaths: <String>[
          'android/app/src/main/java/com/example/flutterproject/MainActivity.java',
          'ios/Runner/AppDelegate.h',
          'ios/Runner/AppDelegate.m',
          'ios/Runner/main.m',
        ],
      );
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('package project', () async {
      await _createAndAnalyzeProject(
        projectDir,
        <String>['--template=package'],
        <String>[
          'lib/flutter_project.dart',
          'test/flutter_project_test.dart',
        ],
        unexpectedPaths: <String>[
          'android/app/src/main/java/com/example/flutterproject/MainActivity.java',
          'android/src/main/java/com/example/flutterproject/FlutterProjectPlugin.java',
          'ios/Classes/FlutterProjectPlugin.h',
          'ios/Classes/FlutterProjectPlugin.m',
          'ios/Runner/AppDelegate.h',
          'ios/Runner/AppDelegate.m',
          'ios/Runner/main.m',
          'lib/main.dart',
          'example/android/app/src/main/java/com/example/flutterprojectexample/MainActivity.java',
          'example/ios/Runner/AppDelegate.h',
          'example/ios/Runner/AppDelegate.m',
          'example/ios/Runner/main.m',
          'example/lib/main.dart',
          'test/widget_test.dart',
        ],
      );
      return _runFlutterTest(projectDir);
    }, timeout: allowForRemotePubInvocation);

    testUsingContext('plugin project', () async {
      await _createAndAnalyzeProject(
        projectDir,
        <String>['--template=plugin'],
        <String>[
          'android/src/main/java/com/example/flutterproject/FlutterProjectPlugin.java',
          'ios/Classes/FlutterProjectPlugin.h',
          'ios/Classes/FlutterProjectPlugin.m',
          'lib/flutter_project.dart',
          'example/android/app/src/main/java/com/example/flutterprojectexample/MainActivity.java',
          'example/ios/Runner/AppDelegate.h',
          'example/ios/Runner/AppDelegate.m',
          'example/ios/Runner/main.m',
          'example/lib/main.dart',
          'flutter_project.iml',
        ],
        plugin: true,
      );
      return _runFlutterTest(projectDir.childDirectory('example'));
    }, timeout: allowForRemotePubInvocation);

    testUsingContext('kotlin/swift plugin project', () async {
      return _createProject(
        projectDir,
        <String>['--no-pub', '--template=plugin', '-a', 'kotlin', '--ios-language', 'swift'],
        <String>[
          'android/src/main/kotlin/com/example/flutterproject/FlutterProjectPlugin.kt',
          'ios/Classes/FlutterProjectPlugin.h',
          'ios/Classes/FlutterProjectPlugin.m',
          'ios/Classes/SwiftFlutterProjectPlugin.swift',
          'lib/flutter_project.dart',
          'example/android/app/src/main/kotlin/com/example/flutterprojectexample/MainActivity.kt',
          'example/ios/Runner/AppDelegate.swift',
          'example/ios/Runner/Runner-Bridging-Header.h',
          'example/lib/main.dart',
        ],
        unexpectedPaths: <String>[
          'android/src/main/java/com/example/flutterproject/FlutterProjectPlugin.java',
          'example/android/app/src/main/java/com/example/flutterprojectexample/MainActivity.java',
          'example/ios/Runner/AppDelegate.h',
          'example/ios/Runner/AppDelegate.m',
          'example/ios/Runner/main.m',
        ],
        plugin: true,
      );
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('plugin project with custom org', () async {
      return _createProject(
        projectDir,
        <String>['--no-pub', '--template=plugin', '--org', 'com.bar.foo'],
        <String>[
          'android/src/main/java/com/bar/foo/flutterproject/FlutterProjectPlugin.java',
          'example/android/app/src/main/java/com/bar/foo/flutterprojectexample/MainActivity.java',
        ],
        unexpectedPaths: <String>[
          'android/src/main/java/com/example/flutterproject/FlutterProjectPlugin.java',
          'example/android/app/src/main/java/com/example/flutterprojectexample/MainActivity.java',
        ],
        plugin: true,
      );
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('project with-driver-test', () async {
      return _createAndAnalyzeProject(
        projectDir,
        <String>['--with-driver-test'],
        <String>['lib/main.dart'],
      );
    }, timeout: allowForRemotePubInvocation);

    // Verify content and formatting
    testUsingContext('content', () async {
      Cache.flutterRoot = '../..';
      when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
      when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', '--org', 'com.foo.bar', projectDir.path]);

      void expectExists(String relPath) {
        expect(fs.isFileSync('${projectDir.path}/$relPath'), true);
      }

      expectExists('lib/main.dart');

      for (FileSystemEntity file in projectDir.listSync(recursive: true)) {
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

      await _runFlutterTest(projectDir, target: fs.path.join(projectDir.path, 'test', 'widget_test.dart'));

      // Generated Xcode settings
      final String xcodeConfigPath = fs.path.join('ios', 'Flutter', 'Generated.xcconfig');
      expectExists(xcodeConfigPath);
      final File xcodeConfigFile = fs.file(fs.path.join(projectDir.path, xcodeConfigPath));
      final String xcodeConfig = xcodeConfigFile.readAsStringSync();
      expect(xcodeConfig, contains('FLUTTER_ROOT='));
      expect(xcodeConfig, contains('FLUTTER_APPLICATION_PATH='));
      expect(xcodeConfig, contains('FLUTTER_FRAMEWORK_DIR='));
      // App identification
      final String xcodeProjectPath = fs.path.join('ios', 'Runner.xcodeproj', 'project.pbxproj');
      expectExists(xcodeProjectPath);
      final File xcodeProjectFile = fs.file(fs.path.join(projectDir.path, xcodeProjectPath));
      final String xcodeProject = xcodeProjectFile.readAsStringSync();
      expect(xcodeProject, contains('PRODUCT_BUNDLE_IDENTIFIER = com.foo.bar.flutterProject'));

      final String versionPath = fs.path.join('.metadata');
      expectExists(versionPath);
      final String version = fs.file(fs.path.join(projectDir.path, versionPath)).readAsStringSync();
      expect(version, contains('version:'));
      expect(version, contains('revision: 12345678'));
      expect(version, contains('channel: omega'));

      // IntelliJ metadata
      final String intelliJSdkMetadataPath = fs.path.join('.idea', 'libraries', 'Dart_SDK.xml');
      expectExists(intelliJSdkMetadataPath);
      final String sdkMetaContents = fs.file(fs.path.join(projectDir.path, intelliJSdkMetadataPath)).readAsStringSync();
      expect(sdkMetaContents, contains('<root url="file:/'));
      expect(sdkMetaContents, contains('/bin/cache/dart-sdk/lib/core"'));
    }, overrides: <Type, Generator>{
      FlutterVersion: () => mockFlutterVersion,
    }, timeout: allowForCreateFlutterProject);

    // Verify that we can regenerate over an existing project.
    testUsingContext('can re-gen over existing project', () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', projectDir.path]);

      await runner.run(<String>['create', '--no-pub', projectDir.path]);
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('can re-gen android/ folder, reusing custom org', () async {
      await _createProject(
        projectDir,
        <String>['--no-pub', '--org', 'com.bar.foo'],
        <String>[],
      );
      projectDir.childDirectory('android').deleteSync(recursive: true);
      return _createProject(
        projectDir,
        <String>['--no-pub'],
        <String>[
          'android/app/src/main/java/com/bar/foo/flutterproject/MainActivity.java',
        ],
        unexpectedPaths: <String>[
          'android/app/src/main/java/com/example/flutterproject/MainActivity.java',
        ],
      );
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('can re-gen ios/ folder, reusing custom org', () async {
      await _createProject(
        projectDir,
        <String>['--no-pub', '--org', 'com.bar.foo'],
        <String>[],
      );
      projectDir.childDirectory('ios').deleteSync(recursive: true);
      await _createProject(projectDir, <String>['--no-pub'], <String>[]);
      expect(
        await new FlutterProject(projectDir).ios.productBundleIdentifier(),
        'com.bar.foo.flutterProject',
      );
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('can re-gen plugin ios/ and example/ folders, reusing custom org', () async {
      await _createProject(
        projectDir,
        <String>['--no-pub', '-t', 'plugin', '--org', 'com.bar.foo'],
        <String>[],
      );
      projectDir.childDirectory('example').deleteSync(recursive: true);
      projectDir.childDirectory('ios').deleteSync(recursive: true);
      await _createProject(
        projectDir,
        <String>['--no-pub', '-t', 'plugin'],
        <String>[
          'example/android/app/src/main/java/com/bar/foo/flutterprojectexample/MainActivity.java',
          'ios/Classes/FlutterProjectPlugin.h',
        ],
        unexpectedPaths: <String>[
          'example/android/app/src/main/java/com/example/flutterprojectexample/MainActivity.java',
          'android/src/main/java/com/example/flutterproject/FlutterProjectPlugin.java',
        ],
      );
      expect(
        await new FlutterProject(projectDir).example.ios.productBundleIdentifier(),
        'com.bar.foo.flutterProjectExample',
      );
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('fails to re-gen without specified org when org is ambiguous', () async {
      await _createProject(
        projectDir,
        <String>['--no-pub', '--org', 'com.bar.foo'],
        <String>[],
      );
      fs.directory(fs.path.join(projectDir.path, 'ios')).deleteSync(recursive: true);
      await _createProject(
        projectDir,
        <String>['--no-pub', '--org', 'com.bar.baz'],
        <String>[],
      );
      expect(
        () => _createProject(projectDir, <String>[], <String>[]),
        throwsToolExit(message: 'Ambiguous organization'),
      );
    }, timeout: allowForCreateFlutterProject);

    // Verify that we help the user correct an option ordering issue
    testUsingContext('produces sensible error message', () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      expect(
        runner.run(<String>['create', projectDir.path, '--pub']),
        throwsToolExit(exitCode: 2, message: 'Try moving --pub'),
      );
    });

    // Verify that we fail with an error code when the file exists.
    testUsingContext('fails when file exists', () async {
      Cache.flutterRoot = '../..';
      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      final File existingFile = fs.file('${projectDir.path.toString()}/bad');
      if (!existingFile.existsSync())
        existingFile.createSync(recursive: true);
      expect(
        runner.run(<String>['create', existingFile.path]),
        throwsToolExit(message: 'file exists'),
      );
    });

    testUsingContext('fails when invalid package name', () async {
      Cache.flutterRoot = '../..';
      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      expect(
        runner.run(<String>['create', fs.path.join(projectDir.path, 'invalidName')]),
        throwsToolExit(message: '"invalidName" is not a valid Dart package name.'),
      );
    });

    testUsingContext('invokes pub offline when requested', () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--pub', '--offline', projectDir.path]);
      expect(loggingProcessManager.commands.first, contains(matches(r'dart-sdk[\\/]bin[\\/]pub')));
      expect(loggingProcessManager.commands.first, contains('--offline'));
    },
      timeout: allowForCreateFlutterProject,
      overrides: <Type, Generator>{
        ProcessManager: () => loggingProcessManager,
      },
    );

    testUsingContext('invokes pub online when offline not requested', () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--pub', projectDir.path]);
      expect(loggingProcessManager.commands.first, contains(matches(r'dart-sdk[\\/]bin[\\/]pub')));
      expect(loggingProcessManager.commands.first, isNot(contains('--offline')));
    },
      timeout: allowForCreateFlutterProject,
      overrides: <Type, Generator>{
        ProcessManager: () => loggingProcessManager,
      },
    );
  });
}

Future<Null> _createProject(
    Directory dir, List<String> createArgs, List<String> expectedPaths,
    { List<String> unexpectedPaths = const <String>[], bool plugin = false}) async {
  Cache.flutterRoot = '../..';
  final CreateCommand command = new CreateCommand();
  final CommandRunner<Null> runner = createTestCommandRunner(command);
  final List<String> args = <String>['create'];
  args.addAll(createArgs);
  args.add(dir.path);
  await runner.run(args);

  for (String path in expectedPaths) {
    expect(fs.file(fs.path.join(dir.path, path)).existsSync(), true, reason: '$path does not exist');
  }
  for (String path in unexpectedPaths) {
    expect(fs.file(fs.path.join(dir.path, path)).existsSync(), false, reason: '$path exists');
  }
}

Future<Null> _createAndAnalyzeProject(
    Directory dir, List<String> createArgs, List<String> expectedPaths,
    { List<String> unexpectedPaths = const <String>[], bool plugin = false }) async {
  await _createProject(dir, createArgs, expectedPaths, unexpectedPaths: unexpectedPaths, plugin: plugin);
  if (plugin) {
    await _analyzeProject(dir.path, target: fs.path.join(dir.path, 'lib', 'flutter_project.dart'));
    await _analyzeProject(fs.path.join(dir.path, 'example'));
  } else {
    await _analyzeProject(dir.path);
  }
}

Future<Null> _analyzeProject(String workingDir, {String target}) async {
  final String flutterToolsPath = fs.path.absolute(fs.path.join(
    'bin',
    'flutter_tools.dart',
  ));

  final List<String> args = <String>[]
    ..addAll(dartVmFlags)
    ..add(flutterToolsPath)
    ..add('analyze');
  if (target != null)
    args.add(target);

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

Future<Null> _runFlutterTest(Directory workingDir, {String target}) async {
  final String flutterToolsPath = fs.path.absolute(fs.path.join(
    'bin',
    'flutter_tools.dart',
  ));

  final List<String> args = <String>[]
    ..addAll(dartVmFlags)
    ..add(flutterToolsPath)
    ..add('test')
    ..add('--no-color');
  if (target != null)
    args.add(target);

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
    List<dynamic> command, {
      String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      ProcessStartMode mode: ProcessStartMode.NORMAL,
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
