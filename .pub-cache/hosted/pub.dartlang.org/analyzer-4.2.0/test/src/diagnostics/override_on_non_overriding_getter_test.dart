// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingGetterTest);
  });
}

@reflectiveTest
class OverrideOnNonOverridingGetterTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class A {
  @override
  int get foo => 0;
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER, 32, 3),
    ]);
  }

  test_class_extends() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B extends A {
  @override
  int get foo => 0;
}
''');
  }

  test_class_implements() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B implements A {
  @override
  int get foo => 0;
}
''');
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  @override
  int get foo => 0;
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER, 36, 3),
    ]);
  }

  test_enum_implements() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

enum E implements A {
  v;
  @override
  int get foo => 0;
}
''');
  }

  test_enum_with() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  @override
  int get foo => 0;
}
''');
  }

  test_extension() async {
    await assertErrorsInCode(r'''
extension E on int {
  @override
  int get foo => 1;
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER, 43, 3),
    ]);
  }

  test_mixin() async {
    await assertErrorsInCode(r'''
mixin M {
  @override
  int get foo => 0;
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER, 32, 3),
    ]);
  }
}
