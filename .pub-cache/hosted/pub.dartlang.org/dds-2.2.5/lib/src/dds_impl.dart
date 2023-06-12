// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../dds.dart';
import 'binary_compatible_peer.dart';
import 'client.dart';
import 'client_manager.dart';
import 'constants.dart';
import 'devtools/handler.dart';
import 'expression_evaluator.dart';
import 'isolate_manager.dart';
import 'package_uri_converter.dart';
import 'stream_manager.dart';

@visibleForTesting
typedef PeerBuilder = Future<json_rpc.Peer> Function(WebSocketChannel, dynamic);

@visibleForTesting
typedef WebSocketBuilder = WebSocketChannel Function(Uri);

@visibleForTesting
PeerBuilder peerBuilder = _defaultPeerBuilder;

@visibleForTesting
WebSocketBuilder webSocketBuilder = _defaultWebSocketBuilder;

Future<json_rpc.Peer> _defaultPeerBuilder(
    WebSocketChannel ws, dynamic streamManager) async {
  return BinaryCompatiblePeer(ws, streamManager);
}

WebSocketChannel _defaultWebSocketBuilder(Uri uri) {
  return WebSocketChannel.connect(uri.replace(scheme: 'ws'));
}

class DartDevelopmentServiceImpl implements DartDevelopmentService {
  DartDevelopmentServiceImpl(
    this._remoteVmServiceUri,
    this._uri,
    this._authCodesEnabled,
    this._cachedUserTags,
    this._ipv6,
    this._devToolsConfiguration,
    this.shouldLogRequests,
    this._enableServicePortFallback,
    this.uriConverter,
  ) {
    _clientManager = ClientManager(this);
    _expressionEvaluator = ExpressionEvaluator(this);
    _isolateManager = IsolateManager(this);
    _streamManager = StreamManager(this);
    _packageUriConverter = PackageUriConverter(this);
    _authCode = _authCodesEnabled ? _makeAuthToken() : '';
  }

  Future<void> startService() async {
    DartDevelopmentServiceException? error;
    // TODO(bkonyi): throw if we've already shutdown.
    // Establish the connection to the VM service.
    _vmServiceSocket = webSocketBuilder(remoteVmServiceWsUri);
    vmServiceClient = await peerBuilder(_vmServiceSocket, _streamManager);
    // Setup the JSON RPC client with the VM service.
    unawaited(
      vmServiceClient.listen().then(
        (_) {
          if (_initializationComplete) {
            shutdown();
          } else {
            // If we fail to connect to the service or the connection is
            // terminated while we're starting up, we'll need to cleanup later
            // once DDS has finished initializing to make sure all ports are
            // closed before throwing the exception.
            error = DartDevelopmentServiceException.failedToStart();
          }
        },
        onError: (e, st) {
          if (_initializationComplete) {
            shutdown();
          } else {
            // If we encounter an error while we're starting up, we'll need to
            // cleanup later once DDS has finished initializing to make sure
            // all ports are closed before throwing the exception.
            error = DartDevelopmentServiceException.connectionIssue(
              e.toString(),
            );
          }
        },
      ),
    );

    try {
      // Setup stream event handling.
      await streamManager.listen();

      // Populate initial isolate state.
      await _isolateManager.initialize();

      // Once we have a connection to the VM service, we're ready to spawn the intermediary.
      await _startDDSServer();
      _initializationComplete = true;
    } on StateError {
      // Handle json-rpc state errors.
      //
      // It's possible that ordering of events on the event queue can result in
      // the cleanup code above being called after this function has returned,
      // resulting in an invalid DDS instance being released into the wild.
      //
      // If initialization hasn't completed and the error hasn't already been
      // set, set it now.
      error ??= DartDevelopmentServiceException.failedToStart();
    }

    // Check if we encountered any errors during startup, cleanup, and throw.
    if (error != null) {
      await shutdown();
      throw error!;
    }
  }

