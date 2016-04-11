#include <SkTypeface.h>
#include <SkPaint.h>

#include <minikin/MinikinFont.h>
#include "MinikinSkia.h"

namespace android {

MinikinFontSkia::MinikinFontSkia(SkTypeface *typeface) :
    MinikinFont(typeface->uniqueID()),
    mTypeface(typeface) {
}

MinikinFontSkia::~MinikinFontSkia() {
    SkSafeUnref(mTypeface);
}

static void MinikinFontSkia_SetSkiaPaint(SkTypeface* typeface, SkPaint* skPaint, const MinikinPaint& paint) {
    skPaint->setTypeface(typeface);
    skPaint->setTextEncoding(SkPaint::kGlyphID_TextEncoding);
    // TODO: set more paint parameters from Minikin
    skPaint->setTextSize(paint.size);
}

float MinikinFontSkia::GetHorizontalAdvance(uint32_t glyph_id,
    const MinikinPaint &paint) const {
    SkPaint skPaint;
    uint16_t glyph16 = glyph_id;
    SkScalar skWidth;
    MinikinFontSkia_SetSkiaPaint(mTypeface, &skPaint, paint);
    skPaint.getTextWidths(&glyph16, sizeof(glyph16), &skWidth, NULL);
#ifdef VERBOSE
    ALOGD("width for typeface %d glyph %d = %f", mTypeface->uniqueID(), glyph_id
#endif
    return skWidth;
}

void MinikinFontSkia::GetBounds(MinikinRect* bounds, uint32_t glyph_id,
    const MinikinPaint& paint) const {
    SkPaint skPaint;
    uint16_t glyph16 = glyph_id;
    SkRect skBounds;
    MinikinFontSkia_SetSkiaPaint(mTypeface, &skPaint, paint);
    skPaint.getTextWidths(&glyph16, sizeof(glyph16), NULL, &skBounds);
    bounds->mLeft = skBounds.fLeft;
    bounds->mTop = skBounds.fTop;
    bounds->mRight = skBounds.fRight;
    bounds->mBottom = skBounds.fBottom;
}

const void* MinikinFontSkia::GetTable(uint32_t tag, size_t* size, MinikinDestroyFunc* destroy) {
    // we don't have a buffer to the font data, copy to own buffer
    const size_t tableSize = mTypeface->getTableSize(tag);
    *size = tableSize;
    if (tableSize == 0) {
        return nullptr;
    }
    void* buf = malloc(tableSize);
    if (buf == nullptr) {
        return nullptr;
    }
    mTypeface->getTableData(tag, 0, tableSize, buf);
    *destroy = free;
    return buf;
}

SkTypeface *MinikinFontSkia::GetSkTypeface() {
    return mTypeface;
}

}
