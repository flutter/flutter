// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

final AppContext _defaultContext = new _DefaultAppContext();

/// A singleton for application functionality. This singleton can be different
/// on a per-Zone basis.
AppContext get context {
  AppContext currentContext = Zone.current['context'];
  return currentContext == null ? _defaultContext : currentContext;
}

/// Display an error level message to the user. Commands should use this if they
/// fail in some way.
void printError(String message, [StackTrace stackTrace]) => context.printError(message, stackTrace);

/// Display normal output of the command. This should be used for things like
/// progress messages, success messages, or just normal command output.
void printStatus(String message) => context.printStatus(message);

/// Use this for verbose tracing output. Users can turn this output on in order
/// to help diagnose issues with the toolchain or with their setup.
void printTrace(String message) => context.printTrace(message);

abstract class AppContext {
  bool get verbose;
  set verbose(bool value);

  void printError(String message, [StackTrace stackTrace]);
  void printStatus(String message);
  void printTrace(String message);
}

class _DefaultAppContext implements AppContext {
  DateTime _startTime = new DateTime.now();

  bool _verbose = false;

  bool get verbose => _verbose;

  set verbose(bool value) {
    _verbose = value;
  }

  void printError(String message, [StackTrace stackTrace]) {
    stderr.writeln(_prefix + message);
    if (stackTrace != null)
      stderr.writeln(stackTrace);
  }

  void printStatus(String message) {
    print(_prefix + message);
  }

  void printTrace(String message) {
    if (_verbose)
      print('$_prefix- $message');
  }

  String get _prefix {
    if (!_verbose)
      return '';
    Duration elapsed = new DateTime.now().difference(_startTime);
    return '[${elapsed.inMilliseconds.toString().padLeft(4)} ms] ';
  }
}
