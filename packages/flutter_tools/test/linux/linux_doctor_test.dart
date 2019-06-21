// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/extension/doctor.dart';
import 'package:flutter_tools/src/linux/linux.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/mocks.dart';

void main() {
  group(LinuxDoctorDomain, () {
    ProcessManager processManager;
    LinuxExtension linuxExtension;

    setUp(() {
      processManager = MockProcessManager();
      linuxExtension = LinuxExtension()
        ..processManager = processManager;
    });

    test('Returns full validation when clang++ and make are availibe', () async {
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

      final ValidationResult result = await linuxExtension.doctorDomain.diagnose(<String, Object>{});
      expect(result.type, ValidationType.installed);
      expect(result.messages, const <ValidationMessage>[
        ValidationMessage('clang++ 4.0.1'),
        ValidationMessage('GNU Make 4.1'),
      ]);
    });

    test('Returns partial validation when clang++ version is too old', () async {
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

      final ValidationResult result = await linuxExtension.doctorDomain.diagnose(<String, Object>{});
      expect(result.type, ValidationType.partial);
      expect(result.messages, const <ValidationMessage>[
        ValidationMessage('clang++ 2.0.1 is below minimum version of 3.4.0', type: ValidationMessageType.error),
        ValidationMessage('GNU Make 4.1'),
      ]);
    });

    test('Returns mising validation when make is not availible', () async {
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

      final ValidationResult result = await linuxExtension.doctorDomain.diagnose(<String, Object>{});
      expect(result.type, ValidationType.missing);
      expect(result.messages, const <ValidationMessage>[
        ValidationMessage('clang++ 4.0.1'),
        ValidationMessage('make is not installed', type: ValidationMessageType.error)
      ]);
    });

    test('Returns mising validation when clang++ is not availible', () async {
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

      final ValidationResult result = await linuxExtension.doctorDomain.diagnose(<String, Object>{});
      expect(result.type, ValidationType.missing);
      expect(result.messages, const <ValidationMessage>[
        ValidationMessage('clang++ is not installed', type: ValidationMessageType.error),
        ValidationMessage('GNU Make 4.1'),
      ]);
    });

    test('Returns missing validation when clang and make are not availible', () async {
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

      final ValidationResult result = await linuxExtension.doctorDomain.diagnose(<String, Object>{});
      expect(result.type, ValidationType.missing);
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
