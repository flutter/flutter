// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RemoteFontFaceSource_h
#define RemoteFontFaceSource_h

#include "core/css/CSSFontFaceSource.h"
#include "core/fetch/FontResource.h"
#include "core/fetch/ResourcePtr.h"

namespace blink {

class FontLoader;

class RemoteFontFaceSource : public CSSFontFaceSource, public FontResourceClient {
public:
    explicit RemoteFontFaceSource(FontResource*, PassRefPtrWillBeRawPtr<FontLoader>);
    virtual ~RemoteFontFaceSource();

    virtual FontResource* resource() override { return m_font.get(); }
    virtual bool isLoading() const override;
    virtual bool isLoaded() const override;
    virtual bool isValid() const override;

    void beginLoadIfNeeded() override;
    virtual bool ensureFontData();

    virtual void didStartFontLoad(FontResource*) override;
    virtual void fontLoaded(FontResource*) override;
    virtual void fontLoadWaitLimitExceeded(FontResource*) override;

    // For UMA reporting
    virtual bool hadBlankText() override { return m_histograms.hadBlankText(); }
    void paintRequested() { m_histograms.fallbackFontPainted(); }

    virtual void trace(Visitor*) override;

protected:
    virtual PassRefPtr<SimpleFontData> createFontData(const FontDescription&) override;
    PassRefPtr<SimpleFontData> createLoadingFallbackFontData(const FontDescription&);
    void pruneTable();

private:
    class FontLoadHistograms {
    public:
        FontLoadHistograms() : m_loadStartTime(0), m_fallbackPaintTime(0) { }
        void loadStarted();
        void fallbackFontPainted();
        void recordRemoteFont(const FontResource*);
        void recordFallbackTime(const FontResource*);
        bool hadBlankText() { return m_fallbackPaintTime; }
    private:
        const char* histogramName(const FontResource*);
        double m_loadStartTime;
        double m_fallbackPaintTime;
    };

    ResourcePtr<FontResource> m_font;
    RefPtrWillBeMember<FontLoader> m_fontLoader;
    FontLoadHistograms m_histograms;
};

} // namespace blink

#endif
