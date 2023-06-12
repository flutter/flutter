// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        LocatedMessage,
        Message,
        MessageCode,
        messageAbstractClassMember,
        messageAbstractLateField,
        messageAbstractStaticField,
        messageConstConstructorWithBody,
        messageConstFactory,
        messageConstructorWithTypeParameters,
        messageDirectiveAfterDeclaration,
        messageExpectedStatement,
        messageExternalField,
        messageExternalLateField,
        messageFieldInitializerOutsideConstructor,
        messageIllegalAssignmentToNonAssignable,
        messageInterpolationInUri,
        messageInvalidInitializer,
        messageInvalidSuperInInitializer,
        messageInvalidThisInInitializer,
        messageMissingAssignableSelector,
        messageNativeClauseShouldBeAnnotation,
        messageOperatorWithTypeParameters,
        messagePositionalAfterNamedArgument,
        templateDuplicateLabelInSwitchStatement,
        templateExpectedButGot,
        templateExpectedIdentifier,
        templateExperimentNotEnabled,
        templateInternalProblemUnhandled,
        templateUnexpectedToken;
import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show
        Assert,
        BlockKind,
        ConstructorReferenceContext,
        DeclarationKind,
        FormalParameterKind,
        IdentifierContext,
        MemberKind,
        optional,
        Parser;
import 'package:_fe_analyzer_shared/src/parser/quote.dart';
import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart'
    show NullValue, StackListener;
import 'package:_fe_analyzer_shared/src/scanner/errors.dart'
    show translateErrorToken;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' hide StringToken;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show StringToken, SyntheticStringToken, SyntheticToken;
import 'package:_fe_analyzer_shared/src/scanner/token_constants.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart'
    show
        ClassDeclarationImpl,
        CompilationUnitImpl,
        ExtensionDeclarationImpl,
        ImportDirectiveImpl,
        MethodInvocationImpl,
        MixinDeclarationImpl,
        SimpleIdentifierImpl,
        TypeArgumentListImpl,
        TypeParameterImpl;
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/fasta/error_converter.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

const _invalidCollectionElement = _InvalidCollectionElement._();

/// A parser listener that builds the analyzer's AST structure.
class AstBuilder extends StackListener {
  final AstFactoryImpl ast = astFactory;

  final FastaErrorReporter errorReporter;
  final Uri fileUri;
  ScriptTag? scriptTag;
  final List<Directive> directives = <Directive>[];
  final List<CompilationUnitMember> declarations = <CompilationUnitMember>[];

  @override
  final Uri uri;

  /// The parser that uses this listener, used to parse optional parts, e.g.
  /// `native` support.
  late Parser parser;

  /// The class currently being parsed, or `null` if no class is being parsed.
  ClassDeclarationImpl? classDeclaration;

  /// The mixin currently being parsed, or `null` if no mixin is being parsed.
  MixinDeclarationImpl? mixinDeclaration;

  /// The extension currently being parsed, or `null` if none.
  ExtensionDeclarationImpl? extensionDeclaration;

  /// If true, this is building a full AST. Otherwise, only create method
  /// bodies.
  final bool isFullAst;

  /// `true` if the `native` clause is allowed
  /// in class, method, and function declarations.
  ///
  /// This is being replaced by the @native(...) annotation.
  //
  // TODO(danrubel) Move this flag to a better location
  // and should only be true if either:
  // * The current library is a platform library
  // * The current library has an import that uses the scheme "dart-ext".
  bool allowNativeClause = false;

  StringLiteral? nativeName;

  bool parseFunctionBodies = true;

  /// `true` if non-nullable behavior is enabled.
  final bool enableNonNullable;

  /// `true` if spread-collections behavior is enabled
  final bool enableSpreadCollections;

  /// `true` if control-flow-collections behavior is enabled
  final bool enableControlFlowCollections;

  /// `true` if triple-shift behavior is enabled
  final bool enableTripleShift;

  /// `true` if nonfunction-type-aliases behavior is enabled
  final bool enableNonFunctionTypeAliases;

  /// `true` if variance behavior is enabled
  final bool enableVariance;

  /// `true` if constructor tearoffs are enabled
  final bool enableConstructorTearoffs;

  /// `true` if extension types are enabled
  final bool enableExtensionTypes;

  /// `true` if named arguments anywhere are enabled
  final bool enableNamedArgumentsAnywhere;

  /// `true` if super parameters are enabled
  final bool enableSuperParameters;

  final FeatureSet _featureSet;

  AstBuilder(ErrorReporter? errorReporter, this.fileUri, this.isFullAst,
      this._featureSet,
      [Uri? uri])
      : errorReporter = FastaErrorReporter(errorReporter),
        enableNonNullable = _featureSet.isEnabled(Feature.non_nullable),
        enableSpreadCollections =
            _featureSet.isEnabled(Feature.spread_collections),
        enableControlFlowCollections =
            _featureSet.isEnabled(Feature.control_flow_collections),
        enableTripleShift = _featureSet.isEnabled(Feature.triple_shift),
        enableNonFunctionTypeAliases =
            _featureSet.isEnabled(Feature.nonfunction_type_aliases),
        enableVariance = _featureSet.isEnabled(Feature.variance),
        enableConstructorTearoffs =
            _featureSet.isEnabled(Feature.constructor_tearoffs),
        enableExtensionTypes = _featureSet.isEnabled(Feature.extension_types),
        enableNamedArgumentsAnywhere =
            _featureSet.isEnabled(Feature.named_arguments_anywhere),
        enableSuperParameters = _featureSet.isEnabled(Feature.super_parameters),
        uri = uri ?? fileUri;

  NodeList<ClassMember> get currentDeclarationMembers {
    if (classDeclaration != null) {
      return classDeclaration!.members;
    } else if (mixinDeclaration != null) {
      return mixinDeclaration!.members;
    } else {
      return extensionDeclaration!.members;
    }
  }

