/*
 * Copyright (C) 2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Nicholas Shanks <webkit@nickshanks.com>
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2012 Intel Corporation. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "core/css/parser/CSSTokenizer.h"

#include "core/css/CSSKeyframeRule.h"
#include "core/css/MediaQuery.h"
#include "core/css/StyleRule.h"
#include "core/css/parser/BisonCSSParser.h"
#include "core/css/parser/CSSParserValues.h"
#include "core/html/parser/HTMLParserIdioms.h"

namespace blink {

#include "gen/sky/core/CSSGrammar.h"

enum CharacterType {
    // Types for the main switch.

    // The first 4 types must be grouped together, as they
    // represent the allowed chars in an identifier.
    CharacterCaselessU,
    CharacterIdentifierStart,
    CharacterNumber,
    CharacterDash,

    CharacterOther,
    CharacterNull,
    CharacterWhiteSpace,
    CharacterEndMediaQueryOrSupports,
    CharacterEndNthChild,
    CharacterQuote,
    CharacterExclamationMark,
    CharacterHashmark,
    CharacterDollar,
    CharacterAsterisk,
    CharacterPlus,
    CharacterDot,
    CharacterSlash,
    CharacterLess,
    CharacterAt,
    CharacterBackSlash,
    CharacterXor,
    CharacterVerticalBar,
    CharacterTilde,
};

// 128 ASCII codes
static const CharacterType typesOfASCIICharacters[128] = {
/*   0 - Null               */ CharacterNull,
/*   1 - Start of Heading   */ CharacterOther,
/*   2 - Start of Text      */ CharacterOther,
/*   3 - End of Text        */ CharacterOther,
/*   4 - End of Transm.     */ CharacterOther,
/*   5 - Enquiry            */ CharacterOther,
/*   6 - Acknowledgment     */ CharacterOther,
/*   7 - Bell               */ CharacterOther,
/*   8 - Back Space         */ CharacterOther,
/*   9 - Horizontal Tab     */ CharacterWhiteSpace,
/*  10 - Line Feed          */ CharacterWhiteSpace,
/*  11 - Vertical Tab       */ CharacterOther,
/*  12 - Form Feed          */ CharacterWhiteSpace,
/*  13 - Carriage Return    */ CharacterWhiteSpace,
/*  14 - Shift Out          */ CharacterOther,
/*  15 - Shift In           */ CharacterOther,
/*  16 - Data Line Escape   */ CharacterOther,
/*  17 - Device Control 1   */ CharacterOther,
/*  18 - Device Control 2   */ CharacterOther,
/*  19 - Device Control 3   */ CharacterOther,
/*  20 - Device Control 4   */ CharacterOther,
/*  21 - Negative Ack.      */ CharacterOther,
/*  22 - Synchronous Idle   */ CharacterOther,
/*  23 - End of Transmit    */ CharacterOther,
/*  24 - Cancel             */ CharacterOther,
/*  25 - End of Medium      */ CharacterOther,
/*  26 - Substitute         */ CharacterOther,
/*  27 - Escape             */ CharacterOther,
/*  28 - File Separator     */ CharacterOther,
/*  29 - Group Separator    */ CharacterOther,
/*  30 - Record Separator   */ CharacterOther,
/*  31 - Unit Separator     */ CharacterOther,
/*  32 - Space              */ CharacterWhiteSpace,
/*  33 - !                  */ CharacterExclamationMark,
/*  34 - "                  */ CharacterQuote,
/*  35 - #                  */ CharacterHashmark,
/*  36 - $                  */ CharacterDollar,
/*  37 - %                  */ CharacterOther,
/*  38 - &                  */ CharacterOther,
/*  39 - '                  */ CharacterQuote,
/*  40 - (                  */ CharacterOther,
/*  41 - )                  */ CharacterOther,
/*  42 - *                  */ CharacterAsterisk,
/*  43 - +                  */ CharacterPlus,
/*  44 - ,                  */ CharacterOther,
/*  45 - -                  */ CharacterDash,
/*  46 - .                  */ CharacterDot,
/*  47 - /                  */ CharacterSlash,
/*  48 - 0                  */ CharacterNumber,
/*  49 - 1                  */ CharacterNumber,
/*  50 - 2                  */ CharacterNumber,
/*  51 - 3                  */ CharacterNumber,
/*  52 - 4                  */ CharacterNumber,
/*  53 - 5                  */ CharacterNumber,
/*  54 - 6                  */ CharacterNumber,
/*  55 - 7                  */ CharacterNumber,
/*  56 - 8                  */ CharacterNumber,
/*  57 - 9                  */ CharacterNumber,
/*  58 - :                  */ CharacterOther,
/*  59 - ;                  */ CharacterEndMediaQueryOrSupports,
/*  60 - <                  */ CharacterLess,
/*  61 - =                  */ CharacterOther,
/*  62 - >                  */ CharacterOther,
/*  63 - ?                  */ CharacterOther,
/*  64 - @                  */ CharacterAt,
/*  65 - A                  */ CharacterIdentifierStart,
/*  66 - B                  */ CharacterIdentifierStart,
/*  67 - C                  */ CharacterIdentifierStart,
/*  68 - D                  */ CharacterIdentifierStart,
/*  69 - E                  */ CharacterIdentifierStart,
/*  70 - F                  */ CharacterIdentifierStart,
/*  71 - G                  */ CharacterIdentifierStart,
/*  72 - H                  */ CharacterIdentifierStart,
/*  73 - I                  */ CharacterIdentifierStart,
/*  74 - J                  */ CharacterIdentifierStart,
/*  75 - K                  */ CharacterIdentifierStart,
/*  76 - L                  */ CharacterIdentifierStart,
/*  77 - M                  */ CharacterIdentifierStart,
/*  78 - N                  */ CharacterIdentifierStart,
/*  79 - O                  */ CharacterIdentifierStart,
/*  80 - P                  */ CharacterIdentifierStart,
/*  81 - Q                  */ CharacterIdentifierStart,
/*  82 - R                  */ CharacterIdentifierStart,
/*  83 - S                  */ CharacterIdentifierStart,
/*  84 - T                  */ CharacterIdentifierStart,
/*  85 - U                  */ CharacterCaselessU,
/*  86 - V                  */ CharacterIdentifierStart,
/*  87 - W                  */ CharacterIdentifierStart,
/*  88 - X                  */ CharacterIdentifierStart,
/*  89 - Y                  */ CharacterIdentifierStart,
/*  90 - Z                  */ CharacterIdentifierStart,
/*  91 - [                  */ CharacterOther,
/*  92 - \                  */ CharacterBackSlash,
/*  93 - ]                  */ CharacterOther,
/*  94 - ^                  */ CharacterXor,
/*  95 - _                  */ CharacterIdentifierStart,
/*  96 - `                  */ CharacterOther,
/*  97 - a                  */ CharacterIdentifierStart,
/*  98 - b                  */ CharacterIdentifierStart,
/*  99 - c                  */ CharacterIdentifierStart,
/* 100 - d                  */ CharacterIdentifierStart,
/* 101 - e                  */ CharacterIdentifierStart,
/* 102 - f                  */ CharacterIdentifierStart,
/* 103 - g                  */ CharacterIdentifierStart,
/* 104 - h                  */ CharacterIdentifierStart,
/* 105 - i                  */ CharacterIdentifierStart,
/* 106 - j                  */ CharacterIdentifierStart,
/* 107 - k                  */ CharacterIdentifierStart,
/* 108 - l                  */ CharacterIdentifierStart,
/* 109 - m                  */ CharacterIdentifierStart,
/* 110 - n                  */ CharacterIdentifierStart,
/* 111 - o                  */ CharacterIdentifierStart,
/* 112 - p                  */ CharacterIdentifierStart,
/* 113 - q                  */ CharacterIdentifierStart,
/* 114 - r                  */ CharacterIdentifierStart,
/* 115 - s                  */ CharacterIdentifierStart,
/* 116 - t                  */ CharacterIdentifierStart,
/* 117 - u                  */ CharacterCaselessU,
/* 118 - v                  */ CharacterIdentifierStart,
/* 119 - w                  */ CharacterIdentifierStart,
/* 120 - x                  */ CharacterIdentifierStart,
/* 121 - y                  */ CharacterIdentifierStart,
/* 122 - z                  */ CharacterIdentifierStart,
/* 123 - {                  */ CharacterEndMediaQueryOrSupports,
/* 124 - |                  */ CharacterVerticalBar,
/* 125 - }                  */ CharacterOther,
/* 126 - ~                  */ CharacterTilde,
/* 127 - Delete             */ CharacterOther,
};

