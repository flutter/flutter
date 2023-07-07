// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassInstantiationAccessToMemberTest);
  });
}

@reflectiveTest
class ClassInstantiationAccessToMemberTest extends PubPackageResolutionTest {
  test_alias() async {
    await assertErrorsInCode('''
class A<T> {
  int i = 1;
}

typedef TA<T> = A<T>;

var x = TA<int>.i;
''', [
      error(CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER,
          60, 9),
    ]);
  }

  test_extensionMember() async {
    await assertErrorsInCode('''
class A<T> {}

extension E on A {
  int get i => 1;
}

var x = A<int>.i;
''', [
      error(CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER,
          63, 8),
    ]);
  }

  test_instanceMember() async {
    await assertErrorsInCode('''
class A<T> {
  int i = 1;
}

var x = A<int>.i;
''', [
      error(CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER,
          37, 8),
    ]);
  }

  test_instanceSetter() async {
    await assertErrorsInCode('''
class A<T> {
  set i(int value) {}
}

void foo() {
  A<int>.i = 7;
}
''', [
      error(CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER,
          53, 8),
    ]);
  }

  test_staticMember() async {
    await assertErrorsInCode('''
class A<T> {
  static int i = 1;
}

var x = A<int>.i;
''', [
      error(CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER,
          44, 8),
    ]);
  }

  test_staticSetter() async {
    await assertErrorsInCode('''
class A<T> {
  static set i(int value) {}
}

void bar() {
  A<int>.i = 7;
}
''', [
      error(CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER,
          60, 8),
    ]);
  }

  test_syntheticIdentifier() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo();
}

var x = A<int>.;
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 42, 1),
    ]);
  }
}
