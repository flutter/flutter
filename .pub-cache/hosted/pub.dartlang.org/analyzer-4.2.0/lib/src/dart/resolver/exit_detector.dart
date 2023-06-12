// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// Instances of the class `ExitDetector` determine whether the visited AST node
/// is guaranteed to terminate by executing a `return` statement, `throw`
/// expression, `rethrow` expression, or simple infinite loop such as
/// `while(true)`.
class ExitDetector extends GeneralizingAstVisitor<bool> {
  /// Set to `true` when a `break` is encountered, and reset to `false` when a
  /// `do`, `while`, `for` or `switch` block is entered.
  bool _enclosingBlockContainsBreak = false;

  /// Set to `true` when a `continue` is encountered, and reset to `false` when
  /// a `do`, `while`, `for` or `switch` block is entered.
  bool _enclosingBlockContainsContinue = false;

  /// Add node when a labelled `break` is encountered.
  final Set<AstNode?> _enclosingBlockBreaksLabel = <AstNode?>{};

  @override
  bool visitArgumentList(ArgumentList node) =>
      _visitExpressions(node.arguments);

  @override
  bool visitAsExpression(AsExpression node) => _nodeExits(node.expression);

  @override
  bool visitAssertInitializer(AssertInitializer node) => false;

  @override
  bool visitAssertStatement(AssertStatement node) => false;

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    Expression leftHandSide = node.leftHandSide;
    if (_nodeExits(leftHandSide)) {
      return true;
    }
    TokenType operatorType = node.operator.type;
    if (operatorType == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operatorType == TokenType.BAR_BAR_EQ ||
        operatorType == TokenType.QUESTION_QUESTION_EQ) {
      return false;
    }
    if (leftHandSide is PropertyAccess && leftHandSide.isNullAware) {
      return false;
    }
    return _nodeExits(node.rightHandSide);
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) =>
      _nodeExits(node.expression);

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    Expression lhsExpression = node.leftOperand;
    Expression rhsExpression = node.rightOperand;
    TokenType operatorType = node.operator.type;
    // If the operator is ||, then only consider the RHS of the binary
    // expression if the left hand side is the false literal.
    // TODO(jwren) Do we want to take constant expressions into account,
    // evaluate if(false) {} differently than if(<condition>), when <condition>
    // evaluates to a constant false value?
    if (operatorType == TokenType.BAR_BAR) {
      if (lhsExpression is BooleanLiteral) {
        if (!lhsExpression.value) {
          return _nodeExits(rhsExpression);
        }
      }
      return _nodeExits(lhsExpression);
    }
    // If the operator is &&, then only consider the RHS of the binary
    // expression if the left hand side is the true literal.
    if (operatorType == TokenType.AMPERSAND_AMPERSAND) {
      if (lhsExpression is BooleanLiteral) {
        if (lhsExpression.value) {
          return _nodeExits(rhsExpression);
        }
      }
      return _nodeExits(lhsExpression);
    }
    // If the operator is ??, then don't consider the RHS of the binary
    // expression.
    if (operatorType == TokenType.QUESTION_QUESTION) {
      return _nodeExits(lhsExpression);
    }
    return _nodeExits(lhsExpression) || _nodeExits(rhsExpression);
  }

  @override
  bool visitBlock(Block node) => _visitStatements(node.statements);

  @override
  bool visitBlockFunctionBody(BlockFunctionBody node) => _nodeExits(node.block);

  @override
  bool visitBreakStatement(BreakStatement node) {
    _enclosingBlockContainsBreak = true;
    if (node.label != null) {
      _enclosingBlockBreaksLabel.add(node.target);
    }
    return false;
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) =>
      _nodeExits(node.target) || _visitExpressions(node.cascadeSections);

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    var conditionExpression = node.condition;
    var thenExpression = node.thenExpression;
    var elseExpression = node.elseExpression;
    // TODO(jwren) Do we want to take constant expressions into account,
    // evaluate if(false) {} differently than if(<condition>), when <condition>
    // evaluates to a constant false value?
    if (_nodeExits(conditionExpression)) {
      return true;
    }
    return thenExpression.accept(this)! && elseExpression.accept(this)!;
  }

  @override
  bool visitConstructorReference(ConstructorReference node) => false;

  @override
  bool visitContinueStatement(ContinueStatement node) {
    _enclosingBlockContainsContinue = true;
    return false;
  }

  @override
  bool visitDoStatement(DoStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    bool outerContinueValue = _enclosingBlockContainsContinue;
    _enclosingBlockContainsBreak = false;
    _enclosingBlockContainsContinue = false;
    try {
      bool bodyExits = _nodeExits(node.body);
      bool containsBreakOrContinue =
          _enclosingBlockContainsBreak || _enclosingBlockContainsContinue;
      // Even if we determine that the body "exits", there might be break or
      // continue statements that actually mean it _doesn't_ always exit.
      if (bodyExits && !containsBreakOrContinue) {
        return true;
      }
      Expression conditionExpression = node.condition;
      if (_nodeExits(conditionExpression)) {
        return true;
      }
      // TODO(jwren) Do we want to take all constant expressions into account?
      if (conditionExpression is BooleanLiteral) {
        // If do {} while (true), and the body doesn't break, then return true.
        if (conditionExpression.value && !_enclosingBlockContainsBreak) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
      _enclosingBlockContainsContinue = outerContinueValue;
    }
  }

  @override
  bool visitEmptyStatement(EmptyStatement node) => false;

  @override
  bool visitExpressionStatement(ExpressionStatement node) =>
      _nodeExits(node.expression);

  @override
  bool visitExtensionOverride(ExtensionOverride node) => false;

  @override
  bool visitForElement(ForElement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      ForLoopParts forLoopParts = node.forLoopParts;
      if (forLoopParts is ForParts) {
        if (forLoopParts is ForPartsWithDeclarations) {
          if (_visitVariableDeclarations(forLoopParts.variables.variables)) {
            return true;
          }
        } else if (forLoopParts is ForPartsWithExpression) {
          var initialization = forLoopParts.initialization;
          if (initialization != null && _nodeExits(initialization)) {
            return true;
          }
        }
        var conditionExpression = forLoopParts.condition;
        if (conditionExpression != null && _nodeExits(conditionExpression)) {
          return true;
        }
        if (_visitExpressions(forLoopParts.updaters)) {
          return true;
        }
        bool blockReturns = _nodeExits(node.body);
        // TODO(jwren) Do we want to take all constant expressions into account?
        // If for(; true; ) (or for(;;)), and the body doesn't return or the body
        // doesn't have a break, then return true.
        bool implicitOrExplictTrue = conditionExpression == null ||
            (conditionExpression is BooleanLiteral &&
                conditionExpression.value);
        if (implicitOrExplictTrue) {
          if (blockReturns || !_enclosingBlockContainsBreak) {
            return true;
          }
        }
        return false;
      } else if (forLoopParts is ForEachParts) {
        bool iterableExits = _nodeExits(forLoopParts.iterable);
        // Discard whether the for-each body exits; since the for-each iterable
        // may be empty, execution may never enter the body, so it doesn't matter
        // if it exits or not.  We still must visit the body, to accurately
        // manage `_enclosingBlockBreaksLabel`.
        _nodeExits(node.body);
        return iterableExits;
      }
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
    return false;
  }

  @override
  bool visitForStatement(ForStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    ForLoopParts parts = node.forLoopParts;
    try {
      if (parts is ForEachParts) {
        bool iterableExits = _nodeExits(parts.iterable);
        // Discard whether the for-each body exits; since the for-each iterable
        // may be empty, execution may never enter the body, so it doesn't matter
        // if it exits or not.  We still must visit the body, to accurately
        // manage `_enclosingBlockBreaksLabel`.
        _nodeExits(node.body);
        return iterableExits;
      }
      VariableDeclarationList? variables;
      Expression? initialization;
      Expression? condition;
      NodeList<Expression> updaters;
      if (parts is ForPartsWithDeclarations) {
        variables = parts.variables;
        condition = parts.condition;
        updaters = parts.updaters;
      } else if (parts is ForPartsWithExpression) {
        initialization = parts.initialization;
        condition = parts.condition;
        updaters = parts.updaters;
      } else {
        throw UnimplementedError();
      }
      if (variables != null &&
          _visitVariableDeclarations(variables.variables)) {
        return true;
      }
      if (initialization != null && _nodeExits(initialization)) {
        return true;
      }
      if (condition != null && _nodeExits(condition)) {
        return true;
      }
      if (_visitExpressions(updaters)) {
        return true;
      }
      bool blockReturns = _nodeExits(node.body);
      // TODO(jwren) Do we want to take all constant expressions into account?
      // If for(; true; ) (or for(;;)), and the body doesn't return or the body
      // doesn't have a break, then return true.
      bool implicitOrExplictTrue =
          condition == null || (condition is BooleanLiteral && condition.value);
      if (implicitOrExplictTrue) {
        if (blockReturns || !_enclosingBlockContainsBreak) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  @override
  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      false;

  @override
  bool visitFunctionExpression(FunctionExpression node) => false;

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (_nodeExits(node.function)) {
      return true;
    }
    return node.argumentList.accept(this)!;
  }

  @override
  bool visitFunctionReference(FunctionReference node) {
    // Note: `node.function` could be a reference to a method
    // (`Target.methodName`) so we need to visit it in case the target exits.
    return node.function.accept(this)!;
  }

  @override
  bool visitGenericFunctionType(GenericFunctionType node) => false;

  @override
  bool visitIdentifier(Identifier node) => false;

  @override
  bool visitIfElement(IfElement node) {
    var conditionExpression = node.condition;
    var thenElement = node.thenElement;
    var elseElement = node.elseElement;
    if (_nodeExits(conditionExpression)) {
      return true;
    }

    var conditionValue = _knownConditionValue(conditionExpression);
    if (conditionValue == true) {
      return _nodeExits(thenElement);
    } else if (conditionValue == false && elseElement != null) {
      return _nodeExits(elseElement);
    }

    bool thenExits = _nodeExits(thenElement);
    bool elseExits = _nodeExits(elseElement);
    if (elseElement == null) {
      return false;
    }
    return thenExits && elseExits;
  }

  @override
  bool visitIfStatement(IfStatement node) {
    var conditionExpression = node.condition;
    var thenStatement = node.thenStatement;
    var elseStatement = node.elseStatement;
    if (_nodeExits(conditionExpression)) {
      return true;
    }

    var conditionValue = _knownConditionValue(conditionExpression);
    if (conditionValue == true) {
      return _nodeExits(thenStatement);
    } else if (conditionValue == false && elseStatement != null) {
      return _nodeExits(elseStatement);
    }

    bool thenExits = _nodeExits(thenStatement);
    bool elseExits = _nodeExits(elseStatement);
    if (elseStatement == null) {
      return false;
    }
    return thenExits && elseExits;
  }

  @override
  bool visitImplicitCallReference(ImplicitCallReference node) {
    return _nodeExits(node.expression);
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    Expression target = node.realTarget;
    if (_nodeExits(target)) {
      return true;
    }
    if (_nodeExits(node.index)) {
      return true;
    }
    return false;
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _nodeExits(node.argumentList);

  @override
  bool visitIsExpression(IsExpression node) => node.expression.accept(this)!;

  @override
  bool visitLabel(Label node) => false;

  @override
  bool visitLabeledStatement(LabeledStatement node) {
    try {
      bool statementExits = _nodeExits(node.statement);
      bool neverBrokeFromLabel =
          !_enclosingBlockBreaksLabel.contains(node.statement);
      return statementExits && neverBrokeFromLabel;
    } finally {
      _enclosingBlockBreaksLabel.remove(node.statement);
    }
  }

  @override
  bool visitListLiteral(ListLiteral node) {
    for (CollectionElement element in node.elements) {
      if (_nodeExits(element)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitLiteral(Literal node) => false;

  @override
  bool visitMapLiteralEntry(MapLiteralEntry node) {
    return _nodeExits(node.key) || _nodeExits(node.value);
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    var target = node.realTarget;
    if (target != null) {
      if (target.accept(this)!) {
        return true;
      }
      if (node.isNullAware) {
        return false;
      }
    }
    var element = node.methodName.staticElement;
    if (_elementExits(element)) {
      return true;
    }
    return _nodeExits(node.argumentList);
  }

  @override
  bool visitNamedExpression(NamedExpression node) =>
      node.expression.accept(this)!;

  @override
  bool visitNamedType(NamedType node) => false;

  @override
  bool visitNode(AstNode node) {
    throw StateError(
        'Missing a visit method for a node of type ${node.runtimeType}');
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) =>
      node.expression.accept(this)!;

  @override
  bool visitPostfixExpression(PostfixExpression node) => false;

  @override
  bool visitPrefixExpression(PrefixExpression node) => false;

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    var target = node.realTarget;
    return target.accept(this)!;
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) => true;

  @override
  bool visitReturnStatement(ReturnStatement node) => true;

  @override
  bool visitSetOrMapLiteral(SetOrMapLiteral node) {
    for (CollectionElement element in node.elements) {
      if (_nodeExits(element)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitSpreadElement(SpreadElement node) {
    return _nodeExits(node.expression);
  }

  @override
  bool visitSuperExpression(SuperExpression node) => false;

  @override
  bool visitSwitchCase(SwitchCase node) => _visitStatements(node.statements);

  @override
  bool visitSwitchDefault(SwitchDefault node) =>
      _visitStatements(node.statements);

  @override
  bool visitSwitchStatement(SwitchStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      bool hasDefault = false;
      bool hasNonExitingCase = false;
      List<SwitchMember> members = node.members;
      for (int i = 0; i < members.length; i++) {
        SwitchMember switchMember = members[i];
        if (switchMember is SwitchDefault) {
          hasDefault = true;
          // If this is the last member and there are no statements, then it
          // does not exit.
          if (switchMember.statements.isEmpty && i + 1 == members.length) {
            hasNonExitingCase = true;
            continue;
          }
        }
        // For switch members with no statements, don't visit the children.
        // Otherwise, if there children statements don't exit, mark this as a
        // non-exiting case.
        if (switchMember.statements.isNotEmpty && !switchMember.accept(this)!) {
          hasNonExitingCase = true;
        }
      }
      if (hasNonExitingCase) {
        return false;
      }
      // As all cases exit, return whether that list includes `default`.
      return hasDefault;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  @override
  bool visitThisExpression(ThisExpression node) => false;

  @override
  bool visitThrowExpression(ThrowExpression node) => true;

  @override
  bool visitTryStatement(TryStatement node) {
    if (_nodeExits(node.finallyBlock)) {
      return true;
    }
    if (!_nodeExits(node.body)) {
      return false;
    }
    for (CatchClause c in node.catchClauses) {
      if (!_nodeExits(c.body)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool visitTypeLiteral(TypeLiteral node) => _nodeExits(node.type);

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    var initializer = node.initializer;
    if (initializer != null) {
      return initializer.accept(this)!;
    }
    return false;
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) =>
      _visitVariableDeclarations(node.variables);

  @override
  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    NodeList<VariableDeclaration> variables = node.variables.variables;
    for (int i = 0; i < variables.length; i++) {
      if (variables[i].accept(this)!) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitWhileStatement(WhileStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      Expression conditionExpression = node.condition;
      if (conditionExpression.accept(this)!) {
        return true;
      }
      node.body.accept(this);
      // TODO(jwren) Do we want to take all constant expressions into account?
      if (conditionExpression is BooleanLiteral) {
        // If while(true), and the body doesn't have a break, then return true.
        // The body might be found to exit, but if there are any break
        // statements, then it is a faulty finding. In other words:
        //
        // * If the body exits, and does not contain a break statement, then
        //   it exits.
        // * If the body does not exit, and does not contain a break statement,
        //   then it loops infinitely (also an exit).
        //
        // As both conditions forbid any break statements to be found, the logic
        // just boils down to checking [_enclosingBlockContainsBreak].
        if (conditionExpression.value && !_enclosingBlockContainsBreak) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  @override
  bool visitYieldStatement(YieldStatement node) => _nodeExits(node.expression);

  /// If the given [expression] has a known Boolean value, return the known
  /// value, otherwise return `null`.
  bool? _knownConditionValue(Expression conditionExpression) {
    // TODO(jwren) Do we want to take all constant expressions into account?
    if (conditionExpression is BooleanLiteral) {
      return conditionExpression.value;
    }
    return null;
  }

  /// Return `true` if the given [node] exits.
  bool _nodeExits(AstNode? node) {
    if (node == null) {
      return false;
    }
    return node.accept(this)!;
  }

  bool _visitExpressions(NodeList<Expression> expressions) {
    for (int i = expressions.length - 1; i >= 0; i--) {
      if (expressions[i].accept(this)!) {
        return true;
      }
    }
    return false;
  }

  bool _visitStatements(NodeList<Statement> statements) {
    for (int i = 0; i < statements.length; i++) {
      if (statements[i].accept(this)!) {
        return true;
      }
    }
    return false;
  }

  bool _visitVariableDeclarations(
      NodeList<VariableDeclaration> variableDeclarations) {
    for (int i = variableDeclarations.length - 1; i >= 0; i--) {
      if (variableDeclarations[i].accept(this)!) {
        return true;
      }
    }
    return false;
  }

  /// Return `true` if the given [node] exits.
  static bool exits(AstNode node) {
    return ExitDetector()._nodeExits(node);
  }

  static bool _elementExits(Element? element) {
    if (element is ExecutableElement) {
      var declaration = element.declaration;
      return declaration.hasAlwaysThrows ||
          identical(declaration.returnType, NeverTypeImpl.instance);
    }

    return false;
  }
}
