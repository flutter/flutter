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
#include <cutils/log.h>
#include <algorithm>

#include "unicode/unistr.h"
#include "unicode/unorm2.h"

#include "FontLanguage.h"
#include "FontLanguageListCache.h"
#include "MinikinInternal.h"
#include <minikin/FontCollection.h>

using std::vector;

namespace android {

template <typename T>
static inline T max(T a, T b) {
    return a>b ? a : b;
}

uint32_t FontCollection::sNextId = 0;

FontCollection::FontCollection(const vector<FontFamily*>& typefaces) :
    mMaxChar(0) {
    AutoMutex _l(gMinikinLock);
    mId = sNextId++;
    vector<uint32_t> lastChar;
    size_t nTypefaces = typefaces.size();
#ifdef VERBOSE_DEBUG
    ALOGD("nTypefaces = %zd\n", nTypefaces);
#endif
    const FontStyle defaultStyle;
    for (size_t i = 0; i < nTypefaces; i++) {
        FontFamily* family = typefaces[i];
        MinikinFont* typeface = family->getClosestMatch(defaultStyle).font;
        if (typeface == NULL) {
            continue;
        }
        family->RefLocked();
        const SparseBitSet* coverage = family->getCoverage();
        if (coverage == nullptr) {
            family->UnrefLocked();
            continue;
        }
        mFamilies.push_back(family);  // emplace_back would be better
        if (family->hasVSTable()) {
            mVSFamilyVec.push_back(family);
        }
        mMaxChar = max(mMaxChar, coverage->length());
        lastChar.push_back(coverage->nextSetBit(0));
    }
    nTypefaces = mFamilies.size();
    LOG_ALWAYS_FATAL_IF(nTypefaces == 0,
        "Font collection must have at least one valid typeface");
    size_t nPages = (mMaxChar + kPageMask) >> kLogCharsPerPage;
    size_t offset = 0;
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
        range->start = offset;
        for (size_t j = 0; j < nTypefaces; j++) {
            if (lastChar[j] < (i + 1) << kLogCharsPerPage) {
                FontFamily* family = mFamilies[j];
                mFamilyVec.push_back(family);
                offset++;
                uint32_t nextChar = family->getCoverage()->nextSetBit((i + 1) << kLogCharsPerPage);
#ifdef VERBOSE_DEBUG
                ALOGD("nextChar = %d (j = %zd)\n", nextChar, j);
#endif
                lastChar[j] = nextChar;
            }
        }
        range->end = offset;
    }
}

