// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

// TODO(48602): deprecate SILENT_OBSERVATORY in favor of SILENT_VM_SERVICE
bool silentObservatory = bool.fromEnvironment('SILENT_OBSERVATORY');
bool silentVMService = bool.fromEnvironment('SILENT_VM_SERVICE');

void serverPrint(String s) {
  if (silentObservatory || silentVMService) {
    // We've been requested to be silent.
    return;
  }
  print(s);
}

class WebSocketClient extends Client {
  static const int parseErrorCode = 4000;
  static const int binaryMessageErrorCode = 4001;
  static const int notMapErrorCode = 4002;
  static const int idErrorCode = 4003;
  final WebSocket socket;

  WebSocketClient(this.socket, VMService service) : super(service) {
    socket.listen((message) => onWebSocketMessage(message));
    socket.done.then((_) => close());
  }

  Future<void> disconnect() => socket.close();

  void onWebSocketMessage(message) {
    if (message is String) {
      dynamic jsonObj;
      try {
        jsonObj = json.decode(message);
      } catch (e) {
        socket.close(parseErrorCode, 'Message parse error: $e');
        return;
      }
      if (jsonObj is! Map<String, dynamic>) {
        socket.close(notMapErrorCode, 'Message must be a JSON map.');
        return;
      }
      final Map<String, dynamic> map = jsonObj;
      final rpc = Message.fromJsonRpc(this, map);
      switch (rpc.type) {
        case MessageType.Request:
          onRequest(rpc);
          break;
        case MessageType.Notification:
          onNotification(rpc);
          break;
        case MessageType.Response:
          onResponse(rpc);
          break;
      }
    } else {
      socket.close(binaryMessageErrorCode, 'Message must be a string.');
    }
  }

  void post(Response? result) {
    if (result == null) {
      // The result of a notification event. Do nothing.
      return;
    }
    try {
      switch (result.kind) {
        case ResponsePayloadKind.String:
        case ResponsePayloadKind.Binary:
          socket.add(result.payload);
          break;
        case ResponsePayloadKind.Utf8String:
          socket.addUtf8Text(result.payload as List<int>);
          break;
      }
    } on StateError catch (_) {
      // VM has shutdown, do nothing.
      return;
    }
  }

  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'type': 'WebSocketClient',
    'socket': '$socket',
  };
}

class HttpRequestClient extends Client {
  static final jsonContentType = ContentType(
    'application',
    'json',
    charset: 'utf-8',
  );
  final HttpRequest request;

  HttpRequestClient(this.request, VMService service)
    : super(service, sendEvents: false);

  Future<void> disconnect() async {
    await request.response.close();
    close();
  }

  void post(Response? result) {
    if (result == null) {
      // The result of a notification event. Nothing to do other than close the
      // connection.
      close();
      return;
    }

    HttpResponse response = request.response;
    // We closed the connection for bad origins earlier.
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.contentType = jsonContentType;
    switch (result.kind) {
      case ResponsePayloadKind.String:
        response.write(result.payload);
        break;
      case ResponsePayloadKind.Utf8String:
        response.add(result.payload);
        break;
      case ResponsePayloadKind.Binary:
        throw 'Can not handle binary responses';
    }
    response.close();
    close();
  }

  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['type'] = 'HttpRequestClient';
    map['request'] = '$request';
    return map;
  }
}

