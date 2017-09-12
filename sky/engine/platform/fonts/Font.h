/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2006, 2007, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Holger Hans Peter Freyther
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef SKY_ENGINE_PLATFORM_FONTS_FONT_H_
#define SKY_ENGINE_PLATFORM_FONTS_FONT_H_

#include "flutter/sky/engine/platform/PlatformExport.h"
#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "flutter/sky/engine/platform/fonts/FontFallbackList.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"
#include "flutter/sky/engine/platform/fonts/TextBlob.h"
#include "flutter/sky/engine/platform/text/TextDirection.h"
#include "flutter/sky/engine/platform/text/TextPath.h"
#include "flutter/sky/engine/wtf/HashMap.h"
#include "flutter/sky/engine/wtf/HashSet.h"
#include "flutter/sky/engine/wtf/MathExtras.h"
#include "flutter/sky/engine/wtf/unicode/CharacterNames.h"

// "X11/X.h" defines Complex to 0 and conflicts
// with Complex value in CodePath enum.
#ifdef Complex
#undef Complex
#endif

class SkTextBlob;
struct SkPoint;

namespace blink {

class FloatPoint;
class FloatRect;
class FontData;
class FontMetrics;
class FontSelector;
class GlyphBuffer;
class GraphicsContext;
class TextRun;
struct TextRunPaintInfo;

struct GlyphData;

struct GlyphOverflow {
  GlyphOverflow()
      : left(0), right(0), top(0), bottom(0), computeBounds(false) {}

  bool isZero() const { return !left && !right && !top && !bottom; }

  int left;
  int right;
  int top;
  int bottom;
  bool computeBounds;
};

class PLATFORM_EXPORT Font {
 public:
  Font();
  Font(const FontDescription&);
  ~Font();

  Font(const Font&);
  Font& operator=(const Font&);

  bool operator==(const Font& other) const;
  bool operator!=(const Font& other) const { return !(*this == other); }

  const FontDescription& fontDescription() const { return m_fontDescription; }

  void update(PassRefPtr<FontSelector>) const;

  enum CustomFontNotReadyAction {
    DoNotPaintIfFontNotReady,
    UseFallbackIfFontNotReady
  };
  void drawText(GraphicsContext*,
                const TextRunPaintInfo&,
                const FloatPoint&) const;
  float drawUncachedText(GraphicsContext*,
                         const TextRunPaintInfo&,
                         const FloatPoint&,
                         CustomFontNotReadyAction) const;
  void drawEmphasisMarks(GraphicsContext*,
                         const TextRunPaintInfo&,
                         const AtomicString& mark,
                         const FloatPoint&) const;

  float width(const TextRun&,
              HashSet<const SimpleFontData*>* fallbackFonts = 0,
              GlyphOverflow* = 0) const;
  float width(const TextRun&, int& charsConsumed, Glyph& glyphId) const;

  int offsetForPosition(const TextRun&,
                        float position,
                        bool includePartialGlyphs) const;
  FloatRect selectionRectForText(const TextRun&,
                                 const FloatPoint&,
                                 int h,
                                 int from = 0,
                                 int to = -1,
                                 bool accountForGlyphBounds = false) const;

  bool isFixedPitch() const;

  // Metrics that we query the FontFallbackList for.
  const FontMetrics& fontMetrics() const {
    return primaryFont()->fontMetrics();
  }
  float spaceWidth() const {
    return primaryFont()->spaceWidth() + fontDescription().letterSpacing();
  }
  float tabWidth(const SimpleFontData&, unsigned tabSize, float position) const;
  float tabWidth(unsigned tabSize, float position) const {
    return tabWidth(*primaryFont(), tabSize, position);
  }

  int emphasisMarkAscent(const AtomicString&) const;
  int emphasisMarkDescent(const AtomicString&) const;
  int emphasisMarkHeight(const AtomicString&) const;

  const SimpleFontData* primaryFont() const;
  const FontData* fontDataAt(unsigned) const;
  inline GlyphData glyphDataForCharacter(
      UChar32 c,
      bool mirror,
      FontDataVariant variant = AutoVariant) const {
    return glyphDataAndPageForCharacter(c, mirror, variant).first;
  }
  std::pair<GlyphData, GlyphPage*> glyphDataAndPageForCharacter(
      UChar32,
      bool mirror,
      FontDataVariant = AutoVariant) const;
  bool primaryFontHasGlyphForCharacter(UChar32) const;

