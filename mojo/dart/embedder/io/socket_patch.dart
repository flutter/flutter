// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//
// Implementation of Socket and RawSocket for Mojo.
//

patch class Socket {
  /* patch */ static Future<Socket> connect(host, int port, {sourceAddress}) {
    return RawSocket.connect(host, port, sourceAddress: sourceAddress).then(
        (socket) => new _MojoSocket(socket));
  }
}

patch class RawSocket {
  /* patch */ static Future<RawSocket> connect(
      host, int port, {sourceAddress}) {
    return _MojoRawSocket.connect(host, port, sourceAddress);
  }
}

class _MojoRawSocket extends Stream<RawSocketEvent> implements RawSocket {
  StreamController<RawSocketEvent> _controller;
  final _tcpBoundSocket = new TcpBoundSocketProxy.unbound();
  final _tcpConnectedSocket = new TcpConnectedSocketProxy.unbound();
  // Constructing a new MojoDataPipe allocates two handles. All failure paths
  // must be sure that these handles are closed so we do not leak any handles.
  final _pipeOut = new MojoDataPipe();
  bool _outClosed = false;
  // Constructing a new MojoDataPipe allocates two handles. All failure paths
  // must be sure that these handles are closed so we do not leak any handles.
  final _pipeIn = new MojoDataPipe();
  bool _inClosed = false;
  bool _readEventsEnabled = true;
  bool _writeEventsEnabled = true;
  MojoEventStream _pipeOutEvents;
  MojoEventStream _pipeInEvents;
  InternetAddress _localAddress;
  int _localPort;
  InternetAddress _remoteAddress;
  int _remotePort;
  var _owner;

  bool _trace = false;
  int _traceId;

  _tracePrint(String message) {
    assert(_trace);
    print('${_traceId}: $message');
  }

  _traceProxies() {
    if (!_trace) {
      return;
    }
    _tracePrint('_tcpBoundSocket handle = ${_tcpBoundSocket.handle}');
    _tracePrint('_tcpConnectedSocket handle = ${_tcpConnectedSocket.handle}');
  }

  _tracePipeIn() {
    if (!_trace) {
      return;
    }
    if (_pipeInEvents != null) {
      _tracePrint('pipe in consumer handle = ${_pipeInEvents.handle}');
    } else {
      _tracePrint('pipe in consumer handle ${_pipeIn.consumer.handle}');
    }
    _tracePrint('pipe in producer handle = ${_pipeIn.producer.handle}');
  }

  _tracePipeOut() {
    if (!_trace) {
      return;
    }

    _tracePrint('pipe out consumer handle = ${_pipeOut.consumer.handle}');
    if (_pipeOutEvents != null) {
      _tracePrint('pipe out producer handle = ${_pipeOutEvents.handle}');
    } else {
      _tracePrint('pipe out producer handle = ${_pipeOut.producer.handle}');
    }
  }

  _tracePipes() {
    if (!_trace) {
      return;
    }
    _tracePipeIn();
    _tracePipeOut();
  }

  _traceLocalAddress() {
    if (!_trace) {
      return;
    }
    var a = (_localAddress == null) ?
        '<no local address>' : _localAddress.toString();
    var p = (_localPort == null) ?
        '<no port>' : _localPort.toString();
    _tracePrint('local: ${a}:${p}');
  }

  _traceRemoteAddress() {
    if (!_trace) {
      return;
    }
    var a = (_remoteAddress == null) ?
        '<no remote address>' : _remoteAddress.toString();
    var p = (_remotePort == null) ?
        '<no port>' : _remotePort.toString();
    _tracePrint('remote: ${a}:${p}');
  }

  _traceConnectedSocket() {
    if (!_trace) {
      return;
    }
    _tracePrint(_tcpConnectedSocket.toString());
  }

  _traceBoundSocket() {
    if (!_trace) {
      return;
    }
    _tracePrint(_tcpBoundSocket.toString());
  }

  static int _traceIdGenerator = 0;
  static _enableTrace(_MojoRawSocket rawSocket) {
    if (rawSocket._trace) {
      return;
    }
    rawSocket._trace = true;
    rawSocket._traceId = _traceIdGenerator++;
    rawSocket._tracePrint('Tracing enabled for ${rawSocket._traceId}');
    rawSocket._traceLocalAddress();
    rawSocket._traceRemoteAddress();
  }

  _MojoRawSocket() {
    _controller = new StreamController(sync: true,
                                       onListen: _onSubscriptionStateChange,
                                       onCancel: _onSubscriptionStateChange,
                                       onPause: _onPauseStateChange,
                                       onResume: _onPauseStateChange);
  }

