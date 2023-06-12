// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

void main() {
  late MockVmService serviceMock;
  late StreamController<Map<String, Object>> requestsController;
  late StreamController<Map<String, Object?>> responsesController;
  late ServiceExtensionRegistry serviceRegistry;

  setUp(() {
    serviceMock = MockVmService();
    requestsController = StreamController<Map<String, Object>>();
    responsesController = StreamController<Map<String, Object?>>();
    serviceRegistry = ServiceExtensionRegistry();
    VmServerConnection(requestsController.stream, responsesController.sink,
        serviceRegistry, serviceMock);
  });

  tearDown(() {
    requestsController.close();
    responsesController.close();
  });

  group('method delegation', () {
    test('works for simple methods', () {
      var request = rpcRequest("getVersion");
      var version = Version(major: 1, minor: 0);
      when(serviceMock.getVersion()).thenAnswer((_) => Future.value(version));
      expect(responsesController.stream, emits(rpcResponse(version)));
      requestsController.add(request);
    });
    test('works for methods with parameters', () {
      var isolate = Isolate(
        name: 'isolate',
        exceptionPauseMode: ExceptionPauseMode.kNone,
        id: '123',
        number: '0',
        startTime: 1,
        runnable: true,
        livePorts: 2,
        isolateFlags: [],
        pauseOnExit: false,
        pauseEvent: Event(
          kind: EventKind.kResume,
          timestamp: 3,
        ),
        libraries: [],
        breakpoints: [],
        isSystemIsolate: false,
      );
      var request =
          rpcRequest("getIsolate", params: {'isolateId': isolate.id!});
      when(serviceMock.getIsolate(isolate.id!))
          .thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments, equals([isolate.id]));
        return Future.value(isolate);
      });
      expect(responsesController.stream, emits(rpcResponse(isolate)));
      requestsController.add(request);
    });

    test('works for methods with list parameters', () {
      var isolate = Isolate(
        name: 'isolate',
        exceptionPauseMode: ExceptionPauseMode.kNone,
        id: '123',
        number: '0',
        startTime: 1,
        runnable: true,
        livePorts: 2,
        isolateFlags: [],
        pauseOnExit: false,
        pauseEvent: Event(
          kind: EventKind.kResume,
          timestamp: 3,
        ),
        libraries: [],
        breakpoints: [],
        isSystemIsolate: false,
      );
      var request = rpcRequest("setVMTimelineFlags", params: {
        'isolateId': isolate.id!,
        // Note: the dynamic list below is intentional in order to exercise the
        // code under test.
        'recordedStreams': <dynamic>['GC', 'Dart', 'Embedder'],
      });
      var response = Success();
      when(serviceMock.getIsolate(isolate.id!))
          .thenAnswer((Invocation invocation) {
        expect(invocation.namedArguments,
            equals({Symbol('isolateId'): null, Symbol('args'): null}));
        return Future.value(isolate);
      });
      expect(responsesController.stream, emits(rpcResponse(response)));
      requestsController.add(request);
    });

    group('custom service extensions', () {
      test('with no params or isolateId', () {
        var extension = 'ext.cool';
        var request = rpcRequest(extension, params: null);
        var response = Response()..json = {"hello": "world"};
        when(serviceMock.callServiceExtension(
          extension,
          isolateId: argThat(isNull, named: 'isolateId'),
          args: argThat(isNull, named: 'args'),
        )).thenAnswer((Invocation invocation) {
          expect(invocation.namedArguments,
              equals({Symbol('isolateId'): null, Symbol('args'): null}));
          return Future.value(response);
        });
        expect(responsesController.stream, emits(rpcResponse(response)));
        requestsController.add(request);
      });

      test('with isolateId and no other params', () {
        var extension = 'ext.cool';
        var request = rpcRequest(extension, params: {'isolateId': '1'});
        var response = Response()..json = {"hello": "world"};
        when(serviceMock.callServiceExtension(
          extension,
          isolateId: argThat(equals('1'), named: 'isolateId'),
          args: argThat(equals({}), named: 'args'),
        )).thenAnswer((Invocation invocation) {
          expect(invocation.namedArguments,
              equals({Symbol('isolateId'): '1', Symbol('args'): {}}));
          return Future.value(response);
        });
        expect(responsesController.stream, emits(rpcResponse(response)));
        requestsController.add(request);
      });

      test('with params and no isolateId', () {
        var extension = 'ext.cool';
        var params = {'cool': 'option'};
        var request = rpcRequest(extension, params: params);
        var response = Response()..json = {"hello": "world"};
        when(serviceMock.callServiceExtension(
          extension,
          isolateId: argThat(isNull, named: 'isolateId'),
          args: argThat(equals(params), named: 'args'),
        )).thenAnswer((Invocation invocation) {
          expect(invocation.namedArguments,
              equals({Symbol('isolateId'): null, Symbol('args'): params}));
          return Future.value(response);
        });
        expect(responsesController.stream, emits(rpcResponse(response)));
        requestsController.add(request);
      });

      test('with params and isolateId', () {
        var extension = 'ext.cool';
        var params = {'cool': 'option'};
        var request =
            rpcRequest(extension, params: Map.of(params)..['isolateId'] = '1');
        var response = Response()..json = {"hello": "world"};
        when(serviceMock.callServiceExtension(
          extension,
          isolateId: argThat(equals("1"), named: 'isolateId'),
          args: argThat(equals(params), named: 'args'),
        )).thenAnswer((Invocation invocation) {
          expect(invocation.namedArguments,
              equals({Symbol('isolateId'): '1', Symbol('args'): params}));
          return Future.value(response);
        });
        expect(responsesController.stream, emits(rpcResponse(response)));
        requestsController.add(request);
      });
    });
  });

  group('error handling', () {
    test('special cases RPCError instances', () {
      var request = rpcRequest("getVersion");
      var error =
          RPCError('getVersion', 1234, 'custom message', {'custom': 'data'});
      when(serviceMock.getVersion()).thenAnswer((_) => Future.error(error));
      expect(responsesController.stream, emits(rpcErrorResponse(error)));
      requestsController.add(request);
    });

    test('has a fallback for generic exceptions', () {
      var request = rpcRequest("getVersion");
      var error = UnimplementedError();
      when(serviceMock.getVersion()).thenAnswer((_) => Future.error(error));
      expect(
          responsesController.stream.map((response) => '$response'),
          emits(startsWith(
              '{jsonrpc: 2.0, id: 1, error: {code: -32603, message: getVersion: UnimplementedError')));
      requestsController.add(request);
    });
  });

  group('streams', () {
    test('can be listened to and canceled', () async {
      var streamId = 'Isolate';
      var responseQueue = StreamQueue(responsesController.stream);
      StreamController<Event> eventController;
      {
        var request =
            rpcRequest('streamListen', params: {'streamId': streamId});
        var response = Success();
        when(serviceMock.streamListen(streamId))
            .thenAnswer((_) => Future.value(response));
        requestsController.add(request);
        await expectLater(responseQueue, emitsThrough(rpcResponse(response)));

        eventController = serviceMock.streamControllers[streamId]!;

        var events = [
          Event(
            kind: EventKind.kIsolateStart,
            timestamp: 0,
          ),
          Event(
            kind: EventKind.kIsolateExit,
            timestamp: 1,
          )
        ];
        events.forEach(eventController.add);
        await expectLater(
            responseQueue,
            emitsInOrder(
                events.map((event) => streamNotifyResponse(streamId, event))));
      }
      {
        var request =
            rpcRequest('streamCancel', params: {'streamId': streamId});
        var response = Success();
        when(serviceMock.streamListen(streamId))
            .thenAnswer((_) => Future.value(response));
        requestsController.add(request);
        await expectLater(responseQueue, emitsThrough(rpcResponse(response)));

        var nextEvent = Event(
          kind: EventKind.kIsolateReload,
          timestamp: 2,
        );
        eventController.add(nextEvent);
        expect(responseQueue,
            neverEmits(streamNotifyResponse(streamId, nextEvent)));

        await pumpEventQueue();
        await eventController.close();
        await responsesController.close();
      }
    });
    test("can't be listened to twice", () {
      var streamId = 'Isolate';
      var responseQueue = StreamQueue(responsesController.stream);
      {
        var request =
            rpcRequest('streamListen', params: {'streamId': streamId});
        var response = Success();
        when(serviceMock.streamListen(streamId))
            .thenAnswer((_) => Future.value(response));
        requestsController.add(request);
        expect(responseQueue, emitsThrough(rpcResponse(response)));
      }
      {
        var request =
            rpcRequest('streamListen', params: {'streamId': streamId});
        var response = Success();
        when(serviceMock.streamListen(streamId))
            .thenAnswer((_) => Future.value(response));
        requestsController.add(request);
        expect(
            responseQueue,
            emitsThrough(rpcErrorResponse(
                RPCError('streamSubcribe', 103, 'Stream already subscribed', {
              'details': "The stream '$streamId' is already subscribed",
            }))));
      }
    });

    test("can't cancel a stream that isn't being listened to", () {
      var streamId = 'Isolate';
      var responseQueue = StreamQueue(responsesController.stream);

      var request = rpcRequest('streamCancel', params: {'streamId': streamId});
      var response = Success();
      when(serviceMock.streamListen(streamId))
          .thenAnswer((_) => Future.value(response));
      requestsController.add(request);
      expect(
          responseQueue,
          emitsThrough(rpcErrorResponse(
              RPCError('streamCancel', 104, 'Stream not subscribed', {
            'details': "The stream '$streamId' is not subscribed",
          }))));
    });

    group('Service', () {
      final serviceStream = 'Service';

      test('gives register and unregister events', () async {
        var serviceId = 'ext.test.service';
        var serviceRegisteredEvent = streamNotifyResponse(
          serviceStream,
          Event(
            kind: EventKind.kServiceRegistered,
            timestamp: 0,
            method: serviceId,
            service: serviceId,
          ),
        );
        var serviceUnRegisteredEvent = streamNotifyResponse(
          serviceStream,
          Event(
            kind: EventKind.kServiceUnregistered,
            timestamp: 0,
            method: serviceId,
            service: serviceId,
          ),
        );

        requestsController.add(
            rpcRequest('streamListen', params: {'streamId': serviceStream}));
        requestsController
            .add(rpcRequest('registerService', params: {'service': serviceId}));
        await expectLater(
            responsesController.stream
                .map((Map response) => stripEventTimestamp(response)),
            emitsThrough(serviceRegisteredEvent));

        // Connect another client to get the previous register events and the
        // unregister event.
        var requestsController2 = StreamController<Map<String, Object>>();
        var responsesController2 = StreamController<Map<String, Object?>>();
        addTearDown(() {
          requestsController2.close();
          responsesController2.close();
        });

        VmServerConnection(
          requestsController2.stream,
          responsesController2.sink,
          serviceRegistry,
          VmService(Stream.empty(), (String _) => null),
        );

        expect(
            responsesController2.stream
                .map((Map response) => stripEventTimestamp(response)),
            emitsThrough(emitsInOrder(
                [serviceRegisteredEvent, serviceUnRegisteredEvent])));

        // Should get the previously registered extension event, as well as
        // the unregister event when the client disconnects.
        requestsController2.add(
            rpcRequest('streamListen', params: {'streamId': serviceStream}));
        // Need to give the client a chance to subscribe.
        await pumpEventQueue();
        unawaited(requestsController.close());
        // Give the old client a chance to shut down
        await pumpEventQueue();

        // Connect yet another client, it should get zero registration or
        // unregistration events.
        var requestsController3 = StreamController<Map<String, Object>>();
        var responsesController3 = StreamController<Map<String, Object?>>();

        VmServerConnection(
          requestsController3.stream,
          responsesController3.sink,
          serviceRegistry,
          VmService(Stream.empty(), (String _) => null),
        );
        expect(
            responsesController3.stream,
            neverEmits(
                anyOf(serviceRegisteredEvent, serviceUnRegisteredEvent)));
        // Give it a chance to deliver events.
        await pumpEventQueue();
        // Disconnect the client so the test can shut down.
        unawaited(requestsController3.close());
        unawaited(responsesController3.close());
      });
    });
  });

  group('registerService', () {
    test('can delegate requests between clients', () async {
      var serviceId = 'ext.test.service';
      var responseQueue = StreamQueue(responsesController.stream);

      var clientInputController =
          StreamController<Map<String, Object?>>.broadcast();
      var clientOutputController =
          StreamController<Map<String, Object>>.broadcast();
      var client = VmService(
          clientInputController.stream.map(jsonEncode),
          (String message) => clientOutputController
              .add(jsonDecode(message).cast<String, Object>()),
          disposeHandler: () async {
        await clientInputController.close();
        await clientOutputController.close();
      });

      var clientConnection = VmServerConnection(clientOutputController.stream,
          clientInputController.sink, serviceRegistry, serviceMock);

      var requestParams = {'foo': 'bar'};
      var expectedResponse = Response()..json = {'zap': 'zip'};
      await client.registerService(serviceId, 'service');
      // Duplicate registrations should fail.
      expect(client.registerService(serviceId, 'service'),
          throwsA(const TypeMatcher<RPCError>()));

      client.registerServiceCallback(serviceId, (request) async {
        expect(request, equals(requestParams));
        return {'result': expectedResponse.toJson()};
      });

      var serviceRequest = rpcRequest(serviceId, params: requestParams);

      requestsController.add(serviceRequest);
      expect(await responseQueue.next, rpcResponse(expectedResponse));

      // Kill the client that registered the handler, it should now fall back
      // on `callServiceExtension`.
      await client.dispose();
      // This should complete as well.
      await clientConnection.done;

      var mockResponse = Response()..json = {'mock': 'response'};
      when(serviceMock.callServiceExtension(serviceId,
              args: argThat(equals(requestParams), named: 'args'),
              isolateId: argThat(isNull, named: 'isolateId')))
          .thenAnswer((_) async => mockResponse);

      requestsController.add(serviceRequest);
      expect(await responseQueue.next, rpcResponse(mockResponse));
    });
  });
}