  CodePath codePath(const TextRun&) const;

 private:
  enum ForTextEmphasisOrNot { NotForTextEmphasis, ForTextEmphasis };

  // Returns the initial in-stream advance.
  float buildGlyphBuffer(const TextRunPaintInfo&,
                         GlyphBuffer&,
                         ForTextEmphasisOrNot = NotForTextEmphasis) const;
  TextBlobPtr buildTextBlob(const GlyphBuffer&,
                            float initialAdvance,
                            const FloatRect& bounds) const;
  void drawGlyphs(GraphicsContext*,
                  const SimpleFontData*,
                  const GlyphBuffer&,
                  unsigned from,
                  unsigned numGlyphs,
                  const FloatPoint&,
                  const FloatRect& textRect) const;
  void drawTextBlob(GraphicsContext*,
                    const SkTextBlob*,
                    const SkPoint& origin) const;
  float drawGlyphBuffer(GraphicsContext*,
                        const TextRunPaintInfo&,
                        const GlyphBuffer&,
                        const FloatPoint&) const;
  void drawEmphasisMarks(GraphicsContext*,
                         const TextRunPaintInfo&,
                         const GlyphBuffer&,
                         const AtomicString&,
                         const FloatPoint&) const;
  float floatWidthForSimpleText(
      const TextRun&,
      HashSet<const SimpleFontData*>* fallbackFonts = 0,
      IntRectExtent* glyphBounds = 0) const;
  int offsetForPositionForSimpleText(const TextRun&,
                                     float position,
                                     bool includePartialGlyphs) const;
  FloatRect selectionRectForSimpleText(const TextRun&,
                                       const FloatPoint&,
                                       int h,
                                       int from,
                                       int to,
                                       bool accountForGlyphBounds) const;

  bool getEmphasisMarkGlyphData(const AtomicString&, GlyphData&) const;

  float floatWidthForComplexText(const TextRun&,
                                 HashSet<const SimpleFontData*>* fallbackFonts,
                                 IntRectExtent* glyphBounds) const;
  int offsetForPositionForComplexText(const TextRun&,
                                      float position,
                                      bool includePartialGlyphs) const;
  FloatRect selectionRectForComplexText(const TextRun&,
                                        const FloatPoint&,
                                        int h,
                                        int from,
                                        int to) const;

  friend struct WidthIterator;

 public:
  // Useful for debugging the different font rendering code paths.
  static void setCodePath(CodePath);
  static CodePath codePath();
  static CodePath s_codePath;

  FontSelector* fontSelector() const;

  FontFallbackList* fontList() const { return m_fontFallbackList.get(); }

  void willUseFontData(UChar32) const;

  static FloatRect pixelSnappedSelectionRect(float fromX,
                                             float toX,
                                             float y,
                                             float height);

 private:
  bool loadingCustomFonts() const {
    return m_fontFallbackList && m_fontFallbackList->loadingCustomFonts();
  }

  bool shouldSkipDrawing() const {
    return m_fontFallbackList && m_fontFallbackList->shouldSkipDrawing();
  }

  FontDescription m_fontDescription;
  mutable RefPtr<FontFallbackList> m_fontFallbackList;
};

inline Font::~Font() {}

inline const SimpleFontData* Font::primaryFont() const {
  ASSERT(m_fontFallbackList);
  return m_fontFallbackList->primarySimpleFontData(m_fontDescription);
}

inline const FontData* Font::fontDataAt(unsigned index) const {
  ASSERT(m_fontFallbackList);
  return m_fontFallbackList->fontDataAt(m_fontDescription, index);
}

inline bool Font::isFixedPitch() const {
  ASSERT(m_fontFallbackList);
  return m_fontFallbackList->isFixedPitch(m_fontDescription);
}

inline FontSelector* Font::fontSelector() const {
  return m_fontFallbackList ? m_fontFallbackList->fontSelector() : 0;
}

inline float Font::tabWidth(const SimpleFontData& fontData,
                            unsigned tabSize,
                            float position) const {
  if (!tabSize)
    return fontDescription().letterSpacing();
  float tabWidth =
      tabSize * fontData.spaceWidth() + fontDescription().letterSpacing();
  return tabWidth - fmodf(position, tabWidth);
}

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FONTS_FONT_H_
