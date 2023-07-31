// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'interfaces.dart';
import 'util.dart';

/// Returns a matcher that inverts [valueOrMatcher] to its logical negation.
Matcher isNot(Object? valueOrMatcher) => _IsNot(wrapMatcher(valueOrMatcher));

class _IsNot extends Matcher {
  final Matcher _matcher;

  const _IsNot(this._matcher);

  @override
  bool matches(dynamic item, Map matchState) =>
      !_matcher.matches(item, matchState);

  @override
  Description describe(Description description) =>
      description.add('not ').addDescriptionOf(_matcher);
}

/// This returns a matcher that matches if all of the matchers passed as
/// arguments (up to 7) match.
///
/// Instead of passing the matchers separately they can be passed as a single
/// List argument. Any argument that is not a matcher is implicitly wrapped in a
/// Matcher to check for equality.
Matcher allOf(Object? arg0,
    [Object? arg1,
    Object? arg2,
    Object? arg3,
    Object? arg4,
    Object? arg5,
    Object? arg6]) {
  return _AllOf(_wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
}

class _AllOf extends Matcher {
  final List<Matcher> _matchers;

  const _AllOf(this._matchers);

  @override
  bool matches(dynamic item, Map matchState) {
    for (var matcher in _matchers) {
      if (!matcher.matches(item, matchState)) {
        addStateInfo(matchState, {'matcher': matcher});
        return false;
      }
    }
    return true;
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    var matcher = matchState['matcher'];
    matcher.describeMismatch(
        item, mismatchDescription, matchState['state'], verbose);
    return mismatchDescription;
  }

  @override
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
Matcher anyOf(Object? arg0,
    [Object? arg1,
    Object? arg2,
    Object? arg3,
    Object? arg4,
    Object? arg5,
    Object? arg6]) {
  return _AnyOf(_wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
}

class _AnyOf extends Matcher {
  final List<Matcher> _matchers;

  const _AnyOf(this._matchers);

  @override
  bool matches(dynamic item, Map matchState) {
    for (var matcher in _matchers) {
      if (matcher.matches(item, matchState)) {
        return true;
      }
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.addAll('(', ' or ', ')', _matchers);
}

List<Matcher> _wrapArgs(Object? arg0, Object? arg1, Object? arg2, Object? arg3,
    Object? arg4, Object? arg5, Object? arg6) {
  Iterable args;
  if (arg0 is List) {
    if (arg1 != null ||
        arg2 != null ||
        arg3 != null ||
        arg4 != null ||
        arg5 != null ||
        arg6 != null) {
      throw ArgumentError('If arg0 is a List, all other arguments must be'
          ' null.');
    }

    args = arg0;
  } else {
    args = [arg0, arg1, arg2, arg3, arg4, arg5, arg6].where((e) => e != null);
  }

  return args.map(wrapMatcher).toList();
}
