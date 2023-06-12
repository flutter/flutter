// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeTest);
    defineReflectiveTests(SubtypingCompoundTest);
  });
}

@reflectiveTest
class SubtypeTest extends _SubtypingTestBase {
  final Map<String, DartType> _types = {};

  void assertExpectedString(DartType type, String? expectedString) {
    if (expectedString != null) {
      var typeStr = _typeStr(type);

      typeStr += _typeParametersStr(type);

      expect(typeStr, expectedString);
    }
  }

  void isNotSubtype(
    DartType T0,
    DartType T1, {
    required String strT0,
    required String strT1,
  }) {
    assertExpectedString(T0, strT0);
    assertExpectedString(T1, strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isFalse);
  }

  void isNotSubtype2(
    String strT0,
    String strT1,
  ) {
    var T0 = _getTypeByStr(strT0);
    var T1 = _getTypeByStr(strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isFalse);
  }

  void isNotSubtype3({
    required String strT0,
    required String strT1,
  }) {
    isNotSubtype2(strT0, strT1);
  }

  void isSubtype(
    DartType T0,
    DartType T1, {
    String? strT0,
    String? strT1,
  }) {
    assertExpectedString(T0, strT0);
    assertExpectedString(T1, strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isTrue);
  }

  void isSubtype2(
    String strT0,
    String strT1,
  ) {
    var T0 = _getTypeByStr(strT0);
    var T1 = _getTypeByStr(strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isTrue);
  }

  @override
  void setUp() {
    super.setUp();
    _defineTypes();
  }

