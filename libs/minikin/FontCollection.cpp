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

#include <minikin/CmapCoverage.h>
#include <minikin/FontCollection.h>

using std::vector;

namespace android {

template <typename T>
static inline T max(T a, T b) {
    return a>b ? a : b;
}

FontCollection::FontCollection(const vector<FontFamily*>& typefaces) :
    mMaxChar(0) {
    vector<uint32_t> lastChar;
    size_t nTypefaces = typefaces.size();
#ifdef VERBOSE_DEBUG
    ALOGD("nTypefaces = %d\n", nTypefaces);
#endif
    const FontStyle defaultStyle;
    for (size_t i = 0; i < nTypefaces; i++) {
        FontFamily* family = typefaces[i];
        family->RefLocked();
        FontInstance dummy;
        mInstances.push_back(dummy);  // emplace_back would be better
        FontInstance* instance = &mInstances.back();
        instance->mFamily = family;
        instance->mCoverage = new SparseBitSet;
        MinikinFont* typeface = family->getClosestMatch(defaultStyle);
#ifdef VERBOSE_DEBUG
        ALOGD("closest match = %p, family size = %d\n", typeface, family->getNumFonts());
#endif
        const uint32_t cmapTag = MinikinFont::MakeTag('c', 'm', 'a', 'p');
        size_t cmapSize = 0;
        bool ok = typeface->GetTable(cmapTag, NULL, &cmapSize);
        UniquePtr<uint8_t[]> cmapData(new uint8_t[cmapSize]);
        ok = typeface->GetTable(cmapTag, cmapData.get(), &cmapSize);
        CmapCoverage::getCoverage(*instance->mCoverage, cmapData.get(), cmapSize);
#ifdef VERBOSE_DEBUG
        ALOGD("font coverage length=%d, first ch=%x\n", instance->mCoverage->length(),
                instance->mCoverage->nextSetBit(0));
#endif
        mMaxChar = max(mMaxChar, instance->mCoverage->length());
        lastChar.push_back(instance->mCoverage->nextSetBit(0));
    }
    size_t nPages = mMaxChar >> kLogCharsPerPage;
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
                const FontInstance* instance = &mInstances[j];
                mInstanceVec.push_back(instance);
                offset++;
                uint32_t nextChar = instance->mCoverage->nextSetBit((i + 1) << kLogCharsPerPage);
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
    for (size_t i = 0; i < mInstances.size(); i++) {
        delete mInstances[i].mCoverage;
        mInstances[i].mFamily->UnrefLocked();
    }
}

const FontFamily* FontCollection::getFamilyForChar(uint32_t ch) const {
    if (ch >= mMaxChar) {
        return NULL;
    }
    const Range& range = mRanges[ch >> kLogCharsPerPage];
#ifdef VERBOSE_DEBUG
    ALOGD("querying range %d:%d\n", range.start, range.end);
#endif
    for (size_t i = range.start; i < range.end; i++) {
        const FontInstance* instance = mInstanceVec[i];
        if (instance->mCoverage->get(ch)) {
            return instance->mFamily;
        }
    }
    return NULL;
}

void FontCollection::itemize(const uint16_t *string, size_t string_size, FontStyle style,
        vector<Run>* result) const {
    const FontFamily* lastFamily = NULL;
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
        const FontFamily* family = getFamilyForChar(ch);
        if (i == 0 || family != lastFamily) {
            Run dummy;
            result->push_back(dummy);
            run = &result->back();
            if (family == NULL) {
                run->font = NULL;  // maybe we should do something different here
            } else {
                run->font = family->getClosestMatch(style);
                run->font->RefLocked();
            }
            lastFamily = family;
            run->start = i;
        }
        run->end = i + nShorts;
    }
}

}  // namespace android
