// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAnnotationTarget_MustBeOverriddenTest);
    defineReflectiveTests(InvalidAnnotationTarget_MustCallSuperTest);
    defineReflectiveTests(InvalidAnnotationTargetTest);
  });
}

@reflectiveTest
class InvalidAnnotationTarget_MustBeOverriddenTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_instance_field() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}
''');
  }

  test_class_instance_getter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int get f => 0;
}
''');
  }

  test_class_instance_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}
''');
  }

  test_class_instance_setter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void set s(int value) {}
}
''');
  }

  test_class_static_field() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
  static int f = 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 45, 17),
    ]);
  }

  test_class_static_getter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
  static int get f => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 45, 17),
    ]);
  }

  test_class_static_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
  static void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 45, 17),
    ]);
  }

  test_class_static_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
  static void set f(int value) {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 45, 17),
    ]);
  }

  test_constructor() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @mustBeOverridden
  C();
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 47, 16),
    ]);
  }

  test_enum_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

enum E {
  one, two;
  @mustBeOverridden
  void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 57, 17),
    ]);
  }

  test_extension_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

extension E on String {
  @mustBeOverridden
  void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 60, 17),
    ]);
  }

  test_mixin_instance_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

mixin M {
  @mustBeOverridden
  void m() {}
}
''');
  }

  test_topLevel() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@mustBeOverridden
void m() {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 35, 16),
    ]);
  }
}

@reflectiveTest
class InvalidAnnotationTarget_MustCallSuperTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_instance_field() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int f = 0;
}
''');
  }

  test_class_instance_getter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int get f => 0;
}
''');
  }

  test_class_instance_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void m() {}
}
''');
  }

  test_class_instance_setter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void set s(int value) {}
}
''');
  }

  test_class_static_field() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  static int f = 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 45, 14),
    ]);
  }

  test_class_static_getter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  static int get f => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 45, 14),
    ]);
  }

  test_class_static_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  static void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 45, 14),
    ]);
  }

  test_class_static_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  static void set f(int value) {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 45, 14),
    ]);
  }

  test_constructor() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @mustCallSuper
  C();
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 47, 13),
    ]);
  }

  test_enum_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

enum E {
  one, two;
  @mustCallSuper
  void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 57, 14),
    ]);
  }

  test_extension_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

extension E on String {
  @mustCallSuper
  void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 60, 14),
    ]);
  }

  test_mixin_instance_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

mixin M {
  @mustCallSuper
  void m() {}
}
''');
  }

  test_topLevel() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@mustCallSuper
void m() {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 35, 13),
    ]);
  }
}

@reflectiveTest
class InvalidAnnotationTargetTest extends PubPackageResolutionTest {
  // todo(pq): add tests for topLevelVariables:
  // https://dart-review.googlesource.com/c/sdk/+/200301
  void test_classType_class() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

@A()
class C {}
''');
  }

  void test_classType_mixin() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

@A()
mixin M {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_classType_topLevelVariable_constructor() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

@A()
int x = 0;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_classType_topLevelVariable_topLevelConstant() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

const a = A();

@a
int x = 0;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 114, 1),
    ]);
  }

  void test_enumType_class() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumType})
class A {
  const A();
}

@A()
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 97, 1),
    ]);
  }

  void test_enumType_enum() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumType})
class A {
  const A();
}

@A()
enum E {a, b}
''');
  }

  void test_extension_class() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.extension})
class A {
  const A();
}

@A()
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_extension_extension() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.extension})
class A {
  const A();
}

@A()
extension on C {}
class C {}
''');
  }

  void test_field_field() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.field})
class A {
  const A();
}

class C {
  @A()
  int f = 0;
}
''');
  }

  void test_function_function() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

@A()
int f(int x) => 0;
''');
  }

  void test_function_method() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

class C {
  @A()
  int M(int x) => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 109, 1),
    ]);
  }

  void test_function_topLevelGetter() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

@A()
int get x => 0;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 97, 1),
    ]);
  }

  void test_function_topLevelSetter() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

@A()
set x(_x) {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 97, 1),
    ]);
  }

  void test_getter_getter() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
  int get x => 0;
}
''');
  }

  void test_getter_method() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
  int m(int x) => x;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_getter_setter() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
  set x(int _x) {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_getter_topLevelGetter() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

@A()
int get x => 0;
''');
  }

  void test_library_class() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class A {
  const A();
}

@A()
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 96, 1),
    ]);
  }

  void test_library_import() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
@A()
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class A {
  const A();
}
''');
  }

  void test_library_library() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
@A()
library test;

import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class A {
  const A();
}
''');
  }

  void test_method_getter() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  int get x => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_method_method() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  int m(int x) => x;
}
''');
  }

  void test_method_operator() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  int operator +(int x) => x;
}
''');
  }

  void test_method_setter() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  set x(int _x) {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_method_topLevelFunction() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

@A()
int f(int x) => x;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 95, 1),
    ]);
  }

  void test_mixinType_class() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.mixinType})
class A {
  const A();
}

@A()
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_mixinType_mixin() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.mixinType})
class A {
  const A();
}

@A()
mixin M {}
''');
  }

  void test_multiple_invalid() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType, TargetKind.method})
class A {
  const A();
}

@A()
int x = 0;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 117, 1),
    ]);
  }

  void test_multiple_valid() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType, TargetKind.method})
class A {
  const A();
}

@A()
class C {
  @A()
  int m(int x) => x;
}
''');
  }

  void test_parameter_function() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.parameter})
class A {
  const A();
}

@A()
void f(int x) {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_parameter_parameter() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.parameter})
class A {
  const A();
}

void f(@A() int x) {}
''');
  }

  void test_setter_getter() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
  int get x => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_setter_method() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
  int m(int x) => x;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_setter_setter() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
  set x(int _x) {}
}
''');
  }

  void test_setter_topLevelSetter() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

@A()
set x(_x) {}
''');
  }

  void test_topLevelVariable_field() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.topLevelVariable})
class A {
  const A();
}

class B {
  @A()
  int f = 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 117, 1),
    ]);
  }

  void test_topLevelVariable_topLevelVariable() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.topLevelVariable})
class A {
  const A();
}

@A()
int f = 0;
''');
  }

  void test_type_class() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
class C {}
''');
  }

  void test_type_enum() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
enum E {a, b}
''');
  }

  void test_type_extension() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
extension on C {}
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 93, 1),
    ]);
  }

  void test_type_genericTypeAlias() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
typedef F = void Function(int);
''');
  }

  void test_type_mixin() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
mixin M {}
''');
  }

  void test_typedefType_genericTypeAlias() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.typedefType})
class A {
  const A();
}

@A()
typedef F = void Function(int);
''');
  }
}
