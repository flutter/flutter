// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class RegExp {
  @patch
  factory RegExp(String source,
      {bool multiLine = false,
      bool caseSensitive = true,
      bool unicode = false,
      bool dotAll = false}) {
    return new _RegExp(source,
        multiLine: multiLine,
        caseSensitive: caseSensitive,
        unicode: unicode,
        dotAll: dotAll);
  }

  /**
   * Finds the index of the first RegExp-significant char in [text].
   *
   * Starts looking from [start]. Returns `text.length` if no character
   * is found that has special meaning in RegExp syntax.
   */
  static int _findEscapeChar(String text, int start) {
    // Table where each character in the range U+0000 to U+007f is represented
    // by whether it needs to be escaped in a regexp.
    // The \x00 characters means escaped, and \x01 means non-escaped.
    const escapes =
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
        //                 $               (   )   *   +           .
        "\x01\x01\x01\x01\x00\x01\x01\x01\x00\x00\x00\x00\x01\x01\x00\x01"
        //                                                             ?
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x00"
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
        //                                             [   \   ]   ^
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x00\x00\x00\x00\x01"
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
        //                                             {   |   }
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x00\x00\x00\x01\x01";
    for (int i = start; i < text.length; i++) {
      int char = text.codeUnitAt(i);
      if (char <= 0x7f && escapes.codeUnitAt(char) == 0) return i;
    }
    return text.length;
  }

  @patch
  static String escape(String text) {
    int escapeCharIndex = _findEscapeChar(text, 0);
    // If the text contains no characters needing escape, return it directly.
    if (escapeCharIndex == text.length) return text;

    var buffer = new StringBuffer();
    int previousSliceEndIndex = 0;
    do {
      // Copy characters from previous escape to current escape into result.
      // This includes the previously escaped character.
      buffer.write(text.substring(previousSliceEndIndex, escapeCharIndex));
      // Prepare the current character to be escaped by prefixing it with a '\'.
      buffer.write(r"\");
      previousSliceEndIndex = escapeCharIndex;
      escapeCharIndex = _findEscapeChar(text, escapeCharIndex + 1);
    } while (escapeCharIndex < text.length);
    // Copy tail of string into result.
    buffer.write(text.substring(previousSliceEndIndex, escapeCharIndex));
    return buffer.toString();
  }

  int get _groupCount;
  Iterable<String> get _groupNames;
  int _groupNameIndex(String name);
}

class _RegExpMatch implements RegExpMatch {
  _RegExpMatch._(this._regexp, this.input, this._match);

  int get start => _start(0);
  int get end => _end(0);

  int _start(int groupIdx) {
    return _match[(groupIdx * _MATCH_PAIR)];
  }

  int _end(int groupIdx) {
    return _match[(groupIdx * _MATCH_PAIR) + 1];
  }

  String? group(int groupIdx) {
    if (groupIdx < 0 || groupIdx > _regexp._groupCount) {
      throw new RangeError.value(groupIdx);
    }
    int startIndex = _start(groupIdx);
    int endIndex = _end(groupIdx);
    if (startIndex == -1) {
      assert(endIndex == -1);
      return null;
    }
    return input._substringUnchecked(startIndex, endIndex);
  }

  String? operator [](int groupIdx) {
    return this.group(groupIdx);
  }

  List<String?> groups(List<int> groupsSpec) {
    var groupsList = new List<String?>.filled(groupsSpec.length, null);
    for (int i = 0; i < groupsSpec.length; i++) {
      groupsList[i] = group(groupsSpec[i]);
    }
    return groupsList;
  }

  int get groupCount => _regexp._groupCount;

  RegExp get pattern => _regexp;

  String? namedGroup(String name) {
    var idx = _regexp._groupNameIndex(name);
    if (idx < 0) {
      throw ArgumentError("Not a capture group name: ${name}");
    }
    return group(idx);
  }

  Iterable<String> get groupNames {
    return _regexp._groupNames;
  }

  final RegExp _regexp;
  final String input;
  final List<int> _match;
  static const int _MATCH_PAIR = 2;
}

const _initialBacktrackingStackSize = 128;

@pragma("vm:entry-point")
class _RegExp implements RegExp {
  @pragma("vm:external-name", "RegExp_factory")
  external factory _RegExp(String pattern,
      {bool multiLine = false,
      bool caseSensitive = true,
      bool unicode = false,
      bool dotAll = false});

