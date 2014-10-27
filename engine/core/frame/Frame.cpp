/*
 * Copyright (C) 1998, 1999 Torben Weis <weis@kde.org>
 *                     1999 Lars Knoll <knoll@kde.org>
 *                     1999 Antti Koivisto <koivisto@kde.org>
 *                     2000 Simon Hausmann <hausmann@kde.org>
 *                     2000 Stefan Schimanski <1Stein@gmx.de>
 *                     2001 George Staikos <staikos@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2005 Alexey Proskuryakov <ap@nypop.com>
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008 Google Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "core/frame/Frame.h"

#include "core/events/Event.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/FrameHost.h"
#include "core/frame/Settings.h"
#include "core/loader/EmptyClients.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/page/EventHandler.h"
#include "core/page/FocusController.h"
#include "core/page/Page.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderPart.h"
#include "platform/graphics/GraphicsLayer.h"
#include "public/platform/WebLayer.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefCountedLeakCounter.h"

namespace blink {

DEFINE_DEBUG_ONLY_GLOBAL(WTF::RefCountedLeakCounter, frameCounter, ("Frame"));

Frame::Frame(FrameClient* client, FrameHost* host)
    : m_host(host)
    , m_client(client)
{
    ASSERT(page());

#ifndef NDEBUG
    frameCounter.increment();
#endif
}

Frame::~Frame()
{
    setDOMWindow(nullptr);

    // FIXME: We should not be doing all this work inside the destructor

#ifndef NDEBUG
    frameCounter.decrement();
#endif
}

void Frame::detachChildren()
{
    // FIXME(sky): remove
}

FrameHost* Frame::host() const
{
    return m_host;
}

Page* Frame::page() const
{
    if (m_host)
        return &m_host->page();
    return 0;
}

Settings* Frame::settings() const
{
    if (m_host)
        return &m_host->settings();
    return 0;
}

void Frame::setDOMWindow(PassRefPtr<LocalDOMWindow> domWindow)
{
    if (m_domWindow)
        m_domWindow->reset();
    m_domWindow = domWindow;
}

static ChromeClient& emptyChromeClient()
{
    DEFINE_STATIC_LOCAL(EmptyChromeClient, client, ());
    return client;
}

ChromeClient& Frame::chromeClient() const
{
    if (Page* page = this->page())
        return page->chrome().client();
    return emptyChromeClient();
}

} // namespace blink
