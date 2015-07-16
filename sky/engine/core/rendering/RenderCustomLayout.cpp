// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/rendering/RenderCustomLayout.h"

#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/layout/LayoutCallback.h"

namespace blink {

RenderCustomLayout::RenderCustomLayout(ContainerNode* node)
    : RenderBlock(node)
{
}

RenderCustomLayout::~RenderCustomLayout()
{
}

void RenderCustomLayout::computePreferredLogicalWidths()
{
    ASSERT(node()->isElementNode());
    toElement(node())->intrinsicWidthsComputer()->handleEvent();
    clearPreferredLogicalWidthsDirty();
}

void RenderCustomLayout::layout()
{
    ASSERT(node()->isElementNode());
    toElement(node())->layoutManager()->handleEvent();
    clearNeedsLayout();
}

const char* RenderCustomLayout::renderName() const
{
    return "RenderCustomLayout";
}

} // namespace blink

