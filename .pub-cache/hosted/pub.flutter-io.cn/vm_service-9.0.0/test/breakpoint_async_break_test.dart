// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE = 19;
const int COL = 7;

// Issue: https://github.com/dart-lang/sdk/issues/36622
Future<void> testMain() async {
  for (int i = 0; i < 2; i++) {
    if (i > 0) {
      break; // breakpoint here
    }
    await Future.delayed(Duration(seconds: 1));
  }
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  // Test future breakpoints.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final scriptId = rootLib.scripts![0].id!;
    final script = await service.getObject(isolateId, scriptId) as Script;

    // Future breakpoint.
    var futureBpt = await service.addBreakpoint(isolateId, scriptId, LINE);
    expect(futureBpt.breakpointNumber, 1);
    expect(futureBpt.resolved, isFalse);
    expect(await futureBpt.location!.line, LINE);
    expect(await futureBpt.location!.column, null);

    final completer = Completer<void>();
    int resolvedCount = 0;
    late StreamSubscription subscription;
    subscription = service.onDebugEvent.listen((event) {
      if (event.kind == EventKind.kBreakpointResolved) {
        resolvedCount++;
      } else if (event.kind == EventKind.kPauseBreakpoint) {
        subscription.cancel();
        service.streamCancel(EventStreams.kDebug);
        completer.complete();
      }
    });

    await service.streamListen(EventStreams.kDebug);
    await service.resume(isolateId);
    await hasStoppedAtBreakpoint(service, isolate);

    // After resolution the breakpoints have assigned line & column.
    expect(resolvedCount, 1);
    futureBpt = await service.getObject(isolateId, futureBpt.id!) as Breakpoint;
    expect(futureBpt.resolved, isTrue);
    expect(
        script.getLineNumberFromTokenPos(futureBpt.location!.tokenPos), LINE);
    expect(futureBpt.location!.line, LINE);
    expect(
        script.getColumnNumberFromTokenPos(futureBpt.location!.tokenPos), COL);
    expect(futureBpt.location!.column, COL);

    // Remove the breakpoints.
    expect((await service.removeBreakpoint(isolateId, futureBpt.id!)).type,
        'Success');
  },
];

main(args) => runIsolateTests(
      args,
      tests,
      'breakpoint_async_break_test.dart',
      testeeConcurrent: testMain,
      pause_on_start: true,
    );
