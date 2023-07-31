// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.diagnostic_message;

import 'codes.dart' show Code, DiagnosticMessageFromJson, FormattedMessage;

import 'severity.dart' show Severity;

/// The type of a diagnostic message callback. For example:
///
///    void handler(DiagnosticMessage message) {
///      if (enableTerminalColors) { // See [terminal_color_support.dart].
///        message.ansiFormatted.forEach(stderr.writeln);
///      } else {
///        message.plainTextFormatted.forEach(stderr.writeln);
///      }
///    }
typedef DiagnosticMessageHandler = void Function(DiagnosticMessage);

/// Represents a diagnostic message that can be reported from a tool, for
/// example, a compiler.
///
/// The word *diagnostic* is used loosely here, as a tool may also use this for
/// reporting any kind of message, including non-diagnostic messages such as
/// licensing, informal, or logging information. This allows a well-behaved
/// tool to never directly write to stdout or stderr.
abstract class DiagnosticMessage {
  DiagnosticMessage._(); // Prevent subclassing.

  Iterable<String> get ansiFormatted;

  Iterable<String> get plainTextFormatted;

  Severity get severity;

  Iterable<Uri>? get involvedFiles;

  String? get codeName;
}

/// This method is subject to change.
Uri? getMessageUri(DiagnosticMessage message) {
  return message is FormattedMessage
      ? message.uri
      : message is DiagnosticMessageFromJson
          ? message.uri
          : null;
}

/// This method is subject to change.
int? getMessageCharOffset(DiagnosticMessage message) {
  return message is FormattedMessage ? message.charOffset : null;
}

/// This method is subject to change.
int? getMessageLength(DiagnosticMessage message) {
  return message is FormattedMessage ? message.length : null;
}

/// This method is subject to change.
Code? getMessageCodeObject(DiagnosticMessage message) {
  return message is FormattedMessage ? message.code : null;
}

/// This method is subject to change.
String? getMessageHeaderText(DiagnosticMessage message) {
  return message is FormattedMessage ? message.problemMessage : null;
}

/// This method is subject to change.
int getMessageCode(DiagnosticMessage message) {
  return message is FormattedMessage ? message.code.index : -1;
}

/// This method is subject to change.
Map<String, dynamic>? getMessageArguments(DiagnosticMessage message) {
  return message is FormattedMessage ? message.arguments : null;
}

/// This method is subject to change.
Iterable<DiagnosticMessage>? getMessageRelatedInformation(
    DiagnosticMessage message) {
  return message is FormattedMessage ? message.relatedInformation : null;
}
