/*
 * Copyright (C) 2003, 2006, 2008, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Holger Hans Peter Freyther
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_PLATFORM_FONTS_WIDTHITERATOR_H_
#define SKY_ENGINE_PLATFORM_FONTS_WIDTHITERATOR_H_

#include "flutter/sky/engine/platform/PlatformExport.h"
#include "flutter/sky/engine/platform/text/TextRun.h"
#include "flutter/sky/engine/wtf/HashSet.h"
#include "flutter/sky/engine/wtf/Vector.h"
#include "flutter/sky/engine/wtf/unicode/Unicode.h"

namespace blink {

class Font;
class GlyphBuffer;
class SimpleFontData;
class TextRun;
struct GlyphData;

struct PLATFORM_EXPORT WidthIterator {
  WTF_MAKE_FAST_ALLOCATED;

 public:
  WidthIterator(const Font*,
                const TextRun&,
                HashSet<const SimpleFontData*>* fallbackFonts = 0,
                bool accountForGlyphBounds = false,
                bool forTextEmphasis = false);

  unsigned advance(int to, GlyphBuffer* = 0);
  bool advanceOneCharacter(float& width);

  float maxGlyphBoundingBoxY() const {
    ASSERT(m_accountForGlyphBounds);
    return m_maxGlyphBoundingBoxY;
  }
  float minGlyphBoundingBoxY() const {
    ASSERT(m_accountForGlyphBounds);
    return m_minGlyphBoundingBoxY;
  }
  float firstGlyphOverflow() const {
    ASSERT(m_accountForGlyphBounds);
    return m_firstGlyphOverflow;
  }
  float lastGlyphOverflow() const {
    ASSERT(m_accountForGlyphBounds);
    return m_lastGlyphOverflow;
  }

  const TextRun& run() const { return m_run; }
  float runWidthSoFar() const { return m_runWidthSoFar; }

  const Font* m_font;

  const TextRun& m_run;

  unsigned m_currentCharacter;
  float m_runWidthSoFar;
  float m_expansion;
  float m_expansionPerOpportunity;
  bool m_isAfterExpansion;

 private:
  struct CharacterData {
    UChar32 character;
    unsigned clusterLength;
    int characterOffset;
  };

  GlyphData glyphDataForCharacter(CharacterData&);
  float characterWidth(UChar32, const GlyphData&) const;
  void cacheFallbackFont(UChar32,
                         const SimpleFontData*,
                         const SimpleFontData* primaryFont);
  float adjustSpacing(float,
                      const CharacterData&,
                      const SimpleFontData&,
                      GlyphBuffer*);
  void updateGlyphBounds(const GlyphData&, float width, bool firstCharacter);

  template <typename TextIterator>
  unsigned advanceInternal(TextIterator&, GlyphBuffer*);

  HashSet<const SimpleFontData*>* m_fallbackFonts;
  float m_maxGlyphBoundingBoxY;
  float m_minGlyphBoundingBoxY;
  float m_firstGlyphOverflow;
  float m_lastGlyphOverflow;

  bool m_accountForGlyphBounds : 1;
  bool m_forTextEmphasis : 1;
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FONTS_WIDTHITERATOR_H_
