// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dds/dds.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf.dart' hide Response;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:vm_service/vm_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../connections/app_connection.dart';
import '../loaders/strategy.dart';
import '../readers/asset_reader.dart';
import '../services/expression_compiler.dart';
import '../debugging/execution_context.dart';
import '../debugging/remote_debugger.dart';
import '../events.dart';
import '../utilities/shared.dart';
import '../utilities/sdk_configuration.dart';
import 'chrome_proxy_service.dart';

bool _acceptNewConnections = true;
int _clientsConnected = 0;

Logger _logger = Logger('DebugService');

void Function(WebSocketChannel, String) _createNewConnectionHandler(
  ChromeProxyService chromeProxyService,
  ServiceExtensionRegistry serviceExtensionRegistry, {
  void Function(Map<String, dynamic>) onRequest,
  void Function(Map<String, dynamic>) onResponse,
}) {
  return (webSocket, protocol) {
    final responseController = StreamController<Map<String, Object>>();
    webSocket.sink.addStream(responseController.stream.map((response) {
      if (onResponse != null) onResponse(response);
      return jsonEncode(response);
    }));
    final inputStream = webSocket.stream.map((value) {
      if (value is List<int>) {
        value = utf8.decode(value as List<int>);
      } else if (value is! String) {
        throw StateError(
            'Got value with unexpected type ${value.runtimeType} from web '
            'socket, expected a List<int> or String.');
      }
      final request = jsonDecode(value as String) as Map<String, Object>;
      if (onRequest != null) onRequest(request);
      return request;
    });
    ++_clientsConnected;
    VmServerConnection(inputStream, responseController.sink,
            serviceExtensionRegistry, chromeProxyService)
        .done
        .whenComplete(() async {
      --_clientsConnected;
      if (!_acceptNewConnections && _clientsConnected == 0) {
        // DDS has disconnected so we can allow for clients to connect directly
        // to DWDS.
        _acceptNewConnections = true;
      }
    });
  };
}

Future<void> _handleSseConnections(
  SseHandler handler,
  ChromeProxyService chromeProxyService,
  ServiceExtensionRegistry serviceExtensionRegistry, {
  void Function(Map<String, dynamic>) onRequest,
  void Function(Map<String, dynamic>) onResponse,
}) async {
  while (await handler.connections.hasNext) {
    final connection = await handler.connections.next;
    final responseController = StreamController<Map<String, Object>>();
    final sub = responseController.stream.map((response) {
      if (onResponse != null) onResponse(response);
      return jsonEncode(response);
    }).listen(connection.sink.add);
    unawaited(chromeProxyService.remoteDebugger.onClose.first.whenComplete(() {
      connection.sink.close();
      sub.cancel();
    }));
    final inputStream = connection.stream.map((value) {
      final request = jsonDecode(value) as Map<String, Object>;
      if (onRequest != null) onRequest(request);
      return request;
    });
    ++_clientsConnected;
    final vmServerConnection = VmServerConnection(inputStream,
        responseController.sink, serviceExtensionRegistry, chromeProxyService);
    unawaited(vmServerConnection.done.whenComplete(() {
      --_clientsConnected;
      if (!_acceptNewConnections && _clientsConnected == 0) {
        // DDS has disconnected so we can allow for clients to connect directly
        // to DWDS.
        _acceptNewConnections = true;
      }
      return sub.cancel();
    }));
  }
}

/// A Dart Web Debug Service.
///
/// Creates a [ChromeProxyService] from an existing Chrome instance.
class DebugService {
  static String _ddsUri;

  final VmServiceInterface chromeProxyService;
  final String hostname;
  final ServiceExtensionRegistry serviceExtensionRegistry;
  final int port;
  final String authToken;
  final HttpServer _server;
  final bool _useSse;
  final bool _spawnDds;
  final UrlEncoder _urlEncoder;
  DartDevelopmentService _dds;

  /// Null until [close] is called.
  ///
  /// All subsequent calls to [close] will return this future.
  Future<void> _closed;

  DebugService._(
      this.chromeProxyService,
      this.hostname,
      this.port,
      this.authToken,
      this.serviceExtensionRegistry,
      this._server,
      this._useSse,
      this._spawnDds,
      this._urlEncoder);

  Future<void> close() => _closed ??= Future.wait([
        _server.close(),
        if (_dds != null) _dds.shutdown(),
      ]);

