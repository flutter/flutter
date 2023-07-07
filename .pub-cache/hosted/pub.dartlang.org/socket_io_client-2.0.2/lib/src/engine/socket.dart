// Copyright (C) 2017 Potix Corporation. All Rights Reserved
// History: 26/04/2017
// Author: jumperchen<jumperchen@potix.com>

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:socket_io_common/src/util/event_emitter.dart';
import 'package:socket_io_client/src/engine/parseqs.dart';
import 'package:socket_io_common/src/engine/parser/parser.dart' as parser;
import 'package:socket_io_client/src/engine/transport/polling_transport.dart';
import './transport/transport.dart';

// ignore: uri_does_not_exist
import './transport/transports_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) './transport/transports.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) './transport/io_transports.dart';

final Logger _logger = Logger('socket_io_client:engine.Socket');

///
/// Socket constructor.
///
/// @param {String|Object} uri or options
/// @param {Object} options
/// @api public
///
class Socket extends EventEmitter {
  late Map opts;
  late Uri uri;
  late bool secure;
  bool? agent;
  late String hostname;
  int? port;
  late Map query;
  bool? upgrade;
  late String path;
  bool? forceJSONP;
  bool? jsonp;
  bool? forceBase64;
  bool? enablesXDR;
  String? timestampParam;
  var timestampRequests;
  late List<String> transports;
  late Map transportOptions;
  String readyState = '';
  List writeBuffer = [];
  int prevBufferLen = 0;
  int? policyPort;
  bool? rememberUpgrade;
  var binaryType;
  bool? onlyBinaryUpgrades;
  late Map perMessageDeflate;
  String? id;
  late List upgrades;
  late int pingInterval;
  late int pingTimeout;
  Timer? pingIntervalTimer;
  Timer? pingTimeoutTimer;
  int? requestTimeout;
  Transport? transport;
  bool? supportsBinary;
  bool? upgrading;
  Map? extraHeaders;

  Socket(String uri, Map? opts) {
    opts = opts ?? <dynamic, dynamic>{};

    if (uri.isNotEmpty) {
      this.uri = Uri.parse(uri);
      opts['hostname'] = this.uri.host;
      opts['secure'] = this.uri.scheme == 'https' || this.uri.scheme == 'wss';
      opts['port'] = this.uri.port;
      if (this.uri.hasQuery) opts['query'] = this.uri.query;
    } else if (opts.containsKey('host')) {
      opts['hostname'] = Uri.parse(opts['host']).host;
    }

    secure = opts['secure'] /*?? (window.location.protocol == 'https:')*/;

    if (opts['hostname'] != null && !opts.containsKey('port')) {
      // if no port is specified manually, use the protocol default
      opts['port'] = secure ? '443' : '80';
    }

    agent = opts['agent'] ?? false;
    hostname =
        opts['hostname'] /*?? (window.location.hostname ?? 'localhost')*/;
    port = opts[
            'port'] /*??
        (window.location.port.isNotEmpty
            ? int.parse(window.location.port)
            : (this.secure ? 443 : 80))*/
        ;
    var query = opts['query'] ?? {};
    if (query is String) {
      this.query = decode(query);
    } else if (query is Map) {
      this.query = query;
    }

    upgrade = opts['upgrade'] != false;
    path = (opts['path'] ?? '/engine.io')
            .toString()
            .replaceFirst(RegExp(r'\/$'), '') +
        '/';
    forceJSONP = opts['forceJSONP'] == true;
    jsonp = opts['jsonp'] != false;
    forceBase64 = opts['forceBase64'] == true;
    enablesXDR = opts['enablesXDR'] == true;
    timestampParam = opts['timestampParam'] ?? 't';
    timestampRequests = opts['timestampRequests'];
    transports = opts['transports'] ?? ['polling', 'websocket'];
    transportOptions = opts['transportOptions'] ?? {};
    policyPort = opts['policyPort'] ?? 843;
    rememberUpgrade = opts['rememberUpgrade'] ?? false;
    binaryType = null;
    onlyBinaryUpgrades = opts['onlyBinaryUpgrades'];

    if (!opts.containsKey('perMessageDeflate') ||
        opts['perMessageDeflate'] == true) {
      perMessageDeflate =
          opts['perMessageDeflate'] is Map ? opts['perMessageDeflate'] : {};
      if (!perMessageDeflate.containsKey('threshold')) {
        perMessageDeflate['threshold'] = 1024;
      }
    }

    extraHeaders = opts['extraHeaders'] ?? <String, dynamic>{};
    // SSL options for Node.js client
//  this.pfx = opts.pfx || null;
//  this.key = opts.key || null;
//  this.passphrase = opts.passphrase || null;
//  this.cert = opts.cert || null;
//  this.ca = opts.ca || null;
//  this.ciphers = opts.ciphers || null;
//  this.rejectUnauthorized = opts.rejectUnauthorized === undefined ? true : opts.rejectUnauthorized;
//  this.forceNode = !!opts.forceNode;

    // other options for Node.js client
//  var freeGlobal = typeof global === 'object' && global;
//  if (freeGlobal.global === freeGlobal) {
//  if (opts.extraHeaders && Object.keys(opts.extraHeaders).length > 0) {
//  this.extraHeaders = opts.extraHeaders;
//  }
//
//  if (opts.localAddress) {
//  this.localAddress = opts.localAddress;
//  }
//  }

    // set on handshake
//  this.id = null;
//  this.upgrades = null;
//  this.pingInterval = null;
//  this.pingTimeout = null;

    // set on heartbeat
//  this.pingIntervalTimer = null;
//  this.pingTimeoutTimer = null;

    open();
  }

