// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustBeImmutableTest);
  });
}

@reflectiveTest
class MustBeImmutableTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_directAnnotation() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  int x = 0;
}
''', [
      error(HintCode.MUST_BE_IMMUTABLE, 50, 1),
    ]);
  }

  test_directMixinAnnotation() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@immutable
mixin A {
  int x = 0;
}
''', [
      error(HintCode.MUST_BE_IMMUTABLE, 50, 1),
    ]);
  }

  test_extendsClassWithAnnotation() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
class B extends A {
  int x = 0;
}
''', [
      error(HintCode.MUST_BE_IMMUTABLE, 61, 1),
    ]);
  }

  test_finalField() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  final x = 7;
}
''');
  }

  test_fromMixinWithAnnotation() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
class B {
  int x = 0;
}
class C extends A with B {}
''', [
      error(HintCode.MUST_BE_IMMUTABLE, 86, 1),
    ]);
  }

  test_mixinApplication() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
class B {
  int x = 0;
}
class C = A with B;
''', [
      error(HintCode.MUST_BE_IMMUTABLE, 86, 1),
    ]);
  }

  test_mixinApplicationBase() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  int x = 0;
}
class B {}
@immutable
class C = A with B;
''', [
      error(HintCode.MUST_BE_IMMUTABLE, 86, 1),
    ]);
  }

  test_staticField() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  static int x = 0;
}
''');
  }
}
