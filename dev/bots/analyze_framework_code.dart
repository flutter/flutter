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

    for (final String filePath in analyzedFilePaths) {
      final SomeResolvedUnitResult unit = await session.getResolvedUnit(filePath);
      if (unit is ResolvedUnitResult) {
        for (final ResolvedUnitVerifier verifier in verifiers) {
          verifier.analyzeResolvedUnitResult(unit, workingDirectory);
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
  void analyzeResolvedUnitResult(ResolvedUnitResult unit, String workingDirectory);
}

// ----------- Verify No double.clamp -----------

/// Verify that we use clampDouble instead of double.clamp for performance
/// reasons.
///
/// See also:
///   * https://github.com/flutter/flutter/pull/103559
///   * https://github.com/flutter/flutter/issues/103917
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
  void analyzeResolvedUnitResult(ResolvedUnitResult unit, String workingDirectory) {
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
      final String relativePath = path.relative(unit.path, from: workingDirectory);
      errors.add('$relativePath:$lineNumber: ${node.parent}');
    }
  }

  @override
  String toString() => 'No "double.clamp"';
}

class _DoubleClampVisitor extends RecursiveAstVisitor<void> {
  final List<AstNode> clampAccessNodes = <AstNode>[];

  // We don't care about directives or comments.
  @override
  void visitImportDirective(ImportDirective node) { }

  @override
  void visitExportDirective(ExportDirective node) { }

  @override
  void visitComment(Comment node) { }

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
  final List<String> accessErrors = <String>[];
  final List<String> annotationErrors = <String>[];
  @override
  void reportError() {
    if (annotationErrors.isNotEmpty) {
      foundError(<String>[
        '${bold}Overriding a framework class member that was not annotated with @_debugAssert and marking the override @_debugAssert is not allowed.$reset',
        '${bold}A framework method/getter/setter not marked as debug-only itself cannot have a debug-only override.$reset\n',
        ...annotationErrors,
        '\n${bold}Consider either removing the @_debugAssert annotation, or adding the annotation to the class member that is being overridden instead.$reset',
      ]);
    }
    if (accessErrors.isNotEmpty) {
      foundError(<String>[
        '${bold}Framework symbols annotated with @_debugAssert should not be accessed outside of asserts.$reset\n',
        ...accessErrors,
      ]);
    }
  }

  @override
  void analyzeResolvedUnitResult(ResolvedUnitResult unit, String workingDirectory) {
    if (unit.libraryElement.metadata.any(_DebugAssertVisitor._isDebugAssertAnnotationElement)) {
      return;
    }

    final Map<ExecutableElement, bool> lookup = <ExecutableElement, bool>{};
    final _DebugAssertVisitor visitor = _DebugAssertVisitor(lookup);
    unit.unit.visitChildren(visitor);
    final String relativePath = path.relative(unit.path, from: workingDirectory);
    for (final (AstNode node, Element element) in visitor.accessViolations) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.offset).lineNumber;
      final String name = switch (element) {
        ConstructorElement(:final InterfaceElement enclosingElement, isDefaultConstructor: true) => '${enclosingElement.name}.new',
        ExecutableElement(:final InterfaceElement enclosingElement, :final String name) => '${enclosingElement.name}.$name',
        Element(:final String? name) => name ?? '',
      };
      accessErrors.add('$relativePath:$lineNumber: $bold$name$reset accessed outside of an assert.');
    }

    for (final (String superImpl, String override) in visitor.incorrectAnnotations) {
      annotationErrors.add('$relativePath: class member $bold$superImpl$reset is not annotated wtih $bold@_debugAssert$reset, but its override $bold$override$reset is.');
    }
  }

  @override
  String toString() => 'No "_debugAssert" access in production code';
}

class _DebugAssertVisitor extends GeneralizingAstVisitor<void> {
  _DebugAssertVisitor(this.overridableMemberLookup);

  final Map<ExecutableElement, bool> overridableMemberLookup;

  final List<(AstNode, Element)> accessViolations = <(AstNode, Element)>[];
  final List<(String, String)> incorrectAnnotations = <(String, String)>[];

  static bool _isDebugAssertAnnotationElement(ElementAnnotation? annotation) {
    final Element? annotationElement = annotation?.element;
    return annotationElement is PropertyAccessorElement && annotationElement.name == '_debugAssert';
  }

  bool _overriddableClassMemberHasDebugAnnotation(ExecutableElement classMember, InterfaceElement enclosingElement) {
    assert(!enclosingElement.library.isInSdk);
    final bool? cached = overridableMemberLookup[classMember];
    if (cached != null) {
      return cached;
    }
    final bool isClassMemberAnnotated = enclosingElement.library.metadata.any(_isDebugAssertAnnotationElement)
                                     || classMember.metadata.any(_isDebugAssertAnnotationElement)
                                     || classMember.enclosingElement.metadata.any(_isDebugAssertAnnotationElement);

    bool isAnnotated = isClassMemberAnnotated;
    for (final InterfaceType supertype in enclosingElement.allSupertypes) {
      if (supertype.element.library.isInSdk) {
        continue;
      }
      final ExecutableElement? superImpl = switch (classMember) {
        MethodElement(:final String name)                           => supertype.getMethod(name),
        PropertyAccessorElement(:final String name, isGetter: true) => supertype.getGetter(name),
        PropertyAccessorElement(:final String name, isSetter: true) => supertype.getSetter(name),
        _ => throw StateError('not reachable $classMember(${classMember.runtimeType})'),
      };
      if (superImpl == null) {
        continue;
      }
      final bool isSuperImplAnnotated = _overriddableClassMemberHasDebugAnnotation(superImpl, supertype.element);
      if (isClassMemberAnnotated && !isSuperImplAnnotated) {
        incorrectAnnotations.add(('$supertype.${superImpl.name}', '${enclosingElement.name}.${classMember.name}'));
      }
      isAnnotated |= isSuperImplAnnotated;
    }

    return overridableMemberLookup[classMember] = isAnnotated;
  }

