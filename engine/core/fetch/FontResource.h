/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef FontResource_h
#define FontResource_h

#include "core/fetch/ResourceClient.h"
#include "core/fetch/ResourcePtr.h"
#include "platform/Timer.h"
#include "platform/fonts/FontOrientation.h"
#include "platform/fonts/FontWidthVariant.h"
#include "wtf/OwnPtr.h"

namespace blink {

class Document;
class ResourceFetcher;
class FontPlatformData;
class SVGFontElement;
class FontCustomPlatformData;

class FontResource FINAL : public Resource {
public:
    typedef ResourceClient ClientType;

    FontResource(const ResourceRequest&);
    virtual ~FontResource();
    virtual void trace(Visitor*) OVERRIDE;

    virtual void load(ResourceFetcher*, const ResourceLoaderOptions&) OVERRIDE;

    virtual void didAddClient(ResourceClient*) OVERRIDE;

    virtual void allClientsRemoved() OVERRIDE;
    void beginLoadIfNeeded(ResourceFetcher* dl);
    virtual bool stillNeedsLoad() const OVERRIDE { return m_state != LoadInitiated; }
    bool exceedsFontLoadWaitLimit() const { return m_exceedsFontLoadWaitLimit; }

    bool loadScheduled() const { return m_state != Unloaded; }
    void didScheduleLoad();
    void didUnscheduleLoad();

    void setCORSFailed() { m_corsFailed = true; }
    bool isCORSFailed() const { return m_corsFailed; }

    bool ensureCustomFontData();
    FontPlatformData platformDataFromCustomData(float size, bool bold, bool italic, FontOrientation = Horizontal, FontWidthVariant = RegularWidth);

protected:
    virtual bool isSafeToUnlock() const OVERRIDE;

private:
    virtual void checkNotify() OVERRIDE;
    void fontLoadWaitLimitCallback(Timer<FontResource>*);

    enum State { Unloaded, LoadScheduled, LoadInitiated };

    OwnPtr<FontCustomPlatformData> m_fontData;
    State m_state;
    bool m_exceedsFontLoadWaitLimit;
    bool m_corsFailed;
    Timer<FontResource> m_fontLoadWaitLimitTimer;

    friend class MemoryCache;
};

DEFINE_RESOURCE_TYPE_CASTS(Font);

class FontResourceClient : public ResourceClient {
public:
    virtual ~FontResourceClient() { }
    static ResourceClientType expectedType() { return FontType; }
    virtual ResourceClientType resourceClientType() const OVERRIDE FINAL { return expectedType(); }
    virtual void fontLoaded(FontResource*) { }
    virtual void didStartFontLoad(FontResource*) { }
    virtual void fontLoadWaitLimitExceeded(FontResource*) { }
};

}

#endif
