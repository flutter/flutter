// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENT_H_
#define UI_EVENTS_EVENT_H_

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/event_types.h"
#include "base/gtest_prod_util.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/time/time.h"
#include "ui/events/event_constants.h"
#include "ui/events/gesture_event_details.h"
#include "ui/events/gestures/gesture_types.h"
#include "ui/events/keycodes/keyboard_codes.h"
#include "ui/events/latency_info.h"
#include "ui/gfx/point.h"
#include "ui/gfx/point_conversions.h"

namespace gfx {
class Transform;
}

namespace ui {
class EventTarget;

class EVENTS_EXPORT Event {
 public:
  static scoped_ptr<Event> Clone(const Event& event);

  virtual ~Event();

  class DispatcherApi {
   public:
    explicit DispatcherApi(Event* event) : event_(event) {}

    void set_target(EventTarget* target) {
      event_->target_ = target;
    }

    void set_phase(EventPhase phase) { event_->phase_ = phase; }
    void set_result(int result) {
      event_->result_ = static_cast<EventResult>(result);
    }

   private:
    DispatcherApi();
    Event* event_;

    DISALLOW_COPY_AND_ASSIGN(DispatcherApi);
  };

  EventType type() const { return type_; }
  void set_type(EventType type) { type_ = type; }

  // time_stamp represents time since machine was booted.
  const base::TimeDelta& time_stamp() const { return time_stamp_; }
  void set_time_stamp(const base::TimeDelta& stamp) { time_stamp_ = stamp; }

  int flags() const { return flags_; }
  void set_flags(int flags) { flags_ = flags; }

  EventTarget* target() const { return target_; }
  EventPhase phase() const { return phase_; }
  EventResult result() const { return result_; }

  LatencyInfo* latency() { return &latency_; }
  const LatencyInfo* latency() const { return &latency_; }
  void set_latency(const LatencyInfo& latency) { latency_ = latency; }

  int source_device_id() const { return source_device_id_; }
  void set_source_device_id(const int id) { source_device_id_ = id; }

  // By default, events are "cancelable", this means any default processing that
  // the containing abstraction layer may perform can be prevented by calling
  // SetHandled(). SetHandled() or StopPropagation() must not be called for
  // events that are not cancelable.
  bool cancelable() const { return cancelable_; }

  // The following methods return true if the respective keys were pressed at
  // the time the event was created.
  bool IsShiftDown() const { return (flags_ & EF_SHIFT_DOWN) != 0; }
  bool IsControlDown() const { return (flags_ & EF_CONTROL_DOWN) != 0; }
  bool IsCapsLockDown() const { return (flags_ & EF_CAPS_LOCK_DOWN) != 0; }
  bool IsAltDown() const { return (flags_ & EF_ALT_DOWN) != 0; }
  bool IsAltGrDown() const { return (flags_ & EF_ALTGR_DOWN) != 0; }
  bool IsCommandDown() const { return (flags_ & EF_COMMAND_DOWN) != 0; }
  bool IsRepeat() const { return (flags_ & EF_IS_REPEAT) != 0; }

  bool IsKeyEvent() const {
    return type_ == ET_KEY_PRESSED ||
           type_ == ET_KEY_RELEASED ||
           type_ == ET_TRANSLATED_KEY_PRESS ||
           type_ == ET_TRANSLATED_KEY_RELEASE;
  }

  bool IsMouseEvent() const {
    return type_ == ET_MOUSE_PRESSED ||
           type_ == ET_MOUSE_DRAGGED ||
           type_ == ET_MOUSE_RELEASED ||
           type_ == ET_MOUSE_MOVED ||
           type_ == ET_MOUSE_ENTERED ||
           type_ == ET_MOUSE_EXITED ||
           type_ == ET_MOUSEWHEEL ||
           type_ == ET_MOUSE_CAPTURE_CHANGED;
  }

  bool IsTouchEvent() const {
    return type_ == ET_TOUCH_RELEASED ||
           type_ == ET_TOUCH_PRESSED ||
           type_ == ET_TOUCH_MOVED ||
           type_ == ET_TOUCH_CANCELLED;
  }

