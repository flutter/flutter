// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:characters/src/grapheme_clusters/table.dart';

import "characters.dart";
import "grapheme_clusters/constants.dart";
import "grapheme_clusters/breaks.dart";

/// The grapheme clusters of a string.
///
/// Backed by a single string.
class StringCharacters extends Iterable<String> implements Characters {
  @override
  final String string;

  const StringCharacters(this.string);

  @override
  CharacterRange get iterator => StringCharacterRange._(string, 0, 0);

  @override
  CharacterRange get iteratorAtEnd =>
      StringCharacterRange._(string, string.length, string.length);

  StringCharacterRange get _rangeAll =>
      StringCharacterRange._(string, 0, string.length);

  @override
  String get first => string.isEmpty
      ? throw StateError("No element")
      : string.substring(
          0, Breaks(string, 0, string.length, stateSoTNoBreak).nextBreak());

  @override
  String get last => string.isEmpty
      ? throw StateError("No element")
      : string.substring(
          BackBreaks(string, string.length, 0, stateEoTNoBreak).nextBreak());

  @override
  String get single {
    if (string.isEmpty) throw StateError("No element");
    var firstEnd =
        Breaks(string, 0, string.length, stateSoTNoBreak).nextBreak();
    if (firstEnd == string.length) return string;
    throw StateError("Too many elements");
  }

  @override
  bool get isEmpty => string.isEmpty;

  @override
  bool get isNotEmpty => string.isNotEmpty;

  @override
  int get length {
    if (string.isEmpty) return 0;
    var brk = Breaks(string, 0, string.length, stateSoTNoBreak);
    var length = 0;
    while (brk.nextBreak() >= 0) {
      length++;
    }
    return length;
  }

  @override
  Iterable<T> whereType<T>() {
    Iterable<Object?> self = this;
    if (self is Iterable<T>) {
      return self.map<T>((x) => x);
    }
    return Iterable<T>.empty();
  }

  @override
  String join([String separator = ""]) {
    if (separator == "") return string;
    return _explodeReplace(string, 0, string.length, separator, "");
  }

  @override
  String lastWhere(bool Function(String element) test,
      {String Function()? orElse}) {
    var cursor = string.length;
    var brk = BackBreaks(string, cursor, 0, stateEoTNoBreak);
    var next = 0;
    while ((next = brk.nextBreak()) >= 0) {
      var current = string.substring(next, cursor);
      if (test(current)) return current;
      cursor = next;
    }
    if (orElse != null) return orElse();
    throw StateError("No element");
  }

  @override
  String elementAt(int index) {
    RangeError.checkNotNegative(index, "index");
    var count = 0;
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      var start = 0;
      var end = 0;
      while ((end = breaks.nextBreak()) >= 0) {
        if (count == index) return string.substring(start, end);
        count++;
        start = end;
      }
    }
    throw RangeError.index(index, this, "index", null, count);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  bool contains(Object? singleCharacterString) {
    if (singleCharacterString is! String) return false;
    if (singleCharacterString.isEmpty) return false;
    var next = Breaks(singleCharacterString, 0, singleCharacterString.length,
            stateSoTNoBreak)
        .nextBreak();
    if (next != singleCharacterString.length) return false;
    // [singleCharacterString] is single grapheme cluster.
    return _indexOf(string, singleCharacterString, 0, string.length) >= 0;
  }

  @override
  bool startsWith(Characters characters) {
    var length = string.length;
    var otherString = characters.string;
    if (otherString.isEmpty) return true;
    return string.startsWith(otherString) &&
        isGraphemeClusterBoundary(string, 0, length, otherString.length);
  }

  @override
  bool endsWith(Characters characters) {
    var length = string.length;
    var otherString = characters.string;
    if (otherString.isEmpty) return true;
    var otherLength = otherString.length;
    var start = string.length - otherLength;
    return start >= 0 &&
        string.startsWith(otherString, start) &&
        isGraphemeClusterBoundary(string, 0, length, start);
  }

  @override
  Characters replaceAll(Characters pattern, Characters replacement) =>
      _rangeAll.replaceAll(pattern, replacement)?.source ?? this;

