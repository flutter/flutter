// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/ios/lldb.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  testWithoutContext('attachAndStart fails if lldb fails', () async {
    const deviceId = '123';
    const appProcessId = 5678;

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['lldb'],
      completer: processCompleter,
      stdin: io.IOSink(StreamController<List<int>>().sink),
      stdout: const Stream.empty(),
      stderr: const Stream.empty(),
      exitCode: 1,
      exception: const ProcessException('lldb', <String>[]),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(logger: logger, processUtils: processUtils);

    final bool success = await lldb.attachAndStart(
      deviceId: deviceId,
      appProcessId: appProcessId,
      lldbLogForwarder: FakeLLDBLogForwarder(),
    );
    expect(success, isFalse);
    expect(lldb.isRunning, isFalse);
    expect(lldb.appProcessId, isNull);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.traceText, contains('Process exception running lldb'));
  });

  testWithoutContext('attachAndStart returns true on success', () async {
    const deviceId = '123';
    const appProcessId = 5678;
    const breakpointId = 123;

    final breakPointCompleter = Completer<List<int>>();
    final processAttachCompleter = Completer<List<int>>();
    final processResumedCompleted = Completer<List<int>>();

    final stdoutStream = Stream<List<int>>.fromFutures([
      breakPointCompleter.future,
      processAttachCompleter.future,
      processResumedCompleted.future,
    ]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(logger: logger, processUtils: processUtils);

    const breakPointMatcher = r"breakpoint set --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'";
    const processAttachMatcher = 'device process attach --pid $appProcessId';
    const processResumedMatcher = 'process continue';
    final expectedInputs = [
      'device select $deviceId',
      breakPointMatcher,
      'breakpoint command add --script-type python $breakpointId',
      processAttachMatcher,
      processResumedMatcher,
    ];

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      expectedInputs.remove(line);
      if (line == breakPointMatcher) {
        breakPointCompleter.complete(
          utf8.encode('Breakpoint $breakpointId: no locations (pending).\n'),
        );
      }
      if (line == processAttachMatcher) {
        processAttachCompleter.complete(
          utf8.encode('''
Process 568 stopped
* thread #1, stop reason = signal SIGSTOP
    frame #0: 0x0000000102c7b240 dyld`_dyld_start
dyld`_dyld_start:
->  0x102c7b240 <+0>:  mov    x0, sp
    0x102c7b244 <+4>:  and    sp, x0, #0xfffffffffffffff0
    0x102c7b248 <+8>:  mov    x29, #0x0 ; =0
    0x102c7b24c <+12>: mov    x30, #0x0 ; =0
Target 0: (Runner) stopped.
'''),
        );
      }
      if (line == processResumedMatcher) {
        processResumedCompleted.complete(utf8.encode('Process $appProcessId resuming\n'));
      }
    });

    final bool success = await lldb.attachAndStart(
      deviceId: deviceId,
      appProcessId: appProcessId,
      lldbLogForwarder: FakeLLDBLogForwarder(),
    );
    expect(success, isTrue);
    expect(lldb.isRunning, isTrue);
    expect(lldb.appProcessId, appProcessId);
    expect(expectedInputs, isEmpty);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.errorText, isEmpty);
  });

  testWithoutContext('attachAndStart returns false when stderr during log waiter', () async {
    const deviceId = '123';
    const appProcessId = 5678;

    final breakPointCompleter = Completer<List<int>>();
    final errorCompleter = Completer<List<int>>();

    final stdoutStream = Stream<List<int>>.fromFutures([breakPointCompleter.future]);

    final stderrStream = Stream<List<int>>.fromFutures([errorCompleter.future]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: stderrStream,
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(logger: logger, processUtils: processUtils);

    const breakPointMatcher = r"breakpoint set --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'";
    final expectedInputs = ['device select $deviceId', breakPointMatcher];
    const errorText = "error: 'device' is not a valid command.\n";

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      expectedInputs.remove(line);
      if (line == breakPointMatcher) {
        errorCompleter.complete(utf8.encode(errorText));
      }
    });

    final bool success = await lldb.attachAndStart(
      deviceId: deviceId,
      appProcessId: appProcessId,
      lldbLogForwarder: FakeLLDBLogForwarder(),
    );
    expect(success, isFalse);
    expect(lldb.isRunning, isFalse);
    expect(lldb.appProcessId, isNull);
    expect(expectedInputs, isEmpty);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.traceText, contains(errorText));
  });

  testWithoutContext('attachAndStart returns false when stderr not during log waiter', () async {
    const deviceId = '123';
    const appProcessId = 5678;

    final breakPointCompleter = Completer<List<int>>();
    final errorCompleter = Completer<List<int>>();

    final stdoutStream = Stream<List<int>>.fromFutures([breakPointCompleter.future]);

    final stderrStream = Stream<List<int>>.fromFutures([errorCompleter.future]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: stderrStream,
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(logger: logger, processUtils: processUtils);
    final expectedInputs = ['device select $deviceId'];
    const errorText = "error: 'device' is not a valid command.\n";

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      expectedInputs.remove(line);
      errorCompleter.complete(utf8.encode(errorText));
    });

    final bool success = await lldb.attachAndStart(
      deviceId: deviceId,
      appProcessId: appProcessId,
      lldbLogForwarder: FakeLLDBLogForwarder(),
    );
    expect(success, isFalse);
    expect(lldb.isRunning, isFalse);
    expect(lldb.appProcessId, isNull);
    expect(expectedInputs, isEmpty);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.traceText, contains(errorText));
  });

  testWithoutContext('attachAndStart prints warning if takes too long', () async {
    const deviceId = '123';
    const appProcessId = 5678;

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: const Stream.empty(),
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(logger: logger, processUtils: processUtils);

    final completer = Completer<void>();

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    await FakeAsync().run((FakeAsync time) {
      lldb.attachAndStart(
        deviceId: deviceId,
        appProcessId: appProcessId,
        lldbLogForwarder: FakeLLDBLogForwarder(),
      );
      time.elapse(const Duration(minutes: 2));
      time.flushMicrotasks();
      return completer.future;
    });

    expect(
      logger.errorText,
      contains('LLDB is taking longer than expected to start debugging the app'),
    );
  });

  testWithoutContext('attachAndStart streams logs to LLDBLogForwarder', () async {
    const deviceId = '123';
    const appProcessId = 5678;
    const breakpointId = 123;

    final breakPointCompleter = Completer<List<int>>();
    final processAttachCompleter = Completer<List<int>>();
    final processResumedCompleted = Completer<List<int>>();
    final logAfterAttachCompleter = Completer<List<int>>();

    final stdoutStream = Stream<List<int>>.fromFutures([
      breakPointCompleter.future,
      processAttachCompleter.future,
      processResumedCompleted.future,
      logAfterAttachCompleter.future,
    ]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(logger: logger, processUtils: processUtils);

    const breakPointMatcher = r"breakpoint set --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'";
    const processAttachMatcher = 'device process attach --pid $appProcessId';
    const processResumedMatcher = 'process continue';
    final expectedInputs = [
      'device select $deviceId',
      breakPointMatcher,
      'breakpoint command add --script-type python $breakpointId',
      processAttachMatcher,
      processResumedMatcher,
    ];

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      expectedInputs.remove(line);
      if (line == breakPointMatcher) {
        breakPointCompleter.complete(
          utf8.encode('Breakpoint $breakpointId: no locations (pending).\n'),
        );
      }
      if (line == processAttachMatcher) {
        processAttachCompleter.complete(
          utf8.encode('''
Process 568 stopped
* thread #1, stop reason = signal SIGSTOP
    frame #0: 0x0000000102c7b240 dyld`_dyld_start
dyld`_dyld_start:
->  0x102c7b240 <+0>:  mov    x0, sp
    0x102c7b244 <+4>:  and    sp, x0, #0xfffffffffffffff0
    0x102c7b248 <+8>:  mov    x29, #0x0 ; =0
    0x102c7b24c <+12>: mov    x30, #0x0 ; =0
Target 0: (Runner) stopped.
'''),
        );
      }
      if (line == processResumedMatcher) {
        processResumedCompleted.complete(utf8.encode('Process $appProcessId resuming\n'));
      }
    });

    const ignoreLog = '1 location added to breakpoint 1';
    const expectedForwardedLog = 'Some random log from LLDB';
    final lldbLogForwarder = FakeLLDBLogForwarder(expectedLog: expectedForwardedLog);

    final bool success = await lldb.attachAndStart(
      deviceId: deviceId,
      appProcessId: appProcessId,
      lldbLogForwarder: lldbLogForwarder,
    );

    logAfterAttachCompleter.complete(utf8.encode('$ignoreLog\n$expectedForwardedLog\n'));
    await lldbLogForwarder.expectedLogCompleter.future;

    expect(success, isTrue);
    expect(lldb.isRunning, isTrue);
    expect(lldb.appProcessId, appProcessId);
    expect(expectedInputs, isEmpty);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.errorText, isEmpty);
    expect(lldbLogForwarder.logs.length, 1);
    expect(lldbLogForwarder.logs, contains(expectedForwardedLog));
  });

  testWithoutContext('exit returns true and kills process', () async {
    const deviceId = '123';
    const appProcessId = 5678;

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: const Stream.empty(),
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(logger: logger, processUtils: processUtils);

    final lldbStarted = Completer<void>();

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      if (!lldbStarted.isCompleted) {
        lldbStarted.complete();
      }
    });

    unawaited(
      lldb.attachAndStart(
        deviceId: deviceId,
        appProcessId: appProcessId,
        lldbLogForwarder: FakeLLDBLogForwarder(),
      ),
    );

    await lldbStarted.future;
    expect(lldb.isRunning, isTrue);
    final bool exitStatus = lldb.exit();
    expect(exitStatus, isTrue);
    expect(lldb.isRunning, isFalse);
    expect(lldb.appProcessId, isNull);
    expect(processManager.hasRemainingExpectations, isFalse);
  });

  testWithoutContext('exit returns true if process not running', () {
    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(logger: logger, processUtils: processUtils);
    expect(lldb.isRunning, isFalse);
    final bool exitStatus = lldb.exit();
    expect(exitStatus, isTrue);
    expect(lldb.isRunning, isFalse);
    expect(lldb.appProcessId, isNull);
  });

  group('LLDBLogForwarder', () {
    testWithoutContext('addLog', () async {
      const expectedLog = 'hello world';
      final expectedLogCompleter = Completer<void>();
      final lldbLogForwarder = LLDBLogForwarder();
      lldbLogForwarder.logLines.listen((String line) {
        expect(line, expectedLog);
        expectedLogCompleter.complete();
      });
      lldbLogForwarder.addLog(expectedLog);
      await expectedLogCompleter.future;
    });

    testWithoutContext('exit', () async {
      final exitCompleter = Completer<void>();
      final lldbLogForwarder = LLDBLogForwarder();
      lldbLogForwarder.logLines.listen((String line) => line).onDone(() {
        exitCompleter.complete();
      });
      await lldbLogForwarder.exit();
      await exitCompleter.future;
    });

    testWithoutContext('addLog after exit', () async {
      final exitCompleter = Completer<void>();
      final lldbLogForwarder = LLDBLogForwarder();
      lldbLogForwarder.logLines.listen((String line) => line).onDone(() {
        exitCompleter.complete();
      });
      await lldbLogForwarder.exit();
      await exitCompleter.future;
      lldbLogForwarder.addLog('hello world');
    });
  });
}

