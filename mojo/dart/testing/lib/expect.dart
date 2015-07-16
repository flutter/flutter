// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library contains an Expect class with static methods that can be used
 * for simple unit-tests.
 */
library expect;

/**
 * Expect is used for tests that do not want to make use of the
 * Dart unit test library - for example, the core language tests.
 * Third parties are discouraged from using this, and should use
 * the expect() function in the unit test library instead for
 * test assertions.
 */
class Expect {
  /**
   * Return a slice of a string.
   *
   * The slice will contain at least the substring from [start] to the lower of
   * [end] and `start + length`.
   * If the result is no more than `length - 10` characters long,
   * context may be added by extending the range of the slice, by decreasing
   * [start] and increasing [end], up to at most length characters.
   * If the start or end of the slice are not matching the start or end of
   * the string, ellipses are added before or after the slice.
   * Control characters may be encoded as "\xhh" codes.
   */
  static String _truncateString(String string, int start, int end, int length) {
    if (end - start > length) {
      end = start + length;
    } else if (end - start < length) {
      int overflow = length - (end - start);
      if (overflow > 10) overflow = 10;
      // Add context.
      start = start - ((overflow + 1) ~/ 2);
      end = end + (overflow ~/ 2);
      if (start < 0) start = 0;
      if (end > string.length) end = string.length;
    }
    if (start == 0 && end == string.length) return string;
    StringBuffer buf = new StringBuffer();
    if (start > 0) buf.write("...");
    for (int i = start; i < end; i++) {
      int code = string.codeUnitAt(i);
      if (code < 0x20) {
        buf.write(r"\x");
        buf.write("0123456789abcdef"[code ~/ 16]);
        buf.write("0123456789abcdef"[code % 16]);
      } else {
        buf.writeCharCode(string.codeUnitAt(i));
      }
    }
    if (end < string.length) buf.write("...");
    return buf.toString();
  }

  /**
   * Find the difference between two strings.
   *
   * This finds the first point where two strings differ, and returns
   * a text describing the difference.
   *
   * For small strings (length less than 20) nothing is done, and null is
   * returned. Small strings can be compared visually, but for longer strings
   * only a slice  containing the first difference will be shown.
   */
  static String _stringDifference(String expected, String actual) {
    if (expected.length < 20 && actual.length < 20) return null;
    for (int i = 0; i < expected.length && i < actual.length; i++) {
      if (expected.codeUnitAt(i) != actual.codeUnitAt(i)) {
        int start = i;
        i++;
        while (i < expected.length && i < actual.length) {
          if (expected.codeUnitAt(i) == actual.codeUnitAt(i)) break;
          i++;
        }
        int end = i;
        var truncExpected = _truncateString(expected, start, end, 20);
        var truncActual = _truncateString(actual, start, end, 20);
        return "at index $start: Expected <$truncExpected>, "
                                "Found: <$truncActual>";
      }
    }
    return null;
  }

  /**
   * Checks whether the expected and actual values are equal (using `==`).
   */
  static void equals(var expected, var actual, [String reason = null]) {
    if (expected == actual) return;
    String msg = _getMessage(reason);
    if (expected is String && actual is String) {
      String stringDifference = _stringDifference(expected, actual);
      if (stringDifference != null) {
        _fail("Expect.equals($stringDifference$msg) fails.");
      }
    }
    _fail("Expect.equals(expected: <$expected>, actual: <$actual>$msg) fails.");
  }

  /**
   * Checks whether the actual value is a bool and its value is true.
   */
  static void isTrue(var actual, [String reason = null]) {
    if (_identical(actual, true)) return;
    String msg = _getMessage(reason);
    _fail("Expect.isTrue($actual$msg) fails.");
  }

  /**
   * Checks whether the actual value is a bool and its value is false.
   */
  static void isFalse(var actual, [String reason = null]) {
    if (_identical(actual, false)) return;
    String msg = _getMessage(reason);
    _fail("Expect.isFalse($actual$msg) fails.");
  }

