// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show BASE64;
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:web_socket_channel/io.dart';

import 'globals.dart';

// TODO(johnmccutchan): Rename this class to ServiceProtocol or VmService.
class Observatory {
  Observatory._(this.peer, this.port, this.httpAddress) {
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
    Uri httpAddress = new Uri(scheme: 'http', host: '127.0.0.1', port: port);
    return new Observatory._(peer, port, httpAddress);
  }
  final Uri httpAddress;
  final rpc.Peer peer;
  final int port;

  List<IsolateRef> isolates = <IsolateRef>[];
  Completer<IsolateRef> _waitFirstIsolateCompleter;

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

  Future<Null> populateIsolateInfo() async {
    // Calling this has the side effect of populating the isolate information.
    await waitFirstIsolate;
  }

  Future<IsolateRef> get waitFirstIsolate async {
    if (isolates.isNotEmpty)
      return isolates.first;

    _waitFirstIsolateCompleter ??= new Completer<IsolateRef>();

    getVM().then((VM vm) {
      for (IsolateRef isolate in vm.isolates)
        _addIsolate(isolate);
    });

    return _waitFirstIsolateCompleter.future;
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

  Future<Map<String, dynamic>> reloadSources(String isolateId) async {
    try {
      Response response =
          await sendRequest('_reloadSources',
                            <String, dynamic>{ 'isolateId': isolateId });
      return response.response;
    } catch (e) {
      return new Future<Map<String, dynamic>>.error(e.data['details']);
    }
  }

  Future<String> getFirstViewId() async {
    Map<String, dynamic> response = await peer.sendRequest('_flutter.listViews');
    List<Map<String, String>> views = response['views'];
    return views[0]['id'];
  }

  Future<Null> runInView(String viewId,
                         String main,
                         String packages,
                         String assetsDirectory) async {
    await peer.sendRequest('_flutter.runInView',
                           <String, dynamic> {
                             'viewId': viewId,
                             'mainScript': main,
                             'packagesFile': packages,
                             'assetDirectory': assetsDirectory
                           });
    return null;
  }

  Future<Response> clearVMTimeline() => sendRequest('_clearVMTimeline');

  Future<Response> setVMTimelineFlags(List<String> recordedStreams) {
    assert(recordedStreams != null);

    return sendRequest('_setVMTimelineFlags', <String, dynamic> {
      'recordedStreams': recordedStreams
    });
  }

  Future<Response> getVMTimeline() => sendRequest('_getVMTimeline');

  // DevFS / VM virtual file system methods

  /// Create a new file system.
  Future<CreateDevFSResponse> createDevFS(String fsName) async {
    Response response = await sendRequest('_createDevFS', <String, dynamic> { 'fsName': fsName });
    return new CreateDevFSResponse(response.response);
  }

  /// List the available file systems.
  Future<List<String>> listDevFS() {
    return sendRequest('_listDevFS').then((Response response) {
      return response.response['fsNames'];
    });
  }

  // Write one file into a file system.
  Future<Response> writeDevFSFile(String fsName, {
    String path,
    List<int> fileContents
  }) {
    assert(path != null);
    assert(fileContents != null);

    return sendRequest('_writeDevFSFile', <String, dynamic> {
      'fsName': fsName,
      'path': path,
      'fileContents': BASE64.encode(fileContents)
    });
  }

  // Read one file from a file system.
  Future<List<int>> readDevFSFile(String fsName, String path) {
    return sendRequest('_readDevFSFile', <String, dynamic> {
      'fsName': fsName,
      'path': path
    }).then((Response response) {
      return BASE64.decode(response.response['fileContents']);
    });
  }

  /// The complete list of a file system.
  Future<List<String>> listDevFSFiles(String fsName) {
    return sendRequest('_listDevFSFiles', <String, dynamic> {
      'fsName': fsName
    }).then((Response response) {
      return response.response['files'];
    });
  }

  /// Delete an existing file system.
  Future<Response> deleteDevFS(String fsName) {
    return sendRequest('_deleteDevFS', <String, dynamic> { 'fsName': fsName });
  }

  // Flutter extension methods.

  Future<Response> flutterDebugDumpApp(String isolateId) {
    return peer.sendRequest('ext.flutter.debugDumpApp', <String, dynamic>{
      'isolateId': isolateId
    }).then((dynamic result) => new Response(result));
  }

  Future<Response> flutterDebugDumpRenderTree(String isolateId) {
    return peer.sendRequest('ext.flutter.debugDumpRenderTree', <String, dynamic>{
      'isolateId': isolateId
    }).then((dynamic result) => new Response(result));
  }

  // Loader page extension methods.

  Future<Response> flutterLoaderShowMessage(String isolateId, String message) {
    return peer.sendRequest('ext.flutter.loaderShowMessage', <String, dynamic>{
      'isolateId': isolateId,
      'value': message
    }).then(
      (dynamic result) => new Response(result),
      onError: (dynamic exception) { printTrace('ext.flutter.loaderShowMessage: $exception'); }
    );
  }

  Future<Response> flutterLoaderSetProgress(String isolateId, double progress) {
    return peer.sendRequest('ext.flutter.loaderSetProgress', <String, dynamic>{
      'isolateId': isolateId,
      'loaderSetProgress': progress
    }).then(
      (dynamic result) => new Response(result),
      onError: (dynamic exception) { printTrace('ext.flutter.loaderSetProgress: $exception'); }
    );
  }

  Future<Response> flutterLoaderSetProgressMax(String isolateId, double max) {
    return peer.sendRequest('ext.flutter.loaderSetProgressMax', <String, dynamic>{
      'isolateId': isolateId,
      'loaderSetProgressMax': max
    }).then(
      (dynamic result) => new Response(result),
      onError: (dynamic exception) { printTrace('ext.flutter.loaderSetProgressMax: $exception'); }
    );
  }

  /// Causes the application to pick up any changed code.
  Future<Response> flutterReassemble(String isolateId) {
    return peer.sendRequest('ext.flutter.reassemble', <String, dynamic>{
      'isolateId': isolateId
    }).then((dynamic result) => new Response(result));
  }

  Future<Response> flutterEvictAsset(String isolateId, String assetPath) {
    return peer.sendRequest('ext.flutter.evict', <String, dynamic>{
      'isolateId': isolateId,
      'value': assetPath
    }).then((dynamic result) => new Response(result));
  }

  Future<Response> flutterExit(String isolateId) {
    return peer
      .sendRequest('ext.flutter.exit', <String, dynamic>{ 'isolateId': isolateId })
      .then((dynamic result) => new Response(result))
      .timeout(new Duration(seconds: 2), onTimeout: () => null);
  }

  void _addIsolate(IsolateRef isolate) {
    if (!isolates.contains(isolate)) {
      isolates.add(isolate);

      if (_waitFirstIsolateCompleter != null) {
        _waitFirstIsolateCompleter.complete(isolate);
        _waitFirstIsolateCompleter = null;
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

class CreateDevFSResponse extends Response {
  CreateDevFSResponse(Map<String, dynamic> response) : super(response);

  String get name => response['name'];
  String get uri => response['uri'];
}

class VM extends Response {
  VM(Map<String, dynamic> response) : super(response);

  List<IsolateRef> get isolates => response['isolates'].map((dynamic ref) => new IsolateRef(ref)).toList();
}

class Event extends Response {
  Event(Map<String, dynamic> response) : super(response);

  String get kind => response['kind'];
  IsolateRef get isolate => new IsolateRef.from(response['isolate']);

  /// Only valid for [kind] == `Extension`.
  String get extensionKind => response['extensionKind'];
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
