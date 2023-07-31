// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/not_serializable_nodes.dart';
import 'package:analyzer/src/summary2/unlinked_token_type.dart';
import 'package:collection/collection.dart';

/// Deserializer of ASTs.
class AstBinaryReader {
  final ResolutionReader _reader;

  AstBinaryReader({
    required ResolutionReader reader,
  }) : _reader = reader;

  AstNode readNode() {
    var tag = _readByte();
    switch (tag) {
      case Tag.AdjacentStrings:
        return _readAdjacentStrings();
      case Tag.Annotation:
        return _readAnnotation();
      case Tag.ArgumentList:
        return _readArgumentList();
      case Tag.AsExpression:
        return _readAsExpression();
      case Tag.AssertInitializer:
        return _readAssertInitializer();
      case Tag.AssignmentExpression:
        return _readAssignmentExpression();
      case Tag.AwaitExpression:
        return _readAwaitExpression();
      case Tag.BinaryExpression:
        return _readBinaryExpression();
      case Tag.BooleanLiteral:
        return _readBooleanLiteral();
      case Tag.CascadeExpression:
        return _readCascadeExpression();
      case Tag.ConditionalExpression:
        return _readConditionalExpression();
      case Tag.ConstructorFieldInitializer:
        return _readConstructorFieldInitializer();
      case Tag.ConstructorName:
        return _readConstructorName();
      case Tag.ConstructorReference:
        return _readConstructorReference();
      case Tag.DeclaredIdentifier:
        return _readDeclaredIdentifier();
      case Tag.DefaultFormalParameter:
        return _readDefaultFormalParameter();
      case Tag.DottedName:
        return _readDottedName();
      case Tag.DoubleLiteral:
        return _readDoubleLiteral();
      case Tag.ExtensionOverride:
        return _readExtensionOverride();
      case Tag.ForEachPartsWithDeclaration:
        return _readForEachPartsWithDeclaration();
      case Tag.ForElement:
        return _readForElement();
      case Tag.ForPartsWithDeclarations:
        return _readForPartsWithDeclarations();
      case Tag.ForPartsWithExpression:
        return _readForPartsWithExpression();
      case Tag.FieldFormalParameter:
        return _readFieldFormalParameter();
      case Tag.FormalParameterList:
        return _readFormalParameterList();
      case Tag.FunctionExpressionStub:
        return _readFunctionExpression();
      case Tag.FunctionExpressionInvocation:
        return _readFunctionExpressionInvocation();
      case Tag.FunctionReference:
        return _readFunctionReference();
      case Tag.FunctionTypedFormalParameter:
        return _readFunctionTypedFormalParameter();
      case Tag.GenericFunctionType:
        return _readGenericFunctionType();
      case Tag.IfElement:
        return _readIfElement();
      case Tag.ImplicitCallReference:
        return _readImplicitCallReference();
      case Tag.IndexExpression:
        return _readIndexExpression();
      case Tag.IntegerLiteralNegative1:
        return _readIntegerLiteralNegative1();
      case Tag.IntegerLiteralNull:
        return _readIntegerLiteralNull();
      case Tag.IntegerLiteralPositive1:
        return _readIntegerLiteralPositive1();
      case Tag.IntegerLiteralPositive:
        return _readIntegerLiteralPositive();
      case Tag.IntegerLiteralNegative:
        return _readIntegerLiteralNegative();
      case Tag.InterpolationExpression:
        return _readInterpolationExpression();
      case Tag.InterpolationString:
        return _readInterpolationString();
      case Tag.IsExpression:
        return _readIsExpression();
      case Tag.ListLiteral:
        return _readListLiteral();
      case Tag.MapLiteralEntry:
        return _readMapLiteralEntry();
      case Tag.MethodInvocation:
        return _readMethodInvocation();
      case Tag.NamedExpression:
        return _readNamedExpression();
      case Tag.NullLiteral:
        return _readNullLiteral();
      case Tag.InstanceCreationExpression:
        return _readInstanceCreationExpression();
      case Tag.ParenthesizedExpression:
        return _readParenthesizedExpression();
      case Tag.PostfixExpression:
        return _readPostfixExpression();
      case Tag.PrefixExpression:
        return _readPrefixExpression();
      case Tag.PrefixedIdentifier:
        return _readPrefixedIdentifier();
      case Tag.PropertyAccess:
        return _readPropertyAccess();
      case Tag.RecordLiteral:
        return _readRecordLiteral();
      case Tag.RedirectingConstructorInvocation:
        return _readRedirectingConstructorInvocation();
      case Tag.SetOrMapLiteral:
        return _readSetOrMapLiteral();
      case Tag.SimpleFormalParameter:
        return _readSimpleFormalParameter();
      case Tag.SimpleIdentifier:
        return _readSimpleIdentifier();
      case Tag.SimpleStringLiteral:
        return _readSimpleStringLiteral();
      case Tag.SpreadElement:
        return _readSpreadElement();
      case Tag.StringInterpolation:
        return _readStringInterpolation();
      case Tag.SuperConstructorInvocation:
        return _readSuperConstructorInvocation();
      case Tag.SuperExpression:
        return _readSuperExpression();
      case Tag.SymbolLiteral:
        return _readSymbolLiteral();
      case Tag.ThisExpression:
        return _readThisExpression();
      case Tag.ThrowExpression:
        return _readThrowExpression();
      case Tag.TypeArgumentList:
        return _readTypeArgumentList();
      case Tag.TypeLiteral:
        return _readTypeLiteral();
      case Tag.NamedType:
        return _readNamedType();
      case Tag.TypeParameter:
        return _readTypeParameter();
      case Tag.TypeParameterList:
        return _readTypeParameterList();
      case Tag.VariableDeclaration:
        return _readVariableDeclaration();
      case Tag.VariableDeclarationList:
        return _readVariableDeclarationList();
      default:
        throw UnimplementedError('Unexpected tag: $tag');
    }
  }

