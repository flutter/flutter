// Copyright (C) 2017 Potix Corporation. All Rights Reserved
// History:  27/04/2017
// Author: jumperchen<jumperchen@potix.com>
import 'dart:async';
import 'dart:html';

import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:socket_io_common/src/util/event_emitter.dart';
import 'package:socket_io_client/src/engine/transport/polling_transport.dart';

final Logger _logger = Logger('socket_io_client:transport.XHRTransport');

class XHRTransport extends PollingTransport {
  // int? requestTimeout;
  late bool xd;
  late bool xs;
  Request? sendXhr;
  Request? pollXhr;
  late Map<String, dynamic> extraHeaders;

  ///
  /// XHR Polling constructor.
  ///
  /// @param {Object} opts
  /// @api public
  XHRTransport(Map opts) : super(opts) {
    // requestTimeout = opts['requestTimeout'];
    extraHeaders = opts['extraHeaders'] ?? <String, dynamic>{};

    var isSSL = 'https:' == window.location.protocol;
    var port = window.location.port;

    // some user agents have empty `location.port`
    if (port.isEmpty) {
      port = isSSL ? '443' : '80';
    }

    xd = opts['hostname'] != window.location.hostname ||
        int.parse(port) != opts['port'];
    xs = opts['secure'] != isSSL;
  }

  ///
  /// XHR supports binary
  @override
  bool? supportsBinary = true;

  ///
  /// Creates a request.
  ///
  /// @api private
  Request request([Map? opts]) {
    opts = opts ?? {};
    opts['uri'] = uri();
    opts['xd'] = xd;
    opts['xs'] = xs;
    opts['agent'] = agent ?? false;
    opts['supportsBinary'] = supportsBinary;
    opts['enablesXDR'] = enablesXDR;

    // SSL options for Node.js client
//    opts.pfx = this.pfx;
//    opts.key = this.key;
//    opts.passphrase = this.passphrase;
//    opts.cert = this.cert;
//    opts.ca = this.ca;
//    opts.ciphers = this.ciphers;
//    opts.rejectUnauthorized = this.rejectUnauthorized;
//    opts.requestTimeout = this.requestTimeout;

    // other options for Node.js client
    opts['extraHeaders'] = extraHeaders;

    return Request(opts);
  }

  ///
  /// Sends data.
  ///
  /// @param {String} data to send.
  /// @param {Function} called upon flush.
  /// @api private
  @override
  void doWrite(data, fn) {
    var isBinary = data is! String;
    var req = request({'method': 'POST', 'data': data, 'isBinary': isBinary});
    req.on('success', fn);
    req.on('error', (err) {
      onError('xhr post error', err);
    });
    sendXhr = req;
  }

  ///
  /// Starts a poll cycle.
  ///
  /// @api private
  @override
  void doPoll() {
    _logger.fine('xhr poll');
    var req = request();
    req.on('data', (data) {
      onData(data);
    });
    req.on('error', (err) {
      onError('xhr poll error', err);
    });
    pollXhr = req;
  }
}

///
/// Request constructor
///
/// @param {Object} options
/// @api public
///
class Request extends EventEmitter {
  late String uri;
  late bool xd;
  late bool xs;
  late bool async;
  late var data;
  late bool agent;
  bool? isBinary;
  late bool supportsBinary;
  late bool enablesXDR;
  // late int requestTimeout;
  HttpRequest? xhr;
  late String method;
  StreamSubscription? readyStateChange;
  Map<String, dynamic>? extraHeaders;

  Request(Map opts) {
    method = opts['method'] ?? 'GET';
    uri = opts['uri'];
    xd = opts['xd'] == true;
    xs = opts['xs'] == true;
    async = opts['async'] != false;
    data = opts['data'];
    agent = opts['agent'];
    isBinary = opts['isBinary'];
    supportsBinary = opts['supportsBinary'];
    enablesXDR = opts['enablesXDR'];
    // requestTimeout = opts['requestTimeout'];
    extraHeaders = opts['extraHeaders'];

    create();
  }

