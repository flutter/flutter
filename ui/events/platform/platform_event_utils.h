// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_PLATFORM_EVENT_UTILS_H_
#define UI_EVENTS_PLATFORM_PLATFORM_EVENT_UTILS_H_

#include "base/basictypes.h"
#include "base/event_types.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string16.h"
#include "ui/events/event_constants.h"
#include "ui/events/events_export.h"
#include "ui/events/keycodes/keyboard_codes.h"
#include "ui/gfx/display.h"
#include "ui/gfx/native_widget_types.h"

namespace gfx {
class Point;
class Vector2d;
}

namespace base {
class TimeDelta;
}

namespace ui {

class Event;
class MouseEvent;

// Updates the list of devices for cached properties.
EVENTS_EXPORT void UpdateDeviceList();

// Get the EventType from a native event.
EVENTS_EXPORT EventType
EventTypeFromNative(const base::NativeEvent& native_event);

// Get the EventFlags from a native event.
EVENTS_EXPORT int EventFlagsFromNative(const base::NativeEvent& native_event);

// Get the timestamp from a native event.
EVENTS_EXPORT base::TimeDelta EventTimeFromNative(
    const base::NativeEvent& native_event);

// Get the location from a native event.  The coordinate system of the resultant
// |Point| has the origin at top-left of the "root window".  The nature of
// this "root window" and how it maps to platform-specific drawing surfaces is
// defined in ui/aura/root_window.* and ui/aura/window_tree_host*.
// TODO(tdresser): Return gfx::PointF here. See crbug.com/337827.
EVENTS_EXPORT gfx::Point EventLocationFromNative(
    const base::NativeEvent& native_event);

// Gets the location in native system coordinate space.
EVENTS_EXPORT gfx::Point EventSystemLocationFromNative(
    const base::NativeEvent& native_event);

#if defined(USE_X11)
// Returns the 'real' button for an event. The button reported in slave events
// does not take into account any remapping (e.g. using xmodmap), while the
// button reported in master events do. This is a utility function to always
// return the mapped button.
EVENTS_EXPORT int EventButtonFromNative(const base::NativeEvent& native_event);
#endif

// Returns the KeyboardCode from a native event.
EVENTS_EXPORT KeyboardCode
KeyboardCodeFromNative(const base::NativeEvent& native_event);

// Returns the DOM KeyboardEvent code (physical location in the
// keyboard) from a native event.  The ownership of the return value
// is NOT trasferred to the caller.
EVENTS_EXPORT const char* CodeFromNative(const base::NativeEvent& native_event);

// Returns the platform related key code. For X11, it is xksym value.
EVENTS_EXPORT uint32
PlatformKeycodeFromNative(const base::NativeEvent& native_event);

// Returns true if the keyboard event is a character event rather than
// a keystroke event.
EVENTS_EXPORT bool IsCharFromNative(const base::NativeEvent& native_event);

// Returns the flags of the button that changed during a press/release.
EVENTS_EXPORT int GetChangedMouseButtonFlagsFromNative(
    const base::NativeEvent& native_event);

// Gets the mouse wheel offsets from a native event.
EVENTS_EXPORT gfx::Vector2d GetMouseWheelOffset(
    const base::NativeEvent& native_event);

// Gets the touch id from a native event.
EVENTS_EXPORT int GetTouchId(const base::NativeEvent& native_event);

// Increases the number of times |ClearTouchIdIfReleased| needs to be called on
// an event with a given touch id before it will actually be cleared.
EVENTS_EXPORT void IncrementTouchIdRefCount(
    const base::NativeEvent& native_event);

// Clear the touch id from bookkeeping if it is a release/cancel event.
EVENTS_EXPORT void ClearTouchIdIfReleased(
    const base::NativeEvent& native_event);

// Gets the radius along the X/Y axis from a native event. Default is 1.0.
EVENTS_EXPORT float GetTouchRadiusX(const base::NativeEvent& native_event);
EVENTS_EXPORT float GetTouchRadiusY(const base::NativeEvent& native_event);

// Gets the angle of the major axis away from the X axis. Default is 0.0.
EVENTS_EXPORT float GetTouchAngle(const base::NativeEvent& native_event);

// Gets the force from a native_event. Normalized to be [0, 1]. Default is 0.0.
EVENTS_EXPORT float GetTouchForce(const base::NativeEvent& native_event);

// Gets the fling velocity from a native event. is_cancel is set to true if
// this was a tap down, intended to stop an ongoing fling.
EVENTS_EXPORT bool GetFlingData(const base::NativeEvent& native_event,
                                float* vx,
                                float* vy,
                                float* vx_ordinal,
                                float* vy_ordinal,
                                bool* is_cancel);

// Returns whether this is a scroll event and optionally gets the amount to be
// scrolled. |x_offset|, |y_offset| and |finger_count| can be NULL.
EVENTS_EXPORT bool GetScrollOffsets(const base::NativeEvent& native_event,
                                    float* x_offset,
                                    float* y_offset,
                                    float* x_offset_ordinal,
                                    float* y_offset_ordinal,
                                    int* finger_count);

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_PLATFORM_EVENT_UTILS_H_