  SimpleIdentifier? get currentDeclarationName {
    if (classDeclaration != null) {
      return classDeclaration!.name;
    } else if (mixinDeclaration != null) {
      return mixinDeclaration!.name;
    } else {
      return extensionDeclaration!.name;
    }
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled = false, List<LocatedMessage>? context}) {
    if (directives.isEmpty &&
        (message.code.analyzerCodes
                ?.contains('NON_PART_OF_DIRECTIVE_IN_PART') ??
            false)) {
      message = messageDirectiveAfterDeclaration;
    }
    errorReporter.reportMessage(message, charOffset, length);
  }

  @override
  void beginAsOperatorType(Token asOperator) {}

  @override
  void beginCascade(Token token) {
    assert(optional('..', token) || optional('?..', token));
    debugEvent("beginCascade");

    var expression = pop() as Expression;
    push(token);
    if (expression is CascadeExpression) {
      push(expression);
    } else {
      push(ast.cascadeExpression(expression, <Expression>[]));
    }
    push(NullValue.CascadeReceiver);
  }

  @override
  void beginClassDeclaration(Token begin, Token? abstractToken, Token name) {
    assert(classDeclaration == null &&
        mixinDeclaration == null &&
        extensionDeclaration == null);
    push(_Modifiers()..abstractKeyword = abstractToken);
  }

  @override
  void beginCompilationUnit(Token token) {
    push(token);
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token? nameToken) {
    assert(optional('extension', extensionKeyword));
    assert(classDeclaration == null &&
        mixinDeclaration == null &&
        extensionDeclaration == null);
    debugEvent("ExtensionHeader");

    var typeParameters = pop() as TypeParameterList?;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, extensionKeyword);

    SimpleIdentifier? name;
    if (nameToken != null) {
      name = ast.simpleIdentifier(nameToken, isDeclaration: true);
    }

    extensionDeclaration = ast.extensionDeclaration(
      comment: comment,
      metadata: metadata,
      extensionKeyword: extensionKeyword,
      typeKeyword: null,
      name: name,
      typeParameters: typeParameters,
      onKeyword: Tokens.on_(),
      extendedType: ast.namedType(
        name: _tmpSimpleIdentifier(),
      ), // extendedType is set in [endExtensionDeclaration]
      showClause: null,
      hideClause: null,
      leftBracket: Tokens.openCurlyBracket(),
      rightBracket: Tokens.closeCurlyBracket(),
      members: [],
    );

    declarations.add(extensionDeclaration!);
  }

  @override
  void beginFactoryMethod(DeclarationKind declarationKind, Token lastConsumed,
      Token? externalToken, Token? constToken) {
    push(_Modifiers()
      ..externalKeyword = externalToken
      ..finalConstOrVarKeyword = constToken);
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token? requiredToken,
      Token? covariantToken, Token? varFinalOrConst) {
    push(_Modifiers()
      ..covariantKeyword = covariantToken
      ..finalConstOrVarKeyword = varFinalOrConst
      ..requiredToken = requiredToken);
  }

  @override
  void beginFormalParameterDefaultValueExpression() {}

  @override
  void beginIfControlFlow(Token ifToken) {
    push(ifToken);
  }

  @override
  void beginIsOperatorType(Token asOperator) {}

  @override
  void beginLiteralString(Token literalString) {
    assert(identical(literalString.kind, STRING_TOKEN));
    debugEvent("beginLiteralString");

    push(literalString);
  }

  @override
  void beginMetadataStar(Token token) {
    debugEvent("beginMetadataStar");
  }

  @override
  void beginMethod(
      DeclarationKind declarationKind,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? varFinalOrConst,
      Token? getOrSet,
      Token name) {
    _Modifiers modifiers = _Modifiers();
    if (externalToken != null) {
      assert(externalToken.isModifier);
      modifiers.externalKeyword = externalToken;
    }
    if (staticToken != null) {
      assert(staticToken.isModifier);
      String? className = classDeclaration != null
          ? classDeclaration!.name.name
          : (mixinDeclaration != null
              ? mixinDeclaration!.name.name
              : extensionDeclaration!.name?.name);
      if (name.lexeme != className || getOrSet != null) {
        modifiers.staticKeyword = staticToken;
      }
    }
    if (covariantToken != null) {
      assert(covariantToken.isModifier);
      modifiers.covariantKeyword = covariantToken;
    }
    if (varFinalOrConst != null) {
      assert(varFinalOrConst.isModifier);
      modifiers.finalConstOrVarKeyword = varFinalOrConst;
    }
    push(modifiers);
  }

  @override
  void beginMixinDeclaration(Token mixinKeyword, Token name) {
    assert(classDeclaration == null &&
        mixinDeclaration == null &&
        extensionDeclaration == null);
  }

  @override
  void beginNamedMixinApplication(
      Token begin, Token? abstractToken, Token name) {
    push(_Modifiers()..abstractKeyword = abstractToken);
  }

  @override
  void beginTopLevelMethod(Token lastConsumed, Token? externalToken) {
    push(_Modifiers()..externalKeyword = externalToken);
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    var name = pop() as SimpleIdentifier;
    var metadata = pop() as List<Annotation>?;

    var comment = _findComment(metadata, name.beginToken);
    var typeParameter = ast.typeParameter(comment, metadata, name, null, null);
    push(typeParameter);
  }

  @override
  void beginVariablesDeclaration(
      Token token, Token? lateToken, Token? varFinalOrConst) {
    debugEvent("beginVariablesDeclaration");
    if (varFinalOrConst != null || lateToken != null) {
      push(_Modifiers()
        ..finalConstOrVarKeyword = varFinalOrConst
        ..lateToken = lateToken);
    } else {
      push(NullValue.Modifiers);
    }
  }

  ConstructorInitializer? buildInitializer(Object initializerObject) {
    if (initializerObject is FunctionExpressionInvocation) {
      Expression function = initializerObject.function;
      if (function is SuperExpression) {
        return ast.superConstructorInvocation(
            function.superKeyword, null, null, initializerObject.argumentList);
      }
      if (function is ThisExpression) {
        return ast.redirectingConstructorInvocation(
            function.thisKeyword, null, null, initializerObject.argumentList);
      }
      return null;
    }

    if (initializerObject is MethodInvocation) {
      var target = initializerObject.target;
      if (target is SuperExpression) {
        return ast.superConstructorInvocation(
            target.superKeyword,
            initializerObject.operator,
            initializerObject.methodName,
            initializerObject.argumentList);
      }
      if (target is ThisExpression) {
        return ast.redirectingConstructorInvocation(
            target.thisKeyword,
            initializerObject.operator,
            initializerObject.methodName,
            initializerObject.argumentList);
      }
      return buildInitializerTargetExpressionRecovery(
          target, initializerObject);
    }

    if (initializerObject is PropertyAccess) {
      return buildInitializerTargetExpressionRecovery(
          initializerObject.target, initializerObject);
    }

    if (initializerObject is AssignmentExpression) {
      Token? thisKeyword;
      Token? period;
      SimpleIdentifier fieldName;
      Expression left = initializerObject.leftHandSide;
      if (left is PropertyAccess) {
        var target = left.target;
        if (target is ThisExpression) {
          thisKeyword = target.thisKeyword;
          period = left.operator;
        } else {
          assert(target is SuperExpression);
          // Recovery:
          // Parser has reported FieldInitializedOutsideDeclaringClass.
        }
        fieldName = left.propertyName;
      } else if (left is SimpleIdentifier) {
        fieldName = left;
      } else {
        // Recovery:
        // Parser has reported invalid assignment.
        var superExpression = left as SuperExpression;
        fieldName = ast.simpleIdentifier(superExpression.superKeyword);
      }
      return ast.constructorFieldInitializer(thisKeyword, period, fieldName,
          initializerObject.operator, initializerObject.rightHandSide);
    }

    if (initializerObject is AssertInitializer) {
      return initializerObject;
    }

    if (initializerObject is IndexExpression) {
      return buildInitializerTargetExpressionRecovery(
          initializerObject.target, initializerObject);
    }

    if (initializerObject is CascadeExpression) {
      return buildInitializerTargetExpressionRecovery(
          initializerObject.target, initializerObject);
    }

    return null;
  }

  ConstructorInitializer? buildInitializerTargetExpressionRecovery(
      Expression? target, Object initializerObject) {
    ArgumentList? argumentList;
    while (true) {
      if (target is FunctionExpressionInvocation) {
        argumentList = target.argumentList;
        target = target.function;
      } else if (target is MethodInvocation) {
        argumentList = target.argumentList;
        target = target.target;
      } else if (target is PropertyAccess) {
        argumentList = null;
        target = target.target;
      } else {
        break;
      }
    }
    if (target is SuperExpression) {
      // TODO(danrubel): Consider generating this error in the parser
      // This error is also reported in the body builder
      handleRecoverableError(messageInvalidSuperInInitializer,
          target.superKeyword, target.superKeyword);
      return ast.superConstructorInvocation(target.superKeyword, null, null,
          argumentList ?? _syntheticArgumentList(target.superKeyword));
    } else if (target is ThisExpression) {
      // TODO(danrubel): Consider generating this error in the parser
      // This error is also reported in the body builder
      handleRecoverableError(messageInvalidThisInInitializer,
          target.thisKeyword, target.thisKeyword);
      return ast.redirectingConstructorInvocation(target.thisKeyword, null,
          null, argumentList ?? _syntheticArgumentList(target.thisKeyword));
    }
    return null;
  }

  void checkFieldFormalParameters(FormalParameterList? parameterList) {
    var parameters = parameterList?.parameters;
    if (parameters != null) {
      parameters.forEach((FormalParameter param) {
        if (param is FieldFormalParameter) {
          // This error is reported in the BodyBuilder.endFormalParameter.
          handleRecoverableError(messageFieldInitializerOutsideConstructor,
              param.thisKeyword, param.thisKeyword);
        }
      });
    }
  }

  @override
  void debugEvent(String name) {
    // printEvent('AstBuilder: $name');
  }

  void doDotExpression(Token dot) {
    var identifierOrInvoke = pop() as Expression;
    var receiver = pop() as Expression?;
    if (identifierOrInvoke is SimpleIdentifier) {
      if (receiver is SimpleIdentifier && identical('.', dot.stringValue)) {
        push(ast.prefixedIdentifier(receiver, dot, identifierOrInvoke));
      } else {
        push(ast.propertyAccess(receiver, dot, identifierOrInvoke));
      }
    } else if (identifierOrInvoke is MethodInvocationImpl) {
      assert(identifierOrInvoke.target == null);
      identifierOrInvoke
        ..target = receiver
        ..operator = dot;
      push(identifierOrInvoke);
    } else {
      // This same error is reported in BodyBuilder.doDotOrCascadeExpression
      Token token = identifierOrInvoke.beginToken;
      // TODO(danrubel): Consider specializing the error message based
      // upon the type of expression. e.g. "x.this" -> templateThisAsIdentifier
      handleRecoverableError(
          templateExpectedIdentifier.withArguments(token), token, token);
      SimpleIdentifier identifier =
          ast.simpleIdentifier(token, isDeclaration: false);
      push(ast.propertyAccess(receiver, dot, identifier));
    }
  }

  void doInvocation(
      TypeArgumentList? typeArguments, MethodInvocationImpl arguments) {
    var receiver = pop() as Expression;
    if (receiver is SimpleIdentifierImpl) {
      arguments.methodName = receiver;
      if (typeArguments != null) {
        arguments.typeArguments = typeArguments;
      }
      push(arguments);
    } else {
      push(ast.functionExpressionInvocation(
          receiver, typeArguments, arguments.argumentList));
    }
  }

  void doPropertyGet() {}

  @override
  void endArguments(int count, Token leftParenthesis, Token rightParenthesis) {
    assert(optional('(', leftParenthesis));
    assert(optional(')', rightParenthesis));
    debugEvent("Arguments");

    var expressions = popTypedList2<Expression>(count);
    ArgumentList arguments =
        ast.argumentList(leftParenthesis, expressions, rightParenthesis);

    if (!enableNamedArgumentsAnywhere) {
      bool hasSeenNamedArgument = false;
      for (Expression expression in expressions) {
        if (expression is NamedExpression) {
          hasSeenNamedArgument = true;
        } else if (hasSeenNamedArgument) {
          // Positional argument after named argument.
          handleRecoverableError(messagePositionalAfterNamedArgument,
              expression.beginToken, expression.endToken);
        }
      }
    }

    push(ast.methodInvocation(
        null, null, _tmpSimpleIdentifier(), null, arguments));
  }

  @override
  void endAsOperatorType(Token asOperator) {
    debugEvent("AsOperatorType");
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token? comma, Token semicolon) {
    assert(optional('assert', assertKeyword));
    assert(optional('(', leftParenthesis));
    assert(optionalOrNull(',', comma));
    assert(kind != Assert.Statement || optionalOrNull(';', semicolon));
    debugEvent("Assert");

    var message = popIfNotNull(comma) as Expression?;
    var condition = pop() as Expression;
    switch (kind) {
      case Assert.Expression:
        // The parser has already reported an error indicating that assert
        // cannot be used in an expression. Insert a placeholder.
        List<Expression> arguments = <Expression>[condition];
        if (message != null) {
          arguments.add(message);
        }
        push(ast.functionExpressionInvocation(
            ast.simpleIdentifier(assertKeyword),
            null,
            ast.argumentList(
                leftParenthesis, arguments, leftParenthesis.endGroup!)));
        break;
      case Assert.Initializer:
        push(ast.assertInitializer(assertKeyword, leftParenthesis, condition,
            comma, message, leftParenthesis.endGroup!));
        break;
      case Assert.Statement:
        push(ast.assertStatement(assertKeyword, leftParenthesis, condition,
            comma, message, leftParenthesis.endGroup!, semicolon));
        break;
    }
  }

  @override
  void endAwaitExpression(Token awaitKeyword, Token endToken) {
    assert(optional('await', awaitKeyword));
    debugEvent("AwaitExpression");

    var expression = pop() as Expression;
    push(ast.awaitExpression(awaitKeyword, expression));
  }

  @override
  void endBinaryExpression(Token operatorToken) {
    assert(operatorToken.isOperator ||
        optional('.', operatorToken) ||
        optional('?.', operatorToken) ||
        optional('..', operatorToken) ||
        optional('?..', operatorToken) ||
        optional('===', operatorToken) ||
        optional('!==', operatorToken));
    debugEvent("BinaryExpression");

    if (identical(".", operatorToken.stringValue) ||
        identical("?.", operatorToken.stringValue) ||
        identical("..", operatorToken.stringValue) ||
        identical("?..", operatorToken.stringValue)) {
      doDotExpression(operatorToken);
    } else {
      var right = pop() as Expression;
      var left = pop() as Expression;
      reportErrorIfSuper(right);
      push(ast.binaryExpression(left, operatorToken, right));
      if (!enableTripleShift && operatorToken.type == TokenType.GT_GT_GT) {
        var feature = ExperimentalFeatures.triple_shift;
        handleRecoverableError(
          templateExperimentNotEnabled.withArguments(
            feature.enableString,
            _versionAsString(ExperimentStatus.currentVersion),
          ),
          operatorToken,
          operatorToken,
        );
      }
    }
  }

  @override
  void endBlock(
      int count, Token leftBracket, Token rightBracket, BlockKind blockKind) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("Block");

    var statements = popTypedList2<Statement>(count);
    push(ast.block(leftBracket, statements, rightBracket));
  }

  @override
  void endBlockFunctionBody(int count, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("BlockFunctionBody");

    var statements = popTypedList2<Statement>(count);
    Block block = ast.block(leftBracket, statements, rightBracket);
    var star = pop() as Token?;
    var asyncKeyword = pop() as Token?;
    if (parseFunctionBodies) {
      push(ast.blockFunctionBody(asyncKeyword, star, block));
    } else {
      // TODO(danrubel): Skip the block rather than parsing it.
      push(ast.emptyFunctionBody(
          SyntheticToken(TokenType.SEMICOLON, leftBracket.charOffset)));
    }
  }

  @override
  void endCascade() {
    debugEvent("Cascade");

    var expression = pop() as Expression;
    var receiver = pop() as CascadeExpression;
    pop(); // Token.
    receiver.cascadeSections.add(expression);
    push(receiver);
  }

  @override
  void endClassConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    assert(getOrSet == null ||
        optional('get', getOrSet) ||
        optional('set', getOrSet));
    debugEvent("ClassConstructor");

    var bodyObject = pop();
    var initializers = (pop() as List<ConstructorInitializer>?) ?? const [];
    var separator = pop() as Token?;
    var parameters = pop() as FormalParameterList;
    var typeParameters = pop() as TypeParameterList?;
    var name = pop();
    pop(); // return type
    var modifiers = pop() as _Modifiers?;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, beginToken);

    ConstructorName? redirectedConstructor;
    FunctionBody body;
    if (bodyObject is FunctionBody) {
      body = bodyObject;
    } else if (bodyObject is _RedirectingFactoryBody) {
      separator = bodyObject.equalToken;
      redirectedConstructor = bodyObject.constructorName;
      body = ast.emptyFunctionBody(endToken);
    } else {
      internalProblem(
          templateInternalProblemUnhandled.withArguments(
              "${bodyObject.runtimeType}", "bodyObject"),
          beginToken.charOffset,
          uri);
    }

    SimpleIdentifier prefixOrName;
    Token? period;
    SimpleIdentifier? nameOrNull;
    if (name is SimpleIdentifier) {
      prefixOrName = name;
    } else if (name is PrefixedIdentifier) {
      prefixOrName = name.prefix;
      period = name.period;
      nameOrNull = name.identifier;
    } else if (name is _OperatorName) {
      prefixOrName = name.name;
    } else {
      throw UnimplementedError(
          'name is an instance of ${name.runtimeType} in endClassConstructor');
    }

    if (typeParameters != null) {
      // Outline builder also reports this error message.
      handleRecoverableError(messageConstructorWithTypeParameters,
          typeParameters.beginToken, typeParameters.endToken);
    }
    if (modifiers?.constKeyword != null &&
        (body.length > 1 || body.beginToken.lexeme != ';')) {
      // This error is also reported in BodyBuilder.finishFunction
      Token bodyToken = body.beginToken;
      // Token bodyToken = body.beginToken ?? modifiers.constKeyword;
      handleRecoverableError(
          messageConstConstructorWithBody, bodyToken, bodyToken);
    }
    ConstructorDeclaration constructor = ast.constructorDeclaration(
        comment,
        metadata,
        modifiers?.externalKeyword,
        modifiers?.finalConstOrVarKeyword,
        null,
        // TODO(paulberry): factoryKeyword
        ast.simpleIdentifier(prefixOrName.token),
        period,
        nameOrNull,
        parameters,
        separator,
        initializers,
        redirectedConstructor,
        body);
    currentDeclarationMembers.add(constructor);
    if (mixinDeclaration != null) {
      // TODO (danrubel): Report an error if this is a mixin declaration.
    }
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("ClassDeclaration");
    classDeclaration = null;
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    assert(optional('factory', factoryKeyword));
    assert(optional(';', endToken) || optional('}', endToken));
    debugEvent("ClassFactoryMethod");

    FunctionBody body;
    Token? separator;
    ConstructorName? redirectedConstructor;
    var bodyObject = pop();
    if (bodyObject is FunctionBody) {
      body = bodyObject;
    } else if (bodyObject is _RedirectingFactoryBody) {
      separator = bodyObject.equalToken;
      redirectedConstructor = bodyObject.constructorName;
      body = ast.emptyFunctionBody(endToken);
    } else {
      internalProblem(
          templateInternalProblemUnhandled.withArguments(
              "${bodyObject.runtimeType}", "bodyObject"),
          beginToken.charOffset,
          uri);
    }

    var parameters = pop() as FormalParameterList;
    var typeParameters = pop() as TypeParameterList?;
    var constructorName = pop() as Identifier;
    var modifiers = pop() as _Modifiers?;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, beginToken);

    if (typeParameters != null) {
      // TODO(danrubel): Update OutlineBuilder to report this error message.
      handleRecoverableError(messageConstructorWithTypeParameters,
          typeParameters.beginToken, typeParameters.endToken);
    }

    // Decompose the preliminary ConstructorName into the type name and
    // the actual constructor name.
    SimpleIdentifier returnType;
    Token? period;
    SimpleIdentifier? name;
    Identifier typeName = constructorName;
    if (typeName is SimpleIdentifier) {
      returnType = typeName;
    } else if (typeName is PrefixedIdentifier) {
      returnType = typeName.prefix;
      period = typeName.period;
      name =
          ast.simpleIdentifier(typeName.identifier.token, isDeclaration: true);
    } else {
      throw UnimplementedError();
    }

    currentDeclarationMembers.add(ast.constructorDeclaration(
        comment,
        metadata,
        modifiers?.externalKeyword,
        modifiers?.finalConstOrVarKeyword,
        factoryKeyword,
        ast.simpleIdentifier(returnType.token),
        period,
        name,
        parameters,
        separator,
        null,
        redirectedConstructor,
        body));
  }

  @override
  void endClassFields(
      Token? abstractToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("Fields");

    if (abstractToken != null) {
      if (!enableNonNullable) {
        handleRecoverableError(
            messageAbstractClassMember, abstractToken, abstractToken);
      } else {
        if (staticToken != null) {
          handleRecoverableError(
              messageAbstractStaticField, abstractToken, abstractToken);
        }
        if (lateToken != null) {
          handleRecoverableError(
              messageAbstractLateField, abstractToken, abstractToken);
        }
      }
    }
    if (externalToken != null) {
      if (!enableNonNullable) {
        handleRecoverableError(
            messageExternalField, externalToken, externalToken);
      } else if (lateToken != null) {
        handleRecoverableError(
            messageExternalLateField, externalToken, externalToken);
      }
    }

    var variables = popTypedList2<VariableDeclaration>(count);
    var type = pop() as TypeAnnotation?;
    var variableList = ast.variableDeclarationList2(
      lateKeyword: lateToken,
      keyword: varFinalOrConst,
      type: type,
      variables: variables,
    );
    var covariantKeyword = covariantToken;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, beginToken);
    currentDeclarationMembers.add(ast.fieldDeclaration2(
        comment: comment,
        metadata: metadata,
        abstractKeyword: abstractToken,
        covariantKeyword: covariantKeyword,
        externalKeyword: externalToken,
        staticKeyword: staticToken,
        fieldList: variableList,
        semicolon: semicolon));
  }

  @override
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    assert(getOrSet == null ||
        optional('get', getOrSet) ||
        optional('set', getOrSet));
    debugEvent("ClassMethod");

    var bodyObject = pop();
    pop(); // initializers
    pop(); // separator
    var parameters = pop() as FormalParameterList?;
    var typeParameters = pop() as TypeParameterList?;
    var name = pop();
    var returnType = pop() as TypeAnnotation?;
    var modifiers = pop() as _Modifiers?;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, beginToken);

    assert(parameters != null || optional('get', getOrSet!));

    FunctionBody body;
    if (bodyObject is FunctionBody) {
      body = bodyObject;
    } else if (bodyObject is _RedirectingFactoryBody) {
      body = ast.emptyFunctionBody(endToken);
    } else {
      internalProblem(
          templateInternalProblemUnhandled.withArguments(
              "${bodyObject.runtimeType}", "bodyObject"),
          beginToken.charOffset,
          uri);
    }

    Token? operatorKeyword;
    SimpleIdentifier nameId;
    if (name is SimpleIdentifier) {
      nameId = name;
    } else if (name is _OperatorName) {
      operatorKeyword = name.operatorKeyword;
      nameId = name.name;
      if (typeParameters != null) {
        handleRecoverableError(messageOperatorWithTypeParameters,
            typeParameters.beginToken, typeParameters.endToken);
      }
    } else {
      throw UnimplementedError(
          'name is an instance of ${name.runtimeType} in endClassMethod');
    }

    checkFieldFormalParameters(parameters);
    currentDeclarationMembers.add(ast.methodDeclaration(
        comment,
        metadata,
        modifiers?.externalKeyword,
        modifiers?.abstractKeyword ?? modifiers?.staticKeyword,
        returnType,
        getOrSet,
        operatorKeyword,
        nameId,
        typeParameters,
        parameters,
        body));
  }

  @override
  void endClassOrMixinOrExtensionBody(DeclarationKind kind, int memberCount,
      Token leftBracket, Token rightBracket) {
    // TODO(danrubel): consider renaming endClassOrMixinBody
    // to endClassOrMixinOrExtensionBody
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("ClassOrMixinBody");

    if (classDeclaration != null) {
      classDeclaration!
        ..leftBracket = leftBracket
        ..rightBracket = rightBracket;
    } else if (mixinDeclaration != null) {
      mixinDeclaration!
        ..leftBracket = leftBracket
        ..rightBracket = rightBracket;
    } else {
      extensionDeclaration!
        ..leftBracket = leftBracket
        ..rightBracket = rightBracket;
    }
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
    push(popTypedList<Combinator>(count) ?? NullValue.Combinators);
  }

  @override
  void endCompilationUnit(int count, Token endToken) {
    debugEvent("CompilationUnit");

    var beginToken = pop() as Token;
    checkEmpty(endToken.charOffset);

    CompilationUnitImpl unit = ast.compilationUnit(
        beginToken: beginToken,
        scriptTag: scriptTag,
        directives: directives,
        declarations: declarations,
        endToken: endToken,
        featureSet: _featureSet);
    push(unit);
  }

  @override
  void endConditionalExpression(Token question, Token colon) {
    assert(optional('?', question));
    assert(optional(':', colon));
    debugEvent("ConditionalExpression");

    var elseExpression = pop() as Expression;
    var thenExpression = pop() as Expression;
    var condition = pop() as Expression;
    reportErrorIfSuper(elseExpression);
    reportErrorIfSuper(thenExpression);
    push(ast.conditionalExpression(
        condition, question, thenExpression, colon, elseExpression));
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token? equalSign) {
    assert(optional('if', ifKeyword));
    assert(optionalOrNull('(', leftParen));
    assert(optionalOrNull('==', equalSign));
    debugEvent("ConditionalUri");

    var libraryUri = pop() as StringLiteral;
    var value = popIfNotNull(equalSign) as StringLiteral?;
    if (value is StringInterpolation) {
      for (var child in value.childEntities) {
        if (child is InterpolationExpression) {
          // This error is reported in OutlineBuilder.endLiteralString
          handleRecoverableError(
              messageInterpolationInUri, child.beginToken, child.endToken);
          break;
        }
      }
    }
    var name = pop() as DottedName;
    push(ast.configuration(ifKeyword, leftParen, name, equalSign, value,
        leftParen.endGroup!, libraryUri));
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("ConditionalUris");

    push(popTypedList<Configuration>(count) ?? NullValue.ConditionalUris);
  }

  @override
  void endConstExpression(Token constKeyword) {
    assert(optional('const', constKeyword));
    debugEvent("ConstExpression");

    _handleInstanceCreation(constKeyword);
  }

  @override
  void endConstLiteral(Token token) {
    debugEvent("endConstLiteral");
  }

  @override
  void endConstructorReference(Token start, Token? periodBeforeName,
      Token endToken, ConstructorReferenceContext constructorReferenceContext) {
    assert(optionalOrNull('.', periodBeforeName));
    debugEvent("ConstructorReference");

    var constructorName = pop() as SimpleIdentifier?;
    var typeArguments = pop() as TypeArgumentList?;
    var typeNameIdentifier = pop() as Identifier;
    push(
      ast.constructorName(
        ast.namedType(
          name: typeNameIdentifier,
          typeArguments: typeArguments,
        ),
        periodBeforeName,
        constructorName,
      ),
    );
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token semicolon) {
    assert(optional('do', doKeyword));
    assert(optional('while', whileKeyword));
    assert(optional(';', semicolon));
    debugEvent("DoWhileStatement");

    var condition = pop() as ParenthesizedExpression;
    var body = pop() as Statement;
    push(ast.doStatement(
        doKeyword,
        body,
        whileKeyword,
        condition.leftParenthesis,
        condition.expression,
        condition.rightParenthesis,
        semicolon));
  }

  @override
  void endDoWhileStatementBody(Token token) {
    debugEvent("endDoWhileStatementBody");
  }

  @override
  void endElseStatement(Token token) {
    debugEvent("endElseStatement");
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    assert(optional('enum', enumKeyword));
    assert(optional('{', leftBrace));
    debugEvent("Enum");

    var constants = popTypedList2<EnumConstantDeclaration>(count);
    var name = pop() as SimpleIdentifier;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, enumKeyword);
    declarations.add(ast.enumDeclaration(comment, metadata, enumKeyword, name,
        leftBrace, constants, leftBrace.endGroup!));
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    assert(optional('export', exportKeyword));
    assert(optional(';', semicolon));
    debugEvent("Export");

    var combinators = pop() as List<Combinator>?;
    var configurations = pop() as List<Configuration>?;
    var uri = pop() as StringLiteral;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, exportKeyword);
    directives.add(ast.exportDirective(comment, metadata, exportKeyword, uri,
        configurations, combinators, semicolon));
  }

  @override
  void endExtensionConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    debugEvent("ExtensionConstructor");
    // TODO(danrubel) Decide how to handle constructor declarations within
    // extensions. They are invalid and the parser has already reported an
    // error at this point. In the future, we should include them in order
    // to get navigation, search, etc.
    pop(); // body
    pop(); // initializers
    pop(); // separator
    pop(); // parameters
    pop(); // typeParameters
    pop(); // name
    pop(); // returnType
    pop(); // modifiers
    pop(); // metadata
  }

  @override
  void endExtensionDeclaration(Token extensionKeyword, Token? typeKeyword,
      Token onKeyword, Token? showKeyword, Token? hideKeyword, Token token) {
    if (typeKeyword != null && !enableExtensionTypes) {
      var feature = ExperimentalFeatures.extension_types;
      handleRecoverableError(
          templateExperimentNotEnabled.withArguments(
            feature.enableString,
            _versionAsString(ExperimentStatus.currentVersion),
          ),
          typeKeyword,
          typeKeyword);
    }

    if ((showKeyword != null || hideKeyword != null) && !enableExtensionTypes) {
      var feature = ExperimentalFeatures.extension_types;
      handleRecoverableError(
          templateExperimentNotEnabled.withArguments(
            feature.enableString,
            _versionAsString(ExperimentStatus.currentVersion),
          ),
          (showKeyword ?? hideKeyword)!,
          (showKeyword ?? hideKeyword)!);
    }

    ShowClause? showClause = pop(NullValue.ShowClause) as ShowClause?;
    HideClause? hideClause = pop(NullValue.HideClause) as HideClause?;

    var type = pop() as TypeAnnotation;

    extensionDeclaration!
      ..extendedType = type
      ..onKeyword = onKeyword
      ..typeKeyword = typeKeyword
      ..showClause = showClause
      ..hideClause = hideClause;
    extensionDeclaration = null;
  }

  @override
  void endExtensionFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    assert(optional('factory', factoryKeyword));
    assert(optional(';', endToken) || optional('}', endToken));
    debugEvent("ExtensionFactoryMethod");

    var bodyObject = pop();
    var parameters = pop() as FormalParameterList;
    var typeParameters = pop() as TypeParameterList?;
    var constructorName = pop();
    var modifiers = pop() as _Modifiers?;
    var metadata = pop() as List<Annotation>?;

    FunctionBody body;
    if (bodyObject is FunctionBody) {
      body = bodyObject;
    } else if (bodyObject is _RedirectingFactoryBody) {
      body = ast.emptyFunctionBody(endToken);
    } else {
      // Unhandled situation which should never happen.
      // Since this event handler is just a recovery attempt,
      // don't bother adding this declaration to the AST.
      return;
    }
    var comment = _findComment(metadata, beginToken);

    // Constructor declarations within extensions are invalid and the parser
    // has already reported an error at this point, but we include them in as
    // a method declaration in order to get navigation, search, etc.

    SimpleIdentifier methodName;
    if (constructorName is SimpleIdentifier) {
      methodName = constructorName;
    } else if (constructorName is PrefixedIdentifier) {
      methodName = constructorName.identifier;
    } else {
      // Unsure what the method name should be in this situation.
      // Since this event handler is just a recovery attempt,
      // don't bother adding this declaration to the AST.
      return;
    }
    currentDeclarationMembers.add(ast.methodDeclaration(
        comment,
        metadata,
        modifiers?.externalKeyword,
        modifiers?.abstractKeyword ?? modifiers?.staticKeyword,
        null, // returnType
        null, // getOrSet
        null, // operatorKeyword
        methodName,
        typeParameters,
        parameters,
        body));
  }

  @override
  void endExtensionFields(
      Token? abstractToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    if (staticToken == null) {
      // TODO(danrubel) Decide how to handle instance field declarations
      // within extensions. They are invalid and the parser has already reported
      // an error at this point, but we include them in order to get navigation,
      // search, etc.
    }
    endClassFields(abstractToken, externalToken, staticToken, covariantToken,
        lateToken, varFinalOrConst, count, beginToken, endToken);
  }

  @override
  void endExtensionMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("ExtensionMethod");
    endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    assert(optional('=', assignment));
    debugEvent("FieldInitializer");

    var initializer = pop() as Expression;
    var name = pop() as SimpleIdentifier;
    push(_makeVariableDeclaration(name, assignment, initializer));
  }

  @override
  void endForControlFlow(Token token) {
    debugEvent("endForControlFlow");
    var entry = pop() as Object;
    var forLoopParts = pop() as ForParts;
    var leftParen = pop() as Token;
    var forToken = pop() as Token;

    pushForControlFlowInfo(null, forToken, leftParen, forLoopParts, entry);
  }

  @override
  void endForIn(Token endToken) {
    debugEvent("ForInExpression");

    var body = pop() as Statement;
    var forLoopParts = pop() as ForEachParts;
    var leftParenthesis = pop() as Token;
    var forToken = pop() as Token;
    var awaitToken = pop(NullValue.AwaitToken) as Token?;

    push(ast.forStatement(
      awaitKeyword: awaitToken,
      forKeyword: forToken,
      leftParenthesis: leftParenthesis,
      forLoopParts: forLoopParts,
      rightParenthesis: leftParenthesis.endGroup!,
      body: body,
    ));
  }

  @override
  void endForInBody(Token token) {
    debugEvent("endForInBody");
  }

  @override
  void endForInControlFlow(Token token) {
    debugEvent("endForInControlFlow");

    var entry = pop() as Object;
    var forLoopParts = pop() as ForEachParts;
    var leftParenthesis = pop() as Token;
    var forToken = pop() as Token;
    var awaitToken = pop(NullValue.AwaitToken) as Token?;

    pushForControlFlowInfo(
        awaitToken, forToken, leftParenthesis, forLoopParts, entry);
  }

  @override
  void endForInExpression(Token token) {
    debugEvent("ForInExpression");
  }

  @override
  void endFormalParameter(
      Token? thisKeyword,
      Token? superKeyword,
      Token? periodAfterThisOrSuper,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    assert(optionalOrNull('this', thisKeyword));
    assert(optionalOrNull('super', superKeyword));
    assert(thisKeyword == null && superKeyword == null
        ? periodAfterThisOrSuper == null
        : optional('.', periodAfterThisOrSuper!));
    debugEvent("FormalParameter");

    if (superKeyword != null && !enableSuperParameters) {
      var feature = ExperimentalFeatures.super_parameters;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(ExperimentStatus.currentVersion),
        ),
        superKeyword,
        superKeyword,
      );
    }

    var defaultValue = pop() as _ParameterDefaultValue?;
    var name = pop() as SimpleIdentifier?;
    var typeOrFunctionTypedParameter = pop() as AstNode?;
    var modifiers = pop() as _Modifiers?;
    var keyword = modifiers?.finalConstOrVarKeyword;
    var covariantKeyword = modifiers?.covariantKeyword;
    var requiredKeyword = modifiers?.requiredToken;
    if (!enableNonNullable) {
      reportNonNullableModifierError(requiredKeyword);
    }
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata,
        thisKeyword ?? typeOrFunctionTypedParameter?.beginToken ?? nameToken);

    NormalFormalParameter node;
    if (typeOrFunctionTypedParameter is FunctionTypedFormalParameter) {
      // This is a temporary AST node that was constructed in
      // [endFunctionTypedFormalParameter]. We now deconstruct it and create
      // the final AST node.
      if (thisKeyword == null && superKeyword == null) {
        node = ast.functionTypedFormalParameter2(
            identifier: name!,
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            requiredKeyword: requiredKeyword,
            returnType: typeOrFunctionTypedParameter.returnType,
            typeParameters: typeOrFunctionTypedParameter.typeParameters,
            parameters: typeOrFunctionTypedParameter.parameters,
            question: typeOrFunctionTypedParameter.question);
      } else if (thisKeyword != null) {
        assert(superKeyword == null,
            "Can't have both 'this' and 'super' in a parameter.");
        node = ast.fieldFormalParameter2(
            identifier: name!,
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            requiredKeyword: requiredKeyword,
            type: typeOrFunctionTypedParameter.returnType,
            thisKeyword: thisKeyword,
            period: periodAfterThisOrSuper!,
            typeParameters: typeOrFunctionTypedParameter.typeParameters,
            parameters: typeOrFunctionTypedParameter.parameters,
            question: typeOrFunctionTypedParameter.question);
      } else {
        assert(superKeyword != null && thisKeyword == null);
        node = ast.superFormalParameter(
            identifier: name!,
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            requiredKeyword: requiredKeyword,
            type: typeOrFunctionTypedParameter.returnType,
            superKeyword: superKeyword!,
            period: periodAfterThisOrSuper!,
            typeParameters: typeOrFunctionTypedParameter.typeParameters,
            parameters: typeOrFunctionTypedParameter.parameters,
            question: typeOrFunctionTypedParameter.question);
      }
    } else {
      var type = typeOrFunctionTypedParameter as TypeAnnotation?;
      if (thisKeyword == null) {
        node = ast.simpleFormalParameter2(
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            requiredKeyword: requiredKeyword,
            keyword: keyword,
            type: type,
            identifier: name);
      } else {
        node = ast.fieldFormalParameter2(
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            requiredKeyword: requiredKeyword,
            keyword: keyword,
            type: type,
            thisKeyword: thisKeyword,
            period: thisKeyword.next!,
            identifier: name!);
      }
    }

    ParameterKind analyzerKind =
        _toAnalyzerParameterKind(kind, requiredKeyword);
    FormalParameter parameter = node;
    if (analyzerKind != ParameterKind.REQUIRED) {
      parameter = ast.defaultFormalParameter(
          node, analyzerKind, defaultValue?.separator, defaultValue?.value);
    } else if (defaultValue != null) {
      // An error is reported if a required parameter has a default value.
      // Record it as named parameter for recovery.
      parameter = ast.defaultFormalParameter(node, ParameterKind.NAMED,
          defaultValue.separator, defaultValue.value);
    }
    push(parameter);
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    debugEvent("FormalParameterDefaultValueExpression");
  }

  @override
  void endFormalParameters(
      int count, Token leftParen, Token rightParen, MemberKind kind) {
    assert(optional('(', leftParen));
    assert(optional(')', rightParen));
    debugEvent("FormalParameters");

    var rawParameters = popTypedList(count) ?? const <Object>[];
    List<FormalParameter> parameters = <FormalParameter>[];
    Token? leftDelimiter;
    Token? rightDelimiter;
    for (Object raw in rawParameters) {
      if (raw is _OptionalFormalParameters) {
        parameters.addAll(raw.parameters ?? const <FormalParameter>[]);
        leftDelimiter = raw.leftDelimiter;
        rightDelimiter = raw.rightDelimiter;
      } else {
        parameters.add(raw as FormalParameter);
      }
    }
    push(ast.formalParameterList(
        leftParen, parameters, leftDelimiter, rightDelimiter, rightParen));
  }

  @override
  void endForStatement(Token endToken) {
    debugEvent("ForStatement");
    var body = pop() as Statement;
    var forLoopParts = pop() as ForParts;
    var leftParen = pop() as Token;
    var forToken = pop() as Token;

    push(ast.forStatement(
      forKeyword: forToken,
      leftParenthesis: leftParen,
      forLoopParts: forLoopParts,
      rightParenthesis: leftParen.endGroup!,
      body: body,
    ));
  }

  @override
  void endForStatementBody(Token token) {
    debugEvent("endForStatementBody");
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.  Note that this is tricky due to the handling of initializers
    // in constructors, so the logic should be shared with BodyBuilder as much
    // as possible.
    debugEvent("FunctionExpression");

    var body = pop() as FunctionBody;
    var parameters = pop() as FormalParameterList?;
    var typeParameters = pop() as TypeParameterList?;
    push(ast.functionExpression(typeParameters, parameters, body));
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    assert(optional('Function', functionToken));
    debugEvent("FunctionType");
    if (!enableNonNullable) {
      reportErrorIfNullableType(questionMark);
    }

    var parameters = pop() as FormalParameterList;
    var returnType = pop() as TypeAnnotation?;
    var typeParameters = pop() as TypeParameterList?;
    push(ast.genericFunctionType(
        returnType, functionToken, typeParameters, parameters,
        question: questionMark));
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken, Token? question) {
    debugEvent("FunctionTypedFormalParameter");
    if (!enableNonNullable) {
      reportErrorIfNullableType(question);
    }

    var formalParameters = pop() as FormalParameterList;
    var returnType = pop() as TypeAnnotation?;
    var typeParameters = pop() as TypeParameterList?;

    // Create a temporary formal parameter that will be dissected later in
    // [endFormalParameter].
    push(ast.functionTypedFormalParameter2(
        identifier: ast.simpleIdentifier(
          StringToken(TokenType.IDENTIFIER, '', 0),
        ),
        returnType: returnType,
        typeParameters: typeParameters,
        parameters: formalParameters,
        question: question));
  }

  @override
  void endHide(Token hideKeyword) {
    assert(optional('hide', hideKeyword));
    debugEvent("Hide");

    var hiddenNames = pop() as List<SimpleIdentifier>;
    push(ast.hideCombinator(hideKeyword, hiddenNames));
  }

  @override
  void endIfControlFlow(Token token) {
    var thenElement = pop() as CollectionElement;
    var condition = pop() as ParenthesizedExpression;
    var ifToken = pop() as Token;
    pushIfControlFlowInfo(ifToken, condition, thenElement, null, null);
  }

  @override
  void endIfElseControlFlow(Token token) {
    var elseElement = pop() as CollectionElement;
    var elseToken = pop() as Token;
    var thenElement = pop() as CollectionElement;
    var condition = pop() as ParenthesizedExpression;
    var ifToken = pop() as Token;
    pushIfControlFlowInfo(
        ifToken, condition, thenElement, elseToken, elseElement);
  }

  @override
  void endIfStatement(Token ifToken, Token? elseToken) {
    assert(optional('if', ifToken));
    assert(optionalOrNull('else', elseToken));

    var elsePart = popIfNotNull(elseToken) as Statement?;
    var thenPart = pop() as Statement;
    var condition = pop() as ParenthesizedExpression;
    push(ast.ifStatement(
        ifToken,
        condition.leftParenthesis,
        condition.expression,
        condition.rightParenthesis,
        thenPart,
        elseToken,
        elsePart));
  }

  @override
  void endImplicitCreationExpression(Token token, Token openAngleBracket) {
    debugEvent("ImplicitCreationExpression");

    _handleInstanceCreation(null);
  }

  @override
  void endImport(Token importKeyword, Token? semicolon) {
    assert(optional('import', importKeyword));
    assert(optionalOrNull(';', semicolon));
    debugEvent("Import");

    var combinators = pop() as List<Combinator>?;
    var deferredKeyword = pop(NullValue.Deferred) as Token?;
    var asKeyword = pop(NullValue.As) as Token?;
    var prefix = pop(NullValue.Prefix) as SimpleIdentifier?;
    var configurations = pop() as List<Configuration>?;
    var uri = pop() as StringLiteral;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, importKeyword);

    directives.add(ast.importDirective(
        comment,
        metadata,
        importKeyword,
        uri,
        configurations,
        deferredKeyword,
        asKeyword,
        prefix,
        combinators,
        semicolon ?? Tokens.semicolon()));
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    debugEvent("InitializedIdentifier");

    var node = pop() as AstNode?;
    VariableDeclaration variable;
    // TODO(paulberry): This seems kludgy.  It would be preferable if we
    // could respond to a "handleNoVariableInitializer" event by converting a
    // SimpleIdentifier into a VariableDeclaration, and then when this code was
    // reached, node would always be a VariableDeclaration.
    if (node is VariableDeclaration) {
      variable = node;
    } else if (node is SimpleIdentifier) {
      variable = _makeVariableDeclaration(node, null, null);
    } else {
      internalProblem(
          templateInternalProblemUnhandled.withArguments(
              "${node.runtimeType}", "identifier"),
          nameToken.charOffset,
          uri);
    }
    push(variable);
  }

  @override
  void endInitializers(int count, Token colon, Token endToken) {
    assert(optional(':', colon));
    debugEvent("Initializers");

    var initializerObjects = popTypedList(count) ?? const [];
    if (!isFullAst) return;

    push(colon);

    var initializers = <ConstructorInitializer>[];
    for (Object initializerObject in initializerObjects) {
      var initializer = buildInitializer(initializerObject);
      if (initializer != null) {
        initializers.add(initializer);
      } else {
        handleRecoverableError(
            messageInvalidInitializer,
            initializerObject is AstNode ? initializerObject.beginToken : colon,
            initializerObject is AstNode ? initializerObject.endToken : colon);
      }
    }

    push(initializers);
  }

  @override
  void endInvalidAwaitExpression(
      Token awaitKeyword, Token endToken, MessageCode errorCode) {
    debugEvent("InvalidAwaitExpression");
    endAwaitExpression(awaitKeyword, endToken);
  }

  @override
  void endInvalidYieldStatement(Token yieldKeyword, Token? starToken,
      Token endToken, MessageCode errorCode) {
    debugEvent("InvalidYieldStatement");
    endYieldStatement(yieldKeyword, starToken, endToken);
  }

  @override
  void endIsOperatorType(Token asOperator) {
    debugEvent("IsOperatorType");
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement");

    var statement = pop() as Statement;
    var labels = popTypedList2<Label>(labelCount);
    push(ast.labeledStatement(labels, statement));
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    assert(optional('library', libraryKeyword));
    assert(optional(';', semicolon));
    debugEvent("LibraryName");

    var libraryName = pop() as List<SimpleIdentifier>;
    var name = ast.libraryIdentifier(libraryName);
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, libraryKeyword);
    directives.add(ast.libraryDirective(
        comment, metadata, libraryKeyword, name, semicolon));
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");

    if (interpolationCount == 0) {
      var token = pop() as Token;
      String value = unescapeString(token.lexeme, token, this);
      push(ast.simpleStringLiteral(token, value));
    } else {
      var parts = popTypedList(1 + interpolationCount * 2)!;
      var first = parts.first as Token;
      var last = parts.last as Token;
      Quote quote = analyzeQuote(first.lexeme);
      List<InterpolationElement> elements = <InterpolationElement>[];
      elements.add(ast.interpolationString(
          first, unescapeFirstStringPart(first.lexeme, quote, first, this)));
      for (int i = 1; i < parts.length - 1; i++) {
        var part = parts[i];
        if (part is Token) {
          elements.add(ast.interpolationString(
              part, unescape(part.lexeme, quote, part, this)));
        } else if (part is InterpolationExpression) {
          elements.add(part);
        } else {
          internalProblem(
              templateInternalProblemUnhandled.withArguments(
                  "${part.runtimeType}", "string interpolation"),
              first.charOffset,
              uri);
        }
      }
      elements.add(ast.interpolationString(
          last,
          unescapeLastStringPart(
              last.lexeme, quote, last, last.isSynthetic, this)));
      push(ast.stringInterpolation(elements));
    }
  }

  @override
  void endLiteralSymbol(Token hashToken, int tokenCount) {
    assert(optional('#', hashToken));
    debugEvent("LiteralSymbol");

    var components = popTypedList2<Token>(tokenCount);
    push(ast.symbolLiteral(hashToken, components));
  }

  @override
  void endLocalFunctionDeclaration(Token token) {
    debugEvent("LocalFunctionDeclaration");
    var body = pop() as FunctionBody;
    if (isFullAst) {
      pop(); // constructor initializers
      pop(); // separator before constructor initializers
    }
    var parameters = pop() as FormalParameterList;
    checkFieldFormalParameters(parameters);
    var name = pop() as SimpleIdentifier;
    var returnType = pop() as TypeAnnotation?;
    var typeParameters = pop() as TypeParameterList?;
    var metadata = pop(NullValue.Metadata) as List<Annotation>?;
    FunctionExpression functionExpression =
        ast.functionExpression(typeParameters, parameters, body);
    var functionDeclaration = ast.functionDeclaration(
        null, metadata, null, returnType, null, name, functionExpression);
    push(ast.functionDeclarationStatement(functionDeclaration));
  }

  @override
  void endMember() {
    debugEvent("Member");
  }

  @override
  void endMetadata(Token atSign, Token? periodBeforeName, Token endToken) {
    assert(optional('@', atSign));
    assert(optionalOrNull('.', periodBeforeName));
    debugEvent("Metadata");

    var invocation = pop() as MethodInvocation?;
    var constructorName =
        periodBeforeName != null ? pop() as SimpleIdentifier : null;
    var typeArguments = pop() as TypeArgumentList?;
    if (typeArguments != null &&
        !_featureSet.isEnabled(Feature.generic_metadata)) {
      var feature = Feature.generic_metadata;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(feature.releaseVersion!),
        ),
        typeArguments.beginToken,
        typeArguments.beginToken,
      );
    }
    var name = pop() as Identifier;
    push(ast.annotation(
        atSign: atSign,
        name: name,
        typeArguments: typeArguments,
        period: periodBeforeName,
        constructorName: constructorName,
        arguments: invocation?.argumentList));
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");

    push(popTypedList<Annotation>(count) ?? NullValue.Metadata);
  }

  @override
  void endMixinConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("MixinConstructor");
    // TODO(danrubel) Decide how to handle constructor declarations within
    // mixins. They are invalid, but we include them in order to get navigation,
    // search, etc. Currently the error is reported by multiple listeners,
    // but should be moved into the parser.
    endClassConstructor(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    debugEvent("MixinDeclaration");
    mixinDeclaration = null;
  }

  @override
  void endMixinFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("MixinFactoryMethod");
    endClassFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endMixinFields(
      Token? abstractToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    endClassFields(abstractToken, externalToken, staticToken, covariantToken,
        lateToken, varFinalOrConst, count, beginToken, endToken);
  }

  @override
  void endMixinMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("MixinMethod");
    endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken);
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    debugEvent("NamedFunctionExpression");
    var body = pop() as FunctionBody;
    if (isFullAst) {
      pop(); // constructor initializers
      pop(); // separator before constructor initializers
    }
    var parameters = pop() as FormalParameterList;
    pop(); // name
    pop(); // returnType
    var typeParameters = pop() as TypeParameterList?;
    push(ast.functionExpression(typeParameters, parameters, body));
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equalsToken, Token? implementsKeyword, Token semicolon) {
    assert(optional('class', classKeyword));
    assert(optionalOrNull('=', equalsToken));
    assert(optionalOrNull('implements', implementsKeyword));
    assert(optional(';', semicolon));
    debugEvent("NamedMixinApplication");

    ImplementsClause? implementsClause;
    if (implementsKeyword != null) {
      var interfaces = pop() as List<NamedType>;
      implementsClause = ast.implementsClause(implementsKeyword, interfaces);
    }
    var withClause = pop(NullValue.WithClause) as WithClause;
    var superclass = pop() as NamedType;
    var modifiers = pop() as _Modifiers?;
    var typeParameters = pop() as TypeParameterList?;
    var name = pop() as SimpleIdentifier;
    var abstractKeyword = modifiers?.abstractKeyword;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, beginToken);
    declarations.add(ast.classTypeAlias(
        comment,
        metadata,
        classKeyword,
        name,
        typeParameters,
        equalsToken,
        abstractKeyword,
        superclass,
        withClause,
        implementsClause,
        semicolon));
  }

  @override
  void endNewExpression(Token newKeyword) {
    assert(optional('new', newKeyword));
    debugEvent("NewExpression");

    _handleInstanceCreation(newKeyword);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token leftDelimeter, Token rightDelimeter) {
    assert((optional('[', leftDelimeter) && optional(']', rightDelimeter)) ||
        (optional('{', leftDelimeter) && optional('}', rightDelimeter)));
    debugEvent("OptionalFormalParameters");

    push(_OptionalFormalParameters(
        popTypedList2<FormalParameter>(count), leftDelimeter, rightDelimeter));
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    assert(optional('part', partKeyword));
    assert(optional(';', semicolon));
    debugEvent("Part");

    var uri = pop() as StringLiteral;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, partKeyword);
    directives
        .add(ast.partDirective(comment, metadata, partKeyword, uri, semicolon));
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    assert(optional('part', partKeyword));
    assert(optional('of', ofKeyword));
    assert(optional(';', semicolon));
    debugEvent("PartOf");
    var libraryNameOrUri = pop();
    LibraryIdentifier? name;
    StringLiteral? uri;
    if (libraryNameOrUri is StringLiteral) {
      uri = libraryNameOrUri;
    } else {
      name = ast.libraryIdentifier(libraryNameOrUri as List<SimpleIdentifier>);
    }
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, partKeyword);
    directives.add(ast.partOfDirective(
        comment, metadata, partKeyword, ofKeyword, uri, name, semicolon));
  }

  @override
  void endRedirectingFactoryBody(Token equalToken, Token endToken) {
    assert(optional('=', equalToken));
    debugEvent("RedirectingFactoryBody");

    var constructorName = pop() as ConstructorName;
    var starToken = pop() as Token?;
    var asyncToken = pop() as Token?;
    push(_RedirectingFactoryBody(
        asyncToken, starToken, equalToken, constructorName));
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token semicolon) {
    assert(optional('rethrow', rethrowToken));
    assert(optional(';', semicolon));
    debugEvent("RethrowStatement");

    RethrowExpression expression = ast.rethrowExpression(rethrowToken);
    // TODO(scheglov) According to the specification, 'rethrow' is a statement.
    push(ast.expressionStatement(expression, semicolon));
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token returnKeyword, Token semicolon) {
    assert(optional('return', returnKeyword));
    assert(optional(';', semicolon));
    debugEvent("ReturnStatement");

    var expression = hasExpression ? pop() as Expression : null;
    push(ast.returnStatement(returnKeyword, expression, semicolon));
  }

  @override
  void endShow(Token showKeyword) {
    assert(optional('show', showKeyword));
    debugEvent("Show");

    var shownNames = pop() as List<SimpleIdentifier>;
    push(ast.showCombinator(showKeyword, shownNames));
  }

  @override
  void endSwitchBlock(int caseCount, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("SwitchBlock");

    var membersList = popTypedList2<List<SwitchMember>>(caseCount);
    List<SwitchMember> members =
        membersList.expand((members) => members).toList();

    Set<String> labels = <String>{};
    for (SwitchMember member in members) {
      for (Label label in member.labels) {
        if (!labels.add(label.label.name)) {
          handleRecoverableError(
              templateDuplicateLabelInSwitchStatement
                  .withArguments(label.label.name),
              label.beginToken,
              label.beginToken);
        }
      }
    }

    push(leftBracket);
    push(members);
    push(rightBracket);
  }

  @override
  void endSwitchCase(
      int labelCount,
      int expressionCount,
      Token? defaultKeyword,
      Token? colonAfterDefault,
      int statementCount,
      Token firstToken,
      Token endToken) {
    assert(optionalOrNull('default', defaultKeyword));
    assert(defaultKeyword == null
        ? colonAfterDefault == null
        : optional(':', colonAfterDefault!));
    debugEvent("SwitchCase");

    var statements = popTypedList2<Statement>(statementCount);
    List<SwitchMember?> members;

    if (labelCount == 0 && defaultKeyword == null) {
      // Common situation: case with no default and no labels.
      members = popTypedList2<SwitchMember>(expressionCount);
    } else {
      // Labels and case statements may be intertwined
      if (defaultKeyword != null) {
        SwitchDefault member = ast.switchDefault(
            <Label>[], defaultKeyword, colonAfterDefault!, <Statement>[]);
        while (peek() is Label) {
          member.labels.insert(0, pop() as Label);
          --labelCount;
        }
        members = List<SwitchMember?>.filled(expressionCount + 1, null);
        members[expressionCount] = member;
      } else {
        members = List<SwitchMember?>.filled(expressionCount, null);
      }
      for (int index = expressionCount - 1; index >= 0; --index) {
        var member = pop() as SwitchMember;
        while (peek() is Label) {
          member.labels.insert(0, pop() as Label);
          --labelCount;
        }
        members[index] = member;
      }
      assert(labelCount == 0);
    }
    var members2 = members.whereNotNull().toList();
    if (members2.isNotEmpty) {
      members2.last.statements.addAll(statements);
    }
    push(members2);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    assert(optional('switch', switchKeyword));
    debugEvent("SwitchStatement");

    var rightBracket = pop() as Token;
    var members = pop() as List<SwitchMember>;
    var leftBracket = pop() as Token;
    var expression = pop() as ParenthesizedExpression;
    push(ast.switchStatement(
        switchKeyword,
        expression.leftParenthesis,
        expression.expression,
        expression.rightParenthesis,
        leftBracket,
        members,
        rightBracket));
  }

  @override
  void endThenStatement(Token token) {
    debugEvent("endThenStatement");
  }

  @override
  void endTopLevelDeclaration(Token token) {
    debugEvent("TopLevelDeclaration");
  }

  @override
  void endTopLevelFields(
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("TopLevelFields");

    if (externalToken != null) {
      if (!enableNonNullable) {
        handleRecoverableError(
            messageExternalField, externalToken, externalToken);
      } else if (lateToken != null) {
        handleRecoverableError(
            messageExternalLateField, externalToken, externalToken);
      }
    }

    var variables = popTypedList2<VariableDeclaration>(count);
    var type = pop() as TypeAnnotation?;
    var variableList = ast.variableDeclarationList2(
      lateKeyword: lateToken,
      keyword: varFinalOrConst,
      type: type,
      variables: variables,
    );
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, beginToken);
    declarations.add(ast.topLevelVariableDeclaration(
        comment, metadata, variableList, semicolon,
        externalKeyword: externalToken));
  }

  @override
  void endTopLevelMethod(Token beginToken, Token? getOrSet, Token endToken) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.
    assert(getOrSet == null ||
        optional('get', getOrSet) ||
        optional('set', getOrSet));
    debugEvent("TopLevelMethod");

    var body = pop() as FunctionBody;
    var parameters = pop() as FormalParameterList?;
    var typeParameters = pop() as TypeParameterList?;
    var name = pop() as SimpleIdentifier;
    var returnType = pop() as TypeAnnotation?;
    var modifiers = pop() as _Modifiers?;
    var externalKeyword = modifiers?.externalKeyword;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, beginToken);
    declarations.add(ast.functionDeclaration(
        comment,
        metadata,
        externalKeyword,
        returnType,
        getOrSet,
        name,
        ast.functionExpression(typeParameters, parameters, body)));
  }

  @override
  void endTryStatement(
      int catchCount, Token tryKeyword, Token? finallyKeyword) {
    assert(optional('try', tryKeyword));
    assert(optionalOrNull('finally', finallyKeyword));
    debugEvent("TryStatement");

    var finallyBlock = popIfNotNull(finallyKeyword) as Block?;
    var catchClauses = popTypedList2<CatchClause>(catchCount);
    var body = pop() as Block;
    push(ast.tryStatement(
        tryKeyword, body, catchClauses, finallyKeyword, finallyBlock));
  }

  @override
  void endTypeArguments(int count, Token leftBracket, Token rightBracket) {
    assert(optional('<', leftBracket));
    assert(optional('>', rightBracket));
    debugEvent("TypeArguments");

    var arguments = popTypedList2<TypeAnnotation>(count);
    push(ast.typeArgumentList(leftBracket, arguments, rightBracket));
  }

  @override
  void endTypedef(Token typedefKeyword, Token? equals, Token semicolon) {
    assert(optional('typedef', typedefKeyword));
    assert(optionalOrNull('=', equals));
    assert(optional(';', semicolon));
    debugEvent("FunctionTypeAlias");

    if (equals == null) {
      var parameters = pop() as FormalParameterList;
      var typeParameters = pop() as TypeParameterList?;
      var name = pop() as SimpleIdentifier;
      var returnType = pop() as TypeAnnotation?;
      var metadata = pop() as List<Annotation>?;
      var comment = _findComment(metadata, typedefKeyword);
      declarations.add(ast.functionTypeAlias(comment, metadata, typedefKeyword,
          returnType, name, typeParameters, parameters, semicolon));
    } else {
      var type = pop() as TypeAnnotation;
      var templateParameters = pop() as TypeParameterList?;
      var name = pop() as SimpleIdentifier;
      var metadata = pop() as List<Annotation>?;
      var comment = _findComment(metadata, typedefKeyword);
      if (type is! GenericFunctionType && !enableNonFunctionTypeAliases) {
        var feature = Feature.nonfunction_type_aliases;
        handleRecoverableError(
          templateExperimentNotEnabled.withArguments(
            feature.enableString,
            _versionAsString(ExperimentStatus.currentVersion),
          ),
          equals,
          equals,
        );
      }
      declarations.add(ast.genericTypeAlias(comment, metadata, typedefKeyword,
          name, templateParameters, equals, type, semicolon));
    }
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popTypedList<NamedType>(count) ?? NullValue.TypeList);
  }

  @override
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    debugEvent("TypeVariable");
    assert(extendsOrSuper == null ||
        optional('extends', extendsOrSuper) ||
        optional('super', extendsOrSuper));

    // TODO (kallentu): Implement variance behaviour for the analyzer.
    assert(variance == null ||
        optional('in', variance) ||
        optional('out', variance) ||
        optional('inout', variance));
    if (!enableVariance) {
      reportVarianceModifierNotEnabled(variance);
    }

    var bound = pop() as TypeAnnotation?;

    // Peek to leave type parameters on top of stack.
    var typeParameters = peek() as List<TypeParameter>;

    // TODO (kallentu) : Clean up TypeParameterImpl casting once variance is
    // added to the interface.
    (typeParameters[index] as TypeParameterImpl)
      ..extendsKeyword = extendsOrSuper
      ..bound = bound
      ..varianceKeyword = variance;
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    assert(optional('<', beginToken));
    assert(optional('>', endToken));
    debugEvent("TypeVariables");

    var typeParameters = pop() as List<TypeParameter>;
    push(ast.typeParameterList(beginToken, typeParameters, endToken));
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    assert(optionalOrNull('=', assignmentOperator));
    debugEvent("VariableInitializer");

    var initializer = pop() as Expression;
    var identifier = pop() as SimpleIdentifier;
    // TODO(ahe): Don't push initializers, instead install them.
    push(_makeVariableDeclaration(identifier, assignmentOperator, initializer));
  }

  @override
  void endVariablesDeclaration(int count, Token? semicolon) {
    assert(optionalOrNull(';', semicolon));
    debugEvent("VariablesDeclaration");

    var variables = popTypedList2<VariableDeclaration>(count);
    var modifiers = pop(NullValue.Modifiers) as _Modifiers?;
    var type = pop() as TypeAnnotation?;
    var keyword = modifiers?.finalConstOrVarKeyword;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, variables[0].beginToken);
    // var comment = _findComment(metadata,
    //     variables[0].beginToken ?? type?.beginToken ?? modifiers.beginToken);
    push(ast.variableDeclarationStatement(
        ast.variableDeclarationList2(
          comment: comment,
          metadata: metadata,
          lateKeyword: modifiers?.lateToken,
          keyword: keyword,
          type: type,
          variables: variables,
        ),
        semicolon ?? Tokens.semicolon()));
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    assert(optional('while', whileKeyword));
    debugEvent("WhileStatement");

    var body = pop() as Statement;
    var condition = pop() as ParenthesizedExpression;
    push(ast.whileStatement(whileKeyword, condition.leftParenthesis,
        condition.expression, condition.rightParenthesis, body));
  }

  @override
  void endWhileStatementBody(Token token) {
    debugEvent("endWhileStatementBody");
  }

  @override
  void endYieldStatement(Token yieldToken, Token? starToken, Token semicolon) {
    assert(optional('yield', yieldToken));
    assert(optionalOrNull('*', starToken));
    assert(optional(';', semicolon));
    debugEvent("YieldStatement");

    var expression = pop() as Expression;
    push(ast.yieldStatement(yieldToken, starToken, expression, semicolon));
  }

  @override
  void handleAsOperator(Token asOperator) {
    assert(optional('as', asOperator));
    debugEvent("AsOperator");

    var type = pop() as TypeAnnotation;
    var expression = pop() as Expression;
    push(ast.asExpression(expression, asOperator, type));
  }

  @override
  void handleAssignmentExpression(Token token) {
    assert(token.type.isAssignmentOperator);
    debugEvent("AssignmentExpression");

    var rhs = pop() as Expression;
    var lhs = pop() as Expression;
    if (!lhs.isAssignable) {
      // TODO(danrubel): Update the BodyBuilder to report this error.
      handleRecoverableError(
          messageMissingAssignableSelector, lhs.beginToken, lhs.endToken);
    }
    push(ast.assignmentExpression(lhs, token, rhs));
    if (!enableTripleShift && token.type == TokenType.GT_GT_GT_EQ) {
      var feature = ExperimentalFeatures.triple_shift;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(ExperimentStatus.currentVersion),
        ),
        token,
        token,
      );
    }
  }

  @override
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    assert(asyncToken == null ||
        optional('async', asyncToken) ||
        optional('sync', asyncToken));
    assert(optionalOrNull('*', starToken));
    debugEvent("AsyncModifier");

    push(asyncToken ?? NullValue.FunctionBodyAsyncToken);
    push(starToken ?? NullValue.FunctionBodyStarToken);
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token semicolon) {
    assert(optional('break', breakKeyword));
    assert(optional(';', semicolon));
    debugEvent("BreakStatement");

    var label = hasTarget ? pop() as SimpleIdentifier : null;
    push(ast.breakStatement(breakKeyword, label, semicolon));
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    assert(optional('case', caseKeyword));
    assert(optional(':', colon));
    debugEvent("CaseMatch");

    var expression = pop() as Expression;
    push(ast.switchCase(
        <Label>[], caseKeyword, expression, colon, <Statement>[]));
  }

  @override
  void handleCatchBlock(Token? onKeyword, Token? catchKeyword, Token? comma) {
    assert(optionalOrNull('on', onKeyword));
    assert(optionalOrNull('catch', catchKeyword));
    assert(optionalOrNull(',', comma));
    debugEvent("CatchBlock");

    var body = pop() as Block;
    var catchParameterList = popIfNotNull(catchKeyword) as FormalParameterList?;
    var type = popIfNotNull(onKeyword) as TypeAnnotation?;
    SimpleIdentifier? exception;
    SimpleIdentifier? stackTrace;
    if (catchParameterList != null) {
      List<FormalParameter> catchParameters = catchParameterList.parameters;
      if (catchParameters.isNotEmpty) {
        exception = catchParameters[0].identifier;
      }
      if (catchParameters.length > 1) {
        stackTrace = catchParameters[1].identifier;
      }
    }
    push(ast.catchClause(
        onKeyword,
        type,
        catchKeyword,
        catchParameterList?.leftParenthesis,
        exception,
        comma,
        stackTrace,
        catchParameterList?.rightParenthesis,
        body));
  }

  @override
  void handleClassExtends(Token? extendsKeyword, int typeCount) {
    assert(extendsKeyword == null || extendsKeyword.isKeywordOrIdentifier);
    debugEvent("ClassExtends");

    // If more extends clauses was specified (parser has already issued an
    // error) throw them away for now and pick the first one.
    while (typeCount > 1) {
      pop();
      typeCount--;
    }
    var supertype = pop() as NamedType?;
    if (supertype != null) {
      push(ast.extendsClause(extendsKeyword!, supertype));
    } else {
      push(NullValue.ExtendsClause);
    }
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token? nativeToken) {
    assert(optional('class', classKeyword));
    assert(optionalOrNull('native', nativeToken));
    assert(classDeclaration == null && mixinDeclaration == null);
    debugEvent("ClassHeader");

    NativeClause? nativeClause;
    if (nativeToken != null) {
      nativeClause = ast.nativeClause(nativeToken, nativeName);
    }
    var implementsClause = pop(NullValue.IdentifierList) as ImplementsClause?;
    var withClause = pop(NullValue.WithClause) as WithClause?;
    var extendsClause = pop(NullValue.ExtendsClause) as ExtendsClause?;
    var modifiers = pop() as _Modifiers?;
    var typeParameters = pop() as TypeParameterList?;
    var name = pop() as SimpleIdentifier;
    var abstractKeyword = modifiers?.abstractKeyword;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, begin);
    // leftBracket, members, and rightBracket
    // are set in [endClassOrMixinBody].
    classDeclaration = ast.classDeclaration(
      comment,
      metadata,
      abstractKeyword,
      classKeyword,
      name,
      typeParameters,
      extendsClause,
      withClause,
      implementsClause,
      Tokens.openCurlyBracket(), // leftBracket
      <ClassMember>[],
      Tokens.closeCurlyBracket(), // rightBracket
    );

    classDeclaration!.nativeClause = nativeClause;
    declarations.add(classDeclaration!);
  }

  @override
  void handleClassNoWithClause() {
    push(NullValue.WithClause);
  }

  @override
  void handleClassOrMixinImplements(
      Token? implementsKeyword, int interfacesCount) {
    assert(optionalOrNull('implements', implementsKeyword));
    debugEvent("ClassImplements");

    if (implementsKeyword != null) {
      var interfaces = popTypedList2<NamedType>(interfacesCount);
      push(ast.implementsClause(implementsKeyword, interfaces));
    } else {
      push(NullValue.IdentifierList);
    }
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    assert(optional('with', withKeyword));
    var mixinTypes = pop() as List<NamedType>;
    push(ast.withClause(withKeyword, mixinTypes));
  }

  @override
  void handleCommentReference(
      Token? newKeyword, Token? prefix, Token? period, Token token) {
    Identifier identifier = ast.simpleIdentifier(token);
    if (prefix != null) {
      identifier = ast.prefixedIdentifier(ast.simpleIdentifier(prefix), period!,
          identifier as SimpleIdentifier);
    }
    push(ast.commentReference(newKeyword, identifier));
  }

  @override
  void handleCommentReferenceText(String referenceSource, int referenceOffset) {
    push(referenceSource);
    push(referenceOffset);
  }

  @override
  void handleConstFactory(Token constKeyword) {
    debugEvent("ConstFactory");
    // TODO(kallentu): Removal of const factory error for const function feature
    handleRecoverableError(messageConstFactory, constKeyword, constKeyword);
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token semicolon) {
    assert(optional('continue', continueKeyword));
    assert(optional(';', semicolon));
    debugEvent("ContinueStatement");

    var label = hasTarget ? pop() as SimpleIdentifier : null;
    push(ast.continueStatement(continueKeyword, label, semicolon));
  }

  @override
  void handleDottedName(int count, Token firstIdentifier) {
    assert(firstIdentifier.isIdentifier);
    debugEvent("DottedName");

    var components = popTypedList2<SimpleIdentifier>(count);
    push(ast.dottedName(components));
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    push(elseToken);
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("EmptyFunctionBody");

    // TODO(scheglov) Change the parser to not produce these modifiers.
    pop(); // star
    pop(); // async
    push(ast.emptyFunctionBody(semicolon));
  }

  @override
  void handleEmptyStatement(Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("EmptyStatement");

    push(ast.emptyStatement(semicolon));
  }

  @override
  void handleErrorToken(ErrorToken token) {
    translateErrorToken(token, errorReporter.reportScannerError);
  }

  @override
  void handleExpressionFunctionBody(Token arrowToken, Token? semicolon) {
    assert(optional('=>', arrowToken) || optional('=', arrowToken));
    assert(optionalOrNull(';', semicolon));
    debugEvent("ExpressionFunctionBody");

    var expression = pop() as Expression;
    var star = pop() as Token?;
    var asyncKeyword = pop() as Token?;
    if (parseFunctionBodies) {
      push(ast.expressionFunctionBody2(
        keyword: asyncKeyword,
        star: star,
        functionDefinition: arrowToken,
        expression: expression,
        semicolon: semicolon,
      ));
    } else {
      push(ast.emptyFunctionBody(semicolon!));
    }
  }

  @override
  void handleExpressionStatement(Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("ExpressionStatement");
    var expression = pop() as Expression;
    reportErrorIfSuper(expression);
    if (expression is SimpleIdentifier &&
        expression.token.keyword?.isBuiltInOrPseudo == false) {
      // This error is also reported by the body builder.
      handleRecoverableError(
          messageExpectedStatement, expression.beginToken, expression.endToken);
    }
    if (expression is AssignmentExpression) {
      if (!expression.leftHandSide.isAssignable) {
        // This error is also reported by the body builder.
        handleRecoverableError(
            messageIllegalAssignmentToNonAssignable,
            expression.leftHandSide.beginToken,
            expression.leftHandSide.endToken);
      }
    }
    push(ast.expressionStatement(expression, semicolon));
  }

  @override
  void handleExtensionShowHide(Token? showKeyword, int showElementCount,
      Token? hideKeyword, int hideElementCount) {
    assert(optionalOrNull('hide', hideKeyword));
    assert(optionalOrNull('show', showKeyword));
    debugEvent("ExtensionShowHide");

    HideClause? hideClause;
    if (hideKeyword != null) {
      var elements = popTypedList2<ShowHideClauseElement>(hideElementCount);
      hideClause = ast.hideClause(hideKeyword: hideKeyword, elements: elements);
    }

    ShowClause? showClause;
    if (showKeyword != null) {
      var elements = popTypedList2<ShowHideClauseElement>(showElementCount);
      showClause = ast.showClause(showKeyword: showKeyword, elements: elements);
    }

    push(hideClause ?? NullValue.HideClause);
    push(showClause ?? NullValue.ShowClause);
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    debugEvent("FinallyBlock");
    // The finally block is popped in "endTryStatement".
  }

  @override
  void handleForInitializerEmptyStatement(Token token) {
    debugEvent("ForInitializerEmptyStatement");
    push(NullValue.Expression);
  }

  @override
  void handleForInitializerExpressionStatement(Token token, bool forIn) {
    debugEvent("ForInitializerExpressionStatement");
  }

  @override
  void handleForInitializerLocalVariableDeclaration(Token token, bool forIn) {
    debugEvent("ForInitializerLocalVariableDeclaration");
  }

  @override
  void handleForInLoopParts(Token? awaitToken, Token forToken,
      Token leftParenthesis, Token inKeyword) {
    assert(optionalOrNull('await', awaitToken));
    assert(optional('for', forToken));
    assert(optional('(', leftParenthesis));
    assert(optional('in', inKeyword) || optional(':', inKeyword));

    var iterator = pop() as Expression;
    var variableOrDeclaration = pop()!;

    ForEachParts forLoopParts;
    if (variableOrDeclaration is VariableDeclarationStatement) {
      VariableDeclarationList variableList = variableOrDeclaration.variables;
      forLoopParts = ast.forEachPartsWithDeclaration(
        loopVariable: ast.declaredIdentifier(
            variableList.documentationComment,
            variableList.metadata,
            variableList.keyword,
            variableList.type,
            variableList.variables.first.name),
        inKeyword: inKeyword,
        iterable: iterator,
      );
    } else {
      if (variableOrDeclaration is! SimpleIdentifier) {
        // Parser has already reported the error.
        if (!leftParenthesis.next!.isIdentifier) {
          parser.rewriter.insertSyntheticIdentifier(leftParenthesis);
        }
        variableOrDeclaration = ast.simpleIdentifier(leftParenthesis.next!);
      }
      forLoopParts = ast.forEachPartsWithIdentifier(
        identifier: variableOrDeclaration,
        inKeyword: inKeyword,
        iterable: iterator,
      );
    }

    push(awaitToken ?? NullValue.AwaitToken);
    push(forToken);
    push(leftParenthesis);
    push(forLoopParts);
  }

  @override
  void handleForLoopParts(Token forKeyword, Token leftParen,
      Token leftSeparator, int updateExpressionCount) {
    assert(optional('for', forKeyword));
    assert(optional('(', leftParen));
    assert(optional(';', leftSeparator));
    assert(updateExpressionCount >= 0);

    var updates = popTypedList2<Expression>(updateExpressionCount);
    var conditionStatement = pop() as Statement;
    var initializerPart = pop();

    Expression? condition;
    Token rightSeparator;
    if (conditionStatement is ExpressionStatement) {
      condition = conditionStatement.expression;
      rightSeparator = conditionStatement.semicolon!;
    } else {
      rightSeparator = (conditionStatement as EmptyStatement).semicolon;
    }

    ForParts forLoopParts;
    if (initializerPart is VariableDeclarationStatement) {
      forLoopParts = ast.forPartsWithDeclarations(
        variables: initializerPart.variables,
        leftSeparator: leftSeparator,
        condition: condition,
        rightSeparator: rightSeparator,
        updaters: updates,
      );
    } else {
      forLoopParts = ast.forPartsWithExpression(
        initialization: initializerPart as Expression?,
        leftSeparator: leftSeparator,
        condition: condition,
        rightSeparator: rightSeparator,
        updaters: updates,
      );
    }

    push(forKeyword);
    push(leftParen);
    push(forLoopParts);
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");

    push(NullValue.ParameterDefaultValue);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    assert(token.isKeywordOrIdentifier);
    debugEvent("handleIdentifier");

    if (context.inSymbol) {
      push(token);
      return;
    }

    SimpleIdentifier identifier =
        ast.simpleIdentifier(token, isDeclaration: context.inDeclaration);
    if (context.inLibraryOrPartOfDeclaration) {
      if (!context.isContinuation) {
        push([identifier]);
      } else {
        push(identifier);
      }
    } else if (context == IdentifierContext.enumValueDeclaration) {
      var metadata = pop() as List<Annotation>?;
      var comment = _findComment(metadata, token);
      push(ast.enumConstantDeclaration(comment, metadata, identifier));
    } else {
      push(identifier);
    }
  }

  @override
  void handleIdentifierList(int count) {
    debugEvent("IdentifierList");

    push(popTypedList<SimpleIdentifier>(count) ?? NullValue.IdentifierList);
  }

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    assert(optionalOrNull('deferred', deferredKeyword));
    assert(optionalOrNull('as', asKeyword));
    debugEvent("ImportPrefix");

    if (asKeyword == null) {
      // If asKeyword is null, then no prefix has been pushed on the stack.
      // Push a placeholder indicating that there is no prefix.
      push(NullValue.Prefix);
      push(NullValue.As);
    } else {
      push(asKeyword);
    }
    push(deferredKeyword ?? NullValue.Deferred);
  }

  @override
  void handleIndexedExpression(
      Token? question, Token leftBracket, Token rightBracket) {
    assert(optional('[', leftBracket) ||
        (enableNonNullable && optional('?.[', leftBracket)));
    assert(optional(']', rightBracket));
    debugEvent("IndexedExpression");

    if (!enableNonNullable) {
      reportErrorIfNullableType(question);
    }

    var index = pop() as Expression;
    var target = pop() as Expression?;
    if (target == null) {
      var receiver = pop() as CascadeExpression;
      var token = peek() as Token;
      push(receiver);
      IndexExpression expression = ast.indexExpressionForCascade2(
          period: token,
          question: question,
          leftBracket: leftBracket,
          index: index,
          rightBracket: rightBracket);
      assert(expression.isCascaded);
      push(expression);
    } else {
      push(ast.indexExpressionForTarget2(
          target: target,
          question: question,
          leftBracket: leftBracket,
          index: index,
          rightBracket: rightBracket));
    }
  }

  @override
  void handleInterpolationExpression(Token leftBracket, Token? rightBracket) {
    var expression = pop() as Expression;
    push(ast.interpolationExpression(leftBracket, expression, rightBracket));
  }

  @override
  void handleInvalidExpression(Token token) {
    debugEvent("InvalidExpression");
  }

  @override
  void handleInvalidFunctionBody(Token leftBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', leftBracket.endGroup!));
    debugEvent("InvalidFunctionBody");
    Block block = ast.block(leftBracket, [], leftBracket.endGroup!);
    var star = pop() as Token?;
    var asyncKeyword = pop() as Token?;
    push(ast.blockFunctionBody(asyncKeyword, star, block));
  }

  @override
  void handleInvalidMember(Token endToken) {
    debugEvent("InvalidMember");
    pop(); // metadata star
  }

  @override
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    assert(optional('operator', operatorKeyword));
    debugEvent("InvalidOperatorName");

    push(_OperatorName(
        operatorKeyword, ast.simpleIdentifier(token, isDeclaration: true)));
  }

  @override
  void handleInvalidTopLevelBlock(Token token) {
    // TODO(danrubel): Consider improved recovery by adding this block
    // as part of a synthetic top level function.
    pop(); // block
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration");

    pop(); // metadata star
    // TODO(danrubel): consider creating a AST node
    // representing the invalid declaration to better support code completion,
    // quick fixes, etc, rather than discarding the metadata and token
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    var invalidTypeArgs = pop() as TypeArgumentList;
    var node = pop();
    if (node is ConstructorName) {
      push(_ConstructorNameWithInvalidTypeArgs(node, invalidTypeArgs));
    } else {
      throw UnimplementedError(
          'node is an instance of ${node.runtimeType} in handleInvalidTypeArguments');
    }
  }

  @override
  void handleIsOperator(Token isOperator, Token? not) {
    assert(optional('is', isOperator));
    assert(optionalOrNull('!', not));
    debugEvent("IsOperator");

    var type = pop() as TypeAnnotation;
    var expression = pop() as Expression;
    push(ast.isExpression(expression, isOperator, not, type));
  }

  @override
  void handleLabel(Token colon) {
    assert(optionalOrNull(':', colon));
    debugEvent("Label");

    var name = pop() as SimpleIdentifier;
    push(ast.label(name, colon));
  }

  @override
  void handleLiteralBool(Token token) {
    bool value = identical(token.stringValue, "true");
    assert(value || identical(token.stringValue, "false"));
    debugEvent("LiteralBool");

    push(ast.booleanLiteral(token, value));
  }

  @override
  void handleLiteralDouble(Token token) {
    assert(token.type == TokenType.DOUBLE);
    debugEvent("LiteralDouble");

    push(ast.doubleLiteral(token, double.parse(token.lexeme)));
  }

  @override
  void handleLiteralInt(Token token) {
    assert(identical(token.kind, INT_TOKEN) ||
        identical(token.kind, HEXADECIMAL_TOKEN));
    debugEvent("LiteralInt");

    push(ast.integerLiteral(token, int.tryParse(token.lexeme)));
  }

  @override
  void handleLiteralList(
      int count, Token leftBracket, Token? constKeyword, Token rightBracket) {
    assert(optional('[', leftBracket));
    assert(optionalOrNull('const', constKeyword));
    assert(optional(']', rightBracket));
    debugEvent("LiteralList");

    if (enableControlFlowCollections || enableSpreadCollections) {
      List<CollectionElement> elements = popCollectionElements(count);
      var typeArguments = pop() as TypeArgumentList?;

      // TODO(danrubel): Remove this and _InvalidCollectionElement
      // once control flow and spread collection support is enabled by default
      elements.removeWhere((e) => e == _invalidCollectionElement);

      push(ast.listLiteral(
          constKeyword, typeArguments, leftBracket, elements, rightBracket));
    } else {
      var elements = popTypedList<Expression>(count) ?? const [];
      var typeArguments = pop() as TypeArgumentList?;

      List<Expression> expressions = <Expression>[];
      for (var elem in elements) {
        expressions.add(elem);
      }

      push(ast.listLiteral(
          constKeyword, typeArguments, leftBracket, expressions, rightBracket));
    }
  }

  @override
  void handleLiteralMapEntry(Token colon, Token endToken) {
    assert(optional(':', colon));
    debugEvent("LiteralMapEntry");

    var value = pop() as Expression;
    var key = pop() as Expression;
    push(ast.mapLiteralEntry(key, colon, value));
  }

  @override
  void handleLiteralNull(Token token) {
    assert(optional('null', token));
    debugEvent("LiteralNull");

    push(ast.nullLiteral(token));
  }

  @override
  void handleLiteralSetOrMap(
    int count,
    Token leftBrace,
    Token? constKeyword,
    Token rightBrace,
    // TODO(danrubel): hasSetEntry parameter exists for replicating existing
    // behavior and will be removed once unified collection has been enabled
    bool hasSetEntry,
  ) {
    if (enableControlFlowCollections || enableSpreadCollections) {
      List<CollectionElement> elements = popCollectionElements(count);

      // TODO(danrubel): Remove this and _InvalidCollectionElement
      // once control flow and spread collection support is enabled by default
      elements.removeWhere((e) => e == _invalidCollectionElement);

      var typeArguments = pop() as TypeArgumentList?;
      push(ast.setOrMapLiteral(
        constKeyword: constKeyword,
        typeArguments: typeArguments,
        leftBracket: leftBrace,
        elements: elements,
        rightBracket: rightBrace,
      ));
    } else {
      var elements = popTypedList(count);
      var typeArguments = pop() as TypeArgumentList?;

      // Replicate existing behavior that has been removed from the parser.
      // This will be removed once control flow collections
      // and spread collections are enabled by default.

      // Determine if this is a set or map based on type args and content
      final typeArgCount = typeArguments?.arguments.length;
      bool? isSet = typeArgCount == 1
          ? true
          : typeArgCount != null
              ? false
              : null;
      isSet ??= hasSetEntry;

      // Build the set or map
      if (isSet) {
        final setEntries = <Expression>[];
        if (elements != null) {
          for (var elem in elements) {
            if (elem is MapLiteralEntry) {
              setEntries.add(elem.key);
              handleRecoverableError(
                  templateUnexpectedToken.withArguments(elem.separator),
                  elem.separator,
                  elem.separator);
            } else if (elem is Expression) {
              setEntries.add(elem);
            }
          }
        }
        push(ast.setOrMapLiteral(
          constKeyword: constKeyword,
          typeArguments: typeArguments,
          leftBracket: leftBrace,
          elements: setEntries,
          rightBracket: rightBrace,
        ));
      } else {
        final mapEntries = <MapLiteralEntry>[];
        if (elements != null) {
          for (var elem in elements) {
            if (elem is MapLiteralEntry) {
              mapEntries.add(elem);
            } else if (elem is Expression) {
              Token next = elem.endToken.next!;
              int offset = next.offset;
              handleRecoverableError(
                  templateExpectedButGot.withArguments(':'), next, next);
              handleRecoverableError(
                  templateExpectedIdentifier.withArguments(next), next, next);
              Token separator = SyntheticToken(TokenType.COLON, offset);
              Expression value = ast.simpleIdentifier(
                  SyntheticStringToken(TokenType.IDENTIFIER, '', offset));
              mapEntries.add(ast.mapLiteralEntry(elem, separator, value));
            }
          }
        }
        push(ast.setOrMapLiteral(
          constKeyword: constKeyword,
          typeArguments: typeArguments,
          leftBracket: leftBrace,
          elements: mapEntries,
          rightBracket: rightBrace,
        ));
      }
    }
  }

  @override
  void handleMixinHeader(Token mixinKeyword) {
    assert(optional('mixin', mixinKeyword));
    assert(classDeclaration == null &&
        mixinDeclaration == null &&
        extensionDeclaration == null);
    debugEvent("MixinHeader");

    var implementsClause = pop(NullValue.IdentifierList) as ImplementsClause?;
    var onClause = pop(NullValue.IdentifierList) as OnClause?;
    var typeParameters = pop() as TypeParameterList?;
    var name = pop() as SimpleIdentifier;
    var metadata = pop() as List<Annotation>?;
    var comment = _findComment(metadata, mixinKeyword);

    mixinDeclaration = ast.mixinDeclaration(
      comment,
      metadata,
      mixinKeyword,
      name,
      typeParameters,
      onClause,
      implementsClause,
      Tokens.openCurlyBracket(), // leftBracket
      <ClassMember>[],
      Tokens.closeCurlyBracket(), // rightBracket
    );
    declarations.add(mixinDeclaration!);
  }

  @override
  void handleMixinOn(Token? onKeyword, int typeCount) {
    assert(onKeyword == null || onKeyword.isKeywordOrIdentifier);
    debugEvent("MixinOn");

    if (onKeyword != null) {
      var types = popTypedList2<NamedType>(typeCount);
      push(ast.onClause(onKeyword, types));
    } else {
      push(NullValue.IdentifierList);
    }
  }

  @override
  void handleNamedArgument(Token colon) {
    assert(optional(':', colon));
    debugEvent("NamedArgument");

    var expression = pop() as Expression;
    var name = pop() as SimpleIdentifier;
    push(ast.namedExpression(ast.label(name, colon), expression));
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    assert(optionalOrNull('with', withKeyword));
    var mixinTypes = pop() as List<NamedType>;
    push(ast.withClause(withKeyword, mixinTypes));
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");

    if (hasName) {
      nativeName = pop() as StringLiteral; // StringLiteral
    } else {
      nativeName = null;
    }
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    assert(optional('native', nativeToken));
    assert(optional(';', semicolon));
    debugEvent("NativeFunctionBody");

    // TODO(danrubel) Change the parser to not produce these modifiers.
    pop(); // star
    pop(); // async
    push(ast.nativeFunctionBody(nativeToken, nativeName, semicolon));
  }

  @override
  void handleNewAsIdentifier(Token token) {
    if (!enableConstructorTearoffs) {
      var feature = ExperimentalFeatures.constructor_tearoffs;
      handleRecoverableError(
          templateExperimentNotEnabled.withArguments(
            feature.enableString,
            _versionAsString(ExperimentStatus.currentVersion),
          ),
          token,
          token);
    }
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");

    push(NullValue.ConstructorReferenceContinuationAfterTypeArguments);
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");

    var name = pop() as SimpleIdentifier;
    push(_makeVariableDeclaration(name, null, null));
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");

    if (!isFullAst) return;
    push(NullValue.ConstructorInitializerSeparator);
    push(NullValue.ConstructorInitializers);
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    debugEvent('NonNullAssertExpression');
    if (!enableNonNullable) {
      reportNonNullAssertExpressionNotEnabled(bang);
    } else {
      push(ast.postfixExpression(pop() as Expression, bang));
    }
  }

  @override
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer");
  }

  @override
  void handleOperator(Token operatorToken) {
    assert(operatorToken.isUserDefinableOperator);
    debugEvent("Operator");

    push(operatorToken);
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    assert(optional('operator', operatorKeyword));
    assert(token.type.isUserDefinableOperator);
    debugEvent("OperatorName");

    push(_OperatorName(
        operatorKeyword, ast.simpleIdentifier(token, isDeclaration: true)));
  }

  @override
  void handleParenthesizedCondition(Token leftParenthesis) {
    // TODO(danrubel): Implement rather than forwarding.
    handleParenthesizedExpression(leftParenthesis);
  }

  @override
  void handleParenthesizedExpression(Token leftParenthesis) {
    assert(optional('(', leftParenthesis));
    debugEvent("ParenthesizedExpression");

    var expression = pop() as Expression;
    push(ast.parenthesizedExpression(
        leftParenthesis, expression, leftParenthesis.endGroup!));
  }

  @override
  void handleQualified(Token period) {
    assert(optional('.', period));

    var identifier = pop() as SimpleIdentifier;
    var prefix = pop();
    if (prefix is List) {
      // We're just accumulating components into a list.
      prefix.add(identifier);
      push(prefix);
    } else if (prefix is SimpleIdentifier) {
      // TODO(paulberry): resolve [identifier].  Note that BodyBuilder handles
      // this situation using SendAccessGenerator.
      push(ast.prefixedIdentifier(prefix, period, identifier));
    } else {
      // TODO(paulberry): implement.
      logEvent('Qualified with >1 dot');
    }
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    /// TODO(danrubel): Ignore this error until we deprecate `native` support.
    if (message == messageNativeClauseShouldBeAnnotation && allowNativeClause) {
      return;
    }
    debugEvent("Error: ${message.problemMessage}");
    if (message.code.analyzerCodes == null && startToken is ErrorToken) {
      translateErrorToken(startToken, errorReporter.reportScannerError);
    } else {
      int offset = startToken.offset;
      int length = endToken.end - offset;
      addProblem(message, offset, length);
    }
  }

  @override
  void handleRecoverClassHeader() {
    debugEvent("RecoverClassHeader");

    var implementsClause = pop(NullValue.IdentifierList) as ImplementsClause?;
    var withClause = pop(NullValue.WithClause) as WithClause?;
    var extendsClause = pop(NullValue.ExtendsClause) as ExtendsClause?;
    var declaration = declarations.last as ClassDeclarationImpl;
    if (extendsClause != null) {
      if (declaration.extendsClause?.superclass2 == null) {
        declaration.extendsClause = extendsClause;
      }
    }
    if (withClause != null) {
      if (declaration.withClause == null) {
        declaration.withClause = withClause;
      } else {
        declaration.withClause!.mixinTypes2.addAll(withClause.mixinTypes2);
      }
    }
    if (implementsClause != null) {
      if (declaration.implementsClause == null) {
        declaration.implementsClause = implementsClause;
      } else {
        declaration.implementsClause!.interfaces2
            .addAll(implementsClause.interfaces2);
      }
    }
  }

  @override
  void handleRecoverImport(Token? semicolon) {
    assert(optionalOrNull(';', semicolon));
    debugEvent("RecoverImport");

    var combinators = pop() as List<Combinator>?;
    var deferredKeyword = pop(NullValue.Deferred) as Token?;
    var asKeyword = pop(NullValue.As) as Token?;
    var prefix = pop(NullValue.Prefix) as SimpleIdentifier?;
    var configurations = pop() as List<Configuration>?;

    var directive = directives.last as ImportDirectiveImpl;
    if (combinators != null) {
      directive.combinators.addAll(combinators);
    }
    directive.deferredKeyword ??= deferredKeyword;
    if (directive.asKeyword == null && asKeyword != null) {
      directive.asKeyword = asKeyword;
      directive.prefix = prefix;
    }
    if (configurations != null) {
      directive.configurations.addAll(configurations);
    }
    if (semicolon != null) {
      directive.semicolon = semicolon;
    }
  }

  @override
  void handleRecoverMixinHeader() {
    var implementsClause = pop(NullValue.IdentifierList) as ImplementsClause?;
    var onClause = pop(NullValue.IdentifierList) as OnClause?;

    if (onClause != null) {
      if (mixinDeclaration!.onClause == null) {
        mixinDeclaration!.onClause = onClause;
      } else {
        mixinDeclaration!.onClause!.superclassConstraints2
            .addAll(onClause.superclassConstraints2);
      }
    }
    if (implementsClause != null) {
      if (mixinDeclaration!.implementsClause == null) {
        mixinDeclaration!.implementsClause = implementsClause;
      } else {
        mixinDeclaration!.implementsClause!.interfaces2
            .addAll(implementsClause.interfaces2);
      }
    }
  }

  @override
  void handleScript(Token token) {
    assert(identical(token.type, TokenType.SCRIPT_TAG));
    debugEvent("Script");

    scriptTag = ast.scriptTag(token);
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    debugEvent("Send");

    var arguments = pop() as MethodInvocationImpl?;
    var typeArguments = pop() as TypeArgumentListImpl?;
    if (arguments != null) {
      doInvocation(typeArguments, arguments);
    } else {
      doPropertyGet();
    }
  }

  @override
  void handleShowHideIdentifier(Token? modifier, Token identifier) {
    debugEvent("handleShowHideIdentifier");

    assert(modifier == null ||
        modifier.stringValue! == "get" ||
        modifier.stringValue! == "set" ||
        modifier.stringValue! == "operator");

    SimpleIdentifier name = ast.simpleIdentifier(identifier);
    ShowHideElement element =
        ast.showHideElement(modifier: modifier, name: name);

    push(element);
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    var expression = pop() as Expression;
    if (enableSpreadCollections) {
      push(ast.spreadElement(
          spreadOperator: spreadToken, expression: expression));
    } else {
      var feature = Feature.spread_collections;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(feature.releaseVersion!),
        ),
        spreadToken,
        spreadToken,
      );
      push(_invalidCollectionElement);
    }
  }

  @override
  void handleStringJuxtaposition(Token startToken, int literalCount) {
    debugEvent("StringJuxtaposition");

    var strings = popTypedList2<StringLiteral>(literalCount);
    push(ast.adjacentStrings(strings));
  }

  @override
  void handleStringPart(Token literalString) {
    assert(identical(literalString.kind, STRING_TOKEN));
    debugEvent("StringPart");

    push(literalString);
  }

  @override
  void handleSuperExpression(Token superKeyword, IdentifierContext context) {
    assert(optional('super', superKeyword));
    debugEvent("SuperExpression");

    push(ast.superExpression(superKeyword));
  }

  @override
  void handleSymbolVoid(Token voidKeyword) {
    assert(optional('void', voidKeyword));
    debugEvent("SymbolVoid");

    push(voidKeyword);
  }

  @override
  void handleThisExpression(Token thisKeyword, IdentifierContext context) {
    assert(optional('this', thisKeyword));
    debugEvent("ThisExpression");

    push(ast.thisExpression(thisKeyword));
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    assert(optional('throw', throwToken));
    debugEvent("ThrowExpression");

    push(ast.throwExpression(throwToken, pop() as Expression));
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    debugEvent("Type");
    if (!enableNonNullable) {
      reportErrorIfNullableType(questionMark);
    }

    var arguments = pop() as TypeArgumentList?;
    var name = pop() as Identifier;
    push(
      ast.namedType(
        name: name,
        typeArguments: arguments,
        question: questionMark,
      ),
    );
  }

  @override
  void handleTypeArgumentApplication(Token openAngleBracket) {
    var typeArguments = pop() as TypeArgumentList;
    var receiver = pop() as Expression;
    if (!enableConstructorTearoffs) {
      var feature = ExperimentalFeatures.constructor_tearoffs;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(ExperimentStatus.currentVersion),
        ),
        typeArguments.leftBracket,
        typeArguments.rightBracket,
      );
    }
    push(ast.functionReference(
        function: receiver, typeArguments: typeArguments));
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("handleTypeVariablesDefined");
    assert(count > 0);
    push(popTypedList<TypeParameter>(count));
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token operator) {
    assert(operator.type.isUnaryPostfixOperator);
    debugEvent("UnaryPostfixAssignmentExpression");

    var expression = pop() as Expression;
    if (!expression.isAssignable) {
      // This error is also reported by the body builder.
      handleRecoverableError(
          messageIllegalAssignmentToNonAssignable, operator, operator);
    }
    push(ast.postfixExpression(expression, operator));
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token operator) {
    assert(operator.type.isUnaryPrefixOperator);
    debugEvent("UnaryPrefixAssignmentExpression");

    var expression = pop() as Expression;
    if (!expression.isAssignable) {
      // This error is also reported by the body builder.
      handleRecoverableError(messageMissingAssignableSelector,
          expression.endToken, expression.endToken);
    }
    push(ast.prefixExpression(operator, expression));
  }

  @override
  void handleUnaryPrefixExpression(Token operator) {
    assert(operator.type.isUnaryPrefixOperator);
    debugEvent("UnaryPrefixExpression");

    push(ast.prefixExpression(operator, pop() as Expression));
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    assert(optional('=', equals) || optional(':', equals));
    debugEvent("ValuedFormalParameter");

    var value = pop() as Expression;
    push(_ParameterDefaultValue(equals, value));
  }

  @override
  void handleVoidKeyword(Token voidKeyword) {
    assert(optional('void', voidKeyword));
    debugEvent("VoidKeyword");

    // TODO(paulberry): is this sufficient, or do we need to hook the "void"
    // keyword up to an element?
    handleIdentifier(voidKeyword, IdentifierContext.typeReference);
    handleNoTypeArguments(voidKeyword);
    handleType(voidKeyword, null);
  }

  @override
  void handleVoidKeywordWithTypeArguments(Token voidKeyword) {
    assert(optional('void', voidKeyword));
    debugEvent("VoidKeywordWithTypeArguments");
    var arguments = pop() as TypeArgumentList;

    // TODO(paulberry): is this sufficient, or do we need to hook the "void"
    // keyword up to an element?
    handleIdentifier(voidKeyword, IdentifierContext.typeReference);
    push(arguments);
    handleType(voidKeyword, null);
  }

  @override
  Never internalProblem(Message message, int charOffset, Uri uri) {
    throw UnsupportedError(message.problemMessage);
  }

  /// Return `true` if [token] is either `null` or is the symbol or keyword
  /// [value].
  bool optionalOrNull(String value, Token? token) {
    return token == null || identical(value, token.stringValue);
  }

  List<CommentReference> parseCommentReferences(Token dartdoc) {
    // Parse dartdoc into potential comment reference source/offset pairs
    int count = parser.parseCommentReferences(dartdoc);
    List sourcesAndOffsets = List.filled(count * 2, null);
    popList(count * 2, sourcesAndOffsets);

    // Parse each of the source/offset pairs into actual comment references
    count = 0;
    int index = 0;
    while (index < sourcesAndOffsets.length) {
      String referenceSource = sourcesAndOffsets[index++];
      int referenceOffset = sourcesAndOffsets[index++];
      ScannerResult result = scanString(referenceSource);
      if (!result.hasErrors) {
        Token token = result.tokens;
        if (parser.parseOneCommentReference(token, referenceOffset)) {
          ++count;
        }
      }
    }

    return popTypedList<CommentReference>(count) ?? const [];
  }

  List<CollectionElement> popCollectionElements(int count) {
    // TODO(scheglov) Not efficient.
    final elements = <CollectionElement>[];
    for (int index = count - 1; index >= 0; --index) {
      var element = pop();
      elements.add(element as CollectionElement);
    }
    return elements.reversed.toList();
  }

  List? popList(int n, List list) {
    if (n == 0) return null;
    return stack.popList(n, list, null);
  }

  List<T>? popTypedList<T extends Object>(int count) {
    if (count == 0) return null;
    assert(stack.length >= count);

    final tailList = List<T?>.filled(count, null, growable: true);
    stack.popList(count, tailList, null);
    return tailList.whereNotNull().toList();
  }

  // List<T?>? popTypedList<T>(int count, [List<T>? list]) {
  //   if (count == 0) return null;
  //   assert(stack.length >= count);
  //
  //   final tailList = list ?? List<T?>.filled(count, null, growable: true);
  //   stack.popList(count, tailList, null);
  //   return tailList;
  // }

  /// TODO(scheglov) This is probably not optimal.
  List<T> popTypedList2<T>(int count) {
    var result = <T>[];
    for (var i = 0; i < count; i++) {
      var element = stack.pop(null) as T;
      result.add(element);
    }
    return result.reversed.toList();
  }

  void pushForControlFlowInfo(Token? awaitToken, Token forToken,
      Token leftParenthesis, ForLoopParts forLoopParts, Object entry) {
    if (entry == _invalidCollectionElement) {
      push(_invalidCollectionElement);
    } else if (enableControlFlowCollections) {
      push(ast.forElement(
        awaitKeyword: awaitToken,
        forKeyword: forToken,
        leftParenthesis: leftParenthesis,
        forLoopParts: forLoopParts,
        rightParenthesis: leftParenthesis.endGroup!,
        body: entry as CollectionElement,
      ));
    } else {
      var feature = Feature.control_flow_collections;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(feature.releaseVersion!),
        ),
        forToken,
        forToken,
      );
      push(_invalidCollectionElement);
    }
  }

  void pushIfControlFlowInfo(
      Token ifToken,
      ParenthesizedExpression condition,
      CollectionElement thenElement,
      Token? elseToken,
      CollectionElement? elseElement) {
    if (thenElement == _invalidCollectionElement ||
        elseElement == _invalidCollectionElement) {
      push(_invalidCollectionElement);
    } else if (enableControlFlowCollections) {
      push(ast.ifElement(
        ifKeyword: ifToken,
        leftParenthesis: condition.leftParenthesis,
        condition: condition.expression,
        rightParenthesis: condition.rightParenthesis,
        thenElement: thenElement,
        elseKeyword: elseToken,
        elseElement: elseElement,
      ));
    } else {
      var feature = ExperimentalFeatures.control_flow_collections;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(feature.releaseVersion!),
        ),
        ifToken,
        ifToken,
      );
      push(_invalidCollectionElement);
    }
  }

  void reportErrorIfNullableType(Token? questionMark) {
    if (questionMark != null) {
      assert(optional('?', questionMark));
      var feature = ExperimentalFeatures.non_nullable;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(feature.releaseVersion!),
        ),
        questionMark,
        questionMark,
      );
    }
  }

  void reportErrorIfSuper(Expression expression) {
    if (expression is SuperExpression) {
      // This error is also reported by the body builder.
      handleRecoverableError(messageMissingAssignableSelector,
          expression.beginToken, expression.endToken);
    }
  }

  void reportNonNullableModifierError(Token? modifierToken) {
    if (modifierToken != null) {
      var feature = ExperimentalFeatures.non_nullable;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(feature.releaseVersion!),
        ),
        modifierToken,
        modifierToken,
      );
    }
  }

  void reportNonNullAssertExpressionNotEnabled(Token bang) {
    var feature = ExperimentalFeatures.non_nullable;
    handleRecoverableError(
      templateExperimentNotEnabled.withArguments(
        feature.enableString,
        _versionAsString(feature.releaseVersion!),
      ),
      bang,
      bang,
    );
  }

  Comment? _findComment(List<Annotation>? metadata, Token tokenAfterMetadata) {
    // Find the dartdoc tokens
    var dartdoc = parser.findDartDoc(tokenAfterMetadata);
    if (dartdoc == null) {
      if (metadata == null) {
        return null;
      }
      int index = metadata.length;
      while (true) {
        if (index == 0) {
          return null;
        }
        --index;
        dartdoc = parser.findDartDoc(metadata[index].beginToken);
        if (dartdoc != null) {
          break;
        }
      }
    }

    // Build and return the comment
    List<CommentReference> references = parseCommentReferences(dartdoc);
    List<Token> tokens = <Token>[dartdoc];
    if (dartdoc.lexeme.startsWith('///')) {
      dartdoc = dartdoc.next;
      while (dartdoc != null) {
        if (dartdoc.lexeme.startsWith('///')) {
          tokens.add(dartdoc);
        }
        dartdoc = dartdoc.next;
      }
    }
    return ast.documentationComment(tokens, references);
  }

  void _handleInstanceCreation(Token? token) {
    var arguments = pop() as MethodInvocation;
    ConstructorName constructorName;
    TypeArgumentList? typeArguments;
    var object = pop();
    if (object is _ConstructorNameWithInvalidTypeArgs) {
      constructorName = object.name;
      typeArguments = object.invalidTypeArgs;
    } else {
      constructorName = object as ConstructorName;
    }
    push(ast.instanceCreationExpression(
        token, constructorName, arguments.argumentList,
        typeArguments: typeArguments));
  }

  VariableDeclaration _makeVariableDeclaration(
      SimpleIdentifier name, Token? equals, Expression? initializer) {
    return ast.variableDeclaration(name, equals, initializer);
  }

  ArgumentList _syntheticArgumentList(Token precedingToken) {
    int syntheticOffset = precedingToken.end;
    return ast.argumentList(
        SyntheticToken(TokenType.OPEN_PAREN, syntheticOffset),
        [],
        SyntheticToken(TokenType.CLOSE_PAREN, syntheticOffset));
  }

  SimpleIdentifier _tmpSimpleIdentifier() {
    return ast.simpleIdentifier(
      StringToken(TokenType.STRING, '__tmp', -1),
    );
  }

  ParameterKind _toAnalyzerParameterKind(
      FormalParameterKind type, Token? requiredKeyword) {
    if (type == FormalParameterKind.optionalPositional) {
      return ParameterKind.POSITIONAL;
    } else if (type == FormalParameterKind.optionalNamed) {
      if (requiredKeyword != null) {
        return ParameterKind.NAMED_REQUIRED;
      }
      return ParameterKind.NAMED;
    } else {
      return ParameterKind.REQUIRED;
    }
  }

  static String _versionAsString(Version version) {
    return '${version.major}.${version.minor}.${version.patch}';
  }
}

