// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [VariableDeclaration]s.
class VariableDeclarationResolver {
  final ResolverVisitor _resolver;
  final bool _strictInference;

  VariableDeclarationResolver({
    required ResolverVisitor resolver,
    required bool strictInference,
  })  : _resolver = resolver,
        _strictInference = strictInference;

  void resolve(VariableDeclarationImpl node) {
    var parent = node.parent as VariableDeclarationList;

    var initializer = node.initializer;

    if (initializer == null) {
      if (_strictInference && parent.type == null) {
        _resolver.errorReporter.reportErrorForNode(
          WarningCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE,
          node,
          [node.name.lexeme],
        );
      }
      return;
    }

    var element = node.declaredElement!;
    var isTopLevel =
        element is FieldElement || element is TopLevelVariableElement;

    if (isTopLevel) {
      _resolver.flowAnalysis.topLevelDeclaration_enter(node, null);
    } else if (element.isLate) {
      _resolver.flowAnalysis.flow?.lateInitializer_begin(node);
    }

    final contextType = element is! PropertyInducingElementImpl ||
            element.shouldUseTypeForInitializerInference
        ? element.type
        : UnknownInferredType.instance;
    _resolver.analyzeExpression(initializer, contextType);
    initializer = _resolver.popRewrite()!;
    var whyNotPromoted =
        _resolver.flowAnalysis.flow?.whyNotPromoted(initializer);

    var initializerType = initializer.typeOrThrow;
    if (parent.type == null && element is LocalVariableElementImpl) {
      element.type = _resolver.variableTypeFromInitializerType(initializerType);
    }

    if (isTopLevel) {
      _resolver.flowAnalysis.topLevelDeclaration_exit();
      _resolver.nullSafetyDeadCodeVerifier.flowEnd(node);
    } else if (element.isLate) {
      _resolver.flowAnalysis.flow?.lateInitializer_end();
    }

    // Initializers of top-level variables and fields are already included
    // into elements during linking.
    if (element is ConstLocalVariableElementImpl) {
      element.constantInitializer = initializer;
    }

    _resolver.checkForAssignableExpressionAtType(
      initializer,
      initializerType,
      element.type,
      CompileTimeErrorCode.INVALID_ASSIGNMENT,
      whyNotPromoted: whyNotPromoted,
    );
  }
}
