// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalThrowsExceptionTest);
    defineReflectiveTests(ConstEvalThrowsExceptionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ConstEvalThrowsExceptionTest extends PubPackageResolutionTest
    with ConstEvalThrowsExceptionTestCases {
  test_asExpression_typeParameter() async {
    await assertErrorsInCode('''
class C<T> {
  final t;
  const C(dynamic x) : t = x as T;
}

main() {
  const C<int>(0);
  const C<int>('foo');
  const C<int>(null);
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 92, 19),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 115, 18),
    ]);
  }

  test_asExpression_typeParameter_nested() async {
    await assertErrorsInCode('''
class C<T> {
  final t;
  const C(dynamic x) : t = x as List<T>;
}

main() {
  const C<int>(<int>[]);
  const C<int>(<num>[]);
  const C<int>(null);
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 104, 21),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 129, 18),
    ]);
  }

  test_enum_constructor_initializer_asExpression() async {
    await assertErrorsInCode(r'''
enum E {
  v();
  final int x;
  const E({int? x}) : x = x as int;
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 11, 3),
    ]);
  }
}

@reflectiveTest
mixin ConstEvalThrowsExceptionTestCases on PubPackageResolutionTest {
  test_assertInitializerThrows() async {
    await assertErrorsInCode(r'''
class A {
  const A(int x, int y) : assert(x < y);
}
var v = const A(3, 2);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 61, 13),
    ]);
  }

  test_CastError_intToDouble_constructor_importAnalyzedAfter() async {
    // See dartbug.com/35993
    newFile('$testPackageLibPath/other.dart', '''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}''');
    await assertNoErrorsInCode(r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''');
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_CastError_intToDouble_constructor_importAnalyzedBefore() async {
    // See dartbug.com/35993
    newFile('$testPackageLibPath/other.dart', '''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}''');
    await assertNoErrorsInCode(r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''');
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_default_constructor_arg_empty_map_import() async {
    newFile('$testPackageLibPath/other.dart', '''
class C {
  final Map<String, int> m;
  const C({this.m = const <String, int>{}})
    : assert(m != null);
}
''');
    await assertErrorsInCode('''
import 'other.dart';

main() {
  var c = const C();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 37, 1),
    ]);
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    assertErrorsInList(
      otherFileResult.errors,
      expectedErrorsByNullability(
        nullable: [
          error(HintCode.UNNECESSARY_NULL_COMPARISON_TRUE, 97, 7),
        ],
        legacy: [],
      ),
    );
  }

  test_finalAlreadySet_initializer() async {
    // If a final variable has an initializer at the site of its declaration,
    // and at the site of the constructor, then invoking that constructor would
    // produce a runtime error; hence invoking that constructor via the "const"
    // keyword results in a compile-time error.
    await assertErrorsInCode('''
class C {
  final x = 1;
  const C() : x = 2;
}
var x = const C();
''', [
      error(
          CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
          39,
          1),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 56, 9),
    ]);
  }

  test_finalAlreadySet_initializing_formal() async {
    // If a final variable has an initializer at the site of its declaration,
    // and it is initialized using an initializing formal at the site of the
    // constructor, then invoking that constructor would produce a runtime
    // error; hence invoking that constructor via the "const" keyword results
    // in a compile-time error.
    await assertErrorsInCode('''
class C {
  final x = 1;
  const C(this.x);
}
var x = const C(2);
''', [
      error(
          CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
          40,
          1),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 54, 10),
    ]);
  }

  test_fromEnvironment_assertInitializer() async {
    await assertNoErrorsInCode('''
class A {
  const A(int x) : assert(x >= 0);
}

main() {
  var c = const A(int.fromEnvironment('x'));
  print(c);
}
''');
  }

  test_fromEnvironment_bool_badArgs() async {
    await assertErrorsInCode(r'''
var b1 = const bool.fromEnvironment(1);
var b2 = const bool.fromEnvironment('x', defaultValue: 1);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 9, 29),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 36, 1),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 49, 48),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 95, 1),
    ]);
  }

  test_fromEnvironment_bool_badDefault_whenDefined() async {
    // The type of the defaultValue needs to be correct even when the default
    // value isn't used (because the variable is defined in the environment).
    declaredVariables = {'x': 'true'};
    await assertErrorsInCode('''
var b = const bool.fromEnvironment('x', defaultValue: 1);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 8, 48),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 54, 1),
    ]);
  }

  test_ifElement_false_thenNotEvaluated() async {
    await assertNoErrorsInCode('''
const dynamic nil = null;
const c = [if (1 < 0) nil + 1];
''');
  }

  test_ifElement_nonBoolCondition_list() async {
    await assertErrorsInCode('''
const dynamic nonBool = 3;
const c = const [if (nonBool) 'a'];
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 48, 7),
    ]);
  }

  test_ifElement_nonBoolCondition_map() async {
    await assertErrorsInCode('''
const dynamic nonBool = null;
const c = const {if (nonBool) 'a' : 1};
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 51, 7),
    ]);
  }

  test_ifElement_nonBoolCondition_set() async {
    await assertErrorsInCode('''
const dynamic nonBool = 'a';
const c = const {if (nonBool) 3};
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 50, 7),
    ]);
  }

  test_ifElement_true_elseNotEvaluated() async {
    await assertNoErrorsInCode('''
const dynamic nil = null;
const c = [if (0 < 1) 3 else nil + 1];
''');
  }

  test_invalid_constructorFieldInitializer_fromSeparateLibrary() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class A<T> {
  final int f;
  const A() : f = T.foo;
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';
const a = const A();
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 29, 9),
    ]);
  }

  test_redirectingConstructor_paramTypeMismatch() async {
    await assertErrorsInCode(r'''
class A {
  const A.a1(x) : this.a2(x);
  const A.a2(String x);
}
var v = const A.a1(0);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 74, 13),
    ]);
  }

  test_superConstructor_paramTypeMismatch() async {
    await assertErrorsInCode(r'''
class C {
  final double d;
  const C(this.d);
}
class D extends C {
  const D(d) : super(d);
}
const f = const D('0.0');
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 106, 14),
    ]);
  }

  test_symbolConstructor_nonStringArgument() async {
    await assertErrorsInCode(r'''
var s2 = const Symbol(3);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 9, 15),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 22, 1),
    ]);
  }

  test_symbolConstructor_string_digit() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [], legacy: [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 8, 17),
    ]);
    await assertErrorsInCode(r'''
var s = const Symbol('3');
''', expectedErrors);
  }

  test_symbolConstructor_string_underscore() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [], legacy: [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 8, 17),
    ]);
    await assertErrorsInCode(r'''
var s = const Symbol('_');
''', expectedErrors);
  }

  test_unaryBitNot_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = ~D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }

  test_unaryNegated_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = -D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }

  test_unaryNot_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = !D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }
}

@reflectiveTest
class ConstEvalThrowsExceptionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, ConstEvalThrowsExceptionTestCases {
  test_binaryMinus_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = D - 5;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);

    await assertErrorsInCode('''
const dynamic D = null;
const C = 5 - D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);
  }

  test_binaryPlus_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = D + 5;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);

    await assertErrorsInCode('''
const dynamic D = null;
const C = 5 + D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);
  }

  test_eqEq_nonPrimitiveRightOperand() async {
    await assertNoErrorsInCode('''
const c = const T.eq(1, const Object());
class T {
  final Object value;
  const T.eq(Object o1, Object o2) : value = o1 == o2;
}
''');
  }

  test_fromEnvironment_ifElement() async {
    await assertNoErrorsInCode('''
const b = bool.fromEnvironment('foo');

main() {
  const l1 = [1, 2, 3];
  const l2 = [if (b) ...l1];
  print(l2);
}
''');
  }
}
