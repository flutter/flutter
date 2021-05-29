// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

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
    'HOME': '/',
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
  TestUsage usage;
  BufferLogger logger;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    usage = TestUsage();
    logger = BufferLogger.test();
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
    'xattr', '-r', '-d', 'com.apple.FinderInfo', '/'
  ]);

  // Creates a FakeCommand for the xcodebuild call to build the app
  // in the given configuration.
  FakeCommand setUpFakeXcodeBuildHandler({ bool verbose = false, bool showBuildSettings = false, void Function() onRun }) {
    return FakeCommand(
      command: <String>[
        'xcrun',
        'xcodebuild',
        '-configuration', 'Release',
        if (verbose)
          'VERBOSE_SCRIPT_LOGGING=YES'
        else
          '-quiet',
        '-workspace', 'Runner.xcworkspace',
        '-scheme', 'Runner',
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

  const FakeCommand exportArchiveCommand = FakeCommand(
    command: <String>[
      'xcrun',
      'xcodebuild',
      '-exportArchive',
      '-archivePath',
      '/build/ios/archive/Runner.xcarchive',
      '-exportPath',
      '/build/ios/ipa',
      '-exportOptionsPlist',
      '/ExportOptions.plist'
    ],
  );

  testUsingContext('ipa build fails when there is no ios project', () async {
    final BuildCommand command = BuildCommand();
    createCoreMockProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    ), throwsToolExit(message: 'Application not configured for iOS'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails in debug with code analysis', () async {
    final BuildCommand command = BuildCommand();
    createCoreMockProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub', '--debug', '--analyze-size']
    ), throwsToolExit(message: '--analyze-size" can only be used on release builds'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails on non-macOS platform', () async {
    final BuildCommand command = BuildCommand();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      .createSync(recursive: true);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails when export plist does not exist',
      () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await expectToolExitLater(
      createTestCommandRunner(command).run(<String>[
        'build',
        'ipa',
        '--export-options-plist',
        'bogus.plist',
        '--no-pub',
      ]),
      contains('property list does not exist'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () =>
        FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails when export plist is not a file', () async {
    final Directory bogus = fileSystem.directory('bogus')..createSync();
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await expectToolExitLater(
      createTestCommandRunner(command).run(<String>[
        'build',
        'ipa',
        '--export-options-plist',
        bogus.path,
        '--no-pub',
      ]),
      contains('is not a file.'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () =>
        FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build invokes xcode build', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(),
      setUpFakeXcodeBuildHandler(showBuildSettings: true),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build invokes xcode build with verbosity', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub', '-v']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(verbose: true),
      setUpFakeXcodeBuildHandler(verbose: true, showBuildSettings: true),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('code size analysis fails when app not found', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await expectToolExitLater(
      createTestCommandRunner(command).run(
          const <String>['build', 'ipa', '--no-pub', '--analyze-size']
      ),
      contains('Could not find app to analyze code size'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () =>
        FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Performs code size analysis and sends analytics', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    fileSystem.file('build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/App.framework/App')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0));

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub', '--analyze-size']
    );

    expect(testLogger.statusText, contains('A summary of your iOS bundle analysis can be found at'));
    expect(testLogger.statusText, contains('flutter pub global activate devtools; flutter pub global run devtools --appSizeBase='));
    expect(usage.events, contains(
      const TestUsageEvent('code-size-analysis', 'ios'),
    ));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file('build/flutter_size_01/snapshot.arm64.json')
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
        fileSystem.file('build/flutter_size_01/trace.arm64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
      }),
      setUpFakeXcodeBuildHandler(showBuildSettings: true),
    ]),
    Platform: () => macosPlatform,
    FileSystemUtils: () => FileSystemUtils(fileSystem: fileSystem, platform: macosPlatform),
    Usage: () => usage,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build invokes xcode build export archive', () async {
    final String outputPath =
        fileSystem.path.absolute(fileSystem.path.join('build', 'ios', 'ipa'));
    final File exportOptions = fileSystem.file('ExportOptions.plist')
      ..createSync();
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      <String>[
        'build',
        'ipa',
        '--no-pub',
        '--export-options-plist',
        exportOptions.path,
      ],
    );

    expect(logger.statusText, contains('Built IPA to $outputPath.'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
          xattrCommand,
          setUpFakeXcodeBuildHandler(),
          setUpFakeXcodeBuildHandler(showBuildSettings: true),
          exportArchiveCommand,
        ]),
    Platform: () => macosPlatform,
    Logger: () => logger,
    XcodeProjectInterpreter: () =>
        FakeXcodeProjectInterpreterWithBuildSettings(),
  });
}
