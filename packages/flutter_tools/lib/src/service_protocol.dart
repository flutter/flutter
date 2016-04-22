// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'device.dart';

/// Discover service protocol ports on devices.
class ServiceProtocolDiscovery {
  /// [logReader] - a [DeviceLogReader] to look for service messages in.
  ServiceProtocolDiscovery(DeviceLogReader logReader, String serviceName)
      : _logReader = logReader, _serviceName = serviceName {
    assert(_logReader != null);
    _subscription = _logReader.logLines.listen(_onLine);
  }

  static const String kObservatoryService = 'Observatory';
  static const String kDiagnosticService = 'Diagnostic server';

  final DeviceLogReader _logReader;
  final String _serviceName;

  Completer<int> _completer = new Completer<int>();
  StreamSubscription<String> _subscription;

  /// The [Future] returned by this function will complete when the next service
  /// protocol port is found.
  Future<int> nextPort() => _completer.future;

  void cancel() {
    _subscription.cancel();
  }

  void _onLine(String line) {
    int portNumber = 0;
    if (line.contains('$_serviceName listening on http://')) {
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
