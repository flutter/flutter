// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantResolutionTest);
    defineReflectiveTests(ConstantResolutionWithNullSafetyTest);
  });
}

@reflectiveTest
class ConstantResolutionTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_constantValue_defaultParameter_noDefaultValue() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A({int p});
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';
const a = const A();
''');

    var aLib = findElement.import('package:test/a.dart').importedLibrary!;
    var aConstructor = aLib.getType('A')!.constructors.single;
    var p = aConstructor.parameters.single as DefaultParameterElementImpl;

    // To evaluate `const A()` we have to evaluate `{int p}`.
    // Even if its value is `null`.
    expect(p.isConstantEvaluated, isTrue);
    expect(p.computeConstantValue()!.isNull, isTrue);
  }

  test_constFactoryRedirection_super() async {
    await assertNoErrorsInCode(r'''
class I {
  const factory I(int f) = B;
}

class A implements I {
  final int f;

  const A(this.f);
}

class B extends A {
  const B(int f) : super(f);
}

@I(42)
main() {}
''');

    var node = findNode.annotation('@I');
    var value = node.elementAnnotation!.computeConstantValue()!;
    expect(value.getField('(super)')!.getField('f')!.toIntValue(), 42);
  }

  test_constNotInitialized() async {
    await assertErrorsInCode(r'''
class B {
  const B(_);
}

class C extends B {
  static const a;
  const C() : super(a);
}
''', [
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 62, 1),
    ]);
  }

  test_context_eliminateTypeVariables() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A({List<T> a = const []});
}
''');
    assertType(findNode.listLiteral('const []'), 'List<Null>');
  }

  test_context_eliminateTypeVariables_functionType() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  const A({List<T Function(U)> a = const []});
}
''');
    assertType(
      findNode.listLiteral('const []'),
      'List<Null Function(Object)>',
    );
  }

  test_functionType_element_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F<T> = T Function(int);
const a = C<F<double>>();

class C<T> {
  const C();
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';

const v = a;
''');

    var v = findElement.topVar('v') as ConstVariableElement;
    var value = v.computeConstantValue()!;

    var type = value.type as InterfaceType;
    assertType(type, 'C<double Function(int)>');

    expect(type.typeArguments, hasLength(1));
    var typeArgument = type.typeArguments[0] as FunctionType;
    assertType(typeArgument, 'double Function(int)');

    // The element and type arguments are available for the function type.
    var importFind = findElement.importFind('package:test/a.dart');
    var alias = importFind.typeAlias('F');
    assertTypeAlias(typeArgument, element: alias, typeArguments: ['double']);
  }

  test_imported_prefixedIdentifier_staticField_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const a = C.f;

class C {
  static const int f = 42;
}
''');
    await resolveTestCode(r'''
import 'a.dart';
''');

    var import_ = findElement.importFind('package:test/a.dart');
    var a = import_.topVar('a') as ConstVariableElement;
    expect(a.computeConstantValue()!.toIntValue(), 42);
  }

  test_imported_prefixedIdentifier_staticField_extension() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const a = E.f;

extension E on int {
  static const int f = 42;
}
''');
    await resolveTestCode(r'''
import 'a.dart';
''');

    var import_ = findElement.importFind('package:test/a.dart');
    var a = import_.topVar('a') as ConstVariableElement;
    expect(a.computeConstantValue()!.toIntValue(), 42);
  }

  test_imported_prefixedIdentifier_staticField_mixin() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const a = M.f;

class C {}

mixin M on C {
  static const int f = 42;
}
''');
    await resolveTestCode(r'''
