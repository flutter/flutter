/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/web/WebInputEventConversion.h"

#include "sky/engine/core/events/GestureEvent.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/platform/KeyboardCodes.h"
#include "sky/engine/platform/Widget.h"

namespace blink {

static const double millisPerSecond = 1000.0;

static float widgetInputEventsScaleFactor(const Widget* widget)
{
    if (!widget)
        return 1;

    FrameView* rootView = toFrameView(widget->root());
    if (!rootView)
        return 1;

    return rootView->inputEventsScaleFactor();
}

static IntSize widgetInputEventsOffset(const Widget* widget)
{
    if (!widget)
        return IntSize();
    FrameView* rootView = toFrameView(widget->root());
    if (!rootView)
        return IntSize();

    return rootView->inputEventsOffsetForEmulation();
}


// PlatformGestureEventBuilder --------------------------------------------------

PlatformGestureEventBuilder::PlatformGestureEventBuilder(Widget* widget, const WebGestureEvent& e)
{
    float scale = widgetInputEventsScaleFactor(widget);
    IntSize offset = widgetInputEventsOffset(widget);

    switch (e.type) {
    case WebInputEvent::GestureScrollBegin:
        m_type = PlatformEvent::GestureScrollBegin;
        break;
    case WebInputEvent::GestureScrollEnd:
        m_type = PlatformEvent::GestureScrollEnd;
        break;
    case WebInputEvent::GestureFlingStart:
        m_type = PlatformEvent::GestureFlingStart;
        break;
    case WebInputEvent::GestureScrollUpdate:
        m_type = PlatformEvent::GestureScrollUpdate;
        m_data.m_scrollUpdate.m_deltaX = e.data.scrollUpdate.deltaX / scale;
        m_data.m_scrollUpdate.m_deltaY = e.data.scrollUpdate.deltaY / scale;
        m_data.m_scrollUpdate.m_velocityX = e.data.scrollUpdate.velocityX;
        m_data.m_scrollUpdate.m_velocityY = e.data.scrollUpdate.velocityY;
        break;
    case WebInputEvent::GestureScrollUpdateWithoutPropagation:
        m_type = PlatformEvent::GestureScrollUpdateWithoutPropagation;
        m_data.m_scrollUpdate.m_deltaX = e.data.scrollUpdate.deltaX / scale;
        m_data.m_scrollUpdate.m_deltaY = e.data.scrollUpdate.deltaY / scale;
        m_data.m_scrollUpdate.m_velocityX = e.data.scrollUpdate.velocityX;
        m_data.m_scrollUpdate.m_velocityY = e.data.scrollUpdate.velocityY;
        break;
    case WebInputEvent::GestureTap:
        m_type = PlatformEvent::GestureTap;
        m_area = expandedIntSize(FloatSize(e.data.tap.width / scale, e.data.tap.height / scale));
        m_data.m_tap.m_tapCount = e.data.tap.tapCount;
        break;
    case WebInputEvent::GestureTapUnconfirmed:
        m_type = PlatformEvent::GestureTapUnconfirmed;
        m_area = expandedIntSize(FloatSize(e.data.tap.width / scale, e.data.tap.height / scale));
        break;
    case WebInputEvent::GestureTapDown:
        m_type = PlatformEvent::GestureTapDown;
        m_area = expandedIntSize(FloatSize(e.data.tapDown.width / scale, e.data.tapDown.height / scale));
        break;
    case WebInputEvent::GestureShowPress:
        m_type = PlatformEvent::GestureShowPress;
        m_area = expandedIntSize(FloatSize(e.data.showPress.width / scale, e.data.showPress.height / scale));
        break;
    case WebInputEvent::GestureTapCancel:
        m_type = PlatformEvent::GestureTapDownCancel;
        break;
    case WebInputEvent::GestureDoubleTap:
        // DoubleTap gesture is now handled as PlatformEvent::GestureTap with tap_count = 2. So no
        // need to convert to a Platfrom DoubleTap gesture. But in WebViewImpl::handleGestureEvent
        // all WebGestureEvent are converted to PlatformGestureEvent, for completeness and not reach
        // the ASSERT_NOT_REACHED() at the end, convert the DoubleTap to a NoType.
        m_type = PlatformEvent::NoType;
        break;
    case WebInputEvent::GestureTwoFingerTap:
        m_type = PlatformEvent::GestureTwoFingerTap;
        m_area = expandedIntSize(FloatSize(e.data.twoFingerTap.firstFingerWidth / scale, e.data.twoFingerTap.firstFingerHeight / scale));
        break;
    case WebInputEvent::GestureLongPress:
        m_type = PlatformEvent::GestureLongPress;
        m_area = expandedIntSize(FloatSize(e.data.longPress.width / scale, e.data.longPress.height / scale));
        break;
    case WebInputEvent::GestureLongTap:
        m_type = PlatformEvent::GestureLongTap;
        m_area = expandedIntSize(FloatSize(e.data.longPress.width / scale, e.data.longPress.height / scale));
        break;
    case WebInputEvent::GesturePinchBegin:
        m_type = PlatformEvent::GesturePinchBegin;
        break;
    case WebInputEvent::GesturePinchEnd:
        m_type = PlatformEvent::GesturePinchEnd;
        break;
    case WebInputEvent::GesturePinchUpdate:
        m_type = PlatformEvent::GesturePinchUpdate;
        m_data.m_pinchUpdate.m_scale = e.data.pinchUpdate.scale;
        break;
    default:
        ASSERT_NOT_REACHED();
    }
    m_position = widget->convertFromContainingView(
        IntPoint((e.x - offset.width()) / scale, (e.y - offset.height()) / scale));
    m_globalPosition = IntPoint(e.globalX, e.globalY);
    m_timestamp = e.timeStampSeconds;

    m_modifiers = 0;
    if (e.modifiers & WebInputEvent::ShiftKey)
        m_modifiers |= PlatformEvent::ShiftKey;
    if (e.modifiers & WebInputEvent::ControlKey)
        m_modifiers |= PlatformEvent::CtrlKey;
    if (e.modifiers & WebInputEvent::AltKey)
        m_modifiers |= PlatformEvent::AltKey;
    if (e.modifiers & WebInputEvent::MetaKey)
        m_modifiers |= PlatformEvent::MetaKey;
}

// MakePlatformKeyboardEvent --------------------------------------------------

inline PlatformEvent::Type toPlatformKeyboardEventType(WebInputEvent::Type type)
{
    switch (type) {
    case WebInputEvent::KeyUp:
        return PlatformEvent::KeyUp;
    case WebInputEvent::KeyDown:
        return PlatformEvent::KeyDown;
    case WebInputEvent::RawKeyDown:
        return PlatformEvent::RawKeyDown;
    case WebInputEvent::Char:
        return PlatformEvent::Char;
    default:
        ASSERT_NOT_REACHED();
    }
    return PlatformEvent::KeyDown;
}

PlatformKeyboardEventBuilder::PlatformKeyboardEventBuilder(const WebKeyboardEvent& e)
{
    m_type = toPlatformKeyboardEventType(e.type);
    m_text = String(e.text);
    m_unmodifiedText = String(e.unmodifiedText);
    m_keyIdentifier = String(e.keyIdentifier);
    m_autoRepeat = (e.modifiers & WebInputEvent::IsAutoRepeat);
    m_nativeVirtualKeyCode = e.nativeKeyCode;
    m_isKeypad = (e.modifiers & WebInputEvent::IsKeyPad);
    m_isSystemKey = e.isSystemKey;

    m_modifiers = 0;
    if (e.modifiers & WebInputEvent::ShiftKey)
        m_modifiers |= PlatformEvent::ShiftKey;
    if (e.modifiers & WebInputEvent::ControlKey)
        m_modifiers |= PlatformEvent::CtrlKey;
    if (e.modifiers & WebInputEvent::AltKey)
        m_modifiers |= PlatformEvent::AltKey;
    if (e.modifiers & WebInputEvent::MetaKey)
        m_modifiers |= PlatformEvent::MetaKey;

    // FIXME: PlatformKeyboardEvents expect a locational version of the keycode (e.g. VK_LSHIFT
    // instead of VK_SHIFT). This should be changed so the location/keycode are stored separately,
    // as in other places in the code.
    m_windowsVirtualKeyCode = e.windowsKeyCode;
    if (e.windowsKeyCode == VK_SHIFT) {
        if (e.modifiers & WebInputEvent::IsLeft)
            m_windowsVirtualKeyCode = VK_LSHIFT;
        else if (e.modifiers & WebInputEvent::IsRight)
            m_windowsVirtualKeyCode = VK_RSHIFT;
    } else if (e.windowsKeyCode == VK_CONTROL) {
        if (e.modifiers & WebInputEvent::IsLeft)
            m_windowsVirtualKeyCode = VK_LCONTROL;
        else if (e.modifiers & WebInputEvent::IsRight)
            m_windowsVirtualKeyCode = VK_RCONTROL;
    } else if (e.windowsKeyCode == VK_MENU) {
        if (e.modifiers & WebInputEvent::IsLeft)
            m_windowsVirtualKeyCode = VK_LMENU;
        else if (e.modifiers & WebInputEvent::IsRight)
            m_windowsVirtualKeyCode = VK_RMENU;
    }

}

void PlatformKeyboardEventBuilder::setKeyType(Type type)
{
    // According to the behavior of Webkit in Windows platform,
    // we need to convert KeyDown to RawKeydown and Char events
    // See WebKit/WebKit/Win/WebView.cpp
    ASSERT(m_type == KeyDown);
    ASSERT(type == RawKeyDown || type == Char);
    m_type = type;

    if (type == RawKeyDown) {
        m_text = String();
        m_unmodifiedText = String();
    } else {
        m_keyIdentifier = String();
        m_windowsVirtualKeyCode = 0;
    }
}

// Please refer to bug http://b/issue?id=961192, which talks about Webkit
// keyboard event handling changes. It also mentions the list of keys
// which don't have associated character events.
bool PlatformKeyboardEventBuilder::isCharacterKey() const
{
    switch (windowsVirtualKeyCode()) {
    case VKEY_BACK:
    case VKEY_ESCAPE:
        return false;
    }
    return true;
}

static int getWebInputModifiers(const UIEventWithKeyState& event)
{
    int modifiers = 0;
    if (event.ctrlKey())
        modifiers |= WebInputEvent::ControlKey;
    if (event.shiftKey())
        modifiers |= WebInputEvent::ShiftKey;
    if (event.altKey())
        modifiers |= WebInputEvent::AltKey;
    if (event.metaKey())
        modifiers |= WebInputEvent::MetaKey;
    return modifiers;
}

static FloatPoint convertAbsoluteLocationForRenderObjectFloat(const LayoutPoint& location, const RenderObject& renderObject)
{
    return renderObject.absoluteToLocal(location, UseTransforms);
}

static IntPoint convertAbsoluteLocationForRenderObject(const LayoutPoint& location, const RenderObject& renderObject)
{
    return roundedIntPoint(convertAbsoluteLocationForRenderObjectFloat(location, renderObject));
}

WebKeyboardEventBuilder::WebKeyboardEventBuilder(const KeyboardEvent& event)
{
    if (event.type() == EventTypeNames::keydown)
        type = KeyDown;
    else if (event.type() == EventTypeNames::keyup)
        type = WebInputEvent::KeyUp;
    else if (event.type() == EventTypeNames::keypress)
        type = WebInputEvent::Char;
    else
        return; // Skip all other keyboard events.

    modifiers = getWebInputModifiers(event);
    if (event.location() == KeyboardEvent::DOM_KEY_LOCATION_NUMPAD)
        modifiers |= WebInputEvent::IsKeyPad;
    else if (event.location() == KeyboardEvent::DOM_KEY_LOCATION_LEFT)
        modifiers |= WebInputEvent::IsLeft;
    else if (event.location() == KeyboardEvent::DOM_KEY_LOCATION_RIGHT)
        modifiers |= WebInputEvent::IsRight;

    timeStampSeconds = event.timeStamp() / millisPerSecond;
    windowsKeyCode = event.keyCode();

    // The platform keyevent does not exist if the event was created using
    // initKeyboardEvent.
    if (!event.keyEvent())
        return;
    nativeKeyCode = event.keyEvent()->nativeVirtualKeyCode();
    unsigned numberOfCharacters = std::min(event.keyEvent()->text().length(), static_cast<unsigned>(textLengthCap));
    for (unsigned i = 0; i < numberOfCharacters; ++i) {
        text[i] = event.keyEvent()->text()[i];
        unmodifiedText[i] = event.keyEvent()->unmodifiedText()[i];
    }
    memcpy(keyIdentifier, event.keyIdentifier().ascii().data(), event.keyIdentifier().length());
}

WebInputEvent::Type toWebKeyboardEventType(PlatformEvent::Type type)
{
    switch (type) {
    case PlatformEvent::KeyUp:
        return WebInputEvent::KeyUp;
    case PlatformEvent::KeyDown:
        return WebInputEvent::KeyDown;
    case PlatformEvent::RawKeyDown:
        return WebInputEvent::RawKeyDown;
    case PlatformEvent::Char:
        return WebInputEvent::Char;
    default:
        return WebInputEvent::Undefined;
    }
}

int toWebKeyboardEventModifiers(int modifiers)
{
    int newModifiers = 0;
    if (modifiers & PlatformEvent::ShiftKey)
        newModifiers |= WebInputEvent::ShiftKey;
    if (modifiers & PlatformEvent::CtrlKey)
        newModifiers |= WebInputEvent::ControlKey;
    if (modifiers & PlatformEvent::AltKey)
        newModifiers |= WebInputEvent::AltKey;
    if (modifiers & PlatformEvent::MetaKey)
        newModifiers |= WebInputEvent::MetaKey;
    return newModifiers;
}

WebKeyboardEventBuilder::WebKeyboardEventBuilder(const PlatformKeyboardEvent& event)
{
    type = toWebKeyboardEventType(event.type());
    modifiers = toWebKeyboardEventModifiers(event.modifiers());
    if (event.isAutoRepeat())
        modifiers |= WebInputEvent::IsAutoRepeat;
    if (event.isKeypad())
        modifiers |= WebInputEvent::IsKeyPad;
    isSystemKey = event.isSystemKey();
    nativeKeyCode = event.nativeVirtualKeyCode();

    windowsKeyCode = windowsKeyCodeWithoutLocation(event.windowsVirtualKeyCode());
    modifiers |= locationModifiersFromWindowsKeyCode(event.windowsVirtualKeyCode());

    event.text().copyTo(text, 0, textLengthCap);
    event.unmodifiedText().copyTo(unmodifiedText, 0, textLengthCap);
    memcpy(keyIdentifier, event.keyIdentifier().ascii().data(), std::min(static_cast<unsigned>(keyIdentifierLengthCap), event.keyIdentifier().length()));
}

WebGestureEventBuilder::WebGestureEventBuilder(const Widget* widget, const RenderObject* renderObject, const GestureEvent& event)
{
    if (event.type() == EventTypeNames::gestureshowpress)
        type = GestureShowPress;
    else if (event.type() == EventTypeNames::gesturetapdown)
        type = GestureTapDown;
    else if (event.type() == EventTypeNames::gesturescrollstart)
        type = GestureScrollBegin;
    else if (event.type() == EventTypeNames::gesturescrollend)
        type = GestureScrollEnd;
    else if (event.type() == EventTypeNames::gesturescrollupdate) {
        type = GestureScrollUpdate;
        data.scrollUpdate.deltaX = event.deltaX();
        data.scrollUpdate.deltaY = event.deltaY();
    } else if (event.type() == EventTypeNames::gesturetap) {
        type = GestureTap;
        data.tap.tapCount = 1;
    }

    timeStampSeconds = event.timeStamp() / millisPerSecond;
    modifiers = getWebInputModifiers(event);

    globalX = event.screenX();
    globalY = event.screenY();
    IntPoint localPoint = convertAbsoluteLocationForRenderObject(event.absoluteLocation(), *renderObject);
    x = localPoint.x();
    y = localPoint.y();
}

} // namespace blink
