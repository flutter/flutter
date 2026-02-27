// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../integration.shard/test_data/basic_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

void main() {
  late Directory tempDir;
  final project = BasicProjectWithUnaryMain();
  late FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('flutter run on web respects --dds-port', () async {
    // Regression test for https://github.com/flutter/flutter/issues/159157
    Future<int> getFreePort() async {
      final ServerSocket serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      try {
        return serverSocket.port;
      } finally {
        await serverSocket.close();
      }
    }

    final int ddsPort = await getFreePort();
    await flutter.run(
      withDebugger: true,
      // Unfortunately, we can't easily test the web-server device as we'd need to attach to the
      // server with a Chromedriver instance to initialize DWDS and start DDS. However, the DDS
      // port is provided via the same code path to DWDS regardless of which device we use, so
      // only testing against the Chrome device should be sufficient.
      device: GoogleChromeDevice.kChromeDeviceId,
      ddsPort: ddsPort,
      additionalCommandArgs: <String>['--verbose', '--no-web-resources-cdn'],
    );
    expect(flutter.vmServicePort, ddsPort);
  });

  group('Clients of flutter run on web with DDS enabled', () {
    testWithoutContext('can validate flutter version', () async {
      await flutter.run(
        withDebugger: true,
        device: GoogleChromeDevice.kChromeDeviceId,
        additionalCommandArgs: <String>['--verbose', '--no-web-resources-cdn'],
      );

      expect(flutter.vmServiceWsUri, isNotNull);

      final VmService client = await vmServiceConnectUri('${flutter.vmServiceWsUri}');
      await validateFlutterVersion(client);
    });

    testWithoutContext('can validate flutter version in parallel', () async {
      await flutter.run(
        withDebugger: true,
        device: GoogleChromeDevice.kChromeDeviceId,
        additionalCommandArgs: <String>['--verbose', '--no-web-resources-cdn'],
      );

      expect(flutter.vmServiceWsUri, isNotNull);

      final VmService client1 = await vmServiceConnectUri('${flutter.vmServiceWsUri}');

      final VmService client2 = await vmServiceConnectUri('${flutter.vmServiceWsUri}');

      await Future.wait(<Future<void>>[
        validateFlutterVersion(client1),
        validateFlutterVersion(client2),
      ]);
    }, skip: true); // https://github.com/flutter/flutter/issues/99003
  });

  group('Clients of flutter run on web with DDS disabled', () {
    setUp(() async {
      tempDir = createResolvedTempDirectorySync('run_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir, spawnDdsInstance: false);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    testWithoutContext('can validate flutter version', () async {
      await flutter.run(
        withDebugger: true,
        device: GoogleChromeDevice.kChromeDeviceId,
        additionalCommandArgs: <String>['--verbose', '--no-web-resources-cdn'],
      );

      expect(flutter.vmServiceWsUri, isNotNull);

      final VmService client = await vmServiceConnectUri('${flutter.vmServiceWsUri}');
      await validateFlutterVersion(client);
    });
  });
}

Future<void> validateFlutterVersion(VmService client) async {
  String? method;

  final Future<dynamic> registration = expectLater(
    client.onEvent('Service'),
    emitsThrough(
      predicate((Event e) {
        if (e.kind == EventKind.kServiceRegistered && e.service == kFlutterVersionServiceName) {
          method = e.method;
          return true;
        }
        return false;
      }),
    ),
  );

  await client.streamListen('Service');
  await registration;
  await client.streamCancel('Service');

  final dynamic version1 = await client.callServiceExtension(method!);
  expect(
    version1,
    const TypeMatcher<Success>()
        .having((Success r) => r.type, 'type', 'Success')
        .having((Success r) => r.json!['frameworkVersion'], 'frameworkVersion', isNotNull),
  );

  await client.dispose();
}
