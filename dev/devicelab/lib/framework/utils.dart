// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:stack_trace/stack_trace.dart';

/// Virtual current working directory, which affect functions, such as [exec].
String cwd = Directory.current.path;

/// The local engine to use for [flutter] and [evalFlutter], if any.
String get localEngine => const String.fromEnvironment('localEngine');

/// The local engine source path to use if a local engine is used for [flutter]
/// and [evalFlutter].
String get localEngineSrcPath => const String.fromEnvironment('localEngineSrcPath');

List<ProcessInfo> _runningProcesses = <ProcessInfo>[];
ProcessManager _processManager = const LocalProcessManager();

class ProcessInfo {
  ProcessInfo(this.command, this.process);

  final DateTime startTime = DateTime.now();
  final String command;
  final Process process;

  @override
  String toString() {
    return '''
  command : $command
  started : $startTime
  pid     : ${process.pid}
'''
        .trim();
  }
}

/// Result of a health check for a specific parameter.
class HealthCheckResult {
  HealthCheckResult.success([this.details]) : succeeded = true;
  HealthCheckResult.failure(this.details) : succeeded = false;
  HealthCheckResult.error(dynamic error, dynamic stackTrace)
      : succeeded = false,
        details = 'ERROR: $error${'\n$stackTrace' ?? ''}';

  final bool succeeded;
  final String details;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer(succeeded ? 'succeeded' : 'failed');
    if (details != null && details.trim().isNotEmpty) {
      buf.writeln();
      // Indent details by 4 spaces
      for (String line in details.trim().split('\n')) {
        buf.writeln('    $line');
      }
    }
    return '$buf';
  }
}

class BuildFailedError extends Error {
  BuildFailedError(this.message);

  final String message;

  @override
  String toString() => message;
}

void fail(String message) {
  throw BuildFailedError(message);
}

// Remove the given file or directory.
void rm(FileSystemEntity entity, { bool recursive = false}) {
  if (entity.existsSync()) {
    // This should not be necessary, but it turns out that
    // on Windows it's common for deletions to fail due to
    // bogus (we think) "access denied" errors.
    try {
      entity.deleteSync(recursive: recursive);
    } on FileSystemException catch (error) {
      print('Failed to delete ${entity.path}: $error');
    }
  }
}

/// Remove recursively.
void rmTree(FileSystemEntity entity) {
  rm(entity, recursive: true);
}

List<FileSystemEntity> ls(Directory directory) => directory.listSync();

Directory dir(String path) => Directory(path);

File file(String path) => File(path);

void copy(File sourceFile, Directory targetDirectory, {String name}) {
  final File target = file(
      path.join(targetDirectory.path, name ?? path.basename(sourceFile.path)));
  target.writeAsBytesSync(sourceFile.readAsBytesSync());
}

void recursiveCopy(Directory source, Directory target) {
  if (!target.existsSync())
    target.createSync();

  for (FileSystemEntity entity in source.listSync(followLinks: false)) {
    final String name = path.basename(entity.path);
    if (entity is Directory)
      recursiveCopy(entity, Directory(path.join(target.path, name)));
    else if (entity is File) {
      final File dest = File(path.join(target.path, name));
      dest.writeAsBytesSync(entity.readAsBytesSync());
      // Preserve executable bit
      final String modes = entity.statSync().modeString();
      if (modes != null && modes.contains('x')) {
        makeExecutable(dest);
      }
    }
  }
}

FileSystemEntity move(FileSystemEntity whatToMove,
    {Directory to, String name}) {
  return whatToMove
      .renameSync(path.join(to.path, name ?? path.basename(whatToMove.path)));
}

/// Equivalent of `chmod a+x file`
void makeExecutable(File file) {
  // Windows files do not have an executable bit
  if (Platform.isWindows) {
    return;
  }
  final ProcessResult result = _processManager.runSync(<String>[
    'chmod',
    'a+x',
    file.path,
  ]);

  if (result.exitCode != 0) {
    throw FileSystemException(
      'Error making ${file.path} executable.\n'
      '${result.stderr}',
      file.path,
    );
  }
}

/// Equivalent of `mkdir directory`.
void mkdir(Directory directory) {
  directory.createSync();
}

/// Equivalent of `mkdir -p directory`.
void mkdirs(Directory directory) {
  directory.createSync(recursive: true);
}

bool exists(FileSystemEntity entity) => entity.existsSync();

void section(String title) {
  title = '╡ ••• $title ••• ╞';
  final String line = '═' * math.max((80 - title.length) ~/ 2, 2);
  String output = '$line$title$line';
  if (output.length == 79)
    output += '═';
  print('\n\n$output\n');
}

