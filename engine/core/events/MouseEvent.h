/*
 * Copyright (C) 2001 Peter Kelly (pmk@post.com)
 * Copyright (C) 2001 Tobias Anton (anton@stud.fbi.fh-darmstadt.de)
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2008 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef MouseEvent_h
#define MouseEvent_h

#include "core/events/EventDispatchMediator.h"
#include "core/events/MouseRelatedEvent.h"
#include "platform/PlatformMouseEvent.h"

namespace blink {

class EventDispatcher;

struct MouseEventInit : public UIEventInit {
    MouseEventInit();

    int screenX;
    int screenY;
    int clientX;
    int clientY;
    bool ctrlKey;
    bool altKey;
    bool shiftKey;
    bool metaKey;
    unsigned short button;
    RefPtrWillBeMember<EventTarget> relatedTarget;
};

class MouseEvent : public MouseRelatedEvent {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<MouseEvent> create()
    {
        return adoptRefWillBeNoop(new MouseEvent);
    }

    static PassRefPtrWillBeRawPtr<MouseEvent> create(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtrWillBeRawPtr<AbstractView>,
        int detail, int screenX, int screenY, int pageX, int pageY,
        int movementX, int movementY,
        bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, unsigned short button,
        PassRefPtrWillBeRawPtr<EventTarget> relatedTarget,
        bool isSimulated = false, PlatformMouseEvent::SyntheticEventType = PlatformMouseEvent::RealOrIndistinguishable);

    static PassRefPtrWillBeRawPtr<MouseEvent> create(const AtomicString& eventType, PassRefPtrWillBeRawPtr<AbstractView>, const PlatformMouseEvent&, int detail, PassRefPtrWillBeRawPtr<Node> relatedTarget);

    static PassRefPtrWillBeRawPtr<MouseEvent> create(const AtomicString& eventType, const MouseEventInit&);

    virtual ~MouseEvent();

    void initMouseEvent(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtrWillBeRawPtr<AbstractView>,
        int detail, int screenX, int screenY, int clientX, int clientY,
        bool ctrlKey, bool altKey, bool shiftKey, bool metaKey,
        unsigned short button, PassRefPtrWillBeRawPtr<EventTarget> relatedTarget);

    // WinIE uses 1,4,2 for left/middle/right but not for click (just for mousedown/up, maybe others),
    // but we will match the standard DOM.
    unsigned short button() const { return m_button; }
    bool buttonDown() const { return m_buttonDown; }
    EventTarget* relatedTarget() const { return m_relatedTarget.get(); }
    void setRelatedTarget(PassRefPtrWillBeRawPtr<EventTarget> relatedTarget) { m_relatedTarget = relatedTarget; }

    Node* toElement() const;
    Node* fromElement() const;

    bool fromTouch() const { return m_syntheticEventType == PlatformMouseEvent::FromTouch; }

    virtual const AtomicString& interfaceName() const OVERRIDE;

    virtual bool isMouseEvent() const OVERRIDE;
    virtual bool isDragEvent() const OVERRIDE FINAL;
    virtual int which() const OVERRIDE FINAL;

    virtual void trace(Visitor*) OVERRIDE;

protected:
    MouseEvent(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtrWillBeRawPtr<AbstractView>,
        int detail, int screenX, int screenY, int pageX, int pageY,
        int movementX, int movementY,
        bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, unsigned short button,
        PassRefPtrWillBeRawPtr<EventTarget> relatedTarget,
        bool isSimulated, PlatformMouseEvent::SyntheticEventType);

    MouseEvent(const AtomicString& type, const MouseEventInit&);

    MouseEvent();

private:
    unsigned short m_button;
    bool m_buttonDown;
    RefPtrWillBeMember<EventTarget> m_relatedTarget;
    PlatformMouseEvent::SyntheticEventType m_syntheticEventType;
};

class SimulatedMouseEvent FINAL : public MouseEvent {
public:
    static PassRefPtrWillBeRawPtr<SimulatedMouseEvent> create(const AtomicString& eventType, PassRefPtrWillBeRawPtr<AbstractView>, PassRefPtrWillBeRawPtr<Event> underlyingEvent);
    virtual ~SimulatedMouseEvent();

    virtual void trace(Visitor*) OVERRIDE;

private:
    SimulatedMouseEvent(const AtomicString& eventType, PassRefPtrWillBeRawPtr<AbstractView>, PassRefPtrWillBeRawPtr<Event> underlyingEvent);
};

class MouseEventDispatchMediator FINAL : public EventDispatchMediator {
public:
    enum MouseEventType { SyntheticMouseEvent, NonSyntheticMouseEvent};
    static PassRefPtrWillBeRawPtr<MouseEventDispatchMediator> create(PassRefPtrWillBeRawPtr<MouseEvent>, MouseEventType = NonSyntheticMouseEvent);

private:
    explicit MouseEventDispatchMediator(PassRefPtrWillBeRawPtr<MouseEvent>, MouseEventType);
    MouseEvent* event() const;

    virtual bool dispatchEvent(EventDispatcher*) const OVERRIDE;
    bool isSyntheticMouseEvent() const { return m_mouseEventType == SyntheticMouseEvent; }
    MouseEventType m_mouseEventType;
};

DEFINE_EVENT_TYPE_CASTS(MouseEvent);

} // namespace blink

#endif // MouseEvent_h
