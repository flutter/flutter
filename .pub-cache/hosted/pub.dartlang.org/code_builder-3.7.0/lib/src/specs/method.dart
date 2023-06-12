// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import '../base.dart';
import '../mixins/annotations.dart';
import '../mixins/dartdoc.dart';
import '../mixins/generics.dart';
import '../visitors.dart';
import 'code.dart';
import 'expression.dart';
import 'reference.dart';

part 'method.g.dart';

const _$void = Reference('void');

@immutable
abstract class Method extends Object
    with HasAnnotations, HasGenerics, HasDartDocs
    implements Built<Method, MethodBuilder>, Spec {
  factory Method([void Function(MethodBuilder) updates]) = _$Method;

  factory Method.returnsVoid([void Function(MethodBuilder) updates]) =>
      Method((b) {
        if (updates != null) {
          updates(b);
        }
        b.returns = _$void;
      });

  Method._();

  @override
  BuiltList<Expression> get annotations;

  @override
  BuiltList<String> get docs;

  @override
  BuiltList<Reference> get types;

  /// Optional parameters.
  BuiltList<Parameter> get optionalParameters;

  /// Required parameters.
  BuiltList<Parameter> get requiredParameters;

  /// Body of the method.
  @nullable
  Code get body;

  /// Whether the method should be prefixed with `external`.
  bool get external;

  /// Whether this method is a simple lambda expression.
  ///
  /// May be `null` to be inferred based on the value of [body].
  @nullable
  bool get lambda;

  /// Whether this method should be prefixed with `static`.
  ///
  /// This is only valid within classes.
  bool get static;

  /// Name of the method or function.
  ///
  /// May be `null` when being used as a [closure].
  @nullable
  String get name;

  /// Whether this is a getter or setter.
  @nullable
  MethodType get type;

  /// Whether this method is `async`, `async*`, or `sync*`.
  @nullable
  MethodModifier get modifier;

  @nullable
  Reference get returns;

  @override
  R accept<R>(
    SpecVisitor<R> visitor, [
    R context,
  ]) =>
      visitor.visitMethod(this, context);

  /// This method as a closure.
  Expression get closure => toClosure(this);

  /// This method as a (possibly) generic closure.
  Expression get genericClosure => toGenericClosure(this);
}

abstract class MethodBuilder extends Object
    with HasAnnotationsBuilder, HasGenericsBuilder, HasDartDocsBuilder
    implements Builder<Method, MethodBuilder> {
  factory MethodBuilder() = _$MethodBuilder;

  MethodBuilder._();

  @override
  ListBuilder<Expression> annotations = ListBuilder<Expression>();

  @override
  ListBuilder<String> docs = ListBuilder<String>();

  @override
  ListBuilder<Reference> types = ListBuilder<Reference>();

  /// Optional parameters.
  ListBuilder<Parameter> optionalParameters = ListBuilder<Parameter>();

  /// Required parameters.
  ListBuilder<Parameter> requiredParameters = ListBuilder<Parameter>();

  /// Body of the method.
  Code body;

  /// Whether the method should be prefixed with `external`.
  bool external = false;

  /// Whether this method is a simple lambda expression.
  ///
  /// If not specified this is inferred from the [body].
  bool lambda;

  /// Whether this method should be prefixed with `static`.
  ///
  /// This is only valid within classes.
  bool static = false;

  /// Name of the method or function.
  String name;

  /// Whether this is a getter or setter.
  MethodType type;

  /// Whether this method is `async`, `async*`, or `sync*`.
  MethodModifier modifier;

  Reference returns;
}

enum MethodType {
  getter,
  setter,
}

enum MethodModifier {
  async,
  asyncStar,
  syncStar,
}

abstract class Parameter extends Object
    with HasAnnotations, HasGenerics, HasDartDocs
    implements Built<Parameter, ParameterBuilder> {
  factory Parameter([void Function(ParameterBuilder) updates]) = _$Parameter;

  Parameter._();

  /// If not `null`, a default assignment if the parameter is optional.
  @nullable
  Code get defaultTo;

  /// Name of the parameter.
  String get name;

  /// Whether this parameter should be named, if optional.
  bool get named;

  /// Whether this parameter should be field formal (i.e. `this.`).
  ///
  /// This is only valid on constructors;
  bool get toThis;

  @override
  BuiltList<Expression> get annotations;

  @override
  BuiltList<String> get docs;

  @override
  BuiltList<Reference> get types;

  /// Type of the parameter;
  @nullable
  Reference get type;

  /// Whether this parameter should be annotated with the `required` keyword.
  ///
  /// This is only valid on named parameters.
  ///
  /// This is only valid when the output is targeting a Dart language version
  /// that supports null safety.
  bool get required;

  /// Whether this parameter should be annotated with the `covariant` keyword.
  ///
  /// This is only valid on instance methods.
  bool get covariant;
}

abstract class ParameterBuilder extends Object
    with HasAnnotationsBuilder, HasGenericsBuilder, HasDartDocsBuilder
    implements Builder<Parameter, ParameterBuilder> {
  factory ParameterBuilder() = _$ParameterBuilder;

  ParameterBuilder._();

  /// If not `null`, a default assignment if the parameter is optional.
  Code defaultTo;

  /// Name of the parameter.
  String name;

  /// Whether this parameter should be named, if optional.
  bool named = false;

  /// Whether this parameter should be field formal (i.e. `this.`).
  ///
  /// This is only valid on constructors;
  bool toThis = false;

  @override
  ListBuilder<Expression> annotations = ListBuilder<Expression>();

  @override
  ListBuilder<String> docs = ListBuilder<String>();

  @override
  ListBuilder<Reference> types = ListBuilder<Reference>();

  /// Type of the parameter;
  Reference type;

  /// Whether this parameter should be annotated with the `required` keyword.
  ///
  /// This is only valid on named parameters.
  ///
  /// This is only valid when the output is targeting a Dart language version
  /// that supports null safety.
  bool required = false;

  /// Whether this parameter should be annotated with the `covariant` keyword.
  ///
  /// This is only valid on instance methods.
  bool covariant = false;
}
