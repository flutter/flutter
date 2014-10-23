/*
 * Copyright (C) 2011 Apple Inc.  All rights reserved.
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

#ifndef MediaController_h
#define MediaController_h

#include "core/events/EventTarget.h"
#include "core/html/HTMLMediaElement.h"
#include "wtf/LinkedHashSet.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class Clock;
class ExceptionState;
class ExecutionContext;
class GenericEventQueue;

class MediaController FINAL : public RefCountedWillBeGarbageCollectedFinalized<MediaController>, public EventTargetWithInlineData {
    DEFINE_WRAPPERTYPEINFO();
    REFCOUNTED_EVENT_TARGET(MediaController);
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(MediaController);
public:
    static PassRefPtrWillBeRawPtr<MediaController> create(ExecutionContext*);
    virtual ~MediaController();

    void addMediaElement(HTMLMediaElement*);
    void removeMediaElement(HTMLMediaElement*);

    PassRefPtrWillBeRawPtr<TimeRanges> buffered() const;
    PassRefPtrWillBeRawPtr<TimeRanges> seekable() const;
    PassRefPtrWillBeRawPtr<TimeRanges> played();

    double duration() const;
    double currentTime() const;
    void setCurrentTime(double, ExceptionState&);

    bool paused() const { return m_paused; }
    void play();
    void pause();
    void unpause();

    double defaultPlaybackRate() const { return m_defaultPlaybackRate; }
    void setDefaultPlaybackRate(double);

    double playbackRate() const;
    void setPlaybackRate(double);

    double volume() const { return m_volume; }
    void setVolume(double, ExceptionState&);

    bool muted() const { return m_muted; }
    void setMuted(bool);

    typedef HTMLMediaElement::ReadyState ReadyState;
    ReadyState readyState() const { return m_readyState; }

    enum PlaybackState { WAITING, PLAYING, ENDED };
    const AtomicString& playbackState() const;

    bool isRestrained() const;
    bool isBlocked() const;

#if !ENABLE(OILPAN)
    void clearExecutionContext() { m_executionContext = nullptr; }
#endif

    virtual void trace(Visitor*) OVERRIDE;

private:
    MediaController(ExecutionContext*);
    void reportControllerState();
    void updateReadyState();
    void updatePlaybackState();
    void updateMediaElements();
    void bringElementUpToSpeed(HTMLMediaElement*);
    void scheduleEvent(const AtomicString& eventName);
    void clearPositionTimerFired(Timer<MediaController>*);
    bool hasEnded() const;
    void scheduleTimeupdateEvent();
    void timeupdateTimerFired(Timer<MediaController>*);
    void startTimeupdateTimer();

    // EventTarget
    virtual const AtomicString& interfaceName() const OVERRIDE;
    virtual ExecutionContext* executionContext() const OVERRIDE { return m_executionContext; }

    friend class HTMLMediaElement;
    friend class MediaControllerEventListener;
    // FIXME: A MediaController should ideally keep an otherwise
    // unreferenced slaved media element alive. When Oilpan is
    // enabled by default, consider making the hash set references
    // strong to accomplish that. crbug.com/383072
    typedef WillBeHeapLinkedHashSet<RawPtrWillBeWeakMember<HTMLMediaElement> > MediaElementSequence;
    MediaElementSequence m_mediaElements;
    bool m_paused;
    double m_defaultPlaybackRate;
    double m_volume;
    mutable double m_position;
    bool m_muted;
    ReadyState m_readyState;
    PlaybackState m_playbackState;
    OwnPtrWillBeMember<GenericEventQueue> m_pendingEventsQueue;
    mutable Timer<MediaController> m_clearPositionTimer;
    OwnPtr<Clock> m_clock;
    RawPtrWillBeWeakMember<ExecutionContext> m_executionContext;
    Timer<MediaController> m_timeupdateTimer;
    double m_previousTimeupdateTime;
};

} // namespace blink

#endif // MediaController_h
