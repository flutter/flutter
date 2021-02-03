// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:file/local.dart' as local_fs;

import '../convert.dart';
import 'common.dart';
import 'context.dart';
import 'file_system.dart';
import 'io.dart';
import 'logger.dart';
import 'platform.dart';

typedef StringConverter = String Function(String string);

/// A function that will be run before the VM exits.
typedef ShutdownHook = FutureOr<dynamic> Function();

// TODO(ianh): We have way too many ways to run subprocesses in this project.
// Convert most of these into one or more lightweight wrappers around the
// [ProcessManager] API using named parameters for the various options.
// See [here](https://github.com/flutter/flutter/pull/14535#discussion_r167041161)
// for more details.

/// The stage in which a [ShutdownHook] will be run. All shutdown hooks within
/// a given stage will be started in parallel and will be guaranteed to run to
/// completion before shutdown hooks in the next stage are started.
class ShutdownStage implements Comparable<ShutdownStage> {
  const ShutdownStage._(this.priority);

  /// The stage priority. Smaller values will be run before larger values.
  final int priority;

  /// The stage before the invocation recording (if one exists) is serialized
  /// to disk. Tasks performed during this stage *will* be recorded.
  static const ShutdownStage STILL_RECORDING = ShutdownStage._(1);

  /// The stage during which the invocation recording (if one exists) will be
  /// serialized to disk. Invocations performed after this stage will not be
  /// recorded.
  static const ShutdownStage SERIALIZE_RECORDING = ShutdownStage._(2);

  /// The stage during which a serialized recording will be refined (e.g.
  /// cleansed for tests, zipped up for bug reporting purposes, etc.).
  static const ShutdownStage POST_PROCESS_RECORDING = ShutdownStage._(3);

  /// The stage during which temporary files and directories will be deleted.
  static const ShutdownStage CLEANUP = ShutdownStage._(4);

  @override
  int compareTo(ShutdownStage other) => priority.compareTo(other.priority);
}

ShutdownHooks get shutdownHooks => ShutdownHooks.instance;

abstract class ShutdownHooks {
  factory ShutdownHooks({
    @required Logger logger,
  }) => _DefaultShutdownHooks(
    logger: logger,
  );

  static ShutdownHooks get instance => context.get<ShutdownHooks>();

  /// Registers a [ShutdownHook] to be executed before the VM exits.
  ///
  /// If [stage] is specified, the shutdown hook will be run during the specified
  /// stage. By default, the shutdown hook will be run during the
  /// [ShutdownStage.CLEANUP] stage.
  void addShutdownHook(
    ShutdownHook shutdownHook, [
    ShutdownStage stage = ShutdownStage.CLEANUP,
  ]);

  /// Runs all registered shutdown hooks and returns a future that completes when
  /// all such hooks have finished.
  ///
  /// Shutdown hooks will be run in groups by their [ShutdownStage]. All shutdown
  /// hooks within a given stage will be started in parallel and will be
  /// guaranteed to run to completion before shutdown hooks in the next stage are
  /// started.
  Future<void> runShutdownHooks();
}

