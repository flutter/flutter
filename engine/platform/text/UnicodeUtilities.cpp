/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2005 Alexey Proskuryakov.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/text/UnicodeUtilities.h"

#include "wtf/text/StringBuffer.h"
#include "wtf/unicode/CharacterNames.h"
#include <unicode/unorm.h>

using namespace WTF::Unicode;

namespace blink {

enum VoicedSoundMarkType {
    NoVoicedSoundMark,
    VoicedSoundMark,
    SemiVoicedSoundMark
};

template <typename CharType>
static inline CharType foldQuoteMarkOrSoftHyphen(CharType c)
{
    switch (static_cast<UChar>(c)) {
    case hebrewPunctuationGershayim:
    case leftDoubleQuotationMark:
    case rightDoubleQuotationMark:
        return '"';
    case hebrewPunctuationGeresh:
    case leftSingleQuotationMark:
    case rightSingleQuotationMark:
        return '\'';
    case softHyphen:
        // Replace soft hyphen with an ignorable character so that their presence or absence will
        // not affect string comparison.
        return 0;
    default:
        return c;
    }
}

void foldQuoteMarksAndSoftHyphens(UChar* data, size_t length)
{
    for (size_t i = 0; i < length; ++i)
        data[i] = foldQuoteMarkOrSoftHyphen(data[i]);
}

void foldQuoteMarksAndSoftHyphens(String& s)
{
    s.replace(hebrewPunctuationGeresh, '\'');
    s.replace(hebrewPunctuationGershayim, '"');
    s.replace(leftDoubleQuotationMark, '"');
    s.replace(leftSingleQuotationMark, '\'');
    s.replace(rightDoubleQuotationMark, '"');
    s.replace(rightSingleQuotationMark, '\'');
    // Replace soft hyphen with an ignorable character so that their presence or absence will
    // not affect string comparison.
    s.replace(softHyphen, 0);
}

static bool isNonLatin1Separator(UChar32 character)
{
    ASSERT_ARG(character, character >= 256);

    return U_GET_GC_MASK(character) & (U_GC_S_MASK | U_GC_P_MASK | U_GC_Z_MASK | U_GC_CF_MASK);
}

bool isSeparator(UChar32 character)
{
    static const bool latin1SeparatorTable[256] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, // space ! " # $ % & ' ( ) * + , - . /
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, //                         : ; < = > ?
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //   @
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, //                         [ \ ] ^ _
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //   `
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, //                           { | } ~
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };

    if (character < 256)
        return latin1SeparatorTable[character];

    return isNonLatin1Separator(character);
}

// ICU's search ignores the distinction between small kana letters and ones
// that are not small, and also characters that differ only in the voicing
// marks when considering only primary collation strength differences.
// This is not helpful for end users, since these differences make words
// distinct, so for our purposes we need these to be considered.
// The Unicode folks do not think the collation algorithm should be
// changed. To work around this, we would like to tailor the ICU searcher,
// but we can't get that to work yet. So instead, we check for cases where
// these differences occur, and skip those matches.

// We refer to the above technique as the "kana workaround". The next few
// functions are helper functinos for the kana workaround.

bool isKanaLetter(UChar character)
{
    // Hiragana letters.
    if (character >= 0x3041 && character <= 0x3096)
        return true;

    // Katakana letters.
    if (character >= 0x30A1 && character <= 0x30FA)
        return true;
    if (character >= 0x31F0 && character <= 0x31FF)
        return true;

    // Halfwidth katakana letters.
    if (character >= 0xFF66 && character <= 0xFF9D && character != 0xFF70)
        return true;

    return false;
}

