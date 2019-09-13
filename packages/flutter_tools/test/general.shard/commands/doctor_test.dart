// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/proxy_validator.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/vscode/vscode.dart';
import 'package:flutter_tools/src/vscode/vscode_validator.dart';
import 'package:flutter_tools/src/web/workflow.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:quiver/testing/async.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

final Generator _kNoColorOutputPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorOutputPlatform,
};

void main() {
  MockProcessManager mockProcessManager;

  setUp(() {
    mockProcessManager = MockProcessManager();
  });

  group('doctor', () {
    testUsingContext('intellij validator', () async {
      const String installPath = '/path/to/intelliJ';
      final ValidationResult result = await IntelliJValidatorTestTarget('Test', installPath).validate();
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
    }, overrides: noColorTerminalOverride);

    testUsingContext('vs code validator when both installed', () async {
      final ValidationResult result = await VsCodeValidatorTestTargets.installedWithExtension.validate();
      expect(result.type, ValidationType.installed);
      expect(result.statusInfo, 'version 1.2.3');
      expect(result.messages, hasLength(2));

      ValidationMessage message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('VS Code '));
      expect(message.message, 'VS Code at ${VsCodeValidatorTestTargets.validInstall}');

      message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Flutter '));
      expect(message.message, 'Flutter extension version 4.5.6');
      expect(message.isError, isFalse);
    }, overrides: noColorTerminalOverride);

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
          .firstWhere((ValidationMessage m) => m.message.startsWith('Flutter '));
      expect(message.message, 'Flutter extension version 4.5.6');
    }, overrides: noColorTerminalOverride);

    testUsingContext('vs code validator when extension missing', () async {
      final ValidationResult result = await VsCodeValidatorTestTargets.installedWithoutExtension.validate();
      expect(result.type, ValidationType.partial);
      expect(result.statusInfo, 'version 1.2.3');
      expect(result.messages, hasLength(2));

      ValidationMessage message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('VS Code '));
      expect(message.message, 'VS Code at ${VsCodeValidatorTestTargets.validInstall}');

      message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Flutter '));
      expect(message.message, startsWith('Flutter extension not installed'));
      expect(message.isError, isTrue);
    }, overrides: noColorTerminalOverride);
  });

  group('proxy validator', () {
    testUsingContext('does not show if HTTP_PROXY is not set', () {
      expect(ProxyValidator.shouldShow, isFalse);
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()..environment = <String, String>{},
    });

    testUsingContext('does not show if HTTP_PROXY is only whitespace', () {
      expect(ProxyValidator.shouldShow, isFalse);
    }, overrides: <Type, Generator>{
      Platform: () =>
          FakePlatform()..environment = <String, String>{'HTTP_PROXY': ' '},
    });

    testUsingContext('shows when HTTP_PROXY is set', () {
      expect(ProxyValidator.shouldShow, isTrue);
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()
        ..environment = <String, String>{'HTTP_PROXY': 'fakeproxy.local'},
    });

    testUsingContext('shows when http_proxy is set', () {
      expect(ProxyValidator.shouldShow, isTrue);
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()
        ..environment = <String, String>{'http_proxy': 'fakeproxy.local'},
    });

    testUsingContext('reports success when NO_PROXY is configured correctly', () async {
      final ValidationResult results = await ProxyValidator().validate();
      final List<ValidationMessage> issues = results.messages
          .where((ValidationMessage msg) => msg.isError || msg.isHint)
          .toList();
      expect(issues, hasLength(0));
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()
        ..environment = <String, String>{
          'HTTP_PROXY': 'fakeproxy.local',
          'NO_PROXY': 'localhost,127.0.0.1',
        },
    });

    testUsingContext('reports success when no_proxy is configured correctly', () async {
      final ValidationResult results = await ProxyValidator().validate();
      final List<ValidationMessage> issues = results.messages
          .where((ValidationMessage msg) => msg.isError || msg.isHint)
          .toList();
      expect(issues, hasLength(0));
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()
        ..environment = <String, String>{
          'http_proxy': 'fakeproxy.local',
          'no_proxy': 'localhost,127.0.0.1',
        },
    });

    testUsingContext('reports issues when NO_PROXY is missing localhost', () async {
      final ValidationResult results = await ProxyValidator().validate();
      final List<ValidationMessage> issues = results.messages
          .where((ValidationMessage msg) => msg.isError || msg.isHint)
          .toList();
      expect(issues, isNot(hasLength(0)));
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()
        ..environment = <String, String>{
          'HTTP_PROXY': 'fakeproxy.local',
          'NO_PROXY': '127.0.0.1',
        },
    });

    testUsingContext('reports issues when NO_PROXY is missing 127.0.0.1', () async {
      final ValidationResult results = await ProxyValidator().validate();
      final List<ValidationMessage> issues = results.messages
          .where((ValidationMessage msg) => msg.isError || msg.isHint)
          .toList();
      expect(issues, isNot(hasLength(0)));
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()
        ..environment = <String, String>{
          'HTTP_PROXY': 'fakeproxy.local',
          'NO_PROXY': 'localhost',
        },
    });
  });

  group('doctor with overridden validators', () {
    testUsingContext('validate non-verbose output format for run without issues', () async {
      expect(await doctor.diagnose(verbose: false), isTrue);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[✓] Passing Validator (with statusInfo)\n'
              '[✓] Another Passing Validator (with statusInfo)\n'
              '[✓] Providing validators is fun (with statusInfo)\n'
              '\n'
              '• No issues found!\n'
      ));
    }, overrides: <Type, Generator>{
      DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      Platform: _kNoColorOutputPlatform,
    });
  });

  group('doctor usage params', () {
    Usage mockUsage;

    setUp(() {
      mockUsage = MockUsage();
      when(mockUsage.isFirstRun).thenReturn(true);
    });

    testUsingContext('contains installed', () async {
      await doctor.diagnose(verbose: false);

      expect(
        verify(mockUsage.sendEvent('doctorResult.PassingValidator', captureAny)).captured,
        <dynamic>['installed', 'installed', 'installed'],
      );
    }, overrides: <Type, Generator>{
      DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      Platform: _kNoColorOutputPlatform,
      Usage: () => mockUsage,
    });

    testUsingContext('contains installed and partial', () async {
      await FakePassingDoctor().diagnose(verbose: false);

      expect(
        verify(mockUsage.sendEvent('doctorResult.PassingValidator', captureAny)).captured,
        <dynamic>['installed', 'installed'],
      );
      expect(
        verify(mockUsage.sendEvent('doctorResult.PartialValidatorWithHintsOnly', captureAny)).captured,
        <dynamic>['partial'],
      );
      expect(
        verify(mockUsage.sendEvent('doctorResult.PartialValidatorWithErrors', captureAny)).captured,
        <dynamic>['partial'],
      );
    }, overrides: <Type, Generator>{
      Platform: _kNoColorOutputPlatform,
      Usage: () => mockUsage,
    });

    testUsingContext('contains installed, missing and partial', () async {
      await FakeDoctor().diagnose(verbose: false);

      expect(
        verify(mockUsage.sendEvent('doctorResult.PassingValidator', captureAny)).captured,
        <dynamic>['installed'],
      );
      expect(
        verify(mockUsage.sendEvent('doctorResult.MissingValidator', captureAny)).captured,
        <dynamic>['missing'],
      );
      expect(
        verify(mockUsage.sendEvent('doctorResult.NotAvailableValidator', captureAny)).captured,
        <dynamic>['notAvailable'],
      );
      expect(
        verify(mockUsage.sendEvent('doctorResult.PartialValidatorWithHintsOnly', captureAny)).captured,
        <dynamic>['partial'],
      );
      expect(
        verify(mockUsage.sendEvent('doctorResult.PartialValidatorWithErrors', captureAny)).captured,
        <dynamic>['partial'],
      );
    }, overrides: <Type, Generator>{
      Platform: _kNoColorOutputPlatform,
      Usage: () => mockUsage,
    });

    testUsingContext('events for grouped validators are properly decomposed', () async {
      await FakeGroupedDoctor().diagnose(verbose: false);

      expect(
        verify(mockUsage.sendEvent('doctorResult.PassingGroupedValidator', captureAny)).captured,
        <dynamic>['installed', 'installed', 'installed'],
      );
      expect(
        verify(mockUsage.sendEvent('doctorResult.MissingGroupedValidator', captureAny)).captured,
        <dynamic>['missing'],
      );
    }, overrides: <Type, Generator>{
      Platform: _kNoColorOutputPlatform,
      Usage: () => mockUsage,
    });
  });

  group('doctor with fake validators', () {
    testUsingContext('validate non-verbose output format for run without issues', () async {
      expect(await FakeQuietDoctor().diagnose(verbose: false), isTrue);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[✓] Passing Validator (with statusInfo)\n'
              '[✓] Another Passing Validator (with statusInfo)\n'
              '[✓] Validators are fun (with statusInfo)\n'
              '[✓] Four score and seven validators ago (with statusInfo)\n'
              '\n'
              '• No issues found!\n'
      ));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate non-verbose output format for run with crash', () async {
      expect(await FakeCrashingDoctor().diagnose(verbose: false), isFalse);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[✓] Passing Validator (with statusInfo)\n'
              '[✓] Another Passing Validator (with statusInfo)\n'
              '[☠] Crashing validator (the doctor check crashed)\n'
              '    ✗ Due to an error, the doctor check did not complete. If the error message below is not helpful, '
              'please let us know about this issue at https://github.com/flutter/flutter/issues.\n'
              '    ✗ fatal error\n'
              '[✓] Validators are fun (with statusInfo)\n'
              '[✓] Four score and seven validators ago (with statusInfo)\n'
              '\n'
              '! Doctor found issues in 1 category.\n'
      ));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate verbose output format contains trace for run with crash', () async {
      expect(await FakeCrashingDoctor().diagnose(verbose: true), isFalse);
      expect(testLogger.statusText, contains('#0      CrashingValidator.validate'));
    }, overrides: noColorTerminalOverride);


    testUsingContext('validate non-verbose output format for run with an async crash', () async {
      final Completer<void> completer = Completer<void>();
      await FakeAsync().run((FakeAsync time) {
        unawaited(FakeAsyncCrashingDoctor(time).diagnose(verbose: false).then((bool r) {
          expect(r, isFalse);
          completer.complete(null);
        }));
        time.elapse(const Duration(seconds: 1));
        time.flushMicrotasks();
        return completer.future;
      });
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[✓] Passing Validator (with statusInfo)\n'
              '[✓] Another Passing Validator (with statusInfo)\n'
              '[☠] Async crashing validator (the doctor check crashed)\n'
              '    ✗ Due to an error, the doctor check did not complete. If the error message below is not helpful, '
              'please let us know about this issue at https://github.com/flutter/flutter/issues.\n'
              '    ✗ fatal error\n'
              '[✓] Validators are fun (with statusInfo)\n'
              '[✓] Four score and seven validators ago (with statusInfo)\n'
              '\n'
              '! Doctor found issues in 1 category.\n'
      ));
    }, overrides: noColorTerminalOverride);


    testUsingContext('validate non-verbose output format when only one category fails', () async {
      expect(await FakeSinglePassingDoctor().diagnose(verbose: false), isTrue);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[!] Partial Validator with only a Hint\n'
              '    ! There is a hint here\n'
              '\n'
              '! Doctor found issues in 1 category.\n'
      ));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate non-verbose output format for a passing run', () async {
      expect(await FakePassingDoctor().diagnose(verbose: false), isTrue);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[✓] Passing Validator (with statusInfo)\n'
              '[!] Partial Validator with only a Hint\n'
              '    ! There is a hint here\n'
              '[!] Partial Validator with Errors\n'
              '    ✗ An error message indicating partial installation\n'
              '    ! Maybe a hint will help the user\n'
              '[✓] Another Passing Validator (with statusInfo)\n'
              '\n'
              '! Doctor found issues in 2 categories.\n'
      ));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate non-verbose output format', () async {
      expect(await FakeDoctor().diagnose(verbose: false), isFalse);
      expect(testLogger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[✓] Passing Validator (with statusInfo)\n'
              '[✗] Missing Validator\n'
              '    ✗ A useful error message\n'
              '    ! A hint message\n'
              '[!] Not Available Validator\n'
              '    ✗ A useful error message\n'
              '    ! A hint message\n'
              '[!] Partial Validator with only a Hint\n'
              '    ! There is a hint here\n'
              '[!] Partial Validator with Errors\n'
              '    ✗ An error message indicating partial installation\n'
              '    ! Maybe a hint will help the user\n'
              '\n'
              '! Doctor found issues in 4 categories.\n'
      ));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate verbose output format', () async {
      expect(await FakeDoctor().diagnose(verbose: true), isFalse);
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
              '[!] Not Available Validator\n'
              '    ✗ A useful error message\n'
              '    • A message that is not an error\n'
              '    ! A hint message\n'
              '\n'
              '[!] Partial Validator with only a Hint\n'
              '    ! There is a hint here\n'
              '    • But there is no error\n'
              '\n'
              '[!] Partial Validator with Errors\n'
              '    ✗ An error message indicating partial installation\n'
              '    ! Maybe a hint will help the user\n'
              '    • An extra message with some verbose details\n'
              '\n'
              '! Doctor found issues in 4 categories.\n'
      ));
    }, overrides: noColorTerminalOverride);

    testUsingContext('gen_snapshot does not work', () async {
      when(mockProcessManager.runSync(
        <String>[artifacts.getArtifactPath(Artifact.genSnapshot)],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenReturn(ProcessResult(101, 1, '', ''));

      expect(await FlutterValidatorDoctor().diagnose(verbose: false), isTrue);
      final List<String> statusLines = testLogger.statusText.split('\n');
      for (String msg in userMessages.flutterBinariesDoNotRun.split('\n')) {
        expect(statusLines, contains(contains(msg)));
      }
      if (platform.isLinux) {
        for (String msg in userMessages.flutterBinariesLinuxRepairCommands.split('\n')) {
          expect(statusLines, contains(contains(msg)));
        }
      }
    }, overrides: <Type, Generator>{
      OutputPreferences: () => OutputPreferences(wrapText: false),
      ProcessManager: () => mockProcessManager,
      Platform: _kNoColorOutputPlatform,
    });
  });

  testUsingContext('validate non-verbose output wrapping', () async {
    expect(await FakeDoctor().diagnose(verbose: false), isFalse);
    expect(testLogger.statusText, equals(
        'Doctor summary (to see all\n'
        'details, run flutter doctor\n'
        '-v):\n'
        '[✓] Passing Validator (with\n'
        '    statusInfo)\n'
        '[✗] Missing Validator\n'
        '    ✗ A useful error message\n'
        '    ! A hint message\n'
        '[!] Not Available Validator\n'
        '    ✗ A useful error message\n'
        '    ! A hint message\n'
        '[!] Partial Validator with\n'
        '    only a Hint\n'
        '    ! There is a hint here\n'
        '[!] Partial Validator with\n'
        '    Errors\n'
        '    ✗ An error message\n'
        '      indicating partial\n'
        '      installation\n'
        '    ! Maybe a hint will help\n'
        '      the user\n'
        '\n'
        '! Doctor found issues in 4\n'
        '  categories.\n'
        ''
    ));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 30),
    Platform: _kNoColorOutputPlatform,
  });

  testUsingContext('validate verbose output wrapping', () async {
    expect(await FakeDoctor().diagnose(verbose: true), isFalse);
    expect(testLogger.statusText, equals(
        '[✓] Passing Validator (with\n'
        '    statusInfo)\n'
        '    • A helpful message\n'
        '    • A second, somewhat\n'
        '      longer helpful message\n'
        '\n'
        '[✗] Missing Validator\n'
        '    ✗ A useful error message\n'
        '    • A message that is not an\n'
        '      error\n'
        '    ! A hint message\n'
        '\n'
        '[!] Not Available Validator\n'
        '    ✗ A useful error message\n'
        '    • A message that is not an\n'
        '      error\n'
        '    ! A hint message\n'
        '\n'
        '[!] Partial Validator with\n'
        '    only a Hint\n'
        '    ! There is a hint here\n'
        '    • But there is no error\n'
        '\n'
        '[!] Partial Validator with\n'
        '    Errors\n'
        '    ✗ An error message\n'
        '      indicating partial\n'
        '      installation\n'
        '    ! Maybe a hint will help\n'
        '      the user\n'
        '    • An extra message with\n'
        '      some verbose details\n'
        '\n'
        '! Doctor found issues in 4\n'
        '  categories.\n'
        ''
    ));
  }, overrides: <Type, Generator>{
    OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 30),
    Platform: _kNoColorOutputPlatform,
  });


  group('doctor with grouped validators', () {
    testUsingContext('validate diagnose combines validator output', () async {
      expect(await FakeGroupedDoctor().diagnose(), isTrue);
      expect(testLogger.statusText, equals(
              '[✓] Category 1\n'
              '    • A helpful message\n'
              '    • A helpful message\n'
              '\n'
              '[!] Category 2\n'
              '    • A helpful message\n'
              '    ✗ A useful error message\n'
              '\n'
              '! Doctor found issues in 1 category.\n'
      ));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate merging assigns statusInfo and title', () async {
      // There are two subvalidators. Only the second contains statusInfo.
      expect(await FakeGroupedDoctorWithStatus().diagnose(), isTrue);
      expect(testLogger.statusText, equals(
              '[✓] First validator title (A status message)\n'
              '    • A helpful message\n'
              '    • A different message\n'
              '\n'
              '• No issues found!\n'
      ));
    }, overrides: noColorTerminalOverride);
  });


  group('grouped validator merging results', () {
    final PassingGroupedValidator installed = PassingGroupedValidator('Category');
    final PartialGroupedValidator partial = PartialGroupedValidator('Category');
    final MissingGroupedValidator missing = MissingGroupedValidator('Category');

    testUsingContext('validate installed + installed = installed', () async {
      expect(await FakeSmallGroupDoctor(installed, installed).diagnose(), isTrue);
      expect(testLogger.statusText, startsWith('[✓]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate installed + partial = partial', () async {
      expect(await FakeSmallGroupDoctor(installed, partial).diagnose(), isTrue);
      expect(testLogger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate installed + missing = partial', () async {
      expect(await FakeSmallGroupDoctor(installed, missing).diagnose(), isTrue);
      expect(testLogger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate partial + installed = partial', () async {
      expect(await FakeSmallGroupDoctor(partial, installed).diagnose(), isTrue);
      expect(testLogger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate partial + partial = partial', () async {
      expect(await FakeSmallGroupDoctor(partial, partial).diagnose(), isTrue);
      expect(testLogger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate partial + missing = partial', () async {
      expect(await FakeSmallGroupDoctor(partial, missing).diagnose(), isTrue);
      expect(testLogger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate missing + installed = partial', () async {
      expect(await FakeSmallGroupDoctor(missing, installed).diagnose(), isTrue);
      expect(testLogger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate missing + partial = partial', () async {
      expect(await FakeSmallGroupDoctor(missing, partial).diagnose(), isTrue);
      expect(testLogger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate missing + missing = missing', () async {
      expect(await FakeSmallGroupDoctor(missing, missing).diagnose(), isFalse);
      expect(testLogger.statusText, startsWith('[✗]'));
    }, overrides: noColorTerminalOverride);
  });

  testUsingContext('WebWorkflow is a part of validator workflows if enabled', () async {
    when(processManager.canRun(any)).thenReturn(true);

    expect(DoctorValidatorsProvider.defaultInstance.workflows.contains(webWorkflow), true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    ProcessManager: () => MockProcessManager(),
  });
}

class MockUsage extends Mock implements Usage {}

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
    messages.add(ValidationMessage('A helpful message'));
    messages.add(ValidationMessage('A second, somewhat longer helpful message'));
    return ValidationResult(ValidationType.installed, messages, statusInfo: 'with statusInfo');
  }
}

class MissingValidator extends DoctorValidator {
  MissingValidator() : super('Missing Validator');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(ValidationMessage.error('A useful error message'));
    messages.add(ValidationMessage('A message that is not an error'));
    messages.add(ValidationMessage.hint('A hint message'));
    return ValidationResult(ValidationType.missing, messages);
  }
}

class NotAvailableValidator extends DoctorValidator {
  NotAvailableValidator() : super('Not Available Validator');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(ValidationMessage.error('A useful error message'));
    messages.add(ValidationMessage('A message that is not an error'));
    messages.add(ValidationMessage.hint('A hint message'));
    return ValidationResult(ValidationType.notAvailable, messages);
  }
}

class PartialValidatorWithErrors extends DoctorValidator {
  PartialValidatorWithErrors() : super('Partial Validator with Errors');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(ValidationMessage.error('An error message indicating partial installation'));
    messages.add(ValidationMessage.hint('Maybe a hint will help the user'));
    messages.add(ValidationMessage('An extra message with some verbose details'));
    return ValidationResult(ValidationType.partial, messages);
  }
}

class PartialValidatorWithHintsOnly extends DoctorValidator {
  PartialValidatorWithHintsOnly() : super('Partial Validator with only a Hint');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(ValidationMessage.hint('There is a hint here'));
    messages.add(ValidationMessage('But there is no error'));
    return ValidationResult(ValidationType.partial, messages);
  }
}

class CrashingValidator extends DoctorValidator {
  CrashingValidator() : super('Crashing validator');

  @override
  Future<ValidationResult> validate() async {
    throw 'fatal error';
  }
}

class AsyncCrashingValidator extends DoctorValidator {
  AsyncCrashingValidator(this._time) : super('Async crashing validator');

  final FakeAsync _time;

  @override
  Future<ValidationResult> validate() {
    const Duration delay = Duration(seconds: 1);
    final Future<ValidationResult> result = Future<ValidationResult>
        .delayed(delay).then((_) {
      throw 'fatal error';
    });
    _time.elapse(const Duration(seconds: 1));
    _time.flushMicrotasks();
    return result;
  }
}

/// A doctor that fails with a missing [ValidationResult].
class FakeDoctor extends Doctor {
  List<DoctorValidator> _validators;

  @override
  List<DoctorValidator> get validators {
    if (_validators == null) {
      _validators = <DoctorValidator>[];
      _validators.add(PassingValidator('Passing Validator'));
      _validators.add(MissingValidator());
      _validators.add(NotAvailableValidator());
      _validators.add(PartialValidatorWithHintsOnly());
      _validators.add(PartialValidatorWithErrors());
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
      _validators.add(PassingValidator('Passing Validator'));
      _validators.add(PartialValidatorWithHintsOnly());
      _validators.add(PartialValidatorWithErrors());
      _validators.add(PassingValidator('Another Passing Validator'));
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
      _validators.add(PartialValidatorWithHintsOnly());
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
      _validators.add(PassingValidator('Passing Validator'));
      _validators.add(PassingValidator('Another Passing Validator'));
      _validators.add(PassingValidator('Validators are fun'));
      _validators.add(PassingValidator('Four score and seven validators ago'));
    }
    return _validators;
  }
}

/// A doctor with a validator that throws an exception.
class FakeCrashingDoctor extends Doctor {
  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    if (_validators == null) {
      _validators = <DoctorValidator>[];
      _validators.add(PassingValidator('Passing Validator'));
      _validators.add(PassingValidator('Another Passing Validator'));
      _validators.add(CrashingValidator());
      _validators.add(PassingValidator('Validators are fun'));
      _validators.add(PassingValidator('Four score and seven validators ago'));
    }
    return _validators;
  }
}

/// A doctor with a validator that throws an exception.
class FakeAsyncCrashingDoctor extends Doctor {
  FakeAsyncCrashingDoctor(this._time);

  final FakeAsync _time;

  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    if (_validators == null) {
      _validators = <DoctorValidator>[];
      _validators.add(PassingValidator('Passing Validator'));
      _validators.add(PassingValidator('Another Passing Validator'));
      _validators.add(AsyncCrashingValidator(_time));
      _validators.add(PassingValidator('Validators are fun'));
      _validators.add(PassingValidator('Four score and seven validators ago'));
    }
    return _validators;
  }
}

/// A DoctorValidatorsProvider that overrides the default validators without
/// overriding the doctor.
class FakeDoctorValidatorsProvider implements DoctorValidatorsProvider {
  @override
  List<DoctorValidator> get validators {
    return <DoctorValidator>[
      PassingValidator('Passing Validator'),
      PassingValidator('Another Passing Validator'),
      PassingValidator('Providing validators is fun'),
    ];
  }

  @override
  List<Workflow> get workflows => <Workflow>[];
}

class PassingGroupedValidator extends DoctorValidator {
  PassingGroupedValidator(String name) : super(name);

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(ValidationMessage('A helpful message'));
    return ValidationResult(ValidationType.installed, messages);
  }
}

class MissingGroupedValidator extends DoctorValidator {
  MissingGroupedValidator(String name) : super(name);

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(ValidationMessage.error('A useful error message'));
    return ValidationResult(ValidationType.missing, messages);
  }
}

