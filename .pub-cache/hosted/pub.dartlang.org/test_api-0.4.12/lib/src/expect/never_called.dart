// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';
import 'package:test_api/hooks.dart';

import 'expect.dart';
import 'future_matchers.dart';
import 'util/placeholder.dart';
import 'util/pretty_print.dart';

/// Returns a function that causes the test to fail if it's called.
///
/// This can safely be passed in place of any callback that takes ten or fewer
/// positional parameters. For example:
///
/// ```
/// // Asserts that the stream never emits an event.
/// stream.listen(neverCalled);
/// ```
///
/// This also ensures that the test doesn't complete until a call to
/// [pumpEventQueue] finishes, so that the callback has a chance to be called.
Null Function(
    [Object?,
    Object?,
    Object?,
    Object?,
    Object?,
    Object?,
    Object?,
    Object?,
    Object?,
    Object?]) get neverCalled {
  // Make sure the test stays alive long enough to call the function if it's
  // going to.
  expect(pumpEventQueue(), completes);

  var zone = Zone.current;
  return (
      [a1 = placeholder,
      a2 = placeholder,
      a3 = placeholder,
      a4 = placeholder,
      a5 = placeholder,
      a6 = placeholder,
      a7 = placeholder,
      a8 = placeholder,
      a9 = placeholder,
      a10 = placeholder]) {
    var arguments = [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10]
        .where((argument) => argument != placeholder)
        .toList();

    var argsText = arguments.isEmpty
        ? ' no arguments.'
        : ':\n${bullet(arguments.map(prettyPrint))}';
    zone.handleUncaughtError(
        TestFailure(
            'Callback should never have been called, but it was called with'
            '$argsText'),
        zone.run(() => Chain.current()));
    return null;
  };
}
