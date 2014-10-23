/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 *           (C) 2007, 2008 Nikolas Zimmermann <zimmermann@kde.org>
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
 *
 */

#ifndef EventTarget_h
#define EventTarget_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/events/EventListenerMap.h"
#include "core/events/ThreadLocalEventNames.h"
#include "platform/heap/Handle.h"

namespace blink {

class LocalDOMWindow;
class Event;
class ExceptionState;
class MessagePort;
class Node;

struct FiringEventIterator {
    FiringEventIterator(const AtomicString& eventType, size_t& iterator, size_t& end)
        : eventType(eventType)
        , iterator(iterator)
        , end(end)
    {
    }

    const AtomicString& eventType;
    size_t& iterator;
    size_t& end;
};
typedef Vector<FiringEventIterator, 1> FiringEventIteratorVector;

struct EventTargetData {
    WTF_MAKE_NONCOPYABLE(EventTargetData); WTF_MAKE_FAST_ALLOCATED;
public:
    EventTargetData();
    ~EventTargetData();

    EventListenerMap eventListenerMap;
    OwnPtr<FiringEventIteratorVector> firingEventIterators;
};

// This is the base class for all DOM event targets. To make your class an
// EventTarget, follow these steps:
// - Make your IDL interface inherit from EventTarget.
//   Optionally add "attribute EventHandler onfoo;" attributes.
// - Inherit from EventTargetWithInlineData (only in rare cases should you use
//   EventTarget directly).
// - Figure out if you now need to inherit from ActiveDOMObject as well.
// - In your class declaration, you will typically use
//   REFCOUNTED_EVENT_TARGET(YourClassName) and
//   WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(YourClassName). Make sure to include
//   this header file in your .h file, or you will get very strange compiler
//   errors.
// - If you added an onfoo attribute, use DEFINE_ATTRIBUTE_EVENT_LISTENER(foo)
//   in your class declaration.
// - Call ScriptWrappable::init(this) in your constructor, unless you are already
//   doing so.
// - Override EventTarget::interfaceName() and executionContext(). The former
//   will typically return EventTargetNames::YourClassName. The latter will
//   return ActiveDOMObject::executionContext (if you are an ActiveDOMObject)
//   or the document you're in.
// - Your trace() method will need to call EventTargetWithInlineData::trace.
//
// Optionally, add a FooEvent.idl class, but that's outside the scope of this
// comment (and much more straightforward).
class EventTarget : public WillBeGarbageCollectedMixin, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
#if !ENABLE(OILPAN)
    void ref() { refEventTarget(); }
    void deref() { derefEventTarget(); }
#endif

    virtual const AtomicString& interfaceName() const = 0;
    virtual ExecutionContext* executionContext() const = 0;

    virtual Node* toNode();
    virtual LocalDOMWindow* toDOMWindow();
    virtual MessagePort* toMessagePort();

    // FIXME: first 2 args to addEventListener and removeEventListener should
    // be required (per spec), but throwing TypeError breaks legacy content.
    // http://crbug.com/353484
    bool addEventListener() { return false; }
    bool addEventListener(const AtomicString& eventType) { return false; }
    virtual bool addEventListener(const AtomicString& eventType, PassRefPtr<EventListener>, bool useCapture = false);
    bool removeEventListener() { return false; }
    bool removeEventListener(const AtomicString& eventType) { return false; }
    virtual bool removeEventListener(const AtomicString& eventType, PassRefPtr<EventListener>, bool useCapture = false);
    virtual void removeAllEventListeners();
    virtual bool dispatchEvent(PassRefPtrWillBeRawPtr<Event>);
    bool dispatchEvent(PassRefPtrWillBeRawPtr<Event>, ExceptionState&); // DOM API
    virtual void uncaughtExceptionInEventHandler();

    // Used for legacy "onEvent" attribute APIs.
    bool setAttributeEventListener(const AtomicString& eventType, PassRefPtr<EventListener>);
    EventListener* getAttributeEventListener(const AtomicString& eventType);

    bool hasEventListeners() const;
    bool hasEventListeners(const AtomicString& eventType) const;
    bool hasCapturingEventListeners(const AtomicString& eventType);
    const EventListenerVector& getEventListeners(const AtomicString& eventType);
    Vector<AtomicString> eventTypes();

    bool fireEventListeners(Event*);

    virtual void trace(Visitor*) { }

    virtual bool keepEventInNode(Event*) { return false; };

protected:
    EventTarget();
    virtual ~EventTarget();

    // Subclasses should likely not override these themselves; instead, they should subclass EventTargetWithInlineData.
    virtual EventTargetData* eventTargetData() = 0;
    virtual EventTargetData& ensureEventTargetData() = 0;

private:
#if !ENABLE(OILPAN)
    // Subclasses should likely not override these themselves; instead, they should use the REFCOUNTED_EVENT_TARGET() macro.
    virtual void refEventTarget() = 0;
    virtual void derefEventTarget() = 0;
#endif

    LocalDOMWindow* executingWindow();
    void fireEventListeners(Event*, EventTargetData*, EventListenerVector&);
    void countLegacyEvents(const AtomicString& legacyTypeName, EventListenerVector*, EventListenerVector*);

    bool clearAttributeEventListener(const AtomicString& eventType);

    friend class EventListenerIterator;
};

class EventTargetWithInlineData : public EventTarget {
protected:
    virtual EventTargetData* eventTargetData() OVERRIDE FINAL { return &m_eventTargetData; }
    virtual EventTargetData& ensureEventTargetData() OVERRIDE FINAL { return m_eventTargetData; }
private:
    EventTargetData m_eventTargetData;
};

