// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io show ProcessSignal, Process, ProcessStartMode, ProcessResult, systemEncoding;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'test_wrapper.dart';

export 'package:process/process.dart' show ProcessManager;

typedef VoidCallback = void Function();

/// A command for [FakeProcessManager].
@immutable
class FakeCommand {
  const FakeCommand({
    required this.command,
    this.workingDirectory,
    this.environment,
    this.encoding,
    this.duration = Duration.zero,
    this.onRun,
    this.exitCode = 0,
    this.stdout = '',
    this.stderr = '',
    this.completer,
    this.stdin,
    this.exception,
    this.outputFollowsExit = false,
  }) : assert(command != null),
       assert(duration != null),
       assert(exitCode != null);

  /// The exact commands that must be matched for this [FakeCommand] to be
  /// considered correct.
  final List<String> command;

  /// The exact working directory that must be matched for this [FakeCommand] to
  /// be considered correct.
  ///
  /// If this is null, the working directory is ignored.
  final String? workingDirectory;

  /// The environment that must be matched for this [FakeCommand] to be considered correct.
  ///
  /// If this is null, then the environment is ignored.
  ///
  /// Otherwise, each key in this environment must be present and must have a
  /// value that matches the one given here for the [FakeCommand] to match.
  final Map<String, String>? environment;

  /// The stdout and stderr encoding that must be matched for this [FakeCommand]
  /// to be considered correct.
  ///
  /// If this is null, then the encodings are ignored.
  final Encoding? encoding;

  /// The time to allow to elapse before returning the [exitCode], if this command
  /// is "executed".
  ///
  /// If you set this to a non-zero time, you should use a [FakeAsync] zone,
  /// otherwise the test will be artificially slow.
  final Duration duration;

  /// A callback that is run after [duration] expires but before the [exitCode]
  /// (and output) are passed back.
  final VoidCallback? onRun;

  /// The process' exit code.
  ///
  /// To simulate a never-ending process, set [duration] to a value greater than
  /// 15 minutes (the timeout for our tests).
  ///
  /// To simulate a crash, subtract the crash signal number from 256. For example,
  /// SIGPIPE (-13) is 243.
  final int exitCode;

  /// The output to simulate on stdout. This will be encoded as UTF-8 and
  /// returned in one go.
  final String stdout;

  /// The output to simulate on stderr. This will be encoded as UTF-8 and
  /// returned in one go.
  final String stderr;

  /// If provided, allows the command completion to be blocked until the future
  /// resolves.
  final Completer<void>? completer;

  /// An optional stdin sink that will be exposed through the resulting
  /// [FakeProcess].
  final IOSink? stdin;

  /// If provided, this exception will be thrown when the fake command is run.
  final Object? exception;

  /// Indicates that output will only be emitted after the `exitCode` [Future]
  /// on [io.Process] completes.
  final bool outputFollowsExit;

  void _matches(
    List<String> command,
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? encoding,
  ) {
    expect(command, equals(this.command));
    if (this.workingDirectory != null) {
      expect(this.workingDirectory, workingDirectory);
    }
    if (this.environment != null) {
      expect(this.environment, environment);
    }
    if (this.encoding != null) {
      expect(this.encoding, encoding);
    }
  }
}

class _FakeProcess implements io.Process {
  _FakeProcess(
    this._exitCode,
    Duration duration,
    this.pid,
    this._stderr,
    IOSink? stdin,
    this._stdout,
    this._completer,
    bool outputFollowsExit,
  ) : exitCode = Future<void>.delayed(duration).then((void value) {
        if (_completer != null) {
          return _completer.future.then((void _) => _exitCode);
        }
        return _exitCode;
      }),
      stdin = stdin ?? IOSink(StreamController<List<int>>().sink)
  {
    if (_stderr == null) {
      stderr = const Stream<List<int>>.empty();
    } else if (outputFollowsExit) {
      stderr = Stream<List<int>>.fromFuture(exitCode.then((_) {
        return Future<List<int>>(() => utf8.encode(_stderr));
      }));
    } else {
      stderr = Stream<List<int>>.value(utf8.encode(_stderr));
    }

    if (_stdout == null) {
      stdout = const Stream<List<int>>.empty();
    } else if (outputFollowsExit) {
      stdout = Stream<List<int>>.fromFuture(exitCode.then((_) {
        return Future<List<int>>(() => utf8.encode(_stdout));
      }));
    } else {
      stdout = Stream<List<int>>.value(utf8.encode(_stdout));
    }
  }

