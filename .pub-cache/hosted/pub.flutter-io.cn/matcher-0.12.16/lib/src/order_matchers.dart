// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'interfaces.dart';

/// Returns a matcher which matches if the match argument is greater
/// than the given [value].
Matcher greaterThan(Object value) =>
    _OrderingMatcher(value, false, false, true, 'a value greater than');

/// Returns a matcher which matches if the match argument is greater
/// than or equal to the given [value].
Matcher greaterThanOrEqualTo(Object value) => _OrderingMatcher(
    value, true, false, true, 'a value greater than or equal to');

/// Returns a matcher which matches if the match argument is less
/// than the given [value].
Matcher lessThan(Object value) =>
    _OrderingMatcher(value, false, true, false, 'a value less than');

/// Returns a matcher which matches if the match argument is less
/// than or equal to the given [value].
Matcher lessThanOrEqualTo(Object value) =>
    _OrderingMatcher(value, true, true, false, 'a value less than or equal to');

/// A matcher which matches if the match argument is zero.
const Matcher isZero =
    _OrderingMatcher(0, true, false, false, 'a value equal to');

/// A matcher which matches if the match argument is non-zero.
const Matcher isNonZero =
    _OrderingMatcher(0, false, true, true, 'a value not equal to');

/// A matcher which matches if the match argument is positive.
const Matcher isPositive =
    _OrderingMatcher(0, false, false, true, 'a positive value', false);

/// A matcher which matches if the match argument is zero or negative.
const Matcher isNonPositive =
    _OrderingMatcher(0, true, true, false, 'a non-positive value', false);

/// A matcher which matches if the match argument is negative.
const Matcher isNegative =
    _OrderingMatcher(0, false, true, false, 'a negative value', false);

/// A matcher which matches if the match argument is zero or positive.
const Matcher isNonNegative =
    _OrderingMatcher(0, true, false, true, 'a non-negative value', false);

// TODO(kevmoo) Note that matchers that use _OrderingComparison only use
// `==` and `<` operators to evaluate the match. Or change the matcher.
class _OrderingMatcher extends Matcher {
  /// Expected value.
  final Object _value;

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

  const _OrderingMatcher(this._value, this._equalValue, this._lessThanValue,
      this._greaterThanValue, this._comparisonDescription,
      [bool valueInDescription = true])
      : _valueInDescription = valueInDescription;

  @override
  bool matches(Object? item, Map matchState) {
    if (item == _value) {
      return _equalValue;
    } else if ((item as dynamic) < _value) {
      return _lessThanValue;
    } else if (item > _value) {
      return _greaterThanValue;
    } else {
      return false;
    }
  }

  @override
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

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    mismatchDescription.add('is not ');
    return describe(mismatchDescription);
  }
}
