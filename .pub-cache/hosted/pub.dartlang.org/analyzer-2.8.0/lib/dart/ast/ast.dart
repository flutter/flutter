// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the AST model. The AST (Abstract Syntax Tree) model describes the
/// syntactic (as opposed to semantic) structure of Dart code. The semantic
/// structure of the code is modeled by the
/// [element model](../dart_element_element/dart_element_element-library.html).
///
/// An AST consists of nodes (instances of a subclass of [AstNode]). The nodes
/// are organized in a tree structure in which the children of a node are the
/// smaller syntactic units from which the node is composed. For example, a
/// binary expression consists of two sub-expressions (the operands) and an
/// operator. The two expressions are represented as nodes. The operator is not
/// represented as a node.
///
/// The AST is constructed by the parser based on the sequence of tokens
/// produced by the scanner. Most nodes provide direct access to the tokens used
/// to build the node. For example, the token for the operator in a binary
/// expression can be accessed from the node representing the binary expression.
///
/// While any node can theoretically be the root of an AST structure, almost all
/// of the AST structures known to the analyzer have a [CompilationUnit] as the
/// root of the structure. A compilation unit represents all of the Dart code in
/// a single file.
///
/// An AST can be either unresolved or resolved. When an AST is unresolved
/// certain properties will not have been computed and the accessors for those
/// properties will return `null`. The documentation for those getters should
/// describe that this is a possibility.
///
/// When an AST is resolved, the identifiers in the AST will be associated with
/// the elements that they refer to and every expression in the AST will have a
/// type associated with it.
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart' show LineInfo, Source;

/// Two or more string literals that are implicitly concatenated because of
/// being adjacent (separated only by whitespace).
///
/// While the grammar only allows adjacent strings when all of the strings are
/// of the same kind (single line or multi-line), this class doesn't enforce
/// that restriction.
///
///    adjacentStrings ::=
///        [StringLiteral] [StringLiteral]+
///
/// Clients may not extend, implement or mix-in this class.
abstract class AdjacentStrings implements StringLiteral {
  /// Return the strings that are implicitly concatenated.
  NodeList<StringLiteral> get strings;
}

/// An AST node that can be annotated with both a documentation comment and a
/// list of annotations.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnnotatedNode implements AstNode {
  /// Return the documentation comment associated with this node, or `null` if
  /// this node does not have a documentation comment associated with it.
  Comment? get documentationComment;

  /// Return the first token following the comment and metadata.
  Token get firstTokenAfterCommentAndMetadata;

  /// Return the annotations associated with this node.
  NodeList<Annotation> get metadata;

  /// Return a list containing the comment and annotations associated with this
  /// node, sorted in lexical order.
  List<AstNode> get sortedCommentAndAnnotations;
}

/// An annotation that can be associated with an AST node.
///
///    metadata ::=
///        annotation*
///
///    annotation ::=
///        '@' metadatum
///
///    metadatum ::=
///        [Identifier]
///      | qualifiedName
///      | constructorDesignation argumentPart
///
/// Clients may not extend, implement or mix-in this class.
abstract class Annotation implements AstNode {
  /// Return the arguments to the constructor being invoked, or `null` if this
  /// annotation is not the invocation of a constructor.
  ArgumentList? get arguments;

  /// Return the at sign that introduced the annotation.
  Token get atSign;

  /// Return the name of the constructor being invoked, or `null` if this
  /// annotation is not the invocation of a named constructor.
  SimpleIdentifier? get constructorName;

  /// Return the element associated with this annotation, or `null` if the AST
  /// structure has not been resolved or if this annotation could not be
  /// resolved.
  Element? get element;

  /// Return the element annotation representing this annotation in the element
  /// model; `null` when the AST has not been resolved.
  ElementAnnotation? get elementAnnotation;

  /// Return the name of the class defining the constructor that is being
  /// invoked or the name of the field that is being referenced.
  Identifier get name;

  @override
  AstNode get parent;

  /// Return the period before the constructor name, or `null` if this
  /// annotation is not the invocation of a named constructor.
  Token? get period;

  /// Returns the type arguments to the constructor being invoked, or `null` if
  /// (a) this annotation is not the invocation of a constructor or (b) this
  /// annotation does not specify type arguments explicitly.
  ///
  /// Note that type arguments are only valid if [Feature.generic_metadata] is
  /// enabled.
  TypeArgumentList? get typeArguments;
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class ArgumentList implements AstNode {
  /// Return the expressions producing the values of the arguments.
  ///
  /// Although the language requires that positional arguments appear before
  /// named arguments, this class allows them to be intermixed.
  NodeList<Expression> get arguments;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

/// An as expression.
///
///    asExpression ::=
///        [Expression] 'as' [TypeAnnotation]
///
/// Clients may not extend, implement or mix-in this class.
abstract class AsExpression implements Expression {
  /// Return the 'as' operator.
  Token get asOperator;

  /// Return the expression used to compute the value being cast.
  Expression get expression;

  /// Return the type being cast to.
  TypeAnnotation get type;
}

/// An assert in the initializer list of a constructor.
///
///    assertInitializer ::=
///        'assert' '(' [Expression] (',' [Expression])? ')'
///
/// Clients may not extend, implement or mix-in this class.
abstract class AssertInitializer implements Assertion, ConstructorInitializer {}

/// An assertion, either in a block or in the initializer list of a constructor.
///
/// Clients may not extend, implement or mix-in this class.
abstract class Assertion implements AstNode {
  /// Return the token representing the 'assert' keyword.
  Token get assertKeyword;

  /// Return the comma between the [condition] and the [message], or `null` if
  /// no message was supplied.
  Token? get comma;

  /// Return the condition that is being asserted to be `true`.
  Expression get condition;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the message to report if the assertion fails, or `null` if no
  /// message was supplied.
  Expression? get message;

  ///  Return the right parenthesis.
  Token get rightParenthesis;
}

/// An assert statement.
///
///    assertStatement ::=
///        'assert' '(' [Expression] (',' [Expression])? ')' ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class AssertStatement implements Assertion, Statement {
  /// Return the semicolon terminating the statement.
  Token get semicolon;
}

/// An assignment expression.
///
///    assignmentExpression ::=
///        [Expression] operator [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class AssignmentExpression
    implements
        NullShortableExpression,
        MethodReferenceExpression,
        CompoundAssignmentExpression {
  /// Return the expression used to compute the left hand side.
  Expression get leftHandSide;

  /// Return the assignment operator being applied.
  Token get operator;

  /// Return the expression used to compute the right hand side.
  Expression get rightHandSide;
}

/// A node in the AST structure for a Dart program.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AstNode implements SyntacticEntity {
  /// A comparator that can be used to sort AST nodes in lexical order.
  ///
  /// In other words, `compare` will return a negative value if the offset of
  /// the first node is less than the offset of the second node, zero (0) if
  /// the nodes have the same offset, and a positive value if the offset of the
  /// first node is greater than the offset of the second node.
  static Comparator<AstNode> LEXICAL_ORDER =
      (AstNode first, AstNode second) => first.offset - second.offset;

  /// Return the first token included in this node's source range.
  Token get beginToken;

  /// Return an iterator that can be used to iterate through all the entities
  /// (either AST nodes or tokens) that make up the contents of this node,
  /// including doc comments but excluding other comments.
  Iterable<SyntacticEntity> get childEntities;

  /// Return the offset of the character immediately following the last
  /// character of this node's source range.
  ///
  /// This is equivalent to `node.getOffset() + node.getLength()`. For a
  /// compilation unit this will be equal to the length of the unit's source.
  /// For synthetic nodes this will be equivalent to the node's offset (because
  /// the length is zero (0) by definition).
  @override
  int get end;

  /// Return the last token included in this node's source range.
  Token get endToken;

  /// Return `true` if this node is a synthetic node.
  ///
  /// A synthetic node is a node that was introduced by the parser in order to
  /// recover from an error in the code. Synthetic nodes always have a length
  /// of zero (`0`).
  bool get isSynthetic;

  @override
  int get length;

  @override
  int get offset;

  /// Return this node's parent node, or `null` if this node is the root of an
  /// AST structure.
  ///
  /// Note that the relationship between an AST node and its parent node may
  /// change over the lifetime of a node.
  AstNode? get parent;

  /// Return the node at the root of this node's AST structure.
  ///
  /// Note that this method's performance is linear with respect to the depth
  /// of the node in the AST structure (O(depth)).
  AstNode get root;

  /// Use the given [visitor] to visit this node.
  ///
  /// Return the value returned by the visitor as a result of visiting this
  /// node.
  E? accept<E>(AstVisitor<E> visitor);

  /// Return the token before [target] or `null` if it cannot be found.
  Token? findPrevious(Token target);

  /// Return the value of the property with the given [name], or `null` if this
  /// node does not have a property with the given name.
  E? getProperty<E>(String name);

  /// Set the value of the property with the given [name] to the given [value].
  /// If the value is `null`, the property will effectively be removed.
  void setProperty(String name, Object? value);

  /// Return either this node or the most immediate ancestor of this node for
  /// which the [predicate] returns `true`, or `null` if there is no such node.
  E? thisOrAncestorMatching<E extends AstNode>(Predicate<AstNode> predicate);

  /// Return either this node or the most immediate ancestor of this node that
  /// has the given type, or `null` if there is no such node.
  E? thisOrAncestorOfType<E extends AstNode>();

  /// Return a textual description of this node in a form approximating valid
  /// source.
  ///
  /// The returned string will not be valid source primarily in the case where
  /// the node itself is not well-formed.
  String toSource();

  /// Use the given [visitor] to visit all of the children of this node.
  ///
  /// The children will be visited in lexical order.
  void visitChildren(AstVisitor visitor);
}

/// An object that can be used to visit an AST structure.
///
/// Clients may not extend, implement or mix-in this class. There are classes
/// that implement this interface that provide useful default behaviors in
/// `package:analyzer/dart/ast/visitor.dart`. A couple of the most useful
/// include
/// * SimpleAstVisitor which implements every visit method by doing nothing,
/// * RecursiveAstVisitor which will cause every node in a structure to be
///   visited, and
/// * ThrowingAstVisitor which implements every visit method by throwing an
///   exception.
abstract class AstVisitor<R> {
  R? visitAdjacentStrings(AdjacentStrings node);

  R? visitAnnotation(Annotation node);

  R? visitArgumentList(ArgumentList node);

  R? visitAsExpression(AsExpression node);

  R? visitAssertInitializer(AssertInitializer node);

  R? visitAssertStatement(AssertStatement assertStatement);

  R? visitAssignmentExpression(AssignmentExpression node);

  R? visitAwaitExpression(AwaitExpression node);

  R? visitBinaryExpression(BinaryExpression node);

  R? visitBlock(Block node);

  R? visitBlockFunctionBody(BlockFunctionBody node);

  R? visitBooleanLiteral(BooleanLiteral node);

  R? visitBreakStatement(BreakStatement node);

  R? visitCascadeExpression(CascadeExpression node);

  R? visitCatchClause(CatchClause node);

  R? visitClassDeclaration(ClassDeclaration node);

  R? visitClassTypeAlias(ClassTypeAlias node);

  R? visitComment(Comment node);

  R? visitCommentReference(CommentReference node);

  R? visitCompilationUnit(CompilationUnit node);

  R? visitConditionalExpression(ConditionalExpression node);

  R? visitConfiguration(Configuration node);

  R? visitConstructorDeclaration(ConstructorDeclaration node);

  R? visitConstructorFieldInitializer(ConstructorFieldInitializer node);

  R? visitConstructorName(ConstructorName node);

  R? visitConstructorReference(ConstructorReference node);

  R? visitContinueStatement(ContinueStatement node);

  R? visitDeclaredIdentifier(DeclaredIdentifier node);

  R? visitDefaultFormalParameter(DefaultFormalParameter node);

  R? visitDoStatement(DoStatement node);

  R? visitDottedName(DottedName node);

  R? visitDoubleLiteral(DoubleLiteral node);

  R? visitEmptyFunctionBody(EmptyFunctionBody node);

  R? visitEmptyStatement(EmptyStatement node);

  R? visitEnumConstantDeclaration(EnumConstantDeclaration node);

  R? visitEnumDeclaration(EnumDeclaration node);

  R? visitExportDirective(ExportDirective node);

  R? visitExpressionFunctionBody(ExpressionFunctionBody node);

  R? visitExpressionStatement(ExpressionStatement node);

  R? visitExtendsClause(ExtendsClause node);

  R? visitExtensionDeclaration(ExtensionDeclaration node);

  R? visitExtensionOverride(ExtensionOverride node);

  R? visitFieldDeclaration(FieldDeclaration node);

  R? visitFieldFormalParameter(FieldFormalParameter node);

  R? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node);

  R? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node);

  R? visitForElement(ForElement node);

  R? visitFormalParameterList(FormalParameterList node);

  R? visitForPartsWithDeclarations(ForPartsWithDeclarations node);

  R? visitForPartsWithExpression(ForPartsWithExpression node);

  R? visitForStatement(ForStatement node);

  R? visitFunctionDeclaration(FunctionDeclaration node);

  R? visitFunctionDeclarationStatement(FunctionDeclarationStatement node);

  R? visitFunctionExpression(FunctionExpression node);

  R? visitFunctionExpressionInvocation(FunctionExpressionInvocation node);

  R? visitFunctionReference(FunctionReference node);

  R? visitFunctionTypeAlias(FunctionTypeAlias functionTypeAlias);

  R? visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node);

  R? visitGenericFunctionType(GenericFunctionType node);

  R? visitGenericTypeAlias(GenericTypeAlias node);

  R? visitHideClause(HideClause node);

  R? visitHideCombinator(HideCombinator node);

  R? visitIfElement(IfElement node);

  R? visitIfStatement(IfStatement node);

  R? visitImplementsClause(ImplementsClause node);

  R? visitImplicitCallReference(ImplicitCallReference node);

  R? visitImportDirective(ImportDirective node);

  R? visitIndexExpression(IndexExpression node);

  R? visitInstanceCreationExpression(InstanceCreationExpression node);

  R? visitIntegerLiteral(IntegerLiteral node);

  R? visitInterpolationExpression(InterpolationExpression node);

  R? visitInterpolationString(InterpolationString node);

  R? visitIsExpression(IsExpression node);

  R? visitLabel(Label node);

  R? visitLabeledStatement(LabeledStatement node);

  R? visitLibraryDirective(LibraryDirective node);

  R? visitLibraryIdentifier(LibraryIdentifier node);

  R? visitListLiteral(ListLiteral node);

  R? visitMapLiteralEntry(MapLiteralEntry node);

  R? visitMethodDeclaration(MethodDeclaration node);

  R? visitMethodInvocation(MethodInvocation node);

  R? visitMixinDeclaration(MixinDeclaration node);

  R? visitNamedExpression(NamedExpression node);

  R? visitNamedType(NamedType node);

  R? visitNativeClause(NativeClause node);

  R? visitNativeFunctionBody(NativeFunctionBody node);

  R? visitNullLiteral(NullLiteral node);

  R? visitOnClause(OnClause node);

  R? visitParenthesizedExpression(ParenthesizedExpression node);

  R? visitPartDirective(PartDirective node);

  R? visitPartOfDirective(PartOfDirective node);

  R? visitPostfixExpression(PostfixExpression node);

  R? visitPrefixedIdentifier(PrefixedIdentifier node);

  R? visitPrefixExpression(PrefixExpression node);

  R? visitPropertyAccess(PropertyAccess node);

  R? visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node);

  R? visitRethrowExpression(RethrowExpression node);

  R? visitReturnStatement(ReturnStatement node);

  R? visitScriptTag(ScriptTag node);

  R? visitSetOrMapLiteral(SetOrMapLiteral node);

  R? visitShowClause(ShowClause node);

  R? visitShowCombinator(ShowCombinator node);

  R? visitShowHideElement(ShowHideElement node);

  R? visitSimpleFormalParameter(SimpleFormalParameter node);

  R? visitSimpleIdentifier(SimpleIdentifier node);

  R? visitSimpleStringLiteral(SimpleStringLiteral node);

  R? visitSpreadElement(SpreadElement node);

  R? visitStringInterpolation(StringInterpolation node);

  R? visitSuperConstructorInvocation(SuperConstructorInvocation node);

  R? visitSuperExpression(SuperExpression node);

  R? visitSuperFormalParameter(SuperFormalParameter node);

  R? visitSwitchCase(SwitchCase node);

  R? visitSwitchDefault(SwitchDefault node);

  R? visitSwitchStatement(SwitchStatement node);

  R? visitSymbolLiteral(SymbolLiteral node);

  R? visitThisExpression(ThisExpression node);

  R? visitThrowExpression(ThrowExpression node);

  R? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node);

  R? visitTryStatement(TryStatement node);

  R? visitTypeArgumentList(TypeArgumentList node);

  R? visitTypeLiteral(TypeLiteral node);

  @Deprecated('Override visitNamedType instead')
  R? visitTypeName(TypeName node);

  R? visitTypeParameter(TypeParameter node);

  R? visitTypeParameterList(TypeParameterList node);

  R? visitVariableDeclaration(VariableDeclaration node);

  R? visitVariableDeclarationList(VariableDeclarationList node);

  R? visitVariableDeclarationStatement(VariableDeclarationStatement node);

  R? visitWhileStatement(WhileStatement node);

  R? visitWithClause(WithClause node);

  R? visitYieldStatement(YieldStatement node);
}

