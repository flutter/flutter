// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        LocatedMessage,
        Message,
        templateExperimentNotEnabled,
        templateInternalProblemUnsupported;
import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

/// "Mini AST" representation of a declaration which can accept annotations.
class AnnotatedNode {
  final Comment? documentationComment;

  final List<Annotation> metadata;

  AnnotatedNode(this.documentationComment, List<Annotation>? metadata)
      : metadata = metadata ?? const [];
}

/// "Mini AST" representation of an annotation.
class Annotation {
  final String name;

  final String? constructorName;

  final List<Expression>? arguments;

  Annotation(this.name, this.constructorName, this.arguments);
}

/// "Mini AST" representation of a class declaration.
class ClassDeclaration extends CompilationUnitMember {
  final String name;

  final TypeName? superclass;

  final List<ClassMember> members;

  ClassDeclaration(Comment? documentationComment, List<Annotation>? metadata,
      this.name, this.superclass, this.members)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of a class member.
class ClassMember extends AnnotatedNode {
  ClassMember(Comment? documentationComment, List<Annotation>? metadata)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of a comment.
class Comment {
  final bool isDocumentation;

  final List<Token> tokens;

  factory Comment(Token commentToken) {
    var tokens = <Token>[];
    bool isDocumentation = false;

    Token? token = commentToken;
    while (token != null) {
      if (token.lexeme.startsWith('/**') || token.lexeme.startsWith('///')) {
        isDocumentation = true;
      }
      tokens.add(token);
      token = token.next;
    }
    return Comment._(isDocumentation, tokens);
  }

  Comment._(this.isDocumentation, this.tokens);
}

/// "Mini AST" representation of a CompilationUnit.
class CompilationUnit {
  final declarations = <CompilationUnitMember>[];
}

/// "Mini AST" representation of a top level member of a compilation unit.
class CompilationUnitMember extends AnnotatedNode {
  CompilationUnitMember(
      Comment? documentationComment, List<Annotation>? metadata)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of a constructor declaration.
class ConstructorDeclaration extends ClassMember {
  final String name;

  ConstructorDeclaration(
      Comment? documentationComment, List<Annotation>? metadata, this.name)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of an individual enum constant in an enum
/// declaration.
class EnumConstantDeclaration extends AnnotatedNode {
  final String name;

  EnumConstantDeclaration(
      Comment? documentationComment, List<Annotation>? metadata, this.name)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of an enum declaration.
class EnumDeclaration extends CompilationUnitMember {
  final String name;

  final List<EnumConstantDeclaration> constants;

  EnumDeclaration(Comment? documentationComment, List<Annotation>? metadata,
      this.name, this.constants)
      : super(documentationComment, metadata);
}

/// "Mini AST" representation of an expression.
class Expression {
  String toCode() {
    throw UnimplementedError('$runtimeType');
  }
}

/// "Mini AST" representation of an integer literal.
class IntegerLiteral extends Expression {
  final int value;

  IntegerLiteral(this.value);
}

/// "Mini AST" representation of a list literal.
class ListLiteral extends Expression {
  final Token leftBracket;
  final List<Expression> elements;
  final Token rightBracket;

  ListLiteral(this.leftBracket, this.elements, this.rightBracket);

  @override
  String toCode() {
    return '[' + elements.map((e) => e.toCode()).join(', ') + ']';
  }
}

/// "Mini AST" representation of a method declaration.
class MethodDeclaration extends ClassMember {
  final bool isGetter;

  final String name;

  final TypeName? returnType;

  MethodDeclaration(Comment? documentationComment, List<Annotation>? metadata,
      this.isGetter, this.name, this.returnType)
      : super(documentationComment, metadata);
}

/// Parser listener which generates a "mini AST" representation of the source
/// code.  This representation is just sufficient for summary code generation.
class MiniAstBuilder extends StackListener {
  bool inMetadata = false;

  final compilationUnit = CompilationUnit();

  @override
  Uri get uri => throw UnimplementedError();

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled = false, List<LocatedMessage>? context}) {
    internalProblem(message, charOffset, uri);
  }

  @override
  void beginMetadata(Token token) {
    inMetadata = true;
  }

  @override
  void beginMetadataStar(Token token) {
    debugEvent("beginMetadataStar");
    var precedingComments = token.precedingComments;
    if (precedingComments != null) {
      push(Comment(precedingComments));
    } else {
      push(NullValue.Comments);
    }
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    push(popList(count, List<dynamic>.filled(count, null, growable: true)));
  }

