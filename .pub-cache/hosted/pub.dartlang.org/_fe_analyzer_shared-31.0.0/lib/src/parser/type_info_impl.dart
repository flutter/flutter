// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.type_info_impl;

import '../messages/codes.dart' as codes;

import '../scanner/token.dart' show SyntheticToken, Token, TokenType;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN;

import '../util/link.dart' show Link;

import 'forwarding_listener.dart' show ForwardingListener;

import 'identifier_context.dart' show IdentifierContext;

import 'member_kind.dart' show MemberKind;

import 'listener.dart' show Listener;

import 'parser_impl.dart' show Parser;

import 'type_info.dart';

import 'util.dart'
    show
        optional,
        skipMetadata,
        splitGtEq,
        splitGtFromGtGtEq,
        splitGtFromGtGtGt,
        splitGtFromGtGtGtEq,
        splitGtGt,
        syntheticGt;

/// [SimpleType] is a specialized [TypeInfo] returned by [computeType]
/// when there is a single identifier as the type reference.
const TypeInfo simpleType = const SimpleType();

/// [SimpleNullableType] is a specialized [TypeInfo] returned by [computeType]
/// when there is a single identifier followed by `?` as the type reference.
const TypeInfo simpleNullableType = const SimpleNullableType();

/// [PrefixedType] is a specialized [TypeInfo] returned by [computeType]
/// when the type reference is of the form: identifier `.` identifier.
const TypeInfo prefixedType = const PrefixedType();

/// [SimpleTypeWith1Argument] is a specialized [TypeInfo] returned by
/// [computeType] when the type reference is of the form:
/// identifier `<` identifier `>`.
const TypeInfo simpleTypeWith1Argument =
    const SimpleTypeWith1Argument(simpleTypeArgument1);

/// [SimpleTypeWith1Argument] is a specialized [TypeInfo] returned by
/// [computeType] when the type reference is of the form:
/// identifier `<` identifier `>=`.
const TypeInfo simpleTypeWith1ArgumentGtEq =
    const SimpleTypeWith1Argument(simpleTypeArgument1GtEq);

/// [SimpleTypeWith1Argument] is a specialized [TypeInfo] returned by
/// [computeType] when the type reference is of the form:
/// identifier `<` identifier `>>`.
const TypeInfo simpleTypeWith1ArgumentGtGt =
    const SimpleTypeWith1Argument(simpleTypeArgument1GtGt);

/// [SimpleNullableTypeWith1Argument] is a specialized [TypeInfo] returned by
/// [computeType] when the type reference is of the form:
/// identifier `<` identifier `>` `?`.
const TypeInfo simpleNullableTypeWith1Argument =
    const SimpleNullableTypeWith1Argument();

/// [SimpleTypeArgument1] is a specialized [TypeParamOrArgInfo] returned by
/// [computeTypeParamOrArg] when the type reference is of the form:
/// `<` identifier `>`.
const TypeParamOrArgInfo simpleTypeArgument1 = const SimpleTypeArgument1();

/// [SimpleTypeArgument1] is a specialized [TypeParamOrArgInfo] returned by
/// [computeTypeParamOrArg] when the type reference is of the form:
/// `<` identifier `>=`.
const TypeParamOrArgInfo simpleTypeArgument1GtEq =
    const SimpleTypeArgument1GtEq();

/// [SimpleTypeArgument1] is a specialized [TypeParamOrArgInfo] returned by
/// [computeTypeParamOrArg] when the type reference is of the form:
/// `<` identifier `>>`.
const TypeParamOrArgInfo simpleTypeArgument1GtGt =
    const SimpleTypeArgument1GtGt();

/// See documentation on the [noType] const.
class NoType implements TypeInfo {
  const NoType();

  @override
  TypeInfo get asNonNullable => this;

  @override
  bool get couldBeExpression => false;

  @override
  bool get hasTypeArguments => false;

  @override
  bool get isNullable => false;

  @override
  bool get isFunctionType => false;

  @override
  bool get recovered => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) {
    parser.reportRecoverableErrorWithToken(
        token.next!, codes.templateExpectedType);
    parser.rewriter.insertSyntheticIdentifier(token);
    return simpleType.parseType(token, parser);
  }

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      ensureTypeNotVoid(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    parser.listener.handleNoType(token);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token;
  }
}

/// See documentation on the [prefixedType] const.
class PrefixedType implements TypeInfo {
  const PrefixedType();

  @override
  TypeInfo get asNonNullable => this;

  @override
  bool get couldBeExpression => true;

  @override
  bool get hasTypeArguments => false;

  @override
  bool get isNullable => false;

  @override
  bool get isFunctionType => false;

  @override
  bool get recovered => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    Token start = token = token.next!;
    assert(token.isKeywordOrIdentifier);
    Listener listener = parser.listener;
    listener.handleIdentifier(token, IdentifierContext.prefixedTypeReference);

