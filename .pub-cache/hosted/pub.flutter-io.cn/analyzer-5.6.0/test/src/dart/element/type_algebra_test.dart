// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubstituteEmptyTest);
    defineReflectiveTests(SubstituteFromInterfaceTypeTest);
    defineReflectiveTests(SubstituteFromPairsTest);
    defineReflectiveTests(SubstituteFromUpperAndLowerBoundsTest);
    defineReflectiveTests(SubstituteTest);
    defineReflectiveTests(SubstituteWithNullabilityTest);
  });
}

@reflectiveTest
class SubstituteEmptyTest extends _Base {
  test_interface() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var type = interfaceTypeNone(A, typeArguments: [intNone]);

    var result = Substitution.empty.substituteType(type);
    expect(result, same(type));
  }
}

@reflectiveTest
class SubstituteFromInterfaceTypeTest extends _Base {
  test_interface() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    // class B<U>  {}
    var U = typeParameter('U');
    var B = class_(name: 'B', typeParameters: [U]);

    var BofInt = interfaceTypeNone(B, typeArguments: [intNone]);
    var substitution = Substitution.fromInterfaceType(BofInt);

    // A<U>
    var type = interfaceTypeNone(A, typeArguments: [typeParameterTypeNone(U)]);
    assertType(type, 'A<U>');

    var result = substitution.substituteType(type);
    assertType(result, 'A<int>');
  }
}

@reflectiveTest
class SubstituteFromPairsTest extends _Base {
  test_interface() async {
    // class A<T, U> {}
    var T = typeParameter('T');
    var U = typeParameter('U');
    var A = class_(name: 'A', typeParameters: [T, U]);

    var type = interfaceTypeNone(
      A,
      typeArguments: [
        typeParameterTypeNone(T),
        typeParameterTypeNone(U),
      ],
    );

    var result = Substitution.fromPairs(
      [T, U],
      [intNone, doubleNone],
    ).substituteType(type);
    assertType(result, 'A<int, double>');
  }
}

@reflectiveTest
class SubstituteFromUpperAndLowerBoundsTest extends _Base {
  test_function() async {
    // T Function(T)
    var T = typeParameter('T');
    var type = functionTypeNone(
      parameters: [
        requiredParameter(type: typeParameterTypeNone(T)),
      ],
      returnType: typeParameterTypeNone(T),
    );

    var result = Substitution.fromUpperAndLowerBounds(
      {T: typeProvider.intType},
      {T: neverNone},
    ).substituteType(type);
    assertType(result, 'int Function(Never)');
  }
}

@reflectiveTest
class SubstituteTest extends _Base {
  test_bottom() async {
    var T = typeParameter('T');
    _assertIdenticalType(typeProvider.bottomType, {T: intNone});
  }

  test_dynamic() async {
    var T = typeParameter('T');
    _assertIdenticalType(typeProvider.dynamicType, {T: intNone});
  }

  test_function_fromAlias_hasRef() async {
    // typedef Alias<T> = void Function();
    var T = typeParameter('T');
    var Alias = typeAlias(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: functionTypeNone(
        returnType: voidNone,
      ),
    );

    var U = typeParameter('U');
    var type = typeAliasTypeNone(Alias, typeArguments: [
      typeParameterTypeNone(U),
    ]);
    assertType(type, 'void Function() via Alias<U>');
    _assertSubstitution(type, {U: intNone}, 'void Function() via Alias<int>');
  }

  test_function_fromAlias_noRef() async {
    // typedef Alias<T> = void Function();
    var T = typeParameter('T');
    var Alias = typeAlias(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: functionTypeNone(
        returnType: voidNone,
      ),
    );

    var type = typeAliasTypeNone(Alias, typeArguments: [doubleNone]);
    assertType(type, 'void Function() via Alias<double>');

    var U = typeParameter('U');
    _assertIdenticalType(type, {U: intNone});
  }

  test_function_fromAlias_noTypeParameters() async {
    // typedef Alias<T> = void Function();
    var T = typeParameter('T');
    var Alias = typeAlias(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: functionTypeNone(
        returnType: voidNone,
      ),
    );

    var type = typeAliasTypeNone(Alias, typeArguments: [intNone]);
    assertType(type, 'void Function() via Alias<int>');

    var U = typeParameter('U');
    _assertIdenticalType(type, {U: intNone});
  }

  test_function_noSubstitutions() async {
    var type = functionTypeNone(
      parameters: [
        requiredParameter(type: intNone),
      ],
      returnType: boolNone,
    );

    var T = typeParameter('T');
    _assertIdenticalType(type, {T: intNone});
  }

  test_function_parameters_returnType() async {
    // typedef F<T, U> = T Function(U u, bool);
    var T = typeParameter('T');
    var U = typeParameter('U');
    var type = functionTypeNone(
      parameters: [
        requiredParameter(type: typeParameterTypeNone(U)),
        requiredParameter(type: boolNone),
      ],
      returnType: typeParameterTypeNone(T),
    );

    assertType(type, 'T Function(U, bool)');
    _assertSubstitution(
      type,
      {T: intNone},
      'int Function(U, bool)',
    );
    _assertSubstitution(
      type,
      {T: intNone, U: doubleNone},
      'int Function(double, bool)',
    );
  }

