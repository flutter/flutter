// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../parser.dart';

class Tokenizer extends TokenizerBase {
  /// U+ prefix for unicode characters.
  final UNICODE_U = 'U'.codeUnitAt(0);
  final UNICODE_LOWER_U = 'u'.codeUnitAt(0);
  final UNICODE_PLUS = '+'.codeUnitAt(0);

  final QUESTION_MARK = '?'.codeUnitAt(0);

  /// CDATA keyword.
  final List<int> CDATA_NAME = 'CDATA'.codeUnits;

  Tokenizer(SourceFile file, String text, bool skipWhitespace, [int index = 0])
      : super(file, text, skipWhitespace, index);

  @override
  Token next({bool unicodeRange = false}) {
    // keep track of our starting position
    _startIndex = _index;

    int ch;
    ch = _nextChar();
    switch (ch) {
      case TokenChar.NEWLINE:
      case TokenChar.RETURN:
      case TokenChar.SPACE:
      case TokenChar.TAB:
        return finishWhitespace();
      case TokenChar.END_OF_FILE:
        return _finishToken(TokenKind.END_OF_FILE);
      case TokenChar.AT:
        var peekCh = _peekChar();
        if (TokenizerHelpers.isIdentifierStart(peekCh)) {
          var oldIndex = _index;
          var oldStartIndex = _startIndex;

          _startIndex = _index;
          ch = _nextChar();
          finishIdentifier();

          // Is it a directive?
          var tokId = TokenKind.matchDirectives(
              _text, _startIndex, _index - _startIndex);
          if (tokId == -1) {
            // No, is it a margin directive?
            tokId = TokenKind.matchMarginDirectives(
                _text, _startIndex, _index - _startIndex);
          }

          if (tokId != -1) {
            return _finishToken(tokId);
          } else {
            // Didn't find a CSS directive or margin directive so the @name is
            // probably the Less definition '@name: value_variable_definition'.
            _startIndex = oldStartIndex;
            _index = oldIndex;
          }
        }
        return _finishToken(TokenKind.AT);
      case TokenChar.DOT:
        var start = _startIndex; // Start where the dot started.
        if (maybeEatDigit()) {
          // looks like a number dot followed by digit(s).
          var number = finishNumber();
          if (number.kind == TokenKind.INTEGER) {
            // It's a number but it's preceeded by a dot, so make it a double.
            _startIndex = start;
            return _finishToken(TokenKind.DOUBLE);
          } else {
            // Don't allow dot followed by a double (e.g,  '..1').
            return _errorToken();
          }
        }
        // It's really a dot.
        return _finishToken(TokenKind.DOT);
      case TokenChar.LPAREN:
        return _finishToken(TokenKind.LPAREN);
      case TokenChar.RPAREN:
        return _finishToken(TokenKind.RPAREN);
      case TokenChar.LBRACE:
        return _finishToken(TokenKind.LBRACE);
      case TokenChar.RBRACE:
        return _finishToken(TokenKind.RBRACE);
      case TokenChar.LBRACK:
        return _finishToken(TokenKind.LBRACK);
      case TokenChar.RBRACK:
        if (_maybeEatChar(TokenChar.RBRACK) &&
            _maybeEatChar(TokenChar.GREATER)) {
          // ]]>
          return next();
        }
        return _finishToken(TokenKind.RBRACK);
      case TokenChar.HASH:
        return _finishToken(TokenKind.HASH);
      case TokenChar.PLUS:
        if (_nextCharsAreNumber(ch)) return finishNumber();
        return _finishToken(TokenKind.PLUS);
      case TokenChar.MINUS:
        if (inSelectorExpression || unicodeRange) {
          // If parsing in pseudo function expression then minus is an operator
          // not part of identifier e.g., interval value range (e.g. U+400-4ff)
          // or minus operator in selector expression.
          return _finishToken(TokenKind.MINUS);
        } else if (_nextCharsAreNumber(ch)) {
          return finishNumber();
        } else if (TokenizerHelpers.isIdentifierStart(ch)) {
          return finishIdentifier();
        }
        return _finishToken(TokenKind.MINUS);
      case TokenChar.GREATER:
        return _finishToken(TokenKind.GREATER);
      case TokenChar.TILDE:
        if (_maybeEatChar(TokenChar.EQUALS)) {
          return _finishToken(TokenKind.INCLUDES); // ~=
        }
        return _finishToken(TokenKind.TILDE);
      case TokenChar.ASTERISK:
        if (_maybeEatChar(TokenChar.EQUALS)) {
          return _finishToken(TokenKind.SUBSTRING_MATCH); // *=
        }
        return _finishToken(TokenKind.ASTERISK);
      case TokenChar.AMPERSAND:
        return _finishToken(TokenKind.AMPERSAND);
      case TokenChar.NAMESPACE:
        if (_maybeEatChar(TokenChar.EQUALS)) {
          return _finishToken(TokenKind.DASH_MATCH); // |=
        }
        return _finishToken(TokenKind.NAMESPACE);
      case TokenChar.COLON:
        return _finishToken(TokenKind.COLON);
      case TokenChar.COMMA:
        return _finishToken(TokenKind.COMMA);
      case TokenChar.SEMICOLON:
        return _finishToken(TokenKind.SEMICOLON);
      case TokenChar.PERCENT:
        return _finishToken(TokenKind.PERCENT);
      case TokenChar.SINGLE_QUOTE:
        return _finishToken(TokenKind.SINGLE_QUOTE);
      case TokenChar.DOUBLE_QUOTE:
        return _finishToken(TokenKind.DOUBLE_QUOTE);
      case TokenChar.SLASH:
        if (_maybeEatChar(TokenChar.ASTERISK)) return finishMultiLineComment();
        return _finishToken(TokenKind.SLASH);
      case TokenChar.LESS: // <!--
        if (_maybeEatChar(TokenChar.BANG)) {
          if (_maybeEatChar(TokenChar.MINUS) &&
              _maybeEatChar(TokenChar.MINUS)) {
            return finishHtmlComment();
          } else if (_maybeEatChar(TokenChar.LBRACK) &&
              _maybeEatChar(CDATA_NAME[0]) &&
              _maybeEatChar(CDATA_NAME[1]) &&
              _maybeEatChar(CDATA_NAME[2]) &&
              _maybeEatChar(CDATA_NAME[3]) &&
              _maybeEatChar(CDATA_NAME[4]) &&
              _maybeEatChar(TokenChar.LBRACK)) {
            // <![CDATA[
            return next();
          }
        }
        return _finishToken(TokenKind.LESS);
      case TokenChar.EQUALS:
        return _finishToken(TokenKind.EQUALS);
      case TokenChar.CARET:
        if (_maybeEatChar(TokenChar.EQUALS)) {
          return _finishToken(TokenKind.PREFIX_MATCH); // ^=
        }
        return _finishToken(TokenKind.CARET);
      case TokenChar.DOLLAR:
        if (_maybeEatChar(TokenChar.EQUALS)) {
          return _finishToken(TokenKind.SUFFIX_MATCH); // $=
        }
        return _finishToken(TokenKind.DOLLAR);
      case TokenChar.BANG:
        return finishIdentifier();
      default:
        // TODO(jmesserly): this is used for IE8 detection; I'm not sure it's
        // appropriate outside of a few specific places; certainly shouldn't
        // be parsed in selectors.
        if (!inSelector && ch == TokenChar.BACKSLASH) {
          return _finishToken(TokenKind.BACKSLASH);
        }

        if (unicodeRange) {
          // Three types of unicode ranges:
          //   - single code point (e.g. U+416)
          //   - interval value range (e.g. U+400-4ff)
          //   - range where trailing ‘?’ characters imply ‘any digit value’
          //   (e.g. U+4??)
          if (maybeEatHexDigit()) {
            var t = finishHexNumber();
            // Any question marks then it's a HEX_RANGE not HEX_NUMBER.
            if (maybeEatQuestionMark()) finishUnicodeRange();
            return t;
          } else if (maybeEatQuestionMark()) {
            // HEX_RANGE U+N???
            return finishUnicodeRange();
          } else {
            return _errorToken();
          }
        } else if (_inString &&
            (ch == UNICODE_U || ch == UNICODE_LOWER_U) &&
            (_peekChar() == UNICODE_PLUS)) {
          // `_inString` is misleading. We actually DON'T want to enter this
          // block while tokenizing a string, but the parser sets this value to
          // false while it IS consuming tokens within a string.
          //
          // Unicode range: U+uNumber[-U+uNumber]
          //   uNumber = 0..10FFFF
          _nextChar(); // Skip +
          _startIndex = _index; // Starts at the number
          return _finishToken(TokenKind.UNICODE_RANGE);
        } else if (varDef(ch)) {
          return _finishToken(TokenKind.VAR_DEFINITION);
        } else if (varUsage(ch)) {
          return _finishToken(TokenKind.VAR_USAGE);
        } else if (TokenizerHelpers.isIdentifierStart(ch)) {
          return finishIdentifier();
        } else if (TokenizerHelpers.isDigit(ch)) {
          return finishNumber();
        }
        return _errorToken();
    }
  }

