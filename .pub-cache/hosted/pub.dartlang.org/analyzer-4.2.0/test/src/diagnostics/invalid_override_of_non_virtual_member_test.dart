// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidOverrideOfNonVirtualMemberTest);
  });
}

@reflectiveTest
class InvalidOverrideOfNonVirtualMemberTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_field() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int g = 0;
}

class B extends C  {
  @override
  int g = 0;
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 113, 1,
          messageContains: ["member 'g'", "in 'C'"]),
    ]);
  }

  test_class_field_2() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int g = 0;
}

class B extends C  {
  int g = 0, h = 1;
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 101, 1),
    ]);
  }

  test_class_field_overriddenByGetter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int g = 0;
}

class B extends C  {
  @override
  int get g => 0;
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 117, 1,
          messageContains: ["member 'g'", "in 'C'"]),
    ]);
  }

  test_class_field_overriddenBySetter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int g = 0;
}

class B extends C  {
  @override
  set g(int v) {}
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 113, 1),
    ]);
  }

  test_class_getter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int get g => 0;
}

class B extends C  {
  @override
  int get g => 0;
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 122, 1),
    ]);
  }

  test_class_getter_overriddenByField() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int get g => 0;
}

class B extends C  {
  @override
  int g = 0;
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 118, 1),
    ]);
  }

  test_class_implements_getter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int get g => 0;
}

class B implements C  {
  @override
  int get g => 0; //OK
}
''');
  }

  test_class_implements_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  void f() {}
}

class B implements C  {
  @override
  void f() {} //OK
}
''');
  }

  test_class_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  void f() {}
}

class B extends C  {
  @override
  void f() {}
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 115, 1),
    ]);
  }

  test_class_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  set g(int v) {}
}

class B extends C  {
  @override
  set g(int v) {}
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 118, 1),
    ]);
  }

  test_class_setter_overriddenByField() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  set g(int v) {}
}

class B extends C  {
  @override
  int g = 0;
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 118, 1),
    ]);
  }

  test_mixin_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

mixin M {
  @nonVirtual
  void f() {}
}

class B with M {
  @override
  void f() {}
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 111, 1,
          messageContains: ["member 'f'", "in 'M'"]),
    ]);
  }

  test_mixin_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

mixin M {
  @nonVirtual
  set g(int v) {}
}

class B with M {
  @override
  set g(int v) {}
}
''', [
      error(HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, 114, 1),
    ]);
  }
}
