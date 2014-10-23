/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebTransformAnimationCurve_h
#define WebTransformAnimationCurve_h

#include "WebCommon.h"
#include "WebCompositorAnimationCurve.h"
#include "WebTransformKeyframe.h"

namespace blink {

// A keyframed transform animation curve.
class WebTransformAnimationCurve : public WebCompositorAnimationCurve {
public:
    virtual ~WebTransformAnimationCurve() { }

    // Adds the keyframe with the default timing function (ease).
    virtual void add(const WebTransformKeyframe&) = 0;
    virtual void add(const WebTransformKeyframe&, TimingFunctionType) = 0;
    // Adds the keyframe with a custom, bezier timing function. Note, it is
    // assumed that x0 = y0 = 0, and x3 = y3 = 1.
    virtual void add(const WebTransformKeyframe&, double x1, double y1, double x2, double y2) = 0;
};

} // namespace blink

#endif // WebTransformAnimationCurve_h
