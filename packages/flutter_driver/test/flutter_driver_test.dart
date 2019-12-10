// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/src/common/error.dart';
import 'package:flutter_driver/src/common/health.dart';
import 'package:flutter_driver/src/common/wait.dart';
import 'package:flutter_driver/src/driver/driver.dart';
import 'package:flutter_driver/src/driver/timeline.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:mockito/mockito.dart';
import 'package:vm_service_client/vm_service_client.dart';
import 'package:quiver/testing/async.dart';

import 'common.dart';

/// Magical timeout value that's different from the default.
const Duration _kTestTimeout = Duration(milliseconds: 1234);
const String _kSerializedTestTimeout = '1234';

void main() {
  final List<String> log = <String>[];
  driverLog = (String source, String message) {
    log.add('$source: $message');
  };

  group('FlutterDriver.connect', () {
    MockVMServiceClient mockClient;
    MockVM mockVM;
    MockIsolate mockIsolate;
    MockPeer mockPeer;

    void expectLogContains(String message) {
      expect(log, anyElement(contains(message)));
    }

    setUp(() {
      log.clear();
      mockClient = MockVMServiceClient();
      mockVM = MockVM();
      mockIsolate = MockIsolate();
      mockPeer = MockPeer();
      when(mockClient.getVM()).thenAnswer((_) => Future<MockVM>.value(mockVM));
      when(mockVM.isolates).thenReturn(<VMRunnableIsolate>[mockIsolate]);
      when(mockIsolate.loadRunnable()).thenAnswer((_) => Future<MockIsolate>.value(mockIsolate));
      when(mockIsolate.invokeExtension(any, any)).thenAnswer(
          (Invocation invocation) => makeMockResponse(<String, dynamic>{'status': 'ok'}));
      vmServiceConnectFunction = (String url) {
        return Future<VMServiceClientConnection>.value(
          VMServiceClientConnection(mockClient, mockPeer)
        );
      };
    });

    tearDown(() async {
      restoreVmServiceConnectFunction();
    });

    test('connects to isolate paused at start', () async {
      final List<String> connectionLog = <String>[];
      when(mockPeer.sendRequest('streamListen', any)).thenAnswer((Invocation invocation) {
        connectionLog.add('streamListen');
        return null;
      });
      when(mockIsolate.pauseEvent).thenReturn(MockVMPauseStartEvent());
      when(mockIsolate.resume()).thenAnswer((Invocation invocation) {
        connectionLog.add('resume');
        return Future<dynamic>.value(null);
      });
      when(mockIsolate.onExtensionAdded).thenAnswer((Invocation invocation) {
        connectionLog.add('onExtensionAdded');
        return Stream<String>.fromIterable(<String>['ext.flutter.driver']);
      });

      final FlutterDriver driver = await FlutterDriver.connect(dartVmServiceUrl: '');
      expect(driver, isNotNull);
      expectLogContains('Isolate is paused at start');
      expect(connectionLog, <String>['streamListen', 'onExtensionAdded', 'resume']);
    });

    test('connects to isolate paused mid-flight', () async {
      when(mockIsolate.pauseEvent).thenReturn(MockVMPauseBreakpointEvent());
      when(mockIsolate.resume()).thenAnswer((Invocation invocation) => Future<dynamic>.value(null));

      final FlutterDriver driver = await FlutterDriver.connect(dartVmServiceUrl: '');
      expect(driver, isNotNull);
      expectLogContains('Isolate is paused mid-flight');
    });

    // This test simulates a situation when we believe that the isolate is
    // currently paused, but something else (e.g. a debugger) resumes it before
    // we do. There's no need to fail as we should be able to drive the app
    // just fine.
    test('connects despite losing the race to resume isolate', () async {
      when(mockIsolate.pauseEvent).thenReturn(MockVMPauseBreakpointEvent());
      when(mockIsolate.resume()).thenAnswer((Invocation invocation) {
        // This needs to be wrapped in a closure to not be considered uncaught
        // by package:test
        return Future<dynamic>.error(rpc.RpcException(101, ''));
      });

      final FlutterDriver driver = await FlutterDriver.connect(dartVmServiceUrl: '');
      expect(driver, isNotNull);
      expectLogContains('Attempted to resume an already resumed isolate');
    });

    test('connects to unpaused isolate', () async {
      when(mockIsolate.pauseEvent).thenReturn(MockVMResumeEvent());
      final FlutterDriver driver = await FlutterDriver.connect(dartVmServiceUrl: '');
      expect(driver, isNotNull);
      expectLogContains('Isolate is not paused. Assuming application is ready.');
    });
  });

  group('FlutterDriver', () {
    MockVMServiceClient mockClient;
    MockPeer mockPeer;
    MockIsolate mockIsolate;
    FlutterDriver driver;

    setUp(() {
      mockClient = MockVMServiceClient();
      mockPeer = MockPeer();
      mockIsolate = MockIsolate();
      driver = FlutterDriver.connectedTo(mockClient, mockPeer, mockIsolate);
    });

    test('checks the health of the driver extension', () async {
      when(mockIsolate.invokeExtension(any, any)).thenAnswer(
          (Invocation invocation) => makeMockResponse(<String, dynamic>{'status': 'ok'}));
      final Health result = await driver.checkHealth();
      expect(result.status, HealthStatus.ok);
    });

    test('closes connection', () async {
      when(mockClient.close()).thenAnswer((Invocation invocation) => Future<dynamic>.value(null));
      await driver.close();
    });

    group('ByValueKey', () {
      test('restricts value types', () async {
        expect(() => find.byValueKey(null),
            throwsA(isInstanceOf<DriverError>()));
      });

      test('finds by ValueKey', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, String>{
            'command': 'tap',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'ByValueKey',
            'keyValueString': 'foo',
            'keyValueType': 'String',
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.tap(find.byValueKey('foo'), timeout: _kTestTimeout);
      });
    });

    group('BySemanticsLabel', () {
      test('finds by Semantic label using String', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, String>{
            'command': 'tap',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'BySemanticsLabel',
            'label': 'foo',
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.tap(find.bySemanticsLabel('foo'), timeout: _kTestTimeout);
      });

      test('finds by Semantic label using RegExp', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, String>{
            'command': 'tap',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'BySemanticsLabel',
            'label': '^foo',
            'isRegExp': 'true',
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.tap(find.bySemanticsLabel(RegExp('^foo')), timeout: _kTestTimeout);
      });
    });

    group('tap', () {
      test('requires a target reference', () async {
        expect(driver.tap(null), throwsA(isInstanceOf<DriverError>()));
      });

      test('sends the tap command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'tap',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'ByText',
            'text': 'foo',
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.tap(find.text('foo'), timeout: _kTestTimeout);
      });
    });

    group('getText', () {
      test('requires a target reference', () async {
        expect(driver.getText(null), throwsA(isInstanceOf<DriverError>()));
      });

      test('sends the getText command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'get_text',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'ByValueKey',
            'keyValueString': '123',
            'keyValueType': 'int',
          });
          return makeMockResponse(<String, String>{
            'text': 'hello',
          });
        });
        final String result = await driver.getText(find.byValueKey(123), timeout: _kTestTimeout);
        expect(result, 'hello');
      });
    });

    group('waitFor', () {
      test('requires a target reference', () async {
        expect(driver.waitFor(null), throwsA(isInstanceOf<DriverError>()));
      });

      test('sends the waitFor command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'waitFor',
            'finderType': 'ByTooltipMessage',
            'text': 'foo',
            'timeout': _kSerializedTestTimeout,
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.waitFor(find.byTooltip('foo'), timeout: _kTestTimeout);
      });
    });

    group('getWidgetDiagnostics', () {
      test('sends the getWidgetDiagnostics command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'get_diagnostics_tree',
            'diagnosticsType': 'widget',
            'finderType': 'ByTooltipMessage',
            'text': 'foo',
            'includeProperties': 'true',
            'subtreeDepth': '0',
            'timeout': _kSerializedTestTimeout,
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.getWidgetDiagnostics(find.byTooltip('foo'), timeout: _kTestTimeout);
      });
    });

    group('getRenderObjectDiagnostics', () {
      test('sends the getRenderObjectDiagnostics command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'get_diagnostics_tree',
            'diagnosticsType': 'renderObject',
            'finderType': 'ByTooltipMessage',
            'text': 'foo',
            'includeProperties': 'true',
            'subtreeDepth': '0',
            'timeout': _kSerializedTestTimeout,
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.getRenderObjectDiagnostics(find.byTooltip('foo'), timeout: _kTestTimeout);
      });
    });

    group('waitForCondition', () {
      test('sends the wait for NoPendingFrameCondition command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'waitForCondition',
            'timeout': _kSerializedTestTimeout,
            'conditionName': 'NoPendingFrameCondition',
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.waitForCondition(const NoPendingFrame(), timeout: _kTestTimeout);
      });

      test('sends the wait for NoPendingPlatformMessages command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'waitForCondition',
            'timeout': _kSerializedTestTimeout,
            'conditionName': 'NoPendingPlatformMessagesCondition',
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.waitForCondition(const NoPendingPlatformMessages(), timeout: _kTestTimeout);
      });

      test('sends the waitForCondition of combined conditions command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'waitForCondition',
            'timeout': _kSerializedTestTimeout,
            'conditionName': 'CombinedCondition',
            'conditions': '[{"conditionName":"NoPendingFrameCondition"},{"conditionName":"NoTransientCallbacksCondition"}]',
          });
          return makeMockResponse(<String, dynamic>{});
        });
        const SerializableWaitCondition combinedCondition =
            CombinedCondition(<SerializableWaitCondition>[NoPendingFrame(), NoTransientCallbacks()]);
        await driver.waitForCondition(combinedCondition, timeout: _kTestTimeout);
      });
    });

    group('waitUntilNoTransientCallbacks', () {
      test('sends the waitUntilNoTransientCallbacks command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'waitForCondition',
            'timeout': _kSerializedTestTimeout,
            'conditionName': 'NoTransientCallbacksCondition',
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.waitUntilNoTransientCallbacks(timeout: _kTestTimeout);
      });
    });

    group('waitUntilFirstFrameRasterized', () {
      test('sends the waitUntilFirstFrameRasterized command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'waitForCondition',
            'conditionName': 'FirstFrameRasterizedCondition',
          });
          return makeMockResponse(<String, dynamic>{});
        });
        await driver.waitUntilFirstFrameRasterized();
      });
    });

    group('getOffset', () {
      test('requires a target reference', () async {
        expect(driver.getCenter(null), throwsA(isInstanceOf<DriverError>()));
        expect(driver.getTopLeft(null), throwsA(isInstanceOf<DriverError>()));
        expect(driver.getTopRight(null), throwsA(isInstanceOf<DriverError>()));
        expect(driver.getBottomLeft(null), throwsA(isInstanceOf<DriverError>()));
        expect(driver.getBottomRight(null), throwsA(isInstanceOf<DriverError>()));
      });

      test('sends the getCenter command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'get_offset',
            'offsetType': 'center',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'ByValueKey',
            'keyValueString': '123',
            'keyValueType': 'int',
          });
          return makeMockResponse(<String, double>{
            'dx': 11,
            'dy': 12,
          });
        });
        final DriverOffset result = await driver.getCenter(find.byValueKey(123), timeout: _kTestTimeout);
        expect(result, const DriverOffset(11, 12));
      });

      test('sends the getTopLeft command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'get_offset',
            'offsetType': 'topLeft',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'ByValueKey',
            'keyValueString': '123',
            'keyValueType': 'int',
          });
          return makeMockResponse(<String, double>{
            'dx': 11,
            'dy': 12,
          });
        });
        final DriverOffset result = await driver.getTopLeft(find.byValueKey(123), timeout: _kTestTimeout);
        expect(result, const DriverOffset(11, 12));
      });

      test('sends the getTopRight command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'get_offset',
            'offsetType': 'topRight',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'ByValueKey',
            'keyValueString': '123',
            'keyValueType': 'int',
          });
          return makeMockResponse(<String, double>{
            'dx': 11,
            'dy': 12,
          });
        });
        final DriverOffset result = await driver.getTopRight(find.byValueKey(123), timeout: _kTestTimeout);
        expect(result, const DriverOffset(11, 12));
      });

      test('sends the getBottomLeft command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'get_offset',
            'offsetType': 'bottomLeft',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'ByValueKey',
            'keyValueString': '123',
            'keyValueType': 'int',
          });
          return makeMockResponse(<String, double>{
            'dx': 11,
            'dy': 12,
          });
        });
        final DriverOffset result = await driver.getBottomLeft(find.byValueKey(123), timeout: _kTestTimeout);
        expect(result, const DriverOffset(11, 12));
      });

      test('sends the getBottomRight command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'get_offset',
            'offsetType': 'bottomRight',
            'timeout': _kSerializedTestTimeout,
            'finderType': 'ByValueKey',
            'keyValueString': '123',
            'keyValueType': 'int',
          });
          return makeMockResponse(<String, double>{
            'dx': 11,
            'dy': 12,
          });
        });
        final DriverOffset result = await driver.getBottomRight(find.byValueKey(123), timeout: _kTestTimeout);
        expect(result, const DriverOffset(11, 12));
      });
    });

    group('clearTimeline', () {
      test('clears timeline', () async {
        bool clearWasCalled = false;
        when(mockPeer.sendRequest('clearVMTimeline', argThat(equals(<String, dynamic>{}))))
          .thenAnswer((Invocation invocation) async {
            clearWasCalled = true;
            return null;
          });
        await driver.clearTimeline();
        expect(clearWasCalled, isTrue);
      });
    });

    group('traceAction', () {
      List<String> log;

      setUp(() async {
        log = <String>[];

        when(mockPeer.sendRequest('clearVMTimeline', argThat(equals(<String, dynamic>{}))))
          .thenAnswer((Invocation invocation) async {
            log.add('clear');
            return null;
          });

        when(mockPeer.sendRequest('setVMTimelineFlags', argThat(equals(<String, dynamic>{'recordedStreams': '[all]'}))))
          .thenAnswer((Invocation invocation) async {
            log.add('startTracing');
            return null;
          });

        when(mockPeer.sendRequest('setVMTimelineFlags', argThat(equals(<String, dynamic>{'recordedStreams': '[]'}))))
          .thenAnswer((Invocation invocation) async {
            log.add('stopTracing');
            return null;
          });

        when(mockPeer.sendRequest('getVMTimeline')).thenAnswer((Invocation invocation) async {
          log.add('download');
          return <String, dynamic>{
            'traceEvents': <dynamic>[
              <String, String>{
                'name': 'test event',
              },
            ],
          };
        });
      });

      test('without clearing timeline', () async {
        final Timeline timeline = await driver.traceAction(() async {
          log.add('action');
        }, retainPriorEvents: true);

        expect(log, const <String>[
          'startTracing',
          'action',
          'stopTracing',
          'download',
        ]);
        expect(timeline.events.single.name, 'test event');
      });

      test('with clearing timeline', () async {
        final Timeline timeline = await driver.traceAction(() async {
          log.add('action');
        });

        expect(log, const <String>[
          'clear',
          'startTracing',
          'action',
          'stopTracing',
          'download',
        ]);
        expect(timeline.events.single.name, 'test event');
      });
    });

    group('traceAction with timeline streams', () {
      test('specify non-default timeline streams', () async {
        bool actionCalled = false;
        bool startTracingCalled = false;
        bool stopTracingCalled = false;

        when(mockPeer.sendRequest('setVMTimelineFlags', argThat(equals(<String, dynamic>{'recordedStreams': '[Dart, GC, Compiler]'}))))
          .thenAnswer((Invocation invocation) async {
            startTracingCalled = true;
            return null;
          });

        when(mockPeer.sendRequest('setVMTimelineFlags', argThat(equals(<String, dynamic>{'recordedStreams': '[]'}))))
          .thenAnswer((Invocation invocation) async {
            stopTracingCalled = true;
            return null;
          });

        when(mockPeer.sendRequest('getVMTimeline')).thenAnswer((Invocation invocation) async {
          return <String, dynamic>{
            'traceEvents': <dynamic>[
              <String, String>{
                'name': 'test event',
              },
            ],
          };
        });

        final Timeline timeline = await driver.traceAction(() async {
          actionCalled = true;
        },
        streams: const <TimelineStream>[
          TimelineStream.dart,
          TimelineStream.gc,
          TimelineStream.compiler,
        ],
        retainPriorEvents: true);

        expect(actionCalled, isTrue);
        expect(startTracingCalled, isTrue);
        expect(stopTracingCalled, isTrue);
        expect(timeline.events.single.name, 'test event');
      });
    });

    group('sendCommand error conditions', () {
      test('local default timeout', () async {
        log.clear();
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          // completer never completed to trigger timeout
          return Completer<Map<String, dynamic>>().future;
        });
        FakeAsync().run((FakeAsync time) {
          driver.waitFor(find.byTooltip('foo'));
          expect(log, <String>[]);
          time.elapse(kUnusuallyLongTimeout);
        });
        expect(log, <String>['FlutterDriver: waitFor message is taking a long time to complete...']);
      });

      test('local custom timeout', () async {
        log.clear();
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          // completer never completed to trigger timeout
          return Completer<Map<String, dynamic>>().future;
        });
        FakeAsync().run((FakeAsync time) {
          final Duration customTimeout = kUnusuallyLongTimeout - const Duration(seconds: 1);
          driver.waitFor(find.byTooltip('foo'), timeout: customTimeout);
          expect(log, <String>[]);
          time.elapse(customTimeout);
        });
        expect(log, <String>['FlutterDriver: waitFor message is taking a long time to complete...']);
      });

      test('remote error', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          return makeMockResponse(<String, dynamic>{
            'message': 'This is a failure',
          }, isError: true);
        });
        try {
          await driver.waitFor(find.byTooltip('foo'));
          fail('expected an exception');
        } catch (error) {
          expect(error is DriverError, isTrue);
          expect(error.message, 'Error in Flutter application: {message: This is a failure}');
        }
      });
    });
  });

  group('FlutterDriver with custom timeout', () {
    MockVMServiceClient mockClient;
    MockPeer mockPeer;
    MockIsolate mockIsolate;
    FlutterDriver driver;

    setUp(() {
      mockClient = MockVMServiceClient();
      mockPeer = MockPeer();
      mockIsolate = MockIsolate();
      driver = FlutterDriver.connectedTo(mockClient, mockPeer, mockIsolate);
    });

    test('GetHealth has no default timeout', () async {
      when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
        expect(i.positionalArguments[1], <String, String>{
          'command': 'get_health',
        });
        return makeMockResponse(<String, dynamic>{'status': 'ok'});
      });
      await driver.checkHealth();
    });

    test('does not interfere with explicit timeouts', () async {
      when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
        expect(i.positionalArguments[1], <String, String>{
          'command': 'get_health',
          'timeout': _kSerializedTestTimeout,
        });
        return makeMockResponse(<String, dynamic>{'status': 'ok'});
      });
      await driver.checkHealth(timeout: _kTestTimeout);
    });
  });
}

Future<Map<String, dynamic>> makeMockResponse(
  Map<String, dynamic> response, {
  bool isError = false,
}) {
  return Future<Map<String, dynamic>>.value(<String, dynamic>{
    'isError': isError,
    'response': response,
  });
}

class MockVMServiceClient extends Mock implements VMServiceClient { }

class MockVM extends Mock implements VM { }

class MockIsolate extends Mock implements VMRunnableIsolate { }

class MockVMPauseStartEvent extends Mock implements VMPauseStartEvent { }

class MockVMPauseBreakpointEvent extends Mock implements VMPauseBreakpointEvent { }

class MockVMResumeEvent extends Mock implements VMResumeEvent { }

class MockPeer extends Mock implements rpc.Peer {
  @override
  bool get isClosed => false;
}