  static Future<_MojoRawSocket> _connect(NetAddress source,
                                         NetAddress dest) async {
    var rawSocket = new _MojoRawSocket();
    var networkService = _getNetworkService().ptr;
    assert(networkService != null);
    var response =
        await networkService.createTcpBoundSocket(source,
                                                  rawSocket._tcpBoundSocket);
    if (!_NetworkService._okay(response.result)) {
      rawSocket.close();
      _NetworkService._throwOnError(response.result);
    }

    rawSocket._traceBoundSocket();

    rawSocket._localAddress =
        _NetworkServiceCodec._fromNetAddress(response.boundTo);
    rawSocket._localPort =
        _NetworkServiceCodec._portFromNetAddress(response.boundTo);

    rawSocket._setupIn();
    rawSocket._setupOut();

    // connect here.
    response =
        await rawSocket._tcpBoundSocket.ptr.connect(
            dest,
            rawSocket._pipeOut.consumer,
            rawSocket._pipeIn.producer,
            rawSocket._tcpConnectedSocket);

    rawSocket._remoteAddress = _NetworkServiceCodec._fromNetAddress(dest);
    rawSocket._remotePort = _NetworkServiceCodec._portFromNetAddress(dest);

    if (!_NetworkService._okay(response.result)) {
      rawSocket.close();
      _NetworkService._throwOnError(response.result);
    }

    rawSocket._traceConnectedSocket();

    return rawSocket;
  }

  static Future<RawSocket> connect(host, int port, sourceAddress) async {
    if (sourceAddress != null && sourceAddress is! _InternetAddress) {
      if (sourceAddress is String) {
        sourceAddress = new InternetAddress(sourceAddress);
      }
    }
    var sourceNetAddress;
    if (sourceAddress != null) {
      sourceNetAddress =
          _NetworkServiceCodec._fromInternetAddress(sourceAddress);
    } else {
      // TODO(johnmccutchan): Is it safe to assume IPv4?
      sourceNetAddress = _NetworkService._localhostIpv4();
    }
    if (host is _InternetAddress) {
      var destinationNetAddress =
          _NetworkServiceCodec._fromInternetAddress(host, port);
      return _connect(sourceNetAddress, destinationNetAddress);
    } else {
      // TODO(johnmccutchan): Use host resolver and try all results.
      // For now, connect to LOOPBACK_IPV4 with specified port.
      var destinationNetAddress = _NetworkService._localhostIpv4(port);
      return _connect(sourceNetAddress, destinationNetAddress);
    }
  }

  int available() {
    return _pipeIn.consumer.query();
  }

  Future<_MojoRawSocket> close() async {
    await _tcpBoundSocket.close();
    await _tcpConnectedSocket.close();
    _shutdownIn();
    _shutdownOut();
    return this;
  }

  void destroy() {
    _tcpConnectedSocket.close(immediate: true);
    _tcpBoundSocket.close(immediate: true);
    _shutdownIn(true);
    _shutdownOut(true);
  }

  bool setOption(SocketOption option, bool enabled) {
    // TODO(johnmccutchan): Implement.
    return false;
  }

  _onInputData(List<int> event) {
    if (_inClosed) {
      return;
    }
    var signalsWatched = new MojoHandleSignals(event[0]);
    var signalsReceived = new MojoHandleSignals(event[1]);
    if (_trace) {
      _tracePrint('<- IN: ${signalsReceived}');
    }
    if (signalsReceived.isReadable) {
      if (_trace) {
        _tracePrint('<- READ');
      }
      _controller.add(RawSocketEvent.READ);
    }
    if (signalsReceived.isPeerClosed) {
      if (_trace) {
        _tracePrint('<- READ_CLOSED');
      }
      _controller.add(RawSocketEvent.READ_CLOSED);
      // Once we are closed, stop reporting events.
      _inClosed = true;
      return;
    }
  }

  _onInputError(e, st) {
    _controller.addError(e);
    _onInputDone();
  }

  _onInputDone() {
    if (_inClosed) {
      return;
    }
    if (_trace) {
      _tracePrint('<- READ_CLOSED (done)');
    }
    _controller.add(RawSocketEvent.READ_CLOSED);
    _inClosed = true;
  }

