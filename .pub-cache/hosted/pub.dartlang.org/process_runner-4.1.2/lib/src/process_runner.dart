// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Completer;
import 'dart:convert' show Encoding;
import 'dart:io'
    show Process, ProcessStartMode, ProcessException, Directory, stderr, stdout, SystemEncoding
    hide Platform;

import 'package:platform/platform.dart' show Platform, LocalPlatform;
import 'package:process/process.dart' show ProcessManager, LocalProcessManager;

const Platform defaultPlatform = LocalPlatform();

/// Exception class for when a process fails to run, so we can catch
/// it and provide something more readable than a stack trace.
class ProcessRunnerException implements Exception {
  ProcessRunnerException(this.message, {this.result});

  final String message;
  final ProcessRunnerResult? result;

  int get exitCode => result?.exitCode ?? -1;

  @override
  String toString() {
    String output = runtimeType.toString();
    output += ': $message';
    final String stderr = result?.stderr ?? '';
    if (stderr.isNotEmpty) {
      output += ':\n$stderr';
    }
    return output;
  }
}

/// This is the result of running a command using [ProcessRunner] or
/// [ProcessPool].  It includes the entire stderr, stdout, and interleaved
/// output from the command after it has completed.
///
/// The [stdoutRaw], [stderrRaw], and [outputRaw] members contain the encoded
/// output from the command as a [List<int>].
///
/// The [stdout], [stderr], and [output] accessors will decode the [stdoutRaw],
/// [stderrRaw], and [outputRaw] data automatically, using a [SystemEncoding]
/// decoder.
class ProcessRunnerResult {
  /// Creates a new [ProcessRunnerResult], usually created by a [ProcessRunner].
  ///
  /// If [decoder] is not supplied, it defaults to [SystemEncoding].
  ProcessRunnerResult(
    this.exitCode,
    this.stdoutRaw,
    this.stderrRaw,
    this.outputRaw, {
    this.decoder = const SystemEncoding(),
    this.pid,
  });

  /// Contains the exit code from the completed process.
  final int exitCode;

  /// Contains the raw, encoded, stdout output from the completed process.
  final List<int> stdoutRaw;

  /// Contains the raw, encoded, stderr output from the completed process.
  final List<int> stderrRaw;

  /// Contains the raw, encoded, interleaved stdout and stderr output from the
  /// process.
  ///
  /// Information appears in the order supplied by the process.
  final List<int> outputRaw;

  /// The optional encoder to use in [stdout], [stderr], and [output] accessors to decode
  /// the raw data.
  ///
  /// Defaults to using [SystemEncoding].
  final Encoding decoder;

  /// The optional PID of the invoked process.
  ///
  /// This will only be populated when [ProcessStartMode.detached] or
  /// [ProcessStartMode.detachedWithStdio] are specified as the start mode given
  /// to [ProcessRunner.runProcess].
  final int? pid;

  /// Returns a lazily-decoded version of the data in [stdoutRaw], decoded using
  /// [decoder].
  String get stdout {
    _stdout ??= decoder.decode(stdoutRaw);
    return _stdout!;
  }

  String? _stdout;

  /// Returns a lazily-decoded version of the data in [stderrRaw], decoded using
  /// [decoder].
  String get stderr {
    _stderr ??= decoder.decode(stderrRaw);
    return _stderr!;
  }

  String? _stderr;

  /// Returns a lazily-decoded version of the data in [outputRaw], decoded using
  /// [decoder].
  ///
  /// Information appears in the order supplied by the process.
  String get output {
    _output ??= decoder.decode(outputRaw);
    return _output!;
  }

  String? _output;

  /// A constant to use if there is no result data available, but the process failed.
  static final ProcessRunnerResult failed = ProcessRunnerResult(-1, <int>[], <int>[], <int>[]);

  /// A constant to use if there is no result data available, but the process succeeded.
  static final ProcessRunnerResult emptySuccess = ProcessRunnerResult(0, <int>[], <int>[], <int>[]);
}

/// A helper class for classes that want to run a process, optionally have the
/// stderr and stdout printed to stdout/stderr as the process runs, and capture
/// the stdout, stderr, and interleaved output properly without dropping any.
class ProcessRunner {
  ProcessRunner({
    Directory? defaultWorkingDirectory,
    this.processManager = const LocalProcessManager(),
    Map<String, String>? environment,
    this.includeParentEnvironment = true,
    this.printOutputDefault = false,
    this.decoder = const SystemEncoding(),
  })  : defaultWorkingDirectory = defaultWorkingDirectory ?? Directory.current,
        environment = environment ?? Map<String, String>.from(defaultPlatform.environment);

  /// Set the [processManager] in order to allow injecting a test instance to
  /// perform testing.
  final ProcessManager processManager;

  /// Sets the default directory used when `workingDirectory` is not specified
  /// to [runProcess].
  final Directory defaultWorkingDirectory;

  /// The environment to run processes with.
  ///
  /// Sets the environment variables for the process. If not set, the
  /// environment of the parent process is inherited. Currently, only US-ASCII
  /// environment variables are supported and errors are likely to occur if an
  /// environment variable with code-points outside the US-ASCII range are
  /// passed in.
  final Map<String, String> environment;

