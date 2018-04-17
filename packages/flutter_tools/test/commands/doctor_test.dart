// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/vscode/vscode.dart';
import 'package:flutter_tools/src/vscode/vscode_validator.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('doctor', () {
    testUsingContext('intellij validator', () async {
      const String installPath = '/path/to/intelliJ';
      final ValidationResult result = await new IntelliJValidatorTestTarget('Test', installPath).validate();
      expect(result.type, ValidationType.partial);
      expect(result.statusInfo, 'version test.test.test');
      expect(result.messages, hasLength(4));

      ValidationMessage message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('IntelliJ '));
      expect(message.message, 'IntelliJ at $installPath');

      message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Dart '));
      expect(message.message, 'Dart plugin version 162.2485');

      message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Flutter '));
      expect(message.message, contains('Flutter plugin version 0.1.3'));
      expect(message.message, contains('recommended minimum version'));
    });

    testUsingContext('vs code validator when both installed', () async {
      final ValidationResult result = await VsCodeValidatorTestTargets.installedWithExtension.validate();
      expect(result.type, ValidationType.installed);
      expect(result.statusInfo, 'version 1.2.3');
      expect(result.messages, hasLength(2));

      ValidationMessage message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('VS Code '));
      expect(message.message, 'VS Code at ${VsCodeValidatorTestTargets.validInstall}');

      message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Dart Code '));
      expect(message.message, 'Dart Code extension version 4.5.6');
    });

    testUsingContext('vs code validator when 64bit installed', () async {
      expect(VsCodeValidatorTestTargets.installedWithExtension64bit.title, 'VS Code, 64-bit edition');
      final ValidationResult result = await VsCodeValidatorTestTargets.installedWithExtension64bit.validate();
      expect(result.type, ValidationType.installed);
      expect(result.statusInfo, 'version 1.2.3');
      expect(result.messages, hasLength(2));

      ValidationMessage message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('VS Code '));
      expect(message.message, 'VS Code at ${VsCodeValidatorTestTargets.validInstall}');

      message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Dart Code '));
      expect(message.message, 'Dart Code extension version 4.5.6');
    });

    testUsingContext('vs code validator when extension missing', () async {
      final ValidationResult result = await VsCodeValidatorTestTargets.installedWithoutExtension.validate();
      expect(result.type, ValidationType.partial);
      expect(result.statusInfo, 'version 1.2.3');
      expect(result.messages, hasLength(2));

      ValidationMessage message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('VS Code '));
      expect(message.message, 'VS Code at ${VsCodeValidatorTestTargets.validInstall}');

      message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Dart Code '));
      expect(message.message, startsWith('Dart Code extension not installed'));
    });
  });

  group('doctor with fake validators', () {
    testUsingContext('validate non-verbose output format for run without issues', () async {
      expect(await new FakeQuietDoctor().diagnose(verbose: false), isTrue);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[✓] Passing Validator (with statusInfo)\n'
              '[✓] Another Passing Validator (with statusInfo)\n'
              '[✓] Validators are fun (with statusInfo)\n'
              '[✓] Four score and seven validators ago (with statusInfo)\n'
              '\n'
              '• No issues found!\n'
      ));
    });

    testUsingContext('validate non-verbose output format when only one category fails', () async {
      expect(await new FakeSinglePassingDoctor().diagnose(verbose: false), isTrue);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[!] Partial Validator with only a Hint\n'
              '    ! There is a hint here\n'
              '\n'
              '! Doctor found issues in 1 category.\n'
      ));
    });

    testUsingContext('validate non-verbose output format for a passing run', () async {
      expect(await new FakePassingDoctor().diagnose(verbose: false), isTrue);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[✓] Passing Validator (with statusInfo)\n'
              '[!] Partial Validator with only a Hint\n'
              '    ! There is a hint here\n'
              '[!] Partial Validator with Errors\n'
              '    ✗ A error message indicating partial installation\n'
              '    ! Maybe a hint will help the user\n'
              '[✓] Another Passing Validator (with statusInfo)\n'
              '\n'
              '! Doctor found issues in 2 categories.\n'
      ));
    });

    testUsingContext('validate non-verbose output format', () async {
      expect(await new FakeDoctor().diagnose(verbose: false), isFalse);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[✓] Passing Validator (with statusInfo)\n'
              '[✗] Missing Validator\n'
              '    ✗ A useful error message\n'
              '    ! A hint message\n'
              '[!] Partial Validator with only a Hint\n'
              '    ! There is a hint here\n'
              '[!] Partial Validator with Errors\n'
              '    ✗ A error message indicating partial installation\n'
              '    ! Maybe a hint will help the user\n'
              '\n'
              '! Doctor found issues in 3 categories.\n'
      ));
    });

    testUsingContext('validate verbose output format', () async {
      expect(await new FakeDoctor().diagnose(verbose: true), isFalse);
      expect(testLogger.statusText, equals(
              '[✓] Passing Validator (with statusInfo)\n'
              '    • A helpful message\n'
              '    • A second, somewhat longer helpful message\n'
              '\n'
              '[✗] Missing Validator\n'
              '    ✗ A useful error message\n'
              '    • A message that is not an error\n'
              '    ! A hint message\n'
              '\n'
              '[!] Partial Validator with only a Hint\n'
              '    ! There is a hint here\n'
              '    • But there is no error\n'
              '\n'
              '[!] Partial Validator with Errors\n'
              '    ✗ A error message indicating partial installation\n'
              '    ! Maybe a hint will help the user\n'
              '    • An extra message with some verbose details\n'
              '\n'
              '! Doctor found issues in 3 categories.\n'
      ));
    });
  });
}

