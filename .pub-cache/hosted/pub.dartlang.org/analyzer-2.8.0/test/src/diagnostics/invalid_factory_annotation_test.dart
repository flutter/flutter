// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFactoryAnnotationTest);
  });
}

@reflectiveTest
class InvalidFactoryAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@factory
class X {
}
''', [
      error(HintCode.INVALID_FACTORY_ANNOTATION, 33, 8),
    ]);
  }

  test_field() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class X {
  @factory
  int x = 0;
}
''', [
      error(HintCode.INVALID_FACTORY_ANNOTATION, 45, 8),
    ]);
  }

  test_topLevelFunction() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@factory
main() { }
''', [
      error(HintCode.INVALID_FACTORY_ANNOTATION, 33, 8),
    ]);
  }
}
