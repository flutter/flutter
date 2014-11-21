// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAGE_PAGEANIMATOR_H_
#define SKY_ENGINE_CORE_PAGE_PAGEANIMATOR_H_

namespace blink {

class LocalFrame;
class Page;

class PageAnimator {
public:
    explicit PageAnimator(Page*);

    void scheduleVisualUpdate();
    void serviceScriptedAnimations(double monotonicAnimationStartTime);

    void setAnimationFramePending() { m_animationFramePending = true; }
    bool isServicingAnimations() const { return m_servicingAnimations; }
    void updateLayoutAndStyleForPainting(LocalFrame* rootFrame);

private:
    Page* m_page;
    bool m_animationFramePending;
    bool m_servicingAnimations;
    bool m_updatingLayoutAndStyleForPainting;
};

}

#endif  // SKY_ENGINE_CORE_PAGE_PAGEANIMATOR_H_
