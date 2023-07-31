// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../flow_analysis/flow_analysis.dart';
import 'type_analysis_result.dart';
import 'type_operations.dart';

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchExpression]
/// or [TypeAnalyzer.analyzeSwitchStatement] about a single case head or
/// `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class CaseHeadOrDefaultInfo<Node extends Object, Expression extends Node,
    Variable extends Object> {
  /// For a `case` clause, the case pattern.  For a `default` clause, `null`.
  final Node? pattern;

  /// The pattern variables declared in [pattern]. Some of them are joins of
  /// individual pattern variable declarations. We don't know their types
  /// until we do type analysis. So, some of these variables might become
  /// not consistent.
  final Map<String, Variable> variables;

  /// For a `case` clause that has a guard clause, the expression following
  /// `when`.  Otherwise `null`.
  final Expression? guard;

  CaseHeadOrDefaultInfo({
    required this.pattern,
    required this.variables,
    this.guard,
  });
}

/// The location where the join of a pattern variable happens.
enum JoinedPatternVariableLocation {
  /// A single pattern, from `logical-or` patterns.
  singlePattern,

  /// A shared `case` scope, when multiple `case`s share the same body.
  sharedCaseScope,
}

class MapPatternEntry<Expression extends Object, Pattern extends Object> {
  final Expression key;
  final Pattern value;

  MapPatternEntry({
    required this.key,
    required this.value,
  });
}

class NamedType<Type extends Object> {
  final String name;
  final Type type;

  NamedType(this.name, this.type);
}

/// Information supplied by the client to [TypeAnalyzer.analyzeObjectPattern],
/// [TypeAnalyzer.analyzeRecordPattern], or
/// [TypeAnalyzer.analyzeRecordPatternSchema] about a single field in a record
/// or object pattern.
///
/// The client is free to `implement` or `extend` this class.
class RecordPatternField<Node extends Object, Pattern extends Object> {
  /// The client specific node from which this object was created.  It can be
  /// used for error reporting.
  final Node node;

  /// If not `null` then the field is named, otherwise it is positional.
  final String? name;
  final Pattern pattern;

  RecordPatternField({
    required this.node,
    required this.name,
    required this.pattern,
  });
}

class RecordType<Type extends Object> {
  final List<Type> positional;
  final List<NamedType<Type>> named;

  RecordType({
    required this.positional,
    required this.named,
  });
}

/// Kinds of relational pattern operators that shared analysis needs to
/// distinguish.
enum RelationalOperatorKind {
  /// The operator `==`
  equals,

  /// The operator `!=`
  notEquals,

  /// Any relational pattern operator other than `==` or `!=`
  other,
}

/// Information about a relational operator.
class RelationalOperatorResolution<Type extends Object> {
  final RelationalOperatorKind kind;
  final Type parameterType;
  final Type returnType;

  RelationalOperatorResolution({
    required this.kind,
    required this.parameterType,
    required this.returnType,
  });
}

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchExpression]
/// about an individual `case` or `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class SwitchExpressionMemberInfo<Node extends Object, Expression extends Node,
    Variable extends Object> {
  /// The [CaseOrDefaultHead] associated with this clause.
  final CaseHeadOrDefaultInfo<Node, Expression, Variable> head;

  /// The body of the `case` or `default` clause.
  final Expression expression;

  SwitchExpressionMemberInfo({required this.head, required this.expression});
}

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchStatement]
/// about an individual `case` or `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class SwitchStatementMemberInfo<Node extends Object, Statement extends Node,
    Expression extends Node, Variable extends Object> {
  /// The list of case heads for this case.
  ///
  /// The reason this is a list rather than a single head is because the front
  /// end merges together cases that share a body at parse time.
  final List<CaseHeadOrDefaultInfo<Node, Expression, Variable>> heads;

  /// Is `true` if the group of `case` and `default` clauses has a label.
  final bool hasLabels;

  /// The statements following this `case` or `default` clause.  If this list is
  /// empty, and this is not the last `case` or `default` clause, this clause
  /// will be considered to share a body with the `case` or `default` clause
  /// that follows.
  final List<Statement> body;

  /// The merged set of pattern variables from [heads]. If there is more than
  /// one element in [heads], these variables are joins of individual pattern
  /// variable declarations. Some of these variables might be already not
  /// consistent, because they are present not in every head. We don't know
  /// their types until we do type analysis. So, some of these variables
  /// might become not consistent.
  final Map<String, Variable> variables;

  SwitchStatementMemberInfo(this.heads, this.body, this.variables,
      {required this.hasLabels});
}

