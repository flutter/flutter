// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/core.dart' as core;
import 'package:sky_services/flutter/platform/app_messages.mojom.dart' as mojom;

import 'shell.dart';

mojom.ApplicationMessagesProxy _initHostAppMessagesProxy() {
  mojom.ApplicationMessagesProxy proxy = new mojom.ApplicationMessagesProxy.unbound();
  shell.connectToViewAssociatedService(proxy);
  return proxy;
}

final mojom.ApplicationMessagesProxy _hostAppMessagesProxy = _initHostAppMessagesProxy();

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
  static Future<String> sendToHost(String messageName, String message) async {
    return (await _hostAppMessagesProxy.ptr.sendString(messageName, message)).reply;
  }

  /// Register a callback for messages received from the host application.
  /// The callback function must return a String, Future<String>, or null.
  static void addMessageHandler(String messageName, HostMessageCallback callback) {
    _appMessages.handlers[messageName] = callback;
  }
}
