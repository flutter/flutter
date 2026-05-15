// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/io.dart';
import 'base/platform.dart';
import 'base/process.dart';
import 'convert.dart';

/// Wrapper around the command-line `git` executable on the host.
interface class Git {
  /// Creates a wrapper that executes `git` using [runProcessWith].
  Git({
    required Platform currentPlatform,
    required ProcessUtils runProcessWith,
    String executable = 'git',
  }) : _platform = currentPlatform,
       _processUtils = runProcessWith,
       _pathToGitExecutable = executable;

  final String _pathToGitExecutable;
  final Platform _platform;
  final ProcessUtils _processUtils;

  /// Returns the result of `git log <arguments>`.
  ///
  /// Automatically injects the arguments `-c log.showSignature=false` in order
  /// to ignore user settings that will break the expected output for this call;
  /// otherwise this call is identical to using [Git.runSync] directly.
  RunResult logSync(
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    assert(arguments.isEmpty || arguments.first != 'log');
    return runSync(
      [..._ignoreLogShowSignature, 'log', ...arguments],
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  static const _ignoreLogShowSignature = ['-c', 'log.showSignature=false'];

  /// Environment variables that can interfere with git commands when targeting
  /// the Flutter SDK.
  static const List<String> _kGitEnvironmentVariables = <String>[
    'GIT_DIR',
    'GIT_INDEX_FILE',
    'GIT_WORK_TREE',
    'GIT_OBJECT_DIRECTORY',
    'GIT_ALTERNATE_OBJECT_DIRECTORIES',
    'GIT_QUARANTINE_PATH',
  ];

  Map<String, String> _filterEnvironment(Map<String, String>? environment, bool includeGitEnv) {
    final result = Map<String, String>.from(environment ?? _platform.environment);
    if (!includeGitEnv) {
      _kGitEnvironmentVariables.forEach(result.remove);
    }
    if (_platform.isWindows) {
      result.addAll(_useNoGlobCygwinGit);
    }
    return result;
  }

  /// Spawns a child process to run `git`.
  ///
  /// The arguments are the same as [ProcessUtils.run], except:
  ///
  /// - [arguments] does _not_ include the executable (it is implicit);
  /// - [environment] may include additional (implicit) platform-specific variables
  /// - [includeGitEnv] whether to include inherited GIT_* environment variables.
  ///   Defaults to false to avoid poisoning SDK-related commands with app-repo
  ///   context.
  Future<RunResult> run(
    List<String> arguments, {
    bool throwOnError = false,
    RunResultChecker? allowedFailures,
    String? workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String>? environment,
    bool includeGitEnv = false,
    Duration? timeout,
    int timeoutRetries = 0,
  }) {
    return _processUtils.run(
      [_pathToGitExecutable, ...arguments],
      throwOnError: throwOnError,
      allowedFailures: allowedFailures,
      workingDirectory: workingDirectory,
      allowReentrantFlutter: allowReentrantFlutter,
      environment: _filterEnvironment(environment, includeGitEnv),
      timeout: timeout,
      timeoutRetries: timeoutRetries,
    );
  }

  /// Runs a command using `git` and blocks waiting for its result.
  ///
  /// The arguments are the same as [ProcessUtils.runSync], except:
  ///
  /// - [arguments] does _not_ include the executable (it is implicit);
  /// - [environment] may include additional (implicit) platform-specific variables
  /// - [includeGitEnv] whether to include inherited GIT_* environment variables.
  ///   Defaults to false to avoid poisoning SDK-related commands with app-repo
  ///   context.
  RunResult runSync(
    List<String> arguments, {
    bool throwOnError = false,
    bool verboseExceptions = false,
    RunResultChecker? allowedFailures,
    bool hideStdout = false,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeGitEnv = false,
    bool allowReentrantFlutter = false,
    Encoding encoding = systemEncoding,
  }) {
    return _processUtils.runSync(
      [_pathToGitExecutable, ...arguments],
      throwOnError: throwOnError,
      verboseExceptions: verboseExceptions,
      allowedFailures: allowedFailures,
      hideStdout: hideStdout,
      workingDirectory: workingDirectory,
      environment: _filterEnvironment(environment, includeGitEnv),
      allowReentrantFlutter: allowReentrantFlutter,
      encoding: encoding,
    );
  }

  /// Spawns a child process to run `git` and streams the result to stdout/err.
  ///
  /// The arguments are the same as [ProcessUtils.stream], except:
  ///
  /// - [arguments] does _not_ include the executable (it is implicit);
  /// - [environment] may include additional (implicit) platform-specific variables
  /// - [includeGitEnv] whether to include inherited GIT_* environment variables.
  ///   Defaults to false to avoid poisoning SDK-related commands with app-repo
  ///   context.
  Future<int> stream(
    List<String> arguments, {
    String? workingDirectory,
    bool allowReentrantFlutter = false,
    String prefix = '',
    bool trace = false,
    RegExp? filter,
    RegExp? stdoutErrorMatcher,
    StringConverter? mapFunction,
    Map<String, String>? environment,
    bool includeGitEnv = false,
  }) {
    assert(arguments.isEmpty || arguments.first != 'git');
    return _processUtils.stream(
      [_pathToGitExecutable, ...arguments],
      workingDirectory: workingDirectory,
      allowReentrantFlutter: allowReentrantFlutter,
      prefix: prefix,
      trace: trace,
      filter: filter,
      stdoutErrorMatcher: stdoutErrorMatcher,
      mapFunction: mapFunction,
      environment: _filterEnvironment(environment, includeGitEnv),
    );
  }

  static const _useNoGlobCygwinGit = {'MSYS': 'noglob', 'CYGWIN': 'noglob'};
}