  _onOutputData(List<int> event) {
    if (_outClosed) {
      return;
    }
    var signalsWatched = new MojoHandleSignals(event[0]);
    var signalsReceived = new MojoHandleSignals(event[1]);
    if (_trace) {
      _tracePrint('<- OUT: ${signalsReceived}');
    }
    if (signalsReceived.isPeerClosed) {
      if (_trace) {
        _tracePrint('<- CLOSED');
      }
      _controller.add(RawSocketEvent.CLOSED);
      // Once we are closed, stop reporting events.
      _outClosed = true;
      return;
    }
    if (signalsReceived.isWritable) {
      if (_trace) {
        _tracePrint('<- WRITE');
      }
      _controller.add(RawSocketEvent.WRITE);
    }
  }

  _onOutputError(e, st) {
    _controller.addError(e);
    _onOutputDone();
  }

  _onOutputDone() {
    if (_outClosed) {
      return;
    }
    if (_trace) {
      _tracePrint('<- CLOSED (done)');
    }
    _controller.add(RawSocketEvent.CLOSED);
    _outClosed = true;
  }

  _setupIn() {
    assert(_pipeInEvents == null);
    _pipeInEvents = new MojoEventStream(_pipeIn.consumer.handle,
                                        MojoHandleSignals.READABLE +
                                        MojoHandleSignals.PEER_CLOSED);
    _pipeInEvents.listen(_onInputData,
                         onError: _onInputError,
                         onDone: _onInputDone);
  }

  _setupOut() {
    assert(_pipeOutEvents == null);
    _pipeOutEvents = new MojoEventStream(_pipeOut.producer.handle,
                                         MojoHandleSignals.WRITABLE +
                                         MojoHandleSignals.PEER_CLOSED);
    _pipeOutEvents.listen(_onOutputData,
                          onError: _onOutputError,
                          onDone: _onOutputDone);
  }

  _shutdownIn([bool force = false]) {
    _inClosed = true;
    if (_trace) {
      _tracePrint('shutdown IN');
      _tracePipeIn();
    }
    if (_pipeInEvents != null) {
      if (force) {
        _pipeInEvents.close(immediate: true);
      } else {
        _pipeInEvents.close();
      }
    } else {
      _pipeIn.consumer.handle.close();
    }
    _pipeIn.producer.handle.close();
    _tracePipeIn();
  }

  _shutdownOut([bool force = false]) {
    _outClosed = true;
    if (_trace) {
      _tracePrint('shutdown OUT');
      _tracePipeOut();
    }
    if (_pipeOutEvents != null) {
      if (force) {
        _pipeOutEvents.close(immediate: true);
      } else {
        _pipeOutEvents.close();
      }
    } else {
      _pipeOut.producer.handle.close();
    }
    _pipeOut.consumer.handle.close();
    _tracePipeOut();
  }

  shutdown(SocketDirection direction) {
    if (direction == SocketDirection.RECEIVE) {
      _shutdownIn();
    } else if (direction == SocketDirection.SEND) {
      _shutdownOut();
    } else {
      _shutdownIn();
      _shutdownOut();
    }
  }

  List<int> read([int len]) {
    var bytesAvailable = available();
    if (bytesAvailable == 0) {
      return null;
    }
    if (len == null) {
      len = bytesAvailable;
    } else {
      len = bytesAvailable < len ? bytesAvailable : len;
    }
    var bytes = new Uint8List(len);
    var bytesRead = _pipeIn.consumer.read(bytes.buffer.asByteData(), len);
    assert(bytesRead == len);
    if (_trace) {
      _tracePrint('read $bytesRead bytes.');
    }
    if (!_controller.isPaused) {
      _resume();
    }
    return bytes;
  }

  int write(List<int> buffer, [int offset = 0, int count]) {
    if (buffer == null) {
      return 0;
    }
    if (count == null) {
      if (offset > buffer.length) {
        throw new RangeError.value(offset);
      }
      count = buffer.length - offset;
    }
    if (offset < 0) {
      throw new RangeError.value(offset);
    }
    if (count < 0) {
      throw new RangeError.value(count);
    }
    if ((offset + count) > buffer.length) {
      throw new RangeError.value(offset + count);
    }
    if (offset is! int || count is! int) {
      throw new ArgumentError("Invalid arguments to write on Socket");
    }
    if (count == 0) {
      return;
    }
    var bytes;
    if (buffer is Uint8List) {
      bytes = buffer;
    } else {
      bytes = new Uint8List.fromList(buffer);
    }
    var byteData = new ByteData.view(bytes.buffer, offset);
    var bytesWritten = _pipeOut.producer.write(byteData, count);
    if (_trace) {
      _tracePrint('wrote $bytesWritten bytes.');
    }
    if (!_controller.isPaused) {
      _resume();
    }
    return bytesWritten;
  }

  InternetAddress get address => _localAddress;
  int get port => _localPort;
  InternetAddress get remoteAddress => _remoteAddress;
  int get remotePort => _remotePort;

