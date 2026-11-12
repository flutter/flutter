// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Severity level for structured log messages emitted by a tool extension.
enum ExtensionLogLevel {
  /// Standard informational status log message.
  info,

  /// Non-fatal warning log message.
  warning,

  /// Error log message.
  error,

  /// Verbose diagnostic trace log message.
  trace;

  /// Resolves an [ExtensionLogLevel] from its wire [name].
  ///
  /// Throws a [FormatException] if [name] is not a recognized log level.
  static ExtensionLogLevel fromName(String name) {
    final ExtensionLogLevel? level = values.asNameMap()[name];
    if (level == null) {
      throw FormatException('Unknown ExtensionLogLevel: "$name".');
    }
    return level;
  }
}

/// Structured log message emitted by an extension over the `'extension.log'`
/// JSON-RPC notification channel.
@immutable
final class ExtensionLogMessage {
  const ExtensionLogMessage({required this.message, required this.timestamp, this.level = .info});

  /// Deserializes an [ExtensionLogMessage] from a JSON notification payload.
  ///
  /// Throws a [FormatException] if any required field ([levelKey],
  /// [messageKey], or [timestampKey]) is missing or invalid.
  factory ExtensionLogMessage.fromJson(Map<String, Object?> json) {
    final ExtensionLogLevel level = ExtensionLogLevel.fromName(
      json.requiredField<String>(levelKey),
    );
    final String message = json.requiredField<String>(messageKey);
    final String rawTimestamp = json.requiredField<String>(timestampKey);
    final DateTime? parsedTimestamp = DateTime.tryParse(rawTimestamp);
    if (parsedTimestamp == null) {
      throw FormatException('Invalid "$timestampKey" ISO-8601 timestamp: "$rawTimestamp".');
    }
    return ExtensionLogMessage(level: level, message: message, timestamp: parsedTimestamp);
  }

  /// JSON key for the log severity level in `'extension.log'` notifications.
  static const String levelKey = 'level';

  /// JSON key for the log message in `'extension.log'` notifications.
  static const String messageKey = 'message';

  /// JSON key for the UTC ISO-8601 timestamp in `'extension.log'` notifications.
  static const String timestampKey = 'timestamp';

  /// Severity level of the log message.
  final ExtensionLogLevel level;

  /// Human-readable log message content.
  final String message;

  /// Timestamp when the log entry was emitted.
  final DateTime timestamp;

  /// Serializes this log message to a JSON-compatible map.
  Map<String, Object?> toMap() => <String, Object?>{
    levelKey: level.name,
    messageKey: message,
    timestampKey: timestamp.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionLogMessage &&
            other.level == level &&
            other.message == message &&
            other.timestamp == timestamp);
  }

  @override
  int get hashCode => Object.hash(level, message, timestamp);

  @override
  String toString() =>
      'ExtensionLogMessage(level: ${level.name}, message: $message, timestamp: $timestamp)';
}
