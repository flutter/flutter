// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:collection/collection.dart';

typedef SharedPatternField
    = shared.RecordPatternField<PatternFieldImpl, DartPatternImpl>;

/// Implementation of [shared.TypeAnalyzerErrors] that reports errors using the
/// analyzer's [ErrorReporter] class.
class SharedTypeAnalyzerErrors
    implements
        shared.TypeAnalyzerErrors<AstNode, Statement, Expression,
            PromotableElement, DartType, DartPattern> {
  final ErrorReporter _errorReporter;

  SharedTypeAnalyzerErrors(this._errorReporter);

  @override
  void argumentTypeNotAssignable({
    required Expression argument,
    required DartType argumentType,
    required DartType parameterType,
  }) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      argument,
      [argumentType, parameterType],
    );
  }

  @override
  void assertInErrorRecovery() {}

  @override
  void caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required DartType scrutineeType,
      required DartType caseExpressionType,
      required bool nullSafetyEnabled}) {
    if (nullSafetyEnabled) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode
              .CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE,
          caseExpression,
          [caseExpressionType, scrutineeType]);
    } else {
      // We only report the error if it occurs on the first case; otherwise
      // separate logic will report that different cases have different types.
      var switchStatement = scrutinee.parent as SwitchStatement;
      if (identical(
          switchStatement.members
              .whereType<SwitchCase>()
              .firstOrNull
              ?.expression,
          caseExpression)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE,
            scrutinee,
            [scrutineeType, caseExpressionType]);
      }
    }
  }

  @override
  void duplicateAssignmentPatternVariable({
    required covariant PromotableElement variable,
    required covariant AssignedVariablePatternImpl original,
    required covariant AssignedVariablePatternImpl duplicate,
  }) {
    _errorReporter.reportError(
      DiagnosticFactory().duplicateAssignmentPatternVariable(
        source: _errorReporter.source,
        variable: variable,
        original: original,
        duplicate: duplicate,
      ),
    );
  }

  @override
  void duplicateRecordPatternField({
    required DartPattern objectOrRecordPattern,
    required String name,
    required covariant SharedPatternField original,
    required covariant SharedPatternField duplicate,
  }) {
    _errorReporter.reportError(
      DiagnosticFactory().duplicatePatternField(
        source: _errorReporter.source,
        name: name,
        duplicateField: duplicate.node,
        originalField: original.node,
      ),
    );
  }

  @override
  void duplicateRestPattern({
    required DartPattern mapOrListPattern,
    required covariant RestPatternElementImpl original,
    required covariant RestPatternElementImpl duplicate,
  }) {
    _errorReporter.reportError(
      DiagnosticFactory().duplicateRestElementInPattern(
        source: _errorReporter.source,
        originalElement: original,
        duplicateElement: duplicate,
      ),
    );
  }

  @override
  void inconsistentJoinedPatternVariable({
    required PromotableElement variable,
    required PromotableElement component,
  }) {
    _errorReporter.reportErrorForElement(
      CompileTimeErrorCode.INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR,
      component,
      [variable.name],
    );
  }

  @override
  void matchedTypeIsStrictlyNonNullable({
    required DartPattern pattern,
    required DartType matchedType,
  }) {
    if (pattern is NullAssertPattern) {
      _errorReporter.reportErrorForToken(
        StaticWarningCode.UNNECESSARY_NULL_ASSERT_PATTERN,
        pattern.operator,
      );
    } else if (pattern is NullCheckPattern) {
      _errorReporter.reportErrorForToken(
        StaticWarningCode.UNNECESSARY_NULL_CHECK_PATTERN,
        pattern.operator,
      );
    } else {
      throw UnimplementedError('(${pattern.runtimeType}) $pattern');
    }
  }

  @override
  void matchedTypeIsSubtypeOfRequired({
    required covariant CastPatternImpl pattern,
    required DartType matchedType,
    required DartType requiredType,
  }) {
    _errorReporter.reportErrorForToken(
      WarningCode.UNNECESSARY_CAST_PATTERN,
      pattern.asToken,
    );
  }

  @override
  void nonBooleanCondition({required Expression node}) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.NON_BOOL_CONDITION,
      node,
    );
  }

  @override
  void nonExhaustiveSwitch(
      {required AstNode node, required DartType scrutineeType}) {
    _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH,
        node,
        [scrutineeType, scrutineeType.toString()]);
  }

  @override
  void patternDoesNotAllowLate({required AstNode pattern}) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void patternForInExpressionIsNotIterable({
    required AstNode node,
    required Expression expression,
    required DartType expressionType,
  }) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE,
      expression,
      [expressionType, 'Iterable'],
    );
  }

  @override
  void patternTypeMismatchInIrrefutableContext({
    required covariant DartPatternImpl pattern,
    required AstNode context,
    required DartType matchedType,
    required DartType requiredType,
  }) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
      pattern,
      [matchedType, requiredType],
    );
  }

  @override
  void refutablePatternInIrrefutableContext(
      {required AstNode pattern, required AstNode context}) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT,
      pattern,
    );
  }

  @override
  void relationalPatternOperatorReturnTypeNotAssignableToBool({
    required covariant RelationalPatternImpl pattern,
    required DartType returnType,
  }) {
    _errorReporter.reportErrorForToken(
      CompileTimeErrorCode
          .RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL,
      pattern.operator,
    );
  }

  @override
  void restPatternNotLastInMap(
      {required covariant MapPatternImpl node,
      required covariant RestPatternElementImpl element}) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.REST_ELEMENT_NOT_LAST_IN_MAP_PATTERN,
      element,
    );
  }

  @override
  void restPatternWithSubPatternInMap(
      {required covariant MapPatternImpl node,
      required covariant RestPatternElementImpl element}) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.REST_ELEMENT_WITH_SUBPATTERN_IN_MAP_PATTERN,
      element.pattern!,
    );
  }

  @override
  void switchCaseCompletesNormally(
      {required covariant SwitchStatement node, required int caseIndex}) {
    _errorReporter.reportErrorForToken(
        CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY,
        node.members[caseIndex].keyword);
  }

  @override
  void unnecessaryWildcardPattern({
    required covariant WildcardPatternImpl pattern,
    required UnnecessaryWildcardKind kind,
  }) {
    switch (kind) {
      case UnnecessaryWildcardKind.logicalAndPatternOperand:
        _errorReporter.reportErrorForNode(
          WarningCode.UNNECESSARY_WILDCARD_PATTERN,
          pattern,
        );
        break;
    }
  }
}
