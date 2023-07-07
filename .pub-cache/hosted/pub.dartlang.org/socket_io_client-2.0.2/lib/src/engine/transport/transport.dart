/// Copyright (C) 2019 Potix Corporation. All Rights Reserved
/// History: 2019-01-21 12:27
/// Author: jumperchen<jumperchen@potix.com>
import 'package:logging/logging.dart';
import 'package:socket_io_common/src/engine/parser/parser.dart';
import 'package:socket_io_common/src/util/event_emitter.dart';
import 'package:socket_io_client/src/engine/socket.dart';

abstract class Transport extends EventEmitter {
  static final Logger _logger = Logger('socket_io_client:transport.Transport');

  late String path;
  late String hostname;
  int? port;
  late bool secure;
  Map? query;
  String? timestampParam;
  bool? timestampRequests;
  String? readyState;
  bool? agent;
  Socket? socket;
  bool? enablesXDR;
  bool? writable;
  String? name;
  bool? supportsBinary;

  Transport(Map opts) {
    path = opts['path'];
    hostname = opts['hostname'];
    port = opts['port'];
    secure = opts['secure'];
    query = opts['query'];
    timestampParam = opts['timestampParam'];
    timestampRequests = opts['timestampRequests'];
    readyState = '';
    agent = opts['agent || false'];
    socket = opts['socket'];
    enablesXDR = opts['enablesXDR'];

    // SSL options for Node.js client
//    this.pfx = opts['x'];
//    this.key = opts['y'];
//    this.passphrase = opts['ssphrase'];
//    this.cert = opts['rt'];
//    this.ca = opts[''];
//    this.ciphers = opts['phers'];
//    this.rejectUnauthorized = opts['jectUnauthorized'];
//    this.forceNode = opts['rceNode'];
//
//    // other options for Node.js client
//    this.extraHeaders = opts['traHeaders'];
//    this.localAddress = opts['calAddress'];
  }

  ///
  /// Emits an error.
  ///
  /// @param {String} str
  /// @return {Transport} for chaining
  /// @api public
  void onError(msg, [desc]) {
    if (hasListeners('error')) {
      emit('error', {'msg': msg, 'desc': desc, 'type': 'TransportError'});
    } else {
      _logger.fine('ignored transport error $msg ($desc)');
    }
  }

  ///
  /// Opens the transport.
  ///
  /// @api public
  void open() {
    if ('closed' == readyState || '' == readyState) {
      readyState = 'opening';
      doOpen();
    }
  }

  ///
  /// Closes the transport.
  ///
  /// @api private
  void close() {
    if ('opening' == readyState || 'open' == readyState) {
      doClose();
      onClose();
    }
  }

  ///
  /// Sends multiple packets.
  ///
  /// @param {Array} packets
  /// @api private
  void send(List packets) {
    if ('open' == readyState) {
      write(packets);
    } else {
      throw StateError('Transport not open');
    }
  }

  ///
  /// Called upon open
  ///
  /// @api private
  void onOpen() {
    readyState = 'open';
    writable = true;
    emit('open');
  }

  ///
  /// Called with data.
  ///
  /// @param {String} data
  /// @api private
  void onData(data) {
    var packet = PacketParser.decodePacket(data, socket!.binaryType);
    onPacket(packet);
  }

  ///
  /// Called with a decoded packet.
  void onPacket(packet) {
    emit('packet', packet);
  }

  ///
  /// Called upon close.
  ///
  /// @api private
  void onClose() {
    readyState = 'closed';
    emit('close');
  }

  void write(List data);
  void doOpen();
  void doClose();
}
