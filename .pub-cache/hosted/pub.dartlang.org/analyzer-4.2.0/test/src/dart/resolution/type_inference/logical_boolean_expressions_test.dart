// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalAndTest);
    defineReflectiveTests(LogicalAndWithoutNullSafetyTest);
    defineReflectiveTests(LogicalOrTest);
    defineReflectiveTests(LogicalOrWithoutNullSafetyTest);
  });
}

@reflectiveTest
class LogicalAndTest extends PubPackageResolutionTest with LogicalAndTestCases {
  @failingTest
  test_downward() async {
    await resolveTestCode('''
void f(b) {
  var c = a() && b();
  print(c);
}
T a<T>() => throw '';
T b<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
    assertInvokeType(findNode.methodInvocation('b('), 'bool Function()');
  }
}

mixin LogicalAndTestCases on PubPackageResolutionTest {
  test_upward() async {
    await resolveTestCode('''
void f(bool a, bool b) {
  var c = a && b;
  print(c);
}
''');
    assertType(findNode.simple('c)'), 'bool');
  }
}

@reflectiveTest
class LogicalAndWithoutNullSafetyTest extends PubPackageResolutionTest
    with LogicalAndTestCases, WithoutNullSafetyMixin {}

@reflectiveTest
class LogicalOrTest extends PubPackageResolutionTest with LogicalOrTestCases {
  @failingTest
  test_downward() async {
    await resolveTestCode('''
void f(b) {
  var c = a() || b();
  print(c);
}
T a<T>() => throw '';
T b<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
    assertInvokeType(findNode.methodInvocation('b('), 'bool Function()');
  }
}

mixin LogicalOrTestCases on PubPackageResolutionTest {
  test_upward() async {
    await resolveTestCode('''
void f(bool a, bool b) {
  var c = a || b;
  print(c);
}
''');
    assertType(findNode.simple('c)'), 'bool');
  }
}

@reflectiveTest
class LogicalOrWithoutNullSafetyTest extends PubPackageResolutionTest
    with LogicalOrTestCases, WithoutNullSafetyMixin {}
