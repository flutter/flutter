// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/fasta/token_utils.dart' as util show findPrevious;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
import 'package:analyzer/src/generated/utilities_dart.dart';

/// Two or more string literals that are implicitly concatenated because of
/// being adjacent (separated only by whitespace).
///
/// While the grammar only allows adjacent strings when all of the strings are
/// of the same kind (single line or multi-line), this class doesn't enforce
/// that restriction.
///
///    adjacentStrings ::=
///        [StringLiteral] [StringLiteral]+
class AdjacentStringsImpl extends StringLiteralImpl implements AdjacentStrings {
  /// The strings that are implicitly concatenated.
  final NodeListImpl<StringLiteral> _strings = NodeListImpl._();

  /// Initialize a newly created list of adjacent strings. To be syntactically
  /// valid, the list of [strings] must contain at least two elements.
  AdjacentStringsImpl(List<StringLiteral> strings) {
    _strings._initialize(this, strings);
  }

  @override
  Token get beginToken => _strings.beginToken!;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(_strings);

  @override
  Token get endToken => _strings.endToken!;

  @override
  NodeListImpl<StringLiteral> get strings => _strings;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAdjacentStrings(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _strings.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    int length = strings.length;
    for (int i = 0; i < length; i++) {
      var stringLiteral = strings[i] as StringLiteralImpl;
      stringLiteral._appendStringValue(buffer);
    }
  }
}

/// An AST node that can be annotated with both a documentation comment and a
/// list of annotations.
abstract class AnnotatedNodeImpl extends AstNodeImpl implements AnnotatedNode {
  /// The documentation comment associated with this node, or `null` if this
  /// node does not have a documentation comment associated with it.
  CommentImpl? _comment;

  /// The annotations associated with this node.
  final NodeListImpl<Annotation> _metadata = NodeListImpl._();

  /// Initialize a newly created annotated node. Either or both of the [comment]
  /// and [metadata] can be `null` if the node does not have the corresponding
  /// attribute.
  AnnotatedNodeImpl(this._comment, List<Annotation>? metadata) {
    _becomeParentOf(_comment);
    _metadata._initialize(this, metadata);
  }

  @override
  Token get beginToken {
    if (_comment == null) {
      if (_metadata.isEmpty) {
        return firstTokenAfterCommentAndMetadata;
      }
      return _metadata.beginToken!;
    } else if (_metadata.isEmpty) {
      return _comment!.beginToken;
    }
    Token commentToken = _comment!.beginToken;
    Token metadataToken = _metadata.beginToken!;
    if (commentToken.offset < metadataToken.offset) {
      return commentToken;
    }
    return metadataToken;
  }

  @override
  CommentImpl? get documentationComment => _comment;

  set documentationComment(Comment? comment) {
    _comment = _becomeParentOf(comment as CommentImpl?);
  }

  @override
  NodeListImpl<Annotation> get metadata => _metadata;

