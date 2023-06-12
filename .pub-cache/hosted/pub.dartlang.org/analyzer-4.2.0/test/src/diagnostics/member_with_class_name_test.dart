// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemberWithClassNameTest);
  });
}

@reflectiveTest
class MemberWithClassNameTest extends PubPackageResolutionTest {
  test_class_field() async {
    await assertErrorsInCode(r'''
class A {
  int A = 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
  }

  test_class_field_multiple() async {
    await assertErrorsInCode(r'''
class A {
  int z = 0, A = 0, b = 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 23, 1),
    ]);
  }

  test_class_getter() async {
    await assertErrorsInCode(r'''
class A {
  get A => 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
  }

  test_class_getter_static() async {
    await assertErrorsInCode(r'''
class A {
  static int get A => 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 27, 1),
    ]);
  }

  test_class_method() async {
    // No test because a method named the same as the enclosing class is
    // indistinguishable from a constructor.
  }

  test_class_setter() async {
    await assertErrorsInCode(r'''
class A {
  set A(_) {}
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
  }

  test_class_setter_static() async {
    await assertErrorsInCode(r'''
class A {
  static set A(_) {}
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 23, 1),
    ]);
  }

  test_enum_field() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int E = 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 26, 1),
    ]);
  }

  test_enum_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  int get E => 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 24, 1),
    ]);
  }

  test_enum_getter_static() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int get E => 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 31, 1),
    ]);
  }

  test_enum_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  set E(int _) {}
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 20, 1),
    ]);
  }

  test_enum_setter_static() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static set E(int _) {}
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 27, 1),
    ]);
  }

  test_mixin_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  int get M => 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 20, 1),
    ]);
  }

  test_mixin_getter_static() async {
    await assertErrorsInCode(r'''
mixin M {
  static int get M => 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 27, 1),
    ]);
  }

  test_mixin_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  void set M(_) {}
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 21, 1),
    ]);
  }

  test_mixin_setter_static() async {
    await assertErrorsInCode(r'''
mixin M {
  static void set M(_) {}
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 28, 1),
    ]);
  }
}
