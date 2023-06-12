// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueInRedirectingFactoryConstructorTest);
  });
}

@reflectiveTest
class DefaultValueInRedirectingFactoryConstructorTest
    extends PubPackageResolutionTest {
  test_default_value() async {
    await assertErrorsInCode(r'''
class A {
  factory A([int x = 0]) = B;
}

class B implements A {
  B([int x = 1]) {}
}
''', [
      error(
          CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR,
          27,
          1),
    ]);
  }
}
