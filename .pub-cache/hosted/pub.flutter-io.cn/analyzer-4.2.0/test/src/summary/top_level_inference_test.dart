// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import 'element_text.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelInferenceTest);
    defineReflectiveTests(TopLevelInferenceErrorsTest);
    // defineReflectiveTests(ApplyCheckElementTextReplacements);
  });
}

@reflectiveTest
class ApplyCheckElementTextReplacements {
  test_applyReplacements() {
    applyCheckElementTextReplacements();
  }
}

@reflectiveTest
class TopLevelInferenceErrorsTest extends PubPackageResolutionTest {
  test_initializer_additive() async {
    await _assertErrorOnlyLeft(['+', '-']);
  }

  test_initializer_assign() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = a += 1;
var t2 = a = 2;
''');
  }

  test_initializer_binary_onlyLeft() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = (a = 1) + (a = 2);
''');
  }

  test_initializer_bitwise() async {
    await _assertErrorOnlyLeft(['&', '|', '^']);
  }

  test_initializer_boolean() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = ((a = 1) == 0) || ((a = 2) == 0);
var t2 = ((a = 1) == 0) && ((a = 2) == 0);
var t3 = !((a = 1) == 0);
''');
  }

  test_initializer_cascade() async {
    await assertNoErrorsInCode('''
var a = 0;
var t = (a = 1)..isEven;
''');
  }

  test_initializer_classField_instance_instanceCreation() async {
    await assertNoErrorsInCode('''
class A<T> {}
class B {
  var t1 = new A<int>();
  var t2 = new A();
}
''');
  }

  test_initializer_classField_static_instanceCreation() async {
    await assertNoErrorsInCode('''
class A<T> {}
class B {
  static var t1 = 1;
  static var t2 = new A();
}
''');
  }

  test_initializer_conditional() async {
    await assertNoErrorsInCode('''
var a = 1;
var b = true;
var t = b
    ? (a = 1)
    : (a = 2);
''');
  }

  test_initializer_dependencyCycle() async {
    await assertErrorsInCode('''
var a = b;
var b = a;
''', [
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 4, 1),
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 15, 1),
    ]);
  }

  test_initializer_equality() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = ((a = 1) == 0) == ((a = 2) == 0);
var t2 = ((a = 1) == 0) != ((a = 2) == 0);
''');
  }

  test_initializer_extractIndex() async {
    await assertNoErrorsInCode('''
var a = [0, 1.2];
var b0 = a[0];
var b1 = a[1];
''');
  }

  test_initializer_functionLiteral_blockBody() async {
    await assertNoErrorsInCode('''
var t = (int p) {};
''');
    assertType(
      findElement.topVar('t').type,
      'Null Function(int)',
    );
  }

  test_initializer_functionLiteral_expressionBody() async {
    await assertNoErrorsInCode('''
var a = 0;
var t = (int p) => (a = 1);
''');
    assertType(
      findElement.topVar('t').type,
      'int Function(int)',
    );
  }

  test_initializer_functionLiteral_parameters_withoutType() async {
    await assertNoErrorsInCode('''
var t = (int a, b,int c, d) => 0;
''');
    assertType(
      findElement.topVar('t').type,
      'int Function(int, dynamic, int, dynamic)',
    );
  }

  test_initializer_hasTypeAnnotation() async {
    await assertNoErrorsInCode('''
var a = 1;
int t = (a = 1);
''');
  }

  test_initializer_identifier() async {
    await assertNoErrorsInCode('''
int top_function() => 0;
var top_variable = 0;
int get top_getter => 0;
class A {
  static var static_field = 0;
  static int get static_getter => 0;
  static int static_method() => 0;
  int instance_method() => 0;
}
var t1 = top_function;
var t2 = top_variable;
var t3 = top_getter;
var t4 = A.static_field;
var t5 = A.static_getter;
var t6 = A.static_method;
var t7 = new A().instance_method;
''');
  }

  test_initializer_identifier_error() async {
    await assertNoErrorsInCode('''
var a = 0;
var b = (a = 1);
var c = b;
''');
  }

  test_initializer_ifNull() async {
    await assertNoErrorsInCode('''
int? a = 1;
var t = a ?? 2;
''');
  }

  test_initializer_instanceCreation_withoutTypeParameters() async {
    await assertNoErrorsInCode('''
class A {}
var t = new A();
''');
  }

  test_initializer_instanceCreation_withTypeParameters() async {
    await assertNoErrorsInCode('''
class A<T> {}
var t1 = new A<int>();
var t2 = new A();
''');
  }

  test_initializer_instanceGetter() async {
    await assertNoErrorsInCode('''
class A {
  int f = 1;
}
var a = new A().f;
''');
  }

  test_initializer_methodInvocation_function() async {
    await assertNoErrorsInCode('''
int f1() => 0;
T f2<T>() => throw 0;
var t1 = f1();
var t2 = f2();
var t3 = f2<int>();
''');
  }

  test_initializer_methodInvocation_method() async {
    await assertNoErrorsInCode('''
class A {
  int m1() => 0;
  T m2<T>() => throw 0;
}
var a = new A();
var t1 = a.m1();
var t2 = a.m2();
var t3 = a.m2<int>();
''');
  }

  test_initializer_multiplicative() async {
    await _assertErrorOnlyLeft(['*', '/', '%', '~/']);
  }

  test_initializer_postfixIncDec() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = a++;
var t2 = a--;
''');
  }

  test_initializer_prefixIncDec() async {
    await assertNoErrorsInCode('''
var a = 1;
var t1 = ++a;
var t2 = --a;
''');
  }

  test_initializer_relational() async {
    await _assertErrorOnlyLeft(['>', '>=', '<', '<=']);
  }

  test_initializer_shift() async {
    await _assertErrorOnlyLeft(['<<', '>>']);
  }

  test_initializer_typedList() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = <int>[a = 1];
''');
  }

  test_initializer_typedMap() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = <int, int>{(a = 1) : (a = 2)};
''');
  }

  test_initializer_untypedList() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = [
    a = 1,
    2,
    3,
];
''');
  }

  test_initializer_untypedMap() async {
    await assertNoErrorsInCode('''
var a = 1;
var t = {
    (a = 1) :
        (a = 2),
};
''');
  }

  test_override_conflictFieldType() async {
    await assertErrorsInCode('''
abstract class A {
  int aaa = 0;
}
abstract class B {
  String aaa = '0';
}
class C implements A, B {
  var aaa;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 109, 3,
          contextMessages: [message('/home/test/lib/test.dart', 64, 3)]),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 109, 3,
          contextMessages: [message('/home/test/lib/test.dart', 25, 3)]),
    ]);
  }

  test_override_conflictParameterType_method() async {
    await assertErrorsInCode('''
abstract class A {
  void mmm(int a);
}
abstract class B {
  void mmm(String a);
}
class C implements A, B {
  void mmm(a) {}
}
''', [
      error(CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE, 116, 3),
    ]);
  }

  Future<void> _assertErrorOnlyLeft(List<String> operators) async {
    String code = 'var a = 1;\n';
    for (var i = 0; i < operators.length; i++) {
      String operator = operators[i];
      code += 'var t$i = (a = 1) $operator (a = 2);\n';
    }
    await assertNoErrorsInCode(code);
  }
}

@reflectiveTest
class TopLevelInferenceTest extends PubPackageResolutionTest {
  test_initializer_additive() async {
    var library = await _encodeDecodeLibrary(r'''
var vPlusIntInt = 1 + 2;
var vPlusIntDouble = 1 + 2.0;
var vPlusDoubleInt = 1.0 + 2;
var vPlusDoubleDouble = 1.0 + 2.0;
var vMinusIntInt = 1 - 2;
var vMinusIntDouble = 1 - 2.0;
var vMinusDoubleInt = 1.0 - 2;
var vMinusDoubleDouble = 1.0 - 2.0;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vPlusIntInt @4
        type: int
      static vPlusIntDouble @29
        type: double
      static vPlusDoubleInt @59
        type: double
      static vPlusDoubleDouble @89
        type: double
      static vMinusIntInt @124
        type: int
      static vMinusIntDouble @150
        type: double
      static vMinusDoubleInt @181
        type: double
      static vMinusDoubleDouble @212
        type: double
    accessors
      synthetic static get vPlusIntInt @-1
        returnType: int
      synthetic static set vPlusIntInt @-1
        parameters
          requiredPositional _vPlusIntInt @-1
            type: int
        returnType: void
      synthetic static get vPlusIntDouble @-1
        returnType: double
      synthetic static set vPlusIntDouble @-1
        parameters
          requiredPositional _vPlusIntDouble @-1
            type: double
        returnType: void
      synthetic static get vPlusDoubleInt @-1
        returnType: double
      synthetic static set vPlusDoubleInt @-1
        parameters
          requiredPositional _vPlusDoubleInt @-1
            type: double
        returnType: void
      synthetic static get vPlusDoubleDouble @-1
        returnType: double
      synthetic static set vPlusDoubleDouble @-1
        parameters
          requiredPositional _vPlusDoubleDouble @-1
            type: double
        returnType: void
      synthetic static get vMinusIntInt @-1
        returnType: int
      synthetic static set vMinusIntInt @-1
        parameters
          requiredPositional _vMinusIntInt @-1
            type: int
        returnType: void
      synthetic static get vMinusIntDouble @-1
        returnType: double
      synthetic static set vMinusIntDouble @-1
        parameters
          requiredPositional _vMinusIntDouble @-1
            type: double
        returnType: void
      synthetic static get vMinusDoubleInt @-1
        returnType: double
      synthetic static set vMinusDoubleInt @-1
        parameters
          requiredPositional _vMinusDoubleInt @-1
            type: double
        returnType: void
      synthetic static get vMinusDoubleDouble @-1
        returnType: double
      synthetic static set vMinusDoubleDouble @-1
        parameters
          requiredPositional _vMinusDoubleDouble @-1
            type: double
        returnType: void
''');
  }

  test_initializer_as() async {
    var library = await _encodeDecodeLibrary(r'''
var V = 1 as num;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static V @4
        type: num
    accessors
      synthetic static get V @-1
        returnType: num
      synthetic static set V @-1
        parameters
          requiredPositional _V @-1
            type: num
        returnType: void
''');
  }

  test_initializer_assign() async {
    var library = await _encodeDecodeLibrary(r'''
var a = 1;
var t1 = (a = 2);
var t2 = (a += 2);
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        type: int
      static t1 @15
        type: int
      static t2 @33
        type: int
    accessors
      synthetic static get a @-1
        returnType: int
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: int
        returnType: void
      synthetic static get t1 @-1
        returnType: int
      synthetic static set t1 @-1
        parameters
          requiredPositional _t1 @-1
            type: int
        returnType: void
      synthetic static get t2 @-1
        returnType: int
      synthetic static set t2 @-1
        parameters
          requiredPositional _t2 @-1
            type: int
        returnType: void
''');
  }

  test_initializer_assign_indexed() async {
    var library = await _encodeDecodeLibrary(r'''
var a = [0];
var t1 = (a[0] = 2);
var t2 = (a[0] += 2);
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        type: List<int>
      static t1 @17
        type: int
      static t2 @38
        type: int
    accessors
      synthetic static get a @-1
        returnType: List<int>
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: List<int>
        returnType: void
      synthetic static get t1 @-1
        returnType: int
      synthetic static set t1 @-1
        parameters
          requiredPositional _t1 @-1
            type: int
        returnType: void
      synthetic static get t2 @-1
        returnType: int
      synthetic static set t2 @-1
        parameters
          requiredPositional _t2 @-1
            type: int
        returnType: void
''');
  }

  test_initializer_assign_prefixed() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int f;
}
var a = new A();
var t1 = (a.f = 1);
var t2 = (a.f += 2);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          f @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
    topLevelVariables
      static a @25
        type: A
      static t1 @42
        type: int
      static t2 @62
        type: int
    accessors
      synthetic static get a @-1
        returnType: A
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: A
        returnType: void
      synthetic static get t1 @-1
        returnType: int
      synthetic static set t1 @-1
        parameters
          requiredPositional _t1 @-1
            type: int
        returnType: void
      synthetic static get t2 @-1
        returnType: int
      synthetic static set t2 @-1
        parameters
          requiredPositional _t2 @-1
            type: int
        returnType: void
''');
  }

  test_initializer_assign_prefixed_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  int f;
}
abstract class C implements I {}
C c;
var t1 = (c.f = 1);
var t2 = (c.f += 2);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class I @6
        fields
          f @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
      abstract class C @36
        interfaces
          I
        constructors
          synthetic @-1
    topLevelVariables
      static c @56
        type: C
      static t1 @63
        type: int
      static t2 @83
        type: int
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get t1 @-1
        returnType: int
      synthetic static set t1 @-1
        parameters
          requiredPositional _t1 @-1
            type: int
        returnType: void
      synthetic static get t2 @-1
        returnType: int
      synthetic static set t2 @-1
        parameters
          requiredPositional _t2 @-1
            type: int
        returnType: void
