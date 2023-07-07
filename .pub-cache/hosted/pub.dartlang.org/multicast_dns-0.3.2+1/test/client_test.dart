// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

void main() {
  test('Can inject datagram socket factory and configure mdns port', () async {
    late int lastPort;
    final FakeRawDatagramSocket datagramSocket = FakeRawDatagramSocket();
    final MDnsClient client = MDnsClient(rawDatagramSocketFactory:
        (dynamic host, int port,
            {bool reuseAddress = true,
            bool reusePort = true,
            int ttl = 1}) async {
      lastPort = port;
      return datagramSocket;
    });

    await client.start(
        mDnsPort: 1234,
        interfacesFactory: (InternetAddressType type) async =>
            <NetworkInterface>[]);

    expect(lastPort, 1234);
  });

  test('Closes IPv4 sockets', () async {
    final FakeRawDatagramSocket datagramSocket = FakeRawDatagramSocket();
    final MDnsClient client = MDnsClient(rawDatagramSocketFactory:
        (dynamic host, int port,
            {bool reuseAddress = true,
            bool reusePort = true,
            int ttl = 1}) async {
      return datagramSocket;
    });

    await client.start(
        mDnsPort: 1234,
        interfacesFactory: (InternetAddressType type) async =>
            <NetworkInterface>[]);
    expect(datagramSocket.closed, false);
    client.stop();
    expect(datagramSocket.closed, true);
  });

  test('Closes IPv6 sockets', () async {
    final FakeRawDatagramSocket datagramSocket = FakeRawDatagramSocket();
    datagramSocket.address = InternetAddress.anyIPv6;
    final MDnsClient client = MDnsClient(rawDatagramSocketFactory:
        (dynamic host, int port,
            {bool reuseAddress = true,
            bool reusePort = true,
            int ttl = 1}) async {
      return datagramSocket;
    });

    await client.start(
        mDnsPort: 1234,
        interfacesFactory: (InternetAddressType type) async =>
            <NetworkInterface>[]);
    expect(datagramSocket.closed, false);
    client.stop();
    expect(datagramSocket.closed, true);
  });

  test('start() is idempotent', () async {
    final FakeRawDatagramSocket datagramSocket = FakeRawDatagramSocket();
    datagramSocket.address = InternetAddress.anyIPv4;
    final MDnsClient client = MDnsClient(rawDatagramSocketFactory:
        (dynamic host, int port,
            {bool reuseAddress = true,
            bool reusePort = true,
            int ttl = 1}) async {
      return datagramSocket;
    });

    await client.start(
        interfacesFactory: (InternetAddressType type) async =>
            <NetworkInterface>[]);
    await client.start();
    await client.lookup(ResourceRecordQuery.serverPointer('_')).toList();
  });
}

class FakeRawDatagramSocket extends Fake implements RawDatagramSocket {
  @override
  InternetAddress address = InternetAddress.anyIPv4;

  @override
  StreamSubscription<RawSocketEvent> listen(
      void Function(RawSocketEvent event)? onData,
      {Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) {
    return const Stream<RawSocketEvent>.empty().listen(onData,
        onError: onError, cancelOnError: cancelOnError, onDone: onDone);
  }

  bool closed = false;

  @override
  void close() {
    closed = true;
  }

  @override
  int send(List<int> buffer, InternetAddress address, int port) {
    return buffer.length;
  }
}