  bool _defaultConstructorHasDebugAnnotation(ConstructorElement constructorElement) {
    if (constructorElement.library.isInSdk) {
      return false;
    }
    final bool annotated = !constructorElement.isSynthetic
      && (constructorElement.library.metadata.any(_isDebugAssertAnnotationElement)
       || constructorElement.metadata.any(_isDebugAssertAnnotationElement)
       || constructorElement.enclosingElement.metadata.any(_isDebugAssertAnnotationElement));
    if (annotated) {
      return true;
    }
    // Subclasses can inherit default constructors from the superclass. Since
    // constructors can't be invoked by the class members (unlike methods that
    // can have "bad annotations"), if any superclass in the class hierarchy has
    // a default constructor (excluding synthesized ones) that has the
    // annotation, then the default constructor is debug-only.
    final ConstructorElement? superConstructor = constructorElement.enclosingElement.thisType.superclass?.element.unnamedConstructor;
    return superConstructor != null && _defaultConstructorHasDebugAnnotation(superConstructor);
  }

  bool _isDebugOnlyExecutableElement(Element element) {
    final LibraryElement? lib = element.library;
    if (lib == null || lib.isInSdk) {
      // The assert is for framework code only. Dart sdk symbols won't be annotated.
      return false;
    }

    switch (element) {
      // The easier cases: things that a subclass does not inherit from its
      // superclass: named constructors, static members, extension members.
      case ConstructorElement(isDefaultConstructor: false, :final Element enclosingElement)
        || ExecutableElement(isStatic: true, :final Element enclosingElement)
        || ClassMemberElement(enclosingElement: ExtensionElement() && final Element enclosingElement):
        return lib.metadata.any(_isDebugAssertAnnotationElement) || element.metadata.any(_isDebugAssertAnnotationElement) || enclosingElement.metadata.any(_isDebugAssertAnnotationElement);
      case ConstructorElement(isDefaultConstructor: true):
        return _defaultConstructorHasDebugAnnotation(element);
      // Non-static class memebers that are overridable. Also we want to detect
      // and warn against "bad annotations":
      // class A {
      //   int get a;
      //   int get b => a;
      // }
      // class B extends A {
      //   @_debugAssert
      //   int get a => 0;
      // }
      case ExecutableElement(:final InterfaceElement enclosingElement):
        assert(!element.isStatic);
        return _overriddableClassMemberHasDebugAnnotation(element, enclosingElement);
      // Non class members.
      case FieldElement() || ExecutableElement():
        assert(element.enclosingElement is! InterfaceElement);
        return lib.metadata.any(_isDebugAssertAnnotationElement) || element.metadata.any(_isDebugAssertAnnotationElement);
      default:
        return false;
    }
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
      if (element != null && _isDebugOnlyExecutableElement(element)) {
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
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add((node, element));
    }
    // Most symbols will be inspected in this method, with the exceptions of:
    //  * unamed constructors
    //  * prefix, binary, postfix operators, index access (e.g., ==, ~, list[index]),
    //    as they're tokens not identifiers.
    //  * assignments (to account for compound assignments the staticElement field is intentionally set to null)
  }

  @override
  void visitConstructorName(ConstructorName node) {
    final Element? element = node.staticElement;
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add((node, element));
    }
  }

 @override
  void visitBinaryExpression(BinaryExpression node) {
    final Element? element = node.staticElement;
    node.leftOperand.accept(this);
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add((node, element));
    }
    node.rightOperand.accept(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final Element? element = node.staticElement;
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add((node, element));
    }
    node.operand.accept(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    node.operand.accept(this);
    final Element? element = node.staticElement;
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add((node, element));
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    final Element? element = node.staticElement;
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add((node, element));
    }
    node.index.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final Element? readElement = node.readElement;
    final Element? writeElement = node.writeElement;
    final Element? operatorElement = node.staticElement;
    if (readElement != null && _isDebugOnlyExecutableElement(readElement)) {
      accessViolations.add((node, readElement));
    }
    if (writeElement != null && writeElement != readElement && _isDebugOnlyExecutableElement(writeElement)) {
      accessViolations.add((node, writeElement));
    }
    if (operatorElement != null && _isDebugOnlyExecutableElement(operatorElement)) {
      accessViolations.add((node, operatorElement));
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Special case toString.
    if (node.name.lexeme != 'toString' || node.isStatic) {
      super.visitMethodDeclaration(node);
    }
  }
}