  static bool priorWebsocketSuccess = false;

  ///
  /// Protocol version.
  ///
  /// @api public
  static int protocol = parser.protocol; // this is an int

//
//  Socket.Socket = Socket;
//  Socket.Transport = require('./transport');
//  Socket.transports = require('./transports/index');
//  Socket.parser = require('engine.io-parser');

  ///
  /// Creates transport of the given type.
  ///
  /// @param {String} transport name
  /// @return {Transport}
  /// @api private
  Transport createTransport(name, [options]) {
    _logger.fine('creating transport "$name"');
    var query = Map.from(this.query);

    // append engine.io protocol identifier
    query['EIO'] = parser.protocol;

    // transport name
    query['transport'] = name;

    // per-transport options
    var options = transportOptions[name] ?? {};

    // session id if we already have one
    if (id != null) query['sid'] = id;

    var transport = Transports.newInstance(name, {
      'query': query,
      'socket': this,
      'agent': options['agent'] ?? agent,
      'hostname': options['hostname'] ?? hostname,
      'port': options['port'] ?? port,
      'secure': options['secure'] ?? secure,
      'path': options['path'] ?? path,
      'forceJSONP': options['forceJSONP'] ?? forceJSONP,
      'jsonp': options['jsonp'] ?? jsonp,
      'forceBase64': options['forceBase64'] ?? forceBase64,
      'enablesXDR': options['enablesXDR'] ?? enablesXDR,
      'timestampRequests': options['timestampRequests'] ?? timestampRequests,
      'timestampParam': options['timestampParam'] ?? timestampParam,
      'policyPort': options['policyPort'] ?? policyPort,
//  'pfx: options.pfx || this.pfx,
//  'key: options.key || this.key,
//  'passphrase: options.passphrase || this.passphrase,
//  'cert: options.cert || this.cert,
//  'ca: options.ca || this.ca,
//  'ciphers: options.ciphers || this.ciphers,
//  'rejectUnauthorized: options.rejectUnauthorized || this.rejectUnauthorized,
      'perMessageDeflate': options['perMessageDeflate'] ?? perMessageDeflate,
      'extraHeaders': options['extraHeaders'] ?? extraHeaders,
//  'forceNode: options.forceNode || this.forceNode,
//  'localAddress: options.localAddress || this.localAddress,
      'requestTimeout': options['requestTimeout'] ?? requestTimeout,
      'protocols': options['protocols']
    });

    return transport;
  }