// Utility functions for the CSS tokenizer.

template <typename CharacterType>
static inline bool isCSSLetter(CharacterType character)
{
    return character >= 128 || typesOfASCIICharacters[character] <= CharacterDash;
}

template <typename CharacterType>
static inline bool isCSSEscape(CharacterType character)
{
    return character >= ' ' && character != 127;
}

template <typename CharacterType>
static inline bool isURILetter(CharacterType character)
{
    return (character >= '*' && character != 127) || (character >= '#' && character <= '&') || character == '!';
}

template <typename CharacterType>
static inline bool isIdentifierStartAfterDash(CharacterType* currentCharacter)
{
    return isASCIIAlpha(currentCharacter[0]) || currentCharacter[0] == '_' || currentCharacter[0] >= 128
        || (currentCharacter[0] == '\\' && isCSSEscape(currentCharacter[1]));
}

template <typename CharacterType>
static inline bool isEqualToCSSIdentifier(CharacterType* cssString, const char* constantString)
{
    // Compare an character memory data with a zero terminated string.
    do {
        // The input must be part of an identifier if constantChar or constString
        // contains '-'. Otherwise toASCIILowerUnchecked('\r') would be equal to '-'.
        ASSERT((*constantString >= 'a' && *constantString <= 'z') || *constantString == '-');
        ASSERT(*constantString != '-' || isCSSLetter(*cssString));
        if (toASCIILowerUnchecked(*cssString++) != (*constantString++))
            return false;
    } while (*constantString);
    return true;
}

template <typename CharacterType>
static inline bool isEqualToCSSCaseSensitiveIdentifier(CharacterType* string, const char* constantString)
{
    ASSERT(*constantString);

    do {
        if (*string++ != *constantString++)
            return false;
    } while (*constantString);
    return true;
}

template <typename CharacterType>
static CharacterType* checkAndSkipEscape(CharacterType* currentCharacter)
{
    // Returns with 0, if escape check is failed. Otherwise
    // it returns with the following character.
    ASSERT(*currentCharacter == '\\');

    ++currentCharacter;
    if (!isCSSEscape(*currentCharacter))
        return 0;

    if (isASCIIHexDigit(*currentCharacter)) {
        int length = 6;

        do {
            ++currentCharacter;
        } while (isASCIIHexDigit(*currentCharacter) && --length);

        // Optional space after the escape sequence.
        if (isHTMLSpace<CharacterType>(*currentCharacter))
            ++currentCharacter;
        return currentCharacter;
    }
    return currentCharacter + 1;
}

template <typename CharacterType>
static inline CharacterType* skipWhiteSpace(CharacterType* currentCharacter)
{
    while (isHTMLSpace<CharacterType>(*currentCharacter))
        ++currentCharacter;
    return currentCharacter;
}

// Main CSS tokenizer functions.

template <>
inline LChar*& CSSTokenizer::currentCharacter<LChar>()
{
    return m_currentCharacter8;
}