  final int _exitCode;
  final Completer<void>? _completer;

  @override
  final Future<int> exitCode;

  @override
  final int pid;

  final String _stderr;

  @override
  late final Stream<List<int>> stderr;

  @override
  final IOSink stdin;

  @override
  late final Stream<List<int>> stdout;

  final String _stdout;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    // Killing a fake process has no effect.
    return false;
  }
}

abstract class FakeProcessManager implements ProcessManager {
  /// A fake [ProcessManager] which responds to all commands as if they had run
  /// instantaneously with an exit code of 0 and no output.
  factory FakeProcessManager.any() = _FakeAnyProcessManager;

  /// A fake [ProcessManager] which responds to particular commands with
  /// particular results.
  ///
  /// On creation, pass in a list of [FakeCommand] objects. When the
  /// [ProcessManager] methods such as [start] are invoked, the next
  /// [FakeCommand] must match (otherwise the test fails); its settings are used
  /// to simulate the result of running that command.
  ///
  /// If no command is found, then one is implied which immediately returns exit
  /// code 0 with no output.
  ///
  /// There is no logic to ensure that all the listed commands are run. Use
  /// [FakeCommand.onRun] to set a flag, or specify a sentinel command as your
  /// last command and verify its execution is successful, to ensure that all
  /// the specified commands are actually called.
  factory FakeProcessManager.list(List<FakeCommand> commands) = _SequenceProcessManager;
  factory FakeProcessManager.empty() => _SequenceProcessManager(<FakeCommand>[]);

  FakeProcessManager._();

  /// Adds a new [FakeCommand] to the current process manager.
  ///
  /// This can be used to configure test expectations after the [ProcessManager] has been
  /// provided to another interface.
  ///
  /// This is a no-op on [FakeProcessManager.any].
  void addCommand(FakeCommand command);

  /// Add multiple [FakeCommand] to the current process manager.
  void addCommands(Iterable<FakeCommand> commands) {
    commands.forEach(addCommand);
  }

  final Map<int, _FakeProcess> _fakeRunningProcesses = <int, _FakeProcess>{};

  /// Whether this fake has more [FakeCommand]s that are expected to run.
  ///
  /// This is always `true` for [FakeProcessManager.any].
  bool get hasRemainingExpectations;

  /// The expected [FakeCommand]s that have not yet run.
  List<FakeCommand> get _remainingExpectations;

  @protected
  FakeCommand findCommand(
    List<String> command,
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? encoding,
  );

  int _pid = 9999;

  _FakeProcess _runCommand(
    List<String> command,
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? encoding,
  ) {
    _pid += 1;
    final FakeCommand fakeCommand = findCommand(command, workingDirectory, environment, encoding);
    if (fakeCommand.exception != null) {
      assert(fakeCommand.exception is Exception || fakeCommand.exception is Error);
      throw fakeCommand.exception!; // ignore: only_throw_errors
    }
    if (fakeCommand.onRun != null) {
      fakeCommand.onRun!();
    }
    return _FakeProcess(
      fakeCommand.exitCode,
      fakeCommand.duration,
      _pid,
      fakeCommand.stderr,
      fakeCommand.stdin,
      fakeCommand.stdout,
      fakeCommand.completer,
      fakeCommand.outputFollowsExit,
    );
  }

