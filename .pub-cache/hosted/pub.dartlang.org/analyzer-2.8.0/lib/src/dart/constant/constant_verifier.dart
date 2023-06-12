// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `ConstantVerifier` traverse an AST structure looking
/// for additional errors and warnings not covered by the parser and resolver.
/// In particular, it looks for errors and warnings related to constant
/// expressions.
class ConstantVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// The type operations.
  final TypeSystemImpl _typeSystem;

  /// The type provider used to access the known types.
  final TypeProvider _typeProvider;

  /// The set of variables declared using '-D' on the command line.
  final DeclaredVariables declaredVariables;

  /// The current library that is being analyzed.
  final LibraryElementImpl _currentLibrary;

  final ConstantEvaluationEngine _evaluationEngine;

  final DiagnosticFactory _diagnosticFactory = DiagnosticFactory();

  /// Initialize a newly created constant verifier.
  ConstantVerifier(
    ErrorReporter errorReporter,
    LibraryElementImpl currentLibrary,
    DeclaredVariables declaredVariables,
  ) : this._(
          errorReporter,
          currentLibrary,
          currentLibrary.typeSystem,
          currentLibrary.typeProvider,
          declaredVariables,
        );

  ConstantVerifier._(
    this._errorReporter,
    this._currentLibrary,
    this._typeSystem,
    this._typeProvider,
    this.declaredVariables,
  ) : _evaluationEngine = ConstantEvaluationEngine(
          declaredVariables: declaredVariables,
          isNonNullableByDefault:
              _currentLibrary.featureSet.isEnabled(Feature.non_nullable),
        );

  @override
  void visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    // check annotation creation
    var element = node.element;
    if (element is ConstructorElement) {
      // should be 'const' constructor
      if (!element.isConst) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR, node);
        return;
      }
      // should have arguments
      var argumentList = node.arguments;
      if (argumentList == null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, node);
        return;
      }
      // arguments should be constants
      _validateConstantArguments(argumentList);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var constKeyword = node.constKeyword;
    if (constKeyword != null) {
      _validateConstructorInitializers(node);
      if (node.factoryKeyword == null) {
        _validateFieldInitializers(
            node.parent as ClassOrMixinDeclaration, constKeyword);
      }
    }
    _validateDefaultValues(node.parameters);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    super.visitConstructorReference(node);
    if (node.inConstantContext || node.inConstantExpression) {
      _checkForConstWithTypeParameters(node.constructorName.type2,
          CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    _validateDefaultValues(node.parameters);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    super.visitFunctionReference(node);
    if (node.inConstantContext || node.inConstantExpression) {
      var typeArguments = node.typeArguments;
      if (typeArguments == null) {
        return;
      }
      for (var typeArgument in typeArguments.arguments) {
        _checkForConstWithTypeParameters(typeArgument,
            CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF);
      }
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // TODO(srawlins): Also check interface types (TypeName?).
    super.visitGenericFunctionType(node);
    var parent = node.parent;
    if ((parent is AsExpression || parent is IsExpression) &&
        (parent as Expression).inConstantContext) {
      _checkForConstWithTypeParameters(
          node, CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      NamedType namedType = node.constructorName.type2;
      _checkForConstWithTypeParameters(
          namedType, CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS);

      node.argumentList.accept(this);

      // We need to evaluate the constant to see if any errors occur during its
      // evaluation.
      var constructor = node.constructorName.staticElement;
      if (constructor != null) {
        ConstantVisitor constantVisitor =
            ConstantVisitor(_evaluationEngine, _currentLibrary, _errorReporter);
        _evaluationEngine.evaluateConstructorCall(
            _currentLibrary,
            node,
            constructor.returnType.typeArguments,
            node.argumentList.arguments,
            constructor,
            constantVisitor,
            _errorReporter);
      }
    } else {
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.isConst) {
      var nodeType = node.staticType as InterfaceType;
      DartType elementType = nodeType.typeArguments[0];
      var verifier = _ConstLiteralVerifier(
        this,
        errorCode: CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT,
        listElementType: elementType,
      );
      for (CollectionElement element in node.elements) {
        verifier.verify(element);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    _validateDefaultValues(node.parameters);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    super.visitSetOrMapLiteral(node);
    if (node.isSet) {
      if (node.isConst) {
        var nodeType = node.staticType as InterfaceType;
        var elementType = nodeType.typeArguments[0];
        var config = _SetVerifierConfig(elementType: elementType);
        var verifier = _ConstLiteralVerifier(
          this,
          errorCode: CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT,
          setConfig: config,
        );
        for (CollectionElement element in node.elements) {
          verifier.verify(element);
        }
        for (var duplicateEntry in config.duplicateElements.entries) {
          _errorReporter.reportError(_diagnosticFactory.equalElementsInConstSet(
              _errorReporter.source, duplicateEntry.key, duplicateEntry.value));
        }
      }
    } else if (node.isMap) {
      if (node.isConst) {
        var nodeType = node.staticType as InterfaceType;
        var keyType = nodeType.typeArguments[0];
        var valueType = nodeType.typeArguments[1];
        bool reportEqualKeys = true;
        var config = _MapVerifierConfig(
          keyType: keyType,
          valueType: valueType,
        );
        var verifier = _ConstLiteralVerifier(
          this,
          errorCode: CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT,
          mapConfig: config,
        );
        for (CollectionElement entry in node.elements) {
          verifier.verify(entry);
        }
        if (reportEqualKeys) {
          for (var duplicateEntry in config.duplicateKeys.entries) {
            _errorReporter.reportError(_diagnosticFactory.equalKeysInConstMap(
                _errorReporter.source,
                duplicateEntry.key,
                duplicateEntry.value));
          }
        }
      }
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (_currentLibrary.isNonNullableByDefault) {
      _validateSwitchStatement_nullSafety(node);
    } else {
      _validateSwitchStatement_legacy(node);
    }
    super.visitSwitchStatement(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    var initializer = node.initializer;
    if (initializer != null && (node.isConst || node.isFinal)) {
      var element = node.declaredElement as VariableElementImpl;
      var result = element.evaluationResult;
      if (result == null) {
        // Variables marked "const" should have had their values computed by
        // ConstantValueComputer.  Other variables will only have had their
        // values computed if the value was needed (e.g. final variables in a
        // class containing const constructors).
        assert(!node.isConst);
        return;
      }
      if (node.isConst) {
        _reportErrors(result.errors,
            CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
      } else {
        _reportErrors(result.errors, null);
      }
      _reportErrorIfFromDeferredLibrary(
          initializer,
          CompileTimeErrorCode
              .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY);
    }
  }

  /// Verify that the given [type] does not reference any type parameters.
  ///
  /// See [CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS].
  void _checkForConstWithTypeParameters(
      TypeAnnotation type, ErrorCode errorCode) {
    if (type is NamedType) {
      Identifier name = type.name;
      // Should not be a type parameter.
      if (name.staticElement is TypeParameterElement) {
        _errorReporter.reportErrorForNode(errorCode, name);
      }
      // Check type arguments.
      var typeArguments = type.typeArguments;
      if (typeArguments != null) {
        for (TypeAnnotation argument in typeArguments.arguments) {
          _checkForConstWithTypeParameters(argument, errorCode);
        }
      }
    } else if (type is GenericFunctionType) {
      var returnType = type.returnType;
      if (returnType != null) {
        _checkForConstWithTypeParameters(returnType, errorCode);
      }
      for (var parameter in type.parameters.parameters) {
        // [parameter] cannot be a [DefaultFormalParameter], a
        // [FieldFormalParameter], nor a [FunctionTypedFormalParameter].
        if (parameter is SimpleFormalParameter) {
          var parameterType = parameter.type;
          if (parameterType != null) {
            _checkForConstWithTypeParameters(parameterType, errorCode);
          }
        }
      }
      var typeParameters = type.typeParameters;
      if (typeParameters != null) {
        for (var typeParameter in typeParameters.typeParameters) {
          var bound = typeParameter.bound;
          if (bound != null) {
            _checkForConstWithTypeParameters(bound, errorCode);
          }
        }
      }
    }
  }

  /// @return `true` if given [Type] implements operator <i>==</i>, and it is
  ///         not <i>int</i> or <i>String</i>.
  bool _implementsEqualsWhenNotAllowed(DartType type) {
    // ignore int or String
    if (type.isDartCoreInt || type.isDartCoreString) {
      return false;
    } else if (type.isDartCoreDouble) {
      return true;
    }
    // prepare ClassElement
    if (type is InterfaceType) {
      var element = type.element;
      // lookup for ==
      var method = element.lookUpConcreteMethod("==", _currentLibrary);
      if (method == null ||
          (method.enclosingElement as ClassElement).isDartCoreObject) {
        return false;
      }
      // there is == that we don't like
      return true;
    }
    return false;
  }

  /// Given some computed [Expression], this method generates the passed
  /// [ErrorCode] on the node if its' value consists of information from a
  /// deferred library.
  ///
  /// @param expression the expression to be tested for a deferred library
  ///        reference
  /// @param errorCode the error code to be used if the expression is or
  ///        consists of a reference to a deferred library
  void _reportErrorIfFromDeferredLibrary(
      Expression expression, ErrorCode errorCode,
      [List<Object>? arguments, List<DiagnosticMessage>? messages]) {
    DeferredLibraryReferenceDetector referenceDetector =
        DeferredLibraryReferenceDetector();
    expression.accept(referenceDetector);
    if (referenceDetector.result) {
      _errorReporter.reportErrorForNode(
          errorCode, expression, arguments, messages);
    }
  }

  /// Report any errors in the given list. Except for special cases, use the
  /// given error code rather than the one reported in the error.
  ///
  /// @param errors the errors that need to be reported
  /// @param errorCode the error code to be used
  void _reportErrors(List<AnalysisError> errors, ErrorCode? errorCode) {
    int length = errors.length;
    for (int i = 0; i < length; i++) {
      AnalysisError data = errors[i];
      ErrorCode dataErrorCode = data.errorCode;
      if (identical(dataErrorCode,
              CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION) ||
          identical(
              dataErrorCode, CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE) ||
          identical(dataErrorCode,
              CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING) ||
          identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL) ||
          identical(
              dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT) ||
          identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_INT) ||
          identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM) ||
          identical(dataErrorCode,
              CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT) ||
          identical(dataErrorCode,
              CompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH) ||
          identical(dataErrorCode,
              CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH) ||
          identical(
              dataErrorCode, CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH)) {
        _errorReporter.reportError(data);
      } else if (errorCode != null) {
        _errorReporter.reportError(
            AnalysisError(data.source, data.offset, data.length, errorCode));
      }
    }
  }

  void _reportNotPotentialConstants(AstNode node) {
    var notPotentiallyConstants = getNotPotentiallyConstants(
      node,
      featureSet: _currentLibrary.featureSet,
    );
    if (notPotentiallyConstants.isEmpty) return;

    for (var notConst in notPotentiallyConstants) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_CONSTANT,
        notConst,
      );
    }
  }

  /// Validates that all arguments in the [argumentList] are potentially
  /// constant expressions.
  void _reportNotPotentialConstantsArguments(ArgumentList argumentList) {
    for (Expression argument in argumentList.arguments) {
      _reportNotPotentialConstants(argument);
    }
  }

  /// Check if the object [obj] matches the type [type] according to runtime
  /// type checking rules.
  bool _runtimeTypeMatch(DartObjectImpl obj, DartType type) {
    return _currentLibrary.typeSystem.runtimeTypeMatch(obj, type);
  }

  /// Validate that the given expression is a compile time constant. Return the
  /// value of the compile time constant, or `null` if the expression is not a
  /// compile time constant.
  ///
  /// @param expression the expression to be validated
  /// @param errorCode the error code to be used if the expression is not a
  ///        compile time constant
  /// @return the value of the compile time constant
  DartObjectImpl? _validate(Expression expression, ErrorCode errorCode) {
    RecordingErrorListener errorListener = RecordingErrorListener();
    ErrorReporter subErrorReporter = ErrorReporter(
      errorListener,
      _errorReporter.source,
      isNonNullableByDefault: _currentLibrary.isNonNullableByDefault,
    );
    var result = expression.accept(
        ConstantVisitor(_evaluationEngine, _currentLibrary, subErrorReporter));
    _reportErrors(errorListener.errors, errorCode);
    return result;
  }

  /// Validate that if the passed arguments are constant expressions.
  ///
  /// @param argumentList the argument list to evaluate
  void _validateConstantArguments(ArgumentList argumentList) {
    for (Expression argument in argumentList.arguments) {
      Expression realArgument =
          argument is NamedExpression ? argument.expression : argument;
      _validate(
          realArgument, CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT);
      if (realArgument is PrefixedIdentifier && realArgument.isDeferred) {
        _reportErrorIfFromDeferredLibrary(
            realArgument,
            CompileTimeErrorCode
                .INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY);
      }
    }
  }

  /// Validates that the expressions of the initializers of the given constant
  /// [constructor] are all compile time constants.
  void _validateConstructorInitializers(ConstructorDeclaration constructor) {
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    for (ConstructorInitializer initializer in initializers) {
      if (initializer is AssertInitializer) {
        _reportNotPotentialConstants(initializer.condition);
        var message = initializer.message;
        if (message != null) {
          _reportNotPotentialConstants(message);
        }
      } else if (initializer is ConstructorFieldInitializer) {
        _reportNotPotentialConstants(initializer.expression);
      } else if (initializer is RedirectingConstructorInvocation) {
        _reportNotPotentialConstantsArguments(initializer.argumentList);
      } else if (initializer is SuperConstructorInvocation) {
        _reportNotPotentialConstantsArguments(initializer.argumentList);
      }
    }
  }

  /// Validate that the default value associated with each of the parameters in
  /// the given list is a compile time constant.
  ///
  /// @param parameters the list of parameters to be validated
  void _validateDefaultValues(FormalParameterList? parameters) {
    if (parameters == null) {
      return;
    }
    for (FormalParameter parameter in parameters.parameters) {
      if (parameter is DefaultFormalParameter) {
        var defaultValue = parameter.defaultValue;
        DartObjectImpl? result;
        if (defaultValue == null) {
          result = DartObjectImpl(
            _typeSystem,
            _typeProvider.nullType,
            NullState.NULL_STATE,
          );
        } else {
          result = _validate(
              defaultValue, CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE);
          if (result != null) {
            _reportErrorIfFromDeferredLibrary(
                defaultValue,
                CompileTimeErrorCode
                    .NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY);
          }
        }
        VariableElementImpl element =
            parameter.declaredElement as VariableElementImpl;
        element.evaluationResult = EvaluationResultImpl(result);
      }
    }
  }

  /// Validates that the expressions of any field initializers in
  /// [classDeclaration] are all compile-time constants. Since this is only
  /// required if the class has a constant constructor, the error is reported at
  /// [constKeyword], the const keyword on such a constant constructor.
  void _validateFieldInitializers(
      ClassOrMixinDeclaration classDeclaration, Token constKeyword) {
    NodeList<ClassMember> members = classDeclaration.members;
    for (ClassMember member in members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (VariableDeclaration variableDeclaration
            in member.fields.variables) {
          var initializer = variableDeclaration.initializer;
          if (initializer != null) {
            // Ignore any errors produced during validation--if the constant
            // can't be evaluated we'll just report a single error.
            AnalysisErrorListener errorListener =
                AnalysisErrorListener.NULL_LISTENER;
            ErrorReporter subErrorReporter = ErrorReporter(
              errorListener,
              _errorReporter.source,
              isNonNullableByDefault: _currentLibrary.isNonNullableByDefault,
            );
            var result = initializer.accept(ConstantVisitor(
                _evaluationEngine, _currentLibrary, subErrorReporter));
            if (result == null) {
              _errorReporter.reportErrorForToken(
                  CompileTimeErrorCode
                      .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
                  constKeyword,
                  [variableDeclaration.name.name]);
            }
          }
        }
      }
    }
  }

  void _validateSwitchStatement_legacy(SwitchStatement node) {
    // TODO(paulberry): to minimize error messages, it would be nice to
    // compare all types with the most popular type rather than the first
    // type.
    bool foundError = false;
    DartType? firstType;
    for (var switchMember in node.members) {
      if (switchMember is SwitchCase) {
        Expression expression = switchMember.expression;

        var expressionValue = _validate(
          expression,
          CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION,
        );
        if (expressionValue == null) {
          continue;
        }

        _reportErrorIfFromDeferredLibrary(
          expression,
          CompileTimeErrorCode
              .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
        );

        var expressionValueType = _typeSystem.toLegacyType(
          expressionValue.type,
        );

        if (firstType == null) {
          firstType = expressionValueType;
        } else {
          if (firstType != expressionValueType) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
              expression,
              [expression.toSource(), firstType],
            );
            foundError = true;
          }
        }
      }
    }

    if (foundError) {
      return;
    }

    if (firstType != null && _implementsEqualsWhenNotAllowed(firstType)) {
      _errorReporter.reportErrorForToken(
        CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
        node.switchKeyword,
        [firstType],
      );
    }
  }

  void _validateSwitchStatement_nullSafety(SwitchStatement node) {
    var switchType = node.expression.typeOrThrow;
    for (var switchMember in node.members) {
      if (switchMember is SwitchCase) {
        Expression expression = switchMember.expression;

        var expressionValue = _validate(
          expression,
          CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION,
        );
        if (expressionValue == null) {
          continue;
        }

        _reportErrorIfFromDeferredLibrary(
          expression,
          CompileTimeErrorCode
              .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
        );

        var expressionType = expressionValue.type;

        if (_implementsEqualsWhenNotAllowed(expressionType)) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
            expression,
            [expressionType],
          );
        }

        if (!_typeSystem.isSubtypeOf(expressionType, switchType)) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode
                .CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE,
            expression,
            [expressionType, switchType],
          );
        }
      }
    }
  }
}

