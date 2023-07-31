// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/bundle_writer.dart';
import 'package:analyzer/src/summary2/tokens_writer.dart';

/// Serializer of fully resolved ASTs.
class AstBinaryWriter extends ThrowingAstVisitor<void> {
  final ResolutionSink _sink;
  final StringIndexer _stringIndexer;

  AstBinaryWriter({
    required ResolutionSink sink,
    required StringIndexer stringIndexer,
  })  : _sink = sink,
        _stringIndexer = stringIndexer;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _writeByte(Tag.AdjacentStrings);
    _writeNodeList(node.strings);
    _storeExpression(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    _writeByte(Tag.Annotation);

    _writeNode(node.name);
    _writeOptionalNode(node.typeArguments);
    _writeOptionalNode(node.constructorName);

    var arguments = node.arguments;
    if (arguments != null) {
      if (!arguments.arguments.every(_isSerializableExpression)) {
        arguments = null;
      }
    }
    _writeOptionalNode(arguments);

    _sink.writeElement(node.element);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _writeByte(Tag.ArgumentList);
    _writeNodeList(node.arguments);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _writeByte(Tag.AsExpression);

    _writeNode(node.expression);

    _writeNode(node.type);

    _storeExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _writeByte(Tag.AssertInitializer);
    _writeNode(node.condition);
    _writeOptionalNode(node.message);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _writeByte(Tag.AssignmentExpression);

    _writeNode(node.leftHandSide);
    _writeNode(node.rightHandSide);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    _sink.writeElement(node.staticElement);
    _sink.writeElement(node.readElement);
    _sink.writeType(node.readType);
    _sink.writeElement(node.writeElement);
    _sink.writeType(node.writeType);
    _storeExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _writeByte(Tag.AwaitExpression);

    _writeNode(node.expression);

    _storeExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _writeByte(Tag.BinaryExpression);

    _writeNode(node.leftOperand);
    _writeNode(node.rightOperand);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    _sink.writeElement(node.staticElement);
    _sink.writeType(node.staticInvokeType);
    _storeExpression(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _writeByte(Tag.BooleanLiteral);
    _writeByte(node.value ? 1 : 0);
    _storeExpression(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _writeByte(Tag.CascadeExpression);
    _writeNode(node.target);
    _writeNodeList(node.cascadeSections);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _writeByte(Tag.ConditionalExpression);
    _writeNode(node.condition);
    _writeNode(node.thenExpression);
    _writeNode(node.elseExpression);
    _storeExpression(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _writeByte(Tag.ConstructorFieldInitializer);

    _writeByte(
      AstBinaryFlags.encode(
        hasThis: node.thisKeyword != null,
      ),
    );

    _writeNode(node.fieldName);
    _writeNode(node.expression);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _writeByte(Tag.ConstructorName);

    // When we parse `C() = A.named` we don't know that `A` is a class name.
    // We parse it as a `TypeName(PrefixedIdentifier)`.
    // But when we resolve, we rewrite it.
    // We need to inform the applier about the right shape of the AST.
    // _sink.writeByte(node.name != null ? 1 : 0);

    _writeNode(node.type);
    _writeOptionalNode(node.name);

    _sink.writeElement(node.staticElement);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _writeByte(Tag.ConstructorReference);
    _writeNode(node.constructorName);
    _storeExpression(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _writeByte(Tag.DeclaredIdentifier);
    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.keyword?.keyword == Keyword.CONST,
        isFinal: node.keyword?.keyword == Keyword.FINAL,
        isVar: node.keyword?.keyword == Keyword.VAR,
      ),
    );
    _writeOptionalNode(node.type);
    _writeDeclarationName(node.name);
    _storeDeclaration(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _writeByte(Tag.DefaultFormalParameter);

    _writeByte(
      AstBinaryFlags.encode(
        hasInitializer: node.defaultValue != null,
        isPositional: node.isPositional,
        isRequired: node.isRequired,
      ),
    );

    _writeNode(node.parameter);

    var defaultValue = node.defaultValue;
    if (!_isSerializableExpression(defaultValue)) {
      defaultValue = null;
    }
    _writeOptionalNode(defaultValue);
  }

  @override
  void visitDottedName(DottedName node) {
    _writeByte(Tag.DottedName);
    _writeNodeList(node.components);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _writeByte(Tag.DoubleLiteral);
    _writeDouble(node.value);
    _storeExpression(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _writeByte(Tag.ExtensionOverride);

    _writeNode(node.extensionName);
    _writeOptionalNode(node.typeArguments);
    _writeNode(node.argumentList);

    _sink.writeType(node.extendedType);

    // TODO(scheglov) typeArgumentTypes?
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _writeByte(Tag.FieldFormalParameter);

    _withTypeParameters(node.typeParameters, () {
      _writeOptionalNode(node.typeParameters);
      _writeOptionalNode(node.type);
      _writeOptionalNode(node.parameters);
      _storeNormalFormalParameter(
        node,
        node.keyword,
        hasQuestion: node.question != null,
      );
    });
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _writeByte(Tag.ForEachPartsWithDeclaration);
    _writeNode(node.loopVariable);
    _storeForEachParts(node);
  }

  @override
  void visitForElement(ForElement node) {
    _writeNotSerializableExpression();
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _writeByte(Tag.FormalParameterList);

    var leftDelimiter = node.leftDelimiter?.type;
    _writeByte(
      AstBinaryFlags.encode(
        isDelimiterCurly: leftDelimiter == TokenType.OPEN_CURLY_BRACKET,
        isDelimiterSquare: leftDelimiter == TokenType.OPEN_SQUARE_BRACKET,
      ),
    );

    _writeNodeList(node.parameters);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _writeByte(Tag.ForPartsWithDeclarations);
    _writeNode(node.variables);
    _storeForParts(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _writeByte(Tag.ForPartsWithExpression);
    _writeOptionalNode(node.initialization);
    _storeForParts(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _writeByte(Tag.FunctionExpressionStub);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _writeByte(Tag.FunctionExpressionInvocation);

    _writeNode(node.function);
    _storeInvocationExpression(node);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _writeByte(Tag.FunctionReference);
    _writeNode(node.function);
    _writeOptionalNode(node.typeArguments);
    _sink.writeOptionalTypeList(node.typeArgumentTypes);
    _storeExpression(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _writeByte(Tag.FunctionTypedFormalParameter);

    _withTypeParameters(node.typeParameters, () {
      _writeOptionalNode(node.typeParameters);
      _writeOptionalNode(node.returnType);
      _writeNode(node.parameters);
      _storeNormalFormalParameter(node, null);
    });
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _writeByte(Tag.GenericFunctionType);

    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion: node.question != null,
      ),
    );

    _withTypeParameters(node.typeParameters, () {
      _writeOptionalNode(node.typeParameters);
      _writeOptionalNode(node.returnType);
      _writeNode(node.parameters);
      _sink.writeType(node.type);
    });
  }

  @override
  void visitIfElement(IfElement node) {
    _writeByte(Tag.IfElement);
    _writeNode(node.condition);
    _writeNode(node.thenElement);
    _writeOptionalNode(node.elseElement);
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    _writeByte(Tag.ImplicitCallReference);
    _writeNode(node.expression);
    _writeOptionalNode(node.typeArguments);
    _sink.writeOptionalTypeList(node.typeArgumentTypes);

    _sink.writeElement(node.staticElement);

    _storeExpression(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _writeByte(Tag.IndexExpression);
    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod: node.period != null,
        hasQuestion: node.question != null,
      ),
    );
    _writeOptionalNode(node.target);
    _writeNode(node.index);

    _sink.writeElement(node.staticElement);

    _storeExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _writeByte(Tag.InstanceCreationExpression);

    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.keyword?.type == Keyword.CONST,
        isNew: node.keyword?.type == Keyword.NEW,
      ),
    );

    _writeNode(node.constructorName);
    _writeNode(node.argumentList);
    _storeExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    var value = node.value;

    if (value == null) {
      _writeByte(Tag.IntegerLiteralNull);
      _writeStringReference(node.literal.lexeme);
    } else {
      var isPositive = value >= 0;
      if (!isPositive) {
        value = -value;
      }

      if (value & 0xFF == value) {
        _writeByte(
          isPositive
              ? Tag.IntegerLiteralPositive1
              : Tag.IntegerLiteralNegative1,
        );
        _writeStringReference(node.literal.lexeme);
        _writeByte(value);
      } else {
        _writeByte(
          isPositive ? Tag.IntegerLiteralPositive : Tag.IntegerLiteralNegative,
        );
        _writeStringReference(node.literal.lexeme);
        _writeUInt32(value >> 32);
        _writeUInt32(value & 0xFFFFFFFF);
      }
    }

    // TODO(scheglov) Don't write type, AKA separate true `int` and `double`?
    _storeExpression(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _writeByte(Tag.InterpolationExpression);
    _writeByte(
      AstBinaryFlags.encode(
        isStringInterpolationIdentifier:
            node.leftBracket.type == TokenType.STRING_INTERPOLATION_IDENTIFIER,
      ),
    );
    _writeNode(node.expression);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _writeByte(Tag.InterpolationString);
    _writeStringReference(node.contents.lexeme);
    _writeStringReference(node.value);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _writeByte(Tag.IsExpression);
    _writeByte(
      AstBinaryFlags.encode(
        hasNot: node.notOperator != null,
      ),
    );
    _writeNode(node.expression);
    _writeNode(node.type);
    _storeExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _writeByte(Tag.ListLiteral);

    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.constKeyword != null,
      ),
    );

    _writeOptionalNode(node.typeArguments);
    _writeNodeList(node.elements);

    _storeExpression(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _writeByte(Tag.MapLiteralEntry);
    _writeNode(node.key);
    _writeNode(node.value);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _writeByte(Tag.MethodInvocation);

    var operatorType = node.operator?.type;
    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod: operatorType == TokenType.PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD,
        hasPeriod2: operatorType == TokenType.PERIOD_PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD_PERIOD,
        hasQuestion: operatorType == TokenType.QUESTION_PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD_PERIOD,
      ),
    );

    _writeOptionalNode(node.target);
    _writeNode(node.methodName);
    _storeInvocationExpression(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _writeByte(Tag.NamedExpression);

    var nameNode = node.name.label;
    _writeStringReference(nameNode.name);

    _writeNode(node.expression);
  }

  @override
  void visitNamedType(NamedType node) {
    _writeByte(Tag.NamedType);

    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion: node.question != null,
        hasTypeArguments: node.typeArguments != null,
      ),
    );

