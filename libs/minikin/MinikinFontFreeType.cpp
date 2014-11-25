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

// Implementation of MinikinFont abstraction specialized for FreeType

#include <stdint.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_TRUETYPE_TABLES_H
#include FT_ADVANCES_H

#include <minikin/MinikinFontFreeType.h>

namespace android {

int32_t MinikinFontFreeType::sIdCounter = 0;

MinikinFontFreeType::MinikinFontFreeType(FT_Face typeface) : 
    mTypeface(typeface) {
    mUniqueId = sIdCounter++;
}

MinikinFontFreeType::~MinikinFontFreeType() {
    FT_Done_Face(mTypeface);
}

bool MinikinFontFreeType::GetGlyph(uint32_t codepoint, uint32_t *glyph) const {
    FT_UInt glyph_index = FT_Get_Char_Index(mTypeface, codepoint);
    *glyph = glyph_index;
    return !!glyph_index;
}

float MinikinFontFreeType::GetHorizontalAdvance(uint32_t glyph_id,
    const MinikinPaint &paint) const {
    FT_Set_Pixel_Sizes(mTypeface, 0, paint.size);
	FT_UInt32 flags = FT_LOAD_DEFAULT;  // TODO: respect hinting settings
	FT_Fixed advance;
    FT_Get_Advance(mTypeface, glyph_id, flags, &advance);
    return advance * (1.0 / 65536);
}

void MinikinFontFreeType::GetBounds(MinikinRect* bounds, uint32_t glyph_id,
    const MinikinPaint& paint) const {
    // TODO: NYI
}

bool MinikinFontFreeType::GetTable(uint32_t tag, uint8_t *buf, size_t *size) {
	FT_ULong ftsize = *size;
	FT_Error error = FT_Load_Sfnt_Table(mTypeface, tag, 0, buf, &ftsize);
	if (error != 0) {
		return false;
	}
	*size = ftsize;
	return true;
}

int32_t MinikinFontFreeType::GetUniqueId() const {
	return mUniqueId;
}

bool MinikinFontFreeType::Render(uint32_t glyph_id,
    const MinikinPaint &paint, GlyphBitmap *result) {
    FT_Error error;
    FT_Int32 load_flags = FT_LOAD_DEFAULT;  // TODO: respect hinting settings
    error = FT_Load_Glyph(mTypeface, glyph_id, load_flags);
    if (error != 0) {
        return false;
    }
    error = FT_Render_Glyph(mTypeface->glyph, FT_RENDER_MODE_NORMAL);
    if (error != 0) {
        return false;
    }
    FT_Bitmap &bitmap = mTypeface->glyph->bitmap;
    result->buffer = bitmap.buffer;
    result->width = bitmap.width;
    result->height = bitmap.rows;
    result->left = mTypeface->glyph->bitmap_left;
    result->top = mTypeface->glyph->bitmap_top;
    return true;
}

MinikinFontFreeType* MinikinFontFreeType::GetFreeType() {
    return this;
}

}  // namespace android
