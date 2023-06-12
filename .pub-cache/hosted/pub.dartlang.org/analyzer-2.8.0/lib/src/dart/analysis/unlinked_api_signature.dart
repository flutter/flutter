// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/summary/api_signature.dart';

/// Return the bytes of the unlinked API signature of the given [unit].
///
/// If API signatures of two units are different, they may have different APIs.
Uint8List computeUnlinkedApiSignature(CompilationUnit unit) {
  var computer = _UnitApiSignatureComputer();
  computer.compute(unit);
  return computer.signature.toByteList();
}

class _UnitApiSignatureComputer {
  static const int _kindConstructorDeclaration = 1;
  static const int _kindFieldDeclaration = 2;
  static const int _kindMethodDeclaration = 3;
  static const int _nullNode = 0;
  static const int _notNullNode = 1;
  static const int _nullToken = 0;
  static const int _notNullToken = 1;

  final ApiSignature signature = ApiSignature();

  void compute(CompilationUnit unit) {
    signature.addFeatureSet(unit.featureSet);

    signature.addInt(unit.directives.length);
    unit.directives.forEach(_addNode);

    signature.addInt(unit.declarations.length);
    for (var declaration in unit.declarations) {
      if (declaration is ClassOrMixinDeclaration) {
        _addClassOrMixin(declaration);
      } else if (declaration is FunctionDeclaration) {
        var functionExpression = declaration.functionExpression;
        _addTokens(
          declaration.beginToken,
          (functionExpression.parameters ?? declaration.name).endToken,
        );
        _addFunctionBodyModifiers(functionExpression.body);
      } else if (declaration is TopLevelVariableDeclaration) {
        _topLevelVariableDeclaration(declaration);
      } else {
        _addNode(declaration);
      }
    }
  }

  void _addClassOrMixin(ClassOrMixinDeclaration node) {
    _addTokens(node.beginToken, node.leftBracket);

    bool hasConstConstructor = node.members
        .any((m) => m is ConstructorDeclaration && m.constKeyword != null);

    signature.addInt(node.members.length);
    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        signature.addInt(_kindConstructorDeclaration);
        _addTokens(member.beginToken, member.parameters.endToken);
        _addNodeList(member.initializers);
        _addNode(member.redirectedConstructor);
      } else if (member is FieldDeclaration) {
        signature.addInt(_kindFieldDeclaration);
        _fieldDeclaration(member, hasConstConstructor);
      } else if (member is MethodDeclaration) {
        signature.addInt(_kindMethodDeclaration);
        _addTokens(
          member.beginToken,
          (member.parameters ?? member.name).endToken,
        );
        signature.addBool(member.body is EmptyFunctionBody);
        _addFunctionBodyModifiers(member.body);
      } else {
        throw UnimplementedError('(${member.runtimeType}) $member');
      }
    }

    _addToken(node.rightBracket);
  }

  void _addFunctionBodyModifiers(FunctionBody? node) {
    if (node != null) {
      signature.addBool(node.isSynchronous);
      signature.addBool(node.isGenerator);
    }
  }

  void _addNode(AstNode? node) {
    if (node != null) {
      signature.addInt(_notNullNode);
      _addTokens(node.beginToken, node.endToken);
    } else {
      signature.addInt(_nullNode);
    }
  }

  void _addNodeList(List<AstNode> nodes) {
    for (var node in nodes) {
      _addNode(node);
    }
  }

  void _addToken(Token? token) {
    if (token != null) {
      signature.addInt(_notNullToken);
      signature.addString(token.lexeme);
    } else {
      signature.addInt(_nullToken);
    }
  }

  /// Appends tokens from [begin] (including), to [end] (also including).
  void _addTokens(Token begin, Token end) {
    if (begin is CommentToken) {
      begin = begin.parent!;
    }

    Token? token = begin;
    while (token != null) {
      _addToken(token);

      if (token == end) {
        break;
      }

      var nextToken = token.next;

      // Stop if EOF.
      if (nextToken == token) {
        break;
      }

      token = nextToken;
    }
  }

  void _fieldDeclaration(FieldDeclaration node, bool hasConstConstructor) {
    _addToken(node.abstractKeyword);
    _addToken(node.covariantKeyword);
    _addToken(node.externalKeyword);
    _addToken(node.staticKeyword);
    _addNodeList(node.metadata);

    var variableList = node.fields;
    var includeInitializers = variableList.type == null ||
        variableList.isConst ||
        hasConstConstructor && !node.isStatic && variableList.isFinal;
    _variableList(variableList, includeInitializers);
  }

  void _topLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _addToken(node.externalKeyword);
    _addNodeList(node.metadata);

    var variableList = node.variables;
    var includeInitializers = variableList.type == null || variableList.isConst;
    _variableList(variableList, includeInitializers);
  }

  void _variableList(VariableDeclarationList node, bool includeInitializers) {
    _addToken(node.keyword);
    _addToken(node.lateKeyword);
    _addNode(node.type);

    var variables = node.variables;
    signature.addInt(variables.length);

    for (var variable in variables) {
      _addNode(variable.name);
      signature.addBool(variable.initializer != null);
      if (includeInitializers) {
        _addNode(variable.initializer);
      }
    }
  }
}
