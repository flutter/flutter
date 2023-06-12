// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/constant/from_environment_evaluator.dart';
import 'package:analyzer/src/dart/constant/has_type_parameter_reference.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart' show TypeSystemImpl;
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/task/api/model.dart';

/// Helper class encapsulating the methods for evaluating constants and
/// constant instance creation expressions.
class ConstantEvaluationEngine {
  /// The set of variables declared on the command line using '-D'.
  final DeclaredVariables _declaredVariables;

  /// Whether the `non-nullable` feature is enabled.
  final bool _isNonNullableByDefault;

  /// Initialize a newly created [ConstantEvaluationEngine].
  ///
  /// [declaredVariables] is the set of variables declared on the command
  /// line using '-D'.
  ConstantEvaluationEngine({
    required DeclaredVariables declaredVariables,
    required bool isNonNullableByDefault,
  })  : _declaredVariables = declaredVariables,
        _isNonNullableByDefault = isNonNullableByDefault;

  /// Compute the constant value associated with the given [constant].
  void computeConstantValue(ConstantEvaluationTarget constant) {
    if (constant is Element) {
      var element = constant as Element;
      constant = element.declaration as ConstantEvaluationTarget;
    }

    var library = constant.library as LibraryElementImpl;
    if (constant is ParameterElementImpl) {
      if (constant.isOptional) {
        var defaultValue = constant.constantInitializer;
        if (defaultValue != null) {
          RecordingErrorListener errorListener = RecordingErrorListener();
          ErrorReporter errorReporter = ErrorReporter(
            errorListener,
            constant.source!,
            isNonNullableByDefault: library.isNonNullableByDefault,
          );
          var dartObject = defaultValue
              .accept(ConstantVisitor(this, library, errorReporter));
          constant.evaluationResult =
              EvaluationResultImpl(dartObject, errorListener.errors);
        } else {
          constant.evaluationResult = EvaluationResultImpl(
            _nullObject(library),
          );
        }
      }
    } else if (constant is VariableElementImpl) {
      var constantInitializer = constant.constantInitializer;
      if (constantInitializer != null) {
        RecordingErrorListener errorListener = RecordingErrorListener();
        ErrorReporter errorReporter = ErrorReporter(
          errorListener,
          constant.source!,
          isNonNullableByDefault: library.isNonNullableByDefault,
        );
        var dartObject = constantInitializer
            .accept(ConstantVisitor(this, library, errorReporter));
        // Only check the type for truly const declarations (don't check final
        // fields with initializers, since their types may be generic.  The type
        // of the final field will be checked later, when the constructor is
        // invoked).
        if (dartObject != null && constant.isConst) {
          if (!library.typeSystem.runtimeTypeMatch(dartObject, constant.type)) {
            // TODO(brianwilkerson) This should not be reported if
            //  CompileTimeErrorCode.INVALID_ASSIGNMENT has already been
            //  reported (that is, if the static types are also wrong).
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH,
                constantInitializer,
                [dartObject.type, constant.type]);
          }
        }
        constant.evaluationResult =
            EvaluationResultImpl(dartObject, errorListener.errors);
      }
    } else if (constant is ConstructorElementImpl) {
      if (constant.isConst) {
        // No evaluation needs to be done; constructor declarations are only in
        // the dependency graph to ensure that any constants referred to in
        // initializer lists and parameter defaults are evaluated before
        // invocations of the constructor.
        constant.isConstantEvaluated = true;
      }
    } else if (constant is ElementAnnotationImpl) {
      var constNode = constant.annotationAst;
      var element = constant.element;
      if (element is PropertyAccessorElement) {
        // The annotation is a reference to a compile-time constant variable.
        // Just copy the evaluation result.
        VariableElementImpl variableElement =
            element.variable.declaration as VariableElementImpl;
        if (variableElement.evaluationResult != null) {
          constant.evaluationResult = variableElement.evaluationResult;
        } else {
          // This could happen in the event that the annotation refers to a
          // non-constant.  The error is detected elsewhere, so just silently
          // ignore it here.
          constant.evaluationResult = EvaluationResultImpl(null);
        }
      } else if (element is ConstructorElement &&
          element.isConst &&
          constNode.arguments != null) {
        RecordingErrorListener errorListener = RecordingErrorListener();
        ErrorReporter errorReporter = ErrorReporter(
          errorListener,
          constant.source,
          isNonNullableByDefault: library.isNonNullableByDefault,
        );
        ConstantVisitor constantVisitor =
            ConstantVisitor(this, library, errorReporter);
        var result = evaluateConstructorCall(
            library,
            constNode,
            element.returnType.typeArguments,
            constNode.arguments!.arguments,
            element,
            constantVisitor,
            errorReporter);
        constant.evaluationResult =
            EvaluationResultImpl(result, errorListener.errors);
      } else {
        // This may happen for invalid code (e.g. failing to pass arguments
        // to an annotation which references a const constructor).  The error
        // is detected elsewhere, so just silently ignore it here.
        constant.evaluationResult = EvaluationResultImpl(null);
      }
    } else if (constant is VariableElement) {
      // constant is a VariableElement but not a VariableElementImpl.  This can
      // happen sometimes in the case of invalid user code (for example, a
      // constant expression that refers to a non-static field inside a generic
      // class will wind up referring to a FieldMember).  The error is detected
      // elsewhere, so just silently ignore it here.
    } else {
      // Should not happen.
      assert(false);
      AnalysisEngine.instance.instrumentationService
          .logError("Constant value computer trying to compute "
              "the value of a node of type ${constant.runtimeType}");
      return;
    }
  }

  /// Determine which constant elements need to have their values computed
  /// prior to computing the value of [constant], and report them using
  /// [callback].
  void computeDependencies(
      ConstantEvaluationTarget constant, ReferenceFinderCallback callback) {
    ReferenceFinder referenceFinder = ReferenceFinder(callback);
    if (constant is ConstructorElement) {
      constant = constant.declaration;
    }
    if (constant is VariableElement) {
      var declaration = constant.declaration as VariableElementImpl;
      var initializer = declaration.constantInitializer;
      if (initializer != null) {
        initializer.accept(referenceFinder);
      }
    } else if (constant is ConstructorElementImpl) {
      if (constant.isConst) {
        var redirectedConstructor = getConstRedirectedConstructor(constant);
        if (redirectedConstructor != null) {
          var redirectedConstructorBase = redirectedConstructor.declaration;
          callback(redirectedConstructorBase);
          return;
        } else if (constant.isFactory) {
          // Factory constructor, but getConstRedirectedConstructor returned
          // null.  This can happen if we're visiting one of the special
          // external const factory constructors in the SDK, or if the code
          // contains errors (such as delegating to a non-const constructor, or
          // delegating to a constructor that can't be resolved).  In any of
          // these cases, we'll evaluate calls to this constructor without
          // having to refer to any other constants.  So we don't need to report
          // any dependencies.
          return;
        }
        bool defaultSuperInvocationNeeded = true;
        var initializers = constant.constantInitializers;
        for (ConstructorInitializer initializer in initializers) {
          if (initializer is SuperConstructorInvocation ||
              initializer is RedirectingConstructorInvocation) {
            defaultSuperInvocationNeeded = false;
          }
          initializer.accept(referenceFinder);
        }
        if (defaultSuperInvocationNeeded) {
          // No explicit superconstructor invocation found, so we need to
          // manually insert a reference to the implicit superconstructor.
          var superclass = constant.returnType.superclass;
          if (superclass != null && !superclass.isDartCoreObject) {
            var unnamedConstructor =
                superclass.element.unnamedConstructor?.declaration;
            if (unnamedConstructor != null) {
              callback(unnamedConstructor);
            }
          }
        }
        for (FieldElement field in constant.enclosingElement.fields) {
          // Note: non-static const isn't allowed but we handle it anyway so
          // that we won't be confused by incorrect code.
          if ((field.isFinal || field.isConst) &&
              !field.isStatic &&
              field.hasInitializer) {
            callback(field);
          }
        }
        for (ParameterElement parameterElement in constant.parameters) {
          callback(parameterElement);
        }
      }
    } else if (constant is ElementAnnotationImpl) {
      Annotation constNode = constant.annotationAst;
      var element = constant.element;
      if (element is PropertyAccessorElement) {
        // The annotation is a reference to a compile-time constant variable,
        // so it depends on the variable.
        callback(element.variable.declaration);
      } else if (element is ConstructorElement) {
        // The annotation is a constructor invocation, so it depends on the
        // constructor.
        callback(element.declaration);
      } else {
        // This could happen in the event of invalid code.  The error will be
        // reported at constant evaluation time.
      }
      if (constNode.arguments != null) {
        constNode.arguments!.accept(referenceFinder);
      }
    } else if (constant is VariableElement) {
      // constant is a VariableElement but not a VariableElementImpl.  This can
      // happen sometimes in the case of invalid user code (for example, a
      // constant expression that refers to a non-static field inside a generic
      // class will wind up referring to a FieldMember).  So just don't bother
      // computing any dependencies.
    } else {
      // Should not happen.
      assert(false);
      AnalysisEngine.instance.instrumentationService
          .logError("Constant value computer trying to compute "
              "the value of a node of type ${constant.runtimeType}");
    }
  }

  DartObjectImpl? evaluateConstructorCall(
    LibraryElementImpl library,
    AstNode node,
    List<DartType>? typeArguments,
    List<Expression> arguments,
    ConstructorElement constructor,
    ConstantVisitor constantVisitor,
    ErrorReporter errorReporter, {
    ConstructorInvocation? invocation,
  }) {
    return _InstanceCreationEvaluator.evaluate(
      this,
      _declaredVariables,
      errorReporter,
      library,
      node,
      constructor,
      typeArguments,
      arguments,
      constantVisitor,
      isNullSafe: _isNonNullableByDefault,
      invocation: invocation,
    );
  }

  /// Generate an error indicating that the given [constant] is not a valid
  /// compile-time constant because it references at least one of the constants
  /// in the given [cycle], each of which directly or indirectly references the
  /// constant.
  void generateCycleError(
    Iterable<ConstantEvaluationTarget> cycle,
    ConstantEvaluationTarget constant,
  ) {
    if (constant is VariableElement) {
      RecordingErrorListener errorListener = RecordingErrorListener();
      ErrorReporter errorReporter = ErrorReporter(
        errorListener,
        constant.source!,
        isNonNullableByDefault: constant.library!.isNonNullableByDefault,
      );
      // TODO(paulberry): It would be really nice if we could extract enough
      // information from the 'cycle' argument to provide the user with a
      // description of the cycle.
      errorReporter.reportErrorForElement(
          CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, constant, []);
      (constant as VariableElementImpl).evaluationResult =
          EvaluationResultImpl(null, errorListener.errors);
    } else if (constant is ConstructorElement) {
      // We don't report cycle errors on constructor declarations since there
      // is nowhere to put the error information.
    } else {
      // Should not happen.  Formal parameter defaults and annotations should
      // never appear as part of a cycle because they can't be referred to.
      assert(false);
      AnalysisEngine.instance.instrumentationService
          .logError("Constant value computer trying to report a cycle error "
              "for a node of type ${constant.runtimeType}");
    }
  }

  /// If [constructor] redirects to another const constructor, return the
  /// const constructor it redirects to.  Otherwise return `null`.
  static ConstructorElement? getConstRedirectedConstructor(
      ConstructorElement constructor) {
    if (!constructor.isFactory) {
      return null;
    }
    var typeProvider = constructor.library.typeProvider;
    if (constructor.enclosingElement == typeProvider.symbolElement) {
      // The dart:core.Symbol has a const factory constructor that redirects
      // to dart:_internal.Symbol.  That in turn redirects to an external
      // const constructor, which we won't be able to evaluate.
      // So stop following the chain of redirections at dart:core.Symbol, and
      // let [evaluateInstanceCreationExpression] handle it specially.
      return null;
    }
    var redirectedConstructor = constructor.redirectedConstructor;
    if (redirectedConstructor == null) {
      // This can happen if constructor is an external factory constructor.
      return null;
    }
    if (!redirectedConstructor.isConst) {
      // Delegating to a non-const constructor--this is not allowed (and
      // is checked elsewhere--see
      // [ErrorVerifier.checkForRedirectToNonConstConstructor()]).
      return null;
    }
    return redirectedConstructor;
  }

  static DartObjectImpl _nullObject(LibraryElementImpl library) {
    return DartObjectImpl(
      library.typeSystem,
      library.typeProvider.nullType,
      NullState.NULL_STATE,
    );
  }
}

