// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
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
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/this_access_tracker.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';
import 'package:meta/meta.dart';

/// A function which returns [NonPromotionReason]s that various types are not
/// promoted.
typedef WhyNotPromotedGetter = Map<DartType, NonPromotionReason> Function();

/// Maintains and manages contextual type information used for
/// inferring types.
class InferenceContext {
  // TODO(leafp): Consider replacing these node properties with a
  // hash table help in an instance of this class.
  static const String _typeProperty =
      'analyzer.src.generated.InferenceContext.contextType';

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

  void popFunctionBodyContext(FunctionBody node) {
    var context = _bodyContexts.removeLast();

    var flow = _resolver.flowAnalysis.flow;

    var resultType = context.computeInferredReturnType(
      endOfBlockIsReachable: flow == null || flow.isReachable,
    );

    setType(node, resultType);
  }

  void pushFunctionBodyContext(FunctionBody node) {
    var imposedType = getContext(node);
    _bodyContexts.add(
      BodyInferenceContext(
        typeSystem: _typeSystem,
        node: node,
        imposedType: imposedType,
      ),
    );
  }

  /// Clear the type information associated with [node].
  static void clearType(AstNode? node) {
    node?.setProperty(_typeProperty, null);
  }

  /// Look for contextual type information attached to [node], and returns
  /// the type if found.
  ///
  /// The returned type may be partially or completely unknown, denoted with an
  /// unknown type `_`, for example `List<_>` or `(_, int) -> void`.
  /// You can use [TypeSystemImpl.upperBoundForType] or
  /// [TypeSystemImpl.lowerBoundForType] if you would prefer a known type
  /// that represents the bound of the context type.
  static DartType? getContext(AstNode? node) =>
      node?.getProperty(_typeProperty);

  /// Attach contextual type information [type] to [node] for use during
  /// inference.
  static void setType(AstNode? node, DartType? type) {
    if (type == null || type.isDynamic) {
      clearType(node);
    } else {
      node?.setProperty(_typeProperty, type);
    }
  }

  /// Attach contextual type information [type] to [node] for use during
  /// inference.
  static void setTypeFromNode(AstNode innerNode, AstNode outerNode) {
    setType(innerNode, getContext(outerNode));
  }
}

/// Base class for visitors that perform resolution.  This class keeps track of
/// some of the basic information that is needed by resolution stages, such as
/// the defining library and the error reporter.
abstract class ResolverBase extends UnifyingAstVisitor<void> {
  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl definingLibrary;

  /// The source representing the compilation unit being visited.
  final Source source;

  /// The object used to access the types from the core library.
  final TypeProviderImpl typeProvider;

  /// The error reporter that will be informed of any errors that are found
  /// during resolution.
  final ErrorReporter errorReporter;

  ResolverBase(this.definingLibrary, this.source, this.typeProvider,
      AnalysisErrorListener errorListener)
      : errorReporter = ErrorReporter(
          errorListener,
          source,
          isNonNullableByDefault: definingLibrary.isNonNullableByDefault,
        );
}

/// Instances of the class `ResolverVisitor` are used to resolve the nodes
/// within a single compilation unit.
class ResolverVisitor extends ResolverBase with ErrorDetectionHelpers {
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
      SimpleIdentifierResolver(this, flowAnalysis);

  late final PropertyElementResolver _propertyElementResolver =
      PropertyElementResolver(this);

