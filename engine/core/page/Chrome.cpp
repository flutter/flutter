/*
 * Copyright (C) 2006, 2007, 2009, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2012, Samsung Electronics. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/page/Chrome.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/platform/Logging.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/public/platform/WebScreenInfo.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

Chrome::Chrome(Page* page, ChromeClient* client)
    : m_page(page)
    , m_client(client)
{
    ASSERT(m_client);
}

Chrome::~Chrome()
{
}

PassOwnPtr<Chrome> Chrome::create(Page* page, ChromeClient* client)
{
    return adoptPtr(new Chrome(page, client));
}

IntRect Chrome::rootViewToScreen(const IntRect& rect) const
{
    return m_client->rootViewToScreen(rect);
}

blink::WebScreenInfo Chrome::screenInfo() const
{
    return m_client->screenInfo();
}

void Chrome::setWindowRect(const FloatRect& rect) const
{
    m_client->setWindowRect(rect);
}

FloatRect Chrome::windowRect() const
{
    return m_client->windowRect();
}

FloatRect Chrome::pageRect() const
{
    return m_client->pageRect();
}

void Chrome::focus() const
{
    m_client->focus();
}

bool Chrome::canTakeFocus(FocusType type) const
{
    return m_client->canTakeFocus(type);
}

void Chrome::takeFocus(FocusType type) const
{
    m_client->takeFocus(type);
}

void Chrome::focusedNodeChanged(Node* node) const
{
    m_client->focusedNodeChanged(node);
}

void Chrome::show(NavigationPolicy policy) const
{
    m_client->show(policy);
}

void Chrome::setCursor(const Cursor& cursor)
{
    m_client->setCursor(cursor);
}

void Chrome::scheduleAnimation()
{
    WTF_LOG(ScriptedAnimationController, "Chrome::scheduleAnimation");
    m_page->animator().setAnimationFramePending();
    m_client->scheduleAnimation();
}

void Chrome::willBeDestroyed()
{
    m_client->chromeDestroyed();
}

} // namespace blink
