// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:fake_async/fake_async.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/device_support.dart';
import 'package:flutter_tools/src/ios/lldb.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';

const _deviceId = '123';
const _appProcessId = 5678;
const _breakpointId = 123;

void main() {
  testWithoutContext('attachAndStart fails if lldb fails', () async {
    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['xcrun', 'lldb'],
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
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(16, 0, 0),
    );

    final bool success = await lldb.attachAndStart(
      deviceId: _deviceId,
      appProcessId: _appProcessId,
      lldbLogForwarder: FakeLLDBLogForwarder(),
      mode: BuildMode.debug,
      deviceSupport: createDeviceSupport(),
    );
    expect(success, isFalse);
    expect(lldb.isRunning, isFalse);
    expect(lldb.appProcessId, isNull);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.traceText, contains('Process exception running lldb'));
  });

  testWithoutContext('attachAndStart returns true on success', () async {
    final breakPointCompleter = Completer<List<int>>();
    final processAttachCompleter = Completer<List<int>>();
    final setupStopHooksCompleter = Completer<List<int>>();
    final platformStatusCompleter = Completer<List<int>>();
    final processResumedCompleter = Completer<List<int>>();

    final stdoutStream = Stream<List<int>>.fromFutures([
      breakPointCompleter.future,
      processAttachCompleter.future,
      setupStopHooksCompleter.future,
      platformStatusCompleter.future,
      processResumedCompleter.future,
    ]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['xcrun', 'lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(16, 0, 0),
    );

    final Map<String, ({Completer<List<int>> completer, String out})?>
    inputsAndOutputs = buildAttachInputsAndOutputs(
      breakPointMatcher:
          r"breakpoint set --auto-continue true --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'",
      processResumingOutput: '1 location added to breakpoint 1\n',
      breakPointCompleter: breakPointCompleter,
      processAttachCompleter: processAttachCompleter,
      setupStopHooksCompleter: setupStopHooksCompleter,
      platformStatusCompleter: platformStatusCompleter,
      processResumedCompleter: processResumedCompleter,
    );

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      final ({Completer<List<int>> completer, String out})? x = inputsAndOutputs.remove(line);
      if (x != null) {
        x.completer.complete(utf8.encode(x.out));
      }
    });

    final bool success = await lldb.attachAndStart(
      deviceId: _deviceId,
      appProcessId: _appProcessId,
      lldbLogForwarder: FakeLLDBLogForwarder(),
      mode: BuildMode.debug,
      deviceSupport: createDeviceSupport(),
    );
    expect(success, isTrue);
    expect(lldb.isRunning, isTrue);
    expect(lldb.appProcessId, _appProcessId);
    expect(inputsAndOutputs, isEmpty);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.errorText, isEmpty);
  });

  testWithoutContext('attachAndStart returns true on success for profile mode', () async {
    final processAttachCompleter = Completer<List<int>>();
    final setupStopHooksCompleter = Completer<List<int>>();
    final platformStatusCompleter = Completer<List<int>>();
    final processResumedCompleter = Completer<List<int>>();

    final stdoutStream = Stream<List<int>>.fromFutures([
      processAttachCompleter.future,
      setupStopHooksCompleter.future,
      platformStatusCompleter.future,
      processResumedCompleter.future,
    ]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['xcrun', 'lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(27, 0, 0),
    );

    final Map<String, ({Completer<List<int>> completer, String out})?>
    inputsAndOutputs = buildAttachInputsAndOutputs(
      breakPointMatcher:
          r"breakpoint set --auto-continue true --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'",
      processResumingOutput: 'Process $_appProcessId resuming\n',
      breakPointCompleter: null,
      processAttachCompleter: processAttachCompleter,
      setupStopHooksCompleter: setupStopHooksCompleter,
      platformStatusCompleter: platformStatusCompleter,
      processResumedCompleter: processResumedCompleter,
    );

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      final ({Completer<List<int>> completer, String out})? x = inputsAndOutputs.remove(line);
      if (x != null) {
        x.completer.complete(utf8.encode(x.out));
      }
    });

    final bool success = await lldb.attachAndStart(
      deviceId: _deviceId,
      appProcessId: _appProcessId,
      lldbLogForwarder: FakeLLDBLogForwarder(),
      mode: BuildMode.profile,
      deviceSupport: createDeviceSupport(),
    );
    expect(success, isTrue);
    expect(lldb.isRunning, isTrue);
    expect(lldb.appProcessId, _appProcessId);
    expect(inputsAndOutputs, isEmpty);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.errorText, isEmpty);
  });

  testWithoutContext('attachAndStart returns false when stderr during log waiter', () async {
    final breakPointCompleter = Completer<List<int>>();
    final errorCompleter = Completer<List<int>>();

    final stdoutStream = Stream<List<int>>.fromFutures([breakPointCompleter.future]);

    final stderrStream = Stream<List<int>>.fromFutures([errorCompleter.future]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['xcrun', 'lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: stderrStream,
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(16, 0, 0),
    );

    const breakPointMatcher =
        r"breakpoint set --auto-continue true --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'";
    final expectedInputs = ['device select $_deviceId', breakPointMatcher];
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
      deviceId: _deviceId,
      appProcessId: _appProcessId,
      lldbLogForwarder: FakeLLDBLogForwarder(),
      mode: BuildMode.debug,
      deviceSupport: createDeviceSupport(),
    );
    expect(success, isFalse);
    expect(lldb.isRunning, isFalse);
    expect(lldb.appProcessId, isNull);
    expect(expectedInputs, isEmpty);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.traceText, contains(errorText));
  });

  testWithoutContext('attachAndStart returns false when stderr not during log waiter', () async {
    final breakPointCompleter = Completer<List<int>>();
    final errorCompleter = Completer<List<int>>();

    final stdoutStream = Stream<List<int>>.fromFutures([breakPointCompleter.future]);

    final stderrStream = Stream<List<int>>.fromFutures([errorCompleter.future]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['xcrun', 'lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: stderrStream,
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(16, 0, 0),
    );
    final expectedInputs = [
      'device select $_deviceId',
      r"breakpoint set --auto-continue true --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'",
    ];
    const errorText = "error: 'device' is not a valid command.\n";

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      expectedInputs.remove(line);
      if (expectedInputs.isEmpty) {
        errorCompleter.complete(utf8.encode(errorText));
      }
    });

    final bool success = await lldb.attachAndStart(
      deviceId: _deviceId,
      appProcessId: _appProcessId,
      lldbLogForwarder: FakeLLDBLogForwarder(),
      mode: BuildMode.debug,
      deviceSupport: createDeviceSupport(),
    );
    expect(success, isFalse);
    expect(lldb.isRunning, isFalse);
    expect(lldb.appProcessId, isNull);
    expect(expectedInputs, isEmpty);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.traceText, contains(errorText));
  });

  testWithoutContext('attachAndStart prints warning if takes too long', () async {
    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['xcrun', 'lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: const Stream.empty(),
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(16, 0, 0),
    );

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
        deviceId: _deviceId,
        appProcessId: _appProcessId,
        lldbLogForwarder: FakeLLDBLogForwarder(),
        mode: BuildMode.debug,
        deviceSupport: createDeviceSupport(),
      );
      time.elapse(const Duration(minutes: 2));
      time.flushMicrotasks();
      return completer.future;
    });

    expect(
      logger.warningText,
      contains('LLDB is taking longer than expected to start debugging the app'),
    );
  });

  testWithoutContext('attachAndStart streams logs to LLDBLogForwarder', () async {
    final breakPointCompleter = Completer<List<int>>();
    final processAttachCompleter = Completer<List<int>>();
    final setupStopHooksCompleter = Completer<List<int>>();
    final platformStatusCompleter = Completer<List<int>>();
    final processResumedCompleter = Completer<List<int>>();
    final logAfterAttachCompleter = Completer<List<int>>();

    final stdoutStream = Stream<List<int>>.fromFutures([
      breakPointCompleter.future,
      processAttachCompleter.future,
      setupStopHooksCompleter.future,
      platformStatusCompleter.future,
      processResumedCompleter.future,
      logAfterAttachCompleter.future,
    ]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['xcrun', 'lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(16, 0, 0),
    );

    final Map<String, ({Completer<List<int>> completer, String out})?>
    inputsAndOutputs = buildAttachInputsAndOutputs(
      breakPointMatcher:
          r"breakpoint set --auto-continue true --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'",
      processResumingOutput: '1 location added to breakpoint 1\n',
      breakPointCompleter: breakPointCompleter,
      processAttachCompleter: processAttachCompleter,
      setupStopHooksCompleter: setupStopHooksCompleter,
      platformStatusCompleter: platformStatusCompleter,
      processResumedCompleter: processResumedCompleter,
    );

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      final ({Completer<List<int>> completer, String out})? x = inputsAndOutputs.remove(line);
      if (x != null) {
        x.completer.complete(utf8.encode(x.out));
      }
    });

    const ignoreLog = '1 location added to breakpoint 1';
    const expectedForwardedLog = 'Some random log from LLDB';
    final lldbLogForwarder = FakeLLDBLogForwarder(expectedLog: expectedForwardedLog);

    final bool success = await lldb.attachAndStart(
      deviceId: _deviceId,
      appProcessId: _appProcessId,
      lldbLogForwarder: lldbLogForwarder,
      mode: BuildMode.debug,
      deviceSupport: createDeviceSupport(),
    );

    logAfterAttachCompleter.complete(utf8.encode('$ignoreLog\n$expectedForwardedLog\n'));
    await lldbLogForwarder.expectedLogCompleter.future;

    expect(success, isTrue);
    expect(lldb.isRunning, isTrue);
    expect(lldb.appProcessId, _appProcessId);
    expect(inputsAndOutputs, isEmpty);
    expect(processManager.hasRemainingExpectations, isFalse);
    expect(logger.errorText, isEmpty);
    expect(lldbLogForwarder.logs.length, 1);
    expect(lldbLogForwarder.logs, contains(expectedForwardedLog));
  });

  testWithoutContext('exit returns true and kills process', () async {
    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['xcrun', 'lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: const Stream.empty(),
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(16, 0, 0),
    );

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
        deviceId: _deviceId,
        appProcessId: _appProcessId,
        lldbLogForwarder: FakeLLDBLogForwarder(),
        mode: BuildMode.debug,
        deviceSupport: createDeviceSupport(),
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
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(16, 0, 0),
    );
    expect(lldb.isRunning, isFalse);
    final bool exitStatus = lldb.exit();
    expect(exitStatus, isTrue);
    expect(lldb.isRunning, isFalse);
    expect(lldb.appProcessId, isNull);
  });

  group('addSymbolSearchPaths', () {
    testWithoutContext(
      'sends platform select remote-ios sysroot for arch symbol directory',
      () async {
        final fileSystem = MemoryFileSystem.test();
        final Directory homeDir = fileSystem.directory('/Users/username');
        final Directory archSymbols =
            homeDir
                .childDirectory('Library')
                .childDirectory('Developer')
                .childDirectory('Xcode')
                .childDirectory('iOS DeviceSupport')
                .childDirectory('iPhone15,2 17.0')
                .childDirectory('arm64e')
                .childDirectory('Symbols')
              ..createSync(recursive: true);

        final platformSelectCompleter = Completer<List<int>>();
        final processAttachCompleter = Completer<List<int>>();
        final setupStopHooksCompleter = Completer<List<int>>();
        final platformStatusCompleter = Completer<List<int>>();
        final processResumedCompleter = Completer<List<int>>();

        final stdoutStream = Stream<List<int>>.fromFutures([
          platformSelectCompleter.future,
          processAttachCompleter.future,
          setupStopHooksCompleter.future,
          platformStatusCompleter.future,
          processResumedCompleter.future,
        ]);

        final stdinController = StreamController<List<int>>();

        final processCompleter = Completer<void>();
        final lldbCommand = FakeLLDBCommand(
          command: const <String>['xcrun', 'lldb'],
          completer: processCompleter,
          stdin: io.IOSink(stdinController.sink),
          stdout: stdoutStream,
          stderr: const Stream.empty(),
        );

        final logger = BufferLogger.test();

        final processManager = FakeLLDBProcessManager([lldbCommand]);
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final lldb = LLDB(
          logger: logger,
          processUtils: processUtils,
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          deviceVersion: Version(16, 0, 0),
        );

        final Map<String, ({Completer<List<int>> completer, String out})?>
        inputsAndOutputs = buildAttachInputsAndOutputs(
          breakPointMatcher:
              r"breakpoint set --auto-continue true --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'",
          processResumingOutput: 'Process $_appProcessId resuming\n',
          breakPointCompleter: null,
          processAttachCompleter: processAttachCompleter,
          setupStopHooksCompleter: setupStopHooksCompleter,
          platformStatusCompleter: platformStatusCompleter,
          processResumedCompleter: processResumedCompleter,
        );
        inputsAndOutputs.addAll({
          'platform select remote-ios --sysroot "${archSymbols.path}"': null,
        });

        stdinController.stream
            .transform<String>(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) {
              final ({Completer<List<int>> completer, String out})? x = inputsAndOutputs.remove(
                line,
              );
              if (x != null) {
                x.completer.complete(utf8.encode(x.out));
              }
            });

        final bool success = await lldb.attachAndStart(
          deviceId: _deviceId,
          appProcessId: _appProcessId,
          lldbLogForwarder: FakeLLDBLogForwarder(),
          mode: BuildMode.profile,
          deviceSupport: createDeviceSupport(
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            homeDirectory: homeDir,
          ),
        );

        expect(success, isTrue);
        expect(inputsAndOutputs, isEmpty);
      },
    );

    testWithoutContext(
      'sends platform select remote-ios sysroot for non-arch symbol directory',
      () async {
        final fileSystem = MemoryFileSystem.test();
        final Directory homeDir = fileSystem.directory('/Users/username');
        final Directory symbols =
            homeDir
                .childDirectory('Library')
                .childDirectory('Developer')
                .childDirectory('Xcode')
                .childDirectory('iOS DeviceSupport')
                .childDirectory('iPhone15,2 17.0')
                .childDirectory('Symbols')
              ..createSync(recursive: true);

        final platformSelectCompleter = Completer<List<int>>();
        final processAttachCompleter = Completer<List<int>>();
        final setupStopHooksCompleter = Completer<List<int>>();
        final platformStatusCompleter = Completer<List<int>>();
        final processResumedCompleter = Completer<List<int>>();

        final stdoutStream = Stream<List<int>>.fromFutures([
          platformSelectCompleter.future,
          processAttachCompleter.future,
          setupStopHooksCompleter.future,
          platformStatusCompleter.future,
          processResumedCompleter.future,
        ]);

        final stdinController = StreamController<List<int>>();

        final processCompleter = Completer<void>();
        final lldbCommand = FakeLLDBCommand(
          command: const <String>['xcrun', 'lldb'],
          completer: processCompleter,
          stdin: io.IOSink(stdinController.sink),
          stdout: stdoutStream,
          stderr: const Stream.empty(),
        );

        final logger = BufferLogger.test();

        final processManager = FakeLLDBProcessManager([lldbCommand]);
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final lldb = LLDB(
          logger: logger,
          processUtils: processUtils,
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          deviceVersion: Version(16, 0, 0),
        );

        final Map<String, ({Completer<List<int>> completer, String out})?>
        inputsAndOutputs = buildAttachInputsAndOutputs(
          breakPointMatcher:
              r"breakpoint set --auto-continue true --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'",
          processResumingOutput: 'Process $_appProcessId resuming\n',
          breakPointCompleter: null,
          processAttachCompleter: processAttachCompleter,
          setupStopHooksCompleter: setupStopHooksCompleter,
          platformStatusCompleter: platformStatusCompleter,
          processResumedCompleter: processResumedCompleter,
        );
        inputsAndOutputs.addAll({'platform select remote-ios --sysroot "${symbols.path}"': null});

        stdinController.stream
            .transform<String>(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) {
              final ({Completer<List<int>> completer, String out})? x = inputsAndOutputs.remove(
                line,
              );
              if (x != null) {
                x.completer.complete(utf8.encode(x.out));
              }
            });

        final bool success = await lldb.attachAndStart(
          deviceId: _deviceId,
          appProcessId: _appProcessId,
          lldbLogForwarder: FakeLLDBLogForwarder(),
          mode: BuildMode.profile,
          deviceSupport: createDeviceSupport(
            modelCode: 'iPhone15,2',
            operatingSystemVersion: '17.0',
            cpuArchitectureString: 'arm64e',
            homeDirectory: homeDir,
          ),
        );

        expect(success, isTrue);
        expect(inputsAndOutputs, isEmpty);
      },
    );
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

  testWithoutContext('Stops are handled manually for iOS 27+', () async {
    final breakPointCompleter = Completer<List<int>>();
    final processAttachCompleter = Completer<List<int>>();
    final platformStatusCompleter = Completer<List<int>>();
    final processResumedCompleter = Completer<List<int>>();
    final breakpointStopCompleter = Completer<List<int>>();
    final breakpointContinueCompleter = Completer<List<int>>();
    final normalLogCompleter = Completer<List<int>>();
    final crashCompleter = Completer<List<int>>();
    final backtraceCompleter = Completer<void>();
    final detachCompleter = Completer<void>();

    var isAttached = false;

    final stdoutStream = Stream<List<int>>.fromFutures([
      breakPointCompleter.future,
      processAttachCompleter.future,
      platformStatusCompleter.future,
      processResumedCompleter.future.whenComplete(() => isAttached = true),
      breakpointStopCompleter.future,
      breakpointContinueCompleter.future,
      normalLogCompleter.future,
      crashCompleter.future,
    ]);

    final stdinController = StreamController<List<int>>();

    final processCompleter = Completer<void>();
    final lldbCommand = FakeLLDBCommand(
      command: const <String>['xcrun', 'lldb'],
      completer: processCompleter,
      stdin: io.IOSink(stdinController.sink),
      stdout: stdoutStream,
      stderr: const Stream.empty(),
    );

    final logger = BufferLogger.test();

    final processManager = FakeLLDBProcessManager([lldbCommand]);
    final processUtils = ProcessUtils(processManager: processManager, logger: logger);
    final lldb = LLDB(
      logger: logger,
      processUtils: processUtils,
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      deviceVersion: Version(27, 0, 0),
    );

    const breakPointMatcher = r"breakpoint set --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'";
    final unexpectedInputs = ['Stop hook #1 added.\n'];
    final Map<String, ({Completer<List<int>> completer, String out})?> inputsAndOutputs =
        buildAttachInputsAndOutputs(
          breakPointMatcher: breakPointMatcher,
          processResumingOutput: '1 location added to breakpoint 1\n',
          breakPointCompleter: breakPointCompleter,
          processAttachCompleter: processAttachCompleter,
          platformStatusCompleter: platformStatusCompleter,
          processResumedCompleter: processResumedCompleter,
          setupStopHooksCompleter: null,
        );

    stdinController.stream.transform<String>(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      final ({Completer<List<int>> completer, String out})? x = inputsAndOutputs.remove(line);
      if (x != null) {
        x.completer.complete(utf8.encode(x.out));
      }
      expect(unexpectedInputs.contains(line), isFalse);
      if (isAttached && line == 'process continue') {
        breakpointContinueCompleter.complete(utf8.encode('Process $_appProcessId resuming\n'));
      }
      if (line == 'thread backtrace all') {
        backtraceCompleter.complete();
      }
      if (line == 'detach') {
        detachCompleter.complete();
      }
    });

    final lldbLogForwarder = FakeLLDBLogForwarder();
    final bool success = await lldb.attachAndStart(
      deviceId: _deviceId,
      appProcessId: _appProcessId,
      lldbLogForwarder: lldbLogForwarder,
      mode: BuildMode.debug,
      deviceSupport: createDeviceSupport(),
    );
    expect(success, isTrue);
    expect(inputsAndOutputs, isEmpty);

    // Simulate a breakpoint stop after attached.
    breakpointStopCompleter.complete(
      utf8.encode('''
Process $_appProcessId stopped
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
    frame #0: 0x0000000107996d18 Flutter`NOTIFY_DEBUGGER_ABOUT_RX_PAGES
Flutter`NOTIFY_DEBUGGER_ABOUT_RX_PAGES:
->  0x107996d18 <+0>: ret

Flutter`dart::VirtualMemory::AllocateAligned:
    0x107996d1c <+0>: stp    x28, x27, [sp, #-0x50]!
    0x107996d20 <+4>: stp    x24, x23, [sp, #0x10]
    0x107996d24 <+8>: stp    x22, x21, [sp, #0x20]
Target 0: (Flutter Gallery) stopped.
'''),
    );
    await breakpointContinueCompleter.future;

    // Verify Breakpoint stop logs should not be printed.
    expect(lldbLogForwarder.logs, isEmpty);
    expect(logger.traceText, isNot(contains('NOTIFY_DEBUGGER_ABOUT_RX_PAGES')));

    // Verify normal logs are printed
    normalLogCompleter.complete(utf8.encode('Hello World\n'));
    await pumpEventQueue();
    expect(lldbLogForwarder.logs, contains('Hello World'));

    // Simulate a crash stop while attached.
    crashCompleter.complete(
      utf8.encode('''
Process $_appProcessId stopped
* thread #1, stop reason = EXC_BAD_ACCESS (code=1, address=0x0)
    frame #0: 0x0000000102c7b240 my_crashed_code
Target 0: (Runner) stopped.
'''),
    );

    await backtraceCompleter.future;
    await detachCompleter.future;

    // Verify crash logs are printed
    expect(lldbLogForwarder.logs, contains('Process $_appProcessId stopped'));
    expect(
      lldbLogForwarder.logs,
      contains('* thread #1, stop reason = EXC_BAD_ACCESS (code=1, address=0x0)'),
    );
    expect(lldbLogForwarder.logs, contains('Target 0: (Runner) stopped.'));
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

IOSDeviceSupport createDeviceSupport({
  Logger? logger,
  ProcessUtils? processUtils,
  Directory? homeDirectory,
  String? modelCode,
  String? operatingSystemVersion,
  String? cpuArchitectureString,
  String deviceId = '123',
}) {
  final Logger testLogger = logger ?? BufferLogger.test();
  return IOSDeviceSupport(
    logger: testLogger,
    processUtils:
        processUtils ??
        ProcessUtils(processManager: FakeProcessManager.empty(), logger: testLogger),
    xcode: null,
    homeDirectory: homeDirectory,
    modelCode: modelCode,
    operatingSystemVersion: operatingSystemVersion,
    cpuArchitectureString: cpuArchitectureString,
    deviceId: _deviceId,
  );
}

/// Builds a map of expected stdin command inputs sent to LLDB during [LLDB.attachAndStart]
/// and their corresponding simulated stdout outputs and completers.
Map<String, ({Completer<List<int>> completer, String out})?> buildAttachInputsAndOutputs({
  required String breakPointMatcher,
  required String processResumingOutput,
  required Completer<List<int>>? breakPointCompleter,
  required Completer<List<int>> processAttachCompleter,
  required Completer<List<int>> platformStatusCompleter,
  required Completer<List<int>> processResumedCompleter,
  required Completer<List<int>>? setupStopHooksCompleter,
}) {
  const processAttachMatcher = 'device process attach --pid $_appProcessId';
  const processContinueMatcher = 'process continue';
  const setupStopHooksMatcher = 'target stop-hook add -o "thread backtrace all" -o "detach"';
  const platformStatusMatcher = 'platform status';
  return {
    'device select $_deviceId': null,
    if (breakPointCompleter != null) ...{
      breakPointMatcher: (
        out: 'Breakpoint $_breakpointId: no locations (pending).\n',
        completer: breakPointCompleter,
      ),
      'breakpoint command add --script-type python $_breakpointId': null,
      'script lldb.debugger.SetAsync(False)': null,
    },
    processAttachMatcher: (
      out: '''
Process 568 stopped
* thread #1, stop reason = signal SIGSTOP
    frame #0: 0x0000000102c7b240 dyld`_dyld_start
dyld`_dyld_start:
->  0x102c7b240 <+0>:  mov    x0, sp
    0x102c7b244 <+4>:  and    sp, x0, #0xfffffffffffffff0
    0x102c7b248 <+8>:  mov    x29, #0x0 ; =0
    0x102c7b24c <+12>: mov    x30, #0x0 ; =0
Target 0: (Runner) stopped.
''',
      completer: processAttachCompleter,
    ),
    if (setupStopHooksCompleter != null)
      setupStopHooksMatcher: (out: 'Stop hook #1 added.\n', completer: setupStopHooksCompleter),
    platformStatusMatcher: (out: '  Platform: remote-ios\n', completer: platformStatusCompleter),
    processContinueMatcher: (out: processResumingOutput, completer: processResumedCompleter),
  };
}