Map<String, Object> rpcRequest(String method,
        {Map<String, Object>? params = const {}, String id = "1"}) =>
    {
      "jsonrpc": "2.0",
      "method": method,
      if (params != null) "params": params,
      "id": id,
    };

Map<String, Object> rpcResponse(Response response, {String id = "1"}) => {
      'jsonrpc': '2.0',
      'id': id,
      'result': response.toJson(),
    };

Map<String, Object> rpcErrorResponse(Object error, {String id = "1"}) {
  Map<String, Object> errorJson;
  if (error is RPCError) {
    errorJson = {
      'code': error.code,
      'message': error.message,
    };
    if (error.data != null) {
      errorJson['data'] = error.data!;
    }
  } else {
    errorJson = {
      'code': -32603,
      'message': error.toString(),
    };
  }
  return {
    'jsonrpc': '2.0',
    'id': id,
    'error': errorJson,
  };
}

Map<String, Object> streamNotifyResponse(String streamId, Event event) {
  return {
    'jsonrpc': '2.0',
    'method': 'streamNotify',
    'params': {
      'streamId': '$streamId',
      'event': event.toJson(),
    },
  };
}

Map<String, Object?> stripEventTimestamp(Map response) {
  if (response.containsKey('params') &&
      response['params'].containsKey('event')) {
    response['params']['event']['timestamp'] = 0;
  }
  return response as Map<String, Object?>;
}

