// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

class Foo {
  static Bar b = Bar();
}

class Bar {}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolate) async {
    final classes = (await service.getClassList(isolate.id!)).classes!;
    final fooRef = classes.firstWhere((element) => element.name == 'Foo');
    final foo = (await service.getObject(isolate.id!, fooRef.id!)) as Class;
    final field =
        (await service.getObject(isolate.id!, foo.fields!.first.id!)) as Field;
    expect(field.staticValue!.valueAsString, '<not initialized>');
  }
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'regress_44588_test.dart',
    );
