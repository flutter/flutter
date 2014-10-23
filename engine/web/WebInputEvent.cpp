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
#include "public/web/WebInputEvent.h"

#include "platform/KeyboardCodes.h"
#include "wtf/Assertions.h"
#include "wtf/StringExtras.h"
#include <ctype.h>

namespace blink {

struct SameSizeAsWebInputEvent {
    int inputData[5];
};

struct SameSizeAsWebKeyboardEvent : public SameSizeAsWebInputEvent {
    int keyboardData[12];
};

struct SameSizeAsWebMouseEvent : public SameSizeAsWebInputEvent {
    int mouseData[10];
};

struct SameSizeAsWebMouseWheelEvent : public SameSizeAsWebMouseEvent {
    int mousewheelData[12];
};

struct SameSizeAsWebGestureEvent : public SameSizeAsWebInputEvent {
    int gestureData[9];
};

struct SameSizeAsWebTouchEvent : public SameSizeAsWebInputEvent {
    WebTouchPoint touchPoints[3 * WebTouchEvent::touchesLengthCap];
    int touchData[4];
};

COMPILE_ASSERT(sizeof(WebInputEvent) == sizeof(SameSizeAsWebInputEvent), WebInputEvent_has_gaps);
COMPILE_ASSERT(sizeof(WebKeyboardEvent) == sizeof(SameSizeAsWebKeyboardEvent), WebKeyboardEvent_has_gaps);
COMPILE_ASSERT(sizeof(WebMouseEvent) == sizeof(SameSizeAsWebMouseEvent), WebMouseEvent_has_gaps);
COMPILE_ASSERT(sizeof(WebMouseWheelEvent) == sizeof(SameSizeAsWebMouseWheelEvent), WebMouseWheelEvent_has_gaps);
COMPILE_ASSERT(sizeof(WebGestureEvent) == sizeof(SameSizeAsWebGestureEvent), WebGestureEvent_has_gaps);
COMPILE_ASSERT(sizeof(WebTouchEvent) == sizeof(SameSizeAsWebTouchEvent), WebTouchEvent_has_gaps);

static const char* staticKeyIdentifiers(unsigned short keyCode)
{
    switch (keyCode) {
    case VKEY_MENU:
        return "Alt";
    case VKEY_CONTROL:
        return "Control";
    case VKEY_SHIFT:
        return "Shift";
    case VKEY_CAPITAL:
        return "CapsLock";
    case VKEY_LWIN:
    case VKEY_RWIN:
        return "Win";
    case VKEY_CLEAR:
        return "Clear";
    case VKEY_DOWN:
        return "Down";
    case VKEY_END:
        return "End";
    case VKEY_RETURN:
        return "Enter";
    case VKEY_EXECUTE:
        return "Execute";
    case VKEY_F1:
        return "F1";
    case VKEY_F2:
        return "F2";
    case VKEY_F3:
        return "F3";
    case VKEY_F4:
        return "F4";
    case VKEY_F5:
        return "F5";
    case VKEY_F6:
        return "F6";
    case VKEY_F7:
        return "F7";
    case VKEY_F8:
        return "F8";
    case VKEY_F9:
        return "F9";
    case VKEY_F10:
        return "F10";
    case VKEY_F11:
        return "F11";
    case VKEY_F12:
        return "F12";
    case VKEY_F13:
        return "F13";
    case VKEY_F14:
        return "F14";
    case VKEY_F15:
        return "F15";
    case VKEY_F16:
        return "F16";
    case VKEY_F17:
        return "F17";
    case VKEY_F18:
        return "F18";
    case VKEY_F19:
        return "F19";
    case VKEY_F20:
        return "F20";
    case VKEY_F21:
        return "F21";
    case VKEY_F22:
        return "F22";
    case VKEY_F23:
        return "F23";
    case VKEY_F24:
        return "F24";
    case VKEY_HELP:
        return "Help";
    case VKEY_HOME:
        return "Home";
    case VKEY_INSERT:
        return "Insert";
    case VKEY_LEFT:
        return "Left";
    case VKEY_NEXT:
        return "PageDown";
    case VKEY_PRIOR:
        return "PageUp";
    case VKEY_PAUSE:
        return "Pause";
    case VKEY_SNAPSHOT:
        return "PrintScreen";
    case VKEY_RIGHT:
        return "Right";
    case VKEY_SCROLL:
        return "Scroll";
    case VKEY_SELECT:
        return "Select";
    case VKEY_UP:
        return "Up";
    case VKEY_DELETE:
        return "U+007F"; // Standard says that DEL becomes U+007F.
    case VKEY_MEDIA_NEXT_TRACK:
        return "MediaNextTrack";
    case VKEY_MEDIA_PREV_TRACK:
        return "MediaPreviousTrack";
    case VKEY_MEDIA_STOP:
        return "MediaStop";
    case VKEY_MEDIA_PLAY_PAUSE:
        return "MediaPlayPause";
    case VKEY_VOLUME_MUTE:
        return "VolumeMute";
    case VKEY_VOLUME_DOWN:
        return "VolumeDown";
    case VKEY_VOLUME_UP:
        return "VolumeUp";
    default:
        return 0;
    }
}

void WebKeyboardEvent::setKeyIdentifierFromWindowsKeyCode()
{
    const char* id = staticKeyIdentifiers(windowsKeyCode);
    if (id) {
        strncpy(keyIdentifier, id, sizeof(keyIdentifier) - 1);
        keyIdentifier[sizeof(keyIdentifier) - 1] = '\0';
    } else
        snprintf(keyIdentifier, sizeof(keyIdentifier), "U+%04X", toupper(windowsKeyCode));
}

// static
int WebKeyboardEvent::windowsKeyCodeWithoutLocation(int keycode)
{
    switch (keycode) {
    case VK_LCONTROL:
    case VK_RCONTROL:
        return VK_CONTROL;
    case VK_LSHIFT:
    case VK_RSHIFT:
        return VK_SHIFT;
    case VK_LMENU:
    case VK_RMENU:
        return VK_MENU;
    default:
        return keycode;
    }
}

// static
int WebKeyboardEvent::locationModifiersFromWindowsKeyCode(int keycode)
{
    switch (keycode) {
    case VK_LCONTROL:
    case VK_LSHIFT:
    case VK_LMENU:
    case VK_LWIN:
        return IsLeft;
    case VK_RCONTROL:
    case VK_RSHIFT:
    case VK_RMENU:
    case VK_RWIN:
        return IsRight;
    default:
        return 0;
    }
}

} // namespace blink
