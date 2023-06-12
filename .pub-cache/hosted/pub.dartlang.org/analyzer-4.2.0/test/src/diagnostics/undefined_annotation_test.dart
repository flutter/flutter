// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedAnnotationTest);
  });
}

@reflectiveTest
class UndefinedAnnotationTest extends PubPackageResolutionTest {
  test_identifier1_localVariable_const() async {
    await assertNoErrorsInCode(r'''
main() {
  const a = 0;
  g(@a x) {}
  g(0);
}
''');
  }

  test_unresolved_identifier() async {
    await assertErrorsInCode(r'''
@unresolved
main() {
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 0, 11),
    ]);
  }

  test_unresolved_invocation() async {
    await assertErrorsInCode(r'''
@Unresolved()
main() {
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 0, 13),
    ]);
  }

  test_unresolved_prefix() async {
    await assertErrorsInCode(r'''
@p.A(0)
class B {}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 0, 7),
    ]);
  }

  test_unresolved_prefixed() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;

@p.A(0)
class B {}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 26, 7),
    ]);
  }

  test_unresolved_prefixedIdentifier() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;
@p.unresolved
main() {
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 25, 13),
    ]);
  }

  test_useLibraryScope() async {
    await assertErrorsInCode(r'''
@foo
class A {
  static const foo = null;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 0, 4),
    ]);
  }
}
