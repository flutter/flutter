/*
 * Copyright (C) 2006, 2009, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2007-2008 Torch Mobile Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_PLATFORM_FONTS_GLYPHBUFFER_H_
#define SKY_ENGINE_PLATFORM_FONTS_GLYPHBUFFER_H_

#include "flutter/sky/engine/platform/fonts/Glyph.h"
#include "flutter/sky/engine/platform/geometry/FloatSize.h"
#include "flutter/sky/engine/wtf/Vector.h"

namespace blink {

class SimpleFontData;

class GlyphBuffer {
 public:
  GlyphBuffer() {}

  bool isEmpty() const { return m_fontData.isEmpty(); }
  bool hasOffsets() const { return !m_offsets.isEmpty(); }
  unsigned size() const { return m_fontData.size(); }

  void clear() {
    m_fontData.clear();
    m_glyphs.clear();
    m_advances.clear();
    m_offsets.clear();
  }

  const Glyph* glyphs(unsigned from) const { return m_glyphs.data() + from; }
  const float* advances(unsigned from) const {
    return m_advances.data() + from;
  }
  const FloatSize* offsets(unsigned from) const {
    return m_offsets.data() + from;
  }

  const SimpleFontData* fontDataAt(unsigned index) const {
    return m_fontData[index];
  }

  Glyph glyphAt(unsigned index) const { return m_glyphs[index]; }

  float advanceAt(unsigned index) const { return m_advances[index]; }

  void add(Glyph glyph, const SimpleFontData* font, float width) {
    // should not mix offset/advance-only glyphs
    ASSERT(!hasOffsets());

    m_fontData.append(font);
    m_glyphs.append(glyph);
    m_advances.append(width);
  }

  void add(Glyph glyph,
           const SimpleFontData* font,
           const FloatSize& offset,
           float advance) {
    // should not mix offset/advance-only glyphs
    ASSERT(size() == m_offsets.size());

    m_fontData.append(font);
    m_glyphs.append(glyph);
    m_offsets.append(offset);
    m_advances.append(advance);
  }

  void reverse() {
    m_fontData.reverse();
    m_glyphs.reverse();
    m_advances.reverse();
  }

  void expandLastAdvance(float width) {
    ASSERT(!isEmpty());
    float& lastAdvance = m_advances.last();
    lastAdvance += width;
  }

 private:
  Vector<const SimpleFontData*, 2048> m_fontData;
  Vector<Glyph, 2048> m_glyphs;
  Vector<float, 2048> m_advances;
  Vector<FloatSize, 1024> m_offsets;
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FONTS_GLYPHBUFFER_H_