/// Type analysis logic to be shared between the analyzer and front end.  The
/// intention is that the client's main type inference visitor class can include
/// this mix-in and call shared analysis logic as needed.
///
/// Concrete methods in this mixin, typically named `analyzeX` for some `X`,
/// are intended to be called by the client in order to analyze an AST node (or
/// equivalent) of type `X`; a client's `visit` method shouldn't have to do much
/// than call the corresponding `analyze` method, passing in AST node's children
/// and other properties, possibly take some client-specific actions with the
/// returned value (such as storing intermediate inference results), and then
/// return the returned value up the call stack.
///
/// Abstract methods in this mixin are intended to be implemented by the client;
/// these are called by the `analyzeX` methods to report analysis results, to
/// query the client-specific information (e.g. to obtain the client's
/// representation of core types), and to trigger recursive analysis of child
/// AST nodes.
///
/// Note that calling an `analyzeX` method is guaranteed to call `dispatch` on
/// all its subexpressions.  However, we don't specify the precise order in
/// which this will happen, nor do we always specify which callbacks will be
/// invoked during analysis, because these details are considered part of the
/// implementation of type analysis, not its API.  Instead, we specify the
/// effect that each method has on a conceptual "stack" of entities.
///
/// In documentation, the entities in the stack are listed in low-to-high order.
/// So, for example, if the documentation says the stack contains "(K, L)", then
/// an entity of kind L is on the top of the stack, with an entity of kind K
/// under it.  This low-to-high order is used when describing pushes and pops
/// too, so, for example a method documented with "pushes (K, L)" pushes K
/// first, then L, whereas a method documented with "pops (K, L)" pops L first,
/// then K.
///
/// In the paragraph above, "K" and "L" are just variables for illustrating the
/// conventions.  The actual kinds used by the analyzer are concepts from the
/// language itself such as "Statement", "Expression", "Pattern", etc.  See the
/// `Kind` enum in `test/mini_ir.dart` for a discussion of all possible kinds of
/// stack entries.
///
/// If multiple stack entries share a kind, we will sometimes add a name to
/// clarify which stack entry is which, e.g. analyzeIfStatement pushes
/// "(Expression condition, Statement ifTrue, Statement ifFalse)".
///
/// We'll also use the convention that "n * K" represents n consecutive entities
/// in the stack, each with kind K.
///
/// The kind associated with all pushes and pops is statically known (and
/// documented, and unit tested), and entities never change from one kind to
/// another.  This fact gives the client considerable freedom in how to actually
/// represent the stack in practice; for example, they might choose to ignore
/// some kinds entirely, or represent certain kinds with a block of multiple
/// stack entries instead of just one.  Or they might choose to multiple stacks,
/// one for each kind.  It's also possible that some clients won't need to keep
/// a stack at all.
///
/// Reasons a client might want to actually have a stack include:
/// - Constructing a lowered intermediate representation of the code as a side
///   effect of analysis,
/// - Building up a symbolic representation of the program's runtime behavior,
/// - Or keeping track of AST nodes that need to be replaced (e.g. replacing an
///   `integer literal` node with a `double literal` node when int->double
///   conversion happens).
///
/// The unit tests in the `_fe_analyzer_shared` package associate a simple
/// intermediate representation with each stack entry, and also record the kind
/// of each entry in order to verify that when an entity is popped, it has the
/// expected kind.
mixin TypeAnalyzer<
    Node extends Object,
    Statement extends Node,
    Expression extends Node,
    Variable extends Object,
    Type extends Object,
    Pattern extends Node> {
  /// Returns the type `bool`.
  Type get boolType;

  /// Returns the type `double`.
  Type get doubleType;

  /// Returns the type `dynamic`.
  Type get dynamicType;

  TypeAnalyzerErrors<Node, Statement, Expression, Variable, Type, Pattern>?
      get errors;

  /// Returns the type used by the client in the case of errors.
  Type get errorType;

  /// Returns the client's [FlowAnalysis] object.
  FlowAnalysis<Node, Statement, Expression, Variable, Type> get flow;

  /// Returns the type `int`.
  Type get intType;

  /// Returns the type `Object?`.
  Type get objectQuestionType;

  /// The [Operations], used to access types, check subtyping, and query
  /// variable types.
  Operations<Variable, Type> get operations;

  /// Options affecting the behavior of [TypeAnalyzer].
  TypeAnalyzerOptions get options;

  /// Returns the unknown type context (`?`) used in type inference.
  Type get unknownType;

  /// Analyzes a non-wildcard variable pattern appearing in an assignment
  /// context.  [node] is the pattern itself, and [variable] is the variable
  /// being referenced.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// For wildcard patterns in an assignment context,
  /// [analyzeDeclaredVariablePattern] should be used instead.
  ///
  /// Stack effect: none.
  void analyzeAssignedVariablePattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Variable variable) {
    Map<Variable, Pattern>? assignedVariables = context.assignedVariables;
    if (assignedVariables != null) {
      Pattern? original = assignedVariables[variable];
      if (original == null) {
        assignedVariables[variable] = node;
      } else {
        errors?.duplicateAssignmentPatternVariable(
          variable: variable,
          original: original,
          duplicate: node,
        );
      }
    }

    Type variableDeclaredType = operations.variableType(variable);
    Node? irrefutableContext = context.irrefutableContext;
    assert(irrefutableContext != null,
        'Assigned variables must only appear in irrefutable pattern contexts');
    Type matchedType = flow.getMatchedValueType();
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedType, variableDeclaredType)) {
      errors?.patternTypeMismatchInIrrefutableContext(
          pattern: node,
          context: irrefutableContext,
          matchedType: matchedType,
          requiredType: variableDeclaredType);
    }
    flow.promoteForPattern(
        matchedType: matchedType, knownType: variableDeclaredType);
    flow.assignedVariablePattern(node, variable, matchedType);
  }

  /// Computes the type schema for a variable pattern appearing in an assignment
  /// context.  [variable] is the variable being referenced.
  Type analyzeAssignedVariablePatternSchema(Variable variable) =>
      flow.promotedType(variable) ?? operations.variableType(variable);

  /// Analyzes a cast pattern.  [innerPattern] is the sub-pattern] and
  /// [requiredType] is the type to cast to.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Pattern innerPattern).
  void analyzeCastPattern({
    required MatchContext<Node, Expression, Pattern, Type, Variable> context,
    required Pattern pattern,
    required Pattern innerPattern,
    required Type requiredType,
  }) {
    Type matchedValueType = flow.getMatchedValueType();
    bool matchedTypeIsSubtypeOfRequired = flow.promoteForPattern(
        matchedType: matchedValueType,
        knownType: requiredType,
        matchFailsIfWrongType: false);
    if (matchedTypeIsSubtypeOfRequired) {
      errors?.matchedTypeIsSubtypeOfRequired(
        pattern: pattern,
        matchedType: matchedValueType,
        requiredType: requiredType,
      );
    }
    // Note: although technically the inner pattern match of a cast-pattern
    // operates on the same value as the cast pattern does, we analyze it as
    // though it's a different value; this ensures that (a) the matched value
    // type when matching the inner pattern is precisely the cast type, and (b)
    // promotions triggered by the inner pattern have no effect outside the
    // cast.
    flow.pushSubpattern(requiredType);
    dispatchPattern(context.withUnnecessaryWildcardKind(null), innerPattern);
    // Stack: (Pattern)
    flow.popSubpattern();
  }

  /// Computes the type schema for a cast pattern.
  ///
  /// Stack effect: none.
  Type analyzeCastPatternSchema() => objectQuestionType;

  /// Analyzes a constant pattern.  [node] is the pattern itself, and
  /// [expression] is the constant expression.  Depending on the client's
  /// representation, [node] and [expression] might or might not be identical.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Returns the static type of [expression].
  ///
  /// Stack effect: pushes (Expression).
  Type analyzeConstantPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Node node,
      Expression expression) {
    // Stack: ()
    TypeAnalyzerErrors<Node, Node, Expression, Variable, Type, Pattern>?
        errors = this.errors;
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null) {
      errors?.refutablePatternInIrrefutableContext(
          pattern: node, context: irrefutableContext);
    }
    Type matchedType = flow.getMatchedValueType();
    Type expressionType = analyzeExpression(expression, matchedType);
    flow.constantPattern_end(expression, expressionType,
        patternsEnabled: options.patternsEnabled);
    // Stack: (Expression)
    if (errors != null && !options.patternsEnabled) {
      Expression? switchScrutinee = context.switchScrutinee;
      if (switchScrutinee != null) {
        bool nullSafetyEnabled = options.nullSafetyEnabled;
        bool matches = nullSafetyEnabled
            ? operations.isSubtypeOf(expressionType, matchedType)
            : operations.isAssignableTo(expressionType, matchedType);
        if (!matches) {
          errors.caseExpressionTypeMismatch(
              caseExpression: expression,
              scrutinee: switchScrutinee,
              caseExpressionType: expressionType,
              scrutineeType: matchedType,
              nullSafetyEnabled: nullSafetyEnabled);
        }
      }
    }
    return expressionType;
  }

  /// Computes the type schema for a constant pattern.
  ///
  /// Stack effect: none.
  Type analyzeConstantPatternSchema() {
    // Constant patterns are only allowed in refutable contexts, and refutable
    // contexts don't propagate a type schema into the scrutinee.  So this
    // code path is only reachable if the user's code contains errors.
    errors?.assertInErrorRecovery();
    return unknownType;
  }

  /// Analyzes a variable pattern in a non-assignment context.  [node] is the
  /// pattern itself, [variable] is the variable, [declaredType] is the
  /// explicitly declared type (if present).  [variableName] is the name of the
  /// variable; this is used to match up corresponding variables in the
  /// different branches of logical-or patterns, as well as different switch
  /// cases that share a body.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Returns the static type of the variable (possibly inferred).
  ///
  /// Stack effect: none.
  Type analyzeDeclaredVariablePattern(
    MatchContext<Node, Expression, Pattern, Type, Variable> context,
    Pattern node,
    Variable variable,
    String variableName,
    Type? declaredType,
  ) {
    Type matchedType = flow.getMatchedValueType();
    Type staticType =
        declaredType ?? variableTypeFromInitializerType(matchedType);
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedType, staticType)) {
      errors?.patternTypeMismatchInIrrefutableContext(
          pattern: node,
          context: irrefutableContext,
          matchedType: matchedType,
          requiredType: staticType);
    }
    flow.promoteForPattern(matchedType: matchedType, knownType: staticType);
    bool isImplicitlyTyped = declaredType == null;
    // TODO(paulberry): are we handling _isFinal correctly?
    int promotionKey = context.patternVariablePromotionKeys[variableName] =
        flow.declaredVariablePattern(
            matchedType: matchedType,
            staticType: staticType,
            initializerExpression: context.initializer,
            isFinal: context.isFinal || isVariableFinal(variable),
            isLate: context.isLate,
            isImplicitlyTyped: isImplicitlyTyped);
    setVariableType(variable, staticType);
    (context.componentVariables[variableName] ??= []).add(variable);
    flow.assignMatchedPatternVariable(variable, promotionKey);
    return staticType;
  }

  /// Computes the type schema for a variable pattern in a non-assignment
  /// context (or a wildcard pattern).  [declaredType] is the explicitly
  /// declared type (if present).
  ///
  /// Stack effect: none.
  Type analyzeDeclaredVariablePatternSchema(Type? declaredType) {
    return declaredType ?? unknownType;
  }

  /// Analyzes an expression.  [node] is the expression to analyze, and
  /// [context] is the type schema which should be used for type inference.
  ///
  /// Stack effect: pushes (Expression).
  Type analyzeExpression(Expression node, Type? context) {
    // Stack: ()
    if (context == null || operations.isDynamic(context)) {
      context = unknownType;
    }
    ExpressionTypeAnalysisResult<Type> result =
        dispatchExpression(node, context);
    // Stack: (Expression)
    if (operations.isNever(result.provisionalType)) {
      flow.handleExit();
    }
    return result.resolveShorting();
  }

  /// Analyzes a collection element of the form
  /// `if (expression case pattern) ifTrue` or
  /// `if (expression case pattern) ifTrue else ifFalse`.
  ///
  /// [node] should be the AST node for the entire element, [expression] for
  /// the expression, [pattern] for the pattern to match, [ifTrue] for the
  /// "then" branch, and [ifFalse] for the "else" branch (if present).
  ///
  /// [variables] should be a map from variable name to the variable the client
  /// wishes to use to represent that variable.  This is used to join together
  /// variables that appear in different branches of logical-or patterns.
  ///
  /// Stack effect: pushes (Expression scrutinee, Pattern, Expression guard,
  /// CollectionElement ifTrue, CollectionElement ifFalse).  If there is no
  /// `else` clause, the representation for `ifFalse` will be pushed by
  /// [handleNoCollectionElement].  If there is no guard, the representation
  /// for `guard` will be pushed by [handleNoGuard].
  void analyzeIfCaseElement({
    required Node node,
    required Expression expression,
    required Pattern pattern,
    required Map<String, Variable> variables,
    required Expression? guard,
    required Node ifTrue,
    required Node? ifFalse,
    required Object? context,
  }) {
    // Stack: ()
    flow.ifCaseStatement_begin();
    Type initializerType = analyzeExpression(expression, unknownType);
    flow.ifCaseStatement_afterExpression(expression, initializerType);
    // Stack: (Expression)
    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    // TODO(paulberry): rework handling of isFinal
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: false,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );
    // Stack: (Expression, Pattern)
    _finishJoinedPatternVariables(
        variables, componentVariables, patternVariablePromotionKeys,
        location: JoinedPatternVariableLocation.singlePattern);
    if (guard != null) {
      _checkGuardType(guard, analyzeExpression(guard, boolType));
    } else {
      handleNoGuard(node, 0);
    }
    // Stack: (Expression, Pattern, Guard)
    flow.ifCaseStatement_thenBegin(guard);
    _analyzeIfElementCommon(node, ifTrue, ifFalse, context);
  }

  /// Analyzes a statement of the form `if (expression case pattern) ifTrue` or
  /// `if (expression case pattern) ifTrue else ifFalse`.
  ///
  /// [node] should be the AST node for the entire statement, [expression] for
  /// the expression, [pattern] for the pattern to match, [ifTrue] for the
  /// "then" branch, and [ifFalse] for the "else" branch (if present).
  ///
  /// Returns the static type of [expression].
  ///
  /// Stack effect: pushes (Expression scrutinee, Pattern, Expression guard,
  /// Statement ifTrue, Statement ifFalse).  If there is no `else` clause, the
  /// representation for `ifFalse` will be pushed by [handleNoStatement].  If
  /// there is no guard, the representation for `guard` will be pushed by
  /// [handleNoGuard].
  Type analyzeIfCaseStatement(
    Statement node,
    Expression expression,
    Pattern pattern,
    Expression? guard,
    Statement ifTrue,
    Statement? ifFalse,
    Map<String, Variable> variables,
  ) {
    // Stack: ()
    flow.ifCaseStatement_begin();
    Type initializerType = analyzeExpression(expression, unknownType);
    flow.ifCaseStatement_afterExpression(expression, initializerType);
    // Stack: (Expression)
    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    // TODO(paulberry): rework handling of isFinal
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: false,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );

    _finishJoinedPatternVariables(
      variables,
      componentVariables,
      patternVariablePromotionKeys,
      location: JoinedPatternVariableLocation.singlePattern,
    );

    handle_ifCaseStatement_afterPattern(node: node);
    // Stack: (Expression, Pattern)
    if (guard != null) {
      _checkGuardType(guard, analyzeExpression(guard, boolType));
    } else {
      handleNoGuard(node, 0);
    }
    // Stack: (Expression, Pattern, Guard)
    flow.ifCaseStatement_thenBegin(guard);
    _analyzeIfCommon(node, ifTrue, ifFalse);
    return initializerType;
  }

  /// Analyzes a collection element of the form `if (condition) ifTrue` or
  /// `if (condition) ifTrue else ifFalse`.
  ///
  /// [node] should be the AST node for the entire element, [condition] for
  /// the condition expression, [ifTrue] for the "then" branch, and [ifFalse]
  /// for the "else" branch (if present).
  ///
  /// Stack effect: pushes (Expression condition, CollectionElement ifTrue,
  /// CollectionElement ifFalse).  Note that if there is no `else` clause, the
  /// representation for `ifFalse` will be pushed by
  /// [handleNoCollectionElement].
  void analyzeIfElement({
    required Node node,
    required Expression condition,
    required Node ifTrue,
    required Node? ifFalse,
    required Object? context,
  }) {
    // Stack: ()
    flow.ifStatement_conditionBegin();
    analyzeExpression(condition, boolType);
    handle_ifElement_conditionEnd(node);
    // Stack: (Expression condition)
    flow.ifStatement_thenBegin(condition, node);
    _analyzeIfElementCommon(node, ifTrue, ifFalse, context);
  }

  /// Analyzes a statement of the form `if (condition) ifTrue` or
  /// `if (condition) ifTrue else ifFalse`.
  ///
  /// [node] should be the AST node for the entire statement, [condition] for
  /// the condition expression, [ifTrue] for the "then" branch, and [ifFalse]
  /// for the "else" branch (if present).
  ///
  /// Stack effect: pushes (Expression condition, Statement ifTrue, Statement
  /// ifFalse).  Note that if there is no `else` clause, the representation for
  /// `ifFalse` will be pushed by [handleNoStatement].
  void analyzeIfStatement(Statement node, Expression condition,
      Statement ifTrue, Statement? ifFalse) {
    // Stack: ()
    flow.ifStatement_conditionBegin();
    analyzeExpression(condition, boolType);
    handle_ifStatement_conditionEnd(node);
    // Stack: (Expression condition)
    flow.ifStatement_thenBegin(condition, node);
    _analyzeIfCommon(node, ifTrue, ifFalse);
  }

  /// Analyzes an integer literal, given the type context [context].
  ///
  /// Stack effect: none.
  IntTypeAnalysisResult<Type> analyzeIntLiteral(Type context) {
    bool convertToDouble = !operations.isSubtypeOf(intType, context) &&
        operations.isSubtypeOf(doubleType, context);
    Type type = convertToDouble ? doubleType : intType;
    return new IntTypeAnalysisResult<Type>(
        type: type, convertedToDouble: convertToDouble);
  }

  /// Analyzes a list pattern.  [node] is the pattern itself, [elementType] is
  /// the list element type (if explicitly supplied), and [elements] is the
  /// list of subpatterns.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (n * Pattern) where n = elements.length.
  Type analyzeListPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      {Type? elementType,
      required List<Node> elements}) {
    Type valueType;
    Type matchedType = flow.getMatchedValueType();
    if (elementType != null) {
      valueType = elementType;
    } else {
      Type? listElementType = operations.matchListType(matchedType);
      if (listElementType != null) {
        valueType = listElementType;
      } else if (operations.isDynamic(matchedType)) {
        valueType = dynamicType;
      } else {
        valueType = objectQuestionType;
      }
    }
    Type requiredType = listType(valueType);
    flow.promoteForPattern(
        matchedType: matchedType,
        knownType: requiredType,
        matchMayFailEvenIfCorrectType: true);
    // Stack: ()
    Node? previousRestPattern;
    for (Node element in elements) {
      if (isRestPatternElement(element)) {
        if (previousRestPattern != null) {
          errors?.duplicateRestPattern(
            mapOrListPattern: node,
            original: previousRestPattern,
            duplicate: element,
          );
        }
        previousRestPattern = element;
        Pattern? subPattern = getRestPatternElementPattern(element);
        if (subPattern != null) {
          Type subPatternMatchedType = requiredType;
          flow.pushSubpattern(subPatternMatchedType);
          dispatchPattern(
              context.withUnnecessaryWildcardKind(null), subPattern);
          flow.popSubpattern();
        }
        handleListPatternRestElement(node, element);
      } else {
        flow.pushSubpattern(valueType);
        dispatchPattern(context.withUnnecessaryWildcardKind(null), element);
        flow.popSubpattern();
      }
    }
    // Stack: (n * Pattern) where n = elements.length
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedType, requiredType)) {
      errors?.patternTypeMismatchInIrrefutableContext(
          pattern: node,
          context: irrefutableContext,
          matchedType: matchedType,
          requiredType: requiredType);
    }
    return requiredType;
  }

  /// Computes the type schema for a list pattern.  [elementType] is the list
  /// element type (if explicitly supplied), and [elements] is the list of
  /// subpatterns.
  ///
  /// Stack effect: none.
  Type analyzeListPatternSchema({
    required Type? elementType,
    required List<Node> elements,
  }) {
    if (elementType != null) {
      return listType(elementType);
    }

    if (elements.isEmpty) {
      return listType(unknownType);
    }

    Type? currentGLB;
    for (Node element in elements) {
      Type? typeToAdd;
      if (isRestPatternElement(element)) {
        Pattern? subPattern = getRestPatternElementPattern(element);
        if (subPattern != null) {
          Type subPatternType = dispatchPatternSchema(subPattern);
          typeToAdd = operations.matchIterableType(subPatternType);
        }
      } else {
        typeToAdd = dispatchPatternSchema(element);
      }
      if (typeToAdd != null) {
        if (currentGLB == null) {
          currentGLB = typeToAdd;
        } else {
          currentGLB = operations.glb(currentGLB, typeToAdd);
        }
      }
    }
    currentGLB ??= unknownType;
    return listType(currentGLB);
  }

  /// Analyzes a logical-and pattern.  [node] is the pattern itself, and [lhs]
  /// and [rhs] are the left and right sides of the `&&` operator.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Pattern left, Pattern right)
  void analyzeLogicalAndPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Node lhs,
      Node rhs) {
    // Stack: ()
    dispatchPattern(
      context.withUnnecessaryWildcardKind(
        UnnecessaryWildcardKind.logicalAndPatternOperand,
      ),
      lhs,
    );
    // Stack: (Pattern left)
    dispatchPattern(
      context.withUnnecessaryWildcardKind(
        UnnecessaryWildcardKind.logicalAndPatternOperand,
      ),
      rhs,
    );
    // Stack: (Pattern left, Pattern right)
  }

  /// Computes the type schema for a logical-and pattern.  [lhs] and [rhs] are
  /// the left and right sides of the `&&` operator.
  ///
  /// Stack effect: none.
  Type analyzeLogicalAndPatternSchema(Node lhs, Node rhs) {
    return operations.glb(
        dispatchPatternSchema(lhs), dispatchPatternSchema(rhs));
  }

  /// Analyzes a logical-or pattern.  [node] is the pattern itself, and [lhs]
  /// and [rhs] are the left and right sides of the `||` operator.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Pattern left, Pattern right)
  void analyzeLogicalOrPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Node lhs,
      Node rhs) {
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null) {
      errors?.refutablePatternInIrrefutableContext(
          pattern: node, context: irrefutableContext);
      // Avoid cascading errors
      context = context.makeRefutable();
    }
    // Stack: ()
    flow.logicalOrPattern_begin();
    Map<String, int> leftPromotionKeys = {};
    dispatchPattern(
      context
          .withPromotionKeys(leftPromotionKeys)
          .withUnnecessaryWildcardKind(null),
      lhs,
    );
    // Stack: (Pattern left)
    // We'll use the promotion keys allocated during processing of the LHS as
    // the merged keys.
    for (MapEntry<String, int> entry in leftPromotionKeys.entries) {
      String variableName = entry.key;
      int promotionKey = entry.value;
      assert(!context.patternVariablePromotionKeys.containsKey(variableName));
      context.patternVariablePromotionKeys[variableName] = promotionKey;
    }
    flow.logicalOrPattern_afterLhs();
    handle_logicalOrPattern_afterLhs(node);
    Map<String, int> rightPromotionKeys = {};
    dispatchPattern(
      context
          .withPromotionKeys(rightPromotionKeys)
          .withUnnecessaryWildcardKind(null),
      rhs,
    );
    // Stack: (Pattern left, Pattern right)
    for (MapEntry<String, int> entry in rightPromotionKeys.entries) {
      String variableName = entry.key;
      int rightPromotionKey = entry.value;
      int? mergedPromotionKey = leftPromotionKeys[variableName];
      if (mergedPromotionKey == null) {
        // No matching variable on the LHS.  This is an error condition (which
        // has already been reported by VariableBinder).  For error recovery,
        // we still need to add the variable to
        // context.patternVariablePromotionKeys so that later analysis still
        // accounts for the presence of this variable.  So we just use the
        // promotion key from the RHS as the merged key.
        mergedPromotionKey = rightPromotionKey;
        assert(!context.patternVariablePromotionKeys.containsKey(variableName));
        context.patternVariablePromotionKeys[variableName] = mergedPromotionKey;
      } else {
        // Copy the promotion data over to the merged key.
        flow.copyPromotionData(
            sourceKey: rightPromotionKey, destinationKey: mergedPromotionKey);
      }
    }
    // Since the promotion data is now all stored in the merged keys in both
    // flow control branches, the normal join process will combine promotions
    // accordingly.
    flow.logicalOrPattern_end();
  }

  /// Computes the type schema for a logical-or pattern.  [lhs] and [rhs] are
  /// the left and right sides of the `|` or `&` operator.
  ///
  /// Stack effect: none.
  Type analyzeLogicalOrPatternSchema(Node lhs, Node rhs) {
    // Logical-or patterns are only allowed in refutable contexts, and
    // refutable contexts don't propagate a type schema into the scrutinee.
    // So this code path is only reachable if the user's code contains errors.
    errors?.assertInErrorRecovery();
    return unknownType;
  }

  /// Analyzes a map pattern.  [node] is the pattern itself, [typeArguments]
  /// contain explicit type arguments (if specified), and [elements] is the
  /// list of subpatterns.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (n * MapPatternElement) where n = elements.length.
  Type analyzeMapPattern(
    MatchContext<Node, Expression, Pattern, Type, Variable> context,
    Pattern node, {
    required MapPatternTypeArguments<Type>? typeArguments,
    required List<Node> elements,
  }) {
    Type keyType;
    Type valueType;
    Type keyContext;
    Type matchedType = flow.getMatchedValueType();
    if (typeArguments != null) {
      keyType = typeArguments.keyType;
      valueType = typeArguments.valueType;
      keyContext = keyType;
    } else {
      typeArguments = operations.matchMapType(matchedType);
      if (typeArguments != null) {
        keyType = typeArguments.keyType;
        valueType = typeArguments.valueType;
        keyContext = keyType;
      } else if (operations.isDynamic(matchedType)) {
        keyType = dynamicType;
        valueType = dynamicType;
        keyContext = unknownType;
      } else {
        keyType = objectQuestionType;
        valueType = objectQuestionType;
        keyContext = unknownType;
      }
    }
    Type requiredType = mapType(
      keyType: keyType,
      valueType: valueType,
    );
    flow.promoteForPattern(
        matchedType: matchedType,
        knownType: requiredType,
        matchMayFailEvenIfCorrectType: true);
    // Stack: ()

    bool hasDuplicateRestPatternReported = false;
    Node? previousRestPattern;
    for (Node element in elements) {
      if (isRestPatternElement(element)) {
        if (previousRestPattern != null) {
          errors?.duplicateRestPattern(
            mapOrListPattern: node,
            original: previousRestPattern,
            duplicate: element,
          );
          hasDuplicateRestPatternReported = true;
        }
        previousRestPattern = element;
      }
    }

    for (int i = 0; i < elements.length; i++) {
      Node element = elements[i];
      MapPatternEntry<Expression, Pattern>? entry = getMapPatternEntry(element);
      if (entry != null) {
        analyzeExpression(entry.key, keyContext);
        flow.pushSubpattern(valueType);
        dispatchPattern(
          context.withUnnecessaryWildcardKind(null),
          entry.value,
        );
        handleMapPatternEntry(node, element);
        flow.popSubpattern();
      } else {
        assert(isRestPatternElement(element));
        if (!hasDuplicateRestPatternReported) {
          if (i != elements.length - 1) {
            errors?.restPatternNotLastInMap(node: node, element: element);
          }
        }
        Pattern? subPattern = getRestPatternElementPattern(element);
        if (subPattern != null) {
          errors?.restPatternWithSubPatternInMap(node: node, element: element);
          flow.pushSubpattern(dynamicType);
          dispatchPattern(
            context.withUnnecessaryWildcardKind(null),
            subPattern,
          );
          flow.popSubpattern();
        }
        handleMapPatternRestElement(node, element);
      }
    }
    // Stack: (n * MapPatternElement) where n = elements.length
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedType, requiredType)) {
      errors?.patternTypeMismatchInIrrefutableContext(
        pattern: node,
        context: irrefutableContext,
        matchedType: matchedType,
        requiredType: requiredType,
      );
    }
    return requiredType;
  }

  /// Computes the type schema for a map pattern.  [typeArguments] contain
  /// explicit type arguments (if specified), and [elements] is the list of
  /// subpatterns.
  ///
  /// Stack effect: none.
  Type analyzeMapPatternSchema({
    required MapPatternTypeArguments<Type>? typeArguments,
    required List<Node> elements,
  }) {
    if (typeArguments != null) {
      return mapType(
        keyType: typeArguments.keyType,
        valueType: typeArguments.valueType,
      );
    }

    Type? valueType;
    for (Node element in elements) {
      MapPatternEntry<Expression, Pattern>? entry = getMapPatternEntry(element);
      if (entry != null) {
        Type entryValueType = dispatchPatternSchema(entry.value);
        if (valueType == null) {
          valueType = entryValueType;
        } else {
          valueType = operations.glb(valueType, entryValueType);
        }
      }
    }
    return mapType(
      keyType: unknownType,
      valueType: valueType ?? unknownType,
    );
  }

  /// Analyzes a null-check or null-assert pattern.  [node] is the pattern
  /// itself, [innerPattern] is the sub-pattern, and [isAssert] indicates
  /// whether this is a null-check or a null-assert pattern.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Pattern innerPattern).
  void analyzeNullCheckOrAssertPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Pattern innerPattern,
      {required bool isAssert}) {
    // Stack: ()
    Node? irrefutableContext = context.irrefutableContext;
    bool matchedTypeIsStrictlyNonNullable =
        flow.nullCheckOrAssertPattern_begin(isAssert: isAssert);
    if (irrefutableContext != null && !isAssert) {
      errors?.refutablePatternInIrrefutableContext(
          pattern: node, context: irrefutableContext);
      // Avoid cascading errors
      context = context.makeRefutable();
    } else if (matchedTypeIsStrictlyNonNullable) {
      errors?.matchedTypeIsStrictlyNonNullable(
        pattern: node,
        matchedType: flow.getMatchedValueType(),
      );
    }
    dispatchPattern(
      context.withUnnecessaryWildcardKind(null),
      innerPattern,
    );
    // Stack: (Pattern)
    flow.nullCheckOrAssertPattern_end();
  }

  /// Computes the type schema for a null-check or null-assert pattern.
  /// [innerPattern] is the sub-pattern and [isAssert] indicates whether this is
  /// a null-check or a null-assert pattern.
  ///
  /// Stack effect: none.
  Type analyzeNullCheckOrAssertPatternSchema(Pattern innerPattern,
      {required bool isAssert}) {
    if (isAssert) {
      return operations.makeNullable(dispatchPatternSchema(innerPattern));
    } else {
      // Null-check patterns are only allowed in refutable contexts, and
      // refutable contexts don't propagate a type schema into the scrutinee.
      // So this code path is only reachable if the user's code contains errors.
      errors?.assertInErrorRecovery();
      return unknownType;
    }
  }

  /// Analyzes an object pattern.  [node] is the pattern itself, and [fields]
  /// is the list of subpatterns.  The [requiredType] must be not `null` in
  /// irrefutable contexts, but can be `null` in refutable contexts, then
  /// [downwardInferObjectPatternRequiredType] is invoked to infer the type.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (n * Pattern) where n = fields.length.
  Type analyzeObjectPattern(
    MatchContext<Node, Expression, Pattern, Type, Variable> context,
    Pattern node, {
    required List<RecordPatternField<Node, Pattern>> fields,
  }) {
    _reportDuplicateRecordPatternFields(node, fields);

    Type matchedType = flow.getMatchedValueType();
    Type requiredType = downwardInferObjectPatternRequiredType(
      matchedType: matchedType,
      pattern: node,
    );
    flow.promoteForPattern(matchedType: matchedType, knownType: requiredType);

    // If the required type is `dynamic` or `Never`, then every getter is
    // treated as having the same type.
    Type? overridePropertyGetType;
    if (operations.isDynamic(requiredType) ||
        operations.isNever(requiredType)) {
      overridePropertyGetType = requiredType;
    }

    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedType, requiredType)) {
      errors?.patternTypeMismatchInIrrefutableContext(
        pattern: node,
        context: irrefutableContext,
        matchedType: matchedType,
        requiredType: requiredType,
      );
    }

    // Stack: ()
    for (RecordPatternField<Node, Pattern> field in fields) {
      Type propertyType = overridePropertyGetType ??
          resolveObjectPatternPropertyGet(
            receiverType: requiredType,
            field: field,
          );
      flow.pushSubpattern(propertyType);
      dispatchPattern(
        context.withUnnecessaryWildcardKind(null),
        field.pattern,
      );
      flow.popSubpattern();
    }
    // Stack: (n * Pattern) where n = fields.length

    return requiredType;
  }

  /// Computes the type schema for an object pattern.  [type] is the type
  /// specified with the object name, and with the type arguments applied.
  ///
  /// Stack effect: none.
  Type analyzeObjectPatternSchema(Type type) {
    return type;
  }

  /// Analyzes a patternAssignment expression of the form `pattern = rhs`.
  ///
  /// [node] should be the AST node for the entire expression, [pattern] for
  /// the pattern, and [rhs] for the right hand side.
  ///
  /// Stack effect: pushes (Expression, Pattern).
  PatternAssignmentAnalysisResult<Type> analyzePatternAssignment(
      Expression node, Pattern pattern, Expression rhs) {
    // Stack: ()
    Type patternSchema = dispatchPatternSchema(pattern);
    Type rhsType = analyzeExpression(rhs, patternSchema);
    // Stack: (Expression)
    flow.patternAssignment_afterRhs(rhs, rhsType);
    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: false,
        initializer: rhs,
        irrefutableContext: node,
        assignedVariables: <Variable, Pattern>{},
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );
    if (componentVariables.isNotEmpty) {
      // Declared pattern variables should never appear in a pattern assignment
      // so this should never happen.
      errors?.assertInErrorRecovery();
    }
    flow.patternAssignment_end();
    // Stack: (Expression, Pattern)
    return new PatternAssignmentAnalysisResult<Type>(
      patternSchema: patternSchema,
      type: rhsType,
    );
  }

  /// Analyzes a `pattern-for-in` statement or element.
  ///
  /// Statement:
  /// `for (<keyword> <pattern> in <expression>) <statement>`
  ///
  /// Element:
  /// `for (<keyword> <pattern> in <expression>) <body>`
  ///
  /// Stack effect: pushes (Expression, Pattern).
  void analyzePatternForIn({
    required Node node,
    required bool hasAwait,
    required Pattern pattern,
    required Expression expression,
    required void Function() dispatchBody,
  }) {
    // Stack: ()
    Type patternTypeSchema = dispatchPatternSchema(pattern);
    Type expressionTypeSchema = hasAwait
        ? streamType(patternTypeSchema)
        : iterableType(patternTypeSchema);
    Type expressionType = analyzeExpression(expression, expressionTypeSchema);
    // Stack: (Expression)

    Type? elementType = hasAwait
        ? operations.matchStreamType(expressionType)
        : operations.matchIterableType(expressionType);
    if (elementType == null) {
      if (operations.isDynamic(expressionType)) {
        elementType = dynamicType;
      } else {
        errors?.patternForInExpressionIsNotIterable(
          node: node,
          expression: expression,
          expressionType: expressionType,
        );
        elementType = dynamicType;
      }
    }
    flow.patternForIn_afterExpression(elementType);

    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: false,
        irrefutableContext: node,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );
    // Stack: (Expression, Pattern)

    flow.forEach_bodyBegin(node);
    dispatchBody();
    flow.forEach_end();
    flow.patternForIn_end();
  }

  /// Analyzes a patternVariableDeclaration node of the form
  /// `var pattern = initializer` or `final pattern = initializer`.
  ///
  /// [node] should be the AST node for the entire declaration, [pattern] for
  /// the pattern, and [initializer] for the initializer.  [isFinal] and
  /// [isLate] indicate whether this is a final declaration and/or a late
  /// declaration, respectively.
  ///
  /// Note that the only kind of pattern allowed in a late declaration is a
  /// variable pattern; [TypeAnalyzerErrors.patternDoesNotAllowLate] will be
  /// reported if any other kind of pattern is used.
  ///
  /// Returns the type schema of the [pattern].
  ///
  /// Stack effect: pushes (Expression, Pattern).
  Type analyzePatternVariableDeclaration(
      Node node, Pattern pattern, Expression initializer,
      {required bool isFinal, required bool isLate}) {
    // Stack: ()
    if (isLate && !isVariablePattern(pattern)) {
      errors?.patternDoesNotAllowLate(pattern: pattern);
    }
    if (isLate) {
      flow.lateInitializer_begin(node);
    }
    Type patternSchema = dispatchPatternSchema(pattern);
    Type initializerType = analyzeExpression(initializer, patternSchema);
    // Stack: (Expression)
    if (isLate) {
      flow.lateInitializer_end();
    }
    flow.patternVariableDeclaration_afterInitializer(
        initializer, initializerType);
    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: isFinal,
        isLate: isLate,
        initializer: initializer,
        irrefutableContext: node,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );
    _finishJoinedPatternVariables(
        {}, componentVariables, patternVariablePromotionKeys,
        location: JoinedPatternVariableLocation.singlePattern);
    flow.patternVariableDeclaration_end();
    // Stack: (Expression, Pattern)
    return patternSchema;
  }

  /// Analyzes a record pattern.  [node] is the pattern itself, and [fields]
  /// is the list of subpatterns.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (n * Pattern) where n = fields.length.
  Type analyzeRecordPattern(
    MatchContext<Node, Expression, Pattern, Type, Variable> context,
    Pattern node, {
    required List<RecordPatternField<Node, Pattern>> fields,
  }) {
    List<Type> demonstratedPositionalTypes = [];
    List<NamedType<Type>> demonstratedNamedTypes = [];
    void dispatchField(
      RecordPatternField<Node, Pattern> field,
      Type matchedType,
    ) {
      flow.pushSubpattern(matchedType);
      dispatchPattern(
        context.withUnnecessaryWildcardKind(null),
        field.pattern,
      );
      Type demonstratedType = flow.getMatchedValueType();
      String? name = field.name;
      if (name == null) {
        demonstratedPositionalTypes.add(demonstratedType);
      } else {
        demonstratedNamedTypes.add(new NamedType(name, demonstratedType));
      }
      flow.popSubpattern();
    }

    void dispatchFields(Type matchedType) {
      for (int i = 0; i < fields.length; i++) {
        dispatchField(fields[i], matchedType);
      }
    }

    _reportDuplicateRecordPatternFields(node, fields);

    // Build the required type.
    int requiredTypePositionalCount = 0;
    List<NamedType<Type>> requiredTypeNamedTypes = [];
    for (RecordPatternField<Node, Pattern> field in fields) {
      String? name = field.name;
      if (name == null) {
        requiredTypePositionalCount++;
      } else {
        requiredTypeNamedTypes.add(
          new NamedType(name, objectQuestionType),
        );
      }
    }
    Type requiredType = recordType(
      positional: new List.filled(
        requiredTypePositionalCount,
        objectQuestionType,
      ),
      named: requiredTypeNamedTypes,
    );
    Type matchedType = flow.getMatchedValueType();
    flow.promoteForPattern(matchedType: matchedType, knownType: requiredType);

    // Stack: ()
    RecordType<Type>? matchedRecordType = asRecordType(matchedType);
    if (matchedRecordType != null) {
      List<Type>? fieldTypes = _matchRecordTypeShape(fields, matchedRecordType);
      if (fieldTypes != null) {
        assert(fieldTypes.length == fields.length);
        for (int i = 0; i < fields.length; i++) {
          dispatchField(fields[i], fieldTypes[i]);
        }
      } else {
        dispatchFields(objectQuestionType);
      }
    } else if (operations.isDynamic(matchedType)) {
      dispatchFields(dynamicType);
    } else {
      dispatchFields(objectQuestionType);
    }
    // Stack: (n * Pattern) where n = fields.length

    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedType, requiredType)) {
      errors?.patternTypeMismatchInIrrefutableContext(
        pattern: node,
        context: irrefutableContext,
        matchedType: matchedType,
        requiredType: requiredType,
      );
    }

    Type demonstratedType = recordType(
        positional: demonstratedPositionalTypes, named: demonstratedNamedTypes);
    flow.promoteForPattern(
        matchedType: matchedType,
        knownType: demonstratedType,
        matchFailsIfWrongType: false);
    return requiredType;
  }

  /// Computes the type schema for a record pattern.
  ///
  /// Stack effect: none.
  Type analyzeRecordPatternSchema({
    required List<RecordPatternField<Node, Pattern>> fields,
  }) {
    List<Type> positional = [];
    List<NamedType<Type>> named = [];
    for (RecordPatternField<Node, Pattern> field in fields) {
      Type fieldType = dispatchPatternSchema(field.pattern);
      String? name = field.name;
      if (name != null) {
        named.add(new NamedType(name, fieldType));
      } else {
        positional.add(fieldType);
      }
    }
    return recordType(positional: positional, named: named);
  }

  /// Analyzes a relational pattern.  [node] is the pattern itself, and
  /// [operand] is a constant expression that will be passed to the relational
  /// operator.
  ///
  /// This method will invoke [resolveRelationalPatternOperator] to obtain
  /// information about the operator.
  ///
  /// Returns the type of the [operand].
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Expression).
  Type analyzeRelationalPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Expression operand) {
    // Stack: ()
    TypeAnalyzerErrors<Node, Node, Expression, Variable, Type, Pattern>?
        errors = this.errors;
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null) {
      errors?.refutablePatternInIrrefutableContext(
          pattern: node, context: irrefutableContext);
    }
    Type matchedValueType = flow.getMatchedValueType();
    RelationalOperatorResolution<Type>? operator =
        resolveRelationalPatternOperator(node, matchedValueType);
    Type operandContext = operator?.parameterType ?? unknownType;
    Type operandType = analyzeExpression(operand, operandContext);
    bool isEquality;
    switch (operator?.kind) {
      case RelationalOperatorKind.equals:
        isEquality = true;
        flow.equalityRelationalPattern_end(operand, operandType,
            notEqual: false);
        break;
      case RelationalOperatorKind.notEquals:
        isEquality = true;
        flow.equalityRelationalPattern_end(operand, operandType,
            notEqual: true);
        break;
      default:
        isEquality = false;
        flow.nonEqualityRelationalPattern_end();
        break;
    }
    // Stack: (Expression)
    if (errors != null && operator != null) {
      Type argumentType =
          isEquality ? operations.promoteToNonNull(operandType) : operandType;
      if (!operations.isAssignableTo(argumentType, operator.parameterType)) {
        errors.argumentTypeNotAssignable(
          argument: operand,
          argumentType: argumentType,
          parameterType: operator.parameterType,
        );
      }
      if (!operations.isAssignableTo(operator.returnType, boolType)) {
        errors.relationalPatternOperatorReturnTypeNotAssignableToBool(
          pattern: node,
          returnType: operator.returnType,
        );
      }
    }
    // TODO(johnniwinther): This doesn't scale. We probably need to pass more
    // information, for instance whether this was an erroneous case.
    return operandType;
  }

  /// Computes the type schema for a relational pattern.
  ///
  /// Stack effect: none.
  Type analyzeRelationalPatternSchema() {
    // Relational patterns are only allowed in refutable contexts, and refutable
    // contexts don't propagate a type schema into the scrutinee.  So this
    // code path is only reachable if the user's code contains errors.
    errors?.assertInErrorRecovery();
    return unknownType;
  }

  /// Analyzes an expression of the form `switch (expression) { cases }`.
  ///
  /// Stack effect: pushes (Expression, n * ExpressionCase), where n is the
  /// number of cases.
  SimpleTypeAnalysisResult<Type> analyzeSwitchExpression(
      Expression node, Expression scrutinee, int numCases, Type context) {
    // Stack: ()
    Type expressionType = analyzeExpression(scrutinee, unknownType);
    // Stack: (Expression)
    handleSwitchScrutinee(expressionType);
    flow.switchStatement_expressionEnd(null, scrutinee, expressionType);
    Type? lubType;
    for (int i = 0; i < numCases; i++) {
      // Stack: (Expression, i * ExpressionCase)
      SwitchExpressionMemberInfo<Node, Expression, Variable> memberInfo =
          getSwitchExpressionMemberInfo(node, i);
      flow.switchStatement_beginAlternatives();
      flow.switchStatement_beginAlternative();
      handleSwitchBeforeAlternative(node, caseIndex: i, subIndex: 0);
      Node? pattern = memberInfo.head.pattern;
      Expression? guard;
      if (pattern != null) {
        Map<String, List<Variable>> componentVariables = {};
        Map<String, int> patternVariablePromotionKeys = {};
        dispatchPattern(
          new MatchContext<Node, Expression, Pattern, Type, Variable>(
            isFinal: false,
            switchScrutinee: scrutinee,
            componentVariables: componentVariables,
            patternVariablePromotionKeys: patternVariablePromotionKeys,
          ),
          pattern,
        );
        _finishJoinedPatternVariables(
          memberInfo.head.variables,
          componentVariables,
          patternVariablePromotionKeys,
          location: JoinedPatternVariableLocation.singlePattern,
        );
        // Stack: (Expression, i * ExpressionCase, Pattern)
        guard = memberInfo.head.guard;
        bool hasGuard = guard != null;
        if (hasGuard) {
          _checkGuardType(guard, analyzeExpression(guard, boolType));
          // Stack: (Expression, i * ExpressionCase, Pattern, Expression)
        } else {
          handleNoGuard(node, i);
          // Stack: (Expression, i * ExpressionCase, Pattern, Expression)
        }
        handleCaseHead(node, caseIndex: i, subIndex: 0);
      } else {
        handleDefault(node, caseIndex: i, subIndex: 0);
      }
      flow.switchStatement_endAlternative(guard, {});
      flow.switchStatement_endAlternatives(null, hasLabels: false);
      // Stack: (Expression, i * ExpressionCase, CaseHead)
      Type type = analyzeExpression(memberInfo.expression, context);
      flow.switchStatement_afterCase();
      // Stack: (Expression, i * ExpressionCase, CaseHead, Expression)
      if (lubType == null) {
        lubType = type;
      } else {
        lubType = operations.lub(lubType, type);
      }
      finishExpressionCase(node, i);
      // Stack: (Expression, (i + 1) * ExpressionCase)
    }
    lubType ??= dynamicType;
    // Stack: (Expression, numCases * ExpressionCase)
    bool isProvenExhaustive = flow.switchStatement_end(true);
    if (options.errorOnSwitchExhaustiveness && !isProvenExhaustive) {
      errors?.nonExhaustiveSwitch(node: node, scrutineeType: expressionType);
    }
    return new SimpleTypeAnalysisResult<Type>(type: lubType);
  }

  /// Analyzes a statement of the form `switch (expression) { cases }`.
  ///
  /// Stack effect: pushes (Expression, n * StatementCase), where n is the
  /// number of cases after merging together cases that share a body.
  SwitchStatementTypeAnalysisResult<Type> analyzeSwitchStatement(
      Statement node, Expression scrutinee, final int numCases) {
    // Stack: ()
    Type scrutineeType = analyzeExpression(scrutinee, unknownType);
    // Stack: (Expression)
    handleSwitchScrutinee(scrutineeType);
    flow.switchStatement_expressionEnd(node, scrutinee, scrutineeType);
    bool hasDefault = false;
    bool lastCaseTerminates = true;
    for (int caseIndex = 0; caseIndex < numCases; caseIndex++) {
      // Stack: (Expression, numExecutionPaths * StatementCase)
      flow.switchStatement_beginAlternatives();
      // Stack: (Expression, numExecutionPaths * StatementCase,
      //         numHeads * CaseHead)
      SwitchStatementMemberInfo<Node, Statement, Expression, Variable>
          memberInfo = getSwitchStatementMemberInfo(node, caseIndex);
      List<CaseHeadOrDefaultInfo<Node, Expression, Variable>> heads =
          memberInfo.heads;
      for (int headIndex = 0; headIndex < heads.length; headIndex++) {
        CaseHeadOrDefaultInfo<Node, Expression, Variable> head =
            heads[headIndex];
        Node? pattern = head.pattern;
        flow.switchStatement_beginAlternative();
        handleSwitchBeforeAlternative(node,
            caseIndex: caseIndex, subIndex: headIndex);
        Expression? guard;
        if (pattern != null) {
          Map<String, List<Variable>> componentVariables = {};
          Map<String, int> patternVariablePromotionKeys = {};
          dispatchPattern(
            new MatchContext<Node, Expression, Pattern, Type, Variable>(
              isFinal: false,
              switchScrutinee: scrutinee,
              componentVariables: componentVariables,
              patternVariablePromotionKeys: patternVariablePromotionKeys,
            ),
            pattern,
          );
          _finishJoinedPatternVariables(
            head.variables,
            componentVariables,
            patternVariablePromotionKeys,
            location: JoinedPatternVariableLocation.singlePattern,
          );
          // Stack: (Expression, numExecutionPaths * StatementCase,
          //         numHeads * CaseHead, Pattern),
          guard = head.guard;
          if (guard != null) {
            _checkGuardType(guard, analyzeExpression(guard, boolType));
            // Stack: (Expression, numExecutionPaths * StatementCase,
            //         numHeads * CaseHead, Pattern, Expression),
          } else {
            handleNoGuard(node, caseIndex);
          }
          handleCaseHead(node, caseIndex: caseIndex, subIndex: headIndex);
        } else {
          hasDefault = true;
          handleDefault(node, caseIndex: caseIndex, subIndex: headIndex);
        }
        // Stack: (Expression, numExecutionPaths * StatementCase,
        //         numHeads * CaseHead),
        flow.switchStatement_endAlternative(guard, head.variables);
      }
      // Stack: (Expression, numExecutionPaths * StatementCase,
      //         numHeads * CaseHead)
      PatternVariableInfo<Variable> patternVariableInfo =
          flow.switchStatement_endAlternatives(node,
              hasLabels: memberInfo.hasLabels);
      Map<String, Variable> variables = memberInfo.variables;
      if (memberInfo.hasLabels || heads.length > 1) {
        _finishJoinedPatternVariables(
          variables,
          patternVariableInfo.componentVariables,
          patternVariableInfo.patternVariablePromotionKeys,
          location: JoinedPatternVariableLocation.sharedCaseScope,
        );
      }
      handleCase_afterCaseHeads(node, caseIndex, variables.values);
      // Stack: (Expression, numExecutionPaths * StatementCase, CaseHeads)
      // If there are joined variables, declare them.
      for (Statement statement in memberInfo.body) {
        dispatchStatement(statement);
      }
      // Stack: (Expression, numExecutionPaths * StatementCase, CaseHeads,
      //         n * Statement), where n = body.length
      lastCaseTerminates = !flow.switchStatement_afterCase();
      if (caseIndex < numCases - 1 &&
          options.nullSafetyEnabled &&
          !options.patternsEnabled &&
          !lastCaseTerminates) {
        errors?.switchCaseCompletesNormally(node: node, caseIndex: caseIndex);
      }
      handleMergedStatementCase(node,
          caseIndex: caseIndex, isTerminating: lastCaseTerminates);
      // Stack: (Expression, (numExecutionPaths + 1) * StatementCase)
    }
    // Stack: (Expression, numExecutionPaths * StatementCase)
    bool isExhaustive;
    bool requiresExhaustivenessValidation;
    if (hasDefault) {
      isExhaustive = true;
      requiresExhaustivenessValidation = false;
    } else if (options.patternsEnabled) {
      requiresExhaustivenessValidation =
          isExhaustive = isAlwaysExhaustiveType(scrutineeType);
    } else {
      isExhaustive = isLegacySwitchExhaustive(node, scrutineeType);
      requiresExhaustivenessValidation = false;
    }
    bool isProvenExhaustive = flow.switchStatement_end(isExhaustive);
    if (options.errorOnSwitchExhaustiveness &&
        requiresExhaustivenessValidation &&
        !isProvenExhaustive) {
      errors?.nonExhaustiveSwitch(node: node, scrutineeType: scrutineeType);
    }
    return new SwitchStatementTypeAnalysisResult<Type>(
      hasDefault: hasDefault,
      isExhaustive: isExhaustive,
      lastCaseTerminates: lastCaseTerminates,
      requiresExhaustivenessValidation: requiresExhaustivenessValidation,
      scrutineeType: scrutineeType,
    );
  }

  /// Analyzes a variable declaration of the form `type variable;` or
  /// `var variable;`.
  ///
  /// [node] should be the AST node for the entire declaration, [variable] for
  /// the variable, and [declaredType] for the type (if present).  [isFinal] and
  /// [isLate] indicate whether this is a final declaration and/or a late
  /// declaration, respectively.
  ///
  /// Stack effect: none.
  ///
  /// Returns the inferred type of the variable.
  Type analyzeUninitializedVariableDeclaration(
      Node node, Variable variable, Type? declaredType,
      {required bool isFinal, required bool isLate}) {
    Type inferredType = declaredType ?? dynamicType;
    setVariableType(variable, inferredType);
    flow.declare(variable, inferredType, initialized: false);
    return inferredType;
  }

  /// Analyzes a wildcard pattern.  [node] is the pattern.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: none.
  void analyzeWildcardPattern({
    required MatchContext<Node, Expression, Pattern, Type, Variable> context,
    required Pattern node,
    required Type? declaredType,
  }) {
    Type matchedType = flow.getMatchedValueType();
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null && declaredType != null) {
      if (!operations.isAssignableTo(matchedType, declaredType)) {
        errors?.patternTypeMismatchInIrrefutableContext(
          pattern: node,
          context: irrefutableContext,
          matchedType: matchedType,
          requiredType: declaredType,
        );
      }
    }

    bool isAlwaysMatching;
    if (declaredType != null) {
      isAlwaysMatching = flow.promoteForPattern(
          matchedType: matchedType, knownType: declaredType);
    } else {
      isAlwaysMatching = true;
    }

    UnnecessaryWildcardKind? unnecessaryWildcardKind =
        context.unnecessaryWildcardKind;
    if (isAlwaysMatching && unnecessaryWildcardKind != null) {
      errors?.unnecessaryWildcardPattern(
        pattern: node,
        kind: unnecessaryWildcardKind,
      );
    }
  }

  /// Computes the type schema for a wildcard pattern.  [declaredType] is the
  /// explicitly declared type (if present).
  ///
  /// Stack effect: none.
  Type analyzeWildcardPatternSchema({
    required Type? declaredType,
  }) {
    return declaredType ?? unknownType;
  }

  /// If [type] is a record type, returns it.
  RecordType<Type>? asRecordType(Type type);

  /// Calls the appropriate `analyze` method according to the form of
  /// collection [element], and then adjusts the stack as needed to combine
  /// any sub-structures into a single collection element.
  ///
  /// For example, if [element] is an `if` element, calls [analyzeIfElement].
  ///
  /// Stack effect: pushes (CollectionElement).
  void dispatchCollectionElement(Node element, Object? context);

  /// Calls the appropriate `analyze` method according to the form of
  /// [expression], and then adjusts the stack as needed to combine any
  /// sub-structures into a single expression.
  ///
  /// For example, if [node] is a binary expression (`a + b`), calls
  /// [analyzeBinaryExpression].
  ///
  /// Stack effect: pushes (Expression).
  ExpressionTypeAnalysisResult<Type> dispatchExpression(
      Expression node, Type context);

  /// Calls the appropriate `analyze` method according to the form of [pattern].
  ///
  /// [context] keeps track of other contextual information pertinent to the
  /// matching of the [pattern], such as the context of the top-level pattern,
  /// and the information accumulated while matching previous patterns.
  ///
  /// Stack effect: pushes (Pattern).
  void dispatchPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Node pattern);

  /// Calls the appropriate `analyze...Schema` method according to the form of
  /// [pattern].
  ///
  /// Stack effect: none.
  Type dispatchPatternSchema(Node pattern);

  /// Calls the appropriate `analyze` method according to the form of
  /// [statement], and then adjusts the stack as needed to combine any
  /// sub-structures into a single statement.
  ///
  /// For example, if [statement] is a `while` loop, calls [analyzeWhileLoop].
  ///
  /// Stack effect: pushes (Statement).
  void dispatchStatement(Statement statement);

  /// Infers the type for the [pattern], should be a subtype of [matchedType].
  Type downwardInferObjectPatternRequiredType({
    required Type matchedType,
    required Pattern pattern,
  });

  /// Called after visiting an expression case.
  ///
  /// [node] is the enclosing switch expression, and [caseIndex] is the index of
  /// this code path within the switch expression's cases.
  ///
  /// Stack effect: pops (CaseHead, Expression) and pushes (ExpressionCase).
  void finishExpressionCase(Expression node, int caseIndex);

  void finishJoinedPatternVariable(
    Variable variable, {
    required JoinedPatternVariableLocation location,
    required bool isConsistent,
    required bool isFinal,
    required Type type,
  });

  /// If the [element] is a map pattern entry, returns it.
  MapPatternEntry<Expression, Pattern>? getMapPatternEntry(Node element);

  /// If [node] is [isRestPatternElement], returns its optional pattern.
  Pattern? getRestPatternElementPattern(Node node);

  /// Returns an [ExpressionCaseInfo] object describing the [index]th `case` or
  /// `default` clause in the switch expression [node].
  ///
  /// Note: it is allowed for the client's AST nodes for `case` and `default`
  /// clauses to implement [ExpressionCaseInfo], in which case this method can
  /// simply return the [index]th `case` or `default` clause.
  ///
  /// See [analyzeSwitchExpression].
  SwitchExpressionMemberInfo<Node, Expression, Variable>
      getSwitchExpressionMemberInfo(Expression node, int index);

  /// Returns a [StatementCaseInfo] object describing the [index]th `case` or
  /// `default` clause in the switch statement [node].
  ///
  /// Note: it is allowed for the client's AST nodes for `case` and `default`
  /// clauses to implement [StatementCaseInfo], in which case this method can
  /// simply return the [index]th `case` or `default` clause.
  ///
  /// See [analyzeSwitchStatement].
  SwitchStatementMemberInfo<Node, Statement, Expression, Variable>
      getSwitchStatementMemberInfo(Statement node, int caseIndex);

  /// Returns the type of [variable].
  Type getVariableType(Variable variable);

  /// Called after visiting the pattern in `if-case` statement.
  void handle_ifCaseStatement_afterPattern({required Statement node}) {}

  /// Called after visiting the expression of an `if` element.
  void handle_ifElement_conditionEnd(Node node) {}

  /// Called after visiting the `else` element of an `if` element.
  void handle_ifElement_elseEnd(Node node, Node ifFalse) {}

  /// Called after visiting the `then` element of an `if` element.
  void handle_ifElement_thenEnd(Node node, Node ifTrue) {}

  /// Called after visiting the expression of an `if` statement.
  void handle_ifStatement_conditionEnd(Statement node) {}

  /// Called after visiting the `else` statement of an `if` statement.
  void handle_ifStatement_elseEnd(Statement node, Statement ifFalse) {}

  /// Called after visiting the `then` statement of an `if` statement.
  void handle_ifStatement_thenEnd(Statement node, Statement ifTrue) {}

  /// Called after visiting the left hand side of a logical-or (`||`) pattern.
  void handle_logicalOrPattern_afterLhs(Pattern node) {}

  /// Called after visiting a merged set of `case` / `default` clauses.
  ///
  /// [node] is the enclosing switch statement, [caseIndex] is the index of the
  /// merged `case` or `default` group.
  ///
  /// Stack effect: pops (numHeads * CaseHead) and pushes (CaseHeads).
  void handleCase_afterCaseHeads(
      Statement node, int caseIndex, Iterable<Variable> variables);

  /// Called after visiting a single `case` clause, consisting of a pattern and
  /// an optional guard.
  ///
  /// [node] is the enclosing switch statement or switch expression and
  /// [caseIndex] is the index of the `case` clause.
  ///
  /// Stack effect: pops (Pattern, Expression) and pushes (CaseHead).
  void handleCaseHead(Node node,
      {required int caseIndex, required int subIndex});

  /// Called after visiting a `default` clause.
  ///
  /// [node] is the enclosing switch statement or switch expression and
  /// [caseIndex] is the index of the `default` clause.
  /// [subIndex] is the index of the case head.
  ///
  /// Stack effect: pushes (CaseHead).
  void handleDefault(
    Node node, {
    required int caseIndex,
    required int subIndex,
  });

  /// Called after visiting a rest element in a list pattern.
  ///
  /// Stack effect: pushes (Pattern).
  void handleListPatternRestElement(Pattern container, Node restElement);

  /// Called after visiting an entry element in a map pattern.
  ///
  /// Stack effect: pushes (MapPatternElement).
  void handleMapPatternEntry(Pattern container, Node entryElement);

  /// Called after visiting a rest element in a map pattern.
  ///
  /// Stack effect: pushes (MapPatternElement).
  void handleMapPatternRestElement(Pattern container, Node restElement);

  /// Called after visiting a merged statement case.
  ///
  /// [node] is enclosing switch statement, [caseIndex] is the index of the
  /// merged `case` or `default` group.
  ///
  /// If [isTerminating] is `true`, then flow analysis has determined that the
  /// case ends in a construct that doesn't complete normally (e.g. a `break`,
  /// `return`, `continue`, `throw`, or infinite loop); the client can use this
  /// to determine whether a jump is needed to the end of the switch statement.
  ///
  /// Stack effect: pops (CaseHeads, numStatements * Statement) and pushes
  /// (StatementCase).
  void handleMergedStatementCase(Statement node,
      {required int caseIndex, required bool isTerminating});

  /// Called when visiting a syntactic construct where there is an implicit
  /// no-op collection element.  For example, this is called in place of the
  /// missing `else` part of an `if` element that lacks an `else` clause.
  ///
  /// Stack effect: pushes (CollectionElement).
  void handleNoCollectionElement(Node node);

  /// Called when visiting a `case` that lacks a guard clause.  Since the lack
  /// of a guard clause is semantically equivalent to `when true`, this method
  /// should behave similarly to visiting the boolean literal `true`.
  ///
  /// [node] is the enclosing switch statement, switch expression, or `if`, and
  /// [caseIndex] is the index of the `case` within [node].
  ///
  /// Stack effect: pushes (Expression).
  void handleNoGuard(Node node, int caseIndex);

  /// Called when visiting a syntactic construct where there is an implicit
  /// no-op statement.  For example, this is called in place of the missing
  /// `else` part of an `if` statement that lacks an `else` clause.
  ///
  /// Stack effect: pushes (Statement).
  void handleNoStatement(Statement node);

  /// Called before visiting a single `case` or `default` clause.
  ///
  /// [node] is the enclosing switch statement or switch expression and
  /// [caseIndex] is the index of the `case` or `default` clause.
  /// [subIndex] is the index of the case head.
  void handleSwitchBeforeAlternative(Node node,
      {required int caseIndex, required int subIndex});

  /// Called after visiting the scrutinee part of a switch statement or switch
  /// expression.  This is a hook to allow the client to start exhaustiveness
  /// analysis.
  ///
  /// [type] is the static type of the scrutinee expression.
  ///
  /// TODO(paulberry): move exhaustiveness analysis into the shared code and
  /// eliminate this method.
  ///
  /// Stack effect: none.
  void handleSwitchScrutinee(Type type);

  /// Queries whether [type] is an "always-exhaustive" type (as defined in the
  /// patterns spec).  Exhaustive types are types for which the switch statement
  /// is required to be exhaustive when patterns support is enabled.
  bool isAlwaysExhaustiveType(Type type);

  /// Queries whether the switch statement or expression represented by [node]
  /// was exhaustive.  [expressionType] is the static type of the scrutinee.
  ///
  /// Will only be called if the switch statement or expression lacks a
  /// `default` clause, and patterns support is disabled.
  bool isLegacySwitchExhaustive(Node node, Type expressionType);

  /// Returns whether [node] is a rest element in a list or map pattern.
  bool isRestPatternElement(Node node);

  /// Returns whether [node] is final.
  bool isVariableFinal(Variable node);

  /// Queries whether [pattern] is a variable pattern.
  bool isVariablePattern(Node pattern);

  /// Returns the type `Iterable`, with type argument [elementType].
  Type iterableType(Type elementType);

  /// Returns the type `List`, with type argument [elementType].
  Type listType(Type elementType);

  /// Returns the type `Map`, with type arguments.
  Type mapType({
    required Type keyType,
    required Type valueType,
  });

  /// Builds the client specific record type.
  Type recordType(
      {required List<Type> positional, required List<NamedType<Type>> named});

  /// Returns the type of the property in [receiverType] that corresponds to
  /// the name of the [field].  If the property cannot be resolved, the client
  /// should report an error, and return `dynamic` for recovery.
  Type resolveObjectPatternPropertyGet({
    required Type receiverType,
    required RecordPatternField<Node, Pattern> field,
  });

  /// Resolves the relational operator for [node] assuming that the value being
  /// matched has static type [matchedValueType].
  ///
  /// If no operator is found, `null` should be returned.  (This could happen
  /// either because the code is invalid, or because [matchedValueType] is
  /// `dynamic`).
  RelationalOperatorResolution<Type>? resolveRelationalPatternOperator(
      Pattern node, Type matchedValueType);

  /// Records that type inference has assigned a [type] to a [variable].  This
  /// is called once per variable, regardless of whether the variable's type is
  /// explicit or inferred.
  void setVariableType(Variable variable, Type type);

  /// Returns the type `Stream`, with type argument [elementType].
  Type streamType(Type elementType);

  /// Computes the type that should be inferred for an implicitly typed variable
  /// whose initializer expression has static type [type].
  Type variableTypeFromInitializerType(Type type);

  /// Common functionality shared by [analyzeIfStatement] and
  /// [analyzeIfCaseStatement].
  ///
  /// Stack effect: pushes (Statement ifTrue, Statement ifFalse).
  void _analyzeIfCommon(Statement node, Statement ifTrue, Statement? ifFalse) {
    // Stack: ()
    dispatchStatement(ifTrue);
    handle_ifStatement_thenEnd(node, ifTrue);
    // Stack: (Statement ifTrue)
    if (ifFalse == null) {
      handleNoStatement(node);
      flow.ifStatement_end(false);
    } else {
      flow.ifStatement_elseBegin();
      dispatchStatement(ifFalse);
      flow.ifStatement_end(true);
      handle_ifStatement_elseEnd(node, ifFalse);
    }
    // Stack: (Statement ifTrue, Statement ifFalse)
  }

  /// Common functionality shared by [analyzeIfElement] and
  /// [analyzeIfCaseElement].
  ///
  /// Stack effect: pushes (CollectionElement ifTrue,
  /// CollectionElement ifFalse).
  void _analyzeIfElementCommon(
      Node node, Node ifTrue, Node? ifFalse, Object? context) {
    // Stack: ()
    dispatchCollectionElement(ifTrue, context);
    handle_ifElement_thenEnd(node, ifTrue);
    // Stack: (CollectionElement ifTrue)
    if (ifFalse == null) {
      handleNoCollectionElement(node);
      flow.ifStatement_end(false);
    } else {
      flow.ifStatement_elseBegin();
      dispatchCollectionElement(ifFalse, context);
      flow.ifStatement_end(true);
      handle_ifElement_elseEnd(node, ifFalse);
    }
    // Stack: (CollectionElement ifTrue, CollectionElement ifFalse)
  }

  void _checkGuardType(Expression expression, Type type) {
    // TODO(paulberry): harmonize this with analyzer's checkForNonBoolExpression
    // TODO(paulberry): spec says the type must be `bool` or `dynamic`.  This
    // logic permits `T extends bool`, `T promoted to bool`, or `Never`.  What
    // do we want?
    if (!operations.isAssignableTo(type, boolType)) {
      errors?.nonBooleanCondition(node: expression);
    }
  }

  void _finishJoinedPatternVariables(
    Map<String, Variable> variables,
    Map<String, List<Variable>> componentVariables,
    Map<String, int> patternVariablePromotionKeys, {
    required JoinedPatternVariableLocation location,
  }) {
    assert(() {
      // Every entry in `variables` should match a variable we know about.
      for (String variableName in variables.keys) {
        assert(patternVariablePromotionKeys.containsKey(variableName));
      }
      return true;
    }());
    for (MapEntry<String, int> entry in patternVariablePromotionKeys.entries) {
      String variableName = entry.key;
      int promotionKey = entry.value;
      Variable? variable = variables[variableName];
      List<Variable> components = componentVariables[variableName] ?? [];
      bool isFirst = true;
      Type? typeIfConsistent;
      bool? isFinalIfConsistent;
      bool isIdenticalToComponent = false;
      for (Variable component in components) {
        if (identical(variable, component)) {
          isIdenticalToComponent = true;
        }
        Type componentType = getVariableType(component);
        bool isComponentFinal = isVariableFinal(component);
        if (isFirst) {
          typeIfConsistent = componentType;
          isFinalIfConsistent = isComponentFinal;
          isFirst = false;
        } else {
          bool inconsistencyFound = false;
          if (typeIfConsistent != null &&
              !_structurallyEqualAfterNormTypes(
                  typeIfConsistent, componentType)) {
            typeIfConsistent = null;
            inconsistencyFound = true;
          }
          if (isFinalIfConsistent != null &&
              isFinalIfConsistent != isComponentFinal) {
            isFinalIfConsistent = null;
            inconsistencyFound = true;
          }
          if (inconsistencyFound &&
              location == JoinedPatternVariableLocation.singlePattern &&
              variable != null) {
            errors?.inconsistentJoinedPatternVariable(
                variable: variable, component: component);
          }
        }
      }
      if (variable != null) {
        if (!isIdenticalToComponent) {
          finishJoinedPatternVariable(variable,
              location: location,
              isConsistent:
                  typeIfConsistent != null && isFinalIfConsistent != null,
              isFinal: isFinalIfConsistent ?? false,
              type: typeIfConsistent ?? errorType);
          flow.assignMatchedPatternVariable(variable, promotionKey);
        }
      }
    }
  }

  /// If the shape described by [fields] is the same as the shape of the
  /// [matchedType], returns matched types for each field in [fields].
  /// Otherwise returns `null`.
  List<Type>? _matchRecordTypeShape(
    List<RecordPatternField<Node, Pattern>> fields,
    RecordType<Type> matchedType,
  ) {
    Map<String, Type> matchedTypeNamed = {};
    for (NamedType<Type> namedField in matchedType.named) {
      matchedTypeNamed[namedField.name] = namedField.type;
    }

    List<Type> result = [];
    int positionalIndex = 0;
    int namedCount = 0;
    for (RecordPatternField<Node, Pattern> field in fields) {
      Type? fieldType;
      String? name = field.name;
      if (name != null) {
        fieldType = matchedTypeNamed[name];
        if (fieldType == null) {
          return null;
        }
        namedCount++;
      } else {
        if (positionalIndex >= matchedType.positional.length) {
          return null;
        }
        fieldType = matchedType.positional[positionalIndex++];
      }
      result.add(fieldType);
    }
    if (positionalIndex != matchedType.positional.length) {
      return null;
    }
    if (namedCount != matchedTypeNamed.length) {
      return null;
    }

    assert(result.length == fields.length);
    return result;
  }

  /// Reports errors for duplicate named record fields.
  void _reportDuplicateRecordPatternFields(
    Pattern pattern,
    List<RecordPatternField<Node, Pattern>> fields,
  ) {
    Map<String, RecordPatternField<Node, Pattern>> nameToField = {};
    for (RecordPatternField<Node, Pattern> field in fields) {
      String? name = field.name;
      if (name != null) {
        RecordPatternField<Node, Pattern>? original = nameToField[name];
        if (original != null) {
          errors?.duplicateRecordPatternField(
            objectOrRecordPattern: pattern,
            name: name,
            original: original,
            duplicate: field,
          );
        } else {
          nameToField[name] = field;
        }
      }
    }
  }

  bool _structurallyEqualAfterNormTypes(Type type1, Type type2) {
    Type norm1 = operations.normalize(type1);
    Type norm2 = operations.normalize(type2);
    return operations.areStructurallyEqual(norm1, norm2);
  }
}

