// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/file_system.dart';
import 'doctor_validator.dart';

class TempDirectoryValidator extends DoctorValidator {
  TempDirectoryValidator({
    required FileSystem fileSystem
  }) : _fileSystem = fileSystem, super('Temp Directory');

  final FileSystem _fileSystem;

  @override
  String get slowWarning => 'Temporary Directory Validator check is taking a long time...';

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    if (!_fileSystem.systemTempDirectory.existsSync()) {
      messages.add(const ValidationMessage('Temp directory missing'));
      return ValidationResult(ValidationType.missing, messages);
    }

    messages.add(const ValidationMessage('Valid temp directory'));
    return ValidationResult(ValidationType.installed, messages);
  }
}