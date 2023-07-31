// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopMergeTest);
  });
}

@reflectiveTest
class TopMergeTest extends AbstractTypeSystemTest {
  test_differentStructure() {
    _checkThrows(
      intNone,
      functionTypeNone(returnType: voidNone),
    );

    _checkThrows(
      intNone,
      typeParameterTypeNone(typeParameter('T')),
    );

    _checkThrows(
      functionTypeNone(returnType: voidNone),
      typeParameterTypeNone(typeParameter('T')),
    );
  }

  test_dynamic() {
    // NNBD_TOP_MERGE(dynamic, dynamic) = dynamic
    _check(dynamicNone, dynamicNone, dynamicNone);
  }

  test_function() {
    _check(
      functionTypeNone(returnType: voidNone),
      functionTypeNone(returnType: objectQuestion),
      functionTypeNone(returnType: objectQuestion),
    );

    _check(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: objectQuestion, name: 'a'),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: dynamicNone, name: 'a'),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: objectQuestion, name: 'a'),
        ],
      ),
    );
  }

  test_function_covariant() {
    _check(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: objectQuestion, isCovariant: true),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: dynamicNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: objectQuestion, isCovariant: true),
        ],
      ),
    );

    _check(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: intNone, isCovariant: true),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: numNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: numNone, isCovariant: true),
        ],
      ),
    );
  }

  test_function_parameters_mismatch() {
    _check(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: intNone, name: 'a'),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: intNone, name: 'b'),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: intNone, name: 'a'),
        ],
      ),
    );

    _checkThrows(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(type: intNone),
        ],
      ),
    );

    _checkThrows(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(type: intNone, name: 'a'),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(type: intNone, name: 'b'),
        ],
      ),
    );
  }

  test_function_typeParameters_boundsMerge() {
    var T1 = typeParameter('T', bound: intNone);
    var T2 = typeParameter('T', bound: intStar);
    var TR = typeParameter('T', bound: intNone);
    _check(
      functionTypeNone(
        typeFormals: [T1],
        returnType: typeParameterTypeNone(T1),
      ),
      functionTypeNone(
        typeFormals: [T2],
        returnType: typeParameterTypeNone(T2),
      ),
      functionTypeNone(
        typeFormals: [TR],
        returnType: typeParameterTypeNone(TR),
      ),
    );
  }

  test_function_typeParameters_boundsMismatch() {
    var T1 = typeParameter('T', bound: intNone);
    var T2 = typeParameter('T');
    _checkThrows(
      functionTypeNone(
        typeFormals: [T1],
        returnType: typeParameterTypeNone(T1),
      ),
      functionTypeNone(
        typeFormals: [T2],
        returnType: typeParameterTypeNone(T2),
      ),
    );
  }

  test_interface() {
    _check(
      listNone(dynamicNone),
      listNone(objectQuestion),
      listNone(objectQuestion),
    );

    _check(
      listNone(voidNone),
      listNone(objectQuestion),
      listNone(objectQuestion),
    );

    _check(
      listQuestion(intNone),
      listStar(intNone),
      listQuestion(intNone),
    );
    _check(
      listNone(intQuestion),
      listNone(intStar),
      listNone(intQuestion),
    );

    _checkThrows(
      iterableNone(intNone),
      listNone(intNone),
    );
  }

  test_never() {
    _check(neverNone, neverNone, neverNone);
  }

  test_null() {
    // NNBD_TOP_MERGE(Never*, Null) = Null
    // NNBD_TOP_MERGE(Null, Never*) = Null
    _check(neverStar, nullNone, nullNone);
  }

  test_nullability() {
    // NNBD_TOP_MERGE(T?, S?) = NNBD_TOP_MERGE(T, S)?
    _check(intQuestion, intQuestion, intQuestion);

    // NNBD_TOP_MERGE(T?, S*) = NNBD_TOP_MERGE(T, S)?
    _check(intQuestion, intStar, intQuestion);

    // NNBD_TOP_MERGE(T*, S?) = NNBD_TOP_MERGE(T, S)?
    _check(intStar, intQuestion, intQuestion);

    // NNBD_TOP_MERGE(T*, S*) = NNBD_TOP_MERGE(T, S)*
    _check(intStar, intStar, intStar);

    // NNBD_TOP_MERGE(T*, S) = NNBD_TOP_MERGE(T, S)
    _check(intStar, intNone, intNone);

    // NNBD_TOP_MERGE(T, S*) = NNBD_TOP_MERGE(T, S)
    _check(intNone, intStar, intNone);
  }

  test_objectQuestion() {
    // NNBD_TOP_MERGE(Object?, Object?) = Object?
    _check(objectQuestion, objectQuestion, objectQuestion);

    // NNBD_TOP_MERGE(Object?, void) = Object?
    // NNBD_TOP_MERGE(void, Object?) = Object?
    _check(objectQuestion, voidNone, objectQuestion);

    // NNBD_TOP_MERGE(Object?, dynamic) = Object?
    // NNBD_TOP_MERGE(dynamic, Object?) = Object?
    _check(objectQuestion, dynamicNone, objectQuestion);
  }

  test_objectStar() {
    // NNBD_TOP_MERGE(Object*, void) = Object?
    // NNBD_TOP_MERGE(void, Object*) = Object?
    _check(objectStar, voidNone, objectQuestion);

    // NNBD_TOP_MERGE(Object*, dynamic) = Object?
    // NNBD_TOP_MERGE(dynamic, Object*) = Object?
    _check(objectStar, dynamicNone, objectQuestion);
  }

  test_typeParameter() {
    var T = typeParameter('T');

    _check(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
    );

    var S = typeParameter('T');
    _checkThrows(
      typeParameterTypeNone(T),
      typeParameterTypeNone(S),
    );
    _checkThrows(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
    );
  }

  test_void() {
    // NNBD_TOP_MERGE(void, void) = void
    _check(voidNone, voidNone, voidNone);

    // NNBD_TOP_MERGE(void, dynamic) = Object?
    // NNBD_TOP_MERGE(dynamic, void) = Object?
    _check(voidNone, dynamicNone, objectQuestion);
  }

  void _check(DartType T, DartType S, DartType expected) {
    var result = typeSystem.topMerge(T, S);
    if (result != expected) {
      var expectedStr = expected.getDisplayString(withNullability: true);
      var resultStr = result.getDisplayString(withNullability: true);
      fail('Expected: $expectedStr, actual: $resultStr');
    }

    result = typeSystem.topMerge(S, T);
    if (result != expected) {
      var expectedStr = expected.getDisplayString(withNullability: true);
      var resultStr = result.getDisplayString(withNullability: true);
      fail('Expected: $expectedStr, actual: $resultStr');
    }
  }

  void _checkThrows(DartType T, DartType S) {
    expect(() {
      return typeSystem.topMerge(T, S);
    }, throwsA(anything));

    expect(() {
      return typeSystem.topMerge(S, T);
    }, throwsA(anything));
  }
}
