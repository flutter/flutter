// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

/// Helper for computing canonical presentation of types.
///
/// https://github.com/dart-lang/language
/// See `resources/type-system/normalization.md`
class NormalizeHelper {
  final TypeSystemImpl typeSystem;
  final TypeProviderImpl typeProvider;

  final Set<TypeParameterElement> _typeParameters = {};

  NormalizeHelper(this.typeSystem) : typeProvider = typeSystem.typeProvider;

  DartType normalize(DartType T) {
    return _normalize(T);
  }

  /// NORM(R Function<X extends B>(S)) = R1 Function(X extends B1>(S1)
  ///   * where R1 = NORM(R)
  ///   * and B1 = NORM(B)
  ///   * and S1 = NORM(S)
  FunctionTypeImpl _functionType(FunctionType functionType) {
    var fresh = getFreshTypeParameters(functionType.typeFormals);
    for (var typeParameter in fresh.freshTypeParameters) {
      var bound = typeParameter.bound;
      if (bound != null) {
        var typeParameterImpl = typeParameter as TypeParameterElementImpl;
        typeParameterImpl.bound = _normalize(bound);
      }
    }

    functionType = fresh.applyToFunctionType(functionType);

    return FunctionTypeImpl(
      typeFormals: functionType.typeFormals,
      parameters: functionType.parameters.map((e) {
        return e.copyWith(
          type: _normalize(e.type),
        );
      }).toList(),
      returnType: _normalize(functionType.returnType),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /// NORM(FutureOr<T>)
  DartType _futureOr(InterfaceType T) {
    // * let S be NORM(T)
    var S = _normalize(T.typeArguments[0]);
    var S_nullability = S.nullabilitySuffix;

    // * if S is a top type then S
    if (typeSystem.isTop(S)) {
      return S;
    }

    // * if S is Object then S
    // * if S is Object* then S
    if (S.isDartCoreObject) {
      if (S_nullability == NullabilitySuffix.none ||
          S_nullability == NullabilitySuffix.star) {
        return S;
      }
    }

    // * if S is Never then Future<Never>
    if (identical(S, NeverTypeImpl.instance)) {
      return typeProvider.futureElement.instantiate(
        typeArguments: [NeverTypeImpl.instance],
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    // * if S is Null then Future<Null>?
    if (S_nullability == NullabilitySuffix.none && S.isDartCoreNull) {
      return typeProvider.futureElement.instantiate(
        typeArguments: [typeSystem.nullNone],
        nullabilitySuffix: NullabilitySuffix.question,
      );
    }

    // * else FutureOr<S>
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [S],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  DartType _normalize(DartType T) {
    var T_nullability = T.nullabilitySuffix;

    // NORM(T) = T if T is primitive
    if (identical(T, DynamicTypeImpl.instance) ||
        identical(T, NeverTypeImpl.instance) ||
        identical(T, VoidTypeImpl.instance) ||
        T_nullability == NullabilitySuffix.none &&
            T is InterfaceType &&
            T.typeArguments.isEmpty) {
      return T;
    }

    // NORM(FutureOr<T>)
    if (T_nullability == NullabilitySuffix.none &&
        T is InterfaceType &&
        T.isDartAsyncFutureOr) {
      return _futureOr(T);
    }

    // NORM(T?)
    if (T_nullability == NullabilitySuffix.question) {
      return _nullabilityQuestion(T);
    }

    // NORM(T*)
    if (T_nullability == NullabilitySuffix.star) {
      return _nullabilityStar(T);
    }

    assert(T_nullability == NullabilitySuffix.none);

    // NORM(X extends T)
    // NORM(X & T)
    if (T is TypeParameterTypeImpl) {
      return _typeParameterType(T);
    }

    // NORM(C<T0, ..., Tn>) = C<R0, ..., Rn> where Ri is NORM(Ti)
    if (T is InterfaceType) {
      return T.element.instantiate(
        typeArguments: T.typeArguments.map(_normalize).toList(),
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    // NORM(R Function<X extends B>(S)) = R1 Function(X extends B1>(S1)
    return _functionType(T as FunctionType);
  }

  /// NORM(T?)
  DartType _nullabilityQuestion(DartType T) {
    // * let S be NORM(T)
    var T_none = (T as TypeImpl).withNullability(NullabilitySuffix.none);
    var S = _normalize(T_none);
    var S_nullability = S.nullabilitySuffix;

    // * if S is a top type then S
    if (typeSystem.isTop(S)) {
      return S;
    }

    // * if S is Never then Null
    if (identical(S, NeverTypeImpl.instance)) {
      return typeSystem.nullNone;
    }

    // * if S is Never* then Null
    if (identical(S, NeverTypeImpl.instanceLegacy)) {
      return typeSystem.nullNone;
    }

    // * if S is Null then Null
    if (S_nullability == NullabilitySuffix.none && S.isDartCoreNull) {
      return typeSystem.nullNone;
    }

    // * if S is FutureOr<R> and R is nullable then S
    if (S_nullability == NullabilitySuffix.none &&
        S is InterfaceType &&
        S.isDartAsyncFutureOr) {
      var R = S.typeArguments[0];
      if (typeSystem.isNullable(R)) {
        return S;
      }
    }

    // * if S is FutureOr<R>* and R is nullable then FutureOr<R>
    if (S_nullability == NullabilitySuffix.star &&
        S is InterfaceType &&
        S.isDartAsyncFutureOr) {
      var R = S.typeArguments[0];
      if (typeSystem.isNullable(R)) {
        return typeProvider.futureOrElement.instantiate(
          typeArguments: [R],
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }

    // * if S is R? then R?
    // * if S is R* then R?
    // * else S?
    return (S as TypeImpl).withNullability(NullabilitySuffix.question);
  }

  /// NORM(T*)
  DartType _nullabilityStar(DartType T) {
    // * let S be NORM(T)
    var T_none = (T as TypeImpl).withNullability(NullabilitySuffix.none);
    var S = _normalize(T_none);
    var S_nullability = S.nullabilitySuffix;

    // * if S is a top type then S
    if (typeSystem.isTop(S)) {
      return S;
    }

    // * if S is Null then Null
    if (S_nullability == NullabilitySuffix.none && S.isDartCoreNull) {
      return typeSystem.nullNone;
    }

    // * if S is R? then R?
    if (S_nullability == NullabilitySuffix.question) {
      return S;
    }

    // * if S is R* then R*
    // * else S*
    return (S as TypeImpl).withNullability(NullabilitySuffix.star);
  }

  /// NORM(X & T)
  /// NORM(X extends T)
  DartType _typeParameterType(TypeParameterTypeImpl T) {
    var element = T.element;

    // NORM(X & T)
    var promotedBound = T.promotedBound;
    if (promotedBound != null) {
      // let S be NORM(T)
      var S = _normalize(promotedBound);
      return _typeParameterType_promoted(element, S);
    }

    var bound = element.bound;
    if (bound == null) {
      return T;
    }

    // * let S be NORM(T)
    DartType S;
    if (_typeParameters.add(element)) {
      S = _normalize(bound);
      _typeParameters.remove(element);
    } else {
      return T;
    }

    // * if S is Never then Never
    if (identical(S, NeverTypeImpl.instance)) {
      return NeverTypeImpl.instance;
    }

    // else X extends T
    return T;
  }

  /// NORM(X & T)
  /// * let S be NORM(T)
  DartType _typeParameterType_promoted(TypeParameterElement X, DartType S) {
    // * if S is Never then Never
    if (identical(S, NeverTypeImpl.instance)) {
      return NeverTypeImpl.instance;
    }

    // * if S is a top type then X
    if (typeSystem.isTop(S)) {
      return X.declaration.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    // * if S is X then X
    if (S is TypeParameterType &&
        S.nullabilitySuffix == NullabilitySuffix.none &&
        S.element == X.declaration) {
      return X.declaration.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    // * if S is Object and NORM(B) is Object where B is the bound of X then X
    if (S.nullabilitySuffix == NullabilitySuffix.none && S.isDartCoreObject) {
      var B = X.declaration.bound;
      if (B != null) {
        var B_norm = _normalize(B);
        if (B_norm.nullabilitySuffix == NullabilitySuffix.none &&
            B_norm.isDartCoreObject) {
          return X.declaration.instantiate(
            nullabilitySuffix: NullabilitySuffix.none,
          );
        }
      }
    }

    // * else X & S
    return TypeParameterTypeImpl(
      element: X.declaration,
      nullabilitySuffix: NullabilitySuffix.none,
      promotedBound: S,
    );
  }
}
