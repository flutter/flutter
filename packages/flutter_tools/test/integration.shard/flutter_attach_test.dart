// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

Future<int> getFreePort() async {
  var port = 0;
  final ServerSocket serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  port = serverSocket.port;
  await serverSocket.close();
  return port;
}

void main() {
  final project = BasicProject();
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('attach_test.');
    await project.setUpIn(tempDir);
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  group('DDS launch race', () {
    late FlutterRunTestDriver flutterRun, flutterAttach, flutterAttach2;
    setUp(() {
      flutterRun = FlutterRunTestDriver(tempDir, logPrefix: '   RUN  ', spawnDdsInstance: false);
      flutterAttach = FlutterRunTestDriver(tempDir, logPrefix: 'ATTACH (1) ');
      flutterAttach2 = FlutterRunTestDriver(tempDir, logPrefix: 'ATTACH (2) ');
    });

    tearDown(() async {
      await flutterAttach.detach();
      await flutterAttach2.detach();
      await flutterRun.stop();
    });

    test('regression test for https://github.com/flutter/flutter/issues/169265', () async {
      // This test is meant to mimic a race between "flutter run" and "flutter attach" instances
      // both trying to start DDS for the same VM service instance. Unfortunately, we need a VM
      // service port for "flutter attach" to work with the flutter-tester device, so instead we
      // invoke "flutter run" with DDS disabled to get a Flutter process with a VM service port and
      // try to perform two "flutter attach" operations to this port at the same time. This fails
      // in the same way as a "flutter run" and "flutter attach" race as both operations result in
      // the same DDS launching logic being executed.
      await flutterRun.run(withDebugger: true, startPaused: true);

      await Future.wait([
        flutterAttach.attach(flutterRun.vmServicePort!),
        flutterAttach2.attach(flutterRun.vmServicePort!),
      ]);

      // Both attach instances should succeed and should both be connected to the same service URI.
      expect(flutterAttach.vmServiceWsUri, flutterAttach2.vmServiceWsUri);
      final FlutterVmService service = await connectToVmService(
        flutterAttach.vmServiceWsUri!,
        logger: BufferLogger.test(),
      );

      // Verify that DDS has actually been launched and we're not just connected to the VM service
      // directly.
      final ProtocolList protocoList = await service.service.getSupportedProtocols();
      expect(protocoList.protocols!.where((p) => p.protocolName == 'DDS'), hasLength(1));
    });
  });

  group('DDS in flutter run', () {
    late FlutterRunTestDriver flutterRun, flutterAttach;
    setUp(() {
      flutterRun = FlutterRunTestDriver(tempDir, logPrefix: '   RUN  ');
      flutterAttach = FlutterRunTestDriver(
        tempDir,
        logPrefix: 'ATTACH  ',
        // Only one DDS instance can be connected to the VM service at a time.
        // DDS can also only initialize if the VM service doesn't have any existing
        // clients, so we'll just let _flutterRun be responsible for spawning DDS.
        spawnDdsInstance: false,
      );
    });

    tearDown(() async {
      await flutterAttach.detach();
      await flutterRun.stop();
    });

    testWithoutContext('can hot reload', () async {
      await flutterRun.run(withDebugger: true);
      await flutterAttach.attach(flutterRun.vmServicePort!);
      await flutterAttach.hotReload();
    });

    testWithoutContext('can detach, reattach, hot reload', () async {
      await flutterRun.run(withDebugger: true);
      await flutterAttach.attach(flutterRun.vmServicePort!);
      await flutterAttach.detach();
      await flutterAttach.attach(flutterRun.vmServicePort!);
      await flutterAttach.hotReload();
    });

    testWithoutContext('killing process behaves the same as detach ', () async {
      await flutterRun.run(withDebugger: true);
      await flutterAttach.attach(flutterRun.vmServicePort!);
      await flutterAttach.quit();
      flutterAttach = FlutterRunTestDriver(tempDir, logPrefix: 'ATTACH-2', spawnDdsInstance: false);
      await flutterAttach.attach(flutterRun.vmServicePort!);
      await flutterAttach.hotReload();
    });

    testWithoutContext('sets activeDevToolsServerAddress extension', () async {
      await flutterRun.run(
        startPaused: true,
        withDebugger: true,
        additionalCommandArgs: <String>['--devtools-server-address', 'http://127.0.0.1:9105'],
      );
      await flutterRun.resume();
      await pollForServiceExtensionValue<String>(
        testDriver: flutterRun,
        extension: 'ext.flutter.activeDevToolsServerAddress',
        continuePollingValue: '',
        matches: equals('http://127.0.0.1:9105'),
      );
      await pollForServiceExtensionValue<String>(
        testDriver: flutterRun,
        extension: 'ext.flutter.connectedVmServiceUri',
        continuePollingValue: '',
        matches: isNotEmpty,
      );

      final Response response = await flutterRun.callServiceExtension(
        'ext.flutter.connectedVmServiceUri',
      );
      final vmServiceUri = response.json!['value'] as String;

      // Attach with a different DevTools server address.
      await flutterAttach.attach(
        flutterRun.vmServicePort!,
        additionalCommandArgs: <String>['--devtools-server-address', 'http://127.0.0.1:9110'],
      );
      await pollForServiceExtensionValue<String>(
        testDriver: flutterAttach,
        extension: 'ext.flutter.activeDevToolsServerAddress',
        continuePollingValue: '',
        matches: equals('http://127.0.0.1:9110'),
      );
      await pollForServiceExtensionValue<String>(
        testDriver: flutterRun,
        extension: 'ext.flutter.connectedVmServiceUri',
        continuePollingValue: '',
        matches: equals(vmServiceUri),
      );
    });
  });

  group('DDS in flutter attach', () {
    late FlutterRunTestDriver flutterRun, flutterAttach;
    setUp(() {
      flutterRun = FlutterRunTestDriver(tempDir, logPrefix: '   RUN  ', spawnDdsInstance: false);
      flutterAttach = FlutterRunTestDriver(tempDir, logPrefix: 'ATTACH  ');
    });

    tearDown(() async {
      await flutterAttach.detach();
      await flutterRun.stop();
    });

    testWithoutContext('uses the designated dds port', () async {
      final int ddsPort = await getFreePort();

      await flutterRun.run(withDebugger: true);
      await flutterAttach.attach(
        flutterRun.vmServicePort!,
        additionalCommandArgs: <String>['--dds-port=$ddsPort'],
      );

      final Response response = await flutterAttach.callServiceExtension(
        'ext.flutter.connectedVmServiceUri',
      );
      final vmServiceUriString = response.json!['value'] as String;
      final Uri vmServiceUri = Uri.parse(vmServiceUriString);
      expect(vmServiceUri.port, equals(ddsPort));
    });
  });
}
