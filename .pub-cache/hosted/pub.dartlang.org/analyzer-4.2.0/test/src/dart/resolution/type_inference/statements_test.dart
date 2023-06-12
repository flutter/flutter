// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssertTest);
    defineReflectiveTests(DoTest);
    defineReflectiveTests(ForTest);
    defineReflectiveTests(IfTest);
    defineReflectiveTests(WhileTest);
  });
}

@reflectiveTest
class AssertTest extends PubPackageResolutionTest {
  test_downward() async {
    await resolveTestCode('''
void f() {
  assert(a());
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }
}

@reflectiveTest
class DoTest extends PubPackageResolutionTest {
  test_downward() async {
    await resolveTestCode('''
void f() {
  do {} while(a())
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }
}

@reflectiveTest
class ForTest extends PubPackageResolutionTest {
  test_awaitForIn_int_downward() async {
    await resolveTestCode('''
void f() async {
  await for (int e in a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'Stream<int> Function()');
  }

  test_awaitForIn_var_downward() async {
    await resolveTestCode('''
void f() async {
  await for (var e in a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Stream<Object?> Function()');
  }

  test_awaitForIn_var_upward() async {
    await resolveTestCode('''
void f(Stream<int> s) async {
  await for (var e in s) {
    e;
  }
}
''');
    assertType(findNode.simple('e;'), 'int');
  }

  test_for_downward() async {
    await resolveTestCode('''
void f() {
  for (int i = 0; a(); i++) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }

  test_forIn_dynamic_downward() async {
    await resolveTestCode('''
void f() {
  for (var e in a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<Object?> Function()');
  }

  test_forIn_int_downward() async {
    await resolveTestCode('''
void f() {
  for (int e in a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<int> Function()');
  }

  test_forIn_var_upward() async {
    await resolveTestCode('''
void f(List<int> s) async {
  for (var e in s) {
    e;
  }
}
''');
    assertType(findNode.simple('e;'), 'int');
  }
}

@reflectiveTest
class IfTest extends PubPackageResolutionTest {
  test_downward() async {
    await resolveTestCode('''
void f() {
  if (a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }
}

@reflectiveTest
class WhileTest extends PubPackageResolutionTest {
  test_downward() async {
    await resolveTestCode('''
void f() {
  while (a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }
}