  /**
   * Checks whether [actual] is null.
   */
  static void isNull(actual, [String reason = null]) {
    if (null == actual) return;
    String msg = _getMessage(reason);
    _fail("Expect.isNull(actual: <$actual>$msg) fails.");
  }

  /**
   * Checks whether [actual] is not null.
   */
  static void isNotNull(actual, [String reason = null]) {
    if (null != actual) return;
    String msg = _getMessage(reason);
    _fail("Expect.isNotNull(actual: <$actual>$msg) fails.");
  }

  /**
   * Checks whether the expected and actual values are identical
   * (using `identical`).
   */
  static void identical(var expected, var actual, [String reason = null]) {
    if (_identical(expected, actual)) return;
    String msg = _getMessage(reason);
    _fail("Expect.identical(expected: <$expected>, actual: <$actual>$msg) "
          "fails.");
  }

  // Unconditional failure.
  static void fail(String msg) {
    _fail("Expect.fail('$msg')");
  }

  /**
   * Failure if the difference between expected and actual is greater than the
   * given tolerance. If no tolerance is given, tolerance is assumed to be the
   * value 4 significant digits smaller than the value given for expected.
   */
  static void approxEquals(num expected,
                           num actual,
                           [num tolerance = null,
                            String reason = null]) {
    if (tolerance == null) {
      tolerance = (expected / 1e4).abs();
    }
    // Note: use !( <= ) rather than > so we fail on NaNs
    if ((expected - actual).abs() <= tolerance) return;

    String msg = _getMessage(reason);
    _fail('Expect.approxEquals(expected:<$expected>, actual:<$actual>, '
          'tolerance:<$tolerance>$msg) fails');
  }

  static void notEquals(unexpected, actual, [String reason = null]) {
    if (unexpected != actual) return;
    String msg = _getMessage(reason);
    _fail("Expect.notEquals(unexpected: <$unexpected>, actual:<$actual>$msg) "
          "fails.");
  }

  /**
   * Checks that all elements in [expected] and [actual] are equal `==`.
   * This is different than the typical check for identity equality `identical`
   * used by the standard list implementation.  It should also produce nicer
   * error messages than just calling `Expect.equals(expected, actual)`.
   */
  static void listEquals(List expected, List actual, [String reason = null]) {
    String msg = _getMessage(reason);
    int n = (expected.length < actual.length) ? expected.length : actual.length;
    for (int i = 0; i < n; i++) {
      if (expected[i] != actual[i]) {
        _fail('Expect.listEquals(at index $i, '
              'expected: <${expected[i]}>, actual: <${actual[i]}>$msg) fails');
      }
    }
    // We check on length at the end in order to provide better error
    // messages when an unexpected item is inserted in a list.
    if (expected.length != actual.length) {
      _fail('Expect.listEquals(list length, '
        'expected: <${expected.length}>, actual: <${actual.length}>$msg) '
        'fails: Next element <'
        '${expected.length > n ? expected[n] : actual[n]}>');
    }
  }

  /**
   * Checks that all [expected] and [actual] have the same set of keys (using
   * the semantics of [Map.containsKey] to determine what "same" means. For
   * each key, checks that the values in both maps are equal using `==`.
   */
  static void mapEquals(Map expected, Map actual, [String reason = null]) {
    String msg = _getMessage(reason);

    // Make sure all of the values are present in both and match.
    for (final key in expected.keys) {
      if (!actual.containsKey(key)) {
        _fail('Expect.mapEquals(missing expected key: <$key>$msg) fails');
      }

      Expect.equals(expected[key], actual[key]);
    }

    // Make sure the actual map doesn't have any extra keys.
    for (final key in actual.keys) {
      if (!expected.containsKey(key)) {
        _fail('Expect.mapEquals(unexpected key: <$key>$msg) fails');
      }
    }
  }

