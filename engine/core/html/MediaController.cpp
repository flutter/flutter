/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

#include "config.h"
#include "core/html/MediaController.h"

#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/dom/ExceptionCode.h"
#include "core/dom/ExecutionContext.h"
#include "core/events/Event.h"
#include "core/events/GenericEventQueue.h"
#include "core/html/HTMLMediaElement.h"
#include "core/html/TimeRanges.h"
#include "platform/Clock.h"
#include "wtf/CurrentTime.h"
#include "wtf/StdLibExtras.h"
#include "wtf/text/AtomicString.h"

namespace blink {

PassRefPtrWillBeRawPtr<MediaController> MediaController::create(ExecutionContext* context)
{
    return adoptRefWillBeNoop(new MediaController(context));
}

MediaController::MediaController(ExecutionContext* context)
    : m_paused(false)
    , m_defaultPlaybackRate(1)
    , m_volume(1)
    , m_position(MediaPlayer::invalidTime())
    , m_muted(false)
    , m_readyState(HTMLMediaElement::HAVE_NOTHING)
    , m_playbackState(WAITING)
    , m_pendingEventsQueue(GenericEventQueue::create(this))
    , m_clearPositionTimer(this, &MediaController::clearPositionTimerFired)
    , m_clock(Clock::create())
    , m_executionContext(context)
    , m_timeupdateTimer(this, &MediaController::timeupdateTimerFired)
    , m_previousTimeupdateTime(0)
{
    ScriptWrappable::init(this);
}

MediaController::~MediaController()
{
}

void MediaController::addMediaElement(HTMLMediaElement* element)
{
    ASSERT(element);
    ASSERT(!m_mediaElements.contains(element));

    m_mediaElements.add(element);
    bringElementUpToSpeed(element);
}

void MediaController::removeMediaElement(HTMLMediaElement* element)
{
    ASSERT(element);
    ASSERT(m_mediaElements.contains(element));
    m_mediaElements.remove(m_mediaElements.find(element));
}

PassRefPtrWillBeRawPtr<TimeRanges> MediaController::buffered() const
{
    if (m_mediaElements.isEmpty())
        return TimeRanges::create();

    // The buffered attribute must return a new static normalized TimeRanges object that represents
    // the intersection of the ranges of the media resources of the slaved media elements that the
    // user agent has buffered, at the time the attribute is evaluated.
    MediaElementSequence::const_iterator it = m_mediaElements.begin();
    RefPtrWillBeRawPtr<TimeRanges> bufferedRanges = (*it)->buffered();
    for (++it; it != m_mediaElements.end(); ++it)
        bufferedRanges->intersectWith((*it)->buffered().get());
    return bufferedRanges;
}

PassRefPtrWillBeRawPtr<TimeRanges> MediaController::seekable() const
{
    if (m_mediaElements.isEmpty())
        return TimeRanges::create();

    // The seekable attribute must return a new static normalized TimeRanges object that represents
    // the intersection of the ranges of the media resources of the slaved media elements that the
    // user agent is able to seek to, at the time the attribute is evaluated.
    MediaElementSequence::const_iterator it = m_mediaElements.begin();
    RefPtrWillBeRawPtr<TimeRanges> seekableRanges = (*it)->seekable();
    for (++it; it != m_mediaElements.end(); ++it)
        seekableRanges->intersectWith((*it)->seekable().get());
    return seekableRanges;
}

PassRefPtrWillBeRawPtr<TimeRanges> MediaController::played()
{
    if (m_mediaElements.isEmpty())
        return TimeRanges::create();

    // The played attribute must return a new static normalized TimeRanges object that represents
    // the union of the ranges of the media resources of the slaved media elements that the
    // user agent has so far rendered, at the time the attribute is evaluated.
    MediaElementSequence::const_iterator it = m_mediaElements.begin();
    RefPtrWillBeRawPtr<TimeRanges> playedRanges = (*it)->played();
    for (++it; it != m_mediaElements.end(); ++it)
        playedRanges->unionWith((*it)->played().get());
    return playedRanges;
}

double MediaController::duration() const
{
    // FIXME: Investigate caching the maximum duration and only updating the cached value
    // when the slaved media elements' durations change.
    double maxDuration = 0;
    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it) {
        double duration = (*it)->duration();
        if (std::isnan(duration))
            continue;
        maxDuration = std::max(maxDuration, duration);
    }
    return maxDuration;
}

double MediaController::currentTime() const
{
    if (m_mediaElements.isEmpty())
        return 0;

    if (m_position == MediaPlayer::invalidTime()) {
        // Some clocks may return times outside the range of [0..duration].
        m_position = std::max(0.0, std::min(duration(), m_clock->currentTime()));
        m_clearPositionTimer.startOneShot(0, FROM_HERE);
    }

    return m_position;
}