import 'a.dart';
''');

    var import_ = findElement.importFind('package:test/a.dart');
    var a = import_.topVar('a') as ConstVariableElement;
    expect(a.computeConstantValue()!.toIntValue(), 42);
  }

  test_imported_super_defaultFieldFormalParameter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
import 'test.dart';

class A {
  static const B b = const B();

  final bool f1;
  final bool f2;

  const A({this.f1: false}) : this.f2 = f1 && true;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

class B extends A {
  const B() : super();
}
''');

    result = await resolveFile(convertPath('$testPackageLibPath/a.dart'));
    assertErrorsInResolvedUnit(result, []);

    var bElement = FindElement(result.unit).field('b') as ConstVariableElement;
    var bValue = bElement.evaluationResult!.value!;
    var superFields = bValue.getField(GenericState.SUPERCLASS_FIELD);
    expect(superFields!.getField('f1')!.toBoolValue(), false);
  }

  test_local_prefixedIdentifier_staticField_extension() async {
    await assertNoErrorsInCode(r'''
const a = E.f;

extension E on int {
  static const int f = 42;
}
''');
    var a = findElement.topVar('a') as ConstVariableElement;
    expect(a.computeConstantValue()!.toIntValue(), 42);
  }

  /// See https://github.com/dart-lang/sdk/issues/43462
  test_useLanguageVersionOfEnclosingLibrary() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class Wrapper {
  final int value;
  const Wrapper(Object value) : value = value as int;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.4
import 'a.dart';

void f() {
  const Wrapper(0);
}
''');
  }
}

@reflectiveTest
class ConstantResolutionWithNullSafetyTest extends PubPackageResolutionTest {
  test_constructor_nullSafe_fromLegacy_super() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A(List<Object> a);
}

class B extends A {
  const B(List<Object> a) : super(a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.8
import 'a.dart';

const a = <dynamic>[];
const b = B(a);
''');

    var b = findElement.topVar('b');
    assertType(b.computeConstantValue()!.type, 'B*');
  }

  test_constructor_nullSafe_fromLegacy_this() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A(List<Object> a) : this(a);
  const A.second(List<Object> a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.8
import 'a.dart';

const a = <dynamic>[];
const b = A(a);
''');

    var b = findElement.topVar('b');
    assertType(b.computeConstantValue()!.type, 'A*');
  }

  test_context_eliminateTypeVariables() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A({List<T> a = const []});
}
''');
    assertType(findNode.listLiteral('const []'), 'List<Never>');
  }

  test_context_eliminateTypeVariables_functionType() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  const A({List<T Function(U)> a = const []});
}
''');
    assertType(
      findNode.listLiteral('const []'),
      'List<Never Function(Object?)>',
    );
  }

  test_field_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static const foo = 42;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

const bar = A.foo;
''');

    var bar = findElement.topVar('bar');
    _assertIntValue(bar, 42);
  }

  test_fromEnvironment_optOut_fromOptIn() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.5

const cBool = const bool.fromEnvironment('foo', defaultValue: false);
const cInt = const int.fromEnvironment('foo', defaultValue: 1);
const cString = const String.fromEnvironment('foo', defaultValue: 'bar');
''');

    await assertErrorsInCode(r'''
import 'a.dart';

const vBool = cBool;
const vInt = cInt;
const vString = cString;
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    DartObjectImpl evaluate(String name) {
      return findElement.topVar(name).computeConstantValue() as DartObjectImpl;
    }

    expect(evaluate('vBool').toBoolValue(), false);
    expect(evaluate('vInt').toIntValue(), 1);
    expect(evaluate('vString').toStringValue(), 'bar');
  }

  test_topLevelVariable_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const foo = 42;
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

const bar = foo;
''');

    var bar = findElement.topVar('bar');
    assertType(bar.type, 'int*');
    _assertIntValue(bar, 42);
  }

  test_topLevelVariable_optOut2() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const a = 42;
''');

    newFile('$testPackageLibPath/b.dart', content: r'''
import 'a.dart';

const b = a;
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'b.dart';

const c = b;
''');

    var c = findElement.topVar('c');
    assertType(c.type, 'int*');
    _assertIntValue(c, 42);
  }

  test_topLevelVariable_optOut3() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
const a = int.fromEnvironment('a', defaultValue: 42);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

const b = a;
''');

    var c = findElement.topVar('b');
    assertType(c.type, 'int*');
    _assertIntValue(c, 42);
  }

  void _assertIntValue(VariableElement element, int value) {
    expect(element.computeConstantValue()!.toIntValue(), value);
  }
}
