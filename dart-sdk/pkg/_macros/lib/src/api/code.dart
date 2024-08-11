// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The base class representing an arbitrary chunk of Dart code, which may or
/// may not be syntactically or semantically valid yet.
sealed class Code {
  /// All the chunks of [Code], raw [String]s, [Identifier]s, or
  /// [OmittedTypeAnnotation]s that comprise this [Code] object.
  ///
  /// Note that [OmittedTypeAnnotation] objects can only be provided through
  /// the [OmittedTypeAnnotationCode] wrapper instance, but will appear in
  /// the [parts] of those, so they must be handled whenever iterating [parts].
  final List<Object> parts;

  /// Can be used to more efficiently detect the kind of code, avoiding is
  /// checks and enabling switch statements.
  CodeKind get kind;

  Code.fromString(String code) : parts = [code];

  Code.fromParts(this.parts) {
    for (final part in parts) {
      switch (part) {
        case Code():
        case Identifier():
        case String():
          break; // OK
        default:
          throw StateError('Unrecognized code part ${part.runtimeType}');
      }
    }
  }
}

/// An arbitrary chunk of code, which does not have to be syntactically valid
/// on its own. Useful to construct other types of code from several parts.
final class RawCode extends Code {
  @override
  CodeKind get kind => CodeKind.raw;

  RawCode.fromString(super.code) : super.fromString();

  RawCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code representing a syntactically valid declaration.
final class DeclarationCode extends Code {
  @override
  CodeKind get kind => CodeKind.declaration;

  DeclarationCode.fromString(super.code) : super.fromString();

  DeclarationCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code representing a code comment. This may contain identifier
/// references inside of `[]` brackets if the comments are doc comments.
final class CommentCode extends Code {
  @override
  CodeKind get kind => CodeKind.comment;

  CommentCode.fromString(super.code) : super.fromString();

  CommentCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code representing a syntactically valid expression.
final class ExpressionCode extends Code {
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
final class FunctionBodyCode extends Code {
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
final class ParameterCode implements Code {
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
sealed class TypeAnnotationCode implements Code, TypeAnnotation {
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
  NullableTypeAnnotationCode get asNullable => NullableTypeAnnotationCode(this);

  /// Whether or not this type is nullable.
  @override
  bool get isNullable => false;
}

/// The nullable version of an underlying type annotation.
final class NullableTypeAnnotationCode implements TypeAnnotationCode {
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
final class NamedTypeAnnotationCode extends TypeAnnotationCode {
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
final class FunctionTypeAnnotationCode extends TypeAnnotationCode {
  final List<ParameterCode> namedParameters;

  final List<ParameterCode> optionalPositionalParameters;

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
        if (optionalPositionalParameters.isNotEmpty) ...[
          '[',
          for (ParameterCode optional in optionalPositionalParameters) ...[
            optional,
            ', ',
          ],
          ']',
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
    this.optionalPositionalParameters = const [],
    this.positionalParameters = const [],
    this.returnType,
    this.typeParameters = const [],
  });
}

/// A piece of code identifying a syntactically valid record field declaration.
/// This is only usable in the context of [RecordTypeAnnotationCode] objects.
///
/// There is no distinction here made between named and positional fields.
///
/// The name is not required because it is optional for positional fields.
///
/// It is the job of the user to construct and combine these together in a way
/// that creates valid record type annotations.
final class RecordFieldCode implements Code {
  final String? name;
  final TypeAnnotationCode type;

  @override
  CodeKind get kind => CodeKind.recordField;

  @override
  List<Object> get parts => [
        type,
        if (name != null) ' ${name!}',
      ];

  RecordFieldCode({
    this.name,
    required this.type,
  });
}

/// A piece of code representing a syntactically valid record type annotation.
final class RecordTypeAnnotationCode extends TypeAnnotationCode {
  final List<RecordFieldCode> namedFields;

  final List<RecordFieldCode> positionalFields;

  @override
  CodeKind get kind => CodeKind.recordTypeAnnotation;

  @override
  List<Object> get parts => [
        '(',
        if (positionalFields.isNotEmpty)
          for (RecordFieldCode positional in positionalFields) ...[
            if (positional != positionalFields.first) ', ',
            positional,
          ],
        if (namedFields.isNotEmpty) ...[
          if (positionalFields.isNotEmpty) ', ',
          '{',
          for (RecordFieldCode named in namedFields) ...[
            if (named != namedFields.first) ', ',
            named,
          ],
          '}',
        ],
        ')',
      ];

