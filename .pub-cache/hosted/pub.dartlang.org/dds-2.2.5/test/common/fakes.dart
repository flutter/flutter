// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// [FakePeer] implements the bare minimum of the [Peer] interface needed for
/// [DartDevelopmentService] to establish a connection with a VM service.
///
/// `sendRequest` can be overridden to provide custom handling for VM service
/// RPCs and custom RPCs to control the state of the [FakePeer] instance from a
/// VM service client request routed through a [DartDevelopmentService] instance.
class FakePeer extends Fake implements json_rpc.Peer {
  @override
  Future<void> get done => doneCompleter.future;
  final Completer<void> doneCompleter = Completer<void>();

  bool get isClosed => doneCompleter.isCompleted;

  @override
  Future<void> listen() {
    return done;
  }

  @override
  void registerMethod(String name, Function callback) {}

  @override
  Future<dynamic> sendRequest(String method, [args]) async {
    switch (method) {
      case 'getVM':
        return _buildResponse(VM(
          name: 'Test',
          architectureBits: 0,
          hostCPU: '',
          operatingSystem: '',
          targetCPU: '',
          version: '',
          pid: 0,
          startTime: 0,
          isolates: [],
          isolateGroups: [],
          systemIsolateGroups: [],
          systemIsolates: [],
        ));
      default:
        return _buildResponse(Success());
    }
  }

  Map<String, dynamic> _buildResponse(dynamic serviceObject) {
    return {
      'json_rpc': '2.0',
      'id': _idCount++,
      ...serviceObject.toJson(),
    };
  }

  int _idCount = 0;
}

class FakeWebSocketSink extends Fake implements WebSocketSink {
  @override
  Future close([int? closeCode, String? closeReason]) {
    // Do nothing.
    return Future.value();
  }
}

/// [FakeWebSocketChannel] implements the bare minimum of the [WebSocket]
/// interface required to finish DDS initialization.
class FakeWebSocketChannel extends Fake implements WebSocketChannel {
  @override
  WebSocketSink get sink => FakeWebSocketSink();
}
