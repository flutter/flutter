// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
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
          HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE,
          node,
          [node.name.name],
        );
      }
      return;
    }

    var element = node.declaredElement!;
    var isTopLevel =
        element is FieldElement || element is TopLevelVariableElement;

    InferenceContext.setTypeFromNode(initializer, node);
    if (isTopLevel) {
      _resolver.flowAnalysis.topLevelDeclaration_enter(node, null);
    } else if (element.isLate) {
      _resolver.flowAnalysis.flow?.lateInitializer_begin(node);
    }

    initializer.accept(_resolver);
    initializer = node.initializer!;
    var whyNotPromoted =
        _resolver.flowAnalysis.flow?.whyNotPromoted(initializer);

    if (parent.type == null) {
      _setInferredType(element, initializer.typeOrThrow);
    }

    if (isTopLevel) {
      _resolver.flowAnalysis.topLevelDeclaration_exit();
    } else if (element.isLate) {
      _resolver.flowAnalysis.flow?.lateInitializer_end();
    }

    initializer = _resolver.insertImplicitCallReference(initializer);

    // Initializers of top-level variables and fields are already included
    // into elements during linking.
    if (element is ConstLocalVariableElementImpl) {
      element.constantInitializer = initializer;
    }

    _resolver.checkForInvalidAssignment(node.name, initializer,
        whyNotPromoted: whyNotPromoted);
  }

  void _setInferredType(VariableElement element, DartType initializerType) {
    if (element is LocalVariableElementImpl) {
      if (initializerType.isDartCoreNull) {
        initializerType = DynamicTypeImpl.instance;
      }

      var inferredType = _resolver.typeSystem.demoteType(initializerType);
      element.type = inferredType;
    }
  }
}
