// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/exit_detector.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';

typedef _CatchClausesVerifierReporter = void Function(
  CatchClause first,
  CatchClause last,
  ErrorCode,
  List<Object> arguments,
);

/// A visitor that finds dead code, other than unreachable code that is
/// handled in [NullSafetyDeadCodeVerifier] or [LegacyDeadCodeVerifier].
class DeadCodeVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// The object used to track the usage of labels within a given label scope.
  _LabelTracker? _labelTracker;

  DeadCodeVerifier(this._errorReporter);

  @override
  void visitBreakStatement(BreakStatement node) {
    _labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    ExportElement? exportElement = node.element;
    if (exportElement != null) {
      // The element is null when the URI is invalid.
      LibraryElement? library = exportElement.exportedLibrary;
      if (library != null && !library.isSynthetic) {
        for (Combinator combinator in node.combinators) {
          _checkCombinator(library, combinator);
        }
      }
    }
    super.visitExportDirective(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    ImportElement? importElement = node.element;
    if (importElement != null) {
      // The element is null when the URI is invalid, but not when the URI is
      // valid but refers to a non-existent file.
      LibraryElement? library = importElement.importedLibrary;
      if (library != null && !library.isSynthetic) {
        for (Combinator combinator in node.combinators) {
          _checkCombinator(library, combinator);
        }
      }
    }
    super.visitImportDirective(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _withLabelTracker(node.labels, () {
      super.visitLabeledStatement(node);
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    List<Label> labels = <Label>[];
    for (SwitchMember member in node.members) {
      labels.addAll(member.labels);
    }
    _withLabelTracker(labels, () {
      super.visitSwitchStatement(node);
    });
  }

  /// Resolve the names in the given [combinator] in the scope of the given
  /// [library].
  void _checkCombinator(LibraryElement library, Combinator combinator) {
    Namespace namespace =
        NamespaceBuilder().createExportNamespaceForLibrary(library);
    NodeList<SimpleIdentifier> names;
    ErrorCode hintCode;
    if (combinator is HideCombinator) {
      names = combinator.hiddenNames;
      hintCode = HintCode.UNDEFINED_HIDDEN_NAME;
    } else {
      names = (combinator as ShowCombinator).shownNames;
      hintCode = HintCode.UNDEFINED_SHOWN_NAME;
    }
    for (SimpleIdentifier name in names) {
      String nameStr = name.name;
      Element? element = namespace.get(nameStr);
      element ??= namespace.get("$nameStr=");
      if (element == null) {
        _errorReporter
            .reportErrorForNode(hintCode, name, [library.identifier, nameStr]);
      }
    }
  }

  void _withLabelTracker(List<Label> labels, void Function() f) {
    var labelTracker = _LabelTracker(_labelTracker, labels);
    try {
      _labelTracker = labelTracker;
      f();
    } finally {
      for (Label label in labelTracker.unusedLabels()) {
        _errorReporter.reportErrorForNode(
            HintCode.UNUSED_LABEL, label, [label.label.name]);
      }
      _labelTracker = labelTracker.outerTracker;
    }
  }
}

/// A visitor that finds dead code.
class LegacyDeadCodeVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  ///  The type system for this visitor
  final TypeSystemImpl _typeSystem;

  /// Initialize a newly created dead code verifier that will report dead code
  /// to the given [errorReporter] and will use the given [typeSystem] if one is
  /// provided.
  LegacyDeadCodeVerifier(this._errorReporter,
      {required TypeSystemImpl typeSystem})
      : _typeSystem = typeSystem;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    bool isAmpAmp = operator.type == TokenType.AMPERSAND_AMPERSAND;
    bool isBarBar = operator.type == TokenType.BAR_BAR;
    if (isAmpAmp || isBarBar) {
      Expression lhsCondition = node.leftOperand;
      if (!_isDebugConstant(lhsCondition)) {
        var lhsResult = _getConstantBooleanValue(lhsCondition);
        if (lhsResult != null) {
          var value = lhsResult.value?.toBoolValue();
          if (value == true && isBarBar) {
            // Report error on "else" block: true || !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // Only visit the LHS:
            lhsCondition.accept(this);
            return;
          } else if (value == false && isAmpAmp) {
            // Report error on "if" block: false && !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // Only visit the LHS:
            lhsCondition.accept(this);
            return;
          }
        }
      }
      // How do we want to handle the RHS? It isn't dead code, but "pointless"
      // or "obscure"...
//            Expression rhsCondition = node.getRightOperand();
//            ValidResult rhsResult = getConstantBooleanValue(rhsCondition);
//            if (rhsResult != null) {
//              if (rhsResult == ValidResult.RESULT_TRUE && isBarBar) {
//                // report error on else block: !e! || true
//                errorReporter.reportError(HintCode.DEAD_CODE, node.getRightOperand());
//                // only visit the RHS:
//                rhsCondition?.accept(this);
//                return null;
//              } else if (rhsResult == ValidResult.RESULT_FALSE && isAmpAmp) {
//                // report error on if block: !e! && false
//                errorReporter.reportError(HintCode.DEAD_CODE, node.getRightOperand());
//                // only visit the RHS:
//                rhsCondition?.accept(this);
//                return null;
//              }
//            }
    }
    super.visitBinaryExpression(node);
  }

  /// For each block, this method reports and error on all statements between
  /// the end of the block and the first return statement (assuming there it is
  /// not at the end of the block.)
  @override
  void visitBlock(Block node) {
    NodeList<Statement> statements = node.statements;
    _checkForDeadStatementsInNodeList(statements);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    Expression conditionExpression = node.condition;
    conditionExpression.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      var result = _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value?.toBoolValue() == true) {
          // Report error on "else" block: true ? 1 : !2!
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.elseExpression);
          node.thenExpression.accept(this);
          return;
        } else {
          // Report error on "if" block: false ? !1! : 2
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenExpression);
          node.elseExpression.accept(this);
          return;
        }
      }
    }
    super.visitConditionalExpression(node);
  }

  @override
  void visitIfElement(IfElement node) {
    Expression conditionExpression = node.condition;
    conditionExpression.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      var result = _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value?.toBoolValue() == true) {
          // Report error on else block: if(true) {} else {!}
          var elseElement = node.elseElement;
          if (elseElement != null) {
            _errorReporter.reportErrorForNode(HintCode.DEAD_CODE, elseElement);
            node.thenElement.accept(this);
            return;
          }
        } else {
          // Report error on if block: if (false) {!} else {}
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenElement);
          node.elseElement?.accept(this);
          return;
        }
      }
    }
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    Expression conditionExpression = node.condition;
    conditionExpression.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      var result = _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value?.toBoolValue() == true) {
          // Report error on else block: if(true) {} else {!}
          var elseStatement = node.elseStatement;
          if (elseStatement != null) {
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, elseStatement);
            node.thenStatement.accept(this);
            return;
          }
        } else {
          // Report error on if block: if (false) {!} else {}
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenStatement);
          node.elseStatement?.accept(this);
          return;
        }
      }
    }
    super.visitIfStatement(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _checkForDeadStatementsInNodeList(node.statements, allowMandated: true);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _checkForDeadStatementsInNodeList(node.statements, allowMandated: true);
    super.visitSwitchDefault(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    node.body.accept(this);
    node.finallyBlock?.accept(this);

    var verifier = _CatchClausesVerifier(
      _typeSystem,
      (first, last, errorCode, arguments) {
        var offset = first.offset;
        var length = last.end - offset;
        _errorReporter.reportErrorForOffset(
          errorCode,
          offset,
          length,
          arguments,
        );
      },
      node.catchClauses,
    );
    for (var catchClause in node.catchClauses) {
      verifier.nextCatchClause(catchClause);
      if (verifier._done) {
        break;
      }
      catchClause.accept(this);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    Expression conditionExpression = node.condition;
    conditionExpression.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      var result = _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value?.toBoolValue() == false) {
          // Report error on while block: while (false) {!}
          _errorReporter.reportErrorForNode(HintCode.DEAD_CODE, node.body);
          return;
        }
      }
    }
    node.body.accept(this);
  }

  /// Given some list of [statements], loop through the list searching for dead
  /// statements. If [allowMandated] is true, then allow dead statements that
  /// are mandated by the language spec. This allows for a final break,
  /// continue, return, or throw statement at the end of a switch case, that are
  /// mandated by the language spec.
  void _checkForDeadStatementsInNodeList(NodeList<Statement> statements,
      {bool allowMandated = false}) {
    bool statementExits(Statement statement) {
      if (statement is BreakStatement) {
        return statement.label == null;
      } else if (statement is ContinueStatement) {
        return statement.label == null;
      }
      return ExitDetector.exits(statement);
    }

    int size = statements.length;
    for (int i = 0; i < size; i++) {
      Statement currentStatement = statements[i];
      currentStatement.accept(this);
      if (statementExits(currentStatement) && i != size - 1) {
        Statement nextStatement = statements[i + 1];
        Statement lastStatement = statements[size - 1];
        // If mandated statements are allowed, and only the last statement is
        // dead, and it's a BreakStatement, then assume it is a statement
        // mandated by the language spec, there to avoid a
        // CASE_BLOCK_NOT_TERMINATED error.
        if (allowMandated && i == size - 2) {
          if (_isMandatedSwitchCaseTerminatingStatement(nextStatement)) {
            return;
          }
        }
        int offset = nextStatement.offset;
        int length = lastStatement.end - offset;
        _errorReporter.reportErrorForOffset(HintCode.DEAD_CODE, offset, length);
        return;
      }
    }
  }

  /// Given some [expression], return [ValidResult.RESULT_TRUE] if it is `true`,
  /// [ValidResult.RESULT_FALSE] if it is `false`, or `null` if the expression
  /// is not a constant boolean value.
  EvaluationResultImpl? _getConstantBooleanValue(Expression expression) {
    if (expression is BooleanLiteral) {
      return EvaluationResultImpl(
        DartObjectImpl(
          _typeSystem,
          _typeSystem.typeProvider.boolType,
          BoolState.from(expression.value),
        ),
      );
    }

    // Don't consider situations where we could evaluate to a constant boolean
    // expression with the ConstantVisitor
    // else {
    // EvaluationResultImpl result = expression.accept(new ConstantVisitor());
    // if (result == ValidResult.RESULT_TRUE) {
    // return ValidResult.RESULT_TRUE;
    // } else if (result == ValidResult.RESULT_FALSE) {
    // return ValidResult.RESULT_FALSE;
    // }
    // return null;
    // }
    return null;
  }

  /// Return `true` if the given [expression] is resolved to a constant
  /// variable.
  bool _isDebugConstant(Expression expression) {
    Element? element;
    if (expression is Identifier) {
      element = expression.staticElement;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
    }
    if (element is PropertyAccessorElement) {
      PropertyInducingElement variable = element.variable;
      return variable.isConst;
    }
    return false;
  }

  static bool _isMandatedSwitchCaseTerminatingStatement(Statement node) {
    if (node is BreakStatement ||
        node is ContinueStatement ||
        node is ReturnStatement) {
      return true;
    }
    if (node is ExpressionStatement) {
      var expression = node.expression;
      if (expression is RethrowExpression || expression is ThrowExpression) {
        return true;
      }
    }
    return false;
  }
}

