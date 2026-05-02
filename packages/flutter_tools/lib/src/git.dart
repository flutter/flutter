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
  RunResult logSync(List<String> arguments, {String? workingDirectory}) {
    assert(arguments.isEmpty || arguments.first != 'log');
    return runSync([
      ..._ignoreLogShowSignature,
      'log',
      ...arguments,
    ], workingDirectory: workingDirectory);
  }

  static const _ignoreLogShowSignature = ['-c', 'log.showSignature=false'];

  /// Spawns a child process to run `git`.
  ///
  /// The arguments are the same as [ProcessUtils.run], except:
  ///
  /// - [arguments] does _not_ include the executable (it is implicit);
  /// - [environment] may include additional (implicit) platform-specific variables
  Future<RunResult> run(
    List<String> arguments, {
    bool throwOnError = false,
    RunResultChecker? allowedFailures,
    String? workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String>? environment,
    Duration? timeout,
    int timeoutRetries = 0,
  }) {
    return _processUtils.run(
      [_pathToGitExecutable, ...arguments],
      throwOnError: throwOnError,
      allowedFailures: allowedFailures,
      workingDirectory: workingDirectory,
      allowReentrantFlutter: allowReentrantFlutter,
      environment: _environment(environment),
      includeParentEnvironment: false,
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
  RunResult runSync(
    List<String> arguments, {
    bool throwOnError = false,
    bool verboseExceptions = false,
    RunResultChecker? allowedFailures,
    bool hideStdout = false,
    String? workingDirectory,
    Map<String, String>? environment,
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
      environment: _environment(environment),
      includeParentEnvironment: false,
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
      environment: _environment(environment),
      includeParentEnvironment: false,
    );
  }

  Map<String, String> _environment(Map<String, String>? environment) {
    return <String, String>{
      ..._platform.environment,
      if (_platform.isWindows) ..._useNoGlobCygwinGit,
      ...?environment,
    }..removeWhere(
      (String key, _) => _repositoryLocalEnvironmentVariables.contains(key.toUpperCase()),
    );
  }

  // Repository-local Git environment variables can be exported by Git hooks.
  // Flutter's internal git commands operate on explicit working directories
  // and must not inherit another repository's git context.
  static const _repositoryLocalEnvironmentVariables = <String>{
    'GIT_ALTERNATE_OBJECT_DIRECTORIES',
    'GIT_CONFIG',
    'GIT_CONFIG_PARAMETERS',
    'GIT_CONFIG_COUNT',
    'GIT_OBJECT_DIRECTORY',
    'GIT_DIR',
    'GIT_WORK_TREE',
    'GIT_IMPLICIT_WORK_TREE',
    'GIT_GRAFT_FILE',
    'GIT_INDEX_FILE',
    'GIT_NO_REPLACE_OBJECTS',
    'GIT_REPLACE_REF_BASE',
    'GIT_PREFIX',
    'GIT_SHALLOW_FILE',
    'GIT_COMMON_DIR',
  };

  static const _useNoGlobCygwinGit = {'MSYS': 'noglob', 'CYGWIN': 'noglob'};
}
