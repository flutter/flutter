/*
 * Copyright (C) 2007, 2008, 2011 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/css/CSSFontFace.h"

#include "core/css/CSSFontFaceSource.h"
#include "core/css/CSSFontSelector.h"
#include "core/css/CSSSegmentedFontFace.h"
#include "core/css/FontFaceSet.h"
#include "core/css/RemoteFontFaceSource.h"
#include "core/frame/UseCounter.h"
#include "platform/fonts/FontDescription.h"
#include "platform/fonts/SimpleFontData.h"

namespace blink {

void CSSFontFace::addSource(PassOwnPtrWillBeRawPtr<CSSFontFaceSource> source)
{
    source->setFontFace(this);
    m_sources.append(source);
}

void CSSFontFace::setSegmentedFontFace(CSSSegmentedFontFace* segmentedFontFace)
{
    ASSERT(!m_segmentedFontFace);
    m_segmentedFontFace = segmentedFontFace;
}

void CSSFontFace::didBeginLoad()
{
    if (loadStatus() == FontFace::Unloaded)
        setLoadStatus(FontFace::Loading);
}

void CSSFontFace::fontLoaded(RemoteFontFaceSource* source)
{
    if (!isValid() || source != m_sources.first())
        return;

    if (loadStatus() == FontFace::Loading) {
        if (source->ensureFontData()) {
            setLoadStatus(FontFace::Loaded);
        } else {
            m_sources.removeFirst();
            load();
        }
    }

    if (m_segmentedFontFace)
        m_segmentedFontFace->fontLoaded(this);
}

void CSSFontFace::fontLoadWaitLimitExceeded(RemoteFontFaceSource* source)
{
    if (!isValid() || source != m_sources.first())
        return;
    if (m_segmentedFontFace)
        m_segmentedFontFace->fontLoadWaitLimitExceeded(this);
}

PassRefPtr<SimpleFontData> CSSFontFace::getFontData(const FontDescription& fontDescription)
{
    if (!isValid())
        return nullptr;

    while (!m_sources.isEmpty()) {
        OwnPtrWillBeMember<CSSFontFaceSource>& source = m_sources.first();
        if (RefPtr<SimpleFontData> result = source->getFontData(fontDescription)) {
            if (loadStatus() == FontFace::Unloaded && (source->isLoading() || source->isLoaded()))
                setLoadStatus(FontFace::Loading);
            if (loadStatus() == FontFace::Loading && source->isLoaded())
                setLoadStatus(FontFace::Loaded);
            return result.release();
        }
        m_sources.removeFirst();
    }

    if (loadStatus() == FontFace::Unloaded)
        setLoadStatus(FontFace::Loading);
    if (loadStatus() == FontFace::Loading)
        setLoadStatus(FontFace::Error);
    return nullptr;
}

bool CSSFontFace::maybeScheduleFontLoad(const FontDescription& fontDescription, UChar32 character)
{
    if (m_ranges.contains(character)) {
        if (loadStatus() == FontFace::Unloaded)
            load(fontDescription);
        return true;
    }
    return false;
}

void CSSFontFace::load()
{
    FontDescription fontDescription;
    FontFamily fontFamily;
    fontFamily.setFamily(m_fontFace->family());
    fontDescription.setFamily(fontFamily);
    fontDescription.setTraits(m_fontFace->traits());
    load(fontDescription);
}

void CSSFontFace::load(const FontDescription& fontDescription)
{
    if (loadStatus() == FontFace::Unloaded)
        setLoadStatus(FontFace::Loading);
    ASSERT(loadStatus() == FontFace::Loading);

    while (!m_sources.isEmpty()) {
        OwnPtrWillBeMember<CSSFontFaceSource>& source = m_sources.first();
        if (source->isValid()) {
            if (source->isLocal()) {
                if (source->isLocalFontAvailable(fontDescription)) {
                    setLoadStatus(FontFace::Loaded);
                    return;
                }
            } else {
                if (!source->isLoaded())
                    source->beginLoadIfNeeded();
                else
                    setLoadStatus(FontFace::Loaded);
                return;
            }
        }
        m_sources.removeFirst();
    }
    setLoadStatus(FontFace::Error);
}

void CSSFontFace::setLoadStatus(FontFace::LoadStatus newStatus)
{
    ASSERT(m_fontFace);
    if (newStatus == FontFace::Error)
        m_fontFace->setError();
    else
        m_fontFace->setLoadStatus(newStatus);

    if (!m_segmentedFontFace)
        return;
    Document* document = m_segmentedFontFace->fontSelector()->document();
    if (!document)
        return;

    switch (newStatus) {
    case FontFace::Loading:
        FontFaceSet::from(*document)->beginFontLoading(m_fontFace);
        break;
    case FontFace::Loaded:
        FontFaceSet::from(*document)->fontLoaded(m_fontFace);
        break;
    case FontFace::Error:
        FontFaceSet::from(*document)->loadError(m_fontFace);
        break;
    default:
        break;
    }
}

CSSFontFace::UnicodeRangeSet::UnicodeRangeSet(const Vector<UnicodeRange>& ranges)
    : m_ranges(ranges)
{
    if (m_ranges.isEmpty())
        return;

    std::sort(m_ranges.begin(), m_ranges.end());

    // Unify overlapping ranges.
    UChar32 from = m_ranges[0].from();
    UChar32 to = m_ranges[0].to();
    size_t targetIndex = 0;
    for (size_t i = 1; i < m_ranges.size(); i++) {
        if (to + 1 >= m_ranges[i].from()) {
            to = std::max(to, m_ranges[i].to());
        } else {
            m_ranges[targetIndex++] = UnicodeRange(from, to);
            from = m_ranges[i].from();
            to = m_ranges[i].to();
        }
    }
    m_ranges[targetIndex++] = UnicodeRange(from, to);
    m_ranges.shrink(targetIndex);
}

bool CSSFontFace::UnicodeRangeSet::contains(UChar32 c) const
{
    if (isEntireRange())
        return true;
    Vector<UnicodeRange>::const_iterator it = std::lower_bound(m_ranges.begin(), m_ranges.end(), c);
    return it != m_ranges.end() && it->contains(c);
}

bool CSSFontFace::UnicodeRangeSet::intersectsWith(const String& text) const
{
    if (text.isEmpty())
        return false;
    if (isEntireRange())
        return true;
    if (text.is8Bit() && m_ranges[0].from() >= 0x100)
        return false;

    unsigned index = 0;
    while (index < text.length()) {
        UChar32 c = text.characterStartingAt(index);
        index += U16_LENGTH(c);
        if (contains(c))
            return true;
    }
    return false;
}

void CSSFontFace::trace(Visitor* visitor)
{
    visitor->trace(m_segmentedFontFace);
    visitor->trace(m_sources);
    visitor->trace(m_fontFace);
}

}
