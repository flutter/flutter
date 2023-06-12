// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'interfaces.dart';
import 'type_matcher.dart';

/// A package-private [TypeMatcher] implementation that makes it easy for
/// subclasses to validate aspects of specific types while providing consistent
/// type checking.
abstract class FeatureMatcher<T> extends TypeMatcher<T> {
  const FeatureMatcher();

  @override
  bool matches(dynamic item, Map matchState) =>
      super.matches(item, matchState) && typedMatches(item as T, matchState);

  bool typedMatches(T item, Map matchState);

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (item is T) {
      return describeTypedMismatch(
          item, mismatchDescription, matchState, verbose);
    }

    return super.describe(mismatchDescription.add('not an '));
  }

  Description describeTypedMismatch(T item, Description mismatchDescription,
          Map matchState, bool verbose) =>
      mismatchDescription;
}
