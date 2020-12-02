// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create_plugin.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/pubspec_schema.dart';
import '../../src/testbed.dart';

const String _kNoPlatformsMessage = 'Must specify at least one platform using --platforms.';
const String frameworkRevision = '12345678';
const String frameworkChannel = 'omega';
// TODO(fujino): replace FakePlatform.fromPlatform() with FakePlatform()
final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};
const String samplesIndexJson = '''
[
  { "id": "sample1" },
  { "id": "sample2" }
]''';

void main() {
  Directory tempDir;
  Directory projectDir;
  FlutterVersion mockFlutterVersion;
  LoggingProcessManager loggingProcessManager;
  BufferLogger logger;

  setUpAll(() async {
    Cache.disableLocking();
    await _ensureFlutterToolsSnapshot();
  });

  setUp(() {
    loggingProcessManager = LoggingProcessManager();
    logger = BufferLogger.test();
    tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_create_plugin_test.');
    projectDir = tempDir.childDirectory('flutter_project');
    mockFlutterVersion = MockFlutterVersion();
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  tearDownAll(() async {
    await _restoreFlutterToolsSnapshot();
  });

  testUsingContext('detects and recreates a plugin project correctly', () async {
    await projectDir.create(recursive: true);
    await projectDir.absolute.childFile('.metadata').writeAsString('project_type: plugin\n');
    await _createPluginAndAnalyzeProject(
      projectDir,
      <String>['--platforms=android,ios'],
      <String>[
        'example/lib/main.dart',
        'flutter_project.iml',
        'lib/flutter_project.dart',
      ],
      unexpectedPaths: <String>[
        'android/app/src/main/java/com/example/flutter_project/MainActivity.java',
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',]
    );
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      usage: globals.flutterUsage,
      botDetector: globals.botDetector,
      platform: globals.platform,
    ),
  });

  testUsingContext('can create a plugin project', () async {
    await _createPluginAndAnalyzeProject(
      projectDir,
      <String>['-i', 'objc', '-a', 'java', '--platforms=android'],
      <String>[
        'example/lib/main.dart',
        'flutter_project.iml',
        'lib/flutter_project.dart',
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
      ],
    );
    return _runFlutterTest(projectDir.childDirectory('example'));
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      usage: globals.flutterUsage,
      botDetector: globals.botDetector,
      platform: globals.platform,
    ),
  });

  testUsingContext('plugin project supports web', () async {
    await _createPluginAndAnalyzeProject(
      projectDir,
      <String>['--platforms=web'],
      <String>[
        'lib/flutter_project.dart',
        'lib/flutter_project_web.dart',
      ],
    );
    final String rawPubspec = await projectDir.childFile('pubspec.yaml').readAsString();
    final Pubspec pubspec = Pubspec.parse(rawPubspec);
    // Expect the dependency on flutter_web_plugins exists
    expect(pubspec.dependencies, contains('flutter_web_plugins'));
    // The platform is correctly registered
    expect(pubspec.flutter['plugin']['platforms']['web']['pluginClass'], 'FlutterProjectWeb');
    expect(pubspec.flutter['plugin']['platforms']['web']['fileName'], 'flutter_project_web.dart');
    expect(logger.errorText, isNot(contains(_kNoPlatformsMessage)));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    Pub: () => Pub(
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      usage: globals.flutterUsage,
      botDetector: globals.botDetector,
      platform: globals.platform,
    ),
    Logger: ()=>logger,
  });

  testUsingContext('plugin example app depends on plugin', () async {
    await _createProject(
      projectDir,
      <String>['-i', 'objc', '-a', 'java', '--platforms=android,ios'],
      <String>[
        'example/pubspec.yaml',
      ],
    );
    final String rawPubspec = await projectDir.childDirectory('example').childFile('pubspec.yaml').readAsString();
    final Pubspec pubspec = Pubspec.parse(rawPubspec);
    final String pluginName = projectDir.basename;
    expect(pubspec.dependencies, contains(pluginName));
    expect(pubspec.dependencies[pluginName] is PathDependency, isTrue);
    final PathDependency pathDependency = pubspec.dependencies[pluginName] as PathDependency;
    expect(pathDependency.path, '../');
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      usage: globals.flutterUsage,
      botDetector: globals.botDetector,
      platform: globals.platform,
    ),
  });

  testUsingContext('kotlin/swift plugin project', () async {
    return _createProject(
      projectDir,
      <String>['--no-pub', '-a', 'kotlin', '--ios-language', 'swift', '--platforms', 'ios,android'],
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
        '--org', 'com.bar.foo',
        '-i', 'objc',
        '-a', 'java',
        '--platforms', 'android',
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
        '--project-name', 'xyz',
        '-i', 'objc',
        '-a', 'java',
        '--platforms', 'android,ios',
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
        <String>['--no-pub', '--project-name', 'xyz.xyz', '--platforms', 'android,ios',],
        <String>[],
      ),
      throwsToolExit(message: '"xyz.xyz" is not a valid Dart package name.'),
    );
  });

  testUsingContext('androidx is used by default in a plugin project', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms', 'android', projectDir.path]);

    void expectExists(String relPath) {
      expect(globals.fs.isFileSync('${projectDir.path}/$relPath'), true);
    }

    expectExists('android/gradle.properties');

    final String actualContents = await globals.fs.file(projectDir.path + '/android/gradle.properties').readAsString();

    expect(actualContents.contains('useAndroidX'), true);
  });

  testUsingContext('plugin supports Linux if requested', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=linux', projectDir.path]);

    expect(
        projectDir.childDirectory('linux').childFile('CMakeLists.txt'), exists);
    expect(
        projectDir.childDirectory('example').childDirectory('linux'), exists);
    expect(projectDir.childDirectory('example').childDirectory('android'),
        isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('ios'),
        isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('windows'),
        isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('macos'),
        isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('web'),
        isNot(exists));
    validatePubspecForPlugin(
        projectDir: projectDir.absolute.path,
        expectedPlatforms: const <String>[
          'linux',
        ],
        pluginClass: 'FlutterProjectPlugin',
    unexpectedPlatforms: <String>['some_platform']);
    expect(logger.errorText, isNot(contains(_kNoPlatformsMessage)));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
    Logger: () => logger,
  });

  testUsingContext('plugin supports macOS if requested', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=macos', projectDir.path]);

    expect(projectDir.childDirectory('macos').childFile('flutter_project.podspec'),
        exists);
    expect(
        projectDir.childDirectory('example').childDirectory('macos'), exists);
    expect(projectDir.childDirectory('example').childDirectory('linux'),
        isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('android'),
        isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('ios'),
        isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('windows'),
        isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('web'),
        isNot(exists));
    validatePubspecForPlugin(projectDir: projectDir.absolute.path, expectedPlatforms: const <String>[
      'macos',
    ], pluginClass: 'FlutterProjectPlugin',
    unexpectedPlatforms: <String>['some_platform']);
    expect(logger.errorText, isNot(contains(_kNoPlatformsMessage)));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    Logger: () => logger,
  });

  testUsingContext('plugin supports Windows if requested', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=windows', projectDir.path]);

    expect(projectDir.childDirectory('windows').childFile('CMakeLists.txt'),
        exists);
    expect(
        projectDir.childDirectory('example').childDirectory('windows'), exists);
    expect(
        projectDir
            .childDirectory('example')
            .childDirectory('android'),
        isNot(exists));
    expect(
        projectDir.childDirectory('example').childDirectory('ios'),
        isNot(exists));
    expect(
        projectDir
            .childDirectory('example')
            .childDirectory('linux'),
        isNot(exists));
    expect(
        projectDir
            .childDirectory('example')
            .childDirectory('macos'),
        isNot(exists));
    expect(
        projectDir.childDirectory('example').childDirectory('web'),
        isNot(exists));
    validatePubspecForPlugin(projectDir: projectDir.absolute.path, expectedPlatforms: const <String>[
      'windows'
    ], pluginClass: 'FlutterProjectPlugin',
    unexpectedPlatforms: <String>['some_platform']);
    expect(logger.errorText, isNot(contains(_kNoPlatformsMessage)));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
    Logger: () => logger,
  });

  testUsingContext('plugin uses new platform schema', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);

    final String pubspecContents = await globals.fs.directory(projectDir.path).childFile('pubspec.yaml').readAsString();

    expect(pubspecContents.contains('platforms:'), true);
  });

  testUsingContext('can re-gen default template over existing plugin project and detect the type', () async {
    Cache.flutterRoot = '../..';

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);

    final String metadata = globals.fs.file(globals.fs.path.join(projectDir.path, '.metadata')).readAsStringSync();
    expect(LineSplitter.split(metadata), contains('project_type: plugin'));
  });

  testUsingContext('can re-gen plugin ios/ and example/ folders, reusing custom org', () async {
    await _createProject(
      projectDir,
      <String>[
        '--no-pub',
        '--org', 'com.bar.foo',
        '-i', 'objc',
        '-a', 'java',
        '--platforms', 'ios,android'
      ],
      <String>[],
    );
    projectDir.childDirectory('example').deleteSync(recursive: true);
    projectDir.childDirectory('ios').deleteSync(recursive: true);
    await _createProject(
      projectDir,
      <String>['--no-pub', '-i', 'objc', '-a', 'java', '--platforms', 'ios,android'],
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
      await project.example.ios.productBundleIdentifier(BuildInfo.debug),
      'com.bar.foo.flutterProjectExample',
    );
  });

  testUsingContext('fails when file exists where output directory should be', () async {
    Cache.flutterRoot = '../..';
    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    final File existingFile = globals.fs.file(globals.fs.path.join(projectDir.path, 'bad'));
    if (!existingFile.existsSync()) {
      existingFile.createSync(recursive: true);
    }
    expect(
      runner.run(<String>['create-plugin', '--platforms=android', existingFile.path]),
      throwsToolExit(message: 'existing file'),
    );
  });

  testUsingContext('fails overwrite when file exists where output directory should be', () async {
    Cache.flutterRoot = '../..';
    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    final File existingFile = globals.fs.file(globals.fs.path.join(projectDir.path, 'bad'));
    if (!existingFile.existsSync()) {
      existingFile.createSync(recursive: true);
    }
    expect(
      runner.run(<String>['create-plugin', '--platforms=android', '--overwrite', existingFile.path]),
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
      <String>['--platforms=ios,android', '--overwrite', '-i', 'objc', '-a', 'java'],
      <String>[
        'example/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        'example/lib/main.dart',
        'example/ios/Flutter/AppFrameworkInfo.plist',
        'example/ios/Runner/AppDelegate.m',
        'example/ios/Runner/GeneratedPluginRegistrant.h',
      ],
    );
  }, overrides: <Type, Generator>{
    Pub: () => Pub(
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      usage: globals.flutterUsage,
      botDetector: globals.botDetector,
      platform: globals.platform,
    ),
  });

  testUsingContext(
    'invokes pub offline when requested',
    () async {
      Cache.flutterRoot = '../..';

      final CreatePluginCommand command = CreatePluginCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create-plugin', '--platforms=android', '--pub', '--offline', projectDir.path]);
      expect(loggingProcessManager.commands.first, contains(matches(r'dart-sdk[\\/]bin[\\/]pub')));
      expect(loggingProcessManager.commands.first, contains('--offline'));
    },
    overrides: <Type, Generator>{
      ProcessManager: () => loggingProcessManager,
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    },
  );

  testUsingContext(
    'invokes pub online when offline not requested',
    () async {
      Cache.flutterRoot = '../..';

      final CreatePluginCommand command = CreatePluginCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create-plugin', '--platforms=android', '--pub', projectDir.path]);
      expect(loggingProcessManager.commands.first, contains(matches(r'dart-sdk[\\/]bin[\\/]pub')));
      expect(loggingProcessManager.commands.first, isNot(contains('--offline')));
    },
    overrides: <Type, Generator>{
      ProcessManager: () => loggingProcessManager,
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    },
  );

  testUsingContext('throws no platforms error message if --platforms not specified', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    expect(
      () => runner.run(<String>['create-plugin', '--no-pub', projectDir.path]),
      throwsToolExit(message: _kNoPlatformsMessage),
    );
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
    Logger: ()=> logger,
  });

  testUsingContext('plugin supports ios if requested', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=ios', projectDir.path]);

    expect(projectDir.childDirectory('ios'), exists);
    expect(projectDir.childDirectory('example').childDirectory('ios'), exists);
    validatePubspecForPlugin(projectDir: projectDir.absolute.path, expectedPlatforms: <String>[
      'ios',
    ], pluginClass: 'FlutterProjectPlugin',
    unexpectedPlatforms: <String>['some_platform']);
    expect(logger.errorText, isNot(contains(_kNoPlatformsMessage)));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
    Logger: () => logger,
  });

  testUsingContext('plugin supports android if requested', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);

    expect(projectDir.childDirectory('android'), exists);
    expect(
        projectDir.childDirectory('example').childDirectory('android'), exists);
    validatePubspecForPlugin(projectDir: projectDir.absolute.path, expectedPlatforms: const <String>[
      'android'
    ], pluginClass: 'FlutterProjectPlugin',
    unexpectedPlatforms: <String>['some_platform'],
    androidIdentifier: 'com.example.flutter_project');
    expect(logger.errorText, isNot(contains(_kNoPlatformsMessage)));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
    Logger: () => logger,
  });

  testUsingContext('plugin supports web if requested', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=web', projectDir.path]);
    expect(
        projectDir.childDirectory('lib').childFile('flutter_project_web.dart'),
        exists);
    validatePubspecForPlugin(projectDir: projectDir.absolute.path, expectedPlatforms: const <String>[
      'web'
    ], pluginClass: 'FlutterProjectWeb',
    unexpectedPlatforms: <String>['some_platform'],
    androidIdentifier: 'com.example.flutter_project',
    webFileName: 'flutter_project_web.dart');
    expect(logger.errorText, isNot(contains(_kNoPlatformsMessage)));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    Logger: () => logger,
  });

  testUsingContext('throw error if web feature is not enabled and web platform is requested', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    expect(
        ()=> runner.run(<String>['create-plugin', '--no-pub', '--platforms=web', projectDir.path]),
        throwsToolExit(exitCode: 2),
    );
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: false),
    Logger: () => logger,
  });

  testUsingContext('create a plugin with ios, then add macos', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=ios', projectDir.path]);
    expect(projectDir.childDirectory('ios'), exists);
    expect(projectDir.childDirectory('example').childDirectory('ios'), exists);
    validatePubspecForPlugin(projectDir: projectDir.absolute.path, expectedPlatforms: const <String>[
      'ios',
    ], pluginClass: 'FlutterProjectPlugin',
    unexpectedPlatforms: <String>['some_platform']);

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=macos', projectDir.path]);
    expect(projectDir.childDirectory('macos'), exists);
    expect(
        projectDir.childDirectory('example').childDirectory('macos'), exists);
    expect(projectDir.childDirectory('ios'), exists);
    expect(projectDir.childDirectory('example').childDirectory('ios'), exists);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('create a plugin with ios and android', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=ios,android', projectDir.path]);
    expect(projectDir.childDirectory('ios'), exists);
    expect(projectDir.childDirectory('example').childDirectory('ios'), exists);

    expect(projectDir.childDirectory('android'), exists);
    expect(
        projectDir.childDirectory('example').childDirectory('android'), exists);
    expect(projectDir.childDirectory('ios'), exists);
    expect(projectDir.childDirectory('example').childDirectory('ios'), exists);
    validatePubspecForPlugin(projectDir: projectDir.absolute.path, expectedPlatforms: const <String>[
      'ios', 'android'
    ], pluginClass: 'FlutterProjectPlugin',
    unexpectedPlatforms: <String>['some_platform'],
    androidIdentifier: 'com.example.flutter_project');
  });

  testUsingContext('create a plugin with android, delete then re-create folders', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);
    expect(projectDir.childDirectory('android'), exists);
    expect(
        projectDir.childDirectory('example').childDirectory('android'), exists);

    globals.fs.file(globals.fs.path.join(projectDir.path, 'android')).deleteSync(recursive: true);
    globals.fs.file(globals.fs.path.join(projectDir.path, 'example/android')).deleteSync(recursive: true);
    expect(projectDir.childDirectory('android'), isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('android'),
        isNot(exists));

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);

    expect(projectDir.childDirectory('android'), exists);
    expect(
        projectDir.childDirectory('example').childDirectory('android'), exists);
  });

  testUsingContext('create a plugin with android, delete then re-create folders while also adding windows', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);
    expect(projectDir.childDirectory('android'), exists);
    expect(
        projectDir.childDirectory('example').childDirectory('android'), exists);

    globals.fs.file(globals.fs.path.join(projectDir.path, 'android')).deleteSync(recursive: true);
    globals.fs.file(globals.fs.path.join(projectDir.path, 'example/android')).deleteSync(recursive: true);
    expect(projectDir.childDirectory('android'), isNot(exists));
    expect(projectDir.childDirectory('example').childDirectory('android'),
        isNot(exists));

    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=windows', projectDir.path]);

    expect(projectDir.childDirectory('android'), exists);
    expect(
        projectDir.childDirectory('example').childDirectory('android'), exists);
    expect(projectDir.childDirectory('windows'), exists);
    expect(
        projectDir.childDirectory('example').childDirectory('windows'), exists);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('flutter create -t plugin in an empty folder should not show pubspec.yaml updating suggestion', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);
    final String projectDirPath = globals.fs.path.normalize(projectDir.absolute.path);
    final String relativePluginPath = globals.fs.path.normalize(globals.fs.path.relative(projectDirPath));
    expect(logger.statusText, isNot(contains('You need to update $relativePluginPath/pubspec.yaml to support android.\n')));
  }, overrides: <Type, Generator> {
    Logger: () => logger,
  });

  testUsingContext('flutter create -t plugin in an existing plugin should show pubspec.yaml updating suggestion', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    final String projectDirPath = globals.fs.path.normalize(projectDir.absolute.path);
    final String relativePluginPath = globals.fs.path.normalize(globals.fs.path.relative(projectDirPath));
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=ios', projectDir.path]);
    expect(logger.statusText, isNot(contains('You need to update $relativePluginPath/pubspec.yaml to support ios.\n')));
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);
    expect(logger.statusText, contains('You need to update $relativePluginPath/pubspec.yaml to support android.\n'));
  }, overrides: <Type, Generator> {
    Logger: () => logger,
  });

  testUsingContext('newly created plugin has min flutter sdk version as 1.20.0', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=android', projectDir.path]);
    final String rawPubspec = await projectDir.childFile('pubspec.yaml').readAsString();
    final Pubspec pubspec = Pubspec.parse(rawPubspec);
    final Map<String, VersionConstraint> env = pubspec.environment;
    expect(env['flutter'].allows(Version(1, 20, 0)), true);
    expect(env['flutter'].allows(Version(1, 19, 0)), false);
  });

  testUsingContext('Linux plugins handle partially camel-case project names correctly', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    const String projectName = 'foo_BarBaz';
    final Directory projectDir = tempDir.childDirectory(projectName);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=linux', '--skip-name-checks', projectDir.path]);
    final Directory platformDir = projectDir.childDirectory('linux');

    const String classFilenameBase = 'foo_bar_baz_plugin';
    const String headerName = '$classFilenameBase.h';
    final File headerFile = platformDir
        .childDirectory('include')
        .childDirectory(projectName)
        .childFile(headerName);
    final File implFile = platformDir.childFile('$classFilenameBase.cc');
    // Ensure that the files have the right names.
    expect(headerFile, exists);
    expect(implFile, exists);
    // Ensure that the include is correct.
    expect(implFile.readAsStringSync(), contains(headerName));
    // Ensure that the CMake file has the right target and source values.
    final String cmakeContents = platformDir.childFile('CMakeLists.txt').readAsStringSync();
    expect(cmakeContents, contains('"$classFilenameBase.cc"'));
    expect(cmakeContents, contains('set(PLUGIN_NAME "foo_BarBaz_plugin")'));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Windows plugins handle partially camel-case project names correctly', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    const String projectName = 'foo_BarBaz';
    final Directory projectDir = tempDir.childDirectory(projectName);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=windows', '--skip-name-checks', projectDir.path]);
    final Directory platformDir = projectDir.childDirectory('windows');

    const String classFilenameBase = 'foo_bar_baz_plugin';
    const String headerName = '$classFilenameBase.h';
    final File headerFile = platformDir
        .childDirectory('include')
        .childDirectory(projectName)
        .childFile(headerName);
    final File implFile = platformDir.childFile('$classFilenameBase.cpp');
    // Ensure that the files have the right names.
    expect(headerFile, exists);
    expect(implFile, exists);
    // Ensure that the include is correct.
    expect(implFile.readAsStringSync(), contains(headerName));
    // Ensure that the plugin target name matches the post-processed version.
    // Ensure that the CMake file has the right target and source values.
    final String cmakeContents = platformDir.childFile('CMakeLists.txt').readAsStringSync();
    expect(cmakeContents, contains('"$classFilenameBase.cpp"'));
    expect(cmakeContents, contains('set(PLUGIN_NAME "foo_BarBaz_plugin")'));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Linux plugins handle project names ending in _plugin correctly', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    const String projectName = 'foo_bar_plugin';
    final Directory projectDir = tempDir.childDirectory(projectName);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=linux', projectDir.path]);
    final Directory platformDir = projectDir.childDirectory('linux');

    // If the project already ends in _plugin, it shouldn't be added again.
    const String classFilenameBase = projectName;
    const String headerName = '$classFilenameBase.h';
    final File headerFile = platformDir
        .childDirectory('include')
        .childDirectory(projectName)
        .childFile(headerName);
    final File implFile = platformDir.childFile('$classFilenameBase.cc');
    // Ensure that the files have the right names.
    expect(headerFile, exists);
    expect(implFile, exists);
    // Ensure that the include is correct.
    expect(implFile.readAsStringSync(), contains(headerName));
    // Ensure that the CMake file has the right target and source values.
    final String cmakeContents = platformDir.childFile('CMakeLists.txt').readAsStringSync();
    expect(cmakeContents, contains('"$classFilenameBase.cc"'));
    // The "_plugin_plugin" suffix is intentional; because the target names must
    // be unique across the ecosystem, no canonicalization can be done,
    // otherwise plugins called "foo_bar" and "foo_bar_plugin" would collide in
    // builds.
    expect(cmakeContents, contains('set(PLUGIN_NAME "foo_bar_plugin_plugin")'));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Windows plugins handle project names ending in _plugin correctly', () async {
    Cache.flutterRoot = '../..';
    when(mockFlutterVersion.frameworkRevision).thenReturn(frameworkRevision);
    when(mockFlutterVersion.channel).thenReturn(frameworkChannel);

    final CreatePluginCommand command = CreatePluginCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);

    const String projectName = 'foo_bar_plugin';
    final Directory projectDir = tempDir.childDirectory(projectName);
    await runner.run(<String>['create-plugin', '--no-pub', '--platforms=windows', projectDir.path]);
    final Directory platformDir = projectDir.childDirectory('windows');

    // If the project already ends in _plugin, it shouldn't be added again.
    const String classFilenameBase = projectName;
    const String headerName = '$classFilenameBase.h';
    final File headerFile = platformDir
        .childDirectory('include')
        .childDirectory(projectName)
        .childFile(headerName);
    final File implFile = platformDir.childFile('$classFilenameBase.cpp');
    // Ensure that the files have the right names.
    expect(headerFile, exists);
    expect(implFile, exists);
    // Ensure that the include is correct.
    expect(implFile.readAsStringSync(), contains(headerName));
    // Ensure that the CMake file has the right target and source values.
    final String cmakeContents = platformDir.childFile('CMakeLists.txt').readAsStringSync();
    expect(cmakeContents, contains('"$classFilenameBase.cpp"'));
    // The "_plugin_plugin" suffix is intentional; because the target names must
    // be unique across the ecosystem, no canonicalization can be done,
    // otherwise plugins called "foo_bar" and "foo_bar_plugin" would collide in
    // builds.
    expect(cmakeContents, contains('set(PLUGIN_NAME "foo_bar_plugin_plugin")'));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });
}

Future<void> _createProject(
  Directory dir,
  List<String> createArgs,
  List<String> expectedPaths, {
  List<String> unexpectedPaths = const <String>[],
}) async {
  Cache.flutterRoot = '../..';
  final CreatePluginCommand command = CreatePluginCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'create-plugin',
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

Future<void> _createPluginAndAnalyzeProject(
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
    flutterToolsSnapshotPath,
    'analyze',
  ];

  final ProcessResult exec = await Process.run(
    globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
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
    globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
    <String>[
      flutterToolsSnapshotPath,
      'packages',
      'get',
    ],
    workingDirectory: workingDir.path,
  );

  final List<String> args = <String>[
    flutterToolsSnapshotPath,
    'test',
    '--no-color',
    if (target != null) target,
  ];

  final ProcessResult exec = await Process.run(
    globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
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
