// Copyright (C) 2017 Potix Corporation. All Rights Reserved
// History: 26/04/2017
// Author: jumperchen<jumperchen@potix.com>

import 'dart:async';
import 'dart:html';
import 'package:logging/logging.dart';
import 'package:socket_io_client/src/engine/transport/transport.dart';
import 'package:socket_io_common/src/engine/parser/parser.dart';
import 'package:socket_io_client/src/engine/parseqs.dart';

class WebSocketTransport extends Transport {
  static final Logger _logger =
      Logger('socket_io_client:transport.WebSocketTransport');

  @override
  String? name = 'websocket';
  late var protocols;

  @override
  bool? supportsBinary;
  late Map perMessageDeflate;
  WebSocket? ws;

  WebSocketTransport(Map opts) : super(opts) {
    var forceBase64 = opts['forceBase64'];
    supportsBinary = !forceBase64;
    perMessageDeflate = opts['perMessageDeflate'];
    protocols = opts['protocols'];
  }

  @override
  void doOpen() {
    var uri = this.uri();
    var protocols = this.protocols;

    try {
      ws = WebSocket(uri, protocols);
    } catch (err) {
      return emit('error', err);
    }

    if (ws!.binaryType == null) {
      supportsBinary = false;
    }

    ws!.binaryType = 'arraybuffer';

    addEventListeners();
  }

  /// Adds event listeners to the socket
  ///
  /// @api private
  void addEventListeners() {
    ws!
      ..onOpen.listen((_) => onOpen())
      ..onClose.listen((_) => onClose())
      ..onMessage.listen((MessageEvent evt) => onData(evt.data))
      ..onError.listen((e) {
        onError('websocket error');
      });
  }

  /// Writes data to socket.
  ///
  /// @param {Array} array of packets.
  /// @api private
  @override
  void write(List packets) {
    writable = false;

    var done = () {
      emit('flush');

      // fake drain
      // defer to next tick to allow Socket to clear writeBuffer
      Timer.run(() {
        writable = true;
        emit('drain');
      });
    };

    var total = packets.length;
    // encodePacket efficient as it uses WS framing
    // no need for encodePayload
    packets.forEach((packet) {
      PacketParser.encodePacket(packet,
          supportsBinary: supportsBinary, fromClient: true, callback: (data) {
        // Sometimes the websocket has already been closed but the browser didn't
        // have a chance of informing us about it yet, in that case send will
        // throw an error
        try {
          // TypeError is thrown when passing the second argument on Safari
          ws!.send(data);
        } catch (e) {
          _logger.fine('websocket closed before onclose event');
        }

        if (--total == 0) done();
      });
    });
  }

  /// Closes socket.
  ///
  /// @api private
  @override
  void doClose() {
    ws?.close();
  }

  /// Generates uri for connection.
  ///
  /// @api private
  String uri() {
    var query = this.query ?? {};
    var schema = secure ? 'wss' : 'ws';
    var port = '';

    // avoid port if default for schema
    if (this.port != null &&
        (('wss' == schema && this.port != 443) ||
            ('ws' == schema && this.port != 80))) {
      port = ':${this.port}';
    }

    // append timestamp to URI
    if (timestampRequests == true) {
      query[timestampParam] =
          DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    }

    // communicate binary support capabilities
    if (supportsBinary == false) {
      query['b64'] = 1;
    }

    var queryString = encode(query);

    // prepend ? to query
    if (queryString.isNotEmpty) {
      queryString = '?$queryString';
    }

    var ipv6 = hostname.contains(':');
    return schema +
        '://' +
        (ipv6 ? '[' + hostname + ']' : hostname) +
        port +
        path +
        queryString;
  }
/////
///// Feature detection for WebSocket.
/////
///// @return {Boolean} whether this transport is available.
///// @api public
//////
//  check() {
//    return !!WebSocket && !('__initialize' in WebSocket && this.name === WS.prototype.name);
//  }
}
