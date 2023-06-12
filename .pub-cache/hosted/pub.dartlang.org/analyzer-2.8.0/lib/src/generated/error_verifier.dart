// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/constructor_fields_verifier.dart';
import 'package:analyzer/src/error/correct_override.dart';
import 'package:analyzer/src/error/duplicate_definition_verifier.dart';
import 'package:analyzer/src/error/getter_setter_types_verifier.dart';
import 'package:analyzer/src/error/literal_element_verifier.dart';
import 'package:analyzer/src/error/required_parameters_verifier.dart';
import 'package:analyzer/src/error/return_type_verifier.dart';
import 'package:analyzer/src/error/type_arguments_verifier.dart';
import 'package:analyzer/src/error/use_result_verifier.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/this_access_tracker.dart';
import 'package:collection/collection.dart';

class EnclosingExecutableContext {
  final ExecutableElement? element;
  final bool isAsynchronous;
  final bool isConstConstructor;
  final bool isGenerativeConstructor;
  final bool isGenerator;
  final bool inFactoryConstructor;
  final bool inStaticMethod;

  /// If this [EnclosingExecutableContext] is the first argument in a method
  /// invocation of [Future.catchError], returns the return type expected for
  /// `Future<T>.catchError`'s `onError` parameter, which is `FutureOr<T>`,
  /// otherwise `null`.
  final InterfaceType? catchErrorOnErrorReturnType;

  /// The return statements that have a value.
  final List<ReturnStatement> _returnsWith = [];

  /// The return statements that do not have a value.
  final List<ReturnStatement> _returnsWithout = [];

  /// This flag is set to `false` when the declared return type is not legal
  /// for the kind of the function body, e.g. not `Future` for `async`.
  bool hasLegalReturnType = true;

  EnclosingExecutableContext(this.element,
      {bool? isAsynchronous, this.catchErrorOnErrorReturnType})
      : isAsynchronous =
            isAsynchronous ?? (element != null && element.isAsynchronous),
        isConstConstructor = element is ConstructorElement && element.isConst,
        isGenerativeConstructor =
            element is ConstructorElement && !element.isFactory,
        isGenerator = element != null && element.isGenerator,
        inFactoryConstructor = _inFactoryConstructor(element),
        inStaticMethod = _inStaticMethod(element);

  EnclosingExecutableContext.empty() : this(null);

  String? get displayName {
    final element = this.element;
    if (element is ConstructorElement) {
      var className = element.enclosingElement.displayName;
      var constructorName = element.displayName;
      return constructorName.isEmpty
          ? className
          : '$className.$constructorName';
    } else {
      return element?.displayName;
    }
  }

  bool get isClosure {
    return element is FunctionElement && element!.displayName.isEmpty;
  }

  bool get isConstructor => element is ConstructorElement;

  bool get isFunction {
    if (element is FunctionElement) {
      return element!.displayName.isNotEmpty;
    }
    return element is PropertyAccessorElement;
  }

  bool get isMethod => element is MethodElement;

  bool get isSynchronous => !isAsynchronous;

  DartType get returnType {
    return catchErrorOnErrorReturnType ?? element!.returnType;
  }

  static bool _inFactoryConstructor(Element? element) {
    var enclosing = element?.enclosingElement;
    if (enclosing == null) {
      return false;
    }
    if (element is ConstructorElement) {
      return element.isFactory;
    }
    return _inFactoryConstructor(enclosing);
  }

  static bool _inStaticMethod(Element? element) {
    var enclosing = element?.enclosingElement;
    if (enclosing == null) {
      return false;
    }
    if (enclosing is ClassElement || enclosing is ExtensionElement) {
      if (element is ExecutableElement) {
        return element.isStatic;
      }
    }
    return _inStaticMethod(enclosing);
  }
}