/// Interface for [AnalysisTarget]s for which constant evaluation can be
/// performed.
abstract class ConstantEvaluationTarget extends AnalysisTarget {
  /// Return the [AnalysisContext] which should be used to evaluate this
  /// constant.
  AnalysisContext get context;

  /// Return whether this constant is evaluated.
  bool get isConstantEvaluated;

  /// The library with this constant.
  LibraryElement? get library;
}

/// Interface used by unit tests to verify correct dependency analysis during
/// constant evaluation.
abstract class ConstantEvaluationValidator {
  /// This method is called just before computing the constant value associated
  /// with [constant]. Unit tests will override this method to introduce
  /// additional error checking.
  void beforeComputeValue(ConstantEvaluationTarget constant);

  /// This method is called just before getting the constant initializers
  /// associated with the [constructor]. Unit tests will override this method to
  /// introduce additional error checking.
  void beforeGetConstantInitializers(ConstructorElement constructor);

  /// This method is called just before retrieving an evaluation result from an
  /// element. Unit tests will override it to introduce additional error
  /// checking.
  void beforeGetEvaluationResult(ConstantEvaluationTarget constant);

  /// This method is called just before getting the constant value of a field
  /// with an initializer.  Unit tests will override this method to introduce
  /// additional error checking.
  void beforeGetFieldEvaluationResult(FieldElementImpl field);

  /// This method is called just before getting a parameter's default value.
  /// Unit tests will override this method to introduce additional error
  /// checking.
  void beforeGetParameterDefault(ParameterElement parameter);
}

/// Implementation of [ConstantEvaluationValidator] used in production; does no
/// validation.
class ConstantEvaluationValidator_ForProduction
    implements ConstantEvaluationValidator {
  @override
  void beforeComputeValue(ConstantEvaluationTarget constant) {}

  @override
  void beforeGetConstantInitializers(ConstructorElement constructor) {}

  @override
  void beforeGetEvaluationResult(ConstantEvaluationTarget constant) {}

  @override
  void beforeGetFieldEvaluationResult(FieldElementImpl field) {}

  @override
  void beforeGetParameterDefault(ParameterElement parameter) {}
}

/// A visitor used to evaluate constant expressions to produce their
/// compile-time value.
class ConstantVisitor extends UnifyingAstVisitor<DartObjectImpl> {
  /// The evaluation engine used to access the feature set, type system, and
  /// type provider.
  final ConstantEvaluationEngine evaluationEngine;

  /// The library that contains the constant expression being evaluated.
  final LibraryElementImpl _library;

  /// A mapping of variable names to runtime values.
  final Map<String, DartObjectImpl>? _lexicalEnvironment;

  /// A mapping of type parameter names to runtime values (types).
  final Map<TypeParameterElement, DartType>? _lexicalTypeEnvironment;

  final Substitution? _substitution;

  /// Error reporter that we use to report errors accumulated while computing
  /// the constant.
  final ErrorReporter _errorReporter;

  /// Helper class used to compute constant values.
  late final DartObjectComputer _dartObjectComputer;

  /// Initialize a newly created constant visitor. The [evaluationEngine] is
  /// used to evaluate instance creation expressions. The [lexicalEnvironment]
  /// is a map containing values which should override identifiers, or `null` if
  /// no overriding is necessary. The [_errorReporter] is used to report errors
  /// found during evaluation.  The [validator] is used by unit tests to verify
  /// correct dependency analysis.
  ///
  /// The [substitution] is specified for instance creations.
  ConstantVisitor(
    this.evaluationEngine,
    this._library,
    this._errorReporter, {
    Map<String, DartObjectImpl>? lexicalEnvironment,
    Map<TypeParameterElement, DartType>? lexicalTypeEnvironment,
    Substitution? substitution,
  })  : _lexicalEnvironment = lexicalEnvironment,
        _lexicalTypeEnvironment = lexicalTypeEnvironment,
        _substitution = substitution {
    _dartObjectComputer = DartObjectComputer(
      typeSystem,
      _errorReporter,
    );
  }

  /// Convenience getter to gain access to the [evaluationEngine]'s type system.
  TypeSystemImpl get typeSystem => _library.typeSystem;

  bool get _isNonNullableByDefault => typeSystem.isNonNullableByDefault;

  /// Convenience getter to gain access to the [evaluationEngine]'s type
  /// provider.
  TypeProvider get _typeProvider => _library.typeProvider;

  @override
  DartObjectImpl? visitAdjacentStrings(AdjacentStrings node) {
    DartObjectImpl? result;
    for (StringLiteral string in node.strings) {
      if (result == null) {
        result = string.accept(this);
      } else {
        result =
            _dartObjectComputer.concatenate(node, result, string.accept(this));
      }
    }
    return result;
  }

  @override
  DartObjectImpl? visitAsExpression(AsExpression node) {
    var expressionResult = node.expression.accept(this);
    var typeResult = node.type.accept(this);
    return _dartObjectComputer.castToType(node, expressionResult, typeResult);
  }

