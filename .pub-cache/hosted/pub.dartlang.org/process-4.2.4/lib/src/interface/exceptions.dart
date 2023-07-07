// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show ProcessException;

/// A specialized exception class for this package, so that it can throw
/// customized exceptions with more information.
class ProcessPackageException extends ProcessException {
  /// Create a const ProcessPackageException.
  ///
  /// The [executable] should be the name of the executable to be run.
  ///
  /// The optional [workingDirectory] is the directory where the command
  /// execution is attempted.
  ///
  /// The optional [arguments] is a list of the arguments to given to the
  /// executable, already separated.
  ///
  /// The optional [message] is an additional message to be included in the
  /// exception string when printed.
  ///
  /// The optional [errorCode] is the error code received when the executable
  /// was run. Zero means it ran successfully, or that no error code was
  /// available.
  ///
  /// See [ProcessException] for more information.
  const ProcessPackageException(
    String executable, {
    List<String> arguments = const <String>[],
    String message = "",
    int errorCode = 0,
    this.workingDirectory,
  }) : super(executable, arguments, message, errorCode);

  /// Creates a [ProcessPackageException] from a [ProcessException].
  factory ProcessPackageException.fromProcessException(
    ProcessException exception, {
    String? workingDirectory,
  }) {
    return ProcessPackageException(
      exception.executable,
      arguments: exception.arguments,
      message: exception.message,
      errorCode: exception.errorCode,
      workingDirectory: workingDirectory,
    );
  }

  /// The optional working directory that the command was being executed in.
  final String? workingDirectory;

  // Don't implement a toString() for this exception, since code may be
  // depending upon the format of ProcessException.toString().
}

/// An exception for when an executable is not found that was expected to be found.
class ProcessPackageExecutableNotFoundException
    extends ProcessPackageException {
  /// Creates a const ProcessPackageExecutableNotFoundException
  ///
  /// The optional [candidates] are the files matching the expected executable
  /// on the [searchPath].
  ///
  /// The optional [searchPath] is the list of directories searched for the
  /// expected executable.
  ///
  /// See [ProcessPackageException] for more information.
  const ProcessPackageExecutableNotFoundException(
    String executable, {
    List<String> arguments = const <String>[],
    String message = "",
    int errorCode = 0,
    String? workingDirectory,
    this.candidates = const <String>[],
    this.searchPath = const <String>[],
  }) : super(
          executable,
          arguments: arguments,
          message: message,
          errorCode: errorCode,
          workingDirectory: workingDirectory,
        );

  /// The list of non-viable executable candidates found.
  final List<String> candidates;

  /// The search path used to find candidates.
  final List<String> searchPath;

  @override
  String toString() {
    StringBuffer buffer = StringBuffer('$runtimeType: $message\n');
    // Don't add an extra space if there are no arguments.
    final String args = arguments.isNotEmpty ? ' ${arguments.join(' ')}' : '';
    buffer.writeln('  Command: $executable$args');
    if (workingDirectory != null && workingDirectory!.isNotEmpty) {
      buffer.writeln('  Working Directory: $workingDirectory');
    }
    if (candidates.isNotEmpty) {
      buffer.writeln('  Candidates:\n    ${candidates.join('\n    ')}');
    }
    buffer.writeln('  Search Path:\n    ${searchPath.join('\n    ')}');
    return buffer.toString();
  }
}
