// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/logger.dart';
import '../base/platform.dart';
import '../doctor_validator.dart' as host_doctor;
import '../extension_prototypes/linux_extension/extension.dart';
import '../flutter_tools_core/diagnostics.dart' as core;
import '../generic_extension_protocol/manager.dart';
import '../generic_extension_protocol/service.dart';
import '../globals.dart' as globals;

/// A host-side doctor validator that delegates diagnostics to tool extensions.
class ExtensionDoctorValidator extends host_doctor.DoctorValidator {
  ExtensionDoctorValidator(this._extensionManager, {Logger? logger, Platform? platform})
    : _logger = logger ?? globals.logger,
      _platform = platform ?? globals.platform,
      super('Extension-backed Diagnostics');

  final ToolExtensionManager _extensionManager;
  final Logger _logger;
  final Platform _platform;

  static const String envPrototypeFlag = 'FLUTTER_TOOL_EXTENSION_PROTOTYPE';
  static const String _serviceNamespace = 'diagnostics';
  static const String _runDiagnosticsMethod = 'diagnostics.runDiagnostics';

  @override
  Future<host_doctor.ValidationResult> validateImpl() async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      return host_doctor.ValidationResult(
        host_doctor.ValidationType.notAvailable,
        const <host_doctor.ValidationMessage>[
          host_doctor.ValidationMessage('Tool extension prototype is not enabled.'),
        ],
        statusInfo: 'disabled',
      );
    }

    if (_extensionManager.extensions.isEmpty) {
      try {
        await _extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        return host_doctor.ValidationResult(
          host_doctor.ValidationType.missing,
          <host_doctor.ValidationMessage>[
            host_doctor.ValidationMessage.error('Failed to spawn prototype extension: $e'),
          ],
          statusInfo: 'failed to spawn extension',
        );
      }
    }

    final subResults = <host_doctor.ValidationResult>[];

    for (final ToolExtension extension in _extensionManager.extensions) {
      late final ToolExtensionCapabilities capabilities;
      try {
        capabilities = await extension.getCapabilities();
      } on Exception catch (e) {
        _logger.printTrace('Failed to get capabilities: $e');
        continue;
      }
      if (!capabilities.services.contains(_serviceNamespace)) {
        continue;
      }

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

    host_doctor.ValidationType mergedType;
    if (types.contains(host_doctor.ValidationType.crash)) {
      if (types.contains(host_doctor.ValidationType.success) ||
          types.contains(host_doctor.ValidationType.partial)) {
        mergedType = host_doctor.ValidationType.partial;
      } else {
        mergedType = host_doctor.ValidationType.crash;
      }
    } else if (types.contains(host_doctor.ValidationType.missing)) {
      if (types.contains(host_doctor.ValidationType.success) ||
          types.contains(host_doctor.ValidationType.partial)) {
        mergedType = host_doctor.ValidationType.partial;
      } else {
        mergedType = host_doctor.ValidationType.missing;
      }
    } else if (types.contains(host_doctor.ValidationType.partial)) {
      mergedType = host_doctor.ValidationType.partial;
    } else if (types.contains(host_doctor.ValidationType.success)) {
      mergedType = host_doctor.ValidationType.success;
    } else {
      mergedType = host_doctor.ValidationType.notAvailable;
    }

    return host_doctor.ValidationResult(mergedType, mergedMessages, statusInfo: statusInfo);
  }
}
