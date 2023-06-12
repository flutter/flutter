// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import '../base.dart';
import '../mixins/generics.dart';
import '../visitors.dart';
import 'code.dart';
import 'expression.dart';
import 'reference.dart';

part 'type_function.g.dart';

@immutable
abstract class FunctionType extends Expression
    with HasGenerics
    implements Built<FunctionType, FunctionTypeBuilder>, Reference, Spec {
  factory FunctionType([
    void Function(FunctionTypeBuilder) updates,
  ]) = _$FunctionType;

  FunctionType._();

  @override
  R accept<R>(
    SpecVisitor<R> visitor, [
    R context,
  ]) =>
      visitor.visitFunctionType(this, context);

  /// Return type.
  @nullable
  Reference get returnType;

  @override
  BuiltList<Reference> get types;

  /// Required positional arguments to this function type.
  BuiltList<Reference> get requiredParameters;

  /// Optional positional arguments to this function type.
  BuiltList<Reference> get optionalParameters;

  /// Named optional arguments to this function type.
  BuiltMap<String, Reference> get namedParameters;

  @override
  String get url => null;

  @override
  String get symbol => null;

  @override
  Reference get type => this;

  /// Optional nullability.
  ///
  /// An emitter may ignore this if the output is not targeting a Dart language
  /// version that supports null safety.
  @nullable
  bool get isNullable;

  @override
  Expression newInstance(
    Iterable<Expression> positionalArguments, [
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const [],
  ]) =>
      throw UnsupportedError('Cannot instantiate a function type.');

  @override
  Expression newInstanceNamed(
    String name,
    Iterable<Expression> positionalArguments, [
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const [],
  ]) =>
      throw UnsupportedError('Cannot instantiate a function type.');

  @override
  Expression constInstance(
    Iterable<Expression> positionalArguments, [
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const [],
  ]) =>
      throw UnsupportedError('Cannot "const" a function type.');

  @override
  Expression constInstanceNamed(
    String name,
    Iterable<Expression> positionalArguments, [
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const [],
  ]) =>
      throw UnsupportedError('Cannot "const" a function type.');

  /// A typedef assignment to this type.
  Code toTypeDef(String name) => createTypeDef(name, this);
}

abstract class FunctionTypeBuilder extends Object
    with HasGenericsBuilder
    implements Builder<FunctionType, FunctionTypeBuilder> {
  factory FunctionTypeBuilder() = _$FunctionTypeBuilder;

  FunctionTypeBuilder._();

  Reference returnType;

  @override
  ListBuilder<Reference> types = ListBuilder<Reference>();

  ListBuilder<Reference> requiredParameters = ListBuilder<Reference>();

  ListBuilder<Reference> optionalParameters = ListBuilder<Reference>();

  MapBuilder<String, Reference> namedParameters =
      MapBuilder<String, Reference>();

  bool isNullable;
}
