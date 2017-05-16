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
    MockDeviceLogReader logReader;
    ProtocolDiscovery discoverer;

    group('no port forwarding', () {
      /// Performs test set-up functionality that must be performed as part of
      /// the `test()` pass and not part of the `setUp()` pass.
      ///
      /// This exists to make sure we're not creating an error that tries to
      /// cross an error-zone boundary. Our use of `testUsingContext()` runs the
      /// test code inside an error zone, but the `setUp()` code is not run in
      /// any zone. This creates the potential for errors that try to cross
      /// error-zone boundaries, which are considered uncaught.
      ///
      /// This also exists for cases where our initialization requires access to
      /// a `Context` object, which is only set up inside the zone.
      ///
      /// Note that these issues do not pertain to real code and are a test-only
      /// concern, since in real code, the zone is set-up in `main()`.
      ///
      /// See also: [runZoned]
      void initialize() {
        logReader = new MockDeviceLogReader();
        discoverer = new ProtocolDiscovery.observatory(logReader);
      }

      tearDown(() {
        discoverer.cancel();
        logReader.dispose();
      });

      testUsingContext('returns non-null uri future', () async {
        initialize();
        expect(discoverer.uri, isNotNull);
      });

      testUsingContext('discovers uri if logs already produced output', () async {
        initialize();
        logReader.addLine('HELLO WORLD');
        logReader.addLine('Observatory listening on http://127.0.0.1:9999');
        final Uri uri = await discoverer.uri;
        expect(uri.port, 9999);
        expect('$uri', 'http://127.0.0.1:9999');
      });

      testUsingContext('discovers uri if logs not yet produced output', () async {
        initialize();
        final Future<Uri> uriFuture = discoverer.uri;
        logReader.addLine('Observatory listening on http://127.0.0.1:3333');
        final Uri uri = await uriFuture;
        expect(uri.port, 3333);
        expect('$uri', 'http://127.0.0.1:3333');
      });

      testUsingContext('uri throws if logs produce bad line', () async {
        initialize();
        Timer.run(() {
          logReader.addLine('Observatory listening on http://127.0.0.1:apple');
        });
        expect(discoverer.uri, throwsA(isFormatException));
      });

      testUsingContext('uri waits for correct log line', () async {
        initialize();
        final Future<Uri> uriFuture = discoverer.uri;
        logReader.addLine('Observatory not listening...');
        final Uri timeoutUri = Uri.parse('http://timeout');
        final Uri actualUri = await uriFuture.timeout(
            const Duration(milliseconds: 100), onTimeout: () => timeoutUri);
        expect(actualUri, timeoutUri);
      });

      testUsingContext('discovers uri if log line contains Android prefix', () async {
        initialize();
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:52584');
        final Uri uri = await discoverer.uri;
        expect(uri.port, 52584);
        expect('$uri', 'http://127.0.0.1:52584');
      });

      testUsingContext('discovers uri if log line contains auth key', () async {
        initialize();
        final Future<Uri> uriFuture = discoverer.uri;
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:54804/PTwjm8Ii8qg=/');
        final Uri uri = await uriFuture;
        expect(uri.port, 54804);
        expect('$uri', 'http://127.0.0.1:54804/PTwjm8Ii8qg=/');
      });

      testUsingContext('discovers uri if log line contains non-localhost', () async {
        initialize();
        final Future<Uri> uriFuture = discoverer.uri;
        logReader.addLine('I/flutter : Observatory listening on http://somehost:54804/PTwjm8Ii8qg=/');
        final Uri uri = await uriFuture;
        expect(uri.port, 54804);
        expect('$uri', 'http://somehost:54804/PTwjm8Ii8qg=/');
      });
    });

    testUsingContext('port forwarding - default port', () async {
      final MockDeviceLogReader logReader = new MockDeviceLogReader();
      final ProtocolDiscovery discoverer = new ProtocolDiscovery.observatory(
          logReader,
          portForwarder: new MockPortForwarder(99),
          hostPort: 54777);

      // Get next port future.
      final Future<Uri> nextUri = discoverer.uri;
      logReader.addLine('I/flutter : Observatory listening on http://somehost:54804/PTwjm8Ii8qg=/');
      final Uri uri = await nextUri;
      expect(uri.port, 54777);
      expect('$uri', 'http://somehost:54777/PTwjm8Ii8qg=/');

      discoverer.cancel();
      logReader.dispose();
    });

    testUsingContext('port forwarding - specified port', () async {
      final MockDeviceLogReader logReader = new MockDeviceLogReader();
      final ProtocolDiscovery discoverer = new ProtocolDiscovery.observatory(
          logReader,
          portForwarder: new MockPortForwarder(99),
          hostPort: 1243);

      // Get next port future.
      final Future<Uri> nextUri = discoverer.uri;
      logReader.addLine('I/flutter : Observatory listening on http://somehost:54804/PTwjm8Ii8qg=/');
      final Uri uri = await nextUri;
      expect(uri.port, 1243);
      expect('$uri', 'http://somehost:1243/PTwjm8Ii8qg=/');

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
