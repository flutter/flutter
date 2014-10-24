// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef AnimationPlayerEvent_h
#define AnimationPlayerEvent_h

#include "core/events/Event.h"

namespace blink {

struct AnimationPlayerEventInit : public EventInit {
    AnimationPlayerEventInit();

    double currentTime;
    double timelineTime;
};

class AnimationPlayerEvent final : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<AnimationPlayerEvent> create()
    {
        return adoptRefWillBeNoop(new AnimationPlayerEvent);
    }
    static PassRefPtrWillBeRawPtr<AnimationPlayerEvent> create(const AtomicString& type, double currentTime, double timelineTime)
    {
        return adoptRefWillBeNoop(new AnimationPlayerEvent(type, currentTime, timelineTime));
    }
    static PassRefPtrWillBeRawPtr<AnimationPlayerEvent> create(const AtomicString& type, const AnimationPlayerEventInit& initializer)
    {
        return adoptRefWillBeNoop(new AnimationPlayerEvent(type, initializer));
    }

    virtual ~AnimationPlayerEvent();

    double currentTime() const;
    double timelineTime() const;

    virtual const AtomicString& interfaceName() const override;

    virtual void trace(Visitor*) override;

private:
    AnimationPlayerEvent();
    AnimationPlayerEvent(const AtomicString& type, double currentTime, double timelineTime);
    AnimationPlayerEvent(const AtomicString&, const AnimationPlayerEventInit&);

    double m_currentTime;
    double m_timelineTime;
};

} // namespace blink

#endif // AnimationPlayerEvent_h