  @override
  DartObjectImpl? visitBinaryExpression(BinaryExpression node) {
    TokenType operatorType = node.operator.type;
    var leftResult = node.leftOperand.accept(this);
    // evaluate lazy operators
    if (operatorType == TokenType.AMPERSAND_AMPERSAND) {
      if (leftResult?.toBoolValue() == false) {
        _reportNotPotentialConstants(node.rightOperand);
      }
      return _dartObjectComputer.lazyAnd(
          node, leftResult, () => node.rightOperand.accept(this));
    } else if (operatorType == TokenType.BAR_BAR) {
      if (leftResult?.toBoolValue() == true) {
        _reportNotPotentialConstants(node.rightOperand);
      }
      return _dartObjectComputer.lazyOr(
          node, leftResult, () => node.rightOperand.accept(this));
    } else if (operatorType == TokenType.QUESTION_QUESTION) {
      if (leftResult?.isNull != true) {
        _reportNotPotentialConstants(node.rightOperand);
      }
      return _dartObjectComputer.lazyQuestionQuestion(
          node, leftResult, () => node.rightOperand.accept(this));
    }
    // evaluate eager operators
    var rightResult = node.rightOperand.accept(this);
    if (operatorType == TokenType.AMPERSAND) {
      return _dartObjectComputer.eagerAnd(node, leftResult, rightResult);
    } else if (operatorType == TokenType.BANG_EQ) {
      return _dartObjectComputer.notEqual(node, leftResult, rightResult);
    } else if (operatorType == TokenType.BAR) {
      return _dartObjectComputer.eagerOr(node, leftResult, rightResult);
    } else if (operatorType == TokenType.CARET) {
      return _dartObjectComputer.eagerXor(node, leftResult, rightResult);
    } else if (operatorType == TokenType.EQ_EQ) {
      return _dartObjectComputer.lazyEqualEqual(node, leftResult, rightResult);
    } else if (operatorType == TokenType.GT) {
      return _dartObjectComputer.greaterThan(node, leftResult, rightResult);
    } else if (operatorType == TokenType.GT_EQ) {
      return _dartObjectComputer.greaterThanOrEqual(
          node, leftResult, rightResult);
    } else if (operatorType == TokenType.GT_GT) {
      return _dartObjectComputer.shiftRight(node, leftResult, rightResult);
    } else if (operatorType == TokenType.GT_GT_GT) {
      return _dartObjectComputer.logicalShiftRight(
          node, leftResult, rightResult);
    } else if (operatorType == TokenType.LT) {
      return _dartObjectComputer.lessThan(node, leftResult, rightResult);
    } else if (operatorType == TokenType.LT_EQ) {
      return _dartObjectComputer.lessThanOrEqual(node, leftResult, rightResult);
    } else if (operatorType == TokenType.LT_LT) {
      return _dartObjectComputer.shiftLeft(node, leftResult, rightResult);
    } else if (operatorType == TokenType.MINUS) {
      return _dartObjectComputer.minus(node, leftResult, rightResult);
    } else if (operatorType == TokenType.PERCENT) {
      return _dartObjectComputer.remainder(node, leftResult, rightResult);
    } else if (operatorType == TokenType.PLUS) {
      return _dartObjectComputer.add(node, leftResult, rightResult);
    } else if (operatorType == TokenType.STAR) {
      return _dartObjectComputer.times(node, leftResult, rightResult);
    } else if (operatorType == TokenType.SLASH) {
      return _dartObjectComputer.divide(node, leftResult, rightResult);
    } else if (operatorType == TokenType.TILDE_SLASH) {
      return _dartObjectComputer.integerDivide(node, leftResult, rightResult);
    } else {
      // TODO(https://github.com/dart-lang/sdk/issues/47061): Use a specific
      // error code.
      _error(node, null);
      return null;
    }
  }

  @override
  DartObjectImpl visitBooleanLiteral(BooleanLiteral node) {
    return DartObjectImpl(
      typeSystem,
      _typeProvider.boolType,
      BoolState.from(node.value),
    );
  }

