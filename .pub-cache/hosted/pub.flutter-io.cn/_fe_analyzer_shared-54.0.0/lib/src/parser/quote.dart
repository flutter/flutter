// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.quote;

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';

import 'package:_fe_analyzer_shared/src/parser/listener.dart'
    show UnescapeErrorListener;

import 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show
        $BACKSLASH,
        $BS,
        $CLOSE_CURLY_BRACKET,
        $CR,
        $FF,
        $LF,
        $OPEN_CURLY_BRACKET,
        $SPACE,
        $TAB,
        $VTAB,
        $b,
        $f,
        $n,
        $r,
        $t,
        $u,
        $v,
        $x,
        hexDigitValue,
        isHexDigit;

import 'package:_fe_analyzer_shared/src/messages/codes.dart' as codes;

enum Quote {
  Single,
  Double,
  MultiLineSingle,
  MultiLineDouble,
  RawSingle,
  RawDouble,
  RawMultiLineSingle,
  RawMultiLineDouble,
}

Quote analyzeQuote(String first) {
  if (first.startsWith('"""')) return Quote.MultiLineDouble;
  if (first.startsWith('r"""')) return Quote.RawMultiLineDouble;
  if (first.startsWith("'''")) return Quote.MultiLineSingle;
  if (first.startsWith("r'''")) return Quote.RawMultiLineSingle;
  if (first.startsWith('"')) return Quote.Double;
  if (first.startsWith('r"')) return Quote.RawDouble;
  if (first.startsWith("'")) return Quote.Single;
  if (first.startsWith("r'")) return Quote.RawSingle;
  return throw new UnsupportedError("'$first' in analyzeQuote");
}

// Note: based on [StringValidator.quotingFromString]
// (pkg/compiler/lib/src/string_validator.dart).
int lengthOfOptionalWhitespacePrefix(String first, int start) {
  List<int> codeUnits = first.codeUnits;
  for (int i = start; i < codeUnits.length; i++) {
    int code = codeUnits[i];
    if (code == $BACKSLASH) {
      i++;
      if (i < codeUnits.length) {
        code = codeUnits[i];
      } else {
        break;
      }
    }
    if (code == $TAB || code == $SPACE) continue;
    if (code == $CR) {
      if (i + 1 < codeUnits.length && codeUnits[i + 1] == $LF) {
        i++;
      }
      return i + 1;
    }
    if (code == $LF) {
      return i + 1;
    }
    break; // Not a white-space character.
  }
  return start;
}

int firstQuoteLength(String first, Quote quote) {
  switch (quote) {
    case Quote.Single:
    case Quote.Double:
      return 1;

    case Quote.MultiLineSingle:
    case Quote.MultiLineDouble:
      return lengthOfOptionalWhitespacePrefix(first, /* start = */ 3);

    case Quote.RawSingle:
    case Quote.RawDouble:
      return 2;

    case Quote.RawMultiLineSingle:
    case Quote.RawMultiLineDouble:
      return lengthOfOptionalWhitespacePrefix(first, /* start = */ 4);
  }
}

int lastQuoteLength(Quote quote) {
  switch (quote) {
    case Quote.Single:
    case Quote.Double:
    case Quote.RawSingle:
    case Quote.RawDouble:
      return 1;

    case Quote.MultiLineSingle:
    case Quote.MultiLineDouble:
    case Quote.RawMultiLineSingle:
    case Quote.RawMultiLineDouble:
      return 3;
  }
}

String unescapeFirstStringPart(String first, Quote quote, Object location,
    UnescapeErrorListener listener) {
  return unescape(first.substring(firstQuoteLength(first, quote)), quote,
      location, listener);
}

String unescapeLastStringPart(String last, Quote quote, Object location,
    bool isLastQuoteSynthetic, UnescapeErrorListener listener) {
  int end = last.length - (isLastQuoteSynthetic ? 0 : lastQuoteLength(quote));
  return unescape(
      last.substring(/* start = */ 0, end), quote, location, listener);
}

String unescapeString(
    String string, Object location, UnescapeErrorListener listener) {
  Quote quote = analyzeQuote(string);
  int startIndex = firstQuoteLength(string, quote);
  int endIndex = string.length - lastQuoteLength(quote);
  if (startIndex > endIndex) {
    // An error has already been signaled.
    return "";
  }
  return unescape(
      string.substring(startIndex, endIndex), quote, location, listener);
}

String unescape(String string, Quote quote, Object location,
    UnescapeErrorListener listener) {
  String result;
  switch (quote) {
    case Quote.Single:
    case Quote.Double:
      result = !string.contains("\\")
          ? string
          : unescapeCodeUnits(
              string.codeUnits, /* isRaw = */ false, location, listener);
      break;
    case Quote.MultiLineSingle:
    case Quote.MultiLineDouble:
      result = !string.contains("\\") && !string.contains("\r")
          ? string
          : unescapeCodeUnits(
              string.codeUnits, /* isRaw = */ false, location, listener);
      break;
    case Quote.RawSingle:
    case Quote.RawDouble:
      result = string;
      break;
    case Quote.RawMultiLineSingle:
    case Quote.RawMultiLineDouble:
      result = !string.contains("\r")
          ? string
          : unescapeCodeUnits(
              string.codeUnits, /* isRaw = */ true, location, listener);
      break;
  }
  return considerCanonicalizeString(result);
}