/// A visitor used to traverse an AST structure looking for additional errors
/// and warnings not covered by the parser and resolver.
class ErrorVerifier extends RecursiveAstVisitor<void>
    with ErrorDetectionHelpers {
  /// The error reporter by which errors will be reported.
  @override
  final ErrorReporter errorReporter;

  /// The current library that is being analyzed.
  final LibraryElementImpl _currentLibrary;

  /// The type representing the type 'int'.
  late final InterfaceType _intType;

  /// The options for verification.
  late final AnalysisOptionsImpl _options;

  /// The object providing access to the types defined by the language.
  final TypeProvider _typeProvider;

  /// The type system primitives
  @override
  late final TypeSystemImpl typeSystem;

  /// The manager for the inheritance mappings.
  final InheritanceManager3 _inheritanceManager;

  /// A flag indicating whether the visitor is currently within a catch clause.
  ///
  /// See [visitCatchClause].
  bool _isInCatchClause = false;

  /// A flag indicating whether the visitor is currently within a comment.
  bool _isInComment = false;

  /// The stack of flags, where `true` at the top (last) of the stack indicates
  /// that the visitor is in the initializer of a lazy local variable. When the
  /// top is `false`, we might be not in a local variable, or it is not `lazy`,
  /// etc.
  final List<bool> _isInLateLocalVariable = [false];

  /// A flag indicating whether the visitor is currently within a native class
  /// declaration.
  bool _isInNativeClass = false;

  /// A flag indicating whether the visitor is currently within a static
  /// variable declaration.
  bool _isInStaticVariableDeclaration = false;

  /// A flag indicating whether the visitor is currently within an instance
  /// variable declaration, which is not `late`.
  bool _isInInstanceNotLateVariableDeclaration = false;

  /// A flag indicating whether the visitor is currently within a constructor
  /// initializer.
  bool _isInConstructorInitializer = false;

  /// This is set to `true` iff the visitor is currently within a function typed
  /// formal parameter.
  bool _isInFunctionTypedFormalParameter = false;

  /// A flag indicating whether the visitor is currently within code in the SDK.
  bool _isInSystemLibrary = false;

  /// The class containing the AST nodes being visited, or `null` if we are not
  /// in the scope of a class.
  ClassElementImpl? _enclosingClass;

  /// The enum containing the AST nodes being visited, or `null` if we are not
  /// in the scope of an enum.
  ClassElement? _enclosingEnum;

  /// The element of the extension being visited, or `null` if we are not
  /// in the scope of an extension.
  ExtensionElement? _enclosingExtension;

  /// The helper for tracking if the current location has access to `this`.
  final ThisAccessTracker _thisAccessTracker = ThisAccessTracker.unit();

  /// The context of the method or function that we are currently visiting, or
  /// `null` if we are not inside a method or function.
  EnclosingExecutableContext _enclosingExecutable =
      EnclosingExecutableContext.empty();

  /// A table mapping names to the exported elements.
  final Map<String, Element> _exportedElements = HashMap<String, Element>();

  /// A set of the names of the variable initializers we are visiting now.
  final HashSet<String> _namesForReferenceToDeclaredVariableInInitializer =
      HashSet<String>();

  /// The elements that will be defined later in the current scope, but right
  /// now are not declared.
  HiddenElements? _hiddenElements;

  final _UninstantiatedBoundChecker _uninstantiatedBoundChecker;

  /// The features enabled in the unit currently being checked for errors.
  FeatureSet? _featureSet;

  final RequiredParametersVerifier _requiredParametersVerifier;
  final DuplicateDefinitionVerifier _duplicateDefinitionVerifier;
  final UseResultVerifier _checkUseVerifier;
  late final TypeArgumentsVerifier _typeArgumentsVerifier;
  late final ConstructorFieldsVerifier _constructorFieldsVerifier;
  late final ReturnTypeVerifier _returnTypeVerifier;

  /// Initialize a newly created error verifier.
  ErrorVerifier(this.errorReporter, this._currentLibrary, this._typeProvider,
      this._inheritanceManager)
      : _uninstantiatedBoundChecker =
            _UninstantiatedBoundChecker(errorReporter),
        _checkUseVerifier = UseResultVerifier(errorReporter),
        _requiredParametersVerifier = RequiredParametersVerifier(errorReporter),
        _duplicateDefinitionVerifier =
            DuplicateDefinitionVerifier(_currentLibrary, errorReporter) {
    _isInSystemLibrary = _currentLibrary.source.uri.isScheme('dart');
    _isInCatchClause = false;
    _isInStaticVariableDeclaration = false;
    _isInConstructorInitializer = false;
    _intType = _typeProvider.intType;
    typeSystem = _currentLibrary.typeSystem;
    _options = _currentLibrary.context.analysisOptions as AnalysisOptionsImpl;
    _typeArgumentsVerifier =
        TypeArgumentsVerifier(_options, _currentLibrary, errorReporter);
    _constructorFieldsVerifier = ConstructorFieldsVerifier(
      typeSystem: typeSystem,
      errorReporter: errorReporter,
    );
    _returnTypeVerifier = ReturnTypeVerifier(
      typeProvider: _typeProvider as TypeProviderImpl,
      typeSystem: typeSystem,
      errorReporter: errorReporter,
    );
  }

  ClassElement? get enclosingClass => _enclosingClass;

  /// For consumers of error verification as a library, (currently just the
  /// angular plugin), expose a setter that can make the errors reported more
  /// accurate when dangling code snippets are being resolved from a class
  /// context. Note that this setter is very defensive for potential misuse; it
  /// should not be modified in the middle of visiting a tree and requires an
  /// analyzer-provided Impl instance to work.
  set enclosingClass(ClassElement? classElement) {
    assert(classElement is ClassElementImpl);
    assert(_enclosingClass == null);
    assert(_enclosingEnum == null);
    assert(_enclosingExecutable.element == null);
    _enclosingClass = classElement as ClassElementImpl;
  }

  /// The language team is thinking about adding abstract fields, or external
  /// fields. But for now we will ignore such fields in `Struct` subtypes.
  bool get _isEnclosingClassFfiStruct {
    var superClass = _enclosingClass?.supertype?.element;
    return superClass != null &&
        superClass.library.name == 'dart.ffi' &&
        superClass.name == 'Struct';
  }

  /// The language team is thinking about adding abstract fields, or external
  /// fields. But for now we will ignore such fields in `Struct` subtypes.
  bool get _isEnclosingClassFfiUnion {
    var superClass = _enclosingClass?.supertype?.element;
    return superClass != null &&
        superClass.library.name == 'dart.ffi' &&
        superClass.name == 'Union';
  }

  bool get _isNonNullableByDefault =>
      _featureSet?.isEnabled(Feature.non_nullable) ?? false;

  @override
  List<DiagnosticMessage> computeWhyNotPromotedMessages(
      SyntacticEntity errorEntity,
      Map<DartType, NonPromotionReason>? whyNotPromoted) {
    return [];
  }

  @override
  void visitAnnotation(Annotation node) {
    _checkForInvalidAnnotationFromDeferredLibrary(node);
    super.visitAnnotation(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _isInConstructorInitializer = true;
    try {
      super.visitAssertInitializer(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    TokenType operatorType = node.operator.type;
    Expression lhs = node.leftHandSide;
    if (operatorType == TokenType.QUESTION_QUESTION_EQ) {
      _checkForDeadNullCoalesce(node.readType as TypeImpl, node.rightHandSide);
    }
    _checkForAssignmentToFinal(lhs);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (!_enclosingExecutable.isAsynchronous) {
      errorReporter.reportErrorForToken(
          CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, node.awaitKeyword);
    }
    if (_isNonNullableByDefault) {
      checkForUseOfVoidResult(node.expression);
    }
    _checkForAwaitInLateLocalVariableInitializer(node);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    TokenType type = operator.type;
    if (type == TokenType.AMPERSAND_AMPERSAND || type == TokenType.BAR_BAR) {
      checkForUseOfVoidResult(node.rightOperand);
    } else {
      // Assignability checking is done by the resolver.
    }

    if (type == TokenType.QUESTION_QUESTION) {
      _checkForDeadNullCoalesce(
          node.leftOperand.staticType as TypeImpl, node.rightOperand);
    }

    checkForUseOfVoidResult(node.leftOperand);

    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(Block node) {
    _withHiddenElements(node.statements, () {
      _duplicateDefinitionVerifier.checkStatements(node.statements);
      super.visitBlock(node);
    });
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _thisAccessTracker.enterFunctionBody(node);
    try {
      super.visitBlockFunctionBody(node);
    } finally {
      _thisAccessTracker.exitFunctionBody(node);
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    var labelNode = node.label;
    if (labelNode != null) {
      var labelElement = labelNode.staticElement;
      if (labelElement is LabelElementImpl && labelElement.isOnSwitchMember) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, labelNode);
      }
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    _duplicateDefinitionVerifier.checkCatchClause(node);
    bool previousIsInCatchClause = _isInCatchClause;
    try {
      _isInCatchClause = true;
      _checkForTypeAnnotationDeferredClass(node.exceptionType);
      super.visitCatchClause(node);
    } finally {
      _isInCatchClause = previousIsInCatchClause;
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var outerClass = _enclosingClass;
    try {
      _isInNativeClass = node.nativeClause != null;
      _enclosingClass = node.declaredElement as ClassElementImpl;

      List<ClassMember> members = node.members;
      _duplicateDefinitionVerifier.checkClass(node);
      _checkForBuiltInIdentifierAsName(
          node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      _checkForConflictingClassTypeVariableErrorCodes();
      var superclass = node.extendsClause?.superclass2;
      var implementsClause = node.implementsClause;
      var withClause = node.withClause;

      // Only do error checks on the clause nodes if there is a non-null clause
      if (implementsClause != null ||
          superclass != null ||
          withClause != null) {
        _checkClassInheritance(node, superclass, withClause, implementsClause);
      }

      _checkForConflictingClassMembers();
      _constructorFieldsVerifier.enterClass(node);
      _checkForFinalNotInitializedInClass(members);
      _checkForBadFunctionUse(node);
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
      _checkForMainFunction(node.name);
      super.visitClassDeclaration(node);
    } finally {
      _isInNativeClass = false;
      _constructorFieldsVerifier.leaveClass();
      _enclosingClass = outerClass;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    var outerClassElement = _enclosingClass;
    try {
      _enclosingClass = node.declaredElement as ClassElementImpl;
      _checkClassInheritance(
          node, node.superclass2, node.withClause, node.implementsClause);
      _checkForMainFunction(node.name);
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
    } finally {
      _enclosingClass = outerClassElement;
    }
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    _isInComment = true;
    try {
      super.visitComment(node);
    } finally {
      _isInComment = false;
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _featureSet = node.featureSet;
    _duplicateDefinitionVerifier.checkUnit(node);
    _checkForDeferredPrefixCollisions(node);
    super.visitCompilationUnit(node);
    _featureSet = null;
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var element = node.declaredElement!;
    _withEnclosingExecutable(element, () {
      _checkForInvalidModifierOnBody(
          node.body, CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR);
      if (!_checkForConstConstructorWithNonConstSuper(node)) {
        _checkForConstConstructorWithNonFinalField(node, element);
      }
      _constructorFieldsVerifier.verify(node);
      _checkForRedirectingConstructorErrorCodes(node);
      _checkForConflictingInitializerErrorCodes(node);
      _checkForRecursiveConstructorRedirect(node, element);
      if (!_checkForRecursiveFactoryRedirect(node, element)) {
        _checkForAllRedirectConstructorErrorCodes(node);
      }
      _checkForUndefinedConstructorInInitializerImplicit(node);
      _checkForReturnInGenerativeConstructor(node);
      super.visitConstructorDeclaration(node);
    });
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _isInConstructorInitializer = true;
    try {
      SimpleIdentifier fieldName = node.fieldName;
      var staticElement = fieldName.staticElement;
      _checkForInvalidField(node, fieldName, staticElement);
      if (staticElement is FieldElement) {
        _checkForAbstractOrExternalFieldConstructorInitializer(
            node.fieldName, staticElement);
      }
      super.visitConstructorFieldInitializer(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _typeArgumentsVerifier.checkConstructorReference(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    var labelNode = node.label;
    if (labelNode != null) {
      var labelElement = labelNode.staticElement;
      if (labelElement is LabelElementImpl &&
          labelElement.isOnSwitchStatement) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONTINUE_LABEL_ON_SWITCH, labelNode);
      }
    }
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    checkForInvalidAssignment(node.identifier, node.defaultValue);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    var outerEnum = _enclosingEnum;
    try {
      _enclosingEnum = node.declaredElement;
      _duplicateDefinitionVerifier.checkEnum(node);
      super.visitEnumDeclaration(node);
    } finally {
      _enclosingEnum = outerEnum;
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    var exportElement = node.element;
    if (exportElement != null) {
      var exportedLibrary = exportElement.exportedLibrary;
      _checkForAmbiguousExport(node, exportElement, exportedLibrary);
      _checkForExportInternalLibrary(node, exportElement);
      _checkForExportLegacySymbol(node);
    }
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _thisAccessTracker.enterFunctionBody(node);
    try {
      _returnTypeVerifier.verifyExpressionFunctionBody(node);
      super.visitExpressionFunctionBody(node);
    } finally {
      _thisAccessTracker.exitFunctionBody(node);
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _enclosingExtension = node.declaredElement;
    _duplicateDefinitionVerifier.checkExtension(node);
    _checkForConflictingExtensionTypeVariableErrorCodes();
    _checkForFinalNotInitializedInClass(node.members);

    GetterSetterTypesVerifier(
      typeSystem: typeSystem,
      errorReporter: errorReporter,
    ).checkExtension(node);

    final name = node.name;
    if (name != null) {
      _checkForBuiltInIdentifierAsName(
          name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME);
    }
    super.visitExtensionDeclaration(node);
    _enclosingExtension = null;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    var fields = node.fields;
    _thisAccessTracker.enterFieldDeclaration(node);
    _isInStaticVariableDeclaration = node.isStatic;
    _isInInstanceNotLateVariableDeclaration =
        !node.isStatic && !node.fields.isLate;
    if (!_isInStaticVariableDeclaration) {
      if (fields.isConst) {
        errorReporter.reportErrorForToken(
            CompileTimeErrorCode.CONST_INSTANCE_FIELD, fields.keyword!);
      }
    }
    try {
      _checkForNotInitializedNonNullableStaticField(node);
      _checkForWrongTypeParameterVarianceInField(node);
      _checkForLateFinalFieldWithConstConstructor(node);
      super.visitFieldDeclaration(node);
    } finally {
      _isInStaticVariableDeclaration = false;
      _isInInstanceNotLateVariableDeclaration = false;
      _thisAccessTracker.exitFieldDeclaration(node);
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _checkForValidField(node);
    _checkForPrivateOptionalParameter(node);
    _checkForFieldInitializingFormalRedirectingConstructor(node);
    _checkForTypeAnnotationDeferredClass(node.type);
    ParameterElement element = node.declaredElement!;
    if (element is FieldFormalParameterElement) {
      var fieldElement = element.field;
      if (fieldElement != null) {
        _checkForAbstractOrExternalFieldConstructorInitializer(
            node.identifier, fieldElement);
      }
    }
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (_checkForEachParts(node, loopVariable.identifier)) {
      if (loopVariable.isConst) {
        errorReporter.reportErrorForToken(
            CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE,
            loopVariable.keyword!);
      }
    }
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    SimpleIdentifier identifier = node.identifier;
    if (_checkForEachParts(node, identifier)) {
      _checkForAssignmentToFinal(identifier);
    }
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _duplicateDefinitionVerifier.checkParameters(node);
    _checkUseOfCovariantInParameters(node);
    _checkUseOfDefaultValuesInParameters(node);
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _duplicateDefinitionVerifier.checkForVariables(node.variables);
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement functionElement = node.declaredElement!;
    if (functionElement.enclosingElement is! CompilationUnitElement) {
      _hiddenElements!.declare(functionElement);
    }

    _withEnclosingExecutable(functionElement, () {
      SimpleIdentifier identifier = node.name;
      TypeAnnotation? returnType = node.returnType;
      if (node.isGetter) {
        GetterSetterTypesVerifier(
          typeSystem: typeSystem,
          errorReporter: errorReporter,
        ).checkGetter(
            node.name, node.declaredElement as PropertyAccessorElement);
      }
      if (node.isSetter) {
        FunctionExpression functionExpression = node.functionExpression;
        _checkForWrongNumberOfParametersForSetter(
            identifier, functionExpression.parameters);
        _checkForNonVoidReturnTypeForSetter(returnType);
      }
      _checkForTypeAnnotationDeferredClass(returnType);
      _returnTypeVerifier.verifyReturnType(returnType);
      _checkForImplicitDynamicReturn(node.name, node.declaredElement!);
      _checkForMainFunction(node.name);
      super.visitFunctionDeclaration(node);
    });
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _isInLateLocalVariable.add(false);

    if (node.parent is FunctionDeclaration) {
      super.visitFunctionExpression(node);
    } else {
      _withEnclosingExecutable(node.declaredElement!, () {
        super.visitFunctionExpression(node);
      });
    }

    _isInLateLocalVariable.removeLast();
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    Expression functionExpression = node.function;

    if (functionExpression is ExtensionOverride) {
      return super.visitFunctionExpressionInvocation(node);
    }

    DartType expressionType = functionExpression.typeOrThrow;
    if (expressionType is FunctionType) {
      _typeArgumentsVerifier.checkFunctionExpressionInvocation(node);
    }
    _requiredParametersVerifier.visitFunctionExpressionInvocation(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _typeArgumentsVerifier.checkFunctionReference(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    _checkForMainFunction(node.name);
    _checkForTypeAliasCannotReferenceItself(
        node.name, node.declaredElement as TypeAliasElementImpl);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    bool old = _isInFunctionTypedFormalParameter;
    _isInFunctionTypedFormalParameter = true;
    try {
      _checkForTypeAnnotationDeferredClass(node.returnType);

      // TODO(jmesserly): ideally we'd use _checkForImplicitDynamicReturn, and
      // we can get the function element via `node?.element?.type?.element` but
      // it doesn't have hasImplicitReturnType set correctly.
      if (!_options.implicitDynamic && node.returnType == null) {
        DartType parameterType = node.declaredElement!.type;
        if (parameterType is FunctionType &&
            parameterType.returnType.isDynamic) {
          errorReporter.reportErrorForNode(LanguageCode.IMPLICIT_DYNAMIC_RETURN,
              node.identifier, [node.identifier.name]);
        }
      }

      super.visitFunctionTypedFormalParameter(node);
    } finally {
      _isInFunctionTypedFormalParameter = old;
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _checkForBuiltInIdentifierAsName(
        node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    _checkForMainFunction(node.name);
    _checkForTypeAliasCannotReferenceItself(
        node.name, node.declaredElement as TypeAliasElementImpl);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces2.forEach(_checkForImplicitDynamicType);
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var importElement = node.element;
    if (node.prefix != null) {
      _checkForBuiltInIdentifierAsName(node.prefix!,
          CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME);
    }
    if (importElement != null) {
      _checkForImportInternalLibrary(node, importElement);
      if (importElement.isDeferred) {
        _checkForDeferredImportOfExtensions(node, importElement);
      }
    }
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.isNullAware) {
      _checkForUnnecessaryNullAware(
        node.realTarget,
        node.question ?? node.period ?? node.leftBracket,
      );
    }

    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    NamedType namedType = constructorName.type2;
    DartType type = namedType.typeOrThrow;
    if (type is InterfaceType) {
      _checkForConstOrNewWithAbstractClass(node, namedType, type);
      _checkForConstOrNewWithEnum(node, namedType, type);
      _checkForConstOrNewWithMixin(node, namedType, type);
      _requiredParametersVerifier.visitInstanceCreationExpression(node);
      if (node.isConst) {
        _checkForConstWithNonConst(node);
        _checkForConstWithUndefinedConstructor(
            node, constructorName, namedType);
        _checkForConstDeferredClass(node, constructorName, namedType);
      } else {
        _checkForNewWithUndefinedConstructor(node, constructorName, namedType);
      }
      _checkForListConstructor(node, type);
    }
    _checkForImplicitDynamicType(namedType);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _checkForOutOfRange(node);
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    checkForUseOfVoidResult(node.expression);
    super.visitInterpolationExpression(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    checkForUseOfVoidResult(node.expression);
    super.visitIsExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _typeArgumentsVerifier.checkListLiteral(node);
    _checkForListElementTypeNotAssignable(node);

    super.visitListLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _withEnclosingExecutable(node.declaredElement!, () {
      var returnType = node.returnType;
      if (node.isStatic && node.isGetter) {
        GetterSetterTypesVerifier(
          typeSystem: typeSystem,
          errorReporter: errorReporter,
        ).checkGetter(
            node.name, node.declaredElement as PropertyAccessorElement);
      }
      if (node.isSetter) {
        _checkForWrongNumberOfParametersForSetter(node.name, node.parameters);
        _checkForNonVoidReturnTypeForSetter(returnType);
      } else if (node.isOperator) {
        var hasWrongNumberOfParameters =
            _checkForWrongNumberOfParametersForOperator(node);
        if (!hasWrongNumberOfParameters) {
          // If the operator has too many parameters including one or more
          // optional parameters, only report one error.
          _checkForOptionalParameterInOperator(node);
        }
        _checkForNonVoidReturnTypeForOperator(node);
      }
      _checkForExtensionDeclaresMemberOfObject(node);
      _checkForTypeAnnotationDeferredClass(returnType);
      _returnTypeVerifier.verifyReturnType(returnType);
      _checkForImplicitDynamicReturn(node, node.declaredElement!);
      _checkForWrongTypeParameterVarianceInMethod(node);
      super.visitMethodDeclaration(node);
    });
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var target = node.realTarget;
    SimpleIdentifier methodName = node.methodName;
    if (target != null) {
      var typeReference = ElementResolver.getTypeReference(target);
      _checkForStaticAccessToInstanceMember(typeReference, methodName);
      _checkForInstanceAccessToStaticMember(
          typeReference, node.target, methodName);
      _checkForUnnecessaryNullAware(target, node.operator!);
    } else {
      _checkForUnqualifiedReferenceToNonLocalStaticMember(methodName);
    }
    _typeArgumentsVerifier.checkMethodInvocation(node);
    _requiredParametersVerifier.visitMethodInvocation(node);
    _checkUseVerifier.checkMethodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    // TODO(scheglov) Verify for all mixin errors.
    var outerClass = _enclosingClass;
    try {
      _enclosingClass = node.declaredElement as ClassElementImpl;

      List<ClassMember> members = node.members;
      _duplicateDefinitionVerifier.checkMixin(node);
      _checkForBuiltInIdentifierAsName(
          node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      _checkForConflictingClassTypeVariableErrorCodes();

      var onClause = node.onClause;
      var implementsClause = node.implementsClause;

      // Only do error checks only if there is a non-null clause.
      if (onClause != null || implementsClause != null) {
        _checkMixinInheritance(node, onClause, implementsClause);
      }

      _checkForConflictingClassMembers();
      _checkForFinalNotInitializedInClass(members);
      _checkForMainFunction(node.name);
      _checkForWrongTypeParameterVarianceInSuperinterfaces();
      //      _checkForBadFunctionUse(node);
      super.visitMixinDeclaration(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }

  @override
  void visitNamedType(NamedType node) {
    _typeArgumentsVerifier.checkNamedType(node);
    super.visitNamedType(node);
  }

  @override
  void visitNativeClause(NativeClause node) {
    // TODO(brianwilkerson) Figure out the right rule for when 'native' is
    // allowed.
    if (!_isInSystemLibrary) {
      errorReporter.reportErrorForNode(
          ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, node);
    }
    super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _checkForNativeFunctionBodyInNonSdkCode(node);
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    var operand = node.operand;
    if (node.operator.type == TokenType.BANG) {
      checkForUseOfVoidResult(node);
      _checkForUnnecessaryNullAware(operand, node.operator);
    } else {
      _checkForAssignmentToFinal(operand);
      _checkForIntNotAssignable(operand);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.parent is! Annotation) {
      var typeReference = ElementResolver.getTypeReference(node.prefix);
      SimpleIdentifier name = node.identifier;
      _checkForStaticAccessToInstanceMember(typeReference, name);
      _checkForInstanceAccessToStaticMember(typeReference, node.prefix, name);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    TokenType operatorType = node.operator.type;
    Expression operand = node.operand;
    if (operatorType != TokenType.BANG) {
      if (operatorType.isIncrementOperator) {
        _checkForAssignmentToFinal(operand);
      }
      checkForUseOfVoidResult(operand);
      _checkForIntNotAssignable(operand);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var target = node.realTarget;
    var typeReference = ElementResolver.getTypeReference(target);
    SimpleIdentifier propertyName = node.propertyName;
    _checkForStaticAccessToInstanceMember(typeReference, propertyName);
    _checkForInstanceAccessToStaticMember(
        typeReference, node.target, propertyName);
    _checkForUnnecessaryNullAware(target, node.operator);
    _checkUseVerifier.checkPropertyAccess(node);
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _requiredParametersVerifier.visitRedirectingConstructorInvocation(node);
    _isInConstructorInitializer = true;
    try {
      super.visitRedirectingConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _checkForRethrowOutsideCatch(node);
    super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) {
      _enclosingExecutable._returnsWithout.add(node);
    } else {
      _enclosingExecutable._returnsWith.add(node);
    }
    _returnTypeVerifier.verifyReturnStatement(node);
    super.visitReturnStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isMap) {
      _typeArgumentsVerifier.checkMapLiteral(node);
      _checkForMapTypeNotAssignable(node);
      _checkForNonConstMapAsExpressionStatement3(node);
    } else if (node.isSet) {
      _typeArgumentsVerifier.checkSetLiteral(node);
      _checkForSetElementTypeNotAssignable3(node);
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _checkForPrivateOptionalParameter(node);
    _checkForTypeAnnotationDeferredClass(node.type);

    // Checks for an implicit dynamic parameter type.
    //
    // We can skip other parameter kinds besides simple formal, because:
    // - DefaultFormalParameter contains a simple one, so it gets here,
    // - FieldFormalParameter error should be reported on the field,
    // - FunctionTypedFormalParameter is a function type, not dynamic.
    _checkForImplicitDynamicIdentifier(node, node.identifier);

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _checkForAmbiguousImport(node);
    _checkForReferenceBeforeDeclaration(node);
    _checkForInvalidInstanceMemberAccess(node);
    _checkForTypeParameterReferencedByStatic(node);
    if (!_isUnqualifiedReferenceToNonLocalStaticMemberAllowed(node)) {
      _checkForUnqualifiedReferenceToNonLocalStaticMember(node);
    }
    _checkUseVerifier.checkSimpleIdentifier(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    if (node.isNullAware) {
      _checkForUnnecessaryNullAware(node.expression, node.spreadOperator);
    }
    super.visitSpreadElement(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _requiredParametersVerifier.visitSuperConstructorInvocation(node);
    _isInConstructorInitializer = true;
    try {
      super.visitSuperConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _withHiddenElements(node.statements, () {
      _duplicateDefinitionVerifier.checkStatements(node.statements);
      super.visitSwitchCase(node);
    });
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _withHiddenElements(node.statements, () {
      _duplicateDefinitionVerifier.checkStatements(node.statements);
      super.visitSwitchDefault(node);
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _checkForSwitchExpressionNotAssignable(node);
    _checkForCaseBlocksNotTerminated(node);
    _checkForMissingEnumConstantInSwitch(node);
    super.visitSwitchStatement(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _checkForInvalidReferenceToThis(node);
    super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _checkForConstEvalThrowsException(node);
    checkForUseOfVoidResult(node.expression);
    _checkForThrowOfInvalidType(node);
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _checkForFinalNotInitialized(node.variables);
    _checkForNotInitializedNonNullableVariable(node.variables);

    for (var declaration in node.variables.variables) {
      _checkForMainFunction(declaration.name);
    }

    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    NodeList<TypeAnnotation> list = node.arguments;
    for (TypeAnnotation type in list) {
      _checkForTypeAnnotationDeferredClass(type);
    }
    super.visitTypeArgumentList(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _checkForBuiltInIdentifierAsName(node.name,
        CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME);
    _checkForTypeAnnotationDeferredClass(node.bound);
    _checkForImplicitDynamicType(node.bound);
    _checkForGenericFunctionType(node.bound);
    node.bound?.accept(_uninstantiatedBoundChecker);
    super.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _duplicateDefinitionVerifier.checkTypeParameters(node);
    _checkForTypeParameterBoundRecursion(node.typeParameters);
    super.visitTypeParameterList(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    SimpleIdentifier nameNode = node.name;
    var initializerNode = node.initializer;
    // do checks
    _checkForImplicitDynamicIdentifier(node, nameNode);
    _checkForAbstractOrExternalVariableInitializer(node);
    // visit name
    nameNode.accept(this);
    // visit initializer
    String name = nameNode.name;
    _namesForReferenceToDeclaredVariableInInitializer.add(name);
    try {
      if (initializerNode != null) {
        initializerNode.accept(this);
      }
    } finally {
      _namesForReferenceToDeclaredVariableInInitializer.remove(name);
    }
    // declare the variable
    AstNode grandparent = node.parent!.parent!;
    if (grandparent is! TopLevelVariableDeclaration &&
        grandparent is! FieldDeclaration) {
      VariableElement element = node.declaredElement!;
      // There is no hidden elements if we are outside of a function body,
      // which will happen for variables declared in control flow elements.
      _hiddenElements?.declare(element);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _checkForTypeAnnotationDeferredClass(node.type);
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _isInLateLocalVariable.add(node.variables.isLate);

    _checkForFinalNotInitialized(node.variables);
    super.visitVariableDeclarationStatement(node);

    _isInLateLocalVariable.removeLast();
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes2.forEach(_checkForImplicitDynamicType);
    super.visitWithClause(node);
  }

  /// Checks the class for problems with the superclass, mixins, or implemented
  /// interfaces.
  void _checkClassInheritance(
      NamedCompilationUnitMember node,
      NamedType? superclass,
      WithClause? withClause,
      ImplementsClause? implementsClause) {
    // Only check for all of the inheritance logic around clauses if there
    // isn't an error code such as "Cannot extend double" already on the
    // class.
    if (!_checkForExtendsDisallowedClass(superclass) &&
        !_checkForImplementsClauseErrorCodes(implementsClause) &&
        !_checkForAllMixinErrorCodes(withClause) &&
        !_checkForNoGenerativeConstructorsInSuperclass(superclass)) {
      _checkForImplicitDynamicType(superclass);
      _checkForExtendsDeferredClass(superclass);
      _checkForRepeatedType(implementsClause?.interfaces2,
          CompileTimeErrorCode.IMPLEMENTS_REPEATED);
      _checkImplementsSuperClass(implementsClause);
      _checkMixinsSuperClass(withClause);
      _checkMixinInference(node, withClause);
      _checkForMixinWithConflictingPrivateMember(withClause, superclass);
      _checkForConflictingGenerics(node);
      if (node is ClassDeclaration) {
        _checkForNoDefaultSuperConstructorImplicit(node);
      }
    }
  }

  /// Given a list of [directives] that have the same prefix, generate an error
  /// if there is more than one import and any of those imports is deferred.
  ///
  /// See [CompileTimeErrorCode.SHARED_DEFERRED_PREFIX].
  void _checkDeferredPrefixCollision(List<ImportDirective> directives) {
    int count = directives.length;
    if (count > 1) {
      for (int i = 0; i < count; i++) {
        var deferredToken = directives[i].deferredKeyword;
        if (deferredToken != null) {
          errorReporter.reportErrorForToken(
              CompileTimeErrorCode.SHARED_DEFERRED_PREFIX, deferredToken);
        }
      }
    }
  }

  void _checkForAbstractOrExternalFieldConstructorInitializer(
      AstNode node, FieldElement fieldElement) {
    if (fieldElement.isAbstract) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER, node);
    }
    if (fieldElement.isExternal) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER, node);
    }
  }

  void _checkForAbstractOrExternalVariableInitializer(
      VariableDeclaration node) {
    var declaredElement = node.declaredElement;
    if (node.initializer != null) {
      if (declaredElement is FieldElement) {
        if (declaredElement.isAbstract) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.ABSTRACT_FIELD_INITIALIZER, node.name);
        }
        if (declaredElement.isExternal) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.EXTERNAL_FIELD_INITIALIZER, node.name);
        }
      } else if (declaredElement is TopLevelVariableElement) {
        if (declaredElement.isExternal) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.EXTERNAL_VARIABLE_INITIALIZER, node.name);
        }
      }
    }
  }

  /// Verify that all classes of the given [withClause] are valid.
  ///
  /// See [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR],
  /// [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT].
  bool _checkForAllMixinErrorCodes(WithClause? withClause) {
    if (withClause == null) {
      return false;
    }
    bool problemReported = false;
    int mixinTypeIndex = -1;
    for (int mixinNameIndex = 0;
        mixinNameIndex < withClause.mixinTypes2.length;
        mixinNameIndex++) {
      NamedType mixinName = withClause.mixinTypes2[mixinNameIndex];
      DartType mixinType = mixinName.typeOrThrow;
      if (mixinType is InterfaceType) {
        mixinTypeIndex++;
        if (_checkForExtendsOrImplementsDisallowedClass(
            mixinName, CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS)) {
          problemReported = true;
        } else {
          ClassElement mixinElement = mixinType.element;
          if (_checkForExtendsOrImplementsDeferredClass(
              mixinName, CompileTimeErrorCode.MIXIN_DEFERRED_CLASS)) {
            problemReported = true;
          }
          if (mixinElement.isMixin) {
            if (_checkForMixinSuperclassConstraints(
                mixinNameIndex, mixinName)) {
              problemReported = true;
            } else if (_checkForMixinSuperInvokedMembers(
                mixinTypeIndex, mixinName, mixinElement, mixinType)) {
              problemReported = true;
            }
          } else {
            if (_checkForMixinClassDeclaresConstructor(
                mixinName, mixinElement)) {
              problemReported = true;
            }
            if (_checkForMixinInheritsNotFromObject(mixinName, mixinElement)) {
              problemReported = true;
            }
          }
        }
      }
    }
    return problemReported;
  }

  /// Check for errors related to the redirected constructors.
  void _checkForAllRedirectConstructorErrorCodes(
      ConstructorDeclaration declaration) {
    // Prepare redirected constructor node
    var redirectedConstructor = declaration.redirectedConstructor;
    if (redirectedConstructor == null) {
      return;
    }

    // Prepare redirected constructor type
    var redirectedElement = redirectedConstructor.staticElement;
    if (redirectedElement == null) {
      // If the element is null, we check for the
      // REDIRECT_TO_MISSING_CONSTRUCTOR case
      NamedType constructorNamedType = redirectedConstructor.type2;
      DartType redirectedType = constructorNamedType.typeOrThrow;
      if (redirectedType.element != null && !redirectedType.isDynamic) {
        // Prepare the constructor name
        String constructorStrName = constructorNamedType.name.name;
        if (redirectedConstructor.name != null) {
          constructorStrName += ".${redirectedConstructor.name!.name}";
        }
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR,
            redirectedConstructor,
            [constructorStrName, redirectedType]);
      }
      return;
    }
    FunctionType redirectedType = redirectedElement.type;
    DartType redirectedReturnType = redirectedType.returnType;

    // Report specific problem when return type is incompatible
    FunctionType constructorType = declaration.declaredElement!.type;
    DartType constructorReturnType = constructorType.returnType;
    if (!typeSystem.isAssignableTo(
        redirectedReturnType, constructorReturnType)) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.REDIRECT_TO_INVALID_RETURN_TYPE,
          redirectedConstructor,
          [redirectedReturnType, constructorReturnType]);
      return;
    } else if (!typeSystem.isSubtypeOf(redirectedType, constructorType)) {
      // Check parameters.
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.REDIRECT_TO_INVALID_FUNCTION_TYPE,
          redirectedConstructor,
          [redirectedType, constructorType]);
    }
  }

  /// Verify that the export namespace of the given export [directive] does not
  /// export any name already exported by another export directive. The
  /// [exportElement] is the [ExportElement] retrieved from the node. If the
  /// element in the node was `null`, then this method is not called. The
  /// [exportedLibrary] is the library element containing the exported element.
  ///
  /// See [CompileTimeErrorCode.AMBIGUOUS_EXPORT].
  void _checkForAmbiguousExport(ExportDirective directive,
      ExportElement exportElement, LibraryElement? exportedLibrary) {
    if (exportedLibrary == null) {
      return;
    }
    // check exported names
    Namespace namespace =
        NamespaceBuilder().createExportNamespaceForDirective(exportElement);
    Map<String, Element> definedNames = namespace.definedNames;
    for (String name in definedNames.keys) {
      var element = definedNames[name]!;
      var prevElement = _exportedElements[name];
      if (prevElement != null && prevElement != element) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.AMBIGUOUS_EXPORT, directive.uri, [
          name,
          prevElement.library!.definingCompilationUnit.source.uri,
          element.library!.definingCompilationUnit.source.uri
        ]);
        return;
      } else {
        _exportedElements[name] = element;
      }
    }
  }

  /// Check the given node to see whether it was ambiguous because the name was
  /// imported from two or more imports.
  void _checkForAmbiguousImport(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element is MultiplyDefinedElementImpl) {
      String name = element.displayName;
      List<Element> conflictingMembers = element.conflictingElements;
      var libraryNames =
          conflictingMembers.map((e) => _getLibraryName(e)).toList();
      libraryNames.sort();
      errorReporter.reportErrorForNode(CompileTimeErrorCode.AMBIGUOUS_IMPORT,
          node, [name, StringUtilities.printListOfQuotedNames(libraryNames)]);
    }
  }

  /// Verify that the given [expression] is not final.
  ///
  /// See [CompileTimeErrorCode.ASSIGNMENT_TO_CONST],
  /// [CompileTimeErrorCode.ASSIGNMENT_TO_FINAL], and
  /// [CompileTimeErrorCode.ASSIGNMENT_TO_METHOD].
  void _checkForAssignmentToFinal(Expression expression) {
    // TODO(scheglov) Check SimpleIdentifier(s) as all other nodes.
    if (expression is! SimpleIdentifier) return;

    // Already handled in the assignment resolver.
    if (expression.parent is AssignmentExpression) {
      return;
    }

    // prepare element
    var highlightedNode = expression;
    var element = expression.staticElement;
    if (expression is PrefixedIdentifier) {
      var prefixedIdentifier = expression as PrefixedIdentifier;
      highlightedNode = prefixedIdentifier.identifier;
    }
    // check if element is assignable
    if (element is VariableElement) {
      if (element.isConst) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_CONST,
          expression,
        );
      } else if (element.isFinal) {
        if (_isNonNullableByDefault) {
          // Handled during resolution, with flow analysis.
        } else {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL,
            expression,
            [element.name],
          );
        }
      }
    } else if (element is PropertyAccessorElement && element.isGetter) {
      var variable = element.variable;
      if (variable.isConst) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_CONST,
          expression,
        );
      } else if (variable is FieldElement && variable.isSynthetic) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER,
          highlightedNode,
          [variable.name, variable.enclosingElement.displayName],
        );
      } else {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_FINAL,
          highlightedNode,
          [variable.name],
        );
      }
    } else if (element is FunctionElement) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_FUNCTION, expression);
    } else if (element is MethodElement) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, expression);
    } else if (element is ClassElement ||
        element is DynamicElementImpl ||
        element is TypeParameterElement) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, expression);
    }
  }

  void _checkForAwaitInLateLocalVariableInitializer(AwaitExpression node) {
    if (_isInLateLocalVariable.last) {
      errorReporter.reportErrorForToken(
        CompileTimeErrorCode.AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER,
        node.awaitKeyword,
      );
    }
  }

  /// Verifies that the class is not named `Function` and that it doesn't
  /// extends/implements/mixes in `Function`.
  void _checkForBadFunctionUse(ClassDeclaration node) {
    var extendsClause = node.extendsClause;
    var implementsClause = node.implementsClause;
    var withClause = node.withClause;

    if (node.name.name == "Function") {
      errorReporter.reportErrorForNode(
          HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION, node.name);
    }

    if (extendsClause != null) {
      var superElement = extendsClause.superclass2.name.staticElement;
      if (superElement != null && superElement.name == "Function") {
        errorReporter.reportErrorForNode(
            HintCode.DEPRECATED_EXTENDS_FUNCTION, extendsClause.superclass2);
      }
    }

    if (implementsClause != null) {
      for (var interface in implementsClause.interfaces2) {
        var type = interface.type;
        if (type != null && type.isDartCoreFunction) {
          errorReporter.reportErrorForNode(
            HintCode.DEPRECATED_IMPLEMENTS_FUNCTION,
            interface,
          );
          break;
        }
      }
    }

    if (withClause != null) {
      for (NamedType type in withClause.mixinTypes2) {
        var mixinElement = type.name.staticElement;
        if (mixinElement != null && mixinElement.name == "Function") {
          errorReporter.reportErrorForNode(
              HintCode.DEPRECATED_MIXIN_FUNCTION, type);
        }
      }
    }
  }

  /// Verify that the given [identifier] is not a keyword, and generates the
  /// given [errorCode] on the identifier if it is a keyword.
  ///
  /// See [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME],
  /// [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME],
  /// [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME], and
  /// [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME].
  void _checkForBuiltInIdentifierAsName(
      SimpleIdentifier identifier, ErrorCode errorCode) {
    Token token = identifier.token;
    if (token.type.isKeyword && token.keyword?.isPseudo != true) {
      errorReporter
          .reportErrorForNode(errorCode, identifier, [identifier.name]);
    }
  }

  /// Verify that the given [switchCase] is terminated with 'break', 'continue',
  /// 'return' or 'throw'.
  ///
  /// see [CompileTimeErrorCode.CASE_BLOCK_NOT_TERMINATED].
  void _checkForCaseBlockNotTerminated(SwitchCase switchCase) {
    NodeList<Statement> statements = switchCase.statements;
    if (statements.isEmpty) {
      // fall-through without statements at all
      var parent = switchCase.parent;
      if (parent is SwitchStatement) {
        NodeList<SwitchMember> members = parent.members;
        int index = members.indexOf(switchCase);
        if (index != -1 && index < members.length - 1) {
          return;
        }
      }
      // no other switch member after this one
    } else {
      Statement statement = statements.last;
      if (statement is Block && statement.statements.isNotEmpty) {
        Block block = statement;
        statement = block.statements.last;
      }
      // terminated with statement
      if (statement is BreakStatement ||
          statement is ContinueStatement ||
          statement is ReturnStatement) {
        return;
      }
      // terminated with 'throw' expression
      if (statement is ExpressionStatement) {
        Expression expression = statement.expression;
        if (expression is ThrowExpression || expression is RethrowExpression) {
          return;
        }
      }
    }

    errorReporter.reportErrorForToken(
        CompileTimeErrorCode.CASE_BLOCK_NOT_TERMINATED, switchCase.keyword);
  }

  /// Verify that the switch cases in the given switch [statement] are
  /// terminated with 'break', 'continue', 'rethrow', 'return' or 'throw'.
  ///
  /// See [CompileTimeErrorCode.CASE_BLOCK_NOT_TERMINATED].
  void _checkForCaseBlocksNotTerminated(SwitchStatement statement) {
    if (_isNonNullableByDefault) return;

    NodeList<SwitchMember> members = statement.members;
    int lastMember = members.length - 1;
    for (int i = 0; i < lastMember; i++) {
      SwitchMember member = members[i];
      if (member is SwitchCase) {
        _checkForCaseBlockNotTerminated(member);
      }
    }
  }

  /// Verify that the [_enclosingClass] does not have a method and getter pair
  /// with the same name, via inheritance.
  ///
  /// See [CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE],
  /// [CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD], and
  /// [CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD].
  void _checkForConflictingClassMembers() {
    if (_enclosingClass == null) {
      return;
    }
    Uri libraryUri = _currentLibrary.source.uri;

    // method declared in the enclosing class vs. inherited getter/setter
    for (MethodElement method in _enclosingClass!.methods) {
      String name = method.name;

      // find inherited property accessor
      var inherited = _inheritanceManager.getInherited2(
          _enclosingClass!, Name(libraryUri, name));
      inherited ??= _inheritanceManager.getInherited2(
          _enclosingClass!, Name(libraryUri, '$name='));

      if (method.isStatic && inherited != null) {
        errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, method, [
          _enclosingClass!.displayName,
          name,
          inherited.enclosingElement.displayName,
        ]);
      } else if (inherited is PropertyAccessorElement) {
        errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, method, [
          _enclosingClass!.displayName,
          name,
          inherited.enclosingElement.displayName
        ]);
      }
    }

    // getter declared in the enclosing class vs. inherited method
    for (PropertyAccessorElement accessor in _enclosingClass!.accessors) {
      String name = accessor.displayName;

      // find inherited method or property accessor
      var inherited = _inheritanceManager.getInherited2(
          _enclosingClass!, Name(libraryUri, name));
      inherited ??= _inheritanceManager.getInherited2(
          _enclosingClass!, Name(libraryUri, '$name='));

      if (accessor.isStatic && inherited != null) {
        errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, accessor, [
          _enclosingClass!.displayName,
          name,
          inherited.enclosingElement.displayName,
        ]);
      } else if (inherited is MethodElement) {
        errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, accessor, [
          _enclosingClass!.displayName,
          name,
          inherited.enclosingElement.displayName
        ]);
      }
    }
  }

  /// Verify all conflicts between type variable and enclosing class.
  /// TODO(scheglov)
  void _checkForConflictingClassTypeVariableErrorCodes() {
    for (TypeParameterElement typeParameter
        in _enclosingClass!.typeParameters) {
      String name = typeParameter.name;
      // name is same as the name of the enclosing class
      if (_enclosingClass!.name == name) {
        var code = _enclosingClass!.isMixin
            ? CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MIXIN
            : CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS;
        errorReporter.reportErrorForElement(code, typeParameter, [name]);
      }
      // check members
      if (_enclosingClass!.getMethod(name) != null ||
          _enclosingClass!.getGetter(name) != null ||
          _enclosingClass!.getSetter(name) != null) {
        var code = _enclosingClass!.isMixin
            ? CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN
            : CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS;
        errorReporter.reportErrorForElement(code, typeParameter, [name]);
      }
    }
  }

  /// Verify all conflicts between type variable and enclosing extension.
  ///
  /// See [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION], and
  /// [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION_MEMBER].
  void _checkForConflictingExtensionTypeVariableErrorCodes() {
    for (TypeParameterElement typeParameter
        in _enclosingExtension!.typeParameters) {
      String name = typeParameter.name;
      // name is same as the name of the enclosing class
      if (_enclosingExtension!.name == name) {
        errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION,
            typeParameter,
            [name]);
      }
      // check members
      if (_enclosingExtension!.getMethod(name) != null ||
          _enclosingExtension!.getGetter(name) != null ||
          _enclosingExtension!.getSetter(name) != null) {
        errorReporter.reportErrorForElement(
            CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION,
            typeParameter,
            [name]);
      }
    }
  }

  void _checkForConflictingGenerics(NamedCompilationUnitMember node) {
    var element = node.declaredElement as ClassElement;

    var analysisSession = _currentLibrary.session as AnalysisSessionImpl;
    var errors = analysisSession.classHierarchy.errors(element);

    for (var error in errors) {
      if (error is IncompatibleInterfacesClassHierarchyError) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES,
          node.name,
          [
            _enclosingClass!.name,
            error.first.getDisplayString(withNullability: true),
            error.second.getDisplayString(withNullability: true),
          ],
        );
      } else {
        throw UnimplementedError('${error.runtimeType}');
      }
    }
  }

  /// Check that the given constructor [declaration] has a valid combination of
  /// redirecting constructor invocation(s), super constructor invocation(s),
  /// field initializers, and assert initializers.
  void _checkForConflictingInitializerErrorCodes(
      ConstructorDeclaration declaration) {
    // Count and check each redirecting initializer.
    var redirectingInitializerCount = 0;
    var superInitializerCount = 0;
    late SuperConstructorInvocation superInitializer;
    for (ConstructorInitializer initializer in declaration.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (redirectingInitializerCount > 0) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS,
              initializer);
        }
        if (declaration.factoryKeyword == null) {
          RedirectingConstructorInvocation invocation = initializer;
          var redirectingElement = invocation.staticElement;
          if (redirectingElement == null) {
            String enclosingNamedType = _enclosingClass!.displayName;
            String constructorStrName = enclosingNamedType;
            if (invocation.constructorName != null) {
              constructorStrName += ".${invocation.constructorName!.name}";
            }
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR,
                invocation,
                [constructorStrName, enclosingNamedType]);
          } else {
            if (redirectingElement.isFactory) {
              errorReporter.reportErrorForNode(
                  CompileTimeErrorCode
                      .REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR,
                  initializer);
            }
          }
        }
        // [declaration] is a redirecting constructor via a redirecting
        // initializer.
        _checkForRedirectToNonConstConstructor(
          declaration.declaredElement!,
          initializer.staticElement,
          initializer.constructorName ?? initializer.thisKeyword,
        );
        redirectingInitializerCount++;
      } else if (initializer is SuperConstructorInvocation) {
        if (superInitializerCount == 1) {
          // Only report the second (first illegal) superinitializer.
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS, initializer);
        }
        superInitializer = initializer;
        superInitializerCount++;
      }
    }
    // Check for initializers which are illegal when alongside a redirecting
    // initializer.
    if (redirectingInitializerCount > 0) {
      for (ConstructorInitializer initializer in declaration.initializers) {
        if (initializer is SuperConstructorInvocation) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR,
              initializer);
        }
        if (initializer is ConstructorFieldInitializer) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR,
              initializer);
        }
        if (initializer is AssertInitializer) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR,
              initializer);
        }
      }
    }
    if (redirectingInitializerCount == 0 &&
        superInitializerCount == 1 &&
        superInitializer != declaration.initializers.last) {
      var superNamedType = _enclosingClass!.supertype!.element.displayName;
      var constructorStrName = superNamedType;
      var constructorName = superInitializer.constructorName;
      if (constructorName != null) {
        constructorStrName += '.${constructorName.name}';
      }
      errorReporter.reportErrorForToken(
          CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST,
          superInitializer.superKeyword,
          [constructorStrName]);
    }
  }

  /// Verify that if the given [constructor] declaration is 'const' then there
  /// are no invocations of non-'const' super constructors, and that there are
  /// no instance variables mixed in.
  ///
  /// Return `true` if an error is reported here, and the caller should stop
  /// checking the constructor for constant-related errors.
  ///
  /// See [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER], and
  /// [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD].
  bool _checkForConstConstructorWithNonConstSuper(
      ConstructorDeclaration constructor) {
    if (!_enclosingExecutable.isConstConstructor) {
      return false;
    }
    // OK, const factory, checked elsewhere
    if (constructor.factoryKeyword != null) {
      return false;
    }

    // check for mixins
    var instanceFields = <FieldElement>[];
    for (var mixin in _enclosingClass!.mixins) {
      instanceFields.addAll(mixin.element.fields.where((field) {
        if (field.isStatic) {
          return false;
        }
        if (field.isSynthetic) {
          return false;
        }
        // From the abstract and external fields specification:
        // > An abstract instance variable declaration D is treated as an
        // > abstract getter declaration and possibly an abstract setter
        // > declaration. The setter is included if and only if D is non-final.
        if (field.isAbstract && field.isFinal) {
          return false;
        }
        return true;
      }));
    }
    if (instanceFields.length == 1) {
      var field = instanceFields.single;
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD,
          constructor.returnType,
          ["'${field.enclosingElement.name}.${field.name}'"]);
      return true;
    } else if (instanceFields.length > 1) {
      var fieldNames = instanceFields
          .map((field) => "'${field.enclosingElement.name}.${field.name}'")
          .join(', ');
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS,
          constructor.returnType,
          [fieldNames]);
      return true;
    }

    // try to find and check super constructor invocation
    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is SuperConstructorInvocation) {
        var element = initializer.staticElement;
        if (element == null || element.isConst) {
          return false;
        }
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER,
            initializer,
            [element.enclosingElement.displayName]);
        return true;
      }
    }
    // no explicit super constructor invocation, check default constructor
    var supertype = _enclosingClass!.supertype;
    if (supertype == null) {
      return false;
    }
    if (supertype.isDartCoreObject) {
      return false;
    }
    var unnamedConstructor = supertype.element.unnamedConstructor;
    if (unnamedConstructor == null || unnamedConstructor.isConst) {
      return false;
    }

    // default constructor is not 'const', report problem
    errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER,
        constructor.returnType,
        [supertype]);
    return true;
  }

  /// Verify that if the given [constructor] declaration is 'const' then there
  /// are no non-final instance variable. The [constructorElement] is the
  /// constructor element.
  void _checkForConstConstructorWithNonFinalField(
      ConstructorDeclaration constructor,
      ConstructorElement constructorElement) {
    if (!_enclosingExecutable.isConstConstructor) {
      return;
    }
    if (!_enclosingExecutable.isGenerativeConstructor) {
      return;
    }
    // check if there is non-final field
    ClassElement classElement = constructorElement.enclosingElement;
    if (!classElement.hasNonFinalField) {
      return;
    }
    errorReporter.reportErrorForName(
        CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
        constructor);
  }

  /// Verify that the given 'const' instance creation [expression] is not
  /// creating a deferred type. The [constructorName] is the constructor name,
  /// always non-`null`. The [namedType] is the name of the type defining the
  /// constructor, always non-`null`.
  ///
  /// See [CompileTimeErrorCode.CONST_DEFERRED_CLASS].
  void _checkForConstDeferredClass(InstanceCreationExpression expression,
      ConstructorName constructorName, NamedType namedType) {
    if (namedType.isDeferred) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_DEFERRED_CLASS, constructorName);
    }
  }

  /// Verify that the given throw [expression] is not enclosed in a 'const'
  /// constructor declaration.
  ///
  /// See [CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION].
  void _checkForConstEvalThrowsException(ThrowExpression expression) {
    if (_enclosingExecutable.isConstConstructor) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION, expression);
    }
  }

  /// Verify that the given instance creation [expression] is not being invoked
  /// on an abstract class. The [namedType] is the [NamedType] of the
  /// [ConstructorName] from the [InstanceCreationExpression], this is the AST
  /// node that the error is attached to. The [type] is the type being
  /// constructed with this [InstanceCreationExpression].
  void _checkForConstOrNewWithAbstractClass(
      InstanceCreationExpression expression,
      NamedType namedType,
      InterfaceType type) {
    if (type.element.isAbstract && !type.element.isMixin) {
      var element = expression.constructorName.staticElement;
      if (element != null && !element.isFactory) {
        bool isImplicit =
            (expression as InstanceCreationExpressionImpl).isImplicit;
        if (!isImplicit) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, namedType);
        } else {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, namedType);
        }
      }
    }
  }

  /// Verify that the given instance creation [expression] is not being invoked
  /// on an enum. The [namedType] is the [NamedType] of the [ConstructorName] from
  /// the [InstanceCreationExpression], this is the AST node that the error is
  /// attached to. The [type] is the type being constructed with this
  /// [InstanceCreationExpression].
  ///
  /// See [CompileTimeErrorCode.INSTANTIATE_ENUM].
  void _checkForConstOrNewWithEnum(InstanceCreationExpression expression,
      NamedType namedType, InterfaceType type) {
    if (type.element.isEnum) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INSTANTIATE_ENUM, namedType);
    }
  }

  /// Verify that the given [expression] is not a mixin instantiation.
  void _checkForConstOrNewWithMixin(InstanceCreationExpression expression,
      NamedType namedType, InterfaceType type) {
    if (type.element.isMixin) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MIXIN_INSTANTIATE, namedType);
    }
  }

  /// Verify that the given 'const' instance creation [expression] is not being
  /// invoked on a constructor that is not 'const'.
  ///
  /// This method assumes that the instance creation was tested to be 'const'
  /// before being called.
  ///
  /// See [CompileTimeErrorCode.CONST_WITH_NON_CONST].
  void _checkForConstWithNonConst(InstanceCreationExpression expression) {
    var constructorElement = expression.constructorName.staticElement;
    if (constructorElement != null && !constructorElement.isConst) {
      if (expression.keyword != null) {
        errorReporter.reportErrorForToken(
            CompileTimeErrorCode.CONST_WITH_NON_CONST, expression.keyword!);
      } else {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CONST_WITH_NON_CONST, expression);
      }
    }
  }

  /// Verify that if the given 'const' instance creation [expression] is being
  /// invoked on the resolved constructor. The [constructorName] is the
  /// constructor name, always non-`null`. The [namedType] is the name of the
  /// type defining the constructor, always non-`null`.
  ///
  /// This method assumes that the instance creation was tested to be 'const'
  /// before being called.
  ///
  /// See [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR], and
  /// [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT].
  void _checkForConstWithUndefinedConstructor(
      InstanceCreationExpression expression,
      ConstructorName constructorName,
      NamedType namedType) {
    // OK if resolved
    if (constructorName.staticElement != null) {
      return;
    }
    DartType type = namedType.typeOrThrow;
    if (type is InterfaceType) {
      ClassElement element = type.element;
      if (element.isEnum) {
        // We have already reported the error.
        return;
      }
    }
    Identifier className = namedType.name;
    // report as named or default constructor absence
    var name = constructorName.name;
    if (name != null) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR,
          name,
          [className.toSource(), name.name]);
    } else {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
          constructorName,
          [className.toSource()]);
    }
  }

  void _checkForDeadNullCoalesce(TypeImpl lhsType, Expression rhs) {
    if (!_isNonNullableByDefault) return;

    if (typeSystem.isStrictlyNonNullable(lhsType)) {
      errorReporter.reportErrorForNode(
        StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION,
        rhs,
      );
    }
  }

  /// Report a diagnostic if there are any extensions in the imported library
  /// that are not hidden.
  void _checkForDeferredImportOfExtensions(
      ImportDirective directive, ImportElement importElement) {
    for (var element in importElement.namespace.definedNames.values) {
      if (element is ExtensionElement) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.DEFERRED_IMPORT_OF_EXTENSION,
          directive.uri,
        );
        return;
      }
    }
  }

  /// Verify that any deferred imports in the given compilation [unit] have a
  /// unique prefix.
  ///
  /// See [CompileTimeErrorCode.SHARED_DEFERRED_PREFIX].
  void _checkForDeferredPrefixCollisions(CompilationUnit unit) {
    NodeList<Directive> directives = unit.directives;
    int count = directives.length;
    if (count > 0) {
      Map<PrefixElement, List<ImportDirective>> prefixToDirectivesMap =
          HashMap<PrefixElement, List<ImportDirective>>();
      for (int i = 0; i < count; i++) {
        Directive directive = directives[i];
        if (directive is ImportDirective) {
          var prefix = directive.prefix;
          if (prefix != null) {
            var element = prefix.staticElement;
            if (element is PrefixElement) {
              var elements = prefixToDirectivesMap[element];
              if (elements == null) {
                elements = <ImportDirective>[];
                prefixToDirectivesMap[element] = elements;
              }
              elements.add(directive);
            }
          }
        }
      }
      for (List<ImportDirective> imports in prefixToDirectivesMap.values) {
        _checkDeferredPrefixCollision(imports);
      }
    }
  }

  /// Return `true` if the caller should continue checking the rest of the
  /// information in the for-each part.
  bool _checkForEachParts(ForEachParts node, SimpleIdentifier variable) {
    if (checkForUseOfVoidResult(node.iterable)) {
      return false;
    }

    DartType iterableType = node.iterable.typeOrThrow;

    Token? awaitKeyword;
    var parent = node.parent;
    if (parent is ForStatement) {
      awaitKeyword = parent.awaitKeyword;
    } else if (parent is ForElement) {
      awaitKeyword = parent.awaitKeyword;
    }

    // Use an explicit string instead of [loopType] to remove the "<E>".
    String loopNamedType = awaitKeyword != null ? 'Stream' : 'Iterable';

    if (iterableType.isDynamic && typeSystem.strictCasts) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE,
        node.iterable,
        [iterableType, loopNamedType],
      );
      return false;
    }

    // TODO(scheglov) use NullableDereferenceVerifier
    if (_isNonNullableByDefault) {
      if (typeSystem.isNullable(iterableType)) {
        return false;
      }
    }

    // The type of the loop variable.
    DartType variableType;
    var variableElement = variable.staticElement;
    if (variableElement is VariableElement) {
      variableType = variableElement.type;
    } else {
      return false;
    }

    // The object being iterated has to implement Iterable<T> for some T that
    // is assignable to the variable's type.
    // TODO(rnystrom): Move this into mostSpecificTypeArgument()?
    iterableType = iterableType.resolveToBound(_typeProvider.objectType);

    var requiredSequenceType = awaitKeyword != null
        ? _typeProvider.streamDynamicType
        : _typeProvider.iterableDynamicType;

    if (typeSystem.isTop(iterableType)) {
      iterableType = requiredSequenceType;
    }

    if (!typeSystem.isAssignableTo(iterableType, requiredSequenceType)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE,
        node.iterable,
        [iterableType, loopNamedType],
      );
      return false;
    }

    DartType? sequenceElementType;
    {
      var sequenceElement = awaitKeyword != null
          ? _typeProvider.streamElement
          : _typeProvider.iterableElement;
      var sequenceType = iterableType.asInstanceOf(sequenceElement);
      if (sequenceType != null) {
        sequenceElementType = sequenceType.typeArguments[0];
      }
    }

    if (sequenceElementType == null) {
      return true;
    }

    if (!typeSystem.isAssignableTo(sequenceElementType, variableType)) {
      // Use an explicit string instead of [loopType] to remove the "<E>".
      String loopNamedType = awaitKeyword != null ? 'Stream' : 'Iterable';

      // A for-in loop is specified to desugar to a different set of statements
      // which include an assignment of the sequence element's `iterator`'s
      // `current` value, at which point "implicit tear-off conversion" may be
      // performed. We do not perform this desugaring; instead we allow a
      // special assignability here.
      var implicitCallMethod = getImplicitCallMethod(
          sequenceElementType, variableType, node.iterable);
      if (implicitCallMethod == null) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE,
          node.iterable,
          [iterableType, loopNamedType, variableType],
        );
      } else {
        var tearoffType = implicitCallMethod.type;
        // An implicit tear-off conversion does occur on the values of the
        // iterator, but this does not guarantee their assignability.

        if (_featureSet?.isEnabled(Feature.constructor_tearoffs) ?? true) {
          var typeArguments = typeSystem.inferFunctionTypeInstantiation(
            variableType as FunctionType,
            tearoffType,
            errorReporter: errorReporter,
            errorNode: node.iterable,
            genericMetadataIsEnabled: true,
          )!;
          if (typeArguments.isNotEmpty) {
            tearoffType = tearoffType.instantiate(typeArguments);
          }
        }

        if (!typeSystem.isAssignableTo(tearoffType, variableType)) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE,
            node.iterable,
            [iterableType, loopNamedType, variableType],
          );
        }
      }
    }

    return true;
  }

  /// Check that if the visiting library is not system, then any given library
  /// should not be SDK internal library. The [exportElement] is the
  /// [ExportElement] retrieved from the node, if the element in the node was
  /// `null`, then this method is not called.
  ///
  /// See [CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY].
  void _checkForExportInternalLibrary(
      ExportDirective directive, ExportElement exportElement) {
    if (_isInSystemLibrary) {
      return;
    }

    var exportedLibrary = exportElement.exportedLibrary;
    if (exportedLibrary == null) {
      return;
    }

    // should be private
    var sdk = _currentLibrary.context.sourceFactory.dartSdk!;
    var uri = exportedLibrary.source.uri.toString();
    var sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null) {
      return;
    }
    if (!sdkLibrary.isInternal) {
      return;
    }

    // It is safe to assume that `directive.uri.stringValue` is non-`null`,
    // because the only time it is `null` is if the URI contains a string
    // interpolation, in which case the export would never have resolved in the
    // first place.
    errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY,
        directive,
        [directive.uri.stringValue!]);
  }

  /// See [CompileTimeErrorCode.EXPORT_LEGACY_SYMBOL].
  void _checkForExportLegacySymbol(ExportDirective node) {
    if (!_isNonNullableByDefault) {
      return;
    }

    var element = node.element!;
    // TODO(scheglov) Expose from ExportElement.
    var namespace =
        NamespaceBuilder().createExportNamespaceForDirective(element);

    for (var element in namespace.definedNames.values) {
      if (element == DynamicElementImpl.instance ||
          element == NeverElementImpl.instance) {
        continue;
      }
      if (!element.library!.isNonNullableByDefault) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.EXPORT_LEGACY_SYMBOL,
          node.uri,
          [element.displayName],
        );
        // Stop after the first symbol.
        // We don't want to list them all.
        break;
      }
    }
  }

  /// Verify that the given extends [clause] does not extend a deferred class.
  ///
  /// See [CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS].
  void _checkForExtendsDeferredClass(NamedType? superclass) {
    if (superclass == null) {
      return;
    }
    _checkForExtendsOrImplementsDeferredClass(
        superclass, CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS);
  }

  /// Verify that the given extends [clause] does not extend classes such as
  /// 'num' or 'String'.
  ///
  /// See [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS].
  bool _checkForExtendsDisallowedClass(NamedType? superclass) {
    if (superclass == null) {
      return false;
    }
    return _checkForExtendsOrImplementsDisallowedClass(
        superclass, CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS);
  }

  /// Verify that the given [namedType] does not extend, implement or mixin
  /// classes that are deferred.
  ///
  /// See [_checkForExtendsDeferredClass],
  /// [_checkForExtendsDeferredClassInTypeAlias],
  /// [_checkForImplementsDeferredClass],
  /// [_checkForAllMixinErrorCodes],
  /// [CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS],
  /// [CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS], and
  /// [CompileTimeErrorCode.MIXIN_DEFERRED_CLASS].
  bool _checkForExtendsOrImplementsDeferredClass(
      NamedType namedType, ErrorCode errorCode) {
    if (namedType.isSynthetic) {
      return false;
    }
    if (namedType.isDeferred) {
      errorReporter.reportErrorForNode(errorCode, namedType);
      return true;
    }
    return false;
  }

  /// Verify that the given [namedType] does not extend, implement or mixin
  /// classes such as 'num' or 'String'.
  ///
  /// TODO(scheglov) Remove this method, when all inheritance / override
  /// is concentrated. We keep it for now only because we need to know when
  /// inheritance is completely wrong, so that we don't need to check anything
  /// else.
  bool _checkForExtendsOrImplementsDisallowedClass(
      NamedType namedType, ErrorCode errorCode) {
    if (namedType.isSynthetic) {
      return false;
    }
    // The SDK implementation may implement disallowed types. For example,
    // JSNumber in dart2js and _Smi in Dart VM both implement int.
    if (_currentLibrary.source.uri.isScheme('dart')) {
      return false;
    }
    var type = namedType.type;
    return type is InterfaceType &&
        _typeProvider.isNonSubtypableClass(type.element);
  }

  void _checkForExtensionDeclaresMemberOfObject(MethodDeclaration node) {
    if (_enclosingExtension == null) return;

    var name = node.name.name;
    if (name == '==' ||
        name == 'hashCode' ||
        name == 'toString' ||
        name == 'runtimeType' ||
        name == FunctionElement.NO_SUCH_METHOD_METHOD_NAME) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT,
        node.name,
      );
    }
  }

  /// Verify that the given field formal [parameter] is in a constructor
  /// declaration.
  ///
  /// See [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR].
  void _checkForFieldInitializingFormalRedirectingConstructor(
      FieldFormalParameter parameter) {
    // prepare the node that should be a ConstructorDeclaration
    var formalParameterList = parameter.parent;
    if (formalParameterList is! FormalParameterList) {
      formalParameterList = formalParameterList?.parent;
    }
    var constructor = formalParameterList?.parent;
    // now check whether the node is actually a ConstructorDeclaration
    if (constructor is ConstructorDeclaration) {
      // constructor cannot be a factory
      if (constructor.factoryKeyword != null) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR,
            parameter);
        return;
      }
      // constructor cannot have a redirection
      for (ConstructorInitializer initializer in constructor.initializers) {
        if (initializer is RedirectingConstructorInvocation) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR,
              parameter);
          return;
        }
      }
    } else {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
          parameter);
    }
  }

  /// Verify that the given variable declaration [list] has only initialized
  /// variables if the list is final or const.
  ///
  /// See [CompileTimeErrorCode.CONST_NOT_INITIALIZED], and
  /// [CompileTimeErrorCode.FINAL_NOT_INITIALIZED].
  void _checkForFinalNotInitialized(VariableDeclarationList list) {
    if (_isInNativeClass || list.isSynthetic) {
      return;
    }

    // Handled during resolution, with flow analysis.
    if (_isNonNullableByDefault &&
        list.isFinal &&
        list.parent is VariableDeclarationStatement) {
      return;
    }

    bool isConst = list.isConst;
    if (!(isConst || list.isFinal)) {
      return;
    }
    NodeList<VariableDeclaration> variables = list.variables;
    for (VariableDeclaration variable in variables) {
      if (variable.initializer == null) {
        if (isConst) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
              variable.name,
              [variable.name.name]);
        } else {
          var variableElement = variable.declaredElement;
          if (variableElement is FieldElement &&
              (variableElement.isAbstract || variableElement.isExternal)) {
            // Abstract and external fields can't be initialized, so no error.
          } else if (variableElement is TopLevelVariableElement &&
              variableElement.isExternal) {
            // External top level variables can't be initialized, so no error.
          } else if (!_isNonNullableByDefault || !variable.isLate) {
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.FINAL_NOT_INITIALIZED,
                variable.name,
                [variable.name.name]);
          }
        }
      }
    }
  }

  /// If there are no constructors in the given [members], verify that all
  /// final fields are initialized.  Cases in which there is at least one
  /// constructor are handled in [_checkForAllFinalInitializedErrorCodes].
  ///
  /// See [CompileTimeErrorCode.CONST_NOT_INITIALIZED], and
  /// [CompileTimeErrorCode.FINAL_NOT_INITIALIZED].
  void _checkForFinalNotInitializedInClass(List<ClassMember> members) {
    for (ClassMember classMember in members) {
      if (classMember is ConstructorDeclaration) {
        if (_isNonNullableByDefault) {
          if (classMember.factoryKeyword == null) {
            return;
          }
        } else {
          return;
        }
      }
    }
    for (ClassMember classMember in members) {
      if (classMember is FieldDeclaration) {
        var fields = classMember.fields;
        _checkForFinalNotInitialized(fields);
        _checkForNotInitializedNonNullableInstanceFields(classMember);
      }
    }
  }

  void _checkForGenericFunctionType(TypeAnnotation? node) {
    if (node == null) {
      return;
    }
    if (_featureSet?.isEnabled(Feature.generic_metadata) ?? false) {
      return;
    }
    DartType type = node.typeOrThrow;
    if (type is FunctionType && type.typeFormals.isNotEmpty) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, node);
    }
  }

  /// Verify that the given implements [clause] does not implement classes such
  /// as 'num' or 'String'.
  ///
  /// See [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS],
  /// [CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS].
  bool _checkForImplementsClauseErrorCodes(ImplementsClause? clause) {
    if (clause == null) {
      return false;
    }
    bool foundError = false;
    for (NamedType type in clause.interfaces2) {
      if (_checkForExtendsOrImplementsDisallowedClass(
          type, CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS)) {
        foundError = true;
      } else if (_checkForExtendsOrImplementsDeferredClass(
          type, CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS)) {
        foundError = true;
      }
    }
    return foundError;
  }

  void _checkForImplicitDynamicIdentifier(AstNode node, Identifier? id) {
    if (_options.implicitDynamic) {
      return;
    }
    var variable = getVariableElement(id);
    if (variable != null &&
        variable.hasImplicitType &&
        variable.type.isDynamic) {
      ErrorCode errorCode;
      if (variable is FieldElement) {
        errorCode = LanguageCode.IMPLICIT_DYNAMIC_FIELD;
      } else if (variable is ParameterElement) {
        errorCode = LanguageCode.IMPLICIT_DYNAMIC_PARAMETER;
      } else {
        errorCode = LanguageCode.IMPLICIT_DYNAMIC_VARIABLE;
      }
      // Parameters associated with a variable always have a name, so we can
      // safely rely on [id] being non-`null`.
      errorReporter.reportErrorForNode(errorCode, node, [id!.toSource()]);
    }
  }

  void _checkForImplicitDynamicReturn(
      AstNode functionName, ExecutableElement element) {
    if (_options.implicitDynamic) {
      return;
    }
    if (element is PropertyAccessorElement && element.isSetter) {
      return;
    }
    if (element.hasImplicitReturnType && element.returnType.isDynamic) {
      errorReporter.reportErrorForNode(LanguageCode.IMPLICIT_DYNAMIC_RETURN,
          functionName, [element.displayName]);
    }
  }

  void _checkForImplicitDynamicType(TypeAnnotation? node) {
    if (_options.implicitDynamic ||
        node == null ||
        (node is NamedType && node.typeArguments != null)) {
      return;
    }
    DartType type = node.typeOrThrow;
    if (type is ParameterizedType &&
        type.typeArguments.isNotEmpty &&
        type.typeArguments.any((t) => t.isDynamic)) {
      errorReporter
          .reportErrorForNode(LanguageCode.IMPLICIT_DYNAMIC_TYPE, node, [type]);
    }
  }

  /// Check that if the visiting library is not system, then any given library
  /// should not be SDK internal library. The [importElement] is the
  /// [ImportElement] retrieved from the node, if the element in the node was
  /// `null`, then this method is not called
  ///
  /// See [CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY].
  void _checkForImportInternalLibrary(
      ImportDirective directive, ImportElement importElement) {
    if (_isInSystemLibrary) {
      return;
    }

    var importedLibrary = importElement.importedLibrary;
    if (importedLibrary == null) {
      return;
    }

    // should be private
    var sdk = _currentLibrary.context.sourceFactory.dartSdk!;
    var uri = importedLibrary.source.uri.toString();
    var sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null || !sdkLibrary.isInternal) {
      return;
    }
    // The only way an import URI's `stringValue` can be `null` is if the string
    // contained interpolations, in which case the import would have failed to
    // resolve, and we would never reach here.  So it is safe to assume that
    // `directive.uri.stringValue` is non-`null`.
    errorReporter.reportErrorForNode(
        CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY,
        directive.uri,
        [directive.uri.stringValue!]);
  }

  /// Check that the given [typeReference] is not a type reference and that then
  /// the [name] is reference to an instance member.
  ///
  /// See [CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER].
  void _checkForInstanceAccessToStaticMember(
      ClassElement? typeReference, Expression? target, SimpleIdentifier name) {
    if (_isInComment) {
      // OK, in comment
      return;
    }
    // prepare member Element
    var element = name.writeOrReadElement;
    if (element is ExecutableElement) {
      if (!element.isStatic) {
        // OK, instance member
        return;
      }
      Element enclosingElement = element.enclosingElement;
      if (enclosingElement is ExtensionElement) {
        if (target is ExtensionOverride) {
          // OK, target is an extension override
          return;
        } else if (target is SimpleIdentifier &&
            target.staticElement is ExtensionElement) {
          return;
        } else if (target is PrefixedIdentifier &&
            target.staticElement is ExtensionElement) {
          return;
        }
      } else {
        if (typeReference != null) {
          // OK, target is a type
          return;
        }
        if (enclosingElement is! ClassElement) {
          // OK, top-level element
          return;
        }
      }
    }
  }

  /// Verify that an 'int' can be assigned to the parameter corresponding to the
  /// given [argument]. This is used for prefix and postfix expressions where
  /// the argument value is implicit.
  ///
  /// See [CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
  void _checkForIntNotAssignable(Expression argument) {
    var staticParameterElement = argument.staticParameterElement;
    var staticParameterType = staticParameterElement?.type;
    if (staticParameterType != null) {
      checkForArgumentTypeNotAssignable(argument, staticParameterType, _intType,
          CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE);
    }
  }

  /// Verify that the given [annotation] isn't defined in a deferred library.
  ///
  /// See [CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY].
  void _checkForInvalidAnnotationFromDeferredLibrary(Annotation annotation) {
    Identifier nameIdentifier = annotation.name;
    if (nameIdentifier is PrefixedIdentifier && nameIdentifier.isDeferred) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY,
          annotation.name);
    }
  }

  /// Check the given [initializer] to ensure that the field being initialized
  /// is a valid field. The [fieldName] is the field name from the
  /// [ConstructorFieldInitializer]. The [staticElement] is the static element
  /// from the name in the [ConstructorFieldInitializer].
  void _checkForInvalidField(ConstructorFieldInitializer initializer,
      SimpleIdentifier fieldName, Element? staticElement) {
    if (staticElement is FieldElement) {
      if (staticElement.isSynthetic) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD,
            initializer,
            [fieldName.name]);
      } else if (staticElement.isStatic) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD,
            initializer,
            [fieldName.name]);
      }
    } else {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD,
          initializer,
          [fieldName.name]);
      return;
    }
  }

  /// Verify that if the given [identifier] is part of a constructor
  /// initializer, then it does not implicitly reference 'this' expression.
  ///
  /// See [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER],
  /// [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY], and
  /// [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC].
  void _checkForInvalidInstanceMemberAccess(SimpleIdentifier identifier) {
    if (_isInComment) {
      return;
    }
    if (!_isInConstructorInitializer &&
        !_enclosingExecutable.inStaticMethod &&
        !_enclosingExecutable.inFactoryConstructor &&
        !_isInInstanceNotLateVariableDeclaration &&
        !_isInStaticVariableDeclaration) {
      return;
    }
    // prepare element
    var element = identifier.writeOrReadElement;
    if (!(element is MethodElement || element is PropertyAccessorElement)) {
      return;
    }
    // static element
    ExecutableElement executableElement = element as ExecutableElement;
    if (executableElement.isStatic) {
      return;
    }
    // not a class member
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement &&
        enclosingElement is! ExtensionElement) {
      return;
    }
    // qualified method invocation
    var parent = identifier.parent;
    if (parent is MethodInvocation) {
      if (identical(parent.methodName, identifier) &&
          parent.realTarget != null) {
        return;
      }
    }
    // qualified property access
    if (parent is PropertyAccess) {
      if (identical(parent.propertyName, identifier)) {
        return;
      }
    }
    if (parent is PrefixedIdentifier) {
      if (identical(parent.identifier, identifier)) {
        return;
      }
    }

    if (_enclosingExecutable.inStaticMethod) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, identifier);
    } else if (_enclosingExecutable.inFactoryConstructor) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, identifier);
    } else {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER,
          identifier,
          [identifier.name]);
    }
  }

  /// Check to see whether the given function [body] has a modifier associated
  /// with it, and report it as an error if it does.
  void _checkForInvalidModifierOnBody(
      FunctionBody body, CompileTimeErrorCode errorCode) {
    var keyword = body.keyword;
    if (keyword != null) {
      errorReporter.reportErrorForToken(errorCode, keyword, [keyword.lexeme]);
    }
  }

  /// Verify that the usage of the given 'this' is valid.
  ///
  /// See [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS].
  void _checkForInvalidReferenceToThis(ThisExpression expression) {
    if (!_thisAccessTracker.hasAccess) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, expression);
    }
  }

  void _checkForLateFinalFieldWithConstConstructor(FieldDeclaration node) {
    if (node.isStatic) return;

    var variableList = node.fields;
    if (!variableList.isFinal) return;

    var lateKeyword = variableList.lateKeyword;
    if (lateKeyword == null) return;

    var enclosingClass = _enclosingClass;
    if (enclosingClass == null) {
      // The field is in an extension and should be handled elsewhere.
      return;
    }

    var hasGenerativeConstConstructor =
        _enclosingClass!.constructors.any((c) => c.isConst && !c.isFactory);
    if (!hasGenerativeConstConstructor) return;

    errorReporter.reportErrorForToken(
      CompileTimeErrorCode.LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR,
      lateKeyword,
    );
  }

  void _checkForListConstructor(
      InstanceCreationExpression node, InterfaceType type) {
    if (!_isNonNullableByDefault) return;

    if (node.constructorName.name == null && type.isDartCoreList) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR,
        node.constructorName,
      );
    }
  }

  /// Verify that the elements of the given list [literal] are subtypes of the
  /// list's static type.
  ///
  /// See [CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE].
  void _checkForListElementTypeNotAssignable(ListLiteral literal) {
    // Determine the list's element type. We base this on the static type and
    // not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType listType = literal.typeOrThrow;
    assert(listType is InterfaceTypeImpl);

    List<DartType> typeArguments =
        (listType as InterfaceTypeImpl).typeArguments;
    assert(typeArguments.length == 1);

    DartType listElementType = typeArguments[0];

    // Check every list element.
    var verifier = LiteralElementVerifier(
      _typeProvider,
      typeSystem,
      errorReporter,
      this,
      forList: true,
      elementType: listElementType,
      featureSet: _featureSet!,
    );
    for (CollectionElement element in literal.elements) {
      verifier.verify(element);
    }
  }

  void _checkForMainFunction(SimpleIdentifier nameNode) {
    if (!_currentLibrary.isNonNullableByDefault) {
      return;
    }

    var element = nameNode.staticElement!;

    // We should only check exported declarations, i.e. top-level.
    if (element.enclosingElement is! CompilationUnitElement) {
      return;
    }

    if (element.displayName != 'main') {
      return;
    }

    if (element is! FunctionElement) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION,
        nameNode,
      );
      return;
    }

    var functionDeclaration = nameNode.parent as FunctionDeclaration;
    var functionExpression = functionDeclaration.functionExpression;
    var parameters = functionExpression.parameters!.parameters;
    var positional = parameters.where((e) => e.isPositional).toList();
    var requiredPositional =
        parameters.where((e) => e.isRequiredPositional).toList();

    if (requiredPositional.length > 2) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS,
        nameNode,
      );
    }

    if (parameters.any((e) => e.isRequiredNamed)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAIN_HAS_REQUIRED_NAMED_PARAMETERS,
        nameNode,
      );
    }

    if (positional.isNotEmpty) {
      var first = positional.first;
      var type = first.declaredElement!.type;
      var listOfString = _typeProvider.listType(_typeProvider.stringType);
      if (!typeSystem.isSubtypeOf(listOfString, type)) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MAIN_FIRST_POSITIONAL_PARAMETER_TYPE,
          first.notDefault.typeOrSelf,
        );
      }
    }
  }

  void _checkForMapTypeNotAssignable(SetOrMapLiteral literal) {
    // Determine the map's key and value types. We base this on the static type
    // and not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType mapType = literal.typeOrThrow;
    assert(mapType is InterfaceTypeImpl);

    List<DartType> typeArguments = (mapType as InterfaceTypeImpl).typeArguments;
    // It is possible for the number of type arguments to be inconsistent when
    // the literal is ambiguous and a non-map type was selected.
    // TODO(brianwilkerson) Unify this and _checkForSetElementTypeNotAssignable3
    //  to better handle recovery situations.
    if (typeArguments.length == 2) {
      DartType keyType = typeArguments[0];
      DartType valueType = typeArguments[1];

      var verifier = LiteralElementVerifier(
        _typeProvider,
        typeSystem,
        errorReporter,
        this,
        forMap: true,
        mapKeyType: keyType,
        mapValueType: valueType,
        featureSet: _featureSet!,
      );
      for (CollectionElement element in literal.elements) {
        verifier.verify(element);
      }
    }
  }

  /// Check to make sure that the given switch [statement] whose static type is
  /// an enum type either have a default case or include all of the enum
  /// constants.
  void _checkForMissingEnumConstantInSwitch(SwitchStatement statement) {
    // TODO(brianwilkerson) This needs to be checked after constant values have
    // been computed.
    var expressionType = statement.expression.staticType;

    var hasCaseNull = false;
    if (expressionType is InterfaceType) {
      var enumElement = expressionType.element;
      if (enumElement.isEnum) {
        var constantNames = enumElement.fields
            .where((field) => field.isStatic && !field.isSynthetic)
            .map((field) => field.name)
            .toSet();

        for (var member in statement.members) {
          if (member is SwitchCase) {
            var expression = member.expression.unParenthesized;
            if (expression is NullLiteral) {
              hasCaseNull = true;
            } else {
              var constantName = _getConstantName(expression);
              constantNames.remove(constantName);
            }
          }
          if (member is SwitchDefault) {
            return;
          }
        }

        for (var constantName in constantNames) {
          int offset = statement.offset;
          int end = statement.rightParenthesis.end;
          errorReporter.reportErrorForOffset(
            StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH,
            offset,
            end - offset,
            [constantName],
          );
        }

        if (typeSystem.isNullable(expressionType) && !hasCaseNull) {
          int offset = statement.offset;
          int end = statement.rightParenthesis.end;
          errorReporter.reportErrorForOffset(
            StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH,
            offset,
            end - offset,
            ['null'],
          );
        }
      }
    }
  }

  /// Verify that the given mixin does not have an explicitly declared
  /// constructor. The [mixinName] is the node to report problem on. The
  /// [mixinElement] is the mixing to evaluate.
  ///
  /// See [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR].
  bool _checkForMixinClassDeclaresConstructor(
      NamedType mixinName, ClassElement mixinElement) {
    for (ConstructorElement constructor in mixinElement.constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR,
            mixinName,
            [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  /// Verify that the given mixin has the 'Object' superclass.
  ///
  /// The [mixinName] is the node to report problem on. The [mixinElement] is
  /// the mixing to evaluate.
  ///
  /// See [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT].
  bool _checkForMixinInheritsNotFromObject(
      NamedType mixinName, ClassElement mixinElement) {
    var mixinSupertype = mixinElement.supertype;
    if (mixinSupertype == null || mixinSupertype.isDartCoreObject) {
      var mixins = mixinElement.mixins;
      if (mixins.isEmpty ||
          mixinElement.isMixinApplication && mixins.length < 2) {
        return false;
      }
    }

    errorReporter.reportErrorForNode(
      CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT,
      mixinName,
      [mixinElement.name],
    );
    return true;
  }

  /// Check that superclass constrains for the mixin type of [mixinName] at
  /// the [mixinIndex] position in the mixins list are satisfied by the
  /// [_enclosingClass], or a previous mixin.
  bool _checkForMixinSuperclassConstraints(
      int mixinIndex, NamedType mixinName) {
    InterfaceType mixinType = mixinName.type as InterfaceType;
    for (var constraint in mixinType.superclassConstraints) {
      var superType = _enclosingClass!.supertype as InterfaceTypeImpl;
      if (_currentLibrary.isNonNullableByDefault) {
        superType = superType.withNullability(NullabilitySuffix.none);
      }

      bool isSatisfied = typeSystem.isSubtypeOf(superType, constraint);
      if (!isSatisfied) {
        for (int i = 0; i < mixinIndex && !isSatisfied; i++) {
          isSatisfied =
              typeSystem.isSubtypeOf(_enclosingClass!.mixins[i], constraint);
        }
      }
      if (!isSatisfied) {
        // This error can only occur if [mixinName] resolved to an actual mixin,
        // so we can safely rely on `mixinName.type` being non-`null`.
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          mixinName.name,
          [
            mixinName.type!,
            superType,
            constraint,
          ],
        );
        return true;
      }
    }
    return false;
  }

  /// Check that the superclass of the given [mixinElement] at the given
  /// [mixinIndex] in the list of mixins of [_enclosingClass] has concrete
  /// implementations of all the super-invoked members of the [mixinElement].
  bool _checkForMixinSuperInvokedMembers(int mixinIndex, NamedType mixinName,
      ClassElement mixinElement, InterfaceType mixinType) {
    var mixinElementImpl = mixinElement as ClassElementImpl;
    if (mixinElementImpl.superInvokedNames.isEmpty) {
      return false;
    }

    Uri mixinLibraryUri = mixinElement.librarySource.uri;
    for (var name in mixinElementImpl.superInvokedNames) {
      var nameObject = Name(mixinLibraryUri, name);

      var superMember = _inheritanceManager.getMember2(
          _enclosingClass!, nameObject,
          forMixinIndex: mixinIndex, concrete: true, forSuper: true);

      if (superMember == null) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode
                .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
            mixinName.name,
            [name]);
        return true;
      }

      var mixinMember =
          _inheritanceManager.getMember(mixinType, nameObject, forSuper: true);

      if (mixinMember != null) {
        var isCorrect = CorrectOverrideHelper(
          library: _currentLibrary,
          thisMember: superMember,
        ).isCorrectOverrideOf(
          superMember: mixinMember,
        );
        if (!isCorrect) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode
                .MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE,
            mixinName.name,
            [name, mixinMember.type, superMember.type],
          );
          return true;
        }
      }
    }
    return false;
  }

  /// Check for the declaration of a mixin from a library other than the current
  /// library that defines a private member that conflicts with a private name
  /// from the same library but from a superclass or a different mixin.
  void _checkForMixinWithConflictingPrivateMember(
      WithClause? withClause, NamedType? superclassName) {
    if (withClause == null) {
      return;
    }
    var declaredSupertype = superclassName?.type ?? _typeProvider.objectType;
    if (declaredSupertype is! InterfaceType) {
      return;
    }
    Map<LibraryElement, Map<String, String>> mixedInNames =
        <LibraryElement, Map<String, String>>{};

    /// Report an error and return `true` if the given [name] is a private name
    /// (which is defined in the given [library]) and it conflicts with another
    /// definition of that name inherited from the superclass.
    bool isConflictingName(
        String name, LibraryElement library, NamedType namedType) {
      if (Identifier.isPrivateName(name)) {
        Map<String, String> names =
            mixedInNames.putIfAbsent(library, () => <String, String>{});
        var conflictingName = names[name];
        if (conflictingName != null) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION,
              namedType,
              [name, namedType.name.name, conflictingName]);
          return true;
        }
        names[name] = namedType.name.name;
        var inheritedMember = _inheritanceManager.getMember2(
          declaredSupertype.element,
          Name(library.source.uri, name),
          concrete: true,
        );
        if (inheritedMember != null) {
          // Inherited members are always contained inside named elements, so we
          // can safely assume `inheritedMember.enclosingElement.name` is
          // non-`null`.
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION,
              namedType, [
            name,
            namedType.name.name,
            inheritedMember.enclosingElement.name!
          ]);
          return true;
        }
      }
      return false;
    }

    for (NamedType mixinType in withClause.mixinTypes2) {
      DartType type = mixinType.typeOrThrow;
      if (type is InterfaceType) {
        LibraryElement library = type.element.library;
        if (library != _currentLibrary) {
          for (PropertyAccessorElement accessor in type.accessors) {
            if (accessor.isStatic) {
              continue;
            }
            if (isConflictingName(accessor.name, library, mixinType)) {
              return;
            }
          }
          for (MethodElement method in type.methods) {
            if (method.isStatic) {
              continue;
            }
            if (isConflictingName(method.name, library, mixinType)) {
              return;
            }
          }
        }
      }
    }
  }

  /// Checks to ensure that the given native function [body] is in SDK code.
  ///
  /// See [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE].
  void _checkForNativeFunctionBodyInNonSdkCode(NativeFunctionBody body) {
    if (!_isInSystemLibrary) {
      errorReporter.reportErrorForNode(
          ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, body);
    }
  }

  /// Verify that the given instance creation [expression] invokes an existing
  /// constructor. The [constructorName] is the constructor name.
  /// The [namedType] is the name of the type defining the constructor.
  ///
  /// This method assumes that the instance creation was tested to be 'new'
  /// before being called.
  ///
  /// See [CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR].
  void _checkForNewWithUndefinedConstructor(
      InstanceCreationExpression expression,
      ConstructorName constructorName,
      NamedType namedType) {
    // OK if resolved
    if (constructorName.staticElement != null) {
      return;
    }
    DartType type = namedType.typeOrThrow;
    if (type is InterfaceType) {
      ClassElement element = type.element;
      if (element.isEnum || element.isMixin) {
        // We have already reported the error.
        return;
      }
    }
    // prepare class name
    Identifier className = namedType.name;
    // report as named or default constructor absence
    var name = constructorName.name;
    if (name != null) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR,
          name,
          [className.toSource(), name.name]);
    } else {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
          constructorName,
          [className.toSource()]);
    }
  }

  /// Check that if the given class [declaration] implicitly calls default
  /// constructor of its superclass, there should be such default constructor -
  /// implicit or explicit.
  ///
  /// See [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT].
  void _checkForNoDefaultSuperConstructorImplicit(
      ClassDeclaration declaration) {
    // do nothing if there is explicit constructor
    List<ConstructorElement> constructors = _enclosingClass!.constructors;
    if (!constructors[0].isSynthetic) {
      return;
    }
    // prepare super
    var superType = _enclosingClass!.supertype;
    if (superType == null) {
      return;
    }
    ClassElement superElement = superType.element;
    // try to find default generative super constructor
    var superUnnamedConstructor = superElement.unnamedConstructor;
    superUnnamedConstructor = superUnnamedConstructor != null
        ? _currentLibrary.toLegacyElementIfOptOut(superUnnamedConstructor)
        : superUnnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_GENERATIVE_IMPLICIT_CONSTRUCTOR,
            declaration.name, [
          superElement.name,
          _enclosingClass!.name,
          superUnnamedConstructor
        ]);
        return;
      }
      if (superUnnamedConstructor.isDefaultConstructor) {
        return;
      }
    }

    if (!_typeProvider.isNonSubtypableClass(superType.element)) {
      // Don't report this diagnostic for non-subtypable classes because the
      // real problem was already reported.
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT,
          declaration.name,
          [superType, _enclosingClass!.displayName]);
    }
  }

  bool _checkForNoGenerativeConstructorsInSuperclass(NamedType? superclass) {
    var superType = _enclosingClass!.supertype;
    if (superType == null) {
      return false;
    }
    if (_enclosingClass!.constructors
        .every((constructor) => constructor.isFactory)) {
      // A class with no generative constructors *can* be extended if the
      // subclass has only factory constructors.
      return false;
    }
    ClassElement superElement = superType.element;
    if (superElement.constructors.isEmpty) {
      // Exclude empty constructor set, which indicates other errors occurred.
      return false;
    }
    if (superElement.constructors
        .every((constructor) => constructor.isFactory)) {
      // For `E extends Exception`, etc., this will never work, because it has
      // no generative constructors. State this clearly to users.
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS,
          superclass!,
          [_enclosingClass!.name, superElement.name]);
      return true;
    }
    return false;
  }

  /// Verify the given map [literal] either:
  /// * has `const modifier`
  /// * has explicit type arguments
  /// * is not start of the statement
  ///
  /// See [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT].
  void _checkForNonConstMapAsExpressionStatement3(SetOrMapLiteral literal) {
    // "const"
    if (literal.constKeyword != null) {
      return;
    }
    // has type arguments
    if (literal.typeArguments != null) {
      return;
    }
    // prepare statement
    var statement = literal.thisOrAncestorOfType<ExpressionStatement>();
    if (statement == null) {
      return;
    }
    // OK, statement does not start with map
    if (!identical(statement.beginToken, literal.beginToken)) {
      return;
    }

    /// TODO(srawlins): Add any tests showing this is reported.
    errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT, literal);
  }

  /// Verify that the given method [declaration] of operator `[]=`, has `void`
  /// return type.
  ///
  /// See [CompileTimeErrorCode.NON_VOID_RETURN_FOR_OPERATOR].
  void _checkForNonVoidReturnTypeForOperator(MethodDeclaration declaration) {
    // check that []= operator
    SimpleIdentifier name = declaration.name;
    if (name.name != "[]=") {
      return;
    }
    // check return type
    var annotation = declaration.returnType;
    if (annotation != null) {
      DartType type = annotation.typeOrThrow;
      if (!type.isVoid) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_VOID_RETURN_FOR_OPERATOR, annotation);
      }
    }
  }

  /// Verify the [namedType], used as the return type of a setter, is valid
  /// (either `null` or the type 'void').
  ///
  /// See [CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER].
  void _checkForNonVoidReturnTypeForSetter(TypeAnnotation? namedType) {
    if (namedType != null) {
      DartType type = namedType.typeOrThrow;
      if (!type.isVoid) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER, namedType);
      }
    }
  }

  void _checkForNotInitializedNonNullableInstanceFields(
    FieldDeclaration fieldDeclaration,
  ) {
    if (!_isNonNullableByDefault) return;

    if (fieldDeclaration.isStatic) return;
    var fields = fieldDeclaration.fields;

    if (fields.isLate) return;
    if (fields.isFinal) return;

    if (_isEnclosingClassFfiStruct) return;
    if (_isEnclosingClassFfiUnion) return;

    for (var field in fields.variables) {
      var fieldElement = field.declaredElement as FieldElement;
      if (fieldElement.isAbstract || fieldElement.isExternal) continue;
      if (field.initializer != null) continue;

      var type = fieldElement.type;
      if (!typeSystem.isPotentiallyNonNullable(type)) continue;

      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD,
        field,
        [field.name.name],
      );
    }
  }

  void _checkForNotInitializedNonNullableStaticField(FieldDeclaration node) {
    if (!node.isStatic) {
      return;
    }
    _checkForNotInitializedNonNullableVariable(node.fields);
  }

  void _checkForNotInitializedNonNullableVariable(
    VariableDeclarationList node,
  ) {
    if (!_isNonNullableByDefault) {
      return;
    }

    // Const and final checked separately.
    if (node.isConst || node.isFinal) {
      return;
    }

    if (node.isLate) {
      return;
    }

    var parent = node.parent;
    if (parent is FieldDeclaration) {
      if (parent.externalKeyword != null) {
        return;
      }
    } else if (parent is TopLevelVariableDeclaration) {
      if (parent.externalKeyword != null) {
        return;
      }
    }

    if (node.type == null) {
      return;
    }
    var type = node.type!.typeOrThrow;

    if (!typeSystem.isPotentiallyNonNullable(type)) {
      return;
    }

    for (var variable in node.variables) {
      if (variable.initializer == null) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE,
          variable.name,
          [variable.name.name],
        );
      }
    }
  }

  /// Verify that all classes of the given [onClause] are valid.
  ///
  /// See [CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS],
  /// [CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS].
  bool _checkForOnClauseErrorCodes(OnClause? onClause) {
    if (onClause == null) {
      return false;
    }
    bool problemReported = false;
    for (NamedType namedType in onClause.superclassConstraints2) {
      DartType type = namedType.typeOrThrow;
      if (type is InterfaceType) {
        if (_checkForExtendsOrImplementsDisallowedClass(
            namedType,
            CompileTimeErrorCode
                .MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS)) {
          problemReported = true;
        } else {
          if (_checkForExtendsOrImplementsDeferredClass(
              namedType,
              CompileTimeErrorCode
                  .MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS)) {
            problemReported = true;
          }
        }
      }
    }
    return problemReported;
  }

  /// Verify the given operator-method [declaration], does not have an optional
  /// parameter.
  ///
  /// This method assumes that the method declaration was tested to be an
  /// operator declaration before being called.
  ///
  /// See [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR].
  void _checkForOptionalParameterInOperator(MethodDeclaration declaration) {
    var parameterList = declaration.parameters;
    if (parameterList == null) {
      return;
    }

    NodeList<FormalParameter> formalParameters = parameterList.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      if (formalParameter.isOptional) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR,
            formalParameter);
      }
    }
  }

  /// Via informal specification: dart-lang/language/issues/4
  ///
  /// If e is an integer literal which is not the operand of a unary minus
  /// operator, then:
  ///   - If the context type is double, it is a compile-time error if the
  ///   numerical value of e is not precisely representable by a double.
  ///   Otherwise the static type of e is double and the result of evaluating e
  ///   is a double instance representing that value.
  ///   - Otherwise (the current behavior of e, with a static type of int).
  ///
  /// and
  ///
  /// If e is -n and n is an integer literal, then
  ///   - If the context type is double, it is a compile-time error if the
  ///   numerical value of n is not precisley representable by a double.
  ///   Otherwise the static type of e is double and the result of evaluating e
  ///   is the result of calling the unary minus operator on a double instance
  ///   representing the numerical value of n.
  ///   - Otherwise (the current behavior of -n)
  void _checkForOutOfRange(IntegerLiteral node) {
    String lexeme = node.literal.lexeme;
    final bool isNegated = (node as IntegerLiteralImpl).immediatelyNegated;
    final List<Object> extraErrorArgs = [];

    final bool treatedAsDouble = node.staticType == _typeProvider.doubleType;
    final bool valid = treatedAsDouble
        ? IntegerLiteralImpl.isValidAsDouble(lexeme)
        : IntegerLiteralImpl.isValidAsInteger(lexeme, isNegated);

    if (!valid) {
      extraErrorArgs.add(isNegated ? '-$lexeme' : lexeme);

      if (treatedAsDouble) {
        // Suggest the nearest valid double (as a BigInt for printing reasons).
        extraErrorArgs.add(
            BigInt.from(IntegerLiteralImpl.nearestValidDouble(lexeme))
                .toString());
      }

      errorReporter.reportErrorForNode(
          treatedAsDouble
              ? CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE
              : CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE,
          node,
          extraErrorArgs);
    }
  }

  /// Check that the given named optional [parameter] does not begin with '_'.
  void _checkForPrivateOptionalParameter(FormalParameter parameter) {
    // should be named parameter
    if (!parameter.isNamed) {
      return;
    }
    // name should start with '_'
    var name = parameter.identifier;
    if (name == null || name.isSynthetic || !name.name.startsWith('_')) {
      return;
    }

    errorReporter.reportErrorForNode(
        CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, name);
  }

  /// Check whether the given constructor [declaration] is the redirecting
  /// generative constructor and references itself directly or indirectly. The
  /// [constructorElement] is the constructor element.
  ///
  /// See [CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT].
  void _checkForRecursiveConstructorRedirect(ConstructorDeclaration declaration,
      ConstructorElement constructorElement) {
    // we check generative constructor here
    if (declaration.factoryKeyword != null) {
      return;
    }
    // try to find redirecting constructor invocation and analyze it for
    // recursion
    for (ConstructorInitializer initializer in declaration.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (_hasRedirectingFactoryConstructorCycle(constructorElement)) {
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, initializer);
        }
        return;
      }
    }
  }

  /// Check whether the given constructor [declaration] has redirected
  /// constructor and references itself directly or indirectly. The
  /// constructor [element] is the element introduced by the declaration.
  ///
  /// See [CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT].
  bool _checkForRecursiveFactoryRedirect(
      ConstructorDeclaration declaration, ConstructorElement element) {
    // prepare redirected constructor
    var redirectedConstructorNode = declaration.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return false;
    }
    // OK if no cycle
    if (!_hasRedirectingFactoryConstructorCycle(element)) {
      return false;
    }
    // report error
    errorReporter.reportErrorForNode(
        CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
        redirectedConstructorNode);
    return true;
  }

  /// Check that the given constructor [declaration] has a valid redirected
  /// constructor.
  void _checkForRedirectingConstructorErrorCodes(
      ConstructorDeclaration declaration) {
    // Check for default values in the parameters.
    var redirectedConstructor = declaration.redirectedConstructor;
    if (redirectedConstructor == null) {
      return;
    }
    for (FormalParameter parameter in declaration.parameters.parameters) {
      if (parameter is DefaultFormalParameter &&
          parameter.defaultValue != null) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode
                .DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR,
            parameter.identifier!);
      }
    }
    var redirectedElement = redirectedConstructor.staticElement;
    _checkForRedirectToNonConstConstructor(
      declaration.declaredElement!,
      redirectedElement,
      redirectedConstructor,
    );
    var redirectedClass = redirectedElement?.enclosingElement;
    if (redirectedClass is ClassElement &&
        redirectedClass.isAbstract &&
        redirectedElement != null &&
        !redirectedElement.isFactory) {
      String enclosingNamedType = _enclosingClass!.displayName;
      String constructorStrName = enclosingNamedType;
      if (declaration.name != null) {
        constructorStrName += ".${declaration.name!.name}";
      }
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR,
          redirectedConstructor,
          [constructorStrName, redirectedClass.name]);
    }
  }

  /// Check whether the redirecting constructor, [element], is const, and
  /// [redirectedElement], its redirectee, is not const.
  ///
  /// See [CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR].
  void _checkForRedirectToNonConstConstructor(
    ConstructorElement element,
    ConstructorElement? redirectedElement,
    SyntacticEntity errorEntity,
  ) {
    // This constructor is const, but it redirects to a non-const constructor.
    if (redirectedElement != null &&
        element.isConst &&
        !redirectedElement.isConst) {
      errorReporter.reportErrorForOffset(
        CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR,
        errorEntity.offset,
        errorEntity.end - errorEntity.offset,
      );
    }
  }

  void _checkForReferenceBeforeDeclaration(SimpleIdentifier node) {
    var element = node.staticElement;
    if (!node.inDeclarationContext() &&
        element != null &&
        _hiddenElements != null &&
        _hiddenElements!.contains(element) &&
        node.parent is! CommentReference) {
      errorReporter.reportError(DiagnosticFactory()
          .referencedBeforeDeclaration(errorReporter.source, node));
    }
  }

  void _checkForRepeatedType(List<NamedType>? namedTypes, ErrorCode errorCode) {
    if (namedTypes == null) {
      return;
    }

    int count = namedTypes.length;
    List<bool> detectedRepeatOnIndex = List<bool>.filled(count, false);
    for (int i = 0; i < count; i++) {
      if (!detectedRepeatOnIndex[i]) {
        var type = namedTypes[i].type;
        if (type is InterfaceType) {
          var element = type.element;
          for (int j = i + 1; j < count; j++) {
            var otherNode = namedTypes[j];
            var otherType = otherNode.type;
            if (otherType is InterfaceType && otherType.element == element) {
              detectedRepeatOnIndex[j] = true;
              errorReporter
                  .reportErrorForNode(errorCode, otherNode, [element.name]);
            }
          }
        }
      }
    }
  }

  /// Check that the given rethrow [expression] is inside of a catch clause.
  ///
  /// See [CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH].
  void _checkForRethrowOutsideCatch(RethrowExpression expression) {
    if (!_isInCatchClause) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH, expression);
    }
  }

  /// Check that if the given constructor [declaration] is generative, then
  /// it does not have an expression function body.
  ///
  /// See [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR].
  void _checkForReturnInGenerativeConstructor(
      ConstructorDeclaration declaration) {
    // ignore factory
    if (declaration.factoryKeyword != null) {
      return;
    }
    // block body (with possible return statement) is checked elsewhere
    FunctionBody body = declaration.body;
    if (body is! ExpressionFunctionBody) {
      return;
    }

    errorReporter.reportErrorForNode(
        CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, body);
  }

  /// Verify that the elements in the given set [literal] are subtypes of the
  /// set's static type.
  ///
  /// See [CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE].
  void _checkForSetElementTypeNotAssignable3(SetOrMapLiteral literal) {
    // Determine the set's element type. We base this on the static type and
    // not the literal's type arguments because in strong mode, the type
    // arguments may be inferred.
    DartType setType = literal.typeOrThrow;
    assert(setType is InterfaceTypeImpl);

    List<DartType> typeArguments = (setType as InterfaceTypeImpl).typeArguments;
    // It is possible for the number of type arguments to be inconsistent when
    // the literal is ambiguous and a non-set type was selected.
    // TODO(brianwilkerson) Unify this and _checkForMapTypeNotAssignable3 to
    //  better handle recovery situations.
    if (typeArguments.length == 1) {
      DartType setElementType = typeArguments[0];

      // Check every set element.
      var verifier = LiteralElementVerifier(
        _typeProvider,
        typeSystem,
        errorReporter,
        this,
        forSet: true,
        elementType: setElementType,
        featureSet: _featureSet!,
      );
      for (CollectionElement element in literal.elements) {
        verifier.verify(element);
      }
    }
  }

  /// Check the given [typeReference] and that the [name] is not a reference to
  /// an instance member.
  ///
  /// See [CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER].
  void _checkForStaticAccessToInstanceMember(
      ClassElement? typeReference, SimpleIdentifier name) {
    // OK, in comment
    if (_isInComment) {
      return;
    }
    // OK, target is not a type
    if (typeReference == null) {
      return;
    }
    // prepare member Element
    var element = name.staticElement;
    if (element is ExecutableElement) {
      // OK, static
      if (element.isStatic || element is ConstructorElement) {
        return;
      }
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
          name,
          [name.name]);
    }
  }

  /// Check that the type of the expression in the given 'switch' [statement] is
  /// assignable to the type of the 'case' members.
  ///
  /// See [CompileTimeErrorCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE].
  void _checkForSwitchExpressionNotAssignable(SwitchStatement statement) {
    // For NNBD we verify runtime types of values, and subtyping.
    if (_isNonNullableByDefault) {
      return;
    }

    Expression expression = statement.expression;
    if (checkForUseOfVoidResult(expression)) {
      return;
    }

    // prepare 'switch' expression type
    DartType expressionType = expression.typeOrThrow;

    // compare with type of the first non-default 'case'
    var switchCase = statement.members.whereType<SwitchCase>().firstOrNull;
    if (switchCase == null) {
      return;
    }

    Expression caseExpression = switchCase.expression;
    DartType caseType = caseExpression.typeOrThrow;

    // check types
    if (!typeSystem.isAssignableTo(expressionType, caseType)) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE,
          expression,
          [expressionType, caseType]);
    }
  }

  void _checkForThrowOfInvalidType(ThrowExpression node) {
    if (!_isNonNullableByDefault) return;

    var expression = node.expression;
    var type = node.expression.typeOrThrow;

    if (!typeSystem.isAssignableTo(type, typeSystem.objectNone)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.THROW_OF_INVALID_TYPE,
        expression,
        [type],
      );
    }
  }

  /// Verify that the given [element] does not reference itself directly.
  /// If it does, report the error on the [node].
  ///
  /// See [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF].
  void _checkForTypeAliasCannotReferenceItself(
    SimpleIdentifier nameNode,
    TypeAliasElementImpl element,
  ) {
    if (element.hasSelfReference) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
        nameNode,
      );
    }
  }

  /// Verify that the [type] is not a deferred type.
  ///
  /// See [CompileTimeErrorCode.TYPE_ANNOTATION_DEFERRED_CLASS].
  void _checkForTypeAnnotationDeferredClass(TypeAnnotation? type) {
    if (type is NamedType && type.isDeferred) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.TYPE_ANNOTATION_DEFERRED_CLASS,
          type,
          [type.name.toSource()]);
    }
  }

  /// Check that none of the type [parameters] references itself in its bound.
  ///
  /// See [CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND].
  void _checkForTypeParameterBoundRecursion(List<TypeParameter> parameters) {
    Map<TypeParameterElement, TypeParameter>? elementToNode;
    for (var parameter in parameters) {
      if (parameter.bound != null) {
        if (elementToNode == null) {
          elementToNode = {};
          for (var parameter in parameters) {
            elementToNode[parameter.declaredElement!] = parameter;
          }
        }

        TypeParameter? current = parameter;
        for (var step = 0; current != null; step++) {
          var bound = current.bound;
          if (bound is NamedType) {
            current = elementToNode[bound.name.staticElement];
          } else {
            current = null;
          }
          if (step == parameters.length) {
            var element = parameter.declaredElement!;
            // This error can only occur if there is a bound, so we can saefly
            // assume `element.bound` is non-`null`.
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND,
              parameter.name,
              [element.displayName, element.bound!],
            );
            break;
          }
        }
      }
    }
  }

  void _checkForTypeParameterReferencedByStatic(SimpleIdentifier identifier) {
    if (_enclosingExecutable.inStaticMethod || _isInStaticVariableDeclaration) {
      var element = identifier.staticElement;
      if (element is TypeParameterElement &&
          element.enclosingElement is ClassElement) {
        // The class's type parameters are not in scope for static methods.
        // However all other type parameters are legal (e.g. the static method's
        // type parameters, or a local function's type parameters).
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC,
            identifier);
      }
    }
  }

  /// Check that if the given generative [constructor] has neither an explicit
  /// super constructor invocation nor a redirecting constructor invocation,
  /// that the superclass has a default generative constructor.
  ///
  /// See [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT],
  /// [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR], and
  /// [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT].
  void _checkForUndefinedConstructorInInitializerImplicit(
      ConstructorDeclaration constructor) {
    if (_enclosingClass == null) {
      return;
    }

    // Ignore if the constructor is not generative.
    if (constructor.factoryKeyword != null) {
      return;
    }

    // Ignore if the constructor is external. See
    // https://github.com/dart-lang/language/issues/869.
    if (constructor.externalKeyword != null) {
      return;
    }

    // Ignore if the constructor has either an implicit super constructor
    // invocation or a redirecting constructor invocation.
    for (ConstructorInitializer constructorInitializer
        in constructor.initializers) {
      if (constructorInitializer is SuperConstructorInvocation ||
          constructorInitializer is RedirectingConstructorInvocation) {
        return;
      }
    }

    // Check to see whether the superclass has a non-factory unnamed
    // constructor.
    var superType = _enclosingClass!.supertype;
    if (superType == null) {
      return;
    }
    ClassElement superElement = superType.element;
    if (superElement.constructors
        .every((constructor) => constructor.isFactory)) {
      // Already reported [NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS].
      return;
    }
    var superUnnamedConstructor = superElement.unnamedConstructor;
    superUnnamedConstructor = superUnnamedConstructor != null
        ? _currentLibrary.toLegacyElementIfOptOut(superUnnamedConstructor)
        : superUnnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR,
            constructor.returnType,
            [superUnnamedConstructor]);
      } else if (!superUnnamedConstructor.isDefaultConstructor) {
        Identifier returnType = constructor.returnType;
        var name = constructor.name;
        int offset = returnType.offset;
        int length = (name != null ? name.end : returnType.end) - offset;
        errorReporter.reportErrorForOffset(
            CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT,
            offset,
            length,
            [superType]);
      }
    } else {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          constructor.returnType,
          [superElement.name]);
    }
  }

  void _checkForUnnecessaryNullAware(Expression target, Token operator) {
    if (!_isNonNullableByDefault) {
      return;
    }

    if (target is SuperExpression) {
      return;
    }

    ErrorCode errorCode;
    Token endToken = operator;
    List<Object> arguments = const [];
    if (operator.type == TokenType.QUESTION) {
      errorCode = StaticWarningCode.INVALID_NULL_AWARE_OPERATOR;
      endToken = operator.next!;
      arguments = ['?[', '['];
    } else if (operator.type == TokenType.QUESTION_PERIOD) {
      errorCode = StaticWarningCode.INVALID_NULL_AWARE_OPERATOR;
      arguments = [operator.lexeme, '.'];
    } else if (operator.type == TokenType.QUESTION_PERIOD_PERIOD) {
      errorCode = StaticWarningCode.INVALID_NULL_AWARE_OPERATOR;
      arguments = [operator.lexeme, '..'];
    } else if (operator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION) {
      errorCode = StaticWarningCode.INVALID_NULL_AWARE_OPERATOR;
      arguments = [operator.lexeme, '...'];
    } else if (operator.type == TokenType.BANG) {
      errorCode = StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION;
    } else {
      return;
    }

    /// If the operator is not valid because the target already makes use of a
    /// null aware operator, return the null aware operator from the target.
    Token? previousShortCircuitingOperator(Expression? target) {
      if (target is PropertyAccess) {
        var operator = target.operator;
        var type = operator.type;
        if (type == TokenType.QUESTION_PERIOD) {
          var realTarget = target.realTarget;
          return previousShortCircuitingOperator(realTarget) ?? operator;
        }
      } else if (target is IndexExpression) {
        if (target.question != null) {
          var realTarget = target.realTarget;
          return previousShortCircuitingOperator(realTarget) ?? target.question;
        }
      } else if (target is MethodInvocation) {
        var operator = target.operator;
        var type = operator?.type;
        if (type == TokenType.QUESTION_PERIOD) {
          var realTarget = target.realTarget;
          return previousShortCircuitingOperator(realTarget) ?? operator;
        }
      }
      return null;
    }

    var targetType = target.staticType;
    if (target is ExtensionOverride) {
      var arguments = target.argumentList.arguments;
      if (arguments.length == 1) {
        targetType = arguments[0].typeOrThrow;
      } else {
        return;
      }
    } else if (targetType == null) {
      return;
    }

    if (typeSystem.isStrictlyNonNullable(targetType)) {
      if (errorCode == StaticWarningCode.INVALID_NULL_AWARE_OPERATOR) {
        var previousOperator = previousShortCircuitingOperator(target);
        if (previousOperator != null) {
          errorReporter.reportError(DiagnosticFactory()
              .invalidNullAwareAfterShortCircuit(
                  errorReporter.source,
                  operator.offset,
                  endToken.end - operator.offset,
                  arguments,
                  previousOperator));
          return;
        }
      }
      errorReporter.reportErrorForOffset(
        errorCode,
        operator.offset,
        endToken.end - operator.offset,
        arguments,
      );
    }
  }

  /// Check that if the given [name] is a reference to a static member it is
  /// defined in the enclosing class rather than in a superclass.
  ///
  /// See
  /// [CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER].
  void _checkForUnqualifiedReferenceToNonLocalStaticMember(
      SimpleIdentifier name) {
    var element = name.writeOrReadElement;
    if (element == null || element is TypeParameterElement) {
      return;
    }
    var enclosingElement = element.enclosingElement;
    if (identical(enclosingElement, _enclosingClass)) {
      return;
    }
    if (identical(enclosingElement, _enclosingEnum)) {
      return;
    }
    if (enclosingElement is! ClassElement) {
      return;
    }
    if (element is ExecutableElement && !element.isStatic) {
      return;
    }
    if (element is MethodElement) {
      // Invalid methods are reported in
      // [MethodInvocationResolver._resolveReceiverNull].
      return;
    }
    if (_enclosingExtension != null) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode
              .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
          name,
          [enclosingElement.displayName]);
    } else {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          name,
          [enclosingElement.displayName]);
    }
  }

  void _checkForValidField(FieldFormalParameter parameter) {
    var parent2 = parameter.parent?.parent;
    if (parent2 is! ConstructorDeclaration &&
        parent2?.parent is! ConstructorDeclaration) {
      return;
    }
    ParameterElement element = parameter.declaredElement!;
    if (element is FieldFormalParameterElement) {
      var fieldElement = element.field;
      if (fieldElement == null || fieldElement.isSynthetic) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
            parameter,
            [parameter.identifier.name]);
      } else {
        var parameterElement = parameter.declaredElement!;
        if (parameterElement is FieldFormalParameterElementImpl) {
          DartType declaredType = parameterElement.type;
          DartType fieldType = fieldElement.type;
          if (fieldElement.isSynthetic) {
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
                parameter,
                [parameter.identifier.name]);
          } else if (fieldElement.isStatic) {
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD,
                parameter,
                [parameter.identifier.name]);
          } else if (!typeSystem.isSubtypeOf(declaredType, fieldType)) {
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE,
                parameter,
                [declaredType, fieldType]);
          }
        } else {
          if (fieldElement.isSynthetic) {
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
                parameter,
                [parameter.identifier.name]);
          } else if (fieldElement.isStatic) {
            errorReporter.reportErrorForNode(
                CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD,
                parameter,
                [parameter.identifier.name]);
          }
        }
      }
    }