  @override
  Characters replaceFirst(Characters pattern, Characters replacement) =>
      _rangeAll.replaceFirst(pattern, replacement)?.source ?? this;

  @override
  Iterable<Characters> split(Characters pattern, [int maxParts = 0]) sync* {
    if (maxParts == 1 || string.isEmpty) {
      yield this;
      return;
    }
    var patternString = pattern.string;
    var start = 0;
    if (patternString.isNotEmpty) {
      do {
        var match = _indexOf(string, patternString, start, string.length);
        if (match < 0) break;
        yield StringCharacters(string.substring(start, match));
        start = match + patternString.length;
        maxParts--;
      } while (maxParts != 1);
    } else {
      // Empty pattern. Split on internal boundaries only.
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      do {
        var match = breaks.nextBreak();
        if (match < 0) return;
        yield StringCharacters(string.substring(start, match));
        start = match;
        maxParts--;
      } while (maxParts != 1);
      if (start == string.length) return;
    }
    yield StringCharacters(string.substring(start));
  }

  @override
  bool containsAll(Characters characters) =>
      _indexOf(string, characters.string, 0, string.length) >= 0;

  /// Returns the break position of the [count]'th break.
  ///
  /// Starts from the index [cursor] in [string].
  /// Use [breaks], which is assumed to be at [cursor],
  /// if available.
  ///
  /// Returns `string.length` if there are less than [count]
  /// characters left.
  int _skipIndices(int count, int cursor, Breaks? breaks) {
    if (count == 0 || cursor == string.length) return cursor;
    breaks ??= Breaks(string, cursor, string.length, stateSoTNoBreak);
    do {
      var nextBreak = breaks.nextBreak();
      if (nextBreak < 0) break;
      cursor = nextBreak;
    } while (--count > 0);
    return cursor;
  }

  @override
  Characters skip(int count) {
    RangeError.checkNotNegative(count, "count");
    return _skip(count);
  }

  Characters _skip(int count) {
    var start = _skipIndices(count, 0, null);
    if (start == string.length) return Characters.empty;
    return StringCharacters(string.substring(start));
  }

  @override
  Characters take(int count) {
    RangeError.checkNotNegative(count, "count");
    return _take(count);
  }

  Characters _take(int count) {
    var end = _skipIndices(count, 0, null);
    if (end == string.length) return this;
    return StringCharacters(string.substring(0, end));
  }

  @override
  Characters getRange(int start, [int? end]) {
    RangeError.checkNotNegative(start, "start");
    if (end == null) return _skip(start);
    if (end < start) throw RangeError.range(end, start, null, "end");
    if (end == start) return Characters.empty;
    if (start == 0) return _take(end);
    if (string.isEmpty) return this;
    var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
    var startIndex = _skipIndices(start, 0, breaks);
    if (startIndex == string.length) return Characters.empty;
    var endIndex = _skipIndices(end - start, start, breaks);
    return StringCharacters(string.substring(startIndex, endIndex));
  }

  @override
  Characters characterAt(int position) {
    var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
    var start = 0;

    while (position > 0) {
      position--;
      start = breaks.nextBreak();
      if (start < 0) throw StateError("No element");
    }
    var end = breaks.nextBreak();
    if (end < 0) throw StateError("No element");
    if (start == 0 && end == string.length) return this;
    return StringCharacters(string.substring(start, end));
  }

