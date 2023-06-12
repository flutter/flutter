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
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/// Helper for checking the subtype relation.
///
/// https://github.com/dart-lang/language
/// See `resources/type-system/subtyping.md`
class SubtypeHelper {
  final TypeProviderImpl _typeProvider;
  final InterfaceTypeImpl _nullNone;
  final InterfaceTypeImpl _objectNone;
  final InterfaceTypeImpl _objectQuestion;

  SubtypeHelper(TypeSystemImpl typeSystem)
      : _typeProvider = typeSystem.typeProvider,
        _nullNone = typeSystem.nullNone,
        _objectNone = typeSystem.objectNone,
        _objectQuestion = typeSystem.objectQuestion;

  /// Return `true` if [_T0] is a subtype of [_T1].
  bool isSubtypeOf(DartType _T0, DartType _T1) {
    // Reflexivity: if `T0` and `T1` are the same type then `T0 <: T1`.
    if (identical(_T0, _T1)) {
      return true;
    }

    // `_` is treated as a top and a bottom type during inference.
    if (identical(_T0, UnknownInferredType.instance) ||
        identical(_T1, UnknownInferredType.instance)) {
      return true;
    }

    var T0 = _T0 as TypeImpl;
    var T1 = _T1 as TypeImpl;

    var T1_nullability = T1.nullabilitySuffix;
    var T0_nullability = T0.nullabilitySuffix;

    // Right Top: if `T1` is a top type (i.e. `dynamic`, or `void`, or
    // `Object?`) then `T0 <: T1`.
    if (identical(T1, DynamicTypeImpl.instance) ||
        identical(T1, VoidTypeImpl.instance) ||
        T1_nullability == NullabilitySuffix.question && T1.isDartCoreObject) {
      return true;
    }

    // Left Top: if `T0` is `dynamic` or `void`,
    //   then `T0 <: T1` if `Object? <: T1`.
    if (identical(T0, DynamicTypeImpl.instance) ||
        identical(T0, VoidTypeImpl.instance)) {
      if (isSubtypeOf(_objectQuestion, T1)) {
        return true;
      }
    }

    // Left Bottom: if `T0` is `Never`, then `T0 <: T1`.
    if (identical(T0, NeverTypeImpl.instance)) {
      return true;
    }

    // Right Object: if `T1` is `Object` then:
    if (T1_nullability == NullabilitySuffix.none && T1.isDartCoreObject) {
      // * if `T0` is an unpromoted type variable with bound `B`,
      //   then `T0 <: T1` iff `B <: Object`.
      // * if `T0` is a promoted type variable `X & S`,
      //   then `T0 <: T1` iff `S <: Object`.
      if (T0_nullability == NullabilitySuffix.none &&
          T0 is TypeParameterTypeImpl) {
        var S = T0.promotedBound;
        if (S == null) {
          var B = T0.element.bound ?? _objectQuestion;
          return isSubtypeOf(B, _objectNone);
        } else {
          return isSubtypeOf(S, _objectNone);
        }
      }
      // * if `T0` is `FutureOr<S>` for some `S`,
      //   then `T0 <: T1` iff `S <: Object`
      if (T0_nullability == NullabilitySuffix.none &&
          T0 is InterfaceTypeImpl &&
          T0.isDartAsyncFutureOr) {
        return isSubtypeOf(T0.typeArguments[0], T1);
      }
      // * if `T0` is `S*` for any `S`, then `T0 <: T1` iff `S <: T1`
      if (T0_nullability == NullabilitySuffix.star) {
        return isSubtypeOf(
          T0.withNullability(NullabilitySuffix.none),
          T1,
        );
      }
      // * if `T0` is `Null`, `dynamic`, `void`, or `S?` for any `S`,
      //   then the subtyping does not hold, the result is false.
      if (T0_nullability == NullabilitySuffix.none && T0.isDartCoreNull ||
          identical(T0, DynamicTypeImpl.instance) ||
          identical(T0, VoidTypeImpl.instance) ||
          T0_nullability == NullabilitySuffix.question) {
        return false;
      }
      // Otherwise `T0 <: T1` is true.
      return true;
    }

    // Left Null: if `T0` is `Null` then:
    if (T0_nullability == NullabilitySuffix.none && T0.isDartCoreNull) {
      // * If `T1` is `FutureOr<S>` for some `S`, then the query is true iff
      // `Null <: S`.
      if (T1_nullability == NullabilitySuffix.none &&
          T1 is InterfaceTypeImpl &&
          T1.isDartAsyncFutureOr) {
        var S = T1.typeArguments[0];
        return isSubtypeOf(_nullNone, S);
      }
      // If `T1` is `Null`, `S?` or `S*` for some `S`, then the query is true.
      if (T1_nullability == NullabilitySuffix.none && T1.isDartCoreNull ||
          T1_nullability == NullabilitySuffix.question ||
          T1_nullability == NullabilitySuffix.star) {
        return true;
      }
      // * if `T1` is a type variable (promoted or not) the query is false
      if (T1 is TypeParameterTypeImpl) {
        return false;
      }
      // Otherwise, the query is false.
      return false;
    }

    // Left Legacy if `T0` is `S0*` then:
    if (T0_nullability == NullabilitySuffix.star) {
      // * `T0 <: T1` iff `S0 <: T1`.
      var S0 = T0.withNullability(NullabilitySuffix.none);
      return isSubtypeOf(S0, T1);
    }

    // Right Legacy `T1` is `S1*` then:
    //   * `T0 <: T1` iff `T0 <: S1?`.
    if (T1_nullability == NullabilitySuffix.star) {
      if (T1 is FunctionType && _isFunctionTypeWithNamedRequired(T0)) {
        T1 = _functionTypeWithNamedRequired(T1 as FunctionType);
      }
      var S1 = T1.withNullability(NullabilitySuffix.question);
      return isSubtypeOf(T0, S1);
    }

    // Left FutureOr: if `T0` is `FutureOr<S0>` then:
    if (T0_nullability == NullabilitySuffix.none &&
        T0 is InterfaceTypeImpl &&
        T0.isDartAsyncFutureOr) {
      var S0 = T0.typeArguments[0];
      // * `T0 <: T1` iff `Future<S0> <: T1` and `S0 <: T1`
      if (isSubtypeOf(S0, T1)) {
        var FutureS0 = _typeProvider.futureElement.instantiate(
          typeArguments: [S0],
          nullabilitySuffix: NullabilitySuffix.none,
        );
        return isSubtypeOf(FutureS0, T1);
      }
      return false;
    }

    // Left Nullable: if `T0` is `S0?` then:
    //   * `T0 <: T1` iff `S0 <: T1` and `Null <: T1`.
    if (T0_nullability == NullabilitySuffix.question) {
      var S0 = T0.withNullability(NullabilitySuffix.none);
      return isSubtypeOf(S0, T1) && isSubtypeOf(_nullNone, T1);
    }

    // Type Variable Reflexivity 1: if T0 is a type variable X0 or a promoted
    // type variables X0 & S0 and T1 is X0 then:
    //   * T0 <: T1
    if (T0 is TypeParameterTypeImpl &&
        T1 is TypeParameterTypeImpl &&
        T1.promotedBound == null &&
        T0.element == T1.element) {
      return true;
    }

    // Right Promoted Variable: if `T1` is a promoted type variable `X1 & S1`:
    //   * `T0 <: T1` iff `T0 <: X1` and `T0 <: S1`
    if (T1 is TypeParameterTypeImpl) {
      var T1_promotedBound = T1.promotedBound;
      if (T1_promotedBound != null) {
        var X1 = TypeParameterTypeImpl(
          element: T1.element,
          nullabilitySuffix: T1.nullabilitySuffix,
        );
        return isSubtypeOf(T0, X1) && isSubtypeOf(T0, T1_promotedBound);
      }
    }

    // Right FutureOr: if `T1` is `FutureOr<S1>` then:
    if (T1_nullability == NullabilitySuffix.none &&
        T1 is InterfaceTypeImpl &&
        T1.isDartAsyncFutureOr) {
      var S1 = T1.typeArguments[0];
      // `T0 <: T1` iff any of the following hold:
      // * either `T0 <: Future<S1>`
      var FutureS1 = _typeProvider.futureElement.instantiate(
        typeArguments: [S1],
        nullabilitySuffix: NullabilitySuffix.none,
      );
      if (isSubtypeOf(T0, FutureS1)) {
        return true;
      }
      // * or `T0 <: S1`
      if (isSubtypeOf(T0, S1)) {
        return true;
      }
      // * or `T0` is `X0` and `X0` has bound `S0` and `S0 <: T1`
      // * or `T0` is `X0 & S0` and `S0 <: T1`
      if (T0 is TypeParameterTypeImpl) {
        var S0 = T0.promotedBound;
        if (S0 != null && isSubtypeOf(S0, T1)) {
          return true;
        }
        var B0 = T0.element.bound;
        if (B0 != null && isSubtypeOf(B0, T1)) {
          return true;
        }
      }
      // iff
      return false;
    }

    // Right Nullable: if `T1` is `S1?` then:
    if (T1_nullability == NullabilitySuffix.question) {
      var S1 = T1.withNullability(NullabilitySuffix.none);
      // `T0 <: T1` iff any of the following hold:
      // * either `T0 <: S1`
      if (isSubtypeOf(T0, S1)) {
        return true;
      }
      // * or `T0 <: Null`
      if (isSubtypeOf(T0, _nullNone)) {
        return true;
      }
      // or `T0` is `X0` and `X0` has bound `S0` and `S0 <: T1`
      // or `T0` is `X0 & S0` and `S0 <: T1`
      if (T0 is TypeParameterTypeImpl) {
        var S0 = T0.promotedBound;
        if (S0 != null && isSubtypeOf(S0, T1)) {
          return true;
        }
        var B0 = T0.element.bound;
        if (B0 != null && isSubtypeOf(B0, T1)) {
          return true;
        }
      }
      // iff
      return false;
    }

    // Super-Interface: `T0` is an interface type with super-interfaces
    // `S0,...Sn`:
    //   * and `Si <: T1` for some `i`.
    if (T0 is InterfaceTypeImpl && T1 is InterfaceTypeImpl) {
      return _isInterfaceSubtypeOf(T0, T1);
    }

    // Left Promoted Variable: `T0` is a promoted type variable `X0 & S0`
    //   * and `S0 <: T1`
    // Left Type Variable Bound: `T0` is a type variable `X0` with bound `B0`
    //   * and `B0 <: T1`
    if (T0 is TypeParameterTypeImpl) {
      var S0 = T0.promotedBound;
      if (S0 != null && isSubtypeOf(S0, T1)) {
        return true;
      }

      var B0 = T0.element.bound;
      if (B0 != null && isSubtypeOf(B0, T1)) {
        return true;
      }
    }

    if (T0 is FunctionTypeImpl) {
      // Function Type/Function: `T0` is a function type and `T1` is `Function`.
      if (T1.isDartCoreFunction) {
        return true;
      }
      if (T1 is FunctionTypeImpl) {
        return _isFunctionSubtypeOf(T0, T1);
      }
    }

    return false;
  }

