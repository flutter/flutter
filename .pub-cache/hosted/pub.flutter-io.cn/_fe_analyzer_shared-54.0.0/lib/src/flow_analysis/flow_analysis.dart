// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../type_inference/assigned_variables.dart';
import '../type_inference/promotion_key_store.dart';
import '../type_inference/type_operations.dart';

/// Non-promotion reason describing the situation where a variable was not
/// promoted due to an explicit write to the variable appearing somewhere in the
/// source code.
class DemoteViaExplicitWrite<Variable extends Object>
    extends NonPromotionReason {
  /// The local variable that was not promoted.
  final Variable variable;

  /// The node that wrote to the variable; this corresponds to a node that was
  /// passed to [FlowAnalysis.write].
  final Object node;

  DemoteViaExplicitWrite(this.variable, this.node);

  @override
  String get documentationLink => 'http://dart.dev/go/non-promo-write';

  @override
  String get shortName => 'explicitWrite';

  @override
  R accept<R, Node extends Object, Variable extends Object,
              Type extends Object>(
          NonPromotionReasonVisitor<R, Node, Variable, Type> visitor) =>
      visitor.visitDemoteViaExplicitWrite(
          this as DemoteViaExplicitWrite<Variable>);

  @override
  String toString() => 'DemoteViaExplicitWrite($node)';
}

/// Information gathered by flow analysis about an argument to either
/// `identical` or `operator ==`.
class EqualityInfo<Type extends Object> {
  /// The [ExpressionInfo] for the expression.  This is used to determine
  /// whether the expression is a `null` literal.
  final ExpressionInfo<Type>? _expressionInfo;

  /// The type of the expression on the LHS of `==` or `!=`.
  final Type _type;

  /// If the LHS of `==` or `!=` is a reference, the thing being referred to.
  /// Otherwise `null`.
  final ReferenceWithType<Type>? _reference;

  EqualityInfo._(this._expressionInfo, this._type, this._reference);

  @override
  String toString() =>
      'EqualityInfo(expressionInfo: $_expressionInfo, type: $_type, reference: '
      '$_reference)';
}

/// A collection of flow models representing the possible outcomes of evaluating
/// an expression that are relevant to flow analysis.
class ExpressionInfo<Type extends Object> {
  /// The state after the expression evaluates, if we don't care what it
  /// evaluates to.
  final FlowModel<Type> after;

  /// The state after the expression evaluates, if it evaluates to `true`.
  final FlowModel<Type> ifTrue;

  /// The state after the expression evaluates, if it evaluates to `false`.
  final FlowModel<Type> ifFalse;

  ExpressionInfo(
      {required this.after, required this.ifTrue, required this.ifFalse});

  /// Computes a new [ExpressionInfo] based on this one, but with the roles of
  /// [ifTrue] and [ifFalse] reversed.
  ExpressionInfo<Type> invert() =>
      new ExpressionInfo<Type>(after: after, ifTrue: ifFalse, ifFalse: ifTrue);

  ExpressionInfo<Type>? rebaseForward(
          TypeOperations<Type> typeOperations, FlowModel<Type> base) =>
      new ExpressionInfo(
          after: base,
          ifTrue: ifTrue.rebaseForward(typeOperations, base),
          ifFalse: ifFalse.rebaseForward(typeOperations, base));

  @override
  String toString() =>
      'ExpressionInfo(after: $after, _ifTrue: $ifTrue, ifFalse: $ifFalse)';
}

/// Implementation of flow analysis to be shared between the analyzer and the
/// front end.
///
/// The client should create one instance of this class for every method, field,
/// or top level variable to be analyzed, and call the appropriate methods
/// while visiting the code for type inference.
abstract class FlowAnalysis<Node extends Object, Statement extends Node,
    Expression extends Object, Variable extends Object, Type extends Object> {
  factory FlowAnalysis(Operations<Variable, Type> operations,
      AssignedVariables<Node, Variable> assignedVariables,
      {required bool respectImplicitlyTypedVarInitializers}) {
    return new _FlowAnalysisImpl(operations, assignedVariables,
        respectImplicitlyTypedVarInitializers:
            respectImplicitlyTypedVarInitializers);
  }

  factory FlowAnalysis.legacy(Operations<Variable, Type> operations,
          AssignedVariables<Node, Variable> assignedVariables) =
      _LegacyTypePromotion;

  /// Return `true` if the current state is reachable.
  bool get isReachable;

  TypeOperations<Type> get operations;

  /// Call this method after visiting an "as" expression.
  ///
  /// [subExpression] should be the expression to which the "as" check was
  /// applied.  [type] should be the type being checked.
  void asExpression_end(Expression subExpression, Type type);

  /// Call this method after visiting the condition part of an assert statement
  /// (or assert initializer).
  ///
  /// [condition] should be the assert statement's condition.
  ///
  /// See [assert_begin] for more information.
  void assert_afterCondition(Expression condition);

  /// Call this method before visiting the condition part of an assert statement
  /// (or assert initializer).
  ///
  /// The order of visiting an assert statement with no "message" part should
  /// be:
  /// - Call [assert_begin]
  /// - Visit the condition
  /// - Call [assert_afterCondition]
  /// - Call [assert_end]
  ///
  /// The order of visiting an assert statement with a "message" part should be:
  /// - Call [assert_begin]
  /// - Visit the condition
  /// - Call [assert_afterCondition]
  /// - Visit the message
  /// - Call [assert_end]
  void assert_begin();

  /// Call this method after visiting an assert statement (or assert
  /// initializer).
  ///
  /// See [assert_begin] for more information.
  void assert_end();

  /// Call this method after visiting a reference to a variable inside a pattern
  /// assignment.  [node] is the pattern, [variable] is the referenced variable,
  /// and [writtenType] is the type that's written to that variable by the
  /// assignment.
  void assignedVariablePattern(Node node, Variable variable, Type writtenType);

  /// Call this method when the temporary variable holding the result of a
  /// pattern match is assigned to a user-accessible variable.  (Depending on
  /// the client's model, this might happen right after a variable pattern is
  /// matched, or later, after one or more logical-or patterns have been
  /// handled).
  ///
  /// [promotionKey] is the promotion key used by flow analysis to represent the
  /// temporary variable holding the result of the pattern match, and [variable]
  /// is the user-accessible variable that the value is being assigned to.
  ///
  /// Returns the promotion key used by flow analysis to represent [variable].
  /// This may be used in future calls to [assignMatchedPatternVariable] to
  /// handle nested logical-ors, or logical-ors nested within switch cases that
  /// share a body.
  void assignMatchedPatternVariable(Variable variable, int promotionKey);

  /// Call this method when visiting a boolean literal expression.
  void booleanLiteral(Expression expression, bool value);

  /// Call this method just before visiting a conditional expression ("?:").
  void conditional_conditionBegin();

  /// Call this method upon reaching the ":" part of a conditional expression
  /// ("?:").  [thenExpression] should be the expression preceding the ":".
  void conditional_elseBegin(Expression thenExpression);

  /// Call this method when finishing the visit of a conditional expression
  /// ("?:").  [elseExpression] should be the expression preceding the ":", and
  /// [conditionalExpression] should be the whole conditional expression.
  void conditional_end(
      Expression conditionalExpression, Expression elseExpression);

  /// Call this method upon reaching the "?" part of a conditional expression
  /// ("?:").  [condition] should be the expression preceding the "?".
  /// [conditionalExpression] should be the entire conditional expression.
  void conditional_thenBegin(Expression condition, Node conditionalExpression);

  /// Call this method after processing a constant pattern.  [expression] should
  /// be the pattern's constant expression, and [type] should be its static
  /// type.
  ///
  /// If [patternsEnabled] is `true`, pattern support is enabled and this is an
  /// ordinary constant pattern.  if [patternsEnabled] is `false`, pattern
  /// support is disabled and this constant pattern is one of the cases of a
  /// legacy switch statement.
  void constantPattern_end(Expression expression, Type type,
      {required bool patternsEnabled});

  /// Copy promotion data associated with one promotion key to another.  This
  /// is used after analyzing a branch of a logical-or pattern, to move the
  /// promotion data associated with the result of a pattern match on the left
  /// hand and right hand sides of the logical-or into a common promotion key,
  /// so that promotions will be properly unified when the control flow paths
  /// are joined.
  void copyPromotionData({required int sourceKey, required int destinationKey});

  /// Register a declaration of the [variable] in the current state.
  /// Should also be called for function parameters.
  ///
  /// [staticType] should be the static type of the variable (after type
  /// inference).
  ///
  /// A local variable is [initialized] if its declaration has an initializer.
  /// A function parameter is always initialized, so [initialized] is `true`.
  ///
  /// In debug builds, an assertion will normally verify that no variable gets
  /// declared more than once.  This assertion may be disabled by passing `true`
  /// to [skipDuplicateCheck].
  ///
  /// TODO(paulberry): try to remove all uses of skipDuplicateCheck
  void declare(Variable variable, Type staticType,
      {required bool initialized, bool skipDuplicateCheck = false});

  /// Call this method after visiting a variable pattern in a non-assignment
  /// context (or a wildcard pattern).
  ///
  /// [matchedType] should be the static type of the value being matched.
  /// [staticType] should be the static type of the variable pattern itself.
  /// [initializerExpression] should be the initializer expression being matched
  /// (or `null` if there is no expression being matched to this variable).
  /// [isFinal] indicates whether the variable is final, and [isImplicitlyTyped]
  /// indicates whether the variable has an explicit type annotation.
  ///
  /// Although pattern variables in Dart cannot be late, the client is allowed
  /// to model a traditional (non-patterned) variable declaration statement
  /// using the same flow analysis machinery as it uses for pattern variable
  /// declaration statements; when it does so, it may use [isLate] to indicate
  /// whether the variable in question is a `late` variable.
  ///
  /// Returns the promotion key used by flow analysis to track the temporary
  /// variable that holds the matched value.
  int declaredVariablePattern(
      {required Type matchedType,
      required Type staticType,
      Expression? initializerExpression,
      bool isFinal = false,
      bool isLate = false,
      required bool isImplicitlyTyped});

  /// Call this method before visiting the body of a "do-while" statement.
  /// [doStatement] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the do-while statement.
  void doStatement_bodyBegin(Statement doStatement);

  /// Call this method after visiting the body of a "do-while" statement, and
  /// before visiting its condition.
  void doStatement_conditionBegin();

  /// Call this method after visiting the condition of a "do-while" statement.
  /// [condition] should be the condition of the loop.
  void doStatement_end(Expression condition);

  /// Call this method just after visiting either side of a binary `==` or `!=`
  /// expression, or an argument to `identical`.
  ///
  /// Returns information about the expression that will later be needed by
  /// [equalityOperation_end].
  ///
  /// Note: the return type is nullable because legacy type promotion doesn't
  /// need to record information about equality operands.
  EqualityInfo<Type>? equalityOperand_end(Expression operand, Type type);

  /// Call this method just after visiting the operands of a binary `==` or `!=`
  /// expression, or an invocation of `identical`.
  ///
  /// [leftOperandInfo] and [rightOperandInfo] should be the values returned by
  /// [equalityOperand_end].
  void equalityOperation_end(Expression wholeExpression,
      EqualityInfo<Type>? leftOperandInfo, EqualityInfo<Type>? rightOperandInfo,
      {bool notEqual = false});

  /// Call this method after processing a relational pattern that uses an
  /// equality operator (either `==` or `!=`).  [operand] should be the operand
  /// to the right of the operator, [operandType] should be its static type, and
  /// [notEqual] should be `true` iff the operator was `!=`.
  void equalityRelationalPattern_end(Expression operand, Type operandType,
      {bool notEqual = false});

  /// Retrieves the [ExpressionInfo] associated with [target], if known.  Will
  /// return `null` if (a) no info is associated with [target], or (b) another
  /// expression with info has been visited more recently than [target].  For
  /// testing only.
  ExpressionInfo<Type>? expressionInfoForTesting(Expression target);

  /// This method should be called at the conclusion of flow analysis for a top
  /// level function or method.  Performs assertion checks.
  void finish();

  /// Call this method just before visiting the body of a conventional "for"
  /// statement or collection element.  See [for_conditionBegin] for details.
  ///
  /// If a "for" statement is being entered, [node] is an opaque representation
  /// of the loop, for use as the target of future calls to [handleBreak] or
  /// [handleContinue].  If a "for" collection element is being entered, [node]
  /// should be `null`.
  ///
  /// [condition] is an opaque representation of the loop condition; it is
  /// matched against expressions passed to previous calls to determine whether
  /// the loop condition should cause any promotions to occur.  If [condition]
  /// is null, the condition is understood to be empty (equivalent to a
  /// condition of `true`).
  void for_bodyBegin(Statement? node, Expression? condition);

  /// Call this method just before visiting the condition of a conventional
  /// "for" statement or collection element.
  ///
  /// Note that a conventional "for" statement is a statement of the form
  /// `for (initializers; condition; updaters) body`.  Statements of the form
  /// `for (variable in iterable) body` should use [forEach_bodyBegin].  Similar
  /// for "for" collection elements.
  ///
  /// The order of visiting a "for" statement or collection element should be:
  /// - Visit the initializers.
  /// - Call [for_conditionBegin].
  /// - Visit the condition.
  /// - Call [for_bodyBegin].
  /// - Visit the body.
  /// - Call [for_updaterBegin].
  /// - Visit the updaters.
  /// - Call [for_end].
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the for statement.
  void for_conditionBegin(Node node);

  /// Call this method just after visiting the updaters of a conventional "for"
  /// statement or collection element.  See [for_conditionBegin] for details.
  void for_end();

  /// Call this method just before visiting the updaters of a conventional "for"
  /// statement or collection element.  See [for_conditionBegin] for details.
  void for_updaterBegin();

  /// Call this method just before visiting the body of a "for-in" statement or
  /// collection element.
  ///
  /// The order of visiting a "for-in" statement or collection element should
  /// be:
  /// - Visit the iterable expression.
  /// - Call [forEach_bodyBegin].
  /// - Visit the body.
  /// - Call [forEach_end].
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the for statement.
  void forEach_bodyBegin(Node node);

  /// Call this method just before visiting the body of a "for-in" statement or
  /// collection element.  See [forEach_bodyBegin] for details.
  void forEach_end();

  /// Call this method to forward information on [oldExpression] to
  /// [newExpression].
  ///
  /// This can be used to preserve promotions through a replacement from
  /// [oldExpression] to [newExpression]. For instance when rewriting
  ///
  ///    method(int i) {
  ///      if (i is int) { ... } else { ... }
  ///    }
  ///
  ///  to
  ///
  ///    method(int i) {
  ///      if (i is int || throw ...) { ... } else { ... }
  ///    }
  ///
  ///  the promotion `i is int` can be forwarded to `i is int || throw ...` and
  ///  there preserved in the surrounding if statement.
  void forwardExpression(Expression newExpression, Expression oldExpression);

  /// Call this method just before visiting the body of a function expression or
  /// local function.
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the function expression.
  void functionExpression_begin(Node node);

  /// Call this method just after visiting the body of a function expression or
  /// local function.
  void functionExpression_end();

  /// Gets the matched value type that should be used to type check the pattern
  /// currently being analyzed.
  ///
  /// May only be called in the context of a pattern.
  Type getMatchedValueType();

  /// Call this method when visiting a break statement.  [target] should be the
  /// statement targeted by the break.
  ///
  /// To facilitate error recovery, [target] is allowed to be `null`; if this
  /// happens, the break statement is analyzed as though it's an unconditional
  /// branch to nowhere (i.e. similar to a `return` or `throw`).
  void handleBreak(Statement? target);

  /// Call this method when visiting a continue statement.  [target] should be
  /// the statement targeted by the continue.
  ///
  /// To facilitate error recovery, [target] is allowed to be `null`; if this
  /// happens, the continue statement is analyzed as though it's an
  /// unconditional branch to nowhere (i.e. similar to a `return` or `throw`).
  void handleContinue(Statement? target);

  /// Register the fact that the current state definitely exists, e.g. returns
  /// from the body, throws an exception, etc.
  ///
  /// Should also be called if a subexpression's type is Never.
  void handleExit();

  /// Call this method after visiting the scrutinee expression of an if-case
  /// statement.
  ///
  /// [scrutinee] is the scrutinee expression, and [scrutineeType] is its static
  /// type.
  void ifCaseStatement_afterExpression(
      Expression scrutinee, Type scrutineeType);

  /// Call this method before visiting an if-case statement.
  ///
  /// The order of visiting an if-case statement with no "else" part should be:
  /// - Call [ifCaseStatement_begin]
  /// - Visit the expression
  /// - Call [ifCaseStatement_afterExpression]
  /// - Visit the pattern
  /// - Visit the guard (if any)
  /// - Call [ifCaseStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_end], passing `false` for `hasElse`.
  ///
  /// The order of visiting an if-case statement with an "else" part should be:
  /// - Call [ifCaseStatement_begin]
  /// - Visit the expression
  /// - Call [ifCaseStatement_afterExpression]
  /// - Visit the pattern
  /// - Visit the guard (if any)
  /// - Call [ifCaseStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_elseBegin]
  /// - Visit the "else" statement
  /// - Call [ifStatement_end], passing `true` for `hasElse`.
  void ifCaseStatement_begin();

  /// Call this method after visiting pattern and guard parts of an if-case
  /// statement.
  ///
  /// [guard] should be the guard expression (if present); otherwise `null`.
  void ifCaseStatement_thenBegin(Expression? guard);

  /// Call this method after visiting the RHS of an if-null expression ("??")
  /// or if-null assignment ("??=").
  ///
  /// Note: for an if-null assignment, the call to [write] should occur before
  /// the call to [ifNullExpression_end] (since the write only occurs if the
  /// read resulted in a null value).
  void ifNullExpression_end();

  /// Call this method after visiting the LHS of an if-null expression ("??")
  /// or if-null assignment ("??=").
  void ifNullExpression_rightBegin(
      Expression leftHandSide, Type leftHandSideType);

  /// Call this method before visiting the condition part of an if statement.
  ///
  /// The order of visiting an if statement with no "else" part should be:
  /// - Call [ifStatement_conditionBegin]
  /// - Visit the condition
  /// - Call [ifStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_end], passing `false` for `hasElse`.
  ///
  /// The order of visiting an if statement with an "else" part should be:
  /// - Call [ifStatement_conditionBegin]
  /// - Visit the condition
  /// - Call [ifStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_elseBegin]
  /// - Visit the "else" statement
  /// - Call [ifStatement_end], passing `true` for `hasElse`.
  void ifStatement_conditionBegin();

  /// Call this method after visiting the "then" part of an if statement, and
  /// before visiting the "else" part.
  void ifStatement_elseBegin();

  /// Call this method after visiting an if statement.
  void ifStatement_end(bool hasElse);

  /// Call this method after visiting the condition part of an if statement.
  /// [condition] should be the if statement's condition.  [ifNode] should be
  /// the entire `if` statement (or the collection literal entry).
  ///
  /// For an if-case statement, [condition] should be `null`.
  void ifStatement_thenBegin(Expression? condition, Node ifNode);

  /// Call this method after visiting the initializer of a variable declaration,
  /// or a variable pattern that is being matched (and hence being initialized
  /// with an implicit value).
  ///
  /// If the initialized value is not known (i.e. because this is a variable
  /// pattern that's being matched), pass `null` for [initializerExpression].
  void initialize(
      Variable variable, Type matchedType, Expression? initializerExpression,
      {required bool isFinal,
      required bool isLate,
      required bool isImplicitlyTyped});

  /// Return whether the [variable] is definitely assigned in the current state.
  bool isAssigned(Variable variable);

  /// Call this method after visiting the LHS of an "is" expression.
  ///
  /// [isExpression] should be the complete expression.  [subExpression] should
  /// be the expression to which the "is" check was applied.  [isNot] should be
  /// a boolean indicating whether this is an "is" or an "is!" expression.
  /// [type] should be the type being checked.
  void isExpression_end(
      Expression isExpression, Expression subExpression, bool isNot, Type type);

  /// Return whether the [variable] is definitely unassigned in the current
  /// state.
  bool isUnassigned(Variable variable);

  /// Call this method before visiting a labeled statement.
  /// Call [labeledStatement_end] after visiting the statement.
  void labeledStatement_begin(Statement node);

  /// Call this method after visiting a labeled statement.
  void labeledStatement_end();

  /// Call this method just before visiting the initializer of a late variable.
  void lateInitializer_begin(Node node);

  /// Call this method just after visiting the initializer of a late variable.
  void lateInitializer_end();

  /// Call this method before visiting the LHS of a logical binary operation
  /// ("||" or "&&").
  void logicalBinaryOp_begin();

  /// Call this method after visiting the RHS of a logical binary operation
  /// ("||" or "&&").
  /// [wholeExpression] should be the whole logical binary expression.
  /// [rightOperand] should be the RHS.  [isAnd] should indicate whether the
  /// logical operator is "&&" or "||".
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {required bool isAnd});

  /// Call this method after visiting the LHS of a logical binary operation
  /// ("||" or "&&").
  /// [rightOperand] should be the LHS.  [isAnd] should indicate whether the
  /// logical operator is "&&" or "||".  [wholeExpression] should be the whole
  /// logical binary expression.
  void logicalBinaryOp_rightBegin(Expression leftOperand, Node wholeExpression,
      {required bool isAnd});

  /// Call this method after visiting a logical not ("!") expression.
  /// [notExpression] should be the complete expression.  [operand] should be
  /// the subexpression whose logical value is being negated.
  void logicalNot_end(Expression notExpression, Expression operand);

  /// Call this method after visiting the left hand side of a logical-or (`||`)
  /// pattern.
  void logicalOrPattern_afterLhs();

  /// Call this method before visiting a logical-or (`||`) pattern.
  void logicalOrPattern_begin();

  /// Call this method after visiting a logical-or (`||`) pattern.
  void logicalOrPattern_end();

  /// Call this method after processing a relational pattern that uses a
  /// non-equality operator (any operator other than `==` or `!=`).
  void nonEqualityRelationalPattern_end();

  /// Call this method just after visiting a non-null assertion (`x!`)
  /// expression.
  void nonNullAssert_end(Expression operand);

  /// Call this method after visiting an expression using `?.`.
  void nullAwareAccess_end();

  /// Call this method after visiting a null-aware operator such as `?.`,
  /// `?..`, `?.[`, or `?..[`.
  ///
  /// [target] should be the expression just before the null-aware operator, or
  /// `null` if the null-aware access starts a cascade section.
  ///
  /// [targetType] should be the type of the expression just before the
  /// null-aware operator, and should be non-null even if the null-aware access
  /// starts a cascade section.
  ///
  /// Note that [nullAwareAccess_end] should be called after the conclusion
  /// of any null-shorting that is caused by the `?.`.  So, for example, if the
  /// code being analyzed is `x?.y?.z(x)`, [nullAwareAccess_rightBegin] should
  /// be called once upon reaching each `?.`, but [nullAwareAccess_end] should
  /// not be called until after processing the method call to `z(x)`.
  void nullAwareAccess_rightBegin(Expression? target, Type targetType);

  /// Call this method before visiting the subpattern of a null-check or a
  /// null-assert pattern. [isAssert] indicates whether the pattern is a
  /// null-check or a null-assert pattern.
  bool nullCheckOrAssertPattern_begin({required bool isAssert});

  /// Call this method after visiting the subpattern of a null-check or a
  /// null-assert pattern.
  void nullCheckOrAssertPattern_end();

  /// Call this method when encountering an expression that is a `null` literal.
  void nullLiteral(Expression expression);

  /// Call this method just after visiting a parenthesized expression.
  ///
  /// This is only necessary if the implementation uses a different [Expression]
  /// object to represent a parenthesized expression and its contents.
  void parenthesizedExpression(
      Expression outerExpression, Expression innerExpression);

  /// Call this method just after visiting the right hand side of a pattern
  /// assignment expression, and before visiting the pattern.
  ///
  /// [rhs] is the right hand side expression, and [rhsType] is its static type.
  void patternAssignment_afterRhs(Expression rhs, Type rhsType);

  /// Call this method after visiting a pattern assignment expression.
  void patternAssignment_end();

  /// Call this method just after visiting the expression (which usually
  /// implements `Iterable`, but can also be `dynamic`), and before visiting
  /// the pattern or body.
  ///
  /// [elementType] is the element type of the `Iterable`, or `dynamic`.
  void patternForIn_afterExpression(Type elementType);

  /// Call this method after visiting the body.
  void patternForIn_end();

  /// Call this method just after visiting the initializer of a pattern variable
  /// declaration, and before visiting the pattern.
  ///
  /// [initializer] is the declaration's initializer expression, and
  /// [initializerType] is its static type.
  void patternVariableDeclaration_afterInitializer(
      Expression initializer, Type initializerType);

  /// Call this method after visiting the pattern of a pattern variable
  /// declaration.
  void patternVariableDeclaration_end();

  /// Call this method after visiting a pattern's subpattern, to restore the
  /// state that was saved by [pushSubpattern].
  void popSubpattern();

  /// Retrieves the type that a property named [propertyName] is promoted to, if
  /// the property is currently promoted.  Otherwise returns `null`.
  ///
  /// The [target] parameter determines which expression's property is being
  /// queried; if it is `null`, a property of `this` is being queried.  If it is
  /// non-`null`, this method should be called just after visiting the target
  /// expression.
  ///
  /// [propertyMember] should be whatever data structure the client uses to keep
  /// track of the field or property being accessed.  If not `null`,
  /// [Operations.isPropertyPromotable] will be consulted to find out whether
  /// the property is promotable.  [staticType] should be the static type of the
  /// value returned by the property get.
  ///
  /// Note: although only fields can be promoted, this method uses the
  /// nomenclature "property" rather than "field", to highlight the fact that
  /// it is not necessary for the client to check whether a property refers to a
  /// field before calling this method; if the property does not refer to a
  /// field, `null` will be returned.
  Type? promotedPropertyType(Expression? target, String propertyName,
      Object? propertyMember, Type staticType);

  /// Retrieves the type that the [variable] is promoted to, if the [variable]
  /// is currently promoted.  Otherwise returns `null`.
  Type? promotedType(Variable variable);

  /// Call this method when visiting a pattern whose semantics constrain the
  /// type of the matched value.  This could be due to a required type of a
  /// declared variable pattern, list pattern, map pattern, record pattern,
  /// object pattern, or wildcard pattern, or it could be due to the
  /// demonstrated type of a record pattern.
  ///
  /// [matchedType] should be the matched value type, and [knownType] should
  /// be the type that the matched value is now known to satisfy.
  ///
  /// If [matchFailsIfWrongType] is `true` (the default), flow analysis models
  /// the usual semantics of a type test in a pattern: if the matched value
  /// fails to have the type [knownType], the pattern will fail to match.
  /// If it is `false`, it models the semantics where the no match failure can
  /// occur (either because the matched value is known, due to other invariants
  /// to have the type [knownType], or because a type test failure would result
  /// in an exception being thrown).
  ///
  /// If [matchMayFailEvenIfCorrectType] is `true`, flow analysis would always
  /// update the unmatched value.
  ///
  /// Returns `true` if [matchedType] is a subtype of [knownType].
  bool promoteForPattern(
      {required Type matchedType,
      required Type knownType,
      bool matchFailsIfWrongType = true,
      bool matchMayFailEvenIfCorrectType = false});

  /// Call this method just after visiting a property get expression.
  /// [wholeExpression] should be the whole property get, [target] should be the
  /// expression to the left hand side of the `.`, and [propertyName] should be
  /// the identifier to the right hand side of the `.`.  [staticType] should be
  /// the static type of the value returned by the property get.
  ///
  /// [wholeExpression] is used by flow analysis to detect the case where the
  /// property get is used as a subexpression of a larger expression that
  /// participates in promotion (e.g. promotion of a property of a property).
  /// If there is no expression corresponding to the property get (e.g. because
  /// the property is being invoked like a method, or the property get is part
  /// of a compound assignment), [wholeExpression] may be `null`.
  ///
  /// [propertyMember] should be whatever data structure the client uses to keep
  /// track of the field or property being accessed.  If not `null`,
  /// [Operations.isPropertyPromotable] will be consulted to find out whether
  /// the property is promotable.  In the event of non-promotion of a property
  /// get, this value can be retrieved from
  /// [PropertyNotPromoted.propertyMember].
  ///
  /// If the property's type is currently promoted, the promoted type is
  /// returned.  Otherwise `null` is returned.
  Type? propertyGet(Expression? wholeExpression, Expression target,
      String propertyName, Object? propertyMember, Type staticType);

  /// Call this method just before analyzing a subpattern of a pattern.
  ///
  /// [matchedType] is the type that should be used to type check the
  /// subpattern.
  ///
  /// Flow analysis makes no assumptions about the relation between the matched
  /// value for the outer pattern and the subpattern.
  void pushSubpattern(Type matchedType);

  /// Retrieves the SSA node associated with [variable], or `null` if [variable]
  /// is not associated with an SSA node because it is write captured.  For
  /// testing only.
  @visibleForTesting
  SsaNode<Type>? ssaNodeForTesting(Variable variable);

  /// Call this method just after visiting a `case` or `default` body.  See
  /// [switchStatement_expressionEnd] for details.
  ///
  /// This method returns a boolean indicating whether the end of the case body
  /// is "locally reachable" (i.e. reachable from its start).
  bool switchStatement_afterCase();

  /// Call this method just before visiting a `case` or `default` clause.  See
  /// [switchStatement_expressionEnd] for details.
  void switchStatement_beginAlternative();

  /// Call this method just before visiting a sequence of one or more `case` or
  /// `default` clauses that share a body.  See [switchStatement_expressionEnd]
  /// for details.
  void switchStatement_beginAlternatives();

  /// Call this method just after visiting the body of a switch statement.  See
  /// [switchStatement_expressionEnd] for details.
  ///
  /// [isExhaustive] indicates whether the switch statement had a "default"
  /// case, or is based on an enumeration and all the enumeration constants
  /// were listed in cases.
  ///
  /// Returns a boolean indicating whether flow analysis was able to prove the
  /// switch statement to be exhaustive (e.g. due to the presence of a `default`
  /// clause, or a pattern that is guaranteed to match the scrutinee type).
  bool switchStatement_end(bool isExhaustive);

  /// Call this method just after visiting a `case` or `default` clause.  See
  /// [switchStatement_expressionEnd] for details.`
  ///
  /// [guard] should be the expression following the `when` keyword, if present.
  ///
  /// If the clause is a `case` clause, [variables] should contain an entry for
  /// all variables defined by the clause's pattern; the key should be the
  /// variable name and the value should be the variable itself.  If the clause
  /// is a `default` clause, [variables] should be an empty map.
  void switchStatement_endAlternative(
      Expression? guard, Map<String, Variable> variables);

  /// Call this method just after visiting a sequence of one or more `case` or
  /// `default` clauses that share a body.  See [switchStatement_expressionEnd]
  /// for details.`
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the switch statement.
  ///
  /// [hasLabels] indicates whether the case has any labels.
  ///
  /// Returns a data structure describing the relationship among variables
  /// defined by patterns in the various alternatives.
  PatternVariableInfo<Variable> switchStatement_endAlternatives(Statement? node,
      {required bool hasLabels});

  /// Call this method just after visiting the expression part of a switch
  /// statement or expression.  [switchStatement] should be the switch statement
  /// itself (or `null` if this is a switch expression).
  ///
  /// The order of visiting a switch statement should be:
  /// - Visit the switch expression.
  /// - Call [switchStatement_expressionEnd].
  /// - For each case body:
  ///   - Call [switchStatement_beginAlternatives].
  ///   - For each `case` or `default` clause associated with this case body:
  ///     - Call [switchStatement_beginAlternative].
  ///     - If a pattern is present, visit it.
  ///     - If a guard is present, visit it.
  ///     - Call [switchStatement_endAlternative].
  ///   - Call [switchStatement_endAlternatives].
  ///   - Visit the case body.
  ///   - Call [switchStatement_afterCase].
  /// - Call [switchStatement_end].
  ///
  /// [scrutinee] should be the expression appearing in parentheses after the
  /// `switch` keyword, and [scrutineeType] should be its static type.
  void switchStatement_expressionEnd(
      Statement? switchStatement, Expression scrutinee, Type scrutineeType);

  /// Call this method just after visiting the expression `this` (or the
  /// pseudo-expression `super`, in the case of the analyzer, which represents
  /// `super.x` as a property get whose target is `super`).  [expression] should
  /// be the `this` or `super` expression.  [staticType] should be the static
  /// type of `this`.
  void thisOrSuper(Expression expression, Type staticType);

  /// Call this method just after visiting an expression that represents a
  /// property get on `this` or `super`.  This handles situations where there is
  /// an implicit reference to `this`, or the case of the front end, where
  /// `super.x` is represented by a single expression.  [expression] should be
  /// the whole property get, and [propertyName] should be the name of the
  /// property being read.  [staticType] should be the static type of the value
  /// returned by the property get.
  ///
  /// [propertyMember] should be whatever data structure the client uses to keep
  /// track of the field or property being accessed.  If not `null`,
  /// [Operations.isPropertyPromotable] will be consulted to find out whether
  /// the property is promotable.  In the event of non-promotion of a property
  /// get, this value can be retrieved from
  /// [PropertyNotPromoted.propertyMember].
  ///
  /// If the property's type is currently promoted, the promoted type is
  /// returned.  Otherwise `null` is returned.
  Type? thisOrSuperPropertyGet(Expression expression, String propertyName,
      Object? propertyMember, Type staticType);

  /// Call this method just before visiting the body of a "try/catch" statement.
  ///
  /// The order of visiting a "try/catch" statement should be:
  /// - Call [tryCatchStatement_bodyBegin]
  /// - Visit the try block
  /// - Call [tryCatchStatement_bodyEnd]
  /// - For each catch block:
  ///   - Call [tryCatchStatement_catchBegin]
  ///   - Call [initialize] for the exception and stack trace variables
  ///   - Visit the catch block
  ///   - Call [tryCatchStatement_catchEnd]
  /// - Call [tryCatchStatement_end]
  ///
  /// The order of visiting a "try/catch/finally" statement should be:
  /// - Call [tryFinallyStatement_bodyBegin]
  /// - Call [tryCatchStatement_bodyBegin]
  /// - Visit the try block
  /// - Call [tryCatchStatement_bodyEnd]
  /// - For each catch block:
  ///   - Call [tryCatchStatement_catchBegin]
  ///   - Call [initialize] for the exception and stack trace variables
  ///   - Visit the catch block
  ///   - Call [tryCatchStatement_catchEnd]
  /// - Call [tryCatchStatement_end]
  /// - Call [tryFinallyStatement_finallyBegin]
  /// - Visit the finally block
  /// - Call [tryFinallyStatement_end]
  void tryCatchStatement_bodyBegin();

  /// Call this method just after visiting the body of a "try/catch" statement.
  /// See [tryCatchStatement_bodyBegin] for details.
  ///
  /// [body] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the "try" part of the try/catch statement.
  void tryCatchStatement_bodyEnd(Node body);

  /// Call this method just before visiting a catch clause of a "try/catch"
  /// statement.  See [tryCatchStatement_bodyBegin] for details.
  ///
  /// [exceptionVariable] should be the exception variable declared by the catch
  /// clause, or `null` if there is no exception variable.  Similar for
  /// [stackTraceVariable].
  void tryCatchStatement_catchBegin(
      Variable? exceptionVariable, Variable? stackTraceVariable);

  /// Call this method just after visiting a catch clause of a "try/catch"
  /// statement.  See [tryCatchStatement_bodyBegin] for details.
  void tryCatchStatement_catchEnd();

  /// Call this method just after visiting a "try/catch" statement.  See
  /// [tryCatchStatement_bodyBegin] for details.
  void tryCatchStatement_end();

  /// Call this method just before visiting the body of a "try/finally"
  /// statement.
  ///
  /// The order of visiting a "try/finally" statement should be:
  /// - Call [tryFinallyStatement_bodyBegin]
  /// - Visit the try block
  /// - Call [tryFinallyStatement_finallyBegin]
  /// - Visit the finally block
  /// - Call [tryFinallyStatement_end]
  ///
  /// See [tryCatchStatement_bodyBegin] for the order of visiting a
  /// "try/catch/finally" statement.
  void tryFinallyStatement_bodyBegin();

  /// Call this method just after visiting a "try/finally" statement.
  /// See [tryFinallyStatement_bodyBegin] for details.
  void tryFinallyStatement_end();

  /// Call this method just before visiting the finally block of a "try/finally"
  /// statement.  See [tryFinallyStatement_bodyBegin] for details.
  ///
  /// [body] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the "try" part of the try/finally
  /// statement.
  void tryFinallyStatement_finallyBegin(Node body);

  /// Call this method when encountering an expression that reads the value of
  /// a variable.
  ///
  /// If the variable's type is currently promoted, the promoted type is
  /// returned.  Otherwise `null` is returned.
  Type? variableRead(Expression expression, Variable variable);

  /// Call this method after visiting the condition part of a "while" statement.
  /// [whileStatement] should be the full while statement.  [condition] should
  /// be the condition part of the while statement.
  void whileStatement_bodyBegin(Statement whileStatement, Expression condition);

  /// Call this method before visiting the condition part of a "while"
  /// statement.
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the while statement.
  void whileStatement_conditionBegin(Node node);

  /// Call this method after visiting a "while" statement.
  void whileStatement_end();

  /// Call this method when an error occurs that may be due to a lack of type
  /// promotion, to retrieve information about why [target] was not promoted.
  /// This call must be made right after visiting [target].
  ///
  /// The returned value is a function yielding a map whose keys are types that
  /// the user might have been expecting the target to be promoted to, and whose
  /// values are reasons why the corresponding promotion did not occur.  The
  /// caller is expected to select which non-promotion reason to report to the
  /// user by seeing which promotion would have prevented the error.  (For
  /// example, if an error occurs due to the target having a nullable type, the
  /// caller should report a non-promotion reason associated with non-promotion
  /// to a non-nullable type).
  ///
  /// This method is expected to execute fairly efficiently; the bulk of the
  /// expensive computation is deferred to the function it returns.  The reason
  /// for this is that in certain cases, it's not possible to know whether "why
  /// not promoted" information will be needed until long after visiting a node.
  /// (For example, in resolving a call like
  /// `(x as Future<T>).then(y, onError: z)`, we don't know whether an error
  /// should be reported at `y` until we've inferred the type argument to
  /// `then`, which doesn't occur until after visiting `z`).  So the caller may
  /// freely call this method after any expression for which an error *might*
  /// need to be generated, and then defer invoking the returned function until
  /// it is determined that an error actually occurred.
  Map<Type, NonPromotionReason> Function() whyNotPromoted(Expression target);

  /// Call this method when an error occurs that may be due to a lack of type
  /// promotion, to retrieve information about why an implicit reference to
  /// `this` was not promoted.  [staticType] is the (unpromoted) type of `this`.
  ///
  /// The returned value is a function yielding a map whose keys are types that
  /// the user might have been expecting `this` to be promoted to, and whose
  /// values are reasons why the corresponding promotion did not occur.  The
  /// caller is expected to select which non-promotion reason to report to the
  /// user by seeing which promotion would have prevented the error.  (For
  /// example, if an error occurs due to the target having a nullable type, the
  /// caller should report a non-promotion reason associated with non-promotion
  /// to a non-nullable type).
  ///
  /// This method is expected to execute fairly efficiently; the bulk of the
  /// expensive computation is deferred to the function it returns.  The reason
  /// for this is that in certain cases, it's not possible to know whether "why
  /// not promoted" information will be needed until long after visiting a node.
  /// (For example, in resolving a call like
  /// `(x as Future<T>).then(y, onError: z)`, we don't know whether an error
  /// should be reported at `y` until we've inferred the type argument to
  /// `then`, which doesn't occur until after visiting `z`).  So the caller may
  /// freely call this method after any expression for which an error *might*
  /// need to be generated, and then defer invoking the returned function until
  /// it is determined that an error actually occurred.
  Map<Type, NonPromotionReason> Function() whyNotPromotedImplicitThis(
      Type staticType);

  /// Register write of the given [variable] in the current state.
  /// [writtenType] should be the type of the value that was written.
  /// [node] should be the syntactic construct performing the write.
  /// [writtenExpression] should be the expression that was written, or `null`
  /// if the expression that was written is not directly represented in the
  /// source code (this happens, for example, with compound assignments and with
  /// for-each loops).
  ///
  /// This should also be used for the implicit write to a non-final variable in
  /// its initializer, to ensure that the type is promoted to non-nullable if
  /// necessary; in this case, [viaInitializer] should be `true`.
  void write(Node node, Variable variable, Type writtenType,
      Expression? writtenExpression);

  /// Prints out a summary of the current state of flow analysis, intended for
  /// debugging use only.
  void _dumpState();
}

