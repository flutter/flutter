// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';

import '../base/io.dart';
import '../base/logger.dart';
import '../device.dart';
import '../mdns_discovery.dart';
import '../protocol_discovery.dart';
import '../reporting/reporting.dart';

typedef VmServiceConnector = Future<VmService> Function(String, {Log log});

/// A protocol for discovery of a vmservice on an attached iOS device with
/// multiple fallbacks.
///
/// On versions of iOS 13 and greater, libimobiledevice can no longer listen to
/// logs directly. The only way to discover an active observatory is through the
/// mDNS protocol. However, there are a number of circumstances where this breaks
/// down, such as when the device is connected to certain wifi networks or with
/// certain hotspot connections enabled.
///
/// Another approach to discover a vmservice is to attempt to assign a
/// specific port and then attempt to connect. This may fail if the port is
/// not available. This port value should be either random, or otherwise
/// generated with application specific input. This reduces the chance of
/// accidentally connecting to another running flutter application.
///
/// Finally, if neither of the above approaches works, we can still attempt
/// to parse logs.
///
/// To improve the overall resilience of the process, this class combines the
/// three discovery strategies. First it assigns a port and attempts to connect.
/// Then if this fails it falls back to mDNS, then finally attempting to scan
/// logs.
class FallbackDiscovery {
  FallbackDiscovery({
    @required DevicePortForwarder portForwarder,
    @required MDnsObservatoryDiscovery mDnsObservatoryDiscovery,
    @required Logger logger,
    @required ProtocolDiscovery protocolDiscovery,
    @required Usage flutterUsage,
    @required VmServiceConnector vmServiceConnectUri,
    Duration pollingDelay,
  }) : _logger = logger,
       _mDnsObservatoryDiscovery = mDnsObservatoryDiscovery,
       _portForwarder = portForwarder,
       _protocolDiscovery = protocolDiscovery,
       _flutterUsage = flutterUsage,
       _vmServiceConnectUri = vmServiceConnectUri,
       _pollingDelay = pollingDelay ?? const Duration(seconds: 2);

  static const String _kEventName = 'ios-handshake';

  final DevicePortForwarder _portForwarder;
  final MDnsObservatoryDiscovery _mDnsObservatoryDiscovery;
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
      final Uri result = await _mDnsObservatoryDiscovery.getObservatoryUri(
        packageId,
        device,
        usesIpv6: usesIpv6,
        hostVmservicePort: hostVmservicePort,
      );
      if (result != null) {
        UsageEvent(
          _kEventName,
          'mdns-success',
          flutterUsage: _flutterUsage,
        ).send();
        return result;
      }
    } on Exception catch (err) {
      _logger.printTrace(err.toString());
    }
    _logger.printTrace('Failed to connect with mDNS, falling back to log scanning');
    UsageEvent(
      _kEventName,
      'mdns-failure',
      flutterUsage: _flutterUsage,
    ).send();

    try {
      final Uri result = await _protocolDiscovery.uri;
      if (result != null) {
        UsageEvent(
          _kEventName,
          'fallback-success',
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
      'fallback-failure',
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
      _logger.printTrace('Failed to connect directly, falling back to mDNS');
      _sendFailureEvent(err, assumedDevicePort);
      return null;
    }

    // Attempt to connect to the VM service 5 times.
    int attempts = 0;
    Exception firstException;
    while (attempts < 5) {
      try {
        final VmService vmService = await _vmServiceConnectUri(
          assumedWsUri.toString(),
        );
        final VM vm = await vmService.getVM();
        for (final IsolateRef isolateRefs in vm.isolates) {
          final Isolate isolateResponse = await vmService.getIsolate(
            isolateRefs.id,
          );
          final LibraryRef library = isolateResponse.rootLib;
          if (library != null && library.uri.startsWith('package:$packageName')) {
            UsageEvent(
              _kEventName,
              'success',
              flutterUsage: _flutterUsage,
            ).send();

            // We absolutely must dispose this vmService instance, otherwise
            // DDS will fail to start.
            vmService.dispose();
            return Uri.parse('http://localhost:$hostPort');
          }
        }
      } on Exception catch (err) {
        // No action, we might have failed to connect.
        firstException ??= err;
        _logger.printTrace(err.toString());
      }

      // No exponential backoff is used here to keep the amount of time the
      // tool waits for a connection to be reasonable. If the vmservice cannot
      // be connected to in this way, the mDNS discovery must be reached
      // sooner rather than later.
      await Future<void>.delayed(_pollingDelay);
      attempts += 1;
    }
    _logger.printTrace('Failed to connect directly, falling back to mDNS');
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
