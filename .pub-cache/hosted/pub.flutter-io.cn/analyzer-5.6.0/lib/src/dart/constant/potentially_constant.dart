// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// Some [ConstructorElement]s can be temporary marked as "const" to check
/// if doing this is valid.
final temporaryConstConstructorElements = Expando<bool>();

/// Check if the [node] and all its sub-nodes are potentially constant.
///
/// Return the list of nodes that are not potentially constant.
List<AstNode> getNotPotentiallyConstants(
  AstNode node, {
  required FeatureSet featureSet,
}) {
  var collector = _Collector(
    featureSet: featureSet,
  );
  collector.collect(node);
  return collector.nodes;
}

/// Return `true` if the [node] is a constant type expression.
bool isConstantTypeExpression(TypeAnnotation node) {
  return _ConstantTypeChecker(potentially: false).check(node);
}

/// Return `true` if the [node] is a potentially constant type expression.
bool isPotentiallyConstantTypeExpression(TypeAnnotation node) {
  return _ConstantTypeChecker(potentially: true).check(node);
}

bool _isConstantTypeName(Identifier name) {
  var element = name.staticElement;
  if (element is InterfaceElement || element is TypeAliasElement) {
    if (name is PrefixedIdentifier) {
      if (name.isDeferred) {
        return false;
      }
    }
    return true;
  }
  return false;
}

class _Collector {
  final FeatureSet featureSet;
  final List<AstNode> nodes = [];

  _Collector({required this.featureSet});

  void collect(AstNode node) {
    if (node is BooleanLiteral ||
        node is DoubleLiteral ||
        node is IntegerLiteral ||
        node is NullLiteral ||
        node is SimpleStringLiteral ||
        node is SymbolLiteral) {
      return;
    }

    if (node is AdjacentStrings) {
      for (var string in node.strings) {
        collect(string);
      }
      return;
    }

    if (node is StringInterpolation) {
      for (var component in node.elements) {
        if (component is InterpolationExpression) {
          collect(component.expression);
        }
      }
      return;
    }

    if (node is Identifier) {
      return _identifier(node);
    }

    if (node is InstanceCreationExpression) {
      if (!node.isConst) {
        nodes.add(node);
      }
      return;
    }

    if (node is TypedLiteral) {
      return _typedLiteral(node);
    }

    if (node is ParenthesizedExpression) {
      collect(node.expression);
      return;
    }

    if (node is RecordLiteral) {
      return _recordLiteral(node);
    }

    if (node is MethodInvocation) {
      return _methodInvocation(node);
    }

    if (node is NamedExpression) {
      return collect(node.expression);
    }

    if (node is BinaryExpression) {
      collect(node.leftOperand);
      collect(node.rightOperand);
      return;
    }

    if (node is PrefixExpression) {
      var operator = node.operator.type;
      if (operator == TokenType.BANG ||
          operator == TokenType.MINUS ||
          operator == TokenType.TILDE) {
        collect(node.operand);
        return;
      }
      nodes.add(node);
      return;
    }

    if (node is ConditionalExpression) {
      collect(node.condition);
      collect(node.thenExpression);
      collect(node.elseExpression);
      return;
    }

    if (node is PropertyAccess) {
      return _propertyAccess(node);
    }

    if (node is AsExpression) {
      if (featureSet.isEnabled(Feature.non_nullable)) {
        if (!isPotentiallyConstantTypeExpression(node.type)) {
          nodes.add(node.type);
        }
      } else {
        if (!isConstantTypeExpression(node.type)) {
          nodes.add(node.type);
        }
      }
      collect(node.expression);
      return;
    }

    if (node is IsExpression) {
      if (featureSet.isEnabled(Feature.non_nullable)) {
        if (!isPotentiallyConstantTypeExpression(node.type)) {
          nodes.add(node.type);
        }
      } else {
        if (!isConstantTypeExpression(node.type)) {
          nodes.add(node.type);
        }
      }
      collect(node.expression);
      return;
    }

    if (node is MapLiteralEntry) {
      collect(node.key);
      collect(node.value);
      return;
    }

    if (node is SpreadElement) {
      collect(node.expression);
      return;
    }

    if (node is IfElement) {
      collect(node.condition);
      collect(node.thenElement);
      if (node.elseElement != null) {
        collect(node.elseElement!);
      }
      return;
    }

    if (node is ConstructorReference) {
      _typeArgumentList(node.constructorName.type.typeArguments);
      return;
    }

    if (node is FunctionReference) {
      _typeArgumentList(node.typeArguments);
      collect(node.function);
      return;
    }

    if (node is TypeLiteral) {
      _typeArgumentList(node.type.typeArguments);
      return;
    }

    nodes.add(node);
  }

