// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

class LeastGreatestClosureHelper extends ReplacementVisitor {
  final TypeSystemImpl typeSystem;
  final DartType topType;
  final DartType topFunctionType;
  final DartType bottomType;
  final Set<TypeParameterElement> eliminationTargets;

  late final bool _isLeastClosure;
  bool _isCovariant = true;

  LeastGreatestClosureHelper({
    required this.typeSystem,
    required this.topType,
    required this.topFunctionType,
    required this.bottomType,
    required this.eliminationTargets,
  });

  DartType get _functionReplacement {
    return _isLeastClosure && _isCovariant ||
            (!_isLeastClosure && !_isCovariant)
        ? bottomType
        : topFunctionType;
  }

  DartType get _typeParameterReplacement {
    return _isLeastClosure && _isCovariant ||
            (!_isLeastClosure && !_isCovariant)
        ? bottomType
        : topType;
  }

  @override
  void changeVariance() {
    _isCovariant = !_isCovariant;
  }

  /// Returns a supertype of [type] for all values of [eliminationTargets].
  DartType eliminateToGreatest(DartType type) {
    _isCovariant = true;
    _isLeastClosure = false;
    return type.accept(this) ?? type;
  }

  /// Returns a subtype of [type] for all values of [eliminationTargets].
  DartType eliminateToLeast(DartType type) {
    _isCovariant = true;
    _isLeastClosure = true;
    return type.accept(this) ?? type;
  }

  @override
  DartType? visitFunctionType(FunctionType node) {
    // - if `S` is
    //   `T Function<X0 extends B0, ...., Xk extends Bk>(T0 x0, ...., Tn xn,
    //       [Tn+1 xn+1, ..., Tm xm])`
    //   or `T Function<X0 extends B0, ...., Xk extends Bk>(T0 x0, ...., Tn xn,
    //       {Tn+1 xn+1, ..., Tm xm})`
    //   and `L` contains any free type variables from any of the `Bi`:
    //  - The least closure of `S` with respect to `L` is `Never`
    //  - The greatest closure of `S` with respect to `L` is `Function`
    for (var typeParameter in node.typeFormals) {
      var bound = typeParameter.bound as TypeImpl;
      if (bound.referencesAny(eliminationTargets)) {
        return _functionReplacement;
      }
    }

    return super.visitFunctionType(node);
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType type) {
    if (eliminationTargets.contains(type.element)) {
      var replacement = _typeParameterReplacement as TypeImpl;
      return replacement.withNullability(
        uniteNullabilities(
          replacement.nullabilitySuffix,
          type.nullabilitySuffix,
        ),
      );
    }
    return super.visitTypeParameterType(type);
  }
}