''');
  }

  test_initializer_assign_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  int f;
}
abstract class C implements I {}
C getC() => null;
var t1 = (getC().f = 1);
var t2 = (getC().f += 2);
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class I @6
        fields
          f @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
      abstract class C @36
        interfaces
          I
        constructors
          synthetic @-1
    topLevelVariables
      static t1 @76
        type: int
      static t2 @101
        type: int
    accessors
      synthetic static get t1 @-1
        returnType: int
      synthetic static set t1 @-1
        parameters
          requiredPositional _t1 @-1
            type: int
        returnType: void
      synthetic static get t2 @-1
        returnType: int
      synthetic static set t2 @-1
        parameters
          requiredPositional _t2 @-1
            type: int
        returnType: void
    functions
      getC @56
        returnType: C
''');
  }

  test_initializer_await() async {
    var library = await _encodeDecodeLibrary(r'''
import 'dart:async';
int fValue() => 42;
Future<int> fFuture() async => 42;
var uValue = () async => await fValue();
var uFuture = () async => await fFuture();
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    topLevelVariables
      static uValue @80
        type: Future<int> Function()
      static uFuture @121
        type: Future<int> Function()
    accessors
      synthetic static get uValue @-1
        returnType: Future<int> Function()
      synthetic static set uValue @-1
        parameters
          requiredPositional _uValue @-1
            type: Future<int> Function()
        returnType: void
      synthetic static get uFuture @-1
        returnType: Future<int> Function()
      synthetic static set uFuture @-1
        parameters
          requiredPositional _uFuture @-1
            type: Future<int> Function()
        returnType: void
    functions
      fValue @25
        returnType: int
      fFuture @53 async
        returnType: Future<int>
''');
  }

  test_initializer_bitwise() async {
    var library = await _encodeDecodeLibrary(r'''
var vBitXor = 1 ^ 2;
var vBitAnd = 1 & 2;
var vBitOr = 1 | 2;
var vBitShiftLeft = 1 << 2;
var vBitShiftRight = 1 >> 2;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vBitXor @4
        type: int
      static vBitAnd @25
        type: int
      static vBitOr @46
        type: int
      static vBitShiftLeft @66
        type: int
      static vBitShiftRight @94
        type: int
    accessors
      synthetic static get vBitXor @-1
        returnType: int
      synthetic static set vBitXor @-1
        parameters
          requiredPositional _vBitXor @-1
            type: int
        returnType: void
      synthetic static get vBitAnd @-1
        returnType: int
      synthetic static set vBitAnd @-1
        parameters
          requiredPositional _vBitAnd @-1
            type: int
        returnType: void
      synthetic static get vBitOr @-1
        returnType: int
      synthetic static set vBitOr @-1
        parameters
          requiredPositional _vBitOr @-1
            type: int
        returnType: void
      synthetic static get vBitShiftLeft @-1
        returnType: int
      synthetic static set vBitShiftLeft @-1
        parameters
          requiredPositional _vBitShiftLeft @-1
            type: int
        returnType: void
      synthetic static get vBitShiftRight @-1
        returnType: int
      synthetic static set vBitShiftRight @-1
        parameters
          requiredPositional _vBitShiftRight @-1
            type: int
        returnType: void
''');
  }

  test_initializer_cascade() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int a;
  void m() {}
}
var vSetField = new A()..a = 1;
var vInvokeMethod = new A()..m();
var vBoth = new A()..a = 1..m();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          a @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get a @-1
            returnType: int
          synthetic set a @-1
            parameters
              requiredPositional _a @-1
                type: int
            returnType: void
        methods
          m @26
            returnType: void
    topLevelVariables
      static vSetField @39
        type: A
      static vInvokeMethod @71
        type: A
      static vBoth @105
        type: A
    accessors
      synthetic static get vSetField @-1
        returnType: A
      synthetic static set vSetField @-1
        parameters
          requiredPositional _vSetField @-1
            type: A
        returnType: void
      synthetic static get vInvokeMethod @-1
        returnType: A
      synthetic static set vInvokeMethod @-1
        parameters
          requiredPositional _vInvokeMethod @-1
            type: A
        returnType: void
      synthetic static get vBoth @-1
        returnType: A
      synthetic static set vBoth @-1
        parameters
          requiredPositional _vBoth @-1
            type: A
        returnType: void
''');
  }

  /// A simple or qualified identifier referring to a top level function, static
  /// variable, field, getter; or a static class variable, static getter or
  /// method; or an instance method; has the inferred type of the identifier.
  ///
  test_initializer_classField_useInstanceGetter() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int f = 1;
}
class B {
  A a;
}
class C {
  B b;
}
class X {
  A a = new A();
  B b = new B();
  C c = new C();
  var t01 = a.f;
  var t02 = b.a.f;
  var t03 = c.b.a.f;
  var t11 = new A().f;
  var t12 = new B().a.f;
  var t13 = new C().b.a.f;
  var t21 = newA().f;
  var t22 = newB().a.f;
  var t23 = newC().b.a.f;
}
A newA() => new A();
B newB() => new B();
C newC() => new C();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          f @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
      class B @31
        fields
          a @39
            type: A
        constructors
          synthetic @-1
        accessors
          synthetic get a @-1
            returnType: A
          synthetic set a @-1
            parameters
              requiredPositional _a @-1
                type: A
            returnType: void
      class C @50
        fields
          b @58
            type: B
        constructors
          synthetic @-1
        accessors
          synthetic get b @-1
            returnType: B
          synthetic set b @-1
            parameters
              requiredPositional _b @-1
                type: B
            returnType: void
      class X @69
        fields
          a @77
            type: A
          b @94
            type: B
          c @111
            type: C
          t01 @130
            type: int
          t02 @147
            type: int
          t03 @166
            type: int
          t11 @187
            type: int
          t12 @210
            type: int
          t13 @235
            type: int
          t21 @262
            type: int
          t22 @284
            type: int
          t23 @308
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get a @-1
            returnType: A
          synthetic set a @-1
            parameters
              requiredPositional _a @-1
                type: A
            returnType: void
          synthetic get b @-1
            returnType: B
          synthetic set b @-1
            parameters
              requiredPositional _b @-1
                type: B
            returnType: void
          synthetic get c @-1
            returnType: C
          synthetic set c @-1
            parameters
              requiredPositional _c @-1
                type: C
            returnType: void
          synthetic get t01 @-1
            returnType: int
          synthetic set t01 @-1
            parameters
              requiredPositional _t01 @-1
                type: int
            returnType: void
          synthetic get t02 @-1
            returnType: int
          synthetic set t02 @-1
            parameters
              requiredPositional _t02 @-1
                type: int
            returnType: void
          synthetic get t03 @-1
            returnType: int
          synthetic set t03 @-1
            parameters
              requiredPositional _t03 @-1
                type: int
            returnType: void
          synthetic get t11 @-1
            returnType: int
          synthetic set t11 @-1
            parameters
              requiredPositional _t11 @-1
                type: int
            returnType: void
          synthetic get t12 @-1
            returnType: int
          synthetic set t12 @-1
            parameters
              requiredPositional _t12 @-1
                type: int
            returnType: void
          synthetic get t13 @-1
            returnType: int
          synthetic set t13 @-1
            parameters
              requiredPositional _t13 @-1
                type: int
            returnType: void
          synthetic get t21 @-1
            returnType: int
          synthetic set t21 @-1
            parameters
              requiredPositional _t21 @-1
                type: int
            returnType: void
          synthetic get t22 @-1
            returnType: int
          synthetic set t22 @-1
            parameters
              requiredPositional _t22 @-1
                type: int
            returnType: void
          synthetic get t23 @-1
            returnType: int
          synthetic set t23 @-1
            parameters
              requiredPositional _t23 @-1
                type: int
            returnType: void
    functions
      newA @332
        returnType: A
      newB @353
        returnType: B
      newC @374
        returnType: C
''');
  }

  test_initializer_conditional() async {
    var library = await _encodeDecodeLibrary(r'''
var V = true ? 1 : 2.3;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static V @4
        type: num
    accessors
      synthetic static get V @-1
        returnType: num
      synthetic static set V @-1
        parameters
          requiredPositional _V @-1
            type: num
        returnType: void
''');
  }

  test_initializer_equality() async {
    var library = await _encodeDecodeLibrary(r'''
var vEq = 1 == 2;
var vNotEq = 1 != 2;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vEq @4
        type: bool
      static vNotEq @22
        type: bool
    accessors
      synthetic static get vEq @-1
        returnType: bool
      synthetic static set vEq @-1
        parameters
          requiredPositional _vEq @-1
            type: bool
        returnType: void
      synthetic static get vNotEq @-1
        returnType: bool
      synthetic static set vNotEq @-1
        parameters
          requiredPositional _vNotEq @-1
            type: bool
        returnType: void
''');
  }

  test_initializer_error_methodInvocation_cycle_topLevel() async {
    var library = await _encodeDecodeLibrary(r'''
var a = b.foo();
var b = a.foo();
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        typeInferenceError: dependencyCycle
        type: dynamic
      static b @21
        typeInferenceError: dependencyCycle
        type: dynamic
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: dynamic
        returnType: void
      synthetic static get b @-1
        returnType: dynamic
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: dynamic
        returnType: void
''');
  }

  test_initializer_error_methodInvocation_cycle_topLevel_self() async {
    var library = await _encodeDecodeLibrary(r'''
var a = a.foo();
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        typeInferenceError: dependencyCycle
        type: dynamic
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: dynamic
        returnType: void
''');
  }

  test_initializer_extractIndex() async {
    var library = await _encodeDecodeLibrary(r'''
var a = [0, 1.2];
var b0 = a[0];
var b1 = a[1];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        type: List<num>
      static b0 @22
        type: num
      static b1 @37
        type: num
    accessors
      synthetic static get a @-1
        returnType: List<num>
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: List<num>
        returnType: void
      synthetic static get b0 @-1
        returnType: num
      synthetic static set b0 @-1
        parameters
          requiredPositional _b0 @-1
            type: num
        returnType: void
      synthetic static get b1 @-1
        returnType: num
      synthetic static set b1 @-1
        parameters
          requiredPositional _b1 @-1
            type: num
        returnType: void
''');
  }

  test_initializer_extractProperty_explicitlyTyped_differentLibraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int f = 0;
}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'a.dart';
var x = new C().f;
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    topLevelVariables
      static x @21
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_initializer_extractProperty_explicitlyTyped_sameLibrary() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  int f = 0;
}
var x = new C().f;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          f @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
    topLevelVariables
      static x @29
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_initializer_extractProperty_explicitlyTyped_sameLibraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'test.dart'; // just do make it part of the library cycle
class C {
  int f = 0;
}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'a.dart';
var x = new C().f;
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    topLevelVariables
      static x @21
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_initializer_extractProperty_implicitlyTyped_differentLibraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  var f = 0;
}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'a.dart';
var x = new C().f;
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    topLevelVariables
      static x @21
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_initializer_extractProperty_implicitlyTyped_sameLibrary() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  var f = 0;
}
var x = new C().f;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          f @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
    topLevelVariables
      static x @29
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_initializer_extractProperty_implicitlyTyped_sameLibraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'test.dart'; // just do make it part of the library cycle
class C {
  var f = 0;
}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'a.dart';
var x = new C().f;
''');
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    topLevelVariables
      static x @21
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_initializer_extractProperty_inStaticField() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int f;
}
class B {
  static var t = new A().f;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          f @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
      class B @27
        fields
          static t @44
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic static get t @-1
            returnType: int
          synthetic static set t @-1
            parameters
              requiredPositional _t @-1
                type: int
            returnType: void
''');
  }

  test_initializer_extractProperty_prefixedIdentifier() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  bool b;
}
C c;
var x = c.b;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          b @17
            type: bool
        constructors
          synthetic @-1
        accessors
          synthetic get b @-1
            returnType: bool
          synthetic set b @-1
            parameters
              requiredPositional _b @-1
                type: bool
            returnType: void
    topLevelVariables
      static c @24
        type: C
      static x @31
        type: bool
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get x @-1
        returnType: bool
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: bool
        returnType: void