class MockVmService extends Mock implements VmServiceInterface {
  final streamControllers = <String, StreamController<Event>>{};

  @override
  Future<Version> getVersion() {
    return super.noSuchMethod(Invocation.method(#getVersion, []),
        returnValue: Future.value(Version(major: 0, minor: 0)));
  }

  @override
  Future<Isolate> getIsolate(String isolateId) {
    return super.noSuchMethod(Invocation.method(#getIsolate, [isolateId]),
        returnValue: Future.value(Isolate(
            id: null,
            number: null,
            name: null,
            isSystemIsolate: null,
            isolateFlags: null,
            startTime: null,
            runnable: null,
            livePorts: null,
            pauseOnExit: null,
            pauseEvent: null,
            libraries: null,
            breakpoints: null,
            exceptionPauseMode: null)));
  }

  @override
  Future<Response> callServiceExtension(
    String method, {
    String? isolateId,
    Map<String, dynamic>? args,
  }) {
    return super.noSuchMethod(
        Invocation.method(#callServiceExtension, [method],
            {#isolateId: isolateId, #args: args}),
        returnValue: Future.value(Response()));
  }

  @override
  Future<Success> streamListen(String streamId) {
    return super.noSuchMethod(Invocation.method(#streamListen, [streamId]),
        returnValue: Future.value(Success()));
  }

  @override
  Stream<Event> onEvent(String streamId) => streamControllers
      .putIfAbsent(streamId, () => StreamController<Event>())
      .stream;

  @override
  Future<Success> setVMTimelineFlags(List<String> recordedStreams) async {
    return Success();
  }
}
