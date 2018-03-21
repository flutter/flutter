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

import 'adb.dart';

/// Virtual current working directory, which affect functions, such as [exec].
String cwd = Directory.current.path;

List<ProcessInfo> _runningProcesses = <ProcessInfo>[];
ProcessManager _processManager = const LocalProcessManager();

class ProcessInfo {
  ProcessInfo(this.command, this.process);

  final DateTime startTime = new DateTime.now();
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
    final StringBuffer buf = new StringBuffer(succeeded ? 'succeeded' : 'failed');
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
  throw new BuildFailedError(message);
}

void rm(FileSystemEntity entity) {
  if (entity.existsSync())
    entity.deleteSync();
}

/// Remove recursively.
void rmTree(FileSystemEntity entity) {
  if (entity.existsSync())
    entity.deleteSync(recursive: true);
}

List<FileSystemEntity> ls(Directory directory) => directory.listSync();

Directory dir(String path) => new Directory(path);

File file(String path) => new File(path);

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
      recursiveCopy(entity, new Directory(path.join(target.path, name)));
    else if (entity is File) {
      final File dest = new File(path.join(target.path, name));
      dest.writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}

FileSystemEntity move(FileSystemEntity whatToMove,
    {Directory to, String name}) {
  return whatToMove
      .renameSync(path.join(to.path, name ?? path.basename(whatToMove.path)));
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
    return null;
  }

  return inDirectory(flutterDirectory, () {
    return eval('git', <String>['rev-parse', 'HEAD']);
  });
}

Future<DateTime> getFlutterRepoCommitTimestamp(String commit) {
  // git show -s --format=%at 4b546df7f0b3858aaaa56c4079e5be1ba91fbb65
  return inDirectory(flutterDirectory, () async {
    final String unixTimestamp = await eval('git', <String>[
      'show',
      '-s',
      '--format=%at',
      commit,
    ]);
    final int secondsSinceEpoch = int.parse(unixTimestamp);
    return new DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
  });
}

Future<Process> startProcess(
  String executable,
  List<String> arguments, {
  Map<String, String> environment,
  String workingDirectory,
}) async {
  final String command = '$executable ${arguments?.join(" ") ?? ""}';
  print('\nExecuting: $command');
  environment ??= <String, String>{};
  environment['BOT'] = 'true';
  final Process process = await _processManager.start(
    <String>[executable]..addAll(arguments),
    environment: environment,
    workingDirectory: workingDirectory ?? cwd,
  );
  final ProcessInfo processInfo = new ProcessInfo(command, process);
  _runningProcesses.add(processInfo);

  process.exitCode.then((int exitCode) {
    print('exitcode: $exitCode');
    _runningProcesses.remove(processInfo);
  });

  return process;
}

Future<Null> forceQuitRunningProcesses() async {
  if (_runningProcesses.isEmpty)
    return;

  // Give normally quitting processes a chance to report their exit code.
  await new Future<Null>.delayed(const Duration(seconds: 1));

  // Whatever's left, kill it.
  for (ProcessInfo p in _runningProcesses) {
    print('Force quitting process:\n$p');
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
  bool canFail: false,
}) async {
  final Process process = await startProcess(executable, arguments, environment: environment);

  final Completer<Null> stdoutDone = new Completer<Null>();
  final Completer<Null> stderrDone = new Completer<Null>();
  process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        print('stdout: $line');
      }, onDone: () { stdoutDone.complete(); });
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        print('stderr: $line');
      }, onDone: () { stderrDone.complete(); });

  await Future.wait<Null>(<Future<Null>>[stdoutDone.future, stderrDone.future]);
  final int exitCode = await process.exitCode;

  if (exitCode != 0 && !canFail)
    fail('Executable failed with exit code $exitCode.');

  return exitCode;
}

