/*
 * Copyright (C) 2006, 2007, 2008, 2013 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
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

#ifndef GlyphPage_h
#define GlyphPage_h

#include "platform/PlatformExport.h"
#include "platform/fonts/CustomFontData.h"
#include "platform/fonts/Glyph.h"
#include <string.h>
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/unicode/Unicode.h"

namespace blink {

class SimpleFontData;
class GlyphPageTreeNode;

// Holds the glyph index and the corresponding SimpleFontData information for a given
// character.
struct GlyphData {
    GlyphData(Glyph g = 0, const SimpleFontData* f = 0)
        : glyph(g)
        , fontData(f)
    {
    }
    Glyph glyph;
    const SimpleFontData* fontData;
};

#if COMPILER(MSVC)
#pragma warning(push)
#pragma warning(disable: 4200) // Disable "zero-sized array in struct/union" warning
#endif

// A GlyphPage contains a fixed-size set of GlyphData mappings for a contiguous
// range of characters in the Unicode code space. GlyphPages are indexed
// starting from 0 and incrementing for each 256 glyphs.
//
// One page may actually include glyphs from other fonts if the characters are
// missing in the primary font. It is owned by exactly one GlyphPageTreeNode,
// although multiple nodes may reference it as their "page" if they are supposed
// to be overriding the parent's node, but provide no additional information.
class PLATFORM_EXPORT GlyphPage : public RefCounted<GlyphPage> {
public:
    static PassRefPtr<GlyphPage> createForMixedFontData(GlyphPageTreeNode* owner)
    {
        void* slot = fastMalloc(sizeof(GlyphPage) + sizeof(SimpleFontData*) * GlyphPage::size);
        return adoptRef(new (slot) GlyphPage(owner));
    }

    static PassRefPtr<GlyphPage> createForSingleFontData(GlyphPageTreeNode* owner, const SimpleFontData* fontData)
    {
        ASSERT(fontData);
        return adoptRef(new GlyphPage(owner, fontData));
    }

    PassRefPtr<GlyphPage> createCopiedSystemFallbackPage(GlyphPageTreeNode* owner) const
    {
        RefPtr<GlyphPage> page = GlyphPage::createForMixedFontData(owner);
        memcpy(page->m_glyphs, m_glyphs, sizeof(m_glyphs));
        if (hasPerGlyphFontData())
            memcpy(page->m_perGlyphFontData, m_perGlyphFontData, sizeof(SimpleFontData*) * GlyphPage::size);
        else {
            for (size_t i = 0; i < GlyphPage::size; ++i) {
                page->m_perGlyphFontData[i] = m_glyphs[i] ? m_fontDataForAllGlyphs : 0;
            }
        }
        page->m_customFontToLoad = m_customFontToLoad;
        return page.release();
    }

    ~GlyphPage() { }

    static const unsigned char sizeBits = 8;
    static const size_t size = (1 << GlyphPage::sizeBits); // Covers Latin-1 in a single page.
    static unsigned indexForCharacter(UChar32 c) { return c & 0xFF; }

    ALWAYS_INLINE GlyphData glyphDataForCharacter(UChar32 c) const
    {
        unsigned index = indexForCharacter(c);
        if (const CustomFontData* customData = customFontToLoadAt(index))
            customData->beginLoadIfNeeded();
        return glyphDataForIndex(index);
    }

    ALWAYS_INLINE GlyphData glyphDataForIndex(unsigned index) const
    {
        ASSERT_WITH_SECURITY_IMPLICATION(index < size);
        Glyph glyph = m_glyphs[index];
        if (hasPerGlyphFontData())
            return GlyphData(glyph, m_perGlyphFontData[index]);
        return GlyphData(glyph, glyph ? m_fontDataForAllGlyphs : 0);
    }

    ALWAYS_INLINE Glyph glyphForCharacter(UChar32 c) const
    {
        return glyphAt(indexForCharacter(c));
    }

    ALWAYS_INLINE Glyph glyphAt(unsigned index) const
    {
        ASSERT_WITH_SECURITY_IMPLICATION(index < size);
        return m_glyphs[index];
    }

    void setGlyphDataForCharacter(UChar32 c, Glyph g, const SimpleFontData* f)
    {
        setGlyphDataForIndex(indexForCharacter(c), g, f);
    }

    void setGlyphDataForIndex(unsigned index, Glyph glyph, const SimpleFontData* fontData)
    {
        ASSERT_WITH_SECURITY_IMPLICATION(index < size);
        m_glyphs[index] = glyph;
        setCustomFontToLoad(index, 0);

        if (hasPerGlyphFontData()) {
            m_perGlyphFontData[index] = fontData;
        } else {
            // A single-font GlyphPage already assigned m_fontDataForAllGlyphs in the constructor.
            ASSERT(!glyph || fontData == m_fontDataForAllGlyphs);
        }
    }

    void setGlyphDataForIndex(unsigned index, const GlyphData& glyphData)
    {
        setGlyphDataForIndex(index, glyphData.glyph, glyphData.fontData);
    }

    const CustomFontData* customFontToLoadAt(unsigned index) const
    {
        ASSERT_WITH_SECURITY_IMPLICATION(index < size);
        return m_customFontToLoad ? m_customFontToLoad->at(index) : 0;
    }

    void setCustomFontToLoad(unsigned index, const CustomFontData* customFontToLoad)
    {
        if (!m_customFontToLoad) {
            if (!customFontToLoad)
                return;
            m_customFontToLoad = CustomDataPage::create();
        }
        ASSERT_WITH_SECURITY_IMPLICATION(index < size);
        m_customFontToLoad->set(index, customFontToLoad);
    }

    void removeFontDataFromSystemFallbackPage(const SimpleFontData* fontData)
    {
        // This method should only be called on the system fallback page, which is never single-font.
        ASSERT(hasPerGlyphFontData());
        for (size_t i = 0; i < size; ++i) {
            if (m_perGlyphFontData[i] == fontData) {
                m_glyphs[i] = 0;
                m_perGlyphFontData[i] = 0;
            }
        }
    }

    GlyphPageTreeNode* owner() const { return m_owner; }

private:
    explicit GlyphPage(GlyphPageTreeNode* owner, const SimpleFontData* fontDataForAllGlyphs = 0)
        : m_fontDataForAllGlyphs(fontDataForAllGlyphs)
        , m_owner(owner)
    {
        memset(m_glyphs, 0, sizeof(m_glyphs));
        if (hasPerGlyphFontData())
            memset(m_perGlyphFontData, 0, sizeof(SimpleFontData*) * GlyphPage::size);
    }

    bool hasPerGlyphFontData() const { return !m_fontDataForAllGlyphs; }

    class CustomDataPage : public RefCounted<CustomDataPage> {
    public:
        static RefPtr<CustomDataPage> create() { return adoptRef(new CustomDataPage()); }
        const CustomFontData* at(size_t index) const { return m_customData[index]; }
        void set(size_t index, const CustomFontData* data) { m_customData[index] = data; }
    private:
        CustomDataPage() { memset(m_customData, 0, sizeof(m_customData)); }
        const CustomFontData* m_customData[size];
    };

    const SimpleFontData* m_fontDataForAllGlyphs;
    GlyphPageTreeNode* m_owner;
    RefPtr<CustomDataPage> m_customFontToLoad;
    Glyph m_glyphs[size];

    // NOTE: This array has (GlyphPage::size) elements if m_fontDataForAllGlyphs is null.
    const SimpleFontData* m_perGlyphFontData[0];
};

#if COMPILER(MSVC)
#pragma warning(pop)
#endif

} // namespace blink

#endif // GlyphPage_h
