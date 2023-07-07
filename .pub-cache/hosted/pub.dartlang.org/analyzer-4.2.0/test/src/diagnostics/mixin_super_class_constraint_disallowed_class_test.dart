// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSuperClassConstraintDisallowedClassTest);
  });
}

@reflectiveTest
class MixinSuperClassConstraintDisallowedClassTest
    extends PubPackageResolutionTest {
  test_dartCoreEnum() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {}
''');
  }

  test_dartCoreEnum_language216() async {
    await assertErrorsInCode(r'''
// @dart = 2.16
mixin M on Enum {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
          27, 4),
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, ['Enum']);

    var typeRef = findNode.namedType('Enum {}');
    assertNamedType(
      typeRef,
      findElement.importFind('dart:core').class_('Enum'),
      'Enum',
    );
  }

  test_int() async {
    await assertErrorsInCode(r'''
mixin M on int {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
          11, 3),
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, ['int']);

    var typeRef = findNode.namedType('int {}');
    assertNamedType(typeRef, intElement, 'int');
  }
}