/// Executes a command and returns its standard output as a String.
///
/// For logging purposes, the command's output is also printed out.
Future<String> eval(
  String executable,
  List<String> arguments, {
  Map<String, String> environment,
  bool canFail: false,
}) async {
  final Process process = await startProcess(executable, arguments, environment: environment);

  final StringBuffer output = new StringBuffer();
  final Completer<Null> stdoutDone = new Completer<Null>();
  final Completer<Null> stderrDone = new Completer<Null>();
  process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        print('stdout: $line');
        output.writeln(line);
      }, onDone: () { stdoutDone.complete(); });
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        print('stderr: $line');
      }, onDone: () { stderrDone.complete(); });

  await Future.wait<Null>(<Future<Null>>[stdoutDone.future, stderrDone.future]);
  final int exitCode = await process.exitCode;

  if (exitCode != 0 && !canFail)
    fail('Executable failed with exit code $exitCode.');

  return output.toString().trimRight();
}

Future<int> flutter(String command, {
  List<String> options: const <String>[],
  bool canFail: false,
  Map<String, String> environment,
}) {
  final List<String> args = <String>[command]..addAll(options);
  return exec(path.join(flutterDirectory.path, 'bin', 'flutter'), args,
      canFail: canFail, environment: environment);
}

/// Runs a `flutter` command and returns the standard output as a string.
Future<String> evalFlutter(String command, {
  List<String> options: const <String>[],
  bool canFail: false,
  Map<String, String> environment,
}) {
  final List<String> args = <String>[command]..addAll(options);
  return eval(path.join(flutterDirectory.path, 'bin', 'flutter'), args,
      canFail: canFail, environment: environment);
}

String get dartBin =>
    path.join(flutterDirectory.path, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');

Future<int> dart(List<String> args) => exec(dartBin, args);

Future<dynamic> inDirectory(dynamic directory, Future<dynamic> action()) async {
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

Future<Null> getFlutter(String revision) async {
  section('Get Flutter!');

  if (exists(flutterDirectory)) {
    rmTree(flutterDirectory);
  }

  await inDirectory(flutterDirectory.parent, () async {
    await exec('git', <String>['clone', 'https://github.com/flutter/flutter.git']);
  });

  await inDirectory(flutterDirectory, () async {
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
Future<Null> runAndCaptureAsyncStacks(Future<Null> callback()) {
  final Completer<Null> completer = new Completer<Null>();
  Chain.capture(() async {
    await callback();
    completer.complete();
  }, onError: completer.completeError);
  return completer.future;
}

/// Return an unused TCP port number.
Future<int> findAvailablePort() async {
  int port = 20000;
  while (true) {
    try {
      final ServerSocket socket =
          await ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, port);
      await socket.close();
      return port;
    } catch (_) {
      port++;
    }
  }
}

bool canRun(String path) => _processManager.canRun(path);

String extractCloudAuthTokenArg(List<String> rawArgs) {
  final ArgParser argParser = new ArgParser()..addOption('cloud-auth-token');
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

// "An Observatory debugger and profiler on ... is available at: http://127.0.0.1:8100/"
final RegExp _kObservatoryRegExp = new RegExp(r'An Observatory debugger .* is available at: (\S+:(\d+))');

bool lineContainsServicePort(String line) => line.contains(_kObservatoryRegExp);

int parseServicePort(String line) {
  final Match match = _kObservatoryRegExp.firstMatch(line);
  return match == null ? null : int.parse(match.group(2));
}

/// If FLUTTER_ENGINE environment variable is set then we need to pass
/// correct --local-engine setting too.
void setLocalEngineOptionIfNecessary(List<String> options, [String flavor]) {
  if (Platform.environment['FLUTTER_ENGINE'] != null) {
    if (flavor == null) {
      // If engine flavor was not specified explicitly then scan options looking
      // for flags that specify the engine flavor (--release, --profile or
      // --debug). Default flavor to debug if no flags were found.
      const Map<String, String> optionToFlavor = const <String, String>{
        '--release': 'release',
        '--debug': 'debug',
        '--profile': 'profile',
      };

      for (String option in options) {
        flavor = optionToFlavor[option];
        if (flavor != null) {
          break;
        }
      }

      flavor ??= 'debug';
    }

    const Map<DeviceOperatingSystem, String> osNames = const <DeviceOperatingSystem, String>{
      DeviceOperatingSystem.ios: 'ios',
      DeviceOperatingSystem.android: 'android',
    };

    options.add('--local-engine=${osNames[deviceOperatingSystem]}_$flavor');
  }
}