// FIXME: These macros should be split into separate DEFINE and DECLARE
// macros to avoid causing so many header includes.
#define DEFINE_ATTRIBUTE_EVENT_LISTENER(attribute) \
    EventListener* on##attribute() { return getAttributeEventListener(EventTypeNames::attribute); } \
    void setOn##attribute(PassRefPtr<EventListener> listener) { setAttributeEventListener(EventTypeNames::attribute, listener); } \

#define DEFINE_STATIC_ATTRIBUTE_EVENT_LISTENER(attribute) \
    static EventListener* on##attribute(EventTarget& eventTarget) { return eventTarget.getAttributeEventListener(EventTypeNames::attribute); } \
    static void setOn##attribute(EventTarget& eventTarget, PassRefPtr<EventListener> listener) { eventTarget.setAttributeEventListener(EventTypeNames::attribute, listener); } \

#define DEFINE_WINDOW_ATTRIBUTE_EVENT_LISTENER(attribute) \
    EventListener* on##attribute() { return document().getWindowAttributeEventListener(EventTypeNames::attribute); } \
    void setOn##attribute(PassRefPtr<EventListener> listener) { document().setWindowAttributeEventListener(EventTypeNames::attribute, listener); } \

#define DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(attribute) \
    static EventListener* on##attribute(EventTarget& eventTarget) { \
        if (Node* node = eventTarget.toNode()) \
            return node->document().getWindowAttributeEventListener(EventTypeNames::attribute); \
        ASSERT(eventTarget.toDOMWindow()); \
        return eventTarget.getAttributeEventListener(EventTypeNames::attribute); \
    } \
    static void setOn##attribute(EventTarget& eventTarget, PassRefPtr<EventListener> listener) { \
        if (Node* node = eventTarget.toNode()) \
            node->document().setWindowAttributeEventListener(EventTypeNames::attribute, listener); \
        else { \
            ASSERT(eventTarget.toDOMWindow()); \
            eventTarget.setAttributeEventListener(EventTypeNames::attribute, listener); \
        } \
    }

#define DEFINE_MAPPED_ATTRIBUTE_EVENT_LISTENER(attribute, eventName) \
    EventListener* on##attribute() { return getAttributeEventListener(EventTypeNames::eventName); } \
    void setOn##attribute(PassRefPtr<EventListener> listener) { setAttributeEventListener(EventTypeNames::eventName, listener); } \

#define DECLARE_FORWARDING_ATTRIBUTE_EVENT_LISTENER(recipient, attribute) \
    EventListener* on##attribute(); \
    void setOn##attribute(PassRefPtr<EventListener> listener);

#define DEFINE_FORWARDING_ATTRIBUTE_EVENT_LISTENER(type, recipient, attribute) \
    EventListener* type::on##attribute() { return recipient ? recipient->getAttributeEventListener(EventTypeNames::attribute) : 0; } \
    void type::setOn##attribute(PassRefPtr<EventListener> listener) \
    { \
        if (recipient) \
            recipient->setAttributeEventListener(EventTypeNames::attribute, listener); \
    }

inline bool EventTarget::hasEventListeners() const
{
    // FIXME: We should have a const version of eventTargetData.
    if (const EventTargetData* d = const_cast<EventTarget*>(this)->eventTargetData())
        return !d->eventListenerMap.isEmpty();
    return false;
}

inline bool EventTarget::hasEventListeners(const AtomicString& eventType) const
{
    // FIXME: We should have const version of eventTargetData.
    if (const EventTargetData* d = const_cast<EventTarget*>(this)->eventTargetData())
        return d->eventListenerMap.contains(eventType);
    return false;
}

inline bool EventTarget::hasCapturingEventListeners(const AtomicString& eventType)
{
    EventTargetData* d = eventTargetData();
    if (!d)
        return false;
    return d->eventListenerMap.containsCapturing(eventType);
}

} // namespace blink

#if ENABLE(OILPAN)
#define DEFINE_EVENT_TARGET_REFCOUNTING(baseClass) \
public: \
    using baseClass::ref; \
    using baseClass::deref; \
private: \
    typedef int thisIsHereToForceASemiColonAfterThisEventTargetMacro
#define DEFINE_EVENT_TARGET_REFCOUNTING_WILL_BE_REMOVED(baseClass)
#else
#define DEFINE_EVENT_TARGET_REFCOUNTING(baseClass) \
public: \
    using baseClass::ref; \
    using baseClass::deref; \
private: \
    virtual void refEventTarget() OVERRIDE FINAL { ref(); } \
    virtual void derefEventTarget() OVERRIDE FINAL { deref(); } \
    typedef int thisIsHereToForceASemiColonAfterThisEventTargetMacro
#define DEFINE_EVENT_TARGET_REFCOUNTING_WILL_BE_REMOVED(baseClass) DEFINE_EVENT_TARGET_REFCOUNTING(baseClass)
#endif

// Use this macro if your EventTarget subclass is also a subclass of WTF::RefCounted.
// A ref-counted class that uses a different method of refcounting should use DEFINE_EVENT_TARGET_REFCOUNTING directly.
// Both of these macros are meant to be placed just before the "public:" section of the class declaration.
#define REFCOUNTED_EVENT_TARGET(className) DEFINE_EVENT_TARGET_REFCOUNTING_WILL_BE_REMOVED(RefCounted<className>)

#endif // EventTarget_h