''');
  }

  test_initializer_extractProperty_prefixedIdentifier_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  bool b;
}
abstract class C implements I {}
C c;
var x = c.b;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class I @6
        fields
          b @17
            type: bool
        constructors
          synthetic @-1
        accessors
          synthetic get b @-1
            returnType: bool
          synthetic set b @-1
            parameters
              requiredPositional _b @-1
                type: bool
            returnType: void
      abstract class C @37
        interfaces
          I
        constructors
          synthetic @-1
    topLevelVariables
      static c @57
        type: C
      static x @64
        type: bool
    accessors
      synthetic static get c @-1
        returnType: C
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: C
        returnType: void
      synthetic static get x @-1
        returnType: bool
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: bool
        returnType: void
''');
  }

  test_initializer_extractProperty_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  bool b;
}
abstract class C implements I {}
C f() => null;
var x = f().b;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class I @6
        fields
          b @17
            type: bool
        constructors
          synthetic @-1
        accessors
          synthetic get b @-1
            returnType: bool
          synthetic set b @-1
            parameters
              requiredPositional _b @-1
                type: bool
            returnType: void
      abstract class C @37
        interfaces
          I
        constructors
          synthetic @-1
    topLevelVariables
      static x @74
        type: bool
    accessors
      synthetic static get x @-1
        returnType: bool
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: bool
        returnType: void
    functions
      f @57
        returnType: C
''');
  }

  test_initializer_fromInstanceMethod() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int foo() => 0;
}
class B extends A {
  foo() => 1;
}
var x = A().foo();
var y = B().foo();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          foo @16
            returnType: int
      class B @36
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          foo @52
            returnType: int
    topLevelVariables
      static x @70
        type: int
      static y @89
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
      synthetic static get y @-1
        returnType: int
      synthetic static set y @-1
        parameters
          requiredPositional _y @-1
            type: int
        returnType: void
''');
  }

  test_initializer_functionExpression() async {
    var library = await _encodeDecodeLibrary(r'''
import 'dart:async';
var vFuture = new Future<int>(42);
var v_noParameters_inferredReturnType = () => 42;
var v_hasParameter_withType_inferredReturnType = (String a) => 42;
var v_hasParameter_withType_returnParameter = (String a) => a;
var v_async_returnValue = () async => 42;
var v_async_returnFuture = () async => vFuture;
''');
    checkElementText(library, r'''
library
  imports
    dart:async
  definingUnit
    topLevelVariables
      static vFuture @25
        type: Future<int>
      static v_noParameters_inferredReturnType @60
        type: int Function()
      static v_hasParameter_withType_inferredReturnType @110
        type: int Function(String)
      static v_hasParameter_withType_returnParameter @177
        type: String Function(String)
      static v_async_returnValue @240
        type: Future<int> Function()
      static v_async_returnFuture @282
        type: Future<int> Function()
    accessors
      synthetic static get vFuture @-1
        returnType: Future<int>
      synthetic static set vFuture @-1
        parameters
          requiredPositional _vFuture @-1
            type: Future<int>
        returnType: void
      synthetic static get v_noParameters_inferredReturnType @-1
        returnType: int Function()
      synthetic static set v_noParameters_inferredReturnType @-1
        parameters
          requiredPositional _v_noParameters_inferredReturnType @-1
            type: int Function()
        returnType: void
      synthetic static get v_hasParameter_withType_inferredReturnType @-1
        returnType: int Function(String)
      synthetic static set v_hasParameter_withType_inferredReturnType @-1
        parameters
          requiredPositional _v_hasParameter_withType_inferredReturnType @-1
            type: int Function(String)
        returnType: void
      synthetic static get v_hasParameter_withType_returnParameter @-1
        returnType: String Function(String)
      synthetic static set v_hasParameter_withType_returnParameter @-1
        parameters
          requiredPositional _v_hasParameter_withType_returnParameter @-1
            type: String Function(String)
        returnType: void
      synthetic static get v_async_returnValue @-1
        returnType: Future<int> Function()
      synthetic static set v_async_returnValue @-1
        parameters
          requiredPositional _v_async_returnValue @-1
            type: Future<int> Function()
        returnType: void
      synthetic static get v_async_returnFuture @-1
        returnType: Future<int> Function()
      synthetic static set v_async_returnFuture @-1
        parameters
          requiredPositional _v_async_returnFuture @-1
            type: Future<int> Function()
        returnType: void
''');
  }

  test_initializer_functionExpressionInvocation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
var v = (() => 42)();
''');
    // TODO(scheglov) add more function expression tests
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static v @4
        type: int
    accessors
      synthetic static get v @-1
        returnType: int
      synthetic static set v @-1
        parameters
          requiredPositional _v @-1
            type: int
        returnType: void
''');
  }

  test_initializer_functionInvocation_hasTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
T f<T>() => null;
var vHasTypeArgument = f<int>();
var vNoTypeArgument = f();
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vHasTypeArgument @22
        type: int
      static vNoTypeArgument @55
        type: dynamic
    accessors
      synthetic static get vHasTypeArgument @-1
        returnType: int
      synthetic static set vHasTypeArgument @-1
        parameters
          requiredPositional _vHasTypeArgument @-1
            type: int
        returnType: void
      synthetic static get vNoTypeArgument @-1
        returnType: dynamic
      synthetic static set vNoTypeArgument @-1
        parameters
          requiredPositional _vNoTypeArgument @-1
            type: dynamic
        returnType: void
    functions
      f @2
        typeParameters
          covariant T @4
        returnType: T
''');
  }

  test_initializer_functionInvocation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
String f(int p) => null;
var vOkArgumentType = f(1);
var vWrongArgumentType = f(2.0);
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vOkArgumentType @29
        type: String
      static vWrongArgumentType @57
        type: String
    accessors
      synthetic static get vOkArgumentType @-1
        returnType: String
      synthetic static set vOkArgumentType @-1
        parameters
          requiredPositional _vOkArgumentType @-1
            type: String
        returnType: void
      synthetic static get vWrongArgumentType @-1
        returnType: String
      synthetic static set vWrongArgumentType @-1
        parameters
          requiredPositional _vWrongArgumentType @-1
            type: String
        returnType: void
    functions
      f @7
        parameters
          requiredPositional p @13
            type: int
        returnType: String
''');
  }

  test_initializer_identifier() async {
    var library = await _encodeDecodeLibrary(r'''
String topLevelFunction(int p) => null;
var topLevelVariable = 0;
int get topLevelGetter => 0;
class A {
  static var staticClassVariable = 0;
  static int get staticGetter => 0;
  static String staticClassMethod(int p) => null;
  String instanceClassMethod(int p) => null;
}
var r_topLevelFunction = topLevelFunction;
var r_topLevelVariable = topLevelVariable;
var r_topLevelGetter = topLevelGetter;
var r_staticClassVariable = A.staticClassVariable;
var r_staticGetter = A.staticGetter;
var r_staticClassMethod = A.staticClassMethod;
var instanceOfA = new A();
var r_instanceClassMethod = instanceOfA.instanceClassMethod;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @101
        fields
          static staticClassVariable @118
            type: int
          synthetic static staticGetter @-1
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic static get staticClassVariable @-1
            returnType: int
          synthetic static set staticClassVariable @-1
            parameters
              requiredPositional _staticClassVariable @-1
                type: int
            returnType: void
          static get staticGetter @160
            returnType: int
        methods
          static staticClassMethod @195
            parameters
              requiredPositional p @217
                type: int
            returnType: String
          instanceClassMethod @238
            parameters
              requiredPositional p @262
                type: int
            returnType: String
    topLevelVariables
      static topLevelVariable @44
        type: int
      static r_topLevelFunction @280
        type: String Function(int)
      static r_topLevelVariable @323
        type: int
      static r_topLevelGetter @366
        type: int
      static r_staticClassVariable @405
        type: int
      static r_staticGetter @456
        type: int
      static r_staticClassMethod @493
        type: String Function(int)
      static instanceOfA @540
        type: A
      static r_instanceClassMethod @567
        type: String Function(int)
      synthetic static topLevelGetter @-1
        type: int
    accessors
      synthetic static get topLevelVariable @-1
        returnType: int
      synthetic static set topLevelVariable @-1
        parameters
          requiredPositional _topLevelVariable @-1
            type: int
        returnType: void
      synthetic static get r_topLevelFunction @-1
        returnType: String Function(int)
      synthetic static set r_topLevelFunction @-1
        parameters
          requiredPositional _r_topLevelFunction @-1
            type: String Function(int)
        returnType: void
      synthetic static get r_topLevelVariable @-1
        returnType: int
      synthetic static set r_topLevelVariable @-1
        parameters
          requiredPositional _r_topLevelVariable @-1
            type: int
        returnType: void
      synthetic static get r_topLevelGetter @-1
        returnType: int
      synthetic static set r_topLevelGetter @-1
        parameters
          requiredPositional _r_topLevelGetter @-1
            type: int
        returnType: void
      synthetic static get r_staticClassVariable @-1
        returnType: int
      synthetic static set r_staticClassVariable @-1
        parameters
          requiredPositional _r_staticClassVariable @-1
            type: int
        returnType: void
      synthetic static get r_staticGetter @-1
        returnType: int
      synthetic static set r_staticGetter @-1
        parameters
          requiredPositional _r_staticGetter @-1
            type: int
        returnType: void
      synthetic static get r_staticClassMethod @-1
        returnType: String Function(int)
      synthetic static set r_staticClassMethod @-1
        parameters
          requiredPositional _r_staticClassMethod @-1
            type: String Function(int)
        returnType: void
      synthetic static get instanceOfA @-1
        returnType: A
      synthetic static set instanceOfA @-1
        parameters
          requiredPositional _instanceOfA @-1
            type: A
        returnType: void
      synthetic static get r_instanceClassMethod @-1
        returnType: String Function(int)
      synthetic static set r_instanceClassMethod @-1
        parameters
          requiredPositional _r_instanceClassMethod @-1
            type: String Function(int)
        returnType: void
      static get topLevelGetter @74
        returnType: int
    functions
      topLevelFunction @7
        parameters
          requiredPositional p @28
            type: int
        returnType: String
''');
  }

  test_initializer_identifier_error_cycle_classField() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  static var a = B.b;
}
class B {
  static var b = A.a;
}
var c = A.a;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          static a @23
            typeInferenceError: dependencyCycle
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic static get a @-1
            returnType: dynamic
          synthetic static set a @-1
            parameters
              requiredPositional _a @-1
                type: dynamic
            returnType: void
      class B @40
        fields
          static b @57
            typeInferenceError: dependencyCycle
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic static get b @-1
            returnType: dynamic
          synthetic static set b @-1
            parameters
              requiredPositional _b @-1
                type: dynamic
            returnType: void
    topLevelVariables
      static c @72
        type: dynamic
    accessors
      synthetic static get c @-1
        returnType: dynamic
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: dynamic
        returnType: void
