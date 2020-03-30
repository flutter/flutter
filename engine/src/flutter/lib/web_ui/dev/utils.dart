// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'common.dart';
import 'environment.dart';

class FilePath {
  FilePath.fromCwd(String relativePath)
      : _absolutePath = path.absolute(relativePath);
  FilePath.fromWebUi(String relativePath)
      : _absolutePath = path.join(environment.webUiRootDir.path, relativePath);

  final String _absolutePath;

  String get absolute => _absolutePath;
  String get relativeToCwd => path.relative(_absolutePath);
  String get relativeToWebUi =>
      path.relative(_absolutePath, from: environment.webUiRootDir.path);

  @override
  bool operator ==(dynamic other) {
    return other is FilePath && _absolutePath == other._absolutePath;
  }

  @override
  String toString() => _absolutePath;
}

/// Runs [executable] merging its output into the current process' standard out and standard error.
Future<int> runProcess(
  String executable,
  List<String> arguments, {
  String workingDirectory,
  bool mustSucceed: false,
}) async {
  final io.Process process = await io.Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    // Running the process in a system shell for Windows. Otherwise
    // the process is not able to get Dart from path.
    runInShell: io.Platform.isWindows,
    mode: io.ProcessStartMode.inheritStdio,
  );
  final int exitCode = await process.exitCode;
  if (mustSucceed && exitCode != 0) {
    throw ProcessException(
      description: 'Sub-process failed.',
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      exitCode: exitCode,
    );
  }
  return exitCode;
}

/// Runs [executable]. Do not follow the exit code or the output.
void startProcess(
  String executable,
  List<String> arguments, {
  String workingDirectory,
  bool mustSucceed: false,
}) async {
  final io.Process process = await io.Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    // Running the process in a system shell for Windows. Otherwise
    // the process is not able to get Dart from path.
    runInShell: io.Platform.isWindows,
    mode: io.ProcessStartMode.inheritStdio,
  );
  processesToCleanUp.add(process);
}

/// Runs [executable] and returns its standard output as a string.
///
/// If the process fails, throws a [ProcessException].
Future<String> evalProcess(
  String executable,
  List<String> arguments, {
  String workingDirectory,
}) async {
  final io.ProcessResult result = await io.Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      description: result.stderr as String,
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      exitCode: result.exitCode,
    );
  }
  return result.stdout as String;
}

@immutable
class ProcessException implements Exception {
  ProcessException({
    @required this.description,
    @required this.executable,
    @required this.arguments,
    @required this.workingDirectory,
    @required this.exitCode,
  });

  final String description;
  final String executable;
  final List<String> arguments;
  final String workingDirectory;
  final int exitCode;

  @override
  String toString() {
    final StringBuffer message = StringBuffer();
    message
      ..writeln(description)
      ..writeln('Command: $executable ${arguments.join(' ')}')
      ..writeln('Working directory: ${workingDirectory ?? io.Directory.current.path}')
      ..writeln('Exit code: $exitCode');
    return '$message';
  }
}

/// Adds utility methods
mixin ArgUtils<T> on Command<T> {
  /// Extracts a boolean argument from [argResults].
  bool boolArg(String name) => argResults[name] as bool;

  /// Extracts a string argument from [argResults].
  String stringArg(String name) => argResults[name] as String;

  /// Extracts a integer argument from [argResults].
  ///
  /// If the argument value cannot be parsed as [int] throws an [ArgumentError].
  int intArg(String name) {
    final String rawValue = stringArg(name);
    if (rawValue == null) {
      return null;
    }
    final int value = int.tryParse(rawValue);
    if (value == null) {
      throw ArgumentError(
        'Argument $name should be an integer value but was "$rawValue"',
      );
    }
    return value;
  }
}
