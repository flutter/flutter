// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart' as log;
import 'package:mdns_dart/mdns_dart.dart';
import 'package:vm_service/vm_service.dart' as vmservice;

import 'base/bot_detector.dart';
import 'base/io.dart';
import 'base/logger.dart';

import 'base/platform.dart';
import 'base/time.dart';
import 'build_info.dart';
import 'convert.dart';
import 'device.dart';
import 'version.dart';

/// Advertises the current Flutter application to other devices via mDNS.
class MDNSDeviceDiscovery {
  MDNSDeviceDiscovery({
    required this.device,
    required this.vmService,
    required this.debuggingOptions,
    required this.logger,
    required this.platform,
    required this.flutterVersion,
    required this.systemClock,
    required this.botDetector,
  });

  static const String kFlutterDevicesService = '_flutter_devices._tcp';

  final Device device;
  final vmservice.VmService vmService;
  final DebuggingOptions debuggingOptions;
  final Logger logger;
  final Platform platform;
  final FlutterVersion flutterVersion;
  final SystemClock systemClock;
  final BotDetector botDetector;

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

      if (!debuggingOptions.enableLocalDiscovery) {
        logger.printTrace('mDNS local discovery is disabled.');
        return;
      }

      if (await botDetector.isRunningOnBot) {
        logger.printTrace('Running on CI/Bot, not starting mDNS server.');
        return;
      }

      // Silence mDNS logs unless verbose logging is enabled.
      // mdns_dart uses the 'mdns_dart' logger.
      log.hierarchicalLoggingEnabled = true;
      log.Logger('mdns_dart').level = logger.isVerbose ? log.Level.ALL : log.Level.SEVERE;

      final ips = <InternetAddress>[InternetAddress.loopbackIPv4, InternetAddress.loopbackIPv6];
      final String hostname = platform.localHostname;
      final TargetPlatform targetPlatform = await device.targetPlatform;
      final String frameworkVersion = flutterVersion.frameworkVersion;
      final String dartVersion = flutterVersion.dartSdkVersion;

      final observation = MDnsObservation(
        wsUri: vmServiceUri.toString(),
        pid: pid.toString(),
        hostname: hostname,
        deviceName: device.name,
        targetPlatform: getNameForTargetPlatform(targetPlatform),
        mode: debuggingOptions.buildInfo.modeName,
        epoch: systemClock.now().millisecondsSinceEpoch.toString(),
        projectName: appName,
        deviceId: device.id,
        flutterVersion: frameworkVersion,
        dartVersion: dartVersion,
      );

      final List<String> txt = observation.toTxtRecord();

      // Advertise on all available interfaces (IPv4 and IPv6).
      for (final ip in ips) {
        try {
          final MDNSService mdnsService = await MDNSService.create(
            instance: 'Flutter Tools on $hostname',
            service: kFlutterDevicesService,
            port: vmServiceUri.port,
            ips: <InternetAddress>[ip],
            txt: txt,
          );

          final server = MDNSServer(
            MDNSServerConfig(zone: mdnsService, reusePort: true, logger: logger.printTrace),
          );
          try {
            await server.start();
            _servers.add(server);
            logger.printTrace(
              'mDNS service started for ${device.name} with appName "$appName" on ${ip.address}',
            );
          } on Exception catch (e) {
            logger.printError('Error starting mDNS server on ${ip.address}: $e');
            // Ensure we clean up any resources if start partially succeeded.
            // mdns_dart server.start might leave sockets open if it throws.
            try {
              await server.stop();
            } on Exception {
              // Ignore errors during cleanup of failed start.
            }
          }
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
    // Create a copy of the list to avoid ConcurrentModificationError as the list
    // is modified during iteration.
    final serversToStop = List<MDNSServer>.of(_servers);
    _servers.clear();
    await Future.wait<void>(
      serversToStop.map(
        (MDNSServer server) => server.stop().catchError((Object e) {
          logger.printTrace('Error stopping mDNS server: $e');
        }, test: (Object error) => error is Exception),
      ),
    );
  }
}

/// A class representing the metadata discovered from a running Flutter application
/// via mDNS.
class MDnsObservation {
  MDnsObservation({
    this.hostname,
    this.projectName,
    this.deviceName,
    this.deviceId,
    this.targetPlatform,
    this.mode,
    this.wsUri,
    this.epoch,
    this.pid,
    this.flutterVersion,
    this.dartVersion,
  });

