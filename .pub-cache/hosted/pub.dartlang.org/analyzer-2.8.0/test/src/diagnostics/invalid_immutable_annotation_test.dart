// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidImmutableAnnotationTest);
  });
}

@reflectiveTest
class InvalidImmutableAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  const A();
}
''');
  }

  test_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @immutable
  void m() {}
}
''', [
      error(HintCode.INVALID_IMMUTABLE_ANNOTATION, 45, 10),
    ]);
  }
}