template <>
inline UChar*& CSSTokenizer::currentCharacter<UChar>()
{
    return m_currentCharacter16;
}

UChar* CSSTokenizer::allocateStringBuffer16(size_t len)
{
    // Allocates and returns a CSSTokenizer owned buffer for storing
    // UTF-16 data. Used to get a suitable life span for UTF-16
    // strings, identifiers and URIs created by the tokenizer.
    OwnPtr<UChar[]> buffer = adoptArrayPtr(new UChar[len]);

    UChar* bufferPtr = buffer.get();

    m_cssStrings16.append(buffer.release());
    return bufferPtr;
}

template <>
inline LChar* CSSTokenizer::dataStart<LChar>()
{
    return m_dataStart8.get();
}

template <>
inline UChar* CSSTokenizer::dataStart<UChar>()
{
    return m_dataStart16.get();
}

template <typename CharacterType>
inline CSSParserLocation CSSTokenizer::tokenLocation()
{
    CSSParserLocation location;
    location.token.init(tokenStart<CharacterType>(), currentCharacter<CharacterType>() - tokenStart<CharacterType>());
    location.lineNumber = m_tokenStartLineNumber;
    location.offset = tokenStart<CharacterType>() - dataStart<CharacterType>();
    return location;
}

CSSParserLocation CSSTokenizer::currentLocation()
{
    if (is8BitSource())
        return tokenLocation<LChar>();
    return tokenLocation<UChar>();
}

template <typename CharacterType>
inline bool CSSTokenizer::isIdentifierStart()
{
    // Check whether an identifier is started.
    return isIdentifierStartAfterDash((*currentCharacter<CharacterType>() != '-') ? currentCharacter<CharacterType>() : currentCharacter<CharacterType>() + 1);
}

enum CheckStringValidationMode {
    AbortIfInvalid,
    SkipInvalid
};

template <typename CharacterType>
static inline CharacterType* checkAndSkipString(CharacterType* currentCharacter, int quote, CheckStringValidationMode mode)
{
    // If mode is AbortIfInvalid and the string check fails it returns
    // with 0. Otherwise it returns with a pointer to the first
    // character after the string.
    while (true) {
        if (UNLIKELY(*currentCharacter == quote)) {
            // String parsing is successful.
            return currentCharacter + 1;
        }
        if (UNLIKELY(!*currentCharacter)) {
            // String parsing is successful up to end of input.
            return currentCharacter;
        }
        if (mode == AbortIfInvalid && UNLIKELY(*currentCharacter <= '\r' && (*currentCharacter == '\n' || (*currentCharacter | 0x1) == '\r'))) {
            // String parsing is failed for character '\n', '\f' or '\r'.
            return 0;
        }

        if (LIKELY(currentCharacter[0] != '\\')) {
            ++currentCharacter;
        } else if (currentCharacter[1] == '\n' || currentCharacter[1] == '\f') {
            currentCharacter += 2;
        } else if (currentCharacter[1] == '\r') {
            currentCharacter += currentCharacter[2] == '\n' ? 3 : 2;
        } else {
            CharacterType* next = checkAndSkipEscape(currentCharacter);
            if (!next) {
                if (mode == AbortIfInvalid)
                    return 0;
                next = currentCharacter + 1;
            }
            currentCharacter = next;
        }
    }
}

template <typename CharacterType>
unsigned CSSTokenizer::parseEscape(CharacterType*& src)
{
    ASSERT(*src == '\\' && isCSSEscape(src[1]));

    unsigned unicode = 0;

    ++src;
    if (isASCIIHexDigit(*src)) {

        int length = 6;

        do {
            unicode = (unicode << 4) + toASCIIHexValue(*src++);
        } while (--length && isASCIIHexDigit(*src));

        // Characters above 0x10ffff are not handled.
        if (unicode > 0x10ffff)
            unicode = 0xfffd;

        // Optional space after the escape sequence.
        if (isHTMLSpace<CharacterType>(*src))
            ++src;

        return unicode;
    }

    return *src++;
}

template <>
inline void CSSTokenizer::UnicodeToChars<LChar>(LChar*& result, unsigned unicode)
{
    ASSERT(unicode <= 0xff);
    *result = unicode;

    ++result;
}

template <>
inline void CSSTokenizer::UnicodeToChars<UChar>(UChar*& result, unsigned unicode)
{
    // Replace unicode with a surrogate pairs when it is bigger than 0xffff
    if (U16_LENGTH(unicode) == 2) {
        *result++ = U16_LEAD(unicode);
        *result = U16_TRAIL(unicode);
    } else {
        *result = unicode;
    }

    ++result;
}

template <typename SrcCharacterType>
size_t CSSTokenizer::peekMaxIdentifierLen(SrcCharacterType* src)
{
    // The decoded form of an identifier (after resolving escape
    // sequences) will not contain more characters (ASCII or UTF-16
    // codepoints) than the input. This code can therefore ignore
    // escape sequences completely.
    SrcCharacterType* start = src;
    do {
        if (LIKELY(*src != '\\'))
            src++;
        else
            parseEscape<SrcCharacterType>(src);
    } while (isCSSLetter(src[0]) || (src[0] == '\\' && isCSSEscape(src[1])));

    return src - start;
}

template <typename SrcCharacterType, typename DestCharacterType>
inline bool CSSTokenizer::parseIdentifierInternal(SrcCharacterType*& src, DestCharacterType*& result, bool& hasEscape)
{
    hasEscape = false;
    do {
        if (LIKELY(*src != '\\')) {
            *result++ = *src++;
        } else {
            hasEscape = true;
            SrcCharacterType* savedEscapeStart = src;
            unsigned unicode = parseEscape<SrcCharacterType>(src);
            if (unicode > 0xff && sizeof(DestCharacterType) == 1) {
                src = savedEscapeStart;
                return false;
            }
            UnicodeToChars(result, unicode);
        }
    } while (isCSSLetter(src[0]) || (src[0] == '\\' && isCSSEscape(src[1])));

    return true;
}