  static const String _kProjectName = 'project_name';
  static const String _kDeviceName = 'device_name';
  static const String _kDeviceId = 'device_id';
  static const String _kTargetPlatform = 'target_platform';
  static const String _kMode = 'mode';
  static const String _kWsUri = 'ws_uri';
  static const String _kEpoch = 'epoch';
  static const String _kPid = 'pid';
  static const String _kFlutterVersion = 'flutter_version';
  static const String _kDartVersion = 'dart_version';
  static const String _kHostname = 'hostname';

  final String? hostname;
  final String? projectName;
  final String? deviceName;
  final String? deviceId;
  final String? targetPlatform;
  final String? mode;
  final String? wsUri;
  final String? epoch;
  final String? pid;
  final String? flutterVersion;
  final String? dartVersion;

  /// Parses a raw TXT record string into an [MDnsObservation].
  ///
  /// Returns `null` if the record is empty or invalid.
  static MDnsObservation? parse(String txtRecord) {
    final metadata = <String, String>{};
    // The multicast_dns package joins the strings of a TXT record with newlines.
    final Iterable<String> parts = LineSplitter.split(txtRecord);
    for (final part in parts) {
      final int equalsIndex = part.indexOf('=');
      if (equalsIndex != -1) {
        // Trim to remove any whitespace that may be around the delimiters.
        metadata[part.substring(0, equalsIndex).trim()] = part.substring(equalsIndex + 1).trim();
      }
    }
    if (metadata.isEmpty) {
      return null;
    }

    return MDnsObservation(
      hostname: metadata[_kHostname],
      projectName: metadata[_kProjectName],
      deviceName: metadata[_kDeviceName],
      deviceId: metadata[_kDeviceId],
      targetPlatform: metadata[_kTargetPlatform],
      mode: metadata[_kMode],
      wsUri: metadata[_kWsUri],
      epoch: metadata[_kEpoch],
      pid: metadata[_kPid],
      flutterVersion: metadata[_kFlutterVersion],
      dartVersion: metadata[_kDartVersion],
    );
  }

  /// Converts the observation to a list of strings for mDNS TXT record.
  List<String> toTxtRecord() {
    return <String>[
      if (hostname != null) '$_kHostname=$hostname',
      if (wsUri != null) '$_kWsUri=$wsUri',
      if (pid != null) '$_kPid=$pid',
      if (targetPlatform != null) '$_kTargetPlatform=$targetPlatform',
      if (mode != null) '$_kMode=$mode',
      if (epoch != null) '$_kEpoch=$epoch',
      if (projectName != null) '$_kProjectName=$projectName',
      if (deviceName != null) '$_kDeviceName=$deviceName',
      if (deviceId != null) '$_kDeviceId=$deviceId',
      if (flutterVersion != null) '$_kFlutterVersion=$flutterVersion',
      if (dartVersion != null) '$_kDartVersion=$dartVersion',
    ];
  }

  Map<String, String> toJson() {
    return <String, String>{
      if (hostname != null) _kHostname: hostname!,
      if (projectName != null) _kProjectName: projectName!,
      if (deviceName != null) _kDeviceName: deviceName!,
      if (deviceId != null) _kDeviceId: deviceId!,
      if (targetPlatform != null) _kTargetPlatform: targetPlatform!,
      if (mode != null) _kMode: mode!,
      if (wsUri != null) _kWsUri: wsUri!,
      if (epoch != null) _kEpoch: epoch!,
      if (pid != null) _kPid: pid!,
      if (flutterVersion != null) _kFlutterVersion: flutterVersion!,
      if (dartVersion != null) _kDartVersion: dartVersion!,
    };
  }
}
