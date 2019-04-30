// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/io.dart';
import '../base/process_manager.dart';
import '../doctor.dart';

/// A validator that checks for GCC and the correct gtk version.
class LinuxDoctorValidator extends DoctorValidator {
  const LinuxDoctorValidator() : super('Linux toolchain - develop for Linux desktop applications');

  @override
  Future<ValidationResult> validate() async {
    ValidationType validationType = ValidationType.installed;
    final List<ValidationMessage> messages = <ValidationMessage>[];
    /// Check for some version of GCC.
    final ProcessResult gccResult = await processManager.run(const <String>[
      'g++',
      '--version',
    ]);
    if (gccResult.exitCode != 0) {
      validationType = ValidationType.missing;
      messages.add(ValidationMessage.error('GCC executable missing'));
    } else {
      messages.add(ValidationMessage(gccResult.stdout));
    }

    /// Check for the correct version of gtk.
    final ProcessResult gtkResult = await processManager.run(const <String>[
      'pkg-config',
      '--exists',
      '--print-errors',
      'gtk+-3.0',
    ]);
    if (gtkResult.exitCode != 0) {
      validationType = ValidationType.missing;
      messages.add(ValidationMessage.error(gtkResult.stdout));
    } else {
      messages.add(ValidationMessage('GTK installed and up to date'));
    }

    return ValidationResult(validationType, messages);
  }
}
