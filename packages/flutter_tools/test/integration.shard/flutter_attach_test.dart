// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io';

import 'package:file/file.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  FlutterRunTestDriver _flutterRun, _flutterAttach;
  final BasicProject _project = BasicProject();
  Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('attach_test.');
    await _project.setUpIn(tempDir);
    _flutterRun = FlutterRunTestDriver(tempDir,    logPrefix: '   RUN  ');
    _flutterAttach = FlutterRunTestDriver(
      tempDir,
      logPrefix: 'ATTACH  ',
      // Only one DDS instance can be connected to the VM service at a time.
      // DDS can also only initialize if the VM service doesn't have any existing
      // clients, so we'll just let _flutterRun be responsible for spawning DDS.
      spawnDdsInstance: false,
    );
  });

  tearDown(() async {
    await _flutterAttach.detach();
    await _flutterRun.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('can hot reload', () async {
    await _flutterRun.run(withDebugger: true);
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.hotReload();
  });

  testWithoutContext('can detach, reattach, hot reload', () async {
    await _flutterRun.run(withDebugger: true);
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.detach();
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.hotReload();
  });

  testWithoutContext('killing process behaves the same as detach ', () async {
    await _flutterRun.run(withDebugger: true);
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.quit();
    _flutterAttach = FlutterRunTestDriver(
      tempDir,
      logPrefix: 'ATTACH-2',
      spawnDdsInstance: false,
    );
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.hotReload();
  });

  testWithoutContext('sets activeDevToolsServerAddress extension', () async {
    await _flutterRun.run(
      startPaused: true,
      withDebugger: true,
      additionalCommandArgs: <String>['--devtools-server-address', 'http://127.0.0.1:9105'],
    );
    await _flutterRun.resume();
    await pollForServiceExtensionValue<String>(
      testDriver: _flutterRun,
      extension: 'ext.flutter.activeDevToolsServerAddress',
      continuePollingValue: '',
      matches: equals('http://127.0.0.1:9105'),
    );
    await pollForServiceExtensionValue<String>(
      testDriver: _flutterRun,
      extension: 'ext.flutter.connectedVmServiceUri',
      continuePollingValue: '',
      matches: isNotEmpty,
    );

    final Response response = await _flutterRun.callServiceExtension('ext.flutter.connectedVmServiceUri');
    final String vmServiceUri = response.json['value'] as String;

    // Attach with a different DevTools server address.
    await _flutterAttach.attach(
      _flutterRun.vmServicePort,
      additionalCommandArgs: <String>['--devtools-server-address', 'http://127.0.0.1:9110'],
    );
    await pollForServiceExtensionValue<String>(
      testDriver: _flutterAttach,
      extension: 'ext.flutter.activeDevToolsServerAddress',
      continuePollingValue: '',
      matches: equals('http://127.0.0.1:9110'),
    );
    await pollForServiceExtensionValue<String>(
      testDriver: _flutterRun,
      extension: 'ext.flutter.connectedVmServiceUri',
      continuePollingValue: '',
      matches: equals(vmServiceUri),
    );
  }, timeout: const Timeout.factor(4));
}
