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
      // Default values regardless of whether VS is installed or not.
      when(mockVisualStudio.workloadDescription).thenReturn('Desktop development');
      when(mockVisualStudio.necessaryComponentDescriptions(any)).thenReturn(<String>['A', 'B']);
    });

    // Assigns default values for a complete VS installation with necessary components.
    void _configureMockVisualStudioAsInstalled() {
      when(mockVisualStudio.isInstalled).thenReturn(true);
      when(mockVisualStudio.isPrerelease).thenReturn(false);
      when(mockVisualStudio.isComplete).thenReturn(true);
      when(mockVisualStudio.isLaunchable).thenReturn(true);
      when(mockVisualStudio.isRebootRequired).thenReturn(false);
      when(mockVisualStudio.hasNecessaryComponents).thenReturn(true);
      when(mockVisualStudio.fullVersion).thenReturn('15.1');
      when(mockVisualStudio.displayName).thenReturn('Visual Studio Community 2019');
    }

    // Assigns default values for a missing VS installation.
    void _configureMockVisualStudioAsNotInstalled() {
      when(mockVisualStudio.isInstalled).thenReturn(false);
      when(mockVisualStudio.isPrerelease).thenReturn(false);
      when(mockVisualStudio.isComplete).thenReturn(false);
      when(mockVisualStudio.isLaunchable).thenReturn(false);
      when(mockVisualStudio.isRebootRequired).thenReturn(false);
      when(mockVisualStudio.hasNecessaryComponents).thenReturn(false);
    }

    testUsingContext('Emits a message when Visual Studio is a pre-release version', () async {
      _configureMockVisualStudioAsInstalled();
      when(visualStudio.isPrerelease).thenReturn(true);

      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage(userMessages.visualStudioIsPrerelease);
      expect(result.messages.contains(expectedMessage), true);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits a partial status when Visual Studio installation is incomplete', () async {
      _configureMockVisualStudioAsInstalled();
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
      _configureMockVisualStudioAsInstalled();
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
      _configureMockVisualStudioAsInstalled();
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
      _configureMockVisualStudioAsInstalled();
      when(visualStudio.hasNecessaryComponents).thenReturn(false);
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits installed status when Visual Studio is installed with necessary components', () async {
      _configureMockVisualStudioAsInstalled();
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedDisplayNameMessage = ValidationMessage(
        userMessages.visualStudioVersion(visualStudio.displayName, visualStudio.fullVersion));
      expect(result.messages.contains(expectedDisplayNameMessage), true);
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits missing status when Visual Studio is not installed', () async {
      _configureMockVisualStudioAsNotInstalled();
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(
        userMessages.visualStudioMissing(
          visualStudio.workloadDescription,
          visualStudio.necessaryComponentDescriptions(validator.majorVersion),
        ),
      );
      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });
  });
}
