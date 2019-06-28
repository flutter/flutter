// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tool_api/extension.dart';

import '../base/context.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';
import 'file_system.dart';

ToolExtensionManager get toolExtensionManager => context.get<ToolExtensionManager>();

/// A cached manifest of all installed tool extensions and their status.
class ToolExtensionManager {
  ToolExtensionManager(List<String> extensions) {
    for (String extension in extensions) {
      _crossIsolateShims.add(CrossIsolateShim(extension));
    }
  }

  final List<CrossIsolateShim> _crossIsolateShims = <CrossIsolateShim>[];

  int _nextId = 0;

  /// Send a request to every active extension.
  Future<List<Response>> sendRequestAll(String method,
      {Map<String, Object> arguments = const <String, Object>{}}) async {
    final int id = _nextId;
    _nextId += 1;
    final Request request = Request(id, method, arguments);
    final List<Future<Response>> pendingResponses = <Future<Response>>[];
    for (CrossIsolateShim shim in _crossIsolateShims) {
      pendingResponses.add(shim.handleMessage(request));
    }
    return Future.wait(pendingResponses);
  }

  /// Send a request to a single named extension.
  Future<Response> sendRequest(String extensionName, String method,
      {Map<String, Object> arguments = const <String, Object>{}}) async {
    final int id = _nextId;
    _nextId += 1;
    final Request request = Request(id, method, arguments);
    final CrossIsolateShim shim = _crossIsolateShims
        .firstWhere((CrossIsolateShim shim) => shim.extensionName == extensionName,
        orElse: () => null);
    if (shim == null) {
      return Response(_nextId, <String, Object>{},
          <String, Object>{'error': 'No extension named $extensionName'});
    }
    return shim.handleMessage(request);
  }
}

/// Launch and connect to a cross isolate tool extension.
class CrossIsolateShim {
  CrossIsolateShim(this.extensionName) {
  final ReceivePort receivePort = ReceivePort();
  final String path = Cache.instance.getArtifactDirectory('tool_extensions')
      .childFile('$extensionName.dill').path;
  Isolate.spawnUri(fs.path.toUri(path), <String>[], receivePort.sendPort)
      .then((Isolate isolate) {
        print("SPAWN ISOLATE");
        _receivePort = receivePort;
        _receivePort.listen((dynamic data) {
          print("GOT PORT");
          if (data is SendPort) {
            _sendPort = data;
            _doneLoading.complete();
          } else if (data is String) {
            final Response response = Response.fromJson(json.decode(data));
            if (_pending[response.id] != null) {
              _pending[response.id].complete(response);
            }
          }
        });
      }, onError: (dynamic error) {
         printError('$error');
         _doneLoading.completeError(error);
      });
  }

  final String extensionName;
  final Completer<void> _doneLoading = Completer<void>();
  final Map<int, Completer<Response>> _pending = <int, Completer<Response>>{};
  ReceivePort _receivePort;
  SendPort _sendPort;

  Future<Response> handleMessage(Request request) async {
    try {
      await _doneLoading.future;
    } catch (err) {
      return Response(request.id, <String, Object>{},
        <String, Object>{'error': '$extensionName failed to start'});
    }
    _pending[request.id] = Completer<Response>();
    _sendPort.send(json.encode(request.toJson()));
    return _pending[request.id].future;
  }
}