/// Helper for tracking dead code - [CatchClause]s and unreachable code.
///
/// [CatchClause]s are checked separately, as we visit AST we may make some
/// of them as dead, and record [_deadCatchClauseRanges].
///
/// When an unreachable node is found, and [_firstDeadNode] is `null`, we
/// set [_firstDeadNode], so start a new dead nodes interval. The dead code
/// interval ends when [flowEnd] is invoked with a node that is the start
/// node, or contains it. So, we end the end of the covering control flow.
class NullSafetyDeadCodeVerifier {
  final TypeSystemImpl _typeSystem;
  final ErrorReporter _errorReporter;
  final FlowAnalysisHelper? _flowAnalysis;

  /// The stack of verifiers of (potentially nested) try statements.
  final List<_CatchClausesVerifier> _catchClausesVerifiers = [];

  /// When a sequence [CatchClause]s is found to be dead, we don't want to
  /// report additional dead code inside of already dead code.
  final List<SourceRange> _deadCatchClauseRanges = [];

  /// When this field is `null`, we are in reachable code.
  /// Once we find the first unreachable node, we store it here.
  ///
  /// When this field is not `null`, and we see an unreachable node, this new
  /// node is ignored, because it continues the same dead code range.
  AstNode? _firstDeadNode;

  NullSafetyDeadCodeVerifier(
    this._typeSystem,
    this._errorReporter,
    this._flowAnalysis,
  );