  @override
  DartObjectImpl? visitConditionalExpression(ConditionalExpression node) {
    var condition = node.condition;
    var conditionResult = condition.accept(this);

    if (conditionResult == null) {
      return conditionResult;
    } else if (!conditionResult.isBool) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, condition);
      return null;
    }
    conditionResult =
        _dartObjectComputer.applyBooleanConversion(condition, conditionResult);
    if (conditionResult == null) {
      return conditionResult;
    }

    var conditionResultBool = conditionResult.toBoolValue();
    if (conditionResultBool == null) {
      node.thenExpression.accept(this);
      node.elseExpression.accept(this);
    } else if (conditionResultBool == true) {
      _reportNotPotentialConstants(node.elseExpression);
      return node.thenExpression.accept(this);
    } else if (conditionResultBool == false) {
      _reportNotPotentialConstants(node.thenExpression);
      return node.elseExpression.accept(this);
    }

    // We used to return an object with a known type and an unknown value, but
    // we can't do that without evaluating both the 'then' and 'else'
    // expressions, and we're not suppose to do that under lazy semantics. I'm
    // not sure which failure mode is worse.
    return null;
  }

  @override
  DartObjectImpl? visitConstructorReference(ConstructorReference node) {
    var constructorFunctionType = node.typeOrThrow as FunctionType;
    var classType = constructorFunctionType.returnType as InterfaceType;
    var typeArguments = classType.typeArguments;
    // The result is already instantiated during resolution;
    // [_dartObjectComputer.typeInstantiate] is unnecessary.
    var typeElement =
        node.constructorName.type2.name.staticElement as TypeDefiningElement;

    TypeAliasElement? viaTypeAlias;
    if (typeElement is TypeAliasElementImpl) {
      if (constructorFunctionType.typeFormals.isNotEmpty &&
          !typeElement.isProperRename) {
        // The type alias is not a proper rename of the aliased class, so
        // the constructor tear-off is distinct from the associated
        // constructor function of the aliased class.
        viaTypeAlias = typeElement;
      }
    }

    return DartObjectImpl(
      typeSystem,
      node.typeOrThrow,
      FunctionState(node.constructorName.staticElement,
          typeArguments: typeArguments, viaTypeAlias: viaTypeAlias),
    );
  }

  @override
  DartObjectImpl visitDoubleLiteral(DoubleLiteral node) {
    return DartObjectImpl(
      typeSystem,
      _typeProvider.doubleType,
      DoubleState(node.value),
    );
  }

  @override
  DartObjectImpl? visitFunctionReference(FunctionReference node) {
    var functionResult = node.function.accept(this);
    if (functionResult == null) {
      return functionResult;
    }

    // Report an error if any of the _inferred_ type argument types refer to a
    // type parameter. If, however, `node.typeArguments` is not `null`, then
    // any type parameters contained therein are reported as non-constant in
    // [ConstantVerifier].
    if (node.typeArguments == null) {
      var typeArgumentTypes = node.typeArgumentTypes;
      if (typeArgumentTypes != null) {
        var instantiatedTypeArgumentTypes = typeArgumentTypes.map((type) {
          if (type is TypeParameterType) {
            return _lexicalTypeEnvironment?[type.element] ?? type;
          } else {
            return type;
          }
        });
        if (instantiatedTypeArgumentTypes.any(hasTypeParameterReference)) {
          _error(node, null);
        }
      }
    }

    var typeArgumentList = node.typeArguments;
    if (typeArgumentList == null) {
      return _instantiateFunctionType(node, functionResult);
    }

    var typeArguments = <DartType>[];
    for (var typeArgument in typeArgumentList.arguments) {
      var object = typeArgument.accept(this);
      if (object == null) {
        return null;
      }
      var typeArgumentType = object.toTypeValue();
      if (typeArgumentType == null) {
        return null;
      }
      // TODO(srawlins): Test type alias types (`typedef i = int`) used as
      // type arguments. Possibly change implementation based on
      // canonicalization rules.
      typeArguments.add(typeArgumentType);
    }
    return _dartObjectComputer.typeInstantiate(functionResult, typeArguments);
  }

  @override
  DartObjectImpl visitGenericFunctionType(GenericFunctionType node) {
    return DartObjectImpl(
      typeSystem,
      _typeProvider.typeType,
      TypeState(node.type),
    );
  }

  @override
  DartObjectImpl? visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    if (!node.isConst) {
      // TODO(https://github.com/dart-lang/sdk/issues/47061): Use a specific
      // error code.
      _error(node, null);
      return null;
    }
    var constructor = node.constructorName.staticElement;
    if (constructor == null) {
      // Couldn't resolve the constructor so we can't compute a value.  No
      // problem - the error has already been reported.
      return null;
    }

    return evaluationEngine.evaluateConstructorCall(
      _library,
      node,
      constructor.returnType.typeArguments,
      node.argumentList.arguments,
      constructor,
      this,
      _errorReporter,
    );
  }

  @override
  DartObjectImpl visitIntegerLiteral(IntegerLiteral node) {
    if (node.staticType == _typeProvider.doubleType) {
      return DartObjectImpl(
        typeSystem,
        _typeProvider.doubleType,
        DoubleState(node.value?.toDouble()),
      );
    }
    return DartObjectImpl(
      typeSystem,
      _typeProvider.intType,
      IntState(node.value),
    );
  }

  @override
  DartObjectImpl? visitInterpolationExpression(InterpolationExpression node) {
    var result = node.expression.accept(this);
    if (result != null && !result.isBoolNumStringOrNull) {
      _error(node, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
      return null;
    }
    return _dartObjectComputer.performToString(node, result);
  }

  @override
  DartObjectImpl visitInterpolationString(InterpolationString node) {
    return DartObjectImpl(
      typeSystem,
      _typeProvider.stringType,
      StringState(node.value),
    );
  }

  @override
  DartObjectImpl? visitIsExpression(IsExpression node) {
    var expressionResult = node.expression.accept(this);
    var typeResult = node.type.accept(this);
    return _dartObjectComputer.typeTest(node, expressionResult, typeResult);
  }

  @override
  DartObjectImpl? visitListLiteral(ListLiteral node) {
    if (!node.isConst) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL, node);
      return null;
    }
    bool errorOccurred = false;
    List<DartObjectImpl> list = [];
    for (CollectionElement element in node.elements) {
      errorOccurred = errorOccurred | _addElementsToList(list, element);
    }
    if (errorOccurred) {
      return null;
    }
    var nodeType = node.staticType;
    DartType elementType =
        nodeType is InterfaceType && nodeType.typeArguments.isNotEmpty
            ? nodeType.typeArguments[0]
            : _typeProvider.dynamicType;
    InterfaceType listType = _typeProvider.listType(elementType);
    return DartObjectImpl(typeSystem, listType, ListState(list));
  }

  @override
  DartObjectImpl? visitMethodInvocation(MethodInvocation node) {
    var element = node.methodName.staticElement;
    if (element is FunctionElement) {
      if (element.name == "identical") {
        NodeList<Expression> arguments = node.argumentList.arguments;
        if (arguments.length == 2) {
          var enclosingElement = element.enclosingElement;
          if (enclosingElement is CompilationUnitElement) {
            LibraryElement library = enclosingElement.library;
            if (library.isDartCore) {
              var leftArgument = arguments[0].accept(this);
              var rightArgument = arguments[1].accept(this);
              return _dartObjectComputer.isIdentical(
                  node, leftArgument, rightArgument);
            }
          }
        }
      }
    }
    // TODO(https://github.com/dart-lang/sdk/issues/47061): Use a specific
    // error code.
    _error(node, null);
    return null;
  }

  @override
  DartObjectImpl? visitNamedExpression(NamedExpression node) =>
      node.expression.accept(this);

  @override
  DartObjectImpl? visitNamedType(NamedType node) {
    var type = node.type;

    if (type == null) {
      return null;
    }

    if (!_isNonNullableByDefault && hasTypeParameterReference(type)) {
      return super.visitNamedType(node);
    }

    if (_substitution != null) {
      type = _substitution!.substituteType(type);
    }

    return DartObjectImpl(
      typeSystem,
      _typeProvider.typeType,
      TypeState(type),
    );
  }

  @override
  DartObjectImpl? visitNode(AstNode node) {
    // TODO(https://github.com/dart-lang/sdk/issues/47061): Use a specific
    // error code.
    _error(node, null);
    return null;
  }

  @override
  DartObjectImpl visitNullLiteral(NullLiteral node) {
    return ConstantEvaluationEngine._nullObject(_library);
  }

  @override
  DartObjectImpl? visitParenthesizedExpression(ParenthesizedExpression node) =>
      node.expression.accept(this);

  @override
  DartObjectImpl? visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixNode = node.prefix;
    var prefixElement = prefixNode.staticElement;
    // String.length
    if (prefixElement is! PrefixElement &&
        prefixElement is! ClassElement &&
        prefixElement is! ExtensionElement) {
      var prefixResult = prefixNode.accept(this);
      if (prefixResult != null &&
          _isStringLength(prefixResult, node.identifier)) {
        return prefixResult.stringLength(typeSystem);
      }
    }
    // importPrefix.CONST
    if (prefixElement is! PrefixElement && prefixElement is! ExtensionElement) {
      var prefixResult = prefixNode.accept(this);
      if (prefixResult == null) {
        // The error has already been reported.
        return null;
      }
    }
    // Validate prefixed identifier.
    return _getConstantValue(node, node.identifier);
  }

  @override
  DartObjectImpl? visitPrefixExpression(PrefixExpression node) {
    var operand = node.operand.accept(this);
    if (operand != null && operand.isNull) {
      _error(node, CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
      return null;
    }
    if (node.operator.type == TokenType.BANG) {
      return _dartObjectComputer.logicalNot(node, operand);
    } else if (node.operator.type == TokenType.TILDE) {
      return _dartObjectComputer.bitNot(node, operand);
    } else if (node.operator.type == TokenType.MINUS) {
      return _dartObjectComputer.negated(node, operand);
    } else {
      // TODO(https://github.com/dart-lang/sdk/issues/47061): Use a specific
      // error code.
      _error(node, null);
      return null;
    }
  }

  @override
  DartObjectImpl? visitPropertyAccess(PropertyAccess node) {
    var target = node.target;
    if (target != null) {
      var prefixResult = target.accept(this);
      if (prefixResult != null &&
          _isStringLength(prefixResult, node.propertyName)) {
        return prefixResult.stringLength(typeSystem);
      }
    }
    return _getConstantValue(node, node.propertyName);
  }

  @override
  DartObjectImpl? visitSetOrMapLiteral(SetOrMapLiteral node) {
    // Note: due to dartbug.com/33441, it's possible that a set/map literal
    // resynthesized from a summary will have neither its `isSet` or `isMap`
    // boolean set to `true`.  We work around the problem by assuming such
    // literals are maps.
    // TODO(paulberry): when dartbug.com/33441 is fixed, add an assertion here
    // to verify that `node.isSet == !node.isMap`.
    bool isMap = !node.isSet;
    if (isMap) {
      if (!node.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL, node);
        return null;
      }
      bool errorOccurred = false;
      Map<DartObjectImpl, DartObjectImpl> map = {};
      for (CollectionElement element in node.elements) {
        errorOccurred = errorOccurred | _addElementsToMap(map, element);
      }
      if (errorOccurred) {
        return null;
      }
      DartType keyType = _typeProvider.dynamicType;
      DartType valueType = _typeProvider.dynamicType;
      var nodeType = node.staticType;
      if (nodeType is InterfaceType) {
        var typeArguments = nodeType.typeArguments;
        if (typeArguments.length >= 2) {
          keyType = typeArguments[0];
          valueType = typeArguments[1];
        }
      }
      InterfaceType mapType = _typeProvider.mapType(keyType, valueType);
      return DartObjectImpl(typeSystem, mapType, MapState(map));
    } else {
      if (!node.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MISSING_CONST_IN_SET_LITERAL, node);
        return null;
      }
      bool errorOccurred = false;
      Set<DartObjectImpl> set = <DartObjectImpl>{};
      for (CollectionElement element in node.elements) {
        errorOccurred = errorOccurred | _addElementsToSet(set, element);
      }
      if (errorOccurred) {
        return null;
      }
      var nodeType = node.staticType;
      DartType elementType =
          nodeType is InterfaceType && nodeType.typeArguments.isNotEmpty
              ? nodeType.typeArguments[0]
              : _typeProvider.dynamicType;
      InterfaceType setType = _typeProvider.setType(elementType);
      return DartObjectImpl(typeSystem, setType, SetState(set));
    }
  }

  @override
  DartObjectImpl? visitSimpleIdentifier(SimpleIdentifier node) {
    var value = _lexicalEnvironment?[node.name];
    if (value != null) {
      return _instantiateFunctionTypeForSimpleIdentifier(node, value);
    }

    return _getConstantValue(node, node);
  }

  @override
  DartObjectImpl visitSimpleStringLiteral(SimpleStringLiteral node) {
    return DartObjectImpl(
      typeSystem,
      _typeProvider.stringType,
      StringState(node.value),
    );
  }

  @override
  DartObjectImpl? visitStringInterpolation(StringInterpolation node) {
    DartObjectImpl? result;
    bool first = true;
    for (InterpolationElement element in node.elements) {
      if (first) {
        result = element.accept(this);
        first = false;
      } else {
        result =
            _dartObjectComputer.concatenate(node, result, element.accept(this));
      }
    }
    return result;
  }

  @override
  DartObjectImpl visitSymbolLiteral(SymbolLiteral node) {
    StringBuffer buffer = StringBuffer();
    List<Token> components = node.components;
    for (int i = 0; i < components.length; i++) {
      if (i > 0) {
        buffer.writeCharCode(0x2E);
      }
      buffer.write(components[i].lexeme);
    }
    return DartObjectImpl(
      typeSystem,
      _typeProvider.symbolType,
      SymbolState(buffer.toString()),
    );
  }

  @override
  DartObjectImpl? visitTypeLiteral(TypeLiteral node) {
    return node.type.accept(this);
  }

  /// Add the entries produced by evaluating the given collection [element] to
  /// the given [list]. Return `true` if the evaluation of one or more of the
  /// elements failed.
  bool _addElementsToList(List<DartObject> list, CollectionElement element) {
    if (element is ForElement) {
      _error(element, null);
    } else if (element is IfElement) {
      var conditionValue = _evaluateCondition(element.condition);
      if (conditionValue == null) {
        return true;
      } else if (conditionValue) {
        return _addElementsToList(list, element.thenElement);
      } else if (element.elseElement != null) {
        return _addElementsToList(list, element.elseElement!);
      }
      return false;
    } else if (element is Expression) {
      var value = element.accept(this);
      if (value == null) {
        return true;
      }
      list.add(value);
      return false;
    } else if (element is SpreadElement) {
      var elementResult = element.expression.accept(this);
      var value = elementResult?.toListValue();
      if (value == null) {
        return true;
      }
      list.addAll(value);
      return false;
    }
    // This error should have been reported elsewhere.
    return true;
  }

  /// Add the entries produced by evaluating the given map [element] to the
  /// given [map]. Return `true` if the evaluation of one or more of the entries
  /// failed.
  bool _addElementsToMap(
      Map<DartObjectImpl, DartObjectImpl> map, CollectionElement element) {
    if (element is ForElement) {
      _error(element, null);
    } else if (element is IfElement) {
      var conditionValue = _evaluateCondition(element.condition);
      if (conditionValue == null) {
        return true;
      } else if (conditionValue) {
        return _addElementsToMap(map, element.thenElement);
      } else if (element.elseElement != null) {
        return _addElementsToMap(map, element.elseElement!);
      }
      return false;
    } else if (element is MapLiteralEntry) {
      var keyResult = element.key.accept(this);
      var valueResult = element.value.accept(this);
      if (keyResult == null || valueResult == null) {
        return true;
      }
      map[keyResult] = valueResult;
      return false;
    } else if (element is SpreadElement) {
      var elementResult = element.expression.accept(this);
      var value = elementResult?.toMapValue();
      if (value == null) {
        return true;
      }
      map.addAll(value);
      return false;
    }
    // This error should have been reported elsewhere.
    return true;
  }

  /// Add the entries produced by evaluating the given collection [element] to
  /// the given [set]. Return `true` if the evaluation of one or more of the
  /// elements failed.
  bool _addElementsToSet(Set<DartObject> set, CollectionElement element) {
    if (element is ForElement) {
      _error(element, null);
    } else if (element is IfElement) {
      var conditionValue = _evaluateCondition(element.condition);
      if (conditionValue == null) {
        return true;
      } else if (conditionValue) {
        return _addElementsToSet(set, element.thenElement);
      } else if (element.elseElement != null) {
        return _addElementsToSet(set, element.elseElement!);
      }
      return false;
    } else if (element is Expression) {
      var value = element.accept(this);
      if (value == null) {
        return true;
      }
      set.add(value);
      return false;
    } else if (element is SpreadElement) {
      var elementResult = element.expression.accept(this);
      var value = elementResult?.toSetValue();
      if (value == null) {
        return true;
      }
      set.addAll(value);
      return false;
    }
    // This error should have been reported elsewhere.
    return true;
  }

  /// Create an error associated with the given [node]. The error will have the
  /// given error [code].
  void _error(AstNode node, ErrorCode? code) {
    if (code == null) {
      var parent = node.parent;
      var parent2 = parent?.parent;
      if (parent is ArgumentList &&
          parent2 is InstanceCreationExpression &&
          parent2.isConst) {
        code = CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT;
      } else {
        code = CompileTimeErrorCode.INVALID_CONSTANT;
      }
    }
    _errorReporter.reportErrorForNode(code, node);
  }

  /// Evaluate the given [condition] with the assumption that it must be a
  /// `bool`.
  bool? _evaluateCondition(Expression condition) {
    var conditionResult = condition.accept(this);
    var conditionValue = conditionResult?.toBoolValue();
    if (conditionValue == null) {
      if (conditionResult?.type != _typeProvider.boolType) {
        // TODO(brianwilkerson) Figure out why the static type is sometimes null.
        var staticType = condition.staticType;
        if (staticType == null ||
            typeSystem.isAssignableTo(staticType, _typeProvider.boolType)) {
          // If the static type is not assignable, then we will have already
          // reported this error.
          // TODO(mfairhurst) get the FeatureSet to suppress this for nnbd too.
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, condition);
        }
      }
    }
    return conditionValue;
  }

  /// Return the constant value of the static constant represented by the given
  /// [identifier]. The [node] is the node to be used if an error needs to be
  /// reported.
  DartObjectImpl? _getConstantValue(
      Expression node, SimpleIdentifier identifier) {
    var element = identifier.staticElement;
    element = element?.declaration;
    var variableElement =
        element is PropertyAccessorElement ? element.variable : element;

    // TODO(srawlins): Remove this check when [FunctionReference]s are inserted
    // for generic function instantiation for pre-constructor-references code.
    if (node is SimpleIdentifier &&
        (node.tearOffTypeArgumentTypes?.any(hasTypeParameterReference) ??
            false)) {
      _error(node, null);
    }

    if (variableElement is VariableElementImpl) {
      // We access values of constant variables here in two cases: when we
      // compute values of other constant variables, or when we compute values
      // and errors for other constant expressions. In either case we have
      // already computed values of all dependencies first (or detect a cycle),
      // so the value has already been computed and we can just return it.
      var result = variableElement.evaluationResult;
      if (variableElement.isConst && result != null) {
        var value = result.value;
        if (value == null) {
          return value;
        }
        return _instantiateFunctionTypeForSimpleIdentifier(identifier, value);
      }
    } else if (variableElement is ConstructorElement) {
      return DartObjectImpl(
        typeSystem,
        node.typeOrThrow,
        FunctionState(variableElement),
      );
    } else if (variableElement is ExecutableElement) {
      var function = element as ExecutableElement;
      if (function.isStatic) {
        var rawType = DartObjectImpl(
          typeSystem,
          function.type,
          FunctionState(function),
        );
        return _instantiateFunctionTypeForSimpleIdentifier(identifier, rawType);
      }
    } else if (variableElement is ClassElement) {
      var type = variableElement.instantiate(
        typeArguments: variableElement.typeParameters
            .map((t) => _typeProvider.dynamicType)
            .toList(),
        nullabilitySuffix: NullabilitySuffix.star,
      );
      return DartObjectImpl(
        typeSystem,
        _typeProvider.typeType,
        TypeState(type),
      );
    } else if (variableElement is DynamicElementImpl) {
      return DartObjectImpl(
        typeSystem,
        _typeProvider.typeType,
        TypeState(_typeProvider.dynamicType),
      );
    } else if (variableElement is TypeAliasElement) {
      var type = variableElement.instantiate(
        typeArguments: variableElement.typeParameters
            .map((t) => t.bound ?? _typeProvider.dynamicType)
            .toList(),
        nullabilitySuffix: NullabilitySuffix.star,
      );
      return DartObjectImpl(
        typeSystem,
        _typeProvider.typeType,
        TypeState(type),
      );
    } else if (variableElement is NeverElementImpl) {
      return DartObjectImpl(
        typeSystem,
        _typeProvider.typeType,
        TypeState(_typeProvider.neverType),
      );
    } else if (variableElement is TypeParameterElement) {
      // Constants may refer to type parameters only if the constructor-tearoffs
      // feature is enabled.
      if (_library.featureSet.isEnabled(Feature.constructor_tearoffs)) {
        var typeArgument = _lexicalTypeEnvironment?[identifier.staticElement];
        if (typeArgument != null) {
          return DartObjectImpl(
            typeSystem,
            _typeProvider.typeType,
            TypeState(typeArgument),
          );
        }
      }
    }

    // TODO(https://github.com/dart-lang/sdk/issues/47061): Use a specific
    // error code.
    _error(node, null);
    return null;
  }

  /// If the type of [value] is a generic [FunctionType], and [node] has type
  /// argument types, returns [value] type-instantiated with those [node]'s
  /// type argument types, otherwise returns [value].
  DartObjectImpl? _instantiateFunctionType(
      FunctionReference node, DartObjectImpl value) {
    var functionElement = value.toFunctionValue();
    if (functionElement is! ExecutableElement) {
      return value;
    }
    var valueType = functionElement.type;
    if (valueType.typeFormals.isNotEmpty) {
      var typeArgumentTypes = node.typeArgumentTypes;
      if (typeArgumentTypes != null && typeArgumentTypes.isNotEmpty) {
        var instantiatedType =
            functionElement.type.instantiate(typeArgumentTypes);
        var substitution = _substitution;
        if (substitution != null) {
          instantiatedType =
              substitution.substituteType(instantiatedType) as FunctionType;
        }
        return value.typeInstantiate(
            typeSystem, instantiatedType, typeArgumentTypes);
      }
    }
    return value;
  }

  /// If the type of [value] is a generic [FunctionType], and [node] is a
  /// [SimpleIdentifier] with tear-off type argument types, returns [value]
  /// type-instantiated with those [node]'s tear-off type argument types,
  /// otherwise returns [value].
  DartObjectImpl? _instantiateFunctionTypeForSimpleIdentifier(
      SimpleIdentifier node, DartObjectImpl value) {
    // TODO(srawlins): When all code uses [FunctionReference]s generated via
    // generic function instantiation, remove this method and all call sites.
    var functionElement = value.toFunctionValue();
    if (functionElement is! ExecutableElement) {
      return value;
    }
    var valueType = functionElement.type;
    if (valueType.typeFormals.isNotEmpty) {
      var tearOffTypeArgumentTypes = node.tearOffTypeArgumentTypes;
      if (tearOffTypeArgumentTypes != null &&
          tearOffTypeArgumentTypes.isNotEmpty) {
        var instantiatedType =
            functionElement.type.instantiate(tearOffTypeArgumentTypes);
        return value.typeInstantiate(
            typeSystem, instantiatedType, tearOffTypeArgumentTypes);
      }
    }
    return value;
  }

  /// Return `true` if the given [targetResult] represents a string and the
  /// [identifier] is "length".
  bool _isStringLength(
      DartObjectImpl targetResult, SimpleIdentifier identifier) {
    if (targetResult.type.element != _typeProvider.stringElement) {
      return false;
    }
    return identifier.name == 'length' &&
        identifier.staticElement?.enclosingElement is! ExtensionElement;
  }

  void _reportNotPotentialConstants(AstNode node) {
    var notPotentiallyConstants = getNotPotentiallyConstants(
      node,
      featureSet: _library.featureSet,
    );
    if (notPotentiallyConstants.isEmpty) return;

    for (var notConst in notPotentiallyConstants) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_CONSTANT,
        notConst,
      );
    }
  }

  /// Return the value of the given [expression], or a representation of 'null'
  /// if the expression cannot be evaluated.
  DartObjectImpl _valueOf(Expression expression) {
    var expressionValue = expression.accept(this);
    if (expressionValue != null) {
      return expressionValue;
    }
    return ConstantEvaluationEngine._nullObject(_library);
  }
}