template <typename CharacterType>
inline void CSSTokenizer::parseIdentifier(CharacterType*& result, CSSParserString& resultString, bool& hasEscape)
{
    // If a valid identifier start is found, we can safely
    // parse the identifier until the next invalid character.
    ASSERT(isIdentifierStart<CharacterType>());

    CharacterType* start = currentCharacter<CharacterType>();
    if (UNLIKELY(!parseIdentifierInternal(currentCharacter<CharacterType>(), result, hasEscape))) {
        // Found an escape we couldn't handle with 8 bits, copy what has been recognized and continue
        ASSERT(is8BitSource());
        UChar* result16 = allocateStringBuffer16((result - start) + peekMaxIdentifierLen(currentCharacter<CharacterType>()));
        UChar* start16 = result16;
        int i = 0;
        for (; i < result - start; i++)
            result16[i] = start[i];

        result16 += i;

        parseIdentifierInternal(currentCharacter<CharacterType>(), result16, hasEscape);

        resultString.init(start16, result16 - start16);

        return;
    }

    resultString.init(start, result - start);
}

template <typename SrcCharacterType>
size_t CSSTokenizer::peekMaxStringLen(SrcCharacterType* src, UChar quote)
{
    // The decoded form of a CSS string (after resolving escape
    // sequences) will not contain more characters (ASCII or UTF-16
    // codepoints) than the input. This code can therefore ignore
    // escape sequences completely and just return the length of the
    // input string (possibly including terminating quote if any).
    SrcCharacterType* end = checkAndSkipString(src, quote, SkipInvalid);
    return end ? end - src : 0;
}

template <typename SrcCharacterType, typename DestCharacterType>
inline bool CSSTokenizer::parseStringInternal(SrcCharacterType*& src, DestCharacterType*& result, UChar quote)
{
    while (true) {
        if (UNLIKELY(*src == quote)) {
            // String parsing is done.
            ++src;
            return true;
        }
        if (UNLIKELY(!*src)) {
            // String parsing is done, but don't advance pointer if at the end of input.
            return true;
        }
        if (LIKELY(src[0] != '\\')) {
            *result++ = *src++;
        } else if (src[1] == '\n' || src[1] == '\f') {
            src += 2;
        } else if (src[1] == '\r') {
            src += src[2] == '\n' ? 3 : 2;
        } else {
            SrcCharacterType* savedEscapeStart = src;
            unsigned unicode = parseEscape<SrcCharacterType>(src);
            if (unicode > 0xff && sizeof(DestCharacterType) == 1) {
                src = savedEscapeStart;
                return false;
            }
            UnicodeToChars(result, unicode);
        }
    }

    return true;
}

template <typename CharacterType>
inline void CSSTokenizer::parseString(CharacterType*& result, CSSParserString& resultString, UChar quote)
{
    CharacterType* start = currentCharacter<CharacterType>();

    if (UNLIKELY(!parseStringInternal(currentCharacter<CharacterType>(), result, quote))) {
        // Found an escape we couldn't handle with 8 bits, copy what has been recognized and continue
        ASSERT(is8BitSource());
        UChar* result16 = allocateStringBuffer16((result - start) + peekMaxStringLen(currentCharacter<CharacterType>(), quote));
        UChar* start16 = result16;
        int i = 0;
        for (; i < result - start; i++)
            result16[i] = start[i];

        result16 += i;

        parseStringInternal(currentCharacter<CharacterType>(), result16, quote);

        resultString.init(start16, result16 - start16);
        return;
    }

    resultString.init(start, result - start);
}

template <typename CharacterType>
inline bool CSSTokenizer::findURI(CharacterType*& start, CharacterType*& end, UChar& quote)
{
    start = skipWhiteSpace(currentCharacter<CharacterType>());

    if (*start == '"' || *start == '\'') {
        quote = *start++;
        end = checkAndSkipString(start, quote, AbortIfInvalid);
        if (!end)
            return false;
    } else {
        quote = 0;
        end = start;
        while (isURILetter(*end)) {
            if (LIKELY(*end != '\\')) {
                ++end;
            } else {
                end = checkAndSkipEscape(end);
                if (!end)
                    return false;
            }
        }
    }

    end = skipWhiteSpace(end);
    if (*end != ')')
        return false;

    return true;
}

template <typename SrcCharacterType>
inline size_t CSSTokenizer::peekMaxURILen(SrcCharacterType* src, UChar quote)
{
    // The decoded form of a URI (after resolving escape sequences)
    // will not contain more characters (ASCII or UTF-16 codepoints)
    // than the input. This code can therefore ignore escape sequences
    // completely.
    SrcCharacterType* start = src;
    if (quote) {
        ASSERT(quote == '"' || quote == '\'');
        return peekMaxStringLen(src, quote);
    }

    while (isURILetter(*src)) {
        if (LIKELY(*src != '\\'))
            src++;
        else
            parseEscape<SrcCharacterType>(src);
    }

    return src - start;
}

template <typename SrcCharacterType, typename DestCharacterType>
inline bool CSSTokenizer::parseURIInternal(SrcCharacterType*& src, DestCharacterType*& dest, UChar quote)
{
    if (quote) {
        ASSERT(quote == '"' || quote == '\'');
        return parseStringInternal(src, dest, quote);
    }

    while (isURILetter(*src)) {
        if (LIKELY(*src != '\\')) {
            *dest++ = *src++;
        } else {
            unsigned unicode = parseEscape<SrcCharacterType>(src);
            if (unicode > 0xff && sizeof(DestCharacterType) == 1)
                return false;
            UnicodeToChars(dest, unicode);
        }
    }

    return true;
}