/// Alternate implementation of [FlowAnalysis] that prints out inputs and output
/// at the API boundary, for assistance in debugging.
class FlowAnalysisDebug<Node extends Object, Statement extends Node,
        Expression extends Object, Variable extends Object, Type extends Object>
    implements FlowAnalysis<Node, Statement, Expression, Variable, Type> {
  static int _nextCallbackId = 0;

  static Expando<String> _description = new Expando<String>();

  FlowAnalysis<Node, Statement, Expression, Variable, Type> _wrapped;

  bool _exceptionOccurred = false;

  factory FlowAnalysisDebug(Operations<Variable, Type> operations,
      AssignedVariables<Node, Variable> assignedVariables,
      {required bool respectImplicitlyTypedVarInitializers}) {
    print('FlowAnalysisDebug()');
    return new FlowAnalysisDebug._(new _FlowAnalysisImpl(
        operations, assignedVariables,
        respectImplicitlyTypedVarInitializers:
            respectImplicitlyTypedVarInitializers));
  }

  factory FlowAnalysisDebug.legacy(Operations<Variable, Type> operations,
      AssignedVariables<Node, Variable> assignedVariables) {
    print('FlowAnalysisDebug.legacy()');
    return new FlowAnalysisDebug._(
        new _LegacyTypePromotion(operations, assignedVariables));
  }

  FlowAnalysisDebug._(this._wrapped);

  @override
  bool get isReachable =>
      _wrap('isReachable', () => _wrapped.isReachable, isQuery: true);

  @override
  TypeOperations<Type> get operations => _wrapped.operations;

  @override
  void asExpression_end(Expression subExpression, Type type) {
    _wrap('asExpression_end($subExpression, $type)',
        () => _wrapped.asExpression_end(subExpression, type));
  }

  @override
  void assert_afterCondition(Expression condition) {
    _wrap('assert_afterCondition($condition)',
        () => _wrapped.assert_afterCondition(condition));
  }

  @override
  void assert_begin() {
    _wrap('assert_begin()', () => _wrapped.assert_begin());
  }

  @override
  void assert_end() {
    _wrap('assert_end()', () => _wrapped.assert_end());
  }

  @override
  void assignedVariablePattern(Node node, Variable variable, Type writtenType) {
    _wrap('assignedVariablePattern($node, $variable, $writtenType)',
        () => _wrapped.assignedVariablePattern(node, variable, writtenType));
  }

  @override
  void assignMatchedPatternVariable(Variable variable, int promotionKey) {
    _wrap('assignMatchedPatternVariable($variable, $promotionKey)',
        () => _wrapped.assignMatchedPatternVariable(variable, promotionKey));
  }

  @override
  void booleanLiteral(Expression expression, bool value) {
    _wrap('booleanLiteral($expression, $value)',
        () => _wrapped.booleanLiteral(expression, value));
  }

  @override
  void conditional_conditionBegin() {
    _wrap('conditional_conditionBegin()',
        () => _wrapped.conditional_conditionBegin());
  }

  @override
  void conditional_elseBegin(Expression thenExpression) {
    _wrap('conditional_elseBegin($thenExpression',
        () => _wrapped.conditional_elseBegin(thenExpression));
  }

  @override
  void conditional_end(
      Expression conditionalExpression, Expression elseExpression) {
    _wrap('conditional_end($conditionalExpression, $elseExpression',
        () => _wrapped.conditional_end(conditionalExpression, elseExpression));
  }

  @override
  void conditional_thenBegin(Expression condition, Node conditionalExpression) {
    _wrap('conditional_thenBegin($condition, $conditionalExpression)',
        () => _wrapped.conditional_thenBegin(condition, conditionalExpression));
  }

  @override
  void constantPattern_end(Expression expression, Type type,
      {required bool patternsEnabled}) {
    _wrap(
        'constantPattern_end($expression, $type, '
        'patternsEnabled: $patternsEnabled)',
        () => _wrapped.constantPattern_end(expression, type,
            patternsEnabled: patternsEnabled));
  }

  @override
  void copyPromotionData(
      {required int sourceKey, required int destinationKey}) {
    _wrap(
        'copyPromotionData(sourceKey: $sourceKey, '
        'destinationKey: $destinationKey)',
        () => _wrapped.copyPromotionData(
            sourceKey: sourceKey, destinationKey: destinationKey));
  }

  @override
  void declare(Variable variable, Type staticType,
      {required bool initialized, bool skipDuplicateCheck = false}) {
    _wrap(
        'declare($variable, $staticType, '
        'initialized: $initialized, skipDuplicateCheck: $skipDuplicateCheck)',
        () => _wrapped.declare(variable, staticType,
            initialized: initialized, skipDuplicateCheck: skipDuplicateCheck));
  }

  @override
  int declaredVariablePattern(
      {required Type matchedType,
      required Type staticType,
      Expression? initializerExpression,
      bool isFinal = false,
      bool isLate = false,
      required bool isImplicitlyTyped}) {
    return _wrap(
        'declaredVariablePattern(matchedType: $matchedType, '
        'staticType: $staticType, '
        'initializerExpression: $initializerExpression, isFinal: $isFinal, '
        'isLate: $isLate, isImplicitlyTyped: $isImplicitlyTyped)',
        () => _wrapped.declaredVariablePattern(
            matchedType: matchedType,
            staticType: staticType,
            initializerExpression: initializerExpression,
            isFinal: isFinal,
            isLate: isLate,
            isImplicitlyTyped: isImplicitlyTyped),
        isQuery: true,
        isPure: false);
  }

  @override
  void doStatement_bodyBegin(Statement doStatement) {
    return _wrap('doStatement_bodyBegin($doStatement)',
        () => _wrapped.doStatement_bodyBegin(doStatement));
  }

  @override
  void doStatement_conditionBegin() {
    return _wrap('doStatement_conditionBegin()',
        () => _wrapped.doStatement_conditionBegin());
  }

  @override
  void doStatement_end(Expression condition) {
    return _wrap('doStatement_end($condition)',
        () => _wrapped.doStatement_end(condition));
  }

  @override
  EqualityInfo<Type>? equalityOperand_end(Expression operand, Type type) =>
      _wrap('equalityOperand_end($operand, $type)',
          () => _wrapped.equalityOperand_end(operand, type),
          isQuery: true);

  @override
  void equalityOperation_end(Expression wholeExpression,
      EqualityInfo<Type>? leftOperandInfo, EqualityInfo<Type>? rightOperandInfo,
      {bool notEqual = false}) {
    _wrap(
        'equalityOperation_end($wholeExpression, $leftOperandInfo, '
        '$rightOperandInfo, notEqual: $notEqual)',
        () => _wrapped.equalityOperation_end(
            wholeExpression, leftOperandInfo, rightOperandInfo,
            notEqual: notEqual));
  }

  @override
  void equalityRelationalPattern_end(Expression operand, Type operandType,
      {bool notEqual = false}) {
    _wrap(
        'equalityRelationalPattern_end($operand, $operandType, '
        'notEqual: $notEqual)',
        () => _wrapped.equalityRelationalPattern_end(operand, operandType,
            notEqual: notEqual));
  }

  @override
  ExpressionInfo<Type>? expressionInfoForTesting(Expression target) {
    return _wrap('expressionInfoForTesting($target)',
        () => _wrapped.expressionInfoForTesting(target),
        isQuery: true);
  }

  @override
  void finish() {
    if (_exceptionOccurred) {
      _wrap('finish() (skipped)', () {}, isPure: true);
    } else {
      _wrap('finish()', () => _wrapped.finish(), isPure: true);
    }
  }

  @override
  void for_bodyBegin(Statement? node, Expression? condition) {
    _wrap('for_bodyBegin($node, $condition)',
        () => _wrapped.for_bodyBegin(node, condition));
  }

  @override
  void for_conditionBegin(Node node) {
    _wrap('for_conditionBegin($node)', () => _wrapped.for_conditionBegin(node));
  }

  @override
  void for_end() {
    _wrap('for_end()', () => _wrapped.for_end());
  }

  @override
  void for_updaterBegin() {
    _wrap('for_updaterBegin()', () => _wrapped.for_updaterBegin());
  }

  @override
  void forEach_bodyBegin(Node node) {
    return _wrap(
        'forEach_bodyBegin($node)', () => _wrapped.forEach_bodyBegin(node));
  }

  @override
  void forEach_end() {
    return _wrap('forEach_end()', () => _wrapped.forEach_end());
  }

  @override
  void forwardExpression(Expression newExpression, Expression oldExpression) {
    return _wrap('forwardExpression($newExpression, $oldExpression)',
        () => _wrapped.forwardExpression(newExpression, oldExpression));
  }

  @override
  void functionExpression_begin(Node node) {
    _wrap('functionExpression_begin($node)',
        () => _wrapped.functionExpression_begin(node));
  }

  @override
  void functionExpression_end() {
    _wrap('functionExpression_end()', () => _wrapped.functionExpression_end());
  }

  @override
  Type getMatchedValueType() {
    return _wrap('getMatchedValueType()', () => _wrapped.getMatchedValueType(),
        isQuery: true);
  }

  @override
  void handleBreak(Statement? target) {
    _wrap('handleBreak($target)', () => _wrapped.handleBreak(target));
  }

  @override
  void handleContinue(Statement? target) {
    _wrap('handleContinue($target)', () => _wrapped.handleContinue(target));
  }

  @override
  void handleExit() {
    _wrap('handleExit()', () => _wrapped.handleExit());
  }

  @override
  void ifCaseStatement_afterExpression(
      Expression scrutinee, Type scrutineeType) {
    _wrap(
        'ifCaseStatement_afterExpression($scrutinee, $scrutineeType)',
        () =>
            _wrapped.ifCaseStatement_afterExpression(scrutinee, scrutineeType));
  }

  @override
  void ifCaseStatement_begin() {
    _wrap('ifCaseStatement_begin()', () => _wrapped.ifCaseStatement_begin());
  }

  @override
  void ifCaseStatement_thenBegin(Expression? guard) {
    _wrap('ifCaseStatement_thenBegin($guard)',
        () => _wrapped.ifCaseStatement_thenBegin(guard));
  }

  @override
  void ifNullExpression_end() {
    return _wrap(
        'ifNullExpression_end()', () => _wrapped.ifNullExpression_end());
  }

  @override
  void ifNullExpression_rightBegin(
      Expression leftHandSide, Type leftHandSideType) {
    _wrap(
        'ifNullExpression_rightBegin($leftHandSide, $leftHandSideType)',
        () => _wrapped.ifNullExpression_rightBegin(
            leftHandSide, leftHandSideType));
  }

  @override
  void ifStatement_conditionBegin() {
    return _wrap('ifStatement_conditionBegin()',
        () => _wrapped.ifStatement_conditionBegin());
  }

  @override
  void ifStatement_elseBegin() {
    return _wrap(
        'ifStatement_elseBegin()', () => _wrapped.ifStatement_elseBegin());
  }

  @override
  void ifStatement_end(bool hasElse) {
    _wrap('ifStatement_end($hasElse)', () => _wrapped.ifStatement_end(hasElse));
  }

  @override
  void ifStatement_thenBegin(Expression? condition, Node ifNode) {
    _wrap('ifStatement_thenBegin($condition, $ifNode)',
        () => _wrapped.ifStatement_thenBegin(condition, ifNode));
  }

  @override
  void initialize(
      Variable variable, Type matchedType, Expression? initializerExpression,
      {required bool isFinal,
      required bool isLate,
      required bool isImplicitlyTyped}) {
    _wrap(
        'initialize($variable, $matchedType, $initializerExpression, '
        'isFinal: $isFinal, isLate: $isLate, '
        'isImplicitlyTyped: $isImplicitlyTyped)',
        () => _wrapped.initialize(variable, matchedType, initializerExpression,
            isFinal: isFinal,
            isLate: isLate,
            isImplicitlyTyped: isImplicitlyTyped));
  }

  @override
  bool isAssigned(Variable variable) {
    return _wrap('isAssigned($variable)', () => _wrapped.isAssigned(variable),
        isQuery: true);
  }

  @override
  void isExpression_end(Expression isExpression, Expression subExpression,
      bool isNot, Type type) {
    _wrap(
        'isExpression_end($isExpression, $subExpression, $isNot, $type)',
        () => _wrapped.isExpression_end(
            isExpression, subExpression, isNot, type));
  }

  @override
  bool isUnassigned(Variable variable) {
    return _wrap(
        'isUnassigned($variable)', () => _wrapped.isUnassigned(variable),
        isQuery: true);
  }

  @override
  void labeledStatement_begin(Statement node) {
    return _wrap('labeledStatement_begin($node)',
        () => _wrapped.labeledStatement_begin(node));
  }

  @override
  void labeledStatement_end() {
    return _wrap(
        'labeledStatement_end()', () => _wrapped.labeledStatement_end());
  }

  @override
  void lateInitializer_begin(Node node) {
    _wrap('lateInitializer_begin($node)',
        () => _wrapped.lateInitializer_begin(node));
  }

  @override
  void lateInitializer_end() {
    _wrap('lateInitializer_end()', () => _wrapped.lateInitializer_end());
  }

  @override
  void logicalBinaryOp_begin() {
    _wrap('logicalBinaryOp_begin()', () => _wrapped.logicalBinaryOp_begin());
  }

  @override
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {required bool isAnd}) {
    _wrap(
        'logicalBinaryOp_end($wholeExpression, $rightOperand, isAnd: $isAnd)',
        () => _wrapped.logicalBinaryOp_end(wholeExpression, rightOperand,
            isAnd: isAnd));
  }

  @override
  void logicalBinaryOp_rightBegin(Expression leftOperand, Node wholeExpression,
      {required bool isAnd}) {
    _wrap(
        'logicalBinaryOp_rightBegin($leftOperand, $wholeExpression, '
        'isAnd: $isAnd)',
        () => _wrapped.logicalBinaryOp_rightBegin(leftOperand, wholeExpression,
            isAnd: isAnd));
  }

  @override
  void logicalNot_end(Expression notExpression, Expression operand) {
    return _wrap('logicalNot_end($notExpression, $operand)',
        () => _wrapped.logicalNot_end(notExpression, operand));
  }

  @override
  void logicalOrPattern_afterLhs() {
    _wrap('logicalOrPattern_afterLhs()',
        () => _wrapped.logicalOrPattern_afterLhs());
  }

  @override
  void logicalOrPattern_begin() {
    _wrap('logicalOrPattern_begin()', () => _wrapped.logicalOrPattern_begin());
  }

  @override
  void logicalOrPattern_end() {
    _wrap('logicalOrPattern_end()', () => _wrapped.logicalOrPattern_end());
  }

  @override
  void nonEqualityRelationalPattern_end() {
    _wrap('nonEqualityRelationalPattern_end()',
        () => _wrapped.nonEqualityRelationalPattern_end());
  }

  @override
  void nonNullAssert_end(Expression operand) {
    return _wrap('nonNullAssert_end($operand)',
        () => _wrapped.nonNullAssert_end(operand));
  }

  @override
  void nullAwareAccess_end() {
    _wrap('nullAwareAccess_end()', () => _wrapped.nullAwareAccess_end());
  }

  @override
  void nullAwareAccess_rightBegin(Expression? target, Type targetType) {
    _wrap('nullAwareAccess_rightBegin($target, $targetType)',
        () => _wrapped.nullAwareAccess_rightBegin(target, targetType));
  }

  @override
  bool nullCheckOrAssertPattern_begin({required bool isAssert}) {
    return _wrap('nullCheckOrAssertPattern_begin(isAssert: $isAssert)',
        () => _wrapped.nullCheckOrAssertPattern_begin(isAssert: isAssert),
        isQuery: true, isPure: false);
  }

  @override
  void nullCheckOrAssertPattern_end() {
    _wrap('nullCheckOrAssertPattern_end()',
        () => _wrapped.nullCheckOrAssertPattern_end());
  }

  @override
  void nullLiteral(Expression expression) {
    _wrap('nullLiteral($expression)', () => _wrapped.nullLiteral(expression));
  }

  @override
  void parenthesizedExpression(
      Expression outerExpression, Expression innerExpression) {
    _wrap(
        'parenthesizedExpression($outerExpression, $innerExpression)',
        () =>
            _wrapped.parenthesizedExpression(outerExpression, innerExpression));
  }

  @override
  void patternAssignment_afterRhs(Expression rhs, Type rhsType) {
    _wrap('patternAssignment_afterRhs($rhs, $rhsType)',
        () => _wrapped.patternAssignment_afterRhs(rhs, rhsType));
  }

  @override
  void patternAssignment_end() {
    _wrap('patternAssignment_end()', () => _wrapped.patternAssignment_end());
  }

  @override
  void patternForIn_afterExpression(Type elementType) {
    _wrap(
      'patternForIn_afterExpression($elementType)',
      () => _wrapped.patternForIn_afterExpression(elementType),
    );
  }

  @override
  void patternForIn_end() {
    _wrap('patternForIn_end()', () => _wrapped.patternForIn_end());
  }

  @override
  void patternVariableDeclaration_afterInitializer(
      Expression initializer, Type initializerType) {
    _wrap(
        'patternVariableDeclaration_afterInitializer($initializer, '
        '$initializerType)',
        () => _wrapped.patternVariableDeclaration_afterInitializer(
            initializer, initializerType));
  }

  @override
  void patternVariableDeclaration_end() {
    _wrap('patternVariableDeclaration_end()',
        () => _wrapped.patternVariableDeclaration_end());
  }

  @override
  void popSubpattern() {
    _wrap('popSubpattern()', () => _wrapped.popSubpattern());
  }

  @override
  Type? promotedPropertyType(Expression? target, String propertyName,
      Object? propertyMember, Type staticType) {
    return _wrap(
        'promotedPropertyType($target, $propertyName, $propertyMember, '
        '$staticType)',
        () => _wrapped.promotedPropertyType(
            target, propertyName, propertyMember, staticType),
        isQuery: true);
  }

  @override
  Type? promotedType(Variable variable) {
    return _wrap(
        'promotedType($variable)', () => _wrapped.promotedType(variable),
        isQuery: true);
  }

  @override
  bool promoteForPattern(
      {required Type matchedType,
      required Type knownType,
      bool matchFailsIfWrongType = true,
      bool matchMayFailEvenIfCorrectType = false}) {
    return _wrap(
        'patternRequiredType(matchedType: $matchedType, '
        'requiredType: $knownType, '
        'matchFailsIfWrongType: $matchFailsIfWrongType, '
        'matchMayFailEvenIfCorrectType: $matchMayFailEvenIfCorrectType)',
        () => _wrapped.promoteForPattern(
            matchedType: matchedType,
            knownType: knownType,
            matchFailsIfWrongType: matchFailsIfWrongType,
            matchMayFailEvenIfCorrectType: matchMayFailEvenIfCorrectType),
        isQuery: true,
        isPure: false);
  }

  @override
  Type? propertyGet(Expression? wholeExpression, Expression target,
      String propertyName, Object? propertyMember, Type staticType) {
    return _wrap(
        'propertyGet($wholeExpression, $target, $propertyName, '
        '$propertyMember, $staticType)',
        () => _wrapped.propertyGet(
            wholeExpression, target, propertyName, propertyMember, staticType),
        isQuery: true,
        isPure: false);
  }

  @override
  void pushSubpattern(Type matchedType) {
    _wrap('pushSubpattern($matchedType)',
        () => _wrapped.pushSubpattern(matchedType));
  }

  @override
  SsaNode<Type>? ssaNodeForTesting(Variable variable) {
    return _wrap('ssaNodeForTesting($variable)',
        () => _wrapped.ssaNodeForTesting(variable),
        isQuery: true);
  }

  @override
  bool switchStatement_afterCase() {
    return _wrap('switchStatement_afterCase()',
        () => _wrapped.switchStatement_afterCase(),
        isPure: false, isQuery: true);
  }

  @override
  void switchStatement_beginAlternative() {
    _wrap('switchStatement_beginAlternative()',
        () => _wrapped.switchStatement_beginAlternative());
  }

  @override
  void switchStatement_beginAlternatives() {
    _wrap('switchStatement_beginAlternatives()',
        () => _wrapped.switchStatement_beginAlternatives());
  }

  @override
  bool switchStatement_end(bool isExhaustive) {
    return _wrap('switchStatement_end($isExhaustive)',
        () => _wrapped.switchStatement_end(isExhaustive),
        isQuery: true, isPure: false);
  }

  @override
  void switchStatement_endAlternative(
      Expression? guard, Map<String, Variable> variables) {
    _wrap('switchStatement_endAlternative($guard, $variables)',
        () => _wrapped.switchStatement_endAlternative(guard, variables));
  }

  @override
  PatternVariableInfo<Variable> switchStatement_endAlternatives(Statement? node,
      {required bool hasLabels}) {
    return _wrap(
        'switchStatement_endAlternatives($node, hasLabels: $hasLabels)',
        () => _wrapped.switchStatement_endAlternatives(node,
            hasLabels: hasLabels),
        isQuery: true,
        isPure: false);
  }

  @override
  void switchStatement_expressionEnd(
      Statement? switchStatement, Expression scrutinee, Type scrutineeType) {
    _wrap(
        'switchStatement_expressionEnd($switchStatement, $scrutinee, '
        '$scrutineeType)',
        () => _wrapped.switchStatement_expressionEnd(
            switchStatement, scrutinee, scrutineeType));
  }

  @override
  void thisOrSuper(Expression expression, Type staticType) {
    return _wrap('thisOrSuper($expression, $staticType)',
        () => _wrapped.thisOrSuper(expression, staticType));
  }

  @override
  Type? thisOrSuperPropertyGet(Expression expression, String propertyName,
      Object? propertyMember, Type staticType) {
    return _wrap(
        'thisOrSuperPropertyGet($expression, $propertyName, $propertyMember, '
        '$staticType)',
        () => _wrapped.thisOrSuperPropertyGet(
            expression, propertyName, propertyMember, staticType),
        isQuery: false,
        isPure: false);
  }

  @override
  void tryCatchStatement_bodyBegin() {
    return _wrap('tryCatchStatement_bodyBegin()',
        () => _wrapped.tryCatchStatement_bodyBegin());
  }

  @override
  void tryCatchStatement_bodyEnd(Node body) {
    return _wrap('tryCatchStatement_bodyEnd($body)',
        () => _wrapped.tryCatchStatement_bodyEnd(body));
  }

  @override
  void tryCatchStatement_catchBegin(
      Variable? exceptionVariable, Variable? stackTraceVariable) {
    return _wrap(
        'tryCatchStatement_catchBegin($exceptionVariable, $stackTraceVariable)',
        () => _wrapped.tryCatchStatement_catchBegin(
            exceptionVariable, stackTraceVariable));
  }

  @override
  void tryCatchStatement_catchEnd() {
    return _wrap('tryCatchStatement_catchEnd()',
        () => _wrapped.tryCatchStatement_catchEnd());
  }

  @override
  void tryCatchStatement_end() {
    return _wrap(
        'tryCatchStatement_end()', () => _wrapped.tryCatchStatement_end());
  }

  @override
  void tryFinallyStatement_bodyBegin() {
    return _wrap('tryFinallyStatement_bodyBegin()',
        () => _wrapped.tryFinallyStatement_bodyBegin());
  }

  @override
  void tryFinallyStatement_end() {
    return _wrap(
        'tryFinallyStatement_end()', () => _wrapped.tryFinallyStatement_end());
  }

  @override
  void tryFinallyStatement_finallyBegin(Node body) {
    return _wrap('tryFinallyStatement_finallyBegin($body)',
        () => _wrapped.tryFinallyStatement_finallyBegin(body));
  }

  @override
  Type? variableRead(Expression expression, Variable variable) {
    return _wrap('variableRead($expression, $variable)',
        () => _wrapped.variableRead(expression, variable),
        isQuery: true, isPure: false);
  }

  @override
  void whileStatement_bodyBegin(
      Statement whileStatement, Expression condition) {
    return _wrap('whileStatement_bodyBegin($whileStatement, $condition)',
        () => _wrapped.whileStatement_bodyBegin(whileStatement, condition));
  }

  @override
  void whileStatement_conditionBegin(Node node) {
    return _wrap('whileStatement_conditionBegin($node)',
        () => _wrapped.whileStatement_conditionBegin(node));
  }

  @override
  void whileStatement_end() {
    return _wrap('whileStatement_end()', () => _wrapped.whileStatement_end());
  }

  @override
  Map<Type, NonPromotionReason> Function() whyNotPromoted(Expression target) {
    return _wrap('whyNotPromoted($target)',
        () => _trackWhyNotPromoted(_wrapped.whyNotPromoted(target)),
        isQuery: true);
  }

  @override
  Map<Type, NonPromotionReason> Function() whyNotPromotedImplicitThis(
      Type staticType) {
    return _wrap(
        'whyNotPromotedImplicitThis($staticType)',
        () => _trackWhyNotPromoted(
            _wrapped.whyNotPromotedImplicitThis(staticType)),
        isQuery: true);
  }

  @override
  void write(Node node, Variable variable, Type writtenType,
      Expression? writtenExpression) {
    _wrap('write($node, $variable, $writtenType, $writtenExpression)',
        () => _wrapped.write(node, variable, writtenType, writtenExpression));
  }

  @override
  void _dumpState() => _wrapped._dumpState();

  /// Wraps [callback] so that when it is called, the call (and its return
  /// value) will be printed to the console.  Also registers the wrapped
  /// callback in [_description] so that it will be given a unique identifier
  /// when printed to the console.
  Map<Type, NonPromotionReason> Function() _trackWhyNotPromoted(
      Map<Type, NonPromotionReason> Function() callback) {
    String callbackToString = '#CALLBACK${_nextCallbackId++}';
    Map<Type, NonPromotionReason> Function() wrappedCallback =
        () => _wrap('$callbackToString()', callback, isQuery: true);
    _description[wrappedCallback] = callbackToString;
    return wrappedCallback;
  }

  T _wrap<T>(String description, T callback(),
      {bool isQuery = false, bool? isPure}) {
    isPure ??= isQuery;
    print(description);
    T result;
    try {
      result = callback();
    } catch (e, st) {
      print('  => EXCEPTION $e');
      print('    ' + st.toString().replaceAll('\n', '\n    '));
      _exceptionOccurred = true;
      rethrow;
    }
    if (!isPure) {
      _wrapped._dumpState();
    }
    if (isQuery) {
      print('  => ${_describe(result)}');
    }
    return result;
  }

  static String _describe(Object? value) {
    if (value != null && value is! String && value is! num && value is! bool) {
      String? description = _description[value];
      if (description != null) return description;
    }
    return value.toString();
  }
}

