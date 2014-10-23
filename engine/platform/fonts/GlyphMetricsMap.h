/*
 * Copyright (C) 2006, 2009 Apple Inc. All rights reserved.
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

#ifndef GlyphMetricsMap_h
#define GlyphMetricsMap_h

#include "platform/fonts/Glyph.h"
#include "platform/geometry/FloatRect.h"
#include "wtf/Assertions.h"
#include "wtf/HashMap.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/unicode/Unicode.h"

namespace blink {

const float cGlyphSizeUnknown = -1;

template<class T> class GlyphMetricsMap {
    WTF_MAKE_NONCOPYABLE(GlyphMetricsMap);
public:
    GlyphMetricsMap() : m_filledPrimaryPage(false) { }
    T metricsForGlyph(Glyph glyph)
    {
        return locatePage(glyph / GlyphMetricsPage::size)->metricsForGlyph(glyph);
    }

    void setMetricsForGlyph(Glyph glyph, const T& metrics)
    {
        locatePage(glyph / GlyphMetricsPage::size)->setMetricsForGlyph(glyph, metrics);
    }

private:
    class GlyphMetricsPage {
    public:
        static const size_t size = 256; // Usually covers Latin-1 in a single page.

        T metricsForGlyph(Glyph glyph) const { return m_metrics[glyph % size]; }
        void setMetricsForGlyph(Glyph glyph, const T& metrics)
        {
            setMetricsForIndex(glyph % size, metrics);
        }
        void setMetricsForIndex(unsigned index, const T& metrics)
        {
            ASSERT_WITH_SECURITY_IMPLICATION(index < size);
            m_metrics[index] = metrics;
        }

    private:
        T m_metrics[size];
    };

    GlyphMetricsPage* locatePage(unsigned pageNumber)
    {
        if (!pageNumber && m_filledPrimaryPage)
            return &m_primaryPage;
        return locatePageSlowCase(pageNumber);
    }

    GlyphMetricsPage* locatePageSlowCase(unsigned pageNumber);

    static T unknownMetrics();

    bool m_filledPrimaryPage;
    GlyphMetricsPage m_primaryPage; // We optimize for the page that contains glyph indices 0-255.
    OwnPtr<HashMap<int, OwnPtr<GlyphMetricsPage> > > m_pages;
};

template<> inline float GlyphMetricsMap<float>::unknownMetrics()
{
    return cGlyphSizeUnknown;
}

template<> inline FloatRect GlyphMetricsMap<FloatRect>::unknownMetrics()
{
    return FloatRect(0, 0, cGlyphSizeUnknown, cGlyphSizeUnknown);
}

template<class T> typename GlyphMetricsMap<T>::GlyphMetricsPage* GlyphMetricsMap<T>::locatePageSlowCase(unsigned pageNumber)
{
    GlyphMetricsPage* page;
    if (!pageNumber) {
        ASSERT(!m_filledPrimaryPage);
        page = &m_primaryPage;
        m_filledPrimaryPage = true;
    } else {
        if (m_pages) {
            page = m_pages->get(pageNumber);
            if (page)
                return page;
        } else
            m_pages = adoptPtr(new HashMap<int, OwnPtr<GlyphMetricsPage> >);
        page = new GlyphMetricsPage;
        m_pages->set(pageNumber, adoptPtr(page));
    }

    // Fill in the whole page with the unknown glyph information.
    for (unsigned i = 0; i < GlyphMetricsPage::size; i++)
        page->setMetricsForIndex(i, unknownMetrics());

    return page;
}

} // namespace blink

#endif
