// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/package_config.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('DoctorResultEvent sends usage event for each sub validator', () async {
    final Usage usage = MockUsage();
    final GroupedValidator groupedValidator = FakeGroupedValidator(<DoctorValidator>[
      FakeDoctorValidator('a'),
      FakeDoctorValidator('b'),
      FakeDoctorValidator('c'),
    ]);
    final ValidationResult result = await groupedValidator.validate();

    final DoctorResultEvent doctorResultEvent = DoctorResultEvent(
      validator: groupedValidator,
      result: result,
      flutterUsage: usage,
    );

    expect(doctorResultEvent.send, returnsNormally);

    verify(usage.sendEvent('doctor-result', any, label: anyNamed('label'))).called(3);
  });

  testWithoutContext('DoctorResultEvent does not crash if a synthetic crash result was used instead'
    ' of validation. This happens when a grouped validator throws an exception, causing subResults to never '
    ' be instantiated.', () async {
    final Usage usage = MockUsage();
    final GroupedValidator groupedValidator = FakeGroupedValidator(<DoctorValidator>[
      FakeDoctorValidator('a'),
      FakeDoctorValidator('b'),
      FakeDoctorValidator('c'),
    ]);
    final ValidationResult result = ValidationResult.crash(Object());

    final DoctorResultEvent doctorResultEvent = DoctorResultEvent(
      validator: groupedValidator,
      result: result,
      flutterUsage: usage,
    );

    expect(doctorResultEvent.send, returnsNormally);

    verify(usage.sendEvent('doctor-result', any, label: anyNamed('label'))).called(1);
  });

  testWithoutContext('Reports null safe analytics events', () {
    final Usage usage = MockUsage();
    final PackageConfig packageConfig = PackageConfig(<Package>[
      Package('foo', Uri.parse('file:///foo/'), languageVersion: LanguageVersion(2, 12)),
      Package('bar', Uri.parse('file:///fizz/'), languageVersion: LanguageVersion(2, 1)),
      Package('baz', Uri.parse('file:///bar/'), languageVersion: LanguageVersion(2, 2)),
    ]);

    NullSafetyAnalysisEvent(
      packageConfig,
      NullSafetyMode.sound,
      'foo',
      usage,
    ).send();

    verify(usage.sendEvent(NullSafetyAnalysisEvent.kNullSafetyCategory, 'runtime-mode', label: 'NullSafetyMode.sound')).called(1);
    verify(usage.sendEvent(NullSafetyAnalysisEvent.kNullSafetyCategory, 'stats', parameters: <String, String>{
      'cd49': '1', 'cd50': '3',
    })).called(1);
    verify(usage.sendEvent(NullSafetyAnalysisEvent.kNullSafetyCategory, 'language-version', label: '2.12')).called(1);
  });

  testWithoutContext('Does not crash if main package is missing', () {
    final Usage usage = MockUsage();
    final PackageConfig packageConfig = PackageConfig(<Package>[
      Package('foo', Uri.parse('file:///foo/lib/'), languageVersion: LanguageVersion(2, 12)),
      Package('bar', Uri.parse('file:///fizz/lib/'), languageVersion: LanguageVersion(2, 1)),
      Package('baz', Uri.parse('file:///bar/lib/'), languageVersion: LanguageVersion(2, 2)),
    ]);

    NullSafetyAnalysisEvent(
      packageConfig,
      NullSafetyMode.sound,
      'something-unrelated',
      usage,
    ).send();

    verify(usage.sendEvent(NullSafetyAnalysisEvent.kNullSafetyCategory, 'runtime-mode', label: 'NullSafetyMode.sound')).called(1);
    verify(usage.sendEvent(NullSafetyAnalysisEvent.kNullSafetyCategory, 'stats', parameters: <String, String>{
      'cd49': '1', 'cd50': '3',
    })).called(1);
    verifyNever(usage.sendEvent(NullSafetyAnalysisEvent.kNullSafetyCategory, 'language-version', label: anyNamed('label')));
  });

  testWithoutContext('a null language version is treated as unmigrated', () {
    final Usage usage = MockUsage();
    final PackageConfig packageConfig = PackageConfig(<Package>[
      Package('foo', Uri.parse('file:///foo/lib/'), languageVersion: null),
    ]);

    NullSafetyAnalysisEvent(
      packageConfig,
      NullSafetyMode.sound,
      'something-unrelated',
      usage,
    ).send();

    verify(usage.sendEvent(NullSafetyAnalysisEvent.kNullSafetyCategory, 'runtime-mode', label: 'NullSafetyMode.sound')).called(1);
    verify(usage.sendEvent(NullSafetyAnalysisEvent.kNullSafetyCategory, 'stats', parameters: <String, String>{
      'cd49': '0', 'cd50': '1',
    })).called(1);
    verifyNever(usage.sendEvent(NullSafetyAnalysisEvent.kNullSafetyCategory, 'language-version', label: anyNamed('label')));
  });
}

class FakeGroupedValidator extends GroupedValidator {
  FakeGroupedValidator(List<DoctorValidator> subValidators) : super(subValidators);
}

class FakeDoctorValidator extends DoctorValidator {
  FakeDoctorValidator(String title) : super(title);

  @override
  Future<ValidationResult> validate() async {
    return ValidationResult.crash(Object());
  }
}

class MockUsage extends Mock implements Usage {}
