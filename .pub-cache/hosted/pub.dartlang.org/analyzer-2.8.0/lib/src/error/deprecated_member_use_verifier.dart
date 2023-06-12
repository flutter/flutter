// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';

class DeprecatedMemberUseVerifier {
  final WorkspacePackage? _workspacePackage;
  final ErrorReporter _errorReporter;

  /// We push a new value every time when we enter into a scope which
  /// can be marked as deprecated - a class, a method, fields (multiple).
  final List<bool> _inDeprecatedMemberStack = [false];

  DeprecatedMemberUseVerifier(this._workspacePackage, this._errorReporter);

  void assignmentExpression(AssignmentExpression node) {
    _checkForDeprecated(node.readElement, node.leftHandSide);
    _checkForDeprecated(node.writeElement, node.leftHandSide);
    _checkForDeprecated(node.staticElement, node);
  }

  void binaryExpression(BinaryExpression node) {
    _checkForDeprecated(node.staticElement, node);
  }

  void constructorName(ConstructorName node) {
    _checkForDeprecated(node.staticElement, node);
  }

  void exportDirective(ExportDirective node) {
    _checkForDeprecated(node.uriElement, node);
  }

  void functionExpressionInvocation(FunctionExpressionInvocation node) {
    var callElement = node.staticElement;
    if (callElement is MethodElement &&
        callElement.name == FunctionElement.CALL_METHOD_NAME) {
      _checkForDeprecated(callElement, node);
    }
  }

  void importDirective(ImportDirective node) {
    _checkForDeprecated(node.uriElement, node);
  }

  void indexExpression(IndexExpression node) {
    _checkForDeprecated(node.staticElement, node);
  }

  void instanceCreationExpression(InstanceCreationExpression node) {
    _invocationArguments(
      node.constructorName.staticElement,
      node.argumentList,
    );
  }

  void methodInvocation(MethodInvocation node) {
    _invocationArguments(
      node.methodName.staticElement,
      node.argumentList,
    );
  }

  void popInDeprecated() {
    _inDeprecatedMemberStack.removeLast();
  }

  void postfixExpression(PostfixExpression node) {
    _checkForDeprecated(node.readElement, node.operand);
    _checkForDeprecated(node.writeElement, node.operand);
    _checkForDeprecated(node.staticElement, node);
  }

  void prefixExpression(PrefixExpression node) {
    _checkForDeprecated(node.readElement, node.operand);
    _checkForDeprecated(node.writeElement, node.operand);
    _checkForDeprecated(node.staticElement, node);
  }

  void pushInDeprecatedMetadata(List<Annotation> metadata) {
    var hasDeprecated = _hasDeprecatedAnnotation(metadata);
    pushInDeprecatedValue(hasDeprecated);
  }

  void pushInDeprecatedValue(bool value) {
    var newValue = _inDeprecatedMemberStack.last || value;
    _inDeprecatedMemberStack.add(newValue);
  }

