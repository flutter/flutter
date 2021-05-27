// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

FakePlatform _kNoColorTerminalPlatform() => FakePlatform(stdoutSupportsAnsi: false);
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};

class MockIosProject extends Mock implements IosProject {}

void main() {
  BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
  });

  group('IMobileDevice', () {
    Artifacts artifacts;
    Cache cache;

    setUp(() {
      artifacts = Artifacts.test();
      cache = Cache.test(
        artifacts: <ArtifactSet>[
          FakeDyldEnvironmentArtifact(),
        ],
        processManager: FakeProcessManager.any(),
      );
    });

    group('screenshot', () {
      FakeProcessManager fakeProcessManager;
      File outputFile;

      setUp(() {
        fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
        outputFile = MemoryFileSystem.test().file('image.png');
      });

      testWithoutContext('error if idevicescreenshot is not installed', () async {
        // Let `idevicescreenshot` fail with exit code 1.
        fakeProcessManager.addCommand(FakeCommand(
          command: <String>[
            'Artifact.idevicescreenshot.TargetPlatform.ios',
            outputFile.path,
            '--udid',
            '1234',
          ],
          environment: const <String, String>{
            'DYLD_LIBRARY_PATH': '/path/to/libraries',
          },
          exitCode: 1,
        ));

        final IMobileDevice iMobileDevice = IMobileDevice(
          artifacts: artifacts,
          cache: cache,
          processManager: fakeProcessManager,
          logger: logger,
        );

        expect(() async => iMobileDevice.takeScreenshot(
          outputFile,
          '1234',
          IOSDeviceInterface.usb,
        ), throwsA(anything));
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      });

      testWithoutContext('idevicescreenshot captures and returns USB screenshot', () async {
        fakeProcessManager.addCommand(FakeCommand(
          command: <String>[
            'Artifact.idevicescreenshot.TargetPlatform.ios', outputFile.path, '--udid', '1234',
          ],
          environment: const <String, String>{'DYLD_LIBRARY_PATH': '/path/to/libraries'},
        ));

        final IMobileDevice iMobileDevice = IMobileDevice(
          artifacts: artifacts,
          cache: cache,
          processManager: fakeProcessManager,
          logger: logger,
        );

        await iMobileDevice.takeScreenshot(
          outputFile,
          '1234',
          IOSDeviceInterface.usb,
        );
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      });

      testWithoutContext('idevicescreenshot captures and returns network screenshot', () async {
        fakeProcessManager.addCommand(FakeCommand(
          command: <String>[
            'Artifact.idevicescreenshot.TargetPlatform.ios', outputFile.path, '--udid', '1234', '--network',
          ],
          environment: const <String, String>{'DYLD_LIBRARY_PATH': '/path/to/libraries'},
        ));

        final IMobileDevice iMobileDevice = IMobileDevice(
          artifacts: artifacts,
          cache: cache,
          processManager: fakeProcessManager,
          logger: logger,
        );

        await iMobileDevice.takeScreenshot(
          outputFile,
          '1234',
          IOSDeviceInterface.network,
        );
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      });
    });
  });

  group('Diagnose Xcode build failure', () {
    Map<String, String> buildSettings;
    TestUsage testUsage;

    setUp(() {
      buildSettings = <String, String>{
        'PRODUCT_BUNDLE_IDENTIFIER': 'test.app',
      };
      testUsage = TestUsage();
    });

    testUsingContext('Sends analytics when bitcode fails', () async {
      const List<String> buildCommands = <String>['xcrun', 'cc', 'blah'];
      final XcodeBuildResult buildResult = XcodeBuildResult(
        success: false,
        stdout: 'BITCODE_ENABLED = YES',
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: buildCommands,
          appDirectory: '/blah/blah',
          buildForPhysicalDevice: true,
          buildSettings: buildSettings,
        ),
      );

      await diagnoseXcodeBuildFailure(buildResult, testUsage, logger);
      expect(testUsage.events, contains(
        TestUsageEvent(
          'build',
          'unspecified',
          label: 'xcode-bitcode-failure',
          parameters: <String, String>{
            cdKey(CustomDimensions.buildEventCommand): buildCommands.toString(),
            cdKey(CustomDimensions.buildEventSettings): buildSettings.toString(),
          },
        ),
      ));
    });

    testUsingContext('No provisioning profile shows message', () async {
      final XcodeBuildResult buildResult = XcodeBuildResult(
        success: false,
        stdout: '''
Launching lib/main.dart on iPhone in debug mode...
Signing iOS app for device deployment using developer identity: "iPhone Developer: test@flutter.io (1122334455)"
Running Xcode build...                                1.3s
Failed to build iOS app
Error output from Xcode build:
↳
    ** BUILD FAILED **


    The following build commands failed:
    	Check dependencies
    (1 failure)
Xcode's output:
↳
    Build settings from command line:
        ARCHS = arm64
        BUILD_DIR = /Users/blah/blah
        DEVELOPMENT_TEAM = AABBCCDDEE
        ONLY_ACTIVE_ARCH = YES
        SDKROOT = iphoneos10.3

    === CLEAN TARGET Runner OF PROJECT Runner WITH CONFIGURATION Release ===

    Check dependencies
    [BCEROR]No profiles for 'com.example.test' were found:  Xcode couldn't find a provisioning profile matching 'com.example.test'.
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'

    Create product structure
    /bin/mkdir -p /Users/blah/Runner.app

    Clean.Remove clean /Users/blah/Runner.app.dSYM
        builtin-rm -rf /Users/blah/Runner.app.dSYM

    Clean.Remove clean /Users/blah/Runner.app
        builtin-rm -rf /Users/blah/Runner.app

    Clean.Remove clean /Users/blah/Runner-dfvicjniknvzghgwsthwtgcjhtsk/Build/Intermediates/Runner.build/Release-iphoneos/Runner.build
        builtin-rm -rf /Users/blah/Runner-dfvicjniknvzghgwsthwtgcjhtsk/Build/Intermediates/Runner.build/Release-iphoneos/Runner.build

    ** CLEAN SUCCEEDED **

    === BUILD TARGET Runner OF PROJECT Runner WITH CONFIGURATION Release ===

    Check dependencies
    No profiles for 'com.example.test' were found:  Xcode couldn't find a provisioning profile matching 'com.example.test'.
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'

Could not build the precompiled application for the device.

Error launching application on iPhone.''',
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: <String>['xcrun', 'xcodebuild', 'blah'],
          appDirectory: '/blah/blah',
          buildForPhysicalDevice: true,
          buildSettings: buildSettings,
        ),
      );

      await diagnoseXcodeBuildFailure(buildResult, testUsage, logger);
      expect(
        logger.errorText,
        contains("No Provisioning Profile was found for your project's Bundle Identifier or your \ndevice."),
      );
    }, overrides: noColorTerminalOverride);

    testUsingContext('No development team shows message', () async {
      final XcodeBuildResult buildResult = XcodeBuildResult(
        success: false,
        stdout: '''
Running "flutter pub get" in flutter_gallery...  0.6s
Launching lib/main.dart on x in release mode...
Running pod install...                                1.2s
Running Xcode build...                                1.4s
Failed to build iOS app
Error output from Xcode build:
↳
    ** BUILD FAILED **


    The following build commands failed:
    	Check dependencies
    (1 failure)
Xcode's output:
↳
    blah

    === CLEAN TARGET url_launcher OF PROJECT Pods WITH CONFIGURATION Release ===

    Check dependencies

    blah

    === CLEAN TARGET Pods-Runner OF PROJECT Pods WITH CONFIGURATION Release ===

    Check dependencies

    blah

    === CLEAN TARGET Runner OF PROJECT Runner WITH CONFIGURATION Release ===

    Check dependencies
    [BCEROR]Signing for "Runner" requires a development team. Select a development team in the project editor.
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'

    blah

    ** CLEAN SUCCEEDED **

    === BUILD TARGET url_launcher OF PROJECT Pods WITH CONFIGURATION Release ===

    Check dependencies

    blah

    === BUILD TARGET Pods-Runner OF PROJECT Pods WITH CONFIGURATION Release ===

    Check dependencies

    blah

    === BUILD TARGET Runner OF PROJECT Runner WITH CONFIGURATION Release ===

    Check dependencies
    Signing for "Runner" requires a development team. Select a development team in the project editor.
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'

Could not build the precompiled application for the device.''',
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: <String>['xcrun', 'xcodebuild', 'blah'],
          appDirectory: '/blah/blah',
          buildForPhysicalDevice: true,
          buildSettings: buildSettings,
        ),
      );

      await diagnoseXcodeBuildFailure(buildResult, testUsage, logger);
      expect(
        logger.errorText,
        contains('Building a deployable iOS app requires a selected Development Team with a \nProvisioning Profile.'),
      );
    }, overrides: noColorTerminalOverride);

    testUsingContext('embedded and linked framework iOS mismatch shows message', () async {
      final XcodeBuildResult buildResult = XcodeBuildResult(
        success: false,
        stdout: '''
Launching lib/main.dart on iPhone in debug mode...
Automatically signing iOS for device deployment using specified development team in Xcode project: blah
Xcode build done. 5.7s
Failed to build iOS app
Error output from Xcode build:
↳
** BUILD FAILED **
Xcode's output:
↳
note: Using new build system
note: Building targets in parallel
note: Planning build
note: Constructing build description
error: Building for iOS Simulator, but the linked and embedded framework 'App.framework' was built for iOS. (in target 'Runner' from project 'Runner')
Could not build the precompiled application for the device.

Error launching application on iPhone.
Exited (sigterm)''',
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: <String>['xcrun', 'xcodebuild', 'blah'],
          appDirectory: '/blah/blah',
          buildForPhysicalDevice: true,
          buildSettings: buildSettings,
        ),
      );

      await diagnoseXcodeBuildFailure(buildResult, testUsage, logger);
      expect(
        logger.errorText,
        contains('Your Xcode project requires migration.'),
      );
    }, overrides: noColorTerminalOverride);

    testUsingContext('embedded and linked framework iOS simulator mismatch shows message', () async {
      final XcodeBuildResult buildResult = XcodeBuildResult(
        success: false,
        stdout: '''
Launching lib/main.dart on iPhone in debug mode...
Automatically signing iOS for device deployment using specified development team in Xcode project: blah
Xcode build done. 5.7s
Failed to build iOS app
Error output from Xcode build:
↳
** BUILD FAILED **
Xcode's output:
↳
note: Using new build system
note: Building targets in parallel
note: Planning build
note: Constructing build description
error: Building for iOS, but the linked and embedded framework 'App.framework' was built for iOS Simulator. (in target 'Runner' from project 'Runner')
Could not build the precompiled application for the device.

Error launching application on iPhone.
Exited (sigterm)''',
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: <String>['xcrun', 'xcodebuild', 'blah'],
          appDirectory: '/blah/blah',
          buildForPhysicalDevice: true,
          buildSettings: buildSettings,
        ),
      );

      await diagnoseXcodeBuildFailure(buildResult, testUsage, logger);
      expect(
        logger.errorText,
        contains('Your Xcode project requires migration.'),
      );
    }, overrides: noColorTerminalOverride);
  });

  group('Upgrades project.pbxproj for old asset usage', () {
    const String flutterAssetPbxProjLines =
      '/* flutter_assets */\n'
      '/* App.framework\n'
      'another line';

    const String appFlxPbxProjLines =
      '/* app.flx\n'
      '/* App.framework\n'
      'another line';

    const String cleanPbxProjLines =
      '/* App.framework\n'
      'another line';

    testWithoutContext('upgradePbxProjWithFlutterAssets', () async {
      final MockIosProject project = MockIosProject();
      final File pbxprojFile = MemoryFileSystem.test().file('project.pbxproj')
        ..writeAsStringSync(flutterAssetPbxProjLines);

      when(project.xcodeProjectInfoFile).thenReturn(pbxprojFile);
      when(project.hostAppBundleName(any)).thenAnswer((_) => Future<String>.value('UnitTestRunner.app'));

      bool result = upgradePbxProjWithFlutterAssets(project, logger);
      expect(result, true);
      expect(
        logger.statusText,
        contains('Removing obsolete reference to flutter_assets'),
      );
      logger.clear();

      pbxprojFile.writeAsStringSync(appFlxPbxProjLines);
      result = upgradePbxProjWithFlutterAssets(project, logger);
      expect(result, true);
      expect(
        logger.statusText,
        contains('Removing obsolete reference to app.flx'),
      );
      logger.clear();

      pbxprojFile.writeAsStringSync(cleanPbxProjLines);
      result = upgradePbxProjWithFlutterAssets(project, logger);
      expect(result, true);
      expect(
        logger.statusText,
        isEmpty,
      );
    });
  });

  group('remove Finder extended attributes', () {
    Directory projectDirectory;
    setUp(() {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      projectDirectory = fs.directory('flutter_project');
    });

    testWithoutContext('removes xattr', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'xattr',
          '-r',
          '-d',
          'com.apple.FinderInfo',
          projectDirectory.path,
        ])
      ]);

      await removeFinderExtendedAttributes(projectDirectory, ProcessUtils(processManager: processManager, logger: logger), logger);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('ignores errors', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'xattr',
          '-r',
          '-d',
          'com.apple.FinderInfo',
          projectDirectory.path,
        ], exitCode: 1,
        )
      ]);

      await removeFinderExtendedAttributes(projectDirectory, ProcessUtils(processManager: processManager, logger: logger), logger);
      expect(logger.traceText, contains('Failed to remove xattr com.apple.FinderInfo'));
      expect(processManager, hasNoRemainingExpectations);
    });
  });
}
