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

#ifndef MINIKIN_TEST_MINIKIN_FONT_FOR_TEST_H
#define MINIKIN_TEST_MINIKIN_FONT_FOR_TEST_H

#include <minikin/MinikinFont.h>

class SkTypeface;

namespace minikin {

class MinikinFontForTest : public MinikinFont {
public:
    MinikinFontForTest(const std::string& font_path, int index);
    MinikinFontForTest(const std::string& font_path) : MinikinFontForTest(font_path, 0) {}
    virtual ~MinikinFontForTest();

    // MinikinFont overrides.
    float GetHorizontalAdvance(uint32_t glyph_id, const MinikinPaint &paint) const;
    void GetBounds(MinikinRect* bounds, uint32_t glyph_id,
            const MinikinPaint& paint) const;

    const std::string& fontPath() const { return mFontPath; }
    const void* GetFontData() const { return mFontData; }
    size_t GetFontSize() const { return mFontSize; }
    int GetFontIndex() const { return mFontIndex; }
private:
    MinikinFontForTest() = delete;
    MinikinFontForTest(const MinikinFontForTest&) = delete;
    MinikinFontForTest& operator=(MinikinFontForTest&) = delete;

    const std::string mFontPath;
    const int mFontIndex;
    void* mFontData;
    size_t mFontSize;
};

}  // namespace minikin

#endif  // MINIKIN_TEST_MINIKIN_FONT_FOR_TEST_H
