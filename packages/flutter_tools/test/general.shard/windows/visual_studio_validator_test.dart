// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/user_messages.dart' hide userMessages;
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:flutter_tools/src/windows/visual_studio_validator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

final UserMessages userMessages = UserMessages();

void main() {
  group('Visual Studio validation', () {
    late FakeVisualStudio fakeVisualStudio;

    setUp(() {
      fakeVisualStudio = FakeVisualStudio();
    });

    // Assigns default values for a complete VS installation with necessary components.
    void configureMockVisualStudioAsInstalled() {
      fakeVisualStudio.isPrerelease = false;
      fakeVisualStudio.isRebootRequired = false;
      fakeVisualStudio.fullVersion = '16.2';
      fakeVisualStudio.displayName = 'Visual Studio Community 2019';
      fakeVisualStudio.windows10SDKVersion = '10.0.18362.0';
    }

    // Assigns default values for a complete VS installation that is too old.
    void configureMockVisualStudioAsTooOld() {
      fakeVisualStudio.isAtLeastMinimumVersion = false;
      fakeVisualStudio.isPrerelease = false;
      fakeVisualStudio.isRebootRequired = false;
      fakeVisualStudio.fullVersion = '15.1';
      fakeVisualStudio.displayName = 'Visual Studio Community 2017';
      fakeVisualStudio.windows10SDKVersion = '10.0.17763.0';
    }

    // Assigns default values for a missing VS installation.
    void configureMockVisualStudioAsNotInstalled() {
      fakeVisualStudio.isInstalled = false;
      fakeVisualStudio.isAtLeastMinimumVersion = false;
      fakeVisualStudio.isPrerelease = false;
      fakeVisualStudio.isComplete = false;
      fakeVisualStudio.isLaunchable = false;
      fakeVisualStudio.isRebootRequired = false;
      fakeVisualStudio.hasNecessaryComponents = false;
      fakeVisualStudio.windows10SDKVersion = null;
    }

    testWithoutContext('Emits a message when Visual Studio is a pre-release version', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: fakeVisualStudio,
      );
      configureMockVisualStudioAsInstalled();
      fakeVisualStudio.isPrerelease = true;

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage(userMessages.visualStudioIsPrerelease);

      expect(result.messages.contains(expectedMessage), true);
    });

    testWithoutContext('Emits a partial status when Visual Studio installation is incomplete', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: fakeVisualStudio,
      );
      configureMockVisualStudioAsInstalled();
      fakeVisualStudio.isComplete = false;

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioIsIncomplete);

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits a partial status when Visual Studio installation needs rebooting', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: fakeVisualStudio,
      );
      configureMockVisualStudioAsInstalled();
      fakeVisualStudio.isRebootRequired = true;

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioRebootRequired);

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits a partial status when Visual Studio installation is not launchable', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: fakeVisualStudio,
      );
      configureMockVisualStudioAsInstalled();
      fakeVisualStudio.isLaunchable = false;

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(userMessages.visualStudioNotLaunchable);

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits partial status when Visual Studio is installed but too old', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: fakeVisualStudio,
      );
      configureMockVisualStudioAsTooOld();

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(
        userMessages.visualStudioTooOld(
          fakeVisualStudio.minimumVersionDescription,
          fakeVisualStudio.workloadDescription,
        ),
      );

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits partial status when Visual Studio is installed without necessary components', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: fakeVisualStudio,
      );
      configureMockVisualStudioAsInstalled();
      fakeVisualStudio.hasNecessaryComponents = false;
      final ValidationResult result = await validator.validate();

      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits partial status when Visual Studio is installed but the SDK cannot be found', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: fakeVisualStudio,
      );
      configureMockVisualStudioAsInstalled();
      fakeVisualStudio.windows10SDKVersion = null;
      final ValidationResult result = await validator.validate();

      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits installed status when Visual Studio is installed with necessary components', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: fakeVisualStudio,
      );
      configureMockVisualStudioAsInstalled();

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedDisplayNameMessage = ValidationMessage(
        userMessages.visualStudioVersion(fakeVisualStudio.displayName!, fakeVisualStudio.fullVersion!));

      expect(result.messages.contains(expectedDisplayNameMessage), true);
      expect(result.type, ValidationType.installed);
    });

    testWithoutContext('Emits missing status when Visual Studio is not installed', () async {
      final VisualStudioValidator validator = VisualStudioValidator(
        userMessages: userMessages,
        visualStudio: fakeVisualStudio,
      );
      configureMockVisualStudioAsNotInstalled();

      final ValidationResult result = await validator.validate();
      final ValidationMessage expectedMessage = ValidationMessage.error(
        userMessages.visualStudioMissing(
          fakeVisualStudio.workloadDescription,
        ),
      );

      expect(result.messages.contains(expectedMessage), true);
      expect(result.type, ValidationType.missing);
    });
  });
}

class FakeVisualStudio extends Fake implements VisualStudio {
  @override
  final String installLocation = 'bogus';

  @override
  final String displayVersion = 'version';

  @override
  final String minimumVersionDescription = '2019';

  @override
  List<String> necessaryComponentDescriptions() => <String>['A', 'B'];

  @override
  bool isInstalled = true;

  @override
  bool isAtLeastMinimumVersion = true;

  @override
  bool isPrerelease = true;

  @override
  bool isComplete = true;

  @override
  bool isLaunchable = true;

  @override
  bool isRebootRequired = true;

  @override
  bool hasNecessaryComponents = true;

  @override
  String? fullVersion;

  @override
  String? displayName;

  String? windows10SDKVersion;

  @override
  String? getWindows10SDKVersion() => windows10SDKVersion;

  @override
  String get workloadDescription => 'Desktop development';
}