    Token period = token = token.next!;
    assert(optional('.', token));

    token = token.next!;
    assert(token.isKeywordOrIdentifier);
    listener.handleIdentifier(
        token, IdentifierContext.typeReferenceContinuation);
    listener.handleQualified(period);

    listener.handleNoTypeArguments(token.next!);
    listener.handleType(start, /* questionMark = */ null);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next!.next!.next!;
  }
}

/// See documentation on the [simpleNullableTypeWith1Argument] const.
class SimpleNullableTypeWith1Argument extends SimpleTypeWith1Argument {
  const SimpleNullableTypeWith1Argument() : super(simpleTypeArgument1);

  @override
  TypeInfo get asNonNullable => simpleTypeWith1Argument;

  @override
  bool get isNullable => true;

  @override
  bool get isFunctionType => false;

  @override
  bool get recovered => false;

  @override
  Token parseTypeRest(Token start, Token token, Parser parser) {
    token = token.next!;
    assert(optional('?', token));
    parser.listener.handleType(start, token);
    return token;
  }

  @override
  Token skipType(Token token) {
    token = super.skipType(token).next!;
    assert(optional('?', token));
    return token;
  }
}

/// See documentation on the [simpleTypeWith1Argument] const.
class SimpleTypeWith1Argument implements TypeInfo {
  final TypeParamOrArgInfo typeArg;

  const SimpleTypeWith1Argument(this.typeArg);

  @override
  TypeInfo get asNonNullable => this;

  @override
  bool get couldBeExpression => false;

  @override
  bool get hasTypeArguments => true;

  @override
  bool get isNullable => false;

  @override
  bool get isFunctionType => false;

  @override
  bool get recovered => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    Token start = token = token.next!;
    assert(token.isKeywordOrIdentifier);
    parser.listener.handleIdentifier(token, IdentifierContext.typeReference);
    token = typeArg.parseArguments(token, parser);
    return parseTypeRest(start, token, parser);
  }

  Token parseTypeRest(Token start, Token token, Parser parser) {
    parser.listener.handleType(start, /* questionMark = */ null);
    return token;
  }

  @override
  Token skipType(Token token) {
    token = token.next!;
    assert(token.isKeywordOrIdentifier);
    return typeArg.skip(token);
  }
}

/// See documentation on the [simpleNullableType] const.
class SimpleNullableType extends SimpleType {
  const SimpleNullableType();

  @override
  TypeInfo get asNonNullable => simpleType;

  @override
  bool get isNullable => true;

  @override
  bool get isFunctionType => false;

  @override
  bool get recovered => false;

  @override
  Token parseTypeRest(Token start, Parser parser) {
    Token token = start.next!;
    assert(optional('?', token));
    parser.listener.handleType(start, token);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next!.next!;
  }
}

/// See documentation on the [simpleType] const.
class SimpleType implements TypeInfo {
  const SimpleType();

  @override
  TypeInfo get asNonNullable => this;

  @override
  bool get couldBeExpression => true;

  @override
  bool get hasTypeArguments => false;

  @override
  bool get isNullable => false;

  @override
  bool get isFunctionType => false;

  @override
  bool get recovered => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    token = token.next!;
    assert(isValidTypeReference(token));
    parser.listener.handleIdentifier(token, IdentifierContext.typeReference);
    token = noTypeParamOrArg.parseArguments(token, parser);
    return parseTypeRest(token, parser);
  }

  Token parseTypeRest(Token token, Parser parser) {
    parser.listener.handleType(token, /* questionMark = */ null);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next!;
  }
}

/// See documentation on the [voidType] const.
class VoidType implements TypeInfo {
  const VoidType();

  @override
  TypeInfo get asNonNullable => this;

  @override
  bool get couldBeExpression => false;

  @override
  bool get hasTypeArguments => false;

  @override
  bool get isNullable => false;

  @override
  bool get isFunctionType => false;

  @override
  bool get recovered => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) {
    // Report an error, then parse `void` as if it were a type name.
    parser.reportRecoverableError(token.next!, codes.messageInvalidVoid);
    return simpleType.parseTypeNotVoid(token, parser);
  }

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      ensureTypeNotVoid(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    Token voidKeyword = token = token.next!;
    bool hasTypeArguments = false;

    // Recovery: Skip past, but issue problem, if followed by type arguments.
    if (optional('<', token.next!)) {
      TypeParamOrArgInfo typeParam = computeTypeParamOrArg(token);
      if (typeParam != noTypeParamOrArg) {
        hasTypeArguments = true;
        parser.reportRecoverableError(
            token.next!, codes.messageVoidWithTypeArguments);
        token = typeParam.parseArguments(token, parser);
      }
    }
    if (hasTypeArguments) {
      parser.listener.handleVoidKeywordWithTypeArguments(voidKeyword);
    } else {
      // Normal case.
      parser.listener.handleVoidKeyword(voidKeyword);
    }
    return token;
  }

  @override
  Token skipType(Token token) {
    token = token.next!;
    // Recovery: Skip past if followed by type arguments.
    if (optional('<', token.next!)) {
      TypeParamOrArgInfo typeParam = computeTypeParamOrArg(token);
      if (typeParam != noTypeParamOrArg) {
        token = typeParam.skip(token);
      }
    }
    return token;
  }
}

