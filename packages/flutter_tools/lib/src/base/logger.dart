// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

abstract class Logger {
  bool verbose = false;

  /// Display an error level message to the user. Commands should use this if they
  /// fail in some way.
  void printError(String message, [StackTrace stackTrace]);

  /// Display normal output of the command. This should be used for things like
  /// progress messages, success messages, or just normal command output.
  void printStatus(String message);

  /// Use this for verbose tracing output. Users can turn this output on in order
  /// to help diagnose issues with the toolchain or with their setup.
  void printTrace(String message);
}

class StdoutLogger implements Logger {
  DateTime _startTime = new DateTime.now();

  bool verbose = false;

  void printError(String message, [StackTrace stackTrace]) {
    stderr.writeln(_prefix + message);
    if (stackTrace != null)
      stderr.writeln(stackTrace);
  }

  void printStatus(String message) {
    print(_prefix + message);
  }

  void printTrace(String message) {
    if (verbose)
      print('$_prefix- $message');
  }

  String get _prefix {
    if (!verbose)
      return '';
    Duration elapsed = new DateTime.now().difference(_startTime);
    return '[${elapsed.inMilliseconds.toString().padLeft(4)} ms] ';
  }
}

class BufferLogger implements Logger {
  StringBuffer _error = new StringBuffer();
  StringBuffer _status = new StringBuffer();
  StringBuffer _trace = new StringBuffer();

  bool verbose = false;

  String get errorText => _error.toString();
  String get statusText => _status.toString();
  String get traceText => _trace.toString();

  void printError(String message, [StackTrace stackTrace]) => _error.writeln(message);
  void printStatus(String message) => _status.writeln(message);
  void printTrace(String message) => _trace.writeln(message);
}
