// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.numeric_matchers;

import 'interfaces.dart';

/// Returns a matcher which matches if the match argument is greater
/// than the given [value].
Matcher greaterThan(value) =>
    new _OrderingComparison(value, false, false, true, 'a value greater than');

/// Returns a matcher which matches if the match argument is greater
/// than or equal to the given [value].
Matcher greaterThanOrEqualTo(value) => new _OrderingComparison(
    value, true, false, true, 'a value greater than or equal to');

/// Returns a matcher which matches if the match argument is less
/// than the given [value].
Matcher lessThan(value) =>
    new _OrderingComparison(value, false, true, false, 'a value less than');

/// Returns a matcher which matches if the match argument is less
/// than or equal to the given [value].
Matcher lessThanOrEqualTo(value) => new _OrderingComparison(
    value, true, true, false, 'a value less than or equal to');

/// A matcher which matches if the match argument is zero.
const Matcher isZero =
    const _OrderingComparison(0, true, false, false, 'a value equal to');

/// A matcher which matches if the match argument is non-zero.
const Matcher isNonZero =
    const _OrderingComparison(0, false, true, true, 'a value not equal to');

/// A matcher which matches if the match argument is positive.
const Matcher isPositive =
    const _OrderingComparison(0, false, false, true, 'a positive value', false);

/// A matcher which matches if the match argument is zero or negative.
const Matcher isNonPositive = const _OrderingComparison(
    0, true, true, false, 'a non-positive value', false);

/// A matcher which matches if the match argument is negative.
const Matcher isNegative =
    const _OrderingComparison(0, false, true, false, 'a negative value', false);

/// A matcher which matches if the match argument is zero or positive.
const Matcher isNonNegative = const _OrderingComparison(
    0, true, false, true, 'a non-negative value', false);

bool _isNumeric(value) {
  return value is num;
}

// TODO(kevmoo) Note that matchers that use _OrderingComparison only use
// `==` and `<` operators to evaluate the match. Or change the matcher.
class _OrderingComparison extends Matcher {
  /// Expected value.
  final _value;
  /// What to return if actual == expected
  final bool _equalValue;
  /// What to return if actual < expected
  final bool _lessThanValue;
  /// What to return if actual > expected
  final bool _greaterThanValue;
  /// Textual name of the inequality
  final String _comparisonDescription;
  /// Whether to include the expected value in the description
  final bool _valueInDescription;

  const _OrderingComparison(this._value, this._equalValue, this._lessThanValue,
      this._greaterThanValue, this._comparisonDescription,
      [bool valueInDescription = true])
      : this._valueInDescription = valueInDescription;

  bool matches(item, Map matchState) {
    if (item == _value) {
      return _equalValue;
    } else if (item < _value) {
      return _lessThanValue;
    } else {
      return _greaterThanValue;
    }
  }

  Description describe(Description description) {
    if (_valueInDescription) {
      return description
          .add(_comparisonDescription)
          .add(' ')
          .addDescriptionOf(_value);
    } else {
      return description.add(_comparisonDescription);
    }
  }

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    mismatchDescription.add('is not ');
    return describe(mismatchDescription);
  }
}

/// Returns a matcher which matches if the match argument is within [delta]
/// of some [value].
///
/// In other words, this matches if the match argument is greater than
/// than or equal [value]-[delta] and less than or equal to [value]+[delta].
Matcher closeTo(num value, num delta) => new _IsCloseTo(value, delta);

class _IsCloseTo extends Matcher {
  final num _value, _delta;

  const _IsCloseTo(this._value, this._delta);

  bool matches(item, Map matchState) {
    if (!_isNumeric(item)) {
      return false;
    }
    var diff = item - _value;
    if (diff < 0) diff = -diff;
    return (diff <= _delta);
  }

  Description describe(Description description) => description
      .add('a numeric value within ')
      .addDescriptionOf(_delta)
      .add(' of ')
      .addDescriptionOf(_value);

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is! num) {
      return mismatchDescription.add(' not numeric');
    } else {
      var diff = item - _value;
      if (diff < 0) diff = -diff;
      return mismatchDescription.add(' differs by ').addDescriptionOf(diff);
    }
  }
}

/// Returns a matcher which matches if the match argument is greater
/// than or equal to [low] and less than or equal to [high].
Matcher inInclusiveRange(num low, num high) =>
    new _InRange(low, high, true, true);

/// Returns a matcher which matches if the match argument is greater
/// than [low] and less than [high].
Matcher inExclusiveRange(num low, num high) =>
    new _InRange(low, high, false, false);

/// Returns a matcher which matches if the match argument is greater
/// than [low] and less than or equal to [high].
Matcher inOpenClosedRange(num low, num high) =>
    new _InRange(low, high, false, true);

/// Returns a matcher which matches if the match argument is greater
/// than or equal to a [low] and less than [high].
Matcher inClosedOpenRange(num low, num high) =>
    new _InRange(low, high, true, false);

class _InRange extends Matcher {
  final num _low, _high;
  final bool _lowMatchValue, _highMatchValue;

  const _InRange(
      this._low, this._high, this._lowMatchValue, this._highMatchValue);

  bool matches(value, Map matchState) {
    if (value is! num) {
      return false;
    }
    if (value < _low || value > _high) {
      return false;
    }
    if (value == _low) {
      return _lowMatchValue;
    }
    if (value == _high) {
      return _highMatchValue;
    }
    return true;
  }

  Description describe(Description description) => description.add(
      "be in range from "
      "$_low (${_lowMatchValue ? 'inclusive' : 'exclusive'}) to "
      "$_high (${_highMatchValue ? 'inclusive' : 'exclusive'})");

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is! num) {
      return mismatchDescription.addDescriptionOf(item).add(' not numeric');
    } else {
      return super.describeMismatch(
          item, mismatchDescription, matchState, verbose);
    }
  }
}
