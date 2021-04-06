// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:flutter_tools/src/protocol_discovery.dart';
import 'package:fake_async/fake_async.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';

void main() {
  group('service_protocol discovery', () {
    FakeDeviceLogReader logReader;
    ProtocolDiscovery discoverer;

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
    /// These issues do not pertain to real code and are a test-only concern,
    /// because in real code, the zone is set up in `main()`.
    ///
    /// See also: [runZoned]
    void initialize({
      int devicePort,
      Duration throttleDuration = const Duration(milliseconds: 200),
    }) {
      logReader = FakeDeviceLogReader();
      discoverer = ProtocolDiscovery.observatory(
        logReader,
        ipv6: false,
        hostPort: null,
        devicePort: devicePort,
        throttleDuration: throttleDuration,
        logger: BufferLogger.test(),
      );
    }

    testUsingContext('returns non-null uri future', () async {
      initialize();
      expect(discoverer.uri, isNotNull);
    });

    group('no port forwarding', () {
      tearDown(() {
        discoverer.cancel();
        logReader.dispose();
      });

      testUsingContext('discovers uri if logs already produced output', () async {
        initialize();
        logReader.addLine('HELLO WORLD');
        logReader.addLine('Observatory listening on http://127.0.0.1:9999');
        final Uri uri = await discoverer.uri;
        expect(uri.port, 9999);
        expect('$uri', 'http://127.0.0.1:9999');
      });

      testUsingContext('discovers uri if logs already produced output and no listener is attached', () async {
        initialize();
        logReader.addLine('HELLO WORLD');
        logReader.addLine('Observatory listening on http://127.0.0.1:9999');

        await Future<void>.delayed(Duration.zero);

        final Uri uri = await discoverer.uri;
        expect(uri, isNotNull);
        expect(uri.port, 9999);
        expect('$uri', 'http://127.0.0.1:9999');
      });

      testUsingContext('uri throws if logs produce bad line and no listener is attached', () async {
        initialize();
        logReader.addLine('Observatory listening on http://127.0.0.1:apple');

        await Future<void>.delayed(Duration.zero);

        expect(discoverer.uri, throwsA(isFormatException));
      });

      testUsingContext('discovers uri if logs not yet produced output', () async {
        initialize();
        final Future<Uri> uriFuture = discoverer.uri;
        logReader.addLine('Observatory listening on http://127.0.0.1:3333');
        final Uri uri = await uriFuture;
        expect(uri.port, 3333);
        expect('$uri', 'http://127.0.0.1:3333');
      });

      testUsingContext('discovers uri with Ascii Esc code', () async {
        initialize();
        logReader.addLine('Observatory listening on http://127.0.0.1:3333\x1b[');
        final Uri uri = await discoverer.uri;
        expect(uri.port, 3333);
        expect('$uri', 'http://127.0.0.1:3333');
      });

      testUsingContext('uri throws if logs produce bad line', () async {
        initialize();
        logReader.addLine('Observatory listening on http://127.0.0.1:apple');
        expect(discoverer.uri, throwsA(isFormatException));
      });

      testUsingContext('uri is null when the log reader closes early', () async {
        initialize();
        final Future<Uri> uriFuture = discoverer.uri;
        await logReader.dispose();

        expect(await uriFuture, isNull);
      });

      testUsingContext('uri waits for correct log line', () async {
        initialize();
        final Future<Uri> uriFuture = discoverer.uri;
        logReader.addLine('Observatory not listening...');
        final Uri timeoutUri = Uri.parse('http://timeout');
        final Uri actualUri = await uriFuture.timeout(
          const Duration(milliseconds: 100),
          onTimeout: () => timeoutUri,
        );
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
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:54804/PTwjm8Ii8qg=/');
        final Uri uri = await uriFuture;
        expect(uri.port, 54804);
        expect('$uri', 'http://127.0.0.1:54804/PTwjm8Ii8qg=/');
      });

      testUsingContext('skips uri if port does not match the requested vmservice - requested last', () async {
        initialize(devicePort: 12346);
        final Future<Uri> uriFuture = discoverer.uri;
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12345/PTwjm8Ii8qg=/');
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12346/PTwjm8Ii8qg=/');
        final Uri uri = await uriFuture;
        expect(uri.port, 12346);
        expect('$uri', 'http://127.0.0.1:12346/PTwjm8Ii8qg=/');
      });

      testUsingContext('skips uri if port does not match the requested vmservice - requested first', () async {
        initialize(devicePort: 12346);
        final Future<Uri> uriFuture = discoverer.uri;
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12346/PTwjm8Ii8qg=/');
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12345/PTwjm8Ii8qg=/');
        final Uri uri = await uriFuture;
        expect(uri.port, 12346);
        expect('$uri', 'http://127.0.0.1:12346/PTwjm8Ii8qg=/');
      });

      testUsingContext('first uri in the stream is the last one from the log', () async {
        initialize();
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12346/PTwjm8Ii8qg=/');
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12345/PTwjm8Ii8qg=/');
        final Uri uri = await discoverer.uris.first;
        expect(uri.port, 12345);
        expect('$uri', 'http://127.0.0.1:12345/PTwjm8Ii8qg=/');
      });

      testUsingContext('first uri in the stream is the last one from the log that matches the port', () async {
        initialize(devicePort: 12345);
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12346/PTwjm8Ii8qg=/');
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12345/PTwjm8Ii8qg=/');
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12344/PTwjm8Ii8qg=/');
        final Uri uri = await discoverer.uris.first;
        expect(uri.port, 12345);
        expect('$uri', 'http://127.0.0.1:12345/PTwjm8Ii8qg=/');
      });

      testUsingContext('protocol discovery does not crash if the log reader is closed while delaying', () async {
        initialize(devicePort: 12346, throttleDuration: const Duration(milliseconds: 10));
        final Future<List<Uri>> results = discoverer.uris.toList();
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12346/PTwjm8Ii8qg=/');
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12346/PTwjm8Ii8qg=/');
        await logReader.dispose();

        // Give time for throttle to finish.
        await Future<void>.delayed(const Duration(milliseconds: 11));
        expect(await results, isEmpty);
      });

      testUsingContext('uris in the stream are throttled', () async {
        const Duration kThrottleDuration = Duration(milliseconds: 10);

        FakeAsync().run((FakeAsync time) {
          initialize(throttleDuration: kThrottleDuration);

          final List<Uri> discoveredUris = <Uri>[];
          discoverer.uris.listen((Uri uri) {
            discoveredUris.add(uri);
          });

          logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12346/PTwjm8Ii8qg=/');
          logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12345/PTwjm8Ii8qg=/');

          time.elapse(kThrottleDuration);

          logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12344/PTwjm8Ii8qg=/');
          logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12343/PTwjm8Ii8qg=/');

          time.elapse(kThrottleDuration);

          expect(discoveredUris.length, 2);
          expect(discoveredUris[0].port, 12345);
          expect('${discoveredUris[0]}', 'http://127.0.0.1:12345/PTwjm8Ii8qg=/');
          expect(discoveredUris[1].port, 12343);
          expect('${discoveredUris[1]}', 'http://127.0.0.1:12343/PTwjm8Ii8qg=/');
        });
      });

      testUsingContext('uris in the stream are throttled when they match the port', () async {
        const Duration kThrottleTimeInMilliseconds = Duration(milliseconds: 10);

        FakeAsync().run((FakeAsync time) {
          initialize(
            devicePort: 12345,
            throttleDuration: kThrottleTimeInMilliseconds,
          );

          final List<Uri> discoveredUris = <Uri>[];
          discoverer.uris.listen((Uri uri) {
            discoveredUris.add(uri);
          });

          logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12346/PTwjm8Ii8qg=/');
          logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12345/PTwjm8Ii8qg=/');

          time.elapse(kThrottleTimeInMilliseconds);

          logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12345/PTwjm8Ii8qc=/');
          logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:12344/PTwjm8Ii8qf=/');

          time.elapse(kThrottleTimeInMilliseconds);

          expect(discoveredUris.length, 2);
          expect(discoveredUris[0].port, 12345);
          expect('${discoveredUris[0]}', 'http://127.0.0.1:12345/PTwjm8Ii8qg=/');
          expect(discoveredUris[1].port, 12345);
          expect('${discoveredUris[1]}', 'http://127.0.0.1:12345/PTwjm8Ii8qc=/');
        });
      });
    });

    group('port forwarding', () {
      testUsingContext('default port', () async {
        final FakeDeviceLogReader logReader = FakeDeviceLogReader();
        final ProtocolDiscovery discoverer = ProtocolDiscovery.observatory(
          logReader,
          portForwarder: MockPortForwarder(99),
          hostPort: null,
          devicePort: null,
          ipv6: false,
          logger: BufferLogger.test(),
        );

        // Get next port future.
        final Future<Uri> nextUri = discoverer.uri;
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:54804/PTwjm8Ii8qg=/');
        final Uri uri = await nextUri;
        expect(uri.port, 99);
        expect('$uri', 'http://127.0.0.1:99/PTwjm8Ii8qg=/');

        await discoverer.cancel();
        await logReader.dispose();
      });

      testUsingContext('specified port', () async {
        final FakeDeviceLogReader logReader = FakeDeviceLogReader();
        final ProtocolDiscovery discoverer = ProtocolDiscovery.observatory(
          logReader,
          portForwarder: MockPortForwarder(99),
          hostPort: 1243,
          devicePort: null,
          ipv6: false,
          logger: BufferLogger.test(),
        );

        // Get next port future.
        final Future<Uri> nextUri = discoverer.uri;
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:54804/PTwjm8Ii8qg=/');
        final Uri uri = await nextUri;
        expect(uri.port, 1243);
        expect('$uri', 'http://127.0.0.1:1243/PTwjm8Ii8qg=/');

        await discoverer.cancel();
        await logReader.dispose();
      });

      testUsingContext('specified port zero', () async {
        final FakeDeviceLogReader logReader = FakeDeviceLogReader();
        final ProtocolDiscovery discoverer = ProtocolDiscovery.observatory(
          logReader,
          portForwarder: MockPortForwarder(99),
          hostPort: 0,
          devicePort: null,
          ipv6: false,
          logger: BufferLogger.test(),
        );

        // Get next port future.
        final Future<Uri> nextUri = discoverer.uri;
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:54804/PTwjm8Ii8qg=/');
        final Uri uri = await nextUri;
        expect(uri.port, 99);
        expect('$uri', 'http://127.0.0.1:99/PTwjm8Ii8qg=/');

        await discoverer.cancel();
        await logReader.dispose();
      });

      testUsingContext('ipv6', () async {
        final FakeDeviceLogReader logReader = FakeDeviceLogReader();
        final ProtocolDiscovery discoverer = ProtocolDiscovery.observatory(
          logReader,
          portForwarder: MockPortForwarder(99),
          hostPort: 54777,
          ipv6: true,
          devicePort: null,
          logger: BufferLogger.test(),
        );

        // Get next port future.
        final Future<Uri> nextUri = discoverer.uri;
        logReader.addLine('I/flutter : Observatory listening on http://127.0.0.1:54804/PTwjm8Ii8qg=/');
        final Uri uri = await nextUri;
        expect(uri.port, 54777);
        expect('$uri', 'http://[::1]:54777/PTwjm8Ii8qg=/');

        await discoverer.cancel();
        await logReader.dispose();
      });

      testUsingContext('ipv6 with Ascii Escape code', () async {
        final FakeDeviceLogReader logReader = FakeDeviceLogReader();
        final ProtocolDiscovery discoverer = ProtocolDiscovery.observatory(
          logReader,
          portForwarder: MockPortForwarder(99),
          hostPort: 54777,
          ipv6: true,
          devicePort: null,
          logger: BufferLogger.test(),
        );

        // Get next port future.
        final Future<Uri> nextUri = discoverer.uri;
        logReader.addLine('I/flutter : Observatory listening on http://[::1]:54777/PTwjm8Ii8qg=/\x1b[');
        final Uri uri = await nextUri;
        expect(uri.port, 54777);
        expect('$uri', 'http://[::1]:54777/PTwjm8Ii8qg=/');

        await discoverer.cancel();
        await logReader.dispose();
      });
    });
  });
}

class MockPortForwarder extends DevicePortForwarder {
  MockPortForwarder([this.availablePort]);

  final int availablePort;

  @override
  Future<int> forward(int devicePort, { int hostPort }) async {
    hostPort ??= 0;
    if (hostPort == 0) {
      return availablePort;
    }
    return hostPort;
  }

  @override
  List<ForwardedPort> get forwardedPorts => throw 'not implemented';

  @override
  Future<void> unforward(ForwardedPort forwardedPort) {
    throw 'not implemented';
  }

  @override
  Future<void> dispose() async {}
}