class _ConstructorNameWithInvalidTypeArgs {
  final ConstructorName name;
  final TypeArgumentList invalidTypeArgs;

  _ConstructorNameWithInvalidTypeArgs(this.name, this.invalidTypeArgs);
}

/// When [enableSpreadCollections] and/or [enableControlFlowCollections]
/// are false, this class is pushed on the stack when a disabled
/// [CollectionElement] has been parsed.
class _InvalidCollectionElement implements CollectionElement {
  // TODO(danrubel): Remove this once control flow and spread collections
  // have been enabled by default.

  const _InvalidCollectionElement._();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Data structure placed on the stack to represent a non-empty sequence
/// of modifiers.
class _Modifiers {
  Token? abstractKeyword;
  Token? externalKeyword;
  Token? finalConstOrVarKeyword;
  Token? staticKeyword;
  Token? covariantKeyword;
  Token? requiredToken;
  Token? lateToken;

  /// Return the token that is lexically first.
  Token? get beginToken {
    Token? firstToken;
    for (Token? token in [
      abstractKeyword,
      externalKeyword,
      finalConstOrVarKeyword,
      staticKeyword,
      covariantKeyword,
      requiredToken,
      lateToken,
    ]) {
      if (firstToken == null) {
        firstToken = token;
      } else if (token != null) {
        if (token.offset < firstToken.offset) {
          firstToken = token;
        }
      }
    }
    return firstToken;
  }

