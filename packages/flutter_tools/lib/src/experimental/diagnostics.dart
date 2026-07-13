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
  ExtensionDoctorValidator({required this.extension, required Logger logger})
    : _logger = logger,
      super(extension.title);

  /// The active extension service executing diagnostic checks.
  final DiagnosticsExtension extension;
  final Logger _logger;

  @override
  String get title => extension.title;

  @override
  Future<ValidationResult> validateImpl() async {
    _logger.printTrace(
      'ExtensionDoctorValidator validating diagnostics for extension "${extension.title}".',
    );
    final DiagnosticsExtension ext = extension;
    if (ext is DiagnosticsExtensionClient) {
      await ext.fetchTitle();
    }
    final List<ValidationResult> results = await ext.runDiagnostics();
    _logger.printTrace(
      'ExtensionDoctorValidator received ${results.length} validation result(s) from "${extension.title}".',
    );
    final allMessages = <ValidationMessage>[];
    ValidationType aggregateType = ValidationType.success;
    String? statusInfo;

    for (final result in results) {
      statusInfo ??= result.statusInfo;
      allMessages.addAll(result.messages);
      if (result.type == ValidationType.crash) {
        aggregateType = ValidationType.crash;
      } else if (result.type == ValidationType.missing && aggregateType != ValidationType.crash) {
        aggregateType = ValidationType.missing;
      } else if (result.type == ValidationType.partial &&
          aggregateType != ValidationType.crash &&
          aggregateType != ValidationType.missing) {
        aggregateType = ValidationType.partial;
      } else if (result.type == ValidationType.notAvailable &&
          aggregateType != ValidationType.crash &&
          aggregateType != ValidationType.missing &&
          aggregateType != ValidationType.partial) {
        aggregateType = ValidationType.notAvailable;
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
    required Logger logger,
    String defaultTitle = 'Tool Extension Diagnostics',
  }) : _defaultTitle = defaultTitle,
       _logger = logger;

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
    _titleCache = (await connection.sendRequest(DiagnosticsExtension.getTitleMethod))! as String;
    _logger.printTrace('DiagnosticsExtensionClient received title: "$_titleCache".');
    return _titleCache!;
  }

  @override
  Future<List<ValidationResult>> runDiagnostics() async {
    _logger.printTrace(
      'DiagnosticsExtensionClient running diagnostics via RPC ("${DiagnosticsExtension.runDiagnosticsMethod}")...',
    );
    final rawResult =
        (await connection.sendRequest(DiagnosticsExtension.runDiagnosticsMethod))! as List<Object?>;
    final List<ValidationResult> results = rawResult
        .cast<Map<String, Object?>>()
        .map(ValidationResult.fromJson)
        .toList();
    _logger.printTrace('DiagnosticsExtensionClient received ${results.length} result(s) via RPC.');
    return results;
  }
}
