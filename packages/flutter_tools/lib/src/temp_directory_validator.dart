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
    try {
      final Directory tempDir = tempDirectory;
      messages.add(ValidationMessage('Valid temporary directory at: ${tempDir.path}'));
      return ValidationResult(ValidationType.installed, messages);
    } on FileSystemException catch (e){
      messages.add(ValidationMessage.hint('Try creating the directory: ${e.path}'));
      return ValidationResult(ValidationType.missing, messages);
    }
  }

  Directory get tempDirectory => _fileSystem.systemTempDirectory;
}
