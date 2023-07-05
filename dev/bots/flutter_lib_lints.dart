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
import 'package:path/path.dart' as path;

import 'utils.dart';

Future<void> runVerifiersInResolvedDirectory(String workingDirectory, List<ResolvedUnitVerifier> verifiers) async {
  final String flutterLibPath = path.canonicalize('$workingDirectory/packages/flutter/lib');
  final AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>[flutterLibPath],
    excludedPaths: <String>['$flutterLibPath/fix_data'],
  );

  final List<String> analyzerErrors = <String>[];
  for (final AnalysisContext context in collection.contexts) {
    final Iterable<String> analyzedFilePaths = context.contextRoot.analyzedFiles();
    final AnalysisSession session = context.currentSession;

    for (final String path in analyzedFilePaths) {
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
      errors.add('${unit.path}:$lineNumber: ${node.parent}');
    }
  }

  @override
  String toString() => 'No "double.clamp"';
}

class _DoubleClampVisitor extends RecursiveAstVisitor<void> {
  final List<AstNode> clampAccessNodes = <AstNode>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != 'clamp' || node.staticElement is! MethodElement) {
      return;
    }
    switch (node.parent) {
      // PropertyAccess matches num.clamp in tear-off form. Always prefer
      // doubleClamp over tear-offs: even when all 3 operands are int literals,
      // the return type doesn't get promoted to int:
      // final x = 1.clamp(0, 2); // The inferred return type is int.
      // final f = 1.clamp;
      // final y = f(0, 2)       // The inferred return type is num.
      case PropertyAccess(
        target: Expression(staticType: DartType(isDartCoreDouble: true) || DartType(isDartCoreNum: true) || DartType(isDartCoreInt: true)),
      ):
        clampAccessNodes.add(node);
      case MethodInvocation(
        target: Expression(staticType: DartType(isDartCoreInt: true)),
        argumentList: ArgumentList(arguments: [Expression(staticType: DartType(isDartCoreInt: true)), Expression(staticType: DartType(isDartCoreInt: true))]),
      ):
        // Expressions such as `final int x = 1.clamp(0, 2);` should be allowed.
        // Do nothing.
        break;
      case MethodInvocation(
        target: Expression(staticType: DartType(isDartCoreDouble: true) || DartType(isDartCoreNum: true) || DartType(isDartCoreInt: true)),
      ):
        clampAccessNodes.add(node);
      case _:
        break;
    }
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
      '\n${bold}Components annotated with @_debugAssert.$reset\n',
      ...errors,
    ]);
  }

  @override
  void analyzeResolvedUnitResult(ResolvedUnitResult unit) {
    if (_DebugAssertVisitor._hasDebugAnnotation(unit.libraryElement)) {
      return;
    }

    final _DebugAssertVisitor visitor = _DebugAssertVisitor();
    unit.unit.visitChildren(visitor);
    for (final AstNode node in visitor.violations) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.offset).lineNumber;
      errors.add('${unit.path}:$lineNumber: ${node.parent ?? node}');
    }
  }

  @override
  String toString() => 'No "_debugAssert" access in production code';
}

class _DebugAssertVisitor extends GeneralizingAstVisitor<void> {
  List<AstNode> violations = <AstNode>[];

  static bool _isDebugAssertAnnotationElement(ElementAnnotation? annotation) {
    final Element? annotationElement = annotation?.element;
    return annotationElement is PropertyAccessorElement && annotationElement.name == '_debugAssert';
  }

  static bool _supertypeHasDebugAnnotation(InterfaceType supertype, ExecutableElement classMember) {
    if (supertype.element.library.isInSdk) {
      return false;
    }
    switch (classMember) {
      case ConstructorElement(): return false;
      case MethodElement(:final String name):
        final MethodElement? method = supertype.getMethod(name);
        return method != null && _hasDebugAnnotation(method);
      case PropertyAccessorElement(:final String name, isGetter: true):
        final PropertyAccessorElement? property = supertype.getGetter(name);
        return property != null && _hasDebugAnnotation(property);
      case PropertyAccessorElement(:final String name, isSetter: true):
        final PropertyAccessorElement? property = supertype.getSetter(name);
        //print('\t property ${supertype.name}.$name $property (all methods: ${supertype.methods}, all accessors: ${supertype.accessors}, )');
        return property != null && _hasDebugAnnotation(property);
      case _: throw StateError('not reachable $classMember(${classMember.runtimeType})');
    }
  }

  static bool _hasDebugAnnotation(Element element) {
    final LibraryElement? lib = element.library;
    // Only search if the element is defined in the framework.
    if (lib == null || lib.isInSdk) {
      return false;
    }
    if (lib.metadata.any(_isDebugAssertAnnotationElement) || element.metadata.any(_isDebugAssertAnnotationElement)) {
      return true;
    }

    final Element? enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) {
      return false;
    } else if (_hasDebugAnnotation(enclosingElement)) {
      return true;
    }

    return element is ExecutableElement
        && !element.isStatic
        && enclosingElement.allSupertypes.any((final InterfaceType type) => _supertypeHasDebugAnnotation(type, element));
  }

  static bool _isValidElementType(Element element) {
    return switch (element) {
      FieldElement() || ExecutableElement() => true,
      _ => false,
    };
  }

  // Accessing debugAsserts in asserts (either in the condition or the message)
  // is allowed.
  @override
  void visitAssertInitializer(AssertInitializer node) { }
  @override
  void visitAssertStatement(AssertStatement node) { }

  // We don't care about directives or comments.
  @override
  void visitDirective(Directive node) { }
  @override
  void visitComment(Comment node) { }

  @override
  void visitAnnotatedNode(AnnotatedNode node) {
    if (node is ClassMember) {
      final Element? element = node.declaredElement;
      if (element != null && _hasDebugAnnotation(element)) {
        return;
      }
    } else if (node.metadata.any((Annotation m) => _isDebugAssertAnnotationElement(m.elementAnnotation))) {
      return;
    }

    // Only continue searching if the declaration doesn't have @_debugAssert.
    return super.visitAnnotatedNode(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final Element? element = node.staticElement;
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      violations.add(node);
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    final Element? element = node.staticElement;
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      violations.add(node);
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    print('func exp invo: $node(${node.runtimeType})');
    super.visitFunctionExpressionInvocation(node);
  }

 @override
  void visitBinaryExpression(BinaryExpression node) {
    final Element? element = node.staticElement;
    node.leftOperand.accept(this);
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      violations.add(node);
    }
    node.rightOperand.accept(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final Element? element = node.staticElement;
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      violations.add(node);
    }
    node.operand.accept(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    node.operand.accept(this);
    final Element? element = node.staticElement;
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      violations.add(node);
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    final Element? element = node.staticElement;
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      violations.add(node);
    }
    node.index.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final Element? readElement = node.readElement;
    final Element? writeElement = node.writeElement;
    final Element? operatorElement = node.staticElement;
    final bool hasDebugAsserts = readElement != null && _hasDebugAnnotation(readElement)
                              || (writeElement != null && writeElement != readElement && _hasDebugAnnotation(writeElement))
                              || (operatorElement != null && _hasDebugAnnotation(operatorElement) && _isValidElementType(operatorElement));
    if (hasDebugAsserts) {
      violations.add(node);
    } else {
      super.visitAssignmentExpression(node);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'toString' || node.isStatic) {
      super.visitMethodDeclaration(node);
    }
  }
}
