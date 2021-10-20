// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:meta/meta.dart';

abstract class Stdio {
  final List<String> logs = <String>[];

  /// Error messages printed to STDERR.
  ///
  /// Display an error `message` to the user on stderr. Print errors if the code
  /// fails in some way. Errors are typically followed shortly by exiting the
  /// app with a non-zero exit status.
  @mustCallSuper
  void printError(String message) {
    logs.add('[error] $message');
  }

  /// Warning messages printed to STDERR.
  ///
  /// Display a warning `message` to the user on stderr. Print warnings if there
  /// is important information to convey to the user that is not fatal.
  @mustCallSuper
  void printWarning(String message) {
    logs.add('[warning] $message');
  }

  /// Ordinary STDOUT messages.
  ///
  /// Displays normal output on stdout. This should be used for things like
  /// progress messages, success messages, or just normal command output.
  @mustCallSuper
  void printStatus(String message) {
    logs.add('[status] $message');
  }

  /// Debug messages that are only printed in verbose mode.
  ///
  /// Use this for verbose tracing output. Users can turn this output on in order
  /// to help diagnose issues.
  @mustCallSuper
  void printTrace(String message) {
    logs.add('[trace] $message');
  }

  /// Write the `message` string to STDOUT without a trailing newline.
  @mustCallSuper
  void write(String message) {
    logs.add('[write] $message');
  }

  /// Read a line of text from STDIN.
  String readLineSync();
}

/// A logger that will print out trace messages.
class VerboseStdio extends Stdio {
  VerboseStdio({
    required this.stdout,
    required this.stderr,
    required this.stdin,
  });

  factory VerboseStdio.local() => VerboseStdio(
        stdout: io.stdout,
        stderr: io.stderr,
        stdin: io.stdin,
      );

  final io.Stdout stdout;
  final io.Stdout stderr;
  final io.Stdin stdin;

  @override
  void printError(String message) {
    super.printError(message);
    stderr.writeln(message);
  }

  @override
  void printStatus(String message) {
    super.printStatus(message);
    stdout.writeln(message);
  }

  @override
  void printTrace(String message) {
    super.printTrace(message);
    stdout.writeln(message);
  }

  @override
  void write(String message) {
    super.write(message);
    stdout.write(message);
  }

  @override
  String readLineSync() {
    return stdin.readLineSync()!;
  }
}
