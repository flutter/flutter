// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// Performs an action and returns either the result of the action or a [Future]
/// that evaluates to the result.
typedef dynamic Action();

/// Performs [action] repeatedly until it either succeeds or [timeout] limit is
/// reached.
///
/// When the retry time out, the last seen error and stack trace are returned in
/// an error [Future].
Future<dynamic> retry(Action action, Duration timeout,
    Duration pauseBetweenRetries) async {
  assert(action != null);
  assert(timeout != null);
  assert(pauseBetweenRetries != null);

  Stopwatch sw = new Stopwatch()..start();
  dynamic result = null;
  dynamic lastError = null;
  dynamic lastStackTrace = null;
  bool success = false;

  while(!success && sw.elapsed < timeout) {
    try {
      result = await action();
      success = true;
    } catch(error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (sw.elapsed < timeout) {
        await new Future<Null>.delayed(pauseBetweenRetries);
      }
    }
  }

  if (success)
    return result;
  else
    return new Future.error(lastError, lastStackTrace);
}
