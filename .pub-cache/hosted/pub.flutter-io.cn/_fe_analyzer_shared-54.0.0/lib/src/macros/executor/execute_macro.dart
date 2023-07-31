// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/builder_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

/// Runs [macro] in the types phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeTypesMacro(Macro macro,
    Declaration declaration, IdentifierResolver identifierResolver) async {
  TypeBuilderImpl builder = new TypeBuilderImpl(identifierResolver);
  if (declaration is FunctionDeclaration) {
    if (macro is ConstructorTypesMacro &&
        declaration is ConstructorDeclaration) {
      await macro.buildTypesForConstructor(declaration, builder);
      return builder.result;
    } else if (macro is MethodTypesMacro && declaration is MethodDeclaration) {
      await macro.buildTypesForMethod(declaration, builder);
      return builder.result;
    } else if (macro is FunctionTypesMacro) {
      await macro.buildTypesForFunction(declaration, builder);
      return builder.result;
    }
  } else if (declaration is VariableDeclaration) {
    if (macro is FieldTypesMacro && declaration is FieldDeclaration) {
      await macro.buildTypesForField(declaration, builder);
      return builder.result;
    } else if (macro is VariableTypesMacro) {
      await macro.buildTypesForVariable(declaration, builder);
      return builder.result;
    }
  } else if (macro is ClassTypesMacro && declaration is ClassDeclaration) {
    await macro.buildTypesForClass(declaration, builder);
    return builder.result;
  }
  throw new UnsupportedError('Unsupported macro type or invalid declaration:\n'
      'macro: $macro\ndeclaration: $declaration');
}

/// Runs [macro] in the declaration phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDeclarationsMacro(
    Macro macro,
    Declaration declaration,
    IdentifierResolver identifierResolver,
    TypeIntrospector typeIntrospector,
    TypeDeclarationResolver typeDeclarationResolver,
    TypeResolver typeResolver) async {
  if (declaration is ClassDeclaration && macro is ClassDeclarationsMacro) {
    if (declaration is! IntrospectableClassDeclaration) {
      throw new ArgumentError(
          'Class declarations annotated with a macro should be introspectable '
          'in the declarations phase.');
    }
    ClassMemberDeclarationBuilderImpl builder =
        new ClassMemberDeclarationBuilderImpl(
            declaration.identifier,
            identifierResolver,
            typeIntrospector,
            typeDeclarationResolver,
            typeResolver);
    await macro.buildDeclarationsForClass(declaration, builder);
    return builder.result;
  } else if (declaration is ClassMemberDeclaration) {
    ClassMemberDeclarationBuilderImpl builder =
        new ClassMemberDeclarationBuilderImpl(
            declaration.definingClass,
            identifierResolver,
            typeIntrospector,
            typeDeclarationResolver,
            typeResolver);
    if (declaration is FunctionDeclaration) {
      if (macro is ConstructorDeclarationsMacro &&
          declaration is ConstructorDeclaration) {
        await macro.buildDeclarationsForConstructor(declaration, builder);
        return builder.result;
      } else if (macro is MethodDeclarationsMacro &&
          declaration is MethodDeclaration) {
        await macro.buildDeclarationsForMethod(declaration, builder);
        return builder.result;
      } else if (macro is FunctionDeclarationsMacro) {
        await macro.buildDeclarationsForFunction(
            declaration as FunctionDeclaration, builder);
        return builder.result;
      }
    } else if (declaration is VariableDeclaration) {
      if (macro is FieldDeclarationsMacro && declaration is FieldDeclaration) {
        await macro.buildDeclarationsForField(declaration, builder);
        return builder.result;
      } else if (macro is VariableDeclarationsMacro) {
        DeclarationBuilderImpl builder = new DeclarationBuilderImpl(
            identifierResolver,
            typeIntrospector,
            typeDeclarationResolver,
            typeResolver);
        await macro.buildDeclarationsForVariable(
            declaration as VariableDeclaration, builder);
        return builder.result;
      }
    }
  } else {
    DeclarationBuilderImpl builder = new DeclarationBuilderImpl(
        identifierResolver,
        typeIntrospector,
        typeDeclarationResolver,
        typeResolver);
    if (declaration is FunctionDeclaration &&
        macro is FunctionDeclarationsMacro) {
      await macro.buildDeclarationsForFunction(declaration, builder);
      return builder.result;
    } else if (macro is VariableDeclarationsMacro &&
        declaration is VariableDeclaration) {
      await macro.buildDeclarationsForVariable(declaration, builder);
      return builder.result;
    }
  }
  throw new UnsupportedError('Unsupported macro type or invalid declaration:\n'
      'macro: $macro\ndeclaration: $declaration');
}

/// Runs [macro] in the definition phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDefinitionMacro(
    Macro macro,
    Declaration declaration,
    IdentifierResolver identifierResolver,
    TypeIntrospector typeIntrospector,
    TypeResolver typeResolver,
    TypeDeclarationResolver typeDeclarationResolver,
    TypeInferrer typeInferrer) async {
  if (declaration is FunctionDeclaration) {
    if (macro is ConstructorDefinitionMacro &&
        declaration is ConstructorDeclaration) {
      ConstructorDefinitionBuilderImpl builder =
          new ConstructorDefinitionBuilderImpl(
              declaration,
              identifierResolver,
              typeIntrospector,
              typeDeclarationResolver,
              typeResolver,
              typeInferrer);
      await macro.buildDefinitionForConstructor(declaration, builder);
      return builder.result;
    } else {
      FunctionDefinitionBuilderImpl builder = new FunctionDefinitionBuilderImpl(
          declaration,
          identifierResolver,
          typeIntrospector,
          typeDeclarationResolver,
          typeResolver,
          typeInferrer);
      if (macro is MethodDefinitionMacro && declaration is MethodDeclaration) {
        await macro.buildDefinitionForMethod(declaration, builder);
        return builder.result;
      } else if (macro is FunctionDefinitionMacro) {
        await macro.buildDefinitionForFunction(declaration, builder);
        return builder.result;
      }
    }
  } else if (declaration is VariableDeclaration) {
    VariableDefinitionBuilderImpl builder = new VariableDefinitionBuilderImpl(
        declaration,
        identifierResolver,
        typeIntrospector,
        typeDeclarationResolver,
        typeResolver,
        typeInferrer);
    if (macro is FieldDefinitionMacro && declaration is FieldDeclaration) {
      await macro.buildDefinitionForField(declaration, builder);
      return builder.result;
    } else if (macro is VariableDefinitionMacro) {
      await macro.buildDefinitionForVariable(declaration, builder);
      return builder.result;
    }
  } else if (macro is ClassDefinitionMacro && declaration is ClassDeclaration) {
    if (declaration is! IntrospectableClassDeclaration) {
      throw new ArgumentError(
          'Class declarations annotated with a macro should be introspectable '
          'in the definitions phase.');
    }
    ClassDefinitionBuilderImpl builder = new ClassDefinitionBuilderImpl(
        declaration,
        identifierResolver,
        typeIntrospector,
        typeResolver,
        typeDeclarationResolver,
        typeInferrer);
    await macro.buildDefinitionForClass(declaration, builder);
    return builder.result;
  }
  throw new UnsupportedError('Unsupported macro type or invalid declaration:\n'
      'macro: $macro\ndeclaration: $declaration');
}
