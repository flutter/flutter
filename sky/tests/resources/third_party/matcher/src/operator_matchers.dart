// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.operator_matchers;

import 'interfaces.dart';
import 'util.dart';

/// This returns a matcher that inverts [matcher] to its logical negation.
Matcher isNot(matcher) => new _IsNot(wrapMatcher(matcher));

class _IsNot extends Matcher {
  final Matcher _matcher;

  const _IsNot(this._matcher);

  bool matches(item, Map matchState) => !_matcher.matches(item, matchState);

  Description describe(Description description) =>
      description.add('not ').addDescriptionOf(_matcher);
}

/// This returns a matcher that matches if all of the matchers passed as
/// arguments (up to 7) match.
///
/// Instead of passing the matchers separately they can be passed as a single
/// List argument. Any argument that is not a matcher is implicitly wrapped in a
/// Matcher to check for equality.
Matcher allOf(arg0, [arg1, arg2, arg3, arg4, arg5, arg6]) {
  return new _AllOf(_wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
}

class _AllOf extends Matcher {
  final List<Matcher> _matchers;

  const _AllOf(this._matchers);

  bool matches(item, Map matchState) {
    for (var matcher in _matchers) {
      if (!matcher.matches(item, matchState)) {
        addStateInfo(matchState, {'matcher': matcher});
        return false;
      }
    }
    return true;
  }

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    var matcher = matchState['matcher'];
    matcher.describeMismatch(
        item, mismatchDescription, matchState['state'], verbose);
    return mismatchDescription;
  }

  Description describe(Description description) =>
      description.addAll('(', ' and ', ')', _matchers);
}

/// Matches if any of the given matchers evaluate to true.
///
/// The arguments can be a set of matchers as separate parameters
/// (up to 7), or a List of matchers.
///
/// The matchers are evaluated from left to right using short-circuit
/// evaluation, so evaluation stops as soon as a matcher returns true.
///
/// Any argument that is not a matcher is implicitly wrapped in a
/// Matcher to check for equality.
Matcher anyOf(arg0, [arg1, arg2, arg3, arg4, arg5, arg6]) {
  return new _AnyOf(_wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
}

class _AnyOf extends Matcher {
  final List<Matcher> _matchers;

  const _AnyOf(this._matchers);

  bool matches(item, Map matchState) {
    for (var matcher in _matchers) {
      if (matcher.matches(item, matchState)) {
        return true;
      }
    }
    return false;
  }

  Description describe(Description description) =>
      description.addAll('(', ' or ', ')', _matchers);
}

List<Matcher> _wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
  Iterable<Matcher> matchers;
  if (arg0 is List) {
    if (arg1 != null ||
        arg2 != null ||
        arg3 != null ||
        arg4 != null ||
        arg5 != null ||
        arg6 != null) {
      throw new ArgumentError('If arg0 is a List, all other arguments must be'
          ' null.');
    }

    matchers = arg0;
  } else {
    matchers =
        [arg0, arg1, arg2, arg3, arg4, arg5, arg6].where((e) => e != null);
  }

  return matchers.map((e) => wrapMatcher(e)).toList();
}
