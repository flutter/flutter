// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//
// Implementation of ServerSocket and RawServerSocket for Mojo.
//

patch class RawServerSocket {
  /* patch */ static Future<RawServerSocket> bind(address,
                                                  int port,
                                                  {int backlog: 0,
                                                   bool v6Only: false,
                                                   bool shared: false}) {
    return _MojoRawServerSocket.bind(address, port, backlog, v6Only, shared);
  }
}

patch class ServerSocket {
  /* patch */ static Future<ServerSocket> bind(address,
                                               int port,
                                               {int backlog: 0,
                                                bool v6Only: false,
                                                bool shared: false}) {
    return _MojoServerSocket.bind(address, port, backlog, v6Only, shared);
  }
}

class _MojoRawServerSocket extends Stream<RawSocket>
                           implements RawServerSocket {
  final _tcpBoundSocket = new TcpBoundSocketProxy.unbound();
  final _tcpServerSocket = new TcpServerSocketProxy.unbound();
  final bool _v6Only;
  InternetAddress _boundAddress;
  int _boundPort;
  StreamController<RawSocket> _controller;
  ReceivePort _referencePort;
  Future _scheduledAccept;
  bool _paused = false;
  bool _closed = false;
  var _owner;

  static Future<_MojoRawServerSocket> _bind(NetAddress bindAddress,
                                            int backlog,
                                            bool v6Only,
                                            bool shared) async {
    final rawServerSocket = new _MojoRawServerSocket(v6Only);
    final networkService = _getNetworkService().ptr;
    assert(networkService != null);
    var response =
        await networkService.createTcpBoundSocket(
            bindAddress,
            rawServerSocket._tcpBoundSocket);
    if (!_NetworkService._okay(response.result)) {
      rawServerSocket.close();
      _NetworkService._throwOnError(response.result);
    }
    rawServerSocket._boundAddress =
        _NetworkServiceCodec._fromNetAddress(response.boundTo);
    rawServerSocket._boundPort =
        _NetworkServiceCodec._portFromNetAddress(response.boundTo);
    final boundSocket = rawServerSocket._tcpBoundSocket.ptr;
    response =
        await boundSocket.startListening(rawServerSocket._tcpServerSocket);
    if (!_NetworkService._okay(response.result)) {
      rawServerSocket.close();
      _NetworkService._throwOnError(response.result);
    }
    return rawServerSocket;
  }

  static Future<_MojoRawServerSocket> bind(address,
                                           int port,
                                           int backlog,
                                           bool v6Only,
                                           bool shared) {
    if ((port < 0) || (port > 0xFFFF)) {
      throw new ArgumentError("Invalid port $port");
    }
    if (backlog < 0) {
      throw new ArgumentError("Invalid backlog $backlog");
    }
    if (address is _InternetAddress) {
      var bindAddress =
          _NetworkServiceCodec._fromInternetAddress(address, port);
      return _bind(bindAddress, backlog, v6Only, shared);
    } else {
      // Use host resolver and bind to first address.
      throw new UnimplementedError('TODO(johnmccutchan)');
    }
  }

  _MojoRawServerSocket(this._v6Only);

  _accept() async {
    var rawSocket = new _MojoRawSocket();
    rawSocket._localAddress = _boundAddress;
    rawSocket._localPort = _boundPort;
    rawSocket._setupIn();
    rawSocket._setupOut();
    rawSocket._tracePipeIn();
    rawSocket._tracePipeOut();
    var response;
    try {
      response = await
          _tcpServerSocket.ptr.accept(rawSocket._pipeOut.consumer,
                                      rawSocket._pipeIn.producer,
                                      rawSocket._tcpConnectedSocket);
    } on ProxyCloseException catch (e) {
      rawSocket.destroy();
      await _destroy();
      return;
    } catch (e) {
      _controller.addError(e);
      rawSocket.destroy();
      await _destroy();
      return;
    }
    if (!_NetworkService._okay(response.result)) {
      rawSocket.destroy();
      _onAcceptFailure(response.result);
      return;
    }
    rawSocket._traceBoundSocket();
    rawSocket._traceConnectedSocket();
    if (_paused) {
      // TODO(johnmccutchan): Add a data pipe to server socket to be notified
      // when a connection is waiting. Re-implement pause using this signal.
      _scheduledAccept = null;
      rawSocket.destroy();
      return;
    }
    if (_closed) {
      rawSocket.destroy();
      await _destroy();
      return;
    }
    rawSocket._remoteAddress = _NetworkServiceCodec._fromNetAddress(
        response.remoteAddress);
    rawSocket._remotePort = _NetworkServiceCodec._portFromNetAddress(
        response.remoteAddress);

    _onAcceptSuccess(rawSocket);
  }

  _scheduleAccept() {
    if (_closed) {
      return;
    }
    assert(_scheduledAccept == null);
    _scheduledAccept = _accept();
  }

  _onAcceptSuccess(RawSocket rawSocket) {
    _controller.add(rawSocket);
    _scheduledAccept = null;
    _scheduleAccept();
  }

  _onAcceptFailure(NetworkError error) {
    _controller.addError(error);
    _scheduledAccept = null;
    _scheduleAccept();
  }

  StreamSubscription<RawSocket> listen(void onData(RawSocket event),
                                       {Function onError,
                                        void onDone(),
                                        bool cancelOnError}) {
    if (_controller != null) {
      throw new StateError("Stream was already listened to");
    }

    _controller = new StreamController(sync: true,
                                       onListen: _onSubscriptionStateChange,
                                       onCancel: _onSubscriptionStateChange,
                                       onPause: _onPauseStateChange,
                                       onResume: _onPauseStateChange);

    _scheduleAccept();

    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  int get port => _boundPort;

  InternetAddress get address => _boundAddress;

  Future close() async {
    _closed = true;
    _scheduledAccept = null;
    await _tcpBoundSocket.close(immediate: true);
    await _tcpServerSocket.close(immediate: true);
    if (_controller != null) {
      await _controller.close();
    }
    _controller = null;
    return this;
  }

  Future _destroy() async {
    return close();
  }

  _shutdown() {
    _closed = true;
    _scheduledAccept = null;
    _tcpServerSocket.close();
    _tcpBoundSocket.close();
    if (_referencePort != null) {
      _referencePort.close();
      _referencePort = null;
    }
    return this;
  }

  void _pause() {
    _paused = true;
    _socket.setListening(read: false, write: false);
  }

  void _resume() {
    _paused = false;
    if (_scheduledAccept == null) {
      // Re-start accept loop.
      _scheduleAccept();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _resume();
    } else {
      _shutdown();
    }
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }

  RawServerSocketReference get reference {
    if (_referencePort == null) {
      _referencePort = new ReceivePort();
      _referencePort.listen((sendPort) {
        sendPort.send(
          [_socket.address,
           _socket.port,
           _v6Only]);
      });
    }
    return new _MojoRawServerSocketReference(_referencePort.sendPort);
  }

  Map _toJSON(bool ref) => {};
}

class _MojoRawServerSocketReference implements RawServerSocketReference {
  final SendPort _sendPort;

  _MojoRawServerSocketReference(this._sendPort);

  Future<RawServerSocket> create() {
    var port = new ReceivePort();
    _sendPort.send(port.sendPort);
    return port.first.then((List args) {
      port.close();

      InternetAddress address = args[0];
      int tcpPort = args[1];
      bool v6Only = args[2];
      return
          RawServerSocket.bind(address, tcpPort, v6Only: v6Only, shared: true);
    });
  }

  int get hashCode => _sendPort.hashCode;

  bool operator==(Object other)
      => other is _MojoServerSocketReference && _sendPort == other._sendPort;
}

class _MojoServerSocket extends Stream<Socket>
                        implements ServerSocket {
  final _MojoRawServerSocket _socket;
  final int _port;
  final InternetAddress _address;
  static Future<_MojoServerSocket> bind(address,
                                        int port,
                                        int backlog,
                                        bool v6Only,
                                        bool shared) {
    return _MojoRawServerSocket.bind(address, port, backlog, v6Only, shared)
        .then((socket) => new _MojoServerSocket(socket));
  }

  _MojoServerSocket(rawSocket)
      : _socket = rawSocket,
        _port = rawSocket.port,
        _address = rawSocket.address;

  StreamSubscription<Socket> listen(void onData(Socket event),
                                    {Function onError,
                                     void onDone(),
                                     bool cancelOnError}) {
    return _socket.map((rawSocket) => new _MojoSocket(rawSocket)).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  Future close() => _socket.close().then((_) => this);

  ServerSocketReference get reference {
    return new _MojoServerSocketReference(_socket.reference);
  }

  Map _toJSON(bool ref) => _socket._toJSON(ref);

  void set _owner(owner) { _socket._owner = owner; }
}

class _MojoServerSocketReference implements ServerSocketReference {
  final RawServerSocketReference _rawReference;

  _MojoServerSocketReference(this._rawReference);

  Future<ServerSocket> create() {
    return _rawReference.create().then((raw) => new _MojoServerSocket(raw));
  }
}
