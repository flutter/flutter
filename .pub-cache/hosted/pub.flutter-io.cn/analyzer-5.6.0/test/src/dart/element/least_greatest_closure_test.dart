// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GreatestClosureTest);
    defineReflectiveTests(GreatestClosureWithoutNullSafetyTest);
  });
}

@reflectiveTest
class GreatestClosureTest extends AbstractTypeSystemTest {
  late final TypeParameterElement T;
  late final TypeParameterType T_none;
  late final TypeParameterType T_question;
  late final TypeParameterType T_star;

  @override
  void setUp() {
    super.setUp();

    T = typeParameter('T');
    T_none = typeParameterTypeNone(T);
    T_question = typeParameterTypeQuestion(T);
    T_star = typeParameterTypeStar(T);
  }

  test_contravariant() {
    _check(
      functionTypeNone(returnType: voidNone, parameters: [
        requiredParameter(type: T_none),
      ]),
      greatest: 'void Function(Never)',
      least: 'void Function(Object?)',
    );

    _check(
      functionTypeNone(
        returnType: functionTypeNone(
          returnType: voidNone,
          parameters: [
            requiredParameter(type: T_none),
          ],
        ),
      ),
      greatest: 'void Function(Never) Function()',
      least: 'void Function(Object?) Function()',
    );
  }

  test_covariant() {
    _check(T_none, greatest: 'Object?', least: 'Never');
    _check(T_question, greatest: 'Object?', least: 'Never?');
    _check(T_star, greatest: 'Object?', least: 'Never*');

    _check(
      listNone(T_none),
      greatest: 'List<Object?>',
      least: 'List<Never>',
    );

    _check(
        functionTypeNone(returnType: voidNone, parameters: [
          requiredParameter(
            type: functionTypeNone(returnType: intNone, parameters: [
              requiredParameter(type: T_none),
            ]),
          ),
        ]),
        greatest: 'void Function(int Function(Object?))',
        least: 'void Function(int Function(Never))');
  }

  test_function() {
    // void Function<U extends T>()
    _check(
      functionTypeNone(
        typeFormals: [
          typeParameter('U', bound: T_none),
        ],
        returnType: voidNone,
      ),
      greatest: 'Function',
      least: 'Never',
    );
  }

  test_unrelated() {
    _check1(intNone, 'int');
    _check1(intQuestion, 'int?');
    _check1(intStar, 'int*');

    _check1(listNone(intNone), 'List<int>');
    _check1(listQuestion(intNone), 'List<int>?');

    _check1(objectNone, 'Object');
    _check1(objectQuestion, 'Object?');
    _check1(objectStar, 'Object*');

    _check1(neverNone, 'Never');
    _check1(neverQuestion, 'Never?');
    _check1(neverStar, 'Never*');

    _check1(dynamicNone, 'dynamic');

    _check1(
      functionTypeNone(returnType: stringNone, parameters: [
        requiredParameter(type: intNone),
      ]),
      'String Function(int)',
    );

    _check1(
      typeParameterTypeNone(
        typeParameter('U'),
      ),
      'U',
    );
  }

  void _check(
    DartType type, {
    required String greatest,
    required String least,
  }) {
    var greatestResult = typeSystem.greatestClosure(type, [T]);
    expect(
      greatestResult.getDisplayString(withNullability: true),
      greatest,
    );

    var leastResult = typeSystem.leastClosure(type, [T]);
    expect(
      leastResult.getDisplayString(withNullability: true),
      least,
    );
  }

  void _check1(DartType type, String expected) {
    _check(type, greatest: expected, least: expected);
  }
}

@reflectiveTest
class GreatestClosureWithoutNullSafetyTest
    extends AbstractTypeSystemWithoutNullSafetyTest {
  late final TypeParameterElement T;
  late final TypeParameterType T_none;
  late final TypeParameterType T_question;
  late final TypeParameterType T_star;

  @override
  void setUp() {
    super.setUp();

    T = typeParameter('T');
    T_none = typeParameterTypeNone(T);
    T_question = typeParameterTypeQuestion(T);
    T_star = typeParameterTypeStar(T);
  }

  test_contravariant() {
    _check(
      functionTypeStar(returnType: voidNone, parameters: [
        requiredParameter(type: T_star),
      ]),
      greatest: 'void Function(Null*)*',
      least: 'void Function(dynamic)*',
    );

    _check(
      functionTypeStar(
        returnType: functionTypeStar(
          returnType: voidNone,
          parameters: [
            requiredParameter(type: T_star),
          ],
        ),
      ),
      greatest: 'void Function(Null*)* Function()*',
      least: 'void Function(dynamic)* Function()*',
    );
  }

  test_covariant() {
    _check(T_star, greatest: 'dynamic', least: 'Null*');

    _check(
      listStar(T_star),
      greatest: 'List<dynamic>*',
      least: 'List<Null*>*',
    );

    _check(
      functionTypeStar(returnType: voidNone, parameters: [
        requiredParameter(
          type: functionTypeStar(returnType: intStar, parameters: [
            requiredParameter(type: T_star),
          ]),
        ),
      ]),
      greatest: 'void Function(int* Function(dynamic)*)*',
      least: 'void Function(int* Function(Null*)*)*',
    );
  }

  test_function() {
    // void Function<U extends T>()
    _check(
      functionTypeStar(
        typeFormals: [
          typeParameter('U', bound: T_star),
        ],
        returnType: voidNone,
      ),
      greatest: 'Function*',
      least: 'Null*',
    );
  }

  test_unrelated() {
    _check1(intStar, 'int*');
    _check1(listStar(intStar), 'List<int*>*');

    _check1(objectStar, 'Object*');
    _check1(neverStar, 'Never*');
    _check1(nullStar, 'Null*');

    _check1(dynamicNone, 'dynamic');

    _check1(
      functionTypeStar(returnType: stringStar, parameters: [
        requiredParameter(type: intStar),
      ]),
      'String* Function(int*)*',
    );

    _check1(
      typeParameterTypeStar(
        typeParameter('U'),
      ),
      'U*',
    );
  }

  void _check(
    DartType type, {
    required String greatest,
    required String least,
  }) {
    var greatestResult = typeSystem.greatestClosure(type, [T]);
    expect(
      greatestResult.getDisplayString(withNullability: true),
      greatest,
    );

    var leastResult = typeSystem.leastClosure(type, [T]);
    expect(
      leastResult.getDisplayString(withNullability: true),
      least,
    );
  }

  void _check1(DartType type, String expected) {
    _check(type, greatest: expected, least: expected);
  }
}
