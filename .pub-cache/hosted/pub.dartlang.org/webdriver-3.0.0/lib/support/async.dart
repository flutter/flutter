// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library webdriver.support.async;

import 'dart:async' show Completer, FutureOr;

import 'package:matcher/matcher.dart' as m;
import 'package:stack_trace/stack_trace.dart' show Chain;

const defaultInterval = Duration(milliseconds: 500);
const defaultTimeout = Duration(seconds: 5);

const clock = Clock();

Future<T?> waitFor<T>(FutureOr<T> Function() condition,
        {matcher,
        Duration timeout = defaultTimeout,
        Duration interval = defaultInterval}) =>
    clock.waitFor<T>(condition,
        matcher: matcher, timeout: timeout, interval: interval);

class Clock {
  const Clock();

  /// Sleep for the specified time.
  Future<void> sleep([Duration interval = defaultInterval]) =>
      Future.delayed(interval);

  /// The current time.
  DateTime get now => DateTime.now();

  /// Waits until [condition] evaluates to a value that matches [matcher] or
  /// until [timeout] time has passed. If [condition] returns a [Future], then
  /// uses the value of that [Future] rather than the value of [condition].
  ///
  /// If the wait is successful, then the matching return value of [condition]
  /// is returned. Otherwise, if [condition] throws, then that exception is
  /// rethrown. If [condition] doesn't throw then an [expect] exception is
  /// thrown.
  Future<T?> waitFor<T>(FutureOr<T>? Function() condition,
      {matcher,
      Duration timeout = defaultTimeout,
      Duration interval = defaultInterval}) async {
    var mMatcher = matcher == null ? null : m.wrapMatcher(matcher);
    var endTime = now.add(timeout);
    while (true) {
      try {
        var value = await condition();
        if (mMatcher != null) {
          _matcherExpect(value, mMatcher);
        }
        return value;
      } catch (e) {
        if (now.isAfter(endTime)) {
          rethrow;
        } else {
          await sleep(interval);
        }
      }
    }
  }
}

void _matcherExpect(value, m.Matcher matcher) {
  var matchState = {};
  if (matcher.matches(value, matchState)) {
    return;
  }
  var desc = m.StringDescription()
    ..add('Expected: ')
    ..addDescriptionOf(matcher)
    ..add('\n')
    ..add('  Actual: ')
    ..addDescriptionOf(value)
    ..add('\n');

  var mismatchDescription = m.StringDescription();
  matcher.describeMismatch(value, mismatchDescription, matchState, true);
  if (mismatchDescription.length > 0) {
    desc.add('   Which: $mismatchDescription\n');
  }
  throw Exception(desc.toString());
}

class Lock {
  Completer<void>? _lock;
  Chain? _stack;

  final bool awaitChecking;

  Lock({this.awaitChecking = false});

  Future<void> acquire() {
    if (awaitChecking) {
      if (isHeld) {
        return Future.error(StateError(
            'Maybe you missed an await? Lock is already held by:\n$_stack'));
      } else {
        _stack = Chain.current().terse;
        _lock = Completer();
        return Future.value();
      }
    } else {
      return () async {
        while (isHeld) {
          await _lock!.future;
        }
        _lock = Completer();
      }();
    }
  }

  void release() {
    if (!isHeld) {
      throw StateError('No lock to release');
    }
    _lock!.complete();
    _lock = null;
    _stack = null;
  }

  bool get isHeld => _lock != null;
}
