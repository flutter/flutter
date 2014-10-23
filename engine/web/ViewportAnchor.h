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

#ifndef ViewportAnchor_h
#define ViewportAnchor_h

#include "platform/geometry/FloatSize.h"
#include "platform/geometry/IntPoint.h"
#include "platform/geometry/IntRect.h"
#include "platform/geometry/LayoutRect.h"
#include "platform/heap/Handle.h"
#include "wtf/RefCounted.h"

namespace blink {

class EventHandler;
class IntSize;
class Node;

// ViewportAnchor provides a way to anchor a viewport origin to a DOM node.
// In particular, the user supplies the current viewport (in CSS coordinates)
// and an anchor point (in view coordinates, e.g., (0, 0) == viewport origin,
// (0.5, 0) == viewport top center). The anchor point tracks the underlying DOM
// node; as the node moves or the view is resized, the viewport anchor maintains
// its orientation relative to the node, and the viewport origin maintains its
// orientation relative to the anchor.
class ViewportAnchor {
    STACK_ALLOCATED();
public:
    explicit ViewportAnchor(EventHandler*);

    void setAnchor(const IntRect& viewRect, const FloatSize& anchorInViewCoords);

    IntPoint computeOrigin(const IntSize& currentViewSize) const;

private:
    RawPtrWillBeMember<EventHandler> m_eventHandler;

    IntRect m_viewRect;

    RefPtrWillBeMember<Node> m_anchorNode;
    LayoutRect m_anchorNodeBounds;

    FloatSize m_anchorInViewCoords;
    FloatSize m_anchorInNodeCoords;
};

} // namespace blink

 #endif
