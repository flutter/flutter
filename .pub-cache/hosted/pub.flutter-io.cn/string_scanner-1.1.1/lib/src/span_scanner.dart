// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import 'eager_span_scanner.dart';
import 'exception.dart';
import 'line_scanner.dart';
import 'relative_span_scanner.dart';
import 'string_scanner.dart';
import 'utils.dart';

/// A subclass of [LineScanner] that exposes matched ranges as source map
/// [FileSpan]s.
class SpanScanner extends StringScanner implements LineScanner {
  /// The source of the scanner.
  ///
  /// This caches line break information and is used to generate [FileSpan]s.
  final SourceFile _sourceFile;

  @override
  int get line => _sourceFile.getLine(position);
  @override
  int get column => _sourceFile.getColumn(position);

  @override
  LineScannerState get state => _SpanScannerState(this, position);

  @override
  set state(LineScannerState state) {
    if (state is! _SpanScannerState || !identical(state._scanner, this)) {
      throw ArgumentError('The given LineScannerState was not returned by '
          'this LineScanner.');
    }

    position = state.position;
  }

  /// The [FileSpan] for [lastMatch].
  ///
  /// This is the span for the entire match. There's no way to get spans for
  /// subgroups since [Match] exposes no information about their positions.
  FileSpan? get lastSpan {
    if (lastMatch == null) _lastSpan = null;
    return _lastSpan;
  }

  FileSpan? _lastSpan;

  /// The current location of the scanner.
  FileLocation get location => _sourceFile.location(position);

  /// Returns an empty span at the current location.
  FileSpan get emptySpan => location.pointSpan();

  /// Creates a new [SpanScanner] that starts scanning from [position].
  ///
  /// [sourceUrl] is used as [SourceLocation.sourceUrl] for the returned
  /// [FileSpan]s as well as for error reporting. It can be a [String], a
  /// [Uri], or `null`.
  SpanScanner(String string, {sourceUrl, int? position})
      : _sourceFile = SourceFile.fromString(string, url: sourceUrl),
        super(string, sourceUrl: sourceUrl, position: position);

  /// Creates a new [SpanScanner] that eagerly computes line and column numbers.
  ///
  /// In general [new SpanScanner] will be more efficient, since it avoids extra
  /// computation on every scan. However, eager scanning can be useful for
  /// situations where the normal course of parsing frequently involves
  /// accessing the current line and column numbers.
  ///
  /// Note that *only* the `line` and `column` fields on the `SpanScanner`
  /// itself and its `LineScannerState` are eagerly computed. To limit their
  /// memory footprint, returned spans and locations will still lazily compute
  /// their line and column numbers.
  factory SpanScanner.eager(String string, {sourceUrl, int? position}) =
      EagerSpanScanner;

  /// Creates a new [SpanScanner] that scans within [span].
  ///
  /// This scans through [span]`.text, but emits new spans from [span]`.file` in
  /// their appropriate relative positions. The [string] field contains only
  /// [span]`.text`, and [position], [line], and [column] are all relative to
  /// the span.
  factory SpanScanner.within(FileSpan span) = RelativeSpanScanner;

  /// Creates a [FileSpan] representing the source range between [startState]
  /// and the current position.
  FileSpan spanFrom(LineScannerState startState, [LineScannerState? endState]) {
    final endPosition = endState == null ? position : endState.position;
    return _sourceFile.span(startState.position, endPosition);
  }

  @override
  bool matches(Pattern pattern) {
    if (!super.matches(pattern)) {
      _lastSpan = null;
      return false;
    }

    _lastSpan = _sourceFile.span(position, lastMatch!.end);
    return true;
  }

  @override
  Never error(String message, {Match? match, int? position, int? length}) {
    validateErrorArgs(string, match, position, length);

    if (match == null && position == null && length == null) match = lastMatch;
    position ??= match == null ? this.position : match.start;
    length ??= match == null ? 0 : match.end - match.start;

    final span = _sourceFile.span(position, position + length);
    throw StringScannerException(message, span, string);
  }
}

/// A class representing the state of a [SpanScanner].
class _SpanScannerState implements LineScannerState {
  /// The [SpanScanner] that created this.
  final SpanScanner _scanner;

  @override
  final int position;
  @override
  int get line => _scanner._sourceFile.getLine(position);
  @override
  int get column => _scanner._sourceFile.getColumn(position);

  _SpanScannerState(this._scanner, this.position);
}
