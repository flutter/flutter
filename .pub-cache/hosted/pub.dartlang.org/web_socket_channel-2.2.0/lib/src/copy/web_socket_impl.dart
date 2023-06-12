// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The following code is copied from sdk/lib/io/websocket_impl.dart. The
// "dart:io" implementation isn't used directly to support non-"dart:io"
// applications.
//
// Because it's copied directly, only modifications necessary to support the
// desired public API and to remove "dart:io" dependencies have been made.
//
// This is up-to-date as of sdk revision
// 365f7b5a8b6ef900a5ee23913b7203569b81b175.

// ignore_for_file: unused_field, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../exception.dart';
import 'io_sink.dart';
import 'web_socket.dart';

const String webSocketGUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

final _random = Random();

// Matches _WebSocketOpcode.
class _WebSocketMessageType {
  static const int NONE = 0;
  static const int TEXT = 1;
  static const int BINARY = 2;
}

class _WebSocketOpcode {
  static const int CONTINUATION = 0;
  static const int TEXT = 1;
  static const int BINARY = 2;
  static const int RESERVED_3 = 3;
  static const int RESERVED_4 = 4;
  static const int RESERVED_5 = 5;
  static const int RESERVED_6 = 6;
  static const int RESERVED_7 = 7;
  static const int CLOSE = 8;
  static const int PING = 9;
  static const int PONG = 10;
  static const int RESERVED_B = 11;
  static const int RESERVED_C = 12;
  static const int RESERVED_D = 13;
  static const int RESERVED_E = 14;
  static const int RESERVED_F = 15;
}

