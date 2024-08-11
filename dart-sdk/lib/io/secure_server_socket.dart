// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// A server socket, providing a stream of high-level [Socket]s.
///
/// See [SecureSocket] for more info.
class SecureServerSocket extends Stream<SecureSocket>
    implements ServerSocketBase<SecureSocket> {
  final RawSecureServerSocket _socket;

  SecureServerSocket._(this._socket);

  /// Listens on a given address and port.
  ///
  /// When the returned future completes, the server socket is bound
  /// to the given [address] and [port] and has started listening on it.
  ///
  /// The [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [bind] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  ///
  /// If [port] has the value `0`, an ephemeral port will be chosen by
  /// the system. The actual port used can be retrieved using the
  /// [port] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of `0` (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// Incoming client connections are promoted to secure connections, using
  /// the server certificate and key set in [context].
  ///
  /// The [address] must be given as a numeric address, not a host name.
  ///
  /// To request or require that clients authenticate by providing an SSL (TLS)
  /// client certificate, set the optional parameter [requestClientCertificate]
  /// or [requireClientCertificate] to true.  Requiring a certificate implies
  /// requesting a certificate, so setting both is redundant.
  /// To check whether a client certificate was received, check
  /// [SecureSocket.peerCertificate] after connecting.  If no certificate
  /// was received, the result will be null.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with
  /// clients.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// The optional argument [shared] specifies whether additional
  /// [SecureServerSocket] objects can bind to the same combination of [address],
  /// [port] and [v6Only].  If [shared] is `true` and more [SecureServerSocket]s
  /// from this isolate or other isolates are bound to the same port, then the
  /// incoming connections will be distributed among all the bound
  /// `SecureServerSocket`s. Connections can be distributed over multiple
  /// isolates this way.
  static Future<SecureServerSocket> bind(
      address, int port, SecurityContext? context,
      {int backlog = 0,
      bool v6Only = false,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String>? supportedProtocols,
      bool shared = false}) {
    return RawSecureServerSocket.bind(address, port, context,
            backlog: backlog,
            v6Only: v6Only,
            requestClientCertificate: requestClientCertificate,
            requireClientCertificate: requireClientCertificate,
            supportedProtocols: supportedProtocols,
            shared: shared)
        .then((serverSocket) => new SecureServerSocket._(serverSocket));
  }

  StreamSubscription<SecureSocket> listen(void onData(SecureSocket socket)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _socket.map((rawSocket) => new SecureSocket._(rawSocket)).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  /// The port used by this socket.
  int get port => _socket.port;

  /// The address used by this socket.
  InternetAddress get address => _socket.address;

  /// Closes this socket.
  ///
  /// The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<SecureServerSocket> close() => _socket.close().then((_) => this);

  void set _owner(owner) {
    _socket._owner = owner;
  }
}

/// A server socket providing a stream of low-level [RawSecureSocket]s.
///
/// See [RawSecureSocket] for more info.
class RawSecureServerSocket extends Stream<RawSecureSocket> {
  final RawServerSocket _socket;
  late StreamController<RawSecureSocket> _controller;
  StreamSubscription<RawSocket>? _subscription;
  final SecurityContext? _context;
  final bool requestClientCertificate;
  final bool requireClientCertificate;
  final List<String>? supportedProtocols;
  bool _closed = false;

  RawSecureServerSocket._(
      this._socket,
      this._context,
      this.requestClientCertificate,
      this.requireClientCertificate,
      this.supportedProtocols) {
    _controller = new StreamController<RawSecureSocket>(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange,
        onCancel: _onSubscriptionStateChange);
  }

  /// Listens on a provided address and port.
  ///
  /// When the returned future completes, the server socket is bound
  /// to the given [address] and [port] and has started listening on it.
  ///
  /// The [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [bind] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  ///
  /// If [port] has the value `0` an ephemeral port will be chosen by
  /// the system. The actual port used can be retrieved using the
  /// [port] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of `0` (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// Incoming client connections are promoted to secure connections,
  /// using the server certificate and key set in [context].
  ///
  /// [address] must be given as a numeric address, not a host name.
  ///
  /// To request or require that clients authenticate by providing an SSL (TLS)
  /// client certificate, set the optional parameters requestClientCertificate or
  /// requireClientCertificate to true.  Require implies request, so one doesn't
  /// need to specify both.  To check whether a client certificate was received,
  /// check SecureSocket.peerCertificate after connecting.  If no certificate
  /// was received, the result will be null.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with
  /// clients.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [RawSecureSocket.selectedProtocol].
  ///
  /// The optional argument [shared] specifies whether additional
  /// [RawSecureServerSocket] objects can bind to the same combination of
  /// [address], [port] and [v6Only].  If [shared] is `true` and more
  /// [RawSecureServerSocket]s from this isolate or other isolates are bound to
  /// the port, then the incoming connections will be distributed among all the
  /// bound [RawSecureServerSocket]s. Connections can be distributed over
  /// multiple isolates this way.
  static Future<RawSecureServerSocket> bind(
      address, int port, SecurityContext? context,
      {int backlog = 0,
      bool v6Only = false,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String>? supportedProtocols,
      bool shared = false}) {
    return RawServerSocket.bind(address, port,
            backlog: backlog, v6Only: v6Only, shared: shared)
        .then((serverSocket) => new RawSecureServerSocket._(
            serverSocket,
            context,
            requestClientCertificate,
            requireClientCertificate,
            supportedProtocols));
  }

  StreamSubscription<RawSecureSocket> listen(void onData(RawSecureSocket s)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// The port used by this socket.
  int get port => _socket.port;

  /// The address used by this socket.
  InternetAddress get address => _socket.address;

  /// Closes this socket.
  ///
  /// The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<RawSecureServerSocket> close() {
    _closed = true;
    return _socket.close().then((_) => this);
  }

  void _onData(RawSocket connection) {
    var remotePort;
    try {
      remotePort = connection.remotePort;
    } catch (e) {
      // If connection is already closed, remotePort throws an exception.
      // Do nothing - connection is closed.
      return;
    }
    _RawSecureSocket.connect(connection.address, remotePort, true, connection,
            context: _context,
            requestClientCertificate: requestClientCertificate,
            requireClientCertificate: requireClientCertificate,
            supportedProtocols: supportedProtocols)
        .then((RawSecureSocket secureConnection) {
      if (_closed) {
        secureConnection.close();
      } else {
        _controller.add(secureConnection);
      }
    }).catchError((e, s) {
      if (!_closed) {
        _controller.addError(e, s);
      }
    });
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _subscription!.pause();
    } else {
      _subscription!.resume();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _subscription = _socket.listen(_onData,
          onError: _controller.addError, onDone: _controller.close);
    } else {
      close();
    }
  }

  void set _owner(owner) {
    (_socket as _RawSocketBase)._owner = owner;
  }
}
