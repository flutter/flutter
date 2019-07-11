// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessException, ProcessResult;
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};

class MockProcessManager extends Mock implements ProcessManager {}
class MockFile extends Mock implements File {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockIosProject extends Mock implements IosProject {}

void main() {
  group('IMobileDevice', () {
    final FakePlatform osx = FakePlatform.fromPlatform(const LocalPlatform())
      ..operatingSystem = 'macos';
    MockProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
    });

    testUsingContext('getAvailableDeviceIDs throws ToolExit when libimobiledevice is not installed', () async {
      when(mockProcessManager.run(<String>['idevice_id', '-l']))
          .thenThrow(const ProcessException('idevice_id', <String>['-l']));
      expect(() async => await iMobileDevice.getAvailableDeviceIDs(), throwsToolExit());
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('getAvailableDeviceIDs throws ToolExit when idevice_id returns non-zero', () async {
      when(mockProcessManager.run(<String>['idevice_id', '-l']))
          .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(1, 1, '', 'Sad today')));
      expect(() async => await iMobileDevice.getAvailableDeviceIDs(), throwsToolExit());
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('getAvailableDeviceIDs returns idevice_id output when installed', () async {
      when(mockProcessManager.run(<String>['idevice_id', '-l']))
          .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(1, 0, 'foo', '')));
      expect(await iMobileDevice.getAvailableDeviceIDs(), 'foo');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('getInfoForDevice throws IOSDeviceNotFoundError when ideviceinfo returns specific error code and message', () async {
      when(mockProcessManager.run(<String>['ideviceinfo', '-u', 'foo', '-k', 'bar']))
          .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(1, 255, 'No device found with udid foo, is it plugged in?', '')));
      expect(() async => await iMobileDevice.getInfoForDevice('foo', 'bar'), throwsA(isInstanceOf<IOSDeviceNotFoundError>()));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    group('screenshot', () {
      final String outputPath = fs.path.join('some', 'test', 'path', 'image.png');
      MockProcessManager mockProcessManager;
      MockFile mockOutputFile;

      setUp(() {
        mockProcessManager = MockProcessManager();
        mockOutputFile = MockFile();
      });

      testUsingContext('error if idevicescreenshot is not installed', () async {
        when(mockOutputFile.path).thenReturn(outputPath);

        // Let `idevicescreenshot` fail with exit code 1.
        when(mockProcessManager.run(<String>['idevicescreenshot', outputPath],
            environment: null,
            workingDirectory: null,
        )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(4, 1, '', '')));

        expect(() async => await iMobileDevice.takeScreenshot(mockOutputFile), throwsA(anything));
      }, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        Platform: () => osx,
      });

      testUsingContext('idevicescreenshot captures and returns screenshot', () async {
        when(mockOutputFile.path).thenReturn(outputPath);
        when(mockProcessManager.run(any, environment: null, workingDirectory: null)).thenAnswer(
            (Invocation invocation) => Future<ProcessResult>.value(ProcessResult(4, 0, '', '')));

        await iMobileDevice.takeScreenshot(mockOutputFile);
        verify(mockProcessManager.run(<String>['idevicescreenshot', outputPath],
            environment: null,
            workingDirectory: null,
        ));
      }, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
      });
    });
  });

  group('Diagnose Xcode build failure', () {
    Map<String, String> buildSettings;

    setUp(() {
      buildSettings = <String, String>{
        'PRODUCT_BUNDLE_IDENTIFIER': 'test.app',
      };
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
      when(pbxprojFile.readAsLines())
          .thenAnswer((_) => Future<List<String>>.value(flutterAssetPbxProjLines));
      when(pbxprojFile.exists())
          .thenAnswer((_) => Future<bool>.value(true));

      bool result = await upgradePbxProjWithFlutterAssets(project);
      expect(result, true);
      expect(
        testLogger.statusText,
        contains('Removing obsolete reference to flutter_assets'),
      );
      testLogger.clear();

      when(pbxprojFile.readAsLines())
          .thenAnswer((_) => Future<List<String>>.value(appFlxPbxProjLines));
      result = await upgradePbxProjWithFlutterAssets(project);
      expect(result, true);
      expect(
        testLogger.statusText,
        contains('Removing obsolete reference to app.flx'),
      );
      testLogger.clear();

      when(pbxprojFile.readAsLines())
          .thenAnswer((_) => Future<List<String>>.value(cleanPbxProjLines));
      result = await upgradePbxProjWithFlutterAssets(project);
      expect(result, true);
      expect(
        testLogger.statusText,
        isEmpty,
      );
    });
  });
}
