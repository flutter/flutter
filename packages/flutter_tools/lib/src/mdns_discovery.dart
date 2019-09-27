// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:multicast_dns/multicast_dns.dart';

import 'base/common.dart';
import 'base/context.dart';
import 'base/io.dart';
import 'device.dart';
import 'globals.dart';

/// A wrapper around [MDnsClient] to find a Dart observatory instance.
class MDnsObservatoryDiscovery {
  /// Creates a new [MDnsObservatoryDiscovery] object.
  ///
  /// The [client] parameter will be defaulted to a new [MDnsClient] if null.
  /// The [applicationId] parameter may be null, and can be used to
  /// automatically select which application to use if multiple are advertising
  /// Dart observatory ports.
  MDnsObservatoryDiscovery({MDnsClient mdnsClient})
    : client = mdnsClient ?? MDnsClient();

  /// The [MDnsClient] used to do a lookup.
  final MDnsClient client;

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
  Future<MDnsObservatoryDiscoveryResult> query({String applicationId}) async {
    printStatus('Checking for advertised Dart observatories...');
    try {
      await client.start();
      final List<PtrResourceRecord> pointerRecords = await client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(dartObservatoryName),
          )
          .toList();
      if (pointerRecords.isEmpty) {
        return null;
      }
      // We have no guarantee that we won't get multiple hits from the same
      // service on this.
      final List<String> uniqueDomainNames = pointerRecords
          .map<String>((PtrResourceRecord record) => record.domainName)
          .toSet()
          .toList();

      String domainName;
      if (applicationId != null) {
        for (String name in uniqueDomainNames) {
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
      printStatus('Checking for available port on $domainName');
      // Here, if we get more than one, it should just be a duplicate.
      final List<SrvResourceRecord> srv = await client
          .lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(domainName),
          )
          .toList();
      if (srv.isEmpty) {
        return null;
      }
      if (srv.length > 1) {
        printError('Unexpectedly found more than one observatory report for $domainName '
                   '- using first one (${srv.first.port}).');
      }
      printStatus('Checking for authentication code for $domainName');
      final List<TxtResourceRecord> txt = await client
        .lookup<TxtResourceRecord>(
            ResourceRecordQuery.text(domainName),
        )
        ?.toList();
      if (txt == null || txt.isEmpty) {
        return MDnsObservatoryDiscoveryResult(srv.first.port, '');
      }
      String authCode = '';
      const String authCodePrefix = 'authCode=';
      String raw = txt.first.text;
      // TXT has a format of [<length byte>, text], so if the length is 2,
      // that means that TXT is empty.
      if (raw.length > 2) {
        // Remove length byte from raw txt.
        raw = raw.substring(1);
        if (raw.startsWith(authCodePrefix)) {
          authCode = raw.substring(authCodePrefix.length);
          // The Observatory currently expects a trailing '/' as part of the
          // URI, otherwise an invalid authentication code response is given.
          if (!authCode.endsWith('/')) {
            authCode += '/';
          }
        }
      }
      return MDnsObservatoryDiscoveryResult(srv.first.port, authCode);
    } finally {
      client.stop();
    }
  }

  Future<Uri> getObservatoryUri(String applicationId, Device device, [bool usesIpv6 = false, int observatoryPort]) async {
    final MDnsObservatoryDiscoveryResult result = await query(applicationId: applicationId);
    Uri observatoryUri;
    if (result != null) {
      final String host = usesIpv6
        ? InternetAddress.loopbackIPv6.address
        : InternetAddress.loopbackIPv4.address;
      observatoryUri = await buildObservatoryUri(device, host, result.port, observatoryPort, result.authCode);
    }
    return observatoryUri;
  }
}

class MDnsObservatoryDiscoveryResult {
  MDnsObservatoryDiscoveryResult(this.port, this.authCode);
  final int port;
  final String authCode;
}

Future<Uri> buildObservatoryUri(Device device,
    String host, int devicePort, [int observatoryPort, String authCode]) async {
  String path = '/';
  if (authCode != null) {
    path = authCode;
  }
  // Not having a trailing slash can cause problems in some situations.
  // Ensure that there's one present.
  if (!path.endsWith('/')) {
    path += '/';
  }
  final int localPort = observatoryPort
      ?? await device.portForwarder.forward(devicePort);
  return Uri(scheme: 'http', host: host, port: localPort, path: path);
}
