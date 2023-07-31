// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:collection/collection.dart';

/// A class for parsing and representing test code that contains special markup
/// to simplify marking up positions and ranges in test code.
///
/// Positions and ranges are marked with brackets inside block comments:
///
/// ```
/// position ::= '/*' integer '*/
/// rangeStart ::= '/*[' integer '*/
/// rangeEnd ::= '/*' integer ']*/
/// ```
///
/// Numbers start at 0 and positions and range starts must be consecutive.
/// The same numbers can be used to represent both positions and ranges.
///
/// For convenience, a single position can also be marked with a `^` (which
/// behaves the same as `/*0*/).
class TestCode {
  static final _positionShorthand = '^';
  static final _rangeStartShorthand = '[!';
  static final _rangeEndShorthand = '!]';
  static final _positionPattern = RegExp(r'\/\*(\d+)\*\/');
  static final _rangeStartPattern = RegExp(r'\/\*\[(\d+)\*\/');
  static final _rangeEndPattern = RegExp(r'\/\*(\d+)\]\*\/');
  final String code;
  final String rawCode;

  /// A map of positions marked in code, indexed by their number.
  final List<TestCodePosition> positions;

  /// A map of ranges marked in code, indexed by their number.
  final List<TestCodeRange> ranges;

  TestCode._({
    required this.rawCode,
    required this.code,
    required this.positions,
    required this.ranges,
  });

  TestCodePosition get position => positions.single;
  TestCodeRange get range => ranges.single;

  static TestCode parse(
    String rawCode, {
    bool positionShorthand = true,
    bool rangeShorthand = true,
  }) {
    final scanner = _StringScanner(rawCode);
    final codeBuffer = StringBuffer();
    final positionOffsets = <int, int>{};
    final rangeStartOffsets = <int, int>{};
    final rangeEndOffsets = <int, int>{};
    late int start;

    int scannedNumber() => int.parse(scanner.lastMatch!.group(1)!);

    void recordPosition(int number) {
      if (positionOffsets.containsKey(number)) {
        throw ArgumentError(
            'Code contains multiple positions numbered $number');
      } else if (number > positionOffsets.length) {
        throw ArgumentError(
            'Code contains position numbered $number but expected ${positionOffsets.length}');
      }
      positionOffsets[number] = start;
    }

    void recordRangeStart(int number) {
      if (rangeStartOffsets.containsKey(number)) {
        throw ArgumentError(
            'Code contains multiple range starts numbered $number');
      } else if (number > rangeStartOffsets.length) {
        throw ArgumentError(
            'Code contains range start numbered $number but expected ${rangeStartOffsets.length}');
      }
      rangeStartOffsets[number] = start;
    }

    void recordRangeEnd(int number) {
      if (rangeEndOffsets.containsKey(number)) {
        throw ArgumentError(
            'Code contains multiple range ends numbered $number');
      }
      if (!rangeStartOffsets.containsKey(number)) {
        throw ArgumentError(
            'Code contains range end numbered $number without a preceeding start');
      }
      rangeEndOffsets[number] = start;
    }

    while (!scanner.isDone) {
      start = codeBuffer.length;
      if (positionShorthand && scanner.scan(_positionShorthand)) {
        recordPosition(0);
      } else if (scanner.scan(_positionPattern)) {
        recordPosition(scannedNumber());
      } else if (rangeShorthand && scanner.scan(_rangeStartShorthand)) {
        recordRangeStart(0);
      } else if (rangeShorthand && scanner.scan(_rangeEndShorthand)) {
        recordRangeEnd(0);
      } else if (scanner.scan(_rangeStartPattern)) {
        recordRangeStart(scannedNumber());
      } else if (scanner.scan(_rangeEndPattern)) {
        recordRangeEnd(scannedNumber());
      } else {
        codeBuffer.writeCharCode(scanner.readChar());
      }
    }

    final unendedRanges =
        rangeStartOffsets.keys.whereNot(rangeEndOffsets.keys.contains).toList();
    if (unendedRanges.isNotEmpty) {
      throw ArgumentError(
          'Code contains range starts numbered $unendedRanges without ends');
    }

    final code = codeBuffer.toString();
    final lineInfo = LineInfo.fromContent(code);

    final positions = positionOffsets.map(
      (number, offset) => MapEntry(
        number,
        TestCodePosition(lineInfo, offset),
      ),
    );

    final ranges = rangeStartOffsets.map(
      (number, offset) => MapEntry(
        number,
        TestCodeRange(
          lineInfo,
          code.substring(offset, rangeEndOffsets[number]!),
          SourceRange(offset, rangeEndOffsets[number]! - offset),
        ),
      ),
    );

    return TestCode._(
      code: code,
      rawCode: rawCode,
      positions: positions.values.toList(),
      ranges: ranges.values.toList(),
    );
  }
}

/// A marked position in the test code.
class TestCodePosition {
  /// Line break information for the test code.
  final LineInfo lineInfo;

  /// The 0-based offset of the marker.
  ///
  /// Offsets are based on [TestCode.code], with all parsed markers removed.
  final int offset;

  TestCodePosition(this.lineInfo, this.offset);
}

class TestCodeRange {
  /// Line break information for the test code.
  final LineInfo lineInfo;

  /// The text from [TestCode.code] covered by this range.
  final String text;

  /// The [SourceRange] indicated by the markers.
  ///
  /// Offsets/lengths are based on [TestCode.code], with all parsed markers
  /// removed.
  final SourceRange sourceRange;

  TestCodeRange(this.lineInfo, this.text, this.sourceRange);
}

/// A simple scanner to read characters and [Pattern]s from a source string.
class _StringScanner {
  final String _source;
  int _position = 0;
  int? _lastMatchPosition;
  Match? _lastMatch;

  _StringScanner(this._source);

  /// Returns whether the end of the string has been reached.
  bool get isDone => _position == _source.length;

  /// Returns the last match from scaling [scan] if the position has not
  /// advanced since.
  Match? get lastMatch {
    return _position == _lastMatchPosition ? _lastMatch : null;
  }

  /// Scans forwards a single character, returning its character code.
  int readChar() {
    if (isDone) {
      throw StateError('Unable to scan past the end of string');
    }
    return _source.codeUnitAt(_position++);
  }

  /// Scans forwards to the end of the match if the string from the current
  /// position starts with [pattern].
  ///
  /// Returns whether any match occurred.
  bool scan(Pattern pattern) {
    if (isDone) {
      throw StateError('Unable to scan past the end of string');
    }

    final match = pattern.matchAsPrefix(_source, _position);
    if (match != null) {
      _position = match.end;
      _lastMatch = match;
      _lastMatchPosition = _position;
      return true;
    }
    return false;
  }
}
