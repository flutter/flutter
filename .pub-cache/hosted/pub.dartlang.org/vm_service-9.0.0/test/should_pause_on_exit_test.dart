// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

void testMain() {
  print('Hello world!');
}

Future<bool> shouldPauseOnExit(VmService service, IsolateRef isolateRef) async {
  final isolate = await service.getIsolate(isolateRef.id!);
  return isolate.pauseOnExit!;
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    await service.setIsolatePauseMode(isolateRef.id!, shouldPauseOnExit: false);
    expect(await shouldPauseOnExit(service, isolateRef), false);
    final completer = Completer<void>();

    final stream = service.onDebugEvent;
    final subscription = stream.listen((Event event) {
      if (event.kind == EventKind.kPauseExit) {
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kDebug);

    await service.setIsolatePauseMode(isolateRef.id!, shouldPauseOnExit: true);
    expect(await shouldPauseOnExit(service, isolateRef), true);
    await service.resume(isolateRef.id!);
    await completer.future;
    await service.resume(isolateRef.id!);
    await subscription.cancel();
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'should_pause_on_exit_test.dart',
      pause_on_start: true,
      pause_on_exit: true,
      testeeConcurrent: testMain,
    );
