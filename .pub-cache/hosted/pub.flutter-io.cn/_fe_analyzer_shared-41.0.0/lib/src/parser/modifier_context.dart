// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages/codes.dart' as codes;
import '../scanner/token.dart' show Keyword, Token;
import 'formal_parameter_kind.dart';
import 'member_kind.dart' show MemberKind;
import 'parser_impl.dart' show Parser;
import 'util.dart' show optional;

bool isModifier(Token token) {
  if (!token.isModifier) {
    return false;
  } else if (token.type.isBuiltIn) {
    // A built-in keyword can only be a modifier as long as it is
    // followed by another keyword or an identifier. Otherwise, it is the
    // identifier.
    //
    // For example, `external` is a modifier in this declaration:
    //   external Foo foo();
    // but is the identifier in this declaration
    //   external() => true;
    // and in
    //   for (final external in list) { }
    Token next = token.next!;
    Keyword? keyword = next.keyword;
    if (keyword == null && !next.isIdentifier || keyword == Keyword.IN) {
      return false;
    }
  }
  return true;
}

/// This class is used to parse modifiers in most locations where modifiers
/// can occur, but does not call handleModifier or handleModifiers.
class ModifierContext {
  final Parser parser;
  Token? abstractToken;
  Token? augmentToken;
  Token? constToken;
  Token? covariantToken;
  Token? externalToken;
  Token? finalToken;
  Token? lateToken;
  Token? requiredToken;
  Token? staticToken;
  Token? varToken;

  // Set `true` when parsing modifiers after the `factory` token.
  bool _afterFactory = false;

  ModifierContext(this.parser);

  set staticOrCovariant(Token? staticOrCovariant) {
    if (staticOrCovariant == null) {
      covariantToken = null;
      staticToken = null;
    } else if (optional('covariant', staticOrCovariant)) {
      covariantToken = staticOrCovariant;
      staticToken = null;
    } else if (optional('static', staticOrCovariant)) {
      covariantToken = null;
      staticToken = staticOrCovariant;
    } else {
      throw "Internal error: "
          "Unexpected staticOrCovariant '$staticOrCovariant'.";
    }
  }

  Token? get varFinalOrConst => varToken ?? finalToken ?? constToken;

  set varFinalOrConst(Token? varFinalOrConst) {
    if (varFinalOrConst == null) {
      varToken = null;
      finalToken = null;
      constToken = null;
    } else if (optional('var', varFinalOrConst)) {
      varToken = varFinalOrConst;
      finalToken = null;
      constToken = null;
    } else if (optional('final', varFinalOrConst)) {
      varToken = null;
      finalToken = varFinalOrConst;
      constToken = null;
    } else if (optional('const', varFinalOrConst)) {
      varToken = null;
      finalToken = null;
      constToken = varFinalOrConst;
    } else {
      throw "Internal error: Unexpected varFinalOrConst '$varFinalOrConst'.";
    }
  }

  /// Parse modifiers for class declarations.
  Token parseClassModifiers(Token token, Token keyword) {
    token = _parseModifiers(token);
    if (constToken != null) {
      reportTopLevelModifierError(constToken!, keyword);
    }
    if (externalToken != null) {
      reportTopLevelModifierError(externalToken!, keyword);
    }
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(finalToken);
    reportExtraneousModifier(lateToken);
    reportExtraneousModifier(requiredToken);
    reportExtraneousModifier(staticToken);
    reportExtraneousModifier(varToken);
    return token;
  }

