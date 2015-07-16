// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of sky_shell_dart_controller_service_isolate;

class WebSocketClient extends Client {
  static const int PARSE_ERROR_CODE = 4000;
  static const int BINARY_MESSAGE_ERROR_CODE = 4001;
  static const int NOT_MAP_ERROR_CODE = 4002;
  final WebSocket socket;

  WebSocketClient(this.socket, VMService service) : super(service) {
    socket.listen((message) => onWebSocketMessage(message));
    socket.done.then((_) => close());
  }

  onWebSocketMessage(message) {
    if (message is String) {
      var map;
      try {
        map = JSON.decode(message);
      } catch (e) {
        socket.close(PARSE_ERROR_CODE, 'Message parse error: $e');
        return;
      }
      if (map is! Map) {
        socket.close(NOT_MAP_ERROR_CODE, 'Message must be a JSON map.');
        return;
      }
      var serial = map['id'];
      onMessage(serial, new Message.fromJsonRpc(this, map));
    } else {
      socket.close(BINARY_MESSAGE_ERROR_CODE, 'Message must be a string.');
    }
  }

  post(dynamic result) {
    try {
      socket.add(result);
    } catch (_) {
      print("Ignoring error posting over WebSocket.");
    }
  }

  dynamic toJson() {
    Map map = super.toJson();
    map['type'] = 'WebSocketClient';
    map['socket'] = '$socket';
    return map;
  }
}


class HttpRequestClient extends Client {
  static ContentType jsonContentType =
      new ContentType("application", "json", charset: "utf-8");
  final HttpRequest request;

  HttpRequestClient(this.request, VMService service) : super(service);

  post(String result) {
    request.response..headers.contentType = jsonContentType
                    ..write(result)
                    ..close();
    close();
  }

  dynamic toJson() {
    Map map = super.toJson();
    map['type'] = 'HttpRequestClient';
    map['request'] = '$request';
    return map;
  }
}

class Server {
  static const WEBSOCKET_PATH = '/ws';
  static const ROOT_REDIRECT_PATH = '/index.html';

  final VMService _service;
  final String _ip;
  final int _port;

  HttpServer _server;
  bool get running => _server != null;
  bool _displayMessages = false;

  Server(this._service, this._ip, this._port) {
    _displayMessages = (_ip != '127.0.0.1' || _port != 8181);
  }

  bool _shouldServeObservatory(HttpRequest request) {
    if (request.headers['Observatory-Version'] != null) {
      // Request is already coming from Observatory.
      return false;
    }
    // TODO(johnmccutchan): Test with obscure browsers.
    if (request.headers.value(HttpHeaders.USER_AGENT).contains('Mozilla')) {
      // Request is coming from a browser but not Observatory application.
      // Serve Observatory and let the Observatory make the real request.
      return true;
    }
    // All other user agents are assumed to be textual.
    return false;
  }

  _onServerShutdown() {
  }

  _serverError(error, stackTrace) {
    _onServerShutdown();
  }

  _serverDone() {
    _onServerShutdown();
  }

  _requestHandler(HttpRequest request) {
    // Allow cross origin requests with 'observatory' header.
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Headers',
                                 'Observatory-Version');

    if (request.method != 'GET') {
      // Not a GET request. Do nothing.
      request.response.close();
      return;
    }

    final String path =
          request.uri.path == '/' ? ROOT_REDIRECT_PATH : request.uri.path;

    if (path == WEBSOCKET_PATH) {
      WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
        new WebSocketClient(webSocket, _service);
      });
      return;
    }

    var resource = Resource.resources[path];
    if (resource == null && _shouldServeObservatory(request)) {
      resource = Resource.resources[ROOT_REDIRECT_PATH];
      assert(resource != null);
    }
    if (resource != null) {
      // Serving up a static resource (e.g. .css, .html, .png).
      request.response.headers.contentType =
          ContentType.parse(resource.mimeType);
      request.response.add(resource.data);
      request.response.close();
      return;
    }
    var client = new HttpRequestClient(request, _service);
    var message = new Message.fromUri(client, request.uri);
    client.onMessage(null, message);
  }

  Future startup() {
    if (_server != null) {
      // Already running.
      return new Future.value(this);
    }

    // Startup HTTP server.
    var address = new InternetAddress('127.0.0.1');
    return HttpServer.bind(address, _port).then((s) {
      _server = s;
      _server.listen(_requestHandler,
                     onError: _serverError,
                     onDone: _serverDone,
                     cancelOnError: true);
      var ip = _server.address.address.toString();
      if (_displayMessages) {
        var port = _server.port.toString();
        print('Observatory listening on http://$ip:$port');
      }
      // Server is up and running.
      _notifyServerState(ip, _server.port);
      return this;
    }).catchError((e, st) {
      print('Could not start Observatory HTTP server:\n$e\n$st\n');
      _notifyServerState("", 0);
      return this;
    });
  }

  close(bool force) {
    if (_server == null) {
      return new Future.value(null);
    }
    return _server.close(force: force);
  }

  Future shutdown(bool forced) {
    if (_server == null) {
      // Not started.
      return new Future.value(this);
    }

    // Force displaying of status messages if we are forcibly shutdown.
    _displayMessages = _displayMessages || forced;

    // Shutdown HTTP server and subscription.
    var ip = _server.address.address.toString();
    var port = _server.port.toString();
    return close(forced).then((_) {
      if (_displayMessages) {
        print('Observatory no longer listening on http://$ip:$port');
      }
      _server = null;
      _notifyServerState("", 0);
      return this;
    }).catchError((e, st) {
      _server = null;
      print('Could not shutdown Observatory HTTP server:\n$e\n$st\n');
      _notifyServerState("", 0);
      return this;
    });
  }

}

_notifyServerState(String ip, int port)
    native "ServiceIsolate_NotifyServerState";
