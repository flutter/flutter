// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:flutter_tools/src/windows/visual_studio_validator.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class MockVisualStudio extends Mock implements VisualStudio {}

void main() {
  group('Visual Studio validation', () {
    MockVisualStudio mockVisualStudio;

    setUp(() {
      mockVisualStudio = MockVisualStudio();
      // Mock a valid VS installation.
      when(mockVisualStudio.isInstalled).thenReturn(true);
      when(mockVisualStudio.isPrerelease).thenReturn(false);
      when(mockVisualStudio.isComplete).thenReturn(true);
      when(mockVisualStudio.isLaunchable).thenReturn(true);
      when(mockVisualStudio.isRebootRequired).thenReturn(false);
      when(mockVisualStudio.hasNecessaryComponents).thenReturn(true);
    });

    testUsingContext('Emits a message when Visual Studio is a pre-release version', () async {
      when(visualStudio.isPrerelease).thenReturn(true);

      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage(userMessages.visualStudioIsPrerelease);
      expect(result.messages.contains(expectedMessage), true);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits missing status when Visual Studio is not installed', () async {
      when(visualStudio.isInstalled).thenReturn(false);
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits a partial status when Visual Studio installation is incomplete', () async {
      when(visualStudio.isComplete).thenReturn(false);

      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioIsIncomplete);
      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits a partial status when Visual Studio installation needs rebooting', () async {
      when(visualStudio.isRebootRequired).thenReturn(true);

      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioRebootRequired);
      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits a partial status when Visual Studio installation is not launchable', () async {
      when(visualStudio.isLaunchable).thenReturn(false);

      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioNotLaunchable);
      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });


    testUsingContext('Emits partial status when Visual Studio is installed without necessary components', () async {
      when(visualStudio.hasNecessaryComponents).thenReturn(false);
      when(visualStudio.workloadDescription).thenReturn('Desktop development');
      when(visualStudio.necessaryComponentDescriptions(any)).thenReturn(<String>['A', 'B']);
      when(visualStudio.fullVersion).thenReturn('15.1');
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits installed status when Visual Studio is installed with necessary components', () async {
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits missing status when Visual Studio is not installed', () async {
      when(visualStudio.isInstalled).thenReturn(false);
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioMissing);
      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });
  });
}