/// An await expression.
///
///    awaitExpression ::=
///        'await' [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class AwaitExpression implements Expression {
  /// Return the 'await' keyword.
  Token get awaitKeyword;

  /// Return the expression whose value is being waited on.
  Expression get expression;
}

/// A binary (infix) expression.
///
///    binaryExpression ::=
///        [Expression] [Token] [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class BinaryExpression
    implements Expression, MethodReferenceExpression {
  /// Return the expression used to compute the left operand.
  Expression get leftOperand;

  /// Return the binary operator being applied.
  Token get operator;

  /// Return the expression used to compute the right operand.
  Expression get rightOperand;

  /// The function type of the invocation, or `null` if the AST structure has
  /// not been resolved, or if the invocation could not be resolved.
  FunctionType? get staticInvokeType;
}

/// A sequence of statements.
///
///    block ::=
///        '{' statement* '}'
///
/// Clients may not extend, implement or mix-in this class.
abstract class Block implements Statement {
  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the right curly bracket.
  Token get rightBracket;

  /// Return the statements contained in the block.
  NodeList<Statement> get statements;
}

/// A function body that consists of a block of statements.
///
///    blockFunctionBody ::=
///        ('async' | 'async' '*' | 'sync' '*')? [Block]
///
/// Clients may not extend, implement or mix-in this class.
abstract class BlockFunctionBody implements FunctionBody {
  /// Return the block representing the body of the function.
  Block get block;
}

/// A boolean literal expression.
///
///    booleanLiteral ::=
///        'false' | 'true'
///
/// Clients may not extend, implement or mix-in this class.
abstract class BooleanLiteral implements Literal {
  /// Return the token representing the literal.
  Token get literal;

  /// Return the value of the literal.
  bool get value;
}

/// A break statement.
///
///    breakStatement ::=
///        'break' [SimpleIdentifier]? ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class BreakStatement implements Statement {
  /// Return the token representing the 'break' keyword.
  Token get breakKeyword;

  /// Return the label associated with the statement, or `null` if there is no
  /// label.
  SimpleIdentifier? get label;

  /// Return the semicolon terminating the statement.
  Token get semicolon;

  /// Return the node from which this break statement is breaking.
  ///
  /// This will be either a [Statement] (in the case of breaking out of a
  /// loop), a [SwitchMember] (in the case of a labeled break statement whose
  /// label matches a label on a switch case in an enclosing switch statement),
  /// or `null` if the AST has not yet been resolved or if the target could not
  /// be resolved. Note that if the source code has errors, the target might be
  /// invalid (e.g. trying to break to a switch case).
  AstNode? get target;
}

/// A sequence of cascaded expressions: expressions that share a common target.
///
/// There are three kinds of expressions that can be used in a cascade
/// expression: [IndexExpression], [MethodInvocation] and [PropertyAccess].
///
///    cascadeExpression ::=
///        [Expression] cascadeSection*
///
///    cascadeSection ::=
///        ('..' | '?..') (cascadeSelector arguments*)
///        (assignableSelector arguments*)*
///        (assignmentOperator expressionWithoutCascade)?
///
///    cascadeSelector ::=
///        '[ ' expression '] '
///      | identifier
///
/// Clients may not extend, implement or mix-in this class.
abstract class CascadeExpression
    implements Expression, NullShortableExpression {
  /// Return the cascade sections sharing the common target.
  NodeList<Expression> get cascadeSections;

  /// Whether this cascade is null aware (as opposed to non-null).
  bool get isNullAware;

  /// Return the target of the cascade sections.
  Expression get target;
}

/// A catch clause within a try statement.
///
///    onPart ::=
///        catchPart [Block]
///      | 'on' type catchPart? [Block]
///
///    catchPart ::=
///        'catch' '(' [SimpleIdentifier] (',' [SimpleIdentifier])? ')'
///
/// Clients may not extend, implement or mix-in this class.
abstract class CatchClause implements AstNode {
  /// Return the body of the catch block.
  Block get body;

  /// Return the token representing the 'catch' keyword, or `null` if there is
  /// no 'catch' keyword.
  Token? get catchKeyword;

  /// Return the comma separating the exception parameter from the stack trace
  /// parameter, or `null` if there is no stack trace parameter.
  Token? get comma;

  /// Return the parameter whose value will be the exception that was thrown, or
  /// `null` if there is no 'catch' keyword.
  SimpleIdentifier? get exceptionParameter;

  /// Return the type of exceptions caught by this catch clause, or `null` if
  /// this catch clause catches every type of exception.
  TypeAnnotation? get exceptionType;

  /// Return the left parenthesis, or `null` if there is no 'catch' keyword.
  Token? get leftParenthesis;

  /// Return the token representing the 'on' keyword, or `null` if there is no
  /// 'on' keyword.
  Token? get onKeyword;

  /// Return the right parenthesis, or `null` if there is no 'catch' keyword.
  Token? get rightParenthesis;

  /// Return the parameter whose value will be the stack trace associated with
  /// the exception, or `null` if there is no stack trace parameter.
  SimpleIdentifier? get stackTraceParameter;
}

/// The declaration of a class.
///
///    classDeclaration ::=
///        'abstract'? 'class' [SimpleIdentifier] [TypeParameterList]?
///        ([ExtendsClause] [WithClause]?)?
///        [ImplementsClause]?
///        '{' [ClassMember]* '}'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassDeclaration implements ClassOrMixinDeclaration {
  /// Return the 'abstract' keyword, or `null` if the keyword was absent.
  Token? get abstractKeyword;

  /// Return the token representing the 'class' keyword.
  Token get classKeyword;

  /// Return the extends clause for this class, or `null` if the class does not
  /// extend any other class.
  ExtendsClause? get extendsClause;

  /// Return `true` if this class is declared to be an abstract class.
  bool get isAbstract;

  /// Return the native clause for this class, or `null` if the class does not
  /// have a native clause.
  NativeClause? get nativeClause;

  /// Return the with clause for the class, or `null` if the class does not have
  /// a with clause.
  WithClause? get withClause;

  /// Return the constructor declared in the class with the given [name], or
  /// `null` if there is no such constructor.
  ///
  /// If the [name] is `null` then the default constructor will be searched
  /// for.
  ConstructorDeclaration? getConstructor(String? name);
}

/// A node that declares a name within the scope of a class declarations.
///
/// When the 'extension-methods' experiment is enabled, these nodes can also be
/// located inside extension declarations.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassMember implements Declaration {}

/// The declaration of a class or mixin.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassOrMixinDeclaration implements NamedCompilationUnitMember {
  @override
  ClassElement? get declaredElement;

  /// Returns the implements clause for the class/mixin, or `null` if the
  /// class/mixin does not implement any interfaces.
  ImplementsClause? get implementsClause;

  /// Returns the left curly bracket.
  Token get leftBracket;

  /// Returns the members defined by the class/mixin.
  NodeList<ClassMember> get members;

  @override
  SimpleIdentifier get name;

  /// Returns the right curly bracket.
  Token get rightBracket;

  /// Returns the type parameters for the class/mixin, or `null` if the
  /// class/mixin does not have any type parameters.
  TypeParameterList? get typeParameters;

  /// Returns the field declared in the class/mixin with the given [name], or
  /// `null` if there is no such field.
  VariableDeclaration? getField(String name);

  /// Returns the method declared in the class/mixin with the given [name], or
  /// `null` if there is no such method.
  MethodDeclaration? getMethod(String name);
}

/// A class type alias.
///
///    classTypeAlias ::=
///        [SimpleIdentifier] [TypeParameterList]? '=' 'abstract'? mixinApplication
///
///    mixinApplication ::=
///        [TypeName] [WithClause] [ImplementsClause]? ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ClassTypeAlias implements TypeAlias {
  /// Return the token for the 'abstract' keyword, or `null` if this is not
  /// defining an abstract class.
  Token? get abstractKeyword;

  @override
  ClassElement? get declaredElement;

  /// Return the token for the '=' separating the name from the definition.
  Token get equals;

  /// Return the implements clause for this class, or `null` if there is no
  /// implements clause.
  ImplementsClause? get implementsClause;

  /// Return `true` if this class is declared to be an abstract class.
  bool get isAbstract;

  @override
  SimpleIdentifier get name;

  /// Return the name of the superclass of the class being declared.
  @Deprecated('Use superclass2 instead')
  TypeName get superclass;

  /// Return the name of the superclass of the class being declared.
  NamedType get superclass2;

  /// Return the type parameters for the class, or `null` if the class does not
  /// have any type parameters.
  TypeParameterList? get typeParameters;

  /// Return the with clause for this class.
  WithClause get withClause;
}

/// An element in a list, map or set literal.
///
///    collectionElement ::=
///        [Expression]
///      | [IfElement]
///      | [ForElement]
///      | [MapLiteralEntry]
///      | [SpreadElement]
///
/// Clients may not extend, implement or mix-in this class.
abstract class CollectionElement implements AstNode {}

/// A combinator associated with an import or export directive.
///
///    combinator ::=
///        [HideCombinator]
///      | [ShowCombinator]
///
/// Clients may not extend, implement or mix-in this class.
abstract class Combinator implements AstNode {
  /// Return the 'hide' or 'show' keyword specifying what kind of processing is
  /// to be done on the names.
  Token get keyword;
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class Comment implements AstNode {
  /// Return `true` if this is a block comment.
  bool get isBlock;

  /// Return `true` if this is a documentation comment.
  bool get isDocumentation;

  /// Return `true` if this is an end-of-line comment.
  bool get isEndOfLine;

  /// Return the references embedded within the documentation comment.
  NodeList<CommentReference> get references;

  /// Return the tokens representing the comment.
  List<Token> get tokens;
}

/// An interface for an [Expression] which can make up a [CommentReference].
///
///    commentReferableExpression ::=
///        [ConstructorReference]
///      | [FunctionReference]
///      | [PrefixedIdentifier]
///      | [PropertyAccess]
///      | [SimpleIdentifier]
///      | [TypeLiteral]
///
/// This interface should align closely with dartdoc's notion of
/// comment-referable expressions at:
/// https://github.com/dart-lang/dartdoc/blob/master/lib/src/comment_references/parser.dart
abstract class CommentReferableExpression implements Expression {}

/// A reference to a Dart element that is found within a documentation comment.
///
///    commentReference ::=
///        '[' 'new'? [CommentReferableExpression] ']'
///
/// Clients may not extend, implement or mix-in this class.
abstract class CommentReference implements AstNode {
  /// The comment-referable expression being referenced.
  CommentReferableExpression get expression;

  /// Return the identifier being referenced.
  @Deprecated('Use expression instead')
  Identifier get identifier;

  /// Return the token representing the 'new' keyword, or `null` if there was no
  /// 'new' keyword.
  Token? get newKeyword;
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class CompilationUnit implements AstNode {
  /// Return the declarations contained in this compilation unit.
  NodeList<CompilationUnitMember> get declarations;

  /// Return the element associated with this compilation unit, or `null` if the
  /// AST structure has not been resolved.
  CompilationUnitElement? get declaredElement;

  /// Return the directives contained in this compilation unit.
  NodeList<Directive> get directives;

  /// The set of features available to this compilation unit.
  ///
  /// Determined by some combination of the .packages file, the enclosing
  /// package's SDK version constraint, and/or the presence of a `@dart`
  /// directive in a comment at the top of the file.
  FeatureSet get featureSet;

  /// The language version override specified for this compilation unit using a
  /// token like '// @dart = 2.7', or `null` if no override is specified.
  LanguageVersionToken? get languageVersionToken;

  /// Return the line information for this compilation unit.
  LineInfo? get lineInfo;

  /// Return the script tag at the beginning of the compilation unit, or `null`
  /// if there is no script tag in this compilation unit.
  ScriptTag? get scriptTag;

  /// Return a list containing all of the directives and declarations in this
  /// compilation unit, sorted in lexical order.
  List<AstNode> get sortedDirectivesAndDeclarations;
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class CompilationUnitMember implements Declaration {}

/// A potentially compound assignment.
///
/// A compound assignment is any node in which a single expression is used to
/// specify both where to access a value to be operated on (the "read") and to
/// specify where to store the result of the operation (the "write"). This
/// happens in an [AssignmentExpression] when the assignment operator is a
/// compound assignment operator, and in a [PrefixExpression] or
/// [PostfixExpression] when the operator is an increment operator.
///
/// Clients may not extend, implement or mix-in this class.
abstract class CompoundAssignmentExpression implements Expression {
  /// The element that is used to read the value.
  ///
  /// If this node is not a compound assignment, this element is `null`.
  ///
  /// In valid code this element can be a [LocalVariableElement], a
  /// [ParameterElement], or a [PropertyAccessorElement] getter.
  ///
  /// In invalid code this element is `null`, for example `int += 2`. For
  /// recovery [writeElement] is filled, and can be used for navigation.
  ///
  /// This element is `null` if the AST structure has not been resolved, or
  /// if the target could not be resolved.
  Element? get readElement;

  /// The type of the value read with the [readElement].
  ///
  /// If this node is not a compound assignment, this type is `null`.
  ///
  /// In invalid code, e.g. `int += 2`, this type is `dynamic`.
  ///
  /// This type is `null` if the AST structure has not been resolved.
  ///
  /// If the target could not be resolved, this type is `dynamic`.
  DartType? get readType;

  /// The element that is used to write the result.
  ///
  /// In valid code this is a [LocalVariableElement], [ParameterElement], or a
  /// [PropertyAccessorElement] setter.
  ///
  /// In invalid code, for recovery, we might use other elements, for example a
  /// [PropertyAccessorElement] getter `myGetter = 0` even though the getter
  /// cannot be used to write a value. We do this to help the user to navigate
  /// to the getter, and maybe add the corresponding setter.
  ///
  /// If this node is a compound assignment, e. g. `x += 2`, both [readElement]
  /// and [writeElement] could be not `null`.
  ///
  /// This element is `null` if the AST structure has not been resolved, or
  /// if the target could not be resolved.
  Element? get writeElement;

  /// The types of assigned values must be subtypes of this type.
  ///
  /// If the target could not be resolved, this type is `dynamic`.
  DartType? get writeType;
}

/// A conditional expression.
///
///    conditionalExpression ::=
///        [Expression] '?' [Expression] ':' [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConditionalExpression implements Expression {
  /// Return the token used to separate the then expression from the else
  /// expression.
  Token get colon;

  /// Return the condition used to determine which of the expressions is
  /// executed next.
  Expression get condition;

  /// Return the expression that is executed if the condition evaluates to
  /// `false`.
  Expression get elseExpression;

  /// Return the token used to separate the condition from the then expression.
  Token get question;

  /// Return the expression that is executed if the condition evaluates to
  /// `true`.
  Expression get thenExpression;
}

/// A configuration in either an import or export directive.
///
///    configuration ::=
///        'if' '(' test ')' uri
///
///    test ::=
///        dottedName ('==' stringLiteral)?
///
///    dottedName ::=
///        identifier ('.' identifier)*
///
/// Clients may not extend, implement or mix-in this class.
abstract class Configuration implements AstNode {
  /// Return the token for the equal operator, or `null` if the condition does
  /// not include an equality test.
  Token? get equalToken;

