// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/io.dart';
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
    this.ipv6,
  }) : assert(logReader != null),
       _prefix = '$serviceName listening on ' {
    _deviceLogSubscription = logReader.logLines.listen(_handleLine);
  }

  factory ProtocolDiscovery.observatory(
    DeviceLogReader logReader, {
    DevicePortForwarder portForwarder,
    int hostPort,
    bool ipv6 = false,
  }) {
    const String kObservatoryService = 'Observatory';
    return new ProtocolDiscovery._(
      logReader, kObservatoryService,
      portForwarder: portForwarder,
      hostPort: hostPort,
      ipv6: ipv6,
    );
  }

  final DeviceLogReader logReader;
  final String serviceName;
  final DevicePortForwarder portForwarder;
  final int hostPort;
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
      final int actualDevicePort = deviceUri.port;
      final int actualHostPort = await portForwarder.forward(actualDevicePort, hostPort: hostPort);
      printTrace('Forwarded host port $actualHostPort to device port $actualDevicePort for $serviceName');
      hostUri = deviceUri.replace(port: actualHostPort);
    }

    assert(new InternetAddress(hostUri.host).isLoopback);
    if (ipv6) {
      hostUri = hostUri.replace(host: InternetAddress.loopbackIPv6.host);
    }

    return hostUri;
  }
}
