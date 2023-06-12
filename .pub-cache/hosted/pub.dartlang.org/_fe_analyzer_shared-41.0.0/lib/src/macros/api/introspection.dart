// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// A concrete reference to a named declaration, which may or may not yet be
/// resolved.
///
/// These can be passed directly to [Code] objects, which will automatically do
/// any necessary prefixing when emitting references.
///
/// Concrete implementations should override `==` so that identifiers can be
/// reliably compared against each other.
abstract class Identifier {
  String get name;
}

/// The base class for an unresolved reference to a type.
///
/// See the subtypes [FunctionTypeAnnotation] and [NamedTypeAnnotation].
abstract class TypeAnnotation {
  /// Whether or not the type annotation is explicitly nullable (contains a
  /// trailing `?`)
  bool get isNullable;

  /// A convenience method to get a [Code] object equivalent to this type
  /// annotation.
  TypeAnnotationCode get code;
}

/// The base class for function type declarations.
abstract class FunctionTypeAnnotation implements TypeAnnotation {
  /// The return type of this function.
  TypeAnnotation get returnType;

  /// The positional parameters for this function.
  Iterable<FunctionTypeParameter> get positionalParameters;

  /// The named parameters for this function.
  Iterable<FunctionTypeParameter> get namedParameters;

  /// The type parameters for this function.
  Iterable<TypeParameterDeclaration> get typeParameters;
}

/// An unresolved reference to a type.
///
/// These can be resolved to a [TypeDeclaration] using the `builder` classes
/// depending on the phase a macro is running in.
abstract class NamedTypeAnnotation implements TypeAnnotation {
  /// An identifier pointing to this named type.
  Identifier get identifier;

  /// The type arguments, if applicable.
  Iterable<TypeAnnotation> get typeArguments;
}

/// An omitted type annotation.
///
/// This will be given whenever there is no explicit type annotation for a
/// declaration.
///
/// These type annotations can still produce valid [Code] objects, which will
/// result in the inferred type being emitted into the resulting code (or
/// dynamic).
///
/// In the definition phase, you may also ask explicitly for the inferred type
/// using the `inferType` API.
abstract class OmittedTypeAnnotation implements TypeAnnotation {}

/// The interface representing a resolved type.
///
/// Resolved types understand exactly what type they represent, and can be
/// compared to other static types.
abstract class StaticType {
  /// Returns true if this is a subtype of [other].
  Future<bool> isSubtypeOf(covariant StaticType other);

  /// Returns true if this is an identical type to [other].
  Future<bool> isExactly(covariant StaticType other);
}

/// A subtype of [StaticType] representing types that can be resolved by name
/// to a concrete declaration.
abstract class NamedStaticType implements StaticType {}

/// The base class for all declarations.
abstract class Declaration {
  ///  An identifier pointing to this named declaration.
  Identifier get identifier;
}

/// Base class for all Declarations which have a surrounding class.
abstract class ClassMemberDeclaration implements Declaration {
  /// The class that defines this method.
  Identifier get definingClass;

  /// Whether or not this is a static member.
  bool get isStatic;
}

/// Marker interface for a declaration that defines a new type in the program.
///
/// See [ParameterizedTypeDeclaration] and [TypeParameterDeclaration].
abstract class TypeDeclaration implements Declaration {}

/// A [TypeDeclaration] which may have type parameters.
///
/// See subtypes [ClassDeclaration] and [TypeAliasDeclaration].
abstract class ParameterizedTypeDeclaration implements TypeDeclaration {
  /// The type parameters defined for this type declaration.
  Iterable<TypeParameterDeclaration> get typeParameters;
}

/// A marker interface for the type declarations which are introspectable.
///
/// All type declarations which can have members will have a variant which
/// implements this type.
mixin IntrospectableType implements TypeDeclaration {}

/// Class (and enum) introspection information.
///
/// Information about fields, methods, and constructors must be retrieved from
/// the `builder` objects.
abstract class ClassDeclaration implements ParameterizedTypeDeclaration {
  /// Whether this class has an `abstract` modifier.
  bool get isAbstract;

  /// Whether this class has an `external` modifier.
  bool get isExternal;

  /// The `extends` type annotation, if present.
  NamedTypeAnnotation? get superclass;

  /// All the `implements` type annotations.
  Iterable<NamedTypeAnnotation> get interfaces;

  /// All the `with` type annotations.
  Iterable<NamedTypeAnnotation> get mixins;

  /// All the type arguments, if applicable.
  Iterable<TypeParameterDeclaration> get typeParameters;
}

/// An introspectable class declaration.
abstract class IntrospectableClassDeclaration
    implements ClassDeclaration, IntrospectableType {}

/// Type alias introspection information.
abstract class TypeAliasDeclaration implements ParameterizedTypeDeclaration {
  /// The type annotation this is an alias for.
  TypeAnnotation get aliasedType;
}

/// Function introspection information.
abstract class FunctionDeclaration implements Declaration {
  /// Whether this function has an `abstract` modifier.
  bool get isAbstract;

  /// Whether this function has an `external` modifier.
  bool get isExternal;

  /// Whether this function is an operator.
  bool get isOperator;

  /// Whether this function is actually a getter.
  bool get isGetter;

  /// Whether this function is actually a setter.
  bool get isSetter;

  /// The return type of this function.
  TypeAnnotation get returnType;

  /// The positional parameters for this function.
  Iterable<ParameterDeclaration> get positionalParameters;

  /// The named parameters for this function.
  Iterable<ParameterDeclaration> get namedParameters;

  /// The type parameters for this function.
  Iterable<TypeParameterDeclaration> get typeParameters;
}

/// Method introspection information.
abstract class MethodDeclaration
    implements FunctionDeclaration, ClassMemberDeclaration {}

/// Constructor introspection information.
abstract class ConstructorDeclaration implements MethodDeclaration {
  /// Whether or not this is a factory constructor.
  bool get isFactory;
}

/// Variable introspection information.
abstract class VariableDeclaration implements Declaration {
  /// Whether this field has an `external` modifier.
  bool get isExternal;

  /// Whether this field has a `final` modifier.
  bool get isFinal;

  /// Whether this field has a `late` modifier.
  bool get isLate;

  /// The type of this field.
  TypeAnnotation get type;
}

/// Field introspection information.
abstract class FieldDeclaration
    implements VariableDeclaration, ClassMemberDeclaration {}

/// General parameter introspection information, see the subtypes
/// [FunctionTypeParameter] and [ParameterDeclaration].
abstract class Parameter {
  /// The type of this parameter.
  TypeAnnotation get type;

  /// Whether or not this is a named parameter.
  bool get isNamed;

  /// Whether or not this parameter is either a non-optional positional
  /// parameter or an optional parameter with the `required` keyword.
  bool get isRequired;

  /// A convenience method to get a `code` object equivalent to this parameter.
  ///
  /// Note that the original default value will not be included, as it is not a
  /// part of this API.
  ParameterCode get code;
}

/// Parameters of normal functions/methods, which always have an identifier.
abstract class ParameterDeclaration implements Parameter, Declaration {}

/// Function type parameters don't always have names, and it is never useful to
/// get an [Identifier] for them, so they do not implement [Declaration] and
/// instead have an optional name.
abstract class FunctionTypeParameter implements Parameter {
  String? get name;
}

/// Generic type parameter introspection information.
abstract class TypeParameterDeclaration implements TypeDeclaration {
  /// The bound for this type parameter, if it has any.
  TypeAnnotation? get bound;

  /// A convenience method to get a `code` object equivalent to this type
  /// parameter.
  TypeParameterCode get code;
}
