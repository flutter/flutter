// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypeTest);
  });
}

DynamicTypeImpl get dynamicType => DynamicTypeImpl.instance;

@reflectiveTest
class FunctionTypeTest extends AbstractTypeSystemTest {
  InterfaceType get intType => typeProvider.intType;

  ClassElement get listElement => typeProvider.listElement;

  ClassElement get mapElement => typeProvider.mapElement;

  InterfaceType get objectType => typeProvider.objectType;

  void basicChecks(FunctionType f,
      {displayName = 'dynamic Function()',
      returnType,
      namedParameterTypes = isEmpty,
      normalParameterNames = isEmpty,
      normalParameterTypes = isEmpty,
      optionalParameterNames = isEmpty,
      optionalParameterTypes = isEmpty,
      parameters = isEmpty,
      typeFormals = isEmpty,
      typeParameters = isEmpty}) {
    // DartType properties
    expect(
      f.getDisplayString(withNullability: false),
      displayName,
      reason: 'displayName',
    );
    // FunctionType properties
    expect(f.namedParameterTypes, namedParameterTypes,
        reason: 'namedParameterTypes');
    expect(f.normalParameterNames, normalParameterNames,
        reason: 'normalParameterNames');
    expect(f.normalParameterTypes, normalParameterTypes,
        reason: 'normalParameterTypes');
    expect(f.optionalParameterNames, optionalParameterNames,
        reason: 'optionalParameterNames');
    expect(f.optionalParameterTypes, optionalParameterTypes,
        reason: 'optionalParameterTypes');
    expect(f.parameters, parameters, reason: 'parameters');
    expect(f.returnType, returnType ?? same(dynamicType), reason: 'returnType');
    expect(f.typeFormals, typeFormals, reason: 'typeFormals');
  }

  DartType listOf(DartType elementType) => listElement.instantiate(
        typeArguments: [elementType],
        nullabilitySuffix: NullabilitySuffix.star,
      );

  DartType mapOf(DartType keyType, DartType valueType) =>
      mapElement.instantiate(
        typeArguments: [keyType, valueType],
        nullabilitySuffix: NullabilitySuffix.star,
      );

  test_equality_leftRequired_rightPositional() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        positionalParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_differentName() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'b', type: typeProvider.intType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_differentType() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.doubleType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_equal() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    expect(f1, f2);
  }

  test_equality_namedParameters_extraLeft() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_extraRight() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_required_left() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedRequiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_required_right() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        namedRequiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_requiredParameters_extraLeft() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
        requiredParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_requiredParameters_extraRight() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
        requiredParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_new_sortsNamedParameters() {
    var f = functionTypeNone(
      returnType: typeProvider.voidType,
      parameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'c', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.intType),
      ],
    );
    var parameters = f.parameters;
    expect(parameters, hasLength(3));
    expect(parameters[0].name, 'a');
    expect(parameters[1].name, 'b');
    expect(parameters[2].name, 'c');
  }

  test_synthetic() {
    FunctionType f = FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    basicChecks(f);
  }

  test_synthetic_instantiate() {
    // T Function<T>(T x)
    var t = typeParameter('T');
    var x = requiredParameter(name: 'x', type: typeParameterTypeNone(t));
    FunctionType f = FunctionTypeImpl(
      typeFormals: [t],
      parameters: [x],
      returnType: typeParameterTypeNone(t),
      nullabilitySuffix: NullabilitySuffix.star,
    );
    FunctionType instantiated = f.instantiate([objectType]);
    basicChecks(instantiated,
        displayName: 'Object Function(Object)',
        returnType: same(objectType),
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: hasLength(1));
  }

  test_synthetic_instantiate_argument_length_mismatch() {
    // dynamic Function<T>()
    var t = typeParameter('T');
    FunctionType f = FunctionTypeImpl(
      typeFormals: [t],
      parameters: const [],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    expect(() => f.instantiate([]), throwsA(TypeMatcher<ArgumentError>()));
  }

  test_synthetic_instantiate_no_type_formals() {
    FunctionType f = FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    expect(f.instantiate([]), same(f));
  }

  test_synthetic_namedParameter() {
    var p = namedParameter(name: 'x', type: objectType);
    FunctionType f = FunctionTypeImpl(
      typeFormals: const [],
      parameters: [p],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    basicChecks(f,
        displayName: 'dynamic Function({Object x})',
        namedParameterTypes: {'x': same(objectType)},
        parameters: hasLength(1));
    expect(f.parameters[0].isNamed, isTrue);
    expect(f.parameters[0].name, 'x');
    expect(f.parameters[0].type, same(objectType));
  }

  test_synthetic_normalParameter() {
    var p = requiredParameter(name: 'x', type: objectType);
    FunctionType f = FunctionTypeImpl(
      typeFormals: const [],
      parameters: [p],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    basicChecks(f,
        displayName: 'dynamic Function(Object)',
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: hasLength(1));
    expect(f.parameters[0].isRequiredPositional, isTrue);
    expect(f.parameters[0].name, 'x');
    expect(f.parameters[0].type, same(objectType));
  }

  test_synthetic_optionalParameter() {
    var p = positionalParameter(name: 'x', type: objectType);
    FunctionType f = FunctionTypeImpl(
      typeFormals: const [],
      parameters: [p],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    basicChecks(f,
        displayName: 'dynamic Function([Object])',
        optionalParameterNames: ['x'],
        optionalParameterTypes: [same(objectType)],
        parameters: hasLength(1));
    expect(f.parameters[0].isOptionalPositional, isTrue);
    expect(f.parameters[0].name, 'x');
    expect(f.parameters[0].type, same(objectType));
  }

  test_synthetic_returnType() {
    FunctionType f = FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: objectType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    basicChecks(f,
        displayName: 'Object Function()', returnType: same(objectType));
  }

  test_synthetic_typeFormals() {
    var t = typeParameter('T');
    FunctionType f = FunctionTypeImpl(
      typeFormals: [t],
      parameters: const [],
      returnType: typeParameterTypeStar(t),
      nullabilitySuffix: NullabilitySuffix.star,
    );
    basicChecks(f,
        displayName: 'T Function<T>()',
        returnType: typeParameterTypeStar(t),
        typeFormals: [same(t)]);
  }
}