FontCollection::~FontCollection() {
    for (size_t i = 0; i < mFamilies.size(); i++) {
        mFamilies[i]->UnrefLocked();
    }
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
                                        FontFamily* fontFamily) const {

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
uint32_t FontCollection::calcCoverageScore(uint32_t ch, uint32_t vs, FontFamily* fontFamily) const {
    const bool hasVSGlyph = (vs != 0) && fontFamily->hasVariationSelector(ch, vs);
    if (!hasVSGlyph && !fontFamily->getCoverage()->get(ch)) {
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

    if (vs == 0xFE0F || vs == 0xFE0E) {
        // TODO use all language in the list.
        const FontLanguage lang = FontLanguageListCache::getById(fontFamily->langId())[0];
        const bool hasEmojiFlag = lang.hasEmojiFlag();
        if (vs == 0xFE0F) {
            return hasEmojiFlag ? 2 : 1;
        } else {  // vs == 0xFE0E
            return hasEmojiFlag ? 1 : 2;
        }
    }
    return 1;
}

// Calculates font scores based on the script matching and primary langauge matching.
//
// If the font's script doesn't support the requested script, the font gets a score of 0. If the
// font's script supports the requested script and the font has the same primary language as the
// requested one, the font gets a score of 2. If the font's script supports the requested script
// but the primary language is different from the requested one, the font gets a score of 1.
//
// If two languages in the requested list have the same language score, the font matching with
// higher priority language gets a higher score. For example, in the case the user requested
// language list is "ja-Jpan,en-Latn". The score of for the font of "ja-Jpan" gets a higher score
// than the font of "en-Latn".
//
// To achieve the above two conditions, the language score is determined as follows:
//   LanguageScore = s(0) * 3^(m - 1) + s(1) * 3^(m - 2) + ... + s(m - 2) * 3 + s(m - 1)
// Here, m is the maximum number of languages to be compared, and s(i) is the i-th language's
// matching score. The possible values of s(i) are 0, 1 and 2.
uint32_t FontCollection::calcLanguageMatchingScore(
        uint32_t userLangListId, const FontFamily& fontFamily) {
    const FontLanguages& langList = FontLanguageListCache::getById(userLangListId);
    // TODO use all language in the list.
    FontLanguage fontLanguage = FontLanguageListCache::getById(fontFamily.langId())[0];

    const size_t maxCompareNum = std::min(langList.size(), FONT_LANGUAGES_LIMIT);
    uint32_t score = fontLanguage.getScoreFor(langList[0]);  // maxCompareNum can't be zero.
    for (size_t i = 1; i < maxCompareNum; ++i) {
        score = score * 3u + fontLanguage.getScoreFor(langList[i]);
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
FontFamily* FontCollection::getFamilyForChar(uint32_t ch, uint32_t vs,
            uint32_t langListId, int variant) const {
    if (ch >= mMaxChar) {
        return NULL;
    }

    const std::vector<FontFamily*>* familyVec = &mFamilyVec;
    Range range = mRanges[ch >> kLogCharsPerPage];

    std::vector<FontFamily*> familyVecForVS;
    if (vs != 0) {
        // If variation selector is specified, need to search for both the variation sequence and
        // its base codepoint. Compute the union vector of them.
        familyVecForVS = mVSFamilyVec;
        familyVecForVS.insert(familyVecForVS.end(),
                mFamilyVec.begin() + range.start, mFamilyVec.begin() + range.end);
        std::sort(familyVecForVS.begin(), familyVecForVS.end());
        auto last = std::unique(familyVecForVS.begin(), familyVecForVS.end());
        familyVecForVS.erase(last, familyVecForVS.end());

        familyVec = &familyVecForVS;
        range = { 0, familyVecForVS.size() };
    }

#ifdef VERBOSE_DEBUG
    ALOGD("querying range %zd:%zd\n", range.start, range.end);
#endif
    FontFamily* bestFamily = nullptr;
    uint32_t bestScore = kUnsupportedFontScore;
    for (size_t i = range.start; i < range.end; i++) {
        FontFamily* family = (*familyVec)[i];
        const uint32_t score = calcFamilyScore(ch, vs, variant, langListId, family);
        if (score == kFirstFontScore) {
            // If the first font family supports the given character or variation sequence, always
            // use it.
            return family;
        }
        if (score > bestScore) {
            bestScore = score;
            bestFamily = family;
        }
    }
    if (bestFamily == nullptr && !mFamilyVec.empty()) {
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
        bestFamily = mFamilies[0];
    }
    return bestFamily;
}

const uint32_t NBSP = 0xa0;
const uint32_t ZWJ = 0x200c;
const uint32_t ZWNJ = 0x200d;
const uint32_t KEYCAP = 0x20e3;
const uint32_t HYPHEN = 0x2010;
const uint32_t NB_HYPHEN = 0x2011;

// Characters where we want to continue using existing font run instead of
// recomputing the best match in the fallback list.
static const uint32_t stickyWhitelist[] = { '!', ',', '-', '.', ':', ';', '?', NBSP, ZWJ, ZWNJ,
        KEYCAP, HYPHEN, NB_HYPHEN };

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
    if (variationSelector == 0) {
        return false;
    }

    // Currently mRanges can not be used here since it isn't aware of the variation sequence.
    for (size_t i = 0; i < mVSFamilyVec.size(); i++) {
        AutoMutex _l(gMinikinLock);
        if (mVSFamilyVec[i]->hasVariationSelector(baseCodepoint, variationSelector)) {
            return true;
        }
    }
    return false;
}

void FontCollection::itemize(const uint16_t *string, size_t string_size, FontStyle style,
        vector<Run>* result) const {
    const uint32_t langListId = style.getLanguageListId();
    int variant = style.getVariant();
    FontFamily* lastFamily = NULL;
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
                shouldContinueRun = lastFamily->getCoverage()->get(ch);
            } else if (isVariationSelector(ch)) {
                // Always continue if the character is a variation selector.
                shouldContinueRun = true;
            }
        }

        if (!shouldContinueRun) {
            FontFamily* family = getFamilyForChar(ch, isVariationSelector(nextCh) ? nextCh : 0,
                    langListId, variant);
            if (utf16Pos == 0 || family != lastFamily) {
                size_t start = utf16Pos;
                // Workaround for Emoji keycap and emoji modifier until we implement per-cluster
                // font selection: if a keycap or an emoji modifier is found in a different font
                // that also supports previous char, attach previous char to the new run.
                // Bug 7557244.
                if (utf16Pos != 0 &&
                        (ch == KEYCAP || (isEmojiModifier(ch) && isEmojiBase(prevCh))) &&
                        family && family->getCoverage()->get(prevCh)) {
                    const size_t prevChLength = U16_LENGTH(prevCh);
                    run->end -= prevChLength;
                    if (run->start == run->end) {
                        result->pop_back();
                    }
                    start -= prevChLength;
                }
                Run dummy;
                result->push_back(dummy);
                run = &result->back();
                if (family == NULL) {
                    run->fakedFont.font = NULL;
                } else {
                    run->fakedFont = family->getClosestMatch(style);
                }
                lastFamily = family;
                run->start = start;
            }
        }
        prevCh = ch;
        run->end = nextUtf16Pos;  // exclusive
    } while (nextCh != kEndOfString);
}

MinikinFont* FontCollection::baseFont(FontStyle style) {
    return baseFontFaked(style).font;
}

FakedFont FontCollection::baseFontFaked(FontStyle style) {
    if (mFamilies.empty()) {
        return FakedFont();
    }
    return mFamilies[0]->getClosestMatch(style);
}

uint32_t FontCollection::getId() const {
    return mId;
}

}  // namespace android