class _ConstLiteralVerifier {
  final ConstantVerifier verifier;
  final ErrorCode errorCode;
  final DartType? listElementType;
  final _SetVerifierConfig? setConfig;
  final _MapVerifierConfig? mapConfig;

  _ConstLiteralVerifier(
    this.verifier, {
    required this.errorCode,
    this.listElementType,
    this.mapConfig,
    this.setConfig,
  });

  bool verify(CollectionElement element) {
    if (element is Expression) {
      var value = verifier._validate(element, errorCode);
      if (value == null) return false;

      _validateExpressionFromDeferredLibrary(element);

      final listElementType = this.listElementType;
      if (listElementType != null) {
        return _validateListExpression(listElementType, element, value);
      }

      final setConfig = this.setConfig;
      if (setConfig != null) {
        return _validateSetExpression(setConfig, element, value);
      }

      return true;
    } else if (element is ForElement) {
      verifier._errorReporter.reportErrorForNode(errorCode, element);
      return false;
    } else if (element is IfElement) {
      var conditionValue = verifier._validate(element.condition, errorCode);
      var conditionBool = conditionValue?.toBoolValue();

      // The errors have already been reported.
      if (conditionBool == null) return false;

      verifier._reportErrorIfFromDeferredLibrary(element.condition,
          CompileTimeErrorCode.IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY);

      var thenValid = true;
      var elseValid = true;
      var thenElement = element.thenElement;
      var elseElement = element.elseElement;
      if (conditionBool) {
        thenValid = verify(thenElement);
        if (elseElement != null) {
          elseValid = _reportNotPotentialConstants(elseElement);
        }
      } else {
        thenValid = _reportNotPotentialConstants(thenElement);
        if (elseElement != null) {
          elseValid = verify(elseElement);
        }
      }

      return thenValid && elseValid;
    } else if (element is MapLiteralEntry) {
      return _validateMapLiteralEntry(element);
    } else if (element is SpreadElement) {
      var value = verifier._validate(element.expression, errorCode);
      if (value == null) return false;

      verifier._reportErrorIfFromDeferredLibrary(element.expression,
          CompileTimeErrorCode.SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY);

      if (listElementType != null || setConfig != null) {
        return _validateListOrSetSpread(element, value);
      }

      final mapConfig = this.mapConfig;
      if (mapConfig != null) {
        return _validateMapSpread(mapConfig, element, value);
      }

      return true;
    }
    throw UnsupportedError(
      'Unhandled type of collection element: ${element.runtimeType}',
    );
  }

