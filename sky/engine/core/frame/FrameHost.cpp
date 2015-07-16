/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/core/frame/FrameHost.h"

#include "sky/engine/core/page/Page.h"

namespace blink {

PassOwnPtr<FrameHost> FrameHost::create(Page& page, ServiceProvider* services)
{
    return adoptPtr(new FrameHost(page, services));
}

PassOwnPtr<FrameHost> FrameHost::createDummy(Settings* settings)
{
    return adoptPtr(new FrameHost(settings));
}

FrameHost::FrameHost(Page& page, ServiceProvider* services)
    : m_page(&page)
    , m_services(services)
    , m_settings(nullptr)
{
}

FrameHost::FrameHost(Settings* settings)
    : m_page(nullptr)
    , m_services(nullptr)
    , m_settings(settings)
{
}

// Explicitly in the .cpp to avoid default constructor in .h
FrameHost::~FrameHost()
{
}

Settings& FrameHost::settings() const
{
    if (m_settings)
        return *m_settings;
    return m_page->settings();
}

float FrameHost::deviceScaleFactor() const
{
    if (m_page)
        return m_page->deviceScaleFactor();
    return 1.0;
}

}
