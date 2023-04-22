// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';

class LoggingLogger extends BufferLogger {
  LoggingLogger() : super.test();

  List<String> messages = <String>[];

  @override
  void printError(final String message, {final StackTrace? stackTrace, final bool? emphasis, final TerminalColor? color, final int? indent, final int? hangingIndent, final bool? wrap}) {
    messages.add(message);
  }

  @override
  void printStatus(final String message, {final bool? emphasis, final TerminalColor? color, final bool? newline, final int? indent, final int? hangingIndent, final bool? wrap}) {
    messages.add(message);
  }

  @override
  void printTrace(final String message) {
    messages.add(message);
  }
}
