// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/experimental/diagnostics.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:test/test.dart';

import '../../src/fakes.dart';

class _SecondaryTestDiagnostics extends DiagnosticsExtension {
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

    test(
      'reports ValidationType.crash and logs extension name when runDiagnostics RPC throws',
      () async {
        void crashingEntryPoint(SendPort sendPort) {
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[_CrashingDiagnosticsExtension()],
            extensionName: 'crashing_diagnostics_ext',
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

        final validator = ExtensionDoctorValidator(
          extension: manager.diagnosticsExtensions.single,
          logger: logger,
        );
        final ValidationResult result = await validator.validate();

        expect(validator.title, 'Crashing Diagnostic Check');
        expect(result.type, ValidationType.crash);
        expect(result.leadingBox, '[☠]');
        expect(result.statusInfo, 'the doctor check crashed');
        expect(
          result.messages.map((ValidationMessage m) => m.message),
          anyElement(contains('Simulated extension diagnostics failure')),
        );
        expect(logger.warningText, contains('crashing_diagnostics_ext'));
      },
    );

    test('reports ValidationType.crash and logs extension name when runDiagnostics returns malformed payload', () async {
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
        firstResult.messages.map((ValidationMessage m) => m.message),
        anyElement(contains('FormatException')),
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
        secondResult.messages.map((ValidationMessage m) => m.message),
        anyElement(contains('unknown_type')),
      );
      expect(logger.warningText, contains('invalid_element_diagnostics_ext'));
    });
  });
}
