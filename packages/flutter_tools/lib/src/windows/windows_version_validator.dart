// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import '../base/platform.dart';
import '../doctor_validator.dart';

class WindowsVersionValidator extends DoctorValidator {
  const WindowsVersionValidator({required Platform platform})
      : super('Windows Version');
  @override
  Future<ValidationResult> validate() async {
    return const ValidationResult(
      ValidationType.installed,
      <ValidationMessage>[
        ValidationMessage(
            'Installed version of Windows is version 10 or higher')
      ],
    );
  }
}
