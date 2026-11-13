// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/experimental/diagnostics.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

final class _SecondaryTestDiagnostics extends DiagnosticsExtension {
  @override
  String get title => 'Secondary Diagnostic Check';

  @override
  Future<List<ValidationResult>> runDiagnostics() async {
    return <ValidationResult>[
      ValidationResult(ValidationType.success, const <ValidationMessage>[
        ValidationMessage('Secondary diagnostic check operational'),
      ], statusInfo: 'Secondary OK'),
    ];
  }
}

final class _CrashingDiagnosticsExtension extends DiagnosticsExtension {
  @override
  String get title => 'Crashing Diagnostic Check';

  @override
  Future<List<ValidationResult>> runDiagnostics() async {
    throw StateError('Simulated extension diagnostics failure');
  }
}

final class _HangingDiagnosticsExtension extends DiagnosticsExtension {
  @override
  String get title => 'Hanging Diagnostic Check';

  @override
  Future<List<ValidationResult>> runDiagnostics() => Completer<List<ValidationResult>>().future;
}

final class _RawPayloadDiagnosticsService extends ToolExtensionService {
  _RawPayloadDiagnosticsService(this._payload);

  final Object? _payload;

  @override
  String get namespace => DiagnosticsExtension.serviceNamespace;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'getTitle': (Map<String, Object?> _) async => 'Malformed Diagnostic Check',
      'runDiagnostics': (Map<String, Object?> _) async => _payload,
    };
  }
}

class _FakeCache extends Fake implements Cache {}

class _DelayedDiagnosticsConnection extends Fake implements ExtensionConnection {
  _DelayedDiagnosticsConnection({required this.responseFuture});

  final Future<Object?> responseFuture;

  @override
  String get extensionName => 'my_test_extension';

  @override
  Future<Object?> sendRequest(
    String method, {
    Object? params,
    Duration? timeout = const Duration(seconds: 5),
  }) {
    if (method == DiagnosticsExtension.getTitleMethod) {
      return Future<Object?>.value('Slow Diagnostic Check');
    }
    return timeout != null ? responseFuture.timeout(timeout) : responseFuture;
  }
}

class _EmptyValidatorsProvider implements DoctorValidatorsProvider {
  @override
  List<DoctorValidator> get validators => <DoctorValidator>[];

  @override
  List<Workflow> get workflows => <Workflow>[];
}

class _TestExtensionDoctor extends Doctor {
  _TestExtensionDoctor({required super.logger, required this.validators})
    : super(
        analytics: const NoOpAnalytics(),
        cache: _FakeCache(),
        clock: const SystemClock(),
        validatorsProviderBuilder: ({ExtensionManager? extensionManager}) =>
            _EmptyValidatorsProvider(),
      );

  @override
  final List<DoctorValidator> validators;
}

final class _DomainErrorDiagnosticsService extends DiagnosticsExtension {
  @override
  String get title => 'Custom Diagnostics';

  @override
  Future<List<ValidationResult>> runDiagnostics() async {
    throw const ToolExtensionException('Diagnostics failed with actionable user error.');
  }
}

void _domainErrorDiagnosticsEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
      _DomainErrorDiagnosticsService(),
    ], extensionName: 'custom_diagnostics_ext'),
  );
}