  @override
  void endBinaryExpression(Token token) {
    debugEvent("BinaryExpression");

    if (identical('.', token.stringValue)) {
      var rightOperand = pop() as String;
      var leftOperand = pop();
      if (leftOperand is String && !leftOperand.contains('.')) {
        push(PrefixedIdentifier(leftOperand, token, rightOperand));
      } else {
        push(UnknownExpression());
      }
    } else {
      pop(); // RHS
      pop(); // LHS
      push(UnknownExpression());
    }
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("ClassDeclaration");
    var members = popTypedList<ClassMember>() ?? [];
    var superclass = pop() as TypeName?;
    pop(); // Type variables
    var name = pop() as String;
    var metadata = popTypedList<Annotation>();
    var comment = pop() as Comment?;
    compilationUnit.declarations
        .add(ClassDeclaration(comment, metadata, name, superclass, members));
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("ClassFactoryMethod");
    pop(); // Body
    pop(); // Type variables
    var name = pop() as String;
    var metadata = popTypedList() as List<Annotation>?;
    var comment = pop() as Comment?;
    push(ConstructorDeclaration(comment, metadata, name));
  }

  @override
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("Method");
    pop(); // Body
    pop(); // Initializers
    pop(); // Formal parameters
    pop(); // Type variables
    var name = pop() as String;
    var returnType = pop() as TypeName?;
    var metadata = popTypedList<Annotation>();
    var comment = pop() as Comment?;
    push(MethodDeclaration(
        comment, metadata, getOrSet?.lexeme == 'get', name, returnType));
  }

  @override
  void endClassOrMixinOrExtensionBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassOrMixinBody");
    push(popList(memberCount,
        List<ClassMember?>.filled(memberCount, null, growable: true)));
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("ConditionalUris");
    if (count != 0) {
      internalProblem(
          templateInternalProblemUnsupported.withArguments("Conditional URIs"),
          -1,
          null);
    }
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    debugEvent("Enum");
    var constants =
        List<EnumConstantDeclaration?>.filled(count, null, growable: true);
    popList(count, constants);
    var name = pop() as String;
    var metadata = popTypedList<Annotation>();
    var comment = pop() as Comment?;
    compilationUnit.declarations.add(EnumDeclaration(
        comment, metadata, name, constants.whereNotNull().toList()));
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    debugEvent("FieldInitializer");
    pop(); // Expression
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
    debugEvent("FormalParameter");
    pop(); // Name
    pop(); // Type
    pop(); // Metadata
    pop(); // Comment
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
  }

  @override
  void endImport(Token importKeyword, Token? semicolon) {
    debugEvent("Import");
    pop(NullValue.Prefix); // Prefix identifier
    pop(); // URI
    pop(); // Metadata
    pop(); // Comment
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("LibraryName");
    pop(); // Library name
    pop(); // Metadata
    pop(); // Comment
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    super.endLiteralString(interpolationCount, endToken);
    var value = pop() as String;
    push(StringLiteral(value));
  }

  @override
  void endMember() {
    debugEvent("Member");
  }

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    inMetadata = false;
    var arguments = pop() as List?;
    var constructorName = popIfNotNull(periodBeforeName) as String?;
    pop(); // Type arguments
    var name = pop() as String;
    push(Annotation(name, constructorName,
        arguments == null ? null : arguments.cast<Expression>()));
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    push(
        popList(count, List<Annotation?>.filled(count, null, growable: true)) ??
            NullValue.Metadata);
  }

  @override
  void endShow(Token showKeyword) {
    debugEvent("Show");
    pop(); // Shown names
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
      Token endToken) {
    // We ignore top level variable declarations; they are present just to make
    // the IDL analyze without warnings.
    debugEvent("TopLevelFields");
    popList(count, List<dynamic>.filled(count, null, growable: true)); // Fields
    pop(); // Type
    pop(); // Metadata
    pop(); // Comment
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(popList(count, List<TypeName?>.filled(count, null, growable: true)));
  }

