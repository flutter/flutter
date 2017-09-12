/*
 * Copyright (C) 2003, 2006, 2008, 2009, 2010, 2011 Apple Inc.
 * All rights reserved.
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

#include "flutter/sky/engine/platform/fonts/WidthIterator.h"

#include "flutter/sky/engine/platform/fonts/Character.h"
#include "flutter/sky/engine/platform/fonts/Font.h"
#include "flutter/sky/engine/platform/fonts/FontPlatformFeatures.h"
#include "flutter/sky/engine/platform/fonts/GlyphBuffer.h"
#include "flutter/sky/engine/platform/fonts/Latin1TextIterator.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"
#include "flutter/sky/engine/platform/text/SurrogatePairAwareTextIterator.h"
#include "flutter/sky/engine/wtf/MathExtras.h"

using namespace WTF;
using namespace Unicode;

namespace blink {

WidthIterator::WidthIterator(const Font* font,
                             const TextRun& run,
                             HashSet<const SimpleFontData*>* fallbackFonts,
                             bool accountForGlyphBounds,
                             bool forTextEmphasis)
    : m_font(font),
      m_run(run),
      m_currentCharacter(0),
      m_runWidthSoFar(0),
      m_isAfterExpansion(!run.allowsLeadingExpansion()),
      m_fallbackFonts(fallbackFonts),
      m_maxGlyphBoundingBoxY(std::numeric_limits<float>::min()),
      m_minGlyphBoundingBoxY(std::numeric_limits<float>::max()),
      m_firstGlyphOverflow(0),
      m_lastGlyphOverflow(0),
      m_accountForGlyphBounds(accountForGlyphBounds),
      m_forTextEmphasis(forTextEmphasis) {
  // If the padding is non-zero, count the number of spaces in the run
  // and divide that by the padding for per space addition.
  m_expansion = m_run.expansion();
  if (!m_expansion)
    m_expansionPerOpportunity = 0;
  else {
    bool isAfterExpansion = m_isAfterExpansion;
    unsigned expansionOpportunityCount =
        m_run.is8Bit() ? Character::expansionOpportunityCount(
                             m_run.characters8(), m_run.length(),
                             m_run.direction(), isAfterExpansion)
                       : Character::expansionOpportunityCount(
                             m_run.characters16(), m_run.length(),
                             m_run.direction(), isAfterExpansion);
    if (isAfterExpansion && !m_run.allowsTrailingExpansion())
      expansionOpportunityCount--;

    if (!expansionOpportunityCount)
      m_expansionPerOpportunity = 0;
    else
      m_expansionPerOpportunity = m_expansion / expansionOpportunityCount;
  }
}

GlyphData WidthIterator::glyphDataForCharacter(CharacterData& charData) {
  ASSERT(m_font);
  return m_font->glyphDataForCharacter(charData.character, m_run.rtl());
}

float WidthIterator::characterWidth(UChar32 character,
                                    const GlyphData& glyphData) const {
  const SimpleFontData* fontData = glyphData.fontData;
  ASSERT(fontData);

  if (UNLIKELY(character == '\t' && m_run.allowTabs()))
    return m_font->tabWidth(*fontData, m_run.tabSize(),
                            m_run.xPos() + m_runWidthSoFar);

  float width = fontData->widthForGlyph(glyphData.glyph);

  // SVG uses horizontalGlyphStretch(), when textLength is used to
  // stretch/squeeze text.
  if (UNLIKELY(m_run.horizontalGlyphStretch() != 1))
    width *= m_run.horizontalGlyphStretch();

  return width;
}

void WidthIterator::cacheFallbackFont(UChar32 character,
                                      const SimpleFontData* fontData,
                                      const SimpleFontData* primaryFont) {
  if (fontData == primaryFont)
    return;

  // FIXME: This does a little extra work that could be avoided if
  // glyphDataForCharacter() returned whether it chose to use a small caps font.
  if (m_font->fontDescription().variant() == FontVariantNormal ||
      character == toUpper(character)) {
    m_fallbackFonts->add(fontData);
  } else {
    ASSERT(m_font->fontDescription().variant() == FontVariantSmallCaps);
    const GlyphData uppercaseGlyphData =
        m_font->glyphDataForCharacter(toUpper(character), m_run.rtl());
    if (uppercaseGlyphData.fontData != primaryFont)
      m_fallbackFonts->add(uppercaseGlyphData.fontData);
  }
}

float WidthIterator::adjustSpacing(float width,
                                   const CharacterData& charData,
                                   const SimpleFontData& fontData,
                                   GlyphBuffer* glyphBuffer) {
  // Account for letter-spacing.
  if (width)
    width += m_font->fontDescription().letterSpacing();

  static bool expandAroundIdeographs =
      FontPlatformFeatures::canExpandAroundIdeographsInComplexText();
  bool treatAsSpace = Character::treatAsSpace(charData.character);
  if (treatAsSpace || (expandAroundIdeographs &&
                       Character::isCJKIdeographOrSymbol(charData.character))) {
    // Distribute the run's total expansion evenly over all expansion
    // opportunities in the run.
    if (m_expansion) {
      if (!treatAsSpace && !m_isAfterExpansion) {
        // Take the expansion opportunity before this ideograph.
        m_expansion -= m_expansionPerOpportunity;
        float expansionAtThisOpportunity = m_expansionPerOpportunity;
        m_runWidthSoFar += expansionAtThisOpportunity;
        if (glyphBuffer) {
          if (glyphBuffer->isEmpty()) {
            if (m_forTextEmphasis)
              glyphBuffer->add(fontData.zeroWidthSpaceGlyph(), &fontData,
                               m_expansionPerOpportunity);
            else
              glyphBuffer->add(fontData.spaceGlyph(), &fontData,
                               expansionAtThisOpportunity);
          } else {
            glyphBuffer->expandLastAdvance(expansionAtThisOpportunity);
          }
        }
      }
      if (m_run.allowsTrailingExpansion() ||
          (m_run.ltr() && charData.characterOffset + charData.clusterLength <
                              static_cast<size_t>(m_run.length())) ||
          (m_run.rtl() && charData.characterOffset)) {
        m_expansion -= m_expansionPerOpportunity;
        width += m_expansionPerOpportunity;
        m_isAfterExpansion = true;
      }
    } else {
      m_isAfterExpansion = false;
    }

    // Account for word spacing.
    // We apply additional space between "words" by adding width to the space
    // character.
    if (treatAsSpace && (charData.character != '\t' || !m_run.allowTabs()) &&
        (charData.characterOffset || charData.character == noBreakSpace) &&
        m_font->fontDescription().wordSpacing()) {
      width += m_font->fontDescription().wordSpacing();
    }
  } else {
    m_isAfterExpansion = false;
  }

  return width;
}

void WidthIterator::updateGlyphBounds(const GlyphData& glyphData,
                                      float width,
                                      bool firstCharacter) {
  ASSERT(glyphData.fontData);
  FloatRect bounds = glyphData.fontData->boundsForGlyph(glyphData.glyph);

  if (firstCharacter)
    m_firstGlyphOverflow = std::max<float>(0, -bounds.x());
  m_lastGlyphOverflow = std::max<float>(0, bounds.maxX() - width);
  m_maxGlyphBoundingBoxY = std::max(m_maxGlyphBoundingBoxY, bounds.maxY());
  m_minGlyphBoundingBoxY = std::min(m_minGlyphBoundingBoxY, bounds.y());
}

template <typename TextIterator>
unsigned WidthIterator::advanceInternal(TextIterator& textIterator,
                                        GlyphBuffer* glyphBuffer) {
  bool hasExtraSpacing =
      (m_font->fontDescription().letterSpacing() ||
       m_font->fontDescription().wordSpacing() || m_expansion) &&
      !m_run.spacingDisabled();

  const SimpleFontData* primaryFont = m_font->primaryFont();
  const SimpleFontData* lastFontData = primaryFont;

  CharacterData charData;
  while (textIterator.consume(charData.character, charData.clusterLength)) {
    charData.characterOffset = textIterator.currentCharacter();

    const GlyphData glyphData = glyphDataForCharacter(charData);
    Glyph glyph = glyphData.glyph;
    const SimpleFontData* fontData = glyphData.fontData;
    ASSERT(fontData);

    // Now that we have a glyph and font data, get its width.
    float width = characterWidth(charData.character, glyphData);

    if (m_fallbackFonts && lastFontData != fontData && width) {
      lastFontData = fontData;
      cacheFallbackFont(charData.character, fontData, primaryFont);
    }

    if (hasExtraSpacing)
      width = adjustSpacing(width, charData, *fontData, glyphBuffer);

    if (m_accountForGlyphBounds)
      updateGlyphBounds(glyphData, width, !charData.characterOffset);

    if (m_forTextEmphasis &&
        !Character::canReceiveTextEmphasis(charData.character))
      glyph = 0;

    // Advance past the character we just dealt with.
    textIterator.advance(charData.clusterLength);
    m_runWidthSoFar += width;

    if (glyphBuffer)
      glyphBuffer->add(glyph, fontData, width);
  }

  unsigned consumedCharacters =
      textIterator.currentCharacter() - m_currentCharacter;
  m_currentCharacter = textIterator.currentCharacter();

  return consumedCharacters;
}

unsigned WidthIterator::advance(int offset, GlyphBuffer* glyphBuffer) {
  int length = m_run.length();

  if (offset > length)
    offset = length;

  if (m_currentCharacter >= static_cast<unsigned>(offset))
    return 0;

  if (m_run.is8Bit()) {
    Latin1TextIterator textIterator(m_run.data8(m_currentCharacter),
                                    m_currentCharacter, offset, length);
    return advanceInternal(textIterator, glyphBuffer);
  }

  SurrogatePairAwareTextIterator textIterator(
      m_run.data16(m_currentCharacter), m_currentCharacter, offset, length);
  return advanceInternal(textIterator, glyphBuffer);
}

bool WidthIterator::advanceOneCharacter(float& width) {
  float initialWidth = m_runWidthSoFar;

  if (!advance(m_currentCharacter + 1))
    return false;

  width = m_runWidthSoFar - initialWidth;
  return true;
}

}  // namespace blink
