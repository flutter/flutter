// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/logger.dart';
import '../doctor_validator.dart';
import 'extension_discovery.dart';

/// A host [DoctorValidator] adapter that delegates diagnostic checks to a single tool extension.
class ExtensionDoctorValidator extends DoctorValidator {
  /// Creates an [ExtensionDoctorValidator] for the given diagnostic [extension].
  ExtensionDoctorValidator({required this.extension, required this._logger})
    : super(extension.title);

  /// Creates a [ValidationResult] attributing a diagnostic crash to the
  /// tool extension identified by [extensionIdentifier].
  static ValidationResult createExtensionCrashResult(
    String extensionIdentifier,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    return ValidationResult(ValidationType.crash, <ValidationMessage>[
      ValidationMessage.error(
        'Due to an error in tool extension "$extensionIdentifier", the doctor check did not complete. '
        'Please report this issue to the extension author.',
      ),
      ValidationMessage.error('$error'),
      if (stackTrace != null) ValidationMessage('$stackTrace'),
    ], statusInfo: 'the doctor check crashed');
  }

  /// The active extension service executing diagnostic checks.
  final DiagnosticsExtension extension;
  final Logger _logger;

  @override
  String get title => extension.title;

  @override
  ValidationResult createCrashResult(Object error, [StackTrace? stackTrace]) {
    final String extensionIdentifier = switch (extension) {
      DiagnosticsExtensionClient(:final ExtensionConnection connection) => connection.extensionName,
      _ => extension.title,
    };
    return createExtensionCrashResult(extensionIdentifier, error, stackTrace);
  }

  @override
  Future<ValidationResult> validateImpl() async {
    _logger.printTrace(
      'ExtensionDoctorValidator validating diagnostics for extension "${extension.title}".',
    );
    final List<ValidationResult> results = await extension.runDiagnostics();
    _logger.printTrace(
      'ExtensionDoctorValidator received ${results.length} validation result(s) from "${extension.title}".',
    );
    final allMessages = <ValidationMessage>[];
    ValidationType aggregateType = ValidationType.success;
    String? statusInfo;

    for (final result in results) {
      statusInfo ??= result.statusInfo;
      allMessages.addAll(result.messages);
      switch (result.type) {
        case ValidationType.crash:
          aggregateType = ValidationType.crash;
        case ValidationType.missing:
          if (aggregateType != ValidationType.crash) {
            aggregateType = ValidationType.missing;
          }
        case ValidationType.partial:
          if (aggregateType != ValidationType.crash && aggregateType != ValidationType.missing) {
            aggregateType = ValidationType.partial;
          }
        case ValidationType.notAvailable:
          if (aggregateType != ValidationType.crash &&
              aggregateType != ValidationType.missing &&
              aggregateType != ValidationType.partial) {
            aggregateType = ValidationType.notAvailable;
          }
        case ValidationType.success:
          break;
      }
    }

    return ValidationResult(aggregateType, allMessages, statusInfo: statusInfo);
  }
}

/// A host-side [DiagnosticsExtension] client adapter that delegates RPC queries to an [ExtensionConnection].
class DiagnosticsExtensionClient extends DiagnosticsExtension {
  /// Creates a [DiagnosticsExtensionClient] wrapping the host [connection].
  DiagnosticsExtensionClient(
    this.connection, {
    required this._logger,
    this._defaultTitle = 'Tool Extension Diagnostics',
  });

  /// The active extension isolate connection.
  final ExtensionConnection connection;
  final String _defaultTitle;
  final Logger _logger;
  String? _titleCache;

  @override
  String get title => _titleCache ?? _defaultTitle;

  /// Fetches the validator title from the remote extension isolate.
  Future<String> fetchTitle() async {
    if (_titleCache != null) {
      return _titleCache!;
    }
    _logger.printTrace(
      'DiagnosticsExtensionClient fetching title via RPC ("${DiagnosticsExtension.getTitleMethod}")...',
    );
    try {
      final Object? response = await connection.sendRequest(DiagnosticsExtension.getTitleMethod);
      if (response is String) {
        _titleCache = response;
      } else {
        _logger.printTrace('DiagnosticsExtensionClient received invalid title response: $response');
      }
    } on Object catch (err, stack) {
      _logger.printTrace('DiagnosticsExtensionClient failed to fetch title: $err\n$stack');
    }
    return _titleCache ?? _defaultTitle;
  }

  @override
  Future<List<ValidationResult>> runDiagnostics() async {
    _logger.printTrace(
      'DiagnosticsExtensionClient running diagnostics via RPC ("${DiagnosticsExtension.runDiagnosticsMethod}")...',
    );
    try {
      final Object? result = await connection.sendRequest(
        DiagnosticsExtension.runDiagnosticsMethod,
        timeout: null,
      );
      final List<ValidationResult> results = ValidationResult.listFromJson(result);
      _logger.printTrace(
        'DiagnosticsExtensionClient received ${results.length} result(s) via RPC.',
      );
      return results;
    } on Object catch (err, stack) {
      _logger.printWarning(
        'Failed to run diagnostics for extension "${connection.extensionName}": $err',
      );
      _logger.printTrace('$stack');
      return <ValidationResult>[
        ExtensionDoctorValidator.createExtensionCrashResult(connection.extensionName, err, stack),
      ];
    }
  }
}
