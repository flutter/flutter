// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrivateOptionalParameterTest);
  });
}

@reflectiveTest
class PrivateOptionalParameterTest extends PubPackageResolutionTest {
  test_fieldFormal() async {
    await assertErrorsInCode(r'''
class A {
  var _p;
  A({this._p: 0});
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 30, 2),
    ]);
  }

  test_private() async {
    await assertErrorsInCode('''
f({var _p}) {}
''', [
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 7, 2),
    ]);
  }

  test_withDefaultValue() async {
    await assertErrorsInCode('''
f({_p : 0}) {}
''', [
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 3, 2),
    ]);
  }
}
