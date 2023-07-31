// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeConstraintGathererTest);
  });
}

@reflectiveTest
class TypeConstraintGathererTest extends AbstractTypeSystemTest {
  late final TypeParameterElement T;
  late final TypeParameterType T_none;
  late final TypeParameterType T_question;
  late final TypeParameterType T_star;

  UnknownInferredType get unknownType => UnknownInferredType.instance;

  @override
  void setUp() {
    super.setUp();
    T = typeParameter('T');
    T_none = typeParameterTypeNone(T);
    T_question = typeParameterTypeQuestion(T);
    T_star = typeParameterTypeStar(T);
  }

  /// If `P` and `Q` are identical types, then the subtype match holds
  /// under no constraints.
  test_equal_left_right() {
    _checkMatch([T], intNone, intNone, true, ['_ <: T <: _']);

    _checkMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      true,
      ['_ <: T <: _'],
    );

    var T1 = typeParameter('T1');
    var T2 = typeParameter('T2');
    _checkMatch(
      [T],
      functionTypeNone(
        returnType: typeParameterTypeNone(T1),
        typeFormals: [T1],
      ),
      functionTypeNone(
        returnType: typeParameterTypeNone(T2),
        typeFormals: [T2],
      ),
      true,
      ['_ <: T <: _'],
    );
  }

  test_functionType_hasTypeFormals() {
    var T1 = typeParameter('T1');
    var S1 = typeParameter('S1');

    var T1_none = typeParameterTypeNone(T1);
    var S1_none = typeParameterTypeNone(S1);

    _checkMatch(
      [T],
      functionTypeNone(
        returnType: T_none,
        typeFormals: [T1],
        parameters: [
          requiredParameter(type: T1_none),
        ],
      ),
      functionTypeNone(
        returnType: intNone,
        typeFormals: [S1],
        parameters: [
          requiredParameter(type: S1_none),
        ],
      ),
      false,
      ['_ <: T <: int'],
    );

    _checkMatch(
      [T],
      functionTypeNone(
        returnType: intNone,
        typeFormals: [T1],
        parameters: [
          requiredParameter(type: T1_none),
        ],
      ),
      functionTypeNone(
        returnType: T_none,
        typeFormals: [S1],
        parameters: [
          requiredParameter(type: S1_none),
        ],
      ),
      true,
      ['int <: T <: _'],
    );

    // We unified type formals, but still not match because return types.
    _checkNotMatch(
      [T],
      functionTypeNone(
        returnType: intNone,
        typeFormals: [T1],
        parameters: [
          requiredParameter(type: T1_none),
        ],
      ),
      functionTypeNone(
        returnType: stringNone,
        typeFormals: [S1],
        parameters: [
          requiredParameter(type: S1_none),
        ],
      ),
      false,
    );
  }

  test_functionType_hasTypeFormals_bounds_different_subtype() {
    var T1 = typeParameter('T1', bound: intNone);
    var S1 = typeParameter('S1', bound: numNone);
    _checkNotMatch(
      [T],
      functionTypeNone(returnType: T_none, typeFormals: [T1]),
      functionTypeNone(returnType: intNone, typeFormals: [S1]),
      false,
    );
  }

  test_functionType_hasTypeFormals_bounds_different_top() {
    var T1 = typeParameter('T1', bound: voidNone);
    var S1 = typeParameter('S1', bound: dynamicNone);
    _checkMatch(
      [T],
      functionTypeNone(returnType: T_none, typeFormals: [T1]),
      functionTypeNone(returnType: intNone, typeFormals: [S1]),
      false,
      ['_ <: T <: int'],
    );
  }

  test_functionType_hasTypeFormals_bounds_different_unrelated() {
    var T1 = typeParameter('T1', bound: intNone);
    var S1 = typeParameter('S1', bound: stringNone);
    _checkNotMatch(
      [T],
      functionTypeNone(returnType: T_none, typeFormals: [T1]),
      functionTypeNone(returnType: intNone, typeFormals: [S1]),
      false,
    );
  }

  test_functionType_hasTypeFormals_bounds_same_leftDefault_rightDefault() {
    var T1 = typeParameter('T1');
    var S1 = typeParameter('S1');
    _checkMatch(
      [T],
      functionTypeNone(returnType: T_none, typeFormals: [T1]),
      functionTypeNone(returnType: intNone, typeFormals: [S1]),
      false,
      ['_ <: T <: int'],
    );
  }

  test_functionType_hasTypeFormals_bounds_same_leftDefault_rightObjectQ() {
    var T1 = typeParameter('T1');
    var S1 = typeParameter('S1', bound: objectQuestion);
    _checkMatch(
      [T],
      functionTypeNone(returnType: T_none, typeFormals: [T1]),
      functionTypeNone(returnType: intNone, typeFormals: [S1]),
      false,
      ['_ <: T <: int'],
    );
  }

  @FailingTest(reason: 'Closure of type constraints is not implemented yet')
  test_functionType_hasTypeFormals_closure() {
    var T = typeParameter('T');
    var X = typeParameter('X');
    var Y = typeParameter('Y');

    var T_none = typeParameterTypeNone(T);
    var X_none = typeParameterTypeNone(X);
    var Y_none = typeParameterTypeNone(Y);

    _checkMatch(
      [T],
      functionTypeNone(
        typeFormals: [X],
        returnType: T_none,
        parameters: [
          requiredParameter(type: X_none),
        ],
      ),
      functionTypeNone(
        typeFormals: [Y],
        returnType: listNone(Y_none),
        parameters: [
          requiredParameter(type: Y_none),
        ],
      ),
      true,
      ['_ <: T <: List<Object?>'],
    );
  }

  test_functionType_hasTypeFormals_differentCount() {
    var T1 = typeParameter('T1');
    var S1 = typeParameter('S1');
    var S2 = typeParameter('S2');
    _checkNotMatch(
      [T],
      functionTypeNone(returnType: T_none, typeFormals: [T1]),
      functionTypeNone(returnType: intNone, typeFormals: [S1, S2]),
      false,
    );
  }

  test_functionType_noTypeFormals_parameters_extraOptionalLeft() {
    _checkMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [],
      ),
      true,
      ['_ <: T <: _'],
    );

    _checkMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [],
      ),
      true,
      ['_ <: T <: _'],
    );
  }

  test_functionType_noTypeFormals_parameters_extraRequiredLeft() {
    _checkNotMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [],
      ),
      true,
    );

    _checkNotMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [],
      ),
      true,
    );
  }

  test_functionType_noTypeFormals_parameters_extraRight() {
    _checkNotMatch(
      [T],
      functionTypeNone(returnType: voidNone),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: T_none),
        ],
      ),
      true,
    );
  }

  test_functionType_noTypeFormals_parameters_leftOptionalNamed() {
    _checkMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: T_none),
        ],
      ),
      true,
      ['_ <: T <: int'],
    );

    _checkMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: T_none),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      false,
      ['int <: T <: _'],
    );

    // int vs. String
    _checkNotMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: stringNone),
        ],
      ),
      true,
    );

    // Skip left non-required named.
    _checkMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedParameter(name: 'b', type: intNone),
          namedParameter(name: 'c', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'b', type: T_none),
        ],
      ),
      true,
      ['_ <: T <: int'],
    );

    // Not match if skip left required named.
    _checkNotMatch(
      [T],
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
          namedParameter(name: 'b', type: T_none),
        ],
      ),
      true,
    );

    // Not match if skip right named.
    _checkNotMatch(
      [T],
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'b', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedParameter(name: 'b', type: T_none),
        ],
      ),
      true,
    );
  }

  test_functionType_noTypeFormals_parameters_leftOptionalPositional() {
    void check({
      required DartType left,
      required ParameterElement right,
      required bool leftSchema,
      required String? expected,
    }) {
      var P = functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(type: left),
        ],
      );
      var Q = functionTypeNone(
        returnType: voidNone,
        parameters: [right],
      );

      if (expected != null) {
        _checkMatch([T], P, Q, leftSchema, [expected]);
      } else {
        _checkNotMatch([T], P, Q, leftSchema);
      }
    }

    check(
      left: intNone,
      right: requiredParameter(type: T_none),
      leftSchema: true,
      expected: '_ <: T <: int',
    );
    check(
      left: T_none,
      right: requiredParameter(type: intNone),
      leftSchema: false,
      expected: 'int <: T <: _',
    );

    check(
      left: intNone,
      right: positionalParameter(type: T_none),
      leftSchema: true,
      expected: '_ <: T <: int',
    );
    check(
      left: T_none,
      right: positionalParameter(type: intNone),
      leftSchema: false,
      expected: 'int <: T <: _',
    );

    check(
      left: intNone,
      right: requiredParameter(type: stringNone),
      leftSchema: true,
      expected: null,
    );
    check(
      left: intNone,
      right: positionalParameter(type: stringNone),
      leftSchema: true,
      expected: null,
    );

    check(
      left: intNone,
      right: namedParameter(type: intNone, name: 'a'),
      leftSchema: true,
      expected: null,
    );
    check(
      left: intNone,
      right: namedParameter(type: intNone, name: 'a'),
      leftSchema: false,
      expected: null,
    );
  }

  test_functionType_noTypeFormals_parameters_leftRequiredPositional() {
    void check({
      required DartType left,
      required ParameterElement right,
      required bool leftSchema,
      required String? expected,
    }) {
      var P = functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: left),
        ],
      );
      var Q = functionTypeNone(
        returnType: voidNone,
        parameters: [right],
      );

      if (expected != null) {
        _checkMatch([T], P, Q, leftSchema, [expected]);
      } else {
        _checkNotMatch([T], P, Q, leftSchema);
      }
    }

    check(
      left: intNone,
      right: requiredParameter(type: T_none),
      leftSchema: true,
      expected: '_ <: T <: int',
    );
    check(
      left: T_none,
      right: requiredParameter(type: intNone),
      leftSchema: false,
      expected: 'int <: T <: _',
    );

    check(
      left: intNone,
      right: requiredParameter(type: stringNone),
      leftSchema: true,
      expected: null,
    );

    check(
      left: intNone,
      right: positionalParameter(type: T_none),
      leftSchema: true,
      expected: null,
    );

    check(
      left: intNone,
      right: namedParameter(type: T_none, name: 'a'),
      leftSchema: true,
      expected: null,
    );
  }

  test_functionType_noTypeFormals_returnType() {
    _checkMatch(
      [T],
      functionTypeNone(returnType: T_none),
      functionTypeNone(returnType: intNone),
      false,
      ['_ <: T <: int'],
    );

    _checkNotMatch(
      [T],
      functionTypeNone(returnType: stringNone),
      functionTypeNone(returnType: intNone),
      false,
    );
  }

  /// If `P` is `C<M0, ..., Mk> and `Q` is `C<N0, ..., Nk>`, then the match
  /// holds under constraints `C0 + ... + Ck`:
  ///   If `Mi` is a subtype match for `Ni` with respect to L under
  ///   constraints `Ci`.
  test_interfaceType_same() {
    _checkMatch(
      [T],
      listNone(T_none),
      listNone(numNone),
      false,
      ['_ <: T <: num'],
    );
    _checkMatch(
      [T],
      listNone(intNone),
      listNone(T_none),
      true,
      ['int <: T <: _'],
    );

    _checkNotMatch([T], listNone(intNone), listNone(stringNone), false);

    _checkMatch(
      [T],
      mapNone(intNone, listNone(T_none)),
      mapNone(numNone, listNone(stringNone)),
      false,
      ['_ <: T <: String'],
    );
    _checkMatch(
      [T],
      mapNone(intNone, listNone(stringNone)),
      mapNone(numNone, listNone(T_none)),
      true,
      ['String <: T <: _'],
    );

    _checkNotMatch(
      [T],
      mapNone(T_none, listNone(intNone)),
      mapNone(numNone, listNone(stringNone)),
      false,
    );
  }

  /// If `P` is `C0<M0, ..., Mk>` and `Q` is `C1<N0, ..., Nj>` then the match
  /// holds with respect to `L` under constraints `C`:
  ///   If `C1<B0, ..., Bj>` is a superinterface of `C0<M0, ..., Mk>` and
  ///   `C1<B0, ..., Bj>` is a subtype match for `C1<N0, ..., Nj>` with
  ///   respect to `L` under constraints `C`.
  test_interfaceType_superInterface() {
    _checkMatch(
      [T],
      listNone(T_none),
      iterableNone(numNone),
      false,
      ['_ <: T <: num'],
    );
    _checkMatch(
      [T],
      listNone(intNone),
      iterableNone(T_none),
      true,
      ['int <: T <: _'],
    );
    _checkMatch(
      [T],
      listNone(intNone),
      iterableStar(T_none),
      true,
      ['int <: T <: _'],
    );

    _checkNotMatch([T], listNone(intNone), iterableNone(stringNone), true);
  }

  void test_interfaceType_topMerge() {
    var testClassIndex = 0;

    void check1(
      DartType extendsTypeArgument,
      DartType implementsTypeArgument,
      String expectedConstraint,
    ) {
      var library = library_(
        uriStr: 'package:test/test.dart',
        analysisContext: analysisContext,
        analysisSession: analysisContext.analysisSession,
        typeSystem: typeSystem,
      );

      // class A<T> {}
      var A = class_(name: 'A', typeParameters: [
        typeParameter('T'),
      ]);
      A.enclosingElement = library.definingCompilationUnit;

      // class B<T> extends A<T> {}
      var B_T = typeParameter('T');
      var B_T_none = typeParameterTypeNone(B_T);
      var B = class_(
        name: 'B',
        typeParameters: [B_T],
        superType: interfaceTypeNone(A, typeArguments: [B_T_none]),
      );
      B.enclosingElement = library.definingCompilationUnit;

      // class Cx extends A<> implements B<> {}
      var C = class_(
        name: 'C${testClassIndex++}',
        superType: interfaceTypeNone(
          A,
          typeArguments: [extendsTypeArgument],
        ),
        interfaces: [
          interfaceTypeNone(
            B,
            typeArguments: [implementsTypeArgument],
          )
        ],
      );
      C.enclosingElement = library.definingCompilationUnit;

      _checkMatch(
        [T],
        interfaceTypeNone(C),
        interfaceTypeNone(A, typeArguments: [T_none]),
        true,
        [expectedConstraint],
      );
    }

    void check(
      DartType typeArgument1,
      DartType typeArgument2,
      String expectedConstraint,
    ) {
      check1(typeArgument1, typeArgument2, expectedConstraint);
      check1(typeArgument2, typeArgument1, expectedConstraint);
    }

    check(objectQuestion, dynamicNone, 'Object? <: T <: _');
    check(objectStar, dynamicNone, 'Object? <: T <: _');
    check(voidNone, objectQuestion, 'Object? <: T <: _');
    check(voidNone, objectStar, 'Object? <: T <: _');
  }

  /// If `P` is `FutureOr<P0>` the match holds under constraint set `C1 + C2`:
  ///   If `Future<P0>` is a subtype match for `Q` under constraint set `C1`.
  ///   And if `P0` is a subtype match for `Q` under constraint set `C2`.
  test_left_futureOr() {
    _checkMatch(
      [T],
      futureOrNone(T_none),
      futureOrNone(intNone),
      false,
      ['_ <: T <: int'],
    );

    // This is 'T <: int' and 'T <: Future<int>'.
    _checkMatch(
      [T],
      futureOrNone(T_none),
      futureNone(intNone),
      false,
      ['_ <: T <: Never'],
    );

    _checkNotMatch([T], futureOrNone(T_none), intNone, false);
  }

  /// If `P` is `Never` then the match holds under no constraints.
  test_left_never() {
    _checkMatch([T], neverNone, intNone, false, ['_ <: T <: _']);
  }

  /// If `P` is `Null`, then the match holds under no constraints:
  ///  Only if `Q` is nullable.
  test_left_null() {
    _checkNotMatch([T], nullNone, intNone, true);

    _checkMatch(
      [T],
      nullNone,
      T_none,
      true,
      ['Null <: T <: _'],
    );

    _checkMatch(
      [T],
      nullNone,
      futureOrNone(T_none),
      true,
      ['Null <: T <: _'],
    );

    void matchNoConstraints(DartType Q) {
      _checkMatch(
        [T],
        nullNone,
        Q,
        true,
        ['_ <: T <: _'],
      );
    }

    matchNoConstraints(listQuestion(T_none));
    matchNoConstraints(stringQuestion);
    matchNoConstraints(voidNone);
    matchNoConstraints(dynamicNone);
    matchNoConstraints(objectQuestion);
    matchNoConstraints(nullNone);
    matchNoConstraints(
      functionTypeQuestion(returnType: voidNone),
    );
  }

  /// If `P` is `P0?` the match holds under constraint set `C1 + C2`:
  ///   If `P0` is a subtype match for `Q` under constraint set `C1`.
  ///   And if `Null` is a subtype match for `Q` under constraint set `C2`.
  test_left_suffixQuestion() {
    // TODO(scheglov) any better test case?
    _checkMatch(
      [T],
      numQuestion,
      dynamicNone,
      true,
      ['_ <: T <: _'],
    );

    _checkNotMatch([T], T_question, intNone, true);
  }

  /// If `P` is a legacy type `P0*` then the match holds under constraint
  /// set `C`:
  ///   Only if `P0` is a subtype match for `Q` under constraint set `C`.
  test_left_suffixStar() {
    _checkMatch([T], T_star, numNone, false, ['_ <: T <: num']);
    _checkMatch([T], T_star, numQuestion, false, ['_ <: T <: num?']);
    _checkMatch([T], T_star, numStar, false, ['_ <: T <: num*']);

    _checkMatch([T], numStar, T_none, true, ['num* <: T <: _']);
    _checkMatch([T], numStar, T_question, true, ['num <: T <: _']);
    _checkMatch([T], numStar, T_star, true, ['num <: T <: _']);
  }

  /// If `Q` is a legacy type `Q0*` then the match holds under constraint
  /// set `C`:
  ///   If `P` is `dynamic` or `void` and `P` is a subtype match for `Q0`
  ///   under constraint set `C`.
  test_left_top_right_legacy() {
    var U = typeParameter('U', bound: objectNone);
    var U_star = typeParameterTypeStar(U);

    _checkMatch([U], dynamicNone, U_star, false, ['dynamic <: U <: _']);
    _checkMatch([U], voidNone, U_star, false, ['void <: U <: _']);
  }

  /// If `Q` is `Q0?` the match holds under constraint set `C`:
  ///   Or if `P` is `dynamic` or `void` and `Object` is a subtype match
  ///   for `Q0` under constraint set `C`.
  test_left_top_right_nullable() {
    var U = typeParameter('U', bound: objectNone);
    var U_question = typeParameterTypeQuestion(U);

    _checkMatch([U], dynamicNone, U_question, false, ['Object <: U <: _']);
    _checkMatch([U], voidNone, U_question, false, ['Object <: U <: _']);
  }

  /// If `P` is a type variable `X` in `L`, then the match holds:
  ///   Under constraint `_ <: X <: Q`.
  test_left_typeParameter() {
    void checkMatch(DartType right, String expected) {
      _checkMatch([T], T_none, right, false, [expected]);
    }

    checkMatch(numNone, '_ <: T <: num');
    checkMatch(numQuestion, '_ <: T <: num?');
    checkMatch(numStar, '_ <: T <: num*');
  }

  /// If `P` is a type variable `X` with bound `B` (or a promoted type
  /// variable `X & B`), the match holds with constraint set `C`:
  ///   If `B` is a subtype match for `Q` with constraint set `C`.
  /// Note: we have already eliminated the case that `X` is a variable in `L`.
  test_left_typeParameterOther() {
    _checkMatch(
      [T],
      typeParameterTypeNone(
        typeParameter('U', bound: intNone),
      ),
      numNone,
      false,
      ['_ <: T <: _'],
    );

    _checkMatch(
      [T],
      promotedTypeParameterTypeNone(
        typeParameter('U'),
        intNone,
      ),
      numNone,
      false,
      ['_ <: T <: _'],
    );

    _checkNotMatch(
      [T],
      typeParameterTypeNone(
        typeParameter('U'),
      ),
      numNone,
      false,
    );
  }

  /// If `P` is `_` then the match holds with no constraints.
  test_left_unknown() {
    _checkMatch([T], unknownType, numNone, true, ['_ <: T <: _']);
  }

  test_recordType_differentShape() {
    _checkNotMatch(
      [T],
      recordTypeNone(
        positionalTypes: [T_none, intNone],
      ),
      recordTypeNone(
        positionalTypes: [intNone],
      ),
      true,
    );

    _checkNotMatch(
      [T],
      recordTypeNone(
        positionalTypes: [T_none],
      ),
      recordTypeNone(
        positionalTypes: [intNone, intNone],
      ),
      true,
    );

    _checkNotMatch(
      [T],
      recordTypeNone(
        namedTypes: {'f1': T_none},
      ),
      recordTypeNone(
        namedTypes: {'f2': intNone},
      ),
      true,
    );

    _checkNotMatch(
      [T],
      recordTypeNone(
        namedTypes: {'f1': T_none, 'f2': intNone},
      ),
      recordTypeNone(
        namedTypes: {'f1': intNone},
      ),
      true,
    );

    _checkNotMatch(
      [T],
      recordTypeNone(
        namedTypes: {'f1': T_none},
      ),
      recordTypeNone(
        namedTypes: {'f1': intNone, 'f2': intNone},
      ),
      true,
    );

    _checkNotMatch(
      [T],
      recordTypeNone(
        positionalTypes: [intNone],
        namedTypes: {'f2': T_none},
      ),
      recordTypeNone(
        namedTypes: {'f1': intNone, 'f2': intNone},
      ),
      true,
    );
  }

  test_recordType_recordClass() {
    _checkMatch(
      [T],
      recordTypeNone(positionalTypes: [T_none]),
      recordNone,
      true,
      ['_ <: T <: _'],
    );
  }

  test_recordType_sameShape_named() {
    _checkMatch(
      [T],
      recordTypeNone(
        namedTypes: {'f1': T_none},
      ),
      recordTypeNone(
        namedTypes: {'f1': intNone},
      ),
      true,
      ['_ <: T <: int'],
    );

    _checkMatch(
      [T],
      recordTypeNone(
        namedTypes: {'f1': intNone},
      ),
      recordTypeNone(
        namedTypes: {'f1': T_none},
      ),
      false,
      ['int <: T <: _'],
    );

    _checkNotMatch(
      [T],
      recordTypeNone(
        namedTypes: {'f1': intNone},
      ),
      recordTypeNone(
        namedTypes: {'f1': stringNone},
      ),
      false,
    );

    _checkMatch(
      [T],
      recordTypeNone(
        namedTypes: {'f1': intNone, 'f2': T_none},
      ),
      recordTypeNone(
        namedTypes: {'f1': numNone, 'f2': stringNone},
      ),
      true,
      ['_ <: T <: String'],
    );

    _checkMatch(
      [T],
      recordTypeNone(
        namedTypes: {'f1': intNone, 'f2': stringNone},
      ),
      recordTypeNone(
        namedTypes: {'f1': numNone, 'f2': T_none},
      ),
      false,
      ['String <: T <: _'],
    );

    _checkNotMatch(
      [T],
      recordTypeNone(
        namedTypes: {'f1': T_none, 'f2': intNone},
        positionalTypes: [T_none, intNone],
      ),
      recordTypeNone(
        namedTypes: {'f1': intNone, 'f2': stringNone},
      ),
      true,
    );
  }

  test_recordType_sameShape_positional() {
    _checkMatch(
      [T],
      recordTypeNone(
        positionalTypes: [T_none],
      ),
      recordTypeNone(
        positionalTypes: [numNone],
      ),
      true,
      ['_ <: T <: num'],
    );

    _checkMatch(
      [T],
      recordTypeNone(
        positionalTypes: [intNone],
      ),
      recordTypeNone(
        positionalTypes: [T_none],
      ),
      false,
      ['int <: T <: _'],
    );

    _checkNotMatch(
      [T],
      recordTypeNone(
        positionalTypes: [intNone],
      ),
      recordTypeNone(
        positionalTypes: [stringNone],
      ),
      false,
    );

    _checkMatch(
      [T],
      recordTypeNone(
        positionalTypes: [intNone, T_none],
      ),
      recordTypeNone(
        positionalTypes: [numNone, stringNone],
      ),
      true,
      ['_ <: T <: String'],
    );

    _checkMatch(
      [T],
      recordTypeNone(
        positionalTypes: [intNone, stringNone],
      ),
      recordTypeNone(
        positionalTypes: [numNone, T_none],
      ),
      false,
      ['String <: T <: _'],
    );

    _checkNotMatch(
      [T],
      recordTypeNone(
        positionalTypes: [T_none, intNone],
      ),
      recordTypeNone(
        positionalTypes: [numNone, stringNone],
      ),
      true,
    );
  }

  test_right_functionClass() {
    _checkMatch(
      [T],
      functionTypeNone(returnType: voidNone),
      functionNone,
      true,
      ['_ <: T <: _'],
    );
  }

  /// If `Q` is `FutureOr<Q0>` the match holds under constraint set `C`:
  test_right_futureOr() {
    // If `P` is `FutureOr<P0>` and `P0` is a subtype match for `Q0` under
    // constraint set `C`.
    _checkMatch(
      [T],
      futureOrNone(T_none),
      futureOrNone(numNone),
      false,
      ['_ <: T <: num'],
    );
    _checkMatch(
      [T],
      futureOrNone(numNone),
      futureOrNone(T_none),
      true,
      ['num <: T <: _'],
    );
    _checkNotMatch(
      [T],
      futureOrNone(stringNone),
      futureOrNone(intNone),
      true,
    );

    // Or if `P` is a subtype match for `Future<Q0>` under non-empty
    // constraint set `C`.
    _checkMatch(
      [T],
      futureNone(T_none),
      futureOrNone(numNone),
      false,
      ['_ <: T <: num'],
    );
    _checkMatch(
      [T],
      futureNone(intNone),
      futureOrNone(T_none),
      true,
      ['int <: T <: _'],
    );
    _checkMatch(
      [T],
      futureNone(intNone),
      futureOrNone(objectNone),
      true,
      ['_ <: T <: _'],
    );
    _checkNotMatch(
      [T],
      futureNone(stringNone),
      futureOrNone(intNone),
      true,
    );

    // Or if `P` is a subtype match for `Q0` under constraint set `C`.
    _checkMatch(
      [T],
      listNone(T_none),
      futureOrNone(listNone(intNone)),
      false,
      ['_ <: T <: int'],
    );
    _checkMatch(
      [T],
      neverNone,
      futureOrNone(T_none),
      true,
      ['Never <: T <: _'],
    );

    // Or if `P` is a subtype match for `Future<Q0>` under empty
    // constraint set `C`.
    _checkMatch(
      [T],
      futureNone(intNone),
      futureOrNone(numNone),
      false,
      ['_ <: T <: _'],
    );

    // Otherwise.
    _checkNotMatch(
      [T],
      listNone(T_none),
      futureOrNone(intNone),
      false,
    );
  }

  /// If `Q` is `Object`, then the match holds under no constraints:
  ///  Only if `P` is non-nullable.
  test_right_object() {
    _checkMatch([T], intNone, objectNone, false, ['_ <: T <: _']);
    _checkNotMatch([T], intQuestion, objectNone, false);

    _checkNotMatch([T], dynamicNone, objectNone, false);

    {
      var U = typeParameter('U', bound: numQuestion);
      _checkNotMatch([T], typeParameterTypeNone(U), objectNone, false);
    }
  }

  /// If `Q` is `Q0?` the match holds under constraint set `C`:
  test_right_suffixQuestion() {
    // If `P` is `P0?` and `P0` is a subtype match for `Q0` under
    // constraint set `C`.
    _checkMatch([T], T_question, numQuestion, false, ['_ <: T <: num']);
    _checkMatch([T], intQuestion, T_question, true, ['int <: T <: _']);

    // Or if `P` is a subtype match for `Q0` under non-empty
    // constraint set `C`.
    _checkMatch(
      [T],
      intNone,
      T_question,
      false,
      ['int <: T <: _'],
    );

    // Or if `P` is a subtype match for `Null` under constraint set `C`.
    _checkMatch([T], nullNone, intQuestion, true, ['_ <: T <: _']);

    // Or if `P` is a subtype match for `Q0` under empty
    // constraint set `C`.
    _checkMatch([T], intNone, intQuestion, true, ['_ <: T <: _']);

    _checkNotMatch([T], intNone, stringQuestion, true);
    _checkNotMatch([T], intQuestion, stringQuestion, true);
    _checkNotMatch([T], intStar, stringQuestion, true);
  }

  /// If `Q` is a legacy type `Q0*` then the match holds under constraint
  /// set `C`:
  ///   Only if `P` is a subtype match for `Q?` under constraint set `C`.
  test_right_suffixStar() {
    _checkMatch([T], T_none, numStar, false, ['_ <: T <: num*']);
    _checkMatch([T], T_star, numStar, false, ['_ <: T <: num*']);
    _checkMatch([T], T_question, numStar, false, ['_ <: T <: num']);

    _checkMatch([T], numNone, T_star, true, ['num <: T <: _']);
    _checkMatch([T], numQuestion, T_star, true, ['num <: T <: _']);
    _checkMatch([T], numStar, T_star, true, ['num <: T <: _']);
  }

  /// If `Q` is `dynamic`, `Object?`, or `void` then the match holds under
  /// no constraints.
  test_right_top() {
    _checkMatch([T], intNone, dynamicNone, false, ['_ <: T <: _']);
    _checkMatch([T], intNone, objectQuestion, false, ['_ <: T <: _']);
    _checkMatch([T], intNone, voidNone, false, ['_ <: T <: _']);
  }

  /// If `Q` is a type variable `X` in `L`, then the match holds:
  ///   Under constraint `P <: X <: _`.
  test_right_typeParameter() {
    void checkMatch(DartType left, String expected) {
      _checkMatch([T], left, T_none, true, [expected]);
    }

    checkMatch(numNone, 'num <: T <: _');
    checkMatch(numQuestion, 'num? <: T <: _');
    checkMatch(numStar, 'num* <: T <: _');
  }

  /// If `Q` is `_` then the match holds with no constraints.
  test_right_unknown() {
    _checkMatch([T], numNone, unknownType, true, ['_ <: T <: _']);
    _checkMatch([T], numNone, unknownType, true, ['_ <: T <: _']);
  }

  void _checkMatch(
    List<TypeParameterElement> typeParameters,
    DartType P,
    DartType Q,
    bool leftSchema,
    List<String> expected,
  ) {
    var gatherer = TypeConstraintGatherer(
      typeSystem: typeSystem,
      typeParameters: typeParameters,
    );

    var isMatch = gatherer.trySubtypeMatch(P, Q, leftSchema);
    expect(isMatch, isTrue);

    var constraints = gatherer.computeConstraints();
    var constraintsStr = constraints.entries.map((e) {
      var lowerStr = e.value.lower.getDisplayString(withNullability: true);
      var upperStr = e.value.upper.getDisplayString(withNullability: true);
      return '$lowerStr <: ${e.key.name} <: $upperStr';
    }).toList();

    expect(constraintsStr, unorderedEquals(expected));
  }

  void _checkNotMatch(
    List<TypeParameterElement> typeParameters,
    DartType P,
    DartType Q,
    bool leftSchema,
  ) {
    var gatherer = TypeConstraintGatherer(
      typeSystem: typeSystem,
      typeParameters: typeParameters,
    );

    var isMatch = gatherer.trySubtypeMatch(P, Q, leftSchema);
    expect(isMatch, isFalse);
    expect(gatherer.isConstraintSetEmpty, isTrue);
  }
}
