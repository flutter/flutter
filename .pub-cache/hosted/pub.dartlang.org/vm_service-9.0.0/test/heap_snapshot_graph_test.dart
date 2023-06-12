// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

class Foo {
  dynamic left;
  dynamic right;
}

late Foo r;

late List lst;

void script() {
  // Create 3 instances of Foo, with out-degrees
  // 0 (for b), 1 (for a), and 2 (for staticFoo).
  r = Foo();
  var a = Foo();
  var b = Foo();
  r.left = a;
  r.right = b;
  a.left = b;

  lst = List.filled(2, null);
  lst[0] = lst; // Self-loop.
  // Larger than any other fixed-size list in a fresh heap.
  lst[1] = List.filled(1234569, null);
}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolate) async {
    final snapshotGraph = await HeapSnapshotGraph.getSnapshot(service, isolate);
    expect(snapshotGraph.name, "main");
    expect(snapshotGraph.flags, isNotNull);
    expect(snapshotGraph.objects, isNotNull);
    expect(snapshotGraph.objects, isNotEmpty);

    int actualShallowSize = 0;
    int actualRefCount = 0;
    snapshotGraph.objects.forEach((HeapSnapshotObject o) {
      // -1 is the CID used by the sentinel.
      expect(o.classId >= -1, isTrue);
      expect(o.data, isNotNull);
      expect(o.references, isNotNull);
      actualShallowSize += o.shallowSize;
      actualRefCount += o.references.length;
    });

    // Some accounting differences in the VM result in the global shallow size
    // often being greater than the sum of the object shallow sizes.
    expect(snapshotGraph.shallowSize >= actualShallowSize, isTrue);
    expect(snapshotGraph.shallowSize <= snapshotGraph.capacity, isTrue);
    expect(snapshotGraph.referenceCount >= actualRefCount, isTrue);

    int actualExternalSize = 0;
    expect(snapshotGraph.externalProperties, isNotEmpty);
    snapshotGraph.externalProperties.forEach((HeapSnapshotExternalProperty e) {
      actualExternalSize += e.externalSize;
      expect(e.object >= 0, isTrue);
      expect(e.name, isNotNull);
    });
    expect(snapshotGraph.externalSize, actualExternalSize);

    expect(snapshotGraph.classes, isNotEmpty);
    snapshotGraph.classes.forEach((HeapSnapshotClass c) {
      expect(c.name, isNotNull);
      expect(c.libraryName, isNotNull);
      expect(c.libraryUri, isNotNull);
      expect(c.fields, isNotNull);
    });

    // We have the class "Foo".
    int foosFound = 0;
    int fooClassId = -1;
    for (int i = 0; i < snapshotGraph.classes.length; i++) {
      HeapSnapshotClass c = snapshotGraph.classes[i];
      if (c.name == "Foo" &&
          c.libraryUri.toString().endsWith("heap_snapshot_graph_test.dart")) {
        foosFound++;
        fooClassId = i;
      }
    }
    expect(foosFound, equals(1));

    // It knows about "Foo" objects.
    foosFound = 0;
    snapshotGraph.objects.forEach((HeapSnapshotObject o) {
      if (o.classId == 0) return;
      if (o.classId == fooClassId) {
        foosFound++;
      }
    });
    expect(foosFound, equals(3));

    // Check that we can get another snapshot.
    final snapshotGraph2 =
        await HeapSnapshotGraph.getSnapshot(service, isolate);
    expect(snapshotGraph2.name, "main");
  },
];

main([args = const <String>[]]) async => runIsolateTests(
      args,
      tests,
      'heap_snapshot_graph_test.dart',
      testeeBefore: script,
    );
