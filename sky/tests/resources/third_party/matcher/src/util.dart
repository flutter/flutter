// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.util;

import 'core_matchers.dart';
import 'interfaces.dart';

/// Useful utility for nesting match states.
void addStateInfo(Map matchState, Map values) {
  var innerState = new Map.from(matchState);
  matchState.clear();
  matchState['state'] = innerState;
  matchState.addAll(values);
}

/// Takes an argument and returns an equivalent [Matcher].
///
/// If the argument is already a matcher this does nothing,
/// else if the argument is a function, it generates a predicate
/// function matcher, else it generates an equals matcher.
Matcher wrapMatcher(x) {
  if (x is Matcher) {
    return x;
  } else if (x is Function) {
    return predicate(x);
  } else {
    return equals(x);
  }
}