/// Interface used by the shared [TypeAnalyzer] logic to report error conditions
/// up to the client during the "visit" phase of type analysis.
abstract class TypeAnalyzerErrors<
    Node extends Object,
    Statement extends Node,
    Expression extends Node,
    Variable extends Object,
    Type extends Object,
    Pattern extends Node> implements TypeAnalyzerErrorsBase {
  /// Called if [argument] has type [argumentType], which is not assignable
  /// to [parameterType].
  void argumentTypeNotAssignable({
    required Expression argument,
    required Type argumentType,
    required Type parameterType,
  });

  /// Called if pattern support is disabled and a case constant's static type
  /// doesn't properly match the scrutinee's static type.
  void caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required Type scrutineeType,
      required Type caseExpressionType,
      required bool nullSafetyEnabled});

  /// Called for variable that is assigned more than once.
  void duplicateAssignmentPatternVariable({
    required Variable variable,
    required Pattern original,
    required Pattern duplicate,
  });

  /// Called for a pair of named fields have the same name.
  void duplicateRecordPatternField({
    required Pattern objectOrRecordPattern,
    required String name,
    required RecordPatternField<Node, Pattern> original,
    required RecordPatternField<Node, Pattern> duplicate,
  });

  /// Called for a duplicate rest pattern found in a list or map pattern.
  void duplicateRestPattern({
    required Pattern mapOrListPattern,
    required Node original,
    required Node duplicate,
  });

  /// Called when both branches have variables with the same name, but these
  /// variables either don't have the same finality, or their `NORM` types
  /// are not structurally equal.
  void inconsistentJoinedPatternVariable({
    required Variable variable,
    required Variable component,
  });

  /// Called when a null-assert or null-check pattern is used with the matched
  /// type that is strictly non-nullable, so the null check is not necessary.
  void matchedTypeIsStrictlyNonNullable({
    required Pattern pattern,
    required Type matchedType,
  });

  /// Called when the matched type of a cast pattern is a subtype of the
  /// required type, so the cast is not necessary.
  void matchedTypeIsSubtypeOfRequired({
    required Pattern pattern,
    required Type matchedType,
    required Type requiredType,
  });

  /// Called if the static type of a condition is not assignable to `bool`.
  void nonBooleanCondition({required Expression node});

  /// Called if [TypeAnalyzerOptions.errorOnSwitchExhaustiveness] is `true`, and
  /// a switch that is required to be exhaustive cannot be proven by flow
  /// analysis to be exhaustive.
  ///
  /// [node] is the offending switch expression or switch statement, and
  /// [scrutineeType] is the static type of the switch statement's scrutinee
  /// expression.
  void nonExhaustiveSwitch({required Node node, required Type scrutineeType});

  /// Called if a pattern is illegally used in a variable declaration statement
  /// that is marked `late`, and that pattern is not allowed in such a
  /// declaration.  The only kind of pattern that may be used in a late variable
  /// declaration is a variable pattern.
  ///
  /// [pattern] is the AST node of the illegal pattern.
  void patternDoesNotAllowLate({required Node pattern});

  /// Called if in a pattern `for-in` statement or element, the [expression]
  /// that should be an `Iterable` (or dynamic) is actually not.
  ///
  /// [expressionType] is the actual type of the [expression].
  void patternForInExpressionIsNotIterable({
    required Node node,
    required Expression expression,
    required Type expressionType,
  });

  /// Called if, for a pattern in an irrefutable context, the matched type of
  /// the pattern is not assignable to the required type.
  ///
  /// [pattern] is the AST node of the pattern with the type error, [context] is
  /// the containing AST node that established an irrefutable context,
  /// [matchedType] is the matched type, and [requiredType] is the required
  /// type.
  void patternTypeMismatchInIrrefutableContext(
      {required Pattern pattern,
      required Node context,
      required Type matchedType,
      required Type requiredType});

  /// Called if a refutable pattern is illegally used in an irrefutable context.
  ///
  /// [pattern] is the AST node of the refutable pattern, and [context] is the
  /// containing AST node that established an irrefutable context.
  ///
  /// TODO(paulberry): move this error reporting to the parser.
  void refutablePatternInIrrefutableContext(
      {required Node pattern, required Node context});

  /// Called if the [returnType] of the invoked relational operator is not
  /// assignable to `bool`.
  void relationalPatternOperatorReturnTypeNotAssignableToBool({
    required Pattern pattern,
    required Type returnType,
  });

  /// Called if a rest pattern inside a map pattern is not the last element.
  ///
  /// [node] is the map pattern.  [element] is the rest pattern.
  void restPatternNotLastInMap({required Pattern node, required Node element});

  /// Called if a rest pattern inside a map pattern has a subpattern.
  ///
  /// [node] is the map pattern.  [element] is the rest pattern.
  void restPatternWithSubPatternInMap(
      {required Pattern node, required Node element});

  /// Called if one of the case bodies of a switch statement completes normally
  /// (other than the last case body), and the "patterns" feature is not
  /// enabled.
  ///
  /// [node] is the AST node of the switch statement.  [caseIndex] is the index
  /// of the merged case with the erroneous case body.
  void switchCaseCompletesNormally(
      {required Statement node, required int caseIndex});

  /// Called when a wildcard pattern appears in the context where it is not
  /// necessary, e.g. `0 && var _` vs. `[var _]`, and does not add anything
  /// to type promotion, e.g. `final x = 0; if (x case int _ && > 0) {}`.
  void unnecessaryWildcardPattern({
    required Pattern pattern,
    required UnnecessaryWildcardKind kind,
  });
}

