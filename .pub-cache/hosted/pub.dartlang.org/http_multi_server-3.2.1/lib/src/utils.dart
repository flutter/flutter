// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Returns whether this computer supports binding to IPv6 addresses.
final Future<bool> supportsIPv6 = () async {
  try {
    var socket = await ServerSocket.bind(InternetAddress.loopbackIPv6, 0);
    await socket.close();
    return true;
  } on SocketException catch (_) {
    return false;
  }
}();

/// Returns whether this computer supports binding to IPv4 addresses.
final Future<bool> supportsIPv4 = () async {
  try {
    var socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    await socket.close();
    return true;
  } on SocketException catch (_) {
    return false;
  }
}();
