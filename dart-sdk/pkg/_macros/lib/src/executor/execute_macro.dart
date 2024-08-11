// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../api.dart';
import '../executor.dart';
import 'builder_impls.dart';
import 'exception_impls.dart';
import 'introspection_impls.dart';

/// Runs [macro] in the types phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeTypesMacro(
    Macro macro, Object target, TypePhaseIntrospector introspector) async {
  // Must be assigned, used for error reporting.
  late final TypeBuilderBase builder;

  // TODO(jakemac): More robust handling for unawaited async errors?
  try {
    // Shared code for most branches. If we do create it, assign it to
    // `builder`.
    late final TypeBuilderImpl typeBuilder =
        builder = TypeBuilderImpl(introspector);
    switch ((target, macro)) {
      case (Library target, LibraryTypesMacro macro):
        await macro.buildTypesForLibrary(target, typeBuilder);
      case (ConstructorDeclaration target, ConstructorTypesMacro macro):
        await macro.buildTypesForConstructor(target, typeBuilder);
      case (MethodDeclaration target, MethodTypesMacro macro):
        await macro.buildTypesForMethod(target, typeBuilder);
      case (FunctionDeclaration target, FunctionTypesMacro macro):
        await macro.buildTypesForFunction(target, typeBuilder);
      case (FieldDeclaration target, FieldTypesMacro macro):
        await macro.buildTypesForField(target, typeBuilder);
      case (VariableDeclaration target, VariableTypesMacro macro):
        await macro.buildTypesForVariable(target, typeBuilder);
      case (ClassDeclaration target, ClassTypesMacro macro):
        await macro.buildTypesForClass(
            target,
            builder = ClassTypeBuilderImpl(
                target.identifier as IdentifierImpl, introspector));
      case (EnumDeclaration target, EnumTypesMacro macro):
        await macro.buildTypesForEnum(
            target,
            builder = EnumTypeBuilderImpl(
                target.identifier as IdentifierImpl, introspector));
      case (ExtensionDeclaration target, ExtensionTypesMacro macro):
        await macro.buildTypesForExtension(target, typeBuilder);
      case (ExtensionTypeDeclaration target, ExtensionTypeTypesMacro macro):
        await macro.buildTypesForExtensionType(target, typeBuilder);
      case (MixinDeclaration target, MixinTypesMacro macro):
        await macro.buildTypesForMixin(
            target,
            builder = MixinTypeBuilderImpl(
                target.identifier as IdentifierImpl, introspector));
      case (EnumValueDeclaration target, EnumValueTypesMacro macro):
        await macro.buildTypesForEnumValue(target, typeBuilder);
      case (TypeAliasDeclaration target, TypeAliasTypesMacro macro):
        await macro.buildTypesForTypeAlias(target, typeBuilder);
      default:
        throw UnsupportedError('Unsupported macro type or invalid target:\n'
            'macro: $macro\ntarget: $target');
    }
  } catch (e, s) {
    _handleError(e, s, builder);
  }
  return builder.result;
}

