// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_ios.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:test/fake.dart';

import '../../general.shard/ios/xcresult_test_data.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

class FakeXcodeProjectInterpreterWithBuildSettings extends FakeXcodeProjectInterpreter {

  FakeXcodeProjectInterpreterWithBuildSettings({this.productBundleIdentifier, this.developmentTeam = 'abc'});

  @override
  Future<Map<String, String>> getBuildSettings(
      String projectPath, {
        XcodeProjectBuildContext? buildContext,
        Duration timeout = const Duration(minutes: 1),
      }) async {
    return <String, String>{
      'PRODUCT_BUNDLE_IDENTIFIER': productBundleIdentifier ?? 'io.flutter.someProject',
      'TARGET_BUILD_DIR': 'build/ios/Release-iphoneos',
      'WRAPPER_NAME': 'Runner.app',
      if (developmentTeam != null) 'DEVELOPMENT_TEAM': developmentTeam!,
    };
  }

  /// The value of 'PRODUCT_BUNDLE_IDENTIFIER'.
  final String? productBundleIdentifier;

  final String? developmentTeam;
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
  late FileSystem fileSystem;
  late TestUsage usage;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    usage = TestUsage();
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
    'xattr', '-r', '-d', 'com.apple.FinderInfo', '/',
  ]);

  FakeCommand setUpRsyncCommand({void Function()? onRun}) {
    return FakeCommand(
      command: const <String>[
        'rsync',
        '-8',
        '-av',
        '--delete',
        'build/ios/Release-iphoneos/Runner.app',
        'build/ios/iphoneos',
      ],
      onRun: onRun,
    );
  }

  FakeCommand setUpXCResultCommand({String stdout = '', void Function()? onRun}) {
    return FakeCommand(
      command: const <String>[
        'xcrun',
        'xcresulttool',
        'get',
        '--path',
        _xcBundleDirectoryPath,
        '--format',
        'json',
      ],
      stdout: stdout,
      onRun: onRun,
    );
  }

  // Creates a FakeCommand for the xcodebuild call to build the app
  // in the given configuration.
  FakeCommand setUpFakeXcodeBuildHandler({
    bool verbose = false,
    bool simulator = false,
    bool customNaming = false,
    String? deviceId,
    int exitCode = 0,
    String? stdout,
    void Function()? onRun,
  }) {
    return FakeCommand(
      command: <String>[
        'xcrun',
        'xcodebuild',
        '-configuration',
        if (simulator)
          'Debug'
        else
          'Release',
        if (verbose)
          'VERBOSE_SCRIPT_LOGGING=YES'
        else
          '-quiet',
        '-workspace',
        if (customNaming)
          'RenamedWorkspace.xcworkspace'
        else
          'Runner.xcworkspace',
        '-scheme', 'Runner',
        'BUILD_DIR=/build/ios',
        '-sdk',
        if (simulator) ...<String>[
          'iphonesimulator',
        ] else ...<String>[
          'iphoneos',
        ],
        if (deviceId != null) ...<String>[
          '-destination',
          'id=$deviceId',
        ] else if (simulator) ...<String>[
          '-destination',
          'generic/platform=iOS Simulator',
        ] else ...<String>[
          '-destination',
          'generic/platform=iOS',
        ],
        '-resultBundlePath', _xcBundleDirectoryPath,
        '-resultBundleVersion', '3',
        'FLUTTER_SUPPRESS_ANALYTICS=true',
        'COMPILER_INDEX_STORE_ENABLE=NO',
      ],
      stdout: '''
      TARGET_BUILD_DIR=build/ios/Release-iphoneos
      WRAPPER_NAME=Runner.app
      $stdout
''',
      exitCode: exitCode,
      onRun: onRun,
    );
  }

  testUsingContext('ios build fails when there is no ios project', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createCoreMockProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ios', '--no-pub']
    ), throwsToolExit(message: 'Application not configured for iOS'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ios build fails in debug with code analysis', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createCoreMockProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ios', '--no-pub', '--debug', '--analyze-size']
    ), throwsToolExit(message: '--analyze-size" can only be used on release builds'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ios build fails on non-macOS platform', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      .createSync(recursive: true);

    final bool supported = BuildIOSCommand(logger: BufferLogger.test(), verboseHelp: false).supported;
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ios', '--no-pub']
    ), supported ? throwsToolExit() : throwsA(isA<UsageException>()));
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ios build invokes xcode build', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ios', '--no-pub']
    );
    expect(testLogger.statusText, contains('build/ios/iphoneos/Runner.app'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
      }),
      setUpRsyncCommand(),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ios build invokes xcode build with renamed xcodeproj and xcworkspace', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );

    fileSystem.directory(fileSystem.path.join('ios', 'RenamedProj.xcodeproj')).createSync(recursive: true);
    fileSystem.directory(fileSystem.path.join('ios', 'RenamedWorkspace.xcworkspace')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('ios', 'RenamedProj.xcodeproj', 'project.pbxproj')).createSync();
    createCoreMockProjectFiles();

    await createTestCommandRunner(command).run(
        const <String>['build', 'ios', '--no-pub']
    );
    expect(testLogger.statusText, contains('build/ios/iphoneos/Runner.app'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(customNaming: true, onRun: () {
        fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
      }),
      setUpRsyncCommand(),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ios build invokes xcode build with device ID', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
        const <String>['build', 'ios', '--no-pub', '--device-id', '1234']
    );
    expect(testLogger.statusText, contains('build/ios/iphoneos/Runner.app'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(deviceId: '1234', onRun: () {
        fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
      }),
      setUpRsyncCommand(),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ios simulator build invokes xcode build', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ios', '--simulator', '--no-pub']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(simulator: true, onRun: () {
        fileSystem.directory('build/ios/Debug-iphonesimulator/Runner.app').createSync(recursive: true);
      }),
      setUpRsyncCommand(),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ios build invokes xcode build with verbosity', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ios', '--no-pub', '-v']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(verbose: true, onRun: () {
        fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
      }),
      setUpRsyncCommand(),
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Performs code size analysis and sends analytics', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ios', '--no-pub', '--analyze-size']
    );

    expect(testLogger.statusText, contains('A summary of your iOS bundle analysis can be found at'));
    expect(testLogger.statusText, contains('dart devtools --appSizeBase='));
    expect(usage.events, contains(
      const TestUsageEvent('code-size-analysis', 'ios'),
    ));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
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
      setUpRsyncCommand(onRun: () => fileSystem.file('build/ios/iphoneos/Runner.app/Frameworks/App.framework/App')
        ..createSync(recursive: true)
        ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0))),
    ]),
    Platform: () => macosPlatform,
    FileSystemUtils: () => FileSystemUtils(fileSystem: fileSystem, platform: macosPlatform),
    Usage: () => usage,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  group('Analytics for impeller plist setting', () {
    const String plistContents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>FLTEnableImpeller</key>
  <false/>
</dict>
</plist>
''';
    const FakeCommand plutilCommand = FakeCommand(
      command: <String>[
        '/usr/bin/plutil', '-convert', 'xml1', '-o', '-', '/ios/Runner/Info.plist',
      ],
      stdout: plistContents,
    );

    testUsingContext('Sends an analytics event when Impeller is enabled', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );
      createMinimalMockProjectFiles();

      await createTestCommandRunner(command).run(
        const <String>['build', 'ios', '--no-pub']
      );

      expect(usage.events, contains(
        const TestUsageEvent(
          'build', 'ios',
          label:'plist-impeller-enabled',
          parameters:CustomDimensions(),
        ),
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(onRun: () {
          fileSystem.directory('build/ios/Release-iphoneos/Runner.app')
            .createSync(recursive: true);
        }),
        setUpRsyncCommand(onRun: () =>
          fileSystem.file('build/ios/iphoneos/Runner.app/Frameworks/App.framework/App')
            ..createSync(recursive: true)
            ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0))),
      ]),
      Platform: () => macosPlatform,
      FileSystemUtils: () => FileSystemUtils(
        fileSystem: fileSystem,
        platform: macosPlatform,
      ),
      Usage: () => usage,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Sends an analytics event when Impeller is disabled', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );
      createMinimalMockProjectFiles();

      fileSystem.file(
        fileSystem.path.join('usr', 'bin', 'plutil'),
      ).createSync(recursive: true);

      final File infoPlist = fileSystem.file(fileSystem.path.join(
        'ios', 'Runner', 'Info.plist',
      ))..createSync(recursive: true);

      infoPlist.writeAsStringSync(plistContents);

      await createTestCommandRunner(command).run(
        const <String>['build', 'ios', '--no-pub']
      );

      expect(usage.events, contains(
        const TestUsageEvent(
          'build', 'ios',
          label:'plist-impeller-disabled',
          parameters:CustomDimensions(),
        ),
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(onRun: () {
          fileSystem.directory('build/ios/Release-iphoneos/Runner.app')
            .createSync(recursive: true);
        }),
        setUpRsyncCommand(onRun: () =>
          fileSystem.file('build/ios/iphoneos/Runner.app/Frameworks/App.framework/App')
            ..createSync(recursive: true)
            ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0))),
      ]),
      Platform: () => macosPlatform,
      FileSystemUtils: () => FileSystemUtils(
        fileSystem: fileSystem,
        platform: macosPlatform,
      ),
      Usage: () => usage,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
      FlutterProjectFactory: () => FlutterProjectFactory(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
      ),
      PlistParser: () => PlistParser(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          plutilCommand, plutilCommand, plutilCommand,
        ]),
      ),
    });
  });

  group('xcresults device', () {
    testUsingContext('Trace error if xcresult is empty.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.traceText, contains('xcresult parser: Unrecognized top level json format.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
          fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
        }),
        setUpXCResultCommand(),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Display xcresult issues on console if parsed, suppress Xcode output', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains("Use of undeclared identifier 'asdas'"));
      expect(testLogger.errorText, contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'));
      expect(testLogger.statusText, isNot(contains("Xcode's output")));
      expect(testLogger.statusText, isNot(contains('Lots of spew from Xcode')));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
          fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
        }, stdout: 'Lots of spew from Xcode',
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Do not display xcresult issues that needs to be discarded.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
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
        setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
          fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
        }),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssuesToBeDiscarded),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Trace if xcresult bundle does not exist.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.traceText, contains('The xcresult bundle are not generated. Displaying xcresult is disabled.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(exitCode: 1),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Extra error message for provision profile issue in xcresult bundle.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains('Some Provisioning profile issue.'));
      expect(testLogger.errorText, contains('It appears that there was a problem signing your application prior to installation on the device.'));
      expect(testLogger.errorText, contains('Verify that the Bundle Identifier in your project is your signing id in Xcode'));
      expect(testLogger.errorText, contains('open ios/Runner.xcworkspace'));
      expect(testLogger.errorText, contains("Also try selecting 'Product > Build' to fix the problem."));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
          fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
        }),
        setUpXCResultCommand(stdout: kSampleResultJsonWithProvisionIssue),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Display xcresult issues with no provisioning profile.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains('Runner requires a provisioning profile. Select a provisioning profile in the Signing & Capabilities editor'));
      expect(testLogger.errorText, contains(noProvisioningProfileInstruction));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithNoProvisioningProfileIssue),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Extra error message for missing simulator platform in xcresult bundle.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains(missingPlatformInstructions('iOS 17.0')));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
          fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
        }),
        setUpXCResultCommand(stdout: kSampleResultJsonWithActionIssues),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Delete xcresult bundle before each xcodebuild command.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']);

      expect(testLogger.statusText, contains('Xcode build done.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        // Intentionally fail the first xcodebuild command with concurrent run failure message.
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          stdout: '$kConcurrentRunFailureMessage1 $kConcurrentRunFailureMessage2',
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).childFile('result.xcresult').createSync(recursive: true);
          }
        ),
        // The second xcodebuild is triggered due to above concurrent run failure message.
        setUpFakeXcodeBuildHandler(
          onRun: () {
            // If the file is not cleaned, throw an error, test failure.
            if (fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).existsSync()) {
              throwToolExit('xcresult bundle file existed.', exitCode: 2);
            }
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).childFile('result.xcresult').createSync(recursive: true);
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonNoIssues),
        setUpRsyncCommand(),
      ],
      ),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Failed to parse xcresult but display missing provisioning profile issue from stdout.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains(noProvisioningProfileInstruction));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          stdout: '''
Runner requires a provisioning profile. Select a provisioning profile in the Signing & Capabilities editor
''',
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonInvalidIssuesMap),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Failed to parse xcresult but detected no development team issue.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains(noDevelopmentTeamInstruction));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonInvalidIssuesMap),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(developmentTeam: null),
    });

    testUsingContext('xcresult did not detect issue but detected by stdout.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains(noProvisioningProfileInstruction));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          stdout: '''
Runner requires a provisioning profile. Select a provisioning profile in the Signing & Capabilities editor
''',
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonNoIssues),
        setUpRsyncCommand(),
      ]),
      EnvironmentType: () => EnvironmentType.physical,
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('xcresult did not detect issue, no development team is detected from build setting.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains(noDevelopmentTeamInstruction));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonInvalidIssuesMap),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(developmentTeam: null),
    });

    testUsingContext('No development team issue error message is not displayed if no provisioning profile issue is detected from xcresult first.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains(noProvisioningProfileInstruction));
      expect(testLogger.errorText, isNot(contains(noDevelopmentTeamInstruction)));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithNoProvisioningProfileIssue),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(developmentTeam: null),
    });

    testUsingContext('General provisioning profile issue error message is not displayed if no development team issue is detected first.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains(noDevelopmentTeamInstruction));
      expect(testLogger.errorText, isNot(contains('It appears that there was a problem signing your application prior to installation on the device.')));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithProvisionIssue),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(developmentTeam: null),
    });
  });

  group('xcresults simulator', () {
    testUsingContext('Trace error if xcresult is empty.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.traceText, contains('xcresult parser: Unrecognized top level json format.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          simulator: true,
          exitCode: 1,
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpXCResultCommand(),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Display xcresult issues on console if parsed.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--simulator',  '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains("Use of undeclared identifier 'asdas'"));
      expect(testLogger.errorText, contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          simulator: true,
          exitCode: 1,
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Do not display xcresult issues that needs to be discarded.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--simulator', '--no-pub']),
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
        setUpFakeXcodeBuildHandler(
          simulator: true,
          exitCode: 1,
          onRun: () {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssuesToBeDiscarded),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Trace if xcresult bundle does not exist.', () async {
      final BuildCommand command = BuildCommand(
        androidSdk: FakeAndroidSdk(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        osUtils: FakeOperatingSystemUtils(),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.traceText, contains('The xcresult bundle are not generated. Displaying xcresult is disabled.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(
          simulator: true,
          exitCode: 1,
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });
  });
}

const String _xcBundleDirectoryPath = '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle';

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  late bool platformToolsAvailable;

  @override
  late bool licensesAvailable;

  @override
  AndroidSdkVersion? latestVersion;
}

class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils({this.hostPlatform = HostPlatform.linux_x64});

  @override
  HostPlatform hostPlatform = HostPlatform.linux_x64;
}
