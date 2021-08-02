// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:meta/meta.dart';

abstract class Stdio {
  final List<String> logs = <String>[];

  /// Error/warning messages printed to STDERR.
  @mustCallSuper
  void printError(String message) {
    logs.add('[error] $message');
  }

  /// Ordinary STDOUT messages.
  @mustCallSuper
  void printStatus(String message) {
    logs.add('[status] $message');
  }

  /// Debug messages that are only printed in verbose mode.
  @mustCallSuper
  void printTrace(String message) {
    logs.add('[trace] $message');
  }

  /// Write string to STDOUT without trailing newline.
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
