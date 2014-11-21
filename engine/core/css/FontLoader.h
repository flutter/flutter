// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FontLoader_h
#define FontLoader_h

#include "sky/engine/core/fetch/ResourceLoader.h"
#include "sky/engine/core/fetch/ResourcePtr.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class CSSFontSelector;
class FontResource;

class FontLoader : public RefCounted<FontLoader> {
public:
    static PassRefPtr<FontLoader> create(CSSFontSelector* fontSelector, ResourceFetcher* fetcher)
    {
        return adoptRef(new FontLoader(fontSelector, fetcher));
    }
    ~FontLoader();

    void addFontToBeginLoading(FontResource*);
    void loadPendingFonts();
    void fontFaceInvalidated();

#if !ENABLE(OILPAN)
    void clearResourceFetcherAndFontSelector();
#endif

private:
    FontLoader(CSSFontSelector*, ResourceFetcher*);
    void beginLoadTimerFired(Timer<FontLoader>*);
    void clearPendingFonts();

    Timer<FontLoader> m_beginLoadingTimer;

    typedef Vector<std::pair<ResourcePtr<FontResource>, ResourceLoader::RequestCountTracker> > FontsToLoadVector;
    FontsToLoadVector m_fontsToBeginLoading;
    RawPtr<CSSFontSelector> m_fontSelector;
    RawPtr<ResourceFetcher> m_resourceFetcher;
};

} // namespace blink

#endif // FontLoader_h
