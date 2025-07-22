// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'executor/serialization_extensions.dart';

import 'api.dart';
import 'executor/cast.dart';
import 'executor/introspection_impls.dart';
import 'executor/serialization.dart';
import 'executor/span.dart';

part 'executor/arguments.dart';

/// The interface used by Dart language implementations, in order to load
/// and execute macros, as well as produce library augmentations from those
/// macro applications.
///
/// This class more clearly defines the role of a Dart language implementation
/// during macro discovery and expansion, and unifies how augmentation libraries
/// are produced.
abstract class MacroExecutor {
  /// Creates an instance of the macro [name] from [library] in the executor,
  /// and returns an identifier for that instance.
  ///
  /// Throws an exception if an instance is not created.
  ///
  /// Instances may be re-used throughout a single build, but should be
  /// re-created on subsequent builds (even incremental ones).
  Future<MacroInstanceIdentifier> instantiateMacro(
      Uri library, String name, String constructor, Arguments arguments);

  /// Disposes a macro [instance] by its identifier.
  ///
  /// All macros should be disposed once expanded to prevent memory leaks in the
  /// client macro executor.
  ///
  /// This is a fire and forget API, it does not happen synchronously but there
  /// is no reason to wait for it to complete, and the client does not send a
  /// response.
  void disposeMacro(MacroInstanceIdentifier instance);

  /// Runs the type phase for [macro] on a given [declaration].
  ///
  /// Throws an exception if there is an error executing the macro.
  Future<MacroExecutionResult> executeTypesPhase(MacroInstanceIdentifier macro,
      MacroTarget target, TypePhaseIntrospector introspector);

  /// Runs the declarations phase for [macro] on a given [declaration].
  ///
  /// Throws an exception if there is an error executing the macro.
  Future<MacroExecutionResult> executeDeclarationsPhase(
      MacroInstanceIdentifier macro,
      MacroTarget target,
      DeclarationPhaseIntrospector introspector);

  /// Runs the definitions phase for [macro] on a given [declaration].
  ///
  /// Throws an exception if there is an error executing the macro.
  Future<MacroExecutionResult> executeDefinitionsPhase(
      MacroInstanceIdentifier macro,
      MacroTarget target,
      DefinitionPhaseIntrospector introspector);

  /// Combines multiple [MacroExecutionResult]s into a single library
  /// augmentation file, and returns a [String] representing that file.
  ///
  /// The [resolveDeclaration] argument should return the [TypeDeclaration] for
  /// an [Identifier] pointing at a named type in the library being augmented
  /// (note this could be a type that was added in the "types" phase).
  ///
  /// The [resolveIdentifier] argument should return the import uri to be used
  /// for that identifier.
  ///
  /// The [inferOmittedType] argument is used to get the inferred type for a
  /// given [OmittedTypeAnnotation].
  ///
  /// If [omittedTypes] is provided, [inferOmittedType] is allowed to return
  /// `null` for types that have not yet been inferred. In this case a fresh
  /// name will be used for the omitted type in the generated library code and
  /// the omitted type will be mapped to the fresh name in [omittedTypes].
  ///
  /// The generated library files content must be deterministic, including the
  /// generation of fresh names for import prefixes and omitted types.
  ///
  /// If [spans] is provided, the [Span]s for the generated source are added
  /// to [spans]. This is used to compute the offset relation between
  /// intermediate augmentation libraries and the merged augmentation library.
  String buildAugmentationLibrary(
      Uri augmentedLibraryUri,
      Iterable<MacroExecutionResult> macroResults,
      TypeDeclaration Function(Identifier) resolveDeclaration,
      ResolvedIdentifier Function(Identifier) resolveIdentifier,
      TypeAnnotation? Function(OmittedTypeAnnotation) inferOmittedType,
      {Map<OmittedTypeAnnotation, String>? omittedTypes,
      List<Span>? spans});

