// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/mac.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../context.dart';

void main() {
  group('iOS Workflow validation', () {
    MockXcode xcode;
    setUp(() {
      xcode = new MockXcode();
    });

    testUsingContext('Emit missing status when nothing is installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..hasPythonSixModule = false
        ..hasHomebrew = false
        ..hasIosDeploy = false;
      ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when Xcode is not installed', () async {
      when(xcode.isInstalled).thenReturn(false);
      IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when Xcode version too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 7.0.1\nBuild version 7C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(false);
      when(xcode.eulaSigned).thenReturn(true);
      IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when Xcode EULA not signed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(false);
      IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget();
      ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when python six not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..hasPythonSixModule = false;
      ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when homebrew not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..hasHomebrew = false;
      ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when ios-deploy is not installed', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..hasIosDeploy = false;
      ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Emits partial status when ios-deploy version is too low', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      IOSWorkflowTestTarget workflow = new IOSWorkflowTestTarget()
        ..iosDeployVersionText = '1.8.0';
      ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });

    testUsingContext('Succeeds when all checks pass', () async {
      when(xcode.isInstalled).thenReturn(true);
      when(xcode.xcodeVersionText)
          .thenReturn('Xcode 8.2.1\nBuild version 8C1002\n');
      when(xcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      when(xcode.eulaSigned).thenReturn(true);
      ValidationResult result = await new IOSWorkflowTestTarget().validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{ Xcode: () => xcode });
  });
}

class MockXcode extends Mock implements Xcode {}

class IOSWorkflowTestTarget extends IOSWorkflow {
  @override
  bool hasPythonSixModule = true;

  @override
  bool hasHomebrew = true;

  @override
  bool hasIosDeploy = true;

  @override
  String iosDeployVersionText = '1.9.0';
}
