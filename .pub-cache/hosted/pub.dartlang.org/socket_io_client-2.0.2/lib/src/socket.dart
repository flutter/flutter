import 'dart:typed_data';

///
/// socket.dart
///
/// Purpose:
///
/// Description:
///
/// History:
///   26/04/2017, Created by jumperchen
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'package:logging/logging.dart';
import 'package:socket_io_common/src/util/event_emitter.dart';
import 'package:socket_io_client/src/manager.dart';
import 'package:socket_io_client/src/on.dart' as util;
import 'package:socket_io_common/src/parser/parser.dart';

///
/// Internal events (blacklisted).
/// These events can't be emitted by the user.
///
/// @api private
///

const List EVENTS = [
  'connect',
  'connect_error',
  'connect_timeout',
  'connecting',
  'disconnect',
  'error',
  'reconnect',
  'reconnect_attempt',
  'reconnect_failed',
  'reconnect_error',
  'reconnecting',
  'ping',
  'pong'
];

final Logger _logger = Logger('socket_io_client:Socket');

///
/// `Socket` constructor.
///
/// @api public
class Socket extends EventEmitter {
  String nsp;
  Map? opts;

  Manager io;
  late Socket json;
  num ids = 0;
  Map acks = {};
  bool connected = false;
  bool disconnected = true;
  List sendBuffer = [];
  List receiveBuffer = [];
  String? query;
  dynamic? auth;
  List? subs;
  Map flags = {};
  String? id;

  Socket(this.io, this.nsp, this.opts) {
    json = this; // compat
    if (opts != null) {
      query = opts!['query'];
      auth = opts!['auth'];
    }
    if (io.autoConnect) open();
  }

  ///
  /// Subscribe to open, close and packet events
  ///
  /// @api private
  void subEvents() {
    if (subs?.isNotEmpty == true) return;

    var io = this.io;
    subs = [
      util.on(io, 'open', onopen),
      util.on(io, 'packet', onpacket),
      util.on(io, 'error', onerror),
      util.on(io, 'close', onclose)
    ];
  }

  /// Whether the Socket will try to reconnect when its Manager connects or reconnects
  bool get active {
    return subs != null;
  }

  ///
  /// "Opens" the socket.
  ///
  /// @api public
  Socket open() => connect();

  Socket connect() {
    if (connected) return this;
    subEvents();
    if (!io.reconnecting) {
      io.open(); // ensure open
    }
    if ('open' == io.readyState) onopen();
    return this;
  }

  ///
  /// Sends a `message` event.
  ///
  /// @return {Socket} self
  /// @api public
  Socket send(List args) {
    emit('message', args);
    return this;
  }

  ///
  /// Override `emit`.
  /// If the event is in `events`, it's emitted normally.
  ///
  /// @param {String} event name
  /// @return {Socket} self
  /// @api public
  @override
  void emit(String event, [data]) {
    emitWithAck(event, data);
  }

  ///
  /// Emits to this client.
  ///
  /// @return {Socket} self
  /// @api public
  void emitWithAck(String event, dynamic data,
      {Function? ack, bool binary = false}) {
    if (EVENTS.contains(event)) {
      super.emit(event, data);
    } else {
      var sendData = <dynamic>[event];
      if (data is ByteBuffer || data is List<int>) {
        sendData.add(data);
      } else if (data is Iterable) {
        sendData.addAll(data);
      } else if (data != null) {
        sendData.add(data);
      }

      var packet = {
        'type': EVENT,
        'data': sendData,
        'options': {'compress': flags.isNotEmpty == true && flags['compress']}
      };

      // event ack callback
      if (ack != null) {
        _logger.fine('emitting packet with ack id $ids');
        acks['$ids'] = ack;
        packet['id'] = '${ids++}';
      }
      final isTransportWritable = io.engine != null &&
          io.engine!.transport != null &&
          io.engine!.transport!.writable == true;

      final discardPacket =
          flags['volatile'] != null && (!isTransportWritable || !connected);
      if (discardPacket) {
        _logger
            .fine('discard packet as the transport is not currently writable');
      } else if (connected) {
        this.packet(packet);
      } else {
        sendBuffer.add(packet);
      }
      flags = {};
    }
  }

  ///
  /// Sends a packet.
  ///
  /// @param {Object} packet
  /// @api private
  void packet(Map packet) {
    packet['nsp'] = nsp;
    io.packet(packet);
  }

  ///
  /// Called upon engine `open`.
  ///
  /// @api private
  void onopen([_]) {
    _logger.fine('transport is open - connecting');

    // write connect packet if necessary
    // if ('/' != nsp) {
    // if (query?.isNotEmpty == true) {
    //   packet({'type': CONNECT, 'query': query});
    // } else {
    // packet({'type': CONNECT});
    // }
    // }

    if (auth != null) {
      if (auth is Function) {
        auth((data) {
          packet({'type': CONNECT, 'data': data});
        });
      } else {
        packet({'type': CONNECT, 'data': auth});
      }
    } else {
      packet({'type': CONNECT});
    }
  }

  /// Called upon engine or manager `error`
  void onerror(err) {
    if (!connected) {
      emit('connect_error', err);
    }
  }

  ///
  /// Called upon engine `close`.
  ///
  /// @param {String} reason
  /// @api private
  void onclose(reason) {
    _logger.fine('close ($reason)');
    emit('disconnecting', reason);
    connected = false;
    disconnected = true;
    id = null;
    emit('disconnect', reason);
  }

