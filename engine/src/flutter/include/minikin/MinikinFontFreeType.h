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

#ifndef MINIKIN_FONT_FREETYPE_H
#define MINIKIN_FONT_FREETYPE_H

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_TRUETYPE_TABLES_H

#include <minikin/MinikinFont.h>

// An abstraction for platform fonts, allowing Minikin to be used with
// multiple actual implementations of fonts.

namespace android {

struct GlyphBitmap {
    uint8_t *buffer;
    int width;
    int height;
    int left;
    int top;
};

class MinikinFontFreeType : public MinikinFont {
public:
    explicit MinikinFontFreeType(FT_Face typeface);

    ~MinikinFontFreeType();

    bool GetGlyph(uint32_t codepoint, uint32_t *glyph) const;

    float GetHorizontalAdvance(uint32_t glyph_id,
        const MinikinPaint &paint) const;

    void GetBounds(MinikinRect* bounds, uint32_t glyph_id,
        const MinikinPaint& paint) const;

    // If buf is NULL, just update size
    bool GetTable(uint32_t tag, uint8_t *buf, size_t *size);

    int32_t GetUniqueId() const;

    // Not a virtual method, as the protocol to access rendered
    // glyph bitmaps is probably different depending on the
    // backend.
    bool Render(uint32_t glyph_id,
        const MinikinPaint &paint, GlyphBitmap *result);

    MinikinFontFreeType* GetFreeType();

private:
    FT_Face mTypeface;
    int32_t mUniqueId;
    static int32_t sIdCounter;
};

}  // namespace android

#endif  // MINIKIN_FONT_FREETYPE_H
