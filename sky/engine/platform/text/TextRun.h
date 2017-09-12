/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2006, 2007, 2011 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_PLATFORM_TEXT_TEXTRUN_H_
#define SKY_ENGINE_PLATFORM_TEXT_TEXTRUN_H_

#include "flutter/sky/engine/platform/PlatformExport.h"
#include "flutter/sky/engine/platform/fonts/Glyph.h"
#include "flutter/sky/engine/platform/geometry/FloatRect.h"
#include "flutter/sky/engine/platform/text/TextDirection.h"
#include "flutter/sky/engine/platform/text/TextPath.h"
#include "flutter/sky/engine/wtf/RefCounted.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"
#include "third_party/skia/include/core/SkRefCnt.h"

class SkTextBlob;

namespace blink {

class FloatPoint;
class Font;
class GraphicsContext;
class GlyphBuffer;
class SimpleFontData;
struct GlyphData;
struct WidthIterator;

class PLATFORM_EXPORT TextRun {
  WTF_MAKE_FAST_ALLOCATED;

 public:
  enum ExpansionBehaviorFlags {
    ForbidTrailingExpansion = 0 << 0,
    AllowTrailingExpansion = 1 << 0,
    ForbidLeadingExpansion = 0 << 1,
    AllowLeadingExpansion = 1 << 1,
  };

  typedef unsigned ExpansionBehavior;

  TextRun(const LChar* c,
          unsigned len,
          float xpos = 0,
          float expansion = 0,
          ExpansionBehavior expansionBehavior = AllowTrailingExpansion |
                                                ForbidLeadingExpansion,
          TextDirection direction = LTR,
          bool directionalOverride = false,
          bool characterScanForCodePath = true)
      : m_charactersLength(len),
        m_len(len),
        m_xpos(xpos),
        m_horizontalGlyphStretch(1),
        m_expansion(expansion),
        m_expansionBehavior(expansionBehavior),
        m_is8Bit(true),
        m_allowTabs(false),
        m_direction(direction),
        m_directionalOverride(directionalOverride),
        m_characterScanForCodePath(characterScanForCodePath),
        m_disableSpacing(false),
        m_tabSize(0) {
    m_data.characters8 = c;
  }

  TextRun(const UChar* c,
          unsigned len,
          float xpos = 0,
          float expansion = 0,
          ExpansionBehavior expansionBehavior = AllowTrailingExpansion |
                                                ForbidLeadingExpansion,
          TextDirection direction = LTR,
          bool directionalOverride = false,
          bool characterScanForCodePath = true)
      : m_charactersLength(len),
        m_len(len),
        m_xpos(xpos),
        m_horizontalGlyphStretch(1),
        m_expansion(expansion),
        m_expansionBehavior(expansionBehavior),
        m_is8Bit(false),
        m_allowTabs(false),
        m_direction(direction),
        m_directionalOverride(directionalOverride),
        m_characterScanForCodePath(characterScanForCodePath),
        m_disableSpacing(false),
        m_tabSize(0) {
    m_data.characters16 = c;
  }

  TextRun(const String& string,
          float xpos = 0,
          float expansion = 0,
          ExpansionBehavior expansionBehavior = AllowTrailingExpansion |
                                                ForbidLeadingExpansion,
          TextDirection direction = LTR,
          bool directionalOverride = false,
          bool characterScanForCodePath = true)
      : m_charactersLength(string.length()),
        m_len(string.length()),
        m_xpos(xpos),
        m_horizontalGlyphStretch(1),
        m_expansion(expansion),
        m_expansionBehavior(expansionBehavior),
        m_allowTabs(false),
        m_direction(direction),
        m_directionalOverride(directionalOverride),
        m_characterScanForCodePath(characterScanForCodePath),
        m_disableSpacing(false),
        m_tabSize(0) {
    if (!m_charactersLength) {
      m_is8Bit = true;
      m_data.characters8 = 0;
    } else if (string.is8Bit()) {
      m_data.characters8 = string.characters8();
      m_is8Bit = true;
    } else {
      m_data.characters16 = string.characters16();
      m_is8Bit = false;
    }
  }

  TextRun(const StringView& string,
          float xpos = 0,
          float expansion = 0,
          ExpansionBehavior expansionBehavior = AllowTrailingExpansion |
                                                ForbidLeadingExpansion,
          TextDirection direction = LTR,
          bool directionalOverride = false,
          bool characterScanForCodePath = true)
      : m_charactersLength(string.length()),
        m_len(string.length()),
        m_xpos(xpos),
        m_horizontalGlyphStretch(1),
        m_expansion(expansion),
        m_expansionBehavior(expansionBehavior),
        m_allowTabs(false),
        m_direction(direction),
        m_directionalOverride(directionalOverride),
        m_characterScanForCodePath(characterScanForCodePath),
        m_disableSpacing(false),
        m_tabSize(0) {
    if (!m_charactersLength) {
      m_is8Bit = true;
      m_data.characters8 = 0;
    } else if (string.is8Bit()) {
      m_data.characters8 = string.characters8();
      m_is8Bit = true;
    } else {
      m_data.characters16 = string.characters16();
      m_is8Bit = false;
    }
  }

