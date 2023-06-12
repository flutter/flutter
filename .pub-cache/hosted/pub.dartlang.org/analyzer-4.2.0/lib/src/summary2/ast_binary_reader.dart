// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
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
      case Tag.MixinDeclaration:
        return _readMixinDeclaration();
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
    var node = astFactory.integerLiteral(
      TokenFactory.tokenFromTypeAndString(TokenType.INT, lexeme),
      value,
    );
    _readExpressionResolution(node);
    return node;
  }

  AdjacentStrings _readAdjacentStrings() {
    var components = _readNodeList<StringLiteral>();
    var node = AdjacentStringsImpl(strings: components);
    _readExpressionResolution(node);
    return node;
  }

  Annotation _readAnnotation() {
    var name = readNode() as Identifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var constructorName = _readOptionalNode() as SimpleIdentifier?;
    var arguments = _readOptionalNode() as ArgumentList?;
    var node = astFactory.annotation(
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
    var arguments = _readNodeList<Expression>();

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
    var node = AstTestFactory.booleanLiteral(value);
    _readExpressionResolution(node);
    return node;
  }

  int _readByte() {
    return _reader.readByte();
  }

  CascadeExpression _readCascadeExpression() {
    var target = readNode() as Expression;
    var sections = _readNodeList<Expression>();
    var node = astFactory.cascadeExpression(target, sections);
    node.staticType = target.staticType;
    return node;
  }

  ConditionalExpression _readConditionalExpression() {
    var condition = readNode() as Expression;
    var thenExpression = readNode() as Expression;
    var elseExpression = readNode() as Expression;
    var node = astFactory.conditionalExpression(
      condition,
      Tokens.question(),
      thenExpression,
      Tokens.colon(),
      elseExpression,
    );
    _readExpressionResolution(node);
    return node;
  }

  ConstructorFieldInitializer _readConstructorFieldInitializer() {
    var flags = _readByte();
    var fieldName = readNode() as SimpleIdentifier;
    var expression = readNode() as Expression;
    var hasThis = AstBinaryFlags.hasThis(flags);
    return astFactory.constructorFieldInitializer(
      hasThis ? Tokens.this_() : null,
      hasThis ? Tokens.period() : null,
      fieldName,
      Tokens.eq(),
      expression,
    );
  }

  ConstructorName _readConstructorName() {
    var type = readNode() as NamedType;
    var name = _readOptionalNode() as SimpleIdentifier?;

    var node = astFactory.constructorName(
      type,
      name != null ? Tokens.period() : null,
      name,
    );
    node.staticElement = _reader.readElement() as ConstructorElement?;
    return node;
  }

  ConstructorReference _readConstructorReference() {
    var constructorName = readNode() as ConstructorName;
    var node = astFactory.constructorReference(
      constructorName: constructorName,
    );
    _readExpressionResolution(node);
    return node;
  }

  SimpleIdentifierImpl _readDeclarationName() {
    var name = _reader.readStringReference();
    return astFactory.simpleIdentifier(
      StringToken(TokenType.STRING, name, -1),
    );
  }

  DeclaredIdentifier _readDeclaredIdentifier() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotation?;
    var identifier = _readDeclarationName();
    var metadata = _readNodeList<Annotation>();
    return astFactory.declaredIdentifier(
      null,
      metadata,
      Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.isVar(flags),
        Tokens.var_(),
      ),
      type,
      identifier,
    );
  }

  DefaultFormalParameter _readDefaultFormalParameter() {
    var flags = _readByte();
    var parameter = readNode() as NormalFormalParameter;
    var defaultValue = _readOptionalNode() as Expression?;

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

    var node = astFactory.defaultFormalParameter(
      parameter,
      kind,
      AstBinaryFlags.hasInitializer(flags) ? Tokens.colon() : null,
      defaultValue,
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
    node.identifier?.staticElement = element;
    element.type = nonDefaultElement.type;

    return node;
  }

  DottedName _readDottedName() {
    var components = _readNodeList<SimpleIdentifier>();
    return astFactory.dottedName(components);
  }

  DoubleLiteral _readDoubleLiteral() {
    var value = _reader.readDouble();
    var node = AstTestFactory.doubleLiteral(value);
    _readExpressionResolution(node);
    return node;
  }

  void _readExpressionResolution(ExpressionImpl node) {
    node.staticType = _reader.readType();
  }

  ExtensionOverride _readExtensionOverride() {
    var extensionName = readNode() as Identifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var argumentList = readNode() as ArgumentList;
    var node = astFactory.extensionOverride(
      extensionName: extensionName,
      argumentList: argumentList,
      typeArguments: typeArguments,
    );
    _readExpressionResolution(node);
    return node;
  }

  FieldFormalParameter _readFieldFormalParameter() {
    var typeParameters = _readOptionalNode() as TypeParameterList?;
    var type = _readOptionalNode() as TypeAnnotation?;
    var formalParameters = _readOptionalNode() as FormalParameterList?;
    var flags = _readByte();
    var metadata = _readNodeList<Annotation>();
    var identifier = readNode() as SimpleIdentifier;
    var node = astFactory.fieldFormalParameter2(
      identifier: identifier,
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
    var loopVariable = readNode() as DeclaredIdentifier;
    var iterable = readNode() as Expression;
    return astFactory.forEachPartsWithDeclaration(
      inKeyword: Tokens.in_(),
      iterable: iterable,
      loopVariable: loopVariable,
    );
  }

  ForElement _readForElement() {
    var flags = _readByte();
    var forLoopParts = readNode() as ForLoopParts;
    var body = readNode() as CollectionElement;
    return astFactory.forElement(
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
    var parameters = _readNodeList<FormalParameter>();

    return astFactory.formalParameterList(
      Tokens.openParenthesis(),
      parameters,
      Tokens.choose(
        AstBinaryFlags.isDelimiterCurly(flags),
        Tokens.openCurlyBracket(),
        AstBinaryFlags.isDelimiterSquare(flags),
        Tokens.openSquareBracket(),
      ),
      Tokens.choose(
        AstBinaryFlags.isDelimiterCurly(flags),
        Tokens.closeCurlyBracket(),
        AstBinaryFlags.isDelimiterSquare(flags),
        Tokens.closeSquareBracket(),
      ),
      Tokens.closeParenthesis(),
    );
  }

  ForPartsWithDeclarations _readForPartsWithDeclarations() {
    var variables = readNode() as VariableDeclarationList;
    var condition = _readOptionalNode() as Expression?;
    var updaters = _readNodeList<Expression>();
    return astFactory.forPartsWithDeclarations(
      condition: condition,
      leftSeparator: Tokens.semicolon(),
      rightSeparator: Tokens.semicolon(),
      updaters: updaters,
      variables: variables,
    );
  }

  ForPartsWithExpression _readForPartsWithExpression() {
    var initialization = _readOptionalNode() as Expression?;
    var condition = _readOptionalNode() as Expression?;
    var updaters = _readNodeList<Expression>();
    return astFactory.forPartsWithExpression(
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
    var function = readNode() as Expression;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var arguments = readNode() as ArgumentList;
    var node = astFactory.functionExpressionInvocation(
      function,
      typeArguments,
      arguments,
    );
    _readInvocationExpression(node);
    return node;
  }

  FunctionReference _readFunctionReference() {
    var function = readNode() as Expression;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;

    var node = astFactory.functionReference(
      function: function,
      typeArguments: typeArguments,
    );
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    _readExpressionResolution(node);
    return node;
  }

  FunctionTypedFormalParameter _readFunctionTypedFormalParameter() {
    var typeParameters = _readOptionalNode() as TypeParameterList?;
    var returnType = _readOptionalNode() as TypeAnnotation?;
    var formalParameters = readNode() as FormalParameterList;
    var flags = _readByte();
    var metadata = _readNodeList<Annotation>();
    var identifier = readNode() as SimpleIdentifier;
    var node = astFactory.functionTypedFormalParameter2(
      comment: null,
      covariantKeyword:
          AstBinaryFlags.isCovariant(flags) ? Tokens.covariant_() : null,
      identifier: identifier,
      metadata: metadata,
      parameters: formalParameters,
      requiredKeyword:
          AstBinaryFlags.isRequired(flags) ? Tokens.required_() : null,
      returnType: returnType,
      typeParameters: typeParameters,
    );
    return node;
  }

  GenericFunctionType _readGenericFunctionType() {
    var flags = _readByte();
    // TODO(scheglov) add type parameters to locals
    var typeParameters = _readOptionalNode() as TypeParameterList?;
    var returnType = _readOptionalNode() as TypeAnnotation?;
    var formalParameters = readNode() as FormalParameterList;
    var node = astFactory.genericFunctionType(
      returnType,
      Tokens.function(),
      typeParameters,
      formalParameters,
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
    var condition = readNode() as Expression;
    var thenElement = readNode() as CollectionElement;
    var elseElement = _readOptionalNode() as CollectionElement?;
    return astFactory.ifElement(
      condition: condition,
      elseElement: elseElement,
      elseKeyword: elseElement != null ? Tokens.else_() : null,
      ifKeyword: Tokens.if_(),
      leftParenthesis: Tokens.openParenthesis(),
      rightParenthesis: Tokens.closeParenthesis(),
      thenElement: thenElement,
    );
  }

  ImplicitCallReference _readImplicitCallReference() {
    var expression = readNode() as Expression;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var typeArgumentTypes = _reader.readOptionalTypeList()!;
    var staticElement = _reader.readElement() as MethodElement;

    var node = astFactory.implicitCallReference(
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
    var target = _readOptionalNode() as Expression?;
    var index = readNode() as Expression;
    // TODO(scheglov) Is this clumsy?
    IndexExpressionImpl node;
    if (target != null) {
      node = (astFactory.indexExpressionForTarget2(
        target: target,
        question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
        leftBracket: Tokens.openSquareBracket(),
        index: index,
        rightBracket: Tokens.closeSquareBracket(),
      ))
        ..period =
            AstBinaryFlags.hasPeriod(flags) ? Tokens.periodPeriod() : null;
    } else {
      node = astFactory.indexExpressionForCascade2(
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
    var constructorName = readNode() as ConstructorName;
    var argumentList = readNode() as ArgumentList;

    var node = astFactory.instanceCreationExpression(
      Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isNew(flags),
        Tokens.new_(),
      ),
      constructorName,
      argumentList,
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
    var node = astFactory.integerLiteral(
      TokenFactory.tokenFromTypeAndString(TokenType.INT, lexeme),
      null,
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
    var expression = readNode() as Expression;
    var isIdentifier = AstBinaryFlags.isStringInterpolationIdentifier(flags);
    return astFactory.interpolationExpression(
      isIdentifier
          ? Tokens.openCurlyBracket()
          : Tokens.stringInterpolationExpression(),
      expression,
      isIdentifier ? null : Tokens.closeCurlyBracket(),
    );
  }

  InterpolationString _readInterpolationString() {
    var lexeme = _readStringReference();
    var value = _readStringReference();
    return astFactory.interpolationString(
      TokenFactory.tokenFromString(lexeme),
      value,
    );
  }

  void _readInvocationExpression(InvocationExpressionImpl node) {
    node.staticInvokeType = _reader.readType();
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    _readExpressionResolution(node);
  }

  IsExpression _readIsExpression() {
    var flags = _readByte();
    var expression = readNode() as Expression;
    var type = readNode() as TypeAnnotation;
    var node = astFactory.isExpression(
      expression,
      Tokens.is_(),
      AstBinaryFlags.hasNot(flags) ? Tokens.bang() : null,
      type,
    );
    _readExpressionResolution(node);
    return node;
  }

  ListLiteral _readListLiteral() {
    var flags = _readByte();
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var elements = _readNodeList<CollectionElement>();

    var node = astFactory.listLiteral(
      AstBinaryFlags.isConst(flags) ? Tokens.const_() : null,
      typeArguments,
      Tokens.openSquareBracket(),
      elements,
      Tokens.closeSquareBracket(),
    );
    _readExpressionResolution(node);
    return node;
  }

  MapLiteralEntry _readMapLiteralEntry() {
    var key = readNode() as Expression;
    var value = readNode() as Expression;
    return astFactory.mapLiteralEntry(key, Tokens.colon(), value);
  }

  MethodInvocation _readMethodInvocation() {
    var flags = _readByte();
    var target = _readOptionalNode() as Expression?;
    var methodName = readNode() as SimpleIdentifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var arguments = readNode() as ArgumentList;

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

    var node = astFactory.methodInvocation(
      target,
      operator,
      methodName,
      typeArguments,
      arguments,
    );
    _readInvocationExpression(node);
    return node;
  }

  MixinDeclaration _readMixinDeclaration() {
    var typeParameters = _readOptionalNode() as TypeParameterList?;
    var onClause = _readOptionalNode() as OnClause?;
    var implementsClause = _readOptionalNode() as ImplementsClause?;
    var name = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.mixinDeclaration(
      null,
      metadata,
      null,
      Tokens.mixin_(),
      name,
      typeParameters,
      onClause,
      implementsClause,
      Tokens.openCurlyBracket(),
      const <ClassMember>[],
      Tokens.closeCurlyBracket(),
    );

    return node;
  }

  NamedExpression _readNamedExpression() {
    var name = _readStringReference();
    var nameNode = astFactory.label(
      astFactory.simpleIdentifier(
        StringToken(TokenType.STRING, name, -1),
      ),
      Tokens.colon(),
    );
    var expression = readNode() as Expression;
    var node = astFactory.namedExpression(nameNode, expression);
    node.staticType = expression.staticType;
    return node;
  }

  NamedType _readNamedType() {
    var flags = _readByte();
    var name = readNode() as Identifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;

    var node = astFactory.namedType(
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
    var node = astFactory.nullLiteral(
      Tokens.null_(),
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
    var expression = readNode() as Expression;
    var node = astFactory.parenthesizedExpression(
      Tokens.openParenthesis(),
      expression,
      Tokens.closeParenthesis(),
    );
    _readExpressionResolution(node);
    return node;
  }

  PostfixExpression _readPostfixExpression() {
    var operand = readNode() as Expression;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var node = astFactory.postfixExpression(
      operand,
      Tokens.fromType(operatorType),
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
    var prefix = readNode() as SimpleIdentifier;
    var identifier = readNode() as SimpleIdentifier;
    var node = astFactory.prefixedIdentifier(
      prefix,
      Tokens.period(),
      identifier,
    );
    _readExpressionResolution(node);
    return node;
  }

  PrefixExpression _readPrefixExpression() {
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var operand = readNode() as Expression;
    var node = astFactory.prefixExpression(
      Tokens.fromType(operatorType),
      operand,
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
    var target = _readOptionalNode() as Expression?;
    var propertyName = readNode() as SimpleIdentifier;

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

    var node = astFactory.propertyAccess(target, operator, propertyName);
    _readExpressionResolution(node);
    return node;
  }

  RedirectingConstructorInvocation _readRedirectingConstructorInvocation() {
    var constructorName = _readOptionalNode() as SimpleIdentifier?;
    var argumentList = readNode() as ArgumentList;
    var node = astFactory.redirectingConstructorInvocation(
      Tokens.this_(),
      constructorName != null ? Tokens.period() : null,
      constructorName,
      argumentList,
    );
    node.staticElement = _reader.readElement() as ConstructorElement?;
    _resolveNamedExpressions(node.staticElement, node.argumentList);
    return node;
  }

  SetOrMapLiteral _readSetOrMapLiteral() {
    var flags = _readByte();
    var isMapOrSetBits = _readByte();
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var elements = _readNodeList<CollectionElement>();
    var node = astFactory.setOrMapLiteral(
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
    var type = _readOptionalNode() as TypeAnnotation?;
    var flags = _readByte();
    var metadata = _readNodeList<Annotation>();
    var identifier =
        AstBinaryFlags.hasName(flags) ? _readDeclarationName() : null;

    var node = astFactory.simpleFormalParameter2(
      identifier: identifier,
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
      name: identifier?.name ?? '',
      nameOffset: -1,
      parameterKind: node.kind,
    );
    element.type = actualType;
    node.declaredElement = element;
    identifier?.staticElement = element;

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

    var node = astFactory.simpleStringLiteral(
      TokenFactory.tokenFromString(lexeme),
      value,
    );
    _readExpressionResolution(node);
    return node;
  }

  SpreadElement _readSpreadElement() {
    var flags = _readByte();
    var expression = readNode() as Expression;
    return astFactory.spreadElement(
      spreadOperator: AstBinaryFlags.hasQuestion(flags)
          ? Tokens.periodPeriodPeriodQuestion()
          : Tokens.periodPeriodPeriod(),
      expression: expression,
    );
  }

  StringInterpolation _readStringInterpolation() {
    var elements = _readNodeList<InterpolationElement>();
    var node = astFactory.stringInterpolation(elements);
    _readExpressionResolution(node);
    return node;
  }

  String _readStringReference() {
    return _reader.readStringReference();
  }

  SuperConstructorInvocation _readSuperConstructorInvocation() {
    var constructorName = _readOptionalNode() as SimpleIdentifier?;
    var argumentList = readNode() as ArgumentList;
    var node = astFactory.superConstructorInvocation(
      Tokens.super_(),
      constructorName != null ? Tokens.period() : null,
      constructorName,
      argumentList,
    );
    node.staticElement = _reader.readElement() as ConstructorElement?;
    _resolveNamedExpressions(node.staticElement, node.argumentList);
    return node;
  }

  SuperExpression _readSuperExpression() {
    var node = astFactory.superExpression(Tokens.super_());
    _readExpressionResolution(node);
    return node;
  }

  SymbolLiteral _readSymbolLiteral() {
    var components = _reader
        .readStringReferenceList()
        .map(TokenFactory.tokenFromString)
        .toList();
    var node = astFactory.symbolLiteral(Tokens.hash(), components);
    _readExpressionResolution(node);
    return node;
  }

  ThisExpression _readThisExpression() {
    var node = astFactory.thisExpression(Tokens.this_());
    _readExpressionResolution(node);
    return node;
  }

  ThrowExpression _readThrowExpression() {
    var expression = readNode() as Expression;
    var node = astFactory.throwExpression(Tokens.throw_(), expression);
    _readExpressionResolution(node);
    return node;
  }

  TypeArgumentList _readTypeArgumentList() {
    var arguments = _readNodeList<TypeAnnotation>();
    return astFactory.typeArgumentList(Tokens.lt(), arguments, Tokens.gt());
  }

  TypeLiteral _readTypeLiteral() {
    var typeName = readNode() as NamedType;
    var node = astFactory.typeLiteral(typeName: typeName);
    _readExpressionResolution(node);
    return node;
  }

  TypeParameter _readTypeParameter() {
    var name = _readDeclarationName();
    var bound = _readOptionalNode() as TypeAnnotation?;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.typeParameter(
      null,
      metadata,
      name,
      bound != null ? Tokens.extends_() : null,
      bound,
    );

    return node;
  }

  TypeParameterList _readTypeParameterList() {
    var typeParameters = _readNodeList<TypeParameter>();
    return astFactory.typeParameterList(
      Tokens.lt(),
      typeParameters,
      Tokens.gt(),
    );
  }

  int _readUInt32() {
    return _reader.readUInt32();
  }

  VariableDeclaration _readVariableDeclaration() {
    var flags = _readByte();
    var name = readNode() as SimpleIdentifier;
    var initializer = _readOptionalNode() as Expression?;

    var node = astFactory.variableDeclaration(
      name,
      Tokens.eq(),
      initializer,
    );

    node.hasInitializer = AstBinaryFlags.hasInitializer(flags);

    return node;
  }

  VariableDeclarationList _readVariableDeclarationList() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotation?;
    var variables = _readNodeList<VariableDeclaration>();
    var metadata = _readNodeList<Annotation>();

    return astFactory.variableDeclarationList2(
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
