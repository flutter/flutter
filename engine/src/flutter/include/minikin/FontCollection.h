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

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_TRUETYPE_TABLES_H

#include "SparseBitSet.h"
#include "FontFamily.h"

namespace android {

class FontCollection {
public:
    explicit FontCollection(const std::vector<FontFamily*>& typefaces);

    ~FontCollection();

    const FontFamily* getFamilyForChar(uint32_t ch) const;
    class Run {
    public:
        // Do copy constructor, assignment, destructor so it can be used in vectors
        Run() : font(NULL) { }
        Run(const Run& other): font(other.font), start(other.start), end(other.end) {
            if (font) FT_Reference_Face(font);
        }
        Run& operator=(const Run& other) {
            if (other.font) FT_Reference_Face(other.font);
            if (font) FT_Done_Face(font);
            font = other.font;
            start = other.start;
            end = other.end;
            return *this;
        }
        ~Run() { if (font) FT_Done_Face(font); }

        FT_Face font;
        int start;
        int end;
    };
    void itemize(const uint16_t *string, size_t string_length, FontStyle style,
            std::vector<Run>* result) const;
    private:
    static const int kLogCharsPerPage = 8;
    static const int kPageMask = (1 << kLogCharsPerPage) - 1;

    struct FontInstance {
        SparseBitSet* mCoverage;
        FontFamily* mFamily;
    };

    struct Range {
        size_t start;
        size_t end;
    };

    // Highest UTF-32 code point that can be mapped
    uint32_t mMaxChar;

    // This vector has ownership of the bitsets and typeface objects.
    std::vector<FontInstance> mInstances;

    // This vector contains pointers into mInstances
    std::vector<const FontInstance*> mInstanceVec;

    // These are offsets into mInstanceVec, one range per page
    std::vector<Range> mRanges;
};

}  // namespace android

#endif  // MINIKIN_FONT_COLLECTION_H