template <typename CharacterType>
inline void CSSTokenizer::parseURI(CSSParserString& string)
{
    CharacterType* uriStart;
    CharacterType* uriEnd;
    UChar quote;
    if (!findURI(uriStart, uriEnd, quote))
        return;

    CharacterType* dest = currentCharacter<CharacterType>() = uriStart;
    if (LIKELY(parseURIInternal(currentCharacter<CharacterType>(), dest, quote))) {
        string.init(uriStart, dest - uriStart);
    } else {
        // An escape sequence was encountered that can't be stored in 8 bits.
        // Reset the current character to the start of the URI and re-parse with
        // a 16-bit destination.
        ASSERT(is8BitSource());
        currentCharacter<CharacterType>() = uriStart;
        UChar* result16 = allocateStringBuffer16(peekMaxURILen(currentCharacter<CharacterType>(), quote));
        UChar* uriStart16 = result16;
        bool result = parseURIInternal(currentCharacter<CharacterType>(), result16, quote);
        ASSERT_UNUSED(result, result);
        string.init(uriStart16, result16 - uriStart16);
    }

    currentCharacter<CharacterType>() = uriEnd + 1;
    m_token = URI;
}

template <typename CharacterType>
inline bool CSSTokenizer::parseUnicodeRange()
{
    CharacterType* character = currentCharacter<CharacterType>() + 1;
    int length = 6;
    ASSERT(*currentCharacter<CharacterType>() == '+');

    while (isASCIIHexDigit(*character) && length) {
        ++character;
        --length;
    }

    if (length && *character == '?') {
        // At most 5 hex digit followed by a question mark.
        do {
            ++character;
            --length;
        } while (*character == '?' && length);
        currentCharacter<CharacterType>() = character;
        return true;
    }

    if (length < 6) {
        // At least one hex digit.
        if (character[0] == '-' && isASCIIHexDigit(character[1])) {
            // Followed by a dash and a hex digit.
            ++character;
            length = 6;
            do {
                ++character;
            } while (--length && isASCIIHexDigit(*character));
        }
        currentCharacter<CharacterType>() = character;
        return true;
    }
    return false;
}

template <typename CharacterType>
inline bool CSSTokenizer::detectFunctionTypeToken(int length)
{
    ASSERT(length > 0);
    CharacterType* name = tokenStart<CharacterType>();
    SWITCH(name, length) {
        CASE("not") {
            m_token = NOTFUNCTION;
            return true;
        }
        CASE("url") {
            m_token = URI;
            return true;
        }
        CASE("calc") {
            m_token = CALCFUNCTION;
            return true;
        }
        CASE("host") {
            m_token = HOSTFUNCTION;
            return true;
        }
    }
    return false;
}

template <typename CharacterType>
inline void CSSTokenizer::detectMediaQueryToken(int length)
{
    ASSERT(m_parsingMode == MediaQueryMode);
    CharacterType* name = tokenStart<CharacterType>();

    SWITCH(name, length) {
        CASE("and") {
            m_token = MEDIA_AND;
        }
        CASE("not") {
            m_token = MEDIA_NOT;
        }
        CASE("only") {
            m_token = MEDIA_ONLY;
        }
        CASE("or") {
            m_token = MEDIA_OR;
        }
    }
}

template <typename CharacterType>
inline void CSSTokenizer::detectNumberToken(CharacterType* type, int length)
{
    ASSERT(length > 0);

    SWITCH(type, length) {
        CASE("cm") {
            m_token = CMS;
        }
        CASE("ch") {
            m_token = CHS;
        }
        CASE("deg") {
            m_token = DEGS;
        }
        CASE("dppx") {
            // There is a discussion about the name of this unit on www-style.
            // Keep this compile time guard in place until that is resolved.
            // http://lists.w3.org/Archives/Public/www-style/2012May/0915.html
            m_token = DPPX;
        }
        CASE("dpcm") {
            m_token = DPCM;
        }
        CASE("dpi") {
            m_token = DPI;
        }
        CASE("em") {
            m_token = EMS;
        }
        CASE("ex") {
            m_token = EXS;
        }
        CASE("fr") {
            m_token = FR;
        }
        CASE("grad") {
            m_token = GRADS;
        }
        CASE("hz") {
            m_token = HERTZ;
        }
        CASE("in") {
            m_token = INS;
        }
        CASE("khz") {
            m_token = KHERTZ;
        }
        CASE("mm") {
            m_token = MMS;
        }
        CASE("ms") {
            m_token = MSECS;
        }
        CASE("px") {
            m_token = PXS;
        }
        CASE("pt") {
            m_token = PTS;
        }
        CASE("pc") {
            m_token = PCS;
        }
        CASE("rad") {
            m_token = RADS;
        }
        CASE("rem") {
            m_token = REMS;
        }
        CASE("s") {
            m_token = SECS;
        }
        CASE("turn") {
            m_token = TURNS;
        }
        CASE("vw") {
            m_token = VW;
        }
        CASE("vh") {
            m_token = VH;
        }
        CASE("vmin") {
            m_token = VMIN;
        }
        CASE("vmax") {
            m_token = VMAX;
        }
    }
}

template <typename CharacterType>
inline void CSSTokenizer::detectDashToken(int length)
{
    CharacterType* name = tokenStart<CharacterType>();

    // Ignore leading dash.
    ++name;
    --length;

    SWITCH(name, length) {
        CASE("webkit-calc") {
            m_token = CALCFUNCTION;
        }
    }
}