  TextRun subRun(unsigned startOffset, unsigned length) const {
    ASSERT(startOffset < m_len);

    TextRun result = *this;

    if (is8Bit()) {
      result.setText(data8(startOffset), length);
      return result;
    }
    result.setText(data16(startOffset), length);
    return result;
  }

  UChar operator[](unsigned i) const {
    ASSERT_WITH_SECURITY_IMPLICATION(i < m_len);
    return is8Bit() ? m_data.characters8[i] : m_data.characters16[i];
  }
  const LChar* data8(unsigned i) const {
    ASSERT_WITH_SECURITY_IMPLICATION(i < m_len);
    ASSERT(is8Bit());
    return &m_data.characters8[i];
  }
  const UChar* data16(unsigned i) const {
    ASSERT_WITH_SECURITY_IMPLICATION(i < m_len);
    ASSERT(!is8Bit());
    return &m_data.characters16[i];
  }

  const LChar* characters8() const {
    ASSERT(is8Bit());
    return m_data.characters8;
  }
  const UChar* characters16() const {
    ASSERT(!is8Bit());
    return m_data.characters16;
  }

  bool is8Bit() const { return m_is8Bit; }
  int length() const { return m_len; }
  int charactersLength() const { return m_charactersLength; }

  void setText(const LChar* c, unsigned len) {
    m_data.characters8 = c;
    m_len = len;
    m_is8Bit = true;
  }
  void setText(const UChar* c, unsigned len) {
    m_data.characters16 = c;
    m_len = len;
    m_is8Bit = false;
  }
  void setText(const String&);
  void setCharactersLength(unsigned charactersLength) {
    m_charactersLength = charactersLength;
  }

  float horizontalGlyphStretch() const { return m_horizontalGlyphStretch; }
  void setHorizontalGlyphStretch(float scale) {
    m_horizontalGlyphStretch = scale;
  }

  bool allowTabs() const { return m_allowTabs; }
  unsigned tabSize() const { return m_tabSize; }
  void setTabSize(bool, unsigned);

  float xPos() const { return m_xpos; }
  void setXPos(float xPos) { m_xpos = xPos; }
  float expansion() const { return m_expansion; }
  bool allowsLeadingExpansion() const {
    return m_expansionBehavior & AllowLeadingExpansion;
  }
  bool allowsTrailingExpansion() const {
    return m_expansionBehavior & AllowTrailingExpansion;
  }
  TextDirection direction() const {
    return static_cast<TextDirection>(m_direction);
  }
  bool rtl() const { return m_direction == RTL; }
  bool ltr() const { return m_direction == LTR; }
  bool directionalOverride() const { return m_directionalOverride; }
  bool characterScanForCodePath() const { return m_characterScanForCodePath; }
  bool spacingDisabled() const { return m_disableSpacing; }

  void disableSpacing() { m_disableSpacing = true; }
  void setDirection(TextDirection direction) { m_direction = direction; }
  void setDirectionalOverride(bool override) {
    m_directionalOverride = override;
  }
  void setCharacterScanForCodePath(bool scan) {
    m_characterScanForCodePath = scan;
  }

  class RenderingContext : public RefCounted<RenderingContext> {
   public:
    virtual ~RenderingContext() {}

    virtual GlyphData glyphDataForCharacter(const Font&,
                                            const TextRun&,
                                            WidthIterator&,
                                            UChar32 character,
                                            bool mirror,
                                            int currentCharacter,
                                            unsigned& advanceLength) = 0;
    virtual float floatWidthUsingSVGFont(const Font&,
                                         const TextRun&,
                                         int& charsConsumed,
                                         Glyph& glyphId) const = 0;
  };

  RenderingContext* renderingContext() const {
    return m_renderingContext.get();
  }
  void setRenderingContext(PassRefPtr<RenderingContext> context) {
    m_renderingContext = context;
  }

 private:
  union {
    const LChar* characters8;
    const UChar* characters16;
  } m_data;
  unsigned m_charactersLength;  // Marks the end of the characters buffer.
                                // Default equals to m_len.
  unsigned m_len;

  // m_xpos is the x position relative to the left start of the text line, not
  // relative to the left start of the containing block. In the case of right
  // alignment or center alignment, left start of the text line is not the same
  // as left start of the containing block.
  float m_xpos;
  float m_horizontalGlyphStretch;

  float m_expansion;
  ExpansionBehavior m_expansionBehavior : 2;
  unsigned m_is8Bit : 1;
  unsigned m_allowTabs : 1;
  unsigned m_direction : 1;
  unsigned m_directionalOverride : 1;  // Was this direction set by an override
                                       // character.
  unsigned m_characterScanForCodePath : 1;
  unsigned m_disableSpacing : 1;
  unsigned m_tabSize;
  RefPtr<RenderingContext> m_renderingContext;
};

inline void TextRun::setTabSize(bool allow, unsigned size) {
  m_allowTabs = allow;
  m_tabSize = size;
}

// Container for parameters needed to paint TextRun.
struct TextRunPaintInfo {
  explicit TextRunPaintInfo(const TextRun& r)
      : run(r), from(0), to(r.length()) {}

  const TextRun& run;
  int from;
  int to;
  FloatRect bounds;
  sk_sp<const SkTextBlob>* cachedTextBlob;
};

}  // namespace blink
#endif  // SKY_ENGINE_PLATFORM_TEXT_TEXTRUN_H_
