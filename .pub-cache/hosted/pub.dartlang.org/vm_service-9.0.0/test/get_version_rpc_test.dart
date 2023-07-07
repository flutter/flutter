// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

var tests = <VMTest>[
  (VmService vm) async {
    final result = await vm.getVersion();
    expect(result.major! > 0, isTrue);
    expect(result.minor! >= 0, isTrue);
  },
];

main([args = const <String>[]]) async => await runVMTests(
      args,
      tests,
      'get_version_rpc_test.dart',
    );