class _DefaultShutdownHooks implements ShutdownHooks {
  _DefaultShutdownHooks({
    @required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  final Map<ShutdownStage, List<ShutdownHook>> _shutdownHooks = <ShutdownStage, List<ShutdownHook>>{};

  bool _shutdownHooksRunning = false;

  @override
  void addShutdownHook(
    ShutdownHook shutdownHook, [
    ShutdownStage stage = ShutdownStage.CLEANUP,
  ]) {
    assert(!_shutdownHooksRunning);
    _shutdownHooks.putIfAbsent(stage, () => <ShutdownHook>[]).add(shutdownHook);
  }

  @override
  Future<void> runShutdownHooks() async {
    _logger.printTrace('Running shutdown hooks');
    _shutdownHooksRunning = true;
    try {
      for (final ShutdownStage stage in _shutdownHooks.keys.toList()..sort()) {
        _logger.printTrace('Shutdown hook priority ${stage.priority}');
        final List<ShutdownHook> hooks = _shutdownHooks.remove(stage);
        final List<Future<dynamic>> futures = <Future<dynamic>>[];
        for (final ShutdownHook shutdownHook in hooks) {
          final FutureOr<dynamic> result = shutdownHook();
          if (result is Future<dynamic>) {
            futures.add(result);
          }
        }
        await Future.wait<dynamic>(futures);
      }
    } finally {
      _shutdownHooksRunning = false;
    }
    assert(_shutdownHooks.isEmpty);
    _logger.printTrace('Shutdown hooks complete');
  }
}

class ProcessExit implements Exception {
  ProcessExit(this.exitCode, {this.immediate = false});

  final bool immediate;
  final int exitCode;

  String get message => 'ProcessExit: $exitCode';

  @override
  String toString() => message;
}

class RunResult {
  RunResult(this.processResult, this._command)
    : assert(_command != null),
      assert(_command.isNotEmpty);

  final ProcessResult processResult;

  final List<String> _command;

  int get exitCode => processResult.exitCode;
  String get stdout => processResult.stdout as String;
  String get stderr => processResult.stderr as String;

  @override
  String toString() {
    final StringBuffer out = StringBuffer();
    if (stdout.isNotEmpty) {
      out.writeln(stdout);
    }
    if (stderr.isNotEmpty) {
      out.writeln(stderr);
    }
    return out.toString().trimRight();
  }

  /// Throws a [ProcessException] with the given `message`.
  void throwException(String message) {
    throw ProcessException(
      _command.first,
      _command.skip(1).toList(),
      message,
      exitCode,
    );
  }
}

typedef RunResultChecker = bool Function(int);

abstract class ProcessUtils {
  factory ProcessUtils({
    @required ProcessManager processManager,
    @required Logger logger,
  }) => _DefaultProcessUtils(
    processManager: processManager,
    logger: logger,
  );

  /// Spawns a child process to run the command [cmd].
  ///
  /// When [throwOnError] is `true`, if the child process finishes with a non-zero
  /// exit code, a [ProcessException] is thrown.
  ///
  /// If [throwOnError] is `true`, and [allowedFailures] is supplied,
  /// a [ProcessException] is only thrown on a non-zero exit code if
  /// [allowedFailures] returns false when passed the exit code.
  ///
  /// When [workingDirectory] is set, it is the working directory of the child
  /// process.
  ///
  /// When [allowReentrantFlutter] is set to `true`, the child process is
  /// permitted to call the Flutter tool. By default it is not.
  ///
  /// When [environment] is supplied, it is used as the environment for the child
  /// process.
  ///
  /// When [timeout] is supplied, [runAsync] will kill the child process and
  /// throw a [ProcessException] when it doesn't finish in time.
  ///
  /// If [timeout] is supplied, the command will be retried [timeoutRetries] times
  /// if it times out.
  Future<RunResult> run(
    List<String> cmd, {
    bool throwOnError = false,
    RunResultChecker allowedFailures,
    String workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String> environment,
    Duration timeout,
    int timeoutRetries = 0,
  });

  /// Run the command and block waiting for its result.
  RunResult runSync(
    List<String> cmd, {
    bool throwOnError = false,
    bool verboseExceptions = false,
    RunResultChecker allowedFailures,
    bool hideStdout = false,
    String workingDirectory,
    Map<String, String> environment,
    bool allowReentrantFlutter = false,
    Encoding encoding = systemEncoding,
  });

  /// This runs the command in the background from the specified working
  /// directory. Completes when the process has been started.
  Future<Process> start(
    List<String> cmd, {
    String workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String> environment,
  });

  /// This runs the command and streams stdout/stderr from the child process to
  /// this process' stdout/stderr. Completes with the process's exit code.
  ///
  /// If [filter] is null, no lines are removed.
  ///
  /// If [filter] is non-null, all lines that do not match it are removed. If
  /// [mapFunction] is present, all lines that match [filter] are also forwarded
  /// to [mapFunction] for further processing.
  ///
  /// If [stdoutErrorMatcher] is non-null, matching lines from stdout will be
  /// treated as errors, just as if they had been logged to stderr instead.
  Future<int> stream(
    List<String> cmd, {
    String workingDirectory,
    bool allowReentrantFlutter = false,
    String prefix = '',
    bool trace = false,
    RegExp filter,
    RegExp stdoutErrorMatcher,
    StringConverter mapFunction,
    Map<String, String> environment,
  });

  bool exitsHappySync(
    List<String> cli, {
    Map<String, String> environment,
  });

  Future<bool> exitsHappy(
    List<String> cli, {
    Map<String, String> environment,
  });
}

class _DefaultProcessUtils implements ProcessUtils {
  _DefaultProcessUtils({
    @required ProcessManager processManager,
    @required Logger logger,
  }) : _processManager = processManager,
      _logger = logger;

  final ProcessManager _processManager;

  final Logger _logger;

  @override
  Future<RunResult> run(
    List<String> cmd, {
    bool throwOnError = false,
    RunResultChecker allowedFailures,
    String workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String> environment,
    Duration timeout,
    int timeoutRetries = 0,
  }) async {
    if (cmd == null || cmd.isEmpty) {
      throw ArgumentError('cmd must be a non-empty list');
    }
    if (timeoutRetries < 0) {
      throw ArgumentError('timeoutRetries must be non-negative');
    }
    _traceCommand(cmd, workingDirectory: workingDirectory);

    // When there is no timeout, there's no need to kill a running process, so
    // we can just use _processManager.run().
    if (timeout == null) {
      final ProcessResult results = await _processManager.run(
        cmd,
        workingDirectory: workingDirectory,
        environment: _environment(allowReentrantFlutter, environment),
      );
      final RunResult runResult = RunResult(results, cmd);
      _logger.printTrace(runResult.toString());
      if (throwOnError && runResult.exitCode != 0 &&
          (allowedFailures == null || !allowedFailures(runResult.exitCode))) {
        runResult.throwException('Process exited abnormally:\n$runResult');
      }
      return runResult;
    }

    // When there is a timeout, we have to kill the running process, so we have
    // to use _processManager.start() through _runCommand() above.
    while (true) {
      assert(timeoutRetries >= 0);
      timeoutRetries = timeoutRetries - 1;

      final Process process = await start(
          cmd,
          workingDirectory: workingDirectory,
          allowReentrantFlutter: allowReentrantFlutter,
          environment: environment,
      );

      final StringBuffer stdoutBuffer = StringBuffer();
      final StringBuffer stderrBuffer = StringBuffer();
      final Future<void> stdoutFuture = process.stdout
          .transform<String>(const Utf8Decoder(reportErrors: false))
          .listen(stdoutBuffer.write)
          .asFuture<void>(null);
      final Future<void> stderrFuture = process.stderr
          .transform<String>(const Utf8Decoder(reportErrors: false))
          .listen(stderrBuffer.write)
          .asFuture<void>(null);

      int exitCode;
      exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
        // The process timed out. Kill it.
        _processManager.killPid(process.pid);
        return null;
      });

      String stdoutString;
      String stderrString;
      try {
        Future<void> stdioFuture =
            Future.wait<void>(<Future<void>>[stdoutFuture, stderrFuture]);
        if (exitCode == null) {
          // If we had to kill the process for a timeout, only wait a short time
          // for the stdio streams to drain in case killing the process didn't
          // work.
          stdioFuture = stdioFuture.timeout(const Duration(seconds: 1));
        }
        await stdioFuture;
      } on Exception catch (_) {
        // Ignore errors on the process' stdout and stderr streams. Just capture
        // whatever we got, and use the exit code
      }
      stdoutString = stdoutBuffer.toString();
      stderrString = stderrBuffer.toString();

      final ProcessResult result = ProcessResult(
          process.pid, exitCode ?? -1, stdoutString, stderrString);
      final RunResult runResult = RunResult(result, cmd);

      // If the process did not timeout. We are done.
      if (exitCode != null) {
        _logger.printTrace(runResult.toString());
        if (throwOnError && runResult.exitCode != 0 &&
            (allowedFailures == null || !allowedFailures(exitCode))) {
          runResult.throwException('Process exited abnormally:\n$runResult');
        }
        return runResult;
      }

      // If we are out of timeoutRetries, throw a ProcessException.
      if (timeoutRetries < 0) {
        runResult.throwException('Process timed out:\n$runResult');
      }

      // Log the timeout with a trace message in verbose mode.
      _logger.printTrace(
        'Process "${cmd[0]}" timed out. $timeoutRetries attempts left:\n'
        '$runResult',
      );
    }

    // Unreachable.
  }

