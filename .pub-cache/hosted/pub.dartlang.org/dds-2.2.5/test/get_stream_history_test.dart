// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';
import 'common/test_helper.dart';

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    process = await spawnDartProcess(
      'get_stream_history_script.dart',
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test('getStreamHistory returns log history', () async {
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);
    final service = await vmServiceConnectUri(dds.wsUri.toString());

    // Wait until the test script has finished writing logs.
    await executeUntilNextPause(service);

    final result = await service.getStreamHistory('Logging');
    expect(result, isNotNull);
    expect(result, isA<StreamHistory>());
    expect(result.history.length, 10);
  });
}