    _writeNode(node.name);
    _writeOptionalNode(node.typeArguments);

    _sink.writeType(node.type);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _writeByte(Tag.NullLiteral);
    _storeExpression(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _writeByte(Tag.ParenthesizedExpression);
    _writeNode(node.expression);
    _storeExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _writeByte(Tag.PostfixExpression);

    _writeNode(node.operand);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    _sink.writeElement(node.staticElement);
    if (operatorToken.isIncrementOperator) {
      _sink.writeElement(node.readElement);
      _sink.writeType(node.readType);
      _sink.writeElement(node.writeElement);
      _sink.writeType(node.writeType);
    }
    _storeExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _writeByte(Tag.PrefixedIdentifier);
    _writeNode(node.prefix);
    _writeNode(node.identifier);

    // TODO(scheglov) In actual prefixed identifier, the type of the identifier.
    _storeExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _writeByte(Tag.PrefixExpression);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    _writeNode(node.operand);

    _sink.writeElement(node.staticElement);
    if (operatorToken.isIncrementOperator) {
      _sink.writeElement(node.readElement);
      _sink.writeType(node.readType);
      _sink.writeElement(node.writeElement);
      _sink.writeType(node.writeType);
    }

    _storeExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _writeByte(Tag.PropertyAccess);

    var operatorType = node.operator.type;
    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod: operatorType == TokenType.PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD,
        hasPeriod2: operatorType == TokenType.PERIOD_PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD_PERIOD,
        hasQuestion: operatorType == TokenType.QUESTION_PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD_PERIOD,
      ),
    );

    _writeOptionalNode(node.target);
    _writeNode(node.propertyName);
    // TODO(scheglov) Get from the property?
    _storeExpression(node);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    _writeByte(Tag.RecordLiteral);
    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.constKeyword != null,
      ),
    );
    _writeNodeList(node.fields);
    _storeExpression(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _writeByte(Tag.RedirectingConstructorInvocation);

    _writeOptionalNode(node.constructorName);
    _writeNode(node.argumentList);

    _sink.writeElement(node.staticElement);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _writeByte(Tag.SetOrMapLiteral);

    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.constKeyword != null,
      ),
    );

    var isMapBit = node.isMap ? (1 << 0) : 0;
    var isSetBit = node.isSet ? (1 << 1) : 0;
    _sink.writeByte(isMapBit | isSetBit);

    _writeOptionalNode(node.typeArguments);
    _writeNodeList(node.elements);

    _storeExpression(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _writeByte(Tag.SimpleFormalParameter);

    _writeOptionalNode(node.type);
    _storeNormalFormalParameter(node, node.keyword);

    var element = node.declaredElement as ParameterElementImpl;
    _sink.writeByte(element.inheritsCovariant ? 1 : 0);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _writeByte(Tag.SimpleIdentifier);
    _writeStringReference(node.name);

    _sink.writeElement(node.staticElement);
    _sink.writeOptionalTypeList(node.tearOffTypeArgumentTypes);

    _storeExpression(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _writeByte(Tag.SimpleStringLiteral);
    _writeStringReference(node.literal.lexeme);
    _writeStringReference(node.value);
    _storeExpression(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _writeByte(Tag.SpreadElement);
    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion:
            node.spreadOperator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION,
      ),
    );
    _writeNode(node.expression);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _writeByte(Tag.StringInterpolation);
    _writeNodeList(node.elements);
    _storeExpression(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writeByte(Tag.SuperConstructorInvocation);

    _writeOptionalNode(node.constructorName);
    _writeNode(node.argumentList);

    _sink.writeElement(node.staticElement);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _writeByte(Tag.SuperExpression);
    _storeExpression(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _writeByte(Tag.SymbolLiteral);

    var components = node.components;
    _writeUInt30(components.length);
    for (var token in components) {
      _writeStringReference(token.lexeme);
    }
    _storeExpression(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _writeByte(Tag.ThisExpression);
    _storeExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _writeByte(Tag.ThrowExpression);
    _writeNode(node.expression);
    _storeExpression(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _writeByte(Tag.TypeArgumentList);
    _writeNodeList(node.arguments);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _writeByte(Tag.TypeLiteral);
    _writeNode(node.type);
    _storeExpression(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _writeByte(Tag.TypeParameter);
    _writeDeclarationName(node.name);
    _writeOptionalNode(node.bound);
    _storeDeclaration(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _writeByte(Tag.TypeParameterList);
    _writeNodeList(node.typeParameters);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _writeByte(Tag.VariableDeclarationList);
    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.isConst,
        isFinal: node.isFinal,
        isLate: node.lateKeyword != null,
        isVar: node.keyword?.keyword == Keyword.VAR,
      ),
    );
    _writeOptionalNode(node.type);
    _writeNodeList(node.variables);
    _storeAnnotatedNode(node);
  }

  void _storeAnnotatedNode(AnnotatedNode node) {
    _writeNodeList(node.metadata);
  }

  void _storeDeclaration(Declaration node) {
    _storeAnnotatedNode(node);
  }

  void _storeExpression(Expression node) {
    _sink.writeType(node.staticType);
  }

  void _storeForEachParts(ForEachParts node) {
    _writeNode(node.iterable);
    _storeForLoopParts(node);
  }

  void _storeForLoopParts(ForLoopParts node) {}

  void _storeFormalParameter(FormalParameter node) {
    var element = node.declaredElement as ParameterElementImpl;
    _writeActualType(_sink, element.type);
  }

  void _storeForParts(ForParts node) {
    _writeOptionalNode(node.condition);
    _writeNodeList(node.updaters);
    _storeForLoopParts(node);
  }

  void _storeInvocationExpression(InvocationExpression node) {
    _writeOptionalNode(node.typeArguments);
    _writeNode(node.argumentList);
    _sink.writeType(node.staticInvokeType);
    _sink.writeOptionalTypeList(node.typeArgumentTypes);
    _storeExpression(node);
  }

  void _storeNormalFormalParameter(
    NormalFormalParameter node,
    Token? keyword, {
    bool hasQuestion = false,
  }) {
    _writeByte(
      AstBinaryFlags.encode(
        hasName: node.name != null,
        hasQuestion: hasQuestion,
        isConst: keyword?.type == Keyword.CONST,
        isCovariant: node.covariantKeyword != null,
        isFinal: keyword?.type == Keyword.FINAL,
        isRequired: node.requiredKeyword != null,
        isVar: keyword?.type == Keyword.VAR,
      ),
    );

    _writeNodeList(node.metadata);
    if (node.name != null) {
      _writeDeclarationName(node.name!);
    }
    _storeFormalParameter(node);
  }

  void _withTypeParameters(TypeParameterList? node, void Function() f) {
    if (node == null) {
      f();
    } else {
      var elements = node.typeParameters
          .map((typeParameter) => typeParameter.declaredElement!)
          .toList();
      _sink.localElements.withElements(elements, () {
        f();
      });
    }
  }

  void _writeActualType(ResolutionSink resolutionSink, DartType type) {
    resolutionSink.writeType(type);
  }

  void _writeByte(int byte) {
    assert((byte & 0xFF) == byte);
    _sink.addByte(byte);
  }

  void _writeDeclarationName(Token token) {
    _writeStringReference(token.lexeme);
  }

  _writeDouble(double value) {
    _sink.addDouble(value);
  }

  void _writeNode(AstNode node) {
    node.accept(this);
  }

  void _writeNodeList(List<AstNode> nodeList) {
    _writeUInt30(nodeList.length);
    for (var i = 0; i < nodeList.length; ++i) {
      nodeList[i].accept(this);
    }
  }

  void _writeNotSerializableExpression() {
    var node = astFactory.simpleIdentifier(
      StringToken(TokenType.STRING, '_notSerializableExpression', -1),
    );
    node.accept(this);
  }

  void _writeOptionalNode(AstNode? node) {
    if (node == null) {
      _writeByte(Tag.Nothing);
    } else {
      _writeByte(Tag.Something);
      _writeNode(node);
    }
  }

  void _writeStringReference(String string) {
    var index = _stringIndexer[string];
    _writeUInt30(index);
  }

  @pragma("vm:prefer-inline")
  void _writeUInt30(int value) {
    _sink.writeUInt30(value);
  }

  void _writeUInt32(int value) {
    _sink.addByte4((value >> 24) & 0xFF, (value >> 16) & 0xFF,
        (value >> 8) & 0xFF, value & 0xFF);
  }

  /// Return `true` if the expression might be successfully serialized.
  ///
  /// This does not mean that the expression is constant, it just means that
  /// we know that it might be serialized and deserialized. For example
  /// function expressions are problematic, and are not necessary to
  /// deserialize, so we choose not to do this.
  static bool _isSerializableExpression(Expression? node) {
    if (node == null) return false;

    var visitor = _IsSerializableExpressionVisitor();
    node.accept(visitor);
    return visitor.result;
  }
}

class _IsSerializableExpressionVisitor extends RecursiveAstVisitor<void> {
  bool result = true;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    result = false;
  }
}
