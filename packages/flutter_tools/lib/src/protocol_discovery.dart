// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/common.dart';
import 'base/port_scanner.dart';
import 'device.dart';
import 'globals.dart';

/// Discovers a specific service protocol on a device, and forward the service
/// protocol device port to the host.
class ProtocolDiscovery {
  ProtocolDiscovery._(
    DeviceLogReader logReader,
    String serviceName, {
    this.portForwarder,
    this.hostPort,
    this.defaultHostPort,
  }) : _logReader = logReader, _serviceName = serviceName {
    assert(_logReader != null);
    assert(portForwarder == null || defaultHostPort != null);
    _deviceLogSubscription = _logReader.logLines.listen(_onLine);
  }

  factory ProtocolDiscovery.observatory(DeviceLogReader logReader,
          {DevicePortForwarder portForwarder, int hostPort}) =>
      new ProtocolDiscovery._(logReader, _kObservatoryService,
          portForwarder: portForwarder,
          hostPort: hostPort,
          defaultHostPort: kDefaultObservatoryPort);

  factory ProtocolDiscovery.diagnosticService(DeviceLogReader logReader,
          {DevicePortForwarder portForwarder, int hostPort}) =>
      new ProtocolDiscovery._(logReader, _kDiagnosticService,
          portForwarder: portForwarder,
          hostPort: hostPort,
          defaultHostPort: kDefaultDiagnosticPort);

  static const String _kObservatoryService = 'Observatory';
  static const String _kDiagnosticService = 'Diagnostic server';

  final DeviceLogReader _logReader;
  final String _serviceName;
  final DevicePortForwarder portForwarder;
  final int hostPort;
  final int defaultHostPort;
  final Completer<Uri> _completer = new Completer<Uri>();

  StreamSubscription<String> _deviceLogSubscription;

  /// The discovered service URI.
  Future<Uri> get uri {
    return _completer.future
        .timeout(const Duration(seconds: 60), onTimeout: () {
          throwToolExit('Timeout while attempting to retrieve Uri for $_serviceName');
        }).whenComplete(() {
          _stopScrapingLogs();
        });
  }

  Future<Null> cancel() => _stopScrapingLogs();

  Future<Null> _stopScrapingLogs() async {
    await _deviceLogSubscription?.cancel();
    _deviceLogSubscription = null;
  }

  void _onLine(String line) {
    Uri uri;
    final String prefix = '$_serviceName listening on ';
    final int index = line.indexOf(prefix + 'http://');
    if (index >= 0) {
      try {
        uri = Uri.parse(line.substring(index + prefix.length));
      } catch (error) {
        _stopScrapingLogs();
        _completer.completeError(error);
      }
    }

    if (uri != null) {
      assert(!_completer.isCompleted);
      _stopScrapingLogs();
      _completer.complete(_forwardPort(uri));
    }
  }

  Future<Uri> _forwardPort(Uri deviceUri) async {
    printTrace('$_serviceName Uri on device: $deviceUri');
    Uri hostUri = deviceUri;

    if (portForwarder != null) {
      final int devicePort = deviceUri.port;
      int hostPort = this.hostPort ?? await portScanner.findPreferredPort(defaultHostPort);
      hostPort = await portForwarder
          .forward(devicePort, hostPort: hostPort)
          .timeout(const Duration(seconds: 60), onTimeout: () {
        throwToolExit('Timeout while atempting to foward device port $devicePort for $_serviceName');
      });
      printTrace('Forwarded host port $hostPort to device port $devicePort for $_serviceName');
      hostUri = deviceUri.replace(port: hostPort);
    }

    return hostUri;
  }
}