  @override
  List<AstNode> get sortedCommentAndAnnotations {
    var comment = _comment;
    return <AstNode>[
      if (comment != null) comment,
      ..._metadata,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  /// Return a holder of child entities that subclasses can add to.
  ChildEntities get _childEntities {
    ChildEntities result = ChildEntities();
    if (_commentIsBeforeAnnotations()) {
      result
        ..add(_comment)
        ..addAll(_metadata);
    } else {
      result.addAll(sortedCommentAndAnnotations);
    }
    return result;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    if (_commentIsBeforeAnnotations()) {
      _comment?.accept(visitor);
      _metadata.accept(visitor);
    } else {
      List<AstNode> children = sortedCommentAndAnnotations;
      int length = children.length;
      for (int i = 0; i < length; i++) {
        children[i].accept(visitor);
      }
    }
  }

  /// Return `true` if there are no annotations before the comment. Note that a
  /// result of `true` does not imply that there is a comment, nor that there
  /// are annotations associated with this node.
  bool _commentIsBeforeAnnotations() {
    if (_comment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _comment!.offset < firstAnnotation.offset;
  }
}

/// An annotation that can be associated with an AST node.
///
///    metadata ::=
///        annotation*
///
///    annotation ::=
///        '@' [Identifier] ('.' [SimpleIdentifier])? [ArgumentList]?
class AnnotationImpl extends AstNodeImpl implements Annotation {
  /// The at sign that introduced the annotation.
  @override
  Token atSign;

  /// The name of the class defining the constructor that is being invoked or
  /// the name of the field that is being referenced.
  IdentifierImpl _name;

  /// The type arguments to the constructor being invoked, or `null` if (a) this
  /// annotation is not the invocation of a constructor or (b) this annotation
  /// does not specify type arguments explicitly.
  ///
  /// Note that type arguments are only valid if [Feature.generic_metadata] is
  /// enabled.
  TypeArgumentListImpl? _typeArguments;

  /// The period before the constructor name, or `null` if this annotation is
  /// not the invocation of a named constructor.
  @override
  Token? period;

  /// The name of the constructor being invoked, or `null` if this annotation is
  /// not the invocation of a named constructor.
  SimpleIdentifierImpl? _constructorName;

  /// The arguments to the constructor being invoked, or `null` if this
  /// annotation is not the invocation of a constructor.
  ArgumentListImpl? _arguments;

  /// The element associated with this annotation, or `null` if the AST
  /// structure has not been resolved or if this annotation could not be
  /// resolved.
  Element? _element;

  /// The element annotation representing this annotation in the element model.
  @override
  ElementAnnotation? elementAnnotation;

  /// Initialize a newly created annotation. Both the [period] and the
  /// [constructorName] can be `null` if the annotation is not referencing a
  /// named constructor. The [arguments] can be `null` if the annotation is not
  /// referencing a constructor.
  ///
  /// Note that type arguments are only valid if [Feature.generic_metadata] is
  /// enabled.
  AnnotationImpl(this.atSign, this._name, this._typeArguments, this.period,
      this._constructorName, this._arguments) {
    _becomeParentOf(_name);
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_constructorName);
    _becomeParentOf(_arguments);
  }

  @override
  ArgumentListImpl? get arguments => _arguments;

  set arguments(ArgumentList? arguments) {
    _arguments = _becomeParentOf(arguments as ArgumentListImpl?);
  }

  @override
  Token get beginToken => atSign;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(atSign)
    ..add(_name)
    ..add(_typeArguments)
    ..add(period)
    ..add(_constructorName)
    ..add(_arguments);

  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  set constructorName(SimpleIdentifier? name) {
    _constructorName = _becomeParentOf(name as SimpleIdentifierImpl?);
  }

  @override
  Element? get element {
    if (_element != null) {
      return _element!;
    } else if (_constructorName == null) {
      return _name.staticElement;
    }
    return null;
  }

  set element(Element? element) {
    _element = element;
  }

  @override
  Token get endToken {
    if (_arguments != null) {
      return _arguments!.endToken;
    } else if (_constructorName != null) {
      return _constructorName!.endToken;
    }
    return _name.endToken;
  }

  @override
  IdentifierImpl get name => _name;

  set name(Identifier name) {
    _name = _becomeParentOf(name as IdentifierImpl)!;
  }

  @override
  AstNode get parent => super.parent!;

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  /// Sets the type arguments to the constructor being invoked to the given
  /// [typeArguments].
  set typeArguments(TypeArgumentList? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAnnotation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name.accept(visitor);
    _typeArguments?.accept(visitor);
    _constructorName?.accept(visitor);
    _arguments?.accept(visitor);
  }
}

/// A list of arguments in the invocation of an executable element (that is, a
/// function, method, or constructor).
///
///    argumentList ::=
///        '(' arguments? ')'
///
///    arguments ::=
///        [NamedExpression] (',' [NamedExpression])*
///      | [Expression] (',' [Expression])* (',' [NamedExpression])*
class ArgumentListImpl extends AstNodeImpl implements ArgumentList {
  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The expressions producing the values of the arguments.
  final NodeListImpl<Expression> _arguments = NodeListImpl._();

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// A list containing the elements representing the parameters corresponding
  /// to each of the arguments in this list, or `null` if the AST has not been
  /// resolved or if the function or method being invoked could not be
  /// determined based on static type information. The list must be the same
  /// length as the number of arguments, but can contain `null` entries if a
  /// given argument does not correspond to a formal parameter.
  List<ParameterElement?>? _correspondingStaticParameters;

  /// Initialize a newly created list of arguments. The list of [arguments] can
  /// be `null` if there are no arguments.
  ArgumentListImpl(
      this.leftParenthesis, List<Expression> arguments, this.rightParenthesis) {
    _arguments._initialize(this, arguments);
  }

  @override
  NodeListImpl<Expression> get arguments => _arguments;

  @override
  Token get beginToken => leftParenthesis;

  @override
  // TODO(paulberry): Add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftParenthesis)
    ..addAll(_arguments)
    ..add(rightParenthesis);

  List<ParameterElement?>? get correspondingStaticParameters =>
      _correspondingStaticParameters;

  set correspondingStaticParameters(List<ParameterElement?>? parameters) {
    if (parameters != null && parameters.length != _arguments.length) {
      throw ArgumentError(
          "Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingStaticParameters = parameters;
  }

  @override
  Token get endToken => rightParenthesis;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitArgumentList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }

  /// If
  /// * the given [expression] is a child of this list,
  /// * the AST structure has been resolved,
  /// * the function being invoked is known based on static type information,
  ///   and
  /// * the expression corresponds to one of the parameters of the function
  ///   being invoked,
  /// then return the parameter element representing the parameter to which the
  /// value of the given expression will be bound. Otherwise, return `null`.
  ParameterElement? _getStaticParameterElementFor(Expression expression) {
    if (_correspondingStaticParameters == null ||
        _correspondingStaticParameters!.length != _arguments.length) {
      // Either the AST structure has not been resolved, the invocation of which
      // this list is a part could not be resolved, or the argument list was
      // modified after the parameters were set.
      return null;
    }
    int index = _arguments.indexOf(expression);
    if (index < 0) {
      // The expression isn't a child of this node.
      return null;
    }
    return _correspondingStaticParameters![index];
  }
}

/// An as expression.
///
///    asExpression ::=
///        [Expression] 'as' [TypeName]
class AsExpressionImpl extends ExpressionImpl implements AsExpression {
  /// The expression used to compute the value being cast.
  ExpressionImpl _expression;

  /// The 'as' operator.
  @override
  Token asOperator;

  /// The type being cast to.
  TypeAnnotationImpl _type;

  /// Initialize a newly created as expression.
  AsExpressionImpl(this._expression, this.asOperator, this._type) {
    _becomeParentOf(_expression);
    _becomeParentOf(_type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_expression)
    ..add(asOperator)
    ..add(_type);

  @override
  Token get endToken => _type.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @override
  TypeAnnotationImpl get type => _type;

  set type(TypeAnnotation type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAsExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
    _type.accept(visitor);
  }
}

/// An assert in the initializer list of a constructor.
///
///    assertInitializer ::=
///        'assert' '(' [Expression] (',' [Expression])? ')'
class AssertInitializerImpl extends ConstructorInitializerImpl
    implements AssertInitializer {
  @override
  Token assertKeyword;

  @override
  Token leftParenthesis;

  /// The condition that is being asserted to be `true`.
  ExpressionImpl _condition;

  @override
  Token? comma;

  /// The message to report if the assertion fails, or `null` if no message was
  /// supplied.
  ExpressionImpl? _message;

  @override
  Token rightParenthesis;

  /// Initialize a newly created assert initializer.
  AssertInitializerImpl(this.assertKeyword, this.leftParenthesis,
      this._condition, this.comma, this._message, this.rightParenthesis) {
    _becomeParentOf(_condition);
    _becomeParentOf(_message);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(assertKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(comma)
    ..add(_message)
    ..add(rightParenthesis);

  @override
  ExpressionImpl get condition => _condition;

  set condition(Expression condition) {
    _condition = _becomeParentOf(condition as ExpressionImpl);
  }

  @override
  Token get endToken => rightParenthesis;

  @override
  ExpressionImpl? get message => _message;

  set message(Expression? expression) {
    _message = _becomeParentOf(expression as ExpressionImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAssertInitializer(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    message?.accept(visitor);
  }
}

/// An assert statement.
///
///    assertStatement ::=
///        'assert' '(' [Expression] ')' ';'
class AssertStatementImpl extends StatementImpl implements AssertStatement {
  @override
  Token assertKeyword;

  @override
  Token leftParenthesis;

  /// The condition that is being asserted to be `true`.
  ExpressionImpl _condition;

  @override
  Token? comma;

  /// The message to report if the assertion fails, or `null` if no message was
  /// supplied.
  ExpressionImpl? _message;

  @override
  Token rightParenthesis;

  @override
  Token semicolon;

  /// Initialize a newly created assert statement.
  AssertStatementImpl(this.assertKeyword, this.leftParenthesis, this._condition,
      this.comma, this._message, this.rightParenthesis, this.semicolon) {
    _becomeParentOf(_condition);
    _becomeParentOf(_message);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(assertKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(comma)
    ..add(_message)
    ..add(rightParenthesis)
    ..add(semicolon);

  @override
  ExpressionImpl get condition => _condition;

  set condition(Expression condition) {
    _condition = _becomeParentOf(condition as ExpressionImpl);
  }

  @override
  Token get endToken => semicolon;

  @override
  ExpressionImpl? get message => _message;

  set message(Expression? expression) {
    _message = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAssertStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    message?.accept(visitor);
  }
}

/// An assignment expression.
///
///    assignmentExpression ::=
///        [Expression] operator [Expression]
class AssignmentExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements AssignmentExpression {
  /// The expression used to compute the left hand side.
  ExpressionImpl _leftHandSide;

  /// The assignment operator being applied.
  @override
  Token operator;

  /// The expression used to compute the right hand side.
  ExpressionImpl _rightHandSide;

  /// The element associated with the operator based on the static type of the
  /// left-hand-side, or `null` if the AST structure has not been resolved, if
  /// the operator is not a compound operator, or if the operator could not be
  /// resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created assignment expression.
  AssignmentExpressionImpl(
      this._leftHandSide, this.operator, this._rightHandSide) {
    _becomeParentOf(_leftHandSide);
    _becomeParentOf(_rightHandSide);
  }

  @override
  Token get beginToken => _leftHandSide.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_leftHandSide)
    ..add(operator)
    ..add(_rightHandSide);

  @override
  Token get endToken => _rightHandSide.endToken;

  @override
  ExpressionImpl get leftHandSide => _leftHandSide;

  set leftHandSide(Expression expression) {
    _leftHandSide = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  ExpressionImpl get rightHandSide => _rightHandSide;

  set rightHandSide(Expression expression) {
    _rightHandSide = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the right operand will be
  /// bound. Otherwise, return `null`.
  ParameterElement? get _staticParameterElementForRightHandSide {
    Element? executableElement;
    if (operator.type != TokenType.EQ) {
      executableElement = staticElement;
    } else {
      executableElement = writeElement;
    }

    if (executableElement is ExecutableElement) {
      List<ParameterElement> parameters = executableElement.parameters;
      if (parameters.isEmpty) {
        return null;
      }
      if (operator.type == TokenType.EQ && leftHandSide is IndexExpression) {
        return parameters.length == 2 ? parameters[1] : null;
      }
      return parameters[0];
    }

    return null;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitAssignmentExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _leftHandSide.accept(visitor);
    _rightHandSide.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) =>
      identical(child, _leftHandSide);
}

/// A node in the AST structure for a Dart program.
abstract class AstNodeImpl implements AstNode {
  /// The parent of the node, or `null` if the node is the root of an AST
  /// structure.
  AstNode? _parent;

  /// A table mapping the names of properties to their values, or `null` if this
  /// node does not have any properties associated with it.
  Map<String, Object>? _propertyMap;

  @override
  int get end => offset + length;

  @override
  bool get isSynthetic => false;

  @override
  int get length {
    final beginToken = this.beginToken;
    final endToken = this.endToken;
    return endToken.offset + endToken.length - beginToken.offset;
  }

  @override
  int get offset {
    final beginToken = this.beginToken;
    return beginToken.offset;
  }

  @override
  AstNode? get parent => _parent;

  @override
  AstNode get root {
    AstNode root = this;
    var rootParent = parent;
    while (rootParent != null) {
      root = rootParent;
      rootParent = root.parent;
    }
    return root;
  }

  void detachFromParent() {
    _parent = null;
  }

  @override
  Token? findPrevious(Token target) =>
      util.findPrevious(beginToken, target) ?? parent?.findPrevious(target);

  @override
  E? getProperty<E>(String name) {
    return _propertyMap?[name] as E?;
  }

  @override
  void setProperty(String name, Object? value) {
    if (value == null) {
      final propertyMap = _propertyMap;
      if (propertyMap != null) {
        propertyMap.remove(name);
        if (propertyMap.isEmpty) {
          _propertyMap = null;
        }
      }
    } else {
      (_propertyMap ??= HashMap<String, Object>())[name] = value;
    }
  }

  @override
  E? thisOrAncestorMatching<E extends AstNode>(Predicate<AstNode> predicate) {
    AstNode? node = this;
    while (node != null && !predicate(node)) {
      node = node.parent;
    }
    return node as E?;
  }

  @override
  E? thisOrAncestorOfType<E extends AstNode>() {
    AstNode? node = this;
    while (node != null && node is! E) {
      node = node.parent;
    }
    return node as E?;
  }

  @override
  String toSource() {
    StringBuffer buffer = StringBuffer();
    accept(ToSourceVisitor(buffer));
    return buffer.toString();
  }

  @override
  String toString() => toSource();

  /// Make this node the parent of the given [child] node. Return the child
  /// node.
  T _becomeParentOf<T extends AstNodeImpl?>(T child) {
    child?._parent = this;
    return child;
  }
}

/// An await expression.
///
///    awaitExpression ::=
///        'await' [Expression]
class AwaitExpressionImpl extends ExpressionImpl implements AwaitExpression {
  /// The 'await' keyword.
  @override
  Token awaitKeyword;

  /// The expression whose value is being waited on.
  ExpressionImpl _expression;

  /// Initialize a newly created await expression.
  AwaitExpressionImpl(this.awaitKeyword, this._expression) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    return awaitKeyword;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(awaitKeyword)
    ..add(_expression);

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAwaitExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A binary (infix) expression.
///
///    binaryExpression ::=
///        [Expression] [Token] [Expression]
class BinaryExpressionImpl extends ExpressionImpl implements BinaryExpression {
  /// The expression used to compute the left operand.
  ExpressionImpl _leftOperand;

  /// The binary operator being applied.
  @override
  Token operator;

  /// The expression used to compute the right operand.
  ExpressionImpl _rightOperand;

  /// The element associated with the operator based on the static type of the
  /// left operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement? staticElement;

  @override
  FunctionType? staticInvokeType;

  /// Initialize a newly created binary expression.
  BinaryExpressionImpl(this._leftOperand, this.operator, this._rightOperand) {
    _becomeParentOf(_leftOperand);
    _becomeParentOf(_rightOperand);
  }

  @override
  Token get beginToken => _leftOperand.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_leftOperand)
    ..add(operator)
    ..add(_rightOperand);

  @override
  Token get endToken => _rightOperand.endToken;

  @override
  ExpressionImpl get leftOperand => _leftOperand;

  set leftOperand(Expression expression) {
    _leftOperand = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.forTokenType(operator.type);

  @override
  ExpressionImpl get rightOperand => _rightOperand;

  set rightOperand(Expression expression) {
    _rightOperand = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBinaryExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _leftOperand.accept(visitor);
    _rightOperand.accept(visitor);
  }
}

/// A function body that consists of a block of statements.
///
///    blockFunctionBody ::=
///        ('async' | 'async' '*' | 'sync' '*')? [Block]
class BlockFunctionBodyImpl extends FunctionBodyImpl
    implements BlockFunctionBody {
  /// The token representing the 'async' or 'sync' keyword, or `null` if there
  /// is no such keyword.
  @override
  Token? keyword;

  /// The star optionally following the 'async' or 'sync' keyword, or `null` if
  /// there is wither no such keyword or no star.
  @override
  Token? star;

  /// The block representing the body of the function.
  BlockImpl _block;

  /// Initialize a newly created function body consisting of a block of
  /// statements. The [keyword] can be `null` if there is no keyword specified
  /// for the block. The [star] can be `null` if there is no star following the
  /// keyword (and must be `null` if there is no keyword).
  BlockFunctionBodyImpl(this.keyword, this.star, this._block) {
    _becomeParentOf(_block);
  }

  @override
  Token get beginToken {
    if (keyword != null) {
      return keyword!;
    }
    return _block.beginToken;
  }

  @override
  BlockImpl get block => _block;

  set block(Block block) {
    _block = _becomeParentOf(block as BlockImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(keyword)
    ..add(star)
    ..add(_block);

  @override
  Token get endToken => _block.endToken;

  @override
  bool get isAsynchronous => keyword?.lexeme == Keyword.ASYNC.lexeme;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword?.lexeme != Keyword.ASYNC.lexeme;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBlockFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _block.accept(visitor);
  }
}

/// A sequence of statements.
///
///    block ::=
///        '{' statement* '}'
class BlockImpl extends StatementImpl implements Block {
  /// The left curly bracket.
  @override
  Token leftBracket;

  /// The statements contained in the block.
  final NodeListImpl<Statement> _statements = NodeListImpl._();

  /// The right curly bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created block of code.
  BlockImpl(this.leftBracket, List<Statement> statements, this.rightBracket) {
    _statements._initialize(this, statements);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftBracket)
    ..addAll(_statements)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  NodeListImpl<Statement> get statements => _statements;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBlock(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _statements.accept(visitor);
  }
}

/// A boolean literal expression.
///
///    booleanLiteral ::=
///        'false' | 'true'
class BooleanLiteralImpl extends LiteralImpl implements BooleanLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// The value of the literal.
  @override
  bool value = false;

  /// Initialize a newly created boolean literal.
  BooleanLiteralImpl(this.literal, this.value);

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  bool get isSynthetic => literal.isSynthetic;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBooleanLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A break statement.
///
///    breakStatement ::=
///        'break' [SimpleIdentifier]? ';'
class BreakStatementImpl extends StatementImpl implements BreakStatement {
  /// The token representing the 'break' keyword.
  @override
  Token breakKeyword;

  /// The label associated with the statement, or `null` if there is no label.
  SimpleIdentifierImpl? _label;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// The AstNode which this break statement is breaking from.  This will be
  /// either a [Statement] (in the case of breaking out of a loop), a
  /// [SwitchMember] (in the case of a labeled break statement whose label
  /// matches a label on a switch case in an enclosing switch statement), or
  /// `null` if the AST has not yet been resolved or if the target could not be
  /// resolved. Note that if the source code has errors, the target might be
  /// invalid (e.g. trying to break to a switch case).
  @override
  AstNode? target;

  /// Initialize a newly created break statement. The [label] can be `null` if
  /// there is no label associated with the statement.
  BreakStatementImpl(this.breakKeyword, this._label, this.semicolon) {
    _becomeParentOf(_label);
  }

  @override
  Token get beginToken => breakKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(breakKeyword)
    ..add(_label)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  SimpleIdentifierImpl? get label => _label;

  set label(SimpleIdentifier? identifier) {
    _label = _becomeParentOf(identifier as SimpleIdentifierImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBreakStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label?.accept(visitor);
  }
}

/// A sequence of cascaded expressions: expressions that share a common target.
/// There are three kinds of expressions that can be used in a cascade
/// expression: [IndexExpression], [MethodInvocation] and [PropertyAccess].
///
///    cascadeExpression ::=
///        [Expression] cascadeSection*
///
///    cascadeSection ::=
///        '..'  (cascadeSelector arguments*) (assignableSelector arguments*)*
///        (assignmentOperator expressionWithoutCascade)?
///
///    cascadeSelector ::=
///        '[ ' expression '] '
///      | identifier
class CascadeExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements CascadeExpression {
  /// The target of the cascade sections.
  ExpressionImpl _target;

  /// The cascade sections sharing the common target.
  final NodeListImpl<Expression> _cascadeSections = NodeListImpl._();

  /// Initialize a newly created cascade expression. The list of
  /// [cascadeSections] must contain at least one element.
  CascadeExpressionImpl(this._target, List<Expression> cascadeSections) {
    _becomeParentOf(_target);
    _cascadeSections._initialize(this, cascadeSections);
  }

  @override
  Token get beginToken => _target.beginToken;

  @override
  NodeListImpl<Expression> get cascadeSections => _cascadeSections;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_target)
    ..addAll(_cascadeSections);

  @override
  Token get endToken => _cascadeSections.endToken!;

  @override
  bool get isNullAware {
    return target.endToken.next!.type == TokenType.QUESTION_PERIOD_PERIOD;
  }

  @override
  Precedence get precedence => Precedence.cascade;

  @override
  ExpressionImpl get target => _target;

  set target(Expression target) {
    _target = _becomeParentOf(target as ExpressionImpl);
  }

  @override
  AstNode? get _nullShortingExtensionCandidate => null;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCascadeExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _target.accept(visitor);
    _cascadeSections.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) {
    return _cascadeSections.contains(descendant);
  }
}

/// A catch clause within a try statement.
///
///    onPart ::=
///        catchPart [Block]
///      | 'on' type catchPart? [Block]
///
///    catchPart ::=
///        'catch' '(' [SimpleIdentifier] (',' [SimpleIdentifier])? ')'
class CatchClauseImpl extends AstNodeImpl implements CatchClause {
  /// The token representing the 'on' keyword, or `null` if there is no 'on'
  /// keyword.
  @override
  Token? onKeyword;

  /// The type of exceptions caught by this catch clause, or `null` if this
  /// catch clause catches every type of exception.
  TypeAnnotationImpl? _exceptionType;

  /// The token representing the 'catch' keyword, or `null` if there is no
  /// 'catch' keyword.
  @override
  Token? catchKeyword;

  /// The left parenthesis, or `null` if there is no 'catch' keyword.
  @override
  Token? leftParenthesis;

  /// The parameter whose value will be the exception that was thrown, or `null`
  /// if there is no 'catch' keyword.
  SimpleIdentifierImpl? _exceptionParameter;

  /// The comma separating the exception parameter from the stack trace
  /// parameter, or `null` if there is no stack trace parameter.
  @override
  Token? comma;

  /// The parameter whose value will be the stack trace associated with the
  /// exception, or `null` if there is no stack trace parameter.
  SimpleIdentifierImpl? _stackTraceParameter;

  /// The right parenthesis, or `null` if there is no 'catch' keyword.
  @override
  Token? rightParenthesis;

  /// The body of the catch block.
  BlockImpl _body;

  /// Initialize a newly created catch clause. The [onKeyword] and
  /// [exceptionType] can be `null` if the clause will catch all exceptions. The
  /// [comma] and [stackTraceParameter] can be `null` if the stack trace
  /// parameter is not defined.
  CatchClauseImpl(
      this.onKeyword,
      this._exceptionType,
      this.catchKeyword,
      this.leftParenthesis,
      this._exceptionParameter,
      this.comma,
      this._stackTraceParameter,
      this.rightParenthesis,
      this._body)
      : assert(onKeyword != null || catchKeyword != null) {
    _becomeParentOf(_exceptionType);
    _becomeParentOf(_exceptionParameter);
    _becomeParentOf(_stackTraceParameter);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken {
    if (onKeyword != null) {
      return onKeyword!;
    }
    return catchKeyword!;
  }

  @override
  BlockImpl get body => _body;

  set body(Block block) {
    _body = _becomeParentOf(block as BlockImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(onKeyword)
    ..add(_exceptionType)
    ..add(catchKeyword)
    ..add(leftParenthesis)
    ..add(_exceptionParameter)
    ..add(comma)
    ..add(_stackTraceParameter)
    ..add(rightParenthesis)
    ..add(_body);

  @override
  Token get endToken => _body.endToken;

  @override
  SimpleIdentifierImpl? get exceptionParameter => _exceptionParameter;

  set exceptionParameter(SimpleIdentifier? parameter) {
    _exceptionParameter = _becomeParentOf(parameter as SimpleIdentifierImpl?);
  }

  @override
  TypeAnnotationImpl? get exceptionType => _exceptionType;

  set exceptionType(TypeAnnotation? exceptionType) {
    _exceptionType = _becomeParentOf(exceptionType as TypeAnnotationImpl?);
  }

  @override
  SimpleIdentifierImpl? get stackTraceParameter => _stackTraceParameter;

  set stackTraceParameter(SimpleIdentifier? parameter) {
    _stackTraceParameter = _becomeParentOf(parameter as SimpleIdentifierImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCatchClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _exceptionType?.accept(visitor);
    _exceptionParameter?.accept(visitor);
    _stackTraceParameter?.accept(visitor);
    _body.accept(visitor);
  }
}

/// Helper class to allow iteration of child entities of an AST node.
class ChildEntities
    with IterableMixin<SyntacticEntity>
    implements Iterable<SyntacticEntity> {
  /// The list of child entities to be iterated over.
  final List<SyntacticEntity> _entities = [];

  @override
  Iterator<SyntacticEntity> get iterator => _entities.iterator;

  /// Add an AST node or token as the next child entity, if it is not `null`.
  void add(SyntacticEntity? entity) {
    if (entity != null) {
      _entities.add(entity);
    }
  }

  /// Add the given items as the next child entities, if [items] is not `null`.
  void addAll(Iterable<SyntacticEntity>? items) {
    if (items != null) {
      _entities.addAll(items);
    }
  }
}

/// The declaration of a class.
///
///    classDeclaration ::=
///        'abstract'? 'class' [SimpleIdentifier] [TypeParameterList]?
///        ([ExtendsClause] [WithClause]?)?
///        [ImplementsClause]?
///        '{' [ClassMember]* '}'
class ClassDeclarationImpl extends ClassOrMixinDeclarationImpl
    implements ClassDeclaration {
  /// The 'abstract' keyword, or `null` if the keyword was absent.
  @override
  Token? abstractKeyword;

  /// The token representing the 'class' keyword.
  @override
  Token classKeyword;

  /// The extends clause for the class, or `null` if the class does not extend
  /// any other class.
  ExtendsClauseImpl? _extendsClause;

  /// The with clause for the class, or `null` if the class does not have a with
  /// clause.
  WithClauseImpl? _withClause;

  /// The native clause for the class, or `null` if the class does not have a
  /// native clause.
  NativeClauseImpl? _nativeClause;

  /// Initialize a newly created class declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the class does not have the
  /// corresponding attribute. The [abstractKeyword] can be `null` if the class
  /// is not abstract. The [typeParameters] can be `null` if the class does not
  /// have any type parameters. Any or all of the [extendsClause], [withClause],
  /// and [implementsClause] can be `null` if the class does not have the
  /// corresponding clause. The list of [members] can be `null` if the class
  /// does not have any members.
  ClassDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.abstractKeyword,
      this.classKeyword,
      SimpleIdentifierImpl name,
      TypeParameterListImpl? typeParameters,
      this._extendsClause,
      this._withClause,
      ImplementsClauseImpl? implementsClause,
      Token leftBracket,
      List<ClassMember> members,
      Token rightBracket)
      : super(comment, metadata, name, typeParameters, implementsClause,
            leftBracket, members, rightBracket) {
    _becomeParentOf(_extendsClause);
    _becomeParentOf(_withClause);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(abstractKeyword)
    ..add(classKeyword)
    ..add(_name)
    ..add(_typeParameters)
    ..add(_extendsClause)
    ..add(_withClause)
    ..add(_implementsClause)
    ..add(_nativeClause)
    ..add(leftBracket)
    ..addAll(members)
    ..add(rightBracket);

  @override
  ClassElement? get declaredElement => _name.staticElement as ClassElement?;

  @override
  ExtendsClauseImpl? get extendsClause => _extendsClause;

  set extendsClause(ExtendsClause? extendsClause) {
    _extendsClause = _becomeParentOf(extendsClause as ExtendsClauseImpl?);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return abstractKeyword ?? classKeyword;
  }

  @override
  bool get isAbstract => abstractKeyword != null;

  @override
  NativeClauseImpl? get nativeClause => _nativeClause;

  set nativeClause(NativeClause? nativeClause) {
    _nativeClause = _becomeParentOf(nativeClause as NativeClauseImpl?);
  }

  @override
  WithClauseImpl? get withClause => _withClause;

  set withClause(WithClause? withClause) {
    _withClause = _becomeParentOf(withClause as WithClauseImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitClassDeclaration(this);

  @override
  ConstructorDeclaration? getConstructor(String? name) {
    int length = _members.length;
    for (int i = 0; i < length; i++) {
      ClassMember classMember = _members[i];
      if (classMember is ConstructorDeclaration) {
        ConstructorDeclaration constructor = classMember;
        SimpleIdentifier? constructorName = constructor.name;
        if (name == null && constructorName == null) {
          return constructor;
        }
        if (constructorName != null && constructorName.name == name) {
          return constructor;
        }
      }
    }
    return null;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name.accept(visitor);
    _typeParameters?.accept(visitor);
    _extendsClause?.accept(visitor);
    _withClause?.accept(visitor);
    _implementsClause?.accept(visitor);
    _nativeClause?.accept(visitor);
    members.accept(visitor);
  }
}

/// A node that declares a name within the scope of a class.
abstract class ClassMemberImpl extends DeclarationImpl implements ClassMember {
  /// Initialize a newly created member of a class. Either or both of the
  /// [comment] and [metadata] can be `null` if the member does not have the
  /// corresponding attribute.
  ClassMemberImpl(CommentImpl? comment, List<Annotation>? metadata)
      : super(comment, metadata);
}

abstract class ClassOrMixinDeclarationImpl
    extends NamedCompilationUnitMemberImpl implements ClassOrMixinDeclaration {
  /// The type parameters for the class or mixin,
  /// or `null` if the declaration does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The implements clause for the class or mixin,
  /// or `null` if the declaration does not implement any interfaces.
  ImplementsClauseImpl? _implementsClause;

  /// The left curly bracket.
  @override
  Token leftBracket;

  /// The members defined by the class or mixin.
  final NodeListImpl<ClassMember> _members = NodeListImpl._();

  /// The right curly bracket.
  @override
  Token rightBracket;

  ClassOrMixinDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      SimpleIdentifierImpl name,
      this._typeParameters,
      this._implementsClause,
      this.leftBracket,
      List<ClassMember> members,
      this.rightBracket)
      : super(comment, metadata, name) {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_implementsClause);
    _members._initialize(this, members);
  }

  @override
  Token get endToken => rightBracket;

  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  set implementsClause(ImplementsClause? implementsClause) {
    _implementsClause =
        _becomeParentOf(implementsClause as ImplementsClauseImpl?);
  }

  @override
  NodeListImpl<ClassMember> get members => _members;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  VariableDeclaration? getField(String name) {
    int memberLength = _members.length;
    for (int i = 0; i < memberLength; i++) {
      ClassMember classMember = _members[i];
      if (classMember is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = classMember;
        NodeList<VariableDeclaration> fields =
            fieldDeclaration.fields.variables;
        int fieldLength = fields.length;
        for (int i = 0; i < fieldLength; i++) {
          VariableDeclaration field = fields[i];
          if (name == field.name.name) {
            return field;
          }
        }
      }
    }
    return null;
  }

  @override
  MethodDeclaration? getMethod(String name) {
    int length = _members.length;
    for (int i = 0; i < length; i++) {
      ClassMember classMember = _members[i];
      if (classMember is MethodDeclaration) {
        MethodDeclaration method = classMember;
        if (name == method.name.name) {
          return method;
        }
      }
    }
    return null;
  }
}

/// A class type alias.
///
///    classTypeAlias ::=
///        [SimpleIdentifier] [TypeParameterList]? '=' 'abstract'?
///        mixinApplication
///
///    mixinApplication ::=
///        [TypeName] [WithClause] [ImplementsClause]? ';'
class ClassTypeAliasImpl extends TypeAliasImpl implements ClassTypeAlias {
  /// The type parameters for the class, or `null` if the class does not have
  /// any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The token for the '=' separating the name from the definition.
  @override
  Token equals;

  /// The token for the 'abstract' keyword, or `null` if this is not defining an
  /// abstract class.
  @override
  Token? abstractKeyword;

  /// The name of the superclass of the class being declared.
  NamedTypeImpl _superclass;

  /// The with clause for this class.
  WithClauseImpl _withClause;

  /// The implements clause for this class, or `null` if there is no implements
  /// clause.
  ImplementsClauseImpl? _implementsClause;

  /// Initialize a newly created class type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the class type alias does not
  /// have the corresponding attribute. The [typeParameters] can be `null` if
  /// the class does not have any type parameters. The [abstractKeyword] can be
  /// `null` if the class is not abstract. The [implementsClause] can be `null`
  /// if the class does not implement any interfaces.
  ClassTypeAliasImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      Token keyword,
      SimpleIdentifierImpl name,
      this._typeParameters,
      this.equals,
      this.abstractKeyword,
      this._superclass,
      this._withClause,
      this._implementsClause,
      Token semicolon)
      : super(comment, metadata, keyword, name, semicolon) {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_superclass);
    _becomeParentOf(_withClause);
    _becomeParentOf(_implementsClause);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(typedefKeyword)
    ..add(_name)
    ..add(_typeParameters)
    ..add(equals)
    ..add(abstractKeyword)
    ..add(_superclass)
    ..add(_withClause)
    ..add(_implementsClause)
    ..add(semicolon);

  @override
  ClassElement? get declaredElement => _name.staticElement as ClassElement?;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return abstractKeyword ?? typedefKeyword;
  }

  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  set implementsClause(ImplementsClause? implementsClause) {
    _implementsClause =
        _becomeParentOf(implementsClause as ImplementsClauseImpl?);
  }

  @override
  bool get isAbstract => abstractKeyword != null;

  @Deprecated('Use superclass2 instead')
  @override
  NamedTypeImpl get superclass => _superclass;

  set superclass(NamedType superclass) {
    _superclass = _becomeParentOf(superclass as NamedTypeImpl);
  }

  @override
  NamedTypeImpl get superclass2 => _superclass;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  WithClauseImpl get withClause => _withClause;

  set withClause(WithClause withClause) {
    _withClause = _becomeParentOf(withClause as WithClauseImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitClassTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name.accept(visitor);
    _typeParameters?.accept(visitor);
    _superclass.accept(visitor);
    _withClause.accept(visitor);
    _implementsClause?.accept(visitor);
  }
}

abstract class CollectionElementImpl extends AstNodeImpl
    implements CollectionElement {}

/// A combinator associated with an import or export directive.
///
///    combinator ::=
///        [HideCombinator]
///      | [ShowCombinator]
abstract class CombinatorImpl extends AstNodeImpl implements Combinator {
  /// The 'hide' or 'show' keyword specifying what kind of processing is to be
  /// done on the names.
  @override
  Token keyword;

  /// Initialize a newly created combinator.
  CombinatorImpl(this.keyword);

  @override
  Token get beginToken => keyword;
}

/// A comment within the source code.
///
///    comment ::=
///        endOfLineComment
///      | blockComment
///      | documentationComment
///
///    endOfLineComment ::=
///        '//' (CHARACTER - EOL)* EOL
///
///    blockComment ::=
///        '/ *' CHARACTER* '&#42;/'
///
///    documentationComment ::=
///        '/ **' (CHARACTER | [CommentReference])* '&#42;/'
///      | ('///' (CHARACTER - EOL)* EOL)+
class CommentImpl extends AstNodeImpl implements Comment {
  /// The tokens representing the comment.
  @override
  final List<Token> tokens;

  /// The type of the comment.
  final CommentType _type;

  /// The references embedded within the documentation comment. This list will
  /// be empty unless this is a documentation comment that has references embedded
  /// within it.
  final NodeListImpl<CommentReference> _references = NodeListImpl._();

  /// Initialize a newly created comment. The list of [tokens] must contain at
  /// least one token. The [_type] is the type of the comment. The list of
  /// [references] can be empty if the comment does not contain any embedded
  /// references.
  CommentImpl(this.tokens, this._type, List<CommentReference> references) {
    _references._initialize(this, references);
  }

  @override
  Token get beginToken => tokens[0];

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(tokens);

  @override
  Token get endToken => tokens[tokens.length - 1];

  @override
  bool get isBlock => _type == CommentType.BLOCK;

  @override
  bool get isDocumentation => _type == CommentType.DOCUMENTATION;

  @override
  bool get isEndOfLine => _type == CommentType.END_OF_LINE;

  @override
  NodeListImpl<CommentReference> get references => _references;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitComment(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _references.accept(visitor);
  }

  /// Create a block comment consisting of the given [tokens].
  static CommentImpl createBlockComment(List<Token> tokens) =>
      CommentImpl(tokens, CommentType.BLOCK, const <CommentReference>[]);

  /// Create a documentation comment consisting of the given [tokens].
  static CommentImpl createDocumentationComment(List<Token> tokens) =>
      CommentImpl(
          tokens, CommentType.DOCUMENTATION, const <CommentReference>[]);

  /// Create a documentation comment consisting of the given [tokens] and having
  /// the given [references] embedded within it.
  static CommentImpl createDocumentationCommentWithReferences(
          List<Token> tokens, List<CommentReference> references) =>
      CommentImpl(tokens, CommentType.DOCUMENTATION, references);

  /// Create an end-of-line comment consisting of the given [tokens].
  static CommentImpl createEndOfLineComment(List<Token> tokens) =>
      CommentImpl(tokens, CommentType.END_OF_LINE, const <CommentReference>[]);
}

abstract class CommentReferableExpressionImpl extends ExpressionImpl
    implements CommentReferableExpression {}

/// A reference to a Dart element that is found within a documentation comment.
///
///    commentReference ::=
///        '[' 'new'? [Identifier] ']'
class CommentReferenceImpl extends AstNodeImpl implements CommentReference {
  /// The token representing the 'new' keyword, or `null` if there was no 'new'
  /// keyword.
  @override
  Token? newKeyword;

  /// The expression being referenced.
  CommentReferableExpressionImpl _expression;

  /// Initialize a newly created reference to a Dart element. The [newKeyword]
  /// can be `null` if the reference is not to a constructor.
  CommentReferenceImpl(this.newKeyword, this._expression) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => newKeyword ?? _expression.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(newKeyword)
    ..add(_expression);

  @override
  Token get endToken => _expression.endToken;

  @override
  CommentReferableExpression get expression => _expression;

  set expression(CommentReferableExpression expression) {
    _expression = _becomeParentOf(expression as CommentReferableExpressionImpl);
  }

  @override
  @Deprecated('Use expression instead')
  IdentifierImpl get identifier => _expression as IdentifierImpl;

  @Deprecated('Use expression= instead')
  set identifier(Identifier identifier) {
    _expression = _becomeParentOf(identifier as CommentReferableExpressionImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCommentReference(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// The possible types of comments that are recognized by the parser.
class CommentType {
  /// A block comment.
  static const CommentType BLOCK = CommentType('BLOCK');

  /// A documentation comment.
  static const CommentType DOCUMENTATION = CommentType('DOCUMENTATION');

  /// An end-of-line comment.
  static const CommentType END_OF_LINE = CommentType('END_OF_LINE');

  /// The name of the comment type.
  final String name;

  /// Initialize a newly created comment type to have the given [name].
  const CommentType(this.name);

  @override
  String toString() => name;
}

/// A compilation unit.
///
/// While the grammar restricts the order of the directives and declarations
/// within a compilation unit, this class does not enforce those restrictions.
/// In particular, the children of a compilation unit will be visited in lexical
/// order even if lexical order does not conform to the restrictions of the
/// grammar.
///
///    compilationUnit ::=
///        directives declarations
///
///    directives ::=
///        [ScriptTag]? [LibraryDirective]? namespaceDirective* [PartDirective]*
///      | [PartOfDirective]
///
///    namespaceDirective ::=
///        [ImportDirective]
///      | [ExportDirective]
///
///    declarations ::=
///        [CompilationUnitMember]*
class CompilationUnitImpl extends AstNodeImpl implements CompilationUnit {
  /// The first token in the token stream that was parsed to form this
  /// compilation unit.
  @override
  Token beginToken;

  /// The script tag at the beginning of the compilation unit, or `null` if
  /// there is no script tag in this compilation unit.
  ScriptTagImpl? _scriptTag;

  /// The directives contained in this compilation unit.
  final NodeListImpl<Directive> _directives = NodeListImpl._();

  /// The declarations contained in this compilation unit.
  final NodeListImpl<CompilationUnitMember> _declarations = NodeListImpl._();

  /// The last token in the token stream that was parsed to form this
  /// compilation unit. This token should always have a type of [TokenType.EOF].
  @override
  Token endToken;

  /// The element associated with this compilation unit, or `null` if the AST
  /// structure has not been resolved.
  @override
  CompilationUnitElement? declaredElement;

  /// The line information for this compilation unit.
  @override
  LineInfo? lineInfo;

  /// The language version information.
  LibraryLanguageVersion? languageVersion;

  @override
  final FeatureSet featureSet;

  /// Initialize a newly created compilation unit to have the given directives
  /// and declarations. The [scriptTag] can be `null` if there is no script tag
  /// in the compilation unit. The list of [directives] can be `null` if there
  /// are no directives in the compilation unit. The list of [declarations] can
  /// be `null` if there are no declarations in the compilation unit.
  CompilationUnitImpl(
      this.beginToken,
      this._scriptTag,
      List<Directive>? directives,
      List<CompilationUnitMember>? declarations,
      this.endToken,
      this.featureSet) {
    _becomeParentOf(_scriptTag);
    _directives._initialize(this, directives);
    _declarations._initialize(this, declarations);
  }

  @override
  Iterable<SyntacticEntity> get childEntities {
    ChildEntities result = ChildEntities()..add(_scriptTag);
    if (_directivesAreBeforeDeclarations) {
      result
        ..addAll(_directives)
        ..addAll(_declarations);
    } else {
      result.addAll(sortedDirectivesAndDeclarations);
    }
    return result;
  }

  @override
  NodeListImpl<CompilationUnitMember> get declarations => _declarations;

  @override
  NodeListImpl<Directive> get directives => _directives;

  set element(CompilationUnitElement? element) {
    declaredElement = element;
  }

  @override
  LanguageVersionToken? get languageVersionToken {
    Token? targetToken = beginToken;
    if (targetToken.type == TokenType.SCRIPT_TAG) {
      targetToken = targetToken.next;
    }

    Token? comment = targetToken?.precedingComments;
    while (comment != null) {
      if (comment is LanguageVersionToken) {
        return comment;
      }
      comment = comment.next;
    }
    return null;
  }

  @override
  int get length {
    final endToken = this.endToken;
    return endToken.offset + endToken.length;
  }

  @override
  int get offset => 0;

  @override
  ScriptTag? get scriptTag => _scriptTag;

  set scriptTag(ScriptTag? scriptTag) {
    _scriptTag = _becomeParentOf(scriptTag as ScriptTagImpl?);
  }

  @override
  List<AstNode> get sortedDirectivesAndDeclarations {
    return <AstNode>[
      ..._directives,
      ..._declarations,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  /// Return `true` if all of the directives are lexically before any
  /// declarations.
  bool get _directivesAreBeforeDeclarations {
    if (_directives.isEmpty || _declarations.isEmpty) {
      return true;
    }
    Directive lastDirective = _directives[_directives.length - 1];
    CompilationUnitMember firstDeclaration = _declarations[0];
    return lastDirective.offset < firstDeclaration.offset;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCompilationUnit(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _scriptTag?.accept(visitor);
    if (_directivesAreBeforeDeclarations) {
      _directives.accept(visitor);
      _declarations.accept(visitor);
    } else {
      List<AstNode> sortedMembers = sortedDirectivesAndDeclarations;
      int length = sortedMembers.length;
      for (int i = 0; i < length; i++) {
        AstNode child = sortedMembers[i];
        child.accept(visitor);
      }
    }
  }
}

/// A node that declares one or more names within the scope of a compilation
/// unit.
///
///    compilationUnitMember ::=
///        [ClassDeclaration]
///      | [MixinDeclaration]
///      | [ExtensionDeclaration]
///      | [EnumDeclaration]
///      | [TypeAlias]
///      | [FunctionDeclaration]
///      | [TopLevelVariableDeclaration]
abstract class CompilationUnitMemberImpl extends DeclarationImpl
    implements CompilationUnitMember {
  /// Initialize a newly created generic compilation unit member. Either or both
  /// of the [comment] and [metadata] can be `null` if the member does not have
  /// the corresponding attribute.
  CompilationUnitMemberImpl(CommentImpl? comment, List<Annotation>? metadata)
      : super(comment, metadata);
}

mixin CompoundAssignmentExpressionImpl implements CompoundAssignmentExpression {
  @override
  Element? readElement;

  @override
  Element? writeElement;

  @override
  DartType? readType;

  @override
  DartType? writeType;
}

/// A conditional expression.
///
///    conditionalExpression ::=
///        [Expression] '?' [Expression] ':' [Expression]
class ConditionalExpressionImpl extends ExpressionImpl
    implements ConditionalExpression {
  /// The condition used to determine which of the expressions is executed next.
  ExpressionImpl _condition;

  /// The token used to separate the condition from the then expression.
  @override
  Token question;

  /// The expression that is executed if the condition evaluates to `true`.
  ExpressionImpl _thenExpression;

  /// The token used to separate the then expression from the else expression.
  @override
  Token colon;

  /// The expression that is executed if the condition evaluates to `false`.
  ExpressionImpl _elseExpression;

  /// Initialize a newly created conditional expression.
  ConditionalExpressionImpl(this._condition, this.question,
      this._thenExpression, this.colon, this._elseExpression) {
    _becomeParentOf(_condition);
    _becomeParentOf(_thenExpression);
    _becomeParentOf(_elseExpression);
  }

  @override
  Token get beginToken => _condition.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_condition)
    ..add(question)
    ..add(_thenExpression)
    ..add(colon)
    ..add(_elseExpression);

  @override
  ExpressionImpl get condition => _condition;

  set condition(Expression expression) {
    _condition = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  ExpressionImpl get elseExpression => _elseExpression;

  set elseExpression(Expression expression) {
    _elseExpression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Token get endToken => _elseExpression.endToken;

  @override
  Precedence get precedence => Precedence.conditional;

  @override
  ExpressionImpl get thenExpression => _thenExpression;

  set thenExpression(Expression expression) {
    _thenExpression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConditionalExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    _thenExpression.accept(visitor);
    _elseExpression.accept(visitor);
  }
}

/// A configuration in either an import or export directive.
///
///     configuration ::=
///         'if' '(' test ')' uri
///
///     test ::=
///         dottedName ('==' stringLiteral)?
///
///     dottedName ::=
///         identifier ('.' identifier)*
class ConfigurationImpl extends AstNodeImpl implements Configuration {
  @override
  Token ifKeyword;

  @override
  Token leftParenthesis;

  DottedNameImpl _name;

  @override
  Token? equalToken;

  StringLiteralImpl? _value;

  @override
  Token rightParenthesis;

  StringLiteralImpl _uri;

  @override
  Source? uriSource;

  ConfigurationImpl(this.ifKeyword, this.leftParenthesis, this._name,
      this.equalToken, this._value, this.rightParenthesis, this._uri) {
    _becomeParentOf(_name);
    _becomeParentOf(_value);
    _becomeParentOf(_uri);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(ifKeyword)
    ..add(leftParenthesis)
    ..add(_name)
    ..add(equalToken)
    ..add(_value)
    ..add(rightParenthesis)
    ..add(_uri);

  @override
  Token get endToken => _uri.endToken;

  @override
  DottedNameImpl get name => _name;

  set name(DottedName name) {
    _name = _becomeParentOf(name as DottedNameImpl);
  }

  @override
  StringLiteralImpl get uri => _uri;

  set uri(StringLiteral uri) {
    _uri = _becomeParentOf(uri as StringLiteralImpl);
  }

  @override
  StringLiteralImpl? get value => _value;

  set value(StringLiteral? value) {
    _value = _becomeParentOf(value as StringLiteralImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConfiguration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name.accept(visitor);
    _value?.accept(visitor);
    _uri.accept(visitor);
  }
}

/// This class is used as a marker of constant context for initializers
/// of constant fields and top-level variables read from summaries.
class ConstantContextForExpressionImpl extends AstNodeImpl {
  final ExpressionImpl expression;

  ConstantContextForExpressionImpl(this.expression) {
    _becomeParentOf(expression);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A constructor declaration.
///
///    constructorDeclaration ::=
///        constructorSignature [FunctionBody]?
///      | constructorName formalParameterList ':' 'this'
///        ('.' [SimpleIdentifier])? arguments
///
///    constructorSignature ::=
///        'external'? constructorName formalParameterList initializerList?
///      | 'external'? 'factory' factoryName formalParameterList
///        initializerList?
///      | 'external'? 'const'  constructorName formalParameterList
///        initializerList?
///
///    constructorName ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])?
///
///    factoryName ::=
///        [Identifier] ('.' [SimpleIdentifier])?
///
///    initializerList ::=
///        ':' [ConstructorInitializer] (',' [ConstructorInitializer])*
class ConstructorDeclarationImpl extends ClassMemberImpl
    implements ConstructorDeclaration {
  /// The token for the 'external' keyword, or `null` if the constructor is not
  /// external.
  @override
  Token? externalKeyword;

  /// The token for the 'const' keyword, or `null` if the constructor is not a
  /// const constructor.
  @override
  Token? constKeyword;

  /// The token for the 'factory' keyword, or `null` if the constructor is not a
  /// factory constructor.
  @override
  Token? factoryKeyword;

  /// The type of object being created. This can be different than the type in
  /// which the constructor is being declared if the constructor is the
  /// implementation of a factory constructor.
  IdentifierImpl _returnType;

  /// The token for the period before the constructor name, or `null` if the
  /// constructor being declared is unnamed.
  @override
  Token? period;

  /// The name of the constructor, or `null` if the constructor being declared
  /// is unnamed.
  SimpleIdentifierImpl? _name;

  /// The parameters associated with the constructor.
  FormalParameterListImpl _parameters;

  /// The token for the separator (colon or equals) before the initializer list
  /// or redirection, or `null` if there are no initializers.
  @override
  Token? separator;

  /// The initializers associated with the constructor.
  final NodeListImpl<ConstructorInitializer> _initializers = NodeListImpl._();

  /// The name of the constructor to which this constructor will be redirected,
  /// or `null` if this is not a redirecting factory constructor.
  ConstructorNameImpl? _redirectedConstructor;

  /// The body of the constructor.
  FunctionBodyImpl _body;

  /// The element associated with this constructor, or `null` if the AST
  /// structure has not been resolved or if this constructor could not be
  /// resolved.
  @override
  ConstructorElement? declaredElement;

  /// Initialize a newly created constructor declaration. The [externalKeyword]
  /// can be `null` if the constructor is not external. Either or both of the
  /// [comment] and [metadata] can be `null` if the constructor does not have
  /// the corresponding attribute. The [constKeyword] can be `null` if the
  /// constructor cannot be used to create a constant. The [factoryKeyword] can
  /// be `null` if the constructor is not a factory. The [period] and [name] can
  /// both be `null` if the constructor is not a named constructor. The
  /// [separator] can be `null` if the constructor does not have any
  /// initializers and does not redirect to a different constructor. The list of
  /// [initializers] can be `null` if the constructor does not have any
  /// initializers. The [redirectedConstructor] can be `null` if the constructor
  /// does not redirect to a different constructor. The [body] can be `null` if
  /// the constructor does not have a body.
  ConstructorDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.externalKeyword,
      this.constKeyword,
      this.factoryKeyword,
      this._returnType,
      this.period,
      this._name,
      this._parameters,
      this.separator,
      List<ConstructorInitializer>? initializers,
      this._redirectedConstructor,
      this._body)
      : super(comment, metadata) {
    _becomeParentOf(_returnType);
    _becomeParentOf(_name);
    _becomeParentOf(_parameters);
    _initializers._initialize(this, initializers);
    _becomeParentOf(_redirectedConstructor);
    _becomeParentOf(_body);
  }

  @override
  FunctionBodyImpl get body => _body;

  set body(FunctionBody functionBody) {
    _body = _becomeParentOf(functionBody as FunctionBodyImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(externalKeyword)
    ..add(constKeyword)
    ..add(factoryKeyword)
    ..add(_returnType)
    ..add(period)
    ..add(_name)
    ..add(_parameters)
    ..add(separator)
    ..addAll(initializers)
    ..add(_redirectedConstructor)
    ..add(_body);

  @override
  Token get endToken {
    return _body.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(
            externalKeyword, constKeyword, factoryKeyword) ??
        _returnType.beginToken;
  }

  @override
  NodeListImpl<ConstructorInitializer> get initializers => _initializers;

  @override
  SimpleIdentifierImpl? get name => _name;

  set name(SimpleIdentifier? identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl?);
  }

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  ConstructorNameImpl? get redirectedConstructor => _redirectedConstructor;

  set redirectedConstructor(ConstructorName? redirectedConstructor) {
    _redirectedConstructor =
        _becomeParentOf(redirectedConstructor as ConstructorNameImpl);
  }

  @override
  IdentifierImpl get returnType => _returnType;

  set returnType(Identifier typeName) {
    _returnType = _becomeParentOf(typeName as IdentifierImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType.accept(visitor);
    _name?.accept(visitor);
    _parameters.accept(visitor);
    _initializers.accept(visitor);
    _redirectedConstructor?.accept(visitor);
    _body.accept(visitor);
  }
}

/// The initialization of a field within a constructor's initialization list.
///
///    fieldInitializer ::=
///        ('this' '.')? [SimpleIdentifier] '=' [Expression]
class ConstructorFieldInitializerImpl extends ConstructorInitializerImpl
    implements ConstructorFieldInitializer {
  /// The token for the 'this' keyword, or `null` if there is no 'this' keyword.
  @override
  Token? thisKeyword;

  /// The token for the period after the 'this' keyword, or `null` if there is
  /// no 'this' keyword.
  @override
  Token? period;

  /// The name of the field being initialized.
  SimpleIdentifierImpl _fieldName;

  /// The token for the equal sign between the field name and the expression.
  @override
  Token equals;

  /// The expression computing the value to which the field will be initialized.
  ExpressionImpl _expression;

  /// Initialize a newly created field initializer to initialize the field with
  /// the given name to the value of the given expression. The [thisKeyword] and
  /// [period] can be `null` if the 'this' keyword was not specified.
  ConstructorFieldInitializerImpl(this.thisKeyword, this.period,
      this._fieldName, this.equals, this._expression) {
    _becomeParentOf(_fieldName);
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    if (thisKeyword != null) {
      return thisKeyword!;
    }
    return _fieldName.beginToken;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(thisKeyword)
    ..add(period)
    ..add(_fieldName)
    ..add(equals)
    ..add(_expression);

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  SimpleIdentifierImpl get fieldName => _fieldName;

  set fieldName(SimpleIdentifier identifier) {
    _fieldName = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorFieldInitializer(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _fieldName.accept(visitor);
    _expression.accept(visitor);
  }
}

/// A node that can occur in the initializer list of a constructor declaration.
///
///    constructorInitializer ::=
///        [SuperConstructorInvocation]
///      | [ConstructorFieldInitializer]
///      | [RedirectingConstructorInvocation]
abstract class ConstructorInitializerImpl extends AstNodeImpl
    implements ConstructorInitializer {}

/// The name of the constructor.
///
///    constructorName ::=
///        type ('.' identifier)?
class ConstructorNameImpl extends AstNodeImpl implements ConstructorName {
  /// The name of the type defining the constructor.
  NamedTypeImpl _type;

  /// The token for the period before the constructor name, or `null` if the
  /// specified constructor is the unnamed constructor.
  @override
  Token? period;

  /// The name of the constructor, or `null` if the specified constructor is the
  /// unnamed constructor.
  SimpleIdentifierImpl? _name;

  /// The element associated with this constructor name based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// this constructor name could not be resolved.
  @override
  ConstructorElement? staticElement;

  /// Initialize a newly created constructor name. The [period] and [name] can
  /// be`null` if the constructor being named is the unnamed constructor.
  ConstructorNameImpl(this._type, this.period, this._name) {
    _becomeParentOf(_type);
    _becomeParentOf(_name);
  }

  @override
  Token get beginToken => _type.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_type)
    ..add(period)
    ..add(_name);

  @override
  Token get endToken {
    if (_name != null) {
      return _name!.endToken;
    }
    return _type.endToken;
  }

  @override
  SimpleIdentifierImpl? get name => _name;

  set name(SimpleIdentifier? name) {
    _name = _becomeParentOf(name as SimpleIdentifierImpl?);
  }

  @Deprecated('Use type2 instead')
  @override
  NamedTypeImpl get type => _type;

  set type(NamedType type) {
    _type = _becomeParentOf(type as NamedTypeImpl);
  }

  @override
  NamedTypeImpl get type2 => _type;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConstructorName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _type.accept(visitor);
    _name?.accept(visitor);
  }
}

/// An expression representing a reference to a constructor, e.g. the expression
/// `List.filled` in `var x = List.filled;`.
///
/// Objects of this type are not produced directly by the parser (because the
/// parser cannot tell whether an identifier refers to a type); they are
/// produced at resolution time.
class ConstructorReferenceImpl extends CommentReferableExpressionImpl
    implements ConstructorReference {
  ConstructorNameImpl _constructorName;

  ConstructorReferenceImpl(this._constructorName) {
    _becomeParentOf(_constructorName);
  }

  @override
  Token get beginToken => constructorName.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(constructorName);

  @override
  ConstructorNameImpl get constructorName => _constructorName;

  set constructorName(ConstructorNameImpl value) {
    _constructorName = _becomeParentOf(value);
  }

  @override
  Token get endToken => constructorName.endToken;

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorReference(this);

  @override
  void visitChildren(AstVisitor visitor) {
    constructorName.accept(visitor);
  }
}

/// A continue statement.
///
///    continueStatement ::=
///        'continue' [SimpleIdentifier]? ';'
class ContinueStatementImpl extends StatementImpl implements ContinueStatement {
  /// The token representing the 'continue' keyword.
  @override
  Token continueKeyword;

  /// The label associated with the statement, or `null` if there is no label.
  SimpleIdentifierImpl? _label;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// The AstNode which this continue statement is continuing to.  This will be
  /// either a Statement (in the case of continuing a loop) or a SwitchMember
  /// (in the case of continuing from one switch case to another).  Null if the
  /// AST has not yet been resolved or if the target could not be resolved.
  /// Note that if the source code has errors, the target may be invalid (e.g.
  /// the target may be in an enclosing function).
  @override
  AstNode? target;

  /// Initialize a newly created continue statement. The [label] can be `null`
  /// if there is no label associated with the statement.
  ContinueStatementImpl(this.continueKeyword, this._label, this.semicolon) {
    _becomeParentOf(_label);
  }

  @override
  Token get beginToken => continueKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(continueKeyword)
    ..add(_label)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  SimpleIdentifierImpl? get label => _label;

  set label(SimpleIdentifier? identifier) {
    _label = _becomeParentOf(identifier as SimpleIdentifierImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitContinueStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label?.accept(visitor);
  }
}

/// A node that represents the declaration of one or more names. Each declared
/// name is visible within a name scope.
abstract class DeclarationImpl extends AnnotatedNodeImpl
    implements Declaration {
  /// Initialize a newly created declaration. Either or both of the [comment]
  /// and [metadata] can be `null` if the declaration does not have the
  /// corresponding attribute.
  DeclarationImpl(CommentImpl? comment, List<Annotation>? metadata)
      : super(comment, metadata);
}

/// The declaration of a single identifier.
///
///    declaredIdentifier ::=
///        [Annotation] finalConstVarOrType [SimpleIdentifier]
class DeclaredIdentifierImpl extends DeclarationImpl
    implements DeclaredIdentifier {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  /// The name of the variable being declared.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [keyword] can be `null` if a type name is
  /// given. The [type] must be `null` if the keyword is 'var'.
  DeclaredIdentifierImpl(CommentImpl? comment, List<Annotation>? metadata,
      this.keyword, this._type, this._identifier)
      : super(comment, metadata) {
    _becomeParentOf(_type);
    _becomeParentOf(_identifier);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..add(_identifier);

  @override
  LocalVariableElement? get declaredElement {
    return _identifier.staticElement as LocalVariableElement;
  }

  @override
  Token get endToken => _identifier.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return keyword ?? _type?.beginToken ?? _identifier.beginToken;
  }

  @override
  SimpleIdentifierImpl get identifier => _identifier;

  set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotation? type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDeclaredIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    _identifier.accept(visitor);
  }
}

/// A simple identifier that declares a name.
// TODO(rnystrom): Consider making this distinct from [SimpleIdentifier] and
// get rid of all of the:
//
//     if (node.inDeclarationContext()) { ... }
//
// code and instead visit this separately. A declaration is semantically pretty
// different from a use, so using the same node type doesn't seem to buy us
// much.
class DeclaredSimpleIdentifier extends SimpleIdentifierImpl {
  DeclaredSimpleIdentifier(Token token) : super(token);

  @override
  bool inDeclarationContext() => true;
}

/// A formal parameter with a default value. There are two kinds of parameters
/// that are both represented by this class: named formal parameters and
/// positional formal parameters.
///
///    defaultFormalParameter ::=
///        [NormalFormalParameter] ('=' [Expression])?
///
///    defaultNamedParameter ::=
///        [NormalFormalParameter] (':' [Expression])?
class DefaultFormalParameterImpl extends FormalParameterImpl
    implements DefaultFormalParameter {
  /// The formal parameter with which the default value is associated.
  NormalFormalParameterImpl _parameter;

  /// The kind of this parameter.
  @override
  ParameterKind kind;

  /// The token separating the parameter from the default value, or `null` if
  /// there is no default value.
  @override
  Token? separator;

  /// The expression computing the default value for the parameter, or `null` if
  /// there is no default value.
  ExpressionImpl? _defaultValue;

  /// Initialize a newly created default formal parameter. The [separator] and
  /// [defaultValue] can be `null` if there is no default value.
  DefaultFormalParameterImpl(
      this._parameter, this.kind, this.separator, this._defaultValue) {
    _becomeParentOf(_parameter);
    _becomeParentOf(_defaultValue);
  }

  @override
  Token get beginToken => _parameter.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_parameter)
    ..add(separator)
    ..add(_defaultValue);

  @override
  Token? get covariantKeyword => null;

  @override
  ParameterElement? get declaredElement => _parameter.declaredElement;

  @override
  ExpressionImpl? get defaultValue => _defaultValue;

  set defaultValue(Expression? expression) {
    _defaultValue = _becomeParentOf(expression as ExpressionImpl?);
  }

  @override
  Token get endToken {
    if (_defaultValue != null) {
      return _defaultValue!.endToken;
    }
    return _parameter.endToken;
  }

  @override
  SimpleIdentifierImpl? get identifier => _parameter.identifier;

  @override
  bool get isConst => _parameter.isConst;

  @override
  bool get isFinal => _parameter.isFinal;

  @override
  NodeListImpl<Annotation> get metadata => _parameter.metadata;

  @override
  NormalFormalParameterImpl get parameter => _parameter;

  set parameter(NormalFormalParameter formalParameter) {
    _parameter = _becomeParentOf(formalParameter as NormalFormalParameterImpl);
  }

  @override
  Token? get requiredKeyword => null;

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDefaultFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _parameter.accept(visitor);
    _defaultValue?.accept(visitor);
  }
}

/// A node that represents a directive.
///
///    directive ::=
///        [ExportDirective]
///      | [ImportDirective]
///      | [LibraryDirective]
///      | [PartDirective]
///      | [PartOfDirective]
abstract class DirectiveImpl extends AnnotatedNodeImpl implements Directive {
  /// The element associated with this directive, or `null` if the AST structure
  /// has not been resolved or if this directive could not be resolved.
  Element? _element;

  /// Initialize a newly create directive. Either or both of the [comment] and
  /// [metadata] can be `null` if the directive does not have the corresponding
  /// attribute.
  DirectiveImpl(CommentImpl? comment, List<Annotation>? metadata)
      : super(comment, metadata);

  @override
  Element? get element => _element;

  /// Set the element associated with this directive to be the given [element].
  set element(Element? element) {
    _element = element;
  }
}

/// A do statement.
///
///    doStatement ::=
///        'do' [Statement] 'while' '(' [Expression] ')' ';'
class DoStatementImpl extends StatementImpl implements DoStatement {
  /// The token representing the 'do' keyword.
  @override
  Token doKeyword;

  /// The body of the loop.
  StatementImpl _body;

  /// The token representing the 'while' keyword.
  @override
  Token whileKeyword;

  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The condition that determines when the loop will terminate.
  ExpressionImpl _condition;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// Initialize a newly created do loop.
  DoStatementImpl(
      this.doKeyword,
      this._body,
      this.whileKeyword,
      this.leftParenthesis,
      this._condition,
      this.rightParenthesis,
      this.semicolon) {
    _becomeParentOf(_body);
    _becomeParentOf(_condition);
  }

  @override
  Token get beginToken => doKeyword;

  @override
  StatementImpl get body => _body;

  set body(Statement statement) {
    _body = _becomeParentOf(statement as StatementImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(doKeyword)
    ..add(_body)
    ..add(whileKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(semicolon);

  @override
  ExpressionImpl get condition => _condition;

  set condition(Expression expression) {
    _condition = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Token get endToken => semicolon;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDoStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _body.accept(visitor);
    _condition.accept(visitor);
  }
}

/// A dotted name, used in a configuration within an import or export directive.
///
///    dottedName ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
class DottedNameImpl extends AstNodeImpl implements DottedName {
  /// The components of the identifier.
  final NodeListImpl<SimpleIdentifier> _components = NodeListImpl._();

  /// Initialize a newly created dotted name.
  DottedNameImpl(List<SimpleIdentifier> components) {
    _components._initialize(this, components);
  }

  @override
  Token get beginToken => _components.beginToken!;

  @override
  // TODO(paulberry): add "." tokens.
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(_components);

  @override
  NodeListImpl<SimpleIdentifier> get components => _components;

  @override
  Token get endToken => _components.endToken!;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDottedName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _components.accept(visitor);
  }
}

/// A floating point literal expression.
///
///    doubleLiteral ::=
///        decimalDigit+ ('.' decimalDigit*)? exponent?
///      | '.' decimalDigit+ exponent?
///
///    exponent ::=
///        ('e' | 'E') ('+' | '-')? decimalDigit+
class DoubleLiteralImpl extends LiteralImpl implements DoubleLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// The value of the literal.
  @override
  double value;

  /// Initialize a newly created floating point literal.
  DoubleLiteralImpl(this.literal, this.value);

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDoubleLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// An empty function body, which can only appear in constructors or abstract
/// methods.
///
///    emptyFunctionBody ::=
///        ';'
class EmptyFunctionBodyImpl extends FunctionBodyImpl
    implements EmptyFunctionBody {
  /// The token representing the semicolon that marks the end of the function
  /// body.
  @override
  Token semicolon;

  /// Initialize a newly created function body.
  EmptyFunctionBodyImpl(this.semicolon);

  @override
  Token get beginToken => semicolon;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // Empty function bodies have no children.
  }
}

/// An empty statement.
///
///    emptyStatement ::=
///        ';'
class EmptyStatementImpl extends StatementImpl implements EmptyStatement {
  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// Initialize a newly created empty statement.
  EmptyStatementImpl(this.semicolon);

  @override
  Token get beginToken => semicolon;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  bool get isSynthetic => semicolon.isSynthetic;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// The declaration of an enum constant.
class EnumConstantDeclarationImpl extends DeclarationImpl
    implements EnumConstantDeclaration {
  /// The name of the constant.
  SimpleIdentifierImpl _name;

  /// Initialize a newly created enum constant declaration. Either or both of
  /// the [comment] and [metadata] can be `null` if the constant does not have
  /// the corresponding attribute. (Technically, enum constants cannot have
  /// metadata, but we allow it for consistency.)
  EnumConstantDeclarationImpl(
      CommentImpl? comment, List<Annotation>? metadata, this._name)
      : super(comment, metadata) {
    _becomeParentOf(_name);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(_name);

  @override
  FieldElement get declaredElement => _name.staticElement as FieldElement;

  @override
  Token get endToken => _name.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;

  @override
  SimpleIdentifierImpl get name => _name;

  set name(SimpleIdentifier name) {
    _name = _becomeParentOf(name as SimpleIdentifierImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitEnumConstantDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name.accept(visitor);
  }
}

/// The declaration of an enumeration.
///
///    enumType ::=
///        metadata 'enum' [SimpleIdentifier] '{' [SimpleIdentifier]
///        (',' [SimpleIdentifier])* (',')? '}'
class EnumDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements EnumDeclaration {
  /// The 'enum' keyword.
  @override
  Token enumKeyword;

  /// The left curly bracket.
  @override
  Token leftBracket;

  /// The enumeration constants being declared.
  final NodeListImpl<EnumConstantDeclaration> _constants = NodeListImpl._();

  /// The right curly bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created enumeration declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The list of [constants] must contain at least
  /// one value.
  EnumDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.enumKeyword,
      SimpleIdentifierImpl name,
      this.leftBracket,
      List<EnumConstantDeclaration> constants,
      this.rightBracket)
      : super(comment, metadata, name) {
    _constants._initialize(this, constants);
  }

  @override
  // TODO(brianwilkerson) Add commas?
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(enumKeyword)
    ..add(_name)
    ..add(leftBracket)
    ..addAll(_constants)
    ..add(rightBracket);

  @override
  NodeListImpl<EnumConstantDeclaration> get constants => _constants;

  @override
  ClassElement? get declaredElement => _name.staticElement as ClassElement?;

  @override
  Token get endToken => rightBracket;

  @override
  Token get firstTokenAfterCommentAndMetadata => enumKeyword;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEnumDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name.accept(visitor);
    _constants.accept(visitor);
  }
}

/// Ephemeral identifiers are created as needed to mimic the presence of an
/// empty identifier.
class EphemeralIdentifier extends SimpleIdentifierImpl {
  EphemeralIdentifier(AstNode parent, int location)
      : super(StringToken(TokenType.IDENTIFIER, "", location)) {
    (parent as AstNodeImpl)._becomeParentOf(this);
  }
}

/// An export directive.
///
///    exportDirective ::=
///        [Annotation] 'export' [StringLiteral] [Combinator]* ';'
class ExportDirectiveImpl extends NamespaceDirectiveImpl
    implements ExportDirective {
  /// Initialize a newly created export directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute. The list of [combinators] can be `null` if there
  /// are no combinators.
  ExportDirectiveImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      Token keyword,
      StringLiteralImpl libraryUri,
      List<Configuration>? configurations,
      List<Combinator>? combinators,
      Token semicolon)
      : super(comment, metadata, keyword, libraryUri, configurations,
            combinators, semicolon);

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_uri)
    ..addAll(combinators)
    ..add(semicolon);

  @override
  ExportElement? get element => super.element as ExportElement?;

  @override
  LibraryElement? get uriElement {
    return element?.exportedLibrary;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExportDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    configurations.accept(visitor);
    super.visitChildren(visitor);
    combinators.accept(visitor);
  }
}

/// A function body consisting of a single expression.
///
///    expressionFunctionBody ::=
///        'async'? '=>' [Expression] ';'
class ExpressionFunctionBodyImpl extends FunctionBodyImpl
    implements ExpressionFunctionBody {
  /// The token representing the 'async' keyword, or `null` if there is no such
  /// keyword.
  @override
  Token? keyword;

  /// The star optionally following the 'async' or 'sync' keyword, or `null` if
  /// there is wither no such keyword or no star.
  ///
  /// It is an error for an expression function body to feature the star, but
  /// the parser will accept it.
  @override
  Token? star;

  /// The token introducing the expression that represents the body of the
  /// function.
  @override
  Token functionDefinition;

  /// The expression representing the body of the function.
  ExpressionImpl _expression;

  /// The semicolon terminating the statement.
  @override
  Token? semicolon;

  /// Initialize a newly created function body consisting of a block of
  /// statements. The [keyword] can be `null` if the function body is not an
  /// async function body.
  ExpressionFunctionBodyImpl(this.keyword, this.star, this.functionDefinition,
      this._expression, this.semicolon) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    if (keyword != null) {
      return keyword!;
    }
    return functionDefinition;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(keyword)
    ..add(star)
    ..add(functionDefinition)
    ..add(_expression)
    ..add(semicolon);

  @override
  Token get endToken {
    if (semicolon != null) {
      return semicolon!;
    }
    return _expression.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  bool get isAsynchronous => keyword?.lexeme == Keyword.ASYNC.lexeme;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword?.lexeme != Keyword.ASYNC.lexeme;

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExpressionFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A node that represents an expression.
///
///    expression ::=
///        [AssignmentExpression]
///      | [ConditionalExpression] cascadeSection*
///      | [ThrowExpression]
abstract class ExpressionImpl extends AstNodeImpl
    implements CollectionElementImpl, Expression {
  /// The static type of this expression, or `null` if the AST structure has not
  /// been resolved.
  @override
  DartType? staticType;

  @override
  bool get inConstantContext {
    AstNode child = this;
    while (child is Expression ||
        child is ArgumentList ||
        child is MapLiteralEntry ||
        child is SpreadElement ||
        child is IfElement ||
        child is ForElement) {
      var parent = child.parent;
      if (parent is ConstantContextForExpressionImpl) {
        return true;
      } else if (parent is TypedLiteralImpl && parent.constKeyword != null) {
        // Inside an explicitly `const` list or map literal.
        return true;
      } else if (parent is InstanceCreationExpression &&
          parent.keyword?.keyword == Keyword.CONST) {
        // Inside an explicitly `const` instance creation expression.
        return true;
      } else if (parent is Annotation) {
        // Inside an annotation.
        return true;
      } else if (parent is VariableDeclaration) {
        var grandParent = parent.parent;
        // Inside the initializer for a `const` variable declaration.
        return grandParent is VariableDeclarationList &&
            grandParent.keyword?.keyword == Keyword.CONST;
      } else if (parent is SwitchCase) {
        // Inside a switch case.
        return true;
      } else if (parent == null) {
        break;
      }
      child = parent;
    }
    return false;
  }

  @override
  bool get isAssignable => false;

  @override
  ParameterElement? get staticParameterElement {
    final parent = this.parent;
    if (parent is ArgumentListImpl) {
      return parent._getStaticParameterElementFor(this);
    } else if (parent is IndexExpressionImpl) {
      if (identical(parent.index, this)) {
        return parent._staticParameterElementForIndex;
      }
    } else if (parent is BinaryExpressionImpl) {
      if (identical(parent.rightOperand, this)) {
        var parameters = parent.staticInvokeType?.parameters;
        if (parameters != null && parameters.isNotEmpty) {
          return parameters[0];
        }
        return null;
      }
    } else if (parent is AssignmentExpressionImpl) {
      if (identical(parent.rightHandSide, this)) {
        return parent._staticParameterElementForRightHandSide;
      }
    } else if (parent is PrefixExpressionImpl) {
      return parent._staticParameterElementForOperand;
    } else if (parent is PostfixExpressionImpl) {
      return parent._staticParameterElementForOperand;
    }
    return null;
  }

  @override
  ExpressionImpl get unParenthesized => this;
}

/// An expression used as a statement.
///
///    expressionStatement ::=
///        [Expression]? ';'
class ExpressionStatementImpl extends StatementImpl
    implements ExpressionStatement {
  /// The expression that comprises the statement.
  ExpressionImpl _expression;

  /// The semicolon terminating the statement, or `null` if the expression is a
  /// function expression and therefore isn't followed by a semicolon.
  @override
  Token? semicolon;

  /// Initialize a newly created expression statement.
  ExpressionStatementImpl(this._expression, this.semicolon) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_expression)
    ..add(semicolon);

  @override
  Token get endToken {
    if (semicolon != null) {
      return semicolon!;
    }
    return _expression.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  bool get isSynthetic =>
      _expression.isSynthetic && (semicolon == null || semicolon!.isSynthetic);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExpressionStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// The "extends" clause in a class declaration.
///
///    extendsClause ::=
///        'extends' [TypeName]
class ExtendsClauseImpl extends AstNodeImpl implements ExtendsClause {
  /// The token representing the 'extends' keyword.
  @override
  Token extendsKeyword;

  /// The name of the class that is being extended.
  NamedTypeImpl _superclass;

  /// Initialize a newly created extends clause.
  ExtendsClauseImpl(this.extendsKeyword, this._superclass) {
    _becomeParentOf(_superclass);
  }

  @override
  Token get beginToken => extendsKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(extendsKeyword)
    ..add(_superclass);

  @override
  Token get endToken => _superclass.endToken;

  @Deprecated('Use superclass2 instead')
  @override
  NamedTypeImpl get superclass => _superclass;

  set superclass(NamedType name) {
    _superclass = _becomeParentOf(name as NamedTypeImpl);
  }

  @override
  NamedTypeImpl get superclass2 => _superclass;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExtendsClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _superclass.accept(visitor);
  }
}

/// The declaration of an extension of a type.
///
///    extension ::=
///        'extension' [SimpleIdentifier] [TypeParameterList]?
///        'on' [TypeAnnotation] '{' [ClassMember]* '}'
///
/// Clients may not extend, implement or mix-in this class.
class ExtensionDeclarationImpl extends CompilationUnitMemberImpl
    implements ExtensionDeclaration {
  @override
  Token extensionKeyword;

  @override
  Token? typeKeyword;

  /// The hide clause for the extension or `null` if the declaration does not
  /// hide any elements.
  HideClauseImpl? _hideClause;

  /// The name of the extension, or `null` if the extension does not have a
  /// name.
  SimpleIdentifierImpl? _name;

  /// The show clause for the extension or `null` if the declaration does not
  /// show any elements.
  ShowClauseImpl? _showClause;

  /// The type parameters for the extension, or `null` if the extension does not
  /// have any type parameters.
  TypeParameterListImpl? _typeParameters;

  @override
  Token onKeyword;

  /// The type that is being extended.
  TypeAnnotationImpl _extendedType;

  @override
  Token leftBracket;

  /// The members being added to the extended class.
  final NodeListImpl<ClassMember> _members = NodeListImpl._();

  @override
  Token rightBracket;

  ExtensionElement? _declaredElement;

  ExtensionDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.extensionKeyword,
      this.typeKeyword,
      this._name,
      this._typeParameters,
      this.onKeyword,
      this._extendedType,
      this._showClause,
      this._hideClause,
      this.leftBracket,
      List<ClassMember> members,
      this.rightBracket)
      : super(comment, metadata) {
    _becomeParentOf(_name);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_extendedType);
    _members._initialize(this, members);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(extensionKeyword)
    ..add(name)
    ..add(typeParameters)
    ..add(onKeyword)
    ..add(extendedType)
    ..add(leftBracket)
    ..addAll(members)
    ..add(rightBracket);

  @override
  ExtensionElement? get declaredElement => _declaredElement;

  /// Set the element declared by this declaration to the given [element].
  set declaredElement(ExtensionElement? element) {
    _declaredElement = element;
  }

  @override
  Token get endToken => rightBracket;

  @override
  TypeAnnotationImpl get extendedType => _extendedType;

  set extendedType(TypeAnnotation extendedClass) {
    _extendedType = _becomeParentOf(extendedClass as TypeAnnotationImpl);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => extensionKeyword;

  @override
  HideClauseImpl? get hideClause => _hideClause;

  set hideClause(HideClause? hideClause) {
    _hideClause = _becomeParentOf(hideClause as HideClauseImpl?);
  }

  @override
  NodeListImpl<ClassMember> get members => _members;

  @override
  SimpleIdentifierImpl? get name => _name;

  set name(SimpleIdentifier? identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl?);
  }

  @override
  ShowClauseImpl? get showClause => _showClause;

  set showClause(ShowClause? showClause) {
    _showClause = _becomeParentOf(showClause as ShowClauseImpl?);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExtensionDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    name?.accept(visitor);
    _typeParameters?.accept(visitor);
    _extendedType.accept(visitor);
    _members.accept(visitor);
  }
}

/// An override to force resolution to choose a member from a specific
/// extension.
///
///    extensionOverride ::=
///        [Identifier] [TypeArgumentList]? [ArgumentList]
class ExtensionOverrideImpl extends ExpressionImpl
    implements ExtensionOverride {
  /// The list of arguments to the override. In valid code this will contain a
  /// single argument, which evaluates to the object being extended.
  ArgumentListImpl _argumentList;

  /// The name of the extension being selected.
  IdentifierImpl _extensionName;

  /// The type arguments to be applied to the extension, or `null` if no type
  /// arguments were provided.
  TypeArgumentListImpl? _typeArguments;

  @override
  List<DartType>? typeArgumentTypes;

  @override
  DartType? extendedType;

  ExtensionOverrideImpl(
      this._extensionName, this._typeArguments, this._argumentList) {
    _becomeParentOf(_extensionName);
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  Token get beginToken => _extensionName.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_extensionName)
    ..add(_typeArguments)
    ..add(_argumentList);

  @override
  Token get endToken => _argumentList.endToken;

  @override
  IdentifierImpl get extensionName => _extensionName;

  set extensionName(Identifier extensionName) {
    _extensionName = _becomeParentOf(extensionName as IdentifierImpl);
  }

  @override
  bool get isNullAware {
    var nextType = argumentList.endToken.next!.type;
    return nextType == TokenType.QUESTION_PERIOD ||
        nextType == TokenType.QUESTION;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ExtensionElement? get staticElement {
    return extensionName.staticElement as ExtensionElement?;
  }

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentList? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitExtensionOverride(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _extensionName.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
  }
}

/// The declaration of one or more fields of the same type.
///
///    fieldDeclaration ::=
///        'static'? [VariableDeclarationList] ';'
class FieldDeclarationImpl extends ClassMemberImpl implements FieldDeclaration {
  @override
  Token? abstractKeyword;

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  @override
  Token? covariantKeyword;

  @override
  Token? externalKeyword;

  /// The token representing the 'static' keyword, or `null` if the fields are
  /// not static.
  @override
  Token? staticKeyword;

  /// The fields being declared.
  VariableDeclarationListImpl _fieldList;

  /// The semicolon terminating the declaration.
  @override
  Token semicolon;

  /// Initialize a newly created field declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [staticKeyword] can be `null` if the
  /// field is not a static field.
  FieldDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.abstractKeyword,
      this.covariantKeyword,
      this.externalKeyword,
      this.staticKeyword,
      this._fieldList,
      this.semicolon)
      : super(comment, metadata) {
    _becomeParentOf(_fieldList);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(staticKeyword)
    ..add(_fieldList)
    ..add(semicolon);

  @override
  Element? get declaredElement => null;

  @override
  Token get endToken => semicolon;

  @override
  VariableDeclarationListImpl get fields => _fieldList;

  set fields(VariableDeclarationList fields) {
    _fieldList = _becomeParentOf(fields as VariableDeclarationListImpl);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(abstractKeyword, externalKeyword,
            covariantKeyword, staticKeyword) ??
        _fieldList.beginToken;
  }

  @override
  bool get isStatic => staticKeyword != null;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFieldDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _fieldList.accept(visitor);
  }
}

/// A field formal parameter.
///
///    fieldFormalParameter ::=
///        ('final' [TypeName] | 'const' [TypeName] | 'var' | [TypeName])?
///        'this' '.' [SimpleIdentifier]
///        ([TypeParameterList]? [FormalParameterList])?
class FieldFormalParameterImpl extends NormalFormalParameterImpl
    implements FieldFormalParameter {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  /// The token representing the 'this' keyword.
  @override
  Token thisKeyword;

  /// The token representing the period.
  @override
  Token period;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters of the function-typed parameter, or `null` if this is not a
  /// function-typed field formal parameter.
  FormalParameterListImpl? _parameters;

  @override
  Token? question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if there is a type.
  /// The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
  /// [period] can be `null` if the keyword 'this' was not provided.  The
  /// [parameters] can be `null` if this is not a function-typed field formal
  /// parameter.
  FieldFormalParameterImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      Token? covariantKeyword,
      Token? requiredKeyword,
      this.keyword,
      this._type,
      this.thisKeyword,
      this.period,
      SimpleIdentifierImpl identifier,
      this._typeParameters,
      this._parameters,
      this.question)
      : super(
            comment, metadata, covariantKeyword, requiredKeyword, identifier) {
    _becomeParentOf(_type);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Token get beginToken {
    final metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken!;
    } else if (requiredKeyword != null) {
      return requiredKeyword!;
    } else if (covariantKeyword != null) {
      return covariantKeyword!;
    } else if (keyword != null) {
      return keyword!;
    } else if (_type != null) {
      return _type!.beginToken;
    }
    return thisKeyword;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..add(thisKeyword)
    ..add(period)
    ..add(identifier)
    ..add(_parameters);

  @override
  Token get endToken {
    return question ?? _parameters?.endToken ?? identifier.endToken;
  }

  @override
  SimpleIdentifierImpl get identifier => super.identifier!;

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterList? parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl?);
  }

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotation? type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFieldFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    identifier.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
  }
}

abstract class ForEachPartsImpl extends ForLoopPartsImpl
    implements ForEachParts {
  @override
  Token inKeyword;

  /// The expression evaluated to produce the iterator.
  ExpressionImpl _iterable;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared internally (in the for-loop part). The [awaitKeyword] can be
  /// `null` if this is not an asynchronous for loop.
  ForEachPartsImpl(this.inKeyword, this._iterable) {
    _becomeParentOf(_iterable);
  }

  @override
  Token get beginToken => inKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(inKeyword)
    ..add(_iterable);

  @override
  Token get endToken => _iterable.endToken;

  @override
  ExpressionImpl get iterable => _iterable;

  set iterable(Expression expression) {
    _iterable = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _iterable.accept(visitor);
  }
}

class ForEachPartsWithDeclarationImpl extends ForEachPartsImpl
    implements ForEachPartsWithDeclaration {
  /// The declaration of the loop variable.
  DeclaredIdentifierImpl _loopVariable;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared internally (inside the for-loop part).
  ForEachPartsWithDeclarationImpl(
      this._loopVariable, Token inKeyword, ExpressionImpl iterator)
      : super(inKeyword, iterator) {
    _becomeParentOf(_loopVariable);
  }

  @override
  Token get beginToken => _loopVariable.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_loopVariable)
    ..addAll(super.childEntities);

  @override
  DeclaredIdentifierImpl get loopVariable => _loopVariable;

  set loopVariable(DeclaredIdentifier variable) {
    _loopVariable = _becomeParentOf(variable as DeclaredIdentifierImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _loopVariable.accept(visitor);
    super.visitChildren(visitor);
  }
}

class ForEachPartsWithIdentifierImpl extends ForEachPartsImpl
    implements ForEachPartsWithIdentifier {
  /// The loop variable.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared externally (outside the for-loop part).
  ForEachPartsWithIdentifierImpl(
      this._identifier, Token inKeyword, ExpressionImpl iterator)
      : super(inKeyword, iterator) {
    _becomeParentOf(_identifier);
  }

  @override
  Token get beginToken => _identifier.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_identifier)
    ..addAll(super.childEntities);

  @override
  SimpleIdentifierImpl get identifier => _identifier;

  set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _identifier.accept(visitor);
    _iterable.accept(visitor);
  }
}

class ForElementImpl extends CollectionElementImpl implements ForElement {
  @override
  Token? awaitKeyword;

  @override
  Token forKeyword;

  @override
  Token leftParenthesis;

  ForLoopPartsImpl _forLoopParts;

  @override
  Token rightParenthesis;

  /// The body of the loop.
  CollectionElementImpl _body;

  /// Initialize a newly created for element.
  ForElementImpl(this.awaitKeyword, this.forKeyword, this.leftParenthesis,
      this._forLoopParts, this.rightParenthesis, this._body) {
    _becomeParentOf(_forLoopParts);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken => awaitKeyword ?? forKeyword;

  @override
  CollectionElementImpl get body => _body;

  set body(CollectionElement statement) {
    _body = _becomeParentOf(statement as CollectionElementImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(awaitKeyword)
    ..add(forKeyword)
    ..add(leftParenthesis)
    ..add(_forLoopParts)
    ..add(rightParenthesis)
    ..add(_body);

  @override
  Token get endToken => _body.endToken;

  @override
  ForLoopPartsImpl get forLoopParts => _forLoopParts;

  set forLoopParts(ForLoopParts forLoopParts) {
    _forLoopParts = _becomeParentOf(forLoopParts as ForLoopPartsImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForElement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _forLoopParts.accept(visitor);
    _body.accept(visitor);
  }
}

abstract class ForLoopPartsImpl extends AstNodeImpl implements ForLoopParts {}

/// A node representing a parameter to a function.
///
///    formalParameter ::=
///        [NormalFormalParameter]
///      | [DefaultFormalParameter]
abstract class FormalParameterImpl extends AstNodeImpl
    implements FormalParameter {
  @override
  ParameterElement? get declaredElement {
    final identifier = this.identifier;
    if (identifier == null) {
      return null;
    }
    return identifier.staticElement as ParameterElement?;
  }

  @override
  SimpleIdentifierImpl? get identifier;

  @override
  bool get isNamed => kind.isNamed;

  @override
  bool get isOptional => kind.isOptional;

  @override
  bool get isOptionalNamed => kind.isOptionalNamed;

  @override
  bool get isOptionalPositional => kind.isOptionalPositional;

  @override
  bool get isPositional => kind.isPositional;

  @override
  bool get isRequired => kind.isRequired;

  @override
  bool get isRequiredNamed => kind.isRequiredNamed;

  @override
  bool get isRequiredPositional => kind.isRequiredPositional;

  /// Return the kind of this parameter.
  ParameterKind get kind;

  static void setDeclaredElement(
    FormalParameterImpl node,
    ParameterElement element,
  ) {
    if (node is DefaultFormalParameterImpl) {
      setDeclaredElement(node.parameter, element);
    } else if (node is SimpleFormalParameterImpl) {
      node.declaredElement = element;
    } else {
      node.identifier!.staticElement = element;
    }
  }
}

/// The formal parameter list of a method declaration, function declaration, or
/// function type alias.
///
/// While the grammar requires all optional formal parameters to follow all of
/// the normal formal parameters and at most one grouping of optional formal
/// parameters, this class does not enforce those constraints. All parameters
/// are flattened into a single list, which can have any or all kinds of
/// parameters (normal, named, and positional) in any order.
///
///    formalParameterList ::=
///        '(' ')'
///      | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
///      | '(' optionalFormalParameters ')'
///
///    normalFormalParameters ::=
///        [NormalFormalParameter] (',' [NormalFormalParameter])*
///
///    optionalFormalParameters ::=
///        optionalPositionalFormalParameters
///      | namedFormalParameters
///
///    optionalPositionalFormalParameters ::=
///        '[' [DefaultFormalParameter] (',' [DefaultFormalParameter])* ']'
///
///    namedFormalParameters ::=
///        '{' [DefaultFormalParameter] (',' [DefaultFormalParameter])* '}'
class FormalParameterListImpl extends AstNodeImpl
    implements FormalParameterList {
  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The parameters associated with the method.
  final NodeListImpl<FormalParameter> _parameters = NodeListImpl._();

  /// The left square bracket ('[') or left curly brace ('{') introducing the
  /// optional parameters, or `null` if there are no optional parameters.
  @override
  Token? leftDelimiter;

  /// The right square bracket (']') or right curly brace ('}') terminating the
  /// optional parameters, or `null` if there are no optional parameters.
  @override
  Token? rightDelimiter;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// Initialize a newly created parameter list. The list of [parameters] can be
  /// `null` if there are no parameters. The [leftDelimiter] and
  /// [rightDelimiter] can be `null` if there are no optional parameters.
  FormalParameterListImpl(
      this.leftParenthesis,
      List<FormalParameter> parameters,
      this.leftDelimiter,
      this.rightDelimiter,
      this.rightParenthesis) {
    _parameters._initialize(this, parameters);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Iterable<SyntacticEntity> get childEntities {
    // TODO(paulberry): include commas.
    ChildEntities result = ChildEntities()..add(leftParenthesis);
    bool leftDelimiterNeeded = leftDelimiter != null;
    int length = _parameters.length;
    for (int i = 0; i < length; i++) {
      FormalParameter parameter = _parameters[i];
      if (leftDelimiterNeeded && leftDelimiter!.offset < parameter.offset) {
        result.add(leftDelimiter);
        leftDelimiterNeeded = false;
      }
      result.add(parameter);
    }
    return result
      ..add(rightDelimiter)
      ..add(rightParenthesis);
  }

  @override
  Token get endToken => rightParenthesis;

  @override
  List<ParameterElement?> get parameterElements {
    int count = _parameters.length;
    var types = <ParameterElement?>[];
    for (int i = 0; i < count; i++) {
      types.add(_parameters[i].declaredElement);
    }
    return types;
  }

  @override
  NodeListImpl<FormalParameter> get parameters => _parameters;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFormalParameterList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _parameters.accept(visitor);
  }
}

abstract class ForPartsImpl extends ForLoopPartsImpl implements ForParts {
  @override
  Token leftSeparator;

  /// The condition used to determine when to terminate the loop, or `null` if
  /// there is no condition.
  ExpressionImpl? _condition;

  @override
  Token rightSeparator;

  /// The list of expressions run after each execution of the loop body.
  final NodeListImpl<Expression> _updaters = NodeListImpl._();

  /// Initialize a newly created for statement. Either the [variableList] or the
  /// [initialization] must be `null`. Either the [condition] and the list of
  /// [updaters] can be `null` if the loop does not have the corresponding
  /// attribute.
  ForPartsImpl(this.leftSeparator, this._condition, this.rightSeparator,
      List<Expression>? updaters) {
    _becomeParentOf(_condition);
    _updaters._initialize(this, updaters);
  }

  @override
  Token get beginToken => leftSeparator;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftSeparator)
    ..add(_condition)
    ..add(rightSeparator)
    ..addAll(_updaters);

  @override
  ExpressionImpl? get condition => _condition;

  set condition(Expression? expression) {
    _condition = _becomeParentOf(expression as ExpressionImpl?);
  }

  @override
  Token get endToken => _updaters.endToken ?? rightSeparator;

  @override
  NodeListImpl<Expression> get updaters => _updaters;

  @override
  void visitChildren(AstVisitor visitor) {
    _condition?.accept(visitor);
    _updaters.accept(visitor);
  }
}

class ForPartsWithDeclarationsImpl extends ForPartsImpl
    implements ForPartsWithDeclarations {
  /// The declaration of the loop variables, or `null` if there are no
  /// variables.  Note that a for statement cannot have both a variable list and
  /// an initialization expression, but can validly have neither.
  VariableDeclarationListImpl _variableList;

  /// Initialize a newly created for statement. Both the [condition] and the
  /// list of [updaters] can be `null` if the loop does not have the
  /// corresponding attribute.
  ForPartsWithDeclarationsImpl(
      this._variableList,
      Token leftSeparator,
      ExpressionImpl? condition,
      Token rightSeparator,
      List<Expression>? updaters)
      : super(leftSeparator, condition, rightSeparator, updaters) {
    _becomeParentOf(_variableList);
  }

  @override
  Token get beginToken => _variableList.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_variableList)
    ..addAll(super.childEntities);

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationList? variableList) {
    _variableList =
        _becomeParentOf(variableList as VariableDeclarationListImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForPartsWithDeclarations(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _variableList.accept(visitor);
    super.visitChildren(visitor);
  }
}

class ForPartsWithExpressionImpl extends ForPartsImpl
    implements ForPartsWithExpression {
  /// The initialization expression, or `null` if there is no initialization
  /// expression. Note that a for statement cannot have both a variable list and
  /// an initialization expression, but can validly have neither.
  ExpressionImpl? _initialization;

  /// Initialize a newly created for statement. Both the [condition] and the
  /// list of [updaters] can be `null` if the loop does not have the
  /// corresponding attribute.
  ForPartsWithExpressionImpl(
      this._initialization,
      Token leftSeparator,
      ExpressionImpl? condition,
      Token rightSeparator,
      List<Expression>? updaters)
      : super(leftSeparator, condition, rightSeparator, updaters) {
    _becomeParentOf(_initialization);
  }

  @override
  Token get beginToken => initialization?.beginToken ?? super.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_initialization)
    ..addAll(super.childEntities);

  @override
  ExpressionImpl? get initialization => _initialization;

  set initialization(Expression? initialization) {
    _initialization = _becomeParentOf(initialization as ExpressionImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForPartsWithExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _initialization?.accept(visitor);
    super.visitChildren(visitor);
  }
}

class ForStatementImpl extends StatementImpl implements ForStatement {
  @override
  Token? awaitKeyword;

  @override
  Token forKeyword;

  @override
  Token leftParenthesis;

  ForLoopPartsImpl _forLoopParts;

  @override
  Token rightParenthesis;

  /// The body of the loop.
  StatementImpl _body;

  /// Initialize a newly created for statement.
  ForStatementImpl(this.awaitKeyword, this.forKeyword, this.leftParenthesis,
      this._forLoopParts, this.rightParenthesis, this._body) {
    _becomeParentOf(_forLoopParts);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken => awaitKeyword ?? forKeyword;

  @override
  StatementImpl get body => _body;

  set body(Statement statement) {
    _body = _becomeParentOf(statement as StatementImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(awaitKeyword)
    ..add(forKeyword)
    ..add(leftParenthesis)
    ..add(_forLoopParts)
    ..add(rightParenthesis)
    ..add(_body);

  @override
  Token get endToken => _body.endToken;

  @override
  ForLoopPartsImpl get forLoopParts => _forLoopParts;

  set forLoopParts(ForLoopParts forLoopParts) {
    _forLoopParts = _becomeParentOf(forLoopParts as ForLoopPartsImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _forLoopParts.accept(visitor);
    _body.accept(visitor);
  }
}

/// A node representing the body of a function or method.
///
///    functionBody ::=
///        [BlockFunctionBody]
///      | [EmptyFunctionBody]
///      | [ExpressionFunctionBody]
abstract class FunctionBodyImpl extends AstNodeImpl implements FunctionBody {
  /// Additional information about local variables and parameters that are
  /// declared within this function body or any enclosing function body.  `null`
  /// if resolution has not yet been performed.
  LocalVariableInfo? localVariableInfo;

  /// Return `true` if this function body is asynchronous.
  @override
  bool get isAsynchronous => false;

  /// Return `true` if this function body is a generator.
  @override
  bool get isGenerator => false;

  /// Return `true` if this function body is synchronous.
  @override
  bool get isSynchronous => true;

  /// Return the token representing the 'async' or 'sync' keyword, or `null` if
  /// there is no such keyword.
  @override
  Token? get keyword => null;

  /// Return the star following the 'async' or 'sync' keyword, or `null` if
  /// there is no star.
  @override
  Token? get star => null;

  @override
  bool isPotentiallyMutatedInClosure(VariableElement variable) {
    if (localVariableInfo == null) {
      throw StateError('Resolution has not yet been performed');
    }
    return localVariableInfo!.potentiallyMutatedInClosure.contains(variable);
  }

  @override
  bool isPotentiallyMutatedInScope(VariableElement variable) {
    if (localVariableInfo == null) {
      throw StateError('Resolution has not yet been performed');
    }
    return localVariableInfo!.potentiallyMutatedInScope.contains(variable);
  }
}

/// A top-level declaration.
///
///    functionDeclaration ::=
///        'external' functionSignature
///      | functionSignature [FunctionBody]
///
///    functionSignature ::=
///        [Type]? ('get' | 'set')? [SimpleIdentifier] [FormalParameterList]
class FunctionDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements FunctionDeclaration {
  /// The token representing the 'external' keyword, or `null` if this is not an
  /// external function.
  @override
  Token? externalKeyword;

  /// The return type of the function, or `null` if no return type was declared.
  TypeAnnotationImpl? _returnType;

  /// The token representing the 'get' or 'set' keyword, or `null` if this is a
  /// function declaration rather than a property declaration.
  @override
  Token? propertyKeyword;

  /// The function expression being wrapped.
  FunctionExpressionImpl _functionExpression;

  /// Initialize a newly created function declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [externalKeyword] can be `null` if the
  /// function is not an external function. The [returnType] can be `null` if no
  /// return type was specified. The [propertyKeyword] can be `null` if the
  /// function is neither a getter or a setter.
  FunctionDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.externalKeyword,
      this._returnType,
      this.propertyKeyword,
      SimpleIdentifierImpl name,
      this._functionExpression)
      : super(comment, metadata, name) {
    _becomeParentOf(_returnType);
    _becomeParentOf(_functionExpression);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(externalKeyword)
    ..add(_returnType)
    ..add(propertyKeyword)
    ..add(_name)
    ..add(_functionExpression);

  @override
  ExecutableElement? get declaredElement =>
      _name.staticElement as ExecutableElement?;

  @override
  Token get endToken => _functionExpression.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return externalKeyword ??
        _returnType?.beginToken ??
        propertyKeyword ??
        _name.beginToken;
  }

  @override
  FunctionExpressionImpl get functionExpression => _functionExpression;

  set functionExpression(FunctionExpression functionExpression) {
    _functionExpression =
        _becomeParentOf(functionExpression as FunctionExpressionImpl);
  }

  @override
  bool get isGetter => propertyKeyword?.keyword == Keyword.GET;

  @override
  bool get isSetter => propertyKeyword?.keyword == Keyword.SET;

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotation? type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _name.accept(visitor);
    _functionExpression.accept(visitor);
  }
}

/// A [FunctionDeclaration] used as a statement.
class FunctionDeclarationStatementImpl extends StatementImpl
    implements FunctionDeclarationStatement {
  /// The function declaration being wrapped.
  FunctionDeclarationImpl _functionDeclaration;

  /// Initialize a newly created function declaration statement.
  FunctionDeclarationStatementImpl(this._functionDeclaration) {
    _becomeParentOf(_functionDeclaration);
  }

  @override
  Token get beginToken => _functionDeclaration.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_functionDeclaration);

  @override
  Token get endToken => _functionDeclaration.endToken;

  @override
  FunctionDeclarationImpl get functionDeclaration => _functionDeclaration;

  set functionDeclaration(FunctionDeclaration functionDeclaration) {
    _functionDeclaration =
        _becomeParentOf(functionDeclaration as FunctionDeclarationImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _functionDeclaration.accept(visitor);
  }
}

/// A function expression.
///
///    functionExpression ::=
///        [TypeParameterList]? [FormalParameterList] [FunctionBody]
class FunctionExpressionImpl extends ExpressionImpl
    implements FunctionExpression {
  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters associated with the function, or `null` if the function is
  /// part of a top-level getter.
  FormalParameterListImpl? _parameters;

  /// The body of the function.
  FunctionBodyImpl _body;

  @override
  ExecutableElement? declaredElement;

  /// Initialize a newly created function declaration.
  FunctionExpressionImpl(this._typeParameters, this._parameters, this._body) {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken {
    if (_typeParameters != null) {
      return _typeParameters!.beginToken;
    } else if (_parameters != null) {
      return _parameters!.beginToken;
    }
    return _body.beginToken;
  }

  @override
  FunctionBodyImpl get body => _body;

  set body(FunctionBody functionBody) {
    _body = _becomeParentOf(functionBody as FunctionBodyImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_typeParameters)
    ..add(_parameters)
    ..add(_body);

  @override
  Token get endToken {
    return _body.endToken;
  }

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterList? parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl?);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
    _body.accept(visitor);
  }
}

/// The invocation of a function resulting from evaluating an expression.
/// Invocations of methods and other forms of functions are represented by
/// [MethodInvocation] nodes. Invocations of getters and setters are represented
/// by either [PrefixedIdentifier] or [PropertyAccess] nodes.
///
///    functionExpressionInvocation ::=
///        [Expression] [TypeArgumentList]? [ArgumentList]
class FunctionExpressionInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl
    implements FunctionExpressionInvocation {
  /// The expression producing the function being invoked.
  ExpressionImpl _function;

  /// The element associated with the function being invoked based on static
  /// type information, or `null` if the AST structure has not been resolved or
  /// the function could not be resolved.
  @override
  ExecutableElement? staticElement;

  /// Initialize a newly created function expression invocation.
  FunctionExpressionInvocationImpl(this._function,
      TypeArgumentListImpl? typeArguments, ArgumentListImpl argumentList)
      : super(typeArguments, argumentList) {
    _becomeParentOf(_function);
  }

  @override
  Token get beginToken => _function.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_function)
    ..add(_argumentList);

  @override
  Token get endToken => _argumentList.endToken;

  @override
  ExpressionImpl get function => _function;

  set function(Expression expression) {
    _function = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionExpressionInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _function.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) => identical(child, _function);
}

/// An expression representing a reference to a function, possibly with type
/// arguments applied to it, e.g. the expression `print` in `var x = print;`.
class FunctionReferenceImpl extends CommentReferableExpressionImpl
    implements FunctionReference {
  ExpressionImpl _function;

  TypeArgumentListImpl? _typeArguments;

  @override
  List<DartType>? typeArgumentTypes;

  FunctionReferenceImpl(this._function, {TypeArgumentListImpl? typeArguments})
      : _typeArguments = typeArguments {
    _becomeParentOf(_function);
    _becomeParentOf(_typeArguments);
  }

  @override
  Token get beginToken => function.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(function)
    ..add(typeArguments);

  @override
  Token get endToken => typeArguments?.endToken ?? function.endToken;

  @override
  ExpressionImpl get function => _function;

  set function(ExpressionImpl value) {
    _function = _becomeParentOf(value);
  }

  @override
  Precedence get precedence =>
      typeArguments == null ? function.precedence : Precedence.postfix;

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? value) {
    _typeArguments = _becomeParentOf(value);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionReference(this);

  @override
  void visitChildren(AstVisitor visitor) {
    function.accept(visitor);
    typeArguments?.accept(visitor);
  }
}

/// A function type alias.
///
///    functionTypeAlias ::=
///        functionPrefix [TypeParameterList]? [FormalParameterList] ';'
///
///    functionPrefix ::=
///        [TypeName]? [SimpleIdentifier]
class FunctionTypeAliasImpl extends TypeAliasImpl implements FunctionTypeAlias {
  /// The name of the return type of the function type being defined, or `null`
  /// if no return type was given.
  TypeAnnotationImpl? _returnType;

  /// The type parameters for the function type, or `null` if the function type
  /// does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The parameters associated with the function type.
  FormalParameterListImpl _parameters;

  /// Initialize a newly created function type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [returnType] can be `null` if no return type
  /// was specified. The [typeParameters] can be `null` if the function has no
  /// type parameters.
  FunctionTypeAliasImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      Token keyword,
      this._returnType,
      SimpleIdentifierImpl name,
      this._typeParameters,
      this._parameters,
      Token semicolon)
      : super(comment, metadata, keyword, name, semicolon) {
    _becomeParentOf(_returnType);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(typedefKeyword)
    ..add(_returnType)
    ..add(_name)
    ..add(_typeParameters)
    ..add(_parameters)
    ..add(semicolon);

  @override
  TypeAliasElement? get declaredElement =>
      _name.staticElement as TypeAliasElement?;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotation? type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl?);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _name.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters.accept(visitor);
  }
}

/// A function-typed formal parameter.
///
///    functionSignature ::=
///        [TypeName]? [SimpleIdentifier] [TypeParameterList]?
///        [FormalParameterList] '?'?
class FunctionTypedFormalParameterImpl extends NormalFormalParameterImpl
    implements FunctionTypedFormalParameter {
  /// The return type of the function, or `null` if the function does not have a
  /// return type.
  TypeAnnotationImpl? _returnType;

  /// The type parameters associated with the function, or `null` if the
  /// function is not a generic function.
  TypeParameterListImpl? _typeParameters;

  /// The parameters of the function-typed parameter.
  FormalParameterListImpl _parameters;

  @override
  Token? question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [returnType] can be `null` if no return type
  /// was specified.
  FunctionTypedFormalParameterImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      Token? covariantKeyword,
      Token? requiredKeyword,
      this._returnType,
      SimpleIdentifierImpl identifier,
      this._typeParameters,
      this._parameters,
      this.question)
      : super(
            comment, metadata, covariantKeyword, requiredKeyword, identifier) {
    _becomeParentOf(_returnType);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Token get beginToken {
    final metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken!;
    } else if (requiredKeyword != null) {
      return requiredKeyword!;
    } else if (covariantKeyword != null) {
      return covariantKeyword!;
    } else if (_returnType != null) {
      return _returnType!.beginToken;
    }
    return identifier.beginToken;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(_returnType)
    ..add(identifier)
    ..add(parameters);

  @override
  Token get endToken => question ?? _parameters.endToken;

  @override
  SimpleIdentifierImpl get identifier => super.identifier!;

  @override
  bool get isConst => false;

  @override
  bool get isFinal => false;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotation? type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl?);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionTypedFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    identifier.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters.accept(visitor);
  }
}

/// An anonymous function type.
///
///    functionType ::=
///        [TypeAnnotation]? 'Function' [TypeParameterList]?
///        [FormalParameterList]
///
/// where the FormalParameterList is being used to represent the following
/// grammar, despite the fact that FormalParameterList can represent a much
/// larger grammar than the one below. This is done in order to simplify the
/// implementation.
///
///    parameterTypeList ::=
///        () |
///        ( normalParameterTypes ,? ) |
///        ( normalParameterTypes , optionalParameterTypes ) |
///        ( optionalParameterTypes )
///    namedParameterTypes ::=
///        { namedParameterType (, namedParameterType)* ,? }
///    namedParameterType ::=
///        [TypeAnnotation]? [SimpleIdentifier]
///    normalParameterTypes ::=
///        normalParameterType (, normalParameterType)*
///    normalParameterType ::=
///        [TypeAnnotation] [SimpleIdentifier]?
///    optionalParameterTypes ::=
///        optionalPositionalParameterTypes | namedParameterTypes
///    optionalPositionalParameterTypes ::=
///        [ normalParameterTypes ,? ]
class GenericFunctionTypeImpl extends TypeAnnotationImpl
    implements GenericFunctionType {
  /// The name of the return type of the function type being defined, or
  /// `null` if no return type was given.
  TypeAnnotationImpl? _returnType;

  @override
  Token functionKeyword;

  /// The type parameters for the function type, or `null` if the function type
  /// does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The parameters associated with the function type.
  FormalParameterListImpl _parameters;

  @override
  Token? question;

  @override
  DartType? type;

  /// Return the element associated with the function type, or `null` if the
  /// AST structure has not been resolved.
  GenericFunctionTypeElement? declaredElement;

  /// Initialize a newly created generic function type.
  GenericFunctionTypeImpl(this._returnType, this.functionKeyword,
      this._typeParameters, this._parameters,
      {this.question}) {
    _becomeParentOf(_returnType);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Token get beginToken => _returnType?.beginToken ?? functionKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_returnType)
    ..add(functionKeyword)
    ..add(_typeParameters)
    ..add(_parameters)
    ..add(question);

  @override
  Token get endToken => question ?? _parameters.endToken;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotation? type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl?);
  }

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  /// Set the type parameters for the function type to the given list of
  /// [typeParameters].
  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitGenericFunctionType(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _returnType?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters.accept(visitor);
  }
}

/// A generic type alias.
///
///    functionTypeAlias ::=
///        metadata 'typedef' [SimpleIdentifier] [TypeParameterList]? =
///        [FunctionType] ';'
class GenericTypeAliasImpl extends TypeAliasImpl implements GenericTypeAlias {
  /// The type being defined by the alias.
  TypeAnnotationImpl _type;

  /// The type parameters for the function type, or `null` if the function
  /// type does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  @override
  Token equals;

  /// Returns a newly created generic type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the variable list does not have
  /// the corresponding attribute. The [typeParameters] can be `null` if there
  /// are no type parameters.
  GenericTypeAliasImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      Token typedefToken,
      SimpleIdentifierImpl name,
      this._typeParameters,
      this.equals,
      this._type,
      Token semicolon)
      : super(comment, metadata, typedefToken, name, semicolon) {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_type);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(metadata)
    ..add(typedefKeyword)
    ..add(name)
    ..add(_typeParameters)
    ..add(equals)
    ..add(_type);

  @override
  Element? get declaredElement => name.staticElement;

  /// The type of function being defined by the alias.
  ///
  /// If the non-function type aliases feature is enabled, a type alias may have
  /// a [_type] which is not a [GenericFunctionTypeImpl].  In that case `null`
  /// is returned.
  @override
  GenericFunctionType? get functionType {
    var type = _type;
    return type is GenericFunctionTypeImpl ? type : null;
  }

  set functionType(GenericFunctionType? functionType) {
    _type = _becomeParentOf(functionType as GenericFunctionTypeImpl?)!;
  }

  @override
  TypeAnnotationImpl get type => _type;

  /// Set the type being defined by the alias to the given [TypeAnnotation].
  set type(TypeAnnotation typeAnnotation) {
    _type = _becomeParentOf(typeAnnotation as TypeAnnotationImpl);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitGenericTypeAlias(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    name.accept(visitor);
    _typeParameters?.accept(visitor);
    _type.accept(visitor);
  }
}

/// The "hide" clause in an extension declaration.
///
///    hideClause ::=
///        'hide' [TypeName] (',' [TypeName])*
class HideClauseImpl extends AstNodeImpl implements HideClause {
  /// The token representing the 'hide' keyword.
  @override
  Token hideKeyword;

  /// The elements that are being shown.
  final NodeListImpl<ShowHideClauseElement> _elements = NodeListImpl._();

  /// Initialize a newly created show clause.
  HideClauseImpl(this.hideKeyword, List<ShowHideClauseElement> elements) {
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken => hideKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(hideKeyword)
    ..addAll(elements);

  @override
  NodeListImpl<ShowHideClauseElement> get elements => _elements;

  @override
  Token get endToken => _elements.endToken!;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitHideClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _elements.accept(visitor);
  }
}

/// A combinator that restricts the names being imported to those that are not
/// in a given list.
///
///    hideCombinator ::=
///        'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
class HideCombinatorImpl extends CombinatorImpl implements HideCombinator {
  /// The list of names from the library that are hidden by this combinator.
  final NodeListImpl<SimpleIdentifier> _hiddenNames = NodeListImpl._();

  /// Initialize a newly created import show combinator.
  HideCombinatorImpl(Token keyword, List<SimpleIdentifier> hiddenNames)
      : super(keyword) {
    _hiddenNames._initialize(this, hiddenNames);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(keyword)
    ..addAll(_hiddenNames);

  @override
  Token get endToken => _hiddenNames.endToken!;

  @override
  NodeListImpl<SimpleIdentifier> get hiddenNames => _hiddenNames;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitHideCombinator(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _hiddenNames.accept(visitor);
  }
}

/// A node that represents an identifier.
///
///    identifier ::=
///        [SimpleIdentifier]
///      | [PrefixedIdentifier]
abstract class IdentifierImpl extends CommentReferableExpressionImpl
    implements Identifier {
  @override
  bool get isAssignable => true;
}

class IfElementImpl extends CollectionElementImpl implements IfElement {
  @override
  Token ifKeyword;

  @override
  Token leftParenthesis;

  /// The condition used to determine which of the branches is executed next.
  ExpressionImpl _condition;

  @override
  Token rightParenthesis;

  @override
  Token? elseKeyword;

  /// The element to be executed if the condition is `true`.
  CollectionElementImpl _thenElement;

  /// The element to be executed if the condition is `false`, or `null` if there
  /// is no such element.
  CollectionElementImpl? _elseElement;

  /// Initialize a newly created for element.
  IfElementImpl(
      this.ifKeyword,
      this.leftParenthesis,
      this._condition,
      this.rightParenthesis,
      this._thenElement,
      this.elseKeyword,
      this._elseElement) {
    _becomeParentOf(_condition);
    _becomeParentOf(_thenElement);
    _becomeParentOf(_elseElement);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(ifKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(_thenElement)
    ..add(elseKeyword)
    ..add(_elseElement);

  @override
  ExpressionImpl get condition => _condition;

  set condition(Expression condition) {
    _condition = _becomeParentOf(condition as ExpressionImpl);
  }

  @override
  CollectionElement? get elseElement => _elseElement;

  set elseElement(CollectionElement? element) {
    _elseElement = _becomeParentOf(element as CollectionElementImpl?);
  }

  @override
  Token get endToken => _elseElement?.endToken ?? _thenElement.endToken;

  @override
  CollectionElementImpl get thenElement => _thenElement;

  set thenElement(CollectionElement element) {
    _thenElement = _becomeParentOf(element as CollectionElementImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIfElement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    _thenElement.accept(visitor);
    _elseElement?.accept(visitor);
  }
}

/// An if statement.
///
///    ifStatement ::=
///        'if' '(' [Expression] ')' [Statement] ('else' [Statement])?
class IfStatementImpl extends StatementImpl implements IfStatement {
  @override
  Token ifKeyword;

  @override
  Token leftParenthesis;

  /// The condition used to determine which of the branches is executed next.
  ExpressionImpl _condition;

  @override
  Token rightParenthesis;

  @override
  Token? elseKeyword;

  /// The statement that is executed if the condition evaluates to `true`.
  StatementImpl _thenStatement;

  /// The statement that is executed if the condition evaluates to `false`, or
  /// `null` if there is no else statement.
  StatementImpl? _elseStatement;

  /// Initialize a newly created if statement. The [elseKeyword] and
  /// [elseStatement] can be `null` if there is no else clause.
  IfStatementImpl(
      this.ifKeyword,
      this.leftParenthesis,
      this._condition,
      this.rightParenthesis,
      this._thenStatement,
      this.elseKeyword,
      this._elseStatement) {
    _becomeParentOf(_condition);
    _becomeParentOf(_thenStatement);
    _becomeParentOf(_elseStatement);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(ifKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(_thenStatement)
    ..add(elseKeyword)
    ..add(_elseStatement);

  @override
  ExpressionImpl get condition => _condition;

  set condition(Expression condition) {
    _condition = _becomeParentOf(condition as ExpressionImpl);
  }

  @override
  StatementImpl? get elseStatement => _elseStatement;

  set elseStatement(Statement? statement) {
    _elseStatement = _becomeParentOf(statement as StatementImpl?);
  }

  @override
  Token get endToken {
    if (_elseStatement != null) {
      return _elseStatement!.endToken;
    }
    return _thenStatement.endToken;
  }

  @override
  StatementImpl get thenStatement => _thenStatement;

  set thenStatement(Statement statement) {
    _thenStatement = _becomeParentOf(statement as StatementImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIfStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    _thenStatement.accept(visitor);
    _elseStatement?.accept(visitor);
  }
}

/// The "implements" clause in an class declaration.
///
///    implementsClause ::=
///        'implements' [TypeName] (',' [TypeName])*
class ImplementsClauseImpl extends AstNodeImpl implements ImplementsClause {
  /// The token representing the 'implements' keyword.
  @override
  Token implementsKeyword;

  /// The interfaces that are being implemented.
  final NodeListImpl<NamedType> _interfaces = NodeListImpl._();

  /// Initialize a newly created implements clause.
  ImplementsClauseImpl(this.implementsKeyword, List<NamedType> interfaces) {
    _interfaces._initialize(this, interfaces);
  }

  @override
  Token get beginToken => implementsKeyword;

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(implementsKeyword)
    ..addAll(interfaces2);

  @override
  Token get endToken => _interfaces.endToken!;

  @Deprecated('Use interfaces2 instead')
  @override
  NodeList<TypeName> get interfaces => _DelegatingTypeNameList(_interfaces);

  @override
  NodeListImpl<NamedType> get interfaces2 => _interfaces;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitImplementsClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _interfaces.accept(visitor);
  }
}

class ImplicitCallReferenceImpl extends ExpressionImpl
    implements ImplicitCallReference {
  ExpressionImpl _expression;

  TypeArgumentListImpl? _typeArguments;

  @override
  List<DartType> typeArgumentTypes;

  @override
  MethodElement staticElement;

  ImplicitCallReferenceImpl(
    this._expression, {
    required this.staticElement,
    required TypeArgumentListImpl? typeArguments,
    required this.typeArgumentTypes,
  }) : _typeArguments = typeArguments {
    _becomeParentOf(_expression);
    _becomeParentOf(_typeArguments);
  }

  @override
  Token get beginToken => expression.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(expression)
    ..add(typeArguments);

  @override
  Token get endToken => typeArguments?.endToken ?? expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl value) {
    _expression = _becomeParentOf(value);
  }

  @override
  Precedence get precedence =>
      typeArguments == null ? expression.precedence : Precedence.postfix;

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? value) {
    _typeArguments = _becomeParentOf(value);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitImplicitCallReference(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    typeArguments?.accept(visitor);
  }
}

/// An import directive.
///
///    importDirective ::=
///        [Annotation] 'import' [StringLiteral] ('as' identifier)?
//         [Combinator]* ';'
///      | [Annotation] 'import' [StringLiteral] 'deferred' 'as' identifier
//         [Combinator]* ';'
class ImportDirectiveImpl extends NamespaceDirectiveImpl
    implements ImportDirective {
  /// The token representing the 'deferred' keyword, or `null` if the imported
  /// is not deferred.
  @override
  Token? deferredKeyword;

  /// The token representing the 'as' keyword, or `null` if the imported names
  /// are not prefixed.
  @override
  Token? asKeyword;

  /// The prefix to be used with the imported names, or `null` if the imported
  /// names are not prefixed.
  SimpleIdentifierImpl? _prefix;

  /// Initialize a newly created import directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [deferredKeyword] can be `null` if the import
  /// is not deferred. The [asKeyword] and [prefix] can be `null` if the import
  /// does not specify a prefix. The list of [combinators] can be `null` if
  /// there are no combinators.
  ImportDirectiveImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      Token keyword,
      StringLiteralImpl libraryUri,
      List<Configuration>? configurations,
      this.deferredKeyword,
      this.asKeyword,
      this._prefix,
      List<Combinator>? combinators,
      Token semicolon)
      : super(comment, metadata, keyword, libraryUri, configurations,
            combinators, semicolon) {
    _becomeParentOf(_prefix);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_uri)
    ..add(deferredKeyword)
    ..add(asKeyword)
    ..add(_prefix)
    ..addAll(combinators)
    ..add(semicolon);

  @override
  ImportElement? get element => super.element as ImportElement?;

  @override
  SimpleIdentifierImpl? get prefix => _prefix;

  set prefix(SimpleIdentifier? identifier) {
    _prefix = _becomeParentOf(identifier as SimpleIdentifierImpl?);
  }

  @override
  LibraryElement? get uriElement {
    return element?.importedLibrary;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitImportDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    configurations.accept(visitor);
    _prefix?.accept(visitor);
    combinators.accept(visitor);
  }
}

/// An index expression.
///
///    indexExpression ::=
///        [Expression] '[' [Expression] ']'
class IndexExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements IndexExpression {
  @override
  Token? period;

  /// The expression used to compute the object being indexed, or `null` if this
  /// index expression is part of a cascade expression.
  ExpressionImpl? _target;

  @override
  Token? question;

  @override
  Token leftBracket;

  /// The expression used to compute the index.
  ExpressionImpl _index;

  @override
  Token rightBracket;

  /// The element associated with the operator based on the static type of the
  /// target, or `null` if the AST structure has not been resolved or if the
  /// operator could not be resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created index expression that is a child of a cascade
  /// expression.
  IndexExpressionImpl.forCascade(this.period, this.question, this.leftBracket,
      this._index, this.rightBracket) {
    _becomeParentOf(_index);
  }

  /// Initialize a newly created index expression that is not a child of a
  /// cascade expression.
  IndexExpressionImpl.forTarget(this._target, this.question, this.leftBracket,
      this._index, this.rightBracket) {
    _becomeParentOf(_target);
    _becomeParentOf(_index);
  }

  @override
  Token get beginToken {
    if (_target != null) {
      return _target!.beginToken;
    }
    return period!;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_target)
    ..add(period)
    ..add(leftBracket)
    ..add(_index)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  ExpressionImpl get index => _index;

  set index(Expression expression) {
    _index = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  bool get isAssignable => true;

  @override
  bool get isCascaded => period != null;

  @override
  bool get isNullAware {
    if (isCascaded) {
      return _ancestorCascade.isNullAware;
    }
    return question != null ||
        (leftBracket.type == TokenType.OPEN_SQUARE_BRACKET &&
            period != null &&
            period!.type == TokenType.QUESTION_PERIOD_PERIOD);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ExpressionImpl get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target!;
  }

  @override
  ExpressionImpl? get target => _target;

  set target(Expression? expression) {
    _target = _becomeParentOf(expression as ExpressionImpl?);
  }

  /// Return the cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpressionImpl get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent!;; ancestor = ancestor.parent!) {
      if (ancestor is CascadeExpressionImpl) {
        return ancestor;
      }
    }
  }

  @override
  AstNode get _nullShortingExtensionCandidate => parent!;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the index expression will
  /// be bound. Otherwise, return `null`.
  ParameterElement? get _staticParameterElementForIndex {
    Element? element = staticElement;

    final parent = this.parent;
    if (parent is CompoundAssignmentExpression) {
      element = parent.writeElement ?? parent.readElement;
    }

    if (element is ExecutableElement) {
      List<ParameterElement> parameters = element.parameters;
      if (parameters.isEmpty) {
        return null;
      }
      return parameters[0];
    }
    return null;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIndexExpression(this);

  @override
  bool inGetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    final parent = this.parent!;
    if (parent is AssignmentExpression) {
      AssignmentExpression assignment = parent;
      if (identical(assignment.leftHandSide, this) &&
          assignment.operator.type == TokenType.EQ) {
        return false;
      }
    }
    return true;
  }

  @override
  bool inSetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    final parent = this.parent!;
    if (parent is PrefixExpression) {
      return parent.operator.type.isIncrementOperator;
    } else if (parent is PostfixExpression) {
      return parent.operator.type.isIncrementOperator;
    } else if (parent is AssignmentExpression) {
      return identical(parent.leftHandSide, this);
    }
    return false;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _index.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) => identical(child, _target);
}

/// An instance creation expression.
///
///    newExpression ::=
///        ('new' | 'const')? [TypeName] ('.' [SimpleIdentifier])?
///        [ArgumentList]
class InstanceCreationExpressionImpl extends ExpressionImpl
    implements InstanceCreationExpression {
  // TODO(brianwilkerson) Consider making InstanceCreationExpressionImpl extend
  // InvocationExpressionImpl. This would probably be a breaking change, but is
  // also probably worth it.

  /// The 'new' or 'const' keyword used to indicate how an object should be
  /// created, or `null` if the keyword is implicit.
  @override
  Token? keyword;

  /// The name of the constructor to be invoked.
  ConstructorNameImpl _constructorName;

  /// The type arguments associated with the constructor, rather than with the
  /// class in which the constructor is defined. It is always an error if there
  /// are type arguments because Dart doesn't currently support generic
  /// constructors, but we capture them in the AST in order to recover better.
  TypeArgumentListImpl? _typeArguments;

  /// The list of arguments to the constructor.
  ArgumentListImpl _argumentList;

  /// Initialize a newly created instance creation expression.
  InstanceCreationExpressionImpl(
      this.keyword, this._constructorName, this._argumentList,
      {TypeArgumentListImpl? typeArguments})
      : _typeArguments = typeArguments {
    _becomeParentOf(_constructorName);
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  Token get beginToken => keyword ?? _constructorName.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(keyword)
    ..add(_constructorName)
    ..add(_typeArguments)
    ..add(_argumentList);

  @override
  ConstructorNameImpl get constructorName => _constructorName;

  set constructorName(ConstructorName name) {
    _constructorName = _becomeParentOf(name as ConstructorNameImpl);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  bool get isConst {
    if (!isImplicit) {
      return keyword!.keyword == Keyword.CONST;
    } else {
      return inConstantContext;
    }
  }

  /// Return `true` if this is an implicit constructor invocations.
  bool get isImplicit => keyword == null;

  @override
  Precedence get precedence => Precedence.primary;

  /// Return the type arguments associated with the constructor, rather than
  /// with the class in which the constructor is defined. It is always an error
  /// if there are type arguments because Dart doesn't currently support generic
  /// constructors, but we capture them in the AST in order to recover better.
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  /// Return the type arguments associated with the constructor, rather than
  /// with the class in which the constructor is defined. It is always an error
  /// if there are type arguments because Dart doesn't currently support generic
  /// constructors, but we capture them in the AST in order to recover better.
  set typeArguments(TypeArgumentList? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitInstanceCreationExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
  }
}

/// An integer literal expression.
///
///    integerLiteral ::=
///        decimalIntegerLiteral
///      | hexadecimalIntegerLiteral
///
///    decimalIntegerLiteral ::=
///        decimalDigit+
///
///    hexadecimalIntegerLiteral ::=
///        '0x' hexadecimalDigit+
///      | '0X' hexadecimalDigit+
class IntegerLiteralImpl extends LiteralImpl implements IntegerLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// The value of the literal.
  @override
  int? value = 0;

  /// Initialize a newly created integer literal.
  IntegerLiteralImpl(this.literal, this.value);

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  /// Returns whether this literal's [parent] is a [PrefixExpression] of unary
  /// negation.
  ///
  /// Note: this does *not* indicate that the value itself is negated, just that
  /// the literal is the child of a negation operation. The literal value itself
  /// will always be positive.
  bool get immediatelyNegated {
    final parent = this.parent!;
    return parent is PrefixExpression &&
        parent.operator.type == TokenType.MINUS;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIntegerLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }

  static bool isValidAsDouble(String lexeme) {
    // Less than 16 characters must be a valid double since it will be less than
    // 9007199254740992, 0x10000000000000, both 16 characters and 53 bits.
    if (lexeme.length < 16) {
      return true;
    }

    var fullPrecision = BigInt.tryParse(lexeme);
    if (fullPrecision == null) {
      return false;
    }

    // Usually handled by the length check, however, we must check this before
    // constructing a mask later, or we'd get a negative-shift runtime error.
    int bitLengthAsInt = fullPrecision.bitLength;
    if (bitLengthAsInt <= 53) {
      return true;
    }

    // This would overflow the exponent (larger than maximum double).
    if (fullPrecision > BigInt.from(double.maxFinite)) {
      return false;
    }

    // Say [lexeme] uses 100 bits as an integer. The bottom 47 must be 0s -- so
    // construct a mask of 47 ones, via of 2^n - 1 where n is 47.
    BigInt bottomMask = (BigInt.one << (bitLengthAsInt - 53)) - BigInt.one;

    return fullPrecision & bottomMask == BigInt.zero;
  }

  /// Return `true` if the given [lexeme] is a valid lexeme for an integer
  /// literal. The flag [isNegative] should be `true` if the lexeme is preceded
  /// by a unary negation operator.
  static bool isValidAsInteger(String lexeme, bool isNegative) {
    // TODO(jmesserly): this depends on the platform int implementation, and
    // may not be accurate if run on dart4web.
    //
    // (Prior to https://dart-review.googlesource.com/c/sdk/+/63023 there was
    // a partial implementation here which may be a good starting point.
    // _isValidDecimalLiteral relied on int.parse so that would need some fixes.
    // _isValidHexadecimalLiteral worked except for negative int64 max.)
    if (isNegative) lexeme = '-$lexeme';
    return int.tryParse(lexeme) != null;
  }

  /// Suggest the nearest valid double to a user. If the integer they wrote
  /// requires more than a 53 bit mantissa, or more than 10 exponent bits, do
  /// them the favor of suggesting the nearest integer that would work for them.
  static double nearestValidDouble(String lexeme) =>
      math.min(double.maxFinite, BigInt.parse(lexeme).toDouble());
}

/// A node within a [StringInterpolation].
///
///    interpolationElement ::=
///        [InterpolationExpression]
///      | [InterpolationString]
abstract class InterpolationElementImpl extends AstNodeImpl
    implements InterpolationElement {}

/// An expression embedded in a string interpolation.
///
///    interpolationExpression ::=
///        '$' [SimpleIdentifier]
///      | '$' '{' [Expression] '}'
class InterpolationExpressionImpl extends InterpolationElementImpl
    implements InterpolationExpression {
  /// The token used to introduce the interpolation expression; either '$' if
  /// the expression is a simple identifier or '${' if the expression is a full
  /// expression.
  @override
  Token leftBracket;

  /// The expression to be evaluated for the value to be converted into a
  /// string.
  ExpressionImpl _expression;

  /// The right curly bracket, or `null` if the expression is an identifier
  /// without brackets.
  @override
  Token? rightBracket;

  /// Initialize a newly created interpolation expression.
  InterpolationExpressionImpl(
      this.leftBracket, this._expression, this.rightBracket) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftBracket)
    ..add(_expression)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket ?? _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitInterpolationExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A non-empty substring of an interpolated string.
///
///    interpolationString ::=
///        characters
class InterpolationStringImpl extends InterpolationElementImpl
    implements InterpolationString {
  /// The characters that will be added to the string.
  @override
  Token contents;

  /// The value of the literal.
  @override
  String value;

  /// Initialize a newly created string of characters that are part of a string
  /// interpolation.
  InterpolationStringImpl(this.contents, this.value);

  @override
  Token get beginToken => contents;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(contents);

  @override
  int get contentsEnd => offset + _lexemeHelper.end;

  @override
  int get contentsOffset => contents.offset + _lexemeHelper.start;

  @override
  Token get endToken => contents;

  @override
  StringInterpolation get parent => super.parent as StringInterpolation;

  StringLexemeHelper get _lexemeHelper {
    String lexeme = contents.lexeme;
    return StringLexemeHelper(lexeme, identical(this, parent.elements.first),
        identical(this, parent.elements.last));
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitInterpolationString(this);

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// Common base class for [FunctionExpressionInvocationImpl] and
/// [MethodInvocationImpl].
abstract class InvocationExpressionImpl extends ExpressionImpl
    implements InvocationExpression {
  /// The list of arguments to the function.
  ArgumentListImpl _argumentList;

  /// The type arguments to be applied to the method being invoked, or `null` if
  /// no type arguments were provided.
  TypeArgumentListImpl? _typeArguments;

  @override
  List<DartType>? typeArgumentTypes;

  @override
  DartType? staticInvokeType;

  /// Initialize a newly created invocation.
  InvocationExpressionImpl(this._typeArguments, this._argumentList) {
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentList? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl?);
  }
}

/// An is expression.
///
///    isExpression ::=
///        [Expression] 'is' '!'? [TypeName]
class IsExpressionImpl extends ExpressionImpl implements IsExpression {
  /// The expression used to compute the value whose type is being tested.
  ExpressionImpl _expression;

  /// The is operator.
  @override
  Token isOperator;

  /// The not operator, or `null` if the sense of the test is not negated.
  @override
  Token? notOperator;

  /// The name of the type being tested for.
  TypeAnnotationImpl _type;

  /// Initialize a newly created is expression. The [notOperator] can be `null`
  /// if the sense of the test is not negated.
  IsExpressionImpl(
      this._expression, this.isOperator, this.notOperator, this._type) {
    _becomeParentOf(_expression);
    _becomeParentOf(_type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_expression)
    ..add(isOperator)
    ..add(notOperator)
    ..add(_type);

  @override
  Token get endToken => _type.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @override
  TypeAnnotationImpl get type => _type;

  set type(TypeAnnotation type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIsExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
    _type.accept(visitor);
  }
}

/// A statement that has a label associated with them.
///
///    labeledStatement ::=
///       [Label]+ [Statement]
class LabeledStatementImpl extends StatementImpl implements LabeledStatement {
  /// The labels being associated with the statement.
  final NodeListImpl<Label> _labels = NodeListImpl._();

  /// The statement with which the labels are being associated.
  StatementImpl _statement;

  /// Initialize a newly created labeled statement.
  LabeledStatementImpl(List<Label> labels, this._statement) {
    _labels._initialize(this, labels);
    _becomeParentOf(_statement);
  }

  @override
  Token get beginToken {
    if (_labels.isNotEmpty) {
      return _labels.beginToken!;
    }
    return _statement.beginToken;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(_labels)
    ..add(_statement);

  @override
  Token get endToken => _statement.endToken;

  @override
  NodeListImpl<Label> get labels => _labels;

  @override
  StatementImpl get statement => _statement;

  set statement(Statement statement) {
    _statement = _becomeParentOf(statement as StatementImpl);
  }

  @override
  StatementImpl get unlabeled => _statement.unlabeled;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLabeledStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _labels.accept(visitor);
    _statement.accept(visitor);
  }
}

/// A label on either a [LabeledStatement] or a [NamedExpression].
///
///    label ::=
///        [SimpleIdentifier] ':'
class LabelImpl extends AstNodeImpl implements Label {
  /// The label being associated with the statement.
  SimpleIdentifierImpl _label;

  /// The colon that separates the label from the statement.
  @override
  Token colon;

  /// Initialize a newly created label.
  LabelImpl(this._label, this.colon) {
    _becomeParentOf(_label);
  }

  @override
  Token get beginToken => _label.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_label)
    ..add(colon);

  @override
  Token get endToken => colon;

  @override
  SimpleIdentifierImpl get label => _label;

  set label(SimpleIdentifier label) {
    _label = _becomeParentOf(label as SimpleIdentifierImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLabel(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label.accept(visitor);
  }
}

/// A library directive.
///
///    libraryDirective ::=
///        [Annotation] 'library' [Identifier] ';'
class LibraryDirectiveImpl extends DirectiveImpl implements LibraryDirective {
  /// The token representing the 'library' keyword.
  @override
  Token libraryKeyword;

  /// The name of the library being defined.
  LibraryIdentifierImpl _name;

  /// The semicolon terminating the directive.
  @override
  Token semicolon;

  /// Initialize a newly created library directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  LibraryDirectiveImpl(CommentImpl? comment, List<Annotation>? metadata,
      this.libraryKeyword, this._name, this.semicolon)
      : super(comment, metadata) {
    _becomeParentOf(_name);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(libraryKeyword)
    ..add(_name)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => libraryKeyword;

  @override
  Token get keyword => libraryKeyword;

  @override
  LibraryIdentifierImpl get name => _name;

  set name(LibraryIdentifier name) {
    _name = _becomeParentOf(name as LibraryIdentifierImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name.accept(visitor);
  }
}

/// The identifier for a library.
///
///    libraryIdentifier ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
class LibraryIdentifierImpl extends IdentifierImpl
    implements LibraryIdentifier {
  /// The components of the identifier.
  final NodeListImpl<SimpleIdentifier> _components = NodeListImpl._();

  /// Initialize a newly created prefixed identifier.
  LibraryIdentifierImpl(List<SimpleIdentifier> components) {
    _components._initialize(this, components);
  }

  @override
  Token get beginToken => _components.beginToken!;

  @override
  // TODO(paulberry): add "." tokens.
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(_components);

  @override
  NodeListImpl<SimpleIdentifier> get components => _components;

  @override
  Token get endToken => _components.endToken!;

  @override
  String get name {
    StringBuffer buffer = StringBuffer();
    bool needsPeriod = false;
    int length = _components.length;
    for (int i = 0; i < length; i++) {
      SimpleIdentifier identifier = _components[i];
      if (needsPeriod) {
        buffer.write(".");
      } else {
        needsPeriod = true;
      }
      buffer.write(identifier.name);
    }
    return buffer.toString();
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  Element? get staticElement => null;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _components.accept(visitor);
  }
}

class ListLiteralImpl extends TypedLiteralImpl implements ListLiteral {
  /// The left square bracket.
  @override
  Token leftBracket;

  /// The expressions used to compute the elements of the list.
  final NodeListImpl<CollectionElement> _elements = NodeListImpl._();

  /// The right square bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created list literal. The [constKeyword] can be `null`
  /// if the literal is not a constant. The [typeArguments] can be `null` if no
  /// type arguments were declared. The list of [elements] can be `null` if the
  /// list is empty.
  ListLiteralImpl(Token? constKeyword, TypeArgumentListImpl? typeArguments,
      this.leftBracket, List<Expression> elements, this.rightBracket)
      : super(constKeyword, typeArguments) {
    _elements._initialize(this, elements);
  }

  /// Initialize a newly created list literal.
  ///
  /// The [constKeyword] can be `null` if the literal is not a constant. The
  /// [typeArguments] can be `null` if no type arguments were declared. The list
  /// of [elements] can be `null` if the list is empty.
  ListLiteralImpl.experimental(
      Token? constKeyword,
      TypeArgumentListImpl? typeArguments,
      this.leftBracket,
      List<CollectionElement> elements,
      this.rightBracket)
      : super(constKeyword, typeArguments) {
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken {
    if (constKeyword != null) {
      return constKeyword!;
    }
    final typeArguments = this.typeArguments;
    if (typeArguments != null) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(leftBracket)
    ..addAll(_elements)
    ..add(rightBracket);

  @override
  NodeListImpl<CollectionElement> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitListLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}

/// A node that represents a literal expression.
///
///    literal ::=
///        [BooleanLiteral]
///      | [DoubleLiteral]
///      | [IntegerLiteral]
///      | [ListLiteral]
///      | [MapLiteral]
///      | [NullLiteral]
///      | [StringLiteral]
abstract class LiteralImpl extends ExpressionImpl implements Literal {
  @override
  Precedence get precedence => Precedence.primary;
}

/// Additional information about local variables within a function or method
/// produced at resolution time.
class LocalVariableInfo {
  /// The set of local variables and parameters that are potentially mutated
  /// within a local function other than the function in which they are
  /// declared.
  final Set<VariableElement> potentiallyMutatedInClosure = <VariableElement>{};

  /// The set of local variables and parameters that are potentially mutated
  /// within the scope of their declarations.
  final Set<VariableElement> potentiallyMutatedInScope = <VariableElement>{};
}

/// A single key/value pair in a map literal.
///
///    mapLiteralEntry ::=
///        [Expression] ':' [Expression]
class MapLiteralEntryImpl extends CollectionElementImpl
    implements MapLiteralEntry {
  /// The expression computing the key with which the value will be associated.
  ExpressionImpl _key;

  /// The colon that separates the key from the value.
  @override
  Token separator;

  /// The expression computing the value that will be associated with the key.
  ExpressionImpl _value;

  /// Initialize a newly created map literal entry.
  MapLiteralEntryImpl(this._key, this.separator, this._value) {
    _becomeParentOf(_key);
    _becomeParentOf(_value);
  }

  @override
  Token get beginToken => _key.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_key)
    ..add(separator)
    ..add(_value);

  @override
  Token get endToken => _value.endToken;

  @override
  ExpressionImpl get key => _key;

  set key(Expression string) {
    _key = _becomeParentOf(string as ExpressionImpl);
  }

  @override
  ExpressionImpl get value => _value;

  set value(Expression expression) {
    _value = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapLiteralEntry(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _key.accept(visitor);
    _value.accept(visitor);
  }
}

/// A method declaration.
///
///    methodDeclaration ::=
///        methodSignature [FunctionBody]
///
///    methodSignature ::=
///        'external'? ('abstract' | 'static')? [Type]? ('get' | 'set')?
///        methodName [TypeParameterList] [FormalParameterList]
///
///    methodName ::=
///        [SimpleIdentifier]
///      | 'operator' [SimpleIdentifier]
class MethodDeclarationImpl extends ClassMemberImpl
    implements MethodDeclaration {
  /// The token for the 'external' keyword, or `null` if the constructor is not
  /// external.
  @override
  Token? externalKeyword;

  /// The token representing the 'abstract' or 'static' keyword, or `null` if
  /// neither modifier was specified.
  @override
  Token? modifierKeyword;

  /// The return type of the method, or `null` if no return type was declared.
  TypeAnnotationImpl? _returnType;

  /// The token representing the 'get' or 'set' keyword, or `null` if this is a
  /// method declaration rather than a property declaration.
  @override
  Token? propertyKeyword;

  /// The token representing the 'operator' keyword, or `null` if this method
  /// does not declare an operator.
  @override
  Token? operatorKeyword;

  /// The name of the method.
  SimpleIdentifierImpl _name;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters associated with the method, or `null` if this method
  /// declares a getter.
  FormalParameterListImpl? _parameters;

  /// The body of the method.
  FunctionBodyImpl _body;

  /// Initialize a newly created method declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [externalKeyword] can be `null` if the
  /// method is not external. The [modifierKeyword] can be `null` if the method
  /// is neither abstract nor static. The [returnType] can be `null` if no
  /// return type was specified. The [propertyKeyword] can be `null` if the
  /// method is neither a getter or a setter. The [operatorKeyword] can be
  /// `null` if the method does not implement an operator. The [parameters] must
  /// be `null` if this method declares a getter.
  MethodDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.externalKeyword,
      this.modifierKeyword,
      this._returnType,
      this.propertyKeyword,
      this.operatorKeyword,
      this._name,
      this._typeParameters,
      this._parameters,
      this._body)
      : super(comment, metadata) {
    _becomeParentOf(_returnType);
    _becomeParentOf(_name);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
    _becomeParentOf(_body);
  }

  @override
  FunctionBodyImpl get body => _body;

  set body(FunctionBody functionBody) {
    _body = _becomeParentOf(functionBody as FunctionBodyImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(externalKeyword)
    ..add(modifierKeyword)
    ..add(_returnType)
    ..add(propertyKeyword)
    ..add(operatorKeyword)
    ..add(_name)
    ..add(_parameters)
    ..add(_body);

  /// Return the element associated with this method, or `null` if the AST
  /// structure has not been resolved. The element can either be a
  /// [MethodElement], if this represents the declaration of a normal method, or
  /// a [PropertyAccessorElement] if this represents the declaration of either a
  /// getter or a setter.
  @override
  ExecutableElement? get declaredElement =>
      _name.staticElement as ExecutableElement?;

  @override
  Token get endToken => _body.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(externalKeyword, modifierKeyword) ??
        _returnType?.beginToken ??
        Token.lexicallyFirst(propertyKeyword, operatorKeyword) ??
        _name.beginToken;
  }

  @override
  bool get isAbstract {
    FunctionBody body = _body;
    return externalKeyword == null &&
        (body is EmptyFunctionBody && !body.semicolon.isSynthetic);
  }

  @override
  bool get isGetter => propertyKeyword?.keyword == Keyword.GET;

  @override
  bool get isOperator => operatorKeyword != null;

  @override
  bool get isSetter => propertyKeyword?.keyword == Keyword.SET;

  @override
  bool get isStatic => modifierKeyword?.keyword == Keyword.STATIC;

  @override
  SimpleIdentifierImpl get name => _name;

  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterList? parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl?);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotation? type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl?);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMethodDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _name.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
    _body.accept(visitor);
  }
}

/// The invocation of either a function or a method. Invocations of functions
/// resulting from evaluating an expression are represented by
/// [FunctionExpressionInvocation] nodes. Invocations of getters and setters are
/// represented by either [PrefixedIdentifier] or [PropertyAccess] nodes.
///
///    methodInvocation ::=
///        ([Expression] '.')? [SimpleIdentifier] [TypeArgumentList]?
///        [ArgumentList]
class MethodInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl
    implements MethodInvocation {
  /// The expression producing the object on which the method is defined, or
  /// `null` if there is no target (that is, the target is implicitly `this`).
  ExpressionImpl? _target;

  /// The operator that separates the target from the method name, or `null`
  /// if there is no target. In an ordinary method invocation this will be a
  /// period ('.'). In a cascade section this will be the cascade operator
  /// ('..' | '?..').
  @override
  Token? operator;

  /// The name of the method being invoked.
  SimpleIdentifierImpl _methodName;

  /// The invoke type of the [methodName] if the target element is a getter,
  /// or `null` otherwise.
  DartType? _methodNameType;

  /// Initialize a newly created method invocation. The [target] and [operator]
  /// can be `null` if there is no target.
  MethodInvocationImpl(this._target, this.operator, this._methodName,
      TypeArgumentListImpl? typeArguments, ArgumentListImpl argumentList)
      : super(typeArguments, argumentList) {
    _becomeParentOf(_target);
    _becomeParentOf(_methodName);
  }

  @override
  Token get beginToken {
    if (_target != null) {
      return _target!.beginToken;
    } else if (operator != null) {
      return operator!;
    }
    return _methodName.beginToken;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_target)
    ..add(operator)
    ..add(_methodName)
    ..add(_argumentList);

  @override
  Token get endToken => _argumentList.endToken;

  @override
  ExpressionImpl get function => methodName;

  @override
  bool get isCascaded =>
      operator != null &&
      (operator!.type == TokenType.PERIOD_PERIOD ||
          operator!.type == TokenType.QUESTION_PERIOD_PERIOD);

  @override
  bool get isNullAware {
    if (isCascaded) {
      return _ancestorCascade.isNullAware;
    }
    return operator != null &&
        (operator!.type == TokenType.QUESTION_PERIOD ||
            operator!.type == TokenType.QUESTION_PERIOD_PERIOD);
  }

  @override
  SimpleIdentifierImpl get methodName => _methodName;

  set methodName(SimpleIdentifier identifier) {
    _methodName = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  /// The invoke type of the [methodName].
  ///
  /// If the target element is a [MethodElement], this is the same as the
  /// [staticInvokeType]. If the target element is a getter, presumably
  /// returning an [ExecutableElement] so that it can be invoked in this
  /// [MethodInvocation], then this type is the type of the getter, and the
  /// [staticInvokeType] is the invoked type of the returned element.
  DartType? get methodNameType => _methodNameType ?? staticInvokeType;

  /// Set the [methodName] invoke type, only if the target element is a getter.
  /// Otherwise, the target element itself is invoked, [_methodNameType] is
  /// `null`, and the getter will return [staticInvokeType].
  set methodNameType(DartType? methodNameType) {
    _methodNameType = methodNameType;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ExpressionImpl? get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target;
  }

  @override
  ExpressionImpl? get target => _target;

  set target(Expression? expression) {
    _target = _becomeParentOf(expression as ExpressionImpl?);
  }

  /// Return the cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpressionImpl get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent!;; ancestor = ancestor.parent!) {
      if (ancestor is CascadeExpressionImpl) {
        return ancestor;
      }
    }
  }

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMethodInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _methodName.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) => identical(child, _target);
}

/// The declaration of a mixin.
///
///    mixinDeclaration ::=
///        metadata? 'mixin' [SimpleIdentifier] [TypeParameterList]?
///        [RequiresClause]? [ImplementsClause]? '{' [ClassMember]* '}'
class MixinDeclarationImpl extends ClassOrMixinDeclarationImpl
    implements MixinDeclaration {
  @override
  Token mixinKeyword;

  /// The on clause for the mixin, or `null` if the mixin does not have any
  /// super-class constraints.
  OnClauseImpl? _onClause;

  /// Initialize a newly created mixin declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the mixin does not have the
  /// corresponding attribute. The [typeParameters] can be `null` if the mixin
  /// does not have any type parameters. Either or both of the [onClause],
  /// and [implementsClause] can be `null` if the mixin does not have the
  /// corresponding clause. The list of [members] can be `null` if the mixin
  /// does not have any members.
  MixinDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.mixinKeyword,
      SimpleIdentifierImpl name,
      TypeParameterListImpl? typeParameters,
      this._onClause,
      ImplementsClauseImpl? implementsClause,
      Token leftBracket,
      List<ClassMember> members,
      Token rightBracket)
      : super(comment, metadata, name, typeParameters, implementsClause,
            leftBracket, members, rightBracket) {
    _becomeParentOf(_onClause);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(mixinKeyword)
    ..add(_name)
    ..add(_typeParameters)
    ..add(_onClause)
    ..add(_implementsClause)
    ..add(leftBracket)
    ..addAll(members)
    ..add(rightBracket);

  @override
  ClassElement? get declaredElement => _name.staticElement as ClassElement?;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return mixinKeyword;
  }

  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  @override
  NodeListImpl<ClassMember> get members => _members;

  @override
  OnClause? get onClause => _onClause;

  set onClause(OnClause? onClause) {
    _onClause = _becomeParentOf(onClause as OnClauseImpl?);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMixinDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name.accept(visitor);
    _typeParameters?.accept(visitor);
    _onClause?.accept(visitor);
    _implementsClause?.accept(visitor);
    members.accept(visitor);
  }
}

/// A node that declares a single name within the scope of a compilation unit.
abstract class NamedCompilationUnitMemberImpl extends CompilationUnitMemberImpl
    implements NamedCompilationUnitMember {
  /// The name of the member being declared.
  SimpleIdentifierImpl _name;

  /// Initialize a newly created compilation unit member with the given [name].
  /// Either or both of the [comment] and [metadata] can be `null` if the member
  /// does not have the corresponding attribute.
  NamedCompilationUnitMemberImpl(
      CommentImpl? comment, List<Annotation>? metadata, this._name)
      : super(comment, metadata) {
    _becomeParentOf(_name);
  }

  @override
  SimpleIdentifierImpl get name => _name;

  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }
}

/// An expression that has a name associated with it. They are used in method
/// invocations when there are named parameters.
///
///    namedExpression ::=
///        [Label] [Expression]
class NamedExpressionImpl extends ExpressionImpl implements NamedExpression {
  /// The name associated with the expression.
  LabelImpl _name;

  /// The expression with which the name is associated.
  ExpressionImpl _expression;

  /// Initialize a newly created named expression..
  NamedExpressionImpl(this._name, this._expression) {
    _becomeParentOf(_name);
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => _name.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_name)
    ..add(_expression);

  @override
  ParameterElement? get element {
    var element = _name.label.staticElement;
    if (element is ParameterElement) {
      return element;
    }
    return null;
  }

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  LabelImpl get name => _name;

  set name(Label identifier) {
    _name = _becomeParentOf(identifier as LabelImpl);
  }

  @override
  Precedence get precedence => Precedence.none;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNamedExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name.accept(visitor);
    _expression.accept(visitor);
  }
}

/// The name of a type, which can optionally include type arguments.
///
///    typeName ::=
///        [Identifier] typeArguments? '?'?
/// ignore: deprecated_member_use_from_same_package
class NamedTypeImpl extends TypeAnnotationImpl implements TypeName {
  /// The name of the type.
  IdentifierImpl _name;

  /// The type arguments associated with the type, or `null` if there are no
  /// type arguments.
  TypeArgumentListImpl? _typeArguments;

  @override
  Token? question;

  /// The type being named, or `null` if the AST structure has not been
  /// resolved, or if this is part of a [ConstructorReference].
  @override
  DartType? type;

  /// Initialize a newly created type name. The [typeArguments] can be `null` if
  /// there are no type arguments.
  NamedTypeImpl(this._name, this._typeArguments, {this.question}) {
    _becomeParentOf(_name);
    _becomeParentOf(_typeArguments);
  }

  @override
  Token get beginToken => _name.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_name)
    ..add(_typeArguments)
    ..add(question);

  @override
  Token get endToken => question ?? _typeArguments?.endToken ?? _name.endToken;

  @override
  bool get isDeferred {
    Identifier identifier = name;
    if (identifier is! PrefixedIdentifier) {
      return false;
    }
    return identifier.isDeferred;
  }

  @override
  bool get isSynthetic => _name.isSynthetic && _typeArguments == null;

  @override
  IdentifierImpl get name => _name;

  set name(Identifier identifier) {
    _name = _becomeParentOf(identifier as IdentifierImpl);
  }

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentList? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNamedType(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name.accept(visitor);
    _typeArguments?.accept(visitor);
  }
}

/// A node that represents a directive that impacts the namespace of a library.
///
///    directive ::=
///        [ExportDirective]
///      | [ImportDirective]
abstract class NamespaceDirectiveImpl extends UriBasedDirectiveImpl
    implements NamespaceDirective {
  /// The token representing the 'import' or 'export' keyword.
  @override
  Token keyword;

  /// The configurations used to control which library will actually be loaded
  /// at run-time.
  final NodeListImpl<Configuration> _configurations = NodeListImpl._();

  /// The combinators used to control which names are imported or exported.
  final NodeListImpl<Combinator> _combinators = NodeListImpl._();

  /// The semicolon terminating the directive.
  @override
  Token semicolon;

  @override
  String? selectedUriContent;

  @override
  Source? selectedSource;

  /// Initialize a newly created namespace directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute. The list of [combinators] can be `null` if there
  /// are no combinators.
  NamespaceDirectiveImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.keyword,
      StringLiteralImpl libraryUri,
      List<Configuration>? configurations,
      List<Combinator>? combinators,
      this.semicolon)
      : super(comment, metadata, libraryUri) {
    _configurations._initialize(this, configurations);
    _combinators._initialize(this, combinators);
  }

  @override
  NodeListImpl<Combinator> get combinators => _combinators;

  @override
  NodeListImpl<Configuration> get configurations => _configurations;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => keyword;

  @override
  LibraryElement? get uriElement;
}

/// The "native" clause in an class declaration.
///
///    nativeClause ::=
///        'native' [StringLiteral]
class NativeClauseImpl extends AstNodeImpl implements NativeClause {
  /// The token representing the 'native' keyword.
  @override
  Token nativeKeyword;

  /// The name of the native object that implements the class.
  StringLiteralImpl? _name;

  /// Initialize a newly created native clause.
  NativeClauseImpl(this.nativeKeyword, this._name) {
    _becomeParentOf(_name);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(nativeKeyword)
    ..add(_name);

  @override
  Token get endToken {
    return _name?.endToken ?? nativeKeyword;
  }

  @override
  StringLiteralImpl? get name => _name;

  set name(StringLiteral? name) {
    _name = _becomeParentOf(name as StringLiteralImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNativeClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name?.accept(visitor);
  }
}

/// A function body that consists of a native keyword followed by a string
/// literal.
///
///    nativeFunctionBody ::=
///        'native' [SimpleStringLiteral] ';'
class NativeFunctionBodyImpl extends FunctionBodyImpl
    implements NativeFunctionBody {
  /// The token representing 'native' that marks the start of the function body.
  @override
  Token nativeKeyword;

  /// The string literal, after the 'native' token.
  StringLiteralImpl? _stringLiteral;

  /// The token representing the semicolon that marks the end of the function
  /// body.
  @override
  Token semicolon;

  /// Initialize a newly created function body consisting of the 'native' token,
  /// a string literal, and a semicolon.
  NativeFunctionBodyImpl(
      this.nativeKeyword, this._stringLiteral, this.semicolon) {
    _becomeParentOf(_stringLiteral);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(nativeKeyword)
    ..add(_stringLiteral)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  StringLiteralImpl? get stringLiteral => _stringLiteral;

  set stringLiteral(StringLiteral? stringLiteral) {
    _stringLiteral = _becomeParentOf(stringLiteral as StringLiteralImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNativeFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _stringLiteral?.accept(visitor);
  }
}

/// A list of AST nodes that have a common parent.
class NodeListImpl<E extends AstNode> with ListMixin<E> implements NodeList<E> {
  /// The node that is the parent of each of the elements in the list.
  late final AstNodeImpl _owner;

  /// The elements contained in the list.
  List<E> _elements = <E>[];

  /// Initialize a newly created list of nodes such that all of the nodes that
  /// are added to the list will have their parent set to the given [owner].
  NodeListImpl(AstNodeImpl owner) : _owner = owner;

  /// Create a partially initialized instance, [_initialize] must be called.
  NodeListImpl._();

  @override
  Token? get beginToken {
    if (_elements.isEmpty) {
      return null;
    }
    return _elements[0].beginToken;
  }

  @override
  Token? get endToken {
    int length = _elements.length;
    if (length == 0) {
      return null;
    }
    return _elements[length - 1].endToken;
  }

  @override
  int get length => _elements.length;

  @override
  set length(int newLength) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @override
  AstNodeImpl get owner => _owner;

  @override
  E operator [](int index) {
    if (index < 0 || index >= _elements.length) {
      throw RangeError("Index: $index, Size: ${_elements.length}");
    }
    return _elements[index];
  }

  @override
  void operator []=(int index, E node) {
    if (index < 0 || index >= _elements.length) {
      throw RangeError("Index: $index, Size: ${_elements.length}");
    }
    _elements[index] = node;
    _owner._becomeParentOf(node as AstNodeImpl);
  }

  @override
  void accept(AstVisitor visitor) {
    int length = _elements.length;
    for (var i = 0; i < length; i++) {
      _elements[i].accept(visitor);
    }
  }

  @override
  void add(E node) {
    insert(length, node);
  }

  @override
  void addAll(Iterable<E> nodes) {
    for (E node in nodes) {
      _elements.add(node);
      _owner._becomeParentOf(node as AstNodeImpl);
    }
  }

  @override
  void clear() {
    _elements = <E>[];
  }

  @override
  void insert(int index, E node) {
    _elements.insert(index, node);
    _owner._becomeParentOf(node as AstNodeImpl);
  }

  @override
  E removeAt(int index) {
    if (index < 0 || index >= _elements.length) {
      throw RangeError("Index: $index, Size: ${_elements.length}");
    }
    return _elements.removeAt(index);
  }

  /// Set the [owner] of this container, and populate it with [elements].
  void _initialize(AstNodeImpl owner, List<E>? elements) {
    _owner = owner;
    if (elements != null) {
      var length = elements.length;
      for (var i = 0; i < length; i++) {
        var node = elements[i];
        _elements.add(node);
        owner._becomeParentOf(node as AstNodeImpl);
      }
    }
  }
}

/// A formal parameter that is required (is not optional).
///
///    normalFormalParameter ::=
///        [FunctionTypedFormalParameter]
///      | [FieldFormalParameter]
///      | [SimpleFormalParameter]
abstract class NormalFormalParameterImpl extends FormalParameterImpl
    implements NormalFormalParameter {
  /// The documentation comment associated with this parameter, or `null` if
  /// this parameter does not have a documentation comment associated with it.
  CommentImpl? _comment;

  /// The annotations associated with this parameter.
  final NodeListImpl<Annotation> _metadata = NodeListImpl._();

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  @override
  Token? covariantKeyword;

  /// The 'required' keyword, or `null` if the keyword was not used.
  @override
  Token? requiredKeyword;

  /// The name of the parameter being declared.
  SimpleIdentifierImpl? _identifier;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute.
  NormalFormalParameterImpl(this._comment, List<Annotation>? metadata,
      this.covariantKeyword, this.requiredKeyword, this._identifier) {
    _becomeParentOf(_comment);
    _metadata._initialize(this, metadata);
    _becomeParentOf(_identifier);
  }

  @override
  CommentImpl? get documentationComment => _comment;

  set documentationComment(Comment? comment) {
    _comment = _becomeParentOf(comment as CommentImpl?);
  }

  @override
  SimpleIdentifierImpl? get identifier => _identifier;

  set identifier(SimpleIdentifier? identifier) {
    _identifier = _becomeParentOf(identifier as SimpleIdentifierImpl?);
  }

  @override
  ParameterKind get kind {
    final parent = this.parent;
    if (parent is DefaultFormalParameterImpl) {
      return parent.kind;
    }
    return ParameterKind.REQUIRED;
  }

  @override
  NodeListImpl<Annotation> get metadata => _metadata;

  set metadata(List<Annotation> metadata) {
    _metadata.clear();
    _metadata.addAll(metadata);
  }

  @override
  List<AstNode> get sortedCommentAndAnnotations {
    var comment = _comment;
    return <AstNode>[
      if (comment != null) comment,
      ..._metadata,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  ChildEntities get _childEntities {
    ChildEntities result = ChildEntities();
    if (_commentIsBeforeAnnotations()) {
      result
        ..add(_comment)
        ..addAll(_metadata);
    } else {
      result.addAll(sortedCommentAndAnnotations);
    }
    result
      ..add(requiredKeyword)
      ..add(covariantKeyword);
    return result;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    //
    // Note that subclasses are responsible for visiting the identifier because
    // they often need to visit other nodes before visiting the identifier.
    //
    if (_commentIsBeforeAnnotations()) {
      _comment?.accept(visitor);
      _metadata.accept(visitor);
    } else {
      List<AstNode> children = sortedCommentAndAnnotations;
      int length = children.length;
      for (int i = 0; i < length; i++) {
        children[i].accept(visitor);
      }
    }
  }

  /// Return `true` if the comment is lexically before any annotations.
  bool _commentIsBeforeAnnotations() {
    if (_comment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _comment!.offset < firstAnnotation.offset;
  }
}

/// A null literal expression.
///
///    nullLiteral ::=
///        'null'
class NullLiteralImpl extends LiteralImpl implements NullLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// Initialize a newly created null literal.
  NullLiteralImpl(this.literal);

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// Mixin that can be used to implement [NullShortableExpression].
mixin NullShortableExpressionImpl implements NullShortableExpression {
  @override
  Expression get nullShortingTermination {
    var result = this;
    while (true) {
      var parent = result._nullShortingExtensionCandidate;
      if (parent is NullShortableExpressionImpl &&
          parent._extendsNullShorting(result)) {
        result = parent;
      } else {
        return result;
      }
    }
  }

  /// Gets the ancestor of this node to which null-shorting might be extended.
  /// Usually this is just the node's parent, however if `this` is the base of
  /// a cascade section, it will be the cascade expression itself, which may be
  /// a more distant ancestor.
  AstNode? get _nullShortingExtensionCandidate;

  /// Indicates whether the effect of any null-shorting within [descendant]
  /// (which should be a descendant of `this`) should extend to include `this`.
  bool _extendsNullShorting(Expression descendant);
}

/// The "on" clause in a mixin declaration.
///
///    onClause ::=
///        'on' [TypeName] (',' [TypeName])*
class OnClauseImpl extends AstNodeImpl implements OnClause {
  @override
  Token onKeyword;

  /// The classes are super-class constraints for the mixin.
  final NodeListImpl<NamedType> _superclassConstraints = NodeListImpl._();

  /// Initialize a newly created on clause.
  OnClauseImpl(this.onKeyword, List<NamedType> superclassConstraints) {
    _superclassConstraints._initialize(this, superclassConstraints);
  }

  @override
  Token get beginToken => onKeyword;

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(onKeyword)
    ..addAll(superclassConstraints2);

  @override
  Token get endToken => _superclassConstraints.endToken!;

  @Deprecated('Use superclassConstraints2 instead')
  @override
  NodeList<TypeName> get superclassConstraints =>
      _DelegatingTypeNameList(_superclassConstraints);

  @override
  NodeListImpl<NamedType> get superclassConstraints2 => _superclassConstraints;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitOnClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _superclassConstraints.accept(visitor);
  }
}

/// A parenthesized expression.
///
///    parenthesizedExpression ::=
///        '(' [Expression] ')'
class ParenthesizedExpressionImpl extends ExpressionImpl
    implements ParenthesizedExpression {
  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The expression within the parentheses.
  ExpressionImpl _expression;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// Initialize a newly created parenthesized expression.
  ParenthesizedExpressionImpl(
      this.leftParenthesis, this._expression, this.rightParenthesis) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftParenthesis)
    ..add(_expression)
    ..add(rightParenthesis);

  @override
  Token get endToken => rightParenthesis;

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @override
  ExpressionImpl get unParenthesized {
    // This is somewhat inefficient, but it avoids a stack overflow in the
    // degenerate case.
    var expression = _expression;
    while (expression is ParenthesizedExpressionImpl) {
      expression = expression._expression;
    }
    return expression;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitParenthesizedExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A part directive.
///
///    partDirective ::=
///        [Annotation] 'part' [StringLiteral] ';'
class PartDirectiveImpl extends UriBasedDirectiveImpl implements PartDirective {
  /// The token representing the 'part' keyword.
  @override
  Token partKeyword;

  /// The semicolon terminating the directive.
  @override
  Token semicolon;

  /// Initialize a newly created part directive. Either or both of the [comment]
  /// and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  PartDirectiveImpl(CommentImpl? comment, List<Annotation>? metadata,
      this.partKeyword, StringLiteralImpl partUri, this.semicolon)
      : super(comment, metadata, partUri);

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(partKeyword)
    ..add(_uri)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  Token get keyword => partKeyword;

  @override
  CompilationUnitElement? get uriElement => element as CompilationUnitElement?;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPartDirective(this);
}

/// A part-of directive.
///
///    partOfDirective ::=
///        [Annotation] 'part' 'of' [Identifier] ';'
class PartOfDirectiveImpl extends DirectiveImpl implements PartOfDirective {
  /// The token representing the 'part' keyword.
  @override
  Token partKeyword;

  /// The token representing the 'of' keyword.
  @override
  Token ofKeyword;

  /// The URI of the library that the containing compilation unit is part of.
  StringLiteralImpl? _uri;

  /// The name of the library that the containing compilation unit is part of,
  /// or `null` if no name was given (typically because a library URI was
  /// provided).
  LibraryIdentifierImpl? _libraryName;

  /// The semicolon terminating the directive.
  @override
  Token semicolon;

  /// Initialize a newly created part-of directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  PartOfDirectiveImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.partKeyword,
      this.ofKeyword,
      this._uri,
      this._libraryName,
      this.semicolon)
      : super(comment, metadata) {
    _becomeParentOf(_uri);
    _becomeParentOf(_libraryName);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(partKeyword)
    ..add(ofKeyword)
    ..add(_uri)
    ..add(_libraryName)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  Token get keyword => partKeyword;

  @override
  LibraryIdentifierImpl? get libraryName => _libraryName;

  set libraryName(LibraryIdentifier? libraryName) {
    _libraryName = _becomeParentOf(libraryName as LibraryIdentifierImpl?);
  }

  @override
  StringLiteralImpl? get uri => _uri;

  set uri(StringLiteral? uri) {
    _uri = _becomeParentOf(uri as StringLiteralImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPartOfDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _libraryName?.accept(visitor);
    _uri?.accept(visitor);
  }
}

/// A postfix unary expression.
///
///    postfixExpression ::=
///        [Expression] [Token]
class PostfixExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements PostfixExpression {
  /// The expression computing the operand for the operator.
  ExpressionImpl _operand;

  /// The postfix operator being applied to the operand.
  @override
  Token operator;

  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created postfix expression.
  PostfixExpressionImpl(this._operand, this.operator) {
    _becomeParentOf(_operand);
  }

  @override
  Token get beginToken => _operand.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_operand)
    ..add(operator);

  @override
  Token get endToken => operator;

  @override
  ExpressionImpl get operand => _operand;

  set operand(Expression expression) {
    _operand = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the operand will be
  /// bound.  Otherwise, return `null`.
  ParameterElement? get _staticParameterElementForOperand {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement!.parameters;
    if (parameters.isEmpty) {
      return null;
    }
    return parameters[0];
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPostfixExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _operand.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) => identical(child, operand);
}

/// An identifier that is prefixed or an access to an object property where the
/// target of the property access is a simple identifier.
///
///    prefixedIdentifier ::=
///        [SimpleIdentifier] '.' [SimpleIdentifier]
class PrefixedIdentifierImpl extends IdentifierImpl
    implements PrefixedIdentifier {
  /// The prefix associated with the library in which the identifier is defined.
  SimpleIdentifierImpl _prefix;

  /// The period used to separate the prefix from the identifier.
  @override
  Token period;

  /// The identifier being prefixed.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created prefixed identifier.
  PrefixedIdentifierImpl(this._prefix, this.period, this._identifier) {
    _becomeParentOf(_prefix);
    _becomeParentOf(_identifier);
  }

  @override
  Token get beginToken => _prefix.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_prefix)
    ..add(period)
    ..add(_identifier);

  @override
  Token get endToken => _identifier.endToken;

  @override
  SimpleIdentifierImpl get identifier => _identifier;

  set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  bool get isDeferred {
    Element? element = _prefix.staticElement;
    if (element is PrefixElement) {
      List<ImportElement> imports =
          element.enclosingElement.getImportsWithPrefix(element);
      if (imports.length != 1) {
        return false;
      }
      return imports[0].isDeferred;
    }
    return false;
  }

  @override
  String get name => "${_prefix.name}.${_identifier.name}";

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  SimpleIdentifierImpl get prefix => _prefix;

  set prefix(SimpleIdentifier identifier) {
    _prefix = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  Element? get staticElement {
    return _identifier.staticElement;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPrefixedIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _prefix.accept(visitor);
    _identifier.accept(visitor);
  }
}

/// A prefix unary expression.
///
///    prefixExpression ::=
///        [Token] [Expression]
class PrefixExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements PrefixExpression {
  /// The prefix operator being applied to the operand.
  @override
  Token operator;

  /// The expression computing the operand for the operator.
  ExpressionImpl _operand;

  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created prefix expression.
  PrefixExpressionImpl(this.operator, this._operand) {
    _becomeParentOf(_operand);
  }

  @override
  Token get beginToken => operator;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(operator)
    ..add(_operand);

  @override
  Token get endToken => _operand.endToken;

  @override
  ExpressionImpl get operand => _operand;

  set operand(Expression expression) {
    _operand = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the operand will be
  /// bound.  Otherwise, return `null`.
  ParameterElement? get _staticParameterElementForOperand {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement!.parameters;
    if (parameters.isEmpty) {
      return null;
    }
    return parameters[0];
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPrefixExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _operand.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) =>
      identical(child, operand) && operator.type.isIncrementOperator;
}

/// The access of a property of an object.
///
/// Note, however, that accesses to properties of objects can also be
/// represented as [PrefixedIdentifier] nodes in cases where the target is also
/// a simple identifier.
///
///    propertyAccess ::=
///        [Expression] '.' [SimpleIdentifier]
class PropertyAccessImpl extends CommentReferableExpressionImpl
    with NullShortableExpressionImpl
    implements PropertyAccess {
  /// The expression computing the object defining the property being accessed.
  ExpressionImpl? _target;

  /// The property access operator.
  @override
  Token operator;

  /// The name of the property being accessed.
  SimpleIdentifierImpl _propertyName;

  /// Initialize a newly created property access expression.
  PropertyAccessImpl(this._target, this.operator, this._propertyName) {
    _becomeParentOf(_target);
    _becomeParentOf(_propertyName);
  }

  @override
  Token get beginToken {
    if (_target != null) {
      return _target!.beginToken;
    }
    return operator;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_target)
    ..add(operator)
    ..add(_propertyName);

  @override
  Token get endToken => _propertyName.endToken;

  @override
  bool get isAssignable => true;

  @override
  bool get isCascaded =>
      operator.type == TokenType.PERIOD_PERIOD ||
      operator.type == TokenType.QUESTION_PERIOD_PERIOD;

  @override
  bool get isNullAware {
    if (isCascaded) {
      return _ancestorCascade.isNullAware;
    }
    return operator.type == TokenType.QUESTION_PERIOD ||
        operator.type == TokenType.QUESTION_PERIOD_PERIOD;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  SimpleIdentifierImpl get propertyName => _propertyName;

  set propertyName(SimpleIdentifier identifier) {
    _propertyName = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  ExpressionImpl get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target!;
  }

  @override
  ExpressionImpl? get target => _target;

  set target(Expression? expression) {
    _target = _becomeParentOf(expression as ExpressionImpl?);
  }

  /// Return the cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpressionImpl get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent!;; ancestor = ancestor.parent!) {
      if (ancestor is CascadeExpressionImpl) {
        return ancestor;
      }
    }
  }

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPropertyAccess(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _propertyName.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) => identical(child, _target);
}

/// The invocation of a constructor in the same class from within a
/// constructor's initialization list.
///
///    redirectingConstructorInvocation ::=
///        'this' ('.' identifier)? arguments
class RedirectingConstructorInvocationImpl extends ConstructorInitializerImpl
    implements RedirectingConstructorInvocation {
  /// The token for the 'this' keyword.
  @override
  Token thisKeyword;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  @override
  Token? period;

  /// The name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifierImpl? _constructorName;

  /// The list of arguments to the constructor.
  ArgumentListImpl _argumentList;

  /// The element associated with the constructor based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// the constructor could not be resolved.
  @override
  ConstructorElement? staticElement;

  /// Initialize a newly created redirecting invocation to invoke the
  /// constructor with the given name with the given arguments. The
  /// [constructorName] can be `null` if the constructor being invoked is the
  /// unnamed constructor.
  RedirectingConstructorInvocationImpl(this.thisKeyword, this.period,
      this._constructorName, this._argumentList) {
    _becomeParentOf(_constructorName);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  Token get beginToken => thisKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(thisKeyword)
    ..add(period)
    ..add(_constructorName)
    ..add(_argumentList);

  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  set constructorName(SimpleIdentifier? identifier) {
    _constructorName = _becomeParentOf(identifier as SimpleIdentifierImpl?);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRedirectingConstructorInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName?.accept(visitor);
    _argumentList.accept(visitor);
  }
}

/// A rethrow expression.
///
///    rethrowExpression ::=
///        'rethrow'
class RethrowExpressionImpl extends ExpressionImpl
    implements RethrowExpression {
  /// The token representing the 'rethrow' keyword.
  @override
  Token rethrowKeyword;

  /// Initialize a newly created rethrow expression.
  RethrowExpressionImpl(this.rethrowKeyword);

  @override
  Token get beginToken => rethrowKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(rethrowKeyword);

  @override
  Token get endToken => rethrowKeyword;

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRethrowExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A return statement.
///
///    returnStatement ::=
///        'return' [Expression]? ';'
class ReturnStatementImpl extends StatementImpl implements ReturnStatement {
  /// The token representing the 'return' keyword.
  @override
  Token returnKeyword;

  /// The expression computing the value to be returned, or `null` if no
  /// explicit value was provided.
  ExpressionImpl? _expression;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// Initialize a newly created return statement. The [expression] can be
  /// `null` if no explicit value was provided.
  ReturnStatementImpl(this.returnKeyword, this._expression, this.semicolon) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => returnKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(returnKeyword)
    ..add(_expression)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  ExpressionImpl? get expression => _expression;

  set expression(Expression? expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitReturnStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// A script tag that can optionally occur at the beginning of a compilation
/// unit.
///
///    scriptTag ::=
///        '#!' (~NEWLINE)* NEWLINE
class ScriptTagImpl extends AstNodeImpl implements ScriptTag {
  /// The token representing this script tag.
  @override
  Token scriptTag;

  /// Initialize a newly created script tag.
  ScriptTagImpl(this.scriptTag);

  @override
  Token get beginToken => scriptTag;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(scriptTag);

  @override
  Token get endToken => scriptTag;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitScriptTag(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

class SetOrMapLiteralImpl extends TypedLiteralImpl implements SetOrMapLiteral {
  @override
  Token leftBracket;

  /// The syntactic elements in the set.
  final NodeListImpl<CollectionElement> _elements = NodeListImpl._();

  @override
  Token rightBracket;

  /// A representation of whether this literal represents a map or a set, or
  /// whether the kind has not or cannot be determined.
  _SetOrMapKind _resolvedKind = _SetOrMapKind.unresolved;

  /// The context type computed by
  /// [ResolverVisitor._computeSetOrMapContextType].
  ///
  /// Note that this is not the same as the context pushed down by type
  /// inference (which can be obtained via [InferenceContext.getContext]).  For
  /// example, in the following code:
  ///
  ///     var m = {};
  ///
  /// The context pushed down by type inference is null, whereas the
  /// `contextType` is `Map<dynamic, dynamic>`.
  InterfaceType? contextType;

  /// Initialize a newly created set or map literal. The [constKeyword] can be
  /// `null` if the literal is not a constant. The [typeArguments] can be `null`
  /// if no type arguments were declared. The [elements] can be `null` if the
  /// set is empty.
  SetOrMapLiteralImpl(Token? constKeyword, TypeArgumentListImpl? typeArguments,
      this.leftBracket, List<CollectionElement> elements, this.rightBracket)
      : super(constKeyword, typeArguments) {
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken {
    if (constKeyword != null) {
      return constKeyword!;
    }
    final typeArguments = this.typeArguments;
    if (typeArguments != null) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(leftBracket)
    ..addAll(elements)
    ..add(rightBracket);

  @override
  NodeListImpl<CollectionElement> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  bool get isMap => _resolvedKind == _SetOrMapKind.map;

  @override
  bool get isSet => _resolvedKind == _SetOrMapKind.set;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSetOrMapLiteral(this);

  void becomeMap() {
    assert(_resolvedKind == _SetOrMapKind.unresolved ||
        _resolvedKind == _SetOrMapKind.map);
    _resolvedKind = _SetOrMapKind.map;
  }

  void becomeSet() {
    assert(_resolvedKind == _SetOrMapKind.unresolved ||
        _resolvedKind == _SetOrMapKind.set);
    _resolvedKind = _SetOrMapKind.set;
  }

  void becomeUnresolved() {
    _resolvedKind = _SetOrMapKind.unresolved;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}

/// The "show" clause in an extension declaration.
///
///    showClause ::=
///        'show' [TypeName] (',' [TypeName])*
class ShowClauseImpl extends AstNodeImpl implements ShowClause {
  /// The token representing the 'show' keyword.
  @override
  Token showKeyword;

  /// The elements that are being shown.
  final NodeListImpl<ShowHideClauseElement> _elements = NodeListImpl._();

  /// Initialize a newly created show clause.
  ShowClauseImpl(this.showKeyword, List<ShowHideClauseElement> elements) {
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken => showKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(showKeyword)
    ..addAll(elements);

  @override
  NodeListImpl<ShowHideClauseElement> get elements => _elements;

  @override
  Token get endToken => _elements.endToken!;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitShowClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _elements.accept(visitor);
  }
}

/// A combinator that restricts the names being imported to those in a given
/// list.
///
///    showCombinator ::=
///        'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
class ShowCombinatorImpl extends CombinatorImpl implements ShowCombinator {
  /// The list of names from the library that are made visible by this
  /// combinator.
  final NodeListImpl<SimpleIdentifier> _shownNames = NodeListImpl._();

  /// Initialize a newly created import show combinator.
  ShowCombinatorImpl(Token keyword, List<SimpleIdentifier> shownNames)
      : super(keyword) {
    _shownNames._initialize(this, shownNames);
  }

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(keyword)
    ..addAll(_shownNames);

  @override
  Token get endToken => _shownNames.endToken!;

  @override
  NodeListImpl<SimpleIdentifier> get shownNames => _shownNames;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitShowCombinator(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _shownNames.accept(visitor);
  }
}

/// A potentially non-type element of a show or a hide clause.
///
///    showHideElement ::=
///        'get' [SimpleIdentifier] |
///        'set' [SimpleIdentifier] |
///        'operator' [SimpleIdentifier] |
///        [SimpleIdentifier]
///
/// Clients may not extend, implement or mix-in this class.
class ShowHideElementImpl extends AstNodeImpl implements ShowHideElement {
  @override
  Token? modifier;

  @override
  SimpleIdentifier name;

  ShowHideElementImpl(this.modifier, this.name) {
    _becomeParentOf<SimpleIdentifierImpl>(name as SimpleIdentifierImpl);
  }

  @override
  Token get beginToken => modifier ?? name.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll([if (modifier != null) modifier!, name]);

  @override
  Token get endToken => name.endToken;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitShowHideElement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    name.accept(visitor);
  }
}

/// A simple formal parameter.
///
///    simpleFormalParameter ::=
///        ('final' [TypeName] | 'var' | [TypeName])? [SimpleIdentifier]
class SimpleFormalParameterImpl extends NormalFormalParameterImpl
    implements SimpleFormalParameter {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  @override
  // TODO(brianwilkerson) This overrides a concrete implementation in which the
  // element is assumed to be stored in the `identifier`, but there is no
  // corresponding inherited setter. This seems inconsistent and error prone.
  ParameterElement? declaredElement;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if a type was
  /// specified. The [type] must be `null` if the keyword is 'var'.
  SimpleFormalParameterImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      Token? covariantKeyword,
      Token? requiredKeyword,
      this.keyword,
      this._type,
      SimpleIdentifierImpl? identifier)
      : super(
            comment, metadata, covariantKeyword, requiredKeyword, identifier) {
    _becomeParentOf(_type);
  }

  @override
  Token get beginToken {
    final metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken!;
    } else if (requiredKeyword != null) {
      return requiredKeyword!;
    } else if (covariantKeyword != null) {
      return covariantKeyword!;
    } else if (keyword != null) {
      return keyword!;
    } else if (_type != null) {
      return _type!.beginToken;
    }
    return identifier!.beginToken;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..add(identifier);

  @override
  Token get endToken => identifier?.endToken ?? type!.endToken;

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotation? type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSimpleFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    identifier?.accept(visitor);
  }
}

/// A simple identifier.
///
///    simpleIdentifier ::=
///        initialCharacter internalCharacter*
///
///    initialCharacter ::= '_' | '$' | letter
///
///    internalCharacter ::= '_' | '$' | letter | digit
class SimpleIdentifierImpl extends IdentifierImpl implements SimpleIdentifier {
  /// The token representing the identifier.
  @override
  Token token;

  /// The element associated with this identifier based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// this identifier could not be resolved.
  Element? _staticElement;

  @override
  List<DartType>? tearOffTypeArgumentTypes;

  /// If this identifier is meant to be looked up in the enclosing scope, the
  /// raw result the scope lookup, prior to figuring out whether a write or a
  /// read context is intended, and prior to falling back on implicit `this` (if
  /// appropriate).
  ///
  /// `null` if this identifier is not meant to be looked up in the enclosing
  /// scope.
  ScopeLookupResult? scopeLookupResult;

  /// Initialize a newly created identifier.
  SimpleIdentifierImpl(this.token);

  /// Return the cascade that contains this [SimpleIdentifier].
  CascadeExpressionImpl? get ancestorCascade {
    var operatorType = token.previous?.type;
    if (operatorType == TokenType.PERIOD_PERIOD ||
        operatorType == TokenType.QUESTION_PERIOD_PERIOD) {
      return thisOrAncestorOfType<CascadeExpressionImpl>();
    }
    return null;
  }

  @override
  Token get beginToken => token;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(token);

  @override
  Token get endToken => token;

  @override
  bool get isQualified {
    final parent = this.parent!;
    if (parent is PrefixedIdentifier) {
      return identical(parent.identifier, this);
    } else if (parent is PropertyAccess) {
      return identical(parent.propertyName, this);
    } else if (parent is ConstructorName) {
      return identical(parent.name, this);
    } else if (parent is MethodInvocation) {
      MethodInvocation invocation = parent;
      return identical(invocation.methodName, this) &&
          invocation.realTarget != null;
    }
    return false;
  }

  @override
  bool get isSynthetic => token.isSynthetic;

  @override
  String get name => token.lexeme;

  @override
  Precedence get precedence => Precedence.primary;

  /// This element is set when this identifier is used not as an expression,
  /// but just to reference some element.
  ///
  /// Examples are the name of the type in a [NamedType], the name of the method
  /// in a [MethodInvocation], the name of the constructor in a
  /// [ConstructorName], the name of the property in a [PropertyAccess], the
  /// prefix and the identifier in a [PrefixedIdentifier] (which then can be
  /// used to read or write a value).
  ///
  /// In invalid code, for recovery, any element could be used, e.g. a
  /// setter as a type name `set mySetter(_) {} mySetter topVar;`. We do this
  /// to help the user to navigate to this element, and maybe change its name,
  /// add a new declaration, etc.
  ///
  /// Return `null` if this identifier is used to either read or write a value,
  /// or the AST structure has not been resolved, or if this identifier could
  /// not be resolved.
  ///
  /// If either [readElement] or [writeElement] are not `null`, the
  /// [referenceElement] is `null`, because the identifier is being used to
  /// read or write a value.
  ///
  /// All three [readElement], [writeElement], and [referenceElement] can be
  /// `null` when the AST structure has not been resolved, or this identifier
  /// could not be resolved.
  Element? get referenceElement => null;

  @override
  Element? get staticElement => _staticElement;

  set staticElement(Element? element) {
    _staticElement = element;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSimpleIdentifier(this);

  @override
  bool inDeclarationContext() => false;

  @override
  bool inGetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    AstNode initialParent = this.parent!;
    AstNode parent = initialParent;
    AstNode target = this;
    // skip prefix
    if (initialParent is PrefixedIdentifier) {
      if (identical(initialParent.prefix, this)) {
        return true;
      }
      parent = initialParent.parent!;
      target = initialParent;
    } else if (initialParent is PropertyAccess) {
      if (identical(initialParent.target, this)) {
        return true;
      }
      parent = initialParent.parent!;
      target = initialParent;
    }
    // skip label
    if (parent is Label) {
      return false;
    }
    // analyze usage
    if (parent is AssignmentExpression) {
      if (identical(parent.leftHandSide, target) &&
          parent.operator.type == TokenType.EQ) {
        return false;
      }
    }
    if (parent is ConstructorFieldInitializer &&
        identical(parent.fieldName, target)) {
      return false;
    }
    if (parent is ForEachPartsWithIdentifier) {
      if (identical(parent.identifier, target)) {
        return false;
      }
    }
    if (parent is FieldFormalParameter) {
      if (identical(parent.identifier, target)) {
        return false;
      }
    }
    if (parent is VariableDeclaration) {
      if (identical(parent.name, target)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool inSetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    AstNode initialParent = this.parent!;
    AstNode parent = initialParent;
    AstNode target = this;
    // skip prefix
    if (initialParent is PrefixedIdentifier) {
      // if this is the prefix, then return false
      if (identical(initialParent.prefix, this)) {
        return false;
      }
      parent = initialParent.parent!;
      target = initialParent;
    } else if (initialParent is PropertyAccess) {
      if (identical(initialParent.target, this)) {
        return false;
      }
      parent = initialParent.parent!;
      target = initialParent;
    }
    // analyze usage
    if (parent is PrefixExpression) {
      return parent.operator.type.isIncrementOperator;
    } else if (parent is PostfixExpression) {
      return parent.operator.type.isIncrementOperator;
    } else if (parent is AssignmentExpression) {
      return identical(parent.leftHandSide, target);
    } else if (parent is ForEachPartsWithIdentifier) {
      return identical(parent.identifier, target);
    }
    return false;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A string literal expression that does not contain any interpolations.
///
///    simpleStringLiteral ::=
///        rawStringLiteral
///      | basicStringLiteral
///
///    rawStringLiteral ::=
///        'r' basicStringLiteral
///
///    simpleStringLiteral ::=
///        multiLineStringLiteral
///      | singleLineStringLiteral
///
///    multiLineStringLiteral ::=
///        "'''" characters "'''"
///      | '"""' characters '"""'
///
///    singleLineStringLiteral ::=
///        "'" characters "'"
///      | '"' characters '"'
class SimpleStringLiteralImpl extends SingleStringLiteralImpl
    implements SimpleStringLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// The value of the literal.
  String _value;

  /// Initialize a newly created simple string literal.
  SimpleStringLiteralImpl(this.literal, this._value) {
    _value = StringUtilities.intern(value);
  }

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

  @override
  int get contentsEnd => offset + _helper.end;

  @override
  int get contentsOffset => offset + _helper.start;

  @override
  Token get endToken => literal;

  @override
  bool get isMultiline => _helper.isMultiline;

  @override
  bool get isRaw => _helper.isRaw;

  @override
  bool get isSingleQuoted => _helper.isSingleQuoted;

  @override
  bool get isSynthetic => literal.isSynthetic;

  @override
  String get value => _value;

  set value(String string) {
    _value = StringUtilities.intern(_value);
  }

  StringLexemeHelper get _helper {
    return StringLexemeHelper(literal.lexeme, true, true);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSimpleStringLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    buffer.write(value);
  }
}

/// A single string literal expression.
///
///    singleStringLiteral ::=
///        [SimpleStringLiteral]
///      | [StringInterpolation]
abstract class SingleStringLiteralImpl extends StringLiteralImpl
    implements SingleStringLiteral {}

class SpreadElementImpl extends AstNodeImpl
    implements CollectionElementImpl, SpreadElement {
  @override
  Token spreadOperator;

  ExpressionImpl _expression;

  SpreadElementImpl(this.spreadOperator, this._expression) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => spreadOperator;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(spreadOperator)
    ..add(_expression);

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  bool get isNullAware =>
      spreadOperator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION;

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitSpreadElement(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A node that represents a statement.
///
///    statement ::=
///        [Block]
///      | [VariableDeclarationStatement]
///      | [ForStatement]
///      | [ForEachStatement]
///      | [WhileStatement]
///      | [DoStatement]
///      | [SwitchStatement]
///      | [IfStatement]
///      | [TryStatement]
///      | [BreakStatement]
///      | [ContinueStatement]
///      | [ReturnStatement]
///      | [ExpressionStatement]
///      | [FunctionDeclarationStatement]
abstract class StatementImpl extends AstNodeImpl implements Statement {
  @override
  StatementImpl get unlabeled => this;
}

/// A string interpolation literal.
///
///    stringInterpolation ::=
///        ''' [InterpolationElement]* '''
///      | '"' [InterpolationElement]* '"'
class StringInterpolationImpl extends SingleStringLiteralImpl
    implements StringInterpolation {
  /// The elements that will be composed to produce the resulting string.
  final NodeListImpl<InterpolationElement> _elements = NodeListImpl._();

  /// Initialize a newly created string interpolation expression.
  StringInterpolationImpl(List<InterpolationElement> elements) {
    // TODO(scheglov) Replace asserts with appropriately typed parameters.
    assert(elements.length > 2, 'Expected at last three elements.');
    assert(
      elements.first is InterpolationStringImpl,
      'The first element must be a string.',
    );
    assert(
      elements[1] is InterpolationExpressionImpl,
      'The second element must be an expression.',
    );
    assert(
      elements.last is InterpolationStringImpl,
      'The last element must be a string.',
    );
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken => _elements.beginToken!;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(_elements);

  @override
  int get contentsEnd {
    var element = _elements.last as InterpolationString;
    return element.contentsEnd;
  }

  @override
  int get contentsOffset {
    var element = _elements.first as InterpolationString;
    return element.contentsOffset;
  }

  /// Return the elements that will be composed to produce the resulting string.
  @override
  NodeListImpl<InterpolationElement> get elements => _elements;

  @override
  Token get endToken => _elements.endToken!;

  @override
  InterpolationStringImpl get firstString =>
      elements.first as InterpolationStringImpl;

  @override
  bool get isMultiline => _firstHelper.isMultiline;

  @override
  bool get isRaw => false;

  @override
  bool get isSingleQuoted => _firstHelper.isSingleQuoted;

  @override
  InterpolationStringImpl get lastString =>
      elements.last as InterpolationStringImpl;

  StringLexemeHelper get _firstHelper {
    var lastString = _elements.first as InterpolationString;
    String lexeme = lastString.contents.lexeme;
    return StringLexemeHelper(lexeme, true, false);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitStringInterpolation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _elements.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    throw ArgumentError();
  }
}

/// A helper for analyzing string lexemes.
class StringLexemeHelper {
  final String lexeme;
  final bool isFirst;
  final bool isLast;

  bool isRaw = false;
  bool isSingleQuoted = false;
  bool isMultiline = false;
  int start = 0;
  int end = 0;

  StringLexemeHelper(this.lexeme, this.isFirst, this.isLast) {
    if (isFirst) {
      isRaw = lexeme.startsWith('r');
      if (isRaw) {
        start++;
      }
      if (StringUtilities.startsWith3(lexeme, start, 0x27, 0x27, 0x27)) {
        isSingleQuoted = true;
        isMultiline = true;
        start += 3;
        start = _trimInitialWhitespace(start);
      } else if (StringUtilities.startsWith3(lexeme, start, 0x22, 0x22, 0x22)) {
        isSingleQuoted = false;
        isMultiline = true;
        start += 3;
        start = _trimInitialWhitespace(start);
      } else if (start < lexeme.length && lexeme.codeUnitAt(start) == 0x27) {
        isSingleQuoted = true;
        isMultiline = false;
        start++;
      } else if (start < lexeme.length && lexeme.codeUnitAt(start) == 0x22) {
        isSingleQuoted = false;
        isMultiline = false;
        start++;
      }
    }
    end = lexeme.length;
    if (isLast) {
      if (start + 3 <= end &&
          (StringUtilities.endsWith3(lexeme, 0x22, 0x22, 0x22) ||
              StringUtilities.endsWith3(lexeme, 0x27, 0x27, 0x27))) {
        end -= 3;
      } else if (start + 1 <= end &&
          (StringUtilities.endsWithChar(lexeme, 0x22) ||
              StringUtilities.endsWithChar(lexeme, 0x27))) {
        end -= 1;
      }
    }
  }

  /// Given the [lexeme] for a multi-line string whose content begins at the
  /// given [start] index, return the index of the first character that is
  /// included in the value of the string. According to the specification:
  ///
  /// If the first line of a multiline string consists solely of the whitespace
  /// characters defined by the production WHITESPACE 20.1), possibly prefixed
  /// by \, then that line is ignored, including the new line at its end.
  int _trimInitialWhitespace(int start) {
    int length = lexeme.length;
    int index = start;
    while (index < length) {
      int currentChar = lexeme.codeUnitAt(index);
      if (currentChar == 0x0D) {
        if (index + 1 < length && lexeme.codeUnitAt(index + 1) == 0x0A) {
          return index + 2;
        }
        return index + 1;
      } else if (currentChar == 0x0A) {
        return index + 1;
      } else if (currentChar == 0x5C) {
        if (index + 1 >= length) {
          return start;
        }
        currentChar = lexeme.codeUnitAt(index + 1);
        if (currentChar != 0x0D &&
            currentChar != 0x0A &&
            currentChar != 0x09 &&
            currentChar != 0x20) {
          return start;
        }
      } else if (currentChar != 0x09 && currentChar != 0x20) {
        return start;
      }
      index++;
    }
    return start;
  }
}

/// A string literal expression.
///
///    stringLiteral ::=
///        [SimpleStringLiteral]
///      | [AdjacentStrings]
///      | [StringInterpolation]
abstract class StringLiteralImpl extends LiteralImpl implements StringLiteral {
  @override
  String? get stringValue {
    StringBuffer buffer = StringBuffer();
    try {
      _appendStringValue(buffer);
    } on ArgumentError {
      return null;
    }
    return buffer.toString();
  }

  /// Append the value of this string literal to the given [buffer]. Throw an
  /// [ArgumentError] if the string is not a constant string without any
  /// string interpolation.
  void _appendStringValue(StringBuffer buffer);
}

/// The invocation of a superclass' constructor from within a constructor's
/// initialization list.
///
///    superInvocation ::=
///        'super' ('.' [SimpleIdentifier])? [ArgumentList]
class SuperConstructorInvocationImpl extends ConstructorInitializerImpl
    implements SuperConstructorInvocation {
  /// The token for the 'super' keyword.
  @override
  Token superKeyword;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  @override
  Token? period;

  /// The name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifierImpl? _constructorName;

  /// The list of arguments to the constructor.
  ArgumentListImpl _argumentList;

  /// The element associated with the constructor based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// the constructor could not be resolved.
  @override
  ConstructorElement? staticElement;

  /// Initialize a newly created super invocation to invoke the inherited
  /// constructor with the given name with the given arguments. The [period] and
  /// [constructorName] can be `null` if the constructor being invoked is the
  /// unnamed constructor.
  SuperConstructorInvocationImpl(this.superKeyword, this.period,
      this._constructorName, this._argumentList) {
    _becomeParentOf(_constructorName);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  Token get beginToken => superKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(superKeyword)
    ..add(period)
    ..add(_constructorName)
    ..add(_argumentList);

  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  set constructorName(SimpleIdentifier? identifier) {
    _constructorName = _becomeParentOf(identifier as SimpleIdentifierImpl?);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSuperConstructorInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName?.accept(visitor);
    _argumentList.accept(visitor);
  }
}

/// A super expression.
///
///    superExpression ::=
///        'super'
class SuperExpressionImpl extends ExpressionImpl implements SuperExpression {
  /// The token representing the 'super' keyword.
  @override
  Token superKeyword;

  /// Initialize a newly created super expression.
  SuperExpressionImpl(this.superKeyword);

  @override
  Token get beginToken => superKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(superKeyword);

  @override
  Token get endToken => superKeyword;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSuperExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A super-initializer formal parameter.
///
///    fieldFormalParameter ::=
///        ('final' [TypeName] | 'const' [TypeName] | 'var' | [TypeName])?
///        'super' '.' [SimpleIdentifier]
///        ([TypeParameterList]? [FormalParameterList])?
class SuperFormalParameterImpl extends NormalFormalParameterImpl
    implements SuperFormalParameter {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  /// The token representing the 'super' keyword.
  @override
  Token superKeyword;

  /// The token representing the period.
  @override
  Token period;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters of the function-typed parameter, or `null` if this is not a
  /// function-typed field formal parameter.
  FormalParameterListImpl? _parameters;

  @override
  Token? question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if there is a type.
  /// The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
  /// [period] can be `null` if the keyword 'this' was not provided.  The
  /// [parameters] can be `null` if this is not a function-typed field formal
  /// parameter.
  SuperFormalParameterImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      Token? covariantKeyword,
      Token? requiredKeyword,
      this.keyword,
      this._type,
      this.superKeyword,
      this.period,
      SimpleIdentifierImpl identifier,
      this._typeParameters,
      this._parameters,
      this.question)
      : super(
            comment, metadata, covariantKeyword, requiredKeyword, identifier) {
    _becomeParentOf(_type);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Token get beginToken {
    final metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken!;
    } else if (requiredKeyword != null) {
      return requiredKeyword!;
    } else if (covariantKeyword != null) {
      return covariantKeyword!;
    } else if (keyword != null) {
      return keyword!;
    } else if (_type != null) {
      return _type!.beginToken;
    }
    return superKeyword;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..add(superKeyword)
    ..add(period)
    ..add(identifier)
    ..add(_parameters);

  @override
  Token get endToken {
    return question ?? _parameters?.endToken ?? identifier.endToken;
  }

  @override
  SimpleIdentifierImpl get identifier => super.identifier!;

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterList? parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl?);
  }

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotation? type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSuperFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    identifier.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
  }
}

/// A case in a switch statement.
///
///    switchCase ::=
///        [SimpleIdentifier]* 'case' [Expression] ':' [Statement]*
class SwitchCaseImpl extends SwitchMemberImpl implements SwitchCase {
  /// The expression controlling whether the statements will be executed.
  ExpressionImpl _expression;

  /// Initialize a newly created switch case. The list of [labels] can be `null`
  /// if there are no labels.
  SwitchCaseImpl(List<Label> labels, Token keyword, this._expression,
      Token colon, List<Statement> statements)
      : super(labels, keyword, colon, statements) {
    _becomeParentOf(_expression);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(labels)
    ..add(keyword)
    ..add(_expression)
    ..add(colon)
    ..addAll(statements);

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchCase(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    _expression.accept(visitor);
    statements.accept(visitor);
  }
}

/// The default case in a switch statement.
///
///    switchDefault ::=
///        [SimpleIdentifier]* 'default' ':' [Statement]*
class SwitchDefaultImpl extends SwitchMemberImpl implements SwitchDefault {
  /// Initialize a newly created switch default. The list of [labels] can be
  /// `null` if there are no labels.
  SwitchDefaultImpl(List<Label> labels, Token keyword, Token colon,
      List<Statement> statements)
      : super(labels, keyword, colon, statements);

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(labels)
    ..add(keyword)
    ..add(colon)
    ..addAll(statements);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchDefault(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    statements.accept(visitor);
  }
}

/// An element within a switch statement.
///
///    switchMember ::=
///        switchCase
///      | switchDefault
abstract class SwitchMemberImpl extends AstNodeImpl implements SwitchMember {
  /// The labels associated with the switch member.
  final NodeListImpl<Label> _labels = NodeListImpl._();

  /// The token representing the 'case' or 'default' keyword.
  @override
  Token keyword;

  /// The colon separating the keyword or the expression from the statements.
  @override
  Token colon;

  /// The statements that will be executed if this switch member is selected.
  final NodeListImpl<Statement> _statements = NodeListImpl._();

  /// Initialize a newly created switch member. The list of [labels] can be
  /// `null` if there are no labels.
  SwitchMemberImpl(List<Label> labels, this.keyword, this.colon,
      List<Statement> statements) {
    _labels._initialize(this, labels);
    _statements._initialize(this, statements);
  }

  @override
  Token get beginToken {
    if (_labels.isNotEmpty) {
      return _labels.beginToken!;
    }
    return keyword;
  }

  @override
  Token get endToken {
    if (_statements.isNotEmpty) {
      return _statements.endToken!;
    }
    return colon;
  }

  @override
  NodeListImpl<Label> get labels => _labels;

  @override
  NodeListImpl<Statement> get statements => _statements;
}

/// A switch statement.
///
///    switchStatement ::=
///        'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
class SwitchStatementImpl extends StatementImpl implements SwitchStatement {
  /// The token representing the 'switch' keyword.
  @override
  Token switchKeyword;

  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The expression used to determine which of the switch members will be
  /// selected.
  ExpressionImpl _expression;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// The left curly bracket.
  @override
  Token leftBracket;

  /// The switch members that can be selected by the expression.
  final NodeListImpl<SwitchMember> _members = NodeListImpl._();

  /// The right curly bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created switch statement. The list of [members] can be
  /// `null` if there are no switch members.
  SwitchStatementImpl(
      this.switchKeyword,
      this.leftParenthesis,
      this._expression,
      this.rightParenthesis,
      this.leftBracket,
      List<SwitchMember> members,
      this.rightBracket) {
    _becomeParentOf(_expression);
    _members._initialize(this, members);
  }

  @override
  Token get beginToken => switchKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(switchKeyword)
    ..add(leftParenthesis)
    ..add(_expression)
    ..add(rightParenthesis)
    ..add(leftBracket)
    ..addAll(_members)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  NodeListImpl<SwitchMember> get members => _members;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
    _members.accept(visitor);
  }
}

/// A symbol literal expression.
///
///    symbolLiteral ::=
///        '#' (operator | (identifier ('.' identifier)*))
class SymbolLiteralImpl extends LiteralImpl implements SymbolLiteral {
  /// The token introducing the literal.
  @override
  Token poundSign;

  /// The components of the literal.
  @override
  final List<Token> components;

  /// Initialize a newly created symbol literal.
  SymbolLiteralImpl(this.poundSign, this.components);

  @override
  Token get beginToken => poundSign;

  @override
  // TODO(paulberry): add "." tokens.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(poundSign)
    ..addAll(components);

  @override
  Token get endToken => components[components.length - 1];

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSymbolLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A this expression.
///
///    thisExpression ::=
///        'this'
class ThisExpressionImpl extends ExpressionImpl implements ThisExpression {
  /// The token representing the 'this' keyword.
  @override
  Token thisKeyword;

  /// Initialize a newly created this expression.
  ThisExpressionImpl(this.thisKeyword);

  @override
  Token get beginToken => thisKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(thisKeyword);

  @override
  Token get endToken => thisKeyword;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitThisExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A throw expression.
///
///    throwExpression ::=
///        'throw' [Expression]
class ThrowExpressionImpl extends ExpressionImpl implements ThrowExpression {
  /// The token representing the 'throw' keyword.
  @override
  Token throwKeyword;

  /// The expression computing the exception to be thrown.
  ExpressionImpl _expression;

  /// Initialize a newly created throw expression.
  ThrowExpressionImpl(this.throwKeyword, this._expression) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => throwKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(throwKeyword)
    ..add(_expression);

  @override
  Token get endToken {
    return _expression.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitThrowExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// The declaration of one or more top-level variables of the same type.
///
///    topLevelVariableDeclaration ::=
///        ('final' | 'const') type? staticFinalDeclarationList ';'
///      | variableDeclaration ';'
class TopLevelVariableDeclarationImpl extends CompilationUnitMemberImpl
    implements TopLevelVariableDeclaration {
  /// The top-level variables being declared.
  VariableDeclarationListImpl _variableList;

  @override
  Token? externalKeyword;

  /// The semicolon terminating the declaration.
  @override
  Token semicolon;

  /// Initialize a newly created top-level variable declaration. Either or both
  /// of the [comment] and [metadata] can be `null` if the variable does not
  /// have the corresponding attribute.
  TopLevelVariableDeclarationImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.externalKeyword,
      this._variableList,
      this.semicolon)
      : super(comment, metadata) {
    _becomeParentOf(_variableList);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(_variableList)
    ..add(semicolon);

  @override
  Element? get declaredElement => null;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      externalKeyword ?? _variableList.beginToken;

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationList variables) {
    _variableList = _becomeParentOf(variables as VariableDeclarationListImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitTopLevelVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _variableList.accept(visitor);
  }
}

/// A try statement.
///
///    tryStatement ::=
///        'try' [Block] ([CatchClause]+ finallyClause? | finallyClause)
///
///    finallyClause ::=
///        'finally' [Block]
class TryStatementImpl extends StatementImpl implements TryStatement {
  /// The token representing the 'try' keyword.
  @override
  Token tryKeyword;

  /// The body of the statement.
  BlockImpl _body;

  /// The catch clauses contained in the try statement.
  final NodeListImpl<CatchClause> _catchClauses = NodeListImpl._();

  /// The token representing the 'finally' keyword, or `null` if the statement
  /// does not contain a finally clause.
  @override
  Token? finallyKeyword;

  /// The finally block contained in the try statement, or `null` if the
  /// statement does not contain a finally clause.
  BlockImpl? _finallyBlock;

  /// Initialize a newly created try statement. The list of [catchClauses] can
  /// be`null` if there are no catch clauses. The [finallyKeyword] and
  /// [finallyBlock] can be `null` if there is no finally clause.
  TryStatementImpl(this.tryKeyword, this._body, List<CatchClause> catchClauses,
      this.finallyKeyword, this._finallyBlock) {
    _becomeParentOf(_body);
    _catchClauses._initialize(this, catchClauses);
    _becomeParentOf(_finallyBlock);
  }

  @override
  Token get beginToken => tryKeyword;

  @override
  BlockImpl get body => _body;

  set body(Block block) {
    _body = _becomeParentOf(block as BlockImpl);
  }

  @override
  NodeListImpl<CatchClause> get catchClauses => _catchClauses;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(tryKeyword)
    ..add(_body)
    ..addAll(_catchClauses)
    ..add(finallyKeyword)
    ..add(_finallyBlock);

  @override
  Token get endToken {
    if (_finallyBlock != null) {
      return _finallyBlock!.endToken;
    } else if (finallyKeyword != null) {
      return finallyKeyword!;
    } else if (_catchClauses.isNotEmpty) {
      return _catchClauses.endToken!;
    }
    return _body.endToken;
  }

  @override
  Block? get finallyBlock => _finallyBlock;

  set finallyBlock(Block? block) {
    _finallyBlock = _becomeParentOf(block as BlockImpl?);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTryStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _body.accept(visitor);
    _catchClauses.accept(visitor);
    _finallyBlock?.accept(visitor);
  }
}

/// The declaration of a type alias.
///
///    typeAlias ::=
///        'typedef' typeAliasBody
///
///    typeAliasBody ::=
///        classTypeAlias
///      | functionTypeAlias
abstract class TypeAliasImpl extends NamedCompilationUnitMemberImpl
    implements TypeAlias {
  /// The token representing the 'typedef' keyword.
  @override
  Token typedefKeyword;

  /// The semicolon terminating the declaration.
  @override
  Token semicolon;

  /// Initialize a newly created type alias. Either or both of the [comment] and
  /// [metadata] can be `null` if the declaration does not have the
  /// corresponding attribute.
  TypeAliasImpl(CommentImpl? comment, List<Annotation>? metadata,
      this.typedefKeyword, SimpleIdentifierImpl name, this.semicolon)
      : super(comment, metadata, name);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => typedefKeyword;
}

/// A type annotation.
///
///    type ::=
///        [NamedType]
///      | [GenericFunctionType]
abstract class TypeAnnotationImpl extends AstNodeImpl
    implements TypeAnnotation {}

/// A list of type arguments.
///
///    typeArguments ::=
///        '<' typeName (',' typeName)* '>'
class TypeArgumentListImpl extends AstNodeImpl implements TypeArgumentList {
  /// The left bracket.
  @override
  Token leftBracket;

  /// The type arguments associated with the type.
  final NodeListImpl<TypeAnnotation> _arguments = NodeListImpl._();

  /// The right bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created list of type arguments.
  TypeArgumentListImpl(
      this.leftBracket, List<TypeAnnotation> arguments, this.rightBracket) {
    _arguments._initialize(this, arguments);
  }

  @override
  NodeListImpl<TypeAnnotation> get arguments => _arguments;

  @override
  Token get beginToken => leftBracket;

  @override
  // TODO(paulberry): Add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftBracket)
    ..addAll(_arguments)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeArgumentList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }
}

/// A literal that has a type associated with it.
///
///    typedLiteral ::=
///        [ListLiteral]
///      | [MapLiteral]
abstract class TypedLiteralImpl extends LiteralImpl implements TypedLiteral {
  /// The token representing the 'const' keyword, or `null` if the literal is
  /// not a constant.
  @override
  Token? constKeyword;

  /// The type argument associated with this literal, or `null` if no type
  /// arguments were declared.
  TypeArgumentListImpl? _typeArguments;

  /// Initialize a newly created typed literal. The [constKeyword] can be
  /// `null` if the literal is not a constant. The [typeArguments] can be `null`
  /// if no type arguments were declared.
  TypedLiteralImpl(this.constKeyword, this._typeArguments) {
    _becomeParentOf(_typeArguments);
  }

  @override
  bool get isConst {
    return constKeyword != null || inConstantContext;
  }

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentList? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl?);
  }

  ChildEntities get _childEntities => ChildEntities()
    ..add(constKeyword)
    ..add(_typeArguments);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeArguments?.accept(visitor);
  }
}

/// An expression representing a type, e.g. the expression `int` in
/// `var x = int;`.
///
/// Objects of this type are not produced directly by the parser (because the
/// parser cannot tell whether an identifier refers to a type); they are
/// produced at resolution time.
///
/// The `.staticType` getter returns the type of the expression (which will
/// always be the type `Type`).  To see the type represented by the type literal
/// use `.typeName.type`.
class TypeLiteralImpl extends CommentReferableExpressionImpl
    implements TypeLiteral {
  NamedTypeImpl _typeName;

  TypeLiteralImpl(this._typeName) {
    _becomeParentOf(_typeName);
  }

  @override
  Token get beginToken => _typeName.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_typeName);

  @override
  Token get endToken => _typeName.endToken;

  @override
  Precedence get precedence => _typeName.typeArguments == null
      ? _typeName.name.precedence
      : Precedence.postfix;

  @override
  NamedTypeImpl get type => _typeName;

  @Deprecated('Use namedType instead')
  @override
  NamedTypeImpl get typeName => _typeName;

  set typeName(NamedTypeImpl value) {
    _typeName = _becomeParentOf(value);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeName.accept(visitor);
  }
}

/// A type parameter.
///
///    typeParameter ::=
///        typeParameterVariance? [SimpleIdentifier] ('extends' [TypeName])?
///
///    typeParameterVariance ::= 'out' | 'inout' | 'in'
class TypeParameterImpl extends DeclarationImpl implements TypeParameter {
  /// The name of the type parameter.
  SimpleIdentifierImpl _name;

  /// The token representing the variance modifier keyword, or `null` if
  /// there is no explicit variance modifier, meaning legacy covariance.
  Token? varianceKeyword;

  /// The token representing the 'extends' keyword, or `null` if there is no
  /// explicit upper bound.
  @override
  Token? extendsKeyword;

  /// The name of the upper bound for legal arguments, or `null` if there is no
  /// explicit upper bound.
  TypeAnnotationImpl? _bound;

  /// Initialize a newly created type parameter. Either or both of the [comment]
  /// and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [extendsKeyword] and [bound] can be `null` if
  /// the parameter does not have an upper bound.
  TypeParameterImpl(CommentImpl? comment, List<Annotation>? metadata,
      this._name, this.extendsKeyword, this._bound)
      : super(comment, metadata) {
    _becomeParentOf(_name);
    _becomeParentOf(_bound);
  }

  @override
  TypeAnnotationImpl? get bound => _bound;

  set bound(TypeAnnotation? type) {
    _bound = _becomeParentOf(type as TypeAnnotationImpl?);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(_name)
    ..add(extendsKeyword)
    ..add(_bound);

  @override
  TypeParameterElement? get declaredElement =>
      _name.staticElement as TypeParameterElement?;

  @override
  Token get endToken {
    if (_bound == null) {
      return _name.endToken;
    }
    return _bound!.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;

  @override
  SimpleIdentifierImpl get name => _name;

  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name.accept(visitor);
    _bound?.accept(visitor);
  }
}

/// Type parameters within a declaration.
///
///    typeParameterList ::=
///        '<' [TypeParameter] (',' [TypeParameter])* '>'
class TypeParameterListImpl extends AstNodeImpl implements TypeParameterList {
  /// The left angle bracket.
  @override
  final Token leftBracket;

  /// The type parameters in the list.
  final NodeListImpl<TypeParameter> _typeParameters = NodeListImpl._();

  /// The right angle bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created list of type parameters.
  TypeParameterListImpl(
      this.leftBracket, List<TypeParameter> typeParameters, this.rightBracket) {
    _typeParameters._initialize(this, typeParameters);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftBracket)
    ..addAll(_typeParameters)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  NodeListImpl<TypeParameter> get typeParameters => _typeParameters;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeParameterList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeParameters.accept(visitor);
  }
}

/// A directive that references a URI.
///
///    uriBasedDirective ::=
///        [ExportDirective]
///      | [ImportDirective]
///      | [PartDirective]
abstract class UriBasedDirectiveImpl extends DirectiveImpl
    implements UriBasedDirective {
  /// The URI referenced by this directive.
  StringLiteralImpl _uri;

  @override
  String? uriContent;

  @override
  Source? uriSource;

  /// Initialize a newly create URI-based directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  UriBasedDirectiveImpl(
      CommentImpl? comment, List<Annotation>? metadata, this._uri)
      : super(comment, metadata) {
    _becomeParentOf(_uri);
  }

  @override
  StringLiteralImpl get uri => _uri;

  set uri(StringLiteral uri) {
    _uri = _becomeParentOf(uri as StringLiteralImpl);
  }

  UriValidationCode? validate() {
    return validateUri(this is ImportDirective, uri, uriContent);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _uri.accept(visitor);
  }

  /// Validate this directive, but do not check for existence. Return a code
  /// indicating the problem if there is one, or `null` no problem.
  static UriValidationCode? validateUri(
      bool isImport, StringLiteral uriLiteral, String? uriContent) {
    if (uriLiteral is StringInterpolation) {
      return UriValidationCode.URI_WITH_INTERPOLATION;
    }
    if (uriContent == null) {
      return UriValidationCode.INVALID_URI;
    }
    if (uriContent.isEmpty) {
      return null;
    }
    Uri uri;
    try {
      uri = Uri.parse(Uri.encodeFull(uriContent));
    } on FormatException {
      return UriValidationCode.INVALID_URI;
    }
    if (uri.path.isEmpty) {
      return UriValidationCode.INVALID_URI;
    }
    return null;
  }
}

/// Validation codes returned by [UriBasedDirective.validate].
class UriValidationCode {
  static const UriValidationCode INVALID_URI = UriValidationCode('INVALID_URI');

  static const UriValidationCode URI_WITH_INTERPOLATION =
      UriValidationCode('URI_WITH_INTERPOLATION');

  /// The name of the validation code.
  final String name;

  /// Initialize a newly created validation code to have the given [name].
  const UriValidationCode(this.name);

  @override
  String toString() => name;
}

/// An identifier that has an initial value associated with it. Instances of
/// this class are always children of the class [VariableDeclarationList].
///
///    variableDeclaration ::=
///        [SimpleIdentifier] ('=' [Expression])?
///
/// TODO(paulberry): the grammar does not allow metadata to be associated with
/// a VariableDeclaration, and currently we don't record comments for it either.
/// Consider changing the class hierarchy so that [VariableDeclaration] does not
/// extend [Declaration].
class VariableDeclarationImpl extends DeclarationImpl
    implements VariableDeclaration {
  /// The name of the variable being declared.
  SimpleIdentifierImpl _name;

  /// The equal sign separating the variable name from the initial value, or
  /// `null` if the initial value was not specified.
  @override
  Token? equals;

  /// The expression used to compute the initial value for the variable, or
  /// `null` if the initial value was not specified.
  ExpressionImpl? _initializer;

  /// When this node is read as a part of summaries, we usually don't want
  /// to read the [initializer], but we need to know if there is one in
  /// the code. So, this flag might be set to `true` even though
  /// [initializer] is `null`.
  bool hasInitializer = false;

  /// Initialize a newly created variable declaration. The [equals] and
  /// [initializer] can be `null` if there is no initializer.
  VariableDeclarationImpl(this._name, this.equals, this._initializer)
      : super(null, null) {
    _becomeParentOf(_name);
    _becomeParentOf(_initializer);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(_name)
    ..add(equals)
    ..add(_initializer);

  @override
  VariableElement? get declaredElement =>
      _name.staticElement as VariableElement?;

  /// This overridden implementation of [documentationComment] looks in the
  /// grandparent node for Dartdoc comments if no documentation is specifically
  /// available on the node.
  @override
  CommentImpl? get documentationComment {
    var comment = super.documentationComment;
    if (comment == null) {
      var node = parent?.parent;
      if (node is AnnotatedNodeImpl) {
        return node.documentationComment;
      }
    }
    return comment;
  }

  @override
  Token get endToken {
    if (_initializer != null) {
      return _initializer!.endToken;
    }
    return _name.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;

  @override
  ExpressionImpl? get initializer => _initializer;

  set initializer(Expression? expression) {
    _initializer = _becomeParentOf(expression as ExpressionImpl?);
  }

  @override
  bool get isConst {
    final parent = this.parent;
    return parent is VariableDeclarationList && parent.isConst;
  }

  @override
  bool get isFinal {
    final parent = this.parent;
    return parent is VariableDeclarationList && parent.isFinal;
  }

  @override
  bool get isLate {
    final parent = this.parent;
    return parent is VariableDeclarationList && parent.isLate;
  }

  @override
  SimpleIdentifierImpl get name => _name;

  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name.accept(visitor);
    _initializer?.accept(visitor);
  }
}

/// The declaration of one or more variables of the same type.
///
///    variableDeclarationList ::=
///        finalConstVarOrType [VariableDeclaration]
///        (',' [VariableDeclaration])*
///
///    finalConstVarOrType ::=
///      'final' 'late'? [TypeAnnotation]?
///      | 'const' [TypeAnnotation]?
///      | 'var'
///      | 'late'? [TypeAnnotation]
class VariableDeclarationListImpl extends AnnotatedNodeImpl
    implements VariableDeclarationList {
  /// The token representing the 'final', 'const' or 'var' keyword, or `null` if
  /// no keyword was included.
  @override
  Token? keyword;

  /// The token representing the 'late' keyword, or `null` if the late modifier
  /// was not included.
  @override
  Token? lateKeyword;

  /// The type of the variables being declared, or `null` if no type was
  /// provided.
  TypeAnnotationImpl? _type;

  /// A list containing the individual variables being declared.
  final NodeListImpl<VariableDeclaration> _variables = NodeListImpl._();

  /// Initialize a newly created variable declaration list. Either or both of
  /// the [comment] and [metadata] can be `null` if the variable list does not
  /// have the corresponding attribute. The [keyword] can be `null` if a type
  /// was specified. The [type] must be `null` if the keyword is 'var'.
  VariableDeclarationListImpl(
      CommentImpl? comment,
      List<Annotation>? metadata,
      this.lateKeyword,
      this.keyword,
      this._type,
      List<VariableDeclaration> variables)
      : super(comment, metadata) {
    _becomeParentOf(_type);
    _variables._initialize(this, variables);
  }

  @override
  // TODO(paulberry): include commas.
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..addAll(_variables);

  @override
  Token get endToken => _variables.endToken!;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(lateKeyword, keyword) ??
        _type?.beginToken ??
        _variables.beginToken!;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  bool get isLate => lateKeyword != null;

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotation? type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl?);
  }

  @override
  NodeListImpl<VariableDeclaration> get variables => _variables;

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitVariableDeclarationList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    _variables.accept(visitor);
  }
}

/// A list of variables that are being declared in a context where a statement
/// is required.
///
///    variableDeclarationStatement ::=
///        [VariableDeclarationList] ';'
class VariableDeclarationStatementImpl extends StatementImpl
    implements VariableDeclarationStatement {
  /// The variables being declared.
  VariableDeclarationListImpl _variableList;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// Initialize a newly created variable declaration statement.
  VariableDeclarationStatementImpl(this._variableList, this.semicolon) {
    _becomeParentOf(_variableList);
  }

  @override
  Token get beginToken => _variableList.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_variableList)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationList variables) {
    _variableList = _becomeParentOf(variables as VariableDeclarationListImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitVariableDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _variableList.accept(visitor);
  }
}

/// A while statement.
///
///    whileStatement ::=
///        'while' '(' [Expression] ')' [Statement]
class WhileStatementImpl extends StatementImpl implements WhileStatement {
  /// The token representing the 'while' keyword.
  @override
  Token whileKeyword;

  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The expression used to determine whether to execute the body of the loop.
  ExpressionImpl _condition;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// The body of the loop.
  StatementImpl _body;

  /// Initialize a newly created while statement.
  WhileStatementImpl(this.whileKeyword, this.leftParenthesis, this._condition,
      this.rightParenthesis, this._body) {
    _becomeParentOf(_condition);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken => whileKeyword;

  @override
  StatementImpl get body => _body;

  set body(Statement statement) {
    _body = _becomeParentOf(statement as StatementImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(whileKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(_body);

  @override
  ExpressionImpl get condition => _condition;

  set condition(Expression expression) {
    _condition = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWhileStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    _body.accept(visitor);
  }
}

/// The with clause in a class declaration.
///
///    withClause ::=
///        'with' [TypeName] (',' [TypeName])*
class WithClauseImpl extends AstNodeImpl implements WithClause {
  /// The token representing the 'with' keyword.
  @override
  Token withKeyword;

  /// The names of the mixins that were specified.
  final NodeListImpl<NamedType> _mixinTypes = NodeListImpl._();

  /// Initialize a newly created with clause.
  WithClauseImpl(this.withKeyword, List<NamedType> mixinTypes) {
    _mixinTypes._initialize(this, mixinTypes);
  }

  @override
  Token get beginToken => withKeyword;

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(withKeyword)
    ..addAll(_mixinTypes);

  @override
  Token get endToken => _mixinTypes.endToken!;

  @Deprecated('Use mixinTypes2 instead')
  @override
  NodeList<TypeName> get mixinTypes => _DelegatingTypeNameList(_mixinTypes);

  @override
  NodeListImpl<NamedType> get mixinTypes2 => _mixinTypes;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWithClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _mixinTypes.accept(visitor);
  }
}

/// A yield statement.
///
///    yieldStatement ::=
///        'yield' '*'? [Expression] ‘;’
class YieldStatementImpl extends StatementImpl implements YieldStatement {
  /// The 'yield' keyword.
  @override
  Token yieldKeyword;

  /// The star optionally following the 'yield' keyword.
  @override
  Token? star;

  /// The expression whose value will be yielded.
  ExpressionImpl _expression;

  /// The semicolon following the expression.
  @override
  Token semicolon;

  /// Initialize a newly created yield expression. The [star] can be `null` if
  /// no star was provided.
  YieldStatementImpl(
      this.yieldKeyword, this.star, this._expression, this.semicolon) {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    return yieldKeyword;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(yieldKeyword)
    ..add(star)
    ..add(_expression)
    ..add(semicolon);

  @override
  Token get endToken {
    return semicolon;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitYieldStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// Implementation of `NodeList<TypeName>` that delegates.
@Deprecated('Use NamedType instead')
class _DelegatingTypeNameList
    with ListMixin<TypeName>
    implements NodeList<TypeName> {
  final NodeListImpl<NamedType> _delegate;

  _DelegatingTypeNameList(this._delegate);

  @override
  Token? get beginToken {
    return _delegate.beginToken;
  }

  @override
  Token? get endToken {
    return _delegate.endToken;
  }

  @override
  int get length => _delegate.length;

  @override
  set length(int newLength) {
    _delegate.length = newLength;
  }

  @override
  AstNodeImpl get owner => _delegate.owner;

  @override
  TypeName operator [](int index) {
    return _delegate[index] as TypeName;
  }

  @override
  void operator []=(int index, TypeName node) {
    _delegate[index] = node;
  }

  @override
  void accept(AstVisitor visitor) {
    _delegate.accept(visitor);
  }

  @override
  void add(NamedType node) {
    _delegate.add(node);
  }

  @override
  void addAll(Iterable<TypeName> nodes) {
    _delegate.addAll(nodes);
  }

  @override
  void clear() {
    _delegate.clear();
  }

  @override
  void insert(int index, TypeName node) {
    _delegate.insert(index, node);
  }

  @override
  TypeName removeAt(int index) {
    return _delegate.removeAt(index) as TypeName;
  }
}

/// An indication of the resolved kind of a [SetOrMapLiteral].
enum _SetOrMapKind {
  /// Indicates that the literal represents a map.
  map,

  /// Indicates that the literal represents a set.
  set,

  /// Indicates that either
  /// - the literal is syntactically ambiguous and resolution has not yet been
  ///   performed, or
  /// - the literal is invalid because resolution was not able to resolve the
  ///   ambiguity.
  unresolved
}
