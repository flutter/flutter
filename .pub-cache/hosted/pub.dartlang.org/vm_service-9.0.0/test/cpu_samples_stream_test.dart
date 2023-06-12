// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// TODO(bkonyi): re-import after sample streaming is fixed.
// import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

fib(int n) {
  if (n <= 1) {
    return n;
  }
  return fib(n - 1) + fib(n - 2);
}

void testMain() async {
  int i = 10;
  while (true) {
    ++i;
    // Create progressively deeper stacks to more quickly fill the sample
    // buffer.
    fib(i);
  }
}

late StreamSubscription sub;

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolate) async {
    // TODO(bkonyi): re-enable after sample streaming is fixed.
    // See https://github.com/dart-lang/sdk/issues/46825
    /*final completer = Completer<void>();
    int count = 0;
    int previousOrigin = 0;
    sub = service.onProfilerEvent.listen((event) async {
      count++;
      expect(event.kind, EventKind.kCpuSamples);
      expect(event.cpuSamples, isNotNull);
      expect(event.cpuSamples!.samples!.isNotEmpty, true);
      if (previousOrigin != 0) {
        expect(
          event.cpuSamples!.timeOriginMicros! >= previousOrigin,
          true,
        );
      }
      previousOrigin = event.cpuSamples!.timeOriginMicros!;

      if (count == 2) {
        await sub.cancel();
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kProfiler);

    await completer.future;
    await service.streamCancel(EventStreams.kProfiler);
    */
  },
];

main([args = const <String>[]]) async => await runIsolateTests(
      args,
      tests,
      'cpu_samples_stream_test.dart',
      testeeConcurrent: testMain,
      extraArgs: [
        '--sample-buffer-duration=1',
        '--profile-vm',
      ],
    );
