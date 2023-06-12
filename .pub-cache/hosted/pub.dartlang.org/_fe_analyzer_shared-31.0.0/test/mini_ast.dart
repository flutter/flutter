// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file implements the AST of a Dart-like language suitable for testing
/// flow analysis.  Callers may use the top level methods in this file to create
/// AST nodes and then feed them to [Harness.run] to run them through flow
/// analysis testing.
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:test/test.dart';

import 'mini_ir.dart';
import 'mini_types.dart';

Expression get nullLiteral => new _NullLiteral();

Expression get this_ => new _This();

Statement assert_(Expression condition, [Expression? message]) =>
    new _Assert(condition, message);

Statement block(List<Statement> statements) => new _Block(statements);

Expression booleanLiteral(bool value) => _BooleanLiteral(value);

Statement break_([LabeledStatement? target]) => new _Break(target);

SwitchCase case_(List<Statement> body, {bool hasLabel = false}) =>
    SwitchCase._(hasLabel, new _Block(body));

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable]'s assigned state to be [expectedAssignedState].
Statement checkAssigned(Var variable, bool expectedAssignedState) =>
    new _CheckAssigned(variable, expectedAssignedState);

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable] to be un-promoted.
Statement checkNotPromoted(Var variable) => new _CheckPromoted(variable, null);

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable]'s assigned state to be promoted to [expectedTypeStr].
Statement checkPromoted(Var variable, String? expectedTypeStr) =>
    new _CheckPromoted(variable, expectedTypeStr);

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers the current location's reachability state to be
/// [expectedReachable].
Statement checkReachable(bool expectedReachable) =>
    new _CheckReachable(expectedReachable);

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable]'s unassigned state to be [expectedUnassignedState].
Statement checkUnassigned(Var variable, bool expectedUnassignedState) =>
    new _CheckUnassigned(variable, expectedUnassignedState);

Statement continue_() => new _Continue();

Statement declare(Var variable, {required bool initialized}) =>
    new _Declare(variable, initialized ? expr(variable.type.type) : null);

Statement declareInitialized(Var variable, Expression initializer) =>
    new _Declare(variable, initializer);

Statement do_(List<Statement> body, Expression condition) =>
    _Do(block(body), condition);

/// Creates a pseudo-expression having type [typeStr] that otherwise has no
/// effect on flow analysis.
Expression expr(String typeStr) =>
    new _PlaceholderExpression(new Type(typeStr));

/// Creates a conventional `for` statement.  Optional boolean [forCollection]
/// indicates that this `for` statement is actually a collection element, so
/// `null` should be passed to [for_bodyBegin].
Statement for_(Statement? initializer, Expression? condition,
        Expression? updater, List<Statement> body,
        {bool forCollection = false}) =>
    new _For(initializer, condition, updater, block(body), forCollection);

/// Creates a "for each" statement where the identifier being assigned to by the
/// iteration is not a local variable.
///
/// This models code like:
///     var x; // Top level variable
///     f(Iterable iterable) {
///       for (x in iterable) { ... }
///     }
Statement forEachWithNonVariable(Expression iterable, List<Statement> body) =>
    new _ForEach(null, iterable, block(body), false);

/// Creates a "for each" statement where the identifier being assigned to by the
/// iteration is a variable that is being declared by the "for each" statement.
///
/// This models code like:
///     f(Iterable iterable) {
///       for (var x in iterable) { ... }
///     }
Statement forEachWithVariableDecl(
    Var variable, Expression iterable, List<Statement> body) {
  // ignore: unnecessary_null_comparison
  assert(variable != null);
  return new _ForEach(variable, iterable, block(body), true);
}

/// Creates a "for each" statement where the identifier being assigned to by the
/// iteration is a local variable that is declared elsewhere in the function.
///
/// This models code like:
///     f(Iterable iterable) {
///       var x;
///       for (x in iterable) { ... }
///     }
Statement forEachWithVariableSet(
    Var variable, Expression iterable, List<Statement> body) {
  // ignore: unnecessary_null_comparison
  assert(variable != null);
  return new _ForEach(variable, iterable, block(body), false);
}

/// Creates a [Statement] that, when analyzed, will cause [callback] to be
/// passed an [SsaNodeHarness] allowing the test to examine the values of
/// variables' SSA nodes.
Statement getSsaNodes(void Function(SsaNodeHarness) callback) =>
    new _GetSsaNodes(callback);

Statement if_(Expression condition, List<Statement> ifTrue,
        [List<Statement>? ifFalse]) =>
    new _If(condition, block(ifTrue), ifFalse == null ? null : block(ifFalse));

Statement implicitThis_whyNotPromoted(String staticType,
        void Function(Map<Type, NonPromotionReason>) callback) =>
    new _WhyNotPromoted_ImplicitThis(Type(staticType), callback);

Statement labeled(Statement Function(LabeledStatement) callback) {
  var labeledStatement = LabeledStatement._();
  labeledStatement._body = callback(labeledStatement);
  return labeledStatement;
}

Statement localFunction(List<Statement> body) => _LocalFunction(block(body));

Statement return_() => new _Return();

Statement switch_(Expression expression, List<SwitchCase> cases,
        {required bool isExhaustive}) =>
    new _Switch(expression, cases, isExhaustive);

Expression thisOrSuperPropertyGet(String name) =>
    new _ThisOrSuperPropertyGet(name);

Expression throw_(Expression operand) => new _Throw(operand);

TryBuilder try_(List<Statement> body) =>
    new _TryStatement(block(body), [], null);

Statement while_(Expression condition, List<Statement> body) =>
    new _While(condition, block(body));

/// Representation of an expression in the pseudo-Dart language used for flow
/// analysis testing.  Methods in this class may be used to create more complex
/// expressions based on this one.
abstract class Expression extends Node {
  Expression() : super._();

  /// If `this` is an expression `x`, creates the expression `x!`.
  Expression get nonNullAssert => new _NonNullAssert(this);

  /// If `this` is an expression `x`, creates the expression `!x`.
  Expression get not => new _Not(this);

  /// If `this` is an expression `x`, creates the expression `(x)`.
  Expression get parenthesized => new _ParenthesizedExpression(this);

  /// If `this` is an expression `x`, creates the statement `x;`.
  Statement get stmt => new _ExpressionStatement(this);

  /// If `this` is an expression `x`, creates the expression `x && other`.
  Expression and(Expression other) => new _Logical(this, other, isAnd: true);

  /// If `this` is an expression `x`, creates the expression `x as typeStr`.
  Expression as_(String typeStr) => new _As(this, Type(typeStr));

  /// If `this` is an expression `x`, creates the expression
  /// `x ? ifTrue : ifFalse`.
  Expression conditional(Expression ifTrue, Expression ifFalse) =>
      new _Conditional(this, ifTrue, ifFalse);

  /// If `this` is an expression `x`, creates the expression `x == other`.
  Expression eq(Expression other) => new _Equal(this, other, false);

  /// Creates an [Expression] that, when analyzed, will behave the same as
  /// `this`, but after visiting it, will cause [callback] to be passed the
  /// [ExpressionInfo] associated with it.  If the expression has no flow
  /// analysis information associated with it, `null` will be passed to
  /// [callback].
  Expression getExpressionInfo(
          void Function(ExpressionInfo<Var, Type>?) callback) =>
      new _GetExpressionInfo(this, callback);