''');
  }

  test_initializer_identifier_error_cycle_mix() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  static var a = b;
}
var b = A.a;
var c = b;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          static a @23
            typeInferenceError: dependencyCycle
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic static get a @-1
            returnType: dynamic
          synthetic static set a @-1
            parameters
              requiredPositional _a @-1
                type: dynamic
            returnType: void
    topLevelVariables
      static b @36
        typeInferenceError: dependencyCycle
        type: dynamic
      static c @49
        type: dynamic
    accessors
      synthetic static get b @-1
        returnType: dynamic
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: dynamic
        returnType: void
      synthetic static get c @-1
        returnType: dynamic
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: dynamic
        returnType: void
''');
  }

  test_initializer_identifier_error_cycle_topLevel() async {
    var library = await _encodeDecodeLibrary(r'''
var a = b;
var b = c;
var c = a;
var d = a;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        typeInferenceError: dependencyCycle
        type: dynamic
      static b @15
        typeInferenceError: dependencyCycle
        type: dynamic
      static c @26
        typeInferenceError: dependencyCycle
        type: dynamic
      static d @37
        type: dynamic
    accessors
      synthetic static get a @-1
        returnType: dynamic
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: dynamic
        returnType: void
      synthetic static get b @-1
        returnType: dynamic
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: dynamic
        returnType: void
      synthetic static get c @-1
        returnType: dynamic
      synthetic static set c @-1
        parameters
          requiredPositional _c @-1
            type: dynamic
        returnType: void
      synthetic static get d @-1
        returnType: dynamic
      synthetic static set d @-1
        parameters
          requiredPositional _d @-1
            type: dynamic
        returnType: void
''');
  }

  test_initializer_identifier_formalParameter() async {
    // TODO(scheglov) I don't understand this yet
  }

  @failingTest
  test_initializer_instanceCreation_hasTypeParameter() async {
    var library = await _encodeDecodeLibrary(r'''
class A<T> {}
var a = new A<int>();
var b = new A();
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
class A<T> {
}
A<int> a;
dynamic b;
''');
  }

  test_initializer_instanceCreation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
class A {}
var a = new A();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
    topLevelVariables
      static a @15
        type: A
    accessors
      synthetic static get a @-1
        returnType: A
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: A
        returnType: void
''');
  }

  test_initializer_instanceGetterOfObject() async {
    var library = await _encodeDecodeLibrary(r'''
dynamic f() => null;
var s = f().toString();
var h = f().hashCode;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static s @25
        type: String
      static h @49
        type: int
    accessors
      synthetic static get s @-1
        returnType: String
      synthetic static set s @-1
        parameters
          requiredPositional _s @-1
            type: String
        returnType: void
      synthetic static get h @-1
        returnType: int
      synthetic static set h @-1
        parameters
          requiredPositional _h @-1
            type: int
        returnType: void
    functions
      f @8
        returnType: dynamic
''');
  }

  test_initializer_instanceGetterOfObject_prefixed() async {
    var library = await _encodeDecodeLibrary(r'''
dynamic d;
var s = d.toString();
var h = d.hashCode;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static d @8
        type: dynamic
      static s @15
        type: String
      static h @37
        type: int
    accessors
      synthetic static get d @-1
        returnType: dynamic
      synthetic static set d @-1
        parameters
          requiredPositional _d @-1
            type: dynamic
        returnType: void
      synthetic static get s @-1
        returnType: String
      synthetic static set s @-1
        parameters
          requiredPositional _s @-1
            type: String
        returnType: void
      synthetic static get h @-1
        returnType: int
      synthetic static set h @-1
        parameters
          requiredPositional _h @-1
            type: int
        returnType: void
''');
  }

  test_initializer_is() async {
    var library = await _encodeDecodeLibrary(r'''
var a = 1.2;
var b = a is int;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        type: double
      static b @17
        type: bool
    accessors
      synthetic static get a @-1
        returnType: double
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: double
        returnType: void
      synthetic static get b @-1
        returnType: bool
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: bool
        returnType: void
''');
  }

  @failingTest
  test_initializer_literal() async {
    var library = await _encodeDecodeLibrary(r'''
var vNull = null;
var vBoolFalse = false;
var vBoolTrue = true;
var vInt = 1;
var vIntLong = 0x9876543210987654321;
var vDouble = 2.3;
var vString = 'abc';
var vStringConcat = 'aaa' 'bbb';
var vStringInterpolation = 'aaa ${true} ${42} bbb';
var vSymbol = #aaa.bbb.ccc;
''');
    checkElementText(library, r'''
Null vNull;
bool vBoolFalse;
bool vBoolTrue;
int vInt;
int vIntLong;
double vDouble;
String vString;
String vStringConcat;
String vStringInterpolation;
Symbol vSymbol;
''');
  }

  test_initializer_literal_list_typed() async {
    var library = await _encodeDecodeLibrary(r'''
var vObject = <Object>[1, 2, 3];
var vNum = <num>[1, 2, 3];
var vNumEmpty = <num>[];
var vInt = <int>[1, 2, 3];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vObject @4
        type: List<Object>
      static vNum @37
        type: List<num>
      static vNumEmpty @64
        type: List<num>
      static vInt @89
        type: List<int>
    accessors
      synthetic static get vObject @-1
        returnType: List<Object>
      synthetic static set vObject @-1
        parameters
          requiredPositional _vObject @-1
            type: List<Object>
        returnType: void
      synthetic static get vNum @-1
        returnType: List<num>
      synthetic static set vNum @-1
        parameters
          requiredPositional _vNum @-1
            type: List<num>
        returnType: void
      synthetic static get vNumEmpty @-1
        returnType: List<num>
      synthetic static set vNumEmpty @-1
        parameters
          requiredPositional _vNumEmpty @-1
            type: List<num>
        returnType: void
      synthetic static get vInt @-1
        returnType: List<int>
      synthetic static set vInt @-1
        parameters
          requiredPositional _vInt @-1
            type: List<int>
        returnType: void
