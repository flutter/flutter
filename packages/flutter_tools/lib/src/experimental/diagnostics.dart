// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/logger.dart';
import '../base/platform.dart';
import '../doctor_validator.dart'
    show
        DoctorValidator,
        ValidationMessage,
        ValidationMessageType,
        ValidationResult,
        ValidationType;
import '../flutter_tools_core/diagnostics.dart' as core;
import '../generic_extension_protocol/manager.dart';
import '../globals.dart' as globals;
import 'extension_discovery.dart';

/// A host-side doctor validator that delegates diagnostics to tool extensions.
class ExtensionDoctorValidator extends DoctorValidator {
  ExtensionDoctorValidator(
    ToolExtensionManager extensionManager, {
    Logger? logger,
    Platform? platform,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         extensionManager: extensionManager,
         logger: logger ?? globals.logger,
         platform: platform ?? globals.platform,
       ),
       super('Extension-backed Diagnostics');

  final ExtensionDiscoveryHelper _discoveryHelper;

  @override
  Future<ValidationResult> validateImpl() async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      return ValidationResult(ValidationType.notAvailable, const <ValidationMessage>[
        ValidationMessage('Tool extension prototype is not enabled.'),
      ], statusInfo: 'disabled');
    }

    final subResults = <ValidationResult>[];

    for (final ToolExtension toolExtension in await _discoveryHelper.getExtensionsSupporting(
      core.DiagnosticsService.serviceNamespace,
    )) {
      try {
        final Object? diagnosticsResult = await toolExtension.callMethod(
          core.DiagnosticsService.runDiagnosticsMethod,
        );
        for (final core.ValidationResult coreResult in core.ValidationResult.listFromJson(
          diagnosticsResult,
        )) {
          subResults.add(_mapCoreResultToHost(coreResult));
        }
      } on Object catch (e) {
        subResults.add(
          ValidationResult(ValidationType.missing, <ValidationMessage>[
            ValidationMessage.error('Diagnostics extension call failed: $e'),
          ], statusInfo: 'error'),
        );
      }
    }

    return _mergeValidationResults(subResults);
  }

  ValidationResult _mapCoreResultToHost(core.ValidationResult coreResult) {
    final List<ValidationMessage> hostMessages = coreResult.messages.map((
      core.ValidationMessage msg,
    ) {
      return switch (msg.type) {
        ValidationMessageType.error => ValidationMessage.error(
          msg.message,
          piiStrippedMessage: msg.piiStrippedMessage,
        ),
        ValidationMessageType.hint => ValidationMessage.hint(
          msg.message,
          piiStrippedMessage: msg.piiStrippedMessage,
        ),
        ValidationMessageType.information => ValidationMessage(
          msg.message,
          contextUrl: msg.contextUrl,
          piiStrippedMessage: msg.piiStrippedMessage,
        ),
      };
    }).toList();

    return ValidationResult(coreResult.type, hostMessages, statusInfo: coreResult.statusInfo);
  }

  ValidationResult _mergeValidationResults(List<ValidationResult> results) {
    if (results.isEmpty) {
      return ValidationResult(
        ValidationType.success,
        const <ValidationMessage>[],
        statusInfo: 'no checks executed',
      );
    }

    final mergedMessages = <ValidationMessage>[];
    String? statusInfo;
    final types = <ValidationType>{};

    for (final result in results) {
      statusInfo ??= result.statusInfo;
      types.add(result.type);
      mergedMessages.addAll(result.messages);
    }

    if (types.length > 1) {
      types.remove(ValidationType.notAvailable);
    }

    final ValidationType mergedType = switch ((
      types.contains(ValidationType.crash),
      types.contains(ValidationType.missing),
      types.contains(ValidationType.partial),
      types.contains(ValidationType.success),
    )) {
      (_, _, true, _) || (true, _, _, true) || (_, true, _, true) => ValidationType.partial,
      (true, _, _, _) => ValidationType.crash,
      (_, true, _, _) => ValidationType.missing,
      (_, _, _, true) => ValidationType.success,
      _ => ValidationType.notAvailable,
    };

    return ValidationResult(mergedType, mergedMessages, statusInfo: statusInfo);
  }
}
