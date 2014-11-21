// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/page/PageAnimator.h"

#include "sky/engine/core/animation/DocumentAnimations.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/page/Chrome.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/platform/Logging.h"

namespace blink {

PageAnimator::PageAnimator(Page* page)
    : m_page(page)
    , m_animationFramePending(false)
    , m_servicingAnimations(false)
    , m_updatingLayoutAndStyleForPainting(false)
{
}

void PageAnimator::serviceScriptedAnimations(double monotonicAnimationStartTime)
{
    m_animationFramePending = false;
    TemporaryChange<bool> servicing(m_servicingAnimations, true);

    Vector<RefPtr<Document> > documents;
    documents.append(m_page->mainFrame()->document());

    WTF_LOG(ScriptedAnimationController, "PageAnimator::serviceScriptedAnimations: #documents = %d",
        static_cast<int>(documents.size()));
    for (size_t i = 0; i < documents.size(); ++i) {
        if (documents[i]->frame()) {
            if (const FrameView::ScrollableAreaSet* scrollableAreas = documents[i]->view()->scrollableAreas()) {
                for (FrameView::ScrollableAreaSet::iterator it = scrollableAreas->begin(); it != scrollableAreas->end(); ++it)
                    (*it)->serviceScrollAnimations(monotonicAnimationStartTime);
            }
        }
    }

    for (size_t i = 0; i < documents.size(); ++i)
        DocumentAnimations::updateAnimationTimingForAnimationFrame(*documents[i], monotonicAnimationStartTime);

    for (size_t i = 0; i < documents.size(); ++i)
        documents[i]->serviceScriptedAnimations(monotonicAnimationStartTime);
}

void PageAnimator::scheduleVisualUpdate()
{
    // FIXME: also include m_animationFramePending here. It is currently not there due to crbug.com/353756.
    if (m_servicingAnimations || m_updatingLayoutAndStyleForPainting)
        return;
    m_page->chrome().scheduleAnimation();
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
