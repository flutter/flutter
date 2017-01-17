/*
 * Copyright (C) 2013 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// #define VERBOSE_DEBUG

#define LOG_TAG "Minikin"

#include <algorithm>

#include <log/log.h>
#include "unicode/unistr.h"
#include "unicode/unorm2.h"

#include "FontLanguage.h"
#include "FontLanguageListCache.h"
#include "MinikinInternal.h"
#include <minikin/FontCollection.h>

using std::vector;

namespace minikin {

template <typename T>
static inline T max(T a, T b) {
    return a>b ? a : b;
}

const uint32_t EMOJI_STYLE_VS = 0xFE0F;
const uint32_t TEXT_STYLE_VS = 0xFE0E;

// See http://www.unicode.org/Public/9.0.0/ucd/StandardizedVariants.txt
// U+2640, U+2642, U+2695 are now in emoji category but not listed in above file, so added them by
// manual.
// Must be sorted.
const uint32_t EMOJI_STYLE_VS_BASES[] = {
    0x0023, 0x002A, 0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037, 0x0038, 0x0039,
    0x00A9, 0x00AE, 0x203C, 0x2049, 0x2122, 0x2139, 0x2194, 0x2195, 0x2196, 0x2197, 0x2198, 0x2199,
    0x21A9, 0x21AA, 0x231A, 0x231B, 0x2328, 0x23CF, 0x23ED, 0x23EE, 0x23EF, 0x23F1, 0x23F2, 0x23F8,
    0x23F9, 0x23FA, 0x24C2, 0x25AA, 0x25AB, 0x25B6, 0x25C0, 0x25FB, 0x25FC, 0x25FD, 0x25FE, 0x2600,
    0x2601, 0x2602, 0x2603, 0x2604, 0x260E, 0x2611, 0x2614, 0x2615, 0x2618, 0x261D, 0x2620, 0x2622,
    0x2623, 0x2626, 0x262A, 0x262E, 0x262F, 0x2638, 0x2639, 0x263A, 0x2640, 0x2642, 0x2648, 0x2649,
    0x264A, 0x264B, 0x264C, 0x264D, 0x264E, 0x264F, 0x2650, 0x2651, 0x2652, 0x2653, 0x2660, 0x2663,
    0x2665, 0x2666, 0x2668, 0x267B, 0x267F, 0x2692, 0x2693, 0x2694, 0x2695, 0x2696, 0x2697, 0x2699,
    0x269B, 0x269C, 0x26A0, 0x26A1, 0x26AA, 0x26AB, 0x26B0, 0x26B1, 0x26BD, 0x26BE, 0x26C4, 0x26C5,
    0x26C8, 0x26CF, 0x26D1, 0x26D3, 0x26D4, 0x26E9, 0x26EA, 0x26F0, 0x26F1, 0x26F2, 0x26F3, 0x26F4,
    0x26F5, 0x26F7, 0x26F8, 0x26F9, 0x26FA, 0x26FD, 0x2702, 0x2708, 0x2709, 0x270C, 0x270D, 0x270F,
    0x2712, 0x2714, 0x2716, 0x271D, 0x2721, 0x2733, 0x2734, 0x2744, 0x2747, 0x2757, 0x2763, 0x2764,
    0x27A1, 0x2934, 0x2935, 0x2B05, 0x2B06, 0x2B07, 0x2B1B, 0x2B1C, 0x2B50, 0x2B55, 0x3030, 0x303D,
    0x3297, 0x3299, 0x1F004, 0x1F170, 0x1F171, 0x1F17E, 0x1F17F, 0x1F202, 0x1F21A, 0x1F22F, 0x1F237,
    0x1F321, 0x1F324, 0x1F325, 0x1F326, 0x1F327, 0x1F328, 0x1F329, 0x1F32A, 0x1F32B, 0x1F32C,
    0x1F336, 0x1F37D, 0x1F396, 0x1F397, 0x1F399, 0x1F39A, 0x1F39B, 0x1F39E, 0x1F39F, 0x1F3CB,
    0x1F3CC, 0x1F3CD, 0x1F3CE, 0x1F3D4, 0x1F3D5, 0x1F3D6, 0x1F3D7, 0x1F3D8, 0x1F3D9, 0x1F3DA,
    0x1F3DB, 0x1F3DC, 0x1F3DD, 0x1F3DE, 0x1F3DF, 0x1F3F3, 0x1F3F5, 0x1F3F7, 0x1F43F, 0x1F441,
    0x1F4FD, 0x1F549, 0x1F54A, 0x1F56F, 0x1F570, 0x1F573, 0x1F574, 0x1F575, 0x1F576, 0x1F577,
    0x1F578, 0x1F579, 0x1F587, 0x1F58A, 0x1F58B, 0x1F58C, 0x1F58D, 0x1F590, 0x1F5A5, 0x1F5A8,
    0x1F5B1, 0x1F5B2, 0x1F5BC, 0x1F5C2, 0x1F5C3, 0x1F5C4, 0x1F5D1, 0x1F5D2, 0x1F5D3, 0x1F5DC,
    0x1F5DD, 0x1F5DE, 0x1F5E1, 0x1F5E3, 0x1F5E8, 0x1F5EF, 0x1F5F3, 0x1F5FA, 0x1F6CB, 0x1F6CD,
    0x1F6CE, 0x1F6CF, 0x1F6E0, 0x1F6E1, 0x1F6E2, 0x1F6E3, 0x1F6E4, 0x1F6E5, 0x1F6E9, 0x1F6F0,
    0x1F6F3,
};

static bool isEmojiStyleVSBase(uint32_t cp) {
    const size_t length = sizeof(EMOJI_STYLE_VS_BASES) / sizeof(EMOJI_STYLE_VS_BASES[0]);
    return std::binary_search(EMOJI_STYLE_VS_BASES, EMOJI_STYLE_VS_BASES + length, cp);
}

uint32_t FontCollection::sNextId = 0;

FontCollection::FontCollection(std::shared_ptr<FontFamily>&& typeface) : mMaxChar(0) {
    std::vector<std::shared_ptr<FontFamily>> typefaces;
    typefaces.push_back(typeface);
    init(typefaces);
}

FontCollection::FontCollection(const vector<std::shared_ptr<FontFamily>>& typefaces) :
    mMaxChar(0) {
    init(typefaces);
}

void FontCollection::init(const vector<std::shared_ptr<FontFamily>>& typefaces) {
    android::AutoMutex _l(gMinikinLock);
    mId = sNextId++;
    vector<uint32_t> lastChar;
    size_t nTypefaces = typefaces.size();
#ifdef VERBOSE_DEBUG
    ALOGD("nTypefaces = %zd\n", nTypefaces);
#endif
    const FontStyle defaultStyle;
    for (size_t i = 0; i < nTypefaces; i++) {
        const std::shared_ptr<FontFamily>& family = typefaces[i];
        if (family->getClosestMatch(defaultStyle).font == nullptr) {
            continue;
        }
        const SparseBitSet& coverage = family->getCoverage();
        mFamilies.push_back(family);  // emplace_back would be better
        if (family->hasVSTable()) {
            mVSFamilyVec.push_back(family);
        }
        mMaxChar = max(mMaxChar, coverage.length());
        lastChar.push_back(coverage.nextSetBit(0));

        const std::unordered_set<AxisTag>& supportedAxes = family->supportedAxes();
        mSupportedAxes.insert(supportedAxes.begin(), supportedAxes.end());
    }
    nTypefaces = mFamilies.size();
    LOG_ALWAYS_FATAL_IF(nTypefaces == 0,
        "Font collection must have at least one valid typeface");
    LOG_ALWAYS_FATAL_IF(nTypefaces > 254,
        "Font collection may only have up to 254 font families.");
    size_t nPages = (mMaxChar + kPageMask) >> kLogCharsPerPage;
    // TODO: Use variation selector map for mRanges construction.
    // A font can have a glyph for a base code point and variation selector pair but no glyph for
    // the base code point without variation selector. The family won't be listed in the range in
    // this case.
    for (size_t i = 0; i < nPages; i++) {
        Range dummy;
        mRanges.push_back(dummy);
        Range* range = &mRanges.back();
#ifdef VERBOSE_DEBUG
        ALOGD("i=%zd: range start = %zd\n", i, offset);
#endif
        range->start = mFamilyVec.size();
        for (size_t j = 0; j < nTypefaces; j++) {
            if (lastChar[j] < (i + 1) << kLogCharsPerPage) {
                const std::shared_ptr<FontFamily>& family = mFamilies[j];
                mFamilyVec.push_back(static_cast<uint8_t>(j));
                uint32_t nextChar = family->getCoverage().nextSetBit((i + 1) << kLogCharsPerPage);
#ifdef VERBOSE_DEBUG
                ALOGD("nextChar = %d (j = %zd)\n", nextChar, j);
#endif
                lastChar[j] = nextChar;
            }
        }
        range->end = mFamilyVec.size();
    }
    // See the comment in Range for more details.
    LOG_ALWAYS_FATAL_IF(mFamilyVec.size() >= 0xFFFF,
        "Exceeded the maximum indexable cmap coverage.");
}

// Special scores for the font fallback.
const uint32_t kUnsupportedFontScore = 0;
const uint32_t kFirstFontScore = UINT32_MAX;

// Calculates a font score.
// The score of the font family is based on three subscores.
//  - Coverage Score: How well the font family covers the given character or variation sequence.
//  - Language Score: How well the font family is appropriate for the language.
//  - Variant Score: Whether the font family matches the variant. Note that this variant is not the
//    one in BCP47. This is our own font variant (e.g., elegant, compact).
//
// Then, there is a priority for these three subscores as follow:
//   Coverage Score > Language Score > Variant Score
// The returned score reflects this priority order.
//
// Note that there are two special scores.
//  - kUnsupportedFontScore: When the font family doesn't support the variation sequence or even its
//    base character.
//  - kFirstFontScore: When the font is the first font family in the collection and it supports the
//    given character or variation sequence.
uint32_t FontCollection::calcFamilyScore(uint32_t ch, uint32_t vs, int variant, uint32_t langListId,
        const std::shared_ptr<FontFamily>& fontFamily) const {

    const uint32_t coverageScore = calcCoverageScore(ch, vs, fontFamily);
    if (coverageScore == kFirstFontScore || coverageScore == kUnsupportedFontScore) {
        // No need to calculate other scores.
        return coverageScore;
    }

    const uint32_t languageScore = calcLanguageMatchingScore(langListId, *fontFamily);
    const uint32_t variantScore = calcVariantMatchingScore(variant, *fontFamily);

    // Subscores are encoded into 31 bits representation to meet the subscore priority.
    // The highest 2 bits are for coverage score, then following 28 bits are for language score,
    // then the last 1 bit is for variant score.
    return coverageScore << 29 | languageScore << 1 | variantScore;
}

// Calculates a font score based on variation sequence coverage.
// - Returns kUnsupportedFontScore if the font doesn't support the variation sequence or its base
//   character.
// - Returns kFirstFontScore if the font family is the first font family in the collection and it
//   supports the given character or variation sequence.
// - Returns 3 if the font family supports the variation sequence.
// - Returns 2 if the vs is a color variation selector (U+FE0F) and if the font is an emoji font.
// - Returns 2 if the vs is a text variation selector (U+FE0E) and if the font is not an emoji font.
// - Returns 1 if the variation selector is not specified or if the font family only supports the
//   variation sequence's base character.
uint32_t FontCollection::calcCoverageScore(uint32_t ch, uint32_t vs,
        const std::shared_ptr<FontFamily>& fontFamily) const {
    const bool hasVSGlyph = (vs != 0) && fontFamily->hasGlyph(ch, vs);
    if (!hasVSGlyph && !fontFamily->getCoverage().get(ch)) {
        // The font doesn't support either variation sequence or even the base character.
        return kUnsupportedFontScore;
    }

    if ((vs == 0 || hasVSGlyph) && mFamilies[0] == fontFamily) {
        // If the first font family supports the given character or variation sequence, always use
        // it.
        return kFirstFontScore;
    }

    if (vs == 0) {
        return 1;
    }

    if (hasVSGlyph) {
        return 3;
    }

    if (vs == EMOJI_STYLE_VS || vs == TEXT_STYLE_VS) {
        const FontLanguages& langs = FontLanguageListCache::getById(fontFamily->langId());
        bool hasEmojiFlag = false;
        for (size_t i = 0; i < langs.size(); ++i) {
            if (langs[i].getEmojiStyle() == FontLanguage::EMSTYLE_EMOJI) {
                hasEmojiFlag = true;
                break;
            }
        }

        if (vs == EMOJI_STYLE_VS) {
            return hasEmojiFlag ? 2 : 1;
        } else {  // vs == TEXT_STYLE_VS
            return hasEmojiFlag ? 1 : 2;
        }
    }
    return 1;
}

// Calculate font scores based on the script matching, subtag matching and primary langauge matching.
//
// 1. If only the font's language matches or there is no matches between requested font and
//    supported font, then the font obtains a score of 0.
// 2. Without a match in language, considering subtag may change font's EmojiStyle over script,
//    a match in subtag gets a score of 2 and a match in scripts gains a score of 1.
// 3. Regarding to two elements matchings, language-and-subtag matching has a score of 4, while
//    language-and-script obtains a socre of 3 with the same reason above.
//
// If two languages in the requested list have the same language score, the font matching with
// higher priority language gets a higher score. For example, in the case the user requested
// language list is "ja-Jpan,en-Latn". The score of for the font of "ja-Jpan" gets a higher score
// than the font of "en-Latn".
//
// To achieve score calculation with priorities, the language score is determined as follows:
//   LanguageScore = s(0) * 5^(m - 1) + s(1) * 5^(m - 2) + ... + s(m - 2) * 5 + s(m - 1)
// Here, m is the maximum number of languages to be compared, and s(i) is the i-th language's
// matching score. The possible values of s(i) are 0, 1, 2, 3 and 4.
uint32_t FontCollection::calcLanguageMatchingScore(
        uint32_t userLangListId, const FontFamily& fontFamily) {
    const FontLanguages& langList = FontLanguageListCache::getById(userLangListId);
    const FontLanguages& fontLanguages = FontLanguageListCache::getById(fontFamily.langId());

    const size_t maxCompareNum = std::min(langList.size(), FONT_LANGUAGES_LIMIT);
    uint32_t score = 0;
    for (size_t i = 0; i < maxCompareNum; ++i) {
        score = score * 5u + langList[i].calcScoreFor(fontLanguages);
    }
    return score;
}

// Calculates a font score based on variant ("compact" or "elegant") matching.
//  - Returns 1 if the font doesn't have variant or the variant matches with the text style.
//  - No score if the font has a variant but it doesn't match with the text style.
uint32_t FontCollection::calcVariantMatchingScore(int variant, const FontFamily& fontFamily) {
    return (fontFamily.variant() == 0 || fontFamily.variant() == variant) ? 1 : 0;
}

// Implement heuristic for choosing best-match font. Here are the rules:
// 1. If first font in the collection has the character, it wins.
// 2. Calculate a score for the font family. See comments in calcFamilyScore for the detail.
// 3. Highest score wins, with ties resolved to the first font.
// This method never returns nullptr.
const std::shared_ptr<FontFamily>& FontCollection::getFamilyForChar(uint32_t ch, uint32_t vs,
            uint32_t langListId, int variant) const {
    if (ch >= mMaxChar) {
        return mFamilies[0];
    }

    Range range = mRanges[ch >> kLogCharsPerPage];

    if (vs != 0) {
        range = { 0, static_cast<uint16_t>(mFamilies.size()) };
    }

#ifdef VERBOSE_DEBUG
    ALOGD("querying range %zd:%zd\n", range.start, range.end);
#endif
    int bestFamilyIndex = -1;
    uint32_t bestScore = kUnsupportedFontScore;
    for (size_t i = range.start; i < range.end; i++) {
        const std::shared_ptr<FontFamily>& family =
                vs == 0 ? mFamilies[mFamilyVec[i]] : mFamilies[i];
        const uint32_t score = calcFamilyScore(ch, vs, variant, langListId, family);
        if (score == kFirstFontScore) {
            // If the first font family supports the given character or variation sequence, always
            // use it.
            return family;
        }
        if (score > bestScore) {
            bestScore = score;
            bestFamilyIndex = i;
        }
    }
    if (bestFamilyIndex == -1) {
        UErrorCode errorCode = U_ZERO_ERROR;
        const UNormalizer2* normalizer = unorm2_getNFDInstance(&errorCode);
        if (U_SUCCESS(errorCode)) {
            UChar decomposed[4];
            int len = unorm2_getRawDecomposition(normalizer, ch, decomposed, 4, &errorCode);
            if (U_SUCCESS(errorCode) && len > 0) {
                int off = 0;
                U16_NEXT_UNSAFE(decomposed, off, ch);
                return getFamilyForChar(ch, vs, langListId, variant);
            }
        }
        return mFamilies[0];
    }
    return vs == 0 ? mFamilies[mFamilyVec[bestFamilyIndex]] : mFamilies[bestFamilyIndex];
}

const uint32_t NBSP = 0x00A0;
const uint32_t SOFT_HYPHEN = 0x00AD;
const uint32_t ZWJ = 0x200C;
const uint32_t ZWNJ = 0x200D;
const uint32_t HYPHEN = 0x2010;
const uint32_t NB_HYPHEN = 0x2011;
const uint32_t NNBSP = 0x202F;
const uint32_t FEMALE_SIGN = 0x2640;
const uint32_t MALE_SIGN = 0x2642;
const uint32_t STAFF_OF_AESCULAPIUS = 0x2695;

// Characters where we want to continue using existing font run instead of
// recomputing the best match in the fallback list.
static const uint32_t stickyWhitelist[] = {
        '!', ',', '-', '.', ':', ';', '?', NBSP, ZWJ, ZWNJ,
        HYPHEN, NB_HYPHEN, NNBSP, FEMALE_SIGN, MALE_SIGN, STAFF_OF_AESCULAPIUS };

static bool isStickyWhitelisted(uint32_t c) {
    for (size_t i = 0; i < sizeof(stickyWhitelist) / sizeof(stickyWhitelist[0]); i++) {
        if (stickyWhitelist[i] == c) return true;
    }
    return false;
}

static bool isVariationSelector(uint32_t c) {
    return (0xFE00 <= c && c <= 0xFE0F) || (0xE0100 <= c && c <= 0xE01EF);
}

bool FontCollection::hasVariationSelector(uint32_t baseCodepoint,
        uint32_t variationSelector) const {
    if (!isVariationSelector(variationSelector)) {
        return false;
    }
    if (baseCodepoint >= mMaxChar) {
        return false;
    }

    android::AutoMutex _l(gMinikinLock);

    // Currently mRanges can not be used here since it isn't aware of the variation sequence.
    for (size_t i = 0; i < mVSFamilyVec.size(); i++) {
        if (mVSFamilyVec[i]->hasGlyph(baseCodepoint, variationSelector)) {
            return true;
        }
    }

    // Even if there is no cmap format 14 subtable entry for the given sequence, should return true
    // for emoji + U+FE0E case since we have special fallback rule for the sequence.
    if (isEmojiStyleVSBase(baseCodepoint) && variationSelector == TEXT_STYLE_VS) {
        for (size_t i = 0; i < mFamilies.size(); ++i) {
            if (!mFamilies[i]->isColorEmojiFamily() && variationSelector == TEXT_STYLE_VS &&
                    mFamilies[i]->hasGlyph(baseCodepoint, 0)) {
                return true;
            }
        }
    }

    return false;
}

void FontCollection::itemize(const uint16_t *string, size_t string_size, FontStyle style,
        vector<Run>* result) const {
    const uint32_t langListId = style.getLanguageListId();
    int variant = style.getVariant();
    const FontFamily* lastFamily = nullptr;
    Run* run = NULL;

    if (string_size == 0) {
        return;
    }

    const uint32_t kEndOfString = 0xFFFFFFFF;

    uint32_t nextCh = 0;
    uint32_t prevCh = 0;
    size_t nextUtf16Pos = 0;
    size_t readLength = 0;
    U16_NEXT(string, readLength, string_size, nextCh);

    do {
        const uint32_t ch = nextCh;
        const size_t utf16Pos = nextUtf16Pos;
        nextUtf16Pos = readLength;
        if (readLength < string_size) {
            U16_NEXT(string, readLength, string_size, nextCh);
        } else {
            nextCh = kEndOfString;
        }

        bool shouldContinueRun = false;
        if (lastFamily != nullptr) {
            if (isStickyWhitelisted(ch)) {
                // Continue using existing font as long as it has coverage and is whitelisted
                shouldContinueRun = lastFamily->getCoverage().get(ch);
            } else if (ch == SOFT_HYPHEN || isVariationSelector(ch)) {
                // Always continue if the character is the soft hyphen or a variation selector.
                shouldContinueRun = true;
            }
        }

        if (!shouldContinueRun) {
            const std::shared_ptr<FontFamily>& family = getFamilyForChar(
                    ch, isVariationSelector(nextCh) ? nextCh : 0, langListId, variant);
            if (utf16Pos == 0 || family.get() != lastFamily) {
                size_t start = utf16Pos;
                // Workaround for combining marks and emoji modifiers until we implement
                // per-cluster font selection: if a combining mark or an emoji modifier is found in
                // a different font that also supports the previous character, attach previous
                // character to the new run. U+20E3 COMBINING ENCLOSING KEYCAP, used in emoji, is
                // handled properly by this since it's a combining mark too.
                if (utf16Pos != 0 &&
                        ((U_GET_GC_MASK(ch) & U_GC_M_MASK) != 0 ||
                         (isEmojiModifier(ch) && isEmojiBase(prevCh))) &&
                        family != nullptr && family->getCoverage().get(prevCh)) {
                    const size_t prevChLength = U16_LENGTH(prevCh);
                    run->end -= prevChLength;
                    if (run->start == run->end) {
                        result->pop_back();
                    }
                    start -= prevChLength;
                }
                result->push_back({family->getClosestMatch(style), static_cast<int>(start), 0});
                run = &result->back();
                lastFamily = family.get();
            }
        }
        prevCh = ch;
        run->end = nextUtf16Pos;  // exclusive
    } while (nextCh != kEndOfString);
}

FakedFont FontCollection::baseFontFaked(FontStyle style) {
    return mFamilies[0]->getClosestMatch(style);
}

std::shared_ptr<FontCollection> FontCollection::createCollectionWithVariation(
        const std::vector<FontVariation>& variations) {
    if (variations.empty() || mSupportedAxes.empty()) {
        return nullptr;
    }

    bool hasSupportedAxis = false;
    for (const FontVariation& variation : variations) {
        if (mSupportedAxes.find(variation.axisTag) != mSupportedAxes.end()) {
            hasSupportedAxis = true;
            break;
        }
    }
    if (!hasSupportedAxis) {
        // None of variation axes are supported by this font collection.
        return nullptr;
    }

    std::vector<std::shared_ptr<FontFamily> > families;
    for (const std::shared_ptr<FontFamily>& family : mFamilies) {
        std::shared_ptr<FontFamily> newFamily = family->createFamilyWithVariation(variations);
        if (newFamily) {
            families.push_back(newFamily);
        } else {
            families.push_back(family);
        }
    }

    return std::shared_ptr<FontCollection>(new FontCollection(families));
}

uint32_t FontCollection::getId() const {
    return mId;
}

}  // namespace minikin
