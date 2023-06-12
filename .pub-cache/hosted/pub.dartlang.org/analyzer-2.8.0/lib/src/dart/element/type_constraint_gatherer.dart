// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

/// A constraint on the type [parameter] that we're inferring.
/// We require that `lower <: parameter <: upper`.
class TypeConstraint {
  final TypeParameterElement parameter;
  final DartType lower;
  final DartType upper;

  TypeConstraint._(this.parameter, this.lower, this.upper);

  bool get isEmpty {
    return identical(lower, UnknownInferredType.instance) &&
        identical(upper, UnknownInferredType.instance);
  }

  @override
  String toString() {
    var lowerStr = lower.getDisplayString(withNullability: true);
    var upperStr = upper.getDisplayString(withNullability: true);
    return '$lowerStr <: ${parameter.name} <: $upperStr';
  }
}

/// Creates sets of [TypeConstraint]s for type parameters, based on an attempt
/// to make one type schema a subtype of another.
class TypeConstraintGatherer {
  final TypeSystemImpl _typeSystem;
  final Set<TypeParameterElement> _typeParameters = Set.identity();
  final List<TypeConstraint> _constraints = [];

  TypeConstraintGatherer({
    required TypeSystemImpl typeSystem,
    required Iterable<TypeParameterElement> typeParameters,
  }) : _typeSystem = typeSystem {
    _typeParameters.addAll(typeParameters);
  }

  DartType get _defaultTypeParameterBound {
    if (_typeSystem.isNonNullableByDefault) {
      return _typeSystem.objectQuestion;
    } else {
      return DynamicTypeImpl.instance;
    }
  }

  /// Returns the set of type constraints that was gathered.
  Map<TypeParameterElement, TypeConstraint> computeConstraints() {
    var result = <TypeParameterElement, TypeConstraint>{};
    for (var parameter in _typeParameters) {
      result[parameter] = TypeConstraint._(
        parameter,
        UnknownInferredType.instance,
        UnknownInferredType.instance,
      );
    }

    for (var constraint in _constraints) {
      var parameter = constraint.parameter;
      var mergedConstraint = result[parameter]!;

      var lower = _typeSystem.getLeastUpperBound(
        mergedConstraint.lower,
        constraint.lower,
      );

      var upper = _typeSystem.getGreatestLowerBound(
        mergedConstraint.upper,
        constraint.upper,
      );

      result[parameter] = TypeConstraint._(parameter, lower, upper);
    }

    return result;
  }

