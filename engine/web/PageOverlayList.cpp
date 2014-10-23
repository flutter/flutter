/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. AND ITS CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL GOOGLE INC.
 * OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "web/PageOverlayList.h"

#include "public/web/WebPageOverlay.h"
#include "web/PageOverlay.h"
#include "web/WebViewImpl.h"

namespace blink {

PassOwnPtr<PageOverlayList> PageOverlayList::create(WebViewImpl* viewImpl)
{
    return adoptPtr(new PageOverlayList(viewImpl));
}

PageOverlayList::PageOverlayList(WebViewImpl* viewImpl)
    : m_viewImpl(viewImpl)
{
}

PageOverlayList::~PageOverlayList()
{
}

bool PageOverlayList::add(WebPageOverlay* overlay, int zOrder)
{
    bool added = false;
    size_t index = find(overlay);
    if (index == WTF::kNotFound) {
        OwnPtr<PageOverlay> pageOverlay = PageOverlay::create(m_viewImpl, overlay);
        m_pageOverlays.append(pageOverlay.release());
        index = m_pageOverlays.size() - 1;
        added = true;
    }

    PageOverlay* pageOverlay = m_pageOverlays[index].get();
    pageOverlay->setZOrder(zOrder);

    // Adjust page overlay list order based on their z-order numbers. We first
    // check if we need to move the overlay up and do so if needed. Otherwise,
    // check if we need to move it down.
    bool zOrderChanged = false;
    for (size_t i = index; i + 1 < m_pageOverlays.size(); ++i) {
        if (m_pageOverlays[i]->zOrder() >= m_pageOverlays[i + 1]->zOrder()) {
            m_pageOverlays[i].swap(m_pageOverlays[i + 1]);
            zOrderChanged = true;
        }
    }

    if (!zOrderChanged) {
        for (size_t i = index; i >= 1; --i) {
            if (m_pageOverlays[i]->zOrder() < m_pageOverlays[i - 1]->zOrder()) {
                m_pageOverlays[i].swap(m_pageOverlays[i - 1]);
                zOrderChanged = true;
            }
        }
    }

    // If we did move the overlay, that means z-order is changed and we need to
    // update overlay layers' z-order. Otherwise, just update current overlay.
    if (zOrderChanged) {
        for (size_t i = 0; i < m_pageOverlays.size(); ++i)
            m_pageOverlays[i]->clear();
        update();
    } else
        pageOverlay->update();

    return added;
}

bool PageOverlayList::remove(WebPageOverlay* overlay)
{
    size_t index = find(overlay);
    if (index == WTF::kNotFound)
        return false;

    m_pageOverlays[index]->clear();
    m_pageOverlays.remove(index);
    return true;
}

void PageOverlayList::update()
{
    for (size_t i = 0; i < m_pageOverlays.size(); ++i)
        m_pageOverlays[i]->update();
}

void PageOverlayList::paintWebFrame(GraphicsContext& gc)
{
    for (size_t i = 0; i < m_pageOverlays.size(); ++i)
        m_pageOverlays[i]->paintWebFrame(gc);
}

size_t PageOverlayList::find(WebPageOverlay* overlay)
{
    for (size_t i = 0; i < m_pageOverlays.size(); ++i) {
        if (m_pageOverlays[i]->overlay() == overlay)
            return i;
    }
    return WTF::kNotFound;
}

size_t PageOverlayList::findGraphicsLayer(GraphicsLayer* layer)
{
    for (size_t i = 0; i < m_pageOverlays.size(); ++i) {
        if (m_pageOverlays[i]->graphicsLayer() == layer)
            return i;
    }
    return WTF::kNotFound;
}

} // namespace blink
