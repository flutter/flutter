// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: close_sinks,cancel_subscriptions

import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';

import 'shared_stdin.dart';

/// Type definition for both [io.Process.start] and [ProcessManager.spawn].
///
/// Useful for taking different implementations of this base functionality.
typedef StartProcess = Future<io.Process> Function(
  String executable,
  List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool includeParentEnvironment,
  bool runInShell,
  io.ProcessStartMode mode,
});

/// A high-level abstraction around using and managing processes on the system.
abstract class ProcessManager {
  /// Terminates the global `stdin` listener, making future listens impossible.
  ///
  /// This method should be invoked only at the _end_ of a program's execution.
  static Future<void> terminateStdIn() async {
    await sharedStdIn.terminate();
  }

  /// Create a new instance of [ProcessManager] for the current platform.
  ///
  /// May manually specify whether the current platform [isWindows], otherwise
  /// this is derived from the Dart runtime (i.e. [io.Platform.isWindows]).
  factory ProcessManager({
    Stream<List<int>>? stdin,
    io.IOSink? stdout,
    io.IOSink? stderr,
    bool? isWindows,
  }) {
    stdin ??= sharedStdIn;
    stdout ??= io.stdout;
    stderr ??= io.stderr;
    isWindows ??= io.Platform.isWindows;
    if (isWindows) {
      return _WindowsProcessManager(stdin, stdout, stderr);
    }
    return _UnixProcessManager(stdin, stdout, stderr);
  }

  final Stream<List<int>> _stdin;
  final io.IOSink _stdout;
  final io.IOSink _stderr;

  const ProcessManager._(this._stdin, this._stdout, this._stderr);

  /// Spawns a process by invoking [executable] with [arguments].
  ///
  /// This is _similar_ to [io.Process.start], but all standard input and output
  /// is forwarded/routed between the process and the host, similar to how a
  /// shell script works.
  ///
  /// Returns a future that completes with a handle to the spawned process.
  Future<io.Process> spawn(
    String executable,
    Iterable<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) async {
    final process = io.Process.start(
      executable,
      arguments.toList(),
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
    return _ForwardingSpawn(await process, _stdin, _stdout, _stderr);
  }

  /// Spawns a process by invoking [executable] with [arguments].
  ///
  /// This is _similar_ to [io.Process.start], but `stdout` and `stderr` is
  /// forwarded/routed between the process and host, similar to how a shell
  /// script works.
  ///
  /// Returns a future that completes with a handle to the spawned process.
  Future<io.Process> spawnBackground(
    String executable,
    Iterable<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) async {
    final process = io.Process.start(
      executable,
      arguments.toList(),
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
    return _ForwardingSpawn(
      await process,
      const Stream.empty(),
      _stdout,
      _stderr,
    );
  }

  /// Spawns a process by invoking [executable] with [arguments].
  ///
  /// This is _identical to [io.Process.start] (no forwarding of I/O).
  ///
  /// Returns a future that completes with a handle to the spawned process.
  Future<io.Process> spawnDetached(
    String executable,
    Iterable<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) async =>
      io.Process.start(
        executable,
        arguments.toList(),
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        mode: mode,
      );
}

/// A process instance created and managed through [ProcessManager].
///
/// Unlike one created directly by [io.Process.start] or [io.Process.run], a
/// spawned process works more like executing a command in a shell script.
class Spawn implements io.Process {
  final io.Process _delegate;

  Spawn._(this._delegate) {
    _delegate.exitCode.then((_) => _onClosed());
  }

  @mustCallSuper
  void _onClosed() {}

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) =>
      _delegate.kill(signal);

  @override
  Future<int> get exitCode => _delegate.exitCode;

  @override
  int get pid => _delegate.pid;

  @override
  Stream<List<int>> get stderr => _delegate.stderr;

  @override
  io.IOSink get stdin => _delegate.stdin;

  @override
  Stream<List<int>> get stdout => _delegate.stdout;
}

/// Forwards `stdin`/`stdout`/`stderr` to/from the host.
class _ForwardingSpawn extends Spawn {
  final StreamSubscription<List<int>> _stdInSub;
  final StreamSubscription<List<int>> _stdOutSub;
  final StreamSubscription<List<int>> _stdErrSub;
  final StreamController<List<int>> _stdOut;
  final StreamController<List<int>> _stdErr;

  factory _ForwardingSpawn(
    io.Process delegate,
    Stream<List<int>> stdin,
    io.IOSink stdout,
    io.IOSink stderr,
  ) {
    final stdoutSelf = StreamController<List<int>>();
    final stderrSelf = StreamController<List<int>>();
    final stdInSub = stdin.listen(delegate.stdin.add);
    final stdOutSub = delegate.stdout.listen((event) {
      stdout.add(event);
      stdoutSelf.add(event);
    });
    final stdErrSub = delegate.stderr.listen((event) {
      stderr.add(event);
      stderrSelf.add(event);
    });
    return _ForwardingSpawn._delegate(
      delegate,
      stdInSub,
      stdOutSub,
      stdErrSub,
      stdoutSelf,
      stderrSelf,
    );
  }

  _ForwardingSpawn._delegate(
    io.Process delegate,
    this._stdInSub,
    this._stdOutSub,
    this._stdErrSub,
    this._stdOut,
    this._stdErr,
  ) : super._(delegate);

  @override
  void _onClosed() {
    _stdInSub.cancel();
    _stdOutSub.cancel();
    _stdErrSub.cancel();
    super._onClosed();
  }

  @override
  Stream<List<int>> get stdout => _stdOut.stream;

  @override
  Stream<List<int>> get stderr => _stdErr.stream;
}

class _UnixProcessManager extends ProcessManager {
  const _UnixProcessManager(
    Stream<List<int>> stdin,
    io.IOSink stdout,
    io.IOSink stderr,
  ) : super._(
          stdin,
          stdout,
          stderr,
        );
}

class _WindowsProcessManager extends ProcessManager {
  const _WindowsProcessManager(
    Stream<List<int>> stdin,
    io.IOSink stdout,
    io.IOSink stderr,
  ) : super._(
          stdin,
          stdout,
          stderr,
        );
}
