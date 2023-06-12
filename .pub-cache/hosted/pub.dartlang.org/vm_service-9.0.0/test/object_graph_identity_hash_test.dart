// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

class Foo {}

class Bar {}

class Container1 {
  @pragma("vm:entry-point")
  Foo foo = Foo();
  @pragma("vm:entry-point")
  Bar bar = Bar();
}

class Container2 {
  Container2(this.foo);

  @pragma("vm:entry-point")
  Foo foo;
  @pragma("vm:entry-point")
  Bar bar = Bar();
}

class Container3 {
  @pragma("vm:entry-point")
  int number = 42;
  @pragma("vm:entry-point")
  double doub = 3.14;
  @pragma("vm:entry-point")
  String foo = 'foobar';
  @pragma("vm:entry-point")
  bool bar = false;
  @pragma("vm:entry-point")
  late Map baz;
  @pragma("vm:entry-point")
  late LinkedHashMap linkedBaz;
  @pragma("vm:entry-point")
  late List list;
  @pragma("vm:entry-point")
  late List unmodifiableList;

  Container3() {
    baz = {
      'a': 'b',
    };
    linkedBaz = LinkedHashMap.from(baz);
    list = [1, 2, 3];
    unmodifiableList = List.empty();
  }
}

late Container1 c1;
late Container2 c2;
late Container3 c3;

void script() {
  c1 = Container1();
  c2 = Container2(c1.foo);
  c3 = Container3();
}

late HeapSnapshotGraph snapshot1;
late HeapSnapshotObject snapshot1Foo;
late HeapSnapshotObject snapshot1Bar;

late HeapSnapshotGraph snapshot2;
late HeapSnapshotObject snapshot2Foo;
late HeapSnapshotObject snapshot2Bar;

late HeapSnapshotGraph snapshot3;

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolate) async {
    snapshot1 = await HeapSnapshotGraph.getSnapshot(service, isolate);

    Iterable<HeapSnapshotObject> container1s = snapshot1.objects.where(
      (HeapSnapshotObject obj) => obj.klass.name == 'Container1',
    );
    expect(container1s.length, 1);

    final c1Obj = container1s.first;

    snapshot1Foo = c1Obj.successors.firstWhere(
      (element) => element.klass.name == 'Foo',
    );
    expect(
      snapshot1Foo.identityHashCode != 0,
      true,
    );

    snapshot1Bar = c1Obj.successors.firstWhere(
      (element) => element.klass.name == 'Bar',
    );
    expect(
      snapshot1Bar.identityHashCode != 0,
      true,
    );
  },
  (VmService service, IsolateRef isolate) async {
    snapshot2 = await HeapSnapshotGraph.getSnapshot(service, isolate);
    ;
    Iterable<HeapSnapshotObject> container2s = snapshot2.objects.where(
      (HeapSnapshotObject obj) => obj.klass.name == 'Container2',
    );
    expect(container2s.length, 1);

    final c2Obj = container2s.first;

    snapshot2Foo = c2Obj.successors.firstWhere(
      (element) => element.klass.name == 'Foo',
    );
    expect(
      snapshot2Foo.identityHashCode != 0,
      true,
    );
    expect(
      snapshot1Foo.identityHashCode == snapshot2Foo.identityHashCode,
      true,
    );

    snapshot2Bar = c2Obj.successors.firstWhere(
      (element) => element.klass.name == 'Bar',
    );
    expect(
      snapshot2Bar.identityHashCode != 0,
      true,
    );
    expect(
      snapshot1Bar.identityHashCode != snapshot2Bar.identityHashCode,
      true,
    );
  },
  (VmService service, IsolateRef isolate) async {
    snapshot3 = await HeapSnapshotGraph.getSnapshot(service, isolate);
    Iterable<HeapSnapshotObject> container3s = snapshot3.objects.where(
      (HeapSnapshotObject obj) => obj.klass.name == 'Container3',
    );
    expect(container3s.length, 1);
    final c3Obj = container3s.first;
    for (final successor in c3Obj.successors) {
      expect(successor.identityHashCode, 0);
    }
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'object_graph_identity_hash_test.dart',
      testeeBefore: script,
      pause_on_exit: true,
    );