  IntegerLiteral _createIntegerLiteral(String lexeme, int value) {
    var node = IntegerLiteralImpl(
      literal: TokenFactory.tokenFromTypeAndString(TokenType.INT, lexeme),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  AdjacentStrings _readAdjacentStrings() {
    var components = _readNodeList<StringLiteralImpl>();
    var node = AdjacentStringsImpl(strings: components);
    _readExpressionResolution(node);
    return node;
  }

  Annotation _readAnnotation() {
    var name = readNode() as IdentifierImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var constructorName = _readOptionalNode() as SimpleIdentifierImpl?;
    var arguments = _readOptionalNode() as ArgumentListImpl?;
    var node = AnnotationImpl(
      atSign: Tokens.at(),
      name: name,
      typeArguments: typeArguments,
      period: constructorName != null ? Tokens.period() : null,
      constructorName: constructorName,
      arguments: arguments,
    );
    node.element = _reader.readElement();
    return node;
  }

  ArgumentList _readArgumentList() {
    var arguments = _readNodeList<ExpressionImpl>();

    return ArgumentListImpl(
      leftParenthesis: Tokens.openParenthesis(),
      arguments: arguments,
      rightParenthesis: Tokens.closeParenthesis(),
    );
  }

  AsExpression _readAsExpression() {
    var expression = readNode() as ExpressionImpl;
    var type = readNode() as TypeAnnotationImpl;
    var node = AsExpressionImpl(
      expression: expression,
      asOperator: Tokens.as_(),
      type: type,
    );
    _readExpressionResolution(node);
    return node;
  }

  AssertInitializer _readAssertInitializer() {
    var condition = readNode() as ExpressionImpl;
    var message = _readOptionalNode() as ExpressionImpl?;
    return AssertInitializerImpl(
      assertKeyword: Tokens.assert_(),
      leftParenthesis: Tokens.openParenthesis(),
      condition: condition,
      comma: message != null ? Tokens.comma() : null,
      message: message,
      rightParenthesis: Tokens.closeParenthesis(),
    );
  }

  AssignmentExpression _readAssignmentExpression() {
    var leftHandSide = readNode() as ExpressionImpl;
    var rightHandSide = readNode() as ExpressionImpl;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var node = AssignmentExpressionImpl(
      leftHandSide: leftHandSide,
      operator: Tokens.fromType(operatorType),
      rightHandSide: rightHandSide,
    );
    node.staticElement = _reader.readElement() as MethodElement?;
    node.readElement = _reader.readElement();
    node.readType = _reader.readType();
    node.writeElement = _reader.readElement();
    node.writeType = _reader.readType();
    _readExpressionResolution(node);
    return node;
  }

  AwaitExpression _readAwaitExpression() {
    var expression = readNode() as ExpressionImpl;
    return AwaitExpressionImpl(
      awaitKeyword: Tokens.await_(),
      expression: expression,
    );
  }

  BinaryExpression _readBinaryExpression() {
    var leftOperand = readNode() as ExpressionImpl;
    var rightOperand = readNode() as ExpressionImpl;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var node = BinaryExpressionImpl(
      leftOperand: leftOperand,
      operator: Tokens.fromType(operatorType),
      rightOperand: rightOperand,
    );
    node.staticElement = _reader.readElement() as MethodElement?;
    node.staticInvokeType = _reader.readOptionalFunctionType();
    _readExpressionResolution(node);
    return node;
  }

  BooleanLiteral _readBooleanLiteral() {
    var value = _readByte() == 1;
    var node = BooleanLiteralImpl(
      literal: value ? Tokens.true_() : Tokens.false_(),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  int _readByte() {
    return _reader.readByte();
  }

  CascadeExpression _readCascadeExpression() {
    var target = readNode() as ExpressionImpl;
    var sections = _readNodeList<ExpressionImpl>();
    var node = CascadeExpressionImpl(
      target: target,
      cascadeSections: sections,
    );
    node.staticType = target.staticType;
    return node;
  }

  ConditionalExpression _readConditionalExpression() {
    var condition = readNode() as ExpressionImpl;
    var thenExpression = readNode() as ExpressionImpl;
    var elseExpression = readNode() as ExpressionImpl;
    var node = ConditionalExpressionImpl(
      condition: condition,
      question: Tokens.question(),
      thenExpression: thenExpression,
      colon: Tokens.colon(),
      elseExpression: elseExpression,
    );
    _readExpressionResolution(node);
    return node;
  }

  ConstructorFieldInitializer _readConstructorFieldInitializer() {
    var flags = _readByte();
    var fieldName = readNode() as SimpleIdentifierImpl;
    var expression = readNode() as ExpressionImpl;
    var hasThis = AstBinaryFlags.hasThis(flags);
    return ConstructorFieldInitializerImpl(
      thisKeyword: hasThis ? Tokens.this_() : null,
      period: hasThis ? Tokens.period() : null,
      fieldName: fieldName,
      equals: Tokens.eq(),
      expression: expression,
    );
  }

  ConstructorName _readConstructorName() {
    var type = readNode() as NamedTypeImpl;
    var name = _readOptionalNode() as SimpleIdentifierImpl?;

    var node = ConstructorNameImpl(
      type: type,
      period: name != null ? Tokens.period() : null,
      name: name,
    );
    node.staticElement = _reader.readElement() as ConstructorElement?;
    return node;
  }

  ConstructorReference _readConstructorReference() {
    var constructorName = readNode() as ConstructorNameImpl;
    var node = ConstructorReferenceImpl(
      constructorName: constructorName,
    );
    _readExpressionResolution(node);
    return node;
  }

  Token _readDeclarationName() {
    var name = _reader.readStringReference();
    return StringToken(TokenType.STRING, name, -1);
  }

  DeclaredIdentifier _readDeclaredIdentifier() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotationImpl?;
    var name = _readDeclarationName();
    var metadata = _readNodeList<AnnotationImpl>();
    return DeclaredIdentifierImpl(
      comment: null,
      metadata: metadata,
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.isVar(flags),
        Tokens.var_(),
      ),
      type: type,
      name: name,
    );
  }

  DefaultFormalParameter _readDefaultFormalParameter() {
    var flags = _readByte();
    var parameter = readNode() as NormalFormalParameterImpl;
    var defaultValue = _readOptionalNode() as ExpressionImpl?;

    ParameterKind kind;
    if (AstBinaryFlags.isPositional(flags)) {
      kind = AstBinaryFlags.isRequired(flags)
          ? ParameterKind.REQUIRED
          : ParameterKind.POSITIONAL;
    } else {
      kind = AstBinaryFlags.isRequired(flags)
          ? ParameterKind.NAMED_REQUIRED
          : ParameterKind.NAMED;
    }

    var node = DefaultFormalParameterImpl(
      parameter: parameter,
      kind: kind,
      separator: AstBinaryFlags.hasInitializer(flags) ? Tokens.colon() : null,
      defaultValue: defaultValue,
    );

    var nonDefaultElement = parameter.declaredElement!;
    var element = DefaultParameterElementImpl(
      name: nonDefaultElement.name,
      nameOffset: nonDefaultElement.nameOffset,
      parameterKind: kind,
    );
    if (parameter is SimpleFormalParameterImpl) {
      parameter.declaredElement = element;
    }
    node.declaredElement = element;
    element.type = nonDefaultElement.type;

    return node;
  }

  DottedName _readDottedName() {
    var components = _readNodeList<SimpleIdentifierImpl>();
    return DottedNameImpl(
      components: components,
    );
  }

  DoubleLiteral _readDoubleLiteral() {
    var value = _reader.readDouble();
    var node = DoubleLiteralImpl(
      literal: StringToken(
          TokenType.STRING, considerCanonicalizeString('$value'), -1),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  void _readExpressionResolution(ExpressionImpl node) {
    node.staticType = _reader.readType();
  }

  ExtensionOverride _readExtensionOverride() {
    var extensionName = readNode() as IdentifierImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var argumentList = readNode() as ArgumentListImpl;
    var node = ExtensionOverrideImpl(
      extensionName: extensionName,
      argumentList: argumentList,
      typeArguments: typeArguments,
    );
    _readExpressionResolution(node);
    return node;
  }

  FieldFormalParameter _readFieldFormalParameter() {
    var typeParameters = _readOptionalNode() as TypeParameterListImpl?;
    var type = _readOptionalNode() as TypeAnnotationImpl?;
    var formalParameters = _readOptionalNode() as FormalParameterListImpl?;
    var flags = _readByte();
    var metadata = _readNodeList<AnnotationImpl>();
    var name = _readDeclarationName();
    var node = FieldFormalParameterImpl(
      name: name,
      period: Tokens.period(),
      thisKeyword: Tokens.this_(),
      covariantKeyword:
          AstBinaryFlags.isCovariant(flags) ? Tokens.covariant_() : null,
      typeParameters: typeParameters,
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.isVar(flags),
        Tokens.var_(),
      ),
      metadata: metadata,
      comment: null,
      type: type,
      parameters: formalParameters,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
      requiredKeyword:
          AstBinaryFlags.isRequired(flags) ? Tokens.required_() : null,
    );
    return node;
  }

  ForEachPartsWithDeclaration _readForEachPartsWithDeclaration() {
    var loopVariable = readNode() as DeclaredIdentifierImpl;
    var iterable = readNode() as ExpressionImpl;
    return ForEachPartsWithDeclarationImpl(
      inKeyword: Tokens.in_(),
      iterable: iterable,
      loopVariable: loopVariable,
    );
  }

  ForElement _readForElement() {
    var flags = _readByte();
    var forLoopParts = readNode() as ForLoopPartsImpl;
    var body = readNode() as CollectionElementImpl;
    return ForElementImpl(
      awaitKeyword: AstBinaryFlags.hasAwait(flags) ? Tokens.await_() : null,
      body: body,
      forKeyword: Tokens.for_(),
      forLoopParts: forLoopParts,
      leftParenthesis: Tokens.openParenthesis(),
      rightParenthesis: Tokens.closeParenthesis(),
    );
  }

  FormalParameterList _readFormalParameterList() {
    var flags = _readByte();
    var parameters = _readNodeList<FormalParameterImpl>();

    return FormalParameterListImpl(
      leftParenthesis: Tokens.openParenthesis(),
      parameters: parameters,
      leftDelimiter: Tokens.choose(
        AstBinaryFlags.isDelimiterCurly(flags),
        Tokens.openCurlyBracket(),
        AstBinaryFlags.isDelimiterSquare(flags),
        Tokens.openSquareBracket(),
      ),
      rightDelimiter: Tokens.choose(
        AstBinaryFlags.isDelimiterCurly(flags),
        Tokens.closeCurlyBracket(),
        AstBinaryFlags.isDelimiterSquare(flags),
        Tokens.closeSquareBracket(),
      ),
      rightParenthesis: Tokens.closeParenthesis(),
    );
  }

  ForPartsWithDeclarations _readForPartsWithDeclarations() {
    var variables = readNode() as VariableDeclarationListImpl;
    var condition = _readOptionalNode() as ExpressionImpl?;
    var updaters = _readNodeList<ExpressionImpl>();
    return ForPartsWithDeclarationsImpl(
      condition: condition,
      leftSeparator: Tokens.semicolon(),
      rightSeparator: Tokens.semicolon(),
      updaters: updaters,
      variableList: variables,
    );
  }

  ForPartsWithExpression _readForPartsWithExpression() {
    var initialization = _readOptionalNode() as ExpressionImpl?;
    var condition = _readOptionalNode() as ExpressionImpl?;
    var updaters = _readNodeList<ExpressionImpl>();
    return ForPartsWithExpressionImpl(
      condition: condition,
      initialization: initialization,
      leftSeparator: Tokens.semicolon(),
      rightSeparator: Tokens.semicolon(),
      updaters: updaters,
    );
  }

  FunctionExpression _readFunctionExpression() {
    return emptyFunctionExpression();
  }

  FunctionExpressionInvocation _readFunctionExpressionInvocation() {
    var function = readNode() as ExpressionImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = readNode() as ArgumentListImpl;
    var node = FunctionExpressionInvocationImpl(
      function: function,
      typeArguments: typeArguments,
      argumentList: arguments,
    );
    _readInvocationExpression(node);
    return node;
  }

  FunctionReference _readFunctionReference() {
    var function = readNode() as ExpressionImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;

    var node = FunctionReferenceImpl(
      function: function,
      typeArguments: typeArguments,
    );
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    _readExpressionResolution(node);
    return node;
  }

  FunctionTypedFormalParameter _readFunctionTypedFormalParameter() {
    var typeParameters = _readOptionalNode() as TypeParameterListImpl?;
    var returnType = _readOptionalNode() as TypeAnnotationImpl?;
    var formalParameters = readNode() as FormalParameterListImpl;
    var flags = _readByte();
    var metadata = _readNodeList<AnnotationImpl>();
    var name = _readDeclarationName();
    var node = FunctionTypedFormalParameterImpl(
      comment: null,
      covariantKeyword:
          AstBinaryFlags.isCovariant(flags) ? Tokens.covariant_() : null,
      name: name,
      metadata: metadata,
      parameters: formalParameters,
      requiredKeyword:
          AstBinaryFlags.isRequired(flags) ? Tokens.required_() : null,
      returnType: returnType,
      typeParameters: typeParameters,
      question: null,
    );
    return node;
  }

  GenericFunctionType _readGenericFunctionType() {
    var flags = _readByte();
    // TODO(scheglov) add type parameters to locals
    var typeParameters = _readOptionalNode() as TypeParameterListImpl?;
    var returnType = _readOptionalNode() as TypeAnnotationImpl?;
    var formalParameters = readNode() as FormalParameterListImpl;
    var node = GenericFunctionTypeImpl(
      returnType: returnType,
      functionKeyword: Tokens.function(),
      typeParameters: typeParameters,
      parameters: formalParameters,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
    );
    var type = _reader.readRequiredType() as FunctionType;
    node.type = type;

    var element = GenericFunctionTypeElementImpl.forOffset(-1);
    element.parameters = formalParameters.parameters
        .map((parameter) => parameter.declaredElement!)
        .toList();
    element.returnType = returnType?.type ?? DynamicTypeImpl.instance;
    element.type = type;
    node.declaredElement = element;

    return node;
  }

  IfElement _readIfElement() {
    var condition = readNode() as ExpressionImpl;
    var thenElement = readNode() as CollectionElementImpl;
    var elseElement = _readOptionalNode() as CollectionElementImpl?;
    return IfElementImpl(
      condition: condition,
      caseClause: null,
      elseElement: elseElement,
      elseKeyword: elseElement != null ? Tokens.else_() : null,
      ifKeyword: Tokens.if_(),
      leftParenthesis: Tokens.openParenthesis(),
      rightParenthesis: Tokens.closeParenthesis(),
      thenElement: thenElement,
    );
  }

  ImplicitCallReference _readImplicitCallReference() {
    var expression = readNode() as ExpressionImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var typeArgumentTypes = _reader.readOptionalTypeList()!;
    var staticElement = _reader.readElement() as MethodElement;

    var node = ImplicitCallReferenceImpl(
      expression: expression,
      staticElement: staticElement,
      typeArguments: typeArguments,
      typeArgumentTypes: typeArgumentTypes,
    );
    _readExpressionResolution(node);
    return node;
  }

  IndexExpression _readIndexExpression() {
    var flags = _readByte();
    var target = _readOptionalNode() as ExpressionImpl?;
    var index = readNode() as ExpressionImpl;
    // TODO(scheglov) Is this clumsy?
    IndexExpressionImpl node;
    if (target != null) {
      node = (IndexExpressionImpl.forTarget(
        target: target,
        question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
        leftBracket: Tokens.openSquareBracket(),
        index: index,
        rightBracket: Tokens.closeSquareBracket(),
      ))
        ..period =
            AstBinaryFlags.hasPeriod(flags) ? Tokens.periodPeriod() : null;
    } else {
      node = IndexExpressionImpl.forCascade(
        period: Tokens.periodPeriod(),
        question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
        leftBracket: Tokens.openSquareBracket(),
        index: index,
        rightBracket: Tokens.closeSquareBracket(),
      );
    }
    node.staticElement = _reader.readElement() as MethodElement?;
    _readExpressionResolution(node);
    return node;
  }

  InstanceCreationExpression _readInstanceCreationExpression() {
    var flags = _readByte();
    var constructorName = readNode() as ConstructorNameImpl;
    var argumentList = readNode() as ArgumentListImpl;

    var node = InstanceCreationExpressionImpl(
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isNew(flags),
        Tokens.new_(),
      ),
      constructorName: constructorName,
      argumentList: argumentList,
      typeArguments: null,
    );
    _readExpressionResolution(node);
    _resolveNamedExpressions(
      node.constructorName.staticElement,
      node.argumentList,
    );
    return node;
  }

  IntegerLiteral _readIntegerLiteralNegative() {
    var lexeme = _readStringReference();
    var value = (_readUInt32() << 32) | _readUInt32();
    return _createIntegerLiteral(lexeme, -value);
  }

  IntegerLiteral _readIntegerLiteralNegative1() {
    var lexeme = _readStringReference();
    var value = _readByte();
    return _createIntegerLiteral(lexeme, -value);
  }

  IntegerLiteral _readIntegerLiteralNull() {
    var lexeme = _readStringReference();
    var node = IntegerLiteralImpl(
      literal: TokenFactory.tokenFromTypeAndString(TokenType.INT, lexeme),
      value: null,
    );
    _readExpressionResolution(node);
    return node;
  }

  IntegerLiteral _readIntegerLiteralPositive() {
    var lexeme = _readStringReference();
    var value = (_readUInt32() << 32) | _readUInt32();
    return _createIntegerLiteral(lexeme, value);
  }

  IntegerLiteral _readIntegerLiteralPositive1() {
    var lexeme = _readStringReference();
    var value = _readByte();
    return _createIntegerLiteral(lexeme, value);
  }

  InterpolationExpression _readInterpolationExpression() {
    var flags = _readByte();
    var expression = readNode() as ExpressionImpl;
    var isIdentifier = AstBinaryFlags.isStringInterpolationIdentifier(flags);
    return InterpolationExpressionImpl(
      leftBracket: isIdentifier
          ? Tokens.openCurlyBracket()
          : Tokens.stringInterpolationExpression(),
      expression: expression,
      rightBracket: isIdentifier ? null : Tokens.closeCurlyBracket(),
    );
  }

  InterpolationString _readInterpolationString() {
    var lexeme = _readStringReference();
    var value = _readStringReference();
    return InterpolationStringImpl(
      contents: TokenFactory.tokenFromString(lexeme),
      value: value,
    );
  }

  void _readInvocationExpression(InvocationExpressionImpl node) {
    node.staticInvokeType = _reader.readType();
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    _readExpressionResolution(node);
  }

  IsExpression _readIsExpression() {
    var flags = _readByte();
    var expression = readNode() as ExpressionImpl;
    var type = readNode() as TypeAnnotationImpl;
    var node = IsExpressionImpl(
      expression: expression,
      isOperator: Tokens.is_(),
      notOperator: AstBinaryFlags.hasNot(flags) ? Tokens.bang() : null,
      type: type,
    );
    _readExpressionResolution(node);
    return node;
  }

  ListLiteral _readListLiteral() {
    var flags = _readByte();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var elements = _readNodeList<CollectionElementImpl>();

    var node = ListLiteralImpl(
      constKeyword: AstBinaryFlags.isConst(flags) ? Tokens.const_() : null,
      typeArguments: typeArguments,
      leftBracket: Tokens.openSquareBracket(),
      elements: elements,
      rightBracket: Tokens.closeSquareBracket(),
    );
    _readExpressionResolution(node);
    return node;
  }

  MapLiteralEntry _readMapLiteralEntry() {
    var key = readNode() as ExpressionImpl;
    var value = readNode() as ExpressionImpl;
    return MapLiteralEntryImpl(
      key: key,
      separator: Tokens.colon(),
      value: value,
    );
  }

  MethodInvocation _readMethodInvocation() {
    var flags = _readByte();
    var target = _readOptionalNode() as ExpressionImpl?;
    var methodName = readNode() as SimpleIdentifierImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = readNode() as ArgumentListImpl;

    Token? operator;
    if (AstBinaryFlags.hasQuestion(flags)) {
      operator = AstBinaryFlags.hasPeriod(flags)
          ? Tokens.questionPeriod()
          : Tokens.questionPeriodPeriod();
    } else if (AstBinaryFlags.hasPeriod(flags)) {
      operator = Tokens.period();
    } else if (AstBinaryFlags.hasPeriod2(flags)) {
      operator = Tokens.periodPeriod();
    }

    var node = MethodInvocationImpl(
      target: target,
      operator: operator,
      methodName: methodName,
      typeArguments: typeArguments,
      argumentList: arguments,
    );
    _readInvocationExpression(node);
    return node;
  }

  NamedExpression _readNamedExpression() {
    var name = _readStringReference();
    var nameNode = LabelImpl(
      label: astFactory.simpleIdentifier(
        StringToken(TokenType.STRING, name, -1),
      ),
      colon: Tokens.colon(),
    );
    var expression = readNode() as ExpressionImpl;
    var node = NamedExpressionImpl(
      name: nameNode,
      expression: expression,
    );
    node.staticType = expression.staticType;
    return node;
  }

  NamedType _readNamedType() {
    var flags = _readByte();
    var name = readNode() as IdentifierImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;

    var node = NamedTypeImpl(
      name: name,
      typeArguments: typeArguments,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
    );
    node.type = _reader.readType();
    return node;
  }

  List<T> _readNodeList<T>() {
    var length = _reader.readUInt30();
    return List.generate(length, (_) => readNode() as T);
  }

  NullLiteral _readNullLiteral() {
    final node = NullLiteralImpl(
      literal: Tokens.null_(),
    );
    _readExpressionResolution(node);
    return node;
  }

  AstNode? _readOptionalNode() {
    if (_readOptionTag()) {
      return readNode();
    } else {
      return null;
    }
  }

  bool _readOptionTag() {
    var tag = _readByte();
    if (tag == Tag.Nothing) {
      return false;
    } else if (tag == Tag.Something) {
      return true;
    } else {
      throw UnimplementedError('Unexpected option tag: $tag');
    }
  }

  ParenthesizedExpression _readParenthesizedExpression() {
    var expression = readNode() as ExpressionImpl;
    var node = ParenthesizedExpressionImpl(
      leftParenthesis: Tokens.openParenthesis(),
      expression: expression,
      rightParenthesis: Tokens.closeParenthesis(),
    );
    _readExpressionResolution(node);
    return node;
  }

  PostfixExpression _readPostfixExpression() {
    var operand = readNode() as ExpressionImpl;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var node = PostfixExpressionImpl(
      operand: operand,
      operator: Tokens.fromType(operatorType),
    );
    node.staticElement = _reader.readElement() as MethodElement?;
    if (node.operator.type.isIncrementOperator) {
      node.readElement = _reader.readElement();
      node.readType = _reader.readType();
      node.writeElement = _reader.readElement();
      node.writeType = _reader.readType();
    }
    _readExpressionResolution(node);
    return node;
  }

  PrefixedIdentifier _readPrefixedIdentifier() {
    var prefix = readNode() as SimpleIdentifierImpl;
    var identifier = readNode() as SimpleIdentifierImpl;
    var node = PrefixedIdentifierImpl(
      prefix: prefix,
      period: Tokens.period(),
      identifier: identifier,
    );
    _readExpressionResolution(node);
    return node;
  }

  PrefixExpression _readPrefixExpression() {
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var operand = readNode() as ExpressionImpl;
    var node = PrefixExpressionImpl(
      operator: Tokens.fromType(operatorType),
      operand: operand,
    );
    node.staticElement = _reader.readElement() as MethodElement?;
    if (node.operator.type.isIncrementOperator) {
      node.readElement = _reader.readElement();
      node.readType = _reader.readType();
      node.writeElement = _reader.readElement();
      node.writeType = _reader.readType();
    }
    _readExpressionResolution(node);
    return node;
  }

  PropertyAccess _readPropertyAccess() {
    var flags = _readByte();
    var target = _readOptionalNode() as ExpressionImpl?;
    var propertyName = readNode() as SimpleIdentifierImpl;

    Token operator;
    if (AstBinaryFlags.hasQuestion(flags)) {
      operator = AstBinaryFlags.hasPeriod(flags)
          ? Tokens.questionPeriod()
          : Tokens.questionPeriodPeriod();
    } else {
      operator = AstBinaryFlags.hasPeriod(flags)
          ? Tokens.period()
          : Tokens.periodPeriod();
    }

    var node = PropertyAccessImpl(
      target: target,
      operator: operator,
      propertyName: propertyName,
    );
    _readExpressionResolution(node);
    return node;
  }

  RecordLiteralImpl _readRecordLiteral() {
    var flags = _readByte();
    var fields = _readNodeList<ExpressionImpl>();
    var node = RecordLiteralImpl(
      constKeyword: AstBinaryFlags.isConst(flags) ? Tokens.const_() : null,
      leftParenthesis: Tokens.openParenthesis(),
      fields: fields,
      rightParenthesis: Tokens.closeParenthesis(),
    );
    _readExpressionResolution(node);
    return node;
  }

  RedirectingConstructorInvocation _readRedirectingConstructorInvocation() {
    var constructorName = _readOptionalNode() as SimpleIdentifierImpl?;
    var argumentList = readNode() as ArgumentListImpl;
    var node = RedirectingConstructorInvocationImpl(
      thisKeyword: Tokens.this_(),
      period: constructorName != null ? Tokens.period() : null,
      constructorName: constructorName,
      argumentList: argumentList,
    );
    node.staticElement = _reader.readElement() as ConstructorElement?;
    _resolveNamedExpressions(node.staticElement, node.argumentList);
    return node;
  }

  SetOrMapLiteral _readSetOrMapLiteral() {
    var flags = _readByte();
    var isMapOrSetBits = _readByte();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var elements = _readNodeList<CollectionElementImpl>();
    var node = SetOrMapLiteralImpl(
      constKeyword: AstBinaryFlags.isConst(flags) ? Tokens.const_() : null,
      elements: elements,
      leftBracket: Tokens.openCurlyBracket(),
      typeArguments: typeArguments,
      rightBracket: Tokens.closeCurlyBracket(),
    );

    const isMapBit = 1 << 0;
    const isSetBit = 1 << 1;
    if ((isMapOrSetBits & isMapBit) != 0) {
      node.becomeMap();
    } else if ((isMapOrSetBits & isSetBit) != 0) {
      node.becomeSet();
    }

    _readExpressionResolution(node);
    return node;
  }

  SimpleFormalParameter _readSimpleFormalParameter() {
    var type = _readOptionalNode() as TypeAnnotationImpl?;
    var flags = _readByte();
    var metadata = _readNodeList<AnnotationImpl>();
    var name = AstBinaryFlags.hasName(flags) ? _readDeclarationName() : null;

    var node = SimpleFormalParameterImpl(
      name: name,
      type: type,
      covariantKeyword:
          AstBinaryFlags.isCovariant(flags) ? Tokens.covariant_() : null,
      comment: null,
      metadata: metadata,
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.isVar(flags),
        Tokens.var_(),
      ),
      requiredKeyword:
          AstBinaryFlags.isRequired(flags) ? Tokens.required_() : null,
    );
    var actualType = _reader.readRequiredType();
    _reader.readByte(); // TODO(scheglov) inherits covariant

    var element = ParameterElementImpl(
      name: name?.lexeme ?? '',
      nameOffset: -1,
      parameterKind: node.kind,
    );
    element.type = actualType;
    node.declaredElement = element;

    return node;
  }

  SimpleIdentifier _readSimpleIdentifier() {
    var name = _readStringReference();
    var node = astFactory.simpleIdentifier(
      StringToken(TokenType.STRING, name, -1),
    );
    node.staticElement = _reader.readElement();
    node.tearOffTypeArgumentTypes = _reader.readOptionalTypeList();
    _readExpressionResolution(node);
    return node;
  }

  SimpleStringLiteral _readSimpleStringLiteral() {
    var lexeme = _readStringReference();
    var value = _readStringReference();

    var node = SimpleStringLiteralImpl(
      literal: TokenFactory.tokenFromString(lexeme),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  SpreadElement _readSpreadElement() {
    var flags = _readByte();
    var expression = readNode() as ExpressionImpl;
    return SpreadElementImpl(
      spreadOperator: AstBinaryFlags.hasQuestion(flags)
          ? Tokens.periodPeriodPeriodQuestion()
          : Tokens.periodPeriodPeriod(),
      expression: expression,
    );
  }

  StringInterpolation _readStringInterpolation() {
    var elements = _readNodeList<InterpolationElementImpl>();
    var node = StringInterpolationImpl(
      elements: elements,
    );
    _readExpressionResolution(node);
    return node;
  }

  String _readStringReference() {
    return _reader.readStringReference();
  }

  SuperConstructorInvocation _readSuperConstructorInvocation() {
    var constructorName = _readOptionalNode() as SimpleIdentifierImpl?;
    var argumentList = readNode() as ArgumentListImpl;
    var node = SuperConstructorInvocationImpl(
      superKeyword: Tokens.super_(),
      period: constructorName != null ? Tokens.period() : null,
      constructorName: constructorName,
      argumentList: argumentList,
    );
    node.staticElement = _reader.readElement() as ConstructorElement?;
    _resolveNamedExpressions(node.staticElement, node.argumentList);
    return node;
  }

  SuperExpression _readSuperExpression() {
    var node = SuperExpressionImpl(
      superKeyword: Tokens.super_(),
    );
    _readExpressionResolution(node);
    return node;
  }

  SymbolLiteral _readSymbolLiteral() {
    var components = _reader
        .readStringReferenceList()
        .map(TokenFactory.tokenFromString)
        .toList();
    var node = SymbolLiteralImpl(
      poundSign: Tokens.hash(),
      components: components,
    );
    _readExpressionResolution(node);
    return node;
  }

  ThisExpression _readThisExpression() {
    var node = ThisExpressionImpl(
      thisKeyword: Tokens.this_(),
    );
    _readExpressionResolution(node);
    return node;
  }

  ThrowExpression _readThrowExpression() {
    var expression = readNode() as ExpressionImpl;
    var node = ThrowExpressionImpl(
      throwKeyword: Tokens.throw_(),
      expression: expression,
    );
    _readExpressionResolution(node);
    return node;
  }

  TypeArgumentList _readTypeArgumentList() {
    var arguments = _readNodeList<TypeAnnotationImpl>();
    return TypeArgumentListImpl(
      leftBracket: Tokens.lt(),
      arguments: arguments,
      rightBracket: Tokens.gt(),
    );
  }

  TypeLiteral _readTypeLiteral() {
    var typeName = readNode() as NamedTypeImpl;
    var node = TypeLiteralImpl(
      typeName: typeName,
    );
    _readExpressionResolution(node);
    return node;
  }

  TypeParameter _readTypeParameter() {
    var name = _readDeclarationName();
    var bound = _readOptionalNode() as TypeAnnotationImpl?;
    var metadata = _readNodeList<AnnotationImpl>();

    var node = TypeParameterImpl(
      comment: null,
      metadata: metadata,
      name: name,
      extendsKeyword: bound != null ? Tokens.extends_() : null,
      bound: bound,
    );

    return node;
  }

  TypeParameterList _readTypeParameterList() {
    var typeParameters = _readNodeList<TypeParameterImpl>();
    return TypeParameterListImpl(
      leftBracket: Tokens.lt(),
      typeParameters: typeParameters,
      rightBracket: Tokens.gt(),
    );
  }

  int _readUInt32() {
    return _reader.readUInt32();
  }

  VariableDeclaration _readVariableDeclaration() {
    var flags = _readByte();
    var name = _readDeclarationName();
    var initializer = _readOptionalNode() as ExpressionImpl?;

    var node = VariableDeclarationImpl(
      name: name,
      equals: Tokens.eq(),
      initializer: initializer,
    );

    node.hasInitializer = AstBinaryFlags.hasInitializer(flags);

    return node;
  }

  VariableDeclarationList _readVariableDeclarationList() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotationImpl?;
    var variables = _readNodeList<VariableDeclarationImpl>();
    var metadata = _readNodeList<AnnotationImpl>();

    return VariableDeclarationListImpl(
      comment: null,
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.isVar(flags),
        Tokens.var_(),
      ),
      lateKeyword: AstBinaryFlags.isLate(flags) ? Tokens.late_() : null,
      metadata: metadata,
      type: type,
      variables: variables,
    );
  }

  void _resolveNamedExpressions(
    Element? executable,
    ArgumentList argumentList,
  ) {
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpressionImpl) {
        var nameNode = argument.name.label;
        if (executable is ExecutableElement) {
          var parameters = executable.parameters;
          var name = nameNode.name;
          nameNode.staticElement = parameters.firstWhereOrNull((e) {
            return e.name == name;
          });
        }
      }
    }
  }
}
