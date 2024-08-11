// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Prints an object to the console.
///
/// On the web, `object` is converted to a string and that string is output to
/// the web console using `console.log`.
///
/// On native (non-Web) platforms, `object` is converted to a string and that
/// string is terminated by a line feed (`'\n'`, U+000A) and written to
/// `stdout`. On Windows, the terminating line feed, and any line feeds in the
/// string representation of `object`, are output using the Windows line
/// terminator sequence of (`'\r\n'`, U+000D + U+000A).
///
/// Calls to `print` can be intercepted by [Zone.print].
void print(Object? object) {
  String line = "$object";
  var toZone = printToZone;
  if (toZone == null) {
    printToConsole(line);
  } else {
    toZone(line);
  }
}