  bool varDef(int ch) {
    return ch == 'v'.codeUnitAt(0) &&
        _maybeEatChar('a'.codeUnitAt(0)) &&
        _maybeEatChar('r'.codeUnitAt(0)) &&
        _maybeEatChar('-'.codeUnitAt(0));
  }

  bool varUsage(int ch) {
    return ch == 'v'.codeUnitAt(0) &&
        _maybeEatChar('a'.codeUnitAt(0)) &&
        _maybeEatChar('r'.codeUnitAt(0)) &&
        (_peekChar() == '-'.codeUnitAt(0));
  }

  @override
  Token _errorToken([String? message]) {
    return _finishToken(TokenKind.ERROR);
  }

  @override
  int getIdentifierKind() {
    // Is the identifier a unit type?
    var tokId = -1;

    // Don't match units in selectors or selector expressions.
    if (!inSelectorExpression && !inSelector) {
      tokId = TokenKind.matchUnits(_text, _startIndex, _index - _startIndex);
    }
    if (tokId == -1) {
      tokId = (_text.substring(_startIndex, _index) == '!important')
          ? TokenKind.IMPORTANT
          : -1;
    }

    return tokId >= 0 ? tokId : TokenKind.IDENTIFIER;
  }

  Token finishIdentifier() {
    // If we encounter an escape sequence, remember it so we can post-process
    // to unescape.
    var chars = <int>[];

    // backup so we can start with the first character
    var validateFrom = _index;
    _index = _startIndex;
    while (_index < _text.length) {
      var ch = _text.codeUnitAt(_index);

      // If the previous character was "\" we need to escape. T
      // http://www.w3.org/TR/CSS21/syndata.html#characters
      // if followed by hexadecimal digits, create the appropriate character.
      // otherwise, include the character in the identifier and don't treat it
      // specially.
      if (ch == 92 /*\*/ && _inString) {
        var startHex = ++_index;
        eatHexDigits(startHex + 6);
        if (_index != startHex) {
          // Parse the hex digits and add that character.
          chars.add(int.parse('0x' + _text.substring(startHex, _index)));

          if (_index == _text.length) break;

          // if we stopped the hex because of a whitespace char, skip it
          ch = _text.codeUnitAt(_index);
          if (_index - startHex != 6 &&
              (ch == TokenChar.SPACE ||
                  ch == TokenChar.TAB ||
                  ch == TokenChar.RETURN ||
                  ch == TokenChar.NEWLINE)) {
            _index++;
          }
        } else {
          // not a digit, just add the next character literally
          if (_index == _text.length) break;
          chars.add(_text.codeUnitAt(_index++));
        }
      } else if (_index < validateFrom ||
          (inSelectorExpression
              ? TokenizerHelpers.isIdentifierPartExpr(ch)
              : TokenizerHelpers.isIdentifierPart(ch))) {
        chars.add(ch);
        _index++;
      } else {
        // Not an identifier or escaped character.
        break;
      }
    }

    var span = _file.span(_startIndex, _index);
    var text = String.fromCharCodes(chars);

    return IdentifierToken(text, getIdentifierKind(), span);
  }

