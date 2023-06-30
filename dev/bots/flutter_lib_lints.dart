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
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';

import 'utils.dart';

Future<void> runVerifiersInResolvedDirectory(String workingDirectory, List<ResolvedUnitVerifier> verifiers) async {
  final String flutterLibPath = '$workingDirectory/packages/flutter/lib';
  final AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>[flutterLibPath],
    excludedPaths: <String>['$flutterLibPath/fix_data'],
  );

  final List<String> analyzerErrors = <String>[];
  for (final AnalysisContext context in collection.contexts) {
    final Iterable<String> analyzedFilePaths = context.contextRoot.analyzedFiles();
    final AnalysisSession session = context.currentSession;

    for (final String path in analyzedFilePaths) {
      if (!path.endsWith('text_painter.dart')) {
        continue;
      }
      final SomeResolvedUnitResult unit = await session.getResolvedUnit(path);
      if (unit is ResolvedUnitResult) {
        for (final ResolvedUnitVerifier verifier in verifiers) {
          verifier.analyzeResolvedUnitResult(unit);
        }
      } else {
        analyzerErrors.add('Analyzer error: file $unit could not be resolved.');
      }
    }
  }

  if (analyzerErrors.isNotEmpty) {
    foundError(analyzerErrors);
  }
  for (final ResolvedUnitVerifier verifier in verifiers) {
    verifier.reportError();
  }
}

abstract class ResolvedUnitVerifier {
  void reportError();
  void analyzeResolvedUnitResult(ResolvedUnitResult unit);
}

// ----------- Verify No double.clamp -----------

final ResolvedUnitVerifier verifyNoDoubleClamp = _NoDoubleClampVerifier();
class _NoDoubleClampVerifier implements ResolvedUnitVerifier {
  final List<String> errors = <String>[];

  @override
  void reportError() {
    if (errors.isEmpty) {
      return;
    }
    foundError(<String>[
      ...errors,
      '\n${bold}For performance reasons, we use a custom "clampDouble" function instead of using "double.clamp".$reset',
      '\n${bold}For non-double uses of "clamp", use "// ignore_clamp_double_lint" on the line to silence this message.$reset',
    ]);
  }

  @override
  void analyzeResolvedUnitResult(ResolvedUnitResult unit) {
    final _DoubleClampVisitor visitor = _DoubleClampVisitor();
    unit.unit.visitChildren(visitor);
    for (final AstNode node in visitor.clampAccessNodes) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.offset).lineNumber;
      final String lineContent = unit.content.substring(
        lineInfo.getOffsetOfLine(lineNumber - 1),
        lineInfo.getOffsetOfLine(lineNumber) - 1,
      );
      if (lineContent.contains('// ignore_clamp_double_lint')) {
        continue;
      }
      errors.add('${unit.path}:$lineNumber: "double.clamp" method used instead of "clampDouble".');
    }
  }

  @override
  String toString() => 'No "double.clamp"';
}

class _DoubleClampVisitor extends RecursiveAstVisitor<void> {
  final List<AstNode> clampAccessNodes = <AstNode>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    switch (node) {
      case SimpleIdentifier(
          name: 'clamp',
          staticElement: MethodElement(),
          // PropertyAccess matches the tearOff form of num.clamp. In this form
          parent: PropertyAccess(target:Expression(staticType: DartType(isDartCoreDouble: true) || DartType(isDartCoreNum: true) || DartType(isDartCoreInt: true)))
              ||  MethodInvocation(target:Expression(staticType: DartType(isDartCoreDouble: true) || DartType(isDartCoreNum: true)))
        ):
        // In tearOff forms it's difficult to tell the ???
        // Example:
        // final fs = [1.clamp, 2.clamp, 3.clamp, 4.clamp];
        // fs2.map((f) => f(11.1, 11.2));
        clampAccessNodes.add(node);
      case SimpleIdentifier(
          name: 'clamp',
          staticElement: MethodElement(),
          parent: MethodInvocation(target:Expression(staticType: DartType(isDartCoreInt: true)))
        ):
        //clampAccessNodes.add(node);
        print('sus: ${node.tearOffTypeArgumentTypes}');
      case SimpleIdentifier():
    }
    super.visitSimpleIdentifier(node);
  }
}

// ----------- Verify No _debugAssert -----------

final ResolvedUnitVerifier verifyDebugAssertAccess = _DebugAssertVerifier();
class _DebugAssertVerifier extends ResolvedUnitVerifier {
  final List<String> errors = <String>[];
  @override
  void reportError() {
    if (errors.isEmpty) {
      return;
    }
    foundError(<String>[
      ...errors,
      '\n${bold}Components annotated with @_debugAssert.$reset',
    ]);
  }

  @override
  void analyzeResolvedUnitResult(ResolvedUnitResult unit) {
    final _DebugAssertVisitor visitor = _DebugAssertVisitor();
    unit.unit.visitChildren(visitor);
    for (final AstNode node in visitor.violations) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.offset).lineNumber;
      errors.add('${unit.path}:$lineNumber: invalid debugAssert access: $node');
    }
  }

  @override
  String toString() => 'No "_debugAssert" access in production code';
}

bool _isDebugAssertAnnotationElement(ElementAnnotation? annotation) {
  final Element? annotationElement = annotation?.element;
  return annotationElement is PropertyAccessorElement && annotationElement.name == '_debugAssert';
}

bool _hasDebugAnnotation(Element element) => element.metadata.any(_isDebugAssertAnnotationElement);
bool _containsDebugAnnotation(AnnotatedNode node) => node.metadata.any((Annotation m) => _isDebugAssertAnnotationElement(m.elementAnnotation));

bool _isDebug(Element element) {
  return switch (element) {
    PropertyAccessorElement(:final PropertyInducingElement variable) => _hasDebugAnnotation(element) || _hasDebugAnnotation(variable),
    MethodElement()                          => _hasDebugAnnotation(element),
    ExecutableElement()                      => _hasDebugAnnotation(element),
    _                                        => false,
  } ;
}

class _DebugAssertVisitor extends RecursiveAstVisitor<void> {
  List<AstNode> violations = <AstNode>[];

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

  // Accessing debugAsserts in asserts (either in the condition or the message)
  // is allowed.
  @override
  void visitAssertInitializer(AssertInitializer node) {}
  @override
  void visitAssertStatement(AssertStatement node) { }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!_containsDebugAnnotation(node)) {
      // Only continue searching if the method doesn't have @_debugAssert.
      super.visitMethodDeclaration(node);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!_containsDebugAnnotation(node)) {
      // Only continue searching if the function doesn't have @_debugAssert.
      super.visitFunctionDeclaration(node);
    }
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

  //@override
  //void visitExportDirective(ExportDirective node) {
  //  _verifyNoDebugAssert(node.element?.exportedLibrary, node);
  //  super.visitExportDirective(node);
  //}

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    switch (node.staticElement) {
      case MethodElement(:final name) when name == FunctionElement.CALL_METHOD_NAME:
       _verifyNoDebugAssert(node.staticElement, node);
      case _:
        break;
    }
    for (final argument in node.argumentList.arguments) {
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
