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
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart' show Member;
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/annotation_resolver.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/binary_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/constructor_reference_resolver.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/for_resolver.dart';
import 'package:analyzer/src/dart/resolver/function_expression_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/function_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/function_reference_resolver.dart';
import 'package:analyzer/src/dart/resolver/instance_creation_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/resolver/lexical_lookup.dart';
import 'package:analyzer/src/dart/resolver/method_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/postfix_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/prefix_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/prefixed_identifier_resolver.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/resolver/simple_identifier_resolver.dart';
import 'package:analyzer/src/dart/resolver/this_lookup.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/dart/resolver/typed_literal_resolver.dart';
import 'package:analyzer/src/dart/resolver/variable_declaration_resolver.dart';
import 'package:analyzer/src/dart/resolver/yield_statement_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/bool_expression_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/error/super_formal_parameters_verifier.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/this_access_tracker.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';
import 'package:meta/meta.dart';

/// A function which returns [NonPromotionReason]s that various types are not
/// promoted.
typedef WhyNotPromotedGetter = Map<DartType, NonPromotionReason> Function();

/// Maintains and manages contextual type information used for
/// inferring types.
class InferenceContext {
  final ResolverVisitor _resolver;

  /// The type system in use.
  final TypeSystemImpl _typeSystem;

  /// The stack of contexts for nested function bodies.
  final List<BodyInferenceContext> _bodyContexts = [];

  InferenceContext._(ResolverVisitor resolver)
      : _resolver = resolver,
        _typeSystem = resolver.typeSystem;

  BodyInferenceContext? get bodyContext {
    if (_bodyContexts.isNotEmpty) {
      return _bodyContexts.last;
    } else {
      return null;
    }
  }

  DartType popFunctionBodyContext(FunctionBody node) {
    var context = _bodyContexts.removeLast();

    var flow = _resolver.flowAnalysis.flow;

    return context.computeInferredReturnType(
      endOfBlockIsReachable: flow == null || flow.isReachable,
    );
  }

  void pushFunctionBodyContext(FunctionBody node, DartType? imposedType) {
    _bodyContexts.add(
      BodyInferenceContext(
        typeSystem: _typeSystem,
        node: node,
        imposedType: imposedType,
      ),
    );
  }
}

