// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

class GreatestLowerBoundHelper {
  final TypeSystemImpl _typeSystem;

  GreatestLowerBoundHelper(this._typeSystem);

  InterfaceTypeImpl get _nullNone => _typeSystem.nullNone;

  TypeProviderImpl get _typeProvider => _typeSystem.typeProvider;

  /// Computes the greatest lower bound of [T1] and [T2].
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/upper-lower-bounds.md`
  DartType getGreatestLowerBound(DartType T1, DartType T2) {
    // DOWN(T, T) = T
    if (identical(T1, T2)) {
      return T1;
    }

    // For any type T, DOWN(?, T) == T.
    if (identical(T1, UnknownInferredType.instance)) {
      return T2;
    }
    if (identical(T2, UnknownInferredType.instance)) {
      return T1;
    }

    var T1_isTop = _typeSystem.isTop(T1);
    var T2_isTop = _typeSystem.isTop(T2);

    // DOWN(T1, T2) where TOP(T1) and TOP(T2)
    if (T1_isTop && T2_isTop) {
      // * T1 if MORETOP(T2, T1)
      // * T2 otherwise
      if (_typeSystem.isMoreTop(T2, T1)) {
        return T1;
      } else {
        return T2;
      }
    }

    // DOWN(T1, T2) = T2 if TOP(T1)
    if (T1_isTop) {
      return T2;
    }

    // DOWN(T1, T2) = T1 if TOP(T2)
    if (T2_isTop) {
      return T1;
    }

    var T1_isBottom = _typeSystem.isBottom(T1);
    var T2_isBottom = _typeSystem.isBottom(T2);

    // DOWN(T1, T2) where BOTTOM(T1) and BOTTOM(T2)
    if (T1_isBottom && T2_isBottom) {
      // * T1 if MOREBOTTOM(T1, T2)
      // * T2 otherwise
      if (_typeSystem.isMoreBottom(T1, T2)) {
        return T1;
      } else {
        return T2;
      }
    }

    // DOWN(T1, T2) = T1 if BOTTOM(T1)
    if (T1_isBottom) {
      return T1;
    }

    // DOWN(T1, T2) = T2 if BOTTOM(T2)
    if (T2_isBottom) {
      return T2;
    }

    var T1_isNull = _typeSystem.isNull(T1);
    var T2_isNull = _typeSystem.isNull(T2);

    // DOWN(T1, T2) where NULL(T1) and NULL(T2)
    if (T1_isNull && T2_isNull) {
      // * T1 if MOREBOTTOM(T1, T2)
      // * T2 otherwise
      if (_typeSystem.isMoreBottom(T1, T2)) {
        return T1;
      } else {
        return T2;
      }
    }

    var T1_impl = T1 as TypeImpl;
    var T2_impl = T2 as TypeImpl;

    var T1_nullability = T1_impl.nullabilitySuffix;
    var T2_nullability = T2_impl.nullabilitySuffix;

    // DOWN(Null, T2)
    if (T1_nullability == NullabilitySuffix.none && T1.isDartCoreNull) {
      // * Null if Null <: T2
      // * Never otherwise
      if (_typeSystem.isSubtypeOf(_nullNone, T2)) {
        return _nullNone;
      } else {
        return NeverTypeImpl.instance;
      }
    }

    // DOWN(T1, Null)
    if (T2_nullability == NullabilitySuffix.none && T2.isDartCoreNull) {
      // * Null if Null <: T1
      // * Never otherwise
      if (_typeSystem.isSubtypeOf(_nullNone, T1)) {
        return _nullNone;
      } else {
        return NeverTypeImpl.instance;
      }
    }

    var T1_isObject = _typeSystem.isObject(T1);
    var T2_isObject = _typeSystem.isObject(T2);

    // DOWN(T1, T2) where OBJECT(T1) and OBJECT(T2)
    if (T1_isObject && T2_isObject) {
      // * T1 if MORETOP(T2, T1)
      // * T2 otherwise
      if (_typeSystem.isMoreTop(T2, T1)) {
        return T1;
      } else {
        return T2;
      }
    }

    // DOWN(T1, T2) where OBJECT(T1)
    if (T1_isObject) {
      // * T2 if T2 is non-nullable
      if (_typeSystem.isNonNullable(T2)) {
        return T2;
      }

      // * NonNull(T2) if NonNull(T2) is non-nullable
      var T2_nonNull = _typeSystem.promoteToNonNull(T2_impl);
      if (_typeSystem.isNonNullable(T2_nonNull)) {
        return T2_nonNull;
      }

      // * Never otherwise
      return NeverTypeImpl.instance;
    }

    // DOWN(T1, T2) where OBJECT(T2)
    if (T2_isObject) {
      // * T1 if T1 is non-nullable
      if (_typeSystem.isNonNullable(T1)) {
        return T1;
      }

      // * NonNull(T1) if NonNull(T1) is non-nullable
      var T1_nonNull = _typeSystem.promoteToNonNull(T1_impl);
      if (_typeSystem.isNonNullable(T1_nonNull)) {
        return T1_nonNull;
      }

      // * Never otherwise
      return NeverTypeImpl.instance;
    }

    // DOWN(T1*, T2*) = S* where S is DOWN(T1, T2)
    // DOWN(T1*, T2?) = S* where S is DOWN(T1, T2)
    // DOWN(T1?, T2*) = S* where S is DOWN(T1, T2)
    // DOWN(T1*, T2) = S where S is DOWN(T1, T2)
    // DOWN(T1, T2*) = S where S is DOWN(T1, T2)
    // DOWN(T1?, T2?) = S? where S is DOWN(T1, T2)
    // DOWN(T1?, T2) = S where S is DOWN(T1, T2)
    // DOWN(T1, T2?) = S where S is DOWN(T1, T2)
    if (T1_nullability != NullabilitySuffix.none ||
        T2_nullability != NullabilitySuffix.none) {
      var resultNullability = NullabilitySuffix.question;
      if (T1_nullability == NullabilitySuffix.none ||
          T2_nullability == NullabilitySuffix.none) {
        resultNullability = NullabilitySuffix.none;
      } else if (T1_nullability == NullabilitySuffix.star ||
          T2_nullability == NullabilitySuffix.star) {
        resultNullability = NullabilitySuffix.star;
      }
      var T1_none = T1_impl.withNullability(NullabilitySuffix.none);
      var T2_none = T2_impl.withNullability(NullabilitySuffix.none);
      var S = getGreatestLowerBound(T1_none, T2_none);
      return (S as TypeImpl).withNullability(resultNullability);
    }

    assert(T1_nullability == NullabilitySuffix.none);
    assert(T2_nullability == NullabilitySuffix.none);

    if (T1 is FunctionTypeImpl && T2 is FunctionTypeImpl) {
      return _functionType(T1, T2);
    }

    if (T1 is RecordTypeImpl && T2 is RecordTypeImpl) {
      return _recordType(T1, T2);
    }

    // DOWN(T1, T2) = T1 if T1 <: T2
    if (_typeSystem.isSubtypeOf(T1, T2)) {
      return T1;
    }

    // DOWN(T1, T2) = T2 if T2 <: T1
    if (_typeSystem.isSubtypeOf(T2, T1)) {
      return T2;
    }

    // FutureOr<S1>
    if (T1 is InterfaceTypeImpl && T1.isDartAsyncFutureOr) {
      var S1 = T1.typeArguments[0];
      // DOWN(FutureOr<S1>, FutureOr<S2>) = FutureOr(S)
      //   S = DOWN(S1, S2)
      if (T2 is InterfaceTypeImpl && T2.isDartAsyncFutureOr) {
        var S2 = T2.typeArguments[0];
        var S = getGreatestLowerBound(S1, S2);
        return _typeProvider.futureOrType(S);
      }
      // DOWN(FutureOr<S1>, Future<S2>) = Future(S)
      //   S = DOWN(S1, S2)
      if (T2 is InterfaceTypeImpl && T2.isDartAsyncFuture) {
        var S2 = T2.typeArguments[0];
        var S = getGreatestLowerBound(S1, S2);
        return _typeProvider.futureType(S);
      }
      // DOWN(FutureOr<S1>, T2) = DOWN(S1, T2)
      return getGreatestLowerBound(S1, T2);
    }

    // FutureOr<S2>
    if (T2 is InterfaceTypeImpl && T2.isDartAsyncFutureOr) {
      var S2 = T2.typeArguments[0];
      // DOWN(Future<S1>, FutureOr<S2>) = Future<S>
      //   S = DOWN(S1, S2)
      if (T1 is InterfaceTypeImpl && T1.isDartAsyncFuture) {
        var S1 = T1.typeArguments[0];
        var S = getGreatestLowerBound(S1, S2);
        return _typeProvider.futureType(S);
      }
      // DOWN(T1, FutureOr<S2>) = DOWN(T1, S2)
      return getGreatestLowerBound(T1, S2);
    }

    // DOWN(T1, T2) = Never otherwise
    return NeverTypeImpl.instance;
  }

  /// Compute the greatest lower bound of function types [f] and [g].
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/upper-lower-bounds.md`
  DartType _functionType(FunctionType f, FunctionType g) {
    var fTypeFormals = f.typeFormals;
    var gTypeFormals = g.typeFormals;

    // The number of type parameters must be the same.
    // Otherwise the result is `Never`.
    if (fTypeFormals.length != gTypeFormals.length) {
      return NeverTypeImpl.instance;
    }

    // The bounds of type parameters must be equal.
    // Otherwise the result is `Never`.
    var fresh = _typeSystem.relateTypeParameters(f.typeFormals, g.typeFormals);
    if (fresh == null) {
      return NeverTypeImpl.instance;
    }

    f = f.instantiate(fresh.typeParameterTypes);
    g = g.instantiate(fresh.typeParameterTypes);

    var fParameters = f.parameters;
    var gParameters = g.parameters;

    var parameters = <ParameterElement>[];
    var fIndex = 0;
    var gIndex = 0;
    while (fIndex < fParameters.length && gIndex < gParameters.length) {
      var fParameter = fParameters[fIndex];
      var gParameter = gParameters[gIndex];
      if (fParameter.isPositional) {
        if (gParameter.isPositional) {
          fIndex++;
          gIndex++;
          parameters.add(
            fParameter.copyWith(
              type: _typeSystem.getLeastUpperBound(
                fParameter.type,
                gParameter.type,
              ),
              kind: fParameter.isOptional || gParameter.isOptional
                  ? ParameterKind.POSITIONAL
                  : ParameterKind.REQUIRED,
            ),
          );
        } else {
          return NeverTypeImpl.instance;
        }
      } else if (fParameter.isNamed) {
        if (gParameter.isNamed) {
          var compareNames = fParameter.name.compareTo(gParameter.name);
          if (compareNames == 0) {
            fIndex++;
            gIndex++;
            parameters.add(
              fParameter.copyWith(
                type: _typeSystem.getLeastUpperBound(
                  fParameter.type,
                  gParameter.type,
                ),
                kind: fParameter.isRequiredNamed && gParameter.isRequiredNamed
                    ? ParameterKind.NAMED_REQUIRED
                    : ParameterKind.NAMED,
              ),
            );
          } else if (compareNames < 0) {
            fIndex++;
            parameters.add(
              fParameter.copyWith(kind: ParameterKind.NAMED),
            );
          } else {
            assert(compareNames > 0);
            gIndex++;
            parameters.add(
              gParameter.copyWith(kind: ParameterKind.NAMED),
            );
          }
        } else {
          return NeverTypeImpl.instance;
        }
      }
    }

    while (fIndex < fParameters.length) {
      var fParameter = fParameters[fIndex++];
      if (fParameter.isPositional) {
        parameters.add(
          fParameter.copyWith(kind: ParameterKind.POSITIONAL),
        );
      } else {
        assert(fParameter.isNamed);
        parameters.add(
          fParameter.copyWith(kind: ParameterKind.NAMED),
        );
      }
    }

    while (gIndex < gParameters.length) {
      var gParameter = gParameters[gIndex++];
      if (gParameter.isPositional) {
        parameters.add(
          gParameter.copyWith(kind: ParameterKind.POSITIONAL),
        );
      } else {
        assert(gParameter.isNamed);
        parameters.add(
          gParameter.copyWith(kind: ParameterKind.NAMED),
        );
      }
    }

    var returnType = getGreatestLowerBound(f.returnType, g.returnType);

    return FunctionTypeImpl(
      typeFormals: fresh.typeParameters,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  DartType _recordType(RecordTypeImpl T1, RecordTypeImpl T2) {
    final positional1 = T1.positionalFields;
    final positional2 = T2.positionalFields;
    if (positional1.length != positional2.length) {
      return _typeSystem.typeProvider.neverType;
    }

    final named1 = T1.namedFields;
    final named2 = T2.namedFields;
    if (named1.length != named2.length) {
      return _typeSystem.typeProvider.neverType;
    }

    final positionalFields = <RecordTypePositionalFieldImpl>[];
    for (var i = 0; i < positional1.length; i++) {
      final field1 = positional1[i];
      final field2 = positional2[i];
      final type = getGreatestLowerBound(field1.type, field2.type);
      positionalFields.add(
        RecordTypePositionalFieldImpl(
          type: type,
        ),
      );
    }

    final namedFields = <RecordTypeNamedFieldImpl>[];
    for (var i = 0; i < named1.length; i++) {
      final field1 = named1[i];
      final field2 = named2[i];
      if (field1.name != field2.name) {
        return _typeSystem.typeProvider.neverType;
      }
      final type = getGreatestLowerBound(field1.type, field2.type);
      namedFields.add(
        RecordTypeNamedFieldImpl(
          name: field1.name,
          type: type,
        ),
      );
    }

    return RecordTypeImpl(
      positionalFields: positionalFields,
      namedFields: namedFields,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}