/// The web socket protocol transformer handles the protocol byte stream
/// which is supplied through the `handleData`. As the protocol is processed,
/// it'll output frame data as either a List<int> or String.
///
/// Important information about usage: Be sure you use cancelOnError, so the
/// socket will be closed when the processor encounter an error. Not using it
/// will lead to undefined behaviour.
class _WebSocketProtocolTransformer extends StreamTransformerBase<List<int>,
        dynamic /*List<int>|_WebSocketPing|_WebSocketPong*/ >
    implements EventSink<List<int>> {
  static const int START = 0;
  static const int LEN_FIRST = 1;
  static const int LEN_REST = 2;
  static const int MASK = 3;
  static const int PAYLOAD = 4;
  static const int CLOSED = 5;
  static const int FAILURE = 6;
  static const int FIN = 0x80;
  static const int RSV1 = 0x40;
  static const int RSV2 = 0x20;
  static const int RSV3 = 0x10;
  static const int OPCODE = 0xF;

  int _state = START;
  bool _fin = false;
  int _opcode = -1;
  int _len = -1;
  bool _masked = false;
  int _remainingLenBytes = -1;
  int _remainingMaskingKeyBytes = 4;
  int _remainingPayloadBytes = -1;
  int _unmaskingIndex = 0;
  int _currentMessageType = _WebSocketMessageType.NONE;
  int closeCode = WebSocketStatus.NO_STATUS_RECEIVED;
  String closeReason = '';

  EventSink<dynamic /*List<int>|_WebSocketPing|_WebSocketPong*/ >? _eventSink;

  final bool _serverSide;
  final List<int> _maskingBytes = List.filled(4, 0);
  final BytesBuilder _payload = BytesBuilder(copy: false);

  _WebSocketProtocolTransformer([this._serverSide = false]);

  @override
  Stream<dynamic /*List<int>|_WebSocketPing|_WebSocketPong*/ > bind(
          Stream<List<int>> stream) =>
      Stream.eventTransformed(stream, (EventSink eventSink) {
        if (_eventSink != null) {
          throw StateError('WebSocket transformer already used.');
        }
        _eventSink = eventSink;
        return this;
      });

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _eventSink!.addError(error, stackTrace);
  }

  @override
  void close() {
    _eventSink!.close();
  }

  /// Process data received from the underlying communication channel.
  @override
  void add(List<int> bytes) {
    final buffer = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    var index = 0;
    final lastIndex = buffer.length;
    if (_state == CLOSED) {
      throw WebSocketChannelException('Data on closed connection');
    }
    if (_state == FAILURE) {
      throw WebSocketChannelException('Data on failed connection');
    }
    while ((index < lastIndex) && _state != CLOSED && _state != FAILURE) {
      final byte = buffer[index];
      if (_state <= LEN_REST) {
        if (_state == START) {
          _fin = (byte & FIN) != 0;

          if ((byte & (RSV2 | RSV3)) != 0) {
            // The RSV2, RSV3 bits must both be zero.
            throw WebSocketChannelException('Protocol error');
          }

          _opcode = byte & OPCODE;

          if (_opcode <= _WebSocketOpcode.BINARY) {
            if (_opcode == _WebSocketOpcode.CONTINUATION) {
              if (_currentMessageType == _WebSocketMessageType.NONE) {
                throw WebSocketChannelException('Protocol error');
              }
            } else {
              assert(_opcode == _WebSocketOpcode.TEXT ||
                  _opcode == _WebSocketOpcode.BINARY);
              if (_currentMessageType != _WebSocketMessageType.NONE) {
                throw WebSocketChannelException('Protocol error');
              }
              _currentMessageType = _opcode;
            }
          } else if (_opcode >= _WebSocketOpcode.CLOSE &&
              _opcode <= _WebSocketOpcode.PONG) {
            // Control frames cannot be fragmented.
            if (!_fin) throw WebSocketChannelException('Protocol error');
          } else {
            throw WebSocketChannelException('Protocol error');
          }
          _state = LEN_FIRST;
        } else if (_state == LEN_FIRST) {
          _masked = (byte & 0x80) != 0;
          _len = byte & 0x7F;
          if (_isControlFrame() && _len > 125) {
            throw WebSocketChannelException('Protocol error');
          }
          if (_len == 126) {
            _len = 0;
            _remainingLenBytes = 2;
            _state = LEN_REST;
          } else if (_len == 127) {
            _len = 0;
            _remainingLenBytes = 8;
            _state = LEN_REST;
          } else {
            assert(_len < 126);
            _lengthDone();
          }
        } else {
          assert(_state == LEN_REST);
          _len = _len << 8 | byte;
          _remainingLenBytes--;
          if (_remainingLenBytes == 0) {
            _lengthDone();
          }
        }
      } else {
        if (_state == MASK) {
          _maskingBytes[4 - _remainingMaskingKeyBytes--] = byte;
          if (_remainingMaskingKeyBytes == 0) {
            _maskDone();
          }
        } else {
          assert(_state == PAYLOAD);
          // The payload is not handled one byte at a time but in blocks.
          final payloadLength = min(lastIndex - index, _remainingPayloadBytes);
          _remainingPayloadBytes -= payloadLength;
          // Unmask payload if masked.
          if (_masked) {
            _unmask(index, payloadLength, buffer);
          }
          // Control frame and data frame share _payloads.
          _payload.add(Uint8List.view(buffer.buffer, index, payloadLength));
          index += payloadLength;
          if (_isControlFrame()) {
            if (_remainingPayloadBytes == 0) _controlFrameEnd();
          } else {
            if (_currentMessageType != _WebSocketMessageType.TEXT &&
                _currentMessageType != _WebSocketMessageType.BINARY) {
              throw WebSocketChannelException('Protocol error');
            }
            if (_remainingPayloadBytes == 0) _messageFrameEnd();
          }

          // Hack - as we always do index++ below.
          index--;
        }
      }

      // Move to the next byte.
      index++;
    }
  }

  void _unmask(int index, int length, Uint8List buffer) {
    const BLOCK_SIZE = 16;
    // Skip Int32x4-version if message is small.
    if (length >= BLOCK_SIZE) {
      // Start by aligning to 16 bytes.
      final startOffset = BLOCK_SIZE - (index & 15);
      final end = index + startOffset;
      for (var i = index; i < end; i++) {
        buffer[i] ^= _maskingBytes[_unmaskingIndex++ & 3];
      }
      index += startOffset;
      length -= startOffset;
      final blockCount = length ~/ BLOCK_SIZE;
      if (blockCount > 0) {
        // Create mask block.
        var mask = 0;
        for (var i = 3; i >= 0; i--) {
          mask = (mask << 8) | _maskingBytes[(_unmaskingIndex + i) & 3];
        }
        final blockMask = Int32x4(mask, mask, mask, mask);
        final blockBuffer = Int32x4List.view(buffer.buffer, index, blockCount);
        for (var i = 0; i < blockBuffer.length; i++) {
          blockBuffer[i] ^= blockMask;
        }
        final bytes = blockCount * BLOCK_SIZE;
        index += bytes;
        length -= bytes;
      }
    }
    // Handle end.
    final end = index + length;
    for (var i = index; i < end; i++) {
      buffer[i] ^= _maskingBytes[_unmaskingIndex++ & 3];
    }
  }

  void _lengthDone() {
    if (_masked) {
      if (!_serverSide) {
        throw WebSocketChannelException('Received masked frame from server');
      }
      _state = MASK;
    } else {
      if (_serverSide) {
        throw WebSocketChannelException('Received unmasked frame from client');
      }
      _remainingPayloadBytes = _len;
      _startPayload();
    }
  }

  void _maskDone() {
    _remainingPayloadBytes = _len;
    _startPayload();
  }

  void _startPayload() {
    // If there is no actual payload perform perform callbacks without
    // going through the PAYLOAD state.
    if (_remainingPayloadBytes == 0) {
      if (_isControlFrame()) {
        switch (_opcode) {
          case _WebSocketOpcode.CLOSE:
            _state = CLOSED;
            _eventSink!.close();
            break;
          case _WebSocketOpcode.PING:
            _eventSink!.add(_WebSocketPing());
            break;
          case _WebSocketOpcode.PONG:
            _eventSink!.add(_WebSocketPong());
            break;
        }
        _prepareForNextFrame();
      } else {
        _messageFrameEnd();
      }
    } else {
      _state = PAYLOAD;
    }
  }

  void _messageFrameEnd() {
    if (_fin) {
      final bytes = _payload.takeBytes();

      switch (_currentMessageType) {
        case _WebSocketMessageType.TEXT:
          _eventSink!.add(utf8.decode(bytes));
          break;
        case _WebSocketMessageType.BINARY:
          _eventSink!.add(bytes);
          break;
      }
      _currentMessageType = _WebSocketMessageType.NONE;
    }
    _prepareForNextFrame();
  }

  void _controlFrameEnd() {
    switch (_opcode) {
      case _WebSocketOpcode.CLOSE:
        closeCode = WebSocketStatus.NO_STATUS_RECEIVED;
        final payload = _payload.takeBytes();
        if (payload.isNotEmpty) {
          if (payload.length == 1) {
            throw WebSocketChannelException('Protocol error');
          }
          closeCode = payload[0] << 8 | payload[1];
          if (closeCode == WebSocketStatus.NO_STATUS_RECEIVED) {
            throw WebSocketChannelException('Protocol error');
          }
          if (payload.length > 2) {
            closeReason = utf8.decode(payload.sublist(2));
          }
        }
        _state = CLOSED;
        _eventSink!.close();
        break;

      case _WebSocketOpcode.PING:
        _eventSink!.add(_WebSocketPing(_payload.takeBytes()));
        break;

      case _WebSocketOpcode.PONG:
        _eventSink!.add(_WebSocketPong(_payload.takeBytes()));
        break;
    }
    _prepareForNextFrame();
  }

  bool _isControlFrame() =>
      _opcode == _WebSocketOpcode.CLOSE ||
      _opcode == _WebSocketOpcode.PING ||
      _opcode == _WebSocketOpcode.PONG;

  void _prepareForNextFrame() {
    if (_state != CLOSED && _state != FAILURE) _state = START;
    _fin = false;
    _opcode = -1;
    _len = -1;
    _remainingLenBytes = -1;
    _remainingMaskingKeyBytes = 4;
    _remainingPayloadBytes = -1;
    _unmaskingIndex = 0;
  }
}

