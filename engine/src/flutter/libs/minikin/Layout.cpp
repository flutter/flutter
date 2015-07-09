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

#include <math.h>
#include <stdio.h>  // for debugging

#include <algorithm>
#include <fstream>
#include <iostream>  // for debugging
#include <string>
#include <vector>

#include <utils/JenkinsHash.h>
#include <utils/LruCache.h>
#include <utils/Singleton.h>
#include <utils/String16.h>

#include <unicode/ubidi.h>
#include <hb-icu.h>

#include "MinikinInternal.h"
#include <minikin/MinikinFontFreeType.h>
#include <minikin/Layout.h>

using std::string;
using std::vector;

namespace minikin {

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

void Bitmap::drawGlyph(const android::GlyphBitmap& bitmap, int x, int y) {
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

} // namespace minikin

namespace android {

const int kDirection_Mask = 0x1;

struct LayoutContext {
    MinikinPaint paint;
    FontStyle style;
    std::vector<hb_font_t*> hbFonts;  // parallel to mFaces

    void clearHbFonts() {
        for (size_t i = 0; i < hbFonts.size(); i++) {
            hb_font_destroy(hbFonts[i]);
        }
        hbFonts.clear();
    }
};

// Layout cache datatypes

class LayoutCacheKey {
public:
    LayoutCacheKey(const FontCollection* collection, const MinikinPaint& paint, FontStyle style,
            const uint16_t* chars, size_t start, size_t count, size_t nchars, bool dir)
            : mChars(chars), mNchars(nchars),
            mStart(start), mCount(count), mId(collection->getId()), mStyle(style),
            mSize(paint.size), mScaleX(paint.scaleX), mSkewX(paint.skewX),
            mLetterSpacing(paint.letterSpacing),
            mPaintFlags(paint.paintFlags), mHyphenEdit(paint.hyphenEdit), mIsRtl(dir) {
    }
    bool operator==(const LayoutCacheKey &other) const;
    hash_t hash() const;

    void copyText() {
        uint16_t* charsCopy = new uint16_t[mNchars];
        memcpy(charsCopy, mChars, mNchars * sizeof(uint16_t));
        mChars = charsCopy;
    }
    void freeText() {
        delete[] mChars;
        mChars = NULL;
    }

    void doLayout(Layout* layout, LayoutContext* ctx, const FontCollection* collection) const {
        layout->setFontCollection(collection);
        layout->mAdvances.resize(mCount, 0);
        ctx->clearHbFonts();
        layout->doLayoutRun(mChars, mStart, mCount, mNchars, mIsRtl, ctx);
    }

private:
    const uint16_t* mChars;
    size_t mNchars;
    size_t mStart;
    size_t mCount;
    uint32_t mId;  // for the font collection
    FontStyle mStyle;
    float mSize;
    float mScaleX;
    float mSkewX;
    float mLetterSpacing;
    int32_t mPaintFlags;
    HyphenEdit mHyphenEdit;
    bool mIsRtl;
    // Note: any fields added to MinikinPaint must also be reflected here.
    // TODO: language matching (possibly integrate into style)
};

class LayoutCache : private OnEntryRemoved<LayoutCacheKey, Layout*> {
public:
    LayoutCache() : mCache(kMaxEntries) {
        mCache.setOnEntryRemovedListener(this);
    }

    void clear() {
        mCache.clear();
    }

    Layout* get(LayoutCacheKey& key, LayoutContext* ctx, const FontCollection* collection) {
        Layout* layout = mCache.get(key);
        if (layout == NULL) {
            key.copyText();
            layout = new Layout();
            key.doLayout(layout, ctx, collection);
            mCache.put(key, layout);
        }
        return layout;
    }

private:
    // callback for OnEntryRemoved
    void operator()(LayoutCacheKey& key, Layout*& value) {
        key.freeText();
        delete value;
    }

    LruCache<LayoutCacheKey, Layout*> mCache;