  /// The [node] ends a basic block in the control flow. If [_firstDeadNode] is
  /// not `null`, and is covered by the [node], then we reached the end of
  /// the current dead code interval.
  void flowEnd(AstNode node) {
    var firstDeadNode = _firstDeadNode;
    if (firstDeadNode != null) {
      if (!_containsFirstDeadNode(node)) {
        return;
      }

      var parent = firstDeadNode.parent;
      if (parent is Assertion && identical(firstDeadNode, parent.message)) {
        // Don't report "dead code" for the message part of an assert statement,
        // because this causes nuisance warnings for redundant `!= null`
        // asserts.
      } else {
        // We know that [node] is the first dead node, or contains it.
        // So, technically the code code interval ends at the end of [node].
        // But we trim it to the last statement for presentation purposes.
        if (node != firstDeadNode) {
          if (node is FunctionDeclaration) {
            node = node.functionExpression.body;
          }
          if (node is FunctionExpression) {
            node = node.body;
          }
          if (node is MethodDeclaration) {
            node = node.body;
          }
          if (node is BlockFunctionBody) {
            node = node.block;
          }
          if (node is Block && node.statements.isNotEmpty) {
            node = node.statements.last;
          }
          if (node is SwitchMember && node.statements.isNotEmpty) {
            node = node.statements.last;
          }
        }

        var offset = firstDeadNode.offset;
        var length = node.end - offset;
        _errorReporter.reportErrorForOffset(HintCode.DEAD_CODE, offset, length);
      }

      _firstDeadNode = null;
    }
  }

