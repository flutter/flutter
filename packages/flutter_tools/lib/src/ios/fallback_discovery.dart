// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/io.dart';
import '../base/logger.dart';
import '../convert.dart';
import '../device.dart';
import '../mdns_discovery.dart';
import '../protocol_discovery.dart';
import '../reporting/reporting.dart';

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
    @required HttpClient httpClient,
  }) : _logger = logger,
       _mDnsObservatoryDiscovery = mDnsObservatoryDiscovery,
       _portForwarder = portForwarder,
       _protocolDiscovery = protocolDiscovery,
       _httpClient = httpClient;

  final DevicePortForwarder _portForwarder;
  final MDnsObservatoryDiscovery _mDnsObservatoryDiscovery;
  final Logger _logger;
  final ProtocolDiscovery _protocolDiscovery;
  final HttpClient _httpClient;

  /// Attempt to discover the observatory port.
  Future<Uri> discover({
    @required int assumedDevicePort,
    @required String packageId,
    @required Device deivce,
    @required bool usesIpv6,
    @required int hostVmservicePort,
  }) async {
    try {
      final int hostPort = await _portForwarder.forward(assumedDevicePort, hostPort: hostVmservicePort);
      final Uri assumedUri = Uri.parse('http://localhost:$hostPort');
      // Attempt to connect to the vmservice with exponential backoff.
      int attempts = 0;
      int delaySeconds = 2;
      while (attempts < 5) {
        // Making a GET request to the forwarded URL should return an HTML
        // response page, though we only care if it is 200 OK. There must
        // be a version method/page that is more easily identifiable? We
        // might otherwise connect to a random server.
        final HttpClientRequest request = await _httpClient.getUrl(assumedUri);
        final HttpClientResponse response = await request.close();
        if (response.statusCode == HttpStatus.ok) {
          final String responseBody = await response.transform(utf8.decoder).join('');
          if (responseBody.contains('Dart')) {
            _httpClient.close();
            UsageEvent('ios-mdns', 'precheck-success').send();
            return assumedUri;
          }
        }
        await Future<void>.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= delaySeconds;
        attempts += 1;
      }
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
