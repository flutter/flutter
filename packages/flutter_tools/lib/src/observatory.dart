// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:web_socket_channel/io.dart';

class Observatory {
  Observatory._(this.peer, this.port) {
    peer.registerMethod('streamNotify', (rpc.Parameters event) {
      _handleStreamNotify(event.asMap);
    });
  }

  static Future<Observatory> connect(int port) async {
    Uri uri = new Uri(scheme: 'ws', host: '127.0.0.1', port: port, path: 'ws');
    WebSocket ws = await WebSocket.connect(uri.toString());
    rpc.Peer peer = new rpc.Peer(new IOWebSocketChannel(ws));
    peer.listen();
    return new Observatory._(peer, port);
  }

  final rpc.Peer peer;
  final int port;

  Map<String, StreamController<Event>> _eventControllers = <String, StreamController<Event>>{};

  bool get isClosed => peer.isClosed;
  Future<Null> get done => peer.done;

  // Events

  // IsolateStart, IsolateRunnable, IsolateExit, IsolateUpdate, ServiceExtensionAdded
  Stream<Event> get onIsolateEvent => _getEventController('Isolate').stream;
  Stream<Event> get onTimelineEvent => _getEventController('Timeline').stream;

  // Listen for a specific event name.
  Stream<Event> onEvent(String streamName) => _getEventController(streamName).stream;

  StreamController<Event> _getEventController(String eventName) {
    StreamController<Event> controller = _eventControllers[eventName];
    if (controller == null) {
      controller = new StreamController<Event>.broadcast();
      _eventControllers[eventName] = controller;
    }
    return controller;
  }

  void _handleStreamNotify(Map<String, dynamic> data) {
    Event event = new Event(data['event']);
    _getEventController(data['streamId']).add(event);
  }

  // Requests

  Future<Response> sendRequest(String method, [Map<String, dynamic> args]) {
    return peer.sendRequest(method, args).then((dynamic result) => new Response(result));
  }

  Future<Response> streamListen(String streamId) {
    return sendRequest('streamListen', <String, dynamic>{
      'streamId': streamId
    });
  }

  Future<VM> getVM() {
    return peer.sendRequest('getVM').then((dynamic result) {
      return new VM(result);
    });
  }

  Future<Response> isolateReload(String isolateId) {
    return sendRequest('isolateReload', <String, dynamic>{
      'isolateId': isolateId
    });
  }

  Future<Response> clearVMTimeline() => sendRequest('_clearVMTimeline');

  Future<Response> setVMTimelineFlags(List<String> recordedStreams) {
    assert(recordedStreams != null);

    return sendRequest('_setVMTimelineFlags', <String, dynamic> {
      'recordedStreams': recordedStreams
    });
  }

  Future<Response> getVMTimeline() => sendRequest('_getVMTimeline');

  // Flutter extension methods.

  Future<Response> flutterExit(String isolateId) {
    return peer.sendRequest('ext.flutter.exit', <String, dynamic>{
      'isolateId': isolateId
    }).then((dynamic result) => new Response(result));
  }
}

class Response {
  Response(this.response);

  final Map<String, dynamic> response;

  dynamic operator[](String key) => response[key];

  @override
  String toString() => response.toString();
}

class VM extends Response {
  VM(Map<String, dynamic> response) : super(response);

  List<dynamic> get isolates => response['isolates'];
}

class Event {
  Event(this.event);

  final Map<String, dynamic> event;

  String get kind => event['kind'];

  dynamic operator[](String key) => event[key];

  @override
  String toString() => event.toString();
}