  bool IsGestureEvent() const {
    switch (type_) {
      case ET_GESTURE_SCROLL_BEGIN:
      case ET_GESTURE_SCROLL_END:
      case ET_GESTURE_SCROLL_UPDATE:
      case ET_GESTURE_TAP:
      case ET_GESTURE_TAP_CANCEL:
      case ET_GESTURE_TAP_DOWN:
      case ET_GESTURE_BEGIN:
      case ET_GESTURE_END:
      case ET_GESTURE_TWO_FINGER_TAP:
      case ET_GESTURE_PINCH_BEGIN:
      case ET_GESTURE_PINCH_END:
      case ET_GESTURE_PINCH_UPDATE:
      case ET_GESTURE_LONG_PRESS:
      case ET_GESTURE_LONG_TAP:
      case ET_GESTURE_SWIPE:
      case ET_GESTURE_SHOW_PRESS:
      case ET_GESTURE_WIN8_EDGE_SWIPE:
        // When adding a gesture event which is paired with an event which
        // occurs earlier, add the event to |IsEndingEvent|.
        return true;

      case ET_SCROLL_FLING_CANCEL:
      case ET_SCROLL_FLING_START:
        // These can be ScrollEvents too. EF_FROM_TOUCH determines if they're
        // Gesture or Scroll events.
        return (flags_ & EF_FROM_TOUCH) == EF_FROM_TOUCH;

      default:
        break;
    }
    return false;
  }

  // An ending event is paired with the event which started it. Setting capture
  // should not prevent ending events from getting to their initial target.
  bool IsEndingEvent() const {
    switch(type_) {
      case ui::ET_TOUCH_CANCELLED:
      case ui::ET_GESTURE_TAP_CANCEL:
      case ui::ET_GESTURE_END:
      case ui::ET_GESTURE_SCROLL_END:
      case ui::ET_GESTURE_PINCH_END:
        return true;
      default:
        return false;
    }
  }

  bool IsScrollEvent() const {
    // Flings can be GestureEvents too. EF_FROM_TOUCH determins if they're
    // Gesture or Scroll events.
    return type_ == ET_SCROLL ||
           ((type_ == ET_SCROLL_FLING_START ||
           type_ == ET_SCROLL_FLING_CANCEL) &&
           !(flags() & EF_FROM_TOUCH));
  }

  bool IsScrollGestureEvent() const {
    return type_ == ET_GESTURE_SCROLL_BEGIN ||
           type_ == ET_GESTURE_SCROLL_UPDATE ||
           type_ == ET_GESTURE_SCROLL_END;
  }

  bool IsFlingScrollEvent() const {
    return type_ == ET_SCROLL_FLING_CANCEL ||
           type_ == ET_SCROLL_FLING_START;
  }

  bool IsMouseWheelEvent() const {
    return type_ == ET_MOUSEWHEEL;
  }

  bool IsLocatedEvent() const {
    return IsMouseEvent() || IsScrollEvent() || IsTouchEvent() ||
           IsGestureEvent();
  }

  // Convenience methods to cast |this| to a GestureEvent. IsGestureEvent()
  // must be true as a precondition to calling these methods.
  GestureEvent* AsGestureEvent();
  const GestureEvent* AsGestureEvent() const;

  // Immediately stops the propagation of the event. This must be called only
  // from an EventHandler during an event-dispatch. Any event handler that may
  // be in the list will not receive the event after this is called.
  // Note that StopPropagation() can be called only for cancelable events.
  void StopPropagation();
  bool stopped_propagation() const { return !!(result_ & ER_CONSUMED); }

  // Marks the event as having been handled. A handled event does not reach the
  // next event phase. For example, if an event is handled during the pre-target
  // phase, then the event is dispatched to all pre-target handlers, but not to
  // the target or post-target handlers.
  // Note that SetHandled() can be called only for cancelable events.
  void SetHandled();
  bool handled() const { return result_ != ER_UNHANDLED; }

 protected:
  Event();
  Event(EventType type, base::TimeDelta time_stamp, int flags);
  Event(const Event& copy);
  void SetType(EventType type);
  void set_cancelable(bool cancelable) { cancelable_ = cancelable; }

