// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import 'charcode.dart';
import 'exception.dart';
import 'utils.dart';

/// A class that scans through a string using [Pattern]s.
class StringScanner {
  /// The URL of the source of the string being scanned.
  ///
  /// This is used for error reporting. It may be `null`, indicating that the
  /// source URL is unknown or unavailable.
  final Uri? sourceUrl;

  /// The string being scanned through.
  final String string;

  /// The current position of the scanner in the string, in characters.
  int get position => _position;
  set position(int position) {
    if (position.isNegative || position > string.length) {
      throw ArgumentError('Invalid position $position');
    }

    _position = position;
    _lastMatch = null;
  }

  int _position = 0;

  /// The data about the previous match made by the scanner.
  ///
  /// If the last match failed, this will be `null`.
  Match? get lastMatch {
    // Lazily unset [_lastMatch] so that we avoid extra assignments in
    // character-by-character methods that are used in core loops.
    if (_position != _lastMatchPosition) _lastMatch = null;
    return _lastMatch;
  }

  Match? _lastMatch;
  int? _lastMatchPosition;

  /// The portion of the string that hasn't yet been scanned.
  String get rest => string.substring(position);

  /// Whether the scanner has completely consumed [string].
  bool get isDone => position == string.length;

  /// Creates a new [StringScanner] that starts scanning from [position].
  ///
  /// [position] defaults to 0, the beginning of the string. [sourceUrl] is the
  /// URL of the source of the string being scanned, if available. It can be
  /// a [String], a [Uri], or `null`.
  StringScanner(this.string, {Object? sourceUrl, int? position})
      : sourceUrl = sourceUrl == null
            ? null
            : sourceUrl is String
                ? Uri.parse(sourceUrl)
                : sourceUrl as Uri {
    if (position != null) this.position = position;
  }

  /// Consumes a single character and returns its character code.
  ///
  /// This throws a [FormatException] if the string has been fully consumed. It
  /// doesn't affect [lastMatch].
  int readChar() {
    if (isDone) _fail('more input');
    return string.codeUnitAt(_position++);
  }

  /// Returns the character code of the character [offset] away from [position].
  ///
  /// [offset] defaults to zero, and may be negative to inspect already-consumed
  /// characters.
  ///
  /// This returns `null` if [offset] points outside the string. It doesn't
  /// affect [lastMatch].
  int? peekChar([int? offset]) {
    offset ??= 0;
    final index = position + offset;
    if (index < 0 || index >= string.length) return null;
    return string.codeUnitAt(index);
  }

  /// If the next character in the string is [character], consumes it.
  ///
  /// If [character] is a Unicode code point in a supplementary plane, this will
  /// consume two code units. Dart's string representation is UTF-16, which
  /// represents supplementary-plane code units as two code units.
  ///
  /// Returns whether or not [character] was consumed.
  bool scanChar(int character) {
    if (inSupplementaryPlane(character)) {
      if (_position + 1 >= string.length ||
          string.codeUnitAt(_position) != highSurrogate(character) ||
          string.codeUnitAt(_position + 1) != lowSurrogate(character)) {
        return false;
      } else {
        _position += 2;
        return true;
      }
    } else {
      if (isDone) return false;
      if (string.codeUnitAt(_position) != character) return false;
      _position++;
      return true;
    }
  }

  /// If the next character in the string is [character], consumes it.
  ///
  /// If [character] is a Unicode code point in a supplementary plane, this will
  /// consume two code units. Dart's string representation is UTF-16, which
  /// represents supplementary-plane code units as two code units.
  ///
  /// If [character] could not be consumed, throws a [FormatException]
  /// describing the position of the failure. [name] is used in this error as
  /// the expected name of the character being matched; if it's `null`, the
  /// character itself is used instead.
  void expectChar(int character, {String? name}) {
    if (scanChar(character)) return;

    if (name == null) {
      if (character == $backslash) {
        name = r'"\"';
      } else if (character == $doubleQuote) {
        name = r'"\""';
      } else {
        name = '"${String.fromCharCode(character)}"';
      }
    }

    _fail(name);
  }

