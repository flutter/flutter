// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/core.dart' as core;
import 'package:sky_services/flutter/platform/app_messages.mojom.dart';

import 'shell.dart';

// APIs for exchanging messages with the host application.

ApplicationMessagesProxy _initHostAppMessagesProxy() {
  ApplicationMessagesProxy proxy = new ApplicationMessagesProxy.unbound();
  shell.connectToViewAssociatedService(proxy);
  return proxy;
}

final ApplicationMessagesProxy _hostAppMessagesProxy = _initHostAppMessagesProxy();

typedef Future<String> HostMessageCallback(String message);
typedef Object _SendStringResponseFactory(String response);

class _ApplicationMessagesImpl extends ApplicationMessages {
  final Map<String, HostMessageCallback> handlers = <String, HostMessageCallback>{};

  _ApplicationMessagesImpl() {
    shell.provideService(ApplicationMessages.serviceName,
      (core.MojoMessagePipeEndpoint endpoint) {
        ApplicationMessagesStub stub = new ApplicationMessagesStub.fromEndpoint(endpoint);
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
