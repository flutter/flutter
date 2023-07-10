// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

import '../utils.dart';
import 'analyze.dart';

/// An [AnalyzeRule] that verifies annotated getters, setters, constructors,
/// functions, methods are only directly or indirectly called inside asserts.
///
/// The annotation can also be applied to [InterfaceElement]s (classes, mixins
/// and extensions), in which case all explicitly defined class members will be
/// marked as debug-only. If the annotation is
final AnalyzeRule debugAssert = _DebugAssert();

class _DebugOnlySymbolAccessError {
  _DebugOnlySymbolAccessError(this.unit, this.node, this.symbol)
    : assert(symbol is ExecutableElement || symbol is FieldElement, '$symbol (${symbol.runtimeType}) unexpected element type.');

  final ResolvedUnitResult unit;
  final AstNode node;
  /// The Element that corresponds to [node].
  final Element symbol;

  String errorMessage(String workingDirectory) {
    final String relativePath = path.relative(path.relative(unit.path, from: workingDirectory));
    final int lineNumber = unit.lineInfo.getLocation(node.offset).lineNumber;
    final String symbolName = switch (symbol) {
      ConstructorElement(:final InterfaceElement enclosingElement, name: '') => '${enclosingElement.name}.new',
      ExecutableElement(:final InterfaceElement enclosingElement, :final String name) => '${enclosingElement.name}.$name',
      Element(:final String? name) => name ?? '',
    };
    return '$relativePath:$lineNumber: $bold$symbolName$reset accessed outside of an assert.';
  }
}

class _IncorrectAnnotationError {
  const _IncorrectAnnotationError(this.supertypeSymbol, this.symbol);
  final Element supertypeSymbol;
  final Element symbol;

  String errorMessage(String workingDirectory) {
    final String? source = symbol.librarySource?.fullName;
    final String? relativePath = source == null ? null :  path.relative(path.relative(source, from: workingDirectory));
    final String superSymbol = '${supertypeSymbol.enclosingElement?.name}.${supertypeSymbol.name}';
    final String overrideSymbol = '${symbol.enclosingElement?.name}.${symbol.name}';
    return '$relativePath: class member $bold$superSymbol$reset is not annotated wtih $bold@_debugAssert$reset,'
           ' but its override $bold$overrideSymbol$reset is.';
  }
}

class _DebugAssert extends AnalyzeRule {
  final List<_IncorrectAnnotationError> _annotationErrors = <_IncorrectAnnotationError>[];
  final List<_DebugOnlySymbolAccessError> _accessErrors = <_DebugOnlySymbolAccessError>[];

  final Map<ExecutableElement, bool> _lookup = <ExecutableElement, bool>{};

  @override
  void reportViolations(String workingDirectory) {
    if (_annotationErrors.isNotEmpty) {
      foundError(<String>[
        '${bold}Overriding a framework class member that was not annotated with @_debugAssert and marking the override @_debugAssert is not allowed.$reset',
        '${bold}A framework method/getter/setter not marked as debug-only itself cannot have a debug-only override.$reset\n',
        ..._annotationErrors.map((_IncorrectAnnotationError e) => e.errorMessage(workingDirectory)),
        '\n${bold}Consider either removing the @_debugAssert annotation, or adding the annotation to the class member that is being overridden instead.$reset',
      ]);
    }

    if (_accessErrors.isNotEmpty) {
      foundError(<String>[
        '${bold}Framework symbols annotated with @_debugAssert must not be accessed outside of asserts.$reset\n',
        ..._accessErrors.map((_DebugOnlySymbolAccessError e) => e.errorMessage(workingDirectory)),
      ]);
    }
  }

  @override
  void applyTo(ResolvedUnitResult unit) {
    if (unit.libraryElement.metadata.any(_DebugAssertVisitor._isDebugAssertAnnotationElement)) {
      return;
    }
    final _DebugAssertVisitor visitor = _DebugAssertVisitor(unit, _lookup);
    unit.unit.visitChildren(visitor);
    _annotationErrors.addAll(visitor.incorrectAnnotations);
    _accessErrors.addAll(visitor.accessViolations);
  }

  @override
  String toString() => 'No "_debugAssert" access in production code';
}

class _DebugAssertVisitor extends GeneralizingAstVisitor<void> {
  _DebugAssertVisitor(this.unit, this.overridableMemberLookup);

  final List<_DebugOnlySymbolAccessError> accessViolations = <_DebugOnlySymbolAccessError>[];
  final List<_IncorrectAnnotationError> incorrectAnnotations = <_IncorrectAnnotationError>[];

