// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart' show AstNode;
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/greatest_lower_bound.dart';
import 'package:analyzer/src/dart/element/least_greatest_closure.dart';
import 'package:analyzer/src/dart/element/least_upper_bound.dart';
import 'package:analyzer/src/dart/element/normalize.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/replace_top_bottom_visitor.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/runtime_type_equality.dart';
import 'package:analyzer/src/dart/element/subtype.dart';
import 'package:analyzer/src/dart/element/top_merge.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_demotion.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_schema_elimination.dart';

/// The [TypeSystem] implementation.
class TypeSystemImpl implements TypeSystem {
  /// If `true`, then NNBD type rules should be used.
  /// If `false`, then legacy type rules should be used.
  final bool isNonNullableByDefault;

  /// The provider of types for the system.
  final TypeProviderImpl typeProvider;

  /// False if implicit casts should always be disallowed.
  ///
  /// This affects the behavior of [isAssignableTo].
  bool implicitCasts;

  /// True if "strict casts" should be enforced.
  ///
  /// This affects the behavior of [isAssignableTo].
  bool strictCasts;

  /// A flag indicating whether inference failures are allowed, off by default.
  ///
  /// This option is experimental and subject to change.
  bool strictInference;

  /// The cached instance of `Object?`.
  InterfaceTypeImpl? _objectQuestion;

  /// The cached instance of `Object*`.
  InterfaceTypeImpl? _objectStar;

  /// The cached instance of `Object!`.
  InterfaceTypeImpl? _objectNone;

  /// The cached instance of `Null!`.
  InterfaceTypeImpl? _nullNone;

  late final GreatestLowerBoundHelper _greatestLowerBoundHelper;
  late final LeastUpperBoundHelper _leastUpperBoundHelper;

  /// The implementation of the subtyping relation.
  late final SubtypeHelper _subtypeHelper;

  TypeSystemImpl({
    required this.implicitCasts,
    required this.isNonNullableByDefault,
    required this.strictCasts,
    required this.strictInference,
    required TypeProvider typeProvider,
  }) : typeProvider = typeProvider as TypeProviderImpl {
    _greatestLowerBoundHelper = GreatestLowerBoundHelper(this);
    _leastUpperBoundHelper = LeastUpperBoundHelper(this);
    _subtypeHelper = SubtypeHelper(this);
  }

  InterfaceTypeImpl get nullNone =>
      _nullNone ??= (typeProvider.nullType as InterfaceTypeImpl)
          .withNullability(NullabilitySuffix.none);

  InterfaceTypeImpl get objectNone =>
      _objectNone ??= (typeProvider.objectType as InterfaceTypeImpl)
          .withNullability(NullabilitySuffix.none);

  InterfaceTypeImpl get objectQuestion =>
      _objectQuestion ??= (typeProvider.objectType as InterfaceTypeImpl)
          .withNullability(NullabilitySuffix.question);

  InterfaceTypeImpl get objectStar =>
      _objectStar ??= (typeProvider.objectType as InterfaceTypeImpl)
          .withNullability(NullabilitySuffix.star);

  /// Returns true iff the type [t] accepts function types, and requires an
  /// implicit coercion if interface types with a `call` method are passed in.
  ///
  /// This is true for:
  /// - all function types
  /// - the special type `Function` that is a supertype of all function types
  /// - `FutureOr<T>` where T is one of the two cases above.
  ///
  /// Note that this returns false if [t] is a top type such as Object.
  bool acceptsFunctionType(DartType? t) {
    if (t == null) return false;
    if (t.isDartAsyncFutureOr) {
      return acceptsFunctionType((t as InterfaceType).typeArguments[0]);
    }
    return t is FunctionType || t.isDartCoreFunction;
  }

  bool anyParameterType(FunctionType ft, bool Function(DartType t) predicate) {
    return ft.parameters.any((p) => predicate(p.type));
  }

  /// Returns [type] in which all promoted type variables have been replaced
  /// with their unpromoted equivalents, and, if non-nullable by default,
  /// replaces all legacy types with their non-nullable equivalents.
  DartType demoteType(DartType type) {
    if (isNonNullableByDefault) {
      var visitor = const DemotionNonNullificationVisitor(
        demoteTypeVariables: true,
        nonNullifyTypes: true,
      );
      return type.accept(visitor) ?? type;
    } else {
      var visitor = const DemotionNonNullificationVisitor(
        demoteTypeVariables: true,
        nonNullifyTypes: false,
      );
      return type.accept(visitor) ?? type;
    }
  }

  /// Eliminates type variables from the context [type], replacing them with
  /// `Null` or `Object` as appropriate.
  ///
  /// For example in `List<T> list = const []`, the context type for inferring
  /// the list should be changed from `List<T>` to `List<Null>` so the constant
  /// doesn't depend on the type variables `T` (because it can't be
  /// canonicalized at compile time, as `T` is unknown).
  ///
  /// Conceptually this is similar to the "least closure", except instead of
  /// eliminating `_` ([UnknownInferredType]) it eliminates all type variables
  /// ([TypeParameterType]).
  ///
  /// The equivalent CFE code can be found in the `TypeVariableEliminator`
  /// class.
  DartType eliminateTypeVariables(DartType type) {
    if (isNonNullableByDefault) {
      return _TypeVariableEliminator(
        objectQuestion,
        NeverTypeImpl.instance,
      ).substituteType(type);
    } else {
      return _TypeVariableEliminator(
        objectNone,
        typeProvider.nullType,
      ).substituteType(type);
    }
  }

  /// Defines the "remainder" of `T` when `S` has been removed from
  /// consideration by an instance check.  This operation is used for type
  /// promotion during flow analysis.
  DartType factor(DartType T, DartType S) {
    // * If T <: S then Never
    if (isSubtypeOf(T, S)) {
      return NeverTypeImpl.instance;
    }

    var T_nullability = T.nullabilitySuffix;

    // * Else if T is R? and Null <: S then factor(R, S)
    // * Else if T is R? then factor(R, S)?
    if (T_nullability == NullabilitySuffix.question) {
      var R = (T as TypeImpl).withNullability(NullabilitySuffix.none);
      var factor_RS = factor(R, S) as TypeImpl;
      if (isSubtypeOf(nullNone, S)) {
        return factor_RS;
      } else {
        return factor_RS.withNullability(NullabilitySuffix.question);
      }
    }

    // * Else if T is R* and Null <: S then factor(R, S)
    // * Else if T is R* then factor(R, S)*
    if (T_nullability == NullabilitySuffix.star) {
      var R = (T as TypeImpl).withNullability(NullabilitySuffix.none);
      var factor_RS = factor(R, S) as TypeImpl;
      if (isSubtypeOf(nullNone, S)) {
        return factor_RS;
      } else {
        return factor_RS.withNullability(NullabilitySuffix.star);
      }
    }

    // * Else if T is FutureOr<R> and Future<R> <: S then factor(R, S)
    // * Else if T is FutureOr<R> and R <: S then factor(Future<R>, S)
    if (T is InterfaceType && T.isDartAsyncFutureOr) {
      var R = T.typeArguments[0];
      var future_R = typeProvider.futureType(R);
      if (isSubtypeOf(future_R, S)) {
        return factor(R, S);
      }
      if (isSubtypeOf(R, S)) {
        return factor(future_R, S);
      }
    }

    return T;
  }

  @override
  DartType flatten(DartType type) {
    if (identical(type, UnknownInferredType.instance)) {
      return type;
    }

    // if T is S? then flatten(T) = flatten(S)?
    // if T is S* then flatten(T) = flatten(S)*
    NullabilitySuffix nullabilitySuffix = type.nullabilitySuffix;
    if (nullabilitySuffix != NullabilitySuffix.none) {
      var S = (type as TypeImpl).withNullability(NullabilitySuffix.none);
      return (flatten(S) as TypeImpl).withNullability(nullabilitySuffix);
    }

    // otherwise if T is FutureOr<S> then flatten(T) = S
    // otherwise if T is Future<S> then flatten(T) = S (shortcut)
    if (type is InterfaceType) {
      if (type.isDartAsyncFutureOr || type.isDartAsyncFuture) {
        return type.typeArguments[0];
      }
    }

    // otherwise if T <: Future then let S be a type such that T <: Future<S>
    //   and for all R, if T <: Future<R> then S <: R; then flatten(T) = S
    var futureType = type.asInstanceOf(typeProvider.futureElement);
    if (futureType != null) {
      return futureType.typeArguments[0];
    }

    // otherwise flatten(T) = T
    return type;
  }