  /// If true, merges the given [environment] into the parent environment.
  ///
  /// If [includeParentEnvironment] is `true`, the process's environment will
  /// include the parent process's environment, with [environment] taking
  /// precedence. Default is `true`.
  ///
  /// If false, uses [environment] as the entire environment to run in.
  final bool includeParentEnvironment;

  /// If set, indicates that, by default, commands will both write the output to
  /// stdout/stderr, as well as return it in the [ProcessRunnerResult.stderr],
  /// [ProcessRunnerResult.stderr] members.
  ///
  /// This setting can be overridden on a per-run basis by providing
  /// `printOutput` to the [runProcess] function.
  ///
  /// Defaults to false.
  final bool printOutputDefault;

  /// The decoder to use for decoding result stderr, stdout, and output.
  ///
  /// Defaults to an instance of [SystemEncoding].
  final Encoding decoder;

  /// Run the command and arguments in `commandLine` as a sub-process from
  /// `workingDirectory` if set, or the [defaultWorkingDirectory] if not. Uses
  /// [Directory.current] if [defaultWorkingDirectory] is not set.
  ///
  /// Set `failOk` if [runProcess] should not throw an exception when the
  /// command completes with a a non-zero exit code.
  ///
  /// If `printOutput` is set, indicates that the command will both write the
  /// output to stdout/stderr, as well as return it in the
  /// [ProcessRunnerResult.stderr], [ProcessRunnerResult.stderr] members of the
  /// result. This overrides the setting of [printOutputDefault].
  ///
  /// The `printOutput` argument defaults to the value of [printOutputDefault].
  Future<ProcessRunnerResult> runProcess(
    List<String> commandLine, {
    Directory? workingDirectory,
    bool? printOutput,
    bool failOk = false,
    Stream<List<int>>? stdin,
    bool runInShell = false,
    ProcessStartMode startMode = ProcessStartMode.normal,
  }) async {
    workingDirectory ??= defaultWorkingDirectory;
    printOutput ??= printOutputDefault;
    if (printOutput) {
      stderr.write('Running "${commandLine.join(' ')}" in ${workingDirectory.path}.\n');
    }
    final List<int> stdoutOutput = <int>[];
    final List<int> stderrOutput = <int>[];
    final List<int> combinedOutput = <int>[];
    final Completer<void> stdoutComplete = Completer<void>();
    final Completer<void> stderrComplete = Completer<void>();
    final Completer<void> stdinComplete = Completer<void>();

    late Process process;
    Future<int> allComplete() async {
      if (stdin != null) {
        await stdinComplete.future;
        await process.stdin.close();
      }
      await stderrComplete.future;
      await stdoutComplete.future;
      return startMode == ProcessStartMode.normal ? process.exitCode : Future<int>.value(0);
    }

    try {
      process = await processManager.start(
        commandLine,
        workingDirectory: workingDirectory.absolute.path,
        environment: environment,
        runInShell: runInShell,
        mode: startMode,
      );
      if (startMode == ProcessStartMode.normal || startMode == ProcessStartMode.detachedWithStdio) {
        if (stdin != null) {
          stdin.listen((List<int> data) {
            process.stdin.add(data);
          }, onDone: () async => stdinComplete.complete());
        }
        process.stdout.listen(
          (List<int> event) {
            stdoutOutput.addAll(event);
            combinedOutput.addAll(event);
            if (printOutput!) {
              stdout.add(event);
            }
          },
          onDone: () async => stdoutComplete.complete(),
        );
        process.stderr.listen(
          (List<int> event) {
            stderrOutput.addAll(event);
            combinedOutput.addAll(event);
            if (printOutput!) {
              stderr.add(event);
            }
          },
          onDone: () async => stderrComplete.complete(),
        );
      } else {
        // For "detached", we can't wait for anything to complete.
        stdinComplete.complete();
        stdoutComplete.complete();
        stderrComplete.complete();
      }
    } on ProcessException catch (e) {
      final String message = 'Running "${commandLine.join(' ')}" in ${workingDirectory.path} '
          'failed with:\n${e.toString()}';
      throw ProcessRunnerException(message);
    } on ArgumentError catch (e) {
      final String message = 'Running "${commandLine.join(' ')}" in ${workingDirectory.path} '
          'failed with:\n${e.toString()}';
      throw ProcessRunnerException(message);
    }

    final int exitCode = await allComplete();
    if (exitCode != 0 && !failOk) {
      final String message =
          'Running "${commandLine.join(' ')}" in ${workingDirectory.path} exited with code $exitCode\n${decoder.decode(combinedOutput)}';
      throw ProcessRunnerException(
        message,
        result: ProcessRunnerResult(
          exitCode,
          stdoutOutput,
          stderrOutput,
          combinedOutput,
          pid: process.pid,
          decoder: decoder,
        ),
      );
    }
    return ProcessRunnerResult(
      exitCode,
      stdoutOutput,
      stderrOutput,
      combinedOutput,
      pid: process.pid,
      decoder: decoder,
    );
  }
}
