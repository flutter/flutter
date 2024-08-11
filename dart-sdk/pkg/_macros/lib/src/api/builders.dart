// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The base interface used to add declarations to the program as well
/// as augment existing ones.
///
/// Can also be used to emit diagnostic messages back to the parent tool.
abstract interface class Builder {
  /// Attaches [diagnostic] to the result of this macro application phase.
  ///
  /// Note that this will not immediately send the result, these will all be
  /// collected and reported at once when the macro completes this phase.
  void report(Diagnostic diagnostic);
}

/// The interface for all introspection that is allowed during the type phase
/// (and later).
abstract interface class TypePhaseIntrospector {
  /// Returns an [Identifier] for a top level [name] in [library].
  ///
  /// You should only do this for libraries that are definitely in the
  /// transitive import graph of the library you are generating code into. If
  /// [library] is not in this transitive import graph, then an unspecified
  /// [Exception] should be thrown. The best way to ensure this, is to have the
  /// macro library itself import [library] (even if it doesn't directly use
  /// it).
  ///
  /// When the name alone is not sufficient to disambiguate between multiple
  /// declarations, such as the case of a field (which has a synthetic getter),
  /// an [Identifier] pointing to the non-synthetic declaration will be
  /// returned. Future calls to `declarationOf(identifier)` will return that
  /// non-synthetic declaration.
  ///
  /// If [name] does not exist in [library], then an unspecified [Exception]
  /// should be thrown.
  @Deprecated(
      'This API should eventually be replaced with a different, safer API.')
  Future<Identifier> resolveIdentifier(Uri library, String name);
}

/// The API used by [Macro]s to contribute new type declarations to the
/// current library, and get [TypeAnnotation]s from runtime [Type] objects.
abstract interface class TypeBuilder implements Builder, TypePhaseIntrospector {
  /// Adds a new type declaration to the surrounding library.
  ///
  /// The [name] must match the name of the new [typeDeclaration] (this does
  /// not include any type parameters, just the name).
  void declareType(String name, DeclarationCode typeDeclaration);
}

/// The API used by macros in the type phase to add interfaces to an existing
/// type.
abstract interface class InterfaceTypesBuilder implements TypeBuilder {
  /// Appends [interfaces] to the list of interfaces for this type.
  void appendInterfaces(Iterable<TypeAnnotationCode> interfaces);
}

/// The API used by macros in the type phase to add mixins to an existing
/// type.
abstract interface class MixinTypesBuilder implements TypeBuilder {
  /// Appends [mixins] to the list of mixins for this type.
  void appendMixins(Iterable<TypeAnnotationCode> mixins);
}

/// The API used by macros in the type phase to add an extends clause to an
/// existing type.
abstract interface class ExtendsTypeBuilder implements TypeBuilder {
  /// Sets the `extends` clause to [superclass].
  ///
  /// The type must not already have an `extends` clause.
  void extendsType(NamedTypeAnnotationCode superclass);
}

/// The API used by macros in the type phase to augment classes.
abstract interface class ClassTypeBuilder
    implements
        TypeBuilder,
        ExtendsTypeBuilder,
        InterfaceTypesBuilder,
        MixinTypesBuilder {}

/// The API used by macros in the type phase to augment enums.
abstract interface class EnumTypeBuilder
    implements TypeBuilder, InterfaceTypesBuilder, MixinTypesBuilder {}

/// The API used by macros in the type phase to augment mixins.
///
/// Note that mixins don't support mixins, only interfaces.
abstract interface class MixinTypeBuilder
    implements TypeBuilder, InterfaceTypesBuilder {}

