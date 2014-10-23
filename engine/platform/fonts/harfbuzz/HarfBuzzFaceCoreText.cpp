/*
 * Copyright (c) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/fonts/harfbuzz/HarfBuzzFace.h"

#include "platform/fonts/FontPlatformData.h"
#include "platform/fonts/SimpleFontData.h"
#include "platform/fonts/harfbuzz/HarfBuzzShaper.h"

#include <ApplicationServices/ApplicationServices.h>
#include "hb.h"

namespace blink {

static hb_position_t floatToHarfBuzzPosition(CGFloat value)
{
    return static_cast<hb_position_t>(value * (1 << 16));
}

static hb_bool_t getGlyph(hb_font_t* hbFont, void* fontData, hb_codepoint_t unicode, hb_codepoint_t variationSelector, hb_codepoint_t* glyph, void* userData)
{
    CTFontRef ctFont = reinterpret_cast<FontPlatformData*>(fontData)->ctFont();
    UniChar characters[4];
    CGGlyph cgGlyphs[4];
    size_t length = 0;
    U16_APPEND_UNSAFE(characters, length, unicode);
    if (!CTFontGetGlyphsForCharacters(ctFont, characters, cgGlyphs, length))
        return false;
    *glyph = cgGlyphs[0];
    return true;
}

static hb_position_t getGlyphHorizontalAdvance(hb_font_t* hbFont, void* fontData, hb_codepoint_t glyph, void* userData)
{
    CTFontRef ctFont = reinterpret_cast<FontPlatformData*>(fontData)->ctFont();
    CGGlyph cgGlyph = glyph;
    CGFloat advance = CTFontGetAdvancesForGlyphs(ctFont, kCTFontHorizontalOrientation, &cgGlyph, 0, 1);
    return floatToHarfBuzzPosition(advance);
}

static hb_bool_t getGlyphHorizontalOrigin(hb_font_t* hbFont, void* fontData, hb_codepoint_t glyph, hb_position_t* x, hb_position_t* y, void* userData)
{
    return true;
}

static hb_bool_t getGlyphExtents(hb_font_t* hbFont, void* fontData, hb_codepoint_t glyph, hb_glyph_extents_t* extents, void* userData)
{
    CTFontRef ctFont = reinterpret_cast<FontPlatformData*>(fontData)->ctFont();
    CGRect cgRect;
    CGGlyph cgGlyph = glyph;
    if (CTFontGetBoundingRectsForGlyphs(ctFont, kCTFontDefaultOrientation, &cgGlyph, &cgRect, 1) == CGRectNull)
        return false;
    extents->x_bearing = floatToHarfBuzzPosition(cgRect.origin.x);
    extents->y_bearing = -floatToHarfBuzzPosition(cgRect.origin.y);
    extents->width = floatToHarfBuzzPosition(cgRect.size.width);
    extents->height = floatToHarfBuzzPosition(cgRect.size.height);
    return true;
}

static hb_font_funcs_t* harfBuzzCoreTextGetFontFuncs()
{
    static hb_font_funcs_t* harfBuzzCoreTextFontFuncs = 0;

    if (!harfBuzzCoreTextFontFuncs) {
        harfBuzzCoreTextFontFuncs = hb_font_funcs_create();
        hb_font_funcs_set_glyph_func(harfBuzzCoreTextFontFuncs, getGlyph, 0, 0);
        hb_font_funcs_set_glyph_h_advance_func(harfBuzzCoreTextFontFuncs, getGlyphHorizontalAdvance, 0, 0);
        hb_font_funcs_set_glyph_h_origin_func(harfBuzzCoreTextFontFuncs, getGlyphHorizontalOrigin, 0, 0);
        hb_font_funcs_set_glyph_extents_func(harfBuzzCoreTextFontFuncs, getGlyphExtents, 0, 0);
        hb_font_funcs_make_immutable(harfBuzzCoreTextFontFuncs);
    }
    return harfBuzzCoreTextFontFuncs;
}

static void releaseTableData(void* userData)
{
    CFDataRef cfData = reinterpret_cast<CFDataRef>(userData);
    CFRelease(cfData);
}

static hb_blob_t* harfBuzzCoreTextGetTable(hb_face_t* face, hb_tag_t tag, void* userData)
{
    CGFontRef cgFont = reinterpret_cast<CGFontRef>(userData);
    CFDataRef cfData = CGFontCopyTableForTag(cgFont, tag);
    if (!cfData)
        return 0;

    const char* data = reinterpret_cast<const char*>(CFDataGetBytePtr(cfData));
    const size_t length = CFDataGetLength(cfData);
    if (!data || !length)
        return 0;
    return hb_blob_create(data, length, HB_MEMORY_MODE_READONLY, reinterpret_cast<void*>(const_cast<__CFData*>(cfData)), releaseTableData);
}

hb_face_t* HarfBuzzFace::createFace()
{
    // It seems that CTFontCopyTable of MacOSX10.5 sdk doesn't work for
    // OpenType layout tables(GDEF, GSUB, GPOS). Use CGFontCopyTableForTag instead.
    hb_face_t* face = hb_face_create_for_tables(harfBuzzCoreTextGetTable, m_platformData->cgFont(), 0);
    ASSERT(face);
    return face;
}

hb_font_t* HarfBuzzFace::createFont()
{
    hb_font_t* font = hb_font_create(m_face);
    hb_font_set_funcs(font, harfBuzzCoreTextGetFontFuncs(), m_platformData, 0);
    const float size = m_platformData->m_size;
    hb_font_set_ppem(font, size, size);
    const int scale = (1 << 16) * static_cast<int>(size);
    hb_font_set_scale(font, scale, scale);
    hb_font_make_immutable(font);
    return font;
}

} // namespace blink
