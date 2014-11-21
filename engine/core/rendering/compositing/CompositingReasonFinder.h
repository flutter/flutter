// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_RENDERING_COMPOSITING_COMPOSITINGREASONFINDER_H_
#define SKY_ENGINE_CORE_RENDERING_COMPOSITING_COMPOSITINGREASONFINDER_H_

#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/compositing/CompositingTriggers.h"
#include "sky/engine/platform/graphics/CompositingReasons.h"

namespace blink {

class RenderObject;
class RenderView;

class CompositingReasonFinder {
    WTF_MAKE_NONCOPYABLE(CompositingReasonFinder);
public:
    explicit CompositingReasonFinder(RenderView&);

    CompositingReasons potentialCompositingReasonsFromStyle(RenderObject*) const;
    CompositingReasons directReasons(const RenderLayer*) const;

    void updateTriggers();

    bool hasOverflowScrollTrigger() const;
    bool requiresCompositingForScrollableFrame() const;

private:
    CompositingReasons nonStyleDeterminedDirectReasons(const RenderLayer*) const;

    bool requiresCompositingForTransform(RenderObject*) const;
    bool requiresCompositingForAnimation(RenderStyle*) const;

    RenderView& m_renderView;
    CompositingTriggerFlags m_compositingTriggers;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_COMPOSITING_COMPOSITINGREASONFINDER_H_
