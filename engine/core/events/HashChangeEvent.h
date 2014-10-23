/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
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

#ifndef HashChangeEvent_h
#define HashChangeEvent_h

#include "core/events/Event.h"

namespace blink {

struct HashChangeEventInit : public EventInit {
    HashChangeEventInit()
    {
    };

    String oldURL;
    String newURL;
};

class HashChangeEvent FINAL : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<HashChangeEvent> create()
    {
        return adoptRefWillBeNoop(new HashChangeEvent);
    }

    static PassRefPtrWillBeRawPtr<HashChangeEvent> create(const String& oldURL, const String& newURL)
    {
        return adoptRefWillBeNoop(new HashChangeEvent(oldURL, newURL));
    }

    static PassRefPtrWillBeRawPtr<HashChangeEvent> create(const AtomicString& type, const HashChangeEventInit& initializer)
    {
        return adoptRefWillBeNoop(new HashChangeEvent(type, initializer));
    }

    void initHashChangeEvent(const AtomicString& eventType, bool canBubble, bool cancelable, const String& oldURL, const String& newURL)
    {
        if (dispatched())
            return;

        initEvent(eventType, canBubble, cancelable);

        m_oldURL = oldURL;
        m_newURL = newURL;
    }

    const String& oldURL() const { return m_oldURL; }
    const String& newURL() const { return m_newURL; }

    virtual const AtomicString& interfaceName() const OVERRIDE { return EventNames::HashChangeEvent; }

    virtual void trace(Visitor* visitor) OVERRIDE { Event::trace(visitor); }

private:
    HashChangeEvent()
    {
        ScriptWrappable::init(this);
    }

    HashChangeEvent(const String& oldURL, const String& newURL)
        : Event(EventTypeNames::hashchange, false, false)
        , m_oldURL(oldURL)
        , m_newURL(newURL)
    {
        ScriptWrappable::init(this);
    }

    HashChangeEvent(const AtomicString& type, const HashChangeEventInit& initializer)
        : Event(type, initializer)
        , m_oldURL(initializer.oldURL)
        , m_newURL(initializer.newURL)
    {
        ScriptWrappable::init(this);
    }

    String m_oldURL;
    String m_newURL;
};

} // namespace blink

#endif // HashChangeEvent_h
