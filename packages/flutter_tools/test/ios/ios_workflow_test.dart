// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/cocoapods.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('iOS Workflow validation', () {
    MockIMobileDevice iMobileDevice;
    MockIMobileDevice iMobileDeviceUninstalled;
    MockXcode xcode;
    MockProcessManager processManager;
    MockCocoaPods cocoaPods;
    FileSystem fs;

    setUp(() {
      iMobileDevice = MockIMobileDevice();
      iMobileDeviceUninstalled = MockIMobileDevice(isInstalled: false);
      xcode = MockXcode();
      processManager = MockProcessManager();
      cocoaPods = MockCocoaPods();
      fs = MemoryFileSystem();

      when(cocoaPods.evaluateCocoaPodsInstallation)
          .thenAnswer((_) async => CocoaPodsStatus.recommended);
      when(cocoaPods.isCocoaPodsInitialized).thenAnswer((_) async => true);
      when(cocoaPods.cocoaPodsVersionText).thenAnswer((_) async => '1.8.0');
    });

    testUsingContext('Emit missing status when nothing is installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      when(xcode.xcodeSelectPath).thenReturn(null);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget(
        hasHomebrew: false,
        hasIosDeploy: false,
        hasIDeviceInstaller: false,
        iosDeployVersionText: '0.0.0',
      );
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDeviceUninstalled,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when Xcode is not installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      when(xcode.xcodeSelectPath).thenReturn(null);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when Xcode is partially installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      when(xcode.xcodeSelectPath).thenReturn('/Library/Developer/CommandLineTools');
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when Xcode version too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 7.0.1\nBuild version 7C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(false);
      when(xcode.eulaSigned).thenReturn(true);
      when(xcode.isSimctlInstalled).thenReturn(true);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when Xcode EULA not signed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(false);
      when(xcode.isSimctlInstalled).thenReturn(true);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits installed status when homebrew not installed, but not needed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      when(xcode.isSimctlInstalled).thenReturn(true);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget(hasHomebrew: false);
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when libimobiledevice is not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      when(xcode.isSimctlInstalled).thenReturn(true);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => MockIMobileDevice(isInstalled: false, isWorking: false),
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when libimobiledevice is installed but not working', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      when(xcode.isSimctlInstalled).thenReturn(true);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => MockIMobileDevice(isWorking: false),
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when libimobiledevice is installed but not working', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      when(xcode.isSimctlInstalled).thenReturn(true);
      when(processManager.run(
        <String>['ideviceinfo', '-u', '00008020-001C2D903C42002E'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')),
      ).thenAnswer((Invocation _) async {
        final MockProcessResult result = MockProcessResult();
        when<String>(result.stdout).thenReturn(r'''
Usage: ideviceinfo [OPTIONS]
Show information about a connected device.

  -d, --debug		enable communication debugging
  -s, --simple		use a simple connection to avoid auto-pairing with the device
  -u, --udid UDID	target specific device by its 40-digit device UDID
  -q, --domain NAME	set domain of query to NAME. Default: None
  -k, --key NAME	only query key specified by NAME. Default: All keys.
  -x, --xml		output information as xml plist instead of key/value pairs
  -h, --help		prints usage information
        ''');
      });
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });


    testUsingContext('Emits partial status when ios-deploy is not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.isSimctlInstalled).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget(hasIosDeploy: false);
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when ios-deploy version is too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      when(xcode.isSimctlInstalled).thenReturn(true);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget(iosDeployVersionText: '1.8.0');
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when simctl is not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      when(xcode.isSimctlInstalled).thenReturn(false);
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
    });


    testUsingContext('Succeeds when all checks pass', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.versionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      when(xcode.isSimctlInstalled).thenReturn(true);

      ensureDirectoryExists(fs.path.join(homeDirPath, '.cocoapods', 'repos', 'master', 'README.md'));

      final ValidationResult result = await IOSWorkflowTestTarget().validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      IMobileDevice: () => iMobileDevice,
      Xcode: () => xcode,
      CocoaPods: () => cocoaPods,
      ProcessManager: () => processManager,
    });
  });

  group('iOS CocoaPods validation', () {
    MockCocoaPods cocoaPods;

    setUp(() {
      cocoaPods = MockCocoaPods();
      when(cocoaPods.evaluateCocoaPodsInstallation)
          .thenAnswer((_) async => CocoaPodsStatus.recommended);
      when(cocoaPods.isCocoaPodsInitialized).thenAnswer((_) async => true);
      when(cocoaPods.cocoaPodsVersionText).thenAnswer((_) async => '1.8.0');
    });

    testUsingContext('Emits installed status when CocoaPods is installed', () async {
      final CocoaPodsTestTarget workflow = CocoaPodsTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits missing status when CocoaPods is not installed', () async {
      when(cocoaPods.evaluateCocoaPodsInstallation)
          .thenAnswer((_) async => CocoaPodsStatus.notInstalled);
      final CocoaPodsTestTarget workflow = CocoaPodsTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when CocoaPods is not initialized', () async {
      when(cocoaPods.isCocoaPodsInitialized).thenAnswer((_) async => false);
      final CocoaPodsTestTarget workflow = CocoaPodsTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when CocoaPods version is too low', () async {
      when(cocoaPods.evaluateCocoaPodsInstallation)
          .thenAnswer((_) async => CocoaPodsStatus.belowRecommendedVersion);
      final CocoaPodsTestTarget workflow = CocoaPodsTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits missing status when homebrew is not installed', () async {
      final CocoaPodsTestTarget workflow = CocoaPodsTestTarget(hasHomebrew: false);
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });
  });
}

final ProcessResult exitsHappy = ProcessResult(
  1, // pid
  0, // exitCode
  '', // stdout
  '', // stderr
);

class MockIMobileDevice extends IMobileDevice {
  MockIMobileDevice({
    this.isInstalled = true,
    bool isWorking = true,
  }) : isWorking = Future<bool>.value(isWorking);

  @override
  final bool isInstalled;

  @override
  final Future<bool> isWorking;
}

class MockXcode extends Mock implements Xcode {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockCocoaPods extends Mock implements CocoaPods {}
class MockProcessResult extends Mock implements ProcessResult {}

class IOSWorkflowTestTarget extends IOSValidator {
  IOSWorkflowTestTarget({
    this.hasHomebrew = true,
    bool hasIosDeploy = true,
    String iosDeployVersionText = '1.9.4',
    bool hasIDeviceInstaller = true,
  }) : hasIosDeploy = Future<bool>.value(hasIosDeploy),
       iosDeployVersionText = Future<String>.value(iosDeployVersionText),
       hasIDeviceInstaller = Future<bool>.value(hasIDeviceInstaller);

  @override
  final bool hasHomebrew;

  @override
  final Future<bool> hasIosDeploy;

  @override
  final Future<String> iosDeployVersionText;

  @override
  final Future<bool> hasIDeviceInstaller;
}

class CocoaPodsTestTarget extends CocoaPodsValidator {
  CocoaPodsTestTarget({
    this.hasHomebrew = true
  });

  @override
  final bool hasHomebrew;
}