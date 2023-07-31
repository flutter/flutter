// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

class RuntimeTypeEqualityHelper {
  final TypeSystemImpl _typeSystem;

  RuntimeTypeEqualityHelper(TypeSystemImpl typeSystem)
      : _typeSystem = typeSystem;

  /// Return `true` if runtime types [T1] and [T2] are equal.
  ///
  /// nnbd/feature-specification.md#runtime-type-equality-operator
  bool equal(DartType T1, DartType T2) {
    var N1 = _typeSystem.normalize(T1);
    var N2 = _typeSystem.normalize(T2);
    return N1.acceptWithArgument(const RuntimeTypeEqualityVisitor(), N2);
  }
}

class RuntimeTypeEqualityVisitor
    extends TypeVisitorWithArgument<bool, DartType> {
  const RuntimeTypeEqualityVisitor();

  @override
  bool visitDynamicType(DynamicType T1, DartType T2) {
    return identical(T1, T2);
  }

  @override
  bool visitFunctionType(FunctionType T1, DartType T2) {
    if (T2 is FunctionType) {
      var typeParameters = _typeParameters(T1.typeFormals, T2.typeFormals);
      if (typeParameters == null) {
        return false;
      }

      bool equal(DartType T1, DartType T2) {
        T1 = typeParameters.T1_substitution.substituteType(T1);
        T2 = typeParameters.T2_substitution.substituteType(T2);
        return T1.acceptWithArgument(this, T2);
      }

      if (!equal(T1.returnType, T2.returnType)) {
        return false;
      }

      var T1_parameters = T1.parameters;
      var T2_parameters = T2.parameters;
      if (T1_parameters.length != T2_parameters.length) {
        return false;
      }

      for (var i = 0; i < T1_parameters.length; i++) {
        var T1_parameter = T1_parameters[i];
        var T2_parameter = T2_parameters[i];

        // ignore: deprecated_member_use_from_same_package
        if (T1_parameter.parameterKind != T2_parameter.parameterKind) {
          return false;
        }

        if (T1_parameter.isNamed) {
          if (T1_parameter.name != T2_parameter.name) {
            return false;
          }
        }

        if (!equal(T1_parameter.type, T2_parameter.type)) {
          return false;
        }
      }

      return true;
    }
    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType T1, DartType T2) {
    if (T2 is InterfaceType &&
        T1.element == T2.element &&
        _compatibleNullability(T1, T2)) {
      var T1_typeArguments = T1.typeArguments;
      var T2_typeArguments = T2.typeArguments;
      if (T1_typeArguments.length == T2_typeArguments.length) {
        for (var i = 0; i < T1_typeArguments.length; i++) {
          var T1_typeArgument = T1_typeArguments[i];
          var T2_typeArgument = T2_typeArguments[i];
          if (!T1_typeArgument.acceptWithArgument(this, T2_typeArgument)) {
            return false;
          }
        }
        return true;
      }
    }
    return false;
  }

  @override
  bool visitNeverType(NeverType T1, DartType T2) {
    // Note, that all types are normalized before this visitor.
    // So, `Never?` never happens, it is already `Null`.
    assert(T1.nullabilitySuffix != NullabilitySuffix.question);
    return T2 is NeverTypeImpl && _compatibleNullability(T1, T2);
  }

  @override
  bool visitRecordType(RecordType T1, DartType T2) {
    if (T1 is! RecordTypeImpl || T2 is! RecordTypeImpl) {
      return false;
    }

    if (!_compatibleNullability(T1, T2)) {
      return false;
    }

    final positional1 = T1.positionalFields;
    final positional2 = T2.positionalFields;
    if (positional1.length != positional2.length) {
      return false;
    }

    final named1 = T1.namedFields;
    final named2 = T2.namedFields;
    if (named1.length != named2.length) {
      return false;
    }

    for (var i = 0; i < positional1.length; i++) {
      final field1 = positional1[i];
      final field2 = positional2[i];
      if (!field1.type.acceptWithArgument(this, field2.type)) {
        return false;
      }
    }

    for (var i = 0; i < named1.length; i++) {
      final field1 = named1[i];
      final field2 = named2[i];
      if (field1.name != field2.name) {
        return false;
      }
      if (!field1.type.acceptWithArgument(this, field2.type)) {
        return false;
      }
    }

    return true;
  }

  @override
  bool visitTypeParameterType(TypeParameterType T1, DartType T2) {
    return T2 is TypeParameterType &&
        _compatibleNullability(T1, T2) &&
        T1.element == T2.element;
  }

  @override
  bool visitVoidType(VoidType T1, DartType T2) {
    return identical(T1, T2);
  }

  bool _compatibleNullability(DartType T1, DartType T2) {
    var T1_nullability = T1.nullabilitySuffix;
    var T2_nullability = T2.nullabilitySuffix;
    return T1_nullability == T2_nullability ||
        T1_nullability == NullabilitySuffix.star &&
            T2_nullability == NullabilitySuffix.none ||
        T2_nullability == NullabilitySuffix.star &&
            T1_nullability == NullabilitySuffix.none;
  }

  /// Determines if the two lists of type parameters are equal.  If they are,
  /// returns a [_TypeParametersResult] indicating the substitutions necessary
  /// to demonstrate their equality.  If they aren't, returns `null`.
  _TypeParametersResult? _typeParameters(
    List<TypeParameterElement> T1_parameters,
    List<TypeParameterElement> T2_parameters,
  ) {
    if (T1_parameters.length != T2_parameters.length) {
      return null;
    }

    var newParameters = <TypeParameterElementImpl>[];
    var newTypes = <TypeParameterType>[];
    for (var i = 0; i < T1_parameters.length; i++) {
      var name = T1_parameters[i].name;
      var newParameter = TypeParameterElementImpl.synthetic(name);
      newParameters.add(newParameter);

      var newType = newParameter.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
      newTypes.add(newType);
    }

    var T1_substitution = Substitution.fromPairs(T1_parameters, newTypes);
    var T2_substitution = Substitution.fromPairs(T2_parameters, newTypes);
    for (var i = 0; i < T1_parameters.length; i++) {
      var T1_parameter = T1_parameters[i];
      var T2_parameter = T2_parameters[i];

      var T1_bound = T1_parameter.bound;
      var T2_bound = T2_parameter.bound;
      if (T1_bound == null && T2_bound == null) {
        // OK, no bound.
      } else if (T1_bound != null && T2_bound != null) {
        T1_bound = T1_substitution.substituteType(T1_bound);
        T2_bound = T2_substitution.substituteType(T2_bound);
        if (!T1_bound.acceptWithArgument(this, T2_bound)) {
          return null;
        }
      } else {
        return null;
      }
    }

    return _TypeParametersResult(T1_substitution, T2_substitution);
  }
}

class _TypeParametersResult {
  final Substitution T1_substitution;
  final Substitution T2_substitution;

  _TypeParametersResult(this.T1_substitution, this.T2_substitution);
}