Future<String> getDartVersion() async {
  // The Dart VM returns the version text to stderr.
  final ProcessResult result = _processManager.runSync(<String>[dartBin, '--version']);
  String version = result.stderr.trim();

  // Convert:
  //   Dart VM version: 1.17.0-dev.2.0 (Tue May  3 12:14:52 2016) on "macos_x64"
  // to:
  //   1.17.0-dev.2.0
  if (version.contains('('))
    version = version.substring(0, version.indexOf('(')).trim();
  if (version.contains(':'))
    version = version.substring(version.indexOf(':') + 1).trim();

  return version.replaceAll('"', "'");
}

Future<String> getCurrentFlutterRepoCommit() {
  if (!dir('${flutterDirectory.path}/.git').existsSync()) {
    return Future<String>.value(null);
  }

  return inDirectory<String>(flutterDirectory, () {
    return eval('git', <String>['rev-parse', 'HEAD']);
  });
}

Future<DateTime> getFlutterRepoCommitTimestamp(String commit) {
  // git show -s --format=%at 4b546df7f0b3858aaaa56c4079e5be1ba91fbb65
  return inDirectory<DateTime>(flutterDirectory, () async {
    final String unixTimestamp = await eval('git', <String>[
      'show',
      '-s',
      '--format=%at',
      commit,
    ]);
    final int secondsSinceEpoch = int.parse(unixTimestamp);
    return DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
  });
}

/// Starts a subprocess.
///
/// The first argument is the full path to the executable to run.
///
/// The second argument is the list of arguments to provide on the command line.
/// This argument can be null, indicating no arguments (same as the empty list).
///
/// The `environment` argument can be provided to configure environment variables
/// that will be made available to the subprocess. The `BOT` environment variable
/// is always set and overrides any value provided in the `environment` argument.
/// The `isBot` argument controls the value of the `BOT` variable. It will either
/// be "true", if `isBot` is true (the default), or "false" if it is false.
///
/// The `BOT` variable is in particular used by the `flutter` tool to determine
/// how verbose to be and whether to enable analytics by default.
///
/// The working directory can be provided using the `workingDirectory` argument.
/// By default it will default to the current working directory (see [cwd]).
///
/// Information regarding the execution of the subprocess is printed to the
/// console.
///
/// The actual process executes asynchronously. A handle to the subprocess is
/// returned in the form of a [Future] that completes to a [Process] object.
Future<Process> startProcess(
  String executable,
  List<String> arguments, {
  Map<String, String> environment,
  bool isBot = true, // set to false to pretend not to be on a bot (e.g. to test user-facing outputs)
  String workingDirectory,
}) async {
  assert(isBot != null);
  final String command = '$executable ${arguments?.join(" ") ?? ""}';
  print('\nExecuting: $command');
  environment ??= <String, String>{};
  environment['BOT'] = isBot ? 'true' : 'false';
  final Process process = await _processManager.start(
    <String>[executable, ...arguments],
    environment: environment,
    workingDirectory: workingDirectory ?? cwd,
  );
  final ProcessInfo processInfo = ProcessInfo(command, process);
  _runningProcesses.add(processInfo);

  process.exitCode.then<void>((int exitCode) {
    print('"$executable" exit code: $exitCode');
    _runningProcesses.remove(processInfo);
  });

  return process;
}

Future<void> forceQuitRunningProcesses() async {
  if (_runningProcesses.isEmpty)
    return;

  // Give normally quitting processes a chance to report their exit code.
  await Future<void>.delayed(const Duration(seconds: 1));

  // Whatever's left, kill it.
  for (ProcessInfo p in _runningProcesses) {
    print('Force-quitting process:\n$p');
    if (!p.process.kill()) {
      print('Failed to force quit process');
    }
  }
  _runningProcesses.clear();
}

/// Executes a command and returns its exit code.
Future<int> exec(
  String executable,
  List<String> arguments, {
  Map<String, String> environment,
  bool canFail = false, // as in, whether failures are ok. False means that they are fatal.
  String workingDirectory,
}) async {
  final Process process = await startProcess(executable, arguments, environment: environment, workingDirectory: workingDirectory);

  final Completer<void> stdoutDone = Completer<void>();
  final Completer<void> stderrDone = Completer<void>();
  process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        print('stdout: $line');
      }, onDone: () { stdoutDone.complete(); });
  process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        print('stderr: $line');
      }, onDone: () { stderrDone.complete(); });

  await Future.wait<void>(<Future<void>>[stdoutDone.future, stderrDone.future]);
  final int exitCode = await process.exitCode;

  if (exitCode != 0 && !canFail)
    fail('Executable "$executable" failed with exit code $exitCode.');

  return exitCode;
}