  /// Return the token for the 'if' keyword.
  Token get ifKeyword;

  /// Return the token for the left parenthesis.
  Token get leftParenthesis;

  /// Return the name of the declared variable whose value is being used in the
  /// condition.
  DottedName get name;

  /// Return the token for the right parenthesis.
  Token get rightParenthesis;

  /// Return the URI of the implementation library to be used if the condition
  /// is true.
  StringLiteral get uri;

  /// Return the source to which the [uri] was resolved.
  Source? get uriSource;

  /// Return the value to which the value of the declared variable will be
  /// compared, or `null` if the condition does not include an equality test.
  StringLiteral? get value;
}

/// A constructor declaration.
///
///    constructorDeclaration ::=
///        constructorSignature [FunctionBody]?
///      | constructorName formalParameterList ':' 'this' ('.' [SimpleIdentifier])? arguments
///
///    constructorSignature ::=
///        'external'? constructorName formalParameterList initializerList?
///      | 'external'? 'factory' factoryName formalParameterList initializerList?
///      | 'external'? 'const'  constructorName formalParameterList initializerList?
///
///    constructorName ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])?
///
///    factoryName ::=
///        [Identifier] ('.' [SimpleIdentifier])?
///
///    initializerList ::=
///        ':' [ConstructorInitializer] (',' [ConstructorInitializer])*
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorDeclaration implements ClassMember {
  /// Return the body of the constructor.
  FunctionBody get body;

  /// Return the token for the 'const' keyword, or `null` if the constructor is
  /// not a const constructor.
  Token? get constKeyword;

  @override
  ConstructorElement? get declaredElement;

  /// Return the token for the 'external' keyword to the given [token].
  Token? get externalKeyword;

  /// Return the token for the 'factory' keyword, or `null` if the constructor
  /// is not a factory constructor.
  Token? get factoryKeyword;

  /// Return the initializers associated with the constructor.
  NodeList<ConstructorInitializer> get initializers;

  /// Return the name of the constructor, or `null` if the constructor being
  /// declared is unnamed.
  SimpleIdentifier? get name;

  /// Return the parameters associated with the constructor.
  FormalParameterList get parameters;

  /// Return the token for the period before the constructor name, or `null` if
  /// the constructor being declared is unnamed.
  Token? get period;

  /// Return the name of the constructor to which this constructor will be
  /// redirected, or `null` if this is not a redirecting factory constructor.
  ConstructorName? get redirectedConstructor;

  /// Return the type of object being created.
  ///
  /// This can be different than the type in which the constructor is being
  /// declared if the constructor is the implementation of a factory
  /// constructor.
  Identifier get returnType;

  /// Return the token for the separator (colon or equals) before the
  /// initializer list or redirection, or `null` if there are no initializers.
  Token? get separator;
}

/// The initialization of a field within a constructor's initialization list.
///
///    fieldInitializer ::=
///        ('this' '.')? [SimpleIdentifier] '=' [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorFieldInitializer implements ConstructorInitializer {
  /// Return the token for the equal sign between the field name and the
  /// expression.
  Token get equals;

  /// Return the expression computing the value to which the field will be
  /// initialized.
  Expression get expression;

  /// Return the name of the field being initialized.
  SimpleIdentifier get fieldName;

  /// Return the token for the period after the 'this' keyword, or `null` if
  /// there is no 'this' keyword.
  Token? get period;

  /// Return the token for the 'this' keyword, or `null` if there is no 'this'
  /// keyword.
  Token? get thisKeyword;
}

/// A node that can occur in the initializer list of a constructor declaration.
///
///    constructorInitializer ::=
///        [SuperConstructorInvocation]
///      | [ConstructorFieldInitializer]
///      | [RedirectingConstructorInvocation]
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorInitializer implements AstNode {}

/// The name of a constructor.
///
///    constructorName ::=
///        type ('.' identifier)?
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorName implements AstNode, ConstructorReferenceNode {
  /// Return the name of the constructor, or `null` if the specified constructor
  /// is the unnamed constructor.
  SimpleIdentifier? get name;

  /// Return the token for the period before the constructor name, or `null` if
  /// the specified constructor is the unnamed constructor.
  Token? get period;

  /// Return the name of the type defining the constructor.
  @Deprecated('Use type2 instead')
  TypeName get type;

  /// Return the name of the type defining the constructor.
  NamedType get type2;
}

/// An expression representing a reference to a constructor, e.g. the expression
/// `List.filled` in `var x = List.filled;`.
///
/// Objects of this type are not produced directly by the parser (because the
/// parser cannot tell whether an identifier refers to a type); they are
/// produced at resolution time.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorReference
    implements Expression, CommentReferableExpression {
  /// The constructor being referenced.
  ConstructorName get constructorName;
}

/// An AST node that makes reference to a constructor.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ConstructorReferenceNode implements AstNode {
  /// Return the element associated with the referenced constructor based on
  /// static type information, or `null` if the AST structure has not been
  /// resolved or if the constructor could not be resolved.
  ConstructorElement? get staticElement;
}

/// A continue statement.
///
///    continueStatement ::=
///        'continue' [SimpleIdentifier]? ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ContinueStatement implements Statement {
  /// Return the token representing the 'continue' keyword.
  Token get continueKeyword;

  /// Return the label associated with the statement, or `null` if there is no
  /// label.
  SimpleIdentifier? get label;

  /// Return the semicolon terminating the statement.
  Token get semicolon;

  /// Return the node to which this continue statement is continuing.
  ///
  /// This will be either a [Statement] (in the case of continuing a loop), a
  /// [SwitchMember] (in the case of continuing from one switch case to
  /// another), or `null` if the AST has not yet been resolved or if the target
  /// could not be resolved. Note that if the source code has errors, the
  /// target might be invalid (e.g. the target may be in an enclosing
  /// function).
  AstNode? get target;
}

/// A node that represents the declaration of one or more names.
///
/// Each declared name is visible within a name scope.
///
/// Clients may not extend, implement or mix-in this class.
abstract class Declaration implements AnnotatedNode {
  /// Return the element associated with this declaration, or `null` if either
  /// this node corresponds to a list of declarations or if the AST structure
  /// has not been resolved.
  Element? get declaredElement;
}

/// The declaration of a single identifier.
///
///    declaredIdentifier ::=
///        [Annotation] finalConstVarOrType [SimpleIdentifier]
///
/// Clients may not extend, implement or mix-in this class.
abstract class DeclaredIdentifier implements Declaration {
  @override
  LocalVariableElement? get declaredElement;

  /// Return the name of the variable being declared.
  SimpleIdentifier get identifier;

  /// Return `true` if this variable was declared with the 'const' modifier.
  bool get isConst;

  /// Return `true` if this variable was declared with the 'final' modifier.
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  bool get isFinal;

  /// Return the token representing either the 'final', 'const' or 'var'
  /// keyword, or `null` if no keyword was used.
  Token? get keyword;

  /// Return the name of the declared type of the parameter, or `null` if the
  /// parameter does not have a declared type.
  TypeAnnotation? get type;
}

/// A formal parameter with a default value.
///
/// There are two kinds of parameters that are both represented by this class:
/// named formal parameters and positional formal parameters.
///
///    defaultFormalParameter ::=
///        [NormalFormalParameter] ('=' [Expression])?
///
///    defaultNamedParameter ::=
///        [NormalFormalParameter] (':' [Expression])?
///
/// Clients may not extend, implement or mix-in this class.
abstract class DefaultFormalParameter implements FormalParameter {
  /// Return the expression computing the default value for the parameter, or
  /// `null` if there is no default value.
  Expression? get defaultValue;

  /// Return the formal parameter with which the default value is associated.
  NormalFormalParameter get parameter;

  /// Return the token separating the parameter from the default value, or
  /// `null` if there is no default value.
  Token? get separator;
}

/// A node that represents a directive.
///
///    directive ::=
///        [ExportDirective]
///      | [ImportDirective]
///      | [LibraryDirective]
///      | [PartDirective]
///      | [PartOfDirective]
///
/// Clients may not extend, implement or mix-in this class.
abstract class Directive implements AnnotatedNode {
  /// Return the element associated with this directive, or `null` if the AST
  /// structure has not been resolved or if this directive could not be
  /// resolved.
  Element? get element;

  /// Return the token representing the keyword that introduces this directive
  /// ('import', 'export', 'library' or 'part').
  Token get keyword;
}

/// A do statement.
///
///    doStatement ::=
///        'do' [Statement] 'while' '(' [Expression] ')' ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class DoStatement implements Statement {
  /// Return the body of the loop.
  Statement get body;

  /// Return the condition that determines when the loop will terminate.
  Expression get condition;

  /// Return the token representing the 'do' keyword.
  Token get doKeyword;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the semicolon terminating the statement.
  Token get semicolon;

  /// Return the token representing the 'while' keyword.
  Token get whileKeyword;
}

/// A dotted name, used in a configuration within an import or export directive.
///
///    dottedName ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
///
/// Clients may not extend, implement or mix-in this class.
abstract class DottedName implements AstNode {
  /// Return the components of the identifier.
  NodeList<SimpleIdentifier> get components;
}

/// A floating point literal expression.
///
///    doubleLiteral ::=
///        decimalDigit+ ('.' decimalDigit*)? exponent?
///      | '.' decimalDigit+ exponent?
///
///    exponent ::=
///        ('e' | 'E') ('+' | '-')? decimalDigit+
///
/// Clients may not extend, implement or mix-in this class.
abstract class DoubleLiteral implements Literal {
  /// Return the token representing the literal.
  Token get literal;

  /// Return the value of the literal.
  double get value;
}

/// An empty function body, which can only appear in constructors or abstract
/// methods.
///
///    emptyFunctionBody ::=
///        ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class EmptyFunctionBody implements FunctionBody {
  /// Return the token representing the semicolon that marks the end of the
  /// function body.
  Token get semicolon;
}

/// An empty statement.
///
///    emptyStatement ::=
///        ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class EmptyStatement implements Statement {
  /// Return the semicolon terminating the statement.
  Token get semicolon;
}

/// The declaration of an enum constant.
///
/// Clients may not extend, implement or mix-in this class.
abstract class EnumConstantDeclaration implements Declaration {
  /// Return the name of the constant.
  SimpleIdentifier get name;
}

/// The declaration of an enumeration.
///
///    enumType ::=
///        metadata 'enum' [SimpleIdentifier] '{' [SimpleIdentifier] (',' [SimpleIdentifier])* (',')? '}'
///
/// Clients may not extend, implement or mix-in this class.
abstract class EnumDeclaration implements NamedCompilationUnitMember {
  /// Return the enumeration constants being declared.
  NodeList<EnumConstantDeclaration> get constants;

  @override
  ClassElement? get declaredElement;

  /// Return the 'enum' keyword.
  Token get enumKeyword;

  /// Return the left curly bracket.
  Token get leftBracket;

  @override
  SimpleIdentifier get name;

  /// Return the right curly bracket.
  Token get rightBracket;
}

/// An export directive.
///
///    exportDirective ::=
///        [Annotation] 'export' [StringLiteral] [Combinator]* ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExportDirective implements NamespaceDirective {
  @override
  ExportElement? get element;
}

/// A node that represents an expression.
///
///    expression ::=
///        [AssignmentExpression]
///      | [ConditionalExpression] cascadeSection*
///      | [ThrowExpression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class Expression implements CollectionElement {
  /// An expression _e_ is said to _occur in a constant context_,
  /// * if _e_ is an element of a constant list literal, or a key or value of an
  ///   entry of a constant map literal.
  /// * if _e_ is an actual argument of a constant object expression or of a
  ///   metadata annotation.
  /// * if _e_ is the initializing expression of a constant variable
  ///   declaration.
  /// * if _e_ is a switch case expression.
  /// * if _e_ is an immediate subexpression of an expression _e1_ which occurs
  ///   in a constant context, unless _e1_ is a `throw` expression or a function
  ///   literal.
  ///
  /// This roughly means that everything which is inside a syntactically
  /// constant expression is in a constant context. A `throw` expression is
  /// currently not allowed in a constant expression, but extensions affecting
  /// that status may be considered. A similar situation arises for function
  /// literals.
  ///
  /// Note that the default value of an optional formal parameter is _not_ a
  /// constant context. This choice reserves some freedom to modify the
  /// semantics of default values.
  bool get inConstantContext;

  /// Return `true` if this expression is syntactically valid for the LHS of an
  /// [AssignmentExpression].
  bool get isAssignable;

  /// Return the precedence of this expression.
  ///
  /// The precedence is a positive integer value that defines how the source
  /// code is parsed into an AST. For example `a * b + c` is parsed as `(a * b)
  /// + c` because the precedence of `*` is greater than the precedence of `+`.
  Precedence get precedence;

  /// If this expression is an argument to an invocation, and the AST structure
  /// has been resolved, and the function being invoked is known based on static
  /// type information, and this expression corresponds to one of the parameters
  /// of the function being invoked, then return the parameter element
  /// representing the parameter to which the value of this expression will be
  /// bound. Otherwise, return `null`.
  ParameterElement? get staticParameterElement;

  /// Return the static type of this expression, or `null` if the AST structure
  /// has not been resolved.
  DartType? get staticType;

  /// If this expression is a parenthesized expression, return the result of
  /// unwrapping the expression inside the parentheses. Otherwise, return this
  /// expression.
  Expression get unParenthesized;
}

/// A function body consisting of a single expression.
///
///    expressionFunctionBody ::=
///        'async'? '=>' [Expression] ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExpressionFunctionBody implements FunctionBody {
  /// Return the expression representing the body of the function.
  Expression get expression;

  /// Return the token introducing the expression that represents the body of the
  /// function.
  Token get functionDefinition;

  /// Return the semicolon terminating the statement.
  Token? get semicolon;
}

/// An expression used as a statement.
///
///    expressionStatement ::=
///        [Expression]? ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExpressionStatement implements Statement {
  /// Return the expression that comprises the statement.
  Expression get expression;

  /// Return the semicolon terminating the statement, or `null` if the
  /// expression is a function expression and therefore isn't followed by a
  /// semicolon.
  Token? get semicolon;
}

