/*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Torch Mobile, Inc.
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

#include "sky/engine/core/fetch/FontResource.h"

#include "sky/engine/core/fetch/ResourceClientWalker.h"
#include "sky/engine/core/html/parser/TextResourceDecoder.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/fonts/FontCustomPlatformData.h"
#include "sky/engine/platform/fonts/FontPlatformData.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/wtf/CurrentTime.h"

namespace blink {

static const double fontLoadWaitLimitSec = 3.0;

enum FontPackageFormat {
    PackageFormatUnknown,
    PackageFormatSFNT,
    PackageFormatWOFF,
    PackageFormatWOFF2,
    PackageFormatSVG,
    PackageFormatEnumMax
};

static FontPackageFormat packageFormatOf(SharedBuffer* buffer)
{
    if (buffer->size() < 4)
        return PackageFormatUnknown;

    const char* data = buffer->data();
    if (data[0] == 'w' && data[1] == 'O' && data[2] == 'F' && data[3] == 'F')
        return PackageFormatWOFF;
    if (data[0] == 'w' && data[1] == 'O' && data[2] == 'F' && data[3] == '2')
        return PackageFormatWOFF2;
    return PackageFormatSFNT;
}

static void recordPackageFormatHistogram(FontPackageFormat format)
{
    blink::Platform::current()->histogramEnumeration("WebFont.PackageFormat", format, PackageFormatEnumMax);
}

FontResource::FontResource(const ResourceRequest& resourceRequest)
    : Resource(resourceRequest, Font)
    , m_state(Unloaded)
    , m_exceedsFontLoadWaitLimit(false)
    , m_corsFailed(false)
    , m_fontLoadWaitLimitTimer(this, &FontResource::fontLoadWaitLimitCallback)
{
}

FontResource::~FontResource()
{
}

void FontResource::didScheduleLoad()
{
    if (m_state == Unloaded)
        m_state = LoadScheduled;
}

void FontResource::didUnscheduleLoad()
{
    if (m_state == LoadScheduled)
        m_state = Unloaded;
}

void FontResource::load(ResourceFetcher*, const ResourceLoaderOptions& options)
{
    // Don't load the file yet. Wait for an access before triggering the load.
    setLoading(true);
    m_options = options;
}

void FontResource::didAddClient(ResourceClient* c)
{
    ASSERT(c->resourceClientType() == FontResourceClient::expectedType());
    Resource::didAddClient(c);
    if (!isLoading())
        static_cast<FontResourceClient*>(c)->fontLoaded(this);
}

void FontResource::beginLoadIfNeeded(ResourceFetcher* dl)
{
    if (m_state != LoadInitiated) {
        m_state = LoadInitiated;
        Resource::load(dl, m_options);
        m_fontLoadWaitLimitTimer.startOneShot(fontLoadWaitLimitSec, FROM_HERE);

        ResourceClientWalker<FontResourceClient> walker(m_clients);
        while (FontResourceClient* client = walker.next())
            client->didStartFontLoad(this);
    }
}

bool FontResource::ensureCustomFontData()
{
    if (!m_fontData && !errorOccurred() && !isLoading()) {
        if (m_data)
            m_fontData = FontCustomPlatformData::create(m_data.get());

        if (m_fontData) {
            recordPackageFormatHistogram(packageFormatOf(m_data.get()));
        } else {
            setStatus(DecodeError);
            recordPackageFormatHistogram(PackageFormatUnknown);
        }
    }
    return m_fontData;
}

FontPlatformData FontResource::platformDataFromCustomData(float size, bool bold, bool italic, FontOrientation orientation, FontWidthVariant widthVariant)
{
    ASSERT(m_fontData);
    return m_fontData->fontPlatformData(size, bold, italic, orientation, widthVariant);
}

bool FontResource::isSafeToUnlock() const
{
    return m_data->hasOneRef();
}

void FontResource::fontLoadWaitLimitCallback(Timer<FontResource>*)
{
    if (!isLoading())
        return;
    m_exceedsFontLoadWaitLimit = true;
    ResourceClientWalker<FontResourceClient> walker(m_clients);
    while (FontResourceClient* client = walker.next())
        client->fontLoadWaitLimitExceeded(this);
}

void FontResource::allClientsRemoved()
{
    m_fontData.clear();
    Resource::allClientsRemoved();
}

void FontResource::checkNotify()
{
    m_fontLoadWaitLimitTimer.stop();
    ResourceClientWalker<FontResourceClient> w(m_clients);
    while (FontResourceClient* c = w.next())
        c->fontLoaded(this);
}

}