/// An instance of the [FlowModel] class represents the information gathered by
/// flow analysis at a single point in the control flow of the function or
/// method being analyzed.
///
/// Instances of this class are immutable, so the methods below that "update"
/// the state actually leave `this` unchanged and return a new state object.
@visibleForTesting
class FlowModel<Type extends Object> {
  final Reachability reachable;

  /// For each promotable thing being tracked by flow analysis, the
  /// corresponding model.
  ///
  /// Flow analysis has no awareness of scope, so variables that are out of
  /// scope are retained in the map until such time as their declaration no
  /// longer dominates the control flow.  So, for example, if a variable is
  /// declared inside the `then` branch of an `if` statement, and the `else`
  /// branch of the `if` statement ends in a `return` statement, then the
  /// variable remains in the map after the `if` statement ends, even though the
  /// variable is not in scope anymore.  This should not have any effect on
  /// analysis results for error-free code, because it is an error to refer to a
  /// variable that is no longer in scope.
  ///
  /// Keys are the unique integers assigned by
  /// [_FlowAnalysisImpl._promotionKeyStore].
  final Map<int, VariableModel<Type> /*!*/ > variableInfo;

  /// The empty map, used to [join] variables.
  final Map<int, VariableModel<Type>> _emptyVariableMap = {};

  /// Creates a state object with the given [reachable] status.  All variables
  /// are assumed to be unpromoted and already assigned, so joining another
  /// state with this one will have no effect on it.
  FlowModel(Reachability reachable)
      : this.withInfo(
          reachable,
          const {},
        );

  @visibleForTesting
  FlowModel.withInfo(this.reachable, this.variableInfo) {
    // ignore:unnecessary_null_comparison
    assert(reachable != null);
    assert(() {
      for (VariableModel<Type> value in variableInfo.values) {
        // ignore:unnecessary_null_comparison
        assert(value != null);
      }
      return true;
    }());
  }

  /// Computes the effect of executing a try/finally's `try` and `finally`
  /// blocks in sequence.  `this` is the flow analysis state from the end of the
  /// `try` block; [beforeFinally] and [afterFinally] are the flow analysis
  /// states from the top and bottom of the `finally` block, respectively.
  ///
  /// Initially the `finally` block is analyzed under the conservative
  /// assumption that the `try` block might have been interrupted at any point
  /// by an exception occurring, therefore no variable assignments or promotions
  /// that occurred in the `try` block can be relied upon.  As a result, when we
  /// get to the end of processing the `finally` block, the only promotions and
  /// variable assignments accounted for by flow analysis are the ones performed
  /// within the `finally` block itself.  However, when we analyze code that
  /// follows the `finally` block, we know that the `try` block did *not* throw
  /// an exception, so we want to reinstate the results of any promotions and
  /// assignments that occurred during the `try` block, to the extent that they
  /// weren't invalidated by later assignments in the `finally` block.
  FlowModel<Type> attachFinally(TypeOperations<Type> typeOperations,
      FlowModel<Type> beforeFinally, FlowModel<Type> afterFinally) {
    // Code that follows the `try/finally` is reachable iff the end of the `try`
    // block is reachable _and_ the end of the `finally` block is reachable.
    Reachability newReachable = afterFinally.reachable.rebaseForward(reachable);

    // Consider each variable that is common to all three models.
    Map<int, VariableModel<Type>> newVariableInfo =
        <int, VariableModel<Type>>{};
    bool variableInfoMatchesThis = true;
    bool variableInfoMatchesAfterFinally = true;
    for (MapEntry<int, VariableModel<Type>> entry in variableInfo.entries) {
      int promotionKey = entry.key;
      VariableModel<Type> thisModel = entry.value;
      VariableModel<Type>? beforeFinallyModel =
          beforeFinally.variableInfo[promotionKey];
      VariableModel<Type>? afterFinallyModel =
          afterFinally.variableInfo[promotionKey];
      if (beforeFinallyModel == null || afterFinallyModel == null) {
        // The variable is in `this` model but not in one of the `finally`
        // models.  This happens when the variable is declared inside the `try`
        // block.  We can just drop the variable because it won't be in scope
        // after the try/finally statement.
        variableInfoMatchesThis = false;
        continue;
      }
      // We can just use the "write captured" state from the `finally` block,
      // because any write captures in the `try` block are conservatively
      // considered to take effect in the `finally` block too.
      List<Type>? newPromotedTypes;
      SsaNode<Type>? newSsaNode;
      if (beforeFinallyModel.ssaNode == afterFinallyModel.ssaNode) {
        // The finally clause doesn't write to the variable, so we want to keep
        // all promotions that were done to it in both the try and finally
        // blocks.
        newPromotedTypes = VariableModel.rebasePromotedTypes(typeOperations,
            thisModel.promotedTypes, afterFinallyModel.promotedTypes);
        // And we can safely restore the SSA node from the end of the try block.
        newSsaNode = thisModel.ssaNode;
      } else {
        // A write to the variable occurred in the finally block, so promotions
        // from the try block aren't necessarily valid.
        newPromotedTypes = afterFinallyModel.promotedTypes;
        // And we can't safely restore the SSA node from the end of the try
        // block; we need to keep the one from the end of the finally block.
        newSsaNode = afterFinallyModel.ssaNode;
      }
      // The `finally` block inherited all tests from the `try` block so we can
      // just inherit tests from it.
      List<Type> newTested = afterFinallyModel.tested;
      // The variable is definitely assigned if it was definitely assigned in
      // either the `try` or the `finally` block.
      bool newAssigned = thisModel.assigned || afterFinallyModel.assigned;
      // The `finally` block inherited the "unassigned" state from the `try`
      // block so we can just inherit from it.
      bool newUnassigned = afterFinallyModel.unassigned;
      VariableModel<Type> newModel = VariableModel._identicalOrNew(
          thisModel,
          afterFinallyModel,
          newPromotedTypes,
          newTested,
          newAssigned,
          newUnassigned,
          newSsaNode);
      newVariableInfo[promotionKey] = newModel;
      if (!identical(newModel, thisModel)) variableInfoMatchesThis = false;
      if (!identical(newModel, afterFinallyModel)) {
        variableInfoMatchesAfterFinally = false;
      }
    }
    // newVariableInfo is now correct.  However, if there are any variables
    // present in `afterFinally` that aren't present in `this`, we may
    // erroneously think that `newVariableInfo` matches `afterFinally`.  If so,
    // correct that.
    if (variableInfoMatchesAfterFinally) {
      for (int promotionKey in afterFinally.variableInfo.keys) {
        if (!variableInfo.containsKey(promotionKey)) {
          variableInfoMatchesAfterFinally = false;
          break;
        }
      }
    }
    assert(variableInfoMatchesThis ==
        _variableInfosEqual(newVariableInfo, variableInfo));
    assert(variableInfoMatchesAfterFinally ==
        _variableInfosEqual(newVariableInfo, afterFinally.variableInfo));
    if (variableInfoMatchesThis) {
      newVariableInfo = variableInfo;
    } else if (variableInfoMatchesAfterFinally) {
      newVariableInfo = afterFinally.variableInfo;
    }

    return _identicalOrNew(this, afterFinally, newReachable, newVariableInfo);
  }

  /// Updates the state to indicate that the given [writtenVariables] are no
  /// longer promoted and are no longer definitely unassigned, and the given
  /// [capturedVariables] have been captured by closures.
  ///
  /// This is used at the top of loops to conservatively cancel the promotion of
  /// variables that are modified within the loop, so that we correctly analyze
  /// code like the following:
  ///
  ///     if (x is int) {
  ///       x.isEven; // OK, promoted to int
  ///       while (true) {
  ///         x.isEven; // ERROR: promotion lost
  ///         x = 'foo';
  ///       }
  ///     }
  ///
  /// Note that a more accurate analysis would be to iterate to a fixed point,
  /// and only remove promotions if it can be shown that they aren't restored
  /// later in the loop body.  If we switch to a fixed point analysis, we should
  /// be able to remove this method.
  FlowModel<Type> conservativeJoin(FlowModelHelper<Type> helper,
      Iterable<int> writtenVariables, Iterable<int> capturedVariables) {
    FlowModel<Type>? newModel;

    for (int variableKey in writtenVariables) {
      VariableModel<Type>? info = variableInfo[variableKey];
      if (info == null) continue;
      VariableModel<Type> newInfo =
          info.discardPromotionsAndMarkNotUnassigned();
      if (!identical(info, newInfo)) {
        (newModel ??= _clone()).variableInfo[variableKey] = newInfo;
      }
      newModel =
          _discardDependentPropertyPromotions(helper, newModel, variableKey);
    }

    for (int variableKey in capturedVariables) {
      VariableModel<Type>? info = variableInfo[variableKey];
      if (info == null) continue;
      if (!info.writeCaptured) {
        (newModel ??= _clone()).variableInfo[variableKey] = info.writeCapture();
        // Note: there's no need to discard dependent property promotions,
        // because when deciding whether a property is promoted,
        // [_FlowAnalysisImpl._handleProperty] checks whether the variable is
        // captured.
      }
    }

    return newModel ?? this;
  }

  /// Register a declaration of the variable whose key is [variableKey].
  /// Should also be called for function parameters.
  ///
  /// A local variable is [initialized] if its declaration has an initializer.
  /// A function parameter is always initialized, so [initialized] is `true`.
  FlowModel<Type> declare(int variableKey, bool initialized) {
    VariableModel<Type> newInfoForVar =
        new VariableModel.fresh(assigned: initialized);

    return _updateVariableInfo(variableKey, newInfoForVar);
  }

  /// Gets the info for the given [promotionKey], creating it if it doesn't
  /// exist.
  VariableModel<Type> infoFor(int promotionKey) =>
      variableInfo[promotionKey] ?? new VariableModel.fresh();

  /// Builds a [FlowModel] based on `this`, but extending the `tested` set to
  /// include types from [other].  This is used at the bottom of certain kinds
  /// of loops, to ensure that types tested within the body of the loop are
  /// consistently treated as "of interest" in code that follows the loop,
  /// regardless of the type of loop.
  @visibleForTesting
  FlowModel<Type> inheritTested(
      TypeOperations<Type> typeOperations, FlowModel<Type> other) {
    Map<int, VariableModel<Type>> newVariableInfo =
        <int, VariableModel<Type>>{};
    Map<int, VariableModel<Type>> otherVariableInfo = other.variableInfo;
    bool changed = false;
    for (MapEntry<int, VariableModel<Type>> entry in variableInfo.entries) {
      int promotionKey = entry.key;
      VariableModel<Type> variableModel = entry.value;
      VariableModel<Type>? otherVariableModel = otherVariableInfo[promotionKey];
      VariableModel<Type> newVariableModel = otherVariableModel == null
          ? variableModel
          : VariableModel.inheritTested(
              typeOperations, variableModel, otherVariableModel.tested);
      newVariableInfo[promotionKey] = newVariableModel;
      if (!identical(newVariableModel, variableModel)) changed = true;
    }
    if (changed) {
      return new FlowModel<Type>.withInfo(reachable, newVariableInfo);
    } else {
      return this;
    }
  }

  /// Updates `this` flow model to account for any promotions and assignments
  /// present in [base].
  ///
  /// This is called "rebasing" the flow model by analogy to "git rebase"; in
  /// effect, it rewinds any flow analysis state present in `this` but not in
  /// the history of [base], and then reapplies that state using [base] as a
  /// starting point, to the extent possible without creating unsoundness.  For
  /// example, if a variable is promoted in `this` but not in [base], then it
  /// will be promoted in the output model, provided that hasn't been reassigned
  /// since then (which would make the promotion unsound).
  FlowModel<Type> rebaseForward(
      TypeOperations<Type> typeOperations, FlowModel<Type> base) {
    // The rebased model is reachable iff both `this` and the new base are
    // reachable.
    Reachability newReachable = reachable.rebaseForward(base.reachable);

    // Consider each variable in the new base model.
    Map<int, VariableModel<Type>> newVariableInfo =
        <int, VariableModel<Type>>{};
    bool variableInfoMatchesThis = true;
    bool variableInfoMatchesBase = true;
    for (MapEntry<int, VariableModel<Type>> entry
        in base.variableInfo.entries) {
      int promotionKey = entry.key;
      VariableModel<Type> baseModel = entry.value;
      VariableModel<Type>? thisModel = variableInfo[promotionKey];
      if (thisModel == null) {
        // The variable has newly came into scope since `thisModel`, so the
        // information in `baseModel` is up to date.
        newVariableInfo[promotionKey] = baseModel;
        variableInfoMatchesThis = false;
        continue;
      }
      // If the variable was write captured in either `this` or the new base,
      // it's captured now.
      bool newWriteCaptured =
          thisModel.writeCaptured || baseModel.writeCaptured;
      List<Type>? newPromotedTypes;
      if (newWriteCaptured) {
        // Write captured variables can't be promoted.
        newPromotedTypes = null;
      } else if (baseModel.ssaNode != thisModel.ssaNode) {
        // The variable may have been written to since `thisModel`, so we can't
        // use any of the promotions from `thisModel`.
        newPromotedTypes = baseModel.promotedTypes;
      } else {
        // The variable hasn't been written to since `thisModel`, so we can keep
        // all of the promotions from `thisModel`, provided that we retain the
        // usual "promotion chain" invariant (each promoted type is a subtype of
        // the previous).
        newPromotedTypes = VariableModel.rebasePromotedTypes(
            typeOperations, thisModel.promotedTypes, baseModel.promotedTypes);
      }
      // Tests are kept regardless of whether they are in `this` model or the
      // new base model.
      List<Type> newTested = VariableModel.joinTested(
          thisModel.tested, baseModel.tested, typeOperations);
      // The variable is definitely assigned if it was definitely assigned
      // either in `this` model or the new base model.
      bool newAssigned = thisModel.assigned || baseModel.assigned;
      // The variable is definitely unassigned if it was definitely unassigned
      // in both `this` model and the new base model.
      bool newUnassigned = thisModel.unassigned && baseModel.unassigned;
      VariableModel<Type> newModel = VariableModel._identicalOrNew(
          thisModel,
          baseModel,
          newPromotedTypes,
          newTested,
          newAssigned,
          newUnassigned,
          newWriteCaptured ? null : baseModel.ssaNode);
      newVariableInfo[promotionKey] = newModel;
      if (!identical(newModel, thisModel)) variableInfoMatchesThis = false;
      if (!identical(newModel, baseModel)) variableInfoMatchesBase = false;
    }
    // newVariableInfo is now correct.  However, if there are any variables
    // present in `this` that aren't present in `base`, we may erroneously think
    // that `newVariableInfo` matches `this`.  If so, correct that.
    if (variableInfoMatchesThis) {
      for (int promotionKey in variableInfo.keys) {
        if (!base.variableInfo.containsKey(promotionKey)) {
          variableInfoMatchesThis = false;
          break;
        }
      }
    }
    assert(variableInfoMatchesThis ==
        _variableInfosEqual(newVariableInfo, variableInfo));
    assert(variableInfoMatchesBase ==
        _variableInfosEqual(newVariableInfo, base.variableInfo));
    if (variableInfoMatchesThis) {
      newVariableInfo = variableInfo;
    } else if (variableInfoMatchesBase) {
      newVariableInfo = base.variableInfo;
    }

    return _identicalOrNew(this, base, newReachable, newVariableInfo);
  }

  /// Updates the state to indicate that the control flow path is unreachable.
  FlowModel<Type> setUnreachable() {
    if (!reachable.locallyReachable) return this;

    return new FlowModel<Type>.withInfo(
        reachable.setUnreachable(), variableInfo);
  }

  /// Returns a [FlowModel] indicating the result of creating a control flow
  /// split.  See [Reachability.split] for more information.
  FlowModel<Type> split() =>
      new FlowModel<Type>.withInfo(reachable.split(), variableInfo);

  @override
  String toString() => '($reachable, $variableInfo)';

  /// Returns an [ExpressionInfo] indicating the result of checking whether the
  /// given [reference] is non-null.
  ///
  /// Note that the state is only changed if the previous type of [variable] was
  /// potentially nullable.
  ExpressionInfo<Type> tryMarkNonNullable(
      FlowModelHelper<Type> helper, ReferenceWithType<Type> referenceWithType) {
    VariableModel<Type> info = _getInfo(referenceWithType.promotionKey);
    if (info.writeCaptured) {
      return new _TrivialExpressionInfo<Type>(this);
    }

    Type previousType = referenceWithType.type;
    Type newType = helper.typeOperations.promoteToNonNull(previousType);
    if (helper.typeOperations.isSameType(newType, previousType)) {
      return new _TrivialExpressionInfo<Type>(this);
    }
    assert(helper.typeOperations.isSubtypeOf(newType, previousType));

    FlowModel<Type> ifTrue =
        _finishTypeTest(helper, referenceWithType, info, null, newType);

    return new ExpressionInfo<Type>(after: this, ifTrue: ifTrue, ifFalse: this);
  }

  /// Returns an [ExpressionInfo] indicating the result of casting the given
  /// [referenceWithType] to the given [type], as a consequence of an `as`
  /// expression.
  ///
  /// Note that the state is only changed if [type] is a subtype of the
  /// variable's previous (possibly promoted) type.
  ///
  /// TODO(paulberry): if the type is non-nullable, should this method mark the
  /// variable as definitely assigned?  Does it matter?
  FlowModel<Type> tryPromoteForTypeCast(FlowModelHelper<Type> helper,
      ReferenceWithType<Type> referenceWithType, Type type) {
    VariableModel<Type> info = _getInfo(referenceWithType.promotionKey);
    if (info.writeCaptured) {
      return this;
    }

    Type previousType = referenceWithType.type;
    Type? newType = helper.typeOperations.tryPromoteToType(type, previousType);
    if (newType == null ||
        helper.typeOperations.isSameType(newType, previousType)) {
      return this;
    }

    assert(helper.typeOperations.isSubtypeOf(newType, previousType),
        "Expected $newType to be a subtype of $previousType.");
    return _finishTypeTest(helper, referenceWithType, info, type, newType);
  }

