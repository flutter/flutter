// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/mdns_discovery.dart';
import 'package:mockito/mockito.dart';
import 'package:multicast_dns/multicast_dns.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('mDNS Discovery', () {
    final int year3000 = DateTime(3000).millisecondsSinceEpoch;

    setUp(() {
      setNetworkInterfaceLister(
        ({
          bool includeLoopback,
          bool includeLinkLocal,
          InternetAddressType type,
        }) async => <NetworkInterface>[],
      );
    });

    tearDown(() {
      resetNetworkInterfaceLister();
    });

    MDnsClient getMockClient(
      List<PtrResourceRecord> ptrRecords,
      Map<String, List<SrvResourceRecord>> srvResponse, {
      Map<String, List<TxtResourceRecord>> txtResponse = const <String, List<TxtResourceRecord>>{},
    }) {
      final MDnsClient client = MockMDnsClient();

      when(client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(MDnsObservatoryDiscovery.dartObservatoryName),
      )).thenAnswer((_) => Stream<PtrResourceRecord>.fromIterable(ptrRecords));

      for (final MapEntry<String, List<SrvResourceRecord>> entry in srvResponse.entries) {
        when(client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(entry.key),
        )).thenAnswer((_) => Stream<SrvResourceRecord>.fromIterable(entry.value));
      }

      for (final MapEntry<String, List<TxtResourceRecord>> entry in txtResponse.entries) {
        when(client.lookup<TxtResourceRecord>(
          ResourceRecordQuery.text(entry.key),
        )).thenAnswer((_) => Stream<TxtResourceRecord>.fromIterable(entry.value));
      }
      return client;
    }

    testUsingContext('No ports available', () async {
      final MDnsClient client = getMockClient(<PtrResourceRecord>[], <String, List<SrvResourceRecord>>{});

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(mdnsClient: client);
      final int port = (await portDiscovery.query())?.port;
      expect(port, isNull);
    });

    testUsingContext('Prints helpful message when there is no ipv4 link local address.', () async {
      final MDnsClient client = getMockClient(<PtrResourceRecord>[], <String, List<SrvResourceRecord>>{});
      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(mdnsClient: client);

      final Uri uri = await portDiscovery.getObservatoryUri(
        '',
        MockIOSDevice(),
      );
      expect(uri, isNull);
      expect(testLogger.errorText, contains('Personal Hotspot'));
    });

    testUsingContext('One port available, no appId', () async {
      final MDnsClient client = getMockClient(
        <PtrResourceRecord>[
          PtrResourceRecord('foo', year3000, domainName: 'bar'),
        ],
        <String, List<SrvResourceRecord>>{
          'bar': <SrvResourceRecord>[
            SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
          ],
        },
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(mdnsClient: client);
      final int port = (await portDiscovery.query())?.port;
      expect(port, 123);
    });

    testUsingContext('One port available, no appId, with authCode', () async {
      final MDnsClient client = getMockClient(
        <PtrResourceRecord>[
          PtrResourceRecord('foo', year3000, domainName: 'bar'),
        ],
        <String, List<SrvResourceRecord>>{
          'bar': <SrvResourceRecord>[
            SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
          ],
        },
        txtResponse: <String, List<TxtResourceRecord>>{
          'bar': <TxtResourceRecord>[
            TxtResourceRecord('bar', year3000, text: 'authCode=xyz\n'),
          ],
        },
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
        mdnsClient: client,
      );
      final MDnsObservatoryDiscoveryResult result = await portDiscovery.query();
      expect(result?.port, 123);
      expect(result?.authCode, 'xyz/');
    });

    testUsingContext('Multiple ports available, without appId', () async {
      final MDnsClient client = getMockClient(
        <PtrResourceRecord>[
          PtrResourceRecord('foo', year3000, domainName: 'bar'),
          PtrResourceRecord('baz', year3000, domainName: 'fiz'),
        ],
        <String, List<SrvResourceRecord>>{
          'bar': <SrvResourceRecord>[
            SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
          ],
          'fiz': <SrvResourceRecord>[
            SrvResourceRecord('fiz', year3000, port: 321, weight: 1, priority: 1, target: 'local'),
          ],
        },
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(mdnsClient: client);
      expect(portDiscovery.query, throwsToolExit());
    });

    testUsingContext('Multiple ports available, with appId', () async {
      final MDnsClient client = getMockClient(
        <PtrResourceRecord>[
          PtrResourceRecord('foo', year3000, domainName: 'bar'),
          PtrResourceRecord('baz', year3000, domainName: 'fiz'),
        ],
        <String, List<SrvResourceRecord>>{
          'bar': <SrvResourceRecord>[
            SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
          ],
          'fiz': <SrvResourceRecord>[
            SrvResourceRecord('fiz', year3000, port: 321, weight: 1, priority: 1, target: 'local'),
          ],
        },
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(mdnsClient: client);
      final int port = (await portDiscovery.query(applicationId: 'fiz'))?.port;
      expect(port, 321);
    });

    testUsingContext('Multiple ports available per process, with appId', () async {
      final MDnsClient client = getMockClient(
        <PtrResourceRecord>[
          PtrResourceRecord('foo', year3000, domainName: 'bar'),
          PtrResourceRecord('baz', year3000, domainName: 'fiz'),
        ],
        <String, List<SrvResourceRecord>>{
          'bar': <SrvResourceRecord>[
            SrvResourceRecord('bar', year3000, port: 1234, weight: 1, priority: 1, target: 'appId'),
            SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
          ],
          'fiz': <SrvResourceRecord>[
            SrvResourceRecord('fiz', year3000, port: 4321, weight: 1, priority: 1, target: 'local'),
            SrvResourceRecord('fiz', year3000, port: 321, weight: 1, priority: 1, target: 'local'),
          ],
        },
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(mdnsClient: client);
      final int port = (await portDiscovery.query(applicationId: 'bar'))?.port;
      expect(port, 1234);
    });

    testUsingContext('Query returns null', () async {
      final MDnsClient client = getMockClient(
        <PtrResourceRecord>[],
         <String, List<SrvResourceRecord>>{},
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(mdnsClient: client);
      final int port = (await portDiscovery.query(applicationId: 'bar'))?.port;
      expect(port, isNull);
    });

    testUsingContext('Throws Exception when client throws OSError on start', () async {
      final MDnsClient client = MockMDnsClient();
      when(client.start()).thenAnswer((_) {
        throw const OSError('Operation not suppoted on socket', 102);
      });

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
        mdnsClient: client,
      );
      expect(
        () async => await portDiscovery.query(),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class MockMDnsClient extends Mock implements MDnsClient {}
