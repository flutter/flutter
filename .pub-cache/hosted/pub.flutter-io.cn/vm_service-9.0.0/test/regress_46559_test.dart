// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<ServiceExtensionResponse> echo(
    String method, Map<String, String> args) async {
  print('In service extension');
  return ServiceExtensionResponse.result(json.encode(args));
}

testMain() {
  registerExtension('ext.foo', echo);
  debugger();
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  resumeIsolate,
  (VmService vm, IsolateRef isolateRef) async {
    print('waiting for response');
    final response = await vm.callServiceExtension(
      'ext.foo',
      isolateId: isolateRef.id!,
      args: {'foo': 'bar'},
    );
    print('got response');
    print(response.json);
  },
];

main([args = const <String>[]]) async => await runIsolateTests(
      args,
      tests,
      'regress_46559_test.dart',
      testeeConcurrent: testMain,
    );