  /// Returns an [ExpressionInfo] indicating the result of checking whether the
  /// given [reference] satisfies the given [type], e.g. as a consequence of an
  /// `is` expression as the condition of an `if` statement.
  ///
  /// Note that the "ifTrue" state is only changed if [type] is a subtype of
  /// the variable's previous (possibly promoted) type.
  ///
  /// TODO(paulberry): if the type is non-nullable, should this method mark the
  /// variable as definitely assigned?  Does it matter?
  ExpressionInfo<Type> tryPromoteForTypeCheck(FlowModelHelper<Type> helper,
      ReferenceWithType<Type> referenceWithType, Type type) {
    VariableModel<Type> info = _getInfo(referenceWithType.promotionKey);
    if (info.writeCaptured) {
      return new _TrivialExpressionInfo<Type>(this);
    }

    Type previousType = referenceWithType.type;
    FlowModel<Type> ifTrue = this;
    Type? typeIfSuccess =
        helper.typeOperations.tryPromoteToType(type, previousType);
    if (typeIfSuccess != null &&
        !helper.typeOperations.isSameType(typeIfSuccess, previousType)) {
      assert(helper.typeOperations.isSubtypeOf(typeIfSuccess, previousType),
          "Expected $typeIfSuccess to be a subtype of $previousType.");
      ifTrue =
          _finishTypeTest(helper, referenceWithType, info, type, typeIfSuccess);
    }

    Type factoredType = helper.typeOperations.factor(previousType, type);
    Type? typeIfFalse;
    if (helper.typeOperations.isNever(factoredType)) {
      // Promoting to `Never` would mark the code as unreachable.  But it might
      // be reachable due to mixed mode unsoundness.  So don't promote.
      typeIfFalse = null;
    } else if (helper.typeOperations.isSameType(factoredType, previousType)) {
      // No change to the type, so don't promote.
      typeIfFalse = null;
    } else {
      typeIfFalse = factoredType;
    }
    FlowModel<Type> ifFalse =
        _finishTypeTest(helper, referenceWithType, info, type, typeIfFalse);

    return new ExpressionInfo<Type>(
        after: this, ifTrue: ifTrue, ifFalse: ifFalse);
  }

  /// Returns a [FlowModel] indicating the result of removing a control flow
  /// split.  See [Reachability.unsplit] for more information.
  FlowModel<Type> unsplit() =>
      new FlowModel<Type>.withInfo(reachable.unsplit(), variableInfo);

  /// Removes control flow splits until a [FlowModel] is obtained whose
  /// reachability has the given [parent].
  FlowModel<Type> unsplitTo(Reachability parent) {
    if (identical(this.reachable.parent, parent)) return this;
    Reachability reachable = this.reachable.unsplit();
    while (!identical(reachable.parent, parent)) {
      reachable = reachable.unsplit();
    }
    return new FlowModel<Type>.withInfo(reachable, variableInfo);
  }

  /// Updates the state to indicate that an assignment was made to [variable],
  /// whose key is [variableKey].  The variable is marked as definitely
  /// assigned, and any previous type promotion is removed.
  ///
  /// If there is any chance that the write will cause a demotion, the caller
  /// must pass in a non-null value for [nonPromotionReason] describing the
  /// reason for any potential demotion.
  FlowModel<Type> write<Variable extends Object>(
      FlowModelHelper<Type> helper,
      NonPromotionReason? nonPromotionReason,
      int variableKey,
      Type writtenType,
      SsaNode<Type> newSsaNode,
      Operations<Variable, Type> operations,
      {bool promoteToTypeOfInterest = true,
      required Type unpromotedType}) {
    FlowModel<Type>? newModel;
    VariableModel<Type>? infoForVar = variableInfo[variableKey];
    if (infoForVar != null) {
      VariableModel<Type> newInfoForVar = infoForVar.write(
          nonPromotionReason, variableKey, writtenType, operations, newSsaNode,
          promoteToTypeOfInterest: promoteToTypeOfInterest,
          unpromotedType: unpromotedType);
      if (!identical(newInfoForVar, infoForVar)) {
        newModel = _updateVariableInfo(variableKey, newInfoForVar);
      }
    }
    newModel =
        _discardDependentPropertyPromotions(helper, newModel, variableKey);

    return newModel ?? this;
  }

  /// Makes a copy of `this` that can be safely edited.  Optional argument
  /// [reachable] may be used to specify a different reachability.
  FlowModel<Type> _clone({Reachability? reachable}) {
    return new FlowModel<Type>.withInfo(reachable ?? this.reachable,
        new Map<int, VariableModel<Type>>.of(variableInfo));
  }

  /// Discards promotions on any property (or property of a property) of
  /// the variable indicated by [variableKey].
  FlowModel<Type>? _discardDependentPropertyPromotions(
      FlowModelHelper<Type> helper,
      FlowModel<Type>? newModel,
      int variableKey) {
    for (int key = variableKey;
        (key = helper.promotionKeyStore.getNextKeyWithSameRoot(key)) !=
            variableKey;) {
      VariableModel<Type>? info = variableInfo[key];
      if (info != null && info.promotedTypes != null) {
        (newModel ??= _clone()).variableInfo[key] =
            info.discardPromotionsAndMarkNotUnassigned();
      }
    }
    return newModel;
  }

  /// Common algorithm for [tryMarkNonNullable], [tryPromoteForTypeCast],
  /// and [tryPromoteForTypeCheck].  Builds a [FlowModel] object describing the
  /// effect of updating the [reference] by adding the [testedType] to the
  /// list of tested types (if not `null`, and not there already), adding the
  /// [promotedType] to the chain of promoted types.
  ///
  /// Preconditions:
  /// - [info] should be the result of calling `infoFor(variable)`
  /// - [promotedType] should be a subtype of the currently-promoted type (i.e.
  ///   no redundant or side-promotions)
  /// - The variable should not be write-captured.
  FlowModel<Type> _finishTypeTest(
      FlowModelHelper<Type> helper,
      ReferenceWithType<Type> reference,
      VariableModel<Type> info,
      Type? testedType,
      Type? promotedType) {
    List<Type> newTested = info.tested;
    if (testedType != null) {
      newTested = VariableModel._addTypeToUniqueList(
          info.tested, testedType, helper.typeOperations);
    }

    List<Type>? newPromotedTypes = info.promotedTypes;
    if (promotedType != null) {
      newPromotedTypes =
          VariableModel._addToPromotedTypes(info.promotedTypes, promotedType);
    }

    return identical(newTested, info.tested) &&
            identical(newPromotedTypes, info.promotedTypes)
        ? this
        : _updateVariableInfo(
            reference.promotionKey,
            new VariableModel<Type>(
                promotedTypes: newPromotedTypes,
                tested: newTested,
                assigned: info.assigned,
                unassigned: info.unassigned,
                ssaNode: info.ssaNode,
                nonPromotionHistory: info.nonPromotionHistory),
            reachable: reachable);
  }

  /// Gets the info for [promotionKey] reference, creating it if it doesn't
  /// exist.
  VariableModel<Type> _getInfo(int promotionKey) =>
      variableInfo[promotionKey] ?? new VariableModel<Type>.fresh();

  /// Returns a new [FlowModel] where the information for [reference] is
  /// replaced with [model].
  FlowModel<Type> _updateVariableInfo(
      int promotionKey, VariableModel<Type> model,
      {Reachability? reachable}) {
    return _clone(reachable: reachable)..variableInfo[promotionKey] = model;
  }

  /// Forms a new state to reflect a control flow path that might have come from
  /// either `this` or the [other] state.
  ///
  /// The control flow path is considered reachable if either of the input
  /// states is reachable.  Variables are considered definitely assigned if they
  /// were definitely assigned in both of the input states.  Variable promotions
  /// are kept only if they are common to both input states; if a variable is
  /// promoted to one type in one state and a subtype in the other state, the
  /// less specific type promotion is kept.
  static FlowModel<Type> join<Type extends Object>(
    TypeOperations<Type> typeOperations,
    FlowModel<Type>? first,
    FlowModel<Type>? second,
    Map<int, VariableModel<Type>> emptyVariableMap,
  ) {
    if (first == null) return second!;
    if (second == null) return first;

    assert(identical(first.reachable.parent, second.reachable.parent));
    if (first.reachable.locallyReachable &&
        !second.reachable.locallyReachable) {
      return first;
    }
    if (!first.reachable.locallyReachable &&
        second.reachable.locallyReachable) {
      return second;
    }

    Reachability newReachable =
        Reachability.join(first.reachable, second.reachable);
    Map<int, VariableModel<Type>> newVariableInfo = FlowModel.joinVariableInfo(
        typeOperations,
        first.variableInfo,
        second.variableInfo,
        emptyVariableMap);

    return FlowModel._identicalOrNew(
        first, second, newReachable, newVariableInfo);
  }

  /// Joins two "variable info" maps.  See [join] for details.
  @visibleForTesting
  static Map<int, VariableModel<Type>> joinVariableInfo<Type extends Object>(
    TypeOperations<Type> typeOperations,
    Map<int, VariableModel<Type>> first,
    Map<int, VariableModel<Type>> second,
    Map<int, VariableModel<Type>> emptyMap,
  ) {
    if (identical(first, second)) return first;
    if (first.isEmpty || second.isEmpty) {
      return emptyMap;
    }

    Map<int, VariableModel<Type>> result = <int, VariableModel<Type>>{};
    bool alwaysFirst = true;
    bool alwaysSecond = true;
    for (MapEntry<int, VariableModel<Type>> entry in first.entries) {
      int promotionKey = entry.key;
      VariableModel<Type>? secondModel = second[promotionKey];
      if (secondModel == null) {
        alwaysFirst = false;
      } else {
        VariableModel<Type> joined =
            VariableModel.join<Type>(typeOperations, entry.value, secondModel);
        result[promotionKey] = joined;
        if (!identical(joined, entry.value)) alwaysFirst = false;
        if (!identical(joined, secondModel)) alwaysSecond = false;
      }
    }

    if (alwaysFirst) return first;
    if (alwaysSecond && result.length == second.length) return second;
    if (result.isEmpty) return emptyMap;
    return result;
  }

  /// Models the result of joining the flow models [first] and [second] at the
  /// merge of two control flow paths.
  static FlowModel<Type> merge<Type extends Object>(
    TypeOperations<Type> typeOperations,
    FlowModel<Type>? first,
    FlowModel<Type>? second,
    Map<int, VariableModel<Type>> emptyVariableMap,
  ) {
    if (first == null) return second!.unsplit();
    if (second == null) return first.unsplit();

    assert(identical(first.reachable.parent, second.reachable.parent));
    if (first.reachable.locallyReachable &&
        !second.reachable.locallyReachable) {
      return first.unsplit();
    }
    if (!first.reachable.locallyReachable &&
        second.reachable.locallyReachable) {
      return second.unsplit();
    }

    Reachability newReachable =
        Reachability.join(first.reachable, second.reachable).unsplit();
    Map<int, VariableModel<Type>> newVariableInfo = FlowModel.joinVariableInfo(
        typeOperations,
        first.variableInfo,
        second.variableInfo,
        emptyVariableMap);

    return FlowModel._identicalOrNew(
        first, second, newReachable, newVariableInfo);
  }

  /// Creates a new [FlowModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static FlowModel<Type> _identicalOrNew<Type extends Object>(
      FlowModel<Type> first,
      FlowModel<Type> second,
      Reachability newReachable,
      Map<int, VariableModel<Type>> newVariableInfo) {
    if (first.reachable == newReachable &&
        identical(first.variableInfo, newVariableInfo)) {
      return first;
    }
    if (second.reachable == newReachable &&
        identical(second.variableInfo, newVariableInfo)) {
      return second;
    }

    return new FlowModel<Type>.withInfo(newReachable, newVariableInfo);
  }

  /// Determines whether the given "variableInfo" maps are equivalent.
  ///
  /// The equivalence check is shallow; if two variables' models are not
  /// identical, we return `false`.
  static bool _variableInfosEqual<Type extends Object>(
      Map<int, VariableModel<Type>> p1, Map<int, VariableModel<Type>> p2) {
    if (p1.length != p2.length) return false;
    if (!p1.keys.toSet().containsAll(p2.keys)) return false;
    for (MapEntry<int, VariableModel<Type>> entry in p1.entries) {
      VariableModel<Type> p1Value = entry.value;
      VariableModel<Type>? p2Value = p2[entry.key];
      if (!identical(p1Value, p2Value)) {
        return false;
      }
    }
    return true;
  }
}

/// Interface used by [FlowModel] and [ReferenceWithType] methods to access
/// variables in [_FlowAnalysisImpl].
@visibleForTesting
abstract class FlowModelHelper<Type extends Object> {
  /// The [PromotionKeyStore], which tracks the unique integer assigned to
  /// everything in the control flow that might be promotable.
  @visibleForTesting
  PromotionKeyStore<Object> get promotionKeyStore;

  /// The [TypeOperations], used to access types and check subtyping.
  @visibleForTesting
  TypeOperations<Type> get typeOperations;
}

/// Linked list node representing a set of reasons why a given expression was
/// not promoted.
///
/// We use a linked list representation because it is very efficient to build;
/// this means that in the "happy path" where no error occurs (so non-promotion
/// history is not needed) we do a minimal amount of work.
class NonPromotionHistory<Type> {
  /// The type that was not promoted to.
  final Type type;

  /// The reason why the promotion didn't occur.
  final NonPromotionReason nonPromotionReason;

  /// The previous link in the list.
  final NonPromotionHistory<Type>? previous;

  NonPromotionHistory(this.type, this.nonPromotionReason, this.previous);

  @override
  String toString() {
    List<String> items = <String>[];
    for (NonPromotionHistory<Type>? link = this;
        link != null;
        link = link.previous) {
      items.add('${link.type}: ${link.nonPromotionReason}');
    }
    return items.toString();
  }
}

/// Abstract class representing a reason why something was not promoted.
abstract class NonPromotionReason {
  /// Link to documentation describing this non-promotion reason; this should be
  /// presented to the user as a source of additional information about the
  /// error.
  String get documentationLink;

  /// Short text description of this non-promotion reason; intended for ID
  /// testing.
  String get shortName;

  /// Implementation of the visitor pattern for non-promotion reasons.
  R accept<R, Node extends Object, Variable extends Object,
          Type extends Object>(
      NonPromotionReasonVisitor<R, Node, Variable, Type> visitor);
}

/// Implementation of the visitor pattern for non-promotion reasons.
abstract class NonPromotionReasonVisitor<R, Node extends Object,
    Variable extends Object, Type extends Object> {
  NonPromotionReasonVisitor._() : assert(false, 'Do not extend this class');

  R visitDemoteViaExplicitWrite(DemoteViaExplicitWrite<Variable> reason);

  R visitPropertyNotPromoted(PropertyNotPromoted<Type> reason);

  R visitThisNotPromoted(ThisNotPromoted reason);
}

/// Operations on types and variables, abstracted from concrete type interfaces.
abstract class Operations<Variable extends Object, Type extends Object>
    implements TypeOperations<Type>, VariableOperations<Variable, Type> {
  /// Determines whether the given property can be promoted.  [propertyMember]
  /// will correspond to a `propertyMember` value passed to
  /// [FlowAnalysis.promotedPropertyType], [FlowAnalysis.propertyGet], or
  /// [FlowAnalysis.thisOrSuperPropertyGet].
  bool isPropertyPromotable(Object property);
}

/// Data structure describing the relationship among variables defined by
/// patterns in the various alternatives of a set of switch cases that share a
/// body.
class PatternVariableInfo<Variable> {
  /// Map from variable name to a list of the variables with this name defined
  /// in each case.
  final Map<String, List<Variable>> componentVariables = {};

  /// Map from variable name to the promotion key used by flow analysis to track
  /// the merged variable.
  final Map<String, int> patternVariablePromotionKeys = {};
}

/// Non-promotion reason describing the situation where an expression was not
/// promoted due to the fact that it's a property get.
class PropertyNotPromoted<Type extends Object> extends NonPromotionReason {
  /// The name of the property.
  final String propertyName;

  /// The field or property being accessed.  This matches a `propertyMember`
  /// value that was passed to either [FlowAnalysis.propertyGet] or
  /// [FlowAnalysis.thisOrSuperPropertyGet].
  final Object? propertyMember;

  /// The static type of the property at the time of the access.  This is the
  /// type that was passed to [FlowAnalysis.whyNotPromoted]; it is provided to
  /// the client as a convenience for ID testing.
  final Type staticType;

  PropertyNotPromoted(this.propertyName, this.propertyMember, this.staticType);

  @override
  String get documentationLink => 'http://dart.dev/go/non-promo-property';

  @override
  String get shortName => 'propertyNotPromoted';

  @override
  R accept<R, Node extends Object, Variable extends Object,
              Type extends Object>(
          NonPromotionReasonVisitor<R, Node, Variable, Type> visitor) =>
      visitor.visitPropertyNotPromoted(this as PropertyNotPromoted<Type>);
}

/// Immutable data structure modeling the reachability of the given point in the
/// source code.  Reachability is tracked relative to checkpoints occurring
/// previously along the control flow path leading up to the current point in
/// the program.  A given point is said to be "locally reachable" if it is
/// reachable from the most recent checkpoint, and "overall reachable" if it is
/// reachable from the top of the function.
@visibleForTesting
class Reachability {
  /// Model of the initial reachability state of the function being analyzed.
  static const Reachability initial = const Reachability._initial();

  /// Reachability of the checkpoint this reachability is relative to, or `null`
  /// if there is no checkpoint.  Reachabilities form a tree structure that
  /// mimics the control flow of the code being analyzed, so this is called the
  /// "parent".
  final Reachability? parent;

  /// Whether this point in the source code is considered reachable from the
  /// most recent checkpoint.
  final bool locallyReachable;

  /// Whether this point in the source code is considered reachable from the
  /// beginning of the function being analyzed.
  final bool overallReachable;

  /// The number of `parent` links between this node and [initial].
  final int depth;

  Reachability._(this.parent, this.locallyReachable, this.overallReachable)
      : depth = parent == null ? 0 : parent.depth + 1 {
    assert(overallReachable ==
        (locallyReachable && (parent?.overallReachable ?? true)));
  }

  const Reachability._initial()
      : parent = null,
        locallyReachable = true,
        overallReachable = true,
        depth = 0;

  /// Updates `this` reachability to account for the reachability of [base].
  ///
  /// This is the reachability component of the algorithm in
  /// [FlowModel.rebaseForward].
  Reachability rebaseForward(Reachability base) {
    // If [base] is not reachable, then the result is not reachable.
    if (!base.locallyReachable) return base;
    // If any of the reachability nodes between `this` and its common ancestor
    // with [base] are locally unreachable, that means that there was an exit in
    // the flow control path from the point at which `this` and [base] diverged
    // up to the current point of `this`; therefore we want to mark [base] as
    // unreachable.
    Reachability? ancestor = commonAncestor(this, base);
    for (Reachability? self = this;
        self != null && !identical(self, ancestor);
        self = self.parent) {
      if (!self.locallyReachable) return base.setUnreachable();
    }
    // Otherwise, the result is as reachable as [base] was.
    return base;
  }

  /// Returns a reachability with the same checkpoint as `this`, but where the
  /// current point in the program is considered locally unreachable.
  Reachability setUnreachable() {
    if (!locallyReachable) return this;
    return new Reachability._(parent, false, false);
  }

  /// Returns a new reachability whose checkpoint is the current point of
  /// execution.  This models flow control within a control flow split, e.g.
  /// inside an `if` statement.
  Reachability split() => new Reachability._(this, true, overallReachable);

  @override
  String toString() {
    List<bool> values = [];
    for (Reachability? node = this; node != null; node = node.parent) {
      values.add(node.locallyReachable);
    }
    return '[${values.join(', ')}]';
  }

  /// Returns a reachability that drops the most recent checkpoint but maintains
  /// the same notion of reachability relative to the previous two checkpoints.
  Reachability unsplit() {
    if (locallyReachable) {
      return parent!;
    } else {
      return parent!.setUnreachable();
    }
  }

  /// Finds the common ancestor node of [r1] and [r2], if any such node exists;
  /// otherwise `null`.  If [r1] and [r2] are the same node, that node is
  /// returned.
  static Reachability? commonAncestor(Reachability? r1, Reachability? r2) {
    if (r1 == null || r2 == null) return null;
    while (r1!.depth > r2.depth) {
      r1 = r1.parent!;
    }
    while (r2!.depth > r1.depth) {
      r2 = r2.parent!;
    }
    while (!identical(r1, r2)) {
      r1 = r1!.parent;
      r2 = r2!.parent;
    }
    return r1;
  }

  /// Combines two reachabilities (both of which must be based on the same
  /// checkpoint), where the code is considered reachable from the checkpoint
  /// iff either argument is reachable from the checkpoint.
  ///
  /// This is used as part of the "join" operation.
  static Reachability join(Reachability r1, Reachability r2) {
    assert(identical(r1.parent, r2.parent));
    if (r2.locallyReachable) {
      return r2;
    } else {
      return r1;
    }
  }

  /// Combines two reachabilities (both of which must be based on the same
  /// checkpoint), where the code is considered reachable from the checkpoint
  /// iff both arguments are reachable from the checkpoint.
  ///
  /// This is used as part of the "restrict" operation.
  static Reachability restrict(Reachability r1, Reachability r2) {
    assert(identical(r1.parent, r2.parent));
    if (r2.locallyReachable) {
      return r1;
    } else {
      return r2;
    }
  }
}

/// Container object combining a [Reference] object with its static type.
@visibleForTesting
class ReferenceWithType<Type extends Object> {
  final int promotionKey;

  final Type type;

  final bool isPromotable;

  final bool isThisOrSuper;

  ReferenceWithType(this.promotionKey, this.type,
      {required this.isPromotable, required this.isThisOrSuper});

  @override
  String toString() => 'ReferenceWithType($promotionKey, $type)';
}

/// Data structure representing a unique value that a variable might take on
/// during execution of the code being analyzed.  SSA nodes are immutable (so
/// they can be safety shared among data structures) and have identity (so that
/// it is possible to tell whether one SSA node is the same as another).
///
/// This is similar to the nodes used in traditional single assignment analysis
/// (https://en.wikipedia.org/wiki/Static_single_assignment_form) except that it
/// does not store a complete IR of the code being analyzed.
@visibleForTesting
class SsaNode<Type extends Object> {
  /// Expando mapping SSA nodes to debug ids.  Only used by `toString`.
  static final Expando<int> _debugIds = new Expando<int>();

  static int _nextDebugId = 0;

  /// Flow analysis information was associated with the expression that
  /// produced the value represented by this SSA node, if it was non-trivial.
  /// This can be used at a later time to perform promotions if the value is
  /// used in a control flow construct.
  ///
  /// We don't bother storing flow analysis information if it's trivial (see
  /// [_TrivialExpressionInfo]) because such information does not lead to
  /// promotions.
  @visibleForTesting
  final ExpressionInfo<Type>? expressionInfo;

  SsaNode(this.expressionInfo);

  @override
  String toString() {
    int id = _debugIds[this] ??= _nextDebugId++;
    return 'ssa$id';
  }
}

/// Non-promotion reason describing the situation where an expression was not
/// promoted due to the fact that it's a reference to `this`.
class ThisNotPromoted extends NonPromotionReason {
  @override
  String get documentationLink => 'http://dart.dev/go/non-promo-this';

  @override
  String get shortName => 'thisNotPromoted';

  @override
  R accept<R, Node extends Object, Variable extends Object,
              Type extends Object>(
          NonPromotionReasonVisitor<R, Node, Variable, Type> visitor) =>
      visitor.visitThisNotPromoted(this);
}

/// An instance of the [VariableModel] class represents the information gathered
/// by flow analysis for a single variable at a single point in the control flow
/// of the function or method being analyzed.
///
/// Instances of this class are immutable, so the methods below that "update"
/// the state actually leave `this` unchanged and return a new state object.
@visibleForTesting
class VariableModel<Type extends Object> {
  /// Sequence of types that the variable has been promoted to, where each
  /// element of the sequence is a subtype of the previous.  Null if the
  /// variable hasn't been promoted.
  final List<Type>? promotedTypes;

  /// List of types that the variable has been tested against in all code paths
  /// leading to the given point in the source code.
  final List<Type> tested;

  /// Indicates whether the variable has definitely been assigned.
  final bool assigned;

  /// Indicates whether the variable is unassigned.
  final bool unassigned;

  /// SSA node associated with this variable.  Every time the variable's value
  /// potentially changes (either through an explicit write or a join with a
  /// control flow path that contains a write), this field is updated to point
  /// to a fresh node.  Thus, it can be used to detect whether a variable's
  /// value has changed since a time in the past.
  ///
  /// `null` if the variable has been write captured.
  final SsaNode<Type>? ssaNode;

  /// Non-promotion history of this variable.
  final NonPromotionHistory<Type>? nonPromotionHistory;

  VariableModel(
      {required this.promotedTypes,
      required this.tested,
      required this.assigned,
      required this.unassigned,
      required this.ssaNode,
      this.nonPromotionHistory}) {
    assert(!(assigned && unassigned),
        "Can't be both definitely assigned and unassigned");
    assert(promotedTypes == null || promotedTypes!.isNotEmpty);
    assert(!writeCaptured || promotedTypes == null,
        "Write-captured variables can't be promoted");
    assert(!(writeCaptured && unassigned),
        "Write-captured variables can't be definitely unassigned");
    // ignore:unnecessary_null_comparison
    assert(tested != null);
  }

  /// Creates a [VariableModel] representing a variable that's never been seen
  /// before.
  VariableModel.fresh({this.assigned = false})
      : promotedTypes = null,
        tested = const [],
        unassigned = !assigned,
        ssaNode = new SsaNode<Type>(null),
        nonPromotionHistory = null;

  /// Indicates whether the variable has been write captured.
  bool get writeCaptured => ssaNode == null;

  /// Returns a new [VariableModel] in which any promotions present have been
  /// dropped, and the variable has been marked as "not unassigned".
  ///
  /// Used by [conservativeJoin] to update the state of variables at the top of
  /// loops whose bodies write to them.
  VariableModel<Type> discardPromotionsAndMarkNotUnassigned() {
    return new VariableModel<Type>(
        promotedTypes: null,
        tested: tested,
        assigned: assigned,
        unassigned: false,
        ssaNode: writeCaptured ? null : new SsaNode<Type>(null));
  }

  @override
  String toString() {
    List<String> parts = [ssaNode.toString()];
    if (promotedTypes != null) {
      parts.add('promotedTypes: $promotedTypes');
    }
    if (tested.isNotEmpty) {
      parts.add('tested: $tested');
    }
    if (assigned) {
      parts.add('assigned: true');
    }
    if (!unassigned) {
      parts.add('unassigned: false');
    }
    if (writeCaptured) {
      parts.add('writeCaptured: true');
    }
    if (nonPromotionHistory != null) {
      parts.add('nonPromotionHistory: $nonPromotionHistory');
    }
    return 'VariableModel(${parts.join(', ')})';
  }

  /// Returns a new [VariableModel] reflecting the fact that the variable was
  /// just written to.
  ///
  /// If there is any chance that the write will cause a demotion, the caller
  /// must pass in a non-null value for [nonPromotionReason] describing the
  /// reason for any potential demotion.
  VariableModel<Type> write<Variable extends Object>(
      NonPromotionReason? nonPromotionReason,
      int variableKey,
      Type writtenType,
      Operations<Variable, Type> operations,
      SsaNode<Type> newSsaNode,
      {required bool promoteToTypeOfInterest,
      required Type unpromotedType}) {
    if (writeCaptured) {
      return new VariableModel<Type>(
          promotedTypes: promotedTypes,
          tested: tested,
          assigned: true,
          unassigned: false,
          ssaNode: null);
    }

    _DemotionResult<Type> demotionResult =
        _demoteViaAssignment(writtenType, operations, nonPromotionReason);
    List<Type>? newPromotedTypes = demotionResult.promotedTypes;

    if (promoteToTypeOfInterest) {
      newPromotedTypes = _tryPromoteToTypeOfInterest(
          operations, unpromotedType, newPromotedTypes, writtenType);
    }
    // TODO(paulberry): remove demotions from demotionResult.nonPromotionHistory
    // that are no longer in effect due to re-promotion.
    if (identical(promotedTypes, newPromotedTypes) && assigned) {
      return new VariableModel<Type>(
          promotedTypes: promotedTypes,
          tested: tested,
          assigned: assigned,
          unassigned: unassigned,
          ssaNode: newSsaNode);
    }

    List<Type> newTested;
    if (newPromotedTypes == null && promotedTypes != null) {
      newTested = const [];
    } else {
      newTested = tested;
    }

    return new VariableModel<Type>(
        promotedTypes: newPromotedTypes,
        tested: newTested,
        assigned: true,
        unassigned: false,
        ssaNode: newSsaNode,
        nonPromotionHistory: demotionResult.nonPromotionHistory);
  }

