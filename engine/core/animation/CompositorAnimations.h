/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef CompositorAnimations_h
#define CompositorAnimations_h

#include "core/animation/AnimationEffect.h"
#include "core/animation/Timing.h"
#include "platform/animation/TimingFunction.h"
#include "wtf/Vector.h"

namespace blink {

class Element;
class FloatBox;

// Given an input timing function between keyframe at 0 and keyframe at 1.0, we
// need a timing function such that the behavior with the keyframes swapped is
// equivalent to reversing time with the input timing function and keyframes.
// This means flipping the timing function about x=0.5 and about y=0.5.
// FIXME: Remove once the Compositor natively understands reversing time.
class CompositorAnimationsTimingFunctionReverser {
public:
    static PassRefPtr<TimingFunction> reverse(const LinearTimingFunction& timefunc);
    static PassRefPtr<TimingFunction> reverse(const CubicBezierTimingFunction& timefunc);
    static PassRefPtr<TimingFunction> reverse(const TimingFunction& timefunc);
};

class CompositorAnimations {
public:
    static CompositorAnimations* instance() { return instance(0); }
    static void setInstanceForTesting(CompositorAnimations* newInstance) { instance(newInstance); }

    virtual bool isCandidateForAnimationOnCompositor(const Timing&, const AnimationEffect&);
    virtual bool canStartAnimationOnCompositor(const Element&);
    // FIXME: This should return void. We should know ahead of time whether these animations can be started.
    virtual bool startAnimationOnCompositor(const Element&, double startTime, double timeOffset, const Timing&, const AnimationEffect&, Vector<int>& startedAnimationIds);
    virtual void cancelAnimationOnCompositor(const Element&, int id);
    virtual void pauseAnimationForTestingOnCompositor(const Element&, int id, double pauseTime);

    virtual bool getAnimatedBoundingBox(FloatBox&, const AnimationEffect&, double minValue, double maxValue) const;
protected:
    CompositorAnimations() { }

private:
    static CompositorAnimations* instance(CompositorAnimations* newInstance)
    {
        static CompositorAnimations* instance = new CompositorAnimations();
        if (newInstance) {
            instance = newInstance;
        }
        return instance;
    }
};

} // namespace blink

#endif