bool looksLikeName(Token token) {
  return token.kind == IDENTIFIER_TOKEN ||
      optional('this', token) ||
      (token.isIdentifier &&
          // Although `typedef` is a legal identifier,
          // type `typedef` identifier is not legal and in this situation
          // `typedef` is probably a separate declaration.
          (!optional('typedef', token) || !token.next!.isIdentifier));
}

bool looksLikeNameOrEndOfBlock(Token token) {
  // End-of-file isn't a name, but this is called in a situation where
  // if there had been a name it would have used the type-info it had
  // collected --- this being eof probably mean the user is currently
  // typing and will probably write a name in a moment.
  // The same logic applies to "}" which ends for instance a class. Again,
  // the user is likely typing and will soon write a name.
  return looksLikeName(token) || token.isEof || optional('}', token);
}

/// When missing a comma, determine if the given token looks like it should
/// be part of a collection of type parameters or arguments.
bool looksLikeTypeParamOrArg(bool inDeclaration, Token token) {
  if (inDeclaration && token.kind == IDENTIFIER_TOKEN) {
    Token next = token.next!;
    if (next.kind == IDENTIFIER_TOKEN ||
        optional(',', next) ||
        isCloser(next)) {
      return true;
    }
  }
  return false;
}

/// Instances of [ComplexTypeInfo] are returned by [computeType] to represent
/// type references that cannot be represented by the constants above.
class ComplexTypeInfo implements TypeInfo {
  /// The first token in the type reference.
  Token start;

  /// Type arguments were seen during analysis.
  final TypeParamOrArgInfo typeArguments;

  /// The token before the trailing question mark or `null` if either
  /// 1) there is no trailing question mark, or
  /// 2) the trailing question mark is not part of the type reference.
  Token? beforeQuestionMark;

  /// The last token in the type reference.
  Token? end;

  /// The `Function` tokens before the start of type variables of function types
  /// as seen during analysis.
  Link<Token> typeVariableStarters = const Link<Token>();

  /// If the receiver represents a generalized function type then this indicates
  /// whether it has a return type, otherwise this is `null`.
  bool? gftHasReturnType;

  @override
  bool recovered;

  ComplexTypeInfo(Token beforeStart, this.typeArguments)
      : this.start = beforeStart.next!,
        recovered = typeArguments.recovered {
    // ignore: unnecessary_null_comparison
    assert(typeArguments != null);
  }

  ComplexTypeInfo._nonNullable(this.start, this.typeArguments, this.end,
      this.typeVariableStarters, this.gftHasReturnType, this.recovered);

  @override
  TypeInfo get asNonNullable {
    return beforeQuestionMark == null
        ? this
        : new ComplexTypeInfo._nonNullable(
            start,
            typeArguments,
            beforeQuestionMark,
            typeVariableStarters,
            gftHasReturnType,
            recovered);
  }

  @override
  bool get couldBeExpression =>
      typeArguments == noTypeParamOrArg && typeVariableStarters.isEmpty;

  @override
  bool get hasTypeArguments => typeArguments is! NoTypeParamOrArg;

  @override
  bool get isNullable => beforeQuestionMark != null;

  @override
  bool get isFunctionType => gftHasReturnType != null;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    assert(identical(token.next!, start));

    if (optional('.', start)) {
      // Recovery: Insert missing identifier without sending events
      start = parser.insertSyntheticIdentifier(
          token, IdentifierContext.prefixedTypeReference);
    }

    final List<Token> typeVariableEndGroups = <Token>[];
    for (Link<Token> t = typeVariableStarters; t.isNotEmpty; t = t.tail!) {
      parser.listener.beginFunctionType(start);
      typeVariableEndGroups.add(
          computeTypeParamOrArg(t.head, /* inDeclaration = */ true)
              .parseVariables(t.head, parser));
    }

