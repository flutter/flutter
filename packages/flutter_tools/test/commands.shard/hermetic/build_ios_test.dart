// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_ios.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../../general.shard/ios/xcresult_test_data.dart';
import '../../src/common.dart';
import '../../src/context.dart';
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
  FakeCommand setUpFakeXcodeBuildHandler({
    bool verbose = false,
    bool simulator = false,
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
        '-workspace', 'Runner.xcworkspace',
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
        '-resultBundlePath', _xcBundleFilePath,
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
    final BuildCommand command = BuildCommand();
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
    final BuildCommand command = BuildCommand();
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
    final BuildCommand command = BuildCommand();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      .createSync(recursive: true);

    final bool supported = BuildIOSCommand(verboseHelp: false).supported;
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
    final BuildCommand command = BuildCommand();
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

  testUsingContext('ios build invokes xcode build with device ID', () async {
    final BuildCommand command = BuildCommand();
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
    final BuildCommand command = BuildCommand();
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
    final BuildCommand command = BuildCommand();
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
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ios', '--no-pub', '--analyze-size']
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
  group('xcresults device', () {
    testUsingContext('Trace error if xcresult is empty.', () async {
      final BuildCommand command = BuildCommand();

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
          fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
        }),
        setUpXCResultCommand(),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Display xcresult issues on console if parsed.', () async {
      final BuildCommand command = BuildCommand();

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains("Use of undeclared identifier 'asdas'"));
      expect(testLogger.errorText, contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
          fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
        }),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Do not display xcresult issues that needs to be discarded.', () async {
      final BuildCommand command = BuildCommand();

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
          fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
        }),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssuesToBeDiscarded),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Trace if xcresult bundle does not exist.', () async {
      final BuildCommand command = BuildCommand();

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
      final BuildCommand command = BuildCommand();

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
          fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
        }),
        setUpXCResultCommand(stdout: kSampleResultJsonWithProvisionIssue),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

   testUsingContext('Default bundle identifier error should be hidden if there is another xcresult issue.', () async {
      final BuildCommand command = BuildCommand();

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains("Use of undeclared identifier 'asdas'"));
      expect(testLogger.errorText, contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'));
      expect(testLogger.errorText, isNot(contains('It appears that your application still contains the default signing identifier.')));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
          fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
        }),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      EnvironmentType: () => EnvironmentType.physical,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(productBundleIdentifier: 'com.example'),
    });

    testUsingContext('Show default bundle identifier error if there are no other errors.', () async {
      final BuildCommand command = BuildCommand();

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(testLogger.errorText, contains('It appears that your application still contains the default signing identifier.'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        xattrCommand,
        setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
          fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
        }),
        setUpXCResultCommand(stdout: kSampleResultJsonNoIssues),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      EnvironmentType: () => EnvironmentType.physical,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(productBundleIdentifier: 'com.example'),
    });


    testUsingContext('Display xcresult issues with no provisioning profile.', () async {
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithNoProvisioningProfileIssue),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Failed to parse xcresult but display missing provisioning profile issue from stdout.', () async {
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonInvalidIssuesMap),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Failed to parse xcresult but detected no development team issue.', () async {
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonInvalidIssuesMap),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(developmentTeam: null),
    });


    testUsingContext('xcresult did not detect issue but detected by stdout.', () async {
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
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
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonInvalidIssuesMap),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(developmentTeam: null),
    });

    testUsingContext('No development team issue error message is not displayed if no provisioning profile issue is detected from xcresult first.', () async {
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
          }
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithNoProvisioningProfileIssue),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(developmentTeam: null),
    });

    testUsingContext('General provisioning profile issue error message is not displayed if no development team issue is detected first.', () async {
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
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
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
          },
        ),
        setUpXCResultCommand(),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Display xcresult issues on console if parsed.', () async {
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
          },
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Do not display xcresult issues that needs to be discarded.', () async {
      final BuildCommand command = BuildCommand();

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
            fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
          },
        ),
        setUpXCResultCommand(stdout: kSampleResultJsonWithIssuesToBeDiscarded),
        setUpRsyncCommand(),
      ]),
      Platform: () => macosPlatform,
      XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    });

    testUsingContext('Trace if xcresult bundle does not exist.', () async {
      final BuildCommand command = BuildCommand();

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

const String _xcBundleFilePath = '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle';