  @override
  Token finishNumber() {
    eatDigits();

    if (_peekChar() == 46 /*.*/) {
      // Handle the case of 1.toString().
      _nextChar();
      if (TokenizerHelpers.isDigit(_peekChar())) {
        eatDigits();
        return _finishToken(TokenKind.DOUBLE);
      } else {
        _index -= 1;
      }
    }

    return _finishToken(TokenKind.INTEGER);
  }

  bool maybeEatDigit() {
    if (_index < _text.length &&
        TokenizerHelpers.isDigit(_text.codeUnitAt(_index))) {
      _index += 1;
      return true;
    }
    return false;
  }

  Token finishHexNumber() {
    eatHexDigits(_text.length);
    return _finishToken(TokenKind.HEX_INTEGER);
  }

  void eatHexDigits(int end) {
    end = math.min(end, _text.length);
    while (_index < end) {
      if (TokenizerHelpers.isHexDigit(_text.codeUnitAt(_index))) {
        _index += 1;
      } else {
        return;
      }
    }
  }

  bool maybeEatHexDigit() {
    if (_index < _text.length &&
        TokenizerHelpers.isHexDigit(_text.codeUnitAt(_index))) {
      _index += 1;
      return true;
    }
    return false;
  }

  bool maybeEatQuestionMark() {
    if (_index < _text.length && _text.codeUnitAt(_index) == QUESTION_MARK) {
      _index += 1;
      return true;
    }
    return false;
  }

