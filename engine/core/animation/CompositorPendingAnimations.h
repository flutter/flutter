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

#ifndef CompositorPendingAnimations_h
#define CompositorPendingAnimations_h

#include "core/animation/AnimationPlayer.h"
#include "platform/Timer.h"
#include "platform/heap/Handle.h"
#include "wtf/Vector.h"

namespace blink {

// Manages the starting of pending animations on the compositor following a
// compositing update.
// For CSS Animations, used to synchronize the start of main-thread animations
// with compositor animations when both classes of CSS Animations are triggered
// by the same recalc
class CompositorPendingAnimations final {
    DISALLOW_ALLOCATION();
public:

    CompositorPendingAnimations()
        : m_timer(this, &CompositorPendingAnimations::timerFired)
    { }

    void add(AnimationPlayer*);
    // Returns whether we are waiting for an animation to start and should
    // service again on the next frame.
    bool update(bool startOnCompositor = true);
    void notifyCompositorAnimationStarted(double monotonicAnimationStartTime);

    void trace(Visitor*);

private:
    void timerFired(Timer<CompositorPendingAnimations>*) { update(false); }

    WillBeHeapVector<RefPtrWillBeMember<AnimationPlayer> > m_pending;
    WillBeHeapVector<RefPtrWillBeMember<AnimationPlayer> > m_waitingForCompositorAnimationStart;
    Timer<CompositorPendingAnimations> m_timer;
};

} // namespace blink

#endif
