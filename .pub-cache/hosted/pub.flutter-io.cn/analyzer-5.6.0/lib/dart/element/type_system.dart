// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

/// A representation of the operations defined for the type system.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeSystem {
  /// Return the result of applying the function "flatten" to the given [type].
  ///
  /// For the Dart 2.0 type system, the function is defined in the Dart Language
  /// Specification, section 16.11 Function Expressions:
  ///
  /// > We define the auxiliary function _flatten(T)_, which is used below and
  /// > in other sections, as follows:
  /// >
  /// > * If _T_ is `FutureOr<`_S_`>` for some _S_ then _flatten(T)_ = _S_.
  /// >
  /// > * Otherwise if _T_ <: `Future` then let _S_ be a type such that _T_ <:
  /// >   `Future<`_S_`>` and for all _R_, if _T_ <: `Future<`_R_`>` then _S_ <:
  /// >   _R_. This ensures that `Future<`_S_`>` is the most specific generic
  /// >   instantiation of `Future` that is a supertype of _T_. Note that _S_ is
  /// >   well-defined because of the requirements on superinterfaces. Then
  /// >   _flatten(T)_ = _S_.
  /// >
  /// > * In any other circumstance, _flatten(T)_ = _T_.
  ///
  /// The subtype relationship (<:) can be tested using [isSubtypeOf].
  ///
  /// Other type systems may define this operation differently.
  DartType flatten(DartType type);

  /// Instantiate the given [element] with default type arguments.
  InterfaceType instantiateInterfaceToBounds({
    required InterfaceElement element,
    required NullabilitySuffix nullabilitySuffix,
  });

  /// Instantiate the given generic element using the type arguments that
  /// correspond to the bounds of its type parameters.
  ///
  /// One and only one of [classElement] or [typeAliasElement] must
  /// be provided.
  @Deprecated('Use instantiateInterface/TypeAliasToBounds() instead')
  DartType instantiateToBounds2({
    ClassElement? classElement,
    TypeAliasElement? typeAliasElement,
    required NullabilitySuffix nullabilitySuffix,
  });

  /// Instantiate the given [element] with default type arguments.
  DartType instantiateTypeAliasToBounds({
    required TypeAliasElement element,
    required NullabilitySuffix nullabilitySuffix,
  });

  /// Return `true` if the [leftType] is assignable to the [rightType].
  ///
  /// For the Dart 2.0 type system, the definition of this relationship is given
  /// in the Dart Language Specification, section 19.4 Subtypes:
  ///
  /// > A type _T_ may be assigned to a type _S_ in an environment &Gamma;,
  /// > written &Gamma; &#8866; _T_ &hArr; _S_, iff either &Gamma; &#8866; _S_
  /// > <: _T_ or &Gamma; &#8866; _T_ <: _S_. In this case we say that the types
  /// > _S_ and _T_ are assignable.
  ///
  /// The subtype relationship (<:) can be tested using [isSubtypeOf].
  ///
  /// Other type systems may define this operation differently. In particular,
  /// while the operation is commutative in the Dart 2.0 type system, it will
  /// not be commutative when NNBD is enabled, so the order of the arguments is
  /// important.
  bool isAssignableTo(DartType leftType, DartType rightType);

  /// Return `true` if the [type] is a non-nullable type.
  ///
  /// We say that a type `T` is non-nullable if `T <: Object`. This is
  /// equivalent to the syntactic criterion that `T` is any of:
  /// - `Object`, `int`, `bool`, `Never`, `Function`
  /// - Any function type
  /// - Any class type or generic class type
  /// - `FutureOr<S>` where `S` is non-nullable
  /// - `X extends S` where `S` is non-nullable
  /// - `X & S` where `S` is non-nullable
  ///
  /// The result of this method is undefined when the experiment 'non-nullable'
  /// is not enabled.
  bool isNonNullable(DartType type);

  /// Return `true` if the [type] is a nullable type.
  ///
  /// We say that a type `T` is nullable if `Null <: T`. This is equivalent to
  /// the syntactic criterion that `T` is any of:
  /// - `Null`
  /// - `S?` for some `S`
  /// - `FutureOr<S>` for some `S` where `S` is nullable
  /// - `dynamic`
  /// - `void`
  ///
  /// The result of this method is undefined when the experiment 'non-nullable'
  /// is not enabled.
  bool isNullable(DartType type);

  /// Return `true` if the [type] is a potentially non-nullable type.
  ///
  /// We say that a type `T` is potentially non-nullable if `T` is not nullable.
  /// Note that this is different from saying that `T` is non-nullable. For
  /// example, a type variable `X extends Object?` is a type which is
  /// potentially non-nullable but not non-nullable.
  ///
  /// The result of this method is undefined when the experiment 'non-nullable'
  /// is not enabled.
  bool isPotentiallyNonNullable(DartType type);

  /// Return `true` if the [type] is a potentially nullable type.
  ///
  /// We say that a type `T` is potentially nullable if `T` is not non-nullable.
  /// Note that this is different from saying that `T` is nullable. For example,
  /// a type variable `X extends Object?` is a type which is potentially
  /// nullable but not nullable.
  ///
  /// The result of this method is undefined when the experiment 'non-nullable'
  /// is not enabled.
  bool isPotentiallyNullable(DartType type);

  /// Return `true` if the [type] is a strictly non-nullable type.
  ///
  /// We say that a type `T` is strictly non-nullable if `T <: Object` and not
  /// `Null <: T`. This is equivalent to the syntactic criterion that `T` is
  /// any of:
  /// - `Never`
  /// - Any function type (including `Function`)
  /// - Any interface type except `Null`
  /// - `FutureOr<S>` where `S` is strictly non-nullable
  /// - `X extends S` where `S` is strictly non-nullable
  /// - `X & S` where `S` is strictly non-nullable
  ///
  /// The result of this method is undefined when the experiment 'non-nullable'
  /// is not enabled.
  bool isStrictlyNonNullable(DartType type);

  /// Return `true` if the [leftType] is a subtype of the [rightType].
  ///
  /// For the Dart 2.0 type system, the rules governing the subtype relationship
  /// are given in the Dart Language Specification, section 19.4 Subtypes.
  ///
  /// Other type systems may define this operation differently.
  bool isSubtypeOf(DartType leftType, DartType rightType);

  /// Compute the least upper bound of two types. This operation if commutative,
  /// meaning that `leastUpperBound(t, s) == leastUpperBound(s, t)` for all `t`
  /// and `s`.
  ///
  /// For the Dart 2.0 type system, the definition of the least upper bound is
  /// given in the Dart Language Specification, section 19.9.2 Least Upper
  /// Bounds.
  ///
  /// Other type systems may define this operation differently.
  DartType leastUpperBound(DartType leftType, DartType rightType);

  /// Returns a non-nullable version of [type].  This is equivalent to the
  /// operation `NonNull` defined in the spec.
  DartType promoteToNonNull(DartType type);

  /// Return the result of resolving the bounds of the given [type].
  ///
  /// For the Dart 2.0 type system, the definition of resolving to bounds is
  /// defined by the following. If the given [type] is a [TypeParameterType] and
  /// it has a bound, return the result of resolving its bound (as per this
  /// method). If the [type] is a [TypeParameterType] and it does not have a
  /// bound, return the type `Object`. For any other type, return the given
  /// type.
  ///
  /// Other type systems may define this operation differently.
  DartType resolveToBound(DartType type);
}