  bool _interfaceArguments(
    ClassElement element,
    InterfaceType subType,
    InterfaceType superType,
  ) {
    List<TypeParameterElement> parameters = element.typeParameters;
    List<DartType> subArguments = subType.typeArguments;
    List<DartType> superArguments = superType.typeArguments;

    assert(subArguments.length == superArguments.length);
    assert(parameters.length == subArguments.length);

    for (int i = 0; i < subArguments.length; i++) {
      var parameter = parameters[i] as TypeParameterElementImpl;
      var subArgument = subArguments[i];
      var superArgument = superArguments[i];

      Variance variance = parameter.variance;
      if (variance.isCovariant) {
        if (!isSubtypeOf(subArgument, superArgument)) {
          return false;
        }
      } else if (variance.isContravariant) {
        if (!isSubtypeOf(superArgument, subArgument)) {
          return false;
        }
      } else if (variance.isInvariant) {
        if (!isSubtypeOf(subArgument, superArgument) ||
            !isSubtypeOf(superArgument, subArgument)) {
          return false;
        }
      } else {
        throw StateError(
          'Type parameter $parameter has unknown '
          'variance $variance for subtype checking.',
        );
      }
    }
    return true;
  }

  /// Check that [f] is a subtype of [g].
  bool _isFunctionSubtypeOf(FunctionType f, FunctionType g) {
    var fTypeFormals = f.typeFormals;
    var gTypeFormals = g.typeFormals;

    // The number of type parameters must be the same.
    if (fTypeFormals.length != gTypeFormals.length) {
      return false;
    }

    // The bounds of type parameters must be equal.
    var freshTypeFormalTypes =
        FunctionTypeImpl.relateTypeFormals(f, g, (t, s, _, __) {
      return isSubtypeOf(t, s) && isSubtypeOf(s, t);
    });
    if (freshTypeFormalTypes == null) {
      return false;
    }

    f = f.instantiate(freshTypeFormalTypes);
    g = g.instantiate(freshTypeFormalTypes);

    if (!isSubtypeOf(f.returnType, g.returnType)) {
      return false;
    }

    var fParameters = f.parameters;
    var gParameters = g.parameters;

    var fIndex = 0;
    var gIndex = 0;
    while (fIndex < fParameters.length && gIndex < gParameters.length) {
      var fParameter = fParameters[fIndex];
      var gParameter = gParameters[gIndex];
      if (fParameter.isRequiredPositional) {
        if (gParameter.isRequiredPositional) {
          if (isSubtypeOf(gParameter.type, fParameter.type)) {
            fIndex++;
            gIndex++;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else if (fParameter.isOptionalPositional) {
        if (gParameter.isPositional) {
          if (isSubtypeOf(gParameter.type, fParameter.type)) {
            fIndex++;
            gIndex++;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else if (fParameter.isNamed) {
        if (gParameter.isNamed) {
          var compareNames = fParameter.name.compareTo(gParameter.name);
          if (compareNames == 0) {
            var gIsRequiredOrLegacy = gParameter.isRequiredNamed ||
                g.nullabilitySuffix == NullabilitySuffix.star;
            if (fParameter.isRequiredNamed && !gIsRequiredOrLegacy) {
              return false;
            } else if (isSubtypeOf(gParameter.type, fParameter.type)) {
              fIndex++;
              gIndex++;
            } else {
              return false;
            }
          } else if (compareNames < 0) {
            if (fParameter.isRequiredNamed) {
              return false;
            } else {
              fIndex++;
            }
          } else {
            assert(compareNames > 0);
            // The subtype must accept all parameters of the supertype.
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
        return false;
      }
    }

    // The subtype must accept all parameters of the supertype.
    assert(fIndex == fParameters.length);
    if (gIndex < gParameters.length) {
      return false;
    }

    return true;
  }

  bool _isInterfaceSubtypeOf(InterfaceType subType, InterfaceType superType) {
    // Note: we should never reach `_isInterfaceSubtypeOf` with `i2 == Object`,
    // because top types are eliminated before `isSubtypeOf` calls this.
    // TODO(scheglov) Replace with assert().
    if (identical(subType, superType) || superType.isDartCoreObject) {
      return true;
    }

    // Object cannot subtype anything but itself (handled above).
    if (subType.isDartCoreObject) {
      return false;
    }

    var subElement = subType.element;
    var superElement = superType.element;
    if (subElement == superElement) {
      return _interfaceArguments(superElement, subType, superType);
    }

    // Classes types cannot subtype `Function` or vice versa.
    if (subType.isDartCoreFunction || superType.isDartCoreFunction) {
      return false;
    }

    for (var interface in subElement.allSupertypes) {
      if (interface.element == superElement) {
        var substitution = Substitution.fromInterfaceType(subType);
        var substitutedInterface =
            substitution.substituteType(interface) as InterfaceType;
        return _interfaceArguments(
          superElement,
          substitutedInterface,
          superType,
        );
      }
    }

    return false;
  }

  static FunctionTypeImpl _functionTypeWithNamedRequired(FunctionType type) {
    return FunctionTypeImpl(
      typeFormals: type.typeFormals,
      parameters: type.parameters.map((e) {
        if (e.isNamed) {
          return e.copyWith(
            kind: ParameterKind.NAMED_REQUIRED,
          );
        } else {
          return e;
        }
      }).toList(growable: false),
      returnType: type.returnType,
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  static bool _isFunctionTypeWithNamedRequired(DartType type) {
    if (type is FunctionType) {
      return type.parameters.any((e) => e.isRequiredNamed);
    }
    return false;
  }
}
