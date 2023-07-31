// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'custom_matcher.dart';
import 'interfaces.dart';
import 'type_matcher.dart';
import 'util.dart';

/// A package-private [TypeMatcher] implementation that handles is returned
/// by calls to [TypeMatcher.having].
class HavingMatcher<T> implements TypeMatcher<T> {
  final TypeMatcher<T> _parent;
  final List<_FunctionMatcher<T>> _functionMatchers;

  HavingMatcher(this._parent, String description, Object? Function(T) feature,
      dynamic matcher)
      : _functionMatchers = [
          _FunctionMatcher<T>(description, feature, matcher)
        ];

  HavingMatcher._fromExisting(
      this._parent,
      String description,
      Object? Function(T) feature,
      dynamic matcher,
      Iterable<_FunctionMatcher<T>>? existing)
      : _functionMatchers = [
          ...?existing,
          _FunctionMatcher<T>(description, feature, matcher)
        ];

  @override
  TypeMatcher<T> having(
          Object? Function(T) feature, String description, dynamic matcher) =>
      HavingMatcher._fromExisting(
          _parent, description, feature, matcher, _functionMatchers);

  @override
  bool matches(dynamic item, Map matchState) {
    for (var matcher in <Matcher>[_parent].followedBy(_functionMatchers)) {
      if (!matcher.matches(item, matchState)) {
        addStateInfo(matchState, {'matcher': matcher});
        return false;
      }
    }
    return true;
  }

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map matchState, bool verbose) {
    var matcher = matchState['matcher'] as Matcher;
    matcher.describeMismatch(
        item, mismatchDescription, matchState['state'] as Map, verbose);
    return mismatchDescription;
  }

  @override
  Description describe(Description description) => description
      .add('')
      .addDescriptionOf(_parent)
      .add(' with ')
      .addAll('', ' and ', '', _functionMatchers);
}

class _FunctionMatcher<T> extends CustomMatcher {
  final Object? Function(T value) _feature;

  _FunctionMatcher(String name, this._feature, Object? matcher)
      : super('`$name`:', '`$name`', matcher);

  @override
  Object? featureValueOf(covariant T actual) => _feature(actual);
}
