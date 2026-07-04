// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/logger.dart';
import '../base/platform.dart';
import '../doctor_validator.dart' as host_doctor;
import '../flutter_tools_core/diagnostics.dart' as core;
import '../generic_extension_protocol/manager.dart';
import '../globals.dart' as globals;
import 'extension_discovery.dart';

/// A host-side doctor validator that delegates diagnostics to tool extensions.
class ExtensionDoctorValidator extends host_doctor.DoctorValidator {
  ExtensionDoctorValidator(
    ToolExtensionManager extensionManager, {
    Logger? logger,
    Platform? platform,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger ?? globals.logger,
         extensionManager: extensionManager,
         platform: platform ?? globals.platform,
       ),
       super('Extension-backed Diagnostics');

  final ExtensionDiscoveryHelper _discoveryHelper;

  static const String _serviceNamespace = 'diagnostics';
  static const String _runDiagnosticsMethod = 'diagnostics.runDiagnostics';

  @override
  Future<host_doctor.ValidationResult> validateImpl() async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      return host_doctor.ValidationResult(
        host_doctor.ValidationType.notAvailable,
        const <host_doctor.ValidationMessage>[
          host_doctor.ValidationMessage('Tool extension prototype is not enabled.'),
        ],
        statusInfo: 'disabled',
      );
    }

    final subResults = <host_doctor.ValidationResult>[];

    for (final ToolExtension extension in await _discoveryHelper.getExtensionsSupporting(
      _serviceNamespace,
    )) {
      try {
        final Object? diagnosticsResult = await extension.callMethod(_runDiagnosticsMethod);
        if (diagnosticsResult case final List<Object?> items) {
          for (final item in items) {
            if (item case final Map<Object?, Object?> rawMap) {
              final coreResult = core.ValidationResult.fromJson(rawMap.cast<String, Object?>());
              subResults.add(_mapCoreResultToHost(coreResult));
            }
          }
        }
      } on Object catch (e) {
        subResults.add(
          host_doctor.ValidationResult(
            host_doctor.ValidationType.missing,
            <host_doctor.ValidationMessage>[
              host_doctor.ValidationMessage.error('Diagnostics extension call failed: $e'),
            ],
            statusInfo: 'error',
          ),
        );
      }
    }

    return _mergeValidationResults(subResults);
  }

  host_doctor.ValidationResult _mapCoreResultToHost(core.ValidationResult coreResult) {
    final List<host_doctor.ValidationMessage> hostMessages = coreResult.messages.map((
      core.ValidationMessage msg,
    ) {
      return switch (msg.type) {
        host_doctor.ValidationMessageType.error => host_doctor.ValidationMessage.error(
          msg.message,
          piiStrippedMessage: msg.piiStrippedMessage,
        ),
        host_doctor.ValidationMessageType.hint => host_doctor.ValidationMessage.hint(
          msg.message,
          piiStrippedMessage: msg.piiStrippedMessage,
        ),
        host_doctor.ValidationMessageType.information => host_doctor.ValidationMessage(
          msg.message,
          contextUrl: msg.contextUrl,
          piiStrippedMessage: msg.piiStrippedMessage,
        ),
      };
    }).toList();

    return host_doctor.ValidationResult(
      coreResult.type,
      hostMessages,
      statusInfo: coreResult.statusInfo,
    );
  }

  host_doctor.ValidationResult _mergeValidationResults(List<host_doctor.ValidationResult> results) {
    if (results.isEmpty) {
      return host_doctor.ValidationResult(
        host_doctor.ValidationType.success,
        const <host_doctor.ValidationMessage>[],
        statusInfo: 'no checks executed',
      );
    }

    final mergedMessages = <host_doctor.ValidationMessage>[];
    String? statusInfo;
    final types = <host_doctor.ValidationType>{};

    for (final result in results) {
      statusInfo ??= result.statusInfo;
      types.add(result.type);
      mergedMessages.addAll(result.messages);
    }

    if (types.length > 1) {
      types.remove(host_doctor.ValidationType.notAvailable);
    }

    final host_doctor.ValidationType mergedType = switch (types) {
      _
          when types.contains(host_doctor.ValidationType.partial) ||
              (types.contains(host_doctor.ValidationType.crash) &&
                  types.contains(host_doctor.ValidationType.success)) ||
              (types.contains(host_doctor.ValidationType.missing) &&
                  types.contains(host_doctor.ValidationType.success)) =>
        host_doctor.ValidationType.partial,
      _ when types.contains(host_doctor.ValidationType.crash) => host_doctor.ValidationType.crash,
      _ when types.contains(host_doctor.ValidationType.missing) =>
        host_doctor.ValidationType.missing,
      _ when types.contains(host_doctor.ValidationType.success) =>
        host_doctor.ValidationType.success,
      _ => host_doctor.ValidationType.notAvailable,
    };

    return host_doctor.ValidationResult(mergedType, mergedMessages, statusInfo: statusInfo);
  }
}