 private:
  friend class EventTestApi;

  EventType type_;
  base::TimeDelta time_stamp_;
  LatencyInfo latency_;
  int flags_;
  bool cancelable_;
  EventTarget* target_;
  EventPhase phase_;
  EventResult result_;

  // The device id the event came from, or ED_UNKNOWN_DEVICE if the information
  // is not available.
  int source_device_id_;
};

class EVENTS_EXPORT CancelModeEvent : public Event {
 public:
  CancelModeEvent();
  ~CancelModeEvent() override;
};

class EVENTS_EXPORT LocatedEvent : public Event {
 public:
  LocatedEvent();
  ~LocatedEvent() override;

  float x() const { return location_.x(); }
  float y() const { return location_.y(); }
  void set_location(const gfx::PointF& location) { location_ = location; }
  // TODO(tdresser): Always return floating point location. See
  // crbug.com/337824.
  gfx::Point location() const { return gfx::ToFlooredPoint(location_); }
  const gfx::PointF& location_f() const { return location_; }
  void set_root_location(const gfx::PointF& root_location) {
    root_location_ = root_location;
  }
  gfx::Point root_location() const {
    return gfx::ToFlooredPoint(root_location_);
  }
  const gfx::PointF& root_location_f() const {
    return root_location_;
  }
  const gfx::Point& screen_location() const { return screen_location_; }
  void set_screen_location(const gfx::Point& screen_location) {
    screen_location_ = screen_location;
  }

  // Transform the locations using |inverted_root_transform|.
  // This is applied to both |location_| and |root_location_|.
  virtual void UpdateForRootTransform(
      const gfx::Transform& inverted_root_transform);

  template <class T> void ConvertLocationToTarget(T* source, T* target) {
    if (!target || target == source)
      return;
    // TODO(tdresser): Rewrite ConvertPointToTarget to use PointF. See
    // crbug.com/337824.
    gfx::Point offset = gfx::ToFlooredPoint(location_);
    T::ConvertPointToTarget(source, target, &offset);
    gfx::Vector2d diff = gfx::ToFlooredPoint(location_) - offset;
    location_= location_ - diff;
  }

 protected:
  friend class LocatedEventTestApi;

  // Create a new LocatedEvent which is identical to the provided model.
  // If source / target windows are provided, the model location will be
  // converted from |source| coordinate system to |target| coordinate system.
  template <class T>
  LocatedEvent(const LocatedEvent& model, T* source, T* target)
      : Event(model),
        location_(model.location_),
        root_location_(model.root_location_),
        screen_location_(model.screen_location_) {
    ConvertLocationToTarget(source, target);
  }

  // Used for synthetic events in testing.
  LocatedEvent(EventType type,
               const gfx::PointF& location,
               const gfx::PointF& root_location,
               base::TimeDelta time_stamp,
               int flags);

  gfx::PointF location_;

  // |location_| multiplied by an optional transformation matrix for
  // rotations, animations and skews.
  gfx::PointF root_location_;

  // The system provided location of the event.
  gfx::Point screen_location_;
};

class EVENTS_EXPORT MouseEvent : public LocatedEvent {
 public:
  MouseEvent();

  // Create a new MouseEvent based on the provided model.
  // Uses the provided |type| and |flags| for the new event.
  // If source / target windows are provided, the model location will be
  // converted from |source| coordinate system to |target| coordinate system.
  template <class T>
  MouseEvent(const MouseEvent& model, T* source, T* target)
      : LocatedEvent(model, source, target),
        changed_button_flags_(model.changed_button_flags_) {
  }

  template <class T>
  MouseEvent(const MouseEvent& model,
             T* source,
             T* target,
             EventType type,
             int flags)
      : LocatedEvent(model, source, target),
        changed_button_flags_(model.changed_button_flags_) {
    SetType(type);
    set_flags(flags);
  }

  // Used for synthetic events in testing and by the gesture recognizer.
  MouseEvent(EventType type,
             const gfx::PointF& location,
             const gfx::PointF& root_location,
             int flags,
             int changed_button_flags);

