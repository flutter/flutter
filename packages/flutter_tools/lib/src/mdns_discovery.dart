// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';
import 'package:multicast_dns/multicast_dns.dart';

import 'base/common.dart';
import 'base/context.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'device.dart';
import 'reporting/reporting.dart';

/// A wrapper around [MDnsClient] to find a Dart observatory instance.
class MDnsObservatoryDiscovery {
  /// Creates a new [MDnsObservatoryDiscovery] object.
  ///
  /// The [_client] parameter will be defaulted to a new [MDnsClient] if null.
  /// The [applicationId] parameter may be null, and can be used to
  /// automatically select which application to use if multiple are advertising
  /// Dart observatory ports.
  MDnsObservatoryDiscovery({
    MDnsClient mdnsClient,
    @required Logger logger,
    @required Usage flutterUsage,
  }): _client = mdnsClient ?? MDnsClient(),
      _logger = logger,
      _flutterUsage = flutterUsage;

  final MDnsClient _client;
  final Logger _logger;
  final Usage _flutterUsage;

  @visibleForTesting
  static const String dartObservatoryName = '_dartobservatory._tcp.local';

  static MDnsObservatoryDiscovery get instance => context.get<MDnsObservatoryDiscovery>();

  /// Executes an mDNS query for a Dart Observatory.
  ///
  /// The [applicationId] parameter may be used to specify which application
  /// to find.  For Android, it refers to the package name; on iOS, it refers to
  /// the bundle ID.
  ///
  /// If it is not null, this method will find the port and authentication code
  /// of the Dart Observatory for that application. If it cannot find a Dart
  /// Observatory matching that application identifier, it will call
  /// [throwToolExit].
  ///
  /// If it is null and there are multiple ports available, the user will be
  /// prompted with a list of available observatory ports and asked to select
  /// one.
  ///
  /// If it is null and there is only one available instance of Observatory,
  /// it will return that instance's information regardless of what application
  /// the Observatory instance is for.
  @visibleForTesting
  Future<MDnsObservatoryDiscoveryResult> query({String applicationId, int deviceVmservicePort}) async {
    _logger.printTrace('Checking for advertised Dart observatories...');
    try {
      await _client.start();
      final List<PtrResourceRecord> pointerRecords = await _client
        .lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer(dartObservatoryName),
        )
        .toList();
      if (pointerRecords.isEmpty) {
        _logger.printTrace('No pointer records found.');
        return null;
      }
      // We have no guarantee that we won't get multiple hits from the same
      // service on this.
      final Set<String> uniqueDomainNames = pointerRecords
        .map<String>((PtrResourceRecord record) => record.domainName)
        .toSet();

      String domainName;
      if (applicationId != null) {
        for (final String name in uniqueDomainNames) {
          if (name.toLowerCase().startsWith(applicationId.toLowerCase())) {
            domainName = name;
            break;
          }
        }
        if (domainName == null) {
          throwToolExit('Did not find a observatory port advertised for $applicationId.');
        }
      } else if (uniqueDomainNames.length > 1) {
        final StringBuffer buffer = StringBuffer();
        buffer.writeln('There are multiple observatory ports available.');
        buffer.writeln('Rerun this command with one of the following passed in as the appId:');
        buffer.writeln('');
        for (final String uniqueDomainName in uniqueDomainNames) {
          buffer.writeln('  flutter attach --app-id ${uniqueDomainName.replaceAll('.$dartObservatoryName', '')}');
        }
        throwToolExit(buffer.toString());
      } else {
        domainName = pointerRecords[0].domainName;
      }
      _logger.printTrace('Checking for available port on $domainName');
      // Here, if we get more than one, it should just be a duplicate.
      final List<SrvResourceRecord> srv = await _client
        .lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(domainName),
        )
        .toList();
      if (srv.isEmpty) {
        return null;
      }
      if (srv.length > 1) {
        _logger.printError('Unexpectedly found more than one observatory report for $domainName '
                   '- using first one (${srv.first.port}).');
      }
      _logger.printTrace('Checking for authentication code for $domainName');
      final List<TxtResourceRecord> txt = await _client
        .lookup<TxtResourceRecord>(
            ResourceRecordQuery.text(domainName),
        )
        ?.toList();
      if (txt == null || txt.isEmpty) {
        return MDnsObservatoryDiscoveryResult(srv.first.port, '');
      }
      const String authCodePrefix = 'authCode=';
      final String raw = txt.first.text.split('\n').firstWhere(
        (String s) => s.startsWith(authCodePrefix),
        orElse: () => null,
      );
      if (raw == null) {
        return MDnsObservatoryDiscoveryResult(srv.first.port, '');
      }
      String authCode = raw.substring(authCodePrefix.length);
      // The Observatory currently expects a trailing '/' as part of the
      // URI, otherwise an invalid authentication code response is given.
      if (!authCode.endsWith('/')) {
        authCode += '/';
      }
      return MDnsObservatoryDiscoveryResult(srv.first.port, authCode);
    } finally {
      _client.stop();
    }
  }

  Future<Uri> getObservatoryUri(String applicationId, Device device, {
    bool usesIpv6 = false,
    int hostVmservicePort,
    int deviceVmservicePort,
  }) async {
    final MDnsObservatoryDiscoveryResult result = await query(
      applicationId: applicationId,
      deviceVmservicePort: deviceVmservicePort,
    );
    if (result == null) {
      await _checkForIPv4LinkLocal(device);
      return null;
    }

    final String host = usesIpv6
      ? InternetAddress.loopbackIPv6.address
      : InternetAddress.loopbackIPv4.address;
    return buildObservatoryUri(
      device,
      host,
      result.port,
      hostVmservicePort,
      result.authCode,
    );
  }

  // If there's not an ipv4 link local address in `NetworkInterfaces.list`,
  // then request user interventions with a `printError()` if possible.
  Future<void> _checkForIPv4LinkLocal(Device device) async {
    _logger.printTrace(
      'mDNS query failed. Checking for an interface with a ipv4 link local address.'
    );
    final List<NetworkInterface> interfaces = await listNetworkInterfaces(
      includeLinkLocal: true,
      type: InternetAddressType.IPv4,
    );
    if (_logger.isVerbose) {
      _logInterfaces(interfaces);
    }
    final bool hasIPv4LinkLocal = interfaces.any(
      (NetworkInterface interface) => interface.addresses.any(
        (InternetAddress address) => address.isLinkLocal,
      ),
    );
    if (hasIPv4LinkLocal) {
      _logger.printTrace('An interface with an ipv4 link local address was found.');
      return;
    }
    final TargetPlatform targetPlatform = await device.targetPlatform;
    switch (targetPlatform) {
      case TargetPlatform.ios:
        UsageEvent('ios-mdns', 'no-ipv4-link-local', flutterUsage: _flutterUsage).send();
        _logger.printError(
          'The mDNS query for an attached iOS device failed. It may '
          'be necessary to disable the "Personal Hotspot" on the device, and '
          'to ensure that the "Disable unless needed" setting is unchecked '
          'under System Preferences > Network > iPhone USB. '
          'See https://github.com/flutter/flutter/issues/46698 for details.'
        );
        break;
      default:
        _logger.printTrace('No interface with an ipv4 link local address was found.');
        break;
    }
  }

  void _logInterfaces(List<NetworkInterface> interfaces) {
    for (final NetworkInterface interface in interfaces) {
      if (_logger.isVerbose) {
        _logger.printTrace('Found interface "${interface.name}":');
        for (final InternetAddress address in interface.addresses) {
          final String linkLocal = address.isLinkLocal ? 'link local' : '';
          _logger.printTrace('\tBound address: "${address.address}" $linkLocal');
        }
      }
    }
  }
}

class MDnsObservatoryDiscoveryResult {
  MDnsObservatoryDiscoveryResult(this.port, this.authCode);
  final int port;
  final String authCode;
}

Future<Uri> buildObservatoryUri(
  Device device,
  String host,
  int devicePort, [
  int hostVmservicePort,
  String authCode,
]) async {
  String path = '/';
  if (authCode != null) {
    path = authCode;
  }
  // Not having a trailing slash can cause problems in some situations.
  // Ensure that there's one present.
  if (!path.endsWith('/')) {
    path += '/';
  }
  hostVmservicePort ??= 0;
  final int actualHostPort = hostVmservicePort == 0 ?
    await device.portForwarder.forward(devicePort) :
    hostVmservicePort;
  return Uri(scheme: 'http', host: host, port: actualHostPort, path: path);
}