  DartType futureOrBase(DartType type) {
    // If `T` is `FutureOr<S>` for some `S`,
    // then `futureOrBase(T)` = `futureOrBase(S)`
    if (type is InterfaceType && type.isDartAsyncFutureOr) {
      return futureOrBase(
        type.typeArguments[0],
      );
    }

    // Otherwise `futureOrBase(T)` = `T`.
    return type;
  }

  /// Compute "future value type" of [T].
  ///
  /// https://github.com/dart-lang/language/
  /// See `nnbd/feature-specification.md`
  /// See `#the-future-value-type-of-an-asynchronous-non-generator-function`
  DartType futureValueType(DartType T) {
    // futureValueType(`S?`) = futureValueType(`S`), for all `S`.
    // futureValueType(`S*`) = futureValueType(`S`), for all `S`.
    if (T.nullabilitySuffix != NullabilitySuffix.none) {
      var S = (T as TypeImpl).withNullability(NullabilitySuffix.none);
      return futureValueType(S);
    }

    // futureValueType(Future<`S`>) = `S`, for all `S`.
    // futureValueType(FutureOr<`S`>) = `S`, for all `S`.
    if (T is InterfaceType) {
      if (T.isDartAsyncFuture || T.isDartAsyncFutureOr) {
        return T.typeArguments[0];
      }
    }

    // futureValueType(`dynamic`) = `dynamic`.
    if (identical(T, DynamicTypeImpl.instance)) {
      return T;
    }

    // futureValueType(`void`) = `void`.
    if (identical(T, VoidTypeImpl.instance)) {
      return T;
    }

    // Otherwise, for all `S`, futureValueType(`S`) = `Object?`.
    return objectQuestion;
  }

  List<InterfaceType> gatherMixinSupertypeConstraintsForInference(
      ClassElement mixinElement) {
    List<InterfaceType> candidates;
    if (mixinElement.isMixin) {
      candidates = mixinElement.superclassConstraints;
    } else {
      candidates = [mixinElement.supertype!];
      candidates.addAll(mixinElement.mixins);
      if (mixinElement.isMixinApplication) {
        candidates.removeLast();
      }
    }
    return candidates
        .where((type) => type.element.typeParameters.isNotEmpty)
        .toList();
  }

  /// Given a type [t], if [t] is an interface type with a `call` method
  /// defined, return the function type for the `call` method, otherwise return
  /// `null`.
  ///
  /// This does not find extension methods (which are not defined on an
  /// interface type); it is meant to find implicit call references.
  FunctionType? getCallMethodType(DartType t) {
    if (t is InterfaceType) {
      return t
          .lookUpMethod2(FunctionElement.CALL_METHOD_NAME, t.element.library)
          ?.type;
    }
    return null;
  }

  /// Computes the greatest lower bound of [T1] and [T2].
  DartType getGreatestLowerBound(DartType T1, DartType T2) {
    return _greatestLowerBoundHelper.getGreatestLowerBound(T1, T2);
  }

  /// Compute the least upper bound of two types.
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/upper-lower-bounds.md`
  DartType getLeastUpperBound(DartType T1, DartType T2) {
    return _leastUpperBoundHelper.getLeastUpperBound(T1, T2);
  }

  /// Returns the greatest closure of [type] with respect to [typeParameters].
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/inference.md`
  DartType greatestClosure(
    DartType type,
    List<TypeParameterElement> typeParameters,
  ) {
    var typeParameterSet = Set<TypeParameterElement>.identity();
    typeParameterSet.addAll(typeParameters);

    if (isNonNullableByDefault) {
      return LeastGreatestClosureHelper(
        typeSystem: this,
        topType: objectQuestion,
        topFunctionType: typeProvider.functionType,
        bottomType: NeverTypeImpl.instance,
        eliminationTargets: typeParameterSet,
      ).eliminateToGreatest(type);
    } else {
      return LeastGreatestClosureHelper(
        typeSystem: this,
        topType: DynamicTypeImpl.instance,
        topFunctionType: typeProvider.functionType,
        bottomType: typeProvider.nullType,
        eliminationTargets: typeParameterSet,
      ).eliminateToGreatest(type);
    }
  }

  /// Returns the greatest closure of the given type [schema] with respect to
  /// `_`.
  ///
  /// The greatest closure of a type schema `P` with respect to `_` is defined
  /// as `P` with every covariant occurrence of `_` replaced with `Null`, and
  /// every contravariant occurrence of `_` replaced with `Object`.
  ///
  /// If the schema contains no instances of `_`, the original schema object is
  /// returned to avoid unnecessary allocation.
  ///
  /// Note that the closure of a type schema is a proper type.
  ///
  /// Note that the greatest closure of a type schema is always a supertype of
  /// any type which matches the schema.
  DartType greatestClosureOfSchema(DartType schema) {
    if (isNonNullableByDefault) {
      return TypeSchemaEliminationVisitor.run(
        topType: objectQuestion,
        bottomType: NeverTypeImpl.instance,
        isLeastClosure: false,
        schema: schema,
      );
    } else {
      return TypeSchemaEliminationVisitor.run(
        topType: DynamicTypeImpl.instance,
        bottomType: typeProvider.nullType,
        isLeastClosure: false,
        schema: schema,
      );
    }
  }

  /// Given a generic function type `F<T0, T1, ... Tn>` and a context type C,
  /// infer an instantiation of F, such that `F<S0, S1, ..., Sn>` <: C.
  ///
  /// This is similar to [inferGenericFunctionOrType], but the return type is
  /// also considered as part of the solution.
  ///
  /// If this function is called with a [contextType] that is also
  /// uninstantiated, or a [fnType] that is already instantiated, it will have
  /// no effect and return `null`.
  List<DartType>? inferFunctionTypeInstantiation(
    FunctionType contextType,
    FunctionType fnType, {
    ErrorReporter? errorReporter,
    AstNode? errorNode,
    required bool genericMetadataIsEnabled,
  }) {
    if (contextType.typeFormals.isNotEmpty || fnType.typeFormals.isEmpty) {
      return const <DartType>[];
    }

    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferrer = GenericInferrer(this, fnType.typeFormals);
    inferrer.constrainGenericFunctionInContext(fnType, contextType);

    // Infer and instantiate the resulting type.
    return inferrer.infer(
      fnType.typeFormals,
      errorReporter: errorReporter,
      errorNode: errorNode,
      genericMetadataIsEnabled: genericMetadataIsEnabled,
    );
  }

  /// Infers type arguments for a generic type, function, method, or
  /// list/map literal, using the downward context type as well as the
  /// argument types if available.
  ///
  /// For example, given a function type with generic type parameters, this
  /// infers the type parameters from the actual argument types, and returns the
  /// instantiated function type.
  ///
  /// Concretely, given a function type with parameter types P0, P1, ... Pn,
  /// result type R, and generic type parameters T0, T1, ... Tm, use the
  /// argument types A0, A1, ... An to solve for the type parameters.
  ///
  /// For each parameter Pi, we want to ensure that Ai <: Pi. We can do this by
  /// running the subtype algorithm, and when we reach a type parameter Tj,
  /// recording the lower or upper bound it must satisfy. At the end, all
  /// constraints can be combined to determine the type.
  ///
  /// All constraints on each type parameter Tj are tracked, as well as where
  /// they originated, so we can issue an error message tracing back to the
  /// argument values, type parameter "extends" clause, or the return type
  /// context.
  List<DartType>? inferGenericFunctionOrType({
    ClassElement? genericClass,
    required List<TypeParameterElement> typeParameters,
    required List<ParameterElement> parameters,
    required DartType declaredReturnType,
    required List<DartType> argumentTypes,
    required DartType? contextReturnType,
    ErrorReporter? errorReporter,
    AstNode? errorNode,
    bool downwards = false,
    bool isConst = false,
    required bool genericMetadataIsEnabled,
  }) {
    if (typeParameters.isEmpty) {
      return null;
    }

    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferrer = GenericInferrer(this, typeParameters);

    if (contextReturnType != null) {
      if (isConst) {
        contextReturnType = eliminateTypeVariables(contextReturnType);
      }
      inferrer.constrainReturnType(declaredReturnType, contextReturnType);
    }

    for (int i = 0; i < argumentTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      inferrer.constrainArgument(
        argumentTypes[i],
        parameters[i].type,
        parameters[i].name,
        genericClass: genericClass,
      );
    }

    return inferrer.infer(
      typeParameters,
      errorReporter: errorReporter,
      errorNode: errorNode,
      downwardsInferPhase: downwards,
      genericMetadataIsEnabled: genericMetadataIsEnabled,
    );
  }

