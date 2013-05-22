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

#ifndef MINIKIN_FONT_H
#define MINIKIN_FONT_H

// An abstraction for platform fonts, allowing Minikin to be used with
// multiple actual implementations of fonts.

namespace android {

class MinikinFont;

// Possibly move into own .h file?
struct MinikinPaint {
    MinikinFont *font;
    float size;
    // todo: skew, stretch, hinting
};

class MinikinFontFreeType;

class MinikinFont {
public:
    void Ref() { mRefcount_++; }
    void Unref() { if (--mRefcount_ == 0) { delete this; } }

    //MinikinFont();
    virtual ~MinikinFont() = 0;

    virtual bool GetGlyph(uint32_t codepoint, uint32_t *glyph) const = 0;

    virtual float GetHorizontalAdvance(uint32_t glyph_id,
        const MinikinPaint &paint) const = 0;

    // If buf is NULL, just update size
    virtual bool GetTable(uint32_t tag, uint8_t *buf, size_t *size) = 0;

    virtual int32_t GetUniqueId() const = 0;

    static uint32_t MakeTag(char c1, char c2, char c3, char c4) {
        return ((uint32_t)c1 << 24) | ((uint32_t)c2 << 16) |
            ((uint32_t)c3 << 8) | (uint32_t)c4;
    }

    // This is used to implement a downcast without RTTI
    virtual MinikinFontFreeType* GetFreeType() {
        return NULL;
    }

private:
    int mRefcount_;
};

}  // namespace android

#endif  // MINIKIN_FONT_H
