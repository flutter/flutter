// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:meta/meta.dart';

import '../base/logger.dart';
import '../device.dart';
import '../mdns_discovery.dart';
import '../protocol_discovery.dart';

/// A protocol for discovery of a vmservice on an attached iOS device with
/// multiple fallbacks.
///
/// On versions of iOS 13 and greater, libimobile device can no longer listen to
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
/// To improve the overall resillence of the process, this class combines the
/// three discovery strategies. First it assigns a port and attempts to connect.
/// Then if this fails it falls back to mDNS, then finally attempting to scan
/// logs.
class FallbackDiscovery {
  FallbackDiscovery({
    @required DevicePortForwarder portForwarder,
    @required MDnsObservatoryDiscovery mDnsObservatoryDiscovery,
    @required Logger logger,
    @required ProtocolDiscovery protocolDiscovery,
  }) : _logger = logger,
       _mDnsObservatoryDiscovery = mDnsObservatoryDiscovery,
       _portForwarder = portForwarder,
       _protocolDiscovery = protocolDiscovery;

  final DevicePortForwarder _portForwarder;

  final MDnsObservatoryDiscovery _mDnsObservatoryDiscovery;

  final Logger _logger;

  final ProtocolDiscovery _protocolDiscovery;

  /// Attempt to discover the observatory port.
  Future<Uri> discover({
    @required int assumedDevicePort,
    @required String packageId,
    @required Device deivce,
    @required bool usesIpv6,
    @required int hostVmservicePort,
  }) async {
    try {
      // TODO(jonahwilliams): determine if this succeeds even if there is nothing
      // listening.
      final int hostPort = await _portForwarder.forward(assumedDevicePort, hostPort: hostVmservicePort);
      UsageEvent('ios-mdns', 'precheck-success').send();
      return Uri.parse('http://localhost:$hostPort');
    } on Exception {
      UsageEvent('ios-mdns', 'precheck-failure').send();
      _logger.printTrace('Failed to connect directly, falling back to mDNS');
    }
    try {
      final Uri result = await _mDnsObservatoryDiscovery.getObservatoryUri(
        packageId,
        deivce,
        usesIpv6: usesIpv6,
        hostVmservicePort: hostVmservicePort,
      );
      UsageEvent('ios-mdns', 'success').send();
      return result;
    } on Exception {
      _logger.printTrace('Failed to connect with mDNS, falling back to log scanning');
      UsageEvent('ios-mdns', 'failure').send();
    }
    try {
      final Uri result = await _protocolDiscovery.uri;
      UsageEvent('ios-mdns', 'fallback-success').send();
      return result;
    } on Exception {
      _logger.printTrace('Failed to connect with log scanning');
      UsageEvent('ios-mdns', 'fallback-failure').send();
    }
    return null;
  }
}