/// Instances of the class `ResolverVisitor` are used to resolve the nodes
/// within a single compilation unit.
class ResolverVisitor extends ThrowingAstVisitor<void>
    with ErrorDetectionHelpers {
  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl definingLibrary;

  /// The source representing the compilation unit being visited.
  final Source source;

  /// The object used to access the types from the core library.
  final TypeProviderImpl typeProvider;

  @override
  final ErrorReporter errorReporter;

  /// The class containing the AST nodes being visited,
  /// or `null` if we are not in the scope of a class.
  ClassElement? enclosingClass;

  /// The element representing the extension containing the AST nodes being
  /// visited, or `null` if we are not in the scope of an extension.
  ExtensionElement? enclosingExtension;

  /// The element representing the function containing the current node, or
  /// `null` if the current node is not contained in a function.
  ExecutableElement? _enclosingFunction;

  /// The manager for the inheritance mappings.
  final InheritanceManager3 inheritance;

  /// The feature set that is enabled for the current unit.
  final FeatureSet _featureSet;

  final MigratableAstInfoProvider _migratableAstInfoProvider;

  final MigrationResolutionHooks? migrationResolutionHooks;

  /// Helper for checking expression that should have the `bool` type.
  late final BoolExpressionVerifier boolExpressionVerifier;

  /// Helper for checking potentially nullable dereferences.
  late final NullableDereferenceVerifier nullableDereferenceVerifier;

  /// Helper for extension method resolution.
  late final ExtensionMemberResolver extensionResolver;

  /// Helper for resolving properties on types.
  late final TypePropertyResolver typePropertyResolver;

  /// Helper for resolving [ListLiteral] and [SetOrMapLiteral].
  late final TypedLiteralResolver _typedLiteralResolver;

  late final AssignmentExpressionResolver _assignmentExpressionResolver;
  late final BinaryExpressionResolver _binaryExpressionResolver;
  late final ConstructorReferenceResolver _constructorReferenceResolver =
      ConstructorReferenceResolver(this);
  late final FunctionExpressionInvocationResolver
      _functionExpressionInvocationResolver;
  late final FunctionExpressionResolver _functionExpressionResolver;
  late final ForResolver _forResolver;
  late final PostfixExpressionResolver _postfixExpressionResolver;
  late final PrefixedIdentifierResolver _prefixedIdentifierResolver;
  late final PrefixExpressionResolver _prefixExpressionResolver;
  late final VariableDeclarationResolver _variableDeclarationResolver;
  late final YieldStatementResolver _yieldStatementResolver;

  late final NullSafetyDeadCodeVerifier nullSafetyDeadCodeVerifier;

  late final InvocationInferenceHelper inferenceHelper;

  /// The object used to resolve the element associated with the current node.
  late final ElementResolver elementResolver;

  /// The object used to compute the type associated with the current node.
  late final StaticTypeAnalyzer typeAnalyzer;

  /// The type system in use during resolution.
  @override
  final TypeSystemImpl typeSystem;

  /// The helper for tracking if the current location has access to `this`.
  final ThisAccessTracker _thisAccessTracker = ThisAccessTracker.unit();

  late final InferenceContext inferenceContext;

  /// If a class, or mixin, is being resolved, the type of the class.
  /// Otherwise `null`.
  DartType? _thisType;

  final FlowAnalysisHelper flowAnalysis;

  /// A comment before a function should be resolved in the context of the
  /// function. But when we incrementally resolve a comment, we don't want to
  /// resolve the whole function.
  ///
  /// So, this flag is set to `true`, when just context of the function should
  /// be built and the comment resolved.
  bool resolveOnlyCommentInFunctionBody = false;

  /// The type of the expression of the immediately enclosing [SwitchStatement],
  /// or `null` if not in a [SwitchStatement].
  DartType? _enclosingSwitchStatementExpressionType;

  /// Stack of expressions which we have not yet finished visiting, that should
  /// terminate a null-shorting expression.
  ///
  /// The stack contains a `null` sentinel as its first entry so that it is
  /// always safe to use `.last` to examine the top of the stack.
  final List<Expression?> _unfinishedNullShorts = [null];

  late final FunctionReferenceResolver _functionReferenceResolver;

  late final InstanceCreationExpressionResolver
      _instanceCreationExpressionResolver =
      InstanceCreationExpressionResolver(this);

  late final SimpleIdentifierResolver _simpleIdentifierResolver =
      SimpleIdentifierResolver(this);

  late final PropertyElementResolver _propertyElementResolver =
      PropertyElementResolver(this);

  late final AnnotationResolver _annotationResolver = AnnotationResolver(this);

  final bool genericMetadataIsEnabled;

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// The [definingLibrary] is the element for the library containing the node
  /// being visited. The [source] is the source representing the compilation
  /// unit containing the node being visited. The [typeProvider] is the object
  /// used to access the types from the core library. The [errorListener] is the
  /// error listener that will be informed of any errors that are found during
  /// resolution.
  ///
  /// TODO(paulberry): make [featureSet] a required parameter (this will be a
  /// breaking change).
  ResolverVisitor(
      InheritanceManager3 inheritanceManager,
      LibraryElementImpl definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      {FeatureSet? featureSet,
      required FlowAnalysisHelper flowAnalysisHelper})
      : this._(
            inheritanceManager,
            definingLibrary,
            source,
            definingLibrary.typeSystem,
            typeProvider as TypeProviderImpl,
            errorListener,
            featureSet ??
                definingLibrary.context.analysisOptions.contextFeatures,
            flowAnalysisHelper,
            const MigratableAstInfoProvider(),
            null);

  ResolverVisitor._(
      this.inheritance,
      this.definingLibrary,
      this.source,
      this.typeSystem,
      this.typeProvider,
      AnalysisErrorListener errorListener,
      FeatureSet featureSet,
      this.flowAnalysis,
      this._migratableAstInfoProvider,
      this.migrationResolutionHooks)
      : errorReporter = ErrorReporter(
          errorListener,
          source,
          isNonNullableByDefault: definingLibrary.isNonNullableByDefault,
        ),
        _featureSet = featureSet,
        genericMetadataIsEnabled =
            definingLibrary.featureSet.isEnabled(Feature.generic_metadata) {
    var analysisOptions =
        definingLibrary.context.analysisOptions as AnalysisOptionsImpl;

    nullableDereferenceVerifier = NullableDereferenceVerifier(
      typeSystem: typeSystem,
      errorReporter: errorReporter,
      resolver: this,
    );
    boolExpressionVerifier = BoolExpressionVerifier(
      resolver: this,
      errorReporter: errorReporter,
      nullableDereferenceVerifier: nullableDereferenceVerifier,
    );
    _typedLiteralResolver = TypedLiteralResolver(
        this, _featureSet, typeSystem, typeProvider,
        migratableAstInfoProvider: _migratableAstInfoProvider);
    extensionResolver = ExtensionMemberResolver(this);
    typePropertyResolver = TypePropertyResolver(this);
    inferenceHelper = InvocationInferenceHelper(
      resolver: this,
      errorReporter: errorReporter,
      typeSystem: typeSystem,
      migrationResolutionHooks: migrationResolutionHooks,
    );
    _assignmentExpressionResolver = AssignmentExpressionResolver(
      resolver: this,
    );
    _binaryExpressionResolver = BinaryExpressionResolver(
      resolver: this,
    );
    _functionExpressionInvocationResolver =
        FunctionExpressionInvocationResolver(
      resolver: this,
    );
    _functionExpressionResolver = FunctionExpressionResolver(
      resolver: this,
      migrationResolutionHooks: migrationResolutionHooks,
    );
    _forResolver = ForResolver(
      resolver: this,
    );
    _postfixExpressionResolver = PostfixExpressionResolver(
      resolver: this,
    );
    _prefixedIdentifierResolver = PrefixedIdentifierResolver(this);
    _prefixExpressionResolver = PrefixExpressionResolver(
      resolver: this,
    );
    _variableDeclarationResolver = VariableDeclarationResolver(
      resolver: this,
      strictInference: analysisOptions.strictInference,
    );
    _yieldStatementResolver = YieldStatementResolver(
      resolver: this,
    );
    nullSafetyDeadCodeVerifier = NullSafetyDeadCodeVerifier(
      typeSystem,
      errorReporter,
      flowAnalysis,
    );
    elementResolver = ElementResolver(this,
        migratableAstInfoProvider: _migratableAstInfoProvider);
    inferenceContext = InferenceContext._(this);
    typeAnalyzer = StaticTypeAnalyzer(this);
    _functionReferenceResolver =
        FunctionReferenceResolver(this, _isNonNullableByDefault);
  }

  /// Return the element representing the function containing the current node,
  /// or `null` if the current node is not contained in a function.
  ///
  /// @return the element representing the function containing the current node
  ExecutableElement? get enclosingFunction => _enclosingFunction;

  bool get isConstructorTearoffsEnabled =>
      _featureSet.isEnabled(Feature.constructor_tearoffs);

  bool get isInferenceUpdate1Enabled =>
      _featureSet.isEnabled(Feature.inference_update_1);

  /// Return the object providing promoted or declared types of variables.
  LocalVariableTypeProvider get localVariableTypeProvider {
    return flowAnalysis.localVariableTypeProvider;
  }

  NullabilitySuffix get noneOrStarSuffix {
    return _isNonNullableByDefault
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  /// If a class, or mixin, is being resolved, the type of the class.
  ///
  /// If an extension is being resolved, the type of `this`, the declared
  /// extended type, or promoted.
  ///
  /// Otherwise `null`.
  DartType? get thisType {
    return _thisType;
  }

  /// Return `true` if NNBD is enabled for this compilation unit.
  bool get _isNonNullableByDefault =>
      _featureSet.isEnabled(Feature.non_nullable);

  void analyzeExpression(Expression expression, DartType? contextType) {
    if (contextType != null && contextType.isDynamic) {
      contextType = null;
    }
    (expression as ExpressionImpl).resolveExpression(this, contextType);
  }

  /// Verify that the arguments in the given [argumentList] can be assigned to
  /// their corresponding parameters.
  ///
  /// See [CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
  void checkForArgumentTypesNotAssignableInList(ArgumentList argumentList,
      List<WhyNotPromotedGetter> whyNotPromotedList) {
    var arguments = argumentList.arguments;
    for (int i = 0; i < arguments.length; i++) {
      checkForArgumentTypeNotAssignableForArgument(arguments[i],
          whyNotPromoted:
              flowAnalysis.flow == null ? null : whyNotPromotedList[i]);
    }
  }

  void checkForBodyMayCompleteNormally({
    required FunctionBody body,
    required AstNode errorNode,
  }) {
    if (!_isNonNullableByDefault) return;
    if (!flowAnalysis.flow!.isReachable) {
      return;
    }

    // TODO(scheglov) encapsulate
    var bodyContext = BodyInferenceContext.of(body);
    if (bodyContext == null) {
      return;
    }
    var returnType = bodyContext.contextType;
    if (returnType == null) {
      return;
    }

    if (body is BlockFunctionBody) {
      if (body.isGenerator) {
        return;
      }

      if (body.isAsynchronous) {
        // Check whether the return type is legal. If not, return rather than
        // reporting a second error.

        // This is the same check as [ReturnTypeVerifier._isLegalReturnType].
        // TODO(srawlins): When this check is moved into the resolution stage,
        // use the result of that check to determine whether this check should
        // be done.
        var lowerBound = typeProvider.futureElement.instantiate(
          typeArguments: [NeverTypeImpl.instance],
          nullabilitySuffix: NullabilitySuffix.star,
        );
        var imposedType = bodyContext.imposedType;
        if (imposedType != null &&
            !typeSystem.isSubtypeOf(lowerBound, imposedType)) {
          // [imposedType] is an illegal return type for an asynchronous
          // non-generator function; do not report an additional error here.
          return;
        }
      }

      ErrorCode errorCode;
      if (typeSystem.isPotentiallyNonNullable(returnType)) {
        errorCode = CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY;
      } else {
        var returnTypeBase = typeSystem.futureOrBase(returnType);
        if (returnTypeBase.isVoid ||
            returnTypeBase.isDynamic ||
            returnTypeBase.isDartCoreNull) {
          return;
        } else {
          errorCode = HintCode.BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE;
        }
      }
      if (errorNode is ConstructorDeclaration) {
        errorReporter.reportErrorForName(
          errorCode,
          errorNode,
          arguments: [returnType],
        );
      } else if (errorNode is BlockFunctionBody) {
        errorReporter.reportErrorForToken(
          errorCode,
          errorNode.block.leftBracket,
          [returnType],
        );
      } else {
        errorReporter.reportErrorForNode(
          errorCode,
          errorNode,
          [returnType],
        );
      }
    }
  }

  void checkReadOfNotAssignedLocalVariable(
    SimpleIdentifier node,
    Element? element,
  ) {
    if (flowAnalysis.flow == null) {
      return;
    }

    if (!node.inGetterContext()) {
      return;
    }

    if (element is VariableElement) {
      var assigned =
          flowAnalysis.isDefinitelyAssigned(node, element as PromotableElement);
      var unassigned = flowAnalysis.isDefinitelyUnassigned(node, element);

      if (element.isLate) {
        if (unassigned) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE,
            node,
            [node.name],
          );
        }
        return;
      }

      if (!assigned) {
        if (element.isFinal) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.READ_POTENTIALLY_UNASSIGNED_FINAL,
            node,
            [node.name],
          );
          return;
        }

        if (typeSystem.isPotentiallyNonNullable(element.type)) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode
                .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
            node,
            [node.name],
          );
          return;
        }
      }
    }
  }

  void checkUnreachableNode(AstNode node) {
    nullSafetyDeadCodeVerifier.visitNode(node);
  }

  @override
  List<DiagnosticMessage> computeWhyNotPromotedMessages(
      SyntacticEntity errorEntity,
      Map<DartType, NonPromotionReason>? whyNotPromoted) {
    List<DiagnosticMessage> messages = [];
    if (whyNotPromoted != null) {
      for (var entry in whyNotPromoted.entries) {
        var whyNotPromotedVisitor = _WhyNotPromotedVisitor(
            source, errorEntity, flowAnalysis.dataForTesting);
        if (typeSystem.isPotentiallyNullable(entry.key)) continue;
        var message = entry.value.accept(whyNotPromotedVisitor);
        if (message != null) {
          if (flowAnalysis.dataForTesting != null) {
            var nonPromotionReasonText = entry.value.shortName;
            var args = <String>[];
            if (whyNotPromotedVisitor.propertyReference != null) {
              var id =
                  computeMemberId(whyNotPromotedVisitor.propertyReference!);
              args.add('target: $id');
            }
            var propertyType = whyNotPromotedVisitor.propertyType;
            if (propertyType != null) {
              var propertyTypeStr = propertyType.getDisplayString(
                withNullability: true,
              );
              args.add('type: $propertyTypeStr');
            }
            if (args.isNotEmpty) {
              nonPromotionReasonText += '(${args.join(', ')})';
            }
            flowAnalysis.dataForTesting!.nonPromotionReasons[errorEntity] =
                nonPromotionReasonText;
          }
          messages = [message];
        }
        break;
      }
    }
    return messages;
  }

  /// Return the static element associated with the given expression whose type
  /// can be overridden, or `null` if there is no element whose type can be
  /// overridden.
  ///
  /// @param expression the expression with which the element is associated
  /// @return the element associated with the given expression
  VariableElement? getOverridableStaticElement(Expression expression) {
    Element? element;
    if (expression is SimpleIdentifier) {
      element = expression.staticElement;
    } else if (expression is PrefixedIdentifier) {
      element = expression.staticElement;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
    }
    if (element is VariableElement) {
      return element;
    }
    return null;
  }

  /// If generic function instantiation should be performed on `expression`,
  /// inserts a [FunctionReference] node which wraps [expression].
  ///
  /// If an [FunctionReference] is inserted, returns it; otherwise, returns
  /// [expression].
  ExpressionImpl insertGenericFunctionInstantiation(Expression expression,
      {required DartType? contextType}) {
    expression as ExpressionImpl;
    if (!isConstructorTearoffsEnabled) {
      // Temporarily, only create [ImplicitCallReference] nodes under the
      // 'constructor-tearoffs' feature.
      // TODO(srawlins): When we are ready to make a breaking change release to
      // the analyzer package, remove this exception.
      return expression;
    }

    var staticType = expression.staticType;
    var context = contextType;
    if (context == null ||
        staticType is! FunctionType ||
        staticType.typeFormals.isEmpty) {
      return expression;
    }

    context = typeSystem.flatten(context);
    if (context is! FunctionType || context.typeFormals.isNotEmpty) {
      return expression;
    }

    List<DartType> typeArgumentTypes =
        typeSystem.inferFunctionTypeInstantiation(
      context,
      staticType,
      errorReporter: errorReporter,
      errorNode: expression,
      // If the constructor-tearoffs feature is enabled, then so is
      // generic-metadata.
      genericMetadataIsEnabled: true,
    );
    if (typeArgumentTypes.isNotEmpty) {
      staticType = staticType.instantiate(typeArgumentTypes);
    }

    var parent = expression.parent;
    var genericFunctionInstantiation = astFactory.functionReference(
      function: expression,
      typeArguments: null,
    );
    NodeReplacer.replace(expression, genericFunctionInstantiation,
        parent: parent);

    genericFunctionInstantiation.typeArgumentTypes = typeArgumentTypes;
    genericFunctionInstantiation.staticType = staticType;

    return genericFunctionInstantiation;
  }

  /// If we reached a null-shorting termination, and the [node] has null
  /// shorting, make the type of the [node] nullable.
  void nullShortingTermination(ExpressionImpl node,
      {bool discardType = false}) {
    if (!_isNonNullableByDefault) return;

    if (identical(_unfinishedNullShorts.last, node)) {
      do {
        _unfinishedNullShorts.removeLast();
        flowAnalysis.flow!.nullAwareAccess_end();
      } while (identical(_unfinishedNullShorts.last, node));
      if (node is! CascadeExpression && !discardType) {
        node.staticType = typeSystem.makeNullable(node.staticType as TypeImpl);
      }
    }
  }

  /// If it is appropriate to do so, override the current type of the static
  /// element associated with the given expression with the given type.
  /// Generally speaking, it is appropriate if the given type is more specific
  /// than the current type.
  ///
  /// @param expression the expression used to access the static element whose
  ///        types might be overridden
  /// @param potentialType the potential type of the elements
  /// @param allowPrecisionLoss see @{code overrideVariable} docs
  void overrideExpression(Expression expression, DartType potentialType,
      bool allowPrecisionLoss, bool setExpressionType) {
    // TODO(brianwilkerson) Remove this method.
  }

  /// Set information about enclosing declarations.
  void prepareEnclosingDeclarations({
    ClassElement? enclosingClassElement,
    ExecutableElement? enclosingExecutableElement,
  }) {
    enclosingClass = enclosingClassElement;
    _thisType = enclosingClass?.thisType;
    _enclosingFunction = enclosingExecutableElement;
  }

  /// We are going to resolve [node], without visiting its parent.
  /// Do necessary preparations - set enclosing elements, scopes, etc.
  /// This [ResolverVisitor] instance is fresh, just created.
  ///
  /// Return `true` if we were able to do this, or `false` if it is not
  /// possible to resolve only [node].
  bool prepareForResolving(AstNode node) {
    var parent = node.parent;

    if (parent is CompilationUnit) {
      return node is ClassDeclaration ||
          node is Directive ||
          node is ExtensionDeclaration ||
          node is FunctionDeclaration ||
          node is TopLevelVariableDeclaration;
    }

    void forClassElement(ClassElement parentElement) {
      enclosingClass = parentElement;
    }

    if (parent is ClassDeclaration) {
      forClassElement(parent.declaredElement!);
      return true;
    }

    if (parent is ExtensionDeclaration) {
      enclosingExtension = parent.declaredElement!;
      return true;
    }

    if (parent is MixinDeclaration) {
      forClassElement(parent.declaredElement!);
      return true;
    }

    return false;
  }

  /// Resolve LHS [node] of an assignment, an explicit [AssignmentExpression],
  /// or implicit [PrefixExpression] or [PostfixExpression].
  PropertyElementResolverResult resolveForWrite({
    required AstNode node,
    required bool hasRead,
  }) {
    if (node is IndexExpression) {
      node.target?.accept(this);
      startNullAwareIndexExpression(node);

      var result = _propertyElementResolver.resolveIndexExpression(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );

      analyzeExpression(node.index, result.indexContextType);
      var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(node.index);
      checkIndexExpressionIndex(
        node.index,
        readElement: result.readElement as ExecutableElement?,
        writeElement: result.writeElement as ExecutableElement?,
        whyNotPromoted: whyNotPromoted,
      );

      return result;
    } else if (node is PrefixedIdentifier) {
      node.prefix.accept(this);

      return _propertyElementResolver.resolvePrefixedIdentifier(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );
    } else if (node is PropertyAccess) {
      node.target?.accept(this);
      startNullAwarePropertyAccess(node);

      return _propertyElementResolver.resolvePropertyAccess(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );
    } else if (node is SimpleIdentifierImpl) {
      var result = _propertyElementResolver.resolveSimpleIdentifier(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );

      if (hasRead && result.readElementRequested == null) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
          node,
          [node.name],
        );
      }

      return result;
    } else {
      node.accept(this);
      return PropertyElementResolverResult();
    }
  }

  void setReadElement(Expression node, Element? element) {
    DartType readType = DynamicTypeImpl.instance;
    if (node is IndexExpression) {
      if (element is MethodElement) {
        readType = element.returnType;
      }
    } else if (node is PrefixedIdentifier ||
        node is PropertyAccess ||
        node is SimpleIdentifier) {
      if (element is PropertyAccessorElement && element.isGetter) {
        readType = element.returnType;
      } else if (element is VariableElement) {
        readType = localVariableTypeProvider.getType(node as SimpleIdentifier,
            isRead: true);
      }
    }

    var parent = node.parent;
    if (parent is AssignmentExpressionImpl && parent.leftHandSide == node) {
      parent.readElement = element;
      parent.readType = readType;
    } else if (parent is PostfixExpressionImpl &&
        parent.operator.type.isIncrementOperator) {
      parent.readElement = element;
      parent.readType = readType;
    } else if (parent is PrefixExpressionImpl &&
        parent.operator.type.isIncrementOperator) {
      parent.readElement = element;
      parent.readType = readType;
    }
  }

  @visibleForTesting
  void setThisInterfaceType(InterfaceType thisType) {
    _thisType = thisType;
  }

  void setWriteElement(Expression node, Element? element) {
    DartType writeType = DynamicTypeImpl.instance;
    if (node is IndexExpression) {
      if (element is MethodElement) {
        var parameters = element.parameters;
        if (parameters.length == 2) {
          writeType = parameters[1].type;
        }
      }
    } else if (node is PrefixedIdentifier ||
        node is PropertyAccess ||
        node is SimpleIdentifier) {
      if (element is PropertyAccessorElement && element.isSetter) {
        if (element.isSynthetic) {
          writeType = element.variable.type;
        } else {
          var parameters = element.parameters;
          if (parameters.length == 1) {
            writeType = parameters[0].type;
          }
        }
      } else if (element is VariableElement) {
        writeType = element.type;
      }
    }

    var parent = node.parent;
    if (parent is AssignmentExpressionImpl && parent.leftHandSide == node) {
      parent.writeElement = element;
      parent.writeType = writeType;
    } else if (parent is PostfixExpressionImpl &&
        parent.operator.type.isIncrementOperator) {
      parent.writeElement = element;
      parent.writeType = writeType;
    } else if (parent is PrefixExpressionImpl &&
        parent.operator.type.isIncrementOperator) {
      parent.writeElement = element;
      parent.writeType = writeType;
    }
  }

  void startNullAwareIndexExpression(IndexExpression node) {
    if (_migratableAstInfoProvider.isIndexExpressionNullAware(node)) {
      var flow = flowAnalysis.flow;
      if (flow != null) {
        flow.nullAwareAccess_rightBegin(node.target,
            node.realTarget.staticType ?? typeProvider.dynamicType);
        _unfinishedNullShorts.add(node.nullShortingTermination);
      }
    }
  }

  void startNullAwarePropertyAccess(PropertyAccess node) {
    if (_migratableAstInfoProvider.isPropertyAccessNullAware(node)) {
      var flow = flowAnalysis.flow;
      if (flow != null) {
        var target = node.target;
        if (target is SimpleIdentifier &&
            target.staticElement is ClassElement) {
          // `?.` to access static methods is equivalent to `.`, so do nothing.
        } else {
          flow.nullAwareAccess_rightBegin(
              target, node.realTarget.staticType ?? typeProvider.dynamicType);
          _unfinishedNullShorts.add(node.nullShortingTermination);
        }
      }
    }
  }

  /// Returns the result of an implicit `this.` lookup for the identifier string
  /// [id] in a getter context, or `null` if no match was found.
  LexicalLookupResult? thisLookupGetter(SimpleIdentifier node) {
    return ThisLookup.lookupGetter(this, node);
  }

  /// Returns the result of an implicit `this.` lookup for the identifier string
  /// [id] in a setter context, or `null` if no match was found.
  LexicalLookupResult? thisLookupSetter(SimpleIdentifier node) {
    return ThisLookup.lookupSetter(this, node);
  }

  /// If in a legacy library, return the legacy view on the [element].
  /// Otherwise, return the original element.
  T toLegacyElement<T extends Element?>(T element) {
    if (_isNonNullableByDefault) return element;
    if (element == null) return element;
    return Member.legacy(element) as T;
  }

  /// If in a legacy library, return the legacy version of the [type].
  /// Otherwise, return the original type.
  DartType toLegacyTypeIfOptOut(DartType type) {
    if (_isNonNullableByDefault) return type;
    return NullabilityEliminator.perform(typeProvider, type);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitAdjacentStrings(node as AdjacentStringsImpl,
        contextType: contextType);
  }

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    _annotationResolver.resolve(node, whyNotPromotedList);
    var arguments = node.arguments;
    if (arguments != null) {
      checkForArgumentTypesNotAssignableInList(arguments, whyNotPromotedList);
    }
  }

  @override
  void visitAsExpression(AsExpression node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitAsExpression(node as AsExpressionImpl,
        contextType: contextType);
    flowAnalysis.asExpression(node);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    flowAnalysis.flow?.assert_begin();
    analyzeExpression(node.condition, typeProvider.boolType);
    boolExpressionVerifier.checkForNonBoolExpression(
      node.condition,
      errorCode: CompileTimeErrorCode.NON_BOOL_EXPRESSION,
      whyNotPromoted: flowAnalysis.flow?.whyNotPromoted(node.condition),
    );
    flowAnalysis.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    flowAnalysis.flow?.assert_end();
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    flowAnalysis.flow?.assert_begin();
    analyzeExpression(node.condition, typeProvider.boolType);
    boolExpressionVerifier.checkForNonBoolExpression(
      node.condition,
      errorCode: CompileTimeErrorCode.NON_BOOL_EXPRESSION,
      whyNotPromoted: flowAnalysis.flow?.whyNotPromoted(node.condition),
    );
    flowAnalysis.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    flowAnalysis.flow?.assert_end();
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node,
      {DartType? contextType}) {
    _assignmentExpressionResolver.resolve(node as AssignmentExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
  }

  @override
  void visitAwaitExpression(AwaitExpression node, {DartType? contextType}) {
    DartType? futureUnion;
    if (contextType != null) {
      futureUnion = _createFutureOr(contextType);
    }
    checkUnreachableNode(node);
    analyzeExpression(node.expression, futureUnion);
    typeAnalyzer.visitAwaitExpression(node as AwaitExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
  }

  @override
  void visitBinaryExpression(BinaryExpression node, {DartType? contextType}) {
    var migrationResolutionHooks = this.migrationResolutionHooks;
    if (migrationResolutionHooks != null) {
      migrationResolutionHooks.reportBinaryExpressionContext(node, contextType);
    }
    _binaryExpressionResolver.resolve(node as BinaryExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
  }

  @override
  void visitBlock(Block node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  DartType visitBlockFunctionBody(BlockFunctionBody node,
      {DartType? imposedType}) {
    try {
      inferenceContext.pushFunctionBodyContext(node, imposedType);
      _thisAccessTracker.enterFunctionBody(node);
      checkUnreachableNode(node);
      node.visitChildren(this);
    } finally {
      _thisAccessTracker.exitFunctionBody(node);
      imposedType = inferenceContext.popFunctionBodyContext(node);
    }
    return imposedType;
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node, {DartType? contextType}) {
    flowAnalysis.flow?.booleanLiteral(node, node.value);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitBooleanLiteral(node as BooleanLiteralImpl,
        contextType: contextType);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    checkUnreachableNode(node);
    flowAnalysis.breakStatement(node);
  }

  @override
  void visitCascadeExpression(covariant CascadeExpressionImpl node,
      {DartType? contextType}) {
    analyzeExpression(node.target, contextType);

    if (node.isNullAware) {
      flowAnalysis.flow!.nullAwareAccess_rightBegin(
          node.target, node.target.staticType ?? typeProvider.dynamicType);
      _unfinishedNullShorts.add(node.nullShortingTermination);
    }

    node.cascadeSections.accept(this);

    typeAnalyzer.visitCascadeExpression(node, contextType: contextType);

    nullShortingTermination(node);
    _insertImplicitCallReference(node, contextType: contextType);
  }

  @override
  void visitCatchClause(CatchClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    //
    // Continue the class resolution.
    //
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitClassDeclaration(node);
    } finally {
      enclosingClass = outerType;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitCommentReference(CommentReference node) {
    //
    // We do not visit the expression because it needs to be visited in the
    // context of the reference.
    //
    elementResolver.visitCommentReference(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    NodeList<Directive> directives = node.directives;
    int directiveCount = directives.length;
    for (int i = 0; i < directiveCount; i++) {
      directives[i].accept(this);
    }
    NodeList<CompilationUnitMember> declarations = node.declarations;
    int declarationCount = declarations.length;
    for (int i = 0; i < declarationCount; i++) {
      declarations[i].accept(this);
    }
  }

  @override
  void visitConditionalExpression(ConditionalExpression node,
      {DartType? contextType}) {
    Expression condition = node.condition;
    var flow = flowAnalysis.flow;
    flow?.conditional_conditionBegin();

    // TODO(scheglov) Do we need these checks for null?
    analyzeExpression(node.condition, typeProvider.boolType);
    condition = node.condition;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);
    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);

    if (flow != null) {
      flow.conditional_thenBegin(condition, node);
      checkUnreachableNode(node.thenExpression);
    }
    analyzeExpression(node.thenExpression, contextType);
    nullSafetyDeadCodeVerifier.flowEnd(node.thenExpression);

    Expression elseExpression = node.elseExpression;

    if (flow != null) {
      flow.conditional_elseBegin(node.thenExpression);
      checkUnreachableNode(elseExpression);
      analyzeExpression(elseExpression, contextType);
      flow.conditional_end(node, elseExpression);
      nullSafetyDeadCodeVerifier.flowEnd(elseExpression);
    } else {
      analyzeExpression(elseExpression, contextType);
    }
    elseExpression = node.elseExpression;

    typeAnalyzer.visitConditionalExpression(node as ConditionalExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(node, contextType: contextType);
  }

  @override
  void visitConfiguration(Configuration node) {
    // Don't visit the children. For the time being we don't resolve anything
    // inside the configuration.
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    flowAnalysis.topLevelDeclaration_enter(node, node.parameters);
    flowAnalysis.executableDeclaration_enter(node, node.parameters,
        isClosure: false);

    var returnType = node.declaredElement!.type.returnType;

    var outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.declaredElement;
      assert(_thisType == null);
      _setupThisType();
      checkUnreachableNode(node);
      node.documentationComment?.accept(this);
      node.metadata.accept(this);
      node.returnType.accept(this);
      node.name?.accept(this);
      node.parameters.accept(this);
      node.initializers.accept(this);
      node.redirectedConstructor?.accept(this);
      node.body.resolve(this, returnType.isDynamic ? null : returnType);
      elementResolver.visitConstructorDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
      _thisType = null;
    }

    if (node.factoryKeyword != null) {
      checkForBodyMayCompleteNormally(
        body: node.body,
        errorNode: node,
      );
    }
    flowAnalysis.executableDeclaration_exit(node.body, false);
    flowAnalysis.topLevelDeclaration_exit();
    nullSafetyDeadCodeVerifier.flowEnd(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    //
    // We visit the expression, but do not visit the field name because it needs
    // to be visited in the context of the constructor field initializer node.
    //
    var fieldElement = enclosingClass!.getField(node.fieldName.name);
    var fieldType = fieldElement?.type;
    var expression = node.expression;
    analyzeExpression(expression, fieldType);
    expression = node.expression;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(expression);
    elementResolver.visitConstructorFieldInitializer(
        node as ConstructorFieldInitializerImpl);
    if (fieldElement != null) {
      var enclosingConstructor = enclosingFunction as ConstructorElement;
      checkForFieldInitializerNotAssignable(node, fieldElement,
          isConstConstructor: enclosingConstructor.isConst,
          whyNotPromoted: whyNotPromoted);
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.type.accept(this);
    elementResolver.visitConstructorName(node as ConstructorNameImpl);
  }

  @override
  void visitConstructorReference(covariant ConstructorReferenceImpl node,
      {DartType? contextType}) {
    _constructorReferenceResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(node, contextType: contextType);
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    checkUnreachableNode(node);
    flowAnalysis.continueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitDeclaredIdentifier(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    checkUnreachableNode(node);
    node.parameter.accept(this);
    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      analyzeExpression(defaultValue, node.declaredElement?.type);
    }
    ParameterElement element = node.declaredElement!;

    if (element is DefaultParameterElementImpl && node.isOfLocalFunction) {
      element.constantInitializer = defaultValue;
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    checkUnreachableNode(node);

    var condition = node.condition;

    flowAnalysis.flow?.doStatement_bodyBegin(node);
    node.body.accept(this);

    flowAnalysis.flow?.doStatement_conditionBegin();
    analyzeExpression(condition, typeProvider.boolType);
    condition = node.condition;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);
    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);

    flowAnalysis.flow?.doStatement_end(condition);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitDoubleLiteral(node as DoubleLiteralImpl,
        contextType: contextType);
  }

  @override
  DartType visitEmptyFunctionBody(EmptyFunctionBody node,
      {DartType? imposedType}) {
    if (!resolveOnlyCommentInFunctionBody) {
      checkUnreachableNode(node);
      node.visitChildren(this);
    }
    return imposedType ?? typeProvider.dynamicType;
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitEnumConstantArguments(EnumConstantArguments node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node as EnumConstantDeclarationImpl;

    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    checkUnreachableNode(node);

    var element = node.declaredElement as ConstFieldElementImpl;
    var initializer = element.constantInitializer;
    if (initializer is InstanceCreationExpression) {
      var constructorName = initializer.constructorName;
      var constructorElement = constructorName.staticElement;
      if (constructorElement != null) {
        node.constructorElement = constructorElement;
        if (!constructorElement.isConst && constructorElement.isFactory) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.ENUM_CONSTANT_WITH_NON_CONST_CONSTRUCTOR,
            node.arguments?.constructorSelector?.name ?? node.name,
          );
        }
      } else {
        var typeName = constructorName.type.name;
        if (typeName.staticElement is EnumElementImpl) {
          var nameNode = node.arguments?.constructorSelector?.name;
          if (nameNode != null) {
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_NAMED,
              nameNode,
              [nameNode.name],
            );
          } else {
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED,
              node.name,
            );
          }
        }
      }
      if (constructorElement != null) {
        var arguments = node.arguments;
        if (arguments != null) {
          var argumentList = arguments.argumentList;
          argumentList.correspondingStaticParameters =
              ResolverVisitor.resolveArgumentsToParameters(
            argumentList: argumentList,
            parameters: constructorElement.parameters,
            errorReporter: errorReporter,
          );
          for (var argument in argumentList.arguments) {
            analyzeExpression(argument, argument.staticParameterElement?.type);
          }
          arguments.typeArguments?.accept(this);

          var whyNotPromotedList =
              <Map<DartType, NonPromotionReason> Function()>[];
          checkForArgumentTypesNotAssignableInList(
              argumentList, whyNotPromotedList);
        } else if (definingLibrary.featureSet
            .isEnabled(Feature.enhanced_enums)) {
          var requiredParameterCount = constructorElement.parameters
              .where((e) => e.isRequiredPositional)
              .length;
          if (requiredParameterCount != 0) {
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS,
              node.name,
              [requiredParameterCount, 0],
            );
          }
        }
      }
    }

    elementResolver.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    //
    // Continue the enum resolution.
    //
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitEnumDeclaration(node);
    } finally {
      enclosingClass = outerType;
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitExportDirective(node);
  }

  @override
  DartType visitExpressionFunctionBody(ExpressionFunctionBody node,
      {DartType? imposedType}) {
    if (resolveOnlyCommentInFunctionBody) {
      return imposedType ?? typeProvider.dynamicType;
    }

    try {
      inferenceContext.pushFunctionBodyContext(node, imposedType);
      _thisAccessTracker.enterFunctionBody(node);

      checkUnreachableNode(node);
      analyzeExpression(
        node.expression,
        inferenceContext.bodyContext!.contextType,
      );

      flowAnalysis.flow?.handleExit();

      inferenceContext.bodyContext!.addReturnExpression(node.expression);
    } finally {
      _thisAccessTracker.exitFunctionBody(node);
      imposedType = inferenceContext.popFunctionBodyContext(node);
    }
    return imposedType;
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var outerExtension = enclosingExtension;
    try {
      enclosingExtension = node.declaredElement!;
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitExtensionDeclaration(node);
    } finally {
      enclosingExtension = outerExtension;
    }
  }

  @override
  void visitExtensionOverride(covariant ExtensionOverrideImpl node,
      {DartType? contextType}) {
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    node.extensionName.accept(this);
    node.typeArguments?.accept(this);

    var receiverContextType =
        ExtensionMemberResolver(this).computeOverrideReceiverContextType(node);
    InvocationInferrer<ExtensionOverrideImpl>(
            resolver: this,
            node: node,
            argumentList: node.argumentList,
            contextType: null,
            whyNotPromotedList: whyNotPromotedList)
        .resolveInvocation(
            rawType: receiverContextType == null
                ? null
                : FunctionTypeImpl(
                    typeFormals: const [],
                    parameters: [
                        ParameterElementImpl.synthetic(
                            null, receiverContextType, ParameterKind.REQUIRED)
                      ],
                    returnType: DynamicTypeImpl.instance,
                    nullabilitySuffix: NullabilitySuffix.none));

    extensionResolver.resolveOverride(node, whyNotPromotedList);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _thisAccessTracker.enterFieldDeclaration(node);
    try {
      assert(_thisType == null);
      _setupThisType();
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitFieldDeclaration(node);
    } finally {
      _thisAccessTracker.exitFieldDeclaration(node);
      _thisType = null;
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitFieldFormalParameter(node);
  }

  @override
  void visitForElement(ForElement node, {CollectionLiteralContext? context}) {
    _forResolver.resolveElement(node as ForElementImpl, context);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitForStatement(ForStatement node) {
    _forResolver.resolveStatement(node as ForStatementImpl);
    nullSafetyDeadCodeVerifier.flowEnd(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    bool isLocal = node.parent is FunctionDeclarationStatement;

    if (isLocal) {
      flowAnalysis.flow!.functionExpression_begin(node);
    } else {
      flowAnalysis.topLevelDeclaration_enter(
          node, node.functionExpression.parameters);
    }
    flowAnalysis.executableDeclaration_enter(
      node,
      node.functionExpression.parameters,
      isClosure: isLocal,
    );

    var functionType = node.declaredElement!.type;

    var outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.declaredElement;
      checkUnreachableNode(node);
      node.documentationComment?.accept(this);
      node.metadata.accept(this);
      node.returnType?.accept(this);
      node.name.accept(this);
      analyzeExpression(node.functionExpression, functionType);
      elementResolver.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }

    if (!node.isSetter) {
      checkForBodyMayCompleteNormally(
        body: node.functionExpression.body,
        errorNode: node.name,
      );
    }
    flowAnalysis.executableDeclaration_exit(
      node.functionExpression.body,
      isLocal,
    );
    if (isLocal) {
      flowAnalysis.flow!.functionExpression_end();
    } else {
      flowAnalysis.topLevelDeclaration_exit();
    }
    nullSafetyDeadCodeVerifier.flowEnd(node);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node,
      {DartType? contextType}) {
    var outerFunction = _enclosingFunction;
    _enclosingFunction = node.declaredElement;

    _functionExpressionResolver.resolve(node, contextType: contextType);
    insertGenericFunctionInstantiation(node, contextType: contextType);

    _enclosingFunction = outerFunction;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node,
      {DartType? contextType}) {
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    node.function.accept(this);
    _functionExpressionInvocationResolver.resolve(
        node as FunctionExpressionInvocationImpl, whyNotPromotedList,
        contextType: contextType);
    nullShortingTermination(node);
    var replacement =
        insertGenericFunctionInstantiation(node, contextType: contextType);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
    _insertImplicitCallReference(replacement, contextType: contextType);
  }

  @override
  void visitFunctionReference(FunctionReference node, {DartType? contextType}) {
    _functionReferenceResolver.resolve(node as FunctionReferenceImpl);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitGenericTypeAlias(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {}

  @override
  void visitIfElement(IfElement node, {CollectionLiteralContext? context}) {
    flowAnalysis.flow?.ifStatement_conditionBegin();
    Expression condition = node.condition;
    analyzeExpression(condition, typeProvider.boolType);
    condition = node.condition;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);

    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);

    flowAnalysis.flow?.ifStatement_thenBegin(condition, node);
    (node.thenElement as CollectionElementImpl).resolveElement(this, context);
    nullSafetyDeadCodeVerifier.flowEnd(node.thenElement);

    var elseElement = node.elseElement;
    if (elseElement != null) {
      flowAnalysis.flow?.ifStatement_elseBegin();
      (elseElement as CollectionElementImpl).resolveElement(this, context);
      nullSafetyDeadCodeVerifier.flowEnd(elseElement);
    }

    flowAnalysis.flow?.ifStatement_end(elseElement != null);
  }

  @override
  void visitIfStatement(IfStatement node) {
    checkUnreachableNode(node);
    flowAnalysis.flow?.ifStatement_conditionBegin();

    Expression condition = node.condition;

    analyzeExpression(condition, typeProvider.boolType);
    condition = node.condition;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);

    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);

    flowAnalysis.flow?.ifStatement_thenBegin(condition, node);
    node.thenStatement.accept(this);
    nullSafetyDeadCodeVerifier.flowEnd(node.thenStatement);

    var elseStatement = node.elseStatement;
    if (elseStatement != null) {
      flowAnalysis.flow?.ifStatement_elseBegin();
      elseStatement.accept(this);
      nullSafetyDeadCodeVerifier.flowEnd(elseStatement);
    }

    flowAnalysis.flow?.ifStatement_end(elseStatement != null);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node,
      {DartType? contextType}) {
    checkUnreachableNode(node);
    analyzeExpression(node.expression, null);
    node.typeArguments?.accept(this);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitImportDirective(node as ImportDirectiveImpl);
  }

  @override
  void visitIndexExpression(covariant IndexExpressionImpl node,
      {DartType? contextType}) {
    node.target?.accept(this);
    startNullAwareIndexExpression(node);

    var result = _propertyElementResolver.resolveIndexExpression(
      node: node,
      hasRead: true,
      hasWrite: false,
    );

    var element = result.readElement;
    node.staticElement = element as MethodElement?;

    analyzeExpression(node.index, result.indexContextType);
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(node.index);
    checkIndexExpressionIndex(
      node.index,
      readElement: result.readElement as ExecutableElement?,
      writeElement: null,
      whyNotPromoted: whyNotPromoted,
    );

    DartType type;
    if (identical(node.realTarget.staticType, NeverTypeImpl.instance)) {
      type = NeverTypeImpl.instance;
    } else if (element is MethodElement) {
      type = element.returnType;
    } else {
      type = DynamicTypeImpl.instance;
    }
    inferenceHelper.recordStaticType(node, type, contextType: contextType);
    var replacement =
        insertGenericFunctionInstantiation(node, contextType: contextType);

    nullShortingTermination(node);
    _insertImplicitCallReference(replacement, contextType: contextType);
  }

  @override
  void visitInstanceCreationExpression(
      covariant InstanceCreationExpressionImpl node,
      {DartType? contextType}) {
    _instanceCreationExpressionResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(node, contextType: contextType);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitIntegerLiteral(node as IntegerLiteralImpl,
        contextType: contextType);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitIsExpression(IsExpression node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitIsExpression(node as IsExpressionImpl,
        contextType: contextType);
    flowAnalysis.isExpression(node);
  }

  @override
  void visitLabel(Label node) {}

  @override
  void visitLabeledStatement(LabeledStatement node) {
    flowAnalysis.labeledStatement_enter(node);
    checkUnreachableNode(node);
    node.visitChildren(this);
    flowAnalysis.labeledStatement_exit(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitLibraryDirective(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node,
      {DartType? contextType}) {}

  @override
  void visitListLiteral(covariant ListLiteralImpl node,
      {DartType? contextType}) {
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveListLiteral(node, contextType: contextType);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node,
      {CollectionLiteralContext? context}) {
    checkUnreachableNode(node);
    analyzeExpression(node.key, context?.keyType);
    analyzeExpression(node.value, context?.valueType);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    flowAnalysis.topLevelDeclaration_enter(node, node.parameters);
    flowAnalysis.executableDeclaration_enter(node, node.parameters,
        isClosure: false);

    DartType returnType = node.declaredElement!.returnType;

    var outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.declaredElement;
      assert(_thisType == null);
      _setupThisType();
      checkUnreachableNode(node);
      node.documentationComment?.accept(this);
      node.metadata.accept(this);
      node.returnType?.accept(this);
      node.name.accept(this);
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      node.body.resolve(this, returnType.isDynamic ? null : returnType);
      elementResolver.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
      _thisType = null;
    }

    if (!node.isSetter) {
      checkForBodyMayCompleteNormally(
        body: node.body,
        errorNode: node.name,
      );
    }
    flowAnalysis.executableDeclaration_exit(node.body, false);
    flowAnalysis.topLevelDeclaration_exit();
    nullSafetyDeadCodeVerifier.flowEnd(node);
  }

  @override
  void visitMethodInvocation(covariant MethodInvocationImpl node,
      {DartType? contextType}) {
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    var target = node.target;
    target?.accept(this);
    target = node.target;

    if (_migratableAstInfoProvider.isMethodInvocationNullAware(node)) {
      var flow = flowAnalysis.flow;
      if (flow != null) {
        if (target is SimpleIdentifierImpl &&
            target.staticElement is ClassElement) {
          // `?.` to access static methods is equivalent to `.`, so do nothing.
        } else {
          flow.nullAwareAccess_rightBegin(
              target, node.realTarget!.staticType ?? typeProvider.dynamicType);
          _unfinishedNullShorts.add(node.nullShortingTermination);
        }
      }
    }

    node.typeArguments?.accept(this);
    elementResolver.visitMethodInvocation(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);

    var functionRewrite = MethodInvocationResolver.getRewriteResult(node);
    if (functionRewrite != null) {
      _resolveRewrittenFunctionExpressionInvocation(
          functionRewrite, whyNotPromotedList,
          contextType: contextType);
      nullShortingTermination(node, discardType: true);
    } else {
      nullShortingTermination(node);
    }
    var replacement =
        insertGenericFunctionInstantiation(node, contextType: contextType);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
    _insertImplicitCallReference(replacement, contextType: contextType);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    //
    // Continue the class resolution.
    //
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement!;
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitMixinDeclaration(node);
    } finally {
      enclosingClass = outerType;
    }
  }

  @override
  void visitNamedExpression(NamedExpression node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.name.accept(this);
    analyzeExpression(node.expression, contextType);
    typeAnalyzer.visitNamedExpression(node as NamedExpressionImpl,
        contextType: contextType);
    // Any "why not promoted" information that flow analysis had associated with
    // `node.expression` now needs to be forwarded to `node`, so that when
    // `visitArgumentList` iterates through the arguments, it will find it.
    flowAnalysis.flow?.forwardExpression(node, node.expression);
  }

  @override
  void visitNamedType(NamedType node) {
    // All TypeName(s) are already resolved, so we don't resolve it here.
    // But there might be type arguments with Expression(s), such as default
    // values for formal parameters of GenericFunctionType(s). These are
    // invalid, but if they exist, they should be resolved.
    node.typeArguments?.accept(this);
  }

  @override
  void visitNativeClause(NativeClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  DartType visitNativeFunctionBody(NativeFunctionBody node,
      {DartType? imposedType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    return imposedType ?? typeProvider.dynamicType;
  }

  @override
  void visitNullLiteral(NullLiteral node, {DartType? contextType}) {
    flowAnalysis.flow?.nullLiteral(node);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitNullLiteral(node as NullLiteralImpl,
        contextType: contextType);
  }

  @override
  void visitOnClause(OnClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node,
      {DartType? contextType}) {
    checkUnreachableNode(node);
    analyzeExpression(node.expression, contextType);
    typeAnalyzer.visitParenthesizedExpression(
        node as ParenthesizedExpressionImpl,
        contextType: contextType);
    flowAnalysis.flow?.parenthesizedExpression(node, node.expression);
  }

  @override
  void visitPartDirective(PartDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitPartOfDirective(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node, {DartType? contextType}) {
    _postfixExpressionResolver.resolve(node as PostfixExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
  }

  @override
  void visitPrefixedIdentifier(covariant PrefixedIdentifierImpl node,
      {DartType? contextType}) {
    _prefixedIdentifierResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
  }

  @override
  void visitPrefixExpression(PrefixExpression node, {DartType? contextType}) {
    _prefixExpressionResolver.resolve(node as PrefixExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
  }

  @override
  void visitPropertyAccess(covariant PropertyAccessImpl node,
      {DartType? contextType}) {
    node.target?.accept(this);
    startNullAwarePropertyAccess(node);

    var result = _propertyElementResolver.resolvePropertyAccess(
      node: node,
      hasRead: true,
      hasWrite: false,
    );

    var element = result.readElement;

    var propertyName = node.propertyName;
    propertyName.staticElement = element;

    DartType type;
    if (element is MethodElement) {
      type = element.type;
    } else if (element is PropertyAccessorElement && element.isGetter) {
      type = element.returnType;
    } else if (result.functionTypeCallType != null) {
      type = result.functionTypeCallType!;
    } else {
      type = DynamicTypeImpl.instance;
    }

    if (!isConstructorTearoffsEnabled) {
      // Only perform a generic function instantiation on a [PrefixedIdentifier]
      // in pre-constructor-tearoffs code. In constructor-tearoffs-enabled code,
      // generic function instantiation is performed at assignability check
      // sites.
      // TODO(srawlins): Switch all resolution to use the latter method, in a
      // breaking change release.
      type = inferenceHelper.inferTearOff(node, propertyName, type,
          contextType: contextType);
    }

    inferenceHelper.recordStaticType(propertyName, type, contextType: null);
    inferenceHelper.recordStaticType(node, type, contextType: contextType);
    var replacement =
        insertGenericFunctionInstantiation(node, contextType: contextType);

    nullShortingTermination(node);
    _insertImplicitCallReference(replacement, contextType: contextType);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    elementResolver.visitRedirectingConstructorInvocation(
        node as RedirectingConstructorInvocationImpl);
    InvocationInferrer<RedirectingConstructorInvocationImpl>(
            resolver: this,
            node: node,
            argumentList: node.argumentList,
            contextType: null,
            whyNotPromotedList: whyNotPromotedList)
        .resolveInvocation(rawType: node.staticElement?.type);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
  }

  @override
  void visitRethrowExpression(RethrowExpression node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitRethrowExpression(node as RethrowExpressionImpl,
        contextType: contextType);
    flowAnalysis.flow?.handleExit();
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    checkUnreachableNode(node);
    var expression = node.expression;
    if (expression != null) {
      analyzeExpression(
        expression,
        inferenceContext.bodyContext?.contextType,
      );
      // Pick up the expression again in case it was rewritten.
      expression = node.expression;
    }

    inferenceContext.bodyContext?.addReturnExpression(expression);
    flowAnalysis.flow?.handleExit();
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node, {DartType? contextType}) {
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveSetOrMapLiteral(node,
        contextType: contextType);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {}

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(covariant SimpleIdentifierImpl node,
      {DartType? contextType}) {
    _simpleIdentifierResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node,
      {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitSimpleStringLiteral(node as SimpleStringLiteralImpl,
        contextType: contextType);
  }

  @override
  void visitSpreadElement(SpreadElement node,
      {CollectionLiteralContext? context}) {
    var iterableType = context?.iterableType;
    if (iterableType != null && _isNonNullableByDefault && node.isNullAware) {
      iterableType = typeSystem.makeNullable(iterableType);
    }
    checkUnreachableNode(node);
    analyzeExpression(node.expression, iterableType);

    if (!node.isNullAware) {
      nullableDereferenceVerifier.expression(
        CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD,
        node.expression,
      );
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node,
      {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitStringInterpolation(node as StringInterpolationImpl,
        contextType: contextType);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    elementResolver.visitSuperConstructorInvocation(
        node as SuperConstructorInvocationImpl);
    InvocationInferrer<SuperConstructorInvocationImpl>(
            resolver: this,
            node: node,
            argumentList: node.argumentList,
            contextType: null,
            whyNotPromotedList: whyNotPromotedList)
        .resolveInvocation(rawType: node.staticElement?.type);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
  }

  @override
  void visitSuperExpression(SuperExpression node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitSuperExpression(node);
    typeAnalyzer.visitSuperExpression(node as SuperExpressionImpl,
        contextType: contextType);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    checkUnreachableNode(node);

    checkUnreachableNode(node);
    node.labels.accept(this);
    analyzeExpression(node.expression, _enclosingSwitchStatementExpressionType);
    node.statements.accept(this);

    var flow = flowAnalysis.flow;
    if (flow != null && flow.isReachable && _isNonNullableByDefault) {
      var switchStatement = node.parent as SwitchStatement;
      if (switchStatement.members.last != node && node.statements.isNotEmpty) {
        errorReporter.reportErrorForToken(
          CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY,
          node.keyword,
        );
      }
    }

    nullSafetyDeadCodeVerifier.flowEnd(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    nullSafetyDeadCodeVerifier.flowEnd(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    checkUnreachableNode(node);

    var previousExpressionType = _enclosingSwitchStatementExpressionType;
    try {
      var expression = node.expression;
      expression.accept(this);
      expression = node.expression;

      _enclosingSwitchStatementExpressionType = expression.typeOrThrow;

      var flow = flowAnalysis.flow!;

      flow.switchStatement_expressionEnd(node);

      var exhaustiveness = _SwitchExhaustiveness(
        _enclosingSwitchStatementExpressionType!,
      );

      var members = node.members;
      for (var member in members) {
        flow.switchStatement_beginCase(member.labels.isNotEmpty, node);
        member.accept(this);

        exhaustiveness.visitSwitchMember(member);
      }

      flow.switchStatement_end(exhaustiveness.isExhaustive);
    } finally {
      _enclosingSwitchStatementExpressionType = previousExpressionType;
    }
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitSymbolLiteral(node as SymbolLiteralImpl,
        contextType: contextType);
  }

  @override
  void visitThisExpression(ThisExpression node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitThisExpression(node as ThisExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(node, contextType: contextType);
  }

  @override
  void visitThrowExpression(ThrowExpression node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitThrowExpression(node as ThrowExpressionImpl,
        contextType: contextType);
    flowAnalysis.flow?.handleExit();
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    checkUnreachableNode(node);
    var flow = flowAnalysis.flow!;

    var body = node.body;
    var catchClauses = node.catchClauses;
    var finallyBlock = node.finallyBlock;

    if (finallyBlock != null) {
      flow.tryFinallyStatement_bodyBegin();
    }

    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyBegin();
    }
    body.accept(this);
    nullSafetyDeadCodeVerifier.flowEnd(node.body);
    nullSafetyDeadCodeVerifier.tryStatementEnter(node);
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyEnd(body);

      var catchLength = catchClauses.length;
      for (var i = 0; i < catchLength; ++i) {
        var catchClause = catchClauses[i];
        nullSafetyDeadCodeVerifier.verifyCatchClause(catchClause);
        flow.tryCatchStatement_catchBegin(
          catchClause.exceptionParameter?.staticElement as PromotableElement?,
          catchClause.stackTraceParameter?.staticElement as PromotableElement?,
        );
        catchClause.accept(this);
        flow.tryCatchStatement_catchEnd();
        nullSafetyDeadCodeVerifier.flowEnd(catchClause.body);
      }

      flow.tryCatchStatement_end();
    }
    nullSafetyDeadCodeVerifier.tryStatementExit(node);

    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(
          catchClauses.isNotEmpty ? node : body);
      finallyBlock.accept(this);
      flow.tryFinallyStatement_end();
    }
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteral(TypeLiteral node, {DartType? contextType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _variableDeclarationResolver.resolve(node as VariableDeclarationImpl);

    var declaredElement = node.declaredElement!;

    var initializer = node.initializer;
    var parent = node.parent as VariableDeclarationList;
    var declaredType = parent.type;
    if (initializer != null) {
      var initializerStaticType = initializer.typeOrThrow;
      flowAnalysis.flow?.initialize(declaredElement as PromotableElement,
          initializerStaticType, initializer,
          isFinal: parent.isFinal,
          isLate: parent.isLate,
          isImplicitlyTyped: declaredType == null);
    }
    _checkTopLevelCycle(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    flowAnalysis.variableDeclarationList(node);
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    checkUnreachableNode(node);

    Expression condition = node.condition;

    flowAnalysis.flow?.whileStatement_conditionBegin(node);
    analyzeExpression(condition, typeProvider.boolType);
    condition = node.condition;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);

    boolExpressionVerifier.checkForNonBoolCondition(node.condition,
        whyNotPromoted: whyNotPromoted);

    flowAnalysis.flow?.whileStatement_bodyBegin(node, condition);
    node.body.accept(this);
    flowAnalysis.flow?.whileStatement_end();
    nullSafetyDeadCodeVerifier.flowEnd(node.body);
    // TODO(brianwilkerson) If the loop can only be exited because the condition
    // is false, then propagateFalseState(condition);
  }

  @override
  void visitWithClause(WithClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _yieldStatementResolver.resolve(node);
  }

  void _checkTopLevelCycle(VariableDeclaration node) {
    var element = node.declaredElement;
    if (element is! PropertyInducingElementImpl) {
      return;
    }
    // Errors on const are reported separately with
    // [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT].
    if (element.isConst) {
      return;
    }
    var error = element.typeInferenceError;
    if (error == null) {
      return;
    }
    if (error.kind == TopLevelInferenceErrorKind.dependencyCycle) {
      var argumentsText = error.arguments.join(', ');
      errorReporter.reportErrorForNode(CompileTimeErrorCode.TOP_LEVEL_CYCLE,
          node.name, [node.name.name, argumentsText]);
    }
  }

  /// Creates a union of `T | Future<T>`, unless `T` is already a
  /// future-union, in which case it simply returns `T`.
  DartType _createFutureOr(DartType type) {
    if (type.isDartAsyncFutureOr) {
      return type;
    }
    return typeProvider.futureOrType(type);
  }

  /// If `expression` should be treated as `expression.call`, inserts an
  /// [ImplicitCallReference] node which wraps [expression].
  void _insertImplicitCallReference(ExpressionImpl expression,
      {required DartType? contextType}) {
    var parent = expression.parent;
    if (_shouldSkipImplicitCallReferenceDueToForm(expression, parent)) {
      return;
    }
    var staticType = expression.staticType;
    if (staticType == null) {
      return;
    }
    DartType? context;
    if (parent is AssignmentExpression) {
      context = parent.writeType;
    } else {
      context = contextType;
    }
    var callMethod = getImplicitCallMethod(staticType, context, expression);
    if (callMethod == null || context == null) {
      return;
    }

    // `expression` is to be treated as `expression.call`.
    context = typeSystem.flatten(context);
    var callMethodType = callMethod.type;
    List<DartType> typeArgumentTypes;
    if (isConstructorTearoffsEnabled &&
        callMethodType.typeFormals.isNotEmpty &&
        context is FunctionType) {
      typeArgumentTypes = typeSystem.inferFunctionTypeInstantiation(
        context,
        callMethodType,
        errorReporter: errorReporter,
        errorNode: expression,
        // If the constructor-tearoffs feature is enabled, then so is
        // generic-metadata.
        genericMetadataIsEnabled: true,
      );
      if (typeArgumentTypes.isNotEmpty) {
        callMethodType = callMethodType.instantiate(typeArgumentTypes);
      }
    } else {
      typeArgumentTypes = [];
    }

    var callReference = astFactory.implicitCallReference(
      expression: expression,
      staticElement: callMethod,
      typeArguments: null,
      typeArgumentTypes: typeArgumentTypes,
    );
    NodeReplacer.replace(expression, callReference, parent: parent);

    callReference.staticType = callMethodType;
  }

  /// Continues resolution of a [FunctionExpressionInvocation] that was created
  /// from a rewritten [MethodInvocation]. The target function is already
  /// resolved.
  ///
  /// The specification says that `target.getter()` should be treated as an
  /// ordinary method invocation. So, we need to perform the same null shorting
  /// as for method invocations.
  void _resolveRewrittenFunctionExpressionInvocation(
      FunctionExpressionInvocation node,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    var function = node.function;

    if (function is PropertyAccess &&
        _migratableAstInfoProvider.isPropertyAccessNullAware(function) &&
        _isNonNullableByDefault) {
      var target = function.target;
      if (target is SimpleIdentifier && target.staticElement is ClassElement) {
        // `?.` to access static methods is equivalent to `.`, so do nothing.
      } else {
        flowAnalysis.flow!.nullAwareAccess_rightBegin(function,
            function.realTarget.staticType ?? typeProvider.dynamicType);
        _unfinishedNullShorts.add(node.nullShortingTermination);
      }
    }

    _functionExpressionInvocationResolver.resolve(
        node as FunctionExpressionInvocationImpl, whyNotPromotedList,
        contextType: contextType);

    nullShortingTermination(node);
  }

  void _setupThisType() {
    var enclosingClass = this.enclosingClass;
    if (enclosingClass != null) {
      _thisType = enclosingClass.thisType;
    } else {
      var enclosingExtension = this.enclosingExtension;
      if (enclosingExtension != null) {
        _thisType = enclosingExtension.extendedType;
      }
    }
  }

  bool _shouldSkipImplicitCallReferenceDueToForm(
      Expression expression, AstNode? parent) {
    while (parent is ParenthesizedExpression) {
      expression = parent;
      parent = expression.parent;
    }
    if (parent is CascadeExpression && parent.target == expression) {
      // Do not perform an "implicit tear-off conversion" here. It should only
      // be performed on [parent]. See
      // https://github.com/dart-lang/language/issues/1873.
      return true;
    }
    if (parent is ConditionalExpression &&
        (parent.thenExpression == expression ||
            parent.elseExpression == expression)) {
      // Do not perform an "implicit tear-off conversion" on the branches of a
      // conditional expression.
      return true;
    }
    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.QUESTION_QUESTION) {
      // Do not perform an "implicit tear-off conversion" on the branches of a
      // `??` operator.
      return true;
    }
    return false;
  }

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments.
  ///
  /// Returns the parameters that correspond to the arguments. If no parameter
  /// matched an argument, that position will be `null` in the list.
  static List<ParameterElement?> resolveArgumentsToParameters({
    required ArgumentList argumentList,
    required List<ParameterElement> parameters,
    ErrorReporter? errorReporter,
    ConstructorDeclaration? enclosingConstructor,
  }) {
    int requiredParameterCount = 0;
    int unnamedParameterCount = 0;
    List<ParameterElement> unnamedParameters = <ParameterElement>[];
    Map<String, ParameterElement>? namedParameters;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      ParameterElement parameter = parameters[i];
      if (parameter.isRequiredPositional) {
        unnamedParameters.add(parameter);
        unnamedParameterCount++;
        requiredParameterCount++;
      } else if (parameter.isOptionalPositional) {
        unnamedParameters.add(parameter);
        unnamedParameterCount++;
      } else {
        namedParameters ??= HashMap<String, ParameterElement>();
        namedParameters[parameter.name] = parameter;
      }
    }
    int unnamedIndex = 0;
    NodeList<Expression> arguments = argumentList.arguments;
    int argumentCount = arguments.length;
    List<ParameterElement?> resolvedParameters =
        List<ParameterElement?>.filled(argumentCount, null);
    int positionalArgumentCount = 0;
    bool noBlankArguments = true;
    Expression? firstUnresolvedArgument;
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is! NamedExpressionImpl) {
        if (argument is SimpleIdentifier && argument.name.isEmpty) {
          noBlankArguments = false;
        }
        positionalArgumentCount++;
        if (unnamedIndex < unnamedParameterCount) {
          resolvedParameters[i] = unnamedParameters[unnamedIndex++];
        } else {
          firstUnresolvedArgument ??= argument;
        }
      }
    }

    Set<String>? usedNames;
    if (enclosingConstructor != null) {
      var result = verifySuperFormalParameters(
        constructor: enclosingConstructor,
        hasExplicitPositionalArguments: positionalArgumentCount != 0,
        errorReporter: errorReporter,
      );
      positionalArgumentCount += result.positionalArgumentCount;
      if (result.namedArgumentNames.isNotEmpty) {
        usedNames = result.namedArgumentNames.toSet();
      }
    }

    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpressionImpl) {
        var nameNode = argument.name.label;
        String name = nameNode.name;
        var element = namedParameters != null ? namedParameters[name] : null;
        if (element == null) {
          errorReporter?.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, nameNode, [name]);
        } else {
          resolvedParameters[i] = element;
          nameNode.staticElement = element;
        }
        usedNames ??= <String>{};
        if (!usedNames.add(name)) {
          errorReporter?.reportErrorForNode(
              CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, nameNode, [name]);
        }
      }
    }

    if (positionalArgumentCount < requiredParameterCount && noBlankArguments) {
      errorReporter?.reportErrorForNode(
          CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS,
          argumentList,
          [requiredParameterCount, positionalArgumentCount]);
    } else if (positionalArgumentCount > unnamedParameterCount &&
        noBlankArguments) {
      ErrorCode errorCode;
      int namedParameterCount = namedParameters?.length ?? 0;
      int namedArgumentCount = usedNames?.length ?? 0;
      if (namedParameterCount > namedArgumentCount) {
        errorCode =
            CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED;
      } else {
        errorCode = CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS;
      }
      if (firstUnresolvedArgument != null) {
        errorReporter?.reportErrorForNode(errorCode, firstUnresolvedArgument,
            [unnamedParameterCount, positionalArgumentCount]);
      }
    }
    return resolvedParameters;
  }
}

/// Override of [ResolverVisitorForMigration] that invokes methods of
/// [MigrationResolutionHooks] when appropriate.
class ResolverVisitorForMigration extends ResolverVisitor {
  final MigrationResolutionHooks _migrationResolutionHooks;

  ResolverVisitorForMigration(
      InheritanceManager3 inheritanceManager,
      LibraryElementImpl definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      TypeSystemImpl typeSystem,
      FeatureSet featureSet,
      MigrationResolutionHooks migrationResolutionHooks)
      : _migrationResolutionHooks = migrationResolutionHooks,
        super._(
            inheritanceManager,
            definingLibrary,
            source,
            typeSystem,
            typeProvider as TypeProviderImpl,
            errorListener,
            featureSet,
            FlowAnalysisHelperForMigration(
                typeSystem, migrationResolutionHooks, featureSet),
            migrationResolutionHooks,
            migrationResolutionHooks);

  @override
  void visitConditionalExpression(covariant ConditionalExpressionImpl node,
      {DartType? contextType}) {
    var conditionalKnownValue =
        _migrationResolutionHooks.getConditionalKnownValue(node);
    if (conditionalKnownValue == null) {
      super.visitConditionalExpression(node, contextType: contextType);
      return;
    } else {
      var subexpressionToKeep =
          conditionalKnownValue ? node.thenExpression : node.elseExpression;
      subexpressionToKeep.accept(this);
      inferenceHelper.recordStaticType(node, subexpressionToKeep.typeOrThrow,
          contextType: contextType);
    }
  }

  @override
  void visitIfElement(IfElement node, {CollectionLiteralContext? context}) {
    var conditionalKnownValue =
        _migrationResolutionHooks.getConditionalKnownValue(node);
    if (conditionalKnownValue == null) {
      super.visitIfElement(node, context: context);
      return;
    } else {
      var element = conditionalKnownValue ? node.thenElement : node.elseElement;
      if (element != null) {
        (element as CollectionElementImpl).resolveElement(this, context);
      }
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    var conditionalKnownValue =
        _migrationResolutionHooks.getConditionalKnownValue(node);
    if (conditionalKnownValue == null) {
      super.visitIfStatement(node);
      return;
    } else {
      (conditionalKnownValue ? node.thenStatement : node.elseStatement)
          ?.accept(this);
    }
  }
}

/// Instances of the class `ScopeResolverVisitor` are used to resolve
/// [SimpleIdentifier]s to declarations using scoping rules.
///
/// TODO(paulberry): migrate the responsibility for all scope resolution into
/// this visitor.
class ScopeResolverVisitor extends UnifyingAstVisitor<void> {
  static const _nameScopeProperty = 'nameScope';

  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl definingLibrary;

  /// The source representing the compilation unit being visited.
  final Source source;

  /// The object used to access the types from the core library.
  final TypeProviderImpl typeProvider;

  /// The error reporter that will be informed of any errors that are found
  /// during resolution.
  final ErrorReporter errorReporter;

  /// The scope used to resolve identifiers.
  Scope nameScope;

  /// The scope used to resolve unlabeled `break` and `continue` statements.
  ImplicitLabelScope _implicitLabelScope = ImplicitLabelScope.ROOT;

  /// The scope used to resolve labels for `break` and `continue` statements, or
  /// `null` if no labels have been defined in the current context.
  LabelScope? labelScope;

  /// The container with information about local variables.
  final LocalVariableInfo _localVariableInfo = LocalVariableInfo();

  /// If the current function is contained within a closure (a local function or
  /// function expression inside another executable declaration), the element
  /// representing the closure; otherwise `null`.
  ExecutableElement? _enclosingClosure;

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// [definingLibrary] is the element for the library containing the node being
  /// visited.
  /// [source] is the source representing the compilation unit containing the
  /// node being visited.
  /// [typeProvider] is the object used to access the types from the core
  /// library.
  /// [errorListener] is the error listener that will be informed of any errors
  /// that are found during resolution.
  /// [nameScope] is the scope used to resolve identifiers in the node that will
  /// first be visited.  If `null` or unspecified, a new [LibraryScope] will be
  /// created based on [definingLibrary] and [typeProvider].
  ScopeResolverVisitor(this.definingLibrary, this.source, this.typeProvider,
      AnalysisErrorListener errorListener,
      {Scope? nameScope})
      : errorReporter = ErrorReporter(
          errorListener,
          source,
          isNonNullableByDefault: definingLibrary.isNonNullableByDefault,
        ),
        nameScope = nameScope ?? LibraryScope(definingLibrary);

  /// Return the implicit label scope in which the current node is being
  /// resolved.
  ImplicitLabelScope get implicitLabelScope => _implicitLabelScope;

  @override
  void visitBlock(Block node) {
    _withDeclaredLocals(node, node.statements, () {
      super.visitBlock(node);
    });
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    ImplicitLabelScope implicitOuterScope = _implicitLabelScope;
    try {
      _implicitLabelScope = ImplicitLabelScope.ROOT;
      super.visitBlockFunctionBody(node);
    } finally {
      _implicitLabelScope = implicitOuterScope;
    }
  }

  @override
  void visitBreakStatement(covariant BreakStatementImpl node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, false);
  }

  @override
  void visitCatchClause(CatchClause node) {
    var exception = node.exceptionParameter;
    if (exception != null) {
      Scope outerScope = nameScope;
      try {
        nameScope = LocalScope(nameScope);
        _define(exception.staticElement!);
        var stackTrace = node.stackTraceParameter;
        if (stackTrace != null) {
          _define(stackTrace.staticElement!);
        }
        super.visitCatchClause(node);
      } finally {
        nameScope = outerScope;
      }
    } else {
      super.visitCatchClause(node);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    Scope outerScope = nameScope;
    try {
      ClassElement element = node.declaredElement!;
      node.metadata.accept(this);

      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      _setNodeNameScope(node, nameScope);
      visitClassDeclarationInScope(node);

      nameScope = ClassScope(nameScope, element);
      visitClassMembersInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitClassDeclarationInScope(ClassDeclaration node) {
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.extendsClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    node.nativeClause?.accept(this);
  }

  void visitClassMembersInScope(ClassDeclaration node) {
    node.documentationComment?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      ClassElement element = node.declaredElement!;
      nameScope = ClassScope(
        TypeParameterScope(nameScope, element.typeParameters),
        element,
      );
      visitClassTypeAliasInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitClassTypeAliasInScope(ClassTypeAlias node) {
    // Note: we don't visit metadata because it's not inside the class type
    // alias's type parameter scope.  It was already visited in
    // [visitClassTypeAlias].
    node.documentationComment?.accept(this);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.superclass.accept(this);
    node.withClause.accept(this);
    node.implementsClause?.accept(this);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _setNodeNameScope(node, nameScope);
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
    Scope outerScope = nameScope;
    try {
      ConstructorElement element = node.declaredElement!;

      node.metadata.accept(this);
      node.returnType.accept(this);
      node.name?.accept(this);
      node.parameters.accept(this);

      try {
        nameScope = ConstructorInitializerScope(
          nameScope,
          element,
        );
        node.initializers.accept(this);
      } finally {
        nameScope = outerScope;
      }

      node.redirectedConstructor?.accept(this);

      nameScope = FormalParameterScope(
        nameScope,
        element.parameters,
      );
      visitConstructorDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitConstructorDeclarationInScope(ConstructorDeclaration node) {
    node.documentationComment?.accept(this);
    node.body.accept(this);
  }

  @override
  void visitContinueStatement(covariant ContinueStatementImpl node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, true);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _define(node.declaredElement!);
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitDoStatementInScope(node);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
  }

  void visitDoStatementInScope(DoStatement node) {
    visitStatementInScope(node.body);
    node.condition.accept(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    Scope outerScope = nameScope;
    try {
      ClassElement element = node.declaredElement!;
      node.metadata.accept(this);

      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      _setNodeNameScope(node, nameScope);
      visitEnumDeclarationInScope(node);

      nameScope = ClassScope(nameScope, element);
      visitEnumMembersInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitEnumDeclarationInScope(EnumDeclaration node) {
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
  }

  void visitEnumMembersInScope(EnumDeclaration node) {
    node.documentationComment?.accept(this);
    node.constants.accept(this);
    node.members.accept(this);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _setNodeNameScope(node, nameScope);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    Scope outerScope = nameScope;
    try {
      ExtensionElement element = node.declaredElement!;
      node.metadata.accept(this);

      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      _setNodeNameScope(node, nameScope);
      visitExtensionDeclarationInScope(node);

      nameScope = ExtensionScope(nameScope, element);
      visitExtensionMembersInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitExtensionDeclarationInScope(ExtensionDeclaration node) {
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    node.extendedType.accept(this);
  }

  void visitExtensionMembersInScope(ExtensionDeclaration node) {
    node.documentationComment?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    //
    // We visit the iterator before the loop variable because the loop variable
    // cannot be in scope while visiting the iterator.
    //
    node.iterable.accept(this);
    node.loopVariable.accept(this);
  }

  @override
  void visitForElement(ForElement node) {
    Scope outerNameScope = nameScope;
    try {
      nameScope = LocalScope(nameScope);
      _setNodeNameScope(node, nameScope);
      visitForElementInScope(node);
    } finally {
      nameScope = outerNameScope;
    }
  }

  /// Visit the given [node] after it's scope has been created. This replaces
  /// the normal call to the inherited visit method so that ResolverVisitor can
  /// intervene when type propagation is enabled.
  void visitForElementInScope(ForElement node) {
    // TODO(brianwilkerson) Investigate the possibility of removing the
    //  visit...InScope methods now that type propagation is no longer done.
    node.forLoopParts.accept(this);
    node.body.accept(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    super.visitFormalParameterList(node);
    // We finished resolving function signature, now include formal parameters
    // scope.  Note: we must not do this if the parent is a
    // FunctionTypedFormalParameter, because in that case we aren't finished
    // resolving the full function signature, just a part of it.
    var parent = node.parent;
    if (parent is FunctionExpression) {
      nameScope = FormalParameterScope(
        nameScope,
        parent.declaredElement!.parameters,
      );
    } else if (parent is FunctionTypeAlias) {
      var aliasedElement = parent.declaredElement!.aliasedElement;
      var functionElement = aliasedElement as GenericFunctionTypeElement;
      nameScope = FormalParameterScope(
        nameScope,
        functionElement.parameters,
      );
    } else if (parent is MethodDeclaration) {
      nameScope = FormalParameterScope(
        nameScope,
        parent.declaredElement!.parameters,
      );
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    Scope outerNameScope = nameScope;
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      nameScope = LocalScope(nameScope);
      _implicitLabelScope = _implicitLabelScope.nest(node);
      _setNodeNameScope(node, nameScope);
      visitForStatementInScope(node);
    } finally {
      nameScope = outerNameScope;
      _implicitLabelScope = outerImplicitScope;
    }
  }

  /// Visit the given [node] after it's scope has been created. This replaces
  /// the normal call to the inherited visit method so that ResolverVisitor can
  /// intervene when type propagation is enabled.
  void visitForStatementInScope(ForStatement node) {
    // TODO(brianwilkerson) Investigate the possibility of removing the
    //  visit...InScope methods now that type propagation is no longer done.
    node.forLoopParts.accept(this);
    visitStatementInScope(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    (node.functionExpression.body as FunctionBodyImpl).localVariableInfo =
        _localVariableInfo;
    var outerClosure = _enclosingClosure;
    Scope outerScope = nameScope;
    try {
      _enclosingClosure = node.parent is FunctionDeclarationStatement
          ? node.declaredElement
          : null;
      node.metadata.accept(this);
      var element = node.declaredElement!;
      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      _setNodeNameScope(node, nameScope);
      visitFunctionDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
      _enclosingClosure = outerClosure;
    }
  }

  void visitFunctionDeclarationInScope(FunctionDeclaration node) {
    // Note: we don't visit metadata because it's not inside the function's type
    // parameter scope.  It was already visited in [visitFunctionDeclaration].
    node.returnType?.accept(this);
    node.name.accept(this);
    node.functionExpression.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var outerClosure = _enclosingClosure;
    Scope outerScope = nameScope;
    try {
      if (node.parent is! FunctionDeclaration) {
        (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
        _enclosingClosure = node.declaredElement;
      }
      var parent = node.parent;
      if (parent is FunctionDeclaration) {
        // We have already created a function scope and don't need to do so again.
        super.visitFunctionExpression(node);
        parent.documentationComment?.accept(this);
        return;
      }

      ExecutableElement element = node.declaredElement!;
      nameScope = FormalParameterScope(
        TypeParameterScope(nameScope, element.typeParameters),
        element.parameters,
      );
      super.visitFunctionExpression(node);
    } finally {
      nameScope = outerScope;
      _enclosingClosure = outerClosure;
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement!;
      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      visitFunctionTypeAliasInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitFunctionTypeAliasInScope(FunctionTypeAlias node) {
    // Note: we don't visit metadata because it's not inside the function type
    // alias's type parameter scope.  It was already visited in
    // [visitFunctionTypeAlias].
    node.returnType?.accept(this);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
    // Visiting the parameters added them to the scope as a side effect.  So it
    // is safe to visit the documentation comment now.
    node.documentationComment?.accept(this);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      ParameterElement element = node.declaredElement!;
      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      visitFunctionTypedFormalParameterInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitFunctionTypedFormalParameterInScope(
      FunctionTypedFormalParameter node) {
    // Note: we don't visit metadata because it's not inside the function typed
    // formal parameter's type parameter scope.  It was already visited in
    // [visitFunctionTypedFormalParameter].
    node.documentationComment?.accept(this);
    node.returnType?.accept(this);
    node.identifier.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var type = node.type;
    if (type == null) {
      // The function type hasn't been resolved yet, so we can't create a scope
      // for its parameters.
      super.visitGenericFunctionType(node);
      return;
    }

    Scope outerScope = nameScope;
    try {
      GenericFunctionTypeElement element =
          (node as GenericFunctionTypeImpl).declaredElement!;
      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      _setNodeNameScope(node, nameScope);
      super.visitGenericFunctionType(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement as TypeAliasElement;
      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      _setNodeNameScope(node, nameScope);
      visitGenericTypeAliasInScope(node);

      var aliasedElement = element.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElement) {
        nameScope = FormalParameterScope(
            TypeParameterScope(nameScope, aliasedElement.typeParameters),
            aliasedElement.parameters);
      }
      node.documentationComment?.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitGenericTypeAliasInScope(GenericTypeAlias node) {
    // Note: we don't visit metadata because it's not inside the generic type
    // alias's type parameter scope.  It was already visited in
    // [visitGenericTypeAlias].
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.type.accept(this);
  }

  @override
  void visitIfStatement(IfStatement node) {
    node.condition.accept(this);
    visitStatementInScope(node.thenStatement);
    visitStatementInScope(node.elseStatement);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    var outerScope = _addScopesFor(node.labels, node.unlabeled);
    try {
      super.visitLabeledStatement(node);
    } finally {
      labelScope = outerScope;
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      ExecutableElement element = node.declaredElement!;
      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      _setNodeNameScope(node, nameScope);
      visitMethodDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitMethodDeclarationInScope(MethodDeclaration node) {
    // Note: we don't visit metadata because it's not inside the method's type
    // parameter scope.  It was already visited in [visitMethodDeclaration].
    node.returnType?.accept(this);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    // Visiting the parameters added them to the scope as a side effect.  So it
    // is safe to visit the documentation comment now.
    node.documentationComment?.accept(this);
    node.body.accept(this);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Only visit the method name if there's no real target (so this is an
    // unprefixed function invocation, outside a cascade).  This is the only
    // circumstance in which the method name is meant to be looked up in the
    // current scope.
    node.target?.accept(this);
    if (node.realTarget == null) {
      node.methodName.accept(this);
    }
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    Scope outerScope = nameScope;
    try {
      ClassElement element = node.declaredElement!;
      node.metadata.accept(this);

      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      _setNodeNameScope(node, nameScope);
      visitMixinDeclarationInScope(node);

      nameScope = ClassScope(nameScope, element);
      visitMixinMembersInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitMixinDeclarationInScope(MixinDeclaration node) {
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
  }

  void visitMixinMembersInScope(MixinDeclaration node) {
    node.documentationComment?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    // All TypeName(s) are already resolved, so we don't resolve it here.
    // But there might be type arguments with Expression(s), such as
    // annotations on formal parameters of GenericFunctionType(s).
    node.typeArguments?.accept(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Do not visit the identifier after the `.`, since it is not meant to be
    // looked up in the current scope.
    node.prefix.accept(this);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Do not visit the property name, since it is not meant to be looked up in
    // the current scope.
    node.target?.accept(this);
  }

  @override
  void visitSimpleIdentifier(covariant SimpleIdentifierImpl node) {
    // Ignore if already resolved - declaration or type.
    if (node.inDeclarationContext()) {
      return;
    }
    // Ignore if qualified.
    var parent = node.parent;
    var scopeLookupResult = nameScope.lookup(node.name);
    node.scopeLookupResult = scopeLookupResult;
    // Ignore if it cannot be a reference to a local variable.
    if (parent is FieldFormalParameter) {
      return;
    } else if (parent is ConstructorDeclaration && parent.returnType == node) {
      return;
    } else if (parent is ConstructorFieldInitializer &&
        parent.fieldName == node) {
      return;
    }
    if (parent is ConstructorName) {
      return;
    }
    if (parent is Label) {
      return;
    }
    // Prepare VariableElement.
    var element = scopeLookupResult.getter;
    if (element is! VariableElement) {
      return;
    }
    // Must be local or parameter.
    ElementKind kind = element.kind;
    if (kind == ElementKind.LOCAL_VARIABLE || kind == ElementKind.PARAMETER) {
      node.staticElement = element;
      if (node.inSetterContext()) {
        _localVariableInfo.potentiallyMutatedInScope.add(element);
        if (_enclosingClosure != null &&
            element.enclosingElement != _enclosingClosure) {
          _localVariableInfo.potentiallyMutatedInClosure.add(element);
        }
      }
    }
  }

  /// Visit the given statement after it's scope has been created. This is used
  /// by ResolverVisitor to correctly visit the 'then' and 'else' statements of
  /// an 'if' statement.
  ///
  /// @param node the statement to be visited
  void visitStatementInScope(Statement? node) {
    if (node is Block) {
      // Don't create a scope around a block because the block will create it's
      // own scope.
      visitBlock(node);
    } else if (node != null) {
      Scope outerNameScope = nameScope;
      try {
        nameScope = LocalScope(nameScope);
        node.accept(this);
      } finally {
        nameScope = outerNameScope;
      }
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    node.expression.accept(this);

    _withDeclaredLocals(node, node.statements, () {
      node.statements.accept(this);
    });
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _withDeclaredLocals(node, node.statements, () {
      node.statements.accept(this);
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    var outerScope = labelScope;
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      for (SwitchMember member in node.members) {
        for (Label label in member.labels) {
          SimpleIdentifier labelName = label.label;
          LabelElement labelElement = labelName.staticElement as LabelElement;
          labelScope =
              LabelScope(labelScope, labelName.name, member, labelElement);
        }
      }
      visitSwitchStatementInScope(node);
    } finally {
      labelScope = outerScope;
      _implicitLabelScope = outerImplicitScope;
    }
  }

  void visitSwitchStatementInScope(SwitchStatement node) {
    super.visitSwitchStatement(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);

    if (node.parent!.parent is ForParts) {
      _define(node.declaredElement!);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    node.condition.accept(this);
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitStatementInScope(node.body);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
  }

  /// Add scopes for each of the given labels.
  ///
  /// @param labels the labels for which new scopes are to be added
  /// @return the scope that was in effect before the new scopes were added
  LabelScope? _addScopesFor(NodeList<Label> labels, AstNode node) {
    var outerScope = labelScope;
    for (Label label in labels) {
      SimpleIdentifier labelNameNode = label.label;
      String labelName = labelNameNode.name;
      LabelElement labelElement = labelNameNode.staticElement as LabelElement;
      labelScope = LabelScope(labelScope, labelName, node, labelElement);
    }
    return outerScope;
  }

  void _define(Element element) {
    (nameScope as LocalScope).add(element);
  }

  /// Return the target of a break or continue statement, and update the static
  /// element of its label (if any). The [parentNode] is the AST node of the
  /// break or continue statement. The [labelNode] is the label contained in
  /// that statement (if any). The flag [isContinue] is `true` if the node being
  /// visited is a continue statement.
  AstNode? _lookupBreakOrContinueTarget(
      AstNode parentNode, SimpleIdentifierImpl? labelNode, bool isContinue) {
    if (labelNode == null) {
      return implicitLabelScope.getTarget(isContinue);
    } else {
      var labelScope = this.labelScope;
      if (labelScope == null) {
        // There are no labels in scope, so by definition the label is
        // undefined.
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        return null;
      }
      var definingScope = labelScope.lookup(labelNode.name);
      if (definingScope == null) {
        // No definition of the given label name could be found in any
        // enclosing scope.
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        return null;
      }
      // The target has been found.
      labelNode.staticElement = definingScope.element;
      ExecutableElement? labelContainer =
          definingScope.element.thisOrAncestorOfType();
      if (_enclosingClosure != null &&
          !identical(labelContainer, _enclosingClosure)) {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE,
            labelNode,
            [labelNode.name]);
      }
      return definingScope.node;
    }
  }

  void _withDeclaredLocals(
    AstNode node,
    List<Statement> statements,
    void Function() f,
  ) {
    var outerScope = nameScope;
    try {
      var enclosedScope = LocalScope(nameScope);
      BlockScope.elementsInStatements(statements).forEach(enclosedScope.add);

      nameScope = enclosedScope;
      _setNodeNameScope(node, nameScope);

      f();
    } finally {
      nameScope = outerScope;
    }
  }

  /// Return the [Scope] to use while resolving inside the [node].
  ///
  /// Not every node has the scope set, for example we set the scopes for
  /// blocks, but statements don't have separate scopes. The compilation unit
  /// has the library scope.
  static Scope? getNodeNameScope(AstNode node) {
    return node.getProperty(_nameScopeProperty);
  }

  /// Set the [Scope] to use while resolving inside the [node].
  static void _setNodeNameScope(AstNode node, Scope scope) {
    node.setProperty(_nameScopeProperty, scope);
  }
}

/// Tracker for whether a `switch` statement has `default` or is on an
/// enumeration, and all the enum constants are covered.
class _SwitchExhaustiveness {
  /// If the switch is on an enumeration, the set of enum constants to cover.
  /// Otherwise `null`.
  final Set<FieldElement>? _enumConstants;

  /// If the switch is on an enumeration, is `true` if the null value is
  /// covered, because the switch expression type is non-nullable, or `null`
  /// was covered explicitly.
  bool _isNullEnumValueCovered = false;

  bool isExhaustive = false;

  factory _SwitchExhaustiveness(DartType expressionType) {
    if (expressionType is InterfaceType) {
      var enum_ = expressionType.element;
      if (enum_ is EnumElementImpl) {
        return _SwitchExhaustiveness._(
          enum_.constants.toSet(),
          expressionType.nullabilitySuffix == NullabilitySuffix.none,
        );
      }
    }
    return _SwitchExhaustiveness._(null, false);
  }

  _SwitchExhaustiveness._(this._enumConstants, this._isNullEnumValueCovered);

  void visitSwitchMember(SwitchMember node) {
    if (_enumConstants != null && node is SwitchCase) {
      var element = _referencedElement(node.expression);
      if (element is PropertyAccessorElement) {
        _enumConstants!.remove(element.variable);
      }

      if (node.expression is NullLiteral) {
        _isNullEnumValueCovered = true;
      }

      if (_enumConstants!.isEmpty && _isNullEnumValueCovered) {
        isExhaustive = true;
      }
    } else if (node is SwitchDefault) {
      isExhaustive = true;
    }
  }

  static Element? _referencedElement(Expression expression) {
    if (expression is ParenthesizedExpression) {
      return _referencedElement(expression.expression);
    } else if (expression is PrefixedIdentifier) {
      return expression.staticElement;
    } else if (expression is PropertyAccess) {
      return expression.propertyName.staticElement;
    } else if (expression is SimpleIdentifier) {
      return expression.staticElement;
    }
    return null;
  }
}

class _WhyNotPromotedVisitor
    implements
        NonPromotionReasonVisitor<DiagnosticMessage?, AstNode,
            PromotableElement, DartType> {
  final Source source;

  final SyntacticEntity _errorEntity;

  final FlowAnalysisDataForTesting? _dataForTesting;

  PropertyAccessorElement? propertyReference;

  DartType? propertyType;

  _WhyNotPromotedVisitor(this.source, this._errorEntity, this._dataForTesting);

  @override
  DiagnosticMessage visitDemoteViaExplicitWrite(
      DemoteViaExplicitWrite<PromotableElement> reason) {
    var node = reason.node as AstNode;
    if (node is ForEachPartsWithIdentifier) {
      node = node.identifier;
    }
    if (_dataForTesting != null) {
      _dataForTesting!.nonPromotionReasonTargets[node] = reason.shortName;
    }
    var variableName = reason.variable.name;
    return _contextMessageForWrite(variableName, node, reason);
  }

  @override
  DiagnosticMessage? visitPropertyNotPromoted(
      PropertyNotPromoted<DartType> reason) {
    var receiverElement = reason.propertyMember;
    if (receiverElement is PropertyAccessorElement) {
      propertyReference = receiverElement;
      propertyType = reason.staticType;
      return _contextMessageForProperty(
          receiverElement, reason.propertyName, reason);
    } else {
      assert(receiverElement == null,
          'Unrecognized property element: ${receiverElement.runtimeType}');
      return null;
    }
  }

  @override
  DiagnosticMessage? visitThisNotPromoted(ThisNotPromoted reason) {
    return DiagnosticMessageImpl(
        filePath: source.fullName,
        message: "'this' can't be promoted",
        offset: _errorEntity.offset,
        length: _errorEntity.length,
        url: reason.documentationLink);
  }

  DiagnosticMessageImpl _contextMessageForProperty(
      PropertyAccessorElement property,
      String propertyName,
      NonPromotionReason reason) {
    return DiagnosticMessageImpl(
        filePath: property.source.fullName,
        message:
            "'$propertyName' refers to a property so it couldn't be promoted",
        offset: property.nonSynthetic.nameOffset,
        length: property.nameLength,
        url: reason.documentationLink);
  }

  DiagnosticMessageImpl _contextMessageForWrite(
      String variableName, AstNode node, NonPromotionReason reason) {
    return DiagnosticMessageImpl(
        filePath: source.fullName,
        message: "Variable '$variableName' could not be promoted due to an "
            "assignment",
        offset: node.offset,
        length: node.length,
        url: reason.documentationLink);
  }
}
