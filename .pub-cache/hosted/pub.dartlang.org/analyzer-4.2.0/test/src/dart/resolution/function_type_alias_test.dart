// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypeAliasResolutionTest);
  });
}

@reflectiveTest
class FunctionTypeAliasResolutionTest extends PubPackageResolutionTest {
  test_type_element() async {
    await resolveTestCode(r'''
G<int> g;

typedef T G<T>();
''');
    var type = findElement.topVar('g').type as FunctionType;
    assertType(type, 'int Function()');
    assertTypeAlias(
      type,
      element: findElement.typeAlias('G'),
      typeArguments: ['int'],
    );
  }
}
