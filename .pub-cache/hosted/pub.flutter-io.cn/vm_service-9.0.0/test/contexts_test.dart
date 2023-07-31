// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

// Make sure these variables are not removed by the tree shaker.
@pragma("vm:entry-point")
var cleanBlock;
@pragma("vm:entry-point")
var copyingBlock;
@pragma("vm:entry-point")
var fullBlock;
@pragma("vm:entry-point")
var fullBlockWithChain;

Function genCleanBlock() {
  block(x) => x;
  return block;
}

Function genCopyingBlock() {
  final x = 'I could be copied into the block';
  block() => x;
  return block;
}

Function genFullBlock() {
  var x = 42; // I must captured in a context.
  block() => x;
  x++;
  return block;
}

Function genFullBlockWithChain() {
  var x = 420; // I must captured in a context.
  outerBlock() {
    var y = 4200;
    innerBlock() => x + y;
    y++;
    return innerBlock;
  }

  x++;
  return outerBlock();
}

void script() {
  cleanBlock = genCleanBlock();
  copyingBlock = genCopyingBlock();
  fullBlock = genFullBlock();
  fullBlockWithChain = genFullBlockWithChain();
}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final lib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final field = await service.getObject(
      isolateId,
      lib.variables!.singleWhere((v) => v.name == 'cleanBlock').id!,
    ) as Field;

    Instance block =
        await service.getObject(isolateId, field.staticValue!.id!) as Instance;
    expect(block.closureFunction, isNotNull);
    expect(block.closureContext, isNull);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final lib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final field = await service.getObject(
      isolateId,
      lib.variables!.singleWhere((v) => v.name == 'copyingBlock').id!,
    ) as Field;
    Instance block =
        await service.getObject(isolateId, field.staticValue!.id!) as Instance;

    expect(block.closureContext, isNotNull);
    expect(block.closureContext!.length, equals(1));
    final ctxt = await service.getObject(isolateId, block.closureContext!.id!)
        as Context;
    expect(ctxt.variables!.single.value.kind, InstanceKind.kString);
    expect(
      ctxt.variables!.single.value.valueAsString,
      'I could be copied into the block',
    );
    expect(ctxt.parent, isNull);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final lib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final field = await service.getObject(
      isolateId,
      lib.variables!.singleWhere((v) => v.name == 'fullBlock').id!,
    ) as Field;
    Instance block =
        await service.getObject(isolateId, field.staticValue!.id!) as Instance;

    expect(block.closureContext, isNotNull);
    expect(block.closureContext!.length, equals(1));
    final ctxt = await service.getObject(isolateId, block.closureContext!.id!)
        as Context;

    expect(ctxt.variables!.single.value.kind, InstanceKind.kInt);
    expect(ctxt.variables!.single.value.valueAsString, '43');
    expect(ctxt.parent, isNull);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final lib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final field = await service.getObject(
      isolateId,
      lib.variables!.singleWhere((v) => v.name == 'fullBlockWithChain').id!,
    ) as Field;
    final block =
        await service.getObject(isolateId, field.staticValue!.id!) as Instance;

    expect(block.closureContext, isNotNull);
    expect(block.closureContext!.length, equals(1));
    final ctxt = await service.getObject(isolateId, block.closureContext!.id!)
        as Context;
    expect(ctxt.variables!.single.value.kind, InstanceKind.kInt);
    expect(ctxt.variables!.single.value.valueAsString, '4201');
    expect(ctxt.parent!.length, 1);

    final outerCtxt =
        await service.getObject(isolateId, ctxt.parent!.id!) as Context;
    expect(outerCtxt.variables!.single.value.kind, InstanceKind.kInt);
    expect(outerCtxt.variables!.single.value.valueAsString, '421');
    expect(outerCtxt.parent, isNull);
  },
];

main(args) => runIsolateTests(
      args,
      tests,
      'contexts_test.dart',
      testeeBefore: script,
    );
