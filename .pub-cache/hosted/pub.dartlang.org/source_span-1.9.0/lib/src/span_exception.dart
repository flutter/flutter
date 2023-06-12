// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'span.dart';

/// A class for exceptions that have source span information attached.
class SourceSpanException implements Exception {
  // This is a getter so that subclasses can override it.
  /// A message describing the exception.
  String get message => _message;
  final String _message;

  // This is a getter so that subclasses can override it.
  /// The span associated with this exception.
  ///
  /// This may be `null` if the source location can't be determined.
  SourceSpan? get span => _span;
  final SourceSpan? _span;

  SourceSpanException(this._message, this._span);

  /// Returns a string representation of `this`.
  ///
  /// [color] may either be a [String], a [bool], or `null`. If it's a string,
  /// it indicates an ANSI terminal color escape that should be used to
  /// highlight the span's text. If it's `true`, it indicates that the text
  /// should be highlighted using the default color. If it's `false` or `null`,
  /// it indicates that the text shouldn't be highlighted.
  @override
  String toString({color}) {
    if (span == null) return message;
    return 'Error on ${span!.message(message, color: color)}';
  }
}

/// A [SourceSpanException] that's also a [FormatException].
class SourceSpanFormatException extends SourceSpanException
    implements FormatException {
  @override
  final dynamic source;

  @override
  int? get offset => span?.start.offset;

  SourceSpanFormatException(String message, SourceSpan? span, [this.source])
      : super(message, span);
}

/// A [SourceSpanException] that also highlights some secondary spans to provide
/// the user with extra context.
///
/// Each span has a label ([primaryLabel] for the primary, and the values of the
/// [secondarySpans] map for the secondary spans) that's used to indicate to the
/// user what that particular span represents.
class MultiSourceSpanException extends SourceSpanException {
  /// A label to attach to [span] that provides additional information and helps
  /// distinguish it from [secondarySpans].
  final String primaryLabel;

  /// A map whose keys are secondary spans that should be highlighted.
  ///
  /// Each span's value is a label to attach to that span that provides
  /// additional information and helps distinguish it from [secondarySpans].
  final Map<SourceSpan, String> secondarySpans;

  MultiSourceSpanException(String message, SourceSpan? span, this.primaryLabel,
      Map<SourceSpan, String> secondarySpans)
      : secondarySpans = Map.unmodifiable(secondarySpans),
        super(message, span);

  /// Returns a string representation of `this`.
  ///
  /// [color] may either be a [String], a [bool], or `null`. If it's a string,
  /// it indicates an ANSI terminal color escape that should be used to
  /// highlight the primary span's text. If it's `true`, it indicates that the
  /// text should be highlighted using the default color. If it's `false` or
  /// `null`, it indicates that the text shouldn't be highlighted.
  ///
  /// If [color] is `true` or a string, [secondaryColor] is used to highlight
  /// [secondarySpans].
  @override
  String toString({color, String? secondaryColor}) {
    if (span == null) return message;

    var useColor = false;
    String? primaryColor;
    if (color is String) {
      useColor = true;
      primaryColor = color;
    } else if (color == true) {
      useColor = true;
    }

    final formatted = span!.messageMultiple(
        message, primaryLabel, secondarySpans,
        color: useColor,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor);
    return 'Error on $formatted';
  }
}

/// A [MultiSourceSpanException] that's also a [FormatException].
class MultiSourceSpanFormatException extends MultiSourceSpanException
    implements FormatException {
  @override
  final dynamic source;

  @override
  int? get offset => span?.start.offset;

  MultiSourceSpanFormatException(String message, SourceSpan? span,
      String primaryLabel, Map<SourceSpan, String> secondarySpans,
      [this.source])
      : super(message, span, primaryLabel, secondarySpans);
}