void MediaController::setCurrentTime(double time, ExceptionState& exceptionState)
{
    // When the user agent is to seek the media controller to a particular new playback position,
    // it must follow these steps:
    // If the new playback position is less than zero, then set it to zero.
    time = std::max(0.0, time);

    // If the new playback position is greater than the media controller duration, then set it
    // to the media controller duration.
    time = std::min(time, duration());

    // Set the media controller position to the new playback position.
    m_position = time;
    m_clock->setCurrentTime(time);

    // Seek each slaved media element to the new playback position relative to the media element timeline.
    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it)
        (*it)->seek(time, exceptionState);

    scheduleTimeupdateEvent();
}

void MediaController::unpause()
{
    // When the unpause() method is invoked, if the MediaController is a paused media controller,
    if (!m_paused)
        return;

    // the user agent must change the MediaController into a playing media controller,
    m_paused = false;
    // queue a task to fire a simple event named play at the MediaController,
    scheduleEvent(EventTypeNames::play);
    // and then report the controller state of the MediaController.
    reportControllerState();
}

void MediaController::play()
{
    // When the play() method is invoked, the user agent must invoke the play method of each
    // slaved media element in turn,
    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it)
        (*it)->play();

    // and then invoke the unpause method of the MediaController.
    unpause();
}

void MediaController::pause()
{
    // When the pause() method is invoked, if the MediaController is a playing media controller,
    if (m_paused)
        return;

    // then the user agent must change the MediaController into a paused media controller,
    m_paused = true;
    // queue a task to fire a simple event named pause at the MediaController,
    scheduleEvent(EventTypeNames::pause);
    // and then report the controller state of the MediaController.
    reportControllerState();
}

void MediaController::setDefaultPlaybackRate(double rate)
{
    if (m_defaultPlaybackRate == rate)
        return;

    // The defaultPlaybackRate attribute, on setting, must set the MediaController's media controller
    // default playback rate to the new value,
    m_defaultPlaybackRate = rate;

    // then queue a task to fire a simple event named ratechange at the MediaController.
    scheduleEvent(EventTypeNames::ratechange);
}

double MediaController::playbackRate() const
{
    return m_clock->playRate();
}

void MediaController::setPlaybackRate(double rate)
{
    if (m_clock->playRate() == rate)
        return;

    // The playbackRate attribute, on setting, must set the MediaController's media controller
    // playback rate to the new value,
    m_clock->setPlayRate(rate);

    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it)
        (*it)->updatePlaybackRate();

    // then queue a task to fire a simple event named ratechange at the MediaController.
    scheduleEvent(EventTypeNames::ratechange);
}

void MediaController::setVolume(double level, ExceptionState& exceptionState)
{
    if (m_volume == level)
        return;

    // If the new value is outside the range 0.0 to 1.0 inclusive, then, on setting, an
    // IndexSizeError exception must be raised instead.
    if (level < 0 || level > 1) {
        exceptionState.throwDOMException(IndexSizeError, ExceptionMessages::indexOutsideRange("volume", level, 0.0, ExceptionMessages::InclusiveBound, 1.0, ExceptionMessages::InclusiveBound));
        return;
    }

    // The volume attribute, on setting, if the new value is in the range 0.0 to 1.0 inclusive,
    // must set the MediaController's media controller volume multiplier to the new value
    m_volume = level;

    // and queue a task to fire a simple event named volumechange at the MediaController.
    scheduleEvent(EventTypeNames::volumechange);

    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it)
        (*it)->updateVolume();
}

void MediaController::setMuted(bool flag)
{
    if (m_muted == flag)
        return;

    // The muted attribute, on setting, must set the MediaController's media controller mute override
    // to the new value
    m_muted = flag;

    // and queue a task to fire a simple event named volumechange at the MediaController.
    scheduleEvent(EventTypeNames::volumechange);

    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it)
        (*it)->updateVolume();
}

static const AtomicString& playbackStateWaiting()
{
    DEFINE_STATIC_LOCAL(AtomicString, waiting, ("waiting", AtomicString::ConstructFromLiteral));
    return waiting;
}

static const AtomicString& playbackStatePlaying()
{
    DEFINE_STATIC_LOCAL(AtomicString, playing, ("playing", AtomicString::ConstructFromLiteral));
    return playing;
}

static const AtomicString& playbackStateEnded()
{
    DEFINE_STATIC_LOCAL(AtomicString, ended, ("ended", AtomicString::ConstructFromLiteral));
    return ended;
}

