// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class JSONSocket {
  JSONSocket(WebSocket socket, this.unusualTermination)
    : _socket = socket, stream = socket.map(JSON.decode).asBroadcastStream();

  final WebSocket _socket;
  final Stream stream;
  final Future<String> unusualTermination;

  void send(dynamic data) {
    _socket.add(JSON.encode(data));
  }
}
