// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';

/// Hooks used by resolution to communicate with the migration engine.
abstract class MigrationResolutionHooks
    implements ElementTypeProvider, MigratableAstInfoProvider {
  /// Called when the resolver is visiting an if statement, if element, or
  /// conditional expression, to determine whether the condition is known to
  /// evaluate to `true` or `false`.
  ///
  /// If the condition is known to evaluate to `true` or `false`, then the value
  /// it is known to evaluate to is returned.  Otherwise `null` is returned.
  bool? getConditionalKnownValue(AstNode node);

  /// Called after the resolver has determined the type of an expression node.
  /// Should return the type that the expression has after migrations have been
  /// applied.
  DartType modifyExpressionType(
      Expression expression, DartType dartType, DartType? contextType);

  /// Called after the resolver has inferred the type of a function literal
  /// parameter.  Should return the type that the parameter has after migrations
  /// have been applied.
  DartType modifyInferredParameterType(
      ParameterElement parameter, DartType type);

  /// Called at the beginning of visiting a binary expression, to report the
  /// context type of the binary expression.
  void reportBinaryExpressionContext(
      BinaryExpression node, DartType? contextType);

  /// Called after the resolver has determined the read and write types
  /// of the assignment expression.
  void setCompoundAssignmentExpressionTypes(CompoundAssignmentExpression node);

  /// Called when the resolver starts or stops making use of a [FlowAnalysis]
  /// instance.
  void setFlowAnalysis(
      FlowAnalysis<AstNode, Statement, Expression, PromotableElement, DartType>?
          flowAnalysis);
}
