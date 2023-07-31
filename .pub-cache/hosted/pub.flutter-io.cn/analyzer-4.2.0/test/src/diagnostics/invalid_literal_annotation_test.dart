// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidLiteralAnnotationTest);
  });
}

@reflectiveTest
class InvalidLiteralAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_constConstructor() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
''');
  }

  test_nonConstConstructor() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  A() {}
}
''', [
      error(HintCode.INVALID_LITERAL_ANNOTATION, 45, 8),
    ]);
  }

  test_nonConstructor() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  void m() {}
}
''', [
      error(HintCode.INVALID_LITERAL_ANNOTATION, 45, 8),
    ]);
  }
}