  @override
  Characters skipWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var stringLength = string.length;
      var breaks = Breaks(string, 0, stringLength, stateSoTNoBreak);
      var index = 0;
      var startIndex = 0;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(startIndex, index))) {
          if (startIndex == 0) return this;
          if (startIndex == stringLength) return Characters.empty;
          return StringCharacters(string.substring(startIndex));
        }
        startIndex = index;
      }
    }
    return Characters.empty;
  }

  @override
  Characters takeWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      var index = 0;
      var endIndex = 0;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(endIndex, index))) {
          if (endIndex == 0) return Characters.empty;
          return StringCharacters(string.substring(0, endIndex));
        }
        endIndex = index;
      }
    }
    return this;
  }

  @override
  Characters where(bool Function(String) test) {
    var string = super.where(test).join();
    if (string.isEmpty) return Characters.empty;
    return StringCharacters(string);
  }

  @override
  Characters operator +(Characters characters) =>
      StringCharacters(string + characters.string);

  @override
  Characters skipLast(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return this;
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      var endIndex = string.length;
      while (count > 0) {
        var index = breaks.nextBreak();
        if (index >= 0) {
          endIndex = index;
          count--;
        } else {
          return Characters.empty;
        }
      }
      if (endIndex > 0) return StringCharacters(string.substring(0, endIndex));
    }
    return Characters.empty;
  }

  @override
  Characters skipLastWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      var index = 0;
      var end = string.length;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(index, end))) {
          if (end == string.length) return this;
          return end == 0
              ? Characters.empty
              : StringCharacters(string.substring(0, end));
        }
        end = index;
      }
    }
    return Characters.empty;
  }

  @override
  Characters takeLast(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return Characters.empty;
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      var startIndex = string.length;
      while (count > 0) {
        var index = breaks.nextBreak();
        if (index >= 0) {
          startIndex = index;
          count--;
        } else {
          return this;
        }
      }
      if (startIndex > 0) {
        return StringCharacters(string.substring(startIndex));
      }
    }
    return this;
  }

  @override
  Characters takeLastWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      var index = 0;
      var start = string.length;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(index, start))) {
          if (start == string.length) return Characters.empty;
          return StringCharacters(string.substring(start));
        }
        start = index;
      }
    }
    return this;
  }

  @override
  Characters toLowerCase() => StringCharacters(string.toLowerCase());

  @override
  Characters toUpperCase() => StringCharacters(string.toUpperCase());

  @override
  bool operator ==(Object other) =>
      other is Characters && string == other.string;

  @override
  int get hashCode => string.hashCode;

  @override
  String toString() => string;

  @override
  CharacterRange? findFirst(Characters characters) {
    var range = _rangeAll;
    if (range.collapseToFirst(characters)) return range;
    return null;
  }

  @override
  CharacterRange? findLast(Characters characters) {
    var range = _rangeAll;
    if (range.collapseToLast(characters)) return range;
    return null;
  }
}

/// A [CharacterRange] on a single string.
class StringCharacterRange implements CharacterRange {
  /// The source string.
  final String _string;

  /// Start index of range in string.
  ///
  /// The index is a code unit index in the [String].
  /// It is always at a grapheme cluster boundary.
  int _start;

  /// End index of range in string.
  ///
  /// The index is a code unit index in the [String].
  /// It is always at a grapheme cluster boundary.
  int _end;

  /// The [current] value is created lazily and cached to avoid repeated
  /// or unnecessary string allocation.
  String? _currentCache;

  StringCharacterRange(String string) : this._(string, 0, 0);

  factory StringCharacterRange.at(String string, int startIndex,
      [int? endIndex]) {
    RangeError.checkValidRange(
        startIndex, endIndex, string.length, "startIndex", "endIndex");
    return _expandRange(string, startIndex, endIndex ?? startIndex);
  }

  StringCharacterRange._(this._string, this._start, this._end);

  /// Changes the current range.
  ///
  /// Resets all cached state.
  void _move(int start, int end) {
    _start = start;
    _end = end;
    _currentCache = null;
  }

  /// Creates a [Breaks] from [_end] to `_string.length`.
  ///
  /// Uses information stored in [_state] for cases where the next
  /// character has already been seen.
  Breaks _breaksFromEnd() {
    return Breaks(_string, _end, _string.length, stateSoTNoBreak);
  }

  /// Creates a [Breaks] from string start to [_start].
  ///
  /// Uses information stored in [_state] for cases where the previous
  /// character has already been seen.
  BackBreaks _backBreaksFromStart() {
    return BackBreaks(_string, _start, 0, stateEoTNoBreak);
  }

  @override
  String get current => _currentCache ??= _string.substring(_start, _end);

  @override
  bool moveNext([int count = 1]) => _advanceEnd(count, _end);

