// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart' show ExecutableMember;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/exit_detector.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/deprecated_member_use_verifier.dart';
import 'package:analyzer/src/error/error_handler_verifier.dart';
import 'package:analyzer/src/error/must_call_super_verifier.dart';
import 'package:analyzer/src/error/null_safe_api_verifier.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// Instances of the class `BestPracticesVerifier` traverse an AST structure
/// looking for violations of Dart best practices.
class BestPracticesVerifier extends RecursiveAstVisitor<void> {
  static const String toIntMethodName = "toInt";

  /// The class containing the AST nodes being visited, or `null` if we are not
  /// in the scope of a class.
  ClassElementImpl? _enclosingClass;

  /// A flag indicating whether a surrounding member is annotated as
  /// `@doNotStore`.
  bool _inDoNotStoreMember = false;

  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// The type [Null].
  final InterfaceType _nullType;

  /// The type system primitives
  final TypeSystemImpl _typeSystem;

  /// The inheritance manager to access interface type hierarchy.
  final InheritanceManager3 _inheritanceManager;

  /// The current library
  final LibraryElement _currentLibrary;

  final _InvalidAccessVerifier _invalidAccessVerifier;

  final DeprecatedMemberUseVerifier _deprecatedVerifier;

  final MustCallSuperVerifier _mustCallSuperVerifier;

  final ErrorHandlerVerifier _errorHandlerVerifier;

  final NullSafeApiVerifier _nullSafeApiVerifier;

  /// The [WorkspacePackage] in which [_currentLibrary] is declared.
  final WorkspacePackage? _workspacePackage;

  /// The [LinterContext] used for possible const calculations.
  final LinterContext _linterContext;

  /// Is `true` if the library being analyzed is non-nullable by default.
  final bool _isNonNullableByDefault;

  /// True if inference failures should be reported, otherwise false.
  final bool _strictInference;

  /// Whether [_currentLibrary] is part of its containing package's public API.
  late final bool _inPublicPackageApi = _workspacePackage != null &&
      _workspacePackage!.sourceIsInPublicApi(_currentLibrary.source);

  BestPracticesVerifier(
    this._errorReporter,
    TypeProviderImpl typeProvider,
    this._currentLibrary,
    CompilationUnit unit,
    String content, {
    required TypeSystemImpl typeSystem,
    required InheritanceManager3 inheritanceManager,
    required DeclaredVariables declaredVariables,
    required AnalysisOptions analysisOptions,
    required WorkspacePackage? workspacePackage,
  })  : _nullType = typeProvider.nullType,
        _typeSystem = typeSystem,
        _isNonNullableByDefault = typeSystem.isNonNullableByDefault,
        _strictInference =
            (analysisOptions as AnalysisOptionsImpl).strictInference,
        _inheritanceManager = inheritanceManager,
        _invalidAccessVerifier = _InvalidAccessVerifier(
            _errorReporter, _currentLibrary, workspacePackage),
        _deprecatedVerifier =
            DeprecatedMemberUseVerifier(workspacePackage, _errorReporter),
        _mustCallSuperVerifier = MustCallSuperVerifier(_errorReporter),
        _errorHandlerVerifier =
            ErrorHandlerVerifier(_errorReporter, typeProvider, typeSystem),
        _nullSafeApiVerifier = NullSafeApiVerifier(_errorReporter, typeSystem),
        _workspacePackage = workspacePackage,
        _linterContext = LinterContextImpl(
          [],
          LinterContextUnit(content, unit),
          declaredVariables,
          typeProvider,
          typeSystem,
          inheritanceManager,
          analysisOptions,
          workspacePackage,
        ) {
    _deprecatedVerifier.pushInDeprecatedValue(_currentLibrary.hasDeprecated);
    _inDoNotStoreMember = _currentLibrary.hasDoNotStore;
    _invalidAccessVerifier._inTestDirectory = _linterContext.inTestDir(unit);
  }

