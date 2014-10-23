/*
 * Copyright (C) 2006, 2007 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Igalia S.L
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

#include "config.h"
#include "core/page/ContextMenuController.h"

#include "core/dom/Document.h"
#include "core/dom/Node.h"
#include "core/events/Event.h"
#include "core/events/MouseEvent.h"
#include "core/events/RelatedEvent.h"
#include "core/frame/LocalFrame.h"
#include "core/page/ContextMenuClient.h"
#include "core/page/ContextMenuProvider.h"
#include "core/page/EventHandler.h"
#include "platform/ContextMenu.h"
#include "platform/ContextMenuItem.h"

namespace blink {

ContextMenuController::ContextMenuController(Page*, ContextMenuClient* client)
    : m_client(client)
{
    ASSERT_ARG(client, client);
}

ContextMenuController::~ContextMenuController()
{
}

PassOwnPtrWillBeRawPtr<ContextMenuController> ContextMenuController::create(Page* page, ContextMenuClient* client)
{
    return adoptPtrWillBeNoop(new ContextMenuController(page, client));
}

void ContextMenuController::trace(Visitor* visitor)
{
    visitor->trace(m_hitTestResult);
}

void ContextMenuController::clearContextMenu()
{
    m_contextMenu.clear();
    if (m_menuProvider)
        m_menuProvider->contextMenuCleared();
    m_menuProvider = nullptr;
    m_client->clearContextMenu();
    m_hitTestResult = HitTestResult();
}

void ContextMenuController::documentDetached(Document* document)
{
    if (Node* innerNode = m_hitTestResult.innerNode()) {
        // Invalidate the context menu info if its target document is detached.
        if (innerNode->document() == document)
            clearContextMenu();
    }
}

void ContextMenuController::handleContextMenuEvent(Event* event)
{
    m_contextMenu = createContextMenu(event);
    if (!m_contextMenu)
        return;
    showContextMenu(event);
}

void ContextMenuController::showContextMenu(Event* event, PassRefPtr<ContextMenuProvider> menuProvider)
{
    m_menuProvider = menuProvider;

    m_contextMenu = createContextMenu(event);
    if (!m_contextMenu) {
        clearContextMenu();
        return;
    }

    m_menuProvider->populateContextMenu(m_contextMenu.get());
    showContextMenu(event);
}

void ContextMenuController::showContextMenuAtPoint(LocalFrame* frame, float x, float y, PassRefPtr<ContextMenuProvider> menuProvider)
{
    m_menuProvider = menuProvider;

    LayoutPoint location(x, y);
    m_contextMenu = createContextMenu(frame, location);
    if (!m_contextMenu) {
        clearContextMenu();
        return;
    }

    m_menuProvider->populateContextMenu(m_contextMenu.get());
    showContextMenu(nullptr);
}

PassOwnPtr<ContextMenu> ContextMenuController::createContextMenu(Event* event)
{
    ASSERT(event);

    if (!event->isMouseEvent())
        return nullptr;

    MouseEvent* mouseEvent = toMouseEvent(event);
    return createContextMenu(event->target()->toNode()->document().frame(), mouseEvent->absoluteLocation());
}

PassOwnPtr<ContextMenu> ContextMenuController::createContextMenu(LocalFrame* frame, const LayoutPoint& location)
{
    HitTestResult result(location);

    if (frame)
        result = frame->eventHandler().hitTestResultAtPoint(location, HitTestRequest::ReadOnly | HitTestRequest::Active);

    if (!result.innerNonSharedNode())
        return nullptr;

    m_hitTestResult = result;

    return adoptPtr(new ContextMenu);
}

void ContextMenuController::showContextMenu(Event* event)
{
    m_client->showContextMenu(m_contextMenu.get());
    if (event)
        event->setDefaultHandled();
}

void ContextMenuController::contextMenuItemSelected(const ContextMenuItem* item)
{
    ASSERT(item->type() == ActionType || item->type() == CheckableActionType);

    if (item->action() < ContextMenuItemBaseCustomTag || item->action() > ContextMenuItemLastCustomTag)
        return;

    ASSERT(m_menuProvider);
    m_menuProvider->contextMenuItemSelected(item);
}

} // namespace blink
