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
  }) {
    _configureLogging(logger);
  }

  static const String kFlutterDevicesService = '_flutter_devices._tcp';

  final Device device;
  final vmservice.VmService vmService;
  final DebuggingOptions debuggingOptions;
  final Logger logger;
  final Platform platform;
  final FlutterVersion flutterVersion;
  final SystemClock systemClock;
  final BotDetector botDetector;

  static bool _loggingConfigured = false;

  static void _configureLogging(Logger logger) {
    if (_loggingConfigured) {
      return;
    }
    // Silence mDNS logs unless verbose logging is enabled.
    // package:mdns_dart uses the 'mdns_dart' logger.
    log.hierarchicalLoggingEnabled = true;
    log.Logger('mdns_dart').level = logger.isVerbose ? log.Level.ALL : log.Level.SEVERE;
    _loggingConfigured = true;
  }

  final _servers = <MDNSServer>[];

  /// Advertises the Flutter application via mDNS.
  ///
  /// The advertisement includes metadata about the application, device, and environment.
  Future<void> advertise({required String appName, required Uri? vmServiceUri}) async {
    try {
      if (_servers.isNotEmpty) {
        throw StateError(
          'mDNS advertisement is already active. Call stop() before starting a new advertisement.',
        );
      }

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

      final ips = <InternetAddress>[InternetAddress.loopbackIPv4, InternetAddress.loopbackIPv6];
      final String hostname = platform.localHostname;
      final TargetPlatform targetPlatform = await device.targetPlatform;
      final String frameworkVersion = flutterVersion.frameworkVersion;
      final String dartVersion = flutterVersion.dartSdkVersion;

      final observation = MDNSObservation(
        wsUri: vmServiceUri.toString(),
        hostname: hostname,
        deviceName: device.name,
        targetPlatform: getNameForTargetPlatform(targetPlatform),
        mode: debuggingOptions.buildInfo.modeName,
        epoch: systemClock.now().millisecondsSinceEpoch,
        projectName: appName,
        deviceId: device.id,
        flutterVersion: frameworkVersion,
        dartVersion: dartVersion,
        pid: pid,
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
    // Create a copy of the list so that the original list can be cleared
    // immediately to prevent re-entrant calls.
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
class MDNSObservation {
  MDNSObservation({
    required this.hostname,
    required this.projectName,
    required this.deviceName,
    required this.deviceId,
    required this.targetPlatform,
    required this.mode,
    required this.wsUri,
    required this.epoch,
    required this.pid,
    required this.flutterVersion,
    required this.dartVersion,
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

  final String hostname;
  final String projectName;
  final String deviceName;
  final String deviceId;
  final String targetPlatform;
  final String mode;
  final String wsUri;
  final int epoch;
  final int pid;
  final String flutterVersion;
  final String dartVersion;

  /// Parses a raw TXT record string into an [MDNSObservation].
  ///
  /// Returns `null` if the record is empty or invalid.
  static MDNSObservation? parse(String txtRecord) {
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

    final int? epoch = int.tryParse(metadata[_kEpoch] ?? '');
    final int? pid = int.tryParse(metadata[_kPid] ?? '');

    if (metadata case {
      _kHostname: final String hostname,
      _kProjectName: final String projectName,
      _kDeviceName: final String deviceName,
      _kDeviceId: final String deviceId,
      _kTargetPlatform: final String targetPlatform,
      _kMode: final String mode,
      _kWsUri: final String wsUri,
      _kFlutterVersion: final String flutterVersion,
      _kDartVersion: final String dartVersion,
    } when epoch != null && pid != null) {
      return MDNSObservation(
        hostname: hostname,
        projectName: projectName,
        deviceName: deviceName,
        deviceId: deviceId,
        targetPlatform: targetPlatform,
        mode: mode,
        wsUri: wsUri,
        epoch: epoch,
        pid: pid,
        flutterVersion: flutterVersion,
        dartVersion: dartVersion,
      );
    }

    return null;
  }

  /// Converts the observation to a list of strings for mDNS TXT record.
  List<String> toTxtRecord() {
    return <String>[
      '$_kHostname=$hostname',
      '$_kWsUri=$wsUri',
      '$_kPid=$pid',
      '$_kTargetPlatform=$targetPlatform',
      '$_kMode=$mode',
      '$_kEpoch=$epoch',
      '$_kProjectName=$projectName',
      '$_kDeviceName=$deviceName',
      '$_kDeviceId=$deviceId',
      '$_kFlutterVersion=$flutterVersion',
      '$_kDartVersion=$dartVersion',
    ];
  }

  Map<String, String> toJson() {
    return <String, String>{
      _kHostname: hostname,
      _kProjectName: projectName,
      _kDeviceName: deviceName,
      _kDeviceId: deviceId,
      _kTargetPlatform: targetPlatform,
      _kMode: mode,
      _kWsUri: wsUri,
      _kEpoch: epoch.toString(),
      _kPid: pid.toString(),
      _kFlutterVersion: flutterVersion,
      _kDartVersion: dartVersion,
    };
  }
}
