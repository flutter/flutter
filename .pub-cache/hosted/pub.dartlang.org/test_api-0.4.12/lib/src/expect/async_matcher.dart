// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';
import 'package:test_api/hooks.dart';

import 'expect.dart';

/// A matcher that does asynchronous computation.
///
/// Rather than implementing [matches], subclasses implement [matchAsync].
/// [AsyncMatcher.matches] ensures that the test doesn't complete until the
/// returned future completes, and [expect] returns a future that completes when
/// the returned future completes so that tests can wait for it.
abstract class AsyncMatcher extends Matcher {
  const AsyncMatcher();

  /// Returns `null` if this matches [item], or a [String] description of the
  /// failure if it doesn't match.
  ///
  /// This can return a [Future] or a synchronous value. If it returns a
  /// [Future], neither [expect] nor the test will complete until that [Future]
  /// completes.
  ///
  /// If this returns a [String] synchronously, [expect] will synchronously
  /// throw a [TestFailure] and [matches] will synchronously return `false`.
  dynamic /*FutureOr<String>*/ matchAsync(item);

  @override
  bool matches(item, Map matchState) {
    final result = matchAsync(item);
    expect(result,
        anyOf([equals(null), TypeMatcher<Future>(), TypeMatcher<String>()]),
        reason: 'matchAsync() may only return a String, a Future, or null.');

    if (result is Future) {
      final outstandingWork = TestHandle.current.markPending();
      result.then((realResult) {
        if (realResult != null) {
          fail(formatFailure(this, item, realResult as String));
        }
        outstandingWork.complete();
      });
    } else if (result is String) {
      matchState[this] = result;
      return false;
    }

    return true;
  }

  @override
  Description describeMismatch(item, Description mismatchDescription,
          Map matchState, bool verbose) =>
      StringDescription(matchState[this] as String);
}
