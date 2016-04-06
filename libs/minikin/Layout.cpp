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
#include <hb-ot.h>

#include "FontLanguage.h"
#include "FontLanguageListCache.h"
#include "LayoutUtils.h"
#include "HbFontCache.h"
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
            hb_font_set_funcs(hbFonts[i], nullptr, nullptr, nullptr);
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
            mPaintFlags(paint.paintFlags), mHyphenEdit(paint.hyphenEdit), mIsRtl(dir),
            mHash(computeHash()) {
    }
    bool operator==(const LayoutCacheKey &other) const;

    hash_t hash() const {
        return mHash;
    }

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
    hash_t mHash;

    hash_t computeHash() const;
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

hash_t LayoutCacheKey::computeHash() const {
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

static hb_position_t harfbuzzGetGlyphHorizontalAdvance(hb_font_t* /* hbFont */, void* fontData,
        hb_codepoint_t glyph, void* /* userData */) {
    MinikinPaint* paint = reinterpret_cast<MinikinPaint*>(fontData);
    MinikinFont* font = paint->font;
    float advance = font->GetHorizontalAdvance(glyph, *paint);
    return 256 * advance + 0.5;
}

static hb_bool_t harfbuzzGetGlyphHorizontalOrigin(hb_font_t* /* hbFont */, void* /* fontData */,
        hb_codepoint_t /* glyph */, hb_position_t* /* x */, hb_position_t* /* y */,
        void* /* userData */) {
    // Just return true, following the way that Harfbuzz-FreeType
    // implementation does.
    return true;
}

hb_font_funcs_t* getHbFontFuncs() {
    static hb_font_funcs_t* hbFontFuncs = 0;

    if (hbFontFuncs == 0) {
        hbFontFuncs = hb_font_funcs_create();
        hb_font_funcs_set_glyph_h_advance_func(hbFontFuncs, harfbuzzGetGlyphHorizontalAdvance, 0, 0);
        hb_font_funcs_set_glyph_h_origin_func(hbFontFuncs, harfbuzzGetGlyphHorizontalOrigin, 0, 0);
        hb_font_funcs_make_immutable(hbFontFuncs);
    }
    return hbFontFuncs;
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
        hb_font_t* font = getHbFontLocked(face.font);
        hb_font_set_funcs(font, getHbFontFuncs(), &ctx->paint, 0);
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

class BidiText {
public:
    class Iter {
    public:
        struct RunInfo {
            int32_t mRunStart;
            int32_t mRunLength;
            bool mIsRtl;
        };

        Iter(UBiDi* bidi, size_t start, size_t end, size_t runIndex, size_t runCount, bool isRtl);

        bool operator!= (const Iter& other) const {
            return mIsEnd != other.mIsEnd || mNextRunIndex != other.mNextRunIndex
                    || mBidi != other.mBidi;
        }

        const RunInfo& operator* () const {
            return mRunInfo;
        }

        const Iter& operator++ () {
            updateRunInfo();
            return *this;
        }

    private:
        UBiDi* const mBidi;
        bool mIsEnd;
        size_t mNextRunIndex;
        const size_t mRunCount;
        const int32_t mStart;
        const int32_t mEnd;
        RunInfo mRunInfo;

        void updateRunInfo();
    };

    BidiText(const uint16_t* buf, size_t start, size_t count, size_t bufSize, int bidiFlags);

    ~BidiText() {
        if (mBidi) {
            ubidi_close(mBidi);
        }
    }

    Iter begin () const {
        return Iter(mBidi, mStart, mEnd, 0, mRunCount, mIsRtl);
    }

    Iter end() const {
        return Iter(mBidi, mStart, mEnd, mRunCount, mRunCount, mIsRtl);
    }

private:
    const size_t mStart;
    const size_t mEnd;
    const size_t mBufSize;
    UBiDi* mBidi;
    size_t mRunCount;
    bool mIsRtl;

    DISALLOW_COPY_AND_ASSIGN(BidiText);
};

BidiText::Iter::Iter(UBiDi* bidi, size_t start, size_t end, size_t runIndex, size_t runCount,
        bool isRtl)
    : mBidi(bidi), mIsEnd(runIndex == runCount), mNextRunIndex(runIndex), mRunCount(runCount),
      mStart(start), mEnd(end), mRunInfo() {
    if (mRunCount == 1) {
        mRunInfo.mRunStart = start;
        mRunInfo.mRunLength = end - start;
        mRunInfo.mIsRtl = isRtl;
        mNextRunIndex = mRunCount;
        return;
    }
    updateRunInfo();
}

void BidiText::Iter::updateRunInfo() {
    if (mNextRunIndex == mRunCount) {
        // All runs have been iterated.
        mIsEnd = true;
        return;
    }
    int32_t startRun = -1;
    int32_t lengthRun = -1;
    const UBiDiDirection runDir = ubidi_getVisualRun(mBidi, mNextRunIndex, &startRun, &lengthRun);
    mNextRunIndex++;
    if (startRun == -1 || lengthRun == -1) {
        ALOGE("invalid visual run");
        // skip the invalid run.
        updateRunInfo();
        return;
    }
    const int32_t runEnd = std::min(startRun + lengthRun, mEnd);
    mRunInfo.mRunStart = std::max(startRun, mStart);
    mRunInfo.mRunLength = runEnd - mRunInfo.mRunStart;
    if (mRunInfo.mRunLength <= 0) {
        // skip the empty run.
        updateRunInfo();
        return;
    }
    mRunInfo.mIsRtl = (runDir == UBIDI_RTL);
}

BidiText::BidiText(const uint16_t* buf, size_t start, size_t count, size_t bufSize, int bidiFlags)
    : mStart(start), mEnd(start + count), mBufSize(bufSize), mBidi(NULL), mRunCount(1),
      mIsRtl((bidiFlags & kDirection_Mask) != 0) {
    if (bidiFlags == kBidi_Force_LTR || bidiFlags == kBidi_Force_RTL) {
        // force single run.
        return;
    }
    mBidi = ubidi_open();
    if (!mBidi) {
        ALOGE("error creating bidi object");
        return;
    }
    UErrorCode status = U_ZERO_ERROR;
    UBiDiLevel bidiReq = bidiFlags;
    if (bidiFlags == kBidi_Default_LTR) {
        bidiReq = UBIDI_DEFAULT_LTR;
    } else if (bidiFlags == kBidi_Default_RTL) {
        bidiReq = UBIDI_DEFAULT_RTL;
    }
    ubidi_setPara(mBidi, buf, mBufSize, bidiReq, NULL, &status);
    if (!U_SUCCESS(status)) {
        ALOGE("error calling ubidi_setPara, status = %d", status);
        return;
    }
    const int paraDir = ubidi_getParaLevel(mBidi) & kDirection_Mask;
    const ssize_t rc = ubidi_countRuns(mBidi, &status);
    if (!U_SUCCESS(status) || rc < 0) {
        ALOGW("error counting bidi runs, status = %d", status);
    }
    if (!U_SUCCESS(status) || rc <= 1) {
        mIsRtl = (paraDir == kBidi_RTL);
        return;
    }
    mRunCount = rc;
}

void Layout::doLayout(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        int bidiFlags, const FontStyle &style, const MinikinPaint &paint) {
    AutoMutex _l(gMinikinLock);

    LayoutContext ctx;
    ctx.style = style;
    ctx.paint = paint;

    reset();
    mAdvances.resize(count, 0);

    for (const BidiText::Iter::RunInfo& runInfo : BidiText(buf, start, count, bufSize, bidiFlags)) {
        doLayoutRunCached(buf, runInfo.mRunStart, runInfo.mRunLength, bufSize, runInfo.mIsRtl, &ctx,
                start, mCollection, this, NULL);
    }
    ctx.clearHbFonts();
}

float Layout::measureText(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        int bidiFlags, const FontStyle &style, const MinikinPaint &paint,
        const FontCollection* collection, float* advances) {
    AutoMutex _l(gMinikinLock);

    LayoutContext ctx;
    ctx.style = style;
    ctx.paint = paint;

    float advance = 0;
    for (const BidiText::Iter::RunInfo& runInfo : BidiText(buf, start, count, bufSize, bidiFlags)) {
        float* advancesForRun = advances ? advances + (runInfo.mRunStart - start) : advances;
        advance += doLayoutRunCached(buf, runInfo.mRunStart, runInfo.mRunLength, bufSize,
                runInfo.mIsRtl, &ctx, 0, collection, NULL, advancesForRun);
    }

    ctx.clearHbFonts();
    return advance;
}

float Layout::doLayoutRunCached(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        bool isRtl, LayoutContext* ctx, size_t dstStart, const FontCollection* collection,
        Layout* layout, float* advances) {
    HyphenEdit hyphen = ctx->paint.hyphenEdit;
    float advance = 0;
    if (!isRtl) {
        // left to right
        size_t wordstart =
                start == bufSize ? start : getPrevWordBreakForCache(buf, start + 1, bufSize);
        size_t wordend;
        for (size_t iter = start; iter < start + count; iter = wordend) {
            wordend = getNextWordBreakForCache(buf, iter, bufSize);
            // Only apply hyphen to the last word in the string.
            ctx->paint.hyphenEdit = wordend >= start + count ? hyphen : HyphenEdit();
            size_t wordcount = std::min(start + count, wordend) - iter;
            advance += doLayoutWord(buf + wordstart, iter - wordstart, wordcount,
                    wordend - wordstart, isRtl, ctx, iter - dstStart, collection, layout,
                    advances ? advances + (iter - start) : advances);
            wordstart = wordend;
        }
    } else {
        // right to left
        size_t wordstart;
        size_t end = start + count;
        size_t wordend = end == 0 ? 0 : getNextWordBreakForCache(buf, end - 1, bufSize);
        for (size_t iter = end; iter > start; iter = wordstart) {
            wordstart = getPrevWordBreakForCache(buf, iter, bufSize);
            // Only apply hyphen to the last (leftmost) word in the string.
            ctx->paint.hyphenEdit = iter == end ? hyphen : HyphenEdit();
            size_t bufStart = std::max(start, wordstart);
            advance += doLayoutWord(buf + wordstart, bufStart - wordstart, iter - bufStart,
                    wordend - wordstart, isRtl, ctx, bufStart - dstStart, collection, layout,
                    advances ? advances + (bufStart - start) : advances);
            wordend = wordstart;
        }
    }
    return advance;
}

float Layout::doLayoutWord(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        bool isRtl, LayoutContext* ctx, size_t bufStart, const FontCollection* collection,
        Layout* layout, float* advances) {
    LayoutCache& cache = LayoutEngine::getInstance().layoutCache;
    LayoutCacheKey key(collection, ctx->paint, ctx->style, buf, start, count, bufSize, isRtl);
    bool skipCache = ctx->paint.skipCache();
    if (skipCache) {
        Layout layoutForWord;
        key.doLayout(&layoutForWord, ctx, collection);
        if (layout) {
            layout->appendLayout(&layoutForWord, bufStart);
        }
        if (advances) {
            layoutForWord.getAdvances(advances);
        }
        return layoutForWord.getAdvance();
    } else {
        Layout* layoutForWord = cache.get(key, ctx, collection);
        if (layout) {
            layout->appendLayout(layoutForWord, bufStart);
        }
        if (advances) {
            layoutForWord->getAdvances(advances);
        }
        return layoutForWord->getAdvance();
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
#ifdef VERBOSE_DEBUG
        ALOGD("Run %zu, font %d [%d:%d]", run_ix, font_ix, run.start, run.end);
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
            const FontLanguages& langList =
                    FontLanguageListCache::getById(ctx->style.getLanguageListId());
            if (langList.size() != 0) {
                const FontLanguage* hbLanguage = &langList[0];
                for (size_t i = 0; i < langList.size(); ++i) {
                    if (langList[i].supportsHbScript(script)) {
                        hbLanguage = &langList[i];
                        break;
                    }
                }
                hb_buffer_set_language(buffer,
                        hb_language_from_string(hbLanguage->getString().c_str(), -1));
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
#ifdef VERBOSE_DEBUG
                ALOGD("%d %d %d %d",
                        positions[i].x_advance, positions[i].y_advance,
                        positions[i].x_offset, positions[i].y_offset);
                ALOGD("DoLayout %u: %f; %d, %d",
                        info[i].codepoint, HBFixedToFloat(positions[i].x_advance),
                        positions[i].x_offset, positions[i].y_offset);
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
                    ALOGE("cluster %zu (start %zu) out of bounds of count %zu",
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
#ifdef VERBOSE_DEBUG
        ALOGD("glyphBitmap.width=%d, glyphBitmap.height=%d (%d, %d) x=%f, y=%f, ok=%d",
            glyphBitmap.width, glyphBitmap.height, glyphBitmap.left, glyphBitmap.top, glyph.x, glyph.y, ok);
#endif
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
    purgeHbFontCacheLocked();
}

}  // namespace android
