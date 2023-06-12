// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/test_helper.dart';

int counter = 0;

void funcB() {
  counter++; // line 13
  if (counter % 100000000 == 0) {
    print(counter);
  }
}

void funcA() {
  funcB();
}

void testFunction() {
  while (true) {
    funcA();
  }
}

var tests = <IsolateTest>[
// Go to breakpoint at line 13.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    // Set up a listener to wait for breakpoint events.
    final completer = Completer<void>();

    late final StreamSubscription subscription;
    subscription = service.onDebugEvent.listen((event) async {
      if (event.kind == EventKind.kPauseBreakpoint) {
        print('Breakpoint reached');
        await service.streamCancel(EventStreams.kDebug);
        await subscription.cancel();
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kDebug);

    // Add the breakpoint.
    final script = rootLib.scripts![0];
    final line = 13;
    await service.addBreakpoint(isolateId, script.id!, line);
    await completer.future; // Wait for breakpoint reached.
  },

// Inspect code objects for top two frames.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    Stack stack = await service.getStack(isolateId);
    // Make sure we are in the right place.
    expect(stack.frames!.length, greaterThanOrEqualTo(3));
    final frame0 = stack.frames![0];
    final frame1 = stack.frames![1];
    expect(frame0.function!.name, equals('funcB'));
    expect(frame1.function!.name, equals('funcA'));
    final codeId0 = frame0.code!.id!;
    final codeId1 = frame1.code!.id!;

    // Load code from frame 0.
    Code code = await service.getObject(isolateId, codeId0) as Code;
    expect(code.name, contains('funcB'));
    expect(code.json!['_disassembly'], isNotNull);
    expect(code.json!['_disassembly'].length, greaterThan(0));

    // Load code from frame 0.
    code = await service.getObject(isolateId, codeId1) as Code;
    expect(code.type, equals('Code'));
    expect(code.name, contains('funcA'));
    expect(code.json!['_disassembly'], isNotNull);
    expect(code.json!['_disassembly'].length, greaterThan(0));
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'code_test.dart',
      testeeConcurrent: testFunction,
    );