    if (gftHasReturnType == false) {
      // A function type without return type.
      // Push the non-existing return type first. The loop below will
      // generate the full type.
      noType.parseType(token, parser);
    } else {
      Token typeRefOrPrefix = token.next!;
      if (optional('void', typeRefOrPrefix)) {
        token = voidType.parseType(token, parser);
      } else {
        if (!optional('.', typeRefOrPrefix) &&
            !optional('.', typeRefOrPrefix.next!)) {
          token =
              parser.ensureIdentifier(token, IdentifierContext.typeReference);
        } else {
          token = parser.ensureIdentifier(
              token, IdentifierContext.prefixedTypeReference);
          token = parser.parseQualifiedRest(
              token, IdentifierContext.typeReferenceContinuation);
          if (token.isSynthetic && end == typeRefOrPrefix.next) {
            // Recovery: Update `end` if a synthetic identifier was inserted.
            end = token;
          }
        }
        token = typeArguments.parseArguments(token, parser);

        // Only consume the `?` if it is part of the complex type
        Token? questionMark = token.next!;
        if (optional('?', questionMark) &&
            (typeVariableEndGroups.isNotEmpty || beforeQuestionMark != null)) {
          token = questionMark;
        } else {
          questionMark = null;
        }

        parser.listener.handleType(typeRefOrPrefix, questionMark);
      }
    }

    int endGroupIndex = typeVariableEndGroups.length - 1;
    for (Link<Token> t = typeVariableStarters; t.isNotEmpty; t = t.tail!) {
      token = token.next!;
      assert(optional('Function', token));
      Token functionToken = token;

      if (optional("<", token.next!)) {
        // Skip type parameters, they were parsed above.
        token = typeVariableEndGroups[endGroupIndex];
        assert(optional('>', token));
      }
      token = parser.parseFormalParametersRequiredOpt(
          token, MemberKind.GeneralizedFunctionType);

      // Only consume the `?` if it is part of the complex type
      Token? questionMark = token.next!;
      if (optional('?', questionMark) &&
          (endGroupIndex > 0 || beforeQuestionMark != null)) {
        token = questionMark;
      } else {
        questionMark = null;
      }

      --endGroupIndex;
      parser.listener.endFunctionType(functionToken, questionMark);
    }

    // There are two situations in which the [token] != [end]:
    // Valid code:    identifier `<` identifier `<` identifier `>>`
    //    where `>>` is replaced by two tokens.
    // Invalid code:  identifier `<` identifier identifier `>`
    //    where a synthetic `>` is inserted between the identifiers.
    assert(identical(token, end) || optional('>', token));

    // During recovery, [token] may be a synthetic that was inserted in the
    // middle of the type reference.
    end = token;
    return token;
  }

  @override
  Token skipType(Token token) {
    return end!;
  }

  /// Given `Function` non-identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeNoTypeGFT(Token beforeStart, bool required) {
    assert(optional('Function', start));
    assert(beforeStart.next == start);

    computeRest(beforeStart, required);
    if (gftHasReturnType == null) {
      return required ? simpleType : noType;
    }
    assert(end != null);
    return this;
  }

  /// Given void `Function` non-identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeVoidGFT(bool required) {
    assert(optional('void', start));
    assert(optional('Function', start.next!));

    computeRest(start, required);
    if (gftHasReturnType == null) {
      return voidType;
    }
    assert(end != null);
    return this;
  }

  /// Given identifier `Function` non-identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeIdentifierGFT(bool required) {
    assert(isValidTypeReference(start));
    assert(optional('Function', start.next!));

    computeRest(start, required);
    if (gftHasReturnType == null) {
      return simpleType;
    }
    assert(end != null);
    return this;
  }

  /// Given identifier `?` `Function` non-identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeIdentifierQuestionGFT(bool required) {
    assert(isValidTypeReference(start));
    assert(optional('?', start.next!));
    assert(optional('Function', start.next!.next!));

    computeRest(start, required);
    if (gftHasReturnType == null) {
      return simpleNullableType;
    }
    assert(end != null);
    return this;
  }

  /// Given a builtin, return the receiver so that parseType will report
  /// an error for the builtin used as a type.
  ComplexTypeInfo computeBuiltinOrVarAsType(bool required) {
    assert(start.type.isBuiltIn || optional('var', start));

    end = typeArguments.skip(start);
    computeRest(end!, required);
    assert(end != null);
    return this;
  }

  /// Given identifier `<` ... `>`, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeSimpleWithTypeArguments(bool required) {
    assert(isValidTypeReference(start));
    assert(optional('<', start.next!));
    assert(typeArguments != noTypeParamOrArg);

    end = typeArguments.skip(start);
    computeRest(end!, required);

    if (!required &&
        !looksLikeNameOrEndOfBlock(end!.next!) &&
        gftHasReturnType == null) {
      return noType;
    }
    assert(end != null);
    return this;
  }

  /// Given identifier `.` identifier (or `.` identifier or identifier `.`
  /// for recovery), compute the type and return the receiver or one of the
  /// [TypeInfo] constants.
  TypeInfo computePrefixedType(bool required) {
    Token token = start;
    if (!optional('.', token)) {
      assert(token.isKeywordOrIdentifier);
      token = token.next!;
    }
    assert(optional('.', token));
    if (token.next!.isKeywordOrIdentifier) {
      token = token.next!;
    }

    end = typeArguments.skip(token);
    computeRest(end!, required);
    if (!required && !looksLikeName(end!.next!) && gftHasReturnType == null) {
      return noType;
    }
    assert(end != null);
    return this;
  }

  void computeRest(Token token, bool required) {
    if (optional('?', token.next!)) {
      beforeQuestionMark = token;
      end = token = token.next!;
    }
    token = token.next!;
    while (optional('Function', token)) {
      Token typeVariableStart = token;
      // TODO(danrubel): Consider caching TypeParamOrArgInfo
      token =
          computeTypeParamOrArg(token, /* inDeclaration = */ true).skip(token);
      token = token.next!;
      if (!optional('(', token)) {
        break; // Not a function type.
      }
      if (token.endGroup == null) {
        break; // Not a function type.
      }
      token = token.endGroup!;
      if (!required) {
        Token next = token.next!;
        if (optional('?', next)) {
          next = next.next!;
        }
        if (!(next.isIdentifier || optional('this', next))) {
          break; // `Function` used as the name in a function declaration.
        }
      }
      assert(optional(')', token));
      gftHasReturnType ??= typeVariableStart != start;
      typeVariableStarters = typeVariableStarters.prepend(typeVariableStart);

      beforeQuestionMark = null;
      end = token;
      token = token.next!;

      if (optional('?', token)) {
        beforeQuestionMark = end;
        end = token;
        token = token.next!;
      }
    }
  }
}