class PartialGroupedValidator extends DoctorValidator {
  PartialGroupedValidator(String name) : super(name);

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(ValidationMessage.error('An error message for partial installation'));
    return ValidationResult(ValidationType.partial, messages);
  }
}

class PassingGroupedValidatorWithStatus extends DoctorValidator {
  PassingGroupedValidatorWithStatus(String name) : super(name);

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    messages.add(ValidationMessage('A different message'));
    return ValidationResult(ValidationType.installed, messages, statusInfo: 'A status message');
  }
}

/// A doctor that has two groups of two validators each.
class FakeGroupedDoctor extends Doctor {
  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    if (_validators == null) {
      _validators = <DoctorValidator>[];
      _validators.add(GroupedValidator(<DoctorValidator>[
        PassingGroupedValidator('Category 1'),
        PassingGroupedValidator('Category 1'),
      ]));
      _validators.add(GroupedValidator(<DoctorValidator>[
        PassingGroupedValidator('Category 2'),
        MissingGroupedValidator('Category 2'),
      ]));
    }
    return _validators;
  }
}

class FakeGroupedDoctorWithStatus extends Doctor {
  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    _validators ??= <DoctorValidator>[
      GroupedValidator(<DoctorValidator>[
        PassingGroupedValidator('First validator title'),
        PassingGroupedValidatorWithStatus('Second validator title'),
    ])];
    return _validators;
  }
}

