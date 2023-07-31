// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignabilityWithoutNullSafetyTest);
    defineReflectiveTests(TryPromoteToTest);
  });
}

@reflectiveTest
class AssignabilityWithoutNullSafetyTest
    extends AbstractTypeSystemWithoutNullSafetyTest {
  void test_isAssignableTo_bottom_isBottom() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectStar,
      intStar,
      doubleStar,
      numStar,
      stringStar,
      interfaceTypeStar(A),
      neverStar,
    ];

    _checkGroups(neverStar, interassignable: interassignable);
  }

  void test_isAssignableTo_call_method() {
    var B = class_(
      name: 'B',
      methods: [
        method('call', objectStar, parameters: [
          requiredParameter(name: '_', type: intStar),
        ]),
      ],
    );

    B.enclosingElement = testLibrary.definingCompilationUnit;

    _checkIsStrictAssignableTo(
      interfaceTypeStar(B),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: objectStar,
      ),
    );
  }

  void test_isAssignableTo_classes() {
    var classTop = class_(name: 'A');
    var classLeft = class_(name: 'B', superType: interfaceTypeStar(classTop));
    var classRight = class_(name: 'C', superType: interfaceTypeStar(classTop));
    var classBottom = class_(
      name: 'D',
      superType: interfaceTypeStar(classLeft),
      interfaces: [interfaceTypeStar(classRight)],
    );
    var top = interfaceTypeStar(classTop);
    var left = interfaceTypeStar(classLeft);
    var right = interfaceTypeStar(classRight);
    var bottom = interfaceTypeStar(classBottom);

    _checkLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_double() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectStar,
      doubleStar,
      numStar,
      neverStar,
    ];
    List<DartType> unrelated = <DartType>[
      intStar,
      stringStar,
      interfaceTypeStar(A),
    ];

    _checkGroups(doubleStar,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_dynamic_isTop() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectStar,
      intStar,
      doubleStar,
      numStar,
      stringStar,
      interfaceTypeStar(A),
      neverStar,
    ];
    _checkGroups(dynamicType, interassignable: interassignable);
  }

  void test_isAssignableTo_generics() {
    var LT = typeParameter('T');
    var L = class_(name: 'L', typeParameters: [LT]);

    var MT = typeParameter('T');
    var M = class_(
      name: 'M',
      typeParameters: [MT],
      interfaces: [
        interfaceTypeStar(
          L,
          typeArguments: [
            typeParameterTypeStar(MT),
          ],
        ),
      ],
    );

    var top = interfaceTypeStar(L, typeArguments: [dynamicType]);
    var left = interfaceTypeStar(M, typeArguments: [dynamicType]);
    var right = interfaceTypeStar(L, typeArguments: [intStar]);
    var bottom = interfaceTypeStar(M, typeArguments: [intStar]);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_int() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectStar,
      intStar,
      numStar,
      neverStar,
    ];
    List<DartType> unrelated = <DartType>[
      doubleStar,
      stringStar,
      interfaceTypeStar(A),
    ];

    _checkGroups(intStar,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_named_optional() {
    var r = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var o = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var n = functionTypeStar(
      parameters: [
        namedParameter(name: 'x', type: intStar),
      ],
      returnType: intStar,
    );

    var rr = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        requiredParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var ro = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        positionalParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var rn = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
        namedParameter(name: 'x', type: intStar),
      ],
      returnType: intStar,
    );
    var oo = functionTypeStar(
      parameters: [
        positionalParameter(type: intStar),
        positionalParameter(type: intStar),
      ],
      returnType: intStar,
    );
    var nn = functionTypeStar(
      parameters: [
        namedParameter(name: 'x', type: intStar),
        namedParameter(name: 'y', type: intStar),
      ],
      returnType: intStar,
    );
    var nnn = functionTypeStar(
      parameters: [
        namedParameter(name: 'x', type: intStar),
        namedParameter(name: 'y', type: intStar),
        namedParameter(name: 'z', type: intStar),
      ],
      returnType: intStar,
    );

    _checkGroups(r,
        interassignable: [r, o, ro, rn, oo], unrelated: [n, rr, nn, nnn]);
    _checkGroups(o,
        interassignable: [o, oo], unrelated: [n, rr, ro, rn, nn, nnn]);
    _checkGroups(n,
        interassignable: [n, nn, nnn], unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(rr,
        interassignable: [rr, ro, oo], unrelated: [r, o, n, rn, nn, nnn]);
    _checkGroups(ro, interassignable: [ro, oo], unrelated: [o, n, rn, nn, nnn]);
    _checkGroups(rn,
        interassignable: [rn], unrelated: [o, n, rr, ro, oo, nn, nnn]);
    _checkGroups(oo, interassignable: [oo], unrelated: [n, rn, nn, nnn]);
    _checkGroups(nn,
        interassignable: [nn, nnn], unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(nnn,
        interassignable: [nnn], unrelated: [r, o, rr, ro, rn, oo]);
  }

  void test_isAssignableTo_num() {
    var A = class_(name: 'A');
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectStar,
      numStar,
      intStar,
      doubleStar,
      neverStar,
    ];
    List<DartType> unrelated = <DartType>[
      stringStar,
      interfaceTypeStar(A),
    ];

    _checkGroups(numStar,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_simple_function() {
    var top = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: objectStar,
    );

    var left = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: intStar,
    );

    var right = functionTypeStar(
      parameters: [
        requiredParameter(type: objectStar),
      ],
      returnType: objectStar,
    );

    var bottom = functionTypeStar(
      parameters: [
        requiredParameter(type: objectStar),
      ],
      returnType: intStar,
    );

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_void_functions() {
    var top = functionTypeStar(
      parameters: [
        requiredParameter(type: intStar),
      ],
      returnType: voidNone,
    );

    var bottom = functionTypeStar(
      parameters: [
        requiredParameter(type: objectStar),
      ],
      returnType: intStar,
    );

    _checkEquivalent(bottom, top);
  }

  void _checkCrossLattice(
      DartType top, DartType left, DartType right, DartType bottom) {
    _checkGroups(top, interassignable: [top, left, right, bottom]);
    _checkGroups(left,
        interassignable: [top, left, bottom], unrelated: [right]);
    _checkGroups(right,
        interassignable: [top, right, bottom], unrelated: [left]);
    _checkGroups(bottom, interassignable: [top, left, right, bottom]);
  }

  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsAssignableTo(type1, type2);
    _checkIsAssignableTo(type2, type1);
  }

  void _checkGroups(DartType t1,
      {List<DartType>? interassignable, List<DartType>? unrelated}) {
    if (interassignable != null) {
      for (DartType t2 in interassignable) {
        _checkEquivalent(t1, t2);
      }
    }
    if (unrelated != null) {
      for (DartType t2 in unrelated) {
        _checkUnrelated(t1, t2);
      }
    }
  }

  void _checkIsAssignableTo(DartType type1, DartType type2) {
    expect(typeSystem.isAssignableTo(type1, type2), true);
  }

  void _checkIsNotAssignableTo(DartType type1, DartType type2) {
    expect(typeSystem.isAssignableTo(type1, type2), false);
  }

  void _checkIsStrictAssignableTo(DartType type1, DartType type2) {
    _checkIsAssignableTo(type1, type2);
    _checkIsNotAssignableTo(type2, type1);
  }

  void _checkLattice(
      DartType top, DartType left, DartType right, DartType bottom) {
    _checkGroups(top, interassignable: <DartType>[top, left, right, bottom]);
    _checkGroups(left,
        interassignable: <DartType>[top, left, bottom],
        unrelated: <DartType>[right]);
    _checkGroups(right,
        interassignable: <DartType>[top, right, bottom],
        unrelated: <DartType>[left]);
    _checkGroups(bottom, interassignable: <DartType>[top, left, right, bottom]);
  }

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotAssignableTo(type1, type2);
    _checkIsNotAssignableTo(type2, type1);
  }
}

