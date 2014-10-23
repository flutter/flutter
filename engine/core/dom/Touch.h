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

#ifndef Touch_h
#define Touch_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/events/EventTarget.h"
#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/FloatSize.h"
#include "platform/geometry/LayoutPoint.h"
#include "platform/heap/Handle.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"

namespace blink {

class LocalFrame;

class Touch FINAL : public RefCountedWillBeGarbageCollected<Touch>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<Touch> create(LocalFrame* frame, EventTarget* target,
        unsigned identifier, const FloatPoint& screenPos, const FloatPoint& pagePos,
        const FloatSize& radius, float rotationAngle, float force)
    {
        return adoptRefWillBeNoop(
            new Touch(frame, target, identifier, screenPos, pagePos, radius, rotationAngle, force));
    }

    // DOM Touch implementation
    EventTarget* target() const { return m_target.get(); }
    unsigned identifier() const { return m_identifier; }
    double clientX() const { return m_clientPos.x(); }
    double clientY() const { return m_clientPos.y(); }
    double screenX() const { return m_screenPos.x(); }
    double screenY() const { return m_screenPos.y(); }
    double pageX() const { return m_pagePos.x(); }
    double pageY() const { return m_pagePos.y(); }
    double radiusX() const { return m_radius.width(); }
    double webkitRadiusX() const { return m_radius.width(); }
    double radiusY() const { return m_radius.height(); }
    double webkitRadiusY() const { return m_radius.height(); }
    float webkitRotationAngle() const { return m_rotationAngle; }
    float force() const { return m_force; }
    float webkitForce() const { return m_force; }

    // Blink-internal methods
    const LayoutPoint& absoluteLocation() const { return m_absoluteLocation; }
    const FloatPoint& screenLocation() const { return m_screenPos; }
    PassRefPtrWillBeRawPtr<Touch> cloneWithNewTarget(EventTarget*) const;

    void trace(Visitor*);

private:
    Touch(LocalFrame* frame, EventTarget* target, unsigned identifier,
        const FloatPoint& screenPos, const FloatPoint& pagePos,
        const FloatSize& radius, float rotationAngle, float force);

    Touch(EventTarget*, unsigned identifier, const FloatPoint& clientPos,
        const FloatPoint& screenPos, const FloatPoint& pagePos,
        const FloatSize& radius, float rotationAngle, float force, LayoutPoint absoluteLocation);

    RefPtrWillBeMember<EventTarget> m_target;
    unsigned m_identifier;
    // Position relative to the viewport in CSS px.
    FloatPoint m_clientPos;
    // Position relative to the screen in DIPs.
    FloatPoint m_screenPos;
    // Position relative to the page in CSS px.
    FloatPoint m_pagePos;
    // Radius in CSS px.
    FloatSize m_radius;
    float m_rotationAngle;
    float m_force;
    // FIXME(rbyers): Shouldn't we be able to migrate callers to relying on screenPos, pagePos
    // or clientPos? absoluteLocation appears to be the same as pagePos but without browser
    // scale applied.
    LayoutPoint m_absoluteLocation;
};

} // namespace blink

#endif // Touch_h