/// The "extends" clause in a class declaration.
///
///    extendsClause ::=
///        'extends' [TypeName]
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExtendsClause implements AstNode {
  /// Return the token representing the 'extends' keyword.
  Token get extendsKeyword;

  /// Return the name of the class that is being extended.
  @Deprecated('Use superclass2 instead')
  TypeName get superclass;

  /// Return the name of the class that is being extended.
  NamedType get superclass2;
}

/// The declaration of an extension of a type.
///
///    extension ::=
///        'extension' [SimpleIdentifier]? [TypeParameterList]?
///        'on' [TypeAnnotation] [ShowClause]? [HideClause]?
///        '{' [ClassMember]* '}'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExtensionDeclaration implements CompilationUnitMember {
  @override
  ExtensionElement? get declaredElement;

  /// Return the type that is being extended.
  TypeAnnotation get extendedType;

  /// Return the token representing the 'extension' keyword.
  Token get extensionKeyword;

  /// Return the hide clause, or `null` if the extension does not have a hide
  /// clause.
  HideClause? get hideClause;

  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the members being added to the extended class.
  NodeList<ClassMember> get members;

  /// Return the name of the extension, or `null` if the extension does not have
  /// a name.
  SimpleIdentifier? get name;

  /// Return the token representing the 'on' keyword.
  Token get onKeyword;

  /// Return the right curly bracket.
  Token get rightBracket;

  /// Return the show clause, or `null` if the extension does not have a show
  /// clause.
  ShowClause? get showClause;

  /// Return the token representing the 'type' keyword.
  Token? get typeKeyword;

  /// Return the type parameters for the extension, or `null` if the extension
  /// does not have any type parameters.
  TypeParameterList? get typeParameters;
}

/// An override to force resolution to choose a member from a specific
/// extension.
///
///    extensionOverride ::=
///        [Identifier] [TypeArgumentList]? [ArgumentList]
///
/// Clients may not extend, implement or mix-in this class.
abstract class ExtensionOverride implements Expression {
  /// Return the list of arguments to the override. In valid code this will
  /// contain a single argument, which evaluates to the object being extended.
  ArgumentList get argumentList;

  /// Return the actual type extended by this override, produced by applying
  /// [typeArgumentTypes] to the generic type extended by the extension.
  ///
  /// Return `null` if the AST structure has not been resolved.
  DartType? get extendedType;

  /// Return the name of the extension being selected.
  Identifier get extensionName;

  /// Whether this override is null aware (as opposed to non-null).
  bool get isNullAware;

  /// Return the forced extension element.
  ///
  /// Return `null` if the AST structure has not been resolved.
  ExtensionElement? get staticElement;

  /// Return the type arguments to be applied to the extension, or `null` if no
  /// type arguments were provided.
  TypeArgumentList? get typeArguments;

  /// Return the actual type arguments to be applied to the extension, either
  /// explicitly specified in [typeArguments], or inferred.
  ///
  /// If the AST has been resolved, never returns `null`, returns an empty list
  /// if the extension does not have type parameters.
  ///
  /// Return `null` if the AST structure has not been resolved.
  List<DartType>? get typeArgumentTypes;
}

/// The declaration of one or more fields of the same type.
///
///    fieldDeclaration ::=
///        'static' 'const' <type>? <staticFinalDeclarationList>
///      | 'static' 'final' <type>? <staticFinalDeclarationList>
///      | 'static' 'late' 'final' <type>? <initializedIdentifierList>
///      | 'static' 'late'? <varOrType> <initializedIdentifierList>
///      | 'covariant' 'late'? <varOrType> <initializedIdentifierList>
///      | 'late'? 'final' <type>? <initializedIdentifierList>
///      | 'late'? <varOrType> <initializedIdentifierList>
///      | 'external' ('static'? <finalVarOrType> | 'covariant' <varOrType>)
///            <identifierList>
///      | 'abstract' (<finalVarOrType> | 'covariant' <varOrType>)
///            <identifierList>
///
/// (Note: there is no <fieldDeclaration> production in the grammar; this is a
/// subset of the grammar production <declaration>, which encompasses everything
/// that can appear inside a class declaration except methods).
///
/// Prior to the 'extension-methods' experiment, these nodes were always
/// children of a class declaration. When the experiment is enabled, these nodes
/// can also be children of an extension declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FieldDeclaration implements ClassMember {
  /// The `abstract` keyword, or `null` if the keyword was not used.
  Token? get abstractKeyword;

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  Token? get covariantKeyword;

  /// The `external` keyword, or `null` if the keyword was not used.
  Token? get externalKeyword;

  /// Return the fields being declared.
  VariableDeclarationList get fields;

  /// Return `true` if the fields are declared to be static.
  bool get isStatic;

  /// Return the semicolon terminating the declaration.
  Token get semicolon;

  /// Return the token representing the 'static' keyword, or `null` if the
  /// fields are not static.
  Token? get staticKeyword;
}

/// A field formal parameter.
///
///    fieldFormalParameter ::=
///        ('final' [TypeAnnotation] | 'const' [TypeAnnotation] | 'var' | [TypeAnnotation])?
///        'this' '.' [SimpleIdentifier] ([TypeParameterList]? [FormalParameterList])?
///
/// Clients may not extend, implement or mix-in this class.
abstract class FieldFormalParameter implements NormalFormalParameter {
  @override
  SimpleIdentifier get identifier;

  /// Return the token representing either the 'final', 'const' or 'var'
  /// keyword, or `null` if no keyword was used.
  Token? get keyword;

  /// Return the parameters of the function-typed parameter, or `null` if this
  /// is not a function-typed field formal parameter.
  FormalParameterList? get parameters;

  /// Return the token representing the period.
  Token get period;

  /// If the parameter is function-typed, and has the question mark, then its
  /// function type is nullable. Having a nullable function type means that the
  /// parameter can be null.
  Token? get question;

  /// Return the token representing the 'this' keyword.
  Token get thisKeyword;

  /// Return the declared type of the parameter, or `null` if the parameter does
  /// not have a declared type.
  ///
  /// Note that if this is a function-typed field formal parameter this is the
  /// return type of the function.
  TypeAnnotation? get type;

  /// Return the type parameters associated with this method, or `null` if this
  /// method is not a generic method.
  TypeParameterList? get typeParameters;
}

/// The parts of a for-each loop that control the iteration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ForEachParts implements ForLoopParts {
  /// Return the token representing the 'in' keyword.
  Token get inKeyword;

  /// Return the expression evaluated to produce the iterator.
  Expression get iterable;
}

/// The parts of a for-each loop that control the iteration when the loop
/// variable is declared as part of the for loop.
///
///   forLoopParts ::=
///       [DeclaredIdentifier] 'in' [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class ForEachPartsWithDeclaration implements ForEachParts {
  /// Return the declaration of the loop variable.
  DeclaredIdentifier get loopVariable;
}

/// The parts of a for-each loop that control the iteration when the loop
/// variable is declared outside of the for loop.
///
///   forLoopParts ::=
///       [SimpleIdentifier] 'in' [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class ForEachPartsWithIdentifier implements ForEachParts {
  /// Return the loop variable.
  SimpleIdentifier get identifier;
}

/// The basic structure of a for element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ForElement implements CollectionElement {
  /// Return the token representing the 'await' keyword, or `null` if there was
  /// no 'await' keyword.
  Token? get awaitKeyword;

  /// Return the body of the loop.
  CollectionElement get body;

  /// Return the token representing the 'for' keyword.
  Token get forKeyword;

  /// Return the parts of the for element that control the iteration.
  ForLoopParts get forLoopParts;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

/// The parts of a for or for-each loop that control the iteration.
///
///   forLoopParts ::=
///       [VariableDeclaration] ';' [Expression]? ';' expressionList?
///     | [Expression]? ';' [Expression]? ';' expressionList?
///     | [DeclaredIdentifier] 'in' [Expression]
///     | [SimpleIdentifier] 'in' [Expression]
///
///   expressionList ::=
///       [Expression] (',' [Expression])*
///
/// Clients may not extend, implement or mix-in this class.
abstract class ForLoopParts implements AstNode {}

/// A node representing a parameter to a function.
///
///    formalParameter ::=
///        [NormalFormalParameter]
///      | [DefaultFormalParameter]
///
/// Clients may not extend, implement or mix-in this class.
abstract class FormalParameter implements AstNode {
  /// The 'covariant' keyword, or `null` if the keyword was not used.
  Token? get covariantKeyword;

  /// Return the element representing this parameter, or `null` if this
  /// parameter has not been resolved.
  ParameterElement? get declaredElement;

  /// Return the name of the parameter being declared, or `null` if the
  /// parameter doesn't have a name, such as when it's part of a generic
  /// function type.
  SimpleIdentifier? get identifier;

  /// Return `true` if this parameter was declared with the 'const' modifier.
  bool get isConst;

  /// Return `true` if this parameter was declared with the 'final' modifier.
  ///
  /// Parameters that are declared with the 'const' modifier will return
  /// `false` even though they are implicitly final.
  bool get isFinal;

  /// Return `true` if this parameter is a named parameter.
  ///
  /// Named parameters can either be required or optional.
  bool get isNamed;

  /// Return `true` if this parameter is an optional parameter.
  ///
  /// Optional parameters can either be positional or named.
  bool get isOptional;

  /// Return `true` if this parameter is both an optional and named parameter.
  bool get isOptionalNamed;

  /// Return `true` if this parameter is both an optional and positional
  /// parameter.
  bool get isOptionalPositional;

  /// Return `true` if this parameter is a positional parameter.
  ///
  /// Positional parameters can either be required or optional.
  bool get isPositional;

  /// Return `true` if this parameter is a required parameter.
  ///
  /// Required parameters can either be positional or named.
  ///
  /// Note: this will return `false` for a named parameter that is annotated
  /// with the `@required` annotation.
  bool get isRequired;

  /// Return `true` if this parameter is both a required and named parameter.
  ///
  /// Note: this will return `false` for a named parameter that is annotated
  /// with the `@required` annotation.
  bool get isRequiredNamed;

  /// Return `true` if this parameter is both a required and positional
  /// parameter.
  bool get isRequiredPositional;

  /// Return the annotations associated with this parameter.
  NodeList<Annotation> get metadata;

  /// The 'required' keyword, or `null` if the keyword was not used.
  Token? get requiredKeyword;
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class FormalParameterList implements AstNode {
  /// Return the left square bracket ('[') or left curly brace ('{') introducing
  /// the optional parameters, or `null` if there are no optional parameters.
  Token? get leftDelimiter;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return a list containing the elements representing the parameters in this
  /// list.
  ///
  /// The list will contain `null`s if the parameters in this list have not
  /// been resolved.
  List<ParameterElement?> get parameterElements;

  /// Return the parameters associated with the method.
  NodeList<FormalParameter> get parameters;

  /// Return the right square bracket (']') or right curly brace ('}')
  /// terminating the optional parameters, or `null` if there are no optional
  /// parameters.
  Token? get rightDelimiter;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

/// The parts of a for loop that control the iteration.
///
///   forLoopParts ::=
///       [VariableDeclaration] ';' [Expression]? ';' expressionList?
///     | [Expression]? ';' [Expression]? ';' expressionList?
///
/// Clients may not extend, implement or mix-in this class.
abstract class ForParts implements ForLoopParts {
  /// Return the condition used to determine when to terminate the loop, or
  /// `null` if there is no condition.
  Expression? get condition;

  /// Return the semicolon separating the initializer and the condition.
  Token get leftSeparator;

  /// Return the semicolon separating the condition and the updater.
  Token get rightSeparator;

  /// Return the list of expressions run after each execution of the loop body.
  NodeList<Expression> get updaters;
}

/// The parts of a for loop that control the iteration when there are one or
/// more variable declarations as part of the for loop.
///
///   forLoopParts ::=
///       [VariableDeclarationList] ';' [Expression]? ';' expressionList?
///
/// Clients may not extend, implement or mix-in this class.
abstract class ForPartsWithDeclarations implements ForParts {
  /// Return the declaration of the loop variables.
  VariableDeclarationList get variables;
}

/// The parts of a for loop that control the iteration when there are no
/// variable declarations as part of the for loop.
///
///   forLoopParts ::=
///       [Expression]? ';' [Expression]? ';' expressionList?
///
/// Clients may not extend, implement or mix-in this class.
abstract class ForPartsWithExpression implements ForParts {
  /// Return the initialization expression, or `null` if there is no
  /// initialization expression.
  Expression? get initialization;
}

/// A for or for-each statement.
///
///    forStatement ::=
///        'for' '(' forLoopParts ')' [Statement]
///
///    forLoopParts ::=
///       [VariableDeclaration] ';' [Expression]? ';' expressionList?
///     | [Expression]? ';' [Expression]? ';' expressionList?
///     | [DeclaredIdentifier] 'in' [Expression]
///     | [SimpleIdentifier] 'in' [Expression]
///
/// This is the class that is used to represent a for loop when either the
/// 'control-flow-collections' or 'spread-collections' experiments are enabled.
/// If neither of those experiments are enabled, then either `ForStatement` or
/// `ForEachStatement` will be used.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ForStatement implements Statement {
  /// Return the token representing the 'await' keyword, or `null` if there is
  /// no 'await' keyword.
  Token? get awaitKeyword;

  /// Return the body of the loop.
  Statement get body;

  /// Return the token representing the 'for' keyword.
  Token get forKeyword;

  /// Return the parts of the for element that control the iteration.
  ForLoopParts get forLoopParts;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

/// A node representing the body of a function or method.
///
///    functionBody ::=
///        [BlockFunctionBody]
///      | [EmptyFunctionBody]
///      | [ExpressionFunctionBody]
///      | [NativeFunctionBody]
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionBody implements AstNode {
  /// Return `true` if this function body is asynchronous.
  bool get isAsynchronous;

  /// Return `true` if this function body is a generator.
  bool get isGenerator;

  /// Return `true` if this function body is synchronous.
  bool get isSynchronous;

  /// Return the token representing the 'async' or 'sync' keyword, or `null` if
  /// there is no such keyword.
  Token? get keyword;

  /// Return the star following the 'async' or 'sync' keyword, or `null` if
  /// there is no star.
  Token? get star;

  /// If [variable] is a local variable or parameter declared anywhere within
  /// the top level function or method containing this [FunctionBody], return a
  /// boolean indicating whether [variable] is potentially mutated within a
  /// local function other than the function in which it is declared.
  ///
  /// If [variable] is not a local variable or parameter declared within the top
  /// level function or method containing this [FunctionBody], return `false`.
  ///
  /// Throws an exception if resolution has not yet been performed.
  bool isPotentiallyMutatedInClosure(VariableElement variable);

  /// If [variable] is a local variable or parameter declared anywhere within
  /// the top level function or method containing this [FunctionBody], return a
  /// boolean indicating whether [variable] is potentially mutated within the
  /// scope of its declaration.
  ///
  /// If [variable] is not a local variable or parameter declared within the top
  /// level function or method containing this [FunctionBody], return `false`.
  ///
  /// Throws an exception if resolution has not yet been performed.
  bool isPotentiallyMutatedInScope(VariableElement variable);
}

/// A top-level function declaration.
///
///    functionDeclaration ::=
///        'external' functionSignature
///      | functionSignature [FunctionBody]
///
///    functionSignature ::=
///        [Type]? ('get' | 'set')? [SimpleIdentifier] [FormalParameterList]
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionDeclaration implements NamedCompilationUnitMember {
  @override
  ExecutableElement? get declaredElement;

  /// Return the token representing the 'external' keyword, or `null` if this is
  /// not an external function.
  Token? get externalKeyword;

  /// Return the function expression being wrapped.
  FunctionExpression get functionExpression;

  /// Return `true` if this function declares a getter.
  bool get isGetter;

  /// Return `true` if this function declares a setter.
  bool get isSetter;

  @override
  SimpleIdentifier get name;

  /// Return the token representing the 'get' or 'set' keyword, or `null` if
  /// this is a function declaration rather than a property declaration.
  Token? get propertyKeyword;

  /// Return the return type of the function, or `null` if no return type was
  /// declared.
  TypeAnnotation? get returnType;
}

/// A [FunctionDeclaration] used as a statement.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionDeclarationStatement implements Statement {
  /// Return the function declaration being wrapped.
  FunctionDeclaration get functionDeclaration;
}

/// A function expression.
///
///    functionExpression ::=
///        [TypeParameterList]? [FormalParameterList] [FunctionBody]
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionExpression implements Expression {
  /// Return the body of the function.
  FunctionBody get body;

  /// Return the element associated with the function, or `null` if the AST
  /// structure has not been resolved.
  ExecutableElement? get declaredElement;

  /// Return the parameters associated with the function, or `null` if the
  /// function is part of a top-level getter.
  FormalParameterList? get parameters;

  /// Return the type parameters associated with this method, or `null` if this
  /// method is not a generic method.
  TypeParameterList? get typeParameters;
}

/// The invocation of a function resulting from evaluating an expression.
///
/// Invocations of methods and other forms of functions are represented by
/// [MethodInvocation] nodes. Invocations of getters and setters are represented
/// by either [PrefixedIdentifier] or [PropertyAccess] nodes.
///
///    functionExpressionInvocation ::=
///        [Expression] [TypeArgumentList]? [ArgumentList]
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionExpressionInvocation
    implements NullShortableExpression, InvocationExpression {
  /// Return the expression producing the function being invoked.
  @override
  Expression get function;

  /// Return the element associated with the function being invoked based on
  /// static type information, or `null` if the AST structure has not been
  /// resolved or the function could not be resolved.
  ExecutableElement? get staticElement;
}

/// An expression representing a reference to a function, possibly with type
/// arguments applied to it, e.g. the expression `print` in `var x = print;`.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionReference
    implements Expression, CommentReferableExpression {
  /// The function being referenced.
  ///
  /// In error-free code, this will be either a SimpleIdentifier (indicating a
  /// function that is in scope), a PrefixedIdentifier (indicating a either
  /// function imported via prefix or a static method in a class), or a
  /// PropertyAccess (indicating a static method in a class imported via
  /// prefix).  In code with errors, this could be other kinds of expressions
  /// (e.g. `(...)<int>` parses as a FunctionReference whose referent is a
  /// ParenthesizedExpression.
  Expression get function;

  /// The type arguments being applied to the function, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;

  /// The actual type arguments being applied to the function, either explicitly
  /// specified in [typeArguments], or inferred.
  ///
  /// If the AST has been resolved, never returns `null`, returns an empty list
  /// if the function does not have type parameters.
  ///
  /// Returns `null` if the AST structure has not been resolved.
  List<DartType>? get typeArgumentTypes;
}

/// A function type alias.
///
///    functionTypeAlias ::=
///        functionPrefix [TypeParameterList]? [FormalParameterList] ';'
///
///    functionPrefix ::=
///        [TypeAnnotation]? [SimpleIdentifier]
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypeAlias implements TypeAlias {
  @override
  TypeAliasElement? get declaredElement;

  /// Return the parameters associated with the function type.
  FormalParameterList get parameters;

  /// Return the return type of the function type being defined, or `null` if no
  /// return type was given.
  TypeAnnotation? get returnType;

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  TypeParameterList? get typeParameters;
}

/// A function-typed formal parameter.
///
///    functionSignature ::=
///        [TypeAnnotation]? [SimpleIdentifier] [TypeParameterList]?
///        [FormalParameterList] '?'?
///
/// Clients may not extend, implement or mix-in this class.
abstract class FunctionTypedFormalParameter implements NormalFormalParameter {
  @override
  SimpleIdentifier get identifier;

