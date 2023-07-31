import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:process_run/process_run.dart';

class ProcessCmd {
  String? executable;
  List<String> arguments;
  String? workingDirectory;
  Map<String, String>? environment;
  bool includeParentEnvironment;
  bool? runInShell;
  Encoding? stdoutEncoding;
  Encoding? stderrEncoding;

  ProcessCmd(this.executable, this.arguments,
      {this.workingDirectory,
      this.environment,
      this.includeParentEnvironment = true,
      this.runInShell,
      this.stdoutEncoding = systemEncoding,
      this.stderrEncoding = systemEncoding});

  ProcessCmd clone() => ProcessCmd(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding);

  @override
  int get hashCode => executable.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is ProcessCmd) {
      return (other.executable == executable &&
          const ListEquality<String>().equals(other.arguments, arguments));
    }
    return false;
  }

  @override
  String toString() => executableArgumentsToString(executable, arguments);
}

// Use ProcessCmd instead
@Deprecated('Use ProcessCmd instead')
ProcessCmd processCmd(String executable, List<String> arguments,
    {String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool? runInShell,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding}) {
  return ProcessCmd(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding);
}

bool _isNotEmpty(Object? stdout) {
  if (stdout is List) {
    return stdout.isNotEmpty;
  } else if (stdout is String) {
    return stdout.isNotEmpty;
  }
  return (stdout != null);
}

String processResultToDebugString(ProcessResult result) {
  final sb = StringBuffer();
  sb.writeln('exitCode: ${result.exitCode}');
  if (_isNotEmpty(result.stdout)) {
    sb.writeln('out: ${result.stdout}');
  }
  if (_isNotEmpty(result.stderr)) {
    sb.writeln('err: ${result.stderr}');
  }
  return sb.toString();
}

String processCmdToDebugString(ProcessCmd cmd) {
  final sb = StringBuffer();
  if (cmd.workingDirectory != null) {
    sb.writeln('dir: ${cmd.workingDirectory}');
  }
  sb.writeln('cmd: $cmd');

  return sb.toString();
}