  @override
  RunResult runSync(
    List<String> cmd, {
    bool throwOnError = false,
    bool verboseExceptions = false,
    RunResultChecker allowedFailures,
    bool hideStdout = false,
    String workingDirectory,
    Map<String, String> environment,
    bool allowReentrantFlutter = false,
    Encoding encoding = systemEncoding,
  }) {
    _traceCommand(cmd, workingDirectory: workingDirectory);
    final ProcessResult results = _processManager.runSync(
      cmd,
      workingDirectory: workingDirectory,
      environment: _environment(allowReentrantFlutter, environment),
      stderrEncoding: encoding,
      stdoutEncoding: encoding,
    );
    final RunResult runResult = RunResult(results, cmd);

    _logger.printTrace('Exit code ${runResult.exitCode} from: ${cmd.join(' ')}');

    bool failedExitCode = runResult.exitCode != 0;
    if (allowedFailures != null && failedExitCode) {
      failedExitCode = !allowedFailures(runResult.exitCode);
    }

    if (runResult.stdout.isNotEmpty && !hideStdout) {
      if (failedExitCode && throwOnError) {
        _logger.printStatus(runResult.stdout.trim());
      } else {
        _logger.printTrace(runResult.stdout.trim());
      }
    }

    if (runResult.stderr.isNotEmpty) {
      if (failedExitCode && throwOnError) {
        _logger.printError(runResult.stderr.trim());
      } else {
        _logger.printTrace(runResult.stderr.trim());
      }
    }

    if (failedExitCode && throwOnError) {
      String message = 'The command failed';
      if (verboseExceptions) {
        message = 'The command failed\nStdout:\n${runResult.stdout}\n'
            'Stderr:\n${runResult.stderr}';
      }
      runResult.throwException(message);
    }

    return runResult;
  }

