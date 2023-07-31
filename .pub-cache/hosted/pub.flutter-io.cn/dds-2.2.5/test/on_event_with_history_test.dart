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

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    process = await spawnDartProcess(
      'on_event_with_history_script.dart',
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test('onEventWithHistory returns stream including log history', () async {
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);
    final service = await vmServiceConnectUri(dds.wsUri.toString());

    // Wait until the test script has finished writing its initial logs.
    await executeUntilNextPause(service);

    await service.streamListen('Logging');
    final stream = service.onLoggingEventWithHistory;

    var completer = Completer<void>();
    int count = 0;
    stream.listen((event) {
      count++;
      expect(event.logRecord!.message!.valueAsString, count.toString());
      if (count % 10 == 0) {
        completer.complete();
      }
    });
    await completer.future;

    completer = Completer<void>();
    final isolateId = (await service.getVM()).isolates!.first.id!;
    await service.resume(isolateId);

    await completer.future;
    expect(count, 20);
  });
}
