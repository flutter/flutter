// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:process/process.dart';

/// Matches only strings that a shell will always parse as a single literal word.
///
/// Some strings that a shell would in fact accept as a single literal word
/// will not match this pattern.  This pattern should only be used when
/// an error in that direction would be merely cosmetic.
final RegExp _definitelyShellLiteralWordRegExp = RegExp(r'^[a-zA-Z0-9./,_-]+$');

/// A string which a shell would parse as the given string value.
///
/// This method makes some effort to return the value unchanged,
/// for the sake of a clean appearance, when doing so meets the requirements.
/// For example, `shellEscapeString("asdf") == "asdf"`.
///
/// See also [shellEscapeCommand], for operating on a whole command line.
String shellEscapeString(String value) {
  if (_definitelyShellLiteralWordRegExp.hasMatch(value)) {
    return value;
  }
  return "'${value.replaceAll("'", r"'\''")}'";
}

/// A string which a shell would parse as the given command.
///
/// Useful for printing a command unambiguously, or for printing
/// a command the user might want to copy-paste and run.
///
/// This method makes some effort to print the command's elements
/// verbatim, for the sake of a clean appearance, where possible.
/// For example, `shellEscapeCommand(['git', 'commit', '-am', 'a commit'])`
/// returns `git commit -am 'a commit'`.
///
/// See also [shellEscapeString], for operating on an individual
/// argument of a command.
String shellEscapeCommand(List<String> command) {
  return command.map(shellEscapeString).join(' ');
}

/// Start a process and run it to completion, throwing an exception on failure.
///
/// Like [ProcessManager.runSync], this blocks until the child process terminates.
///
/// If the child process exits with failure (a nonzero [ProcessResult.exitCode]),
/// this method throws an exception with details of the command and its output.
ProcessResult runSyncSuccess(
  ProcessManager processManager,
  List<String> command, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  // no runInShell; keep that always false
  Encoding? stdoutEncoding = systemEncoding,
  Encoding? stderrEncoding = systemEncoding,
}) {
  final ProcessResult result = processManager.runSync(
    command,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
  );
  if (result.exitCode != 0) {
    throw Exception(
      'child process exited with code ${result.exitCode}\n'
      'command: ${shellEscapeCommand(command)}\n'
      'stdout: ================================================================\n'
      '${result.stdout}\n'
      'stderr: ================================================================\n'
      '${result.stderr}\n'
      'end ====================================================================',
    );
  }
  return result;
}

final RegExp _trailingNewlineRegExp = RegExp(r'\n*$');

String _asShellOutput(String raw) {
  return raw.replaceFirst(_trailingNewlineRegExp, '');
}

List<int> _bytesAsShellOutput(List<int> raw) {
  final int end = 1 + raw.lastIndexWhere((int byte) => byte != 0x0a);
  return end == raw.length ? raw : raw.sublist(0, end);
}

/// Reads the file contents as a string with the semantics of `$(cat …)`,
/// returning null if the operation fails.
///
/// This is commonly the intended semantics when a file was meant to be
/// read or written by a shell script.
///
/// The file's contents are read using the given [Encoding], and then
/// any run of newlines at the end of the string is removed.
///
/// See also:
/// * [processResultShellOutput], for the semantics of `$(…)`
///   on an arbitrary command.
/// * the Bash manual on command substitution `$(…)`: <https://www.gnu.org/software/bash/manual/bash.html#Command-Substitution>.
String? readStringLikeShell(File file, {Encoding encoding = utf8}) {
  try {
    return _asShellOutput(file.readAsStringSync(encoding: encoding));
  } on FileSystemException {
    return null;
  }
}

/// The command's output, as shell command substitution `$(…)` would take it.
///
/// Among commands following Unix CLI conventions, this is commonly the
/// intended semantics for consuming the output.
///
/// This is defined as the result of removing from [ProcessResult.stdout] any run of
/// newlines at the end of the string.  For example, if [ProcessResult.stdout] is any of
/// 'a\nb', 'a\nb\n', or 'a\nb\n\n\n', then the return value of [processResultShellOutput]
/// will be 'a\nb'.
///
/// This value has the same type as [ProcessResult.stdout]: either `List<int>` or `String`.
///
/// See also:
/// * [readStringLikeShell], for reading a file with the semantics of `$(cat …)`.
/// * the Bash manual on command substitution: <https://www.gnu.org/software/bash/manual/bash.html#Command-Substitution>.
Object processResultShellOutput(ProcessResult result) {
  final Object? stdout = result.stdout;
  return switch (stdout) {
    String() => _asShellOutput(stdout),
    List<int>() => _bytesAsShellOutput(stdout),
    _ => throw StateError('ProcessResult.stdout has invalid type ${stdout.runtimeType}'),
  };
}
