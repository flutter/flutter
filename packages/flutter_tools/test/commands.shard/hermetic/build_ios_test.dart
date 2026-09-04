// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_ios.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../general.shard/ios/xcresult_test_data.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_build_command.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

class FakeXcodeProjectInterpreterWithBuildSettings extends FakeXcodeProjectInterpreter {
  FakeXcodeProjectInterpreterWithBuildSettings({
    this.productBundleIdentifier,
    this.developmentTeam = 'abc',
    this.returnsEmptyBuildSettings = false,
  });

  final String? productBundleIdentifier;
  final String? developmentTeam;
  final bool returnsEmptyBuildSettings;

  @override
  Future<Map<String, String>> getBuildSettings(
    XcodeBasedProject xcodeProject, {
    required XcodeProjectBuildContext buildContext,
    Duration timeout = const Duration(minutes: 1),
  }) async {
    if (returnsEmptyBuildSettings) {
      return <String, String>{};
    }

    return <String, String>{
      'PRODUCT_BUNDLE_IDENTIFIER': productBundleIdentifier ?? 'io.flutter.someProject',
      'TARGET_BUILD_DIR': 'build/ios/Release-iphoneos',
      'WRAPPER_NAME': 'Runner.app',
      'DEVELOPMENT_TEAM': ?developmentTeam,
    };
  }
}

final Platform macosPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{'FLUTTER_ROOT': '/', 'HOME': '/'},
);
final Platform notMacosPlatform = FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/'});

