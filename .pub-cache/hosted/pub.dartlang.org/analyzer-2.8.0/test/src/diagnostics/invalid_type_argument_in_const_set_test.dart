// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidTypeArgumentInConstSetTest);
  });
}

@reflectiveTest
class InvalidTypeArgumentInConstSetTest extends PubPackageResolutionTest {
  test_type_parameter() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <E>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET, 39, 1,
          messageContains: ["'E'"]),
    ]);
  }
}