/// See [noTypeParamOrArg].
class NoTypeParamOrArg extends TypeParamOrArgInfo {
  const NoTypeParamOrArg();

  @override
  int get typeArgumentCount => 0;

  @override
  Token parseArguments(Token token, Parser parser) {
    parser.listener.handleNoTypeArguments(token.next!);
    return token;
  }

  @override
  Token parseVariables(Token token, Parser parser) {
    parser.listener.handleNoTypeVariables(token.next!);
    return token;
  }

  @override
  Token skip(Token token) => token;
}

class SimpleTypeArgument1 extends TypeParamOrArgInfo {
  const SimpleTypeArgument1();

  @override
  bool get isSimpleTypeArgument => true;

  @override
  int get typeArgumentCount => 1;

  @override
  TypeInfo get typeInfo => simpleTypeWith1Argument;

  @override
  Token parseArguments(Token token, Parser parser) {
    Token beginGroup = token.next!;
    assert(optional('<', beginGroup));
    Token endGroup = parseEndGroup(beginGroup, beginGroup.next!);
    Listener listener = parser.listener;
    listener.beginTypeArguments(beginGroup);
    simpleType.parseType(beginGroup, parser);
    parser.listener.endTypeArguments(/* count = */ 1, beginGroup, endGroup);
    return endGroup;
  }

  @override
  Token parseVariables(Token token, Parser parser) {
    Token beginGroup = token.next!;
    assert(optional('<', beginGroup));
    token = beginGroup.next!;
    Token endGroup = parseEndGroup(beginGroup, token);
    Listener listener = parser.listener;
    listener.beginTypeVariables(beginGroup);
    listener.beginMetadataStar(token);
    listener.endMetadataStar(/* count = */ 0);
    listener.handleIdentifier(token, IdentifierContext.typeVariableDeclaration);
    listener.beginTypeVariable(token);
    listener.handleTypeVariablesDefined(token, /* count = */ 1);
    listener.handleNoType(token);
    listener.endTypeVariable(endGroup, /* index = */ 0,
        /* extendsOrSuper = */ null, /* variance = */ null);
    listener.endTypeVariables(beginGroup, endGroup);
    return endGroup;
  }

  @override
  Token skip(Token token) {
    token = token.next!;
    assert(optional('<', token));
    token = token.next!;
    assert(token.isKeywordOrIdentifier);
    return skipEndGroup(token);
  }

  Token skipEndGroup(Token token) {
    token = token.next!;
    assert(optional('>', token));
    return token;
  }

  Token parseEndGroup(Token beginGroup, Token token) {
    token = token.next!;
    assert(optional('>', token));
    return token;
  }
}

class SimpleTypeArgument1GtEq extends SimpleTypeArgument1 {
  const SimpleTypeArgument1GtEq();

  @override
  TypeInfo get typeInfo => simpleTypeWith1ArgumentGtEq;

  Token skipEndGroup(Token token) {
    token = token.next!;
    assert(optional('>=', token));
    return splitGtEq(token);
  }

  Token parseEndGroup(Token beginGroup, Token beforeEndGroup) {
    Token endGroup = beforeEndGroup.next!;
    if (!optional('>', endGroup)) {
      endGroup = splitGtEq(endGroup);
      endGroup.next!.setNext(endGroup.next!.next!);
    }
    beforeEndGroup.setNext(endGroup);
    return endGroup;
  }
}