  final ResolvedUnitResult unit;
  final Map<ExecutableElement, bool> overridableMemberLookup;

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
        incorrectAnnotations.add(_IncorrectAnnotationError(superImpl, classMember));
      }
      isAnnotated |= isSuperImplAnnotated;
    }

    return overridableMemberLookup[classMember] = isAnnotated;
  }

  bool _syntheticConstructorHasDebugAnnotation(ConstructorElement constructorElement) {
    assert(constructorElement.isSynthetic);
    assert(constructorElement.isDefaultConstructor);
    if (constructorElement.library.isInSdk) {
      return false;
    }

    assert(!constructorElement.isFactory);
    assert(constructorElement.isDefaultConstructor);

    // Subclasses can "inherit" default constructors from the superclass. Since
    // constructors can't be invoked by the class members (unlike methods that
    // can have "bad annotations"), if any superclass in the class hierarchy has
    // a default constructor (excluding synthesized ones) that has the
    // annotation, then the default constructor is debug-only.
    final ConstructorElement? superConstructor = constructorElement.enclosingElement.thisType
      .superclass?.element.constructors
      .firstWhereOrNull((ConstructorElement constructor) => constructor.isDefaultConstructor);
    return superConstructor != null && _isDebugOnlyExecutableElement(superConstructor);
  }

  bool _isDebugOnlyExecutableElement(Element element) {
    final LibraryElement? lib = element.library;
    if (lib == null || lib.isInSdk) {
      // The assert is for framework code only. Dart sdk symbols won't be annotated.
      return false;
    }

    switch (element) {
      // Constructors are static in nature so there won't be any "bad annotations"
      // (see the non-static ExecutableElement case), but a default synthetic
      // constructor shouldn't be considered debug-only unless any of its
      // superclasses's default constructor is not synthetic and has the debug
      // annotation.
      case ConstructorElement(isSynthetic: true):
        return _syntheticConstructorHasDebugAnnotation(element);
      // The easier cases: non-overridable class members: static members,
      // extension members, non-synthetic constructors.
      case ExecutableElement(isStatic: true, :final Element enclosingElement)
        || ConstructorElement(:final Element enclosingElement)
        || ClassMemberElement(enclosingElement: ExtensionElement() && final Element enclosingElement):
        return lib.metadata.any(_isDebugAssertAnnotationElement) || element.metadata.any(_isDebugAssertAnnotationElement) || enclosingElement.metadata.any(_isDebugAssertAnnotationElement);
      // Non-static, overridable class memebers. Call to these members can be
      // polymorphic so we want to detect and warn against "bad annotations":
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
      // Non class members and fields (which we assume isn't overridable).
      case FieldElement() || ExecutableElement():
        assert(element is FieldElement || element.enclosingElement is! InterfaceElement);
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
      accessViolations.add(_DebugOnlySymbolAccessError(unit, node, element));
    }
    // Most symbols will be inspected in this method, with the exceptions of:
    //  * unamed constructors invocations.
    //  * implicit super/redirecting constructor invocations in another constructor.
    //  * initializing formal parameters.
    //  * prefix, binary, postfix operators, index access (e.g., ==, ~, list[index]),
    //    as they're tokens not identifiers.
    //  * assignments (to account for compound assignments the staticElement field is intentionally set to null)
  }

  @override
  void visitConstructorName(ConstructorName node) {
    final Element? element = node.staticElement;
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add(_DebugOnlySymbolAccessError(unit, node, element));
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final Element? element = node.declaredElement;
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      return;
    }

    if (node.factoryKeyword != null || element is! ConstructorElement) {
      node.visitChildren(this);
      return;
    }

    for (final FormalParameter parameter in node.parameters.parameters) {
      switch (parameter) {
        case FieldFormalParameter(name: Token(:final String lexeme))
          // Default values are Expressions so they should be covered by the
          // simple identifier visitor.
          || DefaultFormalParameter(parameter: FieldFormalParameter(name: Token(:final String lexeme))):
            final FieldElement? field = element.enclosingElement.getField(lexeme);
            assert(field != null);
            if (field != null && _isDebugOnlyExecutableElement(field)) {
              accessViolations.add(_DebugOnlySymbolAccessError(unit, node, field));
            }
        case _:
      }
    }

    node.visitChildren(this);

    final bool hasExplicitConstructor = node.initializers.any((ConstructorInitializer element) => switch (element) {
      SuperConstructorInvocation()       => true,
      RedirectingConstructorInvocation() => true,
      _                                  => false,
    });

    // If this constructor does not invoke any constructor in the initializer
    // list, then it calls the unnamed constructor from the super class
    // implicitly.
    if (!hasExplicitConstructor) {
      final InterfaceType? supertype = element.enclosingElement.supertype;
      if (supertype != null && !supertype.element.library.isInSdk) {
        final ConstructorElement? unnamedSuperConstructor = supertype.constructors
          .firstWhereOrNull((ConstructorElement element) => element.name == '' && !element.isFactory);
        if (unnamedSuperConstructor != null && _isDebugOnlyExecutableElement(unnamedSuperConstructor)) {
          accessViolations.add(_DebugOnlySymbolAccessError(unit, node, unnamedSuperConstructor));
        }
      }
    }
  }

 @override
  void visitBinaryExpression(BinaryExpression node) {
    final Element? element = node.staticElement;
    node.leftOperand.accept(this);
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add(_DebugOnlySymbolAccessError(unit, node, element));
    }
    node.rightOperand.accept(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final Element? element = node.staticElement;
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add(_DebugOnlySymbolAccessError(unit, node, element));
    }
    node.operand.accept(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    node.operand.accept(this);
    final Element? element = node.staticElement;
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add(_DebugOnlySymbolAccessError(unit, node, element));
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    final Element? element = node.staticElement;
    if (element != null && _isDebugOnlyExecutableElement(element)) {
      accessViolations.add(_DebugOnlySymbolAccessError(unit, node, element));
    }
    node.index.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final Element? readElement = node.readElement;
    final Element? writeElement = node.writeElement;
    final Element? operatorElement = node.staticElement;
    if (readElement != null && _isDebugOnlyExecutableElement(readElement)) {
      accessViolations.add(_DebugOnlySymbolAccessError(unit, node, readElement));
    }
    if (writeElement != null && writeElement != readElement && _isDebugOnlyExecutableElement(writeElement)) {
      accessViolations.add(_DebugOnlySymbolAccessError(unit, node, writeElement));
    }
    if (operatorElement != null && _isDebugOnlyExecutableElement(operatorElement)) {
      accessViolations.add(_DebugOnlySymbolAccessError(unit, node, operatorElement));
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final Element? element = node.declaredElement;
    // Special case toString.
    final bool shouldSkip = (node.name.lexeme == 'toString' && !node.isStatic)
                    || (element != null && _isDebugOnlyExecutableElement(element));
    if (shouldSkip) {
      return;
    }
    super.visitMethodDeclaration(node);
  }
}
