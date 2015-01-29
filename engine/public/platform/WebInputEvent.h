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

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_WEBINPUTEVENT_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_WEBINPUTEVENT_H_

#include <string.h>
#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebGestureDevice.h"
#include "sky/engine/public/platform/WebRect.h"

namespace blink {

// The classes defined in this file are intended to be used with
// WebWidget's handleInputEvent method.  These event types are cross-
// platform and correspond closely to WebCore's Platform*Event classes.
//
// WARNING! These classes must remain PODs (plain old data).  They are
// intended to be "serializable" by copying their raw bytes, so they must
// not contain any non-bit-copyable member variables!
//
// Furthermore, the class members need to be packed so they are aligned
// properly and don't have paddings/gaps, otherwise memory check tools
// like Valgrind will complain about uninitialized memory usage when
// transferring these classes over the wire.

#pragma pack(push, 4)

// WebInputEvent --------------------------------------------------------------

class WebInputEvent {
public:
    // When we use an input method (or an input method editor), we receive
    // two events for a keypress. The former event is a keydown, which
    // provides a keycode, and the latter is a textinput, which provides
    // a character processed by an input method. (The mapping from a
    // keycode to a character code is not trivial for non-English
    // keyboards.)
    // To support input methods, Safari sends keydown events to WebKit for
    // filtering. WebKit sends filtered keydown events back to Safari,
    // which sends them to input methods.
    // Unfortunately, it is hard to apply this design to Chrome because of
    // our multiprocess architecture. An input method is running in a
    // browser process. On the other hand, WebKit is running in a renderer
    // process. So, this design results in increasing IPC messages.
    // To support input methods without increasing IPC messages, Chrome
    // handles keyboard events in a browser process and send asynchronous
    // input events (to be translated to DOM events) to a renderer
    // process.
    // This design is mostly the same as the one of Windows and Mac Carbon.
    // So, for what it's worth, our Linux and Mac front-ends emulate our
    // Windows front-end. To emulate our Windows front-end, we can share
    // our back-end code among Windows, Linux, and Mac.
    // TODO(hbono): Issue 18064: remove the KeyDown type since it isn't
    // used in Chrome any longer.

    enum Type {
        Undefined = -1,
        TypeFirst = Undefined,

        // WebPointerEvent
        PointerDown,
        PointerTypeFirst = PointerDown,
        PointerUp,
        PointerMove,
        PointerCancel,
        PointerTypeLast = PointerCancel,

        // WebKeyboardEvent
        KeyDown,
        KeyboardTypeFirst = KeyDown,
        KeyUp,
        Char,
        KeyboardTypeLast = Char,

        // WebGestureEvent
        GestureScrollBegin,
        GestureTypeFirst = GestureScrollBegin,
        GestureScrollEnd,
        GestureScrollUpdate,
        GestureScrollUpdateWithoutPropagation,
        GestureFlingStart,
        GestureFlingCancel,
        GestureShowPress,
        GestureTap,
        GestureTapUnconfirmed,
        GestureTapDown,
        GestureTapCancel,
        GestureDoubleTap,
        GestureTwoFingerTap,
        GestureLongPress,
        GestureLongTap,
        GesturePinchBegin,
        GesturePinchEnd,
        GesturePinchUpdate,
        GestureTypeLast = GesturePinchUpdate,

        WheelEvent,
    };

    enum Modifiers {
        // modifiers for all events:
        ShiftKey         = 1 << 0,
        ControlKey       = 1 << 1,
        AltKey           = 1 << 2,
        MetaKey          = 1 << 3,

        // modifiers for keyboard events:
        IsKeyPad         = 1 << 4,
        IsAutoRepeat     = 1 << 5,

        // modifiers for mouse events:
        LeftButtonDown   = 1 << 6,
        MiddleButtonDown = 1 << 7,
        RightButtonDown  = 1 << 8,

        // Toggle modifiers for all events. Danger: these are not reflected
        // into WebCore, so round-tripping from WebInputEvent to a WebCore
        // event and back will not preserve these flags.
        CapsLockOn       = 1 << 9,
        NumLockOn        = 1 << 10,

        // Left/right modifiers for keyboard events.
        IsLeft           = 1 << 11,
        IsRight          = 1 << 12,

        // Last input event to be sent for the current vsync interval. If this
        // flag is set, the sender guarantees that no more input events will be
        // delivered until the next vsync and the receiver can schedule
        // rendering accordingly. If it isn't set, the receiver should not make
        // any assumptions about the delivery times of future input events
        // w.r.t. vsync.
        IsLastInputEventForCurrentVSync = 1 << 13,
    };