  bool _advanceEnd(int count, int newStart) {
    if (count > 0) {
      var state = stateSoTNoBreak;
      var index = _end;
      while (index < _string.length) {
        var char = _string.codeUnitAt(index);
        var category = categoryControl;
        var nextIndex = index + 1;
        if (char & 0xFC00 != 0xD800) {
          category = low(char);
        } else if (nextIndex < _string.length) {
          var nextChar = _string.codeUnitAt(nextIndex);
          if (nextChar & 0xFC00 == 0xDC00) {
            nextIndex += 1;
            category = high(char, nextChar);
          }
        }
        state = move(state, category);
        if (state & stateNoBreak == 0 && --count == 0) {
          _move(newStart, index);
          return true;
        }
        index = nextIndex;
      }
      _move(newStart, _string.length);
      return count == 1 && state != stateSoTNoBreak;
    } else if (count == 0) {
      _move(newStart, _end);
      return true;
    } else {
      throw RangeError.range(count, 0, null, "count");
    }
  }

  bool _moveNextPattern(String patternString, int start, int end) {
    var offset = _indexOf(_string, patternString, start, end);
    if (offset >= 0) {
      _move(offset, offset + patternString.length);
      return true;
    }
    return false;
  }

  @override
  bool moveBack([int count = 1]) => _retractStart(count, _start);

  bool _retractStart(int count, int newEnd) {
    RangeError.checkNotNegative(count, "count");
    var breaks = _backBreaksFromStart();
    var start = _start;
    while (count > 0) {
      var nextBreak = breaks.nextBreak();
      if (nextBreak >= 0) {
        start = nextBreak;
      } else {
        break;
      }
      count--;
    }
    _move(start, newEnd);
    return count == 0;
  }

  bool _movePreviousPattern(String patternString, int start, int end) {
    var offset = _lastIndexOf(_string, patternString, start, end);
    if (offset >= 0) {
      _move(offset, offset + patternString.length);
      return true;
    }
    return false;
  }

  @override
  Iterable<int> get utf16CodeUnits => _string.codeUnits.getRange(_start, _end);

  @override
  Runes get runes => Runes(current);

  @override
  CharacterRange copy() {
    return StringCharacterRange._(_string, _start, _end);
  }

  @override
  void collapseToEnd() {
    _move(_end, _end);
  }

  @override
  void collapseToStart() {
    _move(_start, _start);
  }

  @override
  bool dropFirst([int count = 1]) {
    RangeError.checkNotNegative(count, "count");
    if (_start == _end) return count == 0;
    var breaks = Breaks(_string, _start, _end, stateSoTNoBreak);
    while (count > 0) {
      var nextBreak = breaks.nextBreak();
      if (nextBreak >= 0) {
        _start = nextBreak;
        _currentCache = null;
        count--;
      } else {
        return false;
      }
    }
    return true;
  }

  @override
  bool dropTo(Characters target) {
    if (_start == _end) return target.isEmpty;
    var targetString = target.string;
    var index = _indexOf(_string, targetString, _start, _end);
    if (index >= 0) {
      _move(index + targetString.length, _end);
      return true;
    }
    return false;
  }

  @override
  bool dropUntil(Characters target) {
    if (_start == _end) return target.isEmpty;
    var targetString = target.string;
    var index = _indexOf(_string, targetString, _start, _end);
    if (index >= 0) {
      _move(index, _end);
      return true;
    }
    _move(_end, _end);
    return false;
  }

