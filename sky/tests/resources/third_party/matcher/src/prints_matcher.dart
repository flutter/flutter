// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.prints_matcher;

import 'dart:async';

import 'description.dart';
import 'expect.dart';
import 'interfaces.dart';
import 'future_matchers.dart';
import 'util.dart';

/// Matches a [Function] that prints text that matches [matcher].
///
/// [matcher] may be a String or a [Matcher].
///
/// If the function this runs against returns a [Future], all text printed by
/// the function (using [Zone] scoping) until that Future completes is matched.
///
/// This only tracks text printed using the [print] function.
Matcher prints(matcher) => new _Prints(wrapMatcher(matcher));

class _Prints extends Matcher {
  final Matcher _matcher;

  _Prints(this._matcher);

  bool matches(item, Map matchState) {
    if (item is! Function) return false;

    var buffer = new StringBuffer();
    var result = runZoned(item,
        zoneSpecification: new ZoneSpecification(print: (_, __, ____, line) {
      buffer.writeln(line);
    }));

    if (result is! Future) {
      var actual = buffer.toString();
      matchState['prints.actual'] = actual;
      return _matcher.matches(actual, matchState);
    }

    return completes.matches(result.then(wrapAsync((_) {
      expect(buffer.toString(), _matcher);
    }, 'prints')), matchState);
  }

  Description describe(Description description) =>
      description.add('prints ').addDescriptionOf(_matcher);

  Description describeMismatch(
      item, Description description, Map matchState, bool verbose) {
    var actual = matchState.remove('prints.actual');
    if (actual == null) return description;
    if (actual.isEmpty) return description.add("printed nothing.");

    description.add('printed ').addDescriptionOf(actual);

    // Create a new description for the matcher because at least
    // [_StringEqualsMatcher] replaces the previous contents of the description.
    var innerMismatch = _matcher
        .describeMismatch(actual, new StringDescription(), matchState, verbose)
        .toString();

    if (innerMismatch.isNotEmpty) {
      description.add('\n   Which: ').add(innerMismatch.toString());
    }

    return description;
  }
}
