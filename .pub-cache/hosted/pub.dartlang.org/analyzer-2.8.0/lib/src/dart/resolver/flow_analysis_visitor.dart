// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart' show TypeSystemImpl;
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';

/// Data gathered by flow analysis, retained for testing purposes.
class FlowAnalysisDataForTesting {
  /// The list of nodes, [Expression]s or [Statement]s, that cannot be reached,
  /// for example because a previous statement always exits.
  final List<AstNode> unreachableNodes = [];

  /// The list of [FunctionBody]s that don't complete, for example because
  /// there is a `return` statement at the end of the function body block.
  final List<FunctionBody> functionBodiesThatDontComplete = [];

  /// The list of references to variables, where a variable is read, and
  /// is not definitely assigned.
  final List<SimpleIdentifier> notDefinitelyAssigned = [];

  /// The list of references to variables, where a variable is read, and
  /// is definitely assigned.
  final List<SimpleIdentifier> definitelyAssigned = [];

  /// The list of references to variables, where a variable is written, and
  /// is definitely unassigned.
  final List<SimpleIdentifier> definitelyUnassigned = [];

  /// For each top level or class level declaration, the assigned variables
  /// information that was computed for it.
  final Map<AstNode, AssignedVariablesForTesting<AstNode, PromotableElement>>
      assignedVariables = {};

  /// For each expression that led to an error because it was not promoted, a
  /// string describing the reason it was not promoted.
  Map<SyntacticEntity, String> nonPromotionReasons = {};

  /// For each auxiliary AST node pointed to by a non-promotion reason, a string
  /// describing the non-promotion reason pointing to it.
  Map<AstNode, String> nonPromotionReasonTargets = {};
}

/// The helper for performing flow analysis during resolution.
///
/// It contains related precomputed data, result, and non-trivial pieces of
/// code that are independent from visiting AST during resolution, so can
/// be extracted.
class FlowAnalysisHelper {
  /// The reused instance for creating new [FlowAnalysis] instances.
  final TypeSystemTypeOperations _typeOperations;

  /// Precomputed sets of potentially assigned variables.
  AssignedVariables<AstNode, PromotableElement>? assignedVariables;

  /// The result for post-resolution stages of analysis, for testing only.
  final FlowAnalysisDataForTesting? dataForTesting;

  final bool isNonNullableByDefault;

  /// Indicates whether initializers of implicitly typed variables should be
  /// accounted for by SSA analysis.  (In an ideal world, they always would be,
  /// but due to https://github.com/dart-lang/language/issues/1785, they weren't
  /// always, and we need to be able to replicate the old behavior when
  /// analyzing old language versions).
  final bool respectImplicitlyTypedVarInitializers;

  /// The current flow, when resolving a function body, or `null` otherwise.
  FlowAnalysis<AstNode, Statement, Expression, PromotableElement, DartType>?
      flow;

  FlowAnalysisHelper(TypeSystemImpl typeSystem, bool retainDataForTesting,
      FeatureSet featureSet)
      : this._(TypeSystemTypeOperations(typeSystem),
            retainDataForTesting ? FlowAnalysisDataForTesting() : null,
            isNonNullableByDefault: featureSet.isEnabled(Feature.non_nullable),
            respectImplicitlyTypedVarInitializers:
                featureSet.isEnabled(Feature.constructor_tearoffs));

  FlowAnalysisHelper._(this._typeOperations, this.dataForTesting,
      {required this.isNonNullableByDefault,
      required this.respectImplicitlyTypedVarInitializers});

  LocalVariableTypeProvider get localVariableTypeProvider {
    return _LocalVariableTypeProvider(this);
  }

  void asExpression(AsExpression node) {
    if (flow == null) return;

    var expression = node.expression;
    var typeAnnotation = node.type;

    flow!.asExpression_end(expression, typeAnnotation.typeOrThrow);
  }

