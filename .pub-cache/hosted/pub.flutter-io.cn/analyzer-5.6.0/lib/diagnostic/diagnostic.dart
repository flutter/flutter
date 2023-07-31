// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A diagnostic, as defined by the [Diagnostic Design Guidelines][guidelines]:
///
/// > An indication of a specific problem at a specific location within the
/// > source code being processed by a development tool.
///
/// Clients may not extend, implement or mix-in this class.
///
/// [guidelines]: ../doc/diagnostics.md
abstract class Diagnostic {
  /// A list of messages that provide context for understanding the problem
  /// being reported. The list will be empty if there are no such messages.
  List<DiagnosticMessage> get contextMessages;

  /// A description of how to fix the problem, or `null` if there is no such
  /// description.
  String? get correctionMessage;

  /// A message describing what is wrong and why.
  DiagnosticMessage get problemMessage;

  /// The severity associated with the diagnostic.
  Severity get severity;
}

/// A single message associated with a [Diagnostic], consisting of the text of
/// the message and the location associated with it.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DiagnosticMessage {
  /// The absolute and normalized path of the file associated with this message.
  String get filePath;

  /// The length of the source range associated with this message.
  int get length;

  /// The zero-based offset from the start of the file to the beginning of the
  /// source range associated with this message.
  int get offset;

  /// The URL associated with this diagnostic message, if any.
  String? get url;

  /// Gets the text of the message.
  ///
  /// If [includeUrl] is `true`, and this diagnostic message has an associated
  /// URL, it is included in the returned value in a human-readable way.
  /// Clients that wish to present URLs as simple text can do this.  If
  /// [includeUrl] is `false`, no URL is included in the returned value.
  /// Clients that have a special mechanism for presenting URLs (e.g. as a
  /// clickable link) should do this and then consult the [url] getter to access
  /// the URL.
  String messageText({required bool includeUrl});
}

/// An indication of the severity of a [Diagnostic].
enum Severity { error, warning, info }
