// Copyright 2015, the Flutter authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sky_services/gcm/gcm.mojom.dart';

GcmServiceProxy _initGcmService() {
  GcmServiceProxy gcmService = new GcmServiceProxy.unbound();
  shell.connectToService(null, gcmService);
  return gcmService;
}

final GcmServiceProxy _gcmService = _initGcmService();

typedef void GcmListenerCallback(String from, String message);
class _GcmListenerImpl implements GcmListener {
  _GcmListenerImpl(this.callback);

  GcmListenerCallback callback;

  void onMessageReceived(String from, String message) {
    callback(from, message);
  }
}

Future<String> registerGcmService(String senderId, GcmListenerCallback listenerCallback) async {
  GcmListenerStub listener = new GcmListenerStub.unbound()
    ..impl = new _GcmListenerImpl(listenerCallback);
  GcmServiceRegisterResponseParams result =
      await _gcmService.ptr.register(senderId, listener);
  return result.token;
}

void subscribeTopics(String token, List<String> topics) {
  _gcmService.ptr.subscribeTopics(token, topics);
}

void unsubscribeTopics(String token, List<String> topics) {
  _gcmService.ptr.unsubscribeTopics(token, topics);
}
