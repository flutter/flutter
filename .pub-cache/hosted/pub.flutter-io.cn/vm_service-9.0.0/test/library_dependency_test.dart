// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: unused_import
import 'dart:isolate' show Isolate, SendPort hide Capability;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

export 'dart:io' show Socket hide SecureSocket;

void testMain() => null;

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id!);
    final libRef = isolate.libraries!.firstWhere(
      (lib) => lib.uri!.contains('library_dependency_test.dart'),
    );
    final lib = await service.getObject(isolate.id!, libRef.id!) as Library;

    for (final dep in lib.dependencies!) {
      final name = dep.target!.name!;
      if (name == 'dart.isolate') {
        expect(dep.isImport, true);
        expect(dep.shows, ['Isolate', 'SendPort']);
        expect(dep.hides, ['Capability']);
      } else if (name == 'dart.io') {
        expect(dep.isImport, false);
        expect(dep.shows, ['Socket']);
        expect(dep.hides, ['SecureSocket']);
      } else {
        expect(dep.isImport, true);
        expect(dep.shows, null);
        expect(dep.hides, null);
      }
    }
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'library_dependency_test.dart',
      testeeConcurrent: testMain,
    );
