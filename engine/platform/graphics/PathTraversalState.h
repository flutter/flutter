/*
 * Copyright (C) 2006, 2007 Eric Seidel <eric@webkit.org>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
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

#ifndef PathTraversalState_h
#define PathTraversalState_h

#include "platform/PlatformExport.h"
#include "platform/geometry/FloatPoint.h"

namespace blink {

class PLATFORM_EXPORT PathTraversalState {
public:
    enum PathTraversalAction {
        TraversalTotalLength,
        TraversalPointAtLength,
        TraversalSegmentAtLength,
        TraversalNormalAngleAtLength
    };

    PathTraversalState(PathTraversalAction);

    float closeSubpath();
    float moveTo(const FloatPoint&);
    float lineTo(const FloatPoint&);
    float quadraticBezierTo(const FloatPoint& newControl, const FloatPoint& newEnd);
    float cubicBezierTo(const FloatPoint& newControl1, const FloatPoint& newControl2, const FloatPoint& newEnd);

    void processSegment();

public:
    PathTraversalAction m_action;
    bool m_success;

    FloatPoint m_current;
    FloatPoint m_start;

    float m_totalLength;
    unsigned m_segmentIndex;
    float m_desiredLength;

    // For normal calculations
    FloatPoint m_previous;
    float m_normalAngle; // degrees
};

} // namespace blink

#endif
