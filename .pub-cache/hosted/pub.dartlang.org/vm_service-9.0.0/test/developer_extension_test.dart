// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:expect/expect.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<ServiceExtensionResponse> Handler(String method, Map paremeters) {
  print('Invoked extension: $method');
  switch (method) {
    case 'ext..delay':
      var c = Completer<ServiceExtensionResponse>();
      Timer(Duration(seconds: 1), () {
        c.complete(ServiceExtensionResponse.result(jsonEncode({
          'type': '_delayedType',
          'method': method,
          'parameters': paremeters,
        })));
      });
      return c.future;
    case 'ext..error':
      return Future<ServiceExtensionResponse>.value(
          ServiceExtensionResponse.error(
              ServiceExtensionResponse.extensionErrorMin, 'My error detail.'));
    case 'ext..exception':
      throw "I always throw!";
    case 'ext..success':
      return Future<ServiceExtensionResponse>.value(
          ServiceExtensionResponse.result(jsonEncode({
        'type': '_extensionType',
        'method': method,
        'parameters': paremeters,
      })));
  }
  throw "Unknown extension: $method";
}

void test() {
  registerExtension('ext..delay', Handler);
  debugger();
  postEvent('ALPHA', {'cat': 'dog'});
  debugger();
  registerExtension('ext..error', Handler);
  registerExtension('ext..exception', Handler);
  registerExtension('ext..success', Handler);
  bool exceptionThrown = false;
  try {
    registerExtension('ext..delay', Handler);
  } catch (e) {
    exceptionThrown = true;
  }
  // This check is running in the target process so we can't used package:test.
  Expect.equals(exceptionThrown, true);
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id!);
    // Note: extensions other than those is this test might already be
    // registered by core libraries.
    expect(isolate.extensionRPCs, contains('ext..delay'));
    expect(isolate.extensionRPCs, isNot(contains('ext..error')));
    expect(isolate.extensionRPCs, isNot(contains('ext..exception')));
    expect(isolate.extensionRPCs, isNot(contains('ext..success')));
  },
  resumeIsolateAndAwaitEvent(EventStreams.kExtension, (event) {
    expect(event.kind, EventKind.kExtension);
    expect(event.extensionKind, 'ALPHA');
    expect(event.extensionData!.data['cat'], equals('dog'));
  }),
  hasStoppedAtBreakpoint,
  resumeIsolateAndAwaitEvent(EventStreams.kIsolate, (event) {
    // Check that we received an event when '__error' was registered.
    expect(event.kind, equals(EventKind.kServiceExtensionAdded));
    expect(event.extensionRPC, 'ext..error');
  }),
  // Initial.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    var result = await service.callServiceExtension(
      'ext..delay',
      isolateId: isolateId,
    );

    expect(result.json!['type'], '_delayedType');
    expect(result.json!['method'], equals('ext..delay'));
    expect(result.json!['parameters']['isolateId'], isNotNull);

    try {
      await service.callServiceExtension(
        'ext..error',
        isolateId: isolateId,
      );
    } on RPCError catch (e) {
      expect(e.code, ServiceExtensionResponse.extensionErrorMin);
      expect(e.details, 'My error detail.');
    }

    try {
      await service.callServiceExtension(
        'ext..exception',
        isolateId: isolateId,
      );
    } on RPCError catch (e) {
      expect(e.code, ServiceExtensionResponse.extensionError);
      expect(e.details!.startsWith('I always throw!\n'), isTrue);
    }

    result = await service.callServiceExtension(
      'ext..success',
      isolateId: isolateId,
      args: {
        'apple': 'banana',
      },
    );
    expect(result.json!['type'], '_extensionType');
    expect(result.json!['method'], 'ext..success');
    expect(result.json!['parameters']['isolateId'], isNotNull);
    expect(result.json!['parameters']['apple'], 'banana');
  },
];

main([args = const <String>[]]) async => runIsolateTests(
      args,
      tests,
      'developer_extension_test.dart',
      testeeConcurrent: test,
    );
