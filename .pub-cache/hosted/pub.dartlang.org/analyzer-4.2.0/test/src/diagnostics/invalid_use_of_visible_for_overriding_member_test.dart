// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForOverridingMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForOverridingMemberTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_differentLibrary_invalid() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}
''');
    await assertErrorsInCode('''
import 'a.dart';

class Child extends Parent {
  Child() {
    foo();
  }
}
''', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, 63, 3),
    ]);
  }

  test_differentLibrary_valid_onlyOverride() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class Child extends Parent {
  @override
  void foo() {}
}
''');
  }

  test_differentLibrary_valid_overrideAndUse() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class Child extends Parent {
  @override
  void foo() {}

  void bar() {
    foo();
  }
}
''');
  }

  test_getter() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  int get g => 0;
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class B {
  int m(A a) {
    return a.g;
  }
}
''', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, 56, 1),
    ]);
  }

  test_operator() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  operator >(A other) => true;
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class B {
  void m(A a) => a > A();
}
''', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, 47, 1),
    ]);
  }

  test_overriding_getter() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  int get g => 0;
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class B extends A {
  @override
  int get g => super.g + 1;

  int get x => super.g + 1;
}
''', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, 100, 1),
    ]);
  }

  test_overriding_methodInvocation() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  void m() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class B extends A {
  @override
  void m() => super.m();

  void x() => super.m();
}
''', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, 96, 1),
    ]);
  }

  test_overriding_operator() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  operator >(A other) => true;
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class B extends A {
  @override
  operator >(A other) => super > other;

  void m() => super > A();
}
''', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, 111, 1),
    ]);
  }

  test_overriding_setter() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  set s(int i) {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class B extends A {
  @override
  set s(int i) => super.s = i;

  set x(int i) => super.s = i;
}
''', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, 106, 1),
    ]);
  }

  test_sameLibrary() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}

class Child extends Parent {
  Child() {
    foo();
  }
}
''');
  }

  test_setter() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @visibleForOverriding
  set s(int i) {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class B {
  void m(A a) {
    a.s = 1;
  }
}
''', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, 50, 1),
    ]);
  }
}
