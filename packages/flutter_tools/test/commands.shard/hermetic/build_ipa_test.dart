// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_ios.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../../general.shard/ios/xcresult_test_data.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

class FakeXcodeProjectInterpreterWithBuildSettings extends FakeXcodeProjectInterpreter {
  @override
  Future<Map<String, String>> getBuildSettings(
      String projectPath, {
        XcodeProjectBuildContext buildContext,
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
  void _createCoreMockProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Sets up the minimal mock project files necessary for iOS builds to succeed.
  void _createMinimalMockProjectFiles() {
    fileSystem.directory(fileSystem.path.join('ios', 'Runner.xcodeproj')).createSync(recursive: true);
    fileSystem.directory(fileSystem.path.join('ios', 'Runner.xcworkspace')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('ios', 'Runner.xcodeproj', 'project.pbxproj')).createSync();
    _createCoreMockProjectFiles();
  }

  const FakeCommand xattrCommand = FakeCommand(command: <String>[
    'xattr', '-r', '-d', 'com.apple.FinderInfo', '/'
  ]);

  FakeCommand _setUpXCResultCommand({String stdout = '', void Function() onRun}) {
    return FakeCommand(
      command: const <String>[
        'xcrun',
        'xcresulttool',
        'get',
        '--path',
        _xcBundleFilePath,
        '--format',
        'json',
      ],
      stdout: stdout,
      onRun: onRun,
    );
  }

  // Creates a FakeCommand for the xcodebuild call to build the app
  // in the given configuration.
  FakeCommand _setUpFakeXcodeBuildHandler({ bool verbose = false, int exitCode = 0, void Function() onRun }) {
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
        '-destination',
        'generic/platform=iOS',
        '-resultBundlePath', '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle',
        '-resultBundleVersion', '3',
        'FLUTTER_SUPPRESS_ANALYTICS=true',
        'COMPILER_INDEX_STORE_ENABLE=NO',
        '-archivePath', '/build/ios/archive/Runner',
        'archive',
      ],
      stdout: 'STDOUT STUFF',
      exitCode: exitCode,
      onRun: onRun,
    );
  }

  const FakeCommand exportArchiveCommand = FakeCommand(
    command: <String>[
      'xcrun',
      'xcodebuild',
      '-exportArchive',
      '-allowProvisioningDeviceRegistration',
      '-allowProvisioningUpdates',
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
    _createCoreMockProjectFiles();

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
    _createCoreMockProjectFiles();

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

    final bool supported = BuildIOSArchiveCommand(verboseHelp: false).supported;
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    ), supported ? throwsToolExit() : throwsA(isA<UsageException>()));
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails when export plist does not exist',
      () async {
    final BuildCommand command = BuildCommand();
    _createMinimalMockProjectFiles();

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
    _createMinimalMockProjectFiles();

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
    _createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    );
    expect(testLogger.statusText, contains('build/ios/archive/Runner.xcarchive'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      _setUpFakeXcodeBuildHandler(),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build invokes xcode build with verbosity', () async {
    final BuildCommand command = BuildCommand();
    _createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub', '-v']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      _setUpFakeXcodeBuildHandler(verbose: true),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('code size analysis fails when app not found', () async {
    final BuildCommand command = BuildCommand();
    _createMinimalMockProjectFiles();

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
    _createMinimalMockProjectFiles();

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
      _setUpFakeXcodeBuildHandler(onRun: () {
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
    _createMinimalMockProjectFiles();

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
          _setUpFakeXcodeBuildHandler(),
          exportArchiveCommand,
        ]),
    Platform: () => macosPlatform,
    Logger: () => logger,
    XcodeProjectInterpreter: () =>
        FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Trace error if xcresult is empty.', () async {
    final BuildCommand command = BuildCommand();

    _createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.traceText, contains('xcresult parser: Unrecognized top level json format.'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      _setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
        fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
      }),
      _setUpXCResultCommand(),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Display xcresult issues on console if parsed.', () async {
    final BuildCommand command = BuildCommand();

    _createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.errorText, contains("Use of undeclared identifier 'asdas'"));
    expect(testLogger.errorText, contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      _setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
        fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
      }),
      _setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Do not display xcresult issues that needs to be discarded.', () async {
    final BuildCommand command = BuildCommand();

    _createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.errorText, contains("Use of undeclared identifier 'asdas'"));
    expect(testLogger.errorText, contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'));
    expect(testLogger.errorText, isNot(contains('Command PhaseScriptExecution failed with a nonzero exit code')));
    expect(testLogger.warningText, isNot(contains("The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99.")));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      _setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
        fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
      }),
      _setUpXCResultCommand(stdout: kSampleResultJsonWithIssuesToBeDiscarded),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Trace if xcresult bundle does not exist.', () async {
    final BuildCommand command = BuildCommand();

    _createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.traceText, contains('The xcresult bundle are not generated. Displaying xcresult is disabled.'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      _setUpFakeXcodeBuildHandler(exitCode: 1),
      _setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });


  testUsingContext('Extra error message for provision profile issue in xcresulb bundle.', () async {
    final BuildCommand command = BuildCommand();

    _createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.errorText, contains('Some Provisioning profile issue.'));
    expect(testLogger.errorText, contains('It appears that there was a problem signing your application prior to installation on the device.'));
    expect(testLogger.errorText, contains('Verify that the Bundle Identifier in your project is your signing id in Xcode'));
    expect(testLogger.errorText, contains('open ios/Runner.xcworkspace'));
    expect(testLogger.errorText, contains("Also try selecting 'Product > Build' to fix the problem:"));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      _setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
        fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
      }),
      _setUpXCResultCommand(stdout: kSampleResultJsonWithProvisionIssue),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });
}

const String _xcBundleFilePath = '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle';
