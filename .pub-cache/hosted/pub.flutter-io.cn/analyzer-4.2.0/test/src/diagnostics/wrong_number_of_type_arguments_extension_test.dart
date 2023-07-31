// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfTypeArgumentsExtensionTest);
  });
}

@reflectiveTest
class WrongNumberOfTypeArgumentsExtensionTest extends PubPackageResolutionTest {
  test_notGeneric() async {
    await assertErrorsInCode(r'''
extension E on int {
  void foo() {}
}

void f() {
  E<int>(0).foo();
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION, 54, 5),
    ]);

    assertExtensionOverride(
      findNode.extensionOverride('E<int>'),
      element: findElement.extension_('E'),
      extendedType: 'int',
      typeArgumentTypes: [],
    );
  }

  test_tooFew() async {
    await assertErrorsInCode(r'''
extension E<S, T> on int {
  void foo() {}
}

void f() {
  E<bool>(0).foo();
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION, 60, 6),
    ]);

    assertExtensionOverride(
      findNode.extensionOverride('E<bool>'),
      element: findElement.extension_('E'),
      extendedType: 'int',
      typeArgumentTypes: ['dynamic', 'dynamic'],
    );
  }

  test_tooMany() async {
    await assertErrorsInCode(r'''
extension E<T> on int {
  void foo() {}
}

void f() {
  E<bool, int>(0).foo();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION, 57,
          11),
    ]);

    assertExtensionOverride(
      findNode.extensionOverride('E<bool, int>'),
      element: findElement.extension_('E'),
      extendedType: 'int',
      typeArgumentTypes: ['dynamic'],
    );
  }
}
