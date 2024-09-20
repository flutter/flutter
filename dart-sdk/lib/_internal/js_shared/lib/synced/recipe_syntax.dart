// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: library_names

/// Constants and predicates used for encoding and decoding type recipes.
///
/// This library is synchronized between the compiler and the runtime system.
library js_shared._recipe_syntax;

abstract class Recipe {
  Recipe._();

  // Operators.

  static const int librarySeparator = _vertical;
  static const String librarySeparatorString = _verticalString;

  static const int separator = _comma;
  static const String separatorString = _commaString;

  static const int toType = _semicolon;
  static const String toTypeString = _semicolonString;

  static const int pushErased = _hash;
  static const String pushErasedString = _hashString;
  static const int pushDynamic = _at;
  static const String pushDynamicString = _atString;
  static const int pushVoid = _tilde;
  static const String pushVoidString = _tildeString;

  static const int wrapStar = _asterisk;
  static const String wrapStarString = _asteriskString;
  static const int wrapQuestion = _question;
  static const String wrapQuestionString = _questionString;
  static const int wrapFutureOr = _slash;
  static const String wrapFutureOrString = _slashString;

  static const int startTypeArguments = _lessThan;
  static const String startTypeArgumentsString = _lessThanString;
  static const int endTypeArguments = _greaterThan;
  static const String endTypeArgumentsString = _greaterThanString;

  static const int startFunctionArguments = _leftParen;
  static const String startFunctionArgumentsString = _leftParenString;
  static const int endFunctionArguments = _rightParen;
  static const String endFunctionArgumentsString = _rightParenString;
  static const int startOptionalGroup = _leftBracket;
  static const String startOptionalGroupString = _leftBracketString;
  static const int endOptionalGroup = _rightBracket;
  static const String endOptionalGroupString = _rightBracketString;
  static const int startNamedGroup = _leftBrace;
  static const String startNamedGroupString = _leftBraceString;
  static const int endNamedGroup = _rightBrace;
  static const String endNamedGroupString = _rightBraceString;
  static const int nameSeparator = _colon;
  static const String nameSeparatorString = _colonString;
  static const int requiredNameSeparator = _exclamation;
  static const String requiredNameSeparatorString = _exclamationString;

  static const int genericFunctionTypeParameterIndex = _circumflex;
  static const String genericFunctionTypeParameterIndexString =
      _circumflexString;

  static const int startRecord = _plus;
  static const String startRecordString = _plusString;

  static const int extensionOp = _ampersand;
  static const String extensionOpString = _ampersandString;
  static const int pushNeverExtension = 0;
  static const String pushNeverExtensionString = '$pushNeverExtension';
  static const int pushAnyExtension = 1;
  static const String pushAnyExtensionString = '$pushAnyExtension';

  // Number and name components.

  static bool isDigit(int code) => code >= _digit0 && code <= _digit9;
  static int digitValue(int code) => code - _digit0;

  static bool isIdentifierStart(int ch) =>
      (((ch | 32) - _lowercaseA) & 0xffff) < 26 ||
      (ch == _underscore) ||
      (ch == _dollar) ||
      (ch == _vertical);

  static const int period = _period;

  // Private names.

  static const int _formfeed = 0x0C;
  static const String _formfeedString = '\f';

  static const int _space = 0x20;
  static const String _spaceString = ' ';
  static const int _exclamation = 0x21;
  static const String _exclamationString = '!';
  static const int _hash = 0x23;
  static const String _hashString = '#';
  static const int _dollar = 0x24;
  static const String _dollarString = r'$';
  static const int _percent = 0x25;
  static const String _percentString = '%';
  static const int _ampersand = 0x26;
  static const String _ampersandString = '&';
  static const int _apostrophe = 0x27;
  static const String _apostropheString = "'";
  static const int _leftParen = 0x28;
  static const String _leftParenString = '(';
  static const int _rightParen = 0x29;
  static const String _rightParenString = ')';
  static const int _asterisk = 0x2A;
  static const String _asteriskString = '*';
  static const int _plus = 0x2B;
  static const String _plusString = '+';
  static const int _comma = 0x2C;
  static const String _commaString = ',';
  static const int _minus = 0x2D;
  static const String _minusString = '-';
  static const int _period = 0x2E;
  static const String _periodString = '.';
  static const int _slash = 0x2F;
  static const String _slashString = '/';

  static const int _digit0 = 0x30;
  static const int _digit9 = 0x39;

  static const int _colon = 0x3A;
  static const String _colonString = ':';
  static const int _semicolon = 0x3B;
  static const String _semicolonString = ';';
  static const int _lessThan = 0x3C;
  static const String _lessThanString = '<';
  static const int _equals = 0x3D;
  static const String _equalsString = '=';
  static const int _greaterThan = 0x3E;
  static const String _greaterThanString = '>';
  static const int _question = 0x3F;
  static const String _questionString = '?';
  static const int _at = 0x40;
  static const String _atString = '@';

