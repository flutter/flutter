/*
 * Copyright (c) 2008, 2009, Google Inc. All rights reserved.
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

#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"

#include <unicode/normlzr.h>
#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "flutter/sky/engine/platform/fonts/GlyphPage.h"
#include "flutter/sky/engine/platform/fonts/VDMXParser.h"
#include "flutter/sky/engine/platform/geometry/FloatRect.h"
#include "flutter/sky/engine/wtf/unicode/Unicode.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "third_party/skia/include/core/SkTypes.h"

namespace blink {

#if OS(LINUX) || OS(ANDROID)

// This is the largest VDMX table which we'll try to load and parse.
static const size_t maxVDMXTableSize = 1024 * 1024;  // 1 MB

#endif  // OS(LINUX) || OS(ANDROID)

void SimpleFontData::platformInit() {
  if (!m_platformData.size()) {
    m_fontMetrics.reset();
    m_avgCharWidth = 0;
    m_maxCharWidth = 0;
    return;
  }

  SkPaint paint;
  SkPaint::FontMetrics metrics;

  m_platformData.setupPaint(&paint);
  paint.getFontMetrics(&metrics);
  SkTypeface* face = paint.getTypeface();
  ASSERT(face);

  int vdmxAscent = 0, vdmxDescent = 0;
  bool isVDMXValid = false;

#if OS(LINUX) || OS(ANDROID)
  // Manually digging up VDMX metrics is only applicable when bytecode hinting
  // using FreeType. With GDI, the metrics will already have taken this into
  // account (as needed). With DirectWrite or CoreText, no bytecode hinting is
  // ever done. This code should be pushed into FreeType (hinted font metrics).
  static const uint32_t vdmxTag = SkSetFourByteTag('V', 'D', 'M', 'X');
  int pixelSize = m_platformData.size() + 0.5;
  if (!paint.isAutohinted() &&
      (paint.getHinting() == SkPaint::kFull_Hinting ||
       paint.getHinting() == SkPaint::kNormal_Hinting)) {
    size_t vdmxSize = face->getTableSize(vdmxTag);
    if (vdmxSize && vdmxSize < maxVDMXTableSize) {
      uint8_t* vdmxTable = (uint8_t*)fastMalloc(vdmxSize);
      if (vdmxTable &&
          face->getTableData(vdmxTag, 0, vdmxSize, vdmxTable) == vdmxSize &&
          parseVDMX(&vdmxAscent, &vdmxDescent, vdmxTable, vdmxSize, pixelSize))
        isVDMXValid = true;
      fastFree(vdmxTable);
    }
  }
#endif

  float ascent;
  float descent;

  // Beware those who step here: This code is designed to match Win32 font
  // metrics *exactly* (except the adjustment of ascent/descent on
  // Linux/Android).
  if (isVDMXValid) {
    ascent = vdmxAscent;
    descent = -vdmxDescent;
  } else {
    ascent = SkScalarRoundToInt(-metrics.fAscent);
    descent = SkScalarRoundToInt(metrics.fDescent);
#if OS(LINUX) || OS(ANDROID)
    // When subpixel positioning is enabled, if the descent is rounded down, the
    // descent part of the glyph may be truncated when displayed in a 'overflow:
    // hidden' container. To avoid that, borrow 1 unit from the ascent when
    // possible.
    // FIXME: This can be removed if sub-pixel ascent/descent is supported.
    if (platformData().fontRenderStyle().useSubpixelPositioning &&
        descent < SkScalarToFloat(metrics.fDescent) && ascent >= 1) {
      ++descent;
      --ascent;
    }
#endif
  }

  m_fontMetrics.setAscent(ascent);
  m_fontMetrics.setDescent(descent);

  float xHeight;
  if (metrics.fXHeight) {
    xHeight = metrics.fXHeight;
    m_fontMetrics.setXHeight(xHeight);
  } else {
    xHeight = ascent * 0.56;  // Best guess from Windows font metrics.
    m_fontMetrics.setXHeight(xHeight);
    m_fontMetrics.setHasXHeight(false);
  }

  float lineGap = SkScalarToFloat(metrics.fLeading);
  m_fontMetrics.setLineGap(lineGap);
  m_fontMetrics.setLineSpacing(lroundf(ascent) + lroundf(descent) +
                               lroundf(lineGap));

  SkScalar underlineThickness, underlinePosition;
  if (metrics.hasUnderlineThickness(&underlineThickness) &&
      metrics.hasUnderlinePosition(&underlinePosition)) {
    m_fontMetrics.setUnderlineThickness(SkScalarToFloat(underlineThickness));
    m_fontMetrics.setUnderlinePosition(SkScalarToFloat(-underlinePosition));
  }

  if (platformData().orientation() == Vertical &&
      !isTextOrientationFallback()) {
    static const uint32_t vheaTag = SkSetFourByteTag('v', 'h', 'e', 'a');
    static const uint32_t vorgTag = SkSetFourByteTag('V', 'O', 'R', 'G');
    size_t vheaSize = face->getTableSize(vheaTag);
    size_t vorgSize = face->getTableSize(vorgTag);
    if ((vheaSize > 0) || (vorgSize > 0))
      m_hasVerticalGlyphs = true;
  }

  // In WebKit/WebCore/platform/graphics/SimpleFontData.cpp, m_spaceWidth is
  // calculated for us, but we need to calculate m_maxCharWidth and
  // m_avgCharWidth in order for text entry widgets to be sized correctly.
  // FIXME: This seems incorrect and should probably use fMaxCharWidth as
  // the code path above.
  SkScalar xRange = metrics.fXMax - metrics.fXMin;
  m_maxCharWidth =
      SkScalarRoundToInt(xRange * SkScalarRoundToInt(m_platformData.size()));

  if (metrics.fAvgCharWidth)
    m_avgCharWidth = SkScalarRoundToInt(metrics.fAvgCharWidth);
  else {
    m_avgCharWidth = xHeight;

    GlyphPage* glyphPageZero = GlyphPageTreeNode::getRootChild(this, 0)->page();

    if (glyphPageZero) {
      static const UChar32 xChar = 'x';
      const Glyph xGlyph = glyphPageZero->glyphForCharacter(xChar);

      if (xGlyph) {
        // In widthForGlyph(), xGlyph will be compared with
        // m_zeroWidthSpaceGlyph, which isn't initialized yet here.
        // Initialize it with zero to make sure widthForGlyph() returns
        // the right width.
        m_zeroWidthSpaceGlyph = 0;
        m_avgCharWidth = widthForGlyph(xGlyph);
      }
    }
  }

  if (int unitsPerEm = face->getUnitsPerEm())
    m_fontMetrics.setUnitsPerEm(unitsPerEm);
}

void SimpleFontData::platformCharWidthInit() {
  // charwidths are set in platformInit.
}

void SimpleFontData::platformDestroy() {}

PassRefPtr<SimpleFontData> SimpleFontData::platformCreateScaledFontData(
    const FontDescription& fontDescription,
    float scaleFactor) const {
  const float scaledSize =
      lroundf(fontDescription.computedSize() * scaleFactor);
  return SimpleFontData::create(
      FontPlatformData(m_platformData, scaledSize),
      isCustomFont() ? CustomFontData::create() : nullptr);
}

void SimpleFontData::determinePitch() {
  m_treatAsFixedPitch = platformData().isFixedPitch();
}

static inline void getSkiaBoundsForGlyph(SkPaint& paint,
                                         Glyph glyph,
                                         SkRect& bounds) {
  paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);

  SkPath path;
  paint.getTextPath(&glyph, sizeof(glyph), 0, 0, &path);
  bounds = path.getBounds();

  if (!paint.isSubpixelText()) {
    SkIRect ir;
    bounds.round(&ir);
    bounds.set(ir);
  }
}

FloatRect SimpleFontData::platformBoundsForGlyph(Glyph glyph) const {
  if (!m_platformData.size())
    return FloatRect();

  SkASSERT(sizeof(glyph) == 2);  // compile-time assert

  SkPaint paint;
  m_platformData.setupPaint(&paint);

  SkRect bounds;
  getSkiaBoundsForGlyph(paint, glyph, bounds);
  return FloatRect(bounds);
}

float SimpleFontData::platformWidthForGlyph(Glyph glyph) const {
  if (!m_platformData.size())
    return 0;

  SkASSERT(sizeof(glyph) == 2);  // compile-time assert

  SkPaint paint;

  m_platformData.setupPaint(&paint);

  paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
  SkScalar width = paint.measureText(&glyph, 2);
  if (!paint.isSubpixelText())
    width = SkScalarRoundToInt(width);
  return SkScalarToFloat(width);
}

bool SimpleFontData::canRenderCombiningCharacterSequence(
    const UChar* characters,
    size_t length) const {
  if (!m_combiningCharacterSequenceSupport)
    m_combiningCharacterSequenceSupport = adoptPtr(new HashMap<String, bool>);

  WTF::HashMap<String, bool>::AddResult addResult =
      m_combiningCharacterSequenceSupport->add(String(characters, length),
                                               false);
  if (!addResult.isNewEntry)
    return addResult.storedValue->value;

  UErrorCode error = U_ZERO_ERROR;
  Vector<UChar, 4> normalizedCharacters(length);
  int32_t normalizedLength =
      unorm_normalize(characters, length, UNORM_NFC, UNORM_UNICODE_3_2,
                      &normalizedCharacters[0], length, &error);
  // Can't render if we have an error or no composition occurred.
  if (U_FAILURE(error) || (static_cast<size_t>(normalizedLength) == length))
    return false;

  SkPaint paint;
  m_platformData.setupPaint(&paint);
  paint.setTextEncoding(SkPaint::kUTF16_TextEncoding);
  if (paint.textToGlyphs(&normalizedCharacters[0], normalizedLength * 2, 0)) {
    addResult.storedValue->value = true;
    return true;
  }
  return false;
}

bool SimpleFontData::fillGlyphPage(GlyphPage* pageToFill,
                                   unsigned offset,
                                   unsigned length,
                                   UChar* buffer,
                                   unsigned bufferLength) const {
  if (U16_IS_LEAD(buffer[bufferLength - 1])) {
    SkDebugf("%s last char is high-surrogate", __FUNCTION__);
    return false;
  }

  SkAutoSTMalloc<GlyphPage::size, uint16_t> glyphStorage(length);

  uint16_t* glyphs = glyphStorage.get();
  SkTypeface* typeface = platformData().typeface();
  typeface->charsToGlyphs(buffer, SkTypeface::kUTF16_Encoding, glyphs, length);

  bool haveGlyphs = false;
  for (unsigned i = 0; i < length; i++) {
    if (glyphs[i]) {
      pageToFill->setGlyphDataForIndex(offset + i, glyphs[i], this);
      haveGlyphs = true;
    }
  }

  return haveGlyphs;
}

}  // namespace blink
