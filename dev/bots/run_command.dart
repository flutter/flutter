// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core' hide print;
import 'dart:io' as io;

import 'package:path/path.dart' as path;

import 'utils.dart';

/// Runs the `executable` and returns standard output as a stream of lines.
///
/// The returned stream reaches its end immediately after the command exits.
///
/// If `expectNonZeroExit` is false and the process exits with a non-zero exit
/// code fails the test immediately by exiting the test process with exit code
/// 1.
Stream<String> runAndGetStdout(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool expectNonZeroExit = false,
}) async* {
  final output = StreamController<String>();
  final Future<CommandResult?> command = runCommand(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    expectNonZeroExit: expectNonZeroExit,
    // Capture the output so it's not printed to the console by default.
    outputMode: OutputMode.capture,
    outputListener: (String line, io.Process process) {
      output.add(line);
    },
  );

  // Close the stream controller after the command is complete. Otherwise,
  // the yield* will never finish.
  command.whenComplete(output.close);

  yield* output.stream;
}

/// Represents a running process launched using [startCommand].
class Command {
  Command._(this.process, this._time, this._savedStdout, this._savedStderr);

  /// The raw process that was launched for this command.
  final io.Process process;
  final Stopwatch _time;
  final Future<String> _savedStdout;
  final Future<String> _savedStderr;
}

/// The result of running a command using [startCommand] and [runCommand];
class CommandResult {
  CommandResult._(this.exitCode, this.elapsedTime, this.flattenedStdout, this.flattenedStderr);

  /// The exit code of the process.
  final int exitCode;

  /// The amount of time it took the process to complete.
  final Duration elapsedTime;

  /// Standard output decoded as a string using UTF8 decoder.
  final String? flattenedStdout;

  /// Standard error output decoded as a string using UTF8 decoder.
  final String? flattenedStderr;
}

/// Starts the `executable` and returns a command object representing the
/// running process.
///
/// `outputListener` is called for every line of standard output from the
/// process, and is given the [Process] object. This can be used to interrupt
/// an indefinitely running process, for example, by waiting until the process
/// emits certain output.
///
/// `outputMode` controls where the standard output from the command process
/// goes. See [OutputMode].
Future<Command> startCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  OutputMode outputMode = OutputMode.print,
  bool Function(String)? removeLine,
  void Function(String, io.Process)? outputListener,
}) async {
  final String relativeWorkingDir = path.relative(workingDirectory ?? io.Directory.current.path);
  final commandDescription =
      '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  print('RUNNING: cd $cyan$relativeWorkingDir$reset; $green$commandDescription$reset');

  final time = Stopwatch()..start();
  print('workingDirectory: $workingDirectory, executable: $executable, arguments: $arguments');

  // Override ANDROID_NDK_PATH with a valid discovered path or empty string to clear a potentially bad value.
  // See also dev/devicelab/lib/framework/utils.dart.
  final finalEnvironment = <String, String>{
    ...?environment,
    'ANDROID_NDK_PATH': ?_discoverBestNdkPath(),
  };
  final io.Process process = await io.Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: finalEnvironment,
  );
  return Command._(
    process,
    time,
    process.stdout
        .transform<String>(const Utf8Decoder())
        .transform(const LineSplitter())
        .where((String line) => removeLine == null || !removeLine(line))
        .map<String>((String line) {
          final formattedLine = '$line\n';
          if (outputListener != null) {
            outputListener(formattedLine, process);
          }
          switch (outputMode) {
            case OutputMode.print:
              print(line);
            case OutputMode.capture:
              break;
          }
          return line;
        })
        .join('\n'),
    process.stderr
        .transform<String>(const Utf8Decoder())
        .transform(const LineSplitter())
        .map<String>((String line) {
          switch (outputMode) {
            case OutputMode.print:
              print(line);
            case OutputMode.capture:
              break;
          }
          return line;
        })
        .join('\n'),
  );
}