  /// Returns a new [VariableModel] reflecting the fact that the variable has
  /// been write-captured.
  VariableModel<Type> writeCapture() {
    return new VariableModel<Type>(
        promotedTypes: null,
        tested: const [],
        assigned: assigned,
        unassigned: false,
        ssaNode: null);
  }

  /// Computes the result of demoting this variable due to writing a value of
  /// type [writtenType].
  ///
  /// If there is any chance that the write will cause an actual demotion to
  /// occur, the caller must pass in a non-null value for [nonPromotionReason]
  /// describing the reason for the potential demotion.
  _DemotionResult<Type> _demoteViaAssignment(
      Type writtenType,
      TypeOperations<Type> typeOperations,
      NonPromotionReason? nonPromotionReason) {
    List<Type>? promotedTypes = this.promotedTypes;
    if (promotedTypes == null) {
      return new _DemotionResult<Type>(null, nonPromotionHistory);
    }

    int numElementsToKeep = promotedTypes.length;
    NonPromotionHistory<Type>? newNonPromotionHistory = nonPromotionHistory;
    List<Type>? newPromotedTypes;
    for (;; numElementsToKeep--) {
      if (numElementsToKeep == 0) {
        break;
      }
      Type promoted = promotedTypes[numElementsToKeep - 1];
      if (typeOperations.isSubtypeOf(writtenType, promoted)) {
        if (numElementsToKeep == promotedTypes.length) {
          newPromotedTypes = promotedTypes;
          break;
        }
        newPromotedTypes = promotedTypes.sublist(0, numElementsToKeep);
        break;
      }
      if (nonPromotionReason == null) {
        assert(false, 'Demotion occurred but nonPromotionReason is null');
      } else {
        newNonPromotionHistory = new NonPromotionHistory<Type>(
            promoted, nonPromotionReason, newNonPromotionHistory);
      }
    }
    return new _DemotionResult<Type>(newPromotedTypes, newNonPromotionHistory);
  }

  /// Returns a variable model that is the same as this one, but with the
  /// variable definitely assigned.
  VariableModel<Type> _setAssigned() => assigned
      ? this
      : new VariableModel(
          promotedTypes: promotedTypes,
          tested: tested,
          assigned: true,
          unassigned: false,
          ssaNode: ssaNode ?? new SsaNode(null),
          nonPromotionHistory: nonPromotionHistory);

  /// Determines whether a variable with the given [promotedTypes] should be
  /// promoted to [writtenType] based on types of interest.  If it should,
  /// returns an updated promotion chain; otherwise returns [promotedTypes]
  /// unchanged.
  ///
  /// Note that since promotion chains are considered immutable, if promotion
  /// is required, a new promotion chain will be created and returned.
  List<Type>? _tryPromoteToTypeOfInterest(TypeOperations<Type> typeOperations,
      Type declaredType, List<Type>? promotedTypes, Type writtenType) {
    assert(!writeCaptured);

    if (typeOperations.forcePromotion(
        writtenType, declaredType, this.promotedTypes, promotedTypes)) {
      return _addToPromotedTypes(promotedTypes, writtenType);
    }

    // Figure out if we have any promotion candidates (types that are a
    // supertype of writtenType and a proper subtype of the currently-promoted
    // type).  If at any point we find an exact match, we take it immediately.
    Type? currentlyPromotedType = promotedTypes?.last;

    List<Type>? result;
    List<Type>? candidates = null;

    void handleTypeOfInterest(Type type) {
      // The written type must be a subtype of the type.
      if (!typeOperations.isSubtypeOf(writtenType, type)) {
        return;
      }

      // Must be more specific that the currently promoted type.
      if (currentlyPromotedType != null) {
        if (typeOperations.isSameType(type, currentlyPromotedType)) {
          return;
        }
        if (!typeOperations.isSubtypeOf(type, currentlyPromotedType)) {
          return;
        }
      }

      // This is precisely the type we want to promote to; take it.
      if (typeOperations.isSameType(type, writtenType)) {
        result = _addToPromotedTypes(promotedTypes, writtenType);
      }

      if (candidates == null) {
        candidates = [type];
        return;
      }

      // Add only unique candidates.
      if (!_typeListContains(typeOperations, candidates!, type)) {
        candidates!.add(type);
        return;
      }
    }

    // The declared type is always a type of interest, but we never promote
    // to the declared type. So, try NonNull of it.
    Type declaredTypeNonNull = typeOperations.promoteToNonNull(declaredType);
    if (!typeOperations.isSameType(declaredTypeNonNull, declaredType)) {
      handleTypeOfInterest(declaredTypeNonNull);
      if (result != null) {
        return result!;
      }
    }

    for (int i = 0; i < tested.length; i++) {
      Type type = tested[i];

      handleTypeOfInterest(type);
      if (result != null) {
        return result!;
      }

      Type typeNonNull = typeOperations.promoteToNonNull(type);
      if (!typeOperations.isSameType(typeNonNull, type)) {
        handleTypeOfInterest(typeNonNull);
        if (result != null) {
          return result!;
        }
      }
    }

    List<Type>? candidates2 = candidates;
    if (candidates2 != null) {
      // Figure out if we have a unique promotion candidate that's a subtype
      // of all the others.
      Type? promoted;
      outer:
      for (int i = 0; i < candidates2.length; i++) {
        for (int j = 0; j < candidates2.length; j++) {
          if (j == i) continue;
          if (!typeOperations.isSubtypeOf(candidates2[i], candidates2[j])) {
            // Not a subtype of all the others.
            continue outer;
          }
        }
        if (promoted != null) {
          // Not unique.  Do not promote.
          return promotedTypes;
        } else {
          promoted = candidates2[i];
        }
      }
      if (promoted != null) {
        return _addToPromotedTypes(promotedTypes, promoted);
      }
    }
    // No suitable promotion found.
    return promotedTypes;
  }

  /// Builds a [VariableModel] based on [model], but extending the [tested] set
  /// to include types from [tested].  This is used at the bottom of certain
  /// kinds of loops, to ensure that types tested within the body of the loop
  /// are consistently treated as "of interest" in code that follows the loop,
  /// regardless of the type of loop.
  @visibleForTesting
  static VariableModel<Type> inheritTested<Type extends Object>(
      TypeOperations<Type> typeOperations,
      VariableModel<Type> model,
      List<Type> tested) {
    List<Type> newTested = joinTested(tested, model.tested, typeOperations);
    if (identical(newTested, model.tested)) return model;
    return new VariableModel<Type>(
        promotedTypes: model.promotedTypes,
        tested: newTested,
        assigned: model.assigned,
        unassigned: model.unassigned,
        ssaNode: model.ssaNode);
  }

  /// Joins two variable models.  See [FlowModel.join] for details.
  static VariableModel<Type> join<Type extends Object>(
      TypeOperations<Type> typeOperations,
      VariableModel<Type> first,
      VariableModel<Type> second) {
    List<Type>? newPromotedTypes = joinPromotedTypes(
        first.promotedTypes, second.promotedTypes, typeOperations);
    newPromotedTypes = typeOperations.refinePromotedTypes(
        first.promotedTypes, second.promotedTypes, newPromotedTypes);
    bool newAssigned = first.assigned && second.assigned;
    bool newUnassigned = first.unassigned && second.unassigned;
    bool newWriteCaptured = first.writeCaptured || second.writeCaptured;
    List<Type> newTested = newWriteCaptured
        ? const []
        : joinTested(first.tested, second.tested, typeOperations);
    SsaNode<Type>? newSsaNode = newWriteCaptured
        ? null
        : first.ssaNode == second.ssaNode
            ? first.ssaNode
            : new SsaNode<Type>(null);
    return _identicalOrNew(first, second, newPromotedTypes, newTested,
        newAssigned, newUnassigned, newWriteCaptured ? null : newSsaNode);
  }

  /// Performs the portion of the "join" algorithm that applies to promotion
  /// chains.  Briefly, we intersect given chains.  The chains are totally
  /// ordered subsets of a global partial order.  Their intersection is a
  /// subset of each, and as such is also totally ordered.
  static List<Type>? joinPromotedTypes<Type extends Object>(List<Type>? chain1,
      List<Type>? chain2, TypeOperations<Type> typeOperations) {
    if (chain1 == null) return chain1;
    if (chain2 == null) return chain2;

    int index1 = 0;
    int index2 = 0;
    bool skipped1 = false;
    bool skipped2 = false;
    List<Type>? result;
    while (index1 < chain1.length && index2 < chain2.length) {
      Type type1 = chain1[index1];
      Type type2 = chain2[index2];
      if (typeOperations.isSameType(type1, type2)) {
        result ??= <Type>[];
        result.add(type1);
        index1++;
        index2++;
      } else if (typeOperations.isSubtypeOf(type2, type1)) {
        index1++;
        skipped1 = true;
      } else if (typeOperations.isSubtypeOf(type1, type2)) {
        index2++;
        skipped2 = true;
      } else {
        skipped1 = true;
        skipped2 = true;
        break;
      }
    }

    if (index1 == chain1.length && !skipped1) return chain1;
    if (index2 == chain2.length && !skipped2) return chain2;
    return result;
  }

  /// Performs the portion of the "join" algorithm that applies to promotion
  /// chains.  Essentially this performs a set union, with the following
  /// caveats:
  /// - The "sets" are represented as lists (since they are expected to be very
  ///   small in real-world cases)
  /// - The sense of equality for the union operation is determined by
  ///   [TypeOperations.isSameType].
  /// - The types of interests lists are considered immutable.
  static List<Type> joinTested<Type extends Object>(List<Type> types1,
      List<Type> types2, TypeOperations<Type> typeOperations) {
    // Ensure that types1 is the shorter list.
    if (types1.length > types2.length) {
      List<Type> tmp = types1;
      types1 = types2;
      types2 = tmp;
    }
    // Determine the length of the common prefix the two lists share.
    int shared = 0;
    for (; shared < types1.length; shared++) {
      if (!typeOperations.isSameType(types1[shared], types2[shared])) break;
    }
    // Use types2 as a starting point and add any entries from types1 that are
    // not present in it.
    for (int i = shared; i < types1.length; i++) {
      Type typeToAdd = types1[i];
      if (_typeListContains(typeOperations, types2, typeToAdd)) continue;
      List<Type> result = types2.toList()..add(typeToAdd);
      for (i++; i < types1.length; i++) {
        typeToAdd = types1[i];
        if (_typeListContains(typeOperations, types2, typeToAdd)) continue;
        result.add(typeToAdd);
      }
      return result;
    }
    // No types needed to be added.
    return types2;
  }

  /// Forms a promotion chain by starting with [basePromotedTypes] and applying
  /// promotions from [thisPromotedTypes] to it, to the extent possible without
  /// violating the usual ordering invariant (each promoted type must be a
  /// subtype of the previous).
  ///
  /// In degenerate cases, the returned chain will be identical to
  /// [thisPromotedTypes] or [basePromotedTypes] (to make it easier for the
  /// caller to detect when data structures may be re-used).
  static List<Type>? rebasePromotedTypes<Type extends Object>(
      TypeOperations<Type> typeOperations,
      List<Type>? thisPromotedTypes,
      List<Type>? basePromotedTypes) {
    if (basePromotedTypes == null) {
      // The base promotion chain contributes nothing so we just use this
      // promotion chain directly.
      return thisPromotedTypes;
    } else if (thisPromotedTypes == null) {
      // This promotion chain contributes nothing so we just use the base
      // promotion chain directly.
      return basePromotedTypes;
    } else {
      // Start with basePromotedTypes and apply each of the promotions in
      // thisPromotedTypes (discarding any that don't follow the ordering
      // invariant)
      List<Type> newPromotedTypes = basePromotedTypes;
      Type otherPromotedType = basePromotedTypes.last;
      for (int i = 0; i < thisPromotedTypes.length; i++) {
        Type nextType = thisPromotedTypes[i];
        if (typeOperations.isSubtypeOf(nextType, otherPromotedType) &&
            !typeOperations.isSameType(nextType, otherPromotedType)) {
          newPromotedTypes = basePromotedTypes.toList()
            ..addAll(thisPromotedTypes.skip(i));
          break;
        }
      }
      return newPromotedTypes;
    }
  }

  static List<Type> _addToPromotedTypes<Type extends Object>(
          List<Type>? promotedTypes, Type promoted) =>
      promotedTypes == null
          ? [promoted]
          : (promotedTypes.toList()..add(promoted));

  static List<Type> _addTypeToUniqueList<Type extends Object>(
      List<Type> types, Type newType, TypeOperations<Type> typeOperations) {
    if (_typeListContains(typeOperations, types, newType)) return types;
    return new List<Type>.of(types)..add(newType);
  }

  /// Creates a new [VariableModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static VariableModel<Type> _identicalOrNew<Type extends Object>(
      VariableModel<Type> first,
      VariableModel<Type> second,
      List<Type>? newPromotedTypes,
      List<Type> newTested,
      bool newAssigned,
      bool newUnassigned,
      SsaNode<Type>? newSsaNode) {
    if (identical(first.promotedTypes, newPromotedTypes) &&
        identical(first.tested, newTested) &&
        first.assigned == newAssigned &&
        first.unassigned == newUnassigned &&
        first.ssaNode == newSsaNode) {
      return first;
    } else if (identical(second.promotedTypes, newPromotedTypes) &&
        identical(second.tested, newTested) &&
        second.assigned == newAssigned &&
        second.unassigned == newUnassigned &&
        second.ssaNode == newSsaNode) {
      return second;
    } else {
      return new VariableModel<Type>(
          promotedTypes: newPromotedTypes,
          tested: newTested,
          assigned: newAssigned,
          unassigned: newUnassigned,
          ssaNode: newSsaNode);
    }
  }

  static bool _typeListContains<Type extends Object>(
      TypeOperations<Type> typeOperations, List<Type> list, Type searchType) {
    for (Type type in list) {
      if (typeOperations.isSameType(type, searchType)) return true;
    }
    return false;
  }
}

/// Operations on variables, abstracted from concrete type interfaces.
abstract class VariableOperations<Variable extends Object,
    Type extends Object> {
  /// Returns the static type of the given [variable].
  Type variableType(Variable variable);
}

class WhyNotPromotedInfo {}

/// [_FlowContext] representing an assert statement or assert initializer.
class _AssertContext<Type extends Object> extends _SimpleContext<Type> {
  /// Flow models associated with the condition being asserted.
  ExpressionInfo<Type>? _conditionInfo;

  _AssertContext(super.previous);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['conditionInfo'] = _conditionInfo;

  @override
  String get _debugType => '_AssertContext';
}

/// [_FlowContext] representing a language construct that branches on a boolean
/// condition, such as an `if` statement, conditional expression, or a logical
/// binary operator.
class _BranchContext<Type extends Object> extends _FlowContext {
  /// Flow model if the branch is taken.
  final FlowModel<Type> _branchModel;

  _BranchContext(this._branchModel);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['branchModel'] = _branchModel;

  @override
  String get _debugType => '_BranchContext';
}

/// [_FlowContext] representing a language construct that can be targeted by
/// `break` or `continue` statements, such as a loop or switch statement.
class _BranchTargetContext<Type extends Object> extends _FlowContext {
  /// Accumulated flow model for all `break` statements seen so far, or `null`
  /// if no `break` statements have been seen yet.
  FlowModel<Type>? _breakModel;

  /// Accumulated flow model for all `continue` statements seen so far, or
  /// `null` if no `continue` statements have been seen yet.
  FlowModel<Type>? _continueModel;

  /// The reachability checkpoint associated with this loop or switch statement.
  /// When analyzing deeply nested `break` and `continue` statements, their flow
  /// models need to be unsplit to this point before joining them to the control
  /// flow paths for the loop or switch.
  final Reachability _checkpoint;

  _BranchTargetContext(this._checkpoint);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['breakModel'] = _breakModel
    ..['continueModel'] = _continueModel
    ..['checkpoint'] = _checkpoint;

  @override
  String get _debugType => '_BranchTargetContext';
}

/// [_FlowContext] representing a conditional expression.
class _ConditionalContext<Type extends Object> extends _BranchContext<Type> {
  /// Flow models associated with the value of the conditional expression in the
  /// circumstance where the "then" branch is taken.
  ExpressionInfo<Type>? _thenInfo;

  _ConditionalContext(super._branchModel);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['thenInfo'] = _thenInfo;

  @override
  String get _debugType => '_ConditionalContext';
}

/// Data structure representing the result of demoting a variable from one type
/// to another.
class _DemotionResult<Type extends Object> {
  /// The new set of promoted types.
  final List<Type>? promotedTypes;

  /// The new non-promotion history (including the types that the variable is
  /// no longer promoted to).
  final NonPromotionHistory<Type>? nonPromotionHistory;

  _DemotionResult(this.promotedTypes, this.nonPromotionHistory);
}

/// Specialization of [_EqualityCheckResult] used as the return value for
/// [_FlowAnalysisImpl._equalityCheck] when exactly one of the two operands is a
/// `null` literal (and therefore the equality test is testing whether the other
/// operand is `null`).
///
/// Note that if both operands are `null`, then [_GuaranteedEqual] will be
/// returned instead.
class _EqualityCheckIsNullCheck<Type extends Object>
    extends _EqualityCheckResult {
  /// If the operand that is being null-tested is something that can undergo
  /// type promotion, the object recording its promotion key, type information,
  /// etc.  Otherwise, `null`.
  final ReferenceWithType<Type>? reference;

  /// If `true` the operand that's being null-tested corresponds to
  /// [_FlowAnalysisImpl._equalityCheck]'s `rightOperandInfo` argument; if
  /// `false`, it corresponds to [_FlowAnalysisImpl._equalityCheck]'s
  /// `leftOperandInfo` argument.
  final bool isReferenceOnRight;

  _EqualityCheckIsNullCheck(this.reference, {required this.isReferenceOnRight})
      : super._();
}

/// Result of performing equality check.  This class is used as the return value
/// for [_FlowAnalysisImpl._equalityCheck].
abstract class _EqualityCheckResult {
  const _EqualityCheckResult._();
}

