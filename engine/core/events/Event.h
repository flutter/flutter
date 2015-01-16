/*
 * Copyright (C) 2001 Peter Kelly (pmk@post.com)
 * Copyright (C) 2001 Tobias Anton (anton@stud.fbi.fh-darmstadt.de)
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_EVENTS_EVENT_H_
#define SKY_ENGINE_CORE_EVENTS_EVENT_H_

#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/core/dom/DOMTimeStamp.h"
#include "sky/engine/core/events/EventPath.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

class EventTarget;
class EventDispatcher;
class ExecutionContext;

struct EventInit {
    bool bubbles = false;
    bool cancelable = false;

private:
    STACK_ALLOCATED();
};

class Event : public RefCounted<Event>,  public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    enum PhaseType {
        NONE                = 0,
        CAPTURING_PHASE     = 1,
        AT_TARGET           = 2,
        BUBBLING_PHASE      = 3
    };

    enum EventType {
        MOUSEDOWN           = 1,
        MOUSEUP             = 2,
        MOUSEOVER           = 4,
        MOUSEOUT            = 8,
        MOUSEMOVE           = 16,
        MOUSEDRAG           = 32,
        CLICK               = 64,
        DBLCLICK            = 128,
        KEYDOWN             = 256,
        KEYUP               = 512,
        KEYPRESS            = 1024,
        DRAGDROP            = 2048,
        FOCUS               = 4096,
        BLUR                = 8192,
        SELECT              = 16384,
        CHANGE              = 32768
    };

    static PassRefPtr<Event> create()
    {
        return adoptRef(new Event);
    }

    // A factory for a simple event. The event doesn't bubble, and isn't
    // cancelable.
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/webappapis.html#fire-a-simple-event
    static PassRefPtr<Event> create(const AtomicString& type)
    {
        return adoptRef(new Event(type, false, false));
    }
    static PassRefPtr<Event> createCancelable(const AtomicString& type)
    {
        return adoptRef(new Event(type, false, true));
    }
    static PassRefPtr<Event> createBubble(const AtomicString& type)
    {
        return adoptRef(new Event(type, true, false));
    }
    static PassRefPtr<Event> createCancelableBubble(const AtomicString& type)
    {
        return adoptRef(new Event(type, true, true));
    }

    static PassRefPtr<Event> create(const AtomicString& type, const EventInit& initializer)
    {
        return adoptRef(new Event(type, initializer));
    }

    virtual ~Event();

    void initEvent(const AtomicString& type, bool canBubble, bool cancelable);

    const AtomicString& type() const { return m_type; }
    void setType(const AtomicString& type) { m_type = type; }

    EventTarget* target() const { return m_target.get(); }
    void setTarget(PassRefPtr<EventTarget>);

    EventTarget* currentTarget() const;
    void setCurrentTarget(EventTarget* currentTarget) { m_currentTarget = currentTarget; }

    unsigned short eventPhase() const { return m_eventPhase; }
    void setEventPhase(unsigned short eventPhase) { m_eventPhase = eventPhase; }

    bool bubbles() const { return m_canBubble; }
    bool cancelable() const { return m_cancelable; }
    DOMTimeStamp timeStamp() const { return m_createTime; }

    void stopPropagation() { m_propagationStopped = true; }
    void stopImmediatePropagation() { m_immediatePropagationStopped = true; }

    // IE Extensions
    EventTarget* srcElement() const { return target(); } // MSIE extension - "the object that fired the event"

    bool legacyReturnValue(ExecutionContext*) const;
    void setLegacyReturnValue(ExecutionContext*, bool returnValue);

    virtual const AtomicString& interfaceName() const;
    bool hasInterface(const AtomicString&) const;

    // These events are general classes of events.
    virtual bool isUIEvent() const;
    virtual bool isMouseEvent() const;
    virtual bool isFocusEvent() const;
    virtual bool isKeyboardEvent() const;
    virtual bool isTouchEvent() const;
    virtual bool isGestureEvent() const;
    virtual bool isWheelEvent() const;

    // Drag events are a subset of mouse events.
    virtual bool isDragEvent() const;

    // These events lack a DOM interface.
    virtual bool isClipboardEvent() const;
    virtual bool isBeforeTextInsertedEvent() const;

    bool propagationStopped() const { return m_propagationStopped || m_immediatePropagationStopped; }
    bool immediatePropagationStopped() const { return m_immediatePropagationStopped; }

    bool defaultPrevented() const { return m_defaultPrevented; }
    virtual void preventDefault()
    {
        if (m_cancelable)
            m_defaultPrevented = true;
    }
    void setDefaultPrevented(bool defaultPrevented) { m_defaultPrevented = defaultPrevented; }

    bool defaultHandled() const { return m_defaultHandled; }
    void setDefaultHandled() { m_defaultHandled = true; }

    bool cancelBubble() const { return m_cancelBubble; }
    void setCancelBubble(bool cancel) { m_cancelBubble = cancel; }

    Event* underlyingEvent() const { return m_underlyingEvent.get(); }
    void setUnderlyingEvent(PassRefPtr<Event>);

    EventPath& eventPath() { ASSERT(m_eventPath); return *m_eventPath; }
    EventPath& ensureEventPath();

    PassRefPtr<StaticNodeList> path() const;

    bool isBeingDispatched() const { return eventPhase(); }

protected:
    Event();
    Event(const AtomicString& type, bool canBubble, bool cancelable);
    Event(const AtomicString& type, const EventInit&);

    virtual void receivedTarget();
    bool dispatched() const { return m_target; }

private:
    AtomicString m_type;
    bool m_canBubble;
    bool m_cancelable;

    bool m_propagationStopped;
    bool m_immediatePropagationStopped;
    bool m_defaultPrevented;
    bool m_defaultHandled;
    bool m_cancelBubble;

    unsigned short m_eventPhase;
    RefPtr<EventTarget> m_currentTarget;
    RefPtr<EventTarget> m_target;
    DOMTimeStamp m_createTime;
    RefPtr<Event> m_underlyingEvent;
    OwnPtr<EventPath> m_eventPath;
};

#define DEFINE_EVENT_TYPE_CASTS(typeName) \
    DEFINE_TYPE_CASTS(typeName, Event, event, event->is##typeName(), event.is##typeName())

} // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_EVENT_H_