  /// Tries to match [P] as a subtype for [Q].
  ///
  /// If the match succeeds, the resulting type constraints are recorded for
  /// later use by [computeConstraints].  If the match fails, the set of type
  /// constraints is unchanged.
  bool trySubtypeMatch(DartType P, DartType Q, bool leftSchema) {
    // If `P` is `_` then the match holds with no constraints.
    if (identical(P, UnknownInferredType.instance)) {
      return true;
    }

    // If `Q` is `_` then the match holds with no constraints.
    if (identical(Q, UnknownInferredType.instance)) {
      return true;
    }

    // If `P` is a type variable `X` in `L`, then the match holds:
    //   Under constraint `_ <: X <: Q`.
    var P_nullability = P.nullabilitySuffix;
    if (P is TypeParameterType &&
        P_nullability == NullabilitySuffix.none &&
        _typeParameters.contains(P.element)) {
      _addUpper(P.element, Q);
      return true;
    }

    // If `Q` is a type variable `X` in `L`, then the match holds:
    //   Under constraint `P <: X <: _`.
    var Q_nullability = Q.nullabilitySuffix;
    if (Q is TypeParameterType &&
        Q_nullability == NullabilitySuffix.none &&
        _typeParameters.contains(Q.element)) {
      _addLower(Q.element, P);
      return true;
    }

    // If `P` and `Q` are identical types, then the subtype match holds
    // under no constraints.
    if (P == Q) {
      return true;
    }

    // If `P` is a legacy type `P0*` then the match holds under constraint
    // set `C`:
    //   Only if `P0` is a subtype match for `Q` under constraint set `C`.
    if (P_nullability == NullabilitySuffix.star) {
      var P0 = (P as TypeImpl).withNullability(NullabilitySuffix.none);
      return trySubtypeMatch(P0, Q, leftSchema);
    }

    // If `Q` is a legacy type `Q0*` then the match holds under constraint
    // set `C`:
    if (Q_nullability == NullabilitySuffix.star) {
      // If `P` is `dynamic` or `void` and `P` is a subtype match
      // for `Q0` under constraint set `C`.
      if (identical(P, DynamicTypeImpl.instance) ||
          identical(P, VoidTypeImpl.instance)) {
        var rewind = _constraints.length;
        var Q0 = (Q as TypeImpl).withNullability(NullabilitySuffix.none);
        if (trySubtypeMatch(P, Q0, leftSchema)) {
          return true;
        }
        _constraints.length = rewind;
      }
      // Or if `P` is a subtype match for `Q0?` under constraint set `C`.
      var Qq = (Q as TypeImpl).withNullability(NullabilitySuffix.question);
      return trySubtypeMatch(P, Qq, leftSchema);
    }

    // If `Q` is `FutureOr<Q0>` the match holds under constraint set `C`:
    if (Q_nullability == NullabilitySuffix.none &&
        Q is InterfaceType &&
        Q.isDartAsyncFutureOr) {
      var Q0 = Q.typeArguments[0];
      var rewind = _constraints.length;

      // If `P` is `FutureOr<P0>` and `P0` is a subtype match for `Q0` under
      // constraint set `C`.
      if (P_nullability == NullabilitySuffix.none &&
          P is InterfaceType &&
          P.isDartAsyncFutureOr) {
        var P0 = P.typeArguments[0];
        if (trySubtypeMatch(P0, Q0, leftSchema)) {
          return true;
        }
        _constraints.length = rewind;
      }

      // Or if `P` is a subtype match for `Future<Q0>` under non-empty
      // constraint set `C`.
      var futureQ0 = _futureNone(Q0);
      var P_matches_FutureQ0 = trySubtypeMatch(P, futureQ0, leftSchema);
      if (P_matches_FutureQ0 && _constraints.length != rewind) {
        return true;
      }
      _constraints.length = rewind;

      // Or if `P` is a subtype match for `Q0` under constraint set `C`.
      if (trySubtypeMatch(P, Q0, leftSchema)) {
        return true;
      }
      _constraints.length = rewind;

      // Or if `P` is a subtype match for `Future<Q0>` under empty
      // constraint set `C`.
      if (P_matches_FutureQ0) {
        return true;
      }
    }

    // If `Q` is `Q0?` the match holds under constraint set `C`:
    if (Q_nullability == NullabilitySuffix.question) {
      var Q0 = (Q as TypeImpl).withNullability(NullabilitySuffix.none);
      var rewind = _constraints.length;

      // If `P` is `P0?` and `P0` is a subtype match for `Q0` under
      // constraint set `C`.
      if (P_nullability == NullabilitySuffix.question) {
        var P0 = (P as TypeImpl).withNullability(NullabilitySuffix.none);
        if (trySubtypeMatch(P0, Q0, leftSchema)) {
          return true;
        }
        _constraints.length = rewind;
      }

      // Or if `P` is `dynamic` or `void` and `Object` is a subtype match
      // for `Q0` under constraint set `C`.
      if (identical(P, DynamicTypeImpl.instance) ||
          identical(P, VoidTypeImpl.instance)) {
        if (trySubtypeMatch(_typeSystem.objectNone, Q0, leftSchema)) {
          return true;
        }
        _constraints.length = rewind;
      }

      // Or if `P` is a subtype match for `Q0` under non-empty
      // constraint set `C`.
      var P_matches_Q0 = trySubtypeMatch(P, Q0, leftSchema);
      if (P_matches_Q0 && _constraints.length != rewind) {
        return true;
      }
      _constraints.length = rewind;

      // Or if `P` is a subtype match for `Null` under constraint set `C`.
      if (trySubtypeMatch(P, _typeSystem.nullNone, leftSchema)) {
        return true;
      }
      _constraints.length = rewind;

      // Or if `P` is a subtype match for `Q0` under empty
      // constraint set `C`.
      if (P_matches_Q0) {
        return true;
      }
    }

    // If `P` is `FutureOr<P0>` the match holds under constraint set `C1 + C2`:
    if (P_nullability == NullabilitySuffix.none &&
        P is InterfaceType &&
        P.isDartAsyncFutureOr) {
      var P0 = P.typeArguments[0];
      var rewind = _constraints.length;

      // If `Future<P0>` is a subtype match for `Q` under constraint set `C1`.
      // And if `P0` is a subtype match for `Q` under constraint set `C2`.
      var future_P0 = _futureNone(P0);
      if (trySubtypeMatch(future_P0, Q, leftSchema) &&
          trySubtypeMatch(P0, Q, leftSchema)) {
        return true;
      }

      _constraints.length = rewind;
    }

    // If `P` is `P0?` the match holds under constraint set `C1 + C2`:
    if (P_nullability == NullabilitySuffix.question) {
      var P0 = (P as TypeImpl).withNullability(NullabilitySuffix.none);
      var rewind = _constraints.length;

      // If `P0` is a subtype match for `Q` under constraint set `C1`.
      // And if `Null` is a subtype match for `Q` under constraint set `C2`.
      if (trySubtypeMatch(P0, Q, leftSchema) &&
          trySubtypeMatch(_typeSystem.nullNone, Q, leftSchema)) {
        return true;
      }

      _constraints.length = rewind;
    }

    // If `Q` is `dynamic`, `Object?`, or `void` then the match holds under
    // no constraints.
    if (identical(Q, DynamicTypeImpl.instance) ||
        identical(Q, VoidTypeImpl.instance) ||
        Q_nullability == NullabilitySuffix.question && Q.isDartCoreObject) {
      return true;
    }

    // If `P` is `Never` then the match holds under no constraints.
    if (identical(P, NeverTypeImpl.instance)) {
      return true;
    }

    // If `Q` is `Object`, then the match holds under no constraints:
    //  Only if `P` is non-nullable.
    if (Q_nullability == NullabilitySuffix.none && Q.isDartCoreObject) {
      return _typeSystem.isNonNullable(P);
    }

    // If `P` is `Null`, then the match holds under no constraints:
    //  Only if `Q` is nullable.
    if (P_nullability == NullabilitySuffix.none && P.isDartCoreNull) {
      return _typeSystem.isNullable(Q);
    }

    // If `P` is a type variable `X` with bound `B` (or a promoted type
    // variable `X & B`), the match holds with constraint set `C`:
    //   If `B` is a subtype match for `Q` with constraint set `C`.
    // Note: we have already eliminated the case that `X` is a variable in `L`.
    if (P_nullability == NullabilitySuffix.none && P is TypeParameterTypeImpl) {
      var rewind = _constraints.length;
      var B = P.promotedBound ?? P.element.bound;
      if (B != null && trySubtypeMatch(B, Q, leftSchema)) {
        return true;
      }
      _constraints.length = rewind;
    }

    if (P is InterfaceType && Q is InterfaceType) {
      return _interfaceType(P, Q, leftSchema);
    }

    // If `Q` is `Function` then the match holds under no constraints:
    //   If `P` is a function type.
    if (Q_nullability == NullabilitySuffix.none && Q.isDartCoreFunction) {
      if (P is FunctionType) {
        return true;
      }
    }

    if (P is FunctionType && Q is FunctionType) {
      return _functionType(P, Q, leftSchema);
    }

    return false;
  }

