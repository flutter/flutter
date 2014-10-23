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

#ifndef GlyphBuffer_h
#define GlyphBuffer_h

#include "platform/fonts/Glyph.h"
#include "platform/geometry/FloatSize.h"
#include "wtf/Vector.h"

namespace blink {

class SimpleFontData;

class GlyphBuffer {
public:
    GlyphBuffer() : m_hasVerticalAdvances(false) { }

    bool isEmpty() const { return m_fontData.isEmpty(); }
    unsigned size() const { return m_fontData.size(); }
    bool hasVerticalAdvances() const { return m_hasVerticalAdvances; }

    void clear()
    {
        m_fontData.clear();
        m_glyphs.clear();
        m_advances.clear();
        m_hasVerticalAdvances = false;
    }

    const Glyph* glyphs(unsigned from) const { return m_glyphs.data() + from; }
    const FloatSize* advances(unsigned from) const { return m_advances.data() + from; }

    const SimpleFontData* fontDataAt(unsigned index) const { return m_fontData[index]; }

    Glyph glyphAt(unsigned index) const
    {
        return m_glyphs[index];
    }

    FloatSize advanceAt(unsigned index) const
    {
        return m_advances[index];
    }

    void add(Glyph glyph, const SimpleFontData* font, float width)
    {
        m_fontData.append(font);
        m_glyphs.append(glyph);
        m_advances.append(FloatSize(width, 0));
    }

    void add(Glyph glyph, const SimpleFontData* font, const FloatSize& advance)
    {
        m_fontData.append(font);
        m_glyphs.append(glyph);
        m_advances.append(advance);
        if (advance.height())
            m_hasVerticalAdvances = true;
    }

    void reverse()
    {
        m_fontData.reverse();
        m_glyphs.reverse();
        m_advances.reverse();
    }

    void setAdvanceWidth(unsigned index, float newWidth)
    {
        m_advances[index].setWidth(newWidth);
    }

    void expandLastAdvance(float width)
    {
        ASSERT(!isEmpty());
        FloatSize& lastAdvance = m_advances.last();
        lastAdvance.setWidth(lastAdvance.width() + width);
    }

private:
    Vector<const SimpleFontData*, 2048> m_fontData;
    Vector<Glyph, 2048> m_glyphs;
    Vector<FloatSize, 2048> m_advances;
    bool m_hasVerticalAdvances;
};

} // namespace blink

#endif
