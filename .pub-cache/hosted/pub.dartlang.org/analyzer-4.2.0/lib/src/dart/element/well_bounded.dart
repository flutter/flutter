// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

class NotWellBoundedTypeResult implements TypeBoundedResult {
  final String elementName;
  final List<TypeArgumentIssue> issues;

  NotWellBoundedTypeResult._({
    required this.elementName,
    required this.issues,
  });
}

class RegularBoundedTypeResult implements WellBoundedTypeResult {
  const RegularBoundedTypeResult._();
}

class SuperBoundedTypeResult implements WellBoundedTypeResult {
  const SuperBoundedTypeResult._();
}

class TypeArgumentIssue {
  /// The index for type argument within the passed type arguments.
  final int index;

  /// The type parameter with the bound that was violated.
  final TypeParameterElement parameter;

  /// The substituted bound of the [parameter].
  final DartType parameterBound;

  /// The type argument that violated the [parameterBound].
  final DartType argument;

  TypeArgumentIssue(
    this.index,
    this.parameter,
    this.parameterBound,
    this.argument,
  );

  @override
  String toString() {
    return 'TypeArgumentIssue(index=$index, parameter=$parameter, '
        'parameterBound=$parameterBound, argument=$argument)';
  }
}

/// Helper for checking whether a type if well-bounded.
///
/// See `15.2 Super-bounded types` in the language specification.
class TypeBoundedHelper {
  final TypeSystemImpl typeSystem;

  TypeBoundedHelper(this.typeSystem);

  TypeBoundedResult isWellBounded(
    DartType type, {
    required bool allowSuperBounded,
  }) {
    var result = _isRegularBounded(type);
    if (!allowSuperBounded) {
      return result;
    }

    return _isSuperBounded(type);
  }

  TypeBoundedResult _isRegularBounded(DartType type) {
    List<TypeArgumentIssue>? issues;

    final String elementName;
    final List<TypeParameterElement> typeParameters;
    final List<DartType> typeArguments;
    final alias = type.alias;
    if (alias != null) {
      elementName = alias.element.name;
      typeParameters = alias.element.typeParameters;
      typeArguments = alias.typeArguments;
    } else if (type is InterfaceType) {
      elementName = type.element.name;
      typeParameters = type.element.typeParameters;
      typeArguments = type.typeArguments;
    } else {
      return const RegularBoundedTypeResult._();
    }

    final substitution = Substitution.fromPairs(typeParameters, typeArguments);
    for (var i = 0; i < typeParameters.length; i++) {
      var typeParameter = typeParameters[i];
      var typeArgument = typeArguments[i];

      var bound = typeParameter.bound;
      if (bound == null) {
        continue;
      }

      bound = typeSystem.toLegacyTypeIfOptOut(bound);
      bound = substitution.substituteType(bound);

      if (!typeSystem.isSubtypeOf(typeArgument, bound)) {
        issues ??= <TypeArgumentIssue>[];
        issues.add(
          TypeArgumentIssue(i, typeParameter, bound, typeArgument),
        );
      }
    }

    if (issues == null) {
      return const RegularBoundedTypeResult._();
    } else {
      return NotWellBoundedTypeResult._(
        elementName: elementName,
        issues: issues,
      );
    }
  }

  TypeBoundedResult _isSuperBounded(DartType type) {
    final invertedType = typeSystem.replaceTopAndBottom(type);
    var result = _isRegularBounded(invertedType);
    if (result is RegularBoundedTypeResult) {
      return const SuperBoundedTypeResult._();
    } else {
      return result;
    }
  }
}

abstract class TypeBoundedResult {}

class WellBoundedTypeResult implements TypeBoundedResult {}
