// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/cocoapods_validator.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('CocoaPods validation', () {
    MockCocoaPods cocoaPods;

    setUp(() {
      cocoaPods = MockCocoaPods();
      when(cocoaPods.evaluateCocoaPodsInstallation)
          .thenAnswer((_) async => CocoaPodsStatus.recommended);
      when(cocoaPods.isCocoaPodsInitialized).thenAnswer((_) async => true);
      when(cocoaPods.cocoaPodsVersionText).thenAnswer((_) async => '1.8.0');
    });

    testUsingContext('Emits installed status when CocoaPods is installed', () async {
      const CocoaPodsValidator workflow = CocoaPodsValidator();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits missing status when CocoaPods is not installed', () async {
      when(cocoaPods.evaluateCocoaPodsInstallation)
          .thenAnswer((_) async => CocoaPodsStatus.notInstalled);
      const CocoaPodsValidator workflow = CocoaPodsValidator();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when CocoaPods is installed with unknown version', () async {
      when(cocoaPods.evaluateCocoaPodsInstallation)
          .thenAnswer((_) async => CocoaPodsStatus.unknownVersion);
      const CocoaPodsValidator workflow = CocoaPodsValidator();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when CocoaPods is not initialized', () async {
      when(cocoaPods.isCocoaPodsInitialized).thenAnswer((_) async => false);
      const CocoaPodsValidator workflow = CocoaPodsValidator();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });

    testUsingContext('Emits partial status when CocoaPods version is too low', () async {
      when(cocoaPods.evaluateCocoaPodsInstallation)
          .thenAnswer((_) async => CocoaPodsStatus.belowRecommendedVersion);
      const String currentVersion = '1.4.0';
      when(cocoaPods.cocoaPodsVersionText)
          .thenAnswer((_) async => currentVersion);
      const String recommendedVersion = '1.8.0';
      when(cocoaPods.cocoaPodsRecommendedVersion)
          .thenAnswer((_) => recommendedVersion);
      const CocoaPodsValidator workflow = CocoaPodsValidator();
      final ValidationResult result = await workflow.validate();
      expect(result.type, ValidationType.partial);
      expect(result.messages.length, 1);
      final ValidationMessage message = result.messages.first;
      expect(message.type, ValidationMessageType.hint);
      expect(message.message, contains('CocoaPods $currentVersion out of date'));
      expect(message.message, contains('($recommendedVersion is recommended)'));
    }, overrides: <Type, Generator>{
      CocoaPods: () => cocoaPods,
    });
  });
}

class MockCocoaPods extends Mock implements CocoaPods {}
