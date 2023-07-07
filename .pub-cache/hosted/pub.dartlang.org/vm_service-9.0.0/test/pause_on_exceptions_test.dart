// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

doThrow() {
  throw "TheException"; // Line 13.
}

doCaught() {
  try {
    doThrow();
  } catch (e) {
    return "end of doCaught";
  }
}

doUncaught() {
  doThrow();
  return "end of doUncaught";
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id!);
    final lib = await service.getObject(isolateRef.id!, isolate.rootLib!.id!);

    Completer? onPaused;
    Completer? onResume;

    final stream = service.onDebugEvent;
    final subscription = stream.listen((Event event) {
      print("Event $event");
      if (event.kind == EventKind.kPauseException) {
        if (onPaused == null) throw "Unexpected pause event $event";
        final t = onPaused;
        onPaused = null;
        t!.complete(event);
      }
      if (event.kind == EventKind.kResume) {
        if (onResume == null) throw "Unexpected resume event $event";
        final t = onResume;
        onResume = null;
        t!.complete(event);
      }
    });
    await service.streamListen(EventStreams.kDebug);

    test(String pauseMode, String expression, bool shouldPause,
        bool shouldBeCaught) async {
      print("Evaluating $expression with pause on $pauseMode exception");

      await service.setIsolatePauseMode(isolate.id!,
          exceptionPauseMode: pauseMode);

      late Completer t;
      if (shouldPause) {
        t = Completer();
        onPaused = t;
      }
      final fres = service.evaluate(isolate.id!, lib.id!, expression);
      if (shouldPause) {
        await t.future;

        final stack = await service.getStack(isolate.id!);
        expect(stack.frames![0].function!.name, 'doThrow');

        t = Completer();
        onResume = t;
        await service.resume(isolate.id!);
        await t.future;
      }

      dynamic res = await fres;
      if (shouldBeCaught) {
        expect(res is InstanceRef, true);
        expect(res.kind, 'String');
        expect(res.valueAsString, equals("end of doCaught"));
      } else {
        print(res.json);
        expect(res is ErrorRef, true);
        res = await service.getObject(isolate.id!, res.id!);
        expect(res is Error, true);
        expect(res.exception.kind, 'String');
        expect(res.exception.valueAsString, equals("TheException"));
      }
    }

    await test("All", "doCaught()", true, true);
    await test("All", "doUncaught()", true, false);

    await test("Unhandled", "doCaught()", false, true);
    await test("Unhandled", "doUncaught()", true, false);

    await test("None", "doCaught()", false, true);
    await test("None", "doUncaught()", false, false);

    await subscription.cancel();
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'pause_on_exceptions_test.dart',
    );
