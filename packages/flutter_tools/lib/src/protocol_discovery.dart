// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/common.dart';
import 'base/io.dart';
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
    this.ipv6,
  }) : assert(logReader != null),
       assert(portForwarder == null || defaultHostPort != null),
       _prefix = '$serviceName listening on ' {
    _deviceLogSubscription = logReader.logLines.listen(_handleLine);
  }

  factory ProtocolDiscovery.observatory(
    DeviceLogReader logReader, {
    DevicePortForwarder portForwarder,
    int hostPort,
    bool ipv6: false,
  }) {
    const String kObservatoryService = 'Observatory';
    return new ProtocolDiscovery._(
      logReader, kObservatoryService,
      portForwarder: portForwarder,
      hostPort: hostPort,
      defaultHostPort: kDefaultObservatoryPort,
      ipv6: ipv6,
    );
  }

  final DeviceLogReader logReader;
  final String serviceName;
  final DevicePortForwarder portForwarder;
  final int hostPort;
  final int defaultHostPort;
  final bool ipv6;

  final String _prefix;
  final Completer<Uri> _completer = new Completer<Uri>();

  StreamSubscription<String> _deviceLogSubscription;

  /// The discovered service URI.
  Future<Uri> get uri => _completer.future;

  Future<Null> cancel() => _stopScrapingLogs();

  Future<Null> _stopScrapingLogs() async {
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
      hostPort = await portForwarder.forward(devicePort, hostPort: hostPort);
      printTrace('Forwarded host port $hostPort to device port $devicePort for $serviceName');
      hostUri = deviceUri.replace(port: hostPort);
    }

    assert(new InternetAddress(hostUri.host).isLoopback);
    if (ipv6) {
      hostUri = hostUri.replace(host: InternetAddress.LOOPBACK_IP_V6.host);
    }

    return hostUri;
  }
}