class SimpleTypeArgument1GtGt extends SimpleTypeArgument1 {
  const SimpleTypeArgument1GtGt();

  @override
  TypeInfo get typeInfo => simpleTypeWith1ArgumentGtGt;

  Token skipEndGroup(Token token) {
    token = token.next!;
    assert(optional('>>', token));
    return splitGtGt(token);
  }

  Token parseEndGroup(Token beginGroup, Token beforeEndGroup) {
    Token endGroup = beforeEndGroup.next!;
    if (!optional('>', endGroup)) {
      endGroup = splitGtGt(endGroup);
      endGroup.next!.setNext(endGroup.next!.next!);
    }
    beforeEndGroup.setNext(endGroup);
    return endGroup;
  }
}

class ComplexTypeParamOrArgInfo extends TypeParamOrArgInfo {
  /// The first token in the type var.
  final Token start;

  /// If [inDeclaration] is `true`, then this will more aggressively recover
  /// given unbalanced `<` `>` and invalid parameters or arguments.
  final bool inDeclaration;

  // Only support variance parsing if it makes sense.
  // Allows parsing of variance for certain structures.
  // See https://github.com/dart-lang/language/issues/524
  final bool allowsVariance;

  @override
  int typeArgumentCount = 0;

  /// The `>` token which ends the type parameter or argument.
  /// This closer may be synthetic, points to the next token in the stream,
  /// is only used when skipping over the type parameters or arguments,
  /// and may not be part of the token stream.
  Token? skipEnd;

  @override
  bool recovered = false;

  ComplexTypeParamOrArgInfo(
      Token token, this.inDeclaration, this.allowsVariance)
      : assert(optional('<', token.next!)),
        // ignore: unnecessary_null_comparison
        assert(inDeclaration != null),
        // ignore: unnecessary_null_comparison
        assert(allowsVariance != null),
        start = token.next!;

  /// Parse the tokens and return the receiver or [noTypeParamOrArg] if there
  /// are no type parameters or arguments. This does not modify the token
  /// stream.
  TypeParamOrArgInfo compute() {
    Token token;
    Token next = start;
    while (true) {
      TypeInfo typeInfo =
          computeType(next, /* required = */ true, inDeclaration);
      recovered = recovered | typeInfo.recovered;
      if (typeInfo == noType) {
        while (typeInfo == noType && optional('@', next.next!)) {
          next = skipMetadata(next);
          typeInfo = computeType(next, /* required = */ true, inDeclaration);
        }
        if (typeInfo == noType) {
          if (next == start && !inDeclaration && !isCloser(next.next!)) {
            return noTypeParamOrArg;
          }
          if (!optional(',', next.next!)) {
            token = next;
            next = token.next!;
            break;
          }
        }
        assert(typeInfo != noType || optional(',', next.next!));
        // Fall through to process type (if any) and consume `,`
      }
      ++typeArgumentCount;
      token = typeInfo.skipType(next);
      next = token.next!;
      if (optional('extends', next)) {
        token = computeType(next, /* required = */ true, inDeclaration)
            .skipType(next);
        next = token.next!;
      }
      if (!optional(',', next)) {
        skipEnd = splitCloser(next);
        if (skipEnd != null) {
          return this;
        }
        if (!inDeclaration) {
          return noTypeParamOrArg;
        }

        // Recovery
        if (!looksLikeTypeParamOrArg(inDeclaration, next)) {
          break;
        }
        // Looks like missing comma. Continue looping.
        next = token;
      }
    }

    // Recovery
    skipEnd = splitCloser(next);
    if (skipEnd == null) {
      recovered = true;
      if (optional('(', next)) {
        token = next.endGroup!;
        next = token.next!;
      }
      skipEnd = splitCloser(next);
      if (skipEnd == null) {
        skipEnd = splitCloser(next.next!);
      }
      if (skipEnd == null) {
        skipEnd = syntheticGt(next);
      }
    }
    return this;
  }

  @override
  Token parseArguments(Token token, Parser parser) {
    assert(identical(token.next!, start));
    Token next = start;
    parser.listener.beginTypeArguments(start);
    int count = 0;
    while (true) {
      TypeInfo typeInfo =
          computeType(next, /* required = */ true, inDeclaration);
      if (typeInfo == noType) {
        // Recovery
        while (typeInfo == noType && optional('@', next.next!)) {
          Token atToken = next.next!;
          next = skipMetadata(next);
          parser.reportRecoverableErrorWithEnd(
              atToken, next, codes.messageAnnotationOnTypeArgument);
          typeInfo = computeType(next, /* required = */ true, inDeclaration);
        }
        // Fall through to process type (if any) and consume `,`
      }
      token = typeInfo.ensureTypeOrVoid(next, parser);
      next = token.next!;
      ++count;
      if (!optional(',', next)) {
        if (parseCloser(token)) {
          break;
        }

        // Recovery
        if (!looksLikeTypeParamOrArg(inDeclaration, next)) {
          token = parseUnexpectedEnd(token, /* isArguments = */ true, parser);
          break;
        }
        // Missing comma. Report error, insert comma, and continue looping.
        next = parseMissingComma(token, parser);
      }
    }
    Token endGroup = token.next!;
    parser.listener.endTypeArguments(count, start, endGroup);
    return endGroup;
  }

