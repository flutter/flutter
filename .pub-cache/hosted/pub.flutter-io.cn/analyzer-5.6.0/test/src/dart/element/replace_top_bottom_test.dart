// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceTopBottomTest);
    defineReflectiveTests(ReplaceTopBottomWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ReplaceTopBottomTest extends AbstractTypeSystemTest {
  test_contravariant_bottom() {
    // Not contravariant.
    _check(neverNone, 'Never');

    void checkContravariant(DartType type, String expectedStr) {
      _check(
        functionTypeNone(returnType: intNone, parameters: [
          requiredParameter(type: type),
        ]),
        'int Function($expectedStr)',
      );
    }

    checkContravariant(neverNone, 'Object?');

    checkContravariant(
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
      'Object?',
    );
  }

  test_notContravariant_covariant_top() {
    _check(objectQuestion, 'Never');
    _check(objectStar, 'Never');
    _check(dynamicNone, 'Never');
    _check(voidNone, 'Never');

    _check(listNone(objectQuestion), 'List<Never>');
    _check(listNone(objectStar), 'List<Never>');
    _check(listNone(dynamicNone), 'List<Never>');
    _check(listNone(voidNone), 'List<Never>');

    _check(futureOrNone(objectQuestion), 'Never');
    _check(futureOrNone(objectStar), 'Never');
    _check(futureOrNone(dynamicNone), 'Never');
    _check(futureOrNone(voidNone), 'Never');
    _check(futureOrNone(futureOrNone(voidNone)), 'Never');

    _check(
      functionTypeNone(returnType: intNone, parameters: [
        requiredParameter(
          type: functionTypeNone(returnType: intNone, parameters: [
            requiredParameter(type: objectQuestion),
          ]),
        ),
      ]),
      'int Function(int Function(Never))',
      typeStr: 'int Function(int Function(Object?))',
    );

    _check(intNone, 'int');
    _check(intQuestion, 'int?');

    _check(listNone(intNone), 'List<int>');
    _check(listNone(intQuestion), 'List<int?>');
    _check(listQuestion(intNone), 'List<int>?');
    _check(listQuestion(intQuestion), 'List<int?>?');
  }

  test_notContravariant_invariant() {
    // typedef F<T> = T Function(T);
    var T = typeParameter('T', variance: Variance.invariant);
    var T_none = typeParameterTypeNone(T);
    var F = typeAlias(
      name: 'F',
      typeParameters: [T],
      aliasedType: functionTypeNone(
        returnType: T_none,
        parameters: [requiredParameter(type: T_none)],
      ),
    );

    var F_dynamic = F.instantiate(
      typeArguments: [dynamicNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    _check(F_dynamic, 'Never Function(Never)');
  }

  void _check(DartType type, String expectedStr, {String? typeStr}) {
    if (typeStr != null) {
      expect(_typeString(type), typeStr);
    }

    var result = typeSystem.replaceTopAndBottom(type);
    var resultStr = _typeString(result);
    expect(resultStr, expectedStr);
  }

  String _typeString(DartType type) {
    return type.getDisplayString(withNullability: true);
  }
}

@reflectiveTest
class ReplaceTopBottomWithoutNullSafetyTest
    extends AbstractTypeSystemWithoutNullSafetyTest {
  test_contravariant_bottom() {
    // Not contravariant.
    _check(nullStar, 'Null*');

    _check(
      functionTypeStar(returnType: intStar, parameters: [
        requiredParameter(type: nullStar),
      ]),
      'int* Function(dynamic)*',
    );
  }

  test_covariant_top() {
    _check(objectStar, 'Null*');
    _check(dynamicNone, 'Null*');
    _check(voidNone, 'Null*');

    _check(listStar(objectStar), 'List<Null*>*');
    _check(listStar(dynamicNone), 'List<Null*>*');
    _check(listStar(voidNone), 'List<Null*>*');

    _check(futureOrStar(objectStar), 'Null*');
    _check(futureOrStar(dynamicNone), 'Null*');
    _check(futureOrStar(voidNone), 'Null*');
    _check(futureOrStar(futureOrStar(voidNone)), 'Null*');

    _check(
      functionTypeStar(returnType: intStar, parameters: [
        requiredParameter(
          type: functionTypeStar(returnType: intStar, parameters: [
            requiredParameter(type: objectStar),
          ]),
        ),
      ]),
      'int* Function(int* Function(Null*)*)*',
      typeStr: 'int* Function(int* Function(Object*)*)*',
    );

    _check(intStar, 'int*');
    _check(listStar(intStar), 'List<int*>*');
  }

  void _check(DartType type, String expectedStr, {String? typeStr}) {
    if (typeStr != null) {
      expect(_typeString(type), typeStr);
    }

    var result = typeSystem.replaceTopAndBottom(type);
    var resultStr = _typeString(result);
    expect(resultStr, expectedStr);
  }

  String _typeString(DartType type) {
    return type.getDisplayString(withNullability: true);
  }
}