  /// If `this` is an expression `x`, creates the expression `x ?? other`.
  Expression ifNull(Expression other) => new _IfNull(this, other);

  /// If `this` is an expression `x`, creates the expression `x is typeStr`.
  ///
  /// With [isInverted] set to `true`, creates the expression `x is! typeStr`.
  Expression is_(String typeStr, {bool isInverted = false}) =>
      new _Is(this, Type(typeStr), isInverted);

  /// If `this` is an expression `x`, creates the expression `x is! typeStr`.
  Expression isNot(String typeStr) => _Is(this, Type(typeStr), true);

  /// If `this` is an expression `x`, creates the expression `x != other`.
  Expression notEq(Expression other) => _Equal(this, other, true);

  /// If `this` is an expression `x`, creates the expression `x?.other`.
  ///
  /// Note that in the real Dart language, the RHS of a null aware access isn't
  /// strictly speaking an expression.  However for flow analysis it suffices to
  /// model it as an expression.
  Expression nullAwareAccess(Expression other, {bool isCascaded = false}) =>
      _NullAwareAccess(this, other, isCascaded);

  /// If `this` is an expression `x`, creates the expression `x || other`.
  Expression or(Expression other) => new _Logical(this, other, isAnd: false);

  /// If `this` is an expression `x`, creates the L-value `x.name`.
  LValue property(String name) => new _Property(this, name);

  /// If `this` is an expression `x`, creates a pseudo-expression that models
  /// evaluation of `x` followed by execution of [stmt].  This can be used to
  /// test that flow analysis is in the correct state after an expression is
  /// visited.
  Expression thenStmt(Statement stmt) =>
      new _WrappedExpression(null, this, stmt);

  /// Creates an [Expression] that, when analyzed, will behave the same as
  /// `this`, but after visiting it, will cause [callback] to be passed the
  /// non-promotion info associated with it.  If the expression has no
  /// non-promotion info, an empty map will be passed to [callback].
  Expression whyNotPromoted(
          void Function(Map<Type, NonPromotionReason>) callback) =>
      new _WhyNotPromoted(this, callback);

  void _preVisit(AssignedVariables<Node, Var> assignedVariables);

  Type _visit(Harness h, Type context);
}

/// Test harness for creating flow analysis tests.  This class implements all
/// the [TypeOperations] needed by flow analysis, as well as other methods
/// needed for testing.
class Harness extends TypeOperations<Var, Type> {
  static const Map<String, bool> _coreSubtypes = const {
    'bool <: int': false,
    'bool <: Object': true,
    'double <: Object': true,
    'double <: num': true,
    'double <: num?': true,
    'double <: int': false,
    'double <: int?': false,
    'int <: double': false,
    'int <: int?': true,
    'int <: Iterable': false,
    'int <: List': false,
    'int <: Null': false,
    'int <: num': true,
    'int <: num?': true,
    'int <: num*': true,
    'int <: Never?': false,
    'int <: Object': true,
    'int <: Object?': true,
    'int <: String': false,
    'int? <: int': false,
    'int? <: Null': false,
    'int? <: num': false,
    'int? <: num?': true,
    'int? <: Object': false,
    'int? <: Object?': true,
    'Never <: Object?': true,
    'Null <: int': false,
    'Null <: Object': false,
    'Null <: Object?': true,
    'num <: int': false,
    'num <: Iterable': false,
    'num <: List': false,
    'num <: num?': true,
    'num <: num*': true,
    'num <: Object': true,
    'num <: Object?': true,
    'num? <: int?': false,
    'num? <: num': false,
    'num? <: num*': true,
    'num? <: Object': false,
    'num? <: Object?': true,
    'num* <: num': true,
    'num* <: num?': true,
    'num* <: Object': true,
    'num* <: Object?': true,
    'Iterable <: int': false,
    'Iterable <: num': false,
    'Iterable <: Object': true,
    'Iterable <: Object?': true,
    'List <: int': false,
    'List <: Iterable': true,
    'List <: Object': true,
    'Never <: int': true,
    'Never <: int?': true,
    'Never <: Null': true,
    'Never? <: int': false,
    'Never? <: int?': true,
    'Never? <: num?': true,
    'Never? <: Object?': true,
    'Null <: int?': true,
    'Object <: int': false,
    'Object <: int?': false,
    'Object <: List': false,
    'Object <: Null': false,
    'Object <: num': false,
    'Object <: num?': false,
    'Object <: Object?': true,
    'Object <: String': false,
    'Object? <: Object': false,
    'Object? <: int': false,
    'Object? <: int?': false,
    'Object? <: Null': false,
    'String <: int': false,
    'String <: int?': false,
    'String <: num?': false,
    'String <: Object': true,
    'String <: Object?': true,
  };

  static final Map<String, Type> _coreFactors = {
    'Object? - int': Type('Object?'),
    'Object? - int?': Type('Object'),
    'Object? - Never': Type('Object?'),
    'Object? - Null': Type('Object'),
    'Object? - num?': Type('Object'),
    'Object? - Object?': Type('Never?'),
    'Object? - String': Type('Object?'),
    'Object - bool': Type('Object'),
    'Object - int': Type('Object'),
    'Object - String': Type('Object'),
    'int - Object': Type('Never'),
    'int - String': Type('int'),
    'int - int': Type('Never'),
    'int - int?': Type('Never'),
    'int? - int': Type('Never?'),
    'int? - int?': Type('Never'),
    'int? - String': Type('int?'),
    'Null - int': Type('Null'),
    'num - int': Type('num'),
    'num? - num': Type('Never?'),
    'num? - int': Type('num?'),
    'num? - int?': Type('num'),
    'num? - Object': Type('Never?'),
    'num? - String': Type('num?'),
    'Object - int?': Type('Object'),
    'Object - num': Type('Object'),
    'Object - num?': Type('Object'),
    'Object - num*': Type('Object'),
    'Object - Iterable': Type('Object'),
    'Object? - Object': Type('Never?'),
    'Object? - Iterable': Type('Object?'),
    'Object? - num': Type('Object?'),
    'Iterable - List': Type('Iterable'),
    'num* - Object': Type('Never'),
  };

  late final FlowAnalysis<Node, Statement, Expression, Var, Type> _flow;

  final bool legacy;

  final Type? thisType;

  final Map<String, bool> _subtypes = Map.of(_coreSubtypes);

  final Map<String, Type> _factorResults = Map.of(_coreFactors);

  final Map<String, Type> _members = {};

  Map<String, Map<String, String>> _promotionExceptions = {};

  late final _typeAnalyzer = _MiniAstTypeAnalyzer(this);

  /// Indicates whether initializers of implicitly typed variables should be
  /// accounted for by SSA analysis.  (In an ideal world, they always would be,
  /// but due to https://github.com/dart-lang/language/issues/1785, they weren't
  /// always, and we need to be able to replicate the old behavior when
  /// analyzing old language versions).
  final bool respectImplicitlyTypedVarInitializers;

