// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer/src/task/strong_mode.dart';
import 'package:analyzer/src/util/collection.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';

/// Resolver for typed constant top-level variables and fields initializers.
///
/// Initializers of untyped variables are resolved during [TopLevelInference].
class ConstantInitializersResolver {
  final Linker linker;

  late CompilationUnitElementImpl _unitElement;
  late LibraryElement _library;
  bool _enclosingClassHasConstConstructor = false;
  late Scope _scope;

  ConstantInitializersResolver(this.linker);

  void perform() {
    for (var builder in linker.builders.values) {
      _library = builder.element;
      for (var unit in _library.units) {
        _unitElement = unit as CompilationUnitElementImpl;
        unit.classes.forEach(_resolveClassFields);
        unit.extensions.forEach(_resolveExtensionFields);
        unit.mixins.forEach(_resolveClassFields);

        _scope = builder.element.scope;
        unit.topLevelVariables.forEach(_resolveVariable);
      }
    }
  }

  void _resolveClassFields(ClassElement class_) {
    _enclosingClassHasConstConstructor =
        class_.constructors.any((c) => c.isConst);

    var node = linker.getLinkingNode(class_)!;
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in class_.fields) {
      _resolveVariable(element);
    }
    _enclosingClassHasConstConstructor = false;
  }

  void _resolveExtensionFields(ExtensionElement extension_) {
    var node = linker.getLinkingNode(extension_)!;
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in extension_.fields) {
      _resolveVariable(element);
    }
  }

  void _resolveVariable(PropertyInducingElement element) {
    element as PropertyInducingElementImpl;
    if (element.isSynthetic) return;

    var variable = linker.getLinkingNode(element) as VariableDeclaration;
    if (variable.initializer == null) return;

    var declarationList = variable.parent as VariableDeclarationList;
    var typeNode = declarationList.type;

    DartType contextType;
    if (element.hasTypeInferred) {
      contextType = element.type;
    } else if (typeNode != null) {
      contextType = typeNode.typeOrThrow;
    } else {
      contextType = DynamicTypeImpl.instance;
    }

    if (declarationList.isConst ||
        declarationList.isFinal && _enclosingClassHasConstConstructor) {
      var astResolver =
          AstResolver(linker, _unitElement, _scope, variable.initializer!);
      astResolver.resolveExpression(() => variable.initializer!,
          contextType: contextType);
    }

    if (element is ConstVariableElement) {
      var constElement = element as ConstVariableElement;
      constElement.constantInitializer = variable.initializer;
    }
  }
}

class TopLevelInference {
  final Linker linker;

  TopLevelInference(this.linker);

  void infer() {
    var initializerInference = _InitializerInference(linker);
    initializerInference.createNodes();

    _performOverrideInference();

    initializerInference.perform();
  }

  void _performOverrideInference() {
    var inferrer = InstanceMemberInferrer(linker.inheritance);
    for (var builder in linker.builders.values) {
      for (var unit in builder.element.units) {
        inferrer.inferCompilationUnit(unit);
      }
    }
  }
}

/// Information about a base constructor of a mixin application.
class _BaseConstructor {
  final InterfaceType superType;
  final ConstructorElement element;

  _BaseConstructor(this.superType, this.element);
}

class _ConstructorInferenceNode extends _InferenceNode {
  final _InferenceWalker _walker;
  final ConstructorElement _constructor;
  final List<_FieldFormalParameterWithField> _parameters = [];

  /// If this node is a constructor of a mixin application, this field
  /// is the corresponding constructor of the superclass.
  _BaseConstructor? _baseConstructor;

  @override
  bool isEvaluated = false;

  _ConstructorInferenceNode(this._walker, this._constructor) {
    for (var parameter in _constructor.parameters) {
      if (parameter is FieldFormalParameterElementImpl) {
        if (parameter.hasImplicitType) {
          var field = parameter.field;
          if (field != null) {
            _parameters.add(
              _FieldFormalParameterWithField(parameter, field),
            );
          }
        }
      }
    }

    var classElement = _constructor.enclosingElement;
    if (classElement.isMixinApplication) {
      var superType = classElement.supertype;
      if (superType != null) {
        var index = classElement.constructors.indexOf(_constructor);
        var superConstructors = superType.element.constructors
            .where((element) => element.isAccessibleIn(classElement.library))
            .toList();
        if (index < superConstructors.length) {
          _baseConstructor = _BaseConstructor(
            superType,
            superConstructors[index],
          );
        }
      }
    }
  }

