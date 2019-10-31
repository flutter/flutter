// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/linux/linux_doctor.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group(LinuxDoctorValidator, () {
    ProcessManager processManager;
    LinuxDoctorValidator linuxDoctorValidator;

    setUp(() {
      processManager = MockProcessManager();
      linuxDoctorValidator = LinuxDoctorValidator();
    });

    testUsingContext('Returns full validation when clang++ and make are availibe', () async {
      when(processManager.run(<String>['clang++', '--version'])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: 'clang version 4.0.1-10 (tags/RELEASE_401/final)\njunk',
          exitCode: 0,
        );
      });
      when(processManager.run(<String>[
        'make',
        '--version',
      ])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: 'GNU Make 4.1\njunk',
          exitCode: 0,
        );
      });

      final ValidationResult result = await linuxDoctorValidator.validate();
      expect(result.type, ValidationType.installed);
      expect(result.messages, <ValidationMessage>[
        ValidationMessage('clang++ 4.0.1'),
        ValidationMessage('GNU Make 4.1'),
      ]);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });

    testUsingContext('Returns partial validation when clang++ version is too old', () async {
      when(processManager.run(<String>['clang++', '--version'])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: 'clang version 2.0.1-10 (tags/RELEASE_401/final)\njunk',
          exitCode: 0,
        );
      });
      when(processManager.run(<String>[
        'make',
        '--version',
      ])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: 'GNU Make 4.1\njunk',
          exitCode: 0,
        );
      });

      final ValidationResult result = await linuxDoctorValidator.validate();
      expect(result.type, ValidationType.partial);
      expect(result.messages, <ValidationMessage>[
        ValidationMessage.error('clang++ 2.0.1 is below minimum version of 3.4.0'),
        ValidationMessage('GNU Make 4.1'),
      ]);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });

    testUsingContext('Returns mising validation when make is not availible', () async {
      when(processManager.run(<String>['clang++', '--version'])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: 'clang version 4.0.1-10 (tags/RELEASE_401/final)\njunk',
          exitCode: 0,
        );
      });
      when(processManager.run(<String>[
        'make',
        '--version',
      ])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: '',
          exitCode: 1,
        );
      });

      final ValidationResult result = await linuxDoctorValidator.validate();
      expect(result.type, ValidationType.missing);
      expect(result.messages, <ValidationMessage>[
        ValidationMessage('clang++ 4.0.1'),
        ValidationMessage.error('make is not installed'),
      ]);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });

    testUsingContext('Returns mising validation when clang++ is not availible', () async {
      when(processManager.run(<String>['clang++', '--version'])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: '',
          exitCode: 1,
        );
      });
      when(processManager.run(<String>[
        'make',
        '--version',
      ])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: 'GNU Make 4.1\njunk',
          exitCode: 0,
        );
      });

      final ValidationResult result = await linuxDoctorValidator.validate();
      expect(result.type, ValidationType.missing);
      expect(result.messages, <ValidationMessage>[
        ValidationMessage.error('clang++ is not installed'),
        ValidationMessage('GNU Make 4.1'),
      ]);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });


    testUsingContext('Returns missing validation when clang and make are not availible', () async {
      when(processManager.run(<String>['clang++', '--version'])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: '',
          exitCode: 1,
        );
      });
      when(processManager.run(<String>[
        'make',
        '--version',
      ])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: '',
          exitCode: 1,
        );
      });

      final ValidationResult result = await linuxDoctorValidator.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
