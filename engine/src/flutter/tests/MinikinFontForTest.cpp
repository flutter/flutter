/*
 * Copyright (C) 2015 The Android Open Source Project
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

#include "MinikinFontForTest.h"

#include <minikin/MinikinFont.h>

#include <SkTypeface.h>

#include <cutils/log.h>

MinikinFontForTest::MinikinFontForTest(const std::string& font_path) : mFontPath(font_path) {
    mTypeface = SkTypeface::CreateFromFile(font_path.c_str());
}

MinikinFontForTest::~MinikinFontForTest() {
}

bool MinikinFontForTest::GetGlyph(uint32_t codepoint, uint32_t *glyph) const {
    LOG_ALWAYS_FATAL("MinikinFontForTest::GetGlyph is not yet implemented");
    return false;
}

float MinikinFontForTest::GetHorizontalAdvance(
        uint32_t glyph_id, const android::MinikinPaint &paint) const {
    LOG_ALWAYS_FATAL("MinikinFontForTest::GetHorizontalAdvance is not yet implemented");
    return 0.0f;
}

void MinikinFontForTest::GetBounds(android::MinikinRect* bounds, uint32_t glyph_id,
        const android::MinikinPaint& paint) const {
    LOG_ALWAYS_FATAL("MinikinFontForTest::GetBounds is not yet implemented");
}

bool MinikinFontForTest::GetTable(uint32_t tag, uint8_t *buf, size_t *size) {
    if (buf == NULL) {
        const size_t tableSize = mTypeface->getTableSize(tag);
        *size = tableSize;
        return tableSize != 0;
    } else {
        const size_t actualSize = mTypeface->getTableData(tag, 0, *size, buf);
        *size = actualSize;
        return actualSize != 0;
    }
}

int32_t MinikinFontForTest::GetUniqueId() const {
    return mTypeface->uniqueID();
}
