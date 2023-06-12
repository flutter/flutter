// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_builder.src.specs.reference;

import 'package:built_value/built_value.dart';
import 'package:meta/meta.dart';

import '../base.dart';
import '../visitors.dart';
import 'code.dart';
import 'expression.dart';
import 'type_reference.dart';

/// Short-hand for `Reference(symbol, url)`.
Reference refer(String symbol, [String url]) => Reference(symbol, url);

/// A reference to [symbol], such as a class, or top-level method or field.
///
/// References can be collected and collated in order to automatically generate
/// `import` statements for all used symbols.
@immutable
class Reference extends Expression implements Spec {
  /// Relative, `package:` or `dart:` URL of the library.
  ///
  /// May be omitted (`null`) in order to express "same library".
  final String url;

  /// Name of the class, method, or field.
  final String symbol;

  /// Create a reference to [symbol] in [url].
  const Reference(this.symbol, [this.url]);

  @override
  R accept<R>(
    SpecVisitor<R> visitor, [
    R context,
  ]) =>
      visitor.visitReference(this, context);

  @override
  int get hashCode => '$url#$symbol'.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Reference && other.url == url && other.symbol == symbol;

  /// Returns a new instance of this expression.
  Expression newInstance(
    Iterable<Expression> positionalArguments, [
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const [],
  ]) =>
      InvokeExpression.newOf(
        this,
        positionalArguments.toList(),
        namedArguments,
        typeArguments,
      );

  /// Returns a new instance of this expression with a named constructor.
  Expression newInstanceNamed(
    String name,
    Iterable<Expression> positionalArguments, [
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const [],
  ]) =>
      InvokeExpression.newOf(
        this,
        positionalArguments.toList(),
        namedArguments,
        typeArguments,
        name,
      );

  /// Returns a const instance of this expression.
  Expression constInstance(
    Iterable<Expression> positionalArguments, [
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const [],
  ]) =>
      InvokeExpression.constOf(
        this,
        positionalArguments.toList(),
        namedArguments,
        typeArguments,
      );

  /// Returns a const instance of this expression with a named constructor.
  Expression constInstanceNamed(
    String name,
    Iterable<Expression> positionalArguments, [
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const [],
  ]) =>
      InvokeExpression.constOf(
        this,
        positionalArguments.toList(),
        namedArguments,
        typeArguments,
        name,
      );

  @override
  Expression get expression => CodeExpression(Code.scope((a) => a(this)));

  @override
  String toString() => (newBuiltValueToStringHelper('Reference')
        ..add('url', url)
        ..add('symbol', symbol))
      .toString();

  /// Returns as a [TypeReference], which allows adding generic type parameters.
  Reference get type => TypeReference((b) => b
    ..url = url
    ..symbol = symbol);
}
