// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
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
  });
}
