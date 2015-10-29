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

#include "unicode/unistr.h"
#include "unicode/unorm2.h"

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
    ALOGD("nTypefaces = %d\n", nTypefaces);
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
        mMaxChar = max(mMaxChar, coverage->length());
        lastChar.push_back(coverage->nextSetBit(0));
    }
    nTypefaces = mFamilies.size();
    LOG_ALWAYS_FATAL_IF(nTypefaces == 0,
        "Font collection must have at least one valid typeface");
    size_t nPages = (mMaxChar + kPageMask) >> kLogCharsPerPage;
    size_t offset = 0;
    for (size_t i = 0; i < nPages; i++) {
        Range dummy;
        mRanges.push_back(dummy);
        Range* range = &mRanges.back();
#ifdef VERBOSE_DEBUG
        ALOGD("i=%d: range start = %d\n", i, offset);
#endif
        range->start = offset;
        for (size_t j = 0; j < nTypefaces; j++) {
            if (lastChar[j] < (i + 1) << kLogCharsPerPage) {
                FontFamily* family = mFamilies[j];
                mFamilyVec.push_back(family);
                offset++;
                uint32_t nextChar = family->getCoverage()->nextSetBit((i + 1) << kLogCharsPerPage);
#ifdef VERBOSE_DEBUG
                ALOGD("nextChar = %d (j = %d)\n", nextChar, j);
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

// Implement heuristic for choosing best-match font. Here are the rules:
// 1. If first font in the collection has the character, it wins.
// 2. If a font matches both language and script, it gets a score of 4.
// 3. If a font matches just language, it gets a score of 2.
// 4. Matching the "compact" or "elegant" variant adds one to the score.
// 5. Highest score wins, with ties resolved to the first font.
FontFamily* FontCollection::getFamilyForChar(uint32_t ch,
            FontLanguage lang, int variant) const {
    if (ch >= mMaxChar) {
        return NULL;
    }
    const Range& range = mRanges[ch >> kLogCharsPerPage];
#ifdef VERBOSE_DEBUG
    ALOGD("querying range %d:%d\n", range.start, range.end);
#endif
    FontFamily* bestFamily = NULL;
    int bestScore = -1;
    for (size_t i = range.start; i < range.end; i++) {
        FontFamily* family = mFamilyVec[i];
        if (family->getCoverage()->get(ch)) {
            // First font family in collection always matches
            if (mFamilies[0] == family) {
                return family;
            }
            int score = lang.match(family->lang()) * 2;
            if (family->variant() == 0 || family->variant() == variant) {
                score++;
            }
            if (score > bestScore) {
                bestScore = score;
                bestFamily = family;
            }
        }
    }
    if (bestFamily == NULL && !mFamilyVec.empty()) {
        UErrorCode errorCode = U_ZERO_ERROR;
        const UNormalizer2* normalizer = unorm2_getNFDInstance(&errorCode);
        if (U_SUCCESS(errorCode)) {
            UChar decomposed[4];
            int len = unorm2_getRawDecomposition(normalizer, ch, decomposed, 4, &errorCode);
            if (U_SUCCESS(errorCode) && len > 0) {
                int off = 0;
                U16_NEXT_UNSAFE(decomposed, off, ch);
                return getFamilyForChar(ch, lang, variant);
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

void FontCollection::itemize(const uint16_t *string, size_t string_size, FontStyle style,
        vector<Run>* result) const {
    FontLanguage lang = style.getLanguage();
    int variant = style.getVariant();
    FontFamily* lastFamily = NULL;
    Run* run = NULL;
    int nShorts;
    for (size_t i = 0; i < string_size; i += nShorts) {
        nShorts = 1;
        uint32_t ch = string[i];
        // sigh, decode UTF-16 by hand here
        if ((ch & 0xfc00) == 0xd800) {
            if ((i + 1) < string_size) {
                ch = 0x10000 + ((ch & 0x3ff) << 10) + (string[i + 1] & 0x3ff);
                nShorts = 2;
            }
        }
        // Continue using existing font as long as it has coverage and is whitelisted;
        // also variation sequences continue existing run.
        if (lastFamily == NULL
                || !((isStickyWhitelisted(ch) && lastFamily->getCoverage()->get(ch))
                      || isVariationSelector(ch))) {
            FontFamily* family = getFamilyForChar(ch, lang, variant);
            if (i == 0 || family != lastFamily) {
                size_t start = i;
                // Workaround for Emoji keycap until we implement per-cluster font
                // selection: if keycap is found in a different font that also
                // supports previous char, attach previous char to the new run.
                // Only handles non-surrogate characters.
                // Bug 7557244.
                if (ch == KEYCAP && i && family && family->getCoverage()->get(string[i - 1])) {
                    run->end--;
                    if (run->start == run->end) {
                        result->pop_back();
                    }
                    start--;
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
        run->end = i + nShorts;
    }
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