    //static const size_t kMaxEntries = LruCache<LayoutCacheKey, Layout*>::kUnlimitedCapacity;

    // TODO: eviction based on memory footprint; for now, we just use a constant
    // number of strings
    static const size_t kMaxEntries = 5000;
};

class HbFaceCache : private OnEntryRemoved<int32_t, hb_face_t*> {
public:
    HbFaceCache() : mCache(kMaxEntries) {
        mCache.setOnEntryRemovedListener(this);
    }

    // callback for OnEntryRemoved
    void operator()(int32_t& key, hb_face_t*& value) {
        hb_face_destroy(value);
    }

    LruCache<int32_t, hb_face_t*> mCache;
private:
    static const size_t kMaxEntries = 100;
};

static unsigned int disabledDecomposeCompatibility(hb_unicode_funcs_t*, hb_codepoint_t,
                                                   hb_codepoint_t*, void*) {
    return 0;
}

class LayoutEngine : public Singleton<LayoutEngine> {
public:
    LayoutEngine() {
        unicodeFunctions = hb_unicode_funcs_create(hb_icu_get_unicode_funcs());
        /* Disable the function used for compatibility decomposition */
        hb_unicode_funcs_set_decompose_compatibility_func(
                unicodeFunctions, disabledDecomposeCompatibility, NULL, NULL);
        hbBuffer = hb_buffer_create();
        hb_buffer_set_unicode_funcs(hbBuffer, unicodeFunctions);
    }

