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

#define LOG_TAG "Minikin"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <log/log.h>
#include <utils/JenkinsHash.h>

#include <hb.h>
#include <hb-ot.h>

#include "FontLanguage.h"
#include "FontLanguageListCache.h"
#include "HbFontCache.h"
#include "MinikinInternal.h"
#include <minikin/AnalyzeStyle.h>
#include <minikin/CmapCoverage.h>
#include <minikin/FontFamily.h>
#include <minikin/MinikinFont.h>

using std::vector;

namespace minikin {

FontStyle::FontStyle(int variant, int weight, bool italic)
        : FontStyle(FontLanguageListCache::kEmptyListId, variant, weight, italic) {
}

FontStyle::FontStyle(uint32_t languageListId, int variant, int weight, bool italic)
        : bits(pack(variant, weight, italic)), mLanguageListId(languageListId) {
}

android::hash_t FontStyle::hash() const {
    uint32_t hash = android::JenkinsHashMix(0, bits);
    hash = android::JenkinsHashMix(hash, mLanguageListId);
    return android::JenkinsHashWhiten(hash);
}

// static
uint32_t FontStyle::registerLanguageList(const std::string& languages) {
    android::AutoMutex _l(gMinikinLock);
    return FontLanguageListCache::getId(languages);
}

// static
uint32_t FontStyle::pack(int variant, int weight, bool italic) {
    return (weight & kWeightMask) | (italic ? kItalicMask : 0) | (variant << kVariantShift);
}

Font::Font(MinikinFont* typeface, FontStyle style)
    : typeface(typeface), style(style) {
    typeface->Ref();
}

Font::Font(Font&& o) {
    typeface = o.typeface;
    style = o.style;
    o.typeface = nullptr;
}

Font::Font(const Font& o) {
    typeface = o.typeface;
    typeface->Ref();
    style = o.style;
}

Font::~Font() {
    if (typeface == nullptr) {
        return;
    }
    typeface->UnrefLocked();
}

FontFamily::FontFamily(std::vector<Font>&& fonts) : FontFamily(0 /* variant */, std::move(fonts)) {
}

FontFamily::FontFamily(int variant, std::vector<Font>&& fonts)
    : FontFamily(FontLanguageListCache::kEmptyListId, variant, std::move(fonts)) {
}

FontFamily::FontFamily(uint32_t langId, int variant, std::vector<Font>&& fonts)
    : mLangId(langId), mVariant(variant), mFonts(std::move(fonts)), mHasVSTable(false) {
    computeCoverage();
}

FontFamily::~FontFamily() {
}

bool FontFamily::analyzeStyle(MinikinFont* typeface, int* weight, bool* italic) {
    android::AutoMutex _l(gMinikinLock);
    const uint32_t os2Tag = MinikinFont::MakeTag('O', 'S', '/', '2');
    HbBlob os2Table(getFontTable(typeface, os2Tag));
    if (os2Table.get() == nullptr) return false;
    return ::minikin::analyzeStyle(os2Table.get(), os2Table.size(), weight, italic);
}

// Compute a matching metric between two styles - 0 is an exact match
static int computeMatch(FontStyle style1, FontStyle style2) {
    if (style1 == style2) return 0;
    int score = abs(style1.getWeight() - style2.getWeight());
    if (style1.getItalic() != style2.getItalic()) {
        score += 2;
    }
    return score;
}

static FontFakery computeFakery(FontStyle wanted, FontStyle actual) {
    // If desired weight is semibold or darker, and 2 or more grades
    // higher than actual (for example, medium 500 -> bold 700), then
    // select fake bold.
    int wantedWeight = wanted.getWeight();
    bool isFakeBold = wantedWeight >= 6 && (wantedWeight - actual.getWeight()) >= 2;
    bool isFakeItalic = wanted.getItalic() && !actual.getItalic();
    return FontFakery(isFakeBold, isFakeItalic);
}

FakedFont FontFamily::getClosestMatch(FontStyle style) const {
    const Font* bestFont = NULL;
    int bestMatch = 0;
    for (size_t i = 0; i < mFonts.size(); i++) {
        const Font& font = mFonts[i];
        int match = computeMatch(font.style, style);
        if (i == 0 || match < bestMatch) {
            bestFont = &font;
            bestMatch = match;
        }
    }
    FakedFont result;
    if (bestFont == NULL) {
        result.font = NULL;
    } else {
        result.font = bestFont->typeface;
        result.fakery = computeFakery(style, bestFont->style);
    }
    return result;
}

bool FontFamily::isColorEmojiFamily() const {
    const FontLanguages& languageList = FontLanguageListCache::getById(mLangId);
    for (size_t i = 0; i < languageList.size(); ++i) {
        if (languageList[i].getEmojiStyle() == FontLanguage::EMSTYLE_EMOJI) {
            return true;
        }
    }
    return false;
}

void FontFamily::computeCoverage() {
    android::AutoMutex _l(gMinikinLock);
    const FontStyle defaultStyle;
    MinikinFont* typeface = getClosestMatch(defaultStyle).font;
    const uint32_t cmapTag = MinikinFont::MakeTag('c', 'm', 'a', 'p');
    HbBlob cmapTable(getFontTable(typeface, cmapTag));
    if (cmapTable.get() == nullptr) {
        ALOGE("Could not get cmap table size!\n");
        return;
    }
    // TODO: Error check?
    CmapCoverage::getCoverage(mCoverage, cmapTable.get(), cmapTable.size(), &mHasVSTable);
#ifdef VERBOSE_DEBUG
    ALOGD("font coverage length=%d, first ch=%x\n", mCoverage.length(), mCoverage.nextSetBit(0));
#endif
}

bool FontFamily::hasGlyph(uint32_t codepoint, uint32_t variationSelector) const {
    assertMinikinLocked();
    if (variationSelector != 0 && !mHasVSTable) {
        // Early exit if the variation selector is specified but the font doesn't have a cmap format
        // 14 subtable.
        return false;
    }

    const FontStyle defaultStyle;
    MinikinFont* minikinFont = getClosestMatch(defaultStyle).font;
    hb_font_t* font = getHbFontLocked(minikinFont);
    uint32_t unusedGlyph;
    bool result = hb_font_get_glyph(font, codepoint, variationSelector, &unusedGlyph);
    hb_font_destroy(font);
    return result;
}

}  // namespace minikin
