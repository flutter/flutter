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

#include <minikin/MinikinRefCounted.h>
#include <minikin/MinikinFont.h>
#include <minikin/SparseBitSet.h>
#include <minikin/FontFamily.h>

namespace android {

class FontCollection : public MinikinRefCounted {
public:
    explicit FontCollection(const std::vector<FontFamily*>& typefaces);

    ~FontCollection();

    const FontFamily* getFamilyForChar(uint32_t ch) const;
    class Run {
    public:
        // Do copy constructor, assignment, destructor so it can be used in vectors
        Run() : font(NULL) { }
        Run(const Run& other): font(other.font), start(other.start), end(other.end) {
            if (font) font->RefLocked();
        }
        Run& operator=(const Run& other) {
            if (other.font) other.font->RefLocked();
            if (font) font->UnrefLocked();
            font = other.font;
            start = other.start;
            end = other.end;
            return *this;
        }
        ~Run() { if (font) font->UnrefLocked(); }

        MinikinFont* font;
        int start;
        int end;
    };

    void itemize(const uint16_t *string, size_t string_length, FontStyle style,
            std::vector<Run>* result) const;

    uint32_t getId() const;
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

    // static for allocating unique id's
    static uint32_t sNextId;

    // unique id for this font collection (suitable for cache key)
    uint32_t mId;

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
