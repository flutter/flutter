// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Inserts the given arguments into [pattern].
///
///     format('Hello, {0}!', 'John') = 'Hello, John!'
///     format('{0} are you {1}ing?', 'How', 'do') = 'How are you doing?'
///     format('{0} are you {1}ing?', 'What', 'read') = 'What are you reading?'
String format(String pattern,
    [Object? arg0,
    Object? arg1,
    Object? arg2,
    Object? arg3,
    Object? arg4,
    Object? arg5,
    Object? arg6,
    Object? arg7]) {
  // TODO(rnystrom): This is not used by analyzer, but is called by
  // analysis_server. Move this code there and remove it from here.
  return formatList(pattern, [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7]);
}

/// Inserts the given [arguments] into [pattern].
///
///     format('Hello, {0}!', ['John']) = 'Hello, John!'
///     format('{0} are you {1}ing?', ['How', 'do']) = 'How are you doing?'
///     format('{0} are you {1}ing?', ['What', 'read']) =
///         'What are you reading?'
String formatList(String pattern, List<Object?>? arguments) {
  if (arguments == null || arguments.isEmpty) {
    assert(!pattern.contains(RegExp(r'\{(\d+)\}')),
        'Message requires arguments, but none were provided.');
    return pattern;
  }
  return pattern.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
    String indexStr = match.group(1)!;
    int index = int.parse(indexStr);
    return arguments[index].toString();
  });
}

/// Very limited printf implementation, supports only %s and %d.
String _printf(String fmt, List args) {
  StringBuffer sb = StringBuffer();
  bool markFound = false;
  int argIndex = 0;
  for (int i = 0; i < fmt.length; i++) {
    int c = fmt.codeUnitAt(i);
    if (c == 0x25) {
      if (markFound) {
        sb.writeCharCode(c);
        markFound = false;
      } else {
        markFound = true;
      }
      continue;
    }
    if (markFound) {
      markFound = false;
      // %d
      if (c == 0x64) {
        sb.write(args[argIndex++]);
        continue;
      }
      // %s
      if (c == 0x73) {
        sb.write(args[argIndex++]);
        continue;
      }
      // unknown
      throw ArgumentError('[$fmt][$i] = 0x${c.toRadixString(16)}');
    } else {
      sb.writeCharCode(c);
    }
  }
  return sb.toString();
}

class Character {
  static const int MAX_VALUE = 0xffff;
  static const int MAX_CODE_POINT = 0x10ffff;
  static const int MIN_SUPPLEMENTARY_CODE_POINT = 0x010000;
  static const int MIN_LOW_SURROGATE = 0xDC00;
  static const int MIN_HIGH_SURROGATE = 0xD800;

  static int digit(int codePoint, int radix) {
    if (radix != 16) {
      throw ArgumentError("only radix == 16 is supported");
    }
    if (0x30 <= codePoint && codePoint <= 0x39) {
      return codePoint - 0x30;
    }
    if (0x41 <= codePoint && codePoint <= 0x46) {
      return 0xA + (codePoint - 0x41);
    }
    if (0x61 <= codePoint && codePoint <= 0x66) {
      return 0xA + (codePoint - 0x61);
    }
    return -1;
  }

  static bool isDigit(int c) => c >= 0x30 && c <= 0x39;

  static bool isLetter(int c) =>
      c >= 0x41 && c <= 0x5A || c >= 0x61 && c <= 0x7A;

  static bool isLetterOrDigit(int c) => isLetter(c) || isDigit(c);

  static bool isWhitespace(int c) =>
      c == 0x09 || c == 0x20 || c == 0x0A || c == 0x0D;

  static String toChars(int codePoint) {
    if (codePoint < 0 || codePoint > MAX_CODE_POINT) {
      throw ArgumentError();
    }
    if (codePoint < MIN_SUPPLEMENTARY_CODE_POINT) {
      return String.fromCharCode(codePoint);
    }
    int offset = codePoint - MIN_SUPPLEMENTARY_CODE_POINT;
    int c0 = ((offset & 0x7FFFFFFF) >> 10) + MIN_HIGH_SURROGATE;
    int c1 = (offset & 0x3ff) + MIN_LOW_SURROGATE;
    return String.fromCharCodes([c0, c1]);
  }
}

@deprecated
abstract class Enum<E extends Enum<E>> implements Comparable<E> {
  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  const Enum(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(E other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

@deprecated
class PrintStringWriter extends PrintWriter {
  final StringBuffer _sb = StringBuffer();

  @override
  void print(Object x) {
    _sb.write(x);
  }

  @override
  String toString() => _sb.toString();
}

abstract class PrintWriter {
  void newLine() {
    print('\n');
  }

  void print(Object x);

  void printf(String fmt, List args) {
    print(_printf(fmt, args));
  }

  void println(String s) {
    print(s);
    newLine();
  }
}