  /// Parse modifiers for enum declarations.
  Token parseEnumModifiers(Token token, Token keyword) {
    token = _parseModifiers(token);
    reportTopLevelModifierError(constToken, keyword);
    reportTopLevelModifierError(externalToken, keyword);
    reportExtraneousModifier(abstractToken);
    // TODO(johnniwinther): Should we support 'augment' on enums.
    reportExtraneousModifier(augmentToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(finalToken);
    reportExtraneousModifier(lateToken);
    reportExtraneousModifier(requiredToken);
    reportExtraneousModifier(staticToken);
    reportExtraneousModifier(varToken);
    return token;
  }

  /// Parse modifiers for mixin declarations.
  Token parseMixinModifiers(Token token, Token keyword) {
    token = _parseModifiers(token);
    reportTopLevelModifierError(constToken, keyword);
    reportTopLevelModifierError(externalToken, keyword);
    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(finalToken);
    reportExtraneousModifier(lateToken);
    reportExtraneousModifier(requiredToken);
    reportExtraneousModifier(staticToken);
    reportExtraneousModifier(varToken);
    return token;
  }

  /// Parse modifiers for library, import, export, part (of) directives and
  /// typedef and extension declarations.
  Token parseTopLevelKeywordModifiers(Token token, Token keyword) {
    token = _parseModifiers(token);
    reportTopLevelModifierError(constToken, keyword);
    reportTopLevelModifierError(externalToken, keyword);
    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(augmentToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(finalToken);
    reportExtraneousModifier(lateToken);
    reportExtraneousModifier(requiredToken);
    reportExtraneousModifier(staticToken);
    reportExtraneousModifier(varToken);
    return token;
  }

  /// Parse modifiers for class methods and fields.
  Token parseClassMemberModifiers(Token token) {
    token = _parseModifiers(token);
    reportExtraneousModifier(requiredToken);
    return token;
  }

  /// Parse modifiers for formal parameters.
  Token parseFormalParameterModifiers(
      Token token, FormalParameterKind parameterKind, MemberKind memberKind) {
    token = _parseModifiers(token);

    if (parameterKind != FormalParameterKind.optionalNamed) {
      reportExtraneousModifier(requiredToken);
    }
    if (memberKind == MemberKind.StaticMethod ||
        memberKind == MemberKind.TopLevelMethod) {
      reportExtraneousModifier(this.covariantToken);
    } else if (memberKind == MemberKind.ExtensionNonStaticMethod ||
        memberKind == MemberKind.ExtensionStaticMethod) {
      reportExtraneousModifierInExtension(this.covariantToken);
    }
    if (constToken != null) {
      reportExtraneousModifier(constToken);
    } else if (memberKind == MemberKind.GeneralizedFunctionType) {
      if (varFinalOrConst != null) {
        parser.reportRecoverableError(
            varFinalOrConst!, codes.messageFunctionTypedParameterVar);
      }
    }
    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(externalToken);
    reportExtraneousModifier(lateToken);
    reportExtraneousModifier(staticToken);
    return token;
  }

  /// Parse modifiers after the `factory` token.
  Token parseModifiersAfterFactory(Token token) {
    _afterFactory = true;
    token = _parseModifiers(token);
    if (abstractToken != null) {
      parser.reportRecoverableError(
          abstractToken!, codes.messageAbstractClassMember);
    }
    reportExtraneousModifier(lateToken);
    reportExtraneousModifier(requiredToken);
    return token;
  }

  /// Parse modifiers for top level functions and fields.
  Token parseTopLevelMemberModifiers(Token token) {
    token = _parseModifiers(token);
    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(requiredToken);
    reportExtraneousModifier(staticToken);
    return token;
  }

  /// Parse modifiers for variable declarations.
  Token parseVariableDeclarationModifiers(Token token) {
    token = _parseModifiers(token);
    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(externalToken);
    reportExtraneousModifier(requiredToken);
    reportExtraneousModifier(staticToken);
    reportExtraneousModifier(augmentToken);
    return token;
  }

  /// Parse modifiers during recovery when modifiers are out of order
  /// or invalid. Typically clients call methods like
  /// [parseClassMemberModifiers] which in turn calls this method,
  /// rather than calling this method directly.
  ///
  /// The various modifier token parameters represent tokens of modifiers
  /// that have already been parsed prior to recovery. The [staticOrCovariant]
  /// parameter is for convenience if caller has a token that may be either
  /// `static` or `covariant`. The first non-null parameter of
  /// [staticOrCovariant], [staticToken], or [covariantToken] will be used,
  /// in that order, and the others ignored.
  Token _parseModifiers(Token token) {
    // Process invalid and out-of-order modifiers
    Token next = token.next!;
    while (true) {
      final String? value = next.stringValue;
      if (isModifier(next)) {
        if (identical('abstract', value)) {
          token = _parseAbstract(token);
        } else if (identical('augment', value)) {
          token = _parseAugment(token);
        } else if (identical('const', value)) {
          token = _parseConst(token);
        } else if (identical('covariant', value)) {
          token = _parseCovariant(token);
        } else if (identical('external', value)) {
          token = _parseExternal(token);
        } else if (identical('final', value)) {
          token = _parseFinal(token);
        } else if (identical('late', value)) {
          token = _parseLate(token);
        } else if (identical('required', value)) {
          token = _parseRequired(token);
        } else if (identical('static', value)) {
          token = _parseStatic(token);
        } else if (identical('var', value)) {
          token = _parseVar(token);
        } else {
          throw 'Internal Error: Unhandled modifier: $value';
        }
      } else if (_afterFactory && identical('factory', value)) {
        parser.reportRecoverableErrorWithToken(
            next, codes.templateDuplicatedModifier);
        token = next;
      } else {
        break;
      }
      next = token.next!;
    }
    return token;
  }

  Token _parseAbstract(Token token) {
    Token next = token.next!;
    assert(optional('abstract', next));
    if (abstractToken == null) {
      abstractToken = next;

      if (varFinalOrConst != null) {
        reportModifierOutOfOrder(next, varFinalOrConst!.lexeme);
      } else if (covariantToken != null) {
        reportModifierOutOfOrder(next, covariantToken!.lexeme);
      }
      return next;
    }

    // Recovery
    parser.reportRecoverableErrorWithToken(
        next, codes.templateDuplicatedModifier);
    return next;
  }

  Token _parseAugment(Token token) {
    Token next = token.next!;
    assert(optional('augment', next));
    if (augmentToken == null) {
      augmentToken = next;

      if (varFinalOrConst != null) {
        reportModifierOutOfOrder(next, varFinalOrConst!.lexeme);
      } else if (abstractToken != null) {
        reportModifierOutOfOrder(next, abstractToken!.lexeme);
      } else if (constToken != null) {
        reportModifierOutOfOrder(next, constToken!.lexeme);
      } else if (covariantToken != null) {
        reportModifierOutOfOrder(next, covariantToken!.lexeme);
      } else if (finalToken != null) {
        reportModifierOutOfOrder(next, finalToken!.lexeme);
      } else if (lateToken != null) {
        reportModifierOutOfOrder(next, lateToken!.lexeme);
      } else if (staticToken != null) {
        reportModifierOutOfOrder(next, staticToken!.lexeme);
      } else if (externalToken != null) {
        reportConflictingModifiers(next, externalToken!);
      }
      return next;
    }

    // Recovery
    parser.reportRecoverableErrorWithToken(
        next, codes.templateDuplicatedModifier);
    return next;
  }

  Token _parseConst(Token token) {
    Token next = token.next!;
    assert(optional('const', next));
    if (varFinalOrConst == null && covariantToken == null) {
      constToken = next;

      if (_afterFactory) {
        reportModifierOutOfOrder(next, 'factory');
      } else if (lateToken != null) {
        reportConflictingModifiers(next, lateToken!);
      }
      return next;
    }

    // Recovery
    if (constToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, codes.templateDuplicatedModifier);
    } else if (covariantToken != null) {
      reportConflictingModifiers(next, covariantToken!);
    } else if (finalToken != null) {
      parser.reportRecoverableError(next, codes.messageConstAndFinal);
    } else if (varToken != null) {
      reportConflictingModifiers(next, varToken!);
    } else {
      throw 'Internal Error: Unexpected varFinalOrConst: $varFinalOrConst';
    }
    return next;
  }

  Token _parseCovariant(Token token) {
    Token next = token.next!;
    assert(optional('covariant', next));
    if (constToken == null &&
        covariantToken == null &&
        staticToken == null &&
        !_afterFactory) {
      covariantToken = next;

      if (varToken != null) {
        reportModifierOutOfOrder(next, varToken!.lexeme);
      } else if (finalToken != null) {
        reportModifierOutOfOrder(next, finalToken!.lexeme);
      } else if (lateToken != null) {
        reportModifierOutOfOrder(next, lateToken!.lexeme);
      }
      return next;
    }

    // Recovery
    if (covariantToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, codes.templateDuplicatedModifier);
    } else if (_afterFactory) {
      reportExtraneousModifier(next);
    } else if (constToken != null) {
      reportConflictingModifiers(next, constToken!);
    } else if (staticToken != null) {
      parser.reportRecoverableError(next, codes.messageCovariantAndStatic);
    } else {
      throw 'Internal Error: Unhandled recovery: $next';
    }
    return next;
  }

