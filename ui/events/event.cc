// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/event.h"

#if defined(USE_X11)
#include <X11/extensions/XInput2.h>
#include <X11/Xlib.h>
#include <X11/keysym.h>
#endif

#include <cmath>
#include <cstring>

#include "base/strings/stringprintf.h"
#include "ui/events/event_utils.h"
#include "ui/events/keycodes/keyboard_code_conversion.h"
#include "ui/gfx/geometry/safe_integer_conversions.h"
#include "ui/gfx/point3_f.h"
#include "ui/gfx/point_conversions.h"
#include "ui/gfx/transform.h"
#include "ui/gfx/transform_util.h"

namespace ui {

////////////////////////////////////////////////////////////////////////////////
// Event

// static
scoped_ptr<Event> Event::Clone(const Event& event) {
  if (event.IsKeyEvent()) {
    return scoped_ptr<Event>(new KeyEvent(static_cast<const KeyEvent&>(event)));
  }

  if (event.IsMouseEvent()) {
    if (event.IsMouseWheelEvent()) {
      return scoped_ptr<Event>(
          new MouseWheelEvent(static_cast<const MouseWheelEvent&>(event)));
    }

    return scoped_ptr<Event>(
        new MouseEvent(static_cast<const MouseEvent&>(event)));
  }

  if (event.IsTouchEvent()) {
    return scoped_ptr<Event>(
        new TouchEvent(static_cast<const TouchEvent&>(event)));
  }

  if (event.IsGestureEvent()) {
    return scoped_ptr<Event>(
        new GestureEvent(static_cast<const GestureEvent&>(event)));
  }

  if (event.IsScrollEvent()) {
    return scoped_ptr<Event>(
        new ScrollEvent(static_cast<const ScrollEvent&>(event)));
  }

  return scoped_ptr<Event>(new Event(event));
}

Event::~Event() {
}

GestureEvent* Event::AsGestureEvent() {
  CHECK(IsGestureEvent());
  return static_cast<GestureEvent*>(this);
}

const GestureEvent* Event::AsGestureEvent() const {
  CHECK(IsGestureEvent());
  return static_cast<const GestureEvent*>(this);
}

void Event::StopPropagation() {
  // TODO(sad): Re-enable these checks once View uses dispatcher to dispatch
  // events.
  // CHECK(phase_ != EP_PREDISPATCH && phase_ != EP_POSTDISPATCH);
  CHECK(cancelable_);
  result_ = static_cast<EventResult>(result_ | ER_CONSUMED);
}

void Event::SetHandled() {
  // TODO(sad): Re-enable these checks once View uses dispatcher to dispatch
  // events.
  // CHECK(phase_ != EP_PREDISPATCH && phase_ != EP_POSTDISPATCH);
  CHECK(cancelable_);
  result_ = static_cast<EventResult>(result_ | ER_HANDLED);
}

Event::Event()
    : type_(ET_UNKNOWN),
      time_stamp_(base::TimeDelta()),
      flags_(EF_NONE),
      cancelable_(true),
      target_(NULL),
      phase_(EP_PREDISPATCH),
      result_(ER_UNHANDLED),
      source_device_id_(ED_UNKNOWN_DEVICE) {
}

Event::Event(EventType type, base::TimeDelta time_stamp, int flags)
    : type_(type),
      time_stamp_(time_stamp),
      flags_(flags),
      cancelable_(true),
      target_(NULL),
      phase_(EP_PREDISPATCH),
      result_(ER_UNHANDLED),
      source_device_id_(ED_UNKNOWN_DEVICE) {
}

Event::Event(const Event& copy)
    : type_(copy.type_),
      time_stamp_(copy.time_stamp_),
      latency_(copy.latency_),
      flags_(copy.flags_),
      cancelable_(true),
      target_(NULL),
      phase_(EP_PREDISPATCH),
      result_(ER_UNHANDLED),
      source_device_id_(copy.source_device_id_) {
}

void Event::SetType(EventType type) {
  type_ = type;
}

////////////////////////////////////////////////////////////////////////////////
// CancelModeEvent

CancelModeEvent::CancelModeEvent()
    : Event(ET_CANCEL_MODE, base::TimeDelta(), 0) {
  set_cancelable(false);
}

CancelModeEvent::~CancelModeEvent() {
}

////////////////////////////////////////////////////////////////////////////////
// LocatedEvent

LocatedEvent::LocatedEvent() : Event() {
}

LocatedEvent::~LocatedEvent() {
}

LocatedEvent::LocatedEvent(EventType type,
                           const gfx::PointF& location,
                           const gfx::PointF& root_location,
                           base::TimeDelta time_stamp,
                           int flags)
    : Event(type, time_stamp, flags),
      location_(location),
      root_location_(root_location) {
}

void LocatedEvent::UpdateForRootTransform(
    const gfx::Transform& reversed_root_transform) {
  // Transform has to be done at root level.
  gfx::Point3F p(location_);
  reversed_root_transform.TransformPoint(&p);
  location_ = p.AsPointF();
  root_location_ = location_;
}

////////////////////////////////////////////////////////////////////////////////
// MouseEvent

MouseEvent::MouseEvent() : LocatedEvent(), changed_button_flags_(0) {
}

MouseEvent::MouseEvent(EventType type,
                       const gfx::PointF& location,
                       const gfx::PointF& root_location,
                       int flags,
                       int changed_button_flags)
    : LocatedEvent(type, location, root_location, EventTimeForNow(), flags),
      changed_button_flags_(changed_button_flags) {
  if (this->type() == ET_MOUSE_MOVED && IsAnyButton())
    SetType(ET_MOUSE_DRAGGED);
}

// static
bool MouseEvent::IsRepeatedClickEvent(
    const MouseEvent& event1,
    const MouseEvent& event2) {
  // These values match the Windows defaults.
  static const int kDoubleClickTimeMS = 500;
  static const int kDoubleClickWidth = 4;
  static const int kDoubleClickHeight = 4;

  if (event1.type() != ET_MOUSE_PRESSED ||
      event2.type() != ET_MOUSE_PRESSED)
    return false;

  // Compare flags, but ignore EF_IS_DOUBLE_CLICK to allow triple clicks.
  if ((event1.flags() & ~EF_IS_DOUBLE_CLICK) !=
      (event2.flags() & ~EF_IS_DOUBLE_CLICK))
    return false;

  base::TimeDelta time_difference = event2.time_stamp() - event1.time_stamp();

  if (time_difference.InMilliseconds() > kDoubleClickTimeMS)
    return false;

  if (std::abs(event2.x() - event1.x()) > kDoubleClickWidth / 2)
    return false;

  if (std::abs(event2.y() - event1.y()) > kDoubleClickHeight / 2)
    return false;

  return true;
}

int MouseEvent::GetClickCount() const {
  if (type() != ET_MOUSE_PRESSED && type() != ET_MOUSE_RELEASED)
    return 0;

  if (flags() & EF_IS_TRIPLE_CLICK)
    return 3;
  else if (flags() & EF_IS_DOUBLE_CLICK)
    return 2;
  else
    return 1;
}

void MouseEvent::SetClickCount(int click_count) {
  if (type() != ET_MOUSE_PRESSED && type() != ET_MOUSE_RELEASED)
    return;

  DCHECK(click_count > 0);
  DCHECK(click_count <= 3);

  int f = flags();
  switch (click_count) {
    case 1:
      f &= ~EF_IS_DOUBLE_CLICK;
      f &= ~EF_IS_TRIPLE_CLICK;
      break;
    case 2:
      f |= EF_IS_DOUBLE_CLICK;
      f &= ~EF_IS_TRIPLE_CLICK;
      break;
    case 3:
      f &= ~EF_IS_DOUBLE_CLICK;
      f |= EF_IS_TRIPLE_CLICK;
      break;
  }
  set_flags(f);
}

////////////////////////////////////////////////////////////////////////////////
// MouseWheelEvent

MouseWheelEvent::MouseWheelEvent() : MouseEvent(), offset_() {
}

MouseWheelEvent::MouseWheelEvent(const ScrollEvent& scroll_event)
    : MouseEvent(scroll_event),
      offset_(gfx::ToRoundedInt(scroll_event.x_offset()),
              gfx::ToRoundedInt(scroll_event.y_offset())) {
  SetType(ET_MOUSEWHEEL);
}

MouseWheelEvent::MouseWheelEvent(const MouseEvent& mouse_event,
                                 int x_offset,
                                 int y_offset)
    : MouseEvent(mouse_event), offset_(x_offset, y_offset) {
  DCHECK(type() == ET_MOUSEWHEEL);
}

MouseWheelEvent::MouseWheelEvent(const MouseWheelEvent& mouse_wheel_event)
    : MouseEvent(mouse_wheel_event),
      offset_(mouse_wheel_event.offset()) {
  DCHECK(type() == ET_MOUSEWHEEL);
}

MouseWheelEvent::MouseWheelEvent(const gfx::Vector2d& offset,
                                 const gfx::PointF& location,
                                 const gfx::PointF& root_location,
                                 int flags,
                                 int changed_button_flags)
    : MouseEvent(ui::ET_MOUSEWHEEL, location, root_location, flags,
                 changed_button_flags),
      offset_(offset) {
}

// This value matches GTK+ wheel scroll amount.
const int MouseWheelEvent::kWheelDelta = 53;

void MouseWheelEvent::UpdateForRootTransform(
    const gfx::Transform& inverted_root_transform) {
  LocatedEvent::UpdateForRootTransform(inverted_root_transform);
  gfx::DecomposedTransform decomp;
  bool success = gfx::DecomposeTransform(&decomp, inverted_root_transform);
  DCHECK(success);
  if (decomp.scale[0]) {
    offset_.set_x(
        gfx::ToRoundedInt(SkMScalarToFloat(offset_.x() * decomp.scale[0])));
  }
  if (decomp.scale[1]) {
    offset_.set_y(
        gfx::ToRoundedInt(SkMScalarToFloat(offset_.y() * decomp.scale[1])));
  }
}

////////////////////////////////////////////////////////////////////////////////
// TouchEvent

TouchEvent::TouchEvent()
    : LocatedEvent(),
      touch_id_(0),
      radius_x_(0),
      radius_y_(0),
      rotation_angle_(0),
      force_(0) {
}

TouchEvent::TouchEvent(EventType type,
                       const gfx::PointF& location,
                       int touch_id,
                       base::TimeDelta time_stamp)
    : LocatedEvent(type, location, location, time_stamp, 0),
      touch_id_(touch_id),
      radius_x_(0.0f),
      radius_y_(0.0f),
      rotation_angle_(0.0f),
      force_(0.0f) {
  latency()->AddLatencyNumber(INPUT_EVENT_LATENCY_UI_COMPONENT, 0, 0);
}

TouchEvent::TouchEvent(EventType type,
                       const gfx::PointF& location,
                       int flags,
                       int touch_id,
                       base::TimeDelta time_stamp,
                       float radius_x,
                       float radius_y,
                       float angle,
                       float force)
    : LocatedEvent(type, location, location, time_stamp, flags),
      touch_id_(touch_id),
      radius_x_(radius_x),
      radius_y_(radius_y),
      rotation_angle_(angle),
      force_(force) {
  latency()->AddLatencyNumber(INPUT_EVENT_LATENCY_UI_COMPONENT, 0, 0);
}

TouchEvent::~TouchEvent() {
}

void TouchEvent::UpdateForRootTransform(
    const gfx::Transform& inverted_root_transform) {
  LocatedEvent::UpdateForRootTransform(inverted_root_transform);
  gfx::DecomposedTransform decomp;
  bool success = gfx::DecomposeTransform(&decomp, inverted_root_transform);
  DCHECK(success);
  if (decomp.scale[0])
    radius_x_ *= decomp.scale[0];
  if (decomp.scale[1])
    radius_y_ *= decomp.scale[1];
}

////////////////////////////////////////////////////////////////////////////////
// KeyEvent

KeyEvent::KeyEvent()
    : Event(),
      key_code_(VKEY_UNKNOWN),
      code_(),
      is_char_(false),
      platform_keycode_(0),
      character_(0) {
}

KeyEvent::KeyEvent(EventType type,
                   KeyboardCode key_code,
                   int flags)
    : Event(type, EventTimeForNow(), flags),
      key_code_(key_code),
      is_char_(false),
      platform_keycode_(0),
      character_() {
}

KeyEvent::KeyEvent(EventType type,
                   KeyboardCode key_code,
                   const std::string& code,
                   int flags)
    : Event(type, EventTimeForNow(), flags),
      key_code_(key_code),
      code_(code),
      is_char_(false),
      platform_keycode_(0),
      character_(0) {
}

KeyEvent::KeyEvent(base::char16 character, KeyboardCode key_code, int flags)
    : Event(ET_KEY_PRESSED, EventTimeForNow(), flags),
      key_code_(key_code),
      code_(""),
      is_char_(true),
      platform_keycode_(0),
      character_(character) {
}

KeyEvent::KeyEvent(const KeyEvent& rhs)
    : Event(rhs),
      key_code_(rhs.key_code_),
      code_(rhs.code_),
      is_char_(rhs.is_char_),
      platform_keycode_(rhs.platform_keycode_),
      character_(rhs.character_) {
  if (rhs.extended_key_event_data_)
    extended_key_event_data_.reset(rhs.extended_key_event_data_->Clone());
}

KeyEvent& KeyEvent::operator=(const KeyEvent& rhs) {
  if (this != &rhs) {
    Event::operator=(rhs);
    key_code_ = rhs.key_code_;
    code_ = rhs.code_;
    is_char_ = rhs.is_char_;
    platform_keycode_ = rhs.platform_keycode_;
    character_ = rhs.character_;

    if (rhs.extended_key_event_data_)
      extended_key_event_data_.reset(rhs.extended_key_event_data_->Clone());
  }
  return *this;
}

KeyEvent::~KeyEvent() {}

void KeyEvent::SetExtendedKeyEventData(scoped_ptr<ExtendedKeyEventData> data) {
  extended_key_event_data_ = data.Pass();
}

base::char16 KeyEvent::GetCharacter() const {
  if (is_char_ || character_)
    return character_;

  // TODO(kpschoedel): streamline these cases after settling Ozone
  // positional coding.
#if defined(USE_X11)
  character_ = GetCharacterFromKeyCode(key_code_, flags());
  return character_;
#else
  return GetCharacterFromKeyCode(key_code_, flags());
#endif
}

base::char16 KeyEvent::GetText() const {
  if ((flags() & EF_CONTROL_DOWN) != 0) {
    return GetControlCharacterForKeycode(key_code_,
                                         (flags() & EF_SHIFT_DOWN) != 0);
  }
  return GetUnmodifiedText();
}

base::char16 KeyEvent::GetUnmodifiedText() const {
  if (!is_char_ && (key_code_ == VKEY_RETURN))
    return '\r';
  return GetCharacter();
}

bool KeyEvent::IsUnicodeKeyCode() const {
  return false;
}

void KeyEvent::NormalizeFlags() {
  int mask = 0;
  switch (key_code()) {
    case VKEY_CONTROL:
      mask = EF_CONTROL_DOWN;
      break;
    case VKEY_SHIFT:
      mask = EF_SHIFT_DOWN;
      break;
    case VKEY_MENU:
      mask = EF_ALT_DOWN;
      break;
    case VKEY_CAPITAL:
      mask = EF_CAPS_LOCK_DOWN;
      break;
    default:
      return;
  }
  if (type() == ET_KEY_PRESSED)
    set_flags(flags() | mask);
  else
    set_flags(flags() & ~mask);
}

bool KeyEvent::IsTranslated() const {
  switch (type()) {
    case ET_KEY_PRESSED:
    case ET_KEY_RELEASED:
      return false;
    case ET_TRANSLATED_KEY_PRESS:
    case ET_TRANSLATED_KEY_RELEASE:
      return true;
    default:
      NOTREACHED();
      return false;
  }
}

void KeyEvent::SetTranslated(bool translated) {
  switch (type()) {
    case ET_KEY_PRESSED:
    case ET_TRANSLATED_KEY_PRESS:
      SetType(translated ? ET_TRANSLATED_KEY_PRESS : ET_KEY_PRESSED);
      break;
    case ET_KEY_RELEASED:
    case ET_TRANSLATED_KEY_RELEASE:
      SetType(translated ? ET_TRANSLATED_KEY_RELEASE : ET_KEY_RELEASED);
      break;
    default:
      NOTREACHED();
  }
}

bool KeyEvent::IsRightSideKey() const {
  switch (key_code_) {
    case VKEY_CONTROL:
    case VKEY_SHIFT:
    case VKEY_MENU:
    case VKEY_LWIN:
#if defined(USE_X11)
      // Under X11, setting code_ requires platform-dependent information, and
      // currently assumes that X keycodes are based on Linux evdev keycodes.
      // In certain test environments this is not the case, and code_ is not
      // set accurately, so we need a different mechanism. Fortunately X11 key
      // mapping preserves the left-right distinction, so testing keysyms works
      // if the value is available (as it is for all X11 native-based events).
      if (platform_keycode_) {
        return (platform_keycode_ == XK_Shift_R) ||
               (platform_keycode_ == XK_Control_R) ||
               (platform_keycode_ == XK_Alt_R) ||
               (platform_keycode_ == XK_Meta_R) ||
               (platform_keycode_ == XK_Super_R) ||
               (platform_keycode_ == XK_Hyper_R);
      }
      // Fall through to the generic code if we have no platform_keycode_.
      // Under X11, this must be a synthetic event, so we can require that
      // code_ be set correctly.
#endif
      return ((code_.size() > 5) &&
              (code_.compare(code_.size() - 5, 5, "Right", 5)) == 0);
    default:
      return false;
  }
}

KeyboardCode KeyEvent::GetLocatedWindowsKeyboardCode() const {
  switch (key_code_) {
    case VKEY_SHIFT:
      return IsRightSideKey() ? VKEY_RSHIFT : VKEY_LSHIFT;
    case VKEY_CONTROL:
      return IsRightSideKey() ? VKEY_RCONTROL : VKEY_LCONTROL;
    case VKEY_MENU:
      return IsRightSideKey() ? VKEY_RMENU : VKEY_LMENU;
    case VKEY_LWIN:
      return IsRightSideKey() ? VKEY_RWIN : VKEY_LWIN;
    // TODO(kpschoedel): EF_NUMPAD_KEY is present only on X11. Currently this
    // function is only called on X11. Likely the tests here will be replaced
    // with a DOM-based code enumeration test in the course of Ozone
    // platform-indpendent key event work.
    case VKEY_0:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD0 : VKEY_0;
    case VKEY_1:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD1 : VKEY_1;
    case VKEY_2:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD2 : VKEY_2;
    case VKEY_3:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD3 : VKEY_3;
    case VKEY_4:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD4 : VKEY_4;
    case VKEY_5:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD5 : VKEY_5;
    case VKEY_6:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD6 : VKEY_6;
    case VKEY_7:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD7 : VKEY_7;
    case VKEY_8:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD8 : VKEY_8;
    case VKEY_9:
      return (flags() & EF_NUMPAD_KEY) ? VKEY_NUMPAD9 : VKEY_9;
    default:
      return key_code_;
  }
}

uint16 KeyEvent::GetConflatedWindowsKeyCode() const {
  if (is_char_)
    return character_;
  return key_code_;
}

////////////////////////////////////////////////////////////////////////////////
// ScrollEvent

ScrollEvent::ScrollEvent() : MouseEvent() {
}

ScrollEvent::ScrollEvent(EventType type,
                         const gfx::PointF& location,
                         base::TimeDelta time_stamp,
                         int flags,
                         float x_offset,
                         float y_offset,
                         float x_offset_ordinal,
                         float y_offset_ordinal,
                         int finger_count)
    : MouseEvent(type, location, location, flags, 0),
      x_offset_(x_offset),
      y_offset_(y_offset),
      x_offset_ordinal_(x_offset_ordinal),
      y_offset_ordinal_(y_offset_ordinal),
      finger_count_(finger_count) {
  set_time_stamp(time_stamp);
  CHECK(IsScrollEvent());
}

void ScrollEvent::Scale(const float factor) {
  x_offset_ *= factor;
  y_offset_ *= factor;
  x_offset_ordinal_ *= factor;
  y_offset_ordinal_ *= factor;
}

////////////////////////////////////////////////////////////////////////////////
// GestureEvent

GestureEvent::GestureEvent(float x,
                           float y,
                           int flags,
                           base::TimeDelta time_stamp,
                           const GestureEventDetails& details)
    : LocatedEvent(details.type(),
                   gfx::PointF(x, y),
                   gfx::PointF(x, y),
                   time_stamp,
                   flags | EF_FROM_TOUCH),
      details_(details) {
}

GestureEvent::~GestureEvent() {
}

}  // namespace ui
