// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';

void main() {
  testWithoutContext('keyboard input handling single help character', () async {
    final TestRunner testRunner = TestRunner();
    final Logger logger = BufferLogger.test();
    final Signals signals = Signals.test();
    final Terminal terminal = Terminal.test();
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final ProcessInfo processInfo = ProcessInfo.test(fs);
    final TerminalHandler terminalHandler = TerminalHandler(
      testRunner,
      logger: logger,
      signals: signals,
      terminal: terminal,
      processInfo: processInfo,
      reportReady: false,
    );

    expect(testRunner.hasHelpBeenPrinted, false);
    await terminalHandler.processTerminalInput('h');
    expect(testRunner.hasHelpBeenPrinted, true);
  });

  testWithoutContext('keyboard input handling help character surrounded with newlines', () async {
    final TestRunner testRunner = TestRunner();
    final Logger logger = BufferLogger.test();
    final Signals signals = Signals.test();
    final Terminal terminal = Terminal.test();
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final ProcessInfo processInfo = ProcessInfo.test(fs);
    final TerminalHandler terminalHandler = TerminalHandler(
      testRunner,
      logger: logger,
      signals: signals,
      terminal: terminal,
      processInfo: processInfo,
      reportReady: false,
    );

    expect(testRunner.hasHelpBeenPrinted, false);
    await terminalHandler.processTerminalInput('\nh\n');
    expect(testRunner.hasHelpBeenPrinted, true);
  });

  group('keycode verification, brought to you by the letter', () {
    MockResidentRunner mockResidentRunner;
    TerminalHandler terminalHandler;
    BufferLogger testLogger;

    setUp(() {
      testLogger = BufferLogger.test();
      final Signals signals = Signals.test();
      final Terminal terminal = Terminal.test();
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final ProcessInfo processInfo = ProcessInfo.test(fs);
      mockResidentRunner = MockResidentRunner();
      terminalHandler = TerminalHandler(
        mockResidentRunner,
        logger: testLogger,
        signals: signals,
        terminal: terminal,
        processInfo: processInfo,
      reportReady: false,
      );
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(true);
    });

    testWithoutContext('a, can handle trailing newlines', () async {
      await terminalHandler.processTerminalInput('a\n');

      expect(terminalHandler.lastReceivedCommand, 'a');
    });

    testWithoutContext('n, can handle trailing only newlines', () async {
      await terminalHandler.processTerminalInput('\n\n');

      expect(terminalHandler.lastReceivedCommand, '');
    });

    testWithoutContext('a - debugToggleProfileWidgetBuilds with service protocol', () async {
      await terminalHandler.processTerminalInput('a');

      verify(mockResidentRunner.debugToggleProfileWidgetBuilds()).called(1);
    });

    testWithoutContext('a - debugToggleProfileWidgetBuilds', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(true);
      await terminalHandler.processTerminalInput('a');

      verify(mockResidentRunner.debugToggleProfileWidgetBuilds()).called(1);
    });

    testWithoutContext('b - debugToggleBrightness', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(true);
      await terminalHandler.processTerminalInput('b');

      verify(mockResidentRunner.debugToggleBrightness()).called(1);
    });

    testWithoutContext('d,D - detach', () async {
      await terminalHandler.processTerminalInput('d');
      await terminalHandler.processTerminalInput('D');

      verify(mockResidentRunner.detach()).called(2);
    });

    testWithoutContext('h,H,? - printHelp', () async {
      await terminalHandler.processTerminalInput('h');
      await terminalHandler.processTerminalInput('H');
      await terminalHandler.processTerminalInput('?');

      verify(mockResidentRunner.printHelp(details: true)).called(3);
    });

    testWithoutContext('i - debugToggleWidgetInspector with service protocol', () async {
      await terminalHandler.processTerminalInput('i');

      verify(mockResidentRunner.debugToggleWidgetInspector()).called(1);
    });

    testWithoutContext('I - debugToggleInvertOversizedImages with service protocol/debug', () async {
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('I');

      verify(mockResidentRunner.debugToggleInvertOversizedImages()).called(1);
    });

    testWithoutContext('L - debugDumpLayerTree with service protocol', () async {
      await terminalHandler.processTerminalInput('L');

      verify(mockResidentRunner.debugDumpLayerTree()).called(1);
    });

    testWithoutContext('o,O - debugTogglePlatform with service protocol and debug mode', () async {
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('o');
      await terminalHandler.processTerminalInput('O');

      verify(mockResidentRunner.debugTogglePlatform()).called(2);
    });

    testWithoutContext('p - debugToggleDebugPaintSizeEnabled with service protocol and debug mode', () async {
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('p');

      verify(mockResidentRunner.debugToggleDebugPaintSizeEnabled()).called(1);
    });

    testWithoutContext('p - debugToggleDebugPaintSizeEnabled with service protocol and debug mode', () async {
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('p');

      verify(mockResidentRunner.debugToggleDebugPaintSizeEnabled()).called(1);
    });

    testWithoutContext('P - debugTogglePerformanceOverlayOverride with service protocol', () async {
      await terminalHandler.processTerminalInput('P');

      verify(mockResidentRunner.debugTogglePerformanceOverlayOverride()).called(1);
    });

    testWithoutContext('q,Q - exit', () async {
      await terminalHandler.processTerminalInput('q');
      await terminalHandler.processTerminalInput('Q');

      verify(mockResidentRunner.exit()).called(2);
    });

    testWithoutContext('s - screenshot', () async {
      final MockDevice mockDevice = MockDevice();
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      when(mockResidentRunner.flutterDevices).thenReturn(<FlutterDevice>[mockFlutterDevice]);
      when(mockFlutterDevice.device).thenReturn(mockDevice);
      when(mockDevice.supportsScreenshot).thenReturn(true);

      await terminalHandler.processTerminalInput('s');

      verify(mockResidentRunner.screenshot(mockFlutterDevice)).called(1);
    });

    testWithoutContext('r - hotReload supported and succeeds', () async {
      when(mockResidentRunner.canHotReload).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: false))
          .thenAnswer((Invocation invocation) async {
            return OperationResult(0, '');
          });
      await terminalHandler.processTerminalInput('r');

      verify(mockResidentRunner.restart(fullRestart: false)).called(1);
    });

    testWithoutContext('r - hotReload supported and fails', () async {
      when(mockResidentRunner.canHotReload).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: false))
          .thenAnswer((Invocation invocation) async {
            return OperationResult(1, '');
          });
      await terminalHandler.processTerminalInput('r');

      verify(mockResidentRunner.restart(fullRestart: false)).called(1);

      expect(testLogger.statusText, contains('Try again after fixing the above error(s).'));
    });

    testWithoutContext('r - hotReload supported and fails fatally', () async {
      when(mockResidentRunner.canHotReload).thenReturn(true);
      when(mockResidentRunner.hotMode).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: false))
        .thenAnswer((Invocation invocation) async {
          return OperationResult(1, 'fail', fatal: true);
        });
      expect(terminalHandler.processTerminalInput('r'), throwsToolExit());
    });

    testWithoutContext('r - hotReload unsupported', () async {
      when(mockResidentRunner.canHotReload).thenReturn(false);
      await terminalHandler.processTerminalInput('r');

      verifyNever(mockResidentRunner.restart(fullRestart: false));
    });

    testWithoutContext('R - hotRestart supported and succeeds', () async {
      when(mockResidentRunner.canHotRestart).thenReturn(true);
      when(mockResidentRunner.hotMode).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: true))
        .thenAnswer((Invocation invocation) async {
          return OperationResult(0, '');
        });
      await terminalHandler.processTerminalInput('R');

      verify(mockResidentRunner.restart(fullRestart: true)).called(1);
    });

    testWithoutContext('R - hotRestart supported and fails', () async {
      when(mockResidentRunner.canHotRestart).thenReturn(true);
      when(mockResidentRunner.hotMode).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: true))
        .thenAnswer((Invocation invocation) async {
          return OperationResult(1, 'fail');
        });
      await terminalHandler.processTerminalInput('R');

      verify(mockResidentRunner.restart(fullRestart: true)).called(1);

      expect(testLogger.statusText, contains('Try again after fixing the above error(s).'));
    });

    testWithoutContext('R - hotRestart supported and fails fatally', () async {
      when(mockResidentRunner.canHotRestart).thenReturn(true);
      when(mockResidentRunner.hotMode).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: true))
        .thenAnswer((Invocation invocation) async {
          return OperationResult(1, 'fail', fatal: true);
        });
      expect(() => terminalHandler.processTerminalInput('R'), throwsToolExit());
    });

    testWithoutContext('R - hot restart unsupported', () async {
      when(mockResidentRunner.canHotRestart).thenReturn(false);
      await terminalHandler.processTerminalInput('R');

      verifyNever(mockResidentRunner.restart(fullRestart: true));
    });

    testWithoutContext('S - debugDumpSemanticsTreeInTraversalOrder with service protocol', () async {
      await terminalHandler.processTerminalInput('S');

      verify(mockResidentRunner.debugDumpSemanticsTreeInTraversalOrder()).called(1);
    });

    testWithoutContext('t,T - debugDumpRenderTree with service protocol', () async {
      await terminalHandler.processTerminalInput('t');
      await terminalHandler.processTerminalInput('T');

      verify(mockResidentRunner.debugDumpRenderTree()).called(2);
    });

    testWithoutContext('U - debugDumpRenderTree with service protocol', () async {
      await terminalHandler.processTerminalInput('U');

      verify(mockResidentRunner.debugDumpSemanticsTreeInInverseHitTestOrder()).called(1);
    });

    testWithoutContext('w,W - debugDumpApp with service protocol', () async {
      await terminalHandler.processTerminalInput('w');
      await terminalHandler.processTerminalInput('W');

      verify(mockResidentRunner.debugDumpApp()).called(2);
    });

    testWithoutContext('z,Z - debugToggleDebugCheckElevationsEnabled with service protocol', () async {
      await terminalHandler.processTerminalInput('z');
      await terminalHandler.processTerminalInput('Z');

      verify(mockResidentRunner.debugToggleDebugCheckElevationsEnabled()).called(2);
    });

    testWithoutContext('z,Z - debugToggleDebugCheckElevationsEnabled without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('z');
      await terminalHandler.processTerminalInput('Z');

      // This should probably be disable when the service protocol is not enabled.
      verify(mockResidentRunner.debugToggleDebugCheckElevationsEnabled()).called(2);
    });
  });

  testWithoutContext('pidfile creation', () {
    final BufferLogger testLogger = BufferLogger.test();
    final Signals signals = _TestSignals(Signals.defaultExitSignals);
    final Terminal terminal = Terminal.test();
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final ProcessInfo processInfo = ProcessInfo.test(fs);
    final ResidentRunner mockResidentRunner = MockResidentRunner();
    when(mockResidentRunner.stayResident).thenReturn(true);
    when(mockResidentRunner.supportsServiceProtocol).thenReturn(true);
    when(mockResidentRunner.supportsRestart).thenReturn(true);
    const String filename = 'test.pid';
    final TerminalHandler terminalHandler = TerminalHandler(
      mockResidentRunner,
      logger: testLogger,
      signals: signals,
      terminal: terminal,
      processInfo: processInfo,
      reportReady: false,
      pidFile: filename,
    );
    expect(fs.file(filename).existsSync(), isFalse);
    terminalHandler.setupTerminal();
    terminalHandler.registerSignalHandlers();
    expect(fs.file(filename).existsSync(), isTrue);
    terminalHandler.stop();
    expect(fs.file(filename).existsSync(), isFalse);
  });
}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class MockResidentRunner extends Mock implements ResidentRunner {}
class MockFlutterDevice extends Mock implements FlutterDevice {}
class FakeResidentCompiler extends Fake implements ResidentCompiler {}