  @override
  void dropWhile(bool Function(String) test) {
    if (_start == _end) return;
    var breaks = Breaks(_string, _start, _end, stateSoTNoBreak);
    var cursor = _start;
    var next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(cursor, next))) {
        break;
      }
      cursor = next;
    }
    _move(cursor, _end);
  }

  @override
  bool dropLast([int count = 1]) {
    RangeError.checkNotNegative(count, "count");
    var breaks = BackBreaks(_string, _end, _start, stateEoTNoBreak);
    while (count > 0) {
      var nextBreak = breaks.nextBreak();
      if (nextBreak >= 0) {
        _end = nextBreak;
        _currentCache = null;
        count--;
      } else {
        return false;
      }
    }
    return true;
  }

  @override
  bool dropBackTo(Characters target) {
    if (_start == _end) return target.isEmpty;
    var targetString = target.string;
    var index = _lastIndexOf(_string, targetString, _start, _end);
    if (index >= 0) {
      _move(_start, index);
      return true;
    }
    return false;
  }

  @override
  bool dropBackUntil(Characters target) {
    if (_start == _end) return target.isEmpty;
    var targetString = target.string;
    var index = _lastIndexOf(_string, targetString, _start, _end);
    if (index >= 0) {
      _move(_start, index + targetString.length);
      return true;
    }
    _move(_start, _start);
    return false;
  }

  @override
  void dropBackWhile(bool Function(String) test) {
    if (_start == _end) return;
    var breaks = BackBreaks(_string, _end, _start, stateEoTNoBreak);
    var cursor = _end;
    var next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(next, cursor))) {
        break;
      }
      cursor = next;
    }
    _move(_start, cursor);
  }

  @override
  bool expandNext([int count = 1]) => _advanceEnd(count, _start);

  @override
  bool expandTo(Characters target) {
    var targetString = target.string;
    var index = _indexOf(_string, targetString, _end, _string.length);
    if (index >= 0) {
      _move(_start, index + targetString.length);
      return true;
    }
    return false;
  }

  @override
  void expandWhile(bool Function(String character) test) {
    var breaks = _breaksFromEnd();
    var cursor = _end;
    var next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(cursor, next))) {
        break;
      }
      cursor = next;
    }
    _move(_start, cursor);
  }

  @override
  void expandAll() {
    _move(_start, _string.length);
  }

  @override
  bool expandBack([int count = 1]) => _retractStart(count, _end);

  @override
  bool expandBackTo(Characters target) {
    var targetString = target.string;
    var index = _lastIndexOf(_string, targetString, 0, _start);
    if (index >= 0) {
      _move(index, _end);
      return true;
    }
    return false;
  }

  @override
  void expandBackWhile(bool Function(String character) test) {
    var breaks = _backBreaksFromStart();
    var cursor = _start;
    var next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(next, cursor))) {
        _move(cursor, _end);
        return;
      }
      cursor = next;
    }
    _move(0, _end);
  }

  @override
  bool expandBackUntil(Characters target) {
    return _retractStartUntil(target.string, _end);
  }

  @override
  void expandBackAll() {
    _move(0, _end);
  }

  @override
  bool expandUntil(Characters target) {
    return _advanceEndUntil(target.string, _start);
  }

  @override
  bool get isEmpty => _start == _end;

  @override
  bool get isNotEmpty => _start != _end;

  @override
  bool moveBackUntil(Characters target) {
    var targetString = target.string;
    return _retractStartUntil(targetString, _start);
  }

  bool _retractStartUntil(String targetString, int newEnd) {
    var index = _lastIndexOf(_string, targetString, 0, _start);
    if (index >= 0) {
      _move(index + targetString.length, newEnd);
      return true;
    }
    _move(0, newEnd);
    return false;
  }

  @override
  bool collapseToFirst(Characters target) {
    return _moveNextPattern(target.string, _start, _end);
  }

  @override
  bool collapseToLast(Characters target) {
    return _movePreviousPattern(target.string, _start, _end);
  }

  @override
  bool moveUntil(Characters target) {
    var targetString = target.string;
    return _advanceEndUntil(targetString, _end);
  }

  bool _advanceEndUntil(String targetString, int newStart) {
    var index = _indexOf(_string, targetString, _end, _string.length);
    if (index >= 0) {
      _move(newStart, index);
      return true;
    }
    _move(newStart, _string.length);
    return false;
  }

  @override
  CharacterRange? replaceFirst(Characters pattern, Characters replacement) {
    var patternString = pattern.string;
    var replacementString = replacement.string;
    String replaced;
    if (patternString.isEmpty) {
      replaced = _string.replaceRange(_start, _start, replacementString);
    } else {
      var index = _indexOf(_string, patternString, _start, _end);
      if (index >= 0) {
        replaced = _string.replaceRange(
            index, index + patternString.length, replacementString);
      } else {
        return null;
      }
    }
    var newEnd = replaced.length - _string.length + _end;
    return _expandRange(replaced, _start, newEnd);
  }

  @override
  CharacterRange? replaceAll(Characters pattern, Characters replacement) {
    var patternString = pattern.string;
    var replacementString = replacement.string;
    if (patternString.isEmpty) {
      var replaced = _explodeReplace(
          _string, _start, _end, replacementString, replacementString);
      var newEnd = replaced.length - (_string.length - _end);
      return _expandRange(replaced, _start, newEnd);
    }
    if (_start == _end) return null;
    var start = 0;
    var cursor = _start;
    StringBuffer? buffer;
    while ((cursor = _indexOf(_string, patternString, cursor, _end)) >= 0) {
      (buffer ??= StringBuffer())
        ..write(_string.substring(start, cursor))
        ..write(replacementString);
      cursor += patternString.length;
      start = cursor;
    }
    if (buffer == null) return null;
    buffer.write(_string.substring(start));
    var replaced = buffer.toString();
    var newEnd = replaced.length - (_string.length - _end);
    return _expandRange(replaced, _start, newEnd);
  }

  @override
  CharacterRange replaceRange(Characters replacement) {
    var replacementString = replacement.string;
    var resultString = _string.replaceRange(_start, _end, replacementString);
    return _expandRange(
        resultString, _start, _start + replacementString.length);
  }

  /// Expands a range if its start or end are not grapheme cluster boundaries.
  ///
  /// Low-level function which does not validate its input. Assume that
  /// 0 <= [start] <= [end] <= `string.length`.
  static StringCharacterRange _expandRange(String string, int start, int end) {
    start = previousBreak(string, 0, string.length, start);
    if (end != start) {
      end = nextBreak(string, 0, string.length, end);
    }
    return StringCharacterRange._(string, start, end);
  }

  @override
  Characters get source => Characters(_string);

  @override
  bool startsWith(Characters characters) {
    return _startsWith(_start, _end, characters.string);
  }

  @override
  bool endsWith(Characters characters) {
    return _endsWith(_start, _end, characters.string);
  }

  @override
  bool isFollowedBy(Characters characters) {
    return _startsWith(_end, _string.length, characters.string);
  }

  @override
  bool isPrecededBy(Characters characters) {
    return _endsWith(0, _start, characters.string);
  }

  bool _endsWith(int start, int end, String string) {
    var length = string.length;
    var stringStart = end - length;
    return stringStart >= start &&
        _string.startsWith(string, stringStart) &&
        isGraphemeClusterBoundary(_string, start, end, stringStart);
  }

  bool _startsWith(int start, int end, String string) {
    var length = string.length;
    var stringEnd = start + length;
    return stringEnd <= end &&
        _string.startsWith(string, start) &&
        isGraphemeClusterBoundary(_string, start, end, stringEnd);
  }

  @override
  bool moveBackTo(Characters target) {
    var targetString = target.string;
    var index = _lastIndexOf(_string, targetString, 0, _start);
    if (index >= 0) {
      _move(index, index + targetString.length);
      return true;
    }
    return false;
  }

  @override
  bool moveTo(Characters target) {
    var targetString = target.string;
    var index = _indexOf(_string, targetString, _end, _string.length);
    if (index >= 0) {
      _move(index, index + targetString.length);
      return true;
    }
    return false;
  }

  @override
  Characters get charactersAfter => StringCharacters(_string.substring(_end));

  @override
  Characters get charactersBefore =>
      StringCharacters(_string.substring(0, _start));

  @override
  Characters get currentCharacters => StringCharacters(current);

  @override
  void moveBackAll() {
    _move(0, _start);
  }

  @override
  void moveNextAll() {
    _move(_end, _string.length);
  }

  @override
  String get stringAfter => _string.substring(_end);

  @override
  int get stringAfterLength => _string.length - _end;

  @override
  String get stringBefore => _string.substring(0, _start);

  @override
  int get stringBeforeLength => _start;

  @override
  Iterable<CharacterRange> split(Characters pattern, [int maxParts = 0]) sync* {
    if (maxParts == 1 || _start == _end) {
      yield this;
      return;
    }
    var patternString = pattern.string;
    var start = _start;
    if (patternString.isNotEmpty) {
      do {
        var match = _indexOf(_string, patternString, start, _end);
        if (match < 0) break;
        yield StringCharacterRange._(_string, start, match);
        start = match + patternString.length;
        maxParts--;
      } while (maxParts != 1);
      yield StringCharacterRange._(_string, start, _end);
    } else {
      // Empty pattern. Split on internal boundaries only.
      var breaks = Breaks(_string, _start, _end, stateSoTNoBreak);
      do {
        var match = breaks.nextBreak();
        if (match < 0) return;
        yield StringCharacterRange._(_string, start, match);
        start = match;
        maxParts--;
      } while (maxParts != 1);
      if (start < _end) {
        yield StringCharacterRange._(_string, start, _end);
      }
    }
  }
}