  @override
  void visitAnnotation(Annotation node) {
    var element = node.elementAnnotation;
    if (element == null) {
      return;
    }
    AstNode parent = node.parent;
    if (element.isFactory == true) {
      if (parent is MethodDeclaration) {
        _checkForInvalidFactory(parent);
      } else {
        _errorReporter
            .reportErrorForNode(HintCode.INVALID_FACTORY_ANNOTATION, node, []);
      }
    } else if (element.isImmutable == true) {
      if (parent is! ClassOrMixinDeclaration && parent is! ClassTypeAlias) {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_IMMUTABLE_ANNOTATION, node, []);
      }
    } else if (element.isInternal) {
      var parentElement = parent is Declaration ? parent.declaredElement : null;
      if (parent is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in parent.variables.variables) {
          var element = variable.declaredElement as TopLevelVariableElement;
          if (Identifier.isPrivateName(element.name)) {
            _errorReporter.reportErrorForNode(
                HintCode.INVALID_INTERNAL_ANNOTATION, variable, []);
          }
        }
      } else if (parent is FieldDeclaration) {
        for (VariableDeclaration variable in parent.fields.variables) {
          var element = variable.declaredElement as FieldElement;
          if (Identifier.isPrivateName(element.name)) {
            _errorReporter.reportErrorForNode(
                HintCode.INVALID_INTERNAL_ANNOTATION, variable, []);
          }
        }
      } else if (parent is ConstructorDeclaration) {
        var class_ = parent.declaredElement!.enclosingElement;
        if (class_.isPrivate || (parentElement?.isPrivate ?? false)) {
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_INTERNAL_ANNOTATION, node, []);
        }
      } else if (parentElement?.isPrivate ?? false) {
        _errorReporter
            .reportErrorForNode(HintCode.INVALID_INTERNAL_ANNOTATION, node, []);
      } else if (_inPublicPackageApi) {
        _errorReporter
            .reportErrorForNode(HintCode.INVALID_INTERNAL_ANNOTATION, node, []);
      }
    } else if (element.isLiteral == true) {
      if (parent is! ConstructorDeclaration || parent.constKeyword == null) {
        _errorReporter
            .reportErrorForNode(HintCode.INVALID_LITERAL_ANNOTATION, node, []);
      }
    } else if (element.isNonVirtual == true) {
      if (parent is FieldDeclaration) {
        if (parent.isStatic) {
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_NON_VIRTUAL_ANNOTATION, node);
        }
      } else if (parent is MethodDeclaration) {
        if (parent.parent is ExtensionDeclaration ||
            parent.isStatic ||
            parent.isAbstract) {
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_NON_VIRTUAL_ANNOTATION, node);
        }
      } else {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_NON_VIRTUAL_ANNOTATION, node);
      }
    } else if (element.isSealed == true) {
      if (!(parent is ClassDeclaration || parent is ClassTypeAlias)) {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_SEALED_ANNOTATION, node);
      }
    } else if (element.isVisibleForTemplate == true ||
        element.isVisibleForTesting == true ||
        element.isVisibleForOverriding == true) {
      if (parent is Declaration) {
        void reportInvalidAnnotation(Element declaredElement) {
          // This method is only called on named elements, so it is safe to
          // assume that `declaredElement.name` is non-`null`.
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_VISIBILITY_ANNOTATION,
              node,
              [declaredElement.name!, node.name.name]);
        }

        void reportInvalidVisibleForOverriding(Element declaredElement) {
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION, node);
        }

        if (parent is TopLevelVariableDeclaration) {
          for (VariableDeclaration variable in parent.variables.variables) {
            var variableElement =
                variable.declaredElement as TopLevelVariableElement;

            if (Identifier.isPrivateName(variableElement.name)) {
              reportInvalidAnnotation(variableElement);
            }

            if (element.isVisibleForOverriding == true) {
              // Top-level variables can't be overridden.
              reportInvalidVisibleForOverriding(variableElement);
            }
          }
        } else if (parent is FieldDeclaration) {
          for (VariableDeclaration variable in parent.fields.variables) {
            var fieldElement = variable.declaredElement as FieldElement;
            if (parent.isStatic && element.isVisibleForOverriding == true) {
              reportInvalidVisibleForOverriding(fieldElement);
            }

            if (Identifier.isPrivateName(fieldElement.name)) {
              reportInvalidAnnotation(fieldElement);
            }
          }
        } else if (parent.declaredElement != null) {
          final declaredElement = parent.declaredElement!;
          if (element.isVisibleForOverriding &&
              !declaredElement.isInstanceMember) {
            reportInvalidVisibleForOverriding(declaredElement);
          }

          var name = declaredElement.name;
          if (name != null && Identifier.isPrivateName(name)) {
            reportInvalidAnnotation(declaredElement);
          }
        }
      } else {
        // Something other than a declaration was annotated. Whatever this is,
        // it probably warrants a Hint, but this has not been specified on
        // visibleForTemplate or visibleForTesting, so leave it alone for now.
      }
    }

    // Check for a reference to an undefined parameter in a `@UseResult.unless`
    // annotation.
    if (element.isUseResult) {
      var undefinedParam = _findUndefinedUseResultParam(element, node, parent);
      if (undefinedParam != null) {
        String? name;
        if (parent is FunctionDeclaration) {
          name = parent.name.name;
        } else if (parent is MethodDeclaration) {
          name = parent.name.name;
        }
        if (name != null) {
          var paramName = undefinedParam is SimpleStringLiteral
              ? undefinedParam.value
              : undefinedParam.staticParameterElement?.name;
          _errorReporter.reportErrorForNode(
              HintCode.UNDEFINED_REFERENCED_PARAMETER,
              undefinedParam,
              [paramName ?? undefinedParam, name]);
        }
      }
    }

    var kinds = element.targetKinds;
    if (kinds.isNotEmpty) {
      if (!_isValidTarget(parent, kinds)) {
        var invokedElement = element.element!;
        var name = invokedElement.name;
        if (invokedElement is ConstructorElement) {
          var className = invokedElement.enclosingElement.name;
          if (name!.isEmpty) {
            name = className;
          } else {
            name = '$className.$name';
          }
        }
        var kindNames = kinds.map((kind) => kind.displayString).toList()
          ..sort();
        var validKinds = kindNames.commaSeparatedWithOr;
        // Annotations always refer to named elements, so we can safely assume
        // that `name` is non-`null`.
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_ANNOTATION_TARGET, node.name, [name!, validKinds]);
        return;
      }
    }

    super.visitAnnotation(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (isUnnecessaryCast(node, _typeSystem)) {
      _errorReporter.reportErrorForNode(HintCode.UNNECESSARY_CAST, node);
    }
    super.visitAsExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _deprecatedVerifier.assignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _checkForDivisionOptimizationHint(node);
    _deprecatedVerifier.binaryExpression(node);
    _checkForInvariantNullComparison(node);
    super.visitBinaryExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    super.visitCatchClause(node);
    _checkForNullableTypeInCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var element = node.declaredElement as ClassElementImpl;
    _enclosingClass = element;
    _invalidAccessVerifier._enclosingClass = element;

    bool wasInDoNotStoreMember = _inDoNotStoreMember;
    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);
    if (element.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }

    try {
      // Commented out until we decide that we want this hint in the analyzer
      //    checkForOverrideEqualsButNotHashCode(node);
      _checkForImmutable(node);
      _checkForInvalidSealedSuperclass(node);
      super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = null;
      _invalidAccessVerifier._enclosingClass = null;
      _deprecatedVerifier.popInDeprecated();
      _inDoNotStoreMember = wasInDoNotStoreMember;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _checkForImmutable(node);
    _checkForInvalidSealedSuperclass(node);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    var newKeyword = node.newKeyword;
    if (newKeyword != null &&
        _currentLibrary.featureSet.isEnabled(Feature.constructor_tearoffs)) {
      _errorReporter.reportErrorForToken(
          HintCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE, newKeyword, []);
    }
    super.visitCommentReference(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var element = node.declaredElement as ConstructorElementImpl;
    if (!_isNonNullableByDefault && element.isFactory) {
      if (node.body is BlockFunctionBody) {
        // Check the block for a return statement, if not, create the hint.
        if (!ExitDetector.exits(node.body)) {
          _errorReporter.reportErrorForNode(
              HintCode.MISSING_RETURN, node, [node.returnType.name]);
        }
      }
    }
    _checkStrictInferenceInParameters(node.parameters,
        body: node.body, initializers: node.initializers);
    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);
    try {
      super.visitConstructorDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _deprecatedVerifier.constructorName(node);
    super.visitConstructorName(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _deprecatedVerifier.exportDirective(node);
    _checkForInternalExport(node);
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (!_invalidAccessVerifier._inTestDirectory) {
      _checkForReturnOfDoNotStore(node.expression);
    }
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedMetadata(node.metadata);

    try {
      super.visitFieldDeclaration(node);
      for (var field in node.fields.variables) {
        ExecutableElement? getOverriddenPropertyAccessor() {
          final element = field.declaredElement;
          if (element is PropertyAccessorElement || element is FieldElement) {
            Name name = Name(_currentLibrary.source.uri, element!.name);
            Element enclosingElement = element.enclosingElement!;
            if (enclosingElement is ClassElement) {
              var overridden = _inheritanceManager
                  .getMember2(enclosingElement, name, forSuper: true);
              // Check for a setter.
              if (overridden == null) {
                Name setterName =
                    Name(_currentLibrary.source.uri, '${element.name}=');
                overridden = _inheritanceManager
                    .getMember2(enclosingElement, setterName, forSuper: true);
              }
              return overridden;
            }
          }
          return null;
        }

        final overriddenElement = getOverriddenPropertyAccessor();
        if (overriddenElement != null &&
            _hasNonVirtualAnnotation(overriddenElement)) {
          // Overridden members are always inside classes or mixins, which are
          // always named, so we can safely assume
          // `overriddenElement.enclosingElement.name` is non-`null`.
          _errorReporter.reportErrorForNode(
              HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER, field.name, [
            field.name.name,
            overriddenElement.enclosingElement.displayName
          ]);
        }
        if (!_invalidAccessVerifier._inTestDirectory) {
          _checkForAssignmentOfDoNotStore(field.initializer);
        }
      }
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _checkRequiredParameter(node);
    super.visitFormalParameterList(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    bool wasInDoNotStoreMember = _inDoNotStoreMember;
    ExecutableElement element = node.declaredElement!;
    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);
    if (element.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }
    try {
      _checkForMissingReturn(node.functionExpression.body, node);

      // Return types are inferred only on non-recursive local functions.
      if (node.parent is CompilationUnit && !node.isSetter) {
        _checkStrictInferenceReturnType(node.returnType, node, node.name.name);
      }
      _checkStrictInferenceInParameters(node.functionExpression.parameters,
          body: node.functionExpression.body);
      super.visitFunctionDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
      _inDoNotStoreMember = wasInDoNotStoreMember;
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    // TODO(srawlins): Check strict-inference return type on recursive
    // local functions.
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      _checkForMissingReturn(node.body, node);
    }
    var functionType = InferenceContext.getContext(node);
    if (functionType is! FunctionType) {
      _checkStrictInferenceInParameters(node.parameters, body: node.body);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _deprecatedVerifier.functionExpressionInvocation(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _checkStrictInferenceReturnType(node.returnType, node, node.name.name);
    _checkStrictInferenceInParameters(node.parameters);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _checkStrictInferenceReturnType(
        node.returnType, node, node.identifier.name);
    _checkStrictInferenceInParameters(node.parameters);
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // GenericTypeAlias is handled in [visitGenericTypeAlias], where a proper
    // name can be reported in any message.
    if (node.parent is! GenericTypeAlias) {
      _checkStrictInferenceReturnType(node.returnType, node, node.toString());
    }
    super.visitGenericFunctionType(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (node.functionType != null) {
      _checkStrictInferenceReturnType(
          node.functionType!.returnType, node, node.name.name);
    }
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _deprecatedVerifier.importDirective(node);
    var importElement = node.element;
    if (importElement != null && importElement.isDeferred) {
      _checkForLoadLibraryFunction(node, importElement);
    }
    _invalidAccessVerifier.verifyImport(node);
    _checkForImportOfLegacyLibraryIntoNullSafe(node);
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _deprecatedVerifier.indexExpression(node);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _deprecatedVerifier.instanceCreationExpression(node);
    _nullSafeApiVerifier.instanceCreation(node);
    _checkForLiteralConstructorUse(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _checkAllTypeChecks(node);
    super.visitIsExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    bool wasInDoNotStoreMember = _inDoNotStoreMember;
    var element = node.declaredElement!;
    var enclosingElement = element.enclosingElement;

    Name name = Name(_currentLibrary.source.uri, element.name);

    ExecutableElement? getConcreteOverriddenElement() =>
        element is ClassMemberElement && enclosingElement is ClassElement
            ? _inheritanceManager.getMember2(enclosingElement, name,
                forSuper: true)
            : null;
    ExecutableElement? getOverriddenPropertyAccessor() =>
        element is PropertyAccessorElement && enclosingElement is ClassElement
            ? _inheritanceManager.getMember2(enclosingElement, name,
                forSuper: true)
            : null;

    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);
    if (element.hasDoNotStore) {
      _inDoNotStoreMember = true;
    }
    try {
      // This was determined to not be a good hint, see: dartbug.com/16029
      //checkForOverridingPrivateMember(node);
      _checkForMissingReturn(node.body, node);
      _mustCallSuperVerifier.checkMethodDeclaration(node);
      _checkForUnnecessaryNoSuchMethod(node);

      var elementIsOverride = element is ClassMemberElement &&
              enclosingElement is ClassElement
          ? _inheritanceManager.getOverridden2(enclosingElement, name) != null
          : false;

      if (!node.isSetter && !elementIsOverride) {
        _checkStrictInferenceReturnType(node.returnType, node, node.name.name);
      }
      if (!elementIsOverride) {
        _checkStrictInferenceInParameters(node.parameters, body: node.body);
      }

      var overriddenElement = getConcreteOverriddenElement();
      if (overriddenElement == null && (node.isSetter || node.isGetter)) {
        overriddenElement = getOverriddenPropertyAccessor();
      }

      if (overriddenElement != null &&
          _hasNonVirtualAnnotation(overriddenElement)) {
        // Overridden members are always inside classes or mixins, which are
        // always named, so we can safely assume
        // `overriddenElement.enclosingElement.name` is non-`null`.
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER,
            node.name,
            [node.name.name, overriddenElement.enclosingElement.displayName]);
      }

      super.visitMethodDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
      _inDoNotStoreMember = wasInDoNotStoreMember;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _deprecatedVerifier.methodInvocation(node);
    _checkForNullAwareHints(node, node.operator);
    _errorHandlerVerifier.verifyMethodInvocation(node);
    _nullSafeApiVerifier.methodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var element = node.declaredElement as ClassElementImpl;
    _enclosingClass = element;
    _invalidAccessVerifier._enclosingClass = _enclosingClass;

    _deprecatedVerifier.pushInDeprecatedValue(element.hasDeprecated);

    try {
      _checkForImmutable(node);
      _checkForInvalidSealedSuperclass(node);
      super.visitMixinDeclaration(node);
    } finally {
      _enclosingClass = null;
      _invalidAccessVerifier._enclosingClass = null;
      _deprecatedVerifier.popInDeprecated();
    }
  }

  @override
  void visitNamedType(NamedType node) {
    var question = node.question;
    if (question != null) {
      var name = node.name.name;
      var type = node.typeOrThrow;
      // Only report non-aliased, non-user-defined `Null?` and `dynamic?`. Do
      // not report synthetic `dynamic` in place of an unresolved type.
      if ((type.element == _nullType.element ||
              (type.isDynamic && name == 'dynamic')) &&
          type.alias == null) {
        _errorReporter.reportErrorForToken(
            HintCode.UNNECESSARY_QUESTION_MARK, question, [name]);
      }
    }
    super.visitNamedType(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _deprecatedVerifier.postfixExpression(node);
    if (node.operator.type == TokenType.BANG &&
        node.operand.typeOrThrow.isDartCoreNull) {
      _errorReporter.reportErrorForNode(HintCode.NULL_CHECK_ALWAYS_FAILS, node);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _deprecatedVerifier.prefixExpression(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _checkForNullAwareHints(node, node.operator);
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _deprecatedVerifier.redirectingConstructorInvocation(node);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (!_invalidAccessVerifier._inTestDirectory) {
      _checkForReturnOfDoNotStore(node.expression);
    }
    super.visitReturnStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _checkForDuplications(node);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _deprecatedVerifier.simpleIdentifier(node);
    _invalidAccessVerifier.verify(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _deprecatedVerifier.superConstructorInvocation(node);
    _invalidAccessVerifier.verifySuperConstructorInvocation(node);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _deprecatedVerifier.pushInDeprecatedMetadata(node.metadata);

    if (!_invalidAccessVerifier._inTestDirectory) {
      for (var decl in node.variables.variables) {
        _checkForAssignmentOfDoNotStore(decl.initializer);
      }
    }

    try {
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      _deprecatedVerifier.popInDeprecated();
    }
  }

  /// Check for the passed is expression for the unnecessary type check hint
  /// codes as well as null checks expressed using an is expression.
  ///
  /// @param node the is expression to check
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.TYPE_CHECK_IS_NOT_NULL], [HintCode.TYPE_CHECK_IS_NULL],
  /// [HintCode.UNNECESSARY_TYPE_CHECK_TRUE], and
  /// [HintCode.UNNECESSARY_TYPE_CHECK_FALSE].
  bool _checkAllTypeChecks(IsExpression node) {
    var leftNode = node.expression;
    var rightNode = node.type;
    var rightType = rightNode.type as TypeImpl;

    void report() {
      _errorReporter.reportErrorForNode(
        node.notOperator == null
            ? HintCode.UNNECESSARY_TYPE_CHECK_TRUE
            : HintCode.UNNECESSARY_TYPE_CHECK_FALSE,
        node,
      );
    }

    // `is dynamic` or `is! dynamic`
    if (rightType.isDynamic) {
      var rightTypeStr = rightNode is NamedType ? rightNode.name.name : null;
      if (rightTypeStr == Keyword.DYNAMIC.lexeme) {
        report();
        return true;
      }
      return false;
    }

    // `is Null` or `is! Null`
    if (rightType.isDartCoreNull) {
      if (leftNode is NullLiteral) {
        report();
      } else {
        _errorReporter.reportErrorForNode(
          node.notOperator == null
              ? HintCode.TYPE_CHECK_IS_NULL
              : HintCode.TYPE_CHECK_IS_NOT_NULL,
          node,
        );
      }
      return true;
    }

    if (_isNonNullableByDefault) {
      var leftType = leftNode.typeOrThrow;
      if (_typeSystem.isSubtypeOf(leftType, rightType)) {
        report();
        return true;
      }
    } else {
      // In legacy all types are subtypes of `Object`.
      if (rightType.isDartCoreObject) {
        report();
        return true;
      }
    }

    return false;
  }

  void _checkForAssignmentOfDoNotStore(Expression? expression) {
    var expressionMap = _getSubExpressionsMarkedDoNotStore(expression);
    for (var entry in expressionMap.entries) {
      // All the elements returned by [_getSubExpressionsMarkedDoNotStore] are
      // named elements, so we can safely assume `entry.value.name` is
      // non-`null`.
      _errorReporter.reportErrorForNode(
        HintCode.ASSIGNMENT_OF_DO_NOT_STORE,
        entry.key,
        [entry.value.name!],
      );
    }
  }

  /// Check for the passed binary expression for the
  /// [HintCode.DIVISION_OPTIMIZATION].
  ///
  /// @param node the binary expression to check
  /// @return `true` if and only if a hint code is generated on the passed node
  /// See [HintCode.DIVISION_OPTIMIZATION].
  bool _checkForDivisionOptimizationHint(BinaryExpression node) {
    // Return if the operator is not '/'
    if (node.operator.type != TokenType.SLASH) {
      return false;
    }
    // Return if the '/' operator is not defined in core, or if we don't know
    // its static type
    var methodElement = node.staticElement;
    if (methodElement == null) {
      return false;
    }
    LibraryElement libraryElement = methodElement.library;
    if (!libraryElement.isDartCore) {
      return false;
    }
    // Report error if the (x/y) has toInt() invoked on it
    var parent = node.parent;
    if (parent is ParenthesizedExpression) {
      ParenthesizedExpression parenthesizedExpression =
          _wrapParenthesizedExpression(parent);
      var grandParent = parenthesizedExpression.parent;
      if (grandParent is MethodInvocation) {
        if (toIntMethodName == grandParent.methodName.name &&
            grandParent.argumentList.arguments.isEmpty) {
          _errorReporter.reportErrorForNode(
              HintCode.DIVISION_OPTIMIZATION, grandParent);
          return true;
        }
      }
    }
    return false;
  }

  /// Generate hints related to duplicate elements (keys) in sets (maps).
  void _checkForDuplications(SetOrMapLiteral node) {
    // This only checks for top-level elements. If, for, and spread elements
    // that contribute duplicate values are not detected.
    if (node.isConst) {
      // This case is covered by the ErrorVerifier.
      return;
    }
    final expressions = node.isSet
        ? node.elements.whereType<Expression>()
        : node.elements.whereType<MapLiteralEntry>().map((entry) => entry.key);
    final alreadySeen = <DartObject>{};
    for (final expression in expressions) {
      final constEvaluation = _linterContext.evaluateConstant(expression);
      if (constEvaluation.errors.isEmpty) {
        var value = constEvaluation.value;
        if (value != null && !alreadySeen.add(value)) {
          var errorCode = node.isSet
              ? HintCode.EQUAL_ELEMENTS_IN_SET
              : HintCode.EQUAL_KEYS_IN_MAP;
          _errorReporter.reportErrorForNode(errorCode, expression);
        }
      }
    }
  }

  /// Checks whether [node] violates the rules of [immutable].
  ///
  /// If [node] is marked with [immutable] or inherits from a class or mixin
  /// marked with [immutable], this function searches the fields of [node] and
  /// its superclasses, reporting a hint if any non-final instance fields are
  /// found.
  void _checkForImmutable(NamedCompilationUnitMember node) {
    /// Return `true` if the given class [element] is annotated with the
    /// `@immutable` annotation.
    bool isImmutable(ClassElement element) {
      for (ElementAnnotation annotation in element.metadata) {
        if (annotation.isImmutable) {
          return true;
        }
      }
      return false;
    }

    /// Return `true` if the given class [element] or any superclass of it is
    /// annotated with the `@immutable` annotation.
    bool isOrInheritsImmutable(
        ClassElement element, HashSet<ClassElement> visited) {
      if (visited.add(element)) {
        if (isImmutable(element)) {
          return true;
        }
        for (InterfaceType interface in element.mixins) {
          if (isOrInheritsImmutable(interface.element, visited)) {
            return true;
          }
        }
        for (InterfaceType mixin in element.interfaces) {
          if (isOrInheritsImmutable(mixin.element, visited)) {
            return true;
          }
        }
        if (element.supertype != null) {
          return isOrInheritsImmutable(element.supertype!.element, visited);
        }
      }
      return false;
    }

    Iterable<String> nonFinalInstanceFields(ClassElement element) {
      return element.fields
          .where((FieldElement field) =>
              !field.isSynthetic && !field.isFinal && !field.isStatic)
          .map((FieldElement field) => '${element.name}.${field.name}');
    }

    Iterable<String> definedOrInheritedNonFinalInstanceFields(
        ClassElement element, HashSet<ClassElement> visited) {
      Iterable<String> nonFinalFields = [];
      if (visited.add(element)) {
        nonFinalFields = nonFinalInstanceFields(element);
        nonFinalFields = nonFinalFields.followedBy(element.mixins.expand(
            (InterfaceType mixin) => nonFinalInstanceFields(mixin.element)));
        if (element.supertype != null) {
          nonFinalFields = nonFinalFields.followedBy(
              definedOrInheritedNonFinalInstanceFields(
                  element.supertype!.element, visited));
        }
      }
      return nonFinalFields;
    }

    var element = node.declaredElement as ClassElement;
    if (isOrInheritsImmutable(element, HashSet<ClassElement>())) {
      Iterable<String> nonFinalFields =
          definedOrInheritedNonFinalInstanceFields(
              element, HashSet<ClassElement>());
      if (nonFinalFields.isNotEmpty) {
        _errorReporter.reportErrorForNode(
            HintCode.MUST_BE_IMMUTABLE, node.name, [nonFinalFields.join(', ')]);
      }
    }
  }

  void _checkForImportOfLegacyLibraryIntoNullSafe(ImportDirective node) {
    if (!_isNonNullableByDefault) {
      return;
    }

    var importElement = node.element;
    if (importElement == null) {
      return;
    }

    var importedLibrary = importElement.importedLibrary;
    if (importedLibrary == null || importedLibrary.isNonNullableByDefault) {
      return;
    }

    _errorReporter.reportErrorForNode(
      HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE,
      node.uri,
      [importedLibrary.source.uri],
    );
  }

  /// Check that the namespace exported by [node] does not include any elements
  /// annotated with `@internal`.
  void _checkForInternalExport(ExportDirective node) {
    if (!_inPublicPackageApi) return;

    var libraryElement = node.uriElement;
    if (libraryElement == null) return;
    if (libraryElement.hasInternal) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT,
          node,
          [libraryElement.displayName]);
    }
    var exportNamespace =
        NamespaceBuilder().createExportNamespaceForDirective(node.element!);
    exportNamespace.definedNames.forEach((String name, Element element) {
      if (element.hasInternal) {
        _errorReporter.reportErrorForNode(
            HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT,
            node,
            [element.displayName]);
      } else if (element is FunctionElement) {
        var signatureTypes = [
          ...element.parameters.map((p) => p.type),
          element.returnType,
          ...element.typeParameters.map((tp) => tp.bound),
        ];
        for (var type in signatureTypes) {
          var aliasElement = type?.alias?.element;
          if (aliasElement != null && aliasElement.hasInternal) {
            _errorReporter.reportErrorForNode(
                HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY,
                node,
                [aliasElement.name, element.displayName]);
          }
        }
      }
    });
  }

  void _checkForInvalidFactory(MethodDeclaration decl) {
    // Check declaration.
    // Note that null return types are expected to be flagged by other analyses.
    var returnType = decl.returnType?.type;
    if (returnType is VoidType) {
      _errorReporter.reportErrorForNode(HintCode.INVALID_FACTORY_METHOD_DECL,
          decl.name, [decl.name.toString()]);
      return;
    }

    // Check implementation.

    FunctionBody body = decl.body;
    if (body is EmptyFunctionBody) {
      // Abstract methods are OK.
      return;
    }

    // `new Foo()` or `null`.
    bool factoryExpression(Expression? expression) =>
        expression is InstanceCreationExpression || expression is NullLiteral;

    if (body is ExpressionFunctionBody && factoryExpression(body.expression)) {
      return;
    } else if (body is BlockFunctionBody) {
      NodeList<Statement> statements = body.block.statements;
      if (statements.isNotEmpty) {
        Statement last = statements.last;
        if (last is ReturnStatement && factoryExpression(last.expression)) {
          return;
        }
      }
    }

    _errorReporter.reportErrorForNode(HintCode.INVALID_FACTORY_METHOD_IMPL,
        decl.name, [decl.name.toString()]);
  }

  void _checkForInvalidSealedSuperclass(NamedCompilationUnitMember node) {
    bool currentPackageContains(Element element) {
      return _isLibraryInWorkspacePackage(element.library);
    }

    // [NamedCompilationUnitMember.declaredElement] is not necessarily a
    // ClassElement, but [_checkForInvalidSealedSuperclass] should only be
    // called with a [ClassOrMixinDeclaration], or a [ClassTypeAlias]. The
    // `declaredElement` of these specific classes is a [ClassElement].
    var element = node.declaredElement as ClassElement;
    // TODO(srawlins): Perhaps replace this with a getter on Element, like
    // `Element.hasOrInheritsSealed`?
    for (InterfaceType supertype in element.allSupertypes) {
      ClassElement superclass = supertype.element;
      if (superclass.hasSealed) {
        if (!currentPackageContains(superclass)) {
          if (element.superclassConstraints.contains(supertype)) {
            // This is a special violation of the sealed class contract,
            // requiring specific messaging.
            _errorReporter.reportErrorForNode(HintCode.MIXIN_ON_SEALED_CLASS,
                node, [superclass.name.toString()]);
          } else {
            // This is a regular violation of the sealed class contract.
            _errorReporter.reportErrorForNode(HintCode.SUBTYPE_OF_SEALED_CLASS,
                node, [superclass.name.toString()]);
          }
        }
      }
    }
  }

  void _checkForInvariantNullComparison(BinaryExpression node) {
    if (!_isNonNullableByDefault) return;

    void reportStartEnd(
      HintCode errorCode,
      SyntacticEntity startEntity,
      SyntacticEntity endEntity,
    ) {
      var offset = startEntity.offset;
      _errorReporter.reportErrorForOffset(
        errorCode,
        offset,
        endEntity.end - offset,
      );
    }

    void checkLeftRight(HintCode errorCode) {
      if (node.leftOperand is NullLiteral) {
        var rightType = node.rightOperand.typeOrThrow;
        if (_typeSystem.isStrictlyNonNullable(rightType)) {
          reportStartEnd(errorCode, node.leftOperand, node.operator);
        }
      }

      if (node.rightOperand is NullLiteral) {
        var leftType = node.leftOperand.typeOrThrow;
        if (_typeSystem.isStrictlyNonNullable(leftType)) {
          reportStartEnd(errorCode, node.operator, node.rightOperand);
        }
      }
    }

    if (node.operator.type == TokenType.BANG_EQ) {
      checkLeftRight(HintCode.UNNECESSARY_NULL_COMPARISON_TRUE);
    } else if (node.operator.type == TokenType.EQ_EQ) {
      checkLeftRight(HintCode.UNNECESSARY_NULL_COMPARISON_FALSE);
    }
  }

  /// Check that the instance creation node is const if the constructor is
  /// marked with [literal].
  void _checkForLiteralConstructorUse(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    ConstructorElement? constructor = constructorName.staticElement;
    if (constructor == null) {
      return;
    }
    if (!node.isConst &&
        constructor.hasLiteral &&
        _linterContext.canBeConst(node)) {
      // Echoing jwren's TODO from _checkForDeprecatedMemberUse:
      // TODO(jwren) We should modify ConstructorElement.getDisplayName(), or
      // have the logic centralized elsewhere, instead of doing this logic
      // here.
      String fullConstructorName = constructorName.type2.name.name;
      if (constructorName.name != null) {
        fullConstructorName = '$fullConstructorName.${constructorName.name}';
      }
      HintCode hint = node.keyword?.keyword == Keyword.NEW
          ? HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW
          : HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR;
      _errorReporter.reportErrorForNode(hint, node, [fullConstructorName]);
    }
  }

  /// Check that the imported library does not define a loadLibrary function.
  /// The import has already been determined to be deferred when this is called.
  ///
  /// @param node the import directive to evaluate
  /// @param importElement the [ImportElement] retrieved from the node
  /// @return `true` if and only if an error code is generated on the passed
  ///         node
  /// See [CompileTimeErrorCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION].
  bool _checkForLoadLibraryFunction(
      ImportDirective node, ImportElement importElement) {
    var importedLibrary = importElement.importedLibrary;
    var prefix = importElement.prefix;
    if (importedLibrary == null || prefix == null) {
      return false;
    }
    var importNamespace = importElement.namespace;
    var loadLibraryElement = importNamespace.getPrefixed(
        prefix.name, FunctionElement.LOAD_LIBRARY_NAME);
    if (loadLibraryElement != null) {
      _errorReporter.reportErrorForNode(
          HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION, node);
      return true;
    }
    return false;
  }

  /// Generate a hint for functions or methods that have a return type, but do
  /// not have a return statement on all branches. At the end of blocks with no
  /// return, Dart implicitly returns `null`. Avoiding these implicit returns
  /// is considered a best practice.
  ///
  /// Note: for async functions/methods, this hint only applies when the
  /// function has a return type that Future<Null> is not assignable to.
  ///
  /// See [HintCode.MISSING_RETURN].
  void _checkForMissingReturn(FunctionBody body, AstNode functionNode) {
    if (_isNonNullableByDefault) {
      return;
    }

    // Generators always return.
    if (body.isGenerator) {
      return;
    }

    if (body is! BlockFunctionBody) {
      return;
    }

    var bodyContext = BodyInferenceContext.of(body)!;
    // TODO(scheglov) Update InferenceContext to record any type, dynamic.
    var returnType = bodyContext.contextType ?? DynamicTypeImpl.instance;

    if (_typeSystem.isNullable(returnType)) {
      return;
    }

    if (ExitDetector.exits(body)) {
      return;
    }

    var errorNode = functionNode;
    if (functionNode is FunctionDeclaration) {
      errorNode = functionNode.name;
    } else if (functionNode is MethodDeclaration) {
      errorNode = functionNode.name;
    }

    _errorReporter.reportErrorForNode(
      HintCode.MISSING_RETURN,
      errorNode,
      [returnType],
    );
  }

  void _checkForNullableTypeInCatchClause(CatchClause node) {
    if (!_isNonNullableByDefault) {
      return;
    }

    var type = node.exceptionType;
    if (type == null) {
      return;
    }

    if (_typeSystem.isPotentiallyNullable(type.typeOrThrow)) {
      _errorReporter.reportErrorForNode(
        HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE,
        type,
      );
    }
  }

  /// Produce several null-aware related hints.
  void _checkForNullAwareHints(Expression node, Token? operator) {
    if (_isNonNullableByDefault) {
      return;
    }

    if (operator == null || operator.type != TokenType.QUESTION_PERIOD) {
      return;
    }

    // childOfParent is used to know from which branch node comes.
    var childOfParent = node;
    var parent = node.parent;
    while (parent is ParenthesizedExpression) {
      childOfParent = parent;
      parent = parent.parent;
    }

    // CAN_BE_NULL_AFTER_NULL_AWARE
    if (parent is MethodInvocation &&
        !parent.isNullAware &&
        _nullType.lookUpMethod2(parent.methodName.name, _currentLibrary) ==
            null) {
      _errorReporter.reportErrorForNode(
          HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, childOfParent);
      return;
    }
    if (parent is PropertyAccess &&
        !parent.isNullAware &&
        _nullType.lookUpGetter2(parent.propertyName.name, _currentLibrary) ==
            null) {
      _errorReporter.reportErrorForNode(
          HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, childOfParent);
      return;
    }
    if (parent is CascadeExpression && parent.target == childOfParent) {
      _errorReporter.reportErrorForNode(
          HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, childOfParent);
      return;
    }

    // NULL_AWARE_IN_CONDITION
    if (parent is IfStatement && parent.condition == childOfParent ||
        parent is ForPartsWithDeclarations &&
            parent.condition == childOfParent ||
        parent is DoStatement && parent.condition == childOfParent ||
        parent is WhileStatement && parent.condition == childOfParent ||
        parent is ConditionalExpression && parent.condition == childOfParent ||
        parent is AssertStatement && parent.condition == childOfParent) {
      _errorReporter.reportErrorForNode(
          HintCode.NULL_AWARE_IN_CONDITION, childOfParent);
      return;
    }

    // NULL_AWARE_IN_LOGICAL_OPERATOR
    if (parent is PrefixExpression && parent.operator.type == TokenType.BANG ||
        parent is BinaryExpression &&
            [TokenType.BAR_BAR, TokenType.AMPERSAND_AMPERSAND]
                .contains(parent.operator.type)) {
      _errorReporter.reportErrorForNode(
          HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR, childOfParent);
      return;
    }

    // NULL_AWARE_BEFORE_OPERATOR
    if (parent is BinaryExpression &&
        ![TokenType.EQ_EQ, TokenType.BANG_EQ, TokenType.QUESTION_QUESTION]
            .contains(parent.operator.type) &&
        parent.leftOperand == childOfParent) {
      _errorReporter.reportErrorForNode(
          HintCode.NULL_AWARE_BEFORE_OPERATOR, childOfParent);
      return;
    }
  }

  void _checkForReturnOfDoNotStore(Expression? expression) {
    if (_inDoNotStoreMember) {
      return;
    }
    var expressionMap = _getSubExpressionsMarkedDoNotStore(expression);
    if (expressionMap.isNotEmpty) {
      var parent = expression!.thisOrAncestorMatching(
              (e) => e is FunctionDeclaration || e is MethodDeclaration)
          as Declaration?;
      if (parent == null) {
        return;
      }
      for (var entry in expressionMap.entries) {
        // All the elements returned by [_getSubExpressionsMarkedDoNotStore] are
        // named elements, so we can safely assume `entry.value.name` is
        // non-`null`.
        _errorReporter.reportErrorForNode(
          HintCode.RETURN_OF_DO_NOT_STORE,
          entry.key,
          [entry.value.name!, parent.declaredElement!.displayName],
        );
      }
    }
  }

  /// Generate a hint for `noSuchMethod` methods that do nothing except of
  /// calling another `noSuchMethod` that is not defined by `Object`.
  ///
  /// Return `true` if and only if a hint code is generated on the passed node.
  bool _checkForUnnecessaryNoSuchMethod(MethodDeclaration node) {
    if (node.name.name != FunctionElement.NO_SUCH_METHOD_METHOD_NAME) {
      return false;
    }
    bool isNonObjectNoSuchMethodInvocation(Expression? invocation) {
      if (invocation is MethodInvocation &&
          invocation.target is SuperExpression &&
          invocation.argumentList.arguments.length == 1) {
        SimpleIdentifier name = invocation.methodName;
        if (name.name == FunctionElement.NO_SUCH_METHOD_METHOD_NAME) {
          var methodElement = name.staticElement;
          var classElement = methodElement?.enclosingElement;
          return methodElement is MethodElement &&
              classElement is ClassElement &&
              !classElement.isDartCoreObject;
        }
      }
      return false;
    }

    FunctionBody body = node.body;
    if (body is ExpressionFunctionBody) {
      if (isNonObjectNoSuchMethodInvocation(body.expression)) {
        _errorReporter.reportErrorForNode(
            HintCode.UNNECESSARY_NO_SUCH_METHOD, node.name);
        return true;
      }
    } else if (body is BlockFunctionBody) {
      List<Statement> statements = body.block.statements;
      if (statements.length == 1) {
        Statement returnStatement = statements.first;
        if (returnStatement is ReturnStatement &&
            isNonObjectNoSuchMethodInvocation(returnStatement.expression)) {
          _errorReporter.reportErrorForNode(
              HintCode.UNNECESSARY_NO_SUCH_METHOD, node.name);
          return true;
        }
      }
    }
    return false;
  }

  void _checkRequiredParameter(FormalParameterList node) {
    final requiredParameters =
        node.parameters.where((p) => p.declaredElement?.hasRequired == true);
    final nonNamedParamsWithRequired =
        requiredParameters.where((p) => p.isPositional);
    final namedParamsWithRequiredAndDefault = requiredParameters
        .where((p) => p.isNamed)
        .where((p) => p.declaredElement!.defaultValueCode != null);
    for (final param in nonNamedParamsWithRequired.where((p) => p.isOptional)) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM,
          param,
          [_formalParameterNameOrEmpty(param)]);
    }
    for (final param in nonNamedParamsWithRequired.where((p) => p.isRequired)) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_REQUIRED_POSITIONAL_PARAM,
          param,
          [_formalParameterNameOrEmpty(param)]);
    }
    for (final param in namedParamsWithRequiredAndDefault) {
      _errorReporter.reportErrorForNode(HintCode.INVALID_REQUIRED_NAMED_PARAM,
          param, [_formalParameterNameOrEmpty(param)]);
    }
  }

  /// In "strict-inference" mode, check that each of the [parameters]' type is
  /// specified.
  ///
  /// Only parameters which are referenced in [initializers] or [body] are
  /// reported. If [initializers] and [body] are both null, the parameters are
  /// assumed to originate from a typedef, function-typed parameter, or function
  /// which is abstract or external.
  void _checkStrictInferenceInParameters(FormalParameterList? parameters,
      {List<ConstructorInitializer>? initializers, FunctionBody? body}) {
    _UsedParameterVisitor? usedParameterVisitor;

    bool isParameterReferenced(SimpleFormalParameter parameter) {
      if ((body == null || body is EmptyFunctionBody) && initializers == null) {
        // The parameter is in a typedef, or function that is abstract,
        // external, etc.
        return true;
      }
      if (usedParameterVisitor == null) {
        // Visit the function body and initializers once to determine whether
        // each of the parameters is referenced.
        usedParameterVisitor = _UsedParameterVisitor(
            parameters!.parameters.map((p) => p.declaredElement!).toSet());
        body?.accept(usedParameterVisitor!);
        for (var initializer in initializers ?? <ConstructorInitializer>[]) {
          initializer.accept(usedParameterVisitor!);
        }
      }

      return usedParameterVisitor!.isUsed(parameter.declaredElement!);
    }

    void checkParameterTypeIsKnown(SimpleFormalParameter parameter) {
      if (parameter.type == null && isParameterReferenced(parameter)) {
        ParameterElement element = parameter.declaredElement!;
        _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER,
          parameter,
          [element.displayName],
        );
      }
    }

    if (_strictInference && parameters != null) {
      for (FormalParameter parameter in parameters.parameters) {
        if (parameter is SimpleFormalParameter) {
          checkParameterTypeIsKnown(parameter);
        } else if (parameter is DefaultFormalParameter) {
          var nonDefault = parameter.parameter;
          if (nonDefault is SimpleFormalParameter) {
            checkParameterTypeIsKnown(nonDefault);
          }
        }
      }
    }
  }

  /// In "strict-inference" mode, check that [returnType] is specified.
  void _checkStrictInferenceReturnType(
      AstNode? returnType, AstNode reportNode, String displayName) {
    if (!_strictInference) {
      return;
    }
    if (returnType == null) {
      _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE,
          reportNode,
          [displayName]);
    }
  }

  Expression? _findUndefinedUseResultParam(
      ElementAnnotation element, Annotation node, AstNode parent) {
    var constructorName = node.name;
    if (constructorName is! PrefixedIdentifier ||
        constructorName.identifier.name != 'unless') {
      return null;
    }

    var unlessParam = element
        .computeConstantValue()
        ?.getField('parameterDefined')
        ?.toStringValue();
    if (unlessParam == null) {
      return null;
    }

    Expression? checkParams(FormalParameterList? parameterList) {
      if (parameterList == null) {
        return null;
      }

      for (var param in parameterList.parameters) {
        // Param is defined.
        if (param.identifier?.name == unlessParam) {
          return null;
        }
      }

      // Find and return the parameter value node.
      var arguments = node.arguments?.arguments;
      if (arguments == null) {
        return null;
      }

      for (var arg in arguments) {
        if (arg is NamedExpression &&
            arg.name.label.name == 'parameterDefined') {
          return arg.expression;
        }
      }

      return null;
    }

    if (parent is FunctionDeclarationImpl) {
      return checkParams(parent.functionExpression.parameters);
    }
    if (parent is MethodDeclarationImpl) {
      return checkParams(parent.parameters);
    }

    return null;
  }

  /// Return subexpressions that are marked `@doNotStore`, as a map so that
  /// corresponding elements can be used in the diagnostic message.
  Map<Expression, Element> _getSubExpressionsMarkedDoNotStore(
      Expression? expression,
      {Map<Expression, Element>? addTo}) {
    var expressions = addTo ?? <Expression, Element>{};

    Element? element;
    if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
      // Tear-off.
      if (element is FunctionElement || element is MethodElement) {
        element = null;
      }
    } else if (expression is MethodInvocation) {
      element = expression.methodName.staticElement;
    } else if (expression is Identifier) {
      element = expression.staticElement;
      // Tear-off.
      if (element is FunctionElement || element is MethodElement) {
        element = null;
      }
    } else if (expression is ConditionalExpression) {
      _getSubExpressionsMarkedDoNotStore(expression.elseExpression,
          addTo: expressions);
      _getSubExpressionsMarkedDoNotStore(expression.thenExpression,
          addTo: expressions);
    } else if (expression is BinaryExpression) {
      _getSubExpressionsMarkedDoNotStore(expression.leftOperand,
          addTo: expressions);
      _getSubExpressionsMarkedDoNotStore(expression.rightOperand,
          addTo: expressions);
    } else if (expression is FunctionExpression) {
      var body = expression.body;
      if (body is ExpressionFunctionBody) {
        _getSubExpressionsMarkedDoNotStore(body.expression, addTo: expressions);
      }
    }
    if (element is PropertyAccessorElement && element.isSynthetic) {
      element = element.variable;
    }

    if (element != null && element.hasOrInheritsDoNotStore) {
      expressions[expression!] = element;
    }

    return expressions;
  }

  bool _isLibraryInWorkspacePackage(LibraryElement? library) {
    if (_workspacePackage == null || library == null) {
      // Better to not make a big claim that they _are_ in the same package,
      // if we were unable to determine what package [_currentLibrary] is in.
      return false;
    }
    return _workspacePackage!.contains(library.source);
  }

  /// Return `true` if it is valid to have an annotation on the given [target]
  /// when the annotation is marked as being valid for the given [kinds] of
  /// targets.
  bool _isValidTarget(AstNode target, Set<TargetKind> kinds) {
    if (target is ClassDeclaration) {
      return kinds.contains(TargetKind.classType) ||
          kinds.contains(TargetKind.type);
    } else if (target is Directive) {
      return (target.parent as CompilationUnit).directives.first == target &&
          kinds.contains(TargetKind.library);
    } else if (target is EnumDeclaration) {
      return kinds.contains(TargetKind.enumType) ||
          kinds.contains(TargetKind.type);
    } else if (target is ExtensionDeclaration) {
      return kinds.contains(TargetKind.extension);
    } else if (target is FieldDeclaration) {
      return kinds.contains(TargetKind.field);
    } else if (target is FunctionDeclaration) {
      if (target.isGetter) {
        return kinds.contains(TargetKind.getter);
      }
      if (target.isSetter) {
        return kinds.contains(TargetKind.setter);
      }
      return kinds.contains(TargetKind.function);
    } else if (target is MethodDeclaration) {
      if (target.isGetter) {
        return kinds.contains(TargetKind.getter);
      }
      if (target.isSetter) {
        return kinds.contains(TargetKind.setter);
      }
      return kinds.contains(TargetKind.method);
    } else if (target is MixinDeclaration) {
      return kinds.contains(TargetKind.mixinType) ||
          kinds.contains(TargetKind.type);
    } else if (target is FormalParameter) {
      return kinds.contains(TargetKind.parameter);
    } else if (target is FunctionTypeAlias || target is GenericTypeAlias) {
      return kinds.contains(TargetKind.typedefType) ||
          kinds.contains(TargetKind.type);
    } else if (target is TopLevelVariableDeclaration) {
      return kinds.contains(TargetKind.topLevelVariable);
    }
    return false;
  }

  /// Checks for the passed as expression for the [HintCode.UNNECESSARY_CAST]
  /// hint code.
  ///
  /// Returns `true` if and only if an unnecessary cast hint should be generated
  /// on [node].  See [HintCode.UNNECESSARY_CAST].
  static bool isUnnecessaryCast(AsExpression node, TypeSystemImpl typeSystem) {
    var leftType = node.expression.typeOrThrow;
    var rightType = node.type.typeOrThrow;

    // `dynamicValue as SomeType` is a valid use case.
    if (leftType.isDynamic) {
      return false;
    }

    // `x as Unresolved` is already reported as an error.
    if (rightType.isDynamic) {
      return false;
    }

    // The cast is necessary.
    if (!typeSystem.isSubtypeOf(leftType, rightType)) {
      return false;
    }

    // Casting from `T*` to `T?` is a way to force `T?`.
    if (leftType.nullabilitySuffix == NullabilitySuffix.star &&
        rightType.nullabilitySuffix == NullabilitySuffix.question) {
      return false;
    }

    // For `condition ? then : else` the result type is `LUB`.
    // Casts might be used to consider only a portion of the inheritance tree.
    var parent = node.parent;
    if (parent is ConditionalExpression) {
      var other = node == parent.thenExpression
          ? parent.elseExpression
          : parent.thenExpression;

      var currentType = typeSystem.leastUpperBound(
        node.typeOrThrow,
        other.typeOrThrow,
      );

      var typeWithoutCast = typeSystem.leastUpperBound(
        node.expression.typeOrThrow,
        other.typeOrThrow,
      );

      if (typeWithoutCast != currentType) {
        return false;
      }
    }

    return true;
  }

  static String _formalParameterNameOrEmpty(FormalParameter node) {
    var identifier = node.identifier;
    return identifier?.name ?? '';
  }

  static bool _hasNonVirtualAnnotation(ExecutableElement element) {
    if (element is PropertyAccessorElement && element.isSynthetic) {
      return element.variable.hasNonVirtual;
    }
    return element.hasNonVirtual;
  }

  /// Given a parenthesized expression, this returns the parent (or recursively
  /// grand-parent) of the expression that is a parenthesized expression, but
  /// whose parent is not a parenthesized expression.
  ///
  /// For example given the code `(((e)))`: `(e) -> (((e)))`.
  ///
  /// @param parenthesizedExpression some expression whose parent is a
  ///        parenthesized expression
  /// @return the first parent or grand-parent that is a parenthesized
  ///         expression, that does not have a parenthesized expression parent
  static ParenthesizedExpression _wrapParenthesizedExpression(
      ParenthesizedExpression parenthesizedExpression) {
    var parent = parenthesizedExpression.parent;
    if (parent is ParenthesizedExpression) {
      return _wrapParenthesizedExpression(parent);
    }
    return parenthesizedExpression;
  }
}

