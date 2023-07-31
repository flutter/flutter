// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

class Point {
  int x, y;
  Point(this.x, this.y);
}

void testeeDo() {
  inspect(Point(3, 4));
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);

    final completer = Completer();
    late StreamSubscription sub;
    sub = service.onDebugEvent.listen((event) async {
      if (event.kind == EventKind.kInspect) {
        expect(event.inspectee!.classRef!.name, 'Point');
        await sub.cancel();
        await service.streamCancel(EventStreams.kDebug);
        completer.complete();
      }
    });

    await service.streamListen(EventStreams.kDebug);

    // Start listening for events first.
    await service.evaluate(
      isolateRef.id!,
      isolate.rootLib!.id!,
      'testeeDo()',
    );
    await completer.future;
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'debugger_inspect_test.dart',
    );
