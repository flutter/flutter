// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/common.dart';
import 'base/os.dart';
import 'device.dart';
import 'globals.dart';

/// Discover service protocol on a device
/// and forward the service protocol device port to the host.
class ProtocolDiscovery {
  /// [logReader] - a [DeviceLogReader] to look for service messages in.
  ProtocolDiscovery(DeviceLogReader logReader, String serviceName,
      {this.portForwarder, this.hostPort, this.defaultHostPort})
      : _logReader = logReader, _serviceName = serviceName {
    assert(_logReader != null);
    _subscription = _logReader.logLines.listen(_onLine);
    assert(portForwarder == null || defaultHostPort != null);
  }

  factory ProtocolDiscovery.observatory(DeviceLogReader logReader,
          {DevicePortForwarder portForwarder, int hostPort}) =>
      new ProtocolDiscovery(logReader, kObservatoryService,
          portForwarder: portForwarder,
          hostPort: hostPort,
          defaultHostPort: kDefaultObservatoryPort);

  factory ProtocolDiscovery.diagnosticService(DeviceLogReader logReader,
          {DevicePortForwarder portForwarder, int hostPort}) =>
      new ProtocolDiscovery(logReader, kDiagnosticService,
          portForwarder: portForwarder,
          hostPort: hostPort,
          defaultHostPort: kDefaultDiagnosticPort);

  static const String kObservatoryService = 'Observatory';
  static const String kDiagnosticService = 'Diagnostic server';

  final DeviceLogReader _logReader;
  final String _serviceName;
  final DevicePortForwarder portForwarder;
  int hostPort;
  final int defaultHostPort;

  Completer<Uri> _completer = new Completer<Uri>();
  StreamSubscription<String> _subscription;

  /// The [Future] returned by this function will complete when the next service
  /// Uri is found.
  Future<Uri> nextUri() async {
    Uri deviceUri = await _completer.future.timeout(
      const Duration(seconds: 60), onTimeout: () {
        throwToolExit('Timeout while attempting to retrieve Uri for $_serviceName');
      }
    );
    printTrace('$_serviceName Uri on device: $deviceUri');
    Uri hostUri;
    if (portForwarder != null) {
      int devicePort = deviceUri.port;
      hostPort ??= await findPreferredPort(defaultHostPort);
      hostPort = await portForwarder
          .forward(devicePort, hostPort: hostPort)
          .timeout(const Duration(seconds: 60), onTimeout: () {
            throwToolExit('Timeout while atempting to foward device port $devicePort for $_serviceName');
          });
      printTrace('Forwarded host port $hostPort to device port $devicePort for $_serviceName');
      hostUri = deviceUri.replace(port: hostPort);
    } else {
      hostUri = deviceUri;
    }
    return hostUri;
  }

  void cancel() {
    _subscription.cancel();
  }

  void _onLine(String line) {
    Uri uri;
    String prefix = '$_serviceName listening on ';
    int index = line.indexOf(prefix + 'http://');
    if (index >= 0) {
      try {
        uri = Uri.parse(line.substring(index + prefix.length));
      } catch (_) {
        // Ignore errors.
      }
    }
    if (uri != null)
      _located(uri);
  }

  void _located(Uri uri) {
    assert(_completer != null);
    assert(!_completer.isCompleted);

    _completer.complete(uri);
    _completer = new Completer<Uri>();
  }
}
