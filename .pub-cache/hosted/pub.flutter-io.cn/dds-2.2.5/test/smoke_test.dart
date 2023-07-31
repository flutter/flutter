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

    void createSmokeTest(bool useAuthCodes, bool ipv6) {
      final protocol = ipv6 ? 'IPv6' : 'IPv4';
      test(
        'Smoke Test with ${useAuthCodes ? "" : "no"} authentication codes '
        'with $protocol',
        () async {
          dds = await DartDevelopmentService.startDartDevelopmentService(
            remoteVmServiceUri,
            enableAuthCodes: useAuthCodes,
            ipv6: ipv6,
          );
          expect(dds.isRunning, true);

          try {
            Uri.parseIPv6Address(dds.uri!.host);
            expect(ipv6, true);
          } on FormatException {
            expect(ipv6, false);
          }

          // Ensure basic websocket requests are forwarded correctly to the VM service.
          final service = await vmServiceConnectUri(dds.wsUri.toString());
          final version = await service.getVersion();
          expect(version.major! > 0, true);
          expect(version.minor! >= 0, true);

          expect(
            dds.uri!.pathSegments,
            useAuthCodes ? isNotEmpty : isEmpty,
          );

          // Ensure we can still make requests of the VM service via HTTP.
          HttpClient client = HttpClient();
          final request = await client.getUrl(remoteVmServiceUri.replace(
            pathSegments: [
              if (remoteVmServiceUri.pathSegments.isNotEmpty)
                remoteVmServiceUri.pathSegments.first,
              'getVersion',
            ],
          ));
          final response = await request.close();
          final Map<String, dynamic> jsonResponse = (await response
              .transform(utf8.decoder)
              .transform(json.decoder)
              .single) as Map<String, dynamic>;
          expect(jsonResponse['result']['type'], 'Version');
          expect(jsonResponse['result']['major'] > 0, true);
          expect(jsonResponse['result']['minor'] >= 0, true);
        },
      );
    }

    createSmokeTest(true, false);
    createSmokeTest(false, false);
    createSmokeTest(true, true);
  });

  test('Invalid args test', () async {
    // Non-HTTP VM Service URI scheme
    expect(
        () async => await DartDevelopmentService.startDartDevelopmentService(
              Uri.parse('dart-lang://localhost:1234'),
            ),
        throwsA(TypeMatcher<ArgumentError>()));

    // Non-HTTP VM Service URI scheme
    expect(
        () async => await DartDevelopmentService.startDartDevelopmentService(
              Uri.parse('http://localhost:1234'),
              serviceUri: Uri.parse('dart-lang://localhost:2345'),
            ),
        throwsA(TypeMatcher<ArgumentError>()));

    // Protocol mismatch
    expect(
        () async => await DartDevelopmentService.startDartDevelopmentService(
              Uri.parse('http://localhost:1234'),
              serviceUri: Uri.parse('http://127.0.0.1:2345'),
              ipv6: true,
            ),
        throwsA(TypeMatcher<ArgumentError>()));

    // Protocol mismatch
    expect(
        () async => await DartDevelopmentService.startDartDevelopmentService(
              Uri.parse('http://localhost:1234'),
              serviceUri: Uri.parse('http://[::1]:2345'),
              ipv6: false,
            ),
        throwsA(TypeMatcher<ArgumentError>()));
  });
}
