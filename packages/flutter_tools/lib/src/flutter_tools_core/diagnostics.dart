// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../generic_extension_protocol.dart';

/// The service responsible for executing custom diagnostic checks that
/// can be reported via `flutter doctor`.
abstract base class DiagnosticsService extends ToolExtensionService {
  @override
  String get namespace => 'diagnostics';

  /// Runs all diagnostic checks and returns the results.
  Future<List<ValidationResult>> runDiagnostics();
}

/// Represents the overall status of the diagnostic check.
enum ValidationType { crash, missing, partial, notAvailable, success }

/// The severity of a specific validation message.
enum ValidationMessageType { error, hint, information }

/// A specific message output by the diagnostic validator.
class ValidationMessage {
  /// Create an information message.
  const ValidationMessage(this.message, {this.contextUrl, String? piiStrippedMessage})
    : type = ValidationMessageType.information,
      piiStrippedMessage = piiStrippedMessage ?? message;

  /// Create an error message.
  const ValidationMessage.error(this.message, {String? piiStrippedMessage})
    : type = ValidationMessageType.error,
      piiStrippedMessage = piiStrippedMessage ?? message,
      contextUrl = null;

  /// Create a hint message.
  const ValidationMessage.hint(this.message, {String? piiStrippedMessage})
    : type = ValidationMessageType.hint,
      piiStrippedMessage = piiStrippedMessage ?? message,
      contextUrl = null;

  /// The severity/type of the message.
  final ValidationMessageType type;

  /// An optional URL for diagnostic context help.
  final String? contextUrl;

  /// The message string.
  final String message;

  /// Optional PII-stripped version of the message.
  final String piiStrippedMessage;
}

/// The outcome of a single diagnostic check.
class ValidationResult {
  ValidationResult(this.type, this.messages, {this.statusInfo});

  /// The status category of validation.
  final ValidationType type;

  /// Additional status info.
  final String? statusInfo;

  /// The messages logged during validation.
  final List<ValidationMessage> messages;
}