  @override
  Future<Process> start(
    List<String> cmd, {
    String workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String> environment,
  }) {
    _traceCommand(cmd, workingDirectory: workingDirectory);
    return _processManager.start(
      cmd,
      workingDirectory: workingDirectory,
      environment: _environment(allowReentrantFlutter, environment),
    );
  }

  @override
  Future<int> stream(
    List<String> cmd, {
    String workingDirectory,
    bool allowReentrantFlutter = false,
    String prefix = '',
    bool trace = false,
    RegExp filter,
    RegExp stdoutErrorMatcher,
    StringConverter mapFunction,
    Map<String, String> environment,
  }) async {
    final Process process = await start(
      cmd,
      workingDirectory: workingDirectory,
      allowReentrantFlutter: allowReentrantFlutter,
      environment: environment,
    );
    final StreamSubscription<String> stdoutSubscription = process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .where((String line) => filter == null || filter.hasMatch(line))
      .listen((String line) {
        if (mapFunction != null) {
          line = mapFunction(line);
        }
        if (line != null) {
          final String message = '$prefix$line';
          if (stdoutErrorMatcher?.hasMatch(line) == true) {
            _logger.printError(message, wrap: false);
          } else if (trace) {
            _logger.printTrace(message);
          } else {
            _logger.printStatus(message, wrap: false);
          }
        }
      });
    final StreamSubscription<String> stderrSubscription = process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .where((String line) => filter == null || filter.hasMatch(line))
      .listen((String line) {
        if (mapFunction != null) {
          line = mapFunction(line);
        }
        if (line != null) {
          _logger.printError('$prefix$line', wrap: false);
        }
      });

    // Wait for stdout to be fully processed
    // because process.exitCode may complete first causing flaky tests.
    await Future.wait<void>(<Future<void>>[
      stdoutSubscription.asFuture<void>(),
      stderrSubscription.asFuture<void>(),
    ]);

    // The streams as futures have already completed, so waiting for the
    // potentially async stream cancellation to complete likely has no benefit.
    // Further, some Stream implementations commonly used in tests don't
    // complete the Future returned here, which causes tests using
    // mocks/FakeAsync to fail when these Futures are awaited.
    unawaited(stdoutSubscription.cancel());
    unawaited(stderrSubscription.cancel());

    return await process.exitCode;
  }

