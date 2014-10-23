/*
 *  Copyright (C) 2006 George Staikos <staikos@kde.org>
 *  Copyright (C) 2006 Alexey Proskuryakov <ap@nypop.com>
 *  Copyright (C) 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 */

#ifndef WTF_UNICODE_ICU_H
#define WTF_UNICODE_ICU_H

#include <unicode/uchar.h>
#include <unicode/ustring.h>

namespace WTF {

namespace Unicode {

enum Direction {
    LeftToRight = U_LEFT_TO_RIGHT,
    RightToLeft = U_RIGHT_TO_LEFT,
    EuropeanNumber = U_EUROPEAN_NUMBER,
    EuropeanNumberSeparator = U_EUROPEAN_NUMBER_SEPARATOR,
    EuropeanNumberTerminator = U_EUROPEAN_NUMBER_TERMINATOR,
    ArabicNumber = U_ARABIC_NUMBER,
    CommonNumberSeparator = U_COMMON_NUMBER_SEPARATOR,
    BlockSeparator = U_BLOCK_SEPARATOR,
    SegmentSeparator = U_SEGMENT_SEPARATOR,
    WhiteSpaceNeutral = U_WHITE_SPACE_NEUTRAL,
    OtherNeutral = U_OTHER_NEUTRAL,
    LeftToRightEmbedding = U_LEFT_TO_RIGHT_EMBEDDING,
    LeftToRightOverride = U_LEFT_TO_RIGHT_OVERRIDE,
    RightToLeftArabic = U_RIGHT_TO_LEFT_ARABIC,
    RightToLeftEmbedding = U_RIGHT_TO_LEFT_EMBEDDING,
    RightToLeftOverride = U_RIGHT_TO_LEFT_OVERRIDE,
    PopDirectionalFormat = U_POP_DIRECTIONAL_FORMAT,
    NonSpacingMark = U_DIR_NON_SPACING_MARK,
    BoundaryNeutral = U_BOUNDARY_NEUTRAL
};

enum DecompositionType {
    DecompositionNone = U_DT_NONE,
    DecompositionCanonical = U_DT_CANONICAL,
    DecompositionCompat = U_DT_COMPAT,
    DecompositionCircle = U_DT_CIRCLE,
    DecompositionFinal = U_DT_FINAL,
    DecompositionFont = U_DT_FONT,
    DecompositionFraction = U_DT_FRACTION,
    DecompositionInitial = U_DT_INITIAL,
    DecompositionIsolated = U_DT_ISOLATED,
    DecompositionMedial = U_DT_MEDIAL,
    DecompositionNarrow = U_DT_NARROW,
    DecompositionNoBreak = U_DT_NOBREAK,
    DecompositionSmall = U_DT_SMALL,
    DecompositionSquare = U_DT_SQUARE,
    DecompositionSub = U_DT_SUB,
    DecompositionSuper = U_DT_SUPER,
    DecompositionVertical = U_DT_VERTICAL,
    DecompositionWide = U_DT_WIDE,
};

enum CharCategory {
    NoCategory =  0,
    Other_NotAssigned = U_MASK(U_GENERAL_OTHER_TYPES),
    Letter_Uppercase = U_MASK(U_UPPERCASE_LETTER),
    Letter_Lowercase = U_MASK(U_LOWERCASE_LETTER),
    Letter_Titlecase = U_MASK(U_TITLECASE_LETTER),
    Letter_Modifier = U_MASK(U_MODIFIER_LETTER),
    Letter_Other = U_MASK(U_OTHER_LETTER),

    Mark_NonSpacing = U_MASK(U_NON_SPACING_MARK),
    Mark_Enclosing = U_MASK(U_ENCLOSING_MARK),
    Mark_SpacingCombining = U_MASK(U_COMBINING_SPACING_MARK),

    Number_DecimalDigit = U_MASK(U_DECIMAL_DIGIT_NUMBER),
    Number_Letter = U_MASK(U_LETTER_NUMBER),
    Number_Other = U_MASK(U_OTHER_NUMBER),

    Separator_Space = U_MASK(U_SPACE_SEPARATOR),
    Separator_Line = U_MASK(U_LINE_SEPARATOR),
    Separator_Paragraph = U_MASK(U_PARAGRAPH_SEPARATOR),

