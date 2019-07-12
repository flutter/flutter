// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/doctor.dart';
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
    MockProcessManager processManager;
    FileSystem fs;

    setUp(() {
      iMobileDevice = MockIMobileDevice();
      iMobileDeviceUninstalled = MockIMobileDevice(isInstalled: false);
      processManager = MockProcessManager();
      fs = MemoryFileSystem();
    });

    testUsingContext('Emit missing status when nothing is installed', () async {
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
    });

    testUsingContext('Emits installed status when homebrew not installed, but not needed', () async {
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget(hasHomebrew: false);
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
    });

    testUsingContext('Emits partial status when libimobiledevice is not installed', () async {
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => MockIMobileDevice(isInstalled: false, isWorking: false),
    });

    testUsingContext('Emits partial status when libimobiledevice is installed but not working', () async {
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => MockIMobileDevice(isWorking: false),
    });

    testUsingContext('Emits partial status when libimobiledevice is installed but not working', () async {
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
        return null;
      });
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });


    testUsingContext('Emits partial status when ios-deploy is not installed', () async {
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget(hasIosDeploy: false);
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
    });

    testUsingContext('Emits partial status when ios-deploy version is too low', () async {
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget(iosDeployVersionText: '1.8.0');
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
    });

    testUsingContext('Emits partial status when ios-deploy version is a known bad version', () async {
      final IOSWorkflowTestTarget workflow = IOSWorkflowTestTarget(iosDeployVersionText: '2.0.0');
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => iMobileDevice,
    });

    testUsingContext('Succeeds when all checks pass', () async {
      final ValidationResult result = await IOSWorkflowTestTarget().validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      IMobileDevice: () => iMobileDevice,
      ProcessManager: () => processManager,
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

class MockProcessManager extends Mock implements ProcessManager {}
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