/// Base class for error reporting callbacks that might be reported either in
/// the "pre-visit" or the "visit" phase of type analysis.
abstract class TypeAnalyzerErrorsBase {
  /// Called when the [TypeAnalyzer] encounters a condition which should be
  /// impossible if the user's code is free from static errors, but which might
  /// arise as a result of error recovery.  To verify this invariant, the client
  /// should double check (preferably using an assertion) that at least one
  /// error is reported.
  ///
  /// Note that the error might be reported after this method is called.
  void assertInErrorRecovery();
}

/// Options affecting the behavior of [TypeAnalyzer].
///
/// The client is free to `implement` or `extend` this class.
class TypeAnalyzerOptions {
  final bool nullSafetyEnabled;

  final bool patternsEnabled;

  /// If `true`, the type analyzer should generate errors if it encounters a
  /// switch that is required to be exhaustive, but cannot be proven to be
  /// exhaustive by flow analysis.
  ///
  /// This option is intended as a temporary workaround if we want to ship an
  /// early beta of the "patterns" feature before exhaustiveness checking is
  /// sufficiently ready.
  ///
  /// TODO(paulberry): remove this option when it is no longer needed.
  final bool errorOnSwitchExhaustiveness;

  TypeAnalyzerOptions(
      {required this.nullSafetyEnabled,
      required this.patternsEnabled,
      this.errorOnSwitchExhaustiveness = false});
}
