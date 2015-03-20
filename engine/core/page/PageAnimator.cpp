// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/page/PageAnimator.h"

#include "sky/engine/core/animation/DocumentAnimations.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/platform/Logging.h"

namespace blink {

PageAnimator::PageAnimator(Page* page)
    : m_page(page)
    , m_servicingAnimations(false)
    , m_updatingLayoutAndStyleForPainting(false)
{
}

void PageAnimator::serviceScriptedAnimations(double monotonicAnimationStartTime)
{
    TemporaryChange<bool> servicing(m_servicingAnimations, true);

    RefPtr<Document> document = m_page->mainFrame()->document();

    DocumentAnimations::updateAnimationTimingForAnimationFrame(*document, monotonicAnimationStartTime);
    document->serviceScriptedAnimations(monotonicAnimationStartTime);
}

void PageAnimator::scheduleVisualUpdate()
{
    if (m_servicingAnimations || m_updatingLayoutAndStyleForPainting)
        return;
    m_page->scheduleVisualUpdate();
}

void PageAnimator::updateLayoutAndStyleForPainting(LocalFrame* rootFrame)
{
    RefPtr<FrameView> view = rootFrame->view();

    TemporaryChange<bool> servicing(m_updatingLayoutAndStyleForPainting, true);

    // In order for our child HWNDs (NativeWindowWidgets) to update properly,
    // they need to be told that we are updating the screen. The problem is that
    // the native widgets need to recalculate their clip region and not overlap
    // any of our non-native widgets. To force the resizing, call
    // setFrameRect(). This will be a quick operation for most frames, but the
    // NativeWindowWidgets will update a proper clipping region.
    view->setFrameRect(view->frameRect());

    // setFrameRect may have the side-effect of causing existing page layout to
    // be invalidated, so layout needs to be called last.
    view->updateLayoutAndStyleForPainting();
}

}