/// Executes a command and returns its standard output as a String.
///
/// For logging purposes, the command's output is also printed out by default.
Future<String> eval(
  String executable,
  List<String> arguments, {
  Map<String, String> environment,
  bool canFail = false, // as in, whether failures are ok. False means that they are fatal.
  String workingDirectory,
  StringBuffer stderr, // if not null, the stderr will be written here
  bool printStdout = true,
  bool printStderr = true,
}) async {
  final Process process = await startProcess(executable, arguments, environment: environment, workingDirectory: workingDirectory);

  final StringBuffer output = StringBuffer();
  final Completer<void> stdoutDone = Completer<void>();
  final Completer<void> stderrDone = Completer<void>();
  process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        if (printStdout) {
          print('stdout: $line');
        }
        output.writeln(line);
      }, onDone: () { stdoutDone.complete(); });
  process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        if (printStderr) {
          print('stderr: $line');
        }
        stderr?.writeln(line);
      }, onDone: () { stderrDone.complete(); });

  await Future.wait<void>(<Future<void>>[stdoutDone.future, stderrDone.future]);
  final int exitCode = await process.exitCode;

  if (exitCode != 0 && !canFail)
    fail('Executable "$executable" failed with exit code $exitCode.');

  return output.toString().trimRight();
}

List<String> flutterCommandArgs(String command, List<String> options) {
  return <String>[
    command,
    if (localEngine != null) ...<String>['--local-engine', localEngine],
    if (localEngineSrcPath != null) ...<String>['--local-engine-src-path', localEngineSrcPath],
    ...options,
  ];
}

Future<int> flutter(String command, {
  List<String> options = const <String>[],
  bool canFail = false, // as in, whether failures are ok. False means that they are fatal.
  Map<String, String> environment,
}) {
  final List<String> args = flutterCommandArgs(command, options);
  return exec(path.join(flutterDirectory.path, 'bin', 'flutter'), args,
      canFail: canFail, environment: environment);
}

/// Runs a `flutter` command and returns the standard output as a string.
Future<String> evalFlutter(String command, {
  List<String> options = const <String>[],
  bool canFail = false, // as in, whether failures are ok. False means that they are fatal.
  Map<String, String> environment,
  StringBuffer stderr, // if not null, the stderr will be written here.
}) {
  final List<String> args = flutterCommandArgs(command, options);
  return eval(path.join(flutterDirectory.path, 'bin', 'flutter'), args,
      canFail: canFail, environment: environment, stderr: stderr);
}

