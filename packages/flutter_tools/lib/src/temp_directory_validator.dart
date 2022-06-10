// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/file_system.dart';
import 'base/io.dart';
import 'base/platform.dart';
import 'doctor_validator.dart';
import 'features.dart';

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


    return ValidationResult(
      availabilityResults.length == _requiredHosts.length
          ? ValidationType.notAvailable
          : ValidationType.partial,
      messages,
    );
  }
}