  bool get readEventsEnabled => _readEventsEnabled;
  void set readEventsEnabled(bool value) {
    if (value != _readEventsEnabled) {
      _readEventsEnabled = value;
      if (_trace) {
        _tracePrint('read events enabled: $_readEventsEnabled');
      }
      if (!_controller.isPaused) {
        _resume();
      }
    }
  }

  bool get writeEventsEnabled => _writeEventsEnabled;
  void set writeEventsEnabled(bool value) {
    if (value != _writeEventsEnabled) {
      _writeEventsEnabled = value;
      if (_trace) {
        _tracePrint('write events enabled: $_writeEventsEnabled');
      }
      if (!_controller.isPaused) {
        _resume();
      }
    }
  }

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event),
                                            {Function onError,
                                             void onDone(),
                                             bool cancelOnError}) {
    return _controller.stream.listen(onData, onError: onError, onDone: onDone,
                                     cancelOnError: cancelOnError);
  }


  static _enableReadEvents(MojoEventStream stream) {
    if (stream == null) {
      return;
    }
    stream.enableSignals(MojoHandleSignals.PEER_CLOSED +
                         MojoHandleSignals.READABLE);
  }

  static _enableWriteEvents(MojoEventStream stream) {
    if (stream == null) {
      return;
    }
    stream.enableSignals(MojoHandleSignals.PEER_CLOSED +
                         MojoHandleSignals.WRITABLE);
  }

  static _disableEvents(MojoEventStream stream) {
    if (stream == null) {
      return;
    }
    stream.enableSignals(MojoHandleSignals.PEER_CLOSED);
  }

  _pause() {
    _disableEvents(_pipeInEvents);
    _disableEvents(_pipeOutEvents);
  }

  void _resume() {
    if (_pipeInEvents != null) {
      if (_readEventsEnabled) {
        _enableReadEvents(_pipeInEvents);
      } else {
        _disableEvents(_pipeInEvents);
      }
    }

    if (_pipeOutEvents != null) {
      if (_writeEventsEnabled) {
        _enableWriteEvents(_pipeOutEvents);
      } else {
        _disableEvents(_pipeOutEvents);
      }
    }
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _resume();
    } else {
      _socket.close();
    }
  }
}

class _SocketStreamConsumer extends StreamConsumer<List<int>> {
  StreamSubscription subscription;
  final _MojoSocket socket;
  int offset;
  List<int> buffer;
  bool paused = false;
  Completer streamCompleter;

  _SocketStreamConsumer(this.socket);

  Future<Socket> addStream(Stream<List<int>> stream) {
    socket._ensureRawSocketSubscription();
    streamCompleter = new Completer<Socket>();
    if (socket._raw != null) {
      subscription = stream.listen(
          (data) {
            assert(!paused);
            assert(buffer == null);
            buffer = data;
            offset = 0;
            try {
              write();
            } catch (e) {
              socket.destroy();
              stop();
              done(e);
            }
          },
          onError: (error, [stackTrace]) {
            socket.destroy();
            done(error, stackTrace);
          },
          onDone: () {
            done();
          },
          cancelOnError: true);
    }
    return streamCompleter.future;
  }

  Future<Socket> close() {
    socket._consumerDone();
    return new Future.value(socket);
  }

  void write() {
    if (subscription == null) {
      return;
    }
    if (buffer == null) {
      return;
    }
    assert(buffer != null);
    // Write as much as possible.
    offset += socket._write(buffer, offset, buffer.length - offset);
    if (offset < buffer.length) {
      if (!paused) {
        paused = true;
        subscription.pause();
      }
      socket._enableWriteEvent();
    } else {
      buffer = null;
      if (paused) {
        paused = false;
        subscription.resume();
      }
    }
  }

  void done([error, stackTrace]) {
    if (streamCompleter != null) {
      if (error != null) {
        streamCompleter.completeError(error, stackTrace);
      } else {
        streamCompleter.complete(socket);
      }
      streamCompleter = null;
    }
  }

  void stop() {
    if (subscription == null) {
      return;
    }
    subscription.cancel();
    subscription = null;
    paused = false;
    socket._disableWriteEvent();
  }
}

class _MojoSocket extends Stream<List<int>> implements Socket {
  _MojoRawSocket _raw;
  final int _port;
  final InternetAddress _address;
  final int _remotePort;
  final InternetAddress _remoteAddress;
  bool _closed = false;
  StreamController _controller;
  bool _controllerClosed = false;
  _SocketStreamConsumer _consumer;
  IOSink _sink;
  var _subscription;
  var _detachReady;


