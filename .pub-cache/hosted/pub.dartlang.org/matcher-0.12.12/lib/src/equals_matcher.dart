// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'feature_matcher.dart';
import 'interfaces.dart';
import 'util.dart';

/// Returns a matcher that matches if the value is structurally equal to
/// [expected].
///
/// If [expected] is a [Matcher], then it matches using that. Otherwise it tests
/// for equality using `==` on the expected value.
///
/// For [Iterable]s and [Map]s, this will recursively match the elements. To
/// handle cyclic structures a recursion depth [limit] can be provided. The
/// default limit is 100. [Set]s will be compared order-independently.
Matcher equals(Object? expected, [int limit = 100]) => expected is String
    ? _StringEqualsMatcher(expected)
    : _DeepMatcher(expected, limit);

typedef _RecursiveMatcher = _Mismatch? Function(Object?, Object?, String, int);

/// A special equality matcher for strings.
class _StringEqualsMatcher extends FeatureMatcher<String> {
  final String _value;

  _StringEqualsMatcher(this._value);

  @override
  bool typedMatches(String item, Map matchState) => _value == item;

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_value);

  @override
  Description describeTypedMismatch(String item,
      Description mismatchDescription, Map matchState, bool verbose) {
    var buff = StringBuffer();
    buff.write('is different.');
    var escapedItem = escape(item);
    var escapedValue = escape(_value);
    var minLength = escapedItem.length < escapedValue.length
        ? escapedItem.length
        : escapedValue.length;
    var start = 0;
    for (; start < minLength; start++) {
      if (escapedValue.codeUnitAt(start) != escapedItem.codeUnitAt(start)) {
        break;
      }
    }
    if (start == minLength) {
      if (escapedValue.length < escapedItem.length) {
        buff.write(' Both strings start the same, but the actual value also'
            ' has the following trailing characters: ');
        _writeTrailing(buff, escapedItem, escapedValue.length);
      } else {
        buff.write(' Both strings start the same, but the actual value is'
            ' missing the following trailing characters: ');
        _writeTrailing(buff, escapedValue, escapedItem.length);
      }
    } else {
      buff.write('\nExpected: ');
      _writeLeading(buff, escapedValue, start);
      _writeTrailing(buff, escapedValue, start);
      buff.write('\n  Actual: ');
      _writeLeading(buff, escapedItem, start);
      _writeTrailing(buff, escapedItem, start);
      buff.write('\n          ');
      for (var i = start > 10 ? 14 : start; i > 0; i--) {
        buff.write(' ');
      }
      buff.write('^\n Differ at offset $start');
    }

    return mismatchDescription.add(buff.toString());
  }

  static void _writeLeading(StringBuffer buff, String s, int start) {
    if (start > 10) {
      buff.write('... ');
      buff.write(s.substring(start - 10, start));
    } else {
      buff.write(s.substring(0, start));
    }
  }

  static void _writeTrailing(StringBuffer buff, String s, int start) {
    if (start + 10 > s.length) {
      buff.write(s.substring(start));
    } else {
      buff.write(s.substring(start, start + 10));
      buff.write(' ...');
    }
  }
}

class _DeepMatcher extends Matcher {
  final Object? _expected;
  final int _limit;

  _DeepMatcher(this._expected, [int limit = 1000]) : _limit = limit;

  _Mismatch? _compareIterables(Iterable expected, Object? actual,
      _RecursiveMatcher matcher, int depth, String location) {
    if (actual is Iterable) {
      var expectedIterator = expected.iterator;
      var actualIterator = actual.iterator;
      for (var index = 0;; index++) {
        // Advance in lockstep.
        var expectedNext = expectedIterator.moveNext();
        var actualNext = actualIterator.moveNext();

        // If we reached the end of both, we succeeded.
        if (!expectedNext && !actualNext) return null;

        // Fail if their lengths are different.
        var newLocation = '$location[$index]';
        if (!expectedNext) {
          return _Mismatch.simple(newLocation, actual, 'longer than expected');
        }
        if (!actualNext) {
          return _Mismatch.simple(newLocation, actual, 'shorter than expected');
        }

        // Match the elements.
        var rp = matcher(expectedIterator.current, actualIterator.current,
            newLocation, depth);
        if (rp != null) return rp;
      }
    } else {
      return _Mismatch.simple(location, actual, 'is not Iterable');
    }
  }

  _Mismatch? _compareSets(Set expected, Object? actual,
      _RecursiveMatcher matcher, int depth, String location) {
    if (actual is Iterable) {
      var other = actual.toSet();

      for (var expectedElement in expected) {
        if (other.every((actualElement) =>
            matcher(expectedElement, actualElement, location, depth) != null)) {
          return _Mismatch(
              location,
              actual,
              (description, verbose) => description
                  .add('does not contain ')
                  .addDescriptionOf(expectedElement));
        }
      }

      if (other.length > expected.length) {
        return _Mismatch.simple(location, actual, 'larger than expected');
      } else if (other.length < expected.length) {
        return _Mismatch.simple(location, actual, 'smaller than expected');
      } else {
        return null;
      }
    } else {
      return _Mismatch.simple(location, actual, 'is not Iterable');
    }
  }

