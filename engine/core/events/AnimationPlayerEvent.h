// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_EVENTS_ANIMATIONPLAYEREVENT_H_
#define SKY_ENGINE_CORE_EVENTS_ANIMATIONPLAYEREVENT_H_

#include "sky/engine/core/events/Event.h"

namespace blink {

struct AnimationPlayerEventInit : public EventInit {
    AnimationPlayerEventInit();

    double currentTime;
    double timelineTime;
};

class AnimationPlayerEvent final : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<AnimationPlayerEvent> create()
    {
        return adoptRef(new AnimationPlayerEvent);
    }
    static PassRefPtr<AnimationPlayerEvent> create(const AtomicString& type, double currentTime, double timelineTime)
    {
        return adoptRef(new AnimationPlayerEvent(type, currentTime, timelineTime));
    }
    static PassRefPtr<AnimationPlayerEvent> create(const AtomicString& type, const AnimationPlayerEventInit& initializer)
    {
        return adoptRef(new AnimationPlayerEvent(type, initializer));
    }

    virtual ~AnimationPlayerEvent();

    double currentTime() const;
    double timelineTime() const;

    virtual const AtomicString& interfaceName() const override;

private:
    AnimationPlayerEvent();
    AnimationPlayerEvent(const AtomicString& type, double currentTime, double timelineTime);
    AnimationPlayerEvent(const AtomicString&, const AnimationPlayerEventInit&);

    double m_currentTime;
    double m_timelineTime;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_ANIMATIONPLAYEREVENT_H_
