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
    if (unit.libraryElement.metadata.any(_DebugAssertVisitor._isDebugAssertAnnotationElement)) {
      return;
    }

    final Map<ExecutableElement, bool> lookup = <ExecutableElement, bool>{};
    final _DebugAssertVisitor visitor = _DebugAssertVisitor(lookup);
    unit.unit.visitChildren(visitor);
    for (final (AstNode node, Element element) in visitor.accessViolations) {
      final LineInfo lineInfo = unit.lineInfo;
      final int lineNumber = lineInfo.getLocation(node.offset).lineNumber;
      errors.add('${unit.path}:$lineNumber: $element');
    }
  }

  @override
  String toString() => 'No "_debugAssert" access in production code';
}

class _DebugAssertVisitor extends GeneralizingAstVisitor<void> {
  _DebugAssertVisitor(this.overridableMemberLookup);
  final Map<ExecutableElement, bool> overridableMemberLookup;
  List<(AstNode, Element)> accessViolations = <(AstNode, Element)>[];

  static bool _isDebugAssertAnnotationElement(ElementAnnotation? annotation) {
    final Element? annotationElement = annotation?.element;
    return annotationElement is PropertyAccessorElement && annotationElement.name == '_debugAssert';
  }

  bool _overriddableClassMemberHasDebugAnnotation(ExecutableElement classMember, InterfaceElement enclosingElement) {
    assert(!enclosingElement.library.isInSdk, '$enclosingElement (${enclosingElement.runtimeType}) is defined in ${enclosingElement.library}');
    final bool? cached = overridableMemberLookup[classMember];
    if (cached != null) {
      return cached;
    }
    final bool isClassMemberAnnotated = enclosingElement.library.metadata.any(_isDebugAssertAnnotationElement)
                                     || classMember.metadata.any(_isDebugAssertAnnotationElement)
                                     || _hasDebugAnnotation(classMember.enclosingElement);

    //print('> Looking for override. ${enclosingElement.name}.$classMember (${classMember.runtimeType} @ $enclosingElement, synthetic: ${classMember.isSynthetic}) is annotated? $isClassMemberAnnotated. Checking supertypes ${enclosingElement.allSupertypes})');

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
        print('!!!!!!!!! bad: ${enclosingElement.name}.${classMember.name} is annotated but $supertype.${superImpl.name}(${supertype.element.runtimeType}, ${superImpl.runtimeType}) is not');
      }
      isAnnotated |= isSuperImplAnnotated;
    }

    return overridableMemberLookup[classMember] = isAnnotated;
    //if (supertype == null || supertype.element.library.isInSdk) {
    //  return classMemberLookup[classMember] = isAnnotated;
    //}

    //print('\t $supertype => $superImpl');
    //if (superImpl != null && _hasDebugAnnotation(superImpl)) {
    //  return classMemberLookup[classMember] = isAnnotated;
    //} else if (superImpl != null && !_hasDebugAnnotation(superImpl) && isAnnotated) {
    //  print('!!!!!!!!! bad: ${enclosingElement.name}.$classMember is annotated but $superImpl(${superImpl.runtimeType}) is not');
    //  return classMemberLookup[classMember] = true;
    //} else {
    //  return classMemberLookup[classMember] = isAnnotated || (superImpl != null && _hasDebugAnnotation(superImpl));
    //}
  }

  bool _defaultConstructorHasDebugAnnotation(ConstructorElement constructorElement) {
    if (constructorElement.library.isInSdk) {
      return false;
    }
    final bool annotated = !constructorElement.isSynthetic
      && (constructorElement.library.metadata.any(_isDebugAssertAnnotationElement)
       || constructorElement.metadata.any(_isDebugAssertAnnotationElement)
       || _hasDebugAnnotation(constructorElement.enclosingElement));
    if (annotated) {
      return true;
    }
    // Subclasses can inherit default constructors from the superclass. Since
    // constructors can't be invoked by the class members (see the next case
    // for an example), if any superclass in the class hierarchy has a default
    // constructor (including synthesized ones) that has the annotation, then
    // the default constructor is debug-only.
    final ConstructorElement? superConstructor = constructorElement.enclosingElement.thisType.superclass?.element.unnamedConstructor;
    return superConstructor != null && _defaultConstructorHasDebugAnnotation(superConstructor);
  }

  bool _hasDebugAnnotation(Element element) {
    final LibraryElement? lib = element.library;
    if (lib == null || lib.isInSdk) {
      // The assert is for framework code only. Dart sdk symbols won't be annotated.
      return false;
    }

    switch (element) {
      // The easier cases: things that a subclass does not inherit from its
      // superclass: named constructors and static members, extension members.
      case ConstructorElement(isDefaultConstructor: false, :final Element enclosingElement)
        || ExecutableElement(isStatic: true, :final Element enclosingElement):
        //print('EZ: $element. enclosing element: $enclosingElement');
        return lib.metadata.any(_isDebugAssertAnnotationElement) || element.metadata.any(_isDebugAssertAnnotationElement) || _hasDebugAnnotation(enclosingElement);
      case ConstructorElement(isDefaultConstructor: true):
        return _defaultConstructorHasDebugAnnotation(element);
      // Non-static class memebers that are overridable. Also we want to detect
      // and warn against cases like this:
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
        //print('Overridable element check: ${enclosingElement.name}.$element (${element.runtimeType})');
        return _overriddableClassMemberHasDebugAnnotation(element, enclosingElement);
      case ClassMemberElement(:final ExtensionElement enclosingElement):
        return lib.metadata.any(_isDebugAssertAnnotationElement) || element.metadata.any(_isDebugAssertAnnotationElement) || _hasDebugAnnotation(enclosingElement);
      // Non class members, fields(?), type parameters
      default:
      //if (element.enclosingElement is! CompilationUnitElement && element is ExecutableElement) {
      //  print('!!! default case. $element (${element.runtimeType} is ClassMemberElement? ${element is ClassMemberElement}). enclosing element: ${element.enclosingElement} (${element.enclosingElement.runtimeType})');
      //}
        return lib.metadata.any(_isDebugAssertAnnotationElement) || element.metadata.any(_isDebugAssertAnnotationElement);
    }
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
      accessViolations.add((node, element));
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    final Element? element = node.staticElement;
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      accessViolations.add((node, element));
    }
  }

 @override
  void visitBinaryExpression(BinaryExpression node) {
    final Element? element = node.staticElement;
    node.leftOperand.accept(this);
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      accessViolations.add((node, element));
    }
    node.rightOperand.accept(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final Element? element = node.staticElement;
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      accessViolations.add((node, element));
    }
    node.operand.accept(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    node.operand.accept(this);
    final Element? element = node.staticElement;
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      accessViolations.add((node, element));
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    final Element? element = node.staticElement;
    if (element != null && _hasDebugAnnotation(element) && _isValidElementType(element)) {
      accessViolations.add((node, element));
    }
    node.index.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final Element? readElement = node.readElement;
    final Element? writeElement = node.writeElement;
    final Element? operatorElement = node.staticElement;
    if (readElement != null && _hasDebugAnnotation(readElement)) {
      accessViolations.add((node, readElement));
    }
    if (writeElement != null && writeElement != readElement && _hasDebugAnnotation(writeElement)) {
      accessViolations.add((node, writeElement));
    }
    if (operatorElement != null && _hasDebugAnnotation(operatorElement) && _isValidElementType(operatorElement)) {
      accessViolations.add((node, operatorElement));
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'toString' || node.isStatic) {
      super.visitMethodDeclaration(node);
    }
  }
}