class _FlowAnalysisImpl<Node extends Object, Statement extends Node,
        Expression extends Object, Variable extends Object, Type extends Object>
    implements
        FlowAnalysis<Node, Statement, Expression, Variable, Type>,
        FlowModelHelper<Type> {
  /// The [Operations], used to access types, check subtyping, and query
  /// variable types.
  @override
  final Operations<Variable, Type> operations;

  /// Stack of [_FlowContext] objects representing the statements and
  /// expressions that are currently being visited.
  final List<_FlowContext> _stack = [];

  /// The mapping from [Statement]s that can act as targets for `break` and
  /// `continue` statements (i.e. loops and switch statements) to the to their
  /// context information.
  final Map<Statement, _BranchTargetContext<Type>> _statementToContext = {};

  FlowModel<Type> _current = new FlowModel<Type>(Reachability.initial);

  /// If a pattern is being analyzed, flow model representing all code paths
  /// accumulated so far in which the pattern fails to match.  Otherwise `null`.
  FlowModel<Type>? _unmatched;

  /// If a pattern is being analyzed, and the scrutinee is something that might
  /// be relevant to type promotion as a consequence of the pattern match,
  /// [ReferenceWithType] object referring to the scrutinee.  Otherwise `null`.
  ReferenceWithType<Type>? _scrutineeReference;

  /// If a pattern is being analyzed, and the scrutinee is something that might
  /// be type promoted as a consequence of the pattern match, [SsaNode]
  /// reflecting the state of the pattern match at the time that
  /// [_scrutineeReference] was captured.  Otherwise `null`.
  ///
  /// This is necessary to detect situations where the scrutinee is modified
  /// after the beginning of a switch statement and before choosing the case to
  /// execute (e.g. in a guard clause), and therefore further pattern matches
  /// should not promote the scrutinee (since they are acting on a cached value
  /// that no longer matches the scrutinee expression).  For example:
  ///
  ///     switch (v) {
  ///       case int _: // promotes `v` to `int`
  ///         break;
  ///       case _ when f(v = ...): // reassigns `v`
  ///         break;
  ///       case String _: // does not promote `v` to `String`
  ///         break;
  ///     }
  SsaNode<Type>? _scrutineeSsaNode;

  /// The most recently visited expression for which an [ExpressionInfo] object
  /// exists, or `null` if no expression has been visited that has a
  /// corresponding [ExpressionInfo] object.
  Expression? _expressionWithInfo;

  /// If [_expressionWithInfo] is not `null`, the [ExpressionInfo] object
  /// corresponding to it.  Otherwise `null`.
  ExpressionInfo<Type>? _expressionInfo;

  /// The most recently visited expression which was a reference, or `null` if
  /// no such expression has been visited.
  Expression? _expressionWithReference;

  /// If [_expressionVariable] is not `null`, the reference corresponding to it.
  /// Otherwise `null`.
  ReferenceWithType<Type>? _expressionReference;

  final AssignedVariables<Node, Variable> _assignedVariables;

  /// Indicates whether initializers of implicitly typed variables should be
  /// accounted for by SSA analysis.  (In an ideal world, they always would be,
  /// but due to https://github.com/dart-lang/language/issues/1785, they weren't
  /// always, and we need to be able to replicate the old behavior when
  /// analyzing old language versions).
  final bool respectImplicitlyTypedVarInitializers;

  @override
  final PromotionKeyStore<Variable> promotionKeyStore;

  /// For debugging only: the set of [Variable]s that have been passed to
  /// [declare] so far.  This is used to detect unnecessary calls to [declare].
  final Set<Variable> _debugDeclaredVariables = {};

  _FlowAnalysisImpl(this.operations, this._assignedVariables,
      {required this.respectImplicitlyTypedVarInitializers})
      : promotionKeyStore = _assignedVariables.promotionKeyStore {
    if (!_assignedVariables.isFinished) {
      _assignedVariables.finish();
    }
    assert(() {
      AssignedVariablesNodeInfo anywhere = _assignedVariables.anywhere;
      Set<int> implicitlyDeclaredVars = {...anywhere.read, ...anywhere.written};
      implicitlyDeclaredVars.removeAll(anywhere.declared);
      assert(implicitlyDeclaredVars.isEmpty,
          'All variables should be declared somewhere');
      return true;
    }());
  }

  @override
  bool get isReachable => _current.reachable.overallReachable;

  @override
  TypeOperations<Type> get typeOperations => operations;

  @override
  void asExpression_end(Expression subExpression, Type type) {
    ReferenceWithType<Type>? referenceWithType =
        _getExpressionReference(subExpression);
    if (referenceWithType == null) return;
    _current = _current.tryPromoteForTypeCast(this, referenceWithType, type);
  }

  @override
  void assert_afterCondition(Expression condition) {
    _AssertContext<Type> context = _stack.last as _AssertContext<Type>;
    ExpressionInfo<Type> conditionInfo = _expressionEnd(condition);
    context._conditionInfo = conditionInfo;
    _current = conditionInfo.ifFalse;
  }

  @override
  void assert_begin() {
    _current = _current.split();
    _stack.add(new _AssertContext<Type>(_current));
  }

  @override
  void assert_end() {
    _AssertContext<Type> context = _stack.removeLast() as _AssertContext<Type>;
    _current = _merge(context._previous, context._conditionInfo!.ifTrue);
  }

  @override
  void assignedVariablePattern(Node node, Variable variable, Type writtenType) {
    _PatternContext<Type> context = _stack.last as _PatternContext<Type>;
    _write(node, variable, writtenType, context._matchedValueInfo);
  }

  @override
  void assignMatchedPatternVariable(Variable variable, int promotionKey) {
    int mergedKey = promotionKeyStore.keyForVariable(variable);
    VariableModel<Type> info = _current.infoFor(promotionKey);
    // Normally flow analysis is responsible for tracking whether variables are
    // definitely assigned; however for variables appearing in patterns we
    // have other logic to make sure that a value is definitely assigned (e.g.
    // the rule that a variable appearing on one side of an `||` must also
    // appear on the other side).  So to avoid reporting redundant errors, we
    // pretend that the variable is definitely assigned, even if it isn't.
    info = info._setAssigned();
    _current = _current._updateVariableInfo(mergedKey, info);
  }

  @override
  void booleanLiteral(Expression expression, bool value) {
    FlowModel<Type> unreachable = _current.setUnreachable();
    _storeExpressionInfo(
        expression,
        value
            ? new ExpressionInfo(
                after: _current, ifTrue: _current, ifFalse: unreachable)
            : new ExpressionInfo(
                after: _current, ifTrue: unreachable, ifFalse: _current));
  }

  @override
  void conditional_conditionBegin() {
    _current = _current.split();
  }

  @override
  void conditional_elseBegin(Expression thenExpression) {
    _ConditionalContext<Type> context =
        _stack.last as _ConditionalContext<Type>;
    context._thenInfo = _expressionEnd(thenExpression);
    _current = context._branchModel;
  }

  @override
  void conditional_end(
      Expression conditionalExpression, Expression elseExpression) {
    _ConditionalContext<Type> context =
        _stack.removeLast() as _ConditionalContext<Type>;
    ExpressionInfo<Type> thenInfo = context._thenInfo!;
    ExpressionInfo<Type> elseInfo = _expressionEnd(elseExpression);
    _storeExpressionInfo(
        conditionalExpression,
        new ExpressionInfo(
            after: _merge(thenInfo.after, elseInfo.after),
            ifTrue: _merge(thenInfo.ifTrue, elseInfo.ifTrue),
            ifFalse: _merge(thenInfo.ifFalse, elseInfo.ifFalse)));
  }

  @override
  void conditional_thenBegin(Expression condition, Node conditionalExpression) {
    ExpressionInfo<Type> conditionInfo = _expressionEnd(condition);
    _stack.add(new _ConditionalContext(conditionInfo.ifFalse));
    _current = conditionInfo.ifTrue;
  }

  @override
  void constantPattern_end(Expression expression, Type type,
      {required bool patternsEnabled}) {
    assert(_stack.last is _PatternContext<Type>);
    if (patternsEnabled) {
      _handleEqualityCheckPattern(expression, type, notEqual: false);
    } else {
      // Before pattern support was added to Dart, flow analysis didn't do any
      // promotion based on the constants in individual case clauses.  Also, it
      // assumed that all case clauses were equally reachable.  So, when
      // analyzing legacy code that targets a language version before patterns
      // were supported, we need to mimic that old behavior.  The easiest way to
      // do that is to simply assume that the pattern might or might not match,
      // regardless of the constant expression.
      _unmatched = _join(_unmatched!, _current);
    }
  }

  @override
  void copyPromotionData(
      {required int sourceKey, required int destinationKey}) {
    _current = _current._updateVariableInfo(
        destinationKey, _current.infoFor(sourceKey));
  }

  @override
  void declare(Variable variable, Type staticType,
      {required bool initialized, bool skipDuplicateCheck = false}) {
    assert(
        operations.isSameType(staticType, operations.variableType(variable)));
    assert(_debugDeclaredVariables.add(variable) || skipDuplicateCheck,
        'Variable $variable already declared');
    _current = _current.declare(
        promotionKeyStore.keyForVariable(variable), initialized);
  }

  @override
  int declaredVariablePattern(
      {required Type matchedType,
      required Type staticType,
      Expression? initializerExpression,
      bool isFinal = false,
      bool isLate = false,
      required bool isImplicitlyTyped}) {
    _PatternContext<Type> context = _stack.last as _PatternContext<Type>;
    // Choose a fresh promotion key to represent the temporary variable that
    // stores the matched value, and mark it as initialized.
    int promotionKey = promotionKeyStore.makeTemporaryKey();
    _current = _current.declare(promotionKey, true);
    _initialize(promotionKey, matchedType, context._matchedValueInfo,
        isFinal: isFinal,
        isLate: isLate,
        isImplicitlyTyped: isImplicitlyTyped,
        unpromotedType: staticType);
    return promotionKey;
  }

  @override
  void doStatement_bodyBegin(Statement doStatement) {
    AssignedVariablesNodeInfo info =
        _assignedVariables.getInfoForNode(doStatement);
    _BranchTargetContext<Type> context =
        new _BranchTargetContext<Type>(_current.reachable);
    _stack.add(context);
    _current =
        _current.conservativeJoin(this, info.written, info.captured).split();
    _statementToContext[doStatement] = context;
  }

  @override
  void doStatement_conditionBegin() {
    _BranchTargetContext<Type> context =
        _stack.last as _BranchTargetContext<Type>;
    _current = _join(_current, context._continueModel);
  }

  @override
  void doStatement_end(Expression condition) {
    _BranchTargetContext<Type> context =
        _stack.removeLast() as _BranchTargetContext<Type>;
    _current = _merge(_expressionEnd(condition).ifFalse, context._breakModel);
  }

  @override
  EqualityInfo<Type> equalityOperand_end(Expression operand, Type type) =>
      _computeEqualityInfo(operand, type);

  @override
  void equalityOperation_end(Expression wholeExpression,
      EqualityInfo<Type>? leftOperandInfo, EqualityInfo<Type>? rightOperandInfo,
      {bool notEqual = false}) {
    // Note: leftOperandInfo and rightOperandInfo are nullable in the base class
    // to account for the fact that legacy type promotion doesn't record
    // information about legacy operands.  But since we are currently in full
    // (post null safety) flow analysis logic, we can safely assume that they
    // are not null.
    _EqualityCheckResult equalityCheckResult =
        _equalityCheck(leftOperandInfo!, rightOperandInfo!);
    if (equalityCheckResult is _GuaranteedEqual) {
      // Both operands are known by flow analysis to compare equal, so the whole
      // expression behaves equivalently to a boolean (either `true` or `false`
      // depending whether the check uses the `!=` operator).
      booleanLiteral(wholeExpression, !notEqual);
    } else if (equalityCheckResult is _EqualityCheckIsNullCheck<Type>) {
      ReferenceWithType<Type>? reference = equalityCheckResult.reference;
      if (reference == null) {
        // One side of the equality check is `null`, but the other side is not a
        // promotable reference.  So there's no promotion to do.
        return;
      }
      // The equality check is a null check of something potentially promotable
      // (e.g. a local variable).  Record the necessary information so that if
      // this null check winds up being used for a conditional branch, the
      // variable's will be promoted on the appropriate code path.
      ExpressionInfo<Type> equalityInfo =
          _current.tryMarkNonNullable(this, reference);
      _storeExpressionInfo(
          wholeExpression, notEqual ? equalityInfo : equalityInfo.invert());
    } else {
      assert(equalityCheckResult is _NoEqualityInformation);
      // Since flow analysis can't garner any information from this equality
      // check, nothing needs to be done; by not calling `_storeExpressionInfo`,
      // we ensure that if `_getExpressionInfo` is later called on this
      // expression, `null` will be returned.  That means that if this
      // expression winds up being used for a conditional branch, flow analysis
      // will consider both code paths reachable and won't perform any
      // promotions on either path.
    }
  }

  @override
  void equalityRelationalPattern_end(Expression operand, Type operandType,
      {bool notEqual = false}) {
    _handleEqualityCheckPattern(operand, operandType, notEqual: notEqual);
  }

  @override
  ExpressionInfo<Type>? expressionInfoForTesting(Expression target) =>
      identical(target, _expressionWithInfo) ? _expressionInfo : null;

  @override
  void finish() {
    assert(_stack.isEmpty);
    assert(_current.reachable.parent == null);
    assert(_unmatched == null);
    assert(_scrutineeReference == null);
    assert(_scrutineeSsaNode == null);
  }

  @override
  void for_bodyBegin(Statement? node, Expression? condition) {
    ExpressionInfo<Type> conditionInfo = condition == null
        ? new ExpressionInfo(
            after: _current,
            ifTrue: _current,
            ifFalse: _current.setUnreachable())
        : _expressionEnd(condition);
    _WhileContext<Type> context =
        new _WhileContext<Type>(_current.reachable.parent!, conditionInfo);
    _stack.add(context);
    if (node != null) {
      _statementToContext[node] = context;
    }
    _current = conditionInfo.ifTrue;
  }

  @override
  void for_conditionBegin(Node node) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node);
    _current =
        _current.conservativeJoin(this, info.written, info.captured).split();
  }

  @override
  void for_end() {
    _WhileContext<Type> context = _stack.removeLast() as _WhileContext<Type>;
    // Tail of the stack: falseCondition, break
    FlowModel<Type>? breakState = context._breakModel;
    FlowModel<Type> falseCondition = context._conditionInfo.ifFalse;

    _current =
        _merge(falseCondition, breakState).inheritTested(operations, _current);
  }

  @override
  void for_updaterBegin() {
    _WhileContext<Type> context = _stack.last as _WhileContext<Type>;
    _current = _join(_current, context._continueModel);
  }

  @override
  void forEach_bodyBegin(Node node) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node);
    _current =
        _current.conservativeJoin(this, info.written, info.captured).split();
    _SimpleStatementContext<Type> context =
        new _SimpleStatementContext<Type>(_current.reachable.parent!, _current);
    _stack.add(context);
  }

  @override
  void forEach_end() {
    _SimpleStatementContext<Type> context =
        _stack.removeLast() as _SimpleStatementContext<Type>;
    _current = _merge(_current, context._previous);
  }

  @override
  void forwardExpression(Expression newExpression, Expression oldExpression) {
    if (identical(_expressionWithInfo, oldExpression)) {
      _expressionWithInfo = newExpression;
    }
    if (identical(_expressionWithReference, oldExpression)) {
      _expressionWithReference = newExpression;
    }
  }

  @override
  void functionExpression_begin(Node node) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node);
    _current = _current.conservativeJoin(this, const [], info.written);
    _stack.add(new _FunctionExpressionContext(_current));
    _current = _current.conservativeJoin(
        this,
        _assignedVariables.anywhere.written,
        _assignedVariables.anywhere.captured);
  }

  @override
  void functionExpression_end() {
    _SimpleContext<Type> context =
        _stack.removeLast() as _FunctionExpressionContext<Type>;
    _current = context._previous;
  }

  @override
  Type getMatchedValueType() {
    _PatternContext<Type> context = _stack.last as _PatternContext<Type>;
    return _current
            .infoFor(context._matchedValuePromotionKey)
            .promotedTypes
            ?.last ??
        context._matchedValueUnpromotedType;
  }

  @override
  void handleBreak(Statement? target) {
    _BranchTargetContext<Type>? context = _statementToContext[target];
    if (context != null) {
      context._breakModel =
          _join(context._breakModel, _current.unsplitTo(context._checkpoint));
    }
    _current = _current.setUnreachable();
  }

  @override
  void handleContinue(Statement? target) {
    _BranchTargetContext<Type>? context = _statementToContext[target];
    if (context != null) {
      context._continueModel = _join(
          context._continueModel, _current.unsplitTo(context._checkpoint));
    }
    _current = _current.setUnreachable();
  }

  @override
  void handleExit() {
    _current = _current.setUnreachable();
  }

  @override
  void ifCaseStatement_afterExpression(
      Expression scrutinee, Type scrutineeType) {
    // If S0 is the statement `if (E0 case P when E1) S1 else S2`, then:
    // - before(P) = after(E0),
    // - before(E1) = matched(P).
    // Note that we don't need to take any action to handle
    // `before(E1) = matched(P)`, because we store both the "matched" state for
    // patterns and the "before" state for expressions in `_current`.
    _pushPattern(_pushScrutinee(scrutinee, scrutineeType));
  }

  @override
  void ifCaseStatement_begin() {
    // If S0 is the statement `if (E0 case P when E1) S1 else S2`, then:
    // - before(E0) = split(before(S0)).
    _current = _current.split();
  }

  @override
  void ifCaseStatement_thenBegin(Expression? guard) {
    // If S0 is the statement `if (E0 case P when E1) S1 else S2`, then:
    // - before(S1) = true(E1).
    FlowModel<Type> branchModel = _popPattern(guard);
    _popScrutinee();
    _stack.add(new _IfContext(branchModel));
  }

  @override
  void ifNullExpression_end() {
    _IfNullExpressionContext<Type> context =
        _stack.removeLast() as _IfNullExpressionContext<Type>;
    _current = _merge(_current, context._shortcutState);
  }

  @override
  void ifNullExpression_rightBegin(
      Expression leftHandSide, Type leftHandSideType) {
    ReferenceWithType<Type>? lhsReference =
        _getExpressionReference(leftHandSide);
    FlowModel<Type> shortcutState;
    _current = _current.split();
    if (lhsReference != null) {
      shortcutState = _current.tryMarkNonNullable(this, lhsReference).ifTrue;
    } else {
      shortcutState = _current;
    }
    if (operations.classifyType(leftHandSideType) ==
        TypeClassification.nullOrEquivalent) {
      shortcutState = shortcutState.setUnreachable();
    }
    _stack.add(new _IfNullExpressionContext<Type>(shortcutState));
    // Note: we are now on the RHS of the `??`, and so at this point in the
    // flow, it is known that the LHS evaluated to `null`.  It's tempting to
    // update `_current` to reflect this (either promoting the type of the LHS,
    // if it's a variable reference, or marking the flow as unreachable, if the
    // LHS had a non-nullable static type).  However:
    // - In the case where the LHS was a variable reference, we can't promote
    //   it, because we don't promote to `Null` (see
    //   https://github.com/dart-lang/language/issues/1505#issuecomment-975706918)
    // - In the case where the LHS had a non-nullable static type, it still
    //   might have been `null` due to mixed-mode unsoundness, so we can't mark
    //   the flow as unreachable without allowing the unsoundness to escalate
    //   (see https://github.com/dart-lang/language/issues/1143)
    //
    // So we just leave `_current` as is.
  }

  @override
  void ifStatement_conditionBegin() {
    _current = _current.split();
  }

  @override
  void ifStatement_elseBegin() {
    _IfContext<Type> context = _stack.last as _IfContext<Type>;
    context._afterThen = _current;
    _current = context._branchModel;
  }

  @override
  void ifStatement_end(bool hasElse) {
    _IfContext<Type> context = _stack.removeLast() as _IfContext<Type>;
    FlowModel<Type> afterThen;
    FlowModel<Type> afterElse;
    if (hasElse) {
      afterThen = context._afterThen!;
      afterElse = _current;
    } else {
      afterThen = _current; // no `else`, so `then` is still current
      afterElse = context._branchModel;
    }
    _current = _merge(afterThen, afterElse);
  }

  @override
  void ifStatement_thenBegin(Expression? condition, Node ifNode) {
    ExpressionInfo<Type> conditionInfo = _expressionEnd(condition);
    _stack.add(new _IfContext(conditionInfo.ifFalse));
    _current = conditionInfo.ifTrue;
  }

  @override
  void initialize(
      Variable variable, Type matchedType, Expression? initializerExpression,
      {required bool isFinal,
      required bool isLate,
      required bool isImplicitlyTyped}) {
    Type unpromotedType = operations.variableType(variable);
    int variableKey = promotionKeyStore.keyForVariable(variable);
    _initialize(
        variableKey, matchedType, _getExpressionInfo(initializerExpression),
        isFinal: isFinal,
        isLate: isLate,
        isImplicitlyTyped: isImplicitlyTyped,
        unpromotedType: unpromotedType);
  }

  @override
  bool isAssigned(Variable variable) {
    return _current
        .infoFor(promotionKeyStore.keyForVariable(variable))
        .assigned;
  }

  @override
  void isExpression_end(Expression isExpression, Expression subExpression,
      bool isNot, Type type) {
    if (operations.isNever(type)) {
      booleanLiteral(isExpression, isNot);
    } else {
      ReferenceWithType<Type>? subExpressionReference =
          _getExpressionReference(subExpression);
      if (subExpressionReference != null) {
        ExpressionInfo<Type> expressionInfo =
            _current.tryPromoteForTypeCheck(this, subExpressionReference, type);
        _storeExpressionInfo(
            isExpression, isNot ? expressionInfo.invert() : expressionInfo);
      }
    }
  }

  @override
  bool isUnassigned(Variable variable) {
    return _current
        .infoFor(promotionKeyStore.keyForVariable(variable))
        .unassigned;
  }

  @override
  void labeledStatement_begin(Statement node) {
    _current = _current.split();
    _BranchTargetContext<Type> context =
        new _BranchTargetContext<Type>(_current.reachable.parent!);
    _stack.add(context);
    _statementToContext[node] = context;
  }

  @override
  void labeledStatement_end() {
    _BranchTargetContext<Type> context =
        _stack.removeLast() as _BranchTargetContext<Type>;
    _current = _merge(_current, context._breakModel);
  }

  @override
  void lateInitializer_begin(Node node) {
    // Late initializers are treated the same as function expressions.
    // Essentially we act as though `late x = expr;` is syntactic sugar for
    // `late x = LAZY_MAGIC(() => expr);` (where `LAZY_MAGIC` creates a lazy
    // evaluation thunk that gets replaced by the result of `expr` once it is
    // evaluated).
    functionExpression_begin(node);
  }

  @override
  void lateInitializer_end() {
    // Late initializers are treated the same as function expressions.
    // Essentially we act as though `late x = expr;` is syntactic sugar for
    // `late x = LAZY_MAGIC(() => expr);` (where `LAZY_MAGIC` creates a lazy
    // evaluation thunk that gets replaced by the result of `expr` once it is
    // evaluated).
    functionExpression_end();
  }

  @override
  void logicalBinaryOp_begin() {
    _current = _current.split();
  }

  @override
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {required bool isAnd}) {
    _BranchContext<Type> context = _stack.removeLast() as _BranchContext<Type>;
    ExpressionInfo<Type> rhsInfo = _expressionEnd(rightOperand);

    FlowModel<Type> trueResult;
    FlowModel<Type> falseResult;
    if (isAnd) {
      trueResult = rhsInfo.ifTrue;
      falseResult = _join(context._branchModel, rhsInfo.ifFalse);
    } else {
      trueResult = _join(context._branchModel, rhsInfo.ifTrue);
      falseResult = rhsInfo.ifFalse;
    }
    _storeExpressionInfo(
        wholeExpression,
        new ExpressionInfo(
            after: _merge(trueResult, falseResult),
            ifTrue: trueResult.unsplit(),
            ifFalse: falseResult.unsplit()));
  }

  @override
  void logicalBinaryOp_rightBegin(Expression leftOperand, Node wholeExpression,
      {required bool isAnd}) {
    ExpressionInfo<Type> conditionInfo = _expressionEnd(leftOperand);
    _stack.add(new _BranchContext<Type>(
        isAnd ? conditionInfo.ifFalse : conditionInfo.ifTrue));
    _current = isAnd ? conditionInfo.ifTrue : conditionInfo.ifFalse;
  }

  @override
  void logicalNot_end(Expression notExpression, Expression operand) {
    ExpressionInfo<Type> conditionInfo = _expressionEnd(operand);
    _storeExpressionInfo(notExpression, conditionInfo.invert());
  }

  @override
  void logicalOrPattern_afterLhs() {
    _OrPatternContext<Type> context = _stack.last as _OrPatternContext<Type>;
    // The current flow state represents the state if the left hand side
    // matched.  Save this so that we can later join it with the state if the
    // right hand side matched.
    context._lhsMatched = _current;
    // An attempt to match the right hand side will only be made if the left
    // hand side failed to match, so set the current flow state to the
    // "unmatched" flow state from the left hand side.
    _current = _unmatched!;
    // And reset `_unmatched` to the value it had prior to visiting the left
    // hand side, so that if the right hand side fails to match, the failure
    // will be accumulated into it.
    _unmatched = context._previousUnmatched;
  }

  @override
  void logicalOrPattern_begin() {
    _PatternContext<Type> context = _stack.last as _PatternContext<Type>;
    // Save the pieces of the current flow state that will be needed later.
    _stack.add(new _OrPatternContext<Type>(
        context._matchedValueInfo,
        context._matchedValuePromotionKey,
        context._matchedValueUnpromotedType,
        _unmatched!));
    // Initialize `_unmatched` to a fresh unreachable flow state, so that after
    // we visit the left hand side, `_unmatched` will represent the flow state
    // if the left hand side failed to match.
    _unmatched = _current.setUnreachable();
  }

  @override
  void logicalOrPattern_end() {
    _OrPatternContext<Type> context =
        _stack.removeLast() as _OrPatternContext<Type>;
    // If either the left hand side or the right hand side matched, the
    // logical-or pattern is considered to have matched.
    _current = _join(context._lhsMatched, _current);
  }

  @override
  void nonEqualityRelationalPattern_end() {
    // Flow analysis has no way of knowing whether the operator will return
    // `true` or `false`, so just assume the worst case--both cases are
    // reachable and no promotions can be done in either case.
    _unmatched = _join(_unmatched!, _current);
  }

  @override
  void nonNullAssert_end(Expression operand) {
    ReferenceWithType<Type>? operandReference =
        _getExpressionReference(operand);
    if (operandReference != null) {
      _current = _current.tryMarkNonNullable(this, operandReference).ifTrue;
    }
  }

  @override
  void nullAwareAccess_end() {
    _NullAwareAccessContext<Type> context =
        _stack.removeLast() as _NullAwareAccessContext<Type>;
    _current = _merge(_current, context._previous);
  }

  @override
  void nullAwareAccess_rightBegin(Expression? target, Type targetType) {
    _current = _current.split();
    _stack.add(new _NullAwareAccessContext<Type>(_current));
    ReferenceWithType<Type>? targetReference = _getExpressionReference(target);
    if (targetReference != null) {
      _current = _current.tryMarkNonNullable(this, targetReference).ifTrue;
    }
    if (operations.classifyType(targetType) ==
        TypeClassification.nullOrEquivalent) {
      _current = _current.setUnreachable();
    }
  }

  @override
  bool nullCheckOrAssertPattern_begin({required bool isAssert}) {
    if (!isAssert) {
      // Account for the possibility that the pattern might not match.  Note
      // that it's tempting to skip this step if matchedValueType is
      // non-nullable (based on the reasoning that a non-null value is
      // guaranteed to satisfy a null check), but in weak mode that's not sound,
      // because in weak mode even non-nullable values might be null.  We don't
      // want flow analysis behavior to depend on mode, so we conservatively
      // assume the pattern might not match regardless of matchedValueType.
      _unmatched = _join(_unmatched, _current);
    }
    FlowModel<Type>? ifNotNull = _nullCheckPattern();
    if (ifNotNull != null) {
      _current = ifNotNull;
    }
    // Note: we don't need to push a new pattern context for the subpattern,
    // because (a) the subpattern matches the same value as the outer pattern,
    // and (b) promotion of the synthetic cache variable takes care of
    // establishing the correct matched value type.
    return ifNotNull == null;
  }

  @override
  void nullCheckOrAssertPattern_end() {}

  @override
  void nullLiteral(Expression expression) {
    _storeExpressionInfo(expression, new _NullInfo(_current));
  }

  @override
  void parenthesizedExpression(
      Expression outerExpression, Expression innerExpression) {
    forwardExpression(outerExpression, innerExpression);
  }

  @override
  void patternAssignment_afterRhs(Expression rhs, Type rhsType) {
    _pushPattern(_pushScrutinee(rhs, rhsType));
  }

  @override
  void patternAssignment_end() {
    _popPattern(null);
    _popScrutinee();
  }

  @override
  void patternForIn_afterExpression(Type elementType) {
    _pushPattern(_pushScrutinee(null, elementType));
  }

  @override
  void patternForIn_end() {
    _popPattern(null);
    _popScrutinee();
  }

  @override
  void patternVariableDeclaration_afterInitializer(
      Expression initializer, Type initializerType) {
    _pushPattern(_pushScrutinee(initializer, initializerType));
  }

  @override
  void patternVariableDeclaration_end() {
    _popPattern(null);
    _popScrutinee();
  }

  @override
  void popSubpattern() {
    _FlowContext context = _stack.removeLast();
    assert(context is _PatternContext<Type>);
  }

  @override
  Type? promotedPropertyType(Expression? target, String propertyName,
      Object? propertyMember, Type staticType) {
    return _handleProperty(
        null, target, propertyName, propertyMember, staticType);
  }

  @override
  Type? promotedType(Variable variable) {
    return _current
        .infoFor(promotionKeyStore.keyForVariable(variable))
        .promotedTypes
        ?.last;
  }

  @override
  bool promoteForPattern(
      {required Type matchedType,
      required Type knownType,
      bool matchFailsIfWrongType = true,
      bool matchMayFailEvenIfCorrectType = false}) {
    _PatternContext<Type> context = _stack.last as _PatternContext<Type>;
    ReferenceWithType<Type> matchedValueReference =
        context.createReference(matchedType);
    bool coversMatchedType = operations.isSubtypeOf(matchedType, knownType);
    // Promote the synthetic cache variable the pattern is being matched
    // against.
    ExpressionInfo<Type> promotionInfo =
        _current.tryPromoteForTypeCheck(this, matchedValueReference, knownType);
    FlowModel<Type> ifTrue = promotionInfo.ifTrue;
    FlowModel<Type> ifFalse = promotionInfo.ifFalse;
    ReferenceWithType<Type>? scrutineeReference = _scrutineeReference;
    // If there's a scrutinee, and its value is known to be the same as that of
    // the synthetic cache variable, promote it too.
    if (scrutineeReference != null &&
        _current.infoFor(matchedValueReference.promotionKey).ssaNode ==
            _current.infoFor(scrutineeReference.promotionKey).ssaNode) {
      ifTrue = ifTrue
          .tryPromoteForTypeCheck(this, scrutineeReference, knownType)
          .ifTrue;
      ifFalse = ifFalse
          .tryPromoteForTypeCheck(this, scrutineeReference, knownType)
          .ifFalse;
    }
    _current = ifTrue;
    if (matchMayFailEvenIfCorrectType ||
        (matchFailsIfWrongType && !coversMatchedType)) {
      _unmatched = _join(_unmatched!, coversMatchedType ? ifTrue : ifFalse);
    }
    return coversMatchedType;
  }

  @override
  Type? propertyGet(Expression? wholeExpression, Expression target,
      String propertyName, Object? propertyMember, Type staticType) {
    return _handleProperty(
        wholeExpression, target, propertyName, propertyMember, staticType);
  }

  @override
  void pushSubpattern(Type matchedType) {
    assert(_stack.last is _PatternContext<Type>);
    assert(_unmatched != null);
    _stack.add(new _PatternContext<Type>(
        null, _makeTemporaryReference(new SsaNode<Type>(null)), matchedType));
  }

  @override
  SsaNode<Type>? ssaNodeForTesting(Variable variable) => _current
      .variableInfo[promotionKeyStore.keyForVariable(variable)]?.ssaNode;

  @override
  bool switchStatement_afterCase() {
    _SwitchStatementContext<Type> context =
        _stack.last as _SwitchStatementContext<Type>;
    bool isLocallyReachable = _current.reachable.locallyReachable;
    _current = _current.unsplit();
    if (isLocallyReachable) {
      context._breakModel = _join(context._breakModel, _current);
    }
    return isLocallyReachable;
  }

  @override
  void switchStatement_beginAlternative() {
    _SwitchAlternativesContext<Variable, Type> context =
        _stack.last as _SwitchAlternativesContext<Variable, Type>;
    _current = context._switchStatementContext._unmatched;
    _pushPattern(context._switchStatementContext._matchedValueInfo);
  }

  @override
  void switchStatement_beginAlternatives() {
    _SwitchStatementContext<Type> context =
        _stack.last as _SwitchStatementContext<Type>;
    _stack.add(new _SwitchAlternativesContext<Variable, Type>(context));
  }

  @override
  bool switchStatement_end(bool isExhaustive) {
    _SwitchStatementContext<Type> context =
        _stack.removeLast() as _SwitchStatementContext<Type>;
    bool isProvenExhaustive = !context._unmatched.reachable.locallyReachable;
    FlowModel<Type>? breakState = context._breakModel;

    // If there is an implicit fall-through default, join it to any breaks.
    if (!isExhaustive) breakState = _join(breakState, context._previous);

    // If there were no breaks (neither implicit nor explicit), then
    // `breakState` will be `null`.  This means this is an empty switch
    // statement and the type of the scrutinee is an exhaustive type.  This
    // could happen, for instance, if the scrutinee type is an abstract sealed
    // class that has no subclasses.  It makes the most sense to treat the code
    // after the switch as unreachable, because that's the normal behavior of a
    // switch over an exhaustive type with no `break`s.  It is sound to do so
    // because the type is uninhabited, therefore the body of the switch
    // statement itself will never be reached.
    breakState ??= context._previous.setUnreachable();

    _current = breakState.unsplit();
    _popScrutinee();
    return isProvenExhaustive;
  }

  @override
  void switchStatement_endAlternative(
      Expression? guard, Map<String, Variable> variables) {
    FlowModel<Type> unmatched = _popPattern(guard);
    _SwitchAlternativesContext<Variable, Type> context =
        _stack.last as _SwitchAlternativesContext<Variable, Type>;
    // Future alternatives will be analyzed under the assumption that this
    // alternative didn't match.  This models the fact that a switch statement
    // behaves like a chain of if/else tests.
    context._switchStatementContext._unmatched = unmatched;

    PatternVariableInfo<Variable> patternVariableInfo =
        context._patternVariableInfo;
    for (MapEntry<String, Variable> entry in variables.entries) {
      String variableName = entry.key;
      Variable variable = entry.value;
      (patternVariableInfo.componentVariables[variableName] ??= [])
          .add(variable);
      int promotionKey = promotionKeyStore.keyForVariable(variable);
      // See if this variable appeared in any previous patterns that share the
      // same case body.
      int? previousPromotionKey =
          patternVariableInfo.patternVariablePromotionKeys[variableName];
      if (previousPromotionKey == null) {
        // This variable hasn't been seen in any previous patterns that share
        // the same body.  So we can safely use the promotion key we have to
        // store information about this variable.
        patternVariableInfo.patternVariablePromotionKeys[variableName] =
            promotionKey;
      } else {
        // This variable has been seen in previous patterns, so we have to
        // copy promotion data into the previously-used promotion key, to
        // ensure that the promotion information is properly joined.
        copyPromotionData(
            sourceKey: promotionKey, destinationKey: previousPromotionKey);
      }
    }
    context._combinedModel = _join(context._combinedModel, _current);
  }

  @override
  PatternVariableInfo<Variable> switchStatement_endAlternatives(Statement? node,
      {required bool hasLabels}) {
    _SwitchAlternativesContext<Variable, Type> alternativesContext =
        _stack.removeLast() as _SwitchAlternativesContext<Variable, Type>;
    _SwitchStatementContext<Type> switchContext =
        _stack.last as _SwitchStatementContext<Type>;
    if (hasLabels) {
      AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node!);
      _current = switchContext._previous
          .conservativeJoin(this, info.written, info.captured);
    } else {
      _current = alternativesContext._combinedModel ?? switchContext._unmatched;
    }
    // Do a control flow split so that in switchStatement_afterCase, we'll be
    // able to tell whether the end of the case body was reachable from its
    // start.
    _current = _current.split();
    return alternativesContext._patternVariableInfo;
  }

  @override
  void switchStatement_expressionEnd(
      Statement? switchStatement, Expression scrutinee, Type scrutineeType) {
    EqualityInfo<Type> matchedValueInfo =
        _pushScrutinee(scrutinee, scrutineeType);
    _current = _current.split();
    _SwitchStatementContext<Type> context = new _SwitchStatementContext<Type>(
        _current.reachable.parent!, _current, matchedValueInfo);
    _stack.add(context);
    if (switchStatement != null) {
      _statementToContext[switchStatement] = context;
    }
  }

  @override
  void thisOrSuper(Expression expression, Type staticType) {
    _storeExpressionReference(expression, _thisOrSuperReference(staticType));
  }

  @override
  Type? thisOrSuperPropertyGet(Expression expression, String propertyName,
      Object? propertyMember, Type staticType) {
    return _handleProperty(
        expression, null, propertyName, propertyMember, staticType);
  }

  @override
  void tryCatchStatement_bodyBegin() {
    _current = _current.split();
    _stack.add(new _TryContext<Type>(_current));
  }

  @override
  void tryCatchStatement_bodyEnd(Node body) {
    FlowModel<Type> afterBody = _current;

    _TryContext<Type> context = _stack.last as _TryContext<Type>;
    FlowModel<Type> beforeBody = context._previous;

    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(body);
    FlowModel<Type> beforeCatch =
        beforeBody.conservativeJoin(this, info.written, info.captured);

    context._beforeCatch = beforeCatch;
    context._afterBodyAndCatches = afterBody;
  }

  @override
  void tryCatchStatement_catchBegin(
      Variable? exceptionVariable, Variable? stackTraceVariable) {
    _TryContext<Type> context = _stack.last as _TryContext<Type>;
    _current = context._beforeCatch!;
    if (exceptionVariable != null) {
      int exceptionVariableKey =
          promotionKeyStore.keyForVariable(exceptionVariable);
      _current = _current.declare(exceptionVariableKey, true);
    }
    if (stackTraceVariable != null) {
      int stackTraceVariableKey =
          promotionKeyStore.keyForVariable(stackTraceVariable);
      _current = _current.declare(stackTraceVariableKey, true);
    }
  }

  @override
  void tryCatchStatement_catchEnd() {
    _TryContext<Type> context = _stack.last as _TryContext<Type>;
    context._afterBodyAndCatches =
        _join(context._afterBodyAndCatches, _current);
  }

  @override
  void tryCatchStatement_end() {
    _TryContext<Type> context = _stack.removeLast() as _TryContext<Type>;
    _current = context._afterBodyAndCatches!.unsplit();
  }

  @override
  void tryFinallyStatement_bodyBegin() {
    _stack.add(new _TryFinallyContext<Type>(_current));
  }

  @override
  void tryFinallyStatement_end() {
    _TryFinallyContext<Type> context =
        _stack.removeLast() as _TryFinallyContext<Type>;
    _current = context._afterBodyAndCatches!
        .attachFinally(operations, context._beforeFinally!, _current);
  }

  @override
  void tryFinallyStatement_finallyBegin(Node body) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(body);
    _TryFinallyContext<Type> context = _stack.last as _TryFinallyContext<Type>;
    context._afterBodyAndCatches = _current;
    _current = _join(_current,
        context._previous.conservativeJoin(this, info.written, info.captured));
    context._beforeFinally = _current;
  }

  @override
  Type? variableRead(Expression expression, Variable variable) {
    Type unpromotedType = operations.variableType(variable);
    int variableKey = promotionKeyStore.keyForVariable(variable);
    VariableModel<Type> variableModel = _current._getInfo(variableKey);
    Type? promotedType = variableModel.promotedTypes?.last;
    _storeExpressionReference(
        expression, _variableReference(variableKey, unpromotedType));
    ExpressionInfo<Type>? expressionInfo = variableModel.ssaNode?.expressionInfo
        ?.rebaseForward(operations, _current);
    if (expressionInfo != null) {
      _storeExpressionInfo(expression, expressionInfo);
    }
    return promotedType;
  }

  @override
  void whileStatement_bodyBegin(
      Statement whileStatement, Expression condition) {
    ExpressionInfo<Type> conditionInfo = _expressionEnd(condition);
    _WhileContext<Type> context =
        new _WhileContext<Type>(_current.reachable.parent!, conditionInfo);
    _stack.add(context);
    _statementToContext[whileStatement] = context;
    _current = conditionInfo.ifTrue;
  }

  @override
  void whileStatement_conditionBegin(Node node) {
    _current = _current.split();
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node);
    _current = _current.conservativeJoin(this, info.written, info.captured);
  }

  @override
  void whileStatement_end() {
    _WhileContext<Type> context = _stack.removeLast() as _WhileContext<Type>;
    _current = _merge(context._conditionInfo.ifFalse, context._breakModel)
        .inheritTested(operations, _current);
  }

  @override
  Map<Type, NonPromotionReason> Function() whyNotPromoted(Expression target) {
    if (identical(target, _expressionWithReference)) {
      ReferenceWithType<Type>? referenceWithType = _expressionReference;
      if (referenceWithType != null) {
        VariableModel<Type>? currentVariableInfo =
            _current.variableInfo[referenceWithType.promotionKey];
        if (currentVariableInfo != null) {
          return _getNonPromotionReasons(
              referenceWithType, currentVariableInfo);
        }
      }
    }
    return () => {};
  }

  @override
  Map<Type, NonPromotionReason> Function() whyNotPromotedImplicitThis(
      Type staticType) {
    VariableModel<Type>? currentThisInfo =
        _current.variableInfo[promotionKeyStore.thisPromotionKey];
    if (currentThisInfo == null) {
      return () => {};
    }
    return _getNonPromotionReasons(
        _thisOrSuperReference(staticType), currentThisInfo);
  }

  @override
  void write(Node node, Variable variable, Type writtenType,
      Expression? writtenExpression) {
    _write(node, variable, writtenType, _getExpressionInfo(writtenExpression));
  }

  /// Computes an [EqualityInfo] object to describe the expression [expression],
  /// having static type [type].
  EqualityInfo<Type> _computeEqualityInfo(Expression expression, Type type) =>
      new EqualityInfo<Type>._(_getExpressionInfo(expression), type,
          _getExpressionReference(expression));

  @override
  void _dumpState() {
    print('  current: $_current');
    if (_unmatched != null) {
      print('  unmatched: $_unmatched');
    }
    if (_scrutineeReference != null) {
      print('  scrutineeReference: $_scrutineeReference');
    }
    if (_scrutineeSsaNode != null) {
      print('  scrutineeSsaNode: $_scrutineeSsaNode');
    }
    if (_expressionWithInfo != null) {
      print('  expressionWithInfo: $_expressionWithInfo');
    }
    if (_expressionInfo != null) {
      print('  expressionInfo: $_expressionInfo');
    }
    if (_expressionWithReference != null) {
      print('  expressionWithReference: $_expressionWithReference');
    }
    if (_expressionReference != null) {
      print('  expressionReference: $_expressionReference');
    }
    if (_stack.isNotEmpty) {
      print('  stack:');
      for (_FlowContext stackEntry in _stack.reversed) {
        print('    $stackEntry');
      }
    }
  }

  /// Analyzes an equality check between the operands described by
  /// [leftOperandInfo] and [rightOperandInfo].
  _EqualityCheckResult _equalityCheck(
      EqualityInfo<Type> leftOperandInfo, EqualityInfo<Type> rightOperandInfo) {
    ReferenceWithType<Type>? lhsReference = leftOperandInfo._reference;
    ReferenceWithType<Type>? rhsReference = rightOperandInfo._reference;
    TypeClassification leftOperandTypeClassification =
        operations.classifyType(leftOperandInfo._type);
    TypeClassification rightOperandTypeClassification =
        operations.classifyType(rightOperandInfo._type);
    if (leftOperandTypeClassification == TypeClassification.nullOrEquivalent &&
        rightOperandTypeClassification == TypeClassification.nullOrEquivalent) {
      return const _GuaranteedEqual();
    } else if ((leftOperandTypeClassification ==
                TypeClassification.nullOrEquivalent &&
            rightOperandTypeClassification == TypeClassification.nonNullable) ||
        (rightOperandTypeClassification ==
                TypeClassification.nullOrEquivalent &&
            leftOperandTypeClassification == TypeClassification.nonNullable)) {
      // In strong mode the test is guaranteed to produce a "not equal" result,
      // but weak mode it might produce an "equal" result.  We don't want flow
      // analysis behavior to depend on mode, so we conservatively assume that
      // either result is possible.
      return const _NoEqualityInformation();
    } else if (leftOperandInfo._expressionInfo is _NullInfo<Type>) {
      return new _EqualityCheckIsNullCheck(rhsReference,
          isReferenceOnRight: true);
    } else if (rightOperandInfo._expressionInfo is _NullInfo<Type>) {
      return new _EqualityCheckIsNullCheck(lhsReference,
          isReferenceOnRight: false);
    } else {
      return const _NoEqualityInformation();
    }
  }

  /// Gets the [ExpressionInfo] associated with the [expression] (which should
  /// be the last expression that was traversed).  If there is no
  /// [ExpressionInfo] associated with the [expression], then a fresh
  /// [ExpressionInfo] is created recording the current flow analysis state.
  ExpressionInfo<Type> _expressionEnd(Expression? expression) =>
      _getExpressionInfo(expression) ?? new _TrivialExpressionInfo(_current);

  /// Gets the [ExpressionInfo] associated with the [expression] (which should
  /// be the last expression that was traversed).  If there is no
  /// [ExpressionInfo] associated with the [expression], then `null` is
  /// returned.
  ExpressionInfo<Type>? _getExpressionInfo(Expression? expression) {
    if (identical(expression, _expressionWithInfo)) {
      ExpressionInfo<Type>? expressionInfo = _expressionInfo;
      _expressionInfo = null;
      return expressionInfo;
    } else {
      return null;
    }
  }

  /// Gets the [Reference] associated with the [expression] (which should be the
  /// last expression that was traversed).  If there is no [Reference]
  /// associated with the [expression], then `null` is returned.
  ReferenceWithType<Type>? _getExpressionReference(Expression? expression) {
    if (identical(expression, _expressionWithReference)) {
      ReferenceWithType<Type>? expressionReference = _expressionReference;
      _expressionReference = null;
      return expressionReference;
    } else {
      return null;
    }
  }

  Map<Type, NonPromotionReason> Function() _getNonPromotionReasons(
      ReferenceWithType<Type> reference,
      VariableModel<Type> currentVariableInfo) {
    if (reference is _PropertyReferenceWithType<Type>) {
      List<Type>? promotedTypes = currentVariableInfo.promotedTypes;
      if (promotedTypes != null) {
        return () {
          Map<Type, NonPromotionReason> result = <Type, NonPromotionReason>{};
          for (Type type in promotedTypes) {
            result[type] = new PropertyNotPromoted(reference.propertyName,
                reference.propertyMember, reference.type);
          }
          return result;
        };
      }
    } else {
      Variable? variable =
          promotionKeyStore.variableForKey(reference.promotionKey);
      if (variable == null) {
        List<Type>? promotedTypes = currentVariableInfo.promotedTypes;
        if (promotedTypes != null) {
          return () {
            Map<Type, NonPromotionReason> result = <Type, NonPromotionReason>{};
            for (Type type in promotedTypes) {
              result[type] = new ThisNotPromoted();
            }
            return result;
          };
        }
      } else {
        return () {
          Map<Type, NonPromotionReason> result = <Type, NonPromotionReason>{};
          Type currentType = currentVariableInfo.promotedTypes?.last ??
              operations.variableType(variable);
          NonPromotionHistory? nonPromotionHistory =
              currentVariableInfo.nonPromotionHistory;
          while (nonPromotionHistory != null) {
            Type nonPromotedType = nonPromotionHistory.type;
            if (!operations.isSubtypeOf(currentType, nonPromotedType)) {
              result[nonPromotedType] ??=
                  nonPromotionHistory.nonPromotionReason;
            }
            nonPromotionHistory = nonPromotionHistory.previous;
          }
          return result;
        };
      }
    }
    return () => {};
  }

  /// Common code for handling patterns that perform an equality check.
  /// [operand] is the expression that the matched value is being compared to,
  /// and [operandType] is its type.
  ///
  /// If [notEqual] is `true`, the pattern matches if the matched value is *not*
  /// equal to the operand; otherwise, it matches if the matched value is
  /// *equal* to the operand.
  void _handleEqualityCheckPattern(Expression operand, Type operandType,
      {required bool notEqual}) {
    _PatternContext<Type> context = _stack.last as _PatternContext<Type>;
    _EqualityCheckResult equalityCheckResult = _equalityCheck(
        new EqualityInfo._(context._matchedValueInfo, getMatchedValueType(),
            context.createReference(getMatchedValueType())),
        equalityOperand_end(operand, operandType));
    if (equalityCheckResult is _NoEqualityInformation) {
      // We have no information so we have to assume the pattern might or
      // might not match.
      _unmatched = _join(_unmatched!, _current);
    } else if (equalityCheckResult is _EqualityCheckIsNullCheck<Type>) {
      FlowModel<Type>? ifNotNull;
      if (!equalityCheckResult.isReferenceOnRight) {
        // The `null` literal is on the right hand side of the implicit
        // equality check, meaning it is the constant value.  So the user is
        // doing something like this:
        //
        //     if (v case == null) { ... }
        //
        // So we want to promote the type of `v` in the case where the
        // constant pattern *didn't* match.
        ifNotNull = _nullCheckPattern();
        if (ifNotNull == null) {
          // `_nullCheckPattern` returns `null` in the case where the matched
          // value type is non-nullable.  In fully sound programs, this would
          // mean that the pattern cannot possibly match.  However, in mixed
          // mode programs it might match due to unsoundness.  Since we don't
          // want type inference results to change when a program becomes
          // fully sound, we have to assume that we're in mixed mode, and thus
          // the pattern might match.
          ifNotNull = _current;
        }
      } else {
        // The `null` literal is on the left hand side of the implicit
        // equality check, meaning it is the scrutinee.  So the user is doing
        // something silly like this:
        //
        //     if (null case == c) { ... }
        //
        // (where `c` is some constant).  There's no variable to promote.
        //
        // Since flow analysis can't make use of the results of constant
        // evaluation, we can't really assume anything; as far as we know, the
        // pattern might or might not match.
        ifNotNull = _current;
      }
      if (notEqual) {
        _unmatched = _join(_unmatched!, _current);
        _current = ifNotNull;
      } else {
        _unmatched = _join(_unmatched!, ifNotNull);
      }
    } else {
      assert(equalityCheckResult is _GuaranteedEqual);
      if (notEqual) {
        // Both operands are known by flow analysis to compare equal, so the
        // constant pattern is guaranteed *not* to match.
        _unmatched = _join(_unmatched!, _current);
        _current = _current.setUnreachable();
      } else {
        // Both operands are known by flow analysis to compare equal, so the
        // constant pattern is guaranteed to match.  Since our approach to
        // handling patterns in flow analysis uses "implicit and" semantics
        // (initially assuming that the pattern always matches, and then
        // updating the `_current` and `_unmatched` states to reflect what
        // values the pattern rejects), we don't have to do any updates.
      }
    }
  }

  Type? _handleProperty(Expression? wholeExpression, Expression? target,
      String propertyName, Object? propertyMember, Type staticType) {
    int targetKey;
    bool isPromotable = propertyMember != null &&
        operations.isPropertyPromotable(propertyMember);
    if (target == null) {
      targetKey = promotionKeyStore.thisPromotionKey;
    } else {
      ReferenceWithType<Type>? targetReference =
          _getExpressionReference(target);
      if (targetReference == null) return null;
      targetKey = targetReference.promotionKey;
      if (!targetReference.isPromotable && !targetReference.isThisOrSuper) {
        isPromotable = false;
      }
    }
    _PropertyReferenceWithType<Type> propertyReference =
        new _PropertyReferenceWithType<Type>(propertyName, propertyMember,
            promotionKeyStore.getProperty(targetKey, propertyName), staticType,
            isPromotable: isPromotable);
    if (wholeExpression != null) {
      _storeExpressionReference(wholeExpression, propertyReference);
    }
    if (!propertyReference.isPromotable) {
      return null;
    }
    if (_current
        .infoFor(promotionKeyStore.getRootVariableKey(targetKey))
        .writeCaptured) {
      // The variable that was used to reach this property has been write
      // captured, so the property can't be promoted.
      return null;
    }
    Type? promotedType =
        _current.infoFor(propertyReference.promotionKey).promotedTypes?.last;
    if (promotedType == null ||
        !operations.isSubtypeOf(promotedType, staticType)) {
      return null;
    }
    return promotedType;
  }

  void _initialize(
      int promotionKey, Type matchedType, ExpressionInfo<Type>? expressionInfo,
      {required bool isFinal,
      required bool isLate,
      required bool isImplicitlyTyped,
      required Type unpromotedType}) {
    if (isLate) {
      // Don't use expression info for late variables, since we don't know when
      // they'll be initialized.
      expressionInfo = null;
    } else if (isImplicitlyTyped && !respectImplicitlyTypedVarInitializers) {
      // If the language version is too old, SSA analysis has to ignore
      // initializer expressions for implicitly typed variables, in order to
      // preserve the buggy behavior of
      // https://github.com/dart-lang/language/issues/1785.
      expressionInfo = null;
    }
    SsaNode<Type> newSsaNode = new SsaNode<Type>(
        expressionInfo is _TrivialExpressionInfo ? null : expressionInfo);
    _current = _current.write(
        this, null, promotionKey, matchedType, newSsaNode, operations,
        promoteToTypeOfInterest: !isImplicitlyTyped && !isFinal,
        unpromotedType: unpromotedType);
    if (isImplicitlyTyped && operations.isTypeParameterType(matchedType)) {
      _current = _current
          .tryPromoteForTypeCheck(this,
              _variableReference(promotionKey, unpromotedType), matchedType)
          .ifTrue;
    }
  }

  FlowModel<Type> _join(FlowModel<Type>? first, FlowModel<Type>? second) =>
      FlowModel.join(operations, first, second, _current._emptyVariableMap);

  /// Creates a promotion key representing a temporary variable that doesn't
  /// correspond to any variable in the user's source code.  This is used by
  /// flow analysis to model the synthetic variables used during pattern
  /// matching to cache the values that the pattern, and its subpatterns, are
  /// being matched against.
  int _makeTemporaryReference(SsaNode<Type>? ssaNode) {
    int promotionKey = promotionKeyStore.makeTemporaryKey();
    _current = _current._updateVariableInfo(
        promotionKey,
        new VariableModel(
            promotedTypes: null,
            tested: const [],
            assigned: true,
            unassigned: false,
            ssaNode: ssaNode));
    return promotionKey;
  }

  FlowModel<Type> _merge(FlowModel<Type> first, FlowModel<Type>? second) =>
      FlowModel.merge(operations, first, second, _current._emptyVariableMap);

  /// Computes an updated flow model representing the result of a null check
  /// performed by a pattern.  The returned flow model represents what is known
  /// about the program state if the matched value is determined to be not equal
  /// to `null`.
  ///
  /// If the matched value's type is non-nullable, then `null` is returned.
  FlowModel<Type>? _nullCheckPattern() {
    _PatternContext<Type> context = _stack.last as _PatternContext<Type>;
    Type matchedValueType = getMatchedValueType();
    ReferenceWithType<Type> matchedValueReference =
        context.createReference(matchedValueType);
    // Promote
    TypeClassification typeClassification =
        operations.classifyType(matchedValueType);
    if (typeClassification == TypeClassification.nonNullable) {
      return null;
    } else {
      FlowModel<Type>? ifNotNull =
          _current.tryMarkNonNullable(this, matchedValueReference).ifTrue;
      ReferenceWithType<Type>? scrutineeReference = _scrutineeReference;
      // If there's a scrutinee, and its value is known to be the same as that
      // of the synthetic cache variable, promote it too.
      if (scrutineeReference != null &&
          _current.infoFor(matchedValueReference.promotionKey).ssaNode ==
              _current.infoFor(scrutineeReference.promotionKey).ssaNode) {
        ifNotNull =
            ifNotNull.tryMarkNonNullable(this, scrutineeReference).ifTrue;
      }
      if (typeClassification == TypeClassification.nullOrEquivalent) {
        ifNotNull = ifNotNull.setUnreachable();
      }
      return ifNotNull;
    }
  }

  FlowModel<Type> _popPattern(Expression? guard) {
    _TopPatternContext<Type> context =
        _stack.removeLast() as _TopPatternContext<Type>;
    FlowModel<Type> unmatched = _unmatched!;
    _unmatched = context._previousUnmatched;
    if (guard != null) {
      ExpressionInfo<Type> guardInfo = _expressionEnd(guard);
      _current = guardInfo.ifTrue;
      unmatched = _join(unmatched, guardInfo.ifFalse);
    }
    return unmatched;
  }

  void _popScrutinee() {
    _ScrutineeContext<Type> context =
        _stack.removeLast() as _ScrutineeContext<Type>;
    _scrutineeReference = context.previousScrutineeReference;
    _scrutineeSsaNode = context.previousScrutineeSsaNode;
  }

  /// Updates the [_stack] to reflect the fact that flow analysis is entering
  /// into a pattern or subpattern match.  [matchedValueInfo] should be the
  /// [EqualityInfo] representing the value being matched.
  void _pushPattern(EqualityInfo<Type> matchedValueInfo) {
    _stack.add(new _TopPatternContext<Type>(
        matchedValueInfo._expressionInfo,
        matchedValueInfo._reference!.promotionKey,
        matchedValueInfo._type,
        _unmatched));
    _unmatched = _current.setUnreachable();
  }

  /// Updates the [_stack] to reflect the fact that flow analysis is entering
  /// into a construct that performs pattern matching.  [scrutinee] should be
  /// the expression that is being matched (or `null` if there is no expression
  /// that's being matched directly, as happens when in `for-in` loops).
  /// [scrutineeType] should be the static type of the scrutinee.
  ///
  /// The returned value is the [EqualityInfo] representing the value being
  /// matched.  It should be passed to [_pushPattern].
  EqualityInfo<Type> _pushScrutinee(Expression? scrutinee, Type scrutineeType) {
    EqualityInfo<Type>? scrutineeInfo = scrutinee == null
        ? null
        : _computeEqualityInfo(scrutinee, scrutineeType);
    _stack.add(new _ScrutineeContext<Type>(
        previousScrutineeReference: _scrutineeReference,
        previousScrutineeSsaNode: _scrutineeSsaNode));
    ReferenceWithType<Type>? scrutineeReference = scrutineeInfo?._reference;
    _scrutineeReference = scrutineeReference;
    _scrutineeSsaNode = scrutineeReference == null
        ? new SsaNode<Type>(null)
        : _current.infoFor(scrutineeReference.promotionKey).ssaNode;
    return new EqualityInfo._(
        scrutineeInfo?._expressionInfo,
        scrutineeType,
        new ReferenceWithType(
            _makeTemporaryReference(_scrutineeSsaNode), scrutineeType,
            isPromotable: true, isThisOrSuper: false));
  }

  /// Associates [expression], which should be the most recently visited
  /// expression, with the given [expressionInfo] object, and updates the
  /// current flow model state to correspond to it.
  void _storeExpressionInfo(
      Expression expression, ExpressionInfo<Type> expressionInfo) {
    _expressionWithInfo = expression;
    _expressionInfo = expressionInfo;
    _current = expressionInfo.after;
  }

  /// Associates [expression], which should be the most recently visited
  /// expression, with the given [Reference] object.
  void _storeExpressionReference(
      Expression expression, ReferenceWithType<Type> expressionReference) {
    _expressionWithReference = expression;
    _expressionReference = expressionReference;
  }

  ReferenceWithType<Type> _thisOrSuperReference(Type staticType) =>
      new ReferenceWithType<Type>(
          promotionKeyStore.thisPromotionKey, staticType,
          isPromotable: false, isThisOrSuper: true);

  ReferenceWithType<Type> _variableReference(
          int variableKey, Type unpromotedType) =>
      new ReferenceWithType<Type>(variableKey,
          _current.infoFor(variableKey).promotedTypes?.last ?? unpromotedType,
          isPromotable: true, isThisOrSuper: false);

  /// Common logic for handling writes to variables, whether they occur as part
  /// of an ordinary assignment or a pattern assignment.
  void _write(Node node, Variable variable, Type writtenType,
      ExpressionInfo<Type>? expressionInfo) {
    Type unpromotedType = operations.variableType(variable);
    int variableKey = promotionKeyStore.keyForVariable(variable);
    SsaNode<Type> newSsaNode = new SsaNode<Type>(
        expressionInfo is _TrivialExpressionInfo ? null : expressionInfo);
    _current = _current.write(
        this,
        new DemoteViaExplicitWrite<Variable>(variable, node),
        variableKey,
        writtenType,
        newSsaNode,
        operations,
        unpromotedType: unpromotedType);
  }
}

