// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:matcher/matcher.dart';

import 'async_matcher.dart';
import 'expect.dart';
import 'util/pretty_print.dart';

/// Matches a [Function] that prints text that matches [matcher].
///
/// [matcher] may be a String or a [Matcher].
///
/// If the function this runs against returns a [Future], all text printed by
/// the function (using [Zone] scoping) until that Future completes is matched.
///
/// This only tracks text printed using the [print] function.
///
/// This returns an [AsyncMatcher], so [expect] won't complete until the matched
/// function does.
Matcher prints(matcher) => _Prints(wrapMatcher(matcher));

class _Prints extends AsyncMatcher {
  final Matcher _matcher;

  _Prints(this._matcher);

  // Avoid async/await so we synchronously fail if the function is
  // synchronous.
  @override
  dynamic /*FutureOr<String>*/ matchAsync(item) {
    if (item is! Function()) return 'was not a unary Function';

    var buffer = StringBuffer();
    var result = runZoned(item,
        zoneSpecification: ZoneSpecification(print: (_, __, ____, line) {
      buffer.writeln(line);
    }));

    return result is Future
        ? result.then((_) => _check(buffer.toString()))
        : _check(buffer.toString());
  }

  @override
  Description describe(Description description) =>
      description.add('prints ').addDescriptionOf(_matcher);

  /// Verifies that [actual] matches [_matcher] and returns a [String]
  /// description of the failure if it doesn't.
  String? _check(String actual) {
    var matchState = {};
    if (_matcher.matches(actual, matchState)) return null;

    var result = _matcher
        .describeMismatch(actual, StringDescription(), matchState, false)
        .toString();

    var buffer = StringBuffer();
    if (actual.isEmpty) {
      buffer.writeln('printed nothing');
    } else {
      buffer.writeln(indent(prettyPrint(actual), first: 'printed '));
    }
    if (result.isNotEmpty) buffer.writeln(indent(result, first: '  which '));
    return buffer.toString().trimRight();
  }
}
