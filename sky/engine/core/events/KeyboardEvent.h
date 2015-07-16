// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_EVENTS_KEYBOARDEVENT_H_
#define SKY_ENGINE_CORE_EVENTS_KEYBOARDEVENT_H_

#include "sky/engine/core/events/Event.h"
#include "sky/engine/public/platform/WebInputEvent.h"

namespace blink {

struct KeyboardEventInit : public EventInit {
    unsigned key = 0;
    String location;
    unsigned charCode = 0;
    bool ctrlKey = false;
    bool shiftKey = false;
    bool altKey = false;
    bool metaKey = false;
    bool repeat = false;
};

class KeyboardEvent : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<KeyboardEvent> create()
    {
        return adoptRef(new KeyboardEvent);
    }
    static PassRefPtr<KeyboardEvent> create(const WebKeyboardEvent& event)
    {
        return adoptRef(new KeyboardEvent(event));
    }
    static PassRefPtr<KeyboardEvent> create(const AtomicString& type, const KeyboardEventInit& initializer)
    {
        return adoptRef(new KeyboardEvent(type, initializer));
    }

    ~KeyboardEvent() override;
    const AtomicString& interfaceName() const override;

    bool isKeyboardEvent() const override;

    unsigned key() const { return m_key; }
    const String& location() const { return m_location; }
    unsigned charCode() const { return m_charCode; }
    bool ctrlKey() const { return m_ctrlKey; }
    bool shiftKey() const { return m_shiftKey; }
    bool altKey() const { return m_altKey; }
    bool metaKey() const { return m_metaKey; }
    bool repeat() const { return m_repeat; }

private:
    KeyboardEvent();
    explicit KeyboardEvent(const WebKeyboardEvent& event);
    KeyboardEvent(const AtomicString&, const KeyboardEventInit&);

    unsigned m_key;
    String m_location;
    unsigned m_charCode;
    bool m_ctrlKey;
    bool m_shiftKey;
    bool m_altKey;
    bool m_metaKey;
    bool m_repeat;
};

DEFINE_EVENT_TYPE_CASTS(KeyboardEvent);

} // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_KEYBOARDEVENT_H_