void main() {
  group('ExtensionDoctorValidator Host Integration', () {
    test('ExtensionDoctorValidator delegates to single extension in ExtensionManager', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

      final List<DiagnosticsExtension> extensions = manager.diagnosticsExtensions;
      expect(extensions, hasLength(1));

      final validator = ExtensionDoctorValidator(extension: extensions.first, logger: logger);
      final ValidationResult result = await validator.validate();
      expect(validator.title, 'Linux Custom Extension Prototype');
      expect(result.type, ValidationType.success);
      expect(result.messages, hasLength(3));
      expect(result.messages.first.message, 'Linux custom extension toolchain is operational');

      await manager.dispose();
    });

    test(
      'ExtensionDoctorValidator creates individual validators with titles per extension',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint]);

        final validators = <ExtensionDoctorValidator>[
          ...manager.diagnosticsExtensions.map(
            (DiagnosticsExtension ext) => ExtensionDoctorValidator(extension: ext, logger: logger),
          ),
          ExtensionDoctorValidator(extension: _SecondaryTestDiagnostics(), logger: logger),
        ];

        expect(validators, hasLength(2));

        final ValidationResult result0 = await validators[0].validate();
        expect(validators[0].title, 'Linux Custom Extension Prototype');
        expect(result0.type, ValidationType.success);
        expect(result0.messages, hasLength(3));

        final ValidationResult result1 = await validators[1].validate();
        expect(validators[1].title, 'Secondary Diagnostic Check');
        expect(result1.type, ValidationType.success);
        expect(result1.messages.last.message, 'Secondary diagnostic check operational');

        await manager.dispose();
      },
    );

    testWithoutContext('reports extension-attributed ValidationType.crash and logs extension name when runDiagnostics RPC throws', () async {
      void crashingEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_CrashingDiagnosticsExtension()],
          extensionName: 'my_test_extension',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      addTearDown(manager.dispose);
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[crashingEntryPoint]);

      final DiagnosticsExtension extension = manager.diagnosticsExtensions.single;
      final List<ValidationResult> clientResults = await extension.runDiagnostics();
      expect(clientResults, hasLength(1));
      expect(clientResults.single.type, ValidationType.crash);
      expect(
        clientResults.single.messages.first.message,
        'Due to an error in tool extension "my_test_extension", the doctor check did not complete. '
        'Please report this issue to the extension author.',
      );
      expect(
        clientResults.single.messages.map((ValidationMessage m) => m.message),
        everyElement(isNot(contains('flutter/flutter/issues'))),
      );
      expect(logger.warningText, contains('my_test_extension'));

      final validator = ExtensionDoctorValidator(extension: extension, logger: logger);
      final ValidationResult result = await validator.validate();

      expect(validator.title, 'Crashing Diagnostic Check');
      expect(result.type, ValidationType.crash);
      expect(result.leadingBox, '[☠]');
      expect(result.statusInfo, 'the doctor check crashed');
      expect(
        result.messages.first.message,
        'Due to an error in tool extension "my_test_extension", the doctor check did not complete. '
        'Please report this issue to the extension author.',
      );
      expect(
        result.messages.map((ValidationMessage m) => m.message),
        anyElement(contains('Simulated extension diagnostics failure')),
      );
      expect(
        result.messages.map((ValidationMessage m) => m.message),
        everyElement(isNot(contains('flutter/flutter/issues'))),
      );
    });

    testWithoutContext('reports extension-attributed ValidationType.crash and logs extension name when runDiagnostics returns malformed payload', () async {
      void nonListPayloadEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_RawPayloadDiagnosticsService('not-a-list')],
          extensionName: 'non_list_diagnostics_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      void invalidElementPayloadEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _RawPayloadDiagnosticsService(const <Object?>[
              <String, Object?>{
                ValidationResult.typeKey: 'unknown_type',
                ValidationResult.messagesKey: <Map<String, Object?>>[],
              },
            ]),
          ],
          extensionName: 'invalid_element_diagnostics_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      addTearDown(manager.dispose);
      await manager.initialize(
        entryPoints: <ExtensionEntryPoint>[
          nonListPayloadEntryPoint,
          invalidElementPayloadEntryPoint,
        ],
      );

      expect(manager.diagnosticsExtensions, hasLength(2));

      final firstValidator = ExtensionDoctorValidator(
        extension: manager.diagnosticsExtensions[0],
        logger: logger,
      );
      final ValidationResult firstResult = await firstValidator.validate();
      expect(firstResult.type, ValidationType.crash);
      expect(firstResult.leadingBox, '[☠]');
      expect(
        firstResult.messages.first.message,
        'Due to an error in tool extension "non_list_diagnostics_ext", the doctor check did not complete. '
        'Please report this issue to the extension author.',
      );
      expect(
        firstResult.messages.map((ValidationMessage m) => m.message),
        anyElement(contains('FormatException')),
      );
      expect(
        firstResult.messages.map((ValidationMessage m) => m.message),
        everyElement(isNot(contains('flutter/flutter/issues'))),
      );
      expect(logger.warningText, contains('non_list_diagnostics_ext'));

      final secondValidator = ExtensionDoctorValidator(
        extension: manager.diagnosticsExtensions[1],
        logger: logger,
      );
      final ValidationResult secondResult = await secondValidator.validate();
      expect(secondResult.type, ValidationType.crash);
      expect(secondResult.leadingBox, '[☠]');
      expect(
        secondResult.messages.first.message,
        'Due to an error in tool extension "invalid_element_diagnostics_ext", the doctor check did not complete. '
        'Please report this issue to the extension author.',
      );
      expect(
        secondResult.messages.map((ValidationMessage m) => m.message),
        anyElement(contains('unknown_type')),
      );
      expect(
        secondResult.messages.map((ValidationMessage m) => m.message),
        everyElement(isNot(contains('flutter/flutter/issues'))),
      );
      expect(logger.warningText, contains('invalid_element_diagnostics_ext'));
    });

    testWithoutContext('DiagnosticsExtensionClient.runDiagnostics allows slow checks past 5 seconds without timing out', () {
      final logger = BufferLogger.test();
      bool? diagnoseSucceeded;
      FakeAsync().run<void>((FakeAsync time) {
        final responseCompleter = Completer<Object?>();
        final connection = _DelayedDiagnosticsConnection(responseFuture: responseCompleter.future);
        final client = DiagnosticsExtensionClient(connection, logger: logger);
        unawaited(client.fetchTitle());
        time.flushMicrotasks();

        final slowDoctor = _TestExtensionDoctor(
          logger: logger,
          validators: <DoctorValidator>[
            ExtensionDoctorValidator(extension: client, logger: logger),
          ],
        );
        unawaited(
          slowDoctor.diagnose(verbose: false, sendEvent: false).then((bool result) {
            diagnoseSucceeded = result;
          }),
        );
        time.elapse(const Duration(seconds: 6));
        time.flushMicrotasks();
        expect(diagnoseSucceeded, isNull);
        expect(logger.warningText, isEmpty);

        responseCompleter.complete(<Map<String, Object?>>[
          ValidationResult(ValidationType.success, const <ValidationMessage>[
            ValidationMessage('Slow check passed'),
          ], statusInfo: 'Slow OK').toMap(),
        ]);
        time.flushMicrotasks();
      });

      expect(diagnoseSucceeded, isTrue);
      expect(logger.warningText, isEmpty);
      expect(logger.statusText, contains('[✓] Slow Diagnostic Check (Slow OK)'));
    });

    testWithoutContext('Doctor.diagnose uses ExtensionDoctorValidator.createCrashResult when extension validator throws directly', () async {
      final directLogger = BufferLogger.test();
      final directDoctor = _TestExtensionDoctor(
        logger: directLogger,
        validators: <DoctorValidator>[
          ExtensionDoctorValidator(
            extension: _CrashingDiagnosticsExtension(),
            logger: directLogger,
          ),
        ],
      );
      expect(await directDoctor.diagnose(verbose: false, sendEvent: false), isFalse);
      expect(
        directLogger.statusText,
        contains(
          'Due to an error in tool extension "Crashing Diagnostic Check", the doctor check did not complete. '
          'Please report this issue to the extension author.',
        ),
      );
      expect(directLogger.statusText, isNot(contains('flutter/flutter/issues')));
    });

    testWithoutContext('Doctor.diagnose uses ExtensionDoctorValidator.createCrashResult when extension exceeds doctorDuration', () async {
      final clientLogger = BufferLogger.test();
      void hangingEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_HangingDiagnosticsExtension()],
          extensionName: 'my_test_extension',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection connection = await ExtensionConnection.spawn(
        hangingEntryPoint,
        logger: clientLogger,
      );
      addTearDown(connection.dispose);
      final client = DiagnosticsExtensionClient(connection, logger: clientLogger);
      await client.fetchTitle();

      bool? diagnoseSucceeded;
      FakeAsync().run<void>((FakeAsync time) {
        final timeoutDoctor = _TestExtensionDoctor(
          logger: clientLogger,
          validators: <DoctorValidator>[
            ExtensionDoctorValidator(extension: client, logger: clientLogger),
          ],
        );
        unawaited(
          timeoutDoctor.diagnose(verbose: false, sendEvent: false).then((bool result) {
            diagnoseSucceeded = result;
          }),
        );
        time.elapse(const Duration(seconds: 6));
        time.flushMicrotasks();
        expect(diagnoseSucceeded, isNull);

        time.elapse(const Duration(minutes: 5));
        time.flushMicrotasks();
      });

      expect(diagnoseSucceeded, isFalse);
      expect(clientLogger.warningText, isEmpty);
      expect(
        clientLogger.statusText,
        contains('Hanging Diagnostic Check exceeded maximum allowed duration of '),
      );
      expect(
        clientLogger.statusText,
        contains(
          'Due to an error in tool extension "my_test_extension", the doctor check did not complete. '
          'Please report this issue to the extension author.',
        ),
      );
      expect(clientLogger.statusText, isNot(contains('flutter/flutter/issues')));
    });

    test(
      'DiagnosticsExtensionClient converts ToolExtensionException into failed ValidationResult',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        addTearDown(manager.dispose);
        await manager.initialize(
          entryPoints: <ExtensionEntryPoint>[_domainErrorDiagnosticsEntryPoint],
        );

        final List<DiagnosticsExtension> extensions = manager.diagnosticsExtensions;
        expect(extensions, hasLength(1));

        final validator = ExtensionDoctorValidator(extension: extensions.single, logger: logger);
        final ValidationResult result = await validator.validate();
        expect(result.type, ValidationType.missing);
        expect(result.messages, hasLength(1));
        expect(result.messages.single.message, 'Diagnostics failed with actionable user error.');
      },
    );
  });
}
