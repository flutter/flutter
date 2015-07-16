// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.throws_matcher;

import 'dart:async';

import 'expect.dart';
import 'interfaces.dart';
import 'util.dart';

/// This can be used to match two kinds of objects:
///
///   * A [Function] that throws an exception when called. The function cannot
///     take any arguments. If you want to test that a function expecting
///     arguments throws, wrap it in another zero-argument function that calls
///     the one you want to test.
///
///   * A [Future] that completes with an exception. Note that this creates an
///     asynchronous expectation. The call to `expect()` that includes this will
///     return immediately and execution will continue. Later, when the future
///     completes, the actual expectation will run.
const Matcher throws = const Throws();

/// This can be used to match two kinds of objects:
///
///   * A [Function] that throws an exception when called. The function cannot
///     take any arguments. If you want to test that a function expecting
///     arguments throws, wrap it in another zero-argument function that calls
///     the one you want to test.
///
///   * A [Future] that completes with an exception. Note that this creates an
///     asynchronous expectation. The call to `expect()` that includes this will
///     return immediately and execution will continue. Later, when the future
///     completes, the actual expectation will run.
///
/// In both cases, when an exception is thrown, this will test that the exception
/// object matches [matcher]. If [matcher] is not an instance of [Matcher], it
/// will implicitly be treated as `equals(matcher)`.
Matcher throwsA(matcher) => new Throws(wrapMatcher(matcher));

class Throws extends Matcher {
  final Matcher _matcher;

  const Throws([Matcher matcher]) : this._matcher = matcher;

  bool matches(item, Map matchState) {
    if (item is! Function && item is! Future) return false;
    if (item is Future) {
      var done = wrapAsync((fn) => fn());

      // Queue up an asynchronous expectation that validates when the future
      // completes.
      item.then((value) {
        done(() {
          fail("Expected future to fail, but succeeded with '$value'.");
        });
      }, onError: (error, trace) {
        done(() {
          if (_matcher == null) return;
          var reason;
          if (trace != null) {
            var stackTrace = trace.toString();
            stackTrace = "  ${stackTrace.replaceAll("\n", "\n  ")}";
            reason = "Actual exception trace:\n$stackTrace";
          }
          expect(error, _matcher, reason: reason);
        });
      });
      // It hasn't failed yet.
      return true;
    }

    try {
      item();
      return false;
    } catch (e, s) {
      if (_matcher == null || _matcher.matches(e, matchState)) {
        return true;
      } else {
        addStateInfo(matchState, {'exception': e, 'stack': s});
        return false;
      }
    }
  }

  Description describe(Description description) {
    if (_matcher == null) {
      return description.add("throws");
    } else {
      return description.add('throws ').addDescriptionOf(_matcher);
    }
  }

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is! Function && item is! Future) {
      return mismatchDescription.add('is not a Function or Future');
    } else if (_matcher == null || matchState['exception'] == null) {
      return mismatchDescription.add('did not throw');
    } else {
      mismatchDescription
          .add('threw ')
          .addDescriptionOf(matchState['exception']);
      if (verbose) {
        mismatchDescription.add(' at ').add(matchState['stack'].toString());
      }
      return mismatchDescription;
    }
  }
}
