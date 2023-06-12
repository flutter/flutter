// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';

// ASCII character codes.

const _zero = 0x30;
const _nine = 0x39;
const _backslash = 0x5C;
const _openCurly = 0x7B;
const _closeCurly = 0x7D;
const _capitalA = 0x41;
const _capitalZ = 0x5A;
const _a = 0x61;
const _n = 0x6E;
const _r = 0x72;
const _f = 0x66;
const _b = 0x62;
const _t = 0x74;
const _u = 0x75;
const _v = 0x76;
const _x = 0x78;
const _z = 0x7A;
const _newline = 0xA;
const _carriageReturn = 0xD;
const _formFeed = 0xC;
const _backspace = 0x8;
const _tab = 0x9;
const _verticalTab = 0xB;

/// An iterator over the runes in the value of a [StringLiteral].
///
/// In addition to exposing the values of the runes themselves, this also
/// exposes the offset of the current rune in the Dart source file.
class StringLiteralIterator extends Iterator<int> {
  @override
  int get current => _current!;
  int? _current;

  /// The offset of the beginning of [current] in the Dart source file that
  /// contains the string literal.
  ///
  /// Before iteration begins, this points to the character before the first
  /// rune.
  int get offset => _offset;
  late int _offset;

  /// The offset of the next rune.
  ///
  /// This isn't necessarily just `offset + 1`, since a single rune may be
  /// represented by multiple characters in the source file, or a string literal
  /// may be composed of several adjacent string literals.
  int? _nextOffset;

  /// All [SimpleStringLiteral]s that compose the input literal.
  ///
  /// If the input literal is itself a [SimpleStringLiteral], this just contains
  /// that literal; otherwise, the literal is an [AdjacentStrings], and this
  /// contains its component literals.
  final _strings = Queue<SimpleStringLiteral>();

  /// Whether this is a raw string that begins with `r`.
  ///
  /// This is necessary for knowing how to parse escape sequences.
  bool? _isRaw;

  /// The iterator over the runes in the Dart source file.
  ///
  /// When switching to a new string in [_strings], this is updated to point to
  /// that string's component runes.
  Iterator<int>? _runes;

  /// The result of the last call to `_runes.moveNext`.
  bool _runesHasCurrent = false;

  /// Creates a new [StringLiteralIterator] iterating over the contents of
  /// [literal].
  ///
  /// Throws an [ArgumentError] if [literal] contains interpolated strings.
  StringLiteralIterator(StringLiteral literal) {
    if (literal is StringInterpolation) {
      throw ArgumentError("Can't iterate over an interpolated string.");
    } else if (literal is SimpleStringLiteral) {
      _strings.add(literal);
    } else {
      assert(literal is AdjacentStrings);

      for (var string in (literal as AdjacentStrings).strings) {
        if (string is StringInterpolation) {
          throw ArgumentError("Can't iterate over an interpolated string.");
        }
        _strings.add(string as SimpleStringLiteral);
      }
    }

    _offset = _strings.first.contentsOffset - 1;
  }

  @override
  bool moveNext() {
    // If we're at beginning of a [SimpleStringLiteral], move forward until
    // there's actually text to consume.
    while (_runes == null || !_runesHasCurrent) {
      if (_strings.isEmpty) {
        // Move the offset past the end of the text.
        _offset = _nextOffset!;
        _current = null;
        return false;
      }

      var string = _strings.removeFirst();
      var start = string.contentsOffset - string.offset;

      // Compensate for the opening and closing quotes.
      var end = start +
          string.literal.lexeme.length -
          2 * (string.isMultiline ? 3 : 1) -
          (string.isRaw ? 1 : 0);
      var text = string.literal.lexeme.substring(start, end);

      _nextOffset = string.contentsOffset;
      _isRaw = string.isRaw;
      _runes = text.runes.iterator;
      _runesHasCurrent = _runes!.moveNext();
    }

    _offset = _nextOffset!;
    _current = _nextRune();
    if (_current != null) return true;

    // If we encounter a parse failure, stop moving forward immediately.
    _strings.clear();
    return false;
  }

  /// Consume and return the next rune.
  int? _nextRune() {
    if (_isRaw! || _runes!.current != _backslash) {
      var rune = _runes!.current;
      _moveRunesNext();
      return (rune < 0) ? null : rune;
    }

    if (!_moveRunesNext()) return null;
    return _parseEscapeSequence();
  }

  /// Parse an escape sequence in the underlying Dart text.
  ///
  /// This assumes that a backslash has already been consumed. It leaves the
  /// [_runes] cursor on the first character after the escape sequence.
  int? _parseEscapeSequence() {
    switch (_runes!.current) {
      case _n:
        _moveRunesNext();
        return _newline;
      case _r:
        _moveRunesNext();
        return _carriageReturn;
      case _f:
        _moveRunesNext();
        return _formFeed;
      case _b:
        _moveRunesNext();
        return _backspace;
      case _t:
        _moveRunesNext();
        return _tab;
      case _v:
        _moveRunesNext();
        return _verticalTab;
      case _x:
        if (!_moveRunesNext()) return null;
        return _parseHex(2);
      case _u:
        if (!_moveRunesNext()) return null;
        if (_runes!.current != _openCurly) return _parseHex(4);
        if (!_moveRunesNext()) return null;

        var number = _parseHexSequence();
        if (_runes!.current != _closeCurly) return null;
        if (!_moveRunesNext()) return null;
        return number;
      default:
        var rune = _runes!.current;
        _moveRunesNext();
        return rune;
    }
  }

  /// Parse a variable-length sequence of hexadecimal digits and returns their
  /// value as an [int].
  ///
  /// This parses digits as they appear in a unicode escape sequence: one to six
  /// hex digits.
  int? _parseHexSequence() {
    var number = _parseHexDigit(_runes!.current);
    if (number == null) return null;
    if (!_moveRunesNext()) return null;

    for (var i = 0; i < 5; i++) {
      var digit = _parseHexDigit(_runes!.current);
      if (digit == null) break;
      number = number! * 16 + digit;
      if (!_moveRunesNext()) return null;
    }

    return number;
  }

  /// Parses [digits] hexadecimal digits and returns their value as an [int].
  int? _parseHex(int digits) {
    var number = 0;
    for (var i = 0; i < digits; i++) {
      if (_runes!.current == -1) return null;
      var digit = _parseHexDigit(_runes!.current);
      if (digit == null) return null;
      number = number * 16 + digit;
      _moveRunesNext();
    }
    return number;
  }

  /// Parses a single hexadecimal digit.
  int? _parseHexDigit(int rune) {
    if (rune < _zero) return null;
    if (rune <= _nine) return rune - _zero;
    if (rune < _capitalA) return null;
    if (rune <= _capitalZ) return 10 + rune - _capitalA;
    if (rune < _a) return null;
    if (rune <= _z) return 10 + rune - _a;
    return null;
  }

  /// Move [_runes] to the next rune and update [_nextOffset].
  bool _moveRunesNext() {
    var result = _runesHasCurrent = _runes!.moveNext();
    _nextOffset = _nextOffset! + 1;
    return result;
  }
}
