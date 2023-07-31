// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DynamicBoundedTest);
    defineReflectiveTests(FunctionBoundedTest);
  });
}

@reflectiveTest
class DynamicBoundedTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _assertDynamicBounded(dynamicNone);
  }

  test_dynamic_typeParameter_hasBound_dynamic() {
    var T = typeParameter('T', bound: dynamicNone);

    _assertDynamicBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasBound_notDynamic() {
    var T = typeParameter('T', bound: intNone);

    _assertNotDynamicBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_dynamic() {
    var T = typeParameter('T');

    _assertDynamicBounded(
      typeParameterTypeNone(T, promotedBound: dynamicNone),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_notDynamic() {
    var T = typeParameter('T');

    _assertNotDynamicBounded(
      typeParameterTypeNone(T, promotedBound: intNone),
    );
  }

  test_dynamic_typeParameter_noBound() {
    var T = typeParameter('T');

    _assertNotDynamicBounded(
      typeParameterTypeNone(T),
    );
  }

  test_functionType() {
    _assertNotDynamicBounded(
      functionTypeNone(returnType: voidNone),
    );

    _assertNotDynamicBounded(
      functionTypeNone(returnType: dynamicNone),
    );
  }

  test_interfaceType() {
    _assertNotDynamicBounded(intNone);
    _assertNotDynamicBounded(intQuestion);
    _assertNotDynamicBounded(intStar);
  }

  test_never() {
    _assertNotDynamicBounded(neverNone);
    _assertNotDynamicBounded(neverQuestion);
    _assertNotDynamicBounded(neverStar);
  }

  test_void() {
    _assertNotDynamicBounded(voidNone);
  }

  void _assertDynamicBounded(DartType type) {
    expect(typeSystem.isDynamicBounded(type), isTrue);
  }

  void _assertNotDynamicBounded(DartType type) {
    expect(typeSystem.isDynamicBounded(type), isFalse);
  }
}

@reflectiveTest
class FunctionBoundedTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _assertNotFunctionBounded(dynamicNone);
  }

  test_dynamic_typeParameter_hasBound_functionType_none() {
    var T = typeParameter(
      'T',
      bound: functionTypeNone(returnType: voidNone),
    );

    _assertFunctionBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasBound_functionType_question() {
    var T = typeParameter(
      'T',
      bound: functionTypeQuestion(returnType: voidNone),
    );

    _assertNotFunctionBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasBound_functionType_star() {
    var T = typeParameter(
      'T',
      bound: functionTypeStar(returnType: voidNone),
    );

    _assertFunctionBounded(
      typeParameterTypeStar(T),
    );
  }

  test_dynamic_typeParameter_hasBound_notFunction() {
    var T = typeParameter('T', bound: intNone);

    _assertNotFunctionBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_functionType_none() {
    var T = typeParameter('T');

    _assertFunctionBounded(
      typeParameterTypeNone(
        T,
        promotedBound: functionTypeNone(
          returnType: voidNone,
        ),
      ),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_functionType_question() {
    var T = typeParameter('T');

    _assertNotFunctionBounded(
      typeParameterTypeStar(
        T,
        promotedBound: functionTypeQuestion(
          returnType: voidNone,
        ),
      ),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_functionType_star() {
    var T = typeParameter('T');

    _assertFunctionBounded(
      typeParameterTypeStar(
        T,
        promotedBound: functionTypeStar(
          returnType: voidNone,
        ),
      ),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_notFunction() {
    var T = typeParameter('T');

    _assertNotFunctionBounded(
      typeParameterTypeNone(T, promotedBound: intNone),
    );
  }

  test_dynamic_typeParameter_noBound() {
    var T = typeParameter('T');

    _assertNotFunctionBounded(
      typeParameterTypeNone(T),
    );
  }

  test_functionType() {
    _assertFunctionBounded(
      functionTypeNone(returnType: voidNone),
    );
    _assertNotFunctionBounded(
      functionTypeQuestion(returnType: voidNone),
    );
    _assertFunctionBounded(
      functionTypeStar(returnType: voidNone),
    );

    _assertFunctionBounded(
      functionTypeNone(returnType: dynamicNone),
    );
  }

  test_interfaceType() {
    _assertNotFunctionBounded(intNone);
    _assertNotFunctionBounded(intQuestion);
    _assertNotFunctionBounded(intStar);
  }

  test_never() {
    _assertNotFunctionBounded(neverNone);
    _assertNotFunctionBounded(neverQuestion);
    _assertNotFunctionBounded(neverStar);
  }

  test_void() {
    _assertNotFunctionBounded(voidNone);
  }

  void _assertFunctionBounded(DartType type) {
    expect(typeSystem.isFunctionBounded(type), isTrue);
  }

  void _assertNotFunctionBounded(DartType type) {
    expect(typeSystem.isFunctionBounded(type), isFalse);
  }
}
