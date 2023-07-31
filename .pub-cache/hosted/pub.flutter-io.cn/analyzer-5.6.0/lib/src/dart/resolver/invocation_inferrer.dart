// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:_fe_analyzer_shared/src/deferred_function_literal_heuristic.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

Set<Object> _computeExplicitlyTypedParameterSet(
    FunctionExpression functionExpression) {
  List<FormalParameter> parameters =
      functionExpression.parameters?.parameters ?? const [];
  Set<Object> result = {};
  int unnamedParameterIndex = 0;
  for (var formalParameter in parameters) {
    var key = formalParameter.isNamed
        ? formalParameter.name?.lexeme ?? ''
        : unnamedParameterIndex++;
    if (formalParameter.isExplicitlyTyped) {
      result.add(key);
    }
  }
  return result;
}

/// Given an iterable of parameters, computes a map whose keys are either the
/// parameter name (for named parameters) or the zero-based integer index (for
/// unnamed parameters), and whose values are the parameters themselves.
Map<Object, ParameterElement> _computeParameterMap(
    Iterable<ParameterElement> parameters) {
  int unnamedParameterIndex = 0;
  return {
    for (var parameter in parameters)
      parameter.isNamed ? parameter.name : unnamedParameterIndex++: parameter
  };
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [Annotation] that resolve to a constructor invocation.
class AnnotationInferrer extends FullInvocationInferrer<AnnotationImpl> {
  /// The identifier pointing to the constructor that's being invoked, or `null`
  /// if a constructor name couldn't be found (should only happen when
  /// recovering from errors).  If the constructor is generic, this identifier's
  /// static element will be updated to point to a [ConstructorMember] with type
  /// arguments filled in.
  final SimpleIdentifierImpl? constructorName;

  AnnotationInferrer(
      {required super.resolver,
      required super.node,
      required super.argumentList,
      required super.contextType,
      required super.whyNotPromotedList,
      required this.constructorName})
      : super._();

  @override
  bool get _isConst => true;

  @override
  bool get _isGenericInferenceDisabled => !resolver.genericMetadataIsEnabled;

  @override
  bool get _needsTypeArgumentBoundsCheck => true;

  @override
  TypeArgumentListImpl? get _typeArguments => node.typeArguments;

  @override
  ErrorCode get _wrongNumberOfTypeArgumentsErrorCode =>
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS;

  @override
  List<ParameterElement>? _storeResult(
      List<DartType>? typeArgumentTypes, FunctionType? invokeType) {
    if (invokeType != null) {
      var constructorElement = ConstructorMember.from(
        node.element as ConstructorElement,
        invokeType.returnType as InterfaceType,
      );
      constructorName?.staticElement = constructorElement;
      node.element = constructorElement;
      return constructorElement.parameters;
    }
    return null;
  }
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes that require full downward and upward inference.
abstract class FullInvocationInferrer<Node extends AstNodeImpl>
    extends InvocationInferrer<Node> {
  FullInvocationInferrer._(
      {required super.resolver,
      required super.node,
      required super.argumentList,
      required super.contextType,
      required super.whyNotPromotedList});

  AstNode get _errorNode => node;

  bool get _isConst => false;

  bool get _isGenericInferenceDisabled => false;

  bool get _needsTypeArgumentBoundsCheck => false;

  TypeArgumentListImpl? get _typeArguments;

  ErrorCode get _wrongNumberOfTypeArgumentsErrorCode =>
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD;

  @override
  DartType resolveInvocation({required FunctionType? rawType}) {
    var typeArgumentList = _typeArguments;

    List<DartType>? typeArgumentTypes;
    GenericInferrer? inferrer;
    Substitution? substitution;
    if (_isGenericInferenceDisabled) {
      if (rawType != null && rawType.typeFormals.isNotEmpty) {
        typeArgumentTypes = List.filled(
          rawType.typeFormals.length,
          DynamicTypeImpl.instance,
        );
        substitution =
            Substitution.fromPairs(rawType.typeFormals, typeArgumentTypes);
      } else {
        typeArgumentTypes = const <DartType>[];
      }
    } else if (typeArgumentList != null) {
      if (rawType != null &&
          typeArgumentList.arguments.length != rawType.typeFormals.length) {
        var typeParameters = rawType.typeFormals;
        _reportWrongNumberOfTypeArguments(
            typeArgumentList, rawType, typeParameters);
        typeArgumentTypes = List.filled(
          typeParameters.length,
          DynamicTypeImpl.instance,
        );
      } else {
        typeArgumentTypes = typeArgumentList.arguments
            .map((typeArgument) => typeArgument.typeOrThrow)
            .toList(growable: true);
        if (rawType != null && _needsTypeArgumentBoundsCheck) {
          var typeParameters = rawType.typeFormals;
          var substitution = Substitution.fromPairs(
            typeParameters,
            typeArgumentTypes,
          );
          for (var i = 0; i < typeParameters.length; i++) {
            var typeParameter = typeParameters[i];
            var bound = typeParameter.bound;
            if (bound != null) {
              bound = resolver.definingLibrary.toLegacyTypeIfOptOut(bound);
              bound = substitution.substituteType(bound);
              var typeArgument = typeArgumentTypes[i];
              if (!resolver.typeSystem.isSubtypeOf(typeArgument, bound)) {
                resolver.errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
                  typeArgumentList.arguments[i],
                  [typeArgument, typeParameter.name, bound],
                );
              }
            }
          }
        }
      }

      if (rawType != null) {
        substitution =
            Substitution.fromPairs(rawType.typeFormals, typeArgumentTypes);
      }
    } else if (rawType == null || rawType.typeFormals.isEmpty) {
      typeArgumentTypes = const <DartType>[];
    } else {
      rawType = getFreshTypeParameters(rawType.typeFormals)
          .applyToFunctionType(rawType);

      inferrer = resolver.typeSystem.setupGenericTypeInference(
        typeParameters: rawType.typeFormals,
        declaredReturnType: rawType.returnType,
        contextReturnType: contextType,
        isConst: _isConst,
        errorReporter: resolver.errorReporter,
        errorNode: _errorNode,
        genericMetadataIsEnabled: resolver.genericMetadataIsEnabled,
      );

      substitution =
          Substitution.fromPairs(rawType.typeFormals, inferrer.partialInfer());
    }

    List<EqualityInfo<DartType>?>? identicalInfo = _isIdentical ? [] : null;
    var parameterMap = _computeParameterMap(rawType?.parameters ?? const []);
    var deferredFunctionLiterals = _visitArguments(
        parameterMap: parameterMap,
        identicalInfo: identicalInfo,
        substitution: substitution,
        inferrer: inferrer);
    if (deferredFunctionLiterals != null) {
      bool isFirstStage = true;
      for (var stage in _FunctionLiteralDependencies(
              resolver.typeSystem,
              deferredFunctionLiterals,
              rawType?.typeFormals.toSet() ?? const {},
              _computeUndeferredParamInfo(
                  rawType, parameterMap, deferredFunctionLiterals))
          .planReconciliationStages()) {
        if (inferrer != null && !isFirstStage) {
          substitution = Substitution.fromPairs(
              rawType!.typeFormals, inferrer.partialInfer());
        }
        _resolveDeferredFunctionLiterals(
            deferredFunctionLiterals: stage,
            identicalInfo: identicalInfo,
            substitution: substitution,
            inferrer: inferrer);
        isFirstStage = false;
      }
    }

    if (inferrer != null) {
      typeArgumentTypes = inferrer.upwardsInfer();
    }
    FunctionType? invokeType = typeArgumentTypes != null
        ? rawType?.instantiate(typeArgumentTypes)
        : rawType;

    var parameters = _storeResult(typeArgumentTypes, invokeType);
    if (parameters != null) {
      argumentList.correspondingStaticParameters =
          ResolverVisitor.resolveArgumentsToParameters(
        argumentList: argumentList,
        parameters: parameters,
        errorReporter: resolver.errorReporter,
      );
    }
    var returnType = _refineReturnType(
        InvocationInferrer.computeInvokeReturnType(invokeType));
    _recordIdenticalInfo(identicalInfo);
    return returnType;
  }

  /// Computes a list of [_ParamInfo] objects corresponding to the invocation
  /// parameters that were *not* deferred.
  List<_ParamInfo> _computeUndeferredParamInfo(
      FunctionType? rawType,
      Map<Object, ParameterElement> parameterMap,
      List<_DeferredParamInfo> deferredFunctionLiterals) {
    if (rawType == null) return const [];
    var parameterKeysAlreadyCovered = {
      for (var functionLiteral in deferredFunctionLiterals)
        functionLiteral.parameterKey
    };
    return [
      for (var entry in parameterMap.entries)
        if (!parameterKeysAlreadyCovered.contains(entry.key))
          _ParamInfo(entry.value)
    ];
  }

  DartType _refineReturnType(DartType returnType) => returnType;

  void _reportWrongNumberOfTypeArguments(TypeArgumentList typeArgumentList,
      FunctionType rawType, List<TypeParameterElement> typeParameters) {
    resolver.errorReporter.reportErrorForNode(
      _wrongNumberOfTypeArgumentsErrorCode,
      typeArgumentList,
      [
        rawType,
        typeParameters.length,
        typeArgumentList.arguments.length,
      ],
    );
  }

  List<ParameterElement>? _storeResult(
      List<DartType>? typeArgumentTypes, FunctionType? invokeType) {
    return invokeType?.parameters;
  }
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [FunctionExpressionInvocation].
class FunctionExpressionInvocationInferrer
    extends InvocationExpressionInferrer<FunctionExpressionInvocationImpl> {
  FunctionExpressionInvocationInferrer(
      {required super.resolver,
      required super.node,
      required super.argumentList,
      required super.contextType,
      required super.whyNotPromotedList})
      : super._();

  @override
  ExpressionImpl get _errorNode => node.function;
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [InstanceCreationExpression].
class InstanceCreationInferrer
    extends FullInvocationInferrer<InstanceCreationExpressionImpl> {
  InstanceCreationInferrer(
      {required super.resolver,
      required super.node,
      required super.argumentList,
      required super.contextType,
      required super.whyNotPromotedList})
      : super._();

  @override
  ConstructorNameImpl get _errorNode => node.constructorName;

  @override
  bool get _isConst => node.isConst;

  @override
  bool get _needsTypeArgumentBoundsCheck => true;

  @override
  TypeArgumentListImpl? get _typeArguments {
    // For an instance creation expression the type arguments are on the
    // constructor name.
    return node.constructorName.type.typeArguments;
  }

  @override
  void _reportWrongNumberOfTypeArguments(TypeArgumentList typeArgumentList,
      FunctionType rawType, List<TypeParameterElement> typeParameters) {
    // Error reporting for instance creations is done elsewhere.
  }

  @override
  List<ParameterElement>? _storeResult(
      List<DartType>? typeArgumentTypes, FunctionType? invokeType) {
    if (invokeType != null) {
      var constructedType = invokeType.returnType;
      node.constructorName.type.type = constructedType;
      var constructorElement = ConstructorMember.from(
        node.constructorName.staticElement!,
        constructedType as InterfaceType,
      );
      node.constructorName.staticElement = constructorElement;
      return constructorElement.parameters;
    }
    return null;
  }
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes derived from [InvocationExpression].
abstract class InvocationExpressionInferrer<
        Node extends InvocationExpressionImpl>
    extends FullInvocationInferrer<Node> {
  InvocationExpressionInferrer._(
      {required super.resolver,
      required super.node,
      required super.argumentList,
      required super.contextType,
      required super.whyNotPromotedList})
      : super._();

  @override
  Expression get _errorNode => node.function;

  @override
  TypeArgumentListImpl? get _typeArguments => node.typeArguments;

  @override
  List<ParameterElement>? _storeResult(
      List<DartType>? typeArgumentTypes, FunctionType? invokeType) {
    node.typeArgumentTypes = typeArgumentTypes;
    node.staticInvokeType = invokeType ?? DynamicTypeImpl.instance;
    return super._storeResult(typeArgumentTypes, invokeType);
  }
}

/// Base class containing functionality for performing type inference on AST
/// nodes that invoke a method, function, or constructor.
///
/// This class may be used directly for inference of [ExtensionOverride],
/// [RedirectingConstructorInvocation], or [SuperConstructorInvocation].
class InvocationInferrer<Node extends AstNodeImpl> {
  final ResolverVisitor resolver;
  final Node node;
  final ArgumentListImpl argumentList;
  final DartType? contextType;
  final List<WhyNotPromotedGetter> whyNotPromotedList;

  /// Prepares to perform type inference on an invocation expression of type
  /// [Node].
  InvocationInferrer(
      {required this.resolver,
      required this.node,
      required this.argumentList,
      required this.contextType,
      required this.whyNotPromotedList});

  /// Determines whether [node] is an invocation of the core function
  /// `identical` (which needs special flow analysis treatment).
  bool get _isIdentical => false;

  /// Performs type inference on the invocation expression.  [rawType] should be
  /// the type of the function the invocation is resolved to (with type
  /// arguments not applied yet).
  void resolveInvocation({required FunctionType? rawType}) {
    var deferredFunctionLiterals = _visitArguments(
        parameterMap: _computeParameterMap(rawType?.parameters ?? const []));
    if (deferredFunctionLiterals != null) {
      _resolveDeferredFunctionLiterals(
          deferredFunctionLiterals: deferredFunctionLiterals);
    }
  }

  /// Computes the type context that should be used when evaluating a particular
  /// argument of the invocation.  Usually this is just the type of the
  /// corresponding parameter, but it can be different for certain primitive
  /// numeric operations.
  DartType? _computeContextForArgument(DartType parameterType) => parameterType;

  /// If the invocation being processed is a call to `identical`, informs flow
  /// analysis about it, so that it can do appropriate promotions.
  void _recordIdenticalInfo(List<EqualityInfo<DartType>?>? identicalInfo) {
    var flow = resolver.flowAnalysis.flow;
    if (identicalInfo != null) {
      flow?.equalityOperation_end(argumentList.parent as Expression,
          identicalInfo[0], identicalInfo[1]);
    }
  }

  /// Resolves any function literals that were deferred by [_visitArguments].
  void _resolveDeferredFunctionLiterals(
      {required List<_DeferredParamInfo> deferredFunctionLiterals,
      List<EqualityInfo<DartType>?>? identicalInfo,
      Substitution? substitution,
      GenericInferrer? inferrer}) {
    var flow = resolver.flowAnalysis.flow;
    var arguments = argumentList.arguments;
    for (var deferredArgument in deferredFunctionLiterals) {
      var parameter = deferredArgument.parameter;
      DartType? parameterContextType;
      if (parameter != null) {
        var parameterType = parameter.type;
        if (substitution != null) {
          parameterType = substitution.substituteType(parameterType);
        }
        parameterContextType = _computeContextForArgument(parameterType);
      }
      var argument = arguments[deferredArgument.index];
      resolver.analyzeExpression(argument, parameterContextType);
      argument = resolver.popRewrite()!;
      if (flow != null) {
        identicalInfo?[deferredArgument.index] =
            flow.equalityOperand_end(argument, argument.typeOrThrow);
      }
      if (parameter != null) {
        inferrer?.constrainArgument(
            argument.typeOrThrow, parameter.type, parameter.name);
      }
    }
  }

  /// Visits [argumentList], resolving each argument.  If any arguments need to
  /// be deferred due to the `inference-update-1` feature, a list of them is
  /// returned.
  List<_DeferredParamInfo>? _visitArguments(
      {required Map<Object, ParameterElement> parameterMap,
      List<EqualityInfo<DartType>?>? identicalInfo,
      Substitution? substitution,
      GenericInferrer? inferrer}) {
    assert(whyNotPromotedList.isEmpty);
    List<_DeferredParamInfo>? deferredFunctionLiterals;
    resolver.checkUnreachableNode(argumentList);
    var flow = resolver.flowAnalysis.flow;
    var unnamedArgumentIndex = 0;
    var arguments = argumentList.arguments;
    for (int i = 0; i < arguments.length; i++) {
      var argument = arguments[i];
      Expression value;
      ParameterElement? parameter;
      Object parameterKey;
      if (argument is NamedExpressionImpl) {
        value = argument.expression;
        parameterKey = argument.name.label.name;
      } else {
        value = argument;
        parameterKey = unnamedArgumentIndex++;
      }
      value = value.unParenthesized;
      parameter = parameterMap[parameterKey];
      if (resolver.isInferenceUpdate1Enabled &&
          value is FunctionExpressionImpl) {
        (deferredFunctionLiterals ??= [])
            .add(_DeferredParamInfo(parameter, value, i, parameterKey));
        identicalInfo?.add(null);
        // The "why not promoted" list isn't really relevant for function
        // literals because promoting a function literal doesn't even make
        // sense.  So we store an innocuous value in the list.
        whyNotPromotedList.add(() => const {});
      } else {
        DartType? parameterContextType;
        if (parameter != null) {
          var parameterType = parameter.type;
          if (substitution != null) {
            parameterType = substitution.substituteType(parameterType);
          }
          parameterContextType = _computeContextForArgument(parameterType);
        }
        resolver.analyzeExpression(argument, parameterContextType);
        argument = resolver.popRewrite()!;
        if (flow != null) {
          identicalInfo
              ?.add(flow.equalityOperand_end(argument, argument.typeOrThrow));
          whyNotPromotedList.add(flow.whyNotPromoted(argument));
        }
        if (parameter != null) {
          inferrer?.constrainArgument(
              argument.typeOrThrow, parameter.type, parameter.name);
        }
      }
    }
    return deferredFunctionLiterals;
  }

  /// Computes the return type of the method or function represented by the
  /// given type that is being invoked.
  static DartType computeInvokeReturnType(DartType? type) {
    if (type is FunctionType) {
      return type.returnType;
    } else {
      return DynamicTypeImpl.instance;
    }
  }
}

/// Specialization of [InvocationInferrer] for performing type inference on AST
/// nodes of type [MethodInvocation].
class MethodInvocationInferrer
    extends InvocationExpressionInferrer<MethodInvocationImpl> {
  MethodInvocationInferrer(
      {required super.resolver,
      required super.node,
      required super.argumentList,
      required super.contextType,
      required super.whyNotPromotedList})
      : super._();

  @override
  bool get _isIdentical {
    var invokedMethod = node.methodName.staticElement;
    return invokedMethod is FunctionElement &&
        invokedMethod.isDartCoreIdentical &&
        node.argumentList.arguments.length == 2;
  }

  @override
  DartType? _computeContextForArgument(DartType parameterType) {
    var argumentContextType = super._computeContextForArgument(parameterType);
    var targetType = node.realTarget?.staticType;
    if (targetType != null) {
      argumentContextType = resolver.typeSystem.refineNumericInvocationContext(
          targetType,
          node.methodName.staticElement,
          contextType,
          parameterType);
    }
    return argumentContextType;
  }

  @override
  DartType _refineReturnType(DartType returnType) {
    var targetType = node.realTarget?.staticType;
    if (targetType != null) {
      returnType = resolver.typeSystem.refineNumericInvocationType(
        targetType,
        node.methodName.staticElement,
        [
          for (var argument in node.argumentList.arguments) argument.typeOrThrow
        ],
        returnType,
      );
    }
    return returnType;
  }
}

/// Information about an invocation argument that needs to be resolved later due
/// to the fact that it's a function literal and the `inference-update-1`
/// feature is enabled.
class _DeferredParamInfo extends _ParamInfo {
  /// The function literal expression.
  final FunctionExpression value;

  /// The index into the argument list of the function literal expression.
  final int index;

  final Object parameterKey;

  _DeferredParamInfo(
      super.parameter, this.value, this.index, this.parameterKey);
}

class _FunctionLiteralDependencies extends FunctionLiteralDependencies<
    TypeParameterElement, _ParamInfo, _DeferredParamInfo> {
  final TypeSystemImpl _typeSystem;

  final Set<TypeParameterElement> _typeVariables;

  _FunctionLiteralDependencies(
      this._typeSystem,
      Iterable<_DeferredParamInfo> deferredParamInfo,
      this._typeVariables,
      List<_ParamInfo> undeferredParamInfo)
      : super(deferredParamInfo, _typeVariables, undeferredParamInfo);

  @override
  Iterable<TypeParameterElement> typeVarsFreeInParamParams(
      _DeferredParamInfo paramInfo) {
    var type = paramInfo.parameter?.type;
    if (type is FunctionType) {
      var parameterMap = _computeParameterMap(type.parameters);
      var explicitlyTypedParameters =
          _computeExplicitlyTypedParameterSet(paramInfo.value);
      Set<TypeParameterElement> result = {};
      for (var entry in parameterMap.entries) {
        if (explicitlyTypedParameters.contains(entry.key)) continue;
        result.addAll(_typeSystem.getFreeParameters(entry.value.type,
                candidates: _typeVariables) ??
            const []);
      }
      return result;
    } else {
      return const [];
    }
  }

  @override
  Iterable<TypeParameterElement> typeVarsFreeInParamReturns(
      _ParamInfo paramInfo) {
    var type = paramInfo.parameter?.type;
    if (type is FunctionType) {
      return _typeSystem.getFreeParameters(type.returnType,
              candidates: _typeVariables) ??
          const [];
    } else if (type != null) {
      return _typeSystem.getFreeParameters(type, candidates: _typeVariables) ??
          const [];
    } else {
      return const [];
    }
  }
}

/// Information about an invocation argument that may or may not have already
/// been resolved, as part of the deferred resolution mechanism for the
/// `inference-update-1` feature.
class _ParamInfo {
  /// The function parameter corresponding to the argument, or `null` if we are
  /// resolving a dynamic invocation.
  final ParameterElement? parameter;

  _ParamInfo(this.parameter);
}
