/*
 * Copyright (C) 2014 Google Inc. All Rights Reserved.
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
 *
 */

#include "config.h"
#include "core/events/NodeEventContext.h"

#include "core/dom/TouchList.h"
#include "core/events/Event.h"
#include "core/events/FocusEvent.h"
#include "core/events/MouseEvent.h"
#include "core/events/TouchEventContext.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(NodeEventContext)

NodeEventContext::NodeEventContext(PassRefPtrWillBeRawPtr<Node> node, PassRefPtrWillBeRawPtr<EventTarget> currentTarget)
    : m_node(node)
    , m_currentTarget(currentTarget)
{
    ASSERT(m_node);
}

void NodeEventContext::trace(Visitor* visitor)
{
    visitor->trace(m_node);
    visitor->trace(m_currentTarget);
    visitor->trace(m_treeScopeEventContext);
}

void NodeEventContext::handleLocalEvents(Event* event) const
{
    if (touchEventContext()) {
        touchEventContext()->handleLocalEvents(event);
    } else if (relatedTarget()) {
        if (event->isMouseEvent()) {
            toMouseEvent(event)->setRelatedTarget(relatedTarget());
        } else if (event->isFocusEvent()) {
            toFocusEvent(event)->setRelatedTarget(relatedTarget());
        }
    }
    event->setTarget(target());
    event->setCurrentTarget(m_currentTarget.get());
    m_node->handleLocalEvents(event);
}

}