/// The interface for all introspection that is allowed during the declaration
/// phase (and later).
abstract interface class DeclarationPhaseIntrospector
    implements TypePhaseIntrospector {
  /// Instantiates a new [StaticType] for a given [type] annotation.
  ///
  /// Throws if [type] is a [RawTypeAnnotationCode], more specific subtypes must
  /// be used, as raw [Identifier]s are not allowed.
  ///
  /// Throws an error if the [type] object contains [Identifier]s which cannot
  /// be resolved. This should only happen in the case of incomplete or invalid
  /// programs, but macros may be asked to run in this state during the
  /// development cycle. It may be helpful for users if macros provide a best
  /// effort implementation in that case or handle the error in a useful way.
  Future<StaticType> resolve(TypeAnnotationCode type);

  /// The values available for [enuum].
  ///
  /// This may be incomplete if additional declaration macros are going to run
  /// on [enuum].
  Future<List<EnumValueDeclaration>> valuesOf(covariant EnumDeclaration enuum);

  /// The fields available for [type].
  ///
  /// This may be incomplete if additional declaration macros are going to run
  /// on [type].
  Future<List<FieldDeclaration>> fieldsOf(covariant TypeDeclaration type);

  /// The methods available for [type].
  ///
  /// This may be incomplete if additional declaration macros are going to run
  /// on [type].
  Future<List<MethodDeclaration>> methodsOf(covariant TypeDeclaration type);

  /// The constructors available for [type].
  ///
  /// This may be incomplete if additional declaration macros are going to run
  /// on [type].
  Future<List<ConstructorDeclaration>> constructorsOf(
      covariant TypeDeclaration type);

  /// [TypeDeclaration]s for all the types declared in [library].
  ///
  /// Note that this includes [ExtensionDeclaration]s as well, even though they
  /// do not actually introduce a new type.
  Future<List<TypeDeclaration>> typesOf(covariant Library library);

  /// Resolves an [identifier] to its [TypeDeclaration].
  ///
  /// If [identifier] does not resolve to a [TypeDeclaration], then a
  /// [MacroImplementationException] is thrown.
  Future<TypeDeclaration> typeDeclarationOf(covariant Identifier identifier);
}

/// The API used by [Macro]s to contribute new (non-type)
/// declarations to the current library.
///
/// Can also be used to do subtype checks on types.
abstract interface class DeclarationBuilder
    implements Builder, DeclarationPhaseIntrospector {
  /// Adds a new regular declaration to the surrounding library.
  ///
  /// Note that type declarations are not supported.
  void declareInLibrary(DeclarationCode declaration);
}

/// The API used by [Macro]s to contribute new members to a type.
abstract interface class MemberDeclarationBuilder
    implements DeclarationBuilder {
  /// Adds a new declaration to the surrounding class.
  void declareInType(DeclarationCode declaration);
}

/// The API used by [Macro]s to contribute new members or values to an enum.
abstract interface class EnumDeclarationBuilder
    implements MemberDeclarationBuilder {
  /// Adds a new enum entry declaration to the surrounding enum.
  void declareEnumValue(DeclarationCode declaration);
}

/// The interface for all introspection that is allowed during the definition
/// phase (and later).
abstract interface class DefinitionPhaseIntrospector
    implements DeclarationPhaseIntrospector {
  /// Resolves any [identifier] to its [Declaration].
  Future<Declaration> declarationOf(covariant Identifier identifier);

  /// Resolves an [identifier] referring to a type to its [TypeDeclaration].
  @override
  Future<TypeDeclaration> typeDeclarationOf(covariant Identifier identifier);

  /// Infers a real type annotation for [omittedType].
  ///
  /// If no type could be inferred, then a type annotation representing the
  /// dynamic type will be given.
  Future<TypeAnnotation> inferType(covariant OmittedTypeAnnotation omittedType);

  /// Returns a list of all the [Declaration]s in the given [library].
  Future<List<Declaration>> topLevelDeclarationsOf(covariant Library library);
}

/// The base class for builders in the definition phase. These can convert
/// any [TypeAnnotation] into its corresponding [TypeDeclaration], and also
/// reflect more deeply on those.
abstract interface class DefinitionBuilder
    implements Builder, DefinitionPhaseIntrospector {}

/// The APIs used by [Macro]s that run on library directives, to fill in the
/// definitions of any declarations within that library.
abstract interface class LibraryDefinitionBuilder implements DefinitionBuilder {
  /// Retrieve a [TypeDefinitionBuilder] for a type declaration with
  /// [identifier].
  ///
  /// Throws a [MacroImplementationException] if [identifier] does not refer to
  /// a type declaration in this library.
  Future<TypeDefinitionBuilder> buildType(Identifier identifier);

