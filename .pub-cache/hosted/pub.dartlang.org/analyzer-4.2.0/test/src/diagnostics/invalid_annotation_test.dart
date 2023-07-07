// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAnnotationTest);
  });
}

@reflectiveTest
class InvalidAnnotationTest extends PubPackageResolutionTest {
  test_class_noUnnamedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  const A.named();
}

@A
void f() {}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 32, 2),
    ]);
  }

  test_class_staticMethod() async {
    await assertErrorsInCode(r'''
class A {
  static int foo() => 0;
}

@A.foo
void f() {}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 38, 6),
    ]);
  }

  test_class_staticMethod_arguments() async {
    await assertErrorsInCode(r'''
class A {
  static int foo() => 0;
}

@A.foo()
void f() {}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 38, 8),
    ]);
  }

  test_getter() async {
    await assertErrorsInCode(r'''
get V => 0;
@V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 12, 2),
    ]);
  }

  test_getter_importWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
get V => 0;
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 24, 4),
    ]);
  }

  test_importWithPrefix_notConstantVariable() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
final V = 0;
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 24, 4),
    ]);
  }

  test_importWithPrefix_notVariableOrConstructorInvocation() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
typedef V();
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 24, 4),
    ]);
  }

  test_localVariable_const() async {
    await assertNoErrorsInCode(r'''
void f() {
  const a = 0;
  @a
  var b; // ignore:unused_local_variable
}
''');
  }

  test_localVariable_const_withArguments() async {
    await assertErrorsInCode(r'''
void f() {
  const a = 0;
  @a(0)
  var b; // ignore:unused_local_variable
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 28, 5),
    ]);
  }

  test_localVariable_final() async {
    await assertErrorsInCode(r'''
void f() {
  final a = 0;
  @a
  var b; // ignore:unused_local_variable
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 28, 2),
    ]);
  }

  test_notClass_importWithPrefix() async {
    newFile('$testPackageLibPath/annotations.dart', r'''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);
''');
    await assertErrorsInCode('''
import 'annotations.dart' as pref;
@pref.property(123)
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 35, 19),
    ]);
  }

  test_notClass_instance() async {
    await assertErrorsInCode('''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);

@property(123)
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 116, 14),
    ]);
  }

  test_notConstantVariable() async {
    await assertErrorsInCode(r'''
final V = 0;
@V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 13, 2),
    ]);
  }

  test_notVariableOrConstructorInvocation() async {
    await assertErrorsInCode(r'''
typedef V();
@V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 13, 2),
    ]);
  }

  test_prefix_function() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;

@p.sin(0)
class B {}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 26, 9),
    ]);
  }

  test_prefix_function_unresolved() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;

@p.sin.cos(0)
class B {}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 26, 13),
    ]);
  }

  test_staticMethodReference() async {
    await assertErrorsInCode(r'''
class A {
  static f() {}
}
@A.f
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 28, 4),
    ]);
  }
}