  @override
  Future<io.Process> start(
    List<dynamic> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true, // ignored
    bool runInShell = false, // ignored
    io.ProcessStartMode mode = io.ProcessStartMode.normal, // ignored
  }) {
    final _FakeProcess process = _runCommand(command.cast<String>(), workingDirectory, environment, io.systemEncoding);
    if (process._completer != null) {
      _fakeRunningProcesses[process.pid] = process;
      process.exitCode.whenComplete(() {
        _fakeRunningProcesses.remove(process.pid);
      });
    }
    return Future<io.Process>.value(process);
  }

  @override
  Future<io.ProcessResult> run(
    List<dynamic> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true, // ignored
    bool runInShell = false, // ignored
    Encoding? stdoutEncoding = io.systemEncoding,
    Encoding? stderrEncoding = io.systemEncoding,
  }) async {
    final _FakeProcess process = _runCommand(command.cast<String>(), workingDirectory, environment, stdoutEncoding);
    await process.exitCode;
    return io.ProcessResult(
      process.pid,
      process._exitCode,
      stdoutEncoding == null ? process.stdout : await stdoutEncoding.decodeStream(process.stdout),
      stderrEncoding == null ? process.stderr : await stderrEncoding.decodeStream(process.stderr),
    );
  }

  @override
  io.ProcessResult runSync(
    List<dynamic> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true, // ignored
    bool runInShell = false, // ignored
    Encoding? stdoutEncoding = io.systemEncoding, // actual encoder is ignored
    Encoding? stderrEncoding = io.systemEncoding, // actual encoder is ignored
  }) {
    final _FakeProcess process = _runCommand(command.cast<String>(), workingDirectory, environment, stdoutEncoding);
    return io.ProcessResult(
      process.pid,
      process._exitCode,
      stdoutEncoding == null ? utf8.encode(process._stdout) : process._stdout,
      stderrEncoding == null ? utf8.encode(process._stderr) : process._stderr,
    );
  }

  /// Returns false if executable in [excludedExecutables].
  @override
  bool canRun(dynamic executable, {String? workingDirectory}) => !excludedExecutables.contains(executable);

  Set<String> excludedExecutables = <String>{};

  @override
  bool killPid(int pid, [io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    // Killing a fake process has no effect unless it has an attached completer.
    final _FakeProcess? fakeProcess = _fakeRunningProcesses[pid];
    if (fakeProcess == null) {
      return false;
    }
    if (fakeProcess._completer != null) {
      fakeProcess._completer!.complete();
    }
    return true;
  }
}

class _FakeAnyProcessManager extends FakeProcessManager {
  _FakeAnyProcessManager() : super._();

  @override
  FakeCommand findCommand(
    List<String> command,
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? encoding,
  ) {
    return FakeCommand(
      command: command,
      workingDirectory: workingDirectory,
      environment: environment,
      encoding: encoding,
    );
  }

  @override
  void addCommand(FakeCommand command) { }

  @override
  bool get hasRemainingExpectations => true;

  @override
  List<FakeCommand> get _remainingExpectations => <FakeCommand>[];
}

class _SequenceProcessManager extends FakeProcessManager {
  _SequenceProcessManager(this._commands) : super._();

  final List<FakeCommand> _commands;

  @override
  FakeCommand findCommand(
    List<String> command,
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? encoding,
  ) {
    expect(_commands, isNotEmpty,
      reason: 'ProcessManager was told to execute $command (in $workingDirectory) '
              'but the FakeProcessManager.list expected no more processes.'
    );
    _commands.first._matches(command, workingDirectory, environment, encoding);
    return _commands.removeAt(0);
  }

  @override
  void addCommand(FakeCommand command) {
    _commands.add(command);
  }

  @override
  bool get hasRemainingExpectations => _commands.isNotEmpty;

  @override
  List<FakeCommand> get _remainingExpectations => _commands;
}

/// Matcher that successfully matches against a [FakeProcessManager] with
/// no remaining expectations ([item.hasRemainingExpectations] returns false).
const Matcher hasNoRemainingExpectations = _HasNoRemainingExpectations();

class _HasNoRemainingExpectations extends Matcher {
  const _HasNoRemainingExpectations();

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      item is FakeProcessManager && !item.hasRemainingExpectations;

  @override
  Description describe(Description description) =>
      description.add('a fake process manager with no remaining expectations');

  @override
  Description describeMismatch(
      dynamic item,
      Description description,
      Map<dynamic, dynamic> matchState,
      bool verbose,
      ) {
    final FakeProcessManager fakeProcessManager = item as FakeProcessManager;
    return description.add(
        'has remaining expectations:\n${fakeProcessManager._remainingExpectations.map((FakeCommand command) => command.command).join('\n')}');
  }
}
