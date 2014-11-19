// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/rendering/compositing/CompositingReasonFinder.h"

#include "gen/sky/core/CSSPropertyNames.h"
#include "core/dom/Document.h"
#include "core/frame/FrameView.h"
#include "core/frame/Settings.h"
#include "core/page/Page.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"

namespace blink {

CompositingReasonFinder::CompositingReasonFinder(RenderView& renderView)
    : m_renderView(renderView)
    , m_compositingTriggers(static_cast<CompositingTriggerFlags>(AllCompositingTriggers))
{
    updateTriggers();
}

void CompositingReasonFinder::updateTriggers()
{
    m_compositingTriggers = 0;

    Settings& settings = m_renderView.document().page()->settings();
    if (settings.preferCompositingToLCDTextEnabled()) {
        m_compositingTriggers |= ScrollableInnerFrameTrigger;
        m_compositingTriggers |= OverflowScrollTrigger;
    }
}

bool CompositingReasonFinder::hasOverflowScrollTrigger() const
{
    return m_compositingTriggers & OverflowScrollTrigger;
}

CompositingReasons CompositingReasonFinder::directReasons(const RenderLayer* layer) const
{
    ASSERT(potentialCompositingReasonsFromStyle(layer->renderer()) == layer->potentialCompositingReasonsFromStyle());
    CompositingReasons styleDeterminedDirectCompositingReasons = layer->potentialCompositingReasonsFromStyle() & CompositingReasonComboAllDirectStyleDeterminedReasons;
    return styleDeterminedDirectCompositingReasons | nonStyleDeterminedDirectReasons(layer);
}

// This information doesn't appear to be incorporated into CompositingReasons.
bool CompositingReasonFinder::requiresCompositingForScrollableFrame() const
{
    // FIXME(sky)
    return false;
}

CompositingReasons CompositingReasonFinder::potentialCompositingReasonsFromStyle(RenderObject* renderer) const
{
    CompositingReasons reasons = CompositingReasonNone;

    RenderStyle* style = renderer->style();

    if (requiresCompositingForTransform(renderer))
        reasons |= CompositingReason3DTransform;

    if (style->backfaceVisibility() == BackfaceVisibilityHidden)
        reasons |= CompositingReasonBackfaceVisibilityHidden;

    if (requiresCompositingForAnimation(style))
        reasons |= CompositingReasonActiveAnimation;

    if (style->hasWillChangeCompositingHint() && !style->subtreeWillChangeContents())
        reasons |= CompositingReasonWillChangeCompositingHint;

    if (style->hasInlineTransform())
        reasons |= CompositingReasonInlineTransform;

    if (style->transformStyle3D() == TransformStyle3DPreserve3D)
        reasons |= CompositingReasonPreserve3DWith3DDescendants;

    if (style->hasPerspective())
        reasons |= CompositingReasonPerspectiveWith3DDescendants;

    // If the implementation of createsGroup changes, we need to be aware of that in this part of code.
    ASSERT((renderer->isTransparent() || renderer->hasMask() || renderer->hasFilter()) == renderer->createsGroup());

    if (style->hasMask())
        reasons |= CompositingReasonMaskWithCompositedDescendants;

    if (style->hasFilter())
        reasons |= CompositingReasonFilterWithCompositedDescendants;

    // See RenderLayer::updateTransform for an explanation of why we check both.
    if (renderer->hasTransform() && style->hasTransform())
        reasons |= CompositingReasonTransformWithCompositedDescendants;

    if (renderer->isTransparent())
        reasons |= CompositingReasonOpacityWithCompositedDescendants;

    ASSERT(!(reasons & ~CompositingReasonComboAllStyleDeterminedReasons));
    return reasons;
}

bool CompositingReasonFinder::requiresCompositingForTransform(RenderObject* renderer) const
{
    // Note that we ask the renderer if it has a transform, because the style may have transforms,
    // but the renderer may be an inline that doesn't suppport them.
    return renderer->hasTransform() && renderer->style()->transform().has3DOperation();
}

CompositingReasons CompositingReasonFinder::nonStyleDeterminedDirectReasons(const RenderLayer* layer) const
{
    CompositingReasons directReasons = CompositingReasonNone;
    RenderObject* renderer = layer->renderer();

    if (hasOverflowScrollTrigger()) {
        if (layer->clipParent())
            directReasons |= CompositingReasonOutOfFlowClipping;

        if (const RenderLayer* scrollingAncestor = layer->ancestorScrollingLayer()) {
            if (scrollingAncestor->needsCompositedScrolling() && layer->scrollParent())
                directReasons |= CompositingReasonOverflowScrollingParent;
        }

        if (layer->needsCompositedScrolling())
            directReasons |= CompositingReasonOverflowScrollingTouch;
    }

    directReasons |= renderer->additionalCompositingReasons();

    ASSERT(!(directReasons & CompositingReasonComboAllStyleDeterminedReasons));
    return directReasons;
}

bool CompositingReasonFinder::requiresCompositingForAnimation(RenderStyle* style) const
{
    if (style->subtreeWillChangeContents())
        return style->isRunningAnimationOnCompositor();

    return style->shouldCompositeForCurrentAnimations();
}

}