''');
  }

  test_initializer_literal_list_untyped() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = [1, 2, 3];
var vNum = [1, 2.0];
var vObject = [1, 2.0, '333'];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vInt @4
        type: List<int>
      static vNum @26
        type: List<num>
      static vObject @47
        type: List<Object>
    accessors
      synthetic static get vInt @-1
        returnType: List<int>
      synthetic static set vInt @-1
        parameters
          requiredPositional _vInt @-1
            type: List<int>
        returnType: void
      synthetic static get vNum @-1
        returnType: List<num>
      synthetic static set vNum @-1
        parameters
          requiredPositional _vNum @-1
            type: List<num>
        returnType: void
      synthetic static get vObject @-1
        returnType: List<Object>
      synthetic static set vObject @-1
        parameters
          requiredPositional _vObject @-1
            type: List<Object>
        returnType: void
''');
  }

  @failingTest
  test_initializer_literal_list_untyped_empty() async {
    var library = await _encodeDecodeLibrary(r'''
var vNonConst = [];
var vConst = const [];
''');
    checkElementText(library, r'''
List<dynamic> vNonConst;
List<Null> vConst;
''');
  }

  test_initializer_literal_map_typed() async {
    var library = await _encodeDecodeLibrary(r'''
var vObjectObject = <Object, Object>{1: 'a'};
var vComparableObject = <Comparable<int>, Object>{1: 'a'};
var vNumString = <num, String>{1: 'a'};
var vNumStringEmpty = <num, String>{};
var vIntString = <int, String>{};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vObjectObject @4
        type: Map<Object, Object>
      static vComparableObject @50
        type: Map<Comparable<int>, Object>
      static vNumString @109
        type: Map<num, String>
      static vNumStringEmpty @149
        type: Map<num, String>
      static vIntString @188
        type: Map<int, String>
    accessors
      synthetic static get vObjectObject @-1
        returnType: Map<Object, Object>
      synthetic static set vObjectObject @-1
        parameters
          requiredPositional _vObjectObject @-1
            type: Map<Object, Object>
        returnType: void
      synthetic static get vComparableObject @-1
        returnType: Map<Comparable<int>, Object>
      synthetic static set vComparableObject @-1
        parameters
          requiredPositional _vComparableObject @-1
            type: Map<Comparable<int>, Object>
        returnType: void
      synthetic static get vNumString @-1
        returnType: Map<num, String>
      synthetic static set vNumString @-1
        parameters
          requiredPositional _vNumString @-1
            type: Map<num, String>
        returnType: void
      synthetic static get vNumStringEmpty @-1
        returnType: Map<num, String>
      synthetic static set vNumStringEmpty @-1
        parameters
          requiredPositional _vNumStringEmpty @-1
            type: Map<num, String>
        returnType: void
      synthetic static get vIntString @-1
        returnType: Map<int, String>
      synthetic static set vIntString @-1
        parameters
          requiredPositional _vIntString @-1
            type: Map<int, String>
        returnType: void
''');
  }

  test_initializer_literal_map_untyped() async {
    var library = await _encodeDecodeLibrary(r'''
var vIntString = {1: 'a', 2: 'b'};
var vNumString = {1: 'a', 2.0: 'b'};
var vIntObject = {1: 'a', 2: 3.0};
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vIntString @4
        type: Map<int, String>
      static vNumString @39
        type: Map<num, String>
      static vIntObject @76
        type: Map<int, Object>
    accessors
      synthetic static get vIntString @-1
        returnType: Map<int, String>
      synthetic static set vIntString @-1
        parameters
          requiredPositional _vIntString @-1
            type: Map<int, String>
        returnType: void
      synthetic static get vNumString @-1
        returnType: Map<num, String>
      synthetic static set vNumString @-1
        parameters
          requiredPositional _vNumString @-1
            type: Map<num, String>
        returnType: void
      synthetic static get vIntObject @-1
        returnType: Map<int, Object>
      synthetic static set vIntObject @-1
        parameters
          requiredPositional _vIntObject @-1
            type: Map<int, Object>
        returnType: void
''');
  }

  @failingTest
  test_initializer_literal_map_untyped_empty() async {
    var library = await _encodeDecodeLibrary(r'''
var vNonConst = {};
var vConst = const {};
''');
    checkElementText(library, r'''
Map<dynamic, dynamic> vNonConst;
Map<Null, Null> vConst;
''');
  }

  test_initializer_logicalBool() async {
    var library = await _encodeDecodeLibrary(r'''
var a = true;
var b = true;
var vEq = 1 == 2;
var vAnd = a && b;
var vOr = a || b;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        type: bool
      static b @18
        type: bool
      static vEq @32
        type: bool
      static vAnd @50
        type: bool
      static vOr @69
        type: bool
    accessors
      synthetic static get a @-1
        returnType: bool
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: bool
        returnType: void
      synthetic static get b @-1
        returnType: bool
      synthetic static set b @-1
        parameters
          requiredPositional _b @-1
            type: bool
        returnType: void
      synthetic static get vEq @-1
        returnType: bool
      synthetic static set vEq @-1
        parameters
          requiredPositional _vEq @-1
            type: bool
        returnType: void
      synthetic static get vAnd @-1
        returnType: bool
      synthetic static set vAnd @-1
        parameters
          requiredPositional _vAnd @-1
            type: bool
        returnType: void
      synthetic static get vOr @-1
        returnType: bool
      synthetic static set vOr @-1
        parameters
          requiredPositional _vOr @-1
            type: bool
        returnType: void
''');
  }

  @failingTest
  test_initializer_methodInvocation_hasTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  List<T> m<T>() => null;
}
var vWithTypeArgument = new A().m<int>();
var vWithoutTypeArgument = new A().m();
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
class A {
  List<T> m<T>(int p) {}
}
List<int> vWithTypeArgument;
dynamic vWithoutTypeArgument;
''');
  }

  test_initializer_methodInvocation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int p) => null;
}
var instanceOfA = new A();
var v1 = instanceOfA.m();
var v2 = new A().m();
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @19
            parameters
              requiredPositional p @25
                type: int
            returnType: String
    topLevelVariables
      static instanceOfA @43
        type: A
      static v1 @70
        type: String
      static v2 @96
        type: String
    accessors
      synthetic static get instanceOfA @-1
        returnType: A
      synthetic static set instanceOfA @-1
        parameters
          requiredPositional _instanceOfA @-1
            type: A
        returnType: void
      synthetic static get v1 @-1
        returnType: String
      synthetic static set v1 @-1
        parameters
          requiredPositional _v1 @-1
            type: String
        returnType: void
      synthetic static get v2 @-1
        returnType: String
      synthetic static set v2 @-1
        parameters
          requiredPositional _v2 @-1
            type: String
        returnType: void
''');
  }

  test_initializer_multiplicative() async {
    var library = await _encodeDecodeLibrary(r'''
var vModuloIntInt = 1 % 2;
var vModuloIntDouble = 1 % 2.0;
var vMultiplyIntInt = 1 * 2;
var vMultiplyIntDouble = 1 * 2.0;
var vMultiplyDoubleInt = 1.0 * 2;
var vMultiplyDoubleDouble = 1.0 * 2.0;
var vDivideIntInt = 1 / 2;
var vDivideIntDouble = 1 / 2.0;
var vDivideDoubleInt = 1.0 / 2;
var vDivideDoubleDouble = 1.0 / 2.0;
var vFloorDivide = 1 ~/ 2;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vModuloIntInt @4
        type: int
      static vModuloIntDouble @31
        type: double
      static vMultiplyIntInt @63
        type: int
      static vMultiplyIntDouble @92
        type: double
      static vMultiplyDoubleInt @126
        type: double
      static vMultiplyDoubleDouble @160
        type: double
      static vDivideIntInt @199
        type: double
      static vDivideIntDouble @226
        type: double
      static vDivideDoubleInt @258
        type: double
      static vDivideDoubleDouble @290
        type: double
      static vFloorDivide @327
        type: int
    accessors
      synthetic static get vModuloIntInt @-1
        returnType: int
      synthetic static set vModuloIntInt @-1
        parameters
          requiredPositional _vModuloIntInt @-1
            type: int
        returnType: void
      synthetic static get vModuloIntDouble @-1
        returnType: double
      synthetic static set vModuloIntDouble @-1
        parameters
          requiredPositional _vModuloIntDouble @-1
            type: double
        returnType: void
      synthetic static get vMultiplyIntInt @-1
        returnType: int
      synthetic static set vMultiplyIntInt @-1
        parameters
          requiredPositional _vMultiplyIntInt @-1
            type: int
        returnType: void
      synthetic static get vMultiplyIntDouble @-1
        returnType: double
      synthetic static set vMultiplyIntDouble @-1
        parameters
          requiredPositional _vMultiplyIntDouble @-1
            type: double
        returnType: void
      synthetic static get vMultiplyDoubleInt @-1
        returnType: double
      synthetic static set vMultiplyDoubleInt @-1
        parameters
          requiredPositional _vMultiplyDoubleInt @-1
            type: double
        returnType: void
      synthetic static get vMultiplyDoubleDouble @-1
        returnType: double
      synthetic static set vMultiplyDoubleDouble @-1
        parameters
          requiredPositional _vMultiplyDoubleDouble @-1
            type: double
        returnType: void
      synthetic static get vDivideIntInt @-1
        returnType: double
      synthetic static set vDivideIntInt @-1
        parameters
          requiredPositional _vDivideIntInt @-1
            type: double
        returnType: void
      synthetic static get vDivideIntDouble @-1
        returnType: double
      synthetic static set vDivideIntDouble @-1
        parameters
          requiredPositional _vDivideIntDouble @-1
            type: double
        returnType: void
      synthetic static get vDivideDoubleInt @-1
        returnType: double
      synthetic static set vDivideDoubleInt @-1
        parameters
          requiredPositional _vDivideDoubleInt @-1
            type: double
        returnType: void
      synthetic static get vDivideDoubleDouble @-1
        returnType: double
      synthetic static set vDivideDoubleDouble @-1
        parameters
          requiredPositional _vDivideDoubleDouble @-1
            type: double
        returnType: void
      synthetic static get vFloorDivide @-1
        returnType: int
      synthetic static set vFloorDivide @-1
        parameters
          requiredPositional _vFloorDivide @-1
            type: int
        returnType: void
''');
  }

  test_initializer_onlyLeft() async {
    var library = await _encodeDecodeLibrary(r'''
var a = 1;
var vEq = a == ((a = 2) == 0);
var vNotEq = a != ((a = 2) == 0);
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static a @4
        type: int
      static vEq @15
        type: bool
      static vNotEq @46
        type: bool
    accessors
      synthetic static get a @-1
        returnType: int
      synthetic static set a @-1
        parameters
          requiredPositional _a @-1
            type: int
        returnType: void
      synthetic static get vEq @-1
        returnType: bool
      synthetic static set vEq @-1
        parameters
          requiredPositional _vEq @-1
            type: bool
        returnType: void
      synthetic static get vNotEq @-1
        returnType: bool
      synthetic static set vNotEq @-1
        parameters
          requiredPositional _vNotEq @-1
            type: bool
        returnType: void
''');
  }

  test_initializer_parenthesized() async {
    var library = await _encodeDecodeLibrary(r'''
var V = (42);
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static V @4
        type: int
    accessors
      synthetic static get V @-1
        returnType: int
      synthetic static set V @-1
        parameters
          requiredPositional _V @-1
            type: int
        returnType: void
''');
  }

  test_initializer_postfix() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = 1;
var vDouble = 2.0;
var vIncInt = vInt++;
var vDecInt = vInt--;
var vIncDouble = vDouble++;
var vDecDouble = vDouble--;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vInt @4
        type: int
      static vDouble @18
        type: double
      static vIncInt @37
        type: int
      static vDecInt @59
        type: int
      static vIncDouble @81
        type: double
      static vDecDouble @109
        type: double
    accessors
      synthetic static get vInt @-1
        returnType: int
      synthetic static set vInt @-1
        parameters
          requiredPositional _vInt @-1
            type: int
        returnType: void
      synthetic static get vDouble @-1
        returnType: double
      synthetic static set vDouble @-1
        parameters
          requiredPositional _vDouble @-1
            type: double
        returnType: void
      synthetic static get vIncInt @-1
        returnType: int
      synthetic static set vIncInt @-1
        parameters
          requiredPositional _vIncInt @-1
            type: int
        returnType: void
      synthetic static get vDecInt @-1
        returnType: int
      synthetic static set vDecInt @-1
        parameters
          requiredPositional _vDecInt @-1
            type: int
        returnType: void
      synthetic static get vIncDouble @-1
        returnType: double
      synthetic static set vIncDouble @-1
        parameters
          requiredPositional _vIncDouble @-1
            type: double
        returnType: void
      synthetic static get vDecDouble @-1
        returnType: double
      synthetic static set vDecDouble @-1
        parameters
          requiredPositional _vDecDouble @-1
            type: double
        returnType: void
''');
  }

  test_initializer_postfix_indexed() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = [1];
var vDouble = [2.0];
var vIncInt = vInt[0]++;
var vDecInt = vInt[0]--;
var vIncDouble = vDouble[0]++;
var vDecDouble = vDouble[0]--;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vInt @4
        type: List<int>
      static vDouble @20
        type: List<double>
      static vIncInt @41
        type: int
      static vDecInt @66
        type: int
      static vIncDouble @91
        type: double
      static vDecDouble @122
        type: double
    accessors
      synthetic static get vInt @-1
        returnType: List<int>
      synthetic static set vInt @-1
        parameters
          requiredPositional _vInt @-1
            type: List<int>
        returnType: void
      synthetic static get vDouble @-1
        returnType: List<double>
      synthetic static set vDouble @-1
        parameters
          requiredPositional _vDouble @-1
            type: List<double>
        returnType: void
      synthetic static get vIncInt @-1
        returnType: int
      synthetic static set vIncInt @-1
        parameters
          requiredPositional _vIncInt @-1
            type: int
        returnType: void
      synthetic static get vDecInt @-1
        returnType: int
      synthetic static set vDecInt @-1
        parameters
          requiredPositional _vDecInt @-1
            type: int
        returnType: void
      synthetic static get vIncDouble @-1
        returnType: double
      synthetic static set vIncDouble @-1
        parameters
          requiredPositional _vIncDouble @-1
            type: double
        returnType: void
      synthetic static get vDecDouble @-1
        returnType: double
      synthetic static set vDecDouble @-1
        parameters
          requiredPositional _vDecDouble @-1
            type: double
        returnType: void
''');
  }

  test_initializer_prefix_incDec() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = 1;
var vDouble = 2.0;
var vIncInt = ++vInt;
var vDecInt = --vInt;
var vIncDouble = ++vDouble;
var vDecInt = --vDouble;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vInt @4
        type: int
      static vDouble @18
        type: double
      static vIncInt @37
        type: int
      static vDecInt @59
        type: int
      static vIncDouble @81
        type: double
      static vDecInt @109
        type: double
    accessors
      synthetic static get vInt @-1
        returnType: int
      synthetic static set vInt @-1
        parameters
          requiredPositional _vInt @-1
            type: int
        returnType: void
      synthetic static get vDouble @-1
        returnType: double
      synthetic static set vDouble @-1
        parameters
          requiredPositional _vDouble @-1
            type: double
        returnType: void
      synthetic static get vIncInt @-1
        returnType: int
      synthetic static set vIncInt @-1
        parameters
          requiredPositional _vIncInt @-1
            type: int
        returnType: void
      synthetic static get vDecInt @-1
        returnType: int
      synthetic static set vDecInt @-1
        parameters
          requiredPositional _vDecInt @-1
            type: int
        returnType: void
      synthetic static get vIncDouble @-1
        returnType: double
      synthetic static set vIncDouble @-1
        parameters
          requiredPositional _vIncDouble @-1
            type: double
        returnType: void
      synthetic static get vDecInt @-1
        returnType: double
      synthetic static set vDecInt @-1
        parameters
          requiredPositional _vDecInt @-1
            type: double
        returnType: void
