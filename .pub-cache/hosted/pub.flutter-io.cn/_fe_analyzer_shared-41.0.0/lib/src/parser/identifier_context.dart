// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages/codes.dart'
    show Message, Template, templateExpectedIdentifier;

import '../scanner/token.dart' show Token, TokenType;

import 'identifier_context_impl.dart';

import 'parser_impl.dart' show Parser;

import 'util.dart' show isOneOfOrEof, optional;

/// Information about the parser state that is passed to the listener at the
/// time an identifier is encountered. It is also used by the parser for error
/// recovery when a recovery template is defined.
///
/// This can be used by the listener to determine the context in which the
/// identifier appears; that in turn can help the listener decide how to resolve
/// the identifier (if the listener is doing resolution).
abstract class IdentifierContext {
  /// Identifier is being declared as the name of an import prefix (i.e. `Foo`
  /// in `import "..." as Foo;`)
  static const ImportPrefixIdentifierContext importPrefixDeclaration =
      const ImportPrefixIdentifierContext();

  /// Identifier is the start of a dotted name in a conditional import or
  /// export.
  static const DottedNameIdentifierContext dottedName =
      const DottedNameIdentifierContext();

  /// Identifier is part of a dotted name in a conditional import or export, but
  /// it's not the first identifier of the dotted name.
  static const DottedNameIdentifierContext dottedNameContinuation =
      const DottedNameIdentifierContext.continuation();

  /// Identifier is one of the shown/hidden names in an import/export
  /// combinator.
  static const CombinatorIdentifierContext combinator =
      const CombinatorIdentifierContext();

  /// Identifier is the start of a name in an annotation that precedes a
  /// declaration (i.e. it appears directly after an `@`).
  static const MetadataReferenceIdentifierContext metadataReference =
      const MetadataReferenceIdentifierContext();

  /// Identifier is part of a name in an annotation that precedes a declaration,
  /// but it's not the first identifier in the name.
  static const MetadataReferenceIdentifierContext metadataContinuation =
      const MetadataReferenceIdentifierContext.continuation();

  /// Identifier is part of a name in an annotation that precedes a declaration,
  /// but it appears after type parameters (e.g. `foo` in `@X<Y>.foo()`).
  static const MetadataReferenceIdentifierContext
      metadataContinuationAfterTypeArguments =
      const MetadataReferenceIdentifierContext.continuationAfterTypeArguments();

  /// Identifier is the name being declared by a typedef declaration.
  static const TypedefDeclarationIdentifierContext typedefDeclaration =
      const TypedefDeclarationIdentifierContext();

  /// Identifier is a field initializer in a formal parameter list (i.e. it
  /// appears directly after `this.`).
  static const FieldInitializerIdentifierContext fieldInitializer =
      const FieldInitializerIdentifierContext();

  /// Identifier is a formal parameter being declared as part of a function,
  /// method, or typedef declaration.
  static const FormalParameterDeclarationIdentifierContext
      formalParameterDeclaration =
      const FormalParameterDeclarationIdentifierContext();

  /// Identifier is a formal parameter being declared as part of a catch block
  /// in a try/catch/finally statement.
  static const CatchParameterIdentifierContext catchParameter =
      const CatchParameterIdentifierContext();

  /// Identifier is the start of a library name (e.g. `foo` in the directive
  /// 'library foo;`).
  static const LibraryIdentifierContext libraryName =
      const LibraryIdentifierContext();

  /// Identifier is part of a library name, but it's not the first identifier in
  /// the name.
  static const LibraryIdentifierContext libraryNameContinuation =
      const LibraryIdentifierContext.continuation();

  /// Identifier is the start of a library name referenced by a `part of`
  /// directive (e.g. `foo` in the directive `part of foo;`).
  static const LibraryIdentifierContext partName =
      const LibraryIdentifierContext.partName();

  /// Identifier is part of a library name referenced by a `part of` directive,
  /// but it's not the first identifier in the name.
  static const LibraryIdentifierContext partNameContinuation =
      const LibraryIdentifierContext.partNameContinuation();

  /// Identifier is the type name being declared by an enum declaration.
  static const EnumDeclarationIdentifierContext enumDeclaration =
      const EnumDeclarationIdentifierContext();

  /// Identifier is an enumerated value name being declared by an enum
  /// declaration.
  static const EnumValueDeclarationIdentifierContext enumValueDeclaration =
      const EnumValueDeclarationIdentifierContext();

  /// Identifier is the name being declared by a class declaration, a mixin
  /// declaration, or a named mixin application, for example,
  /// `Foo` in `class Foo = X with Y;`.
  static const ClassOrMixinOrExtensionIdentifierContext
      classOrMixinOrExtensionDeclaration =
      const ClassOrMixinOrExtensionIdentifierContext();

  /// Identifier is the name of a type variable being declared (e.g. `Foo` in
  /// `class C<Foo extends num> {}`).
  static const TypeVariableDeclarationIdentifierContext
      typeVariableDeclaration =
      const TypeVariableDeclarationIdentifierContext();

