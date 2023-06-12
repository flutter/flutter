// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';
import 'package:test_api/hooks.dart' show pumpEventQueue;

import 'async_matcher.dart';
import 'expect.dart';
import 'util/pretty_print.dart';

/// Matches a [Future] that completes successfully with any value.
///
/// This creates an asynchronous expectation. The call to [expect] will return
/// immediately and execution will continue. Later, when the future completes,
/// the expectation against [matcher] will run. To wait for the future to
/// complete and the expectation to run use [expectLater] and wait on the
/// returned future.
///
/// To test that a Future completes with an exception, you can use [throws] and
/// [throwsA].
final Matcher completes = const _Completes(null);

/// Matches a [Future] that completes successfully with a value that matches
/// [matcher].
///
/// This creates an asynchronous expectation. The call to [expect] will return
/// immediately and execution will continue. Later, when the future completes,
/// the expectation against [matcher] will run. To wait for the future to
/// complete and the expectation to run use [expectLater] and wait on the
/// returned future.
///
/// To test that a Future completes with an exception, you can use [throws] and
/// [throwsA].
Matcher completion(matcher,
        [@Deprecated('this parameter is ignored') String? description]) =>
    _Completes(wrapMatcher(matcher));

class _Completes extends AsyncMatcher {
  final Matcher? _matcher;

  const _Completes(this._matcher);

  // Avoid async/await so we synchronously start listening to [item].
  @override
  dynamic /*FutureOr<String>*/ matchAsync(item) {
    if (item is! Future) return 'was not a Future';

    return item.then((value) async {
      if (_matcher == null) return null;

      String? result;
      if (_matcher is AsyncMatcher) {
        result = await (_matcher as AsyncMatcher).matchAsync(value) as String?;
        if (result == null) return null;
      } else {
        var matchState = {};
        if (_matcher!.matches(value, matchState)) return null;
        result = _matcher!
            .describeMismatch(value, StringDescription(), matchState, false)
            .toString();
      }

      var buffer = StringBuffer();
      buffer.writeln(indent(prettyPrint(value), first: 'emitted '));
      if (result.isNotEmpty) buffer.writeln(indent(result, first: '  which '));
      return buffer.toString().trimRight();
    });
  }

  @override
  Description describe(Description description) {
    if (_matcher == null) {
      description.add('completes successfully');
    } else {
      description.add('completes to a value that ').addDescriptionOf(_matcher);
    }
    return description;
  }
}

/// Matches a [Future] that does not complete.
///
/// Note that this creates an asynchronous expectation. The call to
/// `expect()` that includes this will return immediately and execution will
/// continue.
final Matcher doesNotComplete = const _DoesNotComplete();

class _DoesNotComplete extends Matcher {
  const _DoesNotComplete();

  @override
  Description describe(Description description) {
    description.add('does not complete');
    return description;
  }

  @override
  bool matches(item, Map matchState) {
    if (item is! Future) return false;
    item.then((value) {
      fail('Future was not expected to complete but completed with a value of '
          '$value');
    });
    expect(pumpEventQueue(), completes);
    return true;
  }

  @override
  Description describeMismatch(
      item, Description description, Map matchState, bool verbose) {
    if (item is! Future) return description.add('$item is not a Future');
    return description;
  }
}
