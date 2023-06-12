// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidSealedAnnotationTest);
  });
}

@reflectiveTest
class InvalidSealedAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@sealed class A {}
''');
  }

  test_mixin() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@sealed mixin M {}
''', [
      error(HintCode.INVALID_SEALED_ANNOTATION, 34, 7),
    ]);
  }

  test_mixinApplication() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

abstract class A {}

abstract class B {}

@sealed abstract class M = A with B;
''');
  }

  test_nonClass() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@sealed m({a = 1}) => null;
''', [
      error(HintCode.INVALID_SEALED_ANNOTATION, 34, 7),
    ]);
  }
}