  // Conveniences to quickly test what button is down
  bool IsOnlyLeftMouseButton() const {
    return (flags() & EF_LEFT_MOUSE_BUTTON) &&
      !(flags() & (EF_MIDDLE_MOUSE_BUTTON | EF_RIGHT_MOUSE_BUTTON));
  }

  bool IsLeftMouseButton() const {
    return (flags() & EF_LEFT_MOUSE_BUTTON) != 0;
  }

  bool IsOnlyMiddleMouseButton() const {
    return (flags() & EF_MIDDLE_MOUSE_BUTTON) &&
      !(flags() & (EF_LEFT_MOUSE_BUTTON | EF_RIGHT_MOUSE_BUTTON));
  }

  bool IsMiddleMouseButton() const {
    return (flags() & EF_MIDDLE_MOUSE_BUTTON) != 0;
  }

  bool IsOnlyRightMouseButton() const {
    return (flags() & EF_RIGHT_MOUSE_BUTTON) &&
      !(flags() & (EF_LEFT_MOUSE_BUTTON | EF_MIDDLE_MOUSE_BUTTON));
  }

  bool IsRightMouseButton() const {
    return (flags() & EF_RIGHT_MOUSE_BUTTON) != 0;
  }

  bool IsAnyButton() const {
    return (flags() & (EF_LEFT_MOUSE_BUTTON | EF_MIDDLE_MOUSE_BUTTON |
                       EF_RIGHT_MOUSE_BUTTON)) != 0;
  }

  // Compares two mouse down events and returns true if the second one should
  // be considered a repeat of the first.
  static bool IsRepeatedClickEvent(
      const MouseEvent& event1,
      const MouseEvent& event2);

  // Get the click count. Can be 1, 2 or 3 for mousedown messages, 0 otherwise.
  int GetClickCount() const;

  // Set the click count for a mousedown message. Can be 1, 2 or 3.
  void SetClickCount(int click_count);

  // Identifies the button that changed. During a press this corresponds to the
  // button that was pressed and during a release this corresponds to the button
  // that was released.
  // NOTE: during a press and release flags() contains the complete set of
  // flags. Use this to determine the button that was pressed or released.
  int changed_button_flags() const { return changed_button_flags_; }

  // Updates the button that changed.
  void set_changed_button_flags(int flags) { changed_button_flags_ = flags; }

  // Returns the repeat count based on the previous mouse click, if it is
  // recent enough and within a small enough distance.
  static int GetRepeatCount(const MouseEvent& click_event);

 private:
  FRIEND_TEST_ALL_PREFIXES(EventTest, DoubleClickRequiresRelease);
  FRIEND_TEST_ALL_PREFIXES(EventTest, SingleClickRightLeft);

  // See description above getter for details.
  int changed_button_flags_;
};

class ScrollEvent;

class EVENTS_EXPORT MouseWheelEvent : public MouseEvent {
 public:
  // See |offset| for details.
  static const int kWheelDelta;

  MouseWheelEvent();
  explicit MouseWheelEvent(const ScrollEvent& scroll_event);
  MouseWheelEvent(const MouseEvent& mouse_event, int x_offset, int y_offset);
  MouseWheelEvent(const MouseWheelEvent& mouse_wheel_event);

  template <class T>
  MouseWheelEvent(const MouseWheelEvent& model,
                  T* source,
                  T* target)
      : MouseEvent(model, source, target, model.type(), model.flags()),
        offset_(model.x_offset(), model.y_offset()) {
  }

  // Used for synthetic events in testing and by the gesture recognizer.
  MouseWheelEvent(const gfx::Vector2d& offset,
                  const gfx::PointF& location,
                  const gfx::PointF& root_location,
                  int flags,
                  int changed_button_flags);

  // The amount to scroll. This is in multiples of kWheelDelta.
  // Note: x_offset() > 0/y_offset() > 0 means scroll left/up.
  int x_offset() const { return offset_.x(); }
  int y_offset() const { return offset_.y(); }
  const gfx::Vector2d& offset() const { return offset_; }
  void set_offset(const gfx::Vector2d& offset) { offset_ = offset; }

