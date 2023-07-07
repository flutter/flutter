// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeCheckIsNotNullTest);
  });
}

@reflectiveTest
class TypeCheckIsNotNullTest extends PubPackageResolutionTest {
  test_not_Null() async {
    await assertErrorsInCode(r'''
bool m(i) {
  return i is! Null;
}
''', [
      error(HintCode.TYPE_CHECK_IS_NOT_NULL, 21, 10),
    ]);
  }
}
