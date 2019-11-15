// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

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
    this.devicePort,
    this.ipv6,
  }) : assert(logReader != null) {
    _deviceLogSubscription = logReader.logLines.listen(_handleLine);
  }

  factory ProtocolDiscovery.observatory(
    DeviceLogReader logReader, {
    DevicePortForwarder portForwarder,
    @required int hostPort,
    @required int devicePort,
    @required bool ipv6,
  }) {
    const String kObservatoryService = 'Observatory';
    return ProtocolDiscovery._(
      logReader,
      kObservatoryService,
      portForwarder: portForwarder,
      hostPort: hostPort,
      devicePort: devicePort,
      ipv6: ipv6,
    );
  }

  final DeviceLogReader logReader;
  final String serviceName;
  final DevicePortForwarder portForwarder;
  final int hostPort;
  final int devicePort;
  final bool ipv6;

  final Completer<Uri> _completer = Completer<Uri>();

  StreamSubscription<String> _deviceLogSubscription;

  /// The discovered service URI.
  ///
  /// Port forwarding is only attempted when this is invoked, in case we never
  /// need to port forward.
  Future<Uri> get uri async {
    final Uri rawUri = await _completer.future;
    return await _forwardPort(rawUri);
  }

  Future<void> cancel() => _stopScrapingLogs();

  Future<void> _stopScrapingLogs() async {
    await _deviceLogSubscription?.cancel();
    _deviceLogSubscription = null;
  }

  void _handleLine(String line) {
    Uri uri;
    final RegExp r = RegExp('${RegExp.escape(serviceName)} listening on ((http|\/\/)[a-zA-Z0-9:/=_\\-\.\\[\\]]+)');
    final Match match = r.firstMatch(line);

    if (match != null) {
      try {
        uri = Uri.parse(match[1]);
      } on FormatException catch (error, stackTrace) {
        _stopScrapingLogs();
        _completer.completeError(error, stackTrace);
      }
    }
    if (uri == null) {
      return;
    }
    if (devicePort != null  &&  uri.port != devicePort) {
      printTrace('skipping potential observatory $uri due to device port mismatch');
      return;
    }

    assert(!_completer.isCompleted);
    _stopScrapingLogs();
    _completer.complete(uri);
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

    assert(InternetAddress(hostUri.host).isLoopback);
    if (ipv6) {
      hostUri = hostUri.replace(host: InternetAddress.loopbackIPv6.host);
    }

    return hostUri;
  }
}