  // Overridden from LocatedEvent.
  void UpdateForRootTransform(
      const gfx::Transform& inverted_root_transform) override;

 private:
  gfx::Vector2d offset_;
};

class EVENTS_EXPORT TouchEvent : public LocatedEvent {
 public:
  TouchEvent();

  // Create a new TouchEvent which is identical to the provided model.
  // If source / target windows are provided, the model location will be
  // converted from |source| coordinate system to |target| coordinate system.
  template <class T>
  TouchEvent(const TouchEvent& model, T* source, T* target)
      : LocatedEvent(model, source, target),
        touch_id_(model.touch_id_),
        radius_x_(model.radius_x_),
        radius_y_(model.radius_y_),
        rotation_angle_(model.rotation_angle_),
        force_(model.force_) {
  }

  TouchEvent(EventType type,
             const gfx::PointF& location,
             int touch_id,
             base::TimeDelta time_stamp);

  TouchEvent(EventType type,
             const gfx::PointF& location,
             int flags,
             int touch_id,
             base::TimeDelta timestamp,
             float radius_x,
             float radius_y,
             float angle,
             float force);

  ~TouchEvent() override;

  int touch_id() const { return touch_id_; }
  void set_touch_id(int touch_id) { touch_id_ = touch_id; }

  float radius_x() const { return radius_x_; }
  void set_radius_x(const float r) { radius_x_ = r; }
  float radius_y() const { return radius_y_; }
  void set_radius_y(const float r) { radius_y_ = r; }

  float rotation_angle() const { return rotation_angle_; }
  void set_rotation_angle(float rotation_angle) {
    rotation_angle_ = rotation_angle;
  }

  float force() const { return force_; }
  void set_force(float force) { force_ = force; }

  // Overridden from LocatedEvent.
  void UpdateForRootTransform(
      const gfx::Transform& inverted_root_transform) override;

 protected:
  void set_radius(float radius_x, float radius_y) {
    radius_x_ = radius_x;
    radius_y_ = radius_y;
  }

 private:
  // The identity (typically finger) of the touch starting at 0 and incrementing
  // for each separable additional touch that the hardware can detect.
  int touch_id_;

  // Radius of the X (major) axis of the touch ellipse. 0.0 if unknown.
  float radius_x_;

  // Radius of the Y (minor) axis of the touch ellipse. 0.0 if unknown.
  float radius_y_;

  // Angle of the major axis away from the X axis. Default 0.0.
  float rotation_angle_;

  // Force (pressure) of the touch. Normalized to be [0, 1]. Default to be 0.0.
  float force_;
};

// An interface that individual platforms can use to store additional data on
// KeyEvent.
//
// Currently only used in mojo.
class EVENTS_EXPORT ExtendedKeyEventData {
 public:
  virtual ~ExtendedKeyEventData() {}

  virtual ExtendedKeyEventData* Clone() const = 0;
};

// A KeyEvent is really two distinct classes, melded together due to the
// DOM legacy of Windows key events: a keystroke event (is_char_ == false),
// or a character event (is_char_ == true).
//
// For a keystroke event,
// -- is_char_ is false.
// -- type() can be any one of ET_KEY_PRESSED, ET_KEY_RELEASED,
//    ET_TRANSLATED_KEY_PRESS, or ET_TRANSLATED_KEY_RELEASE.
// -- character_ functions as a bypass or cache for GetCharacter().
// -- key_code_ is a VKEY_ value associated with the key. For printable
//    characters, this may or may not be a mapped value, imitating MS Windows:
//    if the mapped key generates a character that has an associated VKEY_
//    code, then key_code_ is that code; if not, then key_code_ is the unmapped
//    VKEY_ code. For example, US, Greek, Cyrillic, Japanese, etc. all use
//    VKEY_Q for the key beside Tab, while French uses VKEY_A.
// -- code_ is in one-to-one correspondence with a physical keyboard
//    location, and does not vary depending on key layout.
//
// For a character event,
// -- is_char_ is true.
// -- type() is ET_KEY_PRESSED.
// -- character_ is a UTF-16 character value.
// -- key_code_ is conflated with character_ by some code, because both
//    arrive in the wParam field of a Windows event.
// -- code_ is the empty string.
//
class EVENTS_EXPORT KeyEvent : public Event {
 public:
  KeyEvent();