class _WebSocketPing {
  final List<int>? payload;

  _WebSocketPing([this.payload]);
}

class _WebSocketPong {
  final List<int>? payload;

  _WebSocketPong([this.payload]);
}

// TODO(ajohnsen): Make this transformer reusable.
class _WebSocketOutgoingTransformer
    extends StreamTransformerBase<dynamic, List<int>> implements EventSink {
  final WebSocketImpl webSocket;
  EventSink<List<int>>? _eventSink;

  _WebSocketOutgoingTransformer(this.webSocket);

  @override
  Stream<List<int>> bind(Stream stream) =>
      Stream<List<int>>.eventTransformed(stream,
          (EventSink<List<int>> eventSink) {
        if (_eventSink != null) {
          throw StateError('WebSocket transformer already used');
        }
        _eventSink = eventSink;
        return this;
      });

  @override
  void add(message) {
    if (message is _WebSocketPong) {
      addFrame(_WebSocketOpcode.PONG, message.payload);
      return;
    }
    if (message is _WebSocketPing) {
      addFrame(_WebSocketOpcode.PING, message.payload);
      return;
    }
    List<int>? data;
    int opcode;
    if (message != null) {
      if (message is String) {
        opcode = _WebSocketOpcode.TEXT;
        data = utf8.encode(message);
      } else if (message is List<int>) {
        opcode = _WebSocketOpcode.BINARY;
        data = message;
      } else {
        throw ArgumentError(message);
      }
    } else {
      opcode = _WebSocketOpcode.TEXT;
    }
    addFrame(opcode, data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _eventSink!.addError(error, stackTrace);
  }

  @override
  void close() {
    final code = webSocket._outCloseCode;
    final reason = webSocket._outCloseReason;
    List<int>? data;
    if (code != null) {
      data = <int>[];
      data.add((code >> 8) & 0xFF);
      data.add(code & 0xFF);
      if (reason != null) {
        data.addAll(utf8.encode(reason));
      }
    }
    addFrame(_WebSocketOpcode.CLOSE, data);
    _eventSink!.close();
  }

  void addFrame(int opcode, List<int>? data) {
    createFrame(
            opcode,
            data,
            webSocket._serverSide,
            // Logic around _deflateHelper was removed here, since there will
            // never be a deflate helper for a cross-platform WebSocket client.
            false)
        .forEach((e) {
      _eventSink!.add(e);
    });
  }

  static Iterable<List<int>> createFrame(
      int opcode, List<int>? data, bool serverSide, bool compressed) {
    final mask = !serverSide; // Masking not implemented for server.
    final dataLength = data == null ? 0 : data.length;
    // Determine the header size.
    var headerSize = mask ? 6 : 2;
    if (dataLength > 65535) {
      headerSize += 8;
    } else if (dataLength > 125) {
      headerSize += 2;
    }
    final header = Uint8List(headerSize);
    var index = 0;

    // Set FIN and opcode.
    final hoc = _WebSocketProtocolTransformer.FIN |
        (compressed ? _WebSocketProtocolTransformer.RSV1 : 0) |
        (opcode & _WebSocketProtocolTransformer.OPCODE);

    header[index++] = hoc;
    // Determine size and position of length field.
    var lengthBytes = 1;
    if (dataLength > 65535) {
      header[index++] = 127;
      lengthBytes = 8;
    } else if (dataLength > 125) {
      header[index++] = 126;
      lengthBytes = 2;
    }
    // Write the length in network byte order into the header.
    for (var i = 0; i < lengthBytes; i++) {
      header[index++] = dataLength >> (((lengthBytes - 1) - i) * 8) & 0xFF;
    }
    if (mask) {
      header[1] |= 1 << 7;
      final maskBytes = [
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256)
      ];
      header.setRange(index, index + 4, maskBytes);
      index += 4;
      if (data != null) {
        Uint8List list;
        // If this is a text message just do the masking inside the
        // encoded data.
        if (opcode == _WebSocketOpcode.TEXT && data is Uint8List) {
          list = data;
        } else {
          if (data is Uint8List) {
            list = Uint8List.fromList(data);
          } else {
            list = Uint8List(data.length);
            for (var i = 0; i < data.length; i++) {
              if (data[i] < 0 || 255 < data[i]) {
                throw ArgumentError('List element is not a byte value '
                    '(value ${data[i]} at index $i)');
              }
              list[i] = data[i];
            }
          }
        }
        const BLOCK_SIZE = 16;
        final blockCount = list.length ~/ BLOCK_SIZE;
        if (blockCount > 0) {
          // Create mask block.
          var mask = 0;
          for (var i = 3; i >= 0; i--) {
            mask = (mask << 8) | maskBytes[i];
          }
          final blockMask = Int32x4(mask, mask, mask, mask);
          final blockBuffer = Int32x4List.view(list.buffer, 0, blockCount);
          for (var i = 0; i < blockBuffer.length; i++) {
            blockBuffer[i] ^= blockMask;
          }
        }
        // Handle end.
        for (var i = blockCount * BLOCK_SIZE; i < list.length; i++) {
          list[i] ^= maskBytes[i & 3];
        }
        data = list;
      }
    }
    assert(index == headerSize);
    if (data == null) {
      return [header];
    } else {
      return [header, data];
    }
  }
}

