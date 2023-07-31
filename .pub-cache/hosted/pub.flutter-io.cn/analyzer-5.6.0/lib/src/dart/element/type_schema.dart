// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';

/// A type that is being inferred but is not currently known.
///
/// This type will only appear in a downward inference context for type
/// parameters that we do not know yet. Notationally it is written `_`, for
/// example `List<_>`. This is distinct from `List<dynamic>`. These types will
/// never appear in the final resolved AST.
class UnknownInferredType extends TypeImpl {
  static final UnknownInferredType instance = UnknownInferredType._();

  UnknownInferredType._();

  @override
  Element? get element => null;

  @Deprecated('Use element instead')
  @override
  Element? get element2 => element;

  @override
  int get hashCode => 1;

  @override
  bool get isDynamic => true;

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => Keyword.DYNAMIC.lexeme;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.star;

  @override
  bool operator ==(Object other) => identical(other, this);

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    if (visitor is InferenceTypeVisitor<R>) {
      var visitor2 = visitor as InferenceTypeVisitor<R>;
      return visitor2.visitUnknownInferredType(this);
    } else {
      throw StateError('Should not happen outside inference.');
    }
  }

  @override
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
    if (visitor is InferenceTypeVisitor1<R, A>) {
      var visitor2 = visitor as InferenceTypeVisitor1<R, A>;
      return visitor2.visitUnknownInferredType(this, argument);
    } else {
      throw StateError('Should not happen outside inference.');
    }
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeUnknownInferredType();
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) => this;

  /// Given a [type] T, return true if it does not have an unknown type `_`.
  static bool isKnown(DartType type) => !isUnknown(type);

  /// Given a [type] T, return true if it has an unknown type `_`.
  static bool isUnknown(DartType type) {
    if (identical(type, UnknownInferredType.instance)) {
      return true;
    }
    if (type is InterfaceTypeImpl) {
      return type.typeArguments.any(isUnknown);
    }
    if (type is FunctionType) {
      return isUnknown(type.returnType) ||
          type.parameters.any((p) => isUnknown(p.type));
    }
    return false;
  }
}
