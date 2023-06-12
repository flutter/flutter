// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/fasta generate-messages' to update.

// ignore_for_file: lines_longer_than_80_chars

part of _fe_analyzer_shared.messages.codes;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractClassConstructorTearOff =
    messageAbstractClassConstructorTearOff;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractClassConstructorTearOff = const MessageCode(
    "AbstractClassConstructorTearOff",
    problemMessage: r"""Constructors on abstract classes can't be torn off.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateAbstractClassInstantiation =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""The class '#name' is abstract and can't be instantiated.""",
        withArguments: _withArgumentsAbstractClassInstantiation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeAbstractClassInstantiation =
    const Code<Message Function(String name)>("AbstractClassInstantiation",
        analyzerCodes: <String>["NEW_WITH_ABSTRACT_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractClassInstantiation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeAbstractClassInstantiation,
      problemMessage:
          """The class '${name}' is abstract and can't be instantiated.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractClassMember = messageAbstractClassMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractClassMember = const MessageCode(
    "AbstractClassMember",
    index: 51,
    problemMessage:
        r"""Members of classes can't be declared to be 'abstract'.""",
    correctionMessage:
        r"""Try removing the 'abstract' keyword. You can add the 'abstract' keyword before the class declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractExtensionField = messageAbstractExtensionField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractExtensionField = const MessageCode(
    "AbstractExtensionField",
    problemMessage: r"""Extension fields can't be declared 'abstract'.""",
    correctionMessage: r"""Try removing the 'abstract' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractExternalField = messageAbstractExternalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractExternalField = const MessageCode(
    "AbstractExternalField",
    index: 110,
    problemMessage:
        r"""Fields can't be declared both 'abstract' and 'external'.""",
    correctionMessage:
        r"""Try removing the 'abstract' or 'external' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractFieldConstructorInitializer =
    messageAbstractFieldConstructorInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractFieldConstructorInitializer = const MessageCode(
    "AbstractFieldConstructorInitializer",
    problemMessage: r"""Abstract fields cannot have initializers.""",
    correctionMessage:
        r"""Try removing the field initializer or the 'abstract' keyword from the field declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractFieldInitializer = messageAbstractFieldInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractFieldInitializer = const MessageCode(
    "AbstractFieldInitializer",
    problemMessage: r"""Abstract fields cannot have initializers.""",
    correctionMessage:
        r"""Try removing the initializer or the 'abstract' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractLateField = messageAbstractLateField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractLateField = const MessageCode(
    "AbstractLateField",
    index: 108,
    problemMessage: r"""Abstract fields cannot be late.""",
    correctionMessage: r"""Try removing the 'abstract' or 'late' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractNotSync = messageAbstractNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractNotSync = const MessageCode("AbstractNotSync",
    analyzerCodes: <String>["NON_SYNC_ABSTRACT_METHOD"],
    problemMessage:
        r"""Abstract methods can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateAbstractRedirectedClassInstantiation = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Factory redirects to class '#name', which is abstract and can't be instantiated.""",
    withArguments: _withArgumentsAbstractRedirectedClassInstantiation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeAbstractRedirectedClassInstantiation =
    const Code<Message Function(String name)>(
        "AbstractRedirectedClassInstantiation",
        analyzerCodes: <String>["FACTORY_REDIRECTS_TO_ABSTRACT_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractRedirectedClassInstantiation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeAbstractRedirectedClassInstantiation,
      problemMessage:
          """Factory redirects to class '${name}', which is abstract and can't be instantiated.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractStaticField = messageAbstractStaticField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractStaticField = const MessageCode(
    "AbstractStaticField",
    index: 107,
    problemMessage: r"""Static fields can't be declared 'abstract'.""",
    correctionMessage: r"""Try removing the 'abstract' or 'static' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateAccessError =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Access error: '#name'.""",
        withArguments: _withArgumentsAccessError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeAccessError =
    const Code<Message Function(String name)>(
  "AccessError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAccessError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeAccessError,
      problemMessage: """Access error: '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAgnosticWithStrongDillLibrary =
    messageAgnosticWithStrongDillLibrary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAgnosticWithStrongDillLibrary = const MessageCode(
    "AgnosticWithStrongDillLibrary",
    problemMessage:
        r"""Loaded library is compiled with sound null safety and cannot be used in compilation for agnostic null safety.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAgnosticWithWeakDillLibrary =
    messageAgnosticWithWeakDillLibrary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAgnosticWithWeakDillLibrary = const MessageCode(
    "AgnosticWithWeakDillLibrary",
    problemMessage:
        r"""Loaded library is compiled with unsound null safety and cannot be used in compilation for agnostic null safety.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAmbiguousExtensionCause = messageAmbiguousExtensionCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAmbiguousExtensionCause = const MessageCode(
    "AmbiguousExtensionCause",
    severity: Severity.context,
    problemMessage: r"""This is one of the extension members.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAnnotationOnFunctionTypeTypeVariable =
    messageAnnotationOnFunctionTypeTypeVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnnotationOnFunctionTypeTypeVariable =
    const MessageCode("AnnotationOnFunctionTypeTypeVariable",
        problemMessage:
            r"""A type variable on a function type can't have annotations.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAnnotationOnTypeArgument = messageAnnotationOnTypeArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnnotationOnTypeArgument = const MessageCode(
    "AnnotationOnTypeArgument",
    index: 111,
    problemMessage:
        r"""Type arguments can't have annotations because they aren't declarations.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAnonymousBreakTargetOutsideFunction =
    messageAnonymousBreakTargetOutsideFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnonymousBreakTargetOutsideFunction =
    const MessageCode(
        "AnonymousBreakTargetOutsideFunction",
        analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"],
        problemMessage:
            r"""Can't break to a target in a different function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAnonymousContinueTargetOutsideFunction =
    messageAnonymousContinueTargetOutsideFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAnonymousContinueTargetOutsideFunction =
    const MessageCode(
        "AnonymousContinueTargetOutsideFunction",
        analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"],
        problemMessage:
            r"""Can't continue at a target in a different function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int
            codePoint)> templateAsciiControlCharacter = const Template<
        Message Function(int codePoint)>(
    problemMessageTemplate:
        r"""The control character #unicode can only be used in strings and comments.""",
    withArguments: _withArgumentsAsciiControlCharacter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int codePoint)> codeAsciiControlCharacter =
    const Code<Message Function(int codePoint)>("AsciiControlCharacter",
        analyzerCodes: <String>["ILLEGAL_CHARACTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAsciiControlCharacter(int codePoint) {
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(codeAsciiControlCharacter,
      problemMessage:
          """The control character ${unicode} can only be used in strings and comments.""",
      arguments: {'unicode': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAssertAsExpression = messageAssertAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertAsExpression = const MessageCode(
    "AssertAsExpression",
    problemMessage: r"""`assert` can't be used as an expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAssertExtraneousArgument = messageAssertExtraneousArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertExtraneousArgument = const MessageCode(
    "AssertExtraneousArgument",
    problemMessage: r"""`assert` can't have more than two arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitAsIdentifier = messageAwaitAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitAsIdentifier = const MessageCode(
    "AwaitAsIdentifier",
    analyzerCodes: <String>["ASYNC_KEYWORD_USED_AS_IDENTIFIER"],
    problemMessage:
        r"""'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitForNotAsync = messageAwaitForNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitForNotAsync = const MessageCode(
    "AwaitForNotAsync",
    analyzerCodes: <String>["ASYNC_FOR_IN_WRONG_CONTEXT"],
    problemMessage:
        r"""The asynchronous for-in can only be used in functions marked with 'async' or 'async*'.""",
    correctionMessage:
        r"""Try marking the function body with either 'async' or 'async*', or removing the 'await' before the for loop.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitInLateLocalInitializer =
    messageAwaitInLateLocalInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitInLateLocalInitializer = const MessageCode(
    "AwaitInLateLocalInitializer",
    problemMessage:
        r"""`await` expressions are not supported in late local initializers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitNotAsync = messageAwaitNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitNotAsync = const MessageCode("AwaitNotAsync",
    analyzerCodes: <String>["AWAIT_IN_WRONG_CONTEXT"],
    problemMessage:
        r"""'await' can only be used in 'async' or 'async*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateBinaryOperatorWrittenOut = const Template<
        Message Function(String string, String string2)>(
    problemMessageTemplate:
        r"""Binary operator '#string' is written as '#string2' instead of the written out word.""",
    correctionMessageTemplate: r"""Try replacing '#string' with '#string2'.""",
    withArguments: _withArgumentsBinaryOperatorWrittenOut);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeBinaryOperatorWrittenOut =
    const Code<Message Function(String string, String string2)>(
        "BinaryOperatorWrittenOut",
        index: 112);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBinaryOperatorWrittenOut(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeBinaryOperatorWrittenOut,
      problemMessage:
          """Binary operator '${string}' is written as '${string2}' instead of the written out word.""",
      correctionMessage: """Try replacing '${string}' with '${string2}'.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateBoundIssueViaCycleNonSimplicity = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""Generic type '#name' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '#name2'.""",
    correctionMessageTemplate:
        r"""Try providing type arguments to '#name2' here or to some other raw types in the bounds along the reference chain.""",
    withArguments: _withArgumentsBoundIssueViaCycleNonSimplicity);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeBoundIssueViaCycleNonSimplicity =
    const Code<Message Function(String name, String name2)>(
        "BoundIssueViaCycleNonSimplicity",
        analyzerCodes: <String>["NOT_INSTANTIATED_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaCycleNonSimplicity(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeBoundIssueViaCycleNonSimplicity,
      problemMessage:
          """Generic type '${name}' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '${name2}'.""",
      correctionMessage: """Try providing type arguments to '${name2}' here or to some other raw types in the bounds along the reference chain.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateBoundIssueViaLoopNonSimplicity = const Template<
        Message Function(
            String name)>(
    problemMessageTemplate:
        r"""Generic type '#name' can't be used without type arguments in the bounds of its own type variables.""",
    correctionMessageTemplate:
        r"""Try providing type arguments to '#name' here.""",
    withArguments: _withArgumentsBoundIssueViaLoopNonSimplicity);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeBoundIssueViaLoopNonSimplicity =
    const Code<Message Function(String name)>("BoundIssueViaLoopNonSimplicity",
        analyzerCodes: <String>["NOT_INSTANTIATED_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaLoopNonSimplicity(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeBoundIssueViaLoopNonSimplicity,
      problemMessage:
          """Generic type '${name}' can't be used without type arguments in the bounds of its own type variables.""",
      correctionMessage: """Try providing type arguments to '${name}' here.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateBoundIssueViaRawTypeWithNonSimpleBounds =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Generic type '#name' can't be used without type arguments in a type variable bound.""",
        correctionMessageTemplate:
            r"""Try providing type arguments to '#name' here.""",
        withArguments: _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeBoundIssueViaRawTypeWithNonSimpleBounds =
    const Code<Message Function(String name)>(
        "BoundIssueViaRawTypeWithNonSimpleBounds",
        analyzerCodes: <String>["NOT_INSTANTIATED_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBoundIssueViaRawTypeWithNonSimpleBounds(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeBoundIssueViaRawTypeWithNonSimpleBounds,
      problemMessage:
          """Generic type '${name}' can't be used without type arguments in a type variable bound.""",
      correctionMessage: """Try providing type arguments to '${name}' here.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeBreakOutsideOfLoop = messageBreakOutsideOfLoop;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageBreakOutsideOfLoop = const MessageCode(
    "BreakOutsideOfLoop",
    index: 52,
    problemMessage:
        r"""A break statement can't be used outside of a loop or switch statement.""",
    correctionMessage: r"""Try removing the break statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateBreakTargetOutsideFunction =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't break to '#name' in a different function.""",
        withArguments: _withArgumentsBreakTargetOutsideFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeBreakTargetOutsideFunction =
    const Code<Message Function(String name)>("BreakTargetOutsideFunction",
        analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBreakTargetOutsideFunction(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeBreakTargetOutsideFunction,
      problemMessage: """Can't break to '${name}' in a different function.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateBuiltInIdentifierAsType =
    const Template<Message Function(Token token)>(
        problemMessageTemplate:
            r"""The built-in identifier '#lexeme' can't be used as a type.""",
        withArguments: _withArgumentsBuiltInIdentifierAsType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeBuiltInIdentifierAsType =
    const Code<Message Function(Token token)>("BuiltInIdentifierAsType",
        analyzerCodes: <String>["BUILT_IN_IDENTIFIER_AS_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierAsType(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeBuiltInIdentifierAsType,
      problemMessage:
          """The built-in identifier '${lexeme}' can't be used as a type.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateBuiltInIdentifierInDeclaration =
    const Template<Message Function(Token token)>(
        problemMessageTemplate: r"""Can't use '#lexeme' as a name here.""",
        withArguments: _withArgumentsBuiltInIdentifierInDeclaration);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeBuiltInIdentifierInDeclaration =
    const Code<Message Function(Token token)>("BuiltInIdentifierInDeclaration",
        analyzerCodes: <String>["BUILT_IN_IDENTIFIER_IN_DECLARATION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierInDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeBuiltInIdentifierInDeclaration,
      problemMessage: """Can't use '${lexeme}' as a name here.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCandidateFound = messageCandidateFound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCandidateFound = const MessageCode("CandidateFound",
    severity: Severity.context,
    problemMessage:
        r"""Found this candidate, but the arguments don't match.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCandidateFoundIsDefaultConstructor =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""The class '#name' has a constructor that takes no arguments.""",
        withArguments: _withArgumentsCandidateFoundIsDefaultConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeCandidateFoundIsDefaultConstructor =
    const Code<Message Function(String name)>(
        "CandidateFoundIsDefaultConstructor",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCandidateFoundIsDefaultConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCandidateFoundIsDefaultConstructor,
      problemMessage:
          """The class '${name}' has a constructor that takes no arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String name)> templateCannotAssignToConstVariable =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't assign to the const variable '#name'.""",
        withArguments: _withArgumentsCannotAssignToConstVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCannotAssignToConstVariable =
    const Code<Message Function(String name)>(
  "CannotAssignToConstVariable",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToConstVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCannotAssignToConstVariable,
      problemMessage: """Can't assign to the const variable '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCannotAssignToExtensionThis =
    messageCannotAssignToExtensionThis;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToExtensionThis = const MessageCode(
    "CannotAssignToExtensionThis",
    problemMessage: r"""Can't assign to 'this'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String name)> templateCannotAssignToFinalVariable =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't assign to the final variable '#name'.""",
        withArguments: _withArgumentsCannotAssignToFinalVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCannotAssignToFinalVariable =
    const Code<Message Function(String name)>(
  "CannotAssignToFinalVariable",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotAssignToFinalVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCannotAssignToFinalVariable,
      problemMessage: """Can't assign to the final variable '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCannotAssignToParenthesizedExpression =
    messageCannotAssignToParenthesizedExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToParenthesizedExpression =
    const MessageCode("CannotAssignToParenthesizedExpression",
        analyzerCodes: <String>["ASSIGNMENT_TO_PARENTHESIZED_EXPRESSION"],
        problemMessage: r"""Can't assign to a parenthesized expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCannotAssignToSuper = messageCannotAssignToSuper;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToSuper = const MessageCode(
    "CannotAssignToSuper",
    analyzerCodes: <String>["NOT_AN_LVALUE"],
    problemMessage: r"""Can't assign to super.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCannotAssignToTypeLiteral =
    messageCannotAssignToTypeLiteral;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCannotAssignToTypeLiteral = const MessageCode(
    "CannotAssignToTypeLiteral",
    problemMessage: r"""Can't assign to a type literal.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateCannotReadSdkSpecification =
    const Template<Message Function(String string)>(
        problemMessageTemplate:
            r"""Unable to read the 'libraries.json' specification file:
  #string.""",
        withArguments: _withArgumentsCannotReadSdkSpecification);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeCannotReadSdkSpecification =
    const Code<Message Function(String string)>(
  "CannotReadSdkSpecification",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCannotReadSdkSpecification(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeCannotReadSdkSpecification,
      problemMessage: """Unable to read the 'libraries.json' specification file:
  ${string}.""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantDisambiguateAmbiguousInformation =
    messageCantDisambiguateAmbiguousInformation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantDisambiguateAmbiguousInformation = const MessageCode(
    "CantDisambiguateAmbiguousInformation",
    problemMessage:
        r"""Both Iterable and Map spread elements encountered in ambiguous literal.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantDisambiguateNotEnoughInformation =
    messageCantDisambiguateNotEnoughInformation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantDisambiguateNotEnoughInformation = const MessageCode(
    "CantDisambiguateNotEnoughInformation",
    problemMessage:
        r"""Not enough type information to disambiguate between literal set and literal map.""",
    correctionMessage:
        r"""Try providing type arguments for the literal explicitly to disambiguate it.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantInferPackagesFromManyInputs =
    messageCantInferPackagesFromManyInputs;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantInferPackagesFromManyInputs = const MessageCode(
    "CantInferPackagesFromManyInputs",
    problemMessage:
        r"""Can't infer a packages file when compiling multiple inputs.""",
    correctionMessage:
        r"""Try specifying the file explicitly with the --packages option.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantInferPackagesFromPackageUri =
    messageCantInferPackagesFromPackageUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantInferPackagesFromPackageUri = const MessageCode(
    "CantInferPackagesFromPackageUri",
    problemMessage:
        r"""Can't infer a packages file from an input 'package:*' URI.""",
    correctionMessage:
        r"""Try specifying the file explicitly with the --packages option.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCantInferReturnTypeDueToNoCombinedSignature =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't infer a return type for '#name' as the overridden members don't have a combined signature.""",
        correctionMessageTemplate: r"""Try adding an explicit type.""",
        withArguments:
            _withArgumentsCantInferReturnTypeDueToNoCombinedSignature);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeCantInferReturnTypeDueToNoCombinedSignature =
    const Code<Message Function(String name)>(
        "CantInferReturnTypeDueToNoCombinedSignature",
        analyzerCodes: <String>[
      "COMPILE_TIME_ERROR.NO_COMBINED_SUPER_SIGNATURE"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferReturnTypeDueToNoCombinedSignature(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCantInferReturnTypeDueToNoCombinedSignature,
      problemMessage:
          """Can't infer a return type for '${name}' as the overridden members don't have a combined signature.""",
      correctionMessage: """Try adding an explicit type.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateCantInferTypeDueToCircularity = const Template<
        Message Function(String string)>(
    problemMessageTemplate:
        r"""Can't infer the type of '#string': circularity found during type inference.""",
    correctionMessageTemplate: r"""Specify the type explicitly.""",
    withArguments: _withArgumentsCantInferTypeDueToCircularity);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeCantInferTypeDueToCircularity =
    const Code<Message Function(String string)>("CantInferTypeDueToCircularity",
        analyzerCodes: <String>["RECURSIVE_COMPILE_TIME_CONSTANT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToCircularity(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeCantInferTypeDueToCircularity,
      problemMessage:
          """Can't infer the type of '${string}': circularity found during type inference.""",
      correctionMessage: """Specify the type explicitly.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateCantInferTypeDueToNoCombinedSignature = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Can't infer a type for '#name' as the overridden members don't have a combined signature.""",
    correctionMessageTemplate: r"""Try adding an explicit type.""",
    withArguments: _withArgumentsCantInferTypeDueToNoCombinedSignature);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeCantInferTypeDueToNoCombinedSignature =
    const Code<Message Function(String name)>(
        "CantInferTypeDueToNoCombinedSignature",
        analyzerCodes: <String>[
      "COMPILE_TIME_ERROR.NO_COMBINED_SUPER_SIGNATURE"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypeDueToNoCombinedSignature(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCantInferTypeDueToNoCombinedSignature,
      problemMessage:
          """Can't infer a type for '${name}' as the overridden members don't have a combined signature.""",
      correctionMessage: """Try adding an explicit type.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateCantInferTypesDueToNoCombinedSignature = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Can't infer types for '#name' as the overridden members don't have a combined signature.""",
    correctionMessageTemplate: r"""Try adding explicit types.""",
    withArguments: _withArgumentsCantInferTypesDueToNoCombinedSignature);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeCantInferTypesDueToNoCombinedSignature =
    const Code<Message Function(String name)>(
        "CantInferTypesDueToNoCombinedSignature",
        analyzerCodes: <String>[
      "COMPILE_TIME_ERROR.NO_COMBINED_SUPER_SIGNATURE"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantInferTypesDueToNoCombinedSignature(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCantInferTypesDueToNoCombinedSignature,
      problemMessage:
          """Can't infer types for '${name}' as the overridden members don't have a combined signature.""",
      correctionMessage: """Try adding explicit types.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string)> templateCantReadFile =
    const Template<Message Function(Uri uri_, String string)>(
        problemMessageTemplate: r"""Error when reading '#uri': #string""",
        withArguments: _withArgumentsCantReadFile);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, String string)> codeCantReadFile =
    const Code<Message Function(Uri uri_, String string)>("CantReadFile",
        analyzerCodes: <String>["URI_DOES_NOT_EXIST"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantReadFile(Uri uri_, String string) {
  String? uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeCantReadFile,
      problemMessage: """Error when reading '${uri}': ${string}""",
      arguments: {'uri': uri_, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateCantUseControlFlowOrSpreadAsConstant =
    const Template<Message Function(Token token)>(
        problemMessageTemplate:
            r"""'#lexeme' is not supported in constant expressions.""",
        withArguments: _withArgumentsCantUseControlFlowOrSpreadAsConstant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)>
    codeCantUseControlFlowOrSpreadAsConstant =
    const Code<Message Function(Token token)>(
        "CantUseControlFlowOrSpreadAsConstant",
        analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseControlFlowOrSpreadAsConstant(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeCantUseControlFlowOrSpreadAsConstant,
      problemMessage:
          """'${lexeme}' is not supported in constant expressions.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Token
            token)> templateCantUseDeferredPrefixAsConstant = const Template<
        Message Function(Token token)>(
    problemMessageTemplate:
        r"""'#lexeme' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    correctionMessageTemplate:
        r"""Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
    withArguments: _withArgumentsCantUseDeferredPrefixAsConstant);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeCantUseDeferredPrefixAsConstant =
    const Code<Message Function(Token token)>("CantUseDeferredPrefixAsConstant",
        analyzerCodes: <String>["CONST_DEFERRED_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCantUseDeferredPrefixAsConstant(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeCantUseDeferredPrefixAsConstant,
      problemMessage:
          """'${lexeme}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
      correctionMessage: """Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantUsePrefixAsExpression =
    messageCantUsePrefixAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantUsePrefixAsExpression = const MessageCode(
    "CantUsePrefixAsExpression",
    analyzerCodes: <String>["PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT"],
    problemMessage: r"""A prefix can't be used as an expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCantUsePrefixWithNullAware =
    messageCantUsePrefixWithNullAware;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCantUsePrefixWithNullAware = const MessageCode(
    "CantUsePrefixWithNullAware",
    analyzerCodes: <String>["PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT"],
    problemMessage: r"""A prefix can't be used with null-aware operators.""",
    correctionMessage: r"""Try replacing '?.' with '.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCatchSyntax = messageCatchSyntax;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCatchSyntax = const MessageCode("CatchSyntax",
    index: 84,
    problemMessage:
        r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
    correctionMessage:
        r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCatchSyntaxExtraParameters =
    messageCatchSyntaxExtraParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCatchSyntaxExtraParameters = const MessageCode(
    "CatchSyntaxExtraParameters",
    index: 83,
    problemMessage:
        r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
    correctionMessage:
        r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeClassInClass = messageClassInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageClassInClass = const MessageCode("ClassInClass",
    index: 53,
    problemMessage: r"""Classes can't be declared inside other classes.""",
    correctionMessage: r"""Try moving the class to the top-level.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateClassInNullAwareReceiver =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""The class '#name' cannot be null.""",
        correctionMessageTemplate: r"""Try replacing '?.' with '.'""",
        withArguments: _withArgumentsClassInNullAwareReceiver);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeClassInNullAwareReceiver =
    const Code<Message Function(String name)>("ClassInNullAwareReceiver",
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsClassInNullAwareReceiver(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeClassInNullAwareReceiver,
      problemMessage: """The class '${name}' cannot be null.""",
      correctionMessage: """Try replacing '?.' with '.'""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeColonInPlaceOfIn = messageColonInPlaceOfIn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageColonInPlaceOfIn = const MessageCode(
    "ColonInPlaceOfIn",
    index: 54,
    problemMessage: r"""For-in loops use 'in' rather than a colon.""",
    correctionMessage: r"""Try replacing the colon with the keyword 'in'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateCombinedMemberSignatureFailed = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""Class '#name' inherits multiple members named '#name2' with incompatible signatures.""",
    correctionMessageTemplate:
        r"""Try adding a declaration of '#name2' to '#name'.""",
    withArguments: _withArgumentsCombinedMemberSignatureFailed);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeCombinedMemberSignatureFailed =
    const Code<Message Function(String name, String name2)>(
        "CombinedMemberSignatureFailed",
        analyzerCodes: <String>["INCONSISTENT_INHERITANCE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCombinedMemberSignatureFailed(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeCombinedMemberSignatureFailed,
      problemMessage:
          """Class '${name}' inherits multiple members named '${name2}' with incompatible signatures.""",
      correctionMessage: """Try adding a declaration of '${name2}' to '${name}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCompilingWithSoundNullSafety =
    messageCompilingWithSoundNullSafety;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCompilingWithSoundNullSafety = const MessageCode(
    "CompilingWithSoundNullSafety",
    severity: Severity.info,
    problemMessage: r"""Compiling with sound null safety""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCompilingWithoutSoundNullSafety =
    messageCompilingWithoutSoundNullSafety;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCompilingWithoutSoundNullSafety = const MessageCode(
    "CompilingWithoutSoundNullSafety",
    severity: Severity.info,
    problemMessage: r"""Compiling without sound null safety""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateConflictingModifiers = const Template<
        Message Function(String string, String string2)>(
    problemMessageTemplate:
        r"""Members can't be declared to be both '#string' and '#string2'.""",
    correctionMessageTemplate: r"""Try removing one of the keywords.""",
    withArguments: _withArgumentsConflictingModifiers);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeConflictingModifiers =
    const Code<Message Function(String string, String string2)>(
        "ConflictingModifiers",
        index: 59);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictingModifiers(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeConflictingModifiers,
      problemMessage:
          """Members can't be declared to be both '${string}' and '${string2}'.""",
      correctionMessage: """Try removing one of the keywords.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConflictsWithConstructor =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Conflicts with constructor '#name'.""",
        withArguments: _withArgumentsConflictsWithConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithConstructor =
    const Code<Message Function(String name)>("ConflictsWithConstructor",
        analyzerCodes: <String>["CONFLICTS_WITH_CONSTRUCTOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithConstructor,
      problemMessage: """Conflicts with constructor '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConflictsWithFactory =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Conflicts with factory '#name'.""",
        withArguments: _withArgumentsConflictsWithFactory);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithFactory =
    const Code<Message Function(String name)>(
  "ConflictsWithFactory",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithFactory(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithFactory,
      problemMessage: """Conflicts with factory '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConflictsWithImplicitSetter =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Conflicts with the implicit setter of the field '#name'.""",
        withArguments: _withArgumentsConflictsWithImplicitSetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithImplicitSetter =
    const Code<Message Function(String name)>("ConflictsWithImplicitSetter",
        analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithImplicitSetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithImplicitSetter,
      problemMessage:
          """Conflicts with the implicit setter of the field '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConflictsWithMember =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Conflicts with member '#name'.""",
        withArguments: _withArgumentsConflictsWithMember);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithMember =
    const Code<Message Function(String name)>("ConflictsWithMember",
        analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithMember,
      problemMessage: """Conflicts with member '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConflictsWithSetter =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Conflicts with setter '#name'.""",
        withArguments: _withArgumentsConflictsWithSetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithSetter =
    const Code<Message Function(String name)>("ConflictsWithSetter",
        analyzerCodes: <String>["CONFLICTS_WITH_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithSetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithSetter,
      problemMessage: """Conflicts with setter '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConflictsWithTypeVariable =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Conflicts with type variable '#name'.""",
        withArguments: _withArgumentsConflictsWithTypeVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConflictsWithTypeVariable =
    const Code<Message Function(String name)>("ConflictsWithTypeVariable",
        analyzerCodes: <String>["CONFLICTING_TYPE_VARIABLE_AND_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictsWithTypeVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConflictsWithTypeVariable,
      problemMessage: """Conflicts with type variable '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConflictsWithTypeVariableCause =
    messageConflictsWithTypeVariableCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConflictsWithTypeVariableCause = const MessageCode(
    "ConflictsWithTypeVariableCause",
    severity: Severity.context,
    problemMessage: r"""This is the type variable.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstAndFinal = messageConstAndFinal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstAndFinal = const MessageCode("ConstAndFinal",
    index: 58,
    problemMessage:
        r"""Members can't be declared to be both 'const' and 'final'.""",
    correctionMessage:
        r"""Try removing either the 'const' or 'final' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstClass = messageConstClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstClass = const MessageCode("ConstClass",
    index: 60,
    problemMessage: r"""Classes can't be declared to be 'const'.""",
    correctionMessage:
        r"""Try removing the 'const' keyword. If you're trying to indicate that instances of the class can be constants, place the 'const' keyword on  the class' constructor(s).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorLateFinalFieldCause =
    messageConstConstructorLateFinalFieldCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorLateFinalFieldCause =
    const MessageCode("ConstConstructorLateFinalFieldCause",
        severity: Severity.context,
        problemMessage: r"""This constructor is const.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorLateFinalFieldError =
    messageConstConstructorLateFinalFieldError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorLateFinalFieldError = const MessageCode(
    "ConstConstructorLateFinalFieldError",
    problemMessage:
        r"""Can't have a late final field in a class with a const constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorNonFinalField =
    messageConstConstructorNonFinalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorNonFinalField = const MessageCode(
    "ConstConstructorNonFinalField",
    analyzerCodes: <String>["CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD"],
    problemMessage:
        r"""Constructor is marked 'const' so all fields must be final.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorNonFinalFieldCause =
    messageConstConstructorNonFinalFieldCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorNonFinalFieldCause = const MessageCode(
    "ConstConstructorNonFinalFieldCause",
    severity: Severity.context,
    problemMessage: r"""Field isn't final, but constructor is 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorRedirectionToNonConst =
    messageConstConstructorRedirectionToNonConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorRedirectionToNonConst =
    const MessageCode("ConstConstructorRedirectionToNonConst",
        problemMessage:
            r"""A constant constructor can't call a non-constant constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorWithBody = messageConstConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorWithBody = const MessageCode(
    "ConstConstructorWithBody",
    analyzerCodes: <String>["CONST_CONSTRUCTOR_WITH_BODY"],
    problemMessage: r"""A const constructor can't have a body.""",
    correctionMessage:
        r"""Try removing either the 'const' keyword or the body.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstConstructorWithNonConstSuper =
    messageConstConstructorWithNonConstSuper;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstConstructorWithNonConstSuper = const MessageCode(
    "ConstConstructorWithNonConstSuper",
    analyzerCodes: <String>["CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER"],
    problemMessage:
        r"""A constant constructor can't call a non-constant super constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalCircularity = messageConstEvalCircularity;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalCircularity = const MessageCode(
    "ConstEvalCircularity",
    analyzerCodes: <String>["RECURSIVE_COMPILE_TIME_CONSTANT"],
    problemMessage: r"""Constant expression depends on itself.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalContext = messageConstEvalContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalContext = const MessageCode(
    "ConstEvalContext",
    problemMessage: r"""While analyzing:""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            nameOKEmpty)> templateConstEvalDeferredLibrary = const Template<
        Message Function(String nameOKEmpty)>(
    problemMessageTemplate:
        r"""'#nameOKEmpty' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
    correctionMessageTemplate:
        r"""Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
    withArguments: _withArgumentsConstEvalDeferredLibrary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String nameOKEmpty)> codeConstEvalDeferredLibrary =
    const Code<Message Function(String nameOKEmpty)>("ConstEvalDeferredLibrary",
        analyzerCodes: <String>[
      "INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalDeferredLibrary(String nameOKEmpty) {
  // ignore: unnecessary_null_comparison
  if (nameOKEmpty == null || nameOKEmpty.isEmpty) nameOKEmpty = '(unnamed)';
  return new Message(codeConstEvalDeferredLibrary,
      problemMessage:
          """'${nameOKEmpty}' can't be used in a constant expression because it's marked as 'deferred' which means it isn't available until loaded.""",
      correctionMessage: """Try moving the constant from the deferred library, or removing 'deferred' from the import.
""",
      arguments: {'nameOKEmpty': nameOKEmpty});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateConstEvalError =
    const Template<Message Function(String string)>(
        problemMessageTemplate:
            r"""Error evaluating constant expression: #string""",
        withArguments: _withArgumentsConstEvalError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeConstEvalError =
    const Code<Message Function(String string)>(
  "ConstEvalError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalError(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeConstEvalError,
      problemMessage: """Error evaluating constant expression: ${string}""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalExtension = messageConstEvalExtension;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalExtension = const MessageCode(
    "ConstEvalExtension",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    problemMessage:
        r"""Extension operations can't be used in constant expressions.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalExternalConstructor =
    messageConstEvalExternalConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalExternalConstructor = const MessageCode(
    "ConstEvalExternalConstructor",
    problemMessage:
        r"""External constructors can't be evaluated in constant expressions.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalExternalFactory = messageConstEvalExternalFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalExternalFactory = const MessageCode(
    "ConstEvalExternalFactory",
    problemMessage:
        r"""External factory constructors can't be evaluated in constant expressions.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalFailedAssertion = messageConstEvalFailedAssertion;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalFailedAssertion = const MessageCode(
    "ConstEvalFailedAssertion",
    analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    problemMessage: r"""This assertion failed.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String stringOKEmpty)>
    templateConstEvalFailedAssertionWithMessage =
    const Template<Message Function(String stringOKEmpty)>(
        problemMessageTemplate:
            r"""This assertion failed with message: #stringOKEmpty""",
        withArguments: _withArgumentsConstEvalFailedAssertionWithMessage);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String stringOKEmpty)>
    codeConstEvalFailedAssertionWithMessage =
    const Code<Message Function(String stringOKEmpty)>(
        "ConstEvalFailedAssertionWithMessage",
        analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalFailedAssertionWithMessage(
    String stringOKEmpty) {
  // ignore: unnecessary_null_comparison
  if (stringOKEmpty == null || stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  return new Message(codeConstEvalFailedAssertionWithMessage,
      problemMessage:
          """This assertion failed with message: ${stringOKEmpty}""",
      arguments: {'stringOKEmpty': stringOKEmpty});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String nameOKEmpty)>
    templateConstEvalGetterNotFound =
    const Template<Message Function(String nameOKEmpty)>(
        problemMessageTemplate: r"""Variable get not found: '#nameOKEmpty'""",
        withArguments: _withArgumentsConstEvalGetterNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String nameOKEmpty)> codeConstEvalGetterNotFound =
    const Code<Message Function(String nameOKEmpty)>(
  "ConstEvalGetterNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalGetterNotFound(String nameOKEmpty) {
  // ignore: unnecessary_null_comparison
  if (nameOKEmpty == null || nameOKEmpty.isEmpty) nameOKEmpty = '(unnamed)';
  return new Message(codeConstEvalGetterNotFound,
      problemMessage: """Variable get not found: '${nameOKEmpty}'""",
      arguments: {'nameOKEmpty': nameOKEmpty});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String nameOKEmpty)>
    templateConstEvalInvalidStaticInvocation =
    const Template<Message Function(String nameOKEmpty)>(
        problemMessageTemplate:
            r"""The invocation of '#nameOKEmpty' is not allowed in a constant expression.""",
        withArguments: _withArgumentsConstEvalInvalidStaticInvocation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String nameOKEmpty)>
    codeConstEvalInvalidStaticInvocation =
    const Code<Message Function(String nameOKEmpty)>(
        "ConstEvalInvalidStaticInvocation",
        analyzerCodes: <String>["CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalInvalidStaticInvocation(String nameOKEmpty) {
  // ignore: unnecessary_null_comparison
  if (nameOKEmpty == null || nameOKEmpty.isEmpty) nameOKEmpty = '(unnamed)';
  return new Message(codeConstEvalInvalidStaticInvocation,
      problemMessage:
          """The invocation of '${nameOKEmpty}' is not allowed in a constant expression.""",
      arguments: {'nameOKEmpty': nameOKEmpty});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String string2,
        String
            string3)> templateConstEvalNegativeShift = const Template<
        Message Function(String string, String string2, String string3)>(
    problemMessageTemplate:
        r"""Binary operator '#string' on '#string2' requires non-negative operand, but was '#string3'.""",
    withArguments: _withArgumentsConstEvalNegativeShift);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2, String string3)>
    codeConstEvalNegativeShift =
    const Code<Message Function(String string, String string2, String string3)>(
  "ConstEvalNegativeShift",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNegativeShift(
    String string, String string2, String string3) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (string3.isEmpty) throw 'No string provided';
  return new Message(codeConstEvalNegativeShift,
      problemMessage:
          """Binary operator '${string}' on '${string2}' requires non-negative operand, but was '${string3}'.""",
      arguments: {'string': string, 'string2': string2, 'string3': string3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            nameOKEmpty)> templateConstEvalNonConstantVariableGet = const Template<
        Message Function(String nameOKEmpty)>(
    problemMessageTemplate:
        r"""The variable '#nameOKEmpty' is not a constant, only constant expressions are allowed.""",
    withArguments: _withArgumentsConstEvalNonConstantVariableGet);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String nameOKEmpty)>
    codeConstEvalNonConstantVariableGet =
    const Code<Message Function(String nameOKEmpty)>(
        "ConstEvalNonConstantVariableGet",
        analyzerCodes: <String>["NON_CONSTANT_VALUE_IN_INITIALIZER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalNonConstantVariableGet(String nameOKEmpty) {
  // ignore: unnecessary_null_comparison
  if (nameOKEmpty == null || nameOKEmpty.isEmpty) nameOKEmpty = '(unnamed)';
  return new Message(codeConstEvalNonConstantVariableGet,
      problemMessage:
          """The variable '${nameOKEmpty}' is not a constant, only constant expressions are allowed.""",
      arguments: {'nameOKEmpty': nameOKEmpty});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalNonNull = messageConstEvalNonNull;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNonNull = const MessageCode(
    "ConstEvalNonNull",
    problemMessage: r"""Constant expression must be non-null.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalNotListOrSetInSpread =
    messageConstEvalNotListOrSetInSpread;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNotListOrSetInSpread = const MessageCode(
    "ConstEvalNotListOrSetInSpread",
    analyzerCodes: <String>["CONST_SPREAD_EXPECTED_LIST_OR_SET"],
    problemMessage:
        r"""Only lists and sets can be used in spreads in constant lists and sets.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalNotMapInSpread = messageConstEvalNotMapInSpread;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNotMapInSpread = const MessageCode(
    "ConstEvalNotMapInSpread",
    analyzerCodes: <String>["CONST_SPREAD_EXPECTED_MAP"],
    problemMessage: r"""Only maps can be used in spreads in constant maps.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalNullValue = messageConstEvalNullValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalNullValue = const MessageCode(
    "ConstEvalNullValue",
    analyzerCodes: <String>["CONST_EVAL_THROWS_EXCEPTION"],
    problemMessage: r"""Null value during constant evaluation.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalStartingPoint = messageConstEvalStartingPoint;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalStartingPoint = const MessageCode(
    "ConstEvalStartingPoint",
    problemMessage: r"""Constant evaluation error:""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateConstEvalTruncateError = const Template<
        Message Function(String string, String string2)>(
    problemMessageTemplate:
        r"""Binary operator '#string ~/ #string2' results is Infinity or NaN.""",
    withArguments: _withArgumentsConstEvalTruncateError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeConstEvalTruncateError =
    const Code<Message Function(String string, String string2)>(
  "ConstEvalTruncateError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalTruncateError(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeConstEvalTruncateError,
      problemMessage:
          """Binary operator '${string} ~/ ${string2}' results is Infinity or NaN.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstEvalUnevaluated = messageConstEvalUnevaluated;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstEvalUnevaluated = const MessageCode(
    "ConstEvalUnevaluated",
    problemMessage: r"""Couldn't evaluate constant expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String stringOKEmpty)>
    templateConstEvalUnhandledCoreException =
    const Template<Message Function(String stringOKEmpty)>(
        problemMessageTemplate: r"""Unhandled core exception: #stringOKEmpty""",
        withArguments: _withArgumentsConstEvalUnhandledCoreException);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String stringOKEmpty)>
    codeConstEvalUnhandledCoreException =
    const Code<Message Function(String stringOKEmpty)>(
  "ConstEvalUnhandledCoreException",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalUnhandledCoreException(String stringOKEmpty) {
  // ignore: unnecessary_null_comparison
  if (stringOKEmpty == null || stringOKEmpty.isEmpty) stringOKEmpty = '(empty)';
  return new Message(codeConstEvalUnhandledCoreException,
      problemMessage: """Unhandled core exception: ${stringOKEmpty}""",
      arguments: {'stringOKEmpty': stringOKEmpty});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateConstEvalZeroDivisor = const Template<
        Message Function(String string, String string2)>(
    problemMessageTemplate:
        r"""Binary operator '#string' on '#string2' requires non-zero divisor, but divisor was '0'.""",
    withArguments: _withArgumentsConstEvalZeroDivisor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeConstEvalZeroDivisor =
    const Code<Message Function(String string, String string2)>(
        "ConstEvalZeroDivisor",
        analyzerCodes: <String>["CONST_EVAL_THROWS_IDBZE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstEvalZeroDivisor(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeConstEvalZeroDivisor,
      problemMessage:
          """Binary operator '${string}' on '${string2}' requires non-zero divisor, but divisor was '0'.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstFactory = messageConstFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstFactory = const MessageCode("ConstFactory",
    index: 62,
    problemMessage:
        r"""Only redirecting factory constructors can be declared to be 'const'.""",
    correctionMessage:
        r"""Try removing the 'const' keyword, or replacing the body with '=' followed by a valid target.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstFactoryRedirectionToNonConst =
    messageConstFactoryRedirectionToNonConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstFactoryRedirectionToNonConst = const MessageCode(
    "ConstFactoryRedirectionToNonConst",
    analyzerCodes: <String>["REDIRECT_TO_NON_CONST_CONSTRUCTOR"],
    problemMessage:
        r"""Constant factory constructor can't delegate to a non-constant constructor.""",
    correctionMessage:
        r"""Try redirecting to a different constructor or marking the target constructor 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateConstFieldWithoutInitializer = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""The const variable '#name' must be initialized.""",
    correctionMessageTemplate:
        r"""Try adding an initializer ('= expression') to the declaration.""",
    withArguments: _withArgumentsConstFieldWithoutInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstFieldWithoutInitializer =
    const Code<Message Function(String name)>("ConstFieldWithoutInitializer",
        analyzerCodes: <String>["CONST_NOT_INITIALIZED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstFieldWithoutInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConstFieldWithoutInitializer,
      problemMessage: """The const variable '${name}' must be initialized.""",
      correctionMessage:
          """Try adding an initializer ('= expression') to the declaration.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstInstanceField = messageConstInstanceField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstInstanceField = const MessageCode(
    "ConstInstanceField",
    analyzerCodes: <String>["CONST_INSTANCE_FIELD"],
    problemMessage: r"""Only static fields can be declared as const.""",
    correctionMessage:
        r"""Try using 'final' instead of 'const', or adding the keyword 'static'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstMethod = messageConstMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstMethod = const MessageCode("ConstMethod",
    index: 63,
    problemMessage:
        r"""Getters, setters and methods can't be declared to be 'const'.""",
    correctionMessage: r"""Try removing the 'const' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorCyclic = messageConstructorCyclic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorCyclic = const MessageCode(
    "ConstructorCyclic",
    analyzerCodes: <String>["RECURSIVE_CONSTRUCTOR_REDIRECT"],
    problemMessage: r"""Redirecting constructors can't be cyclic.""",
    correctionMessage:
        r"""Try to have all constructors eventually redirect to a non-redirecting constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConstructorInitializeSameInstanceVariableSeveralTimes =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""'#name' was already initialized by this constructor.""",
        withArguments:
            _withArgumentsConstructorInitializeSameInstanceVariableSeveralTimes);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeConstructorInitializeSameInstanceVariableSeveralTimes =
    const Code<Message Function(String name)>(
        "ConstructorInitializeSameInstanceVariableSeveralTimes",
        analyzerCodes: <String>["FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorInitializeSameInstanceVariableSeveralTimes(
    String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConstructorInitializeSameInstanceVariableSeveralTimes,
      problemMessage:
          """'${name}' was already initialized by this constructor.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConstructorNotFound =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Couldn't find constructor '#name'.""",
        withArguments: _withArgumentsConstructorNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstructorNotFound =
    const Code<Message Function(String name)>("ConstructorNotFound",
        analyzerCodes: <String>["CONSTRUCTOR_NOT_FOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConstructorNotFound,
      problemMessage: """Couldn't find constructor '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorNotSync = messageConstructorNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorNotSync = const MessageCode(
    "ConstructorNotSync",
    analyzerCodes: <String>["NON_SYNC_CONSTRUCTOR"],
    problemMessage:
        r"""Constructor bodies can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorTearOffWithTypeArguments =
    messageConstructorTearOffWithTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorTearOffWithTypeArguments = const MessageCode(
    "ConstructorTearOffWithTypeArguments",
    problemMessage:
        r"""A constructor tear-off can't have type arguments after the constructor name.""",
    correctionMessage:
        r"""Try removing the type arguments or placing them after the class name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorWithReturnType =
    messageConstructorWithReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithReturnType = const MessageCode(
    "ConstructorWithReturnType",
    index: 55,
    problemMessage: r"""Constructors can't have a return type.""",
    correctionMessage: r"""Try removing the return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorWithTypeArguments =
    messageConstructorWithTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithTypeArguments = const MessageCode(
    "ConstructorWithTypeArguments",
    index: 118,
    problemMessage:
        r"""A constructor invocation can't have type arguments after the constructor name.""",
    correctionMessage:
        r"""Try removing the type arguments or placing them after the class name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorWithTypeParameters =
    messageConstructorWithTypeParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithTypeParameters = const MessageCode(
    "ConstructorWithTypeParameters",
    index: 99,
    problemMessage: r"""Constructors can't have type parameters.""",
    correctionMessage: r"""Try removing the type parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstructorWithWrongName = messageConstructorWithWrongName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstructorWithWrongName = const MessageCode(
    "ConstructorWithWrongName",
    index: 102,
    problemMessage:
        r"""The name of a constructor must match the name of the enclosing class.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateConstructorWithWrongNameContext =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""The name of the enclosing class is '#name'.""",
        withArguments: _withArgumentsConstructorWithWrongNameContext);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstructorWithWrongNameContext =
    const Code<Message Function(String name)>("ConstructorWithWrongNameContext",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorWithWrongNameContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeConstructorWithWrongNameContext,
      problemMessage: """The name of the enclosing class is '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeContinueLabelNotTarget = messageContinueLabelNotTarget;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueLabelNotTarget = const MessageCode(
    "ContinueLabelNotTarget",
    analyzerCodes: <String>["LABEL_UNDEFINED"],
    problemMessage: r"""Target of continue must be a label.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeContinueOutsideOfLoop = messageContinueOutsideOfLoop;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueOutsideOfLoop = const MessageCode(
    "ContinueOutsideOfLoop",
    index: 2,
    problemMessage:
        r"""A continue statement can't be used outside of a loop or switch statement.""",
    correctionMessage: r"""Try removing the continue statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateContinueTargetOutsideFunction =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't continue at '#name' in a different function.""",
        withArguments: _withArgumentsContinueTargetOutsideFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeContinueTargetOutsideFunction =
    const Code<Message Function(String name)>("ContinueTargetOutsideFunction",
        analyzerCodes: <String>["LABEL_IN_OUTER_SCOPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsContinueTargetOutsideFunction(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeContinueTargetOutsideFunction,
      problemMessage:
          """Can't continue at '${name}' in a different function.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeContinueWithoutLabelInCase =
    messageContinueWithoutLabelInCase;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageContinueWithoutLabelInCase = const MessageCode(
    "ContinueWithoutLabelInCase",
    index: 64,
    problemMessage:
        r"""A continue statement in a switch statement must have a label as a target.""",
    correctionMessage:
        r"""Try adding a label associated with one of the case clauses to the continue statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateCouldNotParseUri =
    const Template<Message Function(String string, String string2)>(
        problemMessageTemplate: r"""Couldn't parse URI '#string':
  #string2.""", withArguments: _withArgumentsCouldNotParseUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeCouldNotParseUri =
    const Code<Message Function(String string, String string2)>(
  "CouldNotParseUri",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCouldNotParseUri(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeCouldNotParseUri,
      problemMessage: """Couldn't parse URI '${string}':
  ${string2}.""", arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCovariantAndStatic = messageCovariantAndStatic;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantAndStatic = const MessageCode(
    "CovariantAndStatic",
    index: 66,
    problemMessage:
        r"""Members can't be declared to be both 'covariant' and 'static'.""",
    correctionMessage:
        r"""Try removing either the 'covariant' or 'static' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCovariantMember = messageCovariantMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCovariantMember = const MessageCode("CovariantMember",
    index: 67,
    problemMessage:
        r"""Getters, setters and methods can't be declared to be 'covariant'.""",
    correctionMessage: r"""Try removing the 'covariant' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateCycleInTypeVariables =
    const Template<Message Function(String name, String string)>(
        problemMessageTemplate:
            r"""Type '#name' is a bound of itself via '#string'.""",
        correctionMessageTemplate:
            r"""Try breaking the cycle by removing at least on of the 'extends' clauses in the cycle.""",
        withArguments: _withArgumentsCycleInTypeVariables);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeCycleInTypeVariables =
    const Code<Message Function(String name, String string)>(
        "CycleInTypeVariables",
        analyzerCodes: <String>["TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCycleInTypeVariables(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeCycleInTypeVariables,
      problemMessage:
          """Type '${name}' is a bound of itself via '${string}'.""",
      correctionMessage:
          """Try breaking the cycle by removing at least on of the 'extends' clauses in the cycle.""",
      arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCyclicClassHierarchy =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""'#name' is a supertype of itself.""",
        withArguments: _withArgumentsCyclicClassHierarchy);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCyclicClassHierarchy =
    const Code<Message Function(String name)>("CyclicClassHierarchy",
        analyzerCodes: <String>["RECURSIVE_INTERFACE_INHERITANCE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicClassHierarchy(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCyclicClassHierarchy,
      problemMessage: """'${name}' is a supertype of itself.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateCyclicRedirectingFactoryConstructors =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Cyclic definition of factory '#name'.""",
        withArguments: _withArgumentsCyclicRedirectingFactoryConstructors);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeCyclicRedirectingFactoryConstructors =
    const Code<Message Function(String name)>(
        "CyclicRedirectingFactoryConstructors",
        analyzerCodes: <String>["RECURSIVE_FACTORY_REDIRECT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicRedirectingFactoryConstructors(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCyclicRedirectingFactoryConstructors,
      problemMessage: """Cyclic definition of factory '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCyclicTypedef =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""The typedef '#name' has a reference to itself.""",
        withArguments: _withArgumentsCyclicTypedef);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCyclicTypedef =
    const Code<Message Function(String name)>("CyclicTypedef",
        analyzerCodes: <String>["TYPE_ALIAS_CANNOT_REFERENCE_ITSELF"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicTypedef(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeCyclicTypedef,
      problemMessage: """The typedef '${name}' has a reference to itself.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateDebugTrace =
    const Template<Message Function(String name, String string)>(
        problemMessageTemplate: r"""Fatal '#name' at:
#string""", withArguments: _withArgumentsDebugTrace);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)> codeDebugTrace =
    const Code<Message Function(String name, String string)>("DebugTrace",
        severity: Severity.ignored);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDebugTrace(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeDebugTrace, problemMessage: """Fatal '${name}' at:
${string}""", arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDeclaredMemberConflictsWithInheritedMember =
    messageDeclaredMemberConflictsWithInheritedMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithInheritedMember =
    const MessageCode("DeclaredMemberConflictsWithInheritedMember",
        analyzerCodes: <String>["DECLARED_MEMBER_CONFLICTS_WITH_INHERITED"],
        problemMessage:
            r"""Can't declare a member that conflicts with an inherited one.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDeclaredMemberConflictsWithInheritedMemberCause =
    messageDeclaredMemberConflictsWithInheritedMemberCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithInheritedMemberCause =
    const MessageCode("DeclaredMemberConflictsWithInheritedMemberCause",
        severity: Severity.context,
        problemMessage: r"""This is the inherited member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDeclaredMemberConflictsWithOverriddenMembersCause =
    messageDeclaredMemberConflictsWithOverriddenMembersCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeclaredMemberConflictsWithOverriddenMembersCause =
    const MessageCode("DeclaredMemberConflictsWithOverriddenMembersCause",
        severity: Severity.context,
        problemMessage: r"""This is one of the overridden members.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDefaultListConstructorError =
    messageDefaultListConstructorError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDefaultListConstructorError = const MessageCode(
    "DefaultListConstructorError",
    problemMessage: r"""Can't use the default List constructor.""",
    correctionMessage: r"""Try using List.filled instead.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDefaultValueInRedirectingFactoryConstructor =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't have a default value here because any default values of '#name' would be used instead.""",
        correctionMessageTemplate: r"""Try removing the default value.""",
        withArguments:
            _withArgumentsDefaultValueInRedirectingFactoryConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeDefaultValueInRedirectingFactoryConstructor =
    const Code<Message Function(String name)>(
        "DefaultValueInRedirectingFactoryConstructor",
        analyzerCodes: <String>[
      "DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDefaultValueInRedirectingFactoryConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDefaultValueInRedirectingFactoryConstructor,
      problemMessage:
          """Can't have a default value here because any default values of '${name}' would be used instead.""",
      correctionMessage: """Try removing the default value.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDeferredAfterPrefix = messageDeferredAfterPrefix;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDeferredAfterPrefix = const MessageCode(
    "DeferredAfterPrefix",
    index: 68,
    problemMessage:
        r"""The deferred keyword should come immediately before the prefix ('as' clause).""",
    correctionMessage:
        r"""Try moving the deferred keyword before the prefix.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDeferredExtensionImport = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Extension '#name' cannot be imported through a deferred import.""",
    correctionMessageTemplate:
        r"""Try adding the `hide #name` to the import.""",
    withArguments: _withArgumentsDeferredExtensionImport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDeferredExtensionImport =
    const Code<Message Function(String name)>(
  "DeferredExtensionImport",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredExtensionImport(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDeferredExtensionImport,
      problemMessage:
          """Extension '${name}' cannot be imported through a deferred import.""",
      correctionMessage: """Try adding the `hide ${name}` to the import.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDeferredPrefixDuplicated = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Can't use the name '#name' for a deferred library, as the name is used elsewhere.""",
    withArguments: _withArgumentsDeferredPrefixDuplicated);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDeferredPrefixDuplicated =
    const Code<Message Function(String name)>("DeferredPrefixDuplicated",
        analyzerCodes: <String>["SHARED_DEFERRED_PREFIX"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicated(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDeferredPrefixDuplicated,
      problemMessage:
          """Can't use the name '${name}' for a deferred library, as the name is used elsewhere.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDeferredPrefixDuplicatedCause =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""'#name' is used here.""",
        withArguments: _withArgumentsDeferredPrefixDuplicatedCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDeferredPrefixDuplicatedCause =
    const Code<Message Function(String name)>("DeferredPrefixDuplicatedCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDeferredPrefixDuplicatedCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDeferredPrefixDuplicatedCause,
      problemMessage: """'${name}' is used here.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            int count, int count2, num _num1, num _num2, num _num3)>
    templateDillOutlineSummary = const Template<
            Message Function(
                int count, int count2, num _num1, num _num2, num _num3)>(
        problemMessageTemplate:
            r"""Indexed #count libraries (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/libraries.""",
        withArguments: _withArgumentsDillOutlineSummary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(int count, int count2, num _num1, num _num2,
        num _num3)> codeDillOutlineSummary = const Code<
    Message Function(int count, int count2, num _num1, num _num2, num _num3)>(
  "DillOutlineSummary",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDillOutlineSummary(
    int count, int count2, num _num1, num _num2, num _num3) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (_num1 == null) throw 'No number provided';
  String num1 = _num1.toStringAsFixed(3);
  // ignore: unnecessary_null_comparison
  if (_num2 == null) throw 'No number provided';
  String num2 = _num2.toStringAsFixed(3).padLeft(12);
  // ignore: unnecessary_null_comparison
  if (_num3 == null) throw 'No number provided';
  String num3 = _num3.toStringAsFixed(3).padLeft(12);
  return new Message(codeDillOutlineSummary,
      problemMessage:
          """Indexed ${count} libraries (${count2} bytes) in ${num1}ms, that is,
${num2} bytes/ms, and
${num3} ms/libraries.""",
      arguments: {
        'count': count,
        'count2': count2,
        'num1': _num1,
        'num2': _num2,
        'num3': _num3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDirectCycleInTypeVariables = const Template<
        Message Function(String name)>(
    problemMessageTemplate: r"""Type '#name' can't use itself as a bound.""",
    correctionMessageTemplate:
        r"""Try breaking the cycle by removing at least on of the 'extends' clauses in the cycle.""",
    withArguments: _withArgumentsDirectCycleInTypeVariables);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDirectCycleInTypeVariables =
    const Code<Message Function(String name)>("DirectCycleInTypeVariables",
        analyzerCodes: <String>["TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDirectCycleInTypeVariables(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDirectCycleInTypeVariables,
      problemMessage: """Type '${name}' can't use itself as a bound.""",
      correctionMessage:
          """Try breaking the cycle by removing at least on of the 'extends' clauses in the cycle.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDirectiveAfterDeclaration =
    messageDirectiveAfterDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDirectiveAfterDeclaration = const MessageCode(
    "DirectiveAfterDeclaration",
    index: 69,
    problemMessage: r"""Directives must appear before any declarations.""",
    correctionMessage:
        r"""Try moving the directive before any declarations.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDuplicateDeferred = messageDuplicateDeferred;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicateDeferred = const MessageCode(
    "DuplicateDeferred",
    index: 71,
    problemMessage:
        r"""An import directive can only have one 'deferred' keyword.""",
    correctionMessage: r"""Try removing all but one 'deferred' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicateLabelInSwitchStatement =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""The label '#name' was already used in this switch statement.""",
        correctionMessageTemplate:
            r"""Try choosing a different name for this label.""",
        withArguments: _withArgumentsDuplicateLabelInSwitchStatement);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicateLabelInSwitchStatement =
    const Code<Message Function(String name)>("DuplicateLabelInSwitchStatement",
        index: 72);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateLabelInSwitchStatement(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicateLabelInSwitchStatement,
      problemMessage:
          """The label '${name}' was already used in this switch statement.""",
      correctionMessage: """Try choosing a different name for this label.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeDuplicatePrefix = messageDuplicatePrefix;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageDuplicatePrefix = const MessageCode("DuplicatePrefix",
    index: 73,
    problemMessage:
        r"""An import directive can only have one prefix ('as' clause).""",
    correctionMessage: r"""Try removing all but one prefix.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedDeclaration =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""'#name' is already declared in this scope.""",
        withArguments: _withArgumentsDuplicatedDeclaration);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedDeclaration =
    const Code<Message Function(String name)>("DuplicatedDeclaration",
        analyzerCodes: <String>["DUPLICATE_DEFINITION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedDeclaration,
      problemMessage: """'${name}' is already declared in this scope.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedDeclarationCause =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Previous declaration of '#name'.""",
        withArguments: _withArgumentsDuplicatedDeclarationCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedDeclarationCause =
    const Code<Message Function(String name)>("DuplicatedDeclarationCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedDeclarationCause,
      problemMessage: """Previous declaration of '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDuplicatedDeclarationSyntheticCause = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Previous declaration of '#name' is implied by this definition.""",
    withArguments: _withArgumentsDuplicatedDeclarationSyntheticCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeDuplicatedDeclarationSyntheticCause =
    const Code<Message Function(String name)>(
        "DuplicatedDeclarationSyntheticCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationSyntheticCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedDeclarationSyntheticCause,
      problemMessage:
          """Previous declaration of '${name}' is implied by this definition.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedDeclarationUse =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't use '#name' because it is declared more than once.""",
        withArguments: _withArgumentsDuplicatedDeclarationUse);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedDeclarationUse =
    const Code<Message Function(String name)>(
  "DuplicatedDeclarationUse",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedDeclarationUse(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedDeclarationUse,
      problemMessage:
          """Can't use '${name}' because it is declared more than once.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateDuplicatedExport =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        problemMessageTemplate:
            r"""'#name' is exported from both '#uri' and '#uri2'.""",
        withArguments: _withArgumentsDuplicatedExport);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeDuplicatedExport =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
        "DuplicatedExport",
        analyzerCodes: <String>["AMBIGUOUS_EXPORT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedExport(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedExport,
      problemMessage:
          """'${name}' is exported from both '${uri}' and '${uri2}'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateDuplicatedExportInType =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        problemMessageTemplate:
            r"""'#name' is exported from both '#uri' and '#uri2'.""",
        withArguments: _withArgumentsDuplicatedExportInType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeDuplicatedExportInType =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
  "DuplicatedExportInType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedExportInType(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedExportInType,
      problemMessage:
          """'${name}' is exported from both '${uri}' and '${uri2}'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateDuplicatedImportInType =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        problemMessageTemplate:
            r"""'#name' is imported from both '#uri' and '#uri2'.""",
        withArguments: _withArgumentsDuplicatedImportInType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeDuplicatedImportInType =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
        "DuplicatedImportInType",
        analyzerCodes: <String>["AMBIGUOUS_IMPORT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedImportInType(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  return new Message(codeDuplicatedImportInType,
      problemMessage:
          """'${name}' is imported from both '${uri}' and '${uri2}'.""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateDuplicatedModifier =
    const Template<Message Function(Token token)>(
        problemMessageTemplate:
            r"""The modifier '#lexeme' was already specified.""",
        correctionMessageTemplate:
            r"""Try removing all but one occurrence of the modifier.""",
        withArguments: _withArgumentsDuplicatedModifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeDuplicatedModifier =
    const Code<Message Function(Token token)>("DuplicatedModifier", index: 70);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedModifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeDuplicatedModifier,
      problemMessage: """The modifier '${lexeme}' was already specified.""",
      correctionMessage:
          """Try removing all but one occurrence of the modifier.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateDuplicatedNamePreviouslyUsed = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Can't declare '#name' because it was already used in this scope.""",
    withArguments: _withArgumentsDuplicatedNamePreviouslyUsed);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedNamePreviouslyUsed =
    const Code<Message Function(String name)>("DuplicatedNamePreviouslyUsed",
        analyzerCodes: <String>["REFERENCED_BEFORE_DECLARATION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedNamePreviouslyUsed(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedNamePreviouslyUsed,
      problemMessage:
          """Can't declare '${name}' because it was already used in this scope.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedNamePreviouslyUsedCause =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Previous use of '#name'.""",
        withArguments: _withArgumentsDuplicatedNamePreviouslyUsedCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeDuplicatedNamePreviouslyUsedCause =
    const Code<Message Function(String name)>(
        "DuplicatedNamePreviouslyUsedCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedNamePreviouslyUsedCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedNamePreviouslyUsedCause,
      problemMessage: """Previous use of '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedNamedArgument =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Duplicated named argument '#name'.""",
        withArguments: _withArgumentsDuplicatedNamedArgument);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedNamedArgument =
    const Code<Message Function(String name)>("DuplicatedNamedArgument",
        analyzerCodes: <String>["DUPLICATE_NAMED_ARGUMENT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedNamedArgument(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedNamedArgument,
      problemMessage: """Duplicated named argument '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateDuplicatedParameterName =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Duplicated parameter name '#name'.""",
        withArguments: _withArgumentsDuplicatedParameterName);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedParameterName =
    const Code<Message Function(String name)>("DuplicatedParameterName",
        analyzerCodes: <String>["DUPLICATE_DEFINITION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterName(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedParameterName,
      problemMessage: """Duplicated parameter name '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateDuplicatedParameterNameCause =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Other parameter named '#name'.""",
        withArguments: _withArgumentsDuplicatedParameterNameCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeDuplicatedParameterNameCause =
    const Code<Message Function(String name)>("DuplicatedParameterNameCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedParameterNameCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeDuplicatedParameterNameCause,
      problemMessage: """Other parameter named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEmptyNamedParameterList = messageEmptyNamedParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyNamedParameterList = const MessageCode(
    "EmptyNamedParameterList",
    analyzerCodes: <String>["MISSING_IDENTIFIER"],
    problemMessage: r"""Named parameter lists cannot be empty.""",
    correctionMessage: r"""Try adding a named parameter to the list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEmptyOptionalParameterList =
    messageEmptyOptionalParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyOptionalParameterList = const MessageCode(
    "EmptyOptionalParameterList",
    analyzerCodes: <String>["MISSING_IDENTIFIER"],
    problemMessage: r"""Optional parameter lists cannot be empty.""",
    correctionMessage: r"""Try adding an optional parameter to the list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEncoding = messageEncoding;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEncoding = const MessageCode("Encoding",
    problemMessage: r"""Unable to decode bytes as UTF-8.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateEnumConstantSameNameAsEnclosing = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Name of enum constant '#name' can't be the same as the enum's own name.""",
    withArguments: _withArgumentsEnumConstantSameNameAsEnclosing);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeEnumConstantSameNameAsEnclosing =
    const Code<Message Function(String name)>("EnumConstantSameNameAsEnclosing",
        analyzerCodes: <String>["ENUM_CONSTANT_WITH_ENUM_NAME"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsEnumConstantSameNameAsEnclosing(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeEnumConstantSameNameAsEnclosing,
      problemMessage:
          """Name of enum constant '${name}' can't be the same as the enum's own name.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEnumDeclarationEmpty = messageEnumDeclarationEmpty;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumDeclarationEmpty = const MessageCode(
    "EnumDeclarationEmpty",
    analyzerCodes: <String>["EMPTY_ENUM_BODY"],
    problemMessage: r"""An enum declaration can't be empty.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEnumInClass = messageEnumInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumInClass = const MessageCode("EnumInClass",
    index: 74,
    problemMessage: r"""Enums can't be declared inside classes.""",
    correctionMessage: r"""Try moving the enum to the top-level.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEnumInstantiation = messageEnumInstantiation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEnumInstantiation = const MessageCode(
    "EnumInstantiation",
    analyzerCodes: <String>["INSTANTIATE_ENUM"],
    problemMessage: r"""Enums can't be instantiated.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEqualityCannotBeEqualityOperand =
    messageEqualityCannotBeEqualityOperand;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEqualityCannotBeEqualityOperand = const MessageCode(
    "EqualityCannotBeEqualityOperand",
    index: 1,
    problemMessage:
        r"""A comparison expression can't be an operand of another comparison expression.""",
    correctionMessage:
        r"""Try putting parentheses around one of the comparisons.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string)>
    templateExceptionReadingFile =
    const Template<Message Function(Uri uri_, String string)>(
        problemMessageTemplate: r"""Exception when reading '#uri': #string""",
        withArguments: _withArgumentsExceptionReadingFile);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, String string)> codeExceptionReadingFile =
    const Code<Message Function(Uri uri_, String string)>(
  "ExceptionReadingFile",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExceptionReadingFile(Uri uri_, String string) {
  String? uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExceptionReadingFile,
      problemMessage: """Exception when reading '${uri}': ${string}""",
      arguments: {'uri': uri_, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedAfterButGot =
    const Template<Message Function(String string)>(
        problemMessageTemplate: r"""Expected '#string' after this.""",
        withArguments: _withArgumentsExpectedAfterButGot);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedAfterButGot =
    const Code<Message Function(String string)>("ExpectedAfterButGot",
        analyzerCodes: <String>["EXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedAfterButGot(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedAfterButGot,
      problemMessage: """Expected '${string}' after this.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedAnInitializer = messageExpectedAnInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedAnInitializer = const MessageCode(
    "ExpectedAnInitializer",
    index: 36,
    problemMessage: r"""Expected an initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBlock = messageExpectedBlock;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBlock = const MessageCode("ExpectedBlock",
    analyzerCodes: <String>["EXPECTED_TOKEN"],
    problemMessage: r"""Expected a block.""",
    correctionMessage: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBlockToSkip = messageExpectedBlockToSkip;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBlockToSkip = const MessageCode(
    "ExpectedBlockToSkip",
    analyzerCodes: <String>["MISSING_FUNCTION_BODY"],
    problemMessage: r"""Expected a function body or '=>'.""",
    correctionMessage: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBody = messageExpectedBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBody = const MessageCode("ExpectedBody",
    analyzerCodes: <String>["MISSING_FUNCTION_BODY"],
    problemMessage: r"""Expected a function body or '=>'.""",
    correctionMessage: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedButGot =
    const Template<Message Function(String string)>(
        problemMessageTemplate: r"""Expected '#string' before this.""",
        withArguments: _withArgumentsExpectedButGot);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedButGot =
    const Code<Message Function(String string)>("ExpectedButGot",
        analyzerCodes: <String>["EXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedButGot(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedButGot,
      problemMessage: """Expected '${string}' before this.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedClassMember =
    const Template<Message Function(Token token)>(
        problemMessageTemplate:
            r"""Expected a class member, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedClassMember);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedClassMember =
    const Code<Message Function(Token token)>("ExpectedClassMember",
        analyzerCodes: <String>["EXPECTED_CLASS_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassMember(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedClassMember,
      problemMessage: """Expected a class member, but got '${lexeme}'.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateExpectedClassOrMixinBody =
    const Template<Message Function(String string)>(
        problemMessageTemplate:
            r"""A #string must have a body, even if it is empty.""",
        correctionMessageTemplate: r"""Try adding an empty body.""",
        withArguments: _withArgumentsExpectedClassOrMixinBody);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedClassOrMixinBody =
    const Code<Message Function(String string)>("ExpectedClassOrMixinBody",
        index: 8);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassOrMixinBody(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedClassOrMixinBody,
      problemMessage: """A ${string} must have a body, even if it is empty.""",
      correctionMessage: """Try adding an empty body.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedDeclaration =
    const Template<Message Function(Token token)>(
        problemMessageTemplate:
            r"""Expected a declaration, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedDeclaration);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedDeclaration =
    const Code<Message Function(Token token)>("ExpectedDeclaration",
        analyzerCodes: <String>["EXPECTED_EXECUTABLE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedDeclaration,
      problemMessage: """Expected a declaration, but got '${lexeme}'.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedElseOrComma = messageExpectedElseOrComma;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedElseOrComma = const MessageCode(
    "ExpectedElseOrComma",
    index: 46,
    problemMessage: r"""Expected 'else' or comma.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Token token)> templateExpectedEnumBody = const Template<
        Message Function(Token token)>(
    problemMessageTemplate: r"""Expected a enum body, but got '#lexeme'.""",
    correctionMessageTemplate:
        r"""An enum definition must have a body with at least one constant name.""",
    withArguments: _withArgumentsExpectedEnumBody);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedEnumBody =
    const Code<Message Function(Token token)>("ExpectedEnumBody",
        analyzerCodes: <String>["MISSING_ENUM_BODY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedEnumBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedEnumBody,
      problemMessage: """Expected a enum body, but got '${lexeme}'.""",
      correctionMessage:
          """An enum definition must have a body with at least one constant name.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedFunctionBody =
    const Template<Message Function(Token token)>(
        problemMessageTemplate:
            r"""Expected a function body, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedFunctionBody);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedFunctionBody =
    const Code<Message Function(Token token)>("ExpectedFunctionBody",
        analyzerCodes: <String>["MISSING_FUNCTION_BODY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedFunctionBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedFunctionBody,
      problemMessage: """Expected a function body, but got '${lexeme}'.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedHexDigit = messageExpectedHexDigit;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedHexDigit = const MessageCode(
    "ExpectedHexDigit",
    analyzerCodes: <String>["MISSING_HEX_DIGIT"],
    problemMessage: r"""A hex digit (0-9 or A-F) must follow '0x'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedIdentifier =
    const Template<Message Function(Token token)>(
        problemMessageTemplate:
            r"""Expected an identifier, but got '#lexeme'.""",
        correctionMessageTemplate:
            r"""Try inserting an identifier before '#lexeme'.""",
        withArguments: _withArgumentsExpectedIdentifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedIdentifier =
    const Code<Message Function(Token token)>("ExpectedIdentifier",
        analyzerCodes: <String>["MISSING_IDENTIFIER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedIdentifier,
      problemMessage: """Expected an identifier, but got '${lexeme}'.""",
      correctionMessage: """Try inserting an identifier before '${lexeme}'.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Token
            token)> templateExpectedIdentifierButGotKeyword = const Template<
        Message Function(Token token)>(
    problemMessageTemplate:
        r"""'#lexeme' can't be used as an identifier because it's a keyword.""",
    correctionMessageTemplate:
        r"""Try renaming this to be an identifier that isn't a keyword.""",
    withArguments: _withArgumentsExpectedIdentifierButGotKeyword);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedIdentifierButGotKeyword =
    const Code<Message Function(Token token)>("ExpectedIdentifierButGotKeyword",
        index: 113);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifierButGotKeyword(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedIdentifierButGotKeyword,
      problemMessage:
          """'${lexeme}' can't be used as an identifier because it's a keyword.""",
      correctionMessage: """Try renaming this to be an identifier that isn't a keyword.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedInstead =
    const Template<Message Function(String string)>(
        problemMessageTemplate: r"""Expected '#string' instead of this.""",
        withArguments: _withArgumentsExpectedInstead);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedInstead =
    const Code<Message Function(String string)>("ExpectedInstead", index: 41);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedInstead(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedInstead,
      problemMessage: """Expected '${string}' instead of this.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedNamedArgument = messageExpectedNamedArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedNamedArgument = const MessageCode(
    "ExpectedNamedArgument",
    analyzerCodes: <String>["EXTRA_POSITIONAL_ARGUMENTS"],
    problemMessage: r"""Expected named argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedOneExpression = messageExpectedOneExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedOneExpression = const MessageCode(
    "ExpectedOneExpression",
    problemMessage:
        r"""Expected one expression, but found additional input.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedOpenParens = messageExpectedOpenParens;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedOpenParens = const MessageCode(
    "ExpectedOpenParens",
    problemMessage: r"""Expected '('.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedStatement = messageExpectedStatement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedStatement = const MessageCode(
    "ExpectedStatement",
    index: 29,
    problemMessage: r"""Expected a statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedString =
    const Template<Message Function(Token token)>(
        problemMessageTemplate: r"""Expected a String, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedString);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedString =
    const Code<Message Function(Token token)>("ExpectedString",
        analyzerCodes: <String>["EXPECTED_STRING_LITERAL"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedString(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedString,
      problemMessage: """Expected a String, but got '${lexeme}'.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedToken =
    const Template<Message Function(String string)>(
        problemMessageTemplate: r"""Expected to find '#string'.""",
        withArguments: _withArgumentsExpectedToken);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedToken =
    const Code<Message Function(String string)>("ExpectedToken",
        analyzerCodes: <String>["EXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedToken(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExpectedToken,
      problemMessage: """Expected to find '${string}'.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedType =
    const Template<Message Function(Token token)>(
        problemMessageTemplate: r"""Expected a type, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedType =
    const Code<Message Function(Token token)>("ExpectedType",
        analyzerCodes: <String>["EXPECTED_TYPE_NAME"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedType(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedType,
      problemMessage: """Expected a type, but got '${lexeme}'.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedUri = messageExpectedUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedUri =
    const MessageCode("ExpectedUri", problemMessage: r"""Expected a URI.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateExperimentDisabled = const Template<
        Message Function(String string)>(
    problemMessageTemplate:
        r"""This requires the '#string' language feature to be enabled.""",
    correctionMessageTemplate:
        r"""The feature is on by default but is currently disabled, maybe because the '--enable-experiment=no-#string' command line option is passed.""",
    withArguments: _withArgumentsExperimentDisabled);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExperimentDisabled =
    const Code<Message Function(String string)>("ExperimentDisabled",
        analyzerCodes: <String>["ParserErrorCode.EXPERIMENT_NOT_ENABLED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentDisabled(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeExperimentDisabled,
      problemMessage:
          """This requires the '${string}' language feature to be enabled.""",
      correctionMessage:
          """The feature is on by default but is currently disabled, maybe because the '--enable-experiment=no-${string}' command line option is passed.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string2)>
    templateExperimentDisabledInvalidLanguageVersion =
    const Template<Message Function(String string2)>(
        problemMessageTemplate:
            r"""This requires the null safety language feature, which requires language version of #string2 or higher.""",
        withArguments: _withArgumentsExperimentDisabledInvalidLanguageVersion);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string2)>
    codeExperimentDisabledInvalidLanguageVersion =
    const Code<Message Function(String string2)>(
        "ExperimentDisabledInvalidLanguageVersion",
        analyzerCodes: <String>["ParserErrorCode.EXPERIMENT_NOT_ENABLED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentDisabledInvalidLanguageVersion(String string2) {
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeExperimentDisabledInvalidLanguageVersion,
      problemMessage:
          """This requires the null safety language feature, which requires language version of ${string2} or higher.""",
      arguments: {'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateExperimentNotEnabled = const Template<
        Message Function(String string, String string2)>(
    problemMessageTemplate:
        r"""This requires the '#string' language feature to be enabled.""",
    correctionMessageTemplate:
        r"""Try updating your pubspec.yaml to set the minimum SDK constraint to #string2 or higher, and running 'pub get'.""",
    withArguments: _withArgumentsExperimentNotEnabled);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeExperimentNotEnabled =
    const Code<Message Function(String string, String string2)>(
        "ExperimentNotEnabled",
        index: 48);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentNotEnabled(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeExperimentNotEnabled,
      problemMessage:
          """This requires the '${string}' language feature to be enabled.""",
      correctionMessage:
          """Try updating your pubspec.yaml to set the minimum SDK constraint to ${string2} or higher, and running 'pub get'.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExplicitExtensionArgumentMismatch =
    messageExplicitExtensionArgumentMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExplicitExtensionArgumentMismatch = const MessageCode(
    "ExplicitExtensionArgumentMismatch",
    problemMessage:
        r"""Explicit extension application requires exactly 1 positional argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExplicitExtensionAsExpression =
    messageExplicitExtensionAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExplicitExtensionAsExpression = const MessageCode(
    "ExplicitExtensionAsExpression",
    problemMessage:
        r"""Explicit extension application cannot be used as an expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExplicitExtensionAsLvalue =
    messageExplicitExtensionAsLvalue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExplicitExtensionAsLvalue = const MessageCode(
    "ExplicitExtensionAsLvalue",
    problemMessage:
        r"""Explicit extension application cannot be a target for assignment.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        int
            count)> templateExplicitExtensionTypeArgumentMismatch = const Template<
        Message Function(String name, int count)>(
    problemMessageTemplate:
        r"""Explicit extension application of extension '#name' takes '#count' type argument(s).""",
    withArguments: _withArgumentsExplicitExtensionTypeArgumentMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, int count)>
    codeExplicitExtensionTypeArgumentMismatch =
    const Code<Message Function(String name, int count)>(
  "ExplicitExtensionTypeArgumentMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExplicitExtensionTypeArgumentMismatch(
    String name, int count) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  return new Message(codeExplicitExtensionTypeArgumentMismatch,
      problemMessage:
          """Explicit extension application of extension '${name}' takes '${count}' type argument(s).""",
      arguments: {'name': name, 'count': count});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExportAfterPart = messageExportAfterPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExportAfterPart = const MessageCode("ExportAfterPart",
    index: 75,
    problemMessage: r"""Export directives must precede part directives.""",
    correctionMessage:
        r"""Try moving the export directives before the part directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExportOptOutFromOptIn = messageExportOptOutFromOptIn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExportOptOutFromOptIn = const MessageCode(
    "ExportOptOutFromOptIn",
    problemMessage:
        r"""Null safe libraries are not allowed to export declarations from of opt-out libraries.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExportedMain = messageExportedMain;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExportedMain = const MessageCode("ExportedMain",
    severity: Severity.context,
    problemMessage: r"""This is exported 'main' declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpressionNotMetadata = messageExpressionNotMetadata;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpressionNotMetadata = const MessageCode(
    "ExpressionNotMetadata",
    problemMessage:
        r"""This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtendFunction = messageExtendFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendFunction = const MessageCode("ExtendFunction",
    severity: Severity.ignored,
    problemMessage: r"""Extending 'Function' is deprecated.""",
    correctionMessage:
        r"""Try removing 'Function' from the 'extends' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateExtendingEnum =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""'#name' is an enum and can't be extended or implemented.""",
        withArguments: _withArgumentsExtendingEnum);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeExtendingEnum =
    const Code<Message Function(String name)>("ExtendingEnum",
        analyzerCodes: <String>["EXTENDS_ENUM"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingEnum(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeExtendingEnum,
      problemMessage:
          """'${name}' is an enum and can't be extended or implemented.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateExtendingRestricted =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""'#name' is restricted and can't be extended or implemented.""",
        withArguments: _withArgumentsExtendingRestricted);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeExtendingRestricted =
    const Code<Message Function(String name)>("ExtendingRestricted",
        analyzerCodes: <String>["EXTENDS_DISALLOWED_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtendingRestricted(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeExtendingRestricted,
      problemMessage:
          """'${name}' is restricted and can't be extended or implemented.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtendsFutureOr = messageExtendsFutureOr;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsFutureOr = const MessageCode("ExtendsFutureOr",
    problemMessage:
        r"""The type 'FutureOr' can't be used in an 'extends' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtendsNever = messageExtendsNever;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsNever = const MessageCode("ExtendsNever",
    problemMessage:
        r"""The type 'Never' can't be used in an 'extends' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtendsVoid = messageExtendsVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtendsVoid = const MessageCode("ExtendsVoid",
    problemMessage:
        r"""The type 'void' can't be used in an 'extends' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtensionDeclaresAbstractMember =
    messageExtensionDeclaresAbstractMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionDeclaresAbstractMember = const MessageCode(
    "ExtensionDeclaresAbstractMember",
    index: 94,
    problemMessage: r"""Extensions can't declare abstract members.""",
    correctionMessage: r"""Try providing an implementation for the member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtensionDeclaresConstructor =
    messageExtensionDeclaresConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionDeclaresConstructor = const MessageCode(
    "ExtensionDeclaresConstructor",
    index: 92,
    problemMessage: r"""Extensions can't declare constructors.""",
    correctionMessage: r"""Try removing the constructor declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExtensionDeclaresInstanceField =
    messageExtensionDeclaresInstanceField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExtensionDeclaresInstanceField = const MessageCode(
    "ExtensionDeclaresInstanceField",
    index: 93,
    problemMessage: r"""Extensions can't declare instance fields""",
    correctionMessage:
        r"""Try removing the field declaration or making it a static field""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateExtensionMemberConflictsWithObjectMember =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""This extension member conflicts with Object member '#name'.""",
        withArguments: _withArgumentsExtensionMemberConflictsWithObjectMember);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeExtensionMemberConflictsWithObjectMember =
    const Code<Message Function(String name)>(
  "ExtensionMemberConflictsWithObjectMember",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtensionMemberConflictsWithObjectMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeExtensionMemberConflictsWithObjectMember,
      problemMessage:
          """This extension member conflicts with Object member '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalClass = messageExternalClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalClass = const MessageCode("ExternalClass",
    index: 3,
    problemMessage: r"""Classes can't be declared to be 'external'.""",
    correctionMessage: r"""Try removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalConstructorWithBody =
    messageExternalConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithBody = const MessageCode(
    "ExternalConstructorWithBody",
    index: 87,
    problemMessage: r"""External constructors can't have a body.""",
    correctionMessage:
        r"""Try removing the body of the constructor, or removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalConstructorWithFieldInitializers =
    messageExternalConstructorWithFieldInitializers;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithFieldInitializers =
    const MessageCode("ExternalConstructorWithFieldInitializers",
        analyzerCodes: <String>["EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS"],
        problemMessage: r"""An external constructor can't initialize fields.""",
        correctionMessage:
            r"""Try removing the field initializers, or removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalConstructorWithInitializer =
    messageExternalConstructorWithInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalConstructorWithInitializer = const MessageCode(
    "ExternalConstructorWithInitializer",
    index: 106,
    problemMessage:
        r"""An external constructor can't have any initializers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalEnum = messageExternalEnum;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalEnum = const MessageCode("ExternalEnum",
    index: 5,
    problemMessage: r"""Enums can't be declared to be 'external'.""",
    correctionMessage: r"""Try removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalFactoryRedirection =
    messageExternalFactoryRedirection;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFactoryRedirection = const MessageCode(
    "ExternalFactoryRedirection",
    index: 85,
    problemMessage: r"""A redirecting factory can't be external.""",
    correctionMessage: r"""Try removing the 'external' modifier.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalFactoryWithBody = messageExternalFactoryWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFactoryWithBody = const MessageCode(
    "ExternalFactoryWithBody",
    index: 86,
    problemMessage: r"""External factories can't have a body.""",
    correctionMessage:
        r"""Try removing the body of the factory, or removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalField = messageExternalField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalField = const MessageCode("ExternalField",
    index: 50,
    problemMessage: r"""Fields can't be declared to be 'external'.""",
    correctionMessage:
        r"""Try removing the keyword 'external', or replacing the field by an external getter and/or setter.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalFieldConstructorInitializer =
    messageExternalFieldConstructorInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFieldConstructorInitializer = const MessageCode(
    "ExternalFieldConstructorInitializer",
    problemMessage: r"""External fields cannot have initializers.""",
    correctionMessage:
        r"""Try removing the field initializer or the 'external' keyword from the field declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalFieldInitializer = messageExternalFieldInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalFieldInitializer = const MessageCode(
    "ExternalFieldInitializer",
    problemMessage: r"""External fields cannot have initializers.""",
    correctionMessage:
        r"""Try removing the initializer or the 'external' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalLateField = messageExternalLateField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalLateField = const MessageCode(
    "ExternalLateField",
    index: 109,
    problemMessage: r"""External fields cannot be late.""",
    correctionMessage: r"""Try removing the 'external' or 'late' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalMethodWithBody = messageExternalMethodWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalMethodWithBody = const MessageCode(
    "ExternalMethodWithBody",
    index: 49,
    problemMessage: r"""An external or native method can't have a body.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExternalTypedef = messageExternalTypedef;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExternalTypedef = const MessageCode("ExternalTypedef",
    index: 76,
    problemMessage: r"""Typedefs can't be declared to be 'external'.""",
    correctionMessage: r"""Try removing the keyword 'external'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExtraneousModifier =
    const Template<Message Function(Token token)>(
        problemMessageTemplate: r"""Can't have modifier '#lexeme' here.""",
        correctionMessageTemplate: r"""Try removing '#lexeme'.""",
        withArguments: _withArgumentsExtraneousModifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExtraneousModifier =
    const Code<Message Function(Token token)>("ExtraneousModifier", index: 77);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExtraneousModifier,
      problemMessage: """Can't have modifier '${lexeme}' here.""",
      correctionMessage: """Try removing '${lexeme}'.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateExtraneousModifierInExtension =
    const Template<Message Function(Token token)>(
        problemMessageTemplate:
            r"""Can't have modifier '#lexeme' in an extension.""",
        correctionMessageTemplate: r"""Try removing '#lexeme'.""",
        withArguments: _withArgumentsExtraneousModifierInExtension);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExtraneousModifierInExtension =
    const Code<Message Function(Token token)>("ExtraneousModifierInExtension",
        index: 98);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInExtension(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExtraneousModifierInExtension,
      problemMessage: """Can't have modifier '${lexeme}' in an extension.""",
      correctionMessage: """Try removing '${lexeme}'.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFactoryNotSync = messageFactoryNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFactoryNotSync = const MessageCode("FactoryNotSync",
    analyzerCodes: <String>["NON_SYNC_FACTORY"],
    problemMessage:
        r"""Factory bodies can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFactoryTopLevelDeclaration =
    messageFactoryTopLevelDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFactoryTopLevelDeclaration = const MessageCode(
    "FactoryTopLevelDeclaration",
    index: 78,
    problemMessage:
        r"""Top-level declarations can't be declared to be 'factory'.""",
    correctionMessage: r"""Try removing the keyword 'factory'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFastaCLIArgumentRequired =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Expected value after '#name'.""",
        withArguments: _withArgumentsFastaCLIArgumentRequired);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFastaCLIArgumentRequired =
    const Code<Message Function(String name)>(
  "FastaCLIArgumentRequired",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFastaCLIArgumentRequired(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFastaCLIArgumentRequired,
      problemMessage: """Expected value after '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFastaUsageLong = messageFastaUsageLong;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFastaUsageLong =
    const MessageCode("FastaUsageLong", problemMessage: r"""Supported options:

  -o <file>, --output=<file>
    Generate the output into <file>.

  -h, /h, /?, --help
    Display this message (add -v for information about all options).

  -v, --verbose
    Display verbose information.

  -Dname
  -Dname=value
    Define an environment variable in the compile-time environment.

  --no-defines
    Ignore all -D options and leave environment constants unevaluated.

  --
    Stop option parsing, the rest of the command line is assumed to be
    file names or arguments to the Dart program.

  --packages=<file>
    Use package resolution configuration <file>, which should contain a mapping
    of package names to paths.

  --platform=<file>
    Read the SDK platform from <file>, which should be in Dill/Kernel IR format
    and contain the Dart SDK.

  --target=dart2js|dart2js_server|dart_runner|dartdevc|flutter|flutter_runner|none|vm
    Specify the target configuration.

  --enable-asserts
    Check asserts in initializers during constant evaluation.

  --verify
    Check that the generated output is free of various problems. This is mostly
    useful for developers of this compiler or Kernel transformations.

  --dump-ir
    Print compiled libraries in Kernel source notation.

  --omit-platform
    Exclude the platform from the serialized dill file.

  --exclude-source
    Do not include source code in the dill file.

  --compile-sdk=<sdk>
    Compile the SDK from scratch instead of reading it from a .dill file
    (see --platform).

  --sdk=<sdk>
    Location of the SDK sources for use when compiling additional platform
    libraries.

  --single-root-scheme=String
  --single-root-base=<dir>
    Specify a custom URI scheme and a location on disk where such URIs are
    mapped to.

    When specified, the compiler can be invoked with inputs using the custom
    URI scheme. The compiler can ignore the exact location of files on disk
    and as a result to produce output that is independent of the absolute
    location of files on disk. This is mostly useful for integrating with
    build systems.

  --fatal=errors
  --fatal=warnings
    Makes messages of the given kinds fatal, that is, immediately stop the
    compiler with a non-zero exit-code. In --verbose mode, also display an
    internal stack trace from the compiler. Multiple kinds can be separated by
    commas, for example, --fatal=errors,warnings.

  --fatal-skip=<number>
  --fatal-skip=trace
    Skip this many messages that would otherwise be fatal before aborting the
    compilation. Default is 0, which stops at the first message. Specify
    'trace' to print a stack trace for every message without stopping.

  --enable-experiment=<flag>
    Enable or disable an experimental flag, used to guard features currently
    in development. Prefix an experiment name with 'no-' to disable it.
    Multiple experiments can be separated by commas.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFastaUsageShort = messageFastaUsageShort;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFastaUsageShort = const MessageCode("FastaUsageShort",
    problemMessage: r"""Frequently used options:

  -o <file> Generate the output into <file>.
  -h        Display this message (add -v for information about all options).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            name)> templateFfiEmptyStruct = const Template<
        Message Function(String string, String name)>(
    problemMessageTemplate:
        r"""#string '#name' is empty. Empty structs and unions are undefined behavior.""",
    withArguments: _withArgumentsFfiEmptyStruct);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String name)> codeFfiEmptyStruct =
    const Code<Message Function(String string, String name)>(
  "FfiEmptyStruct",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiEmptyStruct(String string, String name) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiEmptyStruct,
      problemMessage:
          """${string} '${name}' is empty. Empty structs and unions are undefined behavior.""",
      arguments: {'string': string, 'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFfiExceptionalReturnNull = messageFfiExceptionalReturnNull;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiExceptionalReturnNull = const MessageCode(
    "FfiExceptionalReturnNull",
    problemMessage: r"""Exceptional return value must not be null.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFfiExpectedConstant = messageFfiExpectedConstant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiExpectedConstant = const MessageCode(
    "FfiExpectedConstant",
    problemMessage: r"""Exceptional return value must be a constant.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiExpectedConstantArg =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Argument '#name' must be a constant.""",
        withArguments: _withArgumentsFfiExpectedConstantArg);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiExpectedConstantArg =
    const Code<Message Function(String name)>(
  "FfiExpectedConstantArg",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExpectedConstantArg(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiExpectedConstantArg,
      problemMessage: """Argument '${name}' must be a constant.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFfiExtendsOrImplementsSealedClass =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Class '#name' cannot be extended or implemented.""",
        withArguments: _withArgumentsFfiExtendsOrImplementsSealedClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeFfiExtendsOrImplementsSealedClass =
    const Code<Message Function(String name)>(
  "FfiExtendsOrImplementsSealedClass",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiExtendsOrImplementsSealedClass(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiExtendsOrImplementsSealedClass,
      problemMessage: """Class '${name}' cannot be extended or implemented.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateFfiFieldAnnotation = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Field '#name' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.""",
    withArguments: _withArgumentsFfiFieldAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiFieldAnnotation =
    const Code<Message Function(String name)>(
  "FfiFieldAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiFieldAnnotation,
      problemMessage:
          """Field '${name}' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String string, String name, List<String> _names)>
    templateFfiFieldCyclic = const Template<
            Message Function(String string, String name, List<String> _names)>(
        problemMessageTemplate:
            r"""#string '#name' contains itself. Cycle elements:
#names""",
        withArguments: _withArgumentsFfiFieldCyclic);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String name, List<String> _names)>
    codeFfiFieldCyclic = const Code<
        Message Function(String string, String name, List<String> _names)>(
  "FfiFieldCyclic",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldCyclic(
    String string, String name, List<String> _names) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (_names.isEmpty) throw 'No names provided';
  String names = itemizeNames(_names);
  return new Message(codeFfiFieldCyclic,
      problemMessage: """${string} '${name}' contains itself. Cycle elements:
${names}""", arguments: {'string': string, 'name': name, 'names': _names});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateFfiFieldInitializer = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Field '#name' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.""",
    correctionMessageTemplate:
        r"""Mark the field as external to avoid having to initialize it.""",
    withArguments: _withArgumentsFfiFieldInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiFieldInitializer =
    const Code<Message Function(String name)>(
  "FfiFieldInitializer",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiFieldInitializer,
      problemMessage:
          """Field '${name}' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.""",
      correctionMessage: """Mark the field as external to avoid having to initialize it.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFfiFieldNoAnnotation = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Field '#name' requires no annotation to declare its native type, it is a Pointer which is represented by the same type in Dart and native code.""",
    withArguments: _withArgumentsFfiFieldNoAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiFieldNoAnnotation =
    const Code<Message Function(String name)>(
  "FfiFieldNoAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNoAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiFieldNoAnnotation,
      problemMessage:
          """Field '${name}' requires no annotation to declare its native type, it is a Pointer which is represented by the same type in Dart and native code.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateFfiFieldNull = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Field '#name' cannot have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.""",
    withArguments: _withArgumentsFfiFieldNull);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiFieldNull =
    const Code<Message Function(String name)>(
  "FfiFieldNull",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiFieldNull(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiFieldNull,
      problemMessage:
          """Field '${name}' cannot have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFfiLeafCallMustNotReturnHandle =
    messageFfiLeafCallMustNotReturnHandle;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiLeafCallMustNotReturnHandle = const MessageCode(
    "FfiLeafCallMustNotReturnHandle",
    problemMessage: r"""FFI leaf call must not have Handle return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFfiLeafCallMustNotTakeHandle =
    messageFfiLeafCallMustNotTakeHandle;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiLeafCallMustNotTakeHandle = const MessageCode(
    "FfiLeafCallMustNotTakeHandle",
    problemMessage: r"""FFI leaf call must not have Handle argument types.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFfiNativeMustBeExternal = messageFfiNativeMustBeExternal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiNativeMustBeExternal = const MessageCode(
    "FfiNativeMustBeExternal",
    problemMessage: r"""FfiNative functions must be marked external.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFfiNativeOnlyNativeFieldWrapperClassCanBePointer =
    messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer =
    const MessageCode("FfiNativeOnlyNativeFieldWrapperClassCanBePointer",
        problemMessage:
            r"""Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateFfiNativeUnexpectedNumberOfParameters =
    const Template<Message Function(int count, int count2)>(
        problemMessageTemplate:
            r"""Unexpected number of FfiNative annotation parameters. Expected #count but has #count2.""",
        withArguments: _withArgumentsFfiNativeUnexpectedNumberOfParameters);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeFfiNativeUnexpectedNumberOfParameters =
    const Code<Message Function(int count, int count2)>(
  "FfiNativeUnexpectedNumberOfParameters",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeUnexpectedNumberOfParameters(
    int count, int count2) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  return new Message(codeFfiNativeUnexpectedNumberOfParameters,
      problemMessage:
          """Unexpected number of FfiNative annotation parameters. Expected ${count} but has ${count2}.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateFfiNativeUnexpectedNumberOfParametersWithReceiver =
    const Template<Message Function(int count, int count2)>(
        problemMessageTemplate:
            r"""Unexpected number of FfiNative annotation parameters. Expected #count but has #count2. FfiNative instance method annotation must have receiver as first argument.""",
        withArguments:
            _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeFfiNativeUnexpectedNumberOfParametersWithReceiver =
    const Code<Message Function(int count, int count2)>(
  "FfiNativeUnexpectedNumberOfParametersWithReceiver",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver(
    int count, int count2) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  return new Message(codeFfiNativeUnexpectedNumberOfParametersWithReceiver,
      problemMessage:
          """Unexpected number of FfiNative annotation parameters. Expected ${count} but has ${count2}. FfiNative instance method annotation must have receiver as first argument.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateFfiNotStatic = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""#name expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.""",
    withArguments: _withArgumentsFfiNotStatic);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiNotStatic =
    const Code<Message Function(String name)>(
  "FfiNotStatic",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiNotStatic(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiNotStatic,
      problemMessage:
          """${name} expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiPackedAnnotation =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Struct '#name' must have at most one 'Packed' annotation.""",
        withArguments: _withArgumentsFfiPackedAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiPackedAnnotation =
    const Code<Message Function(String name)>(
  "FfiPackedAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiPackedAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiPackedAnnotation,
      problemMessage:
          """Struct '${name}' must have at most one 'Packed' annotation.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFfiPackedAnnotationAlignment =
    messageFfiPackedAnnotationAlignment;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFfiPackedAnnotationAlignment = const MessageCode(
    "FfiPackedAnnotationAlignment",
    problemMessage:
        r"""Only packing to 1, 2, 4, 8, and 16 bytes is supported.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateFfiPackedNestingNonPacked = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""Nesting the non-packed or less tightly packed struct '#name' in a packed struct '#name2' is not supported.""",
    withArguments: _withArgumentsFfiPackedNestingNonPacked);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeFfiPackedNestingNonPacked =
    const Code<Message Function(String name, String name2)>(
  "FfiPackedNestingNonPacked",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiPackedNestingNonPacked(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeFfiPackedNestingNonPacked,
      problemMessage:
          """Nesting the non-packed or less tightly packed struct '${name}' in a packed struct '${name2}' is not supported.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFfiSizeAnnotation =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Field '#name' must have exactly one 'Array' annotation.""",
        withArguments: _withArgumentsFfiSizeAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiSizeAnnotation =
    const Code<Message Function(String name)>(
  "FfiSizeAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotation(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiSizeAnnotation,
      problemMessage:
          """Field '${name}' must have exactly one 'Array' annotation.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFfiSizeAnnotationDimensions = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Field '#name' must have an 'Array' annotation that matches the dimensions.""",
    withArguments: _withArgumentsFfiSizeAnnotationDimensions);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFfiSizeAnnotationDimensions =
    const Code<Message Function(String name)>(
  "FfiSizeAnnotationDimensions",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiSizeAnnotationDimensions(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiSizeAnnotationDimensions,
      problemMessage:
          """Field '${name}' must have an 'Array' annotation that matches the dimensions.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String name)>
    templateFfiStructGeneric =
    const Template<Message Function(String string, String name)>(
        problemMessageTemplate: r"""#string '#name' should not be generic.""",
        withArguments: _withArgumentsFfiStructGeneric);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String name)> codeFfiStructGeneric =
    const Code<Message Function(String string, String name)>(
  "FfiStructGeneric",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFfiStructGeneric(String string, String name) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFfiStructGeneric,
      problemMessage: """${string} '${name}' should not be generic.""",
      arguments: {'string': string, 'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFieldAlreadyInitializedAtDeclaration = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""'#name' is a final instance variable that was initialized at the declaration.""",
    withArguments: _withArgumentsFieldAlreadyInitializedAtDeclaration);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeFieldAlreadyInitializedAtDeclaration =
    const Code<Message Function(String name)>(
        "FieldAlreadyInitializedAtDeclaration",
        analyzerCodes: <String>[
      "FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldAlreadyInitializedAtDeclaration(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFieldAlreadyInitializedAtDeclaration,
      problemMessage:
          """'${name}' is a final instance variable that was initialized at the declaration.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateFieldAlreadyInitializedAtDeclarationCause =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""'#name' was initialized here.""",
        withArguments: _withArgumentsFieldAlreadyInitializedAtDeclarationCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeFieldAlreadyInitializedAtDeclarationCause =
    const Code<Message Function(String name)>(
        "FieldAlreadyInitializedAtDeclarationCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldAlreadyInitializedAtDeclarationCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFieldAlreadyInitializedAtDeclarationCause,
      problemMessage: """'${name}' was initialized here.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFieldInitializedOutsideDeclaringClass =
    messageFieldInitializedOutsideDeclaringClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFieldInitializedOutsideDeclaringClass = const MessageCode(
    "FieldInitializedOutsideDeclaringClass",
    index: 88,
    problemMessage:
        r"""A field can only be initialized in its declaring class""",
    correctionMessage:
        r"""Try passing a value into the superclass constructor, or moving the initialization into the constructor body.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFieldInitializerOutsideConstructor =
    messageFieldInitializerOutsideConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFieldInitializerOutsideConstructor = const MessageCode(
    "FieldInitializerOutsideConstructor",
    index: 79,
    problemMessage:
        r"""Field formal parameters can only be used in a constructor.""",
    correctionMessage: r"""Try removing 'this.'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateFieldNotPromoted =
    const Template<Message Function(String name, String string)>(
        problemMessageTemplate:
            r"""'#name' refers to a property so it couldn't be promoted.""",
        correctionMessageTemplate: r"""See #string""",
        withArguments: _withArgumentsFieldNotPromoted);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)> codeFieldNotPromoted =
    const Code<Message Function(String name, String string)>(
  "FieldNotPromoted",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFieldNotPromoted(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeFieldNotPromoted,
      problemMessage:
          """'${name}' refers to a property so it couldn't be promoted.""",
      correctionMessage: """See ${string}""",
      arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFinalAndCovariant = messageFinalAndCovariant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndCovariant = const MessageCode(
    "FinalAndCovariant",
    index: 80,
    problemMessage:
        r"""Members can't be declared to be both 'final' and 'covariant'.""",
    correctionMessage:
        r"""Try removing either the 'final' or 'covariant' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFinalAndCovariantLateWithInitializer =
    messageFinalAndCovariantLateWithInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndCovariantLateWithInitializer = const MessageCode(
    "FinalAndCovariantLateWithInitializer",
    index: 101,
    problemMessage:
        r"""Members marked 'late' with an initializer can't be declared to be both 'final' and 'covariant'.""",
    correctionMessage:
        r"""Try removing either the 'final' or 'covariant' keyword, or removing the initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFinalAndVar = messageFinalAndVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalAndVar = const MessageCode("FinalAndVar",
    index: 81,
    problemMessage:
        r"""Members can't be declared to be both 'final' and 'var'.""",
    correctionMessage: r"""Try removing the keyword 'var'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFinalFieldNotInitialized = const Template<
        Message Function(String name)>(
    problemMessageTemplate: r"""Final field '#name' is not initialized.""",
    correctionMessageTemplate:
        r"""Try to initialize the field in the declaration or in every constructor.""",
    withArguments: _withArgumentsFinalFieldNotInitialized);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFinalFieldNotInitialized =
    const Code<Message Function(String name)>("FinalFieldNotInitialized",
        analyzerCodes: <String>["FINAL_NOT_INITIALIZED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitialized(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalFieldNotInitialized,
      problemMessage: """Final field '${name}' is not initialized.""",
      correctionMessage:
          """Try to initialize the field in the declaration or in every constructor.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFinalFieldNotInitializedByConstructor = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Final field '#name' is not initialized by this constructor.""",
    correctionMessageTemplate:
        r"""Try to initialize the field using an initializing formal or a field initializer.""",
    withArguments: _withArgumentsFinalFieldNotInitializedByConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeFinalFieldNotInitializedByConstructor =
    const Code<Message Function(String name)>(
        "FinalFieldNotInitializedByConstructor",
        analyzerCodes: <String>["FINAL_NOT_INITIALIZED_CONSTRUCTOR_1"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldNotInitializedByConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalFieldNotInitializedByConstructor,
      problemMessage:
          """Final field '${name}' is not initialized by this constructor.""",
      correctionMessage:
          """Try to initialize the field using an initializing formal or a field initializer.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFinalFieldWithoutInitializer = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""The final variable '#name' must be initialized.""",
    correctionMessageTemplate:
        r"""Try adding an initializer ('= expression') to the declaration.""",
    withArguments: _withArgumentsFinalFieldWithoutInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFinalFieldWithoutInitializer =
    const Code<Message Function(String name)>("FinalFieldWithoutInitializer",
        analyzerCodes: <String>["FINAL_NOT_INITIALIZED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldWithoutInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalFieldWithoutInitializer,
      problemMessage: """The final variable '${name}' must be initialized.""",
      correctionMessage:
          """Try adding an initializer ('= expression') to the declaration.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFinalNotAssignedError = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Final variable '#name' must be assigned before it can be used.""",
    withArguments: _withArgumentsFinalNotAssignedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFinalNotAssignedError =
    const Code<Message Function(String name)>("FinalNotAssignedError",
        analyzerCodes: <String>["READ_POTENTIALLY_UNASSIGNED_FINAL"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalNotAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalNotAssignedError,
      problemMessage:
          """Final variable '${name}' must be assigned before it can be used.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateFinalPossiblyAssignedError = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Final variable '#name' might already be assigned at this point.""",
    withArguments: _withArgumentsFinalPossiblyAssignedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFinalPossiblyAssignedError =
    const Code<Message Function(String name)>("FinalPossiblyAssignedError",
        analyzerCodes: <String>["ASSIGNMENT_TO_FINAL_LOCAL"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalPossiblyAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFinalPossiblyAssignedError,
      problemMessage:
          """Final variable '${name}' might already be assigned at this point.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeForInLoopExactlyOneVariable =
    messageForInLoopExactlyOneVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageForInLoopExactlyOneVariable = const MessageCode(
    "ForInLoopExactlyOneVariable",
    problemMessage:
        r"""A for-in loop can't have more than one loop variable.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeForInLoopNotAssignable = messageForInLoopNotAssignable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageForInLoopNotAssignable = const MessageCode(
    "ForInLoopNotAssignable",
    problemMessage:
        r"""Can't assign to this, so it can't be used in a for-in loop.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeForInLoopWithConstVariable =
    messageForInLoopWithConstVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageForInLoopWithConstVariable = const MessageCode(
    "ForInLoopWithConstVariable",
    analyzerCodes: <String>["FOR_IN_WITH_CONST_VARIABLE"],
    problemMessage: r"""A for-in loop-variable can't be 'const'.""",
    correctionMessage: r"""Try removing the 'const' modifier.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFunctionAsTypeParameter = messageFunctionAsTypeParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionAsTypeParameter = const MessageCode(
    "FunctionAsTypeParameter",
    problemMessage:
        r"""'Function' is a built-in identifier, could not used as a type identifier.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFunctionTypeDefaultValue = messageFunctionTypeDefaultValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionTypeDefaultValue = const MessageCode(
    "FunctionTypeDefaultValue",
    analyzerCodes: <String>["DEFAULT_VALUE_IN_FUNCTION_TYPE"],
    problemMessage: r"""Can't have a default value in a function type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFunctionTypedParameterVar =
    messageFunctionTypedParameterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionTypedParameterVar = const MessageCode(
    "FunctionTypedParameterVar",
    index: 119,
    problemMessage:
        r"""Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.""",
    correctionMessage: r"""Try replacing the keyword with a return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateFunctionUsedAsDec = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""'Function' is a built-in identifier, could not used as a #name name.""",
    withArguments: _withArgumentsFunctionUsedAsDec);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFunctionUsedAsDec =
    const Code<Message Function(String name)>(
  "FunctionUsedAsDec",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFunctionUsedAsDec(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeFunctionUsedAsDec,
      problemMessage:
          """'Function' is a built-in identifier, could not used as a ${name} name.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGeneratorReturnsValue = messageGeneratorReturnsValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGeneratorReturnsValue = const MessageCode(
    "GeneratorReturnsValue",
    analyzerCodes: <String>["RETURN_IN_GENERATOR"],
    problemMessage: r"""'sync*' and 'async*' can't return a value.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGenericFunctionTypeInBound =
    messageGenericFunctionTypeInBound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGenericFunctionTypeInBound = const MessageCode(
    "GenericFunctionTypeInBound",
    analyzerCodes: <String>["GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND"],
    problemMessage:
        r"""Type variables can't have generic function types in their bounds.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGenericFunctionTypeUsedAsActualTypeArgument =
    messageGenericFunctionTypeUsedAsActualTypeArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGenericFunctionTypeUsedAsActualTypeArgument =
    const MessageCode("GenericFunctionTypeUsedAsActualTypeArgument",
        analyzerCodes: <String>["GENERIC_FUNCTION_CANNOT_BE_TYPE_ARGUMENT"],
        problemMessage:
            r"""A generic function type can't be used as a type argument.""",
        correctionMessage: r"""Try using a non-generic function type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGetterConstructor = messageGetterConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGetterConstructor = const MessageCode(
    "GetterConstructor",
    index: 103,
    problemMessage: r"""Constructors can't be a getter.""",
    correctionMessage: r"""Try removing 'get'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateGetterNotFound =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Getter not found: '#name'.""",
        withArguments: _withArgumentsGetterNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeGetterNotFound =
    const Code<Message Function(String name)>("GetterNotFound",
        analyzerCodes: <String>["UNDEFINED_GETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGetterNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeGetterNotFound,
      problemMessage: """Getter not found: '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGetterWithFormals = messageGetterWithFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGetterWithFormals = const MessageCode(
    "GetterWithFormals",
    analyzerCodes: <String>["GETTER_WITH_PARAMETERS"],
    problemMessage: r"""A getter can't have formal parameters.""",
    correctionMessage: r"""Try removing '(...)'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalAssignmentToNonAssignable =
    messageIllegalAssignmentToNonAssignable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAssignmentToNonAssignable = const MessageCode(
    "IllegalAssignmentToNonAssignable",
    index: 45,
    problemMessage: r"""Illegal assignment to non-assignable expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalAsyncGeneratorReturnType =
    messageIllegalAsyncGeneratorReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAsyncGeneratorReturnType = const MessageCode(
    "IllegalAsyncGeneratorReturnType",
    analyzerCodes: <String>["ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE"],
    problemMessage:
        r"""Functions marked 'async*' must have a return type assignable to 'Stream'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalAsyncGeneratorVoidReturnType =
    messageIllegalAsyncGeneratorVoidReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAsyncGeneratorVoidReturnType =
    const MessageCode("IllegalAsyncGeneratorVoidReturnType",
        problemMessage:
            r"""Functions marked 'async*' can't have return type 'void'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalAsyncReturnType = messageIllegalAsyncReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalAsyncReturnType = const MessageCode(
    "IllegalAsyncReturnType",
    analyzerCodes: <String>["ILLEGAL_ASYNC_RETURN_TYPE"],
    problemMessage:
        r"""Functions marked 'async' must have a return type assignable to 'Future'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateIllegalMixin =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""The type '#name' can't be mixed in.""",
        withArguments: _withArgumentsIllegalMixin);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeIllegalMixin =
    const Code<Message Function(String name)>("IllegalMixin",
        analyzerCodes: <String>["ILLEGAL_MIXIN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixin(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeIllegalMixin,
      problemMessage: """The type '${name}' can't be mixed in.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateIllegalMixinDueToConstructors =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't use '#name' as a mixin because it has constructors.""",
        withArguments: _withArgumentsIllegalMixinDueToConstructors);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeIllegalMixinDueToConstructors =
    const Code<Message Function(String name)>("IllegalMixinDueToConstructors",
        analyzerCodes: <String>["MIXIN_DECLARES_CONSTRUCTOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructors(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeIllegalMixinDueToConstructors,
      problemMessage:
          """Can't use '${name}' as a mixin because it has constructors.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateIllegalMixinDueToConstructorsCause =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""This constructor prevents using '#name' as a mixin.""",
        withArguments: _withArgumentsIllegalMixinDueToConstructorsCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeIllegalMixinDueToConstructorsCause =
    const Code<Message Function(String name)>(
        "IllegalMixinDueToConstructorsCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalMixinDueToConstructorsCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeIllegalMixinDueToConstructorsCause,
      problemMessage:
          """This constructor prevents using '${name}' as a mixin.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalSyncGeneratorReturnType =
    messageIllegalSyncGeneratorReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalSyncGeneratorReturnType = const MessageCode(
    "IllegalSyncGeneratorReturnType",
    analyzerCodes: <String>["ILLEGAL_SYNC_GENERATOR_RETURN_TYPE"],
    problemMessage:
        r"""Functions marked 'sync*' must have a return type assignable to 'Iterable'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIllegalSyncGeneratorVoidReturnType =
    messageIllegalSyncGeneratorVoidReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIllegalSyncGeneratorVoidReturnType = const MessageCode(
    "IllegalSyncGeneratorVoidReturnType",
    problemMessage:
        r"""Functions marked 'sync*' can't have return type 'void'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementFunction = messageImplementFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementFunction = const MessageCode(
    "ImplementFunction",
    severity: Severity.ignored,
    problemMessage: r"""Implementing 'Function' is deprecated.""",
    correctionMessage:
        r"""Try removing 'Function' from the 'implements' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsBeforeExtends = messageImplementsBeforeExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeExtends = const MessageCode(
    "ImplementsBeforeExtends",
    index: 44,
    problemMessage:
        r"""The extends clause must be before the implements clause.""",
    correctionMessage:
        r"""Try moving the extends clause before the implements clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsBeforeOn = messageImplementsBeforeOn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeOn = const MessageCode(
    "ImplementsBeforeOn",
    index: 43,
    problemMessage: r"""The on clause must be before the implements clause.""",
    correctionMessage:
        r"""Try moving the on clause before the implements clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsBeforeWith = messageImplementsBeforeWith;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsBeforeWith = const MessageCode(
    "ImplementsBeforeWith",
    index: 42,
    problemMessage:
        r"""The with clause must be before the implements clause.""",
    correctionMessage:
        r"""Try moving the with clause before the implements clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsFutureOr = messageImplementsFutureOr;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsFutureOr = const MessageCode(
    "ImplementsFutureOr",
    problemMessage:
        r"""The type 'FutureOr' can't be used in an 'implements' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsNever = messageImplementsNever;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsNever = const MessageCode("ImplementsNever",
    problemMessage:
        r"""The type 'Never' can't be used in an 'implements' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, int count)>
    templateImplementsRepeated =
    const Template<Message Function(String name, int count)>(
        problemMessageTemplate: r"""'#name' can only be implemented once.""",
        correctionMessageTemplate:
            r"""Try removing #count of the occurrences.""",
        withArguments: _withArgumentsImplementsRepeated);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, int count)> codeImplementsRepeated =
    const Code<Message Function(String name, int count)>("ImplementsRepeated",
        analyzerCodes: <String>["IMPLEMENTS_REPEATED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsRepeated(String name, int count) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  return new Message(codeImplementsRepeated,
      problemMessage: """'${name}' can only be implemented once.""",
      correctionMessage: """Try removing ${count} of the occurrences.""",
      arguments: {'name': name, 'count': count});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateImplementsSuperClass = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""'#name' can't be used in both 'extends' and 'implements' clauses.""",
    correctionMessageTemplate: r"""Try removing one of the occurrences.""",
    withArguments: _withArgumentsImplementsSuperClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeImplementsSuperClass =
    const Code<Message Function(String name)>("ImplementsSuperClass",
        analyzerCodes: <String>["IMPLEMENTS_SUPER_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplementsSuperClass(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeImplementsSuperClass,
      problemMessage:
          """'${name}' can't be used in both 'extends' and 'implements' clauses.""",
      correctionMessage: """Try removing one of the occurrences.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplementsVoid = messageImplementsVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplementsVoid = const MessageCode("ImplementsVoid",
    problemMessage:
        r"""The type 'void' can't be used in an 'implements' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String name2,
        String
            name3)> templateImplicitMixinOverride = const Template<
        Message Function(String name, String name2, String name3)>(
    problemMessageTemplate:
        r"""Applying the mixin '#name' to '#name2' introduces an erroneous override of '#name3'.""",
    withArguments: _withArgumentsImplicitMixinOverride);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, String name3)>
    codeImplicitMixinOverride =
    const Code<Message Function(String name, String name2, String name3)>(
  "ImplicitMixinOverride",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsImplicitMixinOverride(
    String name, String name2, String name3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  return new Message(codeImplicitMixinOverride,
      problemMessage:
          """Applying the mixin '${name}' to '${name2}' introduces an erroneous override of '${name3}'.""",
      arguments: {'name': name, 'name2': name2, 'name3': name3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImplicitSuperCallOfNonMethod =
    messageImplicitSuperCallOfNonMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImplicitSuperCallOfNonMethod = const MessageCode(
    "ImplicitSuperCallOfNonMethod",
    analyzerCodes: <String>["IMPLICIT_CALL_OF_NON_METHOD"],
    problemMessage:
        r"""Cannot invoke `super` because it declares 'call' to be something other than a method.""",
    correctionMessage:
        r"""Try changing 'call' to a method or explicitly invoke 'call'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeImportAfterPart = messageImportAfterPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageImportAfterPart = const MessageCode("ImportAfterPart",
    index: 10,
    problemMessage: r"""Import directives must precede part directives.""",
    correctionMessage:
        r"""Try moving the import directives before the part directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeIncorrectTypeArgumentVariable =
    messageIncorrectTypeArgumentVariable;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageIncorrectTypeArgumentVariable = const MessageCode(
    "IncorrectTypeArgumentVariable",
    severity: Severity.context,
    problemMessage:
        r"""This is the type variable whose bound isn't conformed to.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateIncrementalCompilerIllegalParameter = const Template<
        Message Function(String string)>(
    problemMessageTemplate:
        r"""Illegal parameter name '#string' found during expression compilation.""",
    withArguments: _withArgumentsIncrementalCompilerIllegalParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeIncrementalCompilerIllegalParameter =
    const Code<Message Function(String string)>(
  "IncrementalCompilerIllegalParameter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncrementalCompilerIllegalParameter(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeIncrementalCompilerIllegalParameter,
      problemMessage:
          """Illegal parameter name '${string}' found during expression compilation.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateIncrementalCompilerIllegalTypeParameter =
    const Template<Message Function(String string)>(
        problemMessageTemplate:
            r"""Illegal type parameter name '#string' found during expression compilation.""",
        withArguments: _withArgumentsIncrementalCompilerIllegalTypeParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeIncrementalCompilerIllegalTypeParameter =
    const Code<Message Function(String string)>(
  "IncrementalCompilerIllegalTypeParameter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIncrementalCompilerIllegalTypeParameter(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeIncrementalCompilerIllegalTypeParameter,
      problemMessage:
          """Illegal type parameter name '${string}' found during expression compilation.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateInferredPackageUri =
    const Template<Message Function(Uri uri_)>(
        problemMessageTemplate:
            r"""Interpreting this as package URI, '#uri'.""",
        withArguments: _withArgumentsInferredPackageUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeInferredPackageUri =
    const Code<Message Function(Uri uri_)>("InferredPackageUri",
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInferredPackageUri(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codeInferredPackageUri,
      problemMessage: """Interpreting this as package URI, '${uri}'.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInheritedMembersConflict = messageInheritedMembersConflict;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInheritedMembersConflict = const MessageCode(
    "InheritedMembersConflict",
    analyzerCodes: <String>["CONFLICTS_WITH_INHERITED_MEMBER"],
    problemMessage:
        r"""Can't inherit members that conflict with each other.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInheritedMembersConflictCause1 =
    messageInheritedMembersConflictCause1;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInheritedMembersConflictCause1 = const MessageCode(
    "InheritedMembersConflictCause1",
    severity: Severity.context,
    problemMessage: r"""This is one inherited member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInheritedMembersConflictCause2 =
    messageInheritedMembersConflictCause2;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInheritedMembersConflictCause2 = const MessageCode(
    "InheritedMembersConflictCause2",
    severity: Severity.context,
    problemMessage: r"""This is the other inherited member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        Uri
            uri_)> templateInitializeFromDillNotSelfContained = const Template<
        Message Function(String string, Uri uri_)>(
    problemMessageTemplate:
        r"""Tried to initialize from a previous compilation (#string), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file #uri in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    withArguments: _withArgumentsInitializeFromDillNotSelfContained);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, Uri uri_)>
    codeInitializeFromDillNotSelfContained =
    const Code<Message Function(String string, Uri uri_)>(
        "InitializeFromDillNotSelfContained",
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContained(
    String string, Uri uri_) {
  if (string.isEmpty) throw 'No string provided';
  String? uri = relativizeUri(uri_);
  return new Message(codeInitializeFromDillNotSelfContained,
      problemMessage:
          """Tried to initialize from a previous compilation (${string}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file ${uri} in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
      arguments: {'string': string, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInitializeFromDillNotSelfContainedNoDump =
    const Template<Message Function(String string)>(
        problemMessageTemplate:
            r"""Tried to initialize from a previous compilation (#string), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
        withArguments: _withArgumentsInitializeFromDillNotSelfContainedNoDump);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeInitializeFromDillNotSelfContainedNoDump =
    const Code<Message Function(String string)>(
        "InitializeFromDillNotSelfContainedNoDump",
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillNotSelfContainedNoDump(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInitializeFromDillNotSelfContainedNoDump,
      problemMessage:
          """Tried to initialize from a previous compilation (${string}), but the file was not self-contained. This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String string2,
        String string3,
        Uri
            uri_)> templateInitializeFromDillUnknownProblem = const Template<
        Message Function(
            String string, String string2, String string3, Uri uri_)>(
    problemMessageTemplate:
        r"""Tried to initialize from a previous compilation (#string), but couldn't.
Error message was '#string2'.
Stacktrace included '#string3'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file #uri in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
    withArguments: _withArgumentsInitializeFromDillUnknownProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String string, String string2, String string3, Uri uri_)>
    codeInitializeFromDillUnknownProblem = const Code<
            Message Function(
                String string, String string2, String string3, Uri uri_)>(
        "InitializeFromDillUnknownProblem",
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblem(
    String string, String string2, String string3, Uri uri_) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (string3.isEmpty) throw 'No string provided';
  String? uri = relativizeUri(uri_);
  return new Message(codeInitializeFromDillUnknownProblem,
      problemMessage:
          """Tried to initialize from a previous compilation (${string}), but couldn't.
Error message was '${string2}'.
Stacktrace included '${string3}'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.
If you are comfortable with it, it would improve the chances of fixing any bug if you included the file ${uri} in your error report, but be aware that this file includes your source code.
Either way, you should probably delete the file so it doesn't use unnecessary disk space.""",
      arguments: {
        'string': string,
        'string2': string2,
        'string3': string3,
        'uri': uri_
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2, String string3)>
    templateInitializeFromDillUnknownProblemNoDump = const Template<
            Message Function(String string, String string2, String string3)>(
        problemMessageTemplate:
            r"""Tried to initialize from a previous compilation (#string), but couldn't.
Error message was '#string2'.
Stacktrace included '#string3'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
        withArguments: _withArgumentsInitializeFromDillUnknownProblemNoDump);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2, String string3)>
    codeInitializeFromDillUnknownProblemNoDump =
    const Code<Message Function(String string, String string2, String string3)>(
        "InitializeFromDillUnknownProblemNoDump",
        severity: Severity.warning);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializeFromDillUnknownProblemNoDump(
    String string, String string2, String string3) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  if (string3.isEmpty) throw 'No string provided';
  return new Message(codeInitializeFromDillUnknownProblemNoDump,
      problemMessage:
          """Tried to initialize from a previous compilation (${string}), but couldn't.
Error message was '${string2}'.
Stacktrace included '${string3}'.
This might be a bug.

The Dart team would greatly appreciate it if you would take a moment to report this problem at http://dartbug.com/new.""",
      arguments: {'string': string, 'string2': string2, 'string3': string3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInitializedVariableInForEach =
    messageInitializedVariableInForEach;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInitializedVariableInForEach = const MessageCode(
    "InitializedVariableInForEach",
    index: 82,
    problemMessage:
        r"""The loop variable in a for-each loop can't be initialized.""",
    correctionMessage:
        r"""Try removing the initializer, or using a different kind of loop.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInitializerForStaticField =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""'#name' isn't an instance field of this class.""",
        withArguments: _withArgumentsInitializerForStaticField);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInitializerForStaticField =
    const Code<Message Function(String name)>("InitializerForStaticField",
        analyzerCodes: <String>["INITIALIZER_FOR_STATIC_FIELD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInitializerForStaticField(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInitializerForStaticField,
      problemMessage: """'${name}' isn't an instance field of this class.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInitializingFormalTypeMismatchField =
    messageInitializingFormalTypeMismatchField;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInitializingFormalTypeMismatchField =
    const MessageCode("InitializingFormalTypeMismatchField",
        severity: Severity.context,
        problemMessage: r"""The field that corresponds to the parameter.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateInputFileNotFound =
    const Template<Message Function(Uri uri_)>(
        problemMessageTemplate: r"""Input file not found: #uri.""",
        withArguments: _withArgumentsInputFileNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeInputFileNotFound =
    const Code<Message Function(Uri uri_)>(
  "InputFileNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInputFileNotFound(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codeInputFileNotFound,
      problemMessage: """Input file not found: ${uri}.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateInstantiationTooFewArguments =
    const Template<Message Function(int count, int count2)>(
        problemMessageTemplate:
            r"""Too few type arguments: #count required, #count2 given.""",
        correctionMessageTemplate:
            r"""Try adding the missing type arguments.""",
        withArguments: _withArgumentsInstantiationTooFewArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeInstantiationTooFewArguments =
    const Code<Message Function(int count, int count2)>(
  "InstantiationTooFewArguments",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooFewArguments(int count, int count2) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  return new Message(codeInstantiationTooFewArguments,
      problemMessage:
          """Too few type arguments: ${count} required, ${count2} given.""",
      correctionMessage: """Try adding the missing type arguments.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count, int count2)>
    templateInstantiationTooManyArguments =
    const Template<Message Function(int count, int count2)>(
        problemMessageTemplate:
            r"""Too many type arguments: #count allowed, but #count2 found.""",
        correctionMessageTemplate:
            r"""Try removing the extra type arguments.""",
        withArguments: _withArgumentsInstantiationTooManyArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)>
    codeInstantiationTooManyArguments =
    const Code<Message Function(int count, int count2)>(
  "InstantiationTooManyArguments",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInstantiationTooManyArguments(int count, int count2) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  return new Message(codeInstantiationTooManyArguments,
      problemMessage:
          """Too many type arguments: ${count} allowed, but ${count2} found.""",
      correctionMessage: """Try removing the extra type arguments.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateIntegerLiteralIsOutOfRange = const Template<
        Message Function(String string)>(
    problemMessageTemplate:
        r"""The integer literal #string can't be represented in 64 bits.""",
    correctionMessageTemplate:
        r"""Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
    withArguments: _withArgumentsIntegerLiteralIsOutOfRange);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeIntegerLiteralIsOutOfRange =
    const Code<Message Function(String string)>("IntegerLiteralIsOutOfRange",
        analyzerCodes: <String>["INTEGER_LITERAL_OUT_OF_RANGE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIntegerLiteralIsOutOfRange(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeIntegerLiteralIsOutOfRange,
      problemMessage:
          """The integer literal ${string} can't be represented in 64 bits.""",
      correctionMessage:
          """Try using the BigInt class if you need an integer larger than 9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateInterfaceCheck = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""The implementation of '#name' in the non-abstract class '#name2' does not conform to its interface.""",
    withArguments: _withArgumentsInterfaceCheck);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)> codeInterfaceCheck =
    const Code<Message Function(String name, String name2)>(
  "InterfaceCheck",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInterfaceCheck(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeInterfaceCheck,
      problemMessage:
          """The implementation of '${name}' in the non-abstract class '${name2}' does not conform to its interface.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemAlreadyInitialized =
    messageInternalProblemAlreadyInitialized;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemAlreadyInitialized = const MessageCode(
    "InternalProblemAlreadyInitialized",
    severity: Severity.internalProblem,
    problemMessage:
        r"""Attempt to set initializer on field without initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemBodyOnAbstractMethod =
    messageInternalProblemBodyOnAbstractMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemBodyOnAbstractMethod =
    const MessageCode("InternalProblemBodyOnAbstractMethod",
        severity: Severity.internalProblem,
        problemMessage: r"""Attempting to set body on abstract method.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templateInternalProblemConstructorNotFound =
    const Template<Message Function(String name, Uri uri_)>(
        problemMessageTemplate: r"""No constructor named '#name' in '#uri'.""",
        withArguments: _withArgumentsInternalProblemConstructorNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)>
    codeInternalProblemConstructorNotFound =
    const Code<Message Function(String name, Uri uri_)>(
        "InternalProblemConstructorNotFound",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemConstructorNotFound(
    String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  return new Message(codeInternalProblemConstructorNotFound,
      problemMessage: """No constructor named '${name}' in '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemContextSeverity =
    const Template<Message Function(String string)>(
        problemMessageTemplate:
            r"""Non-context message has context severity: #string""",
        withArguments: _withArgumentsInternalProblemContextSeverity);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeInternalProblemContextSeverity =
    const Code<Message Function(String string)>(
        "InternalProblemContextSeverity",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemContextSeverity(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemContextSeverity,
      problemMessage: """Non-context message has context severity: ${string}""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateInternalProblemDebugAbort =
    const Template<Message Function(String name, String string)>(
        problemMessageTemplate: r"""Compilation aborted due to fatal '#name' at:
#string""", withArguments: _withArgumentsInternalProblemDebugAbort);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeInternalProblemDebugAbort =
    const Code<Message Function(String name, String string)>(
        "InternalProblemDebugAbort",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemDebugAbort(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemDebugAbort,
      problemMessage: """Compilation aborted due to fatal '${name}' at:
${string}""", arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemExtendingUnmodifiableScope =
    messageInternalProblemExtendingUnmodifiableScope;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemExtendingUnmodifiableScope =
    const MessageCode("InternalProblemExtendingUnmodifiableScope",
        severity: Severity.internalProblem,
        problemMessage: r"""Can't extend an unmodifiable scope.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemLabelUsageInVariablesDeclaration =
    messageInternalProblemLabelUsageInVariablesDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemLabelUsageInVariablesDeclaration =
    const MessageCode("InternalProblemLabelUsageInVariablesDeclaration",
        severity: Severity.internalProblem,
        problemMessage:
            r"""Unexpected usage of label inside declaration of variables.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemMissingContext =
    messageInternalProblemMissingContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemMissingContext = const MessageCode(
    "InternalProblemMissingContext",
    severity: Severity.internalProblem,
    problemMessage: r"""Compiler cannot run without a compiler context.""",
    correctionMessage:
        r"""Are calls to the compiler wrapped in CompilerContext.runInContext?""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInternalProblemNotFound =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Couldn't find '#name'.""",
        withArguments: _withArgumentsInternalProblemNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInternalProblemNotFound =
    const Code<Message Function(String name)>("InternalProblemNotFound",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInternalProblemNotFound,
      problemMessage: """Couldn't find '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateInternalProblemNotFoundIn =
    const Template<Message Function(String name, String name2)>(
        problemMessageTemplate: r"""Couldn't find '#name' in '#name2'.""",
        withArguments: _withArgumentsInternalProblemNotFoundIn);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeInternalProblemNotFoundIn =
    const Code<Message Function(String name, String name2)>(
        "InternalProblemNotFoundIn",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFoundIn(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeInternalProblemNotFoundIn,
      problemMessage: """Couldn't find '${name}' in '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemPreviousTokenNotFound =
    messageInternalProblemPreviousTokenNotFound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemPreviousTokenNotFound =
    const MessageCode("InternalProblemPreviousTokenNotFound",
        severity: Severity.internalProblem,
        problemMessage: r"""Couldn't find previous token.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemPrivateConstructorAccess =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't access private constructor '#name'.""",
        withArguments: _withArgumentsInternalProblemPrivateConstructorAccess);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeInternalProblemPrivateConstructorAccess =
    const Code<Message Function(String name)>(
        "InternalProblemPrivateConstructorAccess",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemPrivateConstructorAccess(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInternalProblemPrivateConstructorAccess,
      problemMessage: """Can't access private constructor '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemProvidedBothCompileSdkAndSdkSummary =
    messageInternalProblemProvidedBothCompileSdkAndSdkSummary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemProvidedBothCompileSdkAndSdkSummary =
    const MessageCode("InternalProblemProvidedBothCompileSdkAndSdkSummary",
        severity: Severity.internalProblem,
        problemMessage:
            r"""The compileSdk and sdkSummary options are mutually exclusive""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateInternalProblemStackNotEmpty =
    const Template<Message Function(String name, String string)>(
        problemMessageTemplate: r"""#name.stack isn't empty:
  #string""", withArguments: _withArgumentsInternalProblemStackNotEmpty);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeInternalProblemStackNotEmpty =
    const Code<Message Function(String name, String string)>(
        "InternalProblemStackNotEmpty",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemStackNotEmpty(String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemStackNotEmpty,
      problemMessage: """${name}.stack isn't empty:
  ${string}""", arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateInternalProblemUnexpected =
    const Template<Message Function(String string, String string2)>(
        problemMessageTemplate: r"""Expected '#string', but got '#string2'.""",
        withArguments: _withArgumentsInternalProblemUnexpected);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeInternalProblemUnexpected =
    const Code<Message Function(String string, String string2)>(
        "InternalProblemUnexpected",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnexpected(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemUnexpected,
      problemMessage: """Expected '${string}', but got '${string2}'.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        Uri
            uri_)> templateInternalProblemUnfinishedTypeVariable = const Template<
        Message Function(String name, Uri uri_)>(
    problemMessageTemplate:
        r"""Unfinished type variable '#name' found in non-source library '#uri'.""",
    withArguments: _withArgumentsInternalProblemUnfinishedTypeVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)>
    codeInternalProblemUnfinishedTypeVariable =
    const Code<Message Function(String name, Uri uri_)>(
        "InternalProblemUnfinishedTypeVariable",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnfinishedTypeVariable(
    String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  return new Message(codeInternalProblemUnfinishedTypeVariable,
      problemMessage:
          """Unfinished type variable '${name}' found in non-source library '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateInternalProblemUnhandled =
    const Template<Message Function(String string, String string2)>(
        problemMessageTemplate: r"""Unhandled #string in #string2.""",
        withArguments: _withArgumentsInternalProblemUnhandled);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeInternalProblemUnhandled =
    const Code<Message Function(String string, String string2)>(
        "InternalProblemUnhandled",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnhandled(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemUnhandled,
      problemMessage: """Unhandled ${string} in ${string2}.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemUnimplemented =
    const Template<Message Function(String string)>(
        problemMessageTemplate: r"""Unimplemented #string.""",
        withArguments: _withArgumentsInternalProblemUnimplemented);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeInternalProblemUnimplemented =
    const Code<Message Function(String string)>("InternalProblemUnimplemented",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnimplemented(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemUnimplemented,
      problemMessage: """Unimplemented ${string}.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemUnsupported =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Unsupported operation: '#name'.""",
        withArguments: _withArgumentsInternalProblemUnsupported);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInternalProblemUnsupported =
    const Code<Message Function(String name)>("InternalProblemUnsupported",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupported(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInternalProblemUnsupported,
      problemMessage: """Unsupported operation: '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)>
    templateInternalProblemUriMissingScheme =
    const Template<Message Function(Uri uri_)>(
        problemMessageTemplate: r"""The URI '#uri' has no scheme.""",
        withArguments: _withArgumentsInternalProblemUriMissingScheme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeInternalProblemUriMissingScheme =
    const Code<Message Function(Uri uri_)>("InternalProblemUriMissingScheme",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUriMissingScheme(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codeInternalProblemUriMissingScheme,
      problemMessage: """The URI '${uri}' has no scheme.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemVerificationError =
    const Template<Message Function(String string)>(
        problemMessageTemplate:
            r"""Verification of the generated program failed:
#string""",
        withArguments: _withArgumentsInternalProblemVerificationError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeInternalProblemVerificationError =
    const Code<Message Function(String string)>(
        "InternalProblemVerificationError",
        severity: Severity.internalProblem);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemVerificationError(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInternalProblemVerificationError,
      problemMessage: """Verification of the generated program failed:
${string}""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInterpolationInUri = messageInterpolationInUri;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInterpolationInUri = const MessageCode(
    "InterpolationInUri",
    analyzerCodes: <String>["INVALID_LITERAL_IN_CONFIGURATION"],
    problemMessage: r"""Can't use string interpolation in a URI.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidAwaitFor = messageInvalidAwaitFor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidAwaitFor = const MessageCode("InvalidAwaitFor",
    index: 9,
    problemMessage:
        r"""The keyword 'await' isn't allowed for a normal 'for' statement.""",
    correctionMessage:
        r"""Try removing the keyword, or use a for-each statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInvalidBreakTarget =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Can't break to '#name'.""",
        withArguments: _withArgumentsInvalidBreakTarget);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInvalidBreakTarget =
    const Code<Message Function(String name)>(
  "InvalidBreakTarget",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidBreakTarget(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInvalidBreakTarget,
      problemMessage: """Can't break to '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidCatchArguments = messageInvalidCatchArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidCatchArguments = const MessageCode(
    "InvalidCatchArguments",
    analyzerCodes: <String>["INVALID_CATCH_ARGUMENTS"],
    problemMessage: r"""Invalid catch arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidCodePoint = messageInvalidCodePoint;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidCodePoint = const MessageCode(
    "InvalidCodePoint",
    analyzerCodes: <String>["INVALID_CODE_POINT"],
    problemMessage:
        r"""The escape sequence starting with '\u' isn't a valid code point.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInvalidContinueTarget =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Can't continue at '#name'.""",
        withArguments: _withArgumentsInvalidContinueTarget);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInvalidContinueTarget =
    const Code<Message Function(String name)>(
  "InvalidContinueTarget",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidContinueTarget(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInvalidContinueTarget,
      problemMessage: """Can't continue at '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInvalidGetterSetterTypeFieldContext =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""This is the declaration of the field '#name'.""",
        withArguments: _withArgumentsInvalidGetterSetterTypeFieldContext);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeInvalidGetterSetterTypeFieldContext =
    const Code<Message Function(String name)>(
        "InvalidGetterSetterTypeFieldContext",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeFieldContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInvalidGetterSetterTypeFieldContext,
      problemMessage: """This is the declaration of the field '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInvalidGetterSetterTypeGetterContext =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""This is the declaration of the getter '#name'.""",
        withArguments: _withArgumentsInvalidGetterSetterTypeGetterContext);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeInvalidGetterSetterTypeGetterContext =
    const Code<Message Function(String name)>(
        "InvalidGetterSetterTypeGetterContext",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeGetterContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInvalidGetterSetterTypeGetterContext,
      problemMessage: """This is the declaration of the getter '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInvalidGetterSetterTypeSetterContext =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""This is the declaration of the setter '#name'.""",
        withArguments: _withArgumentsInvalidGetterSetterTypeSetterContext);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeInvalidGetterSetterTypeSetterContext =
    const Code<Message Function(String name)>(
        "InvalidGetterSetterTypeSetterContext",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidGetterSetterTypeSetterContext(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInvalidGetterSetterTypeSetterContext,
      problemMessage: """This is the declaration of the setter '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidHexEscape = messageInvalidHexEscape;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidHexEscape = const MessageCode(
    "InvalidHexEscape",
    index: 40,
    problemMessage:
        r"""An escape sequence starting with '\x' must be followed by 2 hexadecimal digits.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidInitializer = messageInvalidInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInitializer = const MessageCode(
    "InvalidInitializer",
    index: 90,
    problemMessage: r"""Not a valid initializer.""",
    correctionMessage:
        r"""To initialize a field, use the syntax 'name = value'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidInlineFunctionType =
    messageInvalidInlineFunctionType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInlineFunctionType = const MessageCode(
    "InvalidInlineFunctionType",
    analyzerCodes: <String>["INVALID_INLINE_FUNCTION_TYPE"],
    problemMessage:
        r"""Inline function types cannot be used for parameters in a generic function type.""",
    correctionMessage:
        r"""Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidNnbdDillLibrary = messageInvalidNnbdDillLibrary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidNnbdDillLibrary = const MessageCode(
    "InvalidNnbdDillLibrary",
    problemMessage: r"""Trying to use library with invalid null safety.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateInvalidOperator =
    const Template<Message Function(Token token)>(
        problemMessageTemplate:
            r"""The string '#lexeme' isn't a user-definable operator.""",
        withArguments: _withArgumentsInvalidOperator);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeInvalidOperator =
    const Code<Message Function(Token token)>("InvalidOperator", index: 39);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeInvalidOperator,
      problemMessage:
          """The string '${lexeme}' isn't a user-definable operator.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_, String string)>
    templateInvalidPackageUri =
    const Template<Message Function(Uri uri_, String string)>(
        problemMessageTemplate: r"""Invalid package URI '#uri':
  #string.""", withArguments: _withArgumentsInvalidPackageUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, String string)> codeInvalidPackageUri =
    const Code<Message Function(Uri uri_, String string)>(
  "InvalidPackageUri",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidPackageUri(Uri uri_, String string) {
  String? uri = relativizeUri(uri_);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeInvalidPackageUri,
      problemMessage: """Invalid package URI '${uri}':
  ${string}.""", arguments: {'uri': uri_, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidSuperInInitializer =
    messageInvalidSuperInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidSuperInInitializer = const MessageCode(
    "InvalidSuperInInitializer",
    index: 47,
    problemMessage:
        r"""Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidSyncModifier = messageInvalidSyncModifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidSyncModifier = const MessageCode(
    "InvalidSyncModifier",
    analyzerCodes: <String>["MISSING_STAR_AFTER_SYNC"],
    problemMessage: r"""Invalid modifier 'sync'.""",
    correctionMessage: r"""Try replacing 'sync' with 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidThisInInitializer = messageInvalidThisInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidThisInInitializer = const MessageCode(
    "InvalidThisInInitializer",
    index: 65,
    problemMessage:
        r"""Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String string2,
        String
            name2)> templateInvalidTypeVariableInSupertype = const Template<
        Message Function(
            String name, String string2, String name2)>(
    problemMessageTemplate:
        r"""Can't use implicitly 'out' variable '#name' in an '#string2' position in supertype '#name2'.""",
    withArguments: _withArgumentsInvalidTypeVariableInSupertype);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string2, String name2)>
    codeInvalidTypeVariableInSupertype =
    const Code<Message Function(String name, String string2, String name2)>(
  "InvalidTypeVariableInSupertype",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeVariableInSupertype(
    String name, String string2, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeInvalidTypeVariableInSupertype,
      problemMessage:
          """Can't use implicitly 'out' variable '${name}' in an '${string2}' position in supertype '${name2}'.""",
      arguments: {'name': name, 'string2': string2, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(
            String string, String name, String string2, String name2)>
    templateInvalidTypeVariableInSupertypeWithVariance = const Template<
            Message Function(
                String string, String name, String string2, String name2)>(
        problemMessageTemplate:
            r"""Can't use '#string' type variable '#name' in an '#string2' position in supertype '#name2'.""",
        withArguments:
            _withArgumentsInvalidTypeVariableInSupertypeWithVariance);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
        Message Function(
            String string, String name, String string2, String name2)>
    codeInvalidTypeVariableInSupertypeWithVariance = const Code<
        Message Function(
            String string, String name, String string2, String name2)>(
  "InvalidTypeVariableInSupertypeWithVariance",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeVariableInSupertypeWithVariance(
    String string, String name, String string2, String name2) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeInvalidTypeVariableInSupertypeWithVariance,
      problemMessage:
          """Can't use '${string}' type variable '${name}' in an '${string2}' position in supertype '${name2}'.""",
      arguments: {
        'string': string,
        'name': name,
        'string2': string2,
        'name2': name2
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String name,
        String
            string2)> templateInvalidTypeVariableVariancePosition = const Template<
        Message Function(String string, String name, String string2)>(
    problemMessageTemplate:
        r"""Can't use '#string' type variable '#name' in an '#string2' position.""",
    withArguments: _withArgumentsInvalidTypeVariableVariancePosition);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String name, String string2)>
    codeInvalidTypeVariableVariancePosition =
    const Code<Message Function(String string, String name, String string2)>(
  "InvalidTypeVariableVariancePosition",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeVariableVariancePosition(
    String string, String name, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeInvalidTypeVariableVariancePosition,
      problemMessage:
          """Can't use '${string}' type variable '${name}' in an '${string2}' position.""",
      arguments: {'string': string, 'name': name, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String name, String string2)>
    templateInvalidTypeVariableVariancePositionInReturnType = const Template<
            Message Function(String string, String name, String string2)>(
        problemMessageTemplate:
            r"""Can't use '#string' type variable '#name' in an '#string2' position in the return type.""",
        withArguments:
            _withArgumentsInvalidTypeVariableVariancePositionInReturnType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String name, String string2)>
    codeInvalidTypeVariableVariancePositionInReturnType =
    const Code<Message Function(String string, String name, String string2)>(
  "InvalidTypeVariableVariancePositionInReturnType",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidTypeVariableVariancePositionInReturnType(
    String string, String name, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeInvalidTypeVariableVariancePositionInReturnType,
      problemMessage:
          """Can't use '${string}' type variable '${name}' in an '${string2}' position in the return type.""",
      arguments: {'string': string, 'name': name, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidUnicodeEscape = messageInvalidUnicodeEscape;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidUnicodeEscape = const MessageCode(
    "InvalidUnicodeEscape",
    index: 38,
    problemMessage:
        r"""An escape sequence starting with '\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidUseOfNullAwareAccess =
    messageInvalidUseOfNullAwareAccess;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidUseOfNullAwareAccess = const MessageCode(
    "InvalidUseOfNullAwareAccess",
    analyzerCodes: <String>["INVALID_USE_OF_NULL_AWARE_ACCESS"],
    problemMessage: r"""Cannot use '?.' here.""",
    correctionMessage: r"""Try using '.'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidVoid = messageInvalidVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidVoid = const MessageCode("InvalidVoid",
    analyzerCodes: <String>["EXPECTED_TYPE_NAME"],
    problemMessage: r"""Type 'void' can't be used here.""",
    correctionMessage:
        r"""Try removing 'void' keyword or replace it with 'var', 'final', or a type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInvokeNonFunction =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""'#name' isn't a function or method and can't be invoked.""",
        withArguments: _withArgumentsInvokeNonFunction);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInvokeNonFunction =
    const Code<Message Function(String name)>("InvokeNonFunction",
        analyzerCodes: <String>["INVOCATION_OF_NON_FUNCTION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvokeNonFunction(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeInvokeNonFunction,
      problemMessage:
          """'${name}' isn't a function or method and can't be invoked.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropAnonymousFactoryPositionalParameters =
    messageJsInteropAnonymousFactoryPositionalParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropAnonymousFactoryPositionalParameters =
    const MessageCode("JsInteropAnonymousFactoryPositionalParameters",
        problemMessage:
            r"""Factory constructors for @anonymous JS interop classes should not contain any positional parameters.""",
        correctionMessage:
            r"""Try replacing them with named parameters instead.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateJsInteropDartClassExtendsJSClass = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""Dart class '#name' cannot extend JS interop class '#name2'.""",
    correctionMessageTemplate:
        r"""Try adding the JS interop annotation or removing it from the parent class.""",
    withArguments: _withArgumentsJsInteropDartClassExtendsJSClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeJsInteropDartClassExtendsJSClass =
    const Code<Message Function(String name, String name2)>(
  "JsInteropDartClassExtendsJSClass",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropDartClassExtendsJSClass(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeJsInteropDartClassExtendsJSClass,
      problemMessage:
          """Dart class '${name}' cannot extend JS interop class '${name2}'.""",
      correctionMessage:
          """Try adding the JS interop annotation or removing it from the parent class.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropEnclosingClassJSAnnotation =
    messageJsInteropEnclosingClassJSAnnotation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropEnclosingClassJSAnnotation = const MessageCode(
    "JsInteropEnclosingClassJSAnnotation",
    problemMessage:
        r"""Member has a JS interop annotation but the enclosing class does not.""",
    correctionMessage:
        r"""Try adding the annotation to the enclosing class.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropEnclosingClassJSAnnotationContext =
    messageJsInteropEnclosingClassJSAnnotationContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropEnclosingClassJSAnnotationContext =
    const MessageCode("JsInteropEnclosingClassJSAnnotationContext",
        severity: Severity.context,
        problemMessage: r"""This is the enclosing class.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropExternalExtensionMemberOnTypeInvalid =
    messageJsInteropExternalExtensionMemberOnTypeInvalid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropExternalExtensionMemberOnTypeInvalid =
    const MessageCode("JsInteropExternalExtensionMemberOnTypeInvalid",
        problemMessage:
            r"""JS interop or Native class required for 'external' extension members.""",
        correctionMessage:
            r"""Try adding a JS interop annotation to the on type class of the extension.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropExternalMemberNotJSAnnotated =
    messageJsInteropExternalMemberNotJSAnnotated;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropExternalMemberNotJSAnnotated = const MessageCode(
    "JsInteropExternalMemberNotJSAnnotated",
    problemMessage: r"""Only JS interop members may be 'external'.""",
    correctionMessage:
        r"""Try removing the 'external' keyword or adding a JS interop annotation.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropIndexNotSupported =
    messageJsInteropIndexNotSupported;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropIndexNotSupported = const MessageCode(
    "JsInteropIndexNotSupported",
    problemMessage:
        r"""JS interop classes do not support [] and []= operator methods.""",
    correctionMessage: r"""Try replacing with a normal method.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateJsInteropJSClassExtendsDartClass = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""JS interop class '#name' cannot extend Dart class '#name2'.""",
    correctionMessageTemplate:
        r"""Try removing the JS interop annotation or adding it to the parent class.""",
    withArguments: _withArgumentsJsInteropJSClassExtendsDartClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeJsInteropJSClassExtendsDartClass =
    const Code<Message Function(String name, String name2)>(
  "JsInteropJSClassExtendsDartClass",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropJSClassExtendsDartClass(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeJsInteropJSClassExtendsDartClass,
      problemMessage:
          """JS interop class '${name}' cannot extend Dart class '${name2}'.""",
      correctionMessage:
          """Try removing the JS interop annotation or adding it to the parent class.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropNamedParameters = messageJsInteropNamedParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropNamedParameters = const MessageCode(
    "JsInteropNamedParameters",
    problemMessage:
        r"""Named parameters for JS interop functions are only allowed in a factory constructor of an @anonymous JS class.""",
    correctionMessage:
        r"""Try replacing them with normal or optional parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String name2,
        String
            string3)> templateJsInteropNativeClassInAnnotation = const Template<
        Message Function(
            String name, String name2, String string3)>(
    problemMessageTemplate:
        r"""Non-static JS interop class '#name' conflicts with natively supported class '#name2' in '#string3'.""",
    correctionMessageTemplate:
        r"""Try replacing it with a static JS interop class using `@staticInterop` with extension methods, or use js_util to interact with the native object of type '#name2'.""",
    withArguments: _withArgumentsJsInteropNativeClassInAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, String string3)>
    codeJsInteropNativeClassInAnnotation =
    const Code<Message Function(String name, String name2, String string3)>(
  "JsInteropNativeClassInAnnotation",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropNativeClassInAnnotation(
    String name, String name2, String string3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (string3.isEmpty) throw 'No string provided';
  return new Message(codeJsInteropNativeClassInAnnotation,
      problemMessage:
          """Non-static JS interop class '${name}' conflicts with natively supported class '${name2}' in '${string3}'.""",
      correctionMessage: """Try replacing it with a static JS interop class using `@staticInterop` with extension methods, or use js_util to interact with the native object of type '${name2}'.""",
      arguments: {'name': name, 'name2': name2, 'string3': string3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropNonExternalConstructor =
    messageJsInteropNonExternalConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropNonExternalConstructor = const MessageCode(
    "JsInteropNonExternalConstructor",
    problemMessage:
        r"""JS interop classes do not support non-external constructors.""",
    correctionMessage: r"""Try annotating with `external`.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeJsInteropNonExternalMember =
    messageJsInteropNonExternalMember;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageJsInteropNonExternalMember = const MessageCode(
    "JsInteropNonExternalMember",
    problemMessage:
        r"""This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.""",
    correctionMessage: r"""Try annotating the member with `external`.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateJsInteropStaticInteropWithInstanceMembers =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""JS interop class '#name' with `@staticInterop` annotation cannot declare instance members.""",
        correctionMessageTemplate:
            r"""Try moving the instance member to a static extension.""",
        withArguments: _withArgumentsJsInteropStaticInteropWithInstanceMembers);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeJsInteropStaticInteropWithInstanceMembers =
    const Code<Message Function(String name)>(
  "JsInteropStaticInteropWithInstanceMembers",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropWithInstanceMembers(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeJsInteropStaticInteropWithInstanceMembers,
      problemMessage:
          """JS interop class '${name}' with `@staticInterop` annotation cannot declare instance members.""",
      correctionMessage: """Try moving the instance member to a static extension.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateJsInteropStaticInteropWithNonStaticSupertype =
    const Template<Message Function(String name, String name2)>(
        problemMessageTemplate:
            r"""JS interop class '#name' has an `@staticInterop` annotation, but has supertype '#name2', which is non-static.""",
        correctionMessageTemplate:
            r"""Try marking the supertype as a static interop class using `@staticInterop`.""",
        withArguments:
            _withArgumentsJsInteropStaticInteropWithNonStaticSupertype);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeJsInteropStaticInteropWithNonStaticSupertype =
    const Code<Message Function(String name, String name2)>(
  "JsInteropStaticInteropWithNonStaticSupertype",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsJsInteropStaticInteropWithNonStaticSupertype(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeJsInteropStaticInteropWithNonStaticSupertype,
      problemMessage:
          """JS interop class '${name}' has an `@staticInterop` annotation, but has supertype '${name2}', which is non-static.""",
      correctionMessage: """Try marking the supertype as a static interop class using `@staticInterop`.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(String name)> templateLabelNotFound = const Template<
        Message Function(String name)>(
    problemMessageTemplate: r"""Can't find label '#name'.""",
    correctionMessageTemplate:
        r"""Try defining the label, or correcting the name to match an existing label.""",
    withArguments: _withArgumentsLabelNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeLabelNotFound =
    const Code<Message Function(String name)>("LabelNotFound",
        analyzerCodes: <String>["LABEL_UNDEFINED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLabelNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeLabelNotFound,
      problemMessage: """Can't find label '${name}'.""",
      correctionMessage:
          """Try defining the label, or correcting the name to match an existing label.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionInvalidInDotPackages =
    messageLanguageVersionInvalidInDotPackages;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionInvalidInDotPackages = const MessageCode(
    "LanguageVersionInvalidInDotPackages",
    problemMessage:
        r"""The language version is not specified correctly in the packages file.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionLibraryContext =
    messageLanguageVersionLibraryContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionLibraryContext = const MessageCode(
    "LanguageVersionLibraryContext",
    severity: Severity.context,
    problemMessage: r"""This is language version annotation in the library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionMismatchInPart =
    messageLanguageVersionMismatchInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionMismatchInPart = const MessageCode(
    "LanguageVersionMismatchInPart",
    problemMessage:
        r"""The language version override has to be the same in the library and its part(s).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionMismatchInPatch =
    messageLanguageVersionMismatchInPatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionMismatchInPatch = const MessageCode(
    "LanguageVersionMismatchInPatch",
    problemMessage:
        r"""The language version override has to be the same in the library and its patch(es).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionPartContext =
    messageLanguageVersionPartContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionPartContext = const MessageCode(
    "LanguageVersionPartContext",
    severity: Severity.context,
    problemMessage: r"""This is language version annotation in the part.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLanguageVersionPatchContext =
    messageLanguageVersionPatchContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLanguageVersionPatchContext = const MessageCode(
    "LanguageVersionPatchContext",
    severity: Severity.context,
    problemMessage: r"""This is language version annotation in the patch.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateLanguageVersionTooHigh = const Template<
        Message Function(int count, int count2)>(
    problemMessageTemplate:
        r"""The specified language version is too high. The highest supported language version is #count.#count2.""",
    withArguments: _withArgumentsLanguageVersionTooHigh);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)> codeLanguageVersionTooHigh =
    const Code<Message Function(int count, int count2)>(
  "LanguageVersionTooHigh",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLanguageVersionTooHigh(int count, int count2) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  return new Message(codeLanguageVersionTooHigh,
      problemMessage:
          """The specified language version is too high. The highest supported language version is ${count}.${count2}.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateLateDefinitelyAssignedError =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Late final variable '#name' definitely assigned.""",
        withArguments: _withArgumentsLateDefinitelyAssignedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeLateDefinitelyAssignedError =
    const Code<Message Function(String name)>(
  "LateDefinitelyAssignedError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeLateDefinitelyAssignedError,
      problemMessage: """Late final variable '${name}' definitely assigned.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateLateDefinitelyUnassignedError = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Late variable '#name' without initializer is definitely unassigned.""",
    withArguments: _withArgumentsLateDefinitelyUnassignedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeLateDefinitelyUnassignedError =
    const Code<Message Function(String name)>(
  "LateDefinitelyUnassignedError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLateDefinitelyUnassignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeLateDefinitelyUnassignedError,
      problemMessage:
          """Late variable '${name}' without initializer is definitely unassigned.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLibraryDirectiveNotFirst = messageLibraryDirectiveNotFirst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLibraryDirectiveNotFirst = const MessageCode(
    "LibraryDirectiveNotFirst",
    index: 37,
    problemMessage:
        r"""The library directive must appear before all other directives.""",
    correctionMessage:
        r"""Try moving the library directive before any other directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeListLiteralTooManyTypeArguments =
    messageListLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageListLiteralTooManyTypeArguments = const MessageCode(
    "ListLiteralTooManyTypeArguments",
    analyzerCodes: <String>["EXPECTED_ONE_LIST_TYPE_ARGUMENTS"],
    problemMessage: r"""List literal requires exactly one type argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, Token token)>
    templateLiteralWithClass =
    const Template<Message Function(String string, Token token)>(
        problemMessageTemplate:
            r"""A #string literal can't be prefixed by '#lexeme'.""",
        correctionMessageTemplate: r"""Try removing '#lexeme'""",
        withArguments: _withArgumentsLiteralWithClass);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, Token token)> codeLiteralWithClass =
    const Code<Message Function(String string, Token token)>("LiteralWithClass",
        index: 116);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLiteralWithClass(String string, Token token) {
  if (string.isEmpty) throw 'No string provided';
  String lexeme = token.lexeme;
  return new Message(codeLiteralWithClass,
      problemMessage:
          """A ${string} literal can't be prefixed by '${lexeme}'.""",
      correctionMessage: """Try removing '${lexeme}'""",
      arguments: {'string': string, 'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String string, Token token)>
    templateLiteralWithClassAndNew =
    const Template<Message Function(String string, Token token)>(
        problemMessageTemplate:
            r"""A #string literal can't be prefixed by 'new #lexeme'.""",
        correctionMessageTemplate: r"""Try removing 'new' and '#lexeme'""",
        withArguments: _withArgumentsLiteralWithClassAndNew);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, Token token)>
    codeLiteralWithClassAndNew =
    const Code<Message Function(String string, Token token)>(
        "LiteralWithClassAndNew",
        index: 115);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLiteralWithClassAndNew(String string, Token token) {
  if (string.isEmpty) throw 'No string provided';
  String lexeme = token.lexeme;
  return new Message(codeLiteralWithClassAndNew,
      problemMessage:
          """A ${string} literal can't be prefixed by 'new ${lexeme}'.""",
      correctionMessage: """Try removing 'new' and '${lexeme}'""",
      arguments: {'string': string, 'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLiteralWithNew = messageLiteralWithNew;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLiteralWithNew = const MessageCode("LiteralWithNew",
    index: 117,
    problemMessage: r"""A literal can't be prefixed by 'new'.""",
    correctionMessage: r"""Try removing 'new'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeLoadLibraryTakesNoArguments =
    messageLoadLibraryTakesNoArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageLoadLibraryTakesNoArguments = const MessageCode(
    "LoadLibraryTakesNoArguments",
    analyzerCodes: <String>["LOAD_LIBRARY_TAKES_NO_ARGUMENTS"],
    problemMessage: r"""'loadLibrary' takes no arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMainNotFunctionDeclaration =
    messageMainNotFunctionDeclaration;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainNotFunctionDeclaration = const MessageCode(
    "MainNotFunctionDeclaration",
    problemMessage:
        r"""The 'main' declaration must be a function declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMainNotFunctionDeclarationExported =
    messageMainNotFunctionDeclarationExported;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainNotFunctionDeclarationExported = const MessageCode(
    "MainNotFunctionDeclarationExported",
    problemMessage:
        r"""The exported 'main' declaration must be a function declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMainRequiredNamedParameters =
    messageMainRequiredNamedParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainRequiredNamedParameters = const MessageCode(
    "MainRequiredNamedParameters",
    problemMessage:
        r"""The 'main' method cannot have required named parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMainRequiredNamedParametersExported =
    messageMainRequiredNamedParametersExported;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainRequiredNamedParametersExported = const MessageCode(
    "MainRequiredNamedParametersExported",
    problemMessage:
        r"""The exported 'main' method cannot have required named parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMainTooManyRequiredParameters =
    messageMainTooManyRequiredParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainTooManyRequiredParameters = const MessageCode(
    "MainTooManyRequiredParameters",
    problemMessage:
        r"""The 'main' method must have at most 2 required parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMainTooManyRequiredParametersExported =
    messageMainTooManyRequiredParametersExported;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMainTooManyRequiredParametersExported = const MessageCode(
    "MainTooManyRequiredParametersExported",
    problemMessage:
        r"""The exported 'main' method must have at most 2 required parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMapLiteralTypeArgumentMismatch =
    messageMapLiteralTypeArgumentMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMapLiteralTypeArgumentMismatch = const MessageCode(
    "MapLiteralTypeArgumentMismatch",
    analyzerCodes: <String>["EXPECTED_TWO_MAP_TYPE_ARGUMENTS"],
    problemMessage: r"""A map literal requires exactly two type arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateMemberNotFound =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Member not found: '#name'.""",
        withArguments: _withArgumentsMemberNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeMemberNotFound =
    const Code<Message Function(String name)>("MemberNotFound",
        analyzerCodes: <String>["UNDEFINED_GETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMemberNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeMemberNotFound,
      problemMessage: """Member not found: '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMemberWithSameNameAsClass =
    messageMemberWithSameNameAsClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMemberWithSameNameAsClass = const MessageCode(
    "MemberWithSameNameAsClass",
    index: 105,
    problemMessage:
        r"""A class member can't have the same name as the enclosing class.""",
    correctionMessage: r"""Try renaming the member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMetadataTypeArguments = messageMetadataTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMetadataTypeArguments = const MessageCode(
    "MetadataTypeArguments",
    index: 91,
    problemMessage: r"""An annotation can't use type arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMetadataTypeArgumentsUninstantiated =
    messageMetadataTypeArgumentsUninstantiated;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMetadataTypeArgumentsUninstantiated = const MessageCode(
    "MetadataTypeArgumentsUninstantiated",
    index: 114,
    problemMessage:
        r"""An annotation with type arguments must be followed by an argument list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateMethodNotFound =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Method not found: '#name'.""",
        withArguments: _withArgumentsMethodNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeMethodNotFound =
    const Code<Message Function(String name)>("MethodNotFound",
        analyzerCodes: <String>["UNDEFINED_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMethodNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeMethodNotFound,
      problemMessage: """Method not found: '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingArgumentList = messageMissingArgumentList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingArgumentList = const MessageCode(
    "MissingArgumentList",
    problemMessage: r"""Constructor invocations must have an argument list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingAssignableSelector =
    messageMissingAssignableSelector;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingAssignableSelector = const MessageCode(
    "MissingAssignableSelector",
    index: 35,
    problemMessage: r"""Missing selector such as '.identifier' or '[0]'.""",
    correctionMessage: r"""Try adding a selector.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingAssignmentInInitializer =
    messageMissingAssignmentInInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingAssignmentInInitializer = const MessageCode(
    "MissingAssignmentInInitializer",
    index: 34,
    problemMessage: r"""Expected an assignment after the field name.""",
    correctionMessage:
        r"""To initialize a field, use the syntax 'name = value'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingConstFinalVarOrType =
    messageMissingConstFinalVarOrType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingConstFinalVarOrType = const MessageCode(
    "MissingConstFinalVarOrType",
    index: 33,
    problemMessage:
        r"""Variables must be declared using the keywords 'const', 'final', 'var' or a type name.""",
    correctionMessage:
        r"""Try adding the name of the type of the variable or the keyword 'var'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingExplicitConst = messageMissingExplicitConst;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExplicitConst = const MessageCode(
    "MissingExplicitConst",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    problemMessage: r"""Constant expression expected.""",
    correctionMessage: r"""Try inserting 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingExponent = messageMissingExponent;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExponent = const MessageCode("MissingExponent",
    analyzerCodes: <String>["MISSING_DIGIT"],
    problemMessage:
        r"""Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).""",
    correctionMessage:
        r"""Make sure there is an exponent, and remove any whitespace before it.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingExpressionInThrow = messageMissingExpressionInThrow;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExpressionInThrow = const MessageCode(
    "MissingExpressionInThrow",
    index: 32,
    problemMessage: r"""Missing expression after 'throw'.""",
    correctionMessage:
        r"""Add an expression after 'throw' or use 'rethrow' to throw a caught exception""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingFunctionParameters =
    messageMissingFunctionParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingFunctionParameters = const MessageCode(
    "MissingFunctionParameters",
    analyzerCodes: <String>["MISSING_FUNCTION_PARAMETERS"],
    problemMessage:
        r"""A function declaration needs an explicit list of parameters.""",
    correctionMessage:
        r"""Try adding a parameter list to the function declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateMissingImplementationCause =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""'#name' is defined here.""",
        withArguments: _withArgumentsMissingImplementationCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeMissingImplementationCause =
    const Code<Message Function(String name)>("MissingImplementationCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeMissingImplementationCause,
      problemMessage: """'${name}' is defined here.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        List<String>
            _names)> templateMissingImplementationNotAbstract = const Template<
        Message Function(String name, List<String> _names)>(
    problemMessageTemplate:
        r"""The non-abstract class '#name' is missing implementations for these members:
#names""",
    correctionMessageTemplate: r"""Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.
""",
    withArguments: _withArgumentsMissingImplementationNotAbstract);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, List<String> _names)>
    codeMissingImplementationNotAbstract =
    const Code<Message Function(String name, List<String> _names)>(
        "MissingImplementationNotAbstract",
        analyzerCodes: <String>["CONCRETE_CLASS_WITH_ABSTRACT_MEMBER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingImplementationNotAbstract(
    String name, List<String> _names) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (_names.isEmpty) throw 'No names provided';
  String names = itemizeNames(_names);
  return new Message(codeMissingImplementationNotAbstract,
      problemMessage:
          """The non-abstract class '${name}' is missing implementations for these members:
${names}""",
      correctionMessage: """Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.
""",
      arguments: {'name': name, 'names': _names});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingInput = messageMissingInput;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingInput = const MessageCode("MissingInput",
    problemMessage: r"""No input file provided to the compiler.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingMain = messageMissingMain;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingMain = const MessageCode("MissingMain",
    problemMessage: r"""No 'main' method found.""",
    correctionMessage:
        r"""Try adding a method named 'main' to your program.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingMethodParameters = messageMissingMethodParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingMethodParameters = const MessageCode(
    "MissingMethodParameters",
    analyzerCodes: <String>["MISSING_METHOD_PARAMETERS"],
    problemMessage:
        r"""A method declaration needs an explicit list of parameters.""",
    correctionMessage:
        r"""Try adding a parameter list to the method declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingOperatorKeyword = messageMissingOperatorKeyword;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingOperatorKeyword = const MessageCode(
    "MissingOperatorKeyword",
    index: 31,
    problemMessage:
        r"""Operator declarations must be preceded by the keyword 'operator'.""",
    correctionMessage: r"""Try adding the keyword 'operator'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Uri uri_)> templateMissingPartOf = const Template<
        Message Function(Uri uri_)>(
    problemMessageTemplate:
        r"""Can't use '#uri' as a part, because it has no 'part of' declaration.""",
    withArguments: _withArgumentsMissingPartOf);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeMissingPartOf =
    const Code<Message Function(Uri uri_)>("MissingPartOf",
        analyzerCodes: <String>["PART_OF_NON_PART"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMissingPartOf(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codeMissingPartOf,
      problemMessage:
          """Can't use '${uri}' as a part, because it has no 'part of' declaration.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingPrefixInDeferredImport =
    messageMissingPrefixInDeferredImport;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingPrefixInDeferredImport = const MessageCode(
    "MissingPrefixInDeferredImport",
    index: 30,
    problemMessage: r"""Deferred imports should have a prefix.""",
    correctionMessage:
        r"""Try adding a prefix to the import by adding an 'as' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingTypedefParameters = messageMissingTypedefParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingTypedefParameters = const MessageCode(
    "MissingTypedefParameters",
    analyzerCodes: <String>["MISSING_TYPEDEF_PARAMETERS"],
    problemMessage: r"""A typedef needs an explicit list of parameters.""",
    correctionMessage: r"""Try adding a parameter list to the typedef.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMixinDeclaresConstructor = messageMixinDeclaresConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMixinDeclaresConstructor = const MessageCode(
    "MixinDeclaresConstructor",
    index: 95,
    problemMessage: r"""Mixins can't declare constructors.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMixinFunction = messageMixinFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMixinFunction = const MessageCode("MixinFunction",
    severity: Severity.ignored,
    problemMessage: r"""Mixing in 'Function' is deprecated.""",
    correctionMessage: r"""Try removing 'Function' from the 'with' clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateModifierOutOfOrder = const Template<
        Message Function(String string, String string2)>(
    problemMessageTemplate:
        r"""The modifier '#string' should be before the modifier '#string2'.""",
    correctionMessageTemplate: r"""Try re-ordering the modifiers.""",
    withArguments: _withArgumentsModifierOutOfOrder);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeModifierOutOfOrder =
    const Code<Message Function(String string, String string2)>(
        "ModifierOutOfOrder",
        index: 56);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsModifierOutOfOrder(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeModifierOutOfOrder,
      problemMessage:
          """The modifier '${string}' should be before the modifier '${string2}'.""",
      correctionMessage: """Try re-ordering the modifiers.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMoreThanOneSuperInitializer =
    messageMoreThanOneSuperInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMoreThanOneSuperInitializer = const MessageCode(
    "MoreThanOneSuperInitializer",
    analyzerCodes: <String>["MULTIPLE_SUPER_INITIALIZERS"],
    problemMessage: r"""Can't have more than one 'super' initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleExtends = messageMultipleExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleExtends = const MessageCode("MultipleExtends",
    index: 28,
    problemMessage:
        r"""Each class definition can have at most one extends clause.""",
    correctionMessage:
        r"""Try choosing one superclass and define your class to implement (or mix in) the others.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleImplements = messageMultipleImplements;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleImplements = const MessageCode(
    "MultipleImplements",
    analyzerCodes: <String>["MULTIPLE_IMPLEMENTS_CLAUSES"],
    problemMessage:
        r"""Each class definition can have at most one implements clause.""",
    correctionMessage:
        r"""Try combining all of the implements clauses into a single clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleLibraryDirectives =
    messageMultipleLibraryDirectives;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleLibraryDirectives = const MessageCode(
    "MultipleLibraryDirectives",
    index: 27,
    problemMessage:
        r"""Only one library directive may be declared in a file.""",
    correctionMessage:
        r"""Try removing all but one of the library directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleOnClauses = messageMultipleOnClauses;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleOnClauses = const MessageCode(
    "MultipleOnClauses",
    index: 26,
    problemMessage:
        r"""Each mixin definition can have at most one on clause.""",
    correctionMessage:
        r"""Try combining all of the on clauses into a single clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleVarianceModifiers =
    messageMultipleVarianceModifiers;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleVarianceModifiers = const MessageCode(
    "MultipleVarianceModifiers",
    index: 97,
    problemMessage:
        r"""Each type parameter can have at most one variance modifier.""",
    correctionMessage:
        r"""Use at most one of the 'in', 'out', or 'inout' modifiers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMultipleWith = messageMultipleWith;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMultipleWith = const MessageCode("MultipleWith",
    index: 24,
    problemMessage:
        r"""Each class definition can have at most one with clause.""",
    correctionMessage:
        r"""Try combining all of the with clauses into a single clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNameNotFound =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Undefined name '#name'.""",
        withArguments: _withArgumentsNameNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNameNotFound =
    const Code<Message Function(String name)>("NameNotFound",
        analyzerCodes: <String>["UNDEFINED_NAME"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNameNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNameNotFound,
      problemMessage: """Undefined name '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNamedFunctionExpression = messageNamedFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNamedFunctionExpression = const MessageCode(
    "NamedFunctionExpression",
    analyzerCodes: <String>["NAMED_FUNCTION_EXPRESSION"],
    problemMessage: r"""A function expression can't have a name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateNamedMixinOverride = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""The mixin application class '#name' introduces an erroneous override of '#name2'.""",
    withArguments: _withArgumentsNamedMixinOverride);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)> codeNamedMixinOverride =
    const Code<Message Function(String name, String name2)>(
  "NamedMixinOverride",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNamedMixinOverride(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeNamedMixinOverride,
      problemMessage:
          """The mixin application class '${name}' introduces an erroneous override of '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNativeClauseShouldBeAnnotation =
    messageNativeClauseShouldBeAnnotation;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNativeClauseShouldBeAnnotation = const MessageCode(
    "NativeClauseShouldBeAnnotation",
    index: 23,
    problemMessage: r"""Native clause in this form is deprecated.""",
    correctionMessage:
        r"""Try removing this native clause and adding @native() or @native('native-name') before the declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNeverReachableSwitchDefaultError =
    messageNeverReachableSwitchDefaultError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNeverReachableSwitchDefaultError = const MessageCode(
    "NeverReachableSwitchDefaultError",
    problemMessage:
        r"""`null` encountered as case in a switch expression with a non-nullable enum type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNeverReachableSwitchDefaultWarning =
    messageNeverReachableSwitchDefaultWarning;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNeverReachableSwitchDefaultWarning = const MessageCode(
    "NeverReachableSwitchDefaultWarning",
    severity: Severity.warning,
    problemMessage:
        r"""The default case is not reachable with sound null safety because the switch expression is non-nullable.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNeverValueError = messageNeverValueError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNeverValueError = const MessageCode("NeverValueError",
    problemMessage:
        r"""`null` encountered as the result from expression with type `Never`.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNeverValueWarning = messageNeverValueWarning;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNeverValueWarning = const MessageCode(
    "NeverValueWarning",
    severity: Severity.warning,
    problemMessage:
        r"""The expression can not result in a value with sound null safety because the expression type is `Never`.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNewAsSelector = messageNewAsSelector;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNewAsSelector = const MessageCode("NewAsSelector",
    problemMessage: r"""'new' can only be used as a constructor reference.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Token token)> templateNoFormals = const Template<
        Message Function(Token token)>(
    problemMessageTemplate: r"""A function should have formal parameters.""",
    correctionMessageTemplate:
        r"""Try adding '()' after '#lexeme', or add 'get' before '#lexeme' to declare a getter.""",
    withArguments: _withArgumentsNoFormals);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeNoFormals =
    const Code<Message Function(Token token)>("NoFormals",
        analyzerCodes: <String>["MISSING_FUNCTION_PARAMETERS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoFormals(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeNoFormals,
      problemMessage: """A function should have formal parameters.""",
      correctionMessage:
          """Try adding '()' after '${lexeme}', or add 'get' before '${lexeme}' to declare a getter.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNoSuchNamedParameter =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""No named parameter with the name '#name'.""",
        withArguments: _withArgumentsNoSuchNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNoSuchNamedParameter =
    const Code<Message Function(String name)>("NoSuchNamedParameter",
        analyzerCodes: <String>["UNDEFINED_NAMED_PARAMETER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoSuchNamedParameter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNoSuchNamedParameter,
      problemMessage: """No named parameter with the name '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNoUnnamedConstructorInObject =
    messageNoUnnamedConstructorInObject;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNoUnnamedConstructorInObject = const MessageCode(
    "NoUnnamedConstructorInObject",
    problemMessage: r"""'Object' has no unnamed constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonAgnosticConstant = messageNonAgnosticConstant;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonAgnosticConstant = const MessageCode(
    "NonAgnosticConstant",
    problemMessage: r"""Constant value is not strong/weak mode agnostic.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String character,
        int
            codePoint)> templateNonAsciiIdentifier = const Template<
        Message Function(String character, int codePoint)>(
    problemMessageTemplate:
        r"""The non-ASCII character '#character' (#unicode) can't be used in identifiers, only in strings and comments.""",
    correctionMessageTemplate:
        r"""Try using an US-ASCII letter, a digit, '_' (an underscore), or '$' (a dollar sign).""",
    withArguments: _withArgumentsNonAsciiIdentifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String character, int codePoint)>
    codeNonAsciiIdentifier =
    const Code<Message Function(String character, int codePoint)>(
        "NonAsciiIdentifier",
        analyzerCodes: <String>["ILLEGAL_CHARACTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiIdentifier(String character, int codePoint) {
  if (character.runes.length != 1) throw "Not a character '${character}'";
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(codeNonAsciiIdentifier,
      problemMessage:
          """The non-ASCII character '${character}' (${unicode}) can't be used in identifiers, only in strings and comments.""",
      correctionMessage: """Try using an US-ASCII letter, a digit, '_' (an underscore), or '\$' (a dollar sign).""",
      arguments: {'character': character, 'unicode': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int
            codePoint)> templateNonAsciiWhitespace = const Template<
        Message Function(int codePoint)>(
    problemMessageTemplate:
        r"""The non-ASCII space character #unicode can only be used in strings and comments.""",
    withArguments: _withArgumentsNonAsciiWhitespace);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int codePoint)> codeNonAsciiWhitespace =
    const Code<Message Function(int codePoint)>("NonAsciiWhitespace",
        analyzerCodes: <String>["ILLEGAL_CHARACTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiWhitespace(int codePoint) {
  String unicode =
      "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  return new Message(codeNonAsciiWhitespace,
      problemMessage:
          """The non-ASCII space character ${unicode} can only be used in strings and comments.""",
      arguments: {'unicode': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonConstConstructor = messageNonConstConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonConstConstructor = const MessageCode(
    "NonConstConstructor",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    problemMessage:
        r"""Cannot invoke a non-'const' constructor where a const expression is expected.""",
    correctionMessage:
        r"""Try using a constructor or factory that is 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonConstFactory = messageNonConstFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonConstFactory = const MessageCode("NonConstFactory",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    problemMessage:
        r"""Cannot invoke a non-'const' factory where a const expression is expected.""",
    correctionMessage:
        r"""Try using a constructor or factory that is 'const'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateNonNullableNotAssignedError = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Non-nullable variable '#name' must be assigned before it can be used.""",
    withArguments: _withArgumentsNonNullableNotAssignedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNonNullableNotAssignedError =
    const Code<Message Function(String name)>(
  "NonNullableNotAssignedError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableNotAssignedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNonNullableNotAssignedError,
      problemMessage:
          """Non-nullable variable '${name}' must be assigned before it can be used.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonNullableOptOutComment = messageNonNullableOptOutComment;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonNullableOptOutComment = const MessageCode(
    "NonNullableOptOutComment",
    severity: Severity.context,
    problemMessage:
        r"""This is the annotation that opts out this library from null safety features.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateNonNullableOptOutExplicit = const Template<
        Message Function(String string)>(
    problemMessageTemplate:
        r"""Null safety features are disabled for this library.""",
    correctionMessageTemplate:
        r"""Try removing the `@dart=` annotation or setting the language version to #string or higher.""",
    withArguments: _withArgumentsNonNullableOptOutExplicit);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeNonNullableOptOutExplicit =
    const Code<Message Function(String string)>(
  "NonNullableOptOutExplicit",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableOptOutExplicit(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeNonNullableOptOutExplicit,
      problemMessage: """Null safety features are disabled for this library.""",
      correctionMessage:
          """Try removing the `@dart=` annotation or setting the language version to ${string} or higher.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            string)> templateNonNullableOptOutImplicit = const Template<
        Message Function(String string)>(
    problemMessageTemplate:
        r"""Null safety features are disabled for this library.""",
    correctionMessageTemplate:
        r"""Try removing the package language version or setting the language version to #string or higher.""",
    withArguments: _withArgumentsNonNullableOptOutImplicit);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeNonNullableOptOutImplicit =
    const Code<Message Function(String string)>(
  "NonNullableOptOutImplicit",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonNullableOptOutImplicit(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeNonNullableOptOutImplicit,
      problemMessage: """Null safety features are disabled for this library.""",
      correctionMessage:
          """Try removing the package language version or setting the language version to ${string} or higher.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonPartOfDirectiveInPart = messageNonPartOfDirectiveInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonPartOfDirectiveInPart = const MessageCode(
    "NonPartOfDirectiveInPart",
    analyzerCodes: <String>["NON_PART_OF_DIRECTIVE_IN_PART"],
    problemMessage:
        r"""The part-of directive must be the only directive in a part.""",
    correctionMessage:
        r"""Try removing the other directives, or moving them to the library for which this is a part.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonPositiveArrayDimensions =
    messageNonPositiveArrayDimensions;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonPositiveArrayDimensions = const MessageCode(
    "NonPositiveArrayDimensions",
    problemMessage: r"""Array dimensions must be positive numbers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateNonSimpleBoundViaReference =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Bound of this variable references raw type '#name'.""",
        withArguments: _withArgumentsNonSimpleBoundViaReference);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNonSimpleBoundViaReference =
    const Code<Message Function(String name)>("NonSimpleBoundViaReference",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaReference(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNonSimpleBoundViaReference,
      problemMessage:
          """Bound of this variable references raw type '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateNonSimpleBoundViaVariable = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Bound of this variable references variable '#name' from the same declaration.""",
    withArguments: _withArgumentsNonSimpleBoundViaVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNonSimpleBoundViaVariable =
    const Code<Message Function(String name)>("NonSimpleBoundViaVariable",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonSimpleBoundViaVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNonSimpleBoundViaVariable,
      problemMessage:
          """Bound of this variable references variable '${name}' from the same declaration.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonVoidReturnOperator = messageNonVoidReturnOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonVoidReturnOperator = const MessageCode(
    "NonVoidReturnOperator",
    analyzerCodes: <String>["NON_VOID_RETURN_FOR_OPERATOR"],
    problemMessage: r"""The return type of the operator []= must be 'void'.""",
    correctionMessage: r"""Try changing the return type to 'void'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonVoidReturnSetter = messageNonVoidReturnSetter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonVoidReturnSetter = const MessageCode(
    "NonVoidReturnSetter",
    analyzerCodes: <String>["NON_VOID_RETURN_FOR_SETTER"],
    problemMessage:
        r"""The return type of the setter must be 'void' or absent.""",
    correctionMessage:
        r"""Try removing the return type, or define a method rather than a setter.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNotAConstantExpression = messageNotAConstantExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotAConstantExpression = const MessageCode(
    "NotAConstantExpression",
    analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"],
    problemMessage: r"""Not a constant expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateNotAPrefixInTypeAnnotation = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""'#name.#name2' can't be used as a type because '#name' doesn't refer to an import prefix.""",
    withArguments: _withArgumentsNotAPrefixInTypeAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeNotAPrefixInTypeAnnotation =
    const Code<Message Function(String name, String name2)>(
        "NotAPrefixInTypeAnnotation",
        analyzerCodes: <String>["NOT_A_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAPrefixInTypeAnnotation(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeNotAPrefixInTypeAnnotation,
      problemMessage:
          """'${name}.${name2}' can't be used as a type because '${name}' doesn't refer to an import prefix.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNotAType =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""'#name' isn't a type.""",
        withArguments: _withArgumentsNotAType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNotAType =
    const Code<Message Function(String name)>("NotAType",
        analyzerCodes: <String>["NOT_A_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAType(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNotAType,
      problemMessage: """'${name}' isn't a type.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNotATypeContext = messageNotATypeContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotATypeContext = const MessageCode("NotATypeContext",
    severity: Severity.context, problemMessage: r"""This isn't a type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNotAnLvalue = messageNotAnLvalue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNotAnLvalue = const MessageCode("NotAnLvalue",
    analyzerCodes: <String>["NOT_AN_LVALUE"],
    problemMessage: r"""Can't assign to this.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateNotBinaryOperator =
    const Template<Message Function(Token token)>(
        problemMessageTemplate: r"""'#lexeme' isn't a binary operator.""",
        withArguments: _withArgumentsNotBinaryOperator);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeNotBinaryOperator =
    const Code<Message Function(Token token)>(
  "NotBinaryOperator",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotBinaryOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeNotBinaryOperator,
      problemMessage: """'${lexeme}' isn't a binary operator.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateNotConstantExpression =
    const Template<Message Function(String string)>(
        problemMessageTemplate: r"""#string is not a constant expression.""",
        withArguments: _withArgumentsNotConstantExpression);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeNotConstantExpression =
    const Code<Message Function(String string)>("NotConstantExpression",
        analyzerCodes: <String>["NOT_CONSTANT_EXPRESSION"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotConstantExpression(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeNotConstantExpression,
      problemMessage: """${string} is not a constant expression.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNullAwareCascadeOutOfOrder =
    messageNullAwareCascadeOutOfOrder;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNullAwareCascadeOutOfOrder = const MessageCode(
    "NullAwareCascadeOutOfOrder",
    index: 96,
    problemMessage:
        r"""The '?..' cascade operator must be first in the cascade sequence.""",
    correctionMessage:
        r"""Try moving the '?..' operator to be the first cascade operator in the sequence.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableInterfaceError =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't implement '#name' because it's marked with '?'.""",
        withArguments: _withArgumentsNullableInterfaceError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNullableInterfaceError =
    const Code<Message Function(String name)>(
  "NullableInterfaceError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableInterfaceError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNullableInterfaceError,
      problemMessage:
          """Can't implement '${name}' because it's marked with '?'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableMixinError =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't mix '#name' in because it's marked with '?'.""",
        withArguments: _withArgumentsNullableMixinError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNullableMixinError =
    const Code<Message Function(String name)>(
  "NullableMixinError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableMixinError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNullableMixinError,
      problemMessage:
          """Can't mix '${name}' in because it's marked with '?'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNullableSpreadError = messageNullableSpreadError;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNullableSpreadError = const MessageCode(
    "NullableSpreadError",
    problemMessage:
        r"""An expression whose value can be 'null' must be null-checked before it can be dereferenced.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableSuperclassError =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't extend '#name' because it's marked with '?'.""",
        withArguments: _withArgumentsNullableSuperclassError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNullableSuperclassError =
    const Code<Message Function(String name)>(
  "NullableSuperclassError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableSuperclassError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNullableSuperclassError,
      problemMessage:
          """Can't extend '${name}' because it's marked with '?'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNullableTearoffError =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't tear off method '#name' from a potentially null value.""",
        withArguments: _withArgumentsNullableTearoffError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNullableTearoffError =
    const Code<Message Function(String name)>(
  "NullableTearoffError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNullableTearoffError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeNullableTearoffError,
      problemMessage:
          """Can't tear off method '${name}' from a potentially null value.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeObjectExtends = messageObjectExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectExtends = const MessageCode("ObjectExtends",
    problemMessage: r"""The class 'Object' can't have a superclass.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeObjectImplements = messageObjectImplements;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectImplements = const MessageCode(
    "ObjectImplements",
    problemMessage: r"""The class 'Object' can't implement anything.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeObjectMixesIn = messageObjectMixesIn;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageObjectMixesIn = const MessageCode("ObjectMixesIn",
    problemMessage: r"""The class 'Object' can't use mixins.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeOnlyTry = messageOnlyTry;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOnlyTry = const MessageCode("OnlyTry",
    index: 20,
    problemMessage:
        r"""A try block must be followed by an 'on', 'catch', or 'finally' clause.""",
    correctionMessage:
        r"""Try adding either a catch or finally clause, or remove the try statement.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateOperatorMinusParameterMismatch = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Operator '#name' should have zero or one parameter.""",
    correctionMessageTemplate:
        r"""With zero parameters, it has the syntactic form '-a', formally known as 'unary-'. With one parameter, it has the syntactic form 'a - b', formally known as '-'.""",
    withArguments: _withArgumentsOperatorMinusParameterMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOperatorMinusParameterMismatch =
    const Code<Message Function(String name)>("OperatorMinusParameterMismatch",
        analyzerCodes: <String>[
      "WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorMinusParameterMismatch(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOperatorMinusParameterMismatch,
      problemMessage:
          """Operator '${name}' should have zero or one parameter.""",
      correctionMessage:
          """With zero parameters, it has the syntactic form '-a', formally known as 'unary-'. With one parameter, it has the syntactic form 'a - b', formally known as '-'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorParameterMismatch0 =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Operator '#name' shouldn't have any parameters.""",
        withArguments: _withArgumentsOperatorParameterMismatch0);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOperatorParameterMismatch0 =
    const Code<Message Function(String name)>(
  "OperatorParameterMismatch0",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch0(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOperatorParameterMismatch0,
      problemMessage: """Operator '${name}' shouldn't have any parameters.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorParameterMismatch1 =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Operator '#name' should have exactly one parameter.""",
        withArguments: _withArgumentsOperatorParameterMismatch1);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOperatorParameterMismatch1 =
    const Code<Message Function(String name)>("OperatorParameterMismatch1",
        analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch1(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOperatorParameterMismatch1,
      problemMessage:
          """Operator '${name}' should have exactly one parameter.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateOperatorParameterMismatch2 =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Operator '#name' should have exactly two parameters.""",
        withArguments: _withArgumentsOperatorParameterMismatch2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOperatorParameterMismatch2 =
    const Code<Message Function(String name)>("OperatorParameterMismatch2",
        analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOperatorParameterMismatch2(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOperatorParameterMismatch2,
      problemMessage:
          """Operator '${name}' should have exactly two parameters.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeOperatorWithOptionalFormals =
    messageOperatorWithOptionalFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOperatorWithOptionalFormals = const MessageCode(
    "OperatorWithOptionalFormals",
    problemMessage: r"""An operator can't have optional parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeOperatorWithTypeParameters =
    messageOperatorWithTypeParameters;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOperatorWithTypeParameters = const MessageCode(
    "OperatorWithTypeParameters",
    index: 120,
    problemMessage:
        r"""Types parameters aren't allowed when defining an operator.""",
    correctionMessage: r"""Try removing the type parameters.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateOverriddenMethodCause =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""This is the overridden method ('#name').""",
        withArguments: _withArgumentsOverriddenMethodCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeOverriddenMethodCause =
    const Code<Message Function(String name)>("OverriddenMethodCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverriddenMethodCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeOverriddenMethodCause,
      problemMessage: """This is the overridden method ('${name}').""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateOverrideFewerNamedArguments = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""The method '#name' has fewer named arguments than those of overridden method '#name2'.""",
    withArguments: _withArgumentsOverrideFewerNamedArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeOverrideFewerNamedArguments =
    const Code<Message Function(String name, String name2)>(
        "OverrideFewerNamedArguments",
        analyzerCodes: <String>["INVALID_OVERRIDE_NAMED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerNamedArguments(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeOverrideFewerNamedArguments,
      problemMessage:
          """The method '${name}' has fewer named arguments than those of overridden method '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateOverrideFewerPositionalArguments = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""The method '#name' has fewer positional arguments than those of overridden method '#name2'.""",
    withArguments: _withArgumentsOverrideFewerPositionalArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeOverrideFewerPositionalArguments =
    const Code<Message Function(String name, String name2)>(
        "OverrideFewerPositionalArguments",
        analyzerCodes: <String>["INVALID_OVERRIDE_POSITIONAL"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideFewerPositionalArguments(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeOverrideFewerPositionalArguments,
      problemMessage:
          """The method '${name}' has fewer positional arguments than those of overridden method '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String name2,
        String
            name3)> templateOverrideMismatchNamedParameter = const Template<
        Message Function(String name, String name2, String name3)>(
    problemMessageTemplate:
        r"""The method '#name' doesn't have the named parameter '#name2' of overridden method '#name3'.""",
    withArguments: _withArgumentsOverrideMismatchNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, String name3)>
    codeOverrideMismatchNamedParameter =
    const Code<Message Function(String name, String name2, String name3)>(
        "OverrideMismatchNamedParameter",
        analyzerCodes: <String>["INVALID_OVERRIDE_NAMED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchNamedParameter(
    String name, String name2, String name3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  return new Message(codeOverrideMismatchNamedParameter,
      problemMessage:
          """The method '${name}' doesn't have the named parameter '${name2}' of overridden method '${name3}'.""",
      arguments: {'name': name, 'name2': name2, 'name3': name3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2, String name3)>
    templateOverrideMismatchRequiredNamedParameter =
    const Template<Message Function(String name, String name2, String name3)>(
        problemMessageTemplate:
            r"""The required named parameter '#name' in method '#name2' is not required in overridden method '#name3'.""",
        withArguments: _withArgumentsOverrideMismatchRequiredNamedParameter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2, String name3)>
    codeOverrideMismatchRequiredNamedParameter =
    const Code<Message Function(String name, String name2, String name3)>(
  "OverrideMismatchRequiredNamedParameter",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMismatchRequiredNamedParameter(
    String name, String name2, String name3) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  if (name3.isEmpty) throw 'No name provided';
  name3 = demangleMixinApplicationName(name3);
  return new Message(codeOverrideMismatchRequiredNamedParameter,
      problemMessage:
          """The required named parameter '${name}' in method '${name2}' is not required in overridden method '${name3}'.""",
      arguments: {'name': name, 'name2': name2, 'name3': name3});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateOverrideMoreRequiredArguments = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""The method '#name' has more required arguments than those of overridden method '#name2'.""",
    withArguments: _withArgumentsOverrideMoreRequiredArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeOverrideMoreRequiredArguments =
    const Code<Message Function(String name, String name2)>(
        "OverrideMoreRequiredArguments",
        analyzerCodes: <String>["INVALID_OVERRIDE_REQUIRED"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideMoreRequiredArguments(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeOverrideMoreRequiredArguments,
      problemMessage:
          """The method '${name}' has more required arguments than those of overridden method '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateOverrideTypeVariablesMismatch = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""Declared type variables of '#name' doesn't match those on overridden method '#name2'.""",
    withArguments: _withArgumentsOverrideTypeVariablesMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeOverrideTypeVariablesMismatch =
    const Code<Message Function(String name, String name2)>(
        "OverrideTypeVariablesMismatch",
        analyzerCodes: <String>["INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOverrideTypeVariablesMismatch(String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeOverrideTypeVariablesMismatch,
      problemMessage:
          """Declared type variables of '${name}' doesn't match those on overridden method '${name2}'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templatePackageNotFound =
    const Template<Message Function(String name, Uri uri_)>(
        problemMessageTemplate:
            r"""Couldn't resolve the package '#name' in '#uri'.""",
        withArguments: _withArgumentsPackageNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)> codePackageNotFound =
    const Code<Message Function(String name, Uri uri_)>(
  "PackageNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackageNotFound(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  return new Message(codePackageNotFound,
      problemMessage: """Couldn't resolve the package '${name}' in '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templatePackagesFileFormat =
    const Template<Message Function(String string)>(
        problemMessageTemplate:
            r"""Problem in packages configuration file: #string""",
        withArguments: _withArgumentsPackagesFileFormat);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codePackagesFileFormat =
    const Code<Message Function(String string)>(
  "PackagesFileFormat",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPackagesFileFormat(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codePackagesFileFormat,
      problemMessage: """Problem in packages configuration file: ${string}""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartExport = messagePartExport;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartExport = const MessageCode("PartExport",
    analyzerCodes: <String>["EXPORT_OF_NON_LIBRARY"],
    problemMessage:
        r"""Can't export this file because it contains a 'part of' declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartExportContext = messagePartExportContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartExportContext = const MessageCode(
    "PartExportContext",
    severity: Severity.context,
    problemMessage: r"""This is the file that can't be exported.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartInPart = messagePartInPart;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartInPart = const MessageCode("PartInPart",
    analyzerCodes: <String>["NON_PART_OF_DIRECTIVE_IN_PART"],
    problemMessage:
        r"""A file that's a part of a library can't have parts itself.""",
    correctionMessage:
        r"""Try moving the 'part' declaration to the containing library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartInPartLibraryContext = messagePartInPartLibraryContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartInPartLibraryContext = const MessageCode(
    "PartInPartLibraryContext",
    severity: Severity.context,
    problemMessage: r"""This is the containing library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Uri uri_)> templatePartOfInLibrary = const Template<
        Message Function(Uri uri_)>(
    problemMessageTemplate:
        r"""Can't import '#uri', because it has a 'part of' declaration.""",
    correctionMessageTemplate:
        r"""Try removing the 'part of' declaration, or using '#uri' as a part.""",
    withArguments: _withArgumentsPartOfInLibrary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codePartOfInLibrary =
    const Code<Message Function(Uri uri_)>("PartOfInLibrary",
        analyzerCodes: <String>["IMPORT_OF_NON_LIBRARY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfInLibrary(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codePartOfInLibrary,
      problemMessage:
          """Can't import '${uri}', because it has a 'part of' declaration.""",
      correctionMessage:
          """Try removing the 'part of' declaration, or using '${uri}' as a part.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Uri uri_,
        String name,
        String
            name2)> templatePartOfLibraryNameMismatch = const Template<
        Message Function(Uri uri_, String name, String name2)>(
    problemMessageTemplate:
        r"""Using '#uri' as part of '#name' but its 'part of' declaration says '#name2'.""",
    withArguments: _withArgumentsPartOfLibraryNameMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, String name, String name2)>
    codePartOfLibraryNameMismatch =
    const Code<Message Function(Uri uri_, String name, String name2)>(
        "PartOfLibraryNameMismatch",
        analyzerCodes: <String>["PART_OF_DIFFERENT_LIBRARY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfLibraryNameMismatch(
    Uri uri_, String name, String name2) {
  String? uri = relativizeUri(uri_);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codePartOfLibraryNameMismatch,
      problemMessage:
          """Using '${uri}' as part of '${name}' but its 'part of' declaration says '${name2}'.""",
      arguments: {'uri': uri_, 'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfSelf = messagePartOfSelf;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfSelf = const MessageCode("PartOfSelf",
    analyzerCodes: <String>["PART_OF_NON_PART"],
    problemMessage: r"""A file can't be a part of itself.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfTwice = messagePartOfTwice;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwice = const MessageCode("PartOfTwice",
    index: 25,
    problemMessage:
        r"""Only one part-of directive may be declared in a file.""",
    correctionMessage:
        r"""Try removing all but one of the part-of directives.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfTwoLibraries = messagePartOfTwoLibraries;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwoLibraries = const MessageCode(
    "PartOfTwoLibraries",
    analyzerCodes: <String>["PART_OF_DIFFERENT_LIBRARY"],
    problemMessage: r"""A file can't be part of more than one library.""",
    correctionMessage:
        r"""Try moving the shared declarations into the libraries, or into a new library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOfTwoLibrariesContext =
    messagePartOfTwoLibrariesContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOfTwoLibrariesContext = const MessageCode(
    "PartOfTwoLibrariesContext",
    severity: Severity.context,
    problemMessage: r"""Used as a part in this library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Uri uri_,
        Uri uri2_,
        Uri
            uri3_)> templatePartOfUriMismatch = const Template<
        Message Function(Uri uri_, Uri uri2_, Uri uri3_)>(
    problemMessageTemplate:
        r"""Using '#uri' as part of '#uri2' but its 'part of' declaration says '#uri3'.""",
    withArguments: _withArgumentsPartOfUriMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, Uri uri2_, Uri uri3_)>
    codePartOfUriMismatch =
    const Code<Message Function(Uri uri_, Uri uri2_, Uri uri3_)>(
        "PartOfUriMismatch",
        analyzerCodes: <String>["PART_OF_DIFFERENT_LIBRARY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUriMismatch(Uri uri_, Uri uri2_, Uri uri3_) {
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  String? uri3 = relativizeUri(uri3_);
  return new Message(codePartOfUriMismatch,
      problemMessage:
          """Using '${uri}' as part of '${uri2}' but its 'part of' declaration says '${uri3}'.""",
      arguments: {'uri': uri_, 'uri2': uri2_, 'uri3': uri3_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Uri uri_,
        Uri uri2_,
        String
            name)> templatePartOfUseUri = const Template<
        Message Function(Uri uri_, Uri uri2_, String name)>(
    problemMessageTemplate:
        r"""Using '#uri' as part of '#uri2' but its 'part of' declaration says '#name'.""",
    correctionMessageTemplate:
        r"""Try changing the 'part of' declaration to use a relative file name.""",
    withArguments: _withArgumentsPartOfUseUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_, Uri uri2_, String name)>
    codePartOfUseUri =
    const Code<Message Function(Uri uri_, Uri uri2_, String name)>(
        "PartOfUseUri",
        analyzerCodes: <String>["PART_OF_UNNAMED_LIBRARY"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartOfUseUri(Uri uri_, Uri uri2_, String name) {
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codePartOfUseUri,
      problemMessage:
          """Using '${uri}' as part of '${uri2}' but its 'part of' declaration says '${name}'.""",
      correctionMessage: """Try changing the 'part of' declaration to use a relative file name.""",
      arguments: {'uri': uri_, 'uri2': uri2_, 'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePartOrphan = messagePartOrphan;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePartOrphan = const MessageCode("PartOrphan",
    problemMessage: r"""This part doesn't have a containing library.""",
    correctionMessage: r"""Try removing the 'part of' declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templatePartTwice =
    const Template<Message Function(Uri uri_)>(
        problemMessageTemplate:
            r"""Can't use '#uri' as a part more than once.""",
        withArguments: _withArgumentsPartTwice);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codePartTwice =
    const Code<Message Function(Uri uri_)>("PartTwice",
        analyzerCodes: <String>["DUPLICATE_PART"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPartTwice(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codePartTwice,
      problemMessage: """Can't use '${uri}' as a part more than once.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchClassOrigin = messagePatchClassOrigin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchClassOrigin = const MessageCode(
    "PatchClassOrigin",
    severity: Severity.context,
    problemMessage: r"""This is the origin class.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchClassTypeVariablesMismatch =
    messagePatchClassTypeVariablesMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchClassTypeVariablesMismatch = const MessageCode(
    "PatchClassTypeVariablesMismatch",
    problemMessage:
        r"""A patch class must have the same number of type variables as its origin class.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchDeclarationMismatch = messagePatchDeclarationMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchDeclarationMismatch = const MessageCode(
    "PatchDeclarationMismatch",
    problemMessage: r"""This patch doesn't match origin declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchDeclarationOrigin = messagePatchDeclarationOrigin;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchDeclarationOrigin = const MessageCode(
    "PatchDeclarationOrigin",
    severity: Severity.context,
    problemMessage: r"""This is the origin declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templatePatchInjectionFailed =
    const Template<Message Function(String name, Uri uri_)>(
        problemMessageTemplate: r"""Can't inject '#name' into '#uri'.""",
        correctionMessageTemplate: r"""Try adding '@patch'.""",
        withArguments: _withArgumentsPatchInjectionFailed);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)> codePatchInjectionFailed =
    const Code<Message Function(String name, Uri uri_)>(
  "PatchInjectionFailed",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatchInjectionFailed(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  return new Message(codePatchInjectionFailed,
      problemMessage: """Can't inject '${name}' into '${uri}'.""",
      correctionMessage: """Try adding '@patch'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePatchNonExternal = messagePatchNonExternal;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePatchNonExternal = const MessageCode(
    "PatchNonExternal",
    problemMessage:
        r"""Can't apply this patch as its origin declaration isn't external.""",
    correctionMessage: r"""Try adding 'external' to the origin declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePlatformPrivateLibraryAccess =
    messagePlatformPrivateLibraryAccess;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePlatformPrivateLibraryAccess = const MessageCode(
    "PlatformPrivateLibraryAccess",
    analyzerCodes: <String>["IMPORT_INTERNAL_LIBRARY"],
    problemMessage: r"""Can't access platform private library.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePositionalAfterNamedArgument =
    messagePositionalAfterNamedArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalAfterNamedArgument = const MessageCode(
    "PositionalAfterNamedArgument",
    analyzerCodes: <String>["POSITIONAL_AFTER_NAMED_ARGUMENT"],
    problemMessage: r"""Place positional arguments before named arguments.""",
    correctionMessage:
        r"""Try moving the positional argument before the named arguments, or add a name to the argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePositionalParameterWithEquals =
    messagePositionalParameterWithEquals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalParameterWithEquals = const MessageCode(
    "PositionalParameterWithEquals",
    analyzerCodes: <String>["WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER"],
    problemMessage:
        r"""Positional optional parameters can't use ':' to specify a default value.""",
    correctionMessage: r"""Try replacing ':' with '='.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePrefixAfterCombinator = messagePrefixAfterCombinator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePrefixAfterCombinator = const MessageCode(
    "PrefixAfterCombinator",
    index: 6,
    problemMessage:
        r"""The prefix ('as' clause) should come before any show/hide combinators.""",
    correctionMessage: r"""Try moving the prefix before the combinators.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePrivateNamedParameter = messagePrivateNamedParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePrivateNamedParameter = const MessageCode(
    "PrivateNamedParameter",
    analyzerCodes: <String>["PRIVATE_OPTIONAL_PARAMETER"],
    problemMessage: r"""An optional named parameter can't start with '_'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRedirectingConstructorWithAnotherInitializer =
    messageRedirectingConstructorWithAnotherInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectingConstructorWithAnotherInitializer =
    const MessageCode("RedirectingConstructorWithAnotherInitializer",
        analyzerCodes: <String>["FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR"],
        problemMessage:
            r"""A redirecting constructor can't have other initializers.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRedirectingConstructorWithBody =
    messageRedirectingConstructorWithBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectingConstructorWithBody = const MessageCode(
    "RedirectingConstructorWithBody",
    index: 22,
    problemMessage: r"""Redirecting constructors can't have a body.""",
    correctionMessage:
        r"""Try removing the body, or not making this a redirecting constructor.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRedirectingConstructorWithMultipleRedirectInitializers =
    messageRedirectingConstructorWithMultipleRedirectInitializers;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
    messageRedirectingConstructorWithMultipleRedirectInitializers =
    const MessageCode("RedirectingConstructorWithMultipleRedirectInitializers",
        analyzerCodes: <String>["MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS"],
        problemMessage:
            r"""A redirecting constructor can't have more than one redirection.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRedirectingConstructorWithSuperInitializer =
    messageRedirectingConstructorWithSuperInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectingConstructorWithSuperInitializer =
    const MessageCode("RedirectingConstructorWithSuperInitializer",
        analyzerCodes: <String>["SUPER_IN_REDIRECTING_CONSTRUCTOR"],
        problemMessage:
            r"""A redirecting constructor can't have a 'super' initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRedirectionInNonFactory = messageRedirectionInNonFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRedirectionInNonFactory = const MessageCode(
    "RedirectionInNonFactory",
    index: 21,
    problemMessage:
        r"""Only factory constructor can specify '=' redirection.""",
    correctionMessage:
        r"""Try making this a factory constructor, or remove the redirection.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateRedirectionTargetNotFound =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Redirection constructor target not found: '#name'""",
        withArguments: _withArgumentsRedirectionTargetNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeRedirectionTargetNotFound =
    const Code<Message Function(String name)>("RedirectionTargetNotFound",
        analyzerCodes: <String>["REDIRECT_TO_MISSING_CONSTRUCTOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectionTargetNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeRedirectionTargetNotFound,
      problemMessage: """Redirection constructor target not found: '${name}'""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateRequiredNamedParameterHasDefaultValueError =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Named parameter '#name' is required and can't have a default value.""",
        withArguments:
            _withArgumentsRequiredNamedParameterHasDefaultValueError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeRequiredNamedParameterHasDefaultValueError =
    const Code<Message Function(String name)>(
  "RequiredNamedParameterHasDefaultValueError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRequiredNamedParameterHasDefaultValueError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeRequiredNamedParameterHasDefaultValueError,
      problemMessage:
          """Named parameter '${name}' is required and can't have a default value.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRequiredParameterWithDefault =
    messageRequiredParameterWithDefault;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRequiredParameterWithDefault = const MessageCode(
    "RequiredParameterWithDefault",
    analyzerCodes: <String>["NAMED_PARAMETER_OUTSIDE_GROUP"],
    problemMessage: r"""Non-optional parameters can't have a default value.""",
    correctionMessage:
        r"""Try removing the default value or making the parameter optional.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRethrowNotCatch = messageRethrowNotCatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRethrowNotCatch = const MessageCode("RethrowNotCatch",
    analyzerCodes: <String>["RETHROW_OUTSIDE_CATCH"],
    problemMessage: r"""'rethrow' can only be used in catch clauses.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnFromVoidFunction = messageReturnFromVoidFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnFromVoidFunction = const MessageCode(
    "ReturnFromVoidFunction",
    analyzerCodes: <String>["RETURN_OF_INVALID_TYPE"],
    problemMessage: r"""Can't return a value from a void function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnTypeFunctionExpression =
    messageReturnTypeFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnTypeFunctionExpression = const MessageCode(
    "ReturnTypeFunctionExpression",
    problemMessage: r"""A function expression can't have a return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnWithoutExpression = messageReturnWithoutExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnWithoutExpression = const MessageCode(
    "ReturnWithoutExpression",
    analyzerCodes: <String>["RETURN_WITHOUT_VALUE"],
    severity: Severity.warning,
    problemMessage:
        r"""Must explicitly return a value from a non-void function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnWithoutExpressionAsync =
    messageReturnWithoutExpressionAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnWithoutExpressionAsync = const MessageCode(
    "ReturnWithoutExpressionAsync",
    problemMessage:
        r"""A value must be explicitly returned from a non-void async function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnWithoutExpressionSync =
    messageReturnWithoutExpressionSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnWithoutExpressionSync = const MessageCode(
    "ReturnWithoutExpressionSync",
    problemMessage:
        r"""A value must be explicitly returned from a non-void function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateSdkRootNotFound =
    const Template<Message Function(Uri uri_)>(
        problemMessageTemplate: r"""SDK root directory not found: #uri.""",
        withArguments: _withArgumentsSdkRootNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeSdkRootNotFound =
    const Code<Message Function(Uri uri_)>(
  "SdkRootNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkRootNotFound(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codeSdkRootNotFound,
      problemMessage: """SDK root directory not found: ${uri}.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Uri
            uri_)> templateSdkSpecificationNotFound = const Template<
        Message Function(Uri uri_)>(
    problemMessageTemplate: r"""SDK libraries specification not found: #uri.""",
    correctionMessageTemplate:
        r"""Normally, the specification is a file named 'libraries.json' in the Dart SDK install location.""",
    withArguments: _withArgumentsSdkSpecificationNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeSdkSpecificationNotFound =
    const Code<Message Function(Uri uri_)>(
  "SdkSpecificationNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSpecificationNotFound(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codeSdkSpecificationNotFound,
      problemMessage: """SDK libraries specification not found: ${uri}.""",
      correctionMessage:
          """Normally, the specification is a file named 'libraries.json' in the Dart SDK install location.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateSdkSummaryNotFound =
    const Template<Message Function(Uri uri_)>(
        problemMessageTemplate: r"""SDK summary not found: #uri.""",
        withArguments: _withArgumentsSdkSummaryNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeSdkSummaryNotFound =
    const Code<Message Function(Uri uri_)>(
  "SdkSummaryNotFound",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSdkSummaryNotFound(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codeSdkSummaryNotFound,
      problemMessage: """SDK summary not found: ${uri}.""",
      arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetLiteralTooManyTypeArguments =
    messageSetLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetLiteralTooManyTypeArguments = const MessageCode(
    "SetLiteralTooManyTypeArguments",
    problemMessage: r"""A set literal requires exactly one type argument.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetOrMapLiteralTooManyTypeArguments =
    messageSetOrMapLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetOrMapLiteralTooManyTypeArguments = const MessageCode(
    "SetOrMapLiteralTooManyTypeArguments",
    problemMessage:
        r"""A set or map literal requires exactly one or two type arguments, respectively.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetterConstructor = messageSetterConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterConstructor = const MessageCode(
    "SetterConstructor",
    index: 104,
    problemMessage: r"""Constructors can't be a setter.""",
    correctionMessage: r"""Try removing 'set'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSetterNotFound =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Setter not found: '#name'.""",
        withArguments: _withArgumentsSetterNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSetterNotFound =
    const Code<Message Function(String name)>("SetterNotFound",
        analyzerCodes: <String>["UNDEFINED_SETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSetterNotFound,
      problemMessage: """Setter not found: '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetterNotSync = messageSetterNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterNotSync = const MessageCode("SetterNotSync",
    analyzerCodes: <String>["INVALID_MODIFIER_ON_SETTER"],
    problemMessage: r"""Setters can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetterWithWrongNumberOfFormals =
    messageSetterWithWrongNumberOfFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterWithWrongNumberOfFormals = const MessageCode(
    "SetterWithWrongNumberOfFormals",
    analyzerCodes: <String>["WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER"],
    problemMessage: r"""A setter should have exactly one formal parameter.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int count2,
        num _num1,
        num _num2,
        num
            _num3)> templateSourceBodySummary = const Template<
        Message Function(
            int count, int count2, num _num1, num _num2, num _num3)>(
    problemMessageTemplate:
        r"""Built bodies for #count compilation units (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/compilation unit.""",
    withArguments: _withArgumentsSourceBodySummary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(int count, int count2, num _num1, num _num2,
        num _num3)> codeSourceBodySummary = const Code<
    Message Function(int count, int count2, num _num1, num _num2, num _num3)>(
  "SourceBodySummary",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceBodySummary(
    int count, int count2, num _num1, num _num2, num _num3) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (_num1 == null) throw 'No number provided';
  String num1 = _num1.toStringAsFixed(3);
  // ignore: unnecessary_null_comparison
  if (_num2 == null) throw 'No number provided';
  String num2 = _num2.toStringAsFixed(3).padLeft(12);
  // ignore: unnecessary_null_comparison
  if (_num3 == null) throw 'No number provided';
  String num3 = _num3.toStringAsFixed(3).padLeft(12);
  return new Message(codeSourceBodySummary,
      problemMessage:
          """Built bodies for ${count} compilation units (${count2} bytes) in ${num1}ms, that is,
${num2} bytes/ms, and
${num3} ms/compilation unit.""",
      arguments: {
        'count': count,
        'count2': count2,
        'num1': _num1,
        'num2': _num2,
        'num3': _num3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int count2,
        num _num1,
        num _num2,
        num
            _num3)> templateSourceOutlineSummary = const Template<
        Message Function(
            int count, int count2, num _num1, num _num2, num _num3)>(
    problemMessageTemplate:
        r"""Built outlines for #count compilation units (#count2 bytes) in #num1%.3ms, that is,
#num2%12.3 bytes/ms, and
#num3%12.3 ms/compilation unit.""",
    withArguments: _withArgumentsSourceOutlineSummary);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<
    Message Function(int count, int count2, num _num1, num _num2,
        num _num3)> codeSourceOutlineSummary = const Code<
    Message Function(int count, int count2, num _num1, num _num2, num _num3)>(
  "SourceOutlineSummary",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSourceOutlineSummary(
    int count, int count2, num _num1, num _num2, num _num3) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (_num1 == null) throw 'No number provided';
  String num1 = _num1.toStringAsFixed(3);
  // ignore: unnecessary_null_comparison
  if (_num2 == null) throw 'No number provided';
  String num2 = _num2.toStringAsFixed(3).padLeft(12);
  // ignore: unnecessary_null_comparison
  if (_num3 == null) throw 'No number provided';
  String num3 = _num3.toStringAsFixed(3).padLeft(12);
  return new Message(codeSourceOutlineSummary,
      problemMessage:
          """Built outlines for ${count} compilation units (${count2} bytes) in ${num1}ms, that is,
${num2} bytes/ms, and
${num3} ms/compilation unit.""",
      arguments: {
        'count': count,
        'count2': count2,
        'num1': _num1,
        'num2': _num2,
        'num3': _num3
      });
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSpreadElement = messageSpreadElement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSpreadElement = const MessageCode("SpreadElement",
    severity: Severity.context, problemMessage: r"""Iterable spread.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSpreadMapElement = messageSpreadMapElement;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSpreadMapElement = const MessageCode(
    "SpreadMapElement",
    severity: Severity.context,
    problemMessage: r"""Map spread.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStackOverflow = messageStackOverflow;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStackOverflow = const MessageCode("StackOverflow",
    index: 19,
    problemMessage:
        r"""The file has too many nested expressions or statements.""",
    correctionMessage: r"""Try simplifying the code.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticAndInstanceConflict =
    messageStaticAndInstanceConflict;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticAndInstanceConflict = const MessageCode(
    "StaticAndInstanceConflict",
    analyzerCodes: <String>["CONFLICTING_STATIC_AND_INSTANCE"],
    problemMessage:
        r"""This static member conflicts with an instance member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticAndInstanceConflictCause =
    messageStaticAndInstanceConflictCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticAndInstanceConflictCause = const MessageCode(
    "StaticAndInstanceConflictCause",
    severity: Severity.context,
    problemMessage: r"""This is the instance member.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticConstructor = messageStaticConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticConstructor = const MessageCode(
    "StaticConstructor",
    index: 4,
    problemMessage: r"""Constructors can't be static.""",
    correctionMessage: r"""Try removing the keyword 'static'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticOperator = messageStaticOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticOperator = const MessageCode("StaticOperator",
    index: 17,
    problemMessage: r"""Operators can't be static.""",
    correctionMessage: r"""Try removing the keyword 'static'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStaticTearOffFromInstantiatedClass =
    messageStaticTearOffFromInstantiatedClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStaticTearOffFromInstantiatedClass = const MessageCode(
    "StaticTearOffFromInstantiatedClass",
    problemMessage:
        r"""Cannot access static member on an instantiated generic class.""",
    correctionMessage:
        r"""Try removing the type arguments or placing them after the member name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStrongModeNNBDButOptOut = messageStrongModeNNBDButOptOut;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStrongModeNNBDButOptOut = const MessageCode(
    "StrongModeNNBDButOptOut",
    problemMessage:
        r"""A library can't opt out of null safety by default, when using sound null safety.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        List<String>
            _names)> templateStrongModeNNBDPackageOptOut = const Template<
        Message Function(List<String> _names)>(
    problemMessageTemplate:
        r"""Cannot run with sound null safety, because the following dependencies
don't support null safety:

#names

For solutions, see https://dart.dev/go/unsound-null-safety""",
    withArguments: _withArgumentsStrongModeNNBDPackageOptOut);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(List<String> _names)>
    codeStrongModeNNBDPackageOptOut =
    const Code<Message Function(List<String> _names)>(
  "StrongModeNNBDPackageOptOut",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsStrongModeNNBDPackageOptOut(List<String> _names) {
  if (_names.isEmpty) throw 'No names provided';
  String names = itemizeNames(_names);
  return new Message(codeStrongModeNNBDPackageOptOut,
      problemMessage:
          """Cannot run with sound null safety, because the following dependencies
don't support null safety:

${names}

For solutions, see https://dart.dev/go/unsound-null-safety""",
      arguments: {'names': _names});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStrongWithWeakDillLibrary =
    messageStrongWithWeakDillLibrary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStrongWithWeakDillLibrary = const MessageCode(
    "StrongWithWeakDillLibrary",
    problemMessage:
        r"""Loaded library is compiled with unsound null safety and cannot be used in compilation for sound null safety.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperAsExpression = messageSuperAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperAsExpression = const MessageCode(
    "SuperAsExpression",
    analyzerCodes: <String>["SUPER_AS_EXPRESSION"],
    problemMessage: r"""Can't use 'super' as an expression.""",
    correctionMessage:
        r"""To delegate a constructor to a super constructor, put the super call as an initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperAsIdentifier = messageSuperAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperAsIdentifier = const MessageCode(
    "SuperAsIdentifier",
    analyzerCodes: <String>["SUPER_AS_EXPRESSION"],
    problemMessage: r"""Expected identifier, but got 'super'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperInitializerNotLast = messageSuperInitializerNotLast;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperInitializerNotLast = const MessageCode(
    "SuperInitializerNotLast",
    analyzerCodes: <String>["SUPER_INVOCATION_NOT_LAST"],
    problemMessage: r"""Can't have initializers after 'super'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperNullAware = messageSuperNullAware;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperNullAware = const MessageCode("SuperNullAware",
    index: 18,
    problemMessage:
        r"""The operator '?.' cannot be used with 'super' because 'super' cannot be null.""",
    correctionMessage: r"""Try replacing '?.' with '.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateSuperclassHasNoConstructor =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Superclass has no constructor named '#name'.""",
        withArguments: _withArgumentsSuperclassHasNoConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassHasNoConstructor =
    const Code<Message Function(String name)>("SuperclassHasNoConstructor",
        analyzerCodes: <String>[
      "UNDEFINED_CONSTRUCTOR_IN_INITIALIZER",
      "UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT"
    ]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoConstructor,
      problemMessage: """Superclass has no constructor named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateSuperclassHasNoDefaultConstructor = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""The superclass, '#name', has no unnamed constructor that takes no arguments.""",
    withArguments: _withArgumentsSuperclassHasNoDefaultConstructor);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeSuperclassHasNoDefaultConstructor =
    const Code<Message Function(String name)>(
        "SuperclassHasNoDefaultConstructor",
        analyzerCodes: <String>["NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoDefaultConstructor(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoDefaultConstructor,
      problemMessage:
          """The superclass, '${name}', has no unnamed constructor that takes no arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoGetter =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Superclass has no getter named '#name'.""",
        withArguments: _withArgumentsSuperclassHasNoGetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassHasNoGetter =
    const Code<Message Function(String name)>("SuperclassHasNoGetter",
        analyzerCodes: <String>["UNDEFINED_SUPER_GETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoGetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoGetter,
      problemMessage: """Superclass has no getter named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoMember =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Superclass has no member named '#name'.""",
        withArguments: _withArgumentsSuperclassHasNoMember);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassHasNoMember =
    const Code<Message Function(String name)>("SuperclassHasNoMember",
        analyzerCodes: <String>["UNDEFINED_SUPER_GETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMember(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoMember,
      problemMessage: """Superclass has no member named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoMethod =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Superclass has no method named '#name'.""",
        withArguments: _withArgumentsSuperclassHasNoMethod);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassHasNoMethod =
    const Code<Message Function(String name)>("SuperclassHasNoMethod",
        analyzerCodes: <String>["UNDEFINED_SUPER_METHOD"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoMethod(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoMethod,
      problemMessage: """Superclass has no method named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSuperclassHasNoSetter =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Superclass has no setter named '#name'.""",
        withArguments: _withArgumentsSuperclassHasNoSetter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassHasNoSetter =
    const Code<Message Function(String name)>("SuperclassHasNoSetter",
        analyzerCodes: <String>["UNDEFINED_SUPER_SETTER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassHasNoSetter(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassHasNoSetter,
      problemMessage: """Superclass has no setter named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String
            name)> templateSuperclassMethodArgumentMismatch = const Template<
        Message Function(String name)>(
    problemMessageTemplate:
        r"""Superclass doesn't have a method named '#name' with matching arguments.""",
    withArguments: _withArgumentsSuperclassMethodArgumentMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSuperclassMethodArgumentMismatch =
    const Code<Message Function(String name)>(
  "SuperclassMethodArgumentMismatch",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSuperclassMethodArgumentMismatch(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSuperclassMethodArgumentMismatch,
      problemMessage:
          """Superclass doesn't have a method named '${name}' with matching arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSupertypeIsFunction = messageSupertypeIsFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSupertypeIsFunction = const MessageCode(
    "SupertypeIsFunction",
    problemMessage: r"""Can't use a function type as supertype.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSupertypeIsIllegal =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""The type '#name' can't be used as supertype.""",
        withArguments: _withArgumentsSupertypeIsIllegal);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSupertypeIsIllegal =
    const Code<Message Function(String name)>("SupertypeIsIllegal",
        analyzerCodes: <String>["EXTENDS_NON_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsIllegal(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSupertypeIsIllegal,
      problemMessage: """The type '${name}' can't be used as supertype.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSupertypeIsTypeVariable =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""The type variable '#name' can't be used as supertype.""",
        withArguments: _withArgumentsSupertypeIsTypeVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSupertypeIsTypeVariable =
    const Code<Message Function(String name)>("SupertypeIsTypeVariable",
        analyzerCodes: <String>["EXTENDS_NON_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSupertypeIsTypeVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeSupertypeIsTypeVariable,
      problemMessage:
          """The type variable '${name}' can't be used as supertype.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchCaseFallThrough = messageSwitchCaseFallThrough;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchCaseFallThrough = const MessageCode(
    "SwitchCaseFallThrough",
    analyzerCodes: <String>["CASE_BLOCK_NOT_TERMINATED"],
    problemMessage: r"""Switch case may fall through to the next case.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchExpressionNotAssignableCause =
    messageSwitchExpressionNotAssignableCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchExpressionNotAssignableCause = const MessageCode(
    "SwitchExpressionNotAssignableCause",
    severity: Severity.context,
    problemMessage: r"""The switch expression is here.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchHasCaseAfterDefault =
    messageSwitchHasCaseAfterDefault;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchHasCaseAfterDefault = const MessageCode(
    "SwitchHasCaseAfterDefault",
    index: 16,
    problemMessage:
        r"""The default case should be the last case in a switch statement.""",
    correctionMessage:
        r"""Try moving the default case after the other case clauses.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSwitchHasMultipleDefaults =
    messageSwitchHasMultipleDefaults;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSwitchHasMultipleDefaults = const MessageCode(
    "SwitchHasMultipleDefaults",
    index: 15,
    problemMessage: r"""The 'default' case can only be declared once.""",
    correctionMessage: r"""Try removing all but one default case.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSyntheticToken = messageSyntheticToken;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSyntheticToken = const MessageCode("SyntheticToken",
    problemMessage: r"""This couldn't be parsed.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateThisAccessInFieldInitializer =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't access 'this' in a field initializer to read '#name'.""",
        withArguments: _withArgumentsThisAccessInFieldInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeThisAccessInFieldInitializer =
    const Code<Message Function(String name)>("ThisAccessInFieldInitializer",
        analyzerCodes: <String>["THIS_ACCESS_FROM_FIELD_INITIALIZER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisAccessInFieldInitializer(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeThisAccessInFieldInitializer,
      problemMessage:
          """Can't access 'this' in a field initializer to read '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeThisAsIdentifier = messageThisAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageThisAsIdentifier = const MessageCode(
    "ThisAsIdentifier",
    analyzerCodes: <String>["INVALID_REFERENCE_TO_THIS"],
    problemMessage: r"""Expected identifier, but got 'this'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeThisInNullAwareReceiver = messageThisInNullAwareReceiver;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageThisInNullAwareReceiver = const MessageCode(
    "ThisInNullAwareReceiver",
    severity: Severity.warning,
    problemMessage: r"""The receiver 'this' cannot be null.""",
    correctionMessage: r"""Try replacing '?.' with '.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateThisNotPromoted =
    const Template<Message Function(String string)>(
        problemMessageTemplate: r"""'this' can't be promoted.""",
        correctionMessageTemplate: r"""See #string""",
        withArguments: _withArgumentsThisNotPromoted);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeThisNotPromoted =
    const Code<Message Function(String string)>(
  "ThisNotPromoted",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisNotPromoted(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeThisNotPromoted,
      problemMessage: """'this' can't be promoted.""",
      correctionMessage: """See ${string}""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateThisOrSuperAccessInFieldInitializer =
    const Template<Message Function(String string)>(
        problemMessageTemplate:
            r"""Can't access '#string' in a field initializer.""",
        withArguments: _withArgumentsThisOrSuperAccessInFieldInitializer);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)>
    codeThisOrSuperAccessInFieldInitializer =
    const Code<Message Function(String string)>(
        "ThisOrSuperAccessInFieldInitializer",
        analyzerCodes: <String>["THIS_ACCESS_FROM_INITIALIZER"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsThisOrSuperAccessInFieldInitializer(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeThisOrSuperAccessInFieldInitializer,
      problemMessage: """Can't access '${string}' in a field initializer.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooFewArguments = const Template<
        Message Function(int count, int count2)>(
    problemMessageTemplate:
        r"""Too few positional arguments: #count required, #count2 given.""",
    withArguments: _withArgumentsTooFewArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)> codeTooFewArguments =
    const Code<Message Function(int count, int count2)>("TooFewArguments",
        analyzerCodes: <String>["NOT_ENOUGH_REQUIRED_ARGUMENTS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooFewArguments(int count, int count2) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  return new Message(codeTooFewArguments,
      problemMessage:
          """Too few positional arguments: ${count} required, ${count2} given.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int count,
        int
            count2)> templateTooManyArguments = const Template<
        Message Function(int count, int count2)>(
    problemMessageTemplate:
        r"""Too many positional arguments: #count allowed, but #count2 found.""",
    correctionMessageTemplate:
        r"""Try removing the extra positional arguments.""",
    withArguments: _withArgumentsTooManyArguments);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count, int count2)> codeTooManyArguments =
    const Code<Message Function(int count, int count2)>("TooManyArguments",
        analyzerCodes: <String>["EXTRA_POSITIONAL_ARGUMENTS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTooManyArguments(int count, int count2) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  // ignore: unnecessary_null_comparison
  if (count2 == null) throw 'No count provided';
  return new Message(codeTooManyArguments,
      problemMessage:
          """Too many positional arguments: ${count} allowed, but ${count2} found.""",
      correctionMessage: """Try removing the extra positional arguments.""",
      arguments: {'count': count, 'count2': count2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTopLevelOperator = messageTopLevelOperator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTopLevelOperator = const MessageCode(
    "TopLevelOperator",
    index: 14,
    problemMessage: r"""Operators must be declared within a class.""",
    correctionMessage:
        r"""Try removing the operator, moving it to a class, or converting it to be a function.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeAfterVar = messageTypeAfterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeAfterVar = const MessageCode("TypeAfterVar",
    index: 89,
    problemMessage:
        r"""Variables can't be declared using both 'var' and a type name.""",
    correctionMessage: r"""Try removing 'var.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(int count)> templateTypeArgumentMismatch =
    const Template<Message Function(int count)>(
        problemMessageTemplate: r"""Expected #count type arguments.""",
        withArguments: _withArgumentsTypeArgumentMismatch);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int count)> codeTypeArgumentMismatch =
    const Code<Message Function(int count)>("TypeArgumentMismatch",
        analyzerCodes: <String>["WRONG_NUMBER_OF_TYPE_ARGUMENTS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentMismatch(int count) {
  // ignore: unnecessary_null_comparison
  if (count == null) throw 'No count provided';
  return new Message(codeTypeArgumentMismatch,
      problemMessage: """Expected ${count} type arguments.""",
      arguments: {'count': count});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateTypeArgumentsOnTypeVariable =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Can't use type arguments with type variable '#name'.""",
        correctionMessageTemplate: r"""Try removing the type arguments.""",
        withArguments: _withArgumentsTypeArgumentsOnTypeVariable);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeTypeArgumentsOnTypeVariable =
    const Code<Message Function(String name)>("TypeArgumentsOnTypeVariable",
        index: 13);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentsOnTypeVariable(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeTypeArgumentsOnTypeVariable,
      problemMessage:
          """Can't use type arguments with type variable '${name}'.""",
      correctionMessage: """Try removing the type arguments.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeBeforeFactory = messageTypeBeforeFactory;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeBeforeFactory = const MessageCode(
    "TypeBeforeFactory",
    index: 57,
    problemMessage: r"""Factory constructors cannot have a return type.""",
    correctionMessage:
        r"""Try removing the type appearing before 'factory'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateTypeNotFound =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""Type '#name' not found.""",
        withArguments: _withArgumentsTypeNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeTypeNotFound =
    const Code<Message Function(String name)>("TypeNotFound",
        analyzerCodes: <String>["UNDEFINED_CLASS"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeNotFound(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeTypeNotFound,
      problemMessage: """Type '${name}' not found.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)> templateTypeOrigin =
    const Template<Message Function(String name, Uri uri_)>(
        problemMessageTemplate: r"""'#name' is from '#uri'.""",
        withArguments: _withArgumentsTypeOrigin);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)> codeTypeOrigin =
    const Code<Message Function(String name, Uri uri_)>(
  "TypeOrigin",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOrigin(String name, Uri uri_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  return new Message(codeTypeOrigin,
      problemMessage: """'${name}' is from '${uri}'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_, Uri uri2_)>
    templateTypeOriginWithFileUri =
    const Template<Message Function(String name, Uri uri_, Uri uri2_)>(
        problemMessageTemplate: r"""'#name' is from '#uri' ('#uri2').""",
        withArguments: _withArgumentsTypeOriginWithFileUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_, Uri uri2_)>
    codeTypeOriginWithFileUri =
    const Code<Message Function(String name, Uri uri_, Uri uri2_)>(
  "TypeOriginWithFileUri",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeOriginWithFileUri(String name, Uri uri_, Uri uri2_) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  String? uri = relativizeUri(uri_);
  String? uri2 = relativizeUri(uri2_);
  return new Message(codeTypeOriginWithFileUri,
      problemMessage: """'${name}' is from '${uri}' ('${uri2}').""",
      arguments: {'name': name, 'uri': uri_, 'uri2': uri2_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableDuplicatedName =
    messageTypeVariableDuplicatedName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableDuplicatedName = const MessageCode(
    "TypeVariableDuplicatedName",
    analyzerCodes: <String>["DUPLICATE_DEFINITION"],
    problemMessage:
        r"""A type variable can't have the same name as another.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateTypeVariableDuplicatedNameCause =
    const Template<Message Function(String name)>(
        problemMessageTemplate: r"""The other type variable named '#name'.""",
        withArguments: _withArgumentsTypeVariableDuplicatedNameCause);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeTypeVariableDuplicatedNameCause =
    const Code<Message Function(String name)>("TypeVariableDuplicatedNameCause",
        severity: Severity.context);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeVariableDuplicatedNameCause(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeTypeVariableDuplicatedNameCause,
      problemMessage: """The other type variable named '${name}'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableInConstantContext =
    messageTypeVariableInConstantContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableInConstantContext = const MessageCode(
    "TypeVariableInConstantContext",
    analyzerCodes: <String>["TYPE_PARAMETER_IN_CONST_EXPRESSION"],
    problemMessage: r"""Type variables can't be used as constants.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableInStaticContext =
    messageTypeVariableInStaticContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableInStaticContext = const MessageCode(
    "TypeVariableInStaticContext",
    analyzerCodes: <String>["TYPE_PARAMETER_REFERENCED_BY_STATIC"],
    problemMessage: r"""Type variables can't be used in static members.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeVariableSameNameAsEnclosing =
    messageTypeVariableSameNameAsEnclosing;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeVariableSameNameAsEnclosing = const MessageCode(
    "TypeVariableSameNameAsEnclosing",
    analyzerCodes: <String>["CONFLICTING_TYPE_VARIABLE_AND_CLASS"],
    problemMessage:
        r"""A type variable can't have the same name as its enclosing declaration.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefCause = messageTypedefCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefCause = const MessageCode("TypedefCause",
    severity: Severity.context,
    problemMessage: r"""The issue arises via this type alias.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefInClass = messageTypedefInClass;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefInClass = const MessageCode("TypedefInClass",
    index: 7,
    problemMessage: r"""Typedefs can't be declared inside classes.""",
    correctionMessage: r"""Try moving the typedef to the top-level.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefNotFunction = messageTypedefNotFunction;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNotFunction = const MessageCode(
    "TypedefNotFunction",
    analyzerCodes: <String>["INVALID_GENERIC_FUNCTION_TYPE"],
    problemMessage: r"""Can't create typedef from non-function type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefNotType = messageTypedefNotType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNotType = const MessageCode("TypedefNotType",
    analyzerCodes: <String>["INVALID_TYPE_IN_TYPEDEF"],
    problemMessage: r"""Can't create typedef from non-type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefNullableType = messageTypedefNullableType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefNullableType = const MessageCode(
    "TypedefNullableType",
    problemMessage: r"""Can't create typedef from nullable type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefTypeVariableNotConstructor =
    messageTypedefTypeVariableNotConstructor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefTypeVariableNotConstructor = const MessageCode(
    "TypedefTypeVariableNotConstructor",
    problemMessage:
        r"""Can't use a typedef denoting a type variable as a constructor, nor for a static member access.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefTypeVariableNotConstructorCause =
    messageTypedefTypeVariableNotConstructorCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefTypeVariableNotConstructorCause =
    const MessageCode("TypedefTypeVariableNotConstructorCause",
        severity: Severity.context,
        problemMessage: r"""This is the type variable ultimately denoted.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypedefUnaliasedTypeCause =
    messageTypedefUnaliasedTypeCause;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypedefUnaliasedTypeCause = const MessageCode(
    "TypedefUnaliasedTypeCause",
    severity: Severity.context,
    problemMessage: r"""This is the type denoted by the type alias.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnexpectedDollarInString = messageUnexpectedDollarInString;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnexpectedDollarInString = const MessageCode(
    "UnexpectedDollarInString",
    analyzerCodes: <String>["UNEXPECTED_DOLLAR_IN_STRING"],
    problemMessage:
        r"""A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).""",
    correctionMessage: r"""Try adding a backslash (\) to escape the '$'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        Token
            token)> templateUnexpectedModifierInNonNnbd = const Template<
        Message Function(Token token)>(
    problemMessageTemplate:
        r"""The modifier '#lexeme' is only available in null safe libraries.""",
    withArguments: _withArgumentsUnexpectedModifierInNonNnbd);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeUnexpectedModifierInNonNnbd =
    const Code<Message Function(Token token)>("UnexpectedModifierInNonNnbd",
        analyzerCodes: <String>["UNEXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnexpectedModifierInNonNnbd(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeUnexpectedModifierInNonNnbd,
      problemMessage:
          """The modifier '${lexeme}' is only available in null safe libraries.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateUnexpectedToken =
    const Template<Message Function(Token token)>(
        problemMessageTemplate: r"""Unexpected token '#lexeme'.""",
        withArguments: _withArgumentsUnexpectedToken);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeUnexpectedToken =
    const Code<Message Function(Token token)>("UnexpectedToken",
        analyzerCodes: <String>["UNEXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnexpectedToken(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeUnexpectedToken,
      problemMessage: """Unexpected token '${lexeme}'.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, Token token)>
    templateUnmatchedToken =
    const Template<Message Function(String string, Token token)>(
        problemMessageTemplate: r"""Can't find '#string' to match '#lexeme'.""",
        withArguments: _withArgumentsUnmatchedToken);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, Token token)> codeUnmatchedToken =
    const Code<Message Function(String string, Token token)>("UnmatchedToken",
        analyzerCodes: <String>["EXPECTED_TOKEN"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedToken(String string, Token token) {
  if (string.isEmpty) throw 'No string provided';
  String lexeme = token.lexeme;
  return new Message(codeUnmatchedToken,
      problemMessage: """Can't find '${string}' to match '${lexeme}'.""",
      arguments: {'string': string, 'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            name2)> templateUnresolvedPrefixInTypeAnnotation = const Template<
        Message Function(String name, String name2)>(
    problemMessageTemplate:
        r"""'#name.#name2' can't be used as a type because '#name' isn't defined.""",
    withArguments: _withArgumentsUnresolvedPrefixInTypeAnnotation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeUnresolvedPrefixInTypeAnnotation =
    const Code<Message Function(String name, String name2)>(
        "UnresolvedPrefixInTypeAnnotation",
        analyzerCodes: <String>["NOT_A_TYPE"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnresolvedPrefixInTypeAnnotation(
    String name, String name2) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (name2.isEmpty) throw 'No name provided';
  name2 = demangleMixinApplicationName(name2);
  return new Message(codeUnresolvedPrefixInTypeAnnotation,
      problemMessage:
          """'${name}.${name2}' can't be used as a type because '${name}' isn't defined.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateUnspecified =
    const Template<Message Function(String string)>(
        problemMessageTemplate: r"""#string""",
        withArguments: _withArgumentsUnspecified);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeUnspecified =
    const Code<Message Function(String string)>(
  "Unspecified",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnspecified(String string) {
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeUnspecified,
      problemMessage: """${string}""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnsupportedDartExt = messageUnsupportedDartExt;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsupportedDartExt = const MessageCode(
    "UnsupportedDartExt",
    problemMessage: r"""Dart native extensions are no longer supported.""",
    correctionMessage:
        r"""Migrate to using FFI instead (https://dart.dev/guides/libraries/c-interop)""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateUnsupportedOperator =
    const Template<Message Function(Token token)>(
        problemMessageTemplate: r"""The '#lexeme' operator is not supported.""",
        withArguments: _withArgumentsUnsupportedOperator);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeUnsupportedOperator =
    const Code<Message Function(Token token)>("UnsupportedOperator",
        analyzerCodes: <String>["UNSUPPORTED_OPERATOR"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnsupportedOperator(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeUnsupportedOperator,
      problemMessage: """The '${lexeme}' operator is not supported.""",
      arguments: {'lexeme': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnsupportedPrefixPlus = messageUnsupportedPrefixPlus;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsupportedPrefixPlus = const MessageCode(
    "UnsupportedPrefixPlus",
    analyzerCodes: <String>["MISSING_IDENTIFIER"],
    problemMessage: r"""'+' is not a prefix operator.""",
    correctionMessage: r"""Try removing '+'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnterminatedComment = messageUnterminatedComment;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedComment = const MessageCode(
    "UnterminatedComment",
    analyzerCodes: <String>["UNTERMINATED_MULTI_LINE_COMMENT"],
    problemMessage: r"""Comment starting with '/*' must end with '*/'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
        Message Function(String string, String string2)>
    templateUnterminatedString =
    const Template<Message Function(String string, String string2)>(
        problemMessageTemplate:
            r"""String starting with #string must end with #string2.""",
        withArguments: _withArgumentsUnterminatedString);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeUnterminatedString =
    const Code<Message Function(String string, String string2)>(
        "UnterminatedString",
        analyzerCodes: <String>["UNTERMINATED_STRING_LITERAL"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnterminatedString(String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeUnterminatedString,
      problemMessage:
          """String starting with ${string} must end with ${string2}.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnterminatedToken = messageUnterminatedToken;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedToken = const MessageCode(
    "UnterminatedToken",
    problemMessage: r"""Incomplete token.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Uri uri_)> templateUntranslatableUri =
    const Template<Message Function(Uri uri_)>(
        problemMessageTemplate: r"""Not found: '#uri'""",
        withArguments: _withArgumentsUntranslatableUri);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Uri uri_)> codeUntranslatableUri =
    const Code<Message Function(Uri uri_)>("UntranslatableUri",
        analyzerCodes: <String>["URI_DOES_NOT_EXIST"]);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUntranslatableUri(Uri uri_) {
  String? uri = relativizeUri(uri_);
  return new Message(codeUntranslatableUri,
      problemMessage: """Not found: '${uri}'""", arguments: {'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateValueForRequiredParameterNotProvidedError =
    const Template<Message Function(String name)>(
        problemMessageTemplate:
            r"""Required named parameter '#name' must be provided.""",
        withArguments: _withArgumentsValueForRequiredParameterNotProvidedError);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeValueForRequiredParameterNotProvidedError =
    const Code<Message Function(String name)>(
  "ValueForRequiredParameterNotProvidedError",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsValueForRequiredParameterNotProvidedError(String name) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  return new Message(codeValueForRequiredParameterNotProvidedError,
      problemMessage:
          """Required named parameter '${name}' must be provided.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVarAsTypeName = messageVarAsTypeName;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVarAsTypeName = const MessageCode("VarAsTypeName",
    index: 61,
    problemMessage: r"""The keyword 'var' can't be used as a type name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVarReturnType = messageVarReturnType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVarReturnType = const MessageCode("VarReturnType",
    index: 12,
    problemMessage: r"""The return type can't be 'var'.""",
    correctionMessage:
        r"""Try removing the keyword 'var', or replacing it with the name of the return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String name,
        String
            string)> templateVariableCouldBeNullDueToWrite = const Template<
        Message Function(String name, String string)>(
    problemMessageTemplate:
        r"""Variable '#name' could not be promoted due to an assignment.""",
    correctionMessageTemplate:
        r"""Try null checking the variable after the assignment.  See #string""",
    withArguments: _withArgumentsVariableCouldBeNullDueToWrite);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeVariableCouldBeNullDueToWrite =
    const Code<Message Function(String name, String string)>(
  "VariableCouldBeNullDueToWrite",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsVariableCouldBeNullDueToWrite(
    String name, String string) {
  if (name.isEmpty) throw 'No name provided';
  name = demangleMixinApplicationName(name);
  if (string.isEmpty) throw 'No string provided';
  return new Message(codeVariableCouldBeNullDueToWrite,
      problemMessage:
          """Variable '${name}' could not be promoted due to an assignment.""",
      correctionMessage:
          """Try null checking the variable after the assignment.  See ${string}""",
      arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVerificationErrorOriginContext =
    messageVerificationErrorOriginContext;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVerificationErrorOriginContext = const MessageCode(
    "VerificationErrorOriginContext",
    severity: Severity.context,
    problemMessage:
        r"""The node most likely is taken from here by a transformer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVoidExpression = messageVoidExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVoidExpression = const MessageCode("VoidExpression",
    analyzerCodes: <String>["USE_OF_VOID_RESULT"],
    problemMessage: r"""This expression has type 'void' and can't be used.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeVoidWithTypeArguments = messageVoidWithTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageVoidWithTypeArguments = const MessageCode(
    "VoidWithTypeArguments",
    index: 100,
    problemMessage: r"""Type 'void' can't have type arguments.""",
    correctionMessage: r"""Try removing the type arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeWeakWithStrongDillLibrary =
    messageWeakWithStrongDillLibrary;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWeakWithStrongDillLibrary = const MessageCode(
    "WeakWithStrongDillLibrary",
    problemMessage:
        r"""Loaded library is compiled with sound null safety and cannot be used in compilation for unsound null safety.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String string,
        String
            string2)> templateWebLiteralCannotBeRepresentedExactly = const Template<
        Message Function(String string, String string2)>(
    problemMessageTemplate:
        r"""The integer literal #string can't be represented exactly in JavaScript.""",
    correctionMessageTemplate:
        r"""Try changing the literal to something that can be represented in Javascript. In Javascript #string2 is the nearest value that can be represented exactly.""",
    withArguments: _withArgumentsWebLiteralCannotBeRepresentedExactly);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeWebLiteralCannotBeRepresentedExactly =
    const Code<Message Function(String string, String string2)>(
  "WebLiteralCannotBeRepresentedExactly",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsWebLiteralCannotBeRepresentedExactly(
    String string, String string2) {
  if (string.isEmpty) throw 'No string provided';
  if (string2.isEmpty) throw 'No string provided';
  return new Message(codeWebLiteralCannotBeRepresentedExactly,
      problemMessage:
          """The integer literal ${string} can't be represented exactly in JavaScript.""",
      correctionMessage: """Try changing the literal to something that can be represented in Javascript. In Javascript ${string2} is the nearest value that can be represented exactly.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeWithBeforeExtends = messageWithBeforeExtends;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageWithBeforeExtends = const MessageCode(
    "WithBeforeExtends",
    index: 11,
    problemMessage: r"""The extends clause must be before the with clause.""",
    correctionMessage:
        r"""Try moving the extends clause before the with clause.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeYieldAsIdentifier = messageYieldAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldAsIdentifier = const MessageCode(
    "YieldAsIdentifier",
    analyzerCodes: <String>["ASYNC_KEYWORD_USED_AS_IDENTIFIER"],
    problemMessage:
        r"""'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeYieldNotGenerator = messageYieldNotGenerator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldNotGenerator = const MessageCode(
    "YieldNotGenerator",
    analyzerCodes: <String>["YIELD_IN_NON_GENERATOR"],
    problemMessage:
        r"""'yield' can only be used in 'sync*' or 'async*' methods.""");
