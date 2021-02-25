// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio_validator.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/doctor.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/vscode/vscode.dart';
import 'package:flutter_tools/src/vscode/vscode_validator.dart';
import 'package:flutter_tools/src/web/workflow.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:fake_async/fake_async.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

final Generator _kNoColorOutputPlatform = () => FakePlatform(
  localeName: 'en_US.UTF-8',
  environment: <String, String>{},
  stdoutSupportsAnsi: false,
);

final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorOutputPlatform,
};

final Platform macPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{'HOME': '/foo/bar'}
);

void main() {
  MockFlutterVersion mockFlutterVersion;
  BufferLogger logger;
  FakeProcessManager fakeProcessManager;

  setUp(() {
    mockFlutterVersion = MockFlutterVersion();
    logger = BufferLogger.test();
    fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
  });

  testWithoutContext('ValidationMessage equality and hashCode includes contextUrl', () {
    const ValidationMessage messageA = ValidationMessage('ab', contextUrl: 'a');
    const ValidationMessage messageB = ValidationMessage('ab', contextUrl: 'b');

    expect(messageB, isNot(messageA));
    expect(messageB.hashCode, isNot(messageA.hashCode));
    expect(messageA, isNot(messageB));
    expect(messageA.hashCode, isNot(messageB.hashCode));
  });

  group('doctor', () {
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

    testUsingContext('No IDE Validator includes expected installation messages', () async {
      final ValidationResult result = await NoIdeValidator().validate();
      expect(result.type, ValidationType.missing);

      expect(
        result.messages.map((ValidationMessage vm) => vm.message),
        UserMessages().noIdeInstallationInfo,
      );
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
      expect(result.type, ValidationType.installed);
      expect(result.statusInfo, 'version 1.2.3');
      expect(result.messages, hasLength(2));

      ValidationMessage message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('VS Code '));
      expect(message.message, 'VS Code at ${VsCodeValidatorTestTargets.validInstall}');

      message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Flutter '));
      expect(message.message, startsWith('Flutter extension can be installed from'));
      expect(message.contextUrl, 'https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter');
      expect(message.isError, false);
    }, overrides: noColorTerminalOverride);

    group('device validator', () {
      testWithoutContext('no devices', () async {
        final MockDeviceManager mockDeviceManager = MockDeviceManager();

        when(mockDeviceManager.getAllConnectedDevices()).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[])
        );
        when(mockDeviceManager.getDeviceDiagnostics()).thenAnswer(
          (Invocation invocation) => Future<List<String>>.value(<String>[])
        );

        final DeviceValidator deviceValidator = DeviceValidator(
          deviceManager: mockDeviceManager,
          userMessages: UserMessages(),
        );
        final ValidationResult result = await deviceValidator.validate();
        expect(result.type, ValidationType.notAvailable);
        expect(result.messages, const <ValidationMessage>[
          ValidationMessage.hint('No devices available'),
        ]);
        expect(result.statusInfo, isNull);
      });

      testWithoutContext('diagnostic message', () async {
        final MockDeviceManager mockDeviceManager = MockDeviceManager();

        when(mockDeviceManager.getAllConnectedDevices()).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[])
        );
        when(mockDeviceManager.getDeviceDiagnostics()).thenAnswer(
          (Invocation invocation) => Future<List<String>>.value(<String>['Device locked'])
        );

        final DeviceValidator deviceValidator = DeviceValidator(
          deviceManager: mockDeviceManager,
          userMessages: UserMessages(),
        );
        final ValidationResult result = await deviceValidator.validate();
        expect(result.type, ValidationType.notAvailable);
        expect(result.messages, const <ValidationMessage>[
          ValidationMessage.hint('Device locked'),
        ]);
        expect(result.statusInfo, isNull);
      });

      testWithoutContext('diagnostic message and devices', () async {
        final MockDeviceManager mockDeviceManager = MockDeviceManager();
        final MockDevice mockDevice = MockDevice();

        when(mockDeviceManager.getAllConnectedDevices()).thenAnswer(
          (_) => Future<List<Device>>.value(<Device>[mockDevice])
        );
        when(mockDeviceManager.getDeviceDiagnostics()).thenAnswer(
          (_) => Future<List<String>>.value(<String>['Device locked'])
        );

        final DeviceValidator deviceValidator = DeviceValidator(
          deviceManager: mockDeviceManager,
          userMessages: UserMessages(),
        );
        final ValidationResult result = await deviceValidator.validate();
        expect(result.type, ValidationType.installed);
        expect(result.messages, const <ValidationMessage>[
          ValidationMessage('null (null) • device-id • android • null'),
          ValidationMessage.hint('Device locked'),
        ]);
        expect(result.statusInfo, '1 available');
      });
    });
  });

  group('doctor with overridden validators', () {
    testUsingContext('validate non-verbose output format for run without issues', () async {
      final Doctor doctor = Doctor(logger: logger);
      expect(await doctor.diagnose(verbose: false), isTrue);
      expect(logger.statusText, equals(
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
    TestUsage testUsage;

    setUp(() {
      testUsage = TestUsage();
    });

    testUsingContext('contains installed', () async {
      final Doctor doctor = Doctor(logger: logger);
      await doctor.diagnose(verbose: false);

      expect(testUsage.events.length, 3);
      expect(testUsage.events, contains(
        const TestUsageEvent(
          'doctor-result',
          'PassingValidator',
          label: 'installed',
        ),
      ));
    }, overrides: <Type, Generator>{
      DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      Platform: _kNoColorOutputPlatform,
      Usage: () => testUsage,
    });

    testUsingContext('contains installed and partial', () async {
      await FakePassingDoctor(logger).diagnose(verbose: false);

      expect(testUsage.events, unorderedEquals(<TestUsageEvent>[
        const TestUsageEvent(
          'doctor-result',
          'PassingValidator',
          label: 'installed',
        ),
        const TestUsageEvent(
          'doctor-result',
          'PassingValidator',
          label: 'installed',
        ),
        const TestUsageEvent(
          'doctor-result',
          'PartialValidatorWithHintsOnly',
          label: 'partial',
        ),
        const TestUsageEvent(
          'doctor-result',
          'PartialValidatorWithErrors',
          label: 'partial',
        ),
      ]));
    }, overrides: <Type, Generator>{
      Platform: _kNoColorOutputPlatform,
      Usage: () => testUsage,
    });

    testUsingContext('contains installed, missing and partial', () async {
      await FakeDoctor(logger).diagnose(verbose: false);

      expect(testUsage.events, unorderedEquals(<TestUsageEvent>[
        const TestUsageEvent(
          'doctor-result',
          'PassingValidator',
          label: 'installed',
        ),
        const TestUsageEvent(
          'doctor-result',
          'MissingValidator',
          label: 'missing',
        ),
        const TestUsageEvent(
          'doctor-result',
          'NotAvailableValidator',
          label: 'notAvailable',
        ),
        const TestUsageEvent(
          'doctor-result',
          'PartialValidatorWithHintsOnly',
          label: 'partial',
        ),
        const TestUsageEvent(
          'doctor-result',
          'PartialValidatorWithErrors',
          label: 'partial',
        ),
      ]));
    }, overrides: <Type, Generator>{
      Platform: _kNoColorOutputPlatform,
      Usage: () => testUsage,
    });

    testUsingContext('events for grouped validators are properly decomposed', () async {
      await FakeGroupedDoctor(logger).diagnose(verbose: false);

      expect(testUsage.events, unorderedEquals(<TestUsageEvent>[
        const TestUsageEvent(
          'doctor-result',
          'PassingGroupedValidator',
          label: 'installed',
        ),
        const TestUsageEvent(
          'doctor-result',
          'PassingGroupedValidator',
          label: 'installed',
        ),
        const TestUsageEvent(
          'doctor-result',
          'PassingGroupedValidator',
          label: 'installed',
        ),
        const TestUsageEvent(
          'doctor-result',
          'MissingGroupedValidator',
          label: 'missing',
        ),
      ]));
    }, overrides: <Type, Generator>{
      Platform: _kNoColorOutputPlatform,
      Usage: () => testUsage,
    });
  });

  group('doctor with fake validators', () {
    testUsingContext('validate non-verbose output format for run without issues', () async {
      expect(await FakeQuietDoctor(logger).diagnose(verbose: false), isTrue);
      expect(logger.statusText, equals(
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
      expect(await FakeCrashingDoctor(logger).diagnose(verbose: false), isFalse);
      expect(logger.statusText, equals(
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
      expect(await FakeCrashingDoctor(logger).diagnose(verbose: true), isFalse);
      expect(logger.statusText, contains('#0      CrashingValidator.validate'));
    }, overrides: noColorTerminalOverride);


    testUsingContext('validate non-verbose output format for run with an async crash', () async {
      final Completer<void> completer = Completer<void>();
      await FakeAsync().run((FakeAsync time) {
        unawaited(FakeAsyncCrashingDoctor(time, logger).diagnose(verbose: false).then((bool r) {
          expect(r, isFalse);
          completer.complete(null);
        }));
        time.elapse(const Duration(seconds: 1));
        time.flushMicrotasks();
        return completer.future;
      });
      expect(logger.statusText, equals(
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
      expect(await FakeSinglePassingDoctor(logger).diagnose(verbose: false), isTrue);
      expect(logger.statusText, equals(
              'Doctor summary (to see all details, run flutter doctor -v):\n'
              '[!] Partial Validator with only a Hint\n'
              '    ! There is a hint here\n'
              '\n'
              '! Doctor found issues in 1 category.\n'
      ));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate non-verbose output format for a passing run', () async {
      expect(await FakePassingDoctor(logger).diagnose(verbose: false), isTrue);
      expect(logger.statusText, equals(
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
      expect(await FakeDoctor(logger).diagnose(verbose: false), isFalse);
      expect(logger.statusText, equals(
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
      expect(await FakeDoctor(logger).diagnose(verbose: true), isFalse);
      expect(logger.statusText, equals(
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
  });

  testUsingContext('validate non-verbose output wrapping', () async {
    final BufferLogger wrapLogger = BufferLogger.test(
      outputPreferences: OutputPreferences(wrapText: true, wrapColumn: 30),
    );
    expect(await FakeDoctor(wrapLogger).diagnose(verbose: false), isFalse);
    expect(wrapLogger.statusText, equals(
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
    Platform: _kNoColorOutputPlatform,
  });

  testUsingContext('validate verbose output wrapping', () async {
    final BufferLogger wrapLogger = BufferLogger.test(
      outputPreferences: OutputPreferences(wrapText: true, wrapColumn: 30),
    );
    expect(await FakeDoctor(wrapLogger).diagnose(verbose: true), isFalse);
    expect(wrapLogger.statusText, equals(
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
    Platform: _kNoColorOutputPlatform,
  });


  group('doctor with grouped validators', () {
    testUsingContext('validate diagnose combines validator output', () async {
      expect(await FakeGroupedDoctor(logger).diagnose(), isTrue);
      expect(logger.statusText, equals(
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
      expect(await FakeGroupedDoctorWithStatus(logger).diagnose(), isTrue);
      expect(logger.statusText, equals(
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
      expect(await FakeSmallGroupDoctor(logger, installed, installed).diagnose(), isTrue);
      expect(logger.statusText, startsWith('[✓]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate installed + partial = partial', () async {
      expect(await FakeSmallGroupDoctor(logger, installed, partial).diagnose(), isTrue);
      expect(logger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate installed + missing = partial', () async {
      expect(await FakeSmallGroupDoctor(logger, installed, missing).diagnose(), isTrue);
      expect(logger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate partial + installed = partial', () async {
      expect(await FakeSmallGroupDoctor(logger, partial, installed).diagnose(), isTrue);
      expect(logger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate partial + partial = partial', () async {
      expect(await FakeSmallGroupDoctor(logger, partial, partial).diagnose(), isTrue);
      expect(logger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate partial + missing = partial', () async {
      expect(await FakeSmallGroupDoctor(logger, partial, missing).diagnose(), isTrue);
      expect(logger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate missing + installed = partial', () async {
      expect(await FakeSmallGroupDoctor(logger, missing, installed).diagnose(), isTrue);
      expect(logger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate missing + partial = partial', () async {
      expect(await FakeSmallGroupDoctor(logger, missing, partial).diagnose(), isTrue);
      expect(logger.statusText, startsWith('[!]'));
    }, overrides: noColorTerminalOverride);

    testUsingContext('validate missing + missing = missing', () async {
      expect(await FakeSmallGroupDoctor(logger, missing, missing).diagnose(), isFalse);
      expect(logger.statusText, startsWith('[✗]'));
    }, overrides: noColorTerminalOverride);
  });

  testUsingContext('WebWorkflow is a part of validator workflows if enabled', () async {
    expect(DoctorValidatorsProvider.defaultInstance.workflows,
      contains(isA<WebWorkflow>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWebEnabled: true),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => fakeProcessManager,
  });

  testUsingContext('Fetches tags to get the right version', () async {
    Cache.disableLocking();

    final DoctorCommand doctorCommand = DoctorCommand();
    final CommandRunner<void> commandRunner = createTestCommandRunner(doctorCommand);

    await commandRunner.run(<String>['doctor']);

    verify(mockFlutterVersion.fetchTagsAndUpdate()).called(1);

    Cache.enableLocking();
  }, overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.any(),
    FileSystem: () => MemoryFileSystem.test(),
    FlutterVersion: () => mockFlutterVersion,
    Doctor: () => NoOpDoctor(),
  }, initializeFlutterRoot: false);

  testUsingContext('If android workflow is disabled, AndroidStudio validator is not included', () {
    expect(DoctorValidatorsProvider.defaultInstance.validators, isNot(contains(isA<AndroidStudioValidator>())));
    expect(DoctorValidatorsProvider.defaultInstance.validators, isNot(contains(isA<NoAndroidStudioValidator>())));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isAndroidEnabled: false),
  });
}

class NoOpDoctor implements Doctor {
  @override
  bool get canLaunchAnything => true;

  @override
  bool get canListAnything => true;

  @override
  Future<bool> checkRemoteArtifacts(String engineRevision) async => true;

  @override
  Future<bool> diagnose({
    bool androidLicenses = false,
    bool verbose = true,
    bool showColor = true,
    AndroidLicenseValidator androidLicenseValidator,
  }) async => true;

  @override
  List<ValidatorTask> startValidatorTasks() => <ValidatorTask>[];

  @override
  Future<void> summary() => null;

  @override
  List<DoctorValidator> get validators => <DoctorValidator>[];

  @override
  List<Workflow> get workflows => <Workflow>[];
}

class PassingValidator extends DoctorValidator {
  PassingValidator(String name) : super(name);

  @override
  Future<ValidationResult> validate() async {
    const List<ValidationMessage> messages = <ValidationMessage>[
      ValidationMessage('A helpful message'),
      ValidationMessage('A second, somewhat longer helpful message'),
    ];
    return const ValidationResult(ValidationType.installed, messages, statusInfo: 'with statusInfo');
  }
}

class MissingValidator extends DoctorValidator {
  MissingValidator() : super('Missing Validator');

  @override
  Future<ValidationResult> validate() async {
    const List<ValidationMessage> messages = <ValidationMessage>[
      ValidationMessage.error('A useful error message'),
      ValidationMessage('A message that is not an error'),
      ValidationMessage.hint('A hint message'),
    ];
    return const ValidationResult(ValidationType.missing, messages);
  }
}

class NotAvailableValidator extends DoctorValidator {
  NotAvailableValidator() : super('Not Available Validator');

  @override
  Future<ValidationResult> validate() async {
    const List<ValidationMessage> messages = <ValidationMessage>[
      ValidationMessage.error('A useful error message'),
      ValidationMessage('A message that is not an error'),
      ValidationMessage.hint('A hint message'),
    ];
    return const ValidationResult(ValidationType.notAvailable, messages);
  }
}

class PartialValidatorWithErrors extends DoctorValidator {
  PartialValidatorWithErrors() : super('Partial Validator with Errors');

  @override
  Future<ValidationResult> validate() async {
    const List<ValidationMessage> messages = <ValidationMessage>[
      ValidationMessage.error('An error message indicating partial installation'),
      ValidationMessage.hint('Maybe a hint will help the user'),
      ValidationMessage('An extra message with some verbose details'),
    ];
    return const ValidationResult(ValidationType.partial, messages);
  }
}

class PartialValidatorWithHintsOnly extends DoctorValidator {
  PartialValidatorWithHintsOnly() : super('Partial Validator with only a Hint');

  @override
  Future<ValidationResult> validate() async {
    const List<ValidationMessage> messages = <ValidationMessage>[
      ValidationMessage.hint('There is a hint here'),
      ValidationMessage('But there is no error'),
    ];
    return const ValidationResult(ValidationType.partial, messages);
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
    final Future<ValidationResult> result = Future<ValidationResult>.delayed(delay)
      .then((_) {
        throw 'fatal error';
      });
    _time.elapse(const Duration(seconds: 1));
    _time.flushMicrotasks();
    return result;
  }
}

/// A doctor that fails with a missing [ValidationResult].
class FakeDoctor extends Doctor {
  FakeDoctor(Logger logger) : super(logger: logger);

  List<DoctorValidator> _validators;

  @override
  List<DoctorValidator> get validators {
    return _validators ??= <DoctorValidator>[
      PassingValidator('Passing Validator'),
      MissingValidator(),
      NotAvailableValidator(),
      PartialValidatorWithHintsOnly(),
      PartialValidatorWithErrors(),
    ];
  }
}

/// A doctor that should pass, but still has issues in some categories.
class FakePassingDoctor extends Doctor {
  FakePassingDoctor(Logger logger) : super(logger: logger);

  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    return _validators ??= <DoctorValidator>[
      PassingValidator('Passing Validator'),
      PartialValidatorWithHintsOnly(),
      PartialValidatorWithErrors(),
      PassingValidator('Another Passing Validator'),
    ];
  }
}

/// A doctor that should pass, but still has 1 issue to test the singular of
/// categories.
class FakeSinglePassingDoctor extends Doctor {
  FakeSinglePassingDoctor(Logger logger) : super(logger: logger);

  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    return _validators ??= <DoctorValidator>[
      PartialValidatorWithHintsOnly(),
    ];
  }
}

/// A doctor that passes and has no issues anywhere.
class FakeQuietDoctor extends Doctor {
  FakeQuietDoctor(Logger logger) : super(logger: logger);

  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    return _validators ??= <DoctorValidator>[
      PassingValidator('Passing Validator'),
      PassingValidator('Another Passing Validator'),
      PassingValidator('Validators are fun'),
      PassingValidator('Four score and seven validators ago'),
    ];
  }
}

/// A doctor with a validator that throws an exception.
class FakeCrashingDoctor extends Doctor {
  FakeCrashingDoctor(Logger logger) : super(logger: logger);

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
  FakeAsyncCrashingDoctor(this._time, Logger logger) : super(logger: logger);

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
    const List<ValidationMessage> messages = <ValidationMessage>[
      ValidationMessage('A helpful message'),
    ];
    return const ValidationResult(ValidationType.installed, messages);
  }
}

class MissingGroupedValidator extends DoctorValidator {
  MissingGroupedValidator(String name) : super(name);

  @override
  Future<ValidationResult> validate() async {
    const List<ValidationMessage> messages = <ValidationMessage>[
      ValidationMessage.error('A useful error message'),
    ];
    return const ValidationResult(ValidationType.missing, messages);
  }
}

class PartialGroupedValidator extends DoctorValidator {
  PartialGroupedValidator(String name) : super(name);

  @override
  Future<ValidationResult> validate() async {
    const List<ValidationMessage> messages = <ValidationMessage>[
      ValidationMessage.error('An error message for partial installation'),
    ];
    return const ValidationResult(ValidationType.partial, messages);
  }
}

class PassingGroupedValidatorWithStatus extends DoctorValidator {
  PassingGroupedValidatorWithStatus(String name) : super(name);

  @override
  Future<ValidationResult> validate() async {
    const List<ValidationMessage> messages = <ValidationMessage>[
      ValidationMessage('A different message'),
    ];
    return const ValidationResult(ValidationType.installed, messages, statusInfo: 'A status message');
  }
}

/// A doctor that has two groups of two validators each.
class FakeGroupedDoctor extends Doctor {
  FakeGroupedDoctor(Logger logger) : super(logger: logger);

  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    return _validators ??= <DoctorValidator>[
      GroupedValidator(<DoctorValidator>[
        PassingGroupedValidator('Category 1'),
        PassingGroupedValidator('Category 1'),
      ]),
      GroupedValidator(<DoctorValidator>[
        PassingGroupedValidator('Category 2'),
        MissingGroupedValidator('Category 2'),
      ]),
    ];
  }
}

class FakeGroupedDoctorWithStatus extends Doctor {
  FakeGroupedDoctorWithStatus(Logger logger) : super(logger: logger);

  List<DoctorValidator> _validators;
  @override
  List<DoctorValidator> get validators {
    return _validators ??= <DoctorValidator>[
      GroupedValidator(<DoctorValidator>[
        PassingGroupedValidator('First validator title'),
        PassingGroupedValidatorWithStatus('Second validator title'),
      ]),
    ];
  }
}

/// A doctor that takes any two validators. Used to check behavior when
/// merging ValidationTypes (installed, missing, partial).
class FakeSmallGroupDoctor extends Doctor {
  FakeSmallGroupDoctor(Logger logger, DoctorValidator val1, DoctorValidator val2) : super(logger: logger) {
    _validators = <DoctorValidator>[GroupedValidator(<DoctorValidator>[val1, val2])];
  }

  List<DoctorValidator> _validators;

  @override
  List<DoctorValidator> get validators => _validators;
}

class VsCodeValidatorTestTargets extends VsCodeValidator {
  VsCodeValidatorTestTargets._(String installDirectory, String extensionDirectory, {String edition})
    : super(VsCode.fromDirectory(installDirectory, extensionDirectory, edition: edition, fileSystem: globals.fs));

  static VsCodeValidatorTestTargets get installedWithExtension =>
      VsCodeValidatorTestTargets._(validInstall, validExtensions);

  static VsCodeValidatorTestTargets get installedWithExtension64bit =>
      VsCodeValidatorTestTargets._(validInstall, validExtensions, edition: '64-bit edition');

  static VsCodeValidatorTestTargets get installedWithoutExtension =>
      VsCodeValidatorTestTargets._(validInstall, missingExtensions);

  static final String validInstall = globals.fs.path.join('test', 'data', 'vscode', 'application');
  static final String validExtensions = globals.fs.path.join('test', 'data', 'vscode', 'extensions');
  static final String missingExtensions = globals.fs.path.join('test', 'data', 'vscode', 'notExtensions');
}

class MockDeviceManager extends Mock implements DeviceManager {}
class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
    when(id).thenReturn('device-id');
    when(isLocalEmulator).thenAnswer((_) => Future<bool>.value(false));
    when(targetPlatform).thenAnswer((_) => Future<TargetPlatform>.value(TargetPlatform.android));
    when(targetPlatformDisplayName).thenAnswer((_) async => 'android');
  }
}
