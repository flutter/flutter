// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

class FakeXcodeProjectInterpreterWithBuildSettings extends FakeXcodeProjectInterpreter {
  @override
  Future<Map<String, String>> getBuildSettings(
      String projectPath, {
        String scheme,
        Duration timeout = const Duration(minutes: 1),
      }) async {
    return <String, String>{
      'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
      'DEVELOPMENT_TEAM': 'abc',
    };
  }
}

final Platform macosPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{
    'FLUTTER_ROOT': '/',
  }
);
final Platform notMacosPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{
    'FLUTTER_ROOT': '/',
  }
);

void main() {
  FileSystem fileSystem;
  MockUsage usage;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    usage = MockUsage();
  });

  // Sets up the minimal mock project files necessary to look like a Flutter project.
  void createCoreMockProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Sets up the minimal mock project files necessary for iOS builds to succeed.
  void createMinimalMockProjectFiles() {
    fileSystem.directory(fileSystem.path.join('ios', 'Runner.xcodeproj')).createSync(recursive: true);
    fileSystem.directory(fileSystem.path.join('ios', 'Runner.xcworkspace')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('ios', 'Runner.xcodeproj', 'project.pbxproj')).createSync();
    createCoreMockProjectFiles();
  }

  const FakeCommand xattrCommand = FakeCommand(command: <String>[
    'xattr', '-r', '-d', 'com.apple.FinderInfo', '/ios'
  ]);

  // Creates a FakeCommand for the xcodebuild call to build the app
  // in the given configuration.
  FakeCommand setUpMockXcodeBuildHandler({ bool verbose = false, bool showBuildSettings = false, void Function() onRun }) {
    return FakeCommand(
      command: <String>[
        '/usr/bin/env',
        'xcrun',
        'xcodebuild',
        '-configuration', 'Release',
        if (verbose)
          'VERBOSE_SCRIPT_LOGGING=YES'
        else
          '-quiet',
        '-workspace', 'Runner.xcworkspace',
        '-scheme', 'Runner',
        'BUILD_DIR=/build/ios',
        '-sdk', 'iphoneos',
        'FLUTTER_SUPPRESS_ANALYTICS=true',
        'COMPILER_INDEX_STORE_ENABLE=NO',
        '-archivePath', '/build/ios/archive/Runner',
        'archive',
        if (showBuildSettings)
          '-showBuildSettings',
      ],
      stdout: 'STDOUT STUFF',
      onRun: onRun,
    );
  }

  testUsingContext('xcarchive build fails when there is no ios project', () async {
    final BuildCommand command = BuildCommand();
    createCoreMockProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'xcarchive', '--no-pub']
    ), throwsToolExit(message: 'Application not configured for iOS'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('xcarchive build fails on non-macOS platform', () async {
    final BuildCommand command = BuildCommand();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      .createSync(recursive: true);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'xcarchive', '--no-pub']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('xcarchive build invokes xcode build', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'xcarchive', '--no-pub']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpMockXcodeBuildHandler(),
      setUpMockXcodeBuildHandler(showBuildSettings: true),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('xcarchive build invokes xcode build with verbosity', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'xcarchive', '--no-pub', '-v']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpMockXcodeBuildHandler(verbose: true),
      setUpMockXcodeBuildHandler(verbose: true, showBuildSettings: true),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Performs code size analysis and sends analytics', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    fileSystem.file('build/ios/Release-iphoneos/Runner.app/Frameworks/App.framework/App')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0));

    await createTestCommandRunner(command).run(
      const <String>['build', 'xcarchive', '--no-pub', '--analyze-size']
    );

    expect(testLogger.statusText, contains('A summary of your iOS bundle analysis can be found at'));
    verify(usage.sendEvent('code-size-analysis', 'ios')).called(1);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpMockXcodeBuildHandler(onRun: () {
        fileSystem.file('build/flutter_size_01/snapshot.arm64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('''[
{
  "l": "dart:_internal",
  "c": "SubListIterable",
  "n": "[Optimized] skip",
  "s": 2400
}
          ]''');
        fileSystem.file('build/flutter_size_01/trace.arm64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
      }),
      setUpMockXcodeBuildHandler(showBuildSettings: true),
    ]),
    Platform: () => macosPlatform,
    FileSystemUtils: () => FileSystemUtils(fileSystem: fileSystem, platform: macosPlatform),
    Usage: () => usage,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });
}

class MockUsage extends Mock implements Usage {}