//        else {
//        // TODO(jwren) Report error, constructor initializer variable is a top level element
//        // (Either here or in ErrorVerifier.checkForAllFinalInitializedErrorCodes)
//        }
  }

  /// Verify the given operator-method [declaration], has correct number of
  /// parameters.
  ///
  /// This method assumes that the method declaration was tested to be an
  /// operator declaration before being called.
  ///
  /// See [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR].
  bool _checkForWrongNumberOfParametersForOperator(
      MethodDeclaration declaration) {
    // prepare number of parameters
    var parameterList = declaration.parameters;
    if (parameterList == null) {
      return false;
    }
    int numParameters = parameterList.parameters.length;
    // prepare operator name
    SimpleIdentifier nameNode = declaration.name;
    String name = nameNode.name;
    // check for exact number of parameters
    int expected = -1;
    if ("[]=" == name) {
      expected = 2;
    } else if ("<" == name ||
        ">" == name ||
        "<=" == name ||
        ">=" == name ||
        "==" == name ||
        "+" == name ||
        "/" == name ||
        "~/" == name ||
        "*" == name ||
        "%" == name ||
        "|" == name ||
        "^" == name ||
        "&" == name ||
        "<<" == name ||
        ">>" == name ||
        ">>>" == name ||
        "[]" == name) {
      expected = 1;
    } else if ("~" == name) {
      expected = 0;
    }
    if (expected != -1 && numParameters != expected) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR,
          nameNode,
          [name, expected, numParameters]);
      return true;
    } else if ("-" == name && numParameters > 1) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS,
          nameNode,
          [numParameters]);
      return true;
    }
    return false;
  }

  /// Verify that the given setter [parameterList] has only one required
  /// parameter. The [setterName] is the name of the setter to report problems
  /// on.
  ///
  /// This method assumes that the method declaration was tested to be a setter
  /// before being called.
  ///
  /// See [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER].
  void _checkForWrongNumberOfParametersForSetter(
      SimpleIdentifier setterName, FormalParameterList? parameterList) {
    if (parameterList == null) {
      return;
    }

    NodeList<FormalParameter> parameters = parameterList.parameters;
    if (parameters.length != 1 || !parameters[0].isRequiredPositional) {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
          setterName);
    }
  }

  void _checkForWrongTypeParameterVarianceInField(FieldDeclaration node) {
    if (_enclosingClass != null) {
      for (var typeParameter in _enclosingClass!.typeParameters) {
        // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
        // variance is added to the interface.
        if (!(typeParameter as TypeParameterElementImpl).isLegacyCovariant) {
          var fields = node.fields;
          var fieldElement = fields.variables.first.declaredElement!;
          var fieldName = fields.variables.first.name;
          Variance fieldVariance = Variance(typeParameter, fieldElement.type);

          _checkForWrongVariancePosition(
              fieldVariance, typeParameter, fieldName);
          if (!fields.isFinal && node.covariantKeyword == null) {
            _checkForWrongVariancePosition(
                Variance.contravariant.combine(fieldVariance),
                typeParameter,
                fieldName);
          }
        }
      }
    }
  }

  void _checkForWrongTypeParameterVarianceInMethod(MethodDeclaration method) {
    // Only need to report errors for parameters with explicitly defined type
    // parameters in classes or mixins.
    if (_enclosingClass == null) {
      return;
    }

    for (var typeParameter in _enclosingClass!.typeParameters) {
      // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
      // variance is added to the interface.
      if ((typeParameter as TypeParameterElementImpl).isLegacyCovariant) {
        continue;
      }

      var methodTypeParameters = method.typeParameters?.typeParameters;
      if (methodTypeParameters != null) {
        for (var methodTypeParameter in methodTypeParameters) {
          if (methodTypeParameter.bound == null) {
            continue;
          }
          var methodTypeParameterVariance = Variance.invariant.combine(
            Variance(typeParameter, methodTypeParameter.bound!.typeOrThrow),
          );
          _checkForWrongVariancePosition(
              methodTypeParameterVariance, typeParameter, methodTypeParameter);
        }
      }

      var methodParameters = method.parameters?.parameters;
      if (methodParameters != null) {
        for (var methodParameter in methodParameters) {
          var methodParameterElement = methodParameter.declaredElement!;
          if (methodParameterElement.isCovariant) {
            continue;
          }
          var methodParameterVariance = Variance.contravariant.combine(
            Variance(typeParameter, methodParameterElement.type),
          );
          _checkForWrongVariancePosition(
              methodParameterVariance, typeParameter, methodParameter);
        }
      }

      var returnType = method.returnType;
      if (returnType != null) {
        var methodReturnTypeVariance =
            Variance(typeParameter, returnType.typeOrThrow);
        _checkForWrongVariancePosition(
            methodReturnTypeVariance, typeParameter, returnType);
      }
    }
  }

  void _checkForWrongTypeParameterVarianceInSuperinterfaces() {
    void checkOne(DartType? superInterface) {
      if (superInterface != null) {
        for (var typeParameter in _enclosingClass!.typeParameters) {
          var superVariance = Variance(typeParameter, superInterface);
          // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
          // variance is added to the interface.
          var typeParameterElementImpl =
              typeParameter as TypeParameterElementImpl;
          // Let `D` be a class or mixin declaration, let `S` be a direct
          // superinterface of `D`, and let `X` be a type parameter declared by
          // `D`.
          // If `X` is an `out` type parameter, it can only occur in `S` in an
          // covariant or unrelated position.
          // If `X` is an `in` type parameter, it can only occur in `S` in an
          // contravariant or unrelated position.
          // If `X` is an `inout` type parameter, it can occur in `S` in any
          // position.
          if (!superVariance
              .greaterThanOrEqual(typeParameterElementImpl.variance)) {
            if (!typeParameterElementImpl.isLegacyCovariant) {
              errorReporter.reportErrorForElement(
                CompileTimeErrorCode
                    .WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
                typeParameter,
                [
                  typeParameter.name,
                  typeParameterElementImpl.variance.toKeywordString(),
                  superVariance.toKeywordString(),
                  superInterface
                ],
              );
            } else {
              errorReporter.reportErrorForElement(
                CompileTimeErrorCode
                    .WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
                typeParameter,
                [typeParameter.name, superInterface],
              );
            }
          }
        }
      }
    }

    checkOne(_enclosingClass!.supertype);
    _enclosingClass!.interfaces.forEach(checkOne);
    _enclosingClass!.mixins.forEach(checkOne);
    _enclosingClass!.superclassConstraints.forEach(checkOne);
  }

  /// Check for invalid variance positions in members of a class or mixin.
  ///
  /// Let `C` be a class or mixin declaration with type parameter `T`.
  /// If `T` is an `out` type parameter then `T` can only appear in covariant
  /// positions within the accessors and methods of `C`.
  /// If `T` is an `in` type parameter then `T` can only appear in contravariant
  /// positions within the accessors and methods of `C`.
  /// If `T` is an `inout` type parameter or a type parameter with no explicit
  /// variance modifier then `T` can appear in any variant position within the
  /// accessors and methods of `C`.
  ///
  /// Errors should only be reported in classes and mixins since those are the
  /// only components that allow explicit variance modifiers.
  void _checkForWrongVariancePosition(
      Variance variance, TypeParameterElement typeParameter, AstNode node) {
    TypeParameterElementImpl typeParameterImpl =
        typeParameter as TypeParameterElementImpl;
    if (!variance.greaterThanOrEqual(typeParameterImpl.variance)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_POSITION,
        node,
        [
          typeParameterImpl.variance.toKeywordString(),
          typeParameterImpl.name,
          variance.toKeywordString()
        ],
      );
    }
  }

  /// Verify that the current class does not have the same class in the
  /// 'extends' and 'implements' clauses.
  ///
  /// See [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS].
  void _checkImplementsSuperClass(ImplementsClause? implementsClause) {
    if (implementsClause == null) {
      return;
    }

    var superElement = _enclosingClass!.supertype?.element;
    if (superElement == null) {
      return;
    }

    for (var interfaceNode in implementsClause.interfaces2) {
      var type = interfaceNode.type;
      if (type is InterfaceType && type.element == superElement) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS,
          interfaceNode,
          [superElement],
        );
      }
    }
  }

  void _checkMixinInference(
      NamedCompilationUnitMember node, WithClause? withClause) {
    if (withClause == null) {
      return;
    }
    var classElement = node.declaredElement as ClassElement;
    var supertype = classElement.supertype;

    var interfacesMerger = InterfacesMerger(typeSystem);
    interfacesMerger.addWithSupertypes(supertype);

    for (var namedType in withClause.mixinTypes2) {
      var mixinType = namedType.type;
      if (mixinType is InterfaceType) {
        var mixinElement = mixinType.element;
        if (namedType.typeArguments == null) {
          var mixinSupertypeConstraints = typeSystem
              .gatherMixinSupertypeConstraintsForInference(mixinElement);
          if (mixinSupertypeConstraints.isNotEmpty) {
            var matchingInterfaceTypes = _findInterfaceTypesForConstraints(
              namedType,
              mixinSupertypeConstraints,
              interfacesMerger.typeList,
            );
            if (matchingInterfaceTypes != null) {
              // Try to pattern match matchingInterfaceType against
              // mixinSupertypeConstraint to find the correct set of type
              // parameters to apply to the mixin.
              var inferredTypeArguments = typeSystem.matchSupertypeConstraints(
                mixinElement,
                mixinSupertypeConstraints,
                matchingInterfaceTypes,
                genericMetadataIsEnabled: _currentLibrary.featureSet
                    .isEnabled(Feature.generic_metadata),
              );
              if (inferredTypeArguments == null) {
                errorReporter.reportErrorForToken(
                    CompileTimeErrorCode
                        .MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION,
                    namedType.name.beginToken,
                    [namedType]);
              }
            }
          }
        }
        interfacesMerger.addWithSupertypes(mixinType);
      }
    }
  }

  /// Checks the class for problems with the superclass, mixins, or implemented
  /// interfaces.
  void _checkMixinInheritance(MixinDeclaration node, OnClause? onClause,
      ImplementsClause? implementsClause) {
    // Only check for all of the inheritance logic around clauses if there
    // isn't an error code such as "Cannot implement double" already.
    if (!_checkForOnClauseErrorCodes(onClause) &&
        !_checkForImplementsClauseErrorCodes(implementsClause)) {
//      _checkForImplicitDynamicType(superclass);
      _checkForRepeatedType(
        onClause?.superclassConstraints2,
        CompileTimeErrorCode.ON_REPEATED,
      );
      _checkForRepeatedType(
        implementsClause?.interfaces2,
        CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      );
      _checkForConflictingGenerics(node);
    }
  }

  /// Verify that the current class does not have the same class in the
  /// 'extends' and 'with' clauses.
  ///
  /// See [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS].
  void _checkMixinsSuperClass(WithClause? withClause) {
    if (withClause == null) {
      return;
    }

    var superElement = _enclosingClass!.supertype?.element;
    if (superElement == null) {
      return;
    }

    for (var mixinNode in withClause.mixinTypes2) {
      var type = mixinNode.type;
      if (type is InterfaceType && type.element == superElement) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.MIXINS_SUPER_CLASS,
          mixinNode,
          [superElement],
        );
      }
    }
  }

  void _checkUseOfCovariantInParameters(FormalParameterList node) {
    var parent = node.parent;
    if (_enclosingClass != null && parent is MethodDeclaration) {
      // Either [parent] is a static method, in which case `EXTRANEOUS_MODIFIER`
      // is reported by the parser, or [parent] is an instance method, in which
      // case any use of `covariant` is legal.
      return;
    }

    if (_enclosingExtension != null) {
      // `INVALID_USE_OF_COVARIANT_IN_EXTENSION` is reported by the parser.
      return;
    }

    if (parent is FunctionExpression) {
      var parent2 = parent.parent;
      if (parent2 is FunctionDeclaration && parent2.parent is CompilationUnit) {
        // `EXTRANEOUS_MODIFIER` is reported by the parser, for library-level
        // functions.
        return;
      }
    }

    NodeList<FormalParameter> parameters = node.parameters;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      FormalParameter parameter = parameters[i];
      if (parameter is DefaultFormalParameter) {
        parameter = parameter.parameter;
      }
      var keyword = parameter.covariantKeyword;
      if (keyword != null) {
        errorReporter.reportErrorForToken(
          CompileTimeErrorCode.INVALID_USE_OF_COVARIANT,
          keyword,
        );
      }
    }
  }

  void _checkUseOfDefaultValuesInParameters(FormalParameterList node) {
    if (!_isNonNullableByDefault) return;

    var defaultValuesAreExpected = () {
      var parent = node.parent;
      if (parent is ConstructorDeclaration) {
        if (parent.externalKeyword != null) {
          return false;
        } else if (parent.factoryKeyword != null &&
            parent.redirectedConstructor != null) {
          return false;
        }
        return true;
      } else if (parent is FunctionExpression) {
        var parent2 = parent.parent;
        if (parent2 is FunctionDeclaration && parent2.externalKeyword != null) {
          return false;
        } else if (parent.body is NativeFunctionBody) {
          return false;
        }
        return true;
      } else if (parent is MethodDeclaration) {
        if (parent.isAbstract) {
          return false;
        } else if (parent.externalKeyword != null) {
          return false;
        } else if (parent.body is NativeFunctionBody) {
          return false;
        }
        return true;
      }
      return false;
    }();

    for (var parameter in node.parameters) {
      if (parameter is DefaultFormalParameter) {
        if (parameter.isRequiredNamed) {
          if (parameter.defaultValue != null) {
            var parameterName = _parameterName(parameter);
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER,
              parameterName ?? parameter,
            );
          }
        } else if (defaultValuesAreExpected && parameter.defaultValue == null) {
          var type = parameter.declaredElement!.type;
          if (typeSystem.isPotentiallyNonNullable(type)) {
            var parameterName = _parameterName(parameter);
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER,
              parameterName ?? parameter,
              [parameterName?.name ?? '?'],
            );
          }
        }
      }
    }
  }

  InterfaceType? _findInterfaceTypeForMixin(NamedType mixin,
      InterfaceType supertypeConstraint, List<InterfaceType> interfaceTypes) {
    var element = supertypeConstraint.element;
    InterfaceType? foundInterfaceType;
    for (var interfaceType in interfaceTypes) {
      if (interfaceType.element != element) continue;
      if (foundInterfaceType == null) {
        foundInterfaceType = interfaceType;
      } else {
        if (interfaceType != foundInterfaceType) {
          errorReporter.reportErrorForToken(
              CompileTimeErrorCode
                  .MIXIN_INFERENCE_INCONSISTENT_MATCHING_CLASSES,
              mixin.name.beginToken,
              [mixin, supertypeConstraint]);
        }
      }
    }
    if (foundInterfaceType == null) {
      errorReporter.reportErrorForToken(
          CompileTimeErrorCode.MIXIN_INFERENCE_NO_MATCHING_CLASS,
          mixin.name.beginToken,
          [mixin, supertypeConstraint]);
    }
    return foundInterfaceType;
  }

  List<InterfaceType>? _findInterfaceTypesForConstraints(
      NamedType mixin,
      List<InterfaceType> supertypeConstraints,
      List<InterfaceType> interfaceTypes) {
    var result = <InterfaceType>[];
    for (var constraint in supertypeConstraints) {
      var interfaceType =
          _findInterfaceTypeForMixin(mixin, constraint, interfaceTypes);
      if (interfaceType == null) {
        // No matching interface type found, so inference fails.  The error has
        // already been reported.
        return null;
      }
      result.add(interfaceType);
    }
    return result;
  }

  /// Given an [expression] in a switch case whose value is expected to be an
  /// enum constant, return the name of the constant.
  String? _getConstantName(Expression expression) {
    // TODO(brianwilkerson) Convert this to return the element representing the
    // constant.
    if (expression is SimpleIdentifier) {
      return expression.name;
    } else if (expression is PrefixedIdentifier) {
      return expression.identifier.name;
    } else if (expression is PropertyAccess) {
      return expression.propertyName.name;
    }
    return null;
  }

  /// Return the name of the library that defines given [element].
  String _getLibraryName(Element? element) {
    if (element == null) {
      return StringUtilities.EMPTY;
    }
    var library = element.library;
    if (library == null) {
      return StringUtilities.EMPTY;
    }
    List<ImportElement> imports = _currentLibrary.imports;
    int count = imports.length;
    for (int i = 0; i < count; i++) {
      if (identical(imports[i].importedLibrary, library)) {
        return library.definingCompilationUnit.source.uri.toString();
      }
    }
    List<String> indirectSources = <String>[];
    for (int i = 0; i < count; i++) {
      var importedLibrary = imports[i].importedLibrary;
      if (importedLibrary != null) {
        for (LibraryElement exportedLibrary
            in importedLibrary.exportedLibraries) {
          if (identical(exportedLibrary, library)) {
            indirectSources.add(
                importedLibrary.definingCompilationUnit.source.uri.toString());
          }
        }
      }
    }
    int indirectCount = indirectSources.length;
    StringBuffer buffer = StringBuffer();
    buffer.write(library.definingCompilationUnit.source.uri.toString());
    if (indirectCount > 0) {
      buffer.write(" (via ");
      if (indirectCount > 1) {
        indirectSources.sort();
        buffer.write(StringUtilities.printListOfQuotedNames(indirectSources));
      } else {
        buffer.write(indirectSources[0]);
      }
      buffer.write(")");
    }
    return buffer.toString();
  }

  /// Return `true` if the given [constructor] redirects to itself, directly or
  /// indirectly.
  bool _hasRedirectingFactoryConstructorCycle(ConstructorElement constructor) {
    Set<ConstructorElement> constructors = HashSet<ConstructorElement>();
    ConstructorElement? current = constructor;
    while (current != null) {
      if (constructors.contains(current)) {
        return identical(current, constructor);
      }
      constructors.add(current);
      current = current.redirectedConstructor?.declaration;
    }
    return false;
  }

  /// Return `true` if the given [identifier] is in a location where it is
  /// allowed to resolve to a static member of a supertype.
  bool _isUnqualifiedReferenceToNonLocalStaticMemberAllowed(
      SimpleIdentifier identifier) {
    if (identifier.inDeclarationContext()) {
      return true;
    }
    var parent = identifier.parent;
    if (parent is Annotation) {
      return identical(parent.constructorName, identifier);
    }
    if (parent is CommentReference) {
      return true;
    }
    if (parent is ConstructorName) {
      return identical(parent.name, identifier);
    }
    if (parent is MethodInvocation) {
      return identical(parent.methodName, identifier);
    }
    if (parent is PrefixedIdentifier) {
      return identical(parent.identifier, identifier);
    }
    if (parent is PropertyAccess) {
      return identical(parent.propertyName, identifier);
    }
    if (parent is SuperConstructorInvocation) {
      return identical(parent.constructorName, identifier);
    }
    return false;
  }

  /// Return the name of the [parameter], or `null` if the parameter does not
  /// have a name.
  SimpleIdentifier? _parameterName(FormalParameter parameter) {
    if (parameter is NormalFormalParameter) {
      return parameter.identifier;
    } else if (parameter is DefaultFormalParameter) {
      return parameter.parameter.identifier;
    }
    return null;
  }

  void _withEnclosingExecutable(
    ExecutableElement element,
    void Function() operation,
  ) {
    var current = _enclosingExecutable;
    try {
      _enclosingExecutable = EnclosingExecutableContext(element);
      _returnTypeVerifier.enclosingExecutable = _enclosingExecutable;
      operation();
    } finally {
      _enclosingExecutable = current;
      _returnTypeVerifier.enclosingExecutable = _enclosingExecutable;
    }
  }

  void _withHiddenElements(List<Statement> statements, void Function() f) {
    _hiddenElements = HiddenElements(_hiddenElements, statements);
    try {
      f();
    } finally {
      _hiddenElements = _hiddenElements!.outerElements;
    }
  }

  /// Return [FieldElement]s that are declared in the [ClassDeclaration] with
  /// the given [constructor], but are not initialized.
  static List<FieldElement> computeNotInitializedFields(
      ConstructorDeclaration constructor) {
    Set<FieldElement> fields = <FieldElement>{};
    var classDeclaration = constructor.parent as ClassDeclaration;
    for (ClassMember fieldDeclaration in classDeclaration.members) {
      if (fieldDeclaration is FieldDeclaration) {
        for (VariableDeclaration field in fieldDeclaration.fields.variables) {
          if (field.initializer == null) {
            fields.add(field.declaredElement as FieldElement);
          }
        }
      }
    }

    List<FormalParameter> parameters = constructor.parameters.parameters;
    for (FormalParameter parameter in parameters) {
      if (parameter is DefaultFormalParameter) {
        parameter = parameter.parameter;
      }
      if (parameter is FieldFormalParameter) {
        FieldFormalParameterElement element =
            parameter.identifier.staticElement as FieldFormalParameterElement;
        fields.remove(element.field);
      }
    }

    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is ConstructorFieldInitializer) {
        fields.remove(initializer.fieldName.staticElement);
      }
    }

    return fields.toList();
  }
}