  @override
  String get displayName => '$_constructor';

  @override
  List<_InferenceNode> computeDependencies() {
    var dependencies = _parameters
        .map((e) => _walker.getNode(e.field))
        .whereNotNull()
        .toList();

    dependencies.addIfNotNull(
      _walker.getNode(_baseConstructor?.element),
    );

    return dependencies;
  }

  @override
  void evaluate() {
    for (var parameterWithField in _parameters) {
      var parameter = parameterWithField.parameter;
      parameter.type = parameterWithField.field.type;
    }

    // We have inferred formal parameter types of the base constructor.
    // Update types of a mixin application constructor formal parameters.
    var baseConstructor = _baseConstructor;
    if (baseConstructor != null) {
      var constructor = _constructor as ConstructorElementImpl;
      var substitution = Substitution.fromInterfaceType(
        baseConstructor.superType,
      );
      forCorrespondingPairs<ParameterElement, ParameterElement>(
        constructor.parameters,
        baseConstructor.element.parameters,
        (parameter, baseParameter) {
          var type = substitution.substituteType(baseParameter.type);
          (parameter as ParameterElementImpl).type = type;
        },
      );
      // Update arguments of `SuperConstructorInvocation` to have the types
      // (which we have just set) of the corresponding formal parameters.
      // MixinApp(x, y) : super(x, y);
      var initializers = constructor.constantInitializers;
      var initializer = initializers.single as SuperConstructorInvocation;
      forCorrespondingPairs<ParameterElement, Expression>(
        constructor.parameters,
        initializer.argumentList.arguments,
        (parameter, argument) {
          (argument as SimpleIdentifierImpl).staticType = parameter.type;
        },
      );
    }

    isEvaluated = true;
  }

  @override
  void markCircular(List<_InferenceNode> cycle) {
    for (var parameterWithField in _parameters) {
      var parameter = parameterWithField.parameter;
      parameter.type = DynamicTypeImpl.instance;
    }
    isEvaluated = true;
  }
}

/// A field formal parameter with a non-nullable field.
class _FieldFormalParameterWithField {
  final FieldFormalParameterElementImpl parameter;
  final FieldElement field;

  _FieldFormalParameterWithField(this.parameter, this.field);
}

class _InferenceDependenciesCollector extends RecursiveAstVisitor<void> {
  final Set<Element> _set = Set.identity();

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = node.constructorName.staticElement?.declaration;
    if (element == null) return;

    _set.add(element);

    if (element.enclosingElement.typeParameters.isNotEmpty) {
      node.argumentList.accept(this);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is PropertyAccessorElement && element.isGetter) {
      _set.add(element.variable);
    }
  }
}

abstract class _InferenceNode extends graph.Node<_InferenceNode> {
  String get displayName;

  void evaluate();

  void markCircular(List<_InferenceNode> cycle);
}

class _InferenceWalker extends graph.DependencyWalker<_InferenceNode> {
  final Linker _linker;
  final Map<Element, _InferenceNode> _nodes = Map.identity();

  _InferenceWalker(this._linker);

  @override
  void evaluate(_InferenceNode v) {
    v.evaluate();
  }

  @override
  void evaluateScc(List<_InferenceNode> scc) {
    for (var node in scc) {
      node.markCircular(scc);
    }
  }

  _InferenceNode? getNode(Element? element) {
    return _nodes[element];
  }

  void walkNodes() {
    for (var node in _nodes.values) {
      if (!node.isEvaluated) {
        walk(node);
      }
    }
  }
}

class _InitializerInference {
  final Linker _linker;
  final _InferenceWalker _walker;

  late CompilationUnitElementImpl _unitElement;
  late Scope _scope;

  _InitializerInference(this._linker) : _walker = _InferenceWalker(_linker);

  void createNodes() {
    for (var builder in _linker.builders.values) {
      for (var unit in builder.element.units) {
        _unitElement = unit as CompilationUnitElementImpl;
        unit.classes.forEach(_addClassConstructorFieldFormals);
        unit.classes.forEach(_addClassElementFields);
        unit.extensions.forEach(_addExtensionElementFields);
        unit.mixins.forEach(_addClassElementFields);

        _scope = builder.element.scope;
        for (var element in unit.topLevelVariables) {
          _addVariableNode(element);
        }
      }
    }
  }

  void perform() {
    _walker.walkNodes();
  }