  void _identifier(Identifier node) {
    var element = node.staticElement;

    if (node is PrefixedIdentifier) {
      if (node.isDeferred) {
        nodes.add(node);
        return;
      }
      if (node.identifier.name == 'length') {
        collect(node.prefix);
        return;
      }
      if (element is MethodElement && element.isStatic) {
        if (!_isConstantTypeName(node.prefix)) {
          nodes.add(node);
        }
        return;
      }
    }

    if (element is ParameterElement) {
      var enclosing = element.enclosingElement;
      if (enclosing is ConstructorElement &&
          isConstConstructorElement(enclosing)) {
        if (node.thisOrAncestorOfType<ConstructorInitializer>() != null) {
          return;
        }
      }
      nodes.add(node);
      return;
    }

    if (element is VariableElement) {
      if (!element.isConst) {
        nodes.add(node);
      }
      return;
    }
    if (element is PropertyAccessorElement && element.isGetter) {
      var variable = element.variable;
      if (!variable.isConst) {
        nodes.add(node);
      }
      return;
    }
    if (_isConstantTypeName(node)) {
      return;
    }
    if (element is FunctionElement) {
      return;
    }
    if (element is MethodElement && element.isStatic) {
      return;
    }
    if (element is TypeParameterElement &&
        featureSet.isEnabled(Feature.constructor_tearoffs)) {
      return;
    }
    nodes.add(node);
  }

  void _methodInvocation(MethodInvocation node) {
    var arguments = node.argumentList.arguments;
    if (arguments.length == 2) {
      var element = node.methodName.staticElement;
      if (element is FunctionElement && element.isDartCoreIdentical) {
        collect(arguments[0]);
        collect(arguments[1]);
        return;
      }
    }
    // TODO(srawlins): collect type arguments.
    nodes.add(node);
  }

  void _propertyAccess(PropertyAccess node) {
    // CascadeExpression is not a constant, so the target is never null.
    var target = node.target!;

    if (node.propertyName.name == 'length') {
      collect(target);
      return;
    }

    if (target is PrefixedIdentifier) {
      if (target.isDeferred) {
        nodes.add(node);
        return;
      }

      var element = node.propertyName.staticElement;
      if (element is PropertyAccessorElement && element.isGetter) {
        var variable = element.variable;
        if (!variable.isConst) {
          nodes.add(node.propertyName);
        }
        return;
      }
    }

    nodes.add(node);
  }

  void _recordLiteral(RecordLiteral node) {
    for (final field in node.fields) {
      collect(field);
    }
  }

  void _typeArgumentList(TypeArgumentList? typeArgumentList) {
    var typeArguments = typeArgumentList?.arguments;
    if (typeArguments != null) {
      for (var typeArgument in typeArguments) {
        if (!isPotentiallyConstantTypeExpression(typeArgument)) {
          nodes.add(typeArgument);
        }
      }
    }
  }

  void _typedLiteral(TypedLiteral node) {
    if (!node.isConst) {
      nodes.add(node);
      return;
    }

    if (node is ListLiteral) {
      var typeArguments = node.typeArguments?.arguments;
      if (typeArguments != null && typeArguments.length == 1) {
        var elementType = typeArguments[0];
        if (!isPotentiallyConstantTypeExpression(elementType)) {
          nodes.add(elementType);
        }
      }

      for (var element in node.elements) {
        collect(element);
      }
      return;
    }

    if (node is SetOrMapLiteral) {
      var typeArguments = node.typeArguments?.arguments;
      if (typeArguments != null && typeArguments.length == 1) {
        var elementType = typeArguments[0];
        if (!isPotentiallyConstantTypeExpression(elementType)) {
          nodes.add(elementType);
        }
      }

      if (typeArguments != null && typeArguments.length == 2) {
        var keyType = typeArguments[0];
        var valueType = typeArguments[1];
        if (!isConstantTypeExpression(keyType)) {
          nodes.add(keyType);
        }
        if (!isConstantTypeExpression(valueType)) {
          nodes.add(valueType);
        }
      }

      for (var element in node.elements) {
        collect(element);
      }
    }
  }

  static bool isConstConstructorElement(ConstructorElement element) {
    if (element.isConst) return true;
    return temporaryConstConstructorElements[element] ?? false;
  }
}

class _ConstantTypeChecker {
  final bool potentially;

  _ConstantTypeChecker({required this.potentially});

  /// Return `true` if the [node] is a (potentially) constant type expression.
  bool check(TypeAnnotation? node) {
    if (potentially &&
        node is NamedType &&
        node.name.staticElement is TypeParameterElement) {
      return true;
    }

    if (node is NamedType) {
      if (_isConstantTypeName(node.name)) {
        var arguments = node.typeArguments?.arguments;
        if (arguments != null) {
          for (var argument in arguments) {
            if (!check(argument)) {
              return false;
            }
          }
        }
        return true;
      }
      var type = node.type;
      if (type is DynamicTypeImpl || type is NeverType || type is VoidType) {
        return true;
      }
      return false;
    }

    if (node is GenericFunctionType) {
      var returnType = node.returnType;
      if (returnType != null) {
        if (!check(returnType)) {
          return false;
        }
      }

      var typeParameters = node.typeParameters?.typeParameters;
      if (typeParameters != null) {
        for (var parameter in typeParameters) {
          var bound = parameter.bound;
          if (bound != null && !check(bound)) {
            return false;
          }
        }
      }

      var formalParameters = node.parameters.parameters;
      for (var parameter in formalParameters) {
        if (parameter is SimpleFormalParameter) {
          if (!check(parameter.type)) {
            return false;
          }
        }
      }

      return true;
    }

    return false;
  }
}
