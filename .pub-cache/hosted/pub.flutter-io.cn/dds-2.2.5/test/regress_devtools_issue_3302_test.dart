// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';
import 'common/test_helper.dart';

// Regression test for https://github.com/flutter/devtools/issues/3302.

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    process = await spawnDartProcess(
      'smoke.dart',
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test(
    'Ensure various historical streams can be cancelled without throwing StateError',
    () async {
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      expect(dds.isRunning, true);
      final service = await vmServiceConnectUri(dds.wsUri.toString());

      // This creates two single-subscription streams which are backed by a
      // broadcast stream.
      final stream1 = service.onExtensionEventWithHistory;
      final stream2 = service.onExtensionEventWithHistory;

      // Subscribe to each stream so `cancel()` doesn't hang.
      final sub1 = stream1.listen((_) => null);
      final sub2 = stream2.listen((_) => null);

      // Give some time for the streams to get setup.
      await Future.delayed(const Duration(seconds: 1));

      // The second call to `cancel()` shouldn't cause an exception to be thrown
      // when we try to cancel the underlying broadcast stream again.
      await sub1.cancel();
      await sub2.cancel();
    },
    timeout: Timeout.none,
  );
}
