// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

class TopMergeHelper {
  final TypeSystemImpl typeSystem;

  TopMergeHelper(this.typeSystem);

  /// Merges two types into a single type.
  /// Compute the canonical representation of [T].
  ///
  /// https://github.com/dart-lang/language/
  /// See `accepted/future-releases/nnbd/feature-specification.md`
  /// See `#classes-defined-in-opted-in-libraries`
  DartType topMerge(DartType T, DartType S) {
    var T_nullability = T.nullabilitySuffix;
    var S_nullability = S.nullabilitySuffix;

    // NNBD_TOP_MERGE(Object?, Object?) = Object?
    var T_isObjectQuestion =
        T_nullability == NullabilitySuffix.question && T.isDartCoreObject;
    var S_isObjectQuestion =
        S_nullability == NullabilitySuffix.question && S.isDartCoreObject;
    if (T_isObjectQuestion && S_isObjectQuestion) {
      return T;
    }

    // NNBD_TOP_MERGE(dynamic, dynamic) = dynamic
    var T_isDynamic = identical(T, DynamicTypeImpl.instance);
    var S_isDynamic = identical(S, DynamicTypeImpl.instance);
    if (T_isDynamic && S_isDynamic) {
      return DynamicTypeImpl.instance;
    }

    if (identical(T, NeverTypeImpl.instance) &&
        identical(S, NeverTypeImpl.instance)) {
      return NeverTypeImpl.instance;
    }

    // NNBD_TOP_MERGE(void, void) = void
    var T_isVoid = identical(T, VoidTypeImpl.instance);
    var S_isVoid = identical(S, VoidTypeImpl.instance);
    if (T_isVoid && S_isVoid) {
      return VoidTypeImpl.instance;
    }

    // NNBD_TOP_MERGE(Object?, void) = void
    // NNBD_TOP_MERGE(void, Object?) = void
    if (T_isObjectQuestion && S_isVoid || T_isVoid && S_isObjectQuestion) {
      return typeSystem.objectQuestion;
    }

    // NNBD_TOP_MERGE(Object*, void) = void
    // NNBD_TOP_MERGE(void, Object*) = void
    var T_isObjectStar =
        T_nullability == NullabilitySuffix.star && T.isDartCoreObject;
    var S_isObjectStar =
        S_nullability == NullabilitySuffix.star && S.isDartCoreObject;
    if (T_isObjectStar && S_isVoid || T_isVoid && S_isObjectStar) {
      return typeSystem.objectQuestion;
    }

    // NNBD_TOP_MERGE(dynamic, void) = void
    // NNBD_TOP_MERGE(void, dynamic) = void
    if (T_isDynamic && S_isVoid || T_isVoid && S_isDynamic) {
      return typeSystem.objectQuestion;
    }

    // NNBD_TOP_MERGE(Object?, dynamic) = Object?
    // NNBD_TOP_MERGE(dynamic, Object?) = Object?
    if (T_isObjectQuestion && S_isDynamic) {
      return T;
    }
    if (T_isDynamic && S_isObjectQuestion) {
      return S;
    }

    // NNBD_TOP_MERGE(Object*, dynamic) = Object?
    // NNBD_TOP_MERGE(dynamic, Object*) = Object?
    if (T_isObjectStar && S_isDynamic || T_isDynamic && S_isObjectStar) {
      return typeSystem.objectQuestion;
    }

    // NNBD_TOP_MERGE(Never*, Null) = Null
    // NNBD_TOP_MERGE(Null, Never*) = Null
    if (identical(T, NeverTypeImpl.instanceLegacy) &&
        S_nullability == NullabilitySuffix.none &&
        S.isDartCoreNull) {
      return S;
    }
    if (T_nullability == NullabilitySuffix.none &&
        T.isDartCoreNull &&
        identical(S, NeverTypeImpl.instanceLegacy)) {
      return T;
    }

    // Merge nullabilities.
    var T_isNone = T_nullability == NullabilitySuffix.none;
    var S_isNone = S_nullability == NullabilitySuffix.none;
    if (!T_isNone || !S_isNone) {
      var T_isQuestion = T_nullability == NullabilitySuffix.question;
      var T_isStar = T_nullability == NullabilitySuffix.star;

      var S_isQuestion = S_nullability == NullabilitySuffix.question;
      var S_isStar = S_nullability == NullabilitySuffix.star;

      NullabilitySuffix resultNullability;
      if (T_isQuestion && S_isQuestion ||
          T_isQuestion && S_isStar ||
          T_isStar && S_isQuestion) {
        // NNBD_TOP_MERGE(T?, S?) = NNBD_TOP_MERGE(T, S)?
        // NNBD_TOP_MERGE(T?, S*) = NNBD_TOP_MERGE(T, S)?
        // NNBD_TOP_MERGE(T*, S?) = NNBD_TOP_MERGE(T, S)?
        resultNullability = NullabilitySuffix.question;
      } else if (T_isStar && S_isStar) {
        // NNBD_TOP_MERGE(T*, S*) = NNBD_TOP_MERGE(T, S)*
        resultNullability = NullabilitySuffix.star;
      } else if (T_isStar && S_isNone || T_isNone && S_isStar) {
        // NNBD_TOP_MERGE(T*, S) = NNBD_TOP_MERGE(T, S)
        // NNBD_TOP_MERGE(T, S*) = NNBD_TOP_MERGE(T, S)
        resultNullability = NullabilitySuffix.none;
      } else {
        throw StateError('$T_nullability vs $S_nullability');
      }

      var T_none = (T as TypeImpl).withNullability(NullabilitySuffix.none);
      var S_none = (S as TypeImpl).withNullability(NullabilitySuffix.none);
      var R_none = topMerge(T_none, S_none) as TypeImpl;
      return R_none.withNullability(resultNullability);
    }

    assert(T_nullability == NullabilitySuffix.none);
    assert(S_nullability == NullabilitySuffix.none);

    // And for all other types, recursively apply the transformation over
    // the structure of the type.
    //
    // For example: NNBD_TOP_MERGE(C<T>, C<S>) = C<NNBD_TOP_MERGE(T, S)>
    //
    // The NNBD_TOP_MERGE of two types is not defined for types which are not
    // otherwise structurally equal.

    if (T is InterfaceType && S is InterfaceType) {
      return _interfaceTypes(T, S);
    }

    if (T is FunctionType && S is FunctionType) {
      return _functionTypes(T, S);
    }

    if (T is TypeParameterType && S is TypeParameterType) {
      if (T.element == S.element) {
        return T;
      } else {
        throw _TopMergeStateError(T, S, 'Not the same type parameters');
      }
    }

    throw _TopMergeStateError(T, S, 'Unexpected pair');
  }