void main() {
  late MemoryFileSystem fileSystem;
  late FakeAnalytics fakeAnalytics;
  late BufferLogger logger;
  late FakeProcessManager processManager;
  late FakePlistParser testPlistUtils;
  late OutputPreferences outputPreferences;

  setUpAll(() {
    Cache.disableLocking();
    Cache.flutterRoot = getFlutterRoot();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fileSystem,
      fakeFlutterVersion: FakeFlutterVersion(),
    );
    outputPreferences = OutputPreferences.test();
    logger = BufferLogger.test(outputPreferences: outputPreferences);
    processManager = FakeProcessManager.empty();
    testPlistUtils = FakePlistParser();
  });

  // Sets up the minimal mock project files necessary to look like a Flutter project.
  void createCoreMockProjectFiles() {
    fileSystem.file('pubspec.yaml').writeAsStringSync('name: my_app');
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Sets up the minimal mock project files necessary for iOS builds to succeed.
  void createMinimalMockProjectFiles({bool createWorkspace = true}) {
    fileSystem
        .directory(fileSystem.path.join('ios', 'Runner.xcodeproj'))
        .createSync(recursive: true);
    if (createWorkspace) {
      fileSystem
          .directory(fileSystem.path.join('ios', 'Runner.xcworkspace'))
          .createSync(recursive: true);
    }
    fileSystem
        .file(fileSystem.path.join('ios', 'Runner.xcodeproj', 'project.pbxproj'))
        .createSync();
    createCoreMockProjectFiles();
  }

  List<FakeCommand> postBuildCommands({void Function(List<String> command)? onRun}) {
    return [
      const FakeCommand(
        command: <String>[
          'xattr',
          '-w',
          'com.apple.xcode.CreatedByBuildSystem',
          'true',
          'build/ios/Release-iphoneos',
        ],
      ),
      FakeCommand(
        command: const <String>[
          'rsync',
          '-8',
          '-av',
          '--delete',
          'build/ios/Release-iphoneos/Runner.app',
          'build/ios/iphoneos',
        ],
        onRun: onRun,
      ),
    ];
  }

  // Sets up xcresulttool command for Xcode versions below 16.
  FakeCommand setUpLegacyXCResultCommand({
    String stdout = '',
    void Function(List<String> command)? onRun,
  }) {
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

  BuildCommand createBuildCommand({
    FileSystem? fileSystemParam,
    Logger? loggerParam,
    Platform? platformParam,
    PlistParser? plistParser,
    ProcessManager? processManagerParam,
    XcodeProjectInterpreter? xcodeProjectInterpreter,
    Xcode? xcode,
  }) {
    final FileSystem effectiveFileSystem = fileSystemParam ?? fileSystem;
    final Logger effectiveLogger = loggerParam ?? logger;
    final Platform effectivePlatform = platformParam ?? macosPlatform;
    final ProcessManager effectiveProcessManager = processManagerParam ?? processManager;
    final Xcode effectiveXcode = xcode ?? FakeXcode();
    final XcodeProjectInterpreter effectiveXcodeProjectInterpreter =
        xcodeProjectInterpreter ?? FakeXcodeProjectInterpreterWithBuildSettings();
    final PlistParser effectivePlistParser = plistParser ?? testPlistUtils;
    return createFakeBuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: effectiveFileSystem,
      logger: effectiveLogger,
      osUtils: FakeOperatingSystemUtils(),
      config: FakeConfig(),
      platform: effectivePlatform,
      fileSystemUtils: FileSystemUtils(
        fileSystem: effectiveFileSystem,
        platform: effectivePlatform,
      ),
      terminal: FakeTerminal(),
      plistParser: effectivePlistParser,
      processManager: effectiveProcessManager,
      templateRenderer: FakeTemplateRenderer(),
      xcode: effectiveXcode,
      xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
      artifacts: FakeArtifacts(),
      cache: FakeCache(),
      flutterVersion: FakeFlutterVersion(),
    );
  }

  // Creates a FakeCommand for the xcodebuild call to build the app
  // in the given configuration.
  FakeCommand setUpFakeXcodeBuildHandler({
    bool verbose = false,
    bool simulator = false,
    bool customNaming = false,
    bool hasWorkspace = true,
    bool disablePortPublication = false,
    String? deviceId,
    int exitCode = 0,
    String? stdout,
    void Function(List<String> command)? onRun,
  }) {
    return FakeCommand(
      command: <String>[
        'xcrun',
        'xcodebuild',
        '-configuration',
        if (simulator) 'Debug' else 'Release',
        if (verbose) 'VERBOSE_SCRIPT_LOGGING=YES' else '-quiet',
        '-allowProvisioningUpdates',
        '-allowProvisioningDeviceRegistration',
        if (hasWorkspace) ...<String>[
          '-workspace',
          if (customNaming) 'RenamedWorkspace.xcworkspace' else 'Runner.xcworkspace',
        ] else ...<String>[
          '-project',
          if (customNaming) 'RenamedProj.xcodeproj' else 'Runner.xcodeproj',
        ],
        '-scheme',
        'Runner',
        'BUILD_DIR=/build/ios',
        '-sdk',
        if (simulator) ...<String>['iphonesimulator'] else ...<String>['iphoneos'],
        if (deviceId != null) ...<String>[
          '-destination',
          'id=$deviceId',
        ] else if (simulator) ...<String>[
          '-destination',
          'generic/platform=iOS Simulator',
        ] else ...<String>['-destination', 'generic/platform=iOS'],
        '-resultBundlePath',
        _xcBundleDirectoryPath,
        '-resultBundleVersion',
        '3',
        if (disablePortPublication) 'DISABLE_PORT_PUBLICATION=YES',
        'FLUTTER_SUPPRESS_ANALYTICS=true',
        'COMPILER_INDEX_STORE_ENABLE=NO',
      ],
      stdout:
          '''
      TARGET_BUILD_DIR=build/ios/Release-iphoneos
      WRAPPER_NAME=Runner.app
      $stdout
''',
      exitCode: exitCode,
      onRun: onRun,
    );
  }

  testUsingContext('ios build fails when there is no ios project', () async {
    final BuildCommand command = createBuildCommand();
    createCoreMockProjectFiles();

    expect(
      createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
      throwsToolExit(message: 'Application not configured for iOS'),
    );
  });

  testUsingContext('ios build fails in debug with code analysis', () async {
    final BuildCommand command = createBuildCommand();
    createCoreMockProjectFiles();

    expect(
      createTestCommandRunner(
        command,
      ).run(const <String>['build', 'ios', '--no-pub', '--debug', '--analyze-size']),
      throwsToolExit(message: '--analyze-size" can only be used on release builds'),
    );
  });

  testUsingContext('ios build fails on non-macOS platform', () async {
    final BuildCommand command = createBuildCommand(platformParam: notMacosPlatform);
    fileSystem.file('pubspec.yaml').createSync();
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);

    final bool supported = BuildIOSCommand(
      appleContext: FakeAppleContext(),
      buildSystem: FakeBuildSystem(),
      toolContext: FakeToolContext(logger: BufferLogger.test()),
      verboseHelp: false,
    ).supported;
    expect(
      createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
      supported ? throwsToolExit() : throwsA(isA<UsageException>()),
    );
  });

  testUsingContext('ios build fails eagerly if the Xcode build settings retrieval fails', () async {
    createMinimalMockProjectFiles();

    // Init dummy plist with basic values to detect valid folder
    testPlistUtils.setProperty('CFBundleIdentifier', 'io.flutter.someProject');
    fileSystem
        .file(fileSystem.path.join('ios', 'Runner', 'Info.plist'))
        .createSync(recursive: true);

    final BuildCommand command = createBuildCommand(
      processManagerParam: FakeProcessManager.list(<FakeCommand>[setUpFakeXcodeBuildHandler()]),
      xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
        returnsEmptyBuildSettings: true,
      ),
    );

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
      throwsToolExit(message: 'Encountered error while building for device.'),
    );

    // Eager failure message if something went wrong obtaining the xcode build settings
    expect(
      logger.errorText,
      contains('No Xcode build settings have been found. Please check possible errors above'),
    );
  });

  testUsingContext('ios build outputs path and size when successful', () async {
    final BuildCommand command = createBuildCommand(
      processManagerParam: FakeProcessManager.list(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          onRun: (_) {
            fileSystem
                .directory('build/ios/Release-iphoneos/Runner.app')
                .createSync(recursive: true);
          },
        ),
        ...postBuildCommands(),
      ]),
    );
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']);
    expect(
      logger.statusText,
      contains(RegExp(r'✓ Built build/ios/iphoneos/Runner\.app \(\d+\.\d+MB\)')),
    );
  });

  testUsingContext('ios build invokes xcode build', () async {
    final BuildCommand command = createBuildCommand();
    createMinimalMockProjectFiles();

    processManager.addCommands(<FakeCommand>[
      setUpFakeXcodeBuildHandler(
        onRun: (_) {
          fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
        },
      ),
      ...postBuildCommands(),
    ]);

    await createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']);
    expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
  });

  testUsingContext('ios build invokes xcode build with disable port publication setting', () async {
    final BuildCommand command = createBuildCommand(
      processManagerParam: FakeProcessManager.list(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          disablePortPublication: true,
          onRun: (_) {
            fileSystem
                .directory('build/ios/Release-iphoneos/Runner.app')
                .createSync(recursive: true);
          },
        ),
        ...postBuildCommands(),
      ]),
    );
    createMinimalMockProjectFiles();

    await createTestCommandRunner(
      command,
    ).run(const <String>['build', 'ios', '--no-pub', '--no-publish-port', '--ci']);
    expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
  });

  testUsingContext(
    'ios build invokes xcode build without disable port publication setting when not in CI',
    () async {
      final BuildCommand command = createBuildCommand(
        processManagerParam: FakeProcessManager.list(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            onRun: (_) {
              fileSystem
                  .directory('build/ios/Release-iphoneos/Runner.app')
                  .createSync(recursive: true);
            },
          ),
          ...postBuildCommands(),
        ]),
      );
      createMinimalMockProjectFiles();

      await createTestCommandRunner(
        command,
      ).run(const <String>['build', 'ios', '--no-pub', '--no-publish-port']);
      expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
    },
  );

  testUsingContext(
    'ios build invokes xcode build with renamed xcodeproj and xcworkspace',
    () async {
      final BuildCommand command = createBuildCommand();

      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          customNaming: true,
          onRun: (_) {
            fileSystem
                .directory('build/ios/Release-iphoneos/Runner.app')
                .createSync(recursive: true);
          },
        ),
        ...postBuildCommands(),
      ]);

      fileSystem
          .directory(fileSystem.path.join('ios', 'RenamedProj.xcodeproj'))
          .createSync(recursive: true);
      fileSystem
          .directory(fileSystem.path.join('ios', 'RenamedWorkspace.xcworkspace'))
          .createSync(recursive: true);
      fileSystem
          .file(fileSystem.path.join('ios', 'RenamedProj.xcodeproj', 'project.pbxproj'))
          .createSync();
      createCoreMockProjectFiles();

      await createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']);
      expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
    },
  );

  testUsingContext(
    'ios build invokes xcodebuild with -project when there is no .xcworkspace',
    () async {
      final BuildCommand command = createBuildCommand();
      createMinimalMockProjectFiles(createWorkspace: false);

      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          hasWorkspace: false,
          onRun: (_) {
            fileSystem
                .directory('build/ios/Release-iphoneos/Runner.app')
                .createSync(recursive: true);
          },
        ),
        ...postBuildCommands(),
      ]);

      await createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']);
      expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
    },
  );

  testUsingContext('ios build invokes xcode build with device ID', () async {
    final BuildCommand command = createBuildCommand();
    processManager.addCommands(<FakeCommand>[
      setUpFakeXcodeBuildHandler(
        deviceId: '1234',
        onRun: (_) {
          fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
        },
      ),
      ...postBuildCommands(),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(
      command,
    ).run(const <String>['build', 'ios', '--no-pub', '--device-id', '1234']);
    expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
  });

  testUsingContext('ios simulator build invokes xcode build', () async {
    final BuildCommand command = createBuildCommand();
    processManager.addCommands(<FakeCommand>[
      setUpFakeXcodeBuildHandler(
        simulator: true,
        onRun: (_) {
          fileSystem
              .directory('build/ios/Debug-iphonesimulator/Runner.app')
              .createSync(recursive: true);
        },
      ),
      ...postBuildCommands(),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(
      command,
    ).run(const <String>['build', 'ios', '--simulator', '--no-pub']);
  });

  testUsingContext('ios build invokes xcode build with verbosity', () async {
    final BuildCommand command = createBuildCommand();
    createMinimalMockProjectFiles();
    processManager.addCommands(<FakeCommand>[
      setUpFakeXcodeBuildHandler(
        verbose: true,
        onRun: (_) {
          fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
        },
      ),
      ...postBuildCommands(),
    ]);

    await createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub', '-v']);
  });

  testUsingContext('Performs code size analysis and sends analytics', () async {
    final BuildCommand command = createBuildCommand();
    processManager.addCommands(<FakeCommand>[
      setUpFakeXcodeBuildHandler(
        onRun: (_) {
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
        },
      ),
      ...postBuildCommands(
        onRun: (_) => fileSystem.file('build/ios/iphoneos/Runner.app/Frameworks/App.framework/App')
          ..createSync(recursive: true)
          ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0)),
      ),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(
      command,
      fakeAnalytics,
    ).run(const <String>['build', 'ios', '--no-pub', '--analyze-size']);

    expect(logger.statusText, contains('A summary of your iOS bundle analysis can be found at'));
    expect(logger.statusText, contains('dart devtools --appSizeBase='));
    expect(fakeAnalytics.sentEvents, contains(Event.codeSizeAnalysis(platform: 'ios')));
  });

  group('Analytics for impeller plist setting', () {
    const plistContents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>FLTEnableImpeller</key>
  <false/>
</dict>
</plist>
''';
    const plutilCommand = FakeCommand(
      command: <String>['/usr/bin/plutil', '-convert', 'xml1', '-o', '-', '/ios/Runner/Info.plist'],
      stdout: plistContents,
    );

    testUsingContext('Sends an analytics event when Impeller is enabled', () async {
      final BuildCommand command = createBuildCommand(
        processManagerParam: FakeProcessManager.list(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            onRun: (_) {
              fileSystem
                  .directory('build/ios/Release-iphoneos/Runner.app')
                  .createSync(recursive: true);
            },
          ),
          ...postBuildCommands(
            onRun: (_) =>
                fileSystem.file('build/ios/iphoneos/Runner.app/Frameworks/App.framework/App')
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0)),
          ),
        ]),
      );
      createMinimalMockProjectFiles();

      await createTestCommandRunner(
        command,
        fakeAnalytics,
      ).run(const <String>['build', 'ios', '--no-pub']);

      expect(
        fakeAnalytics.sentEvents,
        contains(Event.flutterBuildInfo(label: 'plist-impeller-enabled', buildType: 'ios')),
      );
    });

    testUsingContext('Sends an analytics event when Impeller is disabled', () async {
      final BuildCommand command = createBuildCommand(
        plistParser: PlistParser(
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          processManager: FakeProcessManager.list(<FakeCommand>[
            plutilCommand,
            plutilCommand,
            plutilCommand,
            plutilCommand,
          ]),
        ),
        processManagerParam: FakeProcessManager.list(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            onRun: (_) {
              fileSystem
                  .directory('build/ios/Release-iphoneos/Runner.app')
                  .createSync(recursive: true);
            },
          ),
          ...postBuildCommands(
            onRun: (_) =>
                fileSystem.file('build/ios/iphoneos/Runner.app/Frameworks/App.framework/App')
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0)),
          ),
        ]),
      );
      createMinimalMockProjectFiles();

      fileSystem.file(fileSystem.path.join('usr', 'bin', 'plutil')).createSync(recursive: true);

      final File infoPlist = fileSystem.file(fileSystem.path.join('ios', 'Runner', 'Info.plist'))
        ..createSync(recursive: true);

      infoPlist.writeAsStringSync(plistContents);

      await createTestCommandRunner(
        command,
        fakeAnalytics,
      ).run(const <String>['build', 'ios', '--no-pub']);

      expect(
        fakeAnalytics.sentEvents,
        contains(Event.flutterBuildInfo(label: 'plist-impeller-disabled', buildType: 'ios')),
      );
    });
  });

  group('xcresults device', () {
    testUsingContext('Trace error if xcresult is empty.', () async {
      final BuildCommand command = createBuildCommand();
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          onRun: (_) {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpLegacyXCResultCommand(),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.traceText, contains('xcresult parser: Unrecognized top level json format.'));
    });

    testUsingContext(
      'Display xcresult issues on console if parsed, suppress Xcode output',
      () async {
        final BuildCommand command = createBuildCommand();
        processManager.addCommands(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            exitCode: 1,
            onRun: (_) {
              fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
            },
            stdout: 'Lots of spew from Xcode',
          ),
          setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithIssues),
          ...postBuildCommands(),
        ]);

        createMinimalMockProjectFiles();

        await expectLater(
          createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
          throwsToolExit(),
        );

        expect(logger.errorText, contains("Use of undeclared identifier 'asdas'"));
        expect(
          logger.errorText,
          contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'),
        );
        expect(logger.statusText, isNot(contains("Xcode's output")));
        expect(logger.statusText, isNot(contains('Lots of spew from Xcode')));
      },
    );

    testUsingContext('Do not display xcresult issues that needs to be discarded.', () async {
      final BuildCommand command = createBuildCommand();
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          onRun: (_) {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithIssuesToBeDiscarded),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains("Use of undeclared identifier 'asdas'"));
      expect(
        logger.errorText,
        contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'),
      );
      expect(
        logger.errorText,
        isNot(contains('Command PhaseScriptExecution failed with a nonzero exit code')),
      );
      expect(
        logger.warningText,
        isNot(contains('but the range of supported deployment target versions is')),
      );
    });

    testUsingContext('Trace if xcresult bundle does not exist.', () async {
      final BuildCommand command = createBuildCommand();
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(exitCode: 1),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithIssues),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(
        logger.traceText,
        contains('The xcresult bundle are not generated. Displaying xcresult is disabled.'),
      );
    });

    testUsingContext(
      'Extra error message for provision profile issue in xcresult bundle.',
      () async {
        final BuildCommand command = createBuildCommand();
        processManager.addCommands(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            exitCode: 1,
            onRun: (_) {
              fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
            },
          ),
          setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithProvisionIssue),
          ...postBuildCommands(),
        ]);

        createMinimalMockProjectFiles();

        await expectLater(
          createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
          throwsToolExit(),
        );

        expect(logger.errorText, contains('Some Provisioning profile issue.'));
        expect(logger.errorText, contains('Error: could not code sign the application.'));
        expect(logger.errorText, contains('To resolve this issue, try the following steps:'));
        expect(logger.errorText, contains('open ios/Runner.xcworkspace'));
        expect(logger.errorText, contains('In Runner > Signing & Capabilities, verify:'));
        expect(
          logger.errorText,
          contains(
            'In Xcode Settings > Accounts, verify the correct Apple Developer account is added',
          ),
        );
        expect(
          logger.errorText,
          contains('Run Product > Build and fix any code signing issues shown by Xcode.'),
        );
      },
    );

    testUsingContext('Display xcresult issues with no provisioning profile.', () async {
      final BuildCommand command = createBuildCommand();
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          onRun: (_) {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithNoProvisioningProfileIssue),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(
        logger.errorText,
        contains(
          'Runner requires a provisioning profile. Select a provisioning profile in the Signing & Capabilities editor',
        ),
      );
      expect(logger.errorText, contains(noProvisioningProfileInstruction));
    });

    testUsingContext(
      'Extra error message for missing simulator platform in xcresult bundle.',
      () async {
        final BuildCommand command = createBuildCommand();
        processManager.addCommands(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            exitCode: 1,
            onRun: (_) {
              fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
            },
          ),
          setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithActionIssues),
          ...postBuildCommands(),
        ]);

        createMinimalMockProjectFiles();

        await expectLater(
          createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
          throwsToolExit(),
        );

        expect(logger.errorText, contains(missingPlatformInstructions('iOS 17.0')));
      },
    );

    testUsingContext('Delete xcresult bundle before each xcodebuild command.', () async {
      final BuildCommand command = createBuildCommand();
      processManager.addCommands(<FakeCommand>[
        // Intentionally fail the first xcodebuild command with concurrent run failure message.
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          stdout: '$kConcurrentRunFailureMessage1 $kConcurrentRunFailureMessage2',
          onRun: (_) {
            fileSystem.systemTempDirectory
                .childDirectory(_xcBundleDirectoryPath)
                .childFile('result.xcresult')
                .createSync(recursive: true);
          },
        ),
        // The second xcodebuild is triggered due to above concurrent run failure message.
        setUpFakeXcodeBuildHandler(
          onRun: (_) {
            // If the file is not cleaned, throw an error, test failure.
            if (fileSystem.systemTempDirectory
                .childDirectory(_xcBundleDirectoryPath)
                .existsSync()) {
              throwToolExit('xcresult bundle file existed.', exitCode: 2);
            }
            fileSystem.systemTempDirectory
                .childDirectory(_xcBundleDirectoryPath)
                .childFile('result.xcresult')
                .createSync(recursive: true);
          },
        ),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonNoIssues),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']);

      expect(logger.statusText, contains('Xcode build done.'));
    });

    testUsingContext(
      'Failed to parse xcresult but display missing provisioning profile issue from stdout.',
      () async {
        final BuildCommand command = createBuildCommand();
        processManager.addCommands(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            exitCode: 1,
            stdout: '''
Runner requires a provisioning profile. Select a provisioning profile in the Signing & Capabilities editor
''',
            onRun: (_) {
              fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
            },
          ),
          setUpLegacyXCResultCommand(stdout: kSampleResultJsonInvalidIssuesMap),
          ...postBuildCommands(),
        ]);

        createMinimalMockProjectFiles();

        await expectLater(
          createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
          throwsToolExit(),
        );

        expect(logger.errorText, contains(noProvisioningProfileInstruction));
      },
    );

    testUsingContext('Failed to parse xcresult but detected no development team issue.', () async {
      final BuildCommand command = createBuildCommand(
        xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
          developmentTeam: null,
        ),
      );
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          exitCode: 1,
          onRun: (_) {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonInvalidIssuesMap),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains(noDevelopmentTeamInstruction));
    });

    testUsingContext('xcresult did not detect issue but detected by stdout.', () async {
      final BuildCommand command = createBuildCommand(
        processManagerParam: FakeProcessManager.list(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            exitCode: 1,
            stdout: '''
Runner requires a provisioning profile. Select a provisioning profile in the Signing & Capabilities editor
''',
            onRun: (_) {
              fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
            },
          ),
          setUpLegacyXCResultCommand(stdout: kSampleResultJsonNoIssues),
          ...postBuildCommands(),
        ]),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains(noProvisioningProfileInstruction));
    });

    testUsingContext(
      'xcresult did not detect issue, no development team is detected from build setting.',
      () async {
        final BuildCommand command = createBuildCommand(
          xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
            developmentTeam: null,
          ),
        );
        processManager.addCommands(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            exitCode: 1,
            onRun: (_) {
              fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
            },
          ),
          setUpLegacyXCResultCommand(stdout: kSampleResultJsonInvalidIssuesMap),
          ...postBuildCommands(),
        ]);

        createMinimalMockProjectFiles();

        await expectLater(
          createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
          throwsToolExit(),
        );

        expect(logger.errorText, contains(noDevelopmentTeamInstruction));
      },
    );

    testUsingContext(
      'No development team issue error message is not displayed if no provisioning profile issue is detected from xcresult first.',
      () async {
        final BuildCommand command = createBuildCommand(
          xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
            developmentTeam: null,
          ),
        );
        processManager.addCommands(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            exitCode: 1,
            onRun: (_) {
              fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
            },
          ),
          setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithNoProvisioningProfileIssue),
          ...postBuildCommands(),
        ]);

        createMinimalMockProjectFiles();

        await expectLater(
          createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
          throwsToolExit(),
        );

        expect(logger.errorText, contains(noProvisioningProfileInstruction));
        expect(logger.errorText, isNot(contains(noDevelopmentTeamInstruction)));
      },
    );

    testUsingContext(
      'General provisioning profile issue error message is not displayed if no development team issue is detected first.',
      () async {
        final BuildCommand command = createBuildCommand(
          xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
            developmentTeam: null,
          ),
        );
        processManager.addCommands(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            exitCode: 1,
            onRun: (_) {
              fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
            },
          ),
          setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithProvisionIssue),
          ...postBuildCommands(),
        ]);

        createMinimalMockProjectFiles();

        await expectLater(
          createTestCommandRunner(command).run(const <String>['build', 'ios', '--no-pub']),
          throwsToolExit(),
        );

        expect(logger.errorText, contains(noDevelopmentTeamInstruction));
        expect(logger.errorText, isNot(contains('Error: could not code sign the application.')));
      },
    );
  });

  group('xcresults simulator', () {
    testUsingContext('Trace error if xcresult is empty.', () async {
      final BuildCommand command = createBuildCommand();
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          simulator: true,
          exitCode: 1,
          onRun: (_) {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpLegacyXCResultCommand(),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(
          command,
        ).run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.traceText, contains('xcresult parser: Unrecognized top level json format.'));
    });

    testUsingContext('Display xcresult issues on console if parsed.', () async {
      final BuildCommand command = createBuildCommand();
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          simulator: true,
          exitCode: 1,
          onRun: (_) {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithIssues),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(
          command,
        ).run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains("Use of undeclared identifier 'asdas'"));
      expect(
        logger.errorText,
        contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'),
      );
    });

    testUsingContext('Do not display xcresult issues that needs to be discarded.', () async {
      final BuildCommand command = createBuildCommand();

      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          simulator: true,
          exitCode: 1,
          onRun: (_) {
            fileSystem.systemTempDirectory.childDirectory(_xcBundleDirectoryPath).createSync();
          },
        ),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithIssuesToBeDiscarded),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(
          command,
        ).run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains("Use of undeclared identifier 'asdas'"));
      expect(
        logger.errorText,
        contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'),
      );
      expect(
        logger.errorText,
        isNot(contains('Command PhaseScriptExecution failed with a nonzero exit code')),
      );
      expect(
        logger.warningText,
        isNot(contains('but the range of supported deployment target versions is')),
      );
    });

    testUsingContext('Trace if xcresult bundle does not exist.', () async {
      final BuildCommand command = createBuildCommand();
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(simulator: true, exitCode: 1),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithIssues),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createTestCommandRunner(
          command,
        ).run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(),
      );

      expect(
        logger.traceText,
        contains('The xcresult bundle are not generated. Displaying xcresult is disabled.'),
      );
    });
  });
}

const _xcBundleDirectoryPath =
    '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle';

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  late bool platformToolsAvailable;

  @override
  late bool licensesAvailable;

  @override
  AndroidSdkVersion? latestVersion;
}