  /// Consumes a single Unicode code unit and returns it.
  ///
  /// This works like [readChar], except that it automatically handles UTF-16
  /// surrogate pairs. Specifically, if the next two code units form a surrogate
  /// pair, consumes them both and returns the corresponding Unicode code point.
  ///
  /// If next two characters are not a surrogate pair, the next code unit is
  /// returned as-is, even if it's an unpaired surrogate.
  int readCodePoint() {
    final first = readChar();
    if (!isHighSurrogate(first)) return first;

    final next = peekChar();
    if (next == null || !isLowSurrogate(next)) return first;

    readChar();
    return decodeSurrogatePair(first, next);
  }

  /// Returns the Unicode code point immediately after [position].
  ///
  /// This works like [peekChar], except that it automatically handles UTF-16
  /// surrogate pairs. Specifically, if the next two code units form a surrogate
  /// pair, returns the corresponding Unicode code point.
  ///
  /// If next two characters are not a surrogate pair, the next code unit is
  /// returned as-is, even if it's an unpaired surrogate.
  int? peekCodePoint() {
    final first = peekChar();
    if (first == null || !isHighSurrogate(first)) return first;

    final next = peekChar(1);
    if (next == null || !isLowSurrogate(next)) return first;

    return decodeSurrogatePair(first, next);
  }

  /// If [pattern] matches at the current position of the string, scans forward
  /// until the end of the match.
  ///
  /// Returns whether or not [pattern] matched.
  bool scan(Pattern pattern) {
    final success = matches(pattern);
    if (success) {
      _position = _lastMatch!.end;
      _lastMatchPosition = _position;
    }
    return success;
  }

  /// If [pattern] matches at the current position of the string, scans forward
  /// until the end of the match.
  ///
  /// If [pattern] did not match, throws a [FormatException] describing the
  /// position of the failure. [name] is used in this error as the expected name
  /// of the pattern being matched; if it's `null`, the pattern itself is used
  /// instead.
  void expect(Pattern pattern, {String? name}) {
    if (scan(pattern)) return;

    if (name == null) {
      if (pattern is RegExp) {
        final source = pattern.pattern;
        name = '/$source/';
      } else {
        name =
            pattern.toString().replaceAll(r'\', r'\\').replaceAll('"', r'\"');
        name = '"$name"';
      }
    }
    _fail(name);
  }

  /// If the string has not been fully consumed, this throws a
  /// [FormatException].
  void expectDone() {
    if (isDone) return;
    _fail('no more input');
  }

  /// Returns whether or not [pattern] matches at the current position of the
  /// string.
  ///
  /// This doesn't move the scan pointer forward.
  bool matches(Pattern pattern) {
    _lastMatch = pattern.matchAsPrefix(string, position);
    _lastMatchPosition = _position;
    return _lastMatch != null;
  }

  /// Returns the substring of [string] between [start] and [end].
  ///
  /// Unlike [String.substring], [end] defaults to [position] rather than the
  /// end of the string.
  String substring(int start, [int? end]) {
    end ??= position;
    return string.substring(start, end);
  }

  /// Throws a [FormatException] with [message] as well as a detailed
  /// description of the location of the error in the string.
  ///
  /// [match] is the match information for the span of the string with which the
  /// error is associated. This should be a match returned by this scanner's
  /// [lastMatch] property. By default, the error is associated with the last
  /// match.
  ///
  /// If [position] and/or [length] are passed, they are used as the error span
  /// instead. If only [length] is passed, [position] defaults to the current
  /// position; if only [position] is passed, [length] defaults to 0.
  ///
  /// It's an error to pass [match] at the same time as [position] or [length].
  Never error(String message, {Match? match, int? position, int? length}) {
    validateErrorArgs(string, match, position, length);

    if (match == null && position == null && length == null) match = lastMatch;
    position ??= match == null ? this.position : match.start;
    length ??= match == null ? 0 : match.end - match.start;

    final sourceFile = SourceFile.fromString(string, url: sourceUrl);
    final span = sourceFile.span(position, position + length);
    throw StringScannerException(message, span, string);
  }

  // TODO(nweiz): Make this handle long lines more gracefully.
  /// Throws a [FormatException] describing that [name] is expected at the
  /// current position in the string.
  Never _fail(String name) {
    error('expected $name.', position: position, length: 0);
  }
}
