/*
 * Copyright 2008, The Android Open Source Project
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "core/dom/Touch.h"

#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "platform/geometry/FloatPoint.h"

namespace blink {

static FloatPoint contentsOffset(LocalFrame* frame)
{
    if (!frame)
        return FloatPoint();
    FrameView* frameView = frame->view();
    if (!frameView)
        return FloatPoint();
    float scale = 1.0f / frame->pageZoomFactor();
    return FloatPoint(frameView->scrollPosition()).scaledBy(scale);
}

Touch::Touch(LocalFrame* frame, EventTarget* target, unsigned identifier, const FloatPoint& screenPos, const FloatPoint& pagePos, const FloatSize& radius, float rotationAngle, float force)
    : m_target(target)
    , m_identifier(identifier)
    , m_clientPos(pagePos - contentsOffset(frame))
    , m_screenPos(screenPos)
    , m_pagePos(pagePos)
    , m_radius(radius)
    , m_rotationAngle(rotationAngle)
    , m_force(force)
{
    ScriptWrappable::init(this);
    float scaleFactor = frame ? frame->pageZoomFactor() : 1.0f;
    m_absoluteLocation = roundedLayoutPoint(pagePos.scaledBy(scaleFactor));
}

Touch::Touch(EventTarget* target, unsigned identifier, const FloatPoint& clientPos, const FloatPoint& screenPos, const FloatPoint& pagePos, const FloatSize& radius, float rotationAngle, float force, LayoutPoint absoluteLocation)
    : m_target(target)
    , m_identifier(identifier)
    , m_clientPos(clientPos)
    , m_screenPos(screenPos)
    , m_pagePos(pagePos)
    , m_radius(radius)
    , m_rotationAngle(rotationAngle)
    , m_force(force)
    , m_absoluteLocation(absoluteLocation)
{
    ScriptWrappable::init(this);
}

PassRefPtrWillBeRawPtr<Touch> Touch::cloneWithNewTarget(EventTarget* eventTarget) const
{
    return adoptRefWillBeNoop(new Touch(eventTarget, m_identifier, m_clientPos, m_screenPos, m_pagePos, m_radius, m_rotationAngle, m_force, m_absoluteLocation));
}

void Touch::trace(Visitor* visitor)
{
    visitor->trace(m_target);
}

} // namespace blink
