// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
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
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../general.shard/ios/xcresult_test_data.dart';
import '../../src/common.dart';
import '../../src/fake_build_command.dart';
import '../../src/fake_process_manager.dart';
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

  CommandRunner<void> createBuildRunner({
    FileSystem? fs,
    OperatingSystemUtils? osUtils,
    Platform? platform,
    PlistParser? plistParser,
    ProcessManager? pm,
    Logger? testLogger,
    XcodeProjectInterpreter? xcodeProjectInterpreter,
  }) {
    final FileSystem targetFileSystem = fs ?? fileSystem;
    final Platform targetPlatform = platform ?? macosPlatform;
    final BuildCommand command = createFakeBuildCommand(
      androidSdk: FakeAndroidSdk(),
      artifacts: FakeArtifacts(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      cache: FakeCache(),
      config: FakeConfig(),
      fileSystem: targetFileSystem,
      fileSystemUtils: FileSystemUtils(fileSystem: targetFileSystem, platform: targetPlatform),
      flutterVersion: FakeFlutterVersion(),
      logger: testLogger ?? logger,
      osUtils: osUtils ?? FakeOperatingSystemUtils(),
      platform: targetPlatform,
      plistParser: plistParser ?? testPlistUtils,
      processManager: pm ?? processManager,
      templateRenderer: FakeTemplateRenderer(),
      terminal: FakeTerminal(),
      xcode: FakeXcode(),
      xcodeProjectInterpreter:
          xcodeProjectInterpreter ?? FakeXcodeProjectInterpreterWithBuildSettings(),
    );
    return createTestCommandRunner(command, fakeAnalytics);
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
    String? scriptOutputStreamFile,
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
        if (scriptOutputStreamFile != null) 'SCRIPT_OUTPUT_STREAM_FILE=$scriptOutputStreamFile',
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

  test('ios build fails when there is no ios project', () async {
    createCoreMockProjectFiles();

    await expectLater(
      createBuildRunner().run(const <String>['build', 'ios', '--no-pub']),
      throwsToolExit(message: 'Application not configured for iOS'),
    );
  });

  test('ios build fails in debug with code analysis', () async {
    createCoreMockProjectFiles();

    await expectLater(
      createBuildRunner().run(const <String>[
        'build',
        'ios',
        '--no-pub',
        '--debug',
        '--analyze-size',
      ]),
      throwsToolExit(message: '--analyze-size" can only be used on release builds'),
    );
  });

  test('ios build fails on non-macOS platform', () async {
    fileSystem.file('pubspec.yaml').createSync();
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);

    final bool supported = BuildIOSCommand(
      appleContext: FakeAppleContext(),
      buildSystem: FakeBuildSystem(),
      templateRenderer: FakeTemplateRenderer(),
      toolContext: FakeToolContext(logger: BufferLogger.test()),
      verboseHelp: false,
    ).supported;
    await expectLater(
      createBuildRunner(platform: notMacosPlatform).run(const <String>['build', 'ios', '--no-pub']),
      supported ? throwsToolExit() : throwsA(isA<UsageException>()),
    );
  });

  test('ios build fails eagerly if the Xcode build settings retrieval fails', () async {
    createMinimalMockProjectFiles();

    // Init dummy plist with basic values to detect valid folder
    testPlistUtils.setProperty('CFBundleIdentifier', 'io.flutter.someProject');
    fileSystem
        .file(fileSystem.path.join('ios', 'Runner', 'Info.plist'))
        .createSync(recursive: true);

    await expectLater(
      createBuildRunner(
        pm: FakeProcessManager.list(<FakeCommand>[setUpFakeXcodeBuildHandler()]),
        xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
          returnsEmptyBuildSettings: true,
        ),
      ).run(const <String>['build', 'ios', '--no-pub']),
      throwsToolExit(message: 'Encountered error while building for device.'),
    );

    // Eager failure message if something went wrong obtaining the xcode build settings
    expect(
      logger.errorText,
      contains('No Xcode build settings have been found. Please check possible errors above'),
    );
  });

  test('ios build outputs path and size when successful', () async {
    createMinimalMockProjectFiles();

    await createBuildRunner(
      pm: FakeProcessManager.list(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          onRun: (_) {
            fileSystem
                .directory('build/ios/Release-iphoneos/Runner.app')
                .createSync(recursive: true);
          },
        ),
        ...postBuildCommands(),
      ]),
    ).run(const <String>['build', 'ios', '--no-pub']);
    expect(
      logger.statusText,
      contains(RegExp(r'✓ Built build/ios/iphoneos/Runner\.app \(\d+\.\d+MB\)')),
    );
  });

  test('ios build invokes xcode build', () async {
    createMinimalMockProjectFiles();

    processManager.addCommands(<FakeCommand>[
      setUpFakeXcodeBuildHandler(
        onRun: (_) {
          fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
        },
      ),
      ...postBuildCommands(),
    ]);

    await createBuildRunner().run(const <String>['build', 'ios', '--no-pub']);
    expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
  });

  test('ios build invokes xcode build with disable port publication setting', () async {
    createMinimalMockProjectFiles();

    await createBuildRunner(
      pm: FakeProcessManager.list(<FakeCommand>[
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
    ).run(const <String>['build', 'ios', '--no-pub', '--no-publish-port', '--ci']);
    expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
  });

  test(
    'ios build invokes xcode build without disable port publication setting when not in CI',
    () async {
      createMinimalMockProjectFiles();

      await createBuildRunner(
        pm: FakeProcessManager.list(<FakeCommand>[
          setUpFakeXcodeBuildHandler(
            onRun: (_) {
              fileSystem
                  .directory('build/ios/Release-iphoneos/Runner.app')
                  .createSync(recursive: true);
            },
          ),
          ...postBuildCommands(),
        ]),
      ).run(const <String>['build', 'ios', '--no-pub', '--no-publish-port']);
      expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
    },
  );

  test('ios build invokes xcode build with renamed xcodeproj and xcworkspace', () async {
    processManager.addCommands(<FakeCommand>[
      setUpFakeXcodeBuildHandler(
        customNaming: true,
        onRun: (_) {
          fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
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

    await createBuildRunner().run(const <String>['build', 'ios', '--no-pub']);
    expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
  });

  test('ios build invokes xcodebuild with -project when there is no .xcworkspace', () async {
    createMinimalMockProjectFiles(createWorkspace: false);

    processManager.addCommands(<FakeCommand>[
      setUpFakeXcodeBuildHandler(
        hasWorkspace: false,
        onRun: (_) {
          fileSystem.directory('build/ios/Release-iphoneos/Runner.app').createSync(recursive: true);
        },
      ),
      ...postBuildCommands(),
    ]);

    await createBuildRunner().run(const <String>['build', 'ios', '--no-pub']);
    expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
  });

  test('ios build invokes xcode build with device ID', () async {
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

    await createBuildRunner().run(const <String>[
      'build',
      'ios',
      '--no-pub',
      '--device-id',
      '1234',
    ]);
    expect(logger.statusText, contains('build/ios/iphoneos/Runner.app'));
  });

  test('ios simulator build invokes xcode build', () async {
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

    await createBuildRunner().run(const <String>['build', 'ios', '--simulator', '--no-pub']);
  });

  test('ios build config-only writes Generated.xcconfig with local engine options', () async {
    fileSystem
        .directory('engine')
        .childDirectory('src')
        .childDirectory('out')
        .childDirectory('ios_debug')
        .childDirectory('Flutter.xcframework')
        .childDirectory('ios-arm64')
        .childDirectory('Flutter.framework')
        .createSync(recursive: true);
    fileSystem
        .directory('engine')
        .childDirectory('src')
        .childDirectory('out')
        .childDirectory('host_debug')
        .createSync(recursive: true);
    createMinimalMockProjectFiles();

    await createBuildRunner().run(const <String>[
      '--local-engine=ios_debug',
      '--local-engine-host=host_debug',
      '--local-engine-src-path=engine/src',
      'build',
      'ios',
      '--config-only',
      '--no-pub',
    ]);

    final File configFile = fileSystem.file('ios/Flutter/Generated.xcconfig');
    expect(configFile, exists);
    final String configContent = configFile.readAsStringSync();
    expect(configContent, contains('LOCAL_ENGINE=ios_debug'));
    expect(configContent, contains('LOCAL_ENGINE_HOST=host_debug'));
    expect(configContent, contains('FLUTTER_ENGINE=engine/src'));
  });

  test('ios build debug config-only writes TRACK_WIDGET_CREATION=true to Generated.xcconfig by default', () async {
    createMinimalMockProjectFiles();

    await createBuildRunner().run(const <String>[
      'build',
      'ios',
      '--debug',
      '--config-only',
      '--no-pub',
    ]);

    final File configFile = fileSystem.file('ios/Flutter/Generated.xcconfig');
    expect(configFile, exists);
    final String configContent = configFile.readAsStringSync();
    expect(configContent, contains('TRACK_WIDGET_CREATION=true'));
  });

  test('ios build debug config-only respects --no-track-widget-creation flag', () async {
    createMinimalMockProjectFiles();

    await createBuildRunner().run(const <String>[
      'build',
      'ios',
      '--debug',
      '--config-only',
      '--no-pub',
      '--no-track-widget-creation',
    ]);

    final File configFile = fileSystem.file('ios/Flutter/Generated.xcconfig');
    expect(configFile, exists);
    final String configContent = configFile.readAsStringSync();
    expect(configContent, contains('TRACK_WIDGET_CREATION=false'));
  });

  test('ios build invokes xcode build with verbosity', () async {
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

    await createBuildRunner().run(const <String>['build', 'ios', '--no-pub', '-v']);
  });

  test('Performs code size analysis and sends analytics', () async {
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

    await createBuildRunner().run(const <String>['build', 'ios', '--no-pub', '--analyze-size']);

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

    test('Sends an analytics event when Impeller is enabled', () async {
      createMinimalMockProjectFiles();

      await createBuildRunner(
        pm: FakeProcessManager.list(<FakeCommand>[
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
      ).run(const <String>['build', 'ios', '--no-pub']);

      expect(
        fakeAnalytics.sentEvents,
        contains(Event.flutterBuildInfo(label: 'plist-impeller-enabled', buildType: 'ios')),
      );
    });

    test('Sends an analytics event when Impeller is disabled', () async {
      createMinimalMockProjectFiles();

      fileSystem.file(fileSystem.path.join('usr', 'bin', 'plutil')).createSync(recursive: true);

      final File infoPlist = fileSystem.file(fileSystem.path.join('ios', 'Runner', 'Info.plist'))
        ..createSync(recursive: true);

      infoPlist.writeAsStringSync(plistContents);

      await createBuildRunner(
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
        pm: FakeProcessManager.list(<FakeCommand>[
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
      ).run(const <String>['build', 'ios', '--no-pub']);

      expect(
        fakeAnalytics.sentEvents,
        contains(Event.flutterBuildInfo(label: 'plist-impeller-disabled', buildType: 'ios')),
      );
    });
  });

  group('xcresults device', () {
    test('Trace error if xcresult is empty.', () async {
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
        createBuildRunner().run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.traceText, contains('xcresult parser: Unrecognized top level json format.'));
    });

    test('Display xcresult issues on console if parsed, suppress Xcode output', () async {
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
        createBuildRunner().run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains("Use of undeclared identifier 'asdas'"));
      expect(
        logger.errorText,
        contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'),
      );
      expect(logger.statusText, isNot(contains("Xcode's output")));
      expect(logger.statusText, isNot(contains('Lots of spew from Xcode')));
    });

    test('Do not display xcresult issues that needs to be discarded.', () async {
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
        createBuildRunner().run(const <String>['build', 'ios', '--no-pub']),
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

    test('Trace if xcresult bundle does not exist.', () async {
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(exitCode: 1),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithIssues),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createBuildRunner().run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(
        logger.traceText,
        contains('The xcresult bundle are not generated. Displaying xcresult is disabled.'),
      );
    });

    test('Extra error message for provision profile issue in xcresult bundle.', () async {
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
        createBuildRunner().run(const <String>['build', 'ios', '--no-pub']),
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
    });

    test('Display xcresult issues with no provisioning profile.', () async {
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
        createBuildRunner().run(const <String>['build', 'ios', '--no-pub']),
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

    test('Extra error message for missing simulator platform in xcresult bundle.', () async {
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
        createBuildRunner().run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains(missingPlatformInstructions('iOS 17.0')));
    });

    test('Delete xcresult bundle before each xcodebuild command.', () async {
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

      await createBuildRunner().run(const <String>['build', 'ios', '--no-pub']);

      expect(logger.statusText, contains('Xcode build done.'));
    });

    test(
      'Failed to parse xcresult but display missing provisioning profile issue from stdout.',
      () async {
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
          createBuildRunner().run(const <String>['build', 'ios', '--no-pub']),
          throwsToolExit(),
        );

        expect(logger.errorText, contains(noProvisioningProfileInstruction));
      },
    );

    test('Failed to parse xcresult but detected no development team issue.', () async {
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
        createBuildRunner(
          xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
            developmentTeam: null,
          ),
        ).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains(noDevelopmentTeamInstruction));
    });

    test('xcresult did not detect issue but detected by stdout.', () async {
      createMinimalMockProjectFiles();

      await expectLater(
        createBuildRunner(
          pm: FakeProcessManager.list(<FakeCommand>[
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
        ).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains(noProvisioningProfileInstruction));
    });

    test(
      'xcresult did not detect issue, no development team is detected from build setting.',
      () async {
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
          createBuildRunner(
            xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
              developmentTeam: null,
            ),
          ).run(const <String>['build', 'ios', '--no-pub']),
          throwsToolExit(),
        );

        expect(logger.errorText, contains(noDevelopmentTeamInstruction));
      },
    );

    test('No development team issue error message is not displayed if no provisioning profile issue is detected from xcresult first.', () async {
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
        createBuildRunner(
          xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
            developmentTeam: null,
          ),
        ).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains(noProvisioningProfileInstruction));
      expect(logger.errorText, isNot(contains(noDevelopmentTeamInstruction)));
    });

    test('General provisioning profile issue error message is not displayed if no development team issue is detected first.', () async {
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
        createBuildRunner(
          xcodeProjectInterpreter: FakeXcodeProjectInterpreterWithBuildSettings(
            developmentTeam: null,
          ),
        ).run(const <String>['build', 'ios', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains(noDevelopmentTeamInstruction));
      expect(logger.errorText, isNot(contains('Error: could not code sign the application.')));
    });
  });

  group('xcresults simulator', () {
    test('Trace error if xcresult is empty.', () async {
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
        createBuildRunner().run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.traceText, contains('xcresult parser: Unrecognized top level json format.'));
    });

    test('Display xcresult issues on console if parsed.', () async {
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
        createBuildRunner().run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(),
      );

      expect(logger.errorText, contains("Use of undeclared identifier 'asdas'"));
      expect(
        logger.errorText,
        contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'),
      );
    });

    test('Do not display xcresult issues that needs to be discarded.', () async {
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
        createBuildRunner().run(const <String>['build', 'ios', '--simulator', '--no-pub']),
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

    test('Trace if xcresult bundle does not exist.', () async {
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(simulator: true, exitCode: 1),
        setUpLegacyXCResultCommand(stdout: kSampleResultJsonWithIssues),
        ...postBuildCommands(),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createBuildRunner().run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(),
      );

      expect(
        logger.traceText,
        contains('The xcresult bundle are not generated. Displaying xcresult is disabled.'),
      );
    });

    test('Do not crash if temporary build directory is deleted before cleanup.', () async {
      processManager.addCommands(<FakeCommand>[
        setUpFakeXcodeBuildHandler(
          simulator: true,
          exitCode: 1,
          onRun: (_) {
            final Directory tempDir = fileSystem.directory(_xcBundleDirectoryPath).parent;
            expect(tempDir, exists);
            tempDir.deleteSync(recursive: true);
          },
        ),
      ]);

      createMinimalMockProjectFiles();

      await expectLater(
        createBuildRunner().run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(message: 'Encountered error while building for simulator.'),
      );
      expect(processManager.hasRemainingExpectations, isFalse);
    });

    Future<void> runTerminalBuildWithDeletedTempDir({
      required void Function(Directory tempDir, File pipeFile) onXcodeRun,
      String initialPipeContents = '',
    }) async {
      final errorHandlingFileSystem = ErrorHandlingFileSystem(
        delegate: fileSystem,
        platform: macosPlatform,
      );
      final CommandRunner<void> runner = createBuildRunner(
        fs: errorHandlingFileSystem,
        testLogger: _TerminalBufferLogger(),
        osUtils: _PipeOperatingSystemUtils(
          errorHandlingFileSystem,
          initialContents: initialPipeContents,
        ),
      );
      final Directory tempDir = errorHandlingFileSystem.directory(_xcBundleDirectoryPath).parent;
      final File pipeFile = tempDir.childFile('pipe_to_stdout');
      processManager.addCommand(
        setUpFakeXcodeBuildHandler(
          simulator: true,
          exitCode: 1,
          scriptOutputStreamFile: pipeFile.path,
          onRun: (_) {
            expect(pipeFile, exists);
            onXcodeRun(tempDir, pipeFile);
          },
        ),
      );

      createMinimalMockProjectFiles();

      await expectLater(
        runner.run(const <String>['build', 'ios', '--simulator', '--no-pub']),
        throwsToolExit(message: 'Encountered error while building for simulator.'),
      );
      expect(tempDir, isNot(exists));
      expect(pipeFile, isNot(exists));
      expect(processManager.hasRemainingExpectations, isFalse);
    }

    test(
      'Do not crash if temporary build directory is deleted before cleanup in terminal session.',
      () async {
        await runTerminalBuildWithDeletedTempDir(
          onXcodeRun: (Directory tempDir, File pipeFile) {
            tempDir.deleteSync(recursive: true);
          },
        );
      },
    );

    test(
      'Do not crash if temporary build directory is deleted during pipe write in terminal session.',
      () async {
        // POSIX errno for ENOENT (No such file or directory).
        const kEnoent = 2;
        var deleteOnNextPipeWrite = false;
        fileSystem = MemoryFileSystem.test(
          opHandle: (String path, FileSystemOp op) {
            if (deleteOnNextPipeWrite &&
                op == FileSystemOp.write &&
                path.endsWith('pipe_to_stdout')) {
              deleteOnNextPipeWrite = false;
              fileSystem.directory(_xcBundleDirectoryPath).parent.deleteSync(recursive: true);
              throw FileSystemException(
                'Cannot open file',
                path,
                const OSError('No such file or directory', kEnoent),
              );
            }
          },
        );
        await runTerminalBuildWithDeletedTempDir(
          initialPipeContents: 'all done\n',
          onXcodeRun: (Directory tempDir, File pipeFile) {
            deleteOnNextPipeWrite = true;
          },
        );
      },
    );

    test('Do not crash if temporary build directory is deleted between existsSync and reading pipe in terminal session.', () async {
      var deleteOnNextPipeRead = false;
      fileSystem = MemoryFileSystem.test(
        opHandle: (String path, FileSystemOp op) {
          if (deleteOnNextPipeRead &&
              (op == FileSystemOp.open || op == FileSystemOp.read) &&
              path.endsWith('pipe_to_stdout')) {
            deleteOnNextPipeRead = false;
            fileSystem.directory(_xcBundleDirectoryPath).parent.deleteSync(recursive: true);
          }
        },
      );
      await runTerminalBuildWithDeletedTempDir(
        onXcodeRun: (Directory tempDir, File pipeFile) {
          deleteOnNextPipeRead = true;
        },
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

class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils({this.hostPlatform = HostPlatform.linux_x64});

  @override
  HostPlatform hostPlatform = HostPlatform.linux_x64;

  @override
  int? getDirectorySize(Directory directory) => 1024;

  @override
  void chmod(FileSystemEntity file, String mode) {}
}

class _TerminalBufferLogger extends BufferLogger {
  _TerminalBufferLogger() : super.test();

  @override
  bool get hasTerminal => true;
}

class _PipeOperatingSystemUtils extends FakeOperatingSystemUtils {
  _PipeOperatingSystemUtils(this._fileSystem, {this.initialContents = ''});

  final FileSystem _fileSystem;

  /// Defaults to an empty pipe file so the listener keeps re-reading until the
  /// temporary directory is deleted. Pass 'all done\n' when deletion happens
  /// after the build so the listener does not spin on microtasks and starve
  /// FakeProcess timers.
  final String initialContents;

  @override
  File makePipe(String path) => _fileSystem.file(path)..writeAsStringSync(initialContents);
}
