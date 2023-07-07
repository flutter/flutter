// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'feature_matcher.dart';
import 'interfaces.dart';

/// Returns a matcher which matches if the match argument is within [delta]
/// of some [value].
///
/// In other words, this matches if the match argument is greater than
/// than or equal [value]-[delta] and less than or equal to [value]+[delta].
Matcher closeTo(num value, num delta) => _IsCloseTo(value, delta);

class _IsCloseTo extends FeatureMatcher<num> {
  final num _value, _delta;

  const _IsCloseTo(this._value, this._delta);

  @override
  bool typedMatches(dynamic item, Map matchState) {
    var diff = item - _value;
    if (diff < 0) diff = -diff;
    return diff <= _delta;
  }

  @override
  Description describe(Description description) => description
      .add('a numeric value within ')
      .addDescriptionOf(_delta)
      .add(' of ')
      .addDescriptionOf(_value);

  @override
  Description describeTypedMismatch(dynamic item,
      Description mismatchDescription, Map matchState, bool verbose) {
    var diff = item - _value;
    if (diff < 0) diff = -diff;
    return mismatchDescription.add(' differs by ').addDescriptionOf(diff);
  }
}

/// Returns a matcher which matches if the match argument is greater
/// than or equal to [low] and less than or equal to [high].
Matcher inInclusiveRange(num low, num high) => _InRange(low, high, true, true);

/// Returns a matcher which matches if the match argument is greater
/// than [low] and less than [high].
Matcher inExclusiveRange(num low, num high) =>
    _InRange(low, high, false, false);

/// Returns a matcher which matches if the match argument is greater
/// than [low] and less than or equal to [high].
Matcher inOpenClosedRange(num low, num high) =>
    _InRange(low, high, false, true);

/// Returns a matcher which matches if the match argument is greater
/// than or equal to a [low] and less than [high].
Matcher inClosedOpenRange(num low, num high) =>
    _InRange(low, high, true, false);

class _InRange extends FeatureMatcher<num> {
  final num _low, _high;
  final bool _lowMatchValue, _highMatchValue;

  const _InRange(
      this._low, this._high, this._lowMatchValue, this._highMatchValue);

  @override
  bool typedMatches(dynamic value, Map matchState) {
    if (value < _low || value > _high) {
      return false;
    }
    if (value == _low) {
      return _lowMatchValue;
    }
    if (value == _high) {
      return _highMatchValue;
    }
    // Value may still be outside if range if it can't be compared.
    return value > _low && value < _high;
  }

  @override
  Description describe(Description description) =>
      description.add('be in range from '
          "$_low (${_lowMatchValue ? 'inclusive' : 'exclusive'}) to "
          "$_high (${_highMatchValue ? 'inclusive' : 'exclusive'})");
}
