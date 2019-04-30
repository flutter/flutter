

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/linux/linux_doctor.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group(LinuxDoctorValidator, () {
    ProcessManager processManager;
    LinuxDoctorValidator linuxDoctorValidator;

    setUp(() {
      processManager = MockProcessManager();
      linuxDoctorValidator = LinuxDoctorValidator();
    });

    testUsingContext('Returns full validation when gcc and gtk are availibe', () async {
      when(processManager.run(<String>['g++', '--version'])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: 'Success',
          exitCode: 0,
        );
      });
      when(processManager.run(<String>[
        'pkg-config',
        '--exists',
        '--print-errors',
        'gtk+-3.0',
      ])).thenAnswer((_) async {
        return FakeProcessResult(
          stdout: 'Success',
          exitCode: 0,
        );
      });

      expect((await linuxDoctorValidator.validate()).type, ValidationType.installed);
    });

    testUsingContext('Returns partial validation when gcc and gtk are not availibe', () async {
      when(processManager.run(<String>['g++', '--version'])).thenAnswer((_) async {
        return FakeProcessResult(
          exitCode: 1,
        );
      });
      when(processManager.run(<String>[
        'pkg-config',
        '--exists',
        '--print-errors',
        'gtk+-3.0',
      ])).thenAnswer((_) async {
        return FakeProcessResult(
          exitCode: 1,
        );
      });

      expect((await linuxDoctorValidator.validate()).type, ValidationType.partial);
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