/// Runs [macro] in the declaration phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDeclarationsMacro(Macro macro,
    Object target, DeclarationPhaseIntrospector introspector) async {
  // Must be assigned, used for error reporting.
  late final DeclarationBuilderBase builder;

  // At most one of these will be used below.
  late MemberDeclarationBuilderImpl memberBuilder =
      builder = MemberDeclarationBuilderImpl(
          switch (target) {
            MemberDeclaration() => target.definingType as IdentifierImpl,
            TypeDeclarationImpl() => target.identifier,
            _ => throw StateError(
                'Can only create member declaration builders for types or '
                'member declarations, but got $target'),
          },
          introspector);
  late DeclarationBuilderImpl topLevelBuilder =
      builder = DeclarationBuilderImpl(introspector);
  late EnumDeclarationBuilderImpl enumBuilder =
      builder = EnumDeclarationBuilderImpl(
          switch (target) {
            EnumDeclarationImpl() => target.identifier,
            EnumValueDeclarationImpl() => target.definingEnum,
            _ => throw StateError(
                'Can only create enum declaration builders for enum or enum '
                'value declarations, but got $target'),
          },
          introspector);

  // TODO(jakemac): More robust handling for unawaited async errors?
  try {
    switch ((target, macro)) {
      case (Library target, LibraryDeclarationsMacro macro):
        await macro.buildDeclarationsForLibrary(target, topLevelBuilder);
      case (ClassDeclaration target, ClassDeclarationsMacro macro):
        await macro.buildDeclarationsForClass(target, memberBuilder);
      case (EnumDeclaration target, EnumDeclarationsMacro macro):
        await macro.buildDeclarationsForEnum(target, enumBuilder);
      case (ExtensionDeclaration target, ExtensionDeclarationsMacro macro):
        await macro.buildDeclarationsForExtension(target, memberBuilder);
      case (
          ExtensionTypeDeclaration target,
          ExtensionTypeDeclarationsMacro macro
        ):
        await macro.buildDeclarationsForExtensionType(target, memberBuilder);
      case (MixinDeclaration target, MixinDeclarationsMacro macro):
        await macro.buildDeclarationsForMixin(target, memberBuilder);
      case (EnumValueDeclaration target, EnumValueDeclarationsMacro macro):
        await macro.buildDeclarationsForEnumValue(target, enumBuilder);
      case (ConstructorDeclaration target, ConstructorDeclarationsMacro macro):
        await macro.buildDeclarationsForConstructor(target, memberBuilder);
      case (MethodDeclaration target, MethodDeclarationsMacro macro):
        await macro.buildDeclarationsForMethod(target, memberBuilder);
      case (FieldDeclaration target, FieldDeclarationsMacro macro):
        await macro.buildDeclarationsForField(target, memberBuilder);
      case (FunctionDeclaration target, FunctionDeclarationsMacro macro):
        await macro.buildDeclarationsForFunction(target, topLevelBuilder);
      case (VariableDeclaration target, VariableDeclarationsMacro macro):
        await macro.buildDeclarationsForVariable(target, topLevelBuilder);
      case (TypeAliasDeclaration target, TypeAliasDeclarationsMacro macro):
        await macro.buildDeclarationsForTypeAlias(target, topLevelBuilder);
      default:
        throw UnsupportedError('Unsupported macro type or invalid target:\n'
            'macro: $macro\ntarget: $target');
    }
  } catch (e, s) {
    _handleError(e, s, builder);
  }
  return builder.result;
}

/// Runs [macro] in the definition phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDefinitionMacro(Macro macro, Object target,
    DefinitionPhaseIntrospector introspector) async {
  // Must be assigned, used for error reporting and returning a value.
  late final DefinitionBuilderBase builder;

  // At most one of these will be used below.
  late FunctionDefinitionBuilderImpl functionBuilder = builder =
      FunctionDefinitionBuilderImpl(
          target as FunctionDeclarationImpl, introspector);
  late VariableDefinitionBuilderImpl variableBuilder = builder =
      VariableDefinitionBuilderImpl(
          target as VariableDeclaration, introspector);
  late TypeDefinitionBuilderImpl typeBuilder = builder =
      TypeDefinitionBuilderImpl(target as TypeDeclaration, introspector);

  // TODO(jakemac): More robust handling for unawaited async errors?
  try {
    switch ((target, macro)) {
      case (Library target, LibraryDefinitionMacro macro):
        LibraryDefinitionBuilderImpl libraryBuilder =
            builder = LibraryDefinitionBuilderImpl(target, introspector);
        await macro.buildDefinitionForLibrary(target, libraryBuilder);
      case (ClassDeclaration target, ClassDefinitionMacro macro):
        await macro.buildDefinitionForClass(target, typeBuilder);
      case (EnumDeclaration target, EnumDefinitionMacro macro):
        EnumDefinitionBuilderImpl enumBuilder =
            builder = EnumDefinitionBuilderImpl(target, introspector);
        await macro.buildDefinitionForEnum(target, enumBuilder);
      case (ExtensionDeclaration target, ExtensionDefinitionMacro macro):
        await macro.buildDefinitionForExtension(target, typeBuilder);
      case (
          ExtensionTypeDeclaration target,
          ExtensionTypeDefinitionMacro macro
        ):
        await macro.buildDefinitionForExtensionType(target, typeBuilder);
      case (MixinDeclaration target, MixinDefinitionMacro macro):
        await macro.buildDefinitionForMixin(target, typeBuilder);
      case (EnumValueDeclaration target, EnumValueDefinitionMacro macro):
        EnumValueDefinitionBuilderImpl enumValueBuilder = builder =
            EnumValueDefinitionBuilderImpl(
                target as EnumValueDeclarationImpl, introspector);
        await macro.buildDefinitionForEnumValue(target, enumValueBuilder);
      case (ConstructorDeclaration target, ConstructorDefinitionMacro macro):
        ConstructorDefinitionBuilderImpl constructorBuilder = builder =
            ConstructorDefinitionBuilderImpl(
                target as ConstructorDeclarationImpl, introspector);
        await macro.buildDefinitionForConstructor(target, constructorBuilder);
      case (MethodDeclaration target, MethodDefinitionMacro macro):
        await macro.buildDefinitionForMethod(
            target as MethodDeclarationImpl, functionBuilder);
      case (FieldDeclaration target, FieldDefinitionMacro macro):
        await macro.buildDefinitionForField(target, variableBuilder);
      case (FunctionDeclaration target, FunctionDefinitionMacro macro):
        await macro.buildDefinitionForFunction(target, functionBuilder);
      case (VariableDeclaration target, VariableDefinitionMacro macro):
        await macro.buildDefinitionForVariable(target, variableBuilder);
      default:
        throw UnsupportedError('Unsupported macro type or invalid target:\n'
            'macro: $macro\ntarget: $target');
    }
  } catch (e, s) {
    _handleError(e, s, builder);
  }
  return builder.result;
}

