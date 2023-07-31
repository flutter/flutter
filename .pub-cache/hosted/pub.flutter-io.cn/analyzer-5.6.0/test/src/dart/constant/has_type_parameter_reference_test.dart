// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/constant/has_type_parameter_reference.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HasTypeParameterReferenceTest);
  });
}

@reflectiveTest
class HasTypeParameterReferenceTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _checkFalse(dynamicNone);
  }

  test_functionType() {
    _checkFalse(functionTypeNone(returnType: voidNone));

    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);

    _checkTrue(
      functionTypeNone(returnType: T_none),
    );

    _checkTrue(
      functionTypeNone(
        returnType: voidNone,
        parameters: [requiredParameter(type: T_none)],
      ),
    );

    _checkTrue(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [typeParameter('S', bound: T_none)],
      ),
    );
  }

  test_interfaceType() {
    _checkFalse(intNone);
    _checkFalse(intQuestion);
    _checkFalse(intStar);

    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);
    _checkTrue(listNone(T_none));
    _checkTrue(mapNone(T_none, intNone));
    _checkTrue(mapNone(intNone, T_none));
  }

  test_typeParameter() {
    var T = typeParameter('T');
    _checkTrue(typeParameterTypeNone(T));
    _checkTrue(typeParameterTypeQuestion(T));
    _checkTrue(typeParameterTypeStar(T));
  }

  test_void() {
    _checkFalse(voidNone);
  }

  void _checkFalse(DartType type) {
    expect(hasTypeParameterReference(type), isFalse);
  }

  void _checkTrue(DartType type) {
    expect(hasTypeParameterReference(type), isTrue);
  }
}