  @override
  Token parseVariables(Token token, Parser parser) {
    assert(identical(token.next!, start));
    Token next = start;
    Listener listener = parser.listener;
    listener.beginTypeVariables(start);
    int count = 0;

    Link<Token> typeStarts = const Link<Token>();
    Link<TypeInfo?> superTypeInfos = const Link<TypeInfo?>();
    Link<Token?> variances = const Link<Token?>();

    while (true) {
      token = parser.parseMetadataStar(next);

      Token variance = next.next!;
      Token? identifier = variance.next;
      if (allowsVariance &&
          isVariance(variance) &&
          identifier != null &&
          identifier.isKeywordOrIdentifier) {
        variances = variances.prepend(variance);

        // Recovery for multiple variance modifiers
        while (identifier != null &&
            isVariance(identifier) &&
            identifier.next != null &&
            identifier.next!.isKeywordOrIdentifier) {
          // Report an error and skip actual identifier
          parser.reportRecoverableError(
              identifier, codes.messageMultipleVarianceModifiers);
          variance = variance.next!;
          identifier = identifier.next!;
        }

        token = variance;
      } else {
        variances = variances.prepend(/* element = */ null);
      }

      next = parser.ensureIdentifier(
          token, IdentifierContext.typeVariableDeclaration);
      token = next;
      listener.beginTypeVariable(token);
      typeStarts = typeStarts.prepend(token);

      next = token.next!;
      if (optional('extends', next)) {
        TypeInfo typeInfo =
            computeType(next, /* required = */ true, inDeclaration);
        token = typeInfo.skipType(next);
        next = token.next!;
        superTypeInfos = superTypeInfos.prepend(typeInfo);
      } else {
        superTypeInfos = superTypeInfos.prepend(/* element = */ null);
      }

      ++count;
      if (!optional(',', next)) {
        if (isCloser(token)) {
          break;
        }

        // Recovery
        if (!looksLikeTypeParamOrArg(inDeclaration, next)) {
          break;
        }
        // Missing comma. Report error, insert comma, and continue looping.
        next = parseMissingComma(token, parser);
      }
    }

    assert(count > 0);
    assert(typeStarts.slowLength() == count);
    assert(superTypeInfos.slowLength() == count);
    assert(variances.slowLength() == count);
    listener.handleTypeVariablesDefined(token, count);

    Token? token3 = null;
    while (typeStarts.isNotEmpty) {
      Token token2 = typeStarts.head;
      TypeInfo? typeInfo = superTypeInfos.head;
      Token? variance = variances.head;

      Token? extendsOrSuper = null;
      Token next2 = token2.next!;
      if (typeInfo != null) {
        assert(optional('extends', next2));
        extendsOrSuper = next2;
        token2 = typeInfo.ensureTypeNotVoid(next2, parser);
        next2 = token2.next!;
      } else {
        assert(!optional('extends', next2));
        listener.handleNoType(token2);
      }
      // Type variables are "completed" in reverse order, so capture the last
      // consumed token from the first "completed" type variable.
      token3 ??= token2;
      listener.endTypeVariable(next2, --count, extendsOrSuper, variance);

      typeStarts = typeStarts.tail!;
      superTypeInfos = superTypeInfos.tail!;
      variances = variances.tail!;
    }

    if (!parseCloser(token3!)) {
      token3 = parseUnexpectedEnd(token3, /* isArguments = */ false, parser);
    }
    Token endGroup = token3.next!;
    listener.endTypeVariables(start, endGroup);
    return endGroup;
  }

  Token parseMissingComma(Token token, Parser parser) {
    Token next = token.next!;
    parser.reportRecoverableError(
        next, codes.templateExpectedButGot.withArguments(','));
    return parser.rewriter.insertToken(
        token, new SyntheticToken(TokenType.COMMA, next.charOffset));
  }

