// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import '../mixins/annotations.dart';
import '../mixins/dartdoc.dart';
import 'code.dart';
import 'expression.dart';
import 'method.dart';
import 'reference.dart';

part 'constructor.g.dart';

@immutable
abstract class Constructor extends Object
    with HasAnnotations, HasDartDocs
    implements Built<Constructor, ConstructorBuilder> {
  factory Constructor([void Function(ConstructorBuilder) updates]) =
      _$Constructor;

  Constructor._();

  @override
  BuiltList<Expression> get annotations;

  @override
  BuiltList<String> get docs;

  /// Optional parameters.
  BuiltList<Parameter> get optionalParameters;

  /// Required parameters.
  BuiltList<Parameter> get requiredParameters;

  /// Constructor initializer statements.
  BuiltList<Code> get initializers;

  /// Body of the method.
  @nullable
  Code get body;

  /// Whether the constructor should be prefixed with `external`.
  bool get external;

  /// Whether the constructor should be prefixed with `const`.
  bool get constant;

  /// Whether this constructor should be prefixed with `factory`.
  bool get factory;

  /// Whether this constructor is a simple lambda expression.
  @nullable
  bool get lambda;

  /// Name of the constructor - optional.
  @nullable
  String get name;

  /// If non-null, redirect to this constructor.
  @nullable
  Reference get redirect;
}

abstract class ConstructorBuilder extends Object
    with HasAnnotationsBuilder, HasDartDocsBuilder
    implements Builder<Constructor, ConstructorBuilder> {
  factory ConstructorBuilder() = _$ConstructorBuilder;

  ConstructorBuilder._();

  @override
  ListBuilder<Expression> annotations = ListBuilder<Expression>();

  @override
  ListBuilder<String> docs = ListBuilder<String>();

  /// Optional parameters.
  ListBuilder<Parameter> optionalParameters = ListBuilder<Parameter>();

  /// Required parameters.
  ListBuilder<Parameter> requiredParameters = ListBuilder<Parameter>();

  /// Constructor initializer statements.
  ListBuilder<Code> initializers = ListBuilder<Code>();

  /// Body of the constructor.
  Code body;

  /// Whether the constructor should be prefixed with `const`.
  bool constant = false;

  /// Whether the constructor should be prefixed with `external`.
  bool external = false;

  /// Whether this constructor should be prefixed with `factory`.
  bool factory = false;

  /// Whether this constructor is a simple lambda expression.
  bool lambda;

  /// Name of the constructor - optional.
  String name;

  /// If non-null, redirect to this constructor.
  @nullable
  Reference redirect;
}
