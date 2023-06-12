// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A multiplexing [RawReceivePort].
///
/// Allows creating a number of [RawReceivePort] implementations that all send
/// messages through the same real `RawReceivePort`.
///
/// This allows reducing the number of receive ports created, but adds an
/// overhead to each message.
/// If a library creates many short-lived receive ports, multiplexing might be
/// faster.
///
/// To use multiplexing receive ports, create and store a
/// [RawReceivePortMultiplexer], and create receive ports by calling
/// `multiplexer.createRawReceivePort(handler)` where you would otherwise
/// write `new RawReceivePort(handler)`.
///
/// Remember to [close] the multiplexer when it is no longer needed.
///
/// (TODO: Check if it really is faster - creating a receive port requires a
/// global mutex, so it may be a bottleneck, but it's not clear how slow it is).
library isolate.raw_receive_port_multiplexer;

import 'dart:collection';
import 'dart:isolate';

import 'util.dart';

class _MultiplexRawReceivePort implements RawReceivePort {
  final RawReceivePortMultiplexer _multiplexer;
  final int _id;
  Function? _handler;

  _MultiplexRawReceivePort(this._multiplexer, this._id, this._handler);

  @override
  set handler(Function? handler) {
    _handler = handler;
  }

  @override
  void close() {
    _multiplexer._closePort(_id);
  }

  @override
  SendPort get sendPort => _multiplexer._createSendPort(_id);

  void _invokeHandler(message) {
    _handler?.call(message);
  }
}

class _MultiplexSendPort implements SendPort {
  final SendPort _sendPort;
  final int _id;

  _MultiplexSendPort(this._id, this._sendPort);

  @override
  void send(message) {
    _sendPort.send(list2(_id, message));
  }
}

/// A shared [RawReceivePort] that distributes messages to
/// [RawReceivePort] instances that it manages.
class RawReceivePortMultiplexer {
  final RawReceivePort _port = RawReceivePort();
  final Map<int, _MultiplexRawReceivePort> _map = HashMap();
  int _nextId = 0;

  RawReceivePortMultiplexer() {
    _port.handler = _multiplexResponse;
  }

  RawReceivePort createRawReceivePort([void Function(dynamic)? handler]) {
    var id = _nextId++;
    var result = _MultiplexRawReceivePort(this, id, handler);
    _map[id] = result;
    return result;
  }

  void close() {
    _port.close();
  }

  void _multiplexResponse(list) {
    var id = list[0];
    var message = list[1];
    var receivePort = _map[id];
    // If the receive port is closed, messages are dropped, just as for
    // the normal ReceivePort.
    if (receivePort == null) return; // Port closed.
    receivePort._invokeHandler(message);
  }

  SendPort _createSendPort(int id) {
    return _MultiplexSendPort(id, _port.sendPort);
  }

  void _closePort(int id) {
    _map.remove(id);
  }
}
