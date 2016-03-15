// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'device.dart';

/// Discover service protocol ports on devices.
class ServiceProtocolDiscovery {
  /// [logReader] A [DeviceLogReader] to look for Observatory messages in.
  ServiceProtocolDiscovery(DeviceLogReader logReader)
      : _logReader = logReader {
    assert(_logReader != null);
    if (!_logReader.isReading)
      _logReader.start();

    _logReader.lines.listen(_onLine);
  }

  final DeviceLogReader _logReader;
  Completer<int> _completer = new Completer<int>();

  /// The [Future] returned by this function will complete when the next
  /// service protocol port is found.
  Future<int> nextPort() {
    return _completer.future;
  }

  void _onLine(String line) {
    int portNumber = 0;
    if (line.contains('Observatory listening on http://')) {
      try {
        RegExp portExp = new RegExp(r"\d+.\d+.\d+.\d+:(\d+)");
        String port = portExp.firstMatch(line).group(1);
        portNumber = int.parse(port);
      } catch (_) {
        // Ignore errors.
      }
    }
    if (portNumber != 0)
      _located(portNumber);
  }

  void _located(int port) {
    assert(_completer != null);
    assert(!_completer.isCompleted);
    _completer.complete(port);
    _completer = new Completer<int>();
  }
}