  Future<void> _startDDSServer() async {
    // No provided address, bind to an available port on localhost.
    final host = uri?.host ??
        (_ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4)
            .host;
    var port = uri?.port ?? 0;
    var pipeline = const Pipeline();
    if (shouldLogRequests) {
      pipeline = pipeline.addMiddleware(
        logRequests(
          logger: (String message, bool isError) {
            print('Log: $message');
          },
        ),
      );
    }
    pipeline = pipeline.addMiddleware(_authCodeMiddleware);
    final handler = pipeline.addHandler(_handlers().handler);
    // Start the DDS server. Run in an error Zone to ensure that asynchronous
    // exceptions encountered during request handling are handled, as exceptions
    // thrown during request handling shouldn't take down the entire service.
    late String errorMessage;
    final tmpServer = await runZonedGuarded(
      () async {
        Future<HttpServer?> startServer() async {
          try {
            return await io.serve(handler, host, port);
          } on SocketException catch (e) {
            if (_enableServicePortFallback && port != 0) {
              // Try again, this time with a random port.
              port = 0;
              return await startServer();
            }
            errorMessage = e.message;
            if (e.osError != null) {
              errorMessage += ' (${e.osError!.message})';
            }
            errorMessage += ': ${e.address?.host}:${e.port}';
            return null;
          }
        }

        return await startServer();
      },
      (error, stack) {
        if (shouldLogRequests) {
          print('Asynchronous error: $error\n$stack');
        }
      },
    );
    if (tmpServer == null) {
      throw DartDevelopmentServiceException.connectionIssue(errorMessage);
    }
    _server = tmpServer;

    final tmpUri = Uri(
      scheme: 'http',
      host: host,
      port: _server.port,
      path: '$authCode/',
    );

    // Notify the VM service that this client is DDS and that it should close
    // and refuse connections from other clients. DDS is now acting in place of
    // the VM service.
    try {
      await vmServiceClient.sendRequest('_yieldControlToDDS', {
        'uri': tmpUri.toString(),
      });
    } on json_rpc.RpcException catch (e) {
      await _server.close(force: true);
      String message = e.toString();
      if (e.data != null) {
        message += ' data: ${e.data}';
      }
      // _yieldControlToDDS fails if DDS is not the only VM service client.
      throw DartDevelopmentServiceException.existingDdsInstance(message);
    }

    _uri = tmpUri;
  }

  /// Stop accepting requests after gracefully handling existing requests.
  @override
  Future<void> shutdown() async {
    if (_done.isCompleted || _shuttingDown || !_initializationComplete) {
      // Already shutdown or we were interrupted during initialization.
      return;
    }
    _shuttingDown = true;
    // Don't accept any more HTTP requests.
    await _server.close();

    // Close connections to clients.
    await clientManager.shutdown();

    // Close connection to VM service.
    await _vmServiceSocket.sink.close();

    _done.complete();
  }