  /// Return `true` if the [node] is a potential constant.
  bool _reportNotPotentialConstants(AstNode node) {
    var notPotentiallyConstants = getNotPotentiallyConstants(
      node,
      featureSet: verifier._currentLibrary.featureSet,
    );
    if (notPotentiallyConstants.isEmpty) return true;

    for (var notConst in notPotentiallyConstants) {
      CompileTimeErrorCode errorCode;
      if (listElementType != null) {
        errorCode = CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT;
      } else if (mapConfig != null) {
        errorCode = CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT;
        for (AstNode? parent = notConst;
            parent != null;
            parent = parent.parent) {
          if (parent is MapLiteralEntry) {
            if (parent.key == notConst) {
              errorCode = CompileTimeErrorCode.NON_CONSTANT_MAP_KEY;
            } else {
              errorCode = CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE;
            }
            break;
          }
        }
      } else if (setConfig != null) {
        errorCode = CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT;
      } else {
        throw UnimplementedError();
      }
      verifier._errorReporter.reportErrorForNode(errorCode, notConst);
    }

    return false;
  }

  void _validateExpressionFromDeferredLibrary(Expression expression) {
    if (listElementType != null) {
      verifier._reportErrorIfFromDeferredLibrary(
        expression,
        CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY,
      );
    } else if (setConfig != null) {
      verifier._reportErrorIfFromDeferredLibrary(
        expression,
        CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY,
      );
    }
  }