  Token parseUnexpectedEnd(Token token, bool isArguments, Parser parser) {
    Token next = token.next!;
    bool errorReported = token.isSynthetic || (next.isSynthetic && !next.isEof);

    bool typeFollowsExtends = false;
    if (optional('extends', next)) {
      if (!errorReported) {
        parser.reportRecoverableError(
            token, codes.templateExpectedAfterButGot.withArguments('>'));
        errorReported = true;
      }
      token = next;
      next = token.next!;
      typeFollowsExtends = isValidTypeReference(next);

      if (parseCloser(token)) {
        return token;
      }
    }

    if (typeFollowsExtends ||
        optional('dynamic', next) ||
        optional('void', next) ||
        optional('Function', next)) {
      TypeInfo invalidType = computeType(token, /* required = */ true);
      if (invalidType != noType) {
        if (!errorReported) {
          parser.reportRecoverableError(
              token, codes.templateExpectedAfterButGot.withArguments('>'));
          errorReported = true;
        }

        // Parse the type so that the token stream is properly modified,
        // but ensure that parser events are ignored by replacing the listener.
        final Listener originalListener = parser.listener;
        parser.listener = new ForwardingListener();
        token = invalidType.parseType(token, parser);
        next = token.next!;
        parser.listener = originalListener;

        if (parseCloser(token)) {
          return token;
        }
      }
    }

    TypeParamOrArgInfo invalidTypeVar =
        computeTypeParamOrArg(token, inDeclaration);
    if (invalidTypeVar != noTypeParamOrArg) {
      if (!errorReported) {
        parser.reportRecoverableError(
            token, codes.templateExpectedAfterButGot.withArguments('>'));
        errorReported = true;
      }

      // Parse the type so that the token stream is properly modified,
      // but ensure that parser events are ignored by replacing the listener.
      final Listener originalListener = parser.listener;
      parser.listener = new ForwardingListener();
      token = isArguments
          ? invalidTypeVar.parseArguments(token, parser)
          : invalidTypeVar.parseVariables(token, parser);
      next = token.next!;
      parser.listener = originalListener;

      if (parseCloser(token)) {
        return token;
      }
    }

    if (optional('(', next) && next.endGroup != null) {
      if (!errorReported) {
        // Only report an error if one has not already been reported.
        parser.reportRecoverableError(
            token, codes.templateExpectedAfterButGot.withArguments('>'));
        errorReported = true;
      }
      token = next.endGroup!;
      next = token.next!;

      if (parseCloser(token)) {
        return token;
      }
    }

    if (!errorReported) {
      // Only report an error if one has not already been reported.
      parser.reportRecoverableError(
          token, codes.templateExpectedAfterButGot.withArguments('>'));
    }
    if (parseCloser(next)) {
      return next;
    }
    Token? endGroup = start.endGroup;
    if (endGroup != null) {
      while (token.next != endGroup &&
          !token.isEof &&
          token.charOffset <= endGroup.charOffset) {
        token = token.next!;
      }
    } else {
      endGroup = syntheticGt(next);
      endGroup.setNext(next);
      token.setNext(endGroup);
    }
    return token;
  }

  @override
  Token skip(Token token) {
    assert(skipEnd != null);
    return skipEnd!;
  }
}

// Return `true` if [token] is one of `in`, `inout`, or `out`
bool isVariance(Token token) {
  return optional('in', token) ||
      optional('inout', token) ||
      optional('out', token);
}

/// Return `true` if [token] is one of `>`, `>>`, `>>>`, `>=`, `>>=`, or `>>>=`.
bool isCloser(Token token) {
  final String? value = token.stringValue;
  return identical(value, '>') ||
      identical(value, '>>') ||
      identical(value, '>=') ||
      identical(value, '>>>') ||
      identical(value, '>>=') ||
      identical(value, '>>>=');
}

/// If [beforeCloser].next is one of `>`, `>>`, `>>>`, `>=`, `>>=`, or `>>>=`
/// then update the token stream and return `true`.
bool parseCloser(Token beforeCloser) {
  Token unsplit = beforeCloser.next!;
  Token? split = splitCloser(unsplit);
  if (split == unsplit) {
    return true;
  } else if (split == null) {
    return false;
  }
  split.next!.setNext(unsplit.next!);
  beforeCloser.setNext(split);
  return true;
}

/// If [closer] is `>` then return it.
/// If [closer] is one of `>>`, `>>>`, `>=`, `>>=`,  or `>>>=` then split
/// the token and return the leading `>` without updating the token stream.
/// If [closer] is none of the above, then return null;
Token? splitCloser(Token closer) {
  String? value = closer.stringValue;
  if (identical(value, '>')) {
    return closer;
  } else if (identical(value, '>>')) {
    return splitGtGt(closer);
  } else if (identical(value, '>=')) {
    return splitGtEq(closer);
  } else if (identical(value, '>>>')) {
    return splitGtFromGtGtGt(closer);
  } else if (identical(value, '>>=')) {
    return splitGtFromGtGtEq(closer);
  } else if (identical(value, '>>>=')) {
    return splitGtFromGtGtGtEq(closer);
  }
  return null;
}
