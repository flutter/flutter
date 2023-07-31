// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantDefaultValueTest);
  });
}

@reflectiveTest
class NonConstantDefaultValueTest extends PubPackageResolutionTest {
  test_appliedTypeParameter_defaultConstructorValue() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  final void Function(T) p;
  const C({this.p = f});
}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 83, 1)]);
  }

  test_appliedTypeParameter_defaultFunctionValue() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

void bar<T>([void Function(T) p = f]) {}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 56, 1)]);
  }

  test_appliedTypeParameter_defaultMethodValue() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  void foo([void Function(T) p = f]) {}
}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 68, 1)]);
  }

  test_appliedTypeParameter_nested() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

void bar<T>([void Function(List<T>) p = f]) {}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 62, 1)]);
  }

  test_appliedTypeParameter_nestedFunction() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

void bar<T>([void Function(T Function()) p = f]) {}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 67, 1)]);
  }

  test_constructor_inDifferentFile() async {
    newFile('/test/lib/a.dart', '''
import 'b.dart';
const v = const MyClass();
''');
    await assertErrorsInCode('''
class MyClass {
  const MyClass([p = foo]);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 37, 3),
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 37, 3),
    ]);
  }

  test_constructor_named() async {
    await assertErrorsInCode(r'''
class A {
  int y = 0;
  A({x = y}) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 32, 1),
    ]);
  }

  test_constructor_positional() async {
    await assertErrorsInCode(r'''
class A {
  int y = 0;
  A([x = y]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 32, 1),
    ]);
  }

  test_enum_issue49097() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const foo = A();
  static const bar = A();
  const A();
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';

enum E {
  v(f: A.foo);
  final A f;
  const E({this.f = A.bar});
}
''');
  }

  test_function_named() async {
    await assertErrorsInCode(r'''
int y = 0;
f({x = y}) {}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 18, 1),
    ]);
  }

  test_function_named_constList() async {
    await assertNoErrorsInCode(r'''
void f({x = const [0, 1]}) {}
''');
  }

  test_function_named_constList_elements_listLiteral() async {
    await assertNoErrorsInCode(r'''
void f({x = const [0, [1]]}) {}
''');
  }

  test_function_named_constRecord() async {
    await assertNoErrorsInCode(r'''
void f({x = const (0, 1)}) {}
''');
  }

  test_function_named_constRecord_namedFields_listLiteral() async {
    await assertNoErrorsInCode(r'''
void f({x = const (0, foo: [1])}) {}
''');
  }

  test_function_named_constRecord_positionalFields_listLiteral() async {
    await assertNoErrorsInCode(r'''
void f({x = const (0, [1])}) {}
''');
  }

  test_function_named_record_namedFields_integerLiteral() async {
    await assertNoErrorsInCode(r'''
void f({x = (a: 0, b: 1)}) {}
''');
  }

  test_function_named_record_namedFields_listLiteral() async {
    await assertErrorsInCode(r'''
void f({x = (a: 0, b: [1])}) {}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 22, 3),
    ]);
  }

  test_function_named_record_namedFields_listLiteral_const() async {
    await assertNoErrorsInCode(r'''
void f({x = (a: 0, b: const [1])}) {}
''');
  }

  test_function_named_record_positionalFields_integerLiteral() async {
    await assertNoErrorsInCode(r'''
void f({x = (0, 1)}) {}
''');
  }

  test_function_named_record_positionalFields_listLiteral() async {
    await assertErrorsInCode(r'''
void f({x = (0, [1])}) {}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 16, 3),
    ]);
  }

  test_function_named_record_positionalFields_listLiteral_const() async {
    await assertNoErrorsInCode(r'''
void f({x = (0, const [1])}) {}
''');
  }

  test_function_positional() async {
    await assertErrorsInCode(r'''
int y = 0;
f([x = y]) {}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 18, 1),
    ]);
  }

  test_method_named() async {
    await assertErrorsInCode(r'''
class A {
  int y = 0;
  m({x = y}) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 32, 1),
    ]);
  }

  test_method_positional() async {
    await assertErrorsInCode(r'''
class A {
  int y = 0;
  m([x = y]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 32, 1),
    ]);
  }

  test_noAppliedTypeParameters_defaultConstructorValue_dynamic() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  final dynamic p;
  const C({this.p = f});
}
''');
  }

  test_noAppliedTypeParameters_defaultConstructorValue_genericFn() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  final void Function<T>(T) p;
  const C({this.p = f});
}
''');
  }

  test_noAppliedTypeParameters_defaultFunctionValue_genericFn() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) => t;

void bar<T>([void Function<T>(T) p = f]) {}
''');
  }

  test_noAppliedTypeParameters_defaultMethodValue_genericFn() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  void foo([void Function<T>(T) p = f]) {}
}
''');
  }
}
