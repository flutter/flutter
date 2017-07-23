// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// Performs an action and returns either the result of the action or a [Future]
/// that evaluates to the result.
typedef dynamic Action();

/// Determines if [value] is acceptable. For good style an implementation should
/// be idempotent.
typedef bool Predicate(dynamic value);

/// Performs [action] repeatedly until it either succeeds or [timeout] limit is
/// reached.
///
/// When the retry time out, the last seen error and stack trace are returned in
/// an error [Future].
Future<dynamic> retry(
  Action action,
  Duration timeout,
  Duration pauseBetweenRetries, {
  Predicate predicate,
}) async {
  assert(action != null);
  assert(timeout != null);
  assert(pauseBetweenRetries != null);

  final Stopwatch sw = stopwatchFactory()..start();
  dynamic result;
  dynamic lastError;
  dynamic lastStackTrace;
  bool success = false;

  while (!success && sw.elapsed < timeout) {
    try {
      result = await action();
      if (predicate == null || predicate(result))
        success = true;
      lastError = null;
      lastStackTrace = null;
    } catch(error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
    }

    if (!success && sw.elapsed < timeout)
      await new Future<Null>.delayed(pauseBetweenRetries);
  }

  if (success)
    return result;
  else if (lastError != null)
    return new Future<Null>.error(lastError, lastStackTrace);
  else
    return new Future<Null>.error('Retry timed out');
}

/// A function that produces a [Stopwatch].
typedef Stopwatch StopwatchFactory();

/// Restores [stopwatchFactory] to the default implementation.
void restoreStopwatchFactory() {
  stopwatchFactory = () => new Stopwatch();
}

/// Used by [retry] as a source of [Stopwatch] implementation.
StopwatchFactory stopwatchFactory = () => new Stopwatch();
