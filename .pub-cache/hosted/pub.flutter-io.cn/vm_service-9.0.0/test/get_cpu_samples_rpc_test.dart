// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

fib(n) {
  if (n < 0) return 0;
  if (n == 0) return 1;
  return fib(n - 1) + fib(n - 2);
}

testeeDo() {
  print("Testee doing something.");
  fib(30);
  print("Testee did something.");
}

Future checkSamples(VmService service, IsolateRef isolate) async {
  // Grab all the samples.
  final isolateId = isolate.id!;
  final result = await service.getCpuSamples(isolateId, 0, ~0);

  final isString = TypeMatcher<String>();
  final isInt = TypeMatcher<int>();
  final isList = TypeMatcher<List>();
  expect(result.functions!.length, greaterThan(10),
      reason: "Should have many functions!");

  final samples = result.samples!;
  expect(samples.length, greaterThan(10), reason: "Should have many samples");
  expect(samples.length, result.sampleCount);

  final sample = samples.first;
  expect(sample.tid, isInt);
  expect(sample.timestamp, isInt);
  if (sample.vmTag != null) {
    expect(sample.vmTag, isString);
  }
  if (sample.userTag != null) {
    expect(sample.userTag, isString);
  }
  expect(sample.stack, isList);
}

var tests = <IsolateTest>[
  ((VmService service, IsolateRef i) => checkSamples(service, i)),
];

var vmArgs = [
  '--profiler=true',
  '--profile-vm=false', // So this also works with KBC.
];

main([args = const <String>[]]) async => runIsolateTests(
      args,
      tests,
      'get_cpu_samples_rpc_test.dart',
      testeeBefore: testeeDo,
      extraArgs: vmArgs,
    );