/// Base class for objects representing constructs in the Dart programming
/// language for which flow analysis information needs to be tracked.
abstract class _FlowContext {
  _FlowContext() {
    assert(() {
      // Check that `_debugType` has been overridden in a way that reflects the
      // class name.  Note that this assumes the behavior of `runtimeType` in
      // the VM, but that's ok, because this code is only active when asserts
      // are enabled, and we only run unit tests on the VM.
      String expectedDebugType = runtimeType.toString();
      int lessThanIndex = expectedDebugType.indexOf('<');
      if (lessThanIndex > 0) {
        expectedDebugType = expectedDebugType.substring(0, lessThanIndex);
      }
      assert(_debugType == expectedDebugType,
          'Expected a debug type of $expectedDebugType, got $_debugType');
      return true;
    }());
  }

  /// Returns a freshly allocated map whose keys are the names of fields in the
  /// class, and whose values are the values of those fields.
  ///
  /// This is used by [toString] to print out information for debugging.
  Map<String, Object?> get _debugFields => {};

  /// Returns a string representation of the class name.  This is used by
  /// [toString] to print out information for debugging.
  String get _debugType;

  @override
  String toString() {
    List<String> fields = [
      for (MapEntry<String, Object?> entry in _debugFields.entries)
        if (entry.value != null) '${entry.key}: ${entry.value}'
    ];
    return '$_debugType(${fields.join(', ')})';
  }
}

/// [_FlowContext] representing a function expression.
class _FunctionExpressionContext<Type extends Object>
    extends _SimpleContext<Type> {
  _FunctionExpressionContext(super.previous);

  @override
  String get _debugType => '_FunctionExpressionContext';
}

/// Specialization of [_EqualityCheckResult] used as the return value for
/// [_FlowAnalysisImpl._equalityCheck] when it is determined that the two
/// operands are guaranteed to be equal to one another, so the code path that
/// results from a not-equal result should be marked as unreachable.  (This
/// happens if both operands have type `Null`).
class _GuaranteedEqual extends _EqualityCheckResult {
  const _GuaranteedEqual() : super._();
}

/// [_FlowContext] representing an `if` statement.
class _IfContext<Type extends Object> extends _BranchContext<Type> {
  /// Flow model associated with the state of program execution after the `if`
  /// statement executes, in the circumstance where the "then" branch is taken.
  FlowModel<Type>? _afterThen;

  _IfContext(super._branchModel);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['afterThen'] = _afterThen;

  @override
  String get _debugType => '_IfContext';
}

/// [_FlowContext] representing an "if-null" (`??`) expression.
class _IfNullExpressionContext<Type extends Object> extends _FlowContext {
  /// The state if the operation short-cuts (i.e. if the expression before the
  /// `??` was non-`null`).
  final FlowModel<Type> _shortcutState;

  _IfNullExpressionContext(this._shortcutState);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['shortcutState'] = _shortcutState;

  @override
  String get _debugType => '_IfNullExpressionContext';
}

/// Contextual information tracked by legacy type promotion about a binary "and"
/// expression (`&&`).
class _LegacyBinaryAndContext<Type extends Object>
    extends _LegacyContext<Type> {
  /// Types that were shown by the LHS of the "and" expression.
  final Map<int, Type> _lhsShownTypes;

  /// Information about variables that might be assigned by the RHS of the "and"
  /// expression.
  final AssignedVariablesNodeInfo _assignedVariablesInfoForRhs;

  _LegacyBinaryAndContext(super.previousKnownTypes, this._lhsShownTypes,
      this._assignedVariablesInfoForRhs);
}

/// Contextual information tracked by legacy type promotion about a statement or
/// expression.
class _LegacyContext<Type> {
  /// The set of known types in effect before the statement or expression in
  /// question was encountered.
  final Map<int, Type> _previousKnownTypes;

  _LegacyContext(this._previousKnownTypes);
}

/// Data tracked by legacy type promotion about an expression.
class _LegacyExpressionInfo<Type> {
  /// Variables whose types are "shown" by the expression in question.
  ///
  /// For example, the spec says that the expression `x is T` "shows" `x` to
  /// have type `T`, so accordingly, the [_LegacyExpressionInfo] for `x is T`
  /// will have an entry in this map that maps `x` to `T`.
  final Map<int, Type> _shownTypes;

  _LegacyExpressionInfo(this._shownTypes);

  @override
  String toString() => 'LegacyExpressionInfo($_shownTypes)';
}

