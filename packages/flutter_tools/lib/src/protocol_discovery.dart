// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'device.dart';

/// Discover service protocol ports on devices.
class ProtocolDiscovery {
  /// [logReader] - a [DeviceLogReader] to look for service messages in.
  ProtocolDiscovery(DeviceLogReader logReader, String serviceName)
      : _logReader = logReader, _serviceName = serviceName {
    assert(_logReader != null);
    _subscription = _logReader.logLines.listen(_onLine);
  }

  static const String kObservatoryService = 'Observatory';
  static const String kDiagnosticService = 'Diagnostic server';

  final DeviceLogReader _logReader;
  final String _serviceName;

  Completer<Uri> _completer = new Completer<Uri>();
  StreamSubscription<String> _subscription;

  /// The [Future] returned by this function will complete when the next service
  /// Uri port is found.
  Future<Uri> nextUri() => _completer.future;

  void cancel() {
    _subscription.cancel();
  }

  void _onLine(String line) {
    int portNumber = 0;
    Uri uri;
    int index = line.indexOf('$_serviceName listening on http://');
    if (index >= 0) {
      try {
        RegExp portExp = new RegExp(r"\d+.\d+.\d+.\d+:(\d+)");
        String port = portExp.firstMatch(line).group(1);
        portNumber = int.parse(port);
        uri = Uri.parse(line, index + _serviceName.length + 14);
      } catch (_) {
        // Ignore errors.
      }
    }
    if (uri != null)
      _located(uri, portNumber);
  }

  void _located(Uri uri, int port) {
    assert(_completer != null);
    assert(!_completer.isCompleted);

    _completer.complete(uri);
    _completer = new Completer<Uri>();
  }
}