  late final AnnotationResolver _annotationResolver = AnnotationResolver(this);

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// The [definingLibrary] is the element for the library containing the node
  /// being visited. The [source] is the source representing the compilation
  /// unit containing the node being visited. The [typeProvider] is the object
  /// used to access the types from the core library. The [errorListener] is the
  /// error listener that will be informed of any errors that are found during
  /// resolution. The [nameScope] is the scope used to resolve identifiers in
  /// the node that will first be visited.  If `null` or unspecified, a new
  /// [LibraryScope] will be created based on [definingLibrary] and
  /// [typeProvider].
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
            typeProvider,
            errorListener,
            featureSet ??
                definingLibrary.context.analysisOptions.contextFeatures,
            flowAnalysisHelper,
            const MigratableAstInfoProvider(),
            null);

  ResolverVisitor._(
      this.inheritance,
      LibraryElementImpl definingLibrary,
      Source source,
      this.typeSystem,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      FeatureSet featureSet,
      this.flowAnalysis,
      this._migratableAstInfoProvider,
      MigrationResolutionHooks? migrationResolutionHooks)
      : _featureSet = featureSet,
        migrationResolutionHooks = migrationResolutionHooks,
        super(definingLibrary, source, typeProvider as TypeProviderImpl,
            errorListener) {
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
    typeAnalyzer = StaticTypeAnalyzer(this, migrationResolutionHooks);
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

  /// Verify that the arguments in the given [argumentList] can be assigned to
  /// their corresponding parameters.
  ///
  /// See [CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
  void checkForArgumentTypesNotAssignableInList(ArgumentList argumentList,
      List<WhyNotPromotedGetter> whyNotPromotedList) {
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        insertImplicitCallReference(argument.expression);
      } else {
        insertImplicitCallReference(argument);
      }
    }
    var arguments = argumentList.arguments;
    for (int i = 0; i < arguments.length; i++) {
      checkForArgumentTypeNotAssignableForArgument(arguments[i],
          whyNotPromoted:
              flowAnalysis.flow == null ? null : whyNotPromotedList[i]);
    }
  }

  void checkForBodyMayCompleteNormally({
    required DartType? returnType,
    required FunctionBody body,
    required AstNode errorNode,
  }) {
    if (!_isNonNullableByDefault) return;
    if (!flowAnalysis.flow!.isReachable) {
      return;
    }

    if (returnType == null) {
      return;
    }

    if (body is BlockFunctionBody) {
      if (body.isGenerator) {
        return;
      }

      if (typeSystem.isPotentiallyNonNullable(returnType)) {
        if (errorNode is ConstructorDeclaration) {
          errorReporter.reportErrorForName(
            CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY,
            errorNode,
          );
        } else if (errorNode is BlockFunctionBody) {
          errorReporter.reportErrorForToken(
            CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY,
            errorNode.block.leftBracket,
          );
        } else {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY,
            errorNode,
          );
        }
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
  ExpressionImpl insertGenericFunctionInstantiation(Expression expression) {
    expression as ExpressionImpl;
    if (!isConstructorTearoffsEnabled) {
      // Temporarily, only create [ImplicitCallReference] nodes under the
      // 'constructor-tearoffs' feature.
      // TODO(srawlins): When we are ready to make a breaking change release to
      // the analyzer package, remove this exception.
      return expression;
    }

    var staticType = expression.staticType;
    var context = InferenceContext.getContext(expression);
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
    )!;
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

  /// If `expression` should be treated as `expression.call`, inserts an
  /// [ImplicitCallReferece] node which wraps [expression].
  ///
  /// If an [ImplicitCallReferece] is inserted, returns it; otherwise, returns
  /// [expression].
  ExpressionImpl insertImplicitCallReference(Expression expression) {
    expression as ExpressionImpl;
    if (!isConstructorTearoffsEnabled) {
      // Temporarily, only create [ImplicitCallReference] nodes under the
      // 'constructor-tearoffs' feature.
      // TODO(srawlins): When we are ready to make a breaking change release to
      // the analyzer package, remove this exception.
      return expression;
    }

    var parent = expression.parent;
    if (parent is CascadeExpression && parent.target == expression) {
      // Do not perform an "implicit tear-off conversion" here. It should only
      // be performed on [parent]. See
      // https://github.com/dart-lang/language/issues/1873.
      return expression;
    }
    var context = InferenceContext.getContext(expression);
    var callMethod =
        getImplicitCallMethod(expression.typeOrThrow, context, expression);
    if (callMethod == null || context == null) {
      return expression;
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
      )!;
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

    return callReference;
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

      InferenceContext.setType(node.index, result.indexContextType);
      node.index.accept(this);
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
  void visitAnnotation(covariant AnnotationImpl node) {
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    _annotationResolver.resolve(node, whyNotPromotedList);
    var arguments = node.arguments;
    if (arguments != null) {
      checkForArgumentTypesNotAssignableInList(arguments, whyNotPromotedList);
    }
  }

  @override
  void visitArgumentList(ArgumentList node,
      {bool isIdentical = false,
      List<WhyNotPromotedGetter>? whyNotPromotedList}) {
    whyNotPromotedList ??= [];
    var callerType = InferenceContext.getContext(node);
    NodeList<Expression> arguments = node.arguments;
    if (callerType is FunctionType) {
      var parameters = callerType.parameters;

      var namedParameters = <String, ParameterElement>{};
      for (var i = 0; i < parameters.length; i++) {
        var parameter = parameters[i];
        if (parameter.isNamed) {
          namedParameters[parameter.name] = parameter;
        }
      }

      var parent = node.parent;
      DartType? targetType;
      Element? methodElement;
      DartType? invocationContext;
      if (parent is MethodInvocation) {
        targetType = parent.realTarget?.staticType;
        methodElement = parent.methodName.staticElement;
        invocationContext = InferenceContext.getContext(parent);
      }

      //TODO(leafp): Consider using the parameter elements here instead.
      //TODO(leafp): Make sure that the parameter elements are getting
      // setup correctly with inference.
      var positionalParameterIndex = 0;
      for (var i = 0; i < arguments.length; i++) {
        var argument = arguments[i];
        ParameterElement? parameter;
        if (argument is NamedExpression) {
          parameter = namedParameters[argument.name.label.name];
        } else {
          while (positionalParameterIndex < parameters.length) {
            parameter = parameters[positionalParameterIndex++];
            if (!parameter.isNamed) {
              break;
            }
          }
        }
        if (parameter != null) {
          var parameterType = parameter.type;
          if (targetType != null) {
            InferenceContext.setType(
                argument,
                typeSystem.refineNumericInvocationContext(targetType,
                    methodElement, invocationContext, parameterType));
          } else {
            InferenceContext.setType(argument, parameterType);
          }
        }
      }
    }
    checkUnreachableNode(node);
    int length = arguments.length;
    var flow = flowAnalysis.flow;
    for (var i = 0; i < length; i++) {
      if (isIdentical && length > 1 && i == 1) {
        var firstArg = arguments[0];
        flow?.equalityOp_rightBegin(firstArg, firstArg.typeOrThrow);
      }
      arguments[i].accept(this);
      if (flow != null) {
        whyNotPromotedList.add(flow.whyNotPromoted(arguments[i]));
      }
    }
    if (isIdentical && length > 1) {
      var secondArg = arguments[1];
      flow?.equalityOp_end(
          node.parent as Expression, secondArg, secondArg.typeOrThrow);
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitAsExpression(AsExpression node) {
    super.visitAsExpression(node);
    flowAnalysis.asExpression(node);
    insertGenericFunctionInstantiation(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    InferenceContext.setType(node.condition, typeProvider.boolType);
    flowAnalysis.flow?.assert_begin();
    node.condition.accept(this);
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
    InferenceContext.setType(node.condition, typeProvider.boolType);
    flowAnalysis.flow?.assert_begin();
    node.condition.accept(this);
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
  void visitAssignmentExpression(AssignmentExpression node) {
    _assignmentExpressionResolver.resolve(node as AssignmentExpressionImpl);
    insertGenericFunctionInstantiation(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    var contextType = InferenceContext.getContext(node);
    if (contextType != null) {
      var futureUnion = _createFutureOr(contextType);
      InferenceContext.setType(node.expression, futureUnion);
    }
    super.visitAwaitExpression(node);
    insertGenericFunctionInstantiation(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _binaryExpressionResolver.resolve(node as BinaryExpressionImpl);
    insertGenericFunctionInstantiation(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    try {
      inferenceContext.pushFunctionBodyContext(node);
      _thisAccessTracker.enterFunctionBody(node);
      super.visitBlockFunctionBody(node);
    } finally {
      _thisAccessTracker.exitFunctionBody(node);
      inferenceContext.popFunctionBodyContext(node);
    }
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    flowAnalysis.flow?.booleanLiteral(node, node.value);
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    checkUnreachableNode(node);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    flowAnalysis.breakStatement(node);
  }

  @override
  void visitCascadeExpression(covariant CascadeExpressionImpl node) {
    InferenceContext.setTypeFromNode(node.target, node);
    node.target.accept(this);

    if (node.isNullAware) {
      flowAnalysis.flow!.nullAwareAccess_rightBegin(
          node.target, node.target.staticType ?? typeProvider.dynamicType);
      _unfinishedNullShorts.add(node.nullShortingTermination);
    }

    node.cascadeSections.accept(this);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);

    nullShortingTermination(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    //
    // Continue the class resolution.
    //
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      super.visitClassDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      enclosingClass = outerType;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    super.visitClassTypeAlias(node);
    node.accept(elementResolver);
    // Note: no need to call the typeAnalyzer since it does not override
    // visitClassTypeAlias.
  }

  @override
  void visitCommentReference(CommentReference node) {
    //
    // We do not visit the identifier because it needs to be visited in the
    // context of the reference.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
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
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    Expression condition = node.condition;
    var flow = flowAnalysis.flow;
    flow?.conditional_conditionBegin();

    // TODO(scheglov) Do we need these checks for null?
    condition.accept(this);
    condition = node.condition;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);
    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);

    InferenceContext.setTypeFromNode(node.thenExpression, node);

    if (flow != null) {
      flow.conditional_thenBegin(condition, node);
      checkUnreachableNode(node.thenExpression);
    }
    node.thenExpression.accept(this);
    nullSafetyDeadCodeVerifier.flowEnd(node.thenExpression);

    Expression elseExpression = node.elseExpression;
    InferenceContext.setTypeFromNode(elseExpression, node);

    if (flow != null) {
      flow.conditional_elseBegin(node.thenExpression);
      checkUnreachableNode(elseExpression);
      elseExpression.accept(this);
      flow.conditional_end(node, elseExpression);
      nullSafetyDeadCodeVerifier.flowEnd(elseExpression);
    } else {
      elseExpression.accept(this);
    }
    elseExpression = node.elseExpression;

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitConfiguration(Configuration node) {
    // Don't visit the children. For the time being we don't resolve anything
    // inside the configuration.
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    flowAnalysis.topLevelDeclaration_enter(node, node.parameters);
    flowAnalysis.executableDeclaration_enter(node, node.parameters, false);

    var returnType = node.declaredElement!.type.returnType;
    InferenceContext.setType(node.body, returnType);

    var outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.declaredElement;
      assert(_thisType == null);
      _setupThisType();
      super.visitConstructorDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
      _thisType = null;
    }

    if (node.factoryKeyword != null) {
      var bodyContext = BodyInferenceContext.of(node.body);
      checkForBodyMayCompleteNormally(
        returnType: bodyContext?.contextType,
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
    InferenceContext.setType(expression, fieldType);
    expression.accept(this);
    expression = node.expression;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(expression);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    if (fieldElement != null) {
      if (fieldType != null && expression.staticType != null) {
        var callReference = insertImplicitCallReference(expression);
        if (expression != callReference) {
          checkForInvalidAssignment(node.fieldName, callReference,
              whyNotPromoted: whyNotPromoted);
        }
      }
      var enclosingConstructor = enclosingFunction as ConstructorElement;
      checkForFieldInitializerNotAssignable(node, fieldElement,
          isConstConstructor: enclosingConstructor.isConst,
          whyNotPromoted: whyNotPromoted);
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.type2.accept(this);
    node.accept(elementResolver);
  }

  @override
  void visitConstructorReference(covariant ConstructorReferenceImpl node) {
    _constructorReferenceResolver.resolve(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    checkUnreachableNode(node);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    flowAnalysis.continueStatement(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    InferenceContext.setType(node.defaultValue, node.declaredElement?.type);
    super.visitDefaultFormalParameter(node);
    ParameterElement element = node.declaredElement!;

    if (element is DefaultParameterElementImpl && node.isOfLocalFunction) {
      element.constantInitializer = node.defaultValue;
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    checkUnreachableNode(node);

    var condition = node.condition;

    flowAnalysis.flow?.doStatement_bodyBegin(node);
    node.body.accept(this);

    flowAnalysis.flow?.doStatement_conditionBegin();
    InferenceContext.setType(condition, typeProvider.boolType);
    condition.accept(this);
    condition = node.condition;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);
    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);

    flowAnalysis.flow?.doStatement_end(condition);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    if (resolveOnlyCommentInFunctionBody) {
      return;
    }
    super.visitEmptyFunctionBody(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.metadata.accept(this);
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    //
    // Continue the enum resolution.
    //
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      super.visitEnumDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      enclosingClass = outerType;
    }
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (resolveOnlyCommentInFunctionBody) {
      return;
    }

    try {
      inferenceContext.pushFunctionBodyContext(node);
      InferenceContext.setType(
        node.expression,
        inferenceContext.bodyContext!.contextType,
      );
      _thisAccessTracker.enterFunctionBody(node);

      super.visitExpressionFunctionBody(node);
      insertImplicitCallReference(node.expression);

      flowAnalysis.flow?.handleExit();

      inferenceContext.bodyContext!.addReturnExpression(node.expression);
    } finally {
      _thisAccessTracker.exitFunctionBody(node);
      inferenceContext.popFunctionBodyContext(node);
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var outerExtension = enclosingExtension;
    try {
      enclosingExtension = node.declaredElement!;
      super.visitExtensionDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      enclosingExtension = outerExtension;
    }
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    node.extensionName.accept(this);
    node.typeArguments?.accept(this);

    ExtensionMemberResolver(this).setOverrideReceiverContextType(node);
    visitArgumentList(node.argumentList,
        whyNotPromotedList: whyNotPromotedList);

    node.accept(elementResolver);
    extensionResolver.resolveOverride(node, whyNotPromotedList);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _thisAccessTracker.enterFieldDeclaration(node);
    try {
      assert(_thisType == null);
      _setupThisType();
      super.visitFieldDeclaration(node);
    } finally {
      _thisAccessTracker.exitFieldDeclaration(node);
      _thisType = null;
    }
  }

  @override
  void visitForElement(ForElement node) {
    _forResolver.resolveElement(node as ForElementImpl);
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
      isLocal,
    );

    var functionType = node.declaredElement!.type;
    InferenceContext.setType(node.functionExpression, functionType);

    var outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.declaredElement;
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }

    if (!node.isSetter) {
      // TODO(scheglov) encapsulate
      var bodyContext = BodyInferenceContext.of(
        node.functionExpression.body,
      );
      checkForBodyMayCompleteNormally(
        returnType: bodyContext?.contextType,
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

    node.accept(elementResolver);
    // Note: no need to call the typeAnalyzer since it does not override
    // visitFunctionDeclaration
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node) {
    var outerFunction = _enclosingFunction;
    _enclosingFunction = node.declaredElement;

    _functionExpressionResolver.resolve(node);
    insertGenericFunctionInstantiation(node);

    _enclosingFunction = outerFunction;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    node.function.accept(this);
    _functionExpressionInvocationResolver.resolve(
        node as FunctionExpressionInvocationImpl, whyNotPromotedList);
    nullShortingTermination(node);
    insertGenericFunctionInstantiation(node);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _functionReferenceResolver.resolve(node as FunctionReferenceImpl);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    super.visitFunctionTypeAlias(node);
    node.accept(elementResolver);
    // Note: no need to call the typeAnalyzer since it does not override
    // visitFunctionTypeAlias.
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    super.visitFunctionTypedFormalParameter(node);
    node.accept(elementResolver);
    // Note: no need to call the typeAnalyzer since it does not override
    // visitFunctionTypedFormalParameter.
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    super.visitGenericTypeAlias(node);
    node.accept(elementResolver);
    // Note: no need to call the typeAnalyzer since it does not override
    // visitGenericTypeAlias.
  }

  @override
  void visitHideCombinator(HideCombinator node) {}

  @override
  void visitIfElement(IfElement node) {
    flowAnalysis.flow?.ifStatement_conditionBegin();
    Expression condition = node.condition;
    InferenceContext.setType(condition, typeProvider.boolType);
    condition.accept(this);
    condition = node.condition;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);

    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);

    flowAnalysis.flow?.ifStatement_thenBegin(condition, node);
    node.thenElement.accept(this);
    nullSafetyDeadCodeVerifier.flowEnd(node.thenElement);

    var elseElement = node.elseElement;
    if (elseElement != null) {
      flowAnalysis.flow?.ifStatement_elseBegin();
      elseElement.accept(this);
      nullSafetyDeadCodeVerifier.flowEnd(elseElement);
    }

    flowAnalysis.flow?.ifStatement_end(elseElement != null);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitIfStatement(IfStatement node) {
    checkUnreachableNode(node);
    flowAnalysis.flow?.ifStatement_conditionBegin();

    Expression condition = node.condition;

    InferenceContext.setType(condition, typeProvider.boolType);
    condition.accept(this);
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

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitIndexExpression(covariant IndexExpressionImpl node) {
    node.target?.accept(this);
    startNullAwareIndexExpression(node);

    var result = _propertyElementResolver.resolveIndexExpression(
      node: node,
      hasRead: true,
      hasWrite: false,
    );

    var element = result.readElement;
    node.staticElement = element as MethodElement?;

    InferenceContext.setType(node.index, result.indexContextType);
    node.index.accept(this);
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
    inferenceHelper.recordStaticType(node, type);
    insertGenericFunctionInstantiation(node);

    nullShortingTermination(node);
  }

  @override
  void visitInstanceCreationExpression(
      covariant InstanceCreationExpressionImpl node) {
    _instanceCreationExpressionResolver.resolve(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    super.visitIsExpression(node);
    flowAnalysis.isExpression(node);
  }

  @override
  void visitLabel(Label node) {}

  @override
  void visitLabeledStatement(LabeledStatement node) {
    flowAnalysis.labeledStatement_enter(node);
    super.visitLabeledStatement(node);
    flowAnalysis.labeledStatement_exit(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  void visitListLiteral(covariant ListLiteralImpl node) {
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveListLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    flowAnalysis.topLevelDeclaration_enter(node, node.parameters);
    flowAnalysis.executableDeclaration_enter(node, node.parameters, false);

    DartType returnType = node.declaredElement!.returnType;
    InferenceContext.setType(node.body, returnType);

    var outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.declaredElement;
      assert(_thisType == null);
      _setupThisType();
      super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
      _thisType = null;
    }

    if (!node.isSetter) {
      // TODO(scheglov) encapsulate
      var bodyContext = BodyInferenceContext.of(node.body);
      checkForBodyMayCompleteNormally(
        returnType: bodyContext?.contextType,
        body: node.body,
        errorNode: node.name,
      );
    }
    flowAnalysis.executableDeclaration_exit(node.body, false);
    flowAnalysis.topLevelDeclaration_exit();
    nullSafetyDeadCodeVerifier.flowEnd(node);

    node.accept(elementResolver);
    // Note: no need to call the typeAnalyzer since it does not override
    // visitMethodDeclaration.
  }

  @override
  void visitMethodInvocation(covariant MethodInvocationImpl node) {
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
        whyNotPromotedList: whyNotPromotedList);

    var functionRewrite = MethodInvocationResolver.getRewriteResult(node);
    if (functionRewrite != null) {
      _resolveRewrittenFunctionExpressionInvocation(
          functionRewrite, whyNotPromotedList);
      nullShortingTermination(node, discardType: true);
    } else {
      nullShortingTermination(node);
    }
    insertGenericFunctionInstantiation(node);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    //
    // Continue the class resolution.
    //
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement!;
      super.visitMixinDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      enclosingClass = outerType;
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    InferenceContext.setTypeFromNode(node.expression, node);
    super.visitNamedExpression(node);
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
  void visitNode(AstNode node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    flowAnalysis.flow?.nullLiteral(node);
    super.visitNullLiteral(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    InferenceContext.setTypeFromNode(node.expression, node);
    super.visitParenthesizedExpression(node);
    flowAnalysis.flow?.parenthesizedExpression(node, node.expression);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _postfixExpressionResolver.resolve(node as PostfixExpressionImpl);
    insertGenericFunctionInstantiation(node);
  }

  @override
  void visitPrefixedIdentifier(covariant PrefixedIdentifierImpl node) {
    _prefixedIdentifierResolver.resolve(node);
    insertGenericFunctionInstantiation(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _prefixExpressionResolver.resolve(node as PrefixExpressionImpl);
    insertGenericFunctionInstantiation(node);
  }

  @override
  void visitPropertyAccess(covariant PropertyAccessImpl node) {
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
      type = inferenceHelper.inferTearOff(node, propertyName, type);
    }

    inferenceHelper.recordStaticType(propertyName, type);
    inferenceHelper.recordStaticType(node, type);
    insertGenericFunctionInstantiation(node);

    nullShortingTermination(node);
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
    node.accept(elementResolver);
    InferenceContext.setType(node.argumentList, node.staticElement?.type);
    visitArgumentList(node.argumentList,
        whyNotPromotedList: whyNotPromotedList);
    node.accept(typeAnalyzer);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    super.visitRethrowExpression(node);
    flowAnalysis.flow?.handleExit();
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    InferenceContext.setType(
      node.expression,
      inferenceContext.bodyContext?.contextType,
    );

    super.visitReturnStatement(node);

    inferenceContext.bodyContext?.addReturnExpression(node.expression);
    flowAnalysis.flow?.handleExit();

    var expression = node.expression;
    if (expression != null) {
      insertImplicitCallReference(expression);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {}

  @override
  void visitSimpleIdentifier(covariant SimpleIdentifierImpl node) {
    _simpleIdentifierResolver.resolve(node);
    insertGenericFunctionInstantiation(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    super.visitSpreadElement(node);

    if (!node.isNullAware) {
      nullableDereferenceVerifier.expression(
        CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD,
        node.expression,
      );
    }
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    var whyNotPromotedList = <Map<DartType, NonPromotionReason> Function()>[];
    node.accept(elementResolver);
    InferenceContext.setType(node.argumentList, node.staticElement?.type);
    visitArgumentList(node.argumentList,
        whyNotPromotedList: whyNotPromotedList);
    node.accept(typeAnalyzer);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    checkUnreachableNode(node);

    InferenceContext.setType(
        node.expression, _enclosingSwitchStatementExpressionType);
    super.visitSwitchCase(node);

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
    super.visitSwitchDefault(node);
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
  void visitThrowExpression(ThrowExpression node) {
    super.visitThrowExpression(node);
    flowAnalysis.flow?.handleExit();
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
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyEnd(body);
      nullSafetyDeadCodeVerifier.flowEnd(node.body);
      nullSafetyDeadCodeVerifier.tryStatementEnter(node);

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
      nullSafetyDeadCodeVerifier.tryStatementExit(node);
    }

    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(
          catchClauses.isNotEmpty ? node : body);
      finallyBlock.accept(this);
      flow.tryFinallyStatement_end();
    }
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
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    flowAnalysis.variableDeclarationList(node);
    for (VariableDeclaration decl in node.variables) {
      VariableElement variableElement = decl.declaredElement!;
      InferenceContext.setType(decl, variableElement.type);
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    checkUnreachableNode(node);

    Expression condition = node.condition;
    InferenceContext.setType(condition, typeProvider.boolType);

    flowAnalysis.flow?.whileStatement_conditionBegin(node);
    condition.accept(this);
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
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _yieldStatementResolver.resolve(node);
  }

  /// Creates a union of `T | Future<T>`, unless `T` is already a
  /// future-union, in which case it simply returns `T`.
  DartType _createFutureOr(DartType type) {
    if (type.isDartAsyncFutureOr) {
      return type;
    }
    return typeProvider.futureOrType(type);
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
  ) {
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
        node as FunctionExpressionInvocationImpl, whyNotPromotedList);

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

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments.
  ///
  /// An error will be reported to [onError] if any of the arguments cannot be
  /// matched to a parameter. onError will be provided the node of the first
  /// argument that is not matched. onError can be null to ignore the error.
  ///
  /// Returns the parameters that correspond to the arguments. If no parameter
  /// matched an argument, that position will be `null` in the list.
  static List<ParameterElement?> resolveArgumentsToParameters(
      ArgumentList argumentList,
      List<ParameterElement> parameters,
      void Function(ErrorCode errorCode, AstNode node,
              [List<Object> arguments])?
          onError) {
    if (parameters.isEmpty && argumentList.arguments.isEmpty) {
      return const <ParameterElement>[];
    }
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
    HashSet<String>? usedNames;
    bool noBlankArguments = true;
    Expression? firstUnresolvedArgument;
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpressionImpl) {
        var nameNode = argument.name.label;
        String name = nameNode.name;
        var element = namedParameters != null ? namedParameters[name] : null;
        if (element == null) {
          if (onError != null) {
            onError(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, nameNode,
                [name]);
          }
        } else {
          resolvedParameters[i] = element;
          nameNode.staticElement = element;
        }
        usedNames ??= HashSet<String>();
        if (!usedNames.add(name)) {
          if (onError != null) {
            onError(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, nameNode,
                [name]);
          }
        }
      } else {
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
    if (positionalArgumentCount < requiredParameterCount && noBlankArguments) {
      if (onError != null) {
        onError(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS,
            argumentList, [requiredParameterCount, positionalArgumentCount]);
      }
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
      if (onError != null) {
        onError(errorCode, firstUnresolvedArgument!,
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
            typeProvider,
            errorListener,
            featureSet,
            FlowAnalysisHelperForMigration(
                typeSystem, migrationResolutionHooks, featureSet),
            migrationResolutionHooks,
            migrationResolutionHooks);

  @override
  void visitConditionalExpression(covariant ConditionalExpressionImpl node) {
    var conditionalKnownValue =
        _migrationResolutionHooks.getConditionalKnownValue(node);
    if (conditionalKnownValue == null) {
      super.visitConditionalExpression(node);
      return;
    } else {
      var subexpressionToKeep =
          conditionalKnownValue ? node.thenExpression : node.elseExpression;
      subexpressionToKeep.accept(this);
      typeAnalyzer.recordStaticType(node, subexpressionToKeep.typeOrThrow);
    }
  }

  @override
  void visitIfElement(IfElement node) {
    var conditionalKnownValue =
        _migrationResolutionHooks.getConditionalKnownValue(node);
    if (conditionalKnownValue == null) {
      super.visitIfElement(node);
      return;
    } else {
      (conditionalKnownValue ? node.thenElement : node.elseElement)
          ?.accept(this);
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
class ScopeResolverVisitor extends ResolverBase {
  static const _nameScopeProperty = 'nameScope';

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
  /// node being visited
  /// [typeProvider] is the object used to access the types from the core
  /// library.
  /// [errorListener] is the error listener that will be informed of any errors
  /// that are found during resolution.
  /// [nameScope] is the scope used to resolve identifiers in the node that will
  /// first be visited.  If `null` or unspecified, a new [LibraryScope] will be
  /// created based on [definingLibrary] and [typeProvider].
  ScopeResolverVisitor(LibraryElementImpl definingLibrary, Source source,
      TypeProvider typeProvider, AnalysisErrorListener errorListener,
      {Scope? nameScope})
      : nameScope = nameScope ?? LibraryScope(definingLibrary),
        super(definingLibrary, source, typeProvider as TypeProviderImpl,
            errorListener);

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
    node.superclass2.accept(this);
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

      nameScope = ClassScope(nameScope, element);
      visitEnumMembersInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitEnumMembersInScope(EnumDeclaration node) {
    node.documentationComment?.accept(this);
    node.constants.accept(this);
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
    if (expression is PrefixedIdentifier) {
      return expression.staticElement;
    } else if (expression is PropertyAccess) {
      return expression.propertyName.staticElement;
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