''');
  }

  @failingTest
  test_initializer_prefix_incDec_custom() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  B operator+(int v) => null;
}
class B {}
var a = new A();
var vInc = ++a;
var vDec = --a;
''');
    checkElementText(library, r'''
A a;
B vInc;
B vDec;
''');
  }

  test_initializer_prefix_incDec_indexed() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = [1];
var vDouble = [2.0];
var vIncInt = ++vInt[0];
var vDecInt = --vInt[0];
var vIncDouble = ++vDouble[0];
var vDecInt = --vDouble[0];
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vInt @4
        type: List<int>
      static vDouble @20
        type: List<double>
      static vIncInt @41
        type: int
      static vDecInt @66
        type: int
      static vIncDouble @91
        type: double
      static vDecInt @122
        type: double
    accessors
      synthetic static get vInt @-1
        returnType: List<int>
      synthetic static set vInt @-1
        parameters
          requiredPositional _vInt @-1
            type: List<int>
        returnType: void
      synthetic static get vDouble @-1
        returnType: List<double>
      synthetic static set vDouble @-1
        parameters
          requiredPositional _vDouble @-1
            type: List<double>
        returnType: void
      synthetic static get vIncInt @-1
        returnType: int
      synthetic static set vIncInt @-1
        parameters
          requiredPositional _vIncInt @-1
            type: int
        returnType: void
      synthetic static get vDecInt @-1
        returnType: int
      synthetic static set vDecInt @-1
        parameters
          requiredPositional _vDecInt @-1
            type: int
        returnType: void
      synthetic static get vIncDouble @-1
        returnType: double
      synthetic static set vIncDouble @-1
        parameters
          requiredPositional _vIncDouble @-1
            type: double
        returnType: void
      synthetic static get vDecInt @-1
        returnType: double
      synthetic static set vDecInt @-1
        parameters
          requiredPositional _vDecInt @-1
            type: double
        returnType: void
''');
  }

  test_initializer_prefix_not() async {
    var library = await _encodeDecodeLibrary(r'''
var vNot = !true;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vNot @4
        type: bool
    accessors
      synthetic static get vNot @-1
        returnType: bool
      synthetic static set vNot @-1
        parameters
          requiredPositional _vNot @-1
            type: bool
        returnType: void
''');
  }

  test_initializer_prefix_other() async {
    var library = await _encodeDecodeLibrary(r'''
var vNegateInt = -1;
var vNegateDouble = -1.0;
var vComplement = ~1;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vNegateInt @4
        type: int
      static vNegateDouble @25
        type: double
      static vComplement @51
        type: int
    accessors
      synthetic static get vNegateInt @-1
        returnType: int
      synthetic static set vNegateInt @-1
        parameters
          requiredPositional _vNegateInt @-1
            type: int
        returnType: void
      synthetic static get vNegateDouble @-1
        returnType: double
      synthetic static set vNegateDouble @-1
        parameters
          requiredPositional _vNegateDouble @-1
            type: double
        returnType: void
      synthetic static get vComplement @-1
        returnType: int
      synthetic static set vComplement @-1
        parameters
          requiredPositional _vComplement @-1
            type: int
        returnType: void
''');
  }

  test_initializer_referenceToFieldOfStaticField() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  static D d;
}
class D {
  int i;
}
final x = C.d.i;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          static d @21
            type: D
        constructors
          synthetic @-1
        accessors
          synthetic static get d @-1
            returnType: D
          synthetic static set d @-1
            parameters
              requiredPositional _d @-1
                type: D
            returnType: void
      class D @32
        fields
          i @42
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get i @-1
            returnType: int
          synthetic set i @-1
            parameters
              requiredPositional _i @-1
                type: int
            returnType: void
    topLevelVariables
      static final x @53
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
''');
  }

  test_initializer_referenceToFieldOfStaticGetter() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  static D get d => null;
}
class D {
  int i;
}
var x = C.d.i;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class C @6
        fields
          synthetic static d @-1
            type: D
        constructors
          synthetic @-1
        accessors
          static get d @25
            returnType: D
      class D @44
        fields
          i @54
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get i @-1
            returnType: int
          synthetic set i @-1
            parameters
              requiredPositional _i @-1
                type: int
            returnType: void
    topLevelVariables
      static x @63
        type: int
    accessors
      synthetic static get x @-1
        returnType: int
      synthetic static set x @-1
        parameters
          requiredPositional _x @-1
            type: int
        returnType: void
''');
  }

  test_initializer_relational() async {
    var library = await _encodeDecodeLibrary(r'''
var vLess = 1 < 2;
var vLessOrEqual = 1 <= 2;
var vGreater = 1 > 2;
var vGreaterOrEqual = 1 >= 2;
''');
    checkElementText(library, r'''
library
  definingUnit
    topLevelVariables
      static vLess @4
        type: bool
      static vLessOrEqual @23
        type: bool
      static vGreater @50
        type: bool
      static vGreaterOrEqual @72
        type: bool
    accessors
      synthetic static get vLess @-1
        returnType: bool
      synthetic static set vLess @-1
        parameters
          requiredPositional _vLess @-1
            type: bool
        returnType: void
      synthetic static get vLessOrEqual @-1
        returnType: bool
      synthetic static set vLessOrEqual @-1
        parameters
          requiredPositional _vLessOrEqual @-1
            type: bool
        returnType: void
      synthetic static get vGreater @-1
        returnType: bool
      synthetic static set vGreater @-1
        parameters
          requiredPositional _vGreater @-1
            type: bool
        returnType: void
      synthetic static get vGreaterOrEqual @-1
        returnType: bool
      synthetic static set vGreaterOrEqual @-1
        parameters
          requiredPositional _vGreaterOrEqual @-1
            type: bool
        returnType: void
''');
  }

  @failingTest
  test_initializer_throw() async {
    var library = await _encodeDecodeLibrary(r'''
var V = throw 42;
''');
    checkElementText(library, r'''
Null V;
''');
  }

  test_instanceField_error_noSetterParameter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int x;
}
class B implements A {
  set x() {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          x @25
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
      class B @36
        interfaces
          A
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          set x @59
            returnType: void
''');
  }

  test_instanceField_fieldFormal() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  var f = 0;
  A([this.f = 'hello']);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          f @16
            type: int
        constructors
          @25
            parameters
              optionalPositional final this.f @33
                type: int
                constantInitializer
                  SimpleStringLiteral
                    literal: 'hello' @37
                field: self::@class::A::@field::f
        accessors
          synthetic get f @-1
            returnType: int
          synthetic set f @-1
            parameters
              requiredPositional _f @-1
                type: int
            returnType: void
''');
  }

  test_instanceField_fromField() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int x;
  int y;
  int z;
}
class B implements A {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          x @25
            type: int
          y @34
            type: int
          z @43
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
          synthetic get y @-1
            returnType: int
          synthetic set y @-1
            parameters
              requiredPositional _y @-1
                type: int
            returnType: void
          synthetic get z @-1
            returnType: int
          synthetic set z @-1
            parameters
              requiredPositional _z @-1
                type: int
            returnType: void
      class B @54
        interfaces
          A
        fields
          x @77
            type: int
          synthetic y @-1
            type: int
          synthetic z @-1
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
          get y @86
            returnType: int
          set z @103
            parameters
              requiredPositional _ @105
                type: int
            returnType: void
''');
  }

  test_instanceField_fromField_explicitDynamic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  dynamic x;
}
class B implements A {
  var x = 1;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          x @29
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
      class B @40
        interfaces
          A
        fields
          x @63
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_instanceField_fromField_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<E> {
  E x;
  E y;
  E z;
}
class B<T> implements A<T> {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        typeParameters
          covariant E @17
            defaultType: dynamic
        fields
          x @26
            type: E
          y @33
            type: E
          z @40
            type: E
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: E
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: E
            returnType: void
          synthetic get y @-1
            returnType: E
          synthetic set y @-1
            parameters
              requiredPositional _y @-1
                type: E
            returnType: void
          synthetic get z @-1
            returnType: E
          synthetic set z @-1
            parameters
              requiredPositional _z @-1
                type: E
            returnType: void
      class B @51
        typeParameters
          covariant T @53
            defaultType: dynamic
        interfaces
          A<T>
        fields
          x @80
            type: T
          synthetic y @-1
            type: T
          synthetic z @-1
            type: T
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: T
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: T
            returnType: void
          get y @89
            returnType: T
          set z @106
            parameters
              requiredPositional _ @108
                type: T
            returnType: void
''');
  }

  test_instanceField_fromField_implicitDynamic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  var x;
}
class B implements A {
  var x = 1;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          x @25
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
      class B @36
        interfaces
          A
        fields
          x @59
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
''');
  }

  test_instanceField_fromField_narrowType() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num x;
}
class B implements A {
  var x = 1;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          x @25
            type: num
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: num
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: num
            returnType: void
      class B @36
        interfaces
          A
        fields
          x @59
            type: num
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: num
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: num
            returnType: void
''');
  }

  test_instanceField_fromGetter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
  int get y;
  int get z;
}
class B implements A {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
          synthetic y @-1
            type: int
          synthetic z @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
          abstract get y @42
            returnType: int
          abstract get z @55
            returnType: int
      class B @66
        interfaces
          A
        fields
          x @89
            type: int
          synthetic y @-1
            type: int
          synthetic z @-1
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
          get y @98
            returnType: int
          set z @115
            parameters
              requiredPositional _ @117
                type: int
            returnType: void
''');
  }

  test_instanceField_fromGetter_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<E> {
  E get x;
  E get y;
  E get z;
}
class B<T> implements A<T> {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        typeParameters
          covariant E @17
            defaultType: dynamic
        fields
          synthetic x @-1
            type: E
          synthetic y @-1
            type: E
          synthetic z @-1
            type: E
        constructors
          synthetic @-1
        accessors
          abstract get x @30
            returnType: E
          abstract get y @41
            returnType: E
          abstract get z @52
            returnType: E
      class B @63
        typeParameters
          covariant T @65
            defaultType: dynamic
        interfaces
          A<T>
        fields
          x @92
            type: T
          synthetic y @-1
            type: T
          synthetic z @-1
            type: T
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: T
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: T
            returnType: void
          get y @101
            returnType: T
          set z @118
            parameters
              requiredPositional _ @120
                type: T
            returnType: void
''');
  }

  test_instanceField_fromGetter_multiple_different() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  String get x;
}
class C implements A, B {
  get x => null;
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
      abstract class B @49
        fields
          synthetic x @-1
            type: String
        constructors
          synthetic @-1
        accessors
          abstract get x @66
            returnType: String
      class C @77
        interfaces
          A
          B
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          get x @103
            returnType: dynamic
''');
  }

  test_instanceField_fromGetter_multiple_different_dynamic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  dynamic get x;
}
class C implements A, B {
  get x => null;
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
      abstract class B @49
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          abstract get x @67
            returnType: dynamic
      class C @78
        interfaces
          A
          B
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get x @104
            returnType: int
''');
  }

  test_instanceField_fromGetter_multiple_different_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<T> {
  T get x;
}
abstract class B<T> {
  T get x;
}
class C implements A<int>, B<String> {
  get x => null;
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        typeParameters
          covariant T @17
            defaultType: dynamic
        fields
          synthetic x @-1
            type: T
        constructors
          synthetic @-1
        accessors
          abstract get x @30
            returnType: T
      abstract class B @50
        typeParameters
          covariant T @52
            defaultType: dynamic
        fields
          synthetic x @-1
            type: T
        constructors
          synthetic @-1
        accessors
          abstract get x @65
            returnType: T
      class C @76
        interfaces
          A<int>
          B<String>
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          get x @115
            returnType: dynamic
''');
  }

  test_instanceField_fromGetter_multiple_same() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  int get x;
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
      abstract class B @49
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @63
            returnType: int
      class C @74
        interfaces
          A
          B
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get x @100
            returnType: int