  FunctionTypeImpl _functionTypes(FunctionType T, FunctionType S) {
    var T_typeParameters = T.typeFormals;
    var S_typeParameters = S.typeFormals;
    if (T_typeParameters.length != S_typeParameters.length) {
      throw _TopMergeStateError(T, S, 'Different number of type parameters');
    }

    List<TypeParameterElement> R_typeParameters;
    Substitution? T_Substitution;
    Substitution? S_Substitution;

    DartType mergeTypes(DartType T, DartType S) {
      if (T_Substitution != null && S_Substitution != null) {
        T = T_Substitution.substituteType(T);
        S = S_Substitution.substituteType(S);
      }
      return topMerge(T, S);
    }

    if (T_typeParameters.isNotEmpty) {
      var mergedTypeParameters = _typeParameters(
        T_typeParameters,
        S_typeParameters,
      );
      if (mergedTypeParameters == null) {
        throw _TopMergeStateError(T, S, 'Unable to merge type parameters');
      }
      R_typeParameters = mergedTypeParameters.typeParameters;
      T_Substitution = mergedTypeParameters.aSubstitution;
      S_Substitution = mergedTypeParameters.bSubstitution;
    } else {
      R_typeParameters = const <TypeParameterElement>[];
    }

    var R_returnType = mergeTypes(T.returnType, S.returnType);

    var T_parameters = T.parameters;
    var S_parameters = S.parameters;
    if (T_parameters.length != S_parameters.length) {
      throw _TopMergeStateError(T, S, 'Different number of formal parameters');
    }

    var R_parameters = <ParameterElement>[];
    for (var i = 0; i < T_parameters.length; i++) {
      var T_parameter = T_parameters[i];
      var S_parameter = S_parameters[i];

      var R_kind = _parameterKind(T_parameter, S_parameter);
      if (R_kind == null) {
        throw _TopMergeStateError(T, S, 'Different formal parameter kinds');
      }

      if (T_parameter.isNamed && T_parameter.name != S_parameter.name) {
        throw _TopMergeStateError(T, S, 'Different named parameter names');
      }

      DartType R_type;

      // Given two corresponding parameters of type `T1` and `T2`, where at least
      // one of the parameters is covariant:
      var T_isCovariant = T_parameter.isCovariant;
      var S_isCovariant = S_parameter.isCovariant;
      var R_isCovariant = T_isCovariant || S_isCovariant;
      if (R_isCovariant) {
        var T1 = T_parameter.type;
        var T2 = S_parameter.type;
        var T1_isSubtype = typeSystem.isSubtypeOf(T1, T2);
        var T2_isSubtype = typeSystem.isSubtypeOf(T2, T1);
        if (T1_isSubtype && T2_isSubtype) {
          // if `T1 <: T2` and `T2 <: T1`, then the result is
          // `NNBD_TOP_MERGE(T1, T2)`, and it is covariant.
          R_type = mergeTypes(T_parameter.type, S_parameter.type);
        } else if (T1_isSubtype) {
          // otherwise, if `T1 <: T2`, then the result is
          // `T2` and it is covariant.
          R_type = T2;
        } else {
          // otherwise, the result is `T1` and it is covariant.
          R_type = T1;
        }
      } else {
        R_type = mergeTypes(T_parameter.type, S_parameter.type);
      }

      R_parameters.add(
        T_parameter.copyWith(
          type: R_type,
          kind: R_kind,
        ),
      );
    }

    return FunctionTypeImpl(
      typeFormals: R_typeParameters,
      parameters: R_parameters,
      returnType: R_returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType _interfaceTypes(InterfaceType T, InterfaceType S) {
    if (T.element != S.element) {
      throw _TopMergeStateError(T, S, 'Different class elements');
    }

    var T_arguments = T.typeArguments;
    var S_arguments = S.typeArguments;
    if (T_arguments.isEmpty) {
      return T;
    } else {
      var arguments = List.generate(
        T_arguments.length,
        (i) => topMerge(T_arguments[i], S_arguments[i]),
      );
      return T.element.instantiate(
        typeArguments: arguments,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }
  }

  ParameterKind? _parameterKind(
    ParameterElement T_parameter,
    ParameterElement S_parameter,
  ) {
    // ignore: deprecated_member_use_from_same_package
    var T_kind = T_parameter.parameterKind;

    // ignore: deprecated_member_use_from_same_package
    var S_kind = S_parameter.parameterKind;

    if (T_kind == S_kind) {
      return T_kind;
    }

    // Legacy named vs. Required named.
    if (T_kind == ParameterKind.NAMED_REQUIRED &&
            S_kind == ParameterKind.NAMED ||
        T_kind == ParameterKind.NAMED &&
            S_kind == ParameterKind.NAMED_REQUIRED) {
      return ParameterKind.NAMED_REQUIRED;
    }

    return null;
  }

  _MergeTypeParametersResult? _typeParameters(
    List<TypeParameterElement> aParameters,
    List<TypeParameterElement> bParameters,
  ) {
    if (aParameters.length != bParameters.length) {
      return null;
    }

    var newParameters = <TypeParameterElementImpl>[];
    var newTypes = <TypeParameterType>[];
    for (var i = 0; i < aParameters.length; i++) {
      var name = aParameters[i].name;
      var newParameter = TypeParameterElementImpl.synthetic(name);
      newParameters.add(newParameter);

      var newType = newParameter.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
      newTypes.add(newType);
    }

    var aSubstitution = Substitution.fromPairs(aParameters, newTypes);
    var bSubstitution = Substitution.fromPairs(bParameters, newTypes);
    for (var i = 0; i < aParameters.length; i++) {
      var a = aParameters[i];
      var b = bParameters[i];

      var aBound = a.bound;
      var bBound = b.bound;
      if (aBound == null && bBound == null) {
        // OK, no bound.
      } else if (aBound != null && bBound != null) {
        aBound = aSubstitution.substituteType(aBound);
        bBound = bSubstitution.substituteType(bBound);
        var newBound = topMerge(aBound, bBound);
        newParameters[i].bound = newBound;
      } else {
        return null;
      }
    }

    return _MergeTypeParametersResult(
      newParameters,
      aSubstitution,
      bSubstitution,
    );
  }
}

class _MergeTypeParametersResult {
  final List<TypeParameterElement> typeParameters;
  final Substitution aSubstitution;
  final Substitution bSubstitution;

  _MergeTypeParametersResult(
    this.typeParameters,
    this.aSubstitution,
    this.bSubstitution,
  );
}

/// This error should never happen, because we should never attempt
/// `NNBD_TOP_MERGE` for types that are not subtypes of each other, and
/// already NORM(ed).
class _TopMergeStateError {
  final DartType T;
  final DartType S;
  final String message;

  _TopMergeStateError(this.T, this.S, this.message);
}
