// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
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

void RenderCustomLayout::layout()
{
    // TODO(ojan): This should really be done by the author code, but
    // if the author code doesn't call layout, then we won't clear the
    // needsLayout bit and we'll assert.
    for (RenderBox* child = firstChildBox(); child; child = child->nextSiblingBox()) {
        child->layoutIfNeeded();
    }

    ASSERT(node()->isElementNode());
    toElement(node())->layoutManager()->handleEvent();
    clearNeedsLayout();
}

const char* RenderCustomLayout::renderName() const
{
    return "RenderCustomLayout";
}

} // namespace blink

