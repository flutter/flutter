// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.utils;

import '../../stack_trace/stack_trace.dart';

/// Indent each line in [str] by two spaces.
String indent(String str) =>
    str.replaceAll(new RegExp("^", multiLine: true), "  ");

/// A pair of values.
class Pair<E, F> {
  final E first;
  final F last;

  Pair(this.first, this.last);

  String toString() => '($first, $last)';

  bool operator ==(other) {
    if (other is! Pair) return false;
    return other.first == first && other.last == last;
  }

  int get hashCode => first.hashCode ^ last.hashCode;
}

/// Returns a Trace object from a StackTrace object or a String, or the
/// unchanged input if formatStacks is false;
Trace getTrace(stack, bool formatStacks, bool filterStacks) {
  Trace trace;
  if (stack == null || !formatStacks) return null;
  if (stack is String) {
    trace = new Trace.parse(stack);
  } else if (stack is StackTrace) {
    trace = new Trace.from(stack);
  } else {
    throw new Exception('Invalid stack type ${stack.runtimeType} for $stack.');
  }

  if (!filterStacks) return trace;

  // Format the stack trace by removing everything above TestCase._runTest,
  // which is usually going to be irrelevant. Also fold together unittest and
  // core library calls so only the function the user called is visible.
  return new Trace(trace.frames.takeWhile((frame) {
    return frame.package != 'unittest' || frame.member != 'TestCase._runTest';
  })).terse.foldFrames((frame) => frame.package == 'unittest' || frame.isCore);
}