/// Responsible for launching a DevTools instance when the service is started
/// via SIGQUIT.
class _DebuggingSession {
  Future<bool> start(
    Uri serverAddress,
    String host,
    String port,
    bool disableServiceAuthCodes,
    bool enableDevTools,
  ) async {
    // This code is part of the SDK and it is ok to have a reference to the
    // internals of the Dart SDK in terms of location of the snapshot etc.
    // It is more efficient doing it this way instead of invoking the Dart CLI
    // with the 'development-service' command which would then dispatch to the
    // Dart AOT runtime.
    final dartDir = File(Platform.executable).parent.path;
    final suffix = Platform.isWindows ? '.exe' : '';
    final dartAotRuntime = 'dartaotruntime${suffix}';
    final dart = 'dart${suffix}';
    var executable = [dartDir, dartAotRuntime].join(Platform.pathSeparator);
    var script = [
      dartDir,
      'snapshots',
      'dds_aot.dart.snapshot',
    ].join(Platform.pathSeparator);
    if (FileSystemEntity.typeSync(script) == FileSystemEntityType.notFound) {
      script = [dartDir, 'dds_aot.dart.snapshot'].join(Platform.pathSeparator);
      if (FileSystemEntity.typeSync(script) == FileSystemEntityType.notFound) {
        executable = [dartDir, dart].join(Platform.pathSeparator);
        script = 'development-service';
      }
    }

    // If the directory of dart is '.' it's likely that dart is on the user's
    // PATH. If so, './dart' might not exist and we should be using 'dart'
    // instead.
    if (dartDir == '.' &&
        (FileSystemEntity.typeSync(executable)) ==
            FileSystemEntityType.notFound) {
      executable = dart;
    }
    var process = await Process.start(executable, [
      script,
      '--vm-service-uri=$serverAddress',
      '--bind-address=$host',
      '--bind-port=$port',
      if (disableServiceAuthCodes) '--disable-service-auth-codes',
      if (enableDevTools) '--serve-devtools',
      if (_enableServicePortFallback) '--enable-service-port-fallback',
    ], mode: ProcessStartMode.detachedWithStdio);
    if (process == null) {
      stderr.writeln('Could not start the VM service: Process.start failed\n');
      return false;
    }
    _process = process;

    // DDS will close stderr once it's finished launching.
    final launchResult = await _process.stderr.transform(utf8.decoder).join();

    void printError(String details) =>
        stderr.writeln('Could not start the VM service:\n$details');

    try {
      final result = json.decode(launchResult) as Map<String, dynamic>;
      if (result case {'state': 'started'}) {
        if (result case {'devToolsUri': String devToolsUri}) {
          // NOTE: update pkg/dartdev/lib/src/commands/run.dart if this message
          // is changed to ensure consistency.
          const devToolsMessagePrefix =
              'The Dart DevTools debugger and profiler is available at:';
          serverPrint('$devToolsMessagePrefix $devToolsUri');
        }
        if (result case {'dtd': {'uri': String dtdUri}} when _printDtd) {
          serverPrint('The Dart Tooling Daemon (DTD) is available at: $dtdUri');
        }
      } else {
        printError(result['error'] ?? result);
        return false;
      }
    } catch (_) {
      // Malformed JSON was likely encountered, so output the entirety of
      // stderr in the error message.
      printError(launchResult);
      return false;
    }
    return true;
  }

  void shutdown() => _process.kill();

  late Process _process;
}

class Server {
  static const WEBSOCKET_PATH = '/ws';
  static const ROOT_REDIRECT_PATH = '/index.html';

  final VMService _service;
  final String _ip;
  final bool _originCheckDisabled;
  final bool _authCodesDisabled;
  final bool _enableServicePortFallback;
  final String? _serviceInfoFilename;
  HttpServer? _httpServer;

  bool get running => _running;
  bool _running = false;

  bool acceptNewWebSocketConnections = true;
  int _port = -1;
  // Ensures only one server is started even if many requests to launch
  // the server come in concurrently.
  Completer<bool>? _startingCompleter;

  _DebuggingSession? _ddsInstance;

  /// Returns the server address including the auth token.
  Uri? get serverAddress {
    // If DDS is connected it should be treated as the "true" VM service and be
    // advertised as such.
    if (_service.ddsUri != null) {
      return _service.ddsUri;
    }
    final server = _httpServer;
    if (server != null) {
      final ip = server.address.address;
      final port = server.port;
      final path = !_authCodesDisabled ? '$serviceAuthToken/' : '/';
      return Uri(scheme: 'http', host: ip, port: port, path: path);
    }
    return null;
  }

  // On Fuchsia, authentication codes are disabled by default. To enable, the authentication token
  // would have to be written into the hub alongside the port number.
  Server(
    this._service,
    this._ip,
    this._port,
    this._originCheckDisabled,
    bool authCodesDisabled,
    this._serviceInfoFilename,
    this._enableServicePortFallback,
  ) : _authCodesDisabled = (authCodesDisabled || Platform.isFuchsia);