template <typename CharacterType>
inline void CSSTokenizer::detectAtToken(int length, bool hasEscape)
{
    CharacterType* name = tokenStart<CharacterType>();
    ASSERT(name[0] == '@' && length >= 2);

    // Ignore leading @.
    ++name;
    --length;

    // charset, font-face, media, supports,
    // -webkit-keyframes, keyframes, and -webkit-mediaquery are not affected by hasEscape.
    SWITCH(name, length) {
        CASE("charset") {
            if (name - 1 == dataStart<CharacterType>())
                m_token = CHARSET_SYM;
        }
        CASE("font-face") {
            m_token = FONT_FACE_SYM;
        }
        CASE("keyframes") {
            if (RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled())
                m_token = KEYFRAMES_SYM;
        }
        CASE("media") {
            m_parsingMode = MediaQueryMode;
            m_token = MEDIA_SYM;
        }
        CASE("supports") {
            m_parsingMode = SupportsMode;
            m_token = SUPPORTS_SYM;
        }
        CASE("-internal-rule") {
            if (LIKELY(!hasEscape && m_internal))
                m_token = INTERNAL_RULE_SYM;
        }
        CASE("-internal-decls") {
            if (LIKELY(!hasEscape && m_internal))
                m_token = INTERNAL_DECLS_SYM;
        }
        CASE("-internal-value") {
            if (LIKELY(!hasEscape && m_internal))
                m_token = INTERNAL_VALUE_SYM;
        }
        CASE("-webkit-keyframes") {
            m_token = WEBKIT_KEYFRAMES_SYM;
        }
        CASE("-internal-selector") {
            if (LIKELY(!hasEscape && m_internal))
                m_token = INTERNAL_SELECTOR_SYM;
        }
        CASE("-internal-medialist") {
            if (!m_internal)
                return;
            m_parsingMode = MediaQueryMode;
            m_token = INTERNAL_MEDIALIST_SYM;
        }
        CASE("-internal-keyframe-rule") {
            if (LIKELY(!hasEscape && m_internal))
                m_token = INTERNAL_KEYFRAME_RULE_SYM;
        }
        CASE("-internal-keyframe-key-list") {
            if (!m_internal)
                return;
            m_token = INTERNAL_KEYFRAME_KEY_LIST_SYM;
        }
        CASE("-internal-supports-condition") {
            if (!m_internal)
                return;
            m_parsingMode = SupportsMode;
            m_token = INTERNAL_SUPPORTS_CONDITION_SYM;
        }
    }
}

template <typename CharacterType>
inline void CSSTokenizer::detectSupportsToken(int length)
{
    ASSERT(m_parsingMode == SupportsMode);
    CharacterType* name = tokenStart<CharacterType>();

    SWITCH(name, length) {
        CASE("or") {
            m_token = SUPPORTS_OR;
        }
        CASE("and") {
            m_token = SUPPORTS_AND;
        }
        CASE("not") {
            m_token = SUPPORTS_NOT;
        }
    }
}

