// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stack_trace/stack_trace.dart' as stack;

/// Returns whether this URI has a scheme that can be resolved to a file path
/// via the VM Service.
bool isResolvableUri(Uri uri) {
  return !uri.isScheme('file') &&
      // Parsed stack frames may have URIs with no scheme and the text
      // "unparsed" if they looked like stack frames but had no file
      // information.
      !uri.isScheme('');
}

/// Attempts to parse a line as a stack frame in order to read path/line/col
/// information.
///
/// It should not be assumed that if a [stack.Frame] is returned that the input
/// was necessarily a stack frame or that calling `toString` will return the
/// original input text.
stack.Frame? parseStackFrame(String line) {
  // Because we split on \n, on Windows there may be trailing \r which prevents
  // package:stack_trace from parsing correctly.
  line = line.trim();

  /// Helper to try parsing a frame with [parser], returning `null` if it
  /// fails to parse.
  stack.Frame? tryParseFrame(stack.Frame Function(String) parser) {
    final frame = parser(line);
    return frame is stack.UnparsedFrame ? null : frame;
  }

  // Try different formats of stack frames.
  // pkg:stack_trace does not have a generic Frame.parse() and Trace.parse()
  // doesn't work well when the content includes non-stack-frame lines
  // (https://github.com/dart-lang/stack_trace/issues/115).
  return tryParseFrame((line) => stack.Frame.parseVM(line)) ??
      // TODO(dantup): Tidy up when constructor tear-offs are available.
      tryParseFrame((line) => stack.Frame.parseV8(line)) ??
      tryParseFrame((line) => stack.Frame.parseSafari(line)) ??
      tryParseFrame((line) => stack.Frame.parseFirefox(line)) ??
      tryParseFrame((line) => stack.Frame.parseIE(line)) ??
      tryParseFrame((line) => stack.Frame.parseFriendly(line));
}
