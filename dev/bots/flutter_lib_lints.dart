// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';

import 'utils.dart';

Future<void> parseFlutterLibAndAnalyze(String workingDirectory, List<ResolvedUnitVerifier> verifiers) async {
  final String flutterLibPath = '$workingDirectory/packages/flutter/lib';
  final AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>[flutterLibPath],
    excludedPaths: <String>['$flutterLibPath/fix_data'],
  );

  final List<String> analyzerErrors = <String>[];
  for (final AnalysisContext context in collection.contexts) {
    // Normalized paths to all analyzed files.
    final Iterable<String> analyzedFilePaths = context.contextRoot.analyzedFiles();
    final AnalysisSession session = context.currentSession;

    for (final String path in analyzedFilePaths) {
      if (!path.endsWith('text_painter.dart')) {
        continue;
      }
      final SomeResolvedUnitResult unit = await session.getResolvedUnit(path);
      if (unit is ResolvedUnitResult) {
        for (final verifier in verifiers) {
          verifier.analyzeResolvedUnitResult(unit);
        }
      } else {
        analyzerErrors.add('analyzer error: file $unit could not be resolved.');
      }
    }
  }

  if (analyzerErrors.isNotEmpty) {
    foundError(analyzerErrors);
  }
  for (final verifier in verifiers) {
    verifier.reportError();
  }
}

abstract class ResolvedUnitVerifier {
  void reportError();

  void analyzeResolvedUnitResult(ResolvedUnitResult unit);
}

final verifyNoDoubleClamp = _NoDoubleClampVerifier();
class _NoDoubleClampVerifier implements ResolvedUnitVerifier {
  final List<String> errors = <String>[];

  @override
  void reportError() {
    if (errors.isEmpty) {
      return;
    }
    foundError(<String>[
      ...errors,
      '\n${bold}For performance reasons, we use a custom `clampDouble` function instead of using `Double.clamp`.$reset',
      '\n${bold}For non-double uses of `clamp`, use `// ignore_clamp_double_lint` on the line to silence this message.$reset',
    ]);
  }

  @override
  void analyzeResolvedUnitResult(ResolvedUnitResult unit) {
    final visitor = _DoubleClampVisitor();
    unit.unit.visitChildren(visitor);
    for (final MethodInvocation node in visitor.clampInvocationNode) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.function.offset).lineNumber;
      final String lineContent = unit.content.substring(
        lineInfo.getOffsetOfLine(lineNumber - 1),
        lineInfo.getOffsetOfLine(lineNumber) - 1,
      );
      if (lineContent.contains('// ignore_clamp_double_lint')) {
        continue;
      }
      errors.add('${unit.path}:$lineNumber: `Double.clamp` method used instead of `clampDouble`.');
    }
  }

  @override
  String toString() => 'No "Double.clamp"';
}

class _DoubleClampVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> clampInvocationNode = <MethodInvocation>[];

  @override
  CompilationUnit? visitMethodInvocation(MethodInvocation node) {
    final bool isNumClampInvocation = node.methodName.name == 'clamp' && (node.target?.staticType?.isDartCoreDouble ?? false);
    if (isNumClampInvocation) {
      clampInvocationNode.add(node);
    }
    node.visitChildren(this);
    return null;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticElement is FunctionElement) {
      print('$node | ${node.staticElement} => ${node.staticElement.runtimeType}');
    }
    super.visitSimpleIdentifier(node);
  }
}


// Element Helpers
bool _isDebugAssertAnnotationElement(ElementAnnotation annotation) {
  final Element? annotationElement = annotation.element;
  return annotationElement is PropertyAccessorElement && annotationElement.name == '_debugAssert';
}

bool _hasDebugAnnotation(Element element) => element.metadata.any(_isDebugAssertAnnotationElement);