  Future<void> startDartDevelopmentService() async {
    // Note: DDS can handle both web socket and SSE connections with no
    // additional configuration.
    _dds = await DartDevelopmentService.startDartDevelopmentService(
      Uri(
        scheme: 'http',
        host: hostname,
        port: port,
        path: authToken,
      ),
      serviceUri: Uri(
        scheme: 'http',
        host: hostname,
        port: 0,
      ),
      ipv6: await useIPv6ForHost(hostname),
    );
  }

  String get uri {
    if (_spawnDds && _dds != null) {
      return (_useSse ? _dds.sseUri : _dds.wsUri).toString();
    }
    return (_useSse
            ? Uri(
                scheme: 'sse',
                host: hostname,
                port: port,
                path: '$authToken/\$debugHandler',
              )
            : Uri(
                scheme: 'ws',
                host: hostname,
                port: port,
                path: authToken,
              ))
        .toString();
  }

  String _encodedUri;
  Future<String> get encodedUri async {
    if (_encodedUri != null) return _encodedUri;
    var encodedUri = uri;
    if (_urlEncoder != null) encodedUri = await _urlEncoder(encodedUri);
    return _encodedUri = encodedUri;
  }

  static bool yieldControlToDDS(String uri) {
    if (_clientsConnected > 1) {
      return false;
    }
    _ddsUri = uri;
    _acceptNewConnections = false;
    return true;
  }

  static Future<DebugService> start(
    String hostname,
    RemoteDebugger remoteDebugger,
    ExecutionContext executionContext,
    String root,
    AssetReader assetReader,
    LoadStrategy loadStrategy,
    AppConnection appConnection,
    UrlEncoder urlEncoder, {
    void Function(Map<String, dynamic>) onRequest,
    void Function(Map<String, dynamic>) onResponse,
    bool spawnDds = true,
    bool useSse,
    ExpressionCompiler expressionCompiler,
    SdkConfigurationProvider sdkConfigurationProvider,
  }) async {
    useSse ??= false;
    final chromeProxyService = await ChromeProxyService.create(
      remoteDebugger,
      root,
      assetReader,
      loadStrategy,
      appConnection,
      executionContext,
      expressionCompiler,
      sdkConfigurationProvider,
    );
    final authToken = _makeAuthToken();
    final serviceExtensionRegistry = ServiceExtensionRegistry();
    Handler handler;
    // DDS will always connect to DWDS via web sockets.
    if (useSse && !spawnDds) {
      final sseHandler = SseHandler(Uri.parse('/$authToken/\$debugHandler'),
          keepAlive: const Duration(seconds: 5));
      handler = sseHandler.handler;
      unawaited(_handleSseConnections(
          sseHandler, chromeProxyService, serviceExtensionRegistry,
          onRequest: onRequest, onResponse: onResponse));
    } else {
      final innerHandler = webSocketHandler(_createNewConnectionHandler(
          chromeProxyService, serviceExtensionRegistry,
          onRequest: onRequest, onResponse: onResponse));
      handler = (shelf.Request request) {
        if (!_acceptNewConnections) {
          return shelf.Response.forbidden(
            'Cannot connect directly to the VM service as a Dart Development '
            'Service (DDS) instance has taken control and can be found at '
            '$_ddsUri.',
          );
        }
        if (request.url.pathSegments.first != authToken) {
          return shelf.Response.forbidden('Incorrect auth token');
        }
        return innerHandler(request);
      };
    }
    final server = await startHttpServer(hostname, port: 44456);
    serveHttpRequests(server, handler, (e, s) {
      _logger.warning('Error serving requests', e);
      emitEvent(DwdsEvent.httpRequestException('DebugService', '$e:$s'));
    });
    return DebugService._(
      chromeProxyService,
      server.address.host,
      server.port,
      authToken,
      serviceExtensionRegistry,
      server,
      useSse,
      spawnDds,
      urlEncoder,
    );
  }
}

// Creates a random auth token for more secure connections.
String _makeAuthToken() {
  final tokenBytes = 8;
  final bytes = Uint8List(tokenBytes);
  final random = Random.secure();
  for (var i = 0; i < tokenBytes; i++) {
    bytes[i] = random.nextInt(256);
  }
  return base64Url.encode(bytes);
}