  Harness(
      {this.legacy = false,
      String? thisType,
      this.respectImplicitlyTypedVarInitializers = true})
      : thisType = thisType == null ? null : Type(thisType);

  MiniIrBuilder get _irBuilder => _typeAnalyzer._irBuilder;

  /// Updates the harness so that when a [factor] query is invoked on types
  /// [from] and [what], [result] will be returned.
  void addFactor(String from, String what, String result) {
    var query = '$from - $what';
    _factorResults[query] = Type(result);
  }

  /// Updates the harness so that when member [memberName] is looked up on type
  /// [targetType], a member is found having the given [type].
  void addMember(String targetType, String memberName, String type) {
    var query = '$targetType.$memberName';
    _members[query] = Type(type);
  }

  void addPromotionException(String from, String to, String result) {
    (_promotionExceptions[from] ??= {})[to] = result;
  }

  /// Updates the harness so that when an [isSubtypeOf] query is invoked on
  /// types [leftType] and [rightType], [isSubtype] will be returned.
  void addSubtype(String leftType, String rightType, bool isSubtype) {
    var query = '$leftType <: $rightType';
    _subtypes[query] = isSubtype;
  }

  @override
  TypeClassification classifyType(Type type) {
    if (isSubtypeOf(type, Type('Object'))) {
      return TypeClassification.nonNullable;
    } else if (isSubtypeOf(type, Type('Null'))) {
      return TypeClassification.nullOrEquivalent;
    } else {
      return TypeClassification.potentiallyNullable;
    }
  }

  @override
  Type factor(Type from, Type what) {
    var query = '$from - $what';
    return _factorResults[query] ?? fail('Unknown factor query: $query');
  }

  /// Attempts to look up a member named [memberName] in the given [type].  If
  /// a member is found, returns its type.  Otherwise the test fails.
  Type getMember(Type type, String memberName) {
    var query = '$type.$memberName';
    return _members[query] ?? fail('Unknown member query: $query');
  }

  @override
  bool isNever(Type type) {
    return type.type == 'Never';
  }

  @override
  bool isSameType(Type type1, Type type2) {
    return type1.type == type2.type;
  }

  @override
  bool isSubtypeOf(Type leftType, Type rightType) {
    if (leftType.type == rightType.type) return true;
    var query = '$leftType <: $rightType';
    return _subtypes[query] ?? fail('Unknown subtype query: $query');
  }

  @override
  bool isTypeParameterType(Type type) => type is PromotedTypeVariableType;

  @override
  Type promoteToNonNull(Type type) {
    if (type.type.endsWith('?')) {
      return Type(type.type.substring(0, type.type.length - 1));
    } else if (type.type == 'Null') {
      return Type('Never');
    } else {
      return type;
    }
  }

  /// Runs the given [statements] through flow analysis, checking any assertions
  /// they contain.
  void run(List<Statement> statements) {
    var assignedVariables = AssignedVariables<Node, Var>();
    var b = block(statements);
    b._preVisit(assignedVariables);
    _flow = legacy
        ? FlowAnalysis<Node, Statement, Expression, Var, Type>.legacy(
            this, assignedVariables)
        : FlowAnalysis<Node, Statement, Expression, Var, Type>(
            this, assignedVariables,
            respectImplicitlyTypedVarInitializers:
                respectImplicitlyTypedVarInitializers);
    _typeAnalyzer.dispatchStatement(b);
    _typeAnalyzer.finish();
  }

  @override
  Type? tryPromoteToType(Type to, Type from) {
    var exception = (_promotionExceptions[from.type] ?? {})[to.type];
    if (exception != null) {
      return Type(exception);
    }
    if (isSubtypeOf(to, from)) {
      return to;
    } else {
      return null;
    }
  }

  @override
  Type variableType(Var variable) {
    return variable.type;
  }

  Type _getIteratedType(Type iterableType) {
    var typeStr = iterableType.type;
    if (typeStr.startsWith('List<') && typeStr.endsWith('>')) {
      return Type(typeStr.substring(5, typeStr.length - 1));
    } else {
      throw UnimplementedError('TODO(paulberry): getIteratedType($typeStr)');
    }
  }

  Type _lub(Type type1, Type type2) {
    if (isSameType(type1, type2)) {
      return type1;
    } else if (isSameType(promoteToNonNull(type1), type2)) {
      return type1;
    } else if (isSameType(promoteToNonNull(type2), type1)) {
      return type2;
    } else if (type1.type == 'Null' &&
        !isSameType(promoteToNonNull(type2), type2)) {
      // type2 is already nullable
      return type2;
    } else if (type2.type == 'Null' &&
        !isSameType(promoteToNonNull(type1), type1)) {
      // type1 is already nullable
      return type1;
    } else if (type1.type == 'Never') {
      return type2;
    } else if (type2.type == 'Never') {
      return type1;
    } else {
      throw UnimplementedError(
          'TODO(paulberry): least upper bound of $type1 and $type2');
    }
  }
}

class LabeledStatement extends Statement {
  late final Statement _body;

  LabeledStatement._() : super._();

  @override
  String toString() => 'labeled: $_body';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    _body._preVisit(assignedVariables);
  }

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeLabeledStatement(this, _body);
  }
}

/// Representation of an expression that can appear on the left hand side of an
/// assignment (or as the target of `++` or `--`).  Methods in this class may be
/// used to create more complex expressions based on this one.
abstract class LValue extends Expression {
  LValue._();

  /// Creates an expression representing a write to this L-value.
  Expression write(Expression? value) => new _Write(this, value);

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables,
      {_LValueDisposition disposition});

  void _visitWrite(Harness h, Expression assignmentExpression, Type writtenType,
      Expression? rhs);
}

/// Representation of an expression or statement in the pseudo-Dart language
/// used for flow analysis testing.
class Node {
  static int _nextId = 0;

  final int id;

  Node._() : id = _nextId++;

  String toString() => 'Node#$id';
}

/// Helper class allowing tests to examine the values of variables' SSA nodes.
class SsaNodeHarness {
  final FlowAnalysis<Node, Statement, Expression, Var, Type> _flow;

  SsaNodeHarness(this._flow);

  /// Gets the SSA node associated with [variable] at the current point in
  /// control flow, or `null` if the variable has been write captured.
  SsaNode<Var, Type>? operator [](Var variable) =>
      _flow.ssaNodeForTesting(variable);
}

/// Representation of a statement in the pseudo-Dart language used for flow
/// analysis testing.
abstract class Statement extends Node {
  Statement._() : super._();

  /// If `this` is a statement `x`, creates a pseudo-expression that models
  /// execution of `x` followed by evaluation of [expr].  This can be used to
  /// test that flow analysis is in the correct state before an expression is
  /// visited.
  Expression thenExpr(Expression expr) => _WrappedExpression(this, expr, null);

  void _preVisit(AssignedVariables<Node, Var> assignedVariables);

  void _visit(Harness h);
}

/// Representation of a single case clause in a switch statement.  Use [case_]
/// to create instances of this class.
class SwitchCase {
  final bool _hasLabel;
  final _Block _body;

  SwitchCase._(this._hasLabel, this._body);

