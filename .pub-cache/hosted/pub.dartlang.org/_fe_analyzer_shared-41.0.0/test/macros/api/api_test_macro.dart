// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'api_test_expectations.dart';

macro

class ClassMacro
    implements ClassTypesMacro, ClassDeclarationsMacro, ClassDefinitionMacro {
  const ClassMacro();

  FutureOr<void> buildTypesForClass(ClassDeclaration clazz,
      TypeBuilder builder) async {
    await checkClassDeclaration(clazz);
  }

  FutureOr<void> buildDeclarationsForClass(
      ClassDeclaration clazz, ClassMemberDeclarationBuilder builder) async {
    await checkClassDeclaration(
      clazz, typeDeclarationResolver: builder, typeIntrospector: builder);
  }

  FutureOr<void> buildDefinitionForClass(
      ClassDeclaration clazz, ClassDefinitionBuilder builder) async {
    await checkClassDeclaration(clazz, typeIntrospector: builder);
    await checkIdentifierResolver(builder);
    await checkTypeDeclarationResolver(builder,
        {clazz.identifier: clazz.identifier.name});
  }
}

macro

class FunctionMacro
    implements
        FunctionTypesMacro,
        FunctionDeclarationsMacro,
        FunctionDefinitionMacro {
  const FunctionMacro();

  FutureOr<void> buildTypesForFunction(FunctionDeclaration function,
      TypeBuilder builder) async {
    checkFunctionDeclaration(function);
    await checkIdentifierResolver(builder);
  }

  FutureOr<void> buildDeclarationsForFunction(FunctionDeclaration function,
      DeclarationBuilder builder) async {
    checkFunctionDeclaration(function);
    await checkIdentifierResolver(builder);
  }

  FutureOr<void> buildDefinitionForFunction(FunctionDeclaration function,
      FunctionDefinitionBuilder builder) async {
    checkFunctionDeclaration(function);
    await checkIdentifierResolver(builder);
    await checkTypeDeclarationResolver(builder, {function.identifier: null});
  }
}
