// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    MDnsClient? mdnsClient,
    MDnsClient? preliminaryMDnsClient,
    required Logger logger,
    required Usage flutterUsage,
  })  : _client = mdnsClient ?? MDnsClient(),
        _preliminaryClient = preliminaryMDnsClient,
        _logger = logger,
        _flutterUsage = flutterUsage;

  final MDnsClient _client;

  final MDnsClient? _preliminaryClient;

  final Logger _logger;
  final Usage _flutterUsage;

  @visibleForTesting
  static const String dartObservatoryName = '_dartobservatory._tcp.local';

  static MDnsObservatoryDiscovery? get instance => context.get<MDnsObservatoryDiscovery>();

  /// Executes an mDNS query for a Dart Observatory.
  /// Checks for observatories that have already been launched.
  /// If none found, will listen for new observatories to become active
  /// and return first it finds that match parameters.
  ///
  /// The [applicationId] parameter may be used to specify which application
  /// to find. For Android, it refers to the package name; on iOS, it refers to
  /// the bundle ID.
  ///
  /// The [deviceVmservicePort] parameter may be used to specify which port
  /// to find.
  ///
  /// The [isNetworkDevice] parameter flags whether to get the device IP
  /// and the [ipv6] parameter flags whether to get an iPv6 address
  /// (otherwise it will get iPv4).
  ///
  /// The [timeout] parameter determines how long to continue to wait for
  /// observatories to become active.
  ///
  /// If [applicationId] is not null, this method will find the port and authentication code
  /// of the Dart Observatory for that application. If it cannot find a Dart
  /// Observatory matching that application identifier after the [timeout], it will call
  /// [throwToolExit].
  ///
  /// If [applicationId] is null and there are multiple ports available, the user will be
  /// prompted with a list of available observatory ports and asked to select
  /// one.
  ///
  /// If it is null and there is only one available or it's the first found instance
  /// of Observatory, it will return that instance's information regardless of
  /// what application the Observatory instance is for.
  @visibleForTesting
  Future<MDnsObservatoryDiscoveryResult?> queryForAttach({
    String? applicationId,
    int? deviceVmservicePort,
    bool ipv6 = false,
    bool isNetworkDevice = false,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    // Poll for 5 seconds to see if there are already services running.
    // Use a new instance of MDnsClient so result don't get cached in _client.
    // If no results are found, poll for a longer duration to wait for connections.
    // If more than 1 result found, throw an error since we can't determine which to pick.
    // If only one found, return it.
    final List<MDnsObservatoryDiscoveryResult> results = await _pollingObservatory(
      _preliminaryClient ?? MDnsClient(),
      applicationId: applicationId,
      deviceVmservicePort: deviceVmservicePort,
      ipv6: ipv6,
      isNetworkDevice: isNetworkDevice,
      timeout: const Duration(seconds: 5),
    );
    if (results.isEmpty) {
      return firstMatchingObservatory(
        _client,
        applicationId: applicationId,
        deviceVmservicePort: deviceVmservicePort,
        ipv6: ipv6,
        isNetworkDevice: isNetworkDevice,
        timeout: timeout,
      );
    } else if (results.length > 1) {
      final StringBuffer buffer = StringBuffer();
      buffer.writeln('There are multiple observatory ports available.');
      buffer.writeln('Rerun this command with one of the following passed in as the appId:');
      buffer.writeln();
      for (final MDnsObservatoryDiscoveryResult result in results) {
        buffer.writeln(
            '  flutter attach --app-id "${result.domainName.replaceAll('.$dartObservatoryName', '')}" --device-vmservice-port ${result.port}');
      }
      throwToolExit(buffer.toString());
    }
    return results.first;
  }

  /// Executes an mDNS query for a Dart Observatory.
  /// Listens for new observatories to become active
  /// and return first it finds that match parameters.
  ///
  /// The [applicationId] parameter must be set to specify which application
  /// to find. For Android, it refers to the package name; on iOS, it refers to
  /// the bundle ID.
  ///
  /// The [deviceVmservicePort] parameter must be set to specify which port
  /// to find.
  ///
  /// [applicationId] and [deviceVmservicePort] are required for launch so that
  /// if multiple flutter apps are running on different devices, it will
  /// only match with the device running the desired app.
  ///
  /// The [isNetworkDevice] parameter flags whether to get the device IP
  /// and the [ipv6] parameter flags whether to get an iPv6 address
  /// (otherwise it will get iPv4).
  ///
  /// The [timeout] parameter determines how long to continue to wait for
  /// observatories to become active.
  ///
  /// If a Dart Observatory matching the [applicationId] and [deviceVmservicePort]
  /// cannot be found after the [timeout], it will call [throwToolExit].
  @visibleForTesting
  Future<MDnsObservatoryDiscoveryResult?> queryForLaunch({
    required String applicationId,
    required int deviceVmservicePort,
    bool ipv6 = false,
    bool isNetworkDevice = false,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    // Query for a specific application and device port.
    return firstMatchingObservatory(
      _client,
      applicationId: applicationId,
      deviceVmservicePort: deviceVmservicePort,
      ipv6: ipv6,
      isNetworkDevice: isNetworkDevice,
      timeout: timeout,
    );
  }

  // Poll for observatories and return the first it finds that match
  // the [applicationId]/[deviceVmservicePort] (if applicable).
  // Return null if not results are found.
  @visibleForTesting
  Future<MDnsObservatoryDiscoveryResult?> firstMatchingObservatory(
    MDnsClient client, {
    String? applicationId,
    int? deviceVmservicePort,
    bool ipv6 = false,
    bool isNetworkDevice = false,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final List<MDnsObservatoryDiscoveryResult> results = await _pollingObservatory(
      client,
      applicationId: applicationId,
      deviceVmservicePort: deviceVmservicePort,
      ipv6: ipv6,
      isNetworkDevice: isNetworkDevice,
      timeout: timeout,
      quitOnFind: true,
    );
    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }

  Future<List<MDnsObservatoryDiscoveryResult>> _pollingObservatory(
    MDnsClient client, {
    String? applicationId,
    int? deviceVmservicePort,
    bool ipv6 = false,
    bool isNetworkDevice = false,
    required Duration timeout,
    bool quitOnFind = false,
  }) async {
    _logger.printTrace('Checking for advertised Dart observatories...');
    try {
      await client.start();

      final List<MDnsObservatoryDiscoveryResult> results =
          <MDnsObservatoryDiscoveryResult>[];
      final Set<String> uniqueDomainNames = <String>{};

      // Listen for mDNS connections until timeout.
      final Stream<PtrResourceRecord> ptrResourceStream = client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(dartObservatoryName),
        timeout: timeout
      );
      await for (final PtrResourceRecord ptr in ptrResourceStream) {
        uniqueDomainNames.add(ptr.domainName);

        String? domainName;
        if (applicationId != null) {
          // If applicationId is set, we only want to find records that match it
          if (ptr.domainName.toLowerCase().startsWith(applicationId.toLowerCase())) {
            domainName = ptr.domainName;
          } else {
            continue;
          }
        } else {
          domainName = ptr.domainName;
        }

        _logger.printTrace('Checking for available port on $domainName');
        // Here, if we get more than one, it should just be a duplicate.
        final List<SrvResourceRecord> srv = await client
          .lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(domainName),
          )
          .toList();

        if (srv.isEmpty) {
          continue;
        }
        if (srv.length > 1) {
          _logger.printWarning(
              'Unexpectedly found more than one observatory report for $domainName '
              '- using first one (${srv.first.port}).');
        }

        // If deviceVmservicePort is set, we only want to find records that match it
        if (deviceVmservicePort != null && srv.first.port != deviceVmservicePort) {
          continue;
        }

        // Get the IP address of the service if using a network device.
        InternetAddress? ipAddress;
        if (isNetworkDevice) {
          List<IPAddressResourceRecord> ipAddresses = await client
            .lookup<IPAddressResourceRecord>(
              ipv6
                  ? ResourceRecordQuery.addressIPv6(srv.first.target)
                  : ResourceRecordQuery.addressIPv4(srv.first.target),
            )
            .toList();
          if (ipAddresses.isEmpty) {
            throwToolExit('Did not find IP for service ${srv.first.target}.');
          }

          // Filter out link-local addresses.
          if (ipAddresses.length > 1) {
            ipAddresses = ipAddresses.where((IPAddressResourceRecord element) => !element.address.isLinkLocal).toList();
          }

          if (ipAddresses.length > 1) {
            _logger.printWarning(
                'Unexpectedly found more than one IP for observatory for service ${srv.first.target} '
                '- using first one (${ipAddresses.first.address}).');
          }
          ipAddress = ipAddresses.first.address;
        }

        _logger.printTrace('Checking for authentication code for $domainName');
        final List<TxtResourceRecord> txt = await client
          .lookup<TxtResourceRecord>(
              ResourceRecordQuery.text(domainName),
          )
          .toList();
        if (txt == null || txt.isEmpty) {
          results.add(MDnsObservatoryDiscoveryResult(domainName, srv.first.port, ''));
          if (quitOnFind) {
            return results;
          }
          continue;
        }
        const String authCodePrefix = 'authCode=';
        String? raw;
        for (final String record in txt.first.text.split('\n')) {
          if (record.startsWith(authCodePrefix)) {
            raw = record;
            break;
          }
        }
        if (raw == null) {
          results.add(MDnsObservatoryDiscoveryResult(domainName, srv.first.port, ''));
          if (quitOnFind) {
            return results;
          }
          continue;
        }
        String authCode = raw.substring(authCodePrefix.length);
        // The Observatory currently expects a trailing '/' as part of the
        // URI, otherwise an invalid authentication code response is given.
        if (!authCode.endsWith('/')) {
          authCode += '/';
        }

        results.add(MDnsObservatoryDiscoveryResult(
          domainName,
          srv.first.port,
          authCode,
          ipAddress: ipAddress
        ));
        if (quitOnFind) {
          return results;
        }
      }

      // If applicationId is set and quitOnFind is true and no results matching
      // the applicationId were found but other results were found, throw an error.
      if (applicationId != null &&
          quitOnFind &&
          results.isEmpty &&
          uniqueDomainNames.isNotEmpty) {
        String message = 'Did not find an observatory advertised for $applicationId';
        if (deviceVmservicePort != null) {
          message += ' on port $deviceVmservicePort';
        }
        throwToolExit('$message.');
      }

      return results;
    } finally {
      client.stop();
    }
  }

  Future<Uri?> getObservatoryUriForAttach(
    String? applicationId,
    Device device, {
    bool usesIpv6 = false,
    int? hostVmservicePort,
    int? deviceVmservicePort,
    bool isNetworkDevice = false,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final MDnsObservatoryDiscoveryResult? result = await queryForAttach(
      applicationId: applicationId,
      deviceVmservicePort: deviceVmservicePort,
      ipv6: usesIpv6,
      isNetworkDevice: isNetworkDevice,
      timeout: timeout,
    );
    return _handleResult(
      result,
      device,
      applicationId: applicationId,
      deviceVmservicePort: deviceVmservicePort,
      hostVmservicePort: hostVmservicePort,
      usesIpv6: usesIpv6,
      isNetworkDevice: isNetworkDevice
    );
  }

  Future<Uri?> getObservatoryUriForLaunch(
    String applicationId,
    Device device, {
    bool usesIpv6 = false,
    int? hostVmservicePort,
    required int deviceVmservicePort,
    bool isNetworkDevice = false,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final MDnsObservatoryDiscoveryResult? result = await queryForLaunch(
      applicationId: applicationId,
      deviceVmservicePort: deviceVmservicePort,
      ipv6: usesIpv6,
      isNetworkDevice: isNetworkDevice,
      timeout: timeout,
    );
    return _handleResult(
      result,
      device,
      applicationId: applicationId,
      deviceVmservicePort: deviceVmservicePort,
      hostVmservicePort: hostVmservicePort,
      usesIpv6: usesIpv6,
      isNetworkDevice: isNetworkDevice
    );
  }

  Future<Uri?> _handleResult(
    MDnsObservatoryDiscoveryResult? result,
    Device device, {
    String? applicationId,
    int? deviceVmservicePort,
    int? hostVmservicePort,
    bool usesIpv6 = false,
    bool isNetworkDevice = false,
  }) async {
    if (result == null) {
      await _checkForIPv4LinkLocal(device);
      return null;
    }
    final String host;

    final InternetAddress? ipAddress = result.ipAddress;
    if (isNetworkDevice && ipAddress != null) {
      host = ipAddress.address;
    } else {
      host = usesIpv6
      ? InternetAddress.loopbackIPv6.address
      : InternetAddress.loopbackIPv4.address;
    }
    return buildObservatoryUri(
      device,
      host,
      result.port,
      hostVmservicePort,
      result.authCode,
      isNetworkDevice,
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
      case TargetPlatform.android:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
      case TargetPlatform.darwin:
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      case TargetPlatform.linux_arm64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
      case TargetPlatform.windows_x64:
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
  MDnsObservatoryDiscoveryResult(
    this.domainName,
    this.port,
    this.authCode, {
    this.ipAddress
  });
  final String domainName;
  final int port;
  final String authCode;
  final InternetAddress? ipAddress;
}

Future<Uri> buildObservatoryUri(
  Device device,
  String host,
  int devicePort, [
  int? hostVmservicePort,
  String? authCode,
  bool isNetworkDevice = false,
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

  final int? actualHostPort;
  if (isNetworkDevice) {
    // When debugging with a network device, port forwarding is not required
    // so just use the device's port.
    actualHostPort = devicePort;
  } else {
    actualHostPort = hostVmservicePort == 0 ?
    await device.portForwarder?.forward(devicePort) :
    hostVmservicePort;
  }
  return Uri(scheme: 'http', host: host, port: actualHostPort, path: path);
}