String get dartBin =>
    path.join(flutterDirectory.path, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');

Future<int> dart(List<String> args) => exec(dartBin, args);

/// Returns a future that completes with a path suitable for JAVA_HOME
/// or with null, if Java cannot be found.
Future<String> findJavaHome() async {
  final Iterable<String> hits = grep(
    'Java binary at: ',
    from: await evalFlutter('doctor', options: <String>['-v']),
  );
  if (hits.isEmpty)
    return null;
  final String javaBinary = hits.first.split(': ').last;
  // javaBinary == /some/path/to/java/home/bin/java
  return path.dirname(path.dirname(javaBinary));
}

Future<T> inDirectory<T>(dynamic directory, Future<T> action()) async {
  final String previousCwd = cwd;
  try {
    cd(directory);
    return await action();
  } finally {
    cd(previousCwd);
  }
}

void cd(dynamic directory) {
  Directory d;
  if (directory is String) {
    cwd = directory;
    d = dir(directory);
  } else if (directory is Directory) {
    cwd = directory.path;
    d = directory;
  } else {
    throw 'Unsupported type ${directory.runtimeType} of $directory';
  }

  if (!d.existsSync())
    throw 'Cannot cd into directory that does not exist: $directory';
}

Directory get flutterDirectory => dir('../..').absolute;

String requireEnvVar(String name) {
  final String value = Platform.environment[name];

  if (value == null)
    fail('$name environment variable is missing. Quitting.');

  return value;
}

T requireConfigProperty<T>(Map<String, dynamic> map, String propertyName) {
  if (!map.containsKey(propertyName))
    fail('Configuration property not found: $propertyName');
  final T result = map[propertyName];
  return result;
}

String jsonEncode(dynamic data) {
  return const JsonEncoder.withIndent('  ').convert(data) + '\n';
}

Future<void> getFlutter(String revision) async {
  section('Get Flutter!');

  if (exists(flutterDirectory)) {
    flutterDirectory.deleteSync(recursive: true);
  }

  await inDirectory<void>(flutterDirectory.parent, () async {
    await exec('git', <String>['clone', 'https://github.com/flutter/flutter.git']);
  });

  await inDirectory<void>(flutterDirectory, () async {
    await exec('git', <String>['checkout', revision]);
  });

  await flutter('config', options: <String>['--no-analytics']);

  section('flutter doctor');
  await flutter('doctor');

  section('flutter update-packages');
  await flutter('update-packages');
}

void checkNotNull(Object o1,
    [Object o2 = 1,
    Object o3 = 1,
    Object o4 = 1,
    Object o5 = 1,
    Object o6 = 1,
    Object o7 = 1,
    Object o8 = 1,
    Object o9 = 1,
    Object o10 = 1]) {
  if (o1 == null)
    throw 'o1 is null';
  if (o2 == null)
    throw 'o2 is null';
  if (o3 == null)
    throw 'o3 is null';
  if (o4 == null)
    throw 'o4 is null';
  if (o5 == null)
    throw 'o5 is null';
  if (o6 == null)
    throw 'o6 is null';
  if (o7 == null)
    throw 'o7 is null';
  if (o8 == null)
    throw 'o8 is null';
  if (o9 == null)
    throw 'o9 is null';
  if (o10 == null)
    throw 'o10 is null';
}

/// Splits [from] into lines and selects those that contain [pattern].
Iterable<String> grep(Pattern pattern, {@required String from}) {
  return from.split('\n').where((String line) {
    return line.contains(pattern);
  });
}

/// Captures asynchronous stack traces thrown by [callback].
///
/// This is a convenience wrapper around [Chain] optimized for use with
/// `async`/`await`.
///
/// Example:
///
///     try {
///       await captureAsyncStacks(() { /* async things */ });
///     } catch (error, chain) {
///
///     }
Future<void> runAndCaptureAsyncStacks(Future<void> callback()) {
  final Completer<void> completer = Completer<void>();
  Chain.capture(() async {
    await callback();
    completer.complete();
  }, onError: completer.completeError);
  return completer.future;
}

bool canRun(String path) => _processManager.canRun(path);

String extractCloudAuthTokenArg(List<String> rawArgs) {
  final ArgParser argParser = ArgParser()..addOption('cloud-auth-token');
  ArgResults args;
  try {
    args = argParser.parse(rawArgs);
  } on FormatException catch (error) {
    stderr.writeln('${error.message}\n');
    stderr.writeln('Usage:\n');
    stderr.writeln(argParser.usage);
    return null;
  }

  final String token = args['cloud-auth-token'];
  if (token == null) {
    stderr.writeln('Required option --cloud-auth-token not found');
    return null;
  }
  return token;
}

final RegExp _obsRegExp =
  RegExp('An Observatory debugger .* is available at: ');
final RegExp _obsPortRegExp = RegExp('(\\S+:(\\d+)/\\S*)\$');
final RegExp _obsUriRegExp = RegExp('((http|\/\/)[a-zA-Z0-9:/=_\\-\.\\[\\]]+)');

/// Tries to extract a port from the string.
///
/// The `prefix`, if specified, is a regular expression pattern and must not contain groups.
/// `prefix` defaults to the RegExp: `An Observatory debugger .* is available at: `.
int parseServicePort(String line, {
  Pattern prefix,
}) {
  prefix ??= _obsRegExp;
  final Iterable<Match> matchesIter = prefix.allMatches(line);
  if (matchesIter.isEmpty) {
    return null;
  }
  final Match prefixMatch = matchesIter.first;
  final List<Match> matches =
    _obsPortRegExp.allMatches(line, prefixMatch.end).toList();
  return matches.isEmpty ? null : int.parse(matches[0].group(2));
}

/// Tries to extract a Uri from the string.
///
/// The `prefix`, if specified, is a regular expression pattern and must not contain groups.
/// `prefix` defaults to the RegExp: `An Observatory debugger .* is available at: `.
Uri parseServiceUri(String line, {
  Pattern prefix,
}) {
  prefix ??= _obsRegExp;
  final Iterable<Match> matchesIter = prefix.allMatches(line);
  if (matchesIter.isEmpty) {
    return null;
  }
  final Match prefixMatch = matchesIter.first;
  final List<Match> matches =
    _obsUriRegExp.allMatches(line, prefixMatch.end).toList();
  return matches.isEmpty ? null : Uri.parse(matches[0].group(0));
}

/// Checks that the file exists, otherwise throws a [FileSystemException].
void checkFileExists(String file) {
  if (!exists(File(file))) {
    throw FileSystemException('Expected file to exit.', file);
  }
}