class FakeLLDBProcessManager extends Fake implements ProcessManager {
  FakeLLDBProcessManager(this._commands);
  final List<FakeLLDBCommand> _commands;

  final fakeRunningProcesses = <int, FakeLLDBProcess>{};
  var _pid = 9999;

  @override
  Future<Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    final FakeLLDBProcess process = _runCommand(
      command.cast<String>(),
      workingDirectory: workingDirectory,
      environment: environment,
      encoding: io.systemEncoding,
      mode: mode,
    );
    if (process._completer != null) {
      fakeRunningProcesses[process.pid] = process;
      process.exitCode.whenComplete(() {
        fakeRunningProcesses.remove(process.pid);
      });
    }
    return Future<io.Process>.value(process);
  }

  FakeLLDBProcess _runCommand(
    List<String> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? encoding,
    io.ProcessStartMode? mode,
  }) {
    _pid += 1;
    final FakeLLDBCommand fakeCommand = findCommand(
      command,
      workingDirectory,
      environment,
      encoding,
      mode,
    );
    if (fakeCommand.exception != null) {
      assert(fakeCommand.exception is Exception || fakeCommand.exception is Error);
      throw fakeCommand.exception!; // ignore: only_throw_errors
    }
    return FakeLLDBProcess(
      exitCode: fakeCommand.exitCode,
      pid: _pid,
      stderr: fakeCommand.stderr,
      stdin: fakeCommand.stdin,
      stdout: fakeCommand.stdout,
      completer: fakeCommand.completer,
    );
  }

  FakeLLDBCommand findCommand(
    List<String> command,
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? encoding,
    io.ProcessStartMode? mode,
  ) {
    expect(
      _commands,
      isNotEmpty,
      reason:
          'ProcessManager was told to execute $command (in $workingDirectory) '
          'but the FakeProcessManager.list expected no more processes.',
    );
    _commands.first.commandMatches(command, workingDirectory, environment, encoding, mode);
    return _commands.removeAt(0);
  }

  bool get hasRemainingExpectations => _commands.isNotEmpty;
}

