// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart' as log;
import 'package:mdns_dart/mdns_dart.dart';
import 'package:vm_service/vm_service.dart' as vmservice;

import 'base/io.dart';
import 'base/logger.dart';
import 'base/net.dart';
import 'base/platform.dart';
import 'base/time.dart';
import 'build_info.dart';
import 'device.dart';
import 'version.dart';

/// Discovers devices via mDNS and advertises the current Flutter application to them.
class MDNSDeviceDiscovery {
  /// Creates a new [MDNSDeviceDiscovery] instance.
  MDNSDeviceDiscovery({
    required this.device,
    required this.vmService,
    required this.debuggingOptions,
    required this.logger,
    required this.platform,
    required this.flutterVersion,
    required this.systemClock,
  });

  final Device device;
  final vmservice.VmService vmService;
  final DebuggingOptions debuggingOptions;
  final Logger logger;
  final Platform platform;
  final FlutterVersion flutterVersion;
  final SystemClock systemClock;

  final _servers = <MDNSServer>[];

  /// Advertises the Flutter application via mDNS.
  ///
  /// The advertisement includes metadata about the application, device, and environment.
  Future<void> advertise({required String appName, required Uri? vmServiceUri}) async {
    try {
      await stop(); // Stop any existing advertisements before starting new ones.

      if (vmServiceUri == null) {
        logger.printTrace('VM Service URI not available, not starting mDNS server.');
        return;
      }
      // Silence mDNS logs unless verbose logging is enabled.
      // mdns_dart uses the 'mdns_dart' logger.
      log.hierarchicalLoggingEnabled = true;
      if (logger.isVerbose) {
        log.Logger('mdns_dart').level = log.Level.ALL;
      } else {
        log.Logger('mdns_dart').level = log.Level.SEVERE;
      }

      final List<InternetAddress> ips = await getLocalInetAddresses();
      final String hostname = platform.localHostname;
      final TargetPlatform targetPlatform = await device.targetPlatform;
      final String frameworkVersion = flutterVersion.frameworkVersion;
      final String dartVersion = flutterVersion.dartSdkVersion;

      final txt = <String>[
        'ws_uri=$vmServiceUri',
        'pid=$pid',
        'hostname=$hostname',
        'target=${device.name}',
        'mode=${debuggingOptions.buildInfo.modeName}',
        'target_platform=${getNameForTargetPlatform(targetPlatform)}',
        'epoch=${systemClock.now().millisecondsSinceEpoch}',
        'project_name=$appName',
        'device_name=${device.name}',
        'device_id=${device.id}',
        'flutter_version=$frameworkVersion',
        'dart_version=$dartVersion',
      ];

      // Advertise on all available interfaces (IPv4 and IPv6).
      for (final ip in ips) {
        try {
          final MDNSService mdnsService = await MDNSService.create(
            instance: 'Flutter Tools on $hostname',
            service: '_flutter_devices._tcp',
            port: await findUnusedPort(),
            ips: <InternetAddress>[ip],
            txt: txt,
          );

          final server = MDNSServer(MDNSServerConfig(zone: mdnsService, reusePort: true));
          await server.start();
          _servers.add(server);
          logger.printTrace(
            'mDNS service started for ${device.name} with appName "$appName" on ${ip.address}',
          );
        } on Exception catch (e) {
          logger.printError('Error starting mDNS server on ${ip.address}: $e');
        }
      }
    } on Exception catch (e) {
      logger.printError('Error getting local IPs or starting mDNS: $e');
    }
  }

  /// Stops the mDNS advertisement.
  Future<void> stop() async {
    for (final MDNSServer server in _servers) {
      try {
        await server.stop();
      } on Exception catch (e) {
        logger.printTrace('Error stopping mDNS server: $e');
      }
    }
    _servers.clear();
  }
}
