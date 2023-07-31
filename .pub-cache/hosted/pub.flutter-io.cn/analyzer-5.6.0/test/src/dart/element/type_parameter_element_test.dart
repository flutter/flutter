// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterElementTest);
    defineReflectiveTests(TypeParameterTypeTest);
  });
}

@reflectiveTest
class TypeParameterElementTest extends AbstractTypeSystemTest {
  test_equal_elementElement_sameLocation() {
    var T1 = typeParameter('T');
    var T2 = typeParameter('T');
    var U = typeParameter('U');
    class_(name: 'A', typeParameters: [T1, T2, U]);

    expect(T1 == T1, isTrue);
    expect(T2 == T2, isTrue);
    expect(U == U, isTrue);

    expect(T1 == T2, isTrue);
    expect(T2 == T1, isTrue);

    expect(U == T1, isFalse);
    expect(T1 == U, isFalse);
  }

  test_equal_elementElement_synthetic() {
    var T1 = typeParameter('T');
    var T2 = typeParameter('T');
    expect(T1 == T1, isTrue);
    expect(T2 == T2, isTrue);
    expect(T1 == T2, isFalse);
    expect(T2 == T1, isFalse);
  }
}

@reflectiveTest
class TypeParameterTypeTest extends AbstractTypeSystemTest {
  test_equal_equalElements() {
    var T1 = typeParameter('T');
    var T2 = typeParameter('T');
    class_(name: 'A', typeParameters: [T1, T2]);

    _assertEqual(typeParameterTypeNone(T1), typeParameterTypeNone(T2), isTrue);
    _assertEqual(typeParameterTypeNone(T2), typeParameterTypeNone(T1), isTrue);

    _assertEqual(typeParameterTypeNone(T1), typeParameterTypeStar(T2), isFalse);
    _assertEqual(typeParameterTypeStar(T1), typeParameterTypeNone(T2), isFalse);
  }

  test_equal_equalElements_withRecursiveBounds() {
    var A = class_(name: 'A', typeParameters: [typeParameter('E')]);

    var T1 = typeParameter('T');
    T1.bound = interfaceTypeStar(A, typeArguments: [
      typeParameterTypeStar(T1),
    ]);

    var T2 = typeParameter('T');
    T2.bound = interfaceTypeStar(A, typeArguments: [
      typeParameterTypeStar(T2),
    ]);

    class_(name: 'B', typeParameters: [T1, T2]);

    _assertEqual(typeParameterTypeNone(T1), typeParameterTypeNone(T2), isTrue);
    _assertEqual(typeParameterTypeNone(T2), typeParameterTypeNone(T1), isTrue);

    _assertEqual(typeParameterTypeNone(T1), typeParameterTypeStar(T2), isFalse);
    _assertEqual(typeParameterTypeStar(T1), typeParameterTypeNone(T2), isFalse);
  }

  test_equal_sameElement_promotedBounds() {
    var T = typeParameter('T');
    class_(name: 'A', typeParameters: [T]);

    _assertEqual(
      promotedTypeParameterTypeNone(T, intNone),
      promotedTypeParameterTypeNone(T, intNone),
      isTrue,
    );

    _assertEqual(
      promotedTypeParameterTypeNone(T, intNone),
      promotedTypeParameterTypeNone(T, doubleNone),
      isFalse,
    );

    _assertEqual(
      promotedTypeParameterTypeNone(T, intNone),
      typeParameterTypeNone(T),
      isFalse,
    );

    _assertEqual(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intNone),
      isFalse,
    );
  }

  test_equal_sameElements() {
    var T = typeParameter('T');

    _assertEqual(typeParameterTypeNone(T), typeParameterTypeNone(T), isTrue);
    _assertEqual(typeParameterTypeNone(T), typeParameterTypeStar(T), isFalse);
    _assertEqual(
      typeParameterTypeNone(T),
      typeParameterTypeQuestion(T),
      isFalse,
    );

    _assertEqual(typeParameterTypeStar(T), typeParameterTypeNone(T), isFalse);
    _assertEqual(typeParameterTypeStar(T), typeParameterTypeStar(T), isTrue);
    _assertEqual(
      typeParameterTypeNone(T),
      typeParameterTypeQuestion(T),
      isFalse,
    );

    _assertEqual(
      typeParameterTypeQuestion(T),
      typeParameterTypeNone(T),
      isFalse,
    );
    _assertEqual(
      typeParameterTypeQuestion(T),
      typeParameterTypeStar(T),
      isFalse,
    );
    _assertEqual(
      typeParameterTypeQuestion(T),
      typeParameterTypeQuestion(T),
      isTrue,
    );
  }

  void _assertEqual(DartType T1, DartType T2, matcher) {
    expect(T1 == T2, matcher);
  }
}
