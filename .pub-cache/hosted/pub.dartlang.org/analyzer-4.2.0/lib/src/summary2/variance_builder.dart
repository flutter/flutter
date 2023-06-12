// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';

class VarianceBuilder {
  final Linker _linker;
  final Set<TypeAlias> _pending = Set.identity();
  final Set<TypeAlias> _visit = Set.identity();

  VarianceBuilder(this._linker);

  void perform() {
    for (var builder in _linker.builders.values) {
      for (var linkingUnit in builder.units) {
        for (var node in linkingUnit.node.declarations) {
          if (node is FunctionTypeAlias) {
            _pending.add(node);
          } else if (node is GenericTypeAlias) {
            _pending.add(node);
          }
        }
      }
    }

    for (var builder in _linker.builders.values) {
      for (var linkingUnit in builder.units) {
        for (var node in linkingUnit.node.declarations) {
          if (node is ClassTypeAlias) {
            _typeParameters(node.typeParameters);
          } else if (node is ClassDeclaration) {
            _typeParameters(node.typeParameters);
          } else if (node is EnumDeclaration) {
            _typeParameters(node.typeParameters);
          } else if (node is FunctionTypeAlias) {
            _functionTypeAlias(node);
          } else if (node is GenericTypeAlias) {
            _genericTypeAlias(node);
          } else if (node is MixinDeclaration) {
            _typeParameters(node.typeParameters);
          }
        }
      }
    }
  }

  Variance _compute(TypeParameterElement variable, DartType? type) {
    if (type is TypeParameterType) {
      if (type.element == variable) {
        return Variance.covariant;
      } else {
        return Variance.unrelated;
      }
    } else if (type is NamedTypeBuilder) {
      var element = type.element;
      var arguments = type.arguments;
      if (element is ClassElement) {
        var result = Variance.unrelated;
        if (arguments.isNotEmpty) {
          var parameters = element.typeParameters;
          for (var i = 0; i < arguments.length && i < parameters.length; i++) {
            var parameter = parameters[i] as TypeParameterElementImpl;
            result = result.meet(
              parameter.variance.combine(
                _compute(variable, arguments[i]),
              ),
            );
          }
        }
        return result;
      } else if (element is TypeAliasElementImpl) {
        _typeAliasElement(element);

        var result = Variance.unrelated;

        if (arguments.isNotEmpty) {
          var parameters = element.typeParameters;
          for (var i = 0; i < arguments.length && i < parameters.length; i++) {
            var parameter = parameters[i] as TypeParameterElementImpl;
            var parameterVariance = parameter.variance;
            result = result.meet(
              parameterVariance.combine(
                _compute(variable, arguments[i]),
              ),
            );
          }
        }
        return result;
      }
    } else if (type is FunctionTypeBuilder) {
      return _computeFunctionType(
        variable,
        returnType: type.returnType,
        typeFormals: type.typeFormals,
        parameters: type.parameters,
      );
    }
    return Variance.unrelated;
  }

  Variance _computeFunctionType(
    TypeParameterElement variable, {
    required DartType? returnType,
    required List<TypeParameterElement>? typeFormals,
    required List<ParameterElement> parameters,
  }) {
    var result = Variance.unrelated;

    result = result.meet(
      _compute(variable, returnType),
    );

    // If [variable] is referenced in a bound at all, it makes the
    // variance of [variable] in the entire type invariant.
    if (typeFormals != null) {
      for (var parameter in typeFormals) {
        var bound = parameter.bound;
        if (bound != null && _compute(variable, bound) != Variance.unrelated) {
          result = Variance.invariant;
        }
      }
    }

    for (var parameter in parameters) {
      result = result.meet(
        Variance.contravariant.combine(
          _compute(variable, parameter.type),
        ),
      );
    }

    return result;
  }

  void _functionTypeAlias(FunctionTypeAlias node) {
    var parameterList = node.typeParameters;
    if (parameterList == null) {
      return;
    }

    // Recursion detected, recover.
    if (_visit.contains(node)) {
      for (var parameter in parameterList.typeParameters) {
        _setVariance(parameter, Variance.covariant);
      }
      return;
    }

    // Not being linked, or already linked.
    if (!_pending.remove(node)) {
      return;
    }

    _visit.add(node);
    try {
      for (var parameter in parameterList.typeParameters) {
        var variance = _computeFunctionType(
          parameter.declaredElement!,
          returnType: node.returnType?.type,
          typeFormals: null,
          parameters: FunctionTypeBuilder.getParameters(
            false,
            node.parameters,
          ),
        );
        _setVariance(parameter, variance);
      }
    } finally {
      _visit.remove(node);
    }
  }

  void _genericTypeAlias(GenericTypeAlias node) {
    var parameterList = node.typeParameters;
    if (parameterList == null) {
      return;
    }

    // Recursion detected, recover.
    if (_visit.contains(node)) {
      for (var parameter in parameterList.typeParameters) {
        _setVariance(parameter, Variance.covariant);
      }
      return;
    }

    // Not being linked, or already linked.
    if (!_pending.remove(node)) {
      return;
    }

    var type = node.type.type;

    // Not a function type, recover.
    if (type == null) {
      for (var parameter in parameterList.typeParameters) {
        _setVariance(parameter, Variance.covariant);
      }
    }

    _visit.add(node);
    try {
      for (var parameter in parameterList.typeParameters) {
        var variance = _compute(parameter.declaredElement!, type);
        _setVariance(parameter, variance);
      }
    } finally {
      _visit.remove(node);
    }
  }

  void _typeAliasElement(TypeAliasElementImpl element) {
    var node = _linker.getLinkingNode(element);
    if (node == null) {
      // Not linking.
    } else if (node is GenericTypeAlias) {
      _genericTypeAlias(node);
    } else if (node is FunctionTypeAlias) {
      _functionTypeAlias(node);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  void _typeParameters(TypeParameterList? parameterList) {
    if (parameterList == null) {
      return;
    }

    for (var parameter in parameterList.typeParameters) {
      var parameterImpl = parameter as TypeParameterImpl;
      var varianceKeyword = parameterImpl.varianceKeyword;
      if (varianceKeyword != null) {
        var variance = Variance.fromKeywordString(varianceKeyword.lexeme);
        _setVariance(parameter, variance);
      }
    }
  }

  static void _setVariance(TypeParameter node, Variance variance) {
    var element = node.declaredElement as TypeParameterElementImpl;
    element.variance = variance;
  }
}