/// A utility class that contains methods for manipulating instances of a Dart
/// class and for collecting errors during evaluation.
class DartObjectComputer {
  final TypeSystemImpl _typeSystem;

  /// The error reporter that we are using to collect errors.
  final ErrorReporter _errorReporter;

  DartObjectComputer(this._typeSystem, this._errorReporter);

  DartObjectImpl? add(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.add(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
        return null;
      }
    }
    return null;
  }

  /// Return the result of applying boolean conversion to the
  /// [evaluationResult]. The [node] is the node against which errors should be
  /// reported.
  DartObjectImpl? applyBooleanConversion(
      AstNode node, DartObjectImpl? evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.convertToBool(_typeSystem);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? bitNot(Expression node, DartObjectImpl? evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.bitNot(_typeSystem);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? castToType(
      AsExpression node, DartObjectImpl? expression, DartObjectImpl? type) {
    if (expression != null && type != null) {
      try {
        return expression.castToType(_typeSystem, type);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? concatenate(Expression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.concatenate(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? divide(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.divide(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? eagerAnd(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.eagerAnd(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? eagerOr(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.eagerOr(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? eagerQuestionQuestion(Expression node,
      DartObjectImpl? leftOperand, DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      if (leftOperand.isNull) {
        return rightOperand;
      }
      return leftOperand;
    }
    return null;
  }

  DartObjectImpl? eagerXor(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.eagerXor(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? equalEqual(Expression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.equalEqual(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? greaterThan(BinaryExpression node,
      DartObjectImpl? leftOperand, DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.greaterThan(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? greaterThanOrEqual(BinaryExpression node,
      DartObjectImpl? leftOperand, DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.greaterThanOrEqual(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? integerDivide(BinaryExpression node,
      DartObjectImpl? leftOperand, DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.integerDivide(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? isIdentical(Expression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.isIdentical2(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? lazyAnd(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? Function() rightOperandComputer) {
    if (leftOperand != null) {
      try {
        return leftOperand.lazyAnd(_typeSystem, rightOperandComputer);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? lazyEqualEqual(Expression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.lazyEqualEqual(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? lazyOr(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? Function() rightOperandComputer) {
    if (leftOperand != null) {
      try {
        return leftOperand.lazyOr(_typeSystem, rightOperandComputer);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? lazyQuestionQuestion(
      Expression node,
      DartObjectImpl? leftOperand,
      DartObjectImpl? Function() rightOperandComputer) {
    if (leftOperand != null) {
      if (leftOperand.isNull) {
        return rightOperandComputer();
      }
      return leftOperand;
    }
    return null;
  }

  DartObjectImpl? lessThan(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.lessThan(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? lessThanOrEqual(BinaryExpression node,
      DartObjectImpl? leftOperand, DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.lessThanOrEqual(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? logicalNot(
      Expression node, DartObjectImpl? evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.logicalNot(_typeSystem);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? logicalShiftRight(BinaryExpression node,
      DartObjectImpl? leftOperand, DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.logicalShiftRight(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? minus(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.minus(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? negated(Expression node, DartObjectImpl? evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.negated(_typeSystem);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? notEqual(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.notEqual(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? performToString(
      AstNode node, DartObjectImpl? evaluationResult) {
    if (evaluationResult != null) {
      try {
        return evaluationResult.performToString(_typeSystem);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? remainder(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.remainder(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? shiftLeft(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.shiftLeft(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? shiftRight(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.shiftRight(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  /// Return the result of invoking the 'length' getter on the
  /// [evaluationResult]. The [node] is the node against which errors should be
  /// reported.
  EvaluationResultImpl? stringLength(
      Expression node, EvaluationResultImpl evaluationResult) {
    var value = evaluationResult.value;
    if (value != null) {
      try {
        return EvaluationResultImpl(value.stringLength(_typeSystem));
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return EvaluationResultImpl(null);
  }

  DartObjectImpl? times(BinaryExpression node, DartObjectImpl? leftOperand,
      DartObjectImpl? rightOperand) {
    if (leftOperand != null && rightOperand != null) {
      try {
        return leftOperand.times(_typeSystem, rightOperand);
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }

  DartObjectImpl? typeInstantiate(
    DartObjectImpl function,
    List<DartType> typeArguments,
  ) {
    var rawType = function.type;
    if (rawType is FunctionType) {
      if (typeArguments.length != rawType.typeFormals.length) {
        return null;
      }
      var type = rawType.instantiate(typeArguments);
      return function.typeInstantiate(_typeSystem, type, typeArguments);
    } else {
      return null;
    }
  }

  DartObjectImpl? typeTest(
      IsExpression node, DartObjectImpl? expression, DartObjectImpl? type) {
    if (expression != null && type != null) {
      try {
        DartObjectImpl result = expression.hasType(_typeSystem, type);
        if (node.notOperator != null) {
          return result.logicalNot(_typeSystem);
        }
        return result;
      } on EvaluationException catch (exception) {
        _errorReporter.reportErrorForNode(exception.errorCode, node);
      }
    }
    return null;
  }
}

/// The result of attempting to evaluate an expression.
class EvaluationResult {
  // TODO(brianwilkerson) Merge with EvaluationResultImpl
  /// The value of the expression.
  final DartObject? value;

  /// The errors that should be reported for the expression(s) that were
  /// evaluated.
  final List<AnalysisError>? _errors;

  /// Initialize a newly created result object with the given [value] and set of
  /// [_errors]. Clients should use one of the factory methods: [forErrors] and
  /// [forValue].
  EvaluationResult(this.value, this._errors);

  /// Return a list containing the errors that should be reported for the
  /// expression(s) that were evaluated. If there are no such errors, the list
  /// will be empty. The list can be empty even if the expression is not a valid
  /// compile time constant if the errors would have been reported by other
  /// parts of the analysis engine.
  List<AnalysisError> get errors => _errors ?? AnalysisError.NO_ERRORS;

  /// Return `true` if the expression is a compile-time constant expression that
  /// would not throw an exception when evaluated.
  bool get isValid => _errors == null;

  /// Return an evaluation result representing the result of evaluating an
  /// expression that is not a compile-time constant because of the given
  /// [errors].
  static EvaluationResult forErrors(List<AnalysisError> errors) =>
      EvaluationResult(null, errors);

  /// Return an evaluation result representing the result of evaluating an
  /// expression that is a compile-time constant that evaluates to the given
  /// [value].
  static EvaluationResult forValue(DartObject value) =>
      EvaluationResult(value, null);
}

/// The result of attempting to evaluate a expression.
class EvaluationResultImpl {
  /// The errors encountered while trying to evaluate the compile time constant.
  /// These errors may or may not have prevented the expression from being a
  /// valid compile time constant.
  late final List<AnalysisError> _errors;

  /// The value of the expression, or `null` if the value couldn't be computed
  /// due to errors.
  final DartObjectImpl? value;

  EvaluationResultImpl(this.value, [List<AnalysisError>? errors]) {
    _errors = errors ?? <AnalysisError>[];
  }

  List<AnalysisError> get errors => _errors;

  bool equalValues(TypeProvider typeProvider, EvaluationResultImpl result) {
    if (value != null) {
      if (result.value == null) {
        return false;
      }
      return value == result.value;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    if (value == null) {
      return "error";
    }
    return value.toString();
  }
}

/// The result of evaluation the initializers declared on a const constructor.
class _InitializersEvaluationResult {
  /// The result of a const evaluation of an initializer, if one was performed,
  /// otherwise `null`.
  ///
  /// If a redirecting initializer which redirects to a const constructor was
  /// encountered, [result] is the result of evaluating that call.
  ///
  /// If an assert initializer is encountered, and the evaluation of this assert
  /// results in an error or a `false` value, [result] is `null`.
  final DartObjectImpl? result;

  /// Whether evaluation of the const instance creation expression which led to
  /// evaluating constructor initializers is complete.
  ///
  /// If `true`, `result` should be used as the result of said const instance
  /// creation expression evaluation.
  final bool evaluationIsComplete;

  /// If a superinitializer was encountered, the name of the super constructor,
  /// otherwise `null`.
  final String? superName;

  /// If a superinitializer was encountered, the arguments passed to the super
  /// constructor, otherwise `null`.
  final NodeList<Expression>? superArguments;

  _InitializersEvaluationResult(
    this.result, {
    required this.evaluationIsComplete,
    this.superName,
    this.superArguments,
  });
}

/// An evaluator which evaluates a const instance creation expression.
///
/// [_InstanceCreationEvaluator.evaluate] is the main entrypoint.
class _InstanceCreationEvaluator {
  /// Parameter to "fromEnvironment" methods that denotes the default value.
  static const String _default_value_param = 'defaultValue';

  /// Source of RegExp matching declarable operator names.
  /// From sdk/lib/internal/symbol.dart.
  static const String _operator_pattern =
      "(?:[\\-+*/%&|^]|\\[\\]=?|==|~/?|<[<=]?|>[>=]?|unary-)";

  /// Source of RegExp matching any public identifier.
  /// From sdk/lib/internal/symbol.dart.
  static const String _public_identifier_pattern =
      "(?!$_reserved_word_pattern\\b(?!\\\$))[a-zA-Z\$][\\w\$]*";

  /// RegExp that validates a non-empty non-private symbol.
  /// From sdk/lib/internal/symbol.dart.
  static final RegExp _public_symbol_pattern =
      RegExp('^(?:$_operator_pattern\$|'
          '$_public_identifier_pattern(?:=?\$|[.](?!\$)))+?\$');

  /// Source of RegExp matching Dart reserved words.
  /// From sdk/lib/internal/symbol.dart.
  static const String _reserved_word_pattern =
      "(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|"
      "d(?:efault|o)|e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|"
      "i[fns]|n(?:ew|ull)|ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|"
      "r(?:ue|y))|v(?:ar|oid)|w(?:hile|ith))";

  final ConstantEvaluationEngine _evaluationEngine;

  /// The set of variables declared on the command line using '-D'.
  final DeclaredVariables _declaredVariables;

  final LibraryElementImpl _library;

  final ErrorReporter _errorReporter;

  final BooleanErrorListener _externalErrorListener = BooleanErrorListener();

  /// An error reporter for errors determined while computing values for field
  /// initializers, or default values for the constructor parameters.
  ///
  /// Such errors cannot be reported into [_errorReporter], because they usually
  /// happen in a different source. But they still should cause a constant
  /// evaluation error for the current node.
  late final ErrorReporter _externalErrorReporter = ErrorReporter(
    _externalErrorListener,
    _constructor.source,
    isNonNullableByDefault: _library.isNonNullableByDefault,
  );

  late final ConstantVisitor _initializerVisitor = ConstantVisitor(
    _evaluationEngine,
    _constructor.library as LibraryElementImpl,
    _externalErrorReporter,
    lexicalEnvironment: _parameterMap,
    lexicalTypeEnvironment: _typeParameterMap,
    substitution: Substitution.fromInterfaceType(definingType),
  );

  /// The node used for most error reporting.
  final AstNode _errorNode;

  final ConstructorElement _constructor;

  final List<DartType>? _typeArguments;

  final ConstructorInvocation _invocation;

  final Map<String, NamedExpression> _namedNodes;

  final Map<String, DartObjectImpl> _namedValues;

  final List<DartObjectImpl> _argumentValues;

  final Map<TypeParameterElement, DartType> _typeParameterMap = HashMap();

  final Map<String, DartObjectImpl> _parameterMap = HashMap();

  final Map<String, DartObjectImpl> _fieldMap = HashMap();

  /// Constructor for [_InstanceCreationEvaluator].
  ///
  /// This constructor is private, as the entry point for using a
  /// [_InstanceCreationEvaluator] is the static method,
  /// [_InstanceCreationEvaluator.evaluate].
  _InstanceCreationEvaluator._(
    this._evaluationEngine,
    this._declaredVariables,
    this._errorReporter,
    this._library,
    this._errorNode,
    this._constructor,
    this._typeArguments, {
    required Map<String, NamedExpression> namedNodes,
    required Map<String, DartObjectImpl> namedValues,
    required List<DartObjectImpl> argumentValues,
    required ConstructorInvocation invocation,
  })  : _namedNodes = namedNodes,
        _namedValues = namedValues,
        _argumentValues = argumentValues,
        _invocation = invocation;

  InterfaceType get definingType => _constructor.returnType;

  DartObjectImpl? get firstArgument => _argumentValues[0];

  TypeProvider get typeProvider => _library.typeProvider;

  TypeSystemImpl get typeSystem => _library.typeSystem;

  /// Evaluates this constructor call as a factory constructor call.
  DartObjectImpl? evaluateFactoryConstructorCall(
    List<Expression> arguments, {
    required bool isNullSafe,
  }) {
    ClassElement definingClass = _constructor.enclosingElement;
    var argumentCount = arguments.length;
    if (_constructor.name == "fromEnvironment") {
      if (!_checkFromEnvironmentArguments(arguments, definingType)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, _errorNode);
        return null;
      }
      String? variableName =
          argumentCount < 1 ? null : firstArgument?.toStringValue();
      if (definingClass == typeProvider.boolElement) {
        return FromEnvironmentEvaluator(typeSystem, _declaredVariables)
            .getBool2(variableName, _namedValues, _constructor);
      } else if (definingClass == typeProvider.intElement) {
        return FromEnvironmentEvaluator(typeSystem, _declaredVariables)
            .getInt2(variableName, _namedValues, _constructor);
      } else if (definingClass == typeProvider.stringElement) {
        return FromEnvironmentEvaluator(typeSystem, _declaredVariables)
            .getString2(variableName, _namedValues, _constructor);
      }
    } else if (_constructor.name == 'hasEnvironment' &&
        definingClass == typeProvider.boolElement) {
      var name = argumentCount < 1 ? null : firstArgument?.toStringValue();
      return FromEnvironmentEvaluator(typeSystem, _declaredVariables)
          .hasEnvironment(name);
    } else if (_constructor.name == "" &&
        definingClass == typeProvider.symbolElement &&
        argumentCount == 1) {
      if (!_checkSymbolArguments(arguments, isNullSafe: isNullSafe)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, _errorNode);
        return null;
      }
      return DartObjectImpl(
        typeSystem,
        definingType,
        SymbolState(firstArgument?.toStringValue()),
      );
    }
    // Either it's an external const factory constructor that we can't
    // emulate, or an error occurred (a cycle, or a const constructor trying to
    // delegate to a non-const constructor).
    //
    // In the former case, the best we can do is consider it an unknown value.
    // In the latter case, the error has already been reported, so considering
    // it an unknown value will suppress further errors.
    return DartObjectImpl.validWithUnknownValue(typeSystem, definingType);
  }

  DartObjectImpl? evaluateGenerativeConstructorCall(
      List<Expression> arguments) {
    // Start with final fields that are initialized at their declaration site.
    _checkFields();

    _checkTypeParameters();
    _checkParameters(arguments);
    var evaluationResult = _checkInitializers();
    if (evaluationResult.evaluationIsComplete) {
      return evaluationResult.result;
    }
    _checkSuperConstructorCall(
        superName: evaluationResult.superName,
        superArguments: evaluationResult.superArguments);
    if (_externalErrorListener.errorReported) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, _errorNode);
    }
    return DartObjectImpl(
      typeSystem,
      definingType,
      GenericState(_fieldMap, invocation: _invocation),
    );
  }

  void _checkFields() {
    var fields = _constructor.enclosingElement.fields;
    for (var field in fields) {
      if ((field.isFinal || field.isConst) &&
          !field.isStatic &&
          field is ConstFieldElementImpl) {
        var fieldValue = field.evaluationResult?.value;

        // It is possible that the evaluation result is null.
        // This happens for example when we have duplicate fields.
        // `class Test {final x = 1; final x = 2; const Test();}`
        if (fieldValue == null) {
          continue;
        }
        // Match the value and the type.
        var fieldType = FieldMember.from(field, _constructor.returnType).type;
        if (!typeSystem.runtimeTypeMatch(fieldValue, fieldType)) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
              _errorNode,
              [fieldValue.type, field.name, fieldType]);
        }
        _fieldMap[field.name] = fieldValue;
      }
    }
  }

  /// Check that the arguments to a call to `fromEnvironment()` are correct.
  ///
  /// The [arguments] are the AST nodes of the arguments. The [argumentValues]
  /// are the values of the unnamed arguments. The [namedArgumentValues] are the
  /// values of the named arguments. The [expectedDefaultValueType] is the
  /// allowed type of the "defaultValue" parameter (if present). Note:
  /// "defaultValue" is always allowed to be `null`. Return `true` if the
  /// arguments are correct, `false` otherwise.
  bool _checkFromEnvironmentArguments(
    List<Expression> arguments,
    InterfaceType expectedDefaultValueType,
  ) {
    var argumentCount = arguments.length;
    if (argumentCount < 1 || argumentCount > 2) {
      return false;
    }
    if (arguments[0] is NamedExpression) {
      return false;
    }
    if (firstArgument!.type != typeProvider.stringType) {
      return false;
    }
    if (argumentCount == 2) {
      var secondArgument = arguments[1];
      if (secondArgument is NamedExpression) {
        if (!(secondArgument.name.label.name == _default_value_param)) {
          return false;
        }
        var defaultValueType = _namedValues[_default_value_param]!.type;
        if (!(defaultValueType == expectedDefaultValueType ||
            defaultValueType == typeProvider.nullType)) {
          return false;
        }
      } else {
        return false;
      }
    }
    return true;
  }

  _InitializersEvaluationResult _checkInitializers() {
    var constructorBase = _constructor.declaration as ConstructorElementImpl;
    // If we encounter a superinitializer, store the name of the constructor,
    // and the arguments.
    String? superName;
    NodeList<Expression>? superArguments;
    for (var initializer in constructorBase.constantInitializers) {
      if (initializer is ConstructorFieldInitializer) {
        var initializerExpression = initializer.expression;
        var evaluationResult =
            initializerExpression.accept(_initializerVisitor);
        if (evaluationResult != null) {
          var fieldName = initializer.fieldName.name;
          if (_fieldMap.containsKey(fieldName)) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, _errorNode);
          }
          _fieldMap[fieldName] = evaluationResult;
          var getter = definingType.getGetter(fieldName);
          if (getter != null) {
            var field = getter.variable;
            if (!typeSystem.runtimeTypeMatch(evaluationResult, field.type)) {
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
                  _errorNode,
                  [evaluationResult.type, fieldName, field.type]);
            }
          }
        } else {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, _errorNode);
        }
      } else if (initializer is SuperConstructorInvocation) {
        var name = initializer.constructorName;
        if (name != null) {
          superName = name.name;
        }
        superArguments = initializer.argumentList.arguments;
      } else if (initializer is RedirectingConstructorInvocation) {
        // This is a redirecting constructor, so just evaluate the constructor
        // it redirects to.
        var constructor = initializer.staticElement;
        if (constructor != null && constructor.isConst) {
          // Instantiate the constructor with the in-scope type arguments.
          constructor = ConstructorMember.from(constructor, definingType);
          var result = _evaluationEngine.evaluateConstructorCall(
              _library,
              _errorNode,
              _typeArguments,
              initializer.argumentList.arguments,
              constructor,
              _initializerVisitor,
              _externalErrorReporter,
              invocation: _invocation);
          if (_externalErrorListener.errorReported) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, _errorNode);
          }
          return _InitializersEvaluationResult(result,
              evaluationIsComplete: true);
        }
      } else if (initializer is AssertInitializer) {
        var condition = initializer.condition;
        var evaluationResult = condition.accept(_initializerVisitor);
        if (evaluationResult == null ||
            !evaluationResult.isBool ||
            evaluationResult.toBoolValue() == false) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, _errorNode);
          return _InitializersEvaluationResult(null,
              evaluationIsComplete: true);
        }
      }
    }
    return _InitializersEvaluationResult(null,
        evaluationIsComplete: false,
        superName: superName,
        superArguments: superArguments);
  }

  void _checkParameters(List<Expression> arguments) {
    var parameters = _constructor.parameters;
    var parameterCount = parameters.length;

    for (var i = 0; i < parameterCount; i++) {
      var parameter = parameters[i];
      var baseParameter = parameter.declaration;
      DartObjectImpl? argumentValue;
      AstNode? errorTarget;
      if (baseParameter.isNamed) {
        argumentValue = _namedValues[baseParameter.name];
        errorTarget = _namedNodes[baseParameter.name];
      } else if (i < _argumentValues.length) {
        argumentValue = _argumentValues[i];
        errorTarget = arguments[i];
      }
      // No argument node that we can direct error messages to, because we
      // are handling an optional parameter that wasn't specified.  So just
      // direct error messages to the constructor call.
      errorTarget ??= _errorNode;
      if (argumentValue == null && baseParameter is ParameterElementImpl) {
        // The parameter is an optional positional parameter for which no value
        // was provided, so use the default value.
        var evaluationResult = baseParameter.evaluationResult;
        if (evaluationResult == null) {
          // No default was provided, so the default value is null.
          argumentValue = ConstantEvaluationEngine._nullObject(_library);
        } else if (evaluationResult.value != null) {
          argumentValue = evaluationResult.value;
        }
      }
      if (argumentValue != null) {
        if (!typeSystem.runtimeTypeMatch(argumentValue, parameter.type)) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
            errorTarget,
            [argumentValue.type, parameter.type],
          );
        }
        if (baseParameter.isInitializingFormal) {
          var field = (parameter as FieldFormalParameterElement).field;
          if (field != null) {
            var fieldType = field.type;
            if (fieldType != parameter.type) {
              // We've already checked that the argument can be assigned to the
              // parameter; we also need to check that it can be assigned to
              // the field.
              if (!typeSystem.runtimeTypeMatch(argumentValue, fieldType)) {
                _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
                  errorTarget,
                  [argumentValue.type, fieldType],
                );
              }
            }
            var fieldName = field.name;
            if (_fieldMap.containsKey(fieldName)) {
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, _errorNode);
            }
            _fieldMap[fieldName] = argumentValue;
          }
        }
        _parameterMap[baseParameter.name] = argumentValue;
      }
    }
  }

  /// Checks an explicit or implicit call to `super()`.
  ///
  /// If a superinitializer was declared on the constructor declaration,
  /// [superName] and [superArguments] are the name of the super constructor
  /// referenced therein, and the arguments passed to the super constructor.
  /// Otherwise these parameters are `null`.
  void _checkSuperConstructorCall({
    required String? superName,
    required NodeList<Expression>? superArguments,
  }) {
    var superclass = definingType.superclass;
    if (superclass != null && !superclass.isDartCoreObject) {
      var superConstructor =
          superclass.lookUpConstructor(superName, _constructor.library);
      if (superConstructor == null) {
        return;
      }

      var constructor = _constructor;
      if (constructor is ConstructorMember && constructor.isLegacy) {
        superConstructor =
            Member.legacy(superConstructor) as ConstructorElement;
      }
      if (superConstructor.isConst) {
        var evaluationResult = _evaluationEngine.evaluateConstructorCall(
          _library,
          _errorNode,
          superclass.typeArguments,
          superArguments ?? astFactory.nodeList(_errorNode),
          superConstructor,
          _initializerVisitor,
          _externalErrorReporter,
        );
        if (evaluationResult != null) {
          _fieldMap[GenericState.SUPERCLASS_FIELD] = evaluationResult;
        }
      }
    }
  }

  /// Checks that the arguments to a call to [Symbol.new] are correct.
  ///
  /// The [arguments] are the AST nodes of the arguments. The [argumentValues]
  /// are the values of the unnamed arguments. The [namedArgumentValues] are the
  /// values of the named arguments. Returns `true` if the arguments are
  /// correct, `false` otherwise.
  bool _checkSymbolArguments(List<Expression> arguments,
      {required bool isNullSafe}) {
    if (arguments.length != 1) {
      return false;
    }
    if (arguments[0] is NamedExpression) {
      return false;
    }
    if (firstArgument!.type != typeProvider.stringType) {
      return false;
    }
    var name = firstArgument?.toStringValue();
    if (name == null) {
      return false;
    }
    if (isNullSafe) {
      return true;
    }
    return _isValidPublicSymbol(name);
  }

  void _checkTypeParameters() {
    var typeParameters = _constructor.enclosingElement.typeParameters;
    var typeArguments = _typeArguments;
    if (typeParameters.isNotEmpty &&
        typeArguments != null &&
        typeParameters.length == typeArguments.length) {
      for (int i = 0; i < typeParameters.length; i++) {
        var typeParameter = typeParameters[i];
        var typeArgument = typeArguments[i];
        _typeParameterMap[typeParameter] = typeArgument;
      }
    }
  }

  /// Evaluates [node] as an instance creation expression using [constructor].
  static DartObjectImpl? evaluate(
    ConstantEvaluationEngine evaluationEngine,
    DeclaredVariables declaredVariables,
    ErrorReporter errorReporter,
    LibraryElementImpl library,
    AstNode node,
    ConstructorElement constructor,
    List<DartType>? typeArguments,
    List<Expression> arguments,
    ConstantVisitor constantVisitor, {
    required bool isNullSafe,
    ConstructorInvocation? invocation,
  }) {
    if (!constructor.isConst) {
      if (node is InstanceCreationExpression && node.keyword != null) {
        errorReporter.reportErrorForToken(
            CompileTimeErrorCode.CONST_WITH_NON_CONST, node.keyword!);
      } else {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_WITH_NON_CONST, node);
      }
      return null;
    }

    if (!(constructor.declaration as ConstructorElementImpl).isCycleFree) {
      // It's not safe to evaluate this constructor, so bail out.
      // TODO(paulberry): ensure that a reasonable error message is produced
      // in this case, as well as other cases involving constant expression
      // cycles (e.g. "compile-time constant expression depends on itself").
      return DartObjectImpl.validWithUnknownValue(
        library.typeSystem,
        constructor.returnType,
      );
    }

    var argumentCount = arguments.length;
    var argumentValues = <DartObjectImpl>[];
    var namedNodes = <String, NamedExpression>{};
    var namedValues = <String, DartObjectImpl>{};
    for (var i = 0; i < argumentCount; i++) {
      var argument = arguments[i];
      if (argument is NamedExpression) {
        var name = argument.name.label.name;
        namedNodes[name] = argument;
        namedValues[name] = constantVisitor._valueOf(argument.expression);
      } else {
        argumentValues.add(constantVisitor._valueOf(argument));
      }
    }

    invocation ??= ConstructorInvocation(
      constructor,
      argumentValues,
      namedValues,
    );

    constructor = _followConstantRedirectionChain(constructor);

    var evaluator = _InstanceCreationEvaluator._(
      evaluationEngine,
      declaredVariables,
      errorReporter,
      library,
      node,
      constructor,
      typeArguments,
      namedNodes: namedNodes,
      namedValues: namedValues,
      argumentValues: argumentValues,
      invocation: invocation,
    );

    if (constructor.isFactory) {
      // We couldn't find a non-factory constructor.
      // See if it's because we reached an external const factory constructor
      // that we can emulate.
      return evaluator.evaluateFactoryConstructorCall(arguments,
          isNullSafe: isNullSafe);
    } else {
      return evaluator.evaluateGenerativeConstructorCall(arguments);
    }
  }

  /// Attempt to follow the chain of factory redirections until a constructor is
  /// reached which is not a const factory constructor. Return the constant
  /// constructor which terminates the chain of factory redirections, if the
  /// chain terminates. If there is a problem (e.g. a redirection can't be
  /// found, or a cycle is encountered), the chain will be followed as far as
  /// possible and then a const factory constructor will be returned.
  static ConstructorElement _followConstantRedirectionChain(
      ConstructorElement constructor) {
    var constructorsVisited = <ConstructorElement>{};
    while (true) {
      var redirectedConstructor =
          ConstantEvaluationEngine.getConstRedirectedConstructor(constructor);
      if (redirectedConstructor == null) {
        break;
      } else {
        var constructorBase = constructor.declaration;
        constructorsVisited.add(constructorBase);
        var redirectedConstructorBase = redirectedConstructor.declaration;
        if (constructorsVisited.contains(redirectedConstructorBase)) {
          // Cycle in redirecting factory constructors--this is not allowed
          // and is checked elsewhere--see
          // [ErrorVerifier.checkForRecursiveFactoryRedirect()]).
          break;
        }
      }
      constructor = redirectedConstructor;
    }
    return constructor;
  }

  /// Determine whether the given string is a valid name for a public symbol
  /// (i.e. whether it is allowed for a call to the Symbol constructor).
  static bool _isValidPublicSymbol(String name) =>
      name.isEmpty || name == "void" || _public_symbol_pattern.hasMatch(name);
}

extension RuntimeExtensions on TypeSystemImpl {
  /// Returns whether [obj] matches the [type] according to runtime
  /// type-checking rules.
  bool runtimeTypeMatch(
    DartObjectImpl obj,
    DartType type,
  ) {
    if (!isNonNullableByDefault) {
      type = toLegacyType(type);
    }
    var objType = obj.type;
    return isSubtypeOf(objType, type);
  }
}