class _InvalidAccessVerifier {
  static final _templateExtension = '.template';

  final ErrorReporter _errorReporter;
  final LibraryElement _library;
  final WorkspacePackage? _workspacePackage;

  final bool _inTemplateSource;
  late final bool _inTestDirectory;

  ClassElement? _enclosingClass;

  _InvalidAccessVerifier(
      this._errorReporter, this._library, this._workspacePackage)
      : _inTemplateSource =
            _library.source.fullName.contains(_templateExtension);

  /// Produces a hint if [identifier] is accessed from an invalid location.
  ///
  /// In particular, a hint is produced in either of the two following cases:
  ///
  /// * The element associated with [identifier] is annotated with [internal],
  ///   and is accessed from outside the package in which the element is
  ///   declared.
  /// * The element associated with [identifier] is annotated with [protected],
  ///   [visibleForTesting], and/or [visibleForTemplate], and is accessed from a
  ///   location which is invalid as per the rules of each such annotation.
  ///   Conversely, if the element is annotated with more than one of these
  ///   annotations, the access is valid (and no hint will be produced) if it
  ///   conforms to the rules of at least one of the annotations.
  void verify(SimpleIdentifier identifier) {
    if (identifier.inDeclarationContext() || _inCommentReference(identifier)) {
      return;
    }

    // This is the same logic used in [checkForDeprecatedMemberUseAtIdentifier]
    // to avoid reporting an error twice for named constructors.
    var parent = identifier.parent;
    if (parent is ConstructorName && identical(identifier, parent.name)) {
      return;
    }
    var grandparent = parent?.parent;

    var element = grandparent is ConstructorName
        ? grandparent.staticElement
        : identifier.writeOrReadElement;

    if (element == null || _inCurrentLibrary(element)) {
      return;
    }

    if (parent is HideCombinator) {
      return;
    }

    _checkForInvalidInternalAccess(identifier, element);
    _checkForOtherInvalidAccess(identifier, element);
  }

