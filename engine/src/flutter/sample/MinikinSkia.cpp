#include <SkTypeface.h>
#include <SkPaint.h>

#include <minikin/MinikinFont.h>
#include "MinikinSkia.h"

namespace android {

MinikinFontSkia::MinikinFontSkia(SkTypeface *typeface) :
    mTypeface(typeface) {
}

MinikinFontSkia::~MinikinFontSkia() {
    SkSafeUnref(mTypeface);
}

bool MinikinFontSkia::GetGlyph(uint32_t codepoint, uint32_t *glyph) const {
    SkPaint paint;
    paint.setTypeface(mTypeface);
    paint.setTextEncoding(SkPaint::kUTF32_TextEncoding);
    uint16_t glyph16;
    paint.textToGlyphs(&codepoint, sizeof(codepoint), &glyph16);
    *glyph  = glyph16;
    //printf("glyph for U+%04x = %d\n", codepoint, glyph16);
    return !!glyph;
}

float MinikinFontSkia::GetHorizontalAdvance(uint32_t glyph_id,
    const MinikinPaint &paint) const {
    SkPaint skpaint;
    skpaint.setTypeface(mTypeface);
    skpaint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
    // TODO: set paint from Minikin
    skpaint.setTextSize(100);
    uint16_t glyph16 = glyph_id;
    SkScalar skWidth;
    SkRect skBounds;
    skpaint.getTextWidths(&glyph16, sizeof(glyph16), &skWidth, &skBounds);
    // bounds?
    //printf("advance for glyph %d = %f\n", glyph_id, SkScalarToFP(skWidth));
    return skWidth;
}

bool MinikinFontSkia::GetTable(uint32_t tag, uint8_t *buf, size_t *size) {
    if (buf == NULL) {
        const size_t tableSize = mTypeface->getTableSize(tag);
        *size = tableSize;
        return tableSize != 0;
    } else {
        const size_t actualSize = mTypeface->getTableData(tag, 0, *size, buf);
        *size = actualSize;
        return actualSize != 0;
    }
}

SkTypeface *MinikinFontSkia::GetSkTypeface() {
    return mTypeface;
}

int32_t MinikinFontSkia::GetUniqueId() const {
    return mTypeface->uniqueID();
}

}
