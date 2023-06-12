// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_utilities/check/check.dart';

import 'token_check.dart';

extension ArgumentListExtension on CheckTarget<ArgumentList> {
  CheckTarget<List<Expression>> get arguments {
    return nest(
      value.arguments,
      (selected) => 'has arguments ${valueStr(selected)}',
    );
  }

  void get isSynthetic {
    leftParenthesis
      ..isOpenParenthesis
      ..isSynthetic;
    rightParenthesis
      ..isCloseParenthesis
      ..isSynthetic;
    arguments.isEmpty;
  }

  CheckTarget<Token> get leftParenthesis {
    return nest(
      value.leftParenthesis,
      (selected) => 'has leftParenthesis ${valueStr(selected)}',
    );
  }

  CheckTarget<Token> get rightParenthesis {
    return nest(
      value.rightParenthesis,
      (selected) => 'has rightParenthesis ${valueStr(selected)}',
    );
  }
}

extension ConstructorSelectorExtension on CheckTarget<ConstructorSelector> {
  CheckTarget<SimpleIdentifier> get name {
    return nest(
      value.name,
      (selected) => 'has name ${valueStr(selected)}',
    );
  }
}

extension EnumConstantArgumentsExtension on CheckTarget<EnumConstantArguments> {
  CheckTarget<ArgumentList> get argumentList {
    return nest(
      value.argumentList,
      (selected) => 'has argumentList ${valueStr(selected)}',
    );
  }

  CheckTarget<ConstructorSelector?> get constructorSelector {
    return nest(
      value.constructorSelector,
      (selected) => 'has constructorSelector ${valueStr(selected)}',
    );
  }

  CheckTarget<TypeArgumentList?> get typeArguments {
    return nest(
      value.typeArguments,
      (selected) => 'has typeArguments ${valueStr(selected)}',
    );
  }
}

extension EnumConstantDeclarationExtension
    on CheckTarget<EnumConstantDeclaration> {
  CheckTarget<EnumConstantArguments?> get arguments {
    return nest(
      value.arguments,
      (selected) => 'has arguments ${valueStr(selected)}',
    );
  }

  CheckTarget<SimpleIdentifier> get name {
    return nest(
      value.name,
      (selected) => 'has name ${valueStr(selected)}',
    );
  }
}

extension EnumDeclarationExtension on CheckTarget<EnumDeclaration> {
  CheckTarget<Token?> get semicolon {
    return nest(
      value.semicolon,
      (selected) => 'has semicolon ${valueStr(selected)}',
    );
  }
}

extension FormalParameterExtension on CheckTarget<FormalParameter> {
  CheckTarget<SimpleIdentifier?> get identifier {
    return nest(
      value.identifier,
      (selected) => 'has identifier ${valueStr(selected)}',
    );
  }
}

extension SimpleFormalParameterExtension on CheckTarget<SimpleFormalParameter> {
  CheckTarget<Token?> get keyword {
    return nest(
      value.keyword,
      (selected) => 'has keyword ${valueStr(selected)}',
    );
  }

  CheckTarget<TypeAnnotation?> get type {
    return nest(
      value.type,
      (selected) => 'has type ${valueStr(selected)}',
    );
  }
}

extension SimpleIdentifierExtension on CheckTarget<SimpleIdentifier> {
  CheckTarget<bool> get inDeclarationContext {
    return nest(
      value.inDeclarationContext(),
      (selected) => 'has inDeclarationContext() ${valueStr(selected)}',
    );
  }

  void get isSynthetic {
    if (!value.token.isSynthetic) {
      fail('Is not synthetic');
    }
  }

  CheckTarget<String> get name {
    return nest(
      value.name,
      (selected) => 'has name ${valueStr(selected)}',
    );
  }
}

extension SuperFormalParameterExtension on CheckTarget<SuperFormalParameter> {
  CheckTarget<SimpleIdentifier> get identifier {
    return nest(
      value.identifier,
      (selected) => 'has identifier ${valueStr(selected)}',
    );
  }

  CheckTarget<Token?> get keyword {
    return nest(
      value.keyword,
      (selected) => 'has keyword ${valueStr(selected)}',
    );
  }

  CheckTarget<FormalParameterList?> get parameters {
    return nest(
      value.parameters,
      (selected) => 'has parameters ${valueStr(selected)}',
    );
  }

  CheckTarget<Token?> get superKeyword {
    return nest(
      value.superKeyword,
      (selected) => 'has superKeyword ${valueStr(selected)}',
    );
  }

  CheckTarget<TypeAnnotation?> get type {
    return nest(
      value.type,
      (selected) => 'has type ${valueStr(selected)}',
    );
  }

  CheckTarget<TypeParameterList?> get typeParameters {
    return nest(
      value.typeParameters,
      (selected) => 'has typeParameters ${valueStr(selected)}',
    );
  }
}

extension TypeParameterListExtension on CheckTarget<TypeParameterList> {
  CheckTarget<List<TypeParameter>> get typeParameters {
    return nest(
      value.typeParameters,
      (selected) => 'has typeParameters ${valueStr(selected)}',
    );
  }
}