  Future<void> startup() async {
    if (running) {
      // Already running.
      return;
    }

    {
      final startingCompleter = _startingCompleter;
      if (startingCompleter != null) {
        if (!startingCompleter.isCompleted) {
          await startingCompleter.future;
        }
        return;
      }
    }

    final startingCompleter = Completer<bool>();
    _startingCompleter = startingCompleter;
    // Startup HTTP server.
    Future<bool> startServer() async {
      try {
        var address;
        var addresses = await InternetAddress.lookup(_ip);
        // Prefer IPv4 addresses.
        for (int i = 0; i < addresses.length; i++) {
          address = addresses[i];
          if (address.type == InternetAddressType.IPv4) break;
        }
        _httpServer = await HttpServer.bind(address, _port);
      } catch (e, st) {
        if (_port != 0 && _enableServicePortFallback) {
          serverPrint(
            'Failed to bind Dart VM service HTTP server to port $_port. '
            'Falling back to automatic port selection',
          );
          _port = 0;
          return await startServer();
        } else {
          serverPrint(
            'Could not start Dart VM service HTTP server:\n'
            '$e\n$st',
          );
          _notifyServerState('');
          onServerAddressChange(null);
          return false;
        }
      }
      return true;
    }

    if (!(await startServer())) {
      startingCompleter.complete(true);
      return;
    }
    if (_service.isExiting) {
      serverPrint(
        'Dart VM service HTTP server exiting before listening as '
        'vm service has received exit request\n',
      );
      startingCompleter.complete(true);
      await shutdown(true);
      return;
    }
    final server = _httpServer!;
    server.listen(_requestHandler, cancelOnError: true);

    if (_waitForDdsToAdvertiseService) {
      _ddsInstance = _DebuggingSession();
      await _ddsInstance!.start(
        serverAddress!,
        _ddsIP,
        _ddsPort.toString(),
        _authCodesDisabled,
        _serveDevtools,
      );
    } else {
      await outputConnectionInformation();
    }
    // Server is up and running.
    _running = true;
    _notifyServerState(serverAddress.toString());
    onServerAddressChange('$serverAddress');
    startingCompleter.complete(true);
  }

  Future<void> shutdown(bool forced) async {
    // If start is pending, wait for it to complete.
    if (_startingCompleter != null) {
      if (!_startingCompleter!.isCompleted) {
        await _startingCompleter!.future;
      }
    }

    final server = _httpServer;
    if (server == null) {
      // Not started.
      return;
    }

    if (Platform.isFuchsia) {
      _cleanupFuchsiaState(server.port);
    }

    final address = serverAddress!;

    try {
      // Shutdown HTTP server and subscription.
      await server.close(force: forced);
      if (!_service.isExiting) {
        // Only print this message if the service has been toggled off, not
        // when the VM is exiting.
        serverPrint('Dart VM service no longer listening on $address');
      }
    } catch (e, st) {
      serverPrint('Could not shutdown Dart VM service HTTP server:\n$e\n$st\n');
    } finally {
      _ddsInstance?.shutdown();
      _ddsInstance = null;
      _httpServer = null;
      _startingCompleter = null;
      _running = false;
      _notifyServerState('');
      onServerAddressChange(null);
    }
  }

  Future<void> outputConnectionInformation() async {
    serverPrint('The Dart VM service is listening on $serverAddress');
    if (Platform.isFuchsia) {
      _writeFuchsiaState(_httpServer!.port);
    }
    final serviceInfoFilenameLocal = _serviceInfoFilename;
    if (serviceInfoFilenameLocal != null &&
        serviceInfoFilenameLocal.isNotEmpty) {
      await _dumpServiceInfoToFile(serviceInfoFilenameLocal);
    }
  }

  bool _isAllowedOrigin(String origin) {
    Uri uri;
    try {
      uri = Uri.parse(origin);
    } catch (_) {
      return false;
    }

    // Explicitly add localhost and 127.0.0.1 on any port (necessary for
    // adb port forwarding).
    if ((uri.host == 'localhost') ||
        (uri.host == '::1') ||
        (uri.host == '127.0.0.1')) {
      return true;
    }

    final server = _httpServer!;
    if ((uri.port == server.port) &&
        ((uri.host == server.address.address) ||
            (uri.host == server.address.host))) {
      return true;
    }

    return false;
  }

