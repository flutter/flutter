// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  TestRunner createTestRunner() {
    // TODO(jacobr): make these tests run with `trackWidgetCreation: true` as
    // well as the default flags.
    return TestRunner(
      <FlutterDevice>[
        FlutterDevice(
          MockDevice(),
          buildInfo: const BuildInfo(
            BuildMode.debug,
            null,
            trackWidgetCreation: false,
            treeShakeIcons: false,
          ),
          generator: MockResidentCompiler(),
        ),
      ],
    );
  }

  group('keyboard input handling', () {
    testUsingContext('single help character', () async {
      final TestRunner testRunner = createTestRunner();
      final TerminalHandler terminalHandler = TerminalHandler(testRunner);
      expect(testRunner.hasHelpBeenPrinted, false);
      await terminalHandler.processTerminalInput('h');
      expect(testRunner.hasHelpBeenPrinted, true);
    });

    testUsingContext('help character surrounded with newlines', () async {
      final TestRunner testRunner = createTestRunner();
      final TerminalHandler terminalHandler = TerminalHandler(testRunner);
      expect(testRunner.hasHelpBeenPrinted, false);
      await terminalHandler.processTerminalInput('\nh\n');
      expect(testRunner.hasHelpBeenPrinted, true);
    });
  });

  group('keycode verification, brought to you by the letter', () {
    MockResidentRunner mockResidentRunner;
    TerminalHandler terminalHandler;

    setUp(() {
      mockResidentRunner = MockResidentRunner();
      terminalHandler = TerminalHandler(mockResidentRunner);
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(true);
    });

    testUsingContext('a, can handle trailing newlines', () async {
      await terminalHandler.processTerminalInput('a\n');

      expect(terminalHandler.lastReceivedCommand, 'a');
    });

    testUsingContext('n, can handle trailing only newlines', () async {
      await terminalHandler.processTerminalInput('\n\n');

      expect(terminalHandler.lastReceivedCommand, '');
    });

    testUsingContext('a - debugToggleProfileWidgetBuilds with service protocol', () async {
      await terminalHandler.processTerminalInput('a');

      verify(mockResidentRunner.debugToggleProfileWidgetBuilds()).called(1);
    });

    testUsingContext('a - debugToggleProfileWidgetBuilds without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('a');

      verifyNever(mockResidentRunner.debugToggleProfileWidgetBuilds());
    });


    testUsingContext('a - debugToggleProfileWidgetBuilds', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(true);
      await terminalHandler.processTerminalInput('a');

      verify(mockResidentRunner.debugToggleProfileWidgetBuilds()).called(1);
    });

    testUsingContext('d,D - detach', () async {
      await terminalHandler.processTerminalInput('d');
      await terminalHandler.processTerminalInput('D');

      verify(mockResidentRunner.detach()).called(2);
    });

    testUsingContext('h,H,? - printHelp', () async {
      await terminalHandler.processTerminalInput('h');
      await terminalHandler.processTerminalInput('H');
      await terminalHandler.processTerminalInput('?');

      verify(mockResidentRunner.printHelp(details: true)).called(3);
    });

    testUsingContext('k - toggles CanvasKit rendering and prints results', () async {
      when(mockResidentRunner.supportsCanvasKit).thenReturn(true);
      when(mockResidentRunner.toggleCanvaskit())
        .thenAnswer((Invocation invocation) async {
          return true;
        });

      await terminalHandler.processTerminalInput('k');

      verify(mockResidentRunner.toggleCanvaskit()).called(1);
    });

    testUsingContext('i - debugToggleWidgetInspector with service protocol', () async {
      await terminalHandler.processTerminalInput('i');

      verify(mockResidentRunner.debugToggleWidgetInspector()).called(1);
    });

    testUsingContext('i - debugToggleWidgetInspector without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('i');

      verifyNever(mockResidentRunner.debugToggleWidgetInspector());
    });

    testUsingContext('I - debugToggleInvertOversizedImages with service protocol/debug', () async {
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('I');

      verify(mockResidentRunner.debugToggleInvertOversizedImages()).called(1);
    });

    testUsingContext('I - debugToggleInvertOversizedImages with service protocol/ndebug', () async {
      when(mockResidentRunner.isRunningDebug).thenReturn(false);
      await terminalHandler.processTerminalInput('I');

      verifyNever(mockResidentRunner.debugToggleInvertOversizedImages());
    });

    testUsingContext('I - debugToggleInvertOversizedImages without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('I');

    });

    testUsingContext('L - debugDumpLayerTree with service protocol', () async {
      await terminalHandler.processTerminalInput('L');

      verify(mockResidentRunner.debugDumpLayerTree()).called(1);
    });

    testUsingContext('L - debugDumpLayerTree without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('L');

      verifyNever(mockResidentRunner.debugDumpLayerTree());
    });

    testUsingContext('o,O - debugTogglePlatform with service protocol and debug mode', () async {
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('o');
      await terminalHandler.processTerminalInput('O');

      verify(mockResidentRunner.debugTogglePlatform()).called(2);
    });

    testUsingContext('o,O - debugTogglePlatform without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('o');
      await terminalHandler.processTerminalInput('O');

      verifyNever(mockResidentRunner.debugTogglePlatform());
    });

    testUsingContext('p - debugToggleDebugPaintSizeEnabled with service protocol and debug mode', () async {
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('p');

      verify(mockResidentRunner.debugToggleDebugPaintSizeEnabled()).called(1);
    });

    testUsingContext('p - debugTogglePlatform without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('p');

      verifyNever(mockResidentRunner.debugToggleDebugPaintSizeEnabled());
    });

    testUsingContext('p - debugToggleDebugPaintSizeEnabled with service protocol and debug mode', () async {
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('p');

      verify(mockResidentRunner.debugToggleDebugPaintSizeEnabled()).called(1);
    });

    testUsingContext('p - debugTogglePlatform without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      await terminalHandler.processTerminalInput('p');

      verifyNever(mockResidentRunner.debugToggleDebugPaintSizeEnabled());
    });

    testUsingContext('P - debugTogglePerformanceOverlayOverride with service protocol', () async {
      await terminalHandler.processTerminalInput('P');

      verify(mockResidentRunner.debugTogglePerformanceOverlayOverride()).called(1);
    });

    testUsingContext('P - debugTogglePerformanceOverlayOverride without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('P');

      verifyNever(mockResidentRunner.debugTogglePerformanceOverlayOverride());
    });

    testUsingContext('q,Q - exit', () async {
      await terminalHandler.processTerminalInput('q');
      await terminalHandler.processTerminalInput('Q');

      verify(mockResidentRunner.exit()).called(2);
    });

    testUsingContext('s - screenshot', () async {
      final MockDevice mockDevice = MockDevice();
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockResidentRunner.isRunningDebug).thenReturn(true);
      when(mockResidentRunner.flutterDevices).thenReturn(<FlutterDevice>[mockFlutterDevice]);
      when(mockFlutterDevice.device).thenReturn(mockDevice);
      when(mockDevice.supportsScreenshot).thenReturn(true);

      await terminalHandler.processTerminalInput('s');

      verify(mockResidentRunner.screenshot(mockFlutterDevice)).called(1);
    });

    testUsingContext('r - hotReload supported and succeeds', () async {
      when(mockResidentRunner.canHotReload).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: false))
          .thenAnswer((Invocation invocation) async {
            return OperationResult(0, '');
          });
      await terminalHandler.processTerminalInput('r');

      verify(mockResidentRunner.restart(fullRestart: false)).called(1);
    });

    testUsingContext('r - hotReload supported and fails', () async {
      when(mockResidentRunner.canHotReload).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: false))
          .thenAnswer((Invocation invocation) async {
            return OperationResult(1, '');
          });
      await terminalHandler.processTerminalInput('r');

      verify(mockResidentRunner.restart(fullRestart: false)).called(1);

      expect(testLogger.statusText, contains('Try again after fixing the above error(s).'));
    });

    testUsingContext('r - hotReload supported and fails fatally', () async {
      when(mockResidentRunner.canHotReload).thenReturn(true);
      when(mockResidentRunner.hotMode).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: false))
        .thenAnswer((Invocation invocation) async {
          return OperationResult(1, 'fail', fatal: true);
        });
      expect(terminalHandler.processTerminalInput('r'), throwsToolExit());
    });

    testUsingContext('r - hotReload unsupported', () async {
      when(mockResidentRunner.canHotReload).thenReturn(false);
      await terminalHandler.processTerminalInput('r');

      verifyNever(mockResidentRunner.restart(fullRestart: false));
    });

    testUsingContext('R - hotRestart supported and succeeds', () async {
      when(mockResidentRunner.canHotRestart).thenReturn(true);
      when(mockResidentRunner.hotMode).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: true))
        .thenAnswer((Invocation invocation) async {
          return OperationResult(0, '');
        });
      await terminalHandler.processTerminalInput('R');

      verify(mockResidentRunner.restart(fullRestart: true)).called(1);
    });

    testUsingContext('R - hotRestart supported and fails', () async {
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

    testUsingContext('R - hotRestart supported and fails fatally', () async {
      when(mockResidentRunner.canHotRestart).thenReturn(true);
      when(mockResidentRunner.hotMode).thenReturn(true);
      when(mockResidentRunner.restart(fullRestart: true))
        .thenAnswer((Invocation invocation) async {
          return OperationResult(1, 'fail', fatal: true);
        });
      expect(() => terminalHandler.processTerminalInput('R'), throwsToolExit());
    });

    testUsingContext('R - hot restart unsupported', () async {
      when(mockResidentRunner.canHotRestart).thenReturn(false);
      await terminalHandler.processTerminalInput('R');

      verifyNever(mockResidentRunner.restart(fullRestart: true));
    });

    testUsingContext('S - debugDumpSemanticsTreeInTraversalOrder with service protocol', () async {
      await terminalHandler.processTerminalInput('S');

      verify(mockResidentRunner.debugDumpSemanticsTreeInTraversalOrder()).called(1);
    });

    testUsingContext('S - debugDumpSemanticsTreeInTraversalOrder without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('S');

      verifyNever(mockResidentRunner.debugDumpSemanticsTreeInTraversalOrder());
    });

    testUsingContext('t,T - debugDumpRenderTree with service protocol', () async {
      await terminalHandler.processTerminalInput('t');
      await terminalHandler.processTerminalInput('T');

      verify(mockResidentRunner.debugDumpRenderTree()).called(2);
    });

    testUsingContext('t,T - debugDumpSemanticsTreeInTraversalOrder without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('t');
      await terminalHandler.processTerminalInput('T');

      verifyNever(mockResidentRunner.debugDumpRenderTree());
    });

    testUsingContext('U - debugDumpRenderTree with service protocol', () async {
      await terminalHandler.processTerminalInput('U');

      verify(mockResidentRunner.debugDumpSemanticsTreeInInverseHitTestOrder()).called(1);
    });

    testUsingContext('U - debugDumpSemanticsTreeInTraversalOrder without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('U');

      verifyNever(mockResidentRunner.debugDumpSemanticsTreeInInverseHitTestOrder());
    });

    testUsingContext('v - launchDevTools', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(true);
      await terminalHandler.processTerminalInput('v');

      verify(mockResidentRunner.launchDevTools()).called(1);
    });

    testUsingContext('w,W - debugDumpApp with service protocol', () async {
      await terminalHandler.processTerminalInput('w');
      await terminalHandler.processTerminalInput('W');

      verify(mockResidentRunner.debugDumpApp()).called(2);
    });

    testUsingContext('w,W - debugDumpApp without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('w');
      await terminalHandler.processTerminalInput('W');

      verifyNever(mockResidentRunner.debugDumpApp());
    });

    testUsingContext('z,Z - debugToggleDebugCheckElevationsEnabled with service protocol', () async {
      await terminalHandler.processTerminalInput('z');
      await terminalHandler.processTerminalInput('Z');

      verify(mockResidentRunner.debugToggleDebugCheckElevationsEnabled()).called(2);
    });

    testUsingContext('z,Z - debugToggleDebugCheckElevationsEnabled without service protocol', () async {
      when(mockResidentRunner.supportsServiceProtocol).thenReturn(false);
      await terminalHandler.processTerminalInput('z');
      await terminalHandler.processTerminalInput('Z');

      // This should probably be disable when the service protocol is not enabled.
      verify(mockResidentRunner.debugToggleDebugCheckElevationsEnabled()).called(2);
    });
  });
}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class MockResidentRunner extends Mock implements ResidentRunner {}
class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}

class TestRunner extends ResidentRunner {
  TestRunner(List<FlutterDevice> devices)
    : super(devices, debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug));

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
    String route,
  }) async => null;

  @override
  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
  }) async => null;
}
