// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/platform_event_builder.h"

#if defined(USE_X11)
#include <X11/extensions/XInput2.h>
#include <X11/Xlib.h>
#include <X11/keysym.h>
#endif

#include "ui/events/event.h"
#include "ui/events/platform/platform_event_utils.h"

namespace ui {
namespace {

bool X11EventHasNonStandardState(const base::NativeEvent& event) {
#if defined(USE_X11)
  const unsigned int kAllStateMask =
      Button1Mask | Button2Mask | Button3Mask | Button4Mask | Button5Mask |
      Mod1Mask | Mod2Mask | Mod3Mask | Mod4Mask | Mod5Mask | ShiftMask |
      LockMask | ControlMask | AnyModifier;
  return event && (event->xkey.state & ~kAllStateMask) != 0;
#else
  return false;
#endif
}

bool IsX11SendEventTrue(const base::NativeEvent& event) {
#if defined(USE_X11)
  return event && event->xany.send_event;
#else
  return false;
#endif
}

KeyEvent* last_key_event_ = nullptr;
MouseEvent* last_click_event_ = nullptr;

// We can create a MouseEvent for a native event more than once. We set this
// to true when the next event either has a different timestamp or we see a
// release signalling that the press (click) event was completed.
bool last_click_complete_ = false;

bool IsRepeated(const base::NativeEvent& native_event, const KeyEvent& event) {
  // A safe guard in case if there were continous key pressed events that are
  // not auto repeat.
  const int kMaxAutoRepeatTimeMs = 2000;
  // Ignore key events that have non standard state masks as it may be
  // reposted by an IME. IBUS-GTK uses this field to detect the
  // re-posted event for example. crbug.com/385873.
  if (X11EventHasNonStandardState(native_event))
    return false;
  if (event.is_char())
    return false;
  if (event.type() == ui::ET_KEY_RELEASED) {
    delete last_key_event_;
    last_key_event_ = NULL;
    return false;
  }
  CHECK_EQ(ui::ET_KEY_PRESSED, event.type());
  if (!last_key_event_) {
    last_key_event_ = new KeyEvent(event);
    return false;
  }
  if (event.key_code() == last_key_event_->key_code() &&
      event.flags() == last_key_event_->flags() &&
      (event.time_stamp() - last_key_event_->time_stamp()).InMilliseconds() <
          kMaxAutoRepeatTimeMs) {
    return true;
  }
  delete last_key_event_;
  last_key_event_ = new KeyEvent(event);
  return false;
}

}  // namespace

// static
MouseEvent PlatformEventBuilder::BuildMouseEvent(
    const base::NativeEvent& native_event) {
  MouseEvent mouse_event;
  FillEventFrom(native_event, &mouse_event);
  FillLocatedEventFrom(native_event, &mouse_event);
  FillMouseEventFrom(native_event, &mouse_event);
  return mouse_event;
}

// static
MouseWheelEvent PlatformEventBuilder::BuildMouseWheelEvent(
    const base::NativeEvent& native_event) {
  MouseWheelEvent mouse_wheel_event;
  FillEventFrom(native_event, &mouse_wheel_event);
  FillLocatedEventFrom(native_event, &mouse_wheel_event);
  FillMouseEventFrom(native_event, &mouse_wheel_event);
  FillMouseWheelEventFrom(native_event, &mouse_wheel_event);
  return mouse_wheel_event;
}

// static
TouchEvent PlatformEventBuilder::BuildTouchEvent(
    const base::NativeEvent& native_event) {
  TouchEvent touch_event;
  FillEventFrom(native_event, &touch_event);
  FillLocatedEventFrom(native_event, &touch_event);
  FillTouchEventFrom(native_event, &touch_event);
  return touch_event;
}

// static
KeyEvent PlatformEventBuilder::BuildKeyEvent(
    const base::NativeEvent& native_event) {
  KeyEvent key_event;
  FillEventFrom(native_event, &key_event);
  FillKeyEventFrom(native_event, &key_event);
  return key_event;
}

// static
ScrollEvent PlatformEventBuilder::BuildScrollEvent(
    const base::NativeEvent& native_event) {
  ScrollEvent scroll_event;
  FillEventFrom(native_event, &scroll_event);
  FillLocatedEventFrom(native_event, &scroll_event);
  FillMouseEventFrom(native_event, &scroll_event);
  FillScrollEventFrom(native_event, &scroll_event);
  return scroll_event;
}

// static
int PlatformEventBuilder::GetRepeatCount(const base::NativeEvent& native_event,
                                         const MouseEvent& event) {
  int click_count = 1;
  if (last_click_event_) {
    if (event.type() == ui::ET_MOUSE_RELEASED) {
      if (event.changed_button_flags() ==
          last_click_event_->changed_button_flags()) {
        last_click_complete_ = true;
        return last_click_event_->GetClickCount();
      } else {
        // If last_click_event_ has changed since this button was pressed
        // return a click count of 1.
        return click_count;
      }
    }
    if (event.time_stamp() != last_click_event_->time_stamp())
      last_click_complete_ = true;
    if (!last_click_complete_ || IsX11SendEventTrue(native_event)) {
      click_count = last_click_event_->GetClickCount();
    } else if (MouseEvent::IsRepeatedClickEvent(*last_click_event_, event)) {
      click_count = last_click_event_->GetClickCount() + 1;
    }
    delete last_click_event_;
  }
  last_click_event_ = new MouseEvent(event);
  last_click_complete_ = false;
  if (click_count > 3)
    click_count = 3;
  last_click_event_->SetClickCount(click_count);
  return click_count;
}

// static
void PlatformEventBuilder::ResetLastClickForTest() {
  if (last_click_event_) {
    delete last_click_event_;
    last_click_event_ = NULL;
    last_click_complete_ = false;
  }
}

// static
void PlatformEventBuilder::FillEventFrom(const base::NativeEvent& native_event,
                                         Event* event) {
  event->set_type(EventTypeFromNative(native_event));
  event->set_time_stamp(EventTimeFromNative(native_event));
  event->set_flags(EventFlagsFromNative(native_event));

#if defined(USE_X11)
  if (native_event->type == GenericEvent) {
    XIDeviceEvent* xiev =
        static_cast<XIDeviceEvent*>(native_event->xcookie.data);
    event->set_source_device_id(xiev->sourceid);
  }
#endif
}

// static
void PlatformEventBuilder::FillLocatedEventFrom(
    const base::NativeEvent& native_event,
    LocatedEvent* located_event) {
  gfx::PointF event_location = EventLocationFromNative(native_event);
  located_event->set_location(event_location);
  located_event->set_root_location(event_location);
  located_event->set_screen_location(
      EventSystemLocationFromNative(native_event));
}

// static
void PlatformEventBuilder::FillMouseEventFrom(
    const base::NativeEvent& native_event,
    MouseEvent* mouse_event) {
  mouse_event->set_changed_button_flags(
      GetChangedMouseButtonFlagsFromNative(native_event));

  if (mouse_event->type() == ET_MOUSE_PRESSED ||
      mouse_event->type() == ET_MOUSE_RELEASED) {
    mouse_event->SetClickCount(GetRepeatCount(native_event, *mouse_event));
  }
}

// static
void PlatformEventBuilder::FillMouseWheelEventFrom(
    const base::NativeEvent& native_event,
    MouseWheelEvent* mouse_wheel_event) {
  mouse_wheel_event->set_offset(GetMouseWheelOffset(native_event));
}

// static
void PlatformEventBuilder::FillTouchEventFrom(
    const base::NativeEvent& native_event,
    TouchEvent* touch_event) {
  touch_event->set_touch_id(GetTouchId(native_event));
  touch_event->set_radius_x(GetTouchRadiusX(native_event));
  touch_event->set_radius_y(GetTouchRadiusY(native_event));
  touch_event->set_rotation_angle(GetTouchAngle(native_event));
  touch_event->set_force(GetTouchForce(native_event));
}

// static
void PlatformEventBuilder::FillKeyEventFrom(
    const base::NativeEvent& native_event,
    KeyEvent* key_event) {
  key_event->set_key_code(KeyboardCodeFromNative(native_event));
  key_event->set_code(CodeFromNative(native_event));
  key_event->set_is_char(IsCharFromNative(native_event));
  key_event->set_platform_keycode(PlatformKeycodeFromNative(native_event));

  if (IsRepeated(native_event, *key_event))
    key_event->set_flags(key_event->flags() | ui::EF_IS_REPEAT);

#if defined(USE_X11)
  key_event->NormalizeFlags();
#endif
}

// static
void PlatformEventBuilder::FillScrollEventFrom(
    const base::NativeEvent& native_event,
    ScrollEvent* scroll_event) {
  float x_offset = 0;
  float y_offset = 0;
  float x_offset_ordinal = 0;
  float y_offset_ordinal = 0;
  int finger_count = 0;

  if (scroll_event->type() == ET_SCROLL) {
    GetScrollOffsets(native_event, &x_offset, &y_offset, &x_offset_ordinal,
                     &y_offset_ordinal, &finger_count);
    scroll_event->set_offset(x_offset, y_offset);
    scroll_event->set_offset_ordinal(x_offset_ordinal, y_offset_ordinal);
    scroll_event->set_finger_count(finger_count);
  } else if (scroll_event->type() == ET_SCROLL_FLING_START ||
             scroll_event->type() == ET_SCROLL_FLING_CANCEL) {
    GetFlingData(native_event, &x_offset, &y_offset, &x_offset_ordinal,
                 &y_offset_ordinal, NULL);
    scroll_event->set_offset(x_offset, y_offset);
    scroll_event->set_offset_ordinal(x_offset_ordinal, y_offset_ordinal);
  } else {
    NOTREACHED() << "Unexpected event type " << scroll_event->type()
                 << " when constructing a ScrollEvent.";
  }
}

}  // namespace ui