  test_function_typeFormals() async {
    // typedef F<T> = T Function<U extends T>(U);
    var T = typeParameter('T');
    var U = typeParameter('U', bound: typeParameterTypeNone(T));
    var type = functionTypeNone(
      typeFormals: [U],
      parameters: [
        requiredParameter(type: typeParameterTypeNone(U)),
      ],
      returnType: typeParameterTypeNone(T),
    );

    assertType(type, 'T Function<U extends T>(U)');
    _assertSubstitution(
      type,
      {T: intNone},
      'int Function<U extends int>(U)',
    );
  }

  test_function_typeFormals_bounds() async {
    // class Triple<X, Y, Z> {}
    // typedef F<V> = bool Function<T extends Triplet<T, U, V>, U>();
    var classTriplet = class_(name: 'Triple', typeParameters: [
      typeParameter('X'),
      typeParameter('Y'),
      typeParameter('Z'),
    ]);

    var T = typeParameter('T');
    var U = typeParameter('U');
    var V = typeParameter('V');
    T.bound = interfaceTypeNone(classTriplet, typeArguments: [
      typeParameterTypeNone(T),
      typeParameterTypeNone(U),
      typeParameterTypeNone(V),
    ]);
    var type = functionTypeNone(
      typeFormals: [T, U],
      returnType: boolNone,
    );

    assertType(
      type,
      'bool Function<T extends Triple<T, U, V>, U>()',
    );

    var result = substitute(type, {V: intNone}) as FunctionType;
    assertType(
      result,
      'bool Function<T extends Triple<T, U, int>, U>()',
    );
    var T2 = result.typeFormals[0];
    var U2 = result.typeFormals[1];
    var T2boundArgs = (T2.bound as InterfaceType).typeArguments;
    expect((T2boundArgs[0] as TypeParameterType).element, same(T2));
    expect((T2boundArgs[1] as TypeParameterType).element, same(U2));
  }

  test_interface_arguments() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = interfaceTypeNone(A, typeArguments: [
      typeParameterTypeNone(U),
    ]);