  bool _validateListExpression(
      DartType listElementType, Expression expression, DartObjectImpl value) {
    if (!verifier._runtimeTypeMatch(value, listElementType)) {
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
        expression,
        [value.type, listElementType],
      );
      return false;
    }

    verifier._reportErrorIfFromDeferredLibrary(
      expression,
      CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY,
    );

    return true;
  }

  bool _validateListOrSetSpread(SpreadElement element, DartObjectImpl value) {
    var listValue = value.toListValue();
    var setValue = value.toSetValue();
    var iterableValue = listValue ?? setValue;

    if (iterableValue == null) {
      if (value.isNull && element.isNullAware) {
        return true;
      }
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET,
        element.expression,
      );
      return false;
    }

    final setConfig = this.setConfig;
    if (setConfig == null) {
      return true;
    }

    if (listValue != null) {
      var type = value.type;
      if (type is InterfaceType) {
        var elementType = type.typeArguments[0];
        if (verifier._implementsEqualsWhenNotAllowed(elementType)) {
          verifier._errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS,
            element,
            [elementType],
          );
          return false;
        }
      }
    }

    for (var item in iterableValue) {
      Expression expression = element.expression;
      var existingValue = setConfig.uniqueValues[item];
      if (existingValue != null) {
        setConfig.duplicateElements[expression] = existingValue;
      } else {
        setConfig.uniqueValues[item] = expression;
      }
    }

    return true;
  }

  bool _validateMapLiteralEntry(MapLiteralEntry entry) {
    var config = mapConfig;
    if (config == null) return false;

    var keyExpression = entry.key;
    var valueExpression = entry.value;

    var keyValue = verifier._validate(
      keyExpression,
      CompileTimeErrorCode.NON_CONSTANT_MAP_KEY,
    );
    var valueValue = verifier._validate(
      valueExpression,
      CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE,
    );

    if (keyValue != null) {
      var keyType = keyValue.type;

      if (!verifier._runtimeTypeMatch(keyValue, config.keyType)) {
        verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
          keyExpression,
          [keyType, config.keyType],
        );
      }

      if (verifier._implementsEqualsWhenNotAllowed(keyType)) {
        verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
          keyExpression,
          [keyType],
        );
      }

      verifier._reportErrorIfFromDeferredLibrary(
        keyExpression,
        CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY,
      );

      var existingKey = config.uniqueKeys[keyValue];
      if (existingKey != null) {
        config.duplicateKeys[keyExpression] = existingKey;
      } else {
        config.uniqueKeys[keyValue] = keyExpression;
      }
    }

    if (valueValue != null) {
      if (!verifier._runtimeTypeMatch(valueValue, config.valueType)) {
        verifier._errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
          valueExpression,
          [valueValue.type, config.valueType],
        );
      }

      verifier._reportErrorIfFromDeferredLibrary(
        valueExpression,
        CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
      );
    }

    return true;
  }

  bool _validateMapSpread(
    _MapVerifierConfig config,
    SpreadElement element,
    DartObjectImpl value,
  ) {
    if (value.isNull && element.isNullAware) {
      return true;
    }
    var map = value.toMapValue();
    if (map != null) {
      // TODO(brianwilkerson) Figure out how to improve the error messages. They
      //  currently point to the whole spread expression, but the key and/or
      //  value being referenced might not be located there (if it's referenced
      //  through a const variable).
      for (var keyValue in map.keys) {
        var existingKey = config.uniqueKeys[keyValue];
        if (existingKey != null) {
          config.duplicateKeys[element.expression] = existingKey;
        } else {
          config.uniqueKeys[keyValue] = element.expression;
        }
      }
      return true;
    }
    verifier._errorReporter.reportErrorForNode(
      CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP,
      element.expression,
    );
    return false;
  }

  bool _validateSetExpression(
    _SetVerifierConfig config,
    Expression expression,
    DartObjectImpl value,
  ) {
    if (!verifier._runtimeTypeMatch(value, config.elementType)) {
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE,
        expression,
        [value.type, config.elementType],
      );
      return false;
    }

    if (verifier._implementsEqualsWhenNotAllowed(value.type)) {
      verifier._errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS,
        expression,
        [value.type],
      );
      return false;
    }

    verifier._reportErrorIfFromDeferredLibrary(
      expression,
      CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY,
    );

    var existingValue = config.uniqueValues[value];
    if (existingValue != null) {
      config.duplicateElements[expression] = existingValue;
    } else {
      config.uniqueValues[value] = expression;
    }

    return true;
  }
}

