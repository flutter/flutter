// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

class Foo {}

// Prevent TFA from removing this static field to ensure the objects are kept
// alive, so the allocation stats will report them via the service api.
@pragma('vm:entry-point')
List<Foo>? foos;

void script() {
  foos = [
    Foo(),
    Foo(),
    Foo(),
  ];
}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    var profile = await service.callMethod('_getAllocationProfile',
        isolateId: isolateRef.id!) as AllocationProfile;
    print(profile.runtimeType);
    var classHeapStats = profile.members!.singleWhere((stats) {
      return stats.classRef!.name == 'Foo';
    });
    expect(classHeapStats.instancesCurrent, 3);
    expect(classHeapStats.instancesAccumulated, 3);
  },
];

main(args) => runIsolateTests(
      args,
      tests,
      'allocations_test.dart',
      testeeBefore: script,
    );
