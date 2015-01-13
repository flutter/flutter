// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/converters/input_event_types.h"

#include "base/logging.h"
#include "base/time/time.h"
#include "mojo/services/input_events/public/interfaces/input_event_constants.mojom.h"
#include "sky/engine/public/web/WebInputEvent.h"

namespace mojo {
namespace {

// Used for scrolling. This matches Firefox behavior.
const int kPixelsPerTick = 53;

int EventFlagsToWebEventModifiers(int flags) {
  int modifiers = 0;

  if (flags & mojo::EVENT_FLAGS_SHIFT_DOWN)
    modifiers |= blink::WebInputEvent::ShiftKey;
  if (flags & mojo::EVENT_FLAGS_CONTROL_DOWN)
    modifiers |= blink::WebInputEvent::ControlKey;
  if (flags & mojo::EVENT_FLAGS_ALT_DOWN)
    modifiers |= blink::WebInputEvent::AltKey;
  // TODO(beng): MetaKey/META_MASK
  if (flags & mojo::EVENT_FLAGS_LEFT_MOUSE_BUTTON)
    modifiers |= blink::WebInputEvent::LeftButtonDown;
  if (flags & mojo::EVENT_FLAGS_MIDDLE_MOUSE_BUTTON)
    modifiers |= blink::WebInputEvent::MiddleButtonDown;
  if (flags & mojo::EVENT_FLAGS_RIGHT_MOUSE_BUTTON)
    modifiers |= blink::WebInputEvent::RightButtonDown;
  if (flags & mojo::EVENT_FLAGS_CAPS_LOCK_DOWN)
    modifiers |= blink::WebInputEvent::CapsLockOn;
  return modifiers;
}

int EventFlagsToWebInputEventModifiers(int flags) {
  return
      (flags & mojo::EVENT_FLAGS_SHIFT_DOWN ?
       blink::WebInputEvent::ShiftKey : 0) |
      (flags & mojo::EVENT_FLAGS_CONTROL_DOWN ?
       blink::WebInputEvent::ControlKey : 0) |
      (flags & mojo::EVENT_FLAGS_CAPS_LOCK_DOWN ?
       blink::WebInputEvent::CapsLockOn : 0) |
      (flags & mojo::EVENT_FLAGS_ALT_DOWN ?
       blink::WebInputEvent::AltKey : 0);
}

int GetClickCount(int flags) {
  if (flags & mojo::MOUSE_EVENT_FLAGS_IS_TRIPLE_CLICK)
    return 3;
  else if (flags & mojo::MOUSE_EVENT_FLAGS_IS_DOUBLE_CLICK)
    return 2;

  return 1;
}

scoped_ptr<blink::WebInputEvent> BuildWebTouchEvent(const EventPtr& event) {
  scoped_ptr<blink::WebTouchEvent> web_event(new blink::WebTouchEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  web_event->touchesLength = 1;
  web_event->changedTouchesLength = 1;
  web_event->targetTouchesLength = 1;

  blink::WebTouchPoint touch;

  switch (event->action) {
    case EVENT_TYPE_TOUCH_RELEASED:
      web_event->type = blink::WebInputEvent::TouchEnd;
      touch.state = blink::WebTouchPoint::StateReleased;
      break;
    case EVENT_TYPE_TOUCH_PRESSED:
      web_event->type = blink::WebInputEvent::TouchStart;
      touch.state = blink::WebTouchPoint::StatePressed;
      break;
    case EVENT_TYPE_TOUCH_MOVED:
      web_event->type = blink::WebInputEvent::TouchMove;
      touch.state = blink::WebTouchPoint::StateMoved;
      break;
    case EVENT_TYPE_TOUCH_CANCELLED:
      web_event->type = blink::WebInputEvent::TouchCancel;
      touch.state = blink::WebTouchPoint::StateCancelled;
      break;
    default:
      NOTIMPLEMENTED() << "Received unexpected event: " << event->action;
      break;
  }

  touch.id = event->touch_data->pointer_id;

  touch.position.x = event->location_data->in_view_location->x;
  touch.position.y = event->location_data->in_view_location->y;

  if (event->location_data->screen_location) {
    touch.screenPosition.x = event->location_data->screen_location->x;
    touch.screenPosition.y = event->location_data->screen_location->y;
  }

  if (web_event->touchesLength)
    web_event->touches[0] = touch;
  if (web_event->changedTouchesLength)
    web_event->changedTouches[0] = touch;
  if (web_event->targetTouchesLength)
    web_event->targetTouches[0] = touch;

  web_event->cancelable = true;

  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebGestureEvent(const EventPtr& event) {
  scoped_ptr<blink::WebGestureEvent> web_event(new blink::WebGestureEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  switch (event->action) {
    case EVENT_TYPE_GESTURE_SCROLL_BEGIN:
      web_event->type = blink::WebInputEvent::GestureScrollBegin;
      break;
    case EVENT_TYPE_GESTURE_SCROLL_END:
      web_event->type = blink::WebInputEvent::GestureScrollEnd;
      break;
    case EVENT_TYPE_GESTURE_SCROLL_UPDATE:
      web_event->type = blink::WebInputEvent::GestureScrollUpdate;
      break;
    case EVENT_TYPE_SCROLL_FLING_START:
      web_event->type = blink::WebInputEvent::GestureFlingStart;
      break;
    case EVENT_TYPE_SCROLL_FLING_CANCEL:
      web_event->type = blink::WebInputEvent::GestureFlingCancel;
      break;
    case EVENT_TYPE_GESTURE_SHOW_PRESS:
      web_event->type = blink::WebInputEvent::GestureShowPress;
      break;
    case EVENT_TYPE_GESTURE_TAP:
      web_event->type = blink::WebInputEvent::GestureTap;
      break;
    case EVENT_TYPE_GESTURE_TAP_UNCONFIRMED:
      web_event->type = blink::WebInputEvent::GestureTapUnconfirmed;
      break;
    case EVENT_TYPE_GESTURE_TAP_DOWN:
      web_event->type = blink::WebInputEvent::GestureTapDown;
      break;
    case EVENT_TYPE_GESTURE_TAP_CANCEL:
      web_event->type = blink::WebInputEvent::GestureTapCancel;
      break;
    case EVENT_TYPE_GESTURE_DOUBLE_TAP:
      web_event->type = blink::WebInputEvent::GestureDoubleTap;
      break;
    case EVENT_TYPE_GESTURE_TWO_FINGER_TAP:
      web_event->type = blink::WebInputEvent::GestureTwoFingerTap;
      break;
    case EVENT_TYPE_GESTURE_LONG_PRESS:
      web_event->type = blink::WebInputEvent::GestureLongPress;
      break;
    case EVENT_TYPE_GESTURE_LONG_TAP:
      web_event->type = blink::WebInputEvent::GestureLongTap;
      break;
    case EVENT_TYPE_GESTURE_PINCH_BEGIN:
      web_event->type = blink::WebInputEvent::GesturePinchBegin;
      break;
    case EVENT_TYPE_GESTURE_PINCH_END:
      web_event->type = blink::WebInputEvent::GesturePinchEnd;
      break;
    case EVENT_TYPE_GESTURE_PINCH_UPDATE:
      web_event->type = blink::WebInputEvent::GesturePinchUpdate;
      break;
    default:
      NOTIMPLEMENTED() << "Received unexpected event: " << event->action;
      break;
  }

  web_event->x = event->location_data->in_view_location->x;
  web_event->y = event->location_data->in_view_location->y;

  // TODO(erg): Remove this null check as parallel to above.
  if (!event->location_data->screen_location.is_null()) {
    web_event->globalX = event->location_data->screen_location->x;
    web_event->globalY = event->location_data->screen_location->y;
  }

  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebMouseEvent(const EventPtr& event) {
  scoped_ptr<blink::WebMouseEvent> web_event(new blink::WebMouseEvent);
  web_event->x = event->location_data->in_view_location->x;
  web_event->y = event->location_data->in_view_location->y;

  // TODO(erg): Remove this if check once we can rely on screen_location
  // actually being passed to us. As written today, getting the screen
  // location from ui::Event objects can only be done by querying the
  // underlying native events, so all synthesized events don't have screen
  // locations.
  if (!event->location_data->screen_location.is_null()) {
    web_event->globalX = event->location_data->screen_location->x;
    web_event->globalY = event->location_data->screen_location->y;
  }

  web_event->modifiers = EventFlagsToWebEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  web_event->button = blink::WebMouseEvent::ButtonNone;
  if (event->flags & mojo::EVENT_FLAGS_LEFT_MOUSE_BUTTON)
    web_event->button = blink::WebMouseEvent::ButtonLeft;
  if (event->flags & mojo::EVENT_FLAGS_MIDDLE_MOUSE_BUTTON)
    web_event->button = blink::WebMouseEvent::ButtonMiddle;
  if (event->flags & mojo::EVENT_FLAGS_RIGHT_MOUSE_BUTTON)
    web_event->button = blink::WebMouseEvent::ButtonRight;

  switch (event->action) {
    case EVENT_TYPE_MOUSE_PRESSED:
      web_event->type = blink::WebInputEvent::MouseDown;
      break;
    case EVENT_TYPE_MOUSE_RELEASED:
      web_event->type = blink::WebInputEvent::MouseUp;
      break;
    case EVENT_TYPE_MOUSE_ENTERED:
      web_event->type = blink::WebInputEvent::MouseLeave;
      web_event->button = blink::WebMouseEvent::ButtonNone;
      break;
    case EVENT_TYPE_MOUSE_EXITED:
    case EVENT_TYPE_MOUSE_MOVED:
    case EVENT_TYPE_MOUSE_DRAGGED:
      web_event->type = blink::WebInputEvent::MouseMove;
      break;
    default:
      NOTIMPLEMENTED() << "Received unexpected event: " << event->action;
      break;
  }

  web_event->clickCount = GetClickCount(event->flags);

  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebKeyboardEvent(
    const EventPtr& event) {
  scoped_ptr<blink::WebKeyboardEvent> web_event(new blink::WebKeyboardEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  switch (event->action) {
    case EVENT_TYPE_KEY_PRESSED:
      web_event->type = event->key_data->is_char ? blink::WebInputEvent::Char :
          blink::WebInputEvent::RawKeyDown;
      break;
    case EVENT_TYPE_KEY_RELEASED:
      web_event->type = blink::WebInputEvent::KeyUp;
      break;
    default:
      NOTREACHED();
  }

  if (web_event->modifiers & blink::WebInputEvent::AltKey)
    web_event->isSystemKey = true;

  web_event->windowsKeyCode = event->key_data->windows_key_code;
  web_event->nativeKeyCode = event->key_data->native_key_code;
  web_event->text[0] = event->key_data->text;
  web_event->unmodifiedText[0] = event->key_data->unmodified_text;

  web_event->setKeyIdentifierFromWindowsKeyCode();
  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebMouseWheelEvent(
    const EventPtr& event) {
  scoped_ptr<blink::WebMouseWheelEvent> web_event(
      new blink::WebMouseWheelEvent);
  web_event->type = blink::WebInputEvent::MouseWheel;
  web_event->button = blink::WebMouseEvent::ButtonNone;
  web_event->modifiers = EventFlagsToWebEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  web_event->x = event->location_data->in_view_location->x;
  web_event->y = event->location_data->in_view_location->y;

  // TODO(erg): Remove this null check as parallel to above.
  if (!event->location_data->screen_location.is_null()) {
    web_event->globalX = event->location_data->screen_location->x;
    web_event->globalY = event->location_data->screen_location->y;
  }

  if ((event->flags & mojo::EVENT_FLAGS_SHIFT_DOWN) != 0 &&
      event->wheel_data->x_offset == 0) {
    web_event->deltaX = event->wheel_data->y_offset;
    web_event->deltaY = 0;
  } else {
    web_event->deltaX = event->wheel_data->x_offset;
    web_event->deltaY = event->wheel_data->y_offset;
  }

  web_event->wheelTicksX = web_event->deltaX / kPixelsPerTick;
  web_event->wheelTicksY = web_event->deltaY / kPixelsPerTick;

  return web_event.Pass();
}

}  // namespace

// static
scoped_ptr<blink::WebInputEvent>
TypeConverter<scoped_ptr<blink::WebInputEvent>, EventPtr>::Convert(
    const EventPtr& event) {
  if (event->action == EVENT_TYPE_TOUCH_RELEASED ||
      event->action == EVENT_TYPE_TOUCH_PRESSED ||
      event->action == EVENT_TYPE_TOUCH_MOVED ||
      event->action == EVENT_TYPE_TOUCH_CANCELLED) {
    return BuildWebTouchEvent(event);
  } else if (event->action == EVENT_TYPE_GESTURE_SCROLL_BEGIN ||
      event->action == EVENT_TYPE_GESTURE_SCROLL_END ||
      event->action == EVENT_TYPE_GESTURE_SCROLL_UPDATE ||
      event->action == EVENT_TYPE_GESTURE_TAP ||
      event->action == EVENT_TYPE_GESTURE_TAP_DOWN ||
      event->action == EVENT_TYPE_GESTURE_TAP_CANCEL ||
      event->action == EVENT_TYPE_GESTURE_TAP_UNCONFIRMED ||
      event->action == EVENT_TYPE_GESTURE_DOUBLE_TAP ||
      event->action == EVENT_TYPE_GESTURE_BEGIN ||
      event->action == EVENT_TYPE_GESTURE_END ||
      event->action == EVENT_TYPE_GESTURE_TWO_FINGER_TAP ||
      event->action == EVENT_TYPE_GESTURE_PINCH_BEGIN ||
      event->action == EVENT_TYPE_GESTURE_PINCH_END ||
      event->action == EVENT_TYPE_GESTURE_PINCH_UPDATE ||
      event->action == EVENT_TYPE_GESTURE_LONG_PRESS ||
      event->action == EVENT_TYPE_GESTURE_LONG_TAP ||
      event->action == EVENT_TYPE_GESTURE_SWIPE ||
      event->action == EVENT_TYPE_GESTURE_SHOW_PRESS ||
      event->action == EVENT_TYPE_GESTURE_WIN8_EDGE_SWIPE ||
      event->action == EVENT_TYPE_SCROLL_FLING_START ||
      event->action == EVENT_TYPE_SCROLL_FLING_CANCEL) {
    return BuildWebGestureEvent(event);
  } else if (event->action == EVENT_TYPE_MOUSE_PRESSED ||
      event->action == EVENT_TYPE_MOUSE_RELEASED ||
      event->action == EVENT_TYPE_MOUSE_ENTERED ||
      event->action == EVENT_TYPE_MOUSE_EXITED ||
      event->action == EVENT_TYPE_MOUSE_MOVED ||
      event->action == EVENT_TYPE_MOUSE_DRAGGED) {
    return BuildWebMouseEvent(event);
  } else if ((event->action == EVENT_TYPE_KEY_PRESSED ||
              event->action == EVENT_TYPE_KEY_RELEASED) &&
             event->key_data) {
    return BuildWebKeyboardEvent(event);
  } else if (event->action == EVENT_TYPE_MOUSEWHEEL) {
    return BuildWebMouseWheelEvent(event);
  }

  return scoped_ptr<blink::WebInputEvent>();
}

}  // namespace mojo
