/*
 * Copyright (c) 2007, 2008, 2010 Google Inc. All rights reserved.
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
#include "platform/fonts/Font.h"

#include "platform/NotImplemented.h"
#include "platform/fonts/FontPlatformFeatures.h"
#include "platform/fonts/SimpleFontData.h"
#include "platform/fonts/harfbuzz/HarfBuzzShaper.h"
#include "platform/fonts/GlyphBuffer.h"
#include "platform/geometry/FloatRect.h"
#include "platform/graphics/GraphicsContext.h"

#include "SkPaint.h"
#include "SkTemplates.h"

#include "wtf/unicode/Unicode.h"

#include <algorithm>

namespace blink {

bool FontPlatformFeatures::canExpandAroundIdeographsInComplexText()
{
    return false;
}

static SkPaint textFillPaint(GraphicsContext* gc, const SimpleFontData* font)
{
    SkPaint paint = gc->fillPaint();
    font->platformData().setupPaint(&paint, gc);
    gc->adjustTextRenderMode(&paint);
    paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
    return paint;
}

static SkPaint textStrokePaint(GraphicsContext* gc, const SimpleFontData* font, bool isFilling)
{
    SkPaint paint = gc->strokePaint();
    font->platformData().setupPaint(&paint, gc);
    gc->adjustTextRenderMode(&paint);
    paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
    if (isFilling) {
        // If there is a shadow and we filled above, there will already be
        // a shadow. We don't want to draw it again or it will be too dark
        // and it will go on top of the fill.
        //
        // Note that this isn't strictly correct, since the stroke could be
        // very thick and the shadow wouldn't account for this. The "right"
        // thing would be to draw to a new layer and then draw that layer
        // with a shadow. But this is a lot of extra work for something
        // that isn't normally an issue.
        paint.setLooper(0);
    }
    return paint;
}

static void paintGlyphs(GraphicsContext* gc, const SimpleFontData* font,
    const Glyph glyphs[], unsigned numGlyphs,
    const SkPoint pos[], const FloatRect& textRect)
{
    TextDrawingModeFlags textMode = gc->textDrawingMode();

    // We draw text up to two times (once for fill, once for stroke).
    if (textMode & TextModeFill) {
        SkPaint paint = textFillPaint(gc, font);
        gc->drawPosText(glyphs, numGlyphs * sizeof(Glyph), pos, textRect, paint);
    }

    if ((textMode & TextModeStroke) && gc->hasStroke()) {
        SkPaint paint = textStrokePaint(gc, font, textMode & TextModeFill);
        gc->drawPosText(glyphs, numGlyphs * sizeof(Glyph), pos, textRect, paint);
    }
}

static void paintGlyphsHorizontal(GraphicsContext* gc, const SimpleFontData* font,
    const Glyph glyphs[], unsigned numGlyphs,
    const SkScalar xpos[], SkScalar constY, const FloatRect& textRect)
{
    TextDrawingModeFlags textMode = gc->textDrawingMode();

    if (textMode & TextModeFill) {
        SkPaint paint = textFillPaint(gc, font);
        gc->drawPosTextH(glyphs, numGlyphs * sizeof(Glyph), xpos, constY, textRect, paint);
    }

    if ((textMode & TextModeStroke) && gc->hasStroke()) {
        SkPaint paint = textStrokePaint(gc, font, textMode & TextModeFill);
        gc->drawPosTextH(glyphs, numGlyphs * sizeof(Glyph), xpos, constY, textRect, paint);
    }
}

void Font::drawGlyphs(GraphicsContext* gc, const SimpleFontData* font,
    const GlyphBuffer& glyphBuffer, unsigned from, unsigned numGlyphs,
    const FloatPoint& point, const FloatRect& textRect) const
{
    SkScalar x = SkFloatToScalar(point.x());
    SkScalar y = SkFloatToScalar(point.y());

    const OpenTypeVerticalData* verticalData = font->verticalData();
    if (font->platformData().orientation() == Vertical && verticalData) {
        SkAutoSTMalloc<32, SkPoint> storage(numGlyphs);
        SkPoint* pos = storage.get();

        AffineTransform savedMatrix = gc->getCTM();
        gc->concatCTM(AffineTransform(0, -1, 1, 0, point.x(), point.y()));
        gc->concatCTM(AffineTransform(1, 0, 0, 1, -point.x(), -point.y()));

        const unsigned kMaxBufferLength = 256;
        Vector<FloatPoint, kMaxBufferLength> translations;

        const FontMetrics& metrics = font->fontMetrics();
        SkScalar verticalOriginX = SkFloatToScalar(point.x() + metrics.floatAscent() - metrics.floatAscent(IdeographicBaseline));
        float horizontalOffset = point.x();

        unsigned glyphIndex = 0;
        while (glyphIndex < numGlyphs) {
            unsigned chunkLength = std::min(kMaxBufferLength, numGlyphs - glyphIndex);

            const Glyph* glyphs = glyphBuffer.glyphs(from + glyphIndex);
            translations.resize(chunkLength);
            verticalData->getVerticalTranslationsForGlyphs(font, &glyphs[0], chunkLength, reinterpret_cast<float*>(&translations[0]));

            x = verticalOriginX;
            y = SkFloatToScalar(point.y() + horizontalOffset - point.x());

            float currentWidth = 0;
            for (unsigned i = 0; i < chunkLength; ++i, ++glyphIndex) {
                pos[i].set(
                    x + SkIntToScalar(lroundf(translations[i].x())),
                    y + -SkIntToScalar(-lroundf(currentWidth - translations[i].y())));
                currentWidth += glyphBuffer.advanceAt(from + glyphIndex).width();
            }
            horizontalOffset += currentWidth;
            paintGlyphs(gc, font, glyphs, chunkLength, pos, textRect);
        }

        gc->setCTM(savedMatrix);
        return;
    }

    if (!glyphBuffer.hasVerticalAdvances()) {
        SkAutoSTMalloc<64, SkScalar> storage(numGlyphs);
        SkScalar* xpos = storage.get();
        const FloatSize* adv = glyphBuffer.advances(from);
        for (unsigned i = 0; i < numGlyphs; i++) {
            xpos[i] = x;
            x += SkFloatToScalar(adv[i].width());
        }
        const Glyph* glyphs = glyphBuffer.glyphs(from);
        paintGlyphsHorizontal(gc, font, glyphs, numGlyphs, xpos, SkFloatToScalar(y), textRect);
        return;
    }

    // FIXME: text rendering speed:
    // Android has code in their WebCore fork to special case when the
    // GlyphBuffer has no advances other than the defaults. In that case the
    // text drawing can proceed faster. However, it's unclear when those
    // patches may be upstreamed to WebKit so we always use the slower path
    // here.
    SkAutoSTMalloc<32, SkPoint> storage(numGlyphs);
    SkPoint* pos = storage.get();
    const FloatSize* adv = glyphBuffer.advances(from);
    for (unsigned i = 0; i < numGlyphs; i++) {
        pos[i].set(x, y);
        x += SkFloatToScalar(adv[i].width());
        y += SkFloatToScalar(adv[i].height());
    }

    const Glyph* glyphs = glyphBuffer.glyphs(from);
    paintGlyphs(gc, font, glyphs, numGlyphs, pos, textRect);
}

void Font::drawTextBlob(GraphicsContext* gc, const SkTextBlob* blob, const SkPoint& origin) const
{
    // FIXME: It would be good to move this to Font.cpp, if we're sure that none
    // of the things in FontMac's setupPaint need to apply here.
    // See also paintGlyphs.
    TextDrawingModeFlags textMode = gc->textDrawingMode();

    if (textMode & TextModeFill) {
        SkPaint paint = gc->fillPaint();
        gc->adjustTextRenderMode(&paint);
        paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
        gc->drawTextBlob(blob, origin, paint);
    }

    if ((textMode & TextModeStroke) && gc->hasStroke()) {
        SkPaint paint = gc->strokePaint();
        gc->adjustTextRenderMode(&paint);
        paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
        if (textMode & TextModeFill)
            paint.setLooper(0);
        gc->drawTextBlob(blob, origin, paint);
    }
}

void Font::drawComplexText(GraphicsContext* gc, const TextRunPaintInfo& runInfo, const FloatPoint& point) const
{
    if (!runInfo.run.length())
        return;

    TextDrawingModeFlags textMode = gc->textDrawingMode();
    bool fill = textMode & TextModeFill;
    bool stroke = (textMode & TextModeStroke) && gc->hasStroke();

    if (!fill && !stroke)
        return;

    GlyphBuffer glyphBuffer;
    HarfBuzzShaper shaper(this, runInfo.run);
    shaper.setDrawRange(runInfo.from, runInfo.to);
    if (!shaper.shape(&glyphBuffer) || glyphBuffer.isEmpty())
        return;
    FloatPoint adjustedPoint = shaper.adjustStartPoint(point);
    drawGlyphBuffer(gc, runInfo, glyphBuffer, adjustedPoint);
}

void Font::drawEmphasisMarksForComplexText(GraphicsContext* context, const TextRunPaintInfo& runInfo, const AtomicString& mark, const FloatPoint& point) const
{
    GlyphBuffer glyphBuffer;

    float initialAdvance = getGlyphsAndAdvancesForComplexText(runInfo, glyphBuffer, ForTextEmphasis);

    if (glyphBuffer.isEmpty())
        return;

    drawEmphasisMarks(context, runInfo, glyphBuffer, mark, FloatPoint(point.x() + initialAdvance, point.y()));
}

float Font::getGlyphsAndAdvancesForComplexText(const TextRunPaintInfo& runInfo, GlyphBuffer& glyphBuffer, ForTextEmphasisOrNot forTextEmphasis) const
{
    HarfBuzzShaper shaper(this, runInfo.run, HarfBuzzShaper::ForTextEmphasis);
    shaper.setDrawRange(runInfo.from, runInfo.to);
    shaper.shape(&glyphBuffer);
    return 0;
}

float Font::floatWidthForComplexText(const TextRun& run, HashSet<const SimpleFontData*>* fallbackFonts, IntRectExtent* glyphBounds) const
{
    HarfBuzzShaper shaper(this, run, HarfBuzzShaper::NotForTextEmphasis, fallbackFonts);
    if (!shaper.shape())
        return 0;

    glyphBounds->setTop(floorf(-shaper.glyphBoundingBox().top()));
    glyphBounds->setBottom(ceilf(shaper.glyphBoundingBox().bottom()));
    glyphBounds->setLeft(std::max<int>(0, floorf(-shaper.glyphBoundingBox().left())));
    glyphBounds->setRight(std::max<int>(0, ceilf(shaper.glyphBoundingBox().right() - shaper.totalWidth())));

    return shaper.totalWidth();
}

// Return the code point index for the given |x| offset into the text run.
int Font::offsetForPositionForComplexText(const TextRun& run, float xFloat,
                                          bool includePartialGlyphs) const
{
    HarfBuzzShaper shaper(this, run);
    if (!shaper.shape())
        return 0;
    return shaper.offsetForPosition(xFloat);
}

// Return the rectangle for selecting the given range of code-points in the TextRun.
FloatRect Font::selectionRectForComplexText(const TextRun& run,
                                            const FloatPoint& point, int height,
                                            int from, int to) const
{
    HarfBuzzShaper shaper(this, run);
    if (!shaper.shape())
        return FloatRect();
    return shaper.selectionRect(point, height, from, to);
}

PassTextBlobPtr Font::buildTextBlob(const GlyphBuffer& glyphBuffer, float initialAdvance, const FloatRect& bounds) const
{
    // FIXME: Except for setupPaint, this is not specific to FontHarfBuzz.
    // FIXME: Also implement the more general full-positioning path.
    ASSERT(!glyphBuffer.hasVerticalAdvances());

    SkTextBlobBuilder builder;
    SkScalar x = SkFloatToScalar(initialAdvance);
    SkRect skBounds = bounds;

    unsigned i = 0;
    while (i < glyphBuffer.size()) {
        const SimpleFontData* fontData = glyphBuffer.fontDataAt(i);

        // FIXME: Handle vertical text.
        if (fontData->platformData().orientation() == Vertical)
            return nullptr;

        // FIXME: Handle SVG fonts.
        if (fontData->isSVGFont())
            return nullptr;

        // FIXME: FontPlatformData makes some decisions on the device scale
        // factor, which is found via the GraphicsContext. This should be fixed
        // to avoid correctness problems here.
        SkPaint paint;
        fontData->platformData().setupPaint(&paint);
        paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);

        unsigned start = i++;
        while (i < glyphBuffer.size() && glyphBuffer.fontDataAt(i) == fontData)
            i++;
        unsigned count = i - start;

        const SkTextBlobBuilder::RunBuffer& buffer = builder.allocRunPosH(paint, count, 0, &skBounds);

        const uint16_t* glyphs = glyphBuffer.glyphs(start);
        std::copy(glyphs, glyphs + count, buffer.glyphs);

        const FloatSize* advances = glyphBuffer.advances(start);
        for (unsigned j = 0; j < count; j++) {
            buffer.pos[j] = x;
            x += SkFloatToScalar(advances[j].width());
        }
    }

    return adoptRef(builder.build());
}

} // namespace blink
