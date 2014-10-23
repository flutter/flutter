// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/FontLoader.h"

#include "core/css/CSSFontSelector.h"
#include "core/fetch/FontResource.h"
#include "core/fetch/ResourceFetcher.h"

namespace blink {

FontLoader::FontLoader(CSSFontSelector* fontSelector, ResourceFetcher* resourceFetcher)
    : m_beginLoadingTimer(this, &FontLoader::beginLoadTimerFired)
    , m_fontSelector(fontSelector)
    , m_resourceFetcher(resourceFetcher)
{
}

FontLoader::~FontLoader()
{
#if ENABLE(OILPAN)
    if (!m_resourceFetcher) {
        ASSERT(m_fontsToBeginLoading.isEmpty());
        return;
    }
    m_beginLoadingTimer.stop();
    // This will decrement the request counts on the ResourceFetcher for all the
    // fonts that were pending at the time the FontLoader dies.
    clearPendingFonts();
#endif
}

void FontLoader::addFontToBeginLoading(FontResource* fontResource)
{
    if (!m_resourceFetcher || !fontResource->stillNeedsLoad() || fontResource->loadScheduled())
        return;

    m_fontsToBeginLoading.append(
        std::make_pair(fontResource, ResourceLoader::RequestCountTracker(m_resourceFetcher, fontResource)));
    fontResource->didScheduleLoad();
    if (!m_beginLoadingTimer.isActive())
        m_beginLoadingTimer.startOneShot(0, FROM_HERE);
}

void FontLoader::beginLoadTimerFired(Timer<blink::FontLoader>*)
{
    loadPendingFonts();
}

void FontLoader::loadPendingFonts()
{
    ASSERT(m_resourceFetcher);

    FontsToLoadVector fontsToBeginLoading;
    fontsToBeginLoading.swap(m_fontsToBeginLoading);
    for (FontsToLoadVector::iterator it = fontsToBeginLoading.begin(); it != fontsToBeginLoading.end(); ++it) {
        FontResource* fontResource = it->first.get();
        fontResource->beginLoadIfNeeded(m_resourceFetcher);
    }

    // When the local fontsToBeginLoading vector goes out of scope it will
    // decrement the request counts on the ResourceFetcher for all the fonts
    // that were just loaded.
}

void FontLoader::fontFaceInvalidated()
{
    if (m_fontSelector)
        m_fontSelector->fontFaceInvalidated();
}

#if !ENABLE(OILPAN)
void FontLoader::clearResourceFetcherAndFontSelector()
{
    if (!m_resourceFetcher) {
        ASSERT(m_fontsToBeginLoading.isEmpty());
        return;
    }

    m_beginLoadingTimer.stop();
    clearPendingFonts();
    m_resourceFetcher = nullptr;
    m_fontSelector = nullptr;
}
#endif

void FontLoader::clearPendingFonts()
{
    for (FontsToLoadVector::iterator it = m_fontsToBeginLoading.begin(); it != m_fontsToBeginLoading.end(); ++it)
        it->first->didUnscheduleLoad();
    m_fontsToBeginLoading.clear();
}

void FontLoader::trace(Visitor* visitor)
{
    visitor->trace(m_resourceFetcher);
    visitor->trace(m_fontSelector);
}

} // namespace blink