  void verifyImport(ImportDirective node) {
    var element = node.uriElement;
    if (_hasInternal(element) &&
        !_isLibraryInWorkspacePackage(element!.library)) {
      // The only way for an import directive's URI to have a `null`
      // `stringValue` is if its string contains an interpolation, in which case
      // the element would never have resolved in the first place.  So we can
      // safely assume `node.uri.stringValue` is non-`null`.
      _errorReporter.reportErrorForNode(HintCode.INVALID_USE_OF_INTERNAL_MEMBER,
          node, [node.uri.stringValue!]);
    }
  }

  void verifySuperConstructorInvocation(SuperConstructorInvocation node) {
    if (node.constructorName != null) {
      // Named constructor calls are handled by [verify].
      return;
    }
    var element = node.staticElement;
    if (_hasInternal(element) &&
        !_isLibraryInWorkspacePackage(element!.library)) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_INTERNAL_MEMBER, node, [element.name]);
    }
  }

  void _checkForInvalidInternalAccess(
      SimpleIdentifier identifier, Element element) {
    if (_hasInternal(element) &&
        !_isLibraryInWorkspacePackage(element.library)) {
      String name;
      AstNode node;

      var grandparent = identifier.parent?.parent;

      if (grandparent is ConstructorName) {
        name = grandparent.toSource();
        node = grandparent;
      } else {
        name = identifier.name;
        node = identifier;
      }

      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_INTERNAL_MEMBER, node, [name]);
    }
  }

  void _checkForOtherInvalidAccess(
      SimpleIdentifier identifier, Element element) {
    bool hasProtected = _hasProtected(element);
    if (hasProtected) {
      var definingClass = element.enclosingElement as ClassElement;
      if (_hasTypeOrSuperType(_enclosingClass, definingClass)) {
        return;
      }
    }

    bool hasVisibleForTemplate = _hasVisibleForTemplate(element);
    if (hasVisibleForTemplate) {
      if (_inTemplateSource || _inExportDirective(identifier)) {
        return;
      }
    }

    bool hasVisibleForTesting = _hasVisibleForTesting(element);
    if (hasVisibleForTesting) {
      if (_inTestDirectory || _inExportDirective(identifier)) {
        return;
      }
    }

    bool hasVisibleForOverriding = _hasVisibleForOverriding(element);

    // At this point, [identifier] was not cleared as protected access, nor
    // cleared as access for templates or testing. Report a violation for each
    // annotation present.

    String name;
    AstNode node;

    var grandparent = identifier.parent?.parent;

    if (grandparent is ConstructorName) {
      name = grandparent.toSource();
      node = grandparent;
    } else {
      name = identifier.name;
      node = identifier;
    }

    var definingClass = element.enclosingElement;
    if (hasProtected) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_PROTECTED_MEMBER,
          node,
          [name, definingClass!.source!.uri]);
    }
    if (hasVisibleForTemplate) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER,
          node,
          [name, definingClass!.source!.uri]);
    }

    if (hasVisibleForTesting) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER,
          node,
          [name, definingClass!.source!.uri]);
    }

    if (hasVisibleForOverriding) {
      _errorReporter.reportErrorForNode(
          HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, node, [name]);
    }
  }

  bool _hasInternal(Element? element) {
    if (element == null) {
      return false;
    }
    if (element.hasInternal) {
      return true;
    }
    if (element is PropertyAccessorElement && element.variable.hasInternal) {
      return true;
    }
    return false;
  }

  bool _hasProtected(Element element) {
    if (element is PropertyAccessorElement &&
        element.enclosingElement is ClassElement &&
        (element.hasProtected || element.variable.hasProtected)) {
      return true;
    }
    if (element is MethodElement &&
        element.enclosingElement is ClassElement &&
        element.hasProtected) {
      return true;
    }
    return false;
  }

  bool _hasTypeOrSuperType(ClassElement? element, ClassElement superElement) {
    if (element == null) {
      return false;
    }
    return element.thisType.asInstanceOf(superElement) != null;
  }

  bool _hasVisibleForOverriding(Element element) {
    if (element.hasVisibleForOverriding) {
      return true;
    }

    if (element is PropertyAccessorElement &&
        element.variable.hasVisibleForOverriding) {
      return true;
    }

    return false;
  }

  bool _hasVisibleForTemplate(Element? element) {
    if (element == null) {
      return false;
    }
    if (element.hasVisibleForTemplate) {
      return true;
    }
    if (element is PropertyAccessorElement &&
        element.variable.hasVisibleForTemplate) {
      return true;
    }
    return false;
  }

  bool _hasVisibleForTesting(Element element) {
    if (element.hasVisibleForTesting) {
      return true;
    }
    if (element is PropertyAccessorElement &&
        element.variable.hasVisibleForTesting) {
      return true;
    }
    return false;
  }

  bool _inCommentReference(SimpleIdentifier identifier) {
    var parent = identifier.parent;
    return parent is CommentReference || parent?.parent is CommentReference;
  }

  bool _inCurrentLibrary(Element element) => element.library == _library;

  bool _inExportDirective(SimpleIdentifier identifier) =>
      identifier.parent is Combinator &&
      identifier.parent!.parent is ExportDirective;

  bool _isLibraryInWorkspacePackage(LibraryElement? library) {
    if (_workspacePackage == null || library == null) {
      // Better to not make a big claim that they _are_ in the same package,
      // if we were unable to determine what package [_currentLibrary] is in.
      return false;
    }
    return _workspacePackage!.contains(library.source);
  }
}

/// A visitor that determines, upon visiting a function body and/or a
/// constructor's initializers, whether a parameter is referenced.
class _UsedParameterVisitor extends RecursiveAstVisitor<void> {
  final Set<ParameterElement> _parameters;

  final Set<ParameterElement> _usedParameters = {};

  _UsedParameterVisitor(this._parameters);

  bool isUsed(ParameterElement parameter) =>
      _usedParameters.contains(parameter);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is ExecutableMember) {
      element = element.declaration;
    }
    if (_parameters.contains(element)) {
      _usedParameters.add(element as ParameterElement);
    }
  }
}
