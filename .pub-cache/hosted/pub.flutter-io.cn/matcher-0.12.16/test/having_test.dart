// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: lines_longer_than_80_chars

import 'package:matcher/matcher.dart';
import 'package:test/test.dart' show test, expect, throwsA, group;

import 'test_utils.dart';

void main() {
  test('success', () {
    shouldPass(RangeError('details'), _rangeMatcher);
  });

  test('failure', () {
    shouldFail(
      CustomRangeError.range(-1, 1, 10),
      _rangeMatcher,
      "Expected: <Instance of 'RangeError'> with "
      "`message`: contains 'details' and `start`: null and `end`: null "
      'Actual: CustomRangeError:<RangeError: Invalid value: details> '
      "Which: has `message` with value 'Invalid value' "
      "which does not contain 'details'",
    );
  });

  // This code is used in the [TypeMatcher] doc comments.
  test('integration and example', () {
    void shouldThrowRangeError(int value) {
      throw RangeError.range(value, 10, 20);
    }

    expect(
        () => shouldThrowRangeError(5),
        throwsA(const TypeMatcher<RangeError>()
            .having((e) => e.start, 'start', greaterThanOrEqualTo(10))
            .having((e) => e.end, 'end', lessThanOrEqualTo(20))));

    expect(
        () => shouldThrowRangeError(5),
        throwsA(isRangeError
            .having((e) => e.start, 'start', greaterThanOrEqualTo(10))
            .having((e) => e.end, 'end', lessThanOrEqualTo(20))));
  });

  test('having inside deep matcher', () {
    shouldFail(
        [RangeError.range(-1, 1, 10)],
        equals([_rangeMatcher]),
        anyOf([
          equalsIgnoringWhitespace(
              "Expected: [ <<Instance of 'RangeError'> with "
              "`message`: contains 'details' and `start`: null and `end`: null> ] "
              'Actual: [RangeError:RangeError: '
              'Invalid value: Not in inclusive range 1..10: -1] '
              'Which: at location [0] is RangeError:<RangeError: '
              'Invalid value: Not in inclusive range 1..10: -1> '
              "which has `message` with value 'Invalid value' "
              "which does not contain 'details'"),
          equalsIgnoringWhitespace(// Older SDKs
              "Expected: [ <<Instance of 'RangeError'> with "
              "`message`: contains 'details' and `start`: null and `end`: null> ] "
              'Actual: [RangeError:RangeError: '
              'Invalid value: Not in range 1..10, inclusive: -1] '
              'Which: at location [0] is RangeError:<RangeError: '
              'Invalid value: Not in range 1..10, inclusive: -1> '
              "which has `message` with value 'Invalid value' "
              "which does not contain 'details'")
        ]));
  });

  group('CustomMatcher copy', () {
    test('Feature Matcher', () {
      var w = Widget();
      w.price = 10;
      shouldPass(w, _hasPrice(10));
      shouldPass(w, _hasPrice(greaterThan(0)));
      shouldFail(
          w,
          _hasPrice(greaterThan(10)),
          "Expected: <Instance of 'Widget'> with `price`: a value greater than <10> "
          "Actual: <Instance of 'Widget'> "
          'Which: has `price` with value <10> which is not '
          'a value greater than <10>');
    });

    test('Custom Matcher Exception', () {
      shouldFail(
          'a',
          _badCustomMatcher(),
          allOf([
            contains(
                "Expected: <Instance of 'Widget'> with `feature`: {1: 'a'} "),
            contains("Actual: 'a'"),
          ]));
      shouldFail(
          Widget(),
          _badCustomMatcher(),
          allOf([
            contains(
                "Expected: <Instance of 'Widget'> with `feature`: {1: 'a'} "),
            contains("Actual: <Instance of 'Widget'> "),
            contains("Which: threw 'Exception: bang' "),
          ]));
    });
  });
}

final _rangeMatcher = isRangeError
    .having((e) => e.message, 'message', contains('details'))
    .having((e) => e.start, 'start', isNull)
    .having((e) => e.end, 'end', isNull);

Matcher _hasPrice(Object matcher) =>
    const TypeMatcher<Widget>().having((e) => e.price, 'price', matcher);

Matcher _badCustomMatcher() => const TypeMatcher<Widget>()
    .having((e) => throw Exception('bang'), 'feature', {1: 'a'});

class CustomRangeError extends RangeError {
  CustomRangeError.range(
      super.invalidValue, int super.minValue, int super.maxValue)
      : super.range();

  @override
  String toString() => 'RangeError: Invalid value: details';
}
