// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessResult;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

final Generator _kNoColorTerminalPlatform = () => FakePlatform(stdoutSupportsAnsi: false);
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};

class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockFile extends Mock implements File {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockIosProject extends Mock implements IosProject {}

void main() {
  BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
  });

  group('IMobileDevice', () {
    final String libimobiledevicePath = globals.fs.path.join('bin', 'cache', 'artifacts', 'libimobiledevice');
    final String idevicescreenshotPath = globals.fs.path.join(libimobiledevicePath, 'idevicescreenshot');
    MockArtifacts mockArtifacts;
    MockCache mockCache;

    setUp(() {
      mockCache = MockCache();
      mockArtifacts = MockArtifacts();
      when(mockArtifacts.getArtifactPath(Artifact.idevicescreenshot, platform: anyNamed('platform'))).thenReturn(idevicescreenshotPath);
      when(mockCache.dyLdLibEntry).thenReturn(
        MapEntry<String, String>('DYLD_LIBRARY_PATH', libimobiledevicePath)
      );
    });

    group('screenshot', () {
      final String outputPath = globals.fs.path.join('some', 'test', 'path', 'image.png');
      MockProcessManager mockProcessManager;
      MockFile mockOutputFile;

      setUp(() {
        mockProcessManager = MockProcessManager();
        mockOutputFile = MockFile();
        when(mockArtifacts.getArtifactPath(Artifact.idevicescreenshot, platform: anyNamed('platform'))).thenReturn(idevicescreenshotPath);
      });

      testWithoutContext('error if idevicescreenshot is not installed', () async {
        when(mockOutputFile.path).thenReturn(outputPath);

        // Let `idevicescreenshot` fail with exit code 1.
        when(mockProcessManager.run(<String>[idevicescreenshotPath, outputPath],
            environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
            workingDirectory: null,
        )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(4, 1, '', '')));

        final IMobileDevice iMobileDevice = IMobileDevice(
          artifacts: mockArtifacts,
          cache: mockCache,
          processManager: mockProcessManager,
          logger: logger,
        );

        expect(() async => await iMobileDevice.takeScreenshot(
          mockOutputFile,
          '1234',
          IOSDeviceInterface.usb,
        ), throwsA(anything));
      });

      testWithoutContext('idevicescreenshot captures and returns USB screenshot', () async {
        when(mockOutputFile.path).thenReturn(outputPath);
        when(mockProcessManager.run(any, environment: anyNamed('environment'), workingDirectory: null)).thenAnswer(
            (Invocation invocation) => Future<ProcessResult>.value(ProcessResult(4, 0, '', '')));

        final IMobileDevice iMobileDevice = IMobileDevice(
          artifacts: mockArtifacts,
          cache: mockCache,
          processManager: mockProcessManager,
          logger: logger,
        );

        await iMobileDevice.takeScreenshot(
          mockOutputFile,
          '1234',
          IOSDeviceInterface.usb,
        );
        verify(mockProcessManager.run(<String>[idevicescreenshotPath, outputPath, '--udid', '1234'],
            environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
            workingDirectory: null,
        ));
      });

      testWithoutContext('idevicescreenshot captures and returns network screenshot', () async {
        when(mockOutputFile.path).thenReturn(outputPath);
        when(mockProcessManager.run(any, environment: anyNamed('environment'), workingDirectory: null)).thenAnswer(
            (Invocation invocation) => Future<ProcessResult>.value(ProcessResult(4, 0, '', '')));

        final IMobileDevice iMobileDevice = IMobileDevice(
          artifacts: mockArtifacts,
          cache: mockCache,
          processManager: mockProcessManager,
          logger: logger,
        );

        await iMobileDevice.takeScreenshot(
          mockOutputFile,
          '1234',
          IOSDeviceInterface.network,
        );
        verify(mockProcessManager.run(<String>[idevicescreenshotPath, outputPath, '--udid', '1234', '--network'],
          environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
          workingDirectory: null,
        ));
      });
    });
  });

  group('Diagnose Xcode build failure', () {
    Map<String, String> buildSettings;
    MockUsage mockUsage;

    setUp(() {
      buildSettings = <String, String>{
        'PRODUCT_BUNDLE_IDENTIFIER': 'test.app',
      };
      mockUsage = MockUsage();
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

      await diagnoseXcodeBuildFailure(buildResult, mockUsage, logger);
      verify(mockUsage.sendEvent('build',
        any,
        label: 'xcode-bitcode-failure',
        parameters: <String, String>{
          cdKey(CustomDimensions.buildEventCommand): buildCommands.toString(),
          cdKey(CustomDimensions.buildEventSettings): buildSettings.toString(),
      })).called(1);
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

      await diagnoseXcodeBuildFailure(buildResult, mockUsage, logger);
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

      await diagnoseXcodeBuildFailure(buildResult, mockUsage, logger);
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

      await diagnoseXcodeBuildFailure(buildResult, mockUsage, logger);
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

      await diagnoseXcodeBuildFailure(buildResult, mockUsage, logger);
      expect(
        logger.errorText,
        contains('Your Xcode project requires migration.'),
      );
    }, overrides: noColorTerminalOverride);
  });

  group('Upgrades project.pbxproj for old asset usage', () {
    const List<String> flutterAssetPbxProjLines = <String>[
      '/* flutter_assets */',
      '/* App.framework',
      'another line',
    ];

    const List<String> appFlxPbxProjLines = <String>[
      '/* app.flx',
      '/* App.framework',
      'another line',
    ];

    const List<String> cleanPbxProjLines = <String>[
      '/* App.framework',
      'another line',
    ];

    testWithoutContext('upgradePbxProjWithFlutterAssets', () async {
      final MockIosProject project = MockIosProject();
      final MockFile pbxprojFile = MockFile();

      when(project.xcodeProjectInfoFile).thenReturn(pbxprojFile);
      when(project.hostAppBundleName(any)).thenAnswer((_) => Future<String>.value('UnitTestRunner.app'));
      when(pbxprojFile.readAsLinesSync())
          .thenAnswer((_) => flutterAssetPbxProjLines);
      when(pbxprojFile.existsSync())
          .thenAnswer((_) => true);

      bool result = upgradePbxProjWithFlutterAssets(project, logger);
      expect(result, true);
      expect(
        logger.statusText,
        contains('Removing obsolete reference to flutter_assets'),
      );
      logger.clear();

      when(pbxprojFile.readAsLinesSync())
          .thenAnswer((_) => appFlxPbxProjLines);
      result = upgradePbxProjWithFlutterAssets(project, logger);
      expect(result, true);
      expect(
        logger.statusText,
        contains('Removing obsolete reference to app.flx'),
      );
      logger.clear();

      when(pbxprojFile.readAsLinesSync())
          .thenAnswer((_) => cleanPbxProjLines);
      result = upgradePbxProjWithFlutterAssets(project, logger);
      expect(result, true);
      expect(
        logger.statusText,
        isEmpty,
      );
    });
  });

  group('remove Finder extended attributes', () {
    Directory iosProjectDirectory;
    setUp(() {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      iosProjectDirectory = fs.directory('ios');
    });

    testWithoutContext('removes xattr', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'xattr',
          '-r',
          '-d',
          'com.apple.FinderInfo',
          iosProjectDirectory.path,
        ])
      ]);

      await removeFinderExtendedAttributes(iosProjectDirectory, ProcessUtils(processManager: processManager, logger: logger), logger);
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('ignores errors', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'xattr',
          '-r',
          '-d',
          'com.apple.FinderInfo',
          iosProjectDirectory.path,
        ], exitCode: 1,
        )
      ]);

      await removeFinderExtendedAttributes(iosProjectDirectory, ProcessUtils(processManager: processManager, logger: logger), logger);
      expect(logger.traceText, contains('Failed to remove xattr com.apple.FinderInfo'));
      expect(processManager.hasRemainingExpectations, false);
    });
  });
}

class MockUsage extends Mock implements Usage {}