const AtomicString& MediaController::playbackState() const
{
    switch (m_playbackState) {
    case WAITING:
        return playbackStateWaiting();
    case PLAYING:
        return playbackStatePlaying();
    case ENDED:
        return playbackStateEnded();
    default:
        ASSERT_NOT_REACHED();
        return nullAtom;
    }
}

void MediaController::reportControllerState()
{
    updateReadyState();
    updatePlaybackState();
}

static const AtomicString& eventNameForReadyState(HTMLMediaElement::ReadyState state)
{
    switch (state) {
    case HTMLMediaElement::HAVE_NOTHING:
        return EventTypeNames::emptied;
    case HTMLMediaElement::HAVE_METADATA:
        return EventTypeNames::loadedmetadata;
    case HTMLMediaElement::HAVE_CURRENT_DATA:
        return EventTypeNames::loadeddata;
    case HTMLMediaElement::HAVE_FUTURE_DATA:
        return EventTypeNames::canplay;
    case HTMLMediaElement::HAVE_ENOUGH_DATA:
        return EventTypeNames::canplaythrough;
    default:
        ASSERT_NOT_REACHED();
        return nullAtom;
    }
}

void MediaController::updateReadyState()
{
    ReadyState oldReadyState = m_readyState;
    ReadyState newReadyState;

    if (m_mediaElements.isEmpty()) {
        // If the MediaController has no slaved media elements, let new readiness state be 0.
        newReadyState = HTMLMediaElement::HAVE_NOTHING;
    } else {
        // Otherwise, let it have the lowest value of the readyState IDL attributes of all of its
        // slaved media elements.
        MediaElementSequence::const_iterator it = m_mediaElements.begin();
        newReadyState = (*it)->readyState();
        for (++it; it != m_mediaElements.end(); ++it)
            newReadyState = std::min(newReadyState, (*it)->readyState());
    }

    if (newReadyState == oldReadyState)
        return;

    // If the MediaController's most recently reported readiness state is greater than new readiness
    // state then queue a task to fire a simple event at the MediaController object, whose name is the
    // event name corresponding to the value of new readiness state given in the table below. [omitted]
    if (oldReadyState > newReadyState) {
        scheduleEvent(eventNameForReadyState(newReadyState));
        return;
    }

    // If the MediaController's most recently reported readiness state is less than the new readiness
    // state, then run these substeps:
    // 1. Let next state be the MediaController's most recently reported readiness state.
    ReadyState nextState = oldReadyState;
    do {
        // 2. Loop: Increment next state by one.
        nextState = static_cast<ReadyState>(nextState + 1);
        // 3. Queue a task to fire a simple event at the MediaController object, whose name is the
        // event name corresponding to the value of next state given in the table below. [omitted]
        scheduleEvent(eventNameForReadyState(nextState));
        // If next state is less than new readiness state, then return to the step labeled loop
    } while (nextState < newReadyState);

    // Let the MediaController's most recently reported readiness state be new readiness state.
    m_readyState = newReadyState;
}

void MediaController::updatePlaybackState()
{
    PlaybackState oldPlaybackState = m_playbackState;
    PlaybackState newPlaybackState;

    // Initialize new playback state by setting it to the state given for the first matching
    // condition from the following list:
    if (m_mediaElements.isEmpty()) {
        // If the MediaController has no slaved media elements
        // Let new playback state be waiting.
        newPlaybackState = WAITING;
    } else if (hasEnded()) {
        // If all of the MediaController's slaved media elements have ended playback and the media
        // controller playback rate is positive or zero
        // Let new playback state be ended.
        newPlaybackState = ENDED;
    } else if (isBlocked()) {
        // If the MediaController is a blocked media controller
        // Let new playback state be waiting.
        newPlaybackState = WAITING;
    } else {
        // Otherwise
        // Let new playback state be playing.
        newPlaybackState = PLAYING;
    }

    // If the MediaController's most recently reported playback state is not equal to new playback state
    if (newPlaybackState == oldPlaybackState)
        return;

    // and the new playback state is ended,
    if (newPlaybackState == ENDED) {
        // then queue a task that, if the MediaController object is a playing media controller, and
        // all of the MediaController's slaved media elements have still ended playback, and the
        // media controller playback rate is still positive or zero,
        if (!m_paused && hasEnded()) {
            // changes the MediaController object to a paused media controller
            m_paused = true;

            // and then fires a simple event named pause at the MediaController object.
            scheduleEvent(EventTypeNames::pause);
        }
    }

    // If the MediaController's most recently reported playback state is not equal to new playback state
    // then queue a task to fire a simple event at the MediaController object, whose name is playing
    // if new playback state is playing, ended if new playback state is ended, and waiting otherwise.
    AtomicString eventName;
    switch (newPlaybackState) {
    case WAITING:
        eventName = EventTypeNames::waiting;
        m_clock->stop();
        m_timeupdateTimer.stop();
        break;
    case ENDED:
        eventName = EventTypeNames::ended;
        m_clock->stop();
        m_timeupdateTimer.stop();
        break;
    case PLAYING:
        eventName = EventTypeNames::playing;
        m_clock->start();
        startTimeupdateTimer();
        break;
    default:
        ASSERT_NOT_REACHED();
    }
    scheduleEvent(eventName);

    // Let the MediaController's most recently reported playback state be new playback state.
    m_playbackState = newPlaybackState;

    updateMediaElements();
}

