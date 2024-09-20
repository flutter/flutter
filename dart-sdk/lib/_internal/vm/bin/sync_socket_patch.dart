// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@patch
class RawSynchronousSocket {
  @patch
  static RawSynchronousSocket connectSync(host, int port) {
    return _RawSynchronousSocket.connectSync(host, port);
  }
}

class _RawSynchronousSocket implements RawSynchronousSocket {
  final _NativeSynchronousSocket _socket;

  _RawSynchronousSocket(this._socket);

  static RawSynchronousSocket connectSync(host, int port) {
    _throwOnBadPort(port);
    return new _RawSynchronousSocket(
        _NativeSynchronousSocket.connectSync(host, port));
  }

  InternetAddress get address => _socket.address;
  int get port => _socket.port;
  InternetAddress get remoteAddress => _socket.remoteAddress;
  int get remotePort => _socket.remotePort;

  int available() => _socket.available;

  void closeSync() => _socket.closeSync();

  int readIntoSync(List<int> buffer, [int start = 0, int? end]) =>
      _socket.readIntoSync(buffer, start, end);

  List<int>? readSync(int bytes) => _socket.readSync(bytes);

  void shutdown(SocketDirection direction) => _socket.shutdown(direction);

  void writeFromSync(List<int> buffer, [int start = 0, int? end]) =>
      _socket.writeFromSync(buffer, start, end);
}

// The NativeFieldWrapperClass1 can not be used with a mixin, due to missing
// implicit constructor.
base class _NativeSynchronousSocketNativeWrapper
    extends NativeFieldWrapperClass1 {}