class FakeLLDBProcess implements io.Process {
  /// Creates a fake process for use with [FakeProcessManager].
  ///
  /// The process delays exit until both [duration] (if specified) has elapsed
  /// and [completer] (if specified) has completed.
  FakeLLDBProcess({
    int exitCode = 0,
    Duration duration = Duration.zero,
    this.pid = 1234,
    required this.stdin,
    required this.stdout,
    required this.stderr,
    Completer<void>? completer,
  }) : exitCode = Future<void>.delayed(duration).then((void value) {
         if (completer != null) {
           return completer.future.then((void _) => exitCode);
         }
         return exitCode;
       }),
       _completer = completer;

  /// When specified, blocks process exit until completed.
  final Completer<void>? _completer;

  @override
  final Future<int> exitCode;

  @override
  final int pid;

  @override
  late final Stream<List<int>> stderr;

  @override
  final IOSink stdin;

  @override
  late final Stream<List<int>> stdout;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    // Killing a fake process has no effect.
    return true;
  }
}

class FakeLLDBCommand {
  const FakeLLDBCommand({
    required this.command,
    this.exitCode = 0,
    required this.stdin,
    required this.stdout,
    required this.stderr,
    this.completer,
    this.exception,
  });

  /// The exact commands that must be matched for this [FakeCommand] to be
  /// considered correct.
  final List<Pattern> command;