  @override
  bool exitsHappySync(
    List<String> cli, {
    Map<String, String> environment,
  }) {
    _traceCommand(cli);
    if (!_processManager.canRun(cli.first)) {
      _logger.printTrace('$cli either does not exist or is not executable.');
      return false;
    }

    try {
      return _processManager.runSync(cli, environment: environment).exitCode == 0;
    } on Exception catch (error) {
      _logger.printTrace('$cli failed with $error');
      return false;
    }
  }

  @override
  Future<bool> exitsHappy(
    List<String> cli, {
    Map<String, String> environment,
  }) async {
    _traceCommand(cli);
    if (!_processManager.canRun(cli.first)) {
      _logger.printTrace('$cli either does not exist or is not executable.');
      return false;
    }

    try {
      return (await _processManager.run(cli, environment: environment)).exitCode == 0;
    } on Exception catch (error) {
      _logger.printTrace('$cli failed with $error');
      return false;
    }
  }

  Map<String, String> _environment(bool allowReentrantFlutter, [
    Map<String, String> environment,
  ]) {
    if (allowReentrantFlutter) {
      if (environment == null) {
        environment = <String, String>{'FLUTTER_ALREADY_LOCKED': 'true'};
      } else {
        environment['FLUTTER_ALREADY_LOCKED'] = 'true';
      }
    }

    return environment;
  }

  void _traceCommand(List<String> args, { String workingDirectory }) {
    final String argsText = args.join(' ');
    if (workingDirectory == null) {
      _logger.printTrace('executing: $argsText');
    } else {
      _logger.printTrace('executing: [$workingDirectory/] $argsText');
    }
  }
}

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
  ///     mgr.start('grep', ['-i', 'main', 'test.dart']).then((process) {
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
  /// The default value for `mode` is `ProcessStartMode.NORMAL`.
  Future<Process> start(
    List<String> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  });

  /// Starts a process and runs it non-interactively to completion.
  ///
  /// The first element in [command] will be treated as the executable to run,
  /// with subsequent elements being passed as arguments to the executable.
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
    List<String> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  });

  /// Starts a process and runs it to completion. This is a synchronous
  /// call and will block until the child process terminates.
  ///
  /// The arguments are the same as for [run]`.
  ///
  /// Returns a `ProcessResult` with the result of running the process,
  /// i.e., exit code, standard out and standard in.
  ProcessResult runSync(
    List<String> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  });

  /// Returns `true` if the [executable] exists and if it can be executed.
  bool canRun(String executable, {String workingDirectory});

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
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.SIGTERM]);
}

/// A process manager that delegates directly to the dart:io Process class.
class LocalProcessManager implements ProcessManager {
  const LocalProcessManager({
    @visibleForTesting FileSystem fileSystem = const local_fs.LocalFileSystem(),
    @visibleForTesting Platform platform = const LocalPlatform(),
  }) : _platform = platform,
       _fileSystem = fileSystem;

  final Platform _platform;
  final FileSystem _fileSystem;

  @override
  bool canRun(String executable, {String workingDirectory}) {
    return getExecutablePath(executable, workingDirectory, platform: _platform, fileSystem: _fileSystem) != null;
  }

