// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Inserts the given arguments into [pattern].
///
///     format('Hello, {0}!', 'John') = 'Hello, John!'
///     format('{0} are you {1}ing?', 'How', 'do') = 'How are you doing?'
///     format('{0} are you {1}ing?', 'What', 'read') = 'What are you reading?'
String format(String pattern,
    [Object? arg0,
    Object? arg1,
    Object? arg2,
    Object? arg3,
    Object? arg4,
    Object? arg5,
    Object? arg6,
    Object? arg7]) {
  // TODO(rnystrom): This is not used by analyzer, but is called by
  // analysis_server. Move this code there and remove it from here.
  return formatList(pattern, [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7]);
}

/// Inserts the given [arguments] into [pattern].
///
///     format('Hello, {0}!', ['John']) = 'Hello, John!'
///     format('{0} are you {1}ing?', ['How', 'do']) = 'How are you doing?'
///     format('{0} are you {1}ing?', ['What', 'read']) =
///         'What are you reading?'
String formatList(String pattern, List<Object?>? arguments) {
  if (arguments == null || arguments.isEmpty) {
    assert(!pattern.contains(RegExp(r'\{(\d+)\}')),
        'Message requires arguments, but none were provided.');
    return pattern;
  }
  return pattern.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
    String indexStr = match.group(1)!;
    int index = int.parse(indexStr);
    return arguments[index].toString();
  });
}