  ///
  /// Initializes transport to use and starts probe.
  ///
  /// @api private
  void open() {
    var transport;
    if (rememberUpgrade != null &&
        priorWebsocketSuccess &&
        transports.contains('websocket')) {
      transport = 'websocket';
    } else if (transports.isEmpty) {
      // Emit error on next tick so it can be listened to
      Timer.run(() => emit('error', 'No transports available'));
      return;
    } else {
      transport = transports[0];
    }
    readyState = 'opening';

    // Retry with the next transport if the transport is disabled (jsonp: false)
    try {
      transport = createTransport(transport);
    } catch (e) {
      transports.removeAt(0);
      open();
      return;
    }

    transport.open();
    setTransport(transport);
  }

  ///
  /// Sets the current transport. Disables the existing one (if any).
  ///
  /// @api private
  void setTransport(transport) {
    _logger.fine('setting transport ${transport?.name}');

    if (this.transport != null) {
      _logger.fine('clearing existing transport ${this.transport!.name}');
      this.transport!.clearListeners();
    }

    // set up transport
    this.transport = transport;

    // set up transport listeners
    transport
      ..on('drain', (_) => onDrain())
      ..on('packet', (packet) => onPacket(packet))
      ..on('error', (e) => onError(e))
      ..on('close', (_) => onClose('transport close'));
  }

  ///
  /// Probes a transport.
  ///
  /// @param {String} transport name
  /// @api private
  void probe(name) {
    _logger.fine('probing transport "$name"');
    Transport? transport = createTransport(name, {'probe': true});
    var failed = false;
    var cleanup;
    priorWebsocketSuccess = false;

    var onTransportOpen = (_) {
      if (onlyBinaryUpgrades == true) {
        var upgradeLosesBinary =
            supportsBinary == false && transport!.supportsBinary == false;
        failed = failed || upgradeLosesBinary;
      }
      if (failed) return;

      _logger.fine('probe transport "$name" opened');
      transport!.send([
        {'type': 'ping', 'data': 'probe'}
      ]);
      transport!.once('packet', (msg) {
        if (failed) return;
        if ('pong' == msg['type'] && 'probe' == msg['data']) {
          _logger.fine('probe transport "$name" pong');
          upgrading = true;
          emit('upgrading', transport);
          if (transport == null) return;
          priorWebsocketSuccess = 'websocket' == transport!.name;

          _logger.fine('pausing current transport "${transport?.name}"');
          if (this.transport is PollingTransport) {
            (this.transport as PollingTransport).pause(() {
              if (failed) return;
              if ('closed' == readyState) return;
              _logger.fine('changing transport and sending upgrade packet');

              cleanup();

              setTransport(transport);
              transport!.send([
                {'type': 'upgrade'}
              ]);
              emit('upgrade', transport);
              transport = null;
              upgrading = false;
              flush();
            });
          }
        } else {
          _logger.fine('probe transport "$name" failed');
          emit('upgradeError',
              {'error': 'probe error', 'transport': transport!.name});
        }
      });
    };

    var freezeTransport = () {
      if (failed) return;

      // Any callback called by transport should be ignored since now
      failed = true;

      cleanup();

      transport!.close();
      transport = null;
    };

    // Handle any error that happens while probing
    var onerror = (err) {
      final oldTransport = transport;
      freezeTransport();

      _logger.fine('probe transport "$name" failed because of error: $err');

      emit('upgradeError',
          {'error': 'probe error: $err', 'transport': oldTransport!.name});
    };

    var onTransportClose = (_) => onerror('transport closed');

    // When the socket is closed while we're probing
    var onclose = (_) => onerror('socket closed');

    // When the socket is upgraded while we're probing
    var onupgrade = (to) {
      if (transport != null && to.name != transport!.name) {
        _logger.fine('"${to?.name}" works - aborting "${transport?.name}"');
        freezeTransport();
      }
    };

    // Remove all listeners on the transport and on self
    cleanup = () {
      transport!.off('open', onTransportOpen);
      transport!.off('error', onerror);
      transport!.off('close', onTransportClose);
      off('close', onclose);
      off('upgrading', onupgrade);
    };

    transport!.once('open', onTransportOpen);
    transport!.once('error', onerror);
    transport!.once('close', onTransportClose);

    once('close', onclose);
    once('upgrading', onupgrade);

    transport!.open();
  }