  void _addClassConstructorFieldFormals(ClassElement class_) {
    for (var constructor in class_.constructors) {
      var inferenceNode = _ConstructorInferenceNode(_walker, constructor);
      _walker._nodes[constructor] = inferenceNode;
    }
  }

  void _addClassElementFields(ClassElement class_) {
    var node = _linker.getLinkingNode(class_)!;
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in class_.fields) {
      _addVariableNode(element);
    }
  }

  void _addExtensionElementFields(ExtensionElement extension_) {
    var node = _linker.getLinkingNode(extension_)!;
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in extension_.fields) {
      _addVariableNode(element);
    }
  }

  void _addVariableNode(PropertyInducingElement element) {
    if (element.isSynthetic) return;

    var node = _linker.getLinkingNode(element) as VariableDeclaration;
    var variableList = node.parent as VariableDeclarationList;
    if (variableList.type != null) {
      return;
    }

    if (node.initializer != null) {
      var inferenceNode =
          _VariableInferenceNode(_walker, _unitElement, _scope, element, node);
      _walker._nodes[element] = inferenceNode;
      (element as PropertyInducingElementImpl).typeInference =
          _PropertyInducingElementTypeInference(inferenceNode);
    } else {
      (element as PropertyInducingElementImpl).type = DynamicTypeImpl.instance;
    }
  }
}

class _PropertyInducingElementTypeInference
    implements PropertyInducingElementTypeInference {
  final _VariableInferenceNode _node;

  _PropertyInducingElementTypeInference(this._node);

  @override
  void perform() {
    if (!_node.isEvaluated) {
      _node._walker.walk(_node);
    }
  }
}

class _VariableInferenceNode extends _InferenceNode {
  final _InferenceWalker _walker;
  final CompilationUnitElementImpl _unitElement;
  final TypeSystemImpl _typeSystem;
  final Scope _scope;
  final PropertyInducingElement _element;
  final VariableDeclaration _node;

  @override
  bool isEvaluated = false;

  _VariableInferenceNode(
    this._walker,
    this._unitElement,
    this._scope,
    this._element,
    this._node,
  ) : _typeSystem = _unitElement.library.typeSystem;

  @override
  String get displayName {
    return _node.name.name;
  }

  PropertyInducingElementImpl get _elementImpl {
    return _node.declaredElement as PropertyInducingElementImpl;
  }

  @override
  List<_InferenceNode> computeDependencies() {
    if (_elementImpl.hasTypeInferred) {
      return const <_InferenceNode>[];
    }

    _resolveInitializer(forDependencies: true);

    var collector = _InferenceDependenciesCollector();
    _node.initializer!.accept(collector);

    if (collector._set.isEmpty) {
      return const <_InferenceNode>[];
    }

    return collector._set.map(_walker.getNode).whereNotNull().toList();
  }

  @override
  void evaluate() {
    if (_elementImpl.hasTypeInferred) {
      return;
    }

    _resolveInitializer(forDependencies: false);

    var initializerType = _node.initializer!.typeOrThrow;
    initializerType = _refineType(initializerType);
    _elementImpl.type = initializerType;
    _elementImpl.hasTypeInferred = true;

    isEvaluated = true;
  }

  @override
  void markCircular(List<_InferenceNode> cycle) {
    _elementImpl.type = DynamicTypeImpl.instance;
    _elementImpl.hasTypeInferred = true;

    var cycleNames = <String>{};
    for (var inferenceNode in cycle) {
      cycleNames.add(inferenceNode.displayName);
    }

    _elementImpl.typeInferenceError = TopLevelInferenceError(
      kind: TopLevelInferenceErrorKind.dependencyCycle,
      arguments: cycleNames.toList(),
    );

    isEvaluated = true;
  }

  DartType _refineType(DartType type) {
    if (type.isDartCoreNull) {
      return DynamicTypeImpl.instance;
    }

    if (_typeSystem.isNonNullableByDefault) {
      return _typeSystem.nonNullifyLegacy(type);
    } else {
      if (type.isBottom) {
        return DynamicTypeImpl.instance;
      }
      return type;
    }
  }

  void _resolveInitializer({required bool forDependencies}) {
    var enclosingElement = _element.enclosingElement;
    var enclosingClassElement =
        enclosingElement is ClassElement ? enclosingElement : null;
    var astResolver = AstResolver(
        _walker._linker, _unitElement, _scope, _node.initializer!,
        enclosingClassElement: enclosingClassElement);
    astResolver.resolveExpression(() => _node.initializer!,
        buildElements: forDependencies);
  }
}
