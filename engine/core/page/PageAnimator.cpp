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
#include "sky/engine/core/painting/PaintingTasks.h"
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

    view->setFrameRect(view->frameRect());
    view->updateLayoutAndStyleForPainting();

    // TODO(abarth): Remove these calls to updateLayoutAndStyleForPainting
    // once requestPaint callbacks can't dirty layout.
    while (PaintingTasks::serviceRequests())
        view->updateLayoutAndStyleForPainting();

    PaintingTasks::drainCommits();

    ASSERT(m_page->mainFrame()->document()->lifecycle().state() == DocumentLifecycle::StyleAndLayoutClean);
}

}