  _MojoSocket(rawSocket)
      : _raw = rawSocket,
        _port = rawSocket.port,
        _address = rawSocket.address,
        _remotePort = rawSocket.remotePort,
        _remoteAddress = rawSocket.remoteAddress {
    _controller = new StreamController<List<int>>(sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _consumer = new _SocketStreamConsumer(this);
    _sink = new IOSink(_consumer);

    // Disable read events until there is a subscription.
    _raw.readEventsEnabled = false;

    // Disable write events until the consumer needs it for pending writes.
    _raw.writeEventsEnabled = false;
  }

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {Function onError,
                                        void onDone(),
                                        bool cancelOnError}) {
    return _controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  Encoding get encoding => _sink.encoding;

  void set encoding(Encoding value) {
    _sink.encoding = value;
  }

  void write(Object obj) => _sink.write(obj);

  void writeln([Object obj = ""]) => _sink.writeln(obj);

  void writeCharCode(int charCode) => _sink.writeCharCode(charCode);

  void writeAll(Iterable objects, [sep = ""]) => _sink.writeAll(objects, sep);

  void add(List<int> bytes) => _sink.add(bytes);

  Future<Socket> addStream(Stream<List<int>> stream) {
    return _sink.addStream(stream);
  }

  Future<Socket> flush() => _sink.flush();

  Future<Socket> close() => _sink.close();

  Future<Socket> get done => _sink.done;

  void destroy() {
    // Destroy can always be called to get rid of a socket.
    if (_raw == null) {
      return;
    }
    _raw._shutdownIn(true);
    _raw._shutdownOut(true);
    _closeRawSocket(true);
    _consumer.stop();
    _controllerClosed = true;
    _controller.close();
  }

  bool setOption(SocketOption option, bool enabled) {
    if (_raw == null) {
      return false;
    }
    return _raw.setOption(option, enabled);
  }

  int get port => _port;
  InternetAddress get address => _address;
  int get remotePort => _remotePort;
  InternetAddress get remoteAddress => _remoteAddress;

  // Ensure a subscription on the raw socket. Both the stream and the
  // consumer needs a subscription as they share the error and done
  // events from the raw socket.
  void _ensureRawSocketSubscription() {
    if (_subscription == null && _raw != null) {
      _subscription = _raw.listen(_onData,
                                  onError: _onError,
                                  onDone: _onDone,
                                  cancelOnError: true);
    }
  }

  _closeRawSocket(bool force) {
    var tmp = _raw;
    _raw = null;
    _closed = true;
    if (force) {
      tmp.destroy();
    } else {
      tmp.close();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _ensureRawSocketSubscription();
      // Enable read events for providing data to subscription.
      if (_raw != null) {
        _raw.readEventsEnabled = true;
      }
    } else {
      _controllerClosed = true;
      if (_raw != null) {
        _raw.shutdown(SocketDirection.RECEIVE);
      }
    }
  }

  void _onPauseStateChange() {
    if (_raw != null) {
      _raw.readEventsEnabled = !_controller.isPaused;
    }
  }

  void _onData(event) {
    switch (event) {
      case RawSocketEvent.READ:
        if (_raw != null) {
          var buffer = _raw.read();
          if (buffer != null) {
            _controller.add(buffer);
          }
        }
        break;
      case RawSocketEvent.WRITE:
        _consumer.write();
        break;
      case RawSocketEvent.READ_CLOSED:
        _controllerClosed = true;
        _controller.close();
        break;
    }
  }

  void _onDone() {
    if (!_controllerClosed) {
      _controllerClosed = true;
      _controller.close();
    }
    _consumer.done();
  }

  void _onError(error, stackTrace) {
    if (!_controllerClosed) {
      _controllerClosed = true;
      _controller.addError(error, stackTrace);
      _controller.close();
    }
    _consumer.done(error, stackTrace);
  }

  int _write(List<int> data, int offset, int length) =>
      _raw.write(data, offset, length);

  void _enableWriteEvent() {
    _raw.writeEventsEnabled = true;
  }

  void _disableWriteEvent() {
    if (_raw != null) {
      _raw.writeEventsEnabled = false;
    }
  }

  void _consumerDone() {
    if (_detachReady != null) {
      _detachReady.complete(null);
    } else {
      if (_raw != null) {
        _raw.shutdown(SocketDirection.SEND);
        _disableWriteEvent();
      }
    }
  }

  Map _toJSON(bool ref) => _raw._toJSON(ref);
  void set _owner(owner) { _raw._owner = owner; }
}