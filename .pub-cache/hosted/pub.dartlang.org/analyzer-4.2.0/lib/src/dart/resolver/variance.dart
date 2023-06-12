// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// The variance of a type parameter `X` in a type `T`.
class Variance {
  /// Used when `X` does not occur free in `T`.
  static const Variance unrelated = Variance._(0);

  /// Used when `X` occurs free in `T`, and `U <: V` implies `[U/X]T <: [V/X]T`.
  static const Variance covariant = Variance._(1);

  /// Used when `X` occurs free in `T`, and `U <: V` implies `[V/X]T <: [U/X]T`.
  static const Variance contravariant = Variance._(2);

  /// Used when there exists a pair `U` and `V` such that `U <: V`, but
  /// `[U/X]T` and `[V/X]T` are incomparable.
  static const Variance invariant = Variance._(3);

  /// The encoding associated with the variance.
  final int _encoding;

  /// Computes the variance of the [typeParameter] in the [type].
  factory Variance(TypeParameterElement typeParameter, DartType type) {
    if (type is TypeParameterType) {
      if (type.element == typeParameter) {
        return covariant;
      } else {
        return unrelated;
      }
    } else if (type is InterfaceType) {
      var result = unrelated;
      for (int i = 0; i < type.typeArguments.length; ++i) {
        var argument = type.typeArguments[i];
        var parameter = type.element.typeParameters[i];

        // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
        // variance is added to the interface.
        var parameterVariance =
            (parameter as TypeParameterElementImpl).variance;
        result = result
            .meet(parameterVariance.combine(Variance(typeParameter, argument)));
      }
      return result;
    } else if (type is FunctionType) {
      var result = Variance(typeParameter, type.returnType);

      for (var parameter in type.typeFormals) {
        // If [parameter] is referenced in the bound at all, it makes the
        // variance of [parameter] in the entire type invariant.  The invocation
        // of [computeVariance] below is made to simply figure out if [variable]
        // occurs in the bound.
        var bound = parameter.bound;
        if (bound != null && !Variance(typeParameter, bound).isUnrelated) {
          result = invariant;
        }
      }

      for (var parameter in type.parameters) {
        result = result.meet(
          contravariant.combine(
            Variance(typeParameter, parameter.type),
          ),
        );
      }
      return result;
    }
    return unrelated;
  }

  /// Return the variance associated with the string representation of variance.
  factory Variance.fromKeywordString(String varianceString) {
    if (varianceString == "in") {
      return contravariant;
    } else if (varianceString == "inout") {
      return invariant;
    } else if (varianceString == "out") {
      return covariant;
    } else if (varianceString == "unrelated") {
      return unrelated;
    }
    throw ArgumentError('Invalid keyword string for variance: $varianceString');
  }

  /// Initialize a newly created variance to have the given [encoding].
  const Variance._(this._encoding);

  /// Return the variance with the given [encoding].
  factory Variance._fromEncoding(int encoding) {
    switch (encoding) {
      case 0:
        return unrelated;
      case 1:
        return covariant;
      case 2:
        return contravariant;
      case 3:
        return invariant;
    }
    throw ArgumentError('Invalid encoding for variance: $encoding');
  }

  /// Return `true` if this represents the case when `X` occurs free in `T`, and
  /// `U <: V` implies `[V/X]T <: [U/X]T`.
  bool get isContravariant => this == contravariant;

  /// Return `true` if this represents the case when `X` occurs free in `T`, and
  /// `U <: V` implies `[U/X]T <: [V/X]T`.
  bool get isCovariant => this == covariant;

  /// Return `true` if this represents the case when there exists a pair `U` and
  /// `V` such that `U <: V`, but `[U/X]T` and `[V/X]T` are incomparable.
  bool get isInvariant => this == invariant;

  /// Return `true` if this represents the case when `X` does not occur free in
  /// `T`.
  bool get isUnrelated => this == unrelated;

  /// Combines variances of `X` in `T` and `Y` in `S` into variance of `X` in
  /// `[Y/T]S`.
  ///
  /// Consider the following examples:
  ///
  /// * variance of `X` in `Function(X)` is contravariant, variance of `Y`
  /// in `List<Y>` is covariant, so variance of `X` in `List<Function(X)>` is
  /// contravariant;
  ///
  /// * variance of `X` in `List<X>` is covariant, variance of `Y` in
  /// `Function(Y)` is contravariant, so variance of `X` in
  /// `Function(List<X>)` is contravariant;
  ///
  /// * variance of `X` in `Function(X)` is contravariant, variance of `Y` in
  /// `Function(Y)` is contravariant, so variance of `X` in
  /// `Function(Function(X))` is covariant;
  ///
  /// * let the following be declared:
  ///
  ///     typedef F<Z> = Function();
  ///
  /// then variance of `X` in `F<X>` is unrelated, variance of `Y` in
  /// `List<Y>` is covariant, so variance of `X` in `List<F<X>>` is
  /// unrelated;
  ///
  /// * let the following be declared:
  ///
  ///     typedef G<Z> = Z Function(Z);
  ///
  /// then variance of `X` in `List<X>` is covariant, variance of `Y` in
  /// `G<Y>` is invariant, so variance of `X` in `G<List<X>>` is invariant.
  Variance combine(Variance other) {
    if (isUnrelated || other.isUnrelated) return unrelated;
    if (isInvariant || other.isInvariant) return invariant;
    return this == other ? covariant : contravariant;
  }

  /// Returns true if this variance is greater than (above) or equal to the
  /// [other] variance in the partial order induced by the variance lattice.
  ///
  ///       unrelated
  /// covariant   contravariant
  ///       invariant
  bool greaterThanOrEqual(Variance other) {
    if (isUnrelated) {
      return true;
    } else if (isCovariant) {
      return other.isCovariant || other.isInvariant;
    } else if (isContravariant) {
      return other.isContravariant || other.isInvariant;
    } else {
      assert(isInvariant);
      return other.isInvariant;
    }
  }

  /// Variance values form a lattice where unrelated is the top, invariant
  /// is the bottom, and covariant and contravariant are incomparable.
  /// [meet] calculates the meet of two elements of such lattice.  It can be
  /// used, for example, to calculate the variance of a typedef type parameter
  /// if it's encountered on the RHS of the typedef multiple times.
  ///
  ///       unrelated
  /// covariant   contravariant
  ///       invariant
  Variance meet(Variance other) =>
      Variance._fromEncoding(_encoding | other._encoding);

  /// Returns the associated keyword lexeme.
  String toKeywordString() {
    switch (this) {
      case contravariant:
        return 'in';
      case invariant:
        return 'inout';
      case covariant:
        return 'out';
      case unrelated:
        return '';
      default:
        throw ArgumentError(
            'Missing keyword lexeme representation for variance: $this');
    }
  }

  @override
  String toString() {
    switch (this) {
      case contravariant:
        return 'contravariant';
      case invariant:
        return 'invariant';
      case covariant:
        return 'covariant';
      case unrelated:
        return 'unrelated';
      default:
        throw UnimplementedError('encoding: $_encoding');
    }
  }
}
