// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/PaintInvalidationState.h"

#include "sky/engine/core/rendering/RenderInline.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/Partitions.h"

namespace blink {

PaintInvalidationState::PaintInvalidationState(const RenderView& renderView)
    : m_clipped(false)
    , m_cachedOffsetsEnabled(true)
    , m_forceCheckForPaintInvalidation(false)
    , m_paintInvalidationContainer(*renderView.containerForPaintInvalidation())
    , m_renderer(renderView)
{
    bool establishesPaintInvalidationContainer = &m_renderer == &m_paintInvalidationContainer;
    if (!establishesPaintInvalidationContainer) {
        if (!renderView.supportsPaintInvalidationStateCachedOffsets()) {
            m_cachedOffsetsEnabled = false;
            return;
        }
        FloatPoint point = renderView.localToContainerPoint(FloatPoint(), &m_paintInvalidationContainer, TraverseDocumentBoundaries);
        m_paintOffset = LayoutSize(point.x(), point.y());
    }
    m_clipRect = renderView.viewRect();
    m_clipRect.move(m_paintOffset);
    m_clipped = true;
}

PaintInvalidationState::PaintInvalidationState(const PaintInvalidationState& next, RenderLayerModelObject& renderer, const RenderLayerModelObject& paintInvalidationContainer)
    : m_clipped(false)
    , m_cachedOffsetsEnabled(true)
    , m_forceCheckForPaintInvalidation(next.m_forceCheckForPaintInvalidation)
    , m_paintInvalidationContainer(paintInvalidationContainer)
    , m_renderer(renderer)
{
    // FIXME: SVG could probably benefit from a stack-based optimization like html does. crbug.com/391054
    bool establishesPaintInvalidationContainer = &m_renderer == &m_paintInvalidationContainer;

    if (establishesPaintInvalidationContainer) {
        // When we hit a new paint invalidation container, we don't need to
        // continue forcing a check for paint invalidation because movement
        // from our parents will just move the whole invalidation container.
        m_forceCheckForPaintInvalidation = false;
    } else {
        if (!renderer.supportsPaintInvalidationStateCachedOffsets() || !next.m_cachedOffsetsEnabled) {
            m_cachedOffsetsEnabled = false;
        } else {
            LayoutSize offset = m_renderer.isBox() ? toRenderBox(renderer).locationOffset() : LayoutSize();
            m_paintOffset = next.m_paintOffset + offset;

            if (m_renderer.isOutOfFlowPositioned()) {
                if (RenderObject* container = m_renderer.container()) {
                    if (container->style()->hasInFlowPosition() && container->isRenderInline())
                        m_paintOffset += toRenderInline(container)->offsetForInFlowPositionedInline(toRenderBox(renderer));
                }
            }

            if (m_renderer.style()->hasInFlowPosition() && renderer.hasLayer())
                m_paintOffset += renderer.layer()->offsetForInFlowPosition();
        }

        m_clipped = next.m_clipped;
        if (m_clipped)
            m_clipRect = next.m_clipRect;
    }

    applyClipIfNeeded(renderer);

    // FIXME: <http://bugs.webkit.org/show_bug.cgi?id=13443> Apply control clip if present.
}

void PaintInvalidationState::applyClipIfNeeded(const RenderObject& renderer)
{
    if (!renderer.hasOverflowClip())
        return;

    const RenderBox& box = toRenderBox(renderer);
    LayoutRect clipRect(toPoint(m_paintOffset), box.layer()->size());
    if (m_clipped) {
        m_clipRect.intersect(clipRect);
    } else {
        m_clipRect = clipRect;
        m_clipped = true;
    }
    m_paintOffset -= box.scrolledContentOffset();
}

} // namespace blink