  ///
  /// Called when connection is deemed open.
  ///
  /// @api public
  void onOpen() {
    _logger.fine('socket open');
    readyState = 'open';
    priorWebsocketSuccess = 'websocket' == transport!.name;
    emit('open');
    flush();

    // we check for `readyState` in case an `open`
    // listener already closed the socket
    if ('open' == readyState &&
        upgrade == true &&
        transport is PollingTransport) {
      _logger.fine('starting upgrade probes');
      for (var i = 0, l = upgrades.length; i < l; i++) {
        probe(upgrades[i]);
      }
    }
  }

  ///
  /// Handles a packet.
  ///
  /// @api private
  void onPacket(Map packet) {
    if ('opening' == readyState ||
        'open' == readyState ||
        'closing' == readyState) {
      var type = packet['type'];
      var data = packet['data'];
      _logger.fine('socket receive: type "$type", data "$data"');

      emit('packet', packet);

      // Socket is live - any packet counts
      emit('heartbeat');

      switch (type) {
        case 'open':
          onHandshake(json.decode(data ?? 'null'));
          break;

        case 'ping':
          resetPingTimeout();
          sendPacket(type: 'pong');
          emit('pong');
          break;

        case 'error':
          onError({'error': 'server error', 'code': data});
          break;

        case 'message':
          emit('data', data);
          emit('message', data);
          break;
      }
    } else {
      _logger.fine('packet received with socket readyState "$readyState"');
    }
  }

  ///
  ///Sets and resets ping timeout timer based on server pings.
  /// @api private
  ///
  void resetPingTimeout() {
    pingTimeoutTimer?.cancel();
    pingTimeoutTimer =
        Timer(Duration(milliseconds: pingInterval + pingTimeout), () {
      onClose('ping timeout');
    });
  }

  ///
  /// Called upon handshake completion.
  ///
  /// @param {Object} handshake obj
  /// @api private
  void onHandshake(Map data) {
    emit('handshake', data);
    id = data['sid'];
    transport!.query!['sid'] = data['sid'];
    upgrades = filterUpgrades(data['upgrades']);
    pingInterval = data['pingInterval'];
    pingTimeout = data['pingTimeout'];
    onOpen();
    // In case open handler closes socket
    if ('closed' == readyState) return;
    resetPingTimeout();

    // Prolong liveness of socket on heartbeat
    // off('heartbeat', onHeartbeat);
    // on('heartbeat', onHeartbeat);
  }

  ///
  /// Resets ping timeout.
  ///
  /// @api private
  // void onHeartbeat(timeout) {
  //   pingTimeoutTimer?.cancel();
  //   pingTimeoutTimer = Timer(
  //       Duration(milliseconds: timeout ?? (pingInterval + pingTimeout)), () {
  //     if ('closed' == readyState) return;
  //     onClose('ping timeout');
  //   });
  // }

  ///
  /// Sends a ping packet.
  ///
  /// @api private
  // void ping() {
  //   sendPacket(type: 'ping', callback: (_) => emit('ping'));
  // }

  ///
  /// Called on `drain` event
  ///
  /// @api private
  void onDrain() {
    writeBuffer.removeRange(0, prevBufferLen);

    // setting prevBufferLen = 0 is very important
    // for example, when upgrading, upgrade packet is sent over,
    // and a nonzero prevBufferLen could cause problems on `drain`
    prevBufferLen = 0;

    if (writeBuffer.isEmpty) {
      emit('drain');
    } else {
      flush();
    }
  }

