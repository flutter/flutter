// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NormalizeTypeTest);
  });
}

@reflectiveTest
class NormalizeTypeTest extends AbstractTypeSystemTest {
  test_functionType_parameter() {
    _check(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: futureOrNone(objectNone)),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: objectNone),
        ],
      ),
    );

    _check(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: futureOrNone(objectNone)),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: objectNone),
        ],
      ),
    );

    _check(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: futureOrNone(objectNone)),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: objectNone),
        ],
      ),
    );

    _check(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(type: futureOrNone(objectNone)),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(type: objectNone),
        ],
      ),
    );
  }

  test_functionType_parameter_covariant() {
    _check(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: futureOrNone(objectNone), isCovariant: true),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: objectNone, isCovariant: true),
        ],
      ),
    );
  }

  test_functionType_parameter_typeParameter() {
    TypeParameterElement T;
    TypeParameterElement T2;

    T = typeParameter('T', bound: neverNone);
    T2 = typeParameter('T2', bound: neverNone);
    _check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [T],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [T2],
        parameters: [
          requiredParameter(type: neverNone),
        ],
      ),
    );

    T = typeParameter('T', bound: iterableNone(futureOrNone(dynamicNone)));
    T2 = typeParameter('T2', bound: iterableNone(dynamicNone));
    _check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [T],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [T2],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(T2)),
        ],
      ),
    );
  }

  test_functionType_returnType() {
    _check(
      functionTypeNone(
        returnType: futureOrNone(objectNone),
      ),
      functionTypeNone(
        returnType: objectNone,
      ),
    );

    _check(
      functionTypeNone(
        returnType: intNone,
      ),
      functionTypeNone(
        returnType: intNone,
      ),
    );
  }

  test_functionType_typeParameter_bound_normalized() {
    _check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: futureOrNone(objectNone)),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: objectNone),
        ],
      ),
    );
  }

  test_functionType_typeParameter_bound_unchanged() {
    _check(
      functionTypeNone(
        returnType: intNone,
        typeFormals: [
          typeParameter('T', bound: numNone),
        ],
      ),
      functionTypeNone(
        returnType: intNone,
        typeFormals: [
          typeParameter('T', bound: numNone),
        ],
      ),
    );
  }

  test_functionType_typeParameter_fresh() {
    var T = typeParameter('T');
    var T2 = typeParameter('T');
    _check(
      functionTypeNone(
        returnType: typeParameterTypeNone(T),
        typeFormals: [T],
        parameters: [
          requiredParameter(
            type: typeParameterTypeNone(T),
          ),
        ],
      ),
      functionTypeNone(
        returnType: typeParameterTypeNone(T2),
        typeFormals: [T2],
        parameters: [
          requiredParameter(
            type: typeParameterTypeNone(T2),
          ),
        ],
      ),
    );
  }

  test_functionType_typeParameter_fresh_bound() {
    var T = typeParameter('T');
    var S = typeParameter('S', bound: typeParameterTypeNone(T));
    var T2 = typeParameter('T');
    var S2 = typeParameter('S', bound: typeParameterTypeNone(T2));
    _check(
      functionTypeNone(
        returnType: typeParameterTypeNone(T),
        typeFormals: [T, S],
        parameters: [
          requiredParameter(
            type: typeParameterTypeNone(T),
          ),
          requiredParameter(
            type: typeParameterTypeNone(S),
          ),
        ],
      ),
      functionTypeNone(
        returnType: typeParameterTypeNone(T2),
        typeFormals: [T2, S2],
        parameters: [
          requiredParameter(
            type: typeParameterTypeNone(T2),
          ),
          requiredParameter(
            type: typeParameterTypeNone(S2),
          ),
        ],
      ),
    );
  }

  /// NORM(FutureOr<T>)
  /// * let S be NORM(T)
  test_futureOr() {
    void check(DartType T, DartType expected) {
      var input = futureOrNone(T);
      _check(input, expected);
    }

    // * if S is a top type then S
    check(dynamicNone, dynamicNone);
    check(voidNone, voidNone);
    check(objectQuestion, objectQuestion);

    // * if S is Object then S
    check(objectNone, objectNone);

    // * if S is Object* then S
    check(objectStar, objectStar);

    // * if S is Never then Future<Never>
    check(neverNone, futureNone(neverNone));

    // * if S is Null then Future<Null>?
    check(nullNone, futureQuestion(nullNone));

    // * else FutureOr<S>
    check(intNone, futureOrNone(intNone));
  }

  test_interfaceType() {
    _check(listNone(intNone), listNone(intNone));

    _check(
      listNone(
        futureOrNone(objectNone),
      ),
      listNone(objectNone),
    );
  }

  test_primitive() {
    _check(dynamicNone, dynamicNone);
    _check(neverNone, neverNone);
    _check(voidNone, voidNone);
    _check(intNone, intNone);
  }

  /// NORM(T?)
  /// * let S be NORM(T)
  test_question() {
    void check(DartType T, DartType expected) {
      _assertNullabilityQuestion(T);
      _check(T, expected);
    }

    // * if S is a top type then S
    check(futureOrQuestion(dynamicNone), dynamicNone);
    check(futureOrQuestion(voidNone), voidNone);
    check(futureOrQuestion(objectQuestion), objectQuestion);

    // * if S is Never then Null
    check(neverQuestion, nullNone);

    // * if S is Never* then Null
    // Analyzer: impossible, we have only one suffix

    // * if S is Null then Null
    check(nullQuestion, nullNone);

    // * if S is FutureOr<R> and R is nullable then S
    check(futureOrQuestion(intQuestion), futureOrNone(intQuestion));

    // * if S is FutureOr<R>* and R is nullable then FutureOr<R>
    // Analyzer: impossible, we have only one suffix

    // * if S is R? then R?
    // * if S is R* then R?
    // * else S?
    check(intQuestion, intQuestion);
    check(objectQuestion, objectQuestion);
    check(futureOrQuestion(objectNone), objectQuestion);
    check(futureOrQuestion(objectStar), objectStar);
  }

  /// NORM(T*)
  /// * let S be NORM(T)
  test_star() {
    void check(DartType T, DartType expected) {
      _assertNullabilityStar(T);
      _check(T, expected);
    }

    // * if S is a top type then S
    check(futureOrStar(dynamicNone), dynamicNone);
    check(futureOrStar(voidNone), voidNone);
    check(futureOrStar(objectQuestion), objectQuestion);

    // * if S is Null then Null
    check(nullStar, nullNone);

    // * if S is R? then R?
    check(futureOrStar(nullNone), futureQuestion(nullNone));

    // * if S is R* then R*
    // * else S*
    check(intStar, intStar);
  }

  /// NORM(X & T)
  /// * let S be NORM(T)
  test_typeParameter_bound() {
    TypeParameterElement T;

    // * if S is Never then Never
    T = typeParameter('T', bound: neverNone);
    _check(typeParameterTypeNone(T), neverNone);

    // * else X
    T = typeParameter('T');
    _check(typeParameterTypeNone(T), typeParameterTypeNone(T));

    // * else X
    T = typeParameter('T', bound: futureOrNone(objectNone));
    _check(typeParameterTypeNone(T), typeParameterTypeNone(T));
  }

  test_typeParameter_bound_recursive() {
    var T = typeParameter('T');
    T.bound = iterableNone(typeParameterTypeNone(T));
    _check(typeParameterTypeNone(T), typeParameterTypeNone(T));
  }

  test_typeParameter_promoted() {
    var T = typeParameter('T');

    // * if S is Never then Never
    _check(
      promotedTypeParameterTypeNone(T, neverNone),
      neverNone,
    );

    // * if S is a top type then X
    _check(
      promotedTypeParameterTypeNone(T, objectQuestion),
      typeParameterTypeNone(T),
    );
    _check(
      promotedTypeParameterTypeNone(T, futureOrQuestion(objectNone)),
      typeParameterTypeNone(T),
    );

    // * if S is X then X
    _check(
      promotedTypeParameterTypeNone(T, typeParameterTypeNone(T)),
      typeParameterTypeNone(T),
    );

    // * if S is Object and NORM(B) is Object where B is the bound of X then X
    T = typeParameter('T', bound: objectNone);
    _check(
      promotedTypeParameterTypeNone(T, futureOrNone(objectNone)),
      typeParameterTypeNone(T),
    );

    // else X & S
    T = typeParameter('T');
    _check(
      promotedTypeParameterType(
        element: T,
        nullabilitySuffix: NullabilitySuffix.none,
        promotedBound: futureOrNone(neverNone),
      ),
      promotedTypeParameterType(
        element: T,
        nullabilitySuffix: NullabilitySuffix.none,
        promotedBound: futureNone(neverNone),
      ),
    );
  }

  void _assertNullability(DartType type, NullabilitySuffix expected) {
    if (type.nullabilitySuffix != expected) {
      fail('Expected $expected in ' + _typeString(type));
    }
  }

  void _assertNullabilityQuestion(DartType type) {
    _assertNullability(type, NullabilitySuffix.question);
  }

  void _assertNullabilityStar(DartType type) {
    _assertNullability(type, NullabilitySuffix.star);
  }

  void _check(DartType T, DartType expected) {
    var expectedStr = _typeString(expected);

    var result = typeSystem.normalize(T);
    var resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');
    _checkFormalParametersIsCovariant(result, expected);
  }

  void _checkFormalParametersIsCovariant(DartType T1, DartType T2) {
    if (T1 is FunctionType && T2 is FunctionType) {
      var parameters1 = T1.parameters;
      var parameters2 = T2.parameters;
      expect(parameters1, hasLength(parameters2.length));
      for (var i = 0; i < parameters1.length; i++) {
        var parameter1 = parameters1[i];
        var parameter2 = parameters2[i];
        if (parameter1.isCovariant != parameter2.isCovariant) {
          fail('''
parameter1: $parameter1, isCovariant: ${parameter1.isCovariant}
parameter2: $parameter2, isCovariant: ${parameter2.isCovariant}
T1: ${_typeString(T1 as TypeImpl)}
T2: ${_typeString(T2 as TypeImpl)}
''');
        }
        _checkFormalParametersIsCovariant(parameter1.type, parameter2.type);
      }
    }
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

  String _typeString(DartType type) {
    return type.getDisplayString(withNullability: true) +
        _typeParametersStr(type);
  }
}

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
      var promotedBound = (type as TypeParameterTypeImpl).promotedBound;

      if (bound == null && promotedBound == null) {
        return;
      }

      var str = '';

      if (bound != null) {
        var boundStr = bound.getDisplayString(withNullability: true);
        str += '${type.element.name} extends ' + boundStr;
      }

      if (promotedBound != null) {
        var promotedBoundStr = promotedBound.getDisplayString(
          withNullability: true,
        );
        if (str.isNotEmpty) {
          str += ', ';
        }
        str += '${type.element.name} & ' + promotedBoundStr;
      }

      typeParameters.add(str);
    }
  }

  @override
  void visitVoidType(VoidType type) {}
}
