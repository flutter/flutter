// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/converters/input_event_types.h"

#include "base/logging.h"
#include "base/time/time.h"
#include "mojo/services/input_events/public/interfaces/input_event_constants.mojom.h"
#include "sky/engine/public/platform/WebInputEvent.h"

namespace sky {
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

scoped_ptr<blink::WebInputEvent> BuildWebPointerEvent(
    const mojo::EventPtr& event, float device_pixel_ratio) {
  scoped_ptr<blink::WebPointerEvent> web_event(new blink::WebPointerEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  switch (event->action) {
    case mojo::EVENT_TYPE_TOUCH_PRESSED:
    case mojo::EVENT_TYPE_MOUSE_PRESSED:
      web_event->type = blink::WebInputEvent::PointerDown;
      break;
    case mojo::EVENT_TYPE_TOUCH_MOVED:
    case mojo::EVENT_TYPE_MOUSE_DRAGGED:
      web_event->type = blink::WebInputEvent::PointerMove;
      break;
    case mojo::EVENT_TYPE_TOUCH_RELEASED:
    case mojo::EVENT_TYPE_MOUSE_RELEASED:
      web_event->type = blink::WebInputEvent::PointerUp;
      break;
    case mojo::EVENT_TYPE_TOUCH_CANCELLED:
    case mojo::EVENT_TYPE_MOUSE_EXITED:
      web_event->type = blink::WebInputEvent::PointerCancel;
      break;
    default:
      NOTIMPLEMENTED() << "Received unexpected event: " << event->action;
      break;
  }

  switch (event->action) {
    case mojo::EVENT_TYPE_TOUCH_CANCELLED:
    case mojo::EVENT_TYPE_TOUCH_MOVED:
    case mojo::EVENT_TYPE_TOUCH_PRESSED:
    case mojo::EVENT_TYPE_TOUCH_RELEASED:
      web_event->kind = blink::WebPointerEvent::Touch;
      break;
    case mojo::EVENT_TYPE_MOUSE_DRAGGED:
    case mojo::EVENT_TYPE_MOUSE_EXITED:
    case mojo::EVENT_TYPE_MOUSE_PRESSED:
    case mojo::EVENT_TYPE_MOUSE_RELEASED:
      web_event->kind = blink::WebPointerEvent::Mouse;
      break;
    default:
      NOTIMPLEMENTED() << "Received unexpected event: " << event->action;
      break;
  }

  if (event->touch_data)
    web_event->pointer = event->touch_data->pointer_id;

  const auto& location = event->location_data->in_view_location;
  web_event->x = location->x / device_pixel_ratio;
  web_event->y = location->y / device_pixel_ratio;

  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebGestureEvent(
    const mojo::EventPtr& event,
    float device_pixel_ratio) {
  scoped_ptr<blink::WebGestureEvent> web_event(new blink::WebGestureEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  switch (event->action) {
    case mojo::EVENT_TYPE_GESTURE_SCROLL_BEGIN:
      web_event->type = blink::WebInputEvent::GestureScrollBegin;
      break;
    case mojo::EVENT_TYPE_GESTURE_SCROLL_END:
      web_event->type = blink::WebInputEvent::GestureScrollEnd;
      break;
    case mojo::EVENT_TYPE_GESTURE_SCROLL_UPDATE:
      web_event->type = blink::WebInputEvent::GestureScrollUpdate;
      web_event->data.scrollUpdate.deltaX = event->gesture_data->scroll_x;
      web_event->data.scrollUpdate.deltaY = event->gesture_data->scroll_y;
      break;
    case mojo::EVENT_TYPE_SCROLL_FLING_START:
      web_event->type = blink::WebInputEvent::GestureFlingStart;
      web_event->data.flingStart.velocityX = event->gesture_data->velocity_x;
      web_event->data.flingStart.velocityY = event->gesture_data->velocity_y;
      break;
    case mojo::EVENT_TYPE_SCROLL_FLING_CANCEL:
      web_event->type = blink::WebInputEvent::GestureFlingCancel;
      break;
    case mojo::EVENT_TYPE_GESTURE_SHOW_PRESS:
      web_event->type = blink::WebInputEvent::GestureShowPress;
      break;
    case mojo::EVENT_TYPE_GESTURE_TAP:
      web_event->type = blink::WebInputEvent::GestureTap;
      web_event->data.tap.tapCount = event->gesture_data->tap_count;
      break;
    case mojo::EVENT_TYPE_GESTURE_TAP_UNCONFIRMED:
      web_event->type = blink::WebInputEvent::GestureTapUnconfirmed;
      web_event->data.tap.tapCount = event->gesture_data->tap_count;
      break;
    case mojo::EVENT_TYPE_GESTURE_TAP_DOWN:
      web_event->type = blink::WebInputEvent::GestureTapDown;
      break;
    case mojo::EVENT_TYPE_GESTURE_TAP_CANCEL:
      web_event->type = blink::WebInputEvent::GestureTapCancel;
      break;
    case mojo::EVENT_TYPE_GESTURE_DOUBLE_TAP:
      web_event->type = blink::WebInputEvent::GestureDoubleTap;
      web_event->data.tap.tapCount = event->gesture_data->tap_count;
      break;
    case mojo::EVENT_TYPE_GESTURE_TWO_FINGER_TAP:
      web_event->type = blink::WebInputEvent::GestureTwoFingerTap;
      break;
    case mojo::EVENT_TYPE_GESTURE_LONG_PRESS:
      web_event->type = blink::WebInputEvent::GestureLongPress;
      break;
    case mojo::EVENT_TYPE_GESTURE_LONG_TAP:
      web_event->type = blink::WebInputEvent::GestureLongTap;
      break;
    case mojo::EVENT_TYPE_GESTURE_PINCH_BEGIN:
      web_event->type = blink::WebInputEvent::GesturePinchBegin;
      break;
    case mojo::EVENT_TYPE_GESTURE_PINCH_END:
      web_event->type = blink::WebInputEvent::GesturePinchEnd;
      break;
    case mojo::EVENT_TYPE_GESTURE_PINCH_UPDATE:
      web_event->type = blink::WebInputEvent::GesturePinchUpdate;
      web_event->data.pinchUpdate.scale = event->gesture_data->scale;
      break;
    default:
      NOTIMPLEMENTED() << "Received unexpected event: " << event->action;
      break;
  }

  web_event->x = event->location_data->in_view_location->x / device_pixel_ratio;
  web_event->y = event->location_data->in_view_location->y / device_pixel_ratio;

  // TODO(erg): Remove this null check as parallel to above.
  if (!event->location_data->screen_location.is_null()) {
    web_event->globalX =
        event->location_data->screen_location->x / device_pixel_ratio;
    web_event->globalY =
        event->location_data->screen_location->y / device_pixel_ratio;
  }

  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebKeyboardEvent(
    const mojo::EventPtr& event,
    float device_pixel_ratio) {
  scoped_ptr<blink::WebKeyboardEvent> web_event(new blink::WebKeyboardEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  switch (event->action) {
    case mojo::EVENT_TYPE_KEY_PRESSED:
      web_event->type = event->key_data->is_char ? blink::WebInputEvent::Char :
          blink::WebInputEvent::RawKeyDown;
      break;
    case mojo::EVENT_TYPE_KEY_RELEASED:
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
    const mojo::EventPtr& event,
    float device_pixel_ratio) {
  scoped_ptr<blink::WebMouseWheelEvent> web_event(
      new blink::WebMouseWheelEvent);
  web_event->type = blink::WebInputEvent::MouseWheel;
  web_event->button = blink::WebMouseEvent::ButtonNone;
  web_event->modifiers = EventFlagsToWebEventModifiers(event->flags);
  web_event->timeStampSeconds =
      base::TimeDelta::FromInternalValue(event->time_stamp).InSecondsF();

  web_event->x = event->location_data->in_view_location->x / device_pixel_ratio;
  web_event->y = event->location_data->in_view_location->y / device_pixel_ratio;

  // TODO(erg): Remove this null check as parallel to above.
  if (!event->location_data->screen_location.is_null()) {
    web_event->globalX =
        event->location_data->screen_location->x / device_pixel_ratio;
    web_event->globalY =
        event->location_data->screen_location->y / device_pixel_ratio;
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

scoped_ptr<blink::WebInputEvent> ConvertEvent(const mojo::EventPtr& event,
                                              float device_pixel_ratio) {
  if (event->action == mojo::EVENT_TYPE_TOUCH_RELEASED ||
      event->action == mojo::EVENT_TYPE_TOUCH_PRESSED ||
      event->action == mojo::EVENT_TYPE_TOUCH_MOVED ||
      event->action == mojo::EVENT_TYPE_TOUCH_CANCELLED ||
      event->action == mojo::EVENT_TYPE_MOUSE_DRAGGED ||
      event->action == mojo::EVENT_TYPE_MOUSE_EXITED ||
      event->action == mojo::EVENT_TYPE_MOUSE_PRESSED ||
      event->action == mojo::EVENT_TYPE_MOUSE_RELEASED) {
    return BuildWebPointerEvent(event, device_pixel_ratio);
  } else if (event->action == mojo::EVENT_TYPE_GESTURE_SCROLL_BEGIN ||
             event->action == mojo::EVENT_TYPE_GESTURE_SCROLL_END ||
             event->action == mojo::EVENT_TYPE_GESTURE_SCROLL_UPDATE ||
             event->action == mojo::EVENT_TYPE_GESTURE_TAP ||
             event->action == mojo::EVENT_TYPE_GESTURE_TAP_DOWN ||
             event->action == mojo::EVENT_TYPE_GESTURE_TAP_CANCEL ||
             event->action == mojo::EVENT_TYPE_GESTURE_TAP_UNCONFIRMED ||
             event->action == mojo::EVENT_TYPE_GESTURE_DOUBLE_TAP ||
             event->action == mojo::EVENT_TYPE_GESTURE_BEGIN ||
             event->action == mojo::EVENT_TYPE_GESTURE_END ||
             event->action == mojo::EVENT_TYPE_GESTURE_TWO_FINGER_TAP ||
             event->action == mojo::EVENT_TYPE_GESTURE_PINCH_BEGIN ||
             event->action == mojo::EVENT_TYPE_GESTURE_PINCH_END ||
             event->action == mojo::EVENT_TYPE_GESTURE_PINCH_UPDATE ||
             event->action == mojo::EVENT_TYPE_GESTURE_LONG_PRESS ||
             event->action == mojo::EVENT_TYPE_GESTURE_LONG_TAP ||
             event->action == mojo::EVENT_TYPE_GESTURE_SWIPE ||
             event->action == mojo::EVENT_TYPE_GESTURE_SHOW_PRESS ||
             event->action == mojo::EVENT_TYPE_GESTURE_WIN8_EDGE_SWIPE ||
             event->action == mojo::EVENT_TYPE_SCROLL_FLING_START ||
             event->action == mojo::EVENT_TYPE_SCROLL_FLING_CANCEL) {
    return BuildWebGestureEvent(event, device_pixel_ratio);
  } else if ((event->action == mojo::EVENT_TYPE_KEY_PRESSED ||
              event->action == mojo::EVENT_TYPE_KEY_RELEASED) &&
             event->key_data) {
    return BuildWebKeyboardEvent(event, device_pixel_ratio);
  } else if (event->action == mojo::EVENT_TYPE_MOUSEWHEEL) {
    return BuildWebMouseWheelEvent(event, device_pixel_ratio);
  }

  return scoped_ptr<blink::WebInputEvent>();
}

}  // namespace mojo
