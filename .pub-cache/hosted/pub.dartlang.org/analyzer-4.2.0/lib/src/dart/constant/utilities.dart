// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// Callback used by [ReferenceFinder] to report that a dependency was found.
typedef ReferenceFinderCallback = void Function(
    ConstantEvaluationTarget dependency);

/// A visitor used to traverse the AST structures of all of the compilation
/// units being resolved and build the full set of dependencies for all constant
/// expressions.
class ConstantExpressionsDependenciesFinder extends RecursiveAstVisitor {
  /// The constants whose values need to be computed.
  HashSet<ConstantEvaluationTarget> dependencies =
      HashSet<ConstantEvaluationTarget>();

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      _find(node);
    } else {
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      _find(node);
    } else {
      super.visitListLiteral(node);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isConst) {
      _find(node);
    } else {
      if (node.isMap) {
        // Values of keys are computed to check that they are unique.
        for (var entry in node.elements) {
          // TODO(mfairhurst): How do if/for loops/spreads affect this?
          _find(entry);
        }
      } else if (node.isSet) {
        // values of sets are computed to check that they are unique.
        for (var entry in node.elements) {
          _find(entry);
        }
      }
      super.visitSetOrMapLiteral(node);
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _find(node.expression);
    node.statements.accept(this);
  }

  /// Add dependencies of a [CollectionElement] or [Expression] (which is a type
  /// of [CollectionElement]).
  void _find(CollectionElement node) {
    ReferenceFinder referenceFinder = ReferenceFinder(dependencies.add);
    node.accept(referenceFinder);
  }
}

/// A visitor used to traverse the AST structures of all of the compilation
/// units being resolved and build tables of the constant variables, constant
/// constructors, constant constructor invocations, and annotations found in
/// those compilation units.
class ConstantFinder extends RecursiveAstVisitor<void> {
  /// The elements and AST nodes whose constant values need to be computed.
  List<ConstantEvaluationTarget> constantsToCompute =
      <ConstantEvaluationTarget>[];

  /// A flag indicating whether instance variables marked as "final" should be
  /// treated as "const".
  bool treatFinalInstanceVarAsConst = false;

  @override
  void visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    var elementAnnotation = node.elementAnnotation;
    if (elementAnnotation == null) {
      // Analyzer ignores annotations on "part of" directives and on enum
      // constant declarations.
      assert(node.parent is PartDirective ||
          node.parent is PartOfDirective ||
          node.parent is EnumConstantDeclaration);
    } else {
      constantsToCompute.add(elementAnnotation);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    bool prevTreatFinalInstanceVarAsConst = treatFinalInstanceVarAsConst;
    if (node.declaredElement!.constructors
        .any((ConstructorElement e) => e.isConst)) {
      // Instance vars marked "final" need to be included in the dependency
      // graph, since constant constructors implicitly use the values in their
      // initializers.
      treatFinalInstanceVarAsConst = true;
    }
    try {
      super.visitClassDeclaration(node);
    } finally {
      treatFinalInstanceVarAsConst = prevTreatFinalInstanceVarAsConst;
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    if (node.constKeyword != null) {
      var element = node.declaredElement;
      if (element != null) {
        constantsToCompute.add(element);
        constantsToCompute.addAll(element.parameters);
      }
    }
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    super.visitDefaultFormalParameter(node);
    var defaultValue = node.defaultValue;
    if (defaultValue != null && node.declaredElement != null) {
      constantsToCompute.add(node.declaredElement!);
    }
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    super.visitEnumConstantDeclaration(node);

    var element = node.declaredElement as ConstFieldElementImpl;
    constantsToCompute.add(element);

    var constantInitializer = element.constantInitializer!;
    enumConstantErrorNodes[constantInitializer] = node;
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    var initializer = node.initializer;
    var element = node.declaredElement!;
    if (initializer != null &&
        (node.isConst ||
            treatFinalInstanceVarAsConst &&
                element is FieldElement &&
                node.isFinal &&
                !element.isStatic)) {
      constantsToCompute.add(element);
    }
  }
}

/// An object used to add reference information for a given variable to the
/// bi-directional mapping used to order the evaluation of constants.
class ReferenceFinder extends RecursiveAstVisitor<void> {
  /// The callback which should be used to report any dependencies that were
  /// found.
  final ReferenceFinderCallback _callback;

  /// Initialize a newly created reference finder to find references from a
  /// given variable to other variables and to add those references to the given
  /// graph. The [_callback] will be invoked for every dependency found.
  ReferenceFinder(this._callback);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      var constructor = node.constructorName.staticElement?.declaration;
      if (constructor != null && constructor.isConst) {
        _callback(constructor);
      }
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitLabel(Label node) {
    // We are visiting the "label" part of a named expression in a function
    // call (presumably a constructor call), e.g. "const C(label: ...)".  We
    // don't want to visit the SimpleIdentifier for the label because that's a
    // reference to a function parameter that needs to be filled in; it's not a
    // constant whose value we depend on.
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    super.visitRedirectingConstructorInvocation(node);
    var target = node.staticElement?.declaration;
    if (target != null) {
      _callback(target);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.staticElement;
    var element = staticElement is PropertyAccessorElement
        ? staticElement.variable
        : staticElement;
    if (element is VariableElement && element.isConst) {
      _callback(element);
    }
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    super.visitSuperConstructorInvocation(node);
    var constructor = node.staticElement?.declaration;
    if (constructor != null) {
      _callback(constructor);
    }
  }
}
