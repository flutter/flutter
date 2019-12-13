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

void main() {
  group('mDNS Discovery', () {
    final int year3000 = DateTime(3000).millisecondsSinceEpoch;

    MDnsClient getMockClient(
      List<PtrResourceRecord> ptrRecords,
      Map<String, List<SrvResourceRecord>> srvResponse, {
      bool ipv6 = false,
      Map<String, List<TxtResourceRecord>> txtResponse = const <String, List<TxtResourceRecord>>{},
    }) {
      final MDnsClient client = MockMDnsClient();

      when(client.start(
        listenAddress: anyNamed('listenAddress'),
      )).thenAnswer((Invocation invocation) async {
        if ((ipv6 && invocation.namedArguments[#listenAddress] != InternetAddress.anyIPv6) ||
            (!ipv6 && invocation.namedArguments[#listenAddress] != InternetAddress.anyIPv4)) {
          throw ipv6 ? 'expected to listen on ipv6 any' : 'expected to listen on ipv4 any';
        }
      });

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

    testUsingContext('One port available, no appId, ipv4', () async {
      final MDnsClient client = getMockClient(
        <PtrResourceRecord>[
          PtrResourceRecord('foo', year3000, domainName: 'bar'),
        ],
        <String, List<SrvResourceRecord>>{
          'bar': <SrvResourceRecord>[
            SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
          ],
        },
        ipv6: false,
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(mdnsClient: client);
      final int port = (await portDiscovery.query(usesIpv6: false))?.port;
      expect(port, 123);
    });

    testUsingContext('One port available, no appId, ipv6', () async {
      final MDnsClient client = getMockClient(
        <PtrResourceRecord>[
          PtrResourceRecord('foo', year3000, domainName: 'bar'),
        ],
        <String, List<SrvResourceRecord>>{
          'bar': <SrvResourceRecord>[
            SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
          ],
        },
        ipv6: true,
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(mdnsClient: client);
      final int port = (await portDiscovery.query(usesIpv6: true))?.port;
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
      expect(() => portDiscovery.query(), throwsToolExit());
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
  });
}

class MockMDnsClient extends Mock implements MDnsClient {}
