// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

var tests = <VMTest>[
  (VmService vm) async {
    // Invoke a non-existent RPC.
    try {
      final res = await vm.callMethod('foo');
      fail('Expected RPCError, got $res');
    } on RPCError catch (e, st) {
      // Ensure stack trace contains actual invocation path.
      final stack = st.toString().split('\n');
      expect(stack.where((e) => e.contains('VmService.callMethod')).length, 1);
      // Call to vm.callMethod('foo').
      expect(
          stack.where((e) => e.contains('test/rpc_error_test.dart')).length, 1);
    } catch (e) {
      fail('Expected RPCError, got $e');
    }
  },
];

main([args = const <String>[]]) async => await runVMTests(
      args,
      tests,
      'rpc_error_test.dart',
    );
