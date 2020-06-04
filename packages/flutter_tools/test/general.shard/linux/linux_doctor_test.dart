// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/linux/linux_doctor.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testWithoutContext('Full validation when clang++ and Make are available',() async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['clang++', '--version'],
        stdout: 'clang version 4.0.1-10 (tags/RELEASE_401/final)\njunk',
      ),
      const FakeCommand(
        command: <String>['make', '--version'],
        stdout: 'GNU Make 4.1\njunk',
      ),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.installed);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang++ 4.0.1'),
      ValidationMessage('GNU Make 4.1'),
    ]);
  });

  testWithoutContext('Partial validation when clang++ version is too old', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['clang++', '--version'],
        stdout: 'clang version 2.0.1-10 (tags/RELEASE_401/final)\njunk',
      ),
      const FakeCommand(
        command: <String>['make', '--version'],
        stdout: 'GNU Make 4.1\njunk',
      ),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.partial);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage.error('clang++ 2.0.1 is below minimum version of 3.4.0'),
      ValidationMessage('GNU Make 4.1'),
    ]);
  });

  testWithoutContext('Missing validation when Make is not available', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['clang++', '--version'],
        stdout: 'clang version 4.0.1-10 (tags/RELEASE_401/final)\njunk',
      ),
      const FakeCommand(
        command: <String>['make', '--version'],
        exitCode: 1,
      ),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang++ 4.0.1'),
      ValidationMessage.error('make is not installed'),
    ]);
  });

  testWithoutContext('Missing validation when clang++ is not available', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['clang++', '--version'],
        exitCode: 1
      ),
      const FakeCommand(
        command: <String>['make', '--version'],
        stdout: 'GNU Make 4.1\njunk'
      ),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage.error('clang++ is not installed'),
      ValidationMessage('GNU Make 4.1'),
    ]);
  });

  testWithoutContext('Missing validation when clang++ and Make are not available', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['clang++', '--version'],
        exitCode: 1,
      ),
      const FakeCommand(
        command: <String>['make', '--version'],
        exitCode: 1,
      ),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
    );

    final ValidationResult result = await linuxDoctorValidator.validate();
    expect(result.type, ValidationType.missing);
  });
}