  void assignmentExpression(AssignmentExpression node) {
    if (flow == null) return null;

    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ) {
      flow!.ifNullExpression_rightBegin(node.leftHandSide, node.readType!);
    }
  }

  void assignmentExpression_afterRight(AssignmentExpression node) {
    if (flow == null) return null;

    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ) {
      flow!.ifNullExpression_end();
    }
  }

  void breakStatement(BreakStatement node) {
    var target = getLabelTarget(node, node.label?.staticElement);
    if (target != null) {
      flow!.handleBreak(target);
    }
  }

  /// Mark the [node] as unreachable if it is not covered by another node that
  /// is already known to be unreachable.
  void checkUnreachableNode(AstNode node) {
    if (flow == null) return;
    if (flow!.isReachable) return;

    if (dataForTesting != null) {
      dataForTesting!.unreachableNodes.add(node);
    }
  }

  void continueStatement(ContinueStatement node) {
    var target = getLabelTarget(node, node.label?.staticElement);
    if (target != null) {
      flow!.handleContinue(target);
    }
  }

  void executableDeclaration_enter(
      AstNode node, FormalParameterList? parameters, bool isClosure) {
    if (isClosure) {
      flow!.functionExpression_begin(node);
    }

    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        flow!.declare(parameter.declaredElement!, true);
      }
    }
  }

  void executableDeclaration_exit(FunctionBody body, bool isClosure) {
    if (isClosure) {
      flow!.functionExpression_end();
    }
    if (!flow!.isReachable) {
      dataForTesting?.functionBodiesThatDontComplete.add(body);
    }
  }

  void for_bodyBegin(AstNode node, Expression? condition) {
    flow?.for_bodyBegin(node is Statement ? node : null, condition);
  }

  void for_conditionBegin(AstNode node) {
    flow?.for_conditionBegin(node);
  }

  bool isDefinitelyAssigned(
    SimpleIdentifier node,
    PromotableElement element,
  ) {
    var isAssigned = flow!.isAssigned(element);

    if (dataForTesting != null) {
      if (isAssigned) {
        dataForTesting!.definitelyAssigned.add(node);
      } else {
        dataForTesting!.notDefinitelyAssigned.add(node);
      }
    }

    return isAssigned;
  }

  bool isDefinitelyUnassigned(
    SimpleIdentifier node,
    PromotableElement element,
  ) {
    var isUnassigned = flow!.isUnassigned(element);

    if (dataForTesting != null && isUnassigned) {
      dataForTesting!.definitelyUnassigned.add(node);
    }

    return isUnassigned;
  }

  void isExpression(IsExpression node) {
    if (flow == null) return;

    var expression = node.expression;
    var typeAnnotation = node.type;

    flow!.isExpression_end(
      node,
      expression,
      node.notOperator != null,
      typeAnnotation.typeOrThrow,
    );
  }

  void labeledStatement_enter(LabeledStatement node) {
    if (flow == null) return;

    flow!.labeledStatement_begin(node);
  }

  void labeledStatement_exit(LabeledStatement node) {
    if (flow == null) return;

    flow!.labeledStatement_end();
  }

  void topLevelDeclaration_enter(AstNode node, FormalParameterList? parameters,
      {void Function(AstVisitor<Object?> visitor)? visit}) {
    assert(flow == null);
    assignedVariables = computeAssignedVariables(node, parameters,
        retainDataForTesting: dataForTesting != null, visit: visit);
    if (dataForTesting != null) {
      dataForTesting!.assignedVariables[node] = assignedVariables
          as AssignedVariablesForTesting<AstNode, PromotableElement>;
    }
    flow = isNonNullableByDefault
        ? FlowAnalysis<AstNode, Statement, Expression, PromotableElement,
                DartType>(_typeOperations, assignedVariables!,
            respectImplicitlyTypedVarInitializers:
                respectImplicitlyTypedVarInitializers)
        : FlowAnalysis<AstNode, Statement, Expression, PromotableElement,
            DartType>.legacy(_typeOperations, assignedVariables!);
  }

  void topLevelDeclaration_exit() {
    // Set this.flow to null before doing any clean-up so that if an exception
    // is raised, the state is already updated correctly, and we don't have
    // cascading failures.
    final flow = this.flow;
    this.flow = null;
    assignedVariables = null;

    flow!.finish();
  }

  /// Transfers any test data that was recorded for [oldNode] so that it is now
  /// associated with [newNode].  We need to do this when doing AST rewriting,
  /// so that test data can be found using the rewritten tree.
  void transferTestData(AstNode oldNode, AstNode newNode) {
    final dataForTesting = this.dataForTesting;
    if (dataForTesting != null) {
      var oldNonPromotionReasons = dataForTesting.nonPromotionReasons[oldNode];
      if (oldNonPromotionReasons != null) {
        dataForTesting.nonPromotionReasons[newNode] = oldNonPromotionReasons;
      }
    }
  }

  void variableDeclarationList(VariableDeclarationList node) {
    if (flow != null) {
      var variables = node.variables;
      for (var i = 0; i < variables.length; ++i) {
        var variable = variables[i];
        flow!.declare(variable.declaredElement as PromotableElement,
            variable.initializer != null);
      }
    }
  }

  /// Computes the [AssignedVariables] map for the given [node].
  static AssignedVariables<AstNode, PromotableElement> computeAssignedVariables(
      AstNode node, FormalParameterList? parameters,
      {bool retainDataForTesting = false,
      void Function(AstVisitor<Object?> visitor)? visit}) {
    AssignedVariables<AstNode, PromotableElement> assignedVariables =
        retainDataForTesting
            ? AssignedVariablesForTesting()
            : AssignedVariables();
    var assignedVariablesVisitor = _AssignedVariablesVisitor(assignedVariables);
    assignedVariablesVisitor._declareParameters(parameters);
    if (visit != null) {
      visit(assignedVariablesVisitor);
    } else {
      node.visitChildren(assignedVariablesVisitor);
    }
    assignedVariables.finish();
    return assignedVariables;
  }

  /// Return the target of the `break` or `continue` statement with the
  /// [element] label. The [element] might be `null` (when the statement does
  /// not specify a label), so the default enclosing target is returned.
  static Statement? getLabelTarget(AstNode? node, Element? element) {
    for (; node != null; node = node.parent) {
      if (element == null) {
        if (node is DoStatement ||
            node is ForStatement ||
            node is SwitchStatement ||
            node is WhileStatement) {
          return node as Statement;
        }
      } else {
        if (node is LabeledStatement) {
          if (_hasLabel(node.labels, element)) {
            var statement = node.statement;
            if (statement is Block ||
                statement is IfStatement ||
                statement is TryStatement) {
              return node;
            }
            return statement;
          }
        }
        if (node is SwitchStatement) {
          for (var member in node.members) {
            if (_hasLabel(member.labels, element)) {
              return node;
            }
          }
        }
      }
    }
    return null;
  }

  static bool _hasLabel(List<Label> labels, Element element) {
    for (var nodeLabel in labels) {
      if (identical(nodeLabel.label.staticElement, element)) {
        return true;
      }
    }
    return false;
  }
}

