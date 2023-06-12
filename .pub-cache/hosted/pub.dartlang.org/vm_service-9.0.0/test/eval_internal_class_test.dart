// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
    ) as Library;
    Class classLibrary = await service.getObject(
      isolateId,
      rootLib.classRef!.id!,
    ) as Class;

    {
      bool caughtExceptions = false;
      try {
        dynamic result = await service.evaluate(
          isolateId,
          classLibrary.id!,
          '3 + 4',
        );
        print(result);
      } on RPCError catch (e) {
        expect(e.toString(), contains('can be evaluated only'));
        caughtExceptions = true;
      }
      expect(caughtExceptions, isTrue);
    }

    final classClass = await service.getObject(
      isolateId,
      classLibrary.classRef!.id!,
    ) as Class;
    {
      bool caughtExceptions = false;
      try {
        dynamic result = await service.evaluate(
          isolateId,
          classClass.id!,
          '3 + 4',
        );
        print(result);
      } on RPCError catch (e) {
        expect(e.toString(), contains('can be evaluated only'));
        caughtExceptions = true;
      }
      expect(caughtExceptions, isTrue);
    }
    final classArray = await service.getObject(
      isolateId,
      (await service.evaluate(
        isolateId,
        rootLib.id!,
        "List<dynamic>.filled(2, null)",
      ) as InstanceRef)
          .classRef!
          .id!,
    ) as Class;
    dynamic result = await service.evaluate(
      isolateId,
      classArray.id!,
      '3 + 4',
    );
    expect(result is InstanceRef, isTrue);
    expect(result.valueAsString, '7');
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'eval_internal_class_test.dart',
    );