  @override
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.SIGTERM]) {
    return signal.send(pid);
  }

  @override
  Future<ProcessResult> run(List<String> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) {
    return Process.run(
      sanitizeExecutablePath(_getExecutable(
        command,
        workingDirectory,
        runInShell,
      ), platform: _platform),
      _getArguments(command),
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      stdoutEncoding: systemEncoding,
      stderrEncoding: systemEncoding,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );
  }

  @override
  ProcessResult runSync(List<String> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) {
    return Process.runSync(
      sanitizeExecutablePath(_getExecutable(
        command,
        workingDirectory,
        runInShell,
      ), platform: _platform),
      _getArguments(command),
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      stdoutEncoding: systemEncoding,
      stderrEncoding: systemEncoding,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );
  }

  @override
  Future<Process> start(
    List<String> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    return Process.start(
      sanitizeExecutablePath(_getExecutable(
        command,
        workingDirectory,
        runInShell,
      ), platform: _platform),
      _getArguments(command),
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
  }

  String _getExecutable(
    List<String> command,
    String workingDirectory,
    bool runInShell,
  ) {
    final String commandName = command.first.toString();
    if (runInShell) {
      return commandName;
    }
    final String executable = getExecutablePath(commandName, workingDirectory, platform: _platform, fileSystem: _fileSystem);
    if (executable == null) {
      throw ArgumentError('Could not resolve $commandName to executablePath in $workingDirectory');
    }
    return executable;
  }

  List<String> _getArguments(
    List<String> command,
  ) {
    return command.skip(1).toList();
  }
}

/// Sanatizes the executable path on Windows.
/// https://github.com/dart-lang/sdk/issues/37751
String sanitizeExecutablePath(String executable, {@required Platform platform }) {
  if (executable.isEmpty) {
    return executable;
  }
  if (!platform.isWindows) {
    return executable;
  }
  if (executable.contains(' ') && !executable.contains('"')) {
    // Use quoted strings to indicate where the file name ends and the arguments begin;
    // otherwise, the file name is ambiguous.
    return '"$executable"';
  }
  return executable;
}

/// Searches the `PATH` for the executable that [command] is supposed to launch.
///
/// This first builds a list of candidate paths where the executable may reside.
/// If [command] is already an absolute path, then the `PATH` environment
/// variable will not be consulted, and the specified absolute path will be the
/// only candidate that is considered.
///
/// Once the list of candidate paths has been constructed, this will pick the
/// first such path that represents an existent file.
///
/// Return `null` if there were no viable candidates, meaning the executable
/// could not be found.
///
/// If [platform] is not specified, it will default to the current platform.
@visibleForTesting
String getExecutablePath(
  String command,
  String workingDirectory, {
  @required Platform platform,
  @required FileSystem fileSystem,
}) {
  try {
    workingDirectory ??= fileSystem.currentDirectory.path;
  } on FileSystemException {
    // The `currentDirectory` getter can throw a FileSystemException for example
    // when the process doesn't have read/list permissions in each component of
    // the cwd path. In this case, fall back on '.'.
    workingDirectory ??= '.';
  }
  final String pathSeparator = platform.isWindows ? ';' : ':';

  List<String> extensions = <String>[];
  if (platform.isWindows && fileSystem.path.extension(command).isEmpty) {
    extensions = platform.environment['PATHEXT'].split(pathSeparator);
  }

  List<String> candidates = <String>[];
  if (command.contains(fileSystem.path.separator)) {
    candidates = _getCandidatePaths(
        command, <String>[workingDirectory], extensions, fileSystem);
  } else {
    final List<String> searchPath = platform.environment['PATH'].split(pathSeparator);
    candidates = _getCandidatePaths(command, searchPath, extensions, fileSystem);
  }
  for (final String path in candidates) {
    if (fileSystem.file(path).existsSync()) {
      return path;
    }
  }
  return null;
}

/// Returns all possible combinations of `$searchPath\$command.$ext` for
/// `searchPath` in [searchPaths] and `ext` in [extensions].
///
/// If [extensions] is empty, it will just enumerate all
/// `$searchPath\$command`.
/// If [command] is an absolute path, it will just enumerate
/// `$command.$ext`.
List<String> _getCandidatePaths(
  String command,
  List<String> searchPaths,
  List<String> extensions,
  FileSystem fileSystem,
) {
  final List<String> withExtensions = extensions.isNotEmpty
      ? extensions.map((String ext) => '$command$ext').toList()
      : <String>[command];
  if (fileSystem.path.isAbsolute(command)) {
    return withExtensions;
  }
  return searchPaths
      .map((String path) =>
          withExtensions.map((String command) => fileSystem.path.join(path, command)))
      .expand((Iterable<String> e) => e)
      .toList()
      .cast<String>();
}
