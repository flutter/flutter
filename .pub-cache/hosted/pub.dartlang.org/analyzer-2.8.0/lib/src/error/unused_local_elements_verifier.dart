// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart' show ExecutableMember;
import 'package:analyzer/src/error/codes.dart';
import 'package:collection/collection.dart';

/// An [AstVisitor] that fills [UsedLocalElements].
class GatherUsedLocalElementsVisitor extends RecursiveAstVisitor<void> {
  final UsedLocalElements usedElements = UsedLocalElements();

  final LibraryElement _enclosingLibrary;
  ClassElement? _enclosingClass;
  ExecutableElement? _enclosingExec;

  GatherUsedLocalElementsVisitor(this._enclosingLibrary);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var element = node.staticElement;
    if (element != null) {
      usedElements.members.add(element);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var element = node.staticElement;
    usedElements.addMember(element);
    super.visitBinaryExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    var exceptionParameter = node.exceptionParameter;
    var stackTraceParameter = node.stackTraceParameter;
    if (exceptionParameter != null) {
      var element = exceptionParameter.staticElement;
      usedElements.addCatchException(element);
      if (stackTraceParameter != null || node.onKeyword == null) {
        usedElements.addElement(element);
      }
    }
    if (stackTraceParameter != null) {
      var element = stackTraceParameter.staticElement;
      usedElements.addCatchStackTrace(element);
    }
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var enclosingClassOld = _enclosingClass;
    try {
      _enclosingClass = node.declaredElement;
      super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = enclosingClassOld;
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var enclosingExecOld = _enclosingExec;
    try {
      _enclosingExec = node.declaredElement;
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingExec = enclosingExecOld;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      usedElements.addElement(node.declaredElement);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    usedElements.addElement(node.staticElement);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    var element = node.writeOrReadElement;
    usedElements.addMember(element);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    for (var argument in node.argumentList.arguments) {
      var parameter = argument.staticParameterElement;
      usedElements.addElement(parameter);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var enclosingExecOld = _enclosingExec;
    try {
      _enclosingExec = node.declaredElement;
      super.visitMethodDeclaration(node);
    } finally {
      _enclosingExec = enclosingExecOld;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var function = node.methodName.staticElement;
    if (function is FunctionElement || function is MethodElement) {
      for (var argument in node.argumentList.arguments) {
        var parameter = argument.staticParameterElement;
        usedElements.addElement(parameter);
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    var element = node.staticElement;
    usedElements.addMember(element);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var element = node.staticElement;
    usedElements.addMember(element);
    super.visitPrefixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    if (_inCommentReference(node)) {
      return;
    }
    var element = node.writeOrReadElement;
    // Store un-parameterized members.
    if (element is ExecutableMember) {
      element = element.declaration;
    }
    bool isIdentifierRead = _isReadIdentifier(node);
    if (element is PropertyAccessorElement &&
        isIdentifierRead &&
        element.variable is TopLevelVariableElement) {
      if (element.isSynthetic) {
        usedElements.addElement(element.variable);
      } else {
        usedElements.members.add(element);
        _addMemberAndCorrespondingGetter(element);
      }
    } else if (element is LocalVariableElement) {
      if (isIdentifierRead) {
        usedElements.addElement(element);
      }
    } else {
      _useIdentifierElement(node, node.readElement);
      _useIdentifierElement(node, node.writeElement);
      _useIdentifierElement(node, node.staticElement);
      var parent = node.parent!;
      // If [node] is a method tear-off, assume all parameters are used.
      var functionReferenceIsCall =
          (element is ExecutableElement && parent is MethodInvocation) ||
              // named constructor
              (element is ConstructorElement &&
                  parent is ConstructorName &&
                  parent.parent is InstanceCreationExpression) ||
              // unnamed constructor
              (element is ClassElement &&
                  parent.parent is ConstructorName &&
                  parent.parent!.parent is InstanceCreationExpression);
      if (element is ExecutableElement &&
          isIdentifierRead &&
          !functionReferenceIsCall) {
        for (var parameter in element.parameters) {
          usedElements.addElement(parameter);
        }
      }
      var enclosingElement = element?.enclosingElement;
      if (element == null) {
        if (isIdentifierRead) {
          usedElements.unresolvedReadMembers.add(node.name);
        }
      } else if (enclosingElement is ClassElement &&
          enclosingElement.isEnum &&
          element.name == 'values') {
        // If the 'values' static accessor of the enum is accessed, then all of
        // the enum values have been read.
        for (var value in enclosingElement.fields) {
          usedElements.readMembers.add(value.getter!);
        }
      } else if ((enclosingElement is ClassElement ||
              enclosingElement is ExtensionElement) &&
          !identical(element, _enclosingExec)) {
        usedElements.members.add(element);
        if (isIdentifierRead) {
          _addMemberAndCorrespondingGetter(element);
        }
      }
    }
  }

  /// Add [element] as a used member and, if [element] is a setter, add its
  /// corresponding getter as a used member.
  void _addMemberAndCorrespondingGetter(Element element) {
    if (element is PropertyAccessorElement && element.isSetter) {
      usedElements.addMember(element.correspondingGetter);
      usedElements.addReadMember(element.correspondingGetter);
    } else {
      usedElements.addReadMember(element);
    }
  }

  /// Marks the [element] of [node] as used in the library.
  void _useIdentifierElement(Identifier node, Element? element) {
    if (element == null) {
      return;
    }
    // Check if [element] is a local element.
    if (!identical(element.library, _enclosingLibrary)) {
      return;
    }
    // Ignore references to an element from itself.
    if (identical(element, _enclosingClass)) {
      return;
    }
    if (identical(element, _enclosingExec)) {
      return;
    }
    // Ignore places where the element is not actually used.
    if (node.parent is NamedType) {
      if (element is ClassElement) {
        AstNode parent2 = node.parent!.parent!;
        if (parent2 is IsExpression) {
          return;
        }
        if (parent2 is VariableDeclarationList) {
          // If it's a field's type, it still counts as used.
          if (parent2.parent is! FieldDeclaration) {
            return;
          }
        }
      }
    }
    // OK
    usedElements.addElement(element);
  }

  /// Returns whether [identifier] is found in a [CommentReference].
  static bool _inCommentReference(SimpleIdentifier identifier) {
    var parent = identifier.parent;
    return parent is CommentReference || parent?.parent is CommentReference;
  }

  /// Returns whether the value of [node] is _only_ being read at this position.
  ///
  /// Returns `false` if [node] is not a read access, or if [node] is a combined
  /// read/write access.
  static bool _isReadIdentifier(SimpleIdentifier node) {
    // Not reading at all.
    if (!node.inGetterContext()) {
      return false;
    }
    // Check if useless reading.
    AstNode parent = node.parent!;

    if (parent.parent is ExpressionStatement) {
      if (parent is PrefixExpression || parent is PostfixExpression) {
        // v++;
        // ++v;
        return false;
      }
      if (parent is AssignmentExpression && parent.leftHandSide == node) {
        // v ??= doSomething();
        //   vs.
        // v += 2;
        var operatorType = parent.operator.type;
        return operatorType == TokenType.QUESTION_QUESTION_EQ;
      }
    }
    // OK
    return true;
  }
}

/// Instances of the class [UnusedLocalElementsVerifier] traverse an AST
/// looking for cases of [HintCode.UNUSED_ELEMENT], [HintCode.UNUSED_FIELD],
/// [HintCode.UNUSED_LOCAL_VARIABLE], etc.
class UnusedLocalElementsVerifier extends RecursiveAstVisitor<void> {
  /// The error listener to which errors will be reported.
  final AnalysisErrorListener _errorListener;

  /// The elements know to be used.
  final UsedLocalElements _usedElements;

  /// The inheritance manager used to find overridden methods.
  final InheritanceManager3 _inheritanceManager;

  /// The URI of the library being verified.
  final Uri _libraryUri;

  /// Create a new instance of the [UnusedLocalElementsVerifier].
  UnusedLocalElementsVerifier(this._errorListener, this._usedElements,
      this._inheritanceManager, LibraryElement library)
      : _libraryUri = library.source.uri;

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var element in node.parameterElements) {
      if (!_isUsedElement(element!)) {
        _reportErrorForElement(
            HintCode.UNUSED_ELEMENT_PARAMETER, element, [element.displayName]);
      }
    }
    super.visitFormalParameterList(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      var element = node.staticElement;
      if (element is ClassElement) {
        _visitClassElement(element);
      } else if (element is ConstructorElement) {
        _visitConstructorElement(element);
      } else if (element is FieldElement) {
        _visitFieldElement(element);
      } else if (element is FunctionElement) {
        _visitFunctionElement(element);
      } else if (element is LocalVariableElement) {
        _visitLocalVariableElement(element);
      } else if (element is MethodElement) {
        _visitMethodElement(element);
      } else if (element is PropertyAccessorElement) {
        _visitPropertyAccessorElement(element);
      } else if (element is TopLevelVariableElement) {
        _visitTopLevelVariableElement(element);
      } else if (element is TypeAliasElement) {
        _visitTypeAliasElement(element);
      }
    }
  }

  /// Returns whether the name of [element] consists only of underscore
  /// characters.
  bool _isNamedUnderscore(LocalVariableElement element) {
    String name = element.name;
    for (int index = name.length - 1; index >= 0; --index) {
      if (name.codeUnitAt(index) != 0x5F) {
        // 0x5F => '_'
        return false;
      }
    }
    return true;
  }

  bool _isPrivateClassOrExtension(Element element) =>
      (element is ClassElement || element is ExtensionElement) &&
      element.isPrivate;

  /// Returns whether [element] is accessible outside of the library in which
  /// it is declared.
  bool _isPubliclyAccessible(ExecutableElement element) {
    if (element.isPrivate) {
      return false;
    }
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement &&
        enclosingElement.isPrivate &&
        (element.isStatic || element is ConstructorElement)) {
      return false;
    } else if (enclosingElement is ExtensionElement &&
        enclosingElement.isPrivate) {
      return false;
    }
    return true;
  }

  /// Returns whether [element] is a private element which is read somewhere in
  /// the library.
  bool _isReadMember(Element element) {
    bool elementIsStaticVariable =
        element is VariableElement && element.isStatic;
    if (element.isPublic) {
      if (_isPrivateClassOrExtension(element.enclosingElement!) &&
          elementIsStaticVariable) {
        // Public static fields of private classes, mixins, and extensions are
        // inaccessible from outside the library in which they are declared.
      } else {
        return true;
      }
    }
    if (element.isSynthetic) {
      return true;
    }
    if (element is FieldElement) {
      var getter = element.getter;
      if (getter == null) {
        return false;
      }
      element = getter;
    }
    if (_usedElements.readMembers.contains(element) ||
        _usedElements.unresolvedReadMembers.contains(element.name)) {
      return true;
    }

    if (elementIsStaticVariable) {
      return false;
    }
    return _overridesUsedElement(element);
  }

  bool _isUsedElement(Element element) {
    if (element.isSynthetic) {
      return true;
    }
    if (_hasPragmaVmEntryPoint(element)) {
      return true;
    }
    if (element is LocalVariableElement ||
        element is FunctionElement && !element.isStatic) {
      // local variable or function
    } else if (element is ParameterElement) {
      var enclosingElement = element.enclosingElement;
      // Only report unused parameters of methods or functions.
      if (enclosingElement is! ConstructorElement &&
          enclosingElement is! FunctionElement &&
          enclosingElement is! MethodElement) {
        return true;
      }

      if (!element.isOptional) {
        return true;
      }
      if (enclosingElement is ExecutableElement) {
        if (_isPubliclyAccessible(enclosingElement)) {
          return true;
        }
        if (_overridesUsedParameter(element, enclosingElement)) {
          return true;
        }
      }
    } else {
      if (element.isPublic) {
        return true;
      }
    }
    return _usedElements.elements.contains(element);
  }

  bool _isUsedMember(ExecutableElement element) {
    if (_isPubliclyAccessible(element)) {
      return true;
    }
    if (element.isSynthetic) {
      return true;
    }
    if (_hasPragmaVmEntryPoint(element)) {
      return true;
    }
    if (_usedElements.members.contains(element)) {
      return true;
    }
    if (_usedElements.elements.contains(element)) {
      return true;
    }

    return _overridesUsedElement(element);
  }

  Iterable<ExecutableElement> _overriddenElements(Element element) {
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement) {
      Name name = Name(_libraryUri, element.name!);
      var overridden =
          _inheritanceManager.getOverridden2(enclosingElement, name);
      if (overridden == null) {
        return [];
      }
      return overridden.map((e) => (e is ExecutableMember) ? e.declaration : e);
    } else {
      return [];
    }
  }

  /// Check if [element] is a class member which overrides a super class's class
  /// member which is used.
  bool _overridesUsedElement(Element element) {
    return _overriddenElements(element).any((ExecutableElement e) =>
        _usedElements.members.contains(e) || _overridesUsedElement(e));
  }

  /// Check if [element] is a parameter of a method which overrides a super
  /// class's method in which the corresponding parameter is used.
  bool _overridesUsedParameter(
      ParameterElement element, ExecutableElement enclosingElement) {
    var overriddenElements = _overriddenElements(enclosingElement);
    for (var overridden in overriddenElements) {
      ParameterElement? correspondingParameter;
      if (element.isNamed) {
        correspondingParameter = overridden.parameters
            .firstWhereOrNull((p) => p.name == element.name);
      } else {
        var parameterIndex = 0;
        var parameterCount = enclosingElement.parameters.length;
        while (parameterIndex < parameterCount) {
          if (enclosingElement.parameters[parameterIndex] == element) {
            break;
          }
          parameterIndex++;
        }
        if (overridden.parameters.length <= parameterIndex) {
          // Something is wrong with the overridden element. Ignore it.
          continue;
        }
        correspondingParameter = overridden.parameters[parameterIndex];
      }
      // The parameter was added in the override.
      if (correspondingParameter == null) {
        continue;
      }
      // The parameter was made optional in the override.
      if (correspondingParameter.isRequiredNamed ||
          correspondingParameter.isRequiredPositional) {
        return true;
      }
      if (_usedElements.elements.contains(correspondingParameter)) {
        return true;
      }
    }
    return false;
  }

  void _reportErrorForElement(
      ErrorCode errorCode, Element? element, List<Object> arguments) {
    if (element != null) {
      _errorListener.onError(AnalysisError(element.source!, element.nameOffset,
          element.nameLength, errorCode, arguments));
    }
  }

  void _visitClassElement(ClassElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  void _visitConstructorElement(ConstructorElement element) {
    // Only complain about an unused constructor if it is not the only
    // constructor in the class. A single unused, private constructor may serve
    // the purpose of preventing the class from being extended. In serving this
    // purpose, the constructor is "used."
    if (element.enclosingElement.constructors.length > 1 &&
        !_isUsedMember(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  void _visitFieldElement(FieldElement element) {
    if (!_isReadMember(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_FIELD, element, [element.displayName]);
    }
  }

  void _visitFunctionElement(FunctionElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  void _visitLocalVariableElement(LocalVariableElement element) {
    if (!_isUsedElement(element) && !_isNamedUnderscore(element)) {
      HintCode errorCode;
      if (_usedElements.isCatchException(element)) {
        errorCode = HintCode.UNUSED_CATCH_CLAUSE;
      } else if (_usedElements.isCatchStackTrace(element)) {
        errorCode = HintCode.UNUSED_CATCH_STACK;
      } else {
        errorCode = HintCode.UNUSED_LOCAL_VARIABLE;
      }
      _reportErrorForElement(errorCode, element, [element.displayName]);
    }
  }

  void _visitMethodElement(MethodElement element) {
    if (!_isUsedMember(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  void _visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!_isUsedMember(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  void _visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  void _visitTypeAliasElement(TypeAliasElement element) {
    if (!_isUsedElement(element)) {
      _reportErrorForElement(
          HintCode.UNUSED_ELEMENT, element, [element.displayName]);
    }
  }

  static bool _hasPragmaVmEntryPoint(Element element) {
    return element is ElementImpl && element.hasPragmaVmEntryPoint;
  }
}

/// A container with sets of used [Element]s.
/// All these elements are defined in a single compilation unit or a library.
class UsedLocalElements {
  /// Resolved, locally defined elements that are used or potentially can be
  /// used.
  final HashSet<Element> elements = HashSet<Element>();

  /// [LocalVariableElement]s that represent exceptions in [CatchClause]s.
  final HashSet<LocalVariableElement> catchExceptionElements =
      HashSet<LocalVariableElement>();

  /// [LocalVariableElement]s that represent stack traces in [CatchClause]s.
  final HashSet<LocalVariableElement> catchStackTraceElements =
      HashSet<LocalVariableElement>();

  /// Resolved class members that are referenced in the library.
  final HashSet<Element> members = HashSet<Element>();

  /// Resolved class members that are read in the library.
  final HashSet<Element> readMembers = HashSet<Element>();

  /// Unresolved class members that are read in the library.
  final HashSet<String> unresolvedReadMembers = HashSet<String>();

  UsedLocalElements();

  factory UsedLocalElements.merge(List<UsedLocalElements> parts) {
    UsedLocalElements result = UsedLocalElements();
    int length = parts.length;
    for (int i = 0; i < length; i++) {
      UsedLocalElements part = parts[i];
      result.elements.addAll(part.elements);
      result.catchExceptionElements.addAll(part.catchExceptionElements);
      result.catchStackTraceElements.addAll(part.catchStackTraceElements);
      result.members.addAll(part.members);
      result.readMembers.addAll(part.readMembers);
      result.unresolvedReadMembers.addAll(part.unresolvedReadMembers);
    }
    return result;
  }

  void addCatchException(Element? element) {
    if (element is LocalVariableElement) {
      catchExceptionElements.add(element);
    }
  }

  void addCatchStackTrace(Element? element) {
    if (element is LocalVariableElement) {
      catchStackTraceElements.add(element);
    }
  }

  void addElement(Element? element) {
    if (element != null) {
      elements.add(element);
    }
  }

  void addMember(Element? element) {
    // Store un-parameterized members.
    if (element is ExecutableMember) {
      element = element.declaration;
    }

    if (element != null) {
      members.add(element);
    }
  }

  void addReadMember(Element? element) {
    if (element != null) {
      readMembers.add(element);
    }
  }

  bool isCatchException(LocalVariableElement element) {
    return catchExceptionElements.contains(element);
  }

  bool isCatchStackTrace(LocalVariableElement element) {
    return catchStackTraceElements.contains(element);
  }
}