  ///
  /// Called with socket packet.
  ///
  /// @param {Object} packet
  /// @api private
  void onpacket(packet) {
    if (packet['nsp'] != nsp) return;

    switch (packet['type']) {
      case CONNECT:
        if (packet['data'] != null && packet['data']['sid'] != null) {
          final id = packet['data']['sid'];
          onconnect(id);
        } else {
          emit('connect_error',
              'It seems you are trying to reach a Socket.IO server in v2.x with a v3.x client, but they are not compatible (more information here: https://socket.io/docs/v3/migrating-from-2-x-to-3-0/)');
        }
        break;

      case EVENT:
        onevent(packet);
        break;

      case BINARY_EVENT:
        onevent(packet);
        break;

      case ACK:
        onack(packet);
        break;

      case BINARY_ACK:
        onack(packet);
        break;

      case DISCONNECT:
        ondisconnect();
        break;

      case CONNECT_ERROR:
        emit('error', packet['data']);
        break;
    }
  }

  ///
  /// Called upon a server event.
  ///
  /// @param {Object} packet
  /// @api private
  void onevent(Map packet) {
    List args = packet['data'] ?? [];
//    debug('emitting event %j', args);

    if (null != packet['id']) {
//      debug('attaching ack callback to event');
      args.add(ack(packet['id']));
    }

    // dart doesn't support "String... rest" syntax.
    if (connected == true) {
      if (args.length > 2) {
        Function.apply(super.emit, [args.first, args.sublist(1)]);
      } else {
        Function.apply(super.emit, args);
      }
    } else {
      receiveBuffer.add(args);
    }
  }

  ///
  /// Produces an ack callback to emit with an event.
  ///
  /// @api private
  Function ack(id) {
    var sent = false;
    return (dynamic data) {
      // prevent double callbacks
      if (sent) return;
      sent = true;
      _logger.fine('sending ack $data');

      var sendData = <dynamic>[];
      if (data is ByteBuffer || data is List<int>) {
        sendData.add(data);
      } else if (data is Iterable) {
        sendData.addAll(data);
      } else if (data != null) {
        sendData.add(data);
      }

      packet({'type': ACK, 'id': id, 'data': sendData});
    };
  }

  ///
  /// Called upon a server acknowlegement.
  ///
  /// @param {Object} packet
  /// @api private
  void onack(Map packet) {
    var ack = acks.remove('${packet['id']}');
    if (ack is Function) {
      _logger.fine('''calling ack ${packet['id']} with ${packet['data']}''');

      var args = packet['data'] as List;
      if (args.length > 1) {
        // Fix for #42 with nodejs server
        Function.apply(ack, [args]);
      } else {
        Function.apply(ack, args);
      }
    } else {
      _logger.fine('''bad ack ${packet['id']}''');
    }
  }

  ///
  /// Called upon server connect.
  ///
  /// @api private
  void onconnect(id) {
    this.id = id;
    connected = true;
    disconnected = false;
    emit('connect');
    emitBuffered();
  }

  ///
  /// Emit buffered events (received and emitted).
  ///
  /// @api private
  void emitBuffered() {
    var i;
    for (i = 0; i < receiveBuffer.length; i++) {
      List args = receiveBuffer[i];
      if (args.length > 2) {
        Function.apply(super.emit, [args.first, args.sublist(1)]);
      } else {
        Function.apply(super.emit, args);
      }
    }
    receiveBuffer = [];

    for (i = 0; i < sendBuffer.length; i++) {
      packet(sendBuffer[i]);
    }
    sendBuffer = [];
  }

  ///
  /// Called upon server disconnect.
  ///
  /// @api private
  void ondisconnect() {
    _logger.fine('server disconnect ($nsp)');
    destroy();
    onclose('io server disconnect');
  }

  ///
  /// Called upon forced client/server side disconnections,
  /// this method ensures the manager stops tracking us and
  /// that reconnections don't get triggered for this.
  ///
  /// @api private.

  void destroy() {
    final _subs = subs;
    if (_subs != null && _subs.isNotEmpty) {
      // clean subscriptions to avoid reconnections

      for (var i = 0; i < _subs.length; i++) {
        _subs[i].destroy();
      }
      subs = null;
    }

    io.destroy(this);
  }

  ///
  /// Disconnects the socket manually.
  ///
  /// @return {Socket} self
  /// @api public
  Socket close() => disconnect();

  Socket disconnect() {
    if (connected == true) {
      _logger.fine('performing disconnect ($nsp)');
      packet({'type': DISCONNECT});
    }

    // remove socket from pool
    destroy();

    if (connected == true) {
      // fire events
      onclose('io client disconnect');
    }
    return this;
  }

  /// Disposes the socket manually which will destroy, close, disconnect the socket connection
  /// and clear all the event listeners. Unlike [close] or [disconnect] which won't clear
  /// all the event listeners
  ///
  /// @since 0.9.11
  void dispose() {
    disconnect();
    clearListeners();
  }

  ///
  /// Sets the compress flag.
  ///
  /// @param {Boolean} if `true`, compresses the sending data
  /// @return {Socket} self
  /// @api public
  Socket compress(compress) {
    flags['compress'] = compress;
    return this;
  }
}