class IntelliJValidatorTestTarget extends IntelliJValidator {
  IntelliJValidatorTestTarget(String title, String installPath) : super(title, installPath);

  @override
  String get pluginsPath => fs.path.join('test', 'data', 'intellij', 'plugins');

  @override
  String get version => 'test.test.test';
}

class PassingValidator extends DoctorValidator {
  PassingValidator(String name) : super(name);

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(new ValidationMessage('A helpful message'));
    messages.add(new ValidationMessage('A second, somewhat longer helpful message'));
    return new ValidationResult(ValidationType.installed, messages, statusInfo: 'with statusInfo');
  }
}

class MissingValidator extends DoctorValidator {
  MissingValidator(): super('Missing Validator');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(new ValidationMessage.error('A useful error message'));
    messages.add(new ValidationMessage('A message that is not an error'));
    messages.add(new ValidationMessage.hint('A hint message'));
    return new ValidationResult(ValidationType.missing, messages);
  }
}

class PartialValidatorWithErrors extends DoctorValidator {
  PartialValidatorWithErrors() : super('Partial Validator with Errors');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(new ValidationMessage.error('A error message indicating partial installation'));
    messages.add(new ValidationMessage.hint('Maybe a hint will help the user'));
    messages.add(new ValidationMessage('An extra message with some verbose details'));
    return new ValidationResult(ValidationType.partial, messages);
  }
}

class PartialValidatorWithHintsOnly extends DoctorValidator {
  PartialValidatorWithHintsOnly() : super('Partial Validator with only a Hint');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(new ValidationMessage.hint('There is a hint here'));
    messages.add(new ValidationMessage('But there is no error'));
    return new ValidationResult(ValidationType.partial, messages);
  }
}

/// A doctor that fails with a missing [ValidationResult].
class FakeDoctor extends Doctor {
  List<DoctorValidator> _validators;

  @override
  List<DoctorValidator> get validators {
    if (_validators == null) {
      _validators = <DoctorValidator>[];
      _validators.add(new PassingValidator('Passing Validator'));
      _validators.add(new MissingValidator());
      _validators.add(new PartialValidatorWithHintsOnly());
      _validators.add(new PartialValidatorWithErrors());
    }
    return _validators;
  }
}

/// A doctor that should pass, but still has issues in some categories.
class FakePassingDoctor extends Doctor {
  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    if (_validators == null) {
      _validators = <DoctorValidator>[];
      _validators.add(new PassingValidator('Passing Validator'));
      _validators.add(new PartialValidatorWithHintsOnly());
      _validators.add(new PartialValidatorWithErrors());
      _validators.add(new PassingValidator('Another Passing Validator'));
    }
    return _validators;
  }
}

/// A doctor that should pass, but still has 1 issue to test the singular of
/// categories.
class FakeSinglePassingDoctor extends Doctor {
  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    if (_validators == null) {
      _validators = <DoctorValidator>[];
      _validators.add(new PartialValidatorWithHintsOnly());
    }
    return _validators;
  }
}

/// A doctor that passes and has no issues anywhere.
class FakeQuietDoctor extends Doctor {
  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    if (_validators == null) {
      _validators = <DoctorValidator>[];
      _validators.add(new PassingValidator('Passing Validator'));
      _validators.add(new PassingValidator('Another Passing Validator'));
      _validators.add(new PassingValidator('Validators are fun'));
      _validators.add(new PassingValidator('Four score and seven validators ago'));
    }
    return _validators;
  }
}

class VsCodeValidatorTestTargets extends VsCodeValidator {
  static final String validInstall = fs.path.join('test', 'data', 'vscode', 'application');
  static final String validExtensions = fs.path.join('test', 'data', 'vscode', 'extensions');
  static final String missingExtensions = fs.path.join('test', 'data', 'vscode', 'notExtensions');
  VsCodeValidatorTestTargets._(String installDirectory, String extensionDirectory, {String edition}) 
    : super(new VsCode.fromDirectory(installDirectory, extensionDirectory, edition: edition));

  static VsCodeValidatorTestTargets get installedWithExtension =>
    new VsCodeValidatorTestTargets._(validInstall, validExtensions);

    static VsCodeValidatorTestTargets get installedWithExtension64bit =>
    new VsCodeValidatorTestTargets._(validInstall, validExtensions, edition: '64-bit edition');

  static VsCodeValidatorTestTargets get installedWithoutExtension =>
    new VsCodeValidatorTestTargets._(validInstall, missingExtensions);
}
