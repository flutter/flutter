// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'frame.dart';

/// An implementation of [StackTrace] that emulates the behavior of the VM's
/// implementation.
///
/// In particular, when [toString] is called, this returns a string in the VM's
/// stack trace format.
class VMTrace implements StackTrace {
  /// The stack frames that comprise this stack trace.
  final List<Frame> frames;

  VMTrace(this.frames);

  @override
  String toString() {
    var i = 1;
    return frames.map((frame) {
      var number = '#${i++}'.padRight(8);
      var member = frame.member!
          .replaceAllMapped(RegExp(r'[^.]+\.<async>'),
              (match) => '${match[1]}.<${match[1]}_async_body>')
          .replaceAll('<fn>', '<anonymous closure>');
      var line = frame.line ?? 0;
      var column = frame.column ?? 0;
      return '$number$member (${frame.uri}:$line:$column)\n';
    }).join();
  }
}
