// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingFieldAndMethodTest);
  });
}

@reflectiveTest
class ConflictingFieldAndMethodTest extends PubPackageResolutionTest {
  test_class_inSuper_field() async {
    await assertErrorsInCode(r'''
class A {
  foo() {}
}
class B extends A {
  int foo = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 49, 3),
    ]);
  }

  test_class_inSuper_getter() async {
    await assertErrorsInCode(r'''
class A {
  foo() {}
}
class B extends A {
  get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 49, 3),
    ]);
  }

  test_class_inSuper_setter() async {
    await assertErrorsInCode(r'''
class A {
  foo() {}
}
class B extends A {
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 49, 3),
    ]);
  }

  test_enum_inMixin_field() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  final int foo = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 62, 3),
    ]);
  }

  test_enum_inMixin_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 60, 3),
    ]);
  }

  test_enum_inMixin_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 56, 3),
    ]);
  }
}
