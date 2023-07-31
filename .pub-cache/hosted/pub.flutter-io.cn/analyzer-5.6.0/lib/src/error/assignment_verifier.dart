// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';

/// Helper for verifying resolution of assignments, in form of explicit
/// an [AssignmentExpression], or a [PrefixExpression] or [PostfixExpression]
/// when the operator is an increment operator.
class AssignmentVerifier {
  final LibraryElement _definingLibrary;
  final ErrorReporter _errorReporter;

  AssignmentVerifier(this._definingLibrary, this._errorReporter);

  /// We resolved [node] and found that it references the [requested] element.
  /// Verify that this element is actually writable.
  ///
  /// If the [requested] element is `null`, we might have the [recovery]
  /// element, which is definitely not a valid write target. We want to report
  /// a good error about this.
  ///
  /// When the [receiverType] is not `null`, we report
  /// [CompileTimeErrorCode.UNDEFINED_SETTER] instead of a more generic
  /// [CompileTimeErrorCode.UNDEFINED_IDENTIFIER].
  void verify({
    required SimpleIdentifier node,
    required Element? requested,
    required Element? recovery,
    required DartType? receiverType,
  }) {
    if (requested != null) {
      if (requested is VariableElement) {
        if (requested.isConst) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.ASSIGNMENT_TO_CONST,
            node,
          );
        } else if (requested.isFinal) {
          if (_definingLibrary.isNonNullableByDefault) {
            // Handled during resolution, with flow analysis.
          } else {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL,
              node,
              [requested.name],
            );
          }
        }
      }
      return;
    }

    if (recovery is DynamicElementImpl ||
        recovery is InterfaceElement ||
        recovery is TypeAliasElement ||
        recovery is TypeParameterElement) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.ASSIGNMENT_TO_TYPE,
        node,
      );
    } else if (recovery is FunctionElement) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.ASSIGNMENT_TO_FUNCTION,
        node,
      );
    } else if (recovery is MethodElement) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.ASSIGNMENT_TO_METHOD,
        node,
      );
    } else if (recovery is PrefixElement) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
        node,
        [recovery.name],
      );
    } else if (recovery is PropertyAccessorElement && recovery.isGetter) {
      var variable = recovery.variable;
      if (variable.isConst) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_CONST,
          node,
        );
      } else if (variable is FieldElement && variable.isSynthetic) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER,
          node,
          [variable.name, variable.enclosingElement.displayName],
        );
      } else {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_FINAL,
          node,
          [variable.name],
        );
      }
    } else if (recovery is MultiplyDefinedElementImpl) {
      // Will be reported in ErrorVerifier.
    } else {
      if (node.isSynthetic) {
        return;
      }
      if (receiverType != null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_SETTER,
          node,
          [node.name, receiverType],
        );
      } else {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
          node,
          [node.name],
        );
      }
    }
  }
}