  RegExpMatch? firstMatch(String input) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (input == null) throw new ArgumentError.notNull('input');
    final match = _ExecuteMatch(input, 0);
    if (match == null) {
      return null;
    }
    return new _RegExpMatch._(this, input, match);
  }

  Iterable<RegExpMatch> allMatches(String string, [int start = 0]) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (string == null) throw new ArgumentError.notNull('string');
    if (start == null) throw new ArgumentError.notNull('start');
    if (0 > start || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    return new _AllMatchesIterable(this, string, start);
  }

  RegExpMatch? matchAsPrefix(String string, [int start = 0]) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (string == null) throw new ArgumentError.notNull('string');
    if (start == null) throw new ArgumentError.notNull('start');
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    final list = _ExecuteMatchSticky(string, start);
    if (list == null) return null;
    return new _RegExpMatch._(this, string, list);
  }

  bool hasMatch(String input) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (input == null) throw new ArgumentError.notNull('input');
    List? match = _ExecuteMatch(input, 0);
    return (match == null) ? false : true;
  }

  String? stringMatch(String input) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (input == null) throw new ArgumentError.notNull('input');
    List? match = _ExecuteMatch(input, 0);
    if (match == null) {
      return null;
    }
    return input._substringUnchecked(match[0], match[1]);
  }

  @pragma("vm:external-name", "RegExp_getPattern")
  external String get pattern;

  @pragma("vm:external-name", "RegExp_getIsMultiLine")
  external bool get isMultiLine;

  @pragma("vm:external-name", "RegExp_getIsCaseSensitive")
  external bool get isCaseSensitive;

  @pragma("vm:external-name", "RegExp_getIsUnicode")
  external bool get isUnicode;

  @pragma("vm:external-name", "RegExp_getIsDotAll")
  external bool get isDotAll;

  @pragma("vm:external-name", "RegExp_getGroupCount")
  external int get _groupCount;

  /// The names and indices of named capture group.
  ///
  /// Returns a [List] of alternating strings and integers,
  /// `[String, int, String, int, ...]` where each
  /// [String] is the name of a capture group and the following
  /// [int] is that capture group's index.
  /// Returns `null` if there are no group names.
  @pragma("vm:external-name", "RegExp_getGroupNameMap")
  external List? get _groupNameList;

  Iterable<String> get _groupNames sync* {
    final nameList = _groupNameList;
    if (nameList == null) return;
    for (var i = 0; i < nameList.length; i += 2) {
      yield nameList[i] as String;
    }
  }

  int _groupNameIndex(String name) {
    var nameList = _groupNameList;
    if (nameList == null) return -1;
    for (var i = 0; i < nameList.length; i += 2) {
      if (name == nameList[i]) {
        return nameList[i + 1] as int;
      }
    }
    return -1;
  }

  // Byte map of one byte characters with a 0xff if the character is a word
  // character (digit, letter or underscore) and 0x00 otherwise.
  // Used by generated RegExp code.
  static const List<int> _wordCharacterMap = const <int>[
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // '0' - '7'
    0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // '8' - '9'

    0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'A' - 'G'
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'H' - 'O'
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'P' - 'W'
    0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xff, // 'X' - 'Z', '_'

    0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'a' - 'g'
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'h' - 'o'
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'p' - 'w'
    0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, // 'x' - 'z'
    // Latin-1 range
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  ];

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:external-name", "RegExp_ExecuteMatch")
  external List<int>? _ExecuteMatch(String str, int start_index);

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:external-name", "RegExp_ExecuteMatchSticky")
  external List<int>? _ExecuteMatchSticky(String str, int start_index);

  static Int32List _getRegisters(int registers_count) {
    var registers = _registers;
    if (registers == null || registers.length < registers_count) {
      _registers = registers = Int32List(registers_count);
    }
    return registers;
  }

// TODO: Should we bound this to the same limit used by the irregexp interpreter
// for consistency?
  static Int32List _growBacktrackingStack() {
    final stack = _backtrackingStack;
    final newStack = Int32List(stack.length * 2);
    for (int i = 0; i < stack.length; i++) {
      newStack[i] = stack[i];
    }
    _backtrackingStack = newStack;
    return newStack;
  }

  static Int32List? _registers;

  static Int32List _backtrackingStack =
      Int32List(_initialBacktrackingStackSize);
}

class _AllMatchesIterable extends Iterable<RegExpMatch> {
  final _RegExp _re;
  final String _str;
  final int _start;

  _AllMatchesIterable(this._re, this._str, this._start);

  Iterator<RegExpMatch> get iterator =>
      new _AllMatchesIterator(_re, _str, _start);
}

class _AllMatchesIterator implements Iterator<RegExpMatch> {
  final String _str;
  int _nextIndex;
  _RegExp? _re;
  RegExpMatch? _current;

  _AllMatchesIterator(this._re, this._str, this._nextIndex);

  RegExpMatch get current => _current as RegExpMatch;

  static bool _isLeadSurrogate(int c) {
    return c >= 0xd800 && c <= 0xdbff;
  }

  static bool _isTrailSurrogate(int c) {
    return c >= 0xdc00 && c <= 0xdfff;
  }

  bool moveNext() {
    final re = _re;
    if (re == null) return false; // Cleared after a failed match.
    if (_nextIndex <= _str.length) {
      final match = re._ExecuteMatch(_str, _nextIndex);
      if (match != null) {
        var current = new _RegExpMatch._(re, _str, match);
        _current = current;
        _nextIndex = current.end;
        if (_nextIndex == current.start) {
          // Zero-width match. Advance by one more, unless the regexp
          // is in unicode mode and it would put us within a surrogate
          // pair. In that case, advance past the code point as a whole.
          if (re.isUnicode &&
              _nextIndex + 1 < _str.length &&
              _isLeadSurrogate(_str.codeUnitAt(_nextIndex)) &&
              _isTrailSurrogate(_str.codeUnitAt(_nextIndex + 1))) {
            _nextIndex++;
          }
          _nextIndex++;
        }
        return true;
      }
    }
    _current = null;
    _re = null;
    return false;
  }
}
