// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidTypeArgumentInConstMapTest);
  });
}

@reflectiveTest
class InvalidTypeArgumentInConstMapTest extends PubPackageResolutionTest {
  test_key() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <E, String>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP, 39, 1,
          messageContains: ["'E'"]),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
class A<E> {
  m() {
    return <String, E>{};
  }
}
''');
  }

  test_value() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <String, E>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP, 47, 1,
          messageContains: ["'E'"]),
    ]);
  }
}
