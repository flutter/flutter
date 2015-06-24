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

#include "sky/engine/core/animation/AnimationPlayer.h"

#include "sky/engine/core/animation/Animation.h"
#include "sky/engine/core/animation/AnimationTimeline.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/events/AnimationPlayerEvent.h"

namespace blink {

namespace {

static unsigned nextSequenceNumber()
{
    static unsigned next = 0;
    return ++next;
}

}

PassRefPtr<AnimationPlayer> AnimationPlayer::create(ExecutionContext* executionContext, AnimationTimeline& timeline, AnimationNode* content)
{
    RefPtr<AnimationPlayer> player = adoptRef(new AnimationPlayer(executionContext, timeline, content));
    timeline.document()->pendingAnimations().add(player.get());
    player->suspendIfNeeded();
    return player.release();
}

AnimationPlayer::AnimationPlayer(ExecutionContext* executionContext, AnimationTimeline& timeline, AnimationNode* content)
    : ActiveDOMObject(executionContext)
    , m_playbackRate(1)
    , m_startTime(nullValue())
    , m_holdTime(0)
    , m_sequenceNumber(nextSequenceNumber())
    , m_content(content)
    , m_timeline(&timeline)
    , m_paused(false)
    , m_held(true)
    , m_isPausedForTesting(false)
    , m_outdated(true)
    , m_finished(false)
    , m_pending(true)
    , m_currentTimePending(false)
{
    if (m_content) {
        if (m_content->player())
            m_content->player()->cancel();
        m_content->attach(this);
    }
}

AnimationPlayer::~AnimationPlayer()
{
    if (m_content)
        m_content->detach();
    if (m_timeline)
        m_timeline->playerDestroyed(this);
}

double AnimationPlayer::sourceEnd() const
{
    return m_content ? m_content->endTimeInternal() : 0;
}

bool AnimationPlayer::limited(double currentTime) const
{
    return (m_playbackRate < 0 && currentTime <= 0) || (m_playbackRate > 0 && currentTime >= sourceEnd());
}

void AnimationPlayer::setCurrentTimeInternal(double newCurrentTime, TimingUpdateReason reason)
{
    ASSERT(std::isfinite(newCurrentTime));

    bool oldHeld = m_held;
    bool outdated = false;
    bool isLimited = limited(newCurrentTime);
    m_held = m_paused || !m_playbackRate || isLimited || std::isnan(m_startTime);
    if (m_held) {
        if (!oldHeld || m_holdTime != newCurrentTime)
            outdated = true;
        m_holdTime = newCurrentTime;
        if (m_paused || !m_playbackRate) {
            m_startTime = nullValue();
        } else if (isLimited && std::isnan(m_startTime) && reason == TimingUpdateForAnimationFrame) {
            m_startTime = calculateStartTime(newCurrentTime);
        }
    } else {
        m_holdTime = nullValue();
        m_startTime = calculateStartTime(newCurrentTime);
        m_finished = false;
        outdated = true;
    }

    if (outdated) {
        setOutdated();
    }
}

// Update timing to reflect updated animation clock due to tick
void AnimationPlayer::updateCurrentTimingState(TimingUpdateReason reason)
{
    if (m_held) {
        setCurrentTimeInternal(m_holdTime, reason);
        return;
    }
    if (!limited(calculateCurrentTime()))
        return;
    m_held = true;
    m_holdTime = m_playbackRate < 0 ? 0 : sourceEnd();
}

double AnimationPlayer::startTime() const
{
    return m_startTime * 1000;
}

double AnimationPlayer::currentTime()
{
    if (m_currentTimePending)
        return std::numeric_limits<double>::quiet_NaN();
    return currentTimeInternal() * 1000;
}

double AnimationPlayer::currentTimeInternal()
{
    updateCurrentTimingState(TimingUpdateOnDemand);
    if (m_held)
        return m_holdTime;
    return calculateCurrentTime();
}

void AnimationPlayer::preCommit()
{
    if (!playing()) {
        m_currentTimePending = false;
    }
}

void AnimationPlayer::postCommit(double timelineTime)
{
    m_pending = false;
}

void AnimationPlayer::notifyCompositorStartTime(double timelineTime)
{
    if (playing()) {
        ASSERT(std::isnan(m_startTime));
        ASSERT(m_held);

        if (m_playbackRate == 0) {
            setStartTimeInternal(timelineTime);
        } else {
            setStartTimeInternal(timelineTime + currentTimeInternal() / -m_playbackRate);
        }

        // FIXME: This avoids marking this player as outdated needlessly when a start time
        // is notified, but we should refactor how outdating works to avoid this.
        m_outdated = false;

        m_currentTimePending = false;
    }
}

double AnimationPlayer::calculateStartTime(double currentTime) const
{
    return m_timeline->effectiveTime() - currentTime / m_playbackRate;
}

double AnimationPlayer::calculateCurrentTime() const
{
    ASSERT(!m_held);
    if (isNull(m_startTime) || !m_timeline)
        return 0;
    return (m_timeline->effectiveTime() - m_startTime) * m_playbackRate;
}

void AnimationPlayer::setCurrentTime(double newCurrentTime)
{
    if (!std::isfinite(newCurrentTime))
        return;

    setPending();

    // Setting current time while pending forces a start time.
    if (m_currentTimePending) {
        m_startTime = 0;
        m_currentTimePending = false;
    }

    setCurrentTimeInternal(newCurrentTime / 1000, TimingUpdateOnDemand);
}

void AnimationPlayer::setStartTime(double startTime)
{
    if (m_paused) // FIXME: Should this throw an exception?
        return;
    if (!std::isfinite(startTime))
        return;
    if (startTime == m_startTime)
        return;

    setPending();
    m_currentTimePending = false;
    setStartTimeInternal(startTime / 1000);
}

void AnimationPlayer::setStartTimeInternal(double newStartTime)
{
    ASSERT(!m_paused);
    ASSERT(std::isfinite(newStartTime));
    ASSERT(newStartTime != m_startTime);

    bool hadStartTime = hasStartTime();
    double previousCurrentTime = currentTimeInternal();
    m_startTime = newStartTime;
    if (m_held && m_playbackRate) {
        // If held, the start time would still be derrived from the hold time.
        // Force a new, limited, current time.
        m_held = false;
        double currentTime = calculateCurrentTime();
        if (m_playbackRate > 0 && currentTime > sourceEnd()) {
            currentTime = sourceEnd();
        } else if (m_playbackRate < 0 && currentTime < 0) {
            currentTime = 0;
        }
        setCurrentTimeInternal(currentTime, TimingUpdateOnDemand);
    }
    double newCurrentTime = currentTimeInternal();

    if (previousCurrentTime != newCurrentTime) {
        setOutdated();
    } else if (!hadStartTime && m_timeline) {
        // Even though this player is not outdated, time to effect change is
        // infinity until start time is set.
        m_timeline->wake();
    }
}

void AnimationPlayer::setSource(AnimationNode* newSource)
{
    if (m_content == newSource)
        return;

    setPending();

    double storedCurrentTime = currentTimeInternal();
    if (m_content)
        m_content->detach();
    m_content = newSource;
    if (newSource) {
        // FIXME: This logic needs to be updated once groups are implemented
        if (newSource->player())
            newSource->player()->cancel();
        newSource->attach(this);
        setOutdated();
    }
    setCurrentTimeInternal(storedCurrentTime, TimingUpdateOnDemand);
}

String AnimationPlayer::playState()
{
    switch (playStateInternal()) {
    case Idle:
        return "idle";
    case Pending:
        return "pending";
    case Running:
        return "running";
    case Paused:
        return "paused";
    case Finished:
        return "finished";
    default:
        ASSERT_NOT_REACHED();
        return "";
    }
}

AnimationPlayer::AnimationPlayState AnimationPlayer::playStateInternal()
{
    // FIXME(shanestephens): Add clause for in-idle-state here.
    if (m_currentTimePending || (isNull(m_startTime) && !m_paused && m_playbackRate != 0))
        return Pending;
    // FIXME(shanestephens): Add idle handling here.
    if (m_paused)
        return Paused;
    if (finished())
        return Finished;
    return Running;
}

void AnimationPlayer::pause()
{
    if (m_paused)
        return;
    if (playing()) {
        setPending();
        m_currentTimePending = true;
    }
    m_paused = true;
    setCurrentTimeInternal(currentTimeInternal(), TimingUpdateOnDemand);
}

void AnimationPlayer::unpause()
{
    if (!m_paused)
        return;
    setPending();
    m_currentTimePending = true;
    unpauseInternal();
}

void AnimationPlayer::unpauseInternal()
{
    if (!m_paused)
        return;
    m_paused = false;
    setCurrentTimeInternal(currentTimeInternal(), TimingUpdateOnDemand);
}

void AnimationPlayer::play()
{
    if (!playing())
        m_startTime = nullValue();

    setPending();
    unpauseInternal();
    if (!m_content)
        return;
    double currentTime = this->currentTimeInternal();
    if (m_playbackRate > 0 && (currentTime < 0 || currentTime >= sourceEnd()))
        setCurrentTimeInternal(0, TimingUpdateOnDemand);
    else if (m_playbackRate < 0 && (currentTime <= 0 || currentTime > sourceEnd()))
        setCurrentTimeInternal(sourceEnd(), TimingUpdateOnDemand);
    m_finished = false;
}

void AnimationPlayer::reverse()
{
    if (!m_playbackRate) {
        return;
    }
    if (m_content) {
        if (m_playbackRate > 0 && currentTimeInternal() > sourceEnd()) {
            setCurrentTimeInternal(sourceEnd(), TimingUpdateOnDemand);
            ASSERT(finished());
        } else if (m_playbackRate < 0 && currentTimeInternal() < 0) {
            setCurrentTimeInternal(0, TimingUpdateOnDemand);
            ASSERT(finished());
        }
    }
    setPlaybackRate(-m_playbackRate);
    unpauseInternal();
}

void AnimationPlayer::finish(ExceptionState& exceptionState)
{
    if (!m_playbackRate) {
        return;
    }
    if (m_playbackRate > 0 && sourceEnd() == std::numeric_limits<double>::infinity()) {
        exceptionState.ThrowDOMException(InvalidStateError, "AnimationPlayer has source content whose end time is infinity.");
        return;
    }
    if (playing()) {
        setPending();
    }
    if (m_playbackRate < 0) {
        setCurrentTimeInternal(0, TimingUpdateOnDemand);
    } else {
        setCurrentTimeInternal(sourceEnd(), TimingUpdateOnDemand);
    }
    ASSERT(finished());
}

const AtomicString& AnimationPlayer::interfaceName() const
{
    return EventTargetNames::AnimationPlayer;
}

ExecutionContext* AnimationPlayer::executionContext() const
{
    return ActiveDOMObject::executionContext();
}

bool AnimationPlayer::hasPendingActivity() const
{
    return m_pendingFinishedEvent || (!m_finished && hasEventListeners(EventTypeNames::finish));
}

void AnimationPlayer::stop()
{
    m_finished = true;
    m_pendingFinishedEvent = nullptr;
}

bool AnimationPlayer::dispatchEvent(PassRefPtr<Event> event)
{
    if (m_pendingFinishedEvent == event)
        m_pendingFinishedEvent = nullptr;
    return EventTargetWithInlineData::dispatchEvent(event);
}

void AnimationPlayer::setPlaybackRate(double playbackRate)
{
    if (!std::isfinite(playbackRate))
        return;
    if (playbackRate == m_playbackRate)
        return;

    setPending();
    if (!finished() && !paused())
        m_currentTimePending = true;

    double storedCurrentTime = currentTimeInternal();
    if ((m_playbackRate < 0 && playbackRate >= 0) || (m_playbackRate > 0 && playbackRate <= 0))
        m_finished = false;

    m_playbackRate = playbackRate;
    m_startTime = std::numeric_limits<double>::quiet_NaN();
    setCurrentTimeInternal(storedCurrentTime, TimingUpdateOnDemand);
}

void AnimationPlayer::setOutdated()
{
    m_outdated = true;
    if (m_timeline)
        m_timeline->setOutdatedAnimationPlayer(this);
}

void AnimationPlayer::setPending()
{
    if (!m_pending) {
        m_pending = true;
        timeline()->document()->pendingAnimations().add(this);
    }
}

bool AnimationPlayer::update(TimingUpdateReason reason)
{
    if (!m_timeline)
        return false;

    updateCurrentTimingState(reason);
    m_outdated = false;

    if (m_content) {
        double inheritedTime = isNull(m_timeline->currentTimeInternal()) ? nullValue() : currentTimeInternal();
        m_content->updateInheritedTime(inheritedTime, reason);
    }

    if (finished() && !m_finished) {
        if (reason == TimingUpdateForAnimationFrame && hasStartTime()) {
            const AtomicString& eventType = EventTypeNames::finish;
            if (executionContext() && hasEventListeners(eventType)) {
                m_pendingFinishedEvent = AnimationPlayerEvent::create(eventType, currentTime(), timeline()->currentTime());
                m_pendingFinishedEvent->setTarget(this);
                m_pendingFinishedEvent->setCurrentTarget(this);
                m_timeline->document()->enqueueAnimationFrameEvent(m_pendingFinishedEvent);
            }
            m_finished = true;
        }
    }
    ASSERT(!m_outdated);
    return !m_finished || !finished();
}

double AnimationPlayer::timeToEffectChange()
{
    ASSERT(!m_outdated);
    if (m_held || !hasStartTime())
        return std::numeric_limits<double>::infinity();
    if (!m_content)
        return -currentTimeInternal() / m_playbackRate;
    if (m_playbackRate > 0)
        return m_content->timeToForwardsEffectChange() / m_playbackRate;
    return m_content->timeToReverseEffectChange() / -m_playbackRate;
}

void AnimationPlayer::cancel()
{
    setSource(0);
}

bool AnimationPlayer::canFree() const
{
    ASSERT(m_content);
    return hasOneRef() && m_content->isAnimation() && m_content->hasOneRef();
}

bool AnimationPlayer::addEventListener(const AtomicString& eventType, PassRefPtr<EventListener> listener, bool useCapture)
{
    return EventTargetWithInlineData::addEventListener(eventType, listener, useCapture);
}

void AnimationPlayer::pauseForTesting(double pauseTime)
{
    RELEASE_ASSERT(!paused());
    setCurrentTimeInternal(pauseTime, TimingUpdateOnDemand);
    m_isPausedForTesting = true;
    pause();
}

} // namespace