  _Mismatch? _recursiveMatch(
      Object? expected, Object? actual, String location, int depth) {
    // If the expected value is a matcher, try to match it.
    if (expected is Matcher) {
      var matchState = {};
      if (expected.matches(actual, matchState)) return null;
      return _Mismatch(location, actual, (description, verbose) {
        var oldLength = description.length;
        expected.describeMismatch(actual, description, matchState, verbose);
        if (depth > 0 && description.length == oldLength) {
          description.add('does not match ');
          expected.describe(description);
        }
      });
    } else {
      // Otherwise, test for equality.
      try {
        if (expected == actual) return null;
      } catch (e) {
        // TODO(gram): Add a test for this case.
        return _Mismatch(
            location,
            actual,
            (description, verbose) =>
                description.add('== threw ').addDescriptionOf(e));
      }
    }

    if (depth > _limit) {
      return _Mismatch.simple(
          location, actual, 'recursion depth limit exceeded');
    }

    // If _limit is 1 we can only recurse one level into object.
    if (depth == 0 || _limit > 1) {
      if (expected is Set) {
        return _compareSets(
            expected, actual, _recursiveMatch, depth + 1, location);
      } else if (expected is Iterable) {
        return _compareIterables(
            expected, actual, _recursiveMatch, depth + 1, location);
      } else if (expected is Map) {
        if (actual is! Map) {
          return _Mismatch.simple(location, actual, 'expected a map');
        }
        var err = (expected.length == actual.length)
            ? ''
            : 'has different length and ';
        for (var key in expected.keys) {
          if (!actual.containsKey(key)) {
            return _Mismatch(
                location,
                actual,
                (description, verbose) => description
                    .add('${err}is missing map key ')
                    .addDescriptionOf(key));
          }
        }

        for (var key in actual.keys) {
          if (!expected.containsKey(key)) {
            return _Mismatch(
                location,
                actual,
                (description, verbose) => description
                    .add('${err}has extra map key ')
                    .addDescriptionOf(key));
          }
        }

        for (var key in expected.keys) {
          var rp = _recursiveMatch(
              expected[key], actual[key], "$location['$key']", depth + 1);
          if (rp != null) return rp;
        }

        return null;
      }
    }

    // If we have recursed, show the expected value too; if not, expect() will
    // show it for us.
    if (depth > 0) {
      return _Mismatch(location, actual,
          (description, verbose) => description.addDescriptionOf(expected),
          instead: true);
    } else {
      return _Mismatch(location, actual, null);
    }
  }

  @override
  bool matches(Object? actual, Map matchState) {
    var mismatch = _recursiveMatch(_expected, actual, '', 0);
    if (mismatch == null) return true;
    addStateInfo(matchState, {'mismatch': mismatch});
    return false;
  }

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map matchState, bool verbose) {
    var mismatch = matchState['mismatch'] as _Mismatch;
    var describeProblem = mismatch.describeProblem;
    if (mismatch.location.isNotEmpty) {
      mismatchDescription
          .add('at location ')
          .add(mismatch.location)
          .add(' is ')
          .addDescriptionOf(mismatch.actual);
      if (describeProblem != null) {
        mismatchDescription
            .add(' ${mismatch.instead ? 'instead of' : 'which'} ');
        describeProblem(mismatchDescription, verbose);
      }
    } else {
      // If we didn't get a good reason, that would normally be a
      // simple 'is <value>' message. We only add that if the mismatch
      // description is non empty (so we are supplementing the mismatch
      // description).
      if (describeProblem == null) {
        if (mismatchDescription.length > 0) {
          mismatchDescription.add('is ').addDescriptionOf(item);
        }
      } else {
        describeProblem(mismatchDescription, verbose);
      }
    }
    return mismatchDescription;
  }
}

class _Mismatch {
  /// A human-readable description of the location within the collection where
  /// the mismatch occurred.
  final String location;

  /// The actual value found at [location].
  final Object? actual;

  /// Callback that can create a detailed description of the problem.
  final void Function(Description, bool verbose)? describeProblem;

  /// If `true`, [describeProblem] describes the expected value, so when the
  /// final mismatch description is pieced together, it will be preceded by
  /// `instead of` (e.g. `at location [2] is <3> instead of <4>`).  If `false`,
  /// [describeProblem] is a problem description from a sub-matcher, so when the
  /// final mismatch description is pieced together, it will be preceded by
  /// `which` (e.g. `at location [2] is <foo> which has length of 3`).
  final bool instead;

  _Mismatch(this.location, this.actual, this.describeProblem,
      {this.instead = false});

  _Mismatch.simple(this.location, this.actual, String problem)
      : describeProblem = ((description, verbose) => description.add(problem)),
        instead = false;
}
