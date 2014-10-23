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

#ifndef AnimationTimeline_h
#define AnimationTimeline_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/animation/AnimationEffect.h"
#include "core/animation/AnimationPlayer.h"
#include "core/dom/Element.h"
#include "platform/Timer.h"
#include "platform/heap/Handle.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"

namespace blink {

class Document;
class AnimationNode;

// AnimationTimeline is constructed and owned by Document, and tied to its lifecycle.
class AnimationTimeline : public RefCountedWillBeGarbageCollectedFinalized<AnimationTimeline>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    class PlatformTiming : public NoBaseWillBeGarbageCollectedFinalized<PlatformTiming> {

    public:
        // Calls AnimationTimeline's wake() method after duration seconds.
        virtual void wakeAfter(double duration) = 0;
        virtual void cancelWake() = 0;
        virtual void serviceOnNextFrame() = 0;
        virtual ~PlatformTiming() { }
        virtual void trace(Visitor*) { }
    };

    static PassRefPtrWillBeRawPtr<AnimationTimeline> create(Document*, PassOwnPtrWillBeRawPtr<PlatformTiming> = nullptr);
    ~AnimationTimeline();

    void serviceAnimations(TimingUpdateReason);

    // Creates a player attached to this timeline, but without a start time.
    AnimationPlayer* createAnimationPlayer(AnimationNode*);
    AnimationPlayer* play(AnimationNode*);
    WillBeHeapVector<RefPtrWillBeMember<AnimationPlayer> > getAnimationPlayers();

#if !ENABLE(OILPAN)
    void playerDestroyed(AnimationPlayer* player)
    {
        ASSERT(m_players.contains(player));
        m_players.remove(player);
    }
#endif

    bool hasPendingUpdates() const { return !m_playersNeedingUpdate.isEmpty(); }
    double zeroTime() const { return 0; }
    double currentTime(bool& isNull);
    double currentTime();
    double currentTimeInternal(bool& isNull);
    double currentTimeInternal();
    double effectiveTime();
    void pauseAnimationsForTesting(double);

    void setOutdatedAnimationPlayer(AnimationPlayer*);
    bool hasOutdatedAnimationPlayer() const;

    Document* document() { return m_document.get(); }
#if !ENABLE(OILPAN)
    void detachFromDocument();
#endif
    void wake();

    void trace(Visitor*);

protected:
    AnimationTimeline(Document*, PassOwnPtrWillBeRawPtr<PlatformTiming>);

private:
    RawPtrWillBeMember<Document> m_document;
    // AnimationPlayers which will be updated on the next frame
    // i.e. current, in effect, or had timing changed
    WillBeHeapHashSet<RefPtrWillBeMember<AnimationPlayer> > m_playersNeedingUpdate;
    WillBeHeapHashSet<RawPtrWillBeWeakMember<AnimationPlayer> > m_players;

    friend class SMILTimeContainer;
    static const double s_minimumDelay;

    OwnPtrWillBeMember<PlatformTiming> m_timing;

    class AnimationTimelineTiming FINAL : public PlatformTiming {
    public:
        AnimationTimelineTiming(AnimationTimeline* timeline)
            : m_timeline(timeline)
            , m_timer(this, &AnimationTimelineTiming::timerFired)
        {
            ASSERT(m_timeline);
        }

        virtual void wakeAfter(double duration) OVERRIDE;
        virtual void cancelWake() OVERRIDE;
        virtual void serviceOnNextFrame() OVERRIDE;

        void timerFired(Timer<AnimationTimelineTiming>*) { m_timeline->wake(); }

        virtual void trace(Visitor*) OVERRIDE;

    private:
        RawPtrWillBeMember<AnimationTimeline> m_timeline;
        Timer<AnimationTimelineTiming> m_timer;
    };

    friend class AnimationAnimationTimelineTest;
};

} // namespace blink

#endif