  /// Return the parameters of the function-typed parameter.
  FormalParameterList get parameters;

  /// Return the question mark indicating that the function type is nullable, or
  /// `null` if there is no question mark. Having a nullable function type means
  /// that the parameter can be null.
  Token? get question;

  /// Return the return type of the function, or `null` if the function does not
  /// have a return type.
  TypeAnnotation? get returnType;

  /// Return the type parameters associated with this function, or `null` if
  /// this function is not a generic function.
  TypeParameterList? get typeParameters;
}

/// An anonymous function type.
///
///    functionType ::=
///        [TypeAnnotation]? 'Function' [TypeParameterList]?
///        [FormalParameterList] '?'?
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class GenericFunctionType implements TypeAnnotation {
  /// Return the keyword 'Function'.
  Token get functionKeyword;

  /// Return the parameters associated with the function type.
  FormalParameterList get parameters;

  /// Return the return type of the function type being defined, or `null` if
  /// no return type was given.
  TypeAnnotation? get returnType;

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  TypeParameterList? get typeParameters;
}

/// A generic type alias.
///
///    functionTypeAlias ::=
///        metadata 'typedef' [SimpleIdentifier] [TypeParameterList]? = [FunctionType] ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class GenericTypeAlias implements TypeAlias {
  /// Return the equal sign separating the name being defined from the function
  /// type.
  Token get equals;

  /// Return the type of function being defined by the alias.
  ///
  /// When the non-function type aliases feature is enabled and the denoted
  /// type is not a [GenericFunctionType], return `null`.
  GenericFunctionType? get functionType;

  /// Return the type being defined by the alias.
  TypeAnnotation get type;

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  TypeParameterList? get typeParameters;
}

/// The "hide" clause in an extension declaration.
///
///    hideClause ::=
///        'hide' [TypeName] (',' [TypeName])*
///
///  Clients may not extend, implement or mix-in this class.
abstract class HideClause implements AstNode {
  /// Return the list of the elements that are being shown.
  NodeList<ShowHideClauseElement> get elements;

  /// Return the token representing the 'hide' keyword.
  Token get hideKeyword;
}

/// A combinator that restricts the names being imported to those that are not
/// in a given list.
///
///    hideCombinator ::=
///        'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
///
/// Clients may not extend, implement or mix-in this class.
abstract class HideCombinator implements Combinator {
  /// Return the list of names from the library that are hidden by this
  /// combinator.
  NodeList<SimpleIdentifier> get hiddenNames;
}

/// A node that represents an identifier.
///
///    identifier ::=
///        [SimpleIdentifier]
///      | [PrefixedIdentifier]
///
/// Clients may not extend, implement or mix-in this class.
abstract class Identifier implements Expression, CommentReferableExpression {
  /// Return the lexical representation of the identifier.
  String get name;

  /// Return the element associated with this identifier based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// this identifier could not be resolved.
  ///
  /// One example of the latter case is an identifier that is not defined
  /// within the scope in which it appears.
  Element? get staticElement;

  /// Return `true` if the given [name] is visible only within the library in
  /// which it is declared.
  static bool isPrivateName(String name) => name.isNotEmpty && name[0] == "_";
}

/// The basic structure of an if element.
///
/// Clients may not extend, implement or mix-in this class.
abstract class IfElement implements CollectionElement {
  /// Return the condition used to determine which of the statements is executed
  /// next.
  Expression get condition;

  /// Return the statement that is executed if the condition evaluates to
  /// `false`, or `null` if there is no else statement.
  CollectionElement? get elseElement;

  /// Return the token representing the 'else' keyword, or `null` if there is no
  /// else statement.
  Token? get elseKeyword;

  /// Return the token representing the 'if' keyword.
  Token get ifKeyword;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the statement that is executed if the condition evaluates to
  /// `true`.
  CollectionElement get thenElement;
}

/// An if statement.
///
///    ifStatement ::=
///        'if' '(' [Expression] ')' [Statement] ('else' [Statement])?
///
/// Clients may not extend, implement or mix-in this class.
abstract class IfStatement implements Statement {
  /// Return the condition used to determine which of the statements is executed
  /// next.
  Expression get condition;

  /// Return the token representing the 'else' keyword, or `null` if there is no
  /// else statement.
  Token? get elseKeyword;

  /// Return the statement that is executed if the condition evaluates to
  /// `false`, or `null` if there is no else statement.
  Statement? get elseStatement;

  /// Return the token representing the 'if' keyword.
  Token get ifKeyword;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the statement that is executed if the condition evaluates to
  /// `true`.
  Statement get thenStatement;
}

/// The "implements" clause in an class declaration.
///
///    implementsClause ::=
///        'implements' [TypeName] (',' [TypeName])*
///
/// Clients may not extend, implement or mix-in this class.
abstract class ImplementsClause implements AstNode {
  /// Return the token representing the 'implements' keyword.
  Token get implementsKeyword;

  /// Return the list of the interfaces that are being implemented.
  @Deprecated('Use interfaces2 instead')
  NodeList<TypeName> get interfaces;

  /// Return the list of the interfaces that are being implemented.
  NodeList<NamedType> get interfaces2;
}

/// An expression representing an implicit 'call' method reference.
///
/// Objects of this type are not produced directly by the parser (because the
/// parser cannot tell whether an expression refers to a callable type); they
/// are produced at resolution time.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ImplicitCallReference implements MethodReferenceExpression {
  /// Return the expression from which a `call` method is being referenced.
  Expression get expression;

  /// Return the element associated with the implicit 'call' reference based on
  /// the static types.
  @override
  MethodElement get staticElement;

  /// The type arguments being applied to the tear-off, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;

  /// The actual type arguments being applied to the tear-off, either explicitly
  /// specified in [typeArguments], or inferred.
  ///
  /// Returns an empty list if the 'call' method does not have type parameters.
  List<DartType> get typeArgumentTypes;
}

/// An import directive.
///
///    importDirective ::=
///        [Annotation] 'import' [StringLiteral] ('as' identifier)? [Combinator]* ';'
///      | [Annotation] 'import' [StringLiteral] 'deferred' 'as' identifier [Combinator]* ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ImportDirective implements NamespaceDirective {
  static Comparator<ImportDirective> COMPARATOR =
      (ImportDirective import1, ImportDirective import2) {
    //
    // uri
    //
    StringLiteral uri1 = import1.uri;
    StringLiteral uri2 = import2.uri;
    String? uriStr1 = uri1.stringValue;
    String? uriStr2 = uri2.stringValue;
    if (uriStr1 != null || uriStr2 != null) {
      if (uriStr1 == null) {
        return -1;
      } else if (uriStr2 == null) {
        return 1;
      } else {
        int compare = uriStr1.compareTo(uriStr2);
        if (compare != 0) {
          return compare;
        }
      }
    }
    //
    // as
    //
    SimpleIdentifier? prefix1 = import1.prefix;
    SimpleIdentifier? prefix2 = import2.prefix;
    String? prefixStr1 = prefix1?.name;
    String? prefixStr2 = prefix2?.name;
    if (prefixStr1 != null || prefixStr2 != null) {
      if (prefixStr1 == null) {
        return -1;
      } else if (prefixStr2 == null) {
        return 1;
      } else {
        int compare = prefixStr1.compareTo(prefixStr2);
        if (compare != 0) {
          return compare;
        }
      }
    }
    //
    // hides and shows
    //
    NodeList<Combinator> combinators1 = import1.combinators;
    List<String> allHides1 = <String>[];
    List<String> allShows1 = <String>[];
    int length1 = combinators1.length;
    for (int i = 0; i < length1; i++) {
      Combinator combinator = combinators1[i];
      if (combinator is HideCombinator) {
        NodeList<SimpleIdentifier> hides = combinator.hiddenNames;
        int hideLength = hides.length;
        for (int j = 0; j < hideLength; j++) {
          SimpleIdentifier simpleIdentifier = hides[j];
          allHides1.add(simpleIdentifier.name);
        }
      } else {
        NodeList<SimpleIdentifier> shows =
            (combinator as ShowCombinator).shownNames;
        int showLength = shows.length;
        for (int j = 0; j < showLength; j++) {
          SimpleIdentifier simpleIdentifier = shows[j];
          allShows1.add(simpleIdentifier.name);
        }
      }
    }
    NodeList<Combinator> combinators2 = import2.combinators;
    List<String> allHides2 = <String>[];
    List<String> allShows2 = <String>[];
    int length2 = combinators2.length;
    for (int i = 0; i < length2; i++) {
      Combinator combinator = combinators2[i];
      if (combinator is HideCombinator) {
        NodeList<SimpleIdentifier> hides = combinator.hiddenNames;
        int hideLength = hides.length;
        for (int j = 0; j < hideLength; j++) {
          SimpleIdentifier simpleIdentifier = hides[j];
          allHides2.add(simpleIdentifier.name);
        }
      } else {
        NodeList<SimpleIdentifier> shows =
            (combinator as ShowCombinator).shownNames;
        int showLength = shows.length;
        for (int j = 0; j < showLength; j++) {
          SimpleIdentifier simpleIdentifier = shows[j];
          allShows2.add(simpleIdentifier.name);
        }
      }
    }
    // test lengths of combinator lists first
    if (allHides1.length != allHides2.length) {
      return allHides1.length - allHides2.length;
    }
    if (allShows1.length != allShows2.length) {
      return allShows1.length - allShows2.length;
    }
    // next ensure that the lists are equivalent
    if (!allHides1.toSet().containsAll(allHides2)) {
      return -1;
    }
    if (!allShows1.toSet().containsAll(allShows2)) {
      return -1;
    }
    return 0;
  };

  /// Return the token representing the 'as' keyword, or `null` if the imported
  /// names are not prefixed.
  Token? get asKeyword;

  /// Return the token representing the 'deferred' keyword, or `null` if the
  /// imported URI is not deferred.
  Token? get deferredKeyword;

  @override
  ImportElement? get element;

  /// Return the prefix to be used with the imported names, or `null` if the
  /// imported names are not prefixed.
  SimpleIdentifier? get prefix;
}

/// An index expression.
///
///    indexExpression ::=
///        [Expression] '[' [Expression] ']'
///
/// Clients may not extend, implement or mix-in this class.
abstract class IndexExpression
    implements NullShortableExpression, MethodReferenceExpression {
  /// Return the expression used to compute the index.
  Expression get index;

  /// Return `true` if this expression is cascaded.
  ///
  /// If it is, then the target of this expression is not stored locally but is
  /// stored in the nearest ancestor that is a [CascadeExpression].
  bool get isCascaded;

  /// Whether this index expression is null aware (as opposed to non-null).
  bool get isNullAware;

  /// Return the left square bracket.
  Token get leftBracket;

  /// Return the period (".." | "?..") before a cascaded index expression, or
  /// `null` if this index expression is not part of a cascade expression.
  Token? get period;

  /// Return the question mark before the left bracket, or `null` if there is no
  /// question mark.
  Token? get question;

  /// Return the expression used to compute the object being indexed.
  ///
  /// If this index expression is not part of a cascade expression, then this
  /// is the same as [target]. If this index expression is part of a cascade
  /// expression, then the target expression stored with the cascade expression
  /// is returned.
  Expression get realTarget;

  /// Return the right square bracket.
  Token get rightBracket;

  /// Return the expression used to compute the object being indexed, or `null`
  /// if this index expression is part of a cascade expression.
  ///
  /// Use [realTarget] to get the target independent of whether this is part of
  /// a cascade expression.
  Expression? get target;

  /// Return `true` if this expression is computing a right-hand value (that is,
  /// if this expression is in a context where the operator '[]' will be
  /// invoked).
  ///
  /// Note that [inGetterContext] and [inSetterContext] are not opposites, nor
  /// are they mutually exclusive. In other words, it is possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inGetterContext();

  /// Return `true` if this expression is computing a left-hand value (that is,
  /// if this expression is in a context where the operator '[]=' will be
  /// invoked).
  ///
  /// Note that [inGetterContext] and [inSetterContext] are not opposites, nor
  /// are they mutually exclusive. In other words, it is possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inSetterContext();
}