/// Override of [FlowAnalysisHelper] that invokes methods of
/// [MigrationResolutionHooks] when appropriate.
class FlowAnalysisHelperForMigration extends FlowAnalysisHelper {
  final MigrationResolutionHooks migrationResolutionHooks;

  FlowAnalysisHelperForMigration(TypeSystemImpl typeSystem,
      this.migrationResolutionHooks, FeatureSet featureSet)
      : super(typeSystem, false, featureSet);

  @override
  void topLevelDeclaration_enter(AstNode node, FormalParameterList? parameters,
      {void Function(AstVisitor<Object?> visitor)? visit}) {
    super.topLevelDeclaration_enter(node, parameters, visit: visit);
    migrationResolutionHooks.setFlowAnalysis(flow);
  }

  @override
  void topLevelDeclaration_exit() {
    super.topLevelDeclaration_exit();
    migrationResolutionHooks.setFlowAnalysis(null);
  }
}

class TypeSystemTypeOperations
    extends TypeOperations<PromotableElement, DartType> {
  final TypeSystemImpl typeSystem;

  TypeSystemTypeOperations(this.typeSystem);

  @override
  TypeClassification classifyType(DartType type) {
    if (isSubtypeOf(type, typeSystem.typeProvider.objectType)) {
      return TypeClassification.nonNullable;
    } else if (isSubtypeOf(type, typeSystem.typeProvider.nullType)) {
      return TypeClassification.nullOrEquivalent;
    } else {
      return TypeClassification.potentiallyNullable;
    }
  }

  @override
  DartType factor(DartType from, DartType what) {
    return typeSystem.factor(from, what);
  }

  @override
  bool isNever(DartType type) {
    return typeSystem.isBottom(type);
  }

  @override
  bool isSameType(covariant TypeImpl type1, covariant TypeImpl type2) {
    return type1 == type2;
  }

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return typeSystem.isSubtypeOf(leftType, rightType);
  }

  @override
  bool isTypeParameterType(DartType type) => type is TypeParameterType;

  @override
  DartType promoteToNonNull(DartType type) {
    return typeSystem.promoteToNonNull(type);
  }

  @override
  DartType? tryPromoteToType(DartType to, DartType from) {
    return typeSystem.tryPromoteToType(to, from);
  }

  @override
  DartType variableType(PromotableElement variable) {
    return variable.type;
  }
}

