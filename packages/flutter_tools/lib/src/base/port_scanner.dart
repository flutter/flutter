// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'context.dart';
import 'io.dart';

const int _kMaxSearchIterations = 20;

PortScanner get portScanner => context[PortScanner];

abstract class PortScanner {
  const PortScanner();

  /// Returns true if the specified [port] is available to bind to.
  Future<bool> isPortAvailable(int port);

  /// Returns an available ephemeral port.
  Future<int> findAvailablePort();

  /// Returns an available port as close to [defaultPort] as possible.
  ///
  /// If [defaultPort] is available, this will return it. Otherwise, it will
  /// search for an available port close to [defaultPort]. If it cannot find one,
  /// it will return any available port.
  Future<int> findPreferredPort(int defaultPort) async {
    int iterationCount = 0;

    while (iterationCount < _kMaxSearchIterations) {
      final int port = defaultPort + iterationCount;
      if (await isPortAvailable(port))
        return port;
      iterationCount++;
    }

    return findAvailablePort();
  }
}

class HostPortScanner extends PortScanner {
  const HostPortScanner();

  @override
  Future<bool> isPortAvailable(int port) async {
    try {
      // TODO(ianh): This is super racy.
      final ServerSocket socket = await ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, port); // ignore: deprecated_member_use
      await socket.close();
      return true;
    } catch (error) {
      return false;
    }
  }

  @override
  Future<int> findAvailablePort() async {
    ServerSocket socket;
    try {
      socket = await ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0); // ignore: deprecated_member_use
    } on SocketException {
      socket = await ServerSocket.bind(InternetAddress.LOOPBACK_IP_V6, 0, v6Only: true); // ignore: deprecated_member_use
    }
    final int port = socket.port;
    await socket.close();
    return port;
  }
}
