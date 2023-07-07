// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

var tests = <VMTest>[
  (VmService service) async {
    final vm = await service.getVM();
    final result = await service.getIsolate(vm.isolates!.first.id!);
    expect(result.id, startsWith('isolates/'));
    expect(result.number, isNotNull);
    expect(result.isolateFlags, isNotNull);
    expect(result.isolateFlags!.length, isPositive);
    expect(result.isSystemIsolate, isFalse);
    expect(result.json!['_originNumber'], result.number);
    expect(result.startTime, isPositive);
    expect(result.livePorts, isPositive);
    expect(result.pauseOnExit, isFalse);
    expect(result.pauseEvent!.type, 'Event');
    expect(result.error, isNull);
    expect(result.rootLib, isNotNull);
    expect(result.libraries!.length, isPositive);
    expect(result.libraries![0], isNotNull);
    expect(result.breakpoints!.length, isZero);
    expect(result.json!['_heaps']['new']['type'], 'HeapSpace');
    expect(result.json!['_heaps']['old']['type'], 'HeapSpace');
  },

  (VmService service) async {
    bool caughtException = false;
    try {
      await service.getIsolate('badid');
      expect(false, isTrue, reason: 'Unreachable');
    } on RPCError catch (e) {
      caughtException = true;
      expect(e.code, equals(RPCError.kInvalidParams));
      expect(e.details, "getIsolate: invalid 'isolateId' parameter: badid");
    }
    expect(caughtException, isTrue);
  },

  // Plausible isolate id, not found.
  (VmService service) async {
    try {
      await service.getIsolate('isolates/9999999999');
      fail('successfully got isolate with bad ID');
    } on SentinelException catch (e) {
      expect(e.sentinel.kind, 'Collected');
      expect(e.sentinel.valueAsString, '<collected>');
    }
  },
];

main([args = const <String>[]]) async => runVMTests(
      args,
      tests,
      'get_isolate_rpc_test.dart',
    );