  // ignore: unused_field
  static const int _uppercaseA = 0x41;
  // ignore: unused_field
  static const int _uppercaseZ = 0x5A;

  static const int _leftBracket = 0x5B;
  static const String _leftBracketString = '[';
  static const int _backslash = 0x5C;
  static const String _backslashString = r'\';
  static const int _rightBracket = 0x5D;
  static const String _rightBracketString = ']';
  static const int _circumflex = 0x5E;
  static const String _circumflexString = '^';
  static const int _underscore = 0x5F;
  static const String _underscoreString = '_';
  static const int _backtick = 0x60;
  static const String _backtickString = '`';

  static const int _lowercaseA = 0x61;
  // ignore: unused_field
  static const int _lowercaseZ = 0x7A;

  static const int _leftBrace = 0x7B;
  static const String _leftBraceString = '{';
  static const int _vertical = 0x7C;
  static const String _verticalString = '|';
  static const int _rightBrace = 0x7D;
  static const String _rightBraceString = '}';
  static const int _tilde = 0x7E;
  static const String _tildeString = '~';

  static void testEquivalence() {
    void test(String label, int charCode, String str) {
      if (String.fromCharCode(charCode) != str) {
        throw StateError("$label: String.fromCharCode($charCode) != $str");
      }
    }

    void testExtension(String label, int op, String str) {
      if ('$op' != str) {
        throw StateError("$label: $op.toString() != $str");
      }
    }

    test("separator", separator, separatorString);
    test("toType", toType, toTypeString);
    test("pushErased", pushErased, pushErasedString);
    test("pushDynamic", pushDynamic, pushDynamicString);
    test("pushVoid", pushVoid, pushVoidString);
    test("wrapStar", wrapStar, wrapStarString);
    test("wrapQuestion", wrapQuestion, wrapQuestionString);
    test("wrapFutureOr", wrapFutureOr, wrapFutureOrString);
    test("startTypeArguments", startTypeArguments, startTypeArgumentsString);
    test("endTypeArguments", endTypeArguments, endTypeArgumentsString);
    test("startFunctionArguments", startFunctionArguments,
        startFunctionArgumentsString);
    test("endFunctionArguments", endFunctionArguments,
        endFunctionArgumentsString);
    test("startOptionalGroup", startOptionalGroup, startOptionalGroupString);
    test("endOptionalGroup", endOptionalGroup, endOptionalGroupString);
    test("startNamedGroup", startNamedGroup, startNamedGroupString);
    test("endNamedGroup", endNamedGroup, endNamedGroupString);
    test("nameSeparator", nameSeparator, nameSeparatorString);
    test("requiredNameSeparator", requiredNameSeparator,
        requiredNameSeparatorString);
    test("genericFunctionTypeParameterIndex", genericFunctionTypeParameterIndex,
        genericFunctionTypeParameterIndexString);
    test("startRecord", startRecord, startRecordString);
    test("extensionOp", extensionOp, extensionOpString);
    testExtension(
        "pushNeverExtension", pushNeverExtension, pushNeverExtensionString);
    testExtension("pushAnyExtension", pushAnyExtension, pushAnyExtensionString);

    test("_formfeed", _formfeed, _formfeedString);
    test("_space", _space, _spaceString);
    test("_exclamation", _exclamation, _exclamationString);
    test("_hash", _hash, _hashString);
    test("_dollar", _dollar, _dollarString);
    test("_percent", _percent, _percentString);
    test("_ampersand", _ampersand, _ampersandString);
    test("_apostrophe", _apostrophe, _apostropheString);
    test("_leftParen", _leftParen, _leftParenString);
    test("_rightParen", _rightParen, _rightParenString);
    test("_asterisk", _asterisk, _asteriskString);
    test("_plus", _plus, _plusString);
    test("_comma", _comma, _commaString);
    test("_minus", _minus, _minusString);
    test("_period", _period, _periodString);
    test("_slash", _slash, _slashString);
    test("_colon", _colon, _colonString);
    test("_semicolon", _semicolon, _semicolonString);
    test("_lessThan", _lessThan, _lessThanString);
    test("_equals", _equals, _equalsString);
    test("_greaterThan", _greaterThan, _greaterThanString);
    test("_question", _question, _questionString);
    test("_at", _at, _atString);
    test("_leftBracket", _leftBracket, _leftBracketString);
    test("_backslash", _backslash, _backslashString);
    test("_rightBracket", _rightBracket, _rightBracketString);
    test("_circumflex", _circumflex, _circumflexString);
    test("_underscore", _underscore, _underscoreString);
    test("_backtick", _backtick, _backtickString);
    test("_leftBrace", _leftBrace, _leftBraceString);
    test("_vertical", _vertical, _verticalString);
    test("_rightBrace", _rightBrace, _rightBraceString);
    test("_tilde", _tilde, _tildeString);
  }
}