  /// Generates a base64 authentication code that must be passed as the first
  /// part of the request path. Used to prevent random connections from clients
  /// watching the common service ports.
  static String _makeAuthToken() {
    final kTokenByteSize = 8;
    final bytes = Uint8List(kTokenByteSize);
    final random = Random.secure();
    for (int i = 0; i < kTokenByteSize; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Url.encode(bytes);
  }

  /// Shelf middleware to verify authentication tokens before processing a
  /// request.
  ///
  /// If authentication codes are enabled, a 403 response is returned if the
  /// authentication code is not the first element of the request's path.
  /// Otherwise, the request is forwarded to the first handler.
  Handler _authCodeMiddleware(Handler innerHandler) => (Request request) {
        if (_authCodesEnabled) {
          final forbidden =
              Response.forbidden('missing or invalid authentication code');
          final pathSegments = request.url.pathSegments;
          if (pathSegments.isEmpty) {
            return forbidden;
          }
          final authToken = pathSegments[0];
          if (authToken != authCode) {
            return forbidden;
          }
          // Creates a new request with the authentication code stripped from
          // the request URI. This method doesn't behave as you might expect.
          // Calling request.change(path: authToken) has the effect of changing
          // the request's handler path from '/' to '/$authToken/' while also
          // changing the request's url from '$authToken/restofpath/' to
          // 'restofpath/'. The handler path is only used by shelf, so this
          // operation has the effect of stripping the authentication code from
          // the request.
          request = request.change(path: authToken);
        }
        return innerHandler(request);
      };

  // Attempt to upgrade HTTP requests to a websocket before processing them as
  // standard HTTP requests. The websocket handler will fail quickly if the
  // request doesn't appear to be a websocket upgrade request.
  Cascade _handlers() {
    return Cascade()
        .add(_webSocketHandler())
        .add(_sseHandler())
        .add(_httpHandler());
  }

  Handler _webSocketHandler() => webSocketHandler((WebSocketChannel ws) {
        final client = DartDevelopmentServiceClient.fromWebSocket(
          this,
          ws,
          vmServiceClient,
        );
        clientManager.addClient(client);
      });

  Handler _sseHandler() {
    final handler = SseHandler(
      authCodesEnabled
          ? Uri.parse('/$authCode/$_kSseHandlerPath')
          : Uri.parse('/$_kSseHandlerPath'),
      keepAlive: sseKeepAlive,
    );

    handler.connections.rest.listen((sseConnection) {
      final client = DartDevelopmentServiceClient.fromSSEConnection(
        this,
        sseConnection,
        vmServiceClient,
      );
      clientManager.addClient(client);
    });

    return handler.handler;
  }

  Handler _httpHandler() {
    if (_devToolsConfiguration != null && _devToolsConfiguration!.enable) {
      // Install the DevTools handlers and forward any unhandled HTTP requests to
      // the VM service.
      final String buildDir =
          _devToolsConfiguration!.customBuildDirectoryPath.toFilePath();
      return defaultHandler(
        dds: this,
        buildDir: buildDir,
        notFoundHandler: proxyHandler(remoteVmServiceUri),
      ) as FutureOr<Response> Function(Request);
    }
    return proxyHandler(remoteVmServiceUri);
  }

  List<String> _cleanupPathSegments(Uri uri) {
    final pathSegments = <String>[];
    if (uri.pathSegments.isNotEmpty) {
      pathSegments.addAll(uri.pathSegments.where(
        // Strip out the empty string that appears at the end of path segments.
        // Empty string elements will result in an extra '/' being added to the
        // URI.
        (s) => s.isNotEmpty,
      ));
    }
    return pathSegments;
  }

  Uri? _toWebSocket(Uri? uri) {
    if (uri == null) {
      return null;
    }
    final pathSegments = _cleanupPathSegments(uri);
    pathSegments.add('ws');
    return uri.replace(scheme: 'ws', pathSegments: pathSegments);
  }

  Uri? _toSse(Uri? uri) {
    if (uri == null) {
      return null;
    }
    final pathSegments = _cleanupPathSegments(uri);
    pathSegments.add(_kSseHandlerPath);
    return uri.replace(scheme: 'sse', pathSegments: pathSegments);
  }

  Uri? _toDevTools(Uri? uri) {
    // The DevTools URI is a bit strange as the query parameters appear after
    // the fragment. There's no nice way to encode the query parameters
    // properly, so we create another Uri just to grab the formatted query.
    // The result will need to have '/?' prepended when being used as the
    // fragment to get the correct format.
    final query = Uri(
      queryParameters: {
        'uri': wsUri.toString(),
      },
    ).query;
    return Uri(
      scheme: 'http',
      host: uri!.host,
      port: uri.port,
      pathSegments: [
        ...uri.pathSegments.where(
          (e) => e.isNotEmpty,
        ),
        'devtools',
        '',
      ],
      fragment: '/?$query',
    );
  }

  String? getNamespace(DartDevelopmentServiceClient client) =>
      clientManager.clients.keyOf(client);

  bool get authCodesEnabled => _authCodesEnabled;
  final bool _authCodesEnabled;
  String? get authCode => _authCode;
  String? _authCode;

  final bool _enableServicePortFallback;
  final bool shouldLogRequests;

  Uri get remoteVmServiceUri => _remoteVmServiceUri;

  @override
  Uri get remoteVmServiceWsUri => _toWebSocket(_remoteVmServiceUri)!;
  Uri _remoteVmServiceUri;

  @override
  Uri? get uri => _uri;
  Uri? _uri;

  @override
  Uri? get sseUri => _toSse(_uri);

  @override
  Uri? get wsUri => _toWebSocket(_uri);

  @override
  Uri? get devToolsUri =>
      _devToolsConfiguration?.enable ?? false ? _toDevTools(_uri) : null;

  final bool _ipv6;

  bool get isRunning => _uri != null;

  final DevToolsConfiguration? _devToolsConfiguration;

  List<String> get cachedUserTags => UnmodifiableListView(_cachedUserTags);
  final List<String> _cachedUserTags;

  Future<void> get done => _done.future;
  Completer _done = Completer<void>();
  bool _initializationComplete = false;
  bool _shuttingDown = false;

  UriConverter? uriConverter;
  PackageUriConverter get packageUriConverter => _packageUriConverter;
  late PackageUriConverter _packageUriConverter;

  ClientManager get clientManager => _clientManager;
  late ClientManager _clientManager;

  ExpressionEvaluator get expressionEvaluator => _expressionEvaluator;
  late ExpressionEvaluator _expressionEvaluator;

  IsolateManager get isolateManager => _isolateManager;
  late IsolateManager _isolateManager;

  StreamManager get streamManager => _streamManager;
  late StreamManager _streamManager;

  static const _kSseHandlerPath = '\$debugHandler';

  late json_rpc.Peer vmServiceClient;
  late WebSocketChannel _vmServiceSocket;
  late HttpServer _server;
}
