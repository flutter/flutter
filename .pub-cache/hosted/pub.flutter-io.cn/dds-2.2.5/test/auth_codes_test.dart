// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';

void main() {
  group('DDS', () {
    late Process process;
    late DartDevelopmentService dds;

    setUp(() async {
      process = await spawnDartProcess('smoke.dart');
    });

    tearDown(() async {
      await dds.shutdown();
      process.kill();
    });

    test('Bad Auth Code', () async {
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      expect(dds.isRunning, true);

      // Ensure basic websocket requests are forwarded correctly to the VM service.
      final service = await vmServiceConnectUri(dds.wsUri.toString());
      final version = await service.getVersion();
      expect(version.major! > 0, true);
      expect(version.minor! >= 0, true);

      // Ensure we can still make requests of the VM service via HTTP.
      HttpClient client = HttpClient();
      final request = await client.getUrl(remoteVmServiceUri.replace(
        pathSegments: [
          // Try an invalid authentication code
          'abc123',
          'getVersion',
        ],
      ));
      final response = await request.close();
      final responseStr = (await response.transform(utf8.decoder).single);
      expect(responseStr, 'missing or invalid authentication code');
    });
  });
}