bool isSmallKanaLetter(UChar character)
{
    ASSERT(isKanaLetter(character));

    switch (character) {
    case 0x3041: // HIRAGANA LETTER SMALL A
    case 0x3043: // HIRAGANA LETTER SMALL I
    case 0x3045: // HIRAGANA LETTER SMALL U
    case 0x3047: // HIRAGANA LETTER SMALL E
    case 0x3049: // HIRAGANA LETTER SMALL O
    case 0x3063: // HIRAGANA LETTER SMALL TU
    case 0x3083: // HIRAGANA LETTER SMALL YA
    case 0x3085: // HIRAGANA LETTER SMALL YU
    case 0x3087: // HIRAGANA LETTER SMALL YO
    case 0x308E: // HIRAGANA LETTER SMALL WA
    case 0x3095: // HIRAGANA LETTER SMALL KA
    case 0x3096: // HIRAGANA LETTER SMALL KE
    case 0x30A1: // KATAKANA LETTER SMALL A
    case 0x30A3: // KATAKANA LETTER SMALL I
    case 0x30A5: // KATAKANA LETTER SMALL U
    case 0x30A7: // KATAKANA LETTER SMALL E
    case 0x30A9: // KATAKANA LETTER SMALL O
    case 0x30C3: // KATAKANA LETTER SMALL TU
    case 0x30E3: // KATAKANA LETTER SMALL YA
    case 0x30E5: // KATAKANA LETTER SMALL YU
    case 0x30E7: // KATAKANA LETTER SMALL YO
    case 0x30EE: // KATAKANA LETTER SMALL WA
    case 0x30F5: // KATAKANA LETTER SMALL KA
    case 0x30F6: // KATAKANA LETTER SMALL KE
    case 0x31F0: // KATAKANA LETTER SMALL KU
    case 0x31F1: // KATAKANA LETTER SMALL SI
    case 0x31F2: // KATAKANA LETTER SMALL SU
    case 0x31F3: // KATAKANA LETTER SMALL TO
    case 0x31F4: // KATAKANA LETTER SMALL NU
    case 0x31F5: // KATAKANA LETTER SMALL HA
    case 0x31F6: // KATAKANA LETTER SMALL HI
    case 0x31F7: // KATAKANA LETTER SMALL HU
    case 0x31F8: // KATAKANA LETTER SMALL HE
    case 0x31F9: // KATAKANA LETTER SMALL HO
    case 0x31FA: // KATAKANA LETTER SMALL MU
    case 0x31FB: // KATAKANA LETTER SMALL RA
    case 0x31FC: // KATAKANA LETTER SMALL RI
    case 0x31FD: // KATAKANA LETTER SMALL RU
    case 0x31FE: // KATAKANA LETTER SMALL RE
    case 0x31FF: // KATAKANA LETTER SMALL RO
    case 0xFF67: // HALFWIDTH KATAKANA LETTER SMALL A
    case 0xFF68: // HALFWIDTH KATAKANA LETTER SMALL I
    case 0xFF69: // HALFWIDTH KATAKANA LETTER SMALL U
    case 0xFF6A: // HALFWIDTH KATAKANA LETTER SMALL E
    case 0xFF6B: // HALFWIDTH KATAKANA LETTER SMALL O
    case 0xFF6C: // HALFWIDTH KATAKANA LETTER SMALL YA
    case 0xFF6D: // HALFWIDTH KATAKANA LETTER SMALL YU
    case 0xFF6E: // HALFWIDTH KATAKANA LETTER SMALL YO
    case 0xFF6F: // HALFWIDTH KATAKANA LETTER SMALL TU
        return true;
    }
    return false;
}