  test_functionType_01() {
    var E0 = typeParameter('E0');
    var E1 = typeParameter('E1', bound: numStar);

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: numStar),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0 Function<E0>(E0, num*)*',
      strT1: 'E1* Function<E1 extends num*>(E1*, E1*)*',
    );
  }

  test_functionType_02() {
    var E0 = typeParameter('E0', bound: numStar);
    var E1 = typeParameter('E1', bound: intStar);

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function<E0 extends num*>(E0*)*',
      strT1: 'int* Function<E1 extends int*>(E1*)*',
    );
  }

  test_functionType_03() {
    var E0 = typeParameter('E0', bound: numStar);
    var E1 = typeParameter('E1', bound: intStar);

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0 extends num*>(E0*)*',
      strT1: 'E1* Function<E1 extends int*>(E1*)*',
    );
  }

  test_functionType_04() {
    var E0 = typeParameter('E0', bound: numStar);
    var E1 = typeParameter('E1', bound: intStar);

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0 extends num*>(int*)*',
      strT1: 'E1* Function<E1 extends int*>(int*)*',
    );
  }

  test_functionType_05() {
    var E0 = typeParameter('E0', bound: numStar);
    var E1 = typeParameter('E1', bound: numStar);

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: numStar,
      ),
      strT0: 'E0* Function<E0 extends num*>(E0*)*',
      strT1: 'num* Function<E1 extends num*>(E1*)*',
    );
  }

  test_functionType_06() {
    var E0 = typeParameter('E0', bound: intStar);
    var E1 = typeParameter('E1', bound: intStar);

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: numStar,
      ),
      strT0: 'E0* Function<E0 extends int*>(E0*)*',
      strT1: 'num* Function<E1 extends int*>(E1*)*',
    );
  }

  test_functionType_07() {
    var E0 = typeParameter('E0', bound: intStar);
    var E1 = typeParameter('E1', bound: intStar);

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: intStar,
      ),
      strT0: 'E0* Function<E0 extends int*>(E0*)*',
      strT1: 'int* Function<E1 extends int*>(E1*)*',
    );
  }

  test_functionType_08() {
    var E0 = typeParameter('E0');

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function<E0>(int*)*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_09() {
    var E0 = typeParameter('E0');
    var F0 = typeParameter('F0');
    var E1 = typeParameter('E1');

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0, F0],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function<E0, F0>(int*)*',
      strT1: 'int* Function<E1>(int*)*',
    );
  }

  test_functionType_10() {
    var E0 = typeParameter('E0');
    E0.bound = listStar(
      typeParameterTypeStar(E0),
    );

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0 extends List<E0*>*>(E0*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*)*',
    );
  }

  test_functionType_11() {
    var E0 = typeParameter('E0');
    E0.bound = iterableStar(
      typeParameterTypeStar(E0),
    );

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0 extends Iterable<E0*>*>(E0*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*)*',
    );
  }

  test_functionType_12() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listStar(objectStar)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0>(E0, List<Object*>*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*, E1*)*',
    );
  }

  test_functionType_13() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listStar(objectStar)),
        ],
        returnType: listStar(
          typeParameterTypeNone(E0),
        ),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'List<E0>* Function<E0>(E0, List<Object*>*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*, E1*)*',
    );
  }

  test_functionType_14() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listStar(objectStar)),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'int* Function<E0>(E0, List<Object*>*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*, E1*)*',
    );
  }

  test_functionType_15() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listStar(objectStar)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: voidNone,
      ),
      strT0: 'E0 Function<E0>(E0, List<Object*>*)*',
      strT1: 'void Function<E1 extends List<E1*>*>(E1*, E1*)*',
    );
  }

  test_functionType_16() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionStar,
      strT0: 'int* Function()*',
      strT1: 'Function*',
    );
  }

  test_functionType_17() {
    isNotSubtype(
      functionStar,
      functionTypeStar(
        returnType: intStar,
      ),
      strT0: 'Function*',
      strT1: 'int* Function()*',
    );
  }

  test_functionType_18() {
    isSubtype(
      functionTypeStar(
        returnType: dynamicNone,
      ),
      functionTypeStar(
        returnType: dynamicNone,
      ),
      strT0: 'dynamic Function()*',
      strT1: 'dynamic Function()*',
    );
  }

  test_functionType_19() {
    isSubtype(
      functionTypeStar(
        returnType: dynamicNone,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'dynamic Function()*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_20() {
    isSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: dynamicNone,
      ),
      strT0: 'void Function()*',
      strT1: 'dynamic Function()*',
    );
  }

  test_functionType_21() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'int* Function()*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_22() {
    isNotSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: intStar,
      ),
      strT0: 'void Function()*',
      strT1: 'int* Function()*',
    );
  }

  test_functionType_23() {
    isSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'void Function()*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_24() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        returnType: intStar,
      ),
      strT0: 'int* Function()*',
      strT1: 'int* Function()*',
    );
  }

  test_functionType_25() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        returnType: objectStar,
      ),
      strT0: 'int* Function()*',
      strT1: 'Object* Function()*',
    );
  }

  test_functionType_26() {
    isNotSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        returnType: doubleStar,
      ),
      strT0: 'int* Function()*',
      strT1: 'double* Function()*',
    );
  }

  test_functionType_27() {
    isNotSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'int* Function()*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_28() {
    isNotSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'void Function()*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_29() {
    isNotSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function()*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_30() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function(int*)*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_31() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: objectStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: objectStar,
      ),
      strT0: 'int* Function(Object*)*',
      strT1: 'Object* Function(int*)*',
    );
  }

  test_functionType_32() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: doubleStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function(int*)*',
      strT1: 'int* Function(double*)*',
    );
  }

  test_functionType_33() {
    isNotSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function()*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_34() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function(int*)*',
      strT1: 'int* Function(int*, int*)*',
    );
  }

  test_functionType_35() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function(int*, int*)*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_36() {
    var f = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    var g = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: intStar),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );

    isNotSubtype(
      f,
      g,
      strT0: 'void Function(void Function()*)*',
      strT1: 'void Function(void Function(int*)*)*',
    );

    isNotSubtype(
      g,
      f,
      strT0: 'void Function(void Function(int*)*)*',
      strT1: 'void Function(void Function()*)*',
    );
  }

  test_functionType_37() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_38() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_39() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*)*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_40() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_41() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: objectStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([Object*])*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_42() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: objectStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function([Object*])*',
    );
  }

  test_functionType_43() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*, [int*])*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_44() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*, [int*])*',
      strT1: 'void Function(int*, [int*])*',
    );
  }

  test_functionType_45() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*])*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_46() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*])*',
      strT1: 'void Function(int*, [int*])*',
    );
  }

  test_functionType_47() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*])*',
      strT1: 'void Function(int*, [int*, int*])*',
    );
  }

  test_functionType_48() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*, int*])*',
      strT1: 'void Function(int*, [int*, int*])*',
    );
  }

  test_functionType_49() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: doubleStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function(double*)*',
    );
  }

  test_functionType_50() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function([int*, int*])*',
    );
  }

  test_functionType_51() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*])*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_52() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: objectStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([Object*, int*])*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_53() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a})*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_54() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a})*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_55() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*)*',
      strT1: 'void Function({int* a})*',
    );
  }

  test_functionType_56() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a})*',
      strT1: 'void Function({int* a})*',
    );
  }

  test_functionType_57() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'b', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a})*',
      strT1: 'void Function({int* b})*',
    );
  }

  test_functionType_58() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: objectStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({Object* a})*',
      strT1: 'void Function({int* a})*',
    );
  }

  test_functionType_59() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: objectStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a})*',
      strT1: 'void Function({Object* a})*',
    );
  }

  test_functionType_60() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*, {int* a})*',
      strT1: 'void Function(int*, {int* a})*',
    );
  }

  test_functionType_61() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: doubleStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a})*',
      strT1: 'void Function({double* a})*',
    );
  }

  test_functionType_62() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a})*',
      strT1: 'void Function({int* a, int* b})*',
    );
  }

  test_functionType_63() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a, int* b})*',
      strT1: 'void Function({int* a})*',
    );
  }

  test_functionType_64() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a, int* b, int* c})*',
      strT1: 'void Function({int* a, int* c})*',
    );
  }

  test_functionType_66() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a, int* b, int* c})*',
      strT1: 'void Function({int* b, int* c})*',
    );
  }

  test_functionType_68() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int* a, int* b, int* c})*',
      strT1: 'void Function({int* c})*',
    );
  }

  test_functionType_70() {
    isSubtype(
      functionTypeNone(
        returnType: numStar,
        parameters: [
          requiredParameter(type: intStar),
        ],
      ),
      objectNone,
      strT0: 'num* Function(int*)',
      strT1: 'Object',
    );
  }

  test_functionType_71() {
    isSubtype(
      functionTypeStar(
        returnType: numStar,
        parameters: [
          requiredParameter(type: intStar),
        ],
      ),
      objectNone,
      strT0: 'num* Function(int*)*',
      strT1: 'Object',
    );
  }

  test_functionType_72() {
    isNotSubtype(
      functionTypeQuestion(
        returnType: numStar,
        parameters: [
          requiredParameter(type: intStar),
        ],
      ),
      objectNone,
      strT0: 'num* Function(int*)?',
      strT1: 'Object',
    );
  }

  test_functionType_73() {
    var E0 = typeParameter('E0', bound: objectNone);
    var E1 = typeParameter('E1', bound: futureOrNone(objectNone));

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        returnType: voidNone,
      ),
      functionTypeNone(
        typeFormals: [E1],
        returnType: voidNone,
      ),
      strT0: 'void Function<E0 extends Object>()',
      strT1: 'void Function<E1 extends FutureOr<Object>>()',
    );
  }

  test_functionType_generic_nested() {
    var E0 = typeParameter('E0');
    var F0 = typeParameter('F0');
    var E1 = typeParameter('E1');
    var F1 = typeParameter('F1');

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(E0)),
          ],
          returnType: typeParameterTypeNone(E0),
        ),
      ),
      functionTypeStar(
        typeFormals: [F1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(F1)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F1)),
          ],
          returnType: typeParameterTypeNone(F1),
        ),
      ),
      strT0: 'E0 Function(E0)* Function<E0>(E0)*',
      strT1: 'F1 Function(F1)* Function<F1>(F1)*',
    );

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(
            type: functionTypeStar(
              parameters: [
                requiredParameter(type: intStar),
                requiredParameter(type: typeParameterTypeNone(E0)),
              ],
              returnType: typeParameterTypeNone(E0),
            ),
          ),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(
            type: functionTypeStar(
              parameters: [
                requiredParameter(type: numStar),
                requiredParameter(type: typeParameterTypeNone(E1)),
              ],
              returnType: typeParameterTypeNone(E1),
            ),
          ),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E0 Function<E0>(E0, E0 Function(int*, E0)*)*',
      strT1: 'E1 Function<E1>(E1, E1 Function(num*, E1)*)*',
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0, F0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F0)),
          ],
          returnType: typeParameterTypeNone(E0),
        ),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: functionTypeStar(
          typeFormals: [F1],
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F1)),
          ],
          returnType: typeParameterTypeNone(E1),
        ),
      ),
      strT0: 'E0 Function(F0)* Function<E0, F0>(E0)*',
      strT1: 'E1 Function<F1>(F1)* Function<E1>(E1)*',
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0, F0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F0)),
          ],
          returnType: typeParameterTypeNone(E0),
        ),
      ),
      functionTypeStar(
        typeFormals: [F1, E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F1)),
          ],
          returnType: typeParameterTypeNone(E1),
        ),
      ),
      strT0: 'E0 Function(F0)* Function<E0, F0>(E0)*',
      strT1: 'E1 Function(F1)* Function<F1, E1>(E1)*',
    );
  }

  test_functionType_generic_required() {
    var E0 = typeParameter('E');
    var E1 = typeParameter('E');

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function<E>(E)*',
      strT1: 'num* Function<E>(E)*',
    );

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E Function<E>(num*)*',
      strT1: 'E Function<E>(int*)*',
    );

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: numStar),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: intStar),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E Function<E>(E, num*)*',
      strT1: 'E Function<E>(E, int*)*',
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: numStar),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E Function<E>(E, num*)*',
      strT1: 'E Function<E>(E, E)*',
    );
  }

  test_functionType_notGeneric_functionReturnType() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: numStar),
          ],
          returnType: numStar,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: intStar),
          ],
          returnType: numStar,
        ),
      ),
      strT0: 'num* Function(num*)* Function(num*)*',
      strT1: 'num* Function(int*)* Function(num*)*',
    );

    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: intStar),
          ],
          returnType: intStar,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: numStar),
          ],
          returnType: numStar,
        ),
      ),
      strT0: 'int* Function(int*)* Function(int*)*',
      strT1: 'num* Function(num*)* Function(num*)*',
    );
  }

  test_functionType_notGeneric_named() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: numStar,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'num* Function({num* x})*',
      strT1: 'num* Function({int* x})*',
    );

    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: numStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          namedParameter(name: 'x', type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'num* Function(num*, {num* x})*',
      strT1: 'num* Function(int*, {int* x})*',
    );

    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function({num* x})*',
      strT1: 'num* Function({num* x})*',
    );

    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function({int* x})*',
      strT1: 'num* Function({num* x})*',
    );
  }

  test_functionType_notGeneric_required() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: numStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'num* Function(num*)*',
      strT1: 'num* Function(int*)*',
    );

    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function(num*)*',
      strT1: 'num* Function(num*)*',
    );

    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function(num*)*',
      strT1: 'num* Function(int*)*',
    );

    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function(int*)*',
      strT1: 'num* Function(num*)*',
    );

    isSubtype(
      nullQuestion,
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'Null?',
      strT1: 'num* Function(int*)*',
    );
  }

  test_functionType_requiredNamedParameter_01() {
    var F0 = functionTypeNone(
      returnType: voidNone,
      parameters: [
        namedRequiredParameter(name: 'a', type: intNone),
      ],
    );

    var F1 = functionTypeNone(
      returnType: voidNone,
      parameters: [
        namedParameter(name: 'a', type: intNone),
      ],
    );

    isSubtype(
      F1,
      F0,
      strT0: 'void Function({int a})',
      strT1: 'void Function({required int a})',
    );

    isNotSubtype(
      F0,
      F1,
      strT0: 'void Function({required int a})',
      strT1: 'void Function({int a})',
    );
  }

  test_functionType_requiredNamedParameter_02() {
    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'void Function({required int a})',
      strT1: 'void Function()',
    );

    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
          namedParameter(name: 'b', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'b', type: intNone),
        ],
      ),
      strT0: 'void Function({required int a, int b})',
      strT1: 'void Function({int b})',
    );
  }

  test_functionType_requiredNamedParameter_03() {
    var F0 = functionTypeStar(
      returnType: voidNone,
      parameters: [
        namedParameter(name: 'a', type: intStar),
      ],
    );

    var F1 = functionTypeNone(
      returnType: voidNone,
      parameters: [
        namedRequiredParameter(name: 'a', type: intNone),
      ],
    );

    isSubtype(
      F0,
      F1,
      strT0: 'void Function({int* a})*',
      strT1: 'void Function({required int a})',
    );

    isSubtype(
      F1,
      F0,
      strT0: 'void Function({required int a})',
      strT1: 'void Function({int* a})*',
    );
  }

  test_futureOr_01() {
    isSubtype(
      intStar,
      futureOrStar(intStar),
      strT0: 'int*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_02() {
    isSubtype(
      intStar,
      futureOrStar(numStar),
      strT0: 'int*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_03() {
    isSubtype(
      futureStar(intStar),
      futureOrStar(intStar),
      strT0: 'Future<int*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_04() {
    isSubtype(
      futureStar(intStar),
      futureOrStar(numStar),
      strT0: 'Future<int*>*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_05() {
    isSubtype(
      futureStar(intStar),
      futureOrStar(objectStar),
      strT0: 'Future<int*>*',
      strT1: 'FutureOr<Object*>*',
    );
  }

  test_futureOr_06() {
    isSubtype(
      futureOrStar(intStar),
      futureOrStar(intStar),
      strT0: 'FutureOr<int*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_07() {
    isSubtype(
      futureOrStar(intStar),
      futureOrStar(numStar),
      strT0: 'FutureOr<int*>*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_08() {
    isSubtype(
      futureOrStar(intStar),
      objectStar,
      strT0: 'FutureOr<int*>*',
      strT1: 'Object*',
    );
  }

  test_futureOr_09() {
    isNotSubtype(
      intStar,
      futureOrStar(doubleStar),
      strT0: 'int*',
      strT1: 'FutureOr<double*>*',
    );
  }

  test_futureOr_10() {
    isNotSubtype(
      futureOrStar(doubleStar),
      intStar,
      strT0: 'FutureOr<double*>*',
      strT1: 'int*',
    );
  }

  test_futureOr_11() {
    isNotSubtype(
      futureOrStar(intStar),
      futureStar(numStar),
      strT0: 'FutureOr<int*>*',
      strT1: 'Future<num*>*',
    );
  }

  test_futureOr_12() {
    isNotSubtype(
      futureOrStar(intStar),
      numStar,
      strT0: 'FutureOr<int*>*',
      strT1: 'num*',
    );
  }

  test_futureOr_13() {
    isSubtype(
      nullQuestion,
      futureOrStar(intStar),
      strT0: 'Null?',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_14() {
    isSubtype(
      nullQuestion,
      futureStar(intStar),
      strT0: 'Null?',
      strT1: 'Future<int*>*',
    );
  }

  test_futureOr_15() {
    isSubtype(
      dynamicNone,
      futureOrStar(dynamicNone),
      strT0: 'dynamic',
      strT1: 'FutureOr<dynamic>*',
    );
  }

  test_futureOr_16() {
    isNotSubtype(
      dynamicNone,
      futureOrStar(stringStar),
      strT0: 'dynamic',
      strT1: 'FutureOr<String*>*',
    );
  }

  test_futureOr_17() {
    isSubtype(
      voidNone,
      futureOrStar(voidNone),
      strT0: 'void',
      strT1: 'FutureOr<void>*',
    );
  }

  test_futureOr_18() {
    isNotSubtype(
      voidNone,
      futureOrStar(stringStar),
      strT0: 'void',
      strT1: 'FutureOr<String*>*',
    );
  }

  test_futureOr_19() {
    var E = typeParameter('E');

    isSubtype(
      typeParameterTypeNone(E),
      futureOrStar(
        typeParameterTypeNone(E),
      ),
      strT0: 'E',
      strT1: 'FutureOr<E>*',
    );
  }

  test_futureOr_20() {
    var E = typeParameter('E');

    isNotSubtype(
      typeParameterTypeNone(E),
      futureOrStar(stringStar),
      strT0: 'E',
      strT1: 'FutureOr<String*>*',
    );
  }

  test_futureOr_21() {
    isSubtype(
      functionTypeStar(
        parameters: const [],
        returnType: stringStar,
      ),
      futureOrStar(
        functionTypeStar(
          parameters: const [],
          returnType: voidNone,
        ),
      ),
      strT0: 'String* Function()*',
      strT1: 'FutureOr<void Function()*>*',
    );
  }

  test_futureOr_22() {
    isNotSubtype(
      functionTypeStar(
        parameters: const [],
        returnType: voidNone,
      ),
      futureOrStar(
        functionTypeStar(
          parameters: const [],
          returnType: stringStar,
        ),
      ),
      strT0: 'void Function()*',
      strT1: 'FutureOr<String* Function()*>*',
    );
  }

  test_futureOr_23() {
    isNotSubtype(
      futureOrStar(numStar),
      futureOrStar(intStar),
      strT0: 'FutureOr<num*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_24() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intStar),
      futureOrStar(numStar),
      strT0: 'T & int*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_25() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, futureStar(numStar)),
      futureOrStar(numStar),
      strT0: 'T & Future<num*>*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_26() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, futureStar(intStar)),
      futureOrStar(numStar),
      strT0: 'T & Future<int*>*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_27() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, numStar),
      futureOrStar(intStar),
      strT0: 'T & num*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_28() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureStar(numStar)),
      futureOrStar(intStar),
      strT0: 'T & Future<num*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_29() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureOrStar(numStar)),
      futureOrStar(intStar),
      strT0: 'T & FutureOr<num*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_30() {
    isSubtype(
      futureOrStar(objectStar),
      futureOrStar(
        futureOrStar(objectStar),
      ),
      strT0: 'FutureOr<Object*>*',
      strT1: 'FutureOr<FutureOr<Object*>*>*',
    );
  }

  test_interfaceType_01() {
    isSubtype(intStar, intStar, strT0: 'int*', strT1: 'int*');
  }

  test_interfaceType_02() {
    isSubtype(intStar, numStar, strT0: 'int*', strT1: 'num*');
  }

  test_interfaceType_03() {
    isSubtype(
      intStar,
      comparableStar(numStar),
      strT0: 'int*',
      strT1: 'Comparable<num*>*',
    );
  }

  test_interfaceType_04() {
    isSubtype(intStar, objectStar, strT0: 'int*', strT1: 'Object*');
  }

  test_interfaceType_05() {
    isSubtype(doubleStar, numStar, strT0: 'double*', strT1: 'num*');
  }

  test_interfaceType_06() {
    isNotSubtype(intStar, doubleStar, strT0: 'int*', strT1: 'double*');
  }

  test_interfaceType_07() {
    isNotSubtype(
      intStar,
      comparableStar(intStar),
      strT0: 'int*',
      strT1: 'Comparable<int*>*',
    );
  }

  test_interfaceType_08() {
    isNotSubtype(
      intStar,
      iterableStar(intStar),
      strT0: 'int*',
      strT1: 'Iterable<int*>*',
    );
  }

  test_interfaceType_09() {
    isNotSubtype(
      comparableStar(intStar),
      iterableStar(intStar),
      strT0: 'Comparable<int*>*',
      strT1: 'Iterable<int*>*',
    );
  }

  test_interfaceType_10() {
    isSubtype(
      listStar(intStar),
      listStar(intStar),
      strT0: 'List<int*>*',
      strT1: 'List<int*>*',
    );
  }

  test_interfaceType_11() {
    isSubtype(
      listStar(intStar),
      iterableStar(intStar),
      strT0: 'List<int*>*',
      strT1: 'Iterable<int*>*',
    );
  }

  test_interfaceType_12() {
    isSubtype(
      listStar(intStar),
      listStar(numStar),
      strT0: 'List<int*>*',
      strT1: 'List<num*>*',
    );
  }

  test_interfaceType_13() {
    isSubtype(
      listStar(intStar),
      iterableStar(numStar),
      strT0: 'List<int*>*',
      strT1: 'Iterable<num*>*',
    );
  }

  test_interfaceType_14() {
    isSubtype(
      listStar(intStar),
      listStar(objectStar),
      strT0: 'List<int*>*',
      strT1: 'List<Object*>*',
    );
  }

  test_interfaceType_15() {
    isSubtype(
      listStar(intStar),
      iterableStar(objectStar),
      strT0: 'List<int*>*',
      strT1: 'Iterable<Object*>*',
    );
  }

  test_interfaceType_16() {
    isSubtype(
      listStar(intStar),
      objectStar,
      strT0: 'List<int*>*',
      strT1: 'Object*',
    );
  }

  test_interfaceType_17() {
    isSubtype(
      listStar(intStar),
      listStar(
        comparableStar(objectStar),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<Object*>*>*',
    );
  }

  test_interfaceType_18() {
    isSubtype(
      listStar(intStar),
      listStar(
        comparableStar(numStar),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<num*>*>*',
    );
  }

  test_interfaceType_19() {
    isSubtype(
      listStar(intStar),
      listStar(
        comparableStar(
          comparableStar(numStar),
        ),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<Comparable<num*>*>*>*',
    );
  }

  test_interfaceType_20() {
    isNotSubtype(
      listStar(intStar),
      listStar(doubleStar),
      strT0: 'List<int*>*',
      strT1: 'List<double*>*',
    );
  }

  test_interfaceType_21() {
    isNotSubtype(
      listStar(intStar),
      iterableStar(doubleStar),
      strT0: 'List<int*>*',
      strT1: 'Iterable<double*>*',
    );
  }

  test_interfaceType_22() {
    isNotSubtype(
      listStar(intStar),
      comparableStar(intStar),
      strT0: 'List<int*>*',
      strT1: 'Comparable<int*>*',
    );
  }

  test_interfaceType_23() {
    isNotSubtype(
      listStar(intStar),
      listStar(
        comparableStar(intStar),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<int*>*>*',
    );
  }

  test_interfaceType_24() {
    isNotSubtype(
      listStar(intStar),
      listStar(
        comparableStar(
          comparableStar(intStar),
        ),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<Comparable<int*>*>*>*',
    );
  }

  test_interfaceType_25_interfaces() {
    var A = class_(name: 'A');
    var I = class_(name: 'I');

    A.interfaces = [
      I.instantiate(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    ];

    var A_none = A.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var I_none = I.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_none, I_none, strT0: 'A', strT1: 'I');
    isNotSubtype(I_none, A_none, strT0: 'I', strT1: 'A');
  }

  test_interfaceType_26_mixins() {
    var A = class_(name: 'A');
    var M = class_(name: 'M');

    A.mixins = [
      M.instantiate(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    ];

    var A_none = A.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var M_none = M.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_none, M_none, strT0: 'A', strT1: 'M');
    isNotSubtype(M_none, A_none, strT0: 'M', strT1: 'A');
  }

  test_interfaceType_27() {
    isSubtype(numNone, objectNone, strT0: 'num', strT1: 'Object');
  }

  test_interfaceType_28() {
    isSubtype(numStar, objectNone, strT0: 'num*', strT1: 'Object');
  }

  test_interfaceType_39() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      listNone(
        promotedTypeParameterTypeNone(T, intNone),
      ),
      listNone(
        typeParameterTypeNone(T),
      ),
      strT0: 'List<T & int>, T extends Object?',
      strT1: 'List<T>, T extends Object?',
    );
  }

  test_interfaceType_40() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      listNone(
        promotedTypeParameterTypeNone(T, intQuestion),
      ),
      listNone(
        typeParameterTypeNone(T),
      ),
      strT0: 'List<T & int?>, T extends Object?',
      strT1: 'List<T>, T extends Object?',
    );
  }

  test_interfaceType_contravariant() {
    var T = typeParameter('T', variance: Variance.contravariant);
    var A = class_(name: 'A', typeParameters: [T]);

    var A_num = A.instantiate(
      typeArguments: [numNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var A_int = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_num, A_int, strT0: "A<num>", strT1: "A<int>");
    isSubtype(A_num, A_num, strT0: "A<num>", strT1: "A<num>");
    isNotSubtype(A_int, A_num, strT0: "A<int>", strT1: "A<num>");
  }

  test_interfaceType_covariant() {
    var T = typeParameter('T', variance: Variance.covariant);
    var A = class_(name: 'A', typeParameters: [T]);

    var A_num = A.instantiate(
      typeArguments: [numNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var A_int = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_int, A_num, strT0: "A<int>", strT1: "A<num>");
    isSubtype(A_num, A_num, strT0: "A<num>", strT1: "A<num>");
    isNotSubtype(A_num, A_int, strT0: "A<num>", strT1: "A<int>");
  }

  test_interfaceType_invariant() {
    var T = typeParameter('T', variance: Variance.invariant);
    var A = class_(name: 'A', typeParameters: [T]);

    var A_num = A.instantiate(
      typeArguments: [numNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var A_int = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_num, A_num, strT0: "A<num>", strT1: "A<num>");
    isNotSubtype(A_int, A_num, strT0: "A<int>", strT1: "A<num>");
    isNotSubtype(A_num, A_int, strT0: "A<num>", strT1: "A<int>");
  }

  test_multi_function_nonGeneric_oneArgument() {
    isSubtype2('num* Function(num*)*', 'num* Function(int*)*');
    isSubtype2('int* Function(num*)*', 'num* Function(num*)*');
    isSubtype2('int* Function(num*)*', 'num* Function(int*)*');
    isNotSubtype2('int* Function(int*)*', 'num* Function(num*)*');
    isSubtype2('Null?', 'num* Function(int*)*');
    isSubtype2('Null?', 'num* Function(int*)?');
    isSubtype2('Never', 'num* Function(int*)');
    isSubtype2('Never', 'num* Function(int*)*');
    isSubtype2('Never', 'num* Function(int*)?');
    isSubtype2('num* Function(num*)*', 'Object');
    isSubtype2('num* Function(num*)', 'Object');
    isNotSubtype2('num* Function(num*)?', 'Object');
    isNotSubtype2('Null?', 'num* Function(int*)');
    isNotSubtype2('num* Function(int*)', 'Never');

    isNotSubtype2('num', 'num Function(num)');
    isNotSubtype2('Object', 'num Function(num)');
    isNotSubtype2('Object*', 'num Function(num)');
    isNotSubtype2('Object?', 'num Function(num)');
    isNotSubtype2('dynamic', 'num Function(num)');

    isSubtype2('num Function(num)', 'num Function(num)*');
    isSubtype2('num Function(num)*', 'num Function(num)');
    isSubtype2('num Function(num)?', 'num Function(num)*');
    isSubtype2('num Function(num)*', 'num Function(num)?');
    isSubtype2('num Function(num)', 'num Function(num)?');
    isNotSubtype2('num Function(num)?', 'num Function(num)');

    isSubtype2('num Function(num)', 'num? Function(num)');
    isSubtype2('num Function(num?)', 'num Function(num)');
    isSubtype2('num Function(num?)', 'num? Function(num)');
    isNotSubtype2('num Function(num)', 'num? Function(num?)');

    isSubtype2('num Function({num x})', 'num? Function({num x})');
    isSubtype2('num Function({num? x})', 'num Function({num x})');
    isSubtype2('num Function({num? x})', 'num? Function({num x})');
    isNotSubtype2('num Function({num x})', 'num? Function({num? x})');

    isSubtype2('num Function([num])', 'num? Function([num])');
    isSubtype2('num Function([num?])', 'num Function([num])');
    isSubtype2('num Function([num?])', 'num? Function([num])');
    isNotSubtype2('num Function([num])', 'num? Function([num?])');
  }

  test_multi_function_nonGeneric_zeroArguments() {
    isSubtype2('int* Function()', 'Function');
    isSubtype2('int* Function()', 'Function*');
    isSubtype2('int* Function()', 'Function?');

    isSubtype2('int* Function()*', 'Function');
    isSubtype2('int* Function()*', 'Function*');
    isSubtype2('int* Function()*', 'Function?');

    isNotSubtype2('int* Function()?', 'Function');
    isSubtype2('int* Function()?', 'Function*');
    isSubtype2('int* Function()?', 'Function?');

    isSubtype2('int* Function()', 'Object');
    isSubtype2('int* Function()', 'Object*');
    isSubtype2('int* Function()', 'Object?');

    isSubtype2('int* Function()*', 'Object');
    isSubtype2('int* Function()*', 'Object*');
    isSubtype2('int* Function()*', 'Object?');

    isNotSubtype2('int* Function()?', 'Object');
    isSubtype2('int* Function()?', 'Object*');
    isSubtype2('int* Function()?', 'Object?');
  }

  test_multi_futureOr() {
    isSubtype2('int*', 'FutureOr<int*>*');
    isSubtype2('int*', 'FutureOr<num*>*');
    isSubtype2('Future<int*>*', 'FutureOr<int*>*');
    isSubtype2('Future<int*>*', 'FutureOr<num*>*');
    isSubtype2('Future<int*>*', 'FutureOr<Object*>*');
    isSubtype2('FutureOr<int*>*', 'FutureOr<int*>*');
    isSubtype2('FutureOr<int*>*', 'FutureOr<num*>*');
    isSubtype2('FutureOr<int*>*', 'Object*');
    isSubtype2('Null?', 'FutureOr<num?>');
    isSubtype2('Null?', 'FutureOr<num>?');
    isSubtype2('num?', 'FutureOr<num?>');
    isSubtype2('num?', 'FutureOr<num>?');
    isSubtype2('Future<num>', 'FutureOr<num?>');
    isSubtype2('Future<num>', 'FutureOr<num>?');
    isSubtype2('Future<num>', 'FutureOr<num?>?');
    isSubtype2('Future<num?>', 'FutureOr<num?>');
    isNotSubtype2('Future<num?>', 'FutureOr<num>?');
    isSubtype2('Future<num?>', 'FutureOr<num?>?');

    isSubtype2('num?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype2('Future<num>?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype2('Future<Future<num>>?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype2(
      'Future<Future<Future<num>>>?',
      'FutureOr<FutureOr<FutureOr<num>>?>',
    );
    isSubtype2('Future<num>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype2('Future<Future<num>>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype2(
      'Future<Future<Future<num>>>?',
      'FutureOr<FutureOr<FutureOr<num?>>>',
    );
    isSubtype2('Future<num?>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype2('Future<Future<num?>?>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype2(
      'Future<Future<Future<num?>?>?>?',
      'FutureOr<FutureOr<FutureOr<num?>>>',
    );

    isSubtype2('FutureOr<num>?', 'FutureOr<num?>');
    isNotSubtype2('FutureOr<num?>', 'FutureOr<num>?');

    isSubtype2('dynamic', 'FutureOr<Object?>');
    isSubtype2('dynamic', 'FutureOr<Object>?');
    isSubtype2('void', 'FutureOr<Object?>');
    isSubtype2('void', 'FutureOr<Object>?');
    isSubtype2('Object*', 'FutureOr<Object?>');
    isSubtype2('Object*', 'FutureOr<Object>?');
    isSubtype2('Object?', 'FutureOr<Object?>');
    isSubtype2('Object?', 'FutureOr<Object>?');
    isSubtype2('Object', 'FutureOr<Object?>');
    isSubtype2('Object', 'FutureOr<Object>?');
    isNotSubtype2('dynamic', 'FutureOr<Object>');
    isNotSubtype2('void', 'FutureOr<Object>');
    isNotSubtype2('Object?', 'FutureOr<Object>');
    isSubtype2('Object', 'FutureOr<Object>');

    isSubtype2('FutureOr<int>', 'Object');
    isSubtype2('FutureOr<int>', 'Object*');
    isSubtype2('FutureOr<int>', 'Object?');

    isSubtype2('FutureOr<int>*', 'Object');
    isSubtype2('FutureOr<int>*', 'Object*');
    isSubtype2('FutureOr<int>*', 'Object?');

    isNotSubtype2('FutureOr<int>?', 'Object');
    isSubtype2('FutureOr<int>?', 'Object*');
    isSubtype2('FutureOr<int>?', 'Object?');

    isSubtype2('FutureOr<int*>', 'Object');
    isSubtype2('FutureOr<int*>', 'Object*');
    isSubtype2('FutureOr<int*>', 'Object?');

    isNotSubtype2('FutureOr<int?>', 'Object');
    isSubtype2('FutureOr<int?>', 'Object*');
    isSubtype2('FutureOr<int?>', 'Object?');

    isSubtype2('FutureOr<Future<Object>>', 'Future<Object>');
    isNotSubtype2('FutureOr<Future<Object>>?', 'Future<Object>');
    isNotSubtype2('FutureOr<Future<Object>?>', 'Future<Object>');
    isNotSubtype2('FutureOr<Future<Object>?>?', 'Future<Object>');

    isSubtype2('FutureOr<num>', 'Object');
    isSubtype2('FutureOr<num>*', 'Object');
    isNotSubtype2('FutureOr<num>?', 'Object');
  }

  test_multi_futureOr_functionType() {
    isSubtype(
      functionTypeStar(
        returnType: stringStar,
      ),
      futureOrStar(
        functionTypeStar(
          returnType: voidNone,
        ),
      ),
      strT0: 'String* Function()*',
      strT1: 'FutureOr<void Function()*>*',
    );

    isSubtype(
      functionTypeNone(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()',
      strT1: 'FutureOr<void Function()>',
    );

    isSubtype(
      functionTypeNone(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeQuestion(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()',
      strT1: 'FutureOr<void Function()?>',
    );

    isSubtype(
      functionTypeNone(
        returnType: stringNone,
      ),
      futureOrQuestion(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()',
      strT1: 'FutureOr<void Function()>?',
    );

    isSubtype(
      functionTypeQuestion(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeQuestion(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()?',
      strT1: 'FutureOr<void Function()?>',
    );

    isSubtype(
      functionTypeQuestion(
        returnType: stringNone,
      ),
      futureOrQuestion(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()?',
      strT1: 'FutureOr<void Function()>?',
    );

    isNotSubtype(
      functionTypeQuestion(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()?',
      strT1: 'FutureOr<void Function()>',
    );

    isNotSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      futureOrStar(
        functionTypeStar(
          returnType: stringNone,
        ),
      ),
      strT0: 'void Function()*',
      strT1: 'FutureOr<String Function()*>*',
    );
  }

  test_multi_futureOr_typeParameter() {
    TypeParameterElement E;

    E = typeParameter('E', bound: objectStar);
    isSubtype(
      typeParameterTypeStar(E),
      futureOrStar(
        typeParameterTypeStar(E),
      ),
      strT0: 'E*, E extends Object*',
      strT1: 'FutureOr<E*>*, E extends Object*',
    );

    E = typeParameter('E', bound: objectNone);
    isSubtype(
      typeParameterTypeQuestion(E),
      futureOrQuestion(
        typeParameterTypeNone(E),
      ),
      strT0: 'E?, E extends Object',
      strT1: 'FutureOr<E>?, E extends Object',
    );
    isSubtype(
      typeParameterTypeQuestion(E),
      futureOrNone(
        typeParameterTypeQuestion(E),
      ),
      strT0: 'E?, E extends Object',
      strT1: 'FutureOr<E?>, E extends Object',
    );
    isNotSubtype(
      typeParameterTypeQuestion(E),
      futureOrNone(
        typeParameterTypeNone(E),
      ),
      strT0: 'E?, E extends Object',
      strT1: 'FutureOr<E>, E extends Object',
    );

    E = typeParameter('E', bound: objectQuestion);
    isSubtype(
      typeParameterTypeNone(E),
      futureOrQuestion(
        typeParameterTypeNone(E),
      ),
      strT0: 'E, E extends Object?',
      strT1: 'FutureOr<E>?, E extends Object?',
    );
    isSubtype(
      typeParameterTypeNone(E),
      futureOrNone(
        typeParameterTypeQuestion(E),
      ),
      strT0: 'E, E extends Object?',
      strT1: 'FutureOr<E?>, E extends Object?',
    );
    isSubtype(
      typeParameterTypeNone(E),
      futureOrNone(
        typeParameterTypeNone(E),
      ),
      strT0: 'E, E extends Object?',
      strT1: 'FutureOr<E>, E extends Object?',
    );

    E = typeParameter('E', bound: objectStar);
    isNotSubtype(
      typeParameterTypeStar(E),
      futureOrStar(stringStar),
      strT0: 'E*, E extends Object*',
      strT1: 'FutureOr<String*>*',
    );

    E = typeParameter('E', bound: stringNone);
    isSubtype(
      typeParameterTypeQuestion(E),
      futureOrQuestion(stringNone),
      strT0: 'E?, E extends String',
      strT1: 'FutureOr<String>?',
    );
    isSubtype(
      typeParameterTypeQuestion(E),
      futureOrNone(stringQuestion),
      strT0: 'E?, E extends String',
      strT1: 'FutureOr<String?>',
    );
    isNotSubtype(
      typeParameterTypeQuestion(E),
      futureOrNone(stringNone),
      strT0: 'E?, E extends String',
      strT1: 'FutureOr<String>',
    );

    E = typeParameter('E', bound: stringQuestion);
    isSubtype(
      typeParameterTypeNone(E),
      futureOrQuestion(stringNone),
      strT0: 'E, E extends String?',
      strT1: 'FutureOr<String>?',
    );
    isSubtype(
      typeParameterTypeNone(E),
      futureOrNone(stringQuestion),
      strT0: 'E, E extends String?',
      strT1: 'FutureOr<String?>',
    );
    isNotSubtype(
      typeParameterTypeNone(E),
      futureOrNone(stringNone),
      strT0: 'E, E extends String?',
      strT1: 'FutureOr<String>',
    );
  }

  test_multi_futureOr_typeParameter_promotion() {
    TypeParameterElement S;
    TypeParameterElement T;

    T = typeParameter('T', bound: objectStar);
    isSubtype(
      promotedTypeParameterTypeStar(T, intStar),
      futureOrStar(numStar),
      strT0: 'T* & int*, T extends Object*',
      strT1: 'FutureOr<num*>*',
    );

    T = typeParameter('T', bound: objectNone);
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrNone(numNone),
      strT0: 'T & int, T extends Object',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrNone(numQuestion),
      strT0: 'T & int, T extends Object',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrQuestion(numNone),
      strT0: 'T & int, T extends Object',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectQuestion);
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrNone(numNone),
      strT0: 'T & int, T extends Object?',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrNone(numQuestion),
      strT0: 'T & int, T extends Object?',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrQuestion(numNone),
      strT0: 'T & int, T extends Object?',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectQuestion);
    isNotSubtype(
      promotedTypeParameterTypeNone(T, intQuestion),
      futureOrNone(numNone),
      strT0: 'T & int?, T extends Object?',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intQuestion),
      futureOrNone(numQuestion),
      strT0: 'T & int?, T extends Object?',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intQuestion),
      futureOrQuestion(numNone),
      strT0: 'T & int?, T extends Object?',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectQuestion);
    S = typeParameter('S', bound: typeParameterTypeNone(T));
    isNotSubtype(
      promotedTypeParameterTypeNone(T, typeParameterTypeNone(S)),
      futureOrNone(objectNone),
      strT0: 'T & S, T extends Object?',
      strT1: 'FutureOr<Object>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, typeParameterTypeNone(S)),
      futureOrNone(objectQuestion),
      strT0: 'T & S, T extends Object?',
      strT1: 'FutureOr<Object?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, typeParameterTypeNone(S)),
      futureOrQuestion(objectNone),
      strT0: 'T & S, T extends Object?',
      strT1: 'FutureOr<Object>?',
    );

    T = typeParameter('T', bound: objectStar);
    isSubtype(
      promotedTypeParameterTypeNone(T, futureStar(numStar)),
      futureOrStar(numStar),
      strT0: 'T & Future<num*>*, T extends Object*',
      strT1: 'FutureOr<num*>*',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureStar(intStar)),
      futureOrStar(numStar),
      strT0: 'T & Future<int*>*, T extends Object*',
      strT1: 'FutureOr<num*>*',
    );

    T = typeParameter('T', bound: objectNone);
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<int>, T extends Object',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numQuestion),
      strT0: 'T & Future<int>, T extends Object',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrQuestion(numNone),
      strT0: 'T & Future<int>, T extends Object',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectQuestion);
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<int>, T extends Object?',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numQuestion),
      strT0: 'T & Future<int>, T extends Object?',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrQuestion(numNone),
      strT0: 'T & Future<int>, T extends Object?',
      strT1: 'FutureOr<num>?',
    );

    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureQuestion(intNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<int>?, T extends Object?',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureQuestion(intNone)),
      futureOrNone(numQuestion),
      strT0: 'T & Future<int>?, T extends Object?',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureQuestion(intNone)),
      futureOrQuestion(numNone),
      strT0: 'T & Future<int>?, T extends Object?',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectNone);
    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intQuestion)),
      futureOrNone(numNone),
      strT0: 'T & Future<int?>, T extends Object',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intQuestion)),
      futureOrNone(numQuestion),
      strT0: 'T & Future<int?>, T extends Object',
      strT1: 'FutureOr<num?>',
    );
    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intQuestion)),
      futureOrQuestion(numNone),
      strT0: 'T & Future<int?>, T extends Object',
      strT1: 'FutureOr<num>?',
    );
  }

  test_multi_list_subTypes_superTypes() {
    isSubtype2('List<int*>*', 'List<int*>*');
    isSubtype2('List<int*>*', 'Iterable<int*>*');
    isSubtype2('List<int*>*', 'List<num*>*');
    isSubtype2('List<int*>*', 'Iterable<num*>*');
    isSubtype2('List<int*>*', 'List<Object*>*');
    isSubtype2('List<int*>*', 'Iterable<Object*>*');
    isSubtype2('List<int*>*', 'Object*');
    isSubtype2('List<int*>*', 'List<Comparable<Object*>*>*');
    isSubtype2('List<int*>*', 'List<Comparable<num*>*>*');
    isSubtype2('List<int*>*', 'List<Comparable<Comparable<num*>*>*>*');
    isSubtype2('List<int*>', 'Object');
    isSubtype2('List<int*>*', 'Object');
    isSubtype2('Null?', 'List<int*>*');
    isSubtype2('Null?', 'List<int*>?');
    isSubtype2('Never', 'List<int*>');
    isSubtype2('Never', 'List<int*>*');
    isSubtype2('Never', 'List<int*>?');

    isSubtype2('List<int>', 'List<int>');
    isSubtype2('List<int>', 'List<int>*');
    isSubtype2('List<int>', 'List<int>?');
    isSubtype2('List<int>*', 'List<int>');
    isSubtype2('List<int>*', 'List<int>*');
    isSubtype2('List<int>*', 'List<int>?');
    isNotSubtype2('List<int>?', 'List<int>');
    isSubtype2('List<int>?', 'List<int>*');
    isSubtype2('List<int>?', 'List<int>?');

    isSubtype2('List<int>', 'List<int*>');
    isSubtype2('List<int>', 'List<int?>');
    isSubtype2('List<int*>', 'List<int>');
    isSubtype2('List<int*>', 'List<int*>');
    isSubtype2('List<int*>', 'List<int?>');
    isNotSubtype2('List<int?>', 'List<int>');
    isSubtype2('List<int?>', 'List<int*>');
    isSubtype2('List<int?>', 'List<int?>');
  }

  test_multi_never() {
    isSubtype2('Never', 'FutureOr<num>');
    isSubtype2('Never', 'FutureOr<num*>');
    isSubtype2('Never', 'FutureOr<num>*');
    isSubtype2('Never', 'FutureOr<num?>');
    isSubtype2('Never', 'FutureOr<num>?');
    isNotSubtype2('FutureOr<num>', 'Never');
  }

  test_multi_num_subTypes_superTypes() {
    isSubtype2('int*', 'num*');
    isSubtype2('int*', 'Comparable<num*>*');
    isSubtype2('int*', 'Comparable<Object*>*');
    isSubtype2('int*', 'Object*');
    isSubtype2('double*', 'num*');
    isSubtype2('num', 'Object');
    isSubtype2('num*', 'Object');
    isSubtype2('Null?', 'num*');
    isSubtype2('Null?', 'num?');
    isSubtype2('Never', 'num');
    isSubtype2('Never', 'num*');
    isSubtype2('Never', 'num?');

    isNotSubtype2('int*', 'double*');
    isNotSubtype2('int*', 'Comparable<int*>*');
    isNotSubtype2('int*', 'Iterable<int*>*');
    isNotSubtype2('Comparable<int*>*', 'Iterable<int*>*');
    isNotSubtype2('num?', 'Object');
    isNotSubtype2('Null?', 'num');
    isNotSubtype2('num', 'Never');
  }

  test_multi_object_topAndBottom() {
    isSubtype2('Never', 'Object');
    isSubtype2('Object', 'dynamic');
    isSubtype2('Object', 'void');
    isSubtype2('Object', 'Object?');
    isSubtype2('Object', 'Object*');
    isSubtype2('Object*', 'Object');

    isNotSubtype2('Object', 'Never');
    isNotSubtype2('Object', 'Null?');
    isNotSubtype2('dynamic', 'Object');
    isNotSubtype2('void', 'Object');
    isNotSubtype2('Object?', 'Object');
  }

  test_multi_special() {
    isNotSubtype2('dynamic', 'int');
    isNotSubtype2('dynamic', 'int*');
    isNotSubtype2('dynamic', 'int?');

    isNotSubtype2('void', 'int');
    isNotSubtype2('void', 'int*');
    isNotSubtype2('void', 'int?');

    isNotSubtype2('Object', 'int');
    isNotSubtype2('Object', 'int*');
    isNotSubtype2('Object', 'int?');

    isNotSubtype2('Object*', 'int');
    isNotSubtype2('Object*', 'int*');
    isNotSubtype2('Object*', 'int?');

    isNotSubtype2('Object?', 'int');
    isNotSubtype2('Object?', 'int*');
    isNotSubtype2('Object?', 'int?');

    isNotSubtype2('int* Function()*', 'int*');
  }

  test_multi_topAndBottom() {
    isSubtype2('Null?', 'Null?');
    isSubtype2('Never', 'Null?');
    isSubtype2('Never', 'Never');
    isNotSubtype2('Null?', 'Never');

    isSubtype2('Null?', 'Never?');
    isSubtype2('Never?', 'Null?');
    isSubtype2('Never', 'Never?');
    isNotSubtype2('Never?', 'Never');

    isSubtype2('Object*', 'Object*');
    isSubtype2('Object*', 'dynamic');
    isSubtype2('Object*', 'void');
    isSubtype2('Object*', 'Object?');
    isSubtype2('dynamic', 'Object*');
    isSubtype2('dynamic', 'dynamic');
    isSubtype2('dynamic', 'void');
    isSubtype2('dynamic', 'Object?');
    isSubtype2('void', 'Object*');
    isSubtype2('void', 'dynamic');
    isSubtype2('void', 'void');
    isSubtype2('void', 'Object?');
    isSubtype2('Object?', 'Object*');
    isSubtype2('Object?', 'dynamic');
    isSubtype2('Object?', 'void');
    isSubtype2('Object?', 'Object?');

    isSubtype2('Never', 'Object?');
    isSubtype2('Never', 'Object*');
    isSubtype2('Never', 'dynamic');
    isSubtype2('Never', 'void');
    isSubtype2('Null?', 'Object?');
    isSubtype2('Null?', 'Object*');
    isSubtype2('Null?', 'dynamic');
    isSubtype2('Null?', 'void');

    isNotSubtype2('Object?', 'Never');
    isNotSubtype2('Object?', 'Null?');
    isNotSubtype2('Object*', 'Never');
    isNotSubtype2('Object*', 'Null?');
    isNotSubtype2('dynamic', 'Never');
    isNotSubtype2('dynamic', 'Null?');
    isNotSubtype2('void', 'Never');
    isNotSubtype2('void', 'Null?');
  }

  test_multi_typeParameter_promotion() {
    TypeParameterElement T;

    T = typeParameter('T', bound: intStar);
    isSubtype(
      typeParameterTypeStar(T),
      promotedTypeParameterTypeStar(T, intStar),
      strT0: 'T*, T extends int*',
      strT1: 'T* & int*, T extends int*',
    );

    T = typeParameter('T', bound: intNone);
    isSubtype(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T, T extends int',
      strT1: 'T & int, T extends int',
    );
    isNotSubtype(
      typeParameterTypeQuestion(T),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T?, T extends int',
      strT1: 'T & int, T extends int',
    );

    T = typeParameter('T', bound: intQuestion);
    isNotSubtype(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T, T extends int?',
      strT1: 'T & int, T extends int?',
    );
    isSubtype(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intQuestion),
      strT0: 'T, T extends int?',
      strT1: 'T & int?, T extends int?',
    );
    isNotSubtype(
      typeParameterTypeQuestion(T),
      promotedTypeParameterTypeNone(T, intQuestion),
      strT0: 'T?, T extends int?',
      strT1: 'T & int?, T extends int?',
    );

    T = typeParameter('T', bound: numStar);
    isSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(T),
      strT0: 'T*, T extends num*',
      strT1: 'T*, T extends num*',
    );

    T = typeParameter('T', bound: numNone);
    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T, T extends num',
      strT1: 'T, T extends num',
    );
    isSubtype(
      typeParameterTypeQuestion(T),
      typeParameterTypeQuestion(T),
      strT0: 'T?, T extends num',
      strT1: 'T?, T extends num',
    );

    T = typeParameter('T', bound: numQuestion);
    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T, T extends num?',
      strT1: 'T, T extends num?',
    );
    isSubtype(
      typeParameterTypeQuestion(T),
      typeParameterTypeQuestion(T),
      strT0: 'T?, T extends num?',
      strT1: 'T?, T extends num?',
    );
  }

  test_never_01() {
    isSubtype(
      neverNone,
      neverNone,
      strT0: 'Never',
      strT1: 'Never',
    );
  }

  test_never_02() {
    isSubtype(neverNone, numNone, strT0: 'Never', strT1: 'num');
  }

  test_never_03() {
    isSubtype(neverNone, numStar, strT0: 'Never', strT1: 'num*');
  }

  test_never_04() {
    isSubtype(neverNone, numQuestion, strT0: 'Never', strT1: 'num?');
  }

  test_never_05() {
    isNotSubtype(numNone, neverNone, strT0: 'num', strT1: 'Never');
  }

  test_never_06() {
    isSubtype(
      neverNone,
      listNone(intStar),
      strT0: 'Never',
      strT1: 'List<int*>',
    );
  }

  test_never_09() {
    isNotSubtype(
      numNone,
      neverNone,
      strT0: 'num',
      strT1: 'Never',
    );
  }

  test_never_15() {
    var T = typeParameter('T', bound: objectStar);

    isSubtype(
      neverNone,
      promotedTypeParameterTypeStar(T, numStar),
      strT0: 'Never',
      strT1: 'T* & num*, T extends Object*',
    );
  }

  test_never_16() {
    var T = typeParameter('T', bound: objectStar);

    isNotSubtype(
      promotedTypeParameterTypeStar(T, numStar),
      neverNone,
      strT0: 'T* & num*, T extends Object*',
      strT1: 'Never',
    );
  }

  test_never_17() {
    var T = typeParameter('T', bound: neverNone);

    isSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Never',
      strT1: 'Never',
    );
  }

  test_never_18() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      promotedTypeParameterTypeNone(T, neverNone),
      neverNone,
      strT0: 'T & Never, T extends Object',
      strT1: 'Never',
    );
  }

  test_never_19() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      neverNone,
      typeParameterTypeQuestion(T),
      strT0: 'Never',
      strT1: 'T?, T extends Object',
    );
  }

  test_never_20() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      neverNone,
      typeParameterTypeQuestion(T),
      strT0: 'Never',
      strT1: 'T?, T extends Object?',
    );
  }

  test_never_21() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      neverNone,
      typeParameterTypeNone(T),
      strT0: 'Never',
      strT1: 'T, T extends Object',
    );
  }

  test_never_22() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      neverNone,
      typeParameterTypeNone(T),
      strT0: 'Never',
      strT1: 'T, T extends Object?',
    );
  }

  test_never_23() {
    var T = typeParameter('T', bound: neverNone);

    isSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Never',
      strT1: 'Never',
    );
  }

  test_never_24() {
    var T = typeParameter('T', bound: neverQuestion);

    isNotSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Never?',
      strT1: 'Never',
    );
  }

  test_never_25() {
    var T = typeParameter('T', bound: neverNone);

    isNotSubtype(
      typeParameterTypeQuestion(T),
      neverNone,
      strT0: 'T?, T extends Never',
      strT1: 'Never',
    );
  }

  test_never_26() {
    var T = typeParameter('T', bound: neverQuestion);

    isNotSubtype(
      typeParameterTypeQuestion(T),
      neverNone,
      strT0: 'T?, T extends Never?',
      strT1: 'Never',
    );
  }

  test_never_27() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Object',
      strT1: 'Never',
    );
  }

  test_never_28() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Object?',
      strT1: 'Never',
    );
  }

  test_never_29() {
    isSubtype(neverNone, nullQuestion, strT0: 'Never', strT1: 'Null?');
  }

  test_null_01() {
    isNotSubtype(
      nullQuestion,
      neverNone,
      strT0: 'Null?',
      strT1: 'Never',
    );
  }

  test_null_02() {
    isSubtype(
      nullQuestion,
      objectStar,
      strT0: 'Null?',
      strT1: 'Object*',
    );
  }

  test_null_03() {
    isSubtype(
      nullQuestion,
      voidNone,
      strT0: 'Null?',
      strT1: 'void',
    );
  }

  test_null_04() {
    isSubtype(
      nullQuestion,
      dynamicNone,
      strT0: 'Null?',
      strT1: 'dynamic',
    );
  }

  test_null_05() {
    isSubtype(
      nullQuestion,
      doubleStar,
      strT0: 'Null?',
      strT1: 'double*',
    );
  }

  test_null_06() {
    isSubtype(
      nullQuestion,
      doubleQuestion,
      strT0: 'Null?',
      strT1: 'double?',
    );
  }

  test_null_07() {
    isSubtype(
      nullQuestion,
      comparableStar(objectStar),
      strT0: 'Null?',
      strT1: 'Comparable<Object*>*',
    );
  }

  test_null_08() {
    var T = typeParameter('T', bound: objectStar);

    isNotSubtype(
      nullQuestion,
      typeParameterTypeNone(T),
      strT0: 'Null?',
      strT1: 'T, T extends Object*',
    );
  }

  test_null_09() {
    isSubtype(
      nullQuestion,
      nullQuestion,
      strT0: 'Null?',
      strT1: 'Null?',
    );
  }

  test_null_10() {
    isNotSubtype(
      nullQuestion,
      listNone(intStar),
      strT0: 'Null?',
      strT1: 'List<int*>',
    );
  }

  test_null_13() {
    isNotSubtype(
      nullQuestion,
      functionTypeNone(
        returnType: numStar,
        parameters: [
          requiredParameter(type: intStar),
        ],
      ),
      strT0: 'Null?',
      strT1: 'num* Function(int*)',
    );
  }

  test_null_14() {
    isSubtype(
      nullQuestion,
      functionTypeStar(
        returnType: numStar,
        parameters: [
          requiredParameter(type: intStar),
        ],
      ),
      strT0: 'Null?',
      strT1: 'num* Function(int*)*',
    );
  }

  test_null_15() {
    isSubtype(
      nullQuestion,
      functionTypeQuestion(
        returnType: numStar,
        parameters: [
          requiredParameter(type: intStar),
        ],
      ),
      strT0: 'Null?',
      strT1: 'num* Function(int*)?',
    );
  }

  test_null_16() {
    var T = typeParameter('T', bound: objectStar);

    isSubtype(
      nullQuestion,
      promotedTypeParameterTypeStar(T, numStar),
      strT0: 'Null?',
      strT1: 'T* & num*, T extends Object*',
    );
  }

  test_null_17() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'Null?',
      strT1: 'T & num, T extends Object?',
    );
  }

  test_null_18() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, numQuestion),
      strT0: 'Null?',
      strT1: 'T & num?, T extends Object?',
    );
  }

  test_null_19() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'Null?',
      strT1: 'T & num, T extends Object',
    );
  }

  test_null_20() {
    var T = typeParameter('T', bound: objectQuestion);
    var S = typeParameter('S', bound: typeParameterTypeNone(T));

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, typeParameterTypeNone(S)),
      strT0: 'Null?',
      strT1: 'T & S, T extends Object?',
    );
  }

  test_null_21() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      nullQuestion,
      typeParameterTypeQuestion(T),
      strT0: 'Null?',
      strT1: 'T?, T extends Object',
    );
  }

  test_null_22() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      nullQuestion,
      typeParameterTypeQuestion(T),
      strT0: 'Null?',
      strT1: 'T?, T extends Object?',
    );
  }

  test_null_23() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      nullQuestion,
      typeParameterTypeNone(T),
      strT0: 'Null?',
      strT1: 'T, T extends Object',
    );
  }

  test_null_24() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      nullQuestion,
      typeParameterTypeNone(T),
      strT0: 'Null?',
      strT1: 'T, T extends Object?',
    );
  }

  test_null_25() {
    var T = typeParameter('T', bound: nullQuestion);

    isSubtype(
      typeParameterTypeNone(T),
      nullQuestion,
      strT0: 'T, T extends Null?',
      strT1: 'Null?',
    );
  }

  test_null_26() {
    var T = typeParameter('T', bound: nullQuestion);

    isSubtype(
      typeParameterTypeQuestion(T),
      nullQuestion,
      strT0: 'T?, T extends Null?',
      strT1: 'Null?',
    );
  }

  test_null_27() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      typeParameterTypeNone(T),
      nullQuestion,
      strT0: 'T, T extends Object',
      strT1: 'Null?',
    );
  }

  test_null_28() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      typeParameterTypeNone(T),
      nullQuestion,
      strT0: 'T, T extends Object?',
      strT1: 'Null?',
    );
  }

  test_null_29() {
    isSubtype(
      nullQuestion,
      comparableQuestion(objectStar),
      strT0: 'Null?',
      strT1: 'Comparable<Object*>?',
    );
  }

  test_null_30() {
    isNotSubtype(nullQuestion, objectNone, strT0: 'Null?', strT1: 'Object');
  }

  test_nullabilitySuffix_01() {
    isSubtype(intNone, intNone, strT0: 'int', strT1: 'int');
    isSubtype(intNone, intQuestion, strT0: 'int', strT1: 'int?');
    isSubtype(intNone, intStar, strT0: 'int', strT1: 'int*');

    isNotSubtype(intQuestion, intNone, strT0: 'int?', strT1: 'int');
    isSubtype(intQuestion, intQuestion, strT0: 'int?', strT1: 'int?');
    isSubtype(intQuestion, intStar, strT0: 'int?', strT1: 'int*');

    isSubtype(intStar, intNone, strT0: 'int*', strT1: 'int');
    isSubtype(intStar, intQuestion, strT0: 'int*', strT1: 'int?');
    isSubtype(intStar, intStar, strT0: 'int*', strT1: 'int*');
  }

  test_nullabilitySuffix_05() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      objectNone,
      strT0: 'void Function(int)',
      strT1: 'Object',
    );
  }

  test_nullabilitySuffix_11() {
    isSubtype(
      intQuestion,
      intQuestion,
      strT0: 'int?',
      strT1: 'int?',
    );
  }

  test_nullabilitySuffix_12() {
    isSubtype(
      intStar,
      intStar,
      strT0: 'int*',
      strT1: 'int*',
    );
  }

  test_nullabilitySuffix_13() {
    var f = functionTypeQuestion(
      parameters: [
        requiredParameter(type: intNone),
      ],
      returnType: intNone,
    );
    isSubtype(
      f,
      f,
      strT0: 'int Function(int)?',
      strT1: 'int Function(int)?',
    );
  }

  test_nullabilitySuffix_14() {
    var f = functionTypeStar(
      parameters: [
        requiredParameter(type: intNone),
      ],
      returnType: intNone,
    );
    isSubtype(
      f,
      f,
      strT0: 'int Function(int)*',
      strT1: 'int Function(int)*',
    );
  }

  test_nullabilitySuffix_15() {
    var f = functionTypeNone(
      parameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: intStar),
        requiredParameter(type: intQuestion),
      ],
      returnType: intQuestion,
    );
    isSubtype(
      f,
      f,
      strT0: 'int? Function(int, int*, int?)',
      strT1: 'int? Function(int, int*, int?)',
    );
  }

  test_nullabilitySuffix_16() {
    var type = listQuestion(intNone);
    isSubtype(
      type,
      type,
      strT0: 'List<int>?',
      strT1: 'List<int>?',
    );
  }

  test_nullabilitySuffix_17() {
    var type = listQuestion(intQuestion);
    isSubtype(
      type,
      type,
      strT0: 'List<int?>?',
      strT1: 'List<int?>?',
    );
  }

  test_nullabilitySuffix_18() {
    var T = typeParameter('T', bound: objectStar);
    var type = promotedTypeParameterTypeNone(T, intQuestion);
    isSubtype(
      type,
      type,
      strT0: 'T & int?, T extends Object*',
      strT1: 'T & int?, T extends Object*',
    );
  }

  test_nullabilitySuffix_19() {
    var T = typeParameter('T', bound: objectNone);
    var type = promotedTypeParameterTypeQuestion(T, intQuestion);
    isSubtype(
      type,
      type,
      strT0: 'T? & int?, T extends Object',
      strT1: 'T? & int?, T extends Object',
    );
  }

  test_special_01() {
    isNotSubtype(
      dynamicNone,
      intStar,
      strT0: 'dynamic',
      strT1: 'int*',
    );
  }

  test_special_02() {
    isNotSubtype(
      voidNone,
      intStar,
      strT0: 'void',
      strT1: 'int*',
    );
  }

  test_special_03() {
    isNotSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      intStar,
      strT0: 'int* Function()*',
      strT1: 'int*',
    );
  }

  test_special_04() {
    isNotSubtype(
      intStar,
      functionTypeStar(
        returnType: intStar,
      ),
      strT0: 'int*',
      strT1: 'int* Function()*',
    );
  }

  test_special_06() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      objectStar,
      strT0: 'int* Function()*',
      strT1: 'Object*',
    );
  }

  test_special_07() {
    isSubtype(
      objectStar,
      objectStar,
      strT0: 'Object*',
      strT1: 'Object*',
    );
  }

  test_special_08() {
    isSubtype(
      objectStar,
      dynamicNone,
      strT0: 'Object*',
      strT1: 'dynamic',
    );
  }

  test_special_09() {
    isSubtype(
      objectStar,
      voidNone,
      strT0: 'Object*',
      strT1: 'void',
    );
  }

  test_special_10() {
    isSubtype(
      dynamicNone,
      objectStar,
      strT0: 'dynamic',
      strT1: 'Object*',
    );
  }

  test_special_11() {
    isSubtype(
      dynamicNone,
      dynamicNone,
      strT0: 'dynamic',
      strT1: 'dynamic',
    );
  }

  test_special_12() {
    isSubtype(
      dynamicNone,
      voidNone,
      strT0: 'dynamic',
      strT1: 'void',
    );
  }

  test_special_13() {
    isSubtype(
      voidNone,
      objectStar,
      strT0: 'void',
      strT1: 'Object*',
    );
  }

  test_special_14() {
    isSubtype(
      voidNone,
      dynamicNone,
      strT0: 'void',
      strT1: 'dynamic',
    );
  }

  test_special_15() {
    isSubtype(
      voidNone,
      voidNone,
      strT0: 'void',
      strT1: 'void',
    );
  }

  test_top_01() {
    var S = typeParameter('S', bound: objectStar);
    var T = typeParameter('T', bound: voidNone);
    var U = typeParameter('U', bound: dynamicNone);
    var V = typeParameter('V', bound: objectStar);

    isSubtype(
      functionTypeStar(
        typeFormals: [S, T],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(S)),
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        typeFormals: [U, V],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(U)),
          requiredParameter(type: typeParameterTypeNone(V)),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function<S extends Object*, T extends void>(S, T)*',
      strT1: 'void Function<U extends dynamic, V extends Object*>(U, V)*',
    );
  }

  test_top_02() {
    var T0 = typeParameter('T0', bound: dynamicNone);
    var T1 = typeParameter('T1', bound: objectStar);

    var f = functionTypeStar(
      typeFormals: [T0],
      returnType: typeParameterTypeNone(T0),
    );

    var g = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    isSubtype(
      f,
      g,
      strT0: 'T0 Function<T0 extends dynamic>()*',
      strT1: 'T1* Function<T1 extends Object*>()*',
    );

    isSubtype(
      g,
      f,
      strT0: 'T1* Function<T1 extends Object*>()*',
      strT1: 'T0 Function<T0 extends dynamic>()*',
    );
  }

  test_top_03() {
    var T0 = typeParameter('T0', bound: dynamicNone);
    var T1 = typeParameter('T1', bound: objectStar);
    var T2 = typeParameter('T2', bound: voidNone);

    var h = functionTypeStar(
      typeFormals: [T0],
      returnType: typeParameterTypeStar(T0),
    );

    var i = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    var j = functionTypeStar(
      typeFormals: [T2],
      returnType: typeParameterTypeStar(T2),
    );

    isSubtype(h, i);
    isSubtype(h, j);
    isSubtype(i, h);
    isSubtype(i, j);
    isSubtype(j, h);
    isSubtype(h, i);
  }

  test_top_04() {
    isNotSubtype(
      dynamicNone,
      functionTypeStar(
        returnType: dynamicNone,
      ),
      strT0: 'dynamic',
      strT1: 'dynamic Function()*',
    );
  }

  test_top_05() {
    isNotSubtype(
      futureOrStar(
        functionTypeStar(
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'FutureOr<void Function()*>*',
      strT1: 'void Function()*',
    );
  }

  test_top_06() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'T & void Function()*',
      strT1: 'void Function()*',
    );
  }

  test_top_07() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        returnType: dynamicNone,
      ),
      strT0: 'T & void Function()*',
      strT1: 'dynamic Function()*',
    );
  }

  test_top_08() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        returnType: objectStar,
      ),
      strT0: 'T & void Function()*',
      strT1: 'Object* Function()*',
    );
  }

  test_top_09() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: voidNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'T & void Function(void)*',
      strT1: 'void Function(void)*',
    );
  }

  test_top_10() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: dynamicNone),
        ],
        returnType: dynamicNone,
      ),
      strT0: 'T & void Function(void)*',
      strT1: 'dynamic Function(dynamic)*',
    );
  }

  test_top_11() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: objectStar),
        ],
        returnType: objectStar,
      ),
      strT0: 'T & void Function(void)*',
      strT1: 'Object* Function(Object*)*',
    );
  }

  test_top_12() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: iterableStar(intStar)),
        ],
        returnType: dynamicNone,
      ),
      strT0: 'T & void Function(void)*',
      strT1: 'dynamic Function(Iterable<int*>*)*',
    );
  }

  test_top_13() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: objectStar,
      ),
      strT0: 'T & void Function(void)*',
      strT1: 'Object* Function(int*)*',
    );
  }

  test_top_14() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'T & void Function(void)*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_top_15() {
    var T = typeParameter(
      'T',
      bound: functionTypeStar(
        returnType: voidNone,
      ),
    );

    isSubtype(
      typeParameterTypeStar(T),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'T*, T extends void Function()*',
      strT1: 'void Function()*',
    );
  }

  test_top_16() {
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(T),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'T',
      strT1: 'void Function()*',
    );
  }

  test_top_17() {
    isNotSubtype(
      voidNone,
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'void',
      strT1: 'void Function()*',
    );
  }

  test_top_18() {
    var T = typeParameter('T');

    isNotSubtype(
      dynamicNone,
      typeParameterTypeNone(T),
      strT0: 'dynamic',
      strT1: 'T',
    );
  }

  test_top_19() {
    var T = typeParameter('T');

    isNotSubtype(
      iterableStar(
        typeParameterTypeNone(T),
      ),
      typeParameterTypeNone(T),
      strT0: 'Iterable<T>*',
      strT1: 'T',
    );
  }

  test_top_21() {
    var T = typeParameter('T');

    isNotSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      typeParameterTypeNone(T),
      strT0: 'void Function()*',
      strT1: 'T',
    );
  }

  test_top_22() {
    var T = typeParameter('T');

    isNotSubtype(
      futureOrStar(
        typeParameterTypeNone(T),
      ),
      typeParameterTypeNone(T),
      strT0: 'FutureOr<T>*',
      strT1: 'T',
    );
  }

  test_top_23() {
    var T = typeParameter('T');

    isNotSubtype(
      voidNone,
      typeParameterTypeNone(T),
      strT0: 'void',
      strT1: 'T',
    );
  }

  test_top_24() {
    var T = typeParameter('T');

    isNotSubtype(
      voidNone,
      promotedTypeParameterTypeNone(T, voidNone),
      strT0: 'void',
      strT1: 'T & void',
    );
  }

  test_top_25() {
    var T = typeParameter('T', bound: voidNone);

    isNotSubtype(
      voidNone,
      promotedTypeParameterTypeNone(T, voidNone),
      strT0: 'void',
      strT1: 'T & void, T extends void',
    );
  }

  test_typeParameter_01() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intStar),
      promotedTypeParameterTypeNone(T, intStar),
      strT0: 'T & int*',
      strT1: 'T & int*',
    );
  }

  test_typeParameter_02() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intStar),
      promotedTypeParameterTypeNone(T, numStar),
      strT0: 'T & int*',
      strT1: 'T & num*',
    );
  }

  test_typeParameter_03() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, numStar),
      promotedTypeParameterTypeNone(T, numStar),
      strT0: 'T & num*',
      strT1: 'T & num*',
    );
  }

  test_typeParameter_04() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, numStar),
      promotedTypeParameterTypeNone(T, intStar),
      strT0: 'T & num*',
      strT1: 'T & int*',
    );
  }

  test_typeParameter_05() {
    var T = typeParameter('T');

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, numStar),
      strT0: 'Null?',
      strT1: 'T & num*',
    );
  }

  test_typeParameter_06() {
    var T = typeParameter('T', bound: intStar);

    isSubtype(
      promotedTypeParameterTypeStar(T, intStar),
      typeParameterTypeStar(T),
      strT0: 'T* & int*, T extends int*',
      strT1: 'T*, T extends int*',
    );
  }

  test_typeParameter_07() {
    var T = typeParameter('T', bound: numStar);

    isSubtype(
      promotedTypeParameterTypeStar(T, intStar),
      typeParameterTypeStar(T),
      strT0: 'T* & int*, T extends num*',
      strT1: 'T*, T extends num*',
    );
  }

  test_typeParameter_08() {
    var T = typeParameter('T', bound: numStar);

    isSubtype(
      promotedTypeParameterTypeStar(T, numStar),
      typeParameterTypeStar(T),
      strT0: 'T* & num*, T extends num*',
      strT1: 'T*, T extends num*',
    );
  }

  test_typeParameter_09() {
    var T = typeParameter('T', bound: intStar);

    isSubtype(
      typeParameterTypeStar(T),
      promotedTypeParameterTypeStar(T, intStar),
      strT0: 'T*, T extends int*',
      strT1: 'T* & int*, T extends int*',
    );
  }

  test_typeParameter_10() {
    var T = typeParameter('T', bound: intStar);

    isSubtype(
      typeParameterTypeStar(T),
      promotedTypeParameterTypeStar(T, numStar),
      strT0: 'T*, T extends int*',
      strT1: 'T* & num*, T extends int*',
    );
  }

  test_typeParameter_11() {
    var T = typeParameter('T', bound: numStar);

    isNotSubtype(
      typeParameterTypeStar(T),
      promotedTypeParameterTypeStar(T, intStar),
      strT0: 'T*, T extends num*',
      strT1: 'T* & int*, T extends num*',
    );
  }

  test_typeParameter_12() {
    var T = typeParameter('T', bound: numStar);

    isSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(T),
      strT0: 'T*, T extends num*',
      strT1: 'T*, T extends num*',
    );
  }

  test_typeParameter_13() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T',
      strT1: 'T',
    );
  }

  test_typeParameter_14() {
    var S = typeParameter('S');
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S',
      strT1: 'T',
    );
  }

  test_typeParameter_15() {
    var T = typeParameter('T', bound: objectStar);

    isSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(T),
      strT0: 'T*, T extends Object*',
      strT1: 'T*, T extends Object*',
    );
  }

  test_typeParameter_16() {
    var S = typeParameter('S', bound: objectStar);
    var T = typeParameter('T', bound: objectStar);

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S, S extends Object*',
      strT1: 'T, T extends Object*',
    );
  }

  test_typeParameter_17() {
    var T = typeParameter('T', bound: dynamicNone);

    isSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(T),
      strT0: 'T*, T extends dynamic',
      strT1: 'T*, T extends dynamic',
    );
  }

  test_typeParameter_18() {
    var S = typeParameter('S', bound: dynamicNone);
    var T = typeParameter('T', bound: dynamicNone);

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S, S extends dynamic',
      strT1: 'T, T extends dynamic',
    );
  }

  test_typeParameter_19() {
    var S = typeParameter('S');
    var T = typeParameter('T', bound: typeParameterTypeNone(S));

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S',
      strT1: 'T, T extends S',
    );

    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(S),
      strT0: 'T, T extends S',
      strT1: 'S',
    );
  }

  test_typeParameter_20() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intStar),
      intStar,
      strT0: 'T & int*',
      strT1: 'int*',
    );
  }

  test_typeParameter_21() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intStar),
      numStar,
      strT0: 'T & int*',
      strT1: 'num*',
    );
  }

  test_typeParameter_22() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, numStar),
      numStar,
      strT0: 'T & num*',
      strT1: 'num*',
    );
  }

  test_typeParameter_23() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, numStar),
      intStar,
      strT0: 'T & num*',
      strT1: 'int*',
    );
  }

  test_typeParameter_24() {
    var S = typeParameter('S');
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(S, numStar),
      typeParameterTypeNone(T),
      strT0: 'S & num*',
      strT1: 'T',
    );
  }

  test_typeParameter_25() {
    var S = typeParameter('S');
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(S, numStar),
      promotedTypeParameterTypeNone(T, numStar),
      strT0: 'S & num*',
      strT1: 'T & num*',
    );
  }

  test_typeParameter_26() {
    var S = typeParameter('S', bound: intStar);

    isSubtype(
      typeParameterTypeStar(S),
      intStar,
      strT0: 'S*, S extends int*',
      strT1: 'int*',
    );
  }

  test_typeParameter_27() {
    var S = typeParameter('S', bound: intStar);

    isSubtype(
      typeParameterTypeStar(S),
      numStar,
      strT0: 'S*, S extends int*',
      strT1: 'num*',
    );
  }

  test_typeParameter_28() {
    var S = typeParameter('S', bound: numStar);

    isSubtype(
      typeParameterTypeStar(S),
      numStar,
      strT0: 'S*, S extends num*',
      strT1: 'num*',
    );
  }

  test_typeParameter_29() {
    var S = typeParameter('S', bound: numStar);

    isNotSubtype(
      typeParameterTypeStar(S),
      intStar,
      strT0: 'S*, S extends num*',
      strT1: 'int*',
    );
  }

  test_typeParameter_30() {
    var S = typeParameter('S', bound: numStar);
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeStar(S),
      typeParameterTypeNone(T),
      strT0: 'S*, S extends num*',
      strT1: 'T',
    );
  }

  test_typeParameter_31() {
    var S = typeParameter('S', bound: numStar);
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeStar(S),
      promotedTypeParameterTypeNone(T, numStar),
      strT0: 'S*, S extends num*',
      strT1: 'T & num*',
    );
  }

  test_typeParameter_32() {
    var T = typeParameter('T', bound: dynamicNone);

    isNotSubtype(
      dynamicNone,
      promotedTypeParameterTypeNone(T, dynamicNone),
      strT0: 'dynamic',
      strT1: 'T & dynamic, T extends dynamic',
    );
  }

  test_typeParameter_33() {
    var T = typeParameter('T');

    isNotSubtype(
      functionTypeStar(
        returnType: typeParameterTypeNone(T),
      ),
      promotedTypeParameterTypeNone(
        T,
        functionTypeStar(
          returnType: typeParameterTypeNone(T),
        ),
      ),
      strT0: 'T Function()*',
      strT1: 'T & T Function()*',
    );
  }

  test_typeParameter_34() {
    var T = typeParameter('T');

    isNotSubtype(
      futureOrStar(
        promotedTypeParameterTypeNone(T, stringStar),
      ),
      promotedTypeParameterTypeNone(T, stringStar),
      strT0: 'FutureOr<T & String*>*',
      strT1: 'T & String*',
    );
  }

  test_typeParameter_35() {
    var T = typeParameter('T');

    isSubtype(
      nullStar,
      typeParameterTypeStar(T),
      strT0: 'Null*',
      strT1: 'T*',
    );
  }

  test_typeParameter_36() {
    var T = typeParameter('T', bound: numNone);

    isSubtype(
      typeParameterTypeNone(T),
      numNone,
      strT0: 'T, T extends num',
      strT1: 'num',
    );
  }

  test_typeParameter_37() {
    var T = typeParameter('T', bound: objectQuestion);

    var type = promotedTypeParameterTypeNone(T, numQuestion);

    isNotSubtype(
      type,
      numNone,
      strT0: 'T & num?, T extends Object?',
      strT1: 'num',
    );
    isSubtype(
      type,
      numQuestion,
      strT0: 'T & num?, T extends Object?',
      strT1: 'num?',
    );
    isSubtype(
      type,
      numStar,
      strT0: 'T & num?, T extends Object?',
      strT1: 'num*',
    );
  }

  test_typeParameter_38() {
    var T = typeParameter('T', bound: numStar);

    isSubtype(
      typeParameterTypeStar(T),
      objectNone,
      strT0: 'T*, T extends num*',
      strT1: 'Object',
    );
  }

  test_typeParameter_39() {
    var T = typeParameter('T', bound: numNone);

    isSubtype(
      typeParameterTypeNone(T),
      objectNone,
      strT0: 'T, T extends num',
      strT1: 'Object',
    );
  }

  test_typeParameter_40() {
    var T = typeParameter('T', bound: numNone);

    isNotSubtype(
      typeParameterTypeQuestion(T),
      objectNone,
      strT0: 'T?, T extends num',
      strT1: 'Object',
    );
  }

  test_typeParameter_41() {
    var T = typeParameter('T', bound: numQuestion);

    isNotSubtype(
      typeParameterTypeNone(T),
      objectNone,
      strT0: 'T, T extends num?',
      strT1: 'Object',
    );
  }

  test_typeParameter_42() {
    var T = typeParameter('T', bound: numQuestion);

    isNotSubtype(
      typeParameterTypeQuestion(T),
      objectNone,
      strT0: 'T?, T extends num?',
      strT1: 'Object',
    );
  }

  test_typeParameter_43() {
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(T),
      objectNone,
      strT0: 'T',
      strT1: 'Object',
    );
  }

  @FailingTest(issue: 'https://github.com/dart-lang/language/issues/433')
  test_typeParameter_44() {
    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);
    var FutureOr_T_none = futureOrNone(T_none);
    T.bound = FutureOr_T_none;

    isSubtype(
      T_none,
      FutureOr_T_none,
      strT0: 'T, T extends FutureOr<T>',
      strT1: 'FutureOr<T>, T extends FutureOr<T>',
    );
  }

  void _defineType(String str, DartType type) {
    for (var entry in _types.entries) {
      var key = entry.key;
      if (key == 'Never' || _typeStr(type) == 'Never') {
        // We have aliases for Never.
      } else {
        var value = entry.value;
        if (key == str) {
          fail('Duplicate type: $str;  existing: $value;  new: $type');
        }
        if (_typeStr(value) == _typeStr(type)) {
          fail('Duplicate type: $str');
        }
      }
    }
    _types[str] = type;
  }

  void _defineTypes() {
    _defineType('dynamic', dynamicNone);
    _defineType('void', voidNone);

    _defineType('Never', neverNone);
    _defineType('Never*', neverStar);
    _defineType('Never?', neverQuestion);

    _defineType('Null?', nullQuestion);

    _defineType('Object', objectNone);
    _defineType('Object*', objectStar);
    _defineType('Object?', objectQuestion);

    _defineType('Comparable<Object*>*', comparableStar(objectStar));
    _defineType('Comparable<num*>*', comparableStar(numStar));
    _defineType('Comparable<int*>*', comparableStar(intStar));

    _defineType('num', numNone);
    _defineType('num*', numStar);
    _defineType('num?', numQuestion);

    _defineType('int', intNone);
    _defineType('int*', intStar);
    _defineType('int?', intQuestion);

    _defineType('double', doubleNone);
    _defineType('double*', doubleStar);
    _defineType('double?', doubleQuestion);

    _defineType('List<Object*>*', listStar(objectStar));
    _defineType('List<num*>*', listStar(numStar));
    _defineType('List<int>', listNone(intNone));
    _defineType('List<int>*', listStar(intNone));
    _defineType('List<int>?', listQuestion(intNone));
    _defineType('List<int*>', listNone(intStar));
    _defineType('List<int*>*', listStar(intStar));
    _defineType('List<int*>?', listQuestion(intStar));
    _defineType('List<int?>', listNone(intQuestion));

    _defineType(
      'List<Comparable<Object*>*>*',
      listStar(
        comparableStar(objectStar),
      ),
    );
    _defineType(
      'List<Comparable<num*>*>*',
      listStar(
        comparableStar(numStar),
      ),
    );
    _defineType(
      'List<Comparable<Comparable<num*>*>*>*',
      listStar(
        comparableStar(
          comparableStar(numStar),
        ),
      ),
    );

    _defineType('Iterable<Object*>*', iterableStar(objectStar));
    _defineType('Iterable<int*>*', iterableStar(intStar));
    _defineType('Iterable<num*>*', iterableStar(numStar));

    _defineType('Function', functionNone);
    _defineType('Function*', functionStar);
    _defineType('Function?', functionQuestion);

    _defineType('FutureOr<Object*>*', futureOrStar(objectStar));
    _defineType('FutureOr<num*>*', futureOrStar(numStar));
    _defineType('FutureOr<int*>*', futureOrStar(intStar));
    _defineType('FutureOr<num?>?', futureOrQuestion(numQuestion));

    _defineType('FutureOr<Object>', futureOrNone(objectNone));
    _defineType('FutureOr<Object>?', futureOrQuestion(objectNone));
    _defineType('FutureOr<Object?>', futureOrNone(objectQuestion));
    _defineType('FutureOr<Object?>?', futureOrQuestion(objectQuestion));

    _defineType('Future<num>', futureNone(numNone));
    _defineType('Future<num>?', futureQuestion(numNone));
    _defineType('Future<num?>', futureNone(numQuestion));
    _defineType('Future<num?>?', futureQuestion(numQuestion));

    _defineType('FutureOr<int>', futureOrNone(intNone));
    _defineType('FutureOr<int>?', futureOrQuestion(intNone));
    _defineType('FutureOr<int?>', futureOrNone(intQuestion));
    _defineType('FutureOr<int?>?', futureOrQuestion(intQuestion));

    _defineType('FutureOr<int>*', futureOrStar(intNone));
    _defineType('FutureOr<int*>', futureOrNone(intStar));
    _defineType('Future<int*>*', futureStar(intStar));

    _defineType('FutureOr<num>', futureOrNone(numNone));
    _defineType('FutureOr<num>*', futureOrStar(numNone));
    _defineType('FutureOr<num>?', futureOrQuestion(numNone));

    _defineType('FutureOr<num*>', futureOrNone(numStar));
    _defineType('FutureOr<num?>', futureOrNone(numQuestion));

    _defineType('Future<Object>', futureNone(objectNone));
    _defineType(
      'FutureOr<Future<Object>>',
      futureOrNone(
        futureNone(objectNone),
      ),
    );
    _defineType(
      'FutureOr<Future<Object>>?',
      futureOrQuestion(
        futureNone(objectNone),
      ),
    );
    _defineType(
      'FutureOr<Future<Object>?>',
      futureOrNone(
        futureQuestion(objectNone),
      ),
    );
    _defineType(
      'FutureOr<Future<Object>?>?',
      futureOrQuestion(
        futureQuestion(objectNone),
      ),
    );

    _defineType(
      'Future<Future<num>>?',
      futureQuestion(
        futureNone(numNone),
      ),
    );
    _defineType(
      'Future<Future<num?>?>?',
      futureQuestion(
        futureQuestion(numQuestion),
      ),
    );

    _defineType(
      'Future<Future<Future<num>>>?',
      futureQuestion(
        futureNone(
          futureNone(numNone),
        ),
      ),
    );
    _defineType(
      'Future<Future<Future<num?>?>?>?',
      futureQuestion(
        futureQuestion(
          futureQuestion(numQuestion),
        ),
      ),
    );

    _defineType(
      'FutureOr<FutureOr<FutureOr<num>>?>',
      futureOrNone(
        futureOrQuestion(
          futureOrNone(numNone),
        ),
      ),
    );
    _defineType(
      'FutureOr<FutureOr<FutureOr<num?>>>',
      futureOrNone(
        futureOrNone(
          futureOrNone(numQuestion),
        ),
      ),
    );

    _defineType(
      'int* Function()',
      functionTypeNone(
        returnType: intStar,
      ),
    );
    _defineType(
      'int* Function()*',
      functionTypeStar(
        returnType: intStar,
      ),
    );
    _defineType(
      'int* Function()?',
      functionTypeQuestion(
        returnType: intStar,
      ),
    );

    _defineType(
      'num Function(num)',
      functionTypeNone(
        parameters: [requiredParameter(type: numNone)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num Function(num)?',
      functionTypeQuestion(
        parameters: [requiredParameter(type: numNone)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num Function(num)*',
      functionTypeStar(
        parameters: [requiredParameter(type: numNone)],
        returnType: numNone,
      ),
    );

    _defineType(
      'num* Function(num*)',
      functionTypeNone(
        parameters: [requiredParameter(type: numStar)],
        returnType: numStar,
      ),
    );
    _defineType(
      'num* Function(num*)*',
      functionTypeStar(
        parameters: [requiredParameter(type: numStar)],
        returnType: numStar,
      ),
    );
    _defineType(
      'num* Function(num*)?',
      functionTypeQuestion(
        parameters: [requiredParameter(type: numStar)],
        returnType: numStar,
      ),
    );

    _defineType(
      'int* Function(num*)*',
      functionTypeStar(
        parameters: [requiredParameter(type: numStar)],
        returnType: intStar,
      ),
    );

    _defineType(
      'num* Function(int*)',
      functionTypeNone(
        parameters: [requiredParameter(type: intStar)],
        returnType: numStar,
      ),
    );
    _defineType(
      'num* Function(int*)*',
      functionTypeStar(
        parameters: [requiredParameter(type: intStar)],
        returnType: numStar,
      ),
    );
    _defineType(
      'num* Function(int*)?',
      functionTypeQuestion(
        parameters: [requiredParameter(type: intStar)],
        returnType: numStar,
      ),
    );

    _defineType(
      'int* Function(int*)*',
      functionTypeStar(
        parameters: [requiredParameter(type: intStar)],
        returnType: intStar,
      ),
    );

    _defineType(
      'num Function(num?)',
      functionTypeNone(
        parameters: [requiredParameter(type: numQuestion)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num? Function(num)',
      functionTypeNone(
        parameters: [requiredParameter(type: numNone)],
        returnType: numQuestion,
      ),
    );
    _defineType(
      'num? Function(num?)',
      functionTypeNone(
        parameters: [requiredParameter(type: numQuestion)],
        returnType: numQuestion,
      ),
    );

    _defineType(
      'num Function({num x})',
      functionTypeNone(
        parameters: [namedParameter(name: 'x', type: numNone)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num Function({num? x})',
      functionTypeNone(
        parameters: [namedParameter(name: 'x', type: numQuestion)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num? Function({num x})',
      functionTypeNone(
        parameters: [namedParameter(name: 'x', type: numNone)],
        returnType: numQuestion,
      ),
    );
    _defineType(
      'num? Function({num? x})',
      functionTypeNone(
        parameters: [namedParameter(name: 'x', type: numQuestion)],
        returnType: numQuestion,
      ),
    );

    _defineType(
      'num Function([num])',
      functionTypeNone(
        parameters: [positionalParameter(type: numNone)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num Function([num?])',
      functionTypeNone(
        parameters: [positionalParameter(type: numQuestion)],
        returnType: numNone,
      ),
    );
    _defineType(
      'num? Function([num])',
      functionTypeNone(
        parameters: [positionalParameter(type: numNone)],
        returnType: numQuestion,
      ),
    );
    _defineType(
      'num? Function([num?])',
      functionTypeNone(
        parameters: [positionalParameter(type: numQuestion)],
        returnType: numQuestion,
      ),
    );
  }

  DartType _getTypeByStr(String str) {
    var type = _types[str];
    if (type == null) {
      fail('No DartType for: $str');
    }
    return type;
  }

  String _typeParametersStr(DartType type) {
    var typeStr = '';

    var typeParameterCollector = _TypeParameterCollector();
    type.accept(typeParameterCollector);
    for (var typeParameter in typeParameterCollector.typeParameters) {
      typeStr += ', $typeParameter';
    }
    return typeStr;
  }

  static String _typeStr(DartType type) {
    return type.getDisplayString(withNullability: true);
  }
}

@reflectiveTest
class SubtypingCompoundTest extends _SubtypingTestBase {
  test_bottom_isBottom() {
    var equivalents = <DartType>[neverStar];

    var supertypes = <DartType>[
      dynamicNone,
      objectStar,
      intStar,
      doubleStar,
      numStar,
      stringStar,
      functionStar,
    ];

    _checkGroups(
      neverStar,
      equivalents: equivalents,
      supertypes: supertypes,
    );
  }

  test_double() {
    var equivalents = <DartType>[doubleStar];
    var supertypes = <DartType>[numStar];
    var unrelated = <DartType>[intStar];
    _checkGroups(
      doubleStar,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
    );
  }

  test_dynamic() {
    var equivalents = <DartType>[
      voidNone,
      objectQuestion,
      objectStar,
    ];

    var subtypes = <DartType>[
      neverNone,
      nullNone,
      objectNone,
    ];

    _checkGroups(
      dynamicNone,
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }

  test_dynamic_isTop() {
    var equivalents = <DartType>[
      dynamicNone,
      objectStar,
      voidNone,
    ];

    var subtypes = <DartType>[
      intStar,
      doubleStar,
      numStar,
      stringStar,
      functionStar,
      neverStar,
    ];

    _checkGroups(
      dynamicType,
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }

  test_futureOr_topTypes() {
    var futureOrObject = futureOrNone(objectNone);
    var futureOrObjectStar = futureOrNone(objectStar);
    var futureOrObjectQuestion = futureOrNone(objectQuestion);

    var futureOrStarObject = futureOrStar(objectNone);
    var futureOrStarObjectStar = futureOrStar(objectStar);
    var futureOrStarObjectQuestion = futureOrStar(objectQuestion);

    var futureOrQuestionObject = futureOrQuestion(objectNone);
    var futureOrQuestionObjectStar = futureOrQuestion(objectStar);
    var futureOrQuestionObjectQuestion = futureOrQuestion(objectQuestion);

    //FutureOr<Object> <: FutureOr*<Object?>
    _checkGroups(
      futureOrObject,
      equivalents: [
        objectStar,
        futureOrObjectStar,
        futureOrStarObject,
        futureOrStarObjectStar,
        objectNone,
      ],
      subtypes: [],
      supertypes: [
        objectQuestion,
        futureOrQuestionObject,
        futureOrObjectQuestion,
        futureOrQuestionObject,
        futureOrQuestionObjectStar,
        futureOrStarObjectQuestion,
        futureOrQuestionObjectQuestion,
      ],
    );
  }

  test_int() {
    var equivalents = <DartType>[intStar];
    var supertypes = <DartType>[numStar];
    var unrelated = <DartType>[doubleStar];
    _checkGroups(
      intStar,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
    );
  }

  test_intNone() {
    var equivalents = <DartType>[
      intNone,
      intStar,
    ];

    var subtypes = <DartType>[
      neverNone,
    ];

    var supertypes = <DartType>[
      intQuestion,
      objectNone,
      objectQuestion,
    ];

    var unrelated = <DartType>[
      doubleNone,
      nullNone,
      nullStar,
      nullQuestion,
      neverQuestion,
    ];

    _checkGroups(
      intNone,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_intQuestion() {
    var equivalents = <DartType>[
      intQuestion,
      intStar,
    ];

    var subtypes = <DartType>[
      intNone,
      nullNone,
      nullQuestion,
      nullStar,
      neverNone,
      neverQuestion,
      neverStar,
    ];

    var supertypes = <DartType>[
      numQuestion,
      numStar,
      objectQuestion,
      objectStar,
    ];

    var unrelated = <DartType>[
      doubleNone,
      numNone,
      objectNone,
    ];

    _checkGroups(
      intQuestion,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_intStar() {
    var equivalents = <DartType>[
      intNone,
      intQuestion,
      intStar,
    ];

    var subtypes = <DartType>[
      nullNone,
      nullStar,
      nullQuestion,
      neverNone,
      neverStar,
      neverQuestion,
    ];

    var supertypes = <DartType>[
      numNone,
      numQuestion,
      numStar,
      objectNone,
      objectQuestion,
    ];

    var unrelated = <DartType>[
      doubleStar,
    ];

    _checkGroups(
      intStar,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_null() {
    var equivalents = <DartType>[
      nullNone,
      nullQuestion,
      nullStar,
      neverQuestion,
    ];

    var supertypes = <DartType>[
      intQuestion,
      intStar,
      objectQuestion,
      objectStar,
      dynamicNone,
      voidNone,
    ];

    var subtypes = <DartType>[
      neverNone,
    ];

    var unrelated = <DartType>[
      doubleNone,
      intNone,
      numNone,
      objectNone,
    ];

    for (final formOfNull in equivalents) {
      _checkGroups(
        formOfNull,
        equivalents: equivalents,
        supertypes: supertypes,
        unrelated: unrelated,
        subtypes: subtypes,
      );
    }
  }

  test_num() {
    var equivalents = <DartType>[numStar];
    var supertypes = <DartType>[objectStar];
    var unrelated = <DartType>[stringStar];
    var subtypes = <DartType>[intStar, doubleStar];
    _checkGroups(
      numStar,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_object() {
    var equivalents = <DartType>[
      objectStar,
    ];

    var supertypes = <DartType>[
      objectQuestion,
      dynamicType,
      voidNone,
    ];

    var subtypes = <DartType>[
      neverNone,
    ];

    var unrelated = <DartType>[
      doubleQuestion,
      numQuestion,
      intQuestion,
      nullNone,
    ];

    _checkGroups(
      objectNone,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_void_isTop() {
    var equivalents = <DartType>[
      dynamicNone,
      objectStar,
      voidNone,
    ];

    var subtypes = <DartType>[
      intStar,
      doubleStar,
      numStar,
      stringStar,
      functionStar,
      neverStar,
    ];

    _checkGroups(
      voidNone,
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }

  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsSubtypeOf(type2, type1);
  }

  void _checkGroups(DartType t1,
      {List<DartType>? equivalents,
      List<DartType>? unrelated,
      List<DartType>? subtypes,
      List<DartType>? supertypes}) {
    if (equivalents != null) {
      for (DartType t2 in equivalents) {
        _checkEquivalent(t1, t2);
      }
    }
    if (unrelated != null) {
      for (DartType t2 in unrelated) {
        _checkUnrelated(t1, t2);
      }
    }
    if (subtypes != null) {
      for (DartType t2 in subtypes) {
        _checkIsStrictSubtypeOf(t2, t1);
      }
    }
    if (supertypes != null) {
      for (DartType t2 in supertypes) {
        _checkIsStrictSubtypeOf(t1, t2);
      }
    }
  }

  void _checkIsNotSubtypeOf(DartType type1, DartType type2) {
    var strType1 = _typeStr(type1);
    var strType2 = _typeStr(type2);
    expect(typeSystem.isSubtypeOf(type1, type2), false,
        reason: '$strType1 was not supposed to be a subtype of $strType2');
  }

  void _checkIsStrictSubtypeOf(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  void _checkIsSubtypeOf(DartType type1, DartType type2) {
    var strType1 = _typeStr(type1);
    var strType2 = _typeStr(type2);
    expect(typeSystem.isSubtypeOf(type1, type2), true,
        reason: '$strType1 is not a subtype of $strType2');
  }

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  static String _typeStr(DartType type) {
    return type.getDisplayString(withNullability: true);
  }
}

class _SubtypingTestBase extends AbstractTypeSystemTest {}

class _TypeParameterCollector extends TypeVisitor<void> {
  final Set<String> typeParameters = {};

  /// We don't need to print bounds for these type parameters, because
  /// they are already included into the function type itself, and cannot
  /// be promoted.
  final Set<TypeParameterElement> functionTypeParameters = {};

  @override
  void visitDynamicType(DynamicType type) {}

  @override
  void visitFunctionType(FunctionType type) {
    functionTypeParameters.addAll(type.typeFormals);
    for (var typeParameter in type.typeFormals) {
      var bound = typeParameter.bound;
      if (bound != null) {
        bound.accept(this);
      }
    }
    for (var parameter in type.parameters) {
      parameter.type.accept(this);
    }
    type.returnType.accept(this);
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    for (var typeArgument in type.typeArguments) {
      typeArgument.accept(this);
    }
  }

  @override
  void visitNeverType(NeverType type) {}

  @override
  void visitTypeParameterType(TypeParameterType type) {
    if (!functionTypeParameters.contains(type.element)) {
      var bound = type.element.bound;

      if (bound == null) {
        return;
      }

      var str = '';

      var boundStr = bound.getDisplayString(withNullability: true);
      str += '${type.element.name} extends ' + boundStr;

      typeParameters.add(str);
    }
  }

  @override
  void visitVoidType(VoidType type) {}
}