  RecordTypeAnnotationCode({
    this.namedFields = const [],
    this.positionalFields = const [],
  });
}

final class OmittedTypeAnnotationCode extends TypeAnnotationCode {
  final OmittedTypeAnnotation typeAnnotation;

  OmittedTypeAnnotationCode(this.typeAnnotation);

  @override
  CodeKind get kind => CodeKind.omittedTypeAnnotation;

  @override
  List<Object> get parts => [typeAnnotation];
}

/// Raw type annotations are typically used to refer to a local type which you
/// do not have an [Identifier] for (possibly you just created it).
///
/// Whenever possible, use a more specific [TypeAnnotationCode] subtype.
final class RawTypeAnnotationCode extends RawCode
    implements TypeAnnotationCode {
  @override
  CodeKind get kind => CodeKind.rawTypeAnnotation;

  /// Returns a [TypeAnnotationCode] object which is a non-nullable version
  /// of this one.
  ///
  /// Returns the current instance if it is already non-nullable.
  @override
  TypeAnnotationCode get asNonNullable => this;

  /// Returns a [TypeAnnotationCode] object which is a non-nullable version
  /// of this one.
  ///
  /// Returns the current instance if it is already nullable.
  @override
  NullableTypeAnnotationCode get asNullable => NullableTypeAnnotationCode(this);

  RawTypeAnnotationCode._(super.parts) : super.fromParts();

  /// Creates a [TypeAnnotationCode] from a raw [String].
  ///
  /// The [code] object must not have trailing whitespace.
  static TypeAnnotationCode fromString(String code) => fromParts([code]);

  /// Creates a [TypeAnnotationCode] from a raw code [parts].
  ///
  /// Must not end in trailing whitespace.
  static TypeAnnotationCode fromParts(List<Object> parts) {
    bool wasNullable;
    (wasNullable, parts) = _makeNonNullable(parts);
    TypeAnnotationCode code = RawTypeAnnotationCode._(parts);
    if (wasNullable) code = code.asNullable;
    return code;
  }

  @override
  TypeAnnotationCode get code => this;

  @override
  bool get isNullable => false;

  /// Checks if [parts] ends with a ?, and if so then it is removed.
  ///
  /// Returns a record which indicates if [parts] was nullable originally, as
  /// well as the potentially new list of parts.
  ///
  /// Throws if [parts] ends with whitespace because we don't allow type
  /// annotations to do that.
  static (bool wasNullable, List<Object> parts) _makeNonNullable(
      List<Object> parts) {
    final Iterator<Object> iterator = parts.reversed.iterator;
    while (iterator.moveNext()) {
      final Object current = iterator.current;
      switch (current) {
        case String():
          if (current.trimRight() != current) {
            throw ArgumentError(
                'Invalid type annotation, type annotations should not end with '
                'whitespace but got `$current`.');
          } else if (current.isEmpty) {
            continue;
          } else if (current.endsWith('?')) {
            // It was nullable, trim the `?` and return a copy.
            return (
              true,
              // We are iterating backwards, and need to reverse it after.
              [
                // Strip the '?'.
                current.substring(0, current.length - 1),
                for (bool hasNext = iterator.moveNext();
                    hasNext;
                    hasNext = iterator.moveNext())
                  iterator.current,
              ].reversed.toList(),
            );
          } else {
            return (false, parts);
          }
        case Identifier():
          // Identifiers never contain a `?`.
          return (false, parts);
      }
    }
    throw ArgumentError('The empty string is not a valid type annotation.');
  }
}

/// A piece of code representing a valid named type parameter.
final class TypeParameterCode implements Code {
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
  /// Joins all the items in this [Join] with [separator], and returns a new
  /// list.
  ///
  /// Works on any kind of non-nullable list which accepts String entries, and
  /// does not convert the individual items to strings.
  List<Object> joinAsCode(String separator) => [
        for (int i = 0; i < length - 1; i++) ...[
          this[i],
          separator,
        ],
        if (isNotEmpty) last,
      ];
}

enum CodeKind {
  comment,
  declaration,
  expression,
  functionBody,
  functionTypeAnnotation,
  namedTypeAnnotation,
  nullableTypeAnnotation,
  omittedTypeAnnotation,
  parameter,
  raw,
  rawTypeAnnotation,
  recordField,
  recordTypeAnnotation,
  typeParameter,
}
