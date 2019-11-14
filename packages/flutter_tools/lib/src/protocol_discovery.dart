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
    this.throttleTimeInMilliseconds,
    this.hostPort,
    this.devicePort,
    this.ipv6,
  }) : assert(logReader != null)
  {
    _deviceLogSubscription = logReader.logLines.listen(
      _handleLine,
      onDone: _stopScrapingLogs,
    );
    _uriStreamController = StreamController<Uri>.broadcast();
  }

  factory ProtocolDiscovery.observatory(
    DeviceLogReader logReader, {
    DevicePortForwarder portForwarder,
    int throttleTimeInMilliseconds = 200,
    @required int hostPort,
    @required int devicePort,
    @required bool ipv6,
  }) {
    const String kObservatoryService = 'Observatory';
    return ProtocolDiscovery._(
      logReader,
      kObservatoryService,
      portForwarder: portForwarder,
      throttleTimeInMilliseconds: throttleTimeInMilliseconds,
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

  /// The time to wait before forwarding observatory URIs from [logReader].
  final int throttleTimeInMilliseconds;

  StreamSubscription<String> _deviceLogSubscription;

  StreamController<Uri> _uriStreamController;

  /// The discovered service URI.
  /// Use [uris] instead.
  // TODO(egarciad): replace `uri` for `uris`.
  Future<Uri> get uri async {
    try {
      return await uris.first;
    } on StateError {
      // If the stream is closed and empty.
      return null;
    }
  }

  /// The discovered service URI stream.
  ///
  /// Port forwarding is only attempted when this is invoked, in case we never
  /// need to port forward.
  ///
  /// Dependending on the lifespan of the app running the observatory,
  /// a new observatory URI may be assigned to the app.
  Stream<Uri> get uris {
    return _uriStreamController.stream
      .transform(_throttle<Uri>(
        timeInMilliseconds: throttleTimeInMilliseconds,
      ))
      .asyncMap<Uri>((Uri observatoryUri) async {
        return await _forwardPort(observatoryUri);
      });
  }

  Future<void> cancel() => _stopScrapingLogs();

  Future<void> _stopScrapingLogs() async {
    await _uriStreamController?.close();
    await _deviceLogSubscription?.cancel();
    _deviceLogSubscription = null;
  }

  Match _getPatternMatch(String line) {
    final RegExp r = RegExp('${RegExp.escape(serviceName)} listening on ((http|\/\/)[a-zA-Z0-9:/=_\\-\.\\[\\]]+)');
    return r.firstMatch(line);
  }

  Uri _getObservatoryUri(String line) {
    final Match match = _getPatternMatch(line);
    if (match != null) {
      return Uri.parse(match[1]);
    }
    return null;
  }

  void _handleLine(String line) {
    Uri uri;
    try {
      uri = _getObservatoryUri(line);
    } on FormatException catch(error, stackTrace) {
      _uriStreamController.addError(error, stackTrace);
    }
    if (uri == null) {
      return;
    }
    if (devicePort != null && uri.port != devicePort) {
      printTrace('skipping potential observatory $uri due to device port mismatch');
      return;
    }
    _uriStreamController.add(uri);
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

/// Throttles a stream by [timeInMilliseconds].
StreamTransformer<S, S> _throttle<S>({
  @required int timeInMilliseconds,
}) {
  assert(timeInMilliseconds != null);
  S latestLine;
  int lastExecution;
  Future<void> throttleFuture;

  return StreamTransformer<S, S>
    .fromHandlers(
      handleData: (S value, EventSink<S> sink) {
        latestLine = value;

        final int currentTime = DateTime.now().millisecondsSinceEpoch;
        lastExecution ??= currentTime;
        final int remainingTime = currentTime - lastExecution;
        final int nextExecutionTime = remainingTime > timeInMilliseconds
          ? 0
          : timeInMilliseconds - remainingTime;
        throttleFuture ??= Future<void>
          .delayed(Duration(milliseconds: nextExecutionTime))
          .whenComplete(() {
            sink.add(latestLine);
            throttleFuture = null;
            lastExecution = DateTime.now().millisecondsSinceEpoch;
          });
      }
    );
}
