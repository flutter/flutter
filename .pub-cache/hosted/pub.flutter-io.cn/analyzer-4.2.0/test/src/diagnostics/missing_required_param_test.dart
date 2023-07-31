// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingRequiredParamTest);
    defineReflectiveTests(MissingRequiredParamWithoutNullSafetyTest);
  });
}

@reflectiveTest
class MissingRequiredParamTest extends PubPackageResolutionTest {
  test_annotation_noImportPrefix_named() async {
    await assertErrorsInCode(r'''
class A {
  const A.named({required int a});
}

@A.named()
void f() {}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 51, 5),
    ]);
  }

  test_annotation_noImportPrefix_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  const A({required int a});
}

@A()
void f() {}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 43, 1),
    ]);
  }

  test_annotation_withImportPrefix_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named({required int a});
}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as a;

@a.A.named()
void f() {}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 28, 5),
    ]);
  }

  test_annotation_withImportPrefix_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A({required int a});
}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as a;

@a.A()
void f() {}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 26, 1),
    ]);
  }

  test_constructor_legacy_argumentGiven() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A({required int a});
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.7
import "a.dart";

void f() {
  A(a: 0);
}
''');
  }

  test_constructor_legacy_missingArgument() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A({required int a});
}
''');
    await assertErrorsInCode(r'''
// @dart = 2.7
import "a.dart";

void f() {
  A();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 46, 1),
    ]);
  }

  test_constructor_nullSafe_argumentGiven() async {
    await assertNoErrorsInCode(r'''
class C {
  C({required int a}) {}
}

main() {
  new C(a: 2);
}
''');
  }

  test_constructor_nullSafe_missingArgument() async {
    await assertErrorsInCode(r'''
class C {
  C({required int a}) {}
}
main() {
  new C();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 52, 1),
    ]);
  }

  test_constructor_nullSafe_redirectingConstructorCall() async {
    await assertErrorsInCode(r'''
class C {
  C({required int x});
  C.named() : this();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 47, 6),
    ]);
  }

  test_constructor_nullSafe_superCall() async {
    await assertErrorsInCode(r'''
class C {
  C({required int a}) {}
}

class D extends C {
  D() : super();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 66, 7),
    ]);
  }

  test_constructor_superFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a}) : super();
}
''');
  }

  test_enumConstant_withArguments() async {
    await assertErrorsInCode(r'''
enum E {
  v();
  const E({required int a});
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 11, 1),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 11, 3),
    ]);
  }

  test_enumConstant_withoutArguments() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E({required int a});
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 11, 1),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 11, 1),
    ]);
  }

  test_function() async {
    await assertErrorsInCode(r'''
void f({required int a}) {}

main() {
  f();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 40, 1),
    ]);
  }

  test_function_call() async {
    await assertErrorsInCode(r'''
void f({required int a}) {}

main() {
  f.call();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 46, 2),
    ]);
  }

  test_function_legacy_argumentGiven() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo({required int a}) {}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.7
import "a.dart";

void f() {
  foo(a: 0);
}
''');
  }

  test_function_legacy_missingArgument() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo({required int a}) {}
''');
    await assertErrorsInCode(r'''
// @dart = 2.7
import "a.dart";

void f() {
  foo();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 46, 3),
    ]);
  }

  test_functionInvocation() async {
    await assertErrorsInCode(r'''
void Function({required int a}) f() => throw '';
g() {
  f()();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 57, 5),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
class A {
  void m({required int a}) {}
}
f() {
  new A().m();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 58, 1),
    ]);
  }

  test_method_inOtherLib() async {
    newFile('$testPackageLibPath/a_lib.dart', r'''
class A {
  void m({required int a}) {}
}
''');
    await assertErrorsInCode(r'''
import "a_lib.dart";
f() {
  new A().m();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 37, 1),
    ]);
  }

  test_method_legacy_argumentGiven() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo({required int a}) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.7
import "a.dart";

void f(A a) {
  a.foo(a: 0);
}
''');
  }

  test_method_legacy_missingArgument() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo({required int a}) {}
}
''');
    await assertErrorsInCode(r'''
// @dart = 2.7
import "a.dart";

void f(A a) {
  a.foo();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 51, 3),
    ]);
  }

  test_typedef_function() async {
    await assertErrorsInCode(r'''
String test(C c) => c.m()();

typedef String F({required String x});

class C {
  F m() => ({required String x}) => throw '';
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 20, 7),
    ]);
  }
}

@reflectiveTest
class MissingRequiredParamWithoutNullSafetyTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_constructor_argumentGiven() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C(a: 2);
}
''');
  }

  test_constructor_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  final int a;
  C({@required this.a});
}

main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 102, 1),
    ]);
  }

  test_constructor_hasReason() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  C({@Required('must specify an `a`') int a}) {}
}
main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 109, 1),
    ]);
  }

  test_constructor_noReason() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 88, 1),
    ]);
  }

  test_constructor_noReason_generic() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C<T> {
  C({@required int a}) {}
}

main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 91, 1),
    ]);
  }

  test_constructor_nullReason() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required(null) int a}) {}
}

main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 94, 1),
    ]);
  }

  test_constructor_redirectingConstructorCall() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  C({@required int x});
  C.named() : this();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 81, 6),
    ]);
  }

  test_constructor_superCall() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required('must specify an `a`') int a}) {}
}

class D extends C {
  D() : super();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 124, 7),
    ]);
  }

  test_function() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

void f({@Required('must specify an `a`') int a}) {}

main() {
  f();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 98, 1),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
f() {
  new A().m();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 115, 1),
    ]);
  }

  test_method_generic() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A<T> {
  void m<U>(U a, {@Required('must specify an `b`') int b}) {}
}
f() {
  new A<double>().m(true);
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 135, 1),
    ]);
  }

  test_method_inOtherLib() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
''');
    newFile('$testPackageLibPath/test.dart', r'''
import 'a.dart';
f() {
  new A().m();
}
''');

    await _resolveFile('$testPackageLibPath/a.dart');
    await _resolveFile('$testPackageLibPath/test.dart', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 33, 1),
    ]);
  }

  @FailingTest(reason: r'''
MISSING_REQUIRED_PARAM cannot be reported here with summary2, because
the return type of `C.m` is a structural FunctionType, which does
not know its elements, and does not know that there was a parameter
marked `@required`. There is exactly one such typedef in Flutter.
''')
  test_typedef_function() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

String test(C c) => c.m()();

typedef String F({@required String x});

class C {
  F m() => ({@required String x}) => null;
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 54, 7),
    ]);
  }

  /// Resolve the file with the given [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveFile(
    String path, [
    List<ExpectedError> expectedErrors = const [],
  ]) async {
    result = await resolveFile(convertPath(path));
    assertErrorsInResolvedUnit(result, expectedErrors);
  }
}