  String toString() => [
        if (_hasLabel) '<label>:',
        'case <value>:',
        ..._body.statements
      ].join(' ');

  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    _body._preVisit(assignedVariables);
  }
}

abstract class TryBuilder {
  TryStatement catch_(
      {Var? exception, Var? stackTrace, required List<Statement> body});

  Statement finally_(List<Statement> statements);
}

abstract class TryStatement extends Statement implements TryBuilder {
  TryStatement._() : super._();
}

/// Representation of a local variable in the pseudo-Dart language used for flow
/// analysis testing.
class Var {
  final String name;
  final Type type;
  final bool isFinal;
  final bool isImplicitlyTyped;
  final bool isLate;

  Var(this.name, String typeStr,
      {this.isFinal = false,
      this.isImplicitlyTyped = false,
      this.isLate = false})
      : type = Type(typeStr);

  /// Creates an L-value representing a reference to this variable.
  LValue get expr => new _VariableReference(this, null);

  /// Creates an expression representing a read of this variable, which as a
  /// side effect will call the given callback with the returned promoted type.
  Expression readAndCheckPromotedType(void Function(Type?) callback) =>
      new _VariableReference(this, callback);

  @override
  String toString() => '$type $name';

  /// Creates an expression representing a write to this variable.
  Expression write(Expression? value) => expr.write(value);
}

class _As extends Expression {
  final Expression target;
  final Type type;

  _As(this.target, this.type);

  @override
  String toString() => '$target as $type';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    target._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    return h._typeAnalyzer.analyzeTypeCast(this, target, type);
  }
}

class _Assert extends Statement {
  final Expression condition;
  final Expression? message;

  _Assert(this.condition, this.message) : super._();

  @override
  String toString() =>
      'assert($condition${message == null ? '' : ', $message'});';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    condition._preVisit(assignedVariables);
    message?._preVisit(assignedVariables);
  }

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeAssertStatement(condition, message);
    h._irBuilder.apply('assert', 2);
  }
}

class _Block extends Statement {
  final List<Statement> statements;

  _Block(this.statements) : super._();

  @override
  String toString() =>
      statements.isEmpty ? '{}' : '{ ${statements.join(' ')} }';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    for (var statement in statements) {
      statement._preVisit(assignedVariables);
    }
  }

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeBlock(statements);
    h._irBuilder.apply('block', statements.length);
  }
}

class _BooleanLiteral extends Expression {
  final bool value;

  _BooleanLiteral(this.value);

  @override
  String toString() => '$value';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  Type _visit(Harness h, Type context) {
    var type = h._typeAnalyzer.analyzeBoolLiteral(this, value);
    h._irBuilder.atom('$value');
    return type;
  }
}

class _Break extends Statement {
  final LabeledStatement? target;

  _Break(this.target) : super._();

  @override
  String toString() => 'break;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeBreakStatement(target);
    h._irBuilder.apply('break', 0);
  }
}

/// Representation of a single catch clause in a try/catch statement.  Use
/// [catch_] to create instances of this class.
class _CatchClause {
  final Statement _body;
  final Var? _exception;
  final Var? _stackTrace;

  _CatchClause(this._body, this._exception, this._stackTrace);

  String toString() {
    String initialPart;
    if (_stackTrace != null) {
      initialPart = 'catch (${_exception!.name}, ${_stackTrace!.name})';
    } else if (_exception != null) {
      initialPart = 'catch (${_exception!.name})';
    } else {
      initialPart = 'on ...';
    }
    return '$initialPart $_body';
  }

  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    _body._preVisit(assignedVariables);
  }
}

class _CheckAssigned extends Statement {
  final Var variable;
  final bool expectedAssignedState;

  _CheckAssigned(this.variable, this.expectedAssignedState) : super._();

  @override
  String toString() {
    var verb = expectedAssignedState ? 'is' : 'is not';
    return 'check $variable $verb definitely assigned;';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(Harness h) {
    expect(h._flow.isAssigned(variable), expectedAssignedState);
    h._irBuilder.atom('null');
  }
}

class _CheckPromoted extends Statement {
  final Var variable;
  final String? expectedTypeStr;
  final StackTrace _creationTrace = StackTrace.current;

  _CheckPromoted(this.variable, this.expectedTypeStr) : super._();

  @override
  String toString() {
    var predicate = expectedTypeStr == null
        ? 'not promoted'
        : 'promoted to $expectedTypeStr';
    return 'check $variable $predicate;';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(Harness h) {
    var promotedType = h._flow.promotedType(variable);
    expect(promotedType?.type, expectedTypeStr, reason: '$_creationTrace');
    h._irBuilder.atom('null');
  }
}

class _CheckReachable extends Statement {
  final bool expectedReachable;

  _CheckReachable(this.expectedReachable) : super._();

  @override
  String toString() => 'check reachable;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(Harness h) {
    expect(h._flow.isReachable, expectedReachable);
    h._irBuilder.atom('null');
  }
}

class _CheckUnassigned extends Statement {
  final Var variable;
  final bool expectedUnassignedState;
  final StackTrace _creationTrace = StackTrace.current;

  _CheckUnassigned(this.variable, this.expectedUnassignedState) : super._();

  @override
  String toString() {
    var verb = expectedUnassignedState ? 'is' : 'is not';
    return 'check $variable $verb definitely unassigned;';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(Harness h) {
    expect(h._flow.isUnassigned(variable), expectedUnassignedState,
        reason: '$_creationTrace');
    h._irBuilder.atom('null');
  }
}

class _Conditional extends Expression {
  final Expression condition;
  final Expression ifTrue;
  final Expression ifFalse;

  _Conditional(this.condition, this.ifTrue, this.ifFalse);

  @override
  String toString() => '$condition ? $ifTrue : $ifFalse';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    condition._preVisit(assignedVariables);
    assignedVariables.beginNode();
    ifTrue._preVisit(assignedVariables);
    assignedVariables.endNode(this);
    ifFalse._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    var type = h._typeAnalyzer
        .analyzeConditionalExpression(this, condition, ifTrue, ifFalse);
    h._irBuilder.apply('if', 3);
    return type;
  }
}

class _Continue extends Statement {
  _Continue() : super._();

  @override
  String toString() => 'continue;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeContinueStatement();
    h._irBuilder.apply('continue', 0);
  }
}

class _Declare extends Statement {
  final Var variable;
  final Expression? initializer;

  _Declare(this.variable, this.initializer) : super._();

  @override
  String toString() {
    var latePart = variable.isLate ? 'late ' : '';
    var finalPart = variable.isFinal ? 'final ' : '';
    var initializerPart = initializer != null ? ' = $initializer' : '';
    return '$latePart$finalPart$variable${initializerPart};';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    initializer?._preVisit(assignedVariables);
  }

  @override
  void _visit(Harness h) {
    h._irBuilder.atom(variable.name);
    h._typeAnalyzer.analyzeVariableDeclaration(
        this, variable.type, variable, initializer,
        isFinal: variable.isFinal, isLate: variable.isLate);
    h._irBuilder.apply(
        ['declare', if (variable.isLate) 'late', if (variable.isFinal) 'final']
            .join('_'),
        2);
  }
}

