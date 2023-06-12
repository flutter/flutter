// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 24;
const int LINE_B = 26;

int value = 0;

int incValue(int amount) {
  value += amount;
  return amount;
}

Future testMain() async {
  incValue(incValue(1)); // line A.

  incValue(incValue(1)); // line B.
}

var tests = <IsolateTest>[
  hasPausedAtStart,

  // Test future breakpoints.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final rootLibId = rootLib.id!;
    final scriptId = rootLib.scripts![0].id!;
    final script = await service.getObject(isolateId, scriptId) as Script;

    // Future breakpoint.
    var futureBpt1 = await service.addBreakpoint(isolateId, scriptId, LINE_A);
    expect(futureBpt1.breakpointNumber, 1);
    expect(futureBpt1.resolved, isFalse);
    expect(await futureBpt1.location!.line!, LINE_A);
    expect(await futureBpt1.location!.column, null);

    // Future breakpoint with specific column.
    var futureBpt2 =
        await service.addBreakpoint(isolateId, scriptId, LINE_A, column: 3);
    expect(futureBpt2.breakpointNumber, 2);
    expect(futureBpt2.resolved, isFalse);
    expect(await futureBpt2.location!.line!, LINE_A);
    expect(await futureBpt2.location!.column!, 3);

    int resolvedCount = await resumeAndCountResolvedBreakpointsUntilPause(
      service,
      isolate,
    );

    // After resolution the breakpoints have assigned line & column.
    expect(resolvedCount, 2);

    // Refresh objects
    futureBpt1 =
        await service.getObject(isolateId, futureBpt1.id!) as Breakpoint;
    futureBpt2 =
        await service.getObject(isolateId, futureBpt2.id!) as Breakpoint;

    expect(futureBpt1.resolved, isTrue);
    expect(script.getLineNumberFromTokenPos(futureBpt1.location!.tokenPos!),
        LINE_A);
    expect(futureBpt1.location!.line, LINE_A);
    expect(
        script.getColumnNumberFromTokenPos(futureBpt1.location!.tokenPos!), 12);
    expect(futureBpt1.location!.column, 12);
    expect(futureBpt2.resolved, isTrue);
    expect(script.getLineNumberFromTokenPos(futureBpt2.location!.tokenPos!),
        LINE_A);
    expect(futureBpt2.location!.line, LINE_A);
    expect(
        script.getColumnNumberFromTokenPos(futureBpt2.location!.tokenPos!), 3);
    expect(futureBpt2.location!.column, 3);

    // The first breakpoint hits before value is modified.
    InstanceRef result =
        await service.evaluate(isolateId, rootLibId, 'value') as InstanceRef;
    expect(result.valueAsString, '0');

    await service.resume(isolateId);
    await hasStoppedAtBreakpoint(service, isolate);

    // The second breakpoint hits after value has been modified once.
    result =
        await service.evaluate(isolateId, rootLibId, 'value') as InstanceRef;
    expect(result.valueAsString, '1');

    // Remove the breakpoints.
    expect((await service.removeBreakpoint(isolateId, futureBpt1.id!)).type,
        'Success');
    expect((await service.removeBreakpoint(isolateId, futureBpt2.id!)).type,
        'Success');
  },

  // Test resolution of column breakpoints.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;
    final rootLib = await service.getObject(isolateId, rootLibId) as Library;

    final scriptId = rootLib.scripts![0].id!;
    final script = await service.getObject(isolateId, scriptId) as Script;

    // Try all columns, including some columns that are too big.
    for (int col = 1; col <= 50; col++) {
      final bpt =
          await service.addBreakpoint(isolateId, scriptId, LINE_A, column: col);
      expect(bpt.resolved, isTrue);
      int resolvedLine =
          script.getLineNumberFromTokenPos(bpt.location!.tokenPos!)!;
      int resolvedCol =
          script.getColumnNumberFromTokenPos(bpt.location!.tokenPos!)!;
      print('$LINE_A:${col} -> ${resolvedLine}:${resolvedCol}');
      if (col <= 12) {
        expect(resolvedLine, LINE_A);
        expect(bpt.location!.line, LINE_A);
        expect(resolvedCol, 3);
        expect(bpt.location!.column, 3);
      } else if (col <= 36) {
        expect(resolvedLine, LINE_A);
        expect(bpt.location!.line, LINE_A);
        expect(resolvedCol, 12);
        expect(bpt.location!.column, 12);
      } else {
        expect(resolvedLine, LINE_B);
        expect(bpt.location!.line, LINE_B);
        expect(resolvedCol, 12);
        expect(bpt.location!.column, 12);
      }
      expect(
          (await service.removeBreakpoint(isolateId, bpt.id!)).type, 'Success');
    }

    // Make sure that a zero column is an error.
    var caughtException = false;
    try {
      await service.addBreakpoint(isolateId, scriptId, 20, column: 0);
      expect(false, isTrue, reason: 'Unreachable');
    } on RPCError catch (e) {
      caughtException = true;
      expect(e.code, RPCError.kInvalidParams);
      expect(e.details, "addBreakpoint: invalid 'column' parameter: 0");
    }
    expect(caughtException, isTrue);
  },
];

Future<int> resumeAndCountResolvedBreakpointsUntilPause(
    VmService service, Isolate isolate) async {
  final completer = Completer<void>();
  late StreamSubscription subscription;
  int resolvedCount = 0;

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

  await service.resume(isolate.id!);
  await completer.future;
  return resolvedCount;
}

main(args) => runIsolateTests(
      args,
      tests,
      'add_breakpoint_rpc_kernel_test.dart',
      testeeConcurrent: testMain,
      pause_on_start: true,
    );
