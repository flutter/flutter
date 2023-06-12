// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorParamTypeMismatchTest);
    defineReflectiveTests(
        ConstConstructorParamTypeMismatchWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ConstConstructorParamTypeMismatchTest extends PubPackageResolutionTest {
  test_assignable_fieldFormal_omittedType() async {
    // If a field is declared without a type, and no initializer, it's type is
    // dynamic.
    await assertNoErrorsInCode(r'''
class A {
  final x;
  const A(this.x);
}
var v = const A(5);
''');
  }

  test_assignable_fieldFormal_subtype() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B();
}
class C {
  final A a;
  const C(this.a);
}
var v = const C(const B());
''');
  }

  test_assignable_fieldFormal_typedef() async {
    // foo has the type dynamic -> dynamic, so it is not assignable to A.f.
    await assertErrorsInCode(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
foo(x) => 1;
var v = const A(foo);
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 116, 3),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 116, 3),
    ]);
  }

  test_assignable_fieldFormal_typeSubstitution() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T x;
  const A(this.x);
}
var v = const A<int>(3);
''');
  }

  test_assignable_typeSubstitution() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>(3);''');
  }

  test_assignable_undefined() async {
    await assertErrorsInCode(r'''
class A {
  const A(Unresolved x);
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 20, 10),
    ]);
  }

  test_assignable_undefined_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    await assertErrorsInCode(r'''
class A {
  const A(Unresolved x);
}
var v = const A(null);
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 20, 10),
    ]);
  }

  test_enum_int_null() async {
    await assertErrorsInCode(r'''
const dynamic a = null;

enum E {
  v(a);
  const E(int a);
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 38, 1),
    ]);
  }

  test_enum_int_String() async {
    await assertErrorsInCode(r'''
const dynamic a = '0';

enum E {
  v(a);
  const E(int a);
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 37, 1),
    ]);
  }

  test_int_to_double_reference_from_other_library_other_file_after() async {
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';
class D {
  final C c;
  const D(this.c);
}
const D constant2 = const D(constant);
''');
    await assertNoErrorsInCode('''
class C {
  final double d;
  const C(this.d);
}
const C constant = const C(0);
''');
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_int_to_double_reference_from_other_library_other_file_before() async {
    await assertNoErrorsInCode('''
class C {
  final double d;
  const C(this.d);
}
const C constant = const C(0);
''');
    newFile('$testPackageLibPath/other.dart', '''
import 'test.dart';
class D {
  final C c;
  const D(this.c);
}
const D constant2 = const D(constant);
''');
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_int_to_double_single_library() async {
    await assertNoErrorsInCode('''
class C {
  final double d;
  const C(this.d);
}
const C constant = const C(0);
''');
  }

  test_int_to_double_via_default_value_other_file_after() async {
    newFile('$testPackageLibPath/other.dart', '''
class C {
  final double x;
  const C([this.x = 0]);
}
''');
    await assertNoErrorsInCode('''
import 'other.dart';
const c = C();
''');
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_int_to_double_via_default_value_other_file_before() async {
    newFile('$testPackageLibPath/other.dart', '''
class C {
  final double x;
  const C([this.x = 0]);
}
''');
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    expect(otherFileResult.errors, isEmpty);

    await assertNoErrorsInCode('''
import 'other.dart';
const c = C();
''');
  }

  test_notAssignable_fieldFormal_optional() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  const A([this.x = 'foo']);
}
var v = const A();
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 45, 5),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 64, 9),
    ]);
  }

  test_notAssignable_fieldFormal_supertype() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B();
}
class C {
  final B b;
  const C(this.b);
}
const A u = const A();
var v = const C(u);
''', [
      // TODO(srawlins): It would be best to report only the first one.
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 143, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 143, 1),
    ]);
  }

  test_notAssignable_fieldFormal_typedef() async {
    // foo has type String -> int, so it is not assignable to A.f
    // (A.f requires it to be int -> String).
    await assertErrorsInCode(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
int foo(String x) => 1;
var v = const A(foo);
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 127, 3),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 127, 3),
    ]);
  }

  test_notAssignable_fieldFormal_unrelated() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 62, 5),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 62, 5),
    ]);
  }

  test_notAssignable_fieldFormal_unresolved() async {
    await assertErrorsInCode(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 18, 10),
    ]);
  }

  test_notAssignable_typeSubstitution() async {
    await assertErrorsInCode(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>('foo');
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 52, 5),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 52, 5),
    ]);
  }

  test_notAssignable_unrelated() async {
    await assertErrorsInCode(r'''
class A {
  const A(int x);
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 46, 5),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 46, 5),
    ]);
  }

  test_superFormalParameter_explicit() async {
    await assertNoErrorsInCode(r'''
class A {
  const A({int a = 0});
}

class B extends A {
  static const f = B();

  const B({super.a = 2});
}
''');
  }

  test_superFormalParameter_inherited() async {
    await assertNoErrorsInCode(r'''
class A {
  const A({int a = 0});
}

class B extends A {
  const B({super.a});
}

const b = const B();
''');
  }

  test_superFormalParameter_inherited_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A({int a = 0});
}

class B extends A<int> {
  const B({super.a});
}

const b = const B();
''');
  }

  test_unknown_conditionalExpression_unknownCondition() async {
    await assertNoErrorsInCode(r'''
const bool kIsWeb = identical(0, 0.0);

void f() {
  const A(kIsWeb ? 0 : 1);
}

class A {
  const A(int _);
}
''');
  }
}

@reflectiveTest
class ConstConstructorParamTypeMismatchWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_assignable_fieldFormal_null() async {
    // Null is assignable to anything (before null safety).
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A(null);
''');
  }

  test_assignable_fieldFormal_unresolved_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    await assertErrorsInCode(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A(null);
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 18, 10),
    ]);
  }

  test_assignable_null() async {
    // Null is assignable to anything (before null safety).
    await assertNoErrorsInCode(r'''
class A {
  const A(int x);
}
var v = const A(null);''');
  }
}