class TestRunner extends Fake implements ResidentRunner {
  bool hasHelpBeenPrinted = false;
  String receivedCommand;

  @override
  Future<void> cleanupAfterSignal() async { }

  @override
  Future<void> cleanupAtFinish() async { }

  @override
  void printHelp({ bool details }) {
    hasHelpBeenPrinted = true;
  }

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    bool enableDevTools = false,
    String route,
  }) async => null;

  @override
  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    bool allowExistingDdsInstance = false,
    bool enableDevTools = false,
  }) async => null;
}

class _TestSignals implements Signals {
  _TestSignals(this.exitSignals);

  final List<ProcessSignal> exitSignals;

  final Map<ProcessSignal, Map<Object, SignalHandler>> _handlersTable =
      <ProcessSignal, Map<Object, SignalHandler>>{};

  @override
  Object addHandler(ProcessSignal signal, SignalHandler handler) {
    final Object token = Object();
    _handlersTable.putIfAbsent(signal, () => <Object, SignalHandler>{})[token] = handler;
    return token;
  }

  @override
  Future<bool> removeHandler(ProcessSignal signal, Object token) async {
    if (!_handlersTable.containsKey(signal)) {
      return false;
    }
    if (!_handlersTable[signal].containsKey(token)) {
      return false;
    }
    _handlersTable[signal].remove(token);
    return true;
  }

  @override
  Stream<Object> get errors => _errors.stream;
  final StreamController<Object> _errors = StreamController<Object>();
}