  @override
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    debugEvent("AsyncModifier");
  }

  @override
  void handleClassNoWithClause() {
    debugEvent("NoClassWithClause");
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    debugEvent("ClassWithClause");
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
  }

  @override
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {
    if (isExpressionBody) pop();
    push(NullValue.FunctionBody);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    if (context == IdentifierContext.enumValueDeclaration) {
      var metadata = popTypedList() as List<Annotation>?;
      var comment = pop() as Comment?;
      push(EnumConstantDeclaration(comment, metadata, token.lexeme));
    } else {
      push(token.lexeme);
    }
  }

  @override
  void handleIdentifierList(int count) {
    debugEvent("IdentifierList");
    push(popList(count, List<dynamic>.filled(count, null, growable: true)));
  }

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    debugEvent("ImportPrefix");
    pushIfNull(asKeyword, NullValue.Prefix);
  }

  @override
  void handleInvalidMember(Token endToken) {
    debugEvent("InvalidMember");
    pop(); // metadata star
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration");
    pop(); // metadata star
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("InvalidTypeArguments");
    pop(NullValue.TypeArguments);
  }

  @override
  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    push(IntegerLiteral(int.parse(token.lexeme)));
  }

  @override
  void handleLiteralList(
      int count, Token leftBracket, Token? constKeyword, Token rightBracket) {
    debugEvent("LiteralList");

    var elements = List<Object?>.filled(count, null);
    popList(count, elements);
    pop(); // type arguments

    push(
      ListLiteral(
        leftBracket,
        List<Expression>.from(elements),
        rightBracket,
      ),
    );
  }

  @override
  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(UnknownExpression());
  }

  @override
  void handleNamedArgument(Token colon) {
    var expression = pop() as Expression;
    var name = pop() as String;
    push(NamedExpression(name, colon, expression));
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    debugEvent("NamedMixinApplicationWithClause");
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      pop(); // Pop the native name which is a StringLiteral.
    }
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodyIgnored");
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodySkipped");
    push(NullValue.FunctionBody);
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    reportNonNullAssertExpressionNotEnabled(bang);
  }

  @override
  void handleQualified(Token period) {
    debugEvent("Qualified");
    var suffix = pop() as String;
    var prefix = pop() as String;
    push('$prefix.$suffix');
  }

  @override
  void handleRecoverClassHeader() {
    pop(); // superclass
  }

  @override
  void handleRecoverImport(Token? semicolon) {
    debugEvent("RecoverImport");
    pop(NullValue.Prefix); // Prefix identifier
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    debugEvent("Send");

    var arguments = pop();
    pop(); // Type arguments
    if (arguments != null) {
      pop(); // Receiver
      push(UnknownExpression());
    } else {
      // Property get.
    }
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    debugEvent("Type");
    // reportErrorIfNullableType(questionMark);
    var typeArguments = popTypedList<TypeName>();
    var name = pop() as String;
    push(TypeName(name, typeArguments));
  }

  @override
  internalProblem(Message message, int charOffset, Uri? uri) {
    throw UnsupportedError(message.problemMessage);
  }

  List? popList(int n, List list) {
    if (n == 0) return null;
    return stack.popList(n, list, null);
  }

  /// Calls [pop] and creates a list with the appropriate type parameter `T`
  /// from the resulting `List<dynamic>`.
  List<T>? popTypedList<T>() {
    var list = pop() as List?;
    return list != null ? List<T>.from(list) : null;
  }

  void reportErrorIfNullableType(Token? questionMark) {
    if (questionMark != null) {
      assert(optional('?', questionMark));
      var feature = ExperimentalFeatures.non_nullable;
      handleRecoverableError(
        templateExperimentNotEnabled.withArguments(
          feature.enableString,
          _versionAsString(ExperimentStatus.currentVersion),
        ),
        questionMark,
        questionMark,
      );
    }
  }

  void reportNonNullAssertExpressionNotEnabled(Token bang) {
    var feature = ExperimentalFeatures.non_nullable;
    handleRecoverableError(
      templateExperimentNotEnabled.withArguments(
        feature.enableString,
        _versionAsString(ExperimentStatus.currentVersion),
      ),
      bang,
      bang,
    );
  }

  static String _versionAsString(Version version) {
    return '${version.major}.${version.minor}.${version.patch}';
  }
}

/// Parser intended for use with [MiniAstBuilder].
class MiniAstParser extends Parser {
  MiniAstParser(MiniAstBuilder listener) : super(listener);

  @override
  Token parseArgumentsOpt(Token token) {
    final listener = this.listener as MiniAstBuilder;
    if (listener.inMetadata) {
      return super.parseArgumentsOpt(token);
    } else {
      return skipArgumentsOpt(token);
    }
  }

  @override
  Token parseFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    return skipFunctionBody(token, isExpression, allowAbstract);
  }

  @override
  Token parseInvalidBlock(Token token) => skipBlock(token);
}

/// "Mini AST" representation of a named expression.
class NamedExpression extends Expression {
  final String name;
  final Token colon;
  final Expression expression;

  NamedExpression(this.name, this.colon, this.expression);
}

/// "Mini AST" representation of a named expression.
class PrefixedIdentifier extends Expression {
  final String prefix;
  final Token operator;
  final String identifier;

  PrefixedIdentifier(this.prefix, this.operator, this.identifier);

  @override
  String toCode() {
    return '$prefix.$identifier';
  }
}

/// "Mini AST" representation of a string literal.
class StringLiteral extends Expression {
  final String stringValue;

  StringLiteral(this.stringValue);
}

/// "Mini AST" representation of a type name.
class TypeName {
  final String name;

  final List<TypeName>? typeArguments;

  TypeName(this.name, this.typeArguments);
}

/// "Mini AST" representation of an expression which summary code generation
/// need not be concerned about.
class UnknownExpression extends Expression {}