String _explodeReplace(String string, int start, int end,
    String internalReplacement, String outerReplacement) {
  if (start == end) {
    return string.replaceRange(start, start, outerReplacement);
  }
  var buffer = StringBuffer(string.substring(0, start));
  var breaks = Breaks(string, start, end, stateSoTNoBreak);
  var index = 0;
  var replacement = outerReplacement;
  while ((index = breaks.nextBreak()) >= 0) {
    buffer
      ..write(replacement)
      ..write(string.substring(start, index));
    start = index;
    replacement = internalReplacement;
  }
  buffer
    ..write(outerReplacement)
    ..write(string.substring(end));
  return buffer.toString();
}

/// Finds [pattern] in the range from [start] to [end].
///
/// Both [start] and [end] are grapheme cluster boundaries in the
/// [source] string.
int _indexOf(String source, String pattern, int start, int end) {
  var patternLength = pattern.length;
  if (patternLength == 0) return start;
  // Any start position after realEnd won't fit the pattern before end.
  var realEnd = end - patternLength;
  if (realEnd < start) return -1;
  // Use indexOf if what we can overshoot is
  // less than twice as much as what we have left to search.
  var rest = source.length - realEnd;
  if (rest <= (realEnd - start) * 2) {
    var index = 0;
    while (start < realEnd && (index = source.indexOf(pattern, start)) >= 0) {
      if (index > realEnd) return -1;
      if (isGraphemeClusterBoundary(source, start, end, index) &&
          isGraphemeClusterBoundary(
              source, start, end, index + patternLength)) {
        return index;
      }
      start = index + 1;
    }
    return -1;
  }
  return _gcIndexOf(source, pattern, start, end);
}

