// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldFormalParameterResolutionTest);
  });
}

@reflectiveTest
class FieldFormalParameterResolutionTest extends PubPackageResolutionTest {
  /// There was a crash.
  /// https://github.com/dart-lang/sdk/issues/46968
  test_class_hasTypeParameters() async {
    await assertNoErrorsInCode(r'''
class A {
  T Function<T>(T) f;
  A(U this.f<U>(U a));
}
''');
  }

  test_enum() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(0);
  final int f;
  const E(this.f);
}
''');

    final node = findNode.fieldFormalParameter('this.f');
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: f
  declaredElement: self::@enum::E::@constructor::new::@parameter::f
  declaredElementType: int
''');
  }
}
