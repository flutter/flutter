// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:mojo/core.dart' as core;
import 'package:flutter_services/platform/app_messages.dart' as mojom;

import 'shell.dart';

mojom.ApplicationMessagesProxy _initHostAppMessagesProxy() {
  return shell.connectToViewAssociatedService(mojom.ApplicationMessages.connectToService);
}

final mojom.ApplicationMessagesProxy _hostAppMessagesProxy = _initHostAppMessagesProxy();

/// Signature for receiving [HostMessages].
typedef Future<String> HostMessageCallback(String message);

typedef Object _SendStringResponseFactory(String response);

class _ApplicationMessagesImpl extends mojom.ApplicationMessages {
  final Map<String, HostMessageCallback> handlers = <String, HostMessageCallback>{};

  _ApplicationMessagesImpl() {
    shell.provideService(mojom.ApplicationMessages.serviceName,
      (core.MojoMessagePipeEndpoint endpoint) {
        mojom.ApplicationMessagesStub stub = new mojom.ApplicationMessagesStub.fromEndpoint(endpoint);
        stub.impl = this;
      }
    );
  }

  @override
  dynamic sendString(String messageName, String message, [_SendStringResponseFactory responseFactory]) {
    HostMessageCallback callback = handlers[messageName];
    if (callback == null)
      return responseFactory(null);

    return callback(message).then((String s) => responseFactory(s));
  }
}

final _ApplicationMessagesImpl _appMessages = new _ApplicationMessagesImpl();

/// A service that can be implemented by the host application and the
/// Flutter framework to exchange application-specific messages.
class HostMessages {
  /// Send a message to the host application.
  static Future<String> sendToHost(String messageName, [String message = '']) {
    Completer<String> completer = new Completer<String>();
    _hostAppMessagesProxy.sendString(messageName, message, (String reply) {
      completer.complete(reply);
    });
    return completer.future;
  }

  static dynamic _decode(String message) {
    return message != null ? JSON.decode(message) : null;
  }

  /// Sends a JSON-encoded message to the host application and JSON-decodes the response.
  static Future<dynamic> sendJSON(String messageName, [dynamic json]) async {
    Completer<dynamic> completer = new Completer<dynamic>();
    _hostAppMessagesProxy.sendString(messageName, JSON.encode(json), (String reply) {
      completer.complete(_decode(reply));
    });
    return completer.future;
  }

  /// Register a callback for receiving messages from the host application.
  static void addMessageHandler(String messageName, HostMessageCallback callback) {
    _appMessages.handlers[messageName] = callback;
  }

  /// Register a callback for receiving JSON messages from the host application.
  ///
  /// Messages received from the host application are decoded as JSON before
  /// being passed to `callback`. The result of the callback is encoded as JSON
  /// before being returned to the host application.
  static void addJSONMessageHandler(String messageName, Future<dynamic> callback(dynamic json)) {
    _appMessages.handlers[messageName] = (String message) async {
      return JSON.encode(await callback(_decode(message)));
    };
  }
}