String? _bestNdkPath;
String? _discoverBestNdkPath() {
  if (_bestNdkPath != null) {
    return _bestNdkPath;
  }
  // If we found a valid NDK, return it.
  // Otherwise return empty string to clear any bad inherited value.
  final Map<String, String> env = io.Platform.environment;
  String? androidHome = env['ANDROID_HOME'] ?? env['ANDROID_SDK_ROOT'];
  if (androidHome == null) {
    // Try to find it in common default locations.
    if (io.Platform.isMacOS) {
      final String? home = env['HOME'];
      if (home != null) {
        androidHome = path.join(home, 'Library', 'Android', 'sdk');
      }
    } else if (io.Platform.isLinux) {
      final String? home = env['HOME'];
      if (home != null) {
        androidHome = path.join(home, 'Android', 'Sdk');
      }
    } else if (io.Platform.isWindows) {
      final String? homeDrive = env['HOMEDRIVE'];
      final String? homePath = env['HOMEPATH'];
      if (homeDrive != null && homePath != null) {
        androidHome = path.join(homeDrive + homePath, 'AppData', 'Local', 'Android', 'sdk');
      }
    }
  }

  if (androidHome == null) {
    return _bestNdkPath = null;
  }
  final ndkDir = io.Directory(path.join(androidHome, 'ndk'));
  if (!ndkDir.existsSync()) {
    return _bestNdkPath = null;
  }
  final versions = <String>[];
  for (final io.FileSystemEntity entity in ndkDir.listSync()) {
    if (entity is io.Directory) {
      final String name = path.basename(entity.path);
      // flutter_tools ignores non-SemVer directories. NDK versions should start with a number.
      if (int.tryParse(name.split('.').first) != null) {
        versions.add(name);
      }
    }
  }
  if (versions.isEmpty) {
    return _bestNdkPath = null;
  }
  // Sort numerically/lexicographically to find the "highest" version.
  // We assume versions are like "21.4.7075529" or "23.1.7779620".
  // A simple sort works for major versions if they have the same number of digits,
  // but to be safe we parse the major version.
  versions.sort((String a, String b) {
    // Try to parse major version.
    final int? aMajor = int.tryParse(a.split('.').first);
    final int? bMajor = int.tryParse(b.split('.').first);
    if (aMajor != null && bMajor != null) {
      if (aMajor != bMajor) {
        return aMajor.compareTo(bMajor);
      }
    }
    // Fallback to string comparison.
    return a.compareTo(b);
  });

  return _bestNdkPath = path.join(ndkDir.path, versions.last);
}

/// Runs the `executable` and waits until the process exits.
///
/// If the process exits with a non-zero exit code and `expectNonZeroExit` is
/// false, calls foundError (which does not terminate execution!).
///
/// `outputListener` is called for every line of standard output from the
/// process, and is given the [Process] object. This can be used to interrupt
/// an indefinitely running process, for example, by waiting until the process
/// emits certain output.
///
/// Returns the result of the finished process.
///
/// `outputMode` controls where the standard output from the command process
/// goes. See [OutputMode].
Future<CommandResult> runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool expectNonZeroExit = false,
  int? expectedExitCode,
  String? failureMessage,
  OutputMode outputMode = OutputMode.print,
  bool Function(String)? removeLine,
  void Function(String, io.Process)? outputListener,
}) async {
  final commandDescription =
      '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = workingDirectory ?? path.relative(io.Directory.current.path);
  if (dryRun) {
    printProgress(_prettyPrintRunCommand(executable, arguments, workingDirectory));
    return CommandResult._(
      0,
      Duration.zero,
      '$executable ${arguments.join(' ')}',
      'Simulated execution due to --dry-run',
    );
  }

  final Command command = await startCommand(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    outputMode: outputMode,
    removeLine: removeLine,
    outputListener: outputListener,
  );

  final result = CommandResult._(
    await command.process.exitCode,
    command._time.elapsed,
    await command._savedStdout,
    await command._savedStderr,
  );

  if ((result.exitCode == 0) == expectNonZeroExit ||
      (expectedExitCode != null && result.exitCode != expectedExitCode)) {
    // Print the output when we get unexpected results (unless output was
    // printed already).
    switch (outputMode) {
      case OutputMode.print:
        break;
      case OutputMode.capture:
        print(result.flattenedStdout);
        print(result.flattenedStderr);
    }
    final allOutput = '${result.flattenedStdout}\n${result.flattenedStderr}';
    foundError(<String>[
      ?failureMessage,
      '${bold}Command: $green$commandDescription$reset',
      if (failureMessage == null)
        '$bold${red}Command exited with exit code ${result.exitCode} but expected ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'} exit code.$reset',
      '${bold}Working directory: $cyan${path.absolute(relativeWorkingDir)}$reset',
      if (allOutput.isNotEmpty && allOutput.length < 512)
        '${bold}stdout and stderr output:\n$allOutput',
    ]);
  } else {
    print(
      'ELAPSED TIME: ${prettyPrintDuration(result.elapsedTime)} for $green$commandDescription$reset in $cyan$relativeWorkingDir$reset',
    );
  }
  return result;
}

final String _flutterRoot = path.dirname(
  path.dirname(path.dirname(path.fromUri(io.Platform.script))),
);

String _prettyPrintRunCommand(String executable, List<String> arguments, String? workingDirectory) {
  final output = StringBuffer();

  // Print CWD relative to the root.
  output.write('|> ');
  output.write(path.relative(executable, from: _flutterRoot));
  if (workingDirectory != null) {
    output.write(' (${path.relative(workingDirectory, from: _flutterRoot)})');
  }
  output.writeln(': ');
  output.writeAll(arguments.map((String a) => '  $a'), '\n');

  return output.toString();
}

/// Specifies what to do with the command output from [runCommand] and [startCommand].
enum OutputMode {
  /// Forwards standard output and standard error streams to the test process'
  /// standard output stream (i.e. stderr is redirected to stdout).
  ///
  /// Use this mode if all you want is print the output of the command to the
  /// console. The output is no longer available after the process exits.
  print,

  /// Saves standard output and standard error streams in memory.
  ///
  /// Captured output can be retrieved from the [CommandResult] object.
  ///
  /// Use this mode in tests that need to inspect the output of a command, or
  /// when the output should not be printed to console.
  capture,
}
