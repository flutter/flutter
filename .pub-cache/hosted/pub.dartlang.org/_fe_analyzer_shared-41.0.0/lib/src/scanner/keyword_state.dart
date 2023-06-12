// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.scanner.keywords;

import 'token.dart' as analyzer;

import 'characters.dart' show $a, $z, $A, $Z;

/**
 * Abstract state in a state machine for scanning keywords.
 */
abstract class KeywordState {
  KeywordState? next(int c);
  KeywordState? nextCapital(int c);

  analyzer.Keyword? get keyword;

  static KeywordState? _KEYWORD_STATE;
  static KeywordState get KEYWORD_STATE {
    if (_KEYWORD_STATE == null) {
      List<String> strings = analyzer.Keyword.values
          .map((keyword) => keyword.lexeme)
          .toList(growable: false);
      strings.sort((a, b) => a.compareTo(b));
      _KEYWORD_STATE = computeKeywordStateTable(
        /* start = */ 0,
        strings,
        /* offset = */ 0,
        strings.length,
      );
    }
    return _KEYWORD_STATE!;
  }

  static KeywordState computeKeywordStateTable(
      int start, List<String> strings, int offset, int length) {
    bool isLowercase = true;

    List<KeywordState?> table =
        new List<KeywordState?>.filled($z - $A + 1, /* fill = */ null);
    assert(length != 0);
    int chunk = 0;
    int chunkStart = -1;
    bool isLeaf = false;
    for (int i = offset; i < offset + length; i++) {
      if (strings[i].length == start) {
        isLeaf = true;
      }
      if (strings[i].length > start) {
        int c = strings[i].codeUnitAt(start);
        if ($A <= c && c <= $Z) {
          isLowercase = false;
        }
        if (chunk != c) {
          if (chunkStart != -1) {
            assert(table[chunk - $A] == null);
            table[chunk - $A] = computeKeywordStateTable(
                start + 1, strings, chunkStart, i - chunkStart);
          }
          chunkStart = i;
          chunk = c;
        }
      }
    }
    if (chunkStart != -1) {
      assert(table[chunk - $A] == null);
      table[chunk - $A] = computeKeywordStateTable(
          start + 1, strings, chunkStart, offset + length - chunkStart);
    } else {
      assert(length == 1);
      return new LeafKeywordState(strings[offset]);
    }
    String? syntax = isLeaf ? strings[offset] : null;
    if (isLowercase) {
      table = table.sublist($a - $A);
      return new LowerCaseArrayKeywordState(table, syntax);
    } else {
      return new UpperCaseArrayKeywordState(table, syntax);
    }
  }
}

/**
 * A state with multiple outgoing transitions.
 */
abstract class ArrayKeywordState implements KeywordState {
  final List<KeywordState?> table;
  final analyzer.Keyword? keyword;

  ArrayKeywordState(this.table, String? syntax)
      : keyword = ((syntax == null) ? null : analyzer.Keyword.keywords[syntax]);

  KeywordState? next(int c);

  KeywordState? nextCapital(int c);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("[");
    if (keyword != null) {
      sb.write("*");
      sb.write(keyword);
      sb.write(" ");
    }
    List<KeywordState?> foo = table;
    for (int i = 0; i < foo.length; i++) {
      if (foo[i] != null) {
        sb.write("${new String.fromCharCodes([i + $a])}: "
            "${foo[i]}; ");
      }
    }
    sb.write("]");
    return sb.toString();
  }
}

class LowerCaseArrayKeywordState extends ArrayKeywordState {
  LowerCaseArrayKeywordState(List<KeywordState?> table, String? syntax)
      : super(table, syntax) {
    assert(table.length == $z - $a + 1);
  }

  KeywordState? next(int c) => table[c - $a];

  KeywordState? nextCapital(int c) => null;
}

class UpperCaseArrayKeywordState extends ArrayKeywordState {
  UpperCaseArrayKeywordState(List<KeywordState?> table, String? syntax)
      : super(table, syntax) {
    assert(table.length == $z - $A + 1);
  }

  KeywordState? next(int c) => table[c - $A];

  KeywordState? nextCapital(int c) => table[c - $A];
}

/**
 * A state that has no outgoing transitions.
 */
class LeafKeywordState implements KeywordState {
  final analyzer.Keyword keyword;

  LeafKeywordState(String syntax)
      : keyword = analyzer.Keyword.keywords[syntax]!;

  KeywordState? next(int c) => null;
  KeywordState? nextCapital(int c) => null;

  String toString() => keyword.lexeme;
}
