// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/daemon.dart';
import 'package:test/fake.dart';

import '../src/common.dart';

class FakeDaemonStreams extends DaemonStreams {
  final StreamController<Map<String, dynamic>> inputs = StreamController<Map<String, dynamic>>();
  final StreamController<Map<String, dynamic>> outputs = StreamController<Map<String, dynamic>>();

  @override
  Stream<Map<String, dynamic>> get inputStream {
    return inputs.stream;
  }

  @override
  void send(Map<String, dynamic> message) {
    outputs.add(message);
  }

  @override
  Future<void> dispose() async {
    await inputs.close();
    // In some tests, outputs have no listeners. We don't wait for outputs to close.
    unawaited(outputs.close());
  }
}

void main() {
  late BufferLogger bufferLogger;
  late FakeDaemonStreams daemonStreams;
  late DaemonConnection daemonConnection;
  setUp(() {
    bufferLogger = BufferLogger.test();
    daemonStreams = FakeDaemonStreams();
    daemonConnection = DaemonConnection(
      daemonStreams: daemonStreams,
      logger: bufferLogger,
    );
  });

  tearDown(() async {
    await daemonConnection.dispose();
  });

  group('DaemonConnection receiving end', () {
    testWithoutContext('redirects input to incoming commands', () async {
      final Map<String, dynamic> commandToSend = <String, dynamic>{'id': 0, 'method': 'some_method'};
      daemonStreams.inputs.add(commandToSend);

      final Map<String, dynamic> commandReceived = await daemonConnection.incomingCommands.first;
      await daemonStreams.dispose();

      expect(commandReceived, commandToSend);
    });

    testWithoutContext('listenToEvent can receive the right events', () async {
      final Future<List<dynamic>> events = daemonConnection.listenToEvent('event1').toList();

      daemonStreams.inputs.add(<String, dynamic>{'event': 'event1', 'params': '1'});
      daemonStreams.inputs.add(<String, dynamic>{'event': 'event2', 'params': '2'});
      daemonStreams.inputs.add(<String, dynamic>{'event': 'event1', 'params': null});
      daemonStreams.inputs.add(<String, dynamic>{'event': 'event1', 'params': 3});

      await pumpEventQueue();
      await daemonConnection.dispose();

      expect(await events, <dynamic>['1', null, 3]);
    });
  });

  group('DaemonConnection sending end', () {
    testWithoutContext('sending requests', () async {
      unawaited(daemonConnection.sendRequest('some_method', 'param'));
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;
      expect(data['id'], isNotNull);
      expect(data['method'], 'some_method');
      expect(data['params'], 'param');
    });

    testWithoutContext('sending requests without param', () async {
      unawaited(daemonConnection.sendRequest('some_method'));
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;
      expect(data['id'], isNotNull);
      expect(data['method'], 'some_method');
      expect(data['params'], isNull);
    });

    testWithoutContext('sending response', () async {
      daemonConnection.sendResponse('1', 'some_data');
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;
      expect(data['id'], '1');
      expect(data['method'], isNull);
      expect(data['error'], isNull);
      expect(data['result'], 'some_data');
    });

    testWithoutContext('sending response without data', () async {
      daemonConnection.sendResponse('1');
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;
      expect(data['id'], '1');
      expect(data['method'], isNull);
      expect(data['error'], isNull);
      expect(data['result'], isNull);
    });

    testWithoutContext('sending error response', () async {
      daemonConnection.sendErrorResponse('1', 'error', StackTrace.fromString('stack trace'));
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;
      expect(data['id'], '1');
      expect(data['method'], isNull);
      expect(data['error'], 'error');
      expect(data['trace'], 'stack trace');
    });

    testWithoutContext('sending events', () async {
      daemonConnection.sendEvent('some_event', '123');
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;
      expect(data['id'], isNull);
      expect(data['event'], 'some_event');
      expect(data['params'], '123');
    });

    testWithoutContext('sending events without params', () async {
      daemonConnection.sendEvent('some_event');
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;
      expect(data['id'], isNull);
      expect(data['event'], 'some_event');
      expect(data['params'], isNull);
    });
  });

  group('DaemonConnection request and response', () {
    testWithoutContext('receiving response from requests', () async {
      final Future<dynamic> requestFuture = daemonConnection.sendRequest('some_method', 'param');
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;

      expect(data['id'], isNotNull);
      expect(data['method'], 'some_method');
      expect(data['params'], 'param');

      final String id = data['id'] as String;
      daemonStreams.inputs.add(<String, dynamic>{'id': id, 'result': '123'});
      expect(await requestFuture, '123');
    });

    testWithoutContext('receiving response from requests without result', () async {
      final Future<dynamic> requestFuture = daemonConnection.sendRequest('some_method', 'param');
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;

      expect(data['id'], isNotNull);
      expect(data['method'], 'some_method');
      expect(data['params'], 'param');

      final String id = data['id'] as String;
      daemonStreams.inputs.add(<String, dynamic>{'id': id});
      expect(await requestFuture, null);
    });

    testWithoutContext('receiving error response from requests without result', () async {
      final Future<dynamic> requestFuture = daemonConnection.sendRequest('some_method', 'param');
      final Map<String, dynamic> data = await daemonStreams.outputs.stream.first;

      expect(data['id'], isNotNull);
      expect(data['method'], 'some_method');
      expect(data['params'], 'param');

      final String id = data['id'] as String;
      daemonStreams.inputs.add(<String, dynamic>{'id': id, 'error': 'some_error', 'trace': 'stack trace'});
      expect(requestFuture, throwsA('some_error'));
    });
  });

  group('TcpDaemonStreams', () {
    final Map<String, Object?> testCommand = <String, Object?>{
      'id': 100,
      'method': 'test',
    };
    late FakeSocket socket;
    late TcpDaemonStreams daemonStreams;
    setUp(() {
      socket = FakeSocket();
      daemonStreams = TcpDaemonStreams(socket, logger: bufferLogger);
    });

    test('parses the message received on the socket', () async {
      socket.controller.add(Uint8List.fromList(utf8.encode('[${jsonEncode(testCommand)}]\n')));
      final Map<String, Object?> command = await daemonStreams.inputStream.first;
      expect(command, testCommand);
    });

    test('sends the encoded message through the socket', () async {
      daemonStreams.send(testCommand);
      await pumpEventQueue();
      expect(socket.writtenObjects.length, 1);
      expect(socket.writtenObjects[0].toString(), '[${jsonEncode(testCommand)}]\n');
    });

    test('dispose calls socket.close', () async {
      await daemonStreams.dispose();
      expect(socket.closeCalled, isTrue);
    });
  });
}

class FakeSocket extends Fake implements Socket {
  bool closeCalled = false;
  final StreamController<Uint8List> controller = StreamController<Uint8List>();
  final List<Object?> writtenObjects = <Object?>[];

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  void write(Object? object) {
    writtenObjects.add(object);
  }

  @override
  Future<void> close() async {
    closeCalled = true;
  }
}
