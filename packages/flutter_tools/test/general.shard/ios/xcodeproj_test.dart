// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/xcode_build_settings.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/package_config.dart';

const xcodebuild = '/usr/bin/xcodebuild';

void main() {
  group('MockProcessManager', () {
    setUp(() {
      final FileSystem fileSystem = MemoryFileSystem.test();
      fileSystem.file(xcodebuild).createSync(recursive: true);
    });
  });

  const kWhichSysctlCommand = FakeCommand(command: <String>['which', 'sysctl']);

  // x64 host.
  const kx64CheckCommand = FakeCommand(
    command: <String>['sysctl', 'hw.optional.arm64'],
    exitCode: 1,
  );

  // ARM host.
  const kARMCheckCommand = FakeCommand(
    command: <String>['sysctl', 'hw.optional.arm64'],
    stdout: 'hw.optional.arm64: 1',
  );

  late FakeProcessManager fakeProcessManager;
  late XcodeProjectInterpreter xcodeProjectInterpreter;
  late FakePlatform platform;
  late FileSystem fileSystem;
  late BufferLogger logger;

  setUp(() {
    fakeProcessManager = FakeProcessManager.empty();
    platform = FakePlatform(operatingSystem: 'macos');
    fileSystem = MemoryFileSystem.test();
    fileSystem.file(xcodebuild).createSync(recursive: true);
    logger = BufferLogger.test();
    xcodeProjectInterpreter = XcodeProjectInterpreter(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      processManager: fakeProcessManager,
      analytics: const NoOpAnalytics(),
    );
  });

  testWithoutContext(
    'xcodebuild versionText returns null when xcodebuild is not fully installed',
    () {
      fakeProcessManager.addCommands(const <FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>['xcrun', 'xcodebuild', '-version'],
          stdout:
              "xcode-select: error: tool 'xcodebuild' requires Xcode, "
              "but active developer directory '/Library/Developer/CommandLineTools' "
              'is a command line tools instance',
          exitCode: 1,
        ),
      ]);

      expect(xcodeProjectInterpreter.versionText, isNull);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext('xcodebuild versionText returns null when xcodebuild is not installed', () {
    fakeProcessManager.addCommands(const <FakeCommand>[
      kWhichSysctlCommand,
      kx64CheckCommand,
      FakeCommand(
        command: <String>['xcrun', 'xcodebuild', '-version'],
        exception: ProcessException(xcodebuild, <String>['-version']),
      ),
    ]);

    expect(xcodeProjectInterpreter.versionText, isNull);
  });

  testWithoutContext('xcodebuild versionText returns formatted version text', () {
    fakeProcessManager.addCommands(const <FakeCommand>[
      kWhichSysctlCommand,
      kx64CheckCommand,
      FakeCommand(
        command: <String>['xcrun', 'xcodebuild', '-version'],
        stdout: 'Xcode 8.3.3\nBuild version 8E3004b',
      ),
    ]);

    expect(xcodeProjectInterpreter.versionText, 'Xcode 8.3.3, Build version 8E3004b');
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext(
    'xcodebuild versionText handles Xcode version string with unexpected format',
    () {
      fakeProcessManager.addCommands(const <FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>['xcrun', 'xcodebuild', '-version'],
          stdout: 'Xcode Ultra5000\nBuild version 8E3004b',
        ),
      ]);

      expect(xcodeProjectInterpreter.versionText, 'Xcode Ultra5000, Build version 8E3004b');
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext('xcodebuild version parts can be parsed', () {
    fakeProcessManager.addCommands(const <FakeCommand>[
      kWhichSysctlCommand,
      kx64CheckCommand,
      FakeCommand(
        command: <String>['xcrun', 'xcodebuild', '-version'],
        stdout: 'Xcode 11.4.1\nBuild version 11N111s',
      ),
    ]);

    expect(xcodeProjectInterpreter.version, Version(11, 4, 1));
    expect(xcodeProjectInterpreter.build, '11N111s');
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext('xcodebuild minor and patch version default to 0', () {
    fakeProcessManager.addCommands(const <FakeCommand>[
      kWhichSysctlCommand,
      kx64CheckCommand,
      FakeCommand(
        command: <String>['xcrun', 'xcodebuild', '-version'],
        stdout: 'Xcode 11\nBuild version 11N111s',
      ),
    ]);

    expect(xcodeProjectInterpreter.version, Version(11, 0, 0));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext('xcodebuild version parts is null when version has unexpected format', () {
    fakeProcessManager.addCommands(const <FakeCommand>[
      kWhichSysctlCommand,
      kx64CheckCommand,
      FakeCommand(
        command: <String>['xcrun', 'xcodebuild', '-version'],
        stdout: 'Xcode Ultra5000\nBuild version 8E3004b',
      ),
    ]);
    expect(xcodeProjectInterpreter.version, isNull);
    expect(xcodeProjectInterpreter.build, isNull);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext('xcodebuild isInstalled is false when not on MacOS', () {
    final Platform platform = FakePlatform(operatingSystem: 'notMacOS');
    xcodeProjectInterpreter = XcodeProjectInterpreter(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      processManager: fakeProcessManager,
      analytics: const NoOpAnalytics(),
    );
    fileSystem.file(xcodebuild).deleteSync();

    expect(xcodeProjectInterpreter.isInstalled, isFalse);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext('xcodebuild isInstalled is false when xcodebuild does not exist', () {
    fileSystem.file(xcodebuild).deleteSync();

    expect(xcodeProjectInterpreter.isInstalled, isFalse);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext('xcodebuild isInstalled is false when Xcode is not fully installed', () {
    fakeProcessManager.addCommands(const <FakeCommand>[
      kWhichSysctlCommand,
      kx64CheckCommand,
      FakeCommand(
        command: <String>['xcrun', 'xcodebuild', '-version'],
        stdout:
            "xcode-select: error: tool 'xcodebuild' requires Xcode, "
            "but active developer directory '/Library/Developer/CommandLineTools' "
            'is a command line tools instance',
        exitCode: 1,
      ),
    ]);

    expect(xcodeProjectInterpreter.isInstalled, isFalse);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext('xcodebuild isInstalled is false when version has unexpected format', () {
    fakeProcessManager.addCommands(const <FakeCommand>[
      kWhichSysctlCommand,
      kx64CheckCommand,
      FakeCommand(
        command: <String>['xcrun', 'xcodebuild', '-version'],
        stdout: 'Xcode Ultra5000\nBuild version 8E3004b',
      ),
    ]);

    expect(xcodeProjectInterpreter.isInstalled, isFalse);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext('xcodebuild isInstalled is true when version has expected format', () {
    fakeProcessManager.addCommands(const <FakeCommand>[
      kWhichSysctlCommand,
      kx64CheckCommand,
      FakeCommand(
        command: <String>['xcrun', 'xcodebuild', '-version'],
        stdout: 'Xcode 8.3.3\nBuild version 8E3004b',
      ),
    ]);

    expect(xcodeProjectInterpreter.isInstalled, isTrue);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext('xcrun runs natively on arm64', () {
    fakeProcessManager.addCommands(const <FakeCommand>[kWhichSysctlCommand, kARMCheckCommand]);

    expect(xcodeProjectInterpreter.xcrunCommand(), <String>['/usr/bin/arch', '-arm64e', 'xcrun']);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testUsingContext(
    'xcodebuild build settings is empty when xcodebuild failed to get the build settings',
    () async {
      platform.environment = const <String, String>{};

      fakeProcessManager.addCommands(<FakeCommand>[
        kWhichSysctlCommand,
        const FakeCommand(command: <String>['sysctl', 'hw.optional.arm64'], exitCode: 1),
        FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-project',
            '/',
            '-scheme',
            'Free',
            '-destination',
            'id=123',
            '-showBuildSettings',
            'BUILD_DIR=${fileSystem.path.absolute('build', 'ios')}',
          ],
          exitCode: 1,
        ),
      ]);

      expect(
        await xcodeProjectInterpreter.getBuildSettings(
          '',
          buildContext: const XcodeProjectBuildContext(deviceId: '123', scheme: 'Free'),
        ),
        const <String, String>{},
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'build settings passes in the simulator SDK',
    () async {
      platform.environment = const <String, String>{};

      fakeProcessManager.addCommands(<FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-project',
            '/',
            '-sdk',
            'iphonesimulator',
            '-destination',
            'generic/platform=iOS Simulator',
            '-showBuildSettings',
            'BUILD_DIR=${fileSystem.path.absolute('build', 'ios')}',
          ],
          exitCode: 1,
        ),
      ]);

      expect(
        await xcodeProjectInterpreter.getBuildSettings(
          '',
          buildContext: const XcodeProjectBuildContext(sdk: XcodeSdk.IPhoneSimulator),
        ),
        const <String, String>{},
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'build settings accepts an empty scheme',
    () async {
      platform.environment = const <String, String>{};

      fakeProcessManager.addCommands(<FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-project',
            '/',
            '-destination',
            'generic/platform=iOS',
            '-showBuildSettings',
            'BUILD_DIR=${fileSystem.path.absolute('build', 'ios')}',
          ],
          exitCode: 1,
        ),
      ]);

      expect(
        await xcodeProjectInterpreter.getBuildSettings(
          '',
          buildContext: const XcodeProjectBuildContext(),
        ),
        const <String, String>{},
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'xcodebuild build settings contains Flutter Xcode environment variables',
    () async {
      platform.environment = const <String, String>{
        'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Manual',
        'FLUTTER_XCODE_ARCHS': 'arm64',
      };
      fakeProcessManager.addCommands(<FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-project',
            fileSystem.path.separator,
            '-scheme',
            'Free',
            '-destination',
            'generic/platform=iOS',
            '-showBuildSettings',
            'BUILD_DIR=${fileSystem.path.absolute('build', 'ios')}',
            'CODE_SIGN_STYLE=Manual',
            'ARCHS=arm64',
          ],
        ),
      ]);
      expect(
        await xcodeProjectInterpreter.getBuildSettings(
          '',
          buildContext: const XcodeProjectBuildContext(scheme: 'Free'),
        ),
        const <String, String>{},
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'build settings uses watch destination',
    () async {
      platform.environment = const <String, String>{};

      fakeProcessManager.addCommands(<FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-project',
            '/',
            '-destination',
            'generic/platform=watchOS',
            '-showBuildSettings',
            'BUILD_DIR=${fileSystem.path.absolute('build', 'ios')}',
          ],
          exitCode: 1,
        ),
      ]);

      expect(
        await xcodeProjectInterpreter.getBuildSettings(
          '',
          buildContext: const XcodeProjectBuildContext(sdk: XcodeSdk.WatchOS),
        ),
        const <String, String>{},
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'build settings uses watch simulator destination',
    () async {
      platform.environment = const <String, String>{};

      fakeProcessManager.addCommands(<FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-project',
            '/',
            '-destination',
            'generic/platform=watchOS Simulator',
            '-showBuildSettings',
            'BUILD_DIR=${fileSystem.path.absolute('build', 'ios')}',
          ],
          exitCode: 1,
        ),
      ]);

      expect(
        await xcodeProjectInterpreter.getBuildSettings(
          '',
          buildContext: const XcodeProjectBuildContext(sdk: XcodeSdk.WatchSimulator),
        ),
        const <String, String>{},
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'build settings uses macosx destination',
    () async {
      platform.environment = const <String, String>{};

      fakeProcessManager.addCommands(<FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-project',
            '/',
            '-destination',
            'generic/platform=macOS',
            '-showBuildSettings',
            'BUILD_DIR=${fileSystem.path.absolute('build', 'macos')}',
          ],
          exitCode: 1,
        ),
      ]);

      expect(
        await xcodeProjectInterpreter.getBuildSettings(
          '',
          buildContext: const XcodeProjectBuildContext(sdk: XcodeSdk.MacOSX),
        ),
        const <String, String>{},
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testWithoutContext('xcodebuild clean contains Flutter Xcode environment variables', () async {
    platform.environment = const <String, String>{
      'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Manual',
      'FLUTTER_XCODE_ARCHS': 'arm64',
    };

    fakeProcessManager.addCommands(const <FakeCommand>[
      kWhichSysctlCommand,
      kx64CheckCommand,
      FakeCommand(
        command: <String>[
          'xcrun',
          'xcodebuild',
          '-workspace',
          'workspace_path',
          '-scheme',
          'Free',
          '-quiet',
          'clean',
          'CODE_SIGN_STYLE=Manual',
          'ARCHS=arm64',
        ],
      ),
    ]);

    await xcodeProjectInterpreter.cleanWorkspace('workspace_path', 'Free');
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testWithoutContext(
    'xcodebuild -list getInfo returns something when xcodebuild -list succeeds',
    () async {
      const workingDirectory = '/';
      fakeProcessManager.addCommands(const <FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(command: <String>['xcrun', 'xcodebuild', '-list']),
      ]);

      final xcodeProjectInterpreter = XcodeProjectInterpreter(
        logger: logger,
        fileSystem: fileSystem,
        platform: platform,
        processManager: fakeProcessManager,
        analytics: const NoOpAnalytics(),
      );

      expect(await xcodeProjectInterpreter.getInfo(workingDirectory), isNotNull);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext(
    'xcodebuild -list getInfo throws a tool exit when it is unable to find a project',
    () async {
      const workingDirectory = '/';
      const stderr = 'Useful Xcode failure message about missing project.';

      fakeProcessManager.addCommands(const <FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>['xcrun', 'xcodebuild', '-list'],
          exitCode: 66,
          stderr: stderr,
        ),
      ]);

      final xcodeProjectInterpreter = XcodeProjectInterpreter(
        logger: logger,
        fileSystem: fileSystem,
        platform: platform,
        processManager: fakeProcessManager,
        analytics: const NoOpAnalytics(),
      );

      expect(
        () => xcodeProjectInterpreter.getInfo(workingDirectory),
        throwsToolExit(message: stderr),
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext(
    'xcodebuild -list getInfo throws a tool exit when project is corrupted',
    () async {
      const workingDirectory = '/';
      const stderr = 'Useful Xcode failure message about corrupted project.';

      fakeProcessManager.addCommands(const <FakeCommand>[
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>['xcrun', 'xcodebuild', '-list'],
          exitCode: 74,
          stderr: stderr,
        ),
      ]);

      final xcodeProjectInterpreter = XcodeProjectInterpreter(
        logger: logger,
        fileSystem: fileSystem,
        platform: platform,
        processManager: fakeProcessManager,
        analytics: const NoOpAnalytics(),
      );

      expect(
        () => xcodeProjectInterpreter.getInfo(workingDirectory),
        throwsToolExit(message: stderr),
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext('Xcode project properties from default project can be parsed', () {
    const output = '''
Information about project "Runner":
    Targets:
        Runner

    Build Configurations:
        Debug
        Release

    If no build configuration is specified and -scheme is not passed then "Release" is used.

    Schemes:
        Runner

''';
    final info = XcodeProjectInfo.fromXcodeBuildOutput(output, logger);
    expect(info.targets, <String>['Runner']);
    expect(info.schemes, <String>['Runner']);
    expect(info.buildConfigurations, <String>['Debug', 'Release']);
  });

  testWithoutContext('Xcode project properties from project with custom schemes can be parsed', () {
    const output = '''
Information about project "Runner":
    Targets:
        Runner

    Build Configurations:
        Debug (Free)
        Debug (Paid)
        Release (Free)
        Release (Paid)

    If no build configuration is specified and -scheme is not passed then "Release (Free)" is used.

    Schemes:
        Free
        Paid

''';
    final info = XcodeProjectInfo.fromXcodeBuildOutput(output, logger);
    expect(info.targets, <String>['Runner']);
    expect(info.schemes, <String>['Free', 'Paid']);
    expect(info.buildConfigurations, <String>[
      'Debug (Free)',
      'Debug (Paid)',
      'Release (Free)',
      'Release (Paid)',
    ]);
  });

  testWithoutContext('expected scheme for non-flavored build is Runner', () {
    expect(XcodeProjectInfo.expectedSchemeFor(BuildInfo.debug), 'Runner');
    expect(XcodeProjectInfo.expectedSchemeFor(BuildInfo.profile), 'Runner');
    expect(XcodeProjectInfo.expectedSchemeFor(BuildInfo.release), 'Runner');
  });

  testWithoutContext(
    'expected build configuration for non-flavored build is derived from BuildMode',
    () {
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.debug, 'Runner'), 'Debug');
      expect(
        XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.profile, 'Runner'),
        'Profile',
      );
      expect(
        XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.release, 'Runner'),
        'Release',
      );
    },
  );

  testWithoutContext('expected scheme for flavored build is the title-cased flavor', () {
    expect(
      XcodeProjectInfo.expectedSchemeFor(
        const BuildInfo(
          BuildMode.debug,
          'hello',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      'Hello',
    );
    expect(
      XcodeProjectInfo.expectedSchemeFor(
        const BuildInfo(
          BuildMode.profile,
          'HELLO',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      'HELLO',
    );
    expect(
      XcodeProjectInfo.expectedSchemeFor(
        const BuildInfo(
          BuildMode.release,
          'Hello',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      'Hello',
    );
  });

  testWithoutContext('expected build configuration for flavored build is Mode-Flavor', () {
    expect(
      XcodeProjectInfo.expectedBuildConfigurationFor(
        const BuildInfo(
          BuildMode.debug,
          'hello',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        'Hello',
      ),
      'Debug-Hello',
    );
    expect(
      XcodeProjectInfo.expectedBuildConfigurationFor(
        const BuildInfo(
          BuildMode.profile,
          'HELLO',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        'Hello',
      ),
      'Profile-Hello',
    );
    expect(
      XcodeProjectInfo.expectedBuildConfigurationFor(
        const BuildInfo(
          BuildMode.release,
          'Hello',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        'Hello',
      ),
      'Release-Hello',
    );
  });

  testWithoutContext('scheme for default project is Runner', () {
    final info = XcodeProjectInfo(<String>['Runner'], <String>['Debug', 'Release'], <String>[
      'Runner',
    ], logger);

    expect(info.schemeFor(BuildInfo.debug), 'Runner');
    expect(info.schemeFor(BuildInfo.profile), 'Runner');
    expect(info.schemeFor(BuildInfo.release), 'Runner');
    expect(
      info.schemeFor(
        const BuildInfo(
          BuildMode.debug,
          'unknown',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      isNull,
    );
  });

  testWithoutContext('build configuration for default project is matched against BuildMode', () {
    final info = XcodeProjectInfo(
      <String>['Runner'],
      <String>['Debug', 'Profile', 'Release'],
      <String>['Runner'],
      logger,
    );

    expect(info.buildConfigurationFor(BuildInfo.debug, 'Runner'), 'Debug');
    expect(info.buildConfigurationFor(BuildInfo.profile, 'Runner'), 'Profile');
    expect(info.buildConfigurationFor(BuildInfo.release, 'Runner'), 'Release');
  });

  testWithoutContext('scheme for project with custom schemes is matched against flavor', () {
    final info = XcodeProjectInfo(
      <String>['Runner'],
      <String>['Debug (Free)', 'Debug (Paid)', 'Release (Free)', 'Release (Paid)'],
      <String>['Free', 'Paid'],
      logger,
    );

    expect(
      info.schemeFor(
        const BuildInfo(
          BuildMode.debug,
          'free',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      'Free',
    );
    expect(
      info.schemeFor(
        const BuildInfo(
          BuildMode.profile,
          'Free',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      'Free',
    );
    expect(
      info.schemeFor(
        const BuildInfo(
          BuildMode.release,
          'paid',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      'Paid',
    );
    expect(info.schemeFor(BuildInfo.debug), isNull);
    expect(
      info.schemeFor(
        const BuildInfo(
          BuildMode.debug,
          'unknown',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      isNull,
    );
  });

  testWithoutContext('reports default scheme error and exit', () {
    final defaultInfo = XcodeProjectInfo(<String>[], <String>[], <String>['Runner'], logger);

    expect(
      defaultInfo.reportFlavorNotFoundAndExit,
      throwsToolExit(
        message:
            'The Xcode project does not define custom schemes. You cannot use the --flavor option.',
      ),
    );
  });

  testWithoutContext('reports custom scheme error and exit', () {
    final info = XcodeProjectInfo(<String>[], <String>[], <String>['Free', 'Paid'], logger);

    expect(
      info.reportFlavorNotFoundAndExit,
      throwsToolExit(
        message: 'You must specify a --flavor option to select one of the available schemes.',
      ),
    );
  });

  testWithoutContext(
    'build configuration for project with custom schemes is matched against BuildMode and flavor',
    () {
      final info = XcodeProjectInfo(
        <String>['Runner'],
        <String>[
          'debug (free)',
          'Debug paid',
          'debug (premium)',
          'profile - Free',
          'Profile-Paid',
          'Profile-Premium',
          'release - Free',
          'Release-Paid',
          'release-premium',
        ],
        <String>['Free', 'Paid', 'premium'],
        logger,
      );

      expect(
        info.buildConfigurationFor(
          const BuildInfo(
            BuildMode.debug,
            'free',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          'Free',
        ),
        'debug (free)',
      );
      expect(
        info.buildConfigurationFor(
          const BuildInfo(
            BuildMode.debug,
            'Paid',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          'Paid',
        ),
        'Debug paid',
      );
      expect(
        info.buildConfigurationFor(
          const BuildInfo(
            BuildMode.debug,
            'premium',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          'premium',
        ),
        'debug (premium)',
      );
      expect(
        info.buildConfigurationFor(
          const BuildInfo(
            BuildMode.debug,
            'premium',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          'Premium',
        ),
        'debug (premium)',
      );
      expect(
        info.buildConfigurationFor(
          const BuildInfo(
            BuildMode.profile,
            'FREE',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          'Free',
        ),
        'profile - Free',
      );
      expect(
        info.buildConfigurationFor(
          const BuildInfo(
            BuildMode.profile,
            'paid',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          'paid',
        ),
        'Profile-Paid',
      );
      expect(
        info.buildConfigurationFor(
          const BuildInfo(
            BuildMode.profile,
            'premium',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          'Premium',
        ),
        'Profile-Premium',
      );
      expect(
        info.buildConfigurationFor(
          const BuildInfo(
            BuildMode.release,
            'paid',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          'Paid',
        ),
        'Release-Paid',
      );
      expect(
        info.buildConfigurationFor(
          const BuildInfo(
            BuildMode.release,
            'PREMIUM',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          'PREMIUM',
        ),
        'release-premium',
      );
    },
  );

  testWithoutContext('build configuration for project with inconsistent naming is null', () {
    final info = XcodeProjectInfo(
      <String>['Runner'],
      <String>['Debug-F', 'Dbg Paid', 'Rel Free', 'Release Full'],
      <String>['Free', 'Paid'],
      logger,
    );
    expect(
      info.buildConfigurationFor(
        const BuildInfo(
          BuildMode.debug,
          'Free',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        'Free',
      ),
      null,
    );
    expect(
      info.buildConfigurationFor(
        const BuildInfo(
          BuildMode.profile,
          'Free',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        'Free',
      ),
      null,
    );
    expect(
      info.buildConfigurationFor(
        const BuildInfo(
          BuildMode.release,
          'Paid',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        'Paid',
      ),
      null,
    );
  });
  group('environmentVariablesAsXcodeBuildSettings', () {
    late FakePlatform platform;

    setUp(() {
      platform = FakePlatform();
    });

    testWithoutContext('environment variables as Xcode build settings', () {
      platform.environment = const <String, String>{
        'Ignored': 'Bogus',
        'FLUTTER_NOT_XCODE': 'Bogus',
        'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Manual',
        'FLUTTER_XCODE_ARCHS': 'arm64',
      };
      final List<String> environmentVariablesAsBuildSettings =
          environmentVariablesAsXcodeBuildSettings(platform);
      expect(environmentVariablesAsBuildSettings, <String>[
        'CODE_SIGN_STYLE=Manual',
        'ARCHS=arm64',
      ]);
    });
  });

  group('updateGeneratedXcodeProperties', () {
    late Artifacts localIosArtifacts;
    late FakePlatform macOS;
    late FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
      localIosArtifacts = Artifacts.testLocalEngine(
        localEngine: 'out/ios_profile_arm64',
        localEngineHost: 'out/host_release',
      );
      macOS = FakePlatform(operatingSystem: 'macos');
      fs.file(xcodebuild).createSync(recursive: true);
    });

    group('arm simulator architecture check', () {
      late FakeProcessManager fakeProcessManager;
      late XcodeProjectInterpreter xcodeProjectInterpreter;
      late Xcode xcode;

      setUp(() {
        fakeProcessManager = FakeProcessManager.empty();
        xcodeProjectInterpreter = XcodeProjectInterpreter.test(
          processManager: fakeProcessManager,
          version: Version(26, 0, 0),
        );
        xcode = Xcode.test(
          processManager: fakeProcessManager,
          xcodeProjectInterpreter: xcodeProjectInterpreter,
        );
      });

      void createFakePlugins(
        FlutterProject flutterProject,
        FileSystem fileSystem,
        List<String> pluginNames,
      ) {
        const pluginYamlTemplate = '''
  flutter:
    plugin:
      platforms:
        ios:
          pluginClass: PLUGIN_CLASS
        macos:
          pluginClass: PLUGIN_CLASS
  ''';

        final Directory fakePubCache = fileSystem.systemTempDirectory.childDirectory(
          'fake_pub_cache',
        );

        writePackageConfigFiles(
          directory: flutterProject.directory,
          mainLibName: 'my_app',
          packages: <String, String>{
            for (final String name in pluginNames) name: fakePubCache.childDirectory(name).path,
          },
        );

        for (final name in pluginNames) {
          final Directory pluginDirectory = fakePubCache.childDirectory(name);
          pluginDirectory.childFile('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync(pluginYamlTemplate.replaceAll('PLUGIN_CLASS', name));
        }

        final File graph = flutterProject.dartTool.childFile('package_graph.json')
          ..createSync(recursive: true);

        final packages = <Map<String, Object>>[
          <String, Object>{
            'name': 'my_app',
            'dependencies': pluginNames,
            'devDependencies': <String>[],
          },
          for (final String name in pluginNames)
            <String, Object>{
              'name': name,
              'dependencies': <String>[],
              'devDependencies': <String>[],
            },
        ];

        graph.writeAsStringSync(
          jsonEncode(<String, Object>{'configVersion': 1, 'packages': packages}),
        );
      }

      testUsingContext(
        'prints Warning when a plugin excludes arm64 on Xcode 26+',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;

          final Directory projectDir = fs.directory('path/to/project')..createSync(recursive: true);
          projectDir.childFile('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('name: my_app\n');

          final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir);

          final Directory podXcodeProject =
              project.ios.hostAppRoot.childDirectory('Pods').childDirectory('Pods.xcodeproj')
                ..createSync(recursive: true);
          project.ios.podManifestLock.createSync(recursive: true);

          createFakePlugins(project, fs, <String>['bad_plugin', 'good_plugin']);

          final String buildDirectory = fs.path.absolute('build', 'ios');

          fakeProcessManager.addCommands(<FakeCommand>[
            kWhichSysctlCommand,
            kARMCheckCommand,
            FakeCommand(
              command: <String>[
                '/usr/bin/arch',
                '-arm64e',
                'xcrun',
                'xcodebuild',
                '-alltargets',
                '-sdk',
                'iphonesimulator',
                '-project',
                podXcodeProject.path,
                '-showBuildSettings',
                'BUILD_DIR=$buildDirectory',
                'OBJROOT=$buildDirectory',
              ],
              stdout: '''
Build settings for action build and target bad_plugin:
    EXCLUDED_ARCHS = i386 arm64

Build settings for action build and target good_plugin:
    EXCLUDED_ARCHS = i386
''',
            ),
          ]);

          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          expect(
            logger.warningText,
            contains(
              'The following plugin(s) are excluding the arm64 architecture, which is a requirement for Xcode 26+',
            ),
          );
          expect(logger.warningText, contains('bad_plugin'));
          expect(fakeProcessManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => fakeProcessManager,
          XcodeProjectInterpreter: () => xcodeProjectInterpreter,
          Xcode: () => xcode,
          Logger: () => logger,
        },
      );
      testUsingContext(
        'succeeds when no plugins exclude arm64 on Xcode 26+',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;

          final Directory projectDir = fs.directory('path/to/project')..createSync(recursive: true);
          projectDir.childFile('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('name: my_app\n');

          final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir);

          final Directory podXcodeProject =
              project.ios.hostAppRoot.childDirectory('Pods').childDirectory('Pods.xcodeproj')
                ..createSync(recursive: true);
          project.ios.podManifestLock.createSync(recursive: true);
          createFakePlugins(project, fs, <String>['good_plugin']);
          final String buildDirectory = fs.path.absolute('build', 'ios');

          fakeProcessManager.addCommands(<FakeCommand>[
            kWhichSysctlCommand,
            kARMCheckCommand,
            FakeCommand(
              command: <String>[
                '/usr/bin/arch',
                '-arm64e',
                'xcrun',
                'xcodebuild',
                '-alltargets',
                '-sdk',
                'iphonesimulator',
                '-project',
                podXcodeProject.path,
                '-showBuildSettings',
                'BUILD_DIR=$buildDirectory',
                'OBJROOT=$buildDirectory',
              ],
              stdout: '''
Build settings for action build and target good_plugin:
    EXCLUDED_ARCHS = i386
''',
            ),
          ]);

          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
          expect(config.readAsStringSync(), contains('EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386'));
          expect(config.readAsStringSync(), contains('EXCLUDED_ARCHS[sdk=iphoneos*]=armv7'));
          expect(fakeProcessManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => fakeProcessManager,
          XcodeProjectInterpreter: () => xcodeProjectInterpreter,
          Xcode: () => xcode,
        },
      );

      testUsingContext(
        'does not warn when EXCLUDED_ARCHS contains arm64e (not arm64)',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;

          final Directory projectDir = fs.directory('path/to/project')..createSync(recursive: true);
          projectDir.childFile('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('name: my_app\n');

          final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir);

          final Directory podXcodeProject =
              project.ios.hostAppRoot.childDirectory('Pods').childDirectory('Pods.xcodeproj')
                ..createSync(recursive: true);
          project.ios.podManifestLock.createSync(recursive: true);

          createFakePlugins(project, fs, <String>['good_plugin']);

          final String buildDirectory = fs.path.absolute('build', 'ios');
          final testLogger = BufferLogger.test();

          fakeProcessManager.addCommands(<FakeCommand>[
            kWhichSysctlCommand,
            kARMCheckCommand,
            FakeCommand(
              command: <String>[
                '/usr/bin/arch',
                '-arm64e',
                'xcrun',
                'xcodebuild',
                '-alltargets',
                '-sdk',
                'iphonesimulator',
                '-project',
                podXcodeProject.path,
                '-showBuildSettings',
                'BUILD_DIR=$buildDirectory',
                'OBJROOT=$buildDirectory',
              ],
              stdout: '''
Build settings for action build and target good_plugin:
    EXCLUDED_ARCHS[sdk=iphonesimulator*] = i386 arm64e
''',
            ),
          ]);

          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          expect(testLogger.warningText, isEmpty);
          expect(fakeProcessManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => fakeProcessManager,
          XcodeProjectInterpreter: () => xcodeProjectInterpreter,
          Xcode: () => xcode,
          Logger: () => BufferLogger.test(),
        },
      );

      testUsingContext(
        'warns when bracketed EXCLUDED_ARCHS contains arm64',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;

          final Directory projectDir = fs.directory('path/to/project')..createSync(recursive: true);
          projectDir.childFile('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('name: my_app\n');

          final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir);

          final Directory podXcodeProject =
              project.ios.hostAppRoot.childDirectory('Pods').childDirectory('Pods.xcodeproj')
                ..createSync(recursive: true);
          project.ios.podManifestLock.createSync(recursive: true);

          createFakePlugins(project, fs, <String>['bad_plugin']);

          final String buildDirectory = fs.path.absolute('build', 'ios');

          fakeProcessManager.addCommands(<FakeCommand>[
            kWhichSysctlCommand,
            kARMCheckCommand,
            FakeCommand(
              command: <String>[
                '/usr/bin/arch',
                '-arm64e',
                'xcrun',
                'xcodebuild',
                '-alltargets',
                '-sdk',
                'iphonesimulator',
                '-project',
                podXcodeProject.path,
                '-showBuildSettings',
                'BUILD_DIR=$buildDirectory',
                'OBJROOT=$buildDirectory',
              ],
              stdout: '''
Build settings for action build and target bad_plugin:
    EXCLUDED_ARCHS[sdk=iphonesimulator*] = i386 arm64
''',
            ),
          ]);

          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          expect(
            logger.warningText,
            contains(
              'The following plugin(s) are excluding the arm64 architecture, which is a requirement for Xcode 26+',
            ),
          );
          expect(logger.warningText, contains('bad_plugin'));
          expect(fakeProcessManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => fakeProcessManager,
          XcodeProjectInterpreter: () => xcodeProjectInterpreter,
          Xcode: () => xcode,
          Logger: () => logger,
        },
      );

      testUsingContext(
        'ignores non-plugin targets that exclude arm64',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;

          final Directory projectDir = fs.directory('path/to/project')..createSync(recursive: true);
          projectDir.childFile('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('name: my_app\n');

          final FlutterProject project = FlutterProject.fromDirectoryTest(projectDir);

          final Directory podXcodeProject =
              project.ios.hostAppRoot.childDirectory('Pods').childDirectory('Pods.xcodeproj')
                ..createSync(recursive: true);
          project.ios.podManifestLock.createSync(recursive: true);

          createFakePlugins(project, fs, <String>['good_plugin']);

          final String buildDirectory = fs.path.absolute('build', 'ios');
          final testLogger = BufferLogger.test();

          fakeProcessManager.addCommands(<FakeCommand>[
            kWhichSysctlCommand,
            kARMCheckCommand,
            FakeCommand(
              command: <String>[
                '/usr/bin/arch',
                '-arm64e',
                'xcrun',
                'xcodebuild',
                '-alltargets',
                '-sdk',
                'iphonesimulator',
                '-project',
                podXcodeProject.path,
                '-showBuildSettings',
                'BUILD_DIR=$buildDirectory',
                'OBJROOT=$buildDirectory',
              ],
              stdout: '''
Build settings for action build and target SomeNonPluginTarget:
    EXCLUDED_ARCHS = arm64

Build settings for action build and target good_plugin:
    EXCLUDED_ARCHS = i386
''',
            ),
          ]);

          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          expect(testLogger.warningText, isEmpty);
          expect(fakeProcessManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => fakeProcessManager,
          XcodeProjectInterpreter: () => xcodeProjectInterpreter,
          Xcode: () => xcode,
          Logger: () => BufferLogger.test(),
        },
      );

      testUsingContext(
        'succeeds and skips check on Xcode 16 even if a plugin excludes arm64',
        () async {
          xcodeProjectInterpreter = XcodeProjectInterpreter.test(
            processManager: fakeProcessManager,
            version: Version(16, 0, 0),
          );
          xcode = Xcode.test(
            processManager: fakeProcessManager,
            xcodeProjectInterpreter: xcodeProjectInterpreter,
          );

          const BuildInfo buildInfo = BuildInfo.debug;
          final FlutterProject project = FlutterProject.fromDirectoryTest(
            fs.directory('path/to/project'),
          );
          project.ios.hostAppRoot
              .childDirectory('Pods')
              .childDirectory('Pods.xcodeproj')
              .createSync(recursive: true);

          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
          expect(config.readAsStringSync(), contains('EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386'));
          expect(config.readAsStringSync(), contains('EXCLUDED_ARCHS[sdk=iphoneos*]=armv7'));
          expect(fakeProcessManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => fakeProcessManager,
          XcodeProjectInterpreter: () => xcodeProjectInterpreter,
          Xcode: () => xcode,
        },
      );
    });

    void testUsingOsxContext(String description, dynamic Function() testMethod) {
      testUsingContext(
        description,
        testMethod,
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    }

    testUsingOsxContext('exits when armv7 local engine is set', () async {
      localIosArtifacts = Artifacts.testLocalEngine(
        localEngine: 'out/ios_profile_arm',
        localEngineHost: 'out/host_release',
      );
      const BuildInfo buildInfo = BuildInfo.debug;
      final FlutterProject project = FlutterProject.fromDirectoryTest(
        fs.directory('path/to/project'),
      );
      await expectLater(
        () => updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo),
        throwsToolExit(message: '32-bit iOS local engine binaries are not supported.'),
      );
    });

    testUsingContext(
      'sets ARCHS=arm64 when arm64 local host engine is set',
      () async {
        const BuildInfo buildInfo = BuildInfo.debug;
        final FlutterProject project = FlutterProject.fromDirectoryTest(
          fs.directory('path/to/project'),
        );
        await updateGeneratedXcodeProperties(
          project: project,
          buildInfo: buildInfo,

          useMacOSConfig: true,
        );

        final File config = fs.file(
          'path/to/project/macos/Flutter/ephemeral/Flutter-Generated.xcconfig',
        );
        expect(config.existsSync(), isTrue);

        final String contents = config.readAsStringSync();
        expect(contents.contains('ARCHS=arm64\n'), isTrue);

        final File buildPhaseScript = fs.file(
          'path/to/project/macos/Flutter/ephemeral/flutter_export_environment.sh',
        );
        expect(buildPhaseScript.existsSync(), isTrue);

        final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
        expect(buildPhaseScriptContents.contains('export "ARCHS=arm64"'), isTrue);
      },
      overrides: <Type, Generator>{
        Artifacts: () => Artifacts.testLocalEngine(
          localEngine: 'out/host_profile_arm64',
          localEngineHost: 'out/host_release',
        ),
        Platform: () => macOS,
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'sets ARCHS=x86_64 when x64 local host engine is set',
      () async {
        const BuildInfo buildInfo = BuildInfo.debug;
        final FlutterProject project = FlutterProject.fromDirectoryTest(
          fs.directory('path/to/project'),
        );
        await updateGeneratedXcodeProperties(
          project: project,
          buildInfo: buildInfo,

          useMacOSConfig: true,
        );

        final File config = fs.file(
          'path/to/project/macos/Flutter/ephemeral/Flutter-Generated.xcconfig',
        );
        expect(config.existsSync(), isTrue);

        final String contents = config.readAsStringSync();
        expect(contents.contains('ARCHS=x86_64\n'), isTrue);

        final File buildPhaseScript = fs.file(
          'path/to/project/macos/Flutter/ephemeral/flutter_export_environment.sh',
        );
        expect(buildPhaseScript.existsSync(), isTrue);

        final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
        expect(buildPhaseScriptContents.contains('export "ARCHS=x86_64"'), isTrue);
      },
      overrides: <Type, Generator>{
        Artifacts: () => Artifacts.testLocalEngine(
          localEngine: 'out/host_profile',
          localEngineHost: 'out/host_release',
        ),
        Platform: () => macOS,
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingOsxContext('does not exclude arm64 simulator when there are no plugins', () async {
      const BuildInfo buildInfo = BuildInfo.debug;
      final FlutterProject project = FlutterProject.fromDirectoryTest(
        fs.directory('path/to/project'),
      );
      await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.readAsStringSync(), contains('EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386\n'));
      expect(config.readAsStringSync(), contains('EXCLUDED_ARCHS[sdk=iphoneos*]=armv7\n'));

      final File buildPhaseScript = fs.file(
        'path/to/project/ios/Flutter/flutter_export_environment.sh',
      );
      expect(buildPhaseScript.readAsStringSync(), isNot(contains('EXCLUDED_ARCHS')));
    });

    testUsingOsxContext(
      'sets TRACK_WIDGET_CREATION=true when trackWidgetCreation is true',
      () async {
        const BuildInfo buildInfo = BuildInfo.debug;
        final FlutterProject project = FlutterProject.fromDirectoryTest(
          fs.directory('path/to/project'),
        );
        await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

        final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
        expect(config.existsSync(), isTrue);

        final String contents = config.readAsStringSync();
        expect(contents.contains('TRACK_WIDGET_CREATION=true'), isTrue);

        final File buildPhaseScript = fs.file(
          'path/to/project/ios/Flutter/flutter_export_environment.sh',
        );
        expect(buildPhaseScript.existsSync(), isTrue);

        final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
        expect(buildPhaseScriptContents.contains('TRACK_WIDGET_CREATION=true'), isTrue);
      },
    );

    testUsingOsxContext(
      'does not set TRACK_WIDGET_CREATION when trackWidgetCreation is false',
      () async {
        const buildInfo = BuildInfo(
          BuildMode.debug,
          null,
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        );
        final FlutterProject project = FlutterProject.fromDirectoryTest(
          fs.directory('path/to/project'),
        );
        await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

        final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
        expect(config.existsSync(), isTrue);

        final String contents = config.readAsStringSync();
        expect(contents.contains('TRACK_WIDGET_CREATION=true'), isFalse);

        final File buildPhaseScript = fs.file(
          'path/to/project/ios/Flutter/flutter_export_environment.sh',
        );
        expect(buildPhaseScript.existsSync(), isTrue);

        final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
        expect(buildPhaseScriptContents.contains('TRACK_WIDGET_CREATION=true'), isFalse);
      },
    );

    group('sim local engine', () {
      testUsingContext(
        'sets ARCHS=x86_64 when x86 sim local engine is set',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;
          final FlutterProject project = FlutterProject.fromDirectoryTest(
            fs.directory('path/to/project'),
          );
          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
          expect(config.existsSync(), isTrue);

          final String contents = config.readAsStringSync();
          expect(contents.contains('ARCHS=x86_64'), isTrue);

          final File buildPhaseScript = fs.file(
            'path/to/project/ios/Flutter/flutter_export_environment.sh',
          );
          expect(buildPhaseScript.existsSync(), isTrue);

          final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
          expect(buildPhaseScriptContents.contains('ARCHS=x86_64'), isTrue);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.testLocalEngine(
            localEngine: 'out/ios_debug_sim_unopt',
            localEngineHost: 'out/host_debug_unopt',
          ),
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );

      testUsingContext(
        'sets ARCHS=arm64 when arm64 sim local engine is set',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;
          final FlutterProject project = FlutterProject.fromDirectoryTest(
            fs.directory('path/to/project'),
          );
          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
          expect(config.existsSync(), isTrue);

          final String contents = config.readAsStringSync();
          expect(contents.contains('ARCHS=arm64'), isTrue);

          final File buildPhaseScript = fs.file(
            'path/to/project/ios/Flutter/flutter_export_environment.sh',
          );
          expect(buildPhaseScript.existsSync(), isTrue);

          final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
          expect(buildPhaseScriptContents.contains('ARCHS=arm64'), isTrue);
        },
        overrides: <Type, Generator>{
          Artifacts: () => Artifacts.testLocalEngine(
            localEngine: 'out/ios_debug_sim_arm64',
            localEngineHost: 'out/host_debug_unopt',
          ),
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    });

    String? propertyFor(String key, File file) {
      final List<String> properties = file
          .readAsLinesSync()
          .where((String line) => line.startsWith('$key='))
          .map((String line) => line.split('=')[1])
          .toList();
      return properties.isEmpty ? null : properties.first;
    }

    Future<void> checkBuildVersion({
      required String manifestString,
      required BuildInfo buildInfo,
      String? expectedBuildName,
      String? expectedBuildNumber,
    }) async {
      final File manifestFile = fs.file('path/to/project/pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifestString);

      await updateGeneratedXcodeProperties(
        project: FlutterProject.fromDirectoryTest(fs.directory('path/to/project')),
        buildInfo: buildInfo,
      );

      final File localPropertiesFile = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(propertyFor('FLUTTER_BUILD_NAME', localPropertiesFile), expectedBuildName);
      expect(propertyFor('FLUTTER_BUILD_NUMBER', localPropertiesFile), expectedBuildNumber);
      expect(propertyFor('FLUTTER_BUILD_NUMBER', localPropertiesFile), isNotNull);
    }

    testUsingOsxContext('extract build name and number from pubspec.yaml', () async {
      const manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';

      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1',
      );
    });

    testUsingOsxContext('extract build name from pubspec.yaml', () async {
      const manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1.0.0',
      );
    });

    testUsingOsxContext('allow build info to override build name', () async {
      const manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildName: '1.0.2',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '1',
      );
    });

    testUsingOsxContext(
      'allow build info to override build name with build number fallback',
      () async {
        const manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
        const buildInfo = BuildInfo(
          BuildMode.release,
          null,
          buildName: '1.0.2',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        );
        await checkBuildVersion(
          manifestString: manifest,
          buildInfo: buildInfo,
          expectedBuildName: '1.0.2',
          expectedBuildNumber: '1.0.2',
        );
      },
    );

    testUsingOsxContext('allow build info to override build number', () async {
      const manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildNumber: '3',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('allow build info to override build name and number', () async {
      const manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildName: '1.0.2',
        buildNumber: '3',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('allow build info to override build name and set number', () async {
      const manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildName: '1.0.2',
        buildNumber: '3',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('allow build info to set build name and number', () async {
      const manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildName: '1.0.2',
        buildNumber: '3',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('default build name and number when version is missing', () async {
      const manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1',
      );
    });

    group('CoreDevice', () {
      late FakeProcessManager fakeProcessManager;
      late XcodeProjectInterpreter xcodeProjectInterpreter;
      late Xcode xcode;

      setUp(() {
        fakeProcessManager = FakeProcessManager.empty();
        xcodeProjectInterpreter = XcodeProjectInterpreter.test(
          processManager: fakeProcessManager,
          version: Version(26, 0, 0),
        );
        xcode = Xcode.test(
          processManager: fakeProcessManager,
          xcodeProjectInterpreter: xcodeProjectInterpreter,
        );
      });
      testUsingContext(
        'sets CONFIGURATION_BUILD_DIR when configurationBuildDir is set',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;
          final FlutterProject project = FlutterProject.fromDirectoryTest(
            fs.directory('path/to/project'),
          );
          await updateGeneratedXcodeProperties(
            project: project,
            buildInfo: buildInfo,

            configurationBuildDir: 'path/to/project/build/ios/iphoneos',
          );

          final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
          expect(config.existsSync(), isTrue);

          final String contents = config.readAsStringSync();
          expect(contents, contains('CONFIGURATION_BUILD_DIR=path/to/project/build/ios/iphoneos'));
        },
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          // Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => fakeProcessManager,
          XcodeProjectInterpreter: () => xcodeProjectInterpreter,
          Xcode: () => xcode,
        },
      );

      testUsingContext(
        'does not set CONFIGURATION_BUILD_DIR when configurationBuildDir is not set',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;
          final FlutterProject project = FlutterProject.fromDirectoryTest(
            fs.directory('path/to/project'),
          );
          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
          expect(config.existsSync(), isTrue);

          final String contents = config.readAsStringSync();
          expect(contents.contains('CONFIGURATION_BUILD_DIR'), isFalse);
        },
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => fakeProcessManager,
          XcodeProjectInterpreter: () => xcodeProjectInterpreter,
          Xcode: () => xcode,
        },
      );

      testUsingContext(
        'Sets FLUTTER_FRAMEWORK_SWIFT_PACKAGE_PATH for iOS',
        () async {
          const BuildInfo buildInfo = BuildInfo.debug;
          final FlutterProject project = FlutterProject.fromDirectoryTest(
            fs.directory('path/to/project'),
          );
          await updateGeneratedXcodeProperties(project: project, buildInfo: buildInfo);

          final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
          expect(config.existsSync(), isTrue);

          final String contents = config.readAsStringSync();
          expect(
            contents,
            contains(
              'FLUTTER_FRAMEWORK_SWIFT_PACKAGE_PATH=path/to/project/ios/Flutter/ephemeral/Packages/.packages/FlutterFramework',
            ),
          );
        },
        overrides: <Type, Generator>{
          Artifacts: () => localIosArtifacts,
          // Platform: () => macOS,
          FileSystem: () => fs,
          ProcessManager: () => fakeProcessManager,
          XcodeProjectInterpreter: () => xcodeProjectInterpreter,
          Xcode: () => xcode,
        },
      );
    });
  });
}
