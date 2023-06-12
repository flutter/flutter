// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'charcode.dart';
import 'string_scanner.dart';

// Note that much of this code is duplicated in eager_span_scanner.dart.

/// A regular expression matching newlines across platforms.
final _newlineRegExp = RegExp(r'\r\n?|\n');

/// A subclass of [StringScanner] that tracks line and column information.
class LineScanner extends StringScanner {
  /// The scanner's current (zero-based) line number.
  int get line => _line;
  int _line = 0;

  /// The scanner's current (zero-based) column number.
  int get column => _column;
  int _column = 0;

  /// The scanner's state, including line and column information.
  ///
  /// This can be used to efficiently save and restore the state of the scanner
  /// when backtracking. A given [LineScannerState] is only valid for the
  /// [LineScanner] that created it.
  ///
  /// This does not include the scanner's match information.
  LineScannerState get state =>
      LineScannerState._(this, position, line, column);

  /// Whether the current position is between a CR character and an LF
  /// charactet.
  bool get _betweenCRLF => peekChar(-1) == $cr && peekChar() == $lf;

  set state(LineScannerState state) {
    if (!identical(state._scanner, this)) {
      throw ArgumentError('The given LineScannerState was not returned by '
          'this LineScanner.');
    }

    super.position = state.position;
    _line = state.line;
    _column = state.column;
  }

  @override
  set position(int newPosition) {
    final oldPosition = position;
    super.position = newPosition;

    if (newPosition > oldPosition) {
      final newlines = _newlinesIn(string.substring(oldPosition, newPosition));
      _line += newlines.length;
      if (newlines.isEmpty) {
        _column += newPosition - oldPosition;
      } else {
        _column = newPosition - newlines.last.end;
      }
    } else {
      final newlines = _newlinesIn(string.substring(newPosition, oldPosition));
      if (_betweenCRLF) newlines.removeLast();

      _line -= newlines.length;
      if (newlines.isEmpty) {
        _column -= oldPosition - newPosition;
      } else {
        _column =
            newPosition - string.lastIndexOf(_newlineRegExp, newPosition) - 1;
      }
    }
  }

  LineScanner(String string, {sourceUrl, int? position})
      : super(string, sourceUrl: sourceUrl, position: position);

  @override
  bool scanChar(int character) {
    if (!super.scanChar(character)) return false;
    _adjustLineAndColumn(character);
    return true;
  }

  @override
  int readChar() {
    final character = super.readChar();
    _adjustLineAndColumn(character);
    return character;
  }

  /// Adjusts [_line] and [_column] after having consumed [character].
  void _adjustLineAndColumn(int character) {
    if (character == $lf || (character == $cr && peekChar() != $lf)) {
      _line += 1;
      _column = 0;
    } else {
      _column += 1;
    }
  }

  @override
  bool scan(Pattern pattern) {
    if (!super.scan(pattern)) return false;

    final newlines = _newlinesIn(lastMatch![0]!);
    _line += newlines.length;
    if (newlines.isEmpty) {
      _column += (lastMatch![0])!.length;
    } else {
      _column = (lastMatch![0])!.length - newlines.last.end;
    }

    return true;
  }

  /// Returns a list of [Match]es describing all the newlines in [text], which
  /// is assumed to end at [position].
  List<Match> _newlinesIn(String text) {
    final newlines = _newlineRegExp.allMatches(text).toList();
    if (_betweenCRLF) newlines.removeLast();
    return newlines;
  }
}

/// A class representing the state of a [LineScanner].
class LineScannerState {
  /// The [LineScanner] that created this.
  final LineScanner _scanner;

  /// The position of the scanner in this state.
  final int position;

  /// The zero-based line number of the scanner in this state.
  final int line;

  /// The zero-based column number of the scanner in this state.
  final int column;

  LineScannerState._(this._scanner, this.position, this.line, this.column);
}