/// The visitor that gathers local variables that are potentially assigned
/// in corresponding statements, such as loops, `switch` and `try`.
class _AssignedVariablesVisitor extends RecursiveAstVisitor<void> {
  final AssignedVariables<AstNode, PromotableElement> assignedVariables;

  _AssignedVariablesVisitor(this.assignedVariables);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;

    super.visitAssignmentExpression(node);

    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is PromotableElement) {
        assignedVariables.write(element);
      }
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.AMPERSAND_AMPERSAND) {
      node.leftOperand.accept(this);
      assignedVariables.beginNode();
      node.rightOperand.accept(this);
      assignedVariables.endNode(node);
    } else {
      super.visitBinaryExpression(node);
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    for (var identifier in [
      node.exceptionParameter,
      node.stackTraceParameter
    ]) {
      if (identifier != null) {
        assignedVariables
            .declare(identifier.staticElement as PromotableElement);
      }
    }
    super.visitCatchClause(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    assignedVariables.beginNode();
    node.thenExpression.accept(this);
    assignedVariables.endNode(node);
    node.elseExpression.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    throw StateError('Should not visit top level declarations');
  }

  @override
  void visitDoStatement(DoStatement node) {
    assignedVariables.beginNode();
    super.visitDoStatement(node);
    assignedVariables.endNode(node);
  }

  @override
  void visitForElement(ForElement node) {
    _handleFor(node, node.forLoopParts, node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    _handleFor(node, node.forLoopParts, node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is CompilationUnit) {
      throw StateError('Should not visit top level declarations');
    }
    assignedVariables.beginNode();
    _declareParameters(node.functionExpression.parameters);
    super.visitFunctionDeclaration(node);
    assignedVariables.endNode(node, isClosureOrLateVariableInitializer: true);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // A FunctionExpression just inside a FunctionDeclaration is an analyzer
      // artifact--it doesn't correspond to a separate closure.  So skip our
      // usual processing.
      return super.visitFunctionExpression(node);
    }
    assignedVariables.beginNode();
    _declareParameters(node.parameters);
    super.visitFunctionExpression(node);
    assignedVariables.endNode(node, isClosureOrLateVariableInitializer: true);
  }

  @override
  void visitIfElement(IfElement node) {
    node.condition.accept(this);
    assignedVariables.beginNode();
    node.thenElement.accept(this);
    assignedVariables.endNode(node);
    node.elseElement?.accept(this);
  }

  @override
  void visitIfStatement(IfStatement node) {
    node.condition.accept(this);
    assignedVariables.beginNode();
    node.thenStatement.accept(this);
    assignedVariables.endNode(node);
    node.elseStatement?.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    throw StateError('Should not visit top level declarations');
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    super.visitPostfixExpression(node);
    if (node.operator.type.isIncrementOperator) {
      var operand = node.operand;
      if (operand is SimpleIdentifier) {
        var element = operand.staticElement;
        if (element is PromotableElement) {
          assignedVariables.write(element);
        }
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    super.visitPrefixExpression(node);
    if (node.operator.type.isIncrementOperator) {
      var operand = node.operand;
      if (operand is SimpleIdentifier) {
        var element = operand.staticElement;
        if (element is PromotableElement) {
          assignedVariables.write(element);
        }
      }
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is PromotableElement &&
        node.inGetterContext() &&
        node.parent is! FormalParameter &&
        node.parent is! CatchClause) {
      assignedVariables.read(element);
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    var expression = node.expression;
    var members = node.members;

    expression.accept(this);

    assignedVariables.beginNode();
    members.accept(this);
    assignedVariables.endNode(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    var finallyBlock = node.finallyBlock;
    assignedVariables.beginNode(); // Begin info for [node].
    assignedVariables.beginNode(); // Begin info for [node.body].
    node.body.accept(this);
    assignedVariables.endNode(node.body);

    node.catchClauses.accept(this);
    assignedVariables.endNode(node);

    finallyBlock?.accept(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var grandParent = node.parent!.parent;
    if (grandParent is TopLevelVariableDeclaration ||
        grandParent is FieldDeclaration) {
      throw StateError('Should not visit top level declarations');
    }
    var declaredElement = node.declaredElement as PromotableElement;
    assignedVariables.declare(declaredElement);
    if (declaredElement.isLate && node.initializer != null) {
      assignedVariables.beginNode();
      super.visitVariableDeclaration(node);
      assignedVariables.endNode(node, isClosureOrLateVariableInitializer: true);
    } else {
      super.visitVariableDeclaration(node);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    assignedVariables.beginNode();
    super.visitWhileStatement(node);
    assignedVariables.endNode(node);
  }

  void _declareParameters(FormalParameterList? parameters) {
    if (parameters == null) return;
    for (var parameter in parameters.parameters) {
      assignedVariables.declare(parameter.declaredElement!);
    }
  }

  void _handleFor(AstNode node, ForLoopParts forLoopParts, AstNode body) {
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithExpression) {
        forLoopParts.initialization?.accept(this);
      } else if (forLoopParts is ForPartsWithDeclarations) {
        forLoopParts.variables.accept(this);
      } else {
        throw StateError('Unrecognized for loop parts');
      }

      assignedVariables.beginNode();
      forLoopParts.condition?.accept(this);
      body.accept(this);
      forLoopParts.updaters.accept(this);
      assignedVariables.endNode(node);
    } else if (forLoopParts is ForEachParts) {
      var iterable = forLoopParts.iterable;

      iterable.accept(this);

      if (forLoopParts is ForEachPartsWithIdentifier) {
        var element = forLoopParts.identifier.staticElement;
        if (element is PromotableElement) {
          assignedVariables.write(element);
        }
      } else if (forLoopParts is ForEachPartsWithDeclaration) {
        var variable = forLoopParts.loopVariable.declaredElement!;
        assignedVariables.declare(variable);
      } else {
        throw StateError('Unrecognized for loop parts');
      }
      assignedVariables.beginNode();
      body.accept(this);
      assignedVariables.endNode(node);
    } else {
      throw StateError('Unrecognized for loop parts');
    }
  }
}

/// The flow analysis based implementation of [LocalVariableTypeProvider].
class _LocalVariableTypeProvider implements LocalVariableTypeProvider {
  final FlowAnalysisHelper _manager;

  _LocalVariableTypeProvider(this._manager);

  @override
  DartType getType(SimpleIdentifier node, {required bool isRead}) {
    var variable = node.staticElement as VariableElement;
    if (variable is PromotableElement) {
      var promotedType = isRead
          ? _manager.flow?.variableRead(node, variable)
          : _manager.flow?.promotedType(variable);
      if (promotedType != null) return promotedType;
    }
    return variable.type;
  }
}