    hb_buffer_t* hbBuffer;
    hb_unicode_funcs_t* unicodeFunctions;
    LayoutCache layoutCache;
    HbFaceCache hbFaceCache;
};

ANDROID_SINGLETON_STATIC_INSTANCE(LayoutEngine);

bool LayoutCacheKey::operator==(const LayoutCacheKey& other) const {
    return mId == other.mId
            && mStart == other.mStart
            && mCount == other.mCount
            && mStyle == other.mStyle
            && mSize == other.mSize
            && mScaleX == other.mScaleX
            && mSkewX == other.mSkewX
            && mLetterSpacing == other.mLetterSpacing
            && mPaintFlags == other.mPaintFlags
            && mHyphenEdit == other.mHyphenEdit
            && mIsRtl == other.mIsRtl
            && mNchars == other.mNchars
            && !memcmp(mChars, other.mChars, mNchars * sizeof(uint16_t));
}

hash_t LayoutCacheKey::hash() const {
    uint32_t hash = JenkinsHashMix(0, mId);
    hash = JenkinsHashMix(hash, mStart);
    hash = JenkinsHashMix(hash, mCount);
    hash = JenkinsHashMix(hash, hash_type(mStyle));
    hash = JenkinsHashMix(hash, hash_type(mSize));
    hash = JenkinsHashMix(hash, hash_type(mScaleX));
    hash = JenkinsHashMix(hash, hash_type(mSkewX));
    hash = JenkinsHashMix(hash, hash_type(mLetterSpacing));
    hash = JenkinsHashMix(hash, hash_type(mPaintFlags));
    hash = JenkinsHashMix(hash, hash_type(mHyphenEdit.hasHyphen()));
    hash = JenkinsHashMix(hash, hash_type(mIsRtl));
    hash = JenkinsHashMixShorts(hash, mChars, mNchars);
    return JenkinsHashWhiten(hash);
}

hash_t hash_type(const LayoutCacheKey& key) {
    return key.hash();
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

// Deprecated. Remove when callers are removed.
void Layout::init() {
}

void Layout::reset() {
    mGlyphs.clear();
    mFaces.clear();
    mBounds.setEmpty();
    mAdvances.clear();
    mAdvance = 0;
}

void Layout::setFontCollection(const FontCollection* collection) {
    mCollection = collection;
}

hb_blob_t* referenceTable(hb_face_t* face, hb_tag_t tag, void* userData)  {
    MinikinFont* font = reinterpret_cast<MinikinFont*>(userData);
    size_t length = 0;
    bool ok = font->GetTable(tag, NULL, &length);
    if (!ok) {
        return 0;
    }
    char* buffer = reinterpret_cast<char*>(malloc(length));
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
    MinikinPaint* paint = reinterpret_cast<MinikinPaint*>(fontData);
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
    MinikinPaint* paint = reinterpret_cast<MinikinPaint*>(fontData);
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

static hb_face_t* getHbFace(MinikinFont* minikinFont) {
    HbFaceCache& cache = LayoutEngine::getInstance().hbFaceCache;
    int32_t fontId = minikinFont->GetUniqueId();
    hb_face_t* face = cache.mCache.get(fontId);
    if (face == NULL) {
        face = hb_face_create_for_tables(referenceTable, minikinFont, NULL);
        cache.mCache.put(fontId, face);
    }
    return face;
}

static hb_font_t* create_hb_font(MinikinFont* minikinFont, MinikinPaint* minikinPaint) {
    hb_face_t* face = getHbFace(minikinFont);
    hb_font_t* font = hb_font_create(face);
    hb_font_set_funcs(font, getHbFontFuncs(), minikinPaint, 0);
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

void Layout::dump() const {
    for (size_t i = 0; i < mGlyphs.size(); i++) {
        const LayoutGlyph& glyph = mGlyphs[i];
        std::cout << glyph.glyph_id << ": " << glyph.x << ", " << glyph.y << std::endl;
    }
}

int Layout::findFace(FakedFont face, LayoutContext* ctx) {
    unsigned int ix;
    for (ix = 0; ix < mFaces.size(); ix++) {
        if (mFaces[ix].font == face.font) {
            return ix;
        }
    }
    mFaces.push_back(face);
    // Note: ctx == NULL means we're copying from the cache, no need to create
    // corresponding hb_font object.
    if (ctx != NULL) {
        hb_font_t* font = create_hb_font(face.font, &ctx->paint);
        ctx->hbFonts.push_back(font);
    }
    return ix;
}

static hb_script_t codePointToScript(hb_codepoint_t codepoint) {
    static hb_unicode_funcs_t* u = 0;
    if (!u) {
        u = LayoutEngine::getInstance().unicodeFunctions;
    }
    return hb_unicode_script(u, codepoint);
}

static hb_codepoint_t decodeUtf16(const uint16_t* chars, size_t len, ssize_t* iter) {
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
            (*iter) -= 1;
            return 0xFFFDu;
        } else {
            return 0xFFFDu;
        }
    } else {
        return v;
    }
}

static hb_script_t getScriptRun(const uint16_t* chars, size_t len, ssize_t* iter) {
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

/**
 * For the purpose of layout, a word break is a boundary with no
 * kerning or complex script processing. This is necessarily a
 * heuristic, but should be accurate most of the time.
 */
static bool isWordBreak(int c) {
    if (c == ' ' || (c >= 0x2000 && c <= 0x200a) || c == 0x3000) {
        // spaces
        return true;
    }
    if ((c >= 0x3400 && c <= 0x9fff)) {
        // CJK ideographs (and yijing hexagram symbols)
        return true;
    }
    // Note: kana is not included, as sophisticated fonts may kern kana
    return false;
}

/**
 * Return offset of previous word break. It is either < offset or == 0.
 */
static size_t getPrevWordBreak(const uint16_t* chars, size_t offset) {
    if (offset == 0) return 0;
    if (isWordBreak(chars[offset - 1])) {
        return offset - 1;
    }
    for (size_t i = offset - 1; i > 0; i--) {
        if (isWordBreak(chars[i - 1])) {
            return i;
        }
    }
    return 0;
}

/**
 * Return offset of next word break. It is either > offset or == len.
 */
static size_t getNextWordBreak(const uint16_t* chars, size_t offset, size_t len) {
    if (offset >= len) return len;
    if (isWordBreak(chars[offset])) {
        return offset + 1;
    }
    for (size_t i = offset + 1; i < len; i++) {
        if (isWordBreak(chars[i])) {
            return i;
        }
    }
    return len;
}

/**
 * Disable certain scripts (mostly those with cursive connection) from having letterspacing
 * applied. See https://github.com/behdad/harfbuzz/issues/64 for more details.
 */
static bool isScriptOkForLetterspacing(hb_script_t script) {
    return !(
            script == HB_SCRIPT_ARABIC ||
            script == HB_SCRIPT_NKO ||
            script == HB_SCRIPT_PSALTER_PAHLAVI ||
            script == HB_SCRIPT_MANDAIC ||
            script == HB_SCRIPT_MONGOLIAN ||
            script == HB_SCRIPT_PHAGS_PA ||
            script == HB_SCRIPT_DEVANAGARI ||
            script == HB_SCRIPT_BENGALI ||
            script == HB_SCRIPT_GURMUKHI ||
            script == HB_SCRIPT_MODI ||
            script == HB_SCRIPT_SHARADA ||
            script == HB_SCRIPT_SYLOTI_NAGRI ||
            script == HB_SCRIPT_TIRHUTA ||
            script == HB_SCRIPT_OGHAM
            );
}

void Layout::doLayout(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        int bidiFlags, const FontStyle &style, const MinikinPaint &paint) {
    AutoMutex _l(gMinikinLock);

    LayoutContext ctx;
    ctx.style = style;
    ctx.paint = paint;

    bool isRtl = (bidiFlags & kDirection_Mask) != 0;
    bool doSingleRun = true;

    reset();
    mAdvances.resize(count, 0);

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
            ubidi_setPara(bidi, buf, bufSize, bidiReq, NULL, &status);
            if (U_SUCCESS(status)) {
                int paraDir = ubidi_getParaLevel(bidi) & kDirection_Mask;
                ssize_t rc = ubidi_countRuns(bidi, &status);
                if (!U_SUCCESS(status) || rc < 0) {
                    ALOGW("error counting bidi runs, status = %d", status);
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
                            // skip the invalid run
                            continue;
                        }
                        int32_t endRun = std::min(startRun + lengthRun, int32_t(start + count));
                        startRun = std::max(startRun, int32_t(start));
                        lengthRun = endRun - startRun;
                        if (lengthRun > 0) {
                            isRtl = (runDir == UBIDI_RTL);
                            doLayoutRunCached(buf, startRun, lengthRun, bufSize, isRtl, &ctx,
                                start);
                        }
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
        doLayoutRunCached(buf, start, count, bufSize, isRtl, &ctx, start);
    }
    ctx.clearHbFonts();
}

void Layout::doLayoutRunCached(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        bool isRtl, LayoutContext* ctx, size_t dstStart) {
    HyphenEdit hyphen = ctx->paint.hyphenEdit;
    if (!isRtl) {
        // left to right
        size_t wordstart = start == bufSize ? start : getPrevWordBreak(buf, start + 1);
        size_t wordend;
        for (size_t iter = start; iter < start + count; iter = wordend) {
            wordend = getNextWordBreak(buf, iter, bufSize);
            // Only apply hyphen to the last word in the string.
            ctx->paint.hyphenEdit = wordend >= start + count ? hyphen : HyphenEdit();
            size_t wordcount = std::min(start + count, wordend) - iter;
            doLayoutWord(buf + wordstart, iter - wordstart, wordcount, wordend - wordstart,
                    isRtl, ctx, iter - dstStart);
            wordstart = wordend;
        }
    } else {
        // right to left
        size_t wordstart;
        size_t end = start + count;
        size_t wordend = end == 0 ? 0 : getNextWordBreak(buf, end - 1, bufSize);
        for (size_t iter = end; iter > start; iter = wordstart) {
            wordstart = getPrevWordBreak(buf, iter);
            // Only apply hyphen to the last (leftmost) word in the string.
            ctx->paint.hyphenEdit = iter == end ? hyphen : HyphenEdit();
            size_t bufStart = std::max(start, wordstart);
            doLayoutWord(buf + wordstart, bufStart - wordstart, iter - bufStart,
                    wordend - wordstart, isRtl, ctx, bufStart - dstStart);
            wordend = wordstart;
        }
    }
}

void Layout::doLayoutWord(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        bool isRtl, LayoutContext* ctx, size_t bufStart) {
    LayoutCache& cache = LayoutEngine::getInstance().layoutCache;
    LayoutCacheKey key(mCollection, ctx->paint, ctx->style, buf, start, count, bufSize, isRtl);
    bool skipCache = ctx->paint.skipCache();
    if (skipCache) {
        Layout layout;
        key.doLayout(&layout, ctx, mCollection);
        appendLayout(&layout, bufStart);
    } else {
        Layout* layout = cache.get(key, ctx, mCollection);
        appendLayout(layout, bufStart);
    }
}

static void addFeatures(const string &str, vector<hb_feature_t>* features) {
    if (!str.size())
        return;

    const char* start = str.c_str();
    const char* end = start + str.size();

    while (start < end) {
        static hb_feature_t feature;
        const char* p = strchr(start, ',');
        if (!p)
            p = end;
        /* We do not allow setting features on ranges.  As such, reject any
         * setting that has non-universal range. */
        if (hb_feature_from_string (start, p - start, &feature)
                && feature.start == 0 && feature.end == (unsigned int) -1)
            features->push_back(feature);
        start = p + 1;
    }
}

void Layout::doLayoutRun(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        bool isRtl, LayoutContext* ctx) {
    hb_buffer_t* buffer = LayoutEngine::getInstance().hbBuffer;
    vector<FontCollection::Run> items;
    mCollection->itemize(buf + start, count, ctx->style, &items);
    if (isRtl) {
        std::reverse(items.begin(), items.end());
    }

    vector<hb_feature_t> features;
    // Disable default-on non-required ligature features if letter-spacing
    // See http://dev.w3.org/csswg/css-text-3/#letter-spacing-property
    // "When the effective spacing between two characters is not zero (due to
    // either justification or a non-zero value of letter-spacing), user agents
    // should not apply optional ligatures."
    if (fabs(ctx->paint.letterSpacing) > 0.03)
    {
        static const hb_feature_t no_liga = { HB_TAG('l', 'i', 'g', 'a'), 0, 0, ~0u };
        static const hb_feature_t no_clig = { HB_TAG('c', 'l', 'i', 'g'), 0, 0, ~0u };
        features.push_back(no_liga);
        features.push_back(no_clig);
    }
    addFeatures(ctx->paint.fontFeatureSettings, &features);

    double size = ctx->paint.size;
    double scaleX = ctx->paint.scaleX;

    float x = mAdvance;
    float y = 0;
    for (size_t run_ix = 0; run_ix < items.size(); run_ix++) {
        FontCollection::Run &run = items[run_ix];
        if (run.fakedFont.font == NULL) {
            ALOGE("no font for run starting u+%04x length %d", buf[run.start], run.end - run.start);
            continue;
        }
        int font_ix = findFace(run.fakedFont, ctx);
        ctx->paint.font = mFaces[font_ix].font;
        ctx->paint.fakery = mFaces[font_ix].fakery;
        hb_font_t* hbFont = ctx->hbFonts[font_ix];
#ifdef VERBOSE
        std::cout << "Run " << run_ix << ", font " << font_ix <<
            " [" << run.start << ":" << run.end << "]" << std::endl;
#endif

        hb_font_set_ppem(hbFont, size * scaleX, size);
        hb_font_set_scale(hbFont, HBFloatToFixed(size * scaleX), HBFloatToFixed(size));

        // TODO: if there are multiple scripts within a font in an RTL run,
        // we need to reorder those runs. This is unlikely with our current
        // font stack, but should be done for correctness.
        ssize_t srunend;
        for (ssize_t srunstart = run.start; srunstart < run.end; srunstart = srunend) {
            srunend = srunstart;
            hb_script_t script = getScriptRun(buf + start, run.end, &srunend);

            double letterSpace = 0.0;
            double letterSpaceHalfLeft = 0.0;
            double letterSpaceHalfRight = 0.0;

            if (ctx->paint.letterSpacing != 0.0 && isScriptOkForLetterspacing(script)) {
                letterSpace = ctx->paint.letterSpacing * size * scaleX;
                if ((ctx->paint.paintFlags & LinearTextFlag) == 0) {
                    letterSpace = round(letterSpace);
                    letterSpaceHalfLeft = floor(letterSpace * 0.5);
                } else {
                    letterSpaceHalfLeft = letterSpace * 0.5;
                }
                letterSpaceHalfRight = letterSpace - letterSpaceHalfLeft;
            }

            hb_buffer_clear_contents(buffer);
            hb_buffer_set_script(buffer, script);
            hb_buffer_set_direction(buffer, isRtl? HB_DIRECTION_RTL : HB_DIRECTION_LTR);
            FontLanguage language = ctx->style.getLanguage();
            if (language) {
                string lang = language.getString();
                hb_buffer_set_language(buffer, hb_language_from_string(lang.c_str(), -1));
            }
            hb_buffer_add_utf16(buffer, buf, bufSize, srunstart + start, srunend - srunstart);
            if (ctx->paint.hyphenEdit.hasHyphen() && srunend > srunstart) {
                // TODO: check whether this is really the desired semantics. It could have the
                // effect of assigning the hyphen width to a nonspacing mark
                unsigned int lastCluster = start + srunend - 1;

                hb_codepoint_t hyphenChar = 0x2010; // HYPHEN
                hb_codepoint_t glyph;
                // Fallback to ASCII HYPHEN-MINUS if the font didn't have a glyph for HYPHEN. Note
                // that we intentionally don't do anything special if the font doesn't have a
                // HYPHEN-MINUS either, so a tofu could be shown, hinting towards something
                // missing.
                if (!hb_font_get_glyph(hbFont, hyphenChar, 0, &glyph)) {
                    hyphenChar = 0x002D; // HYPHEN-MINUS
                }
                hb_buffer_add(buffer, hyphenChar, lastCluster);
            }
            hb_shape(hbFont, buffer, features.empty() ? NULL : &features[0], features.size());
            unsigned int numGlyphs;
            hb_glyph_info_t* info = hb_buffer_get_glyph_infos(buffer, &numGlyphs);
            hb_glyph_position_t* positions = hb_buffer_get_glyph_positions(buffer, NULL);
            if (numGlyphs)
            {
                mAdvances[info[0].cluster - start] += letterSpaceHalfLeft;
                x += letterSpaceHalfLeft;
            }
            for (unsigned int i = 0; i < numGlyphs; i++) {
    #ifdef VERBOSE
                std::cout << positions[i].x_advance << " " << positions[i].y_advance << " " << positions[i].x_offset << " " << positions[i].y_offset << std::endl;            std::cout << "DoLayout " << info[i].codepoint <<
                ": " << HBFixedToFloat(positions[i].x_advance) << "; " << positions[i].x_offset << ", " << positions[i].y_offset << std::endl;
    #endif
                if (i > 0 && info[i - 1].cluster != info[i].cluster) {
                    mAdvances[info[i - 1].cluster - start] += letterSpaceHalfRight;
                    mAdvances[info[i].cluster - start] += letterSpaceHalfLeft;
                    x += letterSpace;
                }

                hb_codepoint_t glyph_ix = info[i].codepoint;
                float xoff = HBFixedToFloat(positions[i].x_offset);
                float yoff = -HBFixedToFloat(positions[i].y_offset);
                xoff += yoff * ctx->paint.skewX;
                LayoutGlyph glyph = {font_ix, glyph_ix, x + xoff, y + yoff};
                mGlyphs.push_back(glyph);
                float xAdvance = HBFixedToFloat(positions[i].x_advance);
                if ((ctx->paint.paintFlags & LinearTextFlag) == 0) {
                    xAdvance = roundf(xAdvance);
                }
                MinikinRect glyphBounds;
                ctx->paint.font->GetBounds(&glyphBounds, glyph_ix, ctx->paint);
                glyphBounds.offset(x + xoff, y + yoff);
                mBounds.join(glyphBounds);
                if (info[i].cluster - start < count) {
                    mAdvances[info[i].cluster - start] += xAdvance;
                } else {
                    ALOGE("cluster %d (start %d) out of bounds of count %d",
                        info[i].cluster - start, start, count);
                }
                x += xAdvance;
            }
            if (numGlyphs)
            {
                mAdvances[info[numGlyphs - 1].cluster - start] += letterSpaceHalfRight;
                x += letterSpaceHalfRight;
            }
        }
    }
    mAdvance = x;
}

void Layout::appendLayout(Layout* src, size_t start) {
    int fontMapStack[16];
    int* fontMap;
    if (src->mFaces.size() < sizeof(fontMapStack) / sizeof(fontMapStack[0])) {
        fontMap = fontMapStack;
    } else {
        fontMap = new int[src->mFaces.size()];
    }
    for (size_t i = 0; i < src->mFaces.size(); i++) {
        int font_ix = findFace(src->mFaces[i], NULL);
        fontMap[i] = font_ix;
    }
    int x0 = mAdvance;
    for (size_t i = 0; i < src->mGlyphs.size(); i++) {
        LayoutGlyph& srcGlyph = src->mGlyphs[i];
        int font_ix = fontMap[srcGlyph.font_ix];
        unsigned int glyph_id = srcGlyph.glyph_id;
        float x = x0 + srcGlyph.x;
        float y = srcGlyph.y;
        LayoutGlyph glyph = {font_ix, glyph_id, x, y};
        mGlyphs.push_back(glyph);
    }
    for (size_t i = 0; i < src->mAdvances.size(); i++) {
        mAdvances[i + start] = src->mAdvances[i];
    }
    MinikinRect srcBounds(src->mBounds);
    srcBounds.offset(x0, 0);
    mBounds.join(srcBounds);
    mAdvance += src->mAdvance;

    if (fontMap != fontMapStack) {
        delete[] fontMap;
    }
}

void Layout::draw(minikin::Bitmap* surface, int x0, int y0, float size) const {
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
        MinikinFont* mf = mFaces[glyph.font_ix].font;
        MinikinFontFreeType* face = static_cast<MinikinFontFreeType*>(mf);
        GlyphBitmap glyphBitmap;
        MinikinPaint paint;
        paint.size = size;
        bool ok = face->Render(glyph.glyph_id, paint, &glyphBitmap);
        printf("glyphBitmap.width=%d, glyphBitmap.height=%d (%d, %d) x=%f, y=%f, ok=%d\n",
            glyphBitmap.width, glyphBitmap.height, glyphBitmap.left, glyphBitmap.top, glyph.x, glyph.y, ok);
        if (ok) {
            surface->drawGlyph(glyphBitmap,
                x0 + int(floor(glyph.x + 0.5)), y0 + int(floor(glyph.y + 0.5)));
        }
    }
}

size_t Layout::nGlyphs() const {
    return mGlyphs.size();
}

MinikinFont* Layout::getFont(int i) const {
    const LayoutGlyph& glyph = mGlyphs[i];
    return mFaces[glyph.font_ix].font;
}

FontFakery Layout::getFakery(int i) const {
    const LayoutGlyph& glyph = mGlyphs[i];
    return mFaces[glyph.font_ix].fakery;
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

void Layout::purgeCaches() {
    AutoMutex _l(gMinikinLock);
    LayoutCache& layoutCache = LayoutEngine::getInstance().layoutCache;
    layoutCache.clear();
    HbFaceCache& hbCache = LayoutEngine::getInstance().hbFaceCache;
    hbCache.mCache.clear();
}

}  // namespace android