  /// Tell the executor to shut down and clean up any resources it may have
  /// allocated.
  Future<void> close();
}

/// A resolved [Identifier], this is used when creating augmentation libraries
/// to qualify identifiers where needed.
class ResolvedIdentifier implements Identifier {
  /// The import URI for the library that defines the member that is referenced
  /// by this identifier.
  ///
  /// If this identifier is an instance member or a built-in type, like
  /// `void`, [uri] is `null`.
  final Uri? uri;

  /// Type of identifier this is (instance, static, top level).
  final IdentifierKind kind;

  /// The unqualified name of this identifier.
  @override
  final String name;

  /// If this is a static member, then the name of the fully qualified scope
  /// surrounding this member. Should not contain a trailing `.`.
  ///
  /// Typically this would just be the name of a type.
  final String? staticScope;

  ResolvedIdentifier({
    required this.kind,
    required this.name,
    required this.staticScope,
    required this.uri,
  });
}

/// The types of identifiers.
enum IdentifierKind {
  instanceMember,
  local, // Parameters, local variables, etc.
  staticInstanceMember,
  topLevelMember,
}

/// An opaque identifier for an instance of a macro class, retrieved by
/// [MacroExecutor.instantiateMacro].
///
/// Used to execute or reload this macro in the future.
abstract class MacroInstanceIdentifier implements Serializable {
  /// Whether or not this instance should run in [phase] on [declarationKind].
  ///
  /// Attempting to execute a macro in a phase it doesn't support, or on a
  /// declaration kind it doesn't support is an error.
  bool shouldExecute(DeclarationKind declarationKind, Phase phase);

  /// Whether or not this macro supports [declarationKind] in any phase.
  bool supportsDeclarationKind(DeclarationKind declarationKind);
}

/// A summary of the results of running a macro in a given phase.
///
/// All modifications are expressed in terms of library augmentation
/// declarations.
abstract class MacroExecutionResult implements Serializable {
  /// All [Diagnostic]s reported as a result of executing a macro.
  List<Diagnostic> get diagnostics;

  /// If execution was stopped by an exception, the exception.
  MacroException? get exception;

  /// Any augmentations to enum values that should be applied to an enum as a
  /// result of executing a macro, indexed by the identifier of the enum.
  Map<Identifier, Iterable<DeclarationCode>> get enumValueAugmentations;

  /// Any extends clauses that should be added to types as a result of executing
  /// a macro, indexed by the identifier of the augmented type declaration.
  Map<Identifier, NamedTypeAnnotationCode> get extendsTypeAugmentations;

  /// Any interfaces that should be added to types as a result of executing a
  /// macro, indexed by the identifier of the augmented type declaration.
  Map<Identifier, Iterable<TypeAnnotationCode>> get interfaceAugmentations;

  /// Any augmentations that should be applied to the library as a result of
  /// executing a macro.
  Iterable<DeclarationCode> get libraryAugmentations;

  /// Any mixins that should be added to types as a result of executing a macro,
  /// indexed by the identifier of the augmented type declaration.
  Map<Identifier, Iterable<TypeAnnotationCode>> get mixinAugmentations;

  /// The names of any new types declared in [augmentations].
  Iterable<String> get newTypeNames;

  /// Any augmentations that should be applied to a class as a result of
  /// executing a macro, indexed by the identifier of the class.
  Map<Identifier, Iterable<DeclarationCode>> get typeAugmentations;
}

/// Each of the possible types of declarations a macro can be applied to
enum DeclarationKind {
  classType,
  constructor,
  enumType,
  enumValue,
  extension,
  extensionType,
  field,
  function,
  library,
  method,
  mixinType,
  typeAlias,
  variable,
}

/// Each of the different macro execution phases.
enum Phase {
  /// Only new types are added in this phase.
  types,

  /// New non-type declarations are added in this phase.
  declarations,

  /// This phase allows augmenting existing declarations.
  definitions,
}
