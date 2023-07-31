// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io'
    show
        Process,
        ProcessResult,
        ProcessSignal,
        ProcessStartMode,
        systemEncoding;

/// Manages the creation of abstract processes.
///
/// Using instances of this class provides level of indirection from the static
/// methods in the [Process] class, which in turn allows the underlying
/// implementation to be mocked out or decorated for testing and debugging
/// purposes.
abstract class ProcessManager {
  /// Starts a process by running the specified [command].
  ///
  /// The first element in [command] will be treated as the executable to run,
  /// with subsequent elements being passed as arguments to the executable. It
  /// is left to implementations to decide what element types they support in
  /// the [command] list.
  ///
  /// Returns a `Future<Process>` that completes with a Process instance when
  /// the process has been successfully started. That [Process] object can be
  /// used to interact with the process. If the process cannot be started, the
  /// returned [Future] completes with an exception.
  ///
  /// Use [workingDirectory] to set the working directory for the process. Note
  /// that the change of directory occurs before executing the process on some
  /// platforms, which may have impact when using relative paths for the
  /// executable and the arguments.
  ///
  /// Use [environment] to set the environment variables for the process. If not
  /// set, the environment of the parent process is inherited. Currently, only
  /// US-ASCII environment variables are supported and errors are likely to occur
  /// if an environment variable with code-points outside the US-ASCII range is
  /// passed in.
  ///
  /// If [includeParentEnvironment] is `true`, the process's environment will
  /// include the parent process's environment, with [environment] taking
  /// precedence. Default is `true`.
  ///
  /// If [runInShell] is `true`, the process will be spawned through a system
  /// shell. On Linux and OS X, `/bin/sh` is used, while
  /// `%WINDIR%\system32\cmd.exe` is used on Windows.
  ///
  /// Users must read all data coming on the `stdout` and `stderr`
  /// streams of processes started with [start]. If the user
  /// does not read all data on the streams the underlying system
  /// resources will not be released since there is still pending data.
  ///
  /// The following code uses `start` to grep for `main` in the
  /// file `test.dart` on Linux.
  ///
  ///     ProcessManager mgr = new LocalProcessManager();
  ///     mgr.start(['grep', '-i', 'main', 'test.dart']).then((process) {
  ///       stdout.addStream(process.stdout);
  ///       stderr.addStream(process.stderr);
  ///     });
  ///
  /// If [mode] is [ProcessStartMode.normal] (the default) a child
  /// process will be started with `stdin`, `stdout` and `stderr`
  /// connected.
  ///
  /// If `mode` is [ProcessStartMode.detached] a detached process will
  /// be created. A detached process has no connection to its parent,
  /// and can keep running on its own when the parent dies. The only
  /// information available from a detached process is its `pid`. There
  /// is no connection to its `stdin`, `stdout` or `stderr`, nor will
  /// the process' exit code become available when it terminates.
  ///
  /// If `mode` is [ProcessStartMode.detachedWithStdio] a detached
  /// process will be created where the `stdin`, `stdout` and `stderr`
  /// are connected. The creator can communicate with the child through
  /// these. The detached process will keep running even if these
  /// communication channels are closed. The process' exit code will
  /// not become available when it terminated.
  ///
  /// The default value for `mode` is `ProcessStartMode.normal`.
  Future<Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  });

  /// Starts a process and runs it non-interactively to completion.
  ///
  /// The first element in [command] will be treated as the executable to run,
  /// with subsequent elements being passed as arguments to the executable. It
  /// is left to implementations to decide what element types they support in
  /// the [command] list.
  ///
  /// Use [workingDirectory] to set the working directory for the process. Note
  /// that the change of directory occurs before executing the process on some
  /// platforms, which may have impact when using relative paths for the
  /// executable and the arguments.
  ///
  /// Use [environment] to set the environment variables for the process. If not
  /// set the environment of the parent process is inherited. Currently, only
  /// US-ASCII environment variables are supported and errors are likely to occur
  /// if an environment variable with code-points outside the US-ASCII range is
  /// passed in.
  ///
  /// If [includeParentEnvironment] is `true`, the process's environment will
  /// include the parent process's environment, with [environment] taking
  /// precedence. Default is `true`.
  ///
  /// If [runInShell] is true, the process will be spawned through a system
  /// shell. On Linux and OS X, `/bin/sh` is used, while
  /// `%WINDIR%\system32\cmd.exe` is used on Windows.
  ///
  /// The encoding used for decoding `stdout` and `stderr` into text is
  /// controlled through [stdoutEncoding] and [stderrEncoding]. The
  /// default encoding is [systemEncoding]. If `null` is used no
  /// decoding will happen and the [ProcessResult] will hold binary
  /// data.
  ///
  /// Returns a `Future<ProcessResult>` that completes with the
  /// result of running the process, i.e., exit code, standard out and
  /// standard in.
  ///
  /// The following code uses `run` to grep for `main` in the
  /// file `test.dart` on Linux.
  ///
  ///     ProcessManager mgr = new LocalProcessManager();
  ///     mgr.run('grep', ['-i', 'main', 'test.dart']).then((result) {
  ///       stdout.write(result.stdout);
  ///       stderr.write(result.stderr);
  ///     });
  Future<ProcessResult> run(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    // TODO(#64): Remove the `covariant` keyword.
    covariant Encoding? stdoutEncoding = systemEncoding,
    covariant Encoding? stderrEncoding = systemEncoding,
  });

  /// Starts a process and runs it to completion. This is a synchronous
  /// call and will block until the child process terminates.
  ///
  /// The arguments are the same as for [run]`.
  ///
  /// Returns a `ProcessResult` with the result of running the process,
  /// i.e., exit code, standard out and standard in.
  ProcessResult runSync(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    // TODO(#64): Remove the `covariant` keyword.
    covariant Encoding? stdoutEncoding = systemEncoding,
    covariant Encoding? stderrEncoding = systemEncoding,
  });

  /// Returns `true` if the [executable] exists and if it can be executed.
  bool canRun(dynamic executable, {String? workingDirectory});

  /// Kills the process with id [pid].
  ///
  /// Where possible, sends the [signal] to the process with id
  /// `pid`. This includes Linux and OS X. The default signal is
  /// [ProcessSignal.sigterm] which will normally terminate the
  /// process.
  ///
  /// On platforms without signal support, including Windows, the call
  /// just terminates the process with id `pid` in a platform specific
  /// way, and the `signal` parameter is ignored.
  ///
  /// Returns `true` if the signal is successfully delivered to the
  /// process. Otherwise the signal could not be sent, usually meaning
  /// that the process is already dead.
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]);
}
