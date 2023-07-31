// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_analyzer.dart';

/// Container for the result of running type analysis on an expression.
///
/// This class keeps track of a provisional type of the expression (prior to
/// resolving null shorting) as well as the information necessary to resolve
/// null shorting.
abstract class ExpressionTypeAnalysisResult<Type extends Object> {
  /// Type of the expression before resolving null shorting.
  ///
  /// For example, if `this` is the result of analyzing `(... as int?)?.isEven`,
  /// [provisionalType] will be `bool`, because the `isEven` getter returns
  /// `bool`, and it is not yet known (until looking at the surrounding code)
  /// whether there will be additional selectors after `isEven` that should act
  /// on the `bool` type.
  Type get provisionalType;

  /// Resolves any pending null shorting.  For example, if `this` is the result
  /// of analyzing `(... as int?)?.isEven`, then calling [resolveShorting] will
  /// cause the `?.` to be desugared (if code generation is occurring) and will
  /// return the type `bool?`.
  ///
  /// TODO(paulberry): document what calls back to the client might be made by
  /// invoking this method.
  Type resolveShorting();
}

/// Container for the result of running type analysis on an integer literal.
class IntTypeAnalysisResult<Type extends Object>
    extends SimpleTypeAnalysisResult<Type> {
  /// Whether the integer literal was converted to a double.
  final bool convertedToDouble;

  IntTypeAnalysisResult({required super.type, required this.convertedToDouble});
}

/// Information about the code context surrounding a pattern match.
class MatchContext<Node extends Object, Expression extends Node,
    Pattern extends Node, Type extends Object, Variable extends Object> {
  /// If non-`null`, the match is being done in an irrefutable context, and this
  /// is the surrounding AST node that establishes the irrefutable context.
  final Node? irrefutableContext;

  /// Indicates whether variables declared in the pattern should be `final`.
  final bool isFinal;

  /// Indicates whether variables declared in the pattern should be `late`.
  final bool isLate;

  /// The initializer being assigned to this pattern via a variable declaration
  /// statement, or `null` if this pattern does not occur in a variable
  /// declaration statement, or this pattern is not the top-level pattern in
  /// the declaration.
  final Expression? initializer;

  /// The switch scrutinee, or `null` if this pattern does not occur in a switch
  /// statement or switch expression, or this pattern is not the top-level
  /// pattern.
  final Expression? switchScrutinee;

  /// If the match is being done in a pattern assignment, the set of variables
  /// assigned so far.
  final Map<Variable, Pattern>? assignedVariables;

  /// For each variable name in the pattern, a list of the variables which might
  /// capture that variable's value, depending upon which alternative is taken
  /// in a logical-or pattern.
  final Map<String, List<Variable>> componentVariables;

  /// For each variable name in the pattern, the promotion key holding the value
  /// captured by that variable.
  final Map<String, int> patternVariablePromotionKeys;

  /// If non-null, the warning that should be issued if the pattern is `_`
  final UnnecessaryWildcardKind? unnecessaryWildcardKind;

  MatchContext({
    this.initializer,
    this.irrefutableContext,
    required this.isFinal,
    this.isLate = false,
    this.switchScrutinee,
    this.assignedVariables,
    required this.componentVariables,
    required this.patternVariablePromotionKeys,
    this.unnecessaryWildcardKind,
  });

  /// Returns a modified version of `this`, with [irrefutableContext] set to
  /// `null`.  This is used to suppress cascading errors after reporting
  /// [TypeAnalyzerErrors.refutablePatternInIrrefutableContext].
  MatchContext<Node, Expression, Pattern, Type, Variable> makeRefutable() =>
      irrefutableContext == null
          ? this
          : new MatchContext(
              initializer: initializer,
              isFinal: isFinal,
              isLate: isLate,
              switchScrutinee: switchScrutinee,
              assignedVariables: assignedVariables,
              componentVariables: componentVariables,
              patternVariablePromotionKeys: patternVariablePromotionKeys,
            );

  /// Returns a modified version of `this`, with a new value of
  /// [patternVariablePromotionKeys].
  MatchContext<Node, Expression, Pattern, Type, Variable> withPromotionKeys(
          Map<String, int> patternVariablePromotionKeys) =>
      new MatchContext(
        initializer: null,
        irrefutableContext: irrefutableContext,
        isFinal: isFinal,
        isLate: isLate,
        switchScrutinee: null,
        assignedVariables: assignedVariables,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
        unnecessaryWildcardKind: unnecessaryWildcardKind,
      );

  /// Returns a modified version of `this`, with both [initializer] and
  /// [switchScrutinee] set to `null` (because this context is not for a
  /// top-level pattern anymore).
  MatchContext<Node, Expression, Pattern, Type, Variable>
      withUnnecessaryWildcardKind(
          UnnecessaryWildcardKind? unnecessaryWildcardKind) {
    return new MatchContext(
      initializer: null,
      irrefutableContext: irrefutableContext,
      isFinal: isFinal,
      isLate: isLate,
      assignedVariables: assignedVariables,
      switchScrutinee: null,
      componentVariables: componentVariables,
      patternVariablePromotionKeys: patternVariablePromotionKeys,
      unnecessaryWildcardKind: unnecessaryWildcardKind,
    );
  }
}

/// Container for the result of running type analysis on a pattern assignment.
class PatternAssignmentAnalysisResult<Type extends Object>
    extends SimpleTypeAnalysisResult<Type> {
  /// The type schema of the pattern on the left hand size of the assignment.
  final Type patternSchema;

  PatternAssignmentAnalysisResult({
    required this.patternSchema,
    required super.type,
  });
}

/// Container for the result of running type analysis on an expression that does
/// not contain any null shorting.
class SimpleTypeAnalysisResult<Type extends Object>
    implements ExpressionTypeAnalysisResult<Type> {
  /// The static type of the expression.
  final Type type;

  SimpleTypeAnalysisResult({required this.type});

  @override
  Type get provisionalType => type;

  @override
  Type resolveShorting() => type;
}

/// Container for the result of running type analysis on an integer literal.
class SwitchStatementTypeAnalysisResult<Type> {
  /// Whether the switch statement had a `default` clause.
  final bool hasDefault;

  /// Whether the switch statement was exhaustive.
  final bool isExhaustive;

  /// Whether the last case body in the switch statement terminated.
  final bool lastCaseTerminates;

  /// If `true`, patterns support is enabled, there is no default clause, and
  /// the static type of the scrutinee expression is an "always exhaustive"
  /// type.  Therefore, flow analysis has assumed (without checking) that the
  /// switch statement is exhaustive.  So at a later stage of compilation, the
  /// exhaustiveness checking algorithm should check whether this switch
  /// statement was exhaustive, and report a compile-time error if it wasn't.
  final bool requiresExhaustivenessValidation;

  /// The static type of the scrutinee expression.
  final Type scrutineeType;

  SwitchStatementTypeAnalysisResult({
    required this.hasDefault,
    required this.isExhaustive,
    required this.lastCaseTerminates,
    required this.requiresExhaustivenessValidation,
    required this.scrutineeType,
  });
}

/// The location of a wildcard pattern that was found unnecessary.
///
/// When a wildcard pattern always matches, and is not required by the
/// by the location, we can report it as unnecessary. The locations where it
/// is necessary include list patterns, record patterns, cast patterns, etc.
enum UnnecessaryWildcardKind {
  /// The wildcard pattern is the left or the right side of a logical-and
  /// pattern. Because we found that is always matches, it has no effect,
  /// and can be removed.
  logicalAndPatternOperand,
}
