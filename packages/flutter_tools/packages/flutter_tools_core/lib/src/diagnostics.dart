// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'json_utils.dart';

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
final class ValidationMessage {
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
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory ValidationMessage.fromJson(Map<String, Object?> json) {
    final ValidationMessageType type = _parseMessageType(json.requiredField<String>(typeKey));
    final String message = json.requiredField<String>(messageKey);
    final String piiStrippedMessage = json.requiredField<String>(piiStrippedMessageKey);
    final String? contextUrl = json.nullableField<String>(contextUrlKey);
    if (contextUrl != null && type != ValidationMessageType.information) {
      throw FormatException(
        'Invalid "$contextUrlKey" in ValidationMessage: "$contextUrlKey" is only '
        'supported when "$typeKey" is "${ValidationMessageType.information.name}", '
        'got "${type.name}".',
      );
    }

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

  static ValidationMessageType _parseMessageType(String typeName) {
    for (final ValidationMessageType value in ValidationMessageType.values) {
      if (value.name == typeName) {
        return value;
      }
    }
    throw FormatException(
      'Invalid "$typeKey" in ValidationMessage: "$typeName". '
      'Expected one of: ${ValidationMessageType.values.map((ValidationMessageType t) => t.name).join(', ')}.',
    );
  }

  /// Map key for [contextUrl].
  static const String contextUrlKey = 'contextUrl';

  /// Map key for [message].
  static const String messageKey = 'message';

  /// Map key for [piiStrippedMessage].
  static const String piiStrippedMessageKey = 'piiStrippedMessage';

  /// Map key for [type].
  static const String typeKey = 'type';

  /// Severity level of the validation message.
  final ValidationMessageType type;

  /// The text content of the validation message.
  final String message;

  /// Optional URL providing additional context or documentation.
  final String? contextUrl;

  /// Version of [message] with Personally Identifiable Information (PII) removed.
  ///
  /// Defaults to [message] when omitted at construction.
  final String piiStrippedMessage;

  /// Whether this is an error-level validation message.
  bool get isError => type == ValidationMessageType.error;

  /// Whether this is a hint-level validation message.
  bool get isHint => type == ValidationMessageType.hint;

  /// Whether this is an informational validation message.
  bool get isInformation => type == ValidationMessageType.information;

  /// Serializes the validation message to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    typeKey: type.name,
    messageKey: message,
    contextUrlKey: ?contextUrl,
    piiStrippedMessageKey: piiStrippedMessage,
  };

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ValidationMessage &&
            other.message == message &&
            other.type == type &&
            other.contextUrl == contextUrl &&
            other.piiStrippedMessage == piiStrippedMessage);
  }

  @override
  int get hashCode => Object.hash(type, message, contextUrl, piiStrippedMessage);
}

/// The outcome of a single diagnostic check.
@immutable
final class ValidationResult {
  /// Creates a [ValidationResult] with status [type] and list of [messages].
  ValidationResult(
    this.type,
    List<ValidationMessage> messages, {
    this.executionTime,
    this.statusInfo,
  }) : messages = List<ValidationMessage>.unmodifiable(messages);

  /// Creates a [ValidationResult] representing a crash during execution.
  factory ValidationResult.crash(Object error, [StackTrace? stackTrace]) {
    return ValidationResult(ValidationType.crash, <ValidationMessage>[
      const ValidationMessage.error('Due to an error, the doctor check did not complete.'),
      ValidationMessage.error('$error'),
      if (stackTrace != null) ValidationMessage('$stackTrace'),
    ], statusInfo: 'the doctor check crashed');
  }

  /// Deserializes a [ValidationResult] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory ValidationResult.fromJson(Map<String, Object?> json) {
    final ValidationType type = _parseValidationType(json.requiredField<String>(typeKey));
    final String? statusInfo = json.nullableField<String>(statusInfoKey);
    final Iterable<Object?> rawMessages = json.requiredField<Iterable<Object?>>(messagesKey);
    final messages = <ValidationMessage>[
      for (final Object? item in rawMessages)
        if (item case final Map<String, Object?> map)
          ValidationMessage.fromJson(map)
        else
          throw FormatException(
            'Invalid "$messagesKey" element: expected Map<String, Object?>, got ${item.runtimeType}.',
          ),
    ];

    return ValidationResult(type, messages, statusInfo: statusInfo);
  }

  static ValidationType _parseValidationType(String typeName) {
    for (final ValidationType value in ValidationType.values) {
      if (value.name == typeName) {
        return value;
      }
    }
    throw FormatException(
      'Invalid "$typeKey" in ValidationResult: "$typeName". '
      'Expected one of: ${ValidationType.values.map((ValidationType t) => t.name).join(', ')}.',
    );
  }

  static const _messageListEquality = ListEquality<ValidationMessage>();

  /// Map key for [messages].
  static const String messagesKey = 'messages';

  /// Map key for [statusInfo].
  static const String statusInfoKey = 'statusInfo';

  /// Map key for [type].
  static const String typeKey = 'type';

  /// Deserializes a list of [ValidationResult] objects from RPC response data.
  ///
  /// Throws a [FormatException] if [json] is not an iterable or contains
  /// invalid entries.
  static List<ValidationResult> listFromJson(Object? json) {
    if (json is! Iterable<Object?>) {
      throw FormatException(
        'Invalid ValidationResult list: expected Iterable<Object?>, got ${json.runtimeType}.',
      );
    }
    return <ValidationResult>[
      for (final Object? item in json)
        if (item is Map<String, Object?>)
          ValidationResult.fromJson(item)
        else
          throw FormatException(
            'Invalid ValidationResult entry: expected Map<String, Object?>, got ${item.runtimeType}.',
          ),
    ];
  }

  /// Status category of the diagnostic check.
  final ValidationType type;

  /// Additional status information text.
  final String? statusInfo;

  /// Diagnostic messages logged during validation.
  final List<ValidationMessage> messages;

  /// The time taken to perform the validation.
  ///
  /// Populated on the host by `DoctorValidator.validate` and omitted from
  /// [toMap] and [ValidationResult.fromJson].
  final Duration? executionTime;

  /// Serializes the validation result to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    typeKey: type.name,
    statusInfoKey: ?statusInfo,
    messagesKey: messages.map((ValidationMessage m) => m.toMap()).toList(),
  };

  @override
  String toString() =>
      'ValidationResult(type: $type, messages: $messages, '
      'statusInfo: $statusInfo, executionTime: $executionTime)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ValidationResult &&
            other.type == type &&
            other.statusInfo == statusInfo &&
            other.executionTime == executionTime &&
            _messageListEquality.equals(other.messages, messages));
  }

  @override
  int get hashCode =>
      Object.hash(type, statusInfo, executionTime, _messageListEquality.hash(messages));
}
