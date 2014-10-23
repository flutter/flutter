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

#ifndef AnimationNode_h
#define AnimationNode_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/animation/Timing.h"
#include "platform/heap/Handle.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class AnimationPlayer;
class AnimationNode;
class AnimationNodeTiming;

enum TimingUpdateReason {
    TimingUpdateOnDemand,
    TimingUpdateForAnimationFrame
};

static inline bool isNull(double value)
{
    return std::isnan(value);
}

static inline double nullValue()
{
    return std::numeric_limits<double>::quiet_NaN();
}

class AnimationNode : public RefCountedWillBeGarbageCollectedFinalized<AnimationNode>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
    friend class AnimationPlayer; // Calls attach/detach, updateInheritedTime.
public:
    // Note that logic in CSSAnimations depends on the order of these values.
    enum Phase {
        PhaseBefore,
        PhaseActive,
        PhaseAfter,
        PhaseNone,
    };

    class EventDelegate : public NoBaseWillBeGarbageCollectedFinalized<EventDelegate> {
    public:
        virtual ~EventDelegate() { }
        virtual void onEventCondition(const AnimationNode*) = 0;
        virtual void trace(Visitor*) { }
    };

    virtual ~AnimationNode() { }

    virtual bool isAnimation() const { return false; }

    Phase phase() const { return ensureCalculated().phase; }
    bool isCurrent() const { return ensureCalculated().isCurrent; }
    bool isInEffect() const { return ensureCalculated().isInEffect; }
    bool isInPlay() const { return ensureCalculated().isInPlay; }
    double timeToForwardsEffectChange() const { return ensureCalculated().timeToForwardsEffectChange; }
    double timeToReverseEffectChange() const { return ensureCalculated().timeToReverseEffectChange; }

    double currentIteration() const { return ensureCalculated().currentIteration; }
    double iterationDuration() const;

    // This method returns time in ms as it is unused except via the API.
    double duration() const { return iterationDuration() * 1000; }

    double activeDuration() const { return activeDurationInternal() * 1000; }
    double activeDurationInternal() const;
    double timeFraction() const { return ensureCalculated().timeFraction; }
    double startTime() const { return m_startTime * 1000; }
    double startTimeInternal() const { return m_startTime; }
    double endTime() const { return endTimeInternal() * 1000; }
    double endTimeInternal() const { return startTime() + specifiedTiming().startDelay + activeDurationInternal() + specifiedTiming().endDelay; }

    const AnimationPlayer* player() const { return m_player; }
    AnimationPlayer* player() { return m_player; }
    const Timing& specifiedTiming() const { return m_timing; }
    PassRefPtrWillBeRawPtr<AnimationNodeTiming> timing();
    void updateSpecifiedTiming(const Timing&);

    // This method returns time in ms as it is unused except via the API.
    double localTime(bool& isNull) const { isNull = !m_player; return ensureCalculated().localTime * 1000; }
    double currentIteration(bool& isNull) const { isNull = !ensureCalculated().isInEffect; return ensureCalculated().currentIteration; }

    virtual void trace(Visitor*);

protected:
    explicit AnimationNode(const Timing&, PassOwnPtrWillBeRawPtr<EventDelegate> = nullptr);

    // When AnimationNode receives a new inherited time via updateInheritedTime
    // it will (if necessary) recalculate timings and (if necessary) call
    // updateChildrenAndEffects.
    void updateInheritedTime(double inheritedTime, TimingUpdateReason) const;
    void invalidate() const { m_needsUpdate = true; };
    bool hasEvents() const { return m_eventDelegate; }
    void clearEventDelegate() { m_eventDelegate = nullptr; }

    virtual void attach(AnimationPlayer* player)
    {
        m_player = player;
    }

    virtual void detach()
    {
        ASSERT(m_player);
        m_player = nullptr;
    }

    double repeatedDuration() const;

    virtual void updateChildrenAndEffects() const = 0;
    virtual double intrinsicIterationDuration() const { return 0; };
    virtual double calculateTimeToEffectChange(bool forwards, double localTime, double timeToNextIteration) const = 0;
    virtual void specifiedTimingChanged() { }

    // FIXME: m_parent and m_startTime are placeholders, they depend on timing groups.
    RawPtrWillBeMember<AnimationNode> m_parent;
    const double m_startTime;
    RawPtrWillBeMember<AnimationPlayer> m_player;
    Timing m_timing;
    OwnPtrWillBeMember<EventDelegate> m_eventDelegate;

    mutable struct CalculatedTiming {
        Phase phase;
        double currentIteration;
        double timeFraction;
        bool isCurrent;
        bool isInEffect;
        bool isInPlay;
        double localTime;
        double timeToForwardsEffectChange;
        double timeToReverseEffectChange;
    } m_calculated;
    mutable bool m_needsUpdate;
    mutable double m_lastUpdateTime;

    const CalculatedTiming& ensureCalculated() const;
};

} // namespace blink

#endif
