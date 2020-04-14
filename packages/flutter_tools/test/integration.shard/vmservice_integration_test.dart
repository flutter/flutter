// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;

  tearDown(() {
    tryToDelete(tempDir);
  });

  test('Flutter Tool VMService methods', () async {
    tempDir = createResolvedTempDirectorySync('vmservice_integration_test.');

    final BasicProject _project = BasicProject();
    await _project.setUpIn(tempDir);

    final FlutterRunTestDriver flutter = FlutterRunTestDriver(tempDir);
    await flutter.run(withDebugger: true);
    final int port = flutter.vmServicePort;
    final VmService vmService = await vmServiceConnectUri('ws://localhost:$port/ws');
    await Future<void>.delayed(const Duration(seconds: 5));

    await vmService.callServiceExtension('flutterVersion');
    await vmService.callMethod('compileExpression');
    await vmService.callMethod('flutterMemoryInfo');
    await vmService.callMethod('reloadSources');
    await vmService.callMethod('hotRestart');
  });
}