''');
  }

  test_instanceField_fromGetterSetter_different_field() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
  int get y;
}
abstract class B {
  void set x(String _);
  void set y(String _);
}
class C implements A, B {
  var x;
  final y;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
          synthetic y @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
          abstract get y @42
            returnType: int
      abstract class B @62
        fields
          synthetic x @-1
            type: String
          synthetic y @-1
            type: String
        constructors
          synthetic @-1
        accessors
          abstract set x @77
            parameters
              requiredPositional _ @86
                type: String
            returnType: void
          abstract set y @101
            parameters
              requiredPositional _ @110
                type: String
            returnType: void
      class C @122
        interfaces
          A
          B
        fields
          x @148
            typeInferenceError: overrideConflictFieldType
            type: dynamic
          final y @159
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: dynamic
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: dynamic
            returnType: void
          synthetic get y @-1
            returnType: int
''');
  }

  test_instanceField_fromGetterSetter_different_getter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
      abstract class B @49
        fields
          synthetic x @-1
            type: String
        constructors
          synthetic @-1
        accessors
          abstract set x @64
            parameters
              requiredPositional _ @73
                type: String
            returnType: void
      class C @85
        interfaces
          A
          B
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get x @111
            returnType: int
''');
  }

  test_instanceField_fromGetterSetter_different_setter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  set x(_);
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
      abstract class B @49
        fields
          synthetic x @-1
            type: String
        constructors
          synthetic @-1
        accessors
          abstract set x @64
            parameters
              requiredPositional _ @73
                type: String
            returnType: void
      class C @85
        interfaces
          A
          B
        fields
          synthetic x @-1
            type: String
        constructors
          synthetic @-1
        accessors
          abstract set x @111
            parameters
              requiredPositional _ @113
                type: String
            returnType: void
''');
  }

  test_instanceField_fromGetterSetter_same_field() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  var x;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
      abstract class B @49
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @64
            parameters
              requiredPositional _ @70
                type: int
            returnType: void
      class C @82
        interfaces
          A
          B
        fields
          x @108
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
''');
  }

  test_instanceField_fromGetterSetter_same_getter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
      abstract class B @49
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @64
            parameters
              requiredPositional _ @70
                type: int
            returnType: void
      class C @82
        interfaces
          A
          B
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get x @108
            returnType: int
''');
  }

  test_instanceField_fromGetterSetter_same_setter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  set x(_);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: int
      abstract class B @49
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @64
            parameters
              requiredPositional _ @70
                type: int
            returnType: void
      class C @82
        interfaces
          A
          B
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @108
            parameters
              requiredPositional _ @110
                type: int
            returnType: void
''');
  }

  test_instanceField_fromSetter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  void set x(int _);
  void set y(int _);
  void set z(int _);
}
class B implements A {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
          synthetic y @-1
            type: int
          synthetic z @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @30
            parameters
              requiredPositional _ @36
                type: int
            returnType: void
          abstract set y @51
            parameters
              requiredPositional _ @57
                type: int
            returnType: void
          abstract set z @72
            parameters
              requiredPositional _ @78
                type: int
            returnType: void
      class B @90
        interfaces
          A
        fields
          x @113
            type: int
          synthetic y @-1
            type: int
          synthetic z @-1
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional _x @-1
                type: int
            returnType: void
          get y @122
            returnType: int
          set z @139
            parameters
              requiredPositional _ @141
                type: int
            returnType: void
''');
  }

  test_instanceField_fromSetter_multiple_different() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  void set x(int _);
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @30
            parameters
              requiredPositional _ @36
                type: int
            returnType: void
      abstract class B @57
        fields
          synthetic x @-1
            type: String
        constructors
          synthetic @-1
        accessors
          abstract set x @72
            parameters
              requiredPositional _ @81
                type: String
            returnType: void
      class C @93
        interfaces
          A
          B
        fields
          synthetic x @-1
            type: dynamic
        constructors
          synthetic @-1
        accessors
          get x @119
            returnType: dynamic
''');
  }

  test_instanceField_fromSetter_multiple_same() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  void set x(int _);
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @30
            parameters
              requiredPositional _ @36
                type: int
            returnType: void
      abstract class B @57
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          abstract set x @72
            parameters
              requiredPositional _ @78
                type: int
            returnType: void
      class C @90
        interfaces
          A
          B
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          get x @116
            returnType: int
''');
  }

  test_instanceField_functionTypeAlias_doesNotUseItsTypeParameter() async {
    var library = await _encodeDecodeLibrary(r'''
typedef F<T>();

class A<T> {
  F<T> get x => null;
  List<F<T>> get y => null;
}

class B extends A<int> {
  get x => null;
  get y => null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @23
        typeParameters
          covariant T @25
            defaultType: dynamic
        fields
          synthetic x @-1
            type: dynamic Function()
              alias: self::@typeAlias::F
                typeArguments
                  T
          synthetic y @-1
            type: List<dynamic Function()>
        constructors
          synthetic @-1
        accessors
          get x @41
            returnType: dynamic Function()
              alias: self::@typeAlias::F
                typeArguments
                  T
          get y @69
            returnType: List<dynamic Function()>
      class B @89
        supertype: A<int>
        fields
          synthetic x @-1
            type: dynamic Function()
              alias: self::@typeAlias::F
                typeArguments
                  int
          synthetic y @-1
            type: List<dynamic Function()>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {T: int}
        accessors
          get x @114
            returnType: dynamic Function()
              alias: self::@typeAlias::F
                typeArguments
                  int
          get y @131
            returnType: List<dynamic Function()>
    typeAliases
      functionTypeAliasBased F @8
        typeParameters
          unrelated T @10
            defaultType: dynamic
        aliasedType: dynamic Function()
        aliasedElement: GenericFunctionTypeElement
          returnType: dynamic
''');
  }

  test_instanceField_inheritsCovariant_fromSetter_field() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num get x;
  void set x(covariant num _);
}
class B implements A {
  int x;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: num
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: num
          abstract set x @43
            parameters
              requiredPositional covariant _ @59
                type: num
            returnType: void
      class B @71
        interfaces
          A
        fields
          x @94
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get x @-1
            returnType: int
          synthetic set x @-1
            parameters
              requiredPositional covariant _x @-1
                type: int
            returnType: void
''');
  }

  test_instanceField_inheritsCovariant_fromSetter_setter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num get x;
  void set x(covariant num _);
}
class B implements A {
  set x(int _) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        fields
          synthetic x @-1
            type: num
        constructors
          synthetic @-1
        accessors
          abstract get x @29
            returnType: num
          abstract set x @43
            parameters
              requiredPositional covariant _ @59
                type: num
            returnType: void
      class B @71
        interfaces
          A
        fields
          synthetic x @-1
            type: int
        constructors
          synthetic @-1
        accessors
          set x @94
            parameters
              requiredPositional covariant _ @100
                type: int
            returnType: void
''');
  }

  test_instanceField_initializer() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  var t1 = 1;
  var t2 = 2.0;
  var t3 = null;
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          t1 @16
            type: int
          t2 @30
            type: double
          t3 @46
            type: dynamic
        constructors
          synthetic @-1
        accessors
          synthetic get t1 @-1
            returnType: int
          synthetic set t1 @-1
            parameters
              requiredPositional _t1 @-1
                type: int
            returnType: void
          synthetic get t2 @-1
            returnType: double
          synthetic set t2 @-1
            parameters
              requiredPositional _t2 @-1
                type: double
            returnType: void
          synthetic get t3 @-1
            returnType: dynamic
          synthetic set t3 @-1
            parameters
              requiredPositional _t3 @-1
                type: dynamic
            returnType: void
''');
  }

  test_method_error_hasMethod_noParameter_required() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B extends A {
  void m(a, b) {}
}
''');
    // It's an error to add a new required parameter, but it is not a
    // top-level type inference error.
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @17
            parameters
              requiredPositional a @23
                type: int
            returnType: void
      class B @37
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @58
            parameters
              requiredPositional a @60
                type: int
              requiredPositional b @63
                type: dynamic
            returnType: void
''');
  }

  test_method_error_noCombinedSuperSignature1() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B {
  void m(String a) {}
}
class C extends A implements B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @17
            parameters
              requiredPositional a @23
                type: int
            returnType: void
      class B @37
        constructors
          synthetic @-1
        methods
          m @48
            parameters
              requiredPositional a @57
                type: String
            returnType: void
      class C @71
        supertype: A
        interfaces
          B
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @100
            typeInferenceError: overrideNoCombinedSuperSignature
            parameters
              requiredPositional a @102
                type: dynamic
            returnType: dynamic
''');
  }

  test_method_error_noCombinedSuperSignature2() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int foo(int x);
}

abstract class B {
  double foo(int x);
}

abstract class C implements A, B {
  Never foo(x);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        constructors
          synthetic @-1
        methods
          abstract foo @25
            parameters
              requiredPositional x @33
                type: int
            returnType: int
      abstract class B @55
        constructors
          synthetic @-1
        methods
          abstract foo @68
            parameters
              requiredPositional x @76
                type: int
            returnType: double
      abstract class C @98
        interfaces
          A
          B
        constructors
          synthetic @-1
        methods
          abstract foo @126
            typeInferenceError: overrideNoCombinedSuperSignature
            parameters
              requiredPositional x @130
                type: dynamic
            returnType: Never
''');
  }

  test_method_error_noCombinedSuperSignature2_legacy() async {
    var library = await _encodeDecodeLibrary(r'''
// @dart = 2.9
abstract class A {
  int foo(int x);
}

abstract class B {
  double foo(int x);
}

abstract class C implements A, B {
  Never foo(x);
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @30
        constructors
          synthetic @-1
        methods
          abstract foo @40
            parameters
              requiredPositional x @48
                type: int*
            returnType: int*
      abstract class B @70
        constructors
          synthetic @-1
        methods
          abstract foo @83
            parameters
              requiredPositional x @91
                type: int*
            returnType: double*
      abstract class C @113
        interfaces
          A*
          B*
        constructors
          synthetic @-1
        methods
          abstract foo @141
            typeInferenceError: overrideNoCombinedSuperSignature
            parameters
              requiredPositional x @145
                type: dynamic
            returnType: Null*
''');
  }

  test_method_error_noCombinedSuperSignature3() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int m() {}
}
class B {
  String m() {}
}
class C extends A implements B {
  m() {}
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @16
            returnType: int
      class B @31
        constructors
          synthetic @-1
        methods
          m @44
            returnType: String
      class C @59
        supertype: A
        interfaces
          B
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @88
            typeInferenceError: overrideNoCombinedSuperSignature
            returnType: dynamic
''');
  }

  test_method_error_noCombinedSuperSignature_generic1() async {
    var library = await _encodeDecodeLibrary(r'''
class A<T> {
  void m(T a) {}
}
class B<E> {
  void m(E a) {}
}
class C extends A<int> implements B<double> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant T @8
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @20
            parameters
              requiredPositional a @24
                type: T
            returnType: void
      class B @38
        typeParameters
          covariant E @40
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @52
            parameters
              requiredPositional a @56
                type: E
            returnType: void
      class C @70
        supertype: A<int>
        interfaces
          B<double>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {T: int}
        methods
          m @112
            typeInferenceError: overrideNoCombinedSuperSignature
            parameters
              requiredPositional a @114
                type: dynamic
            returnType: dynamic
''');
  }

  test_method_error_noCombinedSuperSignature_generic2() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> {
  T m(int a) {}
}
class C extends A<int, String> implements B<double> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant K @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @20
            parameters
              requiredPositional a @24
                type: K
            returnType: V
      class B @38
        typeParameters
          covariant T @40
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @49
            parameters
              requiredPositional a @55
                type: int
            returnType: T
      class C @69
        supertype: A<int, String>
        interfaces
          B<double>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {K: int, V: String}
        methods
          m @119
            typeInferenceError: overrideNoCombinedSuperSignature
            parameters
              requiredPositional a @121
                type: dynamic
            returnType: dynamic
