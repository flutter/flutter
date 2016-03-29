// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:test/test.dart';
import 'package:flutter_driver/src/driver.dart';
import 'package:flutter_driver/src/error.dart';
import 'package:flutter_driver/src/health.dart';
import 'package:flutter_driver/src/message.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:mockito/mockito.dart';
import 'package:quiver/testing/async.dart';
import 'package:vm_service_client/vm_service_client.dart';

void main() {
  group('FlutterDriver.connect', () {
    List<LogRecord> log;
    StreamSubscription<LogRecord> logSub;
    MockVMServiceClient mockClient;
    MockVM mockVM;
    MockIsolate mockIsolate;

    void expectLogContains(String message) {
      expect(log.map((LogRecord r) => '$r'), anyElement(contains(message)));
    }

    setUp(() {
      log = <LogRecord>[];
      logSub = flutterDriverLog.listen(log.add);
      mockClient = new MockVMServiceClient();
      mockVM = new MockVM();
      mockIsolate = new MockIsolate();
      when(mockClient.getVM()).thenReturn(mockVM);
      when(mockVM.isolates).thenReturn([mockIsolate]);
      when(mockIsolate.loadRunnable()).thenReturn(mockIsolate);
      when(mockIsolate.invokeExtension(any, any))
          .thenReturn(new Future<Map<String, dynamic>>.value(<String, String>{'status': 'ok'}));
      vmServiceConnectFunction = (String url) {
        return new Future<VMServiceClientConnection>.value(
          new VMServiceClientConnection(mockClient, null)
        );
      };
    });

    tearDown(() async {
      await logSub.cancel();
      restoreVmServiceConnectFunction();
    });

    test('connects to isolate paused at start', () async {
      when(mockIsolate.pauseEvent).thenReturn(new MockVMPauseStartEvent());
      when(mockIsolate.resume()).thenReturn(new Future<Null>.value());
      when(mockIsolate.onExtensionAdded).thenReturn(new Stream<String>.fromIterable(<String>['ext.flutter_driver']));

      FlutterDriver driver = await FlutterDriver.connect();
      expect(driver, isNotNull);
      expectLogContains('Isolate is paused at start');
    });

    test('connects to isolate paused mid-flight', () async {
      when(mockIsolate.pauseEvent).thenReturn(new MockVMPauseBreakpointEvent());
      when(mockIsolate.resume()).thenReturn(new Future<Null>.value());

      FlutterDriver driver = await FlutterDriver.connect();
      expect(driver, isNotNull);
      expectLogContains('Isolate is paused mid-flight');
    });

    // This test simulates a situation when we believe that the isolate is
    // currently paused, but something else (e.g. a debugger) resumes it before
    // we do. There's no need to fail as we should be able to drive the app
    // just fine.
    test('connects despite losing the race to resume isolate', () async {
      when(mockIsolate.pauseEvent).thenReturn(new MockVMPauseBreakpointEvent());
      when(mockIsolate.resume()).thenAnswer((_) {
        // This needs to be wrapped in a closure to not be considered uncaught
        // by package:test
        return new Future<Null>.error(new rpc.RpcException(101, ''));
      });

      FlutterDriver driver = await FlutterDriver.connect();
      expect(driver, isNotNull);
      expectLogContains('Attempted to resume an already resumed isolate');
    });

    test('connects to unpaused isolate', () async {
      when(mockIsolate.pauseEvent).thenReturn(new MockVMResumeEvent());
      FlutterDriver driver = await FlutterDriver.connect();
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
      mockClient = new MockVMServiceClient();
      mockPeer = new MockPeer();
      mockIsolate = new MockIsolate();
      driver = new FlutterDriver.connectedTo(mockClient, mockPeer, mockIsolate);
    });

    test('checks the health of the driver extension', () async {
      when(mockIsolate.invokeExtension(any, any)).thenReturn(new Future<Map<String, dynamic>>.value(<String, dynamic>{
        'status': 'ok',
      }));
      Health result = await driver.checkHealth();
      expect(result.status, HealthStatus.ok);
    });

    test('closes connection', () async {
      when(mockClient.close()).thenReturn(new Future<Null>.value());
      await driver.close();
    });

    group('findByValueKey', () {
      test('restricts value types', () async {
        expect(driver.findByValueKey(null),
            throwsA(new isInstanceOf<DriverError>()));
      });

      test('finds by ValueKey', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], {
            'command': 'find',
            'searchSpecType': 'ByValueKey',
            'keyValueString': 'foo',
            'keyValueType': 'String'
          });
          return new Future<Map<String, dynamic>>.value(<String, dynamic>{
            'objectReferenceKey': '123',
          });
        });
        ObjectRef result = await driver.findByValueKey('foo');
        expect(result, isNotNull);
        expect(result.objectReferenceKey, '123');
      });
    });

    group('tap', () {
      test('requires a target reference', () async {
        expect(driver.tap(null), throwsA(new isInstanceOf<DriverError>()));
      });

      test('requires a valid target reference', () async {
        expect(driver.tap(new ObjectRef.notFound()),
          throwsA(new isInstanceOf<DriverError>()));
      });

      test('sends the tap command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'tap',
            'targetRef': '123'
          });
          return new Future<Map<String, dynamic>>.value();
        });
        await driver.tap(new ObjectRef('123'));
      });
    });

    group('getText', () {
      test('requires a target reference', () async {
        expect(driver.getText(null), throwsA(new isInstanceOf<DriverError>()));
      });

      test('requires a valid target reference', () async {
        expect(driver.getText(new ObjectRef.notFound()),
          throwsA(new isInstanceOf<DriverError>()));
      });

      test('sends the getText command', () async {
        when(mockIsolate.invokeExtension(any, any)).thenAnswer((Invocation i) {
          expect(i.positionalArguments[1], <String, dynamic>{
            'command': 'get_text',
            'targetRef': '123'
          });
          return new Future<Map<String, dynamic>>.value({
            'text': 'hello'
          });
        });
        String result = await driver.getText(new ObjectRef('123'));
        expect(result, 'hello');
      });
    });

    group('waitFor', () {
      test('waits for a condition', () {
        expect(
          driver.waitFor(() {
            return new Future<int>.delayed(
              new Duration(milliseconds: 50),
              () => 123
            );
          }, equals(123)),
          completion(123)
        );
      });

      test('retries a correct number of times', () {
        new FakeAsync().run((FakeAsync fakeAsync) {
          int retryCount = 0;

          expect(
            driver.waitFor(
              () {
                retryCount++;
                return retryCount;
              },
              equals(2),
              timeout: new Duration(milliseconds: 30),
              pauseBetweenRetries: new Duration(milliseconds: 10)
            ),
            completion(2)
          );

          fakeAsync.elapse(new Duration(milliseconds: 50));

          // Check that we didn't retry more times than necessary
          expect(retryCount, 2);
        });
      });

      test('times out', () async {
        bool timedOut = false;
        await driver.waitFor(
          () => 1,
          equals(2),
          timeout: new Duration(milliseconds: 10),
          pauseBetweenRetries: new Duration(milliseconds: 2)
        ).catchError((dynamic err, dynamic stack) {
          timedOut = true;
        });

        expect(timedOut, isTrue);
      });
    });

    group('traceAction', () {
      test('traces action', () async {
        bool actionCalled = false;
        bool startTracingCalled = false;
        bool stopTracingCalled = false;

        when(mockPeer.sendRequest('_setVMTimelineFlags', argThat(equals({'recordedStreams': '[all]'}))))
          .thenAnswer((_) async {
            startTracingCalled = true;
            return null;
          });

        when(mockPeer.sendRequest('_setVMTimelineFlags', argThat(equals({'recordedStreams': '[]'}))))
          .thenAnswer((_) async {
            stopTracingCalled = true;
            return null;
          });

        when(mockPeer.sendRequest('_getVMTimeline')).thenAnswer((_) async {
          return <String, dynamic> {
            'test': 'profile',
          };
        });

        Map<String, dynamic> profile = await driver.traceAction(() {
          actionCalled = true;
        });

        expect(actionCalled, isTrue);
        expect(startTracingCalled, isTrue);
        expect(stopTracingCalled, isTrue);
        expect(profile['test'], 'profile');
      });
    });
  });
}

@proxy
class MockVMServiceClient extends Mock implements VMServiceClient { }

@proxy
class MockVM extends Mock implements VM { }

@proxy
class MockIsolate extends Mock implements VMRunnableIsolate { }

@proxy
class MockVMPauseStartEvent extends Mock implements VMPauseStartEvent { }

@proxy
class MockVMPauseBreakpointEvent extends Mock implements VMPauseBreakpointEvent { }

@proxy
class MockVMResumeEvent extends Mock implements VMResumeEvent { }

@proxy
class MockPeer extends Mock implements rpc.Peer { }