/// An instance creation expression.
///
///    newExpression ::=
///        ('new' | 'const')? [TypeName] ('.' [SimpleIdentifier])? [ArgumentList]
///
/// Clients may not extend, implement or mix-in this class.
abstract class InstanceCreationExpression implements Expression {
  /// Return the list of arguments to the constructor.
  ArgumentList get argumentList;

  /// Return the name of the constructor to be invoked.
  ConstructorName get constructorName;

  /// Return `true` if this creation expression is used to invoke a constant
  /// constructor, either because the keyword `const` was explicitly provided or
  /// because no keyword was provided and this expression is in a constant
  /// context.
  bool get isConst;

  /// Return the 'new' or 'const' keyword used to indicate how an object should
  /// be created, or `null` if the keyword was not explicitly provided.
  Token? get keyword;
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class IntegerLiteral implements Literal {
  /// Return the token representing the literal.
  Token get literal;

  /// Return the value of the literal, or `null` when [literal] does not
  /// represent a valid `int` value, for example because of overflow.
  int? get value;
}

/// A node within a [StringInterpolation].
///
///    interpolationElement ::=
///        [InterpolationExpression]
///      | [InterpolationString]
///
/// Clients may not extend, implement or mix-in this class.
abstract class InterpolationElement implements AstNode {}

/// An expression embedded in a string interpolation.
///
///    interpolationExpression ::=
///        '$' [SimpleIdentifier]
///      | '$' '{' [Expression] '}'
///
/// Clients may not extend, implement or mix-in this class.
abstract class InterpolationExpression implements InterpolationElement {
  /// Return the expression to be evaluated for the value to be converted into a
  /// string.
  Expression get expression;

  /// Return the token used to introduce the interpolation expression; either
  /// '$' if the expression is a simple identifier or '${' if the expression is
  /// a full expression.
  Token get leftBracket;

  /// Return the right curly bracket, or `null` if the expression is an
  /// identifier without brackets.
  Token? get rightBracket;
}

/// A non-empty substring of an interpolated string.
///
///    interpolationString ::=
///        characters
///
/// Clients may not extend, implement or mix-in this class.
abstract class InterpolationString implements InterpolationElement {
  /// Return the characters that will be added to the string.
  Token get contents;

  /// Return the offset of the after-last contents character.
  int get contentsEnd;

  /// Return the offset of the first contents character.
  int get contentsOffset;

  /// Return the value of the literal.
  String get value;
}

/// The invocation of a function or method; either a
/// [FunctionExpressionInvocation] or a [MethodInvocation].
///
/// Clients may not extend, implement or mix-in this class.
abstract class InvocationExpression implements Expression {
  /// Return the list of arguments to the method.
  ArgumentList get argumentList;

  /// The expression that identifies the function or method being invoked.
  /// For example:
  ///
  ///     (o.m)<TArgs>(args); // target will be `o.m`
  ///     o.m<TArgs>(args);   // target will be `m`
  ///
  /// In either case, the [function.staticType] will be the
  /// [staticInvokeType] before applying type arguments `TArgs`.
  Expression get function;

  /// Return the function type of the invocation based on the static type
  /// information, or `null` if the AST structure has not been resolved, or if
  /// the invoke could not be resolved.
  ///
  /// This will usually be a [FunctionType], but it can also be `dynamic` or
  /// `Function`. In the case of interface types that have a `call` method, we
  /// store the type of that `call` method here as parameterized.
  DartType? get staticInvokeType;

  /// Return the type arguments to be applied to the method being invoked, or
  /// `null` if no type arguments were provided.
  TypeArgumentList? get typeArguments;

  /// Return the actual type arguments of the invocation, either explicitly
  /// specified in [typeArguments], or inferred.
  ///
  /// If the AST has been resolved, never returns `null`, returns an empty list
  /// if the [function] does not have type parameters.
  ///
  /// Return `null` if the AST structure has not been resolved.
  List<DartType>? get typeArgumentTypes;
}

/// An is expression.
///
///    isExpression ::=
///        [Expression] 'is' '!'? [TypeAnnotation]
///
/// Clients may not extend, implement or mix-in this class.
abstract class IsExpression implements Expression {
  /// Return the expression used to compute the value whose type is being
  /// tested.
  Expression get expression;

  /// Return the is operator.
  Token get isOperator;

  /// Return the not operator, or `null` if the sense of the test is not
  /// negated.
  Token? get notOperator;

  /// Return the type being tested for.
  TypeAnnotation get type;
}

/// A label on either a [LabeledStatement] or a [NamedExpression].
///
///    label ::=
///        [SimpleIdentifier] ':'
///
/// Clients may not extend, implement or mix-in this class.
abstract class Label implements AstNode {
  /// Return the colon that separates the label from the statement.
  Token get colon;

  /// Return the label being associated with the statement.
  SimpleIdentifier get label;
}

/// A statement that has a label associated with them.
///
///    labeledStatement ::=
///       [Label]+ [Statement]
///
/// Clients may not extend, implement or mix-in this class.
abstract class LabeledStatement implements Statement {
  /// Return the labels being associated with the statement.
  NodeList<Label> get labels;

  /// Return the statement with which the labels are being associated.
  Statement get statement;
}

/// A library directive.
///
///    libraryDirective ::=
///        [Annotation] 'library' [Identifier] ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryDirective implements Directive {
  /// Return the token representing the 'library' keyword.
  Token get libraryKeyword;

  /// Return the name of the library being defined.
  LibraryIdentifier get name;

  /// Return the semicolon terminating the directive.
  Token get semicolon;
}

/// The identifier for a library.
///
///    libraryIdentifier ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryIdentifier implements Identifier {
  /// Return the components of the identifier.
  NodeList<SimpleIdentifier> get components;
}

/// A list literal.
///
///    listLiteral ::=
///        'const'? [TypeAnnotationList]? '[' elements? ']'
///
///    elements ::=
///        [CollectionElement] (',' [CollectionElement])* ','?
///
/// Clients may not extend, implement or mix-in this class.
abstract class ListLiteral implements TypedLiteral {
  /// Return the syntactic elements used to compute the elements of the list.
  NodeList<CollectionElement> get elements;

  /// Return the left square bracket.
  Token get leftBracket;

  /// Return the right square bracket.
  Token get rightBracket;
}

/// A node that represents a literal expression.
///
///    literal ::=
///        [BooleanLiteral]
///      | [DoubleLiteral]
///      | [IntegerLiteral]
///      | [ListLiteral]
///      | [NullLiteral]
///      | [SetOrMapLiteral]
///      | [StringLiteral]
///
/// Clients may not extend, implement or mix-in this class.
abstract class Literal implements Expression {}

/// A single key/value pair in a map literal.
///
///    mapLiteralEntry ::=
///        [Expression] ':' [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class MapLiteralEntry implements CollectionElement {
  /// Return the expression computing the key with which the value will be
  /// associated.
  Expression get key;

  /// Return the colon that separates the key from the value.
  Token get separator;

  /// Return the expression computing the value that will be associated with the
  /// key.
  Expression get value;
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
///
/// Prior to the 'extension-methods' experiment, these nodes were always
/// children of a class declaration. When the experiment is enabled, these nodes
/// can also be children of an extension declaration.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MethodDeclaration implements ClassMember {
  /// Return the body of the method.
  FunctionBody get body;

  @override
  ExecutableElement? get declaredElement;

  /// Return the token for the 'external' keyword, or `null` if the constructor
  /// is not external.
  Token? get externalKeyword;

  /// Return `true` if this method is declared to be an abstract method.
  bool get isAbstract;

  /// Return `true` if this method declares a getter.
  bool get isGetter;

  /// Return `true` if this method declares an operator.
  bool get isOperator;

  /// Return `true` if this method declares a setter.
  bool get isSetter;

  /// Return `true` if this method is declared to be a static method.
  bool get isStatic;

  /// Return the token representing the 'abstract' or 'static' keyword, or
  /// `null` if neither modifier was specified.
  Token? get modifierKeyword;

  /// Return the name of the method.
  SimpleIdentifier get name;

  /// Return the token representing the 'operator' keyword, or `null` if this
  /// method does not declare an operator.
  Token? get operatorKeyword;

  /// Return the parameters associated with the method, or `null` if this method
  /// declares a getter.
  FormalParameterList? get parameters;

  /// Return the token representing the 'get' or 'set' keyword, or `null` if
  /// this is a method declaration rather than a property declaration.
  Token? get propertyKeyword;

  /// Return the return type of the method, or `null` if no return type was
  /// declared.
  TypeAnnotation? get returnType;

  /// Return the type parameters associated with this method, or `null` if this
  /// method is not a generic method.
  TypeParameterList? get typeParameters;
}

/// The invocation of either a function or a method.
///
/// Invocations of functions resulting from evaluating an expression are
/// represented by [FunctionExpressionInvocation] nodes. Invocations of getters
/// and setters are represented by either [PrefixedIdentifier] or
/// [PropertyAccess] nodes.
///
///    methodInvocation ::=
///        ([Expression] '.')? [SimpleIdentifier] [TypeArgumentList]? [ArgumentList]
///
/// Clients may not extend, implement or mix-in this class.
abstract class MethodInvocation
    implements NullShortableExpression, InvocationExpression {
  /// Return `true` if this expression is cascaded.
  ///
  /// If it is, then the target of this expression is not stored locally but is
  /// stored in the nearest ancestor that is a [CascadeExpression].
  bool get isCascaded;

  /// Whether this method invocation is null aware (as opposed to non-null).
  bool get isNullAware;

  /// Return the name of the method being invoked.
  SimpleIdentifier get methodName;

  /// Return the operator that separates the target from the method name, or
  /// `null` if there is no target.
  ///
  /// In an ordinary method invocation this will be period ('.'). In a cascade
  /// section this will be the cascade operator ('..').
  Token? get operator;

  /// Return the expression used to compute the receiver of the invocation.
  ///
  /// If this invocation is not part of a cascade expression, then this is the
  /// same as [target]. If this invocation is part of a cascade expression,
  /// then the target stored with the cascade expression is returned.
  Expression? get realTarget;

  /// Return the expression producing the object on which the method is defined,
  /// or `null` if there is no target (that is, the target is implicitly `this`)
  /// or if this method invocation is part of a cascade expression.
  ///
  /// Use [realTarget] to get the target independent of whether this is part of
  /// a cascade expression.
  Expression? get target;
}

/// An expression that implicitly makes reference to a method.
///
/// Clients may not extend, implement or mix-in this class.
abstract class MethodReferenceExpression implements Expression {
  /// Return the element associated with the expression based on the static
  /// types, or `null` if the AST structure has not been resolved, or there is
  /// no meaningful static element to return (e.g. because this is a
  /// non-compound assignment expression, or because the method referred to
  /// could not be resolved).
  MethodElement? get staticElement;
}

/// The declaration of a mixin.
///
///    mixinDeclaration ::=
///        metadata? 'mixin' [SimpleIdentifier] [TypeParameterList]?
///        [OnClause]? [ImplementsClause]? '{' [ClassMember]* '}'
///
/// Clients may not extend, implement or mix-in this class.
abstract class MixinDeclaration implements ClassOrMixinDeclaration {
  /// Return the token representing the 'mixin' keyword.
  Token get mixinKeyword;

  /// Return the on clause for the mixin, or `null` if the mixin does not have
  /// any superclass constraints.
  OnClause? get onClause;
}

/// A node that declares a single name within the scope of a compilation unit.
///
/// Clients may not extend, implement or mix-in this class.
abstract class NamedCompilationUnitMember implements CompilationUnitMember {
  /// Return the name of the member being declared.
  SimpleIdentifier get name;
}

/// An expression that has a name associated with it. They are used in method
/// invocations when there are named parameters.
///
///    namedExpression ::=
///        [Label] [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class NamedExpression implements Expression {
  /// Return the element representing the parameter being named by this
  /// expression, or `null` if the AST structure has not been resolved or if
  /// there is no parameter with the same name as this expression.
  ParameterElement? get element;

  /// Return the expression with which the name is associated.
  Expression get expression;

  /// Return the name associated with the expression.
  Label get name;
}

/// A named type, which can optionally include type arguments.
///
///    namedType ::=
///        [Identifier] typeArguments?
///
/// Clients may not extend, implement or mix-in this class.
abstract class NamedType implements TypeAnnotation, ShowHideClauseElement {
  /// Return `true` if this type is a deferred type.
  ///
  /// 15.1 Static Types: A type <i>T</i> is deferred iff it is of the form
  /// </i>p.T</i> where <i>p</i> is a deferred prefix.
  bool get isDeferred;

  /// Return the name of the type.
  Identifier get name;

  /// Return the type arguments associated with the type, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;
}

/// A node that represents a directive that impacts the namespace of a library.
///
///    directive ::=
///        [ExportDirective]
///      | [ImportDirective]
///
/// Clients may not extend, implement or mix-in this class.
abstract class NamespaceDirective implements UriBasedDirective {
  /// Return the combinators used to control how names are imported or exported.
  NodeList<Combinator> get combinators;

  /// Return the configurations used to control which library will actually be
  /// loaded at run-time.
  NodeList<Configuration> get configurations;

  /// Return the source that was selected based on the declared variables.
  ///
  /// This will be the source from the first configuration whose condition is
  /// true, or the `[uriSource]` if either there are no configurations or if
  /// there are no configurations whose condition is true.
  Source? get selectedSource;

  /// Return the content of the URI that was selected based on the declared
  /// variables.
  ///
  /// This will be the URI from the first configuration whose condition is
  /// true, or the `[uriContent]` if either there are no configurations or if
  /// there are no configurations whose condition is true.
  String? get selectedUriContent;

  /// Return the semicolon terminating the directive.
  Token get semicolon;

  @override
  LibraryElement? get uriElement;
}

/// The "native" clause in an class declaration.
///
///    nativeClause ::=
///        'native' [StringLiteral]
///
/// Clients may not extend, implement or mix-in this class.
abstract class NativeClause implements AstNode {
  /// Return the name of the native object that implements the class.
  StringLiteral? get name;

  /// Return the token representing the 'native' keyword.
  Token get nativeKeyword;
}

/// A function body that consists of a native keyword followed by a string
/// literal.
///
///    nativeFunctionBody ::=
///        'native' [SimpleStringLiteral] ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class NativeFunctionBody implements FunctionBody {
  /// Return the token representing 'native' that marks the start of the
  /// function body.
  Token get nativeKeyword;

  /// Return the token representing the semicolon that marks the end of the
  /// function body.
  Token get semicolon;

  /// Return the string literal representing the string after the 'native'
  /// token.
  StringLiteral? get stringLiteral;
}

/// A list of AST nodes that have a common parent.
///
/// Clients may not extend, implement or mix-in this class.
abstract class NodeList<E extends AstNode> implements List<E> {
  /// Return the first token included in this node list's source range, or
  /// `null` if the list is empty.
  Token? get beginToken;

  /// Return the last token included in this node list's source range, or `null`
  /// if the list is empty.
  Token? get endToken;

  /// Return the node that is the parent of each of the elements in the list.
  AstNode get owner;

  /// Return the node at the given [index] in the list or throw a [RangeError]
  /// if [index] is out of bounds.
  @override
  E operator [](int index);

  /// Use the given [visitor] to visit each of the nodes in this list.
  void accept(AstVisitor visitor);
}