void MediaController::updateMediaElements()
{
    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it)
        (*it)->updatePlayState();
}

void MediaController::bringElementUpToSpeed(HTMLMediaElement* element)
{
    ASSERT(element);
    ASSERT(m_mediaElements.contains(element));

    // When the user agent is to bring a media element up to speed with its new media controller,
    // it must seek that media element to the MediaController's media controller position relative
    // to the media element's timeline.
    element->seek(currentTime(), IGNORE_EXCEPTION);

    // Update volume to take controller volume and mute into account.
    element->updateVolume();
}

bool MediaController::isRestrained() const
{
    ASSERT(!m_mediaElements.isEmpty());

    // A MediaController is a restrained media controller if the MediaController is a playing media
    // controller,
    if (m_paused)
        return false;

    bool anyAutoplayingAndPaused = false;
    bool allPaused = true;
    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it) {
        HTMLMediaElement* element = *it;

        // and none of its slaved media elements are blocked media elements,
        if (element->isBlocked())
            return false;

        if (element->isAutoplaying() && element->paused())
            anyAutoplayingAndPaused = true;

        if (!element->paused())
            allPaused = false;
    }

    // but either at least one of its slaved media elements whose autoplaying flag is true still has
    // its paused attribute set to true, or, all of its slaved media elements have their paused
    // attribute set to true.
    return anyAutoplayingAndPaused || allPaused;
}

bool MediaController::isBlocked() const
{
    ASSERT(!m_mediaElements.isEmpty());

    // A MediaController is a blocked media controller if the MediaController is a paused media
    // controller,
    if (m_paused)
        return true;

    bool allPaused = true;
    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it) {
        HTMLMediaElement* element = *it;

        // or if any of its slaved media elements are blocked media elements,
        if (element->isBlocked())
            return true;

        // or if any of its slaved media elements whose autoplaying flag is true still have their
        // paused attribute set to true,
        if (element->isAutoplaying() && element->paused())
            return true;

        if (!element->paused())
            allPaused = false;
    }

    // or if all of its slaved media elements have their paused attribute set to true.
    return allPaused;
}

bool MediaController::hasEnded() const
{
    // If the ... media controller playback rate is positive or zero
    if (m_clock->playRate() < 0)
        return false;

    // [and] all of the MediaController's slaved media elements have ended playback ... let new
    // playback state be ended.
    if (m_mediaElements.isEmpty())
        return false;

    bool allHaveEnded = true;
    for (MediaElementSequence::const_iterator it = m_mediaElements.begin(); it != m_mediaElements.end(); ++it) {
        if (!(*it)->ended())
            allHaveEnded = false;
    }
    return allHaveEnded;
}

void MediaController::scheduleEvent(const AtomicString& eventName)
{
    m_pendingEventsQueue->enqueueEvent(Event::createCancelable(eventName));
}

void MediaController::clearPositionTimerFired(Timer<MediaController>*)
{
    m_position = MediaPlayer::invalidTime();
}

const AtomicString& MediaController::interfaceName() const
{
    return EventTargetNames::MediaController;
}

// The spec says to fire periodic timeupdate events (those sent while playing) every
// "15 to 250ms", we choose the slowest frequency
static const double maxTimeupdateEventFrequency = 0.25;

void MediaController::startTimeupdateTimer()
{
    if (m_timeupdateTimer.isActive())
        return;

    m_timeupdateTimer.startRepeating(maxTimeupdateEventFrequency, FROM_HERE);
}

void MediaController::timeupdateTimerFired(Timer<MediaController>*)
{
    scheduleTimeupdateEvent();
}

void MediaController::scheduleTimeupdateEvent()
{
    double now = WTF::currentTime();
    double timedelta = now - m_previousTimeupdateTime;

    if (timedelta < maxTimeupdateEventFrequency)
        return;

    scheduleEvent(EventTypeNames::timeupdate);
    m_previousTimeupdateTime = now;
}

void MediaController::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_mediaElements);
    visitor->trace(m_pendingEventsQueue);
    visitor->trace(m_executionContext);
#endif
    EventTargetWithInlineData::trace(visitor);
}

}
