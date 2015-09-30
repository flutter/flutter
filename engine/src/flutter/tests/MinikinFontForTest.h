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

#include <minikin/MinikinFont.h>

class SkTypeface;

class MinikinFontForTest : public android::MinikinFont {
public:
    explicit MinikinFontForTest(const std::string& font_path);
    ~MinikinFontForTest();

    // MinikinFont overrides.
    bool GetGlyph(uint32_t codepoint, uint32_t *glyph) const;
    float GetHorizontalAdvance(uint32_t glyph_id, const android::MinikinPaint &paint) const;
    void GetBounds(android::MinikinRect* bounds, uint32_t glyph_id,
            const android::MinikinPaint& paint) const;
    bool GetTable(uint32_t tag, uint8_t *buf, size_t *size);
    int32_t GetUniqueId() const;

    const std::string& fontPath() const { return mFontPath; }
private:
    SkTypeface *mTypeface;
    const std::string mFontPath;
};
