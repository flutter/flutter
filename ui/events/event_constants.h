// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENT_CONSTANTS_H_
#define UI_EVENTS_EVENT_CONSTANTS_H_

namespace ui {

// Event types. (prefixed because of a conflict with windows headers)
enum EventType {
  ET_UNKNOWN = 0,
  ET_MOUSE_PRESSED,
  ET_MOUSE_DRAGGED,
  ET_MOUSE_RELEASED,
  ET_MOUSE_MOVED,
  ET_MOUSE_ENTERED,
  ET_MOUSE_EXITED,
  ET_KEY_PRESSED,
  ET_KEY_RELEASED,
  ET_MOUSEWHEEL,
  ET_MOUSE_CAPTURE_CHANGED,  // Event has no location.
  ET_TOUCH_RELEASED,
  ET_TOUCH_PRESSED,
  ET_TOUCH_MOVED,
  ET_TOUCH_CANCELLED,
  ET_DROP_TARGET_EVENT,
  ET_TRANSLATED_KEY_PRESS,
  ET_TRANSLATED_KEY_RELEASE,

  // GestureEvent types
  ET_GESTURE_SCROLL_BEGIN,
  ET_GESTURE_TYPE_START = ET_GESTURE_SCROLL_BEGIN,
  ET_GESTURE_SCROLL_END,
  ET_GESTURE_SCROLL_UPDATE,
  ET_GESTURE_TAP,
  ET_GESTURE_TAP_DOWN,
  ET_GESTURE_TAP_CANCEL,
  ET_GESTURE_TAP_UNCONFIRMED, // User tapped, but the tap delay hasn't expired.
  ET_GESTURE_DOUBLE_TAP,
  ET_GESTURE_BEGIN,  // The first event sent when each finger is pressed.
  ET_GESTURE_END,    // Sent for each released finger.
  ET_GESTURE_TWO_FINGER_TAP,
  ET_GESTURE_PINCH_BEGIN,
  ET_GESTURE_PINCH_END,
  ET_GESTURE_PINCH_UPDATE,
  ET_GESTURE_LONG_PRESS,
  ET_GESTURE_LONG_TAP,
  // A SWIPE gesture can happen at the end of a touch sequence involving one or
  // more fingers if the finger velocity was high enough when the first finger
  // was released.
  ET_GESTURE_SWIPE,
  ET_GESTURE_SHOW_PRESS,

  // Sent by Win8+ metro when the user swipes from the bottom or top.
  ET_GESTURE_WIN8_EDGE_SWIPE,

  // Scroll support.
  // TODO[davemoore] we need to unify these events w/ touch and gestures.
  ET_SCROLL,
  ET_SCROLL_FLING_START,
  ET_SCROLL_FLING_CANCEL,
  ET_GESTURE_TYPE_END = ET_SCROLL_FLING_CANCEL,

  // Sent by the system to indicate any modal type operations, such as drag and
  // drop or menus, should stop.
  ET_CANCEL_MODE,

  // Sent by the CrOS gesture library for interesting patterns that we want
  // to track with the UMA system.
  ET_UMA_DATA,

  // Must always be last. User namespace starts above this value.
  // See ui::RegisterCustomEventType().
  ET_LAST
};

// Event flags currently supported
enum EventFlags {
  EF_NONE                = 0,       // Used to denote no flags explicitly
  EF_CAPS_LOCK_DOWN      = 1 << 0,
  EF_SHIFT_DOWN          = 1 << 1,
  EF_CONTROL_DOWN        = 1 << 2,
  EF_ALT_DOWN            = 1 << 3,
  EF_LEFT_MOUSE_BUTTON   = 1 << 4,
  EF_MIDDLE_MOUSE_BUTTON = 1 << 5,
  EF_RIGHT_MOUSE_BUTTON  = 1 << 6,
  EF_COMMAND_DOWN        = 1 << 7,  // GUI Key (e.g. Command on OS X keyboards,
                                    // Search on Chromebook keyboards,
                                    // Windows on MS-oriented keyboards)
  EF_EXTENDED            = 1 << 8,  // Windows extended key (see WM_KEYDOWN doc)
  EF_IS_SYNTHESIZED      = 1 << 9,
  EF_ALTGR_DOWN          = 1 << 10,
  EF_MOD3_DOWN           = 1 << 11,
};

// Flags specific to key events
enum KeyEventFlags {
  EF_NUMPAD_KEY         = 1 << 16,  // Key originates from number pad (Xkb only)
  EF_IME_FABRICATED_KEY = 1 << 17,  // Key event fabricated by the underlying
                                    // IME without a user action.
                                    // (Linux X11 only)
  EF_IS_REPEAT          = 1 << 18,
  EF_FUNCTION_KEY       = 1 << 19,  // Key originates from function key row
  EF_FINAL              = 1 << 20,  // Do not remap; the event was created with
                                    // the desired final values.
};

// Flags specific to mouse events
enum MouseEventFlags {
  EF_IS_DOUBLE_CLICK     = 1 << 16,
  EF_IS_TRIPLE_CLICK     = 1 << 17,
  EF_IS_NON_CLIENT       = 1 << 18,
  EF_FROM_TOUCH          = 1 << 19,  // Indicates this mouse event is generated
                                     // from an unconsumed touch/gesture event.
  EF_TOUCH_ACCESSIBILITY = 1 << 20,  // Indicates this event was generated from
                                     // touch accessibility mode.
};

// Result of dispatching an event.
enum EventResult {
  ER_UNHANDLED = 0,       // The event hasn't been handled. The event can be
                          // propagated to other handlers.
  ER_HANDLED   = 1 << 0,  // The event has already been handled, but it can
                          // still be propagated to other handlers.
  ER_CONSUMED  = 1 << 1,  // The event has been handled, and it should not be
                          // propagated to other handlers.
};

// Phase of the event dispatch.
enum EventPhase {
  EP_PREDISPATCH,
  EP_PRETARGET,
  EP_TARGET,
  EP_POSTTARGET,
  EP_POSTDISPATCH
};

// Device ID for Touch and Key Events.
enum EventDeviceId {
  ED_UNKNOWN_DEVICE = -1
};

}  // namespace ui

#endif  // UI_EVENTS_EVENT_CONSTANTS_H_