class _WebSocketConsumer implements StreamConsumer {
  final WebSocketImpl webSocket;
  final StreamSink<List<int>> sink;
  StreamController? _controller;

  // ignore: cancel_subscriptions
  StreamSubscription? _subscription;
  bool _issuedPause = false;
  bool _closed = false;
  final Completer _closeCompleter = Completer<WebSocketImpl>();
  Completer<WebSocketImpl>? _completer;

  _WebSocketConsumer(this.webSocket, this.sink);

  void _onListen() {
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  void _onPause() {
    if (_subscription != null) {
      _subscription!.pause();
    } else {
      _issuedPause = true;
    }
  }

  void _onResume() {
    if (_subscription != null) {
      _subscription!.resume();
    } else {
      _issuedPause = false;
    }
  }

  void _cancel() {
    if (_subscription != null) {
      final subscription = _subscription;
      _subscription = null;
      subscription!.cancel();
    }
  }

  void _ensureController() {
    if (_controller != null) return;
    _controller = StreamController(
        sync: true,
        onPause: _onPause,
        onResume: _onResume,
        onCancel: _onListen);
    final stream =
        _WebSocketOutgoingTransformer(webSocket).bind(_controller!.stream);
    sink.addStream(stream).then((_) {
      _done();
      _closeCompleter.complete(webSocket);
    }, onError: (error, StackTrace stackTrace) {
      _closed = true;
      _cancel();
      if (error is ArgumentError) {
        if (!_done(error, stackTrace)) {
          _closeCompleter.completeError(error, stackTrace);
        }
      } else {
        _done();
        _closeCompleter.complete(webSocket);
      }
    });
  }

  bool _done([Object? error, StackTrace? stackTrace]) {
    if (_completer == null) return false;
    if (error != null) {
      _completer!.completeError(error, stackTrace);
    } else {
      _completer!.complete(webSocket);
    }
    _completer = null;
    return true;
  }

  @override
  Future addStream(var stream) {
    if (_closed) {
      stream.listen(null).cancel();
      return Future.value(webSocket);
    }
    _ensureController();
    _completer = Completer();
    _subscription = stream.listen((data) {
      _controller!.add(data);
    }, onDone: _done, onError: _done, cancelOnError: true);
    if (_issuedPause) {
      _subscription!.pause();
      _issuedPause = false;
    }
    return _completer!.future;
  }

  @override
  Future close() {
    _ensureController();
    Future closeSocket() =>
        sink.close().catchError((_) {}).then((_) => webSocket);

    _controller!.close();
    return _closeCompleter.future.then((_) => closeSocket());
  }

  void add(data) {
    if (_closed) return;
    _ensureController();
    _controller!.add(data);
  }

  void closeSocket() {
    _closed = true;
    _cancel();
    close();
  }
}

class WebSocketImpl extends Stream with _ServiceObject implements StreamSink {
  // Use default Map so we keep order.
  static final Map<int, WebSocketImpl> _webSockets = <int, WebSocketImpl>{};
  static const int DEFAULT_WINDOW_BITS = 15;
  static const String PER_MESSAGE_DEFLATE = 'permessage-deflate';

