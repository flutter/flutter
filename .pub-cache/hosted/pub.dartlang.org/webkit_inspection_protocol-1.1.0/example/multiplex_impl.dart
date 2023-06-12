// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library wip.multiplex_impl;

import 'dart:async' show Future;
import 'dart:convert' show jsonEncode;
import 'dart:io' show HttpServer, InternetAddress;

import 'package:logging/logging.dart' show Logger;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart' as ws;
import 'package:web_socket_channel/web_socket_channel.dart'
    show WebSocketChannel;
import 'package:webkit_inspection_protocol/dom_model.dart' show WipDomModel;
import 'package:webkit_inspection_protocol/forwarder.dart' show WipForwarder;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    show ChromeConnection, ChromeTab, WipConnection;

class Server {
  static final _log = Logger('Server');

  Future<HttpServer>? _server;
  final ChromeConnection chrome;
  final int port;
  final bool modelDom;

  final _connections = <String, Future<WipConnection>>{};
  final _modelDoms = <String, WipDomModel>{};

  Server(this.port, this.chrome, {this.modelDom = false}) {
    _server = io.serve(_handler, InternetAddress.anyIPv4, port);
  }

  shelf.Handler get _handler => const shelf.Pipeline()
      .addMiddleware(shelf.logRequests(logger: _shelfLogger))
      .addHandler(shelf.Cascade()
          .add(_webSocket)
          .add(_mainPage)
          .add(_json)
          .add(_forward)
          .handler);

  void _shelfLogger(String msg, bool isError) {
    if (isError) {
      _log.severe(msg);
    } else {
      _log.info(msg);
    }
  }

  Future<shelf.Response> _mainPage(shelf.Request request) async {
    var path = request.url.pathSegments;
    if (path.isEmpty) {
      var resp = await _mainPageHtml();
      _log.info('mainPage: $resp');
      return shelf.Response.ok(resp, headers: {'Content-Type': 'text/html'});
    }
    return shelf.Response.notFound(null);
  }

  Future<String> _mainPageHtml() async {
    var html = StringBuffer(r'''<!DOCTYPE html>
<html>
<head>
<title>Chrome Windows</title>
</head>
<body>
<table>
<thead>
<tr><td>Title</td><td>Description</td></tr>
</thead>
<tbody>''');

    for (var tab in await chrome.getTabs()) {
      html
        ..write('<tr><td><a href="/devtools/inspector.html?ws=localhost:')
        ..write(port)
        ..write('/devtools/page/')
        ..write(tab.id)
        ..write('">');
      if (tab.title != null && tab.title!.isNotEmpty) {
        html.write(tab.title);
      } else {
        html.write(tab.url);
      }
      html
        ..write('</a></td><td>')
        ..write(tab.description)
        ..write('</td></tr>');
    }
    html.write(r'''</tbody>
</table>
</body>
</html>''');
    return html.toString();
  }

  Future<shelf.Response> _json(shelf.Request request) async {
    var path = request.url.pathSegments;
    if (path.length == 1 && path[0] == 'json') {
      var resp = jsonEncode(await chrome.getTabs(), toEncodable: _jsonEncode);
      _log.info('json: $resp');
      return shelf.Response.ok(resp,
          headers: {'Content-Type': 'application/json'});
    }
    return shelf.Response.notFound(null);
  }

  Future<shelf.Response> _forward(shelf.Request request) async {
    _log.info('forwarding: ${request.url}');
    var dtResp = await chrome.getUrl(request.url.path);

    if (dtResp.statusCode == 200) {
      return shelf.Response.ok(dtResp,
          headers: {'Content-Type': dtResp.headers.contentType.toString()});
    }
    _log.warning(
        'Forwarded ${request.url} returned statusCode: ${dtResp.statusCode}');
    return shelf.Response.notFound(null);
  }

  Future<shelf.Response> _webSocket(shelf.Request request) async {
    var path = request.url.pathSegments;
    if (path.length != 3 || path[0] != 'devtools' || path[1] != 'page') {
      return shelf.Response.notFound(null);
    }
    _log.info('connecting to websocket: ${request.url}');

    // TODO: The first arg of webSocketHandler is untyped; consider refactoring
    // (in package:web_socket_channel) to use a typedef.
    return ws.webSocketHandler((WebSocketChannel webSocket) async {
      var debugger = await _connections.putIfAbsent(path[2], () async {
        var tab = (await chrome.getTab((tab) => tab.id == path[2]))!;
        return WipConnection.connect(tab.webSocketDebuggerUrl);
      });
      WipDomModel? dom;
      if (modelDom) {
        dom = _modelDoms.putIfAbsent(path[2], () {
          return WipDomModel(debugger.dom);
        });
      }
      var forwarder = WipForwarder(debugger, webSocket.stream.cast(),
          sink: webSocket.sink, domModel: dom);
      debugger.onClose.listen((_) {
        _connections.remove(path[2]);
        _modelDoms.remove(path[2]);
        forwarder.stop();
      });
    })(request);
  }

  Future close() async {
    if (_server != null) {
      await (await _server!).close(force: true);
      _server = null;
    }
  }

  Object? _jsonEncode(Object? obj) {
    if (obj is ChromeTab) {
      var json = <String, dynamic>{
        'description': obj.description,
        'devtoolsFrontendUrl': '/devtools/inspector.html'
            '?ws=localhost:$port/devtools/page/${obj.id}',
        'id': obj.id,
        'title': obj.title,
        'type': obj.type,
        'url': obj.url,
        'webSocketDebuggerUrl': 'ws://localhost:$port/devtools/page/${obj.id}'
      };
      if (obj.faviconUrl != null) {
        json['faviconUrl'] = obj.faviconUrl;
      }
      return json;
    } else if (obj is Uri) {
      return obj.toString();
    } else if (obj is Iterable) {
      return obj.toList();
    } else {
      return obj;
    }
  }
}