  /// The process' exit code.
  final int exitCode;

  /// The output to simulate on stdout. This will be encoded as UTF-8 and
  /// returned in one go.
  final Stream<List<int>> stdout;

  /// The output to simulate on stderr. This will be encoded as UTF-8 and
  /// returned in one go.
  final Stream<List<int>> stderr;

  /// If provided, allows the command completion to be blocked until the future
  /// resolves.
  final Completer<void>? completer;

  /// An optional stdin sink that will be exposed through the resulting
  /// [FakeProcess].
  final IOSink stdin;

  /// If provided, this exception will be thrown when the fake command is run.
  final Object? exception;

  void commandMatches(
    List<String> command,
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? encoding,
    io.ProcessStartMode? mode,
  ) {
    final List<dynamic> matchers = this.command
        .map((Pattern x) => x is String ? x : matches(x))
        .toList();
    expect(command, matchers);
  }
}

class FakeLLDBLogForwarder extends Fake implements LLDBLogForwarder {
  FakeLLDBLogForwarder({this.expectedLog});

  final expectedLogCompleter = Completer<void>();

  final String? expectedLog;

  final logs = <String>[];

  @override
  void addLog(String log) {
    logs.add(log);
    if (log == expectedLog) {
      expectedLogCompleter.complete();
    }
  }
}