class _Do extends Statement {
  final Statement body;
  final Expression condition;

  _Do(this.body, this.condition) : super._();

  @override
  String toString() => 'do $body while ($condition);';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    assignedVariables.beginNode();
    body._preVisit(assignedVariables);
    condition._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeDoLoop(this, body, condition);
    h._irBuilder.apply('do', 2);
  }
}

class _Equal extends Expression {
  final Expression lhs;
  final Expression rhs;
  final bool isInverted;

  _Equal(this.lhs, this.rhs, this.isInverted);

  @override
  String toString() => '$lhs ${isInverted ? '!=' : '=='} $rhs';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    lhs._preVisit(assignedVariables);
    rhs._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    var operatorName = isInverted ? '!=' : '==';
    var type =
        h._typeAnalyzer.analyzeBinaryExpression(this, lhs, operatorName, rhs);
    h._irBuilder.apply(operatorName, 2);
    return type;
  }
}

class _ExpressionStatement extends Statement {
  final Expression expr;

  _ExpressionStatement(this.expr) : super._();

  @override
  String toString() => '$expr;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    expr._preVisit(assignedVariables);
  }

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeExpressionStatement(expr);
  }
}

class _For extends Statement {
  final Statement? initializer;
  final Expression? condition;
  final Expression? updater;
  final Statement body;
  final bool forCollection;

  _For(this.initializer, this.condition, this.updater, this.body,
      this.forCollection)
      : super._();

  @override
  String toString() {
    var buffer = StringBuffer('for (');
    if (initializer == null) {
      buffer.write(';');
    } else {
      buffer.write(initializer);
    }
    if (condition == null) {
      buffer.write(';');
    } else {
      buffer.write(' $condition;');
    }
    if (updater != null) {
      buffer.write(' $updater');
    }
    buffer.write(') $body');
    return buffer.toString();
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    initializer?._preVisit(assignedVariables);
    assignedVariables.beginNode();
    condition?._preVisit(assignedVariables);
    body._preVisit(assignedVariables);
    updater?._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  void _visit(Harness h) {
    if (initializer != null) {
      h._typeAnalyzer.dispatchStatement(initializer!);
    } else {
      h._typeAnalyzer.handleNoInitializer();
    }
    h._flow.for_conditionBegin(this);
    if (condition != null) {
      h._typeAnalyzer.analyzeExpression(condition!);
    } else {
      h._typeAnalyzer.handleNoCondition();
    }
    h._flow.for_bodyBegin(forCollection ? null : this, condition);
    h._typeAnalyzer._visitLoopBody(this, body);
    h._flow.for_updaterBegin();
    if (updater != null) {
      h._typeAnalyzer.analyzeExpression(updater!);
    } else {
      h._typeAnalyzer.handleNoStatement();
    }
    h._flow.for_end();
    h._irBuilder.apply('for', 4);
  }
}

class _ForEach extends Statement {
  final Var? variable;
  final Expression iterable;
  final Statement body;
  final bool declaresVariable;

  _ForEach(this.variable, this.iterable, this.body, this.declaresVariable)
      : super._();

  @override
  String toString() {
    String declarationPart;
    if (variable == null) {
      declarationPart = '<identifier>';
    } else if (declaresVariable) {
      declarationPart = variable.toString();
    } else {
      declarationPart = variable!.name;
    }
    return 'for ($declarationPart in $iterable) $body';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    iterable._preVisit(assignedVariables);
    if (variable != null) {
      if (declaresVariable) {
        assignedVariables.declare(variable!);
      } else {
        assignedVariables.write(variable!);
      }
    }
    assignedVariables.beginNode();
    body._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  void _visit(Harness h) {
    var iteratedType =
        h._getIteratedType(h._typeAnalyzer.analyzeExpression(iterable));
    h._flow.forEach_bodyBegin(this);
    var variable = this.variable;
    if (variable != null && !declaresVariable) {
      h._flow.write(this, variable, iteratedType, null);
    }
    h._typeAnalyzer._visitLoopBody(this, body);
    h._flow.forEach_end();
    h._irBuilder.apply('forEach', 2);
  }
}

class _GetExpressionInfo extends Expression {
  final Expression target;

  final void Function(ExpressionInfo<Var, Type>?) callback;

  _GetExpressionInfo(this.target, this.callback);

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    target._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    var type = h._typeAnalyzer.analyzeExpression(target);
    h._flow.forwardExpression(this, target);
    callback(h._flow.expressionInfoForTesting(this));
    return type;
  }
}

class _GetSsaNodes extends Statement {
  final void Function(SsaNodeHarness) callback;

  _GetSsaNodes(this.callback) : super._();

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(Harness h) {
    callback(SsaNodeHarness(h._flow));
    h._irBuilder.atom('null');
  }
}

class _If extends Statement {
  final Expression condition;
  final Statement ifTrue;
  final Statement? ifFalse;

  _If(this.condition, this.ifTrue, this.ifFalse) : super._();

  @override
  String toString() =>
      'if ($condition) $ifTrue' + (ifFalse == null ? '' : 'else $ifFalse');

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    condition._preVisit(assignedVariables);
    assignedVariables.beginNode();
    ifTrue._preVisit(assignedVariables);
    assignedVariables.endNode(this);
    ifFalse?._preVisit(assignedVariables);
  }

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeIfStatement(this, condition, ifTrue, ifFalse);
    h._irBuilder.apply('if', 3);
  }
}

class _IfNull extends Expression {
  final Expression lhs;
  final Expression rhs;

  _IfNull(this.lhs, this.rhs);

  @override
  String toString() => '$lhs ?? $rhs';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    lhs._preVisit(assignedVariables);
    rhs._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    var type = h._typeAnalyzer.analyzeIfNullExpression(this, lhs, rhs);
    h._irBuilder.apply('ifNull', 2);
    return type;
  }
}

class _Is extends Expression {
  final Expression target;
  final Type type;
  final bool isInverted;

  _Is(this.target, this.type, this.isInverted);

  @override
  String toString() => '$target is${isInverted ? '!' : ''} $type';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    target._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    return h._typeAnalyzer
        .analyzeTypeTest(this, target, type, isInverted: isInverted);
  }
}

class _LocalFunction extends Statement {
  final Statement body;

  _LocalFunction(this.body) : super._();

  @override
  String toString() => '() $body';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    assignedVariables.beginNode();
    body._preVisit(assignedVariables);
    assignedVariables.endNode(this, isClosureOrLateVariableInitializer: true);
  }

  @override
  void _visit(Harness h) {
    h._flow.functionExpression_begin(this);
    h._typeAnalyzer.dispatchStatement(body);
    h._flow.functionExpression_end();
  }
}

class _Logical extends Expression {
  final Expression lhs;
  final Expression rhs;
  final bool isAnd;

  _Logical(this.lhs, this.rhs, {required this.isAnd});

  @override
  String toString() => '$lhs ${isAnd ? '&&' : '||'} $rhs';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    lhs._preVisit(assignedVariables);
    assignedVariables.beginNode();
    rhs._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  Type _visit(Harness h, Type context) {
    var operatorName = isAnd ? '&&' : '||';
    var type =
        h._typeAnalyzer.analyzeBinaryExpression(this, lhs, operatorName, rhs);
    h._irBuilder.apply(operatorName, 2);
    return type;
  }
}

