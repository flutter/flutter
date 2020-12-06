// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';

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
