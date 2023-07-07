// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidNonVirtualAnnotationTest);
  });
}

@reflectiveTest
class InvalidNonVirtualAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@nonVirtual
class C {}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 34, 11),
    ]);
  }

  test_class_abstract_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

abstract class C {
  @nonVirtual
  void m();
}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 55, 11),
    ]);
  }

  test_class_getter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int get g => 0;
}
''');
  }

  test_class_instance_field() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  int f = 0;
}
''');
  }

  test_class_instance_member() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  void m() {
  }
}
''');
  }

  test_class_setter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @nonVirtual
  set s(int v) {}
}
''');
  }

  test_class_static_field() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
   @nonVirtual
   static int f = 0;
}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 47, 11),
    ]);
  }

  test_class_static_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
   @nonVirtual
   static void m() {}
}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 47, 11),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@nonVirtual
enum E {
  a, b, c
}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 34, 11),
    ]);
  }

  test_enum_constant() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

enum E {
  @nonVirtual
  a,
  b, c
}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 45, 11),
    ]);
  }

  test_extension() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@nonVirtual
extension E on Object {}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 34, 11),
    ]);
  }

  test_extension_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

extension E on Object {
   @nonVirtual
   void m() {}
}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 61, 11),
    ]);
  }

  test_import() async {
    await assertErrorsInCode(r'''
@nonVirtual
import 'package:meta/meta.dart';
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 0, 11),
    ]);
  }

  test_mixin() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@nonVirtual
mixin M {}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 34, 11),
    ]);
  }

  test_mixin_instance_member() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

mixin M {
  @nonVirtual
  void m() {}
}
''');
  }

  test_mixin_static_field() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

mixin M {
  @nonVirtual
  static int f = 0;
}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 46, 11),
    ]);
  }

  test_mixin_static_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

mixin M {
  @nonVirtual
  static void m() {}
}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 46, 11),
    ]);
  }

  test_top_level_function() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@nonVirtual
m() {}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 34, 11),
    ]);
  }

  test_top_level_getter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@nonVirtual
int get g =>  0;
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 34, 11),
    ]);
  }

  test_top_level_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@nonVirtual
set s(int v) {}
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 34, 11),
    ]);
  }

  test_top_level_var() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@nonVirtual
int x = 0;
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 34, 11),
    ]);
  }

  test_typedef() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@nonVirtual
typedef bool predicate(Object o);
''', [
      error(HintCode.INVALID_NON_VIRTUAL_ANNOTATION, 34, 11),
    ]);
  }
}