  void tryStatementEnter(TryStatement node) {
    var verifier = _CatchClausesVerifier(
      _typeSystem,
      (first, last, errorCode, arguments) {
        var offset = first.offset;
        var length = last.end - offset;
        _errorReporter.reportErrorForOffset(
          errorCode,
          offset,
          length,
          arguments,
        );
        _deadCatchClauseRanges.add(SourceRange(offset, length));
      },
      node.catchClauses,
    );
    _catchClausesVerifiers.add(verifier);
  }

  void tryStatementExit(TryStatement node) {
    _catchClausesVerifiers.removeLast();
  }

  void verifyCatchClause(CatchClause node) {
    var verifier = _catchClausesVerifiers.last;
    if (verifier._done) return;

    verifier.nextCatchClause(node);
  }

  void visitNode(AstNode node) {
    // Comments are visited after bodies of functions.
    // So, they look unreachable, but this does not make sense.
    if (node is Comment) return;

    var flowAnalysis = _flowAnalysis;
    if (flowAnalysis == null) return;
    flowAnalysis.checkUnreachableNode(node);

    // If the first dead node is not `null`, even if this new new node is
    // unreachable, we can ignore it as it is part of the same dead code
    // range anyway.
    if (_firstDeadNode != null) return;

    var flow = flowAnalysis.flow;
    if (flow == null) return;

    if (flow.isReachable) return;

    // If in a dead `CatchClause`, no need to report dead code.
    for (var range in _deadCatchClauseRanges) {
      if (range.contains(node.offset)) {
        return;
      }
    }

    _firstDeadNode = node;
  }

  bool _containsFirstDeadNode(AstNode parent) {
    for (var node = _firstDeadNode; node != null; node = node.parent) {
      if (node == parent) return true;
    }
    return false;
  }
}

class _CatchClausesVerifier {
  final TypeSystemImpl _typeSystem;
  final _CatchClausesVerifierReporter _errorReporter;
  final List<CatchClause> catchClauses;

  bool _done = false;
  final List<DartType> _visitedTypes = <DartType>[];

  _CatchClausesVerifier(
    this._typeSystem,
    this._errorReporter,
    this.catchClauses,
  );

  void nextCatchClause(CatchClause catchClause) {
    var currentType = catchClause.exceptionType?.type;

    // Found catch clause that doesn't have an exception type.
    // Generate an error on any following catch clauses.
    if (currentType == null || currentType.isDartCoreObject) {
      if (catchClause != catchClauses.last) {
        var index = catchClauses.indexOf(catchClause);
        _errorReporter(
          catchClauses[index + 1],
          catchClauses.last,
          HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH,
          const [],
        );
        _done = true;
      }
      return;
    }

    // An on-catch clause was found; verify that the exception type is not a
    // subtype of a previous on-catch exception type.
    for (var type in _visitedTypes) {
      if (_typeSystem.isSubtypeOf(currentType, type)) {
        _errorReporter(
          catchClause,
          catchClauses.last,
          HintCode.DEAD_CODE_ON_CATCH_SUBTYPE,
          [currentType, type],
        );
        _done = true;
        return;
      }
    }

    _visitedTypes.add(currentType);
  }
}

/// An object used to track the usage of labels within a single label scope.
class _LabelTracker {
  /// The tracker for the outer label scope.
  final _LabelTracker? outerTracker;

  /// The labels whose usage is being tracked.
  final List<Label> labels;

  /// A list of flags corresponding to the list of [labels] indicating whether
  /// the corresponding label has been used.
  late final List<bool> used;

  /// A map from the names of labels to the index of the label in [labels].
  final Map<String, int> labelMap = <String, int>{};

  /// Initialize a newly created label tracker.
  _LabelTracker(this.outerTracker, this.labels) {
    used = List.filled(labels.length, false);
    for (int i = 0; i < labels.length; i++) {
      labelMap[labels[i].label.name] = i;
    }
  }

  /// Record that the label with the given [labelName] has been used.
  void recordUsage(String? labelName) {
    if (labelName != null) {
      var index = labelMap[labelName];
      if (index != null) {
        used[index] = true;
      } else {
        outerTracker?.recordUsage(labelName);
      }
    }
  }

  /// Return the unused labels.
  Iterable<Label> unusedLabels() sync* {
    for (int i = 0; i < labels.length; i++) {
      if (!used[i]) {
        yield labels[i];
      }
    }
  }
}