@reflectiveTest
class TryPromoteToTest extends AbstractTypeSystemTest {
  void notPromotes(DartType from, DartType to) {
    var result = typeSystem.tryPromoteToType(to, from);
    expect(result, isNull);
  }

  void promotes(DartType from, DartType to) {
    var result = typeSystem.tryPromoteToType(to, from);
    expect(result, to);
  }

  test_interface() {
    promotes(intNone, intNone);
    promotes(intQuestion, intNone);
    promotes(intStar, intNone);

    promotes(numNone, intNone);
    promotes(numQuestion, intNone);
    promotes(numStar, intNone);

    notPromotes(intNone, doubleNone);
    notPromotes(intNone, intQuestion);
  }

  test_typeParameter() {
    TypeParameterTypeImpl tryPromote(DartType to, TypeParameterTypeImpl from) {
      return typeSystem.tryPromoteToType(to, from) as TypeParameterTypeImpl;
    }

    void check(TypeParameterTypeImpl type, String expected) {
      expect(type.getDisplayString(withNullability: true), expected);
    }

    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);
    var T_question = typeParameterTypeQuestion(T);
    var T_star = typeParameterTypeStar(T);

    check(tryPromote(numNone, T_none), 'T & num');
    check(tryPromote(numQuestion, T_none), 'T & num?');
    check(tryPromote(numStar, T_none), 'T & num*');

    check(tryPromote(numNone, T_question), 'T & num');
    check(tryPromote(numQuestion, T_question), '(T & num?)?');
    check(tryPromote(numStar, T_question), '(T & num*)*');

    check(tryPromote(numNone, T_star), '(T & num)*');
    check(tryPromote(numQuestion, T_star), '(T & num?)*');
    check(tryPromote(numStar, T_star), '(T & num*)*');
  }

  test_typeParameter_twice() {
    TypeParameterTypeImpl tryPromote(DartType to, TypeParameterTypeImpl from) {
      return typeSystem.tryPromoteToType(to, from) as TypeParameterTypeImpl;
    }

    void check(
      TypeParameterTypeImpl type,
      TypeParameterElement element,
      NullabilitySuffix nullability,
      DartType promotedBound,
    ) {
      expect(type.element, element);
      expect(type.nullabilitySuffix, nullability);
      expect(type.promotedBound, promotedBound);
    }

    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);

    var T1 = tryPromote(numNone, T_none);
    check(T1, T, NullabilitySuffix.none, numNone);

    var T2 = tryPromote(intNone, T1);
    check(T2, T, NullabilitySuffix.none, intNone);
  }
}