  ///
  /// Flush write buffers.
  ///
  /// @api private
  void flush() {
    if ('closed' != readyState &&
        transport!.writable == true &&
        upgrading != true &&
        writeBuffer.isNotEmpty) {
      _logger.fine('flushing ${writeBuffer.length} packets in socket');
      transport!.send(writeBuffer);
      // keep track of current length of writeBuffer
      // splice writeBuffer and callbackBuffer on `drain`
      prevBufferLen = writeBuffer.length;
      emit('flush');
    }
  }

  ///
  /// Sends a message.
  ///
  /// @param {String} message.
  /// @param {Function} callback function.
  /// @param {Object} options.
  /// @return {Socket} for chaining.
  /// @api public
  Socket write(msg, options, [EventHandler? fn]) => send(msg, options, fn);

  Socket send(msg, options, [EventHandler? fn]) {
    sendPacket(type: 'message', data: msg, options: options, callback: fn);
    return this;
  }

  ///
  /// Sends a packet.
  ///
  /// @param {String} packet type.
  /// @param {String} data.
  /// @param {Object} options.
  /// @param {Function} callback function.
  /// @api private
  void sendPacket({type, data, options, EventHandler? callback}) {
    if ('closing' == readyState || 'closed' == readyState) {
      return;
    }

    options = options ?? {};
    options['compress'] = false != options['compress'];

    var packet = {'type': type, 'data': data, 'options': options};
    emit('packetCreate', packet);
    writeBuffer.add(packet);
    if (callback != null) once('flush', callback);
    flush();
  }

  ///
  /// Closes the connection.
  ///
  /// @api private
  Socket close() {
    var close = () {
      onClose('forced close');
      _logger.fine('socket closing - telling transport to close');
      transport!.close();
    };

    var temp;
    var cleanupAndClose = (_) {
      off('upgrade', temp);
      off('upgradeError', temp);
      close();
    };

    // a workaround for dart to access the local variable;
    temp = cleanupAndClose;

    var waitForUpgrade = () {
      // wait for upgrade to finish since we can't send packets while pausing a transport
      once('upgrade', cleanupAndClose);
      once('upgradeError', cleanupAndClose);
    };

    if ('opening' == readyState || 'open' == readyState) {
      readyState = 'closing';

      if (writeBuffer.isNotEmpty) {
        once('drain', (_) {
          if (upgrading == true) {
            waitForUpgrade();
          } else {
            close();
          }
        });
      } else if (upgrading == true) {
        waitForUpgrade();
      } else {
        close();
      }
    }

    return this;
  }

  ///
  /// Called upon transport error
  ///
  /// @api private
  void onError(err) {
    _logger.fine('socket error $err');
    priorWebsocketSuccess = false;
    emit('error', err);
    onClose('transport error', err);
  }

  ///
  /// Called upon transport close.
  ///
  /// @api private
  void onClose(reason, [desc]) {
    if ('opening' == readyState ||
        'open' == readyState ||
        'closing' == readyState) {
      _logger.fine('socket close with reason: "$reason"');

      // clear timers
      pingIntervalTimer?.cancel();
      pingTimeoutTimer?.cancel();

      // stop event from firing again for transport
      transport!.off('close');

      // ensure transport won't stay open
      transport!.close();

      // ignore further transport communication
      transport!.clearListeners();

      // set ready state
      readyState = 'closed';

      // clear session id
      id = null;

      // emit close event
      emit('close', {'reason': reason, 'desc': desc});

      // clean buffers after, so users can still
      // grab the buffers on `close` event
      writeBuffer = [];
      prevBufferLen = 0;
    }
  }

  ///
  /// Filters upgrades, returning only those matching client transports.
  ///
  /// @param {Array} server upgrades
  /// @api private
  ///
  List filterUpgrades(List upgrades) =>
      transports.where((_) => upgrades.contains(_)).toList();
}