  /// Identifier is the start of a reference to a type that starts with prefix.
  static const TypeReferenceIdentifierContext prefixedTypeReference =
      const TypeReferenceIdentifierContext.prefixed();

  /// Identifier is the start of a reference to a type declared elsewhere.
  static const TypeReferenceIdentifierContext typeReference =
      const TypeReferenceIdentifierContext();

  /// Identifier is part of a reference to a type declared elsewhere, but it's
  /// not the first identifier of the reference.
  static const TypeReferenceIdentifierContext typeReferenceContinuation =
      const TypeReferenceIdentifierContext.continuation();

  /// Identifier is a name being declared by a top level variable declaration.
  static const TopLevelDeclarationIdentifierContext
      topLevelVariableDeclaration = const TopLevelDeclarationIdentifierContext(
          'topLevelVariableDeclaration', const [';', '=', ',']);

  /// Identifier is a name being declared by a field declaration.
  static const FieldDeclarationIdentifierContext fieldDeclaration =
      const FieldDeclarationIdentifierContext();

  /// Identifier is the name being declared by a top level function declaration.
  static const TopLevelDeclarationIdentifierContext
      topLevelFunctionDeclaration = const TopLevelDeclarationIdentifierContext(
          'topLevelFunctionDeclaration', const ['<', '(', '{', '=>']);

  /// Identifier is the start of the name being declared by a method
  /// declaration.
  static const MethodDeclarationIdentifierContext methodDeclaration =
      const MethodDeclarationIdentifierContext();

  /// Identifier is part of the name being declared by a method declaration,
  /// but it's not the first identifier of the name.
  ///
  /// In valid Dart, this can only happen if the identifier is the name of a
  /// named constructor which is being declared, e.g. `foo` in
  /// `class C { C.foo(); }`.
  static const MethodDeclarationIdentifierContext
      methodDeclarationContinuation =
      const MethodDeclarationIdentifierContext.continuation();

  /// Identifier appears after the word `operator` in a method declaration.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?  If it's only as part of error recovery,
  /// perhaps we should just re-use methodDeclaration.
  static const MethodDeclarationIdentifierContext operatorName =
      const MethodDeclarationIdentifierContext.continuation();

  /// Identifier is the start of the name being declared by a local function
  /// declaration.
  static const LocalFunctionDeclarationIdentifierContext
      localFunctionDeclaration =
      const LocalFunctionDeclarationIdentifierContext();

  /// Identifier is part of the name being declared by a local function
  /// declaration, but it's not the first identifier of the name.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?
  static const LocalFunctionDeclarationIdentifierContext
      localFunctionDeclarationContinuation =
      const LocalFunctionDeclarationIdentifierContext.continuation();

  /// Identifier is the start of a reference to a constructor declared
  /// elsewhere.
  static const ConstructorReferenceIdentifierContext constructorReference =
      const ConstructorReferenceIdentifierContext();

  /// Identifier is part of a reference to a constructor declared elsewhere, but
  /// it's not the first identifier of the reference.
  static const ConstructorReferenceIdentifierContext
      constructorReferenceContinuation =
      const ConstructorReferenceIdentifierContext.continuation();

  /// Identifier is part of a reference to a constructor declared elsewhere, but
  /// it appears after type parameters (e.g. `foo` in `X<Y>.foo`).
  static const ConstructorReferenceIdentifierContext
      constructorReferenceContinuationAfterTypeArguments =
      const ConstructorReferenceIdentifierContext
          .continuationAfterTypeArguments();

  /// Identifier is the declaration of a label (i.e. it is followed by `:` and
  /// then a statement).
  static const LabelDeclarationIdentifierContext labelDeclaration =
      const LabelDeclarationIdentifierContext();

  /// Identifier is the start of a reference occurring in a literal symbol (e.g.
  /// `foo` in `#foo`).
  static const LiteralSymbolIdentifierContext literalSymbol =
      const LiteralSymbolIdentifierContext();

  /// Identifier is part of a reference occurring in a literal symbol, but it's
  /// not the first identifier of the reference (e.g. `foo` in `#prefix.foo`).
  static const LiteralSymbolIdentifierContext literalSymbolContinuation =
      const LiteralSymbolIdentifierContext.continuation();

  /// Identifier appears in an expression, and it does not immediately follow a
  /// `.`.
  static const ExpressionIdentifierContext expression =
      const ExpressionIdentifierContext();

  /// Identifier appears in an expression, and it immediately follows a `.`.
  static const ExpressionIdentifierContext expressionContinuation =
      const ExpressionIdentifierContext.continuation();

  /// Identifier appears in a show or a hide clause of an extension type
  /// declaration preceded by 'get'.
  static const ExtensionShowHideElementIdentifierContext
      extensionShowHideElementGetter =
      const ExtensionShowHideElementIdentifierContext.getter();

  /// Identifier appears in a show or a hide clause of an extension type
  /// declaration, not preceded by 'get', 'set', or 'operator'.
  static const ExtensionShowHideElementIdentifierContext
      extensionShowHideElementMemberOrType =
      const ExtensionShowHideElementIdentifierContext.memberOrType();

