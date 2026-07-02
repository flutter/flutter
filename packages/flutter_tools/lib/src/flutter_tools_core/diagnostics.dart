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

  @override
  Future<Map<String, Function>> initialize() async {
    return <String, Function>{'runDiagnostics': _runDiagnosticsRpc};
  }

  Future<List<Map<String, Object?>>> _runDiagnosticsRpc(Map<String, Object?> params) async {
    final List<ValidationResult> results = await runDiagnostics();
    return results.map((ValidationResult r) => r.toMap()).toList();
  }
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

  /// Create a ValidationMessage from a JSON map.
  factory ValidationMessage.fromJson(Map<String, Object?> json) {
    final message = json['message']! as String;
    final piiStrippedMessage = json['piiStrippedMessage'] as String?;
    final contextUrl = json['contextUrl'] as String?;
    final typeName = json['type']! as String;
    final ValidationMessageType type = ValidationMessageType.values.byName(typeName);
    return switch (type) {
      ValidationMessageType.error => ValidationMessage.error(
        message,
        piiStrippedMessage: piiStrippedMessage,
      ),
      ValidationMessageType.hint => ValidationMessage.hint(
        message,
        piiStrippedMessage: piiStrippedMessage,
      ),
      ValidationMessageType.information => ValidationMessage(
        message,
        contextUrl: contextUrl,
        piiStrippedMessage: piiStrippedMessage,
      ),
    };
  }

  /// The severity/type of the message.
  final ValidationMessageType type;

  /// An optional URL for diagnostic context help.
  final String? contextUrl;

  /// The message string.
  final String message;

  /// Optional PII-stripped version of the message.
  final String piiStrippedMessage;

  /// Convert the ValidationMessage to a JSON-compatible map.
  Map<String, Object?> toMap() => <String, Object?>{
    'type': type.name,
    'contextUrl': contextUrl,
    'message': message,
    'piiStrippedMessage': piiStrippedMessage,
  };
}

/// The outcome of a single diagnostic check.
class ValidationResult {
  ValidationResult(this.type, this.messages, {this.statusInfo});

  /// Create a ValidationResult from a JSON map.
  factory ValidationResult.fromJson(Map<String, Object?> json) {
    final typeName = json['type']! as String;
    final ValidationType type = ValidationType.values.byName(typeName);
    final statusInfo = json['statusInfo'] as String?;
    final messagesJson = json['messages']! as List<Object?>;
    final messages = List<ValidationMessage>.from(
      messagesJson.map(
        (msg) =>
            ValidationMessage.fromJson((msg! as Map<Object?, Object?>).cast<String, Object?>()),
      ),
    );
    return ValidationResult(type, messages, statusInfo: statusInfo);
  }

  /// The status category of validation.
  final ValidationType type;

  /// Additional status info.
  final String? statusInfo;

  /// The messages logged during validation.
  final List<ValidationMessage> messages;

  /// Convert the ValidationResult to a JSON-compatible map.
  Map<String, Object?> toMap() => <String, Object?>{
    'type': type.name,
    'statusInfo': statusInfo,
    'messages': messages.map((ValidationMessage m) => m.toMap()).toList(),
  };
}
