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

#define LOG_TAG "Minikin"
#include <cutils/log.h>

#include <string>
#include <vector>
#include <algorithm>
#include <fstream>
#include <iostream>  // for debugging
#include <stdio.h>  // ditto

#include <unicode/ubidi.h>
#include <hb-icu.h>

#include "MinikinInternal.h"
#include <minikin/MinikinFontFreeType.h>
#include <minikin/Layout.h>

using std::string;
using std::vector;

namespace android {

// TODO: globals are not cool, move to a factory-ish object
hb_buffer_t* buffer = 0;

// TODO: these should move into the header file, but for now we don't want
// to cause namespace collisions with TextLayout.h
enum {
    kBidi_LTR = 0,
    kBidi_RTL = 1,
    kBidi_Default_LTR = 2,
    kBidi_Default_RTL = 3,
    kBidi_Force_LTR = 4,
    kBidi_Force_RTL = 5,

    kBidi_Mask = 0x7
};

const int kDirection_Mask = 0x1;

Bitmap::Bitmap(int width, int height) : width(width), height(height) {
    buf = new uint8_t[width * height]();
}

Bitmap::~Bitmap() {
    delete[] buf;
}

void Bitmap::writePnm(std::ofstream &o) const {
    o << "P5" << std::endl;
    o << width << " " << height << std::endl;
    o << "255" << std::endl;
    o.write((const char *)buf, width * height);
    o.close();
}

void Bitmap::drawGlyph(const GlyphBitmap& bitmap, int x, int y) {
    int bmw = bitmap.width;
    int bmh = bitmap.height;
    x += bitmap.left;
    y -= bitmap.top;
    int x0 = std::max(0, x);
    int x1 = std::min(width, x + bmw);
    int y0 = std::max(0, y);
    int y1 = std::min(height, y + bmh);
    const unsigned char* src = bitmap.buffer + (y0 - y) * bmw + (x0 - x);
    uint8_t* dst = buf + y0 * width;
    for (int yy = y0; yy < y1; yy++) {
        for (int xx = x0; xx < x1; xx++) {
            int pixel = (int)dst[xx] + (int)src[xx - x];
            pixel = pixel > 0xff ? 0xff : pixel;
            dst[xx] = pixel;
        }
        src += bmw;
        dst += width;
    }
}

void MinikinRect::join(const MinikinRect& r) {
    if (isEmpty()) {
        set(r);
    } else if (!r.isEmpty()) {
        mLeft = std::min(mLeft, r.mLeft);
        mTop = std::min(mTop, r.mTop);
        mRight = std::max(mRight, r.mRight);
        mBottom = std::max(mBottom, r.mBottom);
    }
}

// TODO: the actual initialization is deferred, maybe make this explicit
void Layout::init() {
}

void Layout::setFontCollection(const FontCollection *collection) {
    mCollection = collection;
}

hb_blob_t* referenceTable(hb_face_t* face, hb_tag_t tag, void* userData)  {
    MinikinFont* font = reinterpret_cast<MinikinFont *>(userData);
    size_t length = 0;
    bool ok = font->GetTable(tag, NULL, &length);
    if (!ok) {
        return 0;
    }
    char *buffer = reinterpret_cast<char*>(malloc(length));
    if (!buffer) {
        return 0;
    }
    ok = font->GetTable(tag, reinterpret_cast<uint8_t*>(buffer), &length);
    printf("referenceTable %c%c%c%c length=%d %d\n",
        (tag >>24) & 0xff, (tag>>16)&0xff, (tag>>8)&0xff, tag&0xff, length, ok);
    if (!ok) {
        free(buffer);
        return 0;
    }
    return hb_blob_create(const_cast<char*>(buffer), length,
        HB_MEMORY_MODE_WRITABLE, buffer, free);
}

static hb_bool_t harfbuzzGetGlyph(hb_font_t* hbFont, void* fontData, hb_codepoint_t unicode, hb_codepoint_t variationSelector, hb_codepoint_t* glyph, void* userData)
{
    MinikinPaint* paint = reinterpret_cast<MinikinPaint *>(fontData);
    MinikinFont* font = paint->font;
    uint32_t glyph_id;
    bool ok = font->GetGlyph(unicode, &glyph_id);
    if (ok) {
        *glyph = glyph_id;
    }
    return ok;
}

static hb_position_t harfbuzzGetGlyphHorizontalAdvance(hb_font_t* hbFont, void* fontData, hb_codepoint_t glyph, void* userData)
{
    MinikinPaint* paint = reinterpret_cast<MinikinPaint *>(fontData);
    MinikinFont* font = paint->font;
    float advance = font->GetHorizontalAdvance(glyph, *paint);
    return 256 * advance + 0.5;
}

static hb_bool_t harfbuzzGetGlyphHorizontalOrigin(hb_font_t* hbFont, void* fontData, hb_codepoint_t glyph, hb_position_t* x, hb_position_t* y, void* userData)
{
    // Just return true, following the way that Harfbuzz-FreeType
    // implementation does.
    return true;
}

hb_font_funcs_t* getHbFontFuncs() {
    static hb_font_funcs_t* hbFontFuncs = 0;

    if (hbFontFuncs == 0) {
        hbFontFuncs = hb_font_funcs_create();
        hb_font_funcs_set_glyph_func(hbFontFuncs, harfbuzzGetGlyph, 0, 0);
        hb_font_funcs_set_glyph_h_advance_func(hbFontFuncs, harfbuzzGetGlyphHorizontalAdvance, 0, 0);
        hb_font_funcs_set_glyph_h_origin_func(hbFontFuncs, harfbuzzGetGlyphHorizontalOrigin, 0, 0);
        hb_font_funcs_make_immutable(hbFontFuncs);
    }
    return hbFontFuncs;
}

hb_font_t* create_hb_font(MinikinFont* minikinFont, MinikinPaint* minikinPaint) {
    hb_face_t* face = hb_face_create_for_tables(referenceTable, minikinFont, NULL);
    hb_font_t* font = hb_font_create(face);
    hb_face_destroy(face);
    hb_font_set_funcs(font, getHbFontFuncs(), minikinPaint, 0);
    // TODO: manage ownership of face
    return font;
}

static float HBFixedToFloat(hb_position_t v)
{
    return scalbnf (v, -8);
}

static hb_position_t HBFloatToFixed(float v)
{
    return scalbnf (v, +8);
}

Layout::~Layout() {
    for (size_t ix = 0; ix < mHbFonts.size(); ix++) {
        hb_font_destroy(mHbFonts[ix]);
    }
}

void Layout::dump() const {
    for (size_t i = 0; i < mGlyphs.size(); i++) {
        const LayoutGlyph& glyph = mGlyphs[i];
        std::cout << glyph.glyph_id << ": " << glyph.x << ", " << glyph.y << std::endl;
    }
}

// A couple of things probably need to change:
// 1. Deal with multiple sizes in a layout
// 2. We'll probably store FT_Face as primary and then use a cache
// for the hb fonts
int Layout::findFace(MinikinFont* face, MinikinPaint* paint) {
    unsigned int ix;
    for (ix = 0; ix < mFaces.size(); ix++) {
        if (mFaces[ix] == face) {
            return ix;
        }
    }
    mFaces.push_back(face);
    hb_font_t *font = create_hb_font(face, paint);
    mHbFonts.push_back(font);
    return ix;
}

static FontStyle styleFromCss(const CssProperties &props) {
    int weight = 4;
    if (props.hasTag(fontWeight)) {
        weight = props.value(fontWeight).getIntValue() / 100;
    }
    bool italic = false;
    if (props.hasTag(fontStyle)) {
        italic = props.value(fontStyle).getIntValue() != 0;
    }
    return FontStyle(weight, italic);
}

static hb_script_t codePointToScript(hb_codepoint_t codepoint) {
    static hb_unicode_funcs_t *u = 0;
    if (!u) {
        u = hb_icu_get_unicode_funcs();
    }
    return hb_unicode_script(u, codepoint);
}

static hb_codepoint_t decodeUtf16(const uint16_t *chars, size_t len, ssize_t *iter) {
    const uint16_t v = chars[(*iter)++];
    // test whether v in (0xd800..0xdfff), lead or trail surrogate
    if ((v & 0xf800) == 0xd800) {
        // test whether v in (0xd800..0xdbff), lead surrogate
        if (size_t(*iter) < len && (v & 0xfc00) == 0xd800) {
            const uint16_t v2 = chars[(*iter)++];
            // test whether v2 in (0xdc00..0xdfff), trail surrogate
            if ((v2 & 0xfc00) == 0xdc00) {
                // (0xd800 0xdc00) in utf-16 maps to 0x10000 in ucs-32
                const hb_codepoint_t delta = (0xd800 << 10) + 0xdc00 - 0x10000;
                return (((hb_codepoint_t)v) << 10) + v2 - delta;
            }
            (*iter) -= 2;
            return ~0u;
        } else {
            (*iter)--;
            return ~0u;
        }
    } else {
        return v;
    }
}

static hb_script_t getScriptRun(const uint16_t *chars, size_t len, ssize_t *iter) {
    if (size_t(*iter) == len) {
        return HB_SCRIPT_UNKNOWN;
    }
    uint32_t cp = decodeUtf16(chars, len, iter);
    hb_script_t current_script = codePointToScript(cp);
    for (;;) {
        if (size_t(*iter) == len)
            break;
        const ssize_t prev_iter = *iter;
        cp = decodeUtf16(chars, len, iter);
        const hb_script_t script = codePointToScript(cp);
        if (script != current_script) {
            if (current_script == HB_SCRIPT_INHERITED ||
                current_script == HB_SCRIPT_COMMON) {
                current_script = script;
            } else if (script == HB_SCRIPT_INHERITED ||
                script == HB_SCRIPT_COMMON) {
                continue;
            } else {
                *iter = prev_iter;
                break;
            }
        }
    }
    if (current_script == HB_SCRIPT_INHERITED) {
        current_script = HB_SCRIPT_COMMON;
    }

    return current_script;
}

// TODO: API should probably take context
void Layout::doLayout(const uint16_t* buf, size_t nchars) {
    AutoMutex _l(gMinikinLock);
    if (buffer == 0) {
        buffer = hb_buffer_create();
    }
    FT_Error error;

    FontStyle style = styleFromCss(mProps);

    MinikinPaint paint;
    double size = mProps.value(fontSize).getFloatValue();
    paint.size = size;
    int bidiFlags = mProps.hasTag(minikinBidi) ? mProps.value(minikinBidi).getIntValue() : 0;
    bool isRtl = (bidiFlags & kDirection_Mask) != 0;
    bool doSingleRun = true;

    mGlyphs.clear();
    mFaces.clear();
    mHbFonts.clear();
    mBounds.setEmpty();
    mAdvances.clear();
    mAdvances.resize(nchars, 0);
    mAdvance = 0;
    if (!(bidiFlags == kBidi_Force_LTR || bidiFlags == kBidi_Force_RTL)) {
        UBiDi* bidi = ubidi_open();
        if (bidi) {
            UErrorCode status = U_ZERO_ERROR;
            UBiDiLevel bidiReq = bidiFlags;
            if (bidiFlags == kBidi_Default_LTR) {
                bidiReq = UBIDI_DEFAULT_LTR;
            } else if (bidiFlags == kBidi_Default_RTL) {
                bidiReq = UBIDI_DEFAULT_RTL;
            }
            ubidi_setPara(bidi, buf, nchars, bidiReq, NULL, &status);
            if (U_SUCCESS(status)) {
                int paraDir = ubidi_getParaLevel(bidi) & kDirection_Mask;
                ssize_t rc = ubidi_countRuns(bidi, &status);
                if (!U_SUCCESS(status) || rc < 1) {
                    ALOGD("error counting bidi runs, status = %d", status);
                }
                if (!U_SUCCESS(status) || rc <= 1) {
                    isRtl = (paraDir == kBidi_RTL);
                } else {
                    doSingleRun = false;
                    // iterate through runs
                    for (ssize_t i = 0; i < (ssize_t)rc; i++) {
                        int32_t startRun = -1;
                        int32_t lengthRun = -1;
                        UBiDiDirection runDir = ubidi_getVisualRun(bidi, i, &startRun, &lengthRun);
                        if (startRun == -1 || lengthRun == -1) {
                            ALOGE("invalid visual run");
                            // Note: this case will lose text; can it ever actually happen?
                            break;
                        }
                        isRtl = (runDir == UBIDI_RTL);
                        // TODO: min/max with context
                        doLayoutRun(buf, startRun, lengthRun, nchars, isRtl, style, paint);
                    }
                }
            } else {
                ALOGE("error calling ubidi_setPara, status = %d", status);
            }
            ubidi_close(bidi);
        } else {
            ALOGE("error creating bidi object");
        }
    }
    if (doSingleRun) {
        doLayoutRun(buf, 0, nchars, nchars, isRtl, style, paint);
    }
}

void Layout::doLayoutRun(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
    bool isRtl, FontStyle style, MinikinPaint& paint) {
    vector<FontCollection::Run> items;
    mCollection->itemize(buf + start, count, style, &items);
    if (isRtl) {
        std::reverse(items.begin(), items.end());
    }

    float x = mAdvance;
    float y = 0;
    for (size_t run_ix = 0; run_ix < items.size(); run_ix++) {
        FontCollection::Run &run = items[run_ix];
        int font_ix = findFace(run.font, &paint);
        paint.font = mFaces[font_ix];
        hb_font_t *hbFont = mHbFonts[font_ix];
        if (paint.font == NULL) {
            // TODO: should log what went wrong
            continue;
        }
#ifdef VERBOSE
        std::cout << "Run " << run_ix << ", font " << font_ix <<
            " [" << run.start << ":" << run.end << "]" << std::endl;
#endif
        double size = paint.size;
        hb_font_set_ppem(hbFont, size, size);
        hb_font_set_scale(hbFont, HBFloatToFixed(size), HBFloatToFixed(size));

        // TODO: if there are multiple scripts within a font in an RTL run,
        // we need to reorder those runs. This is unlikely with our current
        // font stack, but should be done for correctness.
        ssize_t srunend;
        for (ssize_t srunstart = run.start; srunstart < run.end; srunstart = srunend) {
            srunend = srunstart;
            hb_script_t script = getScriptRun(buf + start, run.end, &srunend);

            hb_buffer_reset(buffer);
            hb_buffer_set_script(buffer, script);
            hb_buffer_set_direction(buffer, isRtl? HB_DIRECTION_RTL : HB_DIRECTION_LTR);
            hb_buffer_add_utf16(buffer, buf, bufSize, srunstart + start, srunend - srunstart);
            hb_shape(hbFont, buffer, NULL, 0);
            unsigned int numGlyphs;
            hb_glyph_info_t *info = hb_buffer_get_glyph_infos(buffer, &numGlyphs);
            hb_glyph_position_t *positions = hb_buffer_get_glyph_positions(buffer, NULL);
            for (unsigned int i = 0; i < numGlyphs; i++) {
    #ifdef VERBOSE
                std::cout << positions[i].x_advance << " " << positions[i].y_advance << " " << positions[i].x_offset << " " << positions[i].y_offset << std::endl;            std::cout << "DoLayout " << info[i].codepoint <<
                ": " << HBFixedToFloat(positions[i].x_advance) << "; " << positions[i].x_offset << ", " << positions[i].y_offset << std::endl;
    #endif
                hb_codepoint_t glyph_ix = info[i].codepoint;
                float xoff = HBFixedToFloat(positions[i].x_offset);
                float yoff = HBFixedToFloat(positions[i].y_offset);
                LayoutGlyph glyph = {font_ix, glyph_ix, x + xoff, y + yoff};
                mGlyphs.push_back(glyph);
                float xAdvance = HBFixedToFloat(positions[i].x_advance);
                MinikinRect glyphBounds;
                paint.font->GetBounds(&glyphBounds, glyph_ix, paint);
                glyphBounds.offset(x + xoff, y + yoff);
                mBounds.join(glyphBounds);
                size_t cluster = info[i].cluster;
                mAdvances[cluster] += xAdvance;
                x += xAdvance;
            }
        }
    }
    mAdvance = x;
}

void Layout::draw(Bitmap* surface, int x0, int y0) const {
    /*
    TODO: redo as MinikinPaint settings
    if (mProps.hasTag(minikinHinting)) {
        int hintflags = mProps.value(minikinHinting).getIntValue();
        if (hintflags & 1) load_flags |= FT_LOAD_NO_HINTING;
        if (hintflags & 2) load_flags |= FT_LOAD_NO_AUTOHINT;
    }
    */
    for (size_t i = 0; i < mGlyphs.size(); i++) {
        const LayoutGlyph& glyph = mGlyphs[i];
        MinikinFont *mf = mFaces[glyph.font_ix];
        MinikinFontFreeType *face = static_cast<MinikinFontFreeType *>(mf);
        GlyphBitmap glyphBitmap;
        MinikinPaint paint;
        paint.size = mProps.value(fontSize).getFloatValue();
        bool ok = face->Render(glyph.glyph_id, paint, &glyphBitmap);
        printf("glyphBitmap.width=%d, glyphBitmap.height=%d (%d, %d) x=%f, y=%f, ok=%d\n",
            glyphBitmap.width, glyphBitmap.height, glyphBitmap.left, glyphBitmap.top, glyph.x, glyph.y, ok);
        if (ok) {
            surface->drawGlyph(glyphBitmap,
                x0 + int(floor(glyph.x + 0.5)), y0 + int(floor(glyph.y + 0.5)));
        }
    }
}

void Layout::setProperties(string css) {
    mProps.parse(css);
}

size_t Layout::nGlyphs() const {
    return mGlyphs.size();
}

MinikinFont *Layout::getFont(int i) const {
    const LayoutGlyph& glyph = mGlyphs[i];
    return mFaces[glyph.font_ix];
}

unsigned int Layout::getGlyphId(int i) const {
    const LayoutGlyph& glyph = mGlyphs[i];
    return glyph.glyph_id;
}

float Layout::getX(int i) const {
    const LayoutGlyph& glyph = mGlyphs[i];
    return glyph.x;
}

float Layout::getY(int i) const {
    const LayoutGlyph& glyph = mGlyphs[i];
    return glyph.y;
}

float Layout::getAdvance() const {
    return mAdvance;
}

void Layout::getAdvances(float* advances) {
    memcpy(advances, &mAdvances[0], mAdvances.size() * sizeof(float));
}

void Layout::getBounds(MinikinRect* bounds) {
    bounds->set(mBounds);
}

}  // namespace android
