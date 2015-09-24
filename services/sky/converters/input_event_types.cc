// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/converters/input_event_types.h"

#include "base/logging.h"
#include "base/time/time.h"
#include "mojo/services/input_events/public/interfaces/input_event_constants.mojom.h"
#include "sky/engine/public/platform/WebInputEvent.h"

namespace sky {
namespace {

int EventFlagsToWebInputEventModifiers(int flags) {
  return
      (flags & mojo::EVENT_FLAGS_SHIFT_DOWN ?
       blink::WebInputEvent::ShiftKey : 0) |
      (flags & mojo::EVENT_FLAGS_CONTROL_DOWN ?
       blink::WebInputEvent::ControlKey : 0) |
      (flags & mojo::EVENT_FLAGS_CAPS_LOCK_DOWN ?
       blink::WebInputEvent::CapsLockOn : 0) |
      (flags & mojo::EVENT_FLAGS_ALT_DOWN ?
       blink::WebInputEvent::AltKey : 0) |
      (flags & mojo::EVENT_FLAGS_LEFT_MOUSE_BUTTON ?
       blink::WebInputEvent::LeftButtonDown : 0) |
      (flags & mojo::EVENT_FLAGS_MIDDLE_MOUSE_BUTTON ?
       blink::WebInputEvent::MiddleButtonDown : 0) |
      (flags & mojo::EVENT_FLAGS_RIGHT_MOUSE_BUTTON ?
       blink::WebInputEvent::RightButtonDown : 0);
}

scoped_ptr<blink::WebInputEvent> BuildWebPointerEvent(
    const mojo::EventPtr& event, float device_pixel_ratio) {
  scoped_ptr<blink::WebPointerEvent> web_event(new blink::WebPointerEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampMS =
      base::TimeDelta::FromInternalValue(event->time_stamp).InMillisecondsF();

  switch (event->action) {
    case mojo::EVENT_TYPE_POINTER_DOWN:
      web_event->type = blink::WebInputEvent::PointerDown;
      break;
    case mojo::EVENT_TYPE_POINTER_MOVE:
      web_event->type = blink::WebInputEvent::PointerMove;
      break;
    case mojo::EVENT_TYPE_POINTER_UP:
      web_event->type = blink::WebInputEvent::PointerUp;
      break;
    case mojo::EVENT_TYPE_POINTER_CANCEL:
      // FIXME: What mouse event should we listen to in order to learn when the
      // mouse moves out of the mojo::View?
      web_event->type = blink::WebInputEvent::PointerCancel;
      break;
    default:
      NOTIMPLEMENTED() << "Received unexpected event: " << event->action;
      break;
  }

  if (event->pointer_data->kind == mojo::POINTER_KIND_TOUCH) {
    web_event->kind = blink::WebPointerEvent::Touch;
    web_event->pointer = event->pointer_data->pointer_id;
  } else {
    web_event->kind = blink::WebPointerEvent::Mouse;
    // Set the buttons according to http://www.w3.org/TR/pointerevents/
    int buttons = 0;
    int modifiers = web_event->modifiers;
    buttons |= modifiers & blink::WebInputEvent::LeftButtonDown ? 1 << 0 : 0;
    buttons |= modifiers & blink::WebInputEvent::RightButtonDown ? 1 << 1 : 0;
    buttons |= modifiers & blink::WebInputEvent::MiddleButtonDown ? 1 << 2 : 0;
    web_event->buttons = buttons;
  }

  web_event->x = event->pointer_data->x / device_pixel_ratio;
  web_event->y = event->pointer_data->y / device_pixel_ratio;
  web_event->pressure = event->pointer_data->pressure;
  web_event->radiusMajor = event->pointer_data->radius_major;
  web_event->radiusMinor = event->pointer_data->radius_minor;
  web_event->orientation = event->pointer_data->orientation;

  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebKeyboardEvent(
    const mojo::EventPtr& event,
    float device_pixel_ratio) {
  scoped_ptr<blink::WebKeyboardEvent> web_event(new blink::WebKeyboardEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampMS =
      base::TimeDelta::FromInternalValue(event->time_stamp).InMillisecondsF();

  switch (event->action) {
    case mojo::EVENT_TYPE_KEY_PRESSED:
      web_event->type = event->key_data->is_char ? blink::WebInputEvent::Char :
          blink::WebInputEvent::KeyDown;
      break;
    case mojo::EVENT_TYPE_KEY_RELEASED:
      web_event->type = blink::WebInputEvent::KeyUp;
      break;
    default:
      NOTREACHED();
  }

  web_event->key = event->key_data->windows_key_code;
  web_event->charCode = event->key_data->text;
  web_event->unmodifiedCharCode = event->key_data->unmodified_text;

  return web_event.Pass();
}

scoped_ptr<blink::WebInputEvent> BuildWebWheelEvent(
    const mojo::EventPtr& event, float device_pixel_ratio) {
  scoped_ptr<blink::WebWheelEvent> web_event(new blink::WebWheelEvent);

  web_event->modifiers = EventFlagsToWebInputEventModifiers(event->flags);
  web_event->timeStampMS =
      base::TimeDelta::FromInternalValue(event->time_stamp).InMillisecondsF();

  web_event->type = blink::WebInputEvent::WheelEvent;

  web_event->x = event->pointer_data->x / device_pixel_ratio;
  web_event->y = event->pointer_data->y / device_pixel_ratio;

  // The times 100 is arbitrary. Need a better way to deal.
  web_event->offsetX =
      event->pointer_data->horizontal_wheel * 100 / device_pixel_ratio;
  web_event->offsetY =
      event->pointer_data->vertical_wheel * 100 / device_pixel_ratio;

  return web_event.Pass();
}

}  // namespace

scoped_ptr<blink::WebInputEvent> ConvertEvent(const mojo::EventPtr& event,
                                              float device_pixel_ratio) {
  if (event->action == mojo::EVENT_TYPE_POINTER_DOWN ||
      event->action == mojo::EVENT_TYPE_POINTER_UP ||
      event->action == mojo::EVENT_TYPE_POINTER_CANCEL ||
      event->action == mojo::EVENT_TYPE_POINTER_MOVE) {
    if (event->pointer_data->horizontal_wheel != 0 ||
        event->pointer_data->vertical_wheel != 0) {
      return BuildWebWheelEvent(event, device_pixel_ratio);
    }
    return BuildWebPointerEvent(event, device_pixel_ratio);
  } else if ((event->action == mojo::EVENT_TYPE_KEY_PRESSED ||
              event->action == mojo::EVENT_TYPE_KEY_RELEASED) &&
             event->key_data) {
    return BuildWebKeyboardEvent(event, device_pixel_ratio);
  }

  return nullptr;
}

}  // namespace mojo
