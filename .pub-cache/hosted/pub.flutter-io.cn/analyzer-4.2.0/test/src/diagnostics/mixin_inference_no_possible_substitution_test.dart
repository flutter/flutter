// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      MixinInferenceNoPossibleSubstitutionTest,
    );
    defineReflectiveTests(
      MixinInferenceNoPossibleSubstitutionWithoutNullSafetyTest,
    );
  });
}

@reflectiveTest
class MixinInferenceNoPossibleSubstitutionTest extends PubPackageResolutionTest
    with MixinInferenceNoPossibleSubstitutionTestCases {
  test_valid_nonNullableMixins_legacyApplication() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}

mixin B<T> on A<T> {}
mixin C<T> on A<T> {}
''');

    await assertNoErrorsInCode('''
// @dart=2.8
import 'a.dart';

class D extends A<int> with B<int>, C {}
''');

    assertType(findNode.namedType('B<int>'), 'B<int*>*');
    assertType(findNode.namedType('C {}'), 'C<int*>*');
  }
}

mixin MixinInferenceNoPossibleSubstitutionTestCases on ResolutionTest {
  test_valid_single() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

mixin M<T> on A<T> {}

class X extends A<int> with M {}
''');

    assertType(findNode.namedType('M {}'), 'M<int>');
  }
}

@reflectiveTest
class MixinInferenceNoPossibleSubstitutionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with
        WithoutNullSafetyMixin,
        MixinInferenceNoPossibleSubstitutionTestCases {}
