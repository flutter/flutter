/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/fonts/Character.h"

#include "platform/fonts/FontPlatformFeatures.h"
#include "wtf/StdLibExtras.h"
#include "wtf/text/StringBuilder.h"

using namespace WTF;
using namespace Unicode;

namespace blink {

static const UChar32 cjkIsolatedSymbolsArray[] = {
    // 0x2C7 Caron, Mandarin Chinese 3rd Tone
    0x2C7,
    // 0x2CA Modifier Letter Acute Accent, Mandarin Chinese 2nd Tone
    0x2CA,
    // 0x2CB Modifier Letter Grave Access, Mandarin Chinese 4th Tone
    0x2CB,
    // 0x2D9 Dot Above, Mandarin Chinese 5th Tone
    0x2D9,
    0x2020, 0x2021, 0x2030, 0x203B, 0x203C, 0x2042, 0x2047, 0x2048, 0x2049, 0x2051,
    0x20DD, 0x20DE, 0x2100, 0x2103, 0x2105, 0x2109, 0x210A, 0x2113, 0x2116, 0x2121,
    0x212B, 0x213B, 0x2150, 0x2151, 0x2152, 0x217F, 0x2189, 0x2307, 0x2312, 0x23CE,
    0x2423, 0x25A0, 0x25A1, 0x25A2, 0x25AA, 0x25AB, 0x25B1, 0x25B2, 0x25B3, 0x25B6,
    0x25B7, 0x25BC, 0x25BD, 0x25C0, 0x25C1, 0x25C6, 0x25C7, 0x25C9, 0x25CB, 0x25CC,
    0x25EF, 0x2605, 0x2606, 0x260E, 0x2616, 0x2617, 0x2640, 0x2642, 0x26A0, 0x26BD,
    0x26BE, 0x2713, 0x271A, 0x273F, 0x2740, 0x2756, 0x2B1A, 0xFE10, 0xFE11, 0xFE12,
    0xFE19, 0xFF1D,
    // Emoji.
    0x1F100
};

// Takes a flattened list of closed intervals
template <class T, size_t size>
bool valueInIntervalList(const T (&intervalList)[size], const T& value)
{
    const T* bound = std::upper_bound(&intervalList[0], &intervalList[size], value);
    if ((bound - intervalList) % 2 == 1)
        return true;
    return bound > intervalList && *(bound - 1) == value;
}

CodePath Character::characterRangeCodePath(const UChar* characters, unsigned len)
{
    static const UChar complexCodePathRanges[] = {
        // U+02E5 through U+02E9 (Modifier Letters : Tone letters)
        0x2E5, 0x2E9,
        // U+0300 through U+036F Combining diacritical marks
        0x300, 0x36F,
        // U+0591 through U+05CF excluding U+05BE Hebrew combining marks, ...
        0x0591, 0x05BD,
        // ... Hebrew punctuation Paseq, Sof Pasuq and Nun Hafukha
        0x05BF, 0x05CF,
        // U+0600 through U+109F Arabic, Syriac, Thaana, NKo, Samaritan, Mandaic,
        // Devanagari, Bengali, Gurmukhi, Gujarati, Oriya, Tamil, Telugu, Kannada,
        // Malayalam, Sinhala, Thai, Lao, Tibetan, Myanmar
        0x0600, 0x109F,
        // U+1100 through U+11FF Hangul Jamo (only Ancient Korean should be left
        // here if you precompose; Modern Korean will be precomposed as a result of step A)
        0x1100, 0x11FF,
        // U+135D through U+135F Ethiopic combining marks
        0x135D, 0x135F,
        // U+1780 through U+18AF Tagalog, Hanunoo, Buhid, Taghanwa,Khmer, Mongolian
        0x1700, 0x18AF,
        // U+1900 through U+194F Limbu (Unicode 4.0)
        0x1900, 0x194F,
        // U+1980 through U+19DF New Tai Lue
        0x1980, 0x19DF,
        // U+1A00 through U+1CFF Buginese, Tai Tham, Balinese, Batak, Lepcha, Vedic
        0x1A00, 0x1CFF,
        // U+1DC0 through U+1DFF Comining diacritical mark supplement
        0x1DC0, 0x1DFF,
        // U+20D0 through U+20FF Combining marks for symbols
        0x20D0, 0x20FF,
        // U+2CEF through U+2CF1 Combining marks for Coptic
        0x2CEF, 0x2CF1,
        // U+302A through U+302F Ideographic and Hangul Tone marks
        0x302A, 0x302F,
        // U+A67C through U+A67D Combining marks for old Cyrillic
        0xA67C, 0xA67D,
        // U+A6F0 through U+A6F1 Combining mark for Bamum
        0xA6F0, 0xA6F1,
        // U+A800 through U+ABFF Nagri, Phags-pa, Saurashtra, Devanagari Extended,
        // Hangul Jamo Ext. A, Javanese, Myanmar Extended A, Tai Viet, Meetei Mayek
        0xA800, 0xABFF,
        // U+D7B0 through U+D7FF Hangul Jamo Ext. B
        0xD7B0, 0xD7FF,
        // U+FE00 through U+FE0F Unicode variation selectors
        0xFE00, 0xFE0F,
        // U+FE20 through U+FE2F Combining half marks
        0xFE20, 0xFE2F
    };

    CodePath result = SimplePath;
    for (unsigned i = 0; i < len; i++) {
        const UChar c = characters[i];

        // Shortcut for common case
        if (c < 0x2E5)
            continue;

        // U+1E00 through U+2000 characters with diacritics and stacked diacritics
        if (c >= 0x1E00 && c <= 0x2000) {
            result = SimpleWithGlyphOverflowPath;
            continue;
        }

        // Surrogate pairs
        if (c > 0xD7FF && c <= 0xDBFF) {
            if (i == len - 1)
                continue;

            UChar next = characters[++i];
            if (!U16_IS_TRAIL(next))
                continue;

            UChar32 supplementaryCharacter = U16_GET_SUPPLEMENTARY(c, next);

            if (supplementaryCharacter < 0x1F1E6) // U+1F1E6 through U+1F1FF Regional Indicator Symbols
                continue;
            if (supplementaryCharacter <= 0x1F1FF)
                return ComplexPath;

            if (supplementaryCharacter < 0xE0100) // U+E0100 through U+E01EF Unicode variation selectors.
                continue;
            if (supplementaryCharacter <= 0xE01EF)
                return ComplexPath;

            // FIXME: Check for Brahmi (U+11000 block), Kaithi (U+11080 block) and other complex scripts
            // in plane 1 or higher.

            continue;
        }

        // Search for other Complex cases
        if (valueInIntervalList(complexCodePathRanges, c))
            return ComplexPath;
    }

    return result;
}

bool Character::isCJKIdeograph(UChar32 c)
{
    static const UChar32 cjkIdeographRanges[] = {
        // CJK Radicals Supplement and Kangxi Radicals.
        0x2E80, 0x2FDF,
        // CJK Strokes.
        0x31C0, 0x31EF,
        // CJK Unified Ideographs Extension A.
        0x3400, 0x4DBF,
        // The basic CJK Unified Ideographs block.
        0x4E00, 0x9FFF,
        // CJK Compatibility Ideographs.
        0xF900, 0xFAFF,
        // CJK Unified Ideographs Extension B.
        0x20000, 0x2A6DF,
        // CJK Unified Ideographs Extension C.
        // CJK Unified Ideographs Extension D.
        0x2A700, 0x2B81F,
        // CJK Compatibility Ideographs Supplement.
        0x2F800, 0x2FA1F
    };
    static size_t cjkIdeographRangesCount = WTF_ARRAY_LENGTH(cjkIdeographRanges);

    // Early out
    if (c < cjkIdeographRanges[0] || c > cjkIdeographRanges[cjkIdeographRangesCount - 1])
        return false;

    return valueInIntervalList(cjkIdeographRanges, c);
}

bool Character::isCJKIdeographOrSymbol(UChar32 c)
{
    // Likely common case
    if (c < 0x2C7)
        return false;

    // Hash lookup for isolated symbols (those not part of a contiguous range)
    static HashSet<UChar32>* cjkIsolatedSymbols = 0;
    if (!cjkIsolatedSymbols) {
        cjkIsolatedSymbols = new HashSet<UChar32>();
        for (size_t i = 0; i < WTF_ARRAY_LENGTH(cjkIsolatedSymbolsArray); ++i)
            cjkIsolatedSymbols->add(cjkIsolatedSymbolsArray[i]);
    }
    if (cjkIsolatedSymbols->contains(c))
        return true;

    if (isCJKIdeograph(c))
        return true;

    static const UChar32 cjkSymbolRanges[] = {
        0x2156, 0x215A,
        0x2160, 0x216B,
        0x2170, 0x217B,
        0x23BE, 0x23CC,
        0x2460, 0x2492,
        0x249C, 0x24FF,
        0x25CE, 0x25D3,
        0x25E2, 0x25E6,
        0x2600, 0x2603,
        0x2660, 0x266F,
        0x2672, 0x267D,
        0x2776, 0x277F,
        // Ideographic Description Characters, with CJK Symbols and Punctuation, excluding 0x3030.
        // Then Hiragana 0x3040 .. 0x309F, Katakana 0x30A0 .. 0x30FF, Bopomofo 0x3100 .. 0x312F
        0x2FF0, 0x302F,
        0x3031, 0x312F,
        // More Bopomofo and Bopomofo Extended 0x31A0 .. 0x31BF
        0x3190, 0x31BF,
        // Enclosed CJK Letters and Months (0x3200 .. 0x32FF).
        // CJK Compatibility (0x3300 .. 0x33FF).
        0x3200, 0x33FF,
        0xF860, 0xF862,
        // CJK Compatibility Forms.
        0xFE30, 0xFE4F,
        // Halfwidth and Fullwidth Forms
        // Usually only used in CJK
        0xFF00, 0xFF0C,
        0xFF0E, 0xFF1A,
        0xFF1F, 0xFFEF,
        // Emoji.
        0x1F110, 0x1F129,
        0x1F130, 0x1F149,
        0x1F150, 0x1F169,
        0x1F170, 0x1F189,
        0x1F200, 0x1F6FF
    };

    return valueInIntervalList(cjkSymbolRanges, c);
}

unsigned Character::expansionOpportunityCount(const LChar* characters, size_t length, TextDirection direction, bool& isAfterExpansion)
{
    unsigned count = 0;
    if (direction == LTR) {
        for (size_t i = 0; i < length; ++i) {
            if (treatAsSpace(characters[i])) {
                count++;
                isAfterExpansion = true;
            } else {
                isAfterExpansion = false;
            }
        }
    } else {
        for (size_t i = length; i > 0; --i) {
            if (treatAsSpace(characters[i - 1])) {
                count++;
                isAfterExpansion = true;
            } else {
                isAfterExpansion = false;
            }
        }
    }
    return count;
}

unsigned Character::expansionOpportunityCount(const UChar* characters, size_t length, TextDirection direction, bool& isAfterExpansion)
{
    static bool expandAroundIdeographs = FontPlatformFeatures::canExpandAroundIdeographsInComplexText();
    unsigned count = 0;
    if (direction == LTR) {
        for (size_t i = 0; i < length; ++i) {
            UChar32 character = characters[i];
            if (treatAsSpace(character)) {
                count++;
                isAfterExpansion = true;
                continue;
            }
            if (U16_IS_LEAD(character) && i + 1 < length && U16_IS_TRAIL(characters[i + 1])) {
                character = U16_GET_SUPPLEMENTARY(character, characters[i + 1]);
                i++;
            }
            if (expandAroundIdeographs && isCJKIdeographOrSymbol(character)) {
                if (!isAfterExpansion)
                    count++;
                count++;
                isAfterExpansion = true;
                continue;
            }
            isAfterExpansion = false;
        }
    } else {
        for (size_t i = length; i > 0; --i) {
            UChar32 character = characters[i - 1];
            if (treatAsSpace(character)) {
                count++;
                isAfterExpansion = true;
                continue;
            }
            if (U16_IS_TRAIL(character) && i > 1 && U16_IS_LEAD(characters[i - 2])) {
                character = U16_GET_SUPPLEMENTARY(characters[i - 2], character);
                i--;
            }
            if (expandAroundIdeographs && isCJKIdeographOrSymbol(character)) {
                if (!isAfterExpansion)
                    count++;
                count++;
                isAfterExpansion = true;
                continue;
            }
            isAfterExpansion = false;
        }
    }
    return count;
}

bool Character::canReceiveTextEmphasis(UChar32 c)
{
    CharCategory category = Unicode::category(c);
    if (category & (Separator_Space | Separator_Line | Separator_Paragraph | Other_NotAssigned | Other_Control | Other_Format))
        return false;

    // Additional word-separator characters listed in CSS Text Level 3 Editor's Draft 3 November 2010.
    if (c == ethiopicWordspace || c == aegeanWordSeparatorLine || c == aegeanWordSeparatorDot
        || c == ugariticWordDivider || c == tibetanMarkIntersyllabicTsheg || c == tibetanMarkDelimiterTshegBstar)
        return false;

    return true;
}

template <typename CharacterType>
static inline String normalizeSpacesInternal(const CharacterType* characters, unsigned length)
{
    StringBuilder normalized;
    normalized.reserveCapacity(length);

    for (unsigned i = 0; i < length; ++i)
        normalized.append(Character::normalizeSpaces(characters[i]));

    return normalized.toString();
}

String Character::normalizeSpaces(const LChar* characters, unsigned length)
{
    return normalizeSpacesInternal(characters, length);
}

String Character::normalizeSpaces(const UChar* characters, unsigned length)
{
    return normalizeSpacesInternal(characters, length);
}

} // namespace blink
