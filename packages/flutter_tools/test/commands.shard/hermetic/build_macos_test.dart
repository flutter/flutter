// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_macos.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

class FakeXcodeProjectInterpreterWithProfile extends FakeXcodeProjectInterpreter {
  @override
  Future<XcodeProjectInfo> getInfo(String projectPath, { String projectFilename }) async {
    return XcodeProjectInfo(
      <String>['Runner'],
      <String>['Debug', 'Profile', 'Release'],
      <String>['Runner'],
      BufferLogger.test(),
    );
  }
}

final Platform macosPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{
    'FLUTTER_ROOT': '/',
    'HOME': '/',
  }
);

final FakePlatform macosPlatformCustomEnv = FakePlatform(
    operatingSystem: 'macos',
    environment: <String, String>{
      'FLUTTER_ROOT': '/',
      'HOME': '/',
    }
);

final Platform notMacosPlatform = FakePlatform(
  environment: <String, String>{
    'FLUTTER_ROOT': '/',
  }
);

void main() {
  FileSystem fileSystem;
  TestUsage usage;
  FakeProcessManager fakeProcessManager;
  XcodeProjectInterpreter xcodeProjectInterpreter;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    usage = TestUsage();
    fakeProcessManager = FakeProcessManager.empty();
    xcodeProjectInterpreter = FakeXcodeProjectInterpreter();
  });

  // Sets up the minimal mock project files necessary to look like a Flutter project.
  void createCoreMockProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Sets up the minimal mock project files necessary for macOS builds to succeed.
  void createMinimalMockProjectFiles() {
    fileSystem.directory(fileSystem.path.join('macos', 'Runner.xcworkspace')).createSync(recursive: true);
    createCoreMockProjectFiles();
  }

  // Creates a FakeCommand for the xcodebuild call to build the app
  // in the given configuration.
  FakeCommand setUpFakeXcodeBuildHandler(String configuration, { bool verbose = false, void Function() onRun }) {
    final FlutterProject flutterProject = FlutterProject.fromDirectory(fileSystem.currentDirectory);
    final Directory flutterBuildDir = fileSystem.directory(getMacOSBuildDirectory());
    return FakeCommand(
      command: <String>[
        '/usr/bin/env',
        'xcrun',
        'xcodebuild',
        '-workspace', flutterProject.macos.xcodeWorkspace.path,
        '-configuration', configuration,
        '-scheme', 'Runner',
        '-derivedDataPath', flutterBuildDir.absolute.path,
        'OBJROOT=${fileSystem.path.join(flutterBuildDir.absolute.path, 'Build', 'Intermediates.noindex')}',
        'SYMROOT=${fileSystem.path.join(flutterBuildDir.absolute.path, 'Build', 'Products')}',
        if (verbose)
          'VERBOSE_SCRIPT_LOGGING=YES'
        else
          '-quiet',
        'COMPILER_INDEX_STORE_ENABLE=NO',
      ],
      stdout: 'STDOUT STUFF',
      onRun: () {
        fileSystem.file(fileSystem.path.join('macos', 'Flutter', 'ephemeral', '.app_filename'))
          ..createSync(recursive: true)
          ..writeAsStringSync('example.app');
        if (onRun != null) {
          onRun();
        }
      }
    );
  }

  testUsingContext('macOS build fails when there is no macos project', () async {
    final BuildCommand command = BuildCommand();
    createCoreMockProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--no-pub']
    ), throwsToolExit(message: 'No macOS desktop project configured. See '
      'https://docs.flutter.dev/desktop#add-desktop-support-to-an-existing-flutter-app '
      'to learn about adding macOS support to a project.'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build fails on non-macOS platform', () async {
    final BuildCommand command = BuildCommand();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      .createSync(recursive: true);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--no-pub']
    ), throwsA(isA<UsageException>()));
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build fails when feature is disabled', () async {
    final BuildCommand command = BuildCommand();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
        .createSync(recursive: true);

    expect(createTestCommandRunner(command).run(
        const <String>['build', 'macos', '--no-pub']
    ), throwsToolExit(message: '"build macos" is not currently supported. To enable, run "flutter config --enable-macos-desktop".'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(),
  });

  testUsingContext('macOS build forwards error stdout to status logger error', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--debug', '--no-pub']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.errorText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpFakeXcodeBuildHandler('Debug')
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes xcode build (debug)', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--debug', '--no-pub']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpFakeXcodeBuildHandler('Debug')
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes xcode build (debug) with verbosity', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--debug', '--no-pub', '-v']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpFakeXcodeBuildHandler('Debug', verbose: true)
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });


  testUsingContext('macOS build invokes xcode build (profile)', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--profile', '--no-pub']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpFakeXcodeBuildHandler('Profile')
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithProfile(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes xcode build (release)', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--release', '--no-pub']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpFakeXcodeBuildHandler('Release')
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build supports standard desktop build options', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();
    fileSystem.file('lib/other.dart')
      .createSync(recursive: true);
    fileSystem.file('foo/bar.sksl.json')
      .createSync(recursive: true);

    await createTestCommandRunner(command).run(
      const <String>[
        'build',
        'macos',
        '--target=lib/other.dart',
        '--no-pub',
        '--track-widget-creation',
        '--split-debug-info=foo/',
        '--enable-experiment=non-nullable',
        '--obfuscate',
        '--dart-define=foo.bar=2',
        '--dart-define=fizz.far=3',
        '--tree-shake-icons',
        '--bundle-sksl-path=foo/bar.sksl.json',
      ]
    );
    final List<String> contents = fileSystem
      .file('./macos/Flutter/ephemeral/Flutter-Generated.xcconfig')
      .readAsLinesSync();

    expect(contents, containsAll(<String>[
      'FLUTTER_APPLICATION_PATH=/',
      'FLUTTER_TARGET=lib/other.dart',
      'FLUTTER_BUILD_DIR=build',
      'FLUTTER_BUILD_NAME=1.0.0',
      'FLUTTER_BUILD_NUMBER=1',
      'EXCLUDED_ARCHS=arm64',
      'DART_DEFINES=Zm9vLmJhcj0y,Zml6ei5mYXI9Mw==',
      'DART_OBFUSCATION=true',
      'EXTRA_FRONT_END_OPTIONS=--enable-experiment=non-nullable',
      'EXTRA_GEN_SNAPSHOT_OPTIONS=--enable-experiment=non-nullable',
      'SPLIT_DEBUG_INFO=foo/',
      'TRACK_WIDGET_CREATION=true',
      'TREE_SHAKE_ICONS=true',
      'BUNDLE_SKSL_PATH=foo/bar.sksl.json',
      'PACKAGE_CONFIG=/.dart_tool/package_config.json',
      'COCOAPODS_PARALLEL_CODE_SIGN=true',
    ]));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpFakeXcodeBuildHandler('Release')
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    Artifacts: () => Artifacts.test(),
  });

  testUsingContext('build settings contains Flutter Xcode environment variables', () async {

    macosPlatformCustomEnv.environment = Map<String, String>.unmodifiable(<String, String>{
      'FLUTTER_XCODE_ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon.special'
    });

    final FlutterProject flutterProject = FlutterProject.fromDirectory(fileSystem.currentDirectory);
    final Directory flutterBuildDir = fileSystem.directory(getMacOSBuildDirectory());

    fakeProcessManager.addCommands(<FakeCommand>[
      FakeCommand(
        command: <String>[
          '/usr/bin/env',
          'xcrun',
          'xcodebuild',
          '-workspace', flutterProject.macos.xcodeWorkspace.path,
          '-configuration', 'Debug',
          '-scheme', 'Runner',
          '-derivedDataPath', flutterBuildDir.absolute.path,
          'OBJROOT=${fileSystem.path.join(flutterBuildDir.absolute.path, 'Build', 'Intermediates.noindex')}',
          'SYMROOT=${fileSystem.path.join(flutterBuildDir.absolute.path, 'Build', 'Products')}',
          '-quiet',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon.special',
        ],
      ),
    ]);

    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
        const <String>['build', 'macos', '--debug', '--no-pub']
    );

    expect(fakeProcessManager.hasRemainingExpectations, isFalse);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatformCustomEnv,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    XcodeProjectInterpreter: () => xcodeProjectInterpreter,
  });

  testUsingContext('macOS build supports build-name and build-number', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>[
        'build',
        'macos',
        '--debug',
        '--no-pub',
        '--build-name=1.2.3',
        '--build-number=42',
      ],
    );
    final String contents = fileSystem
      .file('./macos/Flutter/ephemeral/Flutter-Generated.xcconfig')
      .readAsStringSync();

    expect(contents, contains('FLUTTER_BUILD_NAME=1.2.3'));
    expect(contents, contains('FLUTTER_BUILD_NUMBER=42'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpFakeXcodeBuildHandler('Debug')
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('Refuses to build for macOS when feature is disabled', () {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    final bool supported = BuildMacosCommand(verboseHelp: false).supported;
    expect(() => runner.run(<String>['build', 'macos', '--no-pub']),
      supported ? throwsToolExit() : throwsA(isA<UsageException>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(),
  });

  testUsingContext('hidden when not enabled on macOS host', () {
    expect(BuildMacosCommand(verboseHelp: false).hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(),
    Platform: () => macosPlatform,
  });

  testUsingContext('Not hidden when enabled and on macOS host', () {
    expect(BuildMacosCommand(verboseHelp: false).hidden, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    Platform: () => macosPlatform,
  });

  testUsingContext('Performs code size analysis and sends analytics', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    fileSystem.file('build/macos/Build/Products/Release/Runner.app/App')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0));

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--no-pub', '--analyze-size']
    );

    expect(testLogger.statusText, contains('A summary of your macOS bundle analysis can be found at'));
    expect(testLogger.statusText, contains('flutter pub global activate devtools; flutter pub global run devtools --appSizeBase='));
    expect(usage.events, contains(
      const TestUsageEvent('code-size-analysis', 'macos'),
    ));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpFakeXcodeBuildHandler('Release', onRun: () {
        fileSystem.file('build/flutter_size_01/snapshot.x86_64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
[
  {
    "l": "dart:_internal",
    "c": "SubListIterable",
    "n": "[Optimized] skip",
    "s": 2400
  }
]''');
        fileSystem.file('build/flutter_size_01/trace.x86_64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
      }),
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    FileSystemUtils: () => FileSystemUtils(fileSystem: fileSystem, platform: macosPlatform),
    Usage: () => usage,
  });
}
