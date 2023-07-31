// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as service;

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

testMain() async {
  await Isolate.spawnUri(Platform.script, ['--selftest'], null,
      debugName: 'foo');
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (service.VmService service, _) async {
    final vm = await service.getVM();
    expect(vm.isolates!.length, 1);
    expect(vm.isolates!.first.name, 'foo');
    expect(vm.systemIsolates!.length, greaterThanOrEqualTo(1));
    expect(vm.systemIsolates!.where((e) => e.name == 'main').isNotEmpty, true);
  },
  resumeIsolate,
];

main([args = const <String>[]]) {
  if (args.length > 0 && args[0] == '--selftest') {
    debugger();
    return;
  }
  return runIsolateTests(
    args,
    tests,
    'mark_main_isolate_as_system_isolate_test.dart',
    testeeConcurrent: testMain,
    extraArgs: ['--mark-main-isolate-as-system-isolate'],
  );
}