  /**
   * Specialized equality test for strings. When the strings don't match,
   * this method shows where the mismatch starts and ends.
   */
  static void stringEquals(String expected,
                           String actual,
                           [String reason = null]) {
    String msg = _getMessage(reason);
    String defaultMessage =
        'Expect.stringEquals(expected: <$expected>", <$actual>$msg) fails';

    if (expected == actual) return;
    if ((expected == null) || (actual == null)) {
      _fail('$defaultMessage');
    }
    // scan from the left until we find a mismatch
    int left = 0;
    int eLen = expected.length;
    int aLen = actual.length;
    while (true) {
      if (left == eLen) {
        assert (left < aLen);
        String snippet = actual.substring(left, aLen);
        _fail('$defaultMessage\nDiff:\n...[  ]\n...[ $snippet ]');
        return;
      }
      if (left == aLen) {
        assert (left < eLen);
        String snippet = expected.substring(left, eLen);
        _fail('$defaultMessage\nDiff:\n...[  ]\n...[ $snippet ]');
        return;
      }
      if (expected[left] != actual[left]) {
        break;
      }
      left++;
    }

    // scan from the right until we find a mismatch
    int right = 0;
    while (true) {
      if (right == eLen) {
        assert (right < aLen);
        String snippet = actual.substring(0, aLen - right);
        _fail('$defaultMessage\nDiff:\n[  ]...\n[ $snippet ]...');
        return;
      }
      if (right == aLen) {
        assert (right < eLen);
        String snippet = expected.substring(0, eLen - right);
        _fail('$defaultMessage\nDiff:\n[  ]...\n[ $snippet ]...');
        return;
      }
      // stop scanning if we've reached the end of the left-to-right match
      if (eLen - right <= left || aLen - right <= left) {
        break;
      }
      if (expected[eLen - right - 1] != actual[aLen - right - 1]) {
        break;
      }
      right++;
    }
    String eSnippet = expected.substring(left, eLen - right);
    String aSnippet = actual.substring(left, aLen - right);
    String diff = '\nDiff:\n...[ $eSnippet ]...\n...[ $aSnippet ]...';
    _fail('$defaultMessage$diff');
  }

  /**
   * Checks that every element of [expected] is also in [actual], and that
   * every element of [actual] is also in [expected].
   */
  static void setEquals(Iterable expected,
                        Iterable actual,
                        [String reason = null]) {
    final missingSet = new Set.from(expected);
    missingSet.removeAll(actual);
    final extraSet = new Set.from(actual);
    extraSet.removeAll(expected);

    if (extraSet.isEmpty && missingSet.isEmpty) return;
    String msg = _getMessage(reason);

    StringBuffer sb = new StringBuffer("Expect.setEquals($msg) fails");
    // Report any missing items.
    if (!missingSet.isEmpty) {
      sb.write('\nExpected collection does not contain: ');
    }

    for (final val in missingSet) {
      sb.write('$val ');
    }

    // Report any extra items.
    if (!extraSet.isEmpty) {
      sb.write('\nExpected collection should not contain: ');
    }

    for (final val in extraSet) {
      sb.write('$val ');
    }
    _fail(sb.toString());
  }

  /**
   * Calls the function [f] and verifies that it throws an exception.
   * The optional [check] function can provide additional validation
   * that the correct exception is being thrown.  For example, to check
   * the type of the exception you could write this:
   *
   *     Expect.throws(myThrowingFunction, (e) => e is MyException);
   */
  static void throws(void f(),
                     [_CheckExceptionFn check = null,
                      String reason = null]) {
    try {
      f();
    } catch (e, s) {
      if (check != null) {
        if (!check(e)) {
          String msg = reason == null ? "" : reason;
          _fail("Expect.throws($msg): Unexpected '$e'\n$s");
        }
      }
      return;
    }
    String msg = reason == null ? "" : reason;
    _fail('Expect.throws($msg) fails');
  }

  static String _getMessage(String reason)
      => (reason == null) ? "" : ", '$reason'";

  static void _fail(String message) {
    throw new ExpectException(message);
  }
}

bool _identical(a, b) => identical(a, b);

typedef bool _CheckExceptionFn(exception);

class ExpectException implements Exception {
  ExpectException(this.message);
  String toString() => message;
  String message;
}
