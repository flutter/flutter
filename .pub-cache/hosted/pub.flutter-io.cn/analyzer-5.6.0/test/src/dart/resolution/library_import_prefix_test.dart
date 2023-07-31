// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportPrefixDriverResolutionTest);
  });
}

@reflectiveTest
class ImportPrefixDriverResolutionTest extends PubPackageResolutionTest {
  test_asExpression_expressionStatement() async {
    await assertErrorsInCode(r'''
import 'dart:async' as p;

main() {
  p; // use
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 38, 1),
    ]);

    var pRef = findNode.simple('p; // use');
    assertElement(pRef, findElement.prefix('p'));
    assertTypeDynamic(pRef);
  }

  test_asExpression_forIn_iterable() async {
    await assertErrorsInCode(r'''
import 'dart:async' as p;

main() {
  for (var x in p) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 52, 1),
    ]);

    var xRef = findNode.declaredIdentifier('x in');
    expect(xRef.declaredElement, isNotNull);

    var pRef = findNode.simple('p) {}');
    assertElement(pRef, findElement.prefix('p'));
    assertTypeDynamic(pRef);
  }

  test_asExpression_instanceCreation_argument() async {
    await assertErrorsInCode(r'''
import 'dart:async' as p;

class C<T> {
  C(a);
}

main() {
  var x = new C(p);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 66, 1),
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 76, 1),
    ]);

    var pRef = findNode.simple('p);');
    assertElement(pRef, findElement.prefix('p'));
    assertTypeDynamic(pRef);
  }

  test_asPrefix_methodInvocation() async {
    await assertNoErrorsInCode(r'''
import 'dart:math' as p;

main() {
  p.max(0, 0);
}
''');

    var pRef = findNode.simple('p.max');
    assertElement(pRef, findElement.prefix('p'));
    assertTypeNull(pRef);
  }

  test_asPrefix_prefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
import 'dart:async' as p;

main() {
  p.Future;
}
''');

    var pRef = findNode.simple('p.Future');
    assertElement(pRef, findElement.prefix('p'));
    assertTypeNull(pRef);
  }
}