/// Enum representing the different ways an [LValue] might be used.
enum _LValueDisposition {
  /// The [LValue] is being read from only, not written to.  This happens if it
  /// appears in a place where an ordinary expression is expected.
  read,

  /// The [LValue] is being written to only, not read from.  This happens if it
  /// appears on the left hand side of `=`.
  write,

  /// The [LValue] is being both read from and written to.  This happens if it
  /// appears on the left and side of `op=` (where `op` is some operator), or as
  /// the target of `++` or `--`.
  readWrite,
}

class _MiniAstTypeAnalyzer {
  final Harness _harness;

  Statement? _currentBreakTarget;

  Statement? _currentContinueTarget;

  final _irBuilder = MiniIrBuilder();

  late final Type boolType = Type('bool');

  late final Type neverType = Type('Never');

  late final Type nullType = Type('Null');

  late final Type unknownType = Type('?');

  _MiniAstTypeAnalyzer(this._harness);

  FlowAnalysis<Node, Statement, Expression, Var, Type> get flow =>
      _harness._flow;

  Type get thisType => _harness.thisType!;

  void analyzeAssertStatement(Expression condition, Expression? message) {
    flow.assert_begin();
    analyzeExpression(condition);
    flow.assert_afterCondition(condition);
    if (message != null) {
      analyzeExpression(message);
    } else {
      handleNoMessage();
    }
    flow.assert_end();
  }

  Type analyzeBinaryExpression(
      Expression node, Expression lhs, String operatorName, Expression rhs) {
    bool isEquals = false;
    bool isNot = false;
    bool isLogical = false;
    bool isAnd = false;
    switch (operatorName) {
      case '==':
        isEquals = true;
        break;
      case '!=':
        isEquals = true;
        isNot = true;
        operatorName = '==';
        break;
      case '&&':
        isLogical = true;
        isAnd = true;
        break;
      case '||':
        isLogical = true;
        break;
    }
    if (operatorName == '==') {
      isEquals = true;
    } else if (operatorName == '!=') {
      isEquals = true;
      isNot = true;
      operatorName = '==';
    }
    if (isLogical) {
      flow.logicalBinaryOp_begin();
    }
    var leftType = analyzeExpression(lhs);
    if (isEquals) {
      flow.equalityOp_rightBegin(lhs, leftType);
    } else if (isLogical) {
      flow.logicalBinaryOp_rightBegin(lhs, node, isAnd: isAnd);
    }
    var rightType = analyzeExpression(rhs);
    if (isEquals) {
      flow.equalityOp_end(node, rhs, rightType, notEqual: isNot);
    } else if (isLogical) {
      flow.logicalBinaryOp_end(node, rhs, isAnd: isAnd);
    }
    return boolType;
  }

  void analyzeBlock(Iterable<Statement> statements) {
    for (var statement in statements) {
      dispatchStatement(statement);
    }
  }

  Type analyzeBoolLiteral(Expression node, bool value) {
    flow.booleanLiteral(node, value);
    return boolType;
  }

  void analyzeBreakStatement(Statement? target) {
    flow.handleBreak(target ?? _currentBreakTarget!);
  }

  Type analyzeConditionalExpression(Expression node, Expression condition,
      Expression ifTrue, Expression ifFalse) {
    flow.conditional_conditionBegin();
    analyzeExpression(condition);
    flow.conditional_thenBegin(condition, node);
    var ifTrueType = analyzeExpression(ifTrue);
    flow.conditional_elseBegin(ifTrue);
    var ifFalseType = analyzeExpression(ifFalse);
    flow.conditional_end(node, ifFalse);
    return leastUpperBound(ifTrueType, ifFalseType);
  }

  void analyzeContinueStatement() {
    flow.handleContinue(_currentContinueTarget!);
  }

  void analyzeDoLoop(Statement node, Statement body, Expression condition) {
    flow.doStatement_bodyBegin(node);
    _visitLoopBody(node, body);
    flow.doStatement_conditionBegin();
    analyzeExpression(condition);
    flow.doStatement_end(condition);
  }

  Type analyzeExpression(Expression expression, [Type? context]) {
    // TODO(paulberry): make the [context] argument required.
    context ??= unknownType;
    return dispatchExpression(expression, context);
  }

  void analyzeExpressionStatement(Expression expression) {
    analyzeExpression(expression);
  }

  Type analyzeIfNullExpression(
      Expression node, Expression lhs, Expression rhs) {
    var leftType = analyzeExpression(lhs);
    flow.ifNullExpression_rightBegin(lhs, leftType);
    var rightType = analyzeExpression(rhs);
    flow.ifNullExpression_end();
    return leastUpperBound(
        flow.typeOperations.promoteToNonNull(leftType), rightType);
  }

  void analyzeIfStatement(Statement node, Expression condition,
      Statement ifTrue, Statement? ifFalse) {
    flow.ifStatement_conditionBegin();
    analyzeExpression(condition);
    flow.ifStatement_thenBegin(condition, node);
    dispatchStatement(ifTrue);
    if (ifFalse == null) {
      handleNoStatement();
      flow.ifStatement_end(false);
    } else {
      flow.ifStatement_elseBegin();
      dispatchStatement(ifFalse);
      flow.ifStatement_end(true);
    }
  }

  void analyzeLabeledStatement(Statement node, Statement body) {
    flow.labeledStatement_begin(node);
    dispatchStatement(body);
    flow.labeledStatement_end();
  }

  Type analyzeLogicalNot(Expression node, Expression expression) {
    analyzeExpression(expression);
    flow.logicalNot_end(node, expression);
    return boolType;
  }

  Type analyzeNonNullAssert(Expression node, Expression expression) {
    var type = analyzeExpression(expression);
    flow.nonNullAssert_end(expression);
    return flow.typeOperations.promoteToNonNull(type);
  }

  Type analyzeNullLiteral(Expression node) {
    flow.nullLiteral(node);
    return nullType;
  }

  Type analyzeParenthesizedExpression(Expression node, Expression expression) {
    var type = analyzeExpression(expression);
    flow.parenthesizedExpression(node, expression);
    return type;
  }

  Type analyzePropertyGet(
      Expression node, Expression receiver, String propertyName) {
    var receiverType = analyzeExpression(receiver);
    var type = _lookupMember(node, receiverType, propertyName);
    flow.propertyGet(node, receiver, propertyName, propertyName, type);
    return type;
  }

  void analyzeReturnStatement() {
    flow.handleExit();
  }

  void analyzeSwitchStatement(
      _Switch node, Expression expression, List<SwitchCase> cases) {
    analyzeExpression(expression);
    flow.switchStatement_expressionEnd(node);
    var previousBreakTarget = _currentBreakTarget;
    _currentBreakTarget = node;
    for (var case_ in cases) {
      flow.switchStatement_beginCase(case_._hasLabel, node);
      dispatchStatement(case_._body);
    }
    _currentBreakTarget = previousBreakTarget;
    flow.switchStatement_end(isSwitchExhaustive(node));
  }

