// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

void main() {
  late Process process;
  late DartDevelopmentService dds;
  setUp(() async {
    process = await spawnDartProcess('smoke.dart');
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  Future<int> getAvailablePort() async {
    final tmpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = tmpServer.port;
    await tmpServer.close();
    return port;
  }

  group('Ensure DDS URIs are consistent', () {
    test('without authentication codes', () async {
      final port = await getAvailablePort();
      final serviceUri = Uri.parse('http://127.0.0.1:$port/');
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
        serviceUri: serviceUri,
        enableAuthCodes: false,
      );

      expect(dds.uri, serviceUri);
      expect(
        dds.sseUri,
        serviceUri.replace(
          scheme: 'sse',
          pathSegments: ['\$debugHandler'],
        ),
      );
      expect(
        dds.wsUri,
        serviceUri.replace(
          scheme: 'ws',
          pathSegments: ['ws'],
        ),
      );
    });

    test('with authentication codes', () async {
      final port = await getAvailablePort();
      final serviceUri = Uri.parse('http://127.0.0.1:$port/');
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
        serviceUri: serviceUri,
      );

      // We need to pull the authentication code out of the main DDS URI, so
      // just make sure that it's at the right address and port.
      expect(dds.uri.toString().contains(serviceUri.toString()), isTrue);

      expect(dds.uri!.pathSegments, isNotEmpty);
      final authCode = dds.uri!.pathSegments.first;
      expect(
        dds.sseUri,
        serviceUri.replace(
          scheme: 'sse',
          pathSegments: [authCode, '\$debugHandler'],
        ),
      );
      expect(
        dds.wsUri,
        serviceUri.replace(
          scheme: 'ws',
          pathSegments: [authCode, 'ws'],
        ),
      );
    });
  });
}