template <typename SrcCharacterType>
int CSSTokenizer::realLex(void* yylvalWithoutType)
{
    YYSTYPE* yylval = static_cast<YYSTYPE*>(yylvalWithoutType);
    // Write pointer for the next character.
    SrcCharacterType* result;
    CSSParserString resultString;
    bool hasEscape;

    // The input buffer is terminated by a \0 character, so
    // it is safe to read one character ahead of a known non-null.
#if ENABLE(ASSERT)
    // In debug we check with an ASSERT that the length is > 0 for string types.
    yylval->string.clear();
#endif

restartAfterComment:
    result = currentCharacter<SrcCharacterType>();
    setTokenStart(result);
    m_tokenStartLineNumber = m_lineNumber;
    m_token = *currentCharacter<SrcCharacterType>();
    ++currentCharacter<SrcCharacterType>();

    switch ((m_token <= 127) ? typesOfASCIICharacters[m_token] : CharacterIdentifierStart) {
    case CharacterCaselessU:
        if (UNLIKELY(*currentCharacter<SrcCharacterType>() == '+')) {
            if (parseUnicodeRange<SrcCharacterType>()) {
                m_token = UNICODERANGE;
                yylval->string.init(tokenStart<SrcCharacterType>(), currentCharacter<SrcCharacterType>() - tokenStart<SrcCharacterType>());
                break;
            }
        }
        // Fall through to CharacterIdentifierStart.

    case CharacterIdentifierStart:
        --currentCharacter<SrcCharacterType>();
        parseIdentifier(result, yylval->string, hasEscape);
        m_token = IDENT;

        if (UNLIKELY(*currentCharacter<SrcCharacterType>() == '(')) {
            if (m_parsingMode == SupportsMode && !hasEscape) {
                detectSupportsToken<SrcCharacterType>(result - tokenStart<SrcCharacterType>());
                if (m_token != IDENT)
                    break;
            }

            m_token = FUNCTION;
            if (!hasEscape)
                detectFunctionTypeToken<SrcCharacterType>(result - tokenStart<SrcCharacterType>());

            // Skip parenthesis
            ++currentCharacter<SrcCharacterType>();
            ++result;
            ++yylval->string.m_length;

            if (m_token == URI) {
                m_token = FUNCTION;
                // Check whether it is really an URI.
                if (yylval->string.is8Bit())
                    parseURI<LChar>(yylval->string);
                else
                    parseURI<UChar>(yylval->string);
            }
        } else if (UNLIKELY(m_parsingMode != NormalMode) && !hasEscape) {
            if (m_parsingMode == MediaQueryMode) {
                detectMediaQueryToken<SrcCharacterType>(result - tokenStart<SrcCharacterType>());
            } else if (m_parsingMode == SupportsMode) {
                detectSupportsToken<SrcCharacterType>(result - tokenStart<SrcCharacterType>());
            }
        }
        break;

    case CharacterDot:
        if (!isASCIIDigit(currentCharacter<SrcCharacterType>()[0]))
            break;
        // Fall through to CharacterNumber.

    case CharacterNumber: {
        bool dotSeen = (m_token == '.');

        while (true) {
            if (!isASCIIDigit(currentCharacter<SrcCharacterType>()[0])) {
                // Only one dot is allowed for a number,
                // and it must be followed by a digit.
                if (currentCharacter<SrcCharacterType>()[0] != '.' || dotSeen || !isASCIIDigit(currentCharacter<SrcCharacterType>()[1]))
                    break;
                dotSeen = true;
            }
            ++currentCharacter<SrcCharacterType>();
        }

        yylval->number = charactersToDouble(tokenStart<SrcCharacterType>(), currentCharacter<SrcCharacterType>() - tokenStart<SrcCharacterType>());

        // Type of the function.
        if (isIdentifierStart<SrcCharacterType>()) {
            SrcCharacterType* type = currentCharacter<SrcCharacterType>();
            result = currentCharacter<SrcCharacterType>();

            parseIdentifier(result, resultString, hasEscape);

            m_token = DIMEN;
            if (!hasEscape)
                detectNumberToken(type, currentCharacter<SrcCharacterType>() - type);

            if (m_token == DIMEN) {
                // The decoded number is overwritten, but this is intentional.
                yylval->string.init(tokenStart<SrcCharacterType>(), currentCharacter<SrcCharacterType>() - tokenStart<SrcCharacterType>());
            }
        } else if (*currentCharacter<SrcCharacterType>() == '%') {
            // Although the CSS grammar says {num}% we follow
            // webkit at the moment which uses {num}%+.
            do {
                ++currentCharacter<SrcCharacterType>();
            } while (*currentCharacter<SrcCharacterType>() == '%');
            m_token = PERCENTAGE;
        } else {
            m_token = dotSeen ? FLOATTOKEN : INTEGER;
        }
        break;
    }

    case CharacterDash:
        if (isIdentifierStartAfterDash(currentCharacter<SrcCharacterType>())) {
            --currentCharacter<SrcCharacterType>();
            parseIdentifier(result, resultString, hasEscape);
            m_token = IDENT;

            if (*currentCharacter<SrcCharacterType>() == '(') {
                m_token = FUNCTION;
                if (!hasEscape)
                    detectDashToken<SrcCharacterType>(result - tokenStart<SrcCharacterType>());
                ++currentCharacter<SrcCharacterType>();
                ++result;
            }
            resultString.setLength(result - tokenStart<SrcCharacterType>());
            yylval->string = resultString;
        } else if (currentCharacter<SrcCharacterType>()[0] == '-' && currentCharacter<SrcCharacterType>()[1] == '>') {
            currentCharacter<SrcCharacterType>() += 2;
            m_token = SGML_CD;
        }
        break;

    case CharacterOther:
        // m_token is simply the current character.
        break;

    case CharacterNull:
        // Do not advance pointer at the end of input.
        --currentCharacter<SrcCharacterType>();
        break;

    case CharacterWhiteSpace:
        m_token = WHITESPACE;
        // Might start with a '\n'.
        --currentCharacter<SrcCharacterType>();
        do {
            if (*currentCharacter<SrcCharacterType>() == '\n')
                ++m_lineNumber;
            ++currentCharacter<SrcCharacterType>();
        } while (*currentCharacter<SrcCharacterType>() <= ' ' && (typesOfASCIICharacters[*currentCharacter<SrcCharacterType>()] == CharacterWhiteSpace));
        break;

    case CharacterEndMediaQueryOrSupports:
        if (m_parsingMode == MediaQueryMode || m_parsingMode == SupportsMode)
            m_parsingMode = NormalMode;
        break;

    case CharacterQuote:
        if (checkAndSkipString(currentCharacter<SrcCharacterType>(), m_token, AbortIfInvalid)) {
            ++result;
            parseString<SrcCharacterType>(result, yylval->string, m_token);
            m_token = STRING;
        }
        break;

    case CharacterExclamationMark: {
        SrcCharacterType* start = skipWhiteSpace(currentCharacter<SrcCharacterType>());
        if (isEqualToCSSIdentifier(start, "important")) {
            m_token = IMPORTANT_SYM;
            currentCharacter<SrcCharacterType>() = start + 9;
        }
        break;
    }

    case CharacterHashmark: {
        SrcCharacterType* start = currentCharacter<SrcCharacterType>();
        result = currentCharacter<SrcCharacterType>();

        if (isASCIIDigit(*currentCharacter<SrcCharacterType>())) {
            // This must be a valid hex number token.
            do {
                ++currentCharacter<SrcCharacterType>();
            } while (isASCIIHexDigit(*currentCharacter<SrcCharacterType>()));
            m_token = HEX;
            yylval->string.init(start, currentCharacter<SrcCharacterType>() - start);
        } else if (isIdentifierStart<SrcCharacterType>()) {
            m_token = IDSEL;
            parseIdentifier(result, yylval->string, hasEscape);
            if (!hasEscape) {
                // Check whether the identifier is also a valid hex number.
                SrcCharacterType* current = start;
                m_token = HEX;
                do {
                    if (!isASCIIHexDigit(*current)) {
                        m_token = IDSEL;
                        break;
                    }
                    ++current;
                } while (current < result);
            }
        }
        break;
    }

    case CharacterSlash:
        // Ignore comments. They are not even considered as white spaces.
        if (*currentCharacter<SrcCharacterType>() == '*') {
            const CSSParserLocation startLocation = currentLocation();
            if (m_parser.m_observer) {
                unsigned startOffset = currentCharacter<SrcCharacterType>() - dataStart<SrcCharacterType>() - 1; // Start with a slash.
                m_parser.m_observer->startComment(startOffset - m_parsedTextPrefixLength);
            }
            ++currentCharacter<SrcCharacterType>();
            while (currentCharacter<SrcCharacterType>()[0] != '*' || currentCharacter<SrcCharacterType>()[1] != '/') {
                if (*currentCharacter<SrcCharacterType>() == '\n')
                    ++m_lineNumber;
                if (*currentCharacter<SrcCharacterType>() == '\0') {
                    // Unterminated comments are simply ignored.
                    currentCharacter<SrcCharacterType>() -= 2;
                    m_parser.reportError(startLocation, UnterminatedCommentCSSError);
                    break;
                }
                ++currentCharacter<SrcCharacterType>();
            }
            currentCharacter<SrcCharacterType>() += 2;
            if (m_parser.m_observer) {
                unsigned endOffset = currentCharacter<SrcCharacterType>() - dataStart<SrcCharacterType>();
                unsigned userTextEndOffset = static_cast<unsigned>(m_length - 1 - m_parsedTextSuffixLength);
                m_parser.m_observer->endComment(std::min(endOffset, userTextEndOffset) - m_parsedTextPrefixLength);
            }
            goto restartAfterComment;
        }
        break;

    case CharacterDollar:
        if (*currentCharacter<SrcCharacterType>() == '=') {
            ++currentCharacter<SrcCharacterType>();
            m_token = ENDSWITH;
        }
        break;

    case CharacterAsterisk:
        if (*currentCharacter<SrcCharacterType>() == '=') {
            ++currentCharacter<SrcCharacterType>();
            m_token = CONTAINS;
        }
        break;

    case CharacterPlus:
        break;

    case CharacterLess:
        if (currentCharacter<SrcCharacterType>()[0] == '!' && currentCharacter<SrcCharacterType>()[1] == '-' && currentCharacter<SrcCharacterType>()[2] == '-') {
            currentCharacter<SrcCharacterType>() += 3;
            m_token = SGML_CD;
        }
        break;

    case CharacterAt:
        if (isIdentifierStart<SrcCharacterType>()) {
            m_token = ATKEYWORD;
            ++result;
            parseIdentifier(result, resultString, hasEscape);
            // The standard enables unicode escapes in at-rules. In this case only the resultString will contain the
            // correct identifier, hence we have to use it to determine its length instead of the usual pointer arithmetic.
            detectAtToken<SrcCharacterType>(resultString.length() + 1, hasEscape);
        }
        break;

    case CharacterBackSlash:
        if (isCSSEscape(*currentCharacter<SrcCharacterType>())) {
            --currentCharacter<SrcCharacterType>();
            parseIdentifier(result, yylval->string, hasEscape);
            m_token = IDENT;
        }
        break;

    case CharacterXor:
        if (*currentCharacter<SrcCharacterType>() == '=') {
            ++currentCharacter<SrcCharacterType>();
            m_token = BEGINSWITH;
        }
        break;

    case CharacterVerticalBar:
        if (*currentCharacter<SrcCharacterType>() == '=') {
            ++currentCharacter<SrcCharacterType>();
            m_token = DASHMATCH;
        }
        break;

    case CharacterTilde:
        if (*currentCharacter<SrcCharacterType>() == '=') {
            ++currentCharacter<SrcCharacterType>();
            m_token = INCLUDES;
        }
        break;

    default:
        ASSERT_NOT_REACHED();
        break;
    }

    return m_token;
}

