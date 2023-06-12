// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' show toUri;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericFunctionInferenceTest);
  });
}

@reflectiveTest
class GenericFunctionInferenceTest extends AbstractTypeSystemTest {
  void test_boundedByAnotherTypeParameter() {
    // <TFrom, TTo extends Iterable<TFrom>>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo =
        typeParameter('TTo', bound: iterableNone(typeParameterTypeNone(tFrom)));
    var cast = functionTypeNone(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeNone(tFrom),
        ),
      ],
      returnType: typeParameterTypeNone(tTo),
    );
    _assertTypes(
      _inferCall(cast, [stringNone]),
      [stringNone, (iterableNone(stringNone))],
    );
  }

  void test_boundedByOuterClass() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var A = class_(name: 'A', superType: objectNone);
    var typeA = interfaceTypeNone(A);

    // class B extends A {}
    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeNone(B);

    // class C<T extends A> {
    var CT = typeParameter('T', bound: typeA);
    var C = class_(
      name: 'C',
      superType: objectNone,
      typeParameters: [CT],
    );
    //   S m<S extends T>(S);
    var S = typeParameter('S', bound: typeParameterTypeNone(CT));
    var m = method(
      'm',
      typeParameterTypeNone(S),
      typeFormals: [S],
      parameters: [
        requiredParameter(
          name: '_',
          type: typeParameterTypeNone(S),
        ),
      ],
    );
    C.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = interfaceTypeNone(C, typeArguments: [objectNone]);
    // C<A> cOfA;
    var cOfA = interfaceTypeNone(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = interfaceTypeNone(C, typeArguments: [typeB]);
    // B b;
    // cOfB.m(b); // infer <B>
    _assertType(
        _inferCall2(cOfB.getMethod('m')!.type, [typeB]), 'B Function(B)');
    // cOfA.m(b); // infer <B>
    _assertType(
        _inferCall2(cOfA.getMethod('m')!.type, [typeB]), 'B Function(B)');
    // cOfObject.m(b); // infer <B>
    _assertType(
        _inferCall2(cOfObject.getMethod('m')!.type, [typeB]), 'B Function(B)');
  }

  void test_boundedByOuterClassSubstituted() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.

    // class A {}
    var A = class_(name: 'A', superType: objectNone);
    var typeA = interfaceTypeNone(A);

    // class B extends A {}
    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeNone(B);

    // class C<T extends A> {
    var CT = typeParameter('T', bound: typeA);
    var C = class_(
      name: 'C',
      superType: objectNone,
      typeParameters: [CT],
    );
    //   S m<S extends Iterable<T>>(S);
    var iterableOfT = iterableNone(typeParameterTypeNone(CT));
    var S = typeParameter('S', bound: iterableOfT);
    var m = method(
      'm',
      typeParameterTypeNone(S),
      typeFormals: [S],
      parameters: [
        requiredParameter(
          name: '_',
          type: typeParameterTypeNone(S),
        ),
      ],
    );
    C.methods = [m];
    // }

    // C<Object> cOfObject;
    var cOfObject = interfaceTypeNone(C, typeArguments: [objectNone]);
    // C<A> cOfA;
    var cOfA = interfaceTypeNone(C, typeArguments: [typeA]);
    // C<B> cOfB;
    var cOfB = interfaceTypeNone(C, typeArguments: [typeB]);
    // List<B> b;
    var listOfB = listNone(typeB);
    // cOfB.m(b); // infer <B>
    _assertType(_inferCall2(cOfB.getMethod('m')!.type, [listOfB]),
        'List<B> Function(List<B>)');
    // cOfA.m(b); // infer <B>
    _assertType(_inferCall2(cOfA.getMethod('m')!.type, [listOfB]),
        'List<B> Function(List<B>)');
    // cOfObject.m(b); // infer <B>
    _assertType(_inferCall2(cOfObject.getMethod('m')!.type, [listOfB]),
        'List<B> Function(List<B>)');
  }

  void test_boundedRecursively() {
    // class A<T extends A<T>>
    var T = typeParameter('T');
    var A = class_(
      name: 'Cloneable',
      superType: objectNone,
      typeParameters: [T],
    );
    T.bound = interfaceTypeNone(
      A,
      typeArguments: [typeParameterTypeNone(T)],
    );

    // class B extends A<B> {}
    var B = class_(name: 'B', superType: null);
    B.supertype = interfaceTypeNone(A, typeArguments: [interfaceTypeNone(B)]);
    var typeB = interfaceTypeNone(B);

    // <S extends A<S>>
    var S = typeParameter('S');
    var typeS = typeParameterTypeNone(S);
    S.bound = interfaceTypeNone(A, typeArguments: [typeS]);

    // (S, S) -> S
    var clone = functionTypeNone(
      typeFormals: [S],
      parameters: [
        requiredParameter(type: typeS),
        requiredParameter(type: typeS),
      ],
      returnType: typeS,
    );
    _assertTypes(_inferCall(clone, [typeB, typeB]), [typeB]);

    // Something invalid...
    _assertTypes(
      _inferCall(clone, [stringNone, numNone], expectError: true),
      [objectNone],
    );
  }

  /// https://github.com/dart-lang/language/issues/1182#issuecomment-702272641
  void test_demoteType() {
    // <T>(T x) -> void
    var T = typeParameter('T');
    var rawType = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
      ],
      returnType: voidNone,
    );

    var S = typeParameter('S');
    var S_and_int = typeParameterTypeNone(S, promotedBound: intNone);

    var inferredTypes = _inferCall(rawType, [S_and_int]);
    var inferredType = inferredTypes[0] as TypeParameterTypeImpl;
    expect(inferredType.element, S);
    expect(inferredType.promotedBound, isNull);
  }

  void test_fromLegacy_nonNullableBound() {
    typeSystem = analysisContext.typeSystemLegacy;

    // void Function<T extends Object>(T)
    var T = typeParameter('T', bound: objectNone);
    var rawType = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: typeParameterTypeNone(T),
        ),
      ],
      returnType: voidNone,
    );

    _assertTypes(
      _inferCall(rawType, [dynamicNone]),
      [dynamicNone],
    );
  }

  void test_genericCastFunction() {
    // <TFrom, TTo>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo = typeParameter('TTo');
    var cast = functionTypeNone(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeNone(tFrom),
        ),
      ],
      returnType: typeParameterTypeNone(tTo),
    );
    _assertTypes(_inferCall(cast, [intNone]), [intNone, dynamicNone]);
  }

  void test_genericCastFunctionWithUpperBound() {
    // <TFrom, TTo extends TFrom>(TFrom) -> TTo
    var tFrom = typeParameter('TFrom');
    var tTo = typeParameter(
      'TTo',
      bound: typeParameterTypeNone(tFrom),
    );
    var cast = functionTypeNone(
      typeFormals: [tFrom, tTo],
      parameters: [
        requiredParameter(
          type: typeParameterTypeNone(tFrom),
        ),
      ],
      returnType: typeParameterTypeNone(tTo),
    );
    _assertTypes(_inferCall(cast, [intNone]), [intNone, intNone]);
  }

  void test_parameter_contravariantUseUpperBound() {
    // <T>(T x, void Function(T) y) -> T
    // Generates constraints int <: T <: num.
    // Since T is contravariant, choose num.
    var T = typeParameter('T', variance: Variance.contravariant);
    var tFunction = functionTypeNone(
        parameters: [requiredParameter(type: typeParameterTypeNone(T))],
        returnType: voidNone);
    var numFunction = functionTypeNone(
        parameters: [requiredParameter(type: numNone)], returnType: voidNone);
    var function = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
        requiredParameter(type: tFunction)
      ],
      returnType: typeParameterTypeNone(T),
    );

    _assertTypes(_inferCall(function, [intNone, numFunction]), [numNone]);
  }

  void test_parameter_covariantUseLowerBound() {
    // <T>(T x, void Function(T) y) -> T
    // Generates constraints int <: T <: num.
    // Since T is covariant, choose int.
    var T = typeParameter('T', variance: Variance.covariant);
    var tFunction = functionTypeNone(
        parameters: [requiredParameter(type: typeParameterTypeNone(T))],
        returnType: voidNone);
    var numFunction = functionTypeNone(
        parameters: [requiredParameter(type: numNone)], returnType: voidNone);
    var function = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
        requiredParameter(type: tFunction)
      ],
      returnType: typeParameterTypeNone(T),
    );

    _assertTypes(_inferCall(function, [intNone, numFunction]), [intNone]);
  }

  void test_parametersToFunctionParam() {
    // <T>(f(T t)) -> T
    var T = typeParameter('T');
    var cast = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(
                type: typeParameterTypeNone(T),
              ),
            ],
            returnType: dynamicNone,
          ),
        ),
      ],
      returnType: typeParameterTypeNone(T),
    );
    _assertTypes(
      _inferCall(cast, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: dynamicNone,
        )
      ]),
      [numNone],
    );
  }

  void test_parametersUseLeastUpperBound() {
    // <T>(T x, T y) -> T
    var T = typeParameter('T');
    var cast = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
        requiredParameter(type: typeParameterTypeNone(T)),
      ],
      returnType: typeParameterTypeNone(T),
    );
    _assertTypes(_inferCall(cast, [intNone, doubleNone]), [numNone]);
  }

  void test_parameterTypeUsesUpperBound() {
    // <T extends num>(T) -> dynamic
    var T = typeParameter('T', bound: numNone);
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
      ],
      returnType: dynamicNone,
    );
    _assertTypes(_inferCall(f, [intNone]), [intNone]);
  }

  void test_returnFunctionWithGenericParameter() {
    // <T>(T -> T) -> (T -> void)
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: typeParameterTypeNone(T)),
            ],
            returnType: typeParameterTypeNone(T),
          ),
        ),
      ],
      returnType: functionTypeNone(
        parameters: [
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
        returnType: voidNone,
      ),
    );
    _assertTypes(
      _inferCall(f, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: intNone,
        ),
      ]),
      [intNone],
    );
  }

  void test_returnFunctionWithGenericParameterAndContext() {
    // <T>(T -> T) -> (T -> Null)
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: typeParameterTypeNone(T)),
            ],
            returnType: typeParameterTypeNone(T),
          ),
        ),
      ],
      returnType: functionTypeNone(
        parameters: [
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
        returnType: nullNone,
      ),
    );
    _assertTypes(
      _inferCall(
        f,
        [],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: intQuestion,
        ),
      ),
      [numNone],
    );
  }

  void test_returnFunctionWithGenericParameterAndReturn() {
    // <T>(T -> T) -> (T -> T)
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: typeParameterTypeNone(T)),
            ],
            returnType: typeParameterTypeNone(T),
          ),
        ),
      ],
      returnType: functionTypeNone(
        parameters: [
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
        returnType: typeParameterTypeNone(T),
      ),
    );
    _assertTypes(
      _inferCall(f, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: intNone,
        )
      ]),
      [intNone],
    );
  }

  void test_returnFunctionWithGenericReturn() {
    // <T>(T -> T) -> (() -> T)
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: typeParameterTypeNone(T)),
            ],
            returnType: typeParameterTypeNone(T),
          ),
        ),
      ],
      returnType: functionTypeNone(
        returnType: typeParameterTypeNone(T),
      ),
    );
    _assertTypes(
      _inferCall(f, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: intNone,
        )
      ]),
      [intNone],
    );
  }

  void test_returnTypeFromContext() {
    // <T>() -> T
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    _assertTypes(_inferCall(f, [], returnType: stringNone), [stringNone]);
  }

  void test_returnTypeFromContext_nonNullify() {
    // <T>() -> T
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    _assertTypes(_inferCall(f, [], returnType: intStar), [intNone]);
  }

  void test_returnTypeWithBoundFromContext() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numNone);
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    _assertTypes(_inferCall(f, [], returnType: doubleNone), [doubleNone]);
  }

  void test_returnTypeWithBoundFromInvalidContext() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numNone);
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    _assertTypes(_inferCall(f, [], returnType: stringNone), [neverNone]);
  }

  void test_unifyParametersToFunctionParam() {
    // <T>(f(T t), g(T t)) -> T
    var T = typeParameter('T');
    var cast = functionTypeNone(
      typeFormals: [T],
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(
                type: typeParameterTypeNone(T),
              ),
            ],
            returnType: dynamicNone,
          ),
        ),
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(
                type: typeParameterTypeNone(T),
              ),
            ],
            returnType: dynamicNone,
          ),
        ),
      ],
      returnType: typeParameterTypeNone(T),
    );
    _assertTypes(
      _inferCall(cast, [
        functionTypeNone(
          parameters: [
            requiredParameter(type: intNone),
          ],
          returnType: dynamicNone,
        ),
        functionTypeNone(
          parameters: [
            requiredParameter(type: doubleNone),
          ],
          returnType: dynamicNone,
        )
      ]),
      [neverNone],
    );
  }

  void test_unusedReturnTypeIsDynamic() {
    // <T>() -> T
    var T = typeParameter('T');
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    _assertTypes(_inferCall(f, []), [dynamicNone]);
  }

  void test_unusedReturnTypeWithUpperBound() {
    // <T extends num>() -> T
    var T = typeParameter('T', bound: numNone);
    var f = functionTypeNone(
      typeFormals: [T],
      returnType: typeParameterTypeNone(T),
    );
    _assertTypes(_inferCall(f, []), [numNone]);
  }

  void _assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString(withNullability: false);
    expect(typeStr, expected);
  }

  void _assertTypes(List<DartType> actual, List<DartType> expected) {
    var actualStr = actual.map((e) {
      return e.getDisplayString(withNullability: true);
    }).toList();

    var expectedStr = expected.map((e) {
      return e.getDisplayString(withNullability: true);
    }).toList();

    expect(actualStr, expectedStr);
  }

  List<DartType> _inferCall(FunctionType ft, List<DartType> arguments,
      {DartType? returnType, bool expectError = false}) {
    var listener = RecordingErrorListener();

    var reporter = ErrorReporter(
      listener,
      NonExistingSource('/test.dart', toUri('/test.dart')),
      isNonNullableByDefault: false,
    );

    var typeArguments = typeSystem.inferGenericFunctionOrType(
      typeParameters: ft.typeFormals,
      parameters: ft.parameters,
      declaredReturnType: ft.returnType,
      argumentTypes: arguments,
      contextReturnType: returnType,
      errorReporter: reporter,
      errorNode: astFactory.nullLiteral(KeywordToken(Keyword.NULL, 0)),
      genericMetadataIsEnabled: true,
    );

    if (expectError) {
      expect(listener.errors.map((e) => e.errorCode).toList(),
          [CompileTimeErrorCode.COULD_NOT_INFER],
          reason: 'expected exactly 1 could not infer error.');
    } else {
      expect(listener.errors, isEmpty, reason: 'did not expect any errors.');
    }
    return typeArguments!;
  }

  FunctionType _inferCall2(FunctionType ft, List<DartType> arguments,
      {DartType? returnType, bool expectError = false}) {
    var typeArguments = _inferCall(
      ft,
      arguments,
      returnType: returnType,
      expectError: expectError,
    );
    return ft.instantiate(typeArguments);
  }
}
