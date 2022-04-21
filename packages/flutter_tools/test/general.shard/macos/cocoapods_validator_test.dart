// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/cocoapods_validator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group('CocoaPods validation', () {
    testWithoutContext('Emits installed status when CocoaPods is installed', () async {
      final CocoaPodsValidator workflow = CocoaPodsValidator(FakeCocoaPods(CocoaPodsStatus.recommended, '1000.0.0'), UserMessages());
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.installed);
    });

    testWithoutContext('Emits missing status when CocoaPods is not installed', () async {
      final CocoaPodsValidator workflow = CocoaPodsValidator(FakeCocoaPods(CocoaPodsStatus.notInstalled), UserMessages());
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.missing);
    });

    testWithoutContext('Emits partial status when CocoaPods is installed with unknown version', () async {
      final CocoaPodsValidator workflow = CocoaPodsValidator(FakeCocoaPods(CocoaPodsStatus.unknownVersion), UserMessages());
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    });

    testWithoutContext('Emits partial status when CocoaPods version is too low', () async {
      const String currentVersion = '1.4.0';
      final CocoaPods fakeCocoaPods = FakeCocoaPods(CocoaPodsStatus.belowRecommendedVersion, currentVersion);
      final CocoaPodsValidator workflow = CocoaPodsValidator(fakeCocoaPods, UserMessages());
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
      expect(result.messages.length, 1);
      final ValidationMessage message = result.messages.first;
      expect(message.type, ValidationMessageType.hint);
      expect(message.message, contains('CocoaPods $currentVersion out of date'));
      expect(message.message, contains('(1.11.0 is recommended)'));
    });
  });
}

class FakeCocoaPods extends Fake implements CocoaPods {
  FakeCocoaPods(this._evaluateCocoaPodsInstallation, [this._cocoaPodsVersionText]);

  @override
  Future<CocoaPodsStatus> get evaluateCocoaPodsInstallation async => _evaluateCocoaPodsInstallation;
  final CocoaPodsStatus _evaluateCocoaPodsInstallation;

  @override
  Future<String?> get cocoaPodsVersionText async => _cocoaPodsVersionText;
  final String? _cocoaPodsVersionText;
}
