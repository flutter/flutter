// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Represents the overall status category of a diagnostic validation check.
enum ValidationType {
  /// An unhandled exception or crash occurred during check execution.
  crash,

  /// Required tooling or dependencies are missing.
  missing,

  /// The check found partial issues or non-fatal warnings.
  partial,

  /// Diagnostic check is not applicable or available on the current host.
  notAvailable,

  /// The check completed successfully with no issues found.
  success,
}

/// The severity level of a specific diagnostic validation message.
enum ValidationMessageType {
  /// Fatal or non-fatal error message.
  error,

  /// Suggestion or hint message.
  hint,

  /// General diagnostic information message.
  information,
}

/// A specific message output during a diagnostic validation check.
@immutable
class ValidationMessage {
  /// Creates an information level diagnostic [ValidationMessage].
  const ValidationMessage(this.message, {this.contextUrl, String? piiStrippedMessage})
    : type = ValidationMessageType.information,
      piiStrippedMessage = piiStrippedMessage ?? message;

  /// Creates an error level diagnostic [ValidationMessage].
  const ValidationMessage.error(this.message, {String? piiStrippedMessage})
    : type = ValidationMessageType.error,
      contextUrl = null,
      piiStrippedMessage = piiStrippedMessage ?? message;

  /// Creates a hint level diagnostic [ValidationMessage].
  const ValidationMessage.hint(this.message, {String? piiStrippedMessage})
    : type = ValidationMessageType.hint,
      contextUrl = null,
      piiStrippedMessage = piiStrippedMessage ?? message;

  /// Deserializes a [ValidationMessage] from a JSON-serializable map.
  factory ValidationMessage.fromJson(Map<String, Object?> json) {
    final String message = json['message'] as String? ?? '';
    final piiStrippedMessage = json['piiStrippedMessage'] as String?;
    final contextUrl = json['contextUrl'] as String?;
    final String typeName = json['type'] as String? ?? 'information';
    final ValidationMessageType type = ValidationMessageType.values.firstWhere(
      (ValidationMessageType t) => t.name == typeName,
      orElse: () => ValidationMessageType.information,
    );

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

  /// Severity level of the validation message.
  final ValidationMessageType type;

  /// The text content of the validation message.
  final String message;

  /// Optional URL providing additional context or documentation.
  final String? contextUrl;

  /// Optional version of [message] with Personally Identifiable Information (PII) removed.
  final String piiStrippedMessage;

  /// Whether this is an error-level validation message.
  bool get isError => type == ValidationMessageType.error;

  /// Whether this is a hint-level validation message.
  bool get isHint => type == ValidationMessageType.hint;

  /// Whether this is an informational validation message.
  bool get isInformation => type == ValidationMessageType.information;

  /// Serializes the validation message to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    'type': type.name,
    'message': message,
    'contextUrl': ?contextUrl,
    'piiStrippedMessage': piiStrippedMessage,
  };

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    return other is ValidationMessage &&
        other.message == message &&
        other.type == type &&
        other.contextUrl == contextUrl;
  }

  @override
  int get hashCode => Object.hash(type, message, contextUrl);
}

/// The outcome of a single diagnostic check.
class ValidationResult {
  /// Creates a [ValidationResult] with status [type] and list of [messages].
  ValidationResult(this.type, this.messages, {this.statusInfo});

  /// Creates a [ValidationResult] representing a crash during execution.
  factory ValidationResult.crash(Object error, [StackTrace? stackTrace]) {
    return ValidationResult(ValidationType.crash, <ValidationMessage>[
      const ValidationMessage.error(
        'Due to an error, the doctor check did not complete. '
        'If the error message below is not helpful, '
        'please let us know about this issue at https://github.com/flutter/flutter/issues.',
      ),
      ValidationMessage.error('$error'),
      if (stackTrace != null) ValidationMessage('$stackTrace'),
    ], statusInfo: 'the doctor check crashed');
  }

  /// Deserializes a [ValidationResult] from a JSON-serializable map.
  factory ValidationResult.fromJson(Map<String, Object?> json) {
    final String typeName = json['type'] as String? ?? 'success';
    final ValidationType type = ValidationType.values.firstWhere(
      (ValidationType t) => t.name == typeName,
      orElse: () => ValidationType.success,
    );
    final statusInfo = json['statusInfo'] as String?;

    final Object? messagesJson = json['messages'];
    final messages = <ValidationMessage>[
      if (messagesJson is List)
        for (final Object? item in messagesJson)
          if (item is Map) ValidationMessage.fromJson(item.cast<String, Object?>()),
    ];

    return ValidationResult(type, messages, statusInfo: statusInfo);
  }

  /// Status category of the diagnostic check.
  final ValidationType type;

  /// Additional status information text.
  final String? statusInfo;

  /// Diagnostic messages logged during validation.
  final List<ValidationMessage> messages;

  /// The time taken to perform the validation.
  Duration? executionTime;

  /// Serializes the validation result to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    'type': type.name,
    'statusInfo': ?statusInfo,
    'messages': messages.map((ValidationMessage m) => m.toMap()).toList(),
  };

  @override
  String toString() {
    return '$runtimeType($type, $messages, $statusInfo)';
  }
}