int _gcIndexOf(String source, String pattern, int start, int end) {
  var breaks = Breaks(source, start, end, stateSoT);
  var index = 0;
  while ((index = breaks.nextBreak()) >= 0) {
    var endIndex = index + pattern.length;
    if (endIndex > end) break;
    if (source.startsWith(pattern, index) &&
        isGraphemeClusterBoundary(source, start, end, endIndex)) {
      return index;
    }
  }
  return -1;
}

/// Finds pattern in the range from [start] to [end].
/// Both [start] and [end] are grapheme cluster boundaries in the
/// [source] string.
int _lastIndexOf(String source, String pattern, int start, int end) {
  var patternLength = pattern.length;
  if (patternLength == 0) return end;
  // Start of pattern must be in range [start .. end - patternLength].
  var realEnd = end - patternLength;
  if (realEnd < start) return -1;
  // If the range from 0 to start is no more than double the range from
  // start to end, use lastIndexOf.
  if (realEnd * 2 > start) {
    var index = 0;
    while (realEnd >= start &&
        (index = source.lastIndexOf(pattern, realEnd)) >= 0) {
      if (index < start) return -1;
      if (isGraphemeClusterBoundary(source, start, end, index) &&
          isGraphemeClusterBoundary(
              source, start, end, index + patternLength)) {
        return index;
      }
      realEnd = index - 1;
    }
    return -1;
  }
  return _gcLastIndexOf(source, pattern, start, end);
}

int _gcLastIndexOf(String source, String pattern, int start, int end) {
  var breaks = BackBreaks(source, end, start, stateEoT);
  var index = 0;
  while ((index = breaks.nextBreak()) >= 0) {
    var startIndex = index - pattern.length;
    if (startIndex < start) break;
    if (source.startsWith(pattern, startIndex) &&
        isGraphemeClusterBoundary(source, start, end, startIndex)) {
      return startIndex;
    }
  }
  return -1;
}
