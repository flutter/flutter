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

MinikinFontForTest::MinikinFontForTest(const std::string& font_path) :
    MinikinFontForTest(font_path, SkTypeface::CreateFromFile(font_path.c_str())) {
}

MinikinFontForTest::MinikinFontForTest(const std::string& font_path, SkTypeface* typeface) :
    MinikinFont(typeface->uniqueID()),
    mTypeface(typeface),
    mFontPath(font_path) {
}

MinikinFontForTest::~MinikinFontForTest() {
}

float MinikinFontForTest::GetHorizontalAdvance(uint32_t /* glyph_id */,
        const android::MinikinPaint& /* paint */) const {
    LOG_ALWAYS_FATAL("MinikinFontForTest::GetHorizontalAdvance is not yet implemented");
    return 0.0f;
}

void MinikinFontForTest::GetBounds(android::MinikinRect* /* bounds */, uint32_t /* glyph_id */,
        const android::MinikinPaint& /* paint */) const {
    LOG_ALWAYS_FATAL("MinikinFontForTest::GetBounds is not yet implemented");
}

const void* MinikinFontForTest::GetTable(uint32_t tag, size_t* size,
        android::MinikinDestroyFunc* destroy) {
    const size_t tableSize = mTypeface->getTableSize(tag);
    *size = tableSize;
    if (tableSize == 0) {
        return nullptr;
    }
    void* buf = malloc(tableSize);
    if (buf == nullptr) {
        return nullptr;
    }
    mTypeface->getTableData(tag, 0, tableSize, buf);
    *destroy = free;
    return buf;
}