  bool _originCheck(HttpRequest request) {
    if (_originCheckDisabled) {
      // Always allow.
      return true;
    }
    // First check the web-socket specific origin.
    List<String>? origins = request.headers['Sec-WebSocket-Origin'];
    if (origins == null) {
      // Fall back to the general Origin field.
      origins = request.headers['Origin'];
    }
    if (origins == null) {
      // No origin sent. This is a non-browser client or a same-origin request.
      return true;
    }
    for (final origin in origins) {
      if (_isAllowedOrigin(origin)) {
        return true;
      }
    }
    return false;
  }

  /// Checks the [requestUri] for the service auth token and returns the path
  /// as a String. If the service auth token check fails, returns null.
  /// Returns a Uri if a redirect is required.
  dynamic _checkAuthTokenAndGetPath(Uri requestUri) {
    if (_authCodesDisabled) {
      return requestUri.path == '/' ? ROOT_REDIRECT_PATH : requestUri.path;
    }
    final List<String> requestPathSegments = requestUri.pathSegments;
    if (requestPathSegments.isEmpty) {
      // Malformed.
      return null;
    }
    // Check that we were given the auth token.
    final authToken = requestPathSegments[0];
    if (authToken != serviceAuthToken) {
      // Malformed.
      return null;
    }
    // Missing a trailing '/'. We'll need to redirect to serve
    // ROOT_REDIRECT_PATH correctly, otherwise the response is misinterpreted.
    if (requestPathSegments.length == 1) {
      // requestPathSegments is unmodifiable. Copy it.
      final pathSegments = List<String>.from(requestPathSegments);

      // Adding an empty string to the path segments results in the path having
      // a trailing '/'.
      pathSegments.add('');

      return requestUri.replace(pathSegments: pathSegments);
    }
    // Construct the actual request path by chopping off the auth token.
    return (requestPathSegments[1] == '')
        ? ROOT_REDIRECT_PATH
        : '/${requestPathSegments.sublist(1).join('/')}';
  }

