// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PageAnimator_h
#define PageAnimator_h

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

#endif // PageAnimator_h
