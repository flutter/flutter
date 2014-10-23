// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "platform/scroll/ProgrammaticScrollAnimator.h"

#include "platform/geometry/IntPoint.h"
#include "platform/scroll/ScrollableArea.h"
#include "public/platform/Platform.h"
#include "public/platform/WebCompositorSupport.h"
#include "public/platform/WebScrollOffsetAnimationCurve.h"

namespace blink {

PassOwnPtr<ProgrammaticScrollAnimator> ProgrammaticScrollAnimator::create(ScrollableArea* scrollableArea)
{
    return adoptPtr(new ProgrammaticScrollAnimator(scrollableArea));
}

ProgrammaticScrollAnimator::ProgrammaticScrollAnimator(ScrollableArea* scrollableArea)
    : m_scrollableArea(scrollableArea)
    , m_startTime(0.0)
{
}

ProgrammaticScrollAnimator::~ProgrammaticScrollAnimator()
{
}

void ProgrammaticScrollAnimator::resetAnimationState()
{
    m_animationCurve.clear();
    m_startTime = 0.0;
}

void ProgrammaticScrollAnimator::animateToOffset(FloatPoint offset)
{
    m_startTime = 0.0;
    m_targetOffset = offset;
    m_animationCurve = adoptPtr(Platform::current()->compositorSupport()->createScrollOffsetAnimationCurve(m_targetOffset, WebCompositorAnimationCurve::TimingFunctionTypeEaseInOut));

    m_animationCurve->setInitialValue(FloatPoint(m_scrollableArea->scrollPosition()));
    if (!m_scrollableArea->scheduleAnimation()) {
        resetAnimationState();
        m_scrollableArea->notifyScrollPositionChanged(IntPoint(offset.x(), offset.y()));
    }
}

void ProgrammaticScrollAnimator::cancelAnimation()
{
    resetAnimationState();
}

void ProgrammaticScrollAnimator::tickAnimation(double monotonicTime)
{
    if (m_animationCurve) {
        if (!m_startTime)
            m_startTime = monotonicTime;
        double elapsedTime = monotonicTime - m_startTime;
        bool isFinished = (elapsedTime > m_animationCurve->duration());
        FloatPoint offset = m_animationCurve->getValue(elapsedTime);
        m_scrollableArea->notifyScrollPositionChanged(IntPoint(offset.x(), offset.y()));

        if (isFinished) {
            resetAnimationState();
        } else if (!m_scrollableArea->scheduleAnimation()) {
            m_scrollableArea->notifyScrollPositionChanged(IntPoint(m_targetOffset.x(), m_targetOffset.y()));
            resetAnimationState();
        }
    }
}

} // namespace blink