  ///
  /// Creates the XHR object and sends the request.
  ///
  /// @api private
  void create() {
//var opts = { 'agent': this.agent, 'xdomain': this.xd, 'xscheme': this.xs, 'enablesXDR': this.enablesXDR };

    var xhr = this.xhr = HttpRequest();
    var self = this;

    try {
      _logger.fine('xhr open $method: $uri');
      xhr.open(method, uri, async: async);

      try {
        if (extraHeaders?.isNotEmpty == true) {
          extraHeaders!.forEach((k, v) {
            xhr.setRequestHeader(k, v);
          });
        }
      } catch (e) {
        // ignore
      }

      if ('POST' == method) {
        try {
          if (isBinary!) {
            xhr.setRequestHeader('Content-type', 'application/octet-stream');
          } else {
            xhr.setRequestHeader('Content-type', 'text/plain;charset=UTF-8');
          }
        } catch (e) {
          // ignore
        }
      }

      try {
        xhr.setRequestHeader('Accept', '*/*');
      } catch (e) {
        // ignore
      }

// ie6 check
//if ('withCredentials' in xhr) {
//xhr.withCredentials = true;
//}

      /*if (this.requestTimeout != null) {
        xhr.timeout = this.requestTimeout;
      }

      if (this.hasXDR()) {
        xhr.onload = function()
        {
          self.onLoad();
        };
        xhr.onerror = function()
        {
          self.onError(xhr.responseText);
        };
      } else {*/
      readyStateChange = xhr.onReadyStateChange.listen((evt) {
        if (xhr.readyState == 2) {
          var contentType;
          try {
            contentType = xhr.getResponseHeader('Content-Type');
          } catch (e) {
            // ignore
          }
          if (contentType == 'application/octet-stream') {
            xhr.responseType = 'arraybuffer';
          }
        }
        if (4 != xhr.readyState) return;
        if (200 == xhr.status || 1223 == xhr.status) {
          self.onLoad();
        } else {
// make sure the `error` event handler that's user-set
// does not throw in the same tick and gets caught here
          Timer.run(() => self.onError(xhr.status));
        }
      });
      /*}*/

      _logger.fine('xhr data $data');
      xhr.send(data);
    } catch (e) {
// Need to defer since .create() is called directly fhrom the constructor
// and thus the 'error' event can only be only bound *after* this exception
// occurs.  Therefore, also, we cannot throw here at all.
      Timer.run(() => onError(e));
      return;
    }
  }

  ///
  /// Called upon successful response.
  ///
  /// @api private
  void onSuccess() {
    emit('success');
    cleanup();
  }

  ///
  /// Called if we have data.
  ///
  /// @api private
  void onData(data) {
    emit('data', data);
    onSuccess();
  }

  ///
  /// Called upon error.
  ///
  /// @api private
  void onError(err) {
    emit('error', err);
    cleanup(true);
  }

  ///
  /// Cleans up house.
  ///
  /// @api private
  void cleanup([fromError]) {
    if (xhr == null) {
      return;
    }
    // xmlhttprequest
    if (hasXDR()) {
    } else {
      readyStateChange?.cancel();
      readyStateChange = null;
    }

    if (fromError != null) {
      try {
        xhr!.abort();
      } catch (e) {
        // ignore
      }
    }

    xhr = null;
  }

  ///
  /// Called upon load.
  ///
  /// @api private
  void onLoad() {
    var data;
    try {
      var contentType;
      try {
        contentType = xhr!.getResponseHeader('Content-Type');
      } catch (e) {
        // ignore
      }
      if (contentType == 'application/octet-stream') {
        data = xhr!.response ?? xhr!.responseText;
      } else {
        data = xhr!.responseText;
      }
    } catch (e) {
      onError(e);
    }
    if (null != data) {
      if (data is ByteBuffer) data = data.asUint8List();
      onData(data);
    }
  }

  ///
  /// Check if it has XDomainRequest.
  ///
  /// @api private
  bool hasXDR() {
    // Todo: handle it in dart way
    return false;
    //  return 'undefined' !== typeof global.XDomainRequest && !this.xs && this.enablesXDR;
  }

  ///
  /// Aborts the request.
  ///
  /// @api public
  void abort() => cleanup();
}