/// A formal parameter that is required (is not optional).
///
///    normalFormalParameter ::=
///        [FunctionTypedFormalParameter]
///      | [FieldFormalParameter]
///      | [SimpleFormalParameter]
///
/// Clients may not extend, implement or mix-in this class.
abstract class NormalFormalParameter implements FormalParameter {
  /// Return the documentation comment associated with this parameter, or `null`
  /// if this parameter does not have a documentation comment associated with
  /// it.
  Comment? get documentationComment;

  /// Return a list containing the comment and annotations associated with this
  /// parameter, sorted in lexical order.
  List<AstNode> get sortedCommentAndAnnotations;
}

/// A null literal expression.
///
///    nullLiteral ::=
///        'null'
///
/// Clients may not extend, implement or mix-in this class.
abstract class NullLiteral implements Literal {
  /// Return the token representing the literal.
  Token get literal;
}

/// Abstract interface for expressions that may participate in null-shorting.
abstract class NullShortableExpression implements Expression {
  /// Returns the expression that terminates any null shorting that might occur
  /// in this expression.  This may be called regardless of whether this
  /// expression is itself null-aware.
  ///
  /// For example, the statement `a?.b[c] = d;` contains the following
  /// null-shortable subexpressions:
  /// - `a?.b`
  /// - `a?.b[c]`
  /// - `a?.b[c] = d`
  ///
  /// Calling [nullShortingTermination] on any of these subexpressions yields
  /// the expression `a?.b[c] = d`, indicating that the null-shorting induced by
  /// the `?.` causes the rest of the subexpression `a?.b[c] = d` to be skipped.
  Expression get nullShortingTermination;
}

/// The "on" clause in a mixin declaration.
///
///    onClause ::=
///        'on' [TypeName] (',' [TypeName])*
///
/// Clients may not extend, implement or mix-in this class.
abstract class OnClause implements AstNode {
  /// Return the token representing the 'on' keyword.
  Token get onKeyword;

  /// Return the list of the classes are superclass constraints for the mixin.
  @Deprecated('Use superclassConstraints2 instead')
  NodeList<TypeName> get superclassConstraints;

  /// Return the list of the classes are superclass constraints for the mixin.
  NodeList<NamedType> get superclassConstraints2;
}

/// A parenthesized expression.
///
///    parenthesizedExpression ::=
///        '(' [Expression] ')'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParenthesizedExpression implements Expression {
  /// Return the expression within the parentheses.
  Expression get expression;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

/// A part directive.
///
///    partDirective ::=
///        [Annotation] 'part' [StringLiteral] ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class PartDirective implements UriBasedDirective {
  /// Return the token representing the 'part' keyword.
  Token get partKeyword;

  /// Return the semicolon terminating the directive.
  Token get semicolon;
}

/// A part-of directive.
///
///    partOfDirective ::=
///        [Annotation] 'part' 'of' [Identifier] ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class PartOfDirective implements Directive {
  /// Return the name of the library that the containing compilation unit is
  /// part of.
  LibraryIdentifier? get libraryName;

  /// Return the token representing the 'of' keyword.
  Token get ofKeyword;

  /// Return the token representing the 'part' keyword.
  Token get partKeyword;

  /// Return the semicolon terminating the directive.
  Token get semicolon;

  /// Return the URI of the library that the containing compilation unit is part
  /// of, or `null` if no URI was given (typically because a library name was
  /// provided).
  StringLiteral? get uri;
}

/// A postfix unary expression.
///
///    postfixExpression ::=
///        [Expression] [Token]
///
/// Clients may not extend, implement or mix-in this class.
abstract class PostfixExpression
    implements
        Expression,
        NullShortableExpression,
        MethodReferenceExpression,
        CompoundAssignmentExpression {
  /// Return the expression computing the operand for the operator.
  Expression get operand;

  /// Return the postfix operator being applied to the operand.
  Token get operator;
}

/// An identifier that is prefixed or an access to an object property where the
/// target of the property access is a simple identifier.
///
///    prefixedIdentifier ::=
///        [SimpleIdentifier] '.' [SimpleIdentifier]
///
/// Clients may not extend, implement or mix-in this class.
abstract class PrefixedIdentifier implements Identifier {
  /// Return the identifier being prefixed.
  SimpleIdentifier get identifier;

  /// Return `true` if this type is a deferred type. If the AST structure has
  /// not been resolved, then return `false`.
  ///
  /// 15.1 Static Types: A type <i>T</i> is deferred iff it is of the form
  /// </i>p.T</i> where <i>p</i> is a deferred prefix.
  bool get isDeferred;

  /// Return the period used to separate the prefix from the identifier.
  Token get period;

  /// Return the prefix associated with the library in which the identifier is
  /// defined.
  SimpleIdentifier get prefix;
}

/// A prefix unary expression.
///
///    prefixExpression ::=
///        [Token] [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class PrefixExpression
    implements
        Expression,
        NullShortableExpression,
        MethodReferenceExpression,
        CompoundAssignmentExpression {
  /// Return the expression computing the operand for the operator.
  Expression get operand;

  /// Return the prefix operator being applied to the operand.
  Token get operator;
}

/// The access of a property of an object.
///
/// Note, however, that accesses to properties of objects can also be
/// represented as [PrefixedIdentifier] nodes in cases where the target is also
/// a simple identifier.
///
///    propertyAccess ::=
///        [Expression] '.' [SimpleIdentifier]
///
/// Clients may not extend, implement or mix-in this class.
abstract class PropertyAccess
    implements NullShortableExpression, CommentReferableExpression {
  /// Return `true` if this expression is cascaded.
  ///
  /// If it is, then the target of this expression is not stored locally but is
  /// stored in the nearest ancestor that is a [CascadeExpression].
  bool get isCascaded;

  /// Whether this property access is null aware (as opposed to non-null).
  bool get isNullAware;

  /// Return the property access operator.
  Token get operator;

  /// Return the name of the property being accessed.
  SimpleIdentifier get propertyName;

  /// Return the expression used to compute the receiver of the invocation.
  ///
  /// If this invocation is not part of a cascade expression, then this is the
  /// same as [target]. If this invocation is part of a cascade expression,
  /// then the target stored with the cascade expression is returned.
  Expression get realTarget;

  /// Return the expression computing the object defining the property being
  /// accessed, or `null` if this property access is part of a cascade
  /// expression.
  ///
  /// Use [realTarget] to get the target independent of whether this is part of
  /// a cascade expression.
  Expression? get target;
}

/// The invocation of a constructor in the same class from within a
/// constructor's initialization list.
///
///    redirectingConstructorInvocation ::=
///        'this' ('.' identifier)? arguments
///
/// Clients may not extend, implement or mix-in this class.
abstract class RedirectingConstructorInvocation
    implements ConstructorInitializer, ConstructorReferenceNode {
  /// Return the list of arguments to the constructor.
  ArgumentList get argumentList;

  /// Return the name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifier? get constructorName;

  /// Return the token for the period before the name of the constructor that is
  /// being invoked, or `null` if the unnamed constructor is being invoked.
  Token? get period;

  /// Return the token for the 'this' keyword.
  Token get thisKeyword;
}

/// A rethrow expression.
///
///    rethrowExpression ::=
///        'rethrow'
///
/// Clients may not extend, implement or mix-in this class.
abstract class RethrowExpression implements Expression {
  /// Return the token representing the 'rethrow' keyword.
  Token get rethrowKeyword;
}

/// A return statement.
///
///    returnStatement ::=
///        'return' [Expression]? ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ReturnStatement implements Statement {
  /// Return the expression computing the value to be returned, or `null` if no
  /// explicit value was provided.
  Expression? get expression;

  /// Return the token representing the 'return' keyword.
  Token get returnKeyword;

  /// Return the semicolon terminating the statement.
  Token get semicolon;
}

/// A script tag that can optionally occur at the beginning of a compilation
/// unit.
///
///    scriptTag ::=
///        '#!' (~NEWLINE)* NEWLINE
///
/// Clients may not extend, implement or mix-in this class.
abstract class ScriptTag implements AstNode {
  /// Return the token representing this script tag.
  Token get scriptTag;
}

/// A set or map literal.
///
///    setOrMapLiteral ::=
///        'const'? [TypeArgumentList]? '{' elements? '}'
///
///    elements ::=
///        [CollectionElement] ( ',' [CollectionElement] )* ','?
///
/// This is the class that is used to represent either a map or set literal when
/// either the 'control-flow-collections' or 'spread-collections' experiments
/// are enabled. If neither of those experiments are enabled, then `MapLiteral`
/// will be used to represent a map literal and `SetLiteral` will be used for
/// set literals.
///
/// Clients may not extend, implement or mix-in this class.
abstract class SetOrMapLiteral implements TypedLiteral {
  /// Return the syntactic elements used to compute the elements of the set or
  /// map.
  NodeList<CollectionElement> get elements;

  /// Return `true` if this literal represents a map literal.
  ///
  /// This getter will always return `false` if [isSet] returns `true`.
  ///
  /// However, this getter is _not_ the inverse of [isSet]. It is possible for
  /// both getters to return `false` if
  ///
  /// - the AST has not been resolved (because determining the kind of the
  ///   literal is done during resolution),
  /// - the literal is ambiguous (contains one or more spread elements and none
  ///   of those elements can be used to determine the kind of the literal), or
  /// - the literal is invalid because it contains both expressions (for sets)
  ///   and map entries (for maps).
  ///
  /// In both of the latter two cases there will be compilation errors
  /// associated with the literal.
  bool get isMap;

  /// Return `true` if this literal represents a set literal.
  ///
  /// This getter will always return `false` if [isMap] returns `true`.
  ///
  /// However, this getter is _not_ the inverse of [isMap]. It is possible for
  /// both getters to return `false` if
  ///
  /// - the AST has not been resolved (because determining the kind of the
  ///   literal is done during resolution),
  /// - the literal is ambiguous (contains one or more spread elements and none
  ///   of those elements can be used to determine the kind of the literal), or
  /// - the literal is invalid because it contains both expressions (for sets)
  ///   and map entries (for maps).
  ///
  /// In both of the latter two cases there will be compilation errors
  /// associated with the literal.
  bool get isSet;

  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the right curly bracket.
  Token get rightBracket;
}

/// The "show" clause in an extension declaration.
///
///    showClause ::=
///        'show' [TypeName] (',' [TypeName])*
///
///  Clients may not extend, implement or mix-in this class.
abstract class ShowClause implements AstNode {
  /// Return the list of the elements that are being shown.
  NodeList<ShowHideClauseElement> get elements;

  /// Return the token representing the 'show' keyword.
  Token get showKeyword;
}

/// A combinator that restricts the names being imported to those in a given list.
///
///    showCombinator ::=
///        'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
///
/// Clients may not extend, implement or mix-in this class.
abstract class ShowCombinator implements Combinator {
  /// Return the list of names from the library that are made visible by this
  /// combinator.
  NodeList<SimpleIdentifier> get shownNames;
}

/// A node that can appear in the show or hide clauses.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ShowHideClauseElement implements AstNode {}

/// A potentially non-type element of a show or a hide clause.
///
///    showHideElement ::=
///        'get' [SimpleIdentifier] |
///        'set' [SimpleIdentifier] |
///        'operator' [SimpleIdentifier] |
///        [SimpleIdentifier]
///
/// Clients may not extend, implement or mix-in this class.
abstract class ShowHideElement implements AstNode, ShowHideClauseElement {
  /// Return the 'get', 'set', or 'operator' modifier that appears before the
  /// name, or `null` if there is no modifier.
  Token? get modifier;

  /// Return the name of the member the element refers to.
  SimpleIdentifier get name;
}

/// A simple formal parameter.
///
///    simpleFormalParameter ::=
///        ('final' [TypeAnnotation] | 'var' | [TypeAnnotation])? [SimpleIdentifier]
///
/// Clients may not extend, implement or mix-in this class.
abstract class SimpleFormalParameter implements NormalFormalParameter {
  /// Return the token representing either the 'final', 'const' or 'var'
  /// keyword, or `null` if no keyword was used.
  Token? get keyword;

  /// Return the declared type of the parameter, or `null` if the parameter does
  /// not have a declared type.
  TypeAnnotation? get type;
}

/// A simple identifier.
///
///    simpleIdentifier ::=
///        initialCharacter internalCharacter*
///
///    initialCharacter ::= '_' | '$' | letter
///
///    internalCharacter ::= '_' | '$' | letter | digit
///
/// Clients may not extend, implement or mix-in this class.
abstract class SimpleIdentifier implements Identifier {
  /// Return `true` if this identifier is the "name" part of a prefixed
  /// identifier or a method invocation.
  bool get isQualified;

  /// If the identifier is a tear-off, return the inferred type arguments
  /// applied to the function type of the element to produce its `[staticType]`.
  ///
  /// Return an empty list if the function type does not have type parameters.
  ///
  /// Return an empty list if the context type has type parameters.
  ///
  /// Return `null` if not a tear-off.
  ///
  /// Return `null` if the AST structure has not been resolved.
  List<DartType>? get tearOffTypeArgumentTypes;

  /// Return the token representing the identifier.
  Token get token;

  /// Return `true` if this identifier is the name being declared in a
  /// declaration.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inDeclarationContext();

  /// Return `true` if this expression is computing a right-hand value.
  ///
  /// Note that [inGetterContext] and [inSetterContext] are not opposites, nor
  /// are they mutually exclusive. In other words, it is possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inGetterContext();

  /// Return `true` if this expression is computing a left-hand value.
  ///
  /// Note that [inGetterContext] and [inSetterContext] are not opposites, nor
  /// are they mutually exclusive. In other words, it is possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inSetterContext();
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
///    basicStringLiteral ::=
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class SimpleStringLiteral implements SingleStringLiteral {
  /// Return the token representing the literal.
  Token get literal;

  /// Return the value of the literal.
  String get value;
}

/// A single string literal expression.
///
///    singleStringLiteral ::=
///        [SimpleStringLiteral]
///      | [StringInterpolation]
///
/// Clients may not extend, implement or mix-in this class.
abstract class SingleStringLiteral implements StringLiteral {
  /// Return the offset of the after-last contents character.
  int get contentsEnd;

  /// Return the offset of the first contents character.
  ///
  /// If the string is multiline, then leading whitespaces are skipped.
  int get contentsOffset;

  /// Return `true` if this string literal is a multi-line string.
  bool get isMultiline;

  /// Return `true` if this string literal is a raw string.
  bool get isRaw;

  /// Return `true` if this string literal uses single quotes (' or '''), or
  /// `false` if this string literal uses double quotes (" or """).
  bool get isSingleQuoted;
}

/// A spread element.
///
///    spreadElement:
///        ( '...' | '...?' ) [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class SpreadElement implements CollectionElement {
  /// The expression used to compute the collection being spread.
  Expression get expression;

  /// Whether this is a null-aware spread, as opposed to a non-null spread.
  bool get isNullAware;

  /// The spread operator, either '...' or '...?'.
  Token get spreadOperator;
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class Statement implements AstNode {
  /// If this is a labeled statement, return the unlabeled portion of the
  /// statement, otherwise return the statement itself.
  Statement get unlabeled;
}

/// A string interpolation literal.
///
///    stringInterpolation ::=
///        ''' [InterpolationElement]* '''
///      | '"' [InterpolationElement]* '"'
///
/// Clients may not extend, implement or mix-in this class.
abstract class StringInterpolation implements SingleStringLiteral {
  /// Return the elements that will be composed to produce the resulting string.
  /// The list includes [firstString] and [lastString].
  NodeList<InterpolationElement> get elements;

