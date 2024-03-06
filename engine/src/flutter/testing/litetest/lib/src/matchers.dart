// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:async_helper/async_minitest.dart';
import 'package:expect/expect.dart';

/// The epsilon of tolerable double precision error.
///
/// This is used in various places in the framework to allow for floating point
/// precision loss in calculations. Differences below this threshold are safe
/// to disregard.
const double precisionErrorTolerance = 1e-10;

/// Asserts that `callback` throws an [AssertionError].
///
/// When running in a VM in which assertions are enabled, asserts that the
/// specified callback throws an [AssertionError]. When asserts are not
/// enabled, such as when running using a release-mode VM with default
/// settings, this acts as a no-op.
void expectAssertion(dynamic callback) {
  bool assertsEnabled = false;
  assert(() {
    assertsEnabled = true;
    return true;
  }());
  if (assertsEnabled) {
    throwsA(isInstanceOf<AssertionError>())(callback);
  }
}

/// Asserts that `callback` throws an [ArgumentError].
void expectArgumentError(dynamic callback) {
  throwsA(isInstanceOf<ArgumentError>())(callback);
}

/// Asserts that `callback` throws some [Exception].
void throwsException(dynamic callback) {
  throwsA(isInstanceOf<Exception>())(callback);
}

/// A [Matcher] that matches empty [String]s and [Iterable]s.
void isEmpty(dynamic d) {
  if (d is String) {
    expect(d.isEmpty, true);
    return;
  }
  expect(d, isInstanceOf<Iterable<dynamic>>());
  Expect.isEmpty(d as Iterable<dynamic>);
}

/// A [Matcher] that matches non-empty [String]s and [Iterable]s.
void isNotEmpty(dynamic d) {
  if (d is String) {
    expect(d.isNotEmpty, true);
    return;
  }
  expect(d, isInstanceOf<Iterable<dynamic>>());
  Expect.isNotEmpty(d as Iterable<dynamic>);
}

/// Gives a [Matcher] that asserts that the value being matched is within
/// `tolerance` of `value`.
Matcher closeTo(num value, num tolerance) => (dynamic actual) {
      Expect.approxEquals(value, actual as num, tolerance);
    };

/// A [Matcher] that matches NaN.
void isNaN(dynamic v) {
  expect(v, isInstanceOf<num>());
  expect(double.nan.compareTo(v as num) == 0, true);
}

/// Gives a [Matcher] that asserts that the value being matched is not equal to
/// `unexpected`.
Matcher notEquals(dynamic unexpected) => (dynamic actual) {
      Expect.notEquals(unexpected, actual);
    };

/// A [Matcher] that matches non-zero values.
void isNonZero(dynamic d) {
  Expect.notEquals(0, d);
}

/// A [Matcher] that matches functions that throw a [RangeError] when invoked.
void throwsRangeError(dynamic d) {
  Expect.throwsRangeError(d as void Function());
}

/// Gives a [Matcher] that asserts that the value being matched is a [String]
/// that contains `s` as a substring.
Matcher contains(String s) => (dynamic d) {
      expect(d, isInstanceOf<String>());
      Expect.contains(s, d as String);
    };

/// Gives a [Matcher] that asserts that the value being matched is an [Iterable]
/// of length `d`.
Matcher hasLength(int l) => (dynamic d) {
      expect(d, isInstanceOf<Iterable<dynamic>>());
      expect((d as Iterable<dynamic>).length, equals(l));
    };

/// Gives a matcher that asserts that the value being matched is a [String] that
/// starts with `s`.
Matcher startsWith(String s) => (dynamic d) {
      expect(d, isInstanceOf<String>());
      final String h = d as String;
      if (!h.startsWith(s)) {
        Expect.fail('Expected "$h" to start with "$s"');
      }
    };

/// Gives a matcher that asserts that the value being matched is a [String] that
/// ends with `s`.
Matcher endsWith(String s) => (dynamic d) {
      expect(d, isInstanceOf<String>());
      final String h = d as String;
      if (!h.endsWith(s)) {
        Expect.fail('Expected "$h" to end with "$s"');
      }
    };

/// Gives a matcher that asserts that the value being matched is a [String] that
/// regexp matches with `pattern`.
Matcher hasMatch(String pattern) => (dynamic d) {
      expect(d, isInstanceOf<String>());
      final String h = d as String;
      final RegExp regExp = RegExp(pattern);
      if (!regExp.hasMatch(h)) {
        Expect.fail('Expected "$h" to match with "$pattern"');
      }
    };

/// Gives a matcher that asserts that the value being matched is a
/// `List<String>` that contains the entries in `pattern` in order.
/// There may be values that are not in the pattern interleaved.
Matcher containsStringsInOrder(List<String> pattern) => (dynamic d) {
      expect(d, isInstanceOf<List<String>>());
      final List<String> input = d as List<String>;
      int cursor = 0;
      for (final String el in input) {
        if (cursor == pattern.length) {
          break;
        }
        if (el == pattern[cursor]) {
          cursor++;
        }
      }
      if (cursor < pattern.length) {
        Expect.fail('Did not find ${pattern[cursor]} in $d');
      }
    };

/// Gives a matcher that asserts that the value being matched is a
/// `List<String>` that does not contain any of the values in `unexpected`.
Matcher doesNotContainAny(List<String> unexpected) => (dynamic d) {
      expect(d, isInstanceOf<List<String>>());
      final List<String> input = d as List<String>;
      for (final String string in input) {
        if (unexpected.contains(string)) {
          Expect.fail("String '$d' is unexpected");
        }
      }
    };