    static const int InputModifiers = ShiftKey | ControlKey | AltKey | MetaKey;

    double timeStampMS; // Milliseconds since epoch.
    unsigned size; // The size of this structure, for serialization.
    Type type;
    int modifiers;

    static bool isPointerEventType(int type)
    {
        return PointerTypeFirst <= type && type <= PointerTypeLast;
    }

    static bool isKeyboardEventType(int type)
    {
        return KeyboardTypeFirst <= type && type <= KeyboardTypeLast;
    }

    static bool isGestureEventType(int type)
    {
        return GestureTypeFirst <= type && type <= GestureTypeLast;
    }

    static bool isWheelEventType(int type)
    {
        return type == WheelEvent;
    }

protected:
    explicit WebInputEvent(unsigned sizeParam)
    {
        memset(this, 0, sizeParam);
        timeStampMS = 0.0;
        size = sizeParam;
        type = Undefined;
        modifiers = 0;
    }
};

// WebPointerEvent ------------------------------------------------------------

class WebPointerEvent : public WebInputEvent {
public:
    enum Kind {
        Touch,
        Mouse,
        Stylus,
    };

    int pointer = 0;
    Kind kind = Touch;
    float x = 0;
    float y = 0;
    int buttons = 0;
    float pressure = 0;
    float pressureMin = 0;
    float pressureMax = 0;
    float distance = 0;
    float distanceMin = 0;
    float distanceMax = 0;
    float radiusMajor = 0;
    float radiusMinor = 0;
    float radiusMin = 0;
    float radiusMax = 0;
    float orientation = 0;
    float tilt = 0;

    WebPointerEvent() : WebInputEvent(sizeof(WebPointerEvent)) {}
};

// WebKeyboardEvent -----------------------------------------------------------

class WebKeyboardEvent : public WebInputEvent {
public:
    // |key| is the Windows key code associated with this key
    // event.  Sometimes it's direct from the event (i.e. on Windows),
    // sometimes it's via a mapping function.  If you want a list, see
    // WebCore/platform/chromium/KeyboardCodes* . Note that this should
    // ALWAYS store the non-locational version of a keycode as this is
    // what is returned by the Windows API. For example, it should
    // store VK_SHIFT instead of VK_RSHIFT. The location information
    // should be stored in |modifiers|.
    int key = 0;

    // |charCode| is the text generated by this keystroke.  |unmodifiedCharCode|
    // is |charCode|, but unmodified by an concurrently-held modifiers (except
    // shift).  This is useful for working out shortcut keys.
    WebUChar charCode = 0;
    WebUChar unmodifiedCharCode = 0;

    WebKeyboardEvent() : WebInputEvent(sizeof(WebKeyboardEvent)) {}
};

// WebWheelEvent --------------------------------------------------------------

class WebWheelEvent : public WebInputEvent {
public:
    float x = 0;
    float y = 0;
    float offsetX = 0;
    float offsetY = 0;

    WebWheelEvent() : WebInputEvent(sizeof(WebWheelEvent)) {}
};

// WebGestureEvent ------------------------------------------------------------

class WebGestureEvent : public WebInputEvent {
public:
    float x = 0;
    float y = 0;

    union {
        // Tap information must be set for GestureTap, GestureTapUnconfirmed,
        // and GestureDoubleTap events.
        struct {
            int tapCount;
            float width;
            float height;
        } tap;

        struct {
            float width;
            float height;
        } tapDown;

        struct {
            float width;
            float height;
        } showPress;

        struct {
            float width;
            float height;
        } longPress;

        struct {
            float firstFingerWidth;
            float firstFingerHeight;
        } twoFingerTap;

        struct {
            // Initial motion that triggered the scroll.
            // May be redundant with deltaX/deltaY in the first scrollUpdate.
            float deltaXHint;
            float deltaYHint;
        } scrollBegin;

        struct {
            float deltaX;
            float deltaY;
            float velocityX;
            float velocityY;
        } scrollUpdate;

        struct {
            float velocityX;
            float velocityY;
        } flingStart;

        struct {
            float scale;
        } pinchUpdate;
    } data;

    WebGestureEvent()
        : WebInputEvent(sizeof(WebGestureEvent))
    {
        memset(&data, 0, sizeof(data));
    }
};

#pragma pack(pop)

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_WEBINPUTEVENT_H_
