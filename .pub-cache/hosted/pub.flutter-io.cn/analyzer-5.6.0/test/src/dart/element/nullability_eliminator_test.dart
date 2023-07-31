// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import 'string_types.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullabilityEliminatorTest);
  });
}

@reflectiveTest
class NullabilityEliminatorTest extends AbstractTypeSystemTest
    with StringTypes {
  @override
  void setUp() {
    super.setUp();
    defineStringTypes();
  }

  test_dynamicType() {
    _verifySame(typeProvider.dynamicType);
  }

  test_functionType() {
    _verify(
      functionTypeNone(returnType: voidNone),
      functionTypeStar(returnType: voidNone),
    );

    _verify(
      functionTypeQuestion(returnType: voidNone),
      functionTypeStar(returnType: voidNone),
    );

    _verifySame(
      functionTypeStar(returnType: voidNone),
    );
  }

  test_functionType_parameters() {
    _verify(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
    );

    _verify(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intQuestion),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
    );

    _verifySame(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
    );
  }

  test_functionType_parameters_named() {
    _verify(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
    );

    _verify(
      functionTypeStar(
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
    );

    _verify(
      functionTypeStar(
        parameters: [
          namedRequiredParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
    );
  }

  test_functionType_returnType() {
    _verify(
      functionTypeStar(returnType: intNone),
      functionTypeStar(returnType: intStar),
    );

    _verify(
      functionTypeStar(returnType: intQuestion),
      functionTypeStar(returnType: intStar),
    );

    _verifySame(
      functionTypeStar(returnType: intStar),
    );
  }

  test_functionType_returnType_fromAlias() {
    var T = typeParameter('T');
    var A = typeAlias(
      name: 'A',
      typeParameters: [T],
      aliasedType: functionTypeNone(returnType: intNone),
    );

    var input = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    expect(_typeToString(input), 'int Function()');
    _assertInstantiatedAlias(input, A, 'int');

    var result = NullabilityEliminator.perform(typeProvider, input);
    expect(_typeToString(result), 'int* Function()*');
    _assertInstantiatedAlias(result, A, 'int*');
  }

  test_functionType_typeParameters() {
    var T = typeParameter('T');

    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeNone(T),
      ),
      'T Function<T>()',
      'T* Function<T>()*',
    );
    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeQuestion(T),
      ),
      'T? Function<T>()',
      'T* Function<T>()*',
    );
    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeStar(T),
      ),
      'T* Function<T>()',
      'T* Function<T>()*',
    );

    _verifySame(
      functionTypeStar(
        typeFormals: [T],
        returnType: typeParameterTypeStar(T),
      ),
    );
  }

  test_functionType_typeParameters_bound_none() {
    var T = typeParameter('T', bound: intNone);

    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeNone(T),
      ),
      'T Function<T extends int>()',
      'T* Function<T extends int*>()*',
    );
  }

  test_functionType_typeParameters_bound_other() {
    var T = typeParameter('T', bound: intNone);
    var U = typeParameter('U', bound: typeParameterTypeNone(T));

    _verifyStr(
      functionTypeNone(
        typeFormals: [T, U],
        returnType: typeParameterTypeNone(T),
      ),
      'T Function<T extends int, U extends T>()',
      'T* Function<T extends int*, U extends T*>()*',
    );
  }

  test_functionType_typeParameters_bound_question() {
    var T = typeParameter('T', bound: intQuestion);

    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeNone(T),
      ),
      'T Function<T extends int?>()',
      'T* Function<T extends int*>()*',
    );
  }

  test_functionType_typeParameters_bound_star() {
    var T = typeParameter('T', bound: intStar);

    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeNone(T),
      ),
      'T Function<T extends int*>()',
      'T* Function<T extends int*>()*',
    );

    _verifySame(
      functionTypeStar(
        typeFormals: [T],
        returnType: typeParameterTypeStar(T),
      ),
    );
  }

  test_interfaceType_fromAlias() {
    var T = typeParameter('T');
    var A = typeAlias(
      name: 'A',
      typeParameters: [T],
      aliasedType: listNone(
        typeParameterTypeNone(T),
      ),
    );

    var input = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    expect(_typeToString(input), 'List<int>');

    var result = NullabilityEliminator.perform(typeProvider, input);
    expect(_typeToString(result), 'List<int*>*');
    _assertInstantiatedAlias(result, A, 'int*');
  }

  test_interfaceType_int() {
    _verify(intNone, intStar);
    _verify(intQuestion, intStar);
    _verifySame(intStar);
  }

  test_interfaceType_list() {
    var expected = listStar(intStar);

    _verify(listNone(intNone), expected);
    _verify(listNone(intQuestion), expected);
    _verify(listNone(intStar), expected);

    _verify(listQuestion(intNone), expected);
    _verify(listQuestion(intQuestion), expected);
    _verify(listQuestion(intStar), expected);

    _verify(listStar(intNone), expected);
    _verify(listStar(intQuestion), expected);
    _verifySame(listStar(intStar));
  }

  test_neverType() {
    _verify(neverNone, nullStar);
    _verify(neverQuestion, nullStar);
    _verify(neverStar, nullStar);

    _verify(listNone(neverNone), listStar(nullStar));
    _verify(listQuestion(neverNone), listStar(nullStar));
    _verify(listStar(neverNone), listStar(nullStar));
  }

  test_recordType_fromAlias() {
    var T = typeParameter('T');
    var A = typeAlias(
      name: 'A',
      typeParameters: [T],
      aliasedType: recordTypeNone(
        positionalTypes: [
          typeParameterTypeNone(T),
        ],
      ),
    );

    var input = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    expect(_typeToString(input), '(int)');

    var result = NullabilityEliminator.perform(typeProvider, input);
    expect(_typeToString(result), '(int*)*');
    _assertInstantiatedAlias(result, A, 'int*');
  }

  test_recordType_named() {
    final expected = '({int* f1})*';

    _verify2('({int f1})', expected);
    _verify2('({int? f1})', expected);
    _verify2('({int* f1})', expected);

    _verify2('({int f1})?', expected);
    _verify2('({int? f1})?', expected);
    _verify2('({int* f1})?', expected);

    _verify2('({int f1})*', expected);
    _verify2('({int? f1})*', expected);
    _verifySame(typeOfString(expected));
  }

  test_recordType_positional() {
    final expected = '(int*)*';

    _verify2('(int)', expected);
    _verify2('(int?)', expected);
    _verify2('(int*)', expected);

    _verify2('(int)?', expected);
    _verify2('(int?)?', expected);
    _verify2('(int*)?', expected);

    _verify2('(int)*', expected);
    _verify2('(int?)*', expected);
    _verifySame(typeOfString(expected));
  }

  test_typeParameterType() {
    var T = typeParameter('T');
    _verify(
      typeParameterTypeNone(T),
      typeParameterTypeStar(T),
    );
    _verify(
      typeParameterTypeQuestion(T),
      typeParameterTypeStar(T),
    );
    _verifySame(
      typeParameterTypeStar(T),
    );
  }

  test_voidType() {
    _verifySame(typeProvider.voidType);
  }

  void _assertInstantiatedAlias(
      DartType type, Element aliasElement, String aliasArguments) {
    var alias = type.alias!;
    expect(alias.element, same(aliasElement));
    expect(alias.typeArguments.map(_typeToString).join(', '), aliasArguments);
  }

  String _typeToString(DartType type) {
    return type.getDisplayString(withNullability: true);
  }

  void _verify(DartType input, DartType expected) {
    var result = NullabilityEliminator.perform(typeProvider, input);
    expect(result, isNot(same(input)));
    expect(result, expected);
  }

  void _verify2(String input, String expected) {
    _verify(typeOfString(input), typeOfString(expected));
  }

  void _verifySame(DartType input) {
    var result = NullabilityEliminator.perform(typeProvider, input);
    expect(result, same(input));
  }

  void _verifyStr(DartType input, String inputStr, String expectedStr) {
    expect(_typeToString(input), inputStr);

    var result = NullabilityEliminator.perform(typeProvider, input);
    expect(result, isNot(same(input)));
    expect(_typeToString(result), expectedStr);
  }
}
