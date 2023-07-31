// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

var tests = <VMTest>[
  (VmService service) async {
    final vm = await service.getVM();
    final result = await service.getMemoryUsage(vm.isolates!.first.id!);
    expect(result.heapUsage, isPositive);
    expect(result.heapCapacity, isPositive);
    expect(result.externalUsage, isPositive);
  },
  (VmService service) async {
    bool? caughtException;
    try {
      await service.getMemoryUsage('badid');
      fail('Unreachable');
    } on RPCError catch (e) {
      caughtException = true;
      expect(e.details,
          contains("getMemoryUsage: invalid 'isolateId' parameter: badid"));
    }
    expect(caughtException, isTrue);
  },
];

main([args = const <String>[]]) async => runVMTests(
      args,
      tests,
      'get_memory_usage_test.dart',
    );
