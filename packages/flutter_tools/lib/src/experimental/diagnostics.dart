// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Diagnostics doctor validator for tool extensions.
///
/// This library defines a [host_doctor.DoctorValidator] that delegates diagnostic checks
/// to active tool extensions and merges their results.
library experimental.diagnostics;

import 'dart:async';

import '../base/context.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../doctor_validator.dart' as host_doctor;
import '../flutter_tools_core/diagnostics.dart' as core;
import '../generic_extension_protocol/manager.dart';
import 'extension_discovery.dart';

/// Retrieve the [ExtensionDiagnosticsManager] from the context.
ExtensionDiagnosticsManager? get extensionDiagnosticsManager =>
    context.get<ExtensionDiagnosticsManager>();

/// Manages executing diagnostics from extension isolates.
base class ExtensionDiagnosticsManager extends core.DiagnosticsService {
  ExtensionDiagnosticsManager({
    required ToolExtensionManager extensionManager,
    required Logger logger,
    required Platform platform,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger,
         extensionManager: extensionManager,
         platform: platform,
       );

  final ExtensionDiscoveryHelper _discoveryHelper;

  @override
  Future<List<core.ValidationResult>> runDiagnostics() async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      return const <core.ValidationResult>[];
    }

    final results = <core.ValidationResult>[];
    final List<ToolExtension> extensions = await _discoveryHelper.getExtensionsSupporting(
      core.DiagnosticsService.serviceNamespace,
    );

    for (final extension in extensions) {
      try {
        final Object? rpcResult = await extension
            .callMethod(core.DiagnosticsService.runDiagnosticsMethod)
            .timeout(const Duration(seconds: 5));

        results.addAll(core.ValidationResult.listFromJson(rpcResult));
      } on Object catch (e) {
        _discoveryHelper.logger.printError('Failed to get diagnostics from extension: $e');
        results.add(
          core.ValidationResult(core.ValidationType.missing, <core.ValidationMessage>[
            core.ValidationMessage.error('Diagnostics extension call failed: $e'),
          ], statusInfo: 'error'),
        );
      }
    }
    return results;
  }
}

/// A host-side doctor validator that delegates diagnostics to tool extensions.
///
/// This validator queries active [ToolExtension]s that support the diagnostics
/// service namespace, runs their diagnostics, and merges the results into
/// a single [host_doctor.ValidationResult] to be displayed by `flutter doctor`.
class ExtensionDoctorValidator extends host_doctor.DoctorValidator {
  ExtensionDoctorValidator(
    ToolExtensionManager extensionManager, {
    required Logger logger,
    required Platform platform,
    ExtensionDiagnosticsManager? diagnosticsManager,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger,
         extensionManager: extensionManager,
         platform: platform,
       ),
       _diagnosticsManager =
           diagnosticsManager ??
           (context.get<ToolExtensionManager>() == extensionManager
               ? extensionDiagnosticsManager
               : null) ??
           ExtensionDiagnosticsManager(
             extensionManager: extensionManager,
             logger: logger,
             platform: platform,
           ),
       super('Extension-backed Diagnostics');

  final ExtensionDiscoveryHelper _discoveryHelper;
  final ExtensionDiagnosticsManager _diagnosticsManager;

  /// Runs the diagnostics by calling `diagnostics.runDiagnostics` on all supporting extensions.
  ///
  /// If the prototype is disabled, it returns a result indicating it is not available.
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

    final List<core.ValidationResult> coreResults = await _diagnosticsManager.runDiagnostics();
    final List<host_doctor.ValidationResult> subResults = coreResults
        .map(_mapCoreResultToHost)
        .toList();

    return _mergeValidationResults(subResults);
  }

  /// Maps a [core.ValidationResult] from the extension to a host-side [host_doctor.ValidationResult].
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

  /// Merges multiple [host_doctor.ValidationResult]s into a single result.
  ///
  /// It combines all messages and determines the overall validation type based on
  /// the severity of the individual results (e.g., if any is partial, the merged result is partial).
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