/// Handles macro execution errors, specifically handling [DiagnosticException]s
/// and [MacroException]s in the expected ways.
///
/// Also unwraps [ParallelWaitError]s and [AsyncError]s, such that we can
/// recognize properly the nested errors if they are of specially handled types.
void _handleError(
    Object error, StackTrace stackTrace, TypeBuilderBase builder) {
  switch (error) {
    case ParallelWaitError(errors: List<Object?> errors):
      _handleErrors(errors, stackTrace, builder);
    case ParallelWaitError(errors: (var e1,)):
      _handleErrors([e1], stackTrace, builder);
    case ParallelWaitError(
        errors: (
          var e1,
          var e2,
        )
      ):
      _handleErrors([e1, e2], stackTrace, builder);
    case ParallelWaitError(
        errors: (
          var e1,
          var e2,
          var e3,
        )
      ):
      _handleErrors([e1, e2, e3], stackTrace, builder);
    case ParallelWaitError(
        errors: (
          var e1,
          var e2,
          var e3,
          var e4,
        )
      ):
      _handleErrors([e1, e2, e3, e4], stackTrace, builder);
    case ParallelWaitError(
        errors: (
          var e1,
          var e2,
          var e3,
          var e4,
          var e5,
        )
      ):
      _handleErrors([e1, e2, e3, e4, e5], stackTrace, builder);
    case ParallelWaitError(
        errors: (
          var e1,
          var e2,
          var e3,
          var e4,
          var e5,
          var e6,
        )
      ):
      _handleErrors([e1, e2, e3, e4, e5, e6], stackTrace, builder);
    case ParallelWaitError(
        errors: (
          var e1,
          var e2,
          var e3,
          var e4,
          var e5,
          var e6,
          var e7,
        )
      ):
      _handleErrors([e1, e2, e3, e4, e5, e6, e7], stackTrace, builder);
    case ParallelWaitError(
        errors: (
          var e1,
          var e2,
          var e3,
          var e4,
          var e5,
          var e6,
          var e7,
          var e8,
        )
      ):
      _handleErrors([e1, e2, e3, e4, e5, e6, e7, e8], stackTrace, builder);
    case ParallelWaitError(
        errors: (
          var e1,
          var e2,
          var e3,
          var e4,
          var e5,
          var e6,
          var e7,
          var e8,
          var e9,
        )
      ):
      _handleErrors([e1, e2, e3, e4, e5, e6, e7, e8, e9], stackTrace, builder);
    // Unwrap async errors.
    case AsyncError():
      _handleError(error.error, error.stackTrace, builder);
    // Custom diagnostics from macros, these should just be reported.
    case DiagnosticException():
      builder.report(error.diagnostic);
    // Preserve `MacroException`s thrown by SDK tools.
    case MacroExceptionImpl():
      builder.failWithException(error);
    case _:
      // Convert exceptions thrown by macro implementations into diagnostics.
      builder.report(_unexpectedExceptionDiagnostic(error, stackTrace));
  }
}

/// Handles a number of [errors], ignoring null values.
///
/// This is used for parallel wait scenarios such as [Future.wait].
void _handleErrors(
    List<Object?> errors, StackTrace outerStackTrace, TypeBuilderBase builder) {
  for (var error in errors) {
    if (error == null) continue;
    // Passing the outerStackTrace here is the best we can do - but most of the
    // time `error` will actually be an `AsyncError`, and we will end up using
    // that stack trace anyways.
    _handleError(error, outerStackTrace, builder);
  }
}

// It's a bug in the macro but we need to show something to the user; put the
// debug detail in a context message and suggest reporting to the author.
Diagnostic _unexpectedExceptionDiagnostic(
        Object thrown, StackTrace stackTrace) =>
    Diagnostic(
        DiagnosticMessage(
            'Macro application failed due to a bug in the macro.'),
        Severity.error,
        contextMessages: [
          DiagnosticMessage('$thrown\n$stackTrace'),
        ],
        correctionMessage: 'Try reporting the failure to the macro author.');
