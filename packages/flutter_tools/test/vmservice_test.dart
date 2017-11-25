// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/src/base/port_scanner.dart';
import 'package:flutter_tools/src/vmservice.dart';

void main() {
  group('VMService', () {
    test('fails connection eagerly in the connect() method', () async {
      final int port = await const HostPortScanner().findAvailablePort();
      expect(
        VMService.connect(Uri.parse('http://localhost:$port')),
        throwsA(const isInstanceOf<WebSocketChannelException>()),
      );
    });
  });
}