  /// Retrieve a [FunctionDefinitionBuilder] for a function declaration with
  /// [identifier].
  ///
  /// Throws a [MacroImplementationException] if [identifier] does not refer to
  /// a top level function declaration in this library.
  Future<FunctionDefinitionBuilder> buildFunction(Identifier identifier);

  /// Retrieve a [VariableDefinitionBuilder] for a variable declaration with
  /// [identifier].
  ///
  /// Throws a [MacroImplementationException] if [identifier] does not refer to
  /// a top level variable declaration in this library.
  Future<VariableDefinitionBuilder> buildVariable(Identifier identifier);
}

/// The APIs used by [Macro]s that run on type declarations, to fill in the
/// definitions of any declarations within that class.
abstract interface class TypeDefinitionBuilder implements DefinitionBuilder {
  /// Retrieve a [VariableDefinitionBuilder] for a field with [identifier].
  ///
  /// Throws a [MacroImplementationException] if [identifier] does not refer to
  /// a field in this class.
  Future<VariableDefinitionBuilder> buildField(Identifier identifier);

  /// Retrieve a [FunctionDefinitionBuilder] for a method with [identifier].
  ///
  /// Throws a [MacroImplementationException] if [identifier] does not refer to
  /// a method in this class.
  Future<FunctionDefinitionBuilder> buildMethod(Identifier identifier);

  /// Retrieve a [ConstructorDefinitionBuilder] for a constructor with
  /// [identifier].
  ///
  /// Throws a [MacroImplementationException] if [identifier] does not refer to
  /// a constructor in this class.
  Future<ConstructorDefinitionBuilder> buildConstructor(Identifier identifier);
}

/// The APIs used by [Macro]s that run on enums, to fill in the
/// definitions of any declarations within that enum.
abstract interface class EnumDefinitionBuilder
    implements TypeDefinitionBuilder {
  /// Retrieve an [EnumValueDefinitionBuilder] for an entry with [identifier].
  ///
  /// Throws a [MacroImplementationException] if [identifier] does not refer to
  /// an entry on this enum.
  Future<EnumValueDefinitionBuilder> buildEnumValue(Identifier identifier);
}

/// The APIs used by [Macro]s to define the body of a constructor
/// or wrap the body of an existing constructor with additional statements.
abstract interface class ConstructorDefinitionBuilder
    implements DefinitionBuilder {
  /// Augments an existing constructor body with [body] and [initializers].
  ///
  /// The [initializers] should not contain trailing or preceding commas.
  ///
  /// If [docComments] are supplied, they will be added above this augment
  /// declaration.
  ///
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment({
    FunctionBodyCode? body,
    List<Code>? initializers,
    CommentCode? docComments,
  });
}

/// The APIs used by [Macro]s to augment functions or methods.
abstract interface class FunctionDefinitionBuilder
    implements DefinitionBuilder {
  /// Augments the function.
  ///
  /// If [docComments] are supplied, they will be added above this augment
  /// declaration.
  ///
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment(
    FunctionBodyCode body, {
    CommentCode? docComments,
  });
}

/// The API used by [Macro]s to augment a top level variable or instance field.
abstract interface class VariableDefinitionBuilder
    implements DefinitionBuilder {
  /// Augments the field.
  ///
  /// For [getter] and [setter] the full function declaration should be
  /// provided, minus the `augment` keyword (which will be implicitly added).
  ///
  /// If [initializerDocComments] are supplied, they will be added above the
  /// augment declaration for [initializer]. It is an error to provide
  /// [initializerDocComments] but not [initializer].
  ///
  /// To provide doc comments for [getter] or [setter], just include them in
  /// the [DeclarationCode] object for those.
  ///
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment({
    DeclarationCode? getter,
    DeclarationCode? setter,
    ExpressionCode? initializer,
    CommentCode? initializerDocComments,
  });
}

/// The API used by [Macro]s to augment an enum entry.
abstract interface class EnumValueDefinitionBuilder
    implements DefinitionBuilder {
  /// Augments the entry by replacing it with a new one.
  ///
  /// The name of the produced [entry] must match the original name.
  void augment(DeclarationCode entry);
}
