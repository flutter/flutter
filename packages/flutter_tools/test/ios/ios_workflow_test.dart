// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('iOS Workflow validation', () {
    MockXcode xcode;
    MockProcessManager processManager;
    FileSystem fs;

    setUp(() {
      xcode = new MockXcode();
      processManager = new MockProcessManager();
      fs = new MemoryFileSystem();
    });

    testUsingContext('Emit missing status when nothing is installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      when(xcode.xcodeSelectPath).thenReturn(null);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..hasPythonSixModule = false
        ..hasHomebrew = false
        ..hasIosDeploy = false;
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when Xcode is not installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      when(xcode.xcodeSelectPath).thenReturn(null);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when Xcode is partially installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      when(xcode.xcodeSelectPath).thenReturn('/Library/Developer/CommandLineTools');
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when Xcode version too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 7.0.1\nBuild version 7C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(false);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when Xcode EULA not signed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(false);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when python six not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..hasPythonSixModule = false;
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when homebrew not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..hasHomebrew = false;
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when ios-deploy is not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..hasIosDeploy = false;
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when ios-deploy version is too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..iosDeployVersionText = '1.8.0';
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when CocoaPods is not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..hasCocoaPods = false;
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when CocoaPods version is too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      final IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..cocoaPodsVersionText = '0.39.0';
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when CocoaPods is not initialized', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);

      when(processManager.runSync(argThat(contains('idevice_id'))))
          .thenReturn(exitsHappy);
      when(processManager.run(argThat(contains('idevice_id')), workingDirectory: any, environment: any))
          .thenReturn(exitsHappy);

      final ValidationResult result = await new IOSWorkflowTestTarget().validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      Xcode: () => xcode,
      ProcessManager: () => processManager,
    });

    testUsingContext('Succeeds when all checks pass', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);

      when(processManager.runSync(argThat(contains('idevice_id'))))
          .thenReturn(exitsHappy);
      when(processManager.run(argThat(contains('idevice_id')), workingDirectory: any, environment: any))
          .thenReturn(exitsHappy);

      ensureDirectoryExists(fs.path.join(homeDirPath, '.cocoapods', 'repos', 'master', 'README.md'));

      final ValidationResult result = await new IOSWorkflowTestTarget().validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      Xcode: () => xcode,
      ProcessManager: () => processManager,
    });
  });
}

final ProcessResult exitsHappy = new ProcessResult(
  1,     // pid
  0,     // exitCode
  '',    // stdout
  '',    // stderr
);

class MockXcode extends Mock implements Xcode {}
class MockProcessManager extends Mock implements ProcessManager {}

class IOSWorkflowTestTarget extends IOSWorkflow {
  @override
  bool hasPythonSixModule = true;

  @override
  bool hasHomebrew = true;

  @override
  bool hasIosDeploy = true;

  @override
  String iosDeployVersionText = '1.9.0';

  @override
  bool get hasIDeviceInstaller => true;

  @override
  bool hasCocoaPods = true;

  @override
  String cocoaPodsVersionText = '1.2.0';
}
