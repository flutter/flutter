// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//import 'dart:convert';
import 'dart:io';

//import 'package:meta/meta.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:test/test.dart' as test_package show TypeMatcher;

import 'package:dev_tools/stdio.dart';

import 'package:args/args.dart';
//import 'package:process/process.dart';

export 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

// Defines a 'package:test' shim.
// TODO(ianh): Remove this file once https://github.com/dart-lang/matcher/issues/98 is fixed

/// A matcher that compares the type of the actual value to the type argument T.
test_package.TypeMatcher<T> isInstanceOf<T>() => isA<T>();

void tryToDelete(Directory directory) {
  // This should not be necessary, but it turns out that
  // on Windows it's common for deletions to fail due to
  // bogus (we think) "access denied" errors.
  try {
    directory.deleteSync(recursive: true);
  } on FileSystemException catch (error) {
    print('Failed to delete ${directory.path}: $error');
  }
}

Matcher throwsExceptionWith(String messageSubString) {
  return throwsA(
      isA<Exception>().having(
          (Exception e) => e.toString(),
          'description',
          contains(messageSubString),
      ),
  );
}

class TestStdio implements Stdio {
  TestStdio({
    this.verbose = false,
    List<String> stdin,
  }) {
    _stdin = stdin ?? <String>[];
  }

  final StringBuffer _error = StringBuffer();
  String get error => _error.toString();

  final StringBuffer _stdout = StringBuffer();
  String get stdout => _stdout.toString();
  final bool verbose;
  List<String> _stdin;

  @override
  void printError(String message) {
    _error.writeln(message);
  }

  @override
  void printStatus(String message) {
    _stdout.writeln(message);
  }

  @override
  void printTrace(String message) {
    if (verbose) {
      _stdout.writeln(message);
    }
  }

  @override
  void write(String message) {
    _stdout.write(message);
  }

  @override
  String readLineSync() {
    if (_stdin.isEmpty) {
      throw Exception('Unexpected call to readLineSync!');
    }
    return _stdin.removeAt(0);
  }
}

class FakeArgResults implements ArgResults {
  FakeArgResults({
    String level,
    String commit,
    String remote,
    bool justPrint = false,
    bool autoApprove = true, // so we don't have to mock stdin
    bool help = false,
    bool force = false,
    bool skipTagging = false,
  }) : _parsedArgs = <String, dynamic>{
    'increment': level,
    'commit': commit,
    'remote': remote,
    'just-print': justPrint,
    'yes': autoApprove,
    'help': help,
    'force': force,
    'skip-tagging': skipTagging,
  };

  @override
  String name;

  @override
  ArgResults command;

  @override
  final List<String> rest = <String>[];

  @override
  List<String> arguments;

  final Map<String, dynamic> _parsedArgs;

  @override
  Iterable<String> get options {
    return null;
  }

  @override
  dynamic operator [](String name) {
    return _parsedArgs[name];
  }

  @override
  bool wasParsed(String name) {
    return null;
  }
}

//class FakeCommand {
//  FakeCommand({
//    @required this.command,
//    ProcessResult result,
//  }) : _result = result ?? ProcessResult(), assert(command != null);
//
//  final List<String> command;
//  final ProcessResult _result;
//}
//
//class FakeProcessManager implements ProcessManager {
//  final List<FakeCommand> commands = <FakeCommand>[];
//  void addCommand(FakeCommand command) {
//    commands.add(command);
//  }
//
//  @override
//  Future<Process> start(
//    List<dynamic> command, {
//    String workingDirectory,
//    Map<String, String> environment,
//    bool includeParentEnvironment = true,
//    bool runInShell = false,
//    ProcessStartMode mode = ProcessStartMode.normal,
//  }) {
//    assert(false, 'method `start` not implemented yet.');
//    return null;
//  }
//
//  @override
//  Future<ProcessResult> run(
//    List<dynamic> command, {
//    String workingDirectory,
//    Map<String, String> environment,
//    bool includeParentEnvironment = true,
//    bool runInShell = false,
//    Encoding stdoutEncoding = systemEncoding,
//    Encoding stderrEncoding = systemEncoding,
//  }) {
//    assert(false, 'method `run` not implemented yet.');
//    return null;
//  }
//
//  @override
//  ProcessResult runSync(
//    List<dynamic> command, {
//    String workingDirectory,
//    Map<String, String> environment,
//    bool includeParentEnvironment = true,
//    bool runInShell = false,
//    Encoding stdoutEncoding = systemEncoding,
//    Encoding stderrEncoding = systemEncoding,
//  }) {
//    final FakeCommand expectedCommand = commands.removeAt(0);
//    assert(expectedCommand != null);
//    return null;
//  }
//
//  @override
//  bool canRun(dynamic executable, {String workingDirectory}) {
//    assert(false, 'method `canRun` not implemented yet.');
//    return null;
//  }
//
//  @override
//  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]) {
//    assert(false, 'method `killPid` not implemented yet.');
//    return null;
//  }
//}