  /// Given a [DartType] [type], if [type] is an uninstantiated
  /// parameterized type then instantiate the parameters to their
  /// bounds. See the issue for the algorithm description.
  ///
  /// https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397
  // TODO(scheglov) Move this method to elements for classes, typedefs,
  //  and generic functions; compute lazily and cache.
  DartType instantiateToBounds(DartType type,
      {List<bool>? hasError, Map<TypeParameterElement, DartType>? knownTypes}) {
    List<TypeParameterElement> typeFormals = typeFormalsAsElements(type);
    List<DartType> arguments = instantiateTypeFormalsToBounds(typeFormals,
        hasError: hasError, knownTypes: knownTypes);
    return instantiateType(type, arguments);
  }

  @override
  DartType instantiateToBounds2({
    ClassElement? classElement,
    TypeAliasElement? typeAliasElement,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    if (classElement != null) {
      var typeParameters = classElement.typeParameters;
      var typeArguments = _defaultTypeArguments(typeParameters);
      var type = classElement.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: nullabilitySuffix,
      );
      type = toLegacyType(type) as InterfaceType;
      return type;
    } else if (typeAliasElement != null) {
      var typeParameters = typeAliasElement.typeParameters;
      var typeArguments = _defaultTypeArguments(typeParameters);
      var type = typeAliasElement.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: nullabilitySuffix,
      );
      type = toLegacyType(type);
      return type;
    } else {
      throw ArgumentError('Missing element');
    }
  }

  /// Given a [DartType] [type] and a list of types
  /// [typeArguments], instantiate the type formals with the
  /// provided actuals.  If [type] is not a parameterized type,
  /// no instantiation is done.
  DartType instantiateType(DartType type, List<DartType> typeArguments) {
    if (type is FunctionType) {
      return type.instantiate(typeArguments);
    } else if (type is InterfaceTypeImpl) {
      // TODO(scheglov) Use `ClassElement.instantiate()`, don't use raw types.
      return type.element.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: type.nullabilitySuffix,
      );
    } else {
      return type;
    }
  }

  /// Given uninstantiated [typeFormals], instantiate them to their bounds.
  /// See the issue for the algorithm description.
  ///
  /// https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397
  List<DartType> instantiateTypeFormalsToBounds(
      List<TypeParameterElement> typeFormals,
      {List<bool>? hasError,
      Map<TypeParameterElement, DartType>? knownTypes}) {
    int count = typeFormals.length;
    if (count == 0) {
      return const <DartType>[];
    }

    Set<TypeParameterElement> all = <TypeParameterElement>{};
    // all ground
    Map<TypeParameterElement, DartType> defaults = knownTypes ?? {};
    // not ground
    Map<TypeParameterElement, DartType> partials = {};

    for (TypeParameterElement typeParameter in typeFormals) {
      all.add(typeParameter);
      if (!defaults.containsKey(typeParameter)) {
        var bound = typeParameter.bound ?? DynamicTypeImpl.instance;
        partials[typeParameter] = bound;
      }
    }

    List<TypeParameterElement>? getFreeParameters(DartType rootType) {
      List<TypeParameterElement>? parameters;
      Set<DartType> visitedTypes = HashSet<DartType>();

      void appendParameters(DartType? type) {
        if (type == null) {
          return;
        }
        if (visitedTypes.contains(type)) {
          return;
        }
        visitedTypes.add(type);
        if (type is TypeParameterType) {
          var element = type.element;
          if (all.contains(element)) {
            parameters ??= <TypeParameterElement>[];
            parameters!.add(element);
          }
        } else {
          if (type is FunctionType) {
            appendParameters(type.returnType);
            type.parameters.map((p) => p.type).forEach(appendParameters);
            // TODO(scheglov) https://github.com/dart-lang/sdk/issues/44218
            type.alias?.typeArguments.forEach(appendParameters);
          } else if (type is InterfaceType) {
            type.typeArguments.forEach(appendParameters);
          }
        }
      }

      appendParameters(rootType);
      return parameters;
    }

    bool hasProgress = true;
    while (hasProgress) {
      hasProgress = false;
      for (TypeParameterElement parameter in partials.keys) {
        DartType value = partials[parameter]!;
        var freeParameters = getFreeParameters(value);
        if (freeParameters == null) {
          defaults[parameter] = value;
          partials.remove(parameter);
          hasProgress = true;
          break;
        } else if (freeParameters.every(defaults.containsKey)) {
          defaults[parameter] =
              Substitution.fromMap(defaults).substituteType(value);
          partials.remove(parameter);
          hasProgress = true;
          break;
        }
      }
    }

    // If we stopped making progress, and not all types are ground,
    // then the whole type is malbounded and an error should be reported
    // if errors are requested, and a partially completed type should
    // be returned.
    if (partials.isNotEmpty) {
      if (hasError != null) {
        hasError[0] = true;
      }
      var domain = defaults.keys.toList();
      var range = defaults.values.toList();
      // Build a substitution Phi mapping each uncompleted type variable to
      // dynamic, and each completed type variable to its default.
      for (TypeParameterElement parameter in partials.keys) {
        domain.add(parameter);
        range.add(DynamicTypeImpl.instance);
      }
      // Set the default for an uncompleted type variable (T extends B)
      // to be Phi(B)
      for (TypeParameterElement parameter in partials.keys) {
        defaults[parameter] = Substitution.fromPairs(domain, range)
            .substituteType(partials[parameter]!);
      }
    }

    List<DartType> orderedArguments =
        typeFormals.map((p) => defaults[p]!).toList();
    return orderedArguments;
  }

  @override
  bool isAssignableTo(DartType fromType, DartType toType) {
    // An actual subtype
    if (isSubtypeOf(fromType, toType)) {
      return true;
    }

    // A 'call' method tearoff.
    if (fromType is InterfaceType &&
        !isNullable(fromType) &&
        acceptsFunctionType(toType)) {
      var callMethodType = getCallMethodType(fromType);
      if (callMethodType != null && isAssignableTo(callMethodType, toType)) {
        return true;
      }
    }

    // First make sure that the static analysis options, `implicit-casts: false`
    // and `strict-casts: true` disable all downcasts, including casts from
    // `dynamic`.
    if (!implicitCasts || strictCasts) {
      return false;
    }

    // Now handle NNBD default behavior, where we disable non-dynamic downcasts.
    if (isNonNullableByDefault) {
      return fromType.isDynamic;
    }

    // Don't allow implicit downcasts between function types
    // and call method objects, as these will almost always fail.
    if (fromType is FunctionType && getCallMethodType(toType) != null) {
      return false;
    }

    // Don't allow a non-generic function where a generic one is expected. The
    // former wouldn't know how to handle type arguments being passed to it.
    // TODO(rnystrom): This same check also exists in FunctionTypeImpl.relate()
    // but we don't always reliably go through that code path. This should be
    // cleaned up to avoid the redundancy.
    if (fromType is FunctionType &&
        toType is FunctionType &&
        fromType.typeFormals.isEmpty &&
        toType.typeFormals.isNotEmpty) {
      return false;
    }

    // If the subtype relation goes the other way, allow the implicit downcast.
    if (isSubtypeOf(toType, fromType)) {
      // TODO(leafp,jmesserly): we emit warnings/hints for these in
      // src/task/strong/checker.dart, which is a bit inconsistent. That
      // code should be handled into places that use isAssignableTo, such as
      // ErrorVerifier.
      return true;
    }

    return false;
  }

  /// Return `true`  for things in the equivalence class of `Never`.
  bool isBottom(DartType type) {
    // BOTTOM(Never) is true
    if (type is NeverType) {
      var result = type.nullabilitySuffix != NullabilitySuffix.question;
      assert(type.isBottom == result);
      return result;
    }

    // BOTTOM(X&T) is true iff BOTTOM(T)
    // BOTTOM(X extends T) is true iff BOTTOM(T)
    if (type is TypeParameterTypeImpl) {
      var T = type.promotedBound;
      if (T != null) {
        var result = isBottom(T);
        assert(type.isBottom == result);
        return result;
      }

      T = type.element.bound;
      if (T != null) {
        var result = isBottom(T);
        assert(type.isBottom == result);
        return result;
      }
    }

    // BOTTOM(T) is false otherwise
    assert(!type.isBottom);
    return false;
  }

  /// A dynamic bounded type is either `dynamic` itself, or a type variable
  /// whose bound is dynamic bounded, or an intersection (promoted type
  /// parameter type) whose second operand is dynamic bounded.
  bool isDynamicBounded(DartType type) {
    if (identical(type, DynamicTypeImpl.instance)) {
      return true;
    }

    if (type is TypeParameterTypeImpl) {
      var bound = type.element.bound;
      if (bound != null && isDynamicBounded(bound)) {
        return true;
      }

      var promotedBound = type.promotedBound;
      if (promotedBound != null && isDynamicBounded(promotedBound)) {
        return true;
      }
    }

    return false;
  }

  /// A function bounded type is either `Function` itself, or a type variable
  /// whose bound is function bounded, or an intersection (promoted type
  /// parameter type) whose second operand is function bounded.
  bool isFunctionBounded(DartType type) {
    if (type is FunctionType) {
      return type.nullabilitySuffix != NullabilitySuffix.question;
    }

    if (type is InterfaceType && type.isDartCoreFunction) {
      return type.nullabilitySuffix != NullabilitySuffix.question;
    }

    if (type is TypeParameterTypeImpl) {
      var bound = type.element.bound;
      if (bound != null && isFunctionBounded(bound)) {
        return true;
      }

      var promotedBound = type.promotedBound;
      if (promotedBound != null && isFunctionBounded(promotedBound)) {
        return true;
      }
    }

    return false;
  }

  /// Defines an (almost) total order on bottom and `Null` types. This does not
  /// currently consistently order two different type variables with the same
  /// bound.
  bool isMoreBottom(DartType T, DartType S) {
    var T_impl = T as TypeImpl;
    var S_impl = S as TypeImpl;

    var T_nullability = T_impl.nullabilitySuffix;
    var S_nullability = S_impl.nullabilitySuffix;

    // MOREBOTTOM(Never, T) = true
    if (identical(T, NeverTypeImpl.instance)) {
      return true;
    }

    // MOREBOTTOM(T, Never) = false
    if (identical(S, NeverTypeImpl.instance)) {
      return false;
    }

    // MOREBOTTOM(Null, T) = true
    if (T_nullability == NullabilitySuffix.none && T.isDartCoreNull) {
      return true;
    }

    // MOREBOTTOM(T, Null) = false
    if (S_nullability == NullabilitySuffix.none && S.isDartCoreNull) {
      return false;
    }

    // MOREBOTTOM(T?, S?) = MOREBOTTOM(T, S)
    if (T_nullability == NullabilitySuffix.question &&
        S_nullability == NullabilitySuffix.question) {
      var T2 = T_impl.withNullability(NullabilitySuffix.none);
      var S2 = S_impl.withNullability(NullabilitySuffix.none);
      return isMoreBottom(T2, S2);
    }

    // MOREBOTTOM(T, S?) = true
    if (S_nullability == NullabilitySuffix.question) {
      return true;
    }

    // MOREBOTTOM(T?, S) = false
    if (T_nullability == NullabilitySuffix.question) {
      return false;
    }

    // MOREBOTTOM(T*, S*) = MOREBOTTOM(T, S)
    if (T_nullability == NullabilitySuffix.star &&
        S_nullability == NullabilitySuffix.star) {
      var T2 = T_impl.withNullability(NullabilitySuffix.none);
      var S2 = S_impl.withNullability(NullabilitySuffix.none);
      return isMoreBottom(T2, S2);
    }

    // MOREBOTTOM(T, S*) = true
    if (S_nullability == NullabilitySuffix.star) {
      return true;
    }

    // MOREBOTTOM(T*, S) = false
    if (T_nullability == NullabilitySuffix.star) {
      return false;
    }

    // Type parameters.
    if (T is TypeParameterTypeImpl && S is TypeParameterTypeImpl) {
      // We have eliminated the possibility that T_nullability or S_nullability
      // is anything except none by this point.
      assert(T_nullability == NullabilitySuffix.none);
      assert(S_nullability == NullabilitySuffix.none);
      var T_element = T.element;
      var S_element = S.element;

      // MOREBOTTOM(X&T, Y&S) = MOREBOTTOM(T, S)
      var T_promotedBound = T.promotedBound;
      var S_promotedBound = S.promotedBound;
      if (T_promotedBound != null && S_promotedBound != null) {
        return isMoreBottom(T_promotedBound, S_promotedBound);
      }

      // MOREBOTTOM(X&T, S) = true
      if (T_promotedBound != null) {
        return true;
      }

      // MOREBOTTOM(T, Y&S) = false
      if (S_promotedBound != null) {
        return false;
      }

      // MOREBOTTOM(X extends T, Y extends S) = MOREBOTTOM(T, S)
      // The invariant of the larger algorithm that this is only called with
      // types that satisfy `BOTTOM(T)` or `NULL(T)`, and all such types, if
      // they are type variables, have bounds which themselves are
      // `BOTTOM` or `NULL` types.
      var T_bound = T_element.bound!;
      var S_bound = S_element.bound!;
      return isMoreBottom(T_bound, S_bound);
    }

    return false;
  }

  /// Return `true` if the [leftType] is more specific than the [rightType]
  /// (that is, if leftType << rightType), as defined in the Dart language spec.
  ///
  /// In strong mode, this is equivalent to [isSubtypeOf].
  @Deprecated('Use isSubtypeOf() instead.')
  bool isMoreSpecificThan(DartType leftType, DartType rightType) {
    return isSubtypeOf(leftType, rightType);
  }

  /// Defines a total order on top and Object types.
  bool isMoreTop(DartType T, DartType S) {
    var T_impl = T as TypeImpl;
    var S_impl = S as TypeImpl;

    var T_nullability = T_impl.nullabilitySuffix;
    var S_nullability = S_impl.nullabilitySuffix;

    // MORETOP(void, S) = true
    if (identical(T, VoidTypeImpl.instance)) {
      return true;
    }

    // MORETOP(T, void) = false
    if (identical(S, VoidTypeImpl.instance)) {
      return false;
    }

    // MORETOP(dynamic, S) = true
    if (identical(T, DynamicTypeImpl.instance)) {
      return true;
    }

    // MORETOP(T, dynamic) = false
    if (identical(S, DynamicTypeImpl.instance)) {
      return false;
    }

    // MORETOP(Object, S) = true
    if (T_nullability == NullabilitySuffix.none && T.isDartCoreObject) {
      return true;
    }

    // MORETOP(T, Object) = false
    if (S_nullability == NullabilitySuffix.none && S.isDartCoreObject) {
      return false;
    }

    // MORETOP(T*, S*) = MORETOP(T, S)
    if (T_nullability == NullabilitySuffix.star &&
        S_nullability == NullabilitySuffix.star) {
      var T2 = T_impl.withNullability(NullabilitySuffix.none);
      var S2 = S_impl.withNullability(NullabilitySuffix.none);
      return isMoreTop(T2, S2);
    }

    // MORETOP(T, S*) = true
    if (S_nullability == NullabilitySuffix.star) {
      return true;
    }

    // MORETOP(T*, S) = false
    if (T_nullability == NullabilitySuffix.star) {
      return false;
    }

    // MORETOP(T?, S?) = MORETOP(T, S)
    if (T_nullability == NullabilitySuffix.question &&
        S_nullability == NullabilitySuffix.question) {
      var T2 = T_impl.withNullability(NullabilitySuffix.none);
      var S2 = S_impl.withNullability(NullabilitySuffix.none);
      return isMoreTop(T2, S2);
    }

    // MORETOP(T, S?) = true
    if (S_nullability == NullabilitySuffix.question) {
      return true;
    }

    // MORETOP(T?, S) = false
    if (T_nullability == NullabilitySuffix.question) {
      return false;
    }

    // MORETOP(FutureOr<T>, FutureOr<S>) = MORETOP(T, S)
    if (T is InterfaceTypeImpl &&
        T.isDartAsyncFutureOr &&
        S is InterfaceTypeImpl &&
        S.isDartAsyncFutureOr) {
      assert(T_nullability == NullabilitySuffix.none);
      assert(S_nullability == NullabilitySuffix.none);
      var T2 = T.typeArguments[0];
      var S2 = S.typeArguments[0];
      return isMoreTop(T2, S2);
    }

    return false;
  }

  @override
  bool isNonNullable(DartType type) {
    if (type.isDynamic || type.isVoid || type.isDartCoreNull) {
      return false;
    } else if (type is TypeParameterTypeImpl && type.promotedBound != null) {
      return isNonNullable(type.promotedBound!);
    } else if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return false;
    } else if (type is InterfaceType && type.isDartAsyncFutureOr) {
      return isNonNullable(type.typeArguments[0]);
    } else if (type is TypeParameterType) {
      var bound = type.element.bound;
      return bound != null && isNonNullable(bound);
    }
    return true;
  }

  /// Return `true` for things in the equivalence class of `Null`.
  bool isNull(DartType type) {
    var typeImpl = type as TypeImpl;
    var nullabilitySuffix = typeImpl.nullabilitySuffix;

    // NULL(Null) is true
    // Also includes `Null?` and `Null*` from the rules below.
    if (type.isDartCoreNull) {
      return true;
    }

    // NULL(T?) is true iff NULL(T) or BOTTOM(T)
    // NULL(T*) is true iff NULL(T) or BOTTOM(T)
    // Cases for `Null?` and `Null*` are already checked above.
    if (nullabilitySuffix == NullabilitySuffix.question ||
        nullabilitySuffix == NullabilitySuffix.star) {
      var T = typeImpl.withNullability(NullabilitySuffix.none);
      return isBottom(T);
    }

    // NULL(T) is false otherwise
    return false;
  }

  @override
  bool isNullable(DartType type) {
    if (type.isDynamic || type.isVoid || type.isDartCoreNull) {
      return true;
    } else if (type is TypeParameterTypeImpl && type.promotedBound != null) {
      return isNullable(type.promotedBound!);
    } else if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return true;
    } else if (type.isDartAsyncFutureOr) {
      return isNullable((type as InterfaceType).typeArguments[0]);
    }
    return false;
  }

  /// Return `true` for any type which is in the equivalence class of `Object`.
  bool isObject(DartType type) {
    var typeImpl = type as TypeImpl;
    if (typeImpl.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    // OBJECT(Object) is true
    if (type.isDartCoreObject) {
      return true;
    }

    // OBJECT(FutureOr<T>) is OBJECT(T)
    if (type is InterfaceTypeImpl && type.isDartAsyncFutureOr) {
      var T = type.typeArguments[0];
      return isObject(T);
    }

    // OBJECT(T) is false otherwise
    return false;
  }

  @override
  bool isPotentiallyNonNullable(DartType type) => !isNullable(type);

  @override
  bool isPotentiallyNullable(DartType type) => !isNonNullable(type);

  @override
  bool isStrictlyNonNullable(DartType type) {
    if (type.isDynamic || type.isVoid || type.isDartCoreNull) {
      return false;
    } else if (type.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    } else if (type is InterfaceType && type.isDartAsyncFutureOr) {
      return isStrictlyNonNullable(type.typeArguments[0]);
    } else if (type is TypeParameterType) {
      return isStrictlyNonNullable(type.bound);
    }
    return true;
  }

  /// Check if [leftType] is a subtype of [rightType].
  ///
  /// Implements:
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/subtyping.md`
  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return _subtypeHelper.isSubtypeOf(leftType, rightType);
  }

  /// Return `true` for any type which is in the equivalence class of top types.
  bool isTop(DartType type) {
    // TOP(?) is true
    if (identical(type, UnknownInferredType.instance)) {
      return true;
    }

    // TOP(dynamic) is true
    if (identical(type, DynamicTypeImpl.instance)) {
      return true;
    }

    // TOP(void) is true
    if (identical(type, VoidTypeImpl.instance)) {
      return true;
    }

    var typeImpl = type as TypeImpl;
    var nullabilitySuffix = typeImpl.nullabilitySuffix;

    // TOP(T?) is true iff TOP(T) or OBJECT(T)
    // TOP(T*) is true iff TOP(T) or OBJECT(T)
    if (nullabilitySuffix == NullabilitySuffix.question ||
        nullabilitySuffix == NullabilitySuffix.star) {
      var T = typeImpl.withNullability(NullabilitySuffix.none);
      return isTop(T) || isObject(T);
    }

    // TOP(FutureOr<T>) is TOP(T)
    if (type is InterfaceTypeImpl && type.isDartAsyncFutureOr) {
      assert(nullabilitySuffix == NullabilitySuffix.none);
      var T = type.typeArguments[0];
      return isTop(T);
    }

    // TOP(T) is false otherwise
    return false;
  }

  /// Returns the least closure of [type] with respect to [typeParameters].
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/inference.md`
  DartType leastClosure(
    DartType type,
    List<TypeParameterElement> typeParameters,
  ) {
    var typeParameterSet = Set<TypeParameterElement>.identity();
    typeParameterSet.addAll(typeParameters);

    if (isNonNullableByDefault) {
      return LeastGreatestClosureHelper(
        typeSystem: this,
        topType: objectQuestion,
        topFunctionType: typeProvider.functionType,
        bottomType: NeverTypeImpl.instance,
        eliminationTargets: typeParameterSet,
      ).eliminateToLeast(type);
    } else {
      return LeastGreatestClosureHelper(
        typeSystem: this,
        topType: DynamicTypeImpl.instance,
        topFunctionType: typeProvider.functionType,
        bottomType: typeProvider.nullType,
        eliminationTargets: typeParameterSet,
      ).eliminateToLeast(type);
    }
  }

  /// Returns the least closure of the given type [schema] with respect to `_`.
  ///
  /// The least closure of a type schema `P` with respect to `_` is defined as
  /// `P` with every covariant occurrence of `_` replaced with `Object`, an
  /// every contravariant occurrence of `_` replaced with `Null`.
  ///
  /// If the schema contains no instances of `_`, the original schema object is
  /// returned to avoid unnecessary allocation.
  ///
  /// Note that the closure of a type schema is a proper type.
  ///
  /// Note that the least closure of a type schema is always a subtype of any
  /// type which matches the schema.
  DartType leastClosureOfSchema(DartType schema) {
    if (isNonNullableByDefault) {
      return TypeSchemaEliminationVisitor.run(
        topType: objectQuestion,
        bottomType: NeverTypeImpl.instance,
        isLeastClosure: true,
        schema: schema,
      );
    } else {
      return TypeSchemaEliminationVisitor.run(
        topType: DynamicTypeImpl.instance,
        bottomType: typeProvider.nullType,
        isLeastClosure: true,
        schema: schema,
      );
    }
  }

  @override
  DartType leastUpperBound(DartType leftType, DartType rightType) {
    return getLeastUpperBound(leftType, rightType);
  }

  /// Returns a nullable version of [type].  The result would be equivalent to
  /// the union `type | Null` (if we supported union types).
  DartType makeNullable(DartType type) {
    // TODO(paulberry): handle type parameter types
    return (type as TypeImpl).withNullability(NullabilitySuffix.question);
  }

  /// Attempts to find the appropriate substitution for the [mixinElement]
  /// type parameters that can be applied to [srcTypes] to make it equal to
  /// [destTypes].  If no such substitution can be found, `null` is returned.
  List<DartType>? matchSupertypeConstraints(
    ClassElement mixinElement,
    List<DartType> srcTypes,
    List<DartType> destTypes, {
    required bool genericMetadataIsEnabled,
  }) {
    var typeParameters = mixinElement.typeParameters;
    var inferrer = GenericInferrer(this, typeParameters);
    for (int i = 0; i < srcTypes.length; i++) {
      inferrer.constrainReturnType(srcTypes[i], destTypes[i]);
      inferrer.constrainReturnType(destTypes[i], srcTypes[i]);
    }

    var inferredTypes = inferrer.infer(
      typeParameters,
      considerExtendsClause: false,
      genericMetadataIsEnabled: genericMetadataIsEnabled,
    )!;
    inferredTypes =
        inferredTypes.map(_removeBoundsOfGenericFunctionTypes).toList();
    var substitution = Substitution.fromPairs(typeParameters, inferredTypes);

    for (int i = 0; i < srcTypes.length; i++) {
      var srcType = substitution.substituteType(srcTypes[i]);
      var destType = destTypes[i];
      if (isNonNullableByDefault) {
        // TODO(scheglov) waiting for the spec
        // https://github.com/dart-lang/sdk/issues/42605
      } else {
        srcType = toLegacyType(srcType);
        destType = toLegacyType(destType);
      }
      if (srcType != destType) {
        // Failed to find an appropriate substitution
        return null;
      }
    }

    return inferredTypes;
  }

  /// Replace legacy types in [type] with non-nullable types.
  DartType nonNullifyLegacy(DartType type) {
    if (isNonNullableByDefault) {
      var visitor = const DemotionNonNullificationVisitor(
        demoteTypeVariables: false,
        nonNullifyTypes: true,
      );
      return type.accept(visitor) ?? type;
    }
    return type;
  }

  /// Compute the canonical representation of [T].
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/normalization.md`
  DartType normalize(DartType T) {
    return NormalizeHelper(this).normalize(T);
  }

  /// Returns a non-nullable version of [type].  This is equivalent to the
  /// operation `NonNull` defined in the spec.
  @override
  DartType promoteToNonNull(DartType type) {
    if (type.isDartCoreNull) return NeverTypeImpl.instance;

    if (type is TypeParameterTypeImpl) {
      var element = type.element;

      // NonNull(X & T) = X & NonNull(T)
      if (type.promotedBound != null) {
        var promotedBound = promoteToNonNull(type.promotedBound!);
        return TypeParameterTypeImpl(
          element: element,
          nullabilitySuffix: NullabilitySuffix.none,
          promotedBound: promotedBound,
        );
      }

      // NonNull(X) = X & NonNull(B), where B is the bound of X
      DartType? promotedBound = element.bound != null
          ? promoteToNonNull(element.bound!)
          : typeProvider.objectType;
      if (identical(promotedBound, element.bound)) {
        promotedBound = null;
      }
      return TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: NullabilitySuffix.none,
        promotedBound: promotedBound,
      );
    }

    return (type as TypeImpl).withNullability(NullabilitySuffix.none);
  }

  /// Determine the type of a binary expression with the given [operator] whose
  /// left operand has the type [leftType] and whose right operand has the type
  /// [rightType], given that resolution has so far produced the [currentType].
  DartType refineBinaryExpressionType(
      DartType leftType,
      TokenType operator,
      DartType rightType,
      DartType currentType,
      MethodElement? operatorElement) {
    if (isNonNullableByDefault) {
      if (operatorElement == null) return currentType;
      return _refineNumericInvocationTypeNullSafe(
          leftType, operatorElement, [rightType], currentType);
    } else {
      return _refineBinaryExpressionTypeLegacy(
          leftType, operator, rightType, currentType);
    }
  }

  /// Determines the context type for the parameters of a method invocation
  /// where the type of the target is [targetType], the method being invoked is
  /// [methodElement], the context surrounding the method invocation is
  /// [invocationContext], and the context type produced so far by resolution is
  /// [currentType].
  DartType refineNumericInvocationContext(
      DartType? targetType,
      Element? methodElement,
      DartType? invocationContext,
      DartType currentType) {
    if (targetType != null &&
        methodElement is MethodElement &&
        isNonNullableByDefault) {
      return _refineNumericInvocationContextNullSafe(
          targetType, methodElement, invocationContext, currentType);
    } else {
      // No special rules apply.
      return currentType;
    }
  }

  /// Determines the type of a method invocation where the type of the target is
  /// [targetType], the method being invoked is [methodElement], the types of
  /// the arguments passed to the method are [argumentTypes], and the type
  /// produced so far by resolution is [currentType].
  ///
  /// TODO(scheglov) I expected that [methodElement] is [MethodElement].
  DartType refineNumericInvocationType(
      DartType targetType,
      Element? methodElement,
      List<DartType> argumentTypes,
      DartType currentType) {
    if (methodElement is MethodElement && isNonNullableByDefault) {
      return _refineNumericInvocationTypeNullSafe(
          targetType, methodElement, argumentTypes, currentType);
    } else {
      // No special rules apply.
      return currentType;
    }
  }

  /// Replaces all covariant occurrences of `dynamic`, `void`, and `Object` or
  /// `Object?` with `Null` or `Never` and all contravariant occurrences of
  /// `Null` or `Never` with `Object` or `Object?`.
  DartType replaceTopAndBottom(DartType dartType) {
    if (isNonNullableByDefault) {
      return ReplaceTopBottomVisitor.run(
        topType: objectQuestion,
        bottomType: NeverTypeImpl.instance,
        typeSystem: this,
        type: dartType,
      );
    } else {
      return ReplaceTopBottomVisitor.run(
        topType: DynamicTypeImpl.instance,
        bottomType: typeProvider.nullType,
        typeSystem: this,
        type: dartType,
      );
    }
  }

  @override
  DartType resolveToBound(DartType type) {
    if (type is TypeParameterTypeImpl) {
      var element = type.element;

      var bound = element.bound;
      if (bound == null) {
        return typeProvider.objectType;
      }

      NullabilitySuffix nullabilitySuffix = type.nullabilitySuffix;
      NullabilitySuffix newNullabilitySuffix;
      if (nullabilitySuffix == NullabilitySuffix.question ||
          bound.nullabilitySuffix == NullabilitySuffix.question) {
        newNullabilitySuffix = NullabilitySuffix.question;
      } else if (nullabilitySuffix == NullabilitySuffix.star ||
          bound.nullabilitySuffix == NullabilitySuffix.star) {
        newNullabilitySuffix = NullabilitySuffix.star;
      } else {
        newNullabilitySuffix = NullabilitySuffix.none;
      }

      var resolved = resolveToBound(bound) as TypeImpl;
      return resolved.withNullability(newNullabilitySuffix);
    }

    return type;
  }

  /// Return `true` if runtime types [T1] and [T2] are equal.
  ///
  /// nnbd/feature-specification.md#runtime-type-equality-operator
  bool runtimeTypesEqual(DartType T1, DartType T2) {
    return RuntimeTypeEqualityHelper(this).equal(T1, T2);
  }

  DartType toLegacyType(DartType type) {
    if (isNonNullableByDefault) return type;
    return NullabilityEliminator.perform(typeProvider, type);
  }

  /// If a legacy library, return the legacy version of the [type].
  /// Otherwise, return the original type.
  DartType toLegacyTypeIfOptOut(DartType type) {
    if (isNonNullableByDefault) {
      return type;
    }
    return NullabilityEliminator.perform(typeProvider, type);
  }

  /// Merges two types into a single type.
  /// Compute the canonical representation of [T].
  ///
  /// https://github.com/dart-lang/language/
  /// See `accepted/future-releases/nnbd/feature-specification.md`
  /// See `#classes-defined-in-opted-in-libraries`
  DartType topMerge(DartType T, DartType S) {
    return TopMergeHelper(this).topMerge(T, S);
  }

  /// Tries to promote from the first type from the second type, and returns the
  /// promoted type if it succeeds, otherwise null.
  DartType? tryPromoteToType(DartType to, DartType from) {
    // Allow promoting to a subtype, for example:
    //
    //     f(Base b) {
    //       if (b is SubTypeOfBase) {
    //         // promote `b` to SubTypeOfBase for this block
    //       }
    //     }
    //
    // This allows the variable to be used wherever the supertype (here `Base`)
    // is expected, while gaining a more precise type.
    if (isSubtypeOf(to, from)) {
      return to;
    }
    // For a type parameter `T extends U`, allow promoting the upper bound
    // `U` to `S` where `S <: U`, yielding a type parameter `T extends S`.
    if (from is TypeParameterType) {
      if (isSubtypeOf(to, from.bound)) {
        var declaration = from.element.declaration;
        return TypeParameterTypeImpl(
          element: declaration,
          nullabilitySuffix: _promotedTypeParameterTypeNullability(
            from.nullabilitySuffix,
            to.nullabilitySuffix,
          ),
          promotedBound: to,
        );
      }
    }

    return null;
  }

  /// Given a [DartType] type, return the [TypeParameterElement]s corresponding
  /// to its formal type parameters (if any).
  ///
  /// @param type the type whose type arguments are to be returned
  /// @return the type arguments associated with the given type
  List<TypeParameterElement> typeFormalsAsElements(DartType type) {
    if (type is FunctionType) {
      return type.typeFormals;
    } else if (type is InterfaceType) {
      return type.element.typeParameters;
    } else {
      return const <TypeParameterElement>[];
    }
  }

  void updateOptions({
    required bool implicitCasts,
    required bool strictCasts,
    required bool strictInference,
  }) {
    this.implicitCasts = implicitCasts;
    this.strictCasts = strictCasts;
    this.strictInference = strictInference;
  }

  List<DartType> _defaultTypeArguments(
    List<TypeParameterElement> typeParameters,
  ) {
    return typeParameters.map((typeParameter) {
      var typeParameterImpl = typeParameter as TypeParameterElementImpl;
      return typeParameterImpl.defaultType!;
    }).toList();
  }

  DartType _refineBinaryExpressionTypeLegacy(DartType leftType,
      TokenType operator, DartType rightType, DartType currentType) {
    if (leftType is TypeParameterType && leftType.bound.isDartCoreNum) {
      if (rightType == leftType || rightType.isDartCoreInt) {
        if (operator == TokenType.PLUS ||
            operator == TokenType.MINUS ||
            operator == TokenType.STAR ||
            operator == TokenType.PLUS_EQ ||
            operator == TokenType.MINUS_EQ ||
            operator == TokenType.STAR_EQ ||
            operator == TokenType.PLUS_PLUS ||
            operator == TokenType.MINUS_MINUS) {
          return leftType;
        }
      }
      if (rightType.isDartCoreDouble) {
        if (operator == TokenType.PLUS ||
            operator == TokenType.MINUS ||
            operator == TokenType.STAR ||
            operator == TokenType.SLASH) {
          return typeProvider.doubleType;
        }
      }
      return currentType;
    }
    // bool
    if (operator == TokenType.AMPERSAND_AMPERSAND ||
        operator == TokenType.BAR_BAR ||
        operator == TokenType.EQ_EQ ||
        operator == TokenType.BANG_EQ) {
      return typeProvider.boolType;
    }
    if (leftType.isDartCoreInt) {
      // int op double
      if (operator == TokenType.MINUS ||
          operator == TokenType.PERCENT ||
          operator == TokenType.PLUS ||
          operator == TokenType.STAR ||
          operator == TokenType.MINUS_EQ ||
          operator == TokenType.PERCENT_EQ ||
          operator == TokenType.PLUS_EQ ||
          operator == TokenType.STAR_EQ) {
        if (rightType.isDartCoreDouble) {
          return typeProvider.doubleType;
        }
      }
      // int op int
      if (operator == TokenType.MINUS ||
          operator == TokenType.PERCENT ||
          operator == TokenType.PLUS ||
          operator == TokenType.STAR ||
          operator == TokenType.TILDE_SLASH ||
          operator == TokenType.MINUS_EQ ||
          operator == TokenType.PERCENT_EQ ||
          operator == TokenType.PLUS_EQ ||
          operator == TokenType.STAR_EQ ||
          operator == TokenType.TILDE_SLASH_EQ ||
          operator == TokenType.PLUS_PLUS ||
          operator == TokenType.MINUS_MINUS) {
        if (rightType.isDartCoreInt) {
          return typeProvider.intType;
        }
      }
    }
    // default
    return currentType;
  }

  DartType _refineNumericInvocationContextNullSafe(
      DartType targetType,
      MethodElement methodElement,
      DartType? invocationContext,
      DartType currentType) {
    // If the method being invoked comes from an extension, don't refine the
    // type because we can only make guarantees about methods defined in the
    // SDK, and the numeric methods we refine are all instance methods.
    if (methodElement.enclosingElement is ExtensionElement) {
      return currentType;
    }

    // Sometimes the analyzer represents the unknown context as `null`.
    invocationContext ??= UnknownInferredType.instance;

    // If e is an expression of the form e1 + e2, e1 - e2, e1 * e2, e1 % e2 or
    // e1.remainder(e2)...
    if (const {'+', '-', '*', '%', 'remainder'}.contains(methodElement.name)) {
      // ...where C is the context type of e and T is the static type of e1, and
      // where T is a non-Never subtype of num...
      // Notes:
      // - We don't have to check for Never because if T is Never, the method
      //   element will fail to resolve so we'll never reach here.
      // - We actually check against `num?` rather than `num`.  It's equivalent
      //   from the standpoint of correctness (since it's illegal to call these
      //   methods on nullable types, and that's checked for elsewhere), but
      //   better from the standpoint of error recovery (since it allows e.g.
      //   `int? + int` to resolve to `int` rather than `num`).
      var c = invocationContext;
      var t = targetType;
      assert(!t.isBottom);
      var numType = typeProvider.numType;
      if (isSubtypeOf(t, typeProvider.numTypeQuestion)) {
        // Then:
        // - If int <: C, not num <: C, and T <: int, then the context type of
        //   e2 is int.
        // (Note: as above, we check the type of T against `int?`, because it's
        // equivalent and leads to better error recovery.)
        var intType = typeProvider.intType;
        if (isSubtypeOf(intType, c) &&
            !isSubtypeOf(numType, c) &&
            isSubtypeOf(t, typeProvider.intTypeQuestion)) {
          return intType;
        }
        // - If double <: C, not num <: C, and not T <: double, then the context
        //   type of e2 is double.
        // (Note: as above, we check the type of T against `double?`, because
        // it's equivalent and leads to better error recovery.)
        var doubleType = typeProvider.doubleType;
        if (isSubtypeOf(doubleType, c) &&
            !isSubtypeOf(numType, c) &&
            !isSubtypeOf(t, typeProvider.doubleTypeQuestion)) {
          return doubleType;
        }
        // Otherwise, the context type of e2 is num.
        return numType;
      }
    }
    // If e is an expression of the form e1.clamp(e2, e3)...
    if (methodElement.name == 'clamp') {
      // ...where C is the context type of e and T is the static type of e1
      // where T is a non-Never subtype of num...
      // Notes:
      // - We don't have to check for Never because if T is Never, the method
      //   element will fail to resolve so we'll never reach here.
      // - We actually check against `num?` rather than `num`.  It's
      //   equivalent from the standpoint of correctness (since it's illegal
      //   to call `num.clamp` on a nullable type or to pass it a nullable
      //   type as an argument, and that's checked for elsewhere), but better
      //   from the standpoint of error recovery (since it allows e.g.
      //   `int?.clamp(e2, e3)` to give the same context to `e2` and `e3` that
      //   `int.clamp(e2, e3` would).
      var c = invocationContext;
      var t = targetType;
      assert(!t.isBottom);
      var numType = typeProvider.numType;
      if (isSubtypeOf(t, typeProvider.numTypeQuestion)) {
        // Then:
        // - If int <: C, not num <: C, and T <: int, then the context type of
        //   e2 and e3 is int.
        // (Note: as above, we check the type of T against `int?`, because it's
        // equivalent and leads to better error recovery.)
        var intType = typeProvider.intType;
        if (isSubtypeOf(intType, c) &&
            !isSubtypeOf(numType, c) &&
            isSubtypeOf(t, typeProvider.intTypeQuestion)) {
          return intType;
        }
        // - If double <: C, not num <: C, and T <: double, then the context
        //   type of e2 and e3 is double.
        var doubleType = typeProvider.doubleType;
        if (isSubtypeOf(doubleType, c) &&
            !isSubtypeOf(numType, c) &&
            isSubtypeOf(t, typeProvider.doubleTypeQuestion)) {
          return doubleType;
        }
        // - Otherwise the context type of e2 an e3 is num.
        return numType;
      }
    }
    // No special rules apply.
    return currentType;
  }

  DartType _refineNumericInvocationTypeNullSafe(
      DartType targetType,
      MethodElement methodElement,
      List<DartType> argumentTypes,
      DartType currentType) {
    // If the method being invoked comes from an extension, don't refine the
    // type because we can only make guarantees about methods defined in the
    // SDK, and the numeric methods we refine are all instance methods.
    if (methodElement.enclosingElement is ExtensionElement) {
      return currentType;
    }

    // Let e be an expression of one of the forms e1 + e2, e1 - e2, e1 * e2,
    // e1 % e2 or e1.remainder(e2)...
    if (const {'+', '-', '*', '%', 'remainder'}.contains(methodElement.name)) {
      // ...where the static type of e1 is a non-Never type T and T <: num...
      // Notes:
      // - We don't have to check for Never because if T is Never, the method
      //   element will fail to resolve so we'll never reach here.
      // - We actually check against `num?` rather than `num`.  It's equivalent
      //   from the standpoint of correctness (since it's illegal to call these
      //   methods on nullable types, and that's checked for elsewhere), but
      //   better from the standpoint of error recovery (since it allows e.g.
      //   `int? + int` to resolve to `int` rather than `num`).
      var t = targetType;
      assert(!t.isBottom);
      if (isSubtypeOf(t, typeProvider.numTypeQuestion)) {
        // ...and where the static type of e2 is S and S is assignable to num.
        // (Note: we don't have to check that S is assignable to num because
        // this is required by the signature of the method.)
        if (argumentTypes.length == 1) {
          var s = argumentTypes[0];
          // Then:
          // - If T <: double then the static type of e is double. This includes
          //   S being dynamic or Never.
          // (Note: as above, we check against `double?` because it's equivalent
          // and leads to better error recovery.)
          var doubleType = typeProvider.doubleType;
          var doubleTypeQuestion = typeProvider.doubleTypeQuestion;
          if (isSubtypeOf(t, doubleTypeQuestion)) {
            return doubleType;
          }
          // - If S <: double and not S <: Never, then the static type of e is
          //   double.
          // (Again, we check against `double?` for error recovery.)
          if (!s.isBottom && isSubtypeOf(s, doubleTypeQuestion)) {
            return doubleType;
          }
          // - If T <: int, S <: int and not S <: Never, then the static type of
          //   e is int.
          // (As above, we check against `int?` for error recovery.)
          var intTypeQuestion = typeProvider.intTypeQuestion;
          if (!s.isBottom &&
              isSubtypeOf(t, intTypeQuestion) &&
              isSubtypeOf(s, intTypeQuestion)) {
            return typeProvider.intType;
          }
          // - Otherwise the static type of e is num.
          return typeProvider.numType;
        }
      }
    }
    // Let e be a normal invocation of the form e1.clamp(e2, e3)...
    if (methodElement.name == 'clamp') {
      // ...where the static types of e1, e2 and e3 are T1, T2 and T3
      // respectively...
      var t1 = targetType;
      if (argumentTypes.length == 2) {
        var t2 = argumentTypes[0];
        var t3 = argumentTypes[1];
        // ...and where T1, T2, and T3 are all non-Never subtypes of num.
        // Notes:
        // - We don't have to check T1 for Never because if T1 is Never, the
        //   method element will fail to resolve so we'll never reach here.
        // - We actually check against `num?` rather than `num`.  It's
        //   equivalent from the standpoint of correctness (since it's illegal
        //   to call `num.clamp` on a nullable type or to pass it a nullable
        //   type as an argument, and that's checked for elsewhere), but better
        //   from the standpoint of error recovery (since it allows e.g.
        //   `int?.clamp(int, int)` to resolve to `int` rather than `num`).
        // - We don't check that T2 and T3 are subtypes of num because the
        //   signature of `num.clamp` requires it.
        var numTypeQuestion = typeProvider.numTypeQuestion;
        if (isSubtypeOf(t1, numTypeQuestion) && !t2.isBottom && !t3.isBottom) {
          assert(!t1.isBottom);
          // Then:
          // - If T1, T2 and T3 are all subtypes of int, the static type of e is
          //   int.
          // (Note: as above, we check against `int?` because it's equivalent
          // and leads to better error recovery.)
          var intTypeQuestion = typeProvider.intTypeQuestion;
          if (isSubtypeOf(t1, intTypeQuestion) &&
              isSubtypeOf(t2, intTypeQuestion) &&
              isSubtypeOf(t3, intTypeQuestion)) {
            return typeProvider.intType;
          }
          // If T1, T2 and T3 are all subtypes of double, the static type of e
          // is double.
          // (As above, we check against `double?` for error recovery.)
          var doubleTypeQuestion = typeProvider.doubleTypeQuestion;
          if (isSubtypeOf(t1, doubleTypeQuestion) &&
              isSubtypeOf(t2, doubleTypeQuestion) &&
              isSubtypeOf(t3, doubleTypeQuestion)) {
            return typeProvider.doubleType;
          }
          // Otherwise the static type of e is num.
          return typeProvider.numType;
        }
      }
    }
    // No special rules apply.
    return currentType;
  }

  DartType _removeBoundsOfGenericFunctionTypes(DartType type) {
    return _RemoveBoundsOfGenericFunctionTypeVisitor.run(
      bottomType: isNonNullableByDefault
          ? NeverTypeImpl.instance
          : typeProvider.nullType,
      type: type,
    );
  }

  static NullabilitySuffix _promotedTypeParameterTypeNullability(
    NullabilitySuffix nullabilityOfType,
    NullabilitySuffix nullabilityOfBound,
  ) {
    if (nullabilityOfType == NullabilitySuffix.question &&
        nullabilityOfBound == NullabilitySuffix.none) {
      return NullabilitySuffix.none;
    }

    if (nullabilityOfType == NullabilitySuffix.question &&
        nullabilityOfBound == NullabilitySuffix.question) {
      return NullabilitySuffix.question;
    }

    if (nullabilityOfType == NullabilitySuffix.star &&
        nullabilityOfBound == NullabilitySuffix.none) {
      return NullabilitySuffix.star;
    }

    // Intersection with a non-nullable type always yields a non-nullable type,
    // as it's the most restrictive kind of types.
    if (nullabilityOfType == NullabilitySuffix.none ||
        nullabilityOfBound == NullabilitySuffix.none) {
      return NullabilitySuffix.none;
    }

    return NullabilitySuffix.star;
  }
}

/// TODO(scheglov) Ask the language team how to deal with it.
class _RemoveBoundsOfGenericFunctionTypeVisitor extends ReplacementVisitor {
  final DartType _bottomType;

  _RemoveBoundsOfGenericFunctionTypeVisitor._(this._bottomType);

  @override
  DartType visitTypeParameterBound(DartType type) {
    return _bottomType;
  }

  static DartType run({
    required DartType bottomType,
    required DartType type,
  }) {
    var visitor = _RemoveBoundsOfGenericFunctionTypeVisitor._(bottomType);
    var result = type.accept(visitor);
    return result ?? type;
  }
}

class _TypeVariableEliminator extends Substitution {
  final DartType _topType;
  final DartType _bottomType;

  _TypeVariableEliminator(
    this._topType,
    this._bottomType,
  );

  @override
  DartType getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return upperBound ? _bottomType : _topType;
  }
}