    Other_Control = U_MASK(U_CONTROL_CHAR),
    Other_Format = U_MASK(U_FORMAT_CHAR),
    Other_PrivateUse = U_MASK(U_PRIVATE_USE_CHAR),
    Other_Surrogate = U_MASK(U_SURROGATE),

    Punctuation_Dash = U_MASK(U_DASH_PUNCTUATION),
    Punctuation_Open = U_MASK(U_START_PUNCTUATION),
    Punctuation_Close = U_MASK(U_END_PUNCTUATION),
    Punctuation_Connector = U_MASK(U_CONNECTOR_PUNCTUATION),
    Punctuation_Other = U_MASK(U_OTHER_PUNCTUATION),

    Symbol_Math = U_MASK(U_MATH_SYMBOL),
    Symbol_Currency = U_MASK(U_CURRENCY_SYMBOL),
    Symbol_Modifier = U_MASK(U_MODIFIER_SYMBOL),
    Symbol_Other = U_MASK(U_OTHER_SYMBOL),

    Punctuation_InitialQuote = U_MASK(U_INITIAL_PUNCTUATION),
    Punctuation_FinalQuote = U_MASK(U_FINAL_PUNCTUATION)
};

inline UChar32 foldCase(UChar32 c)
{
    return u_foldCase(c, U_FOLD_CASE_DEFAULT);
}

inline int foldCase(UChar* result, int resultLength, const UChar* src, int srcLength, bool* error)
{
    UErrorCode status = U_ZERO_ERROR;
    int realLength = u_strFoldCase(result, resultLength, src, srcLength, U_FOLD_CASE_DEFAULT, &status);
    *error = !U_SUCCESS(status);
    return realLength;
}

inline int toLower(UChar* result, int resultLength, const UChar* src, int srcLength, bool* error)
{
    UErrorCode status = U_ZERO_ERROR;
    int realLength = u_strToLower(result, resultLength, src, srcLength, "", &status);
    *error = !!U_FAILURE(status);
    return realLength;
}

inline UChar32 toLower(UChar32 c)
{
    return u_tolower(c);
}

inline UChar32 toUpper(UChar32 c)
{
    return u_toupper(c);
}

inline int toUpper(UChar* result, int resultLength, const UChar* src, int srcLength, bool* error)
{
    UErrorCode status = U_ZERO_ERROR;
    int realLength = u_strToUpper(result, resultLength, src, srcLength, "", &status);
    *error = !!U_FAILURE(status);
    return realLength;
}

inline UChar32 toTitleCase(UChar32 c)
{
    return u_totitle(c);
}

inline bool isArabicChar(UChar32 c)
{
      return ublock_getCode(c) == UBLOCK_ARABIC;
}

inline bool isAlphanumeric(UChar32 c)
{
    return u_isalnum(c);
}

inline bool isSeparatorSpace(UChar32 c)
{
    return u_charType(c) == U_SPACE_SEPARATOR;
}

inline bool isPrintableChar(UChar32 c)
{
    return !!u_isprint(c);
}

inline bool isPunct(UChar32 c)
{
    return !!u_ispunct(c);
}

inline bool hasLineBreakingPropertyComplexContext(UChar32 c)
{
    return u_getIntPropertyValue(c, UCHAR_LINE_BREAK) == U_LB_COMPLEX_CONTEXT;
}

inline UChar32 mirroredChar(UChar32 c)
{
    return u_charMirror(c);
}

inline CharCategory category(UChar32 c)
{
    return static_cast<CharCategory>(U_GET_GC_MASK(c));
}

inline Direction direction(UChar32 c)
{
    return static_cast<Direction>(u_charDirection(c));
}

inline bool isLower(UChar32 c)
{
    return !!u_islower(c);
}

inline uint8_t combiningClass(UChar32 c)
{
    return u_getCombiningClass(c);
}

inline DecompositionType decompositionType(UChar32 c)
{
    return static_cast<DecompositionType>(u_getIntPropertyValue(c, UCHAR_DECOMPOSITION_TYPE));
}

inline int umemcasecmp(const UChar* a, const UChar* b, int len)
{
    return u_memcasecmp(a, b, len, U_FOLD_CASE_DEFAULT);
}

} // namespace Unicode

} // namespace WTF

#endif // WTF_UNICODE_ICU_H