  void redirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    _checkForDeprecated(node.staticElement, node);
    _invocationArguments(node.staticElement, node.argumentList);
  }

  void simpleIdentifier(SimpleIdentifier node) {
    // Don't report declared identifiers.
    if (node.inDeclarationContext()) {
      return;
    }

    // Report full ConstructorName, not just the constructor name.
    var parent = node.parent;
    if (parent is ConstructorName && identical(node, parent.name)) {
      return;
    }

    // Report full SuperConstructorInvocation, not just the constructor name.
    if (parent is SuperConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return;
    }

    // HideCombinator is forgiving.
    if (parent is HideCombinator) {
      return;
    }

    _simpleIdentifier(node);
  }

  void superConstructorInvocation(SuperConstructorInvocation node) {
    _checkForDeprecated(node.staticElement, node);
    _invocationArguments(node.staticElement, node.argumentList);
  }

  /// Given some [element], look at the associated metadata and report the use
  /// of the member if it is declared as deprecated. If a diagnostic is reported
  /// it should be reported at the given [node].
  void _checkForDeprecated(Element? element, AstNode node) {
    if (!_isDeprecated(element)) {
      return;
    }

    if (_inDeprecatedMemberStack.last) {
      return;
    }

    if (_isLocalParameter(element, node)) {
      return;
    }

    var errorNode = node;
    var parent = node.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == node) {
      if (node is SimpleIdentifier) {
        errorNode = node;
      } else if (node is PrefixedIdentifier) {
        errorNode = node.identifier;
      } else if (node is PropertyAccess) {
        errorNode = node.propertyName;
      }
    } else if (node is NamedExpression) {
      errorNode = node.name.label;
    }

    String displayName = element!.displayName;
    if (element is ConstructorElement) {
      // TODO(jwren) We should modify ConstructorElement.getDisplayName(),
      // or have the logic centralized elsewhere, instead of doing this logic
      // here.
      displayName = element.enclosingElement.displayName;
      if (element.displayName.isNotEmpty) {
        displayName = "$displayName.${element.displayName}";
      }
    } else if (element is LibraryElement) {
      displayName = element.definingCompilationUnit.source.uri.toString();
    } else if (node is MethodInvocation &&
        displayName == FunctionElement.CALL_METHOD_NAME) {
      var invokeType = node.staticInvokeType as InterfaceType;
      var invokeClass = invokeType.element;
      displayName = "${invokeClass.name}.${element.displayName}";
    }
    var library = element is LibraryElement ? element : element.library;
    var message = _deprecatedMessage(element);
    if (message == null || message.isEmpty) {
      _errorReporter.reportErrorForNode(
        _isLibraryInWorkspacePackage(library)
            ? HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE
            : HintCode.DEPRECATED_MEMBER_USE,
        errorNode,
        [displayName],
      );
    } else {
      _errorReporter.reportErrorForNode(
        _isLibraryInWorkspacePackage(library)
            ? HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE
            : HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE,
        errorNode,
        [displayName, message],
      );
    }
  }

  void _invocationArguments(Element? element, ArgumentList arguments) {
    element = element?.declaration;
    if (element is ExecutableElement) {
      _visitParametersAndArguments(
        element.parameters,
        arguments.arguments,
        (parameter, argument) {
          if (parameter.isOptional) {
            _checkForDeprecated(parameter, argument);
          }
        },
      );
    }
  }

  bool _isLibraryInWorkspacePackage(LibraryElement? library) {
    // Better to not make a big claim that they _are_ in the same package,
    // if we were unable to determine what package [_currentLibrary] is in.
    if (_workspacePackage == null || library == null) {
      return false;
    }
    return _workspacePackage!.contains(library.source);
  }

  void _simpleIdentifier(SimpleIdentifier identifier) {
    _checkForDeprecated(identifier.staticElement, identifier);
  }

  /// Return the message in the deprecated annotation on the given [element], or
  /// `null` if the element doesn't have a deprecated annotation or if the
  /// annotation does not have a message.
  static String? _deprecatedMessage(Element element) {
    // Implicit getters/setters.
    if (element.isSynthetic && element is PropertyAccessorElement) {
      element = element.variable;
    }
    var annotation = element.metadata.firstWhereOrNull((e) => e.isDeprecated);
    if (annotation == null || annotation.element is PropertyAccessorElement) {
      return null;
    }
    var constantValue = annotation.computeConstantValue();
    return constantValue?.getField('message')?.toStringValue() ??
        constantValue?.getField('expires')?.toStringValue();
  }

  static bool _hasDeprecatedAnnotation(List<Annotation> annotations) {
    for (var i = 0; i < annotations.length; i++) {
      if (annotations[i].elementAnnotation!.isDeprecated) {
        return true;
      }
    }
    return false;
  }

  static bool _isDeprecated(Element? element) {
    if (element == null) {
      return false;
    }

    if (element is PropertyAccessorElement && element.isSynthetic) {
      // TODO(brianwilkerson) Why isn't this the implementation for PropertyAccessorElement?
      Element variable = element.variable;
      return variable.hasDeprecated;
    }
    return element.hasDeprecated;
  }

  /// Return `true` if [element] is a [ParameterElement] declared in [node].
  static bool _isLocalParameter(Element? element, AstNode? node) {
    if (element is ParameterElement) {
      var definingFunction = element.enclosingElement as ExecutableElement;

      for (; node != null; node = node.parent) {
        if (node is ConstructorDeclaration) {
          if (node.declaredElement == definingFunction) {
            return true;
          }
        } else if (node is FunctionExpression) {
          if (node.declaredElement == definingFunction) {
            return true;
          }
        } else if (node is MethodDeclaration) {
          if (node.declaredElement == definingFunction) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static void _visitParametersAndArguments(
    List<ParameterElement> parameters,
    List<Expression> arguments,
    void Function(ParameterElement, Expression) f,
  ) {
    Map<String, ParameterElement>? namedParameters;

    var positionalIndex = 0;
    for (var argument in arguments) {
      if (argument is NamedExpression) {
        if (namedParameters == null) {
          namedParameters = {};
          for (var parameter in parameters) {
            if (parameter.isNamed) {
              namedParameters[parameter.name] = parameter;
            }
          }
        }
        var name = argument.name.label.name;
        var parameter = namedParameters[name];
        if (parameter != null) {
          f(parameter, argument);
        }
      } else {
        if (positionalIndex < parameters.length) {
          var parameter = parameters[positionalIndex++];
          if (parameter.isPositional) {
            f(parameter, argument);
          }
        }
      }
    }
  }
}
