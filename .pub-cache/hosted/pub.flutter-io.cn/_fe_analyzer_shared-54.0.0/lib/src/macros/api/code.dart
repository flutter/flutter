// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The base class representing an arbitrary chunk of Dart code, which may or
/// may not be syntactically or semantically valid yet.
class Code {
  /// All the chunks of [Code], raw [String]s, or [Identifier]s that
  /// comprise this [Code] object.
  final List<Object> parts;

  /// Can be used to more efficiently detect the kind of code, avoiding is
  /// checks and enabling switch statements.
  CodeKind get kind => CodeKind.raw;

  Code.fromString(String code) : parts = [code];

  Code.fromParts(this.parts)
      : assert(parts.every((element) =>
            element is String || element is Code || element is Identifier));
}

/// A piece of code representing a syntactically valid declaration.
class DeclarationCode extends Code {
  @override
  CodeKind get kind => CodeKind.declaration;

  DeclarationCode.fromString(super.code) : super.fromString();

  DeclarationCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code representing a syntactically valid expression.
class ExpressionCode extends Code {
  @override
  CodeKind get kind => CodeKind.expression;

  ExpressionCode.fromString(super.code) : super.fromString();

  ExpressionCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code representing a syntactically valid function body.
///
/// This includes any and all code after the parameter list of a function,
/// including modifiers like `async`.
///
/// Both arrow and block function bodies are allowed.
class FunctionBodyCode extends Code {
  @override
  CodeKind get kind => CodeKind.functionBody;

  FunctionBodyCode.fromString(super.code) : super.fromString();

  FunctionBodyCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code identifying a syntactically valid function or function type
/// parameter.
///
/// There is no distinction here made between named and positional parameters.
///
/// There is also no distinction between function type parameters and normal
/// function parameters, so the [name] is nullable (it is not required for
/// positional function type parameters).
///
/// It is the job of the user to construct and combine these together in a way
/// that creates valid parameter lists.
class ParameterCode implements Code {
  final Code? defaultValue;
  final List<String> keywords;
  final String? name;
  final TypeAnnotationCode? type;

  @override
  CodeKind get kind => CodeKind.parameter;

  @override
  List<Object> get parts => [
        if (keywords.isNotEmpty) ...[
          ...keywords.joinAsCode(' '),
          ' ',
        ],
        if (type != null) ...[
          type!,
          ' ',
        ],
        if (name != null) name!,
        if (defaultValue != null) ...[
          ' = ',
          defaultValue!,
        ]
      ];

  ParameterCode({
    this.defaultValue,
    this.keywords = const [],
    this.name,
    this.type,
  });
}

/// A piece of code representing a type annotation.
abstract class TypeAnnotationCode implements Code, TypeAnnotation {
  @override
  TypeAnnotationCode get code => this;

  /// Returns a [TypeAnnotationCode] object which is a non-nullable version
  /// of this one.
  ///
  /// Returns the current instance if it is already non-nullable.
  TypeAnnotationCode get asNonNullable => this;

  /// Returns a [TypeAnnotationCode] object which is a non-nullable version
  /// of this one.
  ///
  /// Returns the current instance if it is already nullable.
  NullableTypeAnnotationCode get asNullable =>
      new NullableTypeAnnotationCode(this);

  /// Whether or not this type is nullable.
  @override
  bool get isNullable => false;
}

/// The nullable version of an underlying type annotation.
class NullableTypeAnnotationCode implements TypeAnnotationCode {
  /// The underlying type that is being made nullable.
  TypeAnnotationCode underlyingType;

  @override
  TypeAnnotationCode get code => this;

  @override
  CodeKind get kind => CodeKind.nullableTypeAnnotation;

  @override
  List<Object> get parts => [...underlyingType.parts, '?'];

  /// Creates a nullable [underlyingType] annotation.
  ///
  /// If [underlyingType] is a NullableTypeAnnotationCode, returns that
  /// same type.
  NullableTypeAnnotationCode(this.underlyingType);

  @override
  TypeAnnotationCode get asNonNullable => underlyingType;

  @override
  NullableTypeAnnotationCode get asNullable => this;

  @override
  bool get isNullable => true;
}

/// A piece of code representing a reference to a named type.
class NamedTypeAnnotationCode extends TypeAnnotationCode {
  final Identifier name;

  final List<TypeAnnotationCode> typeArguments;

  @override
  CodeKind get kind => CodeKind.namedTypeAnnotation;

  @override
  List<Object> get parts => [
        name,
        if (typeArguments.isNotEmpty) ...[
          '<',
          ...typeArguments.joinAsCode(', '),
          '>',
        ],
      ];

  NamedTypeAnnotationCode({required this.name, this.typeArguments = const []});
}

/// A piece of code representing a function type annotation.
class FunctionTypeAnnotationCode extends TypeAnnotationCode {
  final List<ParameterCode> namedParameters;

  final List<ParameterCode> positionalParameters;

  final TypeAnnotationCode? returnType;

  final List<TypeParameterCode> typeParameters;

  @override
  CodeKind get kind => CodeKind.functionTypeAnnotation;

  @override
  List<Object> get parts => [
        if (returnType != null) returnType!,
        ' Function',
        if (typeParameters.isNotEmpty) ...[
          '<',
          ...typeParameters.joinAsCode(', '),
          '>',
        ],
        '(',
        for (ParameterCode positional in positionalParameters) ...[
          positional,
          ', ',
        ],
        if (namedParameters.isNotEmpty) ...[
          '{',
          for (ParameterCode named in namedParameters) ...[
            named,
            ', ',
          ],
          '}',
        ],
        ')',
      ];

  FunctionTypeAnnotationCode({
    this.namedParameters = const [],
    this.positionalParameters = const [],
    this.returnType,
    this.typeParameters = const [],
  });
}

class OmittedTypeAnnotationCode extends TypeAnnotationCode {
  final OmittedTypeAnnotation typeAnnotation;

  OmittedTypeAnnotationCode(this.typeAnnotation);

  @override
  CodeKind get kind => CodeKind.omittedTypeAnnotation;

  @override
  List<Object> get parts => [typeAnnotation];
}

/// A piece of code representing a valid named type parameter.
class TypeParameterCode implements Code {
  final TypeAnnotationCode? bound;
  final String name;

  @override
  CodeKind get kind => CodeKind.typeParameter;

  @override
  List<Object> get parts => [
        name,
        if (bound != null) ...[
          ' extends ',
          bound!,
        ]
      ];

  TypeParameterCode({this.bound, required this.name});
}

extension Join<T extends Object> on List<T> {
  /// Joins all the items in [this] with [separator], and returns
  /// a new list.
  List<Object> joinAsCode(String separator) => [
        for (int i = 0; i < length - 1; i++) ...[
          this[i],
          separator,
        ],
        if (isNotEmpty) last,
      ];
}

enum CodeKind {
  declaration,
  expression,
  functionBody,
  functionTypeAnnotation,
  namedTypeAnnotation,
  nullableTypeAnnotation,
  omittedTypeAnnotation,
  parameter,
  raw,
  typeParameter,
}