  Future<void> _processDevFSRequest(HttpRequest request) async {
    String? fsName;
    String? fsPath;
    Uri? fsUri;

    try {
      // Extract the fs name and fs path from the request headers.
      fsName = request.headers['dev_fs_name']![0];

      // Prefer Uri encoding first, then fallback to path encoding.
      if (request.headers['dev_fs_uri_b64'] case [String base64Uri]) {
        fsUri = Uri.parse(utf8.decode(base64.decode(base64Uri)));
      } else if (request.headers['dev_fs_path_b64'] case [String base64Uri]) {
        fsPath = utf8.decode(base64.decode(base64Uri));
      } else if (request.headers['dev_fs_path'] case [String path]) {
        fsPath = path;
      }
    } catch (_) {
      /* ignore */
    }

    try {
      final result = await _service.devfs.handlePutStream(
        fsName,
        fsPath,
        fsUri,
        request.cast<List<int>>().transform(gzip.decoder),
      );

      request.response.headers.contentType = HttpRequestClient.jsonContentType;
      request.response.write(result);
    } catch (e, st) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(e);
    } finally {
      request.response.close();
    }
  }

  void _handleWebSocketRequest(HttpRequest request) {
    final subprotocols = request.headers['sec-websocket-protocol'];
    if (acceptNewWebSocketConnections) {
      WebSocketTransformer.upgrade(
        request,
        protocolSelector:
            subprotocols == null ? null : (_) => 'implicit-redirect',
        compression: CompressionOptions.compressionOff,
      ).then((WebSocket webSocket) {
        WebSocketClient(webSocket, _service);
      });
    } else {
      // Attempt to redirect client to the DDS instance.
      request.response.redirect(_service.ddsUri!);
    }
  }

  Future<void> _redirectToDevTools(HttpRequest request) async {
    final ddsUri = _service.ddsUri;
    if (ddsUri == null) {
      request.response.headers.contentType = ContentType.text;
      request.response.write(
        'This VM does not have a registered Dart '
        'Development Service (DDS) instance and is not currently serving '
        'Dart DevTools.',
      );
      request.response.close();
      return;
    }
    // We build this path manually rather than manipulating ddsUri directly
    // as the resulting path requires an unencoded '#'. The Uri class will
    // always encode '#' as '%23' in paths to avoid conflicts with fragments,
    // which will result in the redirect failing.
    final path = StringBuffer();
    // Add authentication code to the path.
    if (ddsUri.pathSegments.length > 1) {
      path.writeAll([
        ddsUri.pathSegments
            .sublist(0, ddsUri.pathSegments.length - 1)
            .join('/'),
        '/',
      ]);
    }
    final queryComponent = Uri.encodeQueryComponent(
      ddsUri.replace(scheme: 'ws', path: '${path}ws').toString(),
    );
    path.writeAll(['devtools/', '?uri=$queryComponent']);
    final redirectUri = Uri.parse('http://${ddsUri.host}:${ddsUri.port}/$path');
    request.response.redirect(redirectUri);
    return;
  }

  Future<void> _requestHandler(HttpRequest request) async {
    if (!_originCheck(request)) {
      // This is a cross origin attempt to connect
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write('forbidden origin');
      request.response.close();
      return;
    }
    if (request.method == 'PUT') {
      // PUT requests are forwarded to DevFS for processing.
      await _processDevFSRequest(request);
      return;
    }
    if (request.method != 'GET') {
      // Not a GET request. Do nothing.
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.write('method not allowed');
      request.response.close();
      return;
    }

    final result = _checkAuthTokenAndGetPath(request.uri);
    if (result == null) {
      // Either no authentication code was provided when one was expected or an
      // incorrect authentication code was provided.
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write('missing or invalid authentication code');
      request.response.close();
      return;
    } else if (result is Uri) {
      // The URI contains the valid auth token but is missing a trailing '/'.
      // Redirect to the same URI with the trailing '/' to correctly serve
      // index.html.
      request.response.redirect(result);
      return;
    }

    final String path = result;
    if (path == WEBSOCKET_PATH) {
      _handleWebSocketRequest(request);
      return;
    }
    // Don't redirect HTTP VM service requests, just requests for Observatory
    // assets.
    if (!_serveObservatory && path == ROOT_REDIRECT_PATH) {
      await _redirectToDevTools(request);
      return;
    }
    if (assets == null) {
      request.response.headers.contentType = ContentType.text;
      request.response.write('This VM was built without the Observatory UI.');
      request.response.close();
      return;
    }
    final asset = assets![path];
    if (asset != null) {
      // Serving up a static asset (e.g. .css, .html, .png).
      request.response.headers.contentType = ContentType.parse(asset.mimeType);
      request.response.add(asset.data);
      request.response.close();
      return;
    }
    // HTTP based service request.
    final client = HttpRequestClient(request, _service);
    final message = Message.fromUri(
      client,
      Uri(path: path, queryParameters: request.uri.queryParameters),
    );
    client.onRequest(message); // exception free, no need to try catch
  }

  Future<File> _dumpServiceInfoToFile(String serviceInfoFilenameLocal) async {
    final serviceInfo = <String, dynamic>{'uri': serverAddress.toString()};
    const kFileScheme = 'file://';
    // There's lots of URI parsing weirdness as Uri.parse doesn't do the right
    // thing with Windows drive letters. Only use Uri.parse with known file
    // URIs, and use Uri.file otherwise to properly handle drive letters in
    // paths.
    final uri =
        serviceInfoFilenameLocal.startsWith(kFileScheme)
            ? Uri.parse(serviceInfoFilenameLocal)
            : Uri.file(serviceInfoFilenameLocal);
    final file = File.fromUri(uri);
    return file.writeAsString(json.encode(serviceInfo));
  }

  void _writeFuchsiaState(int port) {
    // Create a file with the port number.
    final tmp = Directory.systemTemp.path;
    final path = '$tmp/dart.services/${port}';
    serverPrint('Creating $path');
    File(path).createSync(recursive: true);
  }

  void _cleanupFuchsiaState(int port) {
    // Remove the file with the port number.
    final tmp = Directory.systemTemp.path;
    final path = '$tmp/dart.services/$port';
    serverPrint('Deleting $path');
    File(path).deleteSync();
  }
}

@pragma("vm:external-name", "VMServiceIO_NotifyServerState")
external void _notifyServerState(String uri);
