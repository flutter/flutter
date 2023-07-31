// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The marker interface for all types of macros.
abstract class Macro {}

/// The interface for [Macro]s that can be applied to any top level function,
/// instance method, or static method, and wants to contribute new type
/// declarations to the program.
abstract class FunctionTypesMacro implements Macro {
  FutureOr<void> buildTypesForFunction(
      FunctionDeclaration function, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level function,
/// instance method, or static method, and wants to contribute new non-type
/// declarations to the program.
abstract class FunctionDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForFunction(
      FunctionDeclaration function, DeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level function,
/// instance method, or static method, and wants to augment the function
/// definition.
abstract class FunctionDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForFunction(
      FunctionDeclaration function, FunctionDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level variable or
/// instance field, and wants to contribute new type declarations to the
/// program.
abstract class VariableTypesMacro implements Macro {
  FutureOr<void> buildTypesForVariable(
      VariableDeclaration variable, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level variable or
/// instance field and wants to contribute new non-type declarations to the
/// program.
abstract class VariableDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForVariable(
      VariableDeclaration variable, DeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level variable
/// or instance field, and wants to augment the variable definition.
abstract class VariableDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForVariable(
      VariableDeclaration variable, VariableDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any class, and wants to
/// contribute new type declarations to the program.
abstract class ClassTypesMacro implements Macro {
  FutureOr<void> buildTypesForClass(
      ClassDeclaration clazz, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any class, and wants to
/// contribute new non-type declarations to the program.
abstract class ClassDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      ClassMemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any class, and wants to
/// augment the definitions of members on the class.
abstract class ClassDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForClass(
      IntrospectableClassDeclaration clazz, ClassDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any field, and wants to
/// contribute new type declarations to the program.
abstract class FieldTypesMacro implements Macro {
  FutureOr<void> buildTypesForField(
      FieldDeclaration field, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any field, and wants to
/// contribute new type declarations to the program.
abstract class FieldDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForField(
      FieldDeclaration field, ClassMemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any field, and wants to
/// augment the field definition.
abstract class FieldDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForField(
      FieldDeclaration field, VariableDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any method, and wants to
/// contribute new type declarations to the program.
abstract class MethodTypesMacro implements Macro {
  FutureOr<void> buildTypesForMethod(
      MethodDeclaration method, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any method, and wants to
/// contribute new non-type declarations to the program.
abstract class MethodDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForMethod(
      MethodDeclaration method, ClassMemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any method, and wants to
/// augment the function definition.
abstract class MethodDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any constructor, and wants
/// to contribute new type declarations to the program.
abstract class ConstructorTypesMacro implements Macro {
  FutureOr<void> buildTypesForConstructor(
      ConstructorDeclaration constructor, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any constructors, and
/// wants to contribute new non-type declarations to the program.
abstract class ConstructorDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForConstructor(
      ConstructorDeclaration constructor,
      ClassMemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any constructor, and wants
/// to augment the function definition.
abstract class ConstructorDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForConstructor(
      ConstructorDeclaration constructor, ConstructorDefinitionBuilder builder);
}
