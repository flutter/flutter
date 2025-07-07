// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show Encoding, jsonDecode, utf8;
import 'dart:io' as io;

import 'package:engine_mcp/server.dart' as engine_mcp;
import 'package:mcp_dart/mcp_dart.dart';
import 'package:process/process.dart' show ProcessManager;
import 'package:process_runner/process_runner.dart';
import 'package:test/test.dart';

// TODO(gaaclarke): Get this integrated with the workspace and use the shared
// version.
final class _FakeProcessManager implements ProcessManager {
  /// Creates a fake process manager delegates to [onRun] and [onStart].
  ///
  /// If either is not provided, it throws an [UnsupportedError] when called.
  _FakeProcessManager({
    io.ProcessResult Function(_FakeCommandLogEntry entry) onRun = unhandledRun,
    io.Process Function(_FakeCommandLogEntry entry) onStart = unhandledStart,
    bool Function(Object?, {String? workingDirectory}) canRun = unhandledCanRun,
  })  : _onRun = onRun,
        _onStart = onStart,
        _canRun = canRun;

  /// A default implementation of [onRun] that throws an [UnsupportedError].
  static io.ProcessResult unhandledRun(_FakeCommandLogEntry entry) {
    throw UnsupportedError('Unhandled run: ${entry.command.join(' ')}');
  }

  /// A default implementation of [onStart] that throws an [UnsupportedError].
  static io.Process unhandledStart(_FakeCommandLogEntry entry) {
    throw UnsupportedError('Unhandled start: ${entry.command.join(' ')}');
  }

  /// A default implementation of [canRun] that returns `true`.
  static bool unhandledCanRun(Object? executable, {String? workingDirectory}) {
    return true;
  }

  final io.ProcessResult Function(_FakeCommandLogEntry entry) _onRun;
  final io.Process Function(_FakeCommandLogEntry entry) _onStart;
  final bool Function(Object?, {String? workingDirectory}) _canRun;

  @override
  bool canRun(Object? executable, {String? workingDirectory}) {
    return _canRun(executable, workingDirectory: workingDirectory);
  }

  @override
  bool killPid(int pid, [io.ProcessSignal signal = io.ProcessSignal.sigterm]) => true;

  @override
  Future<io.ProcessResult> run(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = io.systemEncoding,
    Encoding? stderrEncoding = io.systemEncoding,
  }) async {
    return runSync(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }

  @override
  io.ProcessResult runSync(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = io.systemEncoding,
    Encoding? stderrEncoding = io.systemEncoding,
  }) {
    return _onRun(
      _FakeCommandLogEntry(
        command,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
      ),
    );
  }

  @override
  Future<io.Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) async {
    return _onStart(
      _FakeCommandLogEntry(
        command,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: null,
        stderrEncoding: null,
      ),
    );
  }
}

/// Contains information about [ProcessManager.start] and [ProcessManager.run]
/// invocations.
final class _FakeCommandLogEntry {
  /// Creates a log entry for a single process invocation.
  _FakeCommandLogEntry(
    List<Object> command, {
    required this.workingDirectory,
    required this.environment,
    required this.includeParentEnvironment,
    required this.runInShell,
    required this.stdoutEncoding,
    required this.stderrEncoding,
  }) : command = command.map((o) => '$o').toList();

  /// The command passed to the [ProcessManager].
  final List<String> command;

  /// The working directory passed to the [ProcessManager].
  final String? workingDirectory;

  /// The environment variables at the time [ProcessManager] was called.
  final Map<String, String>? environment;

  /// Whether the parent environment variables were included when spawning the
  /// child process.
  final bool includeParentEnvironment;

  /// When the child was spawned in a shell environment.
  final bool runInShell;

  /// The encoding used by `stdout`.
  final Encoding? stdoutEncoding;

  /// The encoding used by `stderr`.
  final Encoding? stderrEncoding;
}

/// An incomplete fake of [io.Process] that allows control for testing.
final class _FakeProcess implements io.Process {
  /// Creates a fake process that returns the given [exitCode] and out/err.
  _FakeProcess({int exitCode = 0, String stdout = '', String stderr = ''})
      : _exitCode = exitCode,
        _stdout = stdout,
        _stderr = stderr,
        _stdin = io.IOSink(StreamController<List<int>>.broadcast().sink);

  final int _exitCode;
  final String _stdout;
  final String _stderr;
  final io.IOSink _stdin;

  @override
  Future<int> get exitCode async => _exitCode;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) => true;

  @override
  int get pid => 0;

  @override
  Stream<List<int>> get stderr {
    return Stream<List<int>>.fromIterable(<List<int>>[io.systemEncoding.encoder.convert(_stderr)]);
  }

  @override
  io.IOSink get stdin => _stdin;

  @override
  Stream<List<int>> get stdout {
    return Stream<List<int>>.fromIterable(<List<int>>[io.systemEncoding.encoder.convert(_stdout)]);
  }
}

void main() {
  test('list tools', () async {
    final McpServer server = engine_mcp.makeServer();
    final inputController = StreamController<List<int>>();
    final outputController = StreamController<List<int>>();

    server.connect(IOStreamTransport(
      stream: inputController.stream,
      sink: outputController.sink,
    ));

    final responseFuture = outputController.stream.first;

    const requestJson = '{ "jsonrpc": "2.0", "id": 1, "method": "tools/list" }\n';
    inputController.add(utf8.encode(requestJson));

    final List<int> outputBytes = await responseFuture;
    final String outputString = utf8.decode(outputBytes);

    final Map<String, dynamic> json = jsonDecode(outputString) as Map<String, dynamic>;

    expect(json['jsonrpc'], equals('2.0'), reason: outputString);
    expect(json['id'], equals(1), reason: outputString);
    expect(json.containsKey('result'), isTrue);
    // ignore: avoid_dynamic_calls
    expect(json['result']['tools'], isNotEmpty, reason: outputString);

    await inputController.close();
    await server.close();
  });

  test('build', () async {
    final McpServer server =
        engine_mcp.makeServer(processRunner: ProcessRunner(processManager: _FakeProcessManager(
      onStart: (_FakeCommandLogEntry entry) {
        if (entry.command.length == 5 && //
            entry.command[0] == './bin/et' && //
            entry.command[1] == 'build' && //
            entry.command[2] == '-c' && //
            entry.command[3] == 'host_profile_arm64' && //
            entry.command[4] == '//flutter/tools/licenses_cpp') {
          return _FakeProcess(stdout: 'Build succeeded');
        } else {
          return _FakeProcess(exitCode: 1, stdout: 'Build failed');
        }
      },
    )));

    final inputController = StreamController<List<int>>();
    final outputController = StreamController<List<int>>();

    server.connect(IOStreamTransport(
      stream: inputController.stream,
      sink: outputController.sink,
    ));

    final responseFuture = outputController.stream.first;

    const requestJson =
        '{ "jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": { "name": "engine_build", "arguments": { "config": "host_profile_arm64", "target": "//flutter/tools/licenses_cpp"} } }\n';

    inputController.add(utf8.encode(requestJson));

    final List<int> outputBytes = await responseFuture;
    final String outputString = utf8.decode(outputBytes);

    final Map<String, dynamic> json = jsonDecode(outputString) as Map<String, dynamic>;

    expect(json['jsonrpc'], equals('2.0'), reason: outputString);
    expect(json['id'], equals(2), reason: outputString);
    expect(json.containsKey('result'), isTrue);
    // ignore: avoid_dynamic_calls
    expect(json['result']['content'][0]['text'], equals('Build succeeded.'), reason: outputString);

    await inputController.close();
    await server.close();
  });
}