// The _NativeSynchronousSocket class encapsulates a synchronous OS socket.
base class _NativeSynchronousSocket
    extends _NativeSynchronousSocketNativeWrapper {
  // Socket close state.
  bool isClosed = false;
  bool isClosedRead = false;
  bool isClosedWrite = false;

  // Holds the address used to connect the socket.
  late InternetAddress localAddress;

  // Holds the port of the socket, 0 if not known.
  int localPort = 0;

  static _NativeSynchronousSocket connectSync(host, int port) {
    if (host == null) {
      throw new ArgumentError("Parameter host cannot be null");
    }
    late List<_InternetAddress> addresses;
    var error = null;
    if (host is _InternetAddress) {
      addresses = [host];
    } else {
      try {
        addresses = lookup(host);
      } catch (e) {
        error = e;
      }
      if (error != null || addresses == null || addresses.isEmpty) {
        throw createError(error, "Failed host lookup: '$host'");
      }
    }
    var it = addresses.iterator;
    _NativeSynchronousSocket connectNext() {
      if (!it.moveNext()) {
        // Could not connect. Throw the first connection error we encountered.
        assert(error != null);
        throw error;
      }
      var address = it.current;
      var socket = new _NativeSynchronousSocket();
      socket.localAddress = address;
      var result = socket._nativeCreateConnectSync(address._in_addr, port);
      if (result is OSError) {
        // Keep first error, if present.
        if (error == null) {
          error = createError(result, "Connection failed", address, port);
        }
        return connectNext();
      } else {
        // Query the local port, for error messages.
        try {
          socket.port;
        } catch (e) {
          if (error == null) {
            error = createError(e, "Connection failed", address, port);
          }
          return connectNext();
        }
      }
      return socket;
    }

    return connectNext();
  }

  InternetAddress get address => localAddress;
  int get available => _nativeAvailable();

  int get port {
    if (localPort != 0) {
      return localPort;
    }
    if (isClosed) {
      throw const SocketException.closed();
    }
    var result = _nativeGetPort();
    if (result is OSError) {
      throw result;
    }
    return localPort = result;
  }

  InternetAddress get remoteAddress {
    if (isClosed) {
      throw const SocketException.closed();
    }
    var result = _nativeGetRemotePeer();
    if (result is OSError) {
      throw result;
    }
    var addr = result[0];
    var type = InternetAddressType._from(addr[0]);
    if (type == InternetAddressType.unix) {
      return _InternetAddress.fromString(addr[1],
          type: InternetAddressType.unix);
    }
    return _InternetAddress(type, addr[1], null, addr[2]);
  }

  int get remotePort {
    if (isClosed) {
      throw const SocketException.closed();
    }
    var result = _nativeGetRemotePeer();
    if (result is OSError) {
      throw result;
    }
    return result[1];
  }

  void closeSync() {
    if (!isClosed) {
      _nativeCloseSync();
      isClosed = true;
    }
  }

  // Create the appropriate error/exception from different returned
  // error objects.
  static createError(error, String message,
      [InternetAddress? address, int? port]) {
    if (error is OSError) {
      return new SocketException(message,
          osError: error, address: address, port: port);
    } else {
      return new SocketException(message, address: address, port: port);
    }
  }

  static List<_InternetAddress> lookup(String host,
      {InternetAddressType type = InternetAddressType.any}) {
    var response = _nativeLookupRequest(host, type._value);
    if (response is OSError) {
      throw response;
    }
    return <_InternetAddress>[
      for (int i = 0; i < response.length; ++i)
        new _InternetAddress(InternetAddressType._from(response[i][0]),
            response[i][1], host, response[i][2]),
    ];
  }

  int readIntoSync(List<int> buffer, int start, int? end) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(buffer, "buffer");
    ArgumentError.checkNotNull(start, "start");
    _checkAvailable();
    if (isClosedRead) {
      throw new SocketException("Socket is closed for reading");
    }
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return 0;
    }
    var result = _nativeReadInto(buffer, start, end - start);
    if (result is OSError) {
      throw new SocketException("readIntoSync failed", osError: result);
    }
    return result;
  }

  List<int>? readSync(int len) {
    _checkAvailable();
    if (isClosedRead) {
      throw new SocketException("Socket is closed for reading");
    }

    if ((len != null) && (len < 0)) {
      throw new ArgumentError("Illegal length $len");
    }
    if (len == 0) {
      return null;
    }
    var result = _nativeRead(len);
    if (result is OSError) {
      throw result;
    }
    return result;
  }

  void shutdown(SocketDirection direction) {
    if (isClosed) {
      return;
    }
    switch (direction) {
      case SocketDirection.receive:
        shutdownRead();
        break;
      case SocketDirection.send:
        shutdownWrite();
        break;
      case SocketDirection.both:
        closeSync();
        break;
      default:
        throw new ArgumentError(direction);
    }
  }

  void shutdownRead() {
    if (isClosed || isClosedRead) {
      return;
    }
    if (isClosedWrite) {
      closeSync();
    } else {
      _nativeShutdownRead();
    }
    isClosedRead = true;
  }

  void shutdownWrite() {
    if (isClosed || isClosedWrite) {
      return;
    }
    if (isClosedRead) {
      closeSync();
    } else {
      _nativeShutdownWrite();
    }
    isClosedWrite = true;
  }

  void writeFromSync(List<int> buffer, int start, int? end) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(buffer, "buffer");
    ArgumentError.checkNotNull(start, "start");
    _checkAvailable();
    if (isClosedWrite) {
      throw new SocketException("Socket is closed for writing");
    }
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return;
    }
    _BufferAndStart bufferAndStart =
        _ensureFastAndSerializableByteData(buffer, start, end);
    var result = _nativeWrite(bufferAndStart.buffer, bufferAndStart.start,
        end - (start - bufferAndStart.start));
    if (result is OSError) {
      throw new SocketException("writeFromSync failed", osError: result);
    }
  }

  void _checkAvailable() {
    if (isClosed) {
      throw const SocketException.closed();
    }
  }

  // Native method declarations.
  @pragma("vm:external-name", "SynchronousSocket_LookupRequest")
  external static _nativeLookupRequest(host, int type);
  @pragma("vm:external-name", "SynchronousSocket_CreateConnectSync")
  external _nativeCreateConnectSync(host, int port);
  @pragma("vm:external-name", "SynchronousSocket_Available")
  external _nativeAvailable();
  @pragma("vm:external-name", "SynchronousSocket_CloseSync")
  external _nativeCloseSync();
  @pragma("vm:external-name", "SynchronousSocket_GetPort")
  external _nativeGetPort();
  @pragma("vm:external-name", "SynchronousSocket_GetRemotePeer")
  external _nativeGetRemotePeer();
  @pragma("vm:external-name", "SynchronousSocket_Read")
  external _nativeRead(int len);
  @pragma("vm:external-name", "SynchronousSocket_ReadList")
  external _nativeReadInto(List<int> buffer, int offset, int bytes);
  @pragma("vm:external-name", "SynchronousSocket_ShutdownRead")
  external _nativeShutdownRead();
  @pragma("vm:external-name", "SynchronousSocket_ShutdownWrite")
  external _nativeShutdownWrite();
  @pragma("vm:external-name", "SynchronousSocket_WriteList")
  external _nativeWrite(List<int> buffer, int offset, int bytes);
}