  void _addLower(TypeParameterElement element, DartType lower) {
    _constraints.add(
      TypeConstraint._(element, lower, UnknownInferredType.instance),
    );
  }

  void _addUpper(TypeParameterElement element, DartType upper) {
    _constraints.add(
      TypeConstraint._(element, UnknownInferredType.instance, upper),
    );
  }

  bool _functionType(FunctionType P, FunctionType Q, bool leftSchema) {
    if (P.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    if (Q.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    var P_typeFormals = P.typeFormals;
    var Q_typeFormals = Q.typeFormals;
    if (P_typeFormals.length != Q_typeFormals.length) {
      return false;
    }

    if (P_typeFormals.isEmpty && Q_typeFormals.isEmpty) {
      return _functionType0(P, Q, leftSchema);
    }

    // We match two generic function types:
    // `<T0 extends B00, ..., Tn extends B0n>F0`
    // `<S0 extends B10, ..., Sn extends B1n>F1`
    // with respect to `L` under constraint set `C2`:
    var rewind = _constraints.length;

    // If `B0i` is a subtype match for `B1i` with constraint set `Ci0`.
    // If `B1i` is a subtype match for `B0i` with constraint set `Ci1`.
    // And `Ci2` is `Ci0 + Ci1`.
    for (var i = 0; i < P_typeFormals.length; i++) {
      var B0 = P_typeFormals[i].bound ?? _defaultTypeParameterBound;
      var B1 = Q_typeFormals[i].bound ?? _defaultTypeParameterBound;
      if (!trySubtypeMatch(B0, B1, leftSchema)) {
        _constraints.length = rewind;
        return false;
      }
      if (!trySubtypeMatch(B1, B0, !leftSchema)) {
        _constraints.length = rewind;
        return false;
      }
    }

    // And `Z0...Zn` are fresh variables with bounds `B20, ..., B2n`.
    //   Where `B2i` is `B0i[Z0/T0, ..., Zn/Tn]` if `P` is a type schema.
    //   Or `B2i` is `B1i[Z0/S0, ..., Zn/Sn]` if `Q` is a type schema.
    // In other words, we choose the bounds for the fresh variables from
    // whichever of the two generic function types is a type schema and does
    // not contain any variables from `L`.
    var newTypeParameters = <TypeParameterElement>[];
    for (var i = 0; i < P_typeFormals.length; i++) {
      var Z = TypeParameterElementImpl('Z$i', -1);
      if (leftSchema) {
        Z.bound = P_typeFormals[i].bound;
      } else {
        Z.bound = Q_typeFormals[i].bound;
      }
      newTypeParameters.add(Z);
    }

    // And `F0[Z0/T0, ..., Zn/Tn]` is a subtype match for
    // `F1[Z0/S0, ..., Zn/Sn]` with respect to `L` under constraints `C0`.
    var typeArguments = newTypeParameters
        .map((e) => e.instantiate(nullabilitySuffix: NullabilitySuffix.none))
        .toList();
    var P_instantiated = P.instantiate(typeArguments);
    var Q_instantiated = Q.instantiate(typeArguments);
    if (!_functionType0(P_instantiated, Q_instantiated, leftSchema)) {
      _constraints.length = rewind;
      return false;
    }

    // And `C1` is `C02 + ... + Cn2 + C0`.
    // And `C2` is `C1` with each constraint replaced with its closure
    // with respect to `[Z0, ..., Zn]`.
    // TODO(scheglov) do closure

    return true;
  }

  /// A function type `(M0,..., Mn, [M{n+1}, ..., Mm]) -> R0` is a subtype
  /// match for a function type `(N0,..., Nk, [N{k+1}, ..., Nr]) -> R1` with
  /// respect to `L` under constraints `C0 + ... + Cr + C`.
  bool _functionType0(FunctionType f, FunctionType g, bool leftSchema) {
    var rewind = _constraints.length;

    // If `R0` is a subtype match for a type `R1` with respect to `L` under
    // constraints `C`.
    if (!trySubtypeMatch(f.returnType, g.returnType, leftSchema)) {
      _constraints.length = rewind;
      return false;
    }

    var fParameters = f.parameters;
    var gParameters = g.parameters;

    // And for `i` in `0...r`, `Ni` is a subtype match for `Mi` with respect
    // to `L` under constraints `Ci`.
    var fIndex = 0;
    var gIndex = 0;
    while (fIndex < fParameters.length && gIndex < gParameters.length) {
      var fParameter = fParameters[fIndex];
      var gParameter = gParameters[gIndex];
      if (fParameter.isRequiredPositional) {
        if (gParameter.isRequiredPositional) {
          if (trySubtypeMatch(gParameter.type, fParameter.type, leftSchema)) {
            fIndex++;
            gIndex++;
          } else {
            _constraints.length = rewind;
            return false;
          }
        } else {
          _constraints.length = rewind;
          return false;
        }
      } else if (fParameter.isOptionalPositional) {
        if (gParameter.isPositional) {
          if (trySubtypeMatch(gParameter.type, fParameter.type, leftSchema)) {
            fIndex++;
            gIndex++;
          } else {
            _constraints.length = rewind;
            return false;
          }
        } else {
          _constraints.length = rewind;
          return false;
        }
      } else if (fParameter.isNamed) {
        if (gParameter.isNamed) {
          var compareNames = fParameter.name.compareTo(gParameter.name);
          if (compareNames == 0) {
            if (trySubtypeMatch(gParameter.type, fParameter.type, leftSchema)) {
              fIndex++;
              gIndex++;
            } else {
              _constraints.length = rewind;
              return false;
            }
          } else if (compareNames < 0) {
            if (fParameter.isRequiredNamed) {
              _constraints.length = rewind;
              return false;
            } else {
              fIndex++;
            }
          } else {
            assert(compareNames > 0);
            // The subtype must accept all parameters of the supertype.
            _constraints.length = rewind;
            return false;
          }
        } else {
          break;
        }
      }
    }

    // The supertype must provide all required parameters to the subtype.
    while (fIndex < fParameters.length) {
      var fParameter = fParameters[fIndex++];
      if (fParameter.isNotOptional) {
        _constraints.length = rewind;
        return false;
      }
    }

    // The subtype must accept all parameters of the supertype.
    assert(fIndex == fParameters.length);
    if (gIndex < gParameters.length) {
      _constraints.length = rewind;
      return false;
    }

    return true;
  }

  InterfaceType _futureNone(DartType argument) {
    var element = _typeSystem.typeProvider.futureElement;
    return element.instantiate(
      typeArguments: [argument],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  bool _interfaceType(InterfaceType P, InterfaceType Q, bool leftSchema) {
    if (P.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    if (Q.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    // If `P` is `C<M0, ..., Mk> and `Q` is `C<N0, ..., Nk>`, then the match
    // holds under constraints `C0 + ... + Ck`:
    //   If `Mi` is a subtype match for `Ni` with respect to L under
    //   constraints `Ci`.
    if (P.element == Q.element) {
      if (!_interfaceType_arguments(P, Q, leftSchema)) {
        return false;
      }
      return true;
    }

    // If `P` is `C0<M0, ..., Mk>` and `Q` is `C1<N0, ..., Nj>` then the match
    // holds with respect to `L` under constraints `C`:
    //   If `C1<B0, ..., Bj>` is a superinterface of `C0<M0, ..., Mk>` and
    //   `C1<B0, ..., Bj>` is a subtype match for `C1<N0, ..., Nj>` with
    //   respect to `L` under constraints `C`.
    var C0 = P.element;
    var C1 = Q.element;
    for (var interface in C0.allSupertypes) {
      if (interface.element == C1) {
        var substitution = Substitution.fromInterfaceType(P);
        return _interfaceType_arguments(
          substitution.substituteType(interface) as InterfaceType,
          Q,
          leftSchema,
        );
      }
    }

    return false;
  }

  /// Match arguments of [P] against arguments of [Q].
  /// If returns `false`, the constraints are unchanged.
  bool _interfaceType_arguments(
    InterfaceType P,
    InterfaceType Q,
    bool leftSchema,
  ) {
    assert(P.element == Q.element);

    var rewind = _constraints.length;

    for (var i = 0; i < P.typeArguments.length; i++) {
      var M = P.typeArguments[i];
      var N = Q.typeArguments[i];
      if (!trySubtypeMatch(M, N, leftSchema)) {
        _constraints.length = rewind;
        return false;
      }
    }

    return true;
  }
}
