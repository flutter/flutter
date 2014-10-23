// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FontLoader_h
#define FontLoader_h

#include "core/fetch/ResourceLoader.h"
#include "core/fetch/ResourcePtr.h"
#include "platform/Timer.h"
#include "platform/heap/Handle.h"
#include "wtf/Vector.h"

namespace blink {

class CSSFontSelector;
class FontResource;

class FontLoader : public RefCountedWillBeGarbageCollectedFinalized<FontLoader> {
public:
    static PassRefPtrWillBeRawPtr<FontLoader> create(CSSFontSelector* fontSelector, ResourceFetcher* fetcher)
    {
        return adoptRefWillBeNoop(new FontLoader(fontSelector, fetcher));
    }
    ~FontLoader();

    void addFontToBeginLoading(FontResource*);
    void loadPendingFonts();
    void fontFaceInvalidated();

#if !ENABLE(OILPAN)
    void clearResourceFetcherAndFontSelector();
#endif

    void trace(Visitor*);

private:
    FontLoader(CSSFontSelector*, ResourceFetcher*);
    void beginLoadTimerFired(Timer<FontLoader>*);
    void clearPendingFonts();

    Timer<FontLoader> m_beginLoadingTimer;

    typedef Vector<std::pair<ResourcePtr<FontResource>, ResourceLoader::RequestCountTracker> > FontsToLoadVector;
    FontsToLoadVector m_fontsToBeginLoading;
    RawPtrWillBeMember<CSSFontSelector> m_fontSelector;
    RawPtrWillBeWeakMember<ResourceFetcher> m_resourceFetcher;
};

} // namespace blink

#endif // FontLoader_h
