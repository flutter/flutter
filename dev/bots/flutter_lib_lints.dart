// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';

import 'utils.dart' show bold, foundError, printProgress, reset;

Future<void> parseFlutterLibAndAnalyze(String workingDirectory, List<ResolvedASTVerifier> verifiers) async {
  final String flutterLibPath = '$workingDirectory/packages/flutter/lib';
  final AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>[flutterLibPath],
    //includedPaths: <String>[flutterLibPath, '$workingDirectory/packages/flutter/pubspec.lock', '$workingDirectory/packages/flutter/pubspec.yaml'],
    excludedPaths: <String>['$flutterLibPath/fix_data'],
  );

  for (final AnalysisContext context in collection.contexts) {
    // Normalized paths to all analyzed files.
    final Iterable<String> analyzedFilePaths = context.contextRoot.analyzedFiles();
    final AnalysisSession session = context.currentSession;

    for (final String path in analyzedFilePaths) {
      final SomeResolvedUnitResult unit = await session.getResolvedUnit(path);
      for (final ResolvedASTVerifier verifier in verifiers) {
        if (unit is ResolvedUnitResult) {
          verifier.analyzeResolvedUnit(unit);
        } else {
          foundError(<String>['analyzer error: file $unit could not be resolved.']);
        }
      }
    }
  }

  for (final ResolvedASTVerifier verifier in verifiers) {
    verifier.reportErrors();
  }
}

abstract mixin class ResolvedASTVerifier {
  void analyzeResolvedUnit(ResolvedUnitResult unit);
  void reportErrors();
}

/// Verify that we use clampDouble instead of Double.clamp for performance reasons.
///
/// We currently can't distinguish valid uses of clamp from problematic ones so
/// if the clamp is operating on a type other than a `double` the
/// `// ignore_clamp_double_lint` comment must be added to the line where clamp is
/// invoked.
///
/// See also:
///   * https://github.com/flutter/flutter/pull/103559
///   * https://github.com/flutter/flutter/issues/103917
final ResolvedASTVerifier verifyNoDoubleClamp = _NoDoubleClampVerifier();
final class _NoDoubleClampVerifier extends ResolvedASTVerifier {
  final List<String> errors = <String>[];

  @override
  void analyzeResolvedUnit(ResolvedUnitResult unit) {
    final _DoubleClampVisitor visitor = _DoubleClampVisitor();
    unit.unit.visitChildren(visitor);
    for (final MethodInvocation node in visitor.doubleClampInvocations) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.function.offset).lineNumber;
      final String lineContent = unit.content.substring(
        lineInfo.getOffsetOfLine(lineNumber - 1),
        lineInfo.getOffsetOfLine(lineNumber) - 1,
      );
      if (lineContent.contains('// ignore_clamp_double_lint')) {
        continue;
      }
      errors.add('${unit.path}:$lineNumber: "Double.clamp" method used instead of "clampDouble".');
    }
  }

  @override
  void reportErrors() {
    if (errors.isEmpty) {
      return;
    }
    foundError(<String>[
      ...errors,
      '\n${bold}For performance reasons, we use a custom "clampDouble" function instead of using "Double.clamp".$reset',
      '\n${bold}For non-double uses of "clamp", use "// ignore_clamp_double_lint" on the line to silence this message.$reset',
    ]);
  }

  @override
  String toString() => 'No Double.clamp';
}

// The AST visitor for traversing the resolved AST of a file.
final class _DoubleClampVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> doubleClampInvocations = <MethodInvocation>[];

  @override
  CompilationUnit? visitMethodInvocation(MethodInvocation node) {
    final bool isDoubleClampInvocation = node.methodName.name == 'clamp' && (node.target?.staticType?.isDartCoreDouble ?? false);
    if (isDoubleClampInvocation) {
      doubleClampInvocations.add(node);
    }
    node.visitChildren(this);
    return null;
  }
}

final ResolvedASTVerifier verifyNoDebugAssertInProductionCode = _DebugAssertVerifier();
final class _DebugAssertVerifier extends ResolvedASTVerifier {
  final List<String> errors = <String>[];

  @override
  void analyzeResolvedUnit(ResolvedUnitResult unit) {
    final _DebugAssertVisitor visitor = _DebugAssertVisitor();
    unit.unit.visitChildren(visitor);
    for (final node in visitor.badDeclarations) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.offset).lineNumber;
      errors.add('${unit.path}:$lineNumber bad annotation "@debugAssert".');
    }

    for (final MethodInvocation node in visitor.badInvocations) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.function.offset).lineNumber;
      errors.add('${unit.path}:$lineNumber: Avoid calling methods annotated with "@debugAssert" in production code or public methods.');
    }
  }

  @override
  void reportErrors() {
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
  String toString() => 'Avoid calling debug-only methods in production code';
}

final class _DebugAssertVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> badInvocations = <MethodInvocation>[];
  final List<Annotation> badDeclarations = <Annotation>[];

  static bool _hasDebugAssertAnnotation(Annotation annotation) => annotation.name.name == '_debugAssert';
  static bool _hasDebugAssertElementAnnotation(ElementAnnotation annotation) => annotation.element?.name == '_debugAssert';

  static List<ElementAnnotation> _rareAnnotation(Element? element) {
    const Set negative = { 'protected', 'override', 'mustCallSuper', 'Deprecated'  };
    return element?.metadata.where((element) => !negative.contains(element.element?.name)).toList() ?? <ElementAnnotation>[];
  }

  void _warnIfPublic(Element? declarationElement, Annotation node) {
    if (declarationElement != null && declarationElement.isPublic) {
      badDeclarations.add(node);
    }
  }

  Token? className;
  @override
  void visitClassDeclaration(ClassDeclaration node) {
    assert(className == null);
    className = node.name;
    super.visitClassDeclaration(node);
    className = null;
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    // Neither the condition or the message will be evaluated.
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final annotations = node.metadata.where(_hasDebugAssertAnnotation);
    if (annotations.isNotEmpty) {
      for (final annotation in annotations) {
        _warnIfPublic(node.declaredElement, annotation);
      }
      return;
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    //if (node.metadata.any(_hasDebugAssertAnnotation)) {
    //  badDeclarations.add(declarationElement);
    //  return;
    //}
    // node.declaredElement is always null??????????
    //if (node.declaredElement == null) {
    //  print('$className | $node -> no declaredElement?');
    //}
    //if (node.declaredElement?.isPublic ?? false) {
    //  print('>>> public field $className.$node');
    //}
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.declaredElement == null) {
      print('$className | $node -> no declaredElement?');
    }

    super.visitFunctionDeclaration(node);
  }

  // Invocation

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final Element? methodElement = node.methodName.staticElement;
    if (methodElement != null) {
      methodElement.metadata.any(_hasDebugAssertElementAnnotation);
    } else {
      //print('unresolved > $node');
    }
    //final rareAnnotations = _rareAnnotation(node.methodName.staticElement);
    //if (rareAnnotations.isNotEmpty) {
    //  print('$node');
    //}
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final ExecutableElement? callElement = node.staticElement;
    if (callElement != null) {
      print('$node -> callElement: $callElement');
    } else {
      //print('? $node');
    }
    if (callElement is MethodElement && callElement.name == FunctionElement.CALL_METHOD_NAME) {
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    print('func ref -> $node');
    super.visitFunctionReference(node);
  }
}