static inline VoicedSoundMarkType composedVoicedSoundMark(UChar character)
{
    ASSERT(isKanaLetter(character));

    switch (character) {
    case 0x304C: // HIRAGANA LETTER GA
    case 0x304E: // HIRAGANA LETTER GI
    case 0x3050: // HIRAGANA LETTER GU
    case 0x3052: // HIRAGANA LETTER GE
    case 0x3054: // HIRAGANA LETTER GO
    case 0x3056: // HIRAGANA LETTER ZA
    case 0x3058: // HIRAGANA LETTER ZI
    case 0x305A: // HIRAGANA LETTER ZU
    case 0x305C: // HIRAGANA LETTER ZE
    case 0x305E: // HIRAGANA LETTER ZO
    case 0x3060: // HIRAGANA LETTER DA
    case 0x3062: // HIRAGANA LETTER DI
    case 0x3065: // HIRAGANA LETTER DU
    case 0x3067: // HIRAGANA LETTER DE
    case 0x3069: // HIRAGANA LETTER DO
    case 0x3070: // HIRAGANA LETTER BA
    case 0x3073: // HIRAGANA LETTER BI
    case 0x3076: // HIRAGANA LETTER BU
    case 0x3079: // HIRAGANA LETTER BE
    case 0x307C: // HIRAGANA LETTER BO
    case 0x3094: // HIRAGANA LETTER VU
    case 0x30AC: // KATAKANA LETTER GA
    case 0x30AE: // KATAKANA LETTER GI
    case 0x30B0: // KATAKANA LETTER GU
    case 0x30B2: // KATAKANA LETTER GE
    case 0x30B4: // KATAKANA LETTER GO
    case 0x30B6: // KATAKANA LETTER ZA
    case 0x30B8: // KATAKANA LETTER ZI
    case 0x30BA: // KATAKANA LETTER ZU
    case 0x30BC: // KATAKANA LETTER ZE
    case 0x30BE: // KATAKANA LETTER ZO
    case 0x30C0: // KATAKANA LETTER DA
    case 0x30C2: // KATAKANA LETTER DI
    case 0x30C5: // KATAKANA LETTER DU
    case 0x30C7: // KATAKANA LETTER DE
    case 0x30C9: // KATAKANA LETTER DO
    case 0x30D0: // KATAKANA LETTER BA
    case 0x30D3: // KATAKANA LETTER BI
    case 0x30D6: // KATAKANA LETTER BU
    case 0x30D9: // KATAKANA LETTER BE
    case 0x30DC: // KATAKANA LETTER BO
    case 0x30F4: // KATAKANA LETTER VU
    case 0x30F7: // KATAKANA LETTER VA
    case 0x30F8: // KATAKANA LETTER VI
    case 0x30F9: // KATAKANA LETTER VE
    case 0x30FA: // KATAKANA LETTER VO
        return VoicedSoundMark;
    case 0x3071: // HIRAGANA LETTER PA
    case 0x3074: // HIRAGANA LETTER PI
    case 0x3077: // HIRAGANA LETTER PU
    case 0x307A: // HIRAGANA LETTER PE
    case 0x307D: // HIRAGANA LETTER PO
    case 0x30D1: // KATAKANA LETTER PA
    case 0x30D4: // KATAKANA LETTER PI
    case 0x30D7: // KATAKANA LETTER PU
    case 0x30DA: // KATAKANA LETTER PE
    case 0x30DD: // KATAKANA LETTER PO
        return SemiVoicedSoundMark;
    }
    return NoVoicedSoundMark;
}

static inline bool isCombiningVoicedSoundMark(UChar character)
{
    switch (character) {
    case 0x3099: // COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK
    case 0x309A: // COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
        return true;
    }
    return false;
}

bool containsKanaLetters(const String& pattern)
{
    const unsigned length = pattern.length();
    for (unsigned i = 0; i < length; ++i) {
        if (isKanaLetter(pattern[i]))
            return true;
    }
    return false;
}

void normalizeCharactersIntoNFCForm(const UChar* characters, unsigned length, Vector<UChar>& buffer)
{
    ASSERT(length);

    buffer.resize(length);

    UErrorCode status = U_ZERO_ERROR;
    size_t bufferSize = unorm_normalize(characters, length, UNORM_NFC, 0, buffer.data(), length, &status);
    ASSERT(status == U_ZERO_ERROR || status == U_STRING_NOT_TERMINATED_WARNING || status == U_BUFFER_OVERFLOW_ERROR);
    ASSERT(bufferSize);

    buffer.resize(bufferSize);

    if (status == U_ZERO_ERROR || status == U_STRING_NOT_TERMINATED_WARNING)
        return;

    status = U_ZERO_ERROR;
    unorm_normalize(characters, length, UNORM_NFC, 0, buffer.data(), bufferSize, &status);
    ASSERT(status == U_STRING_NOT_TERMINATED_WARNING);
}