  /// Return the first element in this interpolation, which is always a string.
  /// The string might be empty if there is no text before the first
  /// interpolation expression (such as in `'$foo bar'`).
  InterpolationString get firstString;

  /// Return the last element in this interpolation, which is always a string.
  /// The string might be empty if there is no text after the last
  /// interpolation expression (such as in `'foo $bar'`).
  InterpolationString get lastString;
}

/// A string literal expression.
///
///    stringLiteral ::=
///        [SimpleStringLiteral]
///      | [AdjacentStrings]
///      | [StringInterpolation]
///
/// Clients may not extend, implement or mix-in this class.
abstract class StringLiteral implements Literal {
  /// Return the value of the string literal, or `null` if the string is not a
  /// constant string without any string interpolation.
  String? get stringValue;
}

/// The invocation of a superclass' constructor from within a constructor's
/// initialization list.
///
///    superInvocation ::=
///        'super' ('.' [SimpleIdentifier])? [ArgumentList]
///
/// Clients may not extend, implement or mix-in this class.
abstract class SuperConstructorInvocation
    implements ConstructorInitializer, ConstructorReferenceNode {
  /// Return the list of arguments to the constructor.
  ArgumentList get argumentList;

  /// Return the name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifier? get constructorName;

  /// Return the token for the period before the name of the constructor that is
  /// being invoked, or `null` if the unnamed constructor is being invoked.
  Token? get period;

  /// Return the token for the 'super' keyword.
  Token get superKeyword;
}

/// A super expression.
///
///    superExpression ::=
///        'super'
///
/// Clients may not extend, implement or mix-in this class.
abstract class SuperExpression implements Expression {
  /// Return the token representing the 'super' keyword.
  Token get superKeyword;
}

/// A super-initializer formal parameter.
///
///    superFormalParameter ::=
///        ('final' [TypeAnnotation] | 'const' [TypeAnnotation] | 'var' | [TypeAnnotation])?
///        'super' '.' [SimpleIdentifier] ([TypeParameterList]? [FormalParameterList])?
///
/// Clients may not extend, implement or mix-in this class.
abstract class SuperFormalParameter implements NormalFormalParameter {
  @override
  SimpleIdentifier get identifier;

  /// Return the token representing either the 'final', 'const' or 'var'
  /// keyword, or `null` if no keyword was used.
  Token? get keyword;

  /// Return the parameters of the function-typed parameter, or `null` if this
  /// is not a function-typed field formal parameter.
  FormalParameterList? get parameters;

  /// Return the token representing the period.
  Token get period;

  /// If the parameter is function-typed, and has the question mark, then its
  /// function type is nullable. Having a nullable function type means that the
  /// parameter can be null.
  Token? get question;

  /// Return the token representing the 'super' keyword.
  Token get superKeyword;

  /// Return the declared type of the parameter, or `null` if the parameter does
  /// not have a declared type.
  ///
  /// Note that if this is a function-typed field formal parameter this is the
  /// return type of the function.
  TypeAnnotation? get type;

  /// Return the type parameters associated with this method, or `null` if this
  /// method is not a generic method.
  TypeParameterList? get typeParameters;
}

/// A case in a switch statement.
///
///    switchCase ::=
///        [SimpleIdentifier]* 'case' [Expression] ':' [Statement]*
///
/// Clients may not extend, implement or mix-in this class.
abstract class SwitchCase implements SwitchMember {
  /// Return the expression controlling whether the statements will be executed.
  Expression get expression;
}

/// The default case in a switch statement.
///
///    switchDefault ::=
///        [SimpleIdentifier]* 'default' ':' [Statement]*
///
/// Clients may not extend, implement or mix-in this class.
abstract class SwitchDefault implements SwitchMember {}

/// An element within a switch statement.
///
///    switchMember ::=
///        switchCase
///      | switchDefault
///
/// Clients may not extend, implement or mix-in this class.
abstract class SwitchMember implements AstNode {
  /// Return the colon separating the keyword or the expression from the
  /// statements.
  Token get colon;

  /// Return the token representing the 'case' or 'default' keyword.
  Token get keyword;

  /// Return the labels associated with the switch member.
  NodeList<Label> get labels;

  /// Return the statements that will be executed if this switch member is
  /// selected.
  NodeList<Statement> get statements;
}

/// A switch statement.
///
///    switchStatement ::=
///        'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
///
/// Clients may not extend, implement or mix-in this class.
abstract class SwitchStatement implements Statement {
  /// Return the expression used to determine which of the switch members will
  /// be selected.
  Expression get expression;

  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the switch members that can be selected by the expression.
  NodeList<SwitchMember> get members;

  /// Return the right curly bracket.
  Token get rightBracket;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the token representing the 'switch' keyword.
  Token get switchKeyword;
}

/// A symbol literal expression.
///
///    symbolLiteral ::=
///        '#' (operator | (identifier ('.' identifier)*))
///
/// Clients may not extend, implement or mix-in this class.
abstract class SymbolLiteral implements Literal {
  /// Return the components of the literal.
  List<Token> get components;

  /// Return the token introducing the literal.
  Token get poundSign;
}

/// A this expression.
///
///    thisExpression ::=
///        'this'
///
/// Clients may not extend, implement or mix-in this class.
abstract class ThisExpression implements Expression {
  /// Return the token representing the 'this' keyword.
  Token get thisKeyword;
}

/// A throw expression.
///
///    throwExpression ::=
///        'throw' [Expression]
///
/// Clients may not extend, implement or mix-in this class.
abstract class ThrowExpression implements Expression {
  /// Return the expression computing the exception to be thrown.
  Expression get expression;

  /// Return the token representing the 'throw' keyword.
  Token get throwKeyword;
}

/// The declaration of one or more top-level variables of the same type.
///
///    topLevelVariableDeclaration ::=
///        ('final' | 'const') <type>? <staticFinalDeclarationList> ';'
///      | 'late' 'final' <type>? <initializedIdentifierList> ';'
///      | 'late'? <varOrType> <initializedIdentifierList> ';'
///      | 'external' <finalVarOrType> <identifierList> ';'
///
/// (Note: there is no <topLevelVariableDeclaration> production in the grammar;
/// this is a subset of the grammar production <topLevelDeclaration>, which
/// encompasses everything that can appear inside a Dart file after part
/// directives).
///
/// Clients may not extend, implement or mix-in this class.
abstract class TopLevelVariableDeclaration implements CompilationUnitMember {
  /// The `external` keyword, or `null` if the keyword was not used.
  Token? get externalKeyword;

  /// Return the semicolon terminating the declaration.
  Token get semicolon;

  /// Return the top-level variables being declared.
  VariableDeclarationList get variables;
}

/// A try statement.
///
///    tryStatement ::=
///        'try' [Block] ([CatchClause]+ finallyClause? | finallyClause)
///
///    finallyClause ::=
///        'finally' [Block]
///
/// Clients may not extend, implement or mix-in this class.
abstract class TryStatement implements Statement {
  /// Return the body of the statement.
  Block get body;

  /// Return the catch clauses contained in the try statement.
  NodeList<CatchClause> get catchClauses;

  /// Return the finally block contained in the try statement, or `null` if the
  /// statement does not contain a finally clause.
  Block? get finallyBlock;

  /// Return the token representing the 'finally' keyword, or `null` if the
  /// statement does not contain a finally clause.
  Token? get finallyKeyword;

  /// Return the token representing the 'try' keyword.
  Token get tryKeyword;
}

/// The declaration of a type alias.
///
///    typeAlias ::=
///        'typedef' typeAliasBody
///
///    typeAliasBody ::=
///        classTypeAlias
///      | functionTypeAlias
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeAlias implements NamedCompilationUnitMember {
  @override
  SimpleIdentifier get name;

  /// Return the semicolon terminating the declaration.
  Token get semicolon;

  /// Return the token representing the 'typedef' keyword.
  Token get typedefKeyword;
}

/// A type annotation.
///
///    type ::=
///        [NamedType]
///      | [GenericFunctionType]
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeAnnotation implements AstNode {
  /// The question mark indicating that the type is nullable, or `null` if there
  /// is no question mark.
  Token? get question;

  /// Return the type being named, or `null` if the AST structure has not been
  /// resolved.
  DartType? get type;
}

/// A list of type arguments.
///
///    typeArguments ::=
///        '<' typeName (',' typeName)* '>'
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeArgumentList implements AstNode {
  /// Return the type arguments associated with the type.
  NodeList<TypeAnnotation> get arguments;

  /// Return the left bracket.
  Token get leftBracket;

  /// Return the right bracket.
  Token get rightBracket;
}

/// A literal that has a type associated with it.
///
///    typedLiteral ::=
///        [ListLiteral]
///      | [SetOrMapLiteral]
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypedLiteral implements Literal {
  /// Return the token representing the 'const' keyword, or `null` if the
  /// literal is not a constant.
  Token? get constKeyword;

  /// Return `true` if this literal is a constant expression, either because the
  /// keyword `const` was explicitly provided or because no keyword was provided
  /// and this expression is in a constant context.
  bool get isConst;

  /// Return the type argument associated with this literal, or `null` if no
  /// type arguments were declared.
  TypeArgumentList? get typeArguments;
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
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeLiteral implements Expression, CommentReferableExpression {
  /// The type represented by this literal.
  NamedType get type;

  /// The type represented by this literal.
  @Deprecated('Use namedType instead')
  TypeName get typeName;
}

/// The name of a type, which can optionally include type arguments.
///
///    typeName ::=
///        [Identifier] typeArguments?
///
/// Clients may not extend, implement or mix-in this class.
@Deprecated('Use NamedType instead')
abstract class TypeName implements NamedType {}

/// A type parameter.
///
///    typeParameter ::=
///        [SimpleIdentifier] ('extends' [TypeAnnotation])?
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameter implements Declaration {
  /// Return the upper bound for legal arguments, or `null` if there is no
  /// explicit upper bound.
  TypeAnnotation? get bound;

  @override
  TypeParameterElement? get declaredElement;

  /// Return the token representing the 'extends' keyword, or `null` if there is
  /// no explicit upper bound.
  Token? get extendsKeyword;

  /// Return the name of the type parameter.
  SimpleIdentifier get name;
}

/// Type parameters within a declaration.
///
///    typeParameterList ::=
///        '<' [TypeParameter] (',' [TypeParameter])* '>'
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeParameterList implements AstNode {
  /// Return the left angle bracket.
  Token get leftBracket;

  /// Return the right angle bracket.
  Token get rightBracket;

  /// Return the type parameters for the type.
  NodeList<TypeParameter> get typeParameters;
}

/// A directive that references a URI.
///
///    uriBasedDirective ::=
///        [ExportDirective]
///      | [ImportDirective]
///      | [PartDirective]
///
/// Clients may not extend, implement or mix-in this class.
abstract class UriBasedDirective implements Directive {
  /// Return the URI referenced by this directive.
  StringLiteral get uri;

  /// Return the content of the [uri], or `null` if the AST structure has not
  /// been resolved, or if the [uri] has a string interpolation.
  String? get uriContent;

  /// Return the element associated with the [uri] of this directive, or `null`
  /// if the AST structure has not been resolved or if the URI could not be
  /// resolved.
  ///
  /// Examples of the latter case include a directive that contains an invalid
  /// URL or a URL that does not exist.
  Element? get uriElement;

  /// Return the source to which the [uri] was resolved.
  Source? get uriSource;
}

/// An identifier that has an initial value associated with it.
///
/// Instances of this class are always children of the class
/// [VariableDeclarationList].
///
///    variableDeclaration ::=
///        [SimpleIdentifier] ('=' [Expression])?
///
/// Clients may not extend, implement or mix-in this class.
// TODO(paulberry): the grammar does not allow metadata to be associated with a
// VariableDeclaration, and currently we don't record comments for it either.
// Consider changing the class hierarchy so that [VariableDeclaration] does not
// extend [Declaration].
abstract class VariableDeclaration implements Declaration {
  @override
  VariableElement? get declaredElement;

  /// Return the equal sign separating the variable name from the initial value,
  /// or `null` if the initial value was not specified.
  Token? get equals;

  /// Return the expression used to compute the initial value for the variable,
  /// or `null` if the initial value was not specified.
  Expression? get initializer;

  /// Return `true` if this variable was declared with the 'const' modifier.
  bool get isConst;

  /// Return `true` if this variable was declared with the 'final' modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  bool get isFinal;

  /// Return `true` if this variable was declared with the 'late' modifier.
  bool get isLate;

  /// Return the name of the variable being declared.
  SimpleIdentifier get name;
}

/// The declaration of one or more variables of the same type.
///
///    variableDeclarationList ::=
///        finalConstVarOrType [VariableDeclaration] (',' [VariableDeclaration])*
///
///    finalConstVarOrType ::=
///      'final' 'late'? [TypeAnnotation]?
///      | 'const' [TypeAnnotation]?
///      | 'var'
///      | 'late'? [TypeAnnotation]
///
/// Clients may not extend, implement or mix-in this class.
abstract class VariableDeclarationList implements AnnotatedNode {
  /// Return `true` if the variables in this list were declared with the 'const'
  /// modifier.
  bool get isConst;

  /// Return `true` if the variables in this list were declared with the 'final'
  /// modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final. (In other words, this is a
  /// syntactic check rather than a semantic check.)
  bool get isFinal;

  /// Return `true` if the variables in this list were declared with the 'late'
  /// modifier.
  bool get isLate;

  /// Return the token representing the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was included.
  Token? get keyword;

  /// Return the token representing the 'late' keyword, or `null` if the late
  /// modifier was not included.
  Token? get lateKeyword;

  /// Return the type of the variables being declared, or `null` if no type was
  /// provided.
  TypeAnnotation? get type;

  /// Return a list containing the individual variables being declared.
  NodeList<VariableDeclaration> get variables;
}

/// A list of variables that are being declared in a context where a statement
/// is required.
///
///    variableDeclarationStatement ::=
///        [VariableDeclarationList] ';'
///
/// Clients may not extend, implement or mix-in this class.
abstract class VariableDeclarationStatement implements Statement {
  /// Return the semicolon terminating the statement.
  Token get semicolon;

  /// Return the variables being declared.
  VariableDeclarationList get variables;
}

/// A while statement.
///
///    whileStatement ::=
///        'while' '(' [Expression] ')' [Statement]
///
/// Clients may not extend, implement or mix-in this class.
abstract class WhileStatement implements Statement {
  /// Return the body of the loop.
  Statement get body;

  /// Return the expression used to determine whether to execute the body of the
  /// loop.
  Expression get condition;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the token representing the 'while' keyword.
  Token get whileKeyword;
}

/// The with clause in a class declaration.
///
///    withClause ::=
///        'with' [TypeName] (',' [TypeName])*
///
/// Clients may not extend, implement or mix-in this class.
abstract class WithClause implements AstNode {
  /// Return the names of the mixins that were specified.
  @Deprecated('Use mixinTypes2 instead')
  NodeList<TypeName> get mixinTypes;

  /// Return the names of the mixins that were specified.
  NodeList<NamedType> get mixinTypes2;

  /// Return the token representing the 'with' keyword.
  Token get withKeyword;
}

/// A yield statement.
///
///    yieldStatement ::=
///        'yield' '*'? [Expression] ‘;’
///
/// Clients may not extend, implement or mix-in this class.
abstract class YieldStatement implements Statement {
  /// Return the expression whose value will be yielded.
  Expression get expression;

  /// Return the semicolon following the expression.
  Token get semicolon;

  /// Return the star optionally following the 'yield' keyword.
  Token? get star;

  /// Return the 'yield' keyword.
  Token get yieldKeyword;
}