template <>
inline void CSSTokenizer::setTokenStart<LChar>(LChar* tokenStart)
{
    m_tokenStart.ptr8 = tokenStart;
}

template <>
inline void CSSTokenizer::setTokenStart<UChar>(UChar* tokenStart)
{
    m_tokenStart.ptr16 = tokenStart;
}

void CSSTokenizer::setupTokenizer(const char* prefix, unsigned prefixLength, const String& string, const char* suffix, unsigned suffixLength)
{
    m_parsedTextPrefixLength = prefixLength;
    m_parsedTextSuffixLength = suffixLength;
    unsigned stringLength = string.length();
    unsigned length = stringLength + m_parsedTextPrefixLength + m_parsedTextSuffixLength + 1;
    m_length = length;

    if (!stringLength || string.is8Bit()) {
        m_dataStart8 = adoptArrayPtr(new LChar[length]);
        for (unsigned i = 0; i < m_parsedTextPrefixLength; i++)
            m_dataStart8[i] = prefix[i];

        if (stringLength)
            memcpy(m_dataStart8.get() + m_parsedTextPrefixLength, string.characters8(), stringLength * sizeof(LChar));

        unsigned start = m_parsedTextPrefixLength + stringLength;
        unsigned end = start + suffixLength;
        for (unsigned i = start; i < end; i++)
            m_dataStart8[i] = suffix[i - start];

        m_dataStart8[length - 1] = 0;

        m_is8BitSource = true;
        m_currentCharacter8 = m_dataStart8.get();
        m_currentCharacter16 = 0;
        setTokenStart<LChar>(m_currentCharacter8);
        m_lexFunc = &CSSTokenizer::realLex<LChar>;
        return;
    }

    m_dataStart16 = adoptArrayPtr(new UChar[length]);
    for (unsigned i = 0; i < m_parsedTextPrefixLength; i++)
        m_dataStart16[i] = prefix[i];

    ASSERT(stringLength);
    memcpy(m_dataStart16.get() + m_parsedTextPrefixLength, string.characters16(), stringLength * sizeof(UChar));

    unsigned start = m_parsedTextPrefixLength + stringLength;
    unsigned end = start + suffixLength;
    for (unsigned i = start; i < end; i++)
        m_dataStart16[i] = suffix[i - start];

    m_dataStart16[length - 1] = 0;

    m_is8BitSource = false;
    m_currentCharacter8 = 0;
    m_currentCharacter16 = m_dataStart16.get();
    setTokenStart<UChar>(m_currentCharacter16);
    m_lexFunc = &CSSTokenizer::realLex<UChar>;
}

} // namespace blink