  Type analyzeThis(Expression node) {
    var thisType = this.thisType;
    flow.thisOrSuper(node, thisType);
    return thisType;
  }

  Type analyzeThisPropertyGet(Expression node, String propertyName) {
    var type = _lookupMember(node, thisType, propertyName);
    flow.thisOrSuperPropertyGet(node, propertyName, propertyName, type);
    return type;
  }

  Type analyzeThrow(Expression node, Expression expression) {
    analyzeExpression(expression);
    flow.handleExit();
    return neverType;
  }

  void analyzeTryStatement(Statement node, Statement body,
      Iterable<_CatchClause> catchClauses, Statement? finallyBlock) {
    if (finallyBlock != null) {
      flow.tryFinallyStatement_bodyBegin();
    }
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyBegin();
    }
    dispatchStatement(body);
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyEnd(body);
      for (var catch_ in catchClauses) {
        flow.tryCatchStatement_catchBegin(
            catch_._exception, catch_._stackTrace);
        dispatchStatement(catch_._body);
        flow.tryCatchStatement_catchEnd();
      }
      flow.tryCatchStatement_end();
    }
    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(
          catchClauses.isNotEmpty ? node : body);
      dispatchStatement(finallyBlock);
      flow.tryFinallyStatement_end();
    } else {
      handleNoStatement();
    }
  }

  Type analyzeTypeCast(Expression node, Expression expression, Type type) {
    analyzeExpression(expression);
    flow.asExpression_end(expression, type);
    return type;
  }

  Type analyzeTypeTest(Expression node, Expression expression, Type type,
      {bool isInverted = false}) {
    analyzeExpression(expression);
    flow.isExpression_end(node, expression, isInverted, type);
    return boolType;
  }

  void analyzeVariableDeclaration(
      Statement node, Type type, Var variable, Expression? initializer,
      {required bool isFinal, required bool isLate}) {
    if (initializer == null) {
      handleNoInitializer();
      flow.declare(variable, false);
    } else {
      var initializerType = analyzeExpression(initializer);
      flow.declare(variable, true);
      flow.initialize(variable, initializerType, initializer,
          isFinal: isFinal,
          isLate: isLate,
          isImplicitlyTyped: variable.isImplicitlyTyped);
    }
  }

  Type analyzeVariableGet(
      Expression node, Var variable, void Function(Type?)? callback) {
    var promotedType = flow.variableRead(node, variable);
    callback?.call(promotedType);
    return promotedType ?? variable.type;
  }

  void analyzeWhileLoop(Statement node, Expression condition, Statement body) {
    flow.whileStatement_conditionBegin(node);
    analyzeExpression(condition);
    flow.whileStatement_bodyBegin(node, condition);
    _visitLoopBody(node, body);
    flow.whileStatement_end();
  }

  Type dispatchExpression(Expression expression, Type context) =>
      _irBuilder.guard(expression, () => expression._visit(_harness, context));

  void dispatchStatement(Statement statement) =>
      _irBuilder.guard(statement, () => statement._visit(_harness));

  void finish() {
    flow.finish();
  }

  void handleNoCondition() {
    _irBuilder.atom('true');
  }

  void handleNoInitializer() {
    _irBuilder.atom('uninitialized');
  }

  void handleNoMessage() {
    _irBuilder.atom('failure');
  }

  void handleNoStatement() {
    _irBuilder.atom('noop');
  }

  bool isSwitchExhaustive(_Switch node) {
    return node.isExhaustive;
  }

  Type leastUpperBound(Type t1, Type t2) => _harness._lub(t1, t2);

  Type lookupInterfaceMember(Node node, Type receiverType, String memberName) {
    return _harness.getMember(receiverType, memberName);
  }

  Type _lookupMember(Expression node, Type receiverType, String memberName) {
    return lookupInterfaceMember(node, receiverType, memberName);
  }

  void _visitLoopBody(Statement loop, Statement body) {
    var previousBreakTarget = _currentBreakTarget;
    var previousContinueTarget = _currentContinueTarget;
    _currentBreakTarget = loop;
    _currentContinueTarget = loop;
    dispatchStatement(body);
    _currentBreakTarget = previousBreakTarget;
    _currentContinueTarget = previousContinueTarget;
  }
}

class _NonNullAssert extends Expression {
  final Expression operand;

  _NonNullAssert(this.operand);

  @override
  String toString() => '$operand!';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    operand._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    return h._typeAnalyzer.analyzeNonNullAssert(this, operand);
  }
}

class _Not extends Expression {
  final Expression operand;

  _Not(this.operand);

  @override
  String toString() => '!$operand';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    operand._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    return h._typeAnalyzer.analyzeLogicalNot(this, operand);
  }
}

class _NullAwareAccess extends Expression {
  static String _fakeMethodName = 'm';

  final Expression lhs;
  final Expression rhs;
  final bool isCascaded;

  _NullAwareAccess(this.lhs, this.rhs, this.isCascaded);

  @override
  String toString() => '$lhs?.${isCascaded ? '.' : ''}($rhs)';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    lhs._preVisit(assignedVariables);
    rhs._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    var lhsType = h._typeAnalyzer.analyzeExpression(lhs);
    h._flow.nullAwareAccess_rightBegin(isCascaded ? null : lhs, lhsType);
    var rhsType = h._typeAnalyzer.analyzeExpression(rhs);
    h._flow.nullAwareAccess_end();
    var type = h._lub(rhsType, Type('Null'));
    h._irBuilder.apply(_fakeMethodName, 2);
    return type;
  }
}

class _NullLiteral extends Expression {
  _NullLiteral();

  @override
  String toString() => 'null';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  Type _visit(Harness h, Type context) {
    var type = h._typeAnalyzer.analyzeNullLiteral(this);
    h._irBuilder.atom('null');
    return type;
  }
}

class _ParenthesizedExpression extends Expression {
  final Expression expr;

  _ParenthesizedExpression(this.expr);

  @override
  String toString() => '($expr)';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    expr._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    return h._typeAnalyzer.analyzeParenthesizedExpression(this, expr);
  }
}

class _PlaceholderExpression extends Expression {
  final Type type;

  _PlaceholderExpression(this.type);

  @override
  String toString() => '(expr with type $type)';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  Type _visit(Harness h, Type context) {
    h._irBuilder.atom(type.type);
    h._irBuilder.apply('expr', 1);
    return type;
  }
}

class _Property extends LValue {
  final Expression target;

  final String propertyName;

  _Property(this.target, this.propertyName) : super._();

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables,
      {_LValueDisposition disposition = _LValueDisposition.read}) {
    target._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    return h._typeAnalyzer.analyzePropertyGet(this, target, propertyName);
  }

  @override
  void _visitWrite(Harness h, Expression assignmentExpression, Type writtenType,
      Expression? rhs) {
    // No flow analysis impact
  }
}

class _Return extends Statement {
  _Return() : super._();

  @override
  String toString() => 'return;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeReturnStatement();
    h._irBuilder.apply('return', 0);
  }
}

class _Switch extends Statement {
  final Expression expression;
  final List<SwitchCase> cases;
  final bool isExhaustive;

  _Switch(this.expression, this.cases, this.isExhaustive) : super._();

