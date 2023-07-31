// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_operations.dart'
    as shared;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/typed_literal_resolver.dart';
import 'package:analyzer/src/fasta/token_utils.dart' as util show findPrevious;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart' show LineInfo;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

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
  final NodeListImpl<StringLiteralImpl> _strings = NodeListImpl._();

  /// Initialize a newly created list of adjacent strings. To be syntactically
  /// valid, the list of [strings] must contain at least two elements.
  AdjacentStringsImpl({
    required List<StringLiteralImpl> strings,
  }) {
    _strings._initialize(this, strings);
  }

  @override
  Token get beginToken => _strings.beginToken!;

  @override
  Token get endToken => _strings.endToken!;

  @override
  NodeListImpl<StringLiteralImpl> get strings => _strings;

  @override
  ChildEntities get _childEntities {
    return ChildEntities()..addNodeList('strings', strings);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAdjacentStrings(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAdjacentStrings(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _strings.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    int length = strings.length;
    for (int i = 0; i < length; i++) {
      strings[i]._appendStringValue(buffer);
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
  final NodeListImpl<AnnotationImpl> _metadata = NodeListImpl._();

  /// Initialize a newly created annotated node. Either or both of the [comment]
  /// and [metadata] can be `null` if the node does not have the corresponding
  /// attribute.
  AnnotatedNodeImpl({
    required CommentImpl? comment,
    required List<AnnotationImpl>? metadata,
  }) : _comment = comment {
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

  set documentationComment(CommentImpl? comment) {
    _comment = _becomeParentOf(comment);
  }

  @override
  NodeListImpl<AnnotationImpl> get metadata => _metadata;

  @override
  List<AstNode> get sortedCommentAndAnnotations {
    var comment = _comment;
    return <AstNode>[
      if (comment != null) comment,
      ..._metadata,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  @override
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addNode('documentationComment', documentationComment)
      ..addNodeList('metadata', metadata);
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
  final Token atSign;

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
  final Token? period;

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
  AnnotationImpl({
    required this.atSign,
    required IdentifierImpl name,
    required TypeArgumentListImpl? typeArguments,
    required this.period,
    required SimpleIdentifierImpl? constructorName,
    required ArgumentListImpl? arguments,
  })  : _name = name,
        _typeArguments = typeArguments,
        _constructorName = constructorName,
        _arguments = arguments {
    _becomeParentOf(_name);
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_constructorName);
    _becomeParentOf(_arguments);
  }

  @override
  ArgumentListImpl? get arguments => _arguments;

  set arguments(ArgumentListImpl? arguments) {
    _arguments = _becomeParentOf(arguments);
  }

  @override
  Token get beginToken => atSign;

  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  set constructorName(SimpleIdentifierImpl? name) {
    _constructorName = _becomeParentOf(name);
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

  set name(IdentifierImpl name) {
    _name = _becomeParentOf(name)!;
  }

  @override
  AstNode get parent => super.parent!;

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  /// Sets the type arguments to the constructor being invoked to the given
  /// [typeArguments].
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addToken('atSign', atSign)
      ..addNode('name', name)
      ..addNode('typeArguments', typeArguments)
      ..addToken('period', period)
      ..addNode('constructorName', constructorName)
      ..addNode('arguments', arguments);
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
  final Token leftParenthesis;

  /// The expressions producing the values of the arguments.
  final NodeListImpl<ExpressionImpl> _arguments = NodeListImpl._();

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// A list containing the elements representing the parameters corresponding
  /// to each of the arguments in this list, or `null` if the AST has not been
  /// resolved or if the function or method being invoked could not be
  /// determined based on static type information. The list must be the same
  /// length as the number of arguments, but can contain `null` entries if a
  /// given argument does not correspond to a formal parameter.
  List<ParameterElement?>? _correspondingStaticParameters;

  /// Initialize a newly created list of arguments. The list of [arguments] can
  /// be `null` if there are no arguments.
  ArgumentListImpl({
    required this.leftParenthesis,
    required List<ExpressionImpl> arguments,
    required this.rightParenthesis,
  }) {
    _arguments._initialize(this, arguments);
  }

  @override
  NodeListImpl<ExpressionImpl> get arguments => _arguments;

  @override
  Token get beginToken => leftParenthesis;

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
  // TODO(paulberry): Add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('arguments', arguments)
    ..addToken('rightParenthesis', rightParenthesis);

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
  final Token asOperator;

  /// The type being cast to.
  TypeAnnotationImpl _type;

  /// Initialize a newly created as expression.
  AsExpressionImpl({
    required ExpressionImpl expression,
    required this.asOperator,
    required TypeAnnotationImpl type,
  })  : _expression = expression,
        _type = type {
    _becomeParentOf(_expression);
    _becomeParentOf(_type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Token get endToken => _type.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @override
  TypeAnnotationImpl get type => _type;

  set type(TypeAnnotationImpl type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addToken('asOperator', asOperator)
    ..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAsExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAsExpression(this, contextType: contextType);
  }

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
  final Token assertKeyword;

  @override
  final Token leftParenthesis;

  /// The condition that is being asserted to be `true`.
  ExpressionImpl _condition;

  @override
  final Token? comma;

  /// The message to report if the assertion fails, or `null` if no message was
  /// supplied.
  ExpressionImpl? _message;

  @override
  final Token rightParenthesis;

  /// Initialize a newly created assert initializer.
  AssertInitializerImpl({
    required this.assertKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.comma,
    required ExpressionImpl? message,
    required this.rightParenthesis,
  })  : _condition = condition,
        _message = message {
    _becomeParentOf(_condition);
    _becomeParentOf(_message);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @override
  Token get endToken => rightParenthesis;

  @override
  ExpressionImpl? get message => _message;

  set message(ExpressionImpl? expression) {
    _message = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('assertKeyword', assertKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('comma', comma)
    ..addNode('message', message)
    ..addToken('rightParenthesis', rightParenthesis);

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
  final Token assertKeyword;

  @override
  final Token leftParenthesis;

  /// The condition that is being asserted to be `true`.
  ExpressionImpl _condition;

  @override
  final Token? comma;

  /// The message to report if the assertion fails, or `null` if no message was
  /// supplied.
  ExpressionImpl? _message;

  @override
  final Token rightParenthesis;

  @override
  final Token semicolon;

  /// Initialize a newly created assert statement.
  AssertStatementImpl({
    required this.assertKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.comma,
    required ExpressionImpl? message,
    required this.rightParenthesis,
    required this.semicolon,
  })  : _condition = condition,
        _message = message {
    _becomeParentOf(_condition);
    _becomeParentOf(_message);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @override
  Token get endToken => semicolon;

  @override
  ExpressionImpl? get message => _message;

  set message(ExpressionImpl? expression) {
    _message = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('assertKeyword', assertKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('comma', comma)
    ..addNode('message', message)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAssertStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    message?.accept(visitor);
  }
}

/// A variable pattern in [PatternAssignment].
///
///    variablePattern ::= identifier
@experimental
class AssignedVariablePatternImpl extends VariablePatternImpl
    implements AssignedVariablePattern {
  @override
  Element? element;

  AssignedVariablePatternImpl({
    required super.name,
  });

  @override
  Token get beginToken => name;

  @override
  Token get endToken => name;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => ChildEntities()..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitAssignedVariablePattern(this);
  }

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    final element = this.element;
    if (element is PromotableElement) {
      return resolverVisitor.analyzeAssignedVariablePatternSchema(element);
    }
    return resolverVisitor.unknownType;
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.resolveAssignedVariablePattern(
      node: this,
      context: context,
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {}
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
  final Token operator;

  /// The expression used to compute the right hand side.
  ExpressionImpl _rightHandSide;

  /// The element associated with the operator based on the static type of the
  /// left-hand-side, or `null` if the AST structure has not been resolved, if
  /// the operator is not a compound operator, or if the operator could not be
  /// resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created assignment expression.
  AssignmentExpressionImpl({
    required ExpressionImpl leftHandSide,
    required this.operator,
    required ExpressionImpl rightHandSide,
  })  : _leftHandSide = leftHandSide,
        _rightHandSide = rightHandSide {
    _becomeParentOf(_leftHandSide);
    _becomeParentOf(_rightHandSide);
  }

  @override
  Token get beginToken => _leftHandSide.beginToken;

  @override
  Token get endToken => _rightHandSide.endToken;

  @override
  ExpressionImpl get leftHandSide => _leftHandSide;

  set leftHandSide(ExpressionImpl expression) {
    _leftHandSide = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  ExpressionImpl get rightHandSide => _rightHandSide;

  set rightHandSide(ExpressionImpl expression) {
    _rightHandSide = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('leftHandSide', leftHandSide)
    ..addToken('operator', operator)
    ..addNode('rightHandSide', rightHandSide);

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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAssignmentExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _leftHandSide.accept(visitor);
    _rightHandSide.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _leftHandSide);
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
  Iterable<SyntacticEntity> get childEntities =>
      _childEntities.syntacticEntities;

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

  /// Return properties (tokens and nodes) of this node, with names, in the
  /// order in which these entities should normally appear, not necessary in
  /// the order they really are (because of recovery).
  Iterable<ChildEntity> get namedChildEntities => _childEntities.entities;

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

  ChildEntities get _childEntities => ChildEntities();

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
  E? thisOrAncestorMatching<E extends AstNode>(
    bool Function(AstNode) predicate,
  ) {
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

/// An augmentation import directive.
///
///    importDirective ::=
///        [Annotation] 'import' 'augment' [StringLiteral] ';'
class AugmentationImportDirectiveImpl extends UriBasedDirectiveImpl
    implements AugmentationImportDirective {
  @override
  final Token importKeyword;

  @override
  final Token augmentKeyword;

  @override
  final Token semicolon;

  AugmentationImportDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.importKeyword,
    required this.augmentKeyword,
    required this.semicolon,
    required super.uri,
  }) {
    _becomeParentOf(_uri);
  }

  @override
  AugmentationImportElementImpl? get element {
    return super.element as AugmentationImportElementImpl?;
  }

  @Deprecated('Use element instead')
  @override
  AugmentationImportElement? get element2 => element;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => importKeyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('importKeyword', importKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addNode('uri', uri)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitAugmentationImportDirective(this);
  }
}

/// An await expression.
///
///    awaitExpression ::=
///        'await' [Expression]
class AwaitExpressionImpl extends ExpressionImpl implements AwaitExpression {
  /// The 'await' keyword.
  @override
  final Token awaitKeyword;

  /// The expression whose value is being waited on.
  ExpressionImpl _expression;

  /// Initialize a newly created await expression.
  AwaitExpressionImpl({
    required this.awaitKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    return awaitKeyword;
  }

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('awaitKeyword', awaitKeyword)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAwaitExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAwaitExpression(this, contextType: contextType);
  }

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
  final Token operator;

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
  BinaryExpressionImpl({
    required ExpressionImpl leftOperand,
    required this.operator,
    required ExpressionImpl rightOperand,
  })  : _leftOperand = leftOperand,
        _rightOperand = rightOperand {
    _becomeParentOf(leftOperand);
    _becomeParentOf(rightOperand);
  }

  @override
  Token get beginToken => _leftOperand.beginToken;

  @override
  Token get endToken => _rightOperand.endToken;

  @override
  ExpressionImpl get leftOperand => _leftOperand;

  set leftOperand(ExpressionImpl expression) {
    _leftOperand = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.forTokenType(operator.type);

  @override
  ExpressionImpl get rightOperand => _rightOperand;

  set rightOperand(ExpressionImpl expression) {
    _rightOperand = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('leftOperand', leftOperand)
    ..addToken('operator', operator)
    ..addNode('rightOperand', rightOperand);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBinaryExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitBinaryExpression(this, contextType: contextType);
  }

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
  final Token? keyword;

  /// The star optionally following the 'async' or 'sync' keyword, or `null` if
  /// there is wither no such keyword or no star.
  @override
  final Token? star;

  /// The block representing the body of the function.
  BlockImpl _block;

  /// Initialize a newly created function body consisting of a block of
  /// statements. The [keyword] can be `null` if there is no keyword specified
  /// for the block. The [star] can be `null` if there is no star following the
  /// keyword (and must be `null` if there is no keyword).
  BlockFunctionBodyImpl({
    required this.keyword,
    required this.star,
    required BlockImpl block,
  }) : _block = block {
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

  set block(BlockImpl block) {
    _block = _becomeParentOf(block);
  }

  @override
  Token get endToken => _block.endToken;

  @override
  bool get isAsynchronous => keyword?.lexeme == Keyword.ASYNC.lexeme;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword?.lexeme != Keyword.ASYNC.lexeme;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addToken('star', star)
    ..addNode('block', block);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBlockFunctionBody(this);

  @override
  DartType resolve(ResolverVisitor resolver, DartType? imposedType) =>
      resolver.visitBlockFunctionBody(this, imposedType: imposedType);

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
  final Token leftBracket;

  /// The statements contained in the block.
  final NodeListImpl<StatementImpl> _statements = NodeListImpl._();

  /// The right curly bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created block of code.
  BlockImpl({
    required this.leftBracket,
    required List<StatementImpl> statements,
    required this.rightBracket,
  }) {
    _statements._initialize(this, statements);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket;

  @override
  NodeListImpl<StatementImpl> get statements => _statements;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('statements', statements)
    ..addToken('rightBracket', rightBracket);

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
  final Token literal;

  /// The value of the literal.
  @override
  final bool value;

  /// Initialize a newly created boolean literal.
  BooleanLiteralImpl({
    required this.literal,
    required this.value,
  });

  @override
  Token get beginToken => literal;

  @override
  Token get endToken => literal;

  @override
  bool get isSynthetic => literal.isSynthetic;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBooleanLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitBooleanLiteral(this, contextType: contextType);
  }

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
  final Token breakKeyword;

  /// The label associated with the statement, or `null` if there is no label.
  SimpleIdentifierImpl? _label;

  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

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
  BreakStatementImpl({
    required this.breakKeyword,
    required SimpleIdentifierImpl? label,
    required this.semicolon,
  }) : _label = label {
    _becomeParentOf(_label);
  }

  @override
  Token get beginToken => breakKeyword;

  @override
  Token get endToken => semicolon;

  @override
  SimpleIdentifierImpl? get label => _label;

  set label(SimpleIdentifierImpl? identifier) {
    _label = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('breakKeyword', breakKeyword)
    ..addNode('label', label)
    ..addToken('semicolon', semicolon);

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
  final NodeListImpl<ExpressionImpl> _cascadeSections = NodeListImpl._();

  /// Initialize a newly created cascade expression. The list of
  /// [cascadeSections] must contain at least one element.
  CascadeExpressionImpl({
    required ExpressionImpl target,
    required List<ExpressionImpl> cascadeSections,
  }) : _target = target {
    _becomeParentOf(_target);
    _cascadeSections._initialize(this, cascadeSections);
  }

  @override
  Token get beginToken => _target.beginToken;

  @override
  NodeListImpl<ExpressionImpl> get cascadeSections => _cascadeSections;

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

  set target(ExpressionImpl target) {
    _target = _becomeParentOf(target);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addNodeList('cascadeSections', cascadeSections);

  @override
  AstNode? get _nullShortingExtensionCandidate => null;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCascadeExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitCascadeExpression(this, contextType: contextType);
  }

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

/// The `case` clause that can optionally appear in an `if` statement.
///
///    caseClause ::=
///        'case' [DartPattern] [WhenClause]?
///
/// Clients may not extend, implement or mix-in this class.
@experimental
class CaseClauseImpl extends AstNodeImpl implements CaseClause {
  @override
  final Token caseKeyword;

  @override
  final GuardedPatternImpl guardedPattern;

  CaseClauseImpl({
    required this.caseKeyword,
    required this.guardedPattern,
  }) {
    _becomeParentOf(guardedPattern);
  }

  @override
  Token get beginToken => caseKeyword;

  @override
  Token get endToken => guardedPattern.endToken;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('caseKeyword', caseKeyword)
    ..addNode('guardedPattern', guardedPattern);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCaseClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    guardedPattern.accept(visitor);
  }
}

/// A cast pattern.
///
///    castPattern ::=
///        [DartPattern] 'as' [TypeAnnotation]
@experimental
class CastPatternImpl extends DartPatternImpl implements CastPattern {
  @override
  final Token asToken;

  @override
  final DartPatternImpl pattern;

  @override
  final TypeAnnotationImpl type;

  CastPatternImpl({
    required this.pattern,
    required this.asToken,
    required this.type,
  }) {
    _becomeParentOf(pattern);
    _becomeParentOf(type);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => type.endToken;

  @override
  PatternPrecedence get precedence => PatternPrecedence.postfix;

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addToken('asToken', asToken)
    ..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCastPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeCastPatternSchema();
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    type.accept(resolverVisitor);
    resolverVisitor.analyzeCastPattern(
      context: context,
      pattern: this,
      innerPattern: pattern,
      requiredType: type.typeOrThrow,
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
    type.accept(visitor);
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
  final Token? onKeyword;

  /// The type of exceptions caught by this catch clause, or `null` if this
  /// catch clause catches every type of exception.
  TypeAnnotationImpl? _exceptionType;

  /// The token representing the 'catch' keyword, or `null` if there is no
  /// 'catch' keyword.
  @override
  final Token? catchKeyword;

  /// The left parenthesis, or `null` if there is no 'catch' keyword.
  @override
  final Token? leftParenthesis;

  /// The parameter whose value will be the exception that was thrown, or `null`
  /// if there is no 'catch' keyword.
  CatchClauseParameterImpl? _exceptionParameter;

  /// The comma separating the exception parameter from the stack trace
  /// parameter, or `null` if there is no stack trace parameter.
  @override
  final Token? comma;

  /// The parameter whose value will be the stack trace associated with the
  /// exception, or `null` if there is no stack trace parameter.
  CatchClauseParameterImpl? _stackTraceParameter;

  /// The right parenthesis, or `null` if there is no 'catch' keyword.
  @override
  final Token? rightParenthesis;

  /// The body of the catch block.
  BlockImpl _body;

  /// Initialize a newly created catch clause. The [onKeyword] and
  /// [exceptionType] can be `null` if the clause will catch all exceptions. The
  /// [comma] and [_stackTraceParameter] can be `null` if the stack trace
  /// parameter is not defined.
  CatchClauseImpl({
    required this.onKeyword,
    required TypeAnnotationImpl? exceptionType,
    required this.catchKeyword,
    required this.leftParenthesis,
    required CatchClauseParameterImpl? exceptionParameter,
    required this.comma,
    required CatchClauseParameterImpl? stackTraceParameter,
    required this.rightParenthesis,
    required BlockImpl body,
  })  : assert(onKeyword != null || catchKeyword != null),
        _exceptionType = exceptionType,
        _exceptionParameter = exceptionParameter,
        _stackTraceParameter = stackTraceParameter,
        _body = body {
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

  set body(BlockImpl block) {
    _body = _becomeParentOf(block);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  CatchClauseParameterImpl? get exceptionParameter {
    return _exceptionParameter;
  }

  set exceptionParameter(CatchClauseParameterImpl? parameter) {
    _exceptionParameter = parameter;
    _becomeParentOf(parameter);
  }

  @Deprecated('Use exceptionParameter instead')
  @override
  CatchClauseParameterImpl? get exceptionParameter2 {
    return exceptionParameter;
  }

  @override
  TypeAnnotationImpl? get exceptionType => _exceptionType;

  set exceptionType(TypeAnnotationImpl? exceptionType) {
    _exceptionType = _becomeParentOf(exceptionType);
  }

  @override
  CatchClauseParameterImpl? get stackTraceParameter {
    return _stackTraceParameter;
  }

  set stackTraceParameter(CatchClauseParameterImpl? parameter) {
    _stackTraceParameter = parameter;
    _becomeParentOf(parameter);
  }

  @Deprecated('Use stackTraceParameter instead')
  @override
  CatchClauseParameterImpl? get stackTraceParameter2 {
    return stackTraceParameter;
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('onKeyword', onKeyword)
    ..addNode('exceptionType', exceptionType)
    ..addToken('catchKeyword', catchKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('exceptionParameter', exceptionParameter)
    ..addToken('comma', comma)
    ..addNode('stackTraceParameter', stackTraceParameter)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

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

class CatchClauseParameterImpl extends AstNodeImpl
    implements CatchClauseParameter {
  @override
  final Token name;

  @override
  LocalVariableElement? declaredElement;

  CatchClauseParameterImpl({
    required this.name,
  });

  @override
  Token get beginToken => name;

  @override
  Token get endToken => name;

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitCatchClauseParameter(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// Helper class to allow iteration of child entities of an AST node.
class ChildEntities {
  /// The list of child entities to be iterated over.
  final List<ChildEntity> entities = [];

  List<SyntacticEntity> get syntacticEntities {
    var result = <SyntacticEntity>[];
    for (var entity in entities) {
      var entityValue = entity.value;
      if (entityValue is SyntacticEntity) {
        result.add(entityValue);
      } else if (entityValue is List<Object>) {
        for (var element in entityValue) {
          if (element is SyntacticEntity) {
            result.add(element);
          }
        }
      }
    }

    var needsSorting = false;
    int? lastOffset;
    for (var entity in result) {
      if (lastOffset != null && lastOffset > entity.offset) {
        needsSorting = true;
        break;
      }
      lastOffset = entity.offset;
    }

    if (needsSorting) {
      result.sort((a, b) => a.offset - b.offset);
    }

    return result;
  }

  void addAll(ChildEntities other) {
    entities.addAll(other.entities);
  }

  void addNode(String name, AstNode? value) {
    if (value != null) {
      entities.add(
        ChildEntity(name, value),
      );
    }
  }

  void addNodeList(String name, List<AstNode> value) {
    entities.add(
      ChildEntity(name, value),
    );
  }

  void addToken(String name, Token? value) {
    if (value != null) {
      entities.add(
        ChildEntity(name, value),
      );
    }
  }

  void addTokenList(String name, List<Token> value) {
    entities.add(
      ChildEntity(name, value),
    );
  }
}

/// A named child of an [AstNode], usually a token, node, or a list of nodes.
class ChildEntity {
  final String name;
  final Object value;

  ChildEntity(this.name, this.value);
}

/// The declaration of a class.
///
///    classDeclaration ::=
///        classModifiers 'class' [SimpleIdentifier] [TypeParameterList]?
///        ([ExtendsClause] [WithClause]?)?
///        [ImplementsClause]?
///        '{' [ClassMember]* '}'
///
///    classModifiers ::= 'sealed'
///      | 'abstract'? ('base' | 'interface' | 'final')?
///      | 'abstract'? 'base'? 'mixin'
///
class ClassDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements ClassDeclaration {
  /// The 'abstract' keyword, or `null` if the keyword was absent.
  @override
  final Token? abstractKeyword;

  /// The 'macro' keyword, or `null` if the keyword was absent.
  final Token? macroKeyword;

  /// The 'inline' keyword, or `null` if the keyword was absent.
  final Token? inlineKeyword;

  /// The 'sealed' keyword, or `null` if the keyword was absent.
  @override
  final Token? sealedKeyword;

  /// The 'base' keyword, or `null` if the keyword was absent.
  @override
  final Token? baseKeyword;

  /// The 'interface' keyword, or `null` if the keyword was absent.
  @override
  final Token? interfaceKeyword;

  /// The 'final' keyword, or `null` if the keyword was absent.
  @override
  final Token? finalKeyword;

  /// The 'augment' keyword, or `null` if the keyword was absent.
  final Token? augmentKeyword;

  /// The 'mixin' keyword, or `null` if the keyword was absent.
  @override
  final Token? mixinKeyword;

  /// The token representing the 'class' keyword.
  @override
  final Token classKeyword;

  /// The extends clause for the class, or `null` if the class does not extend
  /// any other class.
  ExtendsClauseImpl? _extendsClause;

  /// The type parameters for the class or mixin,
  /// or `null` if the declaration does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The with clause for the class, or `null` if the class does not have a with
  /// clause.
  WithClauseImpl? _withClause;

  /// The implements clause for the class or mixin,
  /// or `null` if the declaration does not implement any interfaces.
  ImplementsClauseImpl? _implementsClause;

  /// The native clause for the class, or `null` if the class does not have a
  /// native clause.
  NativeClauseImpl? _nativeClause;

  @override
  ClassElement? declaredElement;

  /// The left curly bracket.
  @override
  final Token leftBracket;

  /// The members defined by the class or mixin.
  final NodeListImpl<ClassMemberImpl> _members = NodeListImpl._();

  /// The right curly bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created class declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the class does not have the
  /// corresponding attribute. The [abstractKeyword] can be `null` if the class
  /// is not abstract. The [typeParameters] can be `null` if the class does not
  /// have any type parameters. Any or all of the [extendsClause], [withClause],
  /// and [implementsClause] can be `null` if the class does not have the
  /// corresponding clause. The list of [members] can be `null` if the class
  /// does not have any members.
  ClassDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.abstractKeyword,
    required this.macroKeyword,
    required this.inlineKeyword,
    required this.sealedKeyword,
    required this.baseKeyword,
    required this.interfaceKeyword,
    required this.finalKeyword,
    required this.augmentKeyword,
    required this.mixinKeyword,
    required this.classKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required ExtendsClauseImpl? extendsClause,
    required WithClauseImpl? withClause,
    required ImplementsClauseImpl? implementsClause,
    required NativeClauseImpl? nativeClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  })  : _typeParameters = typeParameters,
        _extendsClause = extendsClause,
        _withClause = withClause,
        _implementsClause = implementsClause,
        _nativeClause = nativeClause {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_extendsClause);
    _becomeParentOf(_withClause);
    _becomeParentOf(_implementsClause);
    _becomeParentOf(_nativeClause);
    _members._initialize(this, members);
  }

  @Deprecated('Use declaredElement instead')
  @override
  ClassElement? get declaredElement2 => declaredElement;

  @override
  Token get endToken => rightBracket;

  @override
  ExtendsClauseImpl? get extendsClause => _extendsClause;

  set extendsClause(ExtendsClauseImpl? extendsClause) {
    _extendsClause = _becomeParentOf(extendsClause);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return abstractKeyword ??
        macroKeyword ??
        inlineKeyword ??
        sealedKeyword ??
        baseKeyword ??
        interfaceKeyword ??
        finalKeyword ??
        augmentKeyword ??
        mixinKeyword ??
        classKeyword;
  }

  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @override
  NodeListImpl<ClassMemberImpl> get members => _members;

  @override
  NativeClauseImpl? get nativeClause => _nativeClause;

  set nativeClause(NativeClauseImpl? nativeClause) {
    _nativeClause = _becomeParentOf(nativeClause);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  WithClauseImpl? get withClause => _withClause;

  set withClause(WithClauseImpl? withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('abstractKeyword', abstractKeyword)
    ..addToken('macroKeyword', macroKeyword)
    ..addToken('inlineKeyword', inlineKeyword)
    ..addToken('sealedKeyword', sealedKeyword)
    ..addToken('baseKeyword', baseKeyword)
    ..addToken('interfaceKeyword', interfaceKeyword)
    ..addToken('finalKeyword', finalKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('mixinKeyword', mixinKeyword)
    ..addToken('classKeyword', classKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('extendsClause', extendsClause)
    ..addNode('withClause', withClause)
    ..addNode('implementsClause', implementsClause)
    ..addNode('nativeClause', nativeClause)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitClassDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
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
  ClassMemberImpl({
    required super.comment,
    required super.metadata,
  });
}

/// A class type alias.
///
///    classTypeAlias ::=
///        [SimpleIdentifier] [TypeParameterList]? '=' classModifiers
///        mixinApplication
///
///    classModifiers ::= 'sealed'
///      | 'abstract'? ('base' | 'interface' | 'final')?
///      | 'abstract'? 'base'? 'mixin'
///
///    mixinApplication ::=
///        [TypeName] [WithClause] [ImplementsClause]? ';'
class ClassTypeAliasImpl extends TypeAliasImpl implements ClassTypeAlias {
  /// The type parameters for the class, or `null` if the class does not have
  /// any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The token for the '=' separating the name from the definition.
  @override
  final Token equals;

  /// The token for the 'abstract' keyword, or `null` if this is not defining an
  /// abstract class.
  @override
  final Token? abstractKeyword;

  /// The token for the 'macro' keyword, or `null` if this is not defining a
  /// macro class.
  final Token? macroKeyword;

  /// The token for the 'inline' keyword, or `null` if this is not defining an
  /// inline class.
  final Token? inlineKeyword;

  /// The token for the 'sealed' keyword, or `null` if this is not defining a
  /// sealed class.
  @override
  final Token? sealedKeyword;

  /// The token for the 'base' keyword, or `null` if this is not defining a base
  /// class.
  @override
  final Token? baseKeyword;

  /// The token for the 'interface' keyword, or `null` if this is not defining
  /// an interface class.
  @override
  final Token? interfaceKeyword;

  /// The token for the 'final' keyword, or `null` if this is not defining a
  /// final class.
  @override
  final Token? finalKeyword;

  /// The token for the 'augment' keyword, or `null` if this is not defining an
  /// augmentation class.
  final Token? augmentKeyword;

  /// The token for the 'mixin' keyword, or `null` if this is not defining a
  /// mixin class.
  @override
  final Token? mixinKeyword;

  /// The name of the superclass of the class being declared.
  NamedTypeImpl _superclass;

  /// The with clause for this class.
  WithClauseImpl _withClause;

  /// The implements clause for this class, or `null` if there is no implements
  /// clause.
  ImplementsClauseImpl? _implementsClause;

  @override
  ClassElement? declaredElement;

  /// Initialize a newly created class type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the class type alias does not
  /// have the corresponding attribute. The [typeParameters] can be `null` if
  /// the class does not have any type parameters. The [abstractKeyword] can be
  /// `null` if the class is not abstract. The [implementsClause] can be `null`
  /// if the class does not implement any interfaces.
  ClassTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required super.typedefKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required this.equals,
    required this.abstractKeyword,
    required this.macroKeyword,
    required this.inlineKeyword,
    required this.sealedKeyword,
    required this.baseKeyword,
    required this.interfaceKeyword,
    required this.finalKeyword,
    required this.augmentKeyword,
    required this.mixinKeyword,
    required NamedTypeImpl superclass,
    required WithClauseImpl withClause,
    required ImplementsClauseImpl? implementsClause,
    required super.semicolon,
  })  : _typeParameters = typeParameters,
        _superclass = superclass,
        _withClause = withClause,
        _implementsClause = implementsClause {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_superclass);
    _becomeParentOf(_withClause);
    _becomeParentOf(_implementsClause);
  }

  @Deprecated('Use declaredElement instead')
  @override
  ClassElement? get declaredElement2 => declaredElement;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return abstractKeyword ??
        macroKeyword ??
        inlineKeyword ??
        sealedKeyword ??
        baseKeyword ??
        interfaceKeyword ??
        finalKeyword ??
        augmentKeyword ??
        mixinKeyword ??
        typedefKeyword;
  }

  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @override
  NamedTypeImpl get superclass => _superclass;

  set superclass(NamedTypeImpl superclass) {
    _superclass = _becomeParentOf(superclass);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  WithClauseImpl get withClause => _withClause;

  set withClause(WithClauseImpl withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('typedefKeyword', typedefKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addToken('equals', equals)
    ..addToken('abstractKeyword', abstractKeyword)
    ..addToken('inlineKeyword', inlineKeyword)
    ..addToken('macroKeyword', macroKeyword)
    ..addToken('sealedKeyword', sealedKeyword)
    ..addToken('baseKeyword', baseKeyword)
    ..addToken('interfaceKeyword', interfaceKeyword)
    ..addToken('finalKeyword', finalKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('mixinKeyword', mixinKeyword)
    ..addNode('superclass', superclass)
    ..addNode('withClause', withClause)
    ..addNode('implementsClause', implementsClause)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitClassTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _typeParameters?.accept(visitor);
    _superclass.accept(visitor);
    _withClause.accept(visitor);
    _implementsClause?.accept(visitor);
  }
}

abstract class CollectionElementImpl extends AstNodeImpl
    implements CollectionElement {
  /// Dispatches this collection element to the [resolver], with the given
  /// [context] information.
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context);
}

/// A combinator associated with an import or export directive.
///
///    combinator ::=
///        [HideCombinator]
///      | [ShowCombinator]
abstract class CombinatorImpl extends AstNodeImpl implements Combinator {
  /// The 'hide' or 'show' keyword specifying what kind of processing is to be
  /// done on the names.
  @override
  final Token keyword;

  /// Initialize a newly created combinator.
  CombinatorImpl({
    required this.keyword,
  });

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
  final NodeListImpl<CommentReferenceImpl> _references = NodeListImpl._();

  /// Initialize a newly created comment. The list of [tokens] must contain at
  /// least one token. The [_type] is the type of the comment. The list of
  /// [references] can be empty if the comment does not contain any embedded
  /// references.
  CommentImpl({
    required this.tokens,
    required CommentType type,
    required List<CommentReferenceImpl> references,
  }) : _type = type {
    _references._initialize(this, references);
  }

  @override
  Token get beginToken => tokens[0];

  @override
  Token get endToken => tokens[tokens.length - 1];

  @override
  bool get isBlock => _type == CommentType.BLOCK;

  @override
  bool get isDocumentation => _type == CommentType.DOCUMENTATION;

  @override
  bool get isEndOfLine => _type == CommentType.END_OF_LINE;

  @override
  NodeListImpl<CommentReferenceImpl> get references => _references;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('references', references)
    ..addTokenList('tokens', tokens);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitComment(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _references.accept(visitor);
  }
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
  final Token? newKeyword;

  /// The expression being referenced.
  CommentReferableExpressionImpl _expression;

  /// Initialize a newly created reference to a Dart element. The [newKeyword]
  /// can be `null` if the reference is not to a constructor.
  CommentReferenceImpl({
    required this.newKeyword,
    required CommentReferableExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => newKeyword ?? _expression.beginToken;

  @override
  Token get endToken => _expression.endToken;

  @override
  CommentReferableExpressionImpl get expression => _expression;

  set expression(CommentReferableExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('newKeyword', newKeyword)
    ..addNode('expression', expression);

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
  final NodeListImpl<DirectiveImpl> _directives = NodeListImpl._();

  /// The declarations contained in this compilation unit.
  final NodeListImpl<CompilationUnitMemberImpl> _declarations =
      NodeListImpl._();

  /// The last token in the token stream that was parsed to form this
  /// compilation unit. This token should always have a type of [TokenType.EOF].
  @override
  final Token endToken;

  /// The element associated with this compilation unit, or `null` if the AST
  /// structure has not been resolved.
  @override
  CompilationUnitElement? declaredElement;

  /// The line information for this compilation unit.
  @override
  final LineInfo lineInfo;

  /// The language version information.
  LibraryLanguageVersion? languageVersion;

  @override
  final FeatureSet featureSet;

  /// Initialize a newly created compilation unit to have the given directives
  /// and declarations. The [scriptTag] can be `null` if there is no script tag
  /// in the compilation unit. The list of [directives] can be `null` if there
  /// are no directives in the compilation unit. The list of [declarations] can
  /// be `null` if there are no declarations in the compilation unit.
  CompilationUnitImpl({
    required this.beginToken,
    required ScriptTagImpl? scriptTag,
    required List<DirectiveImpl>? directives,
    required List<CompilationUnitMemberImpl>? declarations,
    required this.endToken,
    required this.featureSet,
    required this.lineInfo,
  }) : _scriptTag = scriptTag {
    _becomeParentOf(_scriptTag);
    _directives._initialize(this, directives);
    _declarations._initialize(this, declarations);
  }

  @override
  NodeListImpl<CompilationUnitMemberImpl> get declarations => _declarations;

  @override
  NodeListImpl<DirectiveImpl> get directives => _directives;

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
  ScriptTagImpl? get scriptTag => _scriptTag;

  set scriptTag(ScriptTagImpl? scriptTag) {
    _scriptTag = _becomeParentOf(scriptTag);
  }

  @override
  List<AstNode> get sortedDirectivesAndDeclarations {
    return <AstNode>[
      ..._directives,
      ..._declarations,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  @override
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addNode('scriptTag', scriptTag)
      ..addNodeList('directives', directives)
      ..addNodeList('declarations', declarations);
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
  CompilationUnitMemberImpl({
    required super.comment,
    required super.metadata,
  });
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
  final Token question;

  /// The expression that is executed if the condition evaluates to `true`.
  ExpressionImpl _thenExpression;

  /// The token used to separate the then expression from the else expression.
  @override
  final Token colon;

  /// The expression that is executed if the condition evaluates to `false`.
  ExpressionImpl _elseExpression;

  /// Initialize a newly created conditional expression.
  ConditionalExpressionImpl({
    required ExpressionImpl condition,
    required this.question,
    required ExpressionImpl thenExpression,
    required this.colon,
    required ExpressionImpl elseExpression,
  })  : _condition = condition,
        _thenExpression = thenExpression,
        _elseExpression = elseExpression {
    _becomeParentOf(_condition);
    _becomeParentOf(_thenExpression);
    _becomeParentOf(_elseExpression);
  }

  @override
  Token get beginToken => _condition.beginToken;

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  ExpressionImpl get elseExpression => _elseExpression;

  set elseExpression(ExpressionImpl expression) {
    _elseExpression = _becomeParentOf(expression);
  }

  @override
  Token get endToken => _elseExpression.endToken;

  @override
  Precedence get precedence => Precedence.conditional;

  @override
  ExpressionImpl get thenExpression => _thenExpression;

  set thenExpression(ExpressionImpl expression) {
    _thenExpression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('condition', condition)
    ..addToken('question', question)
    ..addNode('thenExpression', thenExpression)
    ..addToken('colon', colon)
    ..addNode('elseExpression', elseExpression);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConditionalExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitConditionalExpression(this, contextType: contextType);
  }

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
  final Token ifKeyword;

  @override
  final Token leftParenthesis;

  DottedNameImpl _name;

  @override
  final Token? equalToken;

  StringLiteralImpl? _value;

  @override
  final Token rightParenthesis;

  StringLiteralImpl _uri;

  @override
  DirectiveUri? resolvedUri;

  ConfigurationImpl({
    required this.ifKeyword,
    required this.leftParenthesis,
    required DottedNameImpl name,
    required this.equalToken,
    required StringLiteralImpl? value,
    required this.rightParenthesis,
    required StringLiteralImpl uri,
  })  : _name = name,
        _value = value,
        _uri = uri {
    _becomeParentOf(_name);
    _becomeParentOf(_value);
    _becomeParentOf(_uri);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  Token get endToken => _uri.endToken;

  @override
  DottedNameImpl get name => _name;

  set name(DottedNameImpl name) {
    _name = _becomeParentOf(name);
  }

  @override
  StringLiteralImpl get uri => _uri;

  set uri(StringLiteralImpl uri) {
    _uri = _becomeParentOf(uri);
  }

  @override
  StringLiteralImpl? get value => _value;

  set value(StringLiteralImpl? value) {
    _value = _becomeParentOf(value as StringLiteralImpl);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('ifKeyword', ifKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('name', name)
    ..addToken('equalToken', equalToken)
    ..addNode('value', value)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('uri', uri);

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
  final Element variable;
  final ExpressionImpl expression;

  ConstantContextForExpressionImpl(this.variable, this.expression) {
    _becomeParentOf(expression);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An expression being used as a pattern.
///
/// The only expressions that can be validly used as a pattern are `bool`,
/// `double`, `int`, `null`, and `String` literals and references to constant
/// variables.
///
/// This node is also used to recover from cases where a different kind of
/// expression is used as a pattern, so clients need to handle the case where
/// the expression is not one of the valid alternatives.
///
///    constantPattern ::=
///        'const'? [Expression]
@experimental
class ConstantPatternImpl extends DartPatternImpl implements ConstantPattern {
  @override
  final Token? constKeyword;

  ExpressionImpl _expression;

  ConstantPatternImpl({
    required this.constKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @override
  Token get beginToken => expression.beginToken;

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('const', constKeyword)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConstantPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeConstantPatternSchema();
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeConstantPattern(context, this, expression);
    expression = resolverVisitor.popRewrite()!;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }
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
  final Token? externalKeyword;

  /// The token for the 'const' keyword, or `null` if the constructor is not a
  /// const constructor.
  @override
  Token? constKeyword;

  /// The token for the 'factory' keyword, or `null` if the constructor is not a
  /// factory constructor.
  @override
  final Token? factoryKeyword;

  /// The type of object being created. This can be different than the type in
  /// which the constructor is being declared if the constructor is the
  /// implementation of a factory constructor.
  IdentifierImpl _returnType;

  /// The token for the period before the constructor name, or `null` if the
  /// constructor being declared is unnamed.
  @override
  final Token? period;

  /// The name of the constructor, or `null` if the constructor being declared
  /// is unnamed.
  @override
  final Token? name;

  /// The parameters associated with the constructor.
  FormalParameterListImpl _parameters;

  /// The token for the separator (colon or equals) before the initializer list
  /// or redirection, or `null` if there are no initializers.
  @override
  Token? separator;

  /// The initializers associated with the constructor.
  final NodeListImpl<ConstructorInitializerImpl> _initializers =
      NodeListImpl._();

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
  ConstructorDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.externalKeyword,
    required this.constKeyword,
    required this.factoryKeyword,
    required IdentifierImpl returnType,
    required this.period,
    required this.name,
    required FormalParameterListImpl parameters,
    required this.separator,
    required List<ConstructorInitializerImpl>? initializers,
    required ConstructorNameImpl? redirectedConstructor,
    required FunctionBodyImpl body,
  })  : _returnType = returnType,
        _parameters = parameters,
        _redirectedConstructor = redirectedConstructor,
        _body = body {
    _becomeParentOf(_returnType);
    _becomeParentOf(_parameters);
    _initializers._initialize(this, initializers);
    _becomeParentOf(_redirectedConstructor);
    _becomeParentOf(_body);
  }

  @override
  FunctionBodyImpl get body => _body;

  set body(FunctionBodyImpl functionBody) {
    _body = _becomeParentOf(functionBody);
  }

  @Deprecated('Use declaredElement instead')
  @override
  ConstructorElement? get declaredElement2 => declaredElement;

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
  NodeListImpl<ConstructorInitializerImpl> get initializers => _initializers;

  // A trivial constructor is a generative constructor that is not a
  // redirecting constructor, declares no parameters, has no
  // initializer list, has no body, and is not external.
  bool get isTrivial =>
      redirectedConstructor == null &&
      parameters.parameters.isEmpty &&
      initializers.isEmpty &&
      body is EmptyFunctionBody &&
      externalKeyword == null;

  @Deprecated('Use name instead')
  @override
  Token? get name2 => name;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  ConstructorNameImpl? get redirectedConstructor => _redirectedConstructor;

  set redirectedConstructor(ConstructorNameImpl? redirectedConstructor) {
    _redirectedConstructor =
        _becomeParentOf(redirectedConstructor as ConstructorNameImpl);
  }

  @override
  IdentifierImpl get returnType => _returnType;

  set returnType(IdentifierImpl typeName) {
    _returnType = _becomeParentOf(typeName);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('externalKeyword', externalKeyword)
    ..addToken('constKeyword', constKeyword)
    ..addToken('factoryKeyword', factoryKeyword)
    ..addNode('returnType', returnType)
    ..addToken('period', period)
    ..addToken('name', name)
    ..addNode('parameters', parameters)
    ..addToken('separator', separator)
    ..addNodeList('initializers', initializers)
    ..addNode('redirectedConstructor', redirectedConstructor)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType.accept(visitor);
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
  final Token? thisKeyword;

  /// The token for the period after the 'this' keyword, or `null` if there is
  /// no 'this' keyword.
  @override
  final Token? period;

  /// The name of the field being initialized.
  SimpleIdentifierImpl _fieldName;

  /// The token for the equal sign between the field name and the expression.
  @override
  final Token equals;

  /// The expression computing the value to which the field will be initialized.
  ExpressionImpl _expression;

  /// Initialize a newly created field initializer to initialize the field with
  /// the given name to the value of the given expression. The [thisKeyword] and
  /// [period] can be `null` if the 'this' keyword was not specified.
  ConstructorFieldInitializerImpl({
    required this.thisKeyword,
    required this.period,
    required SimpleIdentifierImpl fieldName,
    required this.equals,
    required ExpressionImpl expression,
  })  : _fieldName = fieldName,
        _expression = expression {
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
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  SimpleIdentifierImpl get fieldName => _fieldName;

  set fieldName(SimpleIdentifierImpl identifier) {
    _fieldName = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('thisKeyword', thisKeyword)
    ..addToken('period', period)
    ..addNode('fieldName', fieldName)
    ..addToken('equals', equals)
    ..addNode('expression', expression);

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
  ConstructorNameImpl({
    required NamedTypeImpl type,
    required this.period,
    required SimpleIdentifierImpl? name,
  })  : _type = type,
        _name = name {
    _becomeParentOf(_type);
    _becomeParentOf(_name);
  }

  @override
  Token get beginToken => _type.beginToken;

  @override
  Token get endToken {
    if (_name != null) {
      return _name!.endToken;
    }
    return _type.endToken;
  }

  @override
  SimpleIdentifierImpl? get name => _name;

  set name(SimpleIdentifierImpl? name) {
    _name = _becomeParentOf(name);
  }

  @override
  NamedTypeImpl get type => _type;

  set type(NamedTypeImpl type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('type', type)
    ..addToken('period', period)
    ..addNode('name', name);

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

  ConstructorReferenceImpl({
    required ConstructorNameImpl constructorName,
  }) : _constructorName = constructorName {
    _becomeParentOf(_constructorName);
  }

  @override
  Token get beginToken => constructorName.beginToken;

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
  ChildEntities get _childEntities =>
      ChildEntities()..addNode('constructorName', constructorName);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorReference(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitConstructorReference(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    constructorName.accept(visitor);
  }
}

class ConstructorSelectorImpl extends AstNodeImpl
    implements ConstructorSelector {
  @override
  final Token period;

  @override
  final SimpleIdentifierImpl name;

  ConstructorSelectorImpl({
    required this.period,
    required this.name,
  }) {
    _becomeParentOf(name);
  }

  @override
  Token get beginToken => period;

  @override
  Token get endToken => name.token;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('period', period)
    ..addNode('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitConstructorSelector(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// A continue statement.
///
///    continueStatement ::=
///        'continue' [SimpleIdentifier]? ';'
class ContinueStatementImpl extends StatementImpl implements ContinueStatement {
  /// The token representing the 'continue' keyword.
  @override
  final Token continueKeyword;

  /// The label associated with the statement, or `null` if there is no label.
  SimpleIdentifierImpl? _label;

  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

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
  ContinueStatementImpl({
    required this.continueKeyword,
    required SimpleIdentifierImpl? label,
    required this.semicolon,
  }) : _label = label {
    _becomeParentOf(_label);
  }

  @override
  Token get beginToken => continueKeyword;

  @override
  Token get endToken => semicolon;

  @override
  SimpleIdentifierImpl? get label => _label;

  set label(SimpleIdentifierImpl? identifier) {
    _label = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('continueKeyword', continueKeyword)
    ..addNode('label', label)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitContinueStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label?.accept(visitor);
  }
}

/// A pattern.
///
///    pattern ::=
///        [AssignedVariablePattern]
///      | [DeclaredVariablePattern]
///      | [CastPattern]
///      | [ConstantPattern]
///      | [ListPattern]
///      | [LogicalAndPattern]
///      | [LogicalOrPattern]
///      | [MapPattern]
///      | [ObjectPattern]
///      | [ParenthesizedPattern]
///      | [PostfixPattern]
///      | [RecordPattern]
///      | [RelationalPattern]
@experimental
abstract class DartPatternImpl extends AstNodeImpl
    implements DartPattern, ListPatternElementImpl {
  @override
  DartType? matchedValueType;

  @override
  DartPattern get unParenthesized => this;

  /// The variable pattern, itself, or wrapped in a unary pattern.
  VariablePatternImpl? get variablePattern => null;

  DartType computePatternSchema(ResolverVisitor resolverVisitor);

  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  );
}

/// A node that represents the declaration of one or more names. Each declared
/// name is visible within a name scope.
abstract class DeclarationImpl extends AnnotatedNodeImpl
    implements Declaration {
  /// Initialize a newly created declaration. Either or both of the [comment]
  /// and [metadata] can be `null` if the declaration does not have the
  /// corresponding attribute.
  DeclarationImpl({
    required super.comment,
    required super.metadata,
  });
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
  final Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  @override
  final Token name;

  @override
  LocalVariableElement? declaredElement;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [keyword] can be `null` if a type name is
  /// given. The [type] must be `null` if the keyword is 'var'.
  DeclaredIdentifierImpl({
    required super.comment,
    required super.metadata,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required this.name,
  }) : _type = type {
    _becomeParentOf(_type);
  }

  @Deprecated('Use declaredElement instead')
  @override
  LocalVariableElement? get declaredElement2 => declaredElement;

  @override
  Token get endToken => name;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return keyword ?? _type?.beginToken ?? name;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDeclaredIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
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
  DeclaredSimpleIdentifier(super.token);

  @override
  bool inDeclarationContext() => true;
}

/// A variable pattern.
///
///    variablePattern ::=
///        ( 'var' | 'final' | 'final'? [TypeAnnotation])? [Identifier]
@experimental
class DeclaredVariablePatternImpl extends VariablePatternImpl
    implements DeclaredVariablePattern {
  @override
  BindPatternVariableElementImpl? declaredElement;

  @override
  final Token? keyword;

  @override
  final TypeAnnotationImpl? type;

  DeclaredVariablePatternImpl({
    required this.keyword,
    required this.type,
    required super.name,
  }) {
    _becomeParentOf(type);
  }

  @override
  Token get beginToken => type?.beginToken ?? name;

  @override
  Token get endToken => name;

  /// If [keyword] is `final`, returns it.
  Token? get finalKeyword {
    final keyword = this.keyword;
    if (keyword != null && keyword.keyword == Keyword.FINAL) {
      return keyword;
    }
    return null;
  }

  /// Returns the context for this pattern.
  /// * Declaration context: [PatternVariableDeclarationImpl]
  /// * Assignment context: [PatternAssignmentImpl]
  /// * Matching context: [GuardedPatternImpl]
  AstNodeImpl? get patternContext {
    for (DartPatternImpl current = this;;) {
      var parent = current.parent;
      if (parent is MapPatternEntry) {
        parent = parent.parent;
      } else if (parent is PatternFieldImpl) {
        parent = parent.parent;
      } else if (parent is RestPatternElementImpl) {
        parent = parent.parent;
      }
      if (parent is ForEachPartsWithPatternImpl) {
        return parent;
      } else if (parent is PatternVariableDeclarationImpl) {
        return parent;
      } else if (parent is PatternAssignmentImpl) {
        return parent;
      } else if (parent is GuardedPatternImpl) {
        return parent;
      } else if (parent is DartPatternImpl) {
        current = parent;
      } else {
        return null;
      }
    }
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDeclaredVariablePattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeDeclaredVariablePatternSchema(type?.typeOrThrow);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    declaredElement!.type = resolverVisitor.analyzeDeclaredVariablePattern(
        context,
        this,
        declaredElement!,
        declaredElement!.name,
        type?.typeOrThrow);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    type?.accept(visitor);
  }
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
  final Token? separator;

  /// The expression computing the default value for the parameter, or `null` if
  /// there is no default value.
  ExpressionImpl? _defaultValue;

  /// Initialize a newly created default formal parameter. The [separator] and
  /// [defaultValue] can be `null` if there is no default value.
  DefaultFormalParameterImpl({
    required NormalFormalParameterImpl parameter,
    required this.kind,
    required this.separator,
    required ExpressionImpl? defaultValue,
  })  : _parameter = parameter,
        _defaultValue = defaultValue {
    _becomeParentOf(_parameter);
    _becomeParentOf(_defaultValue);
  }

  @override
  Token get beginToken => _parameter.beginToken;

  @override
  Token? get covariantKeyword => null;

  @override
  ParameterElementImpl? get declaredElement => _parameter.declaredElement;

  @override
  ExpressionImpl? get defaultValue => _defaultValue;

  set defaultValue(ExpressionImpl? expression) {
    _defaultValue = _becomeParentOf(expression);
  }

  @override
  Token get endToken {
    if (_defaultValue != null) {
      return _defaultValue!.endToken;
    }
    return _parameter.endToken;
  }

  @override
  bool get isConst => _parameter.isConst;

  @override
  bool get isExplicitlyTyped => _parameter.isExplicitlyTyped;

  @override
  bool get isFinal => _parameter.isFinal;

  @override
  NodeListImpl<AnnotationImpl> get metadata => _parameter.metadata;

  @override
  Token? get name => _parameter.name;

  @override
  NormalFormalParameterImpl get parameter => _parameter;

  set parameter(NormalFormalParameterImpl formalParameter) {
    _parameter = _becomeParentOf(formalParameter);
  }

  @override
  Token? get requiredKeyword => null;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('parameter', parameter)
    ..addToken('separator', separator)
    ..addNode('defaultValue', defaultValue);

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
///        [AugmentationImportDirective]
///      | [ExportDirective]
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
  DirectiveImpl({
    required super.comment,
    required super.metadata,
  });

  @override
  Element? get element => _element;

  /// Set the element associated with this directive to be the given [element].
  set element(Element? element) {
    _element = element;
  }

  @Deprecated('Use element instead')
  @override
  Element? get element2 => element;
}

/// A do statement.
///
///    doStatement ::=
///        'do' [Statement] 'while' '(' [Expression] ')' ';'
class DoStatementImpl extends StatementImpl implements DoStatement {
  /// The token representing the 'do' keyword.
  @override
  final Token doKeyword;

  /// The body of the loop.
  StatementImpl _body;

  /// The token representing the 'while' keyword.
  @override
  final Token whileKeyword;

  /// The left parenthesis.
  @override
  final Token leftParenthesis;

  /// The condition that determines when the loop will terminate.
  ExpressionImpl _condition;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

  /// Initialize a newly created do loop.
  DoStatementImpl({
    required this.doKeyword,
    required StatementImpl body,
    required this.whileKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.rightParenthesis,
    required this.semicolon,
  })  : _body = body,
        _condition = condition {
    _becomeParentOf(_body);
    _becomeParentOf(_condition);
  }

  @override
  Token get beginToken => doKeyword;

  @override
  StatementImpl get body => _body;

  set body(StatementImpl statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  Token get endToken => semicolon;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('doKeyword', doKeyword)
    ..addNode('body', body)
    ..addToken('whileKeyword', whileKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('semicolon', semicolon);

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
  final NodeListImpl<SimpleIdentifierImpl> _components = NodeListImpl._();

  /// Initialize a newly created dotted name.
  DottedNameImpl({
    required List<SimpleIdentifierImpl> components,
  }) {
    _components._initialize(this, components);
  }

  @override
  Token get beginToken => _components.beginToken!;

  @override
  NodeListImpl<SimpleIdentifierImpl> get components => _components;

  @override
  Token get endToken => _components.endToken!;

  @override
  // TODO(paulberry): add "." tokens.
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('components', components);

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
  final Token literal;

  /// The value of the literal.
  @override
  double value;

  /// Initialize a newly created floating point literal.
  DoubleLiteralImpl({
    required this.literal,
    required this.value,
  });

  @override
  Token get beginToken => literal;

  @override
  Token get endToken => literal;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDoubleLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitDoubleLiteral(this, contextType: contextType);
  }

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
  final Token semicolon;

  /// Initialize a newly created function body.
  EmptyFunctionBodyImpl({
    required this.semicolon,
  });

  @override
  Token get beginToken => semicolon;

  @override
  Token get endToken => semicolon;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyFunctionBody(this);

  @override
  DartType resolve(ResolverVisitor resolver, DartType? imposedType) =>
      resolver.visitEmptyFunctionBody(this, imposedType: imposedType);

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
  final Token semicolon;

  /// Initialize a newly created empty statement.
  EmptyStatementImpl({
    required this.semicolon,
  });

  @override
  Token get beginToken => semicolon;

  @override
  Token get endToken => semicolon;

  @override
  bool get isSynthetic => semicolon.isSynthetic;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

class EnumConstantArgumentsImpl extends AstNodeImpl
    implements EnumConstantArguments {
  @override
  final TypeArgumentListImpl? typeArguments;

  @override
  final ConstructorSelectorImpl? constructorSelector;

  @override
  final ArgumentListImpl argumentList;

  EnumConstantArgumentsImpl({
    required this.typeArguments,
    required this.constructorSelector,
    required this.argumentList,
  }) {
    _becomeParentOf(typeArguments);
    _becomeParentOf(constructorSelector);
    _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken =>
      (typeArguments ?? constructorSelector ?? argumentList).beginToken;

  @override
  Token get endToken => argumentList.endToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('typeArguments', typeArguments)
    ..addNode('constructorSelector', constructorSelector)
    ..addNode('argumentList', argumentList);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitEnumConstantArguments(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    constructorSelector?.accept(visitor);
    argumentList.accept(visitor);
  }
}

/// The declaration of an enum constant.
class EnumConstantDeclarationImpl extends DeclarationImpl
    implements EnumConstantDeclaration {
  @override
  final Token name;

  @override
  FieldElement? declaredElement;

  @override
  final EnumConstantArgumentsImpl? arguments;

  @override
  ConstructorElement? constructorElement;

  /// Initialize a newly created enum constant declaration. Either or both of
  /// the [documentationComment] and [metadata] can be `null` if the constant
  /// does not have the corresponding attribute.
  EnumConstantDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.name,
    required this.arguments,
  }) {
    _becomeParentOf(arguments);
  }

  @Deprecated('Use declaredElement instead')
  @override
  FieldElement? get declaredElement2 => declaredElement;

  @override
  Token get endToken => arguments?.endToken ?? name;

  @override
  Token get firstTokenAfterCommentAndMetadata => name;

  @Deprecated('Use name instead')
  @override
  Token get name2 => name;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('name', name)
    ..addNode('arguments', arguments);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitEnumConstantDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    arguments?.accept(visitor);
  }
}

/// The declaration of an enumeration.
///
///    enumType ::=
///        metadata 'enum' [SimpleIdentifier] [TypeParameterList]?
///        [WithClause]? [ImplementsClause]? '{' [SimpleIdentifier]
///        (',' [SimpleIdentifier])* (';' [ClassMember]+)? '}'
class EnumDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements EnumDeclaration {
  /// The 'enum' keyword.
  @override
  final Token enumKeyword;

  /// The type parameters, or `null` if the enumeration does not have any
  /// type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The `with` clause for the enumeration, or `null` if the class does not
  /// have a `with` clause.
  WithClauseImpl? _withClause;

  /// The `implements` clause for the enumeration, or `null` if the enumeration
  /// does not implement any interfaces.
  ImplementsClauseImpl? _implementsClause;

  /// The left curly bracket.
  @override
  final Token leftBracket;

  /// The enumeration constants being declared.
  final NodeListImpl<EnumConstantDeclarationImpl> _constants = NodeListImpl._();

  @override
  final Token? semicolon;

  /// The members defined by the enum.
  final NodeListImpl<ClassMemberImpl> _members = NodeListImpl._();

  /// The right curly bracket.
  @override
  final Token rightBracket;

  @override
  EnumElement? declaredElement;

  /// Initialize a newly created enumeration declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The list of [constants] must contain at least
  /// one value.
  EnumDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.enumKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required WithClauseImpl? withClause,
    required ImplementsClauseImpl? implementsClause,
    required this.leftBracket,
    required List<EnumConstantDeclarationImpl> constants,
    required this.semicolon,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  })  : _typeParameters = typeParameters,
        _withClause = withClause,
        _implementsClause = implementsClause {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_withClause);
    _becomeParentOf(_implementsClause);
    _constants._initialize(this, constants);
    _members._initialize(this, members);
  }

  @override
  NodeListImpl<EnumConstantDeclarationImpl> get constants => _constants;

  @Deprecated('Use declaredElement instead')
  @override
  EnumElement? get declaredElement2 => declaredElement;

  @override
  Token get endToken => rightBracket;

  @override
  Token get firstTokenAfterCommentAndMetadata => enumKeyword;

  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @override
  NodeListImpl<ClassMemberImpl> get members => _members;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  WithClauseImpl? get withClause => _withClause;

  set withClause(WithClauseImpl? withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @override
  // TODO(brianwilkerson) Add commas?
  ChildEntities get _childEntities => super._childEntities
    ..addToken('enumKeyword', enumKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('withClause', withClause)
    ..addNode('implementsClause', implementsClause)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('constants', constants)
    ..addToken('semicolon', semicolon)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEnumDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _typeParameters?.accept(visitor);
    _withClause?.accept(visitor);
    _implementsClause?.accept(visitor);
    _constants.accept(visitor);
    _members.accept(visitor);
  }
}

/// An export directive.
///
///    exportDirective ::=
///        [Annotation] 'export' [StringLiteral] [Combinator]* ';'
class ExportDirectiveImpl extends NamespaceDirectiveImpl
    implements ExportDirective {
  @override
  final Token exportKeyword;

  /// Initialize a newly created export directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute. The list of [combinators] can be `null` if there
  /// are no combinators.
  ExportDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.exportKeyword,
    required super.uri,
    required super.configurations,
    required super.combinators,
    required super.semicolon,
  });

  @override
  LibraryExportElementImpl? get element {
    return super.element as LibraryExportElementImpl?;
  }

  @Deprecated('Use element instead')
  @override
  LibraryExportElementImpl? get element2 => element;

  @override
  Token get firstTokenAfterCommentAndMetadata => exportKeyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('exportKeyword', exportKeyword)
    ..addNode('uri', uri)
    ..addNodeList('combinators', combinators)
    ..addNodeList('configurations', configurations)
    ..addToken('semicolon', semicolon);

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
  final Token? keyword;

  /// The star optionally following the 'async' or 'sync' keyword, or `null` if
  /// there is wither no such keyword or no star.
  ///
  /// It is an error for an expression function body to feature the star, but
  /// the parser will accept it.
  @override
  final Token? star;

  /// The token introducing the expression that represents the body of the
  /// function.
  @override
  final Token functionDefinition;

  /// The expression representing the body of the function.
  ExpressionImpl _expression;

  /// The semicolon terminating the statement.
  @override
  final Token? semicolon;

  /// Initialize a newly created function body consisting of a block of
  /// statements. The [keyword] can be `null` if the function body is not an
  /// async function body.
  ExpressionFunctionBodyImpl({
    required this.keyword,
    required this.star,
    required this.functionDefinition,
    required ExpressionImpl expression,
    required this.semicolon,
  }) : _expression = expression {
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
  Token get endToken {
    if (semicolon != null) {
      return semicolon!;
    }
    return _expression.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isAsynchronous => keyword?.lexeme == Keyword.ASYNC.lexeme;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword?.lexeme != Keyword.ASYNC.lexeme;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addToken('star', star)
    ..addToken('functionDefinition', functionDefinition)
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExpressionFunctionBody(this);

  @override
  DartType resolve(ResolverVisitor resolver, DartType? imposedType) =>
      resolver.visitExpressionFunctionBody(this, imposedType: imposedType);

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
      } else if (parent is ConstantPatternImpl) {
        return true;
      } else if (parent is EnumConstantArguments) {
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
      } else if (parent is RecordLiteral && parent.constKeyword != null) {
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
      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/49102
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
      // TODO(scheglov) This does not look right, there is no element for
      // the operand, for `a++` we invoke `a = a + 1`, so the parameter
      // is for `1`, not for `a`.
      return parent._staticParameterElementForOperand;
    } else if (parent is PostfixExpressionImpl) {
      // TODO(scheglov) The same as above.
      return parent._staticParameterElementForOperand;
    }
    return null;
  }

  @override
  ExpressionImpl get unParenthesized => this;

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.analyzeExpression(this, context?.elementType);
  }

  /// Dispatches this expression to the [resolver], with the given [contextType]
  /// information.
  ///
  /// Note: most code shouldn't call this method directly, but should instead
  /// call [ResolverVisitor.analyzeExpression], which has some special logic for
  /// handling dynamic contexts.
  void resolveExpression(ResolverVisitor resolver, DartType contextType);
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
  final Token? semicolon;

  /// Initialize a newly created expression statement.
  ExpressionStatementImpl({
    required ExpressionImpl expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Token get endToken {
    if (semicolon != null) {
      return semicolon!;
    }
    return _expression.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isSynthetic =>
      _expression.isSynthetic && (semicolon == null || semicolon!.isSynthetic);

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

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
  final Token extendsKeyword;

  /// The name of the class that is being extended.
  NamedTypeImpl _superclass;

  /// Initialize a newly created extends clause.
  ExtendsClauseImpl({
    required this.extendsKeyword,
    required NamedTypeImpl superclass,
  }) : _superclass = superclass {
    _becomeParentOf(_superclass);
  }

  @override
  Token get beginToken => extendsKeyword;

  @override
  Token get endToken => _superclass.endToken;

  @override
  NamedTypeImpl get superclass => _superclass;

  set superclass(NamedTypeImpl name) {
    _superclass = _becomeParentOf(name);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('extendsKeyword', extendsKeyword)
    ..addNode('superclass', superclass);

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
  final Token extensionKeyword;

  @override
  final Token? typeKeyword;

  @override
  final Token? name;

  /// The type parameters for the extension, or `null` if the extension does not
  /// have any type parameters.
  TypeParameterListImpl? _typeParameters;

  @override
  final Token onKeyword;

  /// The type that is being extended.
  TypeAnnotationImpl _extendedType;

  @override
  final Token leftBracket;

  /// The members being added to the extended class.
  final NodeListImpl<ClassMemberImpl> _members = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  ExtensionElement? declaredElement;

  ExtensionDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.extensionKeyword,
    required this.typeKeyword,
    required this.name,
    required TypeParameterListImpl? typeParameters,
    required this.onKeyword,
    required TypeAnnotationImpl extendedType,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  })  : _typeParameters = typeParameters,
        _extendedType = extendedType {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_extendedType);
    _members._initialize(this, members);
  }

  @Deprecated('Use declaredElement instead')
  @override
  ExtensionElement? get declaredElement2 => declaredElement;

  @override
  Token get endToken => rightBracket;

  @override
  TypeAnnotationImpl get extendedType => _extendedType;

  set extendedType(TypeAnnotationImpl extendedClass) {
    _extendedType = _becomeParentOf(extendedClass);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => extensionKeyword;

  @override
  NodeListImpl<ClassMemberImpl> get members => _members;

  @Deprecated('Use name instead')
  @override
  Token? get name2 => name;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('extensionKeyword', extensionKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addToken('onKeyword', onKeyword)
    ..addNode('extendedType', extendedType)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExtensionDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
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
  /// The name of the extension being selected.
  IdentifierImpl _extensionName;

  /// The type arguments to be applied to the extension, or `null` if no type
  /// arguments were provided.
  TypeArgumentListImpl? _typeArguments;

  /// The list of arguments to the override. In valid code this will contain a
  /// single argument, which evaluates to the object being extended.
  ArgumentListImpl _argumentList;

  @override
  List<DartType>? typeArgumentTypes;

  @override
  DartType? extendedType;

  ExtensionOverrideImpl({
    required IdentifierImpl extensionName,
    required TypeArgumentListImpl? typeArguments,
    required ArgumentListImpl argumentList,
  })  : _extensionName = extensionName,
        _typeArguments = typeArguments,
        _argumentList = argumentList {
    _becomeParentOf(_extensionName);
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => _extensionName.beginToken;

  @override
  Token get endToken => _argumentList.endToken;

  @override
  IdentifierImpl get extensionName => _extensionName;

  set extensionName(IdentifierImpl extensionName) {
    _extensionName = _becomeParentOf(extensionName);
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

  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('extensionName', extensionName)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitExtensionOverride(this);
  }

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitExtensionOverride(this, contextType: contextType);
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
  final Token? abstractKeyword;

  /// The 'augment' keyword, or `null` if the keyword was not used.
  final Token? augmentKeyword;

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  @override
  final Token? covariantKeyword;

  @override
  final Token? externalKeyword;

  /// The token representing the 'static' keyword, or `null` if the fields are
  /// not static.
  @override
  final Token? staticKeyword;

  /// The fields being declared.
  VariableDeclarationListImpl _fieldList;

  /// The semicolon terminating the declaration.
  @override
  final Token semicolon;

  /// Initialize a newly created field declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [staticKeyword] can be `null` if the
  /// field is not a static field.
  FieldDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.abstractKeyword,
    required this.augmentKeyword,
    required this.covariantKeyword,
    required this.externalKeyword,
    required this.staticKeyword,
    required VariableDeclarationListImpl fieldList,
    required this.semicolon,
  }) : _fieldList = fieldList {
    _becomeParentOf(_fieldList);
  }

  @override
  Element? get declaredElement => null;

  @Deprecated('Use declaredElement instead')
  @override
  Element? get declaredElement2 => null;

  @override
  Token get endToken => semicolon;

  @override
  VariableDeclarationListImpl get fields => _fieldList;

  set fields(VariableDeclarationListImpl fields) {
    _fieldList = _becomeParentOf(fields);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(abstractKeyword, augmentKeyword,
            externalKeyword, covariantKeyword, staticKeyword) ??
        _fieldList.beginToken;
  }

  @override
  bool get isStatic => staticKeyword != null;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('staticKeyword', staticKeyword)
    ..addNode('fields', fields)
    ..addToken('semicolon', semicolon);

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
  final Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  /// The token representing the 'this' keyword.
  @override
  final Token thisKeyword;

  /// The token representing the period.
  @override
  final Token period;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters of the function-typed parameter, or `null` if this is not a
  /// function-typed field formal parameter.
  FormalParameterListImpl? _parameters;

  @override
  final Token? question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if there is a type.
  /// The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
  /// [period] can be `null` if the keyword 'this' was not provided.  The
  /// [parameters] can be `null` if this is not a function-typed field formal
  /// parameter.
  FieldFormalParameterImpl({
    required super.comment,
    required super.metadata,
    required super.covariantKeyword,
    required super.requiredKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required this.thisKeyword,
    required this.period,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl? parameters,
    required this.question,
  })  : _type = type,
        _typeParameters = typeParameters,
        _parameters = parameters {
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
  Token get endToken {
    return question ?? _parameters?.endToken ?? name;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isExplicitlyTyped => _parameters != null || _type != null;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  Token get name => super.name!;

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('thisKeyword', thisKeyword)
    ..addToken('period', period)
    ..addToken('name', name)
    ..addNode('parameters', parameters);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFieldFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
  }
}

abstract class ForEachPartsImpl extends ForLoopPartsImpl
    implements ForEachParts {
  @override
  final Token inKeyword;

  /// The expression evaluated to produce the iterator.
  ExpressionImpl _iterable;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared internally (in the for-loop part). The [awaitKeyword] can be
  /// `null` if this is not an asynchronous for loop.
  ForEachPartsImpl({
    required this.inKeyword,
    required ExpressionImpl iterable,
  }) : _iterable = iterable {
    _becomeParentOf(_iterable);
  }

  @override
  Token get beginToken => inKeyword;

  @override
  Token get endToken => _iterable.endToken;

  @override
  ExpressionImpl get iterable => _iterable;

  set iterable(ExpressionImpl expression) {
    _iterable = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('inKeyword', inKeyword)
    ..addNode('iterable', iterable);

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
  ForEachPartsWithDeclarationImpl({
    required DeclaredIdentifierImpl loopVariable,
    required super.inKeyword,
    required super.iterable,
  }) : _loopVariable = loopVariable {
    _becomeParentOf(_loopVariable);
  }

  @override
  Token get beginToken => _loopVariable.beginToken;

  @override
  DeclaredIdentifierImpl get loopVariable => _loopVariable;

  set loopVariable(DeclaredIdentifierImpl variable) {
    _loopVariable = _becomeParentOf(variable);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('loopVariable', loopVariable)
    ..addAll(super._childEntities);

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
  ForEachPartsWithIdentifierImpl({
    required SimpleIdentifierImpl identifier,
    required super.inKeyword,
    required super.iterable,
  }) : _identifier = identifier {
    _becomeParentOf(_identifier);
  }

  @override
  Token get beginToken => _identifier.beginToken;

  @override
  SimpleIdentifierImpl get identifier => _identifier;

  set identifier(SimpleIdentifierImpl identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('identifier', identifier)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _identifier.accept(visitor);
    _iterable.accept(visitor);
  }
}

/// A for-loop part with a pattern.
///
///    forEachPartsWithPattern ::=
///        ( 'final' | 'var' ) [DartPattern] 'in' [Expression]
@experimental
class ForEachPartsWithPatternImpl extends ForEachPartsImpl
    implements ForEachPartsWithPattern {
  /// The annotations associated with this node.
  final NodeListImpl<AnnotationImpl> _metadata = NodeListImpl._();

  @override
  final Token keyword;

  @override
  final DartPatternImpl pattern;

  /// Variables declared in [pattern].
  late final List<BindPatternVariableElementImpl> variables;

  ForEachPartsWithPatternImpl({
    required List<AnnotationImpl>? metadata,
    required this.keyword,
    required this.pattern,
    required super.inKeyword,
    required super.iterable,
  }) {
    _metadata._initialize(this, metadata);
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken {
    if (_metadata.isEmpty) {
      return keyword;
    } else {
      return _metadata.beginToken!;
    }
  }

  /// If [keyword] is `final`, returns it.
  Token? get finalKeyword {
    if (keyword.keyword == Keyword.FINAL) {
      return keyword;
    }
    return null;
  }

  @override
  NodeListImpl<AnnotationImpl> get metadata => _metadata;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('metadata', metadata)
    ..addToken('keyword', keyword)
    ..addNode('pattern', pattern)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithPattern(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _metadata.accept(visitor);
    pattern.accept(visitor);
    super.visitChildren(visitor);
  }
}

class ForElementImpl extends CollectionElementImpl implements ForElement {
  @override
  final Token? awaitKeyword;

  @override
  final Token forKeyword;

  @override
  final Token leftParenthesis;

  ForLoopPartsImpl _forLoopParts;

  @override
  final Token rightParenthesis;

  /// The body of the loop.
  CollectionElementImpl _body;

  /// Initialize a newly created for element.
  ForElementImpl({
    required this.awaitKeyword,
    required this.forKeyword,
    required this.leftParenthesis,
    required ForLoopPartsImpl forLoopParts,
    required this.rightParenthesis,
    required CollectionElementImpl body,
  })  : _forLoopParts = forLoopParts,
        _body = body {
    _becomeParentOf(_forLoopParts);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken => awaitKeyword ?? forKeyword;

  @override
  CollectionElementImpl get body => _body;

  set body(CollectionElementImpl statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  ForLoopPartsImpl get forLoopParts => _forLoopParts;

  set forLoopParts(ForLoopPartsImpl forLoopParts) {
    _forLoopParts = _becomeParentOf(forLoopParts);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('awaitKeyword', awaitKeyword)
    ..addToken('forKeyword', forKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('forLoopParts', forLoopParts)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForElement(this);

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.visitForElement(this, context: context);
    resolver.pushRewrite(null);
  }

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
  ParameterElementImpl? declaredElement;

  /// TODO(scheglov) I was not able to update 'nnbd_migration' any better.
  SimpleIdentifier? get identifierForMigration {
    final token = name;
    if (token != null) {
      final result = SimpleIdentifierImpl(token);
      result.staticElement = declaredElement;
      _becomeParentOf(result);
      return result;
    }
    return null;
  }

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
  final Token leftParenthesis;

  /// The parameters associated with the method.
  final NodeListImpl<FormalParameterImpl> _parameters = NodeListImpl._();

  /// The left square bracket ('[') or left curly brace ('{') introducing the
  /// optional parameters, or `null` if there are no optional parameters.
  @override
  final Token? leftDelimiter;

  /// The right square bracket (']') or right curly brace ('}') terminating the
  /// optional parameters, or `null` if there are no optional parameters.
  @override
  final Token? rightDelimiter;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// Initialize a newly created parameter list. The list of [parameters] can be
  /// `null` if there are no parameters. The [leftDelimiter] and
  /// [rightDelimiter] can be `null` if there are no optional parameters.
  FormalParameterListImpl({
    required this.leftParenthesis,
    required List<FormalParameterImpl> parameters,
    required this.leftDelimiter,
    required this.rightDelimiter,
    required this.rightParenthesis,
  }) {
    _parameters._initialize(this, parameters);
  }

  @override
  Token get beginToken => leftParenthesis;

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
  NodeListImpl<FormalParameterImpl> get parameters => _parameters;

  @override
  ChildEntities get _childEntities {
    // TODO(paulberry): include commas.
    var result = ChildEntities()..addToken('leftParenthesis', leftParenthesis);
    bool leftDelimiterNeeded = leftDelimiter != null;
    int length = _parameters.length;
    for (int i = 0; i < length; i++) {
      FormalParameter parameter = _parameters[i];
      if (leftDelimiterNeeded && leftDelimiter!.offset < parameter.offset) {
        result.addToken('leftDelimiter', leftDelimiter);
        leftDelimiterNeeded = false;
      }
      result.addNode('parameter', parameter);
    }
    return result
      ..addToken('rightDelimiter', rightDelimiter)
      ..addToken('rightParenthesis', rightParenthesis);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFormalParameterList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _parameters.accept(visitor);
  }
}

abstract class ForPartsImpl extends ForLoopPartsImpl implements ForParts {
  @override
  final Token leftSeparator;

  /// The condition used to determine when to terminate the loop, or `null` if
  /// there is no condition.
  ExpressionImpl? _condition;

  @override
  final Token rightSeparator;

  /// The list of expressions run after each execution of the loop body.
  final NodeListImpl<ExpressionImpl> _updaters = NodeListImpl._();

  /// Initialize a newly created for statement. Either the [variableList] or the
  /// [initialization] must be `null`. Either the [condition] and the list of
  /// [updaters] can be `null` if the loop does not have the corresponding
  /// attribute.
  ForPartsImpl({
    required this.leftSeparator,
    required ExpressionImpl? condition,
    required this.rightSeparator,
    required List<ExpressionImpl>? updaters,
  }) : _condition = condition {
    _becomeParentOf(_condition);
    _updaters._initialize(this, updaters);
  }

  @override
  Token get beginToken => leftSeparator;

  @override
  ExpressionImpl? get condition => _condition;

  set condition(ExpressionImpl? expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  Token get endToken => _updaters.endToken ?? rightSeparator;

  @override
  NodeListImpl<ExpressionImpl> get updaters => _updaters;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftSeparator', leftSeparator)
    ..addNode('condition', condition)
    ..addToken('rightSeparator', rightSeparator)
    ..addNodeList('updaters', updaters);

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
  ForPartsWithDeclarationsImpl({
    required VariableDeclarationListImpl variableList,
    required super.leftSeparator,
    required super.condition,
    required super.rightSeparator,
    required super.updaters,
  }) : _variableList = variableList {
    _becomeParentOf(_variableList);
  }

  @override
  Token get beginToken => _variableList.beginToken;

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationListImpl? variableList) {
    _variableList =
        _becomeParentOf(variableList as VariableDeclarationListImpl);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('variables', variables)
    ..addAll(super._childEntities);

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
  ForPartsWithExpressionImpl({
    required ExpressionImpl? initialization,
    required super.leftSeparator,
    required super.condition,
    required super.rightSeparator,
    required super.updaters,
  }) : _initialization = initialization {
    _becomeParentOf(_initialization);
  }

  @override
  Token get beginToken => initialization?.beginToken ?? super.beginToken;

  @override
  ExpressionImpl? get initialization => _initialization;

  set initialization(ExpressionImpl? initialization) {
    _initialization = _becomeParentOf(initialization);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('initialization', initialization)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForPartsWithExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _initialization?.accept(visitor);
    super.visitChildren(visitor);
  }
}

/// The parts of a for loop that control the iteration when there is a pattern
/// declaration as part of the for loop.
///
///   forLoopParts ::=
///       [PatternVariableDeclaration] ';' [Expression]? ';' expressionList?
class ForPartsWithPatternImpl extends ForPartsImpl
    implements ForPartsWithPattern {
  @override
  final PatternVariableDeclarationImpl variables;

  ForPartsWithPatternImpl({
    required this.variables,
    required super.leftSeparator,
    required super.condition,
    required super.rightSeparator,
    required super.updaters,
  }) {
    _becomeParentOf(variables);
  }

  @override
  Token get beginToken => variables.beginToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('variables', variables)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForPartsWithPattern(this);

  @override
  void visitChildren(AstVisitor visitor) {
    variables.accept(visitor);
    super.visitChildren(visitor);
  }
}

class ForStatementImpl extends StatementImpl implements ForStatement {
  @override
  final Token? awaitKeyword;

  @override
  final Token forKeyword;

  @override
  final Token leftParenthesis;

  ForLoopPartsImpl _forLoopParts;

  @override
  final Token rightParenthesis;

  /// The body of the loop.
  StatementImpl _body;

  /// Initialize a newly created for statement.
  ForStatementImpl({
    required this.awaitKeyword,
    required this.forKeyword,
    required this.leftParenthesis,
    required ForLoopPartsImpl forLoopParts,
    required this.rightParenthesis,
    required StatementImpl body,
  })  : _forLoopParts = forLoopParts,
        _body = body {
    _becomeParentOf(_forLoopParts);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken => awaitKeyword ?? forKeyword;

  @override
  StatementImpl get body => _body;

  set body(StatementImpl statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  ForLoopPartsImpl get forLoopParts => _forLoopParts;

  set forLoopParts(ForLoopPartsImpl forLoopParts) {
    _forLoopParts = _becomeParentOf(forLoopParts);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('awaitKeyword', awaitKeyword)
    ..addToken('forKeyword', forKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('forLoopParts', forLoopParts)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

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

  /// Dispatch this function body to the resolver, imposing [imposedType] as the
  /// return type context for `return` statements.
  ///
  /// Return value is the actual return type of the method.
  DartType resolve(ResolverVisitor resolver, DartType? imposedType);
}

/// A function declaration.
///
/// Wrapped in a [FunctionDeclarationStatementImpl] to represent a local
/// function declaration, otherwise a top-level function declaration.
///
///    functionDeclaration ::=
///        'external' functionSignature
///      | functionSignature [FunctionBody]
///
///    functionSignature ::=
///        [Type]? ('get' | 'set')? [SimpleIdentifier] [FormalParameterList]
class FunctionDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements FunctionDeclaration {
  /// The token representing the 'augment' keyword, or `null` if this is not an
  /// function augmentation.
  final Token? augmentKeyword;

  /// The token representing the 'external' keyword, or `null` if this is not an
  /// external function.
  @override
  final Token? externalKeyword;

  /// The return type of the function, or `null` if no return type was declared.
  TypeAnnotationImpl? _returnType;

  /// The token representing the 'get' or 'set' keyword, or `null` if this is a
  /// function declaration rather than a property declaration.
  @override
  final Token? propertyKeyword;

  /// The function expression being wrapped.
  FunctionExpressionImpl _functionExpression;

  @override
  ExecutableElement? declaredElement;

  /// Initialize a newly created function declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [externalKeyword] can be `null` if the
  /// function is not an external function. The [returnType] can be `null` if no
  /// return type was specified. The [propertyKeyword] can be `null` if the
  /// function is neither a getter or a setter.
  FunctionDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.externalKeyword,
    required TypeAnnotationImpl? returnType,
    required this.propertyKeyword,
    required super.name,
    required FunctionExpressionImpl functionExpression,
  })  : _returnType = returnType,
        _functionExpression = functionExpression {
    _becomeParentOf(_returnType);
    _becomeParentOf(_functionExpression);
  }

  @Deprecated('Use declaredElement instead')
  @override
  ExecutableElement? get declaredElement2 => declaredElement;

  @override
  Token get endToken => _functionExpression.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return augmentKeyword ??
        externalKeyword ??
        _returnType?.beginToken ??
        propertyKeyword ??
        name;
  }

  @override
  FunctionExpressionImpl get functionExpression => _functionExpression;

  set functionExpression(FunctionExpressionImpl functionExpression) {
    _functionExpression = _becomeParentOf(functionExpression);
  }

  @override
  bool get isGetter => propertyKeyword?.keyword == Keyword.GET;

  @override
  bool get isSetter => propertyKeyword?.keyword == Keyword.SET;

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotationImpl? type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('externalKeyword', externalKeyword)
    ..addNode('returnType', returnType)
    ..addToken('propertyKeyword', propertyKeyword)
    ..addToken('name', name)
    ..addNode('functionExpression', functionExpression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _functionExpression.accept(visitor);
  }
}

/// A [FunctionDeclaration] used as a statement.
class FunctionDeclarationStatementImpl extends StatementImpl
    implements FunctionDeclarationStatement {
  /// The function declaration being wrapped.
  FunctionDeclarationImpl _functionDeclaration;

  /// Initialize a newly created function declaration statement.
  FunctionDeclarationStatementImpl({
    required FunctionDeclarationImpl functionDeclaration,
  }) : _functionDeclaration = functionDeclaration {
    _becomeParentOf(_functionDeclaration);
  }

  @override
  Token get beginToken => _functionDeclaration.beginToken;

  @override
  Token get endToken => _functionDeclaration.endToken;

  @override
  FunctionDeclarationImpl get functionDeclaration => _functionDeclaration;

  set functionDeclaration(FunctionDeclarationImpl functionDeclaration) {
    _functionDeclaration = _becomeParentOf(functionDeclaration);
  }

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNode('functionDeclaration', functionDeclaration);

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

  /// If resolution has been performed, this boolean indicates whether a
  /// function type was supplied via context for this function expression.
  /// `false` if resolution hasn't been performed yet.
  bool wasFunctionTypeSupplied = false;

  @override
  ExecutableElement? declaredElement;

  /// Initialize a newly created function declaration.
  FunctionExpressionImpl({
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl? parameters,
    required FunctionBodyImpl body,
  })  : _typeParameters = typeParameters,
        _parameters = parameters,
        _body = body {
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

  set body(FunctionBodyImpl functionBody) {
    _body = _becomeParentOf(functionBody);
  }

  @override
  Token get endToken {
    return _body.endToken;
  }

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitFunctionExpression(this, contextType: contextType);
  }

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
  FunctionExpressionInvocationImpl({
    required ExpressionImpl function,
    required super.typeArguments,
    required super.argumentList,
  }) : _function = function {
    _becomeParentOf(_function);
  }

  @override
  Token get beginToken => _function.beginToken;

  @override
  Token get endToken => _argumentList.endToken;

  @override
  ExpressionImpl get function => _function;

  set function(ExpressionImpl expression) {
    _function = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('function', function)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionExpressionInvocation(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitFunctionExpressionInvocation(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _function.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _function);
}

/// An expression representing a reference to a function, possibly with type
/// arguments applied to it, e.g. the expression `print` in `var x = print;`.
class FunctionReferenceImpl extends CommentReferableExpressionImpl
    implements FunctionReference {
  ExpressionImpl _function;

  TypeArgumentListImpl? _typeArguments;

  @override
  List<DartType>? typeArgumentTypes;

  FunctionReferenceImpl({
    required ExpressionImpl function,
    required TypeArgumentListImpl? typeArguments,
  })  : _function = function,
        _typeArguments = typeArguments {
    _becomeParentOf(_function);
    _becomeParentOf(_typeArguments);
  }

  @override
  Token get beginToken => function.beginToken;

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
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('function', function)
    ..addNode('typeArguments', typeArguments);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionReference(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitFunctionReference(this, contextType: contextType);
  }

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

  @override
  TypeAliasElement? declaredElement;

  /// Initialize a newly created function type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [returnType] can be `null` if no return type
  /// was specified. The [typeParameters] can be `null` if the function has no
  /// type parameters.
  FunctionTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required super.typedefKeyword,
    required TypeAnnotationImpl? returnType,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl parameters,
    required super.semicolon,
  })  : _returnType = returnType,
        _typeParameters = typeParameters,
        _parameters = parameters {
    _becomeParentOf(_returnType);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @Deprecated('Use declaredElement instead')
  @override
  TypeAliasElement? get declaredElement2 => declaredElement;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotationImpl? type) {
    _returnType = _becomeParentOf(type);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('typedefKeyword', typedefKeyword)
    ..addNode('returnType', returnType)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
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
  final Token? question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [returnType] can be `null` if no return type
  /// was specified.
  FunctionTypedFormalParameterImpl({
    required super.comment,
    required super.metadata,
    required super.covariantKeyword,
    required super.requiredKeyword,
    required TypeAnnotationImpl? returnType,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl parameters,
    required this.question,
  })  : _returnType = returnType,
        _typeParameters = typeParameters,
        _parameters = parameters {
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
    return name;
  }

  @override
  Token get endToken => question ?? _parameters.endToken;

  @override
  bool get isConst => false;

  @override
  bool get isExplicitlyTyped => true;

  @override
  bool get isFinal => false;

  @override
  Token get name => super.name!;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotationImpl? type) {
    _returnType = _becomeParentOf(type);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('returnType', returnType)
    ..addToken('name', name)
    ..addNode('parameters', parameters);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionTypedFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
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
  final Token functionKeyword;

  /// The type parameters for the function type, or `null` if the function type
  /// does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The parameters associated with the function type.
  FormalParameterListImpl _parameters;

  @override
  final Token? question;

  @override
  DartType? type;

  /// Return the element associated with the function type, or `null` if the
  /// AST structure has not been resolved.
  GenericFunctionTypeElement? declaredElement;

  /// Initialize a newly created generic function type.
  GenericFunctionTypeImpl({
    required TypeAnnotationImpl? returnType,
    required this.functionKeyword,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl parameters,
    required this.question,
  })  : _returnType = returnType,
        _typeParameters = typeParameters,
        _parameters = parameters {
    _becomeParentOf(_returnType);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Token get beginToken => _returnType?.beginToken ?? functionKeyword;

  @override
  Token get endToken => question ?? _parameters.endToken;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotationImpl? type) {
    _returnType = _becomeParentOf(type);
  }

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  /// Set the type parameters for the function type to the given list of
  /// [typeParameters].
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('returnType', returnType)
    ..addToken('functionKeyword', functionKeyword)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addToken('question', question);

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
  final Token equals;

  @override
  Element? declaredElement;

  /// Returns a newly created generic type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the variable list does not have
  /// the corresponding attribute. The [typeParameters] can be `null` if there
  /// are no type parameters.
  GenericTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required super.typedefKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required this.equals,
    required TypeAnnotationImpl type,
    required super.semicolon,
  })  : _typeParameters = typeParameters,
        _type = type {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_type);
  }

  @Deprecated('Use declaredElement instead')
  @override
  Element? get declaredElement2 => declaredElement;

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
  set type(TypeAnnotationImpl typeAnnotation) {
    _type = _becomeParentOf(typeAnnotation);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('metadata', metadata)
    ..addToken('typedefKeyword', typedefKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addToken('equals', equals)
    ..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitGenericTypeAlias(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _typeParameters?.accept(visitor);
    _type.accept(visitor);
  }
}

/// The `case` clause that can optionally appear in an `if` statement.
///
///    caseClause ::=
///        'case' [DartPattern] [WhenClause]?
///
/// Clients may not extend, implement or mix-in this class.
@experimental
class GuardedPatternImpl extends AstNodeImpl implements GuardedPattern {
  @override
  final DartPatternImpl pattern;

  /// Variables declared in [pattern], available in [whenClause] guard, and
  /// to the `ifTrue` node.
  late Map<String, PatternVariableElementImpl> variables;

  @override
  final WhenClauseImpl? whenClause;

  GuardedPatternImpl({
    required this.pattern,
    required this.whenClause,
  }) {
    _becomeParentOf(pattern);
    _becomeParentOf(whenClause);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => whenClause?.endToken ?? pattern.endToken;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addNode('whenClause', whenClause);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitGuardedPattern(this);

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
    whenClause?.accept(visitor);
  }
}

/// A combinator that restricts the names being imported to those that are not
/// in a given list.
///
///    hideCombinator ::=
///        'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
class HideCombinatorImpl extends CombinatorImpl implements HideCombinator {
  /// The list of names from the library that are hidden by this combinator.
  final NodeListImpl<SimpleIdentifierImpl> _hiddenNames = NodeListImpl._();

  /// Initialize a newly created import show combinator.
  HideCombinatorImpl({
    required super.keyword,
    required List<SimpleIdentifierImpl> hiddenNames,
  }) {
    _hiddenNames._initialize(this, hiddenNames);
  }

  @override
  Token get endToken => _hiddenNames.endToken!;

  @override
  NodeListImpl<SimpleIdentifierImpl> get hiddenNames => _hiddenNames;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNodeList('hiddenNames', hiddenNames);

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

class IfElementImpl extends CollectionElementImpl
    implements IfElement, IfElementOrStatementImpl<CollectionElementImpl> {
  @override
  final Token ifKeyword;

  @override
  final Token leftParenthesis;

  ExpressionImpl _condition;

  @override
  final CaseClauseImpl? caseClause;

  @override
  final Token rightParenthesis;

  @override
  final Token? elseKeyword;

  /// The element to be executed if the condition is `true`.
  CollectionElementImpl _thenElement;

  /// The element to be executed if the condition is `false`, or `null` if there
  /// is no such element.
  CollectionElementImpl? _elseElement;

  /// Initialize a newly created for element.
  IfElementImpl({
    required this.ifKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.caseClause,
    required this.rightParenthesis,
    required CollectionElementImpl thenElement,
    required this.elseKeyword,
    required CollectionElementImpl? elseElement,
  })  : _condition = condition,
        _thenElement = thenElement,
        _elseElement = elseElement {
    _becomeParentOf(_condition);
    _becomeParentOf(caseClause);
    _becomeParentOf(_thenElement);
    _becomeParentOf(_elseElement);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @override
  CollectionElementImpl? get elseElement => _elseElement;

  set elseElement(CollectionElementImpl? element) {
    _elseElement = _becomeParentOf(element);
  }

  @override
  Token get endToken => _elseElement?.endToken ?? _thenElement.endToken;

  @override
  ExpressionImpl get expression => _condition;

  @override
  CollectionElementImpl? get ifFalse => elseElement;

  @override
  CollectionElementImpl get ifTrue => thenElement;

  @override
  CollectionElementImpl get thenElement => _thenElement;

  set thenElement(CollectionElementImpl element) {
    _thenElement = _becomeParentOf(element);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('ifKeyword', ifKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addNode('caseClause', caseClause)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('thenElement', thenElement)
    ..addToken('elseKeyword', elseKeyword)
    ..addNode('elseElement', elseElement);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIfElement(this);

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.visitIfElement(this, context: context);
    resolver.pushRewrite(null);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    condition.accept(visitor);
    caseClause?.accept(visitor);
    _thenElement.accept(visitor);
    _elseElement?.accept(visitor);
  }
}

abstract class IfElementOrStatementImpl<E extends AstNodeImpl>
    implements AstNodeImpl {
  /// Return the `case` clause used to match a pattern against the [expression].
  CaseClauseImpl? get caseClause;

  /// Return the expression used to either determine which of the statements is
  /// executed next or to compute the value matched against the pattern in the
  /// `case` clause.
  ExpressionImpl get expression;

  /// The node that is executed if the condition evaluates to `false`.
  E? get ifFalse;

  /// The node that is executed if the condition evaluates to `true`.
  E get ifTrue;
}

/// An if statement.
///
///    ifStatement ::=
///        'if' '(' [Expression] [CaseClause]? ')'[Statement]
///        ('else' [Statement])?
class IfStatementImpl extends StatementImpl
    implements IfStatement, IfElementOrStatementImpl<StatementImpl> {
  @override
  final Token ifKeyword;

  @override
  final Token leftParenthesis;

  /// The condition used to determine which of the branches is executed next.
  ExpressionImpl _condition;

  @override
  final CaseClauseImpl? caseClause;

  @override
  final Token rightParenthesis;

  @override
  final Token? elseKeyword;

  /// The statement that is executed if the condition evaluates to `true`.
  StatementImpl _thenStatement;

  /// The statement that is executed if the condition evaluates to `false`, or
  /// `null` if there is no else statement.
  StatementImpl? _elseStatement;

  /// Initialize a newly created if statement. The [elseKeyword] and
  /// [elseStatement] can be `null` if there is no else clause.
  IfStatementImpl({
    required this.ifKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.caseClause,
    required this.rightParenthesis,
    required StatementImpl thenStatement,
    required this.elseKeyword,
    required StatementImpl? elseStatement,
  })  : _condition = condition,
        _thenStatement = thenStatement,
        _elseStatement = elseStatement {
    _becomeParentOf(_condition);
    _becomeParentOf(caseClause);
    _becomeParentOf(_thenStatement);
    _becomeParentOf(_elseStatement);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @override
  StatementImpl? get elseStatement => _elseStatement;

  set elseStatement(StatementImpl? statement) {
    _elseStatement = _becomeParentOf(statement);
  }

  @override
  Token get endToken {
    if (_elseStatement != null) {
      return _elseStatement!.endToken;
    }
    return _thenStatement.endToken;
  }

  @override
  ExpressionImpl get expression => _condition;

  @override
  StatementImpl? get ifFalse => elseStatement;

  @override
  StatementImpl get ifTrue => thenStatement;

  @override
  StatementImpl get thenStatement => _thenStatement;

  set thenStatement(StatementImpl statement) {
    _thenStatement = _becomeParentOf(statement);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('ifKeyword', ifKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addNode('caseClause', caseClause)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('thenStatement', thenStatement)
    ..addToken('elseKeyword', elseKeyword)
    ..addNode('elseStatement', elseStatement);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIfStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    caseClause?.accept(visitor);
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
  final Token implementsKeyword;

  /// The interfaces that are being implemented.
  final NodeListImpl<NamedTypeImpl> _interfaces = NodeListImpl._();

  /// Initialize a newly created implements clause.
  ImplementsClauseImpl({
    required this.implementsKeyword,
    required List<NamedTypeImpl> interfaces,
  }) {
    _interfaces._initialize(this, interfaces);
  }

  @override
  Token get beginToken => implementsKeyword;

  @override
  Token get endToken => _interfaces.endToken ?? implementsKeyword;

  @override
  NodeListImpl<NamedTypeImpl> get interfaces => _interfaces;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('implementsKeyword', implementsKeyword)
    ..addNodeList('interfaces', interfaces);

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

  ImplicitCallReferenceImpl({
    required ExpressionImpl expression,
    required this.staticElement,
    required TypeArgumentListImpl? typeArguments,
    required this.typeArgumentTypes,
  })  : _expression = expression,
        _typeArguments = typeArguments {
    _becomeParentOf(_expression);
    _becomeParentOf(_typeArguments);
  }

  @override
  Token get beginToken => expression.beginToken;

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
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addNode('typeArguments', typeArguments);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitImplicitCallReference(this);
  }

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitImplicitCallReference(this, contextType: contextType);
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
  @override
  final Token importKeyword;

  /// The token representing the 'deferred' keyword, or `null` if the imported
  /// is not deferred.
  @override
  final Token? deferredKeyword;

  /// The token representing the 'as' keyword, or `null` if the imported names
  /// are not prefixed.
  @override
  final Token? asKeyword;

  /// The prefix to be used with the imported names, or `null` if the imported
  /// names are not prefixed.
  SimpleIdentifierImpl? _prefix;

  /// Initialize a newly created import directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [deferredKeyword] can be `null` if the import
  /// is not deferred. The [asKeyword] and [prefix] can be `null` if the import
  /// does not specify a prefix. The list of [combinators] can be `null` if
  /// there are no combinators.
  ImportDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.importKeyword,
    required super.uri,
    required super.configurations,
    required this.deferredKeyword,
    required this.asKeyword,
    required SimpleIdentifierImpl? prefix,
    required super.combinators,
    required super.semicolon,
  }) : _prefix = prefix {
    _becomeParentOf(_prefix);
  }

  @override
  LibraryImportElement? get element => super.element as LibraryImportElement?;

  @Deprecated('Use element instead')
  @override
  LibraryImportElement? get element2 => element;

  @override
  Token get firstTokenAfterCommentAndMetadata => importKeyword;

  @override
  SimpleIdentifierImpl? get prefix => _prefix;

  set prefix(SimpleIdentifierImpl? identifier) {
    _prefix = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('importKeyword', importKeyword)
    ..addNode('uri', uri)
    ..addToken('deferredKeyword', deferredKeyword)
    ..addToken('asKeyword', asKeyword)
    ..addNode('prefix', prefix)
    ..addNodeList('combinators', combinators)
    ..addNodeList('configurations', configurations)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitImportDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    configurations.accept(visitor);
    _prefix?.accept(visitor);
    combinators.accept(visitor);
  }

  /// Return `true` if the non-URI components of the two directives are
  /// syntactically identical. URIs are checked outside to see if they resolve
  /// to the same absolute URI, so to the same library, regardless of the used
  /// syntax (absolute, relative, not normalized).
  static bool areSyntacticallyIdenticalExceptUri(
    NamespaceDirective node1,
    NamespaceDirective node2,
  ) {
    if (node1 is ImportDirective &&
        node2 is ImportDirective &&
        node1.prefix?.name != node2.prefix?.name) {
      return false;
    }

    bool areSameNames(
      List<SimpleIdentifier> names1,
      List<SimpleIdentifier> names2,
    ) {
      if (names1.length != names2.length) {
        return false;
      }
      for (var i = 0; i < names1.length; i++) {
        if (names1[i].name != names2[i].name) {
          return false;
        }
      }
      return true;
    }

    final combinators1 = node1.combinators;
    final combinators2 = node2.combinators;
    if (combinators1.length != combinators2.length) {
      return false;
    }
    for (var i = 0; i < combinators1.length; i++) {
      final combinator1 = combinators1[i];
      final combinator2 = combinators2[i];
      if (combinator1 is HideCombinator && combinator2 is HideCombinator) {
        if (!areSameNames(combinator1.hiddenNames, combinator2.hiddenNames)) {
          return false;
        }
      } else if (combinator1 is ShowCombinator &&
          combinator2 is ShowCombinator) {
        if (!areSameNames(combinator1.shownNames, combinator2.shownNames)) {
          return false;
        }
      } else {
        return false;
      }
    }

    return true;
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
  final Token? question;

  @override
  final Token leftBracket;

  /// The expression used to compute the index.
  ExpressionImpl _index;

  @override
  final Token rightBracket;

  /// The element associated with the operator based on the static type of the
  /// target, or `null` if the AST structure has not been resolved or if the
  /// operator could not be resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created index expression that is a child of a cascade
  /// expression.
  IndexExpressionImpl.forCascade({
    required this.period,
    required this.question,
    required this.leftBracket,
    required ExpressionImpl index,
    required this.rightBracket,
  }) : _index = index {
    _becomeParentOf(_index);
  }

  /// Initialize a newly created index expression that is not a child of a
  /// cascade expression.
  IndexExpressionImpl.forTarget({
    required ExpressionImpl? target,
    required this.question,
    required this.leftBracket,
    required ExpressionImpl index,
    required this.rightBracket,
  })  : _target = target,
        _index = index {
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
  Token get endToken => rightBracket;

  @override
  ExpressionImpl get index => _index;

  set index(ExpressionImpl expression) {
    _index = _becomeParentOf(expression);
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

  set target(ExpressionImpl? expression) {
    _target = _becomeParentOf(expression);
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
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addToken('period', period)
    ..addToken('leftBracket', leftBracket)
    ..addNode('index', index)
    ..addToken('rightBracket', rightBracket);

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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitIndexExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _index.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _target);
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
  InstanceCreationExpressionImpl({
    required this.keyword,
    required ConstructorNameImpl constructorName,
    required ArgumentListImpl argumentList,
    required TypeArgumentListImpl? typeArguments,
  })  : _constructorName = constructorName,
        _argumentList = argumentList,
        _typeArguments = typeArguments {
    _becomeParentOf(_constructorName);
    _becomeParentOf(_argumentList);
    _becomeParentOf(_typeArguments);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => keyword ?? _constructorName.beginToken;

  @override
  ConstructorNameImpl get constructorName => _constructorName;

  set constructorName(ConstructorNameImpl name) {
    _constructorName = _becomeParentOf(name);
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
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNode('constructorName', constructorName)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitInstanceCreationExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitInstanceCreationExpression(this, contextType: contextType);
  }

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
  final Token literal;

  /// The value of the literal.
  @override
  int? value = 0;

  /// Initialize a newly created integer literal.
  IntegerLiteralImpl({
    required this.literal,
    required this.value,
  });

  @override
  Token get beginToken => literal;

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
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIntegerLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitIntegerLiteral(this, contextType: contextType);
  }

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
  final Token leftBracket;

  /// The expression to be evaluated for the value to be converted into a
  /// string.
  ExpressionImpl _expression;

  /// The right curly bracket, or `null` if the expression is an identifier
  /// without brackets.
  @override
  final Token? rightBracket;

  /// Initialize a newly created interpolation expression.
  InterpolationExpressionImpl({
    required this.leftBracket,
    required ExpressionImpl expression,
    required this.rightBracket,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket ?? _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNode('expression', expression)
    ..addToken('rightBracket', rightBracket);

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
  final Token contents;

  /// The value of the literal.
  @override
  String value;

  /// Initialize a newly created string of characters that are part of a string
  /// interpolation.
  InterpolationStringImpl({
    required this.contents,
    required this.value,
  });

  @override
  Token get beginToken => contents;

  @override
  int get contentsEnd => offset + _lexemeHelper.end;

  @override
  int get contentsOffset => contents.offset + _lexemeHelper.start;

  @override
  Token get endToken => contents;

  @override
  StringInterpolation get parent => super.parent as StringInterpolation;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('contents', contents);

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
  InvocationExpressionImpl({
    required TypeArgumentListImpl? typeArguments,
    required ArgumentListImpl argumentList,
  })  : _typeArguments = typeArguments,
        _argumentList = argumentList {
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
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
  final Token isOperator;

  /// The not operator, or `null` if the sense of the test is not negated.
  @override
  final Token? notOperator;

  /// The name of the type being tested for.
  TypeAnnotationImpl _type;

  /// Initialize a newly created is expression. The [notOperator] can be `null`
  /// if the sense of the test is not negated.
  IsExpressionImpl({
    required ExpressionImpl expression,
    required this.isOperator,
    required this.notOperator,
    required TypeAnnotationImpl type,
  })  : _expression = expression,
        _type = type {
    _becomeParentOf(_expression);
    _becomeParentOf(_type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Token get endToken => _type.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @override
  TypeAnnotationImpl get type => _type;

  set type(TypeAnnotationImpl type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addToken('isOperator', isOperator)
    ..addToken('notOperator', notOperator)
    ..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIsExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitIsExpression(this, contextType: contextType);
  }

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
  final NodeListImpl<LabelImpl> _labels = NodeListImpl._();

  /// The statement with which the labels are being associated.
  StatementImpl _statement;

  /// Initialize a newly created labeled statement.
  LabeledStatementImpl({
    required List<LabelImpl> labels,
    required StatementImpl statement,
  }) : _statement = statement {
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
  Token get endToken => _statement.endToken;

  @override
  NodeListImpl<LabelImpl> get labels => _labels;

  @override
  StatementImpl get statement => _statement;

  set statement(StatementImpl statement) {
    _statement = _becomeParentOf(statement);
  }

  @override
  StatementImpl get unlabeled => _statement.unlabeled;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addNode('statement', statement);

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
  final Token colon;

  /// Initialize a newly created label.
  LabelImpl({
    required SimpleIdentifierImpl label,
    required this.colon,
  }) : _label = label {
    _becomeParentOf(_label);
  }

  @override
  Token get beginToken => _label.beginToken;

  @override
  Token get endToken => colon;

  @override
  SimpleIdentifierImpl get label => _label;

  set label(SimpleIdentifierImpl label) {
    _label = _becomeParentOf(label);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('label', label)
    ..addToken('colon', colon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLabel(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label.accept(visitor);
  }
}

/// A library directive.
///
///    libraryAugmentationDirective ::=
///        [metadata] 'library' 'augment' [StringLiteral] ';'
@experimental
class LibraryAugmentationDirectiveImpl extends UriBasedDirectiveImpl
    implements LibraryAugmentationDirective {
  @override
  final Token libraryKeyword;

  @override
  final Token augmentKeyword;

  @override
  final Token semicolon;

  LibraryAugmentationDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.libraryKeyword,
    required this.augmentKeyword,
    required super.uri,
    required this.semicolon,
  });

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => libraryKeyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('libraryKeyword', libraryKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addNode('uri', uri)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitLibraryAugmentationDirective(this);
  }
}

/// A library directive.
///
///    libraryDirective ::=
///        [Annotation] 'library' [Identifier] ';'
class LibraryDirectiveImpl extends DirectiveImpl implements LibraryDirective {
  /// The token representing the 'library' keyword.
  @override
  final Token libraryKeyword;

  /// The name of the library being defined.
  LibraryIdentifierImpl? _name;

  /// The semicolon terminating the directive.
  @override
  final Token semicolon;

  /// Initialize a newly created library directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  LibraryDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.libraryKeyword,
    required LibraryIdentifierImpl? name,
    required this.semicolon,
  }) : _name = name {
    _becomeParentOf(_name);
  }

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => libraryKeyword;

  @override
  @Deprecated('Use name2')
  LibraryIdentifierImpl get name => _name!;

  set name(LibraryIdentifierImpl? name) {
    _name = _becomeParentOf(name);
  }

  @override
  LibraryIdentifierImpl? get name2 => _name;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('libraryKeyword', libraryKeyword)
    ..addNode('name', name2)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name?.accept(visitor);
  }
}

/// The identifier for a library.
///
///    libraryIdentifier ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
class LibraryIdentifierImpl extends IdentifierImpl
    implements LibraryIdentifier {
  /// The components of the identifier.
  final NodeListImpl<SimpleIdentifierImpl> _components = NodeListImpl._();

  /// Initialize a newly created prefixed identifier.
  LibraryIdentifierImpl({
    required List<SimpleIdentifierImpl> components,
  }) {
    _components._initialize(this, components);
  }

  @override
  Token get beginToken => _components.beginToken!;

  @override
  NodeListImpl<SimpleIdentifierImpl> get components => _components;

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
    return considerCanonicalizeString(buffer.toString());
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  Element? get staticElement => null;

  @override
  // TODO(paulberry): add "." tokens.
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('components', components);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryIdentifier(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitLibraryIdentifier(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _components.accept(visitor);
  }
}

class ListLiteralImpl extends TypedLiteralImpl implements ListLiteral {
  /// The left square bracket.
  @override
  final Token leftBracket;

  /// The expressions used to compute the elements of the list.
  final NodeListImpl<CollectionElementImpl> _elements = NodeListImpl._();

  /// The right square bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created list literal. The [constKeyword] can be `null`
  /// if the literal is not a constant. The [typeArguments] can be `null` if no
  /// type arguments were declared. The list of [elements] can be `null` if the
  /// list is empty.
  ListLiteralImpl({
    required super.constKeyword,
    required super.typeArguments,
    required this.leftBracket,
    required List<CollectionElementImpl> elements,
    required this.rightBracket,
  }) {
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
  NodeListImpl<CollectionElementImpl> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitListLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitListLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}

@experimental
abstract class ListPatternElementImpl
    implements AstNodeImpl, ListPatternElement {}

/// A list pattern.
///
///    listPattern ::=
///        [TypeArgumentList]? '[' [DartPattern] (',' [DartPattern])* ','? ']'
@experimental
class ListPatternImpl extends DartPatternImpl implements ListPattern {
  @override
  final TypeArgumentListImpl? typeArguments;

  @override
  final Token leftBracket;

  final NodeListImpl<ListPatternElementImpl> _elements = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  DartType? requiredType;

  ListPatternImpl({
    required this.typeArguments,
    required this.leftBracket,
    required List<ListPatternElementImpl> elements,
    required this.rightBracket,
  }) {
    _becomeParentOf(typeArguments);
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken => typeArguments?.beginToken ?? leftBracket;

  @override
  NodeList<ListPatternElementImpl> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('typeArguments', typeArguments)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitListPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    var elementType = typeArguments?.arguments.elementAtOrNull(0)?.typeOrThrow;
    return resolverVisitor.analyzeListPatternSchema(
      elementType: elementType,
      elements: elements,
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.listPatternResolver.resolve(node: this, context: context);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    elements.accept(visitor);
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

/// A logical-and pattern.
///
///    logicalAndPattern ::=
///        [DartPattern] '&&' [DartPattern]
@experimental
class LogicalAndPatternImpl extends DartPatternImpl
    implements LogicalAndPattern {
  @override
  final DartPatternImpl leftOperand;

  @override
  final Token operator;

  @override
  final DartPatternImpl rightOperand;

  LogicalAndPatternImpl({
    required this.leftOperand,
    required this.operator,
    required this.rightOperand,
  }) {
    _becomeParentOf(leftOperand);
    _becomeParentOf(rightOperand);
  }

  @override
  Token get beginToken => leftOperand.beginToken;

  @override
  Token get endToken => rightOperand.endToken;

  @override
  PatternPrecedence get precedence => PatternPrecedence.logicalAnd;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('leftOperand', leftOperand)
    ..addToken('operator', operator)
    ..addNode('rightOperand', rightOperand);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLogicalAndPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeLogicalAndPatternSchema(
        leftOperand, rightOperand);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeLogicalAndPattern(
        context, this, leftOperand, rightOperand);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    leftOperand.accept(visitor);
    rightOperand.accept(visitor);
  }
}

/// A logical-or pattern.
///
///    logicalOrPattern ::=
///        [DartPattern] '||' [DartPattern]
@experimental
class LogicalOrPatternImpl extends DartPatternImpl implements LogicalOrPattern {
  @override
  final DartPatternImpl leftOperand;

  @override
  final Token operator;

  @override
  final DartPatternImpl rightOperand;

  LogicalOrPatternImpl({
    required this.leftOperand,
    required this.operator,
    required this.rightOperand,
  }) {
    _becomeParentOf(leftOperand);
    _becomeParentOf(rightOperand);
  }

  @override
  Token get beginToken => leftOperand.beginToken;

  @override
  Token get endToken => rightOperand.endToken;

  @override
  PatternPrecedence get precedence => PatternPrecedence.logicalOr;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('leftOperand', leftOperand)
    ..addToken('operator', operator)
    ..addNode('rightOperand', rightOperand);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLogicalOrPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeLogicalOrPatternSchema(
        leftOperand, rightOperand);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeLogicalOrPattern(
        context, this, leftOperand, rightOperand);
    resolverVisitor.nullSafetyDeadCodeVerifier.flowEnd(rightOperand);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    leftOperand.accept(visitor);
    rightOperand.accept(visitor);
  }
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
  final Token separator;

  /// The expression computing the value that will be associated with the key.
  ExpressionImpl _value;

  /// Initialize a newly created map literal entry.
  MapLiteralEntryImpl({
    required ExpressionImpl key,
    required this.separator,
    required ExpressionImpl value,
  })  : _key = key,
        _value = value {
    _becomeParentOf(_key);
    _becomeParentOf(_value);
  }

  @override
  Token get beginToken => _key.beginToken;

  @override
  Token get endToken => _value.endToken;

  @override
  ExpressionImpl get key => _key;

  set key(ExpressionImpl string) {
    _key = _becomeParentOf(string);
  }

  @override
  ExpressionImpl get value => _value;

  set value(ExpressionImpl expression) {
    _value = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('key', key)
    ..addToken('separator', separator)
    ..addNode('value', value);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapLiteralEntry(this);

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.visitMapLiteralEntry(this, context: context);
    resolver.pushRewrite(null);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _key.accept(visitor);
    _value.accept(visitor);
  }
}

@experimental
abstract class MapPatternElementImpl
    implements AstNodeImpl, MapPatternElement {}

/// An entry in a map pattern.
///
///    mapPatternEntry ::=
///        [Expression] ':' [DartPattern]
@experimental
class MapPatternEntryImpl extends AstNodeImpl
    implements MapPatternEntry, MapPatternElementImpl {
  ExpressionImpl _key;

  @override
  final Token separator;

  @override
  final DartPatternImpl value;

  MapPatternEntryImpl({
    required ExpressionImpl key,
    required this.separator,
    required this.value,
  }) : _key = key {
    _becomeParentOf(_key);
    _becomeParentOf(value);
  }

  @override
  Token get beginToken => key.beginToken;

  @override
  Token get endToken => value.endToken;

  @override
  ExpressionImpl get key => _key;

  set key(ExpressionImpl key) {
    _key = _becomeParentOf(key);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('key', key)
    ..addToken('separator', separator)
    ..addNode('value', value);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapPatternEntry(this);

  @override
  void visitChildren(AstVisitor visitor) {
    key.accept(visitor);
    value.accept(visitor);
  }
}

/// A map pattern.
///
///    mapPattern ::=
///        [TypeArgumentList]? '{' [MapPatternEntry] (',' [MapPatternEntry])*
///        ','? '}'
@experimental
class MapPatternImpl extends DartPatternImpl implements MapPattern {
  @override
  final TypeArgumentListImpl? typeArguments;

  @override
  final Token leftBracket;

  final NodeListImpl<MapPatternElementImpl> _elements = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  DartType? requiredType;

  MapPatternImpl({
    required this.typeArguments,
    required this.leftBracket,
    required List<MapPatternElementImpl> elements,
    required this.rightBracket,
  }) {
    _becomeParentOf(typeArguments);
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken => typeArguments?.beginToken ?? leftBracket;

  @override
  NodeList<MapPatternElementImpl> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('typeArguments', typeArguments)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    shared.MapPatternTypeArguments<DartType>? typeArguments;
    final typeArgumentNodes = this.typeArguments?.arguments;
    if (typeArgumentNodes != null && typeArgumentNodes.length == 2) {
      typeArguments = shared.MapPatternTypeArguments(
        keyType: typeArgumentNodes[0].typeOrThrow,
        valueType: typeArgumentNodes[1].typeOrThrow,
      );
    }
    return resolverVisitor.analyzeMapPatternSchema(
      typeArguments: typeArguments,
      elements: elements,
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.resolveMapPattern(node: this, context: context);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    elements.accept(visitor);
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
  final Token? externalKeyword;

  /// The token representing the 'abstract' or 'static' keyword, or `null` if
  /// neither modifier was specified.
  @override
  final Token? modifierKeyword;

  /// The return type of the method, or `null` if no return type was declared.
  TypeAnnotationImpl? _returnType;

  /// The token representing the 'get' or 'set' keyword, or `null` if this is a
  /// method declaration rather than a property declaration.
  @override
  final Token? propertyKeyword;

  /// The token representing the 'operator' keyword, or `null` if this method
  /// does not declare an operator.
  @override
  final Token? operatorKeyword;

  @override
  final Token name;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters associated with the method, or `null` if this method
  /// declares a getter.
  FormalParameterListImpl? _parameters;

  /// The body of the method.
  FunctionBodyImpl _body;

  /// Return the element associated with this method, or `null` if the AST
  /// structure has not been resolved. The element can either be a
  /// [MethodElement], if this represents the declaration of a normal method, or
  /// a [PropertyAccessorElement] if this represents the declaration of either a
  /// getter or a setter.
  @override
  ExecutableElement? declaredElement;

  /// Initialize a newly created method declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [externalKeyword] can be `null` if the
  /// method is not external. The [modifierKeyword] can be `null` if the method
  /// is neither abstract nor static. The [returnType] can be `null` if no
  /// return type was specified. The [propertyKeyword] can be `null` if the
  /// method is neither a getter or a setter. The [operatorKeyword] can be
  /// `null` if the method does not implement an operator. The [parameters] must
  /// be `null` if this method declares a getter.
  MethodDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.externalKeyword,
    required this.modifierKeyword,
    required TypeAnnotationImpl? returnType,
    required this.propertyKeyword,
    required this.operatorKeyword,
    required this.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl? parameters,
    required FunctionBodyImpl body,
  })  : _returnType = returnType,
        _typeParameters = typeParameters,
        _parameters = parameters,
        _body = body {
    _becomeParentOf(_returnType);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
    _becomeParentOf(_body);
  }

  @override
  FunctionBodyImpl get body => _body;

  set body(FunctionBodyImpl functionBody) {
    _body = _becomeParentOf(functionBody);
  }

  @Deprecated('Use declaredElement instead')
  @override
  ExecutableElement? get declaredElement2 => declaredElement;

  @override
  Token get endToken => _body.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(externalKeyword, modifierKeyword) ??
        _returnType?.beginToken ??
        Token.lexicallyFirst(propertyKeyword, operatorKeyword) ??
        name;
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

  @Deprecated('Use name instead')
  @override
  Token get name2 => name;

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotationImpl? type) {
    _returnType = _becomeParentOf(type);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('externalKeyword', externalKeyword)
    ..addToken('modifierKeyword', modifierKeyword)
    ..addNode('returnType', returnType)
    ..addToken('propertyKeyword', propertyKeyword)
    ..addToken('operatorKeyword', operatorKeyword)
    ..addToken('name', name)
    ..addNode('parameters', parameters)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMethodDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
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
  MethodInvocationImpl({
    required ExpressionImpl? target,
    required this.operator,
    required SimpleIdentifierImpl methodName,
    required super.typeArguments,
    required super.argumentList,
  })  : _target = target,
        _methodName = methodName {
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

  set methodName(SimpleIdentifierImpl identifier) {
    _methodName = _becomeParentOf(identifier);
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

  set target(ExpressionImpl? expression) {
    _target = _becomeParentOf(expression);
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
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addToken('operator', operator)
    ..addNode('methodName', methodName)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMethodInvocation(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitMethodInvocation(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _methodName.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _target);
}

/// The declaration of a mixin.
///
///    mixinDeclaration ::=
///        metadata? mixinModifiers? 'mixin' [SimpleIdentifier]
///        [TypeParameterList]? [RequiresClause]? [ImplementsClause]?
///        '{' [ClassMember]* '}'
///
///    mixinModifiers ::= 'sealed' | 'base' | 'interface' | 'final'
class MixinDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements MixinDeclaration {
  /// Return the 'augment' keyword, or `null` if the keyword was absent.
  final Token? augmentKeyword;

  /// Return the 'sealed' keyword, or `null` if the keyword was absent.
  @override
  final Token? sealedKeyword;

  /// Return the 'base' keyword, or `null` if the keyword was absent.
  @override
  final Token? baseKeyword;

  /// Return the 'interface' keyword, or `null` if the keyword was absent.
  @override
  final Token? interfaceKeyword;

  /// Return the 'final' keyword, or `null` if the keyword was absent.
  @override
  final Token? finalKeyword;

  @override
  final Token mixinKeyword;

  /// The type parameters for the class or mixin,
  /// or `null` if the declaration does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The on clause for the mixin, or `null` if the mixin does not have any
  /// super-class constraints.
  OnClauseImpl? _onClause;

  /// The implements clause for the class or mixin,
  /// or `null` if the declaration does not implement any interfaces.
  ImplementsClauseImpl? _implementsClause;

  @override
  MixinElement? declaredElement;

  /// The left curly bracket.
  @override
  final Token leftBracket;

  /// The members defined by the class or mixin.
  final NodeListImpl<ClassMemberImpl> _members = NodeListImpl._();

  /// The right curly bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created mixin declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the mixin does not have the
  /// corresponding attribute. The [typeParameters] can be `null` if the mixin
  /// does not have any type parameters. Either or both of the [onClause],
  /// and [implementsClause] can be `null` if the mixin does not have the
  /// corresponding clause. The list of [members] can be `null` if the mixin
  /// does not have any members.
  MixinDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.sealedKeyword,
    required this.baseKeyword,
    required this.interfaceKeyword,
    required this.finalKeyword,
    required this.mixinKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required OnClauseImpl? onClause,
    required ImplementsClauseImpl? implementsClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  })  : _typeParameters = typeParameters,
        _onClause = onClause,
        _implementsClause = implementsClause {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_onClause);
    _becomeParentOf(_implementsClause);
    _members._initialize(this, members);
  }

  @Deprecated('Use declaredElement instead')
  @override
  MixinElement? get declaredElement2 => declaredElement;

  @override
  Token get endToken => rightBracket;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return sealedKeyword ??
        baseKeyword ??
        interfaceKeyword ??
        finalKeyword ??
        mixinKeyword;
  }

  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @override
  NodeListImpl<ClassMemberImpl> get members => _members;

  @override
  OnClauseImpl? get onClause => _onClause;

  set onClause(OnClauseImpl? onClause) {
    _onClause = _becomeParentOf(onClause);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('sealedKeyword', sealedKeyword)
    ..addToken('baseKeyword', baseKeyword)
    ..addToken('interfaceKeyword', interfaceKeyword)
    ..addToken('finalKeyword', finalKeyword)
    ..addToken('mixinKeyword', mixinKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('onClause', onClause)
    ..addNode('implementsClause', implementsClause)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMixinDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
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
  @override
  final Token name;

  /// Initialize a newly created compilation unit member with the given [name].
  /// Either or both of the [comment] and [metadata] can be `null` if the member
  /// does not have the corresponding attribute.
  NamedCompilationUnitMemberImpl({
    required super.comment,
    required super.metadata,
    required this.name,
  });

  @Deprecated('Use name instead')
  @override
  Token get name2 => name;
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
  NamedExpressionImpl({
    required LabelImpl name,
    required ExpressionImpl expression,
  })  : _name = name,
        _expression = expression {
    _becomeParentOf(_name);
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => _name.beginToken;

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

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  LabelImpl get name => _name;

  set name(LabelImpl identifier) {
    _name = _becomeParentOf(identifier);
  }

  @override
  Precedence get precedence => Precedence.none;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('name', name)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNamedExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitNamedExpression(this, contextType: contextType);
  }

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
class NamedTypeImpl extends TypeAnnotationImpl implements NamedType {
  /// The name of the type.
  IdentifierImpl _name;

  /// The type arguments associated with the type, or `null` if there are no
  /// type arguments.
  TypeArgumentListImpl? _typeArguments;

  @override
  final Token? question;

  /// The type being named, or `null` if the AST structure has not been
  /// resolved, or if this is part of a [ConstructorReference].
  @override
  DartType? type;

  /// Initialize a newly created type name. The [typeArguments] can be `null` if
  /// there are no type arguments.
  NamedTypeImpl({
    required IdentifierImpl name,
    required TypeArgumentListImpl? typeArguments,
    required this.question,
  })  : _name = name,
        _typeArguments = typeArguments {
    _becomeParentOf(_name);
    _becomeParentOf(_typeArguments);
  }

  @override
  Token get beginToken => _name.beginToken;

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

  set name(IdentifierImpl identifier) {
    _name = _becomeParentOf(identifier);
  }

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('name', name)
    ..addNode('typeArguments', typeArguments)
    ..addToken('question', question);

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
  /// The configurations used to control which library will actually be loaded
  /// at run-time.
  final NodeListImpl<ConfigurationImpl> _configurations = NodeListImpl._();

  /// The combinators used to control which names are imported or exported.
  final NodeListImpl<CombinatorImpl> _combinators = NodeListImpl._();

  /// The semicolon terminating the directive.
  @override
  final Token semicolon;

  /// Initialize a newly created namespace directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute. The list of [combinators] can be `null` if there
  /// are no combinators.
  NamespaceDirectiveImpl({
    required super.comment,
    required super.metadata,
    required super.uri,
    required List<ConfigurationImpl>? configurations,
    required List<CombinatorImpl>? combinators,
    required this.semicolon,
  }) {
    _configurations._initialize(this, configurations);
    _combinators._initialize(this, combinators);
  }

  @override
  NodeListImpl<CombinatorImpl> get combinators => _combinators;

  @override
  NodeListImpl<ConfigurationImpl> get configurations => _configurations;

  @override
  Token get endToken => semicolon;
}

/// The "native" clause in an class declaration.
///
///    nativeClause ::=
///        'native' [StringLiteral]
class NativeClauseImpl extends AstNodeImpl implements NativeClause {
  @override
  final Token nativeKeyword;

  @override
  final StringLiteralImpl? name;

  /// Initialize a newly created native clause.
  NativeClauseImpl({
    required this.nativeKeyword,
    required this.name,
  }) {
    _becomeParentOf(name);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Token get endToken {
    return name?.endToken ?? nativeKeyword;
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('nativeKeyword', nativeKeyword)
    ..addNode('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNativeClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    name?.accept(visitor);
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
  final Token nativeKeyword;

  /// The string literal, after the 'native' token.
  StringLiteralImpl? _stringLiteral;

  /// The token representing the semicolon that marks the end of the function
  /// body.
  @override
  final Token semicolon;

  /// Initialize a newly created function body consisting of the 'native' token,
  /// a string literal, and a semicolon.
  NativeFunctionBodyImpl({
    required this.nativeKeyword,
    required StringLiteralImpl? stringLiteral,
    required this.semicolon,
  }) : _stringLiteral = stringLiteral {
    _becomeParentOf(_stringLiteral);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Token get endToken => semicolon;

  @override
  StringLiteralImpl? get stringLiteral => _stringLiteral;

  set stringLiteral(StringLiteralImpl? stringLiteral) {
    _stringLiteral = _becomeParentOf(stringLiteral);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('nativeKeyword', nativeKeyword)
    ..addNode('stringLiteral', stringLiteral)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNativeFunctionBody(this);

  @override
  DartType resolve(ResolverVisitor resolver, DartType? imposedType) =>
      resolver.visitNativeFunctionBody(this, imposedType: imposedType);

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
  late final List<E> _elements;

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

  @Deprecated('NodeList cannot be resized')
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

  @Deprecated('NodeList cannot be resized')
  @override
  void add(E element) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @Deprecated('NodeList cannot be resized')
  @override
  void addAll(Iterable<E> iterable) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @Deprecated('NodeList cannot be resized')
  @override
  void clear() {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @Deprecated('NodeList cannot be resized')
  @override
  void insert(int index, E element) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @Deprecated('NodeList cannot be resized')
  @override
  E removeAt(int index) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  /// Set the [owner] of this container, and populate it with [elements].
  void _initialize(AstNodeImpl owner, List<E>? elements) {
    _owner = owner;
    if (elements == null || elements.isEmpty) {
      _elements = const <Never>[];
    } else {
      _elements = elements.toList(growable: false);
      var length = elements.length;
      for (var i = 0; i < length; i++) {
        var node = elements[i];
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
  final NodeListImpl<AnnotationImpl> _metadata = NodeListImpl._();

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  @override
  final Token? covariantKeyword;

  /// The 'required' keyword, or `null` if the keyword was not used.
  @override
  final Token? requiredKeyword;

  @override
  final Token? name;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute.
  NormalFormalParameterImpl({
    required CommentImpl? comment,
    required List<AnnotationImpl>? metadata,
    required this.covariantKeyword,
    required this.requiredKeyword,
    required this.name,
  }) : _comment = comment {
    _becomeParentOf(_comment);
    _metadata._initialize(this, metadata);
  }

  @override
  CommentImpl? get documentationComment => _comment;

  set documentationComment(CommentImpl? comment) {
    _comment = _becomeParentOf(comment);
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
  NodeListImpl<AnnotationImpl> get metadata => _metadata;

  @override
  List<AstNode> get sortedCommentAndAnnotations {
    var comment = _comment;
    return <AstNode>[
      if (comment != null) comment,
      ..._metadata,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  @override
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addNode('documentationComment', documentationComment)
      ..addNodeList('metadata', metadata)
      ..addToken('requiredKeyword', requiredKeyword)
      ..addToken('covariantKeyword', covariantKeyword);
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

/// A null-assert pattern.
///
///    nullAssertPattern ::=
///        [DartPattern] '!'
@experimental
class NullAssertPatternImpl extends DartPatternImpl
    implements NullAssertPattern {
  @override
  final DartPatternImpl pattern;

  @override
  final Token operator;

  NullAssertPatternImpl({
    required this.pattern,
    required this.operator,
  }) {
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => operator;

  @override
  PatternPrecedence get precedence => PatternPrecedence.postfix;

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addToken('operator', operator);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullAssertPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeNullCheckOrAssertPatternSchema(
      pattern,
      isAssert: true,
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeNullCheckOrAssertPattern(context, this, pattern,
        isAssert: true);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }
}

/// A null-check pattern.
///
///    nullCheckPattern ::=
///        [DartPattern] '?'
@experimental
class NullCheckPatternImpl extends DartPatternImpl implements NullCheckPattern {
  @override
  final DartPatternImpl pattern;

  @override
  final Token operator;

  NullCheckPatternImpl({
    required this.pattern,
    required this.operator,
  }) {
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => operator;

  @override
  PatternPrecedence get precedence => PatternPrecedence.postfix;

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addToken('operator', operator);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullCheckPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeNullCheckOrAssertPatternSchema(
      pattern,
      isAssert: false,
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeNullCheckOrAssertPattern(context, this, pattern,
        isAssert: false);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }
}

/// A null literal expression.
///
///    nullLiteral ::=
///        'null'
class NullLiteralImpl extends LiteralImpl implements NullLiteral {
  /// The token representing the literal.
  @override
  final Token literal;

  /// Initialize a newly created null literal.
  NullLiteralImpl({
    required this.literal,
  });

  @override
  Token get beginToken => literal;

  @override
  Token get endToken => literal;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitNullLiteral(this, contextType: contextType);
  }

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

/// An object pattern.
///
///    objectPattern ::=
///        [Identifier] [TypeArgumentList]? '(' [PatternField] ')'
@experimental
class ObjectPatternImpl extends DartPatternImpl implements ObjectPattern {
  final NodeListImpl<PatternFieldImpl> _fields = NodeListImpl._();

  @override
  final Token leftParenthesis;

  @override
  final Token rightParenthesis;

  @override
  final NamedTypeImpl type;

  ObjectPatternImpl({
    required this.type,
    required this.leftParenthesis,
    required List<PatternFieldImpl> fields,
    required this.rightParenthesis,
  }) {
    _becomeParentOf(type);
    _fields._initialize(this, fields);
  }

  @override
  Token get beginToken => type.beginToken;

  @override
  Token get endToken => rightParenthesis;

  @override
  NodeList<PatternFieldImpl> get fields => _fields;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('type', type)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fields', fields)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitObjectPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeObjectPatternSchema(type.typeOrThrow);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeObjectPattern(
      context,
      this,
      fields: resolverVisitor.buildSharedPatternFields(fields),
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {
    type.accept(visitor);
    fields.accept(visitor);
  }
}

/// The "on" clause in a mixin declaration.
///
///    onClause ::=
///        'on' [TypeName] (',' [TypeName])*
class OnClauseImpl extends AstNodeImpl implements OnClause {
  @override
  final Token onKeyword;

  /// The classes are super-class constraints for the mixin.
  final NodeListImpl<NamedTypeImpl> _superclassConstraints = NodeListImpl._();

  /// Initialize a newly created on clause.
  OnClauseImpl({
    required this.onKeyword,
    required List<NamedTypeImpl> superclassConstraints,
  }) {
    _superclassConstraints._initialize(this, superclassConstraints);
  }

  @override
  Token get beginToken => onKeyword;

  @override
  Token get endToken => _superclassConstraints.endToken ?? onKeyword;

  @override
  NodeListImpl<NamedTypeImpl> get superclassConstraints =>
      _superclassConstraints;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('onKeyword', onKeyword)
    ..addNodeList('superclassConstraints', superclassConstraints);

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
  final Token leftParenthesis;

  /// The expression within the parentheses.
  ExpressionImpl _expression;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// Initialize a newly created parenthesized expression.
  ParenthesizedExpressionImpl({
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.rightParenthesis,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Token get endToken => rightParenthesis;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
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
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitParenthesizedExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitParenthesizedExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A parenthesized pattern.
///
///    parenthesizedPattern ::=
///        '(' [DartPattern] ')'
@experimental
class ParenthesizedPatternImpl extends DartPatternImpl
    implements ParenthesizedPattern {
  @override
  final Token leftParenthesis;

  @override
  final DartPatternImpl pattern;

  @override
  final Token rightParenthesis;

  ParenthesizedPatternImpl({
    required this.leftParenthesis,
    required this.pattern,
    required this.rightParenthesis,
  }) {
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Token get endToken => rightParenthesis;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  DartPattern get unParenthesized {
    var result = pattern;
    while (result is ParenthesizedPatternImpl) {
      result = result.pattern;
    }
    return result;
  }

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('pattern', pattern)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitParenthesizedPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.dispatchPatternSchema(pattern);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.dispatchPattern(context, pattern);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }
}

/// A part directive.
///
///    partDirective ::=
///        [Annotation] 'part' [StringLiteral] ';'
class PartDirectiveImpl extends UriBasedDirectiveImpl implements PartDirective {
  /// The token representing the 'part' keyword.
  @override
  final Token partKeyword;

  /// The semicolon terminating the directive.
  @override
  final Token semicolon;

  /// Initialize a newly created part directive. Either or both of the [comment]
  /// and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  PartDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.partKeyword,
    required super.uri,
    required this.semicolon,
  });

  @override
  PartElement? get element {
    return super.element as PartElement?;
  }

  @Deprecated('Use element instead')
  @override
  PartElement? get element2 => element;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('partKeyword', partKeyword)
    ..addNode('uri', uri)
    ..addToken('semicolon', semicolon);

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
  final Token partKeyword;

  /// The token representing the 'of' keyword.
  @override
  final Token ofKeyword;

  /// The URI of the library that the containing compilation unit is part of.
  StringLiteralImpl? _uri;

  /// The name of the library that the containing compilation unit is part of,
  /// or `null` if no name was given (typically because a library URI was
  /// provided).
  LibraryIdentifierImpl? _libraryName;

  /// The semicolon terminating the directive.
  @override
  final Token semicolon;

  /// Initialize a newly created part-of directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  PartOfDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.partKeyword,
    required this.ofKeyword,
    required StringLiteralImpl? uri,
    required LibraryIdentifierImpl? libraryName,
    required this.semicolon,
  })  : _uri = uri,
        _libraryName = libraryName {
    _becomeParentOf(_uri);
    _becomeParentOf(_libraryName);
  }

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  LibraryIdentifierImpl? get libraryName => _libraryName;

  set libraryName(LibraryIdentifierImpl? libraryName) {
    _libraryName = _becomeParentOf(libraryName);
  }

  @override
  StringLiteralImpl? get uri => _uri;

  set uri(StringLiteralImpl? uri) {
    _uri = _becomeParentOf(uri);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('partKeyword', partKeyword)
    ..addToken('ofKeyword', ofKeyword)
    ..addNode('uri', uri)
    ..addNode('libraryName', libraryName)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPartOfDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _libraryName?.accept(visitor);
    _uri?.accept(visitor);
  }
}

/// A pattern assignment.
///
///    patternAssignment ::=
///        [DartPattern] '=' [Expression]
///
/// When used as the condition in an `if`, the pattern is always a
/// [PatternVariable] whose type is not `null`.
@experimental
class PatternAssignmentImpl extends ExpressionImpl
    implements PatternAssignment {
  @override
  final Token equals;

  ExpressionImpl _expression;

  @override
  final DartPatternImpl pattern;

  /// The pattern type schema, used for downward inference of [expression];
  /// or `null` if the node is not resolved yet.
  DartType? patternTypeSchema;

  PatternAssignmentImpl({
    required this.pattern,
    required this.equals,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(pattern);
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  // TODO(brianwilkerson) Create a new precedence constant for pattern
  //  assignments. The proposal doesn't make the actual value clear.
  Precedence get precedence => Precedence.assignment;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addToken('equals', equals)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPatternAssignment(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType? contextType) {
    resolver.visitPatternAssignment(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
    expression.accept(visitor);
  }
}

/// A field in a record pattern.
///
///    patternField ::=
///        [PatternFieldName]? [DartPattern]
@experimental
class PatternFieldImpl extends AstNodeImpl implements PatternField {
  @override
  Element? element;

  @override
  final PatternFieldNameImpl? name;

  @override
  final DartPatternImpl pattern;

  PatternFieldImpl({required this.name, required this.pattern}) {
    _becomeParentOf(name);
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => name?.beginToken ?? pattern.beginToken;

  @override
  Token get endToken => pattern.endToken;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('name', name)
    ..addNode('pattern', pattern);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPatternField(this);

  @override
  void visitChildren(AstVisitor visitor) {
    name?.accept(visitor);
    pattern.accept(visitor);
  }
}

/// A field name in a record pattern field.
///
///    patternFieldName ::=
///        [Token]? ':'
@experimental
class PatternFieldNameImpl extends AstNodeImpl implements PatternFieldName {
  @override
  final Token colon;

  @override
  final Token? name;

  PatternFieldNameImpl({required this.name, required this.colon});

  @override
  Token get beginToken => name ?? colon;

  @override
  Token get endToken => colon;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('name', name)
    ..addToken('colon', colon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPatternFieldName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A pattern variable declaration.
///
///    patternDeclaration ::=
///        ( 'final' | 'var' ) [DartPattern] '=' [Expression]
@experimental
class PatternVariableDeclarationImpl extends AnnotatedNodeImpl
    implements PatternVariableDeclaration {
  @override
  final Token equals;

  ExpressionImpl _expression;

  @override
  final Token keyword;

  @override
  final DartPatternImpl pattern;

  /// The pattern type schema, used for downward inference of [expression];
  /// or `null` if the node is not resolved yet.
  DartType? patternTypeSchema;

  /// Variables declared in [pattern].
  late final List<BindPatternVariableElementImpl> elements;

  PatternVariableDeclarationImpl({
    required this.keyword,
    required this.pattern,
    required this.equals,
    required ExpressionImpl expression,
    required super.comment,
    required super.metadata,
  }) : _expression = expression {
    _becomeParentOf(pattern);
    _becomeParentOf(_expression);
  }

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  /// If [keyword] is `final`, returns it.
  Token? get finalKeyword {
    if (keyword.keyword == Keyword.FINAL) {
      return keyword;
    }
    return null;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => keyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('pattern', pattern)
    ..addToken('equals', equals)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitPatternVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    pattern.accept(visitor);
    expression.accept(visitor);
  }
}

/// A pattern variable declaration statement.
///
///    patternDeclarationStatement ::=
///        [PatternVariableDeclaration] ';'
@experimental
class PatternVariableDeclarationStatementImpl extends StatementImpl
    implements PatternVariableDeclarationStatement {
  @override
  final PatternVariableDeclarationImpl declaration;

  @override
  final Token semicolon;

  PatternVariableDeclarationStatementImpl({
    required this.declaration,
    required this.semicolon,
  }) {
    _becomeParentOf(declaration);
  }

  @override
  Token get beginToken => declaration.beginToken;

  @override
  Token get endToken => semicolon;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('declaration', declaration)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitPatternVariableDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    declaration.accept(visitor);
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
  final Token operator;

  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created postfix expression.
  PostfixExpressionImpl({
    required ExpressionImpl operand,
    required this.operator,
  }) : _operand = operand {
    _becomeParentOf(_operand);
  }

  @override
  Token get beginToken => _operand.beginToken;

  @override
  Token get endToken => operator;

  @override
  ExpressionImpl get operand => _operand;

  set operand(ExpressionImpl expression) {
    _operand = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('operand', operand)
    ..addToken('operator', operator);

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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitPostfixExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _operand.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, operand);
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
  final Token period;

  /// The identifier being prefixed.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created prefixed identifier.
  PrefixedIdentifierImpl({
    required SimpleIdentifierImpl prefix,
    required this.period,
    required SimpleIdentifierImpl identifier,
  })  : _prefix = prefix,
        _identifier = identifier {
    _becomeParentOf(_prefix);
    _becomeParentOf(_identifier);
  }

  @override
  Token get beginToken => _prefix.beginToken;

  @override
  Token get endToken => _identifier.endToken;

  @override
  SimpleIdentifierImpl get identifier => _identifier;

  set identifier(SimpleIdentifierImpl identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  bool get isDeferred {
    Element? element = _prefix.staticElement;
    if (element is PrefixElement) {
      final imports = element.imports;
      if (imports.length != 1) {
        return false;
      }
      return imports[0].prefix is DeferredImportElementPrefix;
    }
    return false;
  }

  @override
  String get name => "${_prefix.name}.${_identifier.name}";

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  SimpleIdentifierImpl get prefix => _prefix;

  set prefix(SimpleIdentifierImpl identifier) {
    _prefix = _becomeParentOf(identifier);
  }

  @override
  Element? get staticElement {
    return _identifier.staticElement;
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('prefix', prefix)
    ..addToken('period', period)
    ..addNode('identifier', identifier);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPrefixedIdentifier(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitPrefixedIdentifier(this, contextType: contextType);
  }

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
  final Token operator;

  /// The expression computing the operand for the operator.
  ExpressionImpl _operand;

  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created prefix expression.
  PrefixExpressionImpl({
    required this.operator,
    required ExpressionImpl operand,
  }) : _operand = operand {
    _becomeParentOf(_operand);
  }

  @override
  Token get beginToken => operator;

  @override
  Token get endToken => _operand.endToken;

  @override
  ExpressionImpl get operand => _operand;

  set operand(ExpressionImpl expression) {
    _operand = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('operator', operator)
    ..addNode('operand', operand);

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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitPrefixExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _operand.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, operand) && operator.type.isIncrementOperator;
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
  final Token operator;

  /// The name of the property being accessed.
  SimpleIdentifierImpl _propertyName;

  /// Initialize a newly created property access expression.
  PropertyAccessImpl({
    required ExpressionImpl? target,
    required this.operator,
    required SimpleIdentifierImpl propertyName,
  })  : _target = target,
        _propertyName = propertyName {
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

  set propertyName(SimpleIdentifierImpl identifier) {
    _propertyName = _becomeParentOf(identifier);
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

  set target(ExpressionImpl? expression) {
    _target = _becomeParentOf(expression);
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
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addToken('operator', operator)
    ..addNode('propertyName', propertyName);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPropertyAccess(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitPropertyAccess(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _propertyName.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _target);
}

class RecordLiteralImpl extends LiteralImpl implements RecordLiteral {
  @override
  final Token? constKeyword;

  @override
  final Token leftParenthesis;

  /// The syntactic elements used to compute the fields of the record.
  final NodeListImpl<ExpressionImpl> _fields = NodeListImpl._();

  @override
  final Token rightParenthesis;

  /// Initialize a newly created record literal.
  RecordLiteralImpl({
    required this.constKeyword,
    required this.leftParenthesis,
    required List<ExpressionImpl> fields,
    required this.rightParenthesis,
  }) {
    _fields._initialize(this, fields);
  }

  @override
  Token get beginToken => constKeyword ?? leftParenthesis;

  @override
  Token get endToken => rightParenthesis;

  @override
  NodeList<ExpressionImpl> get fields => _fields;

  @override
  bool get isConst => constKeyword != null || inConstantContext;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => super._childEntities
    ..addToken('constKeyword', constKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fields', fields)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRecordLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitRecordLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _fields.accept(visitor);
  }
}

/// A record pattern.
///
///    recordPattern ::=
///        '(' [PatternField] (',' [PatternField])* ')'
@experimental
class RecordPatternImpl extends DartPatternImpl implements RecordPattern {
  final NodeListImpl<PatternFieldImpl> _fields = NodeListImpl._();

  @override
  final Token leftParenthesis;

  @override
  final Token rightParenthesis;

  RecordPatternImpl({
    required this.leftParenthesis,
    required List<PatternFieldImpl> fields,
    required this.rightParenthesis,
  }) {
    _fields._initialize(this, fields);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Token get endToken => rightParenthesis;

  @override
  NodeList<PatternFieldImpl> get fields => _fields;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fields', fields)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRecordPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeRecordPatternSchema(
      fields: resolverVisitor.buildSharedPatternFields(fields),
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeRecordPattern(
      context,
      this,
      fields: resolverVisitor.buildSharedPatternFields(fields),
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {
    fields.accept(visitor);
  }
}

abstract class RecordTypeAnnotationFieldImpl extends AstNodeImpl
    implements RecordTypeAnnotationField {
  @override
  final NodeListImpl<AnnotationImpl> metadata = NodeListImpl._();

  @override
  final TypeAnnotationImpl type;

  RecordTypeAnnotationFieldImpl({
    required List<AnnotationImpl>? metadata,
    required this.type,
  }) {
    this.metadata._initialize(this, metadata);
    _becomeParentOf(type);
  }

  @override
  Token get beginToken => metadata.beginToken ?? type.beginToken;

  @override
  Token get endToken => name ?? type.endToken;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNodeList('metadata', metadata)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  void visitChildren(AstVisitor visitor) {
    metadata.accept(visitor);
    type.accept(visitor);
  }
}

class RecordTypeAnnotationImpl extends TypeAnnotationImpl
    implements RecordTypeAnnotation {
  @override
  final Token leftParenthesis;

  @override
  final NodeListImpl<RecordTypeAnnotationPositionalFieldImpl> positionalFields =
      NodeListImpl._();

  @override
  final RecordTypeAnnotationNamedFieldsImpl? namedFields;

  @override
  final Token rightParenthesis;

  @override
  final Token? question;

  @override
  DartType? type;

  RecordTypeAnnotationImpl({
    required this.leftParenthesis,
    required List<RecordTypeAnnotationPositionalFieldImpl> positionalFields,
    required this.namedFields,
    required this.rightParenthesis,
    required this.question,
  }) {
    _becomeParentOf(namedFields);
    this.positionalFields._initialize(this, positionalFields);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Token get endToken => question ?? rightParenthesis;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('positionalFields', positionalFields)
    ..addNode('namedFields', namedFields)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('question', question);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRecordTypeAnnotation(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    positionalFields.accept(visitor);
    namedFields?.accept(visitor);
  }
}

class RecordTypeAnnotationNamedFieldImpl extends RecordTypeAnnotationFieldImpl
    implements RecordTypeAnnotationNamedField {
  @override
  final Token name;

  RecordTypeAnnotationNamedFieldImpl({
    required super.metadata,
    required super.type,
    required this.name,
  });

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRecordTypeAnnotationNamedField(this);
  }
}

class RecordTypeAnnotationNamedFieldsImpl extends AstNodeImpl
    implements RecordTypeAnnotationNamedFields {
  @override
  final Token leftBracket;

  @override
  final NodeListImpl<RecordTypeAnnotationNamedFieldImpl> fields =
      NodeListImpl._();

  @override
  final Token rightBracket;

  RecordTypeAnnotationNamedFieldsImpl({
    required this.leftBracket,
    required List<RecordTypeAnnotationNamedFieldImpl> fields,
    required this.rightBracket,
  }) {
    this.fields._initialize(this, fields);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('fields', fields)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRecordTypeAnnotationNamedFields(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    fields.accept(visitor);
  }
}

class RecordTypeAnnotationPositionalFieldImpl
    extends RecordTypeAnnotationFieldImpl
    implements RecordTypeAnnotationPositionalField {
  @override
  final Token? name;

  RecordTypeAnnotationPositionalFieldImpl({
    required super.metadata,
    required super.type,
    required this.name,
  });

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRecordTypeAnnotationPositionalField(this);
  }
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
  final Token thisKeyword;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  @override
  final Token? period;

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
  RedirectingConstructorInvocationImpl({
    required this.thisKeyword,
    required this.period,
    required SimpleIdentifierImpl? constructorName,
    required ArgumentListImpl argumentList,
  })  : _constructorName = constructorName,
        _argumentList = argumentList {
    _becomeParentOf(_constructorName);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => thisKeyword;

  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  set constructorName(SimpleIdentifierImpl? identifier) {
    _constructorName = _becomeParentOf(identifier);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('thisKeyword', thisKeyword)
    ..addToken('period', period)
    ..addNode('constructorName', constructorName)
    ..addNode('argumentList', argumentList);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRedirectingConstructorInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName?.accept(visitor);
    _argumentList.accept(visitor);
  }
}

/// A relational pattern.
///
///    relationalPattern ::=
///        (equalityOperator | relationalOperator) [Expression]
@experimental
class RelationalPatternImpl extends DartPatternImpl
    implements RelationalPattern {
  ExpressionImpl _operand;

  @override
  final Token operator;

  @override
  MethodElement? element;

  RelationalPatternImpl({
    required this.operator,
    required ExpressionImpl operand,
  }) : _operand = operand {
    _becomeParentOf(operand);
  }

  @override
  Token get beginToken => operator;

  @override
  Token get endToken => operand.endToken;

  @override
  ExpressionImpl get operand => _operand;

  set operand(ExpressionImpl operand) {
    _operand = _becomeParentOf(operand);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.relational;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('operator', operator)
    ..addNode('operand', operand);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRelationalPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeRelationalPatternSchema();
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeRelationalPattern(context, this, operand);
    resolverVisitor.popRewrite();
  }

  @override
  void visitChildren(AstVisitor visitor) {
    operand.accept(visitor);
  }
}

@experimental
class RestPatternElementImpl extends AstNodeImpl
    implements
        RestPatternElement,
        ListPatternElementImpl,
        MapPatternElementImpl {
  @override
  final Token operator;

  @override
  final DartPatternImpl? pattern;

  RestPatternElementImpl({
    required this.operator,
    required this.pattern,
  }) {
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => operator;

  @override
  Token get endToken => pattern?.endToken ?? operator;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('operator', operator)
    ..addNode('pattern', pattern);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRestPatternElement(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern?.accept(visitor);
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
  final Token rethrowKeyword;

  /// Initialize a newly created rethrow expression.
  RethrowExpressionImpl({
    required this.rethrowKeyword,
  });

  @override
  Token get beginToken => rethrowKeyword;

  @override
  Token get endToken => rethrowKeyword;

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('rethrowKeyword', rethrowKeyword);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRethrowExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitRethrowExpression(this, contextType: contextType);
  }

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
  final Token returnKeyword;

  /// The expression computing the value to be returned, or `null` if no
  /// explicit value was provided.
  ExpressionImpl? _expression;

  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

  /// Initialize a newly created return statement. The [expression] can be
  /// `null` if no explicit value was provided.
  ReturnStatementImpl({
    required this.returnKeyword,
    required ExpressionImpl? expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => returnKeyword;

  @override
  Token get endToken => semicolon;

  @override
  ExpressionImpl? get expression => _expression;

  set expression(ExpressionImpl? expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('returnKeyword', returnKeyword)
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

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
  final Token scriptTag;

  /// Initialize a newly created script tag.
  ScriptTagImpl({
    required this.scriptTag,
  });

  @override
  Token get beginToken => scriptTag;

  @override
  Token get endToken => scriptTag;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('scriptTag', scriptTag);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitScriptTag(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

class SetOrMapLiteralImpl extends TypedLiteralImpl implements SetOrMapLiteral {
  @override
  final Token leftBracket;

  /// The syntactic elements in the set.
  final NodeListImpl<CollectionElementImpl> _elements = NodeListImpl._();

  @override
  final Token rightBracket;

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
  SetOrMapLiteralImpl({
    required super.constKeyword,
    required super.typeArguments,
    required this.leftBracket,
    required List<CollectionElementImpl> elements,
    required this.rightBracket,
  }) {
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
  NodeListImpl<CollectionElementImpl> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  bool get isMap => _resolvedKind == _SetOrMapKind.map;

  @override
  bool get isSet => _resolvedKind == _SetOrMapKind.set;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSetOrMapLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
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
  final NodeListImpl<SimpleIdentifierImpl> _shownNames = NodeListImpl._();

  /// Initialize a newly created import show combinator.
  ShowCombinatorImpl({
    required super.keyword,
    required List<SimpleIdentifierImpl> shownNames,
  }) {
    _shownNames._initialize(this, shownNames);
  }

  @override
  Token get endToken => _shownNames.endToken!;

  @override
  NodeListImpl<SimpleIdentifierImpl> get shownNames => _shownNames;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNodeList('shownNames', shownNames);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitShowCombinator(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _shownNames.accept(visitor);
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
  final Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if a type was
  /// specified. The [type] must be `null` if the keyword is 'var'.
  SimpleFormalParameterImpl({
    required super.comment,
    required super.metadata,
    required super.covariantKeyword,
    required super.requiredKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required super.name,
  }) : _type = type {
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
    return name!;
  }

  @override
  Token get endToken => name ?? type!.endToken;

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isExplicitlyTyped => _type != null;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSimpleFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
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
  final Token token;

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
  ChildEntities get _childEntities => ChildEntities()..addToken('token', token);

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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSimpleIdentifier(this, contextType: contextType);
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
  final Token literal;

  /// The value of the literal.
  @override
  String value;

  /// Initialize a newly created simple string literal.
  SimpleStringLiteralImpl({
    required this.literal,
    required this.value,
  });

  @override
  Token get beginToken => literal;

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
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  StringLexemeHelper get _helper {
    return StringLexemeHelper(literal.lexeme, true, true);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSimpleStringLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSimpleStringLiteral(this, contextType: contextType);
  }

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
  final Token spreadOperator;

  ExpressionImpl _expression;

  SpreadElementImpl({
    required this.spreadOperator,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => spreadOperator;

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isNullAware =>
      spreadOperator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('spreadOperator', spreadOperator)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitSpreadElement(this);
  }

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.visitSpreadElement(this, context: context);
    resolver.pushRewrite(null);
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
  final NodeListImpl<InterpolationElementImpl> _elements = NodeListImpl._();

  /// Initialize a newly created string interpolation expression.
  StringInterpolationImpl({
    required List<InterpolationElementImpl> elements,
  }) {
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
  NodeListImpl<InterpolationElementImpl> get elements => _elements;

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

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('elements', elements);

  StringLexemeHelper get _firstHelper {
    var lastString = _elements.first as InterpolationString;
    String lexeme = lastString.contents.lexeme;
    return StringLexemeHelper(lexeme, true, false);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitStringInterpolation(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitStringInterpolation(this, contextType: contextType);
  }

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
      if (lexeme.startsWith("'''", start)) {
        isSingleQuoted = true;
        isMultiline = true;
        start += 3;
        start = _trimInitialWhitespace(start);
      } else if (lexeme.startsWith('"""', start)) {
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
          (lexeme.endsWith("'''") || lexeme.endsWith('"""'))) {
        end -= 3;
      } else if (start + 1 <= end &&
          (lexeme.endsWith("'") || lexeme.endsWith('"'))) {
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
  final Token superKeyword;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  @override
  final Token? period;

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
  SuperConstructorInvocationImpl({
    required this.superKeyword,
    required this.period,
    required SimpleIdentifierImpl? constructorName,
    required ArgumentListImpl argumentList,
  })  : _constructorName = constructorName,
        _argumentList = argumentList {
    _becomeParentOf(_constructorName);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => superKeyword;

  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  set constructorName(SimpleIdentifierImpl? identifier) {
    _constructorName = _becomeParentOf(identifier);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('superKeyword', superKeyword)
    ..addToken('period', period)
    ..addNode('constructorName', constructorName)
    ..addNode('argumentList', argumentList);

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
  final Token superKeyword;

  /// Initialize a newly created super expression.
  SuperExpressionImpl({
    required this.superKeyword,
  });

  @override
  Token get beginToken => superKeyword;

  @override
  Token get endToken => superKeyword;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('superKeyword', superKeyword);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSuperExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSuperExpression(this, contextType: contextType);
  }

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
  final Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  /// The token representing the 'super' keyword.
  @override
  final Token superKeyword;

  /// The token representing the period.
  @override
  final Token period;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters of the function-typed parameter, or `null` if this is not a
  /// function-typed field formal parameter.
  FormalParameterListImpl? _parameters;

  @override
  final Token? question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if there is a type.
  /// The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
  /// [period] can be `null` if the keyword 'this' was not provided.  The
  /// [parameters] can be `null` if this is not a function-typed field formal
  /// parameter.
  SuperFormalParameterImpl({
    required super.comment,
    required super.metadata,
    required super.covariantKeyword,
    required super.requiredKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required this.superKeyword,
    required this.period,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl? parameters,
    required this.question,
  })  : _type = type,
        _typeParameters = typeParameters,
        _parameters = parameters {
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
  Token get endToken {
    return question ?? _parameters?.endToken ?? name;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isExplicitlyTyped => _parameters != null || _type != null;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  Token get name => super.name!;

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('superKeyword', superKeyword)
    ..addToken('period', period)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSuperFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
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
  SwitchCaseImpl({
    required super.labels,
    required super.keyword,
    required ExpressionImpl expression,
    required super.colon,
    required super.statements,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addToken('keyword', keyword)
    ..addNode('expression', expression)
    ..addToken('colon', colon)
    ..addNodeList('statements', statements);

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
  SwitchDefaultImpl({
    required super.labels,
    required super.keyword,
    required super.colon,
    required super.statements,
  });

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addToken('keyword', keyword)
    ..addToken('colon', colon)
    ..addNodeList('statements', statements);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchDefault(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    statements.accept(visitor);
  }
}

/// A case in a switch expression.
///
///    switchExpressionCase ::=
///        [GuardedPattern] '=>' [Expression]
@experimental
class SwitchExpressionCaseImpl extends AstNodeImpl
    implements SwitchExpressionCase {
  @override
  final GuardedPatternImpl guardedPattern;

  @override
  final Token arrow;

  ExpressionImpl _expression;

  SwitchExpressionCaseImpl({
    required this.guardedPattern,
    required this.arrow,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(guardedPattern);
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => guardedPattern.beginToken;

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('guardedPattern', guardedPattern)
    ..addToken('arrow', arrow)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSwitchExpressionCase(this);

  @override
  void visitChildren(AstVisitor visitor) {
    guardedPattern.accept(visitor);
    expression.accept(visitor);
  }
}

/// A switch expression.
///
///    switchExpression ::=
///        'switch' '(' [Expression] ')' '{' [SwitchExpressionCase]
///        (',' [SwitchExpressionCase])* ','? '}'
@experimental
class SwitchExpressionImpl extends ExpressionImpl implements SwitchExpression {
  @override
  final Token switchKeyword;

  @override
  final Token leftParenthesis;

  ExpressionImpl _expression;

  @override
  final Token rightParenthesis;

  @override
  final Token leftBracket;

  @override
  final NodeListImpl<SwitchExpressionCaseImpl> cases = NodeListImpl._();

  @override
  final Token rightBracket;

  SwitchExpressionImpl({
    required this.switchKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.rightParenthesis,
    required this.leftBracket,
    required List<SwitchExpressionCaseImpl> cases,
    required this.rightBracket,
  }) : _expression = expression {
    _becomeParentOf(_expression);
    this.cases._initialize(this, cases);
  }

  @override
  Token get beginToken => switchKeyword;

  @override
  Token get endToken => rightBracket;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('switchKeyword', switchKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('cases', cases)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    staticType = resolver
        .analyzeSwitchExpression(this, expression, cases.length, contextType)
        .type;
    resolver.popRewrite();
  }

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    cases.accept(visitor);
  }
}

/// An element within a switch statement.
///
///    switchMember ::=
///        switchCase
///      | switchDefault
abstract class SwitchMemberImpl extends AstNodeImpl implements SwitchMember {
  /// The labels associated with the switch member.
  final NodeListImpl<LabelImpl> _labels = NodeListImpl._();

  /// The token representing the 'case' or 'default' keyword.
  @override
  final Token keyword;

  /// The colon separating the keyword or the expression from the statements.
  @override
  final Token colon;

  /// The statements that will be executed if this switch member is selected.
  final NodeListImpl<StatementImpl> _statements = NodeListImpl._();

  /// Initialize a newly created switch member. The list of [labels] can be
  /// `null` if there are no labels.
  SwitchMemberImpl({
    required List<LabelImpl> labels,
    required this.keyword,
    required this.colon,
    required List<StatementImpl> statements,
  }) {
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
  NodeListImpl<LabelImpl> get labels => _labels;

  @override
  NodeListImpl<StatementImpl> get statements => _statements;
}

/// A pattern-based case in a switch statement.
///
///    switchPatternCase ::=
///        [Label]* 'case' [DartPattern] [WhenClause]? ':' [Statement]*
@experimental
class SwitchPatternCaseImpl extends SwitchMemberImpl
    implements SwitchPatternCase {
  @override
  final GuardedPatternImpl guardedPattern;

  SwitchPatternCaseImpl({
    required super.labels,
    required super.keyword,
    required this.guardedPattern,
    required super.colon,
    required super.statements,
  }) {
    _becomeParentOf(guardedPattern);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNodeList('labels', labels)
    ..addToken('keyword', keyword)
    ..addNode('guardedPattern', guardedPattern)
    ..addToken('colon', colon)
    ..addNodeList('statements', statements);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchPatternCase(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    guardedPattern.accept(visitor);
    statements.accept(visitor);
  }
}

class SwitchStatementCaseGroup {
  final List<SwitchMemberImpl> members;
  final bool hasLabels;

  /// Joined variables declared in [members], available in [statements].
  late Map<String, PromotableElement> variables;

  SwitchStatementCaseGroup(this.members, this.hasLabels);

  NodeListImpl<StatementImpl> get statements {
    return members.last.statements;
  }
}

/// A switch statement.
///
///    switchStatement ::=
///        'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
class SwitchStatementImpl extends StatementImpl implements SwitchStatement {
  /// The token representing the 'switch' keyword.
  @override
  final Token switchKeyword;

  /// The left parenthesis.
  @override
  final Token leftParenthesis;

  /// The expression used to determine which of the switch members will be
  /// selected.
  ExpressionImpl _expression;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// The left curly bracket.
  @override
  final Token leftBracket;

  /// The switch members that can be selected by the expression.
  final NodeListImpl<SwitchMemberImpl> _members = NodeListImpl._();

  late final List<SwitchStatementCaseGroup> memberGroups =
      _computeMemberGroups();

  /// The right curly bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created switch statement. The list of [members] can be
  /// `null` if there are no switch members.
  SwitchStatementImpl({
    required this.switchKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.rightParenthesis,
    required this.leftBracket,
    required List<SwitchMemberImpl> members,
    required this.rightBracket,
  }) : _expression = expression {
    _becomeParentOf(_expression);
    _members._initialize(this, members);
  }

  @override
  Token get beginToken => switchKeyword;

  @override
  Token get endToken => rightBracket;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  NodeListImpl<SwitchMemberImpl> get members => _members;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('switchKeyword', switchKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
    _members.accept(visitor);
  }

  List<SwitchStatementCaseGroup> _computeMemberGroups() {
    var groups = <SwitchStatementCaseGroup>[];
    var groupMembers = <SwitchMemberImpl>[];
    var groupHasLabels = false;
    for (var member in members) {
      groupMembers.add(member);
      groupHasLabels |= member.labels.isNotEmpty;
      if (member.statements.isNotEmpty) {
        groups.add(
          SwitchStatementCaseGroup(groupMembers, groupHasLabels),
        );
        groupMembers = [];
        groupHasLabels = false;
      }
    }
    if (groupMembers.isNotEmpty) {
      groups.add(
        SwitchStatementCaseGroup(groupMembers, groupHasLabels),
      );
    }
    return groups;
  }
}

/// A symbol literal expression.
///
///    symbolLiteral ::=
///        '#' (operator | (identifier ('.' identifier)*))
class SymbolLiteralImpl extends LiteralImpl implements SymbolLiteral {
  /// The token introducing the literal.
  @override
  final Token poundSign;

  /// The components of the literal.
  @override
  final List<Token> components;

  /// Initialize a newly created symbol literal.
  SymbolLiteralImpl({
    required this.poundSign,
    required this.components,
  });

  @override
  Token get beginToken => poundSign;

  @override
  Token get endToken => components[components.length - 1];

  @override
  // TODO(paulberry): add "." tokens.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('poundSign', poundSign)
    ..addTokenList('components', components);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSymbolLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSymbolLiteral(this, contextType: contextType);
  }

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
  final Token thisKeyword;

  /// Initialize a newly created this expression.
  ThisExpressionImpl({
    required this.thisKeyword,
  });

  @override
  Token get beginToken => thisKeyword;

  @override
  Token get endToken => thisKeyword;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('thisKeyword', thisKeyword);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitThisExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitThisExpression(this, contextType: contextType);
  }

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
  final Token throwKeyword;

  /// The expression computing the exception to be thrown.
  ExpressionImpl _expression;

  /// Initialize a newly created throw expression.
  ThrowExpressionImpl({
    required this.throwKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => throwKeyword;

  @override
  Token get endToken {
    return _expression.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('throwKeyword', throwKeyword)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitThrowExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitThrowExpression(this, contextType: contextType);
  }

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
  final Token? externalKeyword;

  /// The semicolon terminating the declaration.
  @override
  final Token semicolon;

  /// Initialize a newly created top-level variable declaration. Either or both
  /// of the [comment] and [metadata] can be `null` if the variable does not
  /// have the corresponding attribute.
  TopLevelVariableDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.externalKeyword,
    required VariableDeclarationListImpl variableList,
    required this.semicolon,
  }) : _variableList = variableList {
    _becomeParentOf(_variableList);
  }

  @override
  Element? get declaredElement => null;

  @Deprecated('Use declaredElement instead')
  @override
  Element? get declaredElement2 => null;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      externalKeyword ?? _variableList.beginToken;

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationListImpl variables) {
    _variableList = _becomeParentOf(variables);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('variables', variables)
    ..addToken('semicolon', semicolon);

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
  final Token tryKeyword;

  /// The body of the statement.
  BlockImpl _body;

  /// The catch clauses contained in the try statement.
  final NodeListImpl<CatchClauseImpl> _catchClauses = NodeListImpl._();

  /// The token representing the 'finally' keyword, or `null` if the statement
  /// does not contain a finally clause.
  @override
  final Token? finallyKeyword;

  /// The finally block contained in the try statement, or `null` if the
  /// statement does not contain a finally clause.
  BlockImpl? _finallyBlock;

  /// Initialize a newly created try statement. The list of [catchClauses] can
  /// be`null` if there are no catch clauses. The [finallyKeyword] and
  /// [finallyBlock] can be `null` if there is no finally clause.
  TryStatementImpl({
    required this.tryKeyword,
    required BlockImpl body,
    required List<CatchClauseImpl> catchClauses,
    required this.finallyKeyword,
    required BlockImpl? finallyBlock,
  })  : _body = body,
        _finallyBlock = finallyBlock {
    _becomeParentOf(_body);
    _catchClauses._initialize(this, catchClauses);
    _becomeParentOf(_finallyBlock);
  }

  @override
  Token get beginToken => tryKeyword;

  @override
  BlockImpl get body => _body;

  set body(BlockImpl block) {
    _body = _becomeParentOf(block);
  }

  @override
  NodeListImpl<CatchClauseImpl> get catchClauses => _catchClauses;

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
  BlockImpl? get finallyBlock => _finallyBlock;

  set finallyBlock(BlockImpl? block) {
    _finallyBlock = _becomeParentOf(block);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('tryKeyword', tryKeyword)
    ..addNode('body', body)
    ..addNodeList('catchClauses', catchClauses)
    ..addToken('finallyKeyword', finallyKeyword)
    ..addNode('finallyBlock', finallyBlock);

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
  final Token typedefKeyword;

  /// The semicolon terminating the declaration.
  @override
  final Token semicolon;

  /// Initialize a newly created type alias. Either or both of the [comment] and
  /// [metadata] can be `null` if the declaration does not have the
  /// corresponding attribute.
  TypeAliasImpl({
    required super.comment,
    required super.metadata,
    required this.typedefKeyword,
    required super.name,
    required this.semicolon,
  });

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
  final Token leftBracket;

  /// The type arguments associated with the type.
  final NodeListImpl<TypeAnnotationImpl> _arguments = NodeListImpl._();

  /// The right bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created list of type arguments.
  TypeArgumentListImpl({
    required this.leftBracket,
    required List<TypeAnnotationImpl> arguments,
    required this.rightBracket,
  }) {
    _arguments._initialize(this, arguments);
  }

  @override
  NodeListImpl<TypeAnnotationImpl> get arguments => _arguments;

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket;

  @override
  // TODO(paulberry): Add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('arguments', arguments)
    ..addToken('rightBracket', rightBracket);

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
  TypedLiteralImpl({
    required this.constKeyword,
    required TypeArgumentListImpl? typeArguments,
  }) : _typeArguments = typeArguments {
    _becomeParentOf(_typeArguments);
  }

  @override
  bool get isConst {
    return constKeyword != null || inConstantContext;
  }

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('constKeyword', constKeyword)
    ..addNode('typeArguments', typeArguments);

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

  TypeLiteralImpl({
    required NamedTypeImpl typeName,
  }) : _typeName = typeName {
    _becomeParentOf(_typeName);
  }

  @override
  Token get beginToken => _typeName.beginToken;

  @override
  Token get endToken => _typeName.endToken;

  @override
  Precedence get precedence => _typeName.typeArguments == null
      ? _typeName.name.precedence
      : Precedence.postfix;

  @override
  NamedTypeImpl get type => _typeName;

  set typeName(NamedTypeImpl value) {
    _typeName = _becomeParentOf(value);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitTypeLiteral(this, contextType: contextType);
  }

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
  @override
  final Token name;

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

  @override
  TypeParameterElement? declaredElement;

  /// Initialize a newly created type parameter. Either or both of the [comment]
  /// and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [extendsKeyword] and [bound] can be `null` if
  /// the parameter does not have an upper bound.
  TypeParameterImpl({
    required super.comment,
    required super.metadata,
    required this.name,
    required this.extendsKeyword,
    required TypeAnnotationImpl? bound,
    this.varianceKeyword,
  }) : _bound = bound {
    _becomeParentOf(_bound);
  }

  @override
  TypeAnnotationImpl? get bound => _bound;

  set bound(TypeAnnotationImpl? type) {
    _bound = _becomeParentOf(type);
  }

  @Deprecated('Use declaredElement instead')
  @override
  TypeParameterElement? get declaredElement2 => declaredElement;

  @override
  Token get endToken {
    return _bound?.endToken ?? name;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => varianceKeyword ?? name;

  @Deprecated('Use name instead')
  @override
  Token get name2 => name;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('name', name)
    ..addToken('extendsKeyword', extendsKeyword)
    ..addNode('bound', bound);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
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
  final NodeListImpl<TypeParameterImpl> _typeParameters = NodeListImpl._();

  /// The right angle bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created list of type parameters.
  TypeParameterListImpl({
    required this.leftBracket,
    required List<TypeParameterImpl> typeParameters,
    required this.rightBracket,
  }) {
    _typeParameters._initialize(this, typeParameters);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket;

  @override
  NodeListImpl<TypeParameterImpl> get typeParameters => _typeParameters;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('typeParameters', typeParameters)
    ..addToken('rightBracket', rightBracket);

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

  /// Initialize a newly create URI-based directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  UriBasedDirectiveImpl({
    required super.comment,
    required super.metadata,
    required StringLiteralImpl uri,
  }) : _uri = uri {
    _becomeParentOf(_uri);
  }

  @override
  StringLiteralImpl get uri => _uri;

  set uri(StringLiteralImpl uri) {
    _uri = _becomeParentOf(uri);
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
  @override
  final Token name;

  @override
  VariableElement? declaredElement;

  /// The equal sign separating the variable name from the initial value, or
  /// `null` if the initial value was not specified.
  @override
  final Token? equals;

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
  VariableDeclarationImpl({
    required this.name,
    required this.equals,
    required ExpressionImpl? initializer,
  })  : _initializer = initializer,
        super(comment: null, metadata: null) {
    _becomeParentOf(_initializer);
  }

  @Deprecated('Use declaredElement instead')
  @override
  VariableElement? get declaredElement2 => declaredElement;

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
    return name;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => name;

  @override
  ExpressionImpl? get initializer => _initializer;

  set initializer(ExpressionImpl? expression) {
    _initializer = _becomeParentOf(expression);
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

  @Deprecated('Use name instead')
  @override
  Token get name2 => name;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('name', name)
    ..addToken('equals', equals)
    ..addNode('initializer', initializer);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
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
  final Token? keyword;

  /// The token representing the 'late' keyword, or `null` if the late modifier
  /// was not included.
  @override
  final Token? lateKeyword;

  /// The type of the variables being declared, or `null` if no type was
  /// provided.
  TypeAnnotationImpl? _type;

  /// A list containing the individual variables being declared.
  final NodeListImpl<VariableDeclarationImpl> _variables = NodeListImpl._();

  /// Initialize a newly created variable declaration list. Either or both of
  /// the [comment] and [metadata] can be `null` if the variable list does not
  /// have the corresponding attribute. The [keyword] can be `null` if a type
  /// was specified. The [type] must be `null` if the keyword is 'var'.
  VariableDeclarationListImpl({
    required super.comment,
    required super.metadata,
    required this.lateKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required List<VariableDeclarationImpl> variables,
  }) : _type = type {
    _becomeParentOf(_type);
    _variables._initialize(this, variables);
  }

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

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @override
  NodeListImpl<VariableDeclarationImpl> get variables => _variables;

  @override
  // TODO(paulberry): include commas.
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addNodeList('variables', variables);

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
  final Token semicolon;

  /// Initialize a newly created variable declaration statement.
  VariableDeclarationStatementImpl({
    required VariableDeclarationListImpl variableList,
    required this.semicolon,
  }) : _variableList = variableList {
    _becomeParentOf(_variableList);
  }

  @override
  Token get beginToken => _variableList.beginToken;

  @override
  Token get endToken => semicolon;

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationListImpl variables) {
    _variableList = _becomeParentOf(variables);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('variables', variables)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitVariableDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _variableList.accept(visitor);
  }
}

@experimental
abstract class VariablePatternImpl extends DartPatternImpl
    implements VariablePattern {
  @override
  final Token name;

  VariablePatternImpl({
    required this.name,
  });

  @override
  VariablePatternImpl? get variablePattern => this;
}

/// A guard in a pattern-based `case` in a `switch` statement or `switch`
/// expression.
///
///    switchCase ::=
///        'when' [Expression]
@experimental
class WhenClauseImpl extends AstNodeImpl implements WhenClause {
  ExpressionImpl _expression;

  @override
  final Token whenKeyword;

  WhenClauseImpl({
    required this.whenKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @override
  Token get beginToken => whenKeyword;

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('whenKeyword', whenKeyword)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWhenClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }
}

/// A while statement.
///
///    whileStatement ::=
///        'while' '(' [Expression] ')' [Statement]
class WhileStatementImpl extends StatementImpl implements WhileStatement {
  /// The token representing the 'while' keyword.
  @override
  final Token whileKeyword;

  /// The left parenthesis.
  @override
  final Token leftParenthesis;

  /// The expression used to determine whether to execute the body of the loop.
  ExpressionImpl _condition;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// The body of the loop.
  StatementImpl _body;

  /// Initialize a newly created while statement.
  WhileStatementImpl({
    required this.whileKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.rightParenthesis,
    required StatementImpl body,
  })  : _condition = condition,
        _body = body {
    _becomeParentOf(_condition);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken => whileKeyword;

  @override
  StatementImpl get body => _body;

  set body(StatementImpl statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('whileKeyword', whileKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWhileStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    _body.accept(visitor);
  }
}

/// A wildcard pattern.
///
///    variablePattern ::=
///        ( 'var' | 'final' | 'final'? [TypeAnnotation])? '_'
@experimental
class WildcardPatternImpl extends DartPatternImpl implements WildcardPattern {
  @override
  final Token? keyword;

  @override
  final Token name;

  @override
  final TypeAnnotationImpl? type;

  WildcardPatternImpl({
    required this.name,
    required this.keyword,
    required this.type,
  }) {
    _becomeParentOf(type);
  }

  @override
  Token get beginToken => type?.beginToken ?? name;

  @override
  Token get endToken => name;

  /// If [keyword] is `final`, returns it.
  Token? get finalKeyword {
    final keyword = this.keyword;
    if (keyword != null && keyword.keyword == Keyword.FINAL) {
      return keyword;
    }
    return null;
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWildcardPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeDeclaredVariablePatternSchema(type?.typeOrThrow);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeWildcardPattern(
      context: context,
      node: this,
      declaredType: type?.typeOrThrow,
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {
    type?.accept(visitor);
  }
}

/// The with clause in a class declaration.
///
///    withClause ::=
///        'with' [TypeName] (',' [TypeName])*
class WithClauseImpl extends AstNodeImpl implements WithClause {
  /// The token representing the 'with' keyword.
  @override
  final Token withKeyword;

  /// The names of the mixins that were specified.
  final NodeListImpl<NamedTypeImpl> _mixinTypes = NodeListImpl._();

  /// Initialize a newly created with clause.
  WithClauseImpl({
    required this.withKeyword,
    required List<NamedTypeImpl> mixinTypes,
  }) {
    _mixinTypes._initialize(this, mixinTypes);
  }

  @override
  Token get beginToken => withKeyword;

  @override
  Token get endToken => _mixinTypes.endToken ?? withKeyword;

  @override
  NodeListImpl<NamedTypeImpl> get mixinTypes => _mixinTypes;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('withKeyword', withKeyword)
    ..addNodeList('mixinTypes', mixinTypes);

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
  final Token yieldKeyword;

  /// The star optionally following the 'yield' keyword.
  @override
  final Token? star;

  /// The expression whose value will be yielded.
  ExpressionImpl _expression;

  /// The semicolon following the expression.
  @override
  final Token semicolon;

  /// Initialize a newly created yield expression. The [star] can be `null` if
  /// no star was provided.
  YieldStatementImpl({
    required this.yieldKeyword,
    required this.star,
    required ExpressionImpl expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    return yieldKeyword;
  }

  @override
  Token get endToken {
    return semicolon;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('yieldKeyword', yieldKeyword)
    ..addToken('star', star)
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitYieldStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
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
