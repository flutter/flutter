// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:dds/dds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    // We don't care what's actually running in the target process for this
    // test, so we're just using an existing one.
    process = await spawnDartProcess(
      'get_stream_history_script.dart',
      pauseOnStart: false,
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  Future<void> streamSubscribeUnsubscribe(
    VmService client, {
    required bool delay,
  }) async {
    await client.streamListen('Service');
    await Future.delayed(
      Duration(milliseconds: delay ? Random().nextInt(200) : 0),
    );
    await client.streamCancel('Service');
  }

  test('Ensure streamListen and streamCancel calls are handled atomically',
      () async {
    for (int i = 0; i < 100; ++i) {
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      expect(dds.isRunning, true);
      final connection1 = await vmServiceConnectUri(dds.wsUri.toString());
      final connection2 = await vmServiceConnectUri(dds.wsUri.toString());

      await Future.wait([
        streamSubscribeUnsubscribe(connection1, delay: true),
        streamSubscribeUnsubscribe(connection2, delay: false),
      ]);
      await dds.shutdown();
    }
  });
}