  @override
  String toString() {
    var exhaustiveness = isExhaustive ? 'exhaustive' : 'non-exhaustive';
    String body;
    if (cases.isEmpty) {
      body = '{}';
    } else {
      var contents = cases.join(' ');
      body = '{ $contents }';
    }
    return 'switch<$exhaustiveness> ($expression) $body';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    expression._preVisit(assignedVariables);
    assignedVariables.beginNode();
    for (var case_ in cases) {
      case_._preVisit(assignedVariables);
    }
    assignedVariables.endNode(this);
  }

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeSwitchStatement(this, expression, cases);
    h._irBuilder.apply('switch', cases.length + 1);
  }
}

class _This extends Expression {
  @override
  String toString() => 'this';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  Type _visit(Harness h, Type context) {
    var type = h._typeAnalyzer.analyzeThis(this);
    h._irBuilder.atom('this');
    return type;
  }
}

class _ThisOrSuperPropertyGet extends Expression {
  final String propertyName;

  _ThisOrSuperPropertyGet(this.propertyName);

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  Type _visit(Harness h, Type context) {
    var type = h._typeAnalyzer.analyzeThisPropertyGet(this, propertyName);
    h._irBuilder.atom('this.$propertyName');
    return type;
  }
}

class _Throw extends Expression {
  final Expression operand;

  _Throw(this.operand);

  @override
  String toString() => 'throw ...';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    operand._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    return h._typeAnalyzer.analyzeThrow(this, operand);
  }
}

class _TryStatement extends TryStatement {
  final Statement _body;
  final List<_CatchClause> _catches;
  final Statement? _finally;

  _TryStatement(this._body, this._catches, this._finally) : super._();

  @override
  TryStatement catch_(
      {Var? exception, Var? stackTrace, required List<Statement> body}) {
    assert(_finally == null, 'catch after finally');
    return _TryStatement(_body,
        [..._catches, _CatchClause(block(body), exception, stackTrace)], null);
  }

  @override
  Statement finally_(List<Statement> statements) {
    assert(_finally == null, 'multiple finally clauses');
    return _TryStatement(_body, _catches, block(statements));
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    if (_finally != null) {
      assignedVariables.beginNode();
    }
    if (_catches.isNotEmpty) {
      assignedVariables.beginNode();
    }
    _body._preVisit(assignedVariables);
    assignedVariables.endNode(_body);
    for (var catch_ in _catches) {
      catch_._preVisit(assignedVariables);
    }
    if (_finally != null) {
      if (_catches.isNotEmpty) {
        assignedVariables.endNode(this);
      }
      _finally!._preVisit(assignedVariables);
    }
  }

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeTryStatement(this, _body, _catches, _finally);
    h._irBuilder.apply('try', 2 + _catches.length);
  }
}

class _VariableReference extends LValue {
  final Var variable;

  final void Function(Type?)? callback;

  _VariableReference(this.variable, this.callback) : super._();

  @override
  String toString() => variable.name;

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables,
      {_LValueDisposition disposition = _LValueDisposition.read}) {
    if (disposition != _LValueDisposition.write) {
      assignedVariables.read(variable);
    }
    if (disposition != _LValueDisposition.read) {
      assignedVariables.write(variable);
    }
  }

  @override
  Type _visit(Harness h, Type context) {
    var type = h._typeAnalyzer.analyzeVariableGet(this, variable, callback);
    h._irBuilder.atom(variable.name);
    return type;
  }

  @override
  void _visitWrite(Harness h, Expression assignmentExpression, Type writtenType,
      Expression? rhs) {
    h._flow.write(assignmentExpression, variable, writtenType, rhs);
  }
}

class _While extends Statement {
  final Expression condition;
  final Statement body;

  _While(this.condition, this.body) : super._();

  @override
  String toString() => 'while ($condition) $body';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    assignedVariables.beginNode();
    condition._preVisit(assignedVariables);
    body._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  void _visit(Harness h) {
    h._typeAnalyzer.analyzeWhileLoop(this, condition, body);
    h._irBuilder.apply('while', 2);
  }
}

class _WhyNotPromoted extends Expression {
  final Expression target;

  final void Function(Map<Type, NonPromotionReason>) callback;

  _WhyNotPromoted(this.target, this.callback);

  @override
  String toString() => '$target (whyNotPromoted)';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    target._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    var type = h._typeAnalyzer.analyzeExpression(target);
    h._flow.forwardExpression(this, target);
    Type.withComparisonsAllowed(() {
      callback(h._flow.whyNotPromoted(this)());
    });
    return type;
  }
}

class _WhyNotPromoted_ImplicitThis extends Statement {
  final Type staticType;

  final void Function(Map<Type, NonPromotionReason>) callback;

  _WhyNotPromoted_ImplicitThis(this.staticType, this.callback) : super._();

  @override
  String toString() => 'implicit this (whyNotPromoted)';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(Harness h) {
    Type.withComparisonsAllowed(() {
      callback(h._flow.whyNotPromotedImplicitThis(staticType)());
    });
    h._irBuilder.atom('noop');
  }
}

class _WrappedExpression extends Expression {
  final Statement? before;
  final Expression expr;
  final Statement? after;

  _WrappedExpression(this.before, this.expr, this.after);

  @override
  String toString() {
    var s = StringBuffer('(');
    if (before != null) {
      s.write('($before) ');
    }
    s.write(expr);
    if (after != null) {
      s.write(' ($after)');
    }
    s.write(')');
    return s.toString();
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    before?._preVisit(assignedVariables);
    expr._preVisit(assignedVariables);
    after?._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    late MiniIrTmp beforeTmp;
    if (before != null) {
      h._typeAnalyzer.dispatchStatement(before!);
      beforeTmp = h._irBuilder.allocateTmp();
    }
    var type = h._typeAnalyzer.analyzeExpression(expr);
    if (after != null) {
      var exprTmp = h._irBuilder.allocateTmp();
      h._typeAnalyzer.dispatchStatement(after!);
      var afterTmp = h._irBuilder.allocateTmp();
      h._irBuilder.readTmp(exprTmp);
      h._irBuilder.let(afterTmp);
      h._irBuilder.let(exprTmp);
    }
    h._flow.forwardExpression(this, expr);
    if (before != null) {
      h._irBuilder.let(beforeTmp);
    }
    return type;
  }
}

class _Write extends Expression {
  final LValue lhs;
  final Expression? rhs;

  _Write(this.lhs, this.rhs);

  @override
  String toString() => '$lhs = $rhs';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    lhs._preVisit(assignedVariables,
        disposition: rhs == null
            ? _LValueDisposition.readWrite
            : _LValueDisposition.write);
    rhs?._preVisit(assignedVariables);
  }

  @override
  Type _visit(Harness h, Type context) {
    var rhs = this.rhs;
    Type type;
    if (rhs == null) {
      // We are simulating an increment/decrement operation.
      // TODO(paulberry): Make a separate node type for this.
      type = h._typeAnalyzer.analyzeExpression(lhs);
    } else {
      type = h._typeAnalyzer.analyzeExpression(rhs);
    }
    lhs._visitWrite(h, this, type, rhs);
    return type;
  }
}
