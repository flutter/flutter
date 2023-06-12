// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [ForStatement]s and [ForElement]s.
class ForResolver {
  final ResolverVisitor _resolver;

  ForResolver({
    required ResolverVisitor resolver,
  }) : _resolver = resolver;

  void resolveElement(ForElementImpl node) {
    var forLoopParts = node.forLoopParts;
    if (forLoopParts is ForPartsImpl) {
      _forParts(node, forLoopParts, node.body);
    } else if (forLoopParts is ForEachPartsImpl) {
      _forEachParts(node, node.awaitKeyword != null, forLoopParts, node.body);
    }
  }

  void resolveStatement(ForStatementImpl node) {
    _resolver.checkUnreachableNode(node);

    var forLoopParts = node.forLoopParts;
    if (forLoopParts is ForPartsImpl) {
      _forParts(node, forLoopParts, node.body);
    } else if (forLoopParts is ForEachPartsImpl) {
      _forEachParts(node, node.awaitKeyword != null, forLoopParts, node.body);
    }
  }

  /// Given an iterable expression from a foreach loop, attempt to infer
  /// a type for the elements being iterated over.  Inference is based
  /// on the type of the iterator or stream over which the foreach loop
  /// is defined.
  DartType? _computeForEachElementType(Expression iterable, bool isAsync) {
    var iterableType = iterable.staticType;
    if (iterableType == null) return null;
    iterableType =
        iterableType.resolveToBound(_resolver.typeProvider.objectType);

    ClassElement iteratedElement = isAsync
        ? _resolver.typeProvider.streamElement
        : _resolver.typeProvider.iterableElement;

    var iteratedType = iterableType.asInstanceOf(iteratedElement);

    if (iteratedType != null) {
      var elementType = iteratedType.typeArguments.single;
      elementType = _resolver.toLegacyTypeIfOptOut(elementType);
      return elementType;
    } else {
      return null;
    }
  }

  void _forEachParts(
    AstNode node,
    bool isAsync,
    ForEachParts forEachParts,
    AstNode body,
  ) {
    Expression iterable = forEachParts.iterable;
    DeclaredIdentifier? loopVariable;
    SimpleIdentifier? identifier;
    Element? identifierElement;
    if (forEachParts is ForEachPartsWithDeclaration) {
      loopVariable = forEachParts.loopVariable;
    } else if (forEachParts is ForEachPartsWithIdentifier) {
      identifier = forEachParts.identifier;
      // TODO(scheglov) replace with lexical lookup
      identifier.accept(_resolver);
      AssignmentExpressionShared(
        resolver: _resolver,
      ).checkFinalAlreadyAssigned(identifier);
    }

    DartType? valueType;
    if (loopVariable != null) {
      var typeAnnotation = loopVariable.type;
      valueType = typeAnnotation?.type ?? UnknownInferredType.instance;
    }
    if (identifier != null) {
      identifierElement = identifier.staticElement;
      if (identifierElement is VariableElement) {
        valueType = _resolver.localVariableTypeProvider
            .getType(identifier, isRead: false);
      } else if (identifierElement is PropertyAccessorElement) {
        var parameters = identifierElement.parameters;
        if (parameters.isNotEmpty) {
          valueType = parameters[0].type;
        }
      }
    }
    if (valueType != null) {
      InterfaceType targetType = isAsync
          ? _resolver.typeProvider.streamType(valueType)
          : _resolver.typeProvider.iterableType(valueType);
      InferenceContext.setType(iterable, targetType);
    }

    iterable.accept(_resolver);
    iterable = forEachParts.iterable;

    _resolver.nullableDereferenceVerifier.expression(
      CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR,
      iterable,
    );

    loopVariable?.accept(_resolver);
    var elementType = _computeForEachElementType(iterable, isAsync);
    if (loopVariable != null &&
        elementType != null &&
        loopVariable.type == null) {
      var loopVariableElement =
          loopVariable.declaredElement as LocalVariableElementImpl;
      loopVariableElement.type = elementType;
    }

    if (loopVariable != null) {
      _resolver.flowAnalysis.flow?.declare(loopVariable.declaredElement!, true);
    }

    _resolver.flowAnalysis.flow?.forEach_bodyBegin(node);
    if (identifierElement is PromotableElement &&
        forEachParts is ForEachPartsWithIdentifier) {
      _resolver.flowAnalysis.flow?.write(forEachParts, identifierElement,
          elementType ?? DynamicTypeImpl.instance, null);
    }

    body.accept(_resolver);

    _resolver.flowAnalysis.flow?.forEach_end();
  }

  void _forParts(AstNode node, ForParts forParts, AstNode body) {
    if (forParts is ForPartsWithDeclarations) {
      forParts.variables.accept(_resolver);
    } else if (forParts is ForPartsWithExpression) {
      forParts.initialization?.accept(_resolver);
    }

    _resolver.flowAnalysis.for_conditionBegin(node);

    var condition = forParts.condition;
    if (condition != null) {
      InferenceContext.setType(condition, _resolver.typeProvider.boolType);
      condition.accept(_resolver);
      condition = forParts.condition!;
      var whyNotPromoted =
          _resolver.flowAnalysis.flow?.whyNotPromoted(condition);
      _resolver.boolExpressionVerifier
          .checkForNonBoolCondition(condition, whyNotPromoted: whyNotPromoted);
    }

    _resolver.flowAnalysis.for_bodyBegin(node, condition);
    body.accept(_resolver);

    _resolver.flowAnalysis.flow?.for_updaterBegin();
    forParts.updaters.accept(_resolver);

    _resolver.flowAnalysis.flow?.for_end();
  }
}
