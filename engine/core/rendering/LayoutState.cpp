/*
 * Copyright (C) 2007 Apple Inc.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/rendering/LayoutState.h"

#include "core/rendering/RenderInline.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderView.h"
#include "platform/Partitions.h"

namespace blink {

LayoutState::LayoutState(RenderView& view)
    : m_containingBlockLogicalWidthChanged(false)
    , m_next(0)
    , m_renderer(view)
{
    ASSERT(!view.layoutState());
    view.pushLayoutState(*this);
}

LayoutState::LayoutState(RenderBox& renderer, const LayoutSize& offset, bool containingBlockLogicalWidthChanged)
    : m_containingBlockLogicalWidthChanged(containingBlockLogicalWidthChanged)
    , m_next(renderer.view()->layoutState())
    , m_renderer(renderer)
{
    renderer.view()->pushLayoutState(*this);
    bool fixed = renderer.isOutOfFlowPositioned() && renderer.style()->position() == FixedPosition;
    if (fixed) {
        // FIXME: This doesn't work correctly with transforms.
        FloatPoint fixedOffset = renderer.view()->localToAbsolute(FloatPoint(), IsFixed);
        m_layoutOffset = LayoutSize(fixedOffset.x(), fixedOffset.y()) + offset;
    } else {
        m_layoutOffset = m_next->m_layoutOffset + offset;
    }

    if (renderer.isOutOfFlowPositioned() && !fixed) {
        if (RenderObject* container = renderer.container()) {
            if (container->style()->hasInFlowPosition() && container->isRenderInline())
                m_layoutOffset += toRenderInline(container)->offsetForInFlowPositionedInline(renderer);
        }
    }

    // FIXME: <http://bugs.webkit.org/show_bug.cgi?id=13443> Apply control clip if present.
}

LayoutState::LayoutState(RenderObject& root)
    : m_containingBlockLogicalWidthChanged(false)
    , m_next(root.view()->layoutState())
    , m_renderer(root)
{
    ASSERT(!m_next);
    // We'll end up pushing in RenderView itself, so don't bother adding it.
    if (root.isRenderView())
        return;

    root.view()->pushLayoutState(*this);

    RenderObject* container = root.container();
    FloatPoint absContentPoint = container->localToAbsolute(FloatPoint(), UseTransforms);
    m_layoutOffset = LayoutSize(absContentPoint.x(), absContentPoint.y());
}

LayoutState::~LayoutState()
{
    if (m_renderer.view()->layoutState()) {
        ASSERT(m_renderer.view()->layoutState() == this);
        m_renderer.view()->popLayoutState();
    }
}

} // namespace blink
