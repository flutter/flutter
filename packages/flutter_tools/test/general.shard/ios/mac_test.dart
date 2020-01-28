// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessException, ProcessResult;
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
//import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};

class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcessUtils extends Mock implements ProcessUtils {}
class MockFile extends Mock implements File {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockIosProject extends Mock implements IosProject {}

void main() {
  group('IMobileDevice', () {
    final FakePlatform osx = FakePlatform.fromPlatform(const LocalPlatform())
      ..operatingSystem = 'macos';
    MockProcessManager mockProcessManager;
    MockProcessUtils mockProcessUtils;
    final String libimobiledevicePath = globals.fs.path.join('bin', 'cache', 'artifacts', 'libimobiledevice');
    final String ideviceIdPath = globals.fs.path.join(libimobiledevicePath, 'idevice_id');
    final String ideviceInfoPath = globals.fs.path.join(libimobiledevicePath, 'ideviceinfo');
    final String idevicescreenshotPath = globals.fs.path.join(libimobiledevicePath, 'idevicescreenshot');
    MockArtifacts mockArtifacts;
    MockCache mockCache;
    IMobileDevice iMobileDevice;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockProcessUtils = MockProcessUtils();
      mockCache = MockCache();
      mockArtifacts = MockArtifacts();
      when(mockArtifacts.getArtifactPath(Artifact.ideviceId, platform: anyNamed('platform'))).thenReturn(ideviceIdPath);
      when(mockArtifacts.getArtifactPath(Artifact.ideviceinfo, platform: anyNamed('platform'))).thenReturn(ideviceInfoPath);
      when(mockArtifacts.getArtifactPath(Artifact.idevicescreenshot, platform: anyNamed('platform'))).thenReturn(idevicescreenshotPath);
      when(mockCache.dyLdLibEntry).thenReturn(
        MapEntry<String, String>('DYLD_LIBRARY_PATH', libimobiledevicePath)
      );
      iMobileDevice = IMobileDevice(
        artifacts: mockArtifacts,
        cache: mockCache,
        processUtils: mockProcessUtils,
      );
    });

    testWithoutContext('isWorking returns false if libimobiledevice is not installed', () async {
      when(mockProcessUtils.exitsHappySync(
        <String>[ideviceIdPath, '-h'], environment: anyNamed('environment'),
      )).thenReturn(false);
      expect(await iMobileDevice.isWorking, false);
    });

    testWithoutContext('getAvailableDeviceIDs throws ToolExit when libimobiledevice is not installed', () async {
      when(mockProcessUtils.run(
        <String>[ideviceIdPath, '-l'],
        environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
      )).thenThrow(ProcessException(ideviceIdPath, <String>['-l']));
      expect(() async => await iMobileDevice.getAvailableDeviceIDs(), throwsToolExit());
    });

    testWithoutContext('getAvailableDeviceIDs throws ToolExit when idevice_id returns non-zero', () async {
      final List<String> command = <String>[ideviceIdPath, '-l'];
      when(mockProcessUtils.run(
        command,
        environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
      )).thenAnswer((_) => Future<RunResult>.value(
        RunResult(ProcessResult(1, 1, '', 'Sad today'), command)
      ));
      expect(() async => await iMobileDevice.getAvailableDeviceIDs(), throwsToolExit());
    });

    testWithoutContext('getAvailableDeviceIDs returns idevice_id output when installed', () async {
      final List<String> command = <String>[ideviceIdPath, '-l'];
      when(mockProcessUtils.run(
        command,
        environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
      )).thenAnswer((_) => Future<RunResult>.value(
        RunResult(ProcessResult(1, 0, 'foo', ''), command)
      ));
      expect(await iMobileDevice.getAvailableDeviceIDs(), 'foo');
    });

    testWithoutContext('getInfoForDevice throws IOSDeviceNotFoundError when ideviceinfo returns specific error code and message', () async {
      final List<String> command = <String>[ideviceInfoPath, '-u', 'foo', '-k', 'bar'];
      when(mockProcessUtils.run(
        command,
        environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
      )).thenAnswer((_) => Future<RunResult>.value(
        RunResult(ProcessResult(1, 255, 'No device found with udid foo, is it plugged in?', ''), command)
      ));
      expect(() async => await iMobileDevice.getInfoForDevice('foo', 'bar'), throwsA(isA<IOSDeviceNotFoundError>()));
    });

    testWithoutContext('getInfoForDevice throws IOSDeviceNotFoundError when user has not yet trusted the host', () async {
      final List<String> command = <String>[ideviceInfoPath, '-u', 'foo', '-k', 'bar'];
      when(mockProcessUtils.run(
        command,
        environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
      )).thenAnswer((_) {
        final ProcessResult processResult = ProcessResult(
          1,
          255,
          '',
          'ERROR: Could not connect to lockdownd, error code -${LockdownReturnCode.pairingDialogResponsePending.code}',
        );
        return Future<RunResult>.value(RunResult(processResult, command));
      });
      try {
        await iMobileDevice.getInfoForDevice('foo', 'bar');
        fail('Expected exception');
      } on IOSDeviceNotTrustedError catch (e) {
        expect(e.lockdownCode, LockdownReturnCode.pairingDialogResponsePending);
      } catch (e) {
        fail('Unknown exception: $e');
      }
    });

    testWithoutContext('getInfoForDevice throws ToolExit lockdownd fails for unknown reason', () async {
      final List<String> command = <String>[ideviceInfoPath, '-u', 'foo', '-k', 'bar'];
      when(mockProcessUtils.run(
        command,
        environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
      )).thenAnswer((Invocation invocation) {
        final ProcessResult processResult = ProcessResult(
          1,
          255,
          '',
          'ERROR: Could not connect to lockdownd, error code -567',
        );
        return Future<RunResult>.value(RunResult(processResult, command));
      });
      expect(() async => await iMobileDevice.getInfoForDevice('foo', 'bar'), throwsToolExit());
    });

    testWithoutContext('getInfoForDevice throws IOSDeviceNotFoundError when host trust is revoked', () async {
      final List<String> command = <String>[ideviceInfoPath, '-u', 'foo', '-k', 'bar'];
      when(mockProcessUtils.run(
        command,
        environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
      )).thenAnswer((Invocation invocation) {
        final ProcessResult processResult = ProcessResult(
          1,
          255,
          '',
          'ERROR: Could not connect to lockdownd, error code -${LockdownReturnCode.invalidHostId.code}',
        );
        return Future<RunResult>.value(RunResult(processResult, command));
      });
      expect(() async => await iMobileDevice.getInfoForDevice('foo', 'bar'), throwsA(isA<IOSDeviceNotTrustedError>()));
    });

    group('screenshot', () {
      final String outputPath = globals.fs.path.join('some', 'test', 'path', 'image.png');
      MockFile mockOutputFile;

      setUp(() {
        //mockProcessManager = MockProcessManager();
        mockOutputFile = MockFile();
      });

      testWithoutContext('error if idevicescreenshot is not installed', () async {
        when(mockOutputFile.path).thenReturn(outputPath);
        final List<String> command = <String>[idevicescreenshotPath, outputPath];
        // Let `idevicescreenshot` fail with exit code 1.
        when(mockProcessUtils.run(
          command,
          environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
          throwOnError: true,
          workingDirectory: null,
        )).thenThrow(ProcessException(idevicescreenshotPath, <String>[]));
        expect(() async => await iMobileDevice.takeScreenshot(mockOutputFile), throwsA(anything));
      });

      testWithoutContext('idevicescreenshot captures and returns screenshot', () async {
        when(mockOutputFile.path).thenReturn(outputPath);
        final List<String> command = <String>[
          idevicescreenshotPath,
          outputPath,
        ];
        when(mockProcessUtils.run(
          any,
          throwOnError: true,
          environment: anyNamed('environment'),
          whiteListFailures: null,
          workingDirectory: null)).thenAnswer((Invocation invocation) =>
            Future<RunResult>.value(RunResult(ProcessResult(4, 0, '', ''), command)));

        await iMobileDevice.takeScreenshot(mockOutputFile);
        verify(mockProcessUtils.run(<String>[idevicescreenshotPath, outputPath],
            environment: <String, String>{'DYLD_LIBRARY_PATH': libimobiledevicePath},
            throwOnError: true,
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

      await diagnoseXcodeBuildFailure(buildResult);
      verify(mockUsage.sendEvent('build',
        any,
        label: 'xcode-bitcode-failure',
        parameters: <String, String>{
          cdKey(CustomDimensions.buildEventCommand): buildCommands.toString(),
          cdKey(CustomDimensions.buildEventSettings): buildSettings.toString(),
      })).called(1);
    }, overrides: <Type, Generator>{
      Usage: () => mockUsage,
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

      await diagnoseXcodeBuildFailure(buildResult);
      expect(
        testLogger.errorText,
        contains('No Provisioning Profile was found for your project\'s Bundle Identifier or your \ndevice.'),
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

      await diagnoseXcodeBuildFailure(buildResult);
      expect(
        testLogger.errorText,
        contains('Building a deployable iOS app requires a selected Development Team with a \nProvisioning Profile.'),
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

    testUsingContext('upgradePbxProjWithFlutterAssets', () async {
      final MockIosProject project = MockIosProject();
      final MockFile pbxprojFile = MockFile();

      when(project.xcodeProjectInfoFile).thenReturn(pbxprojFile);
      when(project.hostAppBundleName).thenReturn('UnitTestRunner.app');
      when(pbxprojFile.readAsLinesSync())
          .thenAnswer((_) => flutterAssetPbxProjLines);
      when(pbxprojFile.existsSync())
          .thenAnswer((_) => true);

      bool result = upgradePbxProjWithFlutterAssets(project);
      expect(result, true);
      expect(
        testLogger.statusText,
        contains('Removing obsolete reference to flutter_assets'),
      );
      testLogger.clear();

      when(pbxprojFile.readAsLinesSync())
          .thenAnswer((_) => appFlxPbxProjLines);
      result = upgradePbxProjWithFlutterAssets(project);
      expect(result, true);
      expect(
        testLogger.statusText,
        contains('Removing obsolete reference to app.flx'),
      );
      testLogger.clear();

      when(pbxprojFile.readAsLinesSync())
          .thenAnswer((_) => cleanPbxProjLines);
      result = upgradePbxProjWithFlutterAssets(project);
      expect(result, true);
      expect(
        testLogger.statusText,
        isEmpty,
      );
    });
  });
}

class MockUsage extends Mock implements Usage {}
