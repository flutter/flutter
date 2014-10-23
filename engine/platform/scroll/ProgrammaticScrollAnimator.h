// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ProgrammaticScrollAnimator_h
#define ProgrammaticScrollAnimator_h

#include "platform/geometry/FloatPoint.h"
#include "wtf/FastAllocBase.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class ScrollableArea;
class WebScrollOffsetAnimationCurve;

// Animator for fixed-destination scrolls, such as those triggered by
// CSSOM View scroll APIs.
class ProgrammaticScrollAnimator {
    WTF_MAKE_NONCOPYABLE(ProgrammaticScrollAnimator);
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<ProgrammaticScrollAnimator> create(ScrollableArea*);

    ~ProgrammaticScrollAnimator();

    void animateToOffset(FloatPoint);
    void cancelAnimation();
    void tickAnimation(double monotonicTime);

private:
    explicit ProgrammaticScrollAnimator(ScrollableArea*);

    void resetAnimationState();

    ScrollableArea* m_scrollableArea;
    OwnPtr<WebScrollOffsetAnimationCurve> m_animationCurve;
    FloatPoint m_targetOffset;
    double m_startTime;
};

} // namespace blink

#endif // ProgrammaticScrollAnimator_h
