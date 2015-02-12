// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_trace;

import 'frame.dart';
import 'utils.dart';

/// An implementation of [StackTrace] that emulates the behavior of the VM's
/// implementation.
///
/// In particular, when [toString] is called, this returns a string in the VM's
/// stack trace format.
class VMTrace implements StackTrace {
  /// The stack frames that comprise this stack trace.
  final List<Frame> frames;

  VMTrace(this.frames);

  String toString() {
    var i = 1;
    return frames.map((frame) {
      var number = padRight("#${i++}", 8);
      var member = frame.member.replaceAll("<fn>", "<anonymous closure>");
      var line = frame.line == null ? 0 : frame.line;
      var column = frame.column == null ? 0 : frame.column;
      return "$number$member (${frame.uri}:$line:$column)\n";
    }).join();
  }
}
