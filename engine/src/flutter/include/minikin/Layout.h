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

#ifndef MINIKIN_LAYOUT_H
#define MINIKIN_LAYOUT_H

#include <hb.h>

#include <vector>

#include <minikin/FontCollection.h>
#include <minikin/MinikinFontFreeType.h>

namespace minikin {

// The Bitmap class is for debugging. We'll probably move it out
// of here into a separate lightweight software rendering module
// (optional, as we'd hope most clients would do their own)
class Bitmap {
public:
    Bitmap(int width, int height);
    ~Bitmap();
    void writePnm(std::ofstream& o) const;
    void drawGlyph(const android::GlyphBitmap& bitmap, int x, int y);
private:
    int width;
    int height;
    uint8_t* buf;
};

} // namespace minikin

namespace android {

struct LayoutGlyph {
    // index into mFaces and mHbFonts vectors. We could imagine
    // moving this into a run length representation, because it's
    // more efficient for long strings, and we'll probably need
    // something like that for paint attributes (color, underline,
    // fake b/i, etc), as having those per-glyph is bloated.
    int font_ix;

    unsigned int glyph_id;
    float x;
    float y;
};

// Internal state used during layout operation
class LayoutContext;

enum {
    kBidi_LTR = 0,
    kBidi_RTL = 1,
    kBidi_Default_LTR = 2,
    kBidi_Default_RTL = 3,
    kBidi_Force_LTR = 4,
    kBidi_Force_RTL = 5,

    kBidi_Mask = 0x7
};

// Lifecycle and threading assumptions for Layout:
// The object is assumed to be owned by a single thread; multiple threads
// may not mutate it at the same time.
// The lifetime of the FontCollection set through setFontCollection must
// extend through the lifetime of the Layout object.
class Layout {
public:

    Layout() : mGlyphs(), mAdvances(), mCollection(0), mFaces(), mAdvance(0), mBounds() {
        mBounds.setEmpty();
    }

    // Clears layout, ready to be used again
    void reset();

    void dump() const;
    void setFontCollection(const FontCollection* collection);

    void doLayout(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        int bidiFlags, const FontStyle &style, const MinikinPaint &paint);

    void draw(minikin::Bitmap*, int x0, int y0, float size) const;

    // Deprecated. Nont needed. Remove when callers are removed.
    static void init();

    // public accessors
    size_t nGlyphs() const;
    // Does not bump reference; ownership is still layout
    MinikinFont *getFont(int i) const;
    FontFakery getFakery(int i) const;
    unsigned int getGlyphId(int i) const;
    float getX(int i) const;
    float getY(int i) const;

    float getAdvance() const;

    // Get advances, copying into caller-provided buffer. The size of this
    // buffer must match the length of the string (count arg to doLayout).
    void getAdvances(float* advances);

    // The i parameter is an offset within the buf relative to start, it is < count, where
    // start and count are the parameters to doLayout
    float getCharAdvance(size_t i) const { return mAdvances[i]; }

    void getBounds(MinikinRect* rect);

    // Purge all caches, useful in low memory conditions
    static void purgeCaches();

private:
    friend class LayoutCacheKey;

    // Find a face in the mFaces vector, or create a new entry
    int findFace(FakedFont face, LayoutContext* ctx);

    // Lay out a single bidi run
    void doLayoutRunCached(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        bool isRtl, LayoutContext* ctx, size_t dstStart);

    // Lay out a single word
    void doLayoutWord(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        bool isRtl, LayoutContext* ctx, size_t bufStart);

    // Lay out a single bidi run
    void doLayoutRun(const uint16_t* buf, size_t start, size_t count, size_t bufSize,
        bool isRtl, LayoutContext* ctx);

    // Append another layout (for example, cached value) into this one
    void appendLayout(Layout* src, size_t start);

    std::vector<LayoutGlyph> mGlyphs;
    std::vector<float> mAdvances;

    const FontCollection* mCollection;
    std::vector<FakedFont> mFaces;
    float mAdvance;
    MinikinRect mBounds;
};

}  // namespace android

#endif  // MINIKIN_LAYOUT_H
