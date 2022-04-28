// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:meta/meta.dart';

abstract class Stdio {
  /// Error/warning messages printed to STDERR.
  void printError(String message);

  /// Ordinary STDOUT messages.
  void printStatus(String message);

  /// Debug messages that are only printed in verbose mode.
  void printTrace(String message);

  /// Write string to STDOUT without trailing newline.
  void write(String message);

  /// Read a line of text from STDIN.
  String readLineSync();
}

/// A logger that will print out trace messages.
class VerboseStdio extends Stdio {
  VerboseStdio({
    @required this.stdout,
    @required this.stderr,
    @required this.stdin,
  }) : assert(stdout != null), assert(stderr != null), assert(stdin != null);

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
    stderr.writeln(message);
  }

  @override
  void printStatus(String message) {
    stdout.writeln(message);
  }

  @override
  void printTrace(String message) {
    stdout.writeln(message);
  }

  @override
  void write(String message) {
    stdout.write(message);
  }

  @override
  String readLineSync() {
    return stdin.readLineSync();
  }
}