/// A record of the elements that will be declared in some scope (block), but
/// are not yet declared.
class HiddenElements {
  /// The elements hidden in outer scopes, or `null` if this is the outermost
  /// scope.
  final HiddenElements? outerElements;

  /// A set containing the elements that will be declared in this scope, but are
  /// not yet declared.
  final Set<Element> _elements = HashSet<Element>();

  /// Initialize a newly created set of hidden elements to include all of the
  /// elements defined in the set of [outerElements] and all of the elements
  /// declared in the given [statements].
  HiddenElements(this.outerElements, List<Statement> statements) {
    _initializeElements(statements);
  }

  /// Return `true` if this set of elements contains the given [element].
  bool contains(Element element) {
    if (_elements.contains(element)) {
      return true;
    } else if (outerElements != null) {
      return outerElements!.contains(element);
    }
    return false;
  }

  /// Record that the given [element] has been declared, so it is no longer
  /// hidden.
  void declare(Element element) {
    _elements.remove(element);
  }

  /// Initialize the list of elements that are not yet declared to be all of the
  /// elements declared somewhere in the given [statements].
  void _initializeElements(List<Statement> statements) {
    _elements.addAll(BlockScope.elementsInStatements(statements));
  }
}

/// Recursively visits a type annotation, looking uninstantiated bounds.
class _UninstantiatedBoundChecker extends RecursiveAstVisitor<void> {
  final ErrorReporter _errorReporter;

  _UninstantiatedBoundChecker(this._errorReporter);

  @override
  void visitNamedType(NamedType node) {
    var typeArgs = node.typeArguments;
    if (typeArgs != null) {
      typeArgs.accept(this);
      return;
    }

    var element = node.name.staticElement;
    if (element is TypeParameterizedElement && !element.isSimplyBounded) {
      // TODO(srawlins): Don't report this if TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
      //  has been reported.
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, node, []);
    }
  }
}