''');
  }

  test_method_missing_hasMethod_noParameter_named() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B extends A {
  m(a, {b}) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @17
            parameters
              requiredPositional a @23
                type: int
            returnType: void
      class B @37
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @53
            parameters
              requiredPositional a @55
                type: int
              optionalNamed b @59
                type: dynamic
            returnType: void
''');
  }

  test_method_missing_hasMethod_noParameter_optional() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B extends A {
  m(a, [b]) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @17
            parameters
              requiredPositional a @23
                type: int
            returnType: void
      class B @37
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @53
            parameters
              requiredPositional a @55
                type: int
              optionalPositional b @59
                type: dynamic
            returnType: void
''');
  }

  test_method_missing_hasMethod_withoutTypes() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  m(a) {}
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @12
            parameters
              requiredPositional a @14
                type: dynamic
            returnType: dynamic
      class B @28
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @44
            parameters
              requiredPositional a @46
                type: dynamic
            returnType: dynamic
''');
  }

  test_method_missing_noMember() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int foo(String a) => null;
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          foo @16
            parameters
              requiredPositional a @27
                type: String
            returnType: int
      class B @47
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @63
            parameters
              requiredPositional a @65
                type: dynamic
            returnType: dynamic
''');
  }

  test_method_missing_notMethod() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int m = 42;
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        fields
          m @16
            type: int
        constructors
          synthetic @-1
        accessors
          synthetic get m @-1
            returnType: int
          synthetic set m @-1
            parameters
              requiredPositional _m @-1
                type: int
            returnType: void
      class B @32
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @48
            parameters
              requiredPositional a @50
                type: dynamic
            returnType: dynamic
''');
  }

  test_method_OK_sequence_extendsExtends_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> extends A<int, T> {}
class C extends B<String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant K @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @20
            parameters
              requiredPositional a @24
                type: K
            returnType: V
      class B @38
        typeParameters
          covariant T @40
            defaultType: dynamic
        supertype: A<int, T>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {K: int, V: T}
      class C @70
        supertype: B<String>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::B::@constructor::•
              substitution: {T: String}
        methods
          m @94
            parameters
              requiredPositional a @96
                type: int
            returnType: String
''');
  }

  test_method_OK_sequence_inferMiddle_extendsExtends() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends A {
  m(a) {}
}
class C extends B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @19
            parameters
              requiredPositional a @25
                type: int
            returnType: String
      class B @39
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @55
            parameters
              requiredPositional a @57
                type: int
            returnType: String
      class C @71
        supertype: B
        constructors
          synthetic @-1
            superConstructor: self::@class::B::@constructor::•
        methods
          m @87
            parameters
              requiredPositional a @89
                type: int
            returnType: String
''');
  }

  test_method_OK_sequence_inferMiddle_extendsImplements() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B implements A {
  m(a) {}
}
class C extends B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @19
            parameters
              requiredPositional a @25
                type: int
            returnType: String
      class B @39
        interfaces
          A
        constructors
          synthetic @-1
        methods
          m @58
            parameters
              requiredPositional a @60
                type: int
            returnType: String
      class C @74
        supertype: B
        constructors
          synthetic @-1
            superConstructor: self::@class::B::@constructor::•
        methods
          m @90
            parameters
              requiredPositional a @92
                type: int
            returnType: String
''');
  }

  test_method_OK_sequence_inferMiddle_extendsWith() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends Object with A {
  m(a) {}
}
class C extends B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @19
            parameters
              requiredPositional a @25
                type: int
            returnType: String
      class B @39
        supertype: Object
        mixins
          A
        constructors
          synthetic @-1
        methods
          m @67
            parameters
              requiredPositional a @69
                type: int
            returnType: String
      class C @83
        supertype: B
        constructors
          synthetic @-1
            superConstructor: self::@class::B::@constructor::•
        methods
          m @99
            parameters
              requiredPositional a @101
                type: int
            returnType: String
''');
  }

  test_method_OK_single_extends_direct_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a, double b) {}
}
class B extends A<int, String> {
  m(a, b) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant K @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @20
            parameters
              requiredPositional a @24
                type: K
              requiredPositional b @34
                type: double
            returnType: V
      class B @48
        supertype: A<int, String>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {K: int, V: String}
        methods
          m @77
            parameters
              requiredPositional a @79
                type: int
              requiredPositional b @82
                type: double
            returnType: String
''');
  }

  test_method_OK_single_extends_direct_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @19
            parameters
              requiredPositional a @25
                type: int
            returnType: String
      class B @39
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @55
            parameters
              requiredPositional a @57
                type: int
            returnType: String
''');
  }

  test_method_OK_single_extends_direct_notGeneric_named() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a, {double b}) {}
}
class B extends A {
  m(a, {b}) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @19
            parameters
              requiredPositional a @25
                type: int
              optionalNamed b @36
                type: double
            returnType: String
      class B @51
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @67
            parameters
              requiredPositional a @69
                type: int
              optionalNamed b @73
                type: double
            returnType: String
''');
  }

  test_method_OK_single_extends_direct_notGeneric_positional() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a, [double b]) {}
}
class B extends A {
  m(a, [b]) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @19
            parameters
              requiredPositional a @25
                type: int
              optionalPositional b @36
                type: double
            returnType: String
      class B @51
        supertype: A
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @67
            parameters
              requiredPositional a @69
                type: int
              optionalPositional b @73
                type: double
            returnType: String
''');
  }

  test_method_OK_single_extends_indirect_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> extends A<int, T> {}
class C extends B<String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant K @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @20
            parameters
              requiredPositional a @24
                type: K
            returnType: V
      class B @38
        typeParameters
          covariant T @40
            defaultType: dynamic
        supertype: A<int, T>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {K: int, V: T}
      class C @70
        supertype: B<String>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::B::@constructor::•
              substitution: {T: String}
        methods
          m @94
            parameters
              requiredPositional a @96
                type: int
            returnType: String
''');
  }

  test_method_OK_single_implements_direct_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<K, V> {
  V m(K a);
}
class B implements A<int, String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        typeParameters
          covariant K @17
            defaultType: dynamic
          covariant V @20
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          abstract m @29
            parameters
              requiredPositional a @33
                type: K
            returnType: V
      class B @45
        interfaces
          A<int, String>
        constructors
          synthetic @-1
        methods
          m @77
            parameters
              requiredPositional a @79
                type: int
            returnType: String
''');
  }

  test_method_OK_single_implements_direct_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  String m(int a);
}
class B implements A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        constructors
          synthetic @-1
        methods
          abstract m @28
            parameters
              requiredPositional a @34
                type: int
            returnType: String
      class B @46
        interfaces
          A
        constructors
          synthetic @-1
        methods
          m @65
            parameters
              requiredPositional a @67
                type: int
            returnType: String
''');
  }

  test_method_OK_single_implements_indirect_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<K, V> {
  V m(K a);
}
abstract class B<T1, T2> extends A<T2, T1> {}
class C implements B<int, String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      abstract class A @15
        typeParameters
          covariant K @17
            defaultType: dynamic
          covariant V @20
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          abstract m @29
            parameters
              requiredPositional a @33
                type: K
            returnType: V
      abstract class B @54
        typeParameters
          covariant T1 @56
            defaultType: dynamic
          covariant T2 @60
            defaultType: dynamic
        supertype: A<T2, T1>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {K: T2, V: T1}
      class C @91
        interfaces
          B<int, String>
        constructors
          synthetic @-1
        methods
          m @123
            parameters
              requiredPositional a @125
                type: String
            returnType: int
''');
  }

  test_method_OK_single_private_linkThroughOtherLibraryOfCycle() async {
    newFile('$testPackageLibPath/other.dart', r'''
import 'test.dart';
class B extends A2 {}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'other.dart';
class A1 {
  int _foo() => 1;
}
class A2 extends A1 {
  _foo() => 2;
}
''');
    checkElementText(library, r'''
library
  imports
    package:test/other.dart
  definingUnit
    classes
      class A1 @27
        constructors
          synthetic @-1
        methods
          _foo @38
            returnType: int
      class A2 @59
        supertype: A1
        constructors
          synthetic @-1
            superConstructor: self::@class::A1::@constructor::•
        methods
          _foo @77
            returnType: int
''');
  }

  test_method_OK_single_withExtends_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends Object with A {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @19
            parameters
              requiredPositional a @25
                type: int
            returnType: String
      class B @39
        supertype: Object
        mixins
          A
        constructors
          synthetic @-1
        methods
          m @67
            parameters
              requiredPositional a @69
                type: int
            returnType: String
''');
  }

  test_method_OK_two_extendsImplements_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> {
  T m(int a) {}
}
class C extends A<int, String> implements B<String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        typeParameters
          covariant K @8
            defaultType: dynamic
          covariant V @11
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @20
            parameters
              requiredPositional a @24
                type: K
            returnType: V
      class B @38
        typeParameters
          covariant T @40
            defaultType: dynamic
        constructors
          synthetic @-1
        methods
          m @49
            parameters
              requiredPositional a @55
                type: int
            returnType: T
      class C @69
        supertype: A<int, String>
        interfaces
          B<String>
        constructors
          synthetic @-1
            superConstructor: ConstructorMember
              base: self::@class::A::@constructor::•
              substitution: {K: int, V: String}
        methods
          m @119
            parameters
              requiredPositional a @121
                type: int
            returnType: String
''');
  }

  test_method_OK_two_extendsImplements_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B {
  String m(int a) {}
}
class C extends A implements B {
  m(a) {}
}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      class A @6
        constructors
          synthetic @-1
        methods
          m @19
            parameters
              requiredPositional a @25
                type: int
            returnType: String
      class B @39
        constructors
          synthetic @-1
        methods
          m @52
            parameters
              requiredPositional a @58
                type: int
            returnType: String
      class C @72
        supertype: A
        interfaces
          B
        constructors
          synthetic @-1
            superConstructor: self::@class::A::@constructor::•
        methods
          m @101
            parameters
              requiredPositional a @103
                type: int
            returnType: String
''');
  }

  Future<LibraryElement> _encodeDecodeLibrary(String text) async {
    newFile(testFilePath, text);

    var path = convertPath(testFilePath);
    var analysisSession = contextFor(path).currentSession;
    var result = await analysisSession.getUnitElement(path);
    result as UnitElementResult;
    return result.element.library;
  }
}
