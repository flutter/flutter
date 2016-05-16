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

    onIsolateEvent.listen((Event event) {
      if (event.kind == 'IsolateStart') {
        _addIsolate(event.isolate);
      } else if (event.kind == 'IsolateExit') {
        String removedId = event.isolate.id;
        isolates.removeWhere((IsolateRef ref) => ref.id == removedId);
      }
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

  List<IsolateRef> isolates = <IsolateRef>[];
  Completer<IsolateRef> _hasIsolateCompleter;

  Map<String, StreamController<Event>> _eventControllers = <String, StreamController<Event>>{};

  Set<String> _listeningFor = new Set<String>();

  bool get isClosed => peer.isClosed;
  Future<Null> get done => peer.done;

  String get firstIsolateId => isolates.isEmpty ? null : isolates.first.id;

  // Events

  Stream<Event> get onExtensionEvent => onEvent('Extension');
  // IsolateStart, IsolateRunnable, IsolateExit, IsolateUpdate, ServiceExtensionAdded
  Stream<Event> get onIsolateEvent => onEvent('Isolate');
  Stream<Event> get onTimelineEvent => onEvent('Timeline');

  // Listen for a specific event name.
  Stream<Event> onEvent(String streamId) {
    streamListen(streamId);
    return _getEventController(streamId).stream;
  }

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

  Future<IsolateRef> waitHasIsolate() {
    if (isolates.isNotEmpty) {
      return new Future<IsolateRef>.value(isolates.first);
    } else {
      _hasIsolateCompleter = new Completer<IsolateRef>();

      return getVM().then((VM vm) {
        for (IsolateRef isolate in vm.isolates)
          _addIsolate(isolate);
      });
    }
  }

  // Requests

  Future<Response> sendRequest(String method, [Map<String, dynamic> args]) {
    return peer.sendRequest(method, args).then((dynamic result) => new Response(result));
  }

  Future<Null> streamListen(String streamId) async {
    if (!_listeningFor.contains(streamId)) {
      _listeningFor.add(streamId);
      sendRequest('streamListen', <String, dynamic>{ 'streamId': streamId });
    }
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

  void _addIsolate(IsolateRef isolate) {
    if (!isolates.contains(isolate)) {
      isolates.add(isolate);

      if (_hasIsolateCompleter != null) {
        _hasIsolateCompleter.complete(isolate);
        _hasIsolateCompleter = null;
      }
    }
  }
}

class Response {
  Response(this.response);

  final Map<String, dynamic> response;

  String get type => response['type'];

  dynamic operator[](String key) => response[key];

  @override
  String toString() => response.toString();
}

class VM extends Response {
  VM(Map<String, dynamic> response) : super(response);

  List<IsolateRef> get isolates => response['isolates'].map((dynamic ref) => new IsolateRef(ref)).toList();
}

class Event extends Response {
  Event(Map<String, dynamic> response) : super(response);

  String get kind => response['kind'];
  IsolateRef get isolate => new IsolateRef.from(response['isolate']);
}

class IsolateRef extends Response {
  IsolateRef(Map<String, dynamic> response) : super(response);
  factory IsolateRef.from(dynamic ref) => ref == null ? null : new IsolateRef(ref);

  String get id => response['id'];

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! IsolateRef)
      return false;
    final IsolateRef typedOther = other;
    return id == typedOther.id;
  }

  @override
  int get hashCode => id.hashCode;
}