    assertType(type, 'A<U>');
    _assertSubstitution(type, {U: intNone}, 'A<int>');
  }

  test_interface_arguments_deep() async {
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = interfaceTypeNone(A, typeArguments: [
      interfaceTypeNone(
        typeProvider.listElement,
        typeArguments: [
          typeParameterTypeNone(U),
        ],
      )
    ]);
    assertType(type, 'A<List<U>>');

    _assertSubstitution(type, {U: intNone}, 'A<List<int>>');
  }

  test_interface_noArguments() async {
    // class A {}
    var A = class_(name: 'A');

    var type = interfaceTypeNone(A);
    var T = typeParameter('T');
    _assertIdenticalType(type, {T: intNone});
  }

  test_interface_noArguments_inArguments() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var type = interfaceTypeNone(A, typeArguments: [intNone]);

    var U = typeParameter('U');
    _assertIdenticalType(type, {U: doubleNone});
  }

  test_interface_noTypeParameters_fromAlias_hasRef() async {
    // class A {}
    var A = class_(name: 'A');

    // typedef Alias<T> = A;
    var T = typeParameter('T');
    var Alias = typeAlias(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: interfaceTypeNone(A),
    );

    var U = typeParameter('U');
    var type = typeAliasTypeNone(Alias, typeArguments: [
      typeParameterTypeNone(U),
    ]);
    assertType(type, 'A via Alias<U>');
    _assertSubstitution(type, {U: intNone}, 'A via Alias<int>');
  }

  test_interface_noTypeParameters_fromAlias_noRef() async {
    // class A {}
    var A = class_(name: 'A');

    // typedef Alias<T> = A;
    var T = typeParameter('T');
    var Alias = typeAlias(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: interfaceTypeNone(A),
    );

    var type = typeAliasTypeNone(Alias, typeArguments: [doubleNone]);
    assertType(type, 'A via Alias<double>');

    var U = typeParameter('U');
    _assertIdenticalType(type, {U: intNone});
  }

  test_interface_noTypeParameters_fromAlias_noTypeParameters() async {
    // class A {}
    var A = class_(name: 'A');

    // typedef Alias = A;
    var Alias = typeAlias(
      name: 'Alias',
      typeParameters: [],
      aliasedType: interfaceTypeNone(A),
    );

    var type = typeAliasTypeNone(Alias);
    assertType(type, 'A via Alias');

    var T = typeParameter('T');
    _assertIdenticalType(type, {T: intNone});
  }

  test_record_doesNotUseTypeParameter() async {
    final T = typeParameter('T');

    final type = recordTypeNone(
      positionalTypes: [intNone],
    );

    assertType(type, '(int)');
    _assertIdenticalType(type, {T: intNone});
  }

  test_record_fromAlias() async {
    // typedef Alias<T> = (int, String);
    final T = typeParameter('T');
    final Alias = typeAlias(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: recordTypeNone(
        positionalTypes: [intNone, stringNone],
      ),
    );

    final U = typeParameter('U');
    final type = typeAliasTypeNone(Alias, typeArguments: [
      typeParameterTypeNone(U),
    ]);
    assertType(type, '(int, String) via Alias<U>');
    _assertSubstitution(type, {U: intNone}, '(int, String) via Alias<int>');
  }

  test_record_fromAlias2() async {
    // typedef Alias<T> = (T, List<T>);
    final T = typeParameter('T');
    final T_none = typeParameterTypeNone(T);
    final Alias = typeAlias(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: recordTypeNone(
        positionalTypes: [
          T_none,
          listNone(T_none),
        ],
      ),
    );

    final type = typeAliasTypeNone(Alias, typeArguments: [intNone]);
    assertType(type, '(int, List<int>) via Alias<int>');
  }

  test_record_named() async {
    final T = typeParameter('T');
    final T_none = typeParameterTypeNone(T);

    final type = recordTypeNone(
      namedTypes: {
        'f1': T_none,
        'f2': listNone(T_none),
      },
    );

    assertType(type, '({T f1, List<T> f2})');
    _assertSubstitution(type, {T: intNone}, '({int f1, List<int> f2})');
  }

  test_record_positional() async {
    final T = typeParameter('T');
    final T_none = typeParameterTypeNone(T);

    final type = recordTypeNone(
      positionalTypes: [
        T_none,
        listNone(T_none),
      ],
    );

    assertType(type, '(T, List<T>)');
    _assertSubstitution(type, {T: intNone}, '(int, List<int>)');
  }

  test_typeParameter_nullability() async {
    var tElement = typeParameter('T');

    void check(
      NullabilitySuffix typeParameterNullability,
      InterfaceType typeArgument,
      InterfaceType expectedType,
    ) {
      var result = Substitution.fromMap(
        {tElement: typeArgument},
      ).substituteType(
        TypeParameterTypeImpl(
          element: tElement,
          nullabilitySuffix: typeParameterNullability,
        ),
      );
      expect(result, expectedType);
    }

    check(NullabilitySuffix.none, intNone, intNone);
    check(NullabilitySuffix.none, intStar, intStar);
    check(NullabilitySuffix.none, intQuestion, intQuestion);

    check(NullabilitySuffix.star, intNone, intStar);
    check(NullabilitySuffix.star, intStar, intStar);
    check(NullabilitySuffix.star, intQuestion, intQuestion);

    check(NullabilitySuffix.question, intNone, intQuestion);
    check(NullabilitySuffix.question, intStar, intQuestion);
    check(NullabilitySuffix.question, intQuestion, intQuestion);
  }

  test_unknownInferredType() async {
    var T = typeParameter('T');
    _assertIdenticalType(UnknownInferredType.instance, {T: intNone});
  }

  test_void() async {
    var T = typeParameter('T');
    _assertIdenticalType(typeProvider.voidType, {T: intNone});
  }

  test_void_emptyMap() async {
    _assertIdenticalType(intNone, {});
  }

  void _assertIdenticalType(
      DartType type, Map<TypeParameterElement, DartType> substitution) {
    var result = substitute(type, substitution);
    expect(result, same(type));
  }
}

@reflectiveTest
class SubstituteWithNullabilityTest extends _Base {
  SubstituteWithNullabilityTest();

  test_interface_none() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = A.instantiate(
      typeArguments: [
        U.instantiate(nullabilitySuffix: NullabilitySuffix.none),
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    _assertSubstitution(type, {U: intNone}, 'A<int>');
  }

  test_interface_question() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = A.instantiate(
      typeArguments: [
        U.instantiate(nullabilitySuffix: NullabilitySuffix.none),
      ],
      nullabilitySuffix: NullabilitySuffix.question,
    );
    _assertSubstitution(type, {U: intNone}, 'A<int>?');
  }

  test_interface_star() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = A.instantiate(
      typeArguments: [
        U.instantiate(nullabilitySuffix: NullabilitySuffix.none),
      ],
      nullabilitySuffix: NullabilitySuffix.star,
    );
    _assertSubstitution(type, {U: intNone}, 'A<int>*');
  }
}

class _Base extends AbstractTypeSystemTest {
  void assertType(DartType type, String expected) {
    var typeStr = _typeStr(type);
    expect(typeStr, expected);
  }

  void _assertSubstitution(
    DartType type,
    Map<TypeParameterElement, DartType> substitution,
    String expected,
  ) {
    var result = substitute(type, substitution);
    assertType(result, expected);
    expect(result, isNot(same(type)));
  }

  static String _typeStr(DartType type) {
    var result = type.getDisplayString(withNullability: true);

    var alias = type.alias;
    if (alias != null) {
      result += ' via ${alias.element.name}';
      var typeArgumentStrList = alias.typeArguments.map(_typeStr).toList();
      if (typeArgumentStrList.isNotEmpty) {
        result += '<${typeArgumentStrList.join(', ')}>';
      }
    }

    return result;
  }
}