  Token _parseExternal(Token token) {
    Token next = token.next!;
    assert(optional('external', next));
    if (externalToken == null) {
      externalToken = next;

      if (_afterFactory) {
        reportModifierOutOfOrder(next, 'factory');
      } else if (constToken != null) {
        reportModifierOutOfOrder(next, constToken!.lexeme);
      } else if (staticToken != null) {
        reportModifierOutOfOrder(next, staticToken!.lexeme);
      } else if (lateToken != null) {
        reportModifierOutOfOrder(next, lateToken!.lexeme);
      } else if (varFinalOrConst != null) {
        reportModifierOutOfOrder(next, varFinalOrConst!.lexeme);
      } else if (covariantToken != null) {
        reportModifierOutOfOrder(next, covariantToken!.lexeme);
      } else if (augmentToken != null) {
        reportConflictingModifiers(next, augmentToken!);
      }
      return next;
    }

    // Recovery
    parser.reportRecoverableErrorWithToken(
        next, codes.templateDuplicatedModifier);
    return next;
  }

  Token _parseFinal(Token token) {
    Token next = token.next!;
    assert(optional('final', next));
    if (varFinalOrConst == null && !_afterFactory) {
      finalToken = next;
      return next;
    }

    // Recovery
    if (finalToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, codes.templateDuplicatedModifier);
    } else if (_afterFactory) {
      reportExtraneousModifier(next);
    } else if (constToken != null) {
      parser.reportRecoverableError(next, codes.messageConstAndFinal);
    } else if (varToken != null) {
      parser.reportRecoverableError(next, codes.messageFinalAndVar);
    } else if (lateToken != null) {
      reportModifierOutOfOrder(next, lateToken!.lexeme);
    } else {
      throw 'Internal Error: Unexpected varFinalOrConst: $varFinalOrConst';
    }
    return next;
  }

  Token _parseLate(Token token) {
    Token next = token.next!;
    assert(optional('late', next));
    if (lateToken == null) {
      lateToken = next;

      if (constToken != null) {
        reportConflictingModifiers(next, constToken!);
      } else if (varToken != null) {
        reportModifierOutOfOrder(next, varToken!.lexeme);
      } else if (finalToken != null) {
        reportModifierOutOfOrder(next, finalToken!.lexeme);
      }
      return next;
    }

    // Recovery
    parser.reportRecoverableErrorWithToken(
        next, codes.templateDuplicatedModifier);
    return next;
  }

  Token _parseRequired(Token token) {
    Token next = token.next!;
    assert(optional('required', next));
    if (requiredToken == null) {
      requiredToken = next;

      if (constToken != null) {
        reportModifierOutOfOrder(requiredToken!, constToken!.lexeme);
      } else if (covariantToken != null) {
        reportModifierOutOfOrder(requiredToken!, covariantToken!.lexeme);
      } else if (finalToken != null) {
        reportModifierOutOfOrder(requiredToken!, finalToken!.lexeme);
      } else if (varToken != null) {
        reportModifierOutOfOrder(requiredToken!, varToken!.lexeme);
      }
      return next;
    }

    // Recovery
    parser.reportRecoverableErrorWithToken(
        next, codes.templateDuplicatedModifier);
    return next;
  }

  Token _parseStatic(Token token) {
    Token next = token.next!;
    assert(optional('static', next));
    if (covariantToken == null && staticToken == null && !_afterFactory) {
      staticToken = next;

      if (constToken != null) {
        reportModifierOutOfOrder(next, constToken!.lexeme);
      } else if (finalToken != null) {
        reportModifierOutOfOrder(next, finalToken!.lexeme);
      } else if (varToken != null) {
        reportModifierOutOfOrder(next, varToken!.lexeme);
      } else if (lateToken != null) {
        reportModifierOutOfOrder(next, lateToken!.lexeme);
      }
      return next;
    }

    // Recovery
    if (covariantToken != null) {
      parser.reportRecoverableError(next, codes.messageCovariantAndStatic);
    } else if (staticToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, codes.templateDuplicatedModifier);
    } else if (_afterFactory) {
      reportExtraneousModifier(next);
    } else {
      throw 'Internal Error: Unhandled recovery: $next';
    }
    return next;
  }

  Token _parseVar(Token token) {
    Token next = token.next!;
    assert(optional('var', next));
    if (varFinalOrConst == null && !_afterFactory) {
      varToken = next;
      return next;
    }

    // Recovery
    if (varToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, codes.templateDuplicatedModifier);
    } else if (_afterFactory) {
      reportExtraneousModifier(next);
    } else if (constToken != null) {
      reportConflictingModifiers(next, constToken!);
    } else if (finalToken != null) {
      parser.reportRecoverableError(next, codes.messageFinalAndVar);
    } else {
      throw 'Internal Error: Unexpected varFinalOrConst: $varFinalOrConst';
    }
    return next;
  }

  void reportConflictingModifiers(Token modifier, Token earlierModifier) {
    parser.reportRecoverableError(
        modifier,
        codes.templateConflictingModifiers
            .withArguments(modifier.lexeme, earlierModifier.lexeme));
  }

  void reportExtraneousModifier(Token? modifier) {
    if (modifier != null) {
      parser.reportRecoverableErrorWithToken(
          modifier, codes.templateExtraneousModifier);
    }
  }

  // Report an error for the given modifier preceding a top level keyword
  // such as `import` or `class`.
  void reportTopLevelModifierError(Token? modifier, Token afterModifiers) {
    if (modifier != null) {
      if (optional('const', modifier) && optional('class', afterModifiers)) {
        parser.reportRecoverableError(modifier, codes.messageConstClass);
      } else if (optional('external', modifier)) {
        if (optional('class', afterModifiers)) {
          parser.reportRecoverableError(modifier, codes.messageExternalClass);
        } else if (optional('enum', afterModifiers)) {
          parser.reportRecoverableError(modifier, codes.messageExternalEnum);
        } else if (optional('typedef', afterModifiers)) {
          parser.reportRecoverableError(modifier, codes.messageExternalTypedef);
        } else {
          parser.reportRecoverableErrorWithToken(
              modifier, codes.templateExtraneousModifier);
        }
      } else {
        parser.reportRecoverableErrorWithToken(
            modifier, codes.templateExtraneousModifier);
      }
    }
  }

  void reportExtraneousModifierInExtension(Token? modifier) {
    if (modifier != null) {
      parser.reportRecoverableErrorWithToken(
          modifier, codes.templateExtraneousModifierInExtension);
    }
  }

  void reportModifierOutOfOrder(Token modifier, String beforeModifier) {
    parser.reportRecoverableError(
        modifier,
        codes.templateModifierOutOfOrder
            .withArguments(modifier.lexeme, beforeModifier));
  }
}
