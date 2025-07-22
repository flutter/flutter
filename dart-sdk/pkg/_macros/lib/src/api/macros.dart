// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The marker interface for all types of macros.
abstract interface class Macro {}

/// The interface for [Macro]s that can be applied to a library directive, and
/// want to contribute new type declarations to the library.
abstract interface class LibraryTypesMacro implements Macro {
  FutureOr<void> buildTypesForLibrary(Library library, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to a library directive, and
/// want to contribute new non-type declarations to the library.
abstract interface class LibraryDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForLibrary(
      Library library, DeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to a library directive, and
/// want to provide definitions for declarations in the library.
abstract interface class LibraryDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForLibrary(
      Library library, LibraryDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level function,
/// instance method, or static method, and want to contribute new type
/// declarations to the program.
abstract interface class FunctionTypesMacro implements Macro {
  FutureOr<void> buildTypesForFunction(
      FunctionDeclaration function, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level function,
/// instance method, or static method, and want to contribute new non-type
/// declarations to the program.
abstract interface class FunctionDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForFunction(
      FunctionDeclaration function, DeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level function,
/// instance method, or static method, and want to augment the function
/// definition.
abstract interface class FunctionDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForFunction(
      FunctionDeclaration function, FunctionDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level variable or
/// instance field, and want to contribute new type declarations to the
/// program.
abstract interface class VariableTypesMacro implements Macro {
  FutureOr<void> buildTypesForVariable(
      VariableDeclaration variable, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level variable or
/// instance field and want to contribute new non-type declarations to the
/// program.
abstract interface class VariableDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForVariable(
      VariableDeclaration variable, DeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level variable
/// or instance field, and want to augment the variable definition.
abstract interface class VariableDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForVariable(
      VariableDeclaration variable, VariableDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any class, and want to
/// contribute new type declarations to the program.
abstract interface class ClassTypesMacro implements Macro {
  FutureOr<void> buildTypesForClass(
      ClassDeclaration clazz, ClassTypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any class, and want to
/// contribute new non-type declarations to the program.
abstract interface class ClassDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any class, and want to
/// augment the definitions of the members of that class.
abstract interface class ClassDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// contribute new type declarations to the program.
abstract interface class EnumTypesMacro implements Macro {
  FutureOr<void> buildTypesForEnum(
      EnumDeclaration enuum, EnumTypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// contribute new non-type declarations to the program.
abstract interface class EnumDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForEnum(
      EnumDeclaration enuum, EnumDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// augment the definitions of members or values of that enum.
abstract interface class EnumDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForEnum(
      EnumDeclaration enuum, EnumDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// contribute new type declarations to the program.
abstract interface class EnumValueTypesMacro implements Macro {
  FutureOr<void> buildTypesForEnumValue(
      EnumValueDeclaration entry, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// contribute new non-type declarations to the program.
abstract interface class EnumValueDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForEnumValue(
      EnumValueDeclaration entry, EnumDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// augment the definitions of members or values of that enum.
abstract interface class EnumValueDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForEnumValue(
      EnumValueDeclaration entry, EnumValueDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any field, and want to
/// contribute new type declarations to the program.
abstract interface class FieldTypesMacro implements Macro {
  FutureOr<void> buildTypesForField(
      FieldDeclaration field, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any field, and want to
/// contribute new type declarations to the program.
abstract interface class FieldDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForField(
      FieldDeclaration field, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any field, and want to
/// augment the field definition.
abstract interface class FieldDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForField(
      FieldDeclaration field, VariableDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any method, and want to
/// contribute new type declarations to the program.
abstract interface class MethodTypesMacro implements Macro {
  FutureOr<void> buildTypesForMethod(
      MethodDeclaration method, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any method, and want to
/// contribute new non-type declarations to the program.
abstract interface class MethodDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForMethod(
      MethodDeclaration method, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any method, and want to
/// augment the function definition.
abstract interface class MethodDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any constructor, and want
/// to contribute new type declarations to the program.
abstract interface class ConstructorTypesMacro implements Macro {
  FutureOr<void> buildTypesForConstructor(
      ConstructorDeclaration constructor, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any constructors, and
/// want to contribute new non-type declarations to the program.
abstract interface class ConstructorDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForConstructor(
      ConstructorDeclaration constructor, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any constructor, and want
/// to augment the function definition.
abstract interface class ConstructorDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForConstructor(
      ConstructorDeclaration constructor, ConstructorDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any mixin declaration, and
/// want to contribute new type declarations to the program.
abstract interface class MixinTypesMacro implements Macro {
  FutureOr<void> buildTypesForMixin(
      MixinDeclaration mixin, MixinTypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any mixin declaration, and
/// want to contribute new non-type declarations to the program.
abstract interface class MixinDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForMixin(
      MixinDeclaration mixin, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any mixin declaration, and
/// want to augment the definitions of the members of that mixin.
abstract interface class MixinDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForMixin(
      MixinDeclaration mixin, TypeDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any extension declaration,
/// and want to contribute new type declarations to the program.
abstract interface class ExtensionTypesMacro implements Macro {
  FutureOr<void> buildTypesForExtension(
      ExtensionDeclaration extension, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any extension declaration,
/// and want to contribute new non-type declarations to the program.
abstract interface class ExtensionDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForExtension(
      ExtensionDeclaration extension, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any extension declaration,
/// and want to augment the definitions of the members of that extension.
abstract interface class ExtensionDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForExtension(
      ExtensionDeclaration extension, TypeDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any extension type
/// declaration, and want to contribute new type declarations to the program.
abstract interface class ExtensionTypeTypesMacro implements Macro {
  FutureOr<void> buildTypesForExtensionType(
      ExtensionTypeDeclaration extension, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any extension type
/// declaration, and want to contribute new non-type declarations to the
/// program.
abstract interface class ExtensionTypeDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForExtensionType(
      ExtensionTypeDeclaration extension, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any extension type
/// declaration, and want to augment the definitions of the members of that
/// extension.
abstract interface class ExtensionTypeDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForExtensionType(
      ExtensionTypeDeclaration extension, TypeDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any type alias
/// declaration, and want to contribute new type declarations to the program.
abstract interface class TypeAliasTypesMacro implements Macro {
  FutureOr<void> buildTypesForTypeAlias(
    TypeAliasDeclaration declaration,
    TypeBuilder builder,
  );
}

/// The interface for [Macro]s that can be applied to any type alias
/// declaration, and want to contribute new non-type declarations to the
/// program.
abstract interface class TypeAliasDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForTypeAlias(
    TypeAliasDeclaration declaration,
    DeclarationBuilder builder,
  );
}