// This function returns kNotFound if |first| and |second| contain different Kana letters.
// If |first| and |second| contain the same Kana letter
// then function returns offset in characters from |first|.
// Pointers to both strings increase simultaneously so so it is possible to use one offset value.
static inline size_t compareKanaLetterAndComposedVoicedSoundMarks(const UChar* first, const UChar* firstEnd, const UChar* second, const UChar* secondEnd)
{
    const UChar* start = first;
    // Check for differences in the kana letter character itself.
    if (isSmallKanaLetter(*first) != isSmallKanaLetter(*second))
        return kNotFound;
    if (composedVoicedSoundMark(*first) != composedVoicedSoundMark(*second))
        return kNotFound;
    ++first;
    ++second;

    // Check for differences in combining voiced sound marks found after the letter.
    while (true) {
        const bool secondIsNotSoundMark = second == secondEnd || !isCombiningVoicedSoundMark(*second);
        if (first == firstEnd || !isCombiningVoicedSoundMark(*first)) {
            return secondIsNotSoundMark ? first - start : kNotFound;
        }
        if (secondIsNotSoundMark)
            return kNotFound;
        if (*first != *second)
            return kNotFound;
        ++first;
        ++second;
    }
}

bool checkOnlyKanaLettersInStrings(const UChar* firstData, unsigned firstLength, const UChar* secondData, unsigned secondLength)
{
    const UChar* a = firstData;
    const UChar* aEnd = firstData + firstLength;

    const UChar* b = secondData;
    const UChar* bEnd = secondData + secondLength;
    while (true) {
        // Skip runs of non-kana-letter characters. This is necessary so we can
        // correctly handle strings where the |firstData| and |secondData| have different-length
        // runs of characters that match, while still double checking the correctness
        // of matches of kana letters with other kana letters.
        while (a != aEnd && !isKanaLetter(*a))
            ++a;
        while (b != bEnd && !isKanaLetter(*b))
            ++b;

        // If we reached the end of either the target or the match, we should have
        // reached the end of both; both should have the same number of kana letters.
        if (a == aEnd || b == bEnd) {
            return a == aEnd && b == bEnd;
        }

        // Check that single Kana letters in |a| and |b| are the same.
        const size_t offset = compareKanaLetterAndComposedVoicedSoundMarks(a, aEnd, b, bEnd);
        if (offset == kNotFound)
            return false;

        // Update values of |a| and |b| after comparing.
        a += offset;
        b += offset;
    }
}

bool checkKanaStringsEqual(const UChar* firstData, unsigned firstLength, const UChar* secondData, unsigned secondLength)
{
    const UChar* a = firstData;
    const UChar* aEnd = firstData + firstLength;

    const UChar* b = secondData;
    const UChar* bEnd = secondData + secondLength;
    while (true) {
        // Check for non-kana-letter characters.
        while (a != aEnd && !isKanaLetter(*a) && b != bEnd && !isKanaLetter(*b)) {
            if (*a++ != *b++)
                return false;
        }

        // If we reached the end of either the target or the match, we should have
        // reached the end of both; both should have the same number of kana letters.
        if (a == aEnd || b == bEnd) {
            return a == aEnd && b == bEnd;
        }

        if (isKanaLetter(*a) != isKanaLetter(*b))
            return false;

        // Check that single Kana letters in |a| and |b| are the same.
        const size_t offset = compareKanaLetterAndComposedVoicedSoundMarks(a, aEnd, b, bEnd);
        if (offset == kNotFound)
            return false;

        // Update values of |a| and |b| after comparing.
        a += offset;
        b += offset;
    }
}

}
