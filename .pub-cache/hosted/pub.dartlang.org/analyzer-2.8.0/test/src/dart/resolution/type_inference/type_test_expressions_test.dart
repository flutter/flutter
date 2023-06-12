// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsNotTest);
    defineReflectiveTests(IsNotWithoutNullSafetyTest);
    defineReflectiveTests(IsTest);
    defineReflectiveTests(IsWithoutNullSafetyTest);
  });
}

@reflectiveTest
class IsNotTest extends PubPackageResolutionTest with IsNotTestCases {}

mixin IsNotTestCases on PubPackageResolutionTest {
  test_simple() async {
    await resolveTestCode('''
void f(Object a) {
  var b = a is! String;
  print(b);
}
''');
    assertType(findNode.simple('b)'), 'bool');
  }
}

@reflectiveTest
class IsNotWithoutNullSafetyTest extends PubPackageResolutionTest
    with IsNotTestCases, WithoutNullSafetyMixin {}

@reflectiveTest
class IsTest extends PubPackageResolutionTest with IsTestCases {}

mixin IsTestCases on PubPackageResolutionTest {
  test_simple() async {
    await resolveTestCode('''
void f(Object a) {
  var b = a is String;
  print(b);
}
''');
    assertType(findNode.simple('b)'), 'bool');
  }
}

@reflectiveTest
class IsWithoutNullSafetyTest extends PubPackageResolutionTest
    with IsTestCases, WithoutNullSafetyMixin {}
