// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingFieldTest);
  });
}

@reflectiveTest
class OverrideOnNonOverridingFieldTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class A {
  @override
  int? foo;
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD, 29, 3),
    ]);
  }

  test_class_extends() async {
    await assertErrorsInCode(r'''
class A {
  int get a => 0;
  void set b(_) {}
  int c = 0;
}
class B extends A {
  @override
  final int a = 1;
  @override
  int b = 0;
  @override
  int c = 0;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 131, 1,
          contextMessages: [message('/home/test/lib/test.dart', 39, 1)]),
    ]);
  }

  test_class_implements() async {
    await assertErrorsInCode(r'''
class A {
  int get a => 0;
  void set b(_) {}
  int c = 0;
}
class B implements A {
  @override
  final int a = 1;
  @override
  int b = 0;
  @override
  int c = 0;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 134, 1,
          contextMessages: [message('/home/test/lib/test.dart', 39, 1)]),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  @override
  final int foo = 0;
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD, 38, 3),
    ]);
  }

  test_enum_implements() async {
    await assertNoErrorsInCode(r'''
class A {
  int get a => 0;
  void set b(int _) {}
}

enum E implements A {
  v;
  @override
  int get a => 0;

  @override
  void set b(int _) {}
}
''');
  }

  test_enum_with() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get a => 0;
  void set b(int _) {}
}

enum E with M {
  v;
  @override
  int get a => 0;

  @override
  void set b(int _) {}
}
''');
  }
}
