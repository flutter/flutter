// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show IOSink;

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart' hide IOSink;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  Cache.disableLocking();
  group('packages get/upgrade', () {
    Directory temp;

    setUp(() {
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    Future<String> runCommand(String verb, { List<String> args }) async {
      final String projectPath = await createProject(temp);

      final PackagesCommand command = new PackagesCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      final List<String> commandArgs = <String>['packages', verb];
      if (args != null)
        commandArgs.addAll(args);
      commandArgs.add(projectPath);

      await runner.run(commandArgs);

      return projectPath;
    }

    void expectExists(String projectPath, String relPath) {
      expect(fs.isFileSync(fs.path.join(projectPath, relPath)), true);
    }

    // Verify that we create a project that is well-formed.
    testUsingContext('get', () async {
      final String projectPath = await runCommand('get');
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });

    testUsingContext('get --offline', () async {
      final String projectPath = await runCommand('get', args: <String>['--offline']);
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });

    testUsingContext('upgrade', () async {
      final String projectPath = await runCommand('upgrade');
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });
  });

  group('packages test/pub', () {
    MockProcessManager mockProcessManager;
    MockStdio mockStdio;

    setUp(() {
      mockProcessManager = new MockProcessManager();
      mockStdio = new MockStdio();
    });

    testUsingContext('test', () async {
      await createTestCommandRunner(new PackagesCommand()).run(<String>['packages', 'test']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(3));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'run');
      expect(commands[2], 'test');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
    });

    testUsingContext('run', () async {
      await createTestCommandRunner(new PackagesCommand()).run(<String>['packages', '--verbose', 'pub', 'run', '--foo', 'bar']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(4));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'run');
      expect(commands[2], '--foo');
      expect(commands[3], 'bar');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
    });

    testUsingContext('publish', () async {
      final PromptingProcess process = new PromptingProcess();
      mockProcessManager.processFactory = (List<String> commands) => process;
      final Future<Null> runPackages = createTestCommandRunner(new PackagesCommand()).run(<String>['packages', 'pub', 'publish']);
      final Future<Null> runPrompt = process.showPrompt('Proceed (y/n)? ', <String>['hello', 'world']);
      final Future<Null> simulateUserInput = new Future<Null>(() {
        mockStdio.simulateStdin('y');
      });
      await Future.wait(<Future<Null>>[runPackages, runPrompt, simulateUserInput]);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'publish');
      final List<String> stdout = mockStdio.writtenToStdout;
      expect(stdout, hasLength(4));
      expect(stdout.sublist(0, 2), contains('Proceed (y/n)? '));
      expect(stdout.sublist(0, 2), contains('y\n'));
      expect(stdout[2], 'hello\n');
      expect(stdout[3], 'world\n');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
    });
  });
}

/// A strategy for creating Process objects from a list of commands.
typedef Process ProcessFactory(List<String> command);

/// A ProcessManager that starts Processes by delegating to a ProcessFactory.
class MockProcessManager implements ProcessManager {
  ProcessFactory processFactory = (List<String> commands) => new MockProcess();
  List<String> commands;

  @override
  Future<Process> start(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    ProcessStartMode mode: ProcessStartMode.NORMAL,
  }) {
    commands = command;
    return new Future<Process>.value(processFactory(command));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// A process that prompts the user to proceed, then asynchronously writes
/// some lines to stdout before it exits.
class PromptingProcess implements Process {
  Future<Null> showPrompt(String prompt, List<String> outputLines) async {
    _stdoutController.add(UTF8.encode(prompt));
    final List<int> bytesOnStdin = await _stdin.future;
    // Echo stdin to stdout.
    _stdoutController.add(bytesOnStdin);
    if (bytesOnStdin[0] == UTF8.encode('y')[0]) {
      for (final String line in outputLines)
        _stdoutController.add(UTF8.encode('$line\n'));
    }
    await _stdoutController.close();
  }

  final StreamController<List<int>> _stdoutController = new StreamController<List<int>>();
  final CompleterIOSink _stdin = new CompleterIOSink();

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  IOSink get stdin => _stdin;

  @override
  Future<int> get exitCode async {
    await _stdoutController.done;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// An inactive process that collects stdin and produces no output.
class MockProcess implements Process {
  final IOSink _stdin = new MemoryIOSink();

  @override
  Stream<List<int>> get stdout => const Stream<List<int>>.empty();

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  IOSink get stdin => _stdin;

  @override
  Future<int> get exitCode => new Future<int>.value(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// An IOSink that completes a future with the first line written to it.
class CompleterIOSink extends MemoryIOSink {
  final Completer<List<int>> _completer = new Completer<List<int>>();

  Future<List<int>> get future => _completer.future;

  @override
  void add(List<int> data) {
    if (!_completer.isCompleted)
      _completer.complete(data);
    super.add(data);
  }
}

/// A Stdio that collects stdout and supports simulated stdin.
class MockStdio extends Stdio {
  final MemoryIOSink _stdout = new MemoryIOSink();
  final StreamController<List<int>> _stdin = new StreamController<List<int>>();

  @override
  IOSink get stdout => _stdout;

  @override
  Stream<List<int>> get stdin => _stdin.stream;

  void simulateStdin(String line) {
    _stdin.add(UTF8.encode('$line\n'));
  }

  List<String> get writtenToStdout => _stdout.writes.map(_stdout.encoding.decode).toList();
}

/// An IOSink that collects whatever is written to it.
class MemoryIOSink implements IOSink {
  @override
  Encoding encoding = UTF8;

  final List<List<int>> writes = <List<int>>[];

  @override
  void add(List<int> data) {
    writes.add(data);
  }

  @override
  Future<Null> addStream(Stream<List<int>> stream) {
    final Completer<Null> completer = new Completer<Null>();
    stream.listen((List<int> data) {
      add(data);
    }).onDone(() => completer.complete(null));
    return completer.future;
  }

  @override
  void writeCharCode(int charCode) {
    add(<int>[charCode]);
  }

  @override
  void write(Object obj) {
    add(encoding.encode('$obj'));
  }

  @override
  void writeln([Object obj = ""]) {
    add(encoding.encode('$obj\n'));
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    bool addSeparator = false;
    for (dynamic object in objects) {
      if (addSeparator) {
        write(separator);
      }
      write(object);
      addSeparator = true;
    }
  }

  @override
  void addError(dynamic error, [StackTrace stackTrace]) {
    throw new UnimplementedError();
  }

  @override
  Future<Null> get done => close();

  @override
  Future<Null> close() async => null;

  @override
  Future<Null> flush() async => null;
}