  void eatQuestionMarks() {
    while (_index < _text.length) {
      if (_text.codeUnitAt(_index) == QUESTION_MARK) {
        _index += 1;
      } else {
        return;
      }
    }
  }

  Token finishUnicodeRange() {
    eatQuestionMarks();
    return _finishToken(TokenKind.HEX_RANGE);
  }

  Token finishHtmlComment() {
    while (true) {
      var ch = _nextChar();
      if (ch == 0) {
        return _finishToken(TokenKind.INCOMPLETE_COMMENT);
      } else if (ch == TokenChar.MINUS) {
        /* Check if close part of Comment Definition --> (CDC). */
        if (_maybeEatChar(TokenChar.MINUS)) {
          if (_maybeEatChar(TokenChar.GREATER)) {
            if (_inString) {
              return next();
            } else {
              return _finishToken(TokenKind.HTML_COMMENT);
            }
          }
        }
      }
    }
  }

  @override
  Token finishMultiLineComment() {
    while (true) {
      var ch = _nextChar();
      if (ch == 0) {
        return _finishToken(TokenKind.INCOMPLETE_COMMENT);
      } else if (ch == 42 /*'*'*/) {
        if (_maybeEatChar(47 /*'/'*/)) {
          if (_inString) {
            return next();
          } else {
            return _finishToken(TokenKind.COMMENT);
          }
        }
      }
    }
  }
}

/// Static helper methods.
class TokenizerHelpers {
  static bool isIdentifierStart(int c) {
    return isIdentifierStartExpr(c) || c == 45 /*-*/;
  }

  static bool isDigit(int c) {
    return (c >= 48 /*0*/ && c <= 57 /*9*/);
  }

  static bool isHexDigit(int c) {
    return (isDigit(c) ||
        (c >= 97 /*a*/ && c <= 102 /*f*/) ||
        (c >= 65 /*A*/ && c <= 70 /*F*/));
  }

  static bool isIdentifierPart(int c) {
    return isIdentifierPartExpr(c) || c == 45 /*-*/;
  }

  /// Pseudo function expressions identifiers can't have a minus sign.
  static bool isIdentifierStartExpr(int c) {
    return ((c >= 97 /*a*/ && c <= 122 /*z*/) ||
        (c >= 65 /*A*/ && c <= 90 /*Z*/) ||
        // Note: Unicode 10646 chars U+00A0 or higher are allowed, see:
        // http://www.w3.org/TR/CSS21/syndata.html#value-def-identifier
        // http://www.w3.org/TR/CSS21/syndata.html#characters
        // Also, escaped character should be allowed.
        c == 95 /*_*/ ||
        c >= 0xA0 ||
        c == 92 /*\*/);
  }

  /// Pseudo function expressions identifiers can't have a minus sign.
  static bool isIdentifierPartExpr(int c) {
    return (isIdentifierStartExpr(c) || isDigit(c));
  }
}
