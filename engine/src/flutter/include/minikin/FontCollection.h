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

#ifndef MINIKIN_FONT_COLLECTION_H
#define MINIKIN_FONT_COLLECTION_H

#include <vector>
#include <unordered_set>

#include <minikin/MinikinRefCounted.h>
#include <minikin/MinikinFont.h>
#include <minikin/FontFamily.h>

namespace minikin {

class FontCollection : public MinikinRefCounted {
public:
    explicit FontCollection(const std::vector<FontFamily*>& typefaces);

    ~FontCollection();

    struct Run {
        FakedFont fakedFont;
        int start;
        int end;
    };

    void itemize(const uint16_t *string, size_t string_length, FontStyle style,
            std::vector<Run>* result) const;

    // Returns true if there is a glyph for the code point and variation selector pair.
    // Returns false if no fonts have a glyph for the code point and variation
    // selector pair, or invalid variation selector is passed.
    bool hasVariationSelector(uint32_t baseCodepoint, uint32_t variationSelector) const;

    // Get the base font for the given style, useful for font-wide metrics.
    MinikinFont* baseFont(FontStyle style);

    // Get base font with fakery information (fake bold could affect metrics)
    FakedFont baseFontFaked(FontStyle style);

    // Creates new FontCollection based on this collection while applying font variations. Returns
    // nullptr if none of variations apply to this collection.
    FontCollection* createCollectionWithVariation(const std::vector<FontVariation>& variations);

    uint32_t getId() const;

private:
    static const int kLogCharsPerPage = 8;
    static const int kPageMask = (1 << kLogCharsPerPage) - 1;

    struct Range {
        uint8_t start;
        uint8_t end;
    };

    FontFamily* getFamilyForChar(uint32_t ch, uint32_t vs, uint32_t langListId, int variant) const;

    uint32_t calcFamilyScore(uint32_t ch, uint32_t vs, int variant, uint32_t langListId,
                             FontFamily* fontFamily) const;

    uint32_t calcCoverageScore(uint32_t ch, uint32_t vs, FontFamily* fontFamily) const;

    static uint32_t calcLanguageMatchingScore(uint32_t userLangListId,
                                              const FontFamily& fontFamily);

    static uint32_t calcVariantMatchingScore(int variant, const FontFamily& fontFamily);

    // static for allocating unique id's
    static uint32_t sNextId;

    // unique id for this font collection (suitable for cache key)
    uint32_t mId;

    // Highest UTF-32 code point that can be mapped
    uint32_t mMaxChar;

    // This vector has ownership of the bitsets and typeface objects.
    // This vector can't be empty.
    std::vector<FontFamily*> mFamilies;

    // This vector contains indices into mFamilies.
    // This vector can't be empty.
    std::vector<uint8_t> mFamilyVec;

    // This vector has pointers to the font family instance which has cmap 14 subtable.
    std::vector<FontFamily*> mVSFamilyVec;

    // These are offsets into mFamilyVec, one range per page
    std::vector<Range> mRanges;

    // Set of supported axes in this collection.
    std::unordered_set<AxisTag> mSupportedAxes;
};

}  // namespace minikin

#endif  // MINIKIN_FONT_COLLECTION_H
