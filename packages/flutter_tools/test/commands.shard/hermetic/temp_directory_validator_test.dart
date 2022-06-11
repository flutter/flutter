// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/temp_directory_validator.dart';

import '../../src/common.dart';

class FakeTempDirectoryValidator extends TempDirectoryValidator {
  FakeTempDirectoryValidator({required super.fileSystem});

  @override
  Directory get tempDirectory => throw const FileSystemException();
}

void main() {
  testWithoutContext('temporary director validator pass', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final TempDirectoryValidator tempDirectoryValidator = TempDirectoryValidator(fileSystem: fileSystem);

    final ValidationResult result = await tempDirectoryValidator.validate();
    expect(result.messages[0].message, contains('Valid temporary directory'));
  });

  testWithoutContext('temporary director validator fail', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final FakeTempDirectoryValidator tempDirectoryValidator = FakeTempDirectoryValidator(fileSystem: fileSystem);

    final ValidationResult result = await tempDirectoryValidator.validate();
    expect(result.messages[0].message, contains('Try creating the directory'));
  });
}