class _MapVerifierConfig {
  final DartType keyType;
  final DartType valueType;
  final Map<DartObject, Expression> uniqueKeys = {};
  final Map<Expression, Expression> duplicateKeys = {};

  _MapVerifierConfig({
    required this.keyType,
    required this.valueType,
  });
}

class _SetVerifierConfig {
  final DartType elementType;
  final Map<DartObject, Expression> uniqueValues = {};
  final Map<Expression, Expression> duplicateElements = {};

  _SetVerifierConfig({
    required this.elementType,
  });
}

extension on Expression {
  /// Returns whether `this` is found in a constant expression.
  ///
  /// This does not check whether `this` is found in a constant context.
  bool get inConstantExpression {
    AstNode child = this;
    var parent = child.parent;
    while (parent != null) {
      if (parent is DefaultFormalParameter && child == parent.defaultValue) {
        // A parameter default value does not constitute a constant context, but
        // must be a constant expression.
        return true;
      } else if (parent is VariableDeclaration && child == parent.initializer) {
        var declarationList = parent.parent;
        if (declarationList is VariableDeclarationList) {
          var declarationListParent = declarationList.parent;
          if (declarationListParent is FieldDeclaration &&
              !declarationListParent.isStatic) {
            var container = declarationListParent.parent;
            if (container is ClassOrMixinDeclaration) {
              var enclosingClass = container.declaredElement;
              if (enclosingClass != null) {
                // A field initializer of a class with at least one generative
                // const constructor does not constitute a constant context, but
                // must be a constant expression.
                return enclosingClass.constructors
                    .any((c) => c.isConst && !c.isFactory);
              }
            }
          }
        }
        return false;
      } else {
        child = parent;
        parent = child.parent;
      }
    }
    return false;
  }
}