// Note: based on
// [StringValidator.validateString](pkg/compiler/lib/src/string_validator.dart).
String unescapeCodeUnits(List<int> codeUnits, bool isRaw, Object location,
    UnescapeErrorListener listener) {
  // Can't use Uint8List or Uint16List here, the code units may be larger.
  List<int> result = new List<int>.filled(codeUnits.length, /* fill = */ 0);
  int resultOffset = 0;

  for (int i = 0; i < codeUnits.length; i++) {
    int code = codeUnits[i];
    if (code == $CR) {
      if (i + 1 < codeUnits.length && codeUnits[i + 1] == $LF) {
        i++;
      }
      code = $LF;
    } else if (!isRaw && code == $BACKSLASH) {
      if (codeUnits.length == ++i) {
        // This should only be reachable in error cases.
        listener.handleUnescapeError(
            codes.messageInvalidEscapeStarted, location, i, /* length = */ 1);
        return new String.fromCharCodes(codeUnits);
      }
      code = codeUnits[i];

      /// `\n` for newline, equivalent to `\x0A`.
      /// `\r` for carriage return, equivalent to `\x0D`.
      /// `\f` for form feed, equivalent to `\x0C`.
      /// `\b` for backspace, equivalent to `\x08`.
      /// `\t` for tab, equivalent to `\x09`.
      /// `\v` for vertical tab, equivalent to `\x0B`.
      /// `\xXX` for hex escape.
      /// `\uXXXX` or `\u{XX?X?X?X?X?}` for Unicode hex escape.
      if (code == $n) {
        code = $LF;
      } else if (code == $r) {
        code = $CR;
      } else if (code == $f) {
        code = $FF;
      } else if (code == $b) {
        code = $BS;
      } else if (code == $t) {
        code = $TAB;
      } else if (code == $v) {
        code = $VTAB;
      } else if (code == $x) {
        // Expect exactly 2 hex digits.
        int begin = i;
        if (codeUnits.length <= i + 2) {
          listener.handleUnescapeError(codes.messageInvalidHexEscape, location,
              begin, codeUnits.length + 1 - begin);
          return new String.fromCharCodes(codeUnits);
        }
        code = 0;
        for (int j = 0; j < 2; j++) {
          int digit = codeUnits[++i];
          if (!isHexDigit(digit)) {
            listener.handleUnescapeError(
                codes.messageInvalidHexEscape, location, begin, i + 1 - begin);
            return new String.fromCharCodes(codeUnits);
          }
          code = (code << 4) + hexDigitValue(digit);
        }
      } else if (code == $u) {
        int begin = i;
        if (codeUnits.length == i + 1) {
          listener.handleUnescapeError(
              codes.messageInvalidUnicodeEscapeUStarted,
              location,
              begin,
              codeUnits.length + 1 - begin);
          return new String.fromCharCodes(codeUnits);
        }
        code = codeUnits[i + 1];
        bool foundEndBracket = false;
        if (code == $OPEN_CURLY_BRACKET) {
          // Expect 1-6 hex digits followed by '}'.
          if (codeUnits.length == ++i) {
            listener.handleUnescapeError(
                codes.messageInvalidUnicodeEscapeUBracket,
                location,
                begin,
                i + 1 - begin);
            return new String.fromCharCodes(codeUnits);
          }
          code = 0;
          for (int j = 0; j < 7; j++) {
            if (codeUnits.length == ++i) {
              listener.handleUnescapeError(
                  codes.messageInvalidUnicodeEscapeUBracket,
                  location,
                  begin,
                  i + 1 - begin);
              return new String.fromCharCodes(codeUnits);
            }
            int digit = codeUnits[i];
            if (j != 0 && digit == $CLOSE_CURLY_BRACKET) {
              foundEndBracket = true;
              break;
            } else if (j == 6) {
              break;
            }
            if (!isHexDigit(digit)) {
              listener.handleUnescapeError(
                  codes.messageInvalidUnicodeEscapeUBracket,
                  location,
                  begin,
                  i + 2 - begin);
              return new String.fromCharCodes(codeUnits);
            }
            code = (code << 4) + hexDigitValue(digit);
          }
          if (!foundEndBracket) {
            listener.handleUnescapeError(
                codes.messageInvalidUnicodeEscapeUBracket,
                location,
                begin,
                i + 1 - begin);
          }
        } else {
          // Expect exactly 4 hex digits.
          if (codeUnits.length <= i + 4) {
            listener.handleUnescapeError(
                codes.messageInvalidUnicodeEscapeUNoBracket,
                location,
                begin,
                codeUnits.length + 1 - begin);
            return new String.fromCharCodes(codeUnits);
          }
          code = 0;
          for (int j = 0; j < 4; j++) {
            int digit = codeUnits[++i];
            if (!isHexDigit(digit)) {
              listener.handleUnescapeError(
                  codes.messageInvalidUnicodeEscapeUNoBracket,
                  location,
                  begin,
                  i + 1 - begin);
              return new String.fromCharCodes(codeUnits);
            }
            code = (code << 4) + hexDigitValue(digit);
          }
        }
        if (code > 0x10FFFF) {
          listener.handleUnescapeError(
              codes.messageInvalidCodePoint, location, begin, i + 1 - begin);
          return new String.fromCharCodes(codeUnits);
        }
      } else {
        // Nothing, escaped character is passed through;
      }
    }
    result[resultOffset++] = code;
  }
  return new String.fromCharCodes(result, /* start = */ 0, resultOffset);
}