  // Create a keystroke event.
  KeyEvent(EventType type, KeyboardCode key_code, int flags);

  // Create a character event.
  KeyEvent(base::char16 character, KeyboardCode key_code, int flags);

  // Used for synthetic events with code of DOM KeyboardEvent (e.g. 'KeyA')
  // See also: ui/events/keycodes/dom4/keycode_converter_data.h
  KeyEvent(EventType type,
           KeyboardCode key_code,
           const std::string& code,
           int flags);

  KeyEvent(const KeyEvent& rhs);

  KeyEvent& operator=(const KeyEvent& rhs);

  ~KeyEvent() override;

  // TODO(erg): While we transition to mojo, we have to hack around a mismatch
  // in our event types. Our ui::Events don't really have all the data we need
  // to process key events, and we instead do per-platform conversions with
  // native HWNDs or XEvents. And we can't reliably send those native data
  // types across mojo types in a cross-platform way. So instead, we set the
  // resulting data when read across IPC boundaries.
  void SetExtendedKeyEventData(scoped_ptr<ExtendedKeyEventData> data);
  const ExtendedKeyEventData* extended_key_event_data() const {
    return extended_key_event_data_.get();
  }

  // This bypasses the normal mapping from keystroke events to characters,
  // which allows an I18N virtual keyboard to fabricate a keyboard event that
  // does not have a corresponding KeyboardCode (example: U+00E1 Latin small
  // letter A with acute, U+0410 Cyrillic capital letter A).
  void set_character(base::char16 character) { character_ = character; }

  // Gets the character generated by this key event. It only supports Unicode
  // BMP characters.
  base::char16 GetCharacter() const;

  // If this is a keystroke event with key_code_ VKEY_RETURN, returns '\r';
  // otherwise returns the same as GetCharacter().
  base::char16 GetUnmodifiedText() const;

  // If the Control key is down in the event, returns a layout-independent
  // character (corresponding to US layout); otherwise returns the same
  // as GetUnmodifiedText().
  base::char16 GetText() const;

  // Gets the platform key code. For XKB, this is the xksym value.
  uint32 platform_keycode() const { return platform_keycode_; }
  void set_platform_keycode(uint32 keycode) { platform_keycode_ = keycode; }

  // Gets the associated (Windows-based) KeyboardCode for this key event.
  // Historically, this has also been used to obtain the character associated
  // with a character event, because both use the Window message 'wParam' field.
  // This should be avoided; if necessary for backwards compatibility, use
  // GetConflatedWindowsKeyCode().
  KeyboardCode key_code() const { return key_code_; }
  void set_key_code(KeyboardCode key_code) { key_code_ = key_code; }

  // True if this is a character event, false if this is a keystroke event.
  bool is_char() const { return is_char_; }
  void set_is_char(bool is_char) { is_char_ = is_char; }

  // Returns the same value as key_code(), except that located codes are
  // returned in place of non-located ones (e.g. VKEY_LSHIFT or VKEY_RSHIFT
  // instead of VKEY_SHIFT). This is a hybrid of semantic and physical
  // for legacy DOM reasons.
  KeyboardCode GetLocatedWindowsKeyboardCode() const;

  // For a keystroke event, returns the same value as key_code().
  // For a character event, returns the same value as GetCharacter().
  // This exists for backwards compatibility with Windows key events.
  uint16 GetConflatedWindowsKeyCode() const;

  // Returns true for [Alt]+<num-pad digit> Unicode alt key codes used by Win.
  // TODO(msw): Additional work may be needed for analogues on other platforms.
  bool IsUnicodeKeyCode() const;

  std::string code() const { return code_; }
  void set_code(const std::string& code) { code_ = code; }

  // Normalizes flags_ so that it describes the state after the event.
  // (Native X11 event flags describe the state before the event.)
  void NormalizeFlags();

