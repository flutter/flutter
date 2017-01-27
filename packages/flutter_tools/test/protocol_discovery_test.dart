// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/protocol_discovery.dart';
import 'package:test/test.dart';

import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  group('service_protocol discovery', () {
    testUsingContext('no port forwarding', () async {
      MockDeviceLogReader logReader = new MockDeviceLogReader();
      ProtocolDiscovery discoverer =
          new ProtocolDiscovery(logReader, ProtocolDiscovery.kObservatoryService);

      // Get next port future.
      Future<Uri> nextUrl = discoverer.nextUrl();
      expect(nextUrl, isNotNull);

      // Inject some lines.
      logReader.addLine('HELLO WORLD');
      logReader.addLine('Observatory listening on http://127.0.0.1:9999');
      // Await the port.
      Uri url = await nextUrl;
      expect(url.port, 9999);
      expect('$url', 'http://127.0.0.1:9999');

      // Get next port future.
      nextUrl = discoverer.nextUrl();
      logReader.addLine('Observatory listening on http://127.0.0.1:3333');
      url = await nextUrl;
      expect(url.port, 3333);
      expect('$url', 'http://127.0.0.1:3333');

      // Get next port future.
      nextUrl = discoverer.nextUrl();
      // Inject a bad line.
      logReader.addLine('Observatory listening on http://127.0.0.1:apple');
      Uri timeoutUrl = Uri.parse('http://timeout');
      Uri actualUrl = await nextUrl.timeout(
          const Duration(milliseconds: 100), onTimeout: () => timeoutUrl);
      expect(actualUrl, timeoutUrl);

      // Get next port future.
      nextUrl = discoverer.nextUrl();
      logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:52584');
      url = await nextUrl;
      expect(url.port, 52584);
      expect('$url', 'http://127.0.0.1:52584');

      // Get next port future.
      nextUrl = discoverer.nextUrl();
      logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:54804/PTwjm8Ii8qg=/');
      url = await nextUrl;
      expect(url.port, 54804);
      expect('$url', 'http://127.0.0.1:54804/PTwjm8Ii8qg=/');

      // Get next port future.
      nextUrl = discoverer.nextUrl();
      logReader.addLine('I/flutter : Observatory listening on http://somehost:54804/PTwjm8Ii8qg=/');
      url = await nextUrl;
      expect(url.port, 54804);
      expect('$url', 'http://somehost:54804/PTwjm8Ii8qg=/');

      discoverer.cancel();
      logReader.dispose();
    });

    testUsingContext('port forwarding - default port', () async {
      MockDeviceLogReader logReader = new MockDeviceLogReader();
      ProtocolDiscovery discoverer = new ProtocolDiscovery(
          logReader,
          ProtocolDiscovery.kObservatoryService,
          portForwarder: new MockPortForwarder(99),
          defaultHostPort: 54777);

      // Get next port future.
      Future<Uri> nextUrl = discoverer.nextUrl();
      logReader.addLine('I/flutter : Observatory listening on http://somehost:54804/PTwjm8Ii8qg=/');
      Uri url = await nextUrl;
      expect(url.port, 54777);
      expect('$url', 'http://somehost:54777/PTwjm8Ii8qg=/');

      discoverer.cancel();
      logReader.dispose();
    });

    testUsingContext('port forwarding - specified port', () async {
      MockDeviceLogReader logReader = new MockDeviceLogReader();
      ProtocolDiscovery discoverer = new ProtocolDiscovery(
          logReader,
          ProtocolDiscovery.kObservatoryService,
          portForwarder: new MockPortForwarder(99),
          hostPort: 1243,
          defaultHostPort: 192);

      // Get next port future.
      Future<Uri> nextUrl = discoverer.nextUrl();
      logReader.addLine('I/flutter : Observatory listening on http://somehost:54804/PTwjm8Ii8qg=/');
      Uri url = await nextUrl;
      expect(url.port, 1243);
      expect('$url', 'http://somehost:1243/PTwjm8Ii8qg=/');

      discoverer.cancel();
      logReader.dispose();
    });
  });
}

class MockPortForwarder extends DevicePortForwarder {
  final int availablePort;
  MockPortForwarder([this.availablePort]);

  @override
  Future<int> forward(int devicePort, {int hostPort}) async => hostPort ?? availablePort;

  @override
  List<ForwardedPort> get forwardedPorts => throw 'not implemented';

  @override
  Future<Null> unforward(ForwardedPort forwardedPort) {
    throw 'not implemented';
  }
}