  /// Identifier appears in a show or a hide clause of an extension type
  /// declaration preceded by 'operator'.
  static const ExtensionShowHideElementIdentifierContext
      extensionShowHideElementOperator =
      const ExtensionShowHideElementIdentifierContext.operator();

  /// Identifier appears in a show or a hide clause of an extension type
  /// declaration preceded by 'set'.
  static const ExtensionShowHideElementIdentifierContext
      extensionShowHideElementSetter =
      const ExtensionShowHideElementIdentifierContext.setter();

  /// Identifier is a reference to a named argument of a function or method
  /// invocation (e.g. `foo` in `f(foo: 0);`.
  static const NamedArgumentReferenceIdentifierContext namedArgumentReference =
      const NamedArgumentReferenceIdentifierContext();

  /// Identifier is a name being declared by a local variable declaration.
  static const LocalVariableDeclarationIdentifierContext
      localVariableDeclaration =
      const LocalVariableDeclarationIdentifierContext();

  /// Identifier is a reference to a label (e.g. `foo` in `break foo;`).
  /// Labels have their own scope.
  static const LabelReferenceIdentifierContext labelReference =
      const LabelReferenceIdentifierContext();

  final String _name;

  /// Indicates whether the identifier represents a name which is being
  /// declared.
  final bool inDeclaration;

  /// Indicates whether the identifier is within a `library` or `part of`
  /// declaration.
  final bool inLibraryOrPartOfDeclaration;

  /// Indicates whether the identifier is within a symbol literal.
  final bool inSymbol;

  /// Indicates whether the identifier follows a `.`.
  final bool isContinuation;

  /// Indicates whether the identifier should be looked up in the current scope.
  final bool isScopeReference;

  /// Indicates whether built-in identifiers are allowed in this context.
  final bool isBuiltInIdentifierAllowed;

  /// Indicated whether the identifier is allowed in a context where constant
  /// expressions are required.
  final bool allowedInConstantExpression;

  final Template<_MessageWithArgument<Token>> recoveryTemplate;

  const IdentifierContext(this._name,
      {this.inDeclaration: false,
      this.inLibraryOrPartOfDeclaration: false,
      this.inSymbol: false,
      this.isContinuation: false,
      this.isScopeReference: false,
      this.isBuiltInIdentifierAllowed: true,
      bool? allowedInConstantExpression,
      this.recoveryTemplate: templateExpectedIdentifier})
      : this.allowedInConstantExpression =
            // Generally, declarations are legal in constant expressions.  A
            // continuation doesn't affect constant expressions: if what it's
            // continuing is a problem, it has already been reported.
            allowedInConstantExpression ??
                (inDeclaration || isContinuation || inSymbol);

  String toString() => _name;

  /// Indicates whether the token `new` in this context should be treated as a
  /// valid identifier, under the rules of the "constructor tearoff" feature.
  /// Note that if the feature is disabled, such uses of `new` are still parsed
  /// as identifiers, however the parser will report an appropriate error; this
  /// should allow the best possible error recovery in the event that a user
  /// attempts to use the feature with a language version that doesn't permit
  /// it.
  bool get allowsNewAsIdentifier => false;

  /// Ensure that the next token is an identifier (or keyword which should be
  /// treated as an identifier) and return that identifier.
  /// Report errors as necessary via [parser].
  Token ensureIdentifier(Token token, Parser parser);

  /// Ensure that the next token is an identifier (or keyword which should be
  /// treated as an identifier) and return that identifier.
  /// Report errors as necessary via [parser].
  /// If [recovered] implementers could allow 'token' to be used as an
  /// identifier, even if it isn't a valid identifier.
  Token ensureIdentifierPotentiallyRecovered(
          Token token, Parser parser, bool isRecovered) =>
      ensureIdentifier(token, parser);
}

/// Return `true` if the given [token] should be treated like the start of
/// an expression for the purposes of recovery.
bool looksLikeExpressionStart(Token next) =>
    next.isIdentifier ||
    next.isKeyword && !looksLikeStatementStart(next) ||
    next.type == TokenType.DOUBLE ||
    next.type == TokenType.HASH ||
    next.type == TokenType.HEXADECIMAL ||
    next.type == TokenType.IDENTIFIER ||
    next.type == TokenType.INT ||
    next.type == TokenType.STRING ||
    optional('{', next) ||
    optional('(', next) ||
    optional('[', next) ||
    optional('[]', next) ||
    optional('<', next) ||
    optional('!', next) ||
    optional('-', next) ||
    optional('~', next) ||
    optional('++', next) ||
    optional('--', next);

/// Return `true` if the given [token] should be treated like the start of
/// a new statement for the purposes of recovery.
bool looksLikeStatementStart(Token token) => isOneOfOrEof(token, const [
      '@',
      'assert', 'break', 'continue', 'do', 'else', 'final', 'for', //
      'if', 'return', 'switch', 'try', 'var', 'void', 'while', //
    ]);

// TODO(ahe): Remove when analyzer supports generalized function syntax.
typedef _MessageWithArgument<T> = Message Function(T);

const List<String> okNextValueInFormalParameter = const [
  '=',
  ':',
  ',',
  ')',
  ']',
  '}',
];