class FlutterValidatorDoctor extends Doctor {
  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    _validators ??= <DoctorValidator>[FlutterValidator()];
    return _validators;
  }
}

/// A doctor that takes any two validators. Used to check behavior when
/// merging ValidationTypes (installed, missing, partial).
class FakeSmallGroupDoctor extends Doctor {
  FakeSmallGroupDoctor(DoctorValidator val1, DoctorValidator val2) {
    _validators = <DoctorValidator>[GroupedValidator(<DoctorValidator>[val1, val2])];
  }

  List<DoctorValidator> _validators;

  @override
  List<DoctorValidator> get validators => _validators;
}

class VsCodeValidatorTestTargets extends VsCodeValidator {
  VsCodeValidatorTestTargets._(String installDirectory, String extensionDirectory, {String edition})
    : super(VsCode.fromDirectory(installDirectory, extensionDirectory, edition: edition));

  static VsCodeValidatorTestTargets get installedWithExtension =>
      VsCodeValidatorTestTargets._(validInstall, validExtensions);

  static VsCodeValidatorTestTargets get installedWithExtension64bit =>
      VsCodeValidatorTestTargets._(validInstall, validExtensions, edition: '64-bit edition');

  static VsCodeValidatorTestTargets get installedWithoutExtension =>
      VsCodeValidatorTestTargets._(validInstall, missingExtensions);

  static final String validInstall = fs.path.join('test', 'data', 'vscode', 'application');
  static final String validExtensions = fs.path.join('test', 'data', 'vscode', 'extensions');
  static final String missingExtensions = fs.path.join('test', 'data', 'vscode', 'notExtensions');
}

class MockProcessManager extends Mock implements ProcessManager {}