  /// Return the `const` keyword or `null`.
  Token? get constKeyword {
    return identical('const', finalConstOrVarKeyword?.lexeme)
        ? finalConstOrVarKeyword
        : null;
  }
}

/// Data structure placed on the stack to represent the keyword "operator"
/// followed by a token.
class _OperatorName {
  final Token operatorKeyword;
  final SimpleIdentifier name;

  _OperatorName(this.operatorKeyword, this.name);
}

/// Data structure placed on the stack as a container for optional parameters.
class _OptionalFormalParameters {
  final List<FormalParameter>? parameters;
  final Token leftDelimiter;
  final Token rightDelimiter;

  _OptionalFormalParameters(
      this.parameters, this.leftDelimiter, this.rightDelimiter);
}

/// Data structure placed on the stack to represent the default parameter
/// value with the separator token.
class _ParameterDefaultValue {
  final Token separator;
  final Expression value;

  _ParameterDefaultValue(this.separator, this.value);
}

/// Data structure placed on stack to represent the redirected constructor.
class _RedirectingFactoryBody {
  final Token? asyncKeyword;
  final Token? starKeyword;
  final Token equalToken;
  final ConstructorName constructorName;

  _RedirectingFactoryBody(this.asyncKeyword, this.starKeyword, this.equalToken,
      this.constructorName);
}