/// Implementation of [FlowAnalysis] that performs legacy (pre-null-safety) type
/// promotion.
class _LegacyTypePromotion<Node extends Object, Statement extends Node,
        Expression extends Object, Variable extends Object, Type extends Object>
    implements FlowAnalysis<Node, Statement, Expression, Variable, Type> {
  /// The [Operations], used to access types, check subtyping, and query
  /// variable types.
  final Operations<Variable, Type> _operations;

  /// Information about variable assignments computed during the previous
  /// compilation pass.
  final AssignedVariables<Node, Variable> _assignedVariables;

  /// The most recently visited expression for which a [_LegacyExpressionInfo]
  /// object exists, or `null` if no expression has been visited that has a
  /// corresponding [_LegacyExpressionInfo] object.
  Expression? _expressionWithInfo;

  /// If [_expressionWithInfo] is not `null`, the [_LegacyExpressionInfo] object
  /// corresponding to it.  Otherwise `null`.
  _LegacyExpressionInfo<Type>? _expressionInfo;

  /// The set of type promotions currently in effect.
  Map<int, Type> _knownTypes = {};

  /// Stack of [_LegacyContext] objects representing the statements and
  /// expressions that are currently being visited.
  final List<_LegacyContext<Type>> _contextStack = [];

  /// Stack for tracking writes occurring on the LHS of a binary "and" (`&&`)
  /// operation.  Whenever we visit a write, we update the top entry in this
  /// stack; whenever we begin to visit the LHS of a binary "and", we push
  /// a fresh empty entry onto this stack; accordingly, upon reaching the RHS of
  /// the binary "and", the top entry of the stack contains the set of variables
  /// written to during the LHS of the "and".
  final List<Set<int>> _writeStackForAnd = [{}];

  final PromotionKeyStore<Variable> _promotionKeyStore;

  /// Stack of types of scrutinee expressions of switch statements enclosing the
  /// point currently being analyzed.
  final List<Type> _switchStatementTypeStack = [];

  _LegacyTypePromotion(this._operations, this._assignedVariables)
      : _promotionKeyStore = _assignedVariables.promotionKeyStore;

  @override
  bool get isReachable => true;

  @override
  TypeOperations<Type> get operations => _operations;

  @override
  void asExpression_end(Expression subExpression, Type type) {}

  @override
  void assert_afterCondition(Expression condition) {}

  @override
  void assert_begin() {}

  @override
  void assert_end() {}

  @override
  assignedVariablePattern(Node node, Variable variable, Type writtenType) {}

  @override
  void assignMatchedPatternVariable(Variable variable, int promotionKey) {}

  @override
  void booleanLiteral(Expression expression, bool value) {}

  @override
  void conditional_conditionBegin() {}

  @override
  void conditional_elseBegin(Expression thenExpression) {
    _knownTypes = _contextStack.removeLast()._previousKnownTypes;
  }

  @override
  void conditional_end(
      Expression conditionalExpression, Expression elseExpression) {}

  @override
  void conditional_thenBegin(Expression condition, Node conditionalExpression) {
    _conditionalOrIf_thenBegin(condition, conditionalExpression);
  }

  @override
  void constantPattern_end(Expression expression, Type type,
      {required bool patternsEnabled}) {}

  @override
  void copyPromotionData(
      {required int sourceKey, required int destinationKey}) {}

  @override
  void declare(Variable variable, Type staticType,
      {required bool initialized, bool skipDuplicateCheck = false}) {}

  @override
  int declaredVariablePattern(
          {required Type matchedType,
          required Type staticType,
          Expression? initializerExpression,
          bool isFinal = false,
          bool isLate = false,
          required bool isImplicitlyTyped}) =>
      0;

  @override
  void doStatement_bodyBegin(Statement doStatement) {}

  @override
  void doStatement_conditionBegin() {}

  @override
  void doStatement_end(Expression condition) {}

  @override
  EqualityInfo<Type>? equalityOperand_end(Expression operand, Type type) =>
      null;

  @override
  void equalityOperation_end(Expression wholeExpression,
      EqualityInfo<Type>? leftOperandInfo, EqualityInfo<Type>? rightOperandInfo,
      {bool notEqual = false}) {}

  @override
  void equalityRelationalPattern_end(Expression operand, Type operandType,
      {bool notEqual = false}) {}

  @override
  ExpressionInfo<Type>? expressionInfoForTesting(Expression target) {
    throw new StateError(
        'expressionInfoForTesting requires null-aware flow analysis');
  }

  @override
  void finish() {
    assert(_contextStack.isEmpty, 'Unexpected stack: $_contextStack');
    assert(_switchStatementTypeStack.isEmpty);
  }

  @override
  void for_bodyBegin(Statement? node, Expression? condition) {}

  @override
  void for_conditionBegin(Node node) {}

  @override
  void for_end() {}

  @override
  void for_updaterBegin() {}

  @override
  void forEach_bodyBegin(Node node) {}

  @override
  void forEach_end() {}

  @override
  void forwardExpression(Expression newExpression, Expression oldExpression) {
    if (identical(_expressionWithInfo, oldExpression)) {
      _expressionWithInfo = newExpression;
    }
  }

  @override
  void functionExpression_begin(Node node) {}

  @override
  void functionExpression_end() {}

  @override
  Type getMatchedValueType() {
    // Patterns are not permitted in pre-null-safe code, however switch cases
    // are treated as constant patterns by the shared analysis logic, so we need
    // to support this method.  The "matched value type" is simply the static
    // type of the innermost enclosing switch statement's scrutinee.
    return _switchStatementTypeStack.last;
  }

  @override
  void handleBreak(Statement? target) {}

  @override
  void handleContinue(Statement? target) {}

  @override
  void handleExit() {}

  @override
  void ifCaseStatement_afterExpression(
      Expression scrutinee, Type scrutineeType) {}

  @override
  void ifCaseStatement_begin() {}

  @override
  void ifCaseStatement_thenBegin(Expression? guard) {}

  @override
  void ifNullExpression_end() {}

  @override
  void ifNullExpression_rightBegin(
      Expression leftHandSide, Type leftHandSideType) {}

  @override
  void ifStatement_conditionBegin() {}

  @override
  void ifStatement_elseBegin() {
    _knownTypes = _contextStack.removeLast()._previousKnownTypes;
  }

  @override
  void ifStatement_end(bool hasElse) {
    if (!hasElse) {
      _knownTypes = _contextStack.removeLast()._previousKnownTypes;
    }
  }

  @override
  void ifStatement_thenBegin(Expression? condition, Node ifNode) {
    _conditionalOrIf_thenBegin(condition, ifNode);
  }

  @override
  void initialize(
      Variable variable, Type matchedType, Expression? initializerExpression,
      {required bool isFinal,
      required bool isLate,
      required bool isImplicitlyTyped}) {}

  @override
  bool isAssigned(Variable variable) {
    return true;
  }

  @override
  void isExpression_end(Expression isExpression, Expression subExpression,
      bool isNot, Type type) {
    _LegacyExpressionInfo<Type>? expressionInfo =
        _getExpressionInfo(subExpression);
    if (!isNot && expressionInfo is _LegacyVariableReadInfo<Variable, Type>) {
      Variable variable = expressionInfo._variable;
      int variableKey = expressionInfo._variableKey;
      Type currentType =
          _knownTypes[variableKey] ?? _operations.variableType(variable);
      Type? promotedType = _operations.tryPromoteToType(type, currentType);
      if (promotedType != null &&
          !_operations.isSameType(currentType, promotedType)) {
        _storeExpressionInfo(isExpression,
            new _LegacyExpressionInfo<Type>({variableKey: promotedType}));
      }
    }
  }

  @override
  bool isUnassigned(Variable variable) {
    return false;
  }

  @override
  void labeledStatement_begin(Node node) {}

  @override
  void labeledStatement_end() {}

  @override
  void lateInitializer_begin(Node node) {}

  @override
  void lateInitializer_end() {}

  @override
  void logicalBinaryOp_begin() {
    _writeStackForAnd.add({});
  }

  @override
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {required bool isAnd}) {
    if (!isAnd) return;
    _LegacyBinaryAndContext<Type> context =
        _contextStack.removeLast() as _LegacyBinaryAndContext<Type>;
    _knownTypes = context._previousKnownTypes;
    AssignedVariablesNodeInfo assignedVariablesInfoForRhs =
        context._assignedVariablesInfoForRhs;
    Map<int, Type> lhsShownTypes = context._lhsShownTypes;
    Map<int, Type> rhsShownTypes =
        _getExpressionInfo(rightOperand)?._shownTypes ?? {};
    // A logical boolean expression b of the form `e1 && e2` shows that a local
    // variable v has type T if both of the following conditions hold:
    // - Either e1 shows that v has type T or e2 shows that v has type T.
    // - v is not mutated in e2 or within a function other than the one where v
    //   is declared.
    // We don't have to worry about whether v is mutated within a function other
    // than the one where v is declared, because that is checked every time we
    // evaluate whether v is known to have type T.  So we just have to combine
    // together the things shown by e1 and e2, and discard anything mutated in
    // e2.
    //
    // Note, however, that there is an ambiguity that isn't addressed by the
    // spec: what happens if e1 shows that v has type T1 and e2 shows that v has
    // type T2?  The de facto behavior we have had for a long time is to combine
    // the two types in the same way we would combine it if c were first
    // promoted to T1 and then had a successful `is T2` check.
    Map<int, Type> newShownTypes = {};
    for (MapEntry<int, Type> entry in lhsShownTypes.entries) {
      if (assignedVariablesInfoForRhs.written.contains(entry.key)) continue;
      newShownTypes[entry.key] = entry.value;
    }
    for (MapEntry<int, Type> entry in rhsShownTypes.entries) {
      if (assignedVariablesInfoForRhs.written.contains(entry.key)) continue;
      Type? previouslyShownType = newShownTypes[entry.key];
      if (previouslyShownType == null) {
        newShownTypes[entry.key] = entry.value;
      } else {
        Type? newShownType =
            _operations.tryPromoteToType(entry.value, previouslyShownType);
        if (newShownType != null &&
            !_operations.isSameType(previouslyShownType, newShownType)) {
          newShownTypes[entry.key] = newShownType;
        }
      }
    }
    _storeExpressionInfo(
        wholeExpression, new _LegacyExpressionInfo<Type>(newShownTypes));
  }

  @override
  void logicalBinaryOp_rightBegin(Expression leftOperand, Node wholeExpression,
      {required bool isAnd}) {
    Set<int> variablesWrittenOnLhs = _writeStackForAnd.removeLast();
    _writeStackForAnd.last.addAll(variablesWrittenOnLhs);
    if (!isAnd) return;
    AssignedVariablesNodeInfo info =
        _assignedVariables.getInfoForNode(wholeExpression);
    Map<int, Type> lhsShownTypes =
        _getExpressionInfo(leftOperand)?._shownTypes ?? {};
    _contextStack.add(
        new _LegacyBinaryAndContext<Type>(_knownTypes, lhsShownTypes, info));
    Map<int, Type>? newKnownTypes;
    for (MapEntry<int, Type> entry in lhsShownTypes.entries) {
      // Given a statement of the form `e1 && e2`, if e1 shows that a
      // local variable v has type T, then the type of v is known to be T in
      // e2, unless any of the following are true:
      // - v is potentially mutated in e1,
      if (variablesWrittenOnLhs.contains(entry.key)) continue;
      // - v is potentially mutated in e2,
      if (info.written.contains(entry.key)) continue;
      // - v is potentially mutated within a function other than the one where
      //   v is declared, or
      if (_assignedVariables.anywhere.captured.contains(entry.key)) {
        continue;
      }
      // - v is accessed by a function defined in e2 and v is potentially
      //   mutated anywhere in the scope of v.
      if (info.readCaptured.contains(entry.key) &&
          _assignedVariables.anywhere.written.contains(entry.key)) {
        continue;
      }
      (newKnownTypes ??= new Map<int, Type>.of(_knownTypes))[entry.key] =
          entry.value;
    }
    if (newKnownTypes != null) _knownTypes = newKnownTypes;
  }

  @override
  void logicalNot_end(Expression notExpression, Expression operand) {}

  @override
  void logicalOrPattern_afterLhs() {}

  @override
  void logicalOrPattern_begin() {}

  @override
  void logicalOrPattern_end() {}

  @override
  void nonEqualityRelationalPattern_end() {}

  @override
  void nonNullAssert_end(Expression operand) {}

  @override
  void nullAwareAccess_end() {}

  @override
  void nullAwareAccess_rightBegin(Expression? target, Type targetType) {}

  @override
  bool nullCheckOrAssertPattern_begin({required bool isAssert}) => false;

  @override
  void nullCheckOrAssertPattern_end() {}

  @override
  void nullLiteral(Expression expression) {}

  @override
  void parenthesizedExpression(
      Expression outerExpression, Expression innerExpression) {
    forwardExpression(outerExpression, innerExpression);
  }

  @override
  void patternAssignment_afterRhs(Expression rhs, Type rhsType) {}

  @override
  void patternAssignment_end() {}

  @override
  void patternForIn_afterExpression(Type elementType) {}

  @override
  void patternForIn_end() {}

  @override
  void patternVariableDeclaration_afterInitializer(
      Expression initializer, Type initializerType) {}

  @override
  void patternVariableDeclaration_end() {}

  @override
  void popSubpattern() {}

  @override
  Type? promotedPropertyType(Expression? target, String propertyName,
          Object? propertyMember, Type staticType) =>
      null;

  @override
  Type? promotedType(Variable variable) {
    int variableKey = _promotionKeyStore.keyForVariable(variable);
    return _knownTypes[variableKey];
  }

  @override
  bool promoteForPattern(
          {required Type matchedType,
          required Type knownType,
          bool matchFailsIfWrongType = true,
          bool matchMayFailEvenIfCorrectType = false}) =>
      false;

  @override
  Type? propertyGet(Expression? wholeExpression, Expression target,
          String propertyName, Object? propertyMember, Type staticType) =>
      null;

  @override
  void pushSubpattern(Type matchedType) {}

  @override
  SsaNode<Type>? ssaNodeForTesting(Variable variable) {
    throw new StateError('ssaNodeForTesting requires null-aware flow analysis');
  }

  @override
  bool switchStatement_afterCase() => true;

  @override
  void switchStatement_beginAlternative() {}

  @override
  void switchStatement_beginAlternatives() {}

  @override
  bool switchStatement_end(bool isExhaustive) {
    _switchStatementTypeStack.removeLast();
    return false;
  }

  @override
  void switchStatement_endAlternative(
      Expression? guard, Map<String, Variable> variables) {}

  @override
  PatternVariableInfo<Variable> switchStatement_endAlternatives(Statement? node,
          {required bool hasLabels}) =>
      new PatternVariableInfo();

  @override
  void switchStatement_expressionEnd(
      Statement? switchStatement, Expression scrutinee, Type scrutineeType) {
    _switchStatementTypeStack.add(scrutineeType);
  }

  @override
  void thisOrSuper(Expression expression, Type staticType) {}

  @override
  Type? thisOrSuperPropertyGet(Expression expression, String propertyName,
          Object? propertyMember, Type staticType) =>
      null;

  @override
  void tryCatchStatement_bodyBegin() {}

  @override
  void tryCatchStatement_bodyEnd(Node body) {}

  @override
  void tryCatchStatement_catchBegin(
      Variable? exceptionVariable, Variable? stackTraceVariable) {}

  @override
  void tryCatchStatement_catchEnd() {}

  @override
  void tryCatchStatement_end() {}

  @override
  void tryFinallyStatement_bodyBegin() {}

  @override
  void tryFinallyStatement_end() {}

  @override
  void tryFinallyStatement_finallyBegin(Node body) {}

  @override
  Type? variableRead(Expression expression, Variable variable) {
    int variableKey = _promotionKeyStore.keyForVariable(variable);
    _storeExpressionInfo(expression,
        new _LegacyVariableReadInfo<Variable, Type>(variable, variableKey));
    return _knownTypes[variableKey];
  }

  @override
  void whileStatement_bodyBegin(
      Statement whileStatement, Expression condition) {}

  @override
  void whileStatement_conditionBegin(Node node) {}

  @override
  void whileStatement_end() {}

  @override
  Map<Type, NonPromotionReason> Function() whyNotPromoted(Expression target) {
    return () => {};
  }

  @override
  Map<Type, NonPromotionReason> Function() whyNotPromotedImplicitThis(
      Type staticType) {
    return () => {};
  }

  @override
  void write(Node node, Variable variable, Type writtenType,
      Expression? writtenExpression) {
    int variableKey = _promotionKeyStore.keyForVariable(variable);
    _writeStackForAnd.last.add(variableKey);
  }

  void _conditionalOrIf_thenBegin(Expression? condition, Node node) {
    _contextStack.add(new _LegacyContext<Type>(_knownTypes));
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node);
    Map<int, Type>? newKnownTypes;
    _LegacyExpressionInfo<Type>? expressionInfo = _getExpressionInfo(condition);
    if (expressionInfo != null) {
      for (MapEntry<int, Type> entry in expressionInfo._shownTypes.entries) {
        // Given an expression of the form n1?n2:n3 or a statement of the form
        // `if (n1) n2 else n3`, if n1 shows that a local variable v has type T,
        // then the type of v is known to be T in n2, unless any of the
        // following are true:
        // - v is potentially mutated in n2,
        if (info.written.contains(entry.key)) continue;
        // - v is potentially mutated within a function other than the one where
        //   v is declared, or
        if (_assignedVariables.anywhere.captured.contains(entry.key)) {
          continue;
        }
        // - v is accessed by a function defined in n2 and v is potentially
        //   mutated anywhere in the scope of v.
        if (info.readCaptured.contains(entry.key) &&
            _assignedVariables.anywhere.written.contains(entry.key)) {
          continue;
        }
        (newKnownTypes ??= new Map<int, Type>.of(_knownTypes))[entry.key] =
            entry.value;
      }
      if (newKnownTypes != null) _knownTypes = newKnownTypes;
    }
  }

  @override
  void _dumpState() {
    print('  knownTypes: $_knownTypes');
    print('  expressionWithInfo: $_expressionWithInfo');
    print('  expressionInfo: $_expressionInfo');
    print('  contextStack:');
    for (_LegacyContext<Type> stackEntry in _contextStack.reversed) {
      print('    $stackEntry');
    }
    print('  writeStackForAnd:');
    for (Set<int> stackEntry in _writeStackForAnd.reversed) {
      print('    $stackEntry');
    }
  }

  /// Gets the [_LegacyExpressionInfo] associated with [expression], if any;
  /// otherwise returns `null`.
  _LegacyExpressionInfo<Type>? _getExpressionInfo(Expression? expression) {
    if (identical(expression, _expressionWithInfo)) {
      _LegacyExpressionInfo<Type>? expressionInfo = _expressionInfo;
      _expressionInfo = null;
      return expressionInfo;
    } else {
      return null;
    }
  }

  /// Associates [expressionInfo] with [expression] for use by a future call to
  /// [_getExpressionInfo].
  void _storeExpressionInfo(
      Expression expression, _LegacyExpressionInfo<Type> expressionInfo) {
    _expressionWithInfo = expression;
    _expressionInfo = expressionInfo;
  }
}

/// Data tracked by legacy type promotion about an expression that reads the
/// value of a local variable.
class _LegacyVariableReadInfo<Variable, Type>
    implements _LegacyExpressionInfo<Type> {
  /// The variable being referred to.
  final Variable _variable;

  /// The variable's corresponding key, as assigned by [PromotionKeyStore].
  final int _variableKey;

  _LegacyVariableReadInfo(this._variable, this._variableKey);

  @override
  Map<int, Type> get _shownTypes => {};

  @override
  String toString() => 'LegacyVariableReadInfo($_variable, $_shownTypes)';
}

/// Specialization of [_EqualityCheckResult] used as the return value for
/// [_FlowAnalysisImpl._equalityCheck] when no particular conclusion can be
/// drawn about the outcome of the outcome of the equality check.  In other
/// words, regardless of whether the equality check matches or not, the
/// resulting code path is reachable and no promotions can be done.
class _NoEqualityInformation extends _EqualityCheckResult {
  const _NoEqualityInformation() : super._();
}

/// [_FlowContext] representing a null aware access (`?.`).
class _NullAwareAccessContext<Type extends Object>
    extends _SimpleContext<Type> {
  _NullAwareAccessContext(super.previous);

  @override
  String get _debugType => '_NullAwareAccessContext';
}

/// [ExpressionInfo] representing a `null` literal.
class _NullInfo<Type extends Object> implements ExpressionInfo<Type> {
  @override
  final FlowModel<Type> after;

  _NullInfo(this.after);

  @override
  FlowModel<Type> get ifFalse => after;

  @override
  FlowModel<Type> get ifTrue => after;

  @override
  ExpressionInfo<Type> invert() {
    // This should only happen if `!null` is encountered.  That should never
    // happen for a properly typed program, but we need to handle it so we can
    // give reasonable errors for an improperly typed program.
    return this;
  }

  @override
  ExpressionInfo<Type>? rebaseForward(
          TypeOperations<Type> typeOperations, FlowModel<Type> base) =>
      null;
}

/// [_FlowContext] representing a logical-or pattern.
class _OrPatternContext<Type extends Object> extends _PatternContext<Type> {
  /// The value of [_FlowAnalysisImpl._unmatched] prior to entering the
  /// logical-or pattern.
  final FlowModel<Type> _previousUnmatched;

  /// If the left hand side of the logical-or pattern has already been
  /// traversed, the value of [_FlowAnalysisImpl._current] after traversing it.
  /// This represents the flow state under the assumption that the left hand
  /// side matched.
  FlowModel<Type>? _lhsMatched;

  _OrPatternContext(super.matchedValueInfo, super.matchedValuePromotionKey,
      super.matchedValueUnpromotedType, this._previousUnmatched);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['previousUnmatched'] = _previousUnmatched
    ..['lhsMatched'] = _lhsMatched;

  @override
  String get _debugType => '_OrPatternContext';
}

/// [_FlowContext] representing a pattern.
class _PatternContext<Type extends Object> extends _FlowContext {
  /// [ExpressionInfo] for the value being matched.
  final ExpressionInfo<Type>? _matchedValueInfo;

  /// Promotion key for the value being matched.
  final int _matchedValuePromotionKey;

  /// The type of the matched value, before any type promotion.
  final Type _matchedValueUnpromotedType;

  _PatternContext(this._matchedValueInfo, this._matchedValuePromotionKey,
      this._matchedValueUnpromotedType);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['matchedValueInfo'] = _matchedValueInfo
    ..['matchedValuePromotionKey'] = _matchedValuePromotionKey
    ..['matchedValueUnpromotedType'] = _matchedValueUnpromotedType;

  @override
  String get _debugType => '_PatternContext';

  /// Creates a reference to the matched value having type [matchedType].
  ReferenceWithType<Type> createReference(Type matchedType) =>
      new ReferenceWithType(_matchedValuePromotionKey, matchedType,
          isPromotable: true, isThisOrSuper: false);
}

/// [ReferenceWithType] object representing a property get.
class _PropertyReferenceWithType<Type extends Object>
    extends ReferenceWithType<Type> {
  /// The name of the property.
  final String propertyName;

  /// The field or property being accessed.  This matches a `propertyMember`
  /// value that was passed to either [FlowAnalysis.propertyGet] or
  /// [FlowAnalysis.thisOrSuperPropertyGet].
  final Object? propertyMember;

  _PropertyReferenceWithType(
      this.propertyName, this.propertyMember, super.promotionKey, super.type,
      {required super.isPromotable})
      : super(isThisOrSuper: false);

  @override
  String toString() =>
      '_PropertyReferenceWithType($propertyName, $propertyMember, '
      '$promotionKey, $type)';
}

/// [_FlowContext] representing a construct that can contain one or more
/// patterns, and thus has a scrutinee (for example a `switch` statement).
class _ScrutineeContext<Type extends Object> extends _FlowContext {
  final ReferenceWithType<Type>? previousScrutineeReference;

  final SsaNode<Type>? previousScrutineeSsaNode;

  _ScrutineeContext(
      {required this.previousScrutineeReference,
      required this.previousScrutineeSsaNode});

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['previousScrutineeReference'] = previousScrutineeReference
    ..['previousScrutineeSsaNode'] = previousScrutineeSsaNode;

  @override
  String get _debugType => '_ScrutineeContext';
}

/// [_FlowContext] representing a language construct for which flow analysis
/// must store a flow model state to be retrieved later, such as a `try`
/// statement, function expression, or "if-null" (`??`) expression.
abstract class _SimpleContext<Type extends Object> extends _FlowContext {
  /// The stored state.  For a `try` statement, this is the state from the
  /// beginning of the `try` block.  For a function expression, this is the
  /// state at the point the function expression was created.
  final FlowModel<Type> _previous;

  _SimpleContext(this._previous);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['previous'] = _previous;
}

/// [_FlowContext] representing a language construct that can be targeted by
/// `break` or `continue` statements, and for which flow analysis must store a
/// flow model state to be retrieved later.  Examples include "for each" and
/// `switch` statements.
class _SimpleStatementContext<Type extends Object>
    extends _BranchTargetContext<Type> {
  /// The stored state.  For a "for each" statement, this is the state after
  /// evaluation of the iterable.  For a `switch` statement, this is the state
  /// after evaluation of the switch expression.
  final FlowModel<Type> _previous;

  _SimpleStatementContext(super.checkpoint, this._previous);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['previous'] = _previous;

  @override
  String get _debugType => '_SimpleStatementContext';
}

class _SwitchAlternativesContext<Variable extends Object, Type extends Object>
    extends _FlowContext {
  /// The enclosing [_SwitchStatementContext].
  final _SwitchStatementContext<Type> _switchStatementContext;

  /// Data structure accumulating information about the relationship among
  /// variables defined by patterns in the various alternatives.
  final PatternVariableInfo<Variable> _patternVariableInfo =
      new PatternVariableInfo();

  FlowModel<Type>? _combinedModel;

  _SwitchAlternativesContext(this._switchStatementContext);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['combinedModel'] = _combinedModel;

  @override
  String get _debugType => '_SwitchAlternativesContext';
}

/// [_FlowContext] representing a switch statement.
class _SwitchStatementContext<Type extends Object>
    extends _SimpleStatementContext<Type> {
  /// [EqualityInfo] for the value being matched.
  final EqualityInfo<Type> _matchedValueInfo;

  /// Flow state for the code path where no switch cases have matched yet.  If
  /// we think of a switch statement as syntactic sugar for a chain of if-else
  /// statements, this is the flow state on entry to the next `if`.
  FlowModel<Type> _unmatched;

  _SwitchStatementContext(
      super.checkpoint, super._previous, this._matchedValueInfo)
      : _unmatched = _previous;

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['matchedValueInfo'] = _matchedValueInfo
    ..['unmatched'] = _unmatched;

  @override
  String get _debugType => '_SwitchStatementContext';
}

/// [_FlowContext] representing the top level of a pattern syntax tree.
class _TopPatternContext<Type extends Object> extends _PatternContext<Type> {
  final FlowModel<Type>? _previousUnmatched;

  _TopPatternContext(super._matchedValueInfo, super._matchedValuePromotionKey,
      super._matchedValueUnpromotedType, this._previousUnmatched);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['previousUnmatched'] = _previousUnmatched;

  @override
  String get _debugType => '_TopPatternContext';
}

/// Specialization of [ExpressionInfo] for the case where the information we
/// have about the expression is trivial (meaning we know by construction that
/// the expression's [after], [ifTrue], and [ifFalse] models are all the same).
class _TrivialExpressionInfo<Type extends Object>
    implements ExpressionInfo<Type> {
  @override
  final FlowModel<Type> after;

  _TrivialExpressionInfo(this.after);

  @override
  FlowModel<Type> get ifFalse => after;

  @override
  FlowModel<Type> get ifTrue => after;

  @override
  ExpressionInfo<Type> invert() => this;

  @override
  ExpressionInfo<Type> rebaseForward(
          TypeOperations<Type> typeOperations, FlowModel<Type> base) =>
      new _TrivialExpressionInfo(base);
}

/// [_FlowContext] representing a try statement.
class _TryContext<Type extends Object> extends _SimpleContext<Type> {
  /// If the statement is a "try/catch" statement, the flow model representing
  /// program state at the top of any `catch` block.
  FlowModel<Type>? _beforeCatch;

  /// If the statement is a "try/catch" statement, the accumulated flow model
  /// representing program state after the `try` block or one of the `catch`
  /// blocks has finished executing.  If the statement is a "try/finally"
  /// statement, the flow model representing program state after the `try` block
  /// has finished executing.
  FlowModel<Type>? _afterBodyAndCatches;

  _TryContext(super.previous);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['beforeCatch'] = _beforeCatch
    ..['afterBodyAndCatches'] = '_afterBodyAndCatches';

  @override
  String get _debugType => '_TryContext';
}

class _TryFinallyContext<Type extends Object> extends _TryContext<Type> {
  /// The flow model representing program state at the top of the `finally`
  /// block.
  FlowModel<Type>? _beforeFinally;

  _TryFinallyContext(super.previous);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['beforeFinally'] = _beforeFinally;

  @override
  String get _debugType => '_TryFinallyContext';
}

/// [_FlowContext] representing a `while` loop (or a C-style `for` loop, which
/// is functionally similar).
class _WhileContext<Type extends Object> extends _BranchTargetContext<Type> {
  /// Flow models associated with the loop condition.
  final ExpressionInfo<Type> _conditionInfo;

  _WhileContext(super.checkpoint, this._conditionInfo);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['conditionInfo'] = _conditionInfo;

  @override
  String get _debugType => '_WhileContext';
}
