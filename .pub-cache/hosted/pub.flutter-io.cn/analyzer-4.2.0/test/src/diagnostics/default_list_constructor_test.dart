// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultListConstructorMismatch);
  });
}

@reflectiveTest
class DefaultListConstructorMismatch extends PubPackageResolutionTest {
  test_inferredType() async {
    await assertErrorsInCode('''
List<int> v = List(5);
''', [
      error(CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR, 14, 4),
    ]);
  }

  test_nonNullableType() async {
    await assertErrorsInCode('''
var l = new List<int>(3);
''', [
      error(CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR, 12, 9),
    ]);
  }

  test_notDefaultConstructor() async {
    await assertNoErrorsInCode('''
var x = List<int>.unmodifiable([]);
''');
  }

  test_nullableType() async {
    await assertErrorsInCode('''
var l = new List<int?>(3);
''', [
      error(CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR, 12, 10),
    ]);
  }

  test_optOut() async {
    await assertNoErrorsInCode('''
// @dart = 2.2
var l = new List<int>(3);
''');
  }

  test_typeParameter() async {
    await assertErrorsInCode('''
class C<T> {
  var l = new List<T>(3);
}
''', [
      error(CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR, 27, 7),
    ]);
  }
}
