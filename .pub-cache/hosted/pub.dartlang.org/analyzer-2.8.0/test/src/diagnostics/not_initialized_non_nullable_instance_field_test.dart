// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotInitializedNonNullableInstanceFieldTest);
  });
}

@reflectiveTest
class NotInitializedNonNullableInstanceFieldTest
    extends PubPackageResolutionTest {
  test_abstract_field_non_nullable() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int x;
}
''');
  }

  test_abstract_field_non_nullable_with_constructor() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int x;
  A();
}
''');
  }

  test_class_factoryConstructor() async {
    await assertNoErrorsInCode('''
class A {
  int x = 0;

  A(this.x);

  factory A.named() => A(0);
}
''');
  }

  test_class_ffi_struct() async {
    await assertNoErrorsInCode('''
import 'dart:ffi';

class A extends Struct {
  @Double()
  external double foo;
}
''');
  }

  test_class_notNullable_factoryConstructor_only() async {
    await assertErrorsInCode('''
class A {
  int x;

  factory A() => throw 0;
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD,
          16, 1),
    ]);
  }

  test_class_notNullable_late() async {
    await assertNoErrorsInCode('''
class A {
  late int x;
}
''');
  }

  test_constructorFieldInitializer() async {
    await assertNoErrorsInCode('''
class A {
  int x;

  A() : x = 0;
}
''');
  }

  test_external_field_non_nullable() async {
    await assertNoErrorsInCode('''
class A {
  external int x;
}
''');
  }

  test_external_field_non_nullable_with_constructor() async {
    await assertNoErrorsInCode('''
class A {
  external int x;
  A();
}
''');
  }

  test_fieldFormal() async {
    await assertNoErrorsInCode('''
class A {
  int x;

  A(this.x);
}
''');
  }

  test_futureOr_questionArgument_none() async {
    await assertNoErrorsInCode('''
import 'dart:async';

class A {
  FutureOr<int?> x;
}
''');
  }

  test_hasInitializer() async {
    await assertNoErrorsInCode('''
class A {
  int x = 0;
}
''');
  }

  test_inferredType() async {
    await assertErrorsInCode('''
abstract class A {
  int get x;
}

class B extends A {
  var x;
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD,
          61, 1),
    ]);
  }

  test_mixin_notNullable() async {
    await assertErrorsInCode('''
mixin M {
  int x;
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD,
          16, 1),
    ]);
  }

  test_mixin_notNullable_late() async {
    await assertNoErrorsInCode('''
mixin M {
  late int x;
}
''');
  }

  test_notAllConstructors() async {
    await assertErrorsInCode('''
class A {
  int x;

  A.a(this.x);

  A.b();
}
''', [
      error(
          CompileTimeErrorCode
              .NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR,
          38,
          1),
    ]);
  }

  test_notAllFields() async {
    await assertErrorsInCode('''
class A {
  int x, y, z;

  A() : x = 0, z = 2;
}
''', [
      error(
          CompileTimeErrorCode
              .NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR,
          28,
          1),
    ]);
  }

  test_nullable() async {
    await assertNoErrorsInCode('''
class A {
  int? x;
}
''');
  }

  test_type_dynamic() async {
    await assertNoErrorsInCode('''
class A {
  dynamic x;
}
''');
  }

  test_type_dynamic_implicit() async {
    await assertNoErrorsInCode('''
class A {
  var x;
}
''');
  }

  test_type_never() async {
    await assertErrorsInCode('''
class A {
  Never x;
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD,
          18, 1),
    ]);
  }

  test_type_void() async {
    await assertNoErrorsInCode('''
class A {
  void x;
}
''');
  }

  test_typeParameter() async {
    await assertErrorsInCode('''
class A<T> {
  T x;
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD,
          17, 1),
    ]);
  }

  test_typeParameter_nullable() async {
    await assertNoErrorsInCode('''
class A<T> {
  T? x;
}
''');
  }
}
