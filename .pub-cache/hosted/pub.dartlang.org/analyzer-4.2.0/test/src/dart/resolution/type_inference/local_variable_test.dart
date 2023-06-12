// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableTest);
    defineReflectiveTests(LocalVariableWithoutNullSafetyTest);
  });
}

@reflectiveTest
class LocalVariableTest extends PubPackageResolutionTest
    with LocalVariableTestCases {
  test_Never() async {
    await resolveTestCode('''
void f(Never a) {
  var v = a;
  v;
}
''');
    _assertTypeOfV('Never');
  }
}

mixin LocalVariableTestCases on PubPackageResolutionTest {
  test_int() async {
    await resolveTestCode('''
void f() {
  var v = 0;
  v;
}
''');
    _assertTypeOfV('int');
  }

  test_null() async {
    await resolveTestCode('''
void f() {
  var v = null;
  v;
}
''');
    _assertTypeOfV('dynamic');
  }

  void _assertTypeOfV(String expected) {
    assertType(findElement.localVar('v').type, expected);
    assertType(findNode.simple('v;'), expected);
  }
}

@reflectiveTest
class LocalVariableWithoutNullSafetyTest extends PubPackageResolutionTest
    with LocalVariableTestCases, WithoutNullSafetyMixin {}
