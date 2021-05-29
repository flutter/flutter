// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/user_messages.dart' hide userMessages;
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:flutter_tools/src/windows/visual_studio_validator.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';

final UserMessages userMessages = UserMessages();

void main() {
  group('Visual Studio validation', () {
    MockVisualStudio mockVisualStudio;

    setUp(() {
      mockVisualStudio = MockVisualStudio();
      // Default values regardless of whether VS is installed or not.
      when(mockVisualStudio.workloadDescription).thenReturn('Desktop development');
      when(mockVisualStudio.minimumVersionDescription).thenReturn('2019');
      when(mockVisualStudio.necessaryComponentDescriptions()).thenReturn(<String>['A', 'B']);
    });

    // Assigns default values for a complete VS installation with necessary components.
    void _configureMockVisualStudioAsInstalled() {
      when(mockVisualStudio.isInstalled).thenReturn(true);
      when(mockVisualStudio.isAtLeastMinimumVersion).thenReturn(true);
      when(mockVisualStudio.isPrerelease).thenReturn(false);
      when(mockVisualStudio.isComplete).thenReturn(true);
      when(mockVisualStudio.isLaunchable).thenReturn(true);
      when(mockVisualStudio.isRebootRequired).thenReturn(false);
      when(mockVisualStudio.hasNecessaryComponents).thenReturn(true);
      when(mockVisualStudio.fullVersion).thenReturn('16.2');
      when(mockVisualStudio.displayName).thenReturn('Visual Studio Community 2019');
      when(mockVisualStudio.getWindows10SDKVersion()).thenReturn('10.0.18362.0');
    }

    // Assigns default values for a complete VS installation that is too old.
    void _configureMockVisualStudioAsTooOld() {
      when(mockVisualStudio.isInstalled).thenReturn(true);
      when(mockVisualStudio.isAtLeastMinimumVersion).thenReturn(false);
      when(mockVisualStudio.isPrerelease).thenReturn(false);
      when(mockVisualStudio.isComplete).thenReturn(true);
      when(mockVisualStudio.isLaunchable).thenReturn(true);
      when(mockVisualStudio.isRebootRequired).thenReturn(false);
      when(mockVisualStudio.hasNecessaryComponents).thenReturn(true);
      when(mockVisualStudio.fullVersion).thenReturn('15.1');
      when(mockVisualStudio.displayName).thenReturn('Visual Studio Community 2017');
      when(mockVisualStudio.getWindows10SDKVersion()).thenReturn('10.0.17763.0');
    }

    // Assigns default values for a missing VS installation.
    void _configureMockVisualStudioAsNotInstalled() {
      when(mockVisualStudio.isInstalled).thenReturn(false);
      when(mockVisualStudio.isAtLeastMinimumVersion).thenReturn(false);
      when(mockVisualStudio.isPrerelease).thenReturn(false);
      when(mockVisualStudio.isComplete).thenReturn(false);
      when(mockVisualStudio.isLaunchable).thenReturn(false);
      when(mockVisualStudio.isRebootRequired).thenReturn(false);
      when(mockVisualStudio.hasNecessaryComponents).thenReturn(false);
      when(mockVisualStudio.getWindows10SDKVersion()).thenReturn(null);
    }

    testWithoutContext('Emits a message when Visual Studio is a pre-release version', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: mockVisualStudio,
      );
      _configureMockVisualStudioAsInstalled();
      when(mockVisualStudio.isPrerelease).thenReturn(true);

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage(userMessages.visualStudioIsPrerelease);

      expect(result.messages.contains(expectedMessage), true);
    });

    testWithoutContext('Emits a partial status when Visual Studio installation is incomplete', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: mockVisualStudio,
      );
      _configureMockVisualStudioAsInstalled();
      when(mockVisualStudio.isComplete).thenReturn(false);

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioIsIncomplete);

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits a partial status when Visual Studio installation needs rebooting', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: mockVisualStudio,
      );
      _configureMockVisualStudioAsInstalled();
      when(mockVisualStudio.isRebootRequired).thenReturn(true);

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioRebootRequired);

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits a partial status when Visual Studio installation is not launchable', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: mockVisualStudio,
      );
      _configureMockVisualStudioAsInstalled();
      when(mockVisualStudio.isLaunchable).thenReturn(false);

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioNotLaunchable);

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits partial status when Visual Studio is installed but too old', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: mockVisualStudio,
      );
      _configureMockVisualStudioAsTooOld();

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(
        userMessages.visualStudioTooOld(
          mockVisualStudio.minimumVersionDescription,
          mockVisualStudio.workloadDescription,
        ),
      );

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits partial status when Visual Studio is installed without necessary components', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: mockVisualStudio,
      );
      _configureMockVisualStudioAsInstalled();
      when(mockVisualStudio.hasNecessaryComponents).thenReturn(false);
      final ValidationResult result = await validator.validate();

      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits partial status when Visual Studio is installed but the SDK cannot be found', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: mockVisualStudio,
      );
      _configureMockVisualStudioAsInstalled();
      when(mockVisualStudio.getWindows10SDKVersion()).thenReturn(null);
      final ValidationResult result = await validator.validate();

      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits installed status when Visual Studio is installed with necessary components', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: mockVisualStudio,
      );
      _configureMockVisualStudioAsInstalled();

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedDisplayNameMessage = ValidationMessage(
        userMessages.visualStudioVersion(mockVisualStudio.displayName, mockVisualStudio.fullVersion));

      expect(result.messages.contains(expectedDisplayNameMessage), true);
      expect(result.type, ValidationType.installed);
    });

    testWithoutContext('Emits missing status when Visual Studio is not installed', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: mockVisualStudio,
      );
      _configureMockVisualStudioAsNotInstalled();

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(
        userMessages.visualStudioMissing(
          mockVisualStudio.workloadDescription,
        ),
      );

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.missing);
    });
  });
}

class MockVisualStudio extends Mock implements VisualStudio {}