  final String? protocol;

  late final StreamController _controller;

  // ignore: cancel_subscriptions
  StreamSubscription? _subscription;
  late final StreamSink _sink;

  final bool _serverSide;
  int _readyState = WebSocket.CONNECTING;
  bool _writeClosed = false;
  int? _closeCode;
  String? _closeReason;
  Duration? _pingInterval;
  Timer? _pingTimer;
  late final _WebSocketConsumer _consumer;

  int? _outCloseCode;
  String? _outCloseReason;
  Timer? _closeTimer;

  WebSocketImpl.fromSocket(
      Stream<List<int>> stream, StreamSink<List<int>> sink, this.protocol,
      [this._serverSide = false]) {
    _consumer = _WebSocketConsumer(this, sink);
    _sink = StreamSinkImpl(_consumer);
    _readyState = WebSocket.OPEN;

    final transformer = _WebSocketProtocolTransformer(_serverSide);
    _subscription = transformer.bind(stream).listen((data) {
      if (data is _WebSocketPing) {
        if (!_writeClosed) _consumer.add(_WebSocketPong(data.payload));
      } else if (data is _WebSocketPong) {
        // Simply set pingInterval, as it'll cancel any timers.
        pingInterval = _pingInterval;
      } else {
        _controller.add(data);
      }
    }, onError: (error, stackTrace) {
      if (_closeTimer != null) _closeTimer!.cancel();
      if (error is FormatException) {
        _close(WebSocketStatus.INVALID_FRAME_PAYLOAD_DATA);
      } else {
        _close(WebSocketStatus.PROTOCOL_ERROR);
      }
      // An error happened, set the close code set above.
      _closeCode = _outCloseCode;
      _closeReason = _outCloseReason;
      _controller.close();
    }, onDone: () {
      if (_closeTimer != null) _closeTimer!.cancel();
      if (_readyState == WebSocket.OPEN) {
        _readyState = WebSocket.CLOSING;
        if (!_isReservedStatusCode(transformer.closeCode)) {
          _close(transformer.closeCode, transformer.closeReason);
        } else {
          _close();
        }
        _readyState = WebSocket.CLOSED;
      }
      // Protocol close, use close code from transformer.
      _closeCode = transformer.closeCode;
      _closeReason = transformer.closeReason;
      _controller.close();
    }, cancelOnError: true);
    _subscription!.pause();
    _controller = StreamController(
        sync: true,
        onListen: () => _subscription!.resume(),
        onCancel: () {
          _subscription!.cancel();
          _subscription = null;
        },
        onPause: _subscription!.pause,
        onResume: _subscription!.resume);

    _webSockets[_serviceId] = this;
  }