bool _isDebug(Element element) {
  return switch (element) {
    PropertyAccessorElement(:final variable) => _hasDebugAnnotation(element) || _hasDebugAnnotation(variable),
    MethodElement()                          => _hasDebugAnnotation(element),
    ExecutableElement()                      => _hasDebugAnnotation(element),
    _                                        => false,
  } ;
}

final verifyDebugAssertAccess = _DebugAssertVerifier();
class _DebugAssertVerifier extends ResolvedUnitVerifier {
  final List<String> errors = <String>[];
  @override
  void reportError() {
    if (errors.isEmpty) {
      return;
    }
    foundError(errors);
  }

  @override
  void analyzeResolvedUnitResult(ResolvedUnitResult unit) {
    final visitor = _DebugAssertVisitor();
    unit.unit.visitChildren(visitor);
    for (final AstNode node in visitor.violations) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.offset).lineNumber;
      errors.add('${unit.path}:$lineNumber: invalid debugAssert access.');
    }
  }

  @override
  String toString() => '"debugAssert"';
}

class _DebugAssertVisitor extends RecursiveAstVisitor<void> {
  List<AstNode> violations = [];

  void _verifyNoDebugAssert(Element? element, AstNode node) {
    final isDeprecated = switch (element) {
      null => false,
      PropertyAccessorElement(isSynthetic: true, : final variable) => _hasDebugAnnotation(variable),
      _ => _isDebug(element),
    };

    if (!isDeprecated) {
      return;
    }

    violations.add(node);
  }

  InterfaceElement? classDeclaration;

  @override
  void visitAssertInitializer(AssertInitializer node) {
    // Ok to access debugAsserts in asserts, either in the condition or the
    // message.
  }
  @override
  void visitAssertStatement(AssertStatement node) { }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final declaredElement = node.declaredElement;
    if (declaredElement != null && _isDebug(declaredElement)) {
      return;
    }
    super.visitMethodDeclaration(node);
  }


  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _verifyNoDebugAssert(node.readElement, node.leftHandSide);
    _verifyNoDebugAssert(node.writeElement, node.leftHandSide);
    _verifyNoDebugAssert(node.staticElement, node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _verifyNoDebugAssert(node.staticElement, node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _verifyNoDebugAssert(node.staticElement, node);
    super.visitConstructorName(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    assert(classDeclaration == null);
    classDeclaration = node.declaredElement;
    assert(classDeclaration != null);
    try {
      super.visitClassDeclaration(node);
    } finally {
      classDeclaration = null;
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _verifyNoDebugAssert(node.element?.exportedLibrary, node);
    super.visitExportDirective(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    print(node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    switch (node.staticElement) {
      case MethodElement(:final name) when name == FunctionElement.CALL_METHOD_NAME:
       _verifyNoDebugAssert(node.staticElement, node);
      case _:
        break;
    }
    for (final argument in node.argumentList.arguments) {
      print('>> ${argument.staticParameterElement}: $argument');
      _verifyNoDebugAssert(argument.staticParameterElement, argument);
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _verifyNoDebugAssert(node.staticElement, node);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    //TODO
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _verifyNoDebugAssert(node.methodName.staticElement, node);
    for (final argument in node.argumentList.arguments) {
      _verifyNoDebugAssert(argument.staticParameterElement, argument);
    }
    //if (node.methodName.staticElement != null && _hasDebugAnnotation(node.methodName.staticElement!)) {
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _verifyNoDebugAssert(node.element, node);
    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _verifyNoDebugAssert(node.element, node);
    super.visitPatternField(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _verifyNoDebugAssert(node.readElement, node.operand);
    _verifyNoDebugAssert(node.writeElement, node.operand);
    _verifyNoDebugAssert(node.staticElement, node);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _verifyNoDebugAssert(node.readElement, node.operand);
    _verifyNoDebugAssert(node.writeElement, node.operand);
    _verifyNoDebugAssert(node.staticElement, node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _verifyNoDebugAssert(node.staticElement, node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _verifyNoDebugAssert(node.staticElement, node);
    //TODO
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    super.visitFunctionReference(node);
  }
}
