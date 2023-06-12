// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/interner.dart';
import 'package:analyzer/src/generated/java_core.dart';

export 'package:analyzer/exception/exception.dart';

/// A predicate is a one-argument function that returns a boolean value.
typedef Predicate<E> = bool Function(E argument);

class StringUtilities {
  static const String EMPTY = '';
  static const List<String> EMPTY_ARRAY = <String>[];

  static Interner INTERNER = NullInterner();

  /// Compute line starts for the given [content].
  /// Lines end with `\r`, `\n` or `\r\n`.
  static List<int> computeLineStarts(String content) {
    List<int> lineStarts = <int>[0];
    int length = content.length;
    int unit;
    for (int index = 0; index < length; index++) {
      unit = content.codeUnitAt(index);
      // Special-case \r\n.
      if (unit == 0x0D /* \r */) {
        // Peek ahead to detect a following \n.
        if ((index + 1 < length) && content.codeUnitAt(index + 1) == 0x0A) {
          // Line start will get registered at next index at the \n.
        } else {
          lineStarts.add(index + 1);
        }
      }
      // \n
      if (unit == 0x0A) {
        lineStarts.add(index + 1);
      }
    }
    return lineStarts;
  }

  static bool endsWith3(String str, int c1, int c2, int c3) {
    var length = str.length;
    return length >= 3 &&
        str.codeUnitAt(length - 3) == c1 &&
        str.codeUnitAt(length - 2) == c2 &&
        str.codeUnitAt(length - 1) == c3;
  }

  static bool endsWithChar(String str, int c) {
    int length = str.length;
    return length > 0 && str.codeUnitAt(length - 1) == c;
  }

  static int indexOf1(String str, int start, int c) {
    int index = start;
    int last = str.length;
    while (index < last) {
      if (str.codeUnitAt(index) == c) {
        return index;
      }
      index++;
    }
    return -1;
  }

  static int indexOf2(String str, int start, int c1, int c2) {
    int index = start;
    int last = str.length - 1;
    while (index < last) {
      if (str.codeUnitAt(index) == c1 && str.codeUnitAt(index + 1) == c2) {
        return index;
      }
      index++;
    }
    return -1;
  }

  static int indexOf4(
      String string, int start, int c1, int c2, int c3, int c4) {
    int index = start;
    int last = string.length - 3;
    while (index < last) {
      if (string.codeUnitAt(index) == c1 &&
          string.codeUnitAt(index + 1) == c2 &&
          string.codeUnitAt(index + 2) == c3 &&
          string.codeUnitAt(index + 3) == c4) {
        return index;
      }
      index++;
    }
    return -1;
  }

  static int indexOf5(
      String str, int start, int c1, int c2, int c3, int c4, int c5) {
    int index = start;
    int last = str.length - 4;
    while (index < last) {
      if (str.codeUnitAt(index) == c1 &&
          str.codeUnitAt(index + 1) == c2 &&
          str.codeUnitAt(index + 2) == c3 &&
          str.codeUnitAt(index + 3) == c4 &&
          str.codeUnitAt(index + 4) == c5) {
        return index;
      }
      index++;
    }
    return -1;
  }

  /// Return the index of the first not letter/digit character in the [string]
  /// that is at or after the [startIndex]. Return the length of the [string] if
  /// all characters to the end are letters/digits.
  static int indexOfFirstNotLetterDigit(String string, int startIndex) {
    int index = startIndex;
    int last = string.length;
    while (index < last) {
      int c = string.codeUnitAt(index);
      if (!Character.isLetterOrDigit(c)) {
        return index;
      }
      index++;
    }
    return last;
  }

  static String intern(String string) => INTERNER.intern(string);
  static bool isEmpty(String? s) {
    return s == null || s.isEmpty;
  }

  static bool isTagName(String? s) {
    if (s == null || s.isEmpty) {
      return false;
    }
    int sz = s.length;
    for (int i = 0; i < sz; i++) {
      int c = s.codeUnitAt(i);
      if (!Character.isLetter(c)) {
        if (i == 0) {
          return false;
        }
        if (!Character.isDigit(c) && c != 0x2D) {
          return false;
        }
      }
    }
    return true;
  }

  /// Produce a string containing all of the names in the given array,
  /// surrounded by single quotes, and separated by commas.
  ///
  /// The list must contain at least two elements.
  ///
  /// @param names the names to be printed
  /// @return the result of printing the names
  static String printListOfQuotedNames(List<String>? names) {
    if (names == null) {
      throw ArgumentError("The list must not be null");
    }
    int count = names.length;
    if (count < 2) {
      throw ArgumentError("The list must contain at least two names");
    }
    StringBuffer buffer = StringBuffer();
    buffer.write("'");
    buffer.write(names[0]);
    buffer.write("'");
    for (int i = 1; i < count - 1; i++) {
      buffer.write(", '");
      buffer.write(names[i]);
      buffer.write("'");
    }
    buffer.write(" and '");
    buffer.write(names[count - 1]);
    buffer.write("'");
    return buffer.toString();
  }

  static bool startsWith2(String str, int start, int c1, int c2) {
    return str.length - start >= 2 &&
        str.codeUnitAt(start) == c1 &&
        str.codeUnitAt(start + 1) == c2;
  }

  static bool startsWith3(String str, int start, int c1, int c2, int c3) {
    return str.length - start >= 3 &&
        str.codeUnitAt(start) == c1 &&
        str.codeUnitAt(start + 1) == c2 &&
        str.codeUnitAt(start + 2) == c3;
  }

  static bool startsWith4(
      String str, int start, int c1, int c2, int c3, int c4) {
    return str.length - start >= 4 &&
        str.codeUnitAt(start) == c1 &&
        str.codeUnitAt(start + 1) == c2 &&
        str.codeUnitAt(start + 2) == c3 &&
        str.codeUnitAt(start + 3) == c4;
  }

  static bool startsWith5(
      String str, int start, int c1, int c2, int c3, int c4, int c5) {
    return str.length - start >= 5 &&
        str.codeUnitAt(start) == c1 &&
        str.codeUnitAt(start + 1) == c2 &&
        str.codeUnitAt(start + 2) == c3 &&
        str.codeUnitAt(start + 3) == c4 &&
        str.codeUnitAt(start + 4) == c5;
  }

  static bool startsWith6(
      String str, int start, int c1, int c2, int c3, int c4, int c5, int c6) {
    return str.length - start >= 6 &&
        str.codeUnitAt(start) == c1 &&
        str.codeUnitAt(start + 1) == c2 &&
        str.codeUnitAt(start + 2) == c3 &&
        str.codeUnitAt(start + 3) == c4 &&
        str.codeUnitAt(start + 4) == c5 &&
        str.codeUnitAt(start + 5) == c6;
  }

  static String? substringBefore(String? str, String? separator) {
    if (str == null || str.isEmpty) {
      return str;
    }
    if (separator == null) {
      return str;
    }
    int pos = str.indexOf(separator);
    if (pos < 0) {
      return str;
    }
    return str.substring(0, pos);
  }

  static String substringBeforeChar(String str, int c) {
    if (isEmpty(str)) {
      return str;
    }
    int pos = indexOf1(str, 0, c);
    if (pos < 0) {
      return str;
    }
    return str.substring(0, pos);
  }
}

class UUID {
  static const int __nextId = 0;

  final String id;

  UUID(this.id);

  @override
  String toString() => id;

  static UUID randomUUID() => UUID((__nextId).toString());
}
