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

#include "config.h"
#include "core/page/Chrome.h"

#include "core/dom/Document.h"
#include "core/frame/LocalFrame.h"
#include "core/page/ChromeClient.h"
#include "core/page/Page.h"
#include "core/rendering/HitTestResult.h"
#include "platform/Logging.h"
#include "platform/geometry/FloatRect.h"
#include "public/platform/WebScreenInfo.h"
#include "wtf/PassRefPtr.h"
#include "wtf/Vector.h"

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

void Chrome::invalidateContentsAndRootView(const IntRect& updateRect)
{
    m_client->invalidateContentsAndRootView(updateRect);
}

void Chrome::invalidateContentsForSlowScroll(const IntRect& updateRect)
{
    m_client->invalidateContentsForSlowScroll(updateRect);
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

void Chrome::mouseDidMoveOverElement(const HitTestResult& result, unsigned modifierFlags)
{
    m_client->mouseDidMoveOverElement(result, modifierFlags);
}

void Chrome::setToolTip(const HitTestResult& result)
{
    // First priority is a potential toolTip representing a spelling or grammar error
    TextDirection toolTipDirection;
    String toolTip = result.spellingToolTip(toolTipDirection);

    // Next we'll consider a tooltip for element with "title" attribute
    if (toolTip.isEmpty())
        toolTip = result.title(toolTipDirection);

    m_client->setToolTip(toolTip, toolTipDirection);
}

void Chrome::dispatchViewportPropertiesDidChange(const ViewportDescription& description) const
{
    m_client->dispatchViewportPropertiesDidChange(description);
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