  // Returns true if the key event has already been processed by an input method
  // and there is no need to pass the key event to the input method again.
  bool IsTranslated() const;
  // Marks this key event as translated or not translated.
  void SetTranslated(bool translated);

 protected:
  friend class KeyEventTestApi;

 private:
  // True if the key press originated from a 'right' key (VKEY_RSHIFT, etc.).
  bool IsRightSideKey() const;

  KeyboardCode key_code_;

  // String of 'code' defined in DOM KeyboardEvent (e.g. 'KeyA', 'Space')
  // http://www.w3.org/TR/uievents/#keyboard-key-codes.
  //
  // This value represents the physical position in the keyboard and can be
  // converted from / to keyboard scan code like XKB.
  std::string code_;

  // True if this is a character event, false if this is a keystroke event.
  bool is_char_;

  // The platform related keycode value. For XKB, it's keysym value.
  // For now, this is used for CharacterComposer in ChromeOS.
  uint32 platform_keycode_;

  // String of 'key' defined in DOM KeyboardEvent (e.g. 'a', 'â')
  // http://www.w3.org/TR/uievents/#keyboard-key-codes.
  //
  // This value represents the text that the key event will insert to input
  // field. For key with modifier key, it may have specifial text.
  // e.g. CTRL+A has '\x01'.
  mutable base::char16 character_;

  // Parts of our event handling require raw native events (see both the
  // windows and linux implementations of web_input_event in content/). Because
  // mojo instead serializes and deserializes events in potentially different
  // processes, we need to have a mechanism to keep track of this data.
  scoped_ptr<ExtendedKeyEventData> extended_key_event_data_;
};

class EVENTS_EXPORT ScrollEvent : public MouseEvent {
 public:
  ScrollEvent();
  template <class T>
  ScrollEvent(const ScrollEvent& model,
              T* source,
              T* target)
      : MouseEvent(model, source, target),
        x_offset_(model.x_offset_),
        y_offset_(model.y_offset_),
        x_offset_ordinal_(model.x_offset_ordinal_),
        y_offset_ordinal_(model.y_offset_ordinal_),
        finger_count_(model.finger_count_){
  }

  // Used for tests.
  ScrollEvent(EventType type,
              const gfx::PointF& location,
              base::TimeDelta time_stamp,
              int flags,
              float x_offset,
              float y_offset,
              float x_offset_ordinal,
              float y_offset_ordinal,
              int finger_count);

  // Scale the scroll event's offset value.
  // This is useful in the multi-monitor setup where it needs to be scaled
  // to provide a consistent user experience.
  void Scale(const float factor);

  float x_offset() const { return x_offset_; }
  float y_offset() const { return y_offset_; }
  void set_offset(float x, float y) {
    x_offset_ = x;
    y_offset_ = y;
  }

  float x_offset_ordinal() const { return x_offset_ordinal_; }
  float y_offset_ordinal() const { return y_offset_ordinal_; }
  void set_offset_ordinal(float x, float y) {
    x_offset_ordinal_ = x;
    y_offset_ordinal_ = y;
  }

  int finger_count() const { return finger_count_; }
  void set_finger_count(int finger_count) { finger_count_ = finger_count; }

 private:
  // Potential accelerated offsets.
  float x_offset_;
  float y_offset_;
  // Unaccelerated offsets.
  float x_offset_ordinal_;
  float y_offset_ordinal_;
  // Number of fingers on the pad.
  int finger_count_;
};

class EVENTS_EXPORT GestureEvent : public LocatedEvent {
 public:
  GestureEvent(float x,
               float y,
               int flags,
               base::TimeDelta time_stamp,
               const GestureEventDetails& details);

  // Create a new GestureEvent which is identical to the provided model.
  // If source / target windows are provided, the model location will be
  // converted from |source| coordinate system to |target| coordinate system.
  template <typename T>
  GestureEvent(const GestureEvent& model, T* source, T* target)
      : LocatedEvent(model, source, target),
        details_(model.details_) {
  }

  ~GestureEvent() override;

  const GestureEventDetails& details() const { return details_; }

 private:
  GestureEventDetails details_;
};

}  // namespace ui

#endif  // UI_EVENTS_EVENT_H_
