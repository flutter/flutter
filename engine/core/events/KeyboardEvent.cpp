// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/events/KeyboardEvent.h"

namespace blink {

static AtomicString stringForType(WebInputEvent::Type type)
{
    if (type == WebInputEvent::KeyDown)
        return EventTypeNames::keydown;
    if (type == WebInputEvent::Char)
        return EventTypeNames::keypress;
    if (type == WebInputEvent::KeyUp)
        return EventTypeNames::keyup;
    ASSERT_NOT_REACHED();
    return AtomicString();
}

static String locationFromModifiers(int modifiers)
{
    if (modifiers & WebInputEvent::IsKeyPad)
        return "numpad";
    if (modifiers & WebInputEvent::IsLeft)
        return "left";
    if (modifiers & WebInputEvent::IsRight)
        return "right";
    return "standard";
}

KeyboardEvent::~KeyboardEvent()
{
}

const AtomicString& KeyboardEvent::interfaceName() const
{
    return EventNames::KeyboardEvent;
}

bool KeyboardEvent::isKeyboardEvent() const
{
    return true;
}

KeyboardEvent::KeyboardEvent()
    : KeyboardEvent(AtomicString(), KeyboardEventInit())
{
}

KeyboardEvent::KeyboardEvent(const WebKeyboardEvent& event)
    : Event(stringForType(event.type), true, true)
    , m_key(event.key)
    , m_location(locationFromModifiers(event.modifiers))
    , m_charCode(event.charCode)
    , m_ctrlKey(event.modifiers & WebInputEvent::ControlKey)
    , m_shiftKey(event.modifiers & WebInputEvent::ShiftKey)
    , m_altKey(event.modifiers & WebInputEvent::AltKey)
    , m_metaKey(event.modifiers & WebInputEvent::MetaKey)
    , m_repeat(event.modifiers & WebInputEvent::IsAutoRepeat)
{
    m_timeStamp = event.timeStampMS;

    if (event.type == WebInputEvent::KeyDown || event.type == WebInputEvent::KeyUp) {
        m_charCode = 0;
    } else if (event.type == WebInputEvent::Char) {
        m_key = 0;
        m_location = String();
    }
}

KeyboardEvent::KeyboardEvent(const AtomicString& type, const KeyboardEventInit& initializer)
    : Event(type, initializer)
    , m_key(initializer.key)
    , m_location(initializer.location)
    , m_charCode(initializer.charCode)
    , m_ctrlKey(initializer.ctrlKey)
    , m_shiftKey(initializer.shiftKey)
    , m_altKey(initializer.altKey)
    , m_metaKey(initializer.metaKey)
    , m_repeat(initializer.repeat)
{
}

} // namespace blink
