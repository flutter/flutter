// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';

import '../base/io.dart';
import '../base/logger.dart';
import '../device.dart';
import '../protocol_discovery.dart';
import '../reporting/reporting.dart';

typedef VmServiceConnector = Future<VmService> Function(String, {Log log});

/// A protocol for discovery of a vmservice on an attached iOS device with
/// multiple fallbacks.
///
/// First, it tries to discover a vmservice by assigning a
/// specific port and then attempt to connect. This may fail if the port is
/// not available. This port value should be either random, or otherwise
/// generated with application specific input. This reduces the chance of
/// accidentally connecting to another running flutter application.
///
/// If that does not work, attempt to scan logs from the attached debugger
/// and parse the connected port logged by the engine.
class FallbackDiscovery {
  FallbackDiscovery({
    @required DevicePortForwarder portForwarder,
    @required Logger logger,
    @required ProtocolDiscovery protocolDiscovery,
    @required Usage flutterUsage,
    @required VmServiceConnector vmServiceConnectUri,
    Duration pollingDelay,
  }) : _logger = logger,
       _portForwarder = portForwarder,
       _protocolDiscovery = protocolDiscovery,
       _flutterUsage = flutterUsage,
       _vmServiceConnectUri = vmServiceConnectUri,
       _pollingDelay = pollingDelay ?? const Duration(seconds: 2);

  static const String _kEventName = 'ios-handshake';

  final DevicePortForwarder _portForwarder;
  final Logger _logger;
  final ProtocolDiscovery _protocolDiscovery;
  final Usage _flutterUsage;
  final VmServiceConnector  _vmServiceConnectUri;
  final Duration _pollingDelay;

  /// Attempt to discover the observatory port.
  Future<Uri> discover({
    @required int assumedDevicePort,
    @required String packageId,
    @required Device device,
    @required bool usesIpv6,
    @required int hostVmservicePort,
    @required String packageName,
  }) async {
    final Uri result = await _attemptServiceConnection(
      assumedDevicePort: assumedDevicePort,
      hostVmservicePort: hostVmservicePort,
      packageName: packageName,
    );
    if (result != null) {
      return result;
    }

    try {
      final Uri result = await _protocolDiscovery.uri;
      if (result != null) {
        UsageEvent(
          _kEventName,
          'log-success',
          flutterUsage: _flutterUsage,
        ).send();
        return result;
      }
    } on ArgumentError {
      // In the event of an invalid InternetAddress, this code attempts to catch
      // an ArgumentError from protocol_discovery.dart
    } on Exception catch (err) {
      _logger.printTrace(err.toString());
    }
    _logger.printTrace('Failed to connect with log scanning');
    UsageEvent(
      _kEventName,
      'log-failure',
      flutterUsage: _flutterUsage,
    ).send();

    return null;
  }

  // Attempt to connect to the VM service and find an isolate with a matching `packageName`.
  // Returns `null` if no connection can be made.
  Future<Uri> _attemptServiceConnection({
    @required int assumedDevicePort,
    @required int hostVmservicePort,
    @required String packageName,
  }) async {
    int hostPort;
    Uri assumedWsUri;
    try {
      hostPort = await _portForwarder.forward(
        assumedDevicePort,
        hostPort: hostVmservicePort,
      );
      assumedWsUri = Uri.parse('ws://localhost:$hostPort/ws');
    } on Exception catch (err) {
      _logger.printTrace(err.toString());
      _logger.printTrace('Failed to connect directly, falling back to log scanning');
      _sendFailureEvent(err, assumedDevicePort);
      return null;
    }

    // Attempt to connect to the VM service 5 times.
    int attempts = 0;
    Exception firstException;
    VmService vmService;
    while (attempts < 5) {
      try {
        vmService = await _vmServiceConnectUri(
          assumedWsUri.toString(),
        );
        final VM vm = await vmService.getVM();
        for (final IsolateRef isolateRefs in vm.isolates) {
          final Isolate isolateResponse = await vmService.getIsolate(
            isolateRefs.id,
          );
          final LibraryRef library = isolateResponse.rootLib;
          if (library != null &&
             (library.uri.startsWith('package:$packageName') ||
              library.uri.startsWith(RegExp(r'file:\/\/\/.*\/' + packageName)))) {
            UsageEvent(
              _kEventName,
              'success',
              flutterUsage: _flutterUsage,
            ).send();

            // This vmService instance must be disposed of, otherwise DDS will
            // fail to start.
            vmService.dispose();
            return Uri.parse('http://localhost:$hostPort');
          }
        }
      } on Exception catch (err) {
        // No action, we might have failed to connect.
        firstException ??= err;
        _logger.printTrace(err.toString());
      } finally {
        // This vmService instance must be disposed of, otherwise DDS will
        // fail to start.
        vmService?.dispose();
      }

      // No exponential backoff is used here to keep the amount of time the
      // tool waits for a connection to be reasonable. If the vmservice cannot
      // be connected to in this way, the mDNS discovery must be reached
      // sooner rather than later.
      await Future<void>.delayed(_pollingDelay);
      attempts += 1;
    }
    _logger.printTrace('Failed to connect directly, falling back to log scanning');
    _sendFailureEvent(firstException, assumedDevicePort);
    return null;
  }

  void _sendFailureEvent(Exception err, int assumedDevicePort) {
    String eventAction;
    String eventLabel;
    if (err == null) {
      eventAction = 'failure-attempts-exhausted';
      eventLabel = assumedDevicePort.toString();
    } else if (err is HttpException) {
      eventAction = 'failure-http';
      eventLabel = '${err.message}, device port = $assumedDevicePort';
    } else {
      eventAction = 'failure-other';
      eventLabel = '$err, device port = $assumedDevicePort';
    }
    UsageEvent(
      _kEventName,
      eventAction,
      label: eventLabel,
      flutterUsage: _flutterUsage,
    ).send();
  }
}