  @override
  StreamSubscription listen(void Function(dynamic)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  Duration? get pingInterval => _pingInterval;

  set pingInterval(Duration? interval) {
    if (_writeClosed) return;
    if (_pingTimer != null) _pingTimer!.cancel();
    _pingInterval = interval;

    if (_pingInterval == null) return;

    _pingTimer = Timer(_pingInterval!, () {
      if (_writeClosed) return;
      _consumer.add(_WebSocketPing());
      _pingTimer = Timer(_pingInterval!, () {
        // No pong received.
        _close(WebSocketStatus.GOING_AWAY);
      });
    });
  }

  int get readyState => _readyState;

  String? get extensions => null;

  int? get closeCode => _closeCode;

  String? get closeReason => _closeReason;

  @override
  void add(data) {
    _sink.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream stream) => _sink.addStream(stream);

  @override
  Future get done => _sink.done;

  @override
  Future close([int? code, String? reason]) {
    if (_isReservedStatusCode(code)) {
      throw WebSocketChannelException('Reserved status code $code');
    }
    if (_outCloseCode == null) {
      _outCloseCode = code;
      _outCloseReason = reason;
    }
    if (!_controller.isClosed) {
      // If a close has not yet been received from the other end then
      //   1) make sure to listen on the stream so the close frame will be
      //      processed if received.
      //   2) set a timer terminate the connection if a close frame is
      //      not received.
      if (!_controller.hasListener && _subscription != null) {
        _controller.stream.drain().catchError((_) => {});
      }
      // When closing the web-socket, we no longer accept data.
      _closeTimer ??= Timer(const Duration(seconds: 5), () {
        // Reuse code and reason from the local close.
        _closeCode = _outCloseCode;
        _closeReason = _outCloseReason;
        if (_subscription != null) _subscription!.cancel();
        _controller.close();
        _webSockets.remove(_serviceId);
      });
    }
    return _sink.close();
  }

  void _close([int? code, String? reason]) {
    if (_writeClosed) return;
    if (_outCloseCode == null) {
      _outCloseCode = code;
      _outCloseReason = reason;
    }
    _writeClosed = true;
    _consumer.closeSocket();
    _webSockets.remove(_serviceId);
  }

  // The _toJSON, _serviceTypePath, and _serviceTypeName methods have been
  // deleted for web_socket_channel. The methods were unused in WebSocket code
  // and produced warnings.

  static bool _isReservedStatusCode(int? code) =>
      code != null &&
      (code < WebSocketStatus.NORMAL_CLOSURE ||
          code == WebSocketStatus.RESERVED_1004 ||
          code == WebSocketStatus.NO_STATUS_RECEIVED ||
          code == WebSocketStatus.ABNORMAL_CLOSURE ||
          (code > WebSocketStatus.INTERNAL_SERVER_ERROR &&
              code < WebSocketStatus.RESERVED_1015) ||
          (code >= WebSocketStatus.RESERVED_1015 && code < 3000));
}

// The following code is from sdk/lib/io/service_object.dart.

int _nextServiceId = 1;

// TODO(ajohnsen): Use other way of getting a uniq id.
abstract class _ServiceObject {
  int __serviceId = 0;

  int get _serviceId {
    if (__serviceId == 0) __serviceId = _nextServiceId++;
    return __serviceId;
  }

// The _toJSON, _servicePath, _serviceTypePath, _serviceTypeName, and
// _serviceType methods have been deleted for http_parser. The methods were
// unused in WebSocket code and produced warnings.
}
