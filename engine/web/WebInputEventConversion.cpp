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

#include "config.h"
#include "web/WebInputEventConversion.h"

#include "core/dom/Touch.h"
#include "core/dom/TouchList.h"
#include "core/events/GestureEvent.h"
#include "core/events/KeyboardEvent.h"
#include "core/events/MouseEvent.h"
#include "core/events/TouchEvent.h"
#include "core/events/WheelEvent.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/PinchViewport.h"
#include "core/page/Page.h"
#include "core/rendering/RenderObject.h"
#include "platform/KeyboardCodes.h"
#include "platform/Widget.h"
#include "platform/scroll/ScrollView.h"

namespace blink {

static const double millisPerSecond = 1000.0;

static float widgetInputEventsScaleFactor(const Widget* widget)
{
    if (!widget)
        return 1;

    ScrollView* rootView =  toScrollView(widget->root());
    if (!rootView)
        return 1;

    return rootView->inputEventsScaleFactor();
}

static IntSize widgetInputEventsOffset(const Widget* widget)
{
    if (!widget)
        return IntSize();
    ScrollView* rootView =  toScrollView(widget->root());
    if (!rootView)
        return IntSize();

    return rootView->inputEventsOffsetForEmulation();
}

static IntPoint pinchViewportOffset(const Widget* widget)
{
    // Event position needs to be adjusted by the pinch viewport's offset within the
    // main frame before being passed into the widget's convertFromContainingWindow.
    FrameView* rootView = toFrameView(widget->root());
    if (!rootView)
        return IntPoint();

    return flooredIntPoint(rootView->page()->frameHost().pinchViewport().visibleRect().location());
}

// MakePlatformMouseEvent -----------------------------------------------------

PlatformMouseEventBuilder::PlatformMouseEventBuilder(Widget* widget, const WebMouseEvent& e)
{
    float scale = widgetInputEventsScaleFactor(widget);
    IntSize offset = widgetInputEventsOffset(widget);
    IntPoint pinchViewport = pinchViewportOffset(widget);

    // FIXME: Widget is always toplevel, unless it's a popup. We may be able
    // to get rid of this once we abstract popups into a WebKit API.
    m_position = widget->convertFromContainingWindow(
        IntPoint((e.x - offset.width()) / scale + pinchViewport.x(), (e.y - offset.height()) / scale + pinchViewport.y()));
    m_globalPosition = IntPoint(e.globalX, e.globalY);
    m_movementDelta = IntPoint(e.movementX / scale, e.movementY / scale);
    m_button = static_cast<MouseButton>(e.button);

    m_modifiers = 0;
    if (e.modifiers & WebInputEvent::ShiftKey)
        m_modifiers |= PlatformEvent::ShiftKey;
    if (e.modifiers & WebInputEvent::ControlKey)
        m_modifiers |= PlatformEvent::CtrlKey;
    if (e.modifiers & WebInputEvent::AltKey)
        m_modifiers |= PlatformEvent::AltKey;
    if (e.modifiers & WebInputEvent::MetaKey)
        m_modifiers |= PlatformEvent::MetaKey;

    m_modifierFlags = e.modifiers;
    m_timestamp = e.timeStampSeconds;
    m_clickCount = e.clickCount;

    switch (e.type) {
    case WebInputEvent::MouseMove:
    case WebInputEvent::MouseLeave:  // synthesize a move event
        m_type = PlatformEvent::MouseMoved;
        break;

    case WebInputEvent::MouseDown:
        m_type = PlatformEvent::MousePressed;
        break;

    case WebInputEvent::MouseUp:
        m_type = PlatformEvent::MouseReleased;
        break;

    default:
        ASSERT_NOT_REACHED();
    }
}

// PlatformWheelEventBuilder --------------------------------------------------

PlatformWheelEventBuilder::PlatformWheelEventBuilder(Widget* widget, const WebMouseWheelEvent& e)
{
    float scale = widgetInputEventsScaleFactor(widget);
    IntSize offset = widgetInputEventsOffset(widget);
    IntPoint pinchViewport = pinchViewportOffset(widget);

    m_position = widget->convertFromContainingWindow(
        IntPoint((e.x - offset.width()) / scale + pinchViewport.x(), (e.y - offset.height()) / scale + pinchViewport.y()));
    m_globalPosition = IntPoint(e.globalX, e.globalY);
    m_deltaX = e.deltaX;
    m_deltaY = e.deltaY;
    m_wheelTicksX = e.wheelTicksX;
    m_wheelTicksY = e.wheelTicksY;
    m_granularity = e.scrollByPage ?
        ScrollByPageWheelEvent : ScrollByPixelWheelEvent;

    m_type = PlatformEvent::Wheel;

    m_modifiers = 0;
    if (e.modifiers & WebInputEvent::ShiftKey)
        m_modifiers |= PlatformEvent::ShiftKey;
    if (e.modifiers & WebInputEvent::ControlKey)
        m_modifiers |= PlatformEvent::CtrlKey;
    if (e.modifiers & WebInputEvent::AltKey)
        m_modifiers |= PlatformEvent::AltKey;
    if (e.modifiers & WebInputEvent::MetaKey)
        m_modifiers |= PlatformEvent::MetaKey;

    m_hasPreciseScrollingDeltas = e.hasPreciseScrollingDeltas;
#if OS(MACOSX)
    m_phase = static_cast<PlatformWheelEventPhase>(e.phase);
    m_momentumPhase = static_cast<PlatformWheelEventPhase>(e.momentumPhase);
    m_timestamp = e.timeStampSeconds;
    m_scrollCount = 0;
    m_unacceleratedScrollingDeltaX = e.deltaX;
    m_unacceleratedScrollingDeltaY = e.deltaY;
    m_canRubberbandLeft = e.canRubberbandLeft;
    m_canRubberbandRight = e.canRubberbandRight;
#endif
}

// PlatformGestureEventBuilder --------------------------------------------------

PlatformGestureEventBuilder::PlatformGestureEventBuilder(Widget* widget, const WebGestureEvent& e)
{
    float scale = widgetInputEventsScaleFactor(widget);
    IntSize offset = widgetInputEventsOffset(widget);
    IntPoint pinchViewport = pinchViewportOffset(widget);

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
    m_position = widget->convertFromContainingWindow(
        IntPoint((e.x - offset.width()) / scale + pinchViewport.x(), (e.y - offset.height()) / scale + pinchViewport.y()));
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

inline PlatformEvent::Type toPlatformTouchEventType(const WebInputEvent::Type type)
{
    switch (type) {
    case WebInputEvent::TouchStart:
        return PlatformEvent::TouchStart;
    case WebInputEvent::TouchMove:
        return PlatformEvent::TouchMove;
    case WebInputEvent::TouchEnd:
        return PlatformEvent::TouchEnd;
    case WebInputEvent::TouchCancel:
        return PlatformEvent::TouchCancel;
    default:
        ASSERT_NOT_REACHED();
    }
    return PlatformEvent::TouchStart;
}

inline PlatformTouchPoint::State toPlatformTouchPointState(const WebTouchPoint::State state)
{
    switch (state) {
    case WebTouchPoint::StateReleased:
        return PlatformTouchPoint::TouchReleased;
    case WebTouchPoint::StatePressed:
        return PlatformTouchPoint::TouchPressed;
    case WebTouchPoint::StateMoved:
        return PlatformTouchPoint::TouchMoved;
    case WebTouchPoint::StateStationary:
        return PlatformTouchPoint::TouchStationary;
    case WebTouchPoint::StateCancelled:
        return PlatformTouchPoint::TouchCancelled;
    case WebTouchPoint::StateUndefined:
        ASSERT_NOT_REACHED();
    }
    return PlatformTouchPoint::TouchReleased;
}

inline WebTouchPoint::State toWebTouchPointState(const AtomicString& type)
{
    if (type == EventTypeNames::touchend)
        return WebTouchPoint::StateReleased;
    if (type == EventTypeNames::touchcancel)
        return WebTouchPoint::StateCancelled;
    if (type == EventTypeNames::touchstart)
        return WebTouchPoint::StatePressed;
    if (type == EventTypeNames::touchmove)
        return WebTouchPoint::StateMoved;
    return WebTouchPoint::StateUndefined;
}

PlatformTouchPointBuilder::PlatformTouchPointBuilder(Widget* widget, const WebTouchPoint& point)
{
    float scale = 1.0f / widgetInputEventsScaleFactor(widget);
    IntSize offset = widgetInputEventsOffset(widget);
    IntPoint pinchViewport = pinchViewportOffset(widget);
    m_id = point.id;
    m_state = toPlatformTouchPointState(point.state);
    FloatPoint pos = (point.position - offset).scaledBy(scale);
    pos.moveBy(pinchViewport);
    IntPoint flooredPoint = flooredIntPoint(pos);
    // This assumes convertFromContainingWindow does only translations, not scales.
    m_pos = widget->convertFromContainingWindow(flooredPoint) + (pos - flooredPoint);
    m_screenPos = FloatPoint(point.screenPosition.x, point.screenPosition.y);
    m_radius = FloatSize(point.radiusX, point.radiusY).scaledBy(scale);
    m_rotationAngle = point.rotationAngle;
    m_force = point.force;
}

PlatformTouchEventBuilder::PlatformTouchEventBuilder(Widget* widget, const WebTouchEvent& event)
{
    m_type = toPlatformTouchEventType(event.type);

    m_modifiers = 0;
    if (event.modifiers & WebInputEvent::ShiftKey)
        m_modifiers |= PlatformEvent::ShiftKey;
    if (event.modifiers & WebInputEvent::ControlKey)
        m_modifiers |= PlatformEvent::CtrlKey;
    if (event.modifiers & WebInputEvent::AltKey)
        m_modifiers |= PlatformEvent::AltKey;
    if (event.modifiers & WebInputEvent::MetaKey)
        m_modifiers |= PlatformEvent::MetaKey;

    m_timestamp = event.timeStampSeconds;

    for (unsigned i = 0; i < event.touchesLength; ++i)
        m_touchPoints.append(PlatformTouchPointBuilder(widget, event.touches[i]));

    m_cancelable = event.cancelable;
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

static void updateWebMouseEventFromCoreMouseEvent(const MouseRelatedEvent& event, const Widget& widget, const RenderObject& renderObject, WebMouseEvent& webEvent)
{
    webEvent.timeStampSeconds = event.timeStamp() / millisPerSecond;
    webEvent.modifiers = getWebInputModifiers(event);

    ScrollView* view =  toScrollView(widget.parent());
    IntPoint windowPoint = IntPoint(event.absoluteLocation().x(), event.absoluteLocation().y());
    if (view)
        windowPoint = view->contentsToWindow(windowPoint);
    webEvent.globalX = event.screenX();
    webEvent.globalY = event.screenY();
    webEvent.windowX = windowPoint.x();
    webEvent.windowY = windowPoint.y();
    IntPoint localPoint = convertAbsoluteLocationForRenderObject(event.absoluteLocation(), renderObject);
    webEvent.x = localPoint.x();
    webEvent.y = localPoint.y();
}

WebMouseEventBuilder::WebMouseEventBuilder(const Widget* widget, const RenderObject* renderObject, const MouseEvent& event)
{
    if (event.type() == EventTypeNames::mousemove)
        type = WebInputEvent::MouseMove;
    else if (event.type() == EventTypeNames::mouseout)
        type = WebInputEvent::MouseLeave;
    else if (event.type() == EventTypeNames::mouseover)
        type = WebInputEvent::MouseEnter;
    else if (event.type() == EventTypeNames::mousedown)
        type = WebInputEvent::MouseDown;
    else if (event.type() == EventTypeNames::mouseup)
        type = WebInputEvent::MouseUp;
    else if (event.type() == EventTypeNames::contextmenu)
        type = WebInputEvent::ContextMenu;
    else
        return; // Skip all other mouse events.

    updateWebMouseEventFromCoreMouseEvent(event, *widget, *renderObject, *this);

    switch (event.button()) {
    case LeftButton:
        button = WebMouseEvent::ButtonLeft;
        break;
    case MiddleButton:
        button = WebMouseEvent::ButtonMiddle;
        break;
    case RightButton:
        button = WebMouseEvent::ButtonRight;
        break;
    }
    if (event.buttonDown()) {
        switch (event.button()) {
        case LeftButton:
            modifiers |= WebInputEvent::LeftButtonDown;
            break;
        case MiddleButton:
            modifiers |= WebInputEvent::MiddleButtonDown;
            break;
        case RightButton:
            modifiers |= WebInputEvent::RightButtonDown;
            break;
        }
    } else
        button = WebMouseEvent::ButtonNone;
    movementX = event.movementX();
    movementY = event.movementY();
    clickCount = event.detail();
}

// Generate a synthetic WebMouseEvent given a TouchEvent (eg. for emulating a mouse
// with touch input for plugins that don't support touch input).
WebMouseEventBuilder::WebMouseEventBuilder(const Widget* widget, const RenderObject* renderObject, const TouchEvent& event)
{
    if (!event.touches())
        return;
    if (event.touches()->length() != 1) {
        if (event.touches()->length() || event.type() != EventTypeNames::touchend || !event.changedTouches() || event.changedTouches()->length() != 1)
            return;
    }

    const Touch* touch = event.touches()->length() == 1 ? event.touches()->item(0) : event.changedTouches()->item(0);
    if (touch->identifier())
        return;

    if (event.type() == EventTypeNames::touchstart)
        type = MouseDown;
    else if (event.type() == EventTypeNames::touchmove)
        type = MouseMove;
    else if (event.type() == EventTypeNames::touchend)
        type = MouseUp;
    else
        return;

    timeStampSeconds = event.timeStamp() / millisPerSecond;
    modifiers = getWebInputModifiers(event);

    // The mouse event co-ordinates should be generated from the co-ordinates of the touch point.
    ScrollView* view =  toScrollView(widget->parent());
    IntPoint windowPoint = roundedIntPoint(touch->absoluteLocation());
    if (view)
        windowPoint = view->contentsToWindow(windowPoint);
    IntPoint screenPoint = roundedIntPoint(touch->screenLocation());
    globalX = screenPoint.x();
    globalY = screenPoint.y();
    windowX = windowPoint.x();
    windowY = windowPoint.y();

    button = WebMouseEvent::ButtonLeft;
    modifiers |= WebInputEvent::LeftButtonDown;
    clickCount = (type == MouseDown || type == MouseUp);

    IntPoint localPoint = convertAbsoluteLocationForRenderObject(touch->absoluteLocation(), *renderObject);
    x = localPoint.x();
    y = localPoint.y();
}

WebMouseEventBuilder::WebMouseEventBuilder(const Widget* widget, const PlatformMouseEvent& event)
{
    switch (event.type()) {
    case PlatformEvent::MouseMoved:
        type = MouseMove;
        break;
    case PlatformEvent::MousePressed:
        type = MouseDown;
        break;
    case PlatformEvent::MouseReleased:
        type = MouseUp;
        break;
    default:
        ASSERT_NOT_REACHED();
        type = Undefined;
        return;
    }

    modifiers = 0;
    if (event.modifiers() & PlatformEvent::ShiftKey)
        modifiers |= ShiftKey;
    if (event.modifiers() & PlatformEvent::CtrlKey)
        modifiers |= ControlKey;
    if (event.modifiers() & PlatformEvent::AltKey)
        modifiers |= AltKey;
    if (event.modifiers() & PlatformEvent::MetaKey)
        modifiers |= MetaKey;

    timeStampSeconds = event.timestamp();

    // FIXME: Widget is always toplevel, unless it's a popup. We may be able
    // to get rid of this once we abstract popups into a WebKit API.
    IntPoint position = widget->convertToContainingWindow(event.position());
    float scale = widgetInputEventsScaleFactor(widget);
    position.scale(scale, scale);
    x = position.x();
    y = position.y();
    globalX = event.globalPosition().x();
    globalY = event.globalPosition().y();
    movementX = event.movementDelta().x() * scale;
    movementY = event.movementDelta().y() * scale;

    button = static_cast<Button>(event.button());
    clickCount = event.clickCount();
}

WebMouseWheelEventBuilder::WebMouseWheelEventBuilder(const Widget* widget, const RenderObject* renderObject, const WheelEvent& event)
{
    if (event.type() != EventTypeNames::wheel && event.type() != EventTypeNames::mousewheel)
        return;
    type = WebInputEvent::MouseWheel;
    updateWebMouseEventFromCoreMouseEvent(event, *widget, *renderObject, *this);
    deltaX = -event.deltaX();
    deltaY = -event.deltaY();
    wheelTicksX = event.ticksX();
    wheelTicksY = event.ticksY();
    scrollByPage = event.deltaMode() == WheelEvent::DOM_DELTA_PAGE;
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

static void addTouchPoints(const Widget* widget, const AtomicString& touchType, TouchList* touches, WebTouchPoint* touchPoints, unsigned* touchPointsLength, const RenderObject* renderObject)
{
    unsigned numberOfTouches = std::min(touches->length(), static_cast<unsigned>(WebTouchEvent::touchesLengthCap));
    for (unsigned i = 0; i < numberOfTouches; ++i) {
        const Touch* touch = touches->item(i);

        WebTouchPoint point;
        point.id = touch->identifier();
        point.screenPosition = touch->screenLocation();
        point.position = convertAbsoluteLocationForRenderObjectFloat(touch->absoluteLocation(), *renderObject);
        point.radiusX = touch->radiusX();
        point.radiusY = touch->radiusY();
        point.rotationAngle = touch->webkitRotationAngle();
        point.force = touch->force();
        point.state = toWebTouchPointState(touchType);

        touchPoints[i] = point;
    }
    *touchPointsLength = numberOfTouches;
}

WebTouchEventBuilder::WebTouchEventBuilder(const Widget* widget, const RenderObject* renderObject, const TouchEvent& event)
{
    if (event.type() == EventTypeNames::touchstart)
        type = TouchStart;
    else if (event.type() == EventTypeNames::touchmove)
        type = TouchMove;
    else if (event.type() == EventTypeNames::touchend)
        type = TouchEnd;
    else if (event.type() == EventTypeNames::touchcancel)
        type = TouchCancel;
    else {
        ASSERT_NOT_REACHED();
        type = Undefined;
        return;
    }

    modifiers = getWebInputModifiers(event);
    timeStampSeconds = event.timeStamp() / millisPerSecond;
    cancelable = event.cancelable();

    addTouchPoints(widget, event.type(), event.touches(), touches, &touchesLength, renderObject);
    addTouchPoints(widget, event.type(), event.changedTouches(), changedTouches, &changedTouchesLength, renderObject);
    addTouchPoints(widget, event.type(), event.targetTouches(), targetTouches, &targetTouchesLength, renderObject);
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
