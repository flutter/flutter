// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/protocol_discovery.dart';
import 'package:test/test.dart';

import 'src/mocks.dart';

void main() {
  group('service_protocol', () {
    test('Discovery Heartbeat', () async {
      MockDeviceLogReader logReader = new MockDeviceLogReader();
      ProtocolDiscovery discoverer =
          new ProtocolDiscovery(logReader, ProtocolDiscovery.kObservatoryService);

      // Get next port future.
      Future<int> nextPort = discoverer.nextPort();
      expect(nextPort, isNotNull);

      // Inject some lines.
      logReader.addLine('HELLO WORLD');
      logReader.addLine('Observatory listening on http://127.0.0.1:9999');
      // Await the port.
      expect(await nextPort, 9999);

      // Get next port future.
      nextPort = discoverer.nextPort();
      logReader.addLine('Observatory listening on http://127.0.0.1:3333');
      expect(await nextPort, 3333);

      // Get next port future.
      nextPort = discoverer.nextPort();
      // Inject some bad lines.
      logReader.addLine('Observatory listening on http://127.0.0.1');
      logReader.addLine('Observatory listening on http://127.0.0.1:');
      logReader.addLine('Observatory listening on http://127.0.0.1:apple');
      int port = await nextPort.timeout(
      const Duration(milliseconds: 100), onTimeout: () => 77);
      // Expect the timeout port.
      expect(port, 77);

      // Get next port future.
      nextPort = discoverer.nextPort();
      logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:52584');
      expect(await nextPort, 52584);

      discoverer.cancel();
      logReader.dispose();
    });
  });
}
