// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/common.dart';
import 'base/port_scanner.dart';
import 'device.dart';
import 'globals.dart';

/// Discovers a specific service protocol on a device, and forwards the service
/// protocol device port to the host.
class ProtocolDiscovery {
  ProtocolDiscovery._(
    this.logReader,
    this.serviceName, {
    this.portForwarder,
    this.hostPort,
    this.defaultHostPort,
  }) : _prefix = '$serviceName listening on ' {
    assert(logReader != null);
    assert(portForwarder == null || defaultHostPort != null);
    _deviceLogSubscription = logReader.logLines.listen(_handleLine);
    _timer = new Timer(const Duration(seconds: 60), () {
      _stopScrapingLogs();
      _completer.completeError(new ToolExit('Timeout while attempting to retrieve URL for $serviceName'));
    });
  }

  factory ProtocolDiscovery.observatory(
    DeviceLogReader logReader, {
    DevicePortForwarder portForwarder,
    int hostPort,
  }) {
    const String kObservatoryService = 'Observatory';
    return new ProtocolDiscovery._(
      logReader, kObservatoryService,
      portForwarder: portForwarder,
      hostPort: hostPort,
      defaultHostPort: kDefaultObservatoryPort,
    );
  }

  factory ProtocolDiscovery.diagnosticService(
    DeviceLogReader logReader, {
    DevicePortForwarder portForwarder,
    int hostPort,
  }) {
    const String kDiagnosticService = 'Diagnostic server';
    return new ProtocolDiscovery._(
      logReader, kDiagnosticService,
      portForwarder: portForwarder,
      hostPort: hostPort,
      defaultHostPort: kDefaultDiagnosticPort,
    );
  }

  final DeviceLogReader logReader;
  final String serviceName;
  final DevicePortForwarder portForwarder;
  final int hostPort;
  final int defaultHostPort;

  final String _prefix;
  final Completer<Uri> _completer = new Completer<Uri>();

  StreamSubscription<String> _deviceLogSubscription;
  Timer _timer;

  /// The discovered service URI.
  Future<Uri> get uri => _completer.future;

  Future<Null> cancel() => _stopScrapingLogs();

  Future<Null> _stopScrapingLogs() async {
    _timer?.cancel();
    _timer = null;
    await _deviceLogSubscription?.cancel();
    _deviceLogSubscription = null;
  }

  void _handleLine(String line) {
    Uri uri;
    final int index = line.indexOf(_prefix + 'http://');
    if (index >= 0) {
      try {
        uri = Uri.parse(line.substring(index + _prefix.length));
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
    printTrace('$serviceName URL on device: $deviceUri');
    Uri hostUri = deviceUri;

    if (portForwarder != null) {
      final int devicePort = deviceUri.port;
      int hostPort = this.hostPort ?? await portScanner.findPreferredPort(defaultHostPort);
      hostPort = await portForwarder
          .forward(devicePort, hostPort: hostPort)
          .timeout(const Duration(seconds: 60), onTimeout: () {
        throwToolExit('Timeout while atempting to foward device port $devicePort for $serviceName');
      });
      printTrace('Forwarded host port $hostPort to device port $devicePort for $serviceName');
      hostUri = deviceUri.replace(port: hostPort);
    }

    return hostUri;
  }
}
