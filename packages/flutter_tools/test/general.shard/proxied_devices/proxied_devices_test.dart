// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/daemon.dart';
import 'package:flutter_tools/src/proxied_devices/devices.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group('ProxiedPortForwarder', () {
    late BufferLogger bufferLogger;
    late DaemonConnection serverDaemonConnection;
    late DaemonConnection clientDaemonConnection;
    setUp(() {
      bufferLogger = BufferLogger.test();
      final FakeDaemonStreams serverDaemonStreams = FakeDaemonStreams();
      serverDaemonConnection = DaemonConnection(
        daemonStreams: serverDaemonStreams,
        logger: bufferLogger,
      );
      final FakeDaemonStreams clientDaemonStreams = FakeDaemonStreams();
      clientDaemonConnection = DaemonConnection(
        daemonStreams: clientDaemonStreams,
        logger: bufferLogger,
      );

      serverDaemonStreams.inputs.addStream(clientDaemonStreams.outputs.stream);
      clientDaemonStreams.inputs.addStream(serverDaemonStreams.outputs.stream);
    });

    tearDown(() async {
      await serverDaemonConnection.dispose();
      await clientDaemonConnection.dispose();
    });

    testWithoutContext('works correctly without device id', () async {
      final FakeServerSocket fakeServerSocket = FakeServerSocket(200);
      final ProxiedPortForwarder portForwarder = ProxiedPortForwarder(
        clientDaemonConnection,
        logger: bufferLogger,
        createSocketServer: (Logger logger, int? hostPort) async =>
            fakeServerSocket,
      );
      final int result = await portForwarder.forward(100);
      expect(result, 200);

      final FakeSocket fakeSocket = FakeSocket();
      fakeServerSocket.controller.add(fakeSocket);

      final Stream<DaemonMessage> broadcastOutput = serverDaemonConnection.incomingCommands.asBroadcastStream();

      DaemonMessage message = await broadcastOutput.first;

      expect(message.data['id'], isNotNull);
      expect(message.data['method'], 'proxy.connect');
      expect(message.data['params'], <String, Object?>{'port': 100});

      const String id = 'random_id';
      serverDaemonConnection.sendResponse(message.data['id']!, id);

      // Forwards the data received from socket to daemon.
      fakeSocket.controller.add(Uint8List.fromList(<int>[1, 2, 3]));
      message = await broadcastOutput.first;
      expect(message.data['method'], 'proxy.write');
      expect(message.data['params'], <String, Object?>{'id': id});
      expect(message.binary, isNotNull);
      final List<List<int>> binary = await message.binary!.toList();
      expect(binary, <List<int>>[<int>[1, 2, 3]]);

      // Forwards data received as event to socket.
      expect(fakeSocket.addedData.isEmpty, true);
      serverDaemonConnection.sendEvent('proxy.data.$id', null, <int>[4, 5, 6]);
      await pumpEventQueue();
      expect(fakeSocket.addedData.isNotEmpty, true);
      expect(fakeSocket.addedData[0], <int>[4, 5, 6]);

      // Closes the socket after the remote end disconnects
      expect(fakeSocket.closeCalled, false);
      serverDaemonConnection.sendEvent('proxy.disconnected.$id');
      await pumpEventQueue();
      expect(fakeSocket.closeCalled, true);
    });

    testWithoutContext('forwards the port from the remote end with device id', () async {
      final FakeServerSocket fakeServerSocket = FakeServerSocket(400);
      final ProxiedPortForwarder portForwarder = ProxiedPortForwarder(
        clientDaemonConnection,
        deviceId: 'device_id',
        logger: bufferLogger,
        createSocketServer: (Logger logger, int? hostPort) async =>
            fakeServerSocket,
      );

      final Stream<DaemonMessage> broadcastOutput = serverDaemonConnection.incomingCommands.asBroadcastStream();

      final Future<int> result = portForwarder.forward(300);

      DaemonMessage message = await broadcastOutput.first;
      expect(message.data['id'], isNotNull);
      expect(message.data['method'], 'device.forward');
      expect(message.data['params'], <String, Object?>{'deviceId': 'device_id', 'devicePort': 300});

      serverDaemonConnection.sendResponse(message.data['id']!, <String, Object?>{'hostPort': 350});

      expect(await result, 400);

      final FakeSocket fakeSocket = FakeSocket();
      fakeServerSocket.controller.add(fakeSocket);
      message = await broadcastOutput.first;

      expect(message.data['id'], isNotNull);
      expect(message.data['method'], 'proxy.connect');
      expect(message.data['params'], <String, Object?>{'port': 350});

      const String id = 'random_id';
      serverDaemonConnection.sendResponse(message.data['id']!, id);

      // Unforward will try to disconnect the remote port.
      portForwarder.forwardedPorts.single.dispose();
      expect(fakeServerSocket.closeCalled, true);

      message = await broadcastOutput.first;

      expect(message.data['id'], isNotNull);
      expect(message.data['method'], 'device.unforward');
      expect(message.data['params'], <String, Object?>{
        'deviceId': 'device_id',
        'devicePort': 300,
        'hostPort': 350,
      });
    });
  });
}

class FakeDaemonStreams implements DaemonStreams {
  final StreamController<DaemonMessage> inputs = StreamController<DaemonMessage>();
  final StreamController<DaemonMessage> outputs = StreamController<DaemonMessage>();

  @override
  Stream<DaemonMessage> get inputStream {
    return inputs.stream;
  }

  @override
  void send(Map<String, dynamic> message, [List<int>? binary]) {
    outputs.add(DaemonMessage(message, binary != null ? Stream<List<int>>.value(binary) : null));
  }

  @override
  Future<void> dispose() async {
    await inputs.close();
    // In some tests, outputs have no listeners. We don't wait for outputs to close.
    unawaited(outputs.close());
  }
}

class FakeServerSocket extends Fake implements ServerSocket {
  FakeServerSocket(this.port);

  @override
  final int port;

  bool closeCalled = false;
  final StreamController<Socket> controller = StreamController<Socket>();

  @override
  StreamSubscription<Socket> listen(
    void Function(Socket event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Future<ServerSocket> close() async {
    closeCalled = true;
    return this;
  }
}

class FakeSocket extends Fake implements Socket {
  bool closeCalled = false;
  final StreamController<Uint8List> controller = StreamController<Uint8List>();
  final List<List<int>> addedData = <List<int>>[];
  final Completer<bool> doneCompleter = Completer<bool>();

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  void add(List<int> data) {
    addedData.add(data);
  }

  @override
  Future<void> close() async {
    closeCalled = true;
  }

  @override
  Future<bool> get done => doneCompleter.future;

  @override
  void destroy() {}
}
