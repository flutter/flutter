/*
 * Copyright (c) 2013, Google Inc. All rights reserved.
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

#include "config.h"
#include "core/testing/DummyPageHolder.h"

#include "core/frame/LocalDOMWindow.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/loader/EmptyClients.h"
#include "public/platform/ServiceProvider.h"
#include "wtf/Assertions.h"

namespace blink {
namespace {

class DummyServiceProvider : public blink::ServiceProvider {
public:
    mojo::NavigatorHost* NavigatorHost() { return 0; }
    mojo::Shell* Shell() { return 0; }
};

}

PassOwnPtr<DummyPageHolder> DummyPageHolder::create(
    const IntSize& initialViewSize,
    Page::PageClients* pageClients,
    PassOwnPtr<FrameLoaderClient> frameLoaderClient) {
    return adoptPtr(new DummyPageHolder(initialViewSize, pageClients, frameLoaderClient));
}

DummyPageHolder::DummyPageHolder(
    const IntSize& initialViewSize,
    Page::PageClients* pageClients,
    PassOwnPtr<FrameLoaderClient> frameLoaderClient)
{
    DEFINE_STATIC_LOCAL(DummyServiceProvider, serviceProvider, ());

    if (!pageClients) {
        fillWithEmptyClients(m_pageClients);
    } else {
        m_pageClients.chromeClient = pageClients->chromeClient;
        m_pageClients.editorClient = pageClients->editorClient;
        m_pageClients.spellCheckerClient = pageClients->spellCheckerClient;
    }
    m_page = adoptPtr(new Page(m_pageClients, serviceProvider));

    // FIXME(sky): Delete the tests that use DummyPageHolder since
    // they no longer work and we're not running them.

    // Settings& settings = m_page->settings();
    // FIXME: http://crbug.com/363843. This needs to find a better way to
    // not create graphics layers.
    // settings.setAcceleratedCompositingEnabled(false);

    m_frameLoaderClient = frameLoaderClient;
    if (!m_frameLoaderClient)
        m_frameLoaderClient = adoptPtr(new EmptyFrameLoaderClient);

    m_frame = LocalFrame::create(m_frameLoaderClient.get(), &m_page->frameHost());
    m_frame->setView(FrameView::create(m_frame.get(), initialViewSize));
}

DummyPageHolder::~DummyPageHolder()
{
    m_page->willBeDestroyed();
    m_page.clear();
#if !ENABLE(OILPAN)
    ASSERT(m_frame->hasOneRef());
#endif
    m_frame.clear();
}

Page& DummyPageHolder::page() const
{
    return *m_page;
}

LocalFrame& DummyPageHolder::frame() const
{
    return *m_frame;
}

FrameView& DummyPageHolder::frameView() const
{
    return *m_frame->view();
}

Document& DummyPageHolder::document() const
{
    return *m_frame->domWindow()->document();
}

} // namespace blink